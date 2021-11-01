#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "InstBinding.c"
#endif
#include "omc_simulation_settings.h"
#include "InstBinding.h"
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT0,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT0 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "Type mismatch in binding %s = %s, expected subtype of %s, got type %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,70,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT2}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(135)),_OMC_LIT0,_OMC_LIT1,_OMC_LIT3}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,2,14) {&Values_Value_OPTION__desc,MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,0,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,1,3) {&DAE_InlineType_NORM__INLINE__desc,}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT8,1,3) {&DAE_TailCall_NO__TAIL__desc,}};
#define _OMC_LIT8 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,1,3) {&DAE_Const_C__CONST__desc,}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,1,5) {&DAE_BindingSource_BINDING__FROM__RECORD__SUBMODS__desc,}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "- Inst.makeRecordBinding2 failed for "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,37,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,1,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,1,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data "failtrace"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,9,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data "Sets whether to print a failtrace or not."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,41,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT16,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT15}};
#define _OMC_LIT16 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT16)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT17,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT14,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT16}};
#define _OMC_LIT17 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT18,1,3) {&DAE_Binding_UNBOUND__desc,}};
#define _OMC_LIT18 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT18)
#define _OMC_LIT19_data "start"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT19,5,_OMC_LIT19_data);
#define _OMC_LIT19 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT19)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT20,1,4) {&DAE_BindingSource_BINDING__FROM__START__VALUE__desc,}};
#define _OMC_LIT20 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT20)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT21,1,3) {&DAE_BindingSource_BINDING__FROM__DEFAULT__VALUE__desc,}};
#define _OMC_LIT21 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,1,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
#define _OMC_LIT23_data "Type mismatch in modifier of component %s, expected type %s, got modifier %s of type %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT23,88,_OMC_LIT23_data);
#define _OMC_LIT23 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT23)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT24,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT23}};
#define _OMC_LIT24 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT24)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT25,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(88)),_OMC_LIT0,_OMC_LIT1,_OMC_LIT24}};
#define _OMC_LIT25 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "- Inst.makeBinding failed on component:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,39,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT27,2,3) {&DAE_DAElist_DAE__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT27 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT27)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT28,3,3) {&SCode_Comment_COMMENT__desc,MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT28 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT28)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT29,1,5) {&DAE_Const_C__VAR__desc,}};
#define _OMC_LIT29 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT29)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT30,1,4) {&SCode_Initial_NON__INITIAL__desc,}};
#define _OMC_LIT30 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data "- InstBinding.instModEquation failed\n type: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,44,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
#define _OMC_LIT32_data "\n  cref: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT32,9,_OMC_LIT32_data);
#define _OMC_LIT32 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT32)
#define _OMC_LIT33_data "\n mod:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT33,6,_OMC_LIT33_data);
#define _OMC_LIT33 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT33)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT34,1,3) {&DAE_Uncertainty_GIVEN__desc,}};
#define _OMC_LIT34 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT34)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT35,1,1) {_OMC_LIT34}};
#define _OMC_LIT35 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT35)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT36,1,4) {&DAE_Uncertainty_SOUGHT__desc,}};
#define _OMC_LIT36 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT36)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT37,1,1) {_OMC_LIT36}};
#define _OMC_LIT37 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT37)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT38,1,5) {&DAE_Uncertainty_REFINE__desc,}};
#define _OMC_LIT38 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT38)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT39,1,1) {_OMC_LIT38}};
#define _OMC_LIT39 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT39)
#define _OMC_LIT40_data "Uncertainty"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT40,11,_OMC_LIT40_data);
#define _OMC_LIT40 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT40)
#define _OMC_LIT41_data "given"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT41,5,_OMC_LIT41_data);
#define _OMC_LIT41 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT41)
#define _OMC_LIT42_data "sought"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT42,6,_OMC_LIT42_data);
#define _OMC_LIT42 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT42)
#define _OMC_LIT43_data "refine"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT43,6,_OMC_LIT43_data);
#define _OMC_LIT43 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT43)
#define _OMC_LIT44_data "Distribution"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT44,12,_OMC_LIT44_data);
#define _OMC_LIT44 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT44)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT45,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT44}};
#define _OMC_LIT45 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT45)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT46,2,6) {&ClassInf_State_RECORD__desc,_OMC_LIT45}};
#define _OMC_LIT46 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT46)
#define _OMC_LIT47_data "name"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT47,4,_OMC_LIT47_data);
#define _OMC_LIT47 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT47)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT48,1,6) {&DAE_ConnectorType_NON__CONNECTOR__desc,}};
#define _OMC_LIT48 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT48)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT49,1,5) {&SCode_Parallelism_NON__PARALLEL__desc,}};
#define _OMC_LIT49 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT49)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT50,1,5) {&SCode_Variability_PARAM__desc,}};
#define _OMC_LIT50 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT50)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT51,1,5) {&Absyn_Direction_BIDIR__desc,}};
#define _OMC_LIT51 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT51)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT52,1,6) {&Absyn_InnerOuter_NOT__INNER__OUTER__desc,}};
#define _OMC_LIT52 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT52)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT53,1,3) {&SCode_Visibility_PUBLIC__desc,}};
#define _OMC_LIT53 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT53)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT54,7,3) {&DAE_Attributes_ATTR__desc,_OMC_LIT48,_OMC_LIT49,_OMC_LIT50,_OMC_LIT51,_OMC_LIT52,_OMC_LIT53}};
#define _OMC_LIT54 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT54)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT55,2,5) {&DAE_Type_T__STRING__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT55 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT55)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT56,7,3) {&DAE_Var_TYPES__VAR__desc,_OMC_LIT47,_OMC_LIT54,_OMC_LIT55,_OMC_LIT18,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT56 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT56)
#define _OMC_LIT57_data "params"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT57,6,_OMC_LIT57_data);
#define _OMC_LIT57 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT57)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT58,2,4) {&DAE_Type_T__REAL__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT58 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT58)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT59,1,7) {&DAE_Dimension_DIM__UNKNOWN__desc,}};
#define _OMC_LIT59 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT59)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT60,2,1) {_OMC_LIT59,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT60 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT60)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT61,3,9) {&DAE_Type_T__ARRAY__desc,_OMC_LIT58,_OMC_LIT60}};
#define _OMC_LIT61 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT61)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT62,7,3) {&DAE_Var_TYPES__VAR__desc,_OMC_LIT57,_OMC_LIT54,_OMC_LIT61,_OMC_LIT18,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT62 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT62)
#define _OMC_LIT63_data "paramNames"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT63,10,_OMC_LIT63_data);
#define _OMC_LIT63 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT63)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT64,3,9) {&DAE_Type_T__ARRAY__desc,_OMC_LIT55,_OMC_LIT60}};
#define _OMC_LIT64 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT64)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT65,7,3) {&DAE_Var_TYPES__VAR__desc,_OMC_LIT63,_OMC_LIT54,_OMC_LIT64,_OMC_LIT18,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT65 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT65)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT66,2,1) {_OMC_LIT65,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT66 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT66)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT67,2,1) {_OMC_LIT62,_OMC_LIT66}};
#define _OMC_LIT67 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT67)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT68,2,1) {_OMC_LIT56,_OMC_LIT67}};
#define _OMC_LIT68 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT68)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT69,4,12) {&DAE_Type_T__COMPLEX__desc,_OMC_LIT46,_OMC_LIT68,MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT69 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT69)
#define _OMC_LIT70_data "Wrong type on %s, expected %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT70,30,_OMC_LIT70_data);
#define _OMC_LIT70 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT70)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT71,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT70}};
#define _OMC_LIT71 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT71)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT72,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(53)),_OMC_LIT0,_OMC_LIT1,_OMC_LIT71}};
#define _OMC_LIT72 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT72)
#define _OMC_LIT73_data "enumeration type"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT73,16,_OMC_LIT73_data);
#define _OMC_LIT73 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT73)
#define _OMC_LIT74_data "quantity"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT74,8,_OMC_LIT74_data);
#define _OMC_LIT74 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT74)
#define _OMC_LIT75_data "unit"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT75,4,_OMC_LIT75_data);
#define _OMC_LIT75 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT75)
#define _OMC_LIT76_data "displayUnit"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT76,11,_OMC_LIT76_data);
#define _OMC_LIT76 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT76)
#define _OMC_LIT77_data "min"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT77,3,_OMC_LIT77_data);
#define _OMC_LIT77 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT77)
#define _OMC_LIT78_data "max"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT78,3,_OMC_LIT78_data);
#define _OMC_LIT78 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT78)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT79,2,6) {&DAE_Type_T__BOOL__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT79 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT79)
#define _OMC_LIT80_data "fixed"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT80,5,_OMC_LIT80_data);
#define _OMC_LIT80 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT80)
#define _OMC_LIT81_data "nominal"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT81,7,_OMC_LIT81_data);
#define _OMC_LIT81 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT81)
#define _OMC_LIT82_data "stateSelect"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT82,11,_OMC_LIT82_data);
#define _OMC_LIT82 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT82)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT83,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT6}};
#define _OMC_LIT83 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT83)
#define _OMC_LIT84_data "never"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT84,5,_OMC_LIT84_data);
#define _OMC_LIT84 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT84)
#define _OMC_LIT85_data "avoid"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT85,5,_OMC_LIT85_data);
#define _OMC_LIT85 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT85)
#define _OMC_LIT86_data "default"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT86,7,_OMC_LIT86_data);
#define _OMC_LIT86 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT86)
#define _OMC_LIT87_data "prefer"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT87,6,_OMC_LIT87_data);
#define _OMC_LIT87 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT87)
#define _OMC_LIT88_data "always"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT88,6,_OMC_LIT88_data);
#define _OMC_LIT88 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT88)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT89,2,1) {_OMC_LIT88,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT89 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT89)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT90,2,1) {_OMC_LIT87,_OMC_LIT89}};
#define _OMC_LIT90 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT90)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT91,2,1) {_OMC_LIT86,_OMC_LIT90}};
#define _OMC_LIT91 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT91)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT92,2,1) {_OMC_LIT85,_OMC_LIT91}};
#define _OMC_LIT92 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT92)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT93,2,1) {_OMC_LIT84,_OMC_LIT92}};
#define _OMC_LIT93 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT93)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT94,1,1) {MMC_IMMEDIATE(MMC_TAGFIXNUM(1))}};
#define _OMC_LIT94 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT94)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT95,6,8) {&DAE_Type_T__ENUMERATION__desc,_OMC_LIT94,_OMC_LIT83,_OMC_LIT93,MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT95 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT95)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT96,7,3) {&DAE_Var_TYPES__VAR__desc,_OMC_LIT84,_OMC_LIT54,_OMC_LIT95,_OMC_LIT18,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT96 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT96)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT97,1,1) {MMC_IMMEDIATE(MMC_TAGFIXNUM(2))}};
#define _OMC_LIT97 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT97)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT98,6,8) {&DAE_Type_T__ENUMERATION__desc,_OMC_LIT97,_OMC_LIT83,_OMC_LIT93,MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT98 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT98)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT99,7,3) {&DAE_Var_TYPES__VAR__desc,_OMC_LIT85,_OMC_LIT54,_OMC_LIT98,_OMC_LIT18,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT99 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT99)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT100,1,1) {MMC_IMMEDIATE(MMC_TAGFIXNUM(3))}};
#define _OMC_LIT100 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT100)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT101,6,8) {&DAE_Type_T__ENUMERATION__desc,_OMC_LIT100,_OMC_LIT83,_OMC_LIT93,MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT101 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT101)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT102,7,3) {&DAE_Var_TYPES__VAR__desc,_OMC_LIT86,_OMC_LIT54,_OMC_LIT101,_OMC_LIT18,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT102 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT102)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT103,1,1) {MMC_IMMEDIATE(MMC_TAGFIXNUM(4))}};
#define _OMC_LIT103 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT103)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT104,6,8) {&DAE_Type_T__ENUMERATION__desc,_OMC_LIT103,_OMC_LIT83,_OMC_LIT93,MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT104 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT104)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT105,7,3) {&DAE_Var_TYPES__VAR__desc,_OMC_LIT87,_OMC_LIT54,_OMC_LIT104,_OMC_LIT18,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT105 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT105)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT106,1,1) {MMC_IMMEDIATE(MMC_TAGFIXNUM(5))}};
#define _OMC_LIT106 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT106)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT107,6,8) {&DAE_Type_T__ENUMERATION__desc,_OMC_LIT106,_OMC_LIT83,_OMC_LIT93,MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT107 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT107)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT108,7,3) {&DAE_Var_TYPES__VAR__desc,_OMC_LIT88,_OMC_LIT54,_OMC_LIT107,_OMC_LIT18,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT108 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT108)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT109,2,1) {_OMC_LIT108,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT109 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT109)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT110,2,1) {_OMC_LIT105,_OMC_LIT109}};
#define _OMC_LIT110 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT110)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT111,2,1) {_OMC_LIT102,_OMC_LIT110}};
#define _OMC_LIT111 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT111)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT112,2,1) {_OMC_LIT99,_OMC_LIT111}};
#define _OMC_LIT112 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT112)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT113,2,1) {_OMC_LIT96,_OMC_LIT112}};
#define _OMC_LIT113 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT113)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT114,6,8) {&DAE_Type_T__ENUMERATION__desc,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT83,_OMC_LIT93,_OMC_LIT113,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT114 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT114)
#define _OMC_LIT115_data "uncertain"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT115,9,_OMC_LIT115_data);
#define _OMC_LIT115 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT115)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT116,2,1) {_OMC_LIT43,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT116 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT116)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT117,2,1) {_OMC_LIT42,_OMC_LIT116}};
#define _OMC_LIT117 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT117)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT118,2,1) {_OMC_LIT41,_OMC_LIT117}};
#define _OMC_LIT118 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT118)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT119,6,8) {&DAE_Type_T__ENUMERATION__desc,_OMC_LIT94,_OMC_LIT83,_OMC_LIT118,MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT119 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT119)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT120,7,3) {&DAE_Var_TYPES__VAR__desc,_OMC_LIT41,_OMC_LIT54,_OMC_LIT119,_OMC_LIT18,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT120 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT120)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT121,6,8) {&DAE_Type_T__ENUMERATION__desc,_OMC_LIT97,_OMC_LIT83,_OMC_LIT118,MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT121 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT121)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT122,7,3) {&DAE_Var_TYPES__VAR__desc,_OMC_LIT42,_OMC_LIT54,_OMC_LIT121,_OMC_LIT18,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT122 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT122)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT123,6,8) {&DAE_Type_T__ENUMERATION__desc,_OMC_LIT100,_OMC_LIT83,_OMC_LIT118,MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT123 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT123)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT124,7,3) {&DAE_Var_TYPES__VAR__desc,_OMC_LIT43,_OMC_LIT54,_OMC_LIT123,_OMC_LIT18,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT124 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT124)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT125,2,1) {_OMC_LIT124,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT125 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT125)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT126,2,1) {_OMC_LIT122,_OMC_LIT125}};
#define _OMC_LIT126 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT126)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT127,2,1) {_OMC_LIT120,_OMC_LIT126}};
#define _OMC_LIT127 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT127)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT128,6,8) {&DAE_Type_T__ENUMERATION__desc,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT83,_OMC_LIT118,_OMC_LIT127,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT128 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT128)
#define _OMC_LIT129_data "distribution"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT129,12,_OMC_LIT129_data);
#define _OMC_LIT129 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT129)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT130,2,3) {&DAE_Type_T__INTEGER__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT130 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT130)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT131,3,6) {&DAE_VariableAttributes_VAR__ATTR__CLOCK__desc,MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT131 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT131)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT132,1,1) {_OMC_LIT131}};
#define _OMC_LIT132 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT132)
#define _OMC_LIT133_data "binding"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT133,7,_OMC_LIT133_data);
#define _OMC_LIT133 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT133)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT134,2,5) {&DAE_Exp_SCONST__desc,_OMC_LIT133}};
#define _OMC_LIT134 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT134)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT135,1,1) {_OMC_LIT134}};
#define _OMC_LIT135 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT135)
#define _OMC_LIT136_data "type"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT136,4,_OMC_LIT136_data);
#define _OMC_LIT136 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT136)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT137,2,5) {&DAE_Exp_SCONST__desc,_OMC_LIT136}};
#define _OMC_LIT137 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT137)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT138,1,1) {_OMC_LIT137}};
#define _OMC_LIT138 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT138)
#include "util/modelica.h"
#include "InstBinding_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstBinding_makeRecordBinding3(threadData_t *threadData, modelica_metatype _inSubMod, modelica_metatype _inType, modelica_metatype _inInfo, modelica_metatype *out_outValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstBinding_makeRecordBinding3,2,0) {(void*) boxptr_InstBinding_makeRecordBinding3,0}};
#define boxvar_InstBinding_makeRecordBinding3 MMC_REFSTRUCTLIT(boxvar_lit_InstBinding_makeRecordBinding3)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstBinding_getUncertainFromExpOption(threadData_t *threadData, modelica_metatype _expOption);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstBinding_getUncertainFromExpOption,2,0) {(void*) boxptr_InstBinding_getUncertainFromExpOption,0}};
#define boxvar_InstBinding_getUncertainFromExpOption MMC_REFSTRUCTLIT(boxvar_lit_InstBinding_getUncertainFromExpOption)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstBinding_instDistributionBinding(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _varLst, modelica_metatype _inIntegerLst, modelica_string _inString, modelica_boolean _useConstValue);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstBinding_instDistributionBinding(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _varLst, modelica_metatype _inIntegerLst, modelica_metatype _inString, modelica_metatype _useConstValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstBinding_instDistributionBinding,2,0) {(void*) boxptr_InstBinding_instDistributionBinding,0}};
#define boxvar_InstBinding_instDistributionBinding MMC_REFSTRUCTLIT(boxvar_lit_InstBinding_instDistributionBinding)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstBinding_instEnumerationBinding(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _varLst, modelica_metatype _inIndices, modelica_string _inName, modelica_metatype _expected_type, modelica_boolean _useConstValue);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstBinding_instEnumerationBinding(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _varLst, modelica_metatype _inIndices, modelica_metatype _inName, modelica_metatype _expected_type, modelica_metatype _useConstValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstBinding_instEnumerationBinding,2,0) {(void*) boxptr_InstBinding_instEnumerationBinding,0}};
#define boxvar_InstBinding_instEnumerationBinding MMC_REFSTRUCTLIT(boxvar_lit_InstBinding_instEnumerationBinding)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstBinding_instStartOrigin(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _inVarLst, modelica_string _inString);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstBinding_instStartOrigin,2,0) {(void*) boxptr_InstBinding_instStartOrigin,0}};
#define boxvar_InstBinding_instStartOrigin MMC_REFSTRUCTLIT(boxvar_lit_InstBinding_instStartOrigin)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstBinding_instBinding2(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _inType, modelica_metatype _inIntegerLst, modelica_string _inString, modelica_boolean _useConstValue);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstBinding_instBinding2(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _inType, modelica_metatype _inIntegerLst, modelica_metatype _inString, modelica_metatype _useConstValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstBinding_instBinding2,2,0) {(void*) boxptr_InstBinding_instBinding2,0}};
#define boxvar_InstBinding_instBinding2 MMC_REFSTRUCTLIT(boxvar_lit_InstBinding_instBinding2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstBinding_instBinding(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _inVarLst, modelica_metatype _inType, modelica_metatype _inIntegerLst, modelica_string _inString, modelica_boolean _useConstValue);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstBinding_instBinding(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _inVarLst, modelica_metatype _inType, modelica_metatype _inIntegerLst, modelica_metatype _inString, modelica_metatype _useConstValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstBinding_instBinding,2,0) {(void*) boxptr_InstBinding_instBinding,0}};
#define boxvar_InstBinding_instBinding MMC_REFSTRUCTLIT(boxvar_lit_InstBinding_instBinding)
DLLExport
modelica_metatype omc_InstBinding_makeVariableBinding(threadData_t *threadData, modelica_metatype _inType, modelica_metatype _inMod, modelica_metatype _inConst, modelica_metatype _inPrefix, modelica_string _inName)
{
jmp_buf *old_mmc_jumper = threadData->mmc_jumper;
modelica_metatype _outBinding = NULL;
modelica_metatype _oeq_mod = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _p = NULL;
modelica_metatype _info = NULL;
modelica_metatype _c = NULL;
modelica_string _e_str = NULL;
modelica_string _et_str = NULL;
modelica_string _bt_str = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_oeq_mod = omc_Mod_modEquation(threadData, _inMod);
if(isNone(_oeq_mod))
{
_outBinding = mmc_mk_none();
goto _return;
}
tmpMeta1 = _oeq_mod;
if (optionNone(tmpMeta1)) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta2,0,5) == 0) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 2));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 4));
_e = tmpMeta3;
_p = tmpMeta4;
if(omc_Types_isExternalObject(threadData, _inType))
{
_outBinding = mmc_mk_some(_e);
}
else
{
if(omc_Types_isEmptyArray(threadData, omc_Types_getPropType(threadData, _p)))
{
_outBinding = mmc_mk_none();
}
else
{
_info = omc_Mod_getModInfo(threadData, _inMod);
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
tmpMeta11 = mmc_mk_box3(3, &DAE_Properties_PROP__desc, _inType, _inConst);
tmpMeta12 = omc_Types_matchProp(threadData, _e, _p, tmpMeta11, 1, &tmpMeta9);
_e2 = tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,0,2) == 0) goto goto_5;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 3));
_c = tmpMeta10;
goto tmp6_done;
}
case 1: {
modelica_metatype tmpMeta13;
_e_str = omc_ExpressionDump_printExpStr(threadData, _e);
_et_str = omc_Types_unparseTypeNoAttr(threadData, _inType);
_bt_str = omc_Types_unparseTypeNoAttr(threadData, omc_Types_getPropType(threadData, _p));
omc_Types_typeErrorSanityCheck(threadData, _et_str, _bt_str, _info);
tmpMeta13 = mmc_mk_cons(_inName, mmc_mk_cons(_e_str, mmc_mk_cons(_et_str, mmc_mk_cons(_bt_str, MMC_REFSTRUCTLIT(mmc_nil)))));
omc_Error_addSourceMessageAndFail(threadData, _OMC_LIT4, tmpMeta13, _info);
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
omc_InstUtil_checkHigherVariability(threadData, _inConst, _c, _inPrefix, _inName, _e, _info);
_outBinding = mmc_mk_some(_e2);
}
}
_return: OMC_LABEL_UNUSED
threadData->mmc_jumper = old_mmc_jumper;
return _outBinding;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstBinding_makeRecordBinding3(threadData_t *threadData, modelica_metatype _inSubMod, modelica_metatype _inType, modelica_metatype _inInfo, modelica_metatype *out_outValue)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outValue = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inSubMod;
{
modelica_metatype _exp = NULL;
modelica_metatype _val = NULL;
modelica_metatype _ty = NULL;
modelica_string _ident = NULL;
modelica_string _binding_str = NULL;
modelica_string _expected_type_str = NULL;
modelica_string _given_type_str = NULL;
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
modelica_metatype tmpMeta13;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,5) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,0) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
if (optionNone(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,0,5) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 3));
if (optionNone(tmpMeta12)) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 1));
_exp = tmpMeta11;
_val = tmpMeta13;
tmp4 += 2;
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = _val;
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
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,0,5) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,1,0) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 5));
if (optionNone(tmpMeta17)) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,0,5) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 3));
if (optionNone(tmpMeta20)) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 1));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta22,0,2) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 2));
_exp = tmpMeta19;
_val = tmpMeta21;
_ty = tmpMeta23;
tmp4 += 1;
_exp = omc_Types_matchType(threadData, _exp, _ty, _inType, 1 ,&_ty);
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = _val;
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
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta25,0,5) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,1,0) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 5));
if (optionNone(tmpMeta27)) goto tmp3_end;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta28,0,5) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta28), 2));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta28), 3));
if (!optionNone(tmpMeta30)) goto tmp3_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta28), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta31,0,2) == 0) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta31), 2));
_exp = tmpMeta29;
_ty = tmpMeta32;
_exp = omc_Types_matchType(threadData, _exp, _ty, _inType, 1 ,&_ty);
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = _OMC_LIT5;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta33), 2));
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta33), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta35,0,5) == 0) goto tmp3_end;
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta35), 5));
if (optionNone(tmpMeta36)) goto tmp3_end;
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta36), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta37,0,5) == 0) goto tmp3_end;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 2));
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta39,0,2) == 0) goto tmp3_end;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 2));
_ident = tmpMeta34;
_exp = tmpMeta38;
_ty = tmpMeta40;
_binding_str = omc_ExpressionDump_printExpStr(threadData, _exp);
_expected_type_str = omc_Types_unparseTypeNoAttr(threadData, _inType);
_given_type_str = omc_Types_unparseTypeNoAttr(threadData, _ty);
omc_Types_typeErrorSanityCheck(threadData, _given_type_str, _expected_type_str, _inInfo);
tmpMeta41 = mmc_mk_cons(_ident, mmc_mk_cons(_binding_str, mmc_mk_cons(_expected_type_str, mmc_mk_cons(_given_type_str, MMC_REFSTRUCTLIT(mmc_nil)))));
omc_Error_addSourceMessage(threadData, _OMC_LIT4, tmpMeta41, _inInfo);
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
_outExp = tmpMeta[0+0];
_outValue = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outValue) { *out_outValue = _outValue; }
return _outExp;
}
DLLExport
modelica_metatype omc_InstBinding_makeRecordBinding(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inRecordName, modelica_metatype _inRecordType, modelica_metatype _inRecordVars, modelica_metatype _inMods, modelica_metatype _inInfo)
{
modelica_metatype _outBinding = NULL;
modelica_metatype _accum_exps = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _accum_vals = NULL;
modelica_metatype tmpMeta2;
modelica_metatype _accum_names = NULL;
modelica_metatype tmpMeta3;
modelica_metatype _mods = NULL;
modelica_metatype _opt_mod = NULL;
modelica_string _name = NULL;
modelica_string _scope = NULL;
modelica_string _ty_str = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _ety = NULL;
modelica_metatype _binding = NULL;
modelica_metatype _dims = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _val = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_accum_exps = tmpMeta1;
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
_accum_vals = tmpMeta2;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
_accum_names = tmpMeta3;
_mods = _inMods;
_name = _OMC_LIT6;
_dims = omc_Types_getDimensions(threadData, _inRecordType);
{
{
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp5_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp6 < 2; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
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
{
modelica_metatype _var;
for (tmpMeta8 = _inRecordVars; !listEmpty(tmpMeta8); tmpMeta8=MMC_CDR(tmpMeta8))
{
_var = MMC_CAR(tmpMeta8);
tmpMeta9 = _var;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 5));
_name = tmpMeta10;
_ty = tmpMeta11;
_binding = tmpMeta12;
_mods = omc_List_deleteMemberOnTrue(threadData, _name, _mods, boxvar_InstUtil_isSubModNamed ,&_opt_mod);
if(isSome(_opt_mod))
{
_ty = omc_Types_liftArrayListDims(threadData, _ty, _dims);
_exp = omc_InstBinding_makeRecordBinding3(threadData, _opt_mod, _ty, _inInfo ,&_val);
}
else
{
if(omc_DAEUtil_isBound(threadData, _binding))
{
tmpMeta13 = _binding;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,1,4) == 0) goto goto_4;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 3));
if (optionNone(tmpMeta15)) goto goto_4;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 1));
_exp = tmpMeta14;
_val = tmpMeta16;
}
else
{
_ety = omc_Types_simplifyType(threadData, _ty);
_ty = omc_Types_liftArrayListDims(threadData, _ty, _dims);
_scope = omc_FGraph_printGraphPathStr(threadData, _inEnv);
_ty_str = omc_Types_printTypeStr(threadData, _ty);
tmpMeta17 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta18 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _name, _ety, tmpMeta17);
tmpMeta19 = mmc_mk_box5(29, &DAE_Exp_EMPTY__desc, _scope, tmpMeta18, _ety, _ty_str);
_exp = tmpMeta19;
tmpMeta20 = mmc_mk_box5(19, &Values_Value_EMPTY__desc, _scope, _name, omc_Types_typeToValue(threadData, _ty), _ty_str);
_val = tmpMeta20;
}
}
tmpMeta21 = mmc_mk_cons(_exp, _accum_exps);
_accum_exps = tmpMeta21;
tmpMeta22 = mmc_mk_cons(_val, _accum_vals);
_accum_vals = tmpMeta22;
tmpMeta23 = mmc_mk_cons(_name, _accum_names);
_accum_names = tmpMeta23;
}
}
_ety = omc_Types_simplifyType(threadData, omc_Types_arrayElementType(threadData, _inRecordType));
tmpMeta25 = mmc_mk_box8(3, &DAE_CallAttributes_CALL__ATTR__desc, _ety, mmc_mk_boolean(0), mmc_mk_boolean(0), mmc_mk_boolean(0), mmc_mk_boolean(0), _OMC_LIT7, _OMC_LIT8);
tmpMeta26 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _inRecordName, listReverse(_accum_exps), tmpMeta25);
_exp = tmpMeta26;
tmpMeta27 = mmc_mk_box5(13, &Values_Value_RECORD__desc, _inRecordName, listReverse(_accum_vals), listReverse(_accum_names), mmc_mk_integer(((modelica_integer) -1)));
_val = tmpMeta27;
_exp = omc_InstUtil_liftRecordBinding(threadData, _inRecordType, _exp, _val ,&_val);
tmpMeta28 = mmc_mk_box5(4, &DAE_Binding_EQBOUND__desc, _exp, mmc_mk_some(_val), _OMC_LIT9, _OMC_LIT10);
_outBinding = tmpMeta28;
goto tmp5_done;
}
case 1: {
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
if(omc_Flags_isSet(threadData, _OMC_LIT17))
{
tmpMeta29 = stringAppend(_OMC_LIT11,omc_AbsynUtil_pathString(threadData, _inRecordName, _OMC_LIT12, 1, 0));
tmpMeta30 = stringAppend(tmpMeta29,_OMC_LIT12);
tmpMeta31 = stringAppend(tmpMeta30,_name);
tmpMeta32 = stringAppend(tmpMeta31,_OMC_LIT13);
omc_Debug_traceln(threadData, tmpMeta32);
}
goto goto_4;
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
if (++tmp6 < 2) {
goto tmp5_top;
}
MMC_THROW_INTERNAL();
tmp5_done2:;
}
}
;
_return: OMC_LABEL_UNUSED
return _outBinding;
}
DLLExport
modelica_metatype omc_InstBinding_makeBinding(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inAttributes, modelica_metatype _inMod, modelica_metatype _inType, modelica_metatype _inPrefix, modelica_string _componentName, modelica_metatype _inInfo, modelica_metatype *out_outBinding)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outBinding = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inAttributes;
tmp4_3 = _inMod;
tmp4_4 = _inType;
{
modelica_metatype _tp = NULL;
modelica_metatype _e_tp = NULL;
modelica_metatype _e_1 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e_val_exp = NULL;
modelica_metatype _e_val = NULL;
modelica_metatype _c = NULL;
modelica_string _e_tp_str = NULL;
modelica_string _tp_str = NULL;
modelica_string _e_str = NULL;
modelica_string _e_str_1 = NULL;
modelica_string _str = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _prop = NULL;
modelica_metatype _binding = NULL;
modelica_metatype _startValueModification = NULL;
modelica_metatype _complex_vars = NULL;
modelica_metatype _tpath = NULL;
modelica_metatype _sub_mods = NULL;
modelica_metatype _info = NULL;
modelica_metatype _v = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 10; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_boolean tmp10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,0) == 0) goto tmp3_end;
_cache = tmp4_1;
tmpMeta6 = omc_Types_arrayElementType(threadData, _inType);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,9,3) == 0) goto goto_2;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,3,1) == 0) goto goto_2;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
_tpath = tmpMeta8;
_complex_vars = tmpMeta9;
tmp10 = omc_Types_allHaveBindings(threadData, _complex_vars);
if (1 != tmp10) goto goto_2;
tmpMeta11 = MMC_REFSTRUCTLIT(mmc_nil);
_binding = omc_InstBinding_makeRecordBinding(threadData, _cache, _inEnv, _tpath, _inType, _complex_vars, tmpMeta11, _inInfo);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _binding;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,0) == 0) goto tmp3_end;
_cache = tmp4_1;
tmp4 += 7;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _OMC_LIT18;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,4) == 0) goto tmp3_end;
tmp4 += 6;
tmpMeta[0+0] = omc_InstBinding_makeBinding(threadData, _inCache, _inEnv, _inAttributes, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inMod), 5))), _inType, _inPrefix, _componentName, _inInfo, &tmpMeta[0+1]);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_boolean tmp14;
modelica_boolean tmp15;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,2,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,5) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 5));
if (!optionNone(tmpMeta13)) goto tmp3_end;
_cache = tmp4_1;
_tp = tmp4_4;
tmp14 = omc_Types_getFixedVarAttributeParameterOrConstant(threadData, _tp);
if (1 != tmp14) goto goto_2;
_startValueModification = omc_Mod_lookupCompModification(threadData, _inMod, _OMC_LIT19);
tmp15 = omc_Mod_isEmptyMod(threadData, _startValueModification);
if (0 != tmp15) goto goto_2;
_cache = omc_InstBinding_makeBinding(threadData, _cache, _inEnv, _inAttributes, _startValueModification, _inType, _inPrefix, _componentName, _inInfo ,&_binding);
_binding = omc_DAEUtil_setBindingSource(threadData, _binding, _OMC_LIT20);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _binding;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,5) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
if (listEmpty(tmpMeta16)) goto tmp3_end;
tmpMeta17 = MMC_CAR(tmpMeta16);
tmpMeta18 = MMC_CDR(tmpMeta16);
_sub_mods = tmpMeta16;
_cache = tmp4_1;
tmpMeta19 = omc_Types_arrayElementType(threadData, _inType);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta19,9,3) == 0) goto goto_2;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,3,1) == 0) goto goto_2;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 2));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 3));
_tpath = tmpMeta21;
_complex_vars = tmpMeta22;
_binding = omc_InstBinding_makeRecordBinding(threadData, _cache, _inEnv, _tpath, _inType, _complex_vars, _sub_mods, _inInfo);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _binding;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,5) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 5));
if (!optionNone(tmpMeta23)) goto tmp3_end;
_cache = tmp4_1;
tmp4 += 3;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _OMC_LIT18;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_boolean tmp30;
modelica_metatype tmpMeta31;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,5) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 5));
if (optionNone(tmpMeta24)) goto tmp3_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta25,0,5) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 2));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 3));
if (optionNone(tmpMeta27)) goto tmp3_end;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 1));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 4));
_e = tmpMeta26;
_v = tmpMeta28;
_prop = tmpMeta29;
_cache = tmp4_1;
_e_tp = tmp4_4;
_c = omc_Types_propAllConst(threadData, _prop);
_tp = omc_Types_getPropType(threadData, _prop);
tmp30 = omc_Types_equivtypes(threadData, _tp, _e_tp);
if (0 != tmp30) goto goto_2;
_e_val_exp = omc_ValuesUtil_valueExp(threadData, _v, mmc_mk_some(_e));
_e_1 = omc_Types_matchType(threadData, _e, _tp, _e_tp, 0, NULL);
_e_1 = omc_ExpressionSimplify_simplify(threadData, _e_1, NULL);
_e_val_exp = omc_Types_matchType(threadData, _e_val_exp, _tp, _e_tp, 0, NULL);
_e_val_exp = omc_ExpressionSimplify_simplify(threadData, _e_val_exp, NULL);
_v = omc_Ceval_cevalSimple(threadData, _e_val_exp);
_e_val = mmc_mk_some(_v);
tmpMeta31 = mmc_mk_box5(4, &DAE_Binding_EQBOUND__desc, _e_1, _e_val, _c, _OMC_LIT21);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta31;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,5) == 0) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 5));
if (optionNone(tmpMeta32)) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta33,0,5) == 0) goto tmp3_end;
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta33), 2));
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta33), 3));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta33), 4));
_e = tmpMeta34;
_e_val = tmpMeta35;
_prop = tmpMeta36;
_cache = tmp4_1;
_e_tp = tmp4_4;
_c = omc_Types_propAllConst(threadData, _prop);
_tp = omc_Types_getPropType(threadData, _prop);
_e_1 = omc_Types_matchType(threadData, _e, _tp, _e_tp, 0, NULL);
_e_1 = omc_ExpressionSimplify_simplify(threadData, _e_1, NULL);
tmpMeta37 = mmc_mk_box5(4, &DAE_Binding_EQBOUND__desc, _e_1, _e_val, _c, _OMC_LIT21);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta37;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
modelica_boolean tmp43;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,5) == 0) goto tmp3_end;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 5));
if (optionNone(tmpMeta38)) goto tmp3_end;
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta38), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta39,0,5) == 0) goto tmp3_end;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 2));
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 4));
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 6));
_e = tmpMeta40;
_prop = tmpMeta41;
_info = tmpMeta42;
_tp = tmp4_4;
_e_tp = omc_Types_getPropType(threadData, _prop);
omc_Types_propAllConst(threadData, _prop);
tmp43 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_Types_matchType(threadData, _e, _e_tp, _tp, 0, NULL);
tmp43 = 1;
goto goto_44;
goto_44:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp43) {goto goto_2;}
_e_tp_str = omc_Types_unparseTypeNoAttr(threadData, _e_tp);
_tp_str = omc_Types_unparseTypeNoAttr(threadData, _tp);
_e_str = omc_ExpressionDump_printExpStr(threadData, _e);
tmpMeta45 = stringAppend(_OMC_LIT22,_e_str);
_e_str_1 = tmpMeta45;
tmpMeta46 = stringAppend(omc_PrefixUtil_printPrefixStrIgnoreNoPre(threadData, _inPrefix),_OMC_LIT12);
tmpMeta47 = stringAppend(tmpMeta46,_componentName);
_str = tmpMeta47;
omc_Types_typeErrorSanityCheck(threadData, _e_tp_str, _tp_str, _info);
tmpMeta48 = mmc_mk_cons(_str, mmc_mk_cons(_tp_str, mmc_mk_cons(_e_str_1, mmc_mk_cons(_e_tp_str, MMC_REFSTRUCTLIT(mmc_nil)))));
omc_Error_addSourceMessage(threadData, _OMC_LIT25, tmpMeta48, _info);
goto goto_2;
goto tmp3_done;
}
case 9: {
modelica_boolean tmp49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
tmp49 = omc_Flags_isSet(threadData, _OMC_LIT17);
if (1 != tmp49) goto goto_2;
tmpMeta50 = stringAppend(_OMC_LIT26,omc_PrefixUtil_printPrefixStr(threadData, _inPrefix));
tmpMeta51 = stringAppend(tmpMeta50,_OMC_LIT12);
tmpMeta52 = stringAppend(tmpMeta51,_componentName);
omc_Debug_traceln(threadData, tmpMeta52);
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
if (++tmp4 < 10) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outCache = tmpMeta[0+0];
_outBinding = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outBinding) { *out_outBinding = _outBinding; }
return _outCache;
}
DLLExport
modelica_metatype omc_InstBinding_instModEquation(threadData_t *threadData, modelica_metatype _inComponentRef, modelica_metatype _inType, modelica_metatype _inMod, modelica_metatype _inSource, modelica_boolean _inImpl)
{
modelica_metatype _outDae = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inType;
tmp4_2 = _inMod;
{
modelica_metatype _t = NULL;
modelica_metatype _e = NULL;
modelica_metatype _lhs = NULL;
modelica_metatype _prop2 = NULL;
modelica_metatype _aexp1 = NULL;
modelica_metatype _aexp2 = NULL;
modelica_metatype _scode = NULL;
modelica_metatype _acr = NULL;
modelica_metatype _info = NULL;
modelica_metatype _source = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 7; tmp4++) {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
if (optionNone(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,5) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
if (optionNone(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 1));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,0,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,0,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT27;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_integer tmp21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,5) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
if (optionNone(tmpMeta13)) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,0,5) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 4));
_prop2 = tmpMeta15;
tmpMeta16 = omc_Types_getPropType(threadData, _prop2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,6,2) == 0) goto goto_2;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 3));
if (listEmpty(tmpMeta17)) goto goto_2;
tmpMeta18 = MMC_CAR(tmpMeta17);
tmpMeta19 = MMC_CDR(tmpMeta17);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,0,1) == 0) goto goto_2;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
tmp21 = mmc_unbox_integer(tmpMeta20);
if (0 != tmp21) goto goto_2;
if (!listEmpty(tmpMeta19)) goto goto_2;
tmpMeta1 = _OMC_LIT27;
goto tmp3_done;
}
case 2: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,5) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
if (optionNone(tmpMeta22)) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta23,0,5) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 2));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 4));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 5));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 6));
_e = tmpMeta24;
_prop2 = tmpMeta25;
_aexp2 = tmpMeta26;
_info = tmpMeta27;
tmp4 += 3;
_t = omc_Types_simplifyType(threadData, _inType);
_lhs = omc_Expression_makeCrefExp(threadData, _inComponentRef, _t);
_acr = omc_ComponentReference_unelabCref(threadData, _inComponentRef);
tmpMeta28 = mmc_mk_box2(5, &Absyn_Exp_CREF__desc, _acr);
_aexp1 = tmpMeta28;
tmpMeta29 = mmc_mk_box5(4, &SCode_EEquation_EQ__EQUALS__desc, _aexp1, _aexp2, _OMC_LIT28, _info);
_scode = tmpMeta29;
tmpMeta30 = mmc_mk_box3(3, &DAE_SymbolicOperation_FLATTEN__desc, _scode, mmc_mk_none());
_source = omc_ElementSource_addSymbolicTransformation(threadData, _inSource, tmpMeta30);
tmpMeta31 = mmc_mk_box3(3, &DAE_Properties_PROP__desc, _inType, _OMC_LIT29);
tmpMeta1 = omc_InstSection_instEqEquation(threadData, _lhs, tmpMeta31, _e, _prop2, _source, _OMC_LIT30, _inImpl, _info);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta32;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,5) == 0) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
if (!optionNone(tmpMeta32)) goto tmp3_end;
tmp4 += 2;
tmpMeta1 = _OMC_LIT27;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,0) == 0) goto tmp3_end;
tmp4 += 1;
tmpMeta1 = _OMC_LIT27;
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,4) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT27;
goto tmp3_done;
}
case 6: {
modelica_boolean tmp33;
tmp33 = omc_Flags_isSet(threadData, _OMC_LIT17);
if (1 != tmp33) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT31);
omc_Debug_trace(threadData, omc_Types_printTypeStr(threadData, _inType));
omc_Debug_trace(threadData, _OMC_LIT32);
omc_Debug_trace(threadData, omc_ComponentReference_printComponentRefStr(threadData, _inComponentRef));
omc_Debug_trace(threadData, _OMC_LIT33);
omc_Debug_traceln(threadData, omc_Mod_printModStr(threadData, _inMod));
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
if (++tmp4 < 7) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outDae = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outDae;
}
modelica_metatype boxptr_InstBinding_instModEquation(threadData_t *threadData, modelica_metatype _inComponentRef, modelica_metatype _inType, modelica_metatype _inMod, modelica_metatype _inSource, modelica_metatype _inImpl)
{
modelica_integer tmp1;
modelica_metatype _outDae = NULL;
tmp1 = mmc_unbox_integer(_inImpl);
_outDae = omc_InstBinding_instModEquation(threadData, _inComponentRef, _inType, _inMod, _inSource, tmp1);
return _outDae;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstBinding_getUncertainFromExpOption(threadData_t *threadData, modelica_metatype _expOption)
{
modelica_metatype _out = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _expOption;
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
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,5,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (11 != MMC_STRLEN(tmpMeta8) || strcmp(MMC_STRINGDATA(_OMC_LIT40), MMC_STRINGDATA(tmpMeta8)) != 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,1,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (5 != MMC_STRLEN(tmpMeta10) || strcmp(MMC_STRINGDATA(_OMC_LIT41), MMC_STRINGDATA(tmpMeta10)) != 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT35;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,5,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,0,2) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
if (11 != MMC_STRLEN(tmpMeta13) || strcmp(MMC_STRINGDATA(_OMC_LIT40), MMC_STRINGDATA(tmpMeta13)) != 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,1,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
if (6 != MMC_STRLEN(tmpMeta15) || strcmp(MMC_STRINGDATA(_OMC_LIT42), MMC_STRINGDATA(tmpMeta15)) != 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT37;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,5,2) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,0,2) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 2));
if (11 != MMC_STRLEN(tmpMeta18) || strcmp(MMC_STRINGDATA(_OMC_LIT40), MMC_STRINGDATA(tmpMeta18)) != 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta19,1,1) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 2));
if (6 != MMC_STRLEN(tmpMeta20) || strcmp(MMC_STRINGDATA(_OMC_LIT43), MMC_STRINGDATA(tmpMeta20)) != 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT39;
goto tmp3_done;
}
case 3: {
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
_out = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _out;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstBinding_instDistributionBinding(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _varLst, modelica_metatype _inIntegerLst, modelica_string _inString, modelica_boolean _useConstValue)
{
modelica_metatype _out = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_string tmp4_3;
tmp4_1 = _inMod;
tmp4_2 = _inIntegerLst;
tmp4_3 = _inString;
{
modelica_metatype _mod = NULL;
modelica_metatype _name = NULL;
modelica_metatype _params = NULL;
modelica_metatype _paramNames = NULL;
modelica_metatype _index_list = NULL;
modelica_string _bind_name = NULL;
modelica_metatype _ty = NULL;
modelica_integer _paramDim;
modelica_metatype _cr = NULL;
modelica_metatype _crName = NULL;
modelica_metatype _crParams = NULL;
modelica_metatype _path = NULL;
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
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_boolean tmp16;
modelica_metatype tmpMeta17;
_mod = tmp4_1;
_index_list = tmp4_2;
_bind_name = tmp4_3;
tmpMeta6 = omc_InstBinding_instBinding(threadData, _mod, _varLst, _OMC_LIT69, _index_list, _bind_name, _useConstValue);
if (optionNone(tmpMeta6)) goto goto_2;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,13,3) == 0) goto goto_2;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
if (listEmpty(tmpMeta9)) goto goto_2;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
if (listEmpty(tmpMeta11)) goto goto_2;
tmpMeta12 = MMC_CAR(tmpMeta11);
tmpMeta13 = MMC_CDR(tmpMeta11);
if (listEmpty(tmpMeta13)) goto goto_2;
tmpMeta14 = MMC_CAR(tmpMeta13);
tmpMeta15 = MMC_CDR(tmpMeta13);
if (!listEmpty(tmpMeta15)) goto goto_2;
_path = tmpMeta8;
_name = tmpMeta10;
_params = tmpMeta12;
_paramNames = tmpMeta14;
tmp16 = omc_AbsynUtil_pathEqual(threadData, _path, _OMC_LIT45);
if (1 != tmp16) goto goto_2;
tmpMeta17 = mmc_mk_box4(3, &DAE_Distribution_DISTRIBUTION__desc, _name, _params, _paramNames);
tmpMeta1 = mmc_mk_some(tmpMeta17);
goto tmp3_done;
}
case 1: {
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
modelica_boolean tmp28;
modelica_metatype tmpMeta29;
_mod = tmp4_1;
_index_list = tmp4_2;
_bind_name = tmp4_3;
tmpMeta18 = omc_InstBinding_instBinding(threadData, _mod, _varLst, _OMC_LIT69, _index_list, _bind_name, _useConstValue);
if (optionNone(tmpMeta18)) goto goto_2;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta19,14,4) == 0) goto goto_2;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 2));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 3));
if (listEmpty(tmpMeta21)) goto goto_2;
tmpMeta22 = MMC_CAR(tmpMeta21);
tmpMeta23 = MMC_CDR(tmpMeta21);
if (listEmpty(tmpMeta23)) goto goto_2;
tmpMeta24 = MMC_CAR(tmpMeta23);
tmpMeta25 = MMC_CDR(tmpMeta23);
if (listEmpty(tmpMeta25)) goto goto_2;
tmpMeta26 = MMC_CAR(tmpMeta25);
tmpMeta27 = MMC_CDR(tmpMeta25);
if (!listEmpty(tmpMeta27)) goto goto_2;
_path = tmpMeta20;
_name = tmpMeta22;
_params = tmpMeta24;
_paramNames = tmpMeta26;
tmp28 = omc_AbsynUtil_pathEqual(threadData, _path, _OMC_LIT45);
if (1 != tmp28) goto goto_2;
tmpMeta29 = mmc_mk_box4(3, &DAE_Distribution_DISTRIBUTION__desc, _name, _params, _paramNames);
tmpMeta1 = mmc_mk_some(tmpMeta29);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_boolean tmp34;
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
modelica_integer tmp46;
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
_mod = tmp4_1;
_index_list = tmp4_2;
_bind_name = tmp4_3;
tmpMeta30 = omc_InstBinding_instBinding(threadData, _mod, _varLst, _OMC_LIT69, _index_list, _bind_name, _useConstValue);
if (optionNone(tmpMeta30)) goto goto_2;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta31,6,2) == 0) goto goto_2;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta31), 2));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta31), 3));
_cr = tmpMeta32;
_ty = tmpMeta33;
tmp34 = omc_Types_isRecord(threadData, _ty);
if (1 != tmp34) goto goto_2;
tmpMeta35 = _ty;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta35,9,3) == 0) goto goto_2;
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta35), 3));
if (listEmpty(tmpMeta36)) goto goto_2;
tmpMeta37 = MMC_CAR(tmpMeta36);
tmpMeta38 = MMC_CDR(tmpMeta36);
if (listEmpty(tmpMeta38)) goto goto_2;
tmpMeta39 = MMC_CAR(tmpMeta38);
tmpMeta40 = MMC_CDR(tmpMeta38);
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta41,6,2) == 0) goto goto_2;
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 3));
if (listEmpty(tmpMeta42)) goto goto_2;
tmpMeta43 = MMC_CAR(tmpMeta42);
tmpMeta44 = MMC_CDR(tmpMeta42);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta43,0,1) == 0) goto goto_2;
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta43), 2));
tmp46 = mmc_unbox_integer(tmpMeta45);
if (!listEmpty(tmpMeta44)) goto goto_2;
_paramDim = tmp46;
tmpMeta47 = MMC_REFSTRUCTLIT(mmc_nil);
_crName = omc_ComponentReference_crefPrependIdent(threadData, _cr, _OMC_LIT47, tmpMeta47, _OMC_LIT55);
tmpMeta48 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta50 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_paramDim));
tmpMeta49 = mmc_mk_cons(tmpMeta50, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta51 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT58, tmpMeta49);
_crParams = omc_ComponentReference_crefPrependIdent(threadData, _cr, _OMC_LIT57, tmpMeta48, tmpMeta51);
_name = omc_Expression_makeCrefExp(threadData, _crName, _OMC_LIT55);
tmpMeta53 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_paramDim));
tmpMeta52 = mmc_mk_cons(tmpMeta53, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta54 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT58, tmpMeta52);
_params = omc_Expression_makeCrefExp(threadData, _crParams, tmpMeta54);
tmpMeta56 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_paramDim));
tmpMeta55 = mmc_mk_cons(tmpMeta56, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta57 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT55, tmpMeta55);
_paramNames = omc_Expression_makeCrefExp(threadData, _crParams, tmpMeta57);
tmpMeta58 = mmc_mk_box4(3, &DAE_Distribution_DISTRIBUTION__desc, _name, _params, _paramNames);
tmpMeta1 = mmc_mk_some(tmpMeta58);
goto tmp3_done;
}
case 3: {
tmpMeta1 = mmc_mk_none();
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
_out = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _out;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstBinding_instDistributionBinding(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _varLst, modelica_metatype _inIntegerLst, modelica_metatype _inString, modelica_metatype _useConstValue)
{
modelica_integer tmp1;
modelica_metatype _out = NULL;
tmp1 = mmc_unbox_integer(_useConstValue);
_out = omc_InstBinding_instDistributionBinding(threadData, _inMod, _varLst, _inIntegerLst, _inString, tmp1);
return _out;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstBinding_instEnumerationBinding(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _varLst, modelica_metatype _inIndices, modelica_string _inName, modelica_metatype _expected_type, modelica_boolean _useConstValue)
{
modelica_metatype _outBinding = NULL;
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
_outBinding = omc_InstBinding_instBinding(threadData, _inMod, _varLst, _expected_type, _inIndices, _inName, _useConstValue);
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta5;
tmpMeta5 = mmc_mk_cons(_inName, mmc_mk_cons(_OMC_LIT73, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addMessage(threadData, _OMC_LIT72, tmpMeta5);
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
return _outBinding;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstBinding_instEnumerationBinding(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _varLst, modelica_metatype _inIndices, modelica_metatype _inName, modelica_metatype _expected_type, modelica_metatype _useConstValue)
{
modelica_integer tmp1;
modelica_metatype _outBinding = NULL;
tmp1 = mmc_unbox_integer(_useConstValue);
_outBinding = omc_InstBinding_instEnumerationBinding(threadData, _inMod, _varLst, _inIndices, _inName, _expected_type, tmp1);
return _outBinding;
}
DLLExport
modelica_metatype omc_InstBinding_instDaeVariableAttributes(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inMod, modelica_metatype _inType, modelica_metatype _inIntegerLst, modelica_metatype *out_outDAEVariableAttributesOption)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outDAEVariableAttributesOption = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inMod;
tmp4_3 = _inType;
tmp4_4 = _inIntegerLst;
{
modelica_metatype _quantity_str = NULL;
modelica_metatype _unit_str = NULL;
modelica_metatype _displayunit_str = NULL;
modelica_metatype _nominal_val = NULL;
modelica_metatype _fixed_val = NULL;
modelica_metatype _exp_bind_select = NULL;
modelica_metatype _exp_bind_uncertainty = NULL;
modelica_metatype _exp_bind_min = NULL;
modelica_metatype _exp_bind_max = NULL;
modelica_metatype _exp_bind_start = NULL;
modelica_metatype _min_val = NULL;
modelica_metatype _max_val = NULL;
modelica_metatype _start_val = NULL;
modelica_metatype _startOrigin = NULL;
modelica_metatype _stateSelect_value = NULL;
modelica_metatype _uncertainty_value = NULL;
modelica_metatype _distribution_value = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _index_list = NULL;
modelica_metatype _enumtype = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _varLst = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 7; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
_varLst = tmpMeta6;
_cache = tmp4_1;
_mod = tmp4_2;
_index_list = tmp4_4;
tmp4 += 5;
_quantity_str = omc_InstBinding_instBinding(threadData, _mod, _varLst, _OMC_LIT55, _index_list, _OMC_LIT74, 0);
_unit_str = omc_InstBinding_instBinding(threadData, _mod, _varLst, _OMC_LIT55, _index_list, _OMC_LIT75, 0);
_displayunit_str = omc_InstBinding_instBinding(threadData, _mod, _varLst, _OMC_LIT55, _index_list, _OMC_LIT76, 0);
_min_val = omc_InstBinding_instBinding(threadData, _mod, _varLst, _OMC_LIT58, _index_list, _OMC_LIT77, 0);
_max_val = omc_InstBinding_instBinding(threadData, _mod, _varLst, _OMC_LIT58, _index_list, _OMC_LIT78, 0);
_start_val = omc_InstBinding_instBinding(threadData, _mod, _varLst, _OMC_LIT58, _index_list, _OMC_LIT19, 0);
_fixed_val = omc_InstBinding_instBinding(threadData, _mod, _varLst, _OMC_LIT79, _index_list, _OMC_LIT80, 1);
_nominal_val = omc_InstBinding_instBinding(threadData, _mod, _varLst, _OMC_LIT58, _index_list, _OMC_LIT81, 0);
_exp_bind_select = omc_InstBinding_instEnumerationBinding(threadData, _mod, _varLst, _index_list, _OMC_LIT82, _OMC_LIT114, 1);
_stateSelect_value = omc_InstUtil_getStateSelectFromExpOption(threadData, _exp_bind_select);
_exp_bind_uncertainty = omc_InstBinding_instEnumerationBinding(threadData, _mod, _varLst, _index_list, _OMC_LIT115, _OMC_LIT128, 1);
_uncertainty_value = omc_InstBinding_getUncertainFromExpOption(threadData, _exp_bind_uncertainty);
_distribution_value = omc_InstBinding_instDistributionBinding(threadData, _mod, _varLst, _index_list, _OMC_LIT129, 0);
_startOrigin = omc_InstBinding_instStartOrigin(threadData, _mod, _varLst, _OMC_LIT19);
tmpMeta7 = mmc_mk_box16(3, &DAE_VariableAttributes_VAR__ATTR__REAL__desc, _quantity_str, _unit_str, _displayunit_str, _min_val, _max_val, _start_val, _fixed_val, _nominal_val, _stateSelect_value, _uncertainty_value, _distribution_value, mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), _startOrigin);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = mmc_mk_some(tmpMeta7);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
_varLst = tmpMeta8;
_cache = tmp4_1;
_mod = tmp4_2;
_index_list = tmp4_4;
tmp4 += 4;
_quantity_str = omc_InstBinding_instBinding(threadData, _mod, _varLst, _OMC_LIT55, _index_list, _OMC_LIT74, 0);
_min_val = omc_InstBinding_instBinding(threadData, _mod, _varLst, _OMC_LIT130, _index_list, _OMC_LIT77, 0);
_max_val = omc_InstBinding_instBinding(threadData, _mod, _varLst, _OMC_LIT130, _index_list, _OMC_LIT78, 0);
_start_val = omc_InstBinding_instBinding(threadData, _mod, _varLst, _OMC_LIT130, _index_list, _OMC_LIT19, 0);
_fixed_val = omc_InstBinding_instBinding(threadData, _mod, _varLst, _OMC_LIT79, _index_list, _OMC_LIT80, 1);
_exp_bind_uncertainty = omc_InstBinding_instEnumerationBinding(threadData, _mod, _varLst, _index_list, _OMC_LIT115, _OMC_LIT128, 1);
_uncertainty_value = omc_InstBinding_getUncertainFromExpOption(threadData, _exp_bind_uncertainty);
_distribution_value = omc_InstBinding_instDistributionBinding(threadData, _mod, _varLst, _index_list, _OMC_LIT129, 0);
_startOrigin = omc_InstBinding_instStartOrigin(threadData, _mod, _varLst, _OMC_LIT19);
tmpMeta9 = mmc_mk_box12(4, &DAE_VariableAttributes_VAR__ATTR__INT__desc, _quantity_str, _min_val, _max_val, _start_val, _fixed_val, _uncertainty_value, _distribution_value, mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), _startOrigin);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = mmc_mk_some(tmpMeta9);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
_tp = tmp4_3;
_varLst = tmpMeta10;
_cache = tmp4_1;
_mod = tmp4_2;
_index_list = tmp4_4;
tmp4 += 3;
_quantity_str = omc_InstBinding_instBinding(threadData, _mod, _varLst, _OMC_LIT55, _index_list, _OMC_LIT74, 0);
_start_val = omc_InstBinding_instBinding(threadData, _mod, _varLst, _tp, _index_list, _OMC_LIT19, 0);
_fixed_val = omc_InstBinding_instBinding(threadData, _mod, _varLst, _tp, _index_list, _OMC_LIT80, 1);
_startOrigin = omc_InstBinding_instStartOrigin(threadData, _mod, _varLst, _OMC_LIT19);
tmpMeta11 = mmc_mk_box8(5, &DAE_VariableAttributes_VAR__ATTR__BOOL__desc, _quantity_str, _start_val, _fixed_val, mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), _startOrigin);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = mmc_mk_some(tmpMeta11);
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,4,1) == 0) goto tmp3_end;
_cache = tmp4_1;
tmp4 += 2;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _OMC_LIT132;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
_tp = tmp4_3;
_varLst = tmpMeta12;
_cache = tmp4_1;
_mod = tmp4_2;
_index_list = tmp4_4;
tmp4 += 1;
_quantity_str = omc_InstBinding_instBinding(threadData, _mod, _varLst, _tp, _index_list, _OMC_LIT74, 0);
_start_val = omc_InstBinding_instBinding(threadData, _mod, _varLst, _tp, _index_list, _OMC_LIT19, 0);
_fixed_val = omc_InstBinding_instBinding(threadData, _mod, _varLst, _OMC_LIT79, _index_list, _OMC_LIT80, 1);
_startOrigin = omc_InstBinding_instStartOrigin(threadData, _mod, _varLst, _OMC_LIT19);
tmpMeta13 = mmc_mk_box8(7, &DAE_VariableAttributes_VAR__ATTR__STRING__desc, _quantity_str, _start_val, _fixed_val, mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), _startOrigin);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = mmc_mk_some(tmpMeta13);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,5,5) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 6));
_enumtype = tmp4_3;
_varLst = tmpMeta14;
_cache = tmp4_1;
_mod = tmp4_2;
_index_list = tmp4_4;
_quantity_str = omc_InstBinding_instBinding(threadData, _mod, _varLst, _OMC_LIT55, _index_list, _OMC_LIT74, 0);
_exp_bind_min = omc_InstBinding_instBinding(threadData, _mod, _varLst, _enumtype, _index_list, _OMC_LIT77, 0);
_exp_bind_max = omc_InstBinding_instBinding(threadData, _mod, _varLst, _enumtype, _index_list, _OMC_LIT78, 0);
_exp_bind_start = omc_InstBinding_instBinding(threadData, _mod, _varLst, _enumtype, _index_list, _OMC_LIT19, 0);
_fixed_val = omc_InstBinding_instBinding(threadData, _mod, _varLst, _OMC_LIT79, _index_list, _OMC_LIT80, 1);
_startOrigin = omc_InstBinding_instStartOrigin(threadData, _mod, _varLst, _OMC_LIT19);
tmpMeta15 = mmc_mk_box10(8, &DAE_VariableAttributes_VAR__ATTR__ENUMERATION__desc, _quantity_str, _exp_bind_min, _exp_bind_max, _exp_bind_start, _fixed_val, mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), _startOrigin);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = mmc_mk_some(tmpMeta15);
goto tmp3_done;
}
case 6: {
_cache = tmp4_1;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = mmc_mk_none();
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
_outCache = tmpMeta[0+0];
_outDAEVariableAttributesOption = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outDAEVariableAttributesOption) { *out_outDAEVariableAttributesOption = _outDAEVariableAttributesOption; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstBinding_instStartOrigin(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _inVarLst, modelica_string _inString)
{
modelica_metatype _outExpExpOption = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_string tmp4_3;
tmp4_1 = _inMod;
tmp4_2 = _inVarLst;
tmp4_3 = _inString;
{
modelica_metatype _mod2 = NULL;
modelica_metatype _mod = NULL;
modelica_string _bind_name = NULL;
modelica_string _name = NULL;
modelica_metatype _varLst = NULL;
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
_mod = tmp4_1;
_bind_name = tmp4_3;
_mod2 = omc_Mod_lookupCompModification(threadData, _mod, _bind_name);
tmpMeta6 = omc_Mod_modEquation(threadData, _mod2);
if (optionNone(tmpMeta6)) goto goto_2;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
tmpMeta1 = _OMC_LIT135;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_boolean tmp11;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_2);
tmpMeta9 = MMC_CDR(tmp4_2);
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
_name = tmpMeta10;
_bind_name = tmp4_3;
tmp11 = (stringEqual(_name, _bind_name));
if (1 != tmp11) goto goto_2;
tmpMeta1 = _OMC_LIT138;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmp4_2);
tmpMeta13 = MMC_CDR(tmp4_2);
_varLst = tmpMeta13;
_mod = tmp4_1;
_bind_name = tmp4_3;
tmp4 += 1;
tmpMeta1 = omc_InstBinding_instStartOrigin(threadData, _mod, _varLst, _bind_name);
goto tmp3_done;
}
case 3: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta1 = mmc_mk_none();
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
_outExpExpOption = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExpExpOption;
}
DLLExport
modelica_metatype omc_InstBinding_instStartBindingExp(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _inExpectedType, modelica_metatype _inVariability)
{
modelica_metatype _outStartValue = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(omc_SCodeUtil_isConstant(threadData, _inVariability))
{
_outStartValue = mmc_mk_none();
}
else
{
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
_outStartValue = omc_InstBinding_instBinding(threadData, _inMod, tmpMeta1, omc_Types_arrayElementType(threadData, _inExpectedType), tmpMeta2, _OMC_LIT19, 0);
}
_return: OMC_LABEL_UNUSED
return _outStartValue;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstBinding_instBinding2(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _inType, modelica_metatype _inIntegerLst, modelica_string _inString, modelica_boolean _useConstValue)
{
modelica_metatype _outExpExpOption = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_string tmp4_4;
tmp4_1 = _inMod;
tmp4_2 = _inType;
tmp4_3 = _inIntegerLst;
tmp4_4 = _inString;
{
modelica_metatype _mod2 = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e_1 = NULL;
modelica_metatype _ty2 = NULL;
modelica_metatype _etype = NULL;
modelica_integer _index;
modelica_string _bind_name = NULL;
modelica_metatype _res = NULL;
modelica_metatype _optVal = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_integer tmp8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_3);
tmpMeta7 = MMC_CDR(tmp4_3);
tmp8 = mmc_unbox_integer(tmpMeta6);
if (!listEmpty(tmpMeta7)) goto tmp3_end;
_index = tmp8;
_mod = tmp4_1;
_etype = tmp4_2;
tmpMeta9 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_index));
_mod2 = omc_Mod_lookupIdxModification(threadData, _mod, tmpMeta9);
tmpMeta10 = omc_Mod_modEquation(threadData, _mod2);
if (optionNone(tmpMeta10)) goto goto_2;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,0,5) == 0) goto goto_2;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 3));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,0,2) == 0) goto goto_2;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
_e = tmpMeta12;
_optVal = tmpMeta13;
_ty2 = tmpMeta15;
_e_1 = omc_Types_matchType(threadData, _e, _ty2, _etype, 1, NULL);
_e_1 = omc_InstUtil_checkUseConstValue(threadData, _useConstValue, _e_1, _optVal);
tmpMeta1 = mmc_mk_some(_e_1);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_integer tmp18;
modelica_metatype tmpMeta19;
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmp4_3);
tmpMeta17 = MMC_CDR(tmp4_3);
tmp18 = mmc_unbox_integer(tmpMeta16);
_index = tmp18;
_res = tmpMeta17;
_mod = tmp4_1;
_etype = tmp4_2;
_bind_name = tmp4_4;
{
{
volatile mmc_switch_type tmp22;
int tmp23;
tmp22 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp21_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp22 < 2; tmp22++) {
switch (MMC_SWITCH_CAST(tmp22)) {
case 0: {
modelica_metatype tmpMeta24;
tmpMeta24 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_index));
_mod2 = omc_Mod_lookupIdxModification(threadData, _mod, tmpMeta24);
tmpMeta19 = omc_InstBinding_instBinding2(threadData, _mod2, _etype, _res, _bind_name, _useConstValue);
goto tmp21_done;
}
case 1: {
tmpMeta19 = mmc_mk_none();
goto tmp21_done;
}
}
goto tmp21_end;
tmp21_end: ;
}
goto goto_20;
tmp21_done:
(void)tmp22;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp21_done2;
goto_20:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp22 < 2) {
goto tmp21_top;
}
goto goto_2;
tmp21_done2:;
}
}tmpMeta1 = tmpMeta19;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outExpExpOption = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExpExpOption;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstBinding_instBinding2(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _inType, modelica_metatype _inIntegerLst, modelica_metatype _inString, modelica_metatype _useConstValue)
{
modelica_integer tmp1;
modelica_metatype _outExpExpOption = NULL;
tmp1 = mmc_unbox_integer(_useConstValue);
_outExpExpOption = omc_InstBinding_instBinding2(threadData, _inMod, _inType, _inIntegerLst, _inString, tmp1);
return _outExpExpOption;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstBinding_instBinding(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _inVarLst, modelica_metatype _inType, modelica_metatype _inIntegerLst, modelica_string _inString, modelica_boolean _useConstValue)
{
modelica_metatype _outExpExpOption = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;volatile modelica_string tmp4_5;
tmp4_1 = _inMod;
tmp4_2 = _inVarLst;
tmp4_3 = _inType;
tmp4_4 = _inIntegerLst;
tmp4_5 = _inString;
{
modelica_metatype _mod2 = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e_1 = NULL;
modelica_metatype _ty2 = NULL;
modelica_metatype _expected_type = NULL;
modelica_metatype _etype = NULL;
modelica_string _bind_name = NULL;
modelica_metatype _index_list = NULL;
modelica_metatype _binding = NULL;
modelica_string _name = NULL;
modelica_metatype _optVal = NULL;
modelica_metatype _varLst = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (!listEmpty(tmp4_4)) goto tmp3_end;
_mod = tmp4_1;
_expected_type = tmp4_3;
_bind_name = tmp4_5;
_mod2 = omc_Mod_lookupCompModification(threadData, _mod, _bind_name);
tmpMeta6 = omc_Mod_modEquation(threadData, _mod2);
if (optionNone(tmpMeta6)) goto goto_2;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,5) == 0) goto goto_2;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,0,2) == 0) goto goto_2;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_e = tmpMeta8;
_optVal = tmpMeta9;
_ty2 = tmpMeta11;
_e_1 = omc_Types_matchType(threadData, _e, _ty2, _expected_type, 1, NULL);
_e_1 = omc_InstUtil_checkUseConstValue(threadData, _useConstValue, _e_1, _optVal);
tmpMeta1 = mmc_mk_some(_e_1);
goto tmp3_done;
}
case 1: {
_mod = tmp4_1;
_etype = tmp4_3;
_index_list = tmp4_4;
_bind_name = tmp4_5;
_mod2 = omc_Mod_lookupCompModification(threadData, _mod, _bind_name);
tmpMeta1 = omc_InstBinding_instBinding2(threadData, _mod2, _etype, _index_list, _bind_name, _useConstValue);
goto tmp3_done;
}
case 2: {
modelica_boolean tmp12;
if (!listEmpty(tmp4_4)) goto tmp3_end;
_mod = tmp4_1;
_bind_name = tmp4_5;
tmp12 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_Mod_lookupCompModification(threadData, _mod, _bind_name);
tmp12 = 1;
goto goto_13;
goto_13:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp12) {goto goto_2;}
tmpMeta1 = mmc_mk_none();
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_boolean tmp18;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta14 = MMC_CAR(tmp4_2);
tmpMeta15 = MMC_CDR(tmp4_2);
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 5));
_name = tmpMeta16;
_binding = tmpMeta17;
_bind_name = tmp4_5;
tmp18 = (stringEqual(_name, _bind_name));
if (1 != tmp18) goto goto_2;
tmpMeta1 = omc_DAEUtil_bindingExp(threadData, _binding);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta19 = MMC_CAR(tmp4_2);
tmpMeta20 = MMC_CDR(tmp4_2);
_varLst = tmpMeta20;
_mod = tmp4_1;
_etype = tmp4_3;
_index_list = tmp4_4;
_bind_name = tmp4_5;
tmp4 += 1;
tmpMeta1 = omc_InstBinding_instBinding(threadData, _mod, _varLst, _etype, _index_list, _bind_name, _useConstValue);
goto tmp3_done;
}
case 5: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta1 = mmc_mk_none();
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
_outExpExpOption = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExpExpOption;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstBinding_instBinding(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _inVarLst, modelica_metatype _inType, modelica_metatype _inIntegerLst, modelica_metatype _inString, modelica_metatype _useConstValue)
{
modelica_integer tmp1;
modelica_metatype _outExpExpOption = NULL;
tmp1 = mmc_unbox_integer(_useConstValue);
_outExpExpOption = omc_InstBinding_instBinding(threadData, _inMod, _inVarLst, _inType, _inIntegerLst, _inString, tmp1);
return _outExpExpOption;
}
