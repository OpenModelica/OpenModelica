#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "FGraphBuild.c"
#endif
#include "omc_simulation_settings.h"
#include "FGraphBuild.h"
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT0,1,4) {&SCode_Visibility_PROTECTED__desc,}};
#define _OMC_LIT0 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "$match"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,6,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "$for"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,4,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "$ty"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,3,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,2,24) {&FCore_Data_ND__desc,MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "FGraphBuild.mkTypeNode: Error making type node: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,48,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data " in parent: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,12,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,1,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "$subs"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,5,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "$cnd"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,4,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "$it"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,3,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "$ref"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,4,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "$tydims"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,7,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "$dims"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,5,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data "$mod"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,4,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,1,20) {&Absyn_Exp_END__desc,}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "$imp"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,4,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT17,4,3) {&FCore_ImportTable_IMPORT__TABLE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT17 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT18,2,5) {&FCore_Data_IM__desc,_OMC_LIT17}};
#define _OMC_LIT18 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT18)
#define _OMC_LIT19_data "$definedUnits"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT19,13,_OMC_LIT19_data);
#define _OMC_LIT19 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT19)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT20,1,5) {&DAE_Mod_NOMOD__desc,}};
#define _OMC_LIT20 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT20)
#define _OMC_LIT21_data "$eq"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT21,3,_OMC_LIT21_data);
#define _OMC_LIT21 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "$ieq"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,4,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
#define _OMC_LIT23_data "$al"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT23,3,_OMC_LIT23_data);
#define _OMC_LIT23 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT23)
#define _OMC_LIT24_data "$ial"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT24,4,_OMC_LIT24_data);
#define _OMC_LIT24 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT24)
#define _OMC_LIT25_data "$opt"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT25,4,_OMC_LIT25_data);
#define _OMC_LIT25 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "$ed"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,3,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data "$bnd"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,4,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data "FGraphBuild.mkModNode failed with: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,35,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data " mod: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,6,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT30,10,3) {&SCodeDump_SCodeDumpOptions_OPTIONS__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT30 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data "$cc"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,3,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT32,1,3) {&DAE_Prefix_NOPRE__desc,}};
#define _OMC_LIT32 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT32)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT33,1,3) {&FCore_Status_VAR__UNTYPED__desc,}};
#define _OMC_LIT33 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT33)
#include "util/modelica.h"
#include "FGraphBuild_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_analyseStatementTraverser(threadData_t *threadData, modelica_metatype _inTuple);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraphBuild_analyseStatementTraverser,2,0) {(void*) boxptr_FGraphBuild_analyseStatementTraverser,0}};
#define boxvar_FGraphBuild_analyseStatementTraverser MMC_REFSTRUCTLIT(boxvar_lit_FGraphBuild_analyseStatementTraverser)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_analyseStatement(threadData_t *threadData, modelica_metatype _inStatement, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraphBuild_analyseStatement,2,0) {(void*) boxptr_FGraphBuild_analyseStatement,0}};
#define boxvar_FGraphBuild_analyseStatement MMC_REFSTRUCTLIT(boxvar_lit_FGraphBuild_analyseStatement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_analyseAlgorithm(threadData_t *threadData, modelica_metatype _inAlgorithm, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraphBuild_analyseAlgorithm,2,0) {(void*) boxptr_FGraphBuild_analyseAlgorithm,0}};
#define boxvar_FGraphBuild_analyseAlgorithm MMC_REFSTRUCTLIT(boxvar_lit_FGraphBuild_analyseAlgorithm)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_traverseExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTuple, modelica_metatype *out_outTuple);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraphBuild_traverseExp,2,0) {(void*) boxptr_FGraphBuild_traverseExp,0}};
#define boxvar_FGraphBuild_traverseExp MMC_REFSTRUCTLIT(boxvar_lit_FGraphBuild_traverseExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_analyseEEquationTraverser(threadData_t *threadData, modelica_metatype _inTuple);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraphBuild_analyseEEquationTraverser,2,0) {(void*) boxptr_FGraphBuild_analyseEEquationTraverser,0}};
#define boxvar_FGraphBuild_analyseEEquationTraverser MMC_REFSTRUCTLIT(boxvar_lit_FGraphBuild_analyseEEquationTraverser)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_analyseEquation(threadData_t *threadData, modelica_metatype _inEquation, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraphBuild_analyseEquation,2,0) {(void*) boxptr_FGraphBuild_analyseEquation,0}};
#define boxvar_FGraphBuild_analyseEquation MMC_REFSTRUCTLIT(boxvar_lit_FGraphBuild_analyseEquation)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_analyseExpTraverserExit(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTuple, modelica_metatype *out_outTuple);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraphBuild_analyseExpTraverserExit,2,0) {(void*) boxptr_FGraphBuild_analyseExpTraverserExit,0}};
#define boxvar_FGraphBuild_analyseExpTraverserExit MMC_REFSTRUCTLIT(boxvar_lit_FGraphBuild_analyseExpTraverserExit)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_analyseCref(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraphBuild_analyseCref,2,0) {(void*) boxptr_FGraphBuild_analyseCref,0}};
#define boxvar_FGraphBuild_analyseCref MMC_REFSTRUCTLIT(boxvar_lit_FGraphBuild_analyseCref)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_analyseExp2(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inRef, modelica_metatype _inKind, modelica_metatype _inGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraphBuild_analyseExp2,2,0) {(void*) boxptr_FGraphBuild_analyseExp2,0}};
#define boxvar_FGraphBuild_analyseExp2 MMC_REFSTRUCTLIT(boxvar_lit_FGraphBuild_analyseExp2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_analyseExpTraverserEnter(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTuple, modelica_metatype *out_outTuple);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraphBuild_analyseExpTraverserEnter,2,0) {(void*) boxptr_FGraphBuild_analyseExpTraverserEnter,0}};
#define boxvar_FGraphBuild_analyseExpTraverserEnter MMC_REFSTRUCTLIT(boxvar_lit_FGraphBuild_analyseExpTraverserEnter)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_analyseOptExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inRef, modelica_metatype _inKind, modelica_metatype _inGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraphBuild_analyseOptExp,2,0) {(void*) boxptr_FGraphBuild_analyseOptExp,0}};
#define boxvar_FGraphBuild_analyseOptExp MMC_REFSTRUCTLIT(boxvar_lit_FGraphBuild_analyseOptExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_analyseExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inRef, modelica_metatype _inKind, modelica_metatype _inGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraphBuild_analyseExp,2,0) {(void*) boxptr_FGraphBuild_analyseExp,0}};
#define boxvar_FGraphBuild_analyseExp MMC_REFSTRUCTLIT(boxvar_lit_FGraphBuild_analyseExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_mkClassChildren(threadData_t *threadData, modelica_string _name, modelica_metatype _inClassDef, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraphBuild_mkClassChildren,2,0) {(void*) boxptr_FGraphBuild_mkClassChildren,0}};
#define boxvar_FGraphBuild_mkClassChildren MMC_REFSTRUCTLIT(boxvar_lit_FGraphBuild_mkClassChildren)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_mkClassGraph(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraphBuild_mkClassGraph,2,0) {(void*) boxptr_FGraphBuild_mkClassGraph,0}};
#define boxvar_FGraphBuild_mkClassGraph MMC_REFSTRUCTLIT(boxvar_lit_FGraphBuild_mkClassGraph)
DLLExport
modelica_metatype omc_FGraphBuild_mkAssertNode(threadData_t *threadData, modelica_string _inName, modelica_string _inMessage, modelica_metatype _inParentRef, modelica_metatype _inGraph, modelica_metatype *out_outRef)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _outRef = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
{
modelica_metatype _n = NULL;
modelica_metatype _rn = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
_g = tmp4_1;
tmpMeta6 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta7 = mmc_mk_box2(26, &FCore_Data_ASSERT__desc, _inMessage);
_g = omc_FGraph_node(threadData, _g, _inName, tmpMeta6, tmpMeta7 ,&_n);
_rn = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _inName, _rn, 0);
tmpMeta[0+0] = _g;
tmpMeta[0+1] = _rn;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta[0+0];
_outRef = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outRef) { *out_outRef = _outRef; }
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkRefNode(threadData_t *threadData, modelica_string _inName, modelica_metatype _inTargetScope, modelica_metatype _inParentRef, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
{
modelica_metatype _n = NULL;
modelica_metatype _rn = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
_g = tmp4_1;
tmpMeta6 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta7 = mmc_mk_box2(23, &FCore_Data_REF__desc, _inTargetScope);
_g = omc_FGraph_node(threadData, _g, _inName, tmpMeta6, tmpMeta7 ,&_n);
_rn = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _inName, _rn, 0);
tmpMeta1 = _g;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_addMatchScope__helper(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inElements;
tmp4_2 = _inGraph;
{
modelica_metatype _element = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _g = NULL;
modelica_metatype _el = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_g = tmp4_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_element = tmpMeta8;
_rest = tmpMeta7;
_g = tmp4_2;
_el = omc_AbsynToSCode_translateElement(threadData, _element, _OMC_LIT0);
_g = omc_List_fold2(threadData, _el, boxvar_FGraphBuild_mkElementNode, _inParentRef, _inKind, _g);
_inElements = _rest;
_inGraph = _g;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmp4_1);
tmpMeta10 = MMC_CDR(tmp4_1);
_rest = tmpMeta10;
_g = tmp4_2;
_inElements = _rest;
_inGraph = _g;
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
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_addMatchScope(threadData_t *threadData, modelica_metatype _inMatchExp, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _n = NULL;
modelica_metatype _nr = NULL;
modelica_metatype _local_decls = NULL;
modelica_metatype _g = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta2 = mmc_mk_box2(17, &FCore_Data_MS__desc, _inMatchExp);
_g = omc_FGraph_node(threadData, _inGraph, _OMC_LIT1, tmpMeta1, tmpMeta2 ,&_n);
_nr = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _OMC_LIT1, _nr, 0);
tmpMeta3 = _inMatchExp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta3,21,5) == 0) MMC_THROW_INTERNAL();
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 4));
_local_decls = tmpMeta4;
_outGraph = omc_FGraphBuild_addMatchScope__helper(threadData, _local_decls, _nr, _inKind, _g);
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_addIterators__helper(threadData_t *threadData, modelica_metatype _inIterators, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inIterators;
tmp4_2 = _inGraph;
{
modelica_metatype _n = NULL;
modelica_metatype _nr = NULL;
modelica_string _name = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _i = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_g = tmp4_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_i = tmpMeta6;
_name = tmpMeta8;
_rest = tmpMeta7;
_g = tmp4_2;
tmpMeta9 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta10 = mmc_mk_box2(16, &FCore_Data_FI__desc, _i);
_g = omc_FGraph_node(threadData, _g, _name, tmpMeta9, tmpMeta10 ,&_n);
_nr = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _name, _nr, 0);
_inIterators = _rest;
_inGraph = _g;
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
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_addIterators(threadData_t *threadData, modelica_metatype _inIterators, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
{
modelica_metatype _g = NULL;
modelica_metatype _n = NULL;
modelica_metatype _nr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_g = tmp4_1;
_nr = omc_FNode_child(threadData, _inParentRef, _OMC_LIT2);
omc_FNode_addIteratorsToRef(threadData, _nr, _inIterators);
tmpMeta1 = omc_FGraphBuild_addIterators__helper(threadData, _inIterators, _nr, _inKind, _g);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
_g = tmp4_1;
tmpMeta6 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta7 = mmc_mk_box2(15, &FCore_Data_FS__desc, _inIterators);
_g = omc_FGraph_node(threadData, _g, _OMC_LIT2, tmpMeta6, tmpMeta7 ,&_n);
_nr = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _OMC_LIT2, _nr, 0);
tmpMeta1 = omc_FGraphBuild_addIterators__helper(threadData, _inIterators, _nr, _inKind, _g);
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
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_analyseStatementTraverser(threadData_t *threadData, modelica_metatype _inTuple)
{
modelica_metatype _outTuple = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inTuple;
{
modelica_metatype _ref = NULL;
modelica_metatype _stmt = NULL;
modelica_string _iter_name = NULL;
modelica_metatype _g = NULL;
modelica_metatype _k = NULL;
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
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,2,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 1));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
_stmt = tmpMeta6;
_iter_name = tmpMeta7;
_ref = tmpMeta9;
_k = tmpMeta10;
_g = tmpMeta11;
tmpMeta13 = mmc_mk_box4(3, &Absyn_ForIterator_ITERATOR__desc, _iter_name, mmc_mk_none(), mmc_mk_none());
tmpMeta12 = mmc_mk_cons(tmpMeta13, MMC_REFSTRUCTLIT(mmc_nil));
_g = omc_FGraphBuild_addIterators(threadData, tmpMeta12, _ref, _k, _g);
tmpMeta16 = mmc_mk_box3(0, _ref, _k, _g);
omc_SCodeUtil_traverseStatementExps(threadData, _stmt, boxvar_FGraphBuild_traverseExp, tmpMeta16, &tmpMeta14);
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 3));
_g = tmpMeta15;
tmpMeta17 = mmc_mk_box3(0, _ref, _k, _g);
tmpMeta18 = mmc_mk_box2(0, _stmt, tmpMeta17);
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
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta19,3,5) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 2));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 1));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 2));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 3));
_stmt = tmpMeta19;
_iter_name = tmpMeta20;
_ref = tmpMeta22;
_k = tmpMeta23;
_g = tmpMeta24;
tmpMeta26 = mmc_mk_box4(3, &Absyn_ForIterator_ITERATOR__desc, _iter_name, mmc_mk_none(), mmc_mk_none());
tmpMeta25 = mmc_mk_cons(tmpMeta26, MMC_REFSTRUCTLIT(mmc_nil));
_g = omc_FGraphBuild_addIterators(threadData, tmpMeta25, _ref, _k, _g);
tmpMeta29 = mmc_mk_box3(0, _ref, _k, _g);
omc_SCodeUtil_traverseStatementExps(threadData, _stmt, boxvar_FGraphBuild_traverseExp, tmpMeta29, &tmpMeta27);
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 3));
_g = tmpMeta28;
tmpMeta30 = mmc_mk_box3(0, _ref, _k, _g);
tmpMeta31 = mmc_mk_box2(0, _stmt, tmpMeta30);
tmpMeta1 = tmpMeta31;
goto tmp3_done;
}
case 2: {
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
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta33), 1));
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta33), 2));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta33), 3));
_stmt = tmpMeta32;
_ref = tmpMeta34;
_k = tmpMeta35;
_g = tmpMeta36;
omc_SCodeUtil_getStatementInfo(threadData, _stmt);
tmpMeta39 = mmc_mk_box3(0, _ref, _k, _g);
omc_SCodeUtil_traverseStatementExps(threadData, _stmt, boxvar_FGraphBuild_traverseExp, tmpMeta39, &tmpMeta37);
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 3));
_g = tmpMeta38;
tmpMeta40 = mmc_mk_box3(0, _ref, _k, _g);
tmpMeta41 = mmc_mk_box2(0, _stmt, tmpMeta40);
tmpMeta1 = tmpMeta41;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outTuple = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outTuple;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_analyseStatement(threadData_t *threadData, modelica_metatype _inStatement, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta4 = mmc_mk_box3(0, _inParentRef, _inKind, _inGraph);
tmpMeta5 = mmc_mk_box2(0, boxvar_FGraphBuild_analyseStatementTraverser, tmpMeta4);
omc_SCodeUtil_traverseStatements(threadData, _inStatement, tmpMeta5, &tmpMeta1);
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 3));
_outGraph = tmpMeta3;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_analyseAlgorithm(threadData_t *threadData, modelica_metatype _inAlgorithm, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _stmts = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inAlgorithm;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_stmts = tmpMeta2;
_outGraph = omc_List_fold2(threadData, _stmts, boxvar_FGraphBuild_analyseStatement, _inParentRef, _inKind, _inGraph);
_return: OMC_LABEL_UNUSED
return _outGraph;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_traverseExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTuple, modelica_metatype *out_outTuple)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outTuple = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outExp = omc_AbsynUtil_traverseExpBidir(threadData, _inExp, boxvar_FGraphBuild_analyseExpTraverserEnter, boxvar_FGraphBuild_analyseExpTraverserExit, _inTuple ,&_outTuple);
_return: OMC_LABEL_UNUSED
if (out_outTuple) { *out_outTuple = _outTuple; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_analyseEEquationTraverser(threadData_t *threadData, modelica_metatype _inTuple)
{
modelica_metatype _outTuple = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inTuple;
{
modelica_metatype _equ = NULL;
modelica_metatype _equf = NULL;
modelica_metatype _equr = NULL;
modelica_string _iter_name = NULL;
modelica_metatype _ref = NULL;
modelica_metatype _cref1 = NULL;
modelica_metatype _g = NULL;
modelica_metatype _k = NULL;
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
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,4,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 1));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
_equf = tmpMeta6;
_iter_name = tmpMeta7;
_ref = tmpMeta9;
_k = tmpMeta10;
_g = tmpMeta11;
tmpMeta13 = mmc_mk_box4(3, &Absyn_ForIterator_ITERATOR__desc, _iter_name, mmc_mk_none(), mmc_mk_none());
tmpMeta12 = mmc_mk_cons(tmpMeta13, MMC_REFSTRUCTLIT(mmc_nil));
_g = omc_FGraphBuild_addIterators(threadData, tmpMeta12, _ref, _k, _g);
tmpMeta16 = mmc_mk_box3(0, _ref, _k, _g);
tmpMeta17 = omc_SCodeUtil_traverseEEquationExps(threadData, _equf, boxvar_FGraphBuild_traverseExp, tmpMeta16, &tmpMeta14);
_equ = tmpMeta17;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 3));
_g = tmpMeta15;
tmpMeta18 = mmc_mk_box3(0, _ref, _k, _g);
tmpMeta19 = mmc_mk_box2(0, _equ, tmpMeta18);
tmpMeta1 = tmpMeta19;
goto tmp3_done;
}
case 1: {
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
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,8,4) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta21,2,1) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 2));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 1));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 2));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 3));
_equr = tmpMeta20;
_cref1 = tmpMeta22;
_ref = tmpMeta24;
_k = tmpMeta25;
_g = tmpMeta26;
_g = omc_FGraphBuild_analyseCref(threadData, _cref1, _ref, _k, _g);
tmpMeta29 = mmc_mk_box3(0, _ref, _k, _g);
tmpMeta30 = omc_SCodeUtil_traverseEEquationExps(threadData, _equr, boxvar_FGraphBuild_traverseExp, tmpMeta29, &tmpMeta27);
_equ = tmpMeta30;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 3));
_g = tmpMeta28;
tmpMeta31 = mmc_mk_box3(0, _ref, _k, _g);
tmpMeta32 = mmc_mk_box2(0, _equ, tmpMeta31);
tmpMeta1 = tmpMeta32;
goto tmp3_done;
}
case 2: {
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
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 1));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 2));
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 3));
_equ = tmpMeta33;
_ref = tmpMeta35;
_k = tmpMeta36;
_g = tmpMeta37;
omc_SCodeUtil_getEEquationInfo(threadData, _equ);
tmpMeta40 = mmc_mk_box3(0, _ref, _k, _g);
tmpMeta41 = omc_SCodeUtil_traverseEEquationExps(threadData, _equ, boxvar_FGraphBuild_traverseExp, tmpMeta40, &tmpMeta38);
_equ = tmpMeta41;
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta38), 3));
_g = tmpMeta39;
tmpMeta42 = mmc_mk_box3(0, _ref, _k, _g);
tmpMeta43 = mmc_mk_box2(0, _equ, tmpMeta42);
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
_outTuple = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outTuple;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_analyseEquation(threadData_t *threadData, modelica_metatype _inEquation, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _equ = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inEquation;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_equ = tmpMeta2;
tmpMeta6 = mmc_mk_box3(0, _inParentRef, _inKind, _inGraph);
tmpMeta7 = mmc_mk_box2(0, boxvar_FGraphBuild_analyseEEquationTraverser, tmpMeta6);
omc_SCodeUtil_traverseEEquations(threadData, _equ, tmpMeta7, &tmpMeta3);
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 2));
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta4), 3));
_outGraph = tmpMeta5;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_analyseExpTraverserExit(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTuple, modelica_metatype *out_outTuple)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outTuple = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outExp = _inExp;
_outTuple = _inTuple;
_return: OMC_LABEL_UNUSED
if (out_outTuple) { *out_outTuple = _outTuple; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_analyseCref(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inCref;
tmp4_2 = _inGraph;
{
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,0) == 0) goto tmp3_end;
_g = tmp4_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
_g = tmp4_2;
tmpMeta1 = omc_FGraphBuild_mkCrefNode(threadData, _inCref, _inParentRef, _inKind, _g);
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
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_analyseExp2(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _inGraph;
{
modelica_metatype _cref = NULL;
modelica_metatype _iters = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cref = tmpMeta6;
_g = tmp4_2;
tmpMeta1 = omc_FGraphBuild_analyseCref(threadData, _cref, _inRef, _inKind, _g);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
_iters = tmpMeta8;
_g = tmp4_2;
tmpMeta1 = omc_FGraphBuild_addIterators(threadData, _iters, _inRef, _inKind, _g);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,3) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cref = tmpMeta9;
_g = tmp4_2;
tmpMeta1 = omc_FGraphBuild_analyseCref(threadData, _cref, _inRef, _inKind, _g);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cref = tmpMeta10;
_g = tmp4_2;
tmpMeta1 = omc_FGraphBuild_analyseCref(threadData, _cref, _inRef, _inKind, _g);
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,5) == 0) goto tmp3_end;
_g = tmp4_2;
tmpMeta1 = omc_FGraphBuild_addMatchScope(threadData, _inExp, _inRef, _inKind, _g);
goto tmp3_done;
}
case 5: {
tmpMeta1 = _inGraph;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_analyseExpTraverserEnter(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTuple, modelica_metatype *out_outTuple)
{
modelica_metatype _exp = NULL;
modelica_metatype _outTuple = NULL;
modelica_metatype _ref = NULL;
modelica_metatype _k = NULL;
modelica_metatype _g = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inTuple;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_ref = tmpMeta2;
_k = tmpMeta3;
_g = tmpMeta4;
_g = omc_FGraphBuild_analyseExp2(threadData, _inExp, _ref, _k, _g);
_exp = _inExp;
tmpMeta5 = mmc_mk_box3(0, _ref, _k, _g);
_outTuple = tmpMeta5;
_return: OMC_LABEL_UNUSED
if (out_outTuple) { *out_outTuple = _outTuple; }
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_analyseOptExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _inGraph;
{
modelica_metatype _exp = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
_g = tmp4_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_exp = tmpMeta6;
_g = tmp4_2;
tmpMeta1 = omc_FGraphBuild_analyseExp(threadData, _exp, _inRef, _inKind, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_analyseExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta3 = mmc_mk_box3(0, _inRef, _inKind, _inGraph);
omc_AbsynUtil_traverseExpBidir(threadData, _inExp, boxvar_FGraphBuild_analyseExpTraverserEnter, boxvar_FGraphBuild_analyseExpTraverserExit, tmpMeta3, &tmpMeta1);
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_outGraph = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkCrefsFromExps(threadData_t *threadData, modelica_metatype _inExps, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inExps;
tmp4_2 = _inGraph;
{
modelica_metatype _e = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _crefs = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_g = tmp4_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_e = tmpMeta6;
_rest = tmpMeta7;
_g = tmp4_2;
_crefs = omc_AbsynUtil_getCrefFromExp(threadData, _e, 1, 1);
_g = omc_FGraphBuild_mkCrefsNodes(threadData, _crefs, _inParentRef, _inKind, _g);
_inExps = _rest;
_inGraph = _g;
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
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkExternalNode(threadData_t *threadData, modelica_string _inName, modelica_metatype _inExternalDeclOpt, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inExternalDeclOpt;
tmp4_2 = _inGraph;
{
modelica_metatype _g = NULL;
modelica_metatype _n = NULL;
modelica_metatype _nr = NULL;
modelica_metatype _ed = NULL;
modelica_metatype _ocr = NULL;
modelica_metatype _oae = NULL;
modelica_metatype _exps = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
_g = tmp4_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
_ed = tmpMeta6;
_ocr = tmpMeta7;
_exps = tmpMeta8;
_g = tmp4_2;
tmpMeta9 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta10 = mmc_mk_box2(14, &FCore_Data_ED__desc, _ed);
_g = omc_FGraph_node(threadData, _g, _inName, tmpMeta9, tmpMeta10 ,&_n);
_nr = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _inName, _nr, 0);
_oae = omc_Util_applyOption(threadData, _ocr, boxvar_AbsynUtil_crefExp);
tmpMeta1 = omc_FGraphBuild_mkCrefsFromExps(threadData, omc_List_consOption(threadData, _oae, _exps), _nr, _inKind, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkOptNode(threadData_t *threadData, modelica_string _inName, modelica_metatype _inConstraintLst, modelica_metatype _inClsAttrs, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inConstraintLst;
tmp4_2 = _inClsAttrs;
tmp4_3 = _inGraph;
{
modelica_metatype _g = NULL;
modelica_metatype _n = NULL;
modelica_metatype _nr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
if (!listEmpty(tmp4_2)) goto tmp3_end;
_g = tmp4_3;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
_g = tmp4_3;
tmpMeta6 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta7 = mmc_mk_box3(13, &FCore_Data_OT__desc, _inConstraintLst, _inClsAttrs);
_g = omc_FGraph_node(threadData, _g, _inName, tmpMeta6, tmpMeta7 ,&_n);
_nr = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _inName, _nr, 0);
tmpMeta1 = _g;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkAlNode(threadData_t *threadData, modelica_string _inName, modelica_metatype _inAlgs, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inAlgs;
tmp4_2 = _inGraph;
{
modelica_metatype _g = NULL;
modelica_metatype _n = NULL;
modelica_metatype _nr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_g = tmp4_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
_g = tmp4_2;
tmpMeta6 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta7 = mmc_mk_box3(11, &FCore_Data_AL__desc, _inName, _inAlgs);
_g = omc_FGraph_node(threadData, _g, _inName, tmpMeta6, tmpMeta7 ,&_n);
_nr = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _inName, _nr, 0);
tmpMeta1 = omc_List_fold2(threadData, _inAlgs, boxvar_FGraphBuild_analyseAlgorithm, _nr, _inKind, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkEqNode(threadData_t *threadData, modelica_string _inName, modelica_metatype _inEqs, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inEqs;
tmp4_2 = _inGraph;
{
modelica_metatype _g = NULL;
modelica_metatype _n = NULL;
modelica_metatype _nr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_g = tmp4_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
_g = tmp4_2;
tmpMeta6 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta7 = mmc_mk_box3(12, &FCore_Data_EQ__desc, _inName, _inEqs);
_g = omc_FGraph_node(threadData, _g, _inName, tmpMeta6, tmpMeta7 ,&_n);
_nr = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _inName, _nr, 0);
tmpMeta1 = omc_List_fold2(threadData, _inEqs, boxvar_FGraphBuild_analyseEquation, _nr, _inKind, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkTypeNode(threadData_t *threadData, modelica_metatype _inTypes, modelica_metatype _inParentRef, modelica_string _inName, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
{
modelica_metatype _nr = NULL;
modelica_metatype _pr = NULL;
modelica_metatype _n = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_pr = omc_FNode_child(threadData, _inParentRef, _OMC_LIT3);
_nr = omc_FNode_child(threadData, _pr, _inName);
omc_FNode_addTypesToRef(threadData, _nr, _inTypes);
tmpMeta1 = _inGraph;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
_g = tmp4_1;
tmp6 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_FNode_child(threadData, _inParentRef, _OMC_LIT3);
tmp6 = 1;
goto goto_7;
goto_7:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp6) {goto goto_2;}
tmpMeta8 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
_g = omc_FGraph_node(threadData, _g, _OMC_LIT3, tmpMeta8, _OMC_LIT4 ,&_n);
_pr = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _OMC_LIT3, _pr, 0);
tmpMeta9 = mmc_mk_cons(_pr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta10 = mmc_mk_box2(10, &FCore_Data_FT__desc, _inTypes);
_g = omc_FGraph_node(threadData, _g, _inName, tmpMeta9, tmpMeta10 ,&_n);
_nr = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _pr, _inName, _nr, 0);
tmpMeta1 = _g;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp11;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
_g = tmp4_1;
_pr = omc_FNode_child(threadData, _inParentRef, _OMC_LIT3);
tmp11 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_FNode_child(threadData, _pr, _inName);
tmp11 = 1;
goto goto_12;
goto_12:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp11) {goto goto_2;}
tmpMeta13 = mmc_mk_cons(_pr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta14 = mmc_mk_box2(10, &FCore_Data_FT__desc, _inTypes);
_g = omc_FGraph_node(threadData, _g, _inName, tmpMeta13, tmpMeta14 ,&_n);
_nr = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _pr, _inName, _nr, 0);
tmpMeta1 = _g;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
_pr = omc_FGraph_top(threadData, _inGraph);
tmpMeta15 = stringAppend(_OMC_LIT5,_inName);
tmpMeta16 = stringAppend(tmpMeta15,_OMC_LIT6);
tmpMeta17 = stringAppend(tmpMeta16,omc_FNode_name(threadData, omc_FNode_fromRef(threadData, _pr)));
tmpMeta18 = stringAppend(tmpMeta17,_OMC_LIT7);
fputs(MMC_STRINGDATA(tmpMeta18),stdout);
tmpMeta1 = _inGraph;
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
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkCrefNode(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
{
modelica_metatype _n = NULL;
modelica_metatype _nr = NULL;
modelica_metatype _g = NULL;
modelica_string _name = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
_g = tmp4_1;
_name = omc_AbsynUtil_printComponentRefStr(threadData, _inCref);
tmpMeta6 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta7 = mmc_mk_box2(20, &FCore_Data_CR__desc, _inCref);
_g = omc_FGraph_node(threadData, _g, _name, tmpMeta6, tmpMeta7 ,&_n);
_nr = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _name, _nr, 0);
tmpMeta1 = omc_FGraphBuild_mkDimsNode(threadData, _OMC_LIT8, omc_List_mkOption(threadData, omc_AbsynUtil_getSubsFromCref(threadData, _inCref, 1, 1)), _nr, _inKind, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkCrefsNodes(threadData_t *threadData, modelica_metatype _inCrefs, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inCrefs;
tmp4_2 = _inGraph;
{
modelica_metatype _rest = NULL;
modelica_metatype _g = NULL;
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_g = tmp4_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_cr = tmpMeta6;
_rest = tmpMeta7;
_g = tmp4_2;
_g = omc_FGraphBuild_mkCrefNode(threadData, _cr, _inParentRef, _inKind, _g);
_inCrefs = _rest;
_inGraph = _g;
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
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkExpressionNode(threadData_t *threadData, modelica_string _inName, modelica_metatype _inExp, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _inGraph;
{
modelica_metatype _n = NULL;
modelica_metatype _nr = NULL;
modelica_metatype _e = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
_e = tmp4_1;
_g = tmp4_2;
tmpMeta6 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta7 = mmc_mk_box3(19, &FCore_Data_EXP__desc, _inName, _e);
_g = omc_FGraph_node(threadData, _g, _inName, tmpMeta6, tmpMeta7 ,&_n);
_nr = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _inName, _nr, 0);
tmpMeta1 = omc_FGraphBuild_analyseExp(threadData, _e, _nr, _inKind, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkConditionNode(threadData_t *threadData, modelica_metatype _inCondition, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inCondition;
tmp4_2 = _inGraph;
{
modelica_metatype _e = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
_g = tmp4_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_e = tmpMeta6;
_g = tmp4_2;
tmpMeta1 = omc_FGraphBuild_mkExpressionNode(threadData, _OMC_LIT9, _e, _inParentRef, _inKind, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkInstNode(threadData_t *threadData, modelica_metatype _inVar, modelica_metatype _inParentRef, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _nr = NULL;
modelica_metatype _n = NULL;
modelica_metatype _g = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta2 = mmc_mk_box2(4, &FCore_Data_IT__desc, _inVar);
_g = omc_FGraph_node(threadData, _inGraph, _OMC_LIT10, tmpMeta1, tmpMeta2 ,&_n);
_nr = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _OMC_LIT10, _nr, 0);
_outGraph = _g;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkCompNode(threadData_t *threadData, modelica_metatype _inComp, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_string _name = NULL;
modelica_metatype _g = NULL;
modelica_metatype _n = NULL;
modelica_metatype _nr = NULL;
modelica_metatype _m = NULL;
modelica_metatype _cnd = NULL;
modelica_metatype _ad = NULL;
modelica_metatype _ts = NULL;
modelica_metatype _tad = NULL;
modelica_metatype _nd = NULL;
modelica_metatype _i = NULL;
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
tmpMeta1 = _inComp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,3,8) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 2));
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 5));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 6));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 8));
_name = tmpMeta2;
_ad = tmpMeta4;
_ts = tmpMeta5;
_m = tmpMeta6;
_cnd = tmpMeta7;
_nd = omc_FNode_element2Data(threadData, _inComp, _inKind ,&_i);
tmpMeta8 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
_g = omc_FGraph_node(threadData, _inGraph, _name, tmpMeta8, _nd ,&_n);
_nr = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _name, _nr, 0);
_g = omc_FGraphBuild_mkInstNode(threadData, _i, _nr, _g);
tmpMeta9 = MMC_REFSTRUCTLIT(mmc_nil);
_g = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT11, tmpMeta9, _nr, _g);
_tad = omc_AbsynUtil_typeSpecDimensions(threadData, _ts);
_g = omc_FGraphBuild_mkDimsNode(threadData, _OMC_LIT12, mmc_mk_some(_tad), _nr, _inKind, _g);
_g = omc_FGraphBuild_mkDimsNode(threadData, _OMC_LIT13, mmc_mk_some(_ad), _nr, _inKind, _g);
_g = omc_FGraphBuild_mkConditionNode(threadData, _cnd, _nr, _inKind, _g);
_g = omc_FGraphBuild_mkConstrainClass(threadData, _inComp, _nr, _inKind, _g);
tmpMeta10 = mmc_mk_box2(3, &FCore_ModScope_MS__COMPONENT__desc, _name);
_g = omc_FGraphBuild_mkModNode(threadData, _OMC_LIT14, _m, tmpMeta10, _nr, _inKind, _g);
_outGraph = _g;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkDimsNode__helper(threadData_t *threadData, modelica_integer _inStartWith, modelica_metatype _inArrayDims, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_integer tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inStartWith;
tmp4_2 = _inArrayDims;
tmp4_3 = _inGraph;
{
modelica_string _name = NULL;
modelica_metatype _rest = NULL;
modelica_integer _i;
modelica_metatype _e = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
_g = tmp4_3;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,0) == 0) goto tmp3_end;
_rest = tmpMeta7;
_i = tmp4_1;
_g = tmp4_3;
_name = intString(_i);
_g = omc_FGraphBuild_mkExpressionNode(threadData, _name, _OMC_LIT15, _inParentRef, _inKind, _g);
_inStartWith = ((modelica_integer) 1) + _i;
_inArrayDims = _rest;
_inGraph = _g;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_2);
tmpMeta9 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
_e = tmpMeta10;
_rest = tmpMeta9;
_i = tmp4_1;
_g = tmp4_3;
_name = intString(_i);
_g = omc_FGraphBuild_mkExpressionNode(threadData, _name, _e, _inParentRef, _inKind, _g);
_inStartWith = ((modelica_integer) 1) + _i;
_inArrayDims = _rest;
_inGraph = _g;
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
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
modelica_metatype boxptr_FGraphBuild_mkDimsNode__helper(threadData_t *threadData, modelica_metatype _inStartWith, modelica_metatype _inArrayDims, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_integer tmp1;
modelica_metatype _outGraph = NULL;
tmp1 = mmc_unbox_integer(_inStartWith);
_outGraph = omc_FGraphBuild_mkDimsNode__helper(threadData, tmp1, _inArrayDims, _inParentRef, _inKind, _inGraph);
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkDimsNode(threadData_t *threadData, modelica_string _inName, modelica_metatype _inArrayDims, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inArrayDims;
tmp4_2 = _inGraph;
{
modelica_metatype _n = NULL;
modelica_metatype _nr = NULL;
modelica_metatype _a = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
_g = tmp4_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
_g = tmp4_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmpMeta7);
tmpMeta9 = MMC_CDR(tmpMeta7);
_a = tmpMeta7;
_g = tmp4_2;
tmpMeta10 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta11 = mmc_mk_box3(21, &FCore_Data_DIMS__desc, _inName, _a);
_g = omc_FGraph_node(threadData, _g, _inName, tmpMeta10, tmpMeta11 ,&_n);
_nr = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _inName, _nr, 0);
tmpMeta1 = omc_FGraphBuild_mkDimsNode__helper(threadData, ((modelica_integer) 0), _a, _nr, _inKind, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkImportNode(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
{
modelica_metatype _g = NULL;
modelica_metatype _n = NULL;
modelica_metatype _r = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_g = tmp4_1;
_r = omc_FNode_child(threadData, _inParentRef, _OMC_LIT16);
omc_FNode_addImportToRef(threadData, _r, _inElement);
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
_g = tmp4_1;
tmpMeta6 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
_g = omc_FGraph_node(threadData, _g, _OMC_LIT16, tmpMeta6, _OMC_LIT18 ,&_n);
_r = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _OMC_LIT16, _r, 0);
omc_FNode_addImportToRef(threadData, _r, _inElement);
tmpMeta1 = _g;
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
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkUnitsNode(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
{
modelica_metatype _g = NULL;
modelica_metatype _n = NULL;
modelica_metatype _r = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_g = tmp4_1;
_r = omc_FNode_child(threadData, _inParentRef, _OMC_LIT19);
omc_FNode_addDefinedUnitToRef(threadData, _r, _inElement);
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
_g = tmp4_1;
tmpMeta6 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta7 = mmc_mk_cons(_inElement, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta8 = mmc_mk_box2(9, &FCore_Data_DU__desc, tmpMeta7);
_g = omc_FGraph_node(threadData, _g, _OMC_LIT19, tmpMeta6, tmpMeta8 ,&_n);
_r = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _OMC_LIT19, _r, 0);
tmpMeta1 = _g;
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
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkElementNode(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inElement;
tmp4_2 = _inGraph;
{
modelica_metatype _g = NULL;
modelica_string _name = NULL;
modelica_metatype _p = NULL;
modelica_metatype _n = NULL;
modelica_metatype _nr = NULL;
modelica_metatype _m = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,8) == 0) goto tmp3_end;
_g = tmp4_2;
tmpMeta1 = omc_FGraphBuild_mkCompNode(threadData, _inElement, _inParentRef, _inKind, _g);
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
_g = tmp4_2;
tmpMeta1 = omc_FGraphBuild_mkClassNode(threadData, _inElement, _inParentRef, _inKind, _g);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_p = tmpMeta5;
_m = tmpMeta6;
_g = tmp4_2;
_name = omc_FNode_mkExtendsName(threadData, _p);
tmpMeta7 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta8 = mmc_mk_box3(8, &FCore_Data_EX__desc, _inElement, _OMC_LIT20);
_g = omc_FGraph_node(threadData, _g, _name, tmpMeta7, tmpMeta8 ,&_n);
_nr = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _name, _nr, 0);
tmpMeta9 = mmc_mk_box2(4, &FCore_ModScope_MS__EXTENDS__desc, _p);
tmpMeta1 = omc_FGraphBuild_mkModNode(threadData, _OMC_LIT14, _m, tmpMeta9, _nr, _inKind, _g);
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,3) == 0) goto tmp3_end;
_g = tmp4_2;
tmpMeta1 = omc_FGraphBuild_mkImportNode(threadData, _inElement, _inParentRef, _inKind, _g);
goto tmp3_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,5) == 0) goto tmp3_end;
_g = tmp4_2;
tmpMeta1 = omc_FGraphBuild_mkUnitsNode(threadData, _inElement, _inParentRef, _inKind, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_mkClassChildren(threadData_t *threadData, modelica_string _name, modelica_metatype _inClassDef, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inClassDef;
tmp4_2 = _inGraph;
{
modelica_metatype _el = NULL;
modelica_metatype _g = NULL;
modelica_metatype _cdef = NULL;
modelica_metatype _nr = NULL;
modelica_metatype _ts = NULL;
modelica_metatype _p = NULL;
modelica_metatype _m = NULL;
modelica_metatype _ad = NULL;
modelica_metatype _eqs = NULL;
modelica_metatype _ieqs = NULL;
modelica_metatype _als = NULL;
modelica_metatype _ials = NULL;
modelica_metatype _constraintLst = NULL;
modelica_metatype _clsattrs = NULL;
modelica_metatype _externalDecl = NULL;
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
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,8) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 9));
_el = tmpMeta6;
_eqs = tmpMeta7;
_ieqs = tmpMeta8;
_als = tmpMeta9;
_ials = tmpMeta10;
_constraintLst = tmpMeta11;
_clsattrs = tmpMeta12;
_externalDecl = tmpMeta13;
_g = tmp4_2;
tmp4 += 4;
_g = omc_List_fold2(threadData, _el, boxvar_FGraphBuild_mkElementNode, _inParentRef, _inKind, _g);
_g = omc_FGraphBuild_mkEqNode(threadData, _OMC_LIT21, _eqs, _inParentRef, _inKind, _g);
_g = omc_FGraphBuild_mkEqNode(threadData, _OMC_LIT22, _ieqs, _inParentRef, _inKind, _g);
_g = omc_FGraphBuild_mkAlNode(threadData, _OMC_LIT23, _als, _inParentRef, _inKind, _g);
_g = omc_FGraphBuild_mkAlNode(threadData, _OMC_LIT24, _ials, _inParentRef, _inKind, _g);
_g = omc_FGraphBuild_mkOptNode(threadData, _OMC_LIT25, _constraintLst, _clsattrs, _inParentRef, _inKind, _g);
tmpMeta1 = omc_FGraphBuild_mkExternalNode(threadData, _OMC_LIT26, _externalDecl, _inParentRef, _inKind, _g);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_m = tmpMeta14;
_cdef = tmpMeta15;
_g = tmp4_2;
tmp4 += 3;
_g = omc_FGraphBuild_mkClassChildren(threadData, _name, _cdef, _inParentRef, _inKind, _g);
tmpMeta16 = mmc_mk_box2(6, &FCore_ModScope_MS__CLASS__EXTENDS__desc, _name);
tmpMeta1 = omc_FGraphBuild_mkModNode(threadData, _OMC_LIT14, _m, tmpMeta16, _inParentRef, _inKind, _g);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,3) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_ts = tmpMeta17;
_m = tmpMeta18;
_g = tmp4_2;
tmp4 += 2;
_p = omc_AbsynUtil_typeSpecPath(threadData, _ts);
_nr = _inParentRef;
tmpMeta19 = mmc_mk_box2(5, &FCore_ModScope_MS__DERIVED__desc, _p);
_g = omc_FGraphBuild_mkModNode(threadData, _OMC_LIT14, _m, tmpMeta19, _nr, _inKind, _g);
_ad = omc_AbsynUtil_typeSpecDimensions(threadData, _ts);
tmpMeta1 = omc_FGraphBuild_mkDimsNode(threadData, _OMC_LIT12, mmc_mk_some(_ad), _nr, _inKind, _g);
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
_g = tmp4_2;
tmp4 += 1;
tmpMeta1 = _g;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
_g = tmp4_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 5: {
tmpMeta1 = _inGraph;
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
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkBindingNode(threadData_t *threadData, modelica_metatype _inBinding, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inBinding;
tmp4_2 = _inGraph;
{
modelica_metatype _e = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
_g = tmp4_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_e = tmpMeta6;
_g = tmp4_2;
tmpMeta1 = omc_FGraphBuild_mkExpressionNode(threadData, _OMC_LIT27, _e, _inParentRef, _inKind, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkSubMods(threadData_t *threadData, modelica_metatype _inSubMod, modelica_metatype _inModScope, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inSubMod;
tmp4_2 = _inGraph;
{
modelica_metatype _rest = NULL;
modelica_string _id = NULL;
modelica_metatype _m = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_g = tmp4_2;
tmpMeta1 = _g;
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
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
_id = tmpMeta8;
_m = tmpMeta9;
_rest = tmpMeta7;
_g = tmp4_2;
_g = omc_FGraphBuild_mkModNode(threadData, _id, _m, _inModScope, _inParentRef, _inKind, _g);
_inSubMod = _rest;
_inGraph = _g;
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
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkModNode(threadData_t *threadData, modelica_string _inName, modelica_metatype _inMod, modelica_metatype _inModScope, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_string tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inName;
tmp4_2 = _inMod;
tmp4_3 = _inGraph;
{
modelica_string _name = NULL;
modelica_metatype _g = NULL;
modelica_metatype _n = NULL;
modelica_metatype _nr = NULL;
modelica_metatype _e = NULL;
modelica_metatype _sm = NULL;
modelica_metatype _b = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,0) == 0) goto tmp3_end;
_g = tmp4_3;
tmp4 += 4;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,5) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
if (!optionNone(tmpMeta7)) goto tmp3_end;
_g = tmp4_3;
tmp4 += 1;
tmpMeta1 = _g;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,5) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (!listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
if (optionNone(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 1));
_b = tmpMeta9;
_name = tmp4_1;
_g = tmp4_3;
tmpMeta11 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta12 = mmc_mk_box2(18, &FCore_Data_MO__desc, _inMod);
_g = omc_FGraph_node(threadData, _g, _name, tmpMeta11, tmpMeta12 ,&_n);
_nr = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _name, _nr, 0);
tmpMeta1 = omc_FGraphBuild_mkBindingNode(threadData, _b, _nr, _inKind, _g);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,5) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
_sm = tmpMeta13;
_b = tmpMeta14;
_name = tmp4_1;
_g = tmp4_3;
tmp4 += 1;
tmpMeta15 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta16 = mmc_mk_box2(18, &FCore_Data_MO__desc, _inMod);
_g = omc_FGraph_node(threadData, _g, _name, tmpMeta15, tmpMeta16 ,&_n);
_nr = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _name, _nr, 0);
_sm = omc_FMod_compactSubMods(threadData, _sm, _inModScope);
_g = omc_FGraphBuild_mkSubMods(threadData, _sm, _inModScope, _nr, _inKind, _g);
tmpMeta1 = omc_FGraphBuild_mkBindingNode(threadData, _b, _nr, _inKind, _g);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_e = tmpMeta17;
_name = tmp4_1;
_g = tmp4_3;
tmpMeta18 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta19 = mmc_mk_box2(18, &FCore_Data_MO__desc, _inMod);
_g = omc_FGraph_node(threadData, _g, _name, tmpMeta18, tmpMeta19 ,&_n);
_nr = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _name, _nr, 0);
tmpMeta1 = omc_FGraphBuild_mkElementNode(threadData, _e, _nr, _inKind, _g);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
_name = tmp4_1;
_g = tmp4_3;
tmpMeta20 = stringAppend(_OMC_LIT28,_name);
tmpMeta21 = stringAppend(tmpMeta20,_OMC_LIT29);
tmpMeta22 = stringAppend(tmpMeta21,omc_SCodeDump_printModStr(threadData, _inMod, _OMC_LIT30));
tmpMeta23 = stringAppend(tmpMeta22,_OMC_LIT7);
fputs(MMC_STRINGDATA(tmpMeta23),stdout);
tmpMeta1 = _g;
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
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkConstrainClass(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inElement;
tmp4_2 = _inGraph;
{
modelica_metatype _g = NULL;
modelica_metatype _n = NULL;
modelica_metatype _nr = NULL;
modelica_metatype _cc = NULL;
modelica_metatype _m = NULL;
modelica_metatype _p = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (optionNone(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 1));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 3));
_cc = tmpMeta9;
_p = tmpMeta10;
_m = tmpMeta11;
_g = tmp4_2;
tmp4 += 1;
tmpMeta12 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta13 = mmc_mk_box2(22, &FCore_Data_CC__desc, _cc);
_g = omc_FGraph_node(threadData, _g, _OMC_LIT31, tmpMeta12, tmpMeta13 ,&_n);
_nr = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _OMC_LIT31, _nr, 0);
tmpMeta14 = mmc_mk_box2(7, &FCore_ModScope_MS__CONSTRAINEDBY__desc, _p);
tmpMeta1 = omc_FGraphBuild_mkModNode(threadData, _OMC_LIT14, _m, tmpMeta14, _nr, _inKind, _g);
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,8) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,0,1) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
if (optionNone(tmpMeta17)) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 1));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 3));
_cc = tmpMeta18;
_p = tmpMeta19;
_m = tmpMeta20;
_g = tmp4_2;
tmpMeta21 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta22 = mmc_mk_box2(22, &FCore_Data_CC__desc, _cc);
_g = omc_FGraph_node(threadData, _g, _OMC_LIT31, tmpMeta21, tmpMeta22 ,&_n);
_nr = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _OMC_LIT31, _nr, 0);
tmpMeta23 = mmc_mk_box2(7, &FCore_ModScope_MS__CONSTRAINEDBY__desc, _p);
tmpMeta1 = omc_FGraphBuild_mkModNode(threadData, _OMC_LIT14, _m, tmpMeta23, _nr, _inKind, _g);
goto tmp3_done;
}
case 2: {
tmpMeta1 = _inGraph;
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
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkClassNode(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
{
modelica_metatype _cdef = NULL;
modelica_metatype _cls = NULL;
modelica_string _name = NULL;
modelica_metatype _g = NULL;
modelica_metatype _n = NULL;
modelica_metatype _nr = NULL;
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
_g = tmp4_1;
_cls = omc_SCodeInstUtil_expandEnumerationClass(threadData, _inClass);
tmpMeta6 = _cls;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,2,8) == 0) goto goto_2;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 7));
_name = tmpMeta7;
_cdef = tmpMeta8;
tmpMeta9 = mmc_mk_cons(_inParentRef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta10 = mmc_mk_box6(6, &FCore_Data_CL__desc, _cls, _OMC_LIT32, _OMC_LIT20, _inKind, _OMC_LIT33);
_g = omc_FGraph_node(threadData, _g, _name, tmpMeta9, tmpMeta10 ,&_n);
_nr = omc_FNode_toRef(threadData, _n);
omc_FNode_addChildRef(threadData, _inParentRef, _name, _nr, 0);
_g = omc_FGraphBuild_mkConstrainClass(threadData, _cls, _nr, _inKind, _g);
tmpMeta1 = omc_FGraphBuild_mkClassChildren(threadData, _name, _cdef, _nr, _inKind, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraphBuild_mkClassGraph(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inParentRef, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inClass;
tmp4_2 = _inGraph;
{
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
_g = tmp4_2;
tmpMeta1 = omc_FGraphBuild_mkClassNode(threadData, _inClass, _inParentRef, _inKind, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraphBuild_mkProgramGraph(threadData_t *threadData, modelica_metatype _inProgram, modelica_metatype _inKind, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _topRef = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_topRef = omc_FGraph_top(threadData, _inGraph);
_outGraph = omc_List_fold2(threadData, _inProgram, boxvar_FGraphBuild_mkClassGraph, _topRef, _inKind, _inGraph);
_return: OMC_LABEL_UNUSED
return _outGraph;
}
