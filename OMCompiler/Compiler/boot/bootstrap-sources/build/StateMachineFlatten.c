#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "StateMachineFlatten.c"
#endif
#include "omc_simulation_settings.h"
#include "StateMachineFlatten.h"
#define _OMC_LIT0_data "sample"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,6,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "pre"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,3,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT2,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT1}};
#define _OMC_LIT2 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "previous"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,8,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "smOf"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,4,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "initial"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,7,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT5}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,2,6) {&DAE_Type_T__BOOL__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT8,1,7) {&DAE_InlineType_NO__INLINE__desc,}};
#define _OMC_LIT8 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,1,3) {&DAE_TailCall_NO__TAIL__desc,}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,8,3) {&DAE_CallAttributes_CALL__ATTR__desc,_OMC_LIT7,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT8,_OMC_LIT9}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,4,16) {&DAE_Exp_CALL__desc,_OMC_LIT6,MMC_REFSTRUCTLIT(mmc_nil),_OMC_LIT10}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT12,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT0}};
#define _OMC_LIT12 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "defaultClockPeriod"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,18,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT14,1,3) {&Flags_FlagVisibility_INTERNAL__desc,}};
#define _OMC_LIT14 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT15,1.0);
#define _OMC_LIT15 MMC_REFREALLIT(_OMC_LIT_STRUCT15)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT16,2,7) {&Flags_FlagData_REAL__FLAG__desc,_OMC_LIT15}};
#define _OMC_LIT16 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data "Sets the default clock period (in seconds) for state machines (default: 1.0)."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,77,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT18,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT17}};
#define _OMC_LIT18 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(84)),_OMC_LIT13,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT14,_OMC_LIT16,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT18}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT20,2,3) {&DAE_Dimension_DIM__INTEGER__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(2))}};
#define _OMC_LIT20 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT20)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT21,2,1) {_OMC_LIT20,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT21 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT21)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT22,3,9) {&DAE_Type_T__ARRAY__desc,_OMC_LIT7,_OMC_LIT21}};
#define _OMC_LIT22 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT22)
#define _OMC_LIT23_data "cImmediate"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT23,10,_OMC_LIT23_data);
#define _OMC_LIT23 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT23)
#define _OMC_LIT24_data "ctStateMachines"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT24,15,_OMC_LIT24_data);
#define _OMC_LIT24 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT24)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT25,2,4) {&Flags_FlagData_BOOL__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT25 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "Experimental: Enable continuous-time state machine prototype"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,60,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT27,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT26}};
#define _OMC_LIT27 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT27)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT28,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(89)),_OMC_LIT24,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT14,_OMC_LIT25,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT27}};
#define _OMC_LIT28 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,0,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT30,0.0);
#define _OMC_LIT30 MMC_REFREALLIT(_OMC_LIT_STRUCT30)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT31,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT29,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT30}};
#define _OMC_LIT31 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT31)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT32,1,4) {&DAE_ComponentPrefix_NOCOMPPRE__desc,}};
#define _OMC_LIT32 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT32)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT33,8,3) {&DAE_ElementSource_SOURCE__desc,_OMC_LIT31,MMC_REFSTRUCTLIT(mmc_nil),_OMC_LIT32,MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT33 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT33)
#define _OMC_LIT34_data "TRANSITION(from="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT34,16,_OMC_LIT34_data);
#define _OMC_LIT34 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT34)
#define _OMC_LIT35_data ", to="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT35,5,_OMC_LIT35_data);
#define _OMC_LIT35 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT35)
#define _OMC_LIT36_data ", condition="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT36,12,_OMC_LIT36_data);
#define _OMC_LIT36 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT36)
#define _OMC_LIT37_data ", immediate="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT37,12,_OMC_LIT37_data);
#define _OMC_LIT37 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT37)
#define _OMC_LIT38_data "true"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT38,4,_OMC_LIT38_data);
#define _OMC_LIT38 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT38)
#define _OMC_LIT39_data "false"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT39,5,_OMC_LIT39_data);
#define _OMC_LIT39 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT39)
#define _OMC_LIT40_data ", reset="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT40,8,_OMC_LIT40_data);
#define _OMC_LIT40 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT40)
#define _OMC_LIT41_data ", synchronize="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT41,14,_OMC_LIT41_data);
#define _OMC_LIT41 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT41)
#define _OMC_LIT42_data ", priority="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT42,11,_OMC_LIT42_data);
#define _OMC_LIT42 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT42)
#define _OMC_LIT43_data ")"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT43,1,_OMC_LIT43_data);
#define _OMC_LIT43 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT43)
#define _OMC_LIT44_data "initialState"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT44,12,_OMC_LIT44_data);
#define _OMC_LIT44 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT44)
#define _OMC_LIT45_data "transition"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT45,10,_OMC_LIT45_data);
#define _OMC_LIT45 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT45)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT46,1,5) {&DAE_VarDirection_BIDIR__desc,}};
#define _OMC_LIT46 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT46)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT47,1,5) {&DAE_VarParallelism_NON__PARALLEL__desc,}};
#define _OMC_LIT47 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT47)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT48,1,3) {&DAE_VarVisibility_PUBLIC__desc,}};
#define _OMC_LIT48 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT48)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT49,1,6) {&DAE_ConnectorType_NON__CONNECTOR__desc,}};
#define _OMC_LIT49 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT49)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT50,1,6) {&Absyn_InnerOuter_NOT__INNER__OUTER__desc,}};
#define _OMC_LIT50 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT50)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT51,1,4) {&DAE_VarKind_DISCRETE__desc,}};
#define _OMC_LIT51 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT51)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT52,2,3) {&DAE_Type_T__INTEGER__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT52 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT52)
#define _OMC_LIT53_data "nState"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT53,6,_OMC_LIT53_data);
#define _OMC_LIT53 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT53)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT54,1,5) {&DAE_VarKind_PARAM__desc,}};
#define _OMC_LIT54 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT54)
#define _OMC_LIT55_data "tFrom"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT55,5,_OMC_LIT55_data);
#define _OMC_LIT55 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT55)
#define _OMC_LIT56_data "tTo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT56,3,_OMC_LIT56_data);
#define _OMC_LIT56 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT56)
#define _OMC_LIT57_data "tImmediate"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT57,10,_OMC_LIT57_data);
#define _OMC_LIT57 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT57)
#define _OMC_LIT58_data "tReset"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT58,6,_OMC_LIT58_data);
#define _OMC_LIT58 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT58)
#define _OMC_LIT59_data "tSynchronize"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT59,12,_OMC_LIT59_data);
#define _OMC_LIT59 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT59)
#define _OMC_LIT60_data "tPriority"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT60,9,_OMC_LIT60_data);
#define _OMC_LIT60 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT60)
#define _OMC_LIT61_data "c"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT61,1,_OMC_LIT61_data);
#define _OMC_LIT61 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT61)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT62,2,6) {&DAE_Exp_BCONST__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT62 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT62)
#define _OMC_LIT63_data "active"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT63,6,_OMC_LIT63_data);
#define _OMC_LIT63 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT63)
#define _OMC_LIT64_data "reset"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT64,5,_OMC_LIT64_data);
#define _OMC_LIT64 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT64)
#define _OMC_LIT65_data "selectedState"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT65,13,_OMC_LIT65_data);
#define _OMC_LIT65 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT65)
#define _OMC_LIT66_data "selectedReset"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT66,13,_OMC_LIT66_data);
#define _OMC_LIT66 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT66)
#define _OMC_LIT67_data "fired"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT67,5,_OMC_LIT67_data);
#define _OMC_LIT67 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT67)
#define _OMC_LIT68_data "activeState"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT68,11,_OMC_LIT68_data);
#define _OMC_LIT68 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT68)
#define _OMC_LIT69_data "activeReset"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT69,11,_OMC_LIT69_data);
#define _OMC_LIT69 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT69)
#define _OMC_LIT70_data "nextState"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT70,9,_OMC_LIT70_data);
#define _OMC_LIT70 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT70)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT71,2,3) {&DAE_Exp_ICONST__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT71 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT71)
#define _OMC_LIT72_data "nextReset"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT72,9,_OMC_LIT72_data);
#define _OMC_LIT72 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT72)
#define _OMC_LIT73_data "activeResetStates"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT73,17,_OMC_LIT73_data);
#define _OMC_LIT73 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT73)
#define _OMC_LIT74_data "nextResetStates"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT74,15,_OMC_LIT74_data);
#define _OMC_LIT74 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT74)
#define _OMC_LIT75_data "finalStates"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT75,11,_OMC_LIT75_data);
#define _OMC_LIT75 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT75)
#define _OMC_LIT76_data "stateMachineInFinalState"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT76,24,_OMC_LIT76_data);
#define _OMC_LIT76 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT76)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT77,2,6) {&DAE_Exp_BCONST__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1))}};
#define _OMC_LIT77 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT77)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT78,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT3}};
#define _OMC_LIT78 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT78)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT79,2,3) {&DAE_Exp_ICONST__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1))}};
#define _OMC_LIT79 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT79)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT80,8,3) {&DAE_CallAttributes_CALL__ATTR__desc,_OMC_LIT52,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT8,_OMC_LIT9}};
#define _OMC_LIT80 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT80)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT81,2,32) {&DAE_Operator_EQUAL__desc,_OMC_LIT52}};
#define _OMC_LIT81 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT81)
#define _OMC_LIT82_data "max"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT82,3,_OMC_LIT82_data);
#define _OMC_LIT82 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT82)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT83,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT82}};
#define _OMC_LIT83 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT83)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT84,8,3) {&DAE_CallAttributes_CALL__ATTR__desc,_OMC_LIT52,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT8,_OMC_LIT9}};
#define _OMC_LIT84 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT84)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT85,2,30) {&DAE_Operator_GREATER__desc,_OMC_LIT52}};
#define _OMC_LIT85 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT85)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT86,1,1) {_OMC_LIT77}};
#define _OMC_LIT86 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT86)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT87,2,25) {&DAE_Operator_AND__desc,_OMC_LIT7}};
#define _OMC_LIT87 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT87)
#define _OMC_LIT88_data "$ticksInState"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT88,13,_OMC_LIT88_data);
#define _OMC_LIT88 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT88)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT89,2,3) {&DAE_Operator_ADD__desc,_OMC_LIT52}};
#define _OMC_LIT89 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT89)
#define _OMC_LIT90_data "$timeEnteredState"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT90,17,_OMC_LIT90_data);
#define _OMC_LIT90 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT90)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT91,2,4) {&DAE_Type_T__REAL__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT91 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT91)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT92,2,4) {&DAE_Exp_RCONST__desc,_OMC_LIT30}};
#define _OMC_LIT92 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT92)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT93,2,32) {&DAE_Operator_EQUAL__desc,_OMC_LIT7}};
#define _OMC_LIT93 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT93)
#define _OMC_LIT94_data "time"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT94,4,_OMC_LIT94_data);
#define _OMC_LIT94 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT94)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT95,4,4) {&DAE_ComponentRef_CREF__IDENT__desc,_OMC_LIT94,_OMC_LIT91,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT95 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT95)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT96,3,9) {&DAE_Exp_CREF__desc,_OMC_LIT95,_OMC_LIT91}};
#define _OMC_LIT96 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT96)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT97,1,3) {&DAE_ClockKind_INFERRED__CLOCK__desc,}};
#define _OMC_LIT97 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT97)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT98,2,7) {&DAE_Exp_CLKCONST__desc,_OMC_LIT97}};
#define _OMC_LIT98 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT98)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT99,2,1) {_OMC_LIT98,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT99 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT99)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT100,2,1) {_OMC_LIT96,_OMC_LIT99}};
#define _OMC_LIT100 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT100)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT101,8,3) {&DAE_CallAttributes_CALL__ATTR__desc,_OMC_LIT91,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT8,_OMC_LIT9}};
#define _OMC_LIT101 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT101)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT102,4,16) {&DAE_Exp_CALL__desc,_OMC_LIT12,_OMC_LIT100,_OMC_LIT101}};
#define _OMC_LIT102 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT102)
#define _OMC_LIT103_data "$timeInState"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT103,12,_OMC_LIT103_data);
#define _OMC_LIT103 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT103)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT104,2,4) {&DAE_Operator_SUB__desc,_OMC_LIT91}};
#define _OMC_LIT104 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT104)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT105,2,26) {&DAE_Operator_OR__desc,_OMC_LIT7}};
#define _OMC_LIT105 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT105)
#define _OMC_LIT106_data "init"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT106,4,_OMC_LIT106_data);
#define _OMC_LIT106 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT106)
#define _OMC_LIT107_data "_previous"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT107,9,_OMC_LIT107_data);
#define _OMC_LIT107 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT107)
#define _OMC_LIT108_data "StateMachineFlatten.traversingSubsPreviousCref: cr: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT108,52,_OMC_LIT108_data);
#define _OMC_LIT108 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT108)
#define _OMC_LIT109_data ", cref: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT109,8,_OMC_LIT109_data);
#define _OMC_LIT109 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT109)
#define _OMC_LIT110_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT110,1,_OMC_LIT110_data);
#define _OMC_LIT110 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT110)
#define _OMC_LIT111_data "The LHS of equations in state machines needs to be a component reference, e.g., x = .., or its derivative, e.g., der(x) = .."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT111,124,_OMC_LIT111_data);
#define _OMC_LIT111 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT111)
#define _OMC_LIT112_data "The LHS of equations in state machines needs to be a component reference"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT112,72,_OMC_LIT112_data);
#define _OMC_LIT112 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT112)
#define _OMC_LIT113_data "Variable "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT113,9,_OMC_LIT113_data);
#define _OMC_LIT113 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT113)
#define _OMC_LIT114_data " lacks start value. Defaulting to start=0.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT114,43,_OMC_LIT114_data);
#define _OMC_LIT114 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT114)
#define _OMC_LIT115_data " lacks start value. Defaulting to start=false.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT115,47,_OMC_LIT115_data);
#define _OMC_LIT115 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT115)
#define _OMC_LIT116_data " lacks start value. Defaulting to start=\"\".\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT116,44,_OMC_LIT116_data);
#define _OMC_LIT116 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT116)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT117,2,5) {&DAE_Exp_SCONST__desc,_OMC_LIT29}};
#define _OMC_LIT117 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT117)
#define _OMC_LIT118_data " lacks start value.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT118,20,_OMC_LIT118_data);
#define _OMC_LIT118 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT118)
#define _OMC_LIT119_data "Encountered elsewhen part in a when clause of a clocked state machine.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT119,71,_OMC_LIT119_data);
#define _OMC_LIT119 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT119)
#define _OMC_LIT120_data "Internal compiler error: StateMachineFlatten.isPreviousAppliedToVar(..) called with unexpected argument.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT120,105,_OMC_LIT120_data);
#define _OMC_LIT120 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT120)
#define _OMC_LIT121_data "Internal compiler error: StateMachineFlatten.isVarAtLHS(..) called with unexpected argument.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT121,93,_OMC_LIT121_data);
#define _OMC_LIT121 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT121)
#define _OMC_LIT122_data "Couldn't find variable declaration matching to cref "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT122,52,_OMC_LIT122_data);
#define _OMC_LIT122 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT122)
#define _OMC_LIT123_data "_der$"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT123,5,_OMC_LIT123_data);
#define _OMC_LIT123 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT123)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT124,1,3) {&DAE_VarKind_VARIABLE__desc,}};
#define _OMC_LIT124 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT124)
#define _OMC_LIT125_data "Currently, only equations in state machines with a LHS component reference, e.g., x=.., are supported"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT125,101,_OMC_LIT125_data);
#define _OMC_LIT125 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT125)
#define _OMC_LIT126_data "Currently, only equations in state machines with a LHS component reference, e.g., x=.., or its derivative, e.g., der(x)=.., are supported"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT126,137,_OMC_LIT126_data);
#define _OMC_LIT126 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT126)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT127,2,0) {MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT127 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT127)
#define _OMC_LIT128_data "Internal compiler error: StateMachineFlatten.addStateActivationAndReset(..) called with unexpected argument.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT128,109,_OMC_LIT128_data);
#define _OMC_LIT128 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT128)
#define _OMC_LIT129_data "ticksInState"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT129,12,_OMC_LIT129_data);
#define _OMC_LIT129 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT129)
#define _OMC_LIT130_data "Found 'ticksInState()' within a state of an hierarchical state machine."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT130,71,_OMC_LIT130_data);
#define _OMC_LIT130 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT130)
#define _OMC_LIT131_data "timeInState"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT131,11,_OMC_LIT131_data);
#define _OMC_LIT131 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT131)
#define _OMC_LIT132_data "Found 'timeInState()' within a state of an hierarchical state machine."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT132,70,_OMC_LIT132_data);
#define _OMC_LIT132 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT132)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT133,1,5) {&DAE_AvlTreePathFunction_Tree_EMPTY__desc,}};
#define _OMC_LIT133 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT133)
#define _OMC_LIT134_data "Internal compiler error. Unexpected elements in flat state machine."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT134,67,_OMC_LIT134_data);
#define _OMC_LIT134 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT134)
#define _OMC_LIT135_data "Internal compiler error: Handling of elementLst != 1 not supported\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT135,67,_OMC_LIT135_data);
#define _OMC_LIT135 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT135)
#include "util/modelica.h"
#include "StateMachineFlatten_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_traversingSubsXForSampleX(threadData_t *threadData, modelica_metatype _inExp, modelica_integer _inHitCount, modelica_integer *out_outHitCount);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_traversingSubsXForSampleX(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inHitCount, modelica_metatype *out_outHitCount);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_traversingSubsXForSampleX,2,0) {(void*) boxptr_StateMachineFlatten_traversingSubsXForSampleX,0}};
#define boxvar_StateMachineFlatten_traversingSubsXForSampleX MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_traversingSubsXForSampleX)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_traversingSubsPreForPrevious(threadData_t *threadData, modelica_metatype _inExp, modelica_integer _inHitCount, modelica_integer *out_outHitCount);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_traversingSubsPreForPrevious(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inHitCount, modelica_metatype *out_outHitCount);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_traversingSubsPreForPrevious,2,0) {(void*) boxptr_StateMachineFlatten_traversingSubsPreForPrevious,0}};
#define boxvar_StateMachineFlatten_traversingSubsPreForPrevious MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_traversingSubsPreForPrevious)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_extractSmOfExps(threadData_t *threadData, modelica_metatype _inElem, modelica_string _inLastIdent);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_extractSmOfExps,2,0) {(void*) boxptr_StateMachineFlatten_extractSmOfExps,0}};
#define boxvar_StateMachineFlatten_extractSmOfExps MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_extractSmOfExps)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_wrapHack(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _inElementLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_wrapHack,2,0) {(void*) boxptr_StateMachineFlatten_wrapHack,0}};
#define boxvar_StateMachineFlatten_wrapHack MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_wrapHack)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_sMCompEqualsRef(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inCref);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_sMCompEqualsRef(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inCref);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_sMCompEqualsRef,2,0) {(void*) boxptr_StateMachineFlatten_sMCompEqualsRef,0}};
#define boxvar_StateMachineFlatten_sMCompEqualsRef MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_sMCompEqualsRef)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isVar(threadData_t *threadData, modelica_metatype _inElement);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_isVar(threadData_t *threadData, modelica_metatype _inElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_isVar,2,0) {(void*) boxptr_StateMachineFlatten_isVar,0}};
#define boxvar_StateMachineFlatten_isVar MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_isVar)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isPreOrPreviousEquation(threadData_t *threadData, modelica_metatype _inElement);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_isPreOrPreviousEquation(threadData_t *threadData, modelica_metatype _inElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_isPreOrPreviousEquation,2,0) {(void*) boxptr_StateMachineFlatten_isPreOrPreviousEquation,0}};
#define boxvar_StateMachineFlatten_isPreOrPreviousEquation MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_isPreOrPreviousEquation)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isEquationOrWhenEquation(threadData_t *threadData, modelica_metatype _inElement);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_isEquationOrWhenEquation(threadData_t *threadData, modelica_metatype _inElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_isEquationOrWhenEquation,2,0) {(void*) boxptr_StateMachineFlatten_isEquationOrWhenEquation,0}};
#define boxvar_StateMachineFlatten_isEquationOrWhenEquation MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_isEquationOrWhenEquation)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isEquation(threadData_t *threadData, modelica_metatype _inElement);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_isEquation(threadData_t *threadData, modelica_metatype _inElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_isEquation,2,0) {(void*) boxptr_StateMachineFlatten_isEquation,0}};
#define boxvar_StateMachineFlatten_isEquation MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_isEquation)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isInitialState(threadData_t *threadData, modelica_metatype _inElement);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_isInitialState(threadData_t *threadData, modelica_metatype _inElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_isInitialState,2,0) {(void*) boxptr_StateMachineFlatten_isInitialState,0}};
#define boxvar_StateMachineFlatten_isInitialState MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_isInitialState)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isTransition(threadData_t *threadData, modelica_metatype _inElement);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_isTransition(threadData_t *threadData, modelica_metatype _inElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_isTransition,2,0) {(void*) boxptr_StateMachineFlatten_isTransition,0}};
#define boxvar_StateMachineFlatten_isTransition MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_isTransition)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isSMComp(threadData_t *threadData, modelica_metatype _inElement);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_isSMComp(threadData_t *threadData, modelica_metatype _inElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_isSMComp,2,0) {(void*) boxptr_StateMachineFlatten_isSMComp,0}};
#define boxvar_StateMachineFlatten_isSMComp MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_isSMComp)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isFlatSm(threadData_t *threadData, modelica_metatype _inElement);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_isFlatSm(threadData_t *threadData, modelica_metatype _inElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_isFlatSm,2,0) {(void*) boxptr_StateMachineFlatten_isFlatSm,0}};
#define boxvar_StateMachineFlatten_isFlatSm MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_isFlatSm)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_createTransition(threadData_t *threadData, modelica_metatype _transitionElem, modelica_metatype _states);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_createTransition,2,0) {(void*) boxptr_StateMachineFlatten_createTransition,0}};
#define boxvar_StateMachineFlatten_createTransition MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_createTransition)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_priorityLt(threadData_t *threadData, modelica_metatype _inTrans1, modelica_metatype _inTrans2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_priorityLt(threadData_t *threadData, modelica_metatype _inTrans1, modelica_metatype _inTrans2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_priorityLt,2,0) {(void*) boxptr_StateMachineFlatten_priorityLt,0}};
#define boxvar_StateMachineFlatten_priorityLt MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_priorityLt)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_extractCondtionFromTransition(threadData_t *threadData, modelica_metatype _trans);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_extractCondtionFromTransition,2,0) {(void*) boxptr_StateMachineFlatten_extractCondtionFromTransition,0}};
#define boxvar_StateMachineFlatten_extractCondtionFromTransition MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_extractCondtionFromTransition)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_createTandC(threadData_t *threadData, modelica_metatype _inSMComps, modelica_metatype _inTransitions, modelica_metatype *out_c);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_createTandC,2,0) {(void*) boxptr_StateMachineFlatten_createTandC,0}};
#define boxvar_StateMachineFlatten_createTandC MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_createTandC)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_createVarWithStartValue(threadData_t *threadData, modelica_metatype _componentRef, modelica_metatype _kind, modelica_metatype _ty, modelica_metatype _startExp, modelica_metatype _dims);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_createVarWithStartValue,2,0) {(void*) boxptr_StateMachineFlatten_createVarWithStartValue,0}};
#define boxvar_StateMachineFlatten_createVarWithStartValue MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_createVarWithStartValue)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_createVarWithDefaults(threadData_t *threadData, modelica_metatype _componentRef, modelica_metatype _kind, modelica_metatype _ty, modelica_metatype _dims);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_createVarWithDefaults,2,0) {(void*) boxptr_StateMachineFlatten_createVarWithDefaults,0}};
#define boxvar_StateMachineFlatten_createVarWithDefaults MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_createVarWithDefaults)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_qCref(threadData_t *threadData, modelica_string _ident, modelica_metatype _identType, modelica_metatype _subscriptLst, modelica_metatype _componentRef);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_qCref,2,0) {(void*) boxptr_StateMachineFlatten_qCref,0}};
#define boxvar_StateMachineFlatten_qCref MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_qCref)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_basicFlatSmSemantics(threadData_t *threadData, modelica_string _ident, modelica_metatype _q, modelica_metatype _inTransitions);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_basicFlatSmSemantics,2,0) {(void*) boxptr_StateMachineFlatten_basicFlatSmSemantics,0}};
#define boxvar_StateMachineFlatten_basicFlatSmSemantics MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_basicFlatSmSemantics)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_setVarFixedStartValue(threadData_t *threadData, modelica_metatype _inVar, modelica_metatype _inExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_setVarFixedStartValue,2,0) {(void*) boxptr_StateMachineFlatten_setVarFixedStartValue,0}};
#define boxvar_StateMachineFlatten_setVarFixedStartValue MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_setVarFixedStartValue)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_createActiveIndicator(threadData_t *threadData, modelica_metatype _stateRef, modelica_metatype _preRef, modelica_integer _i, modelica_metatype *out_eqn);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_createActiveIndicator(threadData_t *threadData, modelica_metatype _stateRef, modelica_metatype _preRef, modelica_metatype _i, modelica_metatype *out_eqn);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_createActiveIndicator,2,0) {(void*) boxptr_StateMachineFlatten_createActiveIndicator,0}};
#define boxvar_StateMachineFlatten_createActiveIndicator MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_createActiveIndicator)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_createTicksInStateIndicator(threadData_t *threadData, modelica_metatype _stateRef, modelica_metatype _stateActiveRef, modelica_metatype *out_ticksInStateEqn);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_createTicksInStateIndicator,2,0) {(void*) boxptr_StateMachineFlatten_createTicksInStateIndicator,0}};
#define boxvar_StateMachineFlatten_createTicksInStateIndicator MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_createTicksInStateIndicator)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_createTimeEnteredStateIndicator(threadData_t *threadData, modelica_metatype _stateRef, modelica_metatype _stateActiveRef, modelica_metatype *out_timeEnteredStateEqn);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_createTimeEnteredStateIndicator,2,0) {(void*) boxptr_StateMachineFlatten_createTimeEnteredStateIndicator,0}};
#define boxvar_StateMachineFlatten_createTimeEnteredStateIndicator MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_createTimeEnteredStateIndicator)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_createTimeInStateIndicator(threadData_t *threadData, modelica_metatype _stateRef, modelica_metatype _stateActiveRef, modelica_metatype _timeEnteredStateVar, modelica_metatype *out_timeInStateEqn);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_createTimeInStateIndicator,2,0) {(void*) boxptr_StateMachineFlatten_createTimeInStateIndicator,0}};
#define boxvar_StateMachineFlatten_createTimeInStateIndicator MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_createTimeInStateIndicator)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_addPropagationEquations(threadData_t *threadData, modelica_metatype _inFlatSmSemantics, modelica_metatype _inEnclosingStateCrefOption, modelica_metatype _inEnclosingFlatSmSemanticsOption);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_addPropagationEquations,2,0) {(void*) boxptr_StateMachineFlatten_addPropagationEquations,0}};
#define boxvar_StateMachineFlatten_addPropagationEquations MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_addPropagationEquations)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_getStartAttrOption(threadData_t *threadData, modelica_metatype _inVarAttrOpt);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_getStartAttrOption,2,0) {(void*) boxptr_StateMachineFlatten_getStartAttrOption,0}};
#define boxvar_StateMachineFlatten_getStartAttrOption MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_getStartAttrOption)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_traversingSubsPreviousCrefs(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inCrefsHit, modelica_boolean *out_cont, modelica_metatype *out_outCrefsHit);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_traversingSubsPreviousCrefs(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inCrefsHit, modelica_metatype *out_cont, modelica_metatype *out_outCrefsHit);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_traversingSubsPreviousCrefs,2,0) {(void*) boxptr_StateMachineFlatten_traversingSubsPreviousCrefs,0}};
#define boxvar_StateMachineFlatten_traversingSubsPreviousCrefs MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_traversingSubsPreviousCrefs)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_traversingSubsPreviousCref(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inCrefHit, modelica_boolean *out_cont, modelica_metatype *out_outCrefHit);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_traversingSubsPreviousCref(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inCrefHit, modelica_metatype *out_cont, modelica_metatype *out_outCrefHit);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_traversingSubsPreviousCref,2,0) {(void*) boxptr_StateMachineFlatten_traversingSubsPreviousCref,0}};
#define boxvar_StateMachineFlatten_traversingSubsPreviousCref MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_traversingSubsPreviousCref)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_wrapInStateActivationConditionalCT(threadData_t *threadData, modelica_metatype _inEqn, modelica_metatype _inStateCref);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_wrapInStateActivationConditionalCT,2,0) {(void*) boxptr_StateMachineFlatten_wrapInStateActivationConditionalCT,0}};
#define boxvar_StateMachineFlatten_wrapInStateActivationConditionalCT MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_wrapInStateActivationConditionalCT)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_wrapInStateActivationConditional(threadData_t *threadData, modelica_metatype _inEqn, modelica_metatype _inStateCref, modelica_boolean _isResetEquation);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_wrapInStateActivationConditional(threadData_t *threadData, modelica_metatype _inEqn, modelica_metatype _inStateCref, modelica_metatype _isResetEquation);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_wrapInStateActivationConditional,2,0) {(void*) boxptr_StateMachineFlatten_wrapInStateActivationConditional,0}};
#define boxvar_StateMachineFlatten_wrapInStateActivationConditional MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_wrapInStateActivationConditional)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_createResetEquation(threadData_t *threadData, modelica_metatype _inLHSCref, modelica_metatype _inLHSty, modelica_metatype _inStateCref, modelica_metatype _inEnclosingFlatSmSemantics, modelica_metatype _crToExpOpt);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_createResetEquation,2,0) {(void*) boxptr_StateMachineFlatten_createResetEquation,0}};
#define boxvar_StateMachineFlatten_createResetEquation MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_createResetEquation)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isCrefInVar(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inCref);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_isCrefInVar(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inCref);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_isCrefInVar,2,0) {(void*) boxptr_StateMachineFlatten_isCrefInVar,0}};
#define boxvar_StateMachineFlatten_isCrefInVar MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_isCrefInVar)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_createResetEquationCT(threadData_t *threadData, modelica_metatype _inLHSCref, modelica_metatype _inLHSty, modelica_metatype _inStateCref, modelica_metatype _inEnclosingFlatSmSemantics, modelica_metatype _crToExpOpt);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_createResetEquationCT,2,0) {(void*) boxptr_StateMachineFlatten_createResetEquationCT,0}};
#define boxvar_StateMachineFlatten_createResetEquationCT MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_createResetEquationCT)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_traversingFindPreviousCref(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inCrefHit, modelica_boolean *out_cont, modelica_metatype *out_outCrefHit);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_traversingFindPreviousCref(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inCrefHit, modelica_metatype *out_cont, modelica_metatype *out_outCrefHit);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_traversingFindPreviousCref,2,0) {(void*) boxptr_StateMachineFlatten_traversingFindPreviousCref,0}};
#define boxvar_StateMachineFlatten_traversingFindPreviousCref MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_traversingFindPreviousCref)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isPreviousAppliedToVar(threadData_t *threadData, modelica_metatype _eqn, modelica_metatype _var);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_isPreviousAppliedToVar(threadData_t *threadData, modelica_metatype _eqn, modelica_metatype _var);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_isPreviousAppliedToVar,2,0) {(void*) boxptr_StateMachineFlatten_isPreviousAppliedToVar,0}};
#define boxvar_StateMachineFlatten_isPreviousAppliedToVar MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_isPreviousAppliedToVar)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isVarAtLHS(threadData_t *threadData, modelica_metatype _eqn, modelica_metatype _var);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_isVarAtLHS(threadData_t *threadData, modelica_metatype _eqn, modelica_metatype _var);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_isVarAtLHS,2,0) {(void*) boxptr_StateMachineFlatten_isVarAtLHS,0}};
#define boxvar_StateMachineFlatten_isVarAtLHS MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_isVarAtLHS)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_addStateActivationAndReset1(threadData_t *threadData, modelica_metatype _inEqn, modelica_metatype _inEnclosingSMComp, modelica_metatype _inEnclosingFlatSmSemantics, modelica_metatype _crToExpOpt, modelica_metatype _accEqnsVars);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_addStateActivationAndReset1,2,0) {(void*) boxptr_StateMachineFlatten_addStateActivationAndReset1,0}};
#define boxvar_StateMachineFlatten_addStateActivationAndReset1 MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_addStateActivationAndReset1)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_addStateActivationAndReset(threadData_t *threadData, modelica_metatype _inEqn, modelica_metatype _inEnclosingSMComp, modelica_metatype _inEnclosingFlatSmSemantics, modelica_metatype _crToExpOpt, modelica_metatype _accEqnsVars);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_addStateActivationAndReset,2,0) {(void*) boxptr_StateMachineFlatten_addStateActivationAndReset,0}};
#define boxvar_StateMachineFlatten_addStateActivationAndReset MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_addStateActivationAndReset)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_smCompToDataFlow(threadData_t *threadData, modelica_metatype _inSMComp, modelica_metatype _inEnclosingFlatSmSemantics, modelica_metatype _accElems);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_smCompToDataFlow,2,0) {(void*) boxptr_StateMachineFlatten_smCompToDataFlow,0}};
#define boxvar_StateMachineFlatten_smCompToDataFlow MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_smCompToDataFlow)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_traversingSubsXInState(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inXSubstHit, modelica_boolean *out_cont, modelica_metatype *out_outXSubstHit);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_traversingSubsXInState(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inXSubstHit, modelica_metatype *out_cont, modelica_metatype *out_outXSubstHit);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_traversingSubsXInState,2,0) {(void*) boxptr_StateMachineFlatten_traversingSubsXInState,0}};
#define boxvar_StateMachineFlatten_traversingSubsXInState MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_traversingSubsXInState)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_smeqsSubsXInState(threadData_t *threadData, modelica_metatype _inSmeqs, modelica_metatype _initialStateComp, modelica_integer _i, modelica_integer _nTransitions, modelica_metatype _substExp, modelica_string _xInState);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_smeqsSubsXInState(threadData_t *threadData, modelica_metatype _inSmeqs, modelica_metatype _initialStateComp, modelica_metatype _i, modelica_metatype _nTransitions, modelica_metatype _substExp, modelica_metatype _xInState);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_smeqsSubsXInState,2,0) {(void*) boxptr_StateMachineFlatten_smeqsSubsXInState,0}};
#define boxvar_StateMachineFlatten_smeqsSubsXInState MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_smeqsSubsXInState)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_elabXInStateOps(threadData_t *threadData, modelica_metatype _inFlatSmSemantics, modelica_metatype _inEnclosingStateCrefOption);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_elabXInStateOps,2,0) {(void*) boxptr_StateMachineFlatten_elabXInStateOps,0}};
#define boxvar_StateMachineFlatten_elabXInStateOps MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_elabXInStateOps)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_traversingSubsTicksInState(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inCref_HitCount, modelica_metatype *out_outCref_HitCount);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_traversingSubsTicksInState,2,0) {(void*) boxptr_StateMachineFlatten_traversingSubsTicksInState,0}};
#define boxvar_StateMachineFlatten_traversingSubsTicksInState MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_traversingSubsTicksInState)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_elabXInStateOps__CT(threadData_t *threadData, modelica_metatype _inSmComp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_elabXInStateOps__CT,2,0) {(void*) boxptr_StateMachineFlatten_elabXInStateOps__CT,0}};
#define boxvar_StateMachineFlatten_elabXInStateOps__CT MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_elabXInStateOps__CT)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_flatSmToDataFlow(threadData_t *threadData, modelica_metatype _inFlatSm, modelica_metatype _inEnclosingStateCrefOption, modelica_metatype _inEnclosingFlatSmSemanticsOption, modelica_metatype _accElems);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_flatSmToDataFlow,2,0) {(void*) boxptr_StateMachineFlatten_flatSmToDataFlow,0}};
#define boxvar_StateMachineFlatten_flatSmToDataFlow MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_flatSmToDataFlow)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_traversingSubsActiveState(threadData_t *threadData, modelica_metatype _inExp, modelica_integer _inHitCount, modelica_integer *out_outHitCount);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_traversingSubsActiveState(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inHitCount, modelica_metatype *out_outHitCount);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StateMachineFlatten_traversingSubsActiveState,2,0) {(void*) boxptr_StateMachineFlatten_traversingSubsActiveState,0}};
#define boxvar_StateMachineFlatten_traversingSubsActiveState MMC_REFSTRUCTLIT(boxvar_lit_StateMachineFlatten_traversingSubsActiveState)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_traversingSubsXForSampleX(threadData_t *threadData, modelica_metatype _inExp, modelica_integer _inHitCount, modelica_integer *out_outHitCount)
{
modelica_metatype _outExp = NULL;
modelica_integer _outHitCount;
modelica_integer tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _expX = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (6 != MMC_STRLEN(tmpMeta7) || strcmp(MMC_STRINGDATA(_OMC_LIT0), MMC_STRINGDATA(tmpMeta7)) != 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
if (listEmpty(tmpMeta10)) goto tmp3_end;
tmpMeta11 = MMC_CAR(tmpMeta10);
tmpMeta12 = MMC_CDR(tmpMeta10);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,4,1) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,0,0) == 0) goto tmp3_end;
if (!listEmpty(tmpMeta12)) goto tmp3_end;
_expX = tmpMeta9;
tmpMeta[0+0] = _expX;
tmp1_c1 = ((modelica_integer) 1) + _inHitCount;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _inExp;
tmp1_c1 = _inHitCount;
goto tmp3_done;
}
}
goto tmp3_end;
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
_outHitCount = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_outHitCount) { *out_outHitCount = _outHitCount; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_traversingSubsXForSampleX(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inHitCount, modelica_metatype *out_outHitCount)
{
modelica_integer tmp1;
modelica_integer _outHitCount;
modelica_metatype _outExp = NULL;
tmp1 = mmc_unbox_integer(_inHitCount);
_outExp = omc_StateMachineFlatten_traversingSubsXForSampleX(threadData, _inExp, tmp1, &_outHitCount);
if (out_outHitCount) { *out_outHitCount = mmc_mk_icon(_outHitCount); }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_traversingSubsPreForPrevious(threadData_t *threadData, modelica_metatype _inExp, modelica_integer _inHitCount, modelica_integer *out_outHitCount)
{
modelica_metatype _outExp = NULL;
modelica_integer _outHitCount;
modelica_integer tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _expLst = NULL;
modelica_metatype _attr = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (8 != MMC_STRLEN(tmpMeta7) || strcmp(MMC_STRINGDATA(_OMC_LIT3), MMC_STRINGDATA(tmpMeta7)) != 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_expLst = tmpMeta8;
_attr = tmpMeta9;
tmpMeta10 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT2, _expLst, _attr);
tmpMeta[0+0] = tmpMeta10;
tmp1_c1 = ((modelica_integer) 1) + _inHitCount;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _inExp;
tmp1_c1 = _inHitCount;
goto tmp3_done;
}
}
goto tmp3_end;
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
_outHitCount = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_outHitCount) { *out_outHitCount = _outHitCount; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_traversingSubsPreForPrevious(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inHitCount, modelica_metatype *out_outHitCount)
{
modelica_integer tmp1;
modelica_integer _outHitCount;
modelica_metatype _outExp = NULL;
tmp1 = mmc_unbox_integer(_inHitCount);
_outExp = omc_StateMachineFlatten_traversingSubsPreForPrevious(threadData, _inExp, tmp1, &_outHitCount);
if (out_outHitCount) { *out_outHitCount = mmc_mk_icon(_outHitCount); }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_extractSmOfExps(threadData_t *threadData, modelica_metatype _inElem, modelica_string _inLastIdent)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElem;
{
modelica_metatype _exp = NULL;
modelica_metatype _cref = NULL;
modelica_string _firstIdent = NULL;
modelica_string _lastIdent = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_boolean tmp9;
modelica_boolean tmp10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_exp = tmpMeta6;
tmpMeta7 = _exp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,6,2) == 0) goto goto_2;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_cref = tmpMeta8;
_firstIdent = omc_ComponentReference_crefFirstIdent(threadData, _cref);
tmp9 = (stringEqual(_firstIdent, _OMC_LIT4));
if (1 != tmp9) goto goto_2;
_lastIdent = omc_ComponentReference_crefLastIdent(threadData, _cref);
tmp10 = (stringEqual(_lastIdent, _inLastIdent));
if (1 != tmp10) goto goto_2;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_wrapHack(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _inElementLst)
{
modelica_metatype _outElementLst = NULL;
modelica_integer _nOfSubstitutions;
modelica_metatype _eqnLst = NULL;
modelica_metatype _otherLst = NULL;
modelica_metatype _whenEq = NULL;
modelica_metatype _cond1 = NULL;
modelica_metatype _cond2 = NULL;
modelica_metatype _condition = NULL;
modelica_metatype _condLst = NULL;
modelica_metatype _tArrayBool = NULL;
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
_cond1 = _OMC_LIT11;
tmpMeta2 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(omc_Flags_getConfigReal(threadData, _OMC_LIT19)));
tmpMeta3 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(omc_Flags_getConfigReal(threadData, _OMC_LIT19)));
tmpMeta1 = mmc_mk_cons(tmpMeta2, mmc_mk_cons(tmpMeta3, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta4 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT12, tmpMeta1, _OMC_LIT10);
_cond2 = tmpMeta4;
_tArrayBool = _OMC_LIT22;
if(omc_Flags_getConfigBool(threadData, _OMC_LIT28))
{
_condLst = omc_List_filterMap1(threadData, _inElementLst, boxvar_StateMachineFlatten_extractSmOfExps, _OMC_LIT23);
_eqnLst = omc_List_extractOnTrue(threadData, _inElementLst, boxvar_StateMachineFlatten_isPreOrPreviousEquation ,&_otherLst);
tmpMeta5 = mmc_mk_cons(_cond1, _condLst);
tmpMeta6 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _tArrayBool, mmc_mk_boolean(1), tmpMeta5);
_condition = tmpMeta6;
}
else
{
_eqnLst = omc_List_extractOnTrue(threadData, _inElementLst, boxvar_StateMachineFlatten_isEquation ,&_otherLst);
tmpMeta7 = mmc_mk_cons(_cond1, mmc_mk_cons(_cond2, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta8 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _tArrayBool, mmc_mk_boolean(1), tmpMeta7);
_condition = tmpMeta8;
}
tmpMeta9 = mmc_mk_box5(13, &DAE_Element_WHEN__EQUATION__desc, _condition, _eqnLst, mmc_mk_none(), _OMC_LIT33);
_whenEq = tmpMeta9;
tmpMeta10 = mmc_mk_cons(_whenEq, MMC_REFSTRUCTLIT(mmc_nil));
_outElementLst = listAppend(_otherLst, tmpMeta10);
_return: OMC_LABEL_UNUSED
return _outElementLst;
}
DLLExport
modelica_string omc_StateMachineFlatten_dumpTransitionStr(threadData_t *threadData, modelica_metatype _transition)
{
modelica_string _transitionStr = NULL;
modelica_integer _from;
modelica_integer _to;
modelica_metatype _condition = NULL;
modelica_boolean _immediate;
modelica_boolean _reset;
modelica_boolean _synchronize;
modelica_integer _priority;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_integer tmp8;
modelica_metatype tmpMeta9;
modelica_integer tmp10;
modelica_metatype tmpMeta11;
modelica_integer tmp12;
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
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _transition;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmp3 = mmc_unbox_integer(tmpMeta2);
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp5 = mmc_unbox_integer(tmpMeta4);
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 5));
tmp8 = mmc_unbox_integer(tmpMeta7);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 6));
tmp10 = mmc_unbox_integer(tmpMeta9);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 7));
tmp12 = mmc_unbox_integer(tmpMeta11);
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 8));
tmp14 = mmc_unbox_integer(tmpMeta13);
_from = tmp3;
_to = tmp5;
_condition = tmpMeta6;
_immediate = tmp8;
_reset = tmp10;
_synchronize = tmp12;
_priority = tmp14;
tmpMeta15 = stringAppend(_OMC_LIT34,intString(_from));
tmpMeta16 = stringAppend(tmpMeta15,_OMC_LIT35);
tmpMeta17 = stringAppend(tmpMeta16,intString(_to));
tmpMeta18 = stringAppend(tmpMeta17,_OMC_LIT36);
tmpMeta19 = stringAppend(tmpMeta18,omc_ExpressionDump_printExpStr(threadData, _condition));
tmpMeta20 = stringAppend(tmpMeta19,_OMC_LIT37);
tmpMeta21 = stringAppend(tmpMeta20,(_immediate?_OMC_LIT38:_OMC_LIT39));
tmpMeta22 = stringAppend(tmpMeta21,_OMC_LIT40);
tmpMeta23 = stringAppend(tmpMeta22,(_reset?_OMC_LIT38:_OMC_LIT39));
tmpMeta24 = stringAppend(tmpMeta23,_OMC_LIT41);
tmpMeta25 = stringAppend(tmpMeta24,(_synchronize?_OMC_LIT38:_OMC_LIT39));
tmpMeta26 = stringAppend(tmpMeta25,_OMC_LIT42);
tmpMeta27 = stringAppend(tmpMeta26,intString(_priority));
tmpMeta28 = stringAppend(tmpMeta27,_OMC_LIT43);
_transitionStr = tmpMeta28;
_return: OMC_LABEL_UNUSED
return _transitionStr;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_sMCompEqualsRef(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inCref)
{
modelica_boolean _result;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
modelica_metatype _cref = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,29,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cref = tmpMeta6;
if (!omc_ComponentReference_crefEqual(threadData, _cref, _inCref)) goto tmp3_end;
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
_result = tmp1;
_return: OMC_LABEL_UNUSED
return _result;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_sMCompEqualsRef(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inCref)
{
modelica_boolean _result;
modelica_metatype out_result;
_result = omc_StateMachineFlatten_sMCompEqualsRef(threadData, _inElement, _inCref);
out_result = mmc_mk_icon(_result);
return out_result;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isVar(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _result;
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
_result = tmp1;
_return: OMC_LABEL_UNUSED
return _result;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_isVar(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _result;
modelica_metatype out_result;
_result = omc_StateMachineFlatten_isVar(threadData, _inElement);
out_result = mmc_mk_icon(_result);
return out_result;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isPreOrPreviousEquation(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _result;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
modelica_metatype _exp = NULL;
modelica_metatype _scalar = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_exp = tmpMeta6;
_scalar = tmpMeta7;
tmp1 = (((omc_Expression_expHasPre(threadData, _exp) || omc_Expression_expHasPre(threadData, _scalar)) || omc_Expression_expHasPrevious(threadData, _exp)) || omc_Expression_expHasPrevious(threadData, _scalar));
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
_result = tmp1;
_return: OMC_LABEL_UNUSED
return _result;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_isPreOrPreviousEquation(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _result;
modelica_metatype out_result;
_result = omc_StateMachineFlatten_isPreOrPreviousEquation(threadData, _inElement);
out_result = mmc_mk_icon(_result);
return out_result;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isEquationOrWhenEquation(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _result;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 6: {
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
_result = tmp1;
_return: OMC_LABEL_UNUSED
return _result;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_isEquationOrWhenEquation(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _result;
modelica_metatype out_result;
_result = omc_StateMachineFlatten_isEquationOrWhenEquation(threadData, _inElement);
out_result = mmc_mk_icon(_result);
return out_result;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isEquation(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _result;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,3) == 0) goto tmp3_end;
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
_result = tmp1;
_return: OMC_LABEL_UNUSED
return _result;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_isEquation(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _result;
modelica_metatype out_result;
_result = omc_StateMachineFlatten_isEquation(threadData, _inElement);
out_result = mmc_mk_icon(_result);
return out_result;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isInitialState(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _result;
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,13,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (12 != MMC_STRLEN(tmpMeta8) || strcmp(MMC_STRINGDATA(_OMC_LIT44), MMC_STRINGDATA(tmpMeta8)) != 0) goto tmp3_end;
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
_result = tmp1;
_return: OMC_LABEL_UNUSED
return _result;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_isInitialState(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _result;
modelica_metatype out_result;
_result = omc_StateMachineFlatten_isInitialState(threadData, _inElement);
out_result = mmc_mk_icon(_result);
return out_result;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isTransition(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _result;
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,13,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (10 != MMC_STRLEN(tmpMeta8) || strcmp(MMC_STRINGDATA(_OMC_LIT45), MMC_STRINGDATA(tmpMeta8)) != 0) goto tmp3_end;
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
_result = tmp1;
_return: OMC_LABEL_UNUSED
return _result;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_isTransition(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _result;
modelica_metatype out_result;
_result = omc_StateMachineFlatten_isTransition(threadData, _inElement);
out_result = mmc_mk_icon(_result);
return out_result;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isSMComp(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outResult;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,29,2) == 0) goto tmp3_end;
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
_outResult = tmp1;
_return: OMC_LABEL_UNUSED
return _outResult;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_isSMComp(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outResult;
modelica_metatype out_outResult;
_outResult = omc_StateMachineFlatten_isSMComp(threadData, _inElement);
out_outResult = mmc_mk_icon(_outResult);
return out_outResult;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isFlatSm(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outResult;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,28,2) == 0) goto tmp3_end;
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
_outResult = tmp1;
_return: OMC_LABEL_UNUSED
return _outResult;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_isFlatSm(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outResult;
modelica_metatype out_outResult;
_outResult = omc_StateMachineFlatten_isFlatSm(threadData, _inElement);
out_outResult = mmc_mk_icon(_outResult);
return out_outResult;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_createTransition(threadData_t *threadData, modelica_metatype _transitionElem, modelica_metatype _states)
{
modelica_metatype _trans = NULL;
modelica_metatype _crefFrom = NULL;
modelica_metatype _crefTo = NULL;
modelica_integer _from;
modelica_integer _to;
modelica_metatype _condition = NULL;
modelica_boolean _immediate;
modelica_boolean _reset;
modelica_boolean _synchronize;
modelica_integer _priority;
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
modelica_metatype tmpMeta16;
modelica_integer tmp17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_integer tmp21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_integer tmp25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_integer tmp29;
modelica_metatype tmpMeta30;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_immediate = 1;
_reset = 1;
_synchronize = 0;
_priority = ((modelica_integer) 1);
tmpMeta1 = _transitionElem;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,24,2) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta2,13,3) == 0) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta3,1,1) == 0) MMC_THROW_INTERNAL();
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 2));
if (10 != MMC_STRLEN(tmpMeta4) || strcmp("transition", MMC_STRINGDATA(tmpMeta4)) != 0) MMC_THROW_INTERNAL();
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 3));
if (listEmpty(tmpMeta5)) MMC_THROW_INTERNAL();
tmpMeta6 = MMC_CAR(tmpMeta5);
tmpMeta7 = MMC_CDR(tmpMeta5);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,6,2) == 0) MMC_THROW_INTERNAL();
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (listEmpty(tmpMeta7)) MMC_THROW_INTERNAL();
tmpMeta9 = MMC_CAR(tmpMeta7);
tmpMeta10 = MMC_CDR(tmpMeta7);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,6,2) == 0) MMC_THROW_INTERNAL();
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (listEmpty(tmpMeta10)) MMC_THROW_INTERNAL();
tmpMeta12 = MMC_CAR(tmpMeta10);
tmpMeta13 = MMC_CDR(tmpMeta10);
if (listEmpty(tmpMeta13)) MMC_THROW_INTERNAL();
tmpMeta14 = MMC_CAR(tmpMeta13);
tmpMeta15 = MMC_CDR(tmpMeta13);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,3,1) == 0) MMC_THROW_INTERNAL();
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
tmp17 = mmc_unbox_integer(tmpMeta16);
if (listEmpty(tmpMeta15)) MMC_THROW_INTERNAL();
tmpMeta18 = MMC_CAR(tmpMeta15);
tmpMeta19 = MMC_CDR(tmpMeta15);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,3,1) == 0) MMC_THROW_INTERNAL();
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
tmp21 = mmc_unbox_integer(tmpMeta20);
if (listEmpty(tmpMeta19)) MMC_THROW_INTERNAL();
tmpMeta22 = MMC_CAR(tmpMeta19);
tmpMeta23 = MMC_CDR(tmpMeta19);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta22,3,1) == 0) MMC_THROW_INTERNAL();
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 2));
tmp25 = mmc_unbox_integer(tmpMeta24);
if (listEmpty(tmpMeta23)) MMC_THROW_INTERNAL();
tmpMeta26 = MMC_CAR(tmpMeta23);
tmpMeta27 = MMC_CDR(tmpMeta23);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,0,1) == 0) MMC_THROW_INTERNAL();
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 2));
tmp29 = mmc_unbox_integer(tmpMeta28);
if (!listEmpty(tmpMeta27)) MMC_THROW_INTERNAL();
_crefFrom = tmpMeta8;
_crefTo = tmpMeta11;
_condition = tmpMeta12;
_immediate = tmp17;
_reset = tmp21;
_synchronize = tmp25;
_priority = tmp29;
_from = omc_List_position1OnTrue(threadData, _states, boxvar_StateMachineFlatten_sMCompEqualsRef, _crefFrom);
_to = omc_List_position1OnTrue(threadData, _states, boxvar_StateMachineFlatten_sMCompEqualsRef, _crefTo);
tmpMeta30 = mmc_mk_box8(3, &StateMachineFlatten_Transition_TRANSITION__desc, mmc_mk_integer(_from), mmc_mk_integer(_to), _condition, mmc_mk_boolean(_immediate), mmc_mk_boolean(_reset), mmc_mk_boolean(_synchronize), mmc_mk_integer(_priority));
_trans = tmpMeta30;
_return: OMC_LABEL_UNUSED
return _trans;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_priorityLt(threadData_t *threadData, modelica_metatype _inTrans1, modelica_metatype _inTrans2)
{
modelica_boolean _res;
modelica_integer _priority1;
modelica_integer _priority2;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_integer tmp6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inTrans1;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 8));
tmp3 = mmc_unbox_integer(tmpMeta2);
_priority1 = tmp3;
tmpMeta4 = _inTrans2;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta4), 8));
tmp6 = mmc_unbox_integer(tmpMeta5);
_priority2 = tmp6;
_res = (_priority1 < _priority2);
_return: OMC_LABEL_UNUSED
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_priorityLt(threadData_t *threadData, modelica_metatype _inTrans1, modelica_metatype _inTrans2)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_StateMachineFlatten_priorityLt(threadData, _inTrans1, _inTrans2);
out_res = mmc_mk_icon(_res);
return out_res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_extractCondtionFromTransition(threadData_t *threadData, modelica_metatype _trans)
{
modelica_metatype _condition = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _trans;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
_condition = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _condition;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_createTandC(threadData_t *threadData, modelica_metatype _inSMComps, modelica_metatype _inTransitions, modelica_metatype *out_c)
{
modelica_metatype _t = NULL;
modelica_metatype _c = NULL;
modelica_metatype _transitions = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_transitions = omc_List_map1(threadData, _inTransitions, boxvar_StateMachineFlatten_createTransition, _inSMComps);
_t = omc_List_sort(threadData, _transitions, boxvar_StateMachineFlatten_priorityLt);
_c = omc_List_map(threadData, _t, boxvar_StateMachineFlatten_extractCondtionFromTransition);
_return: OMC_LABEL_UNUSED
if (out_c) { *out_c = _c; }
return _t;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_createVarWithStartValue(threadData_t *threadData, modelica_metatype _componentRef, modelica_metatype _kind, modelica_metatype _ty, modelica_metatype _startExp, modelica_metatype _dims)
{
modelica_metatype _outVar = NULL;
modelica_metatype _var = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box14(3, &DAE_Element_VAR__desc, _componentRef, _kind, _OMC_LIT46, _OMC_LIT47, _OMC_LIT48, _ty, mmc_mk_none(), _dims, _OMC_LIT49, _OMC_LIT33, mmc_mk_none(), mmc_mk_none(), _OMC_LIT50);
_var = tmpMeta1;
_outVar = omc_StateMachineFlatten_setVarFixedStartValue(threadData, _var, _startExp);
_return: OMC_LABEL_UNUSED
return _outVar;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_createVarWithDefaults(threadData_t *threadData, modelica_metatype _componentRef, modelica_metatype _kind, modelica_metatype _ty, modelica_metatype _dims)
{
modelica_metatype _var = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box14(3, &DAE_Element_VAR__desc, _componentRef, _kind, _OMC_LIT46, _OMC_LIT47, _OMC_LIT48, _ty, mmc_mk_none(), _dims, _OMC_LIT49, _OMC_LIT33, mmc_mk_none(), mmc_mk_none(), _OMC_LIT50);
_var = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _var;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_qCref(threadData_t *threadData, modelica_string _ident, modelica_metatype _identType, modelica_metatype _subscriptLst, modelica_metatype _componentRef)
{
modelica_metatype _outQual = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _ident, _identType, _subscriptLst);
_outQual = omc_ComponentReference_joinCrefs(threadData, _componentRef, tmpMeta1);
_return: OMC_LABEL_UNUSED
return _outQual;
}
static modelica_metatype closure0_Expression_expEqual(threadData_t *thData, modelica_metatype closure, modelica_metatype inExp2)
{
modelica_metatype inExp1 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_Expression_expEqual(thData, inExp1, inExp2);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_basicFlatSmSemantics(threadData_t *threadData, modelica_string _ident, modelica_metatype _q, modelica_metatype _inTransitions)
{
modelica_metatype _flatSmSemantics = NULL;
modelica_metatype _crefInitialState = NULL;
modelica_metatype _preRef = NULL;
modelica_metatype _defaultIntVar = NULL;
modelica_metatype _defaultBoolVar = NULL;
modelica_metatype _vars = NULL;
modelica_metatype _knowns = NULL;
modelica_integer _i;
modelica_metatype _cref = NULL;
modelica_metatype _nStatesRef = NULL;
modelica_metatype _activeRef = NULL;
modelica_metatype _resetRef = NULL;
modelica_metatype _selectedStateRef = NULL;
modelica_metatype _selectedResetRef = NULL;
modelica_metatype _firedRef = NULL;
modelica_metatype _activeStateRef = NULL;
modelica_metatype _activeResetRef = NULL;
modelica_metatype _nextStateRef = NULL;
modelica_metatype _nextResetRef = NULL;
modelica_metatype _stateMachineInFinalStateRef = NULL;
modelica_metatype _var = NULL;
modelica_metatype _nStatesVar = NULL;
modelica_metatype _activeVar = NULL;
modelica_metatype _resetVar = NULL;
modelica_metatype _selectedStateVar = NULL;
modelica_metatype _selectedResetVar = NULL;
modelica_metatype _firedVar = NULL;
modelica_metatype _activeStateVar = NULL;
modelica_metatype _activeResetVar = NULL;
modelica_metatype _nextStateVar = NULL;
modelica_metatype _nextResetVar = NULL;
modelica_metatype _stateMachineInFinalStateVar = NULL;
modelica_integer _nStates;
modelica_metatype _nStatesDims = NULL;
modelica_metatype _nStatesArrayBool = NULL;
modelica_metatype _activeResetStatesRefs = NULL;
modelica_metatype _nextResetStatesRefs = NULL;
modelica_metatype _finalStatesRefs = NULL;
modelica_metatype _activeResetStatesVars = NULL;
modelica_metatype _nextResetStatesVars = NULL;
modelica_metatype _finalStatesVars = NULL;
modelica_metatype _t = NULL;
modelica_integer _nTransitions;
modelica_metatype _tDims = NULL;
modelica_metatype _tArrayInteger = NULL;
modelica_metatype _tArrayBool = NULL;
modelica_metatype _tFromRefs = NULL;
modelica_metatype _tToRefs = NULL;
modelica_metatype _tImmediateRefs = NULL;
modelica_metatype _tResetRefs = NULL;
modelica_metatype _tSynchronizeRefs = NULL;
modelica_metatype _tPriorityRefs = NULL;
modelica_metatype _tFromVars = NULL;
modelica_metatype _tToVars = NULL;
modelica_metatype _tImmediateVars = NULL;
modelica_metatype _tResetVars = NULL;
modelica_metatype _tSynchronizeVars = NULL;
modelica_metatype _tPriorityVars = NULL;
modelica_integer _from;
modelica_integer _to;
modelica_metatype _condition = NULL;
modelica_boolean _immediate;
modelica_boolean _reset;
modelica_boolean _synchronize;
modelica_integer _priority;
modelica_metatype _cExps = NULL;
modelica_metatype _cRefs = NULL;
modelica_metatype _cImmediateRefs = NULL;
modelica_metatype _cVars = NULL;
modelica_metatype _cImmediateVars = NULL;
modelica_metatype _eqs = NULL;
modelica_metatype _selectedStateEqn = NULL;
modelica_metatype _selectedResetEqn = NULL;
modelica_metatype _firedEqn = NULL;
modelica_metatype _activeStateEqn = NULL;
modelica_metatype _activeResetEqn = NULL;
modelica_metatype _nextStateEqn = NULL;
modelica_metatype _nextResetEqn = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _rhs = NULL;
modelica_metatype _expCond = NULL;
modelica_metatype _expThen = NULL;
modelica_metatype _expElse = NULL;
modelica_metatype _exp1 = NULL;
modelica_metatype _exp2 = NULL;
modelica_metatype _expIf = NULL;
modelica_metatype _expLst = NULL;
modelica_metatype _bindExp = NULL;
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
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_integer tmp18;
modelica_metatype tmpMeta19;
modelica_integer tmp20;
modelica_metatype tmpMeta21;
modelica_integer tmp22;
modelica_metatype tmpMeta23;
modelica_integer tmp24;
modelica_metatype tmpMeta25;
modelica_integer tmp26;
modelica_metatype tmpMeta27;
modelica_integer tmp28;
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
modelica_metatype tmpMeta96;
modelica_metatype tmpMeta97;
modelica_metatype tmpMeta98;
modelica_metatype tmpMeta99;
modelica_metatype tmpMeta100;
modelica_metatype tmpMeta101;
modelica_metatype tmpMeta102;
modelica_metatype tmpMeta103;
modelica_integer tmp104;
modelica_integer tmp105;
modelica_integer tmp106;
modelica_metatype tmpMeta107;
modelica_metatype tmpMeta108;
modelica_metatype tmpMeta109;
modelica_metatype tmpMeta110;
modelica_integer tmp111;
modelica_integer tmp112;
modelica_integer tmp113;
modelica_metatype tmpMeta114;
modelica_metatype tmpMeta115;
modelica_metatype tmpMeta116;
modelica_metatype tmpMeta117;
modelica_integer tmp118;
modelica_integer tmp119;
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
modelica_metatype tmpMeta130;
modelica_metatype tmpMeta131;
modelica_metatype tmpMeta132;
modelica_metatype tmpMeta133;
modelica_metatype tmpMeta134;
modelica_boolean tmp135;
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
modelica_integer tmp166;
modelica_integer tmp167;
modelica_integer tmp168;
modelica_metatype tmpMeta169;
modelica_metatype tmpMeta170;
modelica_boolean tmp171;
modelica_metatype tmpMeta172;
modelica_metatype tmpMeta173;
modelica_metatype tmpMeta174;
modelica_metatype tmpMeta175;
modelica_metatype tmpMeta176;
modelica_metatype tmpMeta177;
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
modelica_metatype tmpMeta224;
modelica_metatype tmpMeta225;
modelica_integer tmp226;
modelica_integer tmp227;
modelica_integer tmp228;
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
modelica_integer tmp242;
modelica_integer tmp243;
modelica_integer tmp244;
modelica_metatype tmpMeta245;
modelica_metatype tmpMeta246;
modelica_metatype tmpMeta247;
modelica_metatype tmpMeta248;
modelica_metatype tmpMeta249;
modelica_metatype tmpMeta250;
modelica_metatype tmpMeta251;
modelica_integer tmp252;
modelica_integer tmp253;
modelica_integer tmp254;
modelica_metatype tmpMeta255;
modelica_metatype tmpMeta256;
modelica_boolean tmp257;
modelica_metatype tmpMeta258;
modelica_metatype tmpMeta259;
modelica_metatype tmpMeta260;
modelica_metatype tmpMeta261;
modelica_integer tmp262;
modelica_integer tmp263;
modelica_integer tmp264;
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
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = listHead(_q);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,29,2) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_crefInitialState = tmpMeta2;
_preRef = omc_ComponentReference_crefPrefixString(threadData, _OMC_LIT4, _crefInitialState);
_t = omc_StateMachineFlatten_createTandC(threadData, _q, _inTransitions ,&_cExps);
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
_defaultIntVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, omc_ComponentReference_makeDummyCref(threadData), _OMC_LIT51, _OMC_LIT52, tmpMeta3);
tmpMeta4 = MMC_REFSTRUCTLIT(mmc_nil);
_defaultBoolVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, omc_ComponentReference_makeDummyCref(threadData), _OMC_LIT51, _OMC_LIT7, tmpMeta4);
tmpMeta5 = MMC_REFSTRUCTLIT(mmc_nil);
_knowns = tmpMeta5;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
_vars = tmpMeta6;
_nStates = listLength(_q);
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
_nStatesRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT53, _OMC_LIT52, tmpMeta7, _preRef);
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
_nStatesVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _nStatesRef, _OMC_LIT54, _OMC_LIT52, tmpMeta8);
tmpMeta9 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_nStates));
_nStatesVar = omc_DAEUtil_setElementVarBinding(threadData, _nStatesVar, mmc_mk_some(tmpMeta9));
tmpMeta10 = mmc_mk_cons(_nStatesVar, _knowns);
_knowns = tmpMeta10;
_nTransitions = listLength(_t);
tmpMeta12 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_nTransitions));
tmpMeta11 = mmc_mk_cons(tmpMeta12, MMC_REFSTRUCTLIT(mmc_nil));
_tDims = tmpMeta11;
tmpMeta13 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT52, _tDims);
_tArrayInteger = tmpMeta13;
tmpMeta14 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT7, _tDims);
_tArrayBool = tmpMeta14;
_tFromRefs = arrayCreate(_nTransitions, omc_ComponentReference_makeDummyCref(threadData));
_tToRefs = arrayCreate(_nTransitions, omc_ComponentReference_makeDummyCref(threadData));
_tImmediateRefs = arrayCreate(_nTransitions, omc_ComponentReference_makeDummyCref(threadData));
_tResetRefs = arrayCreate(_nTransitions, omc_ComponentReference_makeDummyCref(threadData));
_tSynchronizeRefs = arrayCreate(_nTransitions, omc_ComponentReference_makeDummyCref(threadData));
_tPriorityRefs = arrayCreate(_nTransitions, omc_ComponentReference_makeDummyCref(threadData));
_tFromVars = arrayCreate(_nTransitions, _defaultIntVar);
_tToVars = arrayCreate(_nTransitions, _defaultIntVar);
_tImmediateVars = arrayCreate(_nTransitions, _defaultBoolVar);
_tResetVars = arrayCreate(_nTransitions, _defaultBoolVar);
_tSynchronizeVars = arrayCreate(_nTransitions, _defaultBoolVar);
_tPriorityVars = arrayCreate(_nTransitions, _defaultIntVar);
_i = ((modelica_integer) 0);
{
modelica_metatype _t1;
for (tmpMeta15 = _t; !listEmpty(tmpMeta15); tmpMeta15=MMC_CDR(tmpMeta15))
{
_t1 = MMC_CAR(tmpMeta15);
_i = ((modelica_integer) 1) + _i;
tmpMeta16 = _t1;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
tmp18 = mmc_unbox_integer(tmpMeta17);
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 3));
tmp20 = mmc_unbox_integer(tmpMeta19);
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 5));
tmp22 = mmc_unbox_integer(tmpMeta21);
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 6));
tmp24 = mmc_unbox_integer(tmpMeta23);
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 7));
tmp26 = mmc_unbox_integer(tmpMeta25);
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 8));
tmp28 = mmc_unbox_integer(tmpMeta27);
_from = tmp18;
_to = tmp20;
_immediate = tmp22;
_reset = tmp24;
_synchronize = tmp26;
_priority = tmp28;
tmpMeta30 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta31 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta30);
tmpMeta29 = mmc_mk_cons(tmpMeta31, MMC_REFSTRUCTLIT(mmc_nil));
_tFromRefs = arrayUpdate(_tFromRefs, _i, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT55, _tArrayInteger, tmpMeta29, _preRef));
_tFromVars = arrayUpdate(_tFromVars, _i, omc_StateMachineFlatten_createVarWithDefaults(threadData, arrayGet(_tFromRefs, _i), _OMC_LIT54, _OMC_LIT52, _tDims));
tmpMeta32 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_from));
_tFromVars = arrayUpdate(_tFromVars, _i, omc_DAEUtil_setElementVarBinding(threadData, arrayGet(_tFromVars, _i), mmc_mk_some(tmpMeta32)));
tmpMeta33 = mmc_mk_cons(arrayGet(_tFromVars, _i), _knowns);
_knowns = tmpMeta33;
tmpMeta35 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta36 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta35);
tmpMeta34 = mmc_mk_cons(tmpMeta36, MMC_REFSTRUCTLIT(mmc_nil));
_tToRefs = arrayUpdate(_tToRefs, _i, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT56, _tArrayInteger, tmpMeta34, _preRef));
_tToVars = arrayUpdate(_tToVars, _i, omc_StateMachineFlatten_createVarWithDefaults(threadData, arrayGet(_tToRefs, _i), _OMC_LIT54, _OMC_LIT52, _tDims));
tmpMeta37 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_to));
_tToVars = arrayUpdate(_tToVars, _i, omc_DAEUtil_setElementVarBinding(threadData, arrayGet(_tToVars, _i), mmc_mk_some(tmpMeta37)));
tmpMeta38 = mmc_mk_cons(arrayGet(_tToVars, _i), _knowns);
_knowns = tmpMeta38;
tmpMeta40 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta41 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta40);
tmpMeta39 = mmc_mk_cons(tmpMeta41, MMC_REFSTRUCTLIT(mmc_nil));
_tImmediateRefs = arrayUpdate(_tImmediateRefs, _i, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT57, _tArrayBool, tmpMeta39, _preRef));
_tImmediateVars = arrayUpdate(_tImmediateVars, _i, omc_StateMachineFlatten_createVarWithDefaults(threadData, arrayGet(_tImmediateRefs, _i), _OMC_LIT54, _OMC_LIT7, _tDims));
tmpMeta42 = mmc_mk_box2(6, &DAE_Exp_BCONST__desc, mmc_mk_boolean(_immediate));
_tImmediateVars = arrayUpdate(_tImmediateVars, _i, omc_DAEUtil_setElementVarBinding(threadData, arrayGet(_tImmediateVars, _i), mmc_mk_some(tmpMeta42)));
tmpMeta43 = mmc_mk_cons(arrayGet(_tImmediateVars, _i), _knowns);
_knowns = tmpMeta43;
tmpMeta45 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta46 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta45);
tmpMeta44 = mmc_mk_cons(tmpMeta46, MMC_REFSTRUCTLIT(mmc_nil));
_tResetRefs = arrayUpdate(_tResetRefs, _i, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT58, _tArrayBool, tmpMeta44, _preRef));
_tResetVars = arrayUpdate(_tResetVars, _i, omc_StateMachineFlatten_createVarWithDefaults(threadData, arrayGet(_tResetRefs, _i), _OMC_LIT54, _OMC_LIT7, _tDims));
tmpMeta47 = mmc_mk_box2(6, &DAE_Exp_BCONST__desc, mmc_mk_boolean(_reset));
_tResetVars = arrayUpdate(_tResetVars, _i, omc_DAEUtil_setElementVarBinding(threadData, arrayGet(_tResetVars, _i), mmc_mk_some(tmpMeta47)));
tmpMeta48 = mmc_mk_cons(arrayGet(_tResetVars, _i), _knowns);
_knowns = tmpMeta48;
tmpMeta50 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta51 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta50);
tmpMeta49 = mmc_mk_cons(tmpMeta51, MMC_REFSTRUCTLIT(mmc_nil));
_tSynchronizeRefs = arrayUpdate(_tSynchronizeRefs, _i, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT59, _tArrayBool, tmpMeta49, _preRef));
_tSynchronizeVars = arrayUpdate(_tSynchronizeVars, _i, omc_StateMachineFlatten_createVarWithDefaults(threadData, arrayGet(_tSynchronizeRefs, _i), _OMC_LIT54, _OMC_LIT7, _tDims));
tmpMeta52 = mmc_mk_box2(6, &DAE_Exp_BCONST__desc, mmc_mk_boolean(_synchronize));
_tSynchronizeVars = arrayUpdate(_tSynchronizeVars, _i, omc_DAEUtil_setElementVarBinding(threadData, arrayGet(_tSynchronizeVars, _i), mmc_mk_some(tmpMeta52)));
tmpMeta53 = mmc_mk_cons(arrayGet(_tSynchronizeVars, _i), _knowns);
_knowns = tmpMeta53;
tmpMeta55 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta56 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta55);
tmpMeta54 = mmc_mk_cons(tmpMeta56, MMC_REFSTRUCTLIT(mmc_nil));
_tPriorityRefs = arrayUpdate(_tPriorityRefs, _i, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT60, _tArrayInteger, tmpMeta54, _preRef));
_tPriorityVars = arrayUpdate(_tPriorityVars, _i, omc_StateMachineFlatten_createVarWithDefaults(threadData, arrayGet(_tPriorityRefs, _i), _OMC_LIT54, _OMC_LIT52, _tDims));
tmpMeta57 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_priority));
_tPriorityVars = arrayUpdate(_tPriorityVars, _i, omc_DAEUtil_setElementVarBinding(threadData, arrayGet(_tPriorityVars, _i), mmc_mk_some(tmpMeta57)));
tmpMeta58 = mmc_mk_cons(arrayGet(_tPriorityVars, _i), _knowns);
_knowns = tmpMeta58;
}
}
_cRefs = arrayCreate(_nTransitions, omc_ComponentReference_makeDummyCref(threadData));
_cImmediateRefs = arrayCreate(_nTransitions, omc_ComponentReference_makeDummyCref(threadData));
_cVars = arrayCreate(_nTransitions, _defaultBoolVar);
_cImmediateVars = arrayCreate(_nTransitions, _defaultBoolVar);
_i = ((modelica_integer) 0);
{
modelica_metatype _exp;
for (tmpMeta60 = _cExps; !listEmpty(tmpMeta60); tmpMeta60=MMC_CDR(tmpMeta60))
{
_exp = MMC_CAR(tmpMeta60);
_i = ((modelica_integer) 1) + _i;
tmpMeta62 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta63 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta62);
tmpMeta61 = mmc_mk_cons(tmpMeta63, MMC_REFSTRUCTLIT(mmc_nil));
_cRefs = arrayUpdate(_cRefs, _i, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT61, _tArrayBool, tmpMeta61, _preRef));
tmpMeta65 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta66 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta65);
tmpMeta64 = mmc_mk_cons(tmpMeta66, MMC_REFSTRUCTLIT(mmc_nil));
_cImmediateRefs = arrayUpdate(_cImmediateRefs, _i, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT23, _tArrayBool, tmpMeta64, _preRef));
_cVars = arrayUpdate(_cVars, _i, omc_StateMachineFlatten_createVarWithDefaults(threadData, arrayGet(_cRefs, _i), _OMC_LIT51, _OMC_LIT7, _tDims));
_cImmediateVars = arrayUpdate(_cImmediateVars, _i, omc_StateMachineFlatten_createVarWithStartValue(threadData, arrayGet(_cImmediateRefs, _i), _OMC_LIT51, _OMC_LIT7, _OMC_LIT62, _tDims));
tmpMeta67 = mmc_mk_cons(arrayGet(_cVars, _i), _vars);
_vars = tmpMeta67;
tmpMeta68 = mmc_mk_cons(arrayGet(_cImmediateVars, _i), _vars);
_vars = tmpMeta68;
}
}
tmpMeta70 = MMC_REFSTRUCTLIT(mmc_nil);
_activeRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT63, _OMC_LIT7, tmpMeta70, _preRef);
tmpMeta71 = MMC_REFSTRUCTLIT(mmc_nil);
_activeVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _activeRef, _OMC_LIT51, _OMC_LIT7, tmpMeta71);
tmpMeta72 = mmc_mk_cons(_activeVar, _vars);
_vars = tmpMeta72;
tmpMeta73 = MMC_REFSTRUCTLIT(mmc_nil);
_resetRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT64, _OMC_LIT7, tmpMeta73, _preRef);
tmpMeta74 = MMC_REFSTRUCTLIT(mmc_nil);
_resetVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _resetRef, _OMC_LIT51, _OMC_LIT7, tmpMeta74);
tmpMeta75 = mmc_mk_cons(_resetVar, _vars);
_vars = tmpMeta75;
tmpMeta76 = MMC_REFSTRUCTLIT(mmc_nil);
_selectedStateRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT65, _OMC_LIT52, tmpMeta76, _preRef);
tmpMeta77 = MMC_REFSTRUCTLIT(mmc_nil);
_selectedStateVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _selectedStateRef, _OMC_LIT51, _OMC_LIT52, tmpMeta77);
tmpMeta78 = mmc_mk_cons(_selectedStateVar, _vars);
_vars = tmpMeta78;
tmpMeta79 = MMC_REFSTRUCTLIT(mmc_nil);
_selectedResetRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT66, _OMC_LIT7, tmpMeta79, _preRef);
tmpMeta80 = MMC_REFSTRUCTLIT(mmc_nil);
_selectedResetVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _selectedResetRef, _OMC_LIT51, _OMC_LIT7, tmpMeta80);
tmpMeta81 = mmc_mk_cons(_selectedResetVar, _vars);
_vars = tmpMeta81;
tmpMeta82 = MMC_REFSTRUCTLIT(mmc_nil);
_firedRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT67, _OMC_LIT52, tmpMeta82, _preRef);
tmpMeta83 = MMC_REFSTRUCTLIT(mmc_nil);
_firedVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _firedRef, _OMC_LIT51, _OMC_LIT52, tmpMeta83);
tmpMeta84 = mmc_mk_cons(_firedVar, _vars);
_vars = tmpMeta84;
tmpMeta85 = MMC_REFSTRUCTLIT(mmc_nil);
_activeStateRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT68, _OMC_LIT52, tmpMeta85, _preRef);
tmpMeta86 = MMC_REFSTRUCTLIT(mmc_nil);
_activeStateVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _activeStateRef, _OMC_LIT51, _OMC_LIT52, tmpMeta86);
tmpMeta87 = mmc_mk_cons(_activeStateVar, _vars);
_vars = tmpMeta87;
tmpMeta88 = MMC_REFSTRUCTLIT(mmc_nil);
_activeResetRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT69, _OMC_LIT7, tmpMeta88, _preRef);
tmpMeta89 = MMC_REFSTRUCTLIT(mmc_nil);
_activeResetVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _activeResetRef, _OMC_LIT51, _OMC_LIT7, tmpMeta89);
tmpMeta90 = mmc_mk_cons(_activeResetVar, _vars);
_vars = tmpMeta90;
tmpMeta91 = MMC_REFSTRUCTLIT(mmc_nil);
_nextStateRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT70, _OMC_LIT52, tmpMeta91, _preRef);
tmpMeta92 = MMC_REFSTRUCTLIT(mmc_nil);
_nextStateVar = omc_StateMachineFlatten_createVarWithStartValue(threadData, _nextStateRef, _OMC_LIT51, _OMC_LIT52, _OMC_LIT71, tmpMeta92);
tmpMeta93 = mmc_mk_cons(_nextStateVar, _vars);
_vars = tmpMeta93;
tmpMeta94 = MMC_REFSTRUCTLIT(mmc_nil);
_nextResetRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT72, _OMC_LIT7, tmpMeta94, _preRef);
tmpMeta95 = MMC_REFSTRUCTLIT(mmc_nil);
_nextResetVar = omc_StateMachineFlatten_createVarWithStartValue(threadData, _nextResetRef, _OMC_LIT51, _OMC_LIT7, _OMC_LIT62, tmpMeta95);
tmpMeta96 = mmc_mk_cons(_nextResetVar, _vars);
_vars = tmpMeta96;
tmpMeta98 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_nStates));
tmpMeta97 = mmc_mk_cons(tmpMeta98, MMC_REFSTRUCTLIT(mmc_nil));
_nStatesDims = tmpMeta97;
tmpMeta99 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT7, _nStatesDims);
_nStatesArrayBool = tmpMeta99;
_activeResetStatesRefs = arrayCreate(_nStates, omc_ComponentReference_makeDummyCref(threadData));
_activeResetStatesVars = arrayCreate(_nStates, _defaultBoolVar);
tmp104 = ((modelica_integer) 1); tmp105 = 1; tmp106 = _nStates;
if(!(((tmp105 > 0) && (tmp104 > tmp106)) || ((tmp105 < 0) && (tmp104 < tmp106))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp104, tmp106); _i += tmp105)
{
tmpMeta101 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta102 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta101);
tmpMeta100 = mmc_mk_cons(tmpMeta102, MMC_REFSTRUCTLIT(mmc_nil));
_activeResetStatesRefs = arrayUpdate(_activeResetStatesRefs, _i, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT73, _nStatesArrayBool, tmpMeta100, _preRef));
_activeResetStatesVars = arrayUpdate(_activeResetStatesVars, _i, omc_StateMachineFlatten_createVarWithDefaults(threadData, arrayGet(_activeResetStatesRefs, _i), _OMC_LIT51, _OMC_LIT7, _nStatesDims));
tmpMeta103 = mmc_mk_cons(arrayGet(_activeResetStatesVars, _i), _vars);
_vars = tmpMeta103;
}
}
_nextResetStatesRefs = arrayCreate(_nStates, omc_ComponentReference_makeDummyCref(threadData));
_nextResetStatesVars = arrayCreate(_nStates, _defaultBoolVar);
tmp111 = ((modelica_integer) 1); tmp112 = 1; tmp113 = _nStates;
if(!(((tmp112 > 0) && (tmp111 > tmp113)) || ((tmp112 < 0) && (tmp111 < tmp113))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp111, tmp113); _i += tmp112)
{
tmpMeta108 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta109 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta108);
tmpMeta107 = mmc_mk_cons(tmpMeta109, MMC_REFSTRUCTLIT(mmc_nil));
_nextResetStatesRefs = arrayUpdate(_nextResetStatesRefs, _i, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT74, _nStatesArrayBool, tmpMeta107, _preRef));
_nextResetStatesVars = arrayUpdate(_nextResetStatesVars, _i, omc_StateMachineFlatten_createVarWithStartValue(threadData, arrayGet(_nextResetStatesRefs, _i), _OMC_LIT51, _OMC_LIT7, _OMC_LIT62, _nStatesDims));
tmpMeta110 = mmc_mk_cons(arrayGet(_nextResetStatesVars, _i), _vars);
_vars = tmpMeta110;
}
}
_finalStatesRefs = arrayCreate(_nStates, omc_ComponentReference_makeDummyCref(threadData));
_finalStatesVars = arrayCreate(_nStates, _defaultBoolVar);
tmp118 = ((modelica_integer) 1); tmp119 = 1; tmp120 = _nStates;
if(!(((tmp119 > 0) && (tmp118 > tmp120)) || ((tmp119 < 0) && (tmp118 < tmp120))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp118, tmp120); _i += tmp119)
{
tmpMeta115 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta116 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta115);
tmpMeta114 = mmc_mk_cons(tmpMeta116, MMC_REFSTRUCTLIT(mmc_nil));
_finalStatesRefs = arrayUpdate(_finalStatesRefs, _i, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT75, _nStatesArrayBool, tmpMeta114, _preRef));
_finalStatesVars = arrayUpdate(_finalStatesVars, _i, omc_StateMachineFlatten_createVarWithDefaults(threadData, arrayGet(_finalStatesRefs, _i), _OMC_LIT51, _OMC_LIT7, _nStatesDims));
tmpMeta117 = mmc_mk_cons(arrayGet(_finalStatesVars, _i), _vars);
_vars = tmpMeta117;
}
}
tmpMeta121 = MMC_REFSTRUCTLIT(mmc_nil);
_stateMachineInFinalStateRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT76, _OMC_LIT7, tmpMeta121, _preRef);
tmpMeta122 = MMC_REFSTRUCTLIT(mmc_nil);
_stateMachineInFinalStateVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _stateMachineInFinalStateRef, _OMC_LIT51, _OMC_LIT7, tmpMeta122);
tmpMeta123 = mmc_mk_cons(_stateMachineInFinalStateVar, _vars);
_vars = tmpMeta123;
tmpMeta124 = MMC_REFSTRUCTLIT(mmc_nil);
_eqs = tmpMeta124;
_i = ((modelica_integer) 0);
{
modelica_metatype _cExp;
for (tmpMeta125 = _cExps; !listEmpty(tmpMeta125); tmpMeta125=MMC_CDR(tmpMeta125))
{
_cExp = MMC_CAR(tmpMeta125);
_i = ((modelica_integer) 1) + _i;
tmpMeta126 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, arrayGet(_cImmediateRefs, _i), _OMC_LIT7);
_exp = tmpMeta126;
tmpMeta128 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _cExp, _OMC_LIT33);
tmpMeta127 = mmc_mk_cons(tmpMeta128, _eqs);
_eqs = tmpMeta127;
tmpMeta129 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, arrayGet(_cRefs, _i), _OMC_LIT7);
_exp1 = tmpMeta129;
tmpMeta130 = arrayGet(_tImmediateVars, _i);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta130,0,13) == 0) MMC_THROW_INTERNAL();
tmpMeta131 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta130), 8));
_bindExp = tmpMeta131;
tmpMeta132 = mmc_mk_box1(0, _OMC_LIT77);
tmp135 = (modelica_boolean)mmc_unbox_boolean(omc_Util_applyOptionOrDefault(threadData, _bindExp, (modelica_fnptr) mmc_mk_box2(0,closure0_Expression_expEqual,tmpMeta132), mmc_mk_boolean(0)));
if(tmp135)
{
tmpMeta136 = _exp;
}
else
{
tmpMeta133 = mmc_mk_cons(_exp, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta134 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta133, _OMC_LIT10);
tmpMeta136 = tmpMeta134;
}
_rhs = tmpMeta136;
tmpMeta138 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp1, _rhs, _OMC_LIT33);
tmpMeta137 = mmc_mk_cons(tmpMeta138, _eqs);
_eqs = tmpMeta137;
}
}
tmpMeta140 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _selectedStateRef, _OMC_LIT52);
_exp = tmpMeta140;
tmpMeta141 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _resetRef, _OMC_LIT7);
_expCond = tmpMeta141;
_expThen = _OMC_LIT79;
tmpMeta143 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _nextStateRef, _OMC_LIT52);
tmpMeta142 = mmc_mk_cons(tmpMeta143, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta144 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta142, _OMC_LIT80);
_expElse = tmpMeta144;
tmpMeta145 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
_rhs = tmpMeta145;
tmpMeta146 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _rhs, _OMC_LIT33);
_selectedStateEqn = tmpMeta146;
tmpMeta147 = mmc_mk_cons(_selectedStateEqn, _eqs);
_eqs = tmpMeta147;
tmpMeta148 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _selectedResetRef, _OMC_LIT7);
_exp = tmpMeta148;
tmpMeta149 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _resetRef, _OMC_LIT7);
_expCond = tmpMeta149;
_expThen = _OMC_LIT77;
tmpMeta151 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _nextResetRef, _OMC_LIT7);
tmpMeta150 = mmc_mk_cons(tmpMeta151, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta152 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta150, _OMC_LIT10);
_expElse = tmpMeta152;
tmpMeta153 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
_rhs = tmpMeta153;
tmpMeta154 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _rhs, _OMC_LIT33);
_selectedResetEqn = tmpMeta154;
tmpMeta155 = mmc_mk_cons(_selectedResetEqn, _eqs);
_eqs = tmpMeta155;
tmpMeta156 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _firedRef, _OMC_LIT52);
_exp = tmpMeta156;
tmpMeta157 = MMC_REFSTRUCTLIT(mmc_nil);
_expLst = tmpMeta157;
tmp166 = ((modelica_integer) 1); tmp167 = 1; tmp168 = _nTransitions;
if(!(((tmp167 > 0) && (tmp166 > tmp168)) || ((tmp167 < 0) && (tmp166 < tmp168))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp166, tmp168); _i += tmp167)
{
tmpMeta158 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, arrayGet(_tFromRefs, _i), _OMC_LIT52);
tmpMeta159 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _selectedStateRef, _OMC_LIT52);
tmpMeta160 = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, tmpMeta158, _OMC_LIT81, tmpMeta159, mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
_expCond = tmpMeta160;
tmpMeta161 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, arrayGet(_cRefs, _i), _OMC_LIT7);
_expThen = tmpMeta161;
_expElse = _OMC_LIT62;
tmpMeta162 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
_expIf = tmpMeta162;
tmpMeta164 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta165 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expIf, tmpMeta164, _OMC_LIT71);
tmpMeta163 = mmc_mk_cons(tmpMeta165, _expLst);
_expLst = tmpMeta163;
}
}
tmp171 = (modelica_boolean)(listLength(_expLst) > ((modelica_integer) 1));
if(tmp171)
{
tmpMeta169 = mmc_mk_cons(omc_Expression_makeScalarArray(threadData, _expLst, _OMC_LIT52), MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta170 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT83, tmpMeta169, _OMC_LIT84);
tmpMeta172 = tmpMeta170;
}
else
{
tmpMeta172 = listHead(_expLst);
}
_rhs = tmpMeta172;
tmpMeta173 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _rhs, _OMC_LIT33);
_firedEqn = tmpMeta173;
tmpMeta174 = mmc_mk_cons(_firedEqn, _eqs);
_eqs = tmpMeta174;
tmpMeta175 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeStateRef, _OMC_LIT52);
_exp = tmpMeta175;
tmpMeta176 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _resetRef, _OMC_LIT7);
_expCond = tmpMeta176;
_expThen = _OMC_LIT79;
tmpMeta177 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _firedRef, _OMC_LIT52);
tmpMeta178 = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, tmpMeta177, _OMC_LIT85, _OMC_LIT71, mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
_exp1 = tmpMeta178;
tmpMeta180 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _firedRef, _OMC_LIT52);
tmpMeta181 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta180);
tmpMeta179 = mmc_mk_cons(tmpMeta181, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta182 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT56, _tArrayInteger, tmpMeta179, _preRef), _OMC_LIT52);
_exp2 = tmpMeta182;
tmpMeta183 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _selectedStateRef, _OMC_LIT52);
tmpMeta184 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _exp1, _exp2, tmpMeta183);
_expElse = tmpMeta184;
tmpMeta185 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
_rhs = tmpMeta185;
tmpMeta186 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _rhs, _OMC_LIT33);
_activeStateEqn = tmpMeta186;
tmpMeta187 = mmc_mk_cons(_activeStateEqn, _eqs);
_eqs = tmpMeta187;
tmpMeta188 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeResetRef, _OMC_LIT7);
_exp = tmpMeta188;
tmpMeta189 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _resetRef, _OMC_LIT7);
_expCond = tmpMeta189;
_expThen = _OMC_LIT77;
tmpMeta190 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _firedRef, _OMC_LIT52);
tmpMeta191 = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, tmpMeta190, _OMC_LIT85, _OMC_LIT71, mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
_exp1 = tmpMeta191;
tmpMeta193 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _firedRef, _OMC_LIT52);
tmpMeta194 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta193);
tmpMeta192 = mmc_mk_cons(tmpMeta194, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta195 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT58, _tArrayBool, tmpMeta192, _preRef), _OMC_LIT52);
_exp2 = tmpMeta195;
tmpMeta196 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _selectedResetRef, _OMC_LIT7);
tmpMeta197 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _exp1, _exp2, tmpMeta196);
_expElse = tmpMeta197;
tmpMeta198 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
_rhs = tmpMeta198;
tmpMeta199 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _rhs, _OMC_LIT33);
_activeResetEqn = tmpMeta199;
tmpMeta200 = mmc_mk_cons(_activeResetEqn, _eqs);
_eqs = tmpMeta200;
tmpMeta201 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _nextStateRef, _OMC_LIT52);
_exp = tmpMeta201;
tmpMeta202 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeRef, _OMC_LIT7);
_expCond = tmpMeta202;
tmpMeta203 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeStateRef, _OMC_LIT52);
_expThen = tmpMeta203;
tmpMeta205 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _nextStateRef, _OMC_LIT52);
tmpMeta204 = mmc_mk_cons(tmpMeta205, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta206 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta204, _OMC_LIT80);
_expElse = tmpMeta206;
tmpMeta207 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
_rhs = tmpMeta207;
tmpMeta208 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _rhs, _OMC_LIT33);
_nextStateEqn = tmpMeta208;
tmpMeta209 = mmc_mk_cons(_nextStateEqn, _eqs);
_eqs = tmpMeta209;
tmpMeta210 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _nextResetRef, _OMC_LIT7);
_exp = tmpMeta210;
tmpMeta211 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeRef, _OMC_LIT7);
_expCond = tmpMeta211;
_expThen = _OMC_LIT62;
tmpMeta213 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _nextResetRef, _OMC_LIT7);
tmpMeta212 = mmc_mk_cons(tmpMeta213, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta214 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta212, _OMC_LIT10);
_expElse = tmpMeta214;
tmpMeta215 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
_rhs = tmpMeta215;
tmpMeta216 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _rhs, _OMC_LIT33);
_nextResetEqn = tmpMeta216;
tmpMeta217 = mmc_mk_cons(_nextResetEqn, _eqs);
_eqs = tmpMeta217;
tmp226 = ((modelica_integer) 1); tmp227 = 1; tmp228 = _nStates;
if(!(((tmp227 > 0) && (tmp226 > tmp228)) || ((tmp227 < 0) && (tmp226 < tmp228))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp226, tmp228); _i += tmp227)
{
tmpMeta218 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, arrayGet(_activeResetStatesRefs, _i), _OMC_LIT7);
_exp = tmpMeta218;
tmpMeta219 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _resetRef, _OMC_LIT7);
_expCond = tmpMeta219;
_expThen = _OMC_LIT77;
tmpMeta221 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, arrayGet(_nextResetStatesRefs, _i), _OMC_LIT7);
tmpMeta220 = mmc_mk_cons(tmpMeta221, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta222 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta220, _OMC_LIT10);
_expElse = tmpMeta222;
tmpMeta223 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
_rhs = tmpMeta223;
tmpMeta225 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _rhs, _OMC_LIT33);
tmpMeta224 = mmc_mk_cons(tmpMeta225, _eqs);
_eqs = tmpMeta224;
}
}
tmp242 = ((modelica_integer) 1); tmp243 = 1; tmp244 = _nStates;
if(!(((tmp243 > 0) && (tmp242 > tmp244)) || ((tmp243 < 0) && (tmp242 < tmp244))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp242, tmp244); _i += tmp243)
{
tmpMeta229 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, arrayGet(_nextResetStatesRefs, _i), _OMC_LIT7);
_exp = tmpMeta229;
tmpMeta230 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeRef, _OMC_LIT7);
_expCond = tmpMeta230;
tmpMeta231 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeStateRef, _OMC_LIT52);
tmpMeta232 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta233 = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, tmpMeta231, _OMC_LIT81, tmpMeta232, mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
_exp1 = tmpMeta233;
tmpMeta234 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, arrayGet(_activeResetStatesRefs, _i), _OMC_LIT7);
tmpMeta235 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _exp1, _OMC_LIT62, tmpMeta234);
_expThen = tmpMeta235;
tmpMeta237 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, arrayGet(_nextResetStatesRefs, _i), _OMC_LIT7);
tmpMeta236 = mmc_mk_cons(tmpMeta237, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta238 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta236, _OMC_LIT10);
_expElse = tmpMeta238;
tmpMeta239 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
_rhs = tmpMeta239;
tmpMeta241 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _rhs, _OMC_LIT33);
tmpMeta240 = mmc_mk_cons(tmpMeta241, _eqs);
_eqs = tmpMeta240;
}
}
tmp262 = ((modelica_integer) 1); tmp263 = 1; tmp264 = _nStates;
if(!(((tmp263 > 0) && (tmp262 > tmp264)) || ((tmp263 < 0) && (tmp262 < tmp264))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp262, tmp264); _i += tmp263)
{
tmpMeta245 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, arrayGet(_finalStatesRefs, _i), _OMC_LIT7);
_exp = tmpMeta245;
tmpMeta246 = MMC_REFSTRUCTLIT(mmc_nil);
_expLst = tmpMeta246;
tmp252 = ((modelica_integer) 1); tmp253 = 1; tmp254 = _nTransitions;
if(!(((tmp253 > 0) && (tmp252 > tmp254)) || ((tmp253 < 0) && (tmp252 < tmp254))))
{
modelica_integer _j;
for(_j = ((modelica_integer) 1); in_range_integer(_j, tmp252, tmp254); _j += tmp253)
{
tmpMeta247 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, arrayGet(_tFromRefs, _j), _OMC_LIT52);
tmpMeta248 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta249 = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, tmpMeta247, _OMC_LIT81, tmpMeta248, mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
_expCond = tmpMeta249;
tmpMeta251 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _OMC_LIT79, _OMC_LIT71);
tmpMeta250 = mmc_mk_cons(tmpMeta251, _expLst);
_expLst = tmpMeta250;
}
}
tmp257 = (modelica_boolean)(listLength(_expLst) > ((modelica_integer) 1));
if(tmp257)
{
tmpMeta255 = mmc_mk_cons(omc_Expression_makeScalarArray(threadData, _expLst, _OMC_LIT52), MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta256 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT83, tmpMeta255, _OMC_LIT84);
tmpMeta258 = tmpMeta256;
}
else
{
tmpMeta258 = listHead(_expLst);
}
_exp1 = tmpMeta258;
tmpMeta259 = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, _exp1, _OMC_LIT81, _OMC_LIT71, mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
_rhs = tmpMeta259;
tmpMeta261 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _rhs, _OMC_LIT33);
tmpMeta260 = mmc_mk_cons(tmpMeta261, _eqs);
_eqs = tmpMeta260;
}
}
tmpMeta265 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _stateMachineInFinalStateRef, _OMC_LIT7);
_exp = tmpMeta265;
tmpMeta267 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeStateRef, _OMC_LIT52);
tmpMeta268 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta267);
tmpMeta266 = mmc_mk_cons(tmpMeta268, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta269 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT75, _nStatesArrayBool, tmpMeta266, _preRef), _OMC_LIT7);
_rhs = tmpMeta269;
tmpMeta271 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _rhs, _OMC_LIT33);
tmpMeta270 = mmc_mk_cons(tmpMeta271, _eqs);
_eqs = tmpMeta270;
tmpMeta272 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta273 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta274 = mmc_mk_box11(3, &StateMachineFlatten_FlatSmSemantics_FLAT__SM__SEMANTICS__desc, _ident, listArray(_q), _t, _cExps, _vars, _knowns, _eqs, tmpMeta272, tmpMeta273, mmc_mk_none());
_flatSmSemantics = tmpMeta274;
_return: OMC_LABEL_UNUSED
return _flatSmSemantics;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_setVarFixedStartValue(threadData_t *threadData, modelica_metatype _inVar, modelica_metatype _inExp)
{
modelica_metatype _outVar = NULL;
modelica_metatype _vao = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inVar;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,0,13) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 12));
_vao = tmpMeta2;
_vao = omc_DAEUtil_setStartAttrOption(threadData, _vao, mmc_mk_some(_inExp));
_vao = omc_DAEUtil_setFixedAttr(threadData, _vao, _OMC_LIT86);
_outVar = omc_DAEUtil_setVariableAttributes(threadData, _inVar, _vao);
_return: OMC_LABEL_UNUSED
return _outVar;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_createActiveIndicator(threadData_t *threadData, modelica_metatype _stateRef, modelica_metatype _preRef, modelica_integer _i, modelica_metatype *out_eqn)
{
modelica_metatype _activePlotIndicatorVar = NULL;
modelica_metatype _eqn = NULL;
modelica_metatype _activeRef = NULL;
modelica_metatype _activePlotIndicatorRef = NULL;
modelica_metatype _activeStateRef = NULL;
modelica_metatype _andExp = NULL;
modelica_metatype _eqExp = NULL;
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
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_activePlotIndicatorRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT63, _OMC_LIT7, tmpMeta1, _stateRef);
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
_activePlotIndicatorVar = omc_StateMachineFlatten_createVarWithStartValue(threadData, _activePlotIndicatorRef, _OMC_LIT51, _OMC_LIT7, _OMC_LIT62, tmpMeta2);
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
_activeRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT63, _OMC_LIT7, tmpMeta3, _preRef);
tmpMeta4 = MMC_REFSTRUCTLIT(mmc_nil);
_activeStateRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT68, _OMC_LIT52, tmpMeta4, _preRef);
tmpMeta5 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeStateRef, _OMC_LIT52);
tmpMeta6 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta7 = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, tmpMeta5, _OMC_LIT81, tmpMeta6, mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
_eqExp = tmpMeta7;
tmpMeta8 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeRef, _OMC_LIT7);
tmpMeta9 = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, tmpMeta8, _OMC_LIT87, _eqExp);
_andExp = tmpMeta9;
tmpMeta10 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activePlotIndicatorRef, _OMC_LIT7);
tmpMeta11 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, tmpMeta10, _andExp, _OMC_LIT33);
_eqn = tmpMeta11;
_return: OMC_LABEL_UNUSED
if (out_eqn) { *out_eqn = _eqn; }
return _activePlotIndicatorVar;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_createActiveIndicator(threadData_t *threadData, modelica_metatype _stateRef, modelica_metatype _preRef, modelica_metatype _i, modelica_metatype *out_eqn)
{
modelica_integer tmp1;
modelica_metatype _activePlotIndicatorVar = NULL;
tmp1 = mmc_unbox_integer(_i);
_activePlotIndicatorVar = omc_StateMachineFlatten_createActiveIndicator(threadData, _stateRef, _preRef, tmp1, out_eqn);
return _activePlotIndicatorVar;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_createTicksInStateIndicator(threadData_t *threadData, modelica_metatype _stateRef, modelica_metatype _stateActiveRef, modelica_metatype *out_ticksInStateEqn)
{
modelica_metatype _ticksInStateVar = NULL;
modelica_metatype _ticksInStateEqn = NULL;
modelica_metatype _ticksInStateRef = NULL;
modelica_metatype _ticksInStateExp = NULL;
modelica_metatype _expCond = NULL;
modelica_metatype _expThen = NULL;
modelica_metatype _expElse = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_ticksInStateRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT88, _OMC_LIT52, tmpMeta1, _stateRef);
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
_ticksInStateVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _ticksInStateRef, _OMC_LIT51, _OMC_LIT52, tmpMeta2);
_ticksInStateVar = omc_StateMachineFlatten_setVarFixedStartValue(threadData, _ticksInStateVar, _OMC_LIT71);
tmpMeta3 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _ticksInStateRef, _OMC_LIT52);
_ticksInStateExp = tmpMeta3;
_expCond = omc_Expression_crefExp(threadData, _stateActiveRef);
tmpMeta4 = mmc_mk_cons(_ticksInStateExp, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta5 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta4, _OMC_LIT80);
tmpMeta6 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta5, _OMC_LIT89, _OMC_LIT79);
_expThen = tmpMeta6;
_expElse = _OMC_LIT71;
tmpMeta7 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
tmpMeta8 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _ticksInStateExp, tmpMeta7, _OMC_LIT33);
_ticksInStateEqn = tmpMeta8;
_return: OMC_LABEL_UNUSED
if (out_ticksInStateEqn) { *out_ticksInStateEqn = _ticksInStateEqn; }
return _ticksInStateVar;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_createTimeEnteredStateIndicator(threadData_t *threadData, modelica_metatype _stateRef, modelica_metatype _stateActiveRef, modelica_metatype *out_timeEnteredStateEqn)
{
modelica_metatype _timeEnteredStateVar = NULL;
modelica_metatype _timeEnteredStateEqn = NULL;
modelica_metatype _timeEnteredStateRef = NULL;
modelica_metatype _timeEnteredStateExp = NULL;
modelica_metatype _stateActiveExp = NULL;
modelica_metatype _expCond = NULL;
modelica_metatype _expThen = NULL;
modelica_metatype _expElse = NULL;
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
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_timeEnteredStateRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT90, _OMC_LIT91, tmpMeta1, _stateRef);
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
_timeEnteredStateVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _timeEnteredStateRef, _OMC_LIT51, _OMC_LIT91, tmpMeta2);
_timeEnteredStateVar = omc_StateMachineFlatten_setVarFixedStartValue(threadData, _timeEnteredStateVar, _OMC_LIT92);
tmpMeta3 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _timeEnteredStateRef, _OMC_LIT91);
_timeEnteredStateExp = tmpMeta3;
_stateActiveExp = omc_Expression_crefExp(threadData, _stateActiveRef);
tmpMeta4 = mmc_mk_cons(_stateActiveExp, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta5 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta4, _OMC_LIT10);
tmpMeta6 = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, tmpMeta5, _OMC_LIT93, _OMC_LIT62, mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
tmpMeta7 = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, _stateActiveExp, _OMC_LIT93, _OMC_LIT77, mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
tmpMeta8 = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, tmpMeta6, _OMC_LIT87, tmpMeta7);
_expCond = tmpMeta8;
_expThen = _OMC_LIT102;
tmpMeta9 = mmc_mk_cons(_timeEnteredStateExp, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta10 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta9, _OMC_LIT101);
_expElse = tmpMeta10;
tmpMeta11 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
tmpMeta12 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _timeEnteredStateExp, tmpMeta11, _OMC_LIT33);
_timeEnteredStateEqn = tmpMeta12;
_return: OMC_LABEL_UNUSED
if (out_timeEnteredStateEqn) { *out_timeEnteredStateEqn = _timeEnteredStateEqn; }
return _timeEnteredStateVar;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_createTimeInStateIndicator(threadData_t *threadData, modelica_metatype _stateRef, modelica_metatype _stateActiveRef, modelica_metatype _timeEnteredStateVar, modelica_metatype *out_timeInStateEqn)
{
modelica_metatype _timeInStateVar = NULL;
modelica_metatype _timeInStateEqn = NULL;
modelica_metatype _timeInStateRef = NULL;
modelica_metatype _timeEnteredStateRef = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _timeInStateExp = NULL;
modelica_metatype _timeEnteredStateExp = NULL;
modelica_metatype _stateActiveExp = NULL;
modelica_metatype _expCond = NULL;
modelica_metatype _expSampleTime = NULL;
modelica_metatype _expThen = NULL;
modelica_metatype _expElse = NULL;
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
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_timeInStateRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT103, _OMC_LIT91, tmpMeta1, _stateRef);
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
_timeInStateVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _timeInStateRef, _OMC_LIT51, _OMC_LIT91, tmpMeta2);
_timeInStateVar = omc_StateMachineFlatten_setVarFixedStartValue(threadData, _timeInStateVar, _OMC_LIT92);
tmpMeta3 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _timeInStateRef, _OMC_LIT91);
_timeInStateExp = tmpMeta3;
tmpMeta4 = _timeEnteredStateVar;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta4,0,13) == 0) MMC_THROW_INTERNAL();
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta4), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta4), 7));
_timeEnteredStateRef = tmpMeta5;
_ty = tmpMeta6;
tmpMeta7 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _timeEnteredStateRef, _ty);
_timeEnteredStateExp = tmpMeta7;
_stateActiveExp = omc_Expression_crefExp(threadData, _stateActiveRef);
_expCond = omc_Expression_crefExp(threadData, _stateActiveRef);
_expSampleTime = _OMC_LIT102;
tmpMeta8 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _expSampleTime, _OMC_LIT104, _timeEnteredStateExp);
_expThen = tmpMeta8;
_expElse = _OMC_LIT92;
tmpMeta9 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
tmpMeta10 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _timeInStateExp, tmpMeta9, _OMC_LIT33);
_timeInStateEqn = tmpMeta10;
_return: OMC_LABEL_UNUSED
if (out_timeInStateEqn) { *out_timeInStateEqn = _timeInStateEqn; }
return _timeInStateVar;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_addPropagationEquations(threadData_t *threadData, modelica_metatype _inFlatSmSemantics, modelica_metatype _inEnclosingStateCrefOption, modelica_metatype _inEnclosingFlatSmSemanticsOption)
{
modelica_metatype _outFlatSmSemantics = NULL;
modelica_metatype _preRef = NULL;
modelica_metatype _initStateRef = NULL;
modelica_metatype _initRef = NULL;
modelica_metatype _resetRef = NULL;
modelica_metatype _activeRef = NULL;
modelica_metatype _stateRef = NULL;
modelica_metatype _activePlotIndicatorRef = NULL;
modelica_metatype _initVar = NULL;
modelica_metatype _activePlotIndicatorVar = NULL;
modelica_metatype _ticksInStateVar = NULL;
modelica_metatype _timeEnteredStateVar = NULL;
modelica_metatype _timeInStateVar = NULL;
modelica_metatype _activePlotIndicatorEqn = NULL;
modelica_metatype _ticksInStateEqn = NULL;
modelica_metatype _timeEnteredStateEqn = NULL;
modelica_metatype _timeInStateEqn = NULL;
modelica_metatype _rhs = NULL;
modelica_metatype _andExp = NULL;
modelica_metatype _eqExp = NULL;
modelica_metatype _activeResetStateRefExp = NULL;
modelica_metatype _activeStateRefExp = NULL;
modelica_metatype _activeResetRefExp = NULL;
modelica_metatype _tArrayBool = NULL;
modelica_metatype _tArrayInteger = NULL;
modelica_string _ident = NULL;
modelica_metatype _smComps = NULL;
modelica_metatype _t = NULL;
modelica_metatype _c = NULL;
modelica_metatype _smvars = NULL;
modelica_metatype _smknowns = NULL;
modelica_metatype _smeqs = NULL;
modelica_metatype _enclosingStateOption = NULL;
modelica_metatype _pvars = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _peqs = NULL;
modelica_metatype tmpMeta2;
modelica_metatype _enclosingStateCref = NULL;
modelica_metatype _enclosingPreRef = NULL;
modelica_metatype _enclosingActiveResetStateRef = NULL;
modelica_metatype _enclosingActiveResetRef = NULL;
modelica_metatype _enclosingActiveStateRef = NULL;
modelica_metatype _enclosingFlatSMSemantics = NULL;
modelica_metatype _enclosingFlatSMComps = NULL;
modelica_metatype _enclosingFlatSMInitStateRef = NULL;
modelica_integer _posOfEnclosingSMComp;
modelica_integer _nStates;
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
modelica_metatype tmpMeta72;
modelica_integer tmp73;
modelica_integer tmp74;
modelica_integer tmp75;
modelica_metatype tmpMeta76;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_pvars = tmpMeta1;
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
_peqs = tmpMeta2;
tmpMeta3 = _inFlatSmSemantics;
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 2));
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 3));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 4));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 5));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 6));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 7));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 8));
_ident = tmpMeta4;
_smComps = tmpMeta5;
_t = tmpMeta6;
_c = tmpMeta7;
_smvars = tmpMeta8;
_smknowns = tmpMeta9;
_smeqs = tmpMeta10;
tmpMeta11 = arrayGet(_smComps, ((modelica_integer) 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,29,2) == 0) MMC_THROW_INTERNAL();
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
_initStateRef = tmpMeta12;
_preRef = omc_ComponentReference_crefPrefixString(threadData, _OMC_LIT4, _initStateRef);
tmpMeta13 = MMC_REFSTRUCTLIT(mmc_nil);
_activeRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT63, _OMC_LIT7, tmpMeta13, _preRef);
tmpMeta14 = MMC_REFSTRUCTLIT(mmc_nil);
_resetRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT64, _OMC_LIT7, tmpMeta14, _preRef);
if(isNone(_inEnclosingFlatSmSemanticsOption))
{
tmpMeta15 = MMC_REFSTRUCTLIT(mmc_nil);
_initRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT106, _OMC_LIT7, tmpMeta15, _preRef);
tmpMeta16 = MMC_REFSTRUCTLIT(mmc_nil);
_initVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _initRef, _OMC_LIT51, _OMC_LIT7, tmpMeta16);
_initVar = omc_StateMachineFlatten_setVarFixedStartValue(threadData, _initVar, _OMC_LIT77);
tmpMeta17 = mmc_mk_cons(_initVar, _pvars);
_pvars = tmpMeta17;
tmpMeta19 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _initRef, _OMC_LIT7);
tmpMeta20 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, tmpMeta19, _OMC_LIT62, _OMC_LIT33);
tmpMeta18 = mmc_mk_cons(tmpMeta20, _peqs);
_peqs = tmpMeta18;
tmpMeta22 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _initRef, _OMC_LIT7);
tmpMeta21 = mmc_mk_cons(tmpMeta22, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta23 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta21, _OMC_LIT10);
_rhs = tmpMeta23;
tmpMeta25 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _resetRef, _OMC_LIT7);
tmpMeta26 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, tmpMeta25, _rhs, _OMC_LIT33);
tmpMeta24 = mmc_mk_cons(tmpMeta26, _peqs);
_peqs = tmpMeta24;
tmpMeta28 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeRef, _OMC_LIT7);
tmpMeta29 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, tmpMeta28, _OMC_LIT77, _OMC_LIT33);
tmpMeta27 = mmc_mk_cons(tmpMeta29, _peqs);
_peqs = tmpMeta27;
}
else
{
_enclosingStateCref = omc_Util_getOption(threadData, _inEnclosingStateCrefOption);
_enclosingFlatSMSemantics = omc_Util_getOption(threadData, _inEnclosingFlatSmSemanticsOption);
tmpMeta30 = _enclosingFlatSMSemantics;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 3));
_enclosingFlatSMComps = tmpMeta31;
tmpMeta32 = arrayGet(_enclosingFlatSMComps, ((modelica_integer) 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta32,29,2) == 0) MMC_THROW_INTERNAL();
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 2));
_enclosingFlatSMInitStateRef = tmpMeta33;
_enclosingPreRef = omc_ComponentReference_crefPrefixString(threadData, _OMC_LIT4, _enclosingFlatSMInitStateRef);
_posOfEnclosingSMComp = omc_List_position1OnTrue(threadData, arrayList(_enclosingFlatSMComps), boxvar_StateMachineFlatten_sMCompEqualsRef, _enclosingStateCref);
_nStates = arrayLength(_enclosingFlatSMComps);
tmpMeta35 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_nStates));
tmpMeta34 = mmc_mk_cons(tmpMeta35, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta36 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT7, tmpMeta34);
_tArrayBool = tmpMeta36;
tmpMeta38 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_nStates));
tmpMeta37 = mmc_mk_cons(tmpMeta38, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta39 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT52, tmpMeta37);
_tArrayInteger = tmpMeta39;
tmpMeta41 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_posOfEnclosingSMComp));
tmpMeta42 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta41);
tmpMeta40 = mmc_mk_cons(tmpMeta42, MMC_REFSTRUCTLIT(mmc_nil));
_enclosingActiveResetStateRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT73, _tArrayBool, tmpMeta40, _enclosingPreRef);
tmpMeta43 = MMC_REFSTRUCTLIT(mmc_nil);
_enclosingActiveResetRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT69, _OMC_LIT7, tmpMeta43, _enclosingPreRef);
tmpMeta44 = MMC_REFSTRUCTLIT(mmc_nil);
_enclosingActiveStateRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT68, _OMC_LIT52, tmpMeta44, _enclosingPreRef);
tmpMeta45 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _enclosingActiveStateRef, _OMC_LIT52);
tmpMeta46 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_posOfEnclosingSMComp));
tmpMeta47 = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, tmpMeta45, _OMC_LIT81, tmpMeta46, mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
_eqExp = tmpMeta47;
tmpMeta48 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _enclosingActiveResetRef, _OMC_LIT7);
tmpMeta49 = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, tmpMeta48, _OMC_LIT87, _eqExp);
_andExp = tmpMeta49;
tmpMeta50 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _enclosingActiveResetStateRef, _OMC_LIT7);
tmpMeta51 = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, tmpMeta50, _OMC_LIT105, _andExp);
_rhs = tmpMeta51;
tmpMeta53 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _resetRef, _OMC_LIT7);
tmpMeta54 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, tmpMeta53, _rhs, _OMC_LIT33);
tmpMeta52 = mmc_mk_cons(tmpMeta54, _peqs);
_peqs = tmpMeta52;
tmpMeta55 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _enclosingActiveStateRef, _OMC_LIT52);
tmpMeta56 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_posOfEnclosingSMComp));
tmpMeta57 = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, tmpMeta55, _OMC_LIT81, tmpMeta56, mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
_rhs = tmpMeta57;
tmpMeta59 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeRef, _OMC_LIT7);
tmpMeta60 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, tmpMeta59, _rhs, _OMC_LIT33);
tmpMeta58 = mmc_mk_cons(tmpMeta60, _peqs);
_peqs = tmpMeta58;
}
tmp73 = ((modelica_integer) 1); tmp74 = 1; tmp75 = arrayLength(_smComps);
if(!(((tmp74 > 0) && (tmp73 > tmp75)) || ((tmp74 < 0) && (tmp73 < tmp75))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp73, tmp75); _i += tmp74)
{
tmpMeta61 = arrayGet(_smComps, _i);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta61,29,2) == 0) MMC_THROW_INTERNAL();
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta61), 2));
_stateRef = tmpMeta62;
_activePlotIndicatorVar = omc_StateMachineFlatten_createActiveIndicator(threadData, _stateRef, _preRef, _i ,&_activePlotIndicatorEqn);
tmpMeta63 = mmc_mk_cons(_activePlotIndicatorVar, _pvars);
_pvars = tmpMeta63;
tmpMeta64 = mmc_mk_cons(_activePlotIndicatorEqn, _peqs);
_peqs = tmpMeta64;
tmpMeta65 = _activePlotIndicatorVar;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta65,0,13) == 0) MMC_THROW_INTERNAL();
tmpMeta66 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta65), 2));
_activePlotIndicatorRef = tmpMeta66;
_ticksInStateVar = omc_StateMachineFlatten_createTicksInStateIndicator(threadData, _stateRef, _activePlotIndicatorRef ,&_ticksInStateEqn);
tmpMeta67 = mmc_mk_cons(_ticksInStateVar, _pvars);
_pvars = tmpMeta67;
tmpMeta68 = mmc_mk_cons(_ticksInStateEqn, _peqs);
_peqs = tmpMeta68;
_timeEnteredStateVar = omc_StateMachineFlatten_createTimeEnteredStateIndicator(threadData, _stateRef, _activePlotIndicatorRef ,&_timeEnteredStateEqn);
_timeInStateVar = omc_StateMachineFlatten_createTimeInStateIndicator(threadData, _stateRef, _activePlotIndicatorRef, _timeEnteredStateVar ,&_timeInStateEqn);
tmpMeta70 = mmc_mk_cons(_timeInStateVar, _pvars);
tmpMeta69 = mmc_mk_cons(_timeEnteredStateVar, tmpMeta70);
_pvars = tmpMeta69;
tmpMeta72 = mmc_mk_cons(_timeInStateEqn, _peqs);
tmpMeta71 = mmc_mk_cons(_timeEnteredStateEqn, tmpMeta72);
_peqs = tmpMeta71;
}
}
tmpMeta76 = mmc_mk_box11(3, &StateMachineFlatten_FlatSmSemantics_FLAT__SM__SEMANTICS__desc, _ident, _smComps, _t, _c, _smvars, _smknowns, _smeqs, _pvars, _peqs, _inEnclosingStateCrefOption);
_outFlatSmSemantics = tmpMeta76;
_return: OMC_LABEL_UNUSED
return _outFlatSmSemantics;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_getStartAttrOption(threadData_t *threadData, modelica_metatype _inVarAttrOpt)
{
modelica_metatype _outExpOpt = NULL;
modelica_metatype _start = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(isSome(_inVarAttrOpt))
{
_start = omc_DAEUtil_getStartAttr(threadData, _inVarAttrOpt);
_outExpOpt = mmc_mk_some(_start);
}
else
{
_outExpOpt = mmc_mk_none();
}
_return: OMC_LABEL_UNUSED
return _outExpOpt;
}
static modelica_metatype closure1_ComponentReference_crefEqual(threadData_t *thData, modelica_metatype closure, modelica_metatype inComponentRef2)
{
modelica_metatype inComponentRef1 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_ComponentReference_crefEqual(thData, inComponentRef1, inComponentRef2);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_traversingSubsPreviousCrefs(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inCrefsHit, modelica_boolean *out_cont, modelica_metatype *out_outCrefsHit)
{
modelica_metatype _outExp = NULL;
modelica_boolean _cont;
modelica_metatype _outCrefsHit = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cont = 1;
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _inCrefsHit;
{
modelica_metatype _cr = NULL;
modelica_metatype _substituteRef = NULL;
modelica_metatype _crefs = NULL;
modelica_metatype _ty = NULL;
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
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (8 != MMC_STRLEN(tmpMeta7) || strcmp(MMC_STRINGDATA(_OMC_LIT3), MMC_STRINGDATA(tmpMeta7)) != 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,6,2) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 3));
if (!listEmpty(tmpMeta10)) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
_cr = tmpMeta11;
_ty = tmpMeta12;
_crefs = tmpMeta13;
tmpMeta14 = mmc_mk_box1(0, _cr);
if (!omc_List_exist(threadData, _crefs, (modelica_fnptr) mmc_mk_box2(0,closure1_ComponentReference_crefEqual,tmpMeta14))) goto tmp3_end;
_substituteRef = omc_ComponentReference_appendStringLastIdent(threadData, _OMC_LIT107, _cr);
tmpMeta15 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _substituteRef, _ty);
tmpMeta16 = mmc_mk_box2(0, _crefs, mmc_mk_boolean(1));
tmpMeta[0+0] = tmpMeta15;
tmpMeta[0+1] = tmpMeta16;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inCrefsHit;
goto tmp3_done;
}
}
goto tmp3_end;
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
_outCrefsHit = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_cont) { *out_cont = _cont; }
if (out_outCrefsHit) { *out_outCrefsHit = _outCrefsHit; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_traversingSubsPreviousCrefs(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inCrefsHit, modelica_metatype *out_cont, modelica_metatype *out_outCrefsHit)
{
modelica_boolean _cont;
modelica_metatype _outExp = NULL;
_outExp = omc_StateMachineFlatten_traversingSubsPreviousCrefs(threadData, _inExp, _inCrefsHit, &_cont, out_outCrefsHit);
if (out_cont) { *out_cont = mmc_mk_icon(_cont); }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_traversingSubsPreviousCref(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inCrefHit, modelica_boolean *out_cont, modelica_metatype *out_outCrefHit)
{
modelica_metatype _outExp = NULL;
modelica_boolean _cont;
modelica_metatype _outCrefHit = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cont = 1;
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _inCrefHit;
{
modelica_metatype _cr = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _substituteRef = NULL;
modelica_metatype _ty = NULL;
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
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (8 != MMC_STRLEN(tmpMeta7) || strcmp(MMC_STRINGDATA(_OMC_LIT3), MMC_STRINGDATA(tmpMeta7)) != 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,6,2) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 3));
if (!listEmpty(tmpMeta10)) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
_cr = tmpMeta11;
_ty = tmpMeta12;
_cref = tmpMeta13;
if (!omc_ComponentReference_crefEqual(threadData, _cr, _cref)) goto tmp3_end;
tmpMeta14 = stringAppend(_OMC_LIT108,omc_ComponentReference_crefStr(threadData, _cr));
tmpMeta15 = stringAppend(tmpMeta14,_OMC_LIT109);
tmpMeta16 = stringAppend(tmpMeta15,omc_ComponentReference_crefStr(threadData, _cref));
tmpMeta17 = stringAppend(tmpMeta16,_OMC_LIT110);
fputs(MMC_STRINGDATA(tmpMeta17),stdout);
_substituteRef = omc_ComponentReference_appendStringLastIdent(threadData, _OMC_LIT107, _cref);
tmpMeta18 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _substituteRef, _ty);
tmpMeta19 = mmc_mk_box2(0, _cref, mmc_mk_boolean(1));
tmpMeta[0+0] = tmpMeta18;
tmpMeta[0+1] = tmpMeta19;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inCrefHit;
goto tmp3_done;
}
}
goto tmp3_end;
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
_outCrefHit = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_cont) { *out_cont = _cont; }
if (out_outCrefHit) { *out_outCrefHit = _outCrefHit; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_traversingSubsPreviousCref(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inCrefHit, modelica_metatype *out_cont, modelica_metatype *out_outCrefHit)
{
modelica_boolean _cont;
modelica_metatype _outExp = NULL;
_outExp = omc_StateMachineFlatten_traversingSubsPreviousCref(threadData, _inExp, _inCrefHit, &_cont, out_outCrefHit);
if (out_cont) { *out_cont = mmc_mk_icon(_cont); }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_wrapInStateActivationConditionalCT(threadData_t *threadData, modelica_metatype _inEqn, modelica_metatype _inStateCref)
{
modelica_metatype _outEqn = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _scalar = NULL;
modelica_metatype _scalar1 = NULL;
modelica_metatype _activeRef = NULL;
modelica_metatype _expElse = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _callAttributes = NULL;
modelica_metatype _source = NULL;
modelica_metatype _cref = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inEqn;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,3,3) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
_exp = tmpMeta2;
_scalar = tmpMeta3;
_source = tmpMeta4;
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
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
tmpMeta9 = _exp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,13,3) == 0) goto goto_5;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,1,1) == 0) goto goto_5;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
if (3 != MMC_STRLEN(tmpMeta11) || strcmp("der", MMC_STRINGDATA(tmpMeta11)) != 0) goto goto_5;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 3));
if (listEmpty(tmpMeta12)) goto goto_5;
tmpMeta13 = MMC_CAR(tmpMeta12);
tmpMeta14 = MMC_CDR(tmpMeta12);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,6,2) == 0) goto goto_5;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 3));
if (!listEmpty(tmpMeta14)) goto goto_5;
_cref = tmpMeta15;
_ty = tmpMeta16;
goto tmp6_done;
}
case 1: {
omc_Error_addCompilerError(threadData, _OMC_LIT111);
goto goto_5;
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
tmpMeta17 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta18 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT63, _OMC_LIT7, tmpMeta17, _inStateCref), _OMC_LIT7);
_activeRef = tmpMeta18;
tmpMeta19 = mmc_mk_box8(3, &DAE_CallAttributes_CALL__ATTR__desc, _ty, mmc_mk_boolean(0), mmc_mk_boolean(1), mmc_mk_boolean(0), mmc_mk_boolean(0), _OMC_LIT8, _OMC_LIT9);
_callAttributes = tmpMeta19;
_expElse = _OMC_LIT92;
tmpMeta20 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _activeRef, _scalar, _expElse);
_scalar1 = tmpMeta20;
tmpMeta21 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _scalar1, _source);
_outEqn = tmpMeta21;
_return: OMC_LABEL_UNUSED
return _outEqn;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_wrapInStateActivationConditional(threadData_t *threadData, modelica_metatype _inEqn, modelica_metatype _inStateCref, modelica_boolean _isResetEquation)
{
modelica_metatype _outEqn = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _scalar = NULL;
modelica_metatype _scalar1 = NULL;
modelica_metatype _activeRef = NULL;
modelica_metatype _expElse = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _callAttributes = NULL;
modelica_metatype _source = NULL;
modelica_metatype _cref = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inEqn;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,3,3) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
_exp = tmpMeta2;
_scalar = tmpMeta3;
_source = tmpMeta4;
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
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
tmpMeta9 = _exp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,6,2) == 0) goto goto_5;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 3));
_cref = tmpMeta10;
_ty = tmpMeta11;
goto tmp6_done;
}
case 1: {
omc_Error_addCompilerError(threadData, _OMC_LIT112);
goto goto_5;
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
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta13 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT63, _OMC_LIT7, tmpMeta12, _inStateCref), _OMC_LIT7);
_activeRef = tmpMeta13;
tmpMeta14 = mmc_mk_box8(3, &DAE_CallAttributes_CALL__ATTR__desc, _ty, mmc_mk_boolean(0), mmc_mk_boolean(1), mmc_mk_boolean(0), mmc_mk_boolean(0), _OMC_LIT8, _OMC_LIT9);
_callAttributes = tmpMeta14;
if(_isResetEquation)
{
tmpMeta15 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_ComponentReference_appendStringLastIdent(threadData, _OMC_LIT107, _cref), _ty);
_expElse = tmpMeta15;
}
else
{
tmpMeta16 = mmc_mk_cons(_exp, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta17 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta16, _callAttributes);
_expElse = tmpMeta17;
}
tmpMeta18 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _activeRef, _scalar, _expElse);
_scalar1 = tmpMeta18;
tmpMeta19 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _scalar1, _source);
_outEqn = tmpMeta19;
_return: OMC_LABEL_UNUSED
return _outEqn;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_wrapInStateActivationConditional(threadData_t *threadData, modelica_metatype _inEqn, modelica_metatype _inStateCref, modelica_metatype _isResetEquation)
{
modelica_integer tmp1;
modelica_metatype _outEqn = NULL;
tmp1 = mmc_unbox_integer(_isResetEquation);
_outEqn = omc_StateMachineFlatten_wrapInStateActivationConditional(threadData, _inEqn, _inStateCref, tmp1);
return _outEqn;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_createResetEquation(threadData_t *threadData, modelica_metatype _inLHSCref, modelica_metatype _inLHSty, modelica_metatype _inStateCref, modelica_metatype _inEnclosingFlatSmSemantics, modelica_metatype _crToExpOpt)
{
modelica_metatype _outEqn = NULL;
modelica_metatype _activeExp = NULL;
modelica_metatype _lhsExp = NULL;
modelica_metatype _activeResetExp = NULL;
modelica_metatype _activeResetStatesExp = NULL;
modelica_metatype _orExp = NULL;
modelica_metatype _andExp = NULL;
modelica_metatype _previousExp = NULL;
modelica_metatype _startValueExp = NULL;
modelica_metatype _ifExp = NULL;
modelica_metatype _startValueOpt = NULL;
modelica_metatype _initStateRef = NULL;
modelica_metatype _preRef = NULL;
modelica_integer _i;
modelica_integer _nStates;
modelica_metatype _enclosingFlatSMComps = NULL;
modelica_metatype _tArrayBool = NULL;
modelica_metatype _callAttributes = NULL;
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
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inEnclosingFlatSmSemantics;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_enclosingFlatSMComps = tmpMeta2;
tmpMeta3 = arrayGet(_enclosingFlatSMComps, ((modelica_integer) 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta3,29,2) == 0) MMC_THROW_INTERNAL();
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 2));
_initStateRef = tmpMeta4;
_preRef = omc_ComponentReference_crefPrefixString(threadData, _OMC_LIT4, _initStateRef);
_i = omc_List_position1OnTrue(threadData, arrayList(_enclosingFlatSMComps), boxvar_StateMachineFlatten_sMCompEqualsRef, _inStateCref);
tmpMeta5 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta6 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT69, _OMC_LIT7, tmpMeta5, _preRef), _OMC_LIT7);
_activeResetExp = tmpMeta6;
_nStates = arrayLength(_enclosingFlatSMComps);
tmpMeta8 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_nStates));
tmpMeta7 = mmc_mk_cons(tmpMeta8, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta9 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT7, tmpMeta7);
_tArrayBool = tmpMeta9;
tmpMeta11 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta12 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta11);
tmpMeta10 = mmc_mk_cons(tmpMeta12, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta13 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT73, _tArrayBool, tmpMeta10, _preRef), _OMC_LIT7);
_activeResetStatesExp = tmpMeta13;
tmpMeta14 = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, _activeResetExp, _OMC_LIT105, _activeResetStatesExp);
_orExp = tmpMeta14;
tmpMeta15 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta16 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT63, _OMC_LIT7, tmpMeta15, _inStateCref), _OMC_LIT7);
_activeExp = tmpMeta16;
tmpMeta17 = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, _activeExp, _OMC_LIT87, _orExp);
_andExp = tmpMeta17;
tmpMeta18 = mmc_mk_box8(3, &DAE_CallAttributes_CALL__ATTR__desc, _inLHSty, mmc_mk_boolean(0), mmc_mk_boolean(1), mmc_mk_boolean(0), mmc_mk_boolean(0), _OMC_LIT8, _OMC_LIT9);
_callAttributes = tmpMeta18;
tmpMeta20 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _inLHSCref, _inLHSty);
tmpMeta19 = mmc_mk_cons(tmpMeta20, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta21 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta19, _callAttributes);
_previousExp = tmpMeta21;
_startValueOpt = omc_BaseHashTable_get(threadData, _inLHSCref, _crToExpOpt);
if(isSome(_startValueOpt))
{
_startValueExp = omc_Util_getOption(threadData, _startValueOpt);
}
else
{
{
modelica_metatype tmp25_1;
tmp25_1 = _inLHSty;
{
int tmp25;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp25_1))) {
case 3: {
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
tmpMeta26 = stringAppend(_OMC_LIT113,omc_ComponentReference_crefStr(threadData, _inLHSCref));
tmpMeta27 = stringAppend(tmpMeta26,_OMC_LIT114);
omc_Error_addCompilerWarning(threadData, tmpMeta27);
tmpMeta22 = _OMC_LIT71;
goto tmp24_done;
}
case 4: {
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
tmpMeta28 = stringAppend(_OMC_LIT113,omc_ComponentReference_crefStr(threadData, _inLHSCref));
tmpMeta29 = stringAppend(tmpMeta28,_OMC_LIT114);
omc_Error_addCompilerWarning(threadData, tmpMeta29);
tmpMeta22 = _OMC_LIT92;
goto tmp24_done;
}
case 6: {
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
tmpMeta30 = stringAppend(_OMC_LIT113,omc_ComponentReference_crefStr(threadData, _inLHSCref));
tmpMeta31 = stringAppend(tmpMeta30,_OMC_LIT115);
omc_Error_addCompilerWarning(threadData, tmpMeta31);
tmpMeta22 = _OMC_LIT62;
goto tmp24_done;
}
case 5: {
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
tmpMeta32 = stringAppend(_OMC_LIT113,omc_ComponentReference_crefStr(threadData, _inLHSCref));
tmpMeta33 = stringAppend(tmpMeta32,_OMC_LIT116);
omc_Error_addCompilerWarning(threadData, tmpMeta33);
tmpMeta22 = _OMC_LIT117;
goto tmp24_done;
}
default:
tmp24_default: OMC_LABEL_UNUSED; {
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
tmpMeta34 = stringAppend(_OMC_LIT113,omc_ComponentReference_crefStr(threadData, _inLHSCref));
tmpMeta35 = stringAppend(tmpMeta34,_OMC_LIT118);
omc_Error_addCompilerError(threadData, tmpMeta35);
goto goto_23;
goto tmp24_done;
}
}
goto tmp24_end;
tmp24_end: ;
}
goto goto_23;
goto_23:;
MMC_THROW_INTERNAL();
goto tmp24_done;
tmp24_done:;
}
}
_startValueExp = tmpMeta22;
}
tmpMeta36 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _andExp, _startValueExp, _previousExp);
_ifExp = tmpMeta36;
tmpMeta37 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_ComponentReference_appendStringLastIdent(threadData, _OMC_LIT107, _inLHSCref), _inLHSty);
_lhsExp = tmpMeta37;
tmpMeta38 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _lhsExp, _ifExp, _OMC_LIT33);
_outEqn = tmpMeta38;
_return: OMC_LABEL_UNUSED
return _outEqn;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isCrefInVar(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inCref)
{
modelica_boolean _result;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
modelica_metatype _cref = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cref = tmpMeta6;
if (!omc_ComponentReference_crefEqual(threadData, _cref, _inCref)) goto tmp3_end;
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
_result = tmp1;
_return: OMC_LABEL_UNUSED
return _result;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_isCrefInVar(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inCref)
{
modelica_boolean _result;
modelica_metatype out_result;
_result = omc_StateMachineFlatten_isCrefInVar(threadData, _inElement, _inCref);
out_result = mmc_mk_icon(_result);
return out_result;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_createResetEquationCT(threadData_t *threadData, modelica_metatype _inLHSCref, modelica_metatype _inLHSty, modelica_metatype _inStateCref, modelica_metatype _inEnclosingFlatSmSemantics, modelica_metatype _crToExpOpt)
{
modelica_metatype _outEqn = NULL;
modelica_metatype _activeExp = NULL;
modelica_metatype _activeResetExp = NULL;
modelica_metatype _activeResetStatesExp = NULL;
modelica_metatype _orExp = NULL;
modelica_metatype _andExp = NULL;
modelica_metatype _startValueExp = NULL;
modelica_metatype _preExp = NULL;
modelica_metatype _reinitElem = NULL;
modelica_metatype _startValueOpt = NULL;
modelica_metatype _initStateRef = NULL;
modelica_metatype _preRef = NULL;
modelica_integer _i;
modelica_integer _nStates;
modelica_metatype _enclosingFlatSMComps = NULL;
modelica_metatype _tArrayBool = NULL;
modelica_metatype _callAttributes = NULL;
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
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inEnclosingFlatSmSemantics;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_enclosingFlatSMComps = tmpMeta2;
tmpMeta3 = arrayGet(_enclosingFlatSMComps, ((modelica_integer) 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta3,29,2) == 0) MMC_THROW_INTERNAL();
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 2));
_initStateRef = tmpMeta4;
_preRef = omc_ComponentReference_crefPrefixString(threadData, _OMC_LIT4, _initStateRef);
_i = omc_List_position1OnTrue(threadData, arrayList(_enclosingFlatSMComps), boxvar_StateMachineFlatten_sMCompEqualsRef, _inStateCref);
tmpMeta5 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta6 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT69, _OMC_LIT7, tmpMeta5, _preRef), _OMC_LIT7);
_activeResetExp = tmpMeta6;
_nStates = arrayLength(_enclosingFlatSMComps);
tmpMeta8 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_nStates));
tmpMeta7 = mmc_mk_cons(tmpMeta8, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta9 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT7, tmpMeta7);
_tArrayBool = tmpMeta9;
tmpMeta11 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta12 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta11);
tmpMeta10 = mmc_mk_cons(tmpMeta12, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta13 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT73, _tArrayBool, tmpMeta10, _preRef), _OMC_LIT7);
_activeResetStatesExp = tmpMeta13;
tmpMeta14 = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, _activeResetExp, _OMC_LIT105, _activeResetStatesExp);
_orExp = tmpMeta14;
tmpMeta15 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta16 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT63, _OMC_LIT7, tmpMeta15, _inStateCref), _OMC_LIT7);
_activeExp = tmpMeta16;
tmpMeta17 = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, _activeExp, _OMC_LIT87, _orExp);
_andExp = tmpMeta17;
_startValueOpt = omc_BaseHashTable_get(threadData, _inLHSCref, _crToExpOpt);
if(isSome(_startValueOpt))
{
_startValueExp = omc_Util_getOption(threadData, _startValueOpt);
}
else
{
{
modelica_metatype tmp21_1;
tmp21_1 = _inLHSty;
{
int tmp21;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp21_1))) {
case 3: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
tmpMeta22 = stringAppend(_OMC_LIT113,omc_ComponentReference_crefStr(threadData, _inLHSCref));
tmpMeta23 = stringAppend(tmpMeta22,_OMC_LIT114);
omc_Error_addCompilerWarning(threadData, tmpMeta23);
tmpMeta18 = _OMC_LIT71;
goto tmp20_done;
}
case 4: {
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
tmpMeta24 = stringAppend(_OMC_LIT113,omc_ComponentReference_crefStr(threadData, _inLHSCref));
tmpMeta25 = stringAppend(tmpMeta24,_OMC_LIT114);
omc_Error_addCompilerWarning(threadData, tmpMeta25);
tmpMeta18 = _OMC_LIT92;
goto tmp20_done;
}
case 6: {
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
tmpMeta26 = stringAppend(_OMC_LIT113,omc_ComponentReference_crefStr(threadData, _inLHSCref));
tmpMeta27 = stringAppend(tmpMeta26,_OMC_LIT115);
omc_Error_addCompilerWarning(threadData, tmpMeta27);
tmpMeta18 = _OMC_LIT62;
goto tmp20_done;
}
case 5: {
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
tmpMeta28 = stringAppend(_OMC_LIT113,omc_ComponentReference_crefStr(threadData, _inLHSCref));
tmpMeta29 = stringAppend(tmpMeta28,_OMC_LIT116);
omc_Error_addCompilerWarning(threadData, tmpMeta29);
tmpMeta18 = _OMC_LIT117;
goto tmp20_done;
}
default:
tmp20_default: OMC_LABEL_UNUSED; {
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
tmpMeta30 = stringAppend(_OMC_LIT113,omc_ComponentReference_crefStr(threadData, _inLHSCref));
tmpMeta31 = stringAppend(tmpMeta30,_OMC_LIT118);
omc_Error_addCompilerError(threadData, tmpMeta31);
goto goto_19;
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
_startValueExp = tmpMeta18;
}
tmpMeta32 = mmc_mk_box4(26, &DAE_Element_REINIT__desc, _inLHSCref, _startValueExp, _OMC_LIT33);
_reinitElem = tmpMeta32;
tmpMeta33 = mmc_mk_cons(_reinitElem, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta34 = mmc_mk_box5(13, &DAE_Element_WHEN__EQUATION__desc, _andExp, tmpMeta33, mmc_mk_none(), _OMC_LIT33);
_outEqn = tmpMeta34;
_return: OMC_LABEL_UNUSED
return _outEqn;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_traversingFindPreviousCref(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inCrefHit, modelica_boolean *out_cont, modelica_metatype *out_outCrefHit)
{
modelica_metatype _outExp = NULL;
modelica_boolean _cont;
modelica_metatype _outCrefHit = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cont = 1;
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _inCrefHit;
{
modelica_metatype _cr = NULL;
modelica_metatype _cref = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (8 != MMC_STRLEN(tmpMeta7) || strcmp(MMC_STRINGDATA(_OMC_LIT3), MMC_STRINGDATA(tmpMeta7)) != 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,6,2) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (!listEmpty(tmpMeta10)) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
_cr = tmpMeta11;
_cref = tmpMeta12;
if (!omc_ComponentReference_crefEqual(threadData, _cr, _cref)) goto tmp3_end;
tmpMeta13 = mmc_mk_box2(0, _cref, mmc_mk_boolean(1));
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = tmpMeta13;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inCrefHit;
goto tmp3_done;
}
}
goto tmp3_end;
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
_outCrefHit = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_cont) { *out_cont = _cont; }
if (out_outCrefHit) { *out_outCrefHit = _outCrefHit; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_traversingFindPreviousCref(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inCrefHit, modelica_metatype *out_cont, modelica_metatype *out_outCrefHit)
{
modelica_boolean _cont;
modelica_metatype _outExp = NULL;
_outExp = omc_StateMachineFlatten_traversingFindPreviousCref(threadData, _inExp, _inCrefHit, &_cont, out_outCrefHit);
if (out_cont) { *out_cont = mmc_mk_icon(_cont); }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isPreviousAppliedToVar(threadData_t *threadData, modelica_metatype _eqn, modelica_metatype _var)
{
modelica_boolean _found;
modelica_metatype _cref = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _scalar = NULL;
modelica_metatype _scalarNew = NULL;
modelica_metatype _source = NULL;
modelica_metatype _equations = NULL;
modelica_metatype _elsewhen_ = NULL;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_found = 0;
{
modelica_metatype tmp4_1;
tmp4_1 = _eqn;
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
modelica_metatype tmpMeta10;
modelica_integer tmp11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_exp = tmpMeta6;
_scalar = tmpMeta7;
_source = tmpMeta8;
_cref = omc_DAEUtil_varCref(threadData, _var);
tmpMeta12 = mmc_mk_box2(0, _cref, mmc_mk_boolean(0));
omc_Expression_traverseExpTopDown(threadData, _scalar, boxvar_StateMachineFlatten_traversingFindPreviousCref, tmpMeta12, &tmpMeta9);
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmp11 = mmc_unbox_integer(tmpMeta10);
_found = tmp11;
tmp1 = _found;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!optionNone(tmpMeta14)) goto tmp3_end;
_equations = tmpMeta13;
tmp1 = omc_List_exist1(threadData, _equations, boxvar_StateMachineFlatten_isPreviousAppliedToVar, _var);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (optionNone(tmpMeta15)) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 1));
omc_Error_addCompilerError(threadData, _OMC_LIT119);
goto goto_2;
goto tmp3_done;
}
case 3: {
omc_Error_addCompilerError(threadData, _OMC_LIT120);
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
_found = tmp1;
_return: OMC_LABEL_UNUSED
return _found;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_isPreviousAppliedToVar(threadData_t *threadData, modelica_metatype _eqn, modelica_metatype _var)
{
modelica_boolean _found;
modelica_metatype out_found;
_found = omc_StateMachineFlatten_isPreviousAppliedToVar(threadData, _eqn, _var);
out_found = mmc_mk_icon(_found);
return out_found;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isVarAtLHS(threadData_t *threadData, modelica_metatype _eqn, modelica_metatype _var)
{
modelica_boolean _res;
modelica_metatype _cref = NULL;
modelica_metatype _crefLHS = NULL;
modelica_metatype _tyLHS = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _scalar = NULL;
modelica_metatype _scalarNew = NULL;
modelica_metatype _source = NULL;
modelica_metatype _equations = NULL;
modelica_metatype _elsewhen_ = NULL;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _eqn;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_exp = tmpMeta6;
_scalar = tmpMeta7;
_source = tmpMeta8;
_cref = omc_DAEUtil_varCref(threadData, _var);
{
{
volatile mmc_switch_type tmp11;
int tmp12;
tmp11 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp10_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp11 < 2; tmp11++) {
switch (MMC_SWITCH_CAST(tmp11)) {
case 0: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
tmpMeta13 = _exp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,6,2) == 0) goto goto_9;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 3));
_crefLHS = tmpMeta14;
_tyLHS = tmpMeta15;
_res = omc_ComponentReference_crefEqual(threadData, _crefLHS, _cref);
goto tmp10_done;
}
case 1: {
_res = 0;
goto tmp10_done;
}
}
goto tmp10_end;
tmp10_end: ;
}
goto goto_9;
tmp10_done:
(void)tmp11;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp10_done2;
goto_9:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp11 < 2) {
goto tmp10_top;
}
goto goto_2;
tmp10_done2:;
}
}
;
tmp1 = _res;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!optionNone(tmpMeta17)) goto tmp3_end;
_equations = tmpMeta16;
tmp1 = omc_List_exist1(threadData, _equations, boxvar_StateMachineFlatten_isVarAtLHS, _var);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (optionNone(tmpMeta18)) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 1));
omc_Error_addCompilerError(threadData, _OMC_LIT119);
goto goto_2;
goto tmp3_done;
}
case 3: {
omc_Error_addCompilerError(threadData, _OMC_LIT121);
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_isVarAtLHS(threadData_t *threadData, modelica_metatype _eqn, modelica_metatype _var)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_StateMachineFlatten_isVarAtLHS(threadData, _eqn, _var);
out_res = mmc_mk_icon(_res);
return out_res;
}
static modelica_metatype closure2_ComponentReference_crefEqual(threadData_t *thData, modelica_metatype closure, modelica_metatype inComponentRef2)
{
modelica_metatype inComponentRef1 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_ComponentReference_crefEqual(thData, inComponentRef1, inComponentRef2);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_addStateActivationAndReset1(threadData_t *threadData, modelica_metatype _inEqn, modelica_metatype _inEnclosingSMComp, modelica_metatype _inEnclosingFlatSmSemantics, modelica_metatype _crToExpOpt, modelica_metatype _accEqnsVars)
{
modelica_metatype _outEqnsVars = NULL;
modelica_metatype _stateVarCrefs = NULL;
modelica_metatype _crefLHS = NULL;
modelica_metatype _enclosingStateRef = NULL;
modelica_metatype _substituteRef = NULL;
modelica_metatype _activeResetRef = NULL;
modelica_metatype _activeResetStatesRef = NULL;
modelica_metatype _cref2 = NULL;
modelica_boolean _found;
modelica_boolean _is;
modelica_metatype _tyLHS = NULL;
modelica_metatype _eqn = NULL;
modelica_metatype _eqn1 = NULL;
modelica_metatype _eqn2 = NULL;
modelica_metatype _var2 = NULL;
modelica_metatype _varDecl = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _dAElist = NULL;
modelica_boolean _isOuterVar;
modelica_metatype _exp = NULL;
modelica_metatype _scalar = NULL;
modelica_metatype _scalarNew = NULL;
modelica_metatype _source = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inEqn;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,3,3) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
_exp = tmpMeta2;
_scalar = tmpMeta3;
_source = tmpMeta4;
tmpMeta5 = _inEnclosingSMComp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta5,29,2) == 0) MMC_THROW_INTERNAL();
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 3));
_enclosingStateRef = tmpMeta6;
_dAElist = tmpMeta7;
_stateVarCrefs = omc_BaseHashTable_hashTableKeyList(threadData, _crToExpOpt);
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
modelica_metatype tmpMeta28;
tmpMeta12 = _exp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,6,2) == 0) goto goto_8;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 3));
_crefLHS = tmpMeta13;
_tyLHS = tmpMeta14;
tmpMeta18 = mmc_mk_box2(0, _stateVarCrefs, mmc_mk_boolean(0));
tmpMeta19 = omc_Expression_traverseExpTopDown(threadData, _scalar, boxvar_StateMachineFlatten_traversingSubsPreviousCrefs, tmpMeta18, &tmpMeta15);
_scalarNew = tmpMeta19;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
tmp17 = mmc_unbox_integer(tmpMeta16);
_found = tmp17;
tmpMeta20 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _scalarNew, _source);
_eqn = tmpMeta20;
tmpMeta21 = mmc_mk_box1(0, _crefLHS);
if(omc_List_exist(threadData, _stateVarCrefs, (modelica_fnptr) mmc_mk_box2(0,closure2_ComponentReference_crefEqual,tmpMeta21)))
{
_eqn1 = omc_StateMachineFlatten_wrapInStateActivationConditional(threadData, _eqn, _enclosingStateRef, 1);
tmpMeta22 = MMC_REFSTRUCTLIT(mmc_nil);
_var2 = omc_StateMachineFlatten_createVarWithDefaults(threadData, omc_ComponentReference_appendStringLastIdent(threadData, _OMC_LIT107, _crefLHS), _OMC_LIT51, _tyLHS, tmpMeta22);
_eqn2 = omc_StateMachineFlatten_createResetEquation(threadData, _crefLHS, _tyLHS, _enclosingStateRef, _inEnclosingFlatSmSemantics, _crToExpOpt);
tmpMeta24 = mmc_mk_cons(_eqn2, omc_Util_tuple21(threadData, _accEqnsVars));
tmpMeta23 = mmc_mk_cons(_eqn1, tmpMeta24);
tmpMeta25 = mmc_mk_cons(_var2, omc_Util_tuple22(threadData, _accEqnsVars));
tmpMeta26 = mmc_mk_box2(0, tmpMeta23, tmpMeta25);
_outEqnsVars = tmpMeta26;
}
else
{
tmpMeta27 = mmc_mk_cons(omc_StateMachineFlatten_wrapInStateActivationConditional(threadData, _eqn, _enclosingStateRef, 0), omc_Util_tuple21(threadData, _accEqnsVars));
tmpMeta28 = mmc_mk_box2(0, tmpMeta27, omc_Util_tuple22(threadData, _accEqnsVars));
_outEqnsVars = tmpMeta28;
}
goto tmp9_done;
}
case 1: {
{
{
volatile mmc_switch_type tmp31;
int tmp32;
tmp31 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp30_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp31 < 2; tmp31++) {
switch (MMC_SWITCH_CAST(tmp31)) {
case 0: {
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
if(omc_Flags_getConfigBool(threadData, _OMC_LIT28))
{
tmpMeta33 = _exp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta33,13,3) == 0) goto goto_29;
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta33), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta34,1,1) == 0) goto goto_29;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 2));
if (3 != MMC_STRLEN(tmpMeta35) || strcmp("der", MMC_STRINGDATA(tmpMeta35)) != 0) goto goto_29;
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta33), 3));
if (listEmpty(tmpMeta36)) goto goto_29;
tmpMeta37 = MMC_CAR(tmpMeta36);
tmpMeta38 = MMC_CDR(tmpMeta36);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta37,6,2) == 0) goto goto_29;
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 2));
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 3));
if (!listEmpty(tmpMeta38)) goto goto_29;
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta33), 4));
_crefLHS = tmpMeta39;
_tyLHS = tmpMeta40;
_attr = tmpMeta41;
{
{
volatile mmc_switch_type tmp44;
int tmp45;
tmp44 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp43_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp44 < 2; tmp44++) {
switch (MMC_SWITCH_CAST(tmp44)) {
case 0: {
_varDecl = omc_List_find1(threadData, _dAElist, boxvar_StateMachineFlatten_isCrefInVar, _crefLHS);
goto tmp43_done;
}
case 1: {
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
tmpMeta46 = stringAppend(_OMC_LIT122,omc_ComponentReference_crefStr(threadData, _crefLHS));
tmpMeta47 = stringAppend(tmpMeta46,_OMC_LIT110);
omc_Error_addCompilerError(threadData, tmpMeta47);
goto goto_42;
goto tmp43_done;
}
}
goto tmp43_end;
tmp43_end: ;
}
goto goto_42;
tmp43_done:
(void)tmp44;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp43_done2;
goto_42:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp44 < 2) {
goto tmp43_top;
}
goto goto_29;
tmp43_done2:;
}
}
;
_isOuterVar = omc_DAEUtil_isOuterVar(threadData, _varDecl);
if(_isOuterVar)
{
_cref2 = omc_ComponentReference_appendStringLastIdent(threadData, _OMC_LIT123, _crefLHS);
tmpMeta48 = MMC_REFSTRUCTLIT(mmc_nil);
_var2 = omc_StateMachineFlatten_createVarWithDefaults(threadData, _cref2, _OMC_LIT124, _tyLHS, tmpMeta48);
tmpMeta49 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _cref2, _tyLHS);
tmpMeta50 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, tmpMeta49, _scalar, _source);
_eqn1 = tmpMeta50;
tmpMeta51 = mmc_mk_cons(_eqn1, omc_Util_tuple21(threadData, _accEqnsVars));
tmpMeta52 = mmc_mk_cons(_var2, omc_Util_tuple22(threadData, _accEqnsVars));
tmpMeta53 = mmc_mk_box2(0, tmpMeta51, tmpMeta52);
_outEqnsVars = tmpMeta53;
}
else
{
_eqn1 = omc_StateMachineFlatten_wrapInStateActivationConditionalCT(threadData, _inEqn, _enclosingStateRef);
_eqn2 = omc_StateMachineFlatten_createResetEquationCT(threadData, _crefLHS, _tyLHS, _enclosingStateRef, _inEnclosingFlatSmSemantics, _crToExpOpt);
tmpMeta55 = mmc_mk_cons(_eqn2, omc_Util_tuple21(threadData, _accEqnsVars));
tmpMeta54 = mmc_mk_cons(_eqn1, tmpMeta55);
tmpMeta56 = mmc_mk_box2(0, tmpMeta54, omc_Util_tuple22(threadData, _accEqnsVars));
_outEqnsVars = tmpMeta56;
}
}
else
{
goto goto_29;
}
goto tmp30_done;
}
case 1: {
if(omc_Flags_getConfigBool(threadData, _OMC_LIT28))
{
omc_Error_addCompilerError(threadData, _OMC_LIT126);
}
else
{
omc_Error_addCompilerError(threadData, _OMC_LIT125);
}
goto goto_29;
goto tmp30_done;
}
}
goto tmp30_end;
tmp30_end: ;
}
goto goto_29;
tmp30_done:
(void)tmp31;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp30_done2;
goto_29:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp31 < 2) {
goto tmp30_top;
}
goto goto_8;
tmp30_done2:;
}
}
;
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
_return: OMC_LABEL_UNUSED
return _outEqnsVars;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_addStateActivationAndReset(threadData_t *threadData, modelica_metatype _inEqn, modelica_metatype _inEnclosingSMComp, modelica_metatype _inEnclosingFlatSmSemantics, modelica_metatype _crToExpOpt, modelica_metatype _accEqnsVars)
{
modelica_metatype _outEqnsVars = NULL;
modelica_metatype _equations1 = NULL;
modelica_metatype _vars1 = NULL;
modelica_metatype _condition = NULL;
modelica_metatype _equations = NULL;
modelica_metatype _source = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inEqn;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,3) == 0) goto tmp3_end;
tmpMeta1 = omc_StateMachineFlatten_addStateActivationAndReset1(threadData, _inEqn, _inEnclosingSMComp, _inEnclosingFlatSmSemantics, _crToExpOpt, _accEqnsVars);
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!optionNone(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_condition = tmpMeta6;
_equations = tmpMeta7;
_source = tmpMeta9;
tmpMeta10 = omc_List_fold3(threadData, _equations, boxvar_StateMachineFlatten_addStateActivationAndReset, _inEnclosingSMComp, _inEnclosingFlatSmSemantics, _crToExpOpt, _OMC_LIT127);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 1));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_equations1 = tmpMeta11;
_vars1 = tmpMeta12;
tmpMeta14 = mmc_mk_box5(13, &DAE_Element_WHEN__EQUATION__desc, _condition, _equations1, mmc_mk_none(), _source);
tmpMeta13 = mmc_mk_cons(tmpMeta14, omc_Util_tuple21(threadData, _accEqnsVars));
tmpMeta15 = mmc_mk_box2(0, tmpMeta13, listAppend(_vars1, omc_Util_tuple22(threadData, _accEqnsVars)));
tmpMeta1 = tmpMeta15;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (optionNone(tmpMeta16)) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 1));
omc_Error_addCompilerError(threadData, _OMC_LIT119);
goto goto_2;
goto tmp3_done;
}
case 3: {
omc_Error_addCompilerError(threadData, _OMC_LIT128);
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
_outEqnsVars = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outEqnsVars;
}
static modelica_metatype closure3_List_exist1(threadData_t *thData, modelica_metatype closure, modelica_metatype inExtraArg)
{
modelica_metatype inList = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_fnptr inFindFunc = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_List_exist1(thData, inList, inFindFunc, inExtraArg);
}static modelica_metatype closure4_List_exist1(threadData_t *thData, modelica_metatype closure, modelica_metatype inExtraArg)
{
modelica_metatype inList = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_fnptr inFindFunc = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_List_exist1(thData, inList, inFindFunc, inExtraArg);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_smCompToDataFlow(threadData_t *threadData, modelica_metatype _inSMComp, modelica_metatype _inEnclosingFlatSmSemantics, modelica_metatype _accElems)
{
modelica_metatype _outElems = NULL;
modelica_metatype _varLst1 = NULL;
modelica_metatype _varLst2 = NULL;
modelica_metatype _assignedVarLst = NULL;
modelica_metatype _stateVarLst = NULL;
modelica_metatype _otherLst1 = NULL;
modelica_metatype _equationLst1 = NULL;
modelica_metatype _equationLst2 = NULL;
modelica_metatype _otherLst2 = NULL;
modelica_metatype _flatSmLst = NULL;
modelica_metatype _otherLst3 = NULL;
modelica_metatype _componentRef = NULL;
modelica_metatype _stateVarCrefs = NULL;
modelica_metatype _variableAttributesOptions = NULL;
modelica_metatype _startValuesOpt = NULL;
modelica_metatype _varCrefStartVal = NULL;
modelica_metatype _dAElist = NULL;
modelica_metatype _crToExpOpt = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outElems = _accElems;
tmpMeta1 = _inSMComp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,29,2) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_componentRef = tmpMeta2;
_dAElist = tmpMeta3;
_varLst1 = omc_List_extractOnTrue(threadData, _dAElist, boxvar_StateMachineFlatten_isVar ,&_otherLst1);
_equationLst1 = omc_List_extractOnTrue(threadData, _otherLst1, boxvar_StateMachineFlatten_isEquationOrWhenEquation ,&_otherLst2);
tmpMeta4 = mmc_mk_box2(0, _equationLst1, boxvar_StateMachineFlatten_isVarAtLHS);
_assignedVarLst = omc_List_filterOnTrue(threadData, _varLst1, (modelica_fnptr) mmc_mk_box2(0,closure3_List_exist1,tmpMeta4));
tmpMeta5 = mmc_mk_box2(0, _equationLst1, boxvar_StateMachineFlatten_isPreviousAppliedToVar);
_stateVarLst = omc_List_filterOnTrue(threadData, _varLst1, (modelica_fnptr) mmc_mk_box2(0,closure4_List_exist1,tmpMeta5));
_stateVarCrefs = omc_List_map(threadData, _stateVarLst, boxvar_DAEUtil_varCref);
_variableAttributesOptions = omc_List_map(threadData, _stateVarLst, boxvar_DAEUtil_getVariableAttributes);
_startValuesOpt = omc_List_map(threadData, _variableAttributesOptions, boxvar_StateMachineFlatten_getStartAttrOption);
_varCrefStartVal = omc_List_zip(threadData, _stateVarCrefs, _startValuesOpt);
_crToExpOpt = omc_HashTableCrToExpOption_emptyHashTableSized(threadData, ((modelica_integer) 1) + listLength(_varCrefStartVal));
_crToExpOpt = omc_List_fold(threadData, _varCrefStartVal, boxvar_BaseHashTable_add, _crToExpOpt);
tmpMeta6 = omc_List_fold3(threadData, _equationLst1, boxvar_StateMachineFlatten_addStateActivationAndReset, _inSMComp, _inEnclosingFlatSmSemantics, _crToExpOpt, _OMC_LIT127);
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_equationLst2 = tmpMeta7;
_varLst2 = tmpMeta8;
_flatSmLst = omc_List_extractOnTrue(threadData, _otherLst2, boxvar_StateMachineFlatten_isFlatSm ,&_otherLst3);
tmpMeta9 = mmc_mk_cons(_outElems, mmc_mk_cons(_varLst1, mmc_mk_cons(_varLst2, mmc_mk_cons(_equationLst2, mmc_mk_cons(_otherLst3, MMC_REFSTRUCTLIT(mmc_nil))))));
_outElems = omc_List_flatten(threadData, tmpMeta9);
_outElems = omc_List_fold2(threadData, _flatSmLst, boxvar_StateMachineFlatten_flatSmToDataFlow, mmc_mk_some(_componentRef), mmc_mk_some(_inEnclosingFlatSmSemantics), _outElems);
_return: OMC_LABEL_UNUSED
return _outElems;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_traversingSubsXInState(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inXSubstHit, modelica_boolean *out_cont, modelica_metatype *out_outXSubstHit)
{
modelica_metatype _outExp = NULL;
modelica_boolean _cont;
modelica_metatype _outXSubstHit = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cont = 1;
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _inXSubstHit;
{
modelica_metatype _subsExp = NULL;
modelica_string _xInState = NULL;
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
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_name = tmpMeta7;
_xInState = tmpMeta8;
_subsExp = tmpMeta9;
if (!(stringEqual(_name, _xInState))) goto tmp3_end;
tmpMeta10 = mmc_mk_box3(0, _xInState, _subsExp, mmc_mk_boolean(1));
tmpMeta[0+0] = _subsExp;
tmpMeta[0+1] = tmpMeta10;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inXSubstHit;
goto tmp3_done;
}
}
goto tmp3_end;
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
_outXSubstHit = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_cont) { *out_cont = _cont; }
if (out_outXSubstHit) { *out_outXSubstHit = _outXSubstHit; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_traversingSubsXInState(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inXSubstHit, modelica_metatype *out_cont, modelica_metatype *out_outXSubstHit)
{
modelica_boolean _cont;
modelica_metatype _outExp = NULL;
_outExp = omc_StateMachineFlatten_traversingSubsXInState(threadData, _inExp, _inXSubstHit, &_cont, out_outXSubstHit);
if (out_cont) { *out_cont = mmc_mk_icon(_cont); }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_smeqsSubsXInState(threadData_t *threadData, modelica_metatype _inSmeqs, modelica_metatype _initialStateComp, modelica_integer _i, modelica_integer _nTransitions, modelica_metatype _substExp, modelica_string _xInState)
{
modelica_metatype _outSmeqs = NULL;
modelica_metatype _preRef = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _lhsRef = NULL;
modelica_metatype _crefInitialState = NULL;
modelica_metatype _tArrayBool = NULL;
modelica_metatype _elemSource = NULL;
modelica_metatype _lhsExp = NULL;
modelica_metatype _rhsExp = NULL;
modelica_metatype _rhsExp2 = NULL;
modelica_metatype _ty = NULL;
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
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _initialStateComp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,29,2) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_crefInitialState = tmpMeta2;
_preRef = omc_ComponentReference_crefPrefixString(threadData, _OMC_LIT4, _crefInitialState);
tmpMeta4 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_nTransitions));
tmpMeta3 = mmc_mk_cons(tmpMeta4, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta5 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT7, tmpMeta3);
_tArrayBool = tmpMeta5;
tmpMeta7 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta8 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta7);
tmpMeta6 = mmc_mk_cons(tmpMeta8, MMC_REFSTRUCTLIT(mmc_nil));
_cref = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT23, _tArrayBool, tmpMeta6, _preRef);
tmpMeta9 = _inSmeqs;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,3,3) == 0) MMC_THROW_INTERNAL();
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 3));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 4));
_lhsExp = tmpMeta10;
_rhsExp = tmpMeta11;
_elemSource = tmpMeta12;
tmpMeta13 = _lhsExp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,6,2) == 0) MMC_THROW_INTERNAL();
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 3));
_lhsRef = tmpMeta14;
_ty = tmpMeta15;
if(omc_ComponentReference_crefEqual(threadData, _cref, _lhsRef))
{
tmpMeta16 = mmc_mk_box3(0, _xInState, _substExp, mmc_mk_boolean(0));
_rhsExp2 = omc_Expression_traverseExpTopDown(threadData, _rhsExp, boxvar_StateMachineFlatten_traversingSubsXInState, tmpMeta16, NULL);
}
else
{
_rhsExp2 = _rhsExp;
}
tmpMeta17 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _lhsExp, _rhsExp2, _elemSource);
_outSmeqs = tmpMeta17;
_return: OMC_LABEL_UNUSED
return _outSmeqs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_smeqsSubsXInState(threadData_t *threadData, modelica_metatype _inSmeqs, modelica_metatype _initialStateComp, modelica_metatype _i, modelica_metatype _nTransitions, modelica_metatype _substExp, modelica_metatype _xInState)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outSmeqs = NULL;
tmp1 = mmc_unbox_integer(_i);
tmp2 = mmc_unbox_integer(_nTransitions);
_outSmeqs = omc_StateMachineFlatten_smeqsSubsXInState(threadData, _inSmeqs, _initialStateComp, tmp1, tmp2, _substExp, _xInState);
return _outSmeqs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_elabXInStateOps(threadData_t *threadData, modelica_metatype _inFlatSmSemantics, modelica_metatype _inEnclosingStateCrefOption)
{
modelica_metatype _outFlatSmSemantics = NULL;
modelica_integer _i;
modelica_boolean _found;
modelica_metatype _c2 = NULL;
modelica_metatype _c3 = NULL;
modelica_metatype _c4 = NULL;
modelica_metatype _conditionNew = NULL;
modelica_metatype _substTickExp = NULL;
modelica_metatype _substTimeExp = NULL;
modelica_metatype _stateRef = NULL;
modelica_metatype _t2 = NULL;
modelica_metatype _tElab = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _cElab = NULL;
modelica_metatype tmpMeta2;
modelica_metatype _smeqsElab = NULL;
modelica_metatype tmpMeta3;
modelica_string _ident = NULL;
modelica_metatype _smComps = NULL;
modelica_metatype _t = NULL;
modelica_metatype _c = NULL;
modelica_metatype _smvars = NULL;
modelica_metatype _smknowns = NULL;
modelica_metatype _smeqs = NULL;
modelica_metatype _pvars = NULL;
modelica_metatype tmpMeta4;
modelica_metatype _peqs = NULL;
modelica_metatype tmpMeta5;
modelica_metatype _enclosingStateOption = NULL;
modelica_integer _from;
modelica_integer _to;
modelica_metatype _condition = NULL;
modelica_boolean _immediate;
modelica_boolean _reset;
modelica_boolean _synchronize;
modelica_integer _priority;
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
modelica_integer tmp23;
modelica_metatype tmpMeta24;
modelica_integer tmp25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_integer tmp28;
modelica_metatype tmpMeta29;
modelica_integer tmp30;
modelica_metatype tmpMeta31;
modelica_integer tmp32;
modelica_metatype tmpMeta33;
modelica_integer tmp34;
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
modelica_integer tmp48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_tElab = tmpMeta1;
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
_cElab = tmpMeta2;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
_smeqsElab = tmpMeta3;
tmpMeta4 = MMC_REFSTRUCTLIT(mmc_nil);
_pvars = tmpMeta4;
tmpMeta5 = MMC_REFSTRUCTLIT(mmc_nil);
_peqs = tmpMeta5;
tmpMeta6 = _inFlatSmSemantics;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 6));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 7));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 8));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 9));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 10));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 11));
_ident = tmpMeta7;
_smComps = tmpMeta8;
_t = tmpMeta9;
_c = tmpMeta10;
_smvars = tmpMeta11;
_smknowns = tmpMeta12;
_smeqs = tmpMeta13;
_pvars = tmpMeta14;
_peqs = tmpMeta15;
_enclosingStateOption = tmpMeta16;
_i = ((modelica_integer) 0);
{
modelica_metatype _tc;
for (tmpMeta17 = omc_List_zip(threadData, _t, _c); !listEmpty(tmpMeta17); tmpMeta17=MMC_CDR(tmpMeta17))
{
_tc = MMC_CAR(tmpMeta17);
_i = ((modelica_integer) 1) + _i;
tmpMeta18 = _tc;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 1));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
_t2 = tmpMeta19;
_c2 = tmpMeta20;
tmpMeta21 = _t2;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 2));
tmp23 = mmc_unbox_integer(tmpMeta22);
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 3));
tmp25 = mmc_unbox_integer(tmpMeta24);
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 4));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 5));
tmp28 = mmc_unbox_integer(tmpMeta27);
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 6));
tmp30 = mmc_unbox_integer(tmpMeta29);
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 7));
tmp32 = mmc_unbox_integer(tmpMeta31);
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 8));
tmp34 = mmc_unbox_integer(tmpMeta33);
_from = tmp23;
_to = tmp25;
_condition = tmpMeta26;
_immediate = tmp28;
_reset = tmp30;
_synchronize = tmp32;
_priority = tmp34;
tmpMeta35 = arrayGet(_smComps, _from);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta35,29,2) == 0) MMC_THROW_INTERNAL();
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta35), 2));
_stateRef = tmpMeta36;
tmpMeta37 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta38 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT88, _OMC_LIT52, tmpMeta37, _stateRef), _OMC_LIT52);
_substTickExp = tmpMeta38;
tmpMeta42 = mmc_mk_box3(0, _OMC_LIT129, _substTickExp, mmc_mk_boolean(0));
tmpMeta43 = omc_Expression_traverseExpTopDown(threadData, _c2, boxvar_StateMachineFlatten_traversingSubsXInState, tmpMeta42, &tmpMeta39);
_c3 = tmpMeta43;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 3));
tmp41 = mmc_unbox_integer(tmpMeta40);
_found = tmp41;
if((_found && isSome(_inEnclosingStateCrefOption)))
{
omc_Error_addCompilerError(threadData, _OMC_LIT130);
MMC_THROW_INTERNAL();
}
_smeqsElab = (_found?omc_List_map5(threadData, _smeqs, boxvar_StateMachineFlatten_smeqsSubsXInState, arrayGet(_smComps, ((modelica_integer) 1)), mmc_mk_integer(_i), mmc_mk_integer(listLength(_t)), _substTickExp, _OMC_LIT129):_smeqs);
_smeqs = _smeqsElab;
tmpMeta44 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta45 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT103, _OMC_LIT91, tmpMeta44, _stateRef), _OMC_LIT91);
_substTimeExp = tmpMeta45;
tmpMeta49 = mmc_mk_box3(0, _OMC_LIT131, _substTimeExp, mmc_mk_boolean(0));
tmpMeta50 = omc_Expression_traverseExpTopDown(threadData, _c2, boxvar_StateMachineFlatten_traversingSubsXInState, tmpMeta49, &tmpMeta46);
_c4 = tmpMeta50;
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta46), 3));
tmp48 = mmc_unbox_integer(tmpMeta47);
_found = tmp48;
if((_found && isSome(_inEnclosingStateCrefOption)))
{
omc_Error_addCompilerError(threadData, _OMC_LIT132);
MMC_THROW_INTERNAL();
}
_smeqsElab = (_found?omc_List_map5(threadData, _smeqs, boxvar_StateMachineFlatten_smeqsSubsXInState, arrayGet(_smComps, ((modelica_integer) 1)), mmc_mk_integer(_i), mmc_mk_integer(listLength(_t)), _substTimeExp, _OMC_LIT131):_smeqs);
_smeqs = _smeqsElab;
tmpMeta52 = mmc_mk_box8(3, &StateMachineFlatten_Transition_TRANSITION__desc, mmc_mk_integer(_from), mmc_mk_integer(_to), _c4, mmc_mk_boolean(_immediate), mmc_mk_boolean(_reset), mmc_mk_boolean(_synchronize), mmc_mk_integer(_priority));
tmpMeta51 = mmc_mk_cons(tmpMeta52, _tElab);
_tElab = tmpMeta51;
tmpMeta53 = mmc_mk_cons(_c4, _cElab);
_cElab = tmpMeta53;
}
}
tmpMeta55 = mmc_mk_box11(3, &StateMachineFlatten_FlatSmSemantics_FLAT__SM__SEMANTICS__desc, _ident, _smComps, listReverse(_tElab), listReverse(_cElab), _smvars, _smknowns, _smeqsElab, _pvars, _peqs, _enclosingStateOption);
_outFlatSmSemantics = tmpMeta55;
_return: OMC_LABEL_UNUSED
return _outFlatSmSemantics;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_traversingSubsTicksInState(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inCref_HitCount, modelica_metatype *out_outCref_HitCount)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outCref_HitCount = NULL;
modelica_metatype _cref = NULL;
modelica_integer _hitCount;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_integer tmp4;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inCref_HitCount;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmp4 = mmc_unbox_integer(tmpMeta3);
_cref = tmpMeta2;
_hitCount = tmp4;
{
modelica_metatype tmp8_1;
tmp8_1 = _inExp;
{
modelica_metatype _ty = NULL;
modelica_metatype _crefTicksInState = NULL;
volatile mmc_switch_type tmp8;
int tmp9;
tmp8 = 0;
for (; tmp8 < 2; tmp8++) {
switch (MMC_SWITCH_CAST(tmp8)) {
case 0: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,13,3) == 0) goto tmp7_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,1,1) == 0) goto tmp7_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
if (12 != MMC_STRLEN(tmpMeta11) || strcmp(MMC_STRINGDATA(_OMC_LIT129), MMC_STRINGDATA(tmpMeta11)) != 0) goto tmp7_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 3));
if (!listEmpty(tmpMeta12)) goto tmp7_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 4));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
_ty = tmpMeta14;
tmpMeta15 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta16 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _OMC_LIT88, _ty, tmpMeta15);
_crefTicksInState = omc_ComponentReference_joinCrefs(threadData, _cref, tmpMeta16);
tmpMeta17 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _crefTicksInState, _ty);
tmpMeta18 = mmc_mk_box2(0, _cref, mmc_mk_integer(((modelica_integer) 1) + _hitCount));
tmpMeta[0+0] = tmpMeta17;
tmpMeta[0+1] = tmpMeta18;
goto tmp7_done;
}
case 1: {
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inCref_HitCount;
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
_outExp = tmpMeta[0+0];
_outCref_HitCount = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outCref_HitCount) { *out_outCref_HitCount = _outCref_HitCount; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_elabXInStateOps__CT(threadData_t *threadData, modelica_metatype _inSmComp)
{
modelica_metatype _outSmComp = NULL;
modelica_integer _nOfHits;
modelica_metatype _componentRef = NULL;
modelica_metatype _dAElist1 = NULL;
modelica_metatype _dAElist2 = NULL;
modelica_metatype _emptyTree = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_nOfHits = ((modelica_integer) 0);
tmpMeta1 = _inSmComp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,29,2) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_componentRef = tmpMeta2;
_dAElist1 = tmpMeta3;
_emptyTree = _OMC_LIT133;
tmpMeta8 = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _dAElist1);
tmpMeta9 = mmc_mk_box2(0, _componentRef, mmc_mk_integer(((modelica_integer) 0)));
tmpMeta10 = mmc_mk_box2(0, boxvar_StateMachineFlatten_traversingSubsTicksInState, tmpMeta9);
tmpMeta11 = omc_DAEUtil_traverseDAE(threadData, tmpMeta8, _emptyTree, boxvar_Expression_traverseSubexpressionsHelper, tmpMeta10, NULL, &tmpMeta4);
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
_dAElist2 = tmpMeta12;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta4), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
_nOfHits = tmp7;
tmpMeta13 = mmc_mk_box3(32, &DAE_Element_SM__COMP__desc, _componentRef, _dAElist2);
_outSmComp = tmpMeta13;
_return: OMC_LABEL_UNUSED
return _outSmComp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_flatSmToDataFlow(threadData_t *threadData, modelica_metatype _inFlatSm, modelica_metatype _inEnclosingStateCrefOption, modelica_metatype _inEnclosingFlatSmSemanticsOption, modelica_metatype _accElems)
{
modelica_metatype _outElems = NULL;
modelica_string _ident = NULL;
modelica_metatype _dAElist = NULL;
modelica_metatype _smCompsLst = NULL;
modelica_metatype _otherLst1 = NULL;
modelica_metatype _transitionLst = NULL;
modelica_metatype _otherLst2 = NULL;
modelica_metatype _otherLst3 = NULL;
modelica_metatype _eqnLst = NULL;
modelica_metatype _otherLst4 = NULL;
modelica_metatype _smCompsLst2 = NULL;
modelica_metatype _initialStateOp = NULL;
modelica_metatype _initialStateComp = NULL;
modelica_metatype _crefInitialState = NULL;
modelica_metatype _flatSmSemanticsBasics = NULL;
modelica_metatype _flatSmSemanticsWithPropagation = NULL;
modelica_metatype _flatSmSemantics = NULL;
modelica_metatype _transitions = NULL;
modelica_metatype _vars = NULL;
modelica_metatype _knowns = NULL;
modelica_metatype _eqs = NULL;
modelica_metatype _pvars = NULL;
modelica_metatype _peqs = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
static int tmp8 = 0;
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
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outElems = _accElems;
tmpMeta1 = _inFlatSm;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,28,2) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_ident = tmpMeta2;
_dAElist = tmpMeta3;
_smCompsLst = omc_List_extractOnTrue(threadData, _dAElist, boxvar_StateMachineFlatten_isSMComp ,&_otherLst1);
_transitionLst = omc_List_extractOnTrue(threadData, _otherLst1, boxvar_StateMachineFlatten_isTransition ,&_otherLst2);
tmpMeta5 = omc_List_extractOnTrue(threadData, _otherLst2, boxvar_StateMachineFlatten_isInitialState, &tmpMeta4);
if (listEmpty(tmpMeta5)) MMC_THROW_INTERNAL();
tmpMeta6 = MMC_CAR(tmpMeta5);
tmpMeta7 = MMC_CDR(tmpMeta5);
if (!listEmpty(tmpMeta7)) MMC_THROW_INTERNAL();
_initialStateOp = tmpMeta6;
_otherLst3 = tmpMeta4;
_eqnLst = omc_List_extractOnTrue(threadData, _otherLst3, boxvar_StateMachineFlatten_isEquation ,&_otherLst4);
{
if(!(listLength(_otherLst4) == ((modelica_integer) 0)))
{
{
FILE_INFO info = {"StateMachineFlatten.mo",197,3,197,108,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT134));
}
}
}
tmpMeta9 = _initialStateOp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,24,2) == 0) MMC_THROW_INTERNAL();
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,13,3) == 0) MMC_THROW_INTERNAL();
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,1,1) == 0) MMC_THROW_INTERNAL();
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
if (12 != MMC_STRLEN(tmpMeta12) || strcmp("initialState", MMC_STRINGDATA(tmpMeta12)) != 0) MMC_THROW_INTERNAL();
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 3));
if (listEmpty(tmpMeta13)) MMC_THROW_INTERNAL();
tmpMeta14 = MMC_CAR(tmpMeta13);
tmpMeta15 = MMC_CDR(tmpMeta13);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,6,2) == 0) MMC_THROW_INTERNAL();
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
if (!listEmpty(tmpMeta15)) MMC_THROW_INTERNAL();
_crefInitialState = tmpMeta16;
tmpMeta18 = omc_List_extract1OnTrue(threadData, _smCompsLst, boxvar_StateMachineFlatten_sMCompEqualsRef, _crefInitialState, &tmpMeta17);
if (listEmpty(tmpMeta18)) MMC_THROW_INTERNAL();
tmpMeta19 = MMC_CAR(tmpMeta18);
tmpMeta20 = MMC_CDR(tmpMeta18);
if (!listEmpty(tmpMeta20)) MMC_THROW_INTERNAL();
_initialStateComp = tmpMeta19;
_smCompsLst2 = tmpMeta17;
tmpMeta21 = mmc_mk_cons(_initialStateComp, _smCompsLst2);
_flatSmSemanticsBasics = omc_StateMachineFlatten_basicFlatSmSemantics(threadData, _ident, tmpMeta21, _transitionLst);
_flatSmSemanticsWithPropagation = omc_StateMachineFlatten_addPropagationEquations(threadData, _flatSmSemanticsBasics, _inEnclosingStateCrefOption, _inEnclosingFlatSmSemanticsOption);
_flatSmSemantics = omc_StateMachineFlatten_elabXInStateOps(threadData, _flatSmSemanticsWithPropagation, _inEnclosingStateCrefOption);
if(omc_Flags_getConfigBool(threadData, _OMC_LIT28))
{
_smCompsLst = omc_List_map(threadData, _smCompsLst, boxvar_StateMachineFlatten_elabXInStateOps__CT);
}
tmpMeta22 = _flatSmSemantics;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 6));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 7));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 8));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 9));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 10));
_vars = tmpMeta23;
_knowns = tmpMeta24;
_eqs = tmpMeta25;
_pvars = tmpMeta26;
_peqs = tmpMeta27;
tmpMeta28 = mmc_mk_cons(_outElems, mmc_mk_cons(_eqnLst, mmc_mk_cons(_vars, mmc_mk_cons(_knowns, mmc_mk_cons(_eqs, mmc_mk_cons(_pvars, mmc_mk_cons(_peqs, MMC_REFSTRUCTLIT(mmc_nil))))))));
_outElems = omc_List_flatten(threadData, tmpMeta28);
_outElems = omc_List_fold1(threadData, _smCompsLst, boxvar_StateMachineFlatten_smCompToDataFlow, _flatSmSemantics, _outElems);
_return: OMC_LABEL_UNUSED
return _outElems;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_traversingSubsActiveState(threadData_t *threadData, modelica_metatype _inExp, modelica_integer _inHitCount, modelica_integer *out_outHitCount)
{
modelica_metatype _outExp = NULL;
modelica_integer _outHitCount;
modelica_integer tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _componentRef = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (11 != MMC_STRLEN(tmpMeta7) || strcmp(MMC_STRINGDATA(_OMC_LIT68), MMC_STRINGDATA(tmpMeta7)) != 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,6,2) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (!listEmpty(tmpMeta10)) goto tmp3_end;
_componentRef = tmpMeta11;
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta13 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_ComponentReference_crefPrependIdent(threadData, _componentRef, _OMC_LIT63, tmpMeta12, _OMC_LIT7), _OMC_LIT7);
tmpMeta[0+0] = tmpMeta13;
tmp1_c1 = ((modelica_integer) 1) + _inHitCount;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _inExp;
tmp1_c1 = _inHitCount;
goto tmp3_done;
}
}
goto tmp3_end;
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
_outHitCount = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_outHitCount) { *out_outHitCount = _outHitCount; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_StateMachineFlatten_traversingSubsActiveState(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inHitCount, modelica_metatype *out_outHitCount)
{
modelica_integer tmp1;
modelica_integer _outHitCount;
modelica_metatype _outExp = NULL;
tmp1 = mmc_unbox_integer(_inHitCount);
_outExp = omc_StateMachineFlatten_traversingSubsActiveState(threadData, _inExp, tmp1, &_outHitCount);
if (out_outHitCount) { *out_outHitCount = mmc_mk_icon(_outHitCount); }
return _outExp;
}
DLLExport
modelica_metatype omc_StateMachineFlatten_stateMachineToDataFlow(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _inDAElist)
{
modelica_metatype _outDAElist = NULL;
modelica_metatype _elementLst = NULL;
modelica_metatype _elementLst1 = NULL;
modelica_metatype _flatSmLst = NULL;
modelica_metatype _otherLst = NULL;
modelica_metatype _elementLst2 = NULL;
modelica_metatype _elementLst3 = NULL;
modelica_metatype _t = NULL;
modelica_metatype _compElem = NULL;
modelica_integer _nOfSubstitutions;
modelica_string _ident = NULL;
modelica_metatype _dAElist = NULL;
modelica_metatype _source = NULL;
modelica_metatype _comment = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
static int tmp3 = 0;
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
modelica_integer tmp15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_integer tmp20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inDAElist;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_elementLst = tmpMeta2;
{
if(!(listLength(_elementLst) == ((modelica_integer) 1)))
{
{
FILE_INFO info = {"StateMachineFlatten.mo",115,3,115,110,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT135));
}
}
}
tmpMeta4 = listHead(_elementLst);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta4,17,4) == 0) MMC_THROW_INTERNAL();
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta4), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta4), 3));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta4), 4));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta4), 5));
_ident = tmpMeta5;
_dAElist = tmpMeta6;
_source = tmpMeta7;
_comment = tmpMeta8;
if((!omc_List_exist(threadData, _dAElist, boxvar_StateMachineFlatten_isFlatSm)))
{
_outDAElist = _inDAElist;
goto _return;
}
_flatSmLst = omc_List_extractOnTrue(threadData, _dAElist, boxvar_StateMachineFlatten_isFlatSm ,&_otherLst);
tmpMeta9 = MMC_REFSTRUCTLIT(mmc_nil);
_elementLst2 = omc_List_fold2(threadData, _flatSmLst, boxvar_StateMachineFlatten_flatSmToDataFlow, mmc_mk_none(), mmc_mk_none(), tmpMeta9);
if(omc_Flags_getConfigBool(threadData, _OMC_LIT28))
{
_elementLst2 = omc_StateMachineFlatten_wrapHack(threadData, _cache, _elementLst2);
}
_elementLst3 = listAppend(_otherLst, _elementLst2);
tmpMeta11 = mmc_mk_box5(20, &DAE_Element_COMP__desc, _ident, _elementLst3, _source, _comment);
tmpMeta10 = mmc_mk_cons(tmpMeta11, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta12 = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta10);
_outDAElist = tmpMeta12;
tmpMeta16 = mmc_mk_box2(0, boxvar_StateMachineFlatten_traversingSubsActiveState, mmc_mk_integer(((modelica_integer) 0)));
tmpMeta17 = omc_DAEUtil_traverseDAE(threadData, _outDAElist, omc_FCore_getFunctionTree(threadData, _cache), boxvar_Expression_traverseSubexpressionsHelper, tmpMeta16, NULL, &tmpMeta13);
_outDAElist = tmpMeta17;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmp15 = mmc_unbox_integer(tmpMeta14);
_nOfSubstitutions = tmp15;
if(omc_Flags_getConfigBool(threadData, _OMC_LIT28))
{
tmpMeta21 = mmc_mk_box2(0, boxvar_StateMachineFlatten_traversingSubsPreForPrevious, mmc_mk_integer(((modelica_integer) 0)));
tmpMeta22 = omc_DAEUtil_traverseDAE(threadData, _outDAElist, omc_FCore_getFunctionTree(threadData, _cache), boxvar_Expression_traverseSubexpressionsHelper, tmpMeta21, NULL, &tmpMeta18);
_outDAElist = tmpMeta22;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
tmp20 = mmc_unbox_integer(tmpMeta19);
_nOfSubstitutions = tmp20;
}
_return: OMC_LABEL_UNUSED
return _outDAElist;
}
