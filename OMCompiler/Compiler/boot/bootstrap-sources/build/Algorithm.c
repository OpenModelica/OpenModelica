#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "Algorithm.c"
#endif
#include "omc_simulation_settings.h"
#include "Algorithm.h"
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
#define _OMC_LIT5_data "Algorithm.getStatementSource"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,28,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,2,1) {_OMC_LIT5,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "Expression '%1' has type %3, expected type %2."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,46,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT8,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT7}};
#define _OMC_LIT8 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(246)),_OMC_LIT0,_OMC_LIT1,_OMC_LIT8}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "Boolean"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,7,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "String"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,6,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "AssertionLevel"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,14,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT13,2,4) {&DAE_Type_T__REAL__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT13 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data "reinit called with wrong args"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,29,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,2,1) {_OMC_LIT14,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "Type error in when conditional '%s'. Expected Boolean scalar or vector, got %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,79,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT17,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT16}};
#define _OMC_LIT17 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT18,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(12)),_OMC_LIT0,_OMC_LIT1,_OMC_LIT17}};
#define _OMC_LIT18 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT18)
#define _OMC_LIT19_data "Type error in while conditional '%s'. Expected Boolean got %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT19,62,_OMC_LIT19_data);
#define _OMC_LIT19 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT19)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT20,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT19}};
#define _OMC_LIT20 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT20)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT21,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(13)),_OMC_LIT0,_OMC_LIT1,_OMC_LIT20}};
#define _OMC_LIT21 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "Type error in iteration range '%s'. Expected array got %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,58,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT23,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT22}};
#define _OMC_LIT23 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT23)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT24,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(11)),_OMC_LIT0,_OMC_LIT1,_OMC_LIT23}};
#define _OMC_LIT24 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT24)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT25,1,3) {&DAE_Else_NOELSE__desc,}};
#define _OMC_LIT25 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT25)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT26,2,6) {&DAE_Type_T__BOOL__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT26 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data "Type error in conditional '%s'. Expected Boolean, got %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,57,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT28,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT27}};
#define _OMC_LIT28 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT28)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT29,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(10)),_OMC_LIT0,_OMC_LIT1,_OMC_LIT28}};
#define _OMC_LIT29 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT29)
#define _OMC_LIT30_data ", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT30,2,_OMC_LIT30_data);
#define _OMC_LIT30 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data "("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,1,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
#define _OMC_LIT32_data ")"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT32,1,_OMC_LIT32_data);
#define _OMC_LIT32 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT32)
#define _OMC_LIT33_data "Trying to assign to constant component in %s := %s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT33,50,_OMC_LIT33_data);
#define _OMC_LIT33 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT33)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT34,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT33}};
#define _OMC_LIT34 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT34)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT35,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(6)),_OMC_LIT0,_OMC_LIT1,_OMC_LIT34}};
#define _OMC_LIT35 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT35)
#define _OMC_LIT36_data "Trying to assign to parameter component in %s := %s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT36,51,_OMC_LIT36_data);
#define _OMC_LIT36 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT36)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT37,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT36}};
#define _OMC_LIT37 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT37)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT38,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(7)),_OMC_LIT0,_OMC_LIT1,_OMC_LIT37}};
#define _OMC_LIT38 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT38)
#define _OMC_LIT39_data "failtrace"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT39,9,_OMC_LIT39_data);
#define _OMC_LIT39 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT39)
#define _OMC_LIT40_data "Sets whether to print a failtrace or not."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT40,41,_OMC_LIT40_data);
#define _OMC_LIT40 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT40)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT41,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT40}};
#define _OMC_LIT41 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT41)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT42,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT39,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT41}};
#define _OMC_LIT42 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT42)
#define _OMC_LIT43_data "- Algorithm.makeTupleAssignment failed on: \n	"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT43,45,_OMC_LIT43_data);
#define _OMC_LIT43 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT43)
#define _OMC_LIT44_data " = "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT44,3,_OMC_LIT44_data);
#define _OMC_LIT44 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT44)
#define _OMC_LIT45_data "\n	props lhs: ("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT45,14,_OMC_LIT45_data);
#define _OMC_LIT45 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT45)
#define _OMC_LIT46_data ") =  props rhs: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT46,16,_OMC_LIT46_data);
#define _OMC_LIT46 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT46)
#define _OMC_LIT47_data "\n	in "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT47,5,_OMC_LIT47_data);
#define _OMC_LIT47 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT47)
#define _OMC_LIT48_data " section"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT48,8,_OMC_LIT48_data);
#define _OMC_LIT48 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT48)
#define _OMC_LIT49_data "Trying to assign to parameter component %s(fixed=true) in %s := %s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT49,66,_OMC_LIT49_data);
#define _OMC_LIT49 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT49)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT50,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT49}};
#define _OMC_LIT50 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT50)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT51,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(580)),_OMC_LIT0,_OMC_LIT1,_OMC_LIT50}};
#define _OMC_LIT51 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT51)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT52,1,5) {&ErrorTypes_Severity_WARNING__desc,}};
#define _OMC_LIT52 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT52)
#define _OMC_LIT53_data "%1:=listAppend(%1, _) has the first argument in the \"wrong\" order.\n  It is very slow to keep appending a linked list (scales like O(N²)).\n  Consider building the list in the reverse order in order to improve performance (scales like O(N) even if you need to reverse a lot of lists). Use annotation __OpenModelica_DisableListAppendWarning=true to disable this message for a certain assignment."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT53,393,_OMC_LIT53_data);
#define _OMC_LIT53 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT53)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT54,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT53}};
#define _OMC_LIT54 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT54)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT55,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(5039)),_OMC_LIT0,_OMC_LIT52,_OMC_LIT54}};
#define _OMC_LIT55 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT55)
#define _OMC_LIT56_data "listAppendWrongOrder"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT56,20,_OMC_LIT56_data);
#define _OMC_LIT56 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT56)
#define _OMC_LIT57_data "Print notifications about bad usage of listAppend."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT57,50,_OMC_LIT57_data);
#define _OMC_LIT57 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT57)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT58,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT57}};
#define _OMC_LIT58 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT58)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT59,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(155)),_OMC_LIT56,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT58}};
#define _OMC_LIT59 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT59)
#define _OMC_LIT60_data "__OpenModelica_DisableListAppendWarning"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT60,39,_OMC_LIT60_data);
#define _OMC_LIT60 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT60)
#define _OMC_LIT61_data "listAppend"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT61,10,_OMC_LIT61_data);
#define _OMC_LIT61 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT61)
#define _OMC_LIT62_data "Trying to assign to %s component %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT62,36,_OMC_LIT62_data);
#define _OMC_LIT62 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT62)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT63,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT62}};
#define _OMC_LIT63 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT63)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT64,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(8)),_OMC_LIT0,_OMC_LIT1,_OMC_LIT63}};
#define _OMC_LIT64 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT64)
#define _OMC_LIT65_data "constant"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT65,8,_OMC_LIT65_data);
#define _OMC_LIT65 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT65)
#define _OMC_LIT66_data "Type mismatch in assignment in %s := %s of %s := %s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT66,51,_OMC_LIT66_data);
#define _OMC_LIT66 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT66)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT67,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT66}};
#define _OMC_LIT67 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT67)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT68,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(9)),_OMC_LIT0,_OMC_LIT1,_OMC_LIT67}};
#define _OMC_LIT68 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT68)
#define _OMC_LIT69_data "- Algorithm.makeAssignment failed"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT69,33,_OMC_LIT69_data);
#define _OMC_LIT69 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT69)
#define _OMC_LIT70_data "    "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT70,4,_OMC_LIT70_data);
#define _OMC_LIT70 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT70)
#define _OMC_LIT71_data " := "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT71,4,_OMC_LIT71_data);
#define _OMC_LIT71 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT71)
#include "util/modelica.h"
#include "Algorithm_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Algorithm_makeElse(threadData_t *threadData, modelica_metatype _inTuple, modelica_metatype _inStatementLst, modelica_metatype _inSource);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Algorithm_makeElse,2,0) {(void*) boxptr_Algorithm_makeElse,0}};
#define boxvar_Algorithm_makeElse MMC_REFSTRUCTLIT(boxvar_lit_Algorithm_makeElse)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Algorithm_makeElseFromBranches(threadData_t *threadData, modelica_metatype _inTpl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Algorithm_makeElseFromBranches,2,0) {(void*) boxptr_Algorithm_makeElseFromBranches,0}};
#define boxvar_Algorithm_makeElseFromBranches MMC_REFSTRUCTLIT(boxvar_lit_Algorithm_makeElseFromBranches)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Algorithm_getPropExpType(threadData_t *threadData, modelica_metatype _p);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Algorithm_getPropExpType,2,0) {(void*) boxptr_Algorithm_getPropExpType,0}};
#define boxvar_Algorithm_getPropExpType MMC_REFSTRUCTLIT(boxvar_lit_Algorithm_getPropExpType)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Algorithm_makeAssignment2(threadData_t *threadData, modelica_metatype _lhs, modelica_metatype _lhprop, modelica_metatype _rhs, modelica_metatype _rhprop, modelica_metatype _source);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Algorithm_makeAssignment2,2,0) {(void*) boxptr_Algorithm_makeAssignment2,0}};
#define boxvar_Algorithm_makeAssignment2 MMC_REFSTRUCTLIT(boxvar_lit_Algorithm_makeAssignment2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Algorithm_makeTupleAssignmentNoTypeCheck2(threadData_t *threadData, modelica_boolean _allWild, modelica_boolean _singleAssign, modelica_metatype _ty, modelica_metatype _lhs, modelica_metatype _rhs, modelica_metatype _source);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Algorithm_makeTupleAssignmentNoTypeCheck2(threadData_t *threadData, modelica_metatype _allWild, modelica_metatype _singleAssign, modelica_metatype _ty, modelica_metatype _lhs, modelica_metatype _rhs, modelica_metatype _source);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Algorithm_makeTupleAssignmentNoTypeCheck2,2,0) {(void*) boxptr_Algorithm_makeTupleAssignmentNoTypeCheck2,0}};
#define boxvar_Algorithm_makeTupleAssignmentNoTypeCheck2 MMC_REFSTRUCTLIT(boxvar_lit_Algorithm_makeTupleAssignmentNoTypeCheck2)
DLLExport
modelica_boolean omc_Algorithm_isNotDummyStatement(threadData_t *threadData, modelica_metatype _stmt)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _stmt;
{
modelica_metatype _exp = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_integer tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_exp = tmpMeta6;
omc_Expression_traverseExpBottomUp(threadData, _exp, boxvar_Expression_hasNoSideEffects, mmc_mk_boolean(1), &tmpMeta7);
tmp8 = mmc_unbox_integer(tmpMeta7);
_b = tmp8;
tmp1 = (!_b);
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
modelica_metatype boxptr_Algorithm_isNotDummyStatement(threadData_t *threadData, modelica_metatype _stmt)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_Algorithm_isNotDummyStatement(threadData, _stmt);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_metatype omc_Algorithm_getAssertCond(threadData_t *threadData, modelica_metatype _stmt)
{
modelica_metatype _cond = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _stmt;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,8,4) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_cond = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _cond;
}
DLLExport
modelica_metatype omc_Algorithm_getStatementSource(threadData_t *threadData, modelica_metatype _stmt)
{
modelica_metatype _source = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _stmt;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_source = tmpMeta5;
tmpMeta1 = _source;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_source = tmpMeta6;
tmpMeta1 = _source;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_source = tmpMeta7;
tmpMeta1 = _source;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,4) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_source = tmpMeta8;
tmpMeta1 = _source;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,7) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_source = tmpMeta9;
tmpMeta1 = _source;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,8) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 9));
_source = tmpMeta10;
tmpMeta1 = _source;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,3) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_source = tmpMeta11;
tmpMeta1 = _source;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,6) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
_source = tmpMeta12;
tmpMeta1 = _source;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,4) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_source = tmpMeta13;
tmpMeta1 = _source;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,2) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_source = tmpMeta14;
tmpMeta1 = _source;
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,3) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_source = tmpMeta15;
tmpMeta1 = _source;
goto tmp3_done;
}
case 14: {
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,2) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_source = tmpMeta16;
tmpMeta1 = _source;
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,1) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_source = tmpMeta17;
tmpMeta1 = _source;
goto tmp3_done;
}
case 16: {
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,1) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_source = tmpMeta18;
tmpMeta1 = _source;
goto tmp3_done;
}
case 17: {
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,14,1) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_source = tmpMeta19;
tmpMeta1 = _source;
goto tmp3_done;
}
case 19: {
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,2) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_source = tmpMeta20;
tmpMeta1 = _source;
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
_source = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _source;
}
DLLExport
modelica_metatype omc_Algorithm_getAllExpsStmts(threadData_t *threadData, modelica_metatype _stmts)
{
modelica_metatype _exps = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta4 = mmc_mk_box2(0, boxvar_Expression_expressionCollector, tmpMeta3);
omc_DAEUtil_traverseDAEEquationsStmts(threadData, _stmts, boxvar_Expression_traverseSubexpressionsHelper, tmpMeta4, &tmpMeta1);
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_exps = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _exps;
}
DLLExport
modelica_metatype omc_Algorithm_getAllExps(threadData_t *threadData, modelica_metatype _inAlgorithm)
{
modelica_metatype _outExpExpLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAlgorithm;
{
modelica_metatype _stmts = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_stmts = tmpMeta6;
tmpMeta1 = omc_Algorithm_getAllExpsStmts(threadData, _stmts);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outExpExpLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExpExpLst;
}
DLLExport
modelica_metatype omc_Algorithm_getCrefFromAlg(threadData_t *threadData, modelica_metatype _alg)
{
modelica_metatype _crs = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_crs = omc_List_unionOnTrueList(threadData, omc_List_map(threadData, omc_Algorithm_getAllExps(threadData, _alg), boxvar_Expression_extractCrefsFromExp), boxvar_ComponentReference_crefEqual);
_return: OMC_LABEL_UNUSED
return _crs;
}
DLLExport
modelica_metatype omc_Algorithm_makeTerminate(threadData_t *threadData, modelica_metatype _msg, modelica_metatype _props, modelica_metatype _source)
{
modelica_metatype _outStatement = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _props;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,2,1) == 0) goto tmp3_end;
tmpMeta8 = mmc_mk_box3(12, &DAE_Statement_STMT__TERMINATE__desc, _msg, _source);
tmpMeta7 = mmc_mk_cons(tmpMeta8, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outStatement = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStatement;
}
DLLExport
modelica_metatype omc_Algorithm_makeAssert(threadData_t *threadData, modelica_metatype _cond, modelica_metatype _msg, modelica_metatype _level, modelica_metatype _inProperties3, modelica_metatype _inProperties4, modelica_metatype _inProperties5, modelica_metatype _source)
{
modelica_metatype _outStatement = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;
tmp4_1 = _cond;
tmp4_2 = _inProperties3;
tmp4_3 = _inProperties4;
tmp4_4 = _inProperties5;
{
modelica_metatype _info = NULL;
modelica_metatype _t1 = NULL;
modelica_metatype _t2 = NULL;
modelica_metatype _t3 = NULL;
modelica_string _strTy = NULL;
modelica_string _strExp = NULL;
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
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
if (1 != tmp7) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,0,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,5,5) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,2,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,1,1) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
if (14 != MMC_STRLEN(tmpMeta13) || strcmp(MMC_STRINGDATA(_OMC_LIT12), MMC_STRINGDATA(tmpMeta13)) != 0) goto tmp3_end;
tmpMeta14 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta14;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,2) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,0,2) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,5,5) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,2,1) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta19,1,1) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 2));
if (14 != MMC_STRLEN(tmpMeta20) || strcmp(MMC_STRINGDATA(_OMC_LIT12), MMC_STRINGDATA(tmpMeta20)) != 0) goto tmp3_end;
tmpMeta22 = mmc_mk_box5(11, &DAE_Statement_STMT__ASSERT__desc, _cond, _msg, _level, _source);
tmpMeta21 = mmc_mk_cons(tmpMeta22, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta21;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_boolean tmp28;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,2) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,0,2) == 0) goto tmp3_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 2));
_t1 = tmpMeta23;
_t2 = tmpMeta24;
_t3 = tmpMeta25;
_info = omc_ElementSource_getElementSourceFileInfo(threadData, _source);
_strExp = omc_ExpressionDump_printExpStr(threadData, _cond);
_strTy = omc_Types_unparseType(threadData, _t1);
tmpMeta26 = mmc_mk_cons(_strExp, mmc_mk_cons(_OMC_LIT10, mmc_mk_cons(_strTy, MMC_REFSTRUCTLIT(mmc_nil))));
omc_Error_assertionOrAddSourceMessage(threadData, omc_Types_isBooleanOrSubTypeBoolean(threadData, _t1), _OMC_LIT9, tmpMeta26, _info);
_strExp = omc_ExpressionDump_printExpStr(threadData, _msg);
_strTy = omc_Types_unparseType(threadData, _t2);
tmpMeta27 = mmc_mk_cons(_strExp, mmc_mk_cons(_OMC_LIT11, mmc_mk_cons(_strTy, MMC_REFSTRUCTLIT(mmc_nil))));
omc_Error_assertionOrAddSourceMessage(threadData, omc_Types_isString(threadData, _t2), _OMC_LIT9, tmpMeta27, _info);
tmp28 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmpMeta30 = _t3;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta30,5,5) == 0) goto goto_29;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta31,1,1) == 0) goto goto_29;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta31), 2));
if (14 != MMC_STRLEN(tmpMeta32) || strcmp("AssertionLevel", MMC_STRINGDATA(tmpMeta32)) != 0) goto goto_29;
tmp28 = 1;
goto goto_29;
goto_29:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp28) {goto goto_2;}
_strExp = omc_ExpressionDump_printExpStr(threadData, _level);
_strTy = omc_Types_unparseType(threadData, _t3);
tmpMeta33 = mmc_mk_cons(_strExp, mmc_mk_cons(_OMC_LIT12, mmc_mk_cons(_strTy, MMC_REFSTRUCTLIT(mmc_nil))));
omc_Error_assertionOrAddSourceMessage(threadData, omc_Types_isString(threadData, _t3), _OMC_LIT9, tmpMeta33, _info);
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
_outStatement = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStatement;
}
DLLExport
modelica_metatype omc_Algorithm_makeReinit(threadData_t *threadData, modelica_metatype _inExp1, modelica_metatype _inExp2, modelica_metatype _inProperties3, modelica_metatype _inProperties4, modelica_metatype _source)
{
modelica_metatype _outStatement = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;
tmp4_1 = _inExp1;
tmp4_2 = _inExp2;
tmp4_3 = _inProperties3;
tmp4_4 = _inProperties4;
{
modelica_metatype _var = NULL;
modelica_metatype _val = NULL;
modelica_metatype _var_1 = NULL;
modelica_metatype _val_1 = NULL;
modelica_metatype _tp1 = NULL;
modelica_metatype _tp2 = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,0,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 2));
_var = tmp4_1;
_tp1 = tmpMeta6;
_tp2 = tmpMeta7;
_val = tmp4_2;
_val_1 = omc_Types_matchType(threadData, _val, _tp2, _OMC_LIT13, 1, NULL);
_var_1 = omc_Types_matchType(threadData, _var, _tp1, _OMC_LIT13, 1, NULL);
tmpMeta9 = mmc_mk_box4(13, &DAE_Statement_STMT__REINIT__desc, _var_1, _val_1, _source);
tmpMeta8 = mmc_mk_cons(tmpMeta9, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
omc_Error_addSourceMessage(threadData, _OMC_LIT4, _OMC_LIT15, omc_ElementSource_getElementSourceFileInfo(threadData, _source));
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
_outStatement = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStatement;
}
DLLExport
modelica_metatype omc_Algorithm_makeWhenA(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inProperties, modelica_metatype _inStatementLst, modelica_metatype _elseWhenStmt, modelica_metatype _source)
{
modelica_metatype _outStatement = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;
tmp4_1 = _inExp;
tmp4_2 = _inProperties;
tmp4_3 = _inStatementLst;
tmp4_4 = _elseWhenStmt;
{
modelica_metatype _e = NULL;
modelica_metatype _stmts = NULL;
modelica_metatype _elsew = NULL;
modelica_string _e_str = NULL;
modelica_string _t_str = NULL;
modelica_metatype _t = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,1) == 0) goto tmp3_end;
_e = tmp4_1;
_stmts = tmp4_3;
_elsew = tmp4_4;
tmp4 += 1;
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta8 = mmc_mk_box7(10, &DAE_Statement_STMT__WHEN__desc, _e, tmpMeta7, mmc_mk_boolean(0), _stmts, _elsew, _source);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,6,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,3,1) == 0) goto tmp3_end;
_e = tmp4_1;
_stmts = tmp4_3;
_elsew = tmp4_4;
tmpMeta11 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta12 = mmc_mk_box7(10, &DAE_Statement_STMT__WHEN__desc, _e, tmpMeta11, mmc_mk_boolean(0), _stmts, _elsew, _source);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_t = tmpMeta13;
_e = tmp4_1;
_e_str = omc_ExpressionDump_printExpStr(threadData, _e);
_t_str = omc_Types_unparseTypeNoAttr(threadData, _t);
tmpMeta14 = mmc_mk_cons(_e_str, mmc_mk_cons(_t_str, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT18, tmpMeta14, omc_ElementSource_getElementSourceFileInfo(threadData, _source));
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
_outStatement = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStatement;
}
DLLExport
modelica_metatype omc_Algorithm_makeWhile(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inProperties, modelica_metatype _inStatementLst, modelica_metatype _source)
{
modelica_metatype _outStatement = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inExp;
tmp4_2 = _inProperties;
tmp4_3 = _inStatementLst;
{
modelica_metatype _e = NULL;
modelica_metatype _stmts = NULL;
modelica_string _e_str = NULL;
modelica_string _t_str = NULL;
modelica_metatype _t = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,1) == 0) goto tmp3_end;
_e = tmp4_1;
_stmts = tmp4_3;
tmpMeta7 = mmc_mk_box4(9, &DAE_Statement_STMT__WHILE__desc, _e, _stmts, _source);
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_t = tmpMeta8;
_e = tmp4_1;
_e_str = omc_ExpressionDump_printExpStr(threadData, _e);
_t_str = omc_Types_unparseTypeNoAttr(threadData, _t);
tmpMeta9 = mmc_mk_cons(_e_str, mmc_mk_cons(_t_str, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT21, tmpMeta9, omc_ElementSource_getElementSourceFileInfo(threadData, _source));
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
_outStatement = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStatement;
}
DLLExport
modelica_metatype omc_Algorithm_makeParFor(threadData_t *threadData, modelica_string _inIdent, modelica_metatype _inExp, modelica_metatype _inProperties, modelica_metatype _inStatementLst, modelica_metatype _inLoopPrlVars, modelica_metatype _source)
{
modelica_metatype _outStatement = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_string tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;
tmp4_1 = _inIdent;
tmp4_2 = _inExp;
tmp4_3 = _inProperties;
tmp4_4 = _inStatementLst;
{
modelica_boolean _isArray;
modelica_string _i = NULL;
modelica_string _e_str = NULL;
modelica_string _t_str = NULL;
modelica_metatype _e = NULL;
modelica_metatype _t = NULL;
modelica_metatype _stmts = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,6,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
_t = tmpMeta7;
_dims = tmpMeta8;
_i = tmp4_1;
_e = tmp4_2;
_stmts = tmp4_4;
_isArray = omc_Types_isNonscalarArray(threadData, _t, _dims);
omc_Types_simplifyType(threadData, _t);
tmpMeta9 = mmc_mk_box9(8, &DAE_Statement_STMT__PARFOR__desc, _t, mmc_mk_boolean(_isArray), _i, mmc_mk_integer(((modelica_integer) -1)), _e, _stmts, _inLoopPrlVars, _source);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
_t = tmpMeta10;
_e = tmp4_2;
_e_str = omc_ExpressionDump_printExpStr(threadData, _e);
_t_str = omc_Types_unparseTypeNoAttr(threadData, _t);
tmpMeta11 = mmc_mk_cons(_e_str, mmc_mk_cons(_t_str, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT24, tmpMeta11, omc_ElementSource_getElementSourceFileInfo(threadData, _source));
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
_outStatement = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStatement;
}
DLLExport
modelica_metatype omc_Algorithm_makeFor(threadData_t *threadData, modelica_string _inIdent, modelica_metatype _inExp, modelica_metatype _inProperties, modelica_metatype _inStatementLst, modelica_metatype _source)
{
modelica_metatype _outStatement = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_string tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;
tmp4_1 = _inIdent;
tmp4_2 = _inExp;
tmp4_3 = _inProperties;
tmp4_4 = _inStatementLst;
{
modelica_boolean _isArray;
modelica_string _i = NULL;
modelica_string _e_str = NULL;
modelica_string _t_str = NULL;
modelica_metatype _e = NULL;
modelica_metatype _t = NULL;
modelica_metatype _stmts = NULL;
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
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,6,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
_t = tmpMeta7;
_dims = tmpMeta8;
_i = tmp4_1;
_e = tmp4_2;
_stmts = tmp4_4;
tmp4 += 2;
_isArray = omc_Types_isNonscalarArray(threadData, _t, _dims);
tmpMeta9 = mmc_mk_box8(7, &DAE_Statement_STMT__FOR__desc, _t, mmc_mk_boolean(_isArray), _i, mmc_mk_integer(((modelica_integer) -1)), _e, _stmts, _source);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,17,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_t = tmpMeta11;
_i = tmp4_1;
_e = tmp4_2;
_stmts = tmp4_4;
tmp4 += 1;
_t = omc_Types_simplifyType(threadData, _t);
tmpMeta12 = mmc_mk_box8(7, &DAE_Statement_STMT__FOR__desc, _t, mmc_mk_boolean(0), _i, mmc_mk_integer(((modelica_integer) -1)), _e, _stmts, _source);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,2) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,22,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
_t = tmpMeta14;
_i = tmp4_1;
_e = tmp4_2;
_stmts = tmp4_4;
_t = omc_Types_simplifyType(threadData, _t);
tmpMeta15 = mmc_mk_box8(7, &DAE_Statement_STMT__FOR__desc, _t, mmc_mk_boolean(0), _i, mmc_mk_integer(((modelica_integer) -1)), _e, _stmts, _source);
tmpMeta1 = tmpMeta15;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,2) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
_t = tmpMeta16;
_e = tmp4_2;
_e_str = omc_ExpressionDump_printExpStr(threadData, _e);
_t_str = omc_Types_unparseTypeNoAttr(threadData, _t);
tmpMeta17 = mmc_mk_cons(_e_str, mmc_mk_cons(_t_str, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT24, tmpMeta17, omc_ElementSource_getElementSourceFileInfo(threadData, _source));
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
_outStatement = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStatement;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Algorithm_makeElse(threadData_t *threadData, modelica_metatype _inTuple, modelica_metatype _inStatementLst, modelica_metatype _inSource)
{
modelica_metatype _outElse = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inTuple;
tmp4_2 = _inStatementLst;
{
modelica_metatype _fb = NULL;
modelica_metatype _b = NULL;
modelica_metatype _else_ = NULL;
modelica_metatype _e = NULL;
modelica_metatype _xs = NULL;
modelica_string _e_str = NULL;
modelica_string _t_str = NULL;
modelica_metatype _t = NULL;
modelica_metatype _info = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta1 = _OMC_LIT25;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (!listEmpty(tmp4_1)) goto tmp3_end;
_fb = tmp4_2;
tmp4 += 4;
tmpMeta6 = mmc_mk_box2(5, &DAE_Else_ELSE__desc, _fb);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_integer tmp11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,3,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmp11 = mmc_unbox_integer(tmpMeta10);
if (1 != tmp11) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,0,2) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
_b = tmpMeta13;
tmp4 += 1;
tmpMeta14 = mmc_mk_box2(5, &DAE_Else_ELSE__desc, _b);
tmpMeta1 = tmpMeta14;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_integer tmp19;
modelica_metatype tmpMeta20;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta15 = MMC_CAR(tmp4_1);
tmpMeta16 = MMC_CDR(tmp4_1);
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,3,1) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 2));
tmp19 = mmc_unbox_integer(tmpMeta18);
if (0 != tmp19) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,0,2) == 0) goto tmp3_end;
_xs = tmpMeta16;
_fb = tmp4_2;
tmpMeta1 = omc_Algorithm_makeElse(threadData, _xs, _fb, _inSource);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta21 = MMC_CAR(tmp4_1);
tmpMeta22 = MMC_CDR(tmp4_1);
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 1));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta24,0,2) == 0) goto tmp3_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 2));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 3));
_e = tmpMeta23;
_t = tmpMeta25;
_b = tmpMeta26;
_xs = tmpMeta22;
_fb = tmp4_2;
_e = omc_Types_matchType(threadData, _e, _t, _OMC_LIT26, 1, NULL);
_else_ = omc_Algorithm_makeElse(threadData, _xs, _fb, _inSource);
tmpMeta27 = mmc_mk_box4(4, &DAE_Else_ELSEIF__desc, _e, _b, _else_);
tmpMeta1 = tmpMeta27;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta28 = MMC_CAR(tmp4_1);
tmpMeta29 = MMC_CDR(tmp4_1);
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta28), 1));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta28), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta31,0,2) == 0) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta31), 2));
_e = tmpMeta30;
_t = tmpMeta32;
_e_str = omc_ExpressionDump_printExpStr(threadData, _e);
_t_str = omc_Types_unparseTypeNoAttr(threadData, _t);
_info = omc_ElementSource_getElementSourceFileInfo(threadData, _inSource);
tmpMeta33 = mmc_mk_cons(_e_str, mmc_mk_cons(_t_str, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT29, tmpMeta33, _info);
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
if (++tmp4 < 6) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outElse = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outElse;
}
DLLExport
modelica_metatype omc_Algorithm_optimizeElseIf(threadData_t *threadData, modelica_metatype _cond, modelica_metatype _stmts, modelica_metatype _els)
{
modelica_metatype _oelse = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cond;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
if (1 != tmp7) goto tmp3_end;
tmpMeta8 = mmc_mk_box2(5, &DAE_Else_ELSE__desc, _stmts);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_integer tmp10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp10 = mmc_unbox_integer(tmpMeta9);
if (0 != tmp10) goto tmp3_end;
tmpMeta1 = _els;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta11;
tmpMeta11 = mmc_mk_box4(4, &DAE_Else_ELSEIF__desc, _cond, _stmts, _els);
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
_oelse = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _oelse;
}
DLLExport
modelica_metatype omc_Algorithm_optimizeIf(threadData_t *threadData, modelica_metatype _icond, modelica_metatype _istmts, modelica_metatype _iels, modelica_metatype _isource, modelica_boolean *out_changed)
{
modelica_metatype _ostmts = NULL;
modelica_boolean _changed;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_metatype tmp4_4;
tmp4_1 = _icond;
tmp4_2 = _istmts;
tmp4_3 = _iels;
tmp4_4 = _isource;
{
modelica_metatype _stmts = NULL;
modelica_metatype _els = NULL;
modelica_metatype _source = NULL;
modelica_metatype _cond = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
if (1 != tmp7) goto tmp3_end;
_stmts = tmp4_2;
tmpMeta[0+0] = _stmts;
tmp1_c1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_integer tmp9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp9 = mmc_unbox_integer(tmpMeta8);
if (0 != tmp9) goto tmp3_end;
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = tmpMeta10;
tmp1_c1 = 1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_integer tmp13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp13 = mmc_unbox_integer(tmpMeta12);
if (0 != tmp13) goto tmp3_end;
_stmts = tmpMeta11;
tmpMeta[0+0] = _stmts;
tmp1_c1 = 1;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_integer tmp18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,3) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp18 = mmc_unbox_integer(tmpMeta17);
if (0 != tmp18) goto tmp3_end;
_cond = tmpMeta14;
_stmts = tmpMeta15;
_els = tmpMeta16;
_source = tmp4_4;
_ostmts = omc_Algorithm_optimizeIf(threadData, _cond, _stmts, _els, _source, NULL);
tmpMeta[0+0] = _ostmts;
tmp1_c1 = 1;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
tmpMeta20 = mmc_mk_box5(6, &DAE_Statement_STMT__IF__desc, _icond, _istmts, _iels, _isource);
tmpMeta19 = mmc_mk_cons(tmpMeta20, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = tmpMeta19;
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
_ostmts = tmpMeta[0+0];
_changed = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_changed) { *out_changed = _changed; }
return _ostmts;
}
modelica_metatype boxptr_Algorithm_optimizeIf(threadData_t *threadData, modelica_metatype _icond, modelica_metatype _istmts, modelica_metatype _iels, modelica_metatype _isource, modelica_metatype *out_changed)
{
modelica_boolean _changed;
modelica_metatype _ostmts = NULL;
_ostmts = omc_Algorithm_optimizeIf(threadData, _icond, _istmts, _iels, _isource, &_changed);
if (out_changed) { *out_changed = mmc_mk_icon(_changed); }
return _ostmts;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Algorithm_makeElseFromBranches(threadData_t *threadData, modelica_metatype _inTpl)
{
modelica_metatype _outElse = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inTpl;
{
modelica_metatype _b = NULL;
modelica_metatype _else_ = NULL;
modelica_metatype _e = NULL;
modelica_metatype _xs = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta1 = _OMC_LIT25;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_integer tmp10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,3,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmp10 = mmc_unbox_integer(tmpMeta9);
if (1 != tmp10) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (!listEmpty(tmpMeta7)) goto tmp3_end;
_b = tmpMeta11;
tmpMeta12 = mmc_mk_box2(5, &DAE_Else_ELSE__desc, _b);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta13 = MMC_CAR(tmp4_1);
tmpMeta14 = MMC_CDR(tmp4_1);
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 1));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
_e = tmpMeta15;
_b = tmpMeta16;
_xs = tmpMeta14;
_else_ = omc_Algorithm_makeElseFromBranches(threadData, _xs);
tmpMeta17 = mmc_mk_box4(4, &DAE_Else_ELSEIF__desc, _e, _b, _else_);
tmpMeta1 = tmpMeta17;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outElse = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outElse;
}
DLLExport
modelica_metatype omc_Algorithm_makeIfFromBranches(threadData_t *threadData, modelica_metatype _branches, modelica_metatype _source)
{
modelica_metatype _outStatements = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _branches;
{
modelica_metatype _else_ = NULL;
modelica_metatype _e = NULL;
modelica_metatype _br = NULL;
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
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_e = tmpMeta9;
_br = tmpMeta10;
_rest = tmpMeta8;
_else_ = omc_Algorithm_makeElseFromBranches(threadData, _rest);
tmpMeta12 = mmc_mk_box5(6, &DAE_Statement_STMT__IF__desc, _e, _br, _else_, _source);
tmpMeta11 = mmc_mk_cons(tmpMeta12, MMC_REFSTRUCTLIT(mmc_nil));
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
_outStatements = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStatements;
}
DLLExport
modelica_metatype omc_Algorithm_makeIf(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inProperties, modelica_metatype _inTrueBranch, modelica_metatype _inElseIfBranches, modelica_metatype _inElseBranch, modelica_metatype _source)
{
modelica_metatype _outStatements = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;volatile modelica_metatype tmp4_5;
tmp4_1 = _inExp;
tmp4_2 = _inProperties;
tmp4_3 = _inTrueBranch;
tmp4_4 = _inElseIfBranches;
tmp4_5 = _inElseBranch;
{
modelica_metatype _else_ = NULL;
modelica_metatype _e = NULL;
modelica_metatype _tb = NULL;
modelica_metatype _fb = NULL;
modelica_metatype _eib = NULL;
modelica_string _e_str = NULL;
modelica_string _t_str = NULL;
modelica_metatype _t = NULL;
modelica_metatype _prop = NULL;
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
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
if (1 != tmp7) goto tmp3_end;
_tb = tmp4_3;
tmp4 += 2;
tmpMeta1 = _tb;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_integer tmp9;
if (!listEmpty(tmp4_4)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp9 = mmc_unbox_integer(tmpMeta8);
if (0 != tmp9) goto tmp3_end;
_fb = tmp4_5;
tmp4 += 1;
tmpMeta1 = _fb;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_integer tmp16;
if (listEmpty(tmp4_4)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_4);
tmpMeta11 = MMC_CDR(tmp4_4);
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 1));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp16 = mmc_unbox_integer(tmpMeta15);
if (0 != tmp16) goto tmp3_end;
_e = tmpMeta12;
_prop = tmpMeta13;
_tb = tmpMeta14;
_eib = tmpMeta11;
_fb = tmp4_5;
tmpMeta1 = omc_Algorithm_makeIf(threadData, _e, _prop, _tb, _eib, _fb, _source);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_t = tmpMeta17;
_e = tmp4_1;
_tb = tmp4_3;
_eib = tmp4_4;
_fb = tmp4_5;
_e = omc_Types_matchType(threadData, _e, _t, _OMC_LIT26, 1, NULL);
_else_ = omc_Algorithm_makeElse(threadData, _eib, _fb, _source);
tmpMeta19 = mmc_mk_box5(6, &DAE_Statement_STMT__IF__desc, _e, _tb, _else_, _source);
tmpMeta18 = mmc_mk_cons(tmpMeta19, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta18;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_t = tmpMeta20;
_e = tmp4_1;
_e_str = omc_ExpressionDump_printExpStr(threadData, _e);
_t_str = omc_Types_unparseTypeNoAttr(threadData, _t);
tmpMeta21 = mmc_mk_cons(_e_str, mmc_mk_cons(_t_str, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT29, tmpMeta21, omc_ElementSource_getElementSourceFileInfo(threadData, _source));
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
_outStatements = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStatements;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Algorithm_getPropExpType(threadData_t *threadData, modelica_metatype _p)
{
modelica_metatype _t = NULL;
modelica_metatype _ty = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ty = omc_Types_getPropType(threadData, _p);
_t = omc_Types_simplifyType(threadData, _ty);
_return: OMC_LABEL_UNUSED
return _t;
}
DLLExport
modelica_metatype omc_Algorithm_makeTupleAssignment(threadData_t *threadData, modelica_metatype _inExpExpLst, modelica_metatype _inTypesPropertiesLst, modelica_metatype _inExp, modelica_metatype _inProperties, modelica_metatype _initial_, modelica_metatype _source)
{
modelica_metatype _outStatement = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;volatile modelica_metatype tmp4_5;
tmp4_1 = _inExpExpLst;
tmp4_2 = _inTypesPropertiesLst;
tmp4_3 = _inExp;
tmp4_4 = _inProperties;
tmp4_5 = _initial_;
{
modelica_metatype _bvals = NULL;
modelica_metatype _sl = NULL;
modelica_string _s = NULL;
modelica_string _lhs_str = NULL;
modelica_string _rhs_str = NULL;
modelica_string _str1 = NULL;
modelica_string _str2 = NULL;
modelica_string _strInitial = NULL;
modelica_metatype _lhs = NULL;
modelica_metatype _expl = NULL;
modelica_metatype _lprop = NULL;
modelica_metatype _lhprops = NULL;
modelica_metatype _rhs = NULL;
modelica_metatype _rprop = NULL;
modelica_metatype _lhrtypes = NULL;
modelica_metatype _tpl = NULL;
modelica_metatype _ty = NULL;
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
modelica_metatype tmpMeta8;
_lhs = tmp4_1;
_lprop = tmp4_2;
_rhs = tmp4_3;
_bvals = omc_List_map(threadData, _lprop, boxvar_Types_propAnyConst);
tmpMeta6 = omc_List_reduce(threadData, _bvals, boxvar_Types_constOr);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,0) == 0) goto goto_2;
_sl = omc_List_map(threadData, _lhs, boxvar_ExpressionDump_printExpStr);
_s = stringDelimitList(_sl, _OMC_LIT30);
tmpMeta7 = mmc_mk_cons(_OMC_LIT31, mmc_mk_cons(_s, mmc_mk_cons(_OMC_LIT32, MMC_REFSTRUCTLIT(mmc_nil))));
_lhs_str = stringAppendList(tmpMeta7);
_rhs_str = omc_ExpressionDump_printExpStr(threadData, _rhs);
tmpMeta8 = mmc_mk_cons(_lhs_str, mmc_mk_cons(_rhs_str, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT35, tmpMeta8, omc_ElementSource_getElementSourceFileInfo(threadData, _source));
goto goto_2;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_5,1,0) == 0) goto tmp3_end;
_lhs = tmp4_1;
_lprop = tmp4_2;
_rhs = tmp4_3;
_bvals = omc_List_map(threadData, _lprop, boxvar_Types_propAnyConst);
tmpMeta9 = omc_List_reduce(threadData, _bvals, boxvar_Types_constOr);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,1,0) == 0) goto goto_2;
_sl = omc_List_map(threadData, _lhs, boxvar_ExpressionDump_printExpStr);
_s = stringDelimitList(_sl, _OMC_LIT30);
tmpMeta10 = mmc_mk_cons(_OMC_LIT31, mmc_mk_cons(_s, mmc_mk_cons(_OMC_LIT32, MMC_REFSTRUCTLIT(mmc_nil))));
_lhs_str = stringAppendList(tmpMeta10);
_rhs_str = omc_ExpressionDump_printExpStr(threadData, _rhs);
tmpMeta11 = mmc_mk_cons(_lhs_str, mmc_mk_cons(_rhs_str, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT38, tmpMeta11, omc_ElementSource_getElementSourceFileInfo(threadData, _source));
goto goto_2;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,0,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,14,2) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
_ty = tmpMeta12;
_tpl = tmpMeta13;
_expl = tmp4_1;
_lhprops = tmp4_2;
_rhs = tmp4_3;
tmp4 += 1;
omc_Algorithm_checkLHSWritable(threadData, _expl, _lhprops, _rhs, _source);
_lhrtypes = omc_List_map(threadData, _lhprops, boxvar_Types_getPropType);
omc_Types_matchTypeTupleCall(threadData, _rhs, _tpl, _lhrtypes);
tmpMeta1 = omc_Algorithm_makeTupleAssignmentNoTypeCheck(threadData, _ty, _expl, _rhs, _source);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,1,2) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,14,2) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,1,1) == 0) goto tmp3_end;
_ty = tmpMeta14;
_tpl = tmpMeta15;
_expl = tmp4_1;
_lhprops = tmp4_2;
_rhs = tmp4_3;
omc_Algorithm_checkLHSWritable(threadData, _expl, _lhprops, _rhs, _source);
_lhrtypes = omc_List_map(threadData, _lhprops, boxvar_Types_getPropType);
omc_Types_matchTypeTupleCall(threadData, _rhs, _tpl, _lhrtypes);
tmpMeta1 = omc_Algorithm_makeTupleAssignmentNoTypeCheck(threadData, _ty, _expl, _rhs, _source);
goto tmp3_done;
}
case 4: {
modelica_boolean tmp17;
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
_lhs = tmp4_1;
_lprop = tmp4_2;
_rhs = tmp4_3;
_rprop = tmp4_4;
tmp17 = omc_Flags_isSet(threadData, _OMC_LIT42);
if (1 != tmp17) goto goto_2;
_sl = omc_List_map(threadData, _lhs, boxvar_ExpressionDump_printExpStr);
_s = stringDelimitList(_sl, _OMC_LIT30);
tmpMeta18 = mmc_mk_cons(_OMC_LIT31, mmc_mk_cons(_s, mmc_mk_cons(_OMC_LIT32, MMC_REFSTRUCTLIT(mmc_nil))));
_lhs_str = stringAppendList(tmpMeta18);
_rhs_str = omc_ExpressionDump_printExpStr(threadData, _rhs);
_str1 = stringDelimitList(omc_List_map(threadData, _lprop, boxvar_Types_printPropStr), _OMC_LIT30);
_str2 = omc_Types_printPropStr(threadData, _rprop);
_strInitial = omc_SCodeDump_printInitialStr(threadData, _initial_);
tmpMeta19 = stringAppend(_OMC_LIT43,_lhs_str);
tmpMeta20 = stringAppend(tmpMeta19,_OMC_LIT44);
tmpMeta21 = stringAppend(tmpMeta20,_rhs_str);
tmpMeta22 = stringAppend(tmpMeta21,_OMC_LIT45);
tmpMeta23 = stringAppend(tmpMeta22,_str1);
tmpMeta24 = stringAppend(tmpMeta23,_OMC_LIT46);
tmpMeta25 = stringAppend(tmpMeta24,_str2);
tmpMeta26 = stringAppend(tmpMeta25,_OMC_LIT47);
tmpMeta27 = stringAppend(tmpMeta26,_strInitial);
tmpMeta28 = stringAppend(tmpMeta27,_OMC_LIT48);
omc_Debug_traceln(threadData, tmpMeta28);
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
_outStatement = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStatement;
}
DLLExport
void omc_Algorithm_checkLHSWritable(threadData_t *threadData, modelica_metatype _lhs, modelica_metatype _props, modelica_metatype _rhs, modelica_metatype _source)
{
modelica_metatype _ty = NULL;
modelica_integer _i;
modelica_string _c = NULL;
modelica_string _l = NULL;
modelica_string _r = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta14;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_i = ((modelica_integer) 1);
{
modelica_metatype _p;
for (tmpMeta1 = _props; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_p = MMC_CAR(tmpMeta1);
{
modelica_metatype tmp4_1;
tmp4_1 = _p;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,2,0) == 0) goto tmp3_end;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,0) == 0) goto tmp3_end;
tmpMeta8 = mmc_mk_cons(_OMC_LIT31, mmc_mk_cons(stringDelimitList(omc_List_map(threadData, _lhs, boxvar_ExpressionDump_printExpStr), _OMC_LIT30), mmc_mk_cons(_OMC_LIT32, MMC_REFSTRUCTLIT(mmc_nil))));
_l = stringAppendList(tmpMeta8);
_r = omc_ExpressionDump_printExpStr(threadData, _rhs);
tmpMeta9 = mmc_mk_cons(_l, mmc_mk_cons(_r, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT35, tmpMeta9, omc_ElementSource_getElementSourceFileInfo(threadData, _source));
goto goto_2;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,1,0) == 0) goto tmp3_end;
_ty = tmpMeta10;
if(omc_Types_getFixedVarAttributeParameterOrConstant(threadData, _ty))
{
tmpMeta12 = mmc_mk_cons(_OMC_LIT31, mmc_mk_cons(stringDelimitList(omc_List_map(threadData, _lhs, boxvar_ExpressionDump_printExpStr), _OMC_LIT30), mmc_mk_cons(_OMC_LIT32, MMC_REFSTRUCTLIT(mmc_nil))));
_l = stringAppendList(tmpMeta12);
_r = omc_ExpressionDump_printExpStr(threadData, _rhs);
_c = omc_ExpressionDump_printExpStr(threadData, listGet(_lhs, _i));
tmpMeta13 = mmc_mk_cons(_c, mmc_mk_cons(_l, mmc_mk_cons(_r, MMC_REFSTRUCTLIT(mmc_nil))));
omc_Error_addSourceMessage(threadData, _OMC_LIT51, tmpMeta13, omc_ElementSource_getElementSourceFileInfo(threadData, _source));
goto goto_2;
}
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
;
_i = ((modelica_integer) 1) + _i;
}
}
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_metatype omc_Algorithm_makeAssignmentsList(threadData_t *threadData, modelica_metatype _lhsExps, modelica_metatype _lhsProps, modelica_metatype _rhsExps, modelica_metatype _rhsProps, modelica_metatype _attributes, modelica_metatype _initial_, modelica_metatype _source)
{
modelica_metatype _assignments = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_metatype tmp4_4;
tmp4_1 = _lhsExps;
tmp4_2 = _lhsProps;
tmp4_3 = _rhsExps;
tmp4_4 = _rhsProps;
{
modelica_metatype _lhs = NULL;
modelica_metatype _rhs = NULL;
modelica_metatype _rest_lhs = NULL;
modelica_metatype _rest_rhs = NULL;
modelica_metatype _lhs_prop = NULL;
modelica_metatype _rhs_prop = NULL;
modelica_metatype _rest_lhs_prop = NULL;
modelica_metatype _rest_rhs_prop = NULL;
modelica_metatype _ass = NULL;
modelica_metatype _rest_ass = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
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
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_2);
tmpMeta8 = MMC_CDR(tmp4_2);
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmp4_3);
tmpMeta10 = MMC_CDR(tmp4_3);
if (listEmpty(tmp4_4)) goto tmp3_end;
tmpMeta11 = MMC_CAR(tmp4_4);
tmpMeta12 = MMC_CDR(tmp4_4);
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta13 = MMC_CAR(tmp4_1);
tmpMeta14 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,6,2) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,4,0) == 0) goto tmp3_end;
_rest_lhs_prop = tmpMeta8;
_rest_rhs = tmpMeta10;
_rest_rhs_prop = tmpMeta12;
_rest_lhs = tmpMeta14;
_lhsExps = _rest_lhs;
_lhsProps = _rest_lhs_prop;
_rhsExps = _rest_rhs;
_rhsProps = _rest_rhs_prop;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmp4_1);
tmpMeta17 = MMC_CDR(tmp4_1);
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta18 = MMC_CAR(tmp4_2);
tmpMeta19 = MMC_CDR(tmp4_2);
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta20 = MMC_CAR(tmp4_3);
tmpMeta21 = MMC_CDR(tmp4_3);
if (listEmpty(tmp4_4)) goto tmp3_end;
tmpMeta22 = MMC_CAR(tmp4_4);
tmpMeta23 = MMC_CDR(tmp4_4);
_lhs = tmpMeta16;
_rest_lhs = tmpMeta17;
_lhs_prop = tmpMeta18;
_rest_lhs_prop = tmpMeta19;
_rhs = tmpMeta20;
_rest_rhs = tmpMeta21;
_rhs_prop = tmpMeta22;
_rest_rhs_prop = tmpMeta23;
_ass = omc_Algorithm_makeAssignment(threadData, _lhs, _lhs_prop, _rhs, _rhs_prop, _attributes, _initial_, _source);
_rest_ass = omc_Algorithm_makeAssignmentsList(threadData, _rest_lhs, _rest_lhs_prop, _rest_rhs, _rest_rhs_prop, _attributes, _initial_, _source);
tmpMeta24 = mmc_mk_cons(_ass, _rest_ass);
tmpMeta1 = tmpMeta24;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_assignments = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _assignments;
}
DLLExport
modelica_metatype omc_Algorithm_makeSimpleAssignment(threadData_t *threadData, modelica_metatype _inTpl, modelica_metatype _source)
{
modelica_metatype _outStmt = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _tp = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inTpl;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta2,6,2) == 0) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 3));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_e1 = tmpMeta2;
_tp = tmpMeta3;
_e2 = tmpMeta4;
tmpMeta5 = mmc_mk_box5(3, &DAE_Statement_STMT__ASSIGN__desc, _tp, _e1, _e2, _source);
_outStmt = tmpMeta5;
_return: OMC_LABEL_UNUSED
return _outStmt;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Algorithm_makeAssignment2(threadData_t *threadData, modelica_metatype _lhs, modelica_metatype _lhprop, modelica_metatype _rhs, modelica_metatype _rhprop, modelica_metatype _source)
{
modelica_metatype _outStatement = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _lhs;
{
modelica_metatype _rhs_1 = NULL;
modelica_metatype _e3 = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _t = NULL;
modelica_metatype _ty = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
if (!(!omc_Types_isPropArray(threadData, _lhprop))) goto tmp3_end;
_rhs_1 = omc_Types_matchProp(threadData, _rhs, _rhprop, _lhprop, 1, NULL);
_t = omc_Algorithm_getPropExpType(threadData, _lhprop);
{
modelica_metatype tmp8_1;
tmp8_1 = _rhs_1;
{
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
modelica_integer tmp17;
modelica_boolean tmp18;
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,13,3) == 0) goto tmp7_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,1,1) == 0) goto tmp7_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
if (10 != MMC_STRLEN(tmpMeta11) || strcmp(MMC_STRINGDATA(_OMC_LIT61), MMC_STRINGDATA(tmpMeta11)) != 0) goto tmp7_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 3));
if (listEmpty(tmpMeta12)) goto tmp7_end;
tmpMeta13 = MMC_CAR(tmpMeta12);
tmpMeta14 = MMC_CDR(tmpMeta12);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,6,2) == 0) goto tmp7_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 4));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 4));
tmp17 = mmc_unbox_integer(tmpMeta16);
if (1 != tmp17) goto tmp7_end;
_e1 = tmpMeta13;
if (!omc_Expression_expEqual(threadData, _lhs, _e1)) goto tmp7_end;
{
modelica_boolean __omcQ_24tmpVar1;
modelica_boolean __omcQ_24tmpVar0;
modelica_integer tmp19;
modelica_metatype _comment_loopVar = 0;
modelica_metatype _comment;
_comment_loopVar = omc_ElementSource_getComments(threadData, _source);
__omcQ_24tmpVar1 = 0;
while(1) {
tmp19 = 1;
if (!listEmpty(_comment_loopVar)) {
_comment = MMC_CAR(_comment_loopVar);
_comment_loopVar = MMC_CDR(_comment_loopVar);
tmp19--;
}
if (tmp19 == 0) {
__omcQ_24tmpVar0 = omc_SCodeUtil_commentHasBooleanNamedAnnotation(threadData, _comment, _OMC_LIT60);
__omcQ_24tmpVar1 = (__omcQ_24tmpVar0 || __omcQ_24tmpVar1);
} else if (tmp19 == 1) {
break;
} else {
goto goto_6;
}
}
tmp18 = __omcQ_24tmpVar1;
}
if((omc_Flags_isSet(threadData, _OMC_LIT59) && (!tmp18)))
{
tmpMeta20 = mmc_mk_cons(omc_ExpressionDump_printExpStr(threadData, _e1), MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT55, tmpMeta20, omc_ElementSource_getElementSourceFileInfo(threadData, _source));
goto goto_6;
}
goto tmp7_done;
}
case 1: {
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
;
tmpMeta21 = mmc_mk_box5(3, &DAE_Statement_STMT__ASSIGN__desc, _t, _lhs, _rhs_1, _source);
tmpMeta1 = tmpMeta21;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
_rhs_1 = omc_Types_matchProp(threadData, _rhs, _rhprop, _lhprop, 0, NULL);
_ty = omc_Types_getPropType(threadData, _lhprop);
_t = omc_Types_simplifyType(threadData, _ty);
tmpMeta22 = mmc_mk_box5(5, &DAE_Statement_STMT__ASSIGN__ARR__desc, _t, _lhs, _rhs_1, _source);
tmpMeta1 = tmpMeta22;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,2) == 0) goto tmp3_end;
_e3 = tmp4_1;
_rhs_1 = omc_Types_matchProp(threadData, _rhs, _rhprop, _lhprop, 1, NULL);
_t = omc_Algorithm_getPropExpType(threadData, _lhprop);
tmpMeta23 = mmc_mk_box5(3, &DAE_Statement_STMT__ASSIGN__desc, _t, _e3, _rhs_1, _source);
tmpMeta1 = tmpMeta23;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outStatement = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStatement;
}
DLLExport
modelica_metatype omc_Algorithm_makeAssignment(threadData_t *threadData, modelica_metatype _inExp1, modelica_metatype _inProperties2, modelica_metatype _inExp3, modelica_metatype _inProperties4, modelica_metatype _inAttributes, modelica_metatype _initial_, modelica_metatype _source)
{
modelica_metatype _outStatement = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;volatile modelica_metatype tmp4_5;volatile modelica_metatype tmp4_6;
tmp4_1 = _inExp1;
tmp4_2 = _inProperties2;
tmp4_3 = _inExp3;
tmp4_4 = _inProperties4;
tmp4_5 = _inAttributes;
tmp4_6 = _initial_;
{
modelica_string _lhs_str = NULL;
modelica_string _rhs_str = NULL;
modelica_string _lt_str = NULL;
modelica_string _rt_str = NULL;
modelica_metatype _lhs = NULL;
modelica_metatype _rhs = NULL;
modelica_metatype _lprop = NULL;
modelica_metatype _rprop = NULL;
modelica_metatype _lhprop = NULL;
modelica_metatype _rhprop = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _lt = NULL;
modelica_metatype _rt = NULL;
modelica_metatype _info = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,4,0) == 0) goto tmp3_end;
_rhs = tmp4_3;
tmpMeta7 = mmc_mk_box3(14, &DAE_Statement_STMT__NORETCALL__desc, _rhs, _source);
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_boolean tmp10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,1,0) == 0) goto tmp3_end;
_lhs = tmp4_1;
_cr = tmpMeta8;
_lhprop = tmp4_2;
_rhs = tmp4_3;
_rhprop = tmp4_4;
tmpMeta9 = omc_Types_propAnyConst(threadData, _lhprop);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,1,0) == 0) goto goto_2;
tmp10 = omc_ComponentReference_isRecord(threadData, _cr);
if (1 != tmp10) goto goto_2;
tmpMeta1 = omc_Algorithm_makeAssignment2(threadData, _lhs, _lhprop, _rhs, _rhprop, _source);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,1,0) == 0) goto tmp3_end;
_lhs = tmp4_1;
_lprop = tmp4_2;
_rhs = tmp4_3;
tmpMeta11 = omc_Types_propAnyConst(threadData, _lprop);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,1,0) == 0) goto goto_2;
_lhs_str = omc_ExpressionDump_printExpStr(threadData, _lhs);
_rhs_str = omc_ExpressionDump_printExpStr(threadData, _rhs);
tmpMeta12 = mmc_mk_cons(_lhs_str, mmc_mk_cons(_rhs_str, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT38, tmpMeta12, omc_ElementSource_getElementSourceFileInfo(threadData, _source));
goto goto_2;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_5), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,3,0) == 0) goto tmp3_end;
_lhs = tmp4_1;
_lhs_str = omc_ExpressionDump_printExpStr(threadData, _lhs);
tmpMeta14 = mmc_mk_cons(_OMC_LIT65, mmc_mk_cons(_lhs_str, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT64, tmpMeta14, omc_ElementSource_getElementSourceFileInfo(threadData, _source));
goto goto_2;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,0,0) == 0) goto tmp3_end;
_lhs = tmp4_1;
_lhprop = tmp4_2;
_rhs = tmp4_3;
_rhprop = tmp4_4;
tmpMeta15 = omc_Types_propAnyConst(threadData, _lhprop);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,1,0) == 0) goto goto_2;
tmpMeta1 = omc_Algorithm_makeAssignment2(threadData, _lhs, _lhprop, _rhs, _rhprop, _source);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta16;
_lhs = tmp4_1;
_lhprop = tmp4_2;
_rhs = tmp4_3;
_rhprop = tmp4_4;
tmpMeta16 = omc_Types_propAnyConst(threadData, _lhprop);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,2,0) == 0) goto goto_2;
tmpMeta1 = omc_Algorithm_makeAssignment2(threadData, _lhs, _lhprop, _rhs, _rhprop, _source);
goto tmp3_done;
}
case 6: {
modelica_boolean tmp17;
modelica_metatype tmpMeta18;
_lhs = tmp4_1;
_lprop = tmp4_2;
_rhs = tmp4_3;
_rprop = tmp4_4;
_lt = omc_Types_getPropType(threadData, _lprop);
_rt = omc_Types_getPropType(threadData, _rprop);
tmp17 = omc_Types_equivtypes(threadData, _lt, _rt);
if (0 != tmp17) goto goto_2;
_lhs_str = omc_ExpressionDump_printExpStr(threadData, _lhs);
_rhs_str = omc_ExpressionDump_printExpStr(threadData, _rhs);
_lt_str = omc_Types_unparseTypeNoAttr(threadData, _lt);
_rt_str = omc_Types_unparseTypeNoAttr(threadData, _rt);
_info = omc_ElementSource_getElementSourceFileInfo(threadData, _source);
omc_Types_typeErrorSanityCheck(threadData, _lt_str, _rt_str, _info);
tmpMeta18 = mmc_mk_cons(_lhs_str, mmc_mk_cons(_rhs_str, mmc_mk_cons(_lt_str, mmc_mk_cons(_rt_str, MMC_REFSTRUCTLIT(mmc_nil)))));
omc_Error_addSourceMessage(threadData, _OMC_LIT68, tmpMeta18, _info);
goto goto_2;
goto tmp3_done;
}
case 7: {
modelica_boolean tmp19;
_lhs = tmp4_1;
_rhs = tmp4_3;
tmp19 = omc_Flags_isSet(threadData, _OMC_LIT42);
if (1 != tmp19) goto goto_2;
omc_Debug_traceln(threadData, _OMC_LIT69);
omc_Debug_trace(threadData, _OMC_LIT70);
omc_Debug_trace(threadData, omc_ExpressionDump_printExpStr(threadData, _lhs));
omc_Debug_trace(threadData, _OMC_LIT71);
omc_Debug_traceln(threadData, omc_ExpressionDump_printExpStr(threadData, _rhs));
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
_outStatement = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStatement;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Algorithm_makeTupleAssignmentNoTypeCheck2(threadData_t *threadData, modelica_boolean _allWild, modelica_boolean _singleAssign, modelica_metatype _ty, modelica_metatype _lhs, modelica_metatype _rhs, modelica_metatype _source)
{
modelica_metatype _outStatement = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean tmp4_1;modelica_boolean tmp4_2;modelica_metatype tmp4_3;modelica_metatype tmp4_4;
tmp4_1 = _allWild;
tmp4_2 = _singleAssign;
tmp4_3 = _ty;
tmp4_4 = _lhs;
{
modelica_metatype _ty1 = NULL;
modelica_metatype _lhs1 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (1 != tmp4_1) goto tmp3_end;
tmpMeta6 = mmc_mk_box3(14, &DAE_Statement_STMT__NORETCALL__desc, _rhs, _source);
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
modelica_metatype tmpMeta13;
if (1 != tmp4_2) goto tmp3_end;
if (listEmpty(tmp4_4)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_4);
tmpMeta8 = MMC_CDR(tmp4_4);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,14,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (listEmpty(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,6,2) == 0) goto tmp3_end;
_lhs1 = tmpMeta7;
_ty1 = tmpMeta10;
tmpMeta12 = mmc_mk_box4(25, &DAE_Exp_TSUB__desc, _rhs, mmc_mk_integer(((modelica_integer) 1)), _ty1);
tmpMeta13 = mmc_mk_box5(5, &DAE_Statement_STMT__ASSIGN__ARR__desc, _ty1, _lhs1, tmpMeta12, _source);
tmpMeta1 = tmpMeta13;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
if (1 != tmp4_2) goto tmp3_end;
if (listEmpty(tmp4_4)) goto tmp3_end;
tmpMeta14 = MMC_CAR(tmp4_4);
tmpMeta15 = MMC_CDR(tmp4_4);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,14,2) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (listEmpty(tmpMeta16)) goto tmp3_end;
tmpMeta17 = MMC_CAR(tmpMeta16);
tmpMeta18 = MMC_CDR(tmpMeta16);
_lhs1 = tmpMeta14;
_ty1 = tmpMeta17;
tmpMeta19 = mmc_mk_box4(25, &DAE_Exp_TSUB__desc, _rhs, mmc_mk_integer(((modelica_integer) 1)), _ty1);
tmpMeta20 = mmc_mk_box5(3, &DAE_Statement_STMT__ASSIGN__desc, _ty1, _lhs1, tmpMeta19, _source);
tmpMeta1 = tmpMeta20;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta21;
tmpMeta21 = mmc_mk_box5(4, &DAE_Statement_STMT__TUPLE__ASSIGN__desc, _ty, _lhs, _rhs, _source);
tmpMeta1 = tmpMeta21;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outStatement = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStatement;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Algorithm_makeTupleAssignmentNoTypeCheck2(threadData_t *threadData, modelica_metatype _allWild, modelica_metatype _singleAssign, modelica_metatype _ty, modelica_metatype _lhs, modelica_metatype _rhs, modelica_metatype _source)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outStatement = NULL;
tmp1 = mmc_unbox_integer(_allWild);
tmp2 = mmc_unbox_integer(_singleAssign);
_outStatement = omc_Algorithm_makeTupleAssignmentNoTypeCheck2(threadData, tmp1, tmp2, _ty, _lhs, _rhs, _source);
return _outStatement;
}
DLLExport
modelica_metatype omc_Algorithm_makeTupleAssignmentNoTypeCheck(threadData_t *threadData, modelica_metatype _ty, modelica_metatype _lhs, modelica_metatype _rhs, modelica_metatype _source)
{
modelica_metatype _outStatement = NULL;
modelica_boolean _b1;
modelica_boolean _b2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b1 = omc_List_mapBoolAnd(threadData, _lhs, boxvar_Expression_isWild);
_b2 = omc_List_mapBoolAnd(threadData, omc_List_restOrEmpty(threadData, _lhs), boxvar_Expression_isWild);
_outStatement = omc_Algorithm_makeTupleAssignmentNoTypeCheck2(threadData, _b1, _b2, _ty, _lhs, _rhs, _source);
_return: OMC_LABEL_UNUSED
return _outStatement;
}
DLLExport
modelica_metatype omc_Algorithm_makeArrayAssignmentNoTypeCheck(threadData_t *threadData, modelica_metatype _ty, modelica_metatype _lhs, modelica_metatype _rhs, modelica_metatype _source)
{
modelica_metatype _outStatement = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _lhs;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,4,0) == 0) goto tmp3_end;
tmpMeta7 = mmc_mk_box3(14, &DAE_Statement_STMT__NORETCALL__desc, _rhs, _source);
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
tmpMeta8 = mmc_mk_box5(5, &DAE_Statement_STMT__ASSIGN__ARR__desc, _ty, _lhs, _rhs, _source);
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
_outStatement = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStatement;
}
DLLExport
modelica_metatype omc_Algorithm_makeAssignmentNoTypeCheck(threadData_t *threadData, modelica_metatype _ty, modelica_metatype _lhs, modelica_metatype _rhs, modelica_metatype _source)
{
modelica_metatype _outStatement = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _lhs;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,4,0) == 0) goto tmp3_end;
tmpMeta7 = mmc_mk_box3(14, &DAE_Statement_STMT__NORETCALL__desc, _rhs, _source);
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,37,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,0) == 0) goto tmp3_end;
tmpMeta9 = mmc_mk_box3(14, &DAE_Statement_STMT__NORETCALL__desc, _rhs, _source);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
tmpMeta10 = mmc_mk_box5(3, &DAE_Statement_STMT__ASSIGN__desc, _ty, _lhs, _rhs, _source);
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
_outStatement = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStatement;
}
DLLExport
modelica_boolean omc_Algorithm_isNotAssertStatement(threadData_t *threadData, modelica_metatype _stmt)
{
modelica_boolean _res;
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_Algorithm_isNotAssertStatement(threadData_t *threadData, modelica_metatype _stmt)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_Algorithm_isNotAssertStatement(threadData, _stmt);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_boolean omc_Algorithm_isReinitStatement(threadData_t *threadData, modelica_metatype _stmt)
{
modelica_boolean _res;
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_Algorithm_isReinitStatement(threadData_t *threadData, modelica_metatype _stmt)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_Algorithm_isReinitStatement(threadData, _stmt);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_boolean omc_Algorithm_algorithmEmpty(threadData_t *threadData, modelica_metatype _alg)
{
modelica_boolean _empty;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _alg;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
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
_empty = tmp1;
_return: OMC_LABEL_UNUSED
return _empty;
}
modelica_metatype boxptr_Algorithm_algorithmEmpty(threadData_t *threadData, modelica_metatype _alg)
{
modelica_boolean _empty;
modelica_metatype out_empty;
_empty = omc_Algorithm_algorithmEmpty(threadData, _alg);
out_empty = mmc_mk_icon(_empty);
return out_empty;
}
