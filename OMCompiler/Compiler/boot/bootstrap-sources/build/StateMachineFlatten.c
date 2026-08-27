#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/StateMachineFlatten.c"
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
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(89)),_OMC_LIT13,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT14,_OMC_LIT16,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT18}};
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
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT28,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(94)),_OMC_LIT24,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT14,_OMC_LIT25,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT27}};
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
modelica_metatype tmpMeta[10] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (6 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT0), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta[4])) goto tmp3_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (listEmpty(tmpMeta[6])) goto tmp3_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],4,1) == 0) goto tmp3_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[9],0,0) == 0) goto tmp3_end;
if (!listEmpty(tmpMeta[8])) goto tmp3_end;
_expX = tmpMeta[5];
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
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (8 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT3), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_expLst = tmpMeta[4];
_attr = tmpMeta[5];
tmpMeta[2] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT2, _expLst, _attr);
tmpMeta[0+0] = tmpMeta[2];
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inElem;
{
modelica_metatype _exp = NULL;
modelica_metatype _cref = NULL;
modelica_string _firstIdent = NULL;
modelica_string _lastIdent = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
modelica_boolean tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_exp = tmpMeta[1];
tmpMeta[1] = _exp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,2) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_cref = tmpMeta[2];
_firstIdent = omc_ComponentReference_crefFirstIdent(threadData, _cref);
tmp5 = (stringEqual(_firstIdent, _OMC_LIT4));
if (1 != tmp5) goto goto_1;
_lastIdent = omc_ComponentReference_crefLastIdent(threadData, _cref);
tmp6 = (stringEqual(_lastIdent, _inLastIdent));
if (1 != tmp6) goto goto_1;
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
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cond1 = _OMC_LIT11;
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(omc_Flags_getConfigReal(threadData, _OMC_LIT19)));
tmpMeta[2] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(omc_Flags_getConfigReal(threadData, _OMC_LIT19)));
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta[3] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT12, tmpMeta[0], _OMC_LIT10);
_cond2 = tmpMeta[3];
_tArrayBool = _OMC_LIT22;
if(omc_Flags_getConfigBool(threadData, _OMC_LIT28))
{
_condLst = omc_List_filterMap1(threadData, _inElementLst, boxvar_StateMachineFlatten_extractSmOfExps, _OMC_LIT23);
_eqnLst = omc_List_extractOnTrue(threadData, _inElementLst, boxvar_StateMachineFlatten_isPreOrPreviousEquation ,&_otherLst);
tmpMeta[0] = mmc_mk_cons(_cond1, _condLst);
tmpMeta[1] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _tArrayBool, mmc_mk_boolean(1), tmpMeta[0]);
_condition = tmpMeta[1];
}
else
{
_eqnLst = omc_List_extractOnTrue(threadData, _inElementLst, boxvar_StateMachineFlatten_isEquation ,&_otherLst);
tmpMeta[0] = mmc_mk_cons(_cond1, mmc_mk_cons(_cond2, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta[1] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _tArrayBool, mmc_mk_boolean(1), tmpMeta[0]);
_condition = tmpMeta[1];
}
tmpMeta[0] = mmc_mk_box5(13, &DAE_Element_WHEN__EQUATION__desc, _condition, _eqnLst, mmc_mk_none(), _OMC_LIT33);
_whenEq = tmpMeta[0];
tmpMeta[0] = mmc_mk_cons(_whenEq, MMC_REFSTRUCTLIT(mmc_nil));
_outElementLst = listAppend(_otherLst, tmpMeta[0]);
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
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
modelica_metatype tmpMeta[14] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _transition;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp1 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmp2 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
tmp3 = mmc_unbox_integer(tmpMeta[4]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
tmp4 = mmc_unbox_integer(tmpMeta[5]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
tmp5 = mmc_unbox_integer(tmpMeta[6]);
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 8));
tmp6 = mmc_unbox_integer(tmpMeta[7]);
_from = tmp1;
_to = tmp2;
_condition = tmpMeta[3];
_immediate = tmp3;
_reset = tmp4;
_synchronize = tmp5;
_priority = tmp6;
tmpMeta[0] = stringAppend(_OMC_LIT34,intString(_from));
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT35);
tmpMeta[2] = stringAppend(tmpMeta[1],intString(_to));
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT36);
tmpMeta[4] = stringAppend(tmpMeta[3],omc_ExpressionDump_printExpStr(threadData, _condition));
tmpMeta[5] = stringAppend(tmpMeta[4],_OMC_LIT37);
tmpMeta[6] = stringAppend(tmpMeta[5],(_immediate?_OMC_LIT38:_OMC_LIT39));
tmpMeta[7] = stringAppend(tmpMeta[6],_OMC_LIT40);
tmpMeta[8] = stringAppend(tmpMeta[7],(_reset?_OMC_LIT38:_OMC_LIT39));
tmpMeta[9] = stringAppend(tmpMeta[8],_OMC_LIT41);
tmpMeta[10] = stringAppend(tmpMeta[9],(_synchronize?_OMC_LIT38:_OMC_LIT39));
tmpMeta[11] = stringAppend(tmpMeta[10],_OMC_LIT42);
tmpMeta[12] = stringAppend(tmpMeta[11],intString(_priority));
tmpMeta[13] = stringAppend(tmpMeta[12],_OMC_LIT43);
_transitionStr = tmpMeta[13];
_return: OMC_LABEL_UNUSED
return _transitionStr;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_sMCompEqualsRef(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inCref)
{
modelica_boolean _result;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,29,2) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cref = tmpMeta[0];
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
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,3) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_exp = tmpMeta[0];
_scalar = tmpMeta[1];
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,2) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],13,3) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (12 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT44), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp3_end;
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,2) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],13,3) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (10 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT45), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp3_end;
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
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_metatype tmpMeta[25] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_immediate = 1;
_reset = 1;
_synchronize = 0;
_priority = ((modelica_integer) 1);
tmpMeta[0] = _transitionElem;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],24,2) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],13,3) == 0) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) MMC_THROW_INTERNAL();
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (10 != MMC_STRLEN(tmpMeta[3]) || strcmp("transition", MMC_STRINGDATA(tmpMeta[3])) != 0) MMC_THROW_INTERNAL();
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (listEmpty(tmpMeta[4])) MMC_THROW_INTERNAL();
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],6,2) == 0) MMC_THROW_INTERNAL();
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
if (listEmpty(tmpMeta[6])) MMC_THROW_INTERNAL();
tmpMeta[8] = MMC_CAR(tmpMeta[6]);
tmpMeta[9] = MMC_CDR(tmpMeta[6]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],6,2) == 0) MMC_THROW_INTERNAL();
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 2));
if (listEmpty(tmpMeta[9])) MMC_THROW_INTERNAL();
tmpMeta[11] = MMC_CAR(tmpMeta[9]);
tmpMeta[12] = MMC_CDR(tmpMeta[9]);
if (listEmpty(tmpMeta[12])) MMC_THROW_INTERNAL();
tmpMeta[13] = MMC_CAR(tmpMeta[12]);
tmpMeta[14] = MMC_CDR(tmpMeta[12]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[13],3,1) == 0) MMC_THROW_INTERNAL();
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[13]), 2));
tmp1 = mmc_unbox_integer(tmpMeta[15]);
if (listEmpty(tmpMeta[14])) MMC_THROW_INTERNAL();
tmpMeta[16] = MMC_CAR(tmpMeta[14]);
tmpMeta[17] = MMC_CDR(tmpMeta[14]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[16],3,1) == 0) MMC_THROW_INTERNAL();
tmpMeta[18] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[16]), 2));
tmp2 = mmc_unbox_integer(tmpMeta[18]);
if (listEmpty(tmpMeta[17])) MMC_THROW_INTERNAL();
tmpMeta[19] = MMC_CAR(tmpMeta[17]);
tmpMeta[20] = MMC_CDR(tmpMeta[17]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[19],3,1) == 0) MMC_THROW_INTERNAL();
tmpMeta[21] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[19]), 2));
tmp3 = mmc_unbox_integer(tmpMeta[21]);
if (listEmpty(tmpMeta[20])) MMC_THROW_INTERNAL();
tmpMeta[22] = MMC_CAR(tmpMeta[20]);
tmpMeta[23] = MMC_CDR(tmpMeta[20]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[22],0,1) == 0) MMC_THROW_INTERNAL();
tmpMeta[24] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[22]), 2));
tmp4 = mmc_unbox_integer(tmpMeta[24]);
if (!listEmpty(tmpMeta[23])) MMC_THROW_INTERNAL();
_crefFrom = tmpMeta[7];
_crefTo = tmpMeta[10];
_condition = tmpMeta[11];
_immediate = tmp1;
_reset = tmp2;
_synchronize = tmp3;
_priority = tmp4;
_from = omc_List_position1OnTrue(threadData, _states, boxvar_StateMachineFlatten_sMCompEqualsRef, _crefFrom);
_to = omc_List_position1OnTrue(threadData, _states, boxvar_StateMachineFlatten_sMCompEqualsRef, _crefTo);
tmpMeta[0] = mmc_mk_box8(3, &StateMachineFlatten_Transition_TRANSITION__desc, mmc_mk_integer(_from), mmc_mk_integer(_to), _condition, mmc_mk_boolean(_immediate), mmc_mk_boolean(_reset), mmc_mk_boolean(_synchronize), mmc_mk_integer(_priority));
_trans = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _trans;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_priorityLt(threadData_t *threadData, modelica_metatype _inTrans1, modelica_metatype _inTrans2)
{
modelica_boolean _res;
modelica_integer _priority1;
modelica_integer _priority2;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inTrans1;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 8));
tmp1 = mmc_unbox_integer(tmpMeta[1]);
_priority1 = tmp1;
tmpMeta[0] = _inTrans2;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 8));
tmp2 = mmc_unbox_integer(tmpMeta[1]);
_priority2 = tmp2;
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
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _trans;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
_condition = tmpMeta[1];
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
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box14(3, &DAE_Element_VAR__desc, _componentRef, _kind, _OMC_LIT46, _OMC_LIT47, _OMC_LIT48, _ty, mmc_mk_none(), _dims, _OMC_LIT49, _OMC_LIT33, mmc_mk_none(), mmc_mk_none(), _OMC_LIT50);
_var = tmpMeta[0];
_outVar = omc_StateMachineFlatten_setVarFixedStartValue(threadData, _var, _startExp);
_return: OMC_LABEL_UNUSED
return _outVar;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_createVarWithDefaults(threadData_t *threadData, modelica_metatype _componentRef, modelica_metatype _kind, modelica_metatype _ty, modelica_metatype _dims)
{
modelica_metatype _var = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box14(3, &DAE_Element_VAR__desc, _componentRef, _kind, _OMC_LIT46, _OMC_LIT47, _OMC_LIT48, _ty, mmc_mk_none(), _dims, _OMC_LIT49, _OMC_LIT33, mmc_mk_none(), mmc_mk_none(), _OMC_LIT50);
_var = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _var;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_qCref(threadData_t *threadData, modelica_string _ident, modelica_metatype _identType, modelica_metatype _subscriptLst, modelica_metatype _componentRef)
{
modelica_metatype _outQual = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _ident, _identType, _subscriptLst);
_outQual = omc_ComponentReference_joinCrefs(threadData, _componentRef, tmpMeta[0]);
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
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer tmp7;
modelica_integer tmp8;
modelica_integer tmp9;
modelica_integer tmp10;
modelica_integer tmp11;
modelica_integer tmp12;
modelica_integer tmp13;
modelica_integer tmp14;
modelica_integer tmp15;
modelica_boolean tmp16;
modelica_integer tmp17;
modelica_integer tmp18;
modelica_integer tmp19;
modelica_boolean tmp20;
modelica_integer tmp21;
modelica_integer tmp22;
modelica_integer tmp23;
modelica_integer tmp24;
modelica_integer tmp25;
modelica_integer tmp26;
modelica_integer tmp27;
modelica_integer tmp28;
modelica_integer tmp29;
modelica_boolean tmp30;
modelica_integer tmp31;
modelica_integer tmp32;
modelica_integer tmp33;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = listHead(_q);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],29,2) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_crefInitialState = tmpMeta[1];
_preRef = omc_ComponentReference_crefPrefixString(threadData, _OMC_LIT4, _crefInitialState);
_t = omc_StateMachineFlatten_createTandC(threadData, _q, _inTransitions ,&_cExps);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_defaultIntVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, omc_ComponentReference_makeDummyCref(threadData), _OMC_LIT51, _OMC_LIT52, tmpMeta[0]);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_defaultBoolVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, omc_ComponentReference_makeDummyCref(threadData), _OMC_LIT51, _OMC_LIT7, tmpMeta[0]);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_knowns = tmpMeta[0];
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_vars = tmpMeta[0];
_nStates = listLength(_q);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_nStatesRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT53, _OMC_LIT52, tmpMeta[0], _preRef);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_nStatesVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _nStatesRef, _OMC_LIT54, _OMC_LIT52, tmpMeta[0]);
tmpMeta[0] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_nStates));
_nStatesVar = omc_DAEUtil_setElementVarBinding(threadData, _nStatesVar, mmc_mk_some(tmpMeta[0]));
tmpMeta[0] = mmc_mk_cons(_nStatesVar, _knowns);
_knowns = tmpMeta[0];
_nTransitions = listLength(_t);
tmpMeta[1] = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_nTransitions));
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], MMC_REFSTRUCTLIT(mmc_nil));
_tDims = tmpMeta[0];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT52, _tDims);
_tArrayInteger = tmpMeta[0];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT7, _tDims);
_tArrayBool = tmpMeta[0];
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
for (tmpMeta[0] = _t; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_t1 = MMC_CAR(tmpMeta[0]);
_i = ((modelica_integer) 1) + _i;
tmpMeta[1] = _t1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp1 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmp2 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmp3 = mmc_unbox_integer(tmpMeta[4]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmp4 = mmc_unbox_integer(tmpMeta[5]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmp5 = mmc_unbox_integer(tmpMeta[6]);
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
tmp6 = mmc_unbox_integer(tmpMeta[7]);
_from = tmp1;
_to = tmp2;
_immediate = tmp3;
_reset = tmp4;
_synchronize = tmp5;
_priority = tmp6;
tmpMeta[2] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[3] = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta[2]);
tmpMeta[1] = mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil));
_tFromRefs = arrayUpdate(_tFromRefs, _i, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT55, _tArrayInteger, tmpMeta[1], _preRef));
_tFromVars = arrayUpdate(_tFromVars, _i, omc_StateMachineFlatten_createVarWithDefaults(threadData, arrayGet(_tFromRefs, _i), _OMC_LIT54, _OMC_LIT52, _tDims));
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_from));
_tFromVars = arrayUpdate(_tFromVars, _i, omc_DAEUtil_setElementVarBinding(threadData, arrayGet(_tFromVars, _i), mmc_mk_some(tmpMeta[1])));
tmpMeta[1] = mmc_mk_cons(arrayGet(_tFromVars, _i), _knowns);
_knowns = tmpMeta[1];
tmpMeta[2] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[3] = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta[2]);
tmpMeta[1] = mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil));
_tToRefs = arrayUpdate(_tToRefs, _i, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT56, _tArrayInteger, tmpMeta[1], _preRef));
_tToVars = arrayUpdate(_tToVars, _i, omc_StateMachineFlatten_createVarWithDefaults(threadData, arrayGet(_tToRefs, _i), _OMC_LIT54, _OMC_LIT52, _tDims));
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_to));
_tToVars = arrayUpdate(_tToVars, _i, omc_DAEUtil_setElementVarBinding(threadData, arrayGet(_tToVars, _i), mmc_mk_some(tmpMeta[1])));
tmpMeta[1] = mmc_mk_cons(arrayGet(_tToVars, _i), _knowns);
_knowns = tmpMeta[1];
tmpMeta[2] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[3] = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta[2]);
tmpMeta[1] = mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil));
_tImmediateRefs = arrayUpdate(_tImmediateRefs, _i, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT57, _tArrayBool, tmpMeta[1], _preRef));
_tImmediateVars = arrayUpdate(_tImmediateVars, _i, omc_StateMachineFlatten_createVarWithDefaults(threadData, arrayGet(_tImmediateRefs, _i), _OMC_LIT54, _OMC_LIT7, _tDims));
tmpMeta[1] = mmc_mk_box2(6, &DAE_Exp_BCONST__desc, mmc_mk_boolean(_immediate));
_tImmediateVars = arrayUpdate(_tImmediateVars, _i, omc_DAEUtil_setElementVarBinding(threadData, arrayGet(_tImmediateVars, _i), mmc_mk_some(tmpMeta[1])));
tmpMeta[1] = mmc_mk_cons(arrayGet(_tImmediateVars, _i), _knowns);
_knowns = tmpMeta[1];
tmpMeta[2] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[3] = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta[2]);
tmpMeta[1] = mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil));
_tResetRefs = arrayUpdate(_tResetRefs, _i, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT58, _tArrayBool, tmpMeta[1], _preRef));
_tResetVars = arrayUpdate(_tResetVars, _i, omc_StateMachineFlatten_createVarWithDefaults(threadData, arrayGet(_tResetRefs, _i), _OMC_LIT54, _OMC_LIT7, _tDims));
tmpMeta[1] = mmc_mk_box2(6, &DAE_Exp_BCONST__desc, mmc_mk_boolean(_reset));
_tResetVars = arrayUpdate(_tResetVars, _i, omc_DAEUtil_setElementVarBinding(threadData, arrayGet(_tResetVars, _i), mmc_mk_some(tmpMeta[1])));
tmpMeta[1] = mmc_mk_cons(arrayGet(_tResetVars, _i), _knowns);
_knowns = tmpMeta[1];
tmpMeta[2] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[3] = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta[2]);
tmpMeta[1] = mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil));
_tSynchronizeRefs = arrayUpdate(_tSynchronizeRefs, _i, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT59, _tArrayBool, tmpMeta[1], _preRef));
_tSynchronizeVars = arrayUpdate(_tSynchronizeVars, _i, omc_StateMachineFlatten_createVarWithDefaults(threadData, arrayGet(_tSynchronizeRefs, _i), _OMC_LIT54, _OMC_LIT7, _tDims));
tmpMeta[1] = mmc_mk_box2(6, &DAE_Exp_BCONST__desc, mmc_mk_boolean(_synchronize));
_tSynchronizeVars = arrayUpdate(_tSynchronizeVars, _i, omc_DAEUtil_setElementVarBinding(threadData, arrayGet(_tSynchronizeVars, _i), mmc_mk_some(tmpMeta[1])));
tmpMeta[1] = mmc_mk_cons(arrayGet(_tSynchronizeVars, _i), _knowns);
_knowns = tmpMeta[1];
tmpMeta[2] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[3] = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta[2]);
tmpMeta[1] = mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil));
_tPriorityRefs = arrayUpdate(_tPriorityRefs, _i, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT60, _tArrayInteger, tmpMeta[1], _preRef));
_tPriorityVars = arrayUpdate(_tPriorityVars, _i, omc_StateMachineFlatten_createVarWithDefaults(threadData, arrayGet(_tPriorityRefs, _i), _OMC_LIT54, _OMC_LIT52, _tDims));
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_priority));
_tPriorityVars = arrayUpdate(_tPriorityVars, _i, omc_DAEUtil_setElementVarBinding(threadData, arrayGet(_tPriorityVars, _i), mmc_mk_some(tmpMeta[1])));
tmpMeta[1] = mmc_mk_cons(arrayGet(_tPriorityVars, _i), _knowns);
_knowns = tmpMeta[1];
}
}
_cRefs = arrayCreate(_nTransitions, omc_ComponentReference_makeDummyCref(threadData));
_cImmediateRefs = arrayCreate(_nTransitions, omc_ComponentReference_makeDummyCref(threadData));
_cVars = arrayCreate(_nTransitions, _defaultBoolVar);
_cImmediateVars = arrayCreate(_nTransitions, _defaultBoolVar);
_i = ((modelica_integer) 0);
{
modelica_metatype _exp;
for (tmpMeta[0] = _cExps; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_exp = MMC_CAR(tmpMeta[0]);
_i = ((modelica_integer) 1) + _i;
tmpMeta[2] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[3] = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta[2]);
tmpMeta[1] = mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil));
_cRefs = arrayUpdate(_cRefs, _i, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT61, _tArrayBool, tmpMeta[1], _preRef));
tmpMeta[2] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[3] = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta[2]);
tmpMeta[1] = mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil));
_cImmediateRefs = arrayUpdate(_cImmediateRefs, _i, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT23, _tArrayBool, tmpMeta[1], _preRef));
_cVars = arrayUpdate(_cVars, _i, omc_StateMachineFlatten_createVarWithDefaults(threadData, arrayGet(_cRefs, _i), _OMC_LIT51, _OMC_LIT7, _tDims));
_cImmediateVars = arrayUpdate(_cImmediateVars, _i, omc_StateMachineFlatten_createVarWithStartValue(threadData, arrayGet(_cImmediateRefs, _i), _OMC_LIT51, _OMC_LIT7, _OMC_LIT62, _tDims));
tmpMeta[1] = mmc_mk_cons(arrayGet(_cVars, _i), _vars);
_vars = tmpMeta[1];
tmpMeta[1] = mmc_mk_cons(arrayGet(_cImmediateVars, _i), _vars);
_vars = tmpMeta[1];
}
}
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_activeRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT63, _OMC_LIT7, tmpMeta[0], _preRef);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_activeVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _activeRef, _OMC_LIT51, _OMC_LIT7, tmpMeta[0]);
tmpMeta[0] = mmc_mk_cons(_activeVar, _vars);
_vars = tmpMeta[0];
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_resetRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT64, _OMC_LIT7, tmpMeta[0], _preRef);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_resetVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _resetRef, _OMC_LIT51, _OMC_LIT7, tmpMeta[0]);
tmpMeta[0] = mmc_mk_cons(_resetVar, _vars);
_vars = tmpMeta[0];
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_selectedStateRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT65, _OMC_LIT52, tmpMeta[0], _preRef);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_selectedStateVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _selectedStateRef, _OMC_LIT51, _OMC_LIT52, tmpMeta[0]);
tmpMeta[0] = mmc_mk_cons(_selectedStateVar, _vars);
_vars = tmpMeta[0];
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_selectedResetRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT66, _OMC_LIT7, tmpMeta[0], _preRef);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_selectedResetVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _selectedResetRef, _OMC_LIT51, _OMC_LIT7, tmpMeta[0]);
tmpMeta[0] = mmc_mk_cons(_selectedResetVar, _vars);
_vars = tmpMeta[0];
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_firedRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT67, _OMC_LIT52, tmpMeta[0], _preRef);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_firedVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _firedRef, _OMC_LIT51, _OMC_LIT52, tmpMeta[0]);
tmpMeta[0] = mmc_mk_cons(_firedVar, _vars);
_vars = tmpMeta[0];
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_activeStateRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT68, _OMC_LIT52, tmpMeta[0], _preRef);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_activeStateVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _activeStateRef, _OMC_LIT51, _OMC_LIT52, tmpMeta[0]);
tmpMeta[0] = mmc_mk_cons(_activeStateVar, _vars);
_vars = tmpMeta[0];
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_activeResetRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT69, _OMC_LIT7, tmpMeta[0], _preRef);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_activeResetVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _activeResetRef, _OMC_LIT51, _OMC_LIT7, tmpMeta[0]);
tmpMeta[0] = mmc_mk_cons(_activeResetVar, _vars);
_vars = tmpMeta[0];
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_nextStateRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT70, _OMC_LIT52, tmpMeta[0], _preRef);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_nextStateVar = omc_StateMachineFlatten_createVarWithStartValue(threadData, _nextStateRef, _OMC_LIT51, _OMC_LIT52, _OMC_LIT71, tmpMeta[0]);
tmpMeta[0] = mmc_mk_cons(_nextStateVar, _vars);
_vars = tmpMeta[0];
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_nextResetRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT72, _OMC_LIT7, tmpMeta[0], _preRef);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_nextResetVar = omc_StateMachineFlatten_createVarWithStartValue(threadData, _nextResetRef, _OMC_LIT51, _OMC_LIT7, _OMC_LIT62, tmpMeta[0]);
tmpMeta[0] = mmc_mk_cons(_nextResetVar, _vars);
_vars = tmpMeta[0];
tmpMeta[1] = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_nStates));
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], MMC_REFSTRUCTLIT(mmc_nil));
_nStatesDims = tmpMeta[0];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT7, _nStatesDims);
_nStatesArrayBool = tmpMeta[0];
_activeResetStatesRefs = arrayCreate(_nStates, omc_ComponentReference_makeDummyCref(threadData));
_activeResetStatesVars = arrayCreate(_nStates, _defaultBoolVar);
tmp7 = ((modelica_integer) 1); tmp8 = 1; tmp9 = _nStates;
if(!(((tmp8 > 0) && (tmp7 > tmp9)) || ((tmp8 < 0) && (tmp7 < tmp9))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp7, tmp9); _i += tmp8)
{
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[2] = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta[1]);
tmpMeta[0] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
_activeResetStatesRefs = arrayUpdate(_activeResetStatesRefs, _i, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT73, _nStatesArrayBool, tmpMeta[0], _preRef));
_activeResetStatesVars = arrayUpdate(_activeResetStatesVars, _i, omc_StateMachineFlatten_createVarWithDefaults(threadData, arrayGet(_activeResetStatesRefs, _i), _OMC_LIT51, _OMC_LIT7, _nStatesDims));
tmpMeta[0] = mmc_mk_cons(arrayGet(_activeResetStatesVars, _i), _vars);
_vars = tmpMeta[0];
}
}
_nextResetStatesRefs = arrayCreate(_nStates, omc_ComponentReference_makeDummyCref(threadData));
_nextResetStatesVars = arrayCreate(_nStates, _defaultBoolVar);
tmp10 = ((modelica_integer) 1); tmp11 = 1; tmp12 = _nStates;
if(!(((tmp11 > 0) && (tmp10 > tmp12)) || ((tmp11 < 0) && (tmp10 < tmp12))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp10, tmp12); _i += tmp11)
{
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[2] = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta[1]);
tmpMeta[0] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
_nextResetStatesRefs = arrayUpdate(_nextResetStatesRefs, _i, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT74, _nStatesArrayBool, tmpMeta[0], _preRef));
_nextResetStatesVars = arrayUpdate(_nextResetStatesVars, _i, omc_StateMachineFlatten_createVarWithStartValue(threadData, arrayGet(_nextResetStatesRefs, _i), _OMC_LIT51, _OMC_LIT7, _OMC_LIT62, _nStatesDims));
tmpMeta[0] = mmc_mk_cons(arrayGet(_nextResetStatesVars, _i), _vars);
_vars = tmpMeta[0];
}
}
_finalStatesRefs = arrayCreate(_nStates, omc_ComponentReference_makeDummyCref(threadData));
_finalStatesVars = arrayCreate(_nStates, _defaultBoolVar);
tmp13 = ((modelica_integer) 1); tmp14 = 1; tmp15 = _nStates;
if(!(((tmp14 > 0) && (tmp13 > tmp15)) || ((tmp14 < 0) && (tmp13 < tmp15))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp13, tmp15); _i += tmp14)
{
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[2] = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta[1]);
tmpMeta[0] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
_finalStatesRefs = arrayUpdate(_finalStatesRefs, _i, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT75, _nStatesArrayBool, tmpMeta[0], _preRef));
_finalStatesVars = arrayUpdate(_finalStatesVars, _i, omc_StateMachineFlatten_createVarWithDefaults(threadData, arrayGet(_finalStatesRefs, _i), _OMC_LIT51, _OMC_LIT7, _nStatesDims));
tmpMeta[0] = mmc_mk_cons(arrayGet(_finalStatesVars, _i), _vars);
_vars = tmpMeta[0];
}
}
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_stateMachineInFinalStateRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT76, _OMC_LIT7, tmpMeta[0], _preRef);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_stateMachineInFinalStateVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _stateMachineInFinalStateRef, _OMC_LIT51, _OMC_LIT7, tmpMeta[0]);
tmpMeta[0] = mmc_mk_cons(_stateMachineInFinalStateVar, _vars);
_vars = tmpMeta[0];
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_eqs = tmpMeta[0];
_i = ((modelica_integer) 0);
{
modelica_metatype _cExp;
for (tmpMeta[0] = _cExps; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_cExp = MMC_CAR(tmpMeta[0]);
_i = ((modelica_integer) 1) + _i;
tmpMeta[1] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, arrayGet(_cImmediateRefs, _i), _OMC_LIT7);
_exp = tmpMeta[1];
tmpMeta[2] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _cExp, _OMC_LIT33);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _eqs);
_eqs = tmpMeta[1];
tmpMeta[1] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, arrayGet(_cRefs, _i), _OMC_LIT7);
_exp1 = tmpMeta[1];
tmpMeta[1] = arrayGet(_tImmediateVars, _i);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,13) == 0) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
_bindExp = tmpMeta[2];
tmpMeta[1] = mmc_mk_box1(0, _OMC_LIT77);
tmp16 = (modelica_boolean)mmc_unbox_boolean(omc_Util_applyOptionOrDefault(threadData, _bindExp, (modelica_fnptr) mmc_mk_box2(0,closure0_Expression_expEqual,tmpMeta[1]), mmc_mk_boolean(0)));
if(tmp16)
{
tmpMeta[4] = _exp;
}
else
{
tmpMeta[2] = mmc_mk_cons(_exp, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[3] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta[2], _OMC_LIT10);
tmpMeta[4] = tmpMeta[3];
}
_rhs = tmpMeta[4];
tmpMeta[2] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp1, _rhs, _OMC_LIT33);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _eqs);
_eqs = tmpMeta[1];
}
}
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _selectedStateRef, _OMC_LIT52);
_exp = tmpMeta[0];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _resetRef, _OMC_LIT7);
_expCond = tmpMeta[0];
_expThen = _OMC_LIT79;
tmpMeta[1] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _nextStateRef, _OMC_LIT52);
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta[0], _OMC_LIT80);
_expElse = tmpMeta[2];
tmpMeta[0] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
_rhs = tmpMeta[0];
tmpMeta[0] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _rhs, _OMC_LIT33);
_selectedStateEqn = tmpMeta[0];
tmpMeta[0] = mmc_mk_cons(_selectedStateEqn, _eqs);
_eqs = tmpMeta[0];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _selectedResetRef, _OMC_LIT7);
_exp = tmpMeta[0];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _resetRef, _OMC_LIT7);
_expCond = tmpMeta[0];
_expThen = _OMC_LIT77;
tmpMeta[1] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _nextResetRef, _OMC_LIT7);
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta[0], _OMC_LIT10);
_expElse = tmpMeta[2];
tmpMeta[0] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
_rhs = tmpMeta[0];
tmpMeta[0] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _rhs, _OMC_LIT33);
_selectedResetEqn = tmpMeta[0];
tmpMeta[0] = mmc_mk_cons(_selectedResetEqn, _eqs);
_eqs = tmpMeta[0];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _firedRef, _OMC_LIT52);
_exp = tmpMeta[0];
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_expLst = tmpMeta[0];
tmp17 = ((modelica_integer) 1); tmp18 = 1; tmp19 = _nTransitions;
if(!(((tmp18 > 0) && (tmp17 > tmp19)) || ((tmp18 < 0) && (tmp17 < tmp19))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp17, tmp19); _i += tmp18)
{
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, arrayGet(_tFromRefs, _i), _OMC_LIT52);
tmpMeta[1] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _selectedStateRef, _OMC_LIT52);
tmpMeta[2] = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, tmpMeta[0], _OMC_LIT81, tmpMeta[1], mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
_expCond = tmpMeta[2];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, arrayGet(_cRefs, _i), _OMC_LIT7);
_expThen = tmpMeta[0];
_expElse = _OMC_LIT62;
tmpMeta[0] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
_expIf = tmpMeta[0];
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[2] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expIf, tmpMeta[1], _OMC_LIT71);
tmpMeta[0] = mmc_mk_cons(tmpMeta[2], _expLst);
_expLst = tmpMeta[0];
}
}
tmp20 = (modelica_boolean)(listLength(_expLst) > ((modelica_integer) 1));
if(tmp20)
{
tmpMeta[0] = mmc_mk_cons(omc_Expression_makeScalarArray(threadData, _expLst, _OMC_LIT52), MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[1] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT83, tmpMeta[0], _OMC_LIT84);
tmpMeta[2] = tmpMeta[1];
}
else
{
tmpMeta[2] = listHead(_expLst);
}
_rhs = tmpMeta[2];
tmpMeta[0] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _rhs, _OMC_LIT33);
_firedEqn = tmpMeta[0];
tmpMeta[0] = mmc_mk_cons(_firedEqn, _eqs);
_eqs = tmpMeta[0];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeStateRef, _OMC_LIT52);
_exp = tmpMeta[0];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _resetRef, _OMC_LIT7);
_expCond = tmpMeta[0];
_expThen = _OMC_LIT79;
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _firedRef, _OMC_LIT52);
tmpMeta[1] = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, tmpMeta[0], _OMC_LIT85, _OMC_LIT71, mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
_exp1 = tmpMeta[1];
tmpMeta[1] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _firedRef, _OMC_LIT52);
tmpMeta[2] = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta[1]);
tmpMeta[0] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[3] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT56, _tArrayInteger, tmpMeta[0], _preRef), _OMC_LIT52);
_exp2 = tmpMeta[3];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _selectedStateRef, _OMC_LIT52);
tmpMeta[1] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _exp1, _exp2, tmpMeta[0]);
_expElse = tmpMeta[1];
tmpMeta[0] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
_rhs = tmpMeta[0];
tmpMeta[0] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _rhs, _OMC_LIT33);
_activeStateEqn = tmpMeta[0];
tmpMeta[0] = mmc_mk_cons(_activeStateEqn, _eqs);
_eqs = tmpMeta[0];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeResetRef, _OMC_LIT7);
_exp = tmpMeta[0];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _resetRef, _OMC_LIT7);
_expCond = tmpMeta[0];
_expThen = _OMC_LIT77;
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _firedRef, _OMC_LIT52);
tmpMeta[1] = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, tmpMeta[0], _OMC_LIT85, _OMC_LIT71, mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
_exp1 = tmpMeta[1];
tmpMeta[1] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _firedRef, _OMC_LIT52);
tmpMeta[2] = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta[1]);
tmpMeta[0] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[3] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT58, _tArrayBool, tmpMeta[0], _preRef), _OMC_LIT52);
_exp2 = tmpMeta[3];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _selectedResetRef, _OMC_LIT7);
tmpMeta[1] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _exp1, _exp2, tmpMeta[0]);
_expElse = tmpMeta[1];
tmpMeta[0] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
_rhs = tmpMeta[0];
tmpMeta[0] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _rhs, _OMC_LIT33);
_activeResetEqn = tmpMeta[0];
tmpMeta[0] = mmc_mk_cons(_activeResetEqn, _eqs);
_eqs = tmpMeta[0];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _nextStateRef, _OMC_LIT52);
_exp = tmpMeta[0];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeRef, _OMC_LIT7);
_expCond = tmpMeta[0];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeStateRef, _OMC_LIT52);
_expThen = tmpMeta[0];
tmpMeta[1] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _nextStateRef, _OMC_LIT52);
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta[0], _OMC_LIT80);
_expElse = tmpMeta[2];
tmpMeta[0] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
_rhs = tmpMeta[0];
tmpMeta[0] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _rhs, _OMC_LIT33);
_nextStateEqn = tmpMeta[0];
tmpMeta[0] = mmc_mk_cons(_nextStateEqn, _eqs);
_eqs = tmpMeta[0];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _nextResetRef, _OMC_LIT7);
_exp = tmpMeta[0];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeRef, _OMC_LIT7);
_expCond = tmpMeta[0];
_expThen = _OMC_LIT62;
tmpMeta[1] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _nextResetRef, _OMC_LIT7);
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta[0], _OMC_LIT10);
_expElse = tmpMeta[2];
tmpMeta[0] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
_rhs = tmpMeta[0];
tmpMeta[0] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _rhs, _OMC_LIT33);
_nextResetEqn = tmpMeta[0];
tmpMeta[0] = mmc_mk_cons(_nextResetEqn, _eqs);
_eqs = tmpMeta[0];
tmp21 = ((modelica_integer) 1); tmp22 = 1; tmp23 = _nStates;
if(!(((tmp22 > 0) && (tmp21 > tmp23)) || ((tmp22 < 0) && (tmp21 < tmp23))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp21, tmp23); _i += tmp22)
{
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, arrayGet(_activeResetStatesRefs, _i), _OMC_LIT7);
_exp = tmpMeta[0];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _resetRef, _OMC_LIT7);
_expCond = tmpMeta[0];
_expThen = _OMC_LIT77;
tmpMeta[1] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, arrayGet(_nextResetStatesRefs, _i), _OMC_LIT7);
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta[0], _OMC_LIT10);
_expElse = tmpMeta[2];
tmpMeta[0] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
_rhs = tmpMeta[0];
tmpMeta[1] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _rhs, _OMC_LIT33);
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], _eqs);
_eqs = tmpMeta[0];
}
}
tmp24 = ((modelica_integer) 1); tmp25 = 1; tmp26 = _nStates;
if(!(((tmp25 > 0) && (tmp24 > tmp26)) || ((tmp25 < 0) && (tmp24 < tmp26))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp24, tmp26); _i += tmp25)
{
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, arrayGet(_nextResetStatesRefs, _i), _OMC_LIT7);
_exp = tmpMeta[0];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeRef, _OMC_LIT7);
_expCond = tmpMeta[0];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeStateRef, _OMC_LIT52);
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[2] = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, tmpMeta[0], _OMC_LIT81, tmpMeta[1], mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
_exp1 = tmpMeta[2];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, arrayGet(_activeResetStatesRefs, _i), _OMC_LIT7);
tmpMeta[1] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _exp1, _OMC_LIT62, tmpMeta[0]);
_expThen = tmpMeta[1];
tmpMeta[1] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, arrayGet(_nextResetStatesRefs, _i), _OMC_LIT7);
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta[0], _OMC_LIT10);
_expElse = tmpMeta[2];
tmpMeta[0] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
_rhs = tmpMeta[0];
tmpMeta[1] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _rhs, _OMC_LIT33);
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], _eqs);
_eqs = tmpMeta[0];
}
}
tmp31 = ((modelica_integer) 1); tmp32 = 1; tmp33 = _nStates;
if(!(((tmp32 > 0) && (tmp31 > tmp33)) || ((tmp32 < 0) && (tmp31 < tmp33))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp31, tmp33); _i += tmp32)
{
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, arrayGet(_finalStatesRefs, _i), _OMC_LIT7);
_exp = tmpMeta[0];
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_expLst = tmpMeta[0];
tmp27 = ((modelica_integer) 1); tmp28 = 1; tmp29 = _nTransitions;
if(!(((tmp28 > 0) && (tmp27 > tmp29)) || ((tmp28 < 0) && (tmp27 < tmp29))))
{
modelica_integer _j;
for(_j = ((modelica_integer) 1); in_range_integer(_j, tmp27, tmp29); _j += tmp28)
{
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, arrayGet(_tFromRefs, _j), _OMC_LIT52);
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[2] = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, tmpMeta[0], _OMC_LIT81, tmpMeta[1], mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
_expCond = tmpMeta[2];
tmpMeta[1] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _OMC_LIT79, _OMC_LIT71);
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], _expLst);
_expLst = tmpMeta[0];
}
}
tmp30 = (modelica_boolean)(listLength(_expLst) > ((modelica_integer) 1));
if(tmp30)
{
tmpMeta[0] = mmc_mk_cons(omc_Expression_makeScalarArray(threadData, _expLst, _OMC_LIT52), MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[1] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT83, tmpMeta[0], _OMC_LIT84);
tmpMeta[2] = tmpMeta[1];
}
else
{
tmpMeta[2] = listHead(_expLst);
}
_exp1 = tmpMeta[2];
tmpMeta[0] = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, _exp1, _OMC_LIT81, _OMC_LIT71, mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
_rhs = tmpMeta[0];
tmpMeta[1] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _rhs, _OMC_LIT33);
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], _eqs);
_eqs = tmpMeta[0];
}
}
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _stateMachineInFinalStateRef, _OMC_LIT7);
_exp = tmpMeta[0];
tmpMeta[1] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeStateRef, _OMC_LIT52);
tmpMeta[2] = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta[1]);
tmpMeta[0] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[3] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT75, _nStatesArrayBool, tmpMeta[0], _preRef), _OMC_LIT7);
_rhs = tmpMeta[3];
tmpMeta[1] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _rhs, _OMC_LIT33);
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], _eqs);
_eqs = tmpMeta[0];
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[2] = mmc_mk_box11(3, &StateMachineFlatten_FlatSmSemantics_FLAT__SM__SEMANTICS__desc, _ident, listArray(_q), _t, _cExps, _vars, _knowns, _eqs, tmpMeta[0], tmpMeta[1], mmc_mk_none());
_flatSmSemantics = tmpMeta[2];
_return: OMC_LABEL_UNUSED
return _flatSmSemantics;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_setVarFixedStartValue(threadData_t *threadData, modelica_metatype _inVar, modelica_metatype _inExp)
{
modelica_metatype _outVar = NULL;
modelica_metatype _vao = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inVar;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,13) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 12));
_vao = tmpMeta[1];
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_activePlotIndicatorRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT63, _OMC_LIT7, tmpMeta[0], _stateRef);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_activePlotIndicatorVar = omc_StateMachineFlatten_createVarWithStartValue(threadData, _activePlotIndicatorRef, _OMC_LIT51, _OMC_LIT7, _OMC_LIT62, tmpMeta[0]);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_activeRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT63, _OMC_LIT7, tmpMeta[0], _preRef);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_activeStateRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT68, _OMC_LIT52, tmpMeta[0], _preRef);
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeStateRef, _OMC_LIT52);
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[2] = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, tmpMeta[0], _OMC_LIT81, tmpMeta[1], mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
_eqExp = tmpMeta[2];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeRef, _OMC_LIT7);
tmpMeta[1] = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, tmpMeta[0], _OMC_LIT87, _eqExp);
_andExp = tmpMeta[1];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activePlotIndicatorRef, _OMC_LIT7);
tmpMeta[1] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, tmpMeta[0], _andExp, _OMC_LIT33);
_eqn = tmpMeta[1];
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_ticksInStateRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT88, _OMC_LIT52, tmpMeta[0], _stateRef);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_ticksInStateVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _ticksInStateRef, _OMC_LIT51, _OMC_LIT52, tmpMeta[0]);
_ticksInStateVar = omc_StateMachineFlatten_setVarFixedStartValue(threadData, _ticksInStateVar, _OMC_LIT71);
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _ticksInStateRef, _OMC_LIT52);
_ticksInStateExp = tmpMeta[0];
_expCond = omc_Expression_crefExp(threadData, _stateActiveRef);
tmpMeta[0] = mmc_mk_cons(_ticksInStateExp, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[1] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta[0], _OMC_LIT80);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], _OMC_LIT89, _OMC_LIT79);
_expThen = tmpMeta[2];
_expElse = _OMC_LIT71;
tmpMeta[0] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
tmpMeta[1] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _ticksInStateExp, tmpMeta[0], _OMC_LIT33);
_ticksInStateEqn = tmpMeta[1];
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
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_timeEnteredStateRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT90, _OMC_LIT91, tmpMeta[0], _stateRef);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_timeEnteredStateVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _timeEnteredStateRef, _OMC_LIT51, _OMC_LIT91, tmpMeta[0]);
_timeEnteredStateVar = omc_StateMachineFlatten_setVarFixedStartValue(threadData, _timeEnteredStateVar, _OMC_LIT92);
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _timeEnteredStateRef, _OMC_LIT91);
_timeEnteredStateExp = tmpMeta[0];
_stateActiveExp = omc_Expression_crefExp(threadData, _stateActiveRef);
tmpMeta[0] = mmc_mk_cons(_stateActiveExp, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[1] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta[0], _OMC_LIT10);
tmpMeta[2] = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, tmpMeta[1], _OMC_LIT93, _OMC_LIT62, mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
tmpMeta[3] = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, _stateActiveExp, _OMC_LIT93, _OMC_LIT77, mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
tmpMeta[4] = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, tmpMeta[2], _OMC_LIT87, tmpMeta[3]);
_expCond = tmpMeta[4];
_expThen = _OMC_LIT102;
tmpMeta[0] = mmc_mk_cons(_timeEnteredStateExp, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[1] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta[0], _OMC_LIT101);
_expElse = tmpMeta[1];
tmpMeta[0] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
tmpMeta[1] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _timeEnteredStateExp, tmpMeta[0], _OMC_LIT33);
_timeEnteredStateEqn = tmpMeta[1];
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_timeInStateRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT103, _OMC_LIT91, tmpMeta[0], _stateRef);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_timeInStateVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _timeInStateRef, _OMC_LIT51, _OMC_LIT91, tmpMeta[0]);
_timeInStateVar = omc_StateMachineFlatten_setVarFixedStartValue(threadData, _timeInStateVar, _OMC_LIT92);
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _timeInStateRef, _OMC_LIT91);
_timeInStateExp = tmpMeta[0];
tmpMeta[0] = _timeEnteredStateVar;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,13) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
_timeEnteredStateRef = tmpMeta[1];
_ty = tmpMeta[2];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _timeEnteredStateRef, _ty);
_timeEnteredStateExp = tmpMeta[0];
_stateActiveExp = omc_Expression_crefExp(threadData, _stateActiveRef);
_expCond = omc_Expression_crefExp(threadData, _stateActiveRef);
_expSampleTime = _OMC_LIT102;
tmpMeta[0] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _expSampleTime, _OMC_LIT104, _timeEnteredStateExp);
_expThen = tmpMeta[0];
_expElse = _OMC_LIT92;
tmpMeta[0] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _expCond, _expThen, _expElse);
tmpMeta[1] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _timeInStateExp, tmpMeta[0], _OMC_LIT33);
_timeInStateEqn = tmpMeta[1];
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
modelica_metatype _peqs = NULL;
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
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype tmpMeta[10] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_pvars = tmpMeta[0];
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_peqs = tmpMeta[1];
tmpMeta[2] = _inFlatSmSemantics;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 6));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 7));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 8));
_ident = tmpMeta[3];
_smComps = tmpMeta[4];
_t = tmpMeta[5];
_c = tmpMeta[6];
_smvars = tmpMeta[7];
_smknowns = tmpMeta[8];
_smeqs = tmpMeta[9];
tmpMeta[2] = arrayGet(_smComps, ((modelica_integer) 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],29,2) == 0) MMC_THROW_INTERNAL();
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_initStateRef = tmpMeta[3];
_preRef = omc_ComponentReference_crefPrefixString(threadData, _OMC_LIT4, _initStateRef);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_activeRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT63, _OMC_LIT7, tmpMeta[2], _preRef);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_resetRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT64, _OMC_LIT7, tmpMeta[2], _preRef);
if(isNone(_inEnclosingFlatSmSemanticsOption))
{
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_initRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT106, _OMC_LIT7, tmpMeta[2], _preRef);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_initVar = omc_StateMachineFlatten_createVarWithDefaults(threadData, _initRef, _OMC_LIT51, _OMC_LIT7, tmpMeta[2]);
_initVar = omc_StateMachineFlatten_setVarFixedStartValue(threadData, _initVar, _OMC_LIT77);
tmpMeta[2] = mmc_mk_cons(_initVar, _pvars);
_pvars = tmpMeta[2];
tmpMeta[3] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _initRef, _OMC_LIT7);
tmpMeta[4] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, tmpMeta[3], _OMC_LIT62, _OMC_LIT33);
tmpMeta[2] = mmc_mk_cons(tmpMeta[4], _peqs);
_peqs = tmpMeta[2];
tmpMeta[3] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _initRef, _OMC_LIT7);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[4] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta[2], _OMC_LIT10);
_rhs = tmpMeta[4];
tmpMeta[3] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _resetRef, _OMC_LIT7);
tmpMeta[4] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, tmpMeta[3], _rhs, _OMC_LIT33);
tmpMeta[2] = mmc_mk_cons(tmpMeta[4], _peqs);
_peqs = tmpMeta[2];
tmpMeta[3] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeRef, _OMC_LIT7);
tmpMeta[4] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, tmpMeta[3], _OMC_LIT77, _OMC_LIT33);
tmpMeta[2] = mmc_mk_cons(tmpMeta[4], _peqs);
_peqs = tmpMeta[2];
}
else
{
_enclosingStateCref = omc_Util_getOption(threadData, _inEnclosingStateCrefOption);
_enclosingFlatSMSemantics = omc_Util_getOption(threadData, _inEnclosingFlatSmSemanticsOption);
tmpMeta[2] = _enclosingFlatSMSemantics;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
_enclosingFlatSMComps = tmpMeta[3];
tmpMeta[2] = arrayGet(_enclosingFlatSMComps, ((modelica_integer) 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],29,2) == 0) MMC_THROW_INTERNAL();
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_enclosingFlatSMInitStateRef = tmpMeta[3];
_enclosingPreRef = omc_ComponentReference_crefPrefixString(threadData, _OMC_LIT4, _enclosingFlatSMInitStateRef);
_posOfEnclosingSMComp = omc_List_position1OnTrue(threadData, arrayList(_enclosingFlatSMComps), boxvar_StateMachineFlatten_sMCompEqualsRef, _enclosingStateCref);
_nStates = arrayLength(_enclosingFlatSMComps);
tmpMeta[3] = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_nStates));
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[4] = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT7, tmpMeta[2]);
_tArrayBool = tmpMeta[4];
tmpMeta[3] = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_nStates));
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[4] = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT52, tmpMeta[2]);
_tArrayInteger = tmpMeta[4];
tmpMeta[3] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_posOfEnclosingSMComp));
tmpMeta[4] = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta[3]);
tmpMeta[2] = mmc_mk_cons(tmpMeta[4], MMC_REFSTRUCTLIT(mmc_nil));
_enclosingActiveResetStateRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT73, _tArrayBool, tmpMeta[2], _enclosingPreRef);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_enclosingActiveResetRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT69, _OMC_LIT7, tmpMeta[2], _enclosingPreRef);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_enclosingActiveStateRef = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT68, _OMC_LIT52, tmpMeta[2], _enclosingPreRef);
tmpMeta[2] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _enclosingActiveStateRef, _OMC_LIT52);
tmpMeta[3] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_posOfEnclosingSMComp));
tmpMeta[4] = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, tmpMeta[2], _OMC_LIT81, tmpMeta[3], mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
_eqExp = tmpMeta[4];
tmpMeta[2] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _enclosingActiveResetRef, _OMC_LIT7);
tmpMeta[3] = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, tmpMeta[2], _OMC_LIT87, _eqExp);
_andExp = tmpMeta[3];
tmpMeta[2] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _enclosingActiveResetStateRef, _OMC_LIT7);
tmpMeta[3] = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, tmpMeta[2], _OMC_LIT105, _andExp);
_rhs = tmpMeta[3];
tmpMeta[3] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _resetRef, _OMC_LIT7);
tmpMeta[4] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, tmpMeta[3], _rhs, _OMC_LIT33);
tmpMeta[2] = mmc_mk_cons(tmpMeta[4], _peqs);
_peqs = tmpMeta[2];
tmpMeta[2] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _enclosingActiveStateRef, _OMC_LIT52);
tmpMeta[3] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_posOfEnclosingSMComp));
tmpMeta[4] = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, tmpMeta[2], _OMC_LIT81, tmpMeta[3], mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
_rhs = tmpMeta[4];
tmpMeta[3] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _activeRef, _OMC_LIT7);
tmpMeta[4] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, tmpMeta[3], _rhs, _OMC_LIT33);
tmpMeta[2] = mmc_mk_cons(tmpMeta[4], _peqs);
_peqs = tmpMeta[2];
}
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = arrayLength(_smComps);
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
tmpMeta[2] = arrayGet(_smComps, _i);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],29,2) == 0) MMC_THROW_INTERNAL();
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_stateRef = tmpMeta[3];
_activePlotIndicatorVar = omc_StateMachineFlatten_createActiveIndicator(threadData, _stateRef, _preRef, _i ,&_activePlotIndicatorEqn);
tmpMeta[2] = mmc_mk_cons(_activePlotIndicatorVar, _pvars);
_pvars = tmpMeta[2];
tmpMeta[2] = mmc_mk_cons(_activePlotIndicatorEqn, _peqs);
_peqs = tmpMeta[2];
tmpMeta[2] = _activePlotIndicatorVar;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,13) == 0) MMC_THROW_INTERNAL();
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_activePlotIndicatorRef = tmpMeta[3];
_ticksInStateVar = omc_StateMachineFlatten_createTicksInStateIndicator(threadData, _stateRef, _activePlotIndicatorRef ,&_ticksInStateEqn);
tmpMeta[2] = mmc_mk_cons(_ticksInStateVar, _pvars);
_pvars = tmpMeta[2];
tmpMeta[2] = mmc_mk_cons(_ticksInStateEqn, _peqs);
_peqs = tmpMeta[2];
_timeEnteredStateVar = omc_StateMachineFlatten_createTimeEnteredStateIndicator(threadData, _stateRef, _activePlotIndicatorRef ,&_timeEnteredStateEqn);
_timeInStateVar = omc_StateMachineFlatten_createTimeInStateIndicator(threadData, _stateRef, _activePlotIndicatorRef, _timeEnteredStateVar ,&_timeInStateEqn);
tmpMeta[3] = mmc_mk_cons(_timeInStateVar, _pvars);
tmpMeta[2] = mmc_mk_cons(_timeEnteredStateVar, tmpMeta[3]);
_pvars = tmpMeta[2];
tmpMeta[3] = mmc_mk_cons(_timeInStateEqn, _peqs);
tmpMeta[2] = mmc_mk_cons(_timeEnteredStateEqn, tmpMeta[3]);
_peqs = tmpMeta[2];
}
}
tmpMeta[2] = mmc_mk_box11(3, &StateMachineFlatten_FlatSmSemantics_FLAT__SM__SEMANTICS__desc, _ident, _smComps, _t, _c, _smvars, _smknowns, _smeqs, _pvars, _peqs, _inEnclosingStateCrefOption);
_outFlatSmSemantics = tmpMeta[2];
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
modelica_metatype tmpMeta[10] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (8 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT3), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta[4])) goto tmp3_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],6,2) == 0) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
if (!listEmpty(tmpMeta[6])) goto tmp3_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
_cr = tmpMeta[7];
_ty = tmpMeta[8];
_crefs = tmpMeta[9];
tmpMeta[2] = mmc_mk_box1(0, _cr);
if (!omc_List_exist(threadData, _crefs, (modelica_fnptr) mmc_mk_box2(0,closure1_ComponentReference_crefEqual,tmpMeta[2]))) goto tmp3_end;
_substituteRef = omc_ComponentReference_appendStringLastIdent(threadData, _OMC_LIT107, _cr);
tmpMeta[3] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _substituteRef, _ty);
tmpMeta[4] = mmc_mk_box2(0, _crefs, mmc_mk_boolean(1));
tmpMeta[0+0] = tmpMeta[3];
tmpMeta[0+1] = tmpMeta[4];
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
modelica_metatype tmpMeta[10] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (8 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT3), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta[4])) goto tmp3_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],6,2) == 0) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
if (!listEmpty(tmpMeta[6])) goto tmp3_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
_cr = tmpMeta[7];
_ty = tmpMeta[8];
_cref = tmpMeta[9];
if (!omc_ComponentReference_crefEqual(threadData, _cr, _cref)) goto tmp3_end;
tmpMeta[2] = stringAppend(_OMC_LIT108,omc_ComponentReference_crefStr(threadData, _cr));
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT109);
tmpMeta[4] = stringAppend(tmpMeta[3],omc_ComponentReference_crefStr(threadData, _cref));
tmpMeta[5] = stringAppend(tmpMeta[4],_OMC_LIT110);
fputs(MMC_STRINGDATA(tmpMeta[5]),stdout);
_substituteRef = omc_ComponentReference_appendStringLastIdent(threadData, _OMC_LIT107, _cref);
tmpMeta[2] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _substituteRef, _ty);
tmpMeta[3] = mmc_mk_box2(0, _cref, mmc_mk_boolean(1));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = tmpMeta[3];
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
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inEqn;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],3,3) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
_exp = tmpMeta[1];
_scalar = tmpMeta[2];
_source = tmpMeta[3];
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
tmpMeta[0] = _exp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],13,3) == 0) goto goto_1;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp("der", MMC_STRINGDATA(tmpMeta[2])) != 0) goto goto_1;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
if (listEmpty(tmpMeta[3])) goto goto_1;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],6,2) == 0) goto goto_1;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (!listEmpty(tmpMeta[5])) goto goto_1;
_cref = tmpMeta[6];
_ty = tmpMeta[7];
goto tmp2_done;
}
case 1: {
omc_Error_addCompilerError(threadData, _OMC_LIT111);
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
;
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT63, _OMC_LIT7, tmpMeta[0], _inStateCref), _OMC_LIT7);
_activeRef = tmpMeta[1];
tmpMeta[0] = mmc_mk_box8(3, &DAE_CallAttributes_CALL__ATTR__desc, _ty, mmc_mk_boolean(0), mmc_mk_boolean(1), mmc_mk_boolean(0), mmc_mk_boolean(0), _OMC_LIT8, _OMC_LIT9);
_callAttributes = tmpMeta[0];
_expElse = _OMC_LIT92;
tmpMeta[0] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _activeRef, _scalar, _expElse);
_scalar1 = tmpMeta[0];
tmpMeta[0] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _scalar1, _source);
_outEqn = tmpMeta[0];
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
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inEqn;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],3,3) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
_exp = tmpMeta[1];
_scalar = tmpMeta[2];
_source = tmpMeta[3];
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
tmpMeta[0] = _exp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],6,2) == 0) goto goto_1;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_cref = tmpMeta[1];
_ty = tmpMeta[2];
goto tmp2_done;
}
case 1: {
omc_Error_addCompilerError(threadData, _OMC_LIT112);
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
;
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT63, _OMC_LIT7, tmpMeta[0], _inStateCref), _OMC_LIT7);
_activeRef = tmpMeta[1];
tmpMeta[0] = mmc_mk_box8(3, &DAE_CallAttributes_CALL__ATTR__desc, _ty, mmc_mk_boolean(0), mmc_mk_boolean(1), mmc_mk_boolean(0), mmc_mk_boolean(0), _OMC_LIT8, _OMC_LIT9);
_callAttributes = tmpMeta[0];
if(_isResetEquation)
{
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_ComponentReference_appendStringLastIdent(threadData, _OMC_LIT107, _cref), _ty);
_expElse = tmpMeta[0];
}
else
{
tmpMeta[0] = mmc_mk_cons(_exp, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[1] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta[0], _callAttributes);
_expElse = tmpMeta[1];
}
tmpMeta[0] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _activeRef, _scalar, _expElse);
_scalar1 = tmpMeta[0];
tmpMeta[0] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _scalar1, _source);
_outEqn = tmpMeta[0];
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
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inEnclosingFlatSmSemantics;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_enclosingFlatSMComps = tmpMeta[1];
tmpMeta[0] = arrayGet(_enclosingFlatSMComps, ((modelica_integer) 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],29,2) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_initStateRef = tmpMeta[1];
_preRef = omc_ComponentReference_crefPrefixString(threadData, _OMC_LIT4, _initStateRef);
_i = omc_List_position1OnTrue(threadData, arrayList(_enclosingFlatSMComps), boxvar_StateMachineFlatten_sMCompEqualsRef, _inStateCref);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT69, _OMC_LIT7, tmpMeta[0], _preRef), _OMC_LIT7);
_activeResetExp = tmpMeta[1];
_nStates = arrayLength(_enclosingFlatSMComps);
tmpMeta[1] = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_nStates));
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT7, tmpMeta[0]);
_tArrayBool = tmpMeta[2];
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[2] = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta[1]);
tmpMeta[0] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[3] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT73, _tArrayBool, tmpMeta[0], _preRef), _OMC_LIT7);
_activeResetStatesExp = tmpMeta[3];
tmpMeta[0] = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, _activeResetExp, _OMC_LIT105, _activeResetStatesExp);
_orExp = tmpMeta[0];
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT63, _OMC_LIT7, tmpMeta[0], _inStateCref), _OMC_LIT7);
_activeExp = tmpMeta[1];
tmpMeta[0] = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, _activeExp, _OMC_LIT87, _orExp);
_andExp = tmpMeta[0];
tmpMeta[0] = mmc_mk_box8(3, &DAE_CallAttributes_CALL__ATTR__desc, _inLHSty, mmc_mk_boolean(0), mmc_mk_boolean(1), mmc_mk_boolean(0), mmc_mk_boolean(0), _OMC_LIT8, _OMC_LIT9);
_callAttributes = tmpMeta[0];
tmpMeta[1] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _inLHSCref, _inLHSty);
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT78, tmpMeta[0], _callAttributes);
_previousExp = tmpMeta[2];
_startValueOpt = omc_BaseHashTable_get(threadData, _inLHSCref, _crToExpOpt);
if(isSome(_startValueOpt))
{
_startValueExp = omc_Util_getOption(threadData, _startValueOpt);
}
else
{
{
modelica_metatype tmp3_1;
tmp3_1 = _inLHSty;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
tmpMeta[1] = stringAppend(_OMC_LIT113,omc_ComponentReference_crefStr(threadData, _inLHSCref));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT114);
omc_Error_addCompilerWarning(threadData, tmpMeta[2]);
tmpMeta[0] = _OMC_LIT71;
goto tmp2_done;
}
case 4: {
tmpMeta[1] = stringAppend(_OMC_LIT113,omc_ComponentReference_crefStr(threadData, _inLHSCref));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT114);
omc_Error_addCompilerWarning(threadData, tmpMeta[2]);
tmpMeta[0] = _OMC_LIT92;
goto tmp2_done;
}
case 6: {
tmpMeta[1] = stringAppend(_OMC_LIT113,omc_ComponentReference_crefStr(threadData, _inLHSCref));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT115);
omc_Error_addCompilerWarning(threadData, tmpMeta[2]);
tmpMeta[0] = _OMC_LIT62;
goto tmp2_done;
}
case 5: {
tmpMeta[1] = stringAppend(_OMC_LIT113,omc_ComponentReference_crefStr(threadData, _inLHSCref));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT116);
omc_Error_addCompilerWarning(threadData, tmpMeta[2]);
tmpMeta[0] = _OMC_LIT117;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
tmpMeta[1] = stringAppend(_OMC_LIT113,omc_ComponentReference_crefStr(threadData, _inLHSCref));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT118);
omc_Error_addCompilerError(threadData, tmpMeta[2]);
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
_startValueExp = tmpMeta[0];
}
tmpMeta[0] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _andExp, _startValueExp, _previousExp);
_ifExp = tmpMeta[0];
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_ComponentReference_appendStringLastIdent(threadData, _OMC_LIT107, _inLHSCref), _inLHSty);
_lhsExp = tmpMeta[0];
tmpMeta[0] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _lhsExp, _ifExp, _OMC_LIT33);
_outEqn = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outEqn;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_StateMachineFlatten_isCrefInVar(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inCref)
{
modelica_boolean _result;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cref = tmpMeta[0];
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
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inEnclosingFlatSmSemantics;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_enclosingFlatSMComps = tmpMeta[1];
tmpMeta[0] = arrayGet(_enclosingFlatSMComps, ((modelica_integer) 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],29,2) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_initStateRef = tmpMeta[1];
_preRef = omc_ComponentReference_crefPrefixString(threadData, _OMC_LIT4, _initStateRef);
_i = omc_List_position1OnTrue(threadData, arrayList(_enclosingFlatSMComps), boxvar_StateMachineFlatten_sMCompEqualsRef, _inStateCref);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT69, _OMC_LIT7, tmpMeta[0], _preRef), _OMC_LIT7);
_activeResetExp = tmpMeta[1];
_nStates = arrayLength(_enclosingFlatSMComps);
tmpMeta[1] = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_nStates));
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT7, tmpMeta[0]);
_tArrayBool = tmpMeta[2];
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[2] = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta[1]);
tmpMeta[0] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[3] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT73, _tArrayBool, tmpMeta[0], _preRef), _OMC_LIT7);
_activeResetStatesExp = tmpMeta[3];
tmpMeta[0] = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, _activeResetExp, _OMC_LIT105, _activeResetStatesExp);
_orExp = tmpMeta[0];
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT63, _OMC_LIT7, tmpMeta[0], _inStateCref), _OMC_LIT7);
_activeExp = tmpMeta[1];
tmpMeta[0] = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, _activeExp, _OMC_LIT87, _orExp);
_andExp = tmpMeta[0];
_startValueOpt = omc_BaseHashTable_get(threadData, _inLHSCref, _crToExpOpt);
if(isSome(_startValueOpt))
{
_startValueExp = omc_Util_getOption(threadData, _startValueOpt);
}
else
{
{
modelica_metatype tmp3_1;
tmp3_1 = _inLHSty;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
tmpMeta[1] = stringAppend(_OMC_LIT113,omc_ComponentReference_crefStr(threadData, _inLHSCref));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT114);
omc_Error_addCompilerWarning(threadData, tmpMeta[2]);
tmpMeta[0] = _OMC_LIT71;
goto tmp2_done;
}
case 4: {
tmpMeta[1] = stringAppend(_OMC_LIT113,omc_ComponentReference_crefStr(threadData, _inLHSCref));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT114);
omc_Error_addCompilerWarning(threadData, tmpMeta[2]);
tmpMeta[0] = _OMC_LIT92;
goto tmp2_done;
}
case 6: {
tmpMeta[1] = stringAppend(_OMC_LIT113,omc_ComponentReference_crefStr(threadData, _inLHSCref));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT115);
omc_Error_addCompilerWarning(threadData, tmpMeta[2]);
tmpMeta[0] = _OMC_LIT62;
goto tmp2_done;
}
case 5: {
tmpMeta[1] = stringAppend(_OMC_LIT113,omc_ComponentReference_crefStr(threadData, _inLHSCref));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT116);
omc_Error_addCompilerWarning(threadData, tmpMeta[2]);
tmpMeta[0] = _OMC_LIT117;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
tmpMeta[1] = stringAppend(_OMC_LIT113,omc_ComponentReference_crefStr(threadData, _inLHSCref));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT118);
omc_Error_addCompilerError(threadData, tmpMeta[2]);
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
_startValueExp = tmpMeta[0];
}
tmpMeta[0] = mmc_mk_box4(26, &DAE_Element_REINIT__desc, _inLHSCref, _startValueExp, _OMC_LIT33);
_reinitElem = tmpMeta[0];
tmpMeta[0] = mmc_mk_cons(_reinitElem, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[1] = mmc_mk_box5(13, &DAE_Element_WHEN__EQUATION__desc, _andExp, tmpMeta[0], mmc_mk_none(), _OMC_LIT33);
_outEqn = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _outEqn;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_traversingFindPreviousCref(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inCrefHit, modelica_boolean *out_cont, modelica_metatype *out_outCrefHit)
{
modelica_metatype _outExp = NULL;
modelica_boolean _cont;
modelica_metatype _outCrefHit = NULL;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (8 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT3), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta[4])) goto tmp3_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],6,2) == 0) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
if (!listEmpty(tmpMeta[6])) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
_cr = tmpMeta[7];
_cref = tmpMeta[8];
if (!omc_ComponentReference_crefEqual(threadData, _cr, _cref)) goto tmp3_end;
tmpMeta[2] = mmc_mk_box2(0, _cref, mmc_mk_boolean(1));
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = tmpMeta[2];
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
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
modelica_integer tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,3) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_exp = tmpMeta[0];
_scalar = tmpMeta[1];
_source = tmpMeta[2];
_cref = omc_DAEUtil_varCref(threadData, _var);
tmpMeta[2] = mmc_mk_box2(0, _cref, mmc_mk_boolean(0));
omc_Expression_traverseExpTopDown(threadData, _scalar, boxvar_StateMachineFlatten_traversingFindPreviousCref, tmpMeta[2], &tmpMeta[0]);
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp6 = mmc_unbox_integer(tmpMeta[1]);
_found = tmp6;
tmp1 = _found;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!optionNone(tmpMeta[1])) goto tmp3_end;
_equations = tmpMeta[0];
tmp1 = omc_List_exist1(threadData, _equations, boxvar_StateMachineFlatten_isPreviousAppliedToVar, _var);
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (optionNone(tmpMeta[0])) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,3) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_exp = tmpMeta[0];
_scalar = tmpMeta[1];
_source = tmpMeta[2];
_cref = omc_DAEUtil_varCref(threadData, _var);
{
{
volatile mmc_switch_type tmp8;
int tmp9;
tmp8 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp7_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp8 < 2; tmp8++) {
switch (MMC_SWITCH_CAST(tmp8)) {
case 0: {
tmpMeta[0] = _exp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],6,2) == 0) goto goto_6;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_crefLHS = tmpMeta[1];
_tyLHS = tmpMeta[2];
_res = omc_ComponentReference_crefEqual(threadData, _crefLHS, _cref);
goto tmp7_done;
}
case 1: {
_res = 0;
goto tmp7_done;
}
}
goto tmp7_end;
tmp7_end: ;
}
goto goto_6;
tmp7_done:
(void)tmp8;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp7_done2;
goto_6:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp8 < 2) {
goto tmp7_top;
}
goto goto_2;
tmp7_done2:;
}
}
;
tmp1 = _res;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!optionNone(tmpMeta[1])) goto tmp3_end;
_equations = tmpMeta[0];
tmp1 = omc_List_exist1(threadData, _equations, boxvar_StateMachineFlatten_isVarAtLHS, _var);
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (optionNone(tmpMeta[0])) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
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
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inEqn;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],3,3) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
_exp = tmpMeta[1];
_scalar = tmpMeta[2];
_source = tmpMeta[3];
tmpMeta[0] = _inEnclosingSMComp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],29,2) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_enclosingStateRef = tmpMeta[1];
_dAElist = tmpMeta[2];
_stateVarCrefs = omc_BaseHashTable_hashTableKeyList(threadData, _crToExpOpt);
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
tmpMeta[0] = _exp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],6,2) == 0) goto goto_1;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_crefLHS = tmpMeta[1];
_tyLHS = tmpMeta[2];
tmpMeta[2] = mmc_mk_box2(0, _stateVarCrefs, mmc_mk_boolean(0));
tmpMeta[3] = omc_Expression_traverseExpTopDown(threadData, _scalar, boxvar_StateMachineFlatten_traversingSubsPreviousCrefs, tmpMeta[2], &tmpMeta[0]);
_scalarNew = tmpMeta[3];
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
_found = tmp5;
tmpMeta[0] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp, _scalarNew, _source);
_eqn = tmpMeta[0];
tmpMeta[0] = mmc_mk_box1(0, _crefLHS);
if(omc_List_exist(threadData, _stateVarCrefs, (modelica_fnptr) mmc_mk_box2(0,closure2_ComponentReference_crefEqual,tmpMeta[0])))
{
_eqn1 = omc_StateMachineFlatten_wrapInStateActivationConditional(threadData, _eqn, _enclosingStateRef, 1);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_var2 = omc_StateMachineFlatten_createVarWithDefaults(threadData, omc_ComponentReference_appendStringLastIdent(threadData, _OMC_LIT107, _crefLHS), _OMC_LIT51, _tyLHS, tmpMeta[1]);
_eqn2 = omc_StateMachineFlatten_createResetEquation(threadData, _crefLHS, _tyLHS, _enclosingStateRef, _inEnclosingFlatSmSemantics, _crToExpOpt);
tmpMeta[2] = mmc_mk_cons(_eqn2, omc_Util_tuple21(threadData, _accEqnsVars));
tmpMeta[1] = mmc_mk_cons(_eqn1, tmpMeta[2]);
tmpMeta[3] = mmc_mk_cons(_var2, omc_Util_tuple22(threadData, _accEqnsVars));
tmpMeta[4] = mmc_mk_box2(0, tmpMeta[1], tmpMeta[3]);
_outEqnsVars = tmpMeta[4];
}
else
{
tmpMeta[1] = mmc_mk_cons(omc_StateMachineFlatten_wrapInStateActivationConditional(threadData, _eqn, _enclosingStateRef, 0), omc_Util_tuple21(threadData, _accEqnsVars));
tmpMeta[2] = mmc_mk_box2(0, tmpMeta[1], omc_Util_tuple22(threadData, _accEqnsVars));
_outEqnsVars = tmpMeta[2];
}
goto tmp2_done;
}
case 1: {
{
{
volatile mmc_switch_type tmp8;
int tmp9;
tmp8 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp7_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp8 < 2; tmp8++) {
switch (MMC_SWITCH_CAST(tmp8)) {
case 0: {
if(omc_Flags_getConfigBool(threadData, _OMC_LIT28))
{
tmpMeta[0] = _exp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],13,3) == 0) goto goto_6;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto goto_6;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp("der", MMC_STRINGDATA(tmpMeta[2])) != 0) goto goto_6;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
if (listEmpty(tmpMeta[3])) goto goto_6;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],6,2) == 0) goto goto_6;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (!listEmpty(tmpMeta[5])) goto goto_6;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
_crefLHS = tmpMeta[6];
_tyLHS = tmpMeta[7];
_attr = tmpMeta[8];
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
_varDecl = omc_List_find1(threadData, _dAElist, boxvar_StateMachineFlatten_isCrefInVar, _crefLHS);
goto tmp11_done;
}
case 1: {
tmpMeta[0] = stringAppend(_OMC_LIT122,omc_ComponentReference_crefStr(threadData, _crefLHS));
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT110);
omc_Error_addCompilerError(threadData, tmpMeta[1]);
goto goto_10;
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
goto goto_6;
tmp11_done2:;
}
}
;
_isOuterVar = omc_DAEUtil_isOuterVar(threadData, _varDecl);
if(_isOuterVar)
{
_cref2 = omc_ComponentReference_appendStringLastIdent(threadData, _OMC_LIT123, _crefLHS);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_var2 = omc_StateMachineFlatten_createVarWithDefaults(threadData, _cref2, _OMC_LIT124, _tyLHS, tmpMeta[0]);
tmpMeta[0] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _cref2, _tyLHS);
tmpMeta[1] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, tmpMeta[0], _scalar, _source);
_eqn1 = tmpMeta[1];
tmpMeta[0] = mmc_mk_cons(_eqn1, omc_Util_tuple21(threadData, _accEqnsVars));
tmpMeta[1] = mmc_mk_cons(_var2, omc_Util_tuple22(threadData, _accEqnsVars));
tmpMeta[2] = mmc_mk_box2(0, tmpMeta[0], tmpMeta[1]);
_outEqnsVars = tmpMeta[2];
}
else
{
_eqn1 = omc_StateMachineFlatten_wrapInStateActivationConditionalCT(threadData, _inEqn, _enclosingStateRef);
_eqn2 = omc_StateMachineFlatten_createResetEquationCT(threadData, _crefLHS, _tyLHS, _enclosingStateRef, _inEnclosingFlatSmSemantics, _crToExpOpt);
tmpMeta[1] = mmc_mk_cons(_eqn2, omc_Util_tuple21(threadData, _accEqnsVars));
tmpMeta[0] = mmc_mk_cons(_eqn1, tmpMeta[1]);
tmpMeta[2] = mmc_mk_box2(0, tmpMeta[0], omc_Util_tuple22(threadData, _accEqnsVars));
_outEqnsVars = tmpMeta[2];
}
}
else
{
goto goto_6;
}
goto tmp7_done;
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
goto goto_6;
goto tmp7_done;
}
}
goto tmp7_end;
tmp7_end: ;
}
goto goto_6;
tmp7_done:
(void)tmp8;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp7_done2;
goto_6:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp8 < 2) {
goto tmp7_top;
}
goto goto_1;
tmp7_done2:;
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
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inEqn;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,3) == 0) goto tmp2_end;
tmpMeta[0] = omc_StateMachineFlatten_addStateActivationAndReset1(threadData, _inEqn, _inEnclosingSMComp, _inEnclosingFlatSmSemantics, _crToExpOpt, _accEqnsVars);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,10,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (!optionNone(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_condition = tmpMeta[1];
_equations = tmpMeta[2];
_source = tmpMeta[4];
tmpMeta[1] = omc_List_fold3(threadData, _equations, boxvar_StateMachineFlatten_addStateActivationAndReset, _inEnclosingSMComp, _inEnclosingFlatSmSemantics, _crToExpOpt, _OMC_LIT127);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_equations1 = tmpMeta[2];
_vars1 = tmpMeta[3];
tmpMeta[2] = mmc_mk_box5(13, &DAE_Element_WHEN__EQUATION__desc, _condition, _equations1, mmc_mk_none(), _source);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], omc_Util_tuple21(threadData, _accEqnsVars));
tmpMeta[3] = mmc_mk_box2(0, tmpMeta[1], listAppend(_vars1, omc_Util_tuple22(threadData, _accEqnsVars)));
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,10,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
omc_Error_addCompilerError(threadData, _OMC_LIT119);
goto goto_1;
goto tmp2_done;
}
case 3: {
omc_Error_addCompilerError(threadData, _OMC_LIT128);
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
_outEqnsVars = tmpMeta[0];
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outElems = _accElems;
tmpMeta[0] = _inSMComp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],29,2) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_componentRef = tmpMeta[1];
_dAElist = tmpMeta[2];
_varLst1 = omc_List_extractOnTrue(threadData, _dAElist, boxvar_StateMachineFlatten_isVar ,&_otherLst1);
_equationLst1 = omc_List_extractOnTrue(threadData, _otherLst1, boxvar_StateMachineFlatten_isEquationOrWhenEquation ,&_otherLst2);
tmpMeta[0] = mmc_mk_box2(0, _equationLst1, boxvar_StateMachineFlatten_isVarAtLHS);
_assignedVarLst = omc_List_filterOnTrue(threadData, _varLst1, (modelica_fnptr) mmc_mk_box2(0,closure3_List_exist1,tmpMeta[0]));
tmpMeta[0] = mmc_mk_box2(0, _equationLst1, boxvar_StateMachineFlatten_isPreviousAppliedToVar);
_stateVarLst = omc_List_filterOnTrue(threadData, _varLst1, (modelica_fnptr) mmc_mk_box2(0,closure4_List_exist1,tmpMeta[0]));
_stateVarCrefs = omc_List_map(threadData, _stateVarLst, boxvar_DAEUtil_varCref);
_variableAttributesOptions = omc_List_map(threadData, _stateVarLst, boxvar_DAEUtil_getVariableAttributes);
_startValuesOpt = omc_List_map(threadData, _variableAttributesOptions, boxvar_StateMachineFlatten_getStartAttrOption);
_varCrefStartVal = omc_List_zip(threadData, _stateVarCrefs, _startValuesOpt);
_crToExpOpt = omc_HashTableCrToExpOption_emptyHashTableSized(threadData, ((modelica_integer) 1) + listLength(_varCrefStartVal));
_crToExpOpt = omc_List_fold(threadData, _varCrefStartVal, boxvar_BaseHashTable_add, _crToExpOpt);
tmpMeta[0] = omc_List_fold3(threadData, _equationLst1, boxvar_StateMachineFlatten_addStateActivationAndReset, _inSMComp, _inEnclosingFlatSmSemantics, _crToExpOpt, _OMC_LIT127);
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_equationLst2 = tmpMeta[1];
_varLst2 = tmpMeta[2];
_flatSmLst = omc_List_extractOnTrue(threadData, _otherLst2, boxvar_StateMachineFlatten_isFlatSm ,&_otherLst3);
tmpMeta[0] = mmc_mk_cons(_outElems, mmc_mk_cons(_varLst1, mmc_mk_cons(_varLst2, mmc_mk_cons(_equationLst2, mmc_mk_cons(_otherLst3, MMC_REFSTRUCTLIT(mmc_nil))))));
_outElems = omc_List_flatten(threadData, tmpMeta[0]);
_outElems = omc_List_fold2(threadData, _flatSmLst, boxvar_StateMachineFlatten_flatSmToDataFlow, mmc_mk_some(_componentRef), mmc_mk_some(_inEnclosingFlatSmSemantics), _outElems);
_return: OMC_LABEL_UNUSED
return _outElems;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_traversingSubsXInState(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inXSubstHit, modelica_boolean *out_cont, modelica_metatype *out_outXSubstHit)
{
modelica_metatype _outExp = NULL;
modelica_boolean _cont;
modelica_metatype _outXSubstHit = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_name = tmpMeta[3];
_xInState = tmpMeta[4];
_subsExp = tmpMeta[5];
if (!(stringEqual(_name, _xInState))) goto tmp3_end;
tmpMeta[2] = mmc_mk_box3(0, _xInState, _subsExp, mmc_mk_boolean(1));
tmpMeta[0+0] = _subsExp;
tmpMeta[0+1] = tmpMeta[2];
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
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _initialStateComp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],29,2) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_crefInitialState = tmpMeta[1];
_preRef = omc_ComponentReference_crefPrefixString(threadData, _OMC_LIT4, _crefInitialState);
tmpMeta[1] = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_nTransitions));
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT7, tmpMeta[0]);
_tArrayBool = tmpMeta[2];
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[2] = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta[1]);
tmpMeta[0] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
_cref = omc_StateMachineFlatten_qCref(threadData, _OMC_LIT23, _tArrayBool, tmpMeta[0], _preRef);
tmpMeta[0] = _inSmeqs;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],3,3) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
_lhsExp = tmpMeta[1];
_rhsExp = tmpMeta[2];
_elemSource = tmpMeta[3];
tmpMeta[0] = _lhsExp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],6,2) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_lhsRef = tmpMeta[1];
_ty = tmpMeta[2];
if(omc_ComponentReference_crefEqual(threadData, _cref, _lhsRef))
{
tmpMeta[0] = mmc_mk_box3(0, _xInState, _substExp, mmc_mk_boolean(0));
_rhsExp2 = omc_Expression_traverseExpTopDown(threadData, _rhsExp, boxvar_StateMachineFlatten_traversingSubsXInState, tmpMeta[0], NULL);
}
else
{
_rhsExp2 = _rhsExp;
}
tmpMeta[0] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _lhsExp, _rhsExp2, _elemSource);
_outSmeqs = tmpMeta[0];
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
modelica_metatype _cElab = NULL;
modelica_metatype _smeqsElab = NULL;
modelica_string _ident = NULL;
modelica_metatype _smComps = NULL;
modelica_metatype _t = NULL;
modelica_metatype _c = NULL;
modelica_metatype _smvars = NULL;
modelica_metatype _smknowns = NULL;
modelica_metatype _smeqs = NULL;
modelica_metatype _pvars = NULL;
modelica_metatype _peqs = NULL;
modelica_metatype _enclosingStateOption = NULL;
modelica_integer _from;
modelica_integer _to;
modelica_metatype _condition = NULL;
modelica_boolean _immediate;
modelica_boolean _reset;
modelica_boolean _synchronize;
modelica_integer _priority;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer tmp7;
modelica_integer tmp8;
modelica_metatype tmpMeta[16] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_tElab = tmpMeta[0];
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_cElab = tmpMeta[1];
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_smeqsElab = tmpMeta[2];
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
_pvars = tmpMeta[3];
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
_peqs = tmpMeta[4];
tmpMeta[5] = _inFlatSmSemantics;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 4));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 5));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 6));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 7));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 8));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 9));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 10));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 11));
_ident = tmpMeta[6];
_smComps = tmpMeta[7];
_t = tmpMeta[8];
_c = tmpMeta[9];
_smvars = tmpMeta[10];
_smknowns = tmpMeta[11];
_smeqs = tmpMeta[12];
_pvars = tmpMeta[13];
_peqs = tmpMeta[14];
_enclosingStateOption = tmpMeta[15];
_i = ((modelica_integer) 0);
{
modelica_metatype _tc;
for (tmpMeta[5] = omc_List_zip(threadData, _t, _c); !listEmpty(tmpMeta[5]); tmpMeta[5]=MMC_CDR(tmpMeta[5]))
{
_tc = MMC_CAR(tmpMeta[5]);
_i = ((modelica_integer) 1) + _i;
tmpMeta[6] = _tc;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 1));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
_t2 = tmpMeta[7];
_c2 = tmpMeta[8];
tmpMeta[6] = _t2;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
tmp1 = mmc_unbox_integer(tmpMeta[7]);
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 3));
tmp2 = mmc_unbox_integer(tmpMeta[8]);
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 4));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 5));
tmp3 = mmc_unbox_integer(tmpMeta[10]);
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 6));
tmp4 = mmc_unbox_integer(tmpMeta[11]);
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 7));
tmp5 = mmc_unbox_integer(tmpMeta[12]);
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 8));
tmp6 = mmc_unbox_integer(tmpMeta[13]);
_from = tmp1;
_to = tmp2;
_condition = tmpMeta[9];
_immediate = tmp3;
_reset = tmp4;
_synchronize = tmp5;
_priority = tmp6;
tmpMeta[6] = arrayGet(_smComps, _from);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],29,2) == 0) MMC_THROW_INTERNAL();
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
_stateRef = tmpMeta[7];
tmpMeta[6] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[7] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT88, _OMC_LIT52, tmpMeta[6], _stateRef), _OMC_LIT52);
_substTickExp = tmpMeta[7];
tmpMeta[8] = mmc_mk_box3(0, _OMC_LIT129, _substTickExp, mmc_mk_boolean(0));
tmpMeta[9] = omc_Expression_traverseExpTopDown(threadData, _c2, boxvar_StateMachineFlatten_traversingSubsXInState, tmpMeta[8], &tmpMeta[6]);
_c3 = tmpMeta[9];
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 3));
tmp7 = mmc_unbox_integer(tmpMeta[7]);
_found = tmp7;
if((_found && isSome(_inEnclosingStateCrefOption)))
{
omc_Error_addCompilerError(threadData, _OMC_LIT130);
MMC_THROW_INTERNAL();
}
_smeqsElab = (_found?omc_List_map5(threadData, _smeqs, boxvar_StateMachineFlatten_smeqsSubsXInState, arrayGet(_smComps, ((modelica_integer) 1)), mmc_mk_integer(_i), mmc_mk_integer(listLength(_t)), _substTickExp, _OMC_LIT129):_smeqs);
_smeqs = _smeqsElab;
tmpMeta[6] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[7] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_StateMachineFlatten_qCref(threadData, _OMC_LIT103, _OMC_LIT91, tmpMeta[6], _stateRef), _OMC_LIT91);
_substTimeExp = tmpMeta[7];
tmpMeta[8] = mmc_mk_box3(0, _OMC_LIT131, _substTimeExp, mmc_mk_boolean(0));
tmpMeta[9] = omc_Expression_traverseExpTopDown(threadData, _c2, boxvar_StateMachineFlatten_traversingSubsXInState, tmpMeta[8], &tmpMeta[6]);
_c4 = tmpMeta[9];
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 3));
tmp8 = mmc_unbox_integer(tmpMeta[7]);
_found = tmp8;
if((_found && isSome(_inEnclosingStateCrefOption)))
{
omc_Error_addCompilerError(threadData, _OMC_LIT132);
MMC_THROW_INTERNAL();
}
_smeqsElab = (_found?omc_List_map5(threadData, _smeqs, boxvar_StateMachineFlatten_smeqsSubsXInState, arrayGet(_smComps, ((modelica_integer) 1)), mmc_mk_integer(_i), mmc_mk_integer(listLength(_t)), _substTimeExp, _OMC_LIT131):_smeqs);
_smeqs = _smeqsElab;
tmpMeta[7] = mmc_mk_box8(3, &StateMachineFlatten_Transition_TRANSITION__desc, mmc_mk_integer(_from), mmc_mk_integer(_to), _c4, mmc_mk_boolean(_immediate), mmc_mk_boolean(_reset), mmc_mk_boolean(_synchronize), mmc_mk_integer(_priority));
tmpMeta[6] = mmc_mk_cons(tmpMeta[7], _tElab);
_tElab = tmpMeta[6];
tmpMeta[6] = mmc_mk_cons(_c4, _cElab);
_cElab = tmpMeta[6];
}
}
tmpMeta[5] = mmc_mk_box11(3, &StateMachineFlatten_FlatSmSemantics_FLAT__SM__SEMANTICS__desc, _ident, _smComps, listReverse(_tElab), listReverse(_cElab), _smvars, _smknowns, _smeqsElab, _pvars, _peqs, _enclosingStateOption);
_outFlatSmSemantics = tmpMeta[5];
_return: OMC_LABEL_UNUSED
return _outFlatSmSemantics;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_traversingSubsTicksInState(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inCref_HitCount, modelica_metatype *out_outCref_HitCount)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outCref_HitCount = NULL;
modelica_metatype _cref = NULL;
modelica_integer _hitCount;
modelica_integer tmp1;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inCref_HitCount;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp1 = mmc_unbox_integer(tmpMeta[2]);
_cref = tmpMeta[1];
_hitCount = tmp1;
{
modelica_metatype tmp5_1;
tmp5_1 = _inExp;
{
modelica_metatype _ty = NULL;
modelica_metatype _crefTicksInState = NULL;
volatile mmc_switch_type tmp5;
int tmp6;
tmp5 = 0;
for (; tmp5 < 2; tmp5++) {
switch (MMC_SWITCH_CAST(tmp5)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,13,3) == 0) goto tmp4_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp4_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (12 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT129), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp4_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 3));
if (!listEmpty(tmpMeta[4])) goto tmp4_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
_ty = tmpMeta[6];
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[3] = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _OMC_LIT88, _ty, tmpMeta[2]);
_crefTicksInState = omc_ComponentReference_joinCrefs(threadData, _cref, tmpMeta[3]);
tmpMeta[2] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _crefTicksInState, _ty);
tmpMeta[3] = mmc_mk_box2(0, _cref, mmc_mk_integer(((modelica_integer) 1) + _hitCount));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = tmpMeta[3];
goto tmp4_done;
}
case 1: {
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inCref_HitCount;
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
modelica_integer tmp1;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_nOfHits = ((modelica_integer) 0);
tmpMeta[0] = _inSmComp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],29,2) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_componentRef = tmpMeta[1];
_dAElist1 = tmpMeta[2];
_emptyTree = _OMC_LIT133;
tmpMeta[3] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _dAElist1);
tmpMeta[4] = mmc_mk_box2(0, _componentRef, mmc_mk_integer(((modelica_integer) 0)));
tmpMeta[5] = mmc_mk_box2(0, boxvar_StateMachineFlatten_traversingSubsTicksInState, tmpMeta[4]);
tmpMeta[6] = omc_DAEUtil_traverseDAE(threadData, tmpMeta[3], _emptyTree, boxvar_Expression_traverseSubexpressionsHelper, tmpMeta[5], NULL, &tmpMeta[0]);
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
_dAElist2 = tmpMeta[7];
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp1 = mmc_unbox_integer(tmpMeta[2]);
_nOfHits = tmp1;
tmpMeta[0] = mmc_mk_box3(32, &DAE_Element_SM__COMP__desc, _componentRef, _dAElist2);
_outSmComp = tmpMeta[0];
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
static int tmp1 = 0;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outElems = _accElems;
tmpMeta[0] = _inFlatSm;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],28,2) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_ident = tmpMeta[1];
_dAElist = tmpMeta[2];
_smCompsLst = omc_List_extractOnTrue(threadData, _dAElist, boxvar_StateMachineFlatten_isSMComp ,&_otherLst1);
_transitionLst = omc_List_extractOnTrue(threadData, _otherLst1, boxvar_StateMachineFlatten_isTransition ,&_otherLst2);
tmpMeta[1] = omc_List_extractOnTrue(threadData, _otherLst2, boxvar_StateMachineFlatten_isInitialState, &tmpMeta[0]);
if (listEmpty(tmpMeta[1])) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (!listEmpty(tmpMeta[3])) MMC_THROW_INTERNAL();
_initialStateOp = tmpMeta[2];
_otherLst3 = tmpMeta[0];
_eqnLst = omc_List_extractOnTrue(threadData, _otherLst3, boxvar_StateMachineFlatten_isEquation ,&_otherLst4);
{
if(!(listLength(_otherLst4) == ((modelica_integer) 0)))
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/FrontEnd/StateMachineFlatten.mo",197,3,197,108,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT134));
}
}
}
tmpMeta[0] = _initialStateOp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],24,2) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],13,3) == 0) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) MMC_THROW_INTERNAL();
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (12 != MMC_STRLEN(tmpMeta[3]) || strcmp("initialState", MMC_STRINGDATA(tmpMeta[3])) != 0) MMC_THROW_INTERNAL();
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (listEmpty(tmpMeta[4])) MMC_THROW_INTERNAL();
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],6,2) == 0) MMC_THROW_INTERNAL();
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
if (!listEmpty(tmpMeta[6])) MMC_THROW_INTERNAL();
_crefInitialState = tmpMeta[7];
tmpMeta[1] = omc_List_extract1OnTrue(threadData, _smCompsLst, boxvar_StateMachineFlatten_sMCompEqualsRef, _crefInitialState, &tmpMeta[0]);
if (listEmpty(tmpMeta[1])) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (!listEmpty(tmpMeta[3])) MMC_THROW_INTERNAL();
_initialStateComp = tmpMeta[2];
_smCompsLst2 = tmpMeta[0];
tmpMeta[0] = mmc_mk_cons(_initialStateComp, _smCompsLst2);
_flatSmSemanticsBasics = omc_StateMachineFlatten_basicFlatSmSemantics(threadData, _ident, tmpMeta[0], _transitionLst);
_flatSmSemanticsWithPropagation = omc_StateMachineFlatten_addPropagationEquations(threadData, _flatSmSemanticsBasics, _inEnclosingStateCrefOption, _inEnclosingFlatSmSemanticsOption);
_flatSmSemantics = omc_StateMachineFlatten_elabXInStateOps(threadData, _flatSmSemanticsWithPropagation, _inEnclosingStateCrefOption);
if(omc_Flags_getConfigBool(threadData, _OMC_LIT28))
{
_smCompsLst = omc_List_map(threadData, _smCompsLst, boxvar_StateMachineFlatten_elabXInStateOps__CT);
}
tmpMeta[0] = _flatSmSemantics;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 8));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 9));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 10));
_vars = tmpMeta[1];
_knowns = tmpMeta[2];
_eqs = tmpMeta[3];
_pvars = tmpMeta[4];
_peqs = tmpMeta[5];
tmpMeta[0] = mmc_mk_cons(_outElems, mmc_mk_cons(_eqnLst, mmc_mk_cons(_vars, mmc_mk_cons(_knowns, mmc_mk_cons(_eqs, mmc_mk_cons(_pvars, mmc_mk_cons(_peqs, MMC_REFSTRUCTLIT(mmc_nil))))))));
_outElems = omc_List_flatten(threadData, tmpMeta[0]);
_outElems = omc_List_fold1(threadData, _smCompsLst, boxvar_StateMachineFlatten_smCompToDataFlow, _flatSmSemantics, _outElems);
_return: OMC_LABEL_UNUSED
return _outElems;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_StateMachineFlatten_traversingSubsActiveState(threadData_t *threadData, modelica_metatype _inExp, modelica_integer _inHitCount, modelica_integer *out_outHitCount)
{
modelica_metatype _outExp = NULL;
modelica_integer _outHitCount;
modelica_integer tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (11 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT68), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta[4])) goto tmp3_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],6,2) == 0) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
if (!listEmpty(tmpMeta[6])) goto tmp3_end;
_componentRef = tmpMeta[7];
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[3] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_ComponentReference_crefPrependIdent(threadData, _componentRef, _OMC_LIT63, tmpMeta[2], _OMC_LIT7), _OMC_LIT7);
tmpMeta[0+0] = tmpMeta[3];
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
static int tmp1 = 0;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inDAElist;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_elementLst = tmpMeta[1];
{
if(!(listLength(_elementLst) == ((modelica_integer) 1)))
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/FrontEnd/StateMachineFlatten.mo",115,3,115,110,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT135));
}
}
}
tmpMeta[0] = listHead(_elementLst);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],17,4) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
_ident = tmpMeta[1];
_dAElist = tmpMeta[2];
_source = tmpMeta[3];
_comment = tmpMeta[4];
if((!omc_List_exist(threadData, _dAElist, boxvar_StateMachineFlatten_isFlatSm)))
{
_outDAElist = _inDAElist;
goto _return;
}
_flatSmLst = omc_List_extractOnTrue(threadData, _dAElist, boxvar_StateMachineFlatten_isFlatSm ,&_otherLst);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_elementLst2 = omc_List_fold2(threadData, _flatSmLst, boxvar_StateMachineFlatten_flatSmToDataFlow, mmc_mk_none(), mmc_mk_none(), tmpMeta[0]);
if(omc_Flags_getConfigBool(threadData, _OMC_LIT28))
{
_elementLst2 = omc_StateMachineFlatten_wrapHack(threadData, _cache, _elementLst2);
}
_elementLst3 = listAppend(_otherLst, _elementLst2);
tmpMeta[1] = mmc_mk_box5(20, &DAE_Element_COMP__desc, _ident, _elementLst3, _source, _comment);
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta[0]);
_outDAElist = tmpMeta[2];
tmpMeta[2] = mmc_mk_box2(0, boxvar_StateMachineFlatten_traversingSubsActiveState, mmc_mk_integer(((modelica_integer) 0)));
tmpMeta[3] = omc_DAEUtil_traverseDAE(threadData, _outDAElist, omc_FCore_getFunctionTree(threadData, _cache), boxvar_Expression_traverseSubexpressionsHelper, tmpMeta[2], NULL, &tmpMeta[0]);
_outDAElist = tmpMeta[3];
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp2 = mmc_unbox_integer(tmpMeta[1]);
_nOfSubstitutions = tmp2;
if(omc_Flags_getConfigBool(threadData, _OMC_LIT28))
{
tmpMeta[2] = mmc_mk_box2(0, boxvar_StateMachineFlatten_traversingSubsPreForPrevious, mmc_mk_integer(((modelica_integer) 0)));
tmpMeta[3] = omc_DAEUtil_traverseDAE(threadData, _outDAElist, omc_FCore_getFunctionTree(threadData, _cache), boxvar_Expression_traverseSubexpressionsHelper, tmpMeta[2], NULL, &tmpMeta[0]);
_outDAElist = tmpMeta[3];
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp3 = mmc_unbox_integer(tmpMeta[1]);
_nOfSubstitutions = tmp3;
}
_return: OMC_LABEL_UNUSED
return _outDAElist;
}
