#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "VarTransform.c"
#endif
#include "omc_simulation_settings.h"
#include "VarTransform.h"
#define _OMC_LIT0_data "Got exp to replace when condition is not allowing replacements. Check traversal."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,80,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "VarTransform.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,15,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT2_6,0.0);
#define _OMC_LIT2_6 MMC_REFREALLIT(_OMC_LIT_STRUCT2_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT2,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT1,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1260)),MMC_IMMEDIATE(MMC_TAGFIXNUM(5)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1260)),MMC_IMMEDIATE(MMC_TAGFIXNUM(125)),_OMC_LIT2_6}};
#define _OMC_LIT2 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "-add_replacement failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,24,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data " -> "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,4,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,1,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "Replacements: ("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,15,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data ")\n=============\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,16,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data ")\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,2,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "=============\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,14,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "Internal error, emptyReplacementsArray2 called with negative n!"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,63,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "applyReplacementsDAEElts should not fail"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,40,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT12_6,0.0);
#define _OMC_LIT12_6 MMC_REFREALLIT(_OMC_LIT_STRUCT12_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT12,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT1,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(302)),MMC_IMMEDIATE(MMC_TAGFIXNUM(9)),MMC_IMMEDIATE(MMC_TAGFIXNUM(302)),MMC_IMMEDIATE(MMC_TAGFIXNUM(89)),_OMC_LIT12_6}};
#define _OMC_LIT12 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT12)
#include "util/modelica.h"
#include "VarTransform_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_replaceExpMatrix(threadData_t *threadData, modelica_metatype _inTplExpExpBooleanLstLst, modelica_metatype _inVariableReplacements, modelica_metatype _inFuncTypeExpExpToBooleanOption, modelica_boolean *out_replacementPerformed);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_VarTransform_replaceExpMatrix(threadData_t *threadData, modelica_metatype _inTplExpExpBooleanLstLst, modelica_metatype _inVariableReplacements, modelica_metatype _inFuncTypeExpExpToBooleanOption, modelica_metatype *out_replacementPerformed);
static const MMC_DEFSTRUCTLIT(boxvar_lit_VarTransform_replaceExpMatrix,2,0) {(void*) boxptr_VarTransform_replaceExpMatrix,0}};
#define boxvar_VarTransform_replaceExpMatrix MMC_REFSTRUCTLIT(boxvar_lit_VarTransform_replaceExpMatrix)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_VarTransform_replaceExpCond(threadData_t *threadData, modelica_metatype _inFuncTypeExpExpToBooleanOption, modelica_metatype _inExp);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_VarTransform_replaceExpCond(threadData_t *threadData, modelica_metatype _inFuncTypeExpExpToBooleanOption, modelica_metatype _inExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_VarTransform_replaceExpCond,2,0) {(void*) boxptr_VarTransform_replaceExpCond,0}};
#define boxvar_VarTransform_replaceExpCond MMC_REFSTRUCTLIT(boxvar_lit_VarTransform_replaceExpCond)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_replaceExpCref(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inVarReplacements, modelica_metatype _inCondition, modelica_boolean _inReplacementPerformed, modelica_boolean *out_replacementPerformed);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_VarTransform_replaceExpCref(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inVarReplacements, modelica_metatype _inCondition, modelica_metatype _inReplacementPerformed, modelica_metatype *out_replacementPerformed);
static const MMC_DEFSTRUCTLIT(boxvar_lit_VarTransform_replaceExpCref,2,0) {(void*) boxptr_VarTransform_replaceExpCref,0}};
#define boxvar_VarTransform_replaceExpCref MMC_REFSTRUCTLIT(boxvar_lit_VarTransform_replaceExpCref)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_makeTransitive2(threadData_t *threadData, modelica_metatype _repl, modelica_metatype _src, modelica_metatype _dst, modelica_metatype *out_outSrc, modelica_metatype *out_outDst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_VarTransform_makeTransitive2,2,0) {(void*) boxptr_VarTransform_makeTransitive2,0}};
#define boxvar_VarTransform_makeTransitive2 MMC_REFSTRUCTLIT(boxvar_lit_VarTransform_makeTransitive2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_makeTransitive12(threadData_t *threadData, modelica_metatype _lst, modelica_metatype _repl, modelica_metatype _singleRepl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_VarTransform_makeTransitive12,2,0) {(void*) boxptr_VarTransform_makeTransitive12,0}};
#define boxvar_VarTransform_makeTransitive12 MMC_REFSTRUCTLIT(boxvar_lit_VarTransform_makeTransitive12)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_makeTransitive1(threadData_t *threadData, modelica_metatype _repl, modelica_metatype _src, modelica_metatype _dst, modelica_metatype *out_outSrc, modelica_metatype *out_outDst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_VarTransform_makeTransitive1,2,0) {(void*) boxptr_VarTransform_makeTransitive1,0}};
#define boxvar_VarTransform_makeTransitive1 MMC_REFSTRUCTLIT(boxvar_lit_VarTransform_makeTransitive1)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_makeTransitive(threadData_t *threadData, modelica_metatype _repl, modelica_metatype _src, modelica_metatype _dst, modelica_metatype *out_outSrc, modelica_metatype *out_outDst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_VarTransform_makeTransitive,2,0) {(void*) boxptr_VarTransform_makeTransitive,0}};
#define boxvar_VarTransform_makeTransitive MMC_REFSTRUCTLIT(boxvar_lit_VarTransform_makeTransitive)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_amortizeUnion(threadData_t *threadData, modelica_metatype _inCrefs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_VarTransform_amortizeUnion,2,0) {(void*) boxptr_VarTransform_amortizeUnion,0}};
#define boxvar_VarTransform_amortizeUnion MMC_REFSTRUCTLIT(boxvar_lit_VarTransform_amortizeUnion)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_addReplacementInv2(threadData_t *threadData, modelica_metatype _invHt, modelica_metatype _dst, modelica_metatype _src);
static const MMC_DEFSTRUCTLIT(boxvar_lit_VarTransform_addReplacementInv2,2,0) {(void*) boxptr_VarTransform_addReplacementInv2,0}};
#define boxvar_VarTransform_addReplacementInv2 MMC_REFSTRUCTLIT(boxvar_lit_VarTransform_addReplacementInv2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_addReplacementInv(threadData_t *threadData, modelica_metatype _invHt, modelica_metatype _src, modelica_metatype _dst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_VarTransform_addReplacementInv,2,0) {(void*) boxptr_VarTransform_addReplacementInv,0}};
#define boxvar_VarTransform_addReplacementInv MMC_REFSTRUCTLIT(boxvar_lit_VarTransform_addReplacementInv)
PROTECTED_FUNCTION_STATIC modelica_string omc_VarTransform_printReplacementTupleStr(threadData_t *threadData, modelica_metatype _tpl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_VarTransform_printReplacementTupleStr,2,0) {(void*) boxptr_VarTransform_printReplacementTupleStr,0}};
#define boxvar_VarTransform_printReplacementTupleStr MMC_REFSTRUCTLIT(boxvar_lit_VarTransform_printReplacementTupleStr)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_replaceOptEquationsStmts(threadData_t *threadData, modelica_metatype _optStmt, modelica_metatype _inVariableReplacements, modelica_metatype _condExpFunc, modelica_boolean *out_replacementPerformed);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_VarTransform_replaceOptEquationsStmts(threadData_t *threadData, modelica_metatype _optStmt, modelica_metatype _inVariableReplacements, modelica_metatype _condExpFunc, modelica_metatype *out_replacementPerformed);
static const MMC_DEFSTRUCTLIT(boxvar_lit_VarTransform_replaceOptEquationsStmts,2,0) {(void*) boxptr_VarTransform_replaceOptEquationsStmts,0}};
#define boxvar_VarTransform_replaceOptEquationsStmts MMC_REFSTRUCTLIT(boxvar_lit_VarTransform_replaceOptEquationsStmts)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_replaceEquationsElse(threadData_t *threadData, modelica_metatype _inElse, modelica_metatype _repl, modelica_metatype _condExpFunc, modelica_boolean *out_replacementPerformed);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_VarTransform_replaceEquationsElse(threadData_t *threadData, modelica_metatype _inElse, modelica_metatype _repl, modelica_metatype _condExpFunc, modelica_metatype *out_replacementPerformed);
static const MMC_DEFSTRUCTLIT(boxvar_lit_VarTransform_replaceEquationsElse,2,0) {(void*) boxptr_VarTransform_replaceEquationsElse,0}};
#define boxvar_VarTransform_replaceEquationsElse MMC_REFSTRUCTLIT(boxvar_lit_VarTransform_replaceEquationsElse)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_emptyReplacementsArray2(threadData_t *threadData, modelica_integer _n);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_VarTransform_emptyReplacementsArray2(threadData_t *threadData, modelica_metatype _n);
static const MMC_DEFSTRUCTLIT(boxvar_lit_VarTransform_emptyReplacementsArray2,2,0) {(void*) boxptr_VarTransform_emptyReplacementsArray2,0}};
#define boxvar_VarTransform_emptyReplacementsArray2 MMC_REFSTRUCTLIT(boxvar_lit_VarTransform_emptyReplacementsArray2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_applyReplacementsVarAttr(threadData_t *threadData, modelica_metatype _attr, modelica_metatype _repl, modelica_metatype _condExpFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_VarTransform_applyReplacementsVarAttr,2,0) {(void*) boxptr_VarTransform_applyReplacementsVarAttr,0}};
#define boxvar_VarTransform_applyReplacementsVarAttr MMC_REFSTRUCTLIT(boxvar_lit_VarTransform_applyReplacementsVarAttr)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_replaceExpMatrix(threadData_t *threadData, modelica_metatype _inTplExpExpBooleanLstLst, modelica_metatype _inVariableReplacements, modelica_metatype _inFuncTypeExpExpToBooleanOption, modelica_boolean *out_replacementPerformed)
{
modelica_metatype _outTplExpExpBooleanLstLst = NULL;
modelica_boolean _replacementPerformed;
modelica_metatype _acc1 = NULL;
modelica_metatype tmpMeta1;
modelica_boolean _acc2;
modelica_boolean _c;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_acc1 = tmpMeta1;
_acc2 = 0;
{
modelica_metatype _exp;
for (tmpMeta2 = _inTplExpExpBooleanLstLst; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_exp = MMC_CAR(tmpMeta2);
_exp = omc_VarTransform_replaceExpList(threadData, _exp, _inVariableReplacements, _inFuncTypeExpExpToBooleanOption ,&_c);
_acc2 = (_acc2 || _c);
tmpMeta3 = mmc_mk_cons(_exp, _acc1);
_acc1 = tmpMeta3;
}
}
_outTplExpExpBooleanLstLst = listReverseInPlace(_acc1);
_replacementPerformed = _acc2;
_return: OMC_LABEL_UNUSED
if (out_replacementPerformed) { *out_replacementPerformed = _replacementPerformed; }
return _outTplExpExpBooleanLstLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_VarTransform_replaceExpMatrix(threadData_t *threadData, modelica_metatype _inTplExpExpBooleanLstLst, modelica_metatype _inVariableReplacements, modelica_metatype _inFuncTypeExpExpToBooleanOption, modelica_metatype *out_replacementPerformed)
{
modelica_boolean _replacementPerformed;
modelica_metatype _outTplExpExpBooleanLstLst = NULL;
_outTplExpExpBooleanLstLst = omc_VarTransform_replaceExpMatrix(threadData, _inTplExpExpBooleanLstLst, _inVariableReplacements, _inFuncTypeExpExpToBooleanOption, &_replacementPerformed);
if (out_replacementPerformed) { *out_replacementPerformed = mmc_mk_icon(_replacementPerformed); }
return _outTplExpExpBooleanLstLst;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_VarTransform_replaceExpCond(threadData_t *threadData, modelica_metatype _inFuncTypeExpExpToBooleanOption, modelica_metatype _inExp)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inFuncTypeExpExpToBooleanOption;
tmp4_2 = _inExp;
{
modelica_fnptr _cond;
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
_cond = tmpMeta6;
_e = tmp4_2;
tmp1 = mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cond), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cond), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cond), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cond), 1)))) (threadData, _e));
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
_outBoolean = tmp1;
_return: OMC_LABEL_UNUSED
return _outBoolean;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_VarTransform_replaceExpCond(threadData_t *threadData, modelica_metatype _inFuncTypeExpExpToBooleanOption, modelica_metatype _inExp)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_VarTransform_replaceExpCond(threadData, _inFuncTypeExpExpToBooleanOption, _inExp);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_metatype omc_VarTransform_replaceExpList(threadData_t *threadData, modelica_metatype _iexpl, modelica_metatype _repl, modelica_metatype _cond, modelica_boolean *out_replacementPerformed)
{
modelica_metatype _outExpl = NULL;
modelica_boolean _replacementPerformed;
modelica_metatype _acc1 = NULL;
modelica_metatype tmpMeta1;
modelica_boolean _acc2;
modelica_boolean _c;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_acc1 = tmpMeta1;
_acc2 = 0;
{
modelica_metatype _exp;
for (tmpMeta2 = _iexpl; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_exp = MMC_CAR(tmpMeta2);
_exp = omc_VarTransform_replaceExp(threadData, _exp, _repl, _cond ,&_c);
_acc2 = (_acc2 || _c);
tmpMeta3 = mmc_mk_cons(_exp, _acc1);
_acc1 = tmpMeta3;
}
}
_outExpl = listReverseInPlace(_acc1);
_replacementPerformed = _acc2;
_return: OMC_LABEL_UNUSED
if (out_replacementPerformed) { *out_replacementPerformed = _replacementPerformed; }
return _outExpl;
}
modelica_metatype boxptr_VarTransform_replaceExpList(threadData_t *threadData, modelica_metatype _iexpl, modelica_metatype _repl, modelica_metatype _cond, modelica_metatype *out_replacementPerformed)
{
modelica_boolean _replacementPerformed;
modelica_metatype _outExpl = NULL;
_outExpl = omc_VarTransform_replaceExpList(threadData, _iexpl, _repl, _cond, &_replacementPerformed);
if (out_replacementPerformed) { *out_replacementPerformed = mmc_mk_icon(_replacementPerformed); }
return _outExpl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_replaceExpCref(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inVarReplacements, modelica_metatype _inCondition, modelica_boolean _inReplacementPerformed, modelica_boolean *out_replacementPerformed)
{
modelica_metatype _outExp = NULL;
modelica_boolean _replacementPerformed;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if((!omc_VarTransform_replaceExpCond(threadData, _inCondition, _inExp)))
{
omc_Error_addInternalError(threadData, _OMC_LIT0, _OMC_LIT2);
}
_replacementPerformed = 0;
_outExp = _inExp;
{
modelica_metatype tmp3_1;
tmp3_1 = _inExp;
{
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_cr = tmpMeta5;
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
_outExp = omc_VarTransform_getReplacement(threadData, _inVarReplacements, _cr);
_outExp = omc_VarTransform_avoidDoubleHashLookup(threadData, _outExp, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inExp), 3))));
_replacementPerformed = 1;
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
if (out_replacementPerformed) { *out_replacementPerformed = _replacementPerformed; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_VarTransform_replaceExpCref(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inVarReplacements, modelica_metatype _inCondition, modelica_metatype _inReplacementPerformed, modelica_metatype *out_replacementPerformed)
{
modelica_integer tmp1;
modelica_boolean _replacementPerformed;
modelica_metatype _outExp = NULL;
tmp1 = mmc_unbox_integer(_inReplacementPerformed);
_outExp = omc_VarTransform_replaceExpCref(threadData, _inExp, _inVarReplacements, _inCondition, tmp1, &_replacementPerformed);
if (out_replacementPerformed) { *out_replacementPerformed = mmc_mk_icon(_replacementPerformed); }
return _outExp;
}
static modelica_metatype closure0_VarTransform_replaceExpCref(threadData_t *thData, modelica_metatype closure, modelica_metatype inExp, modelica_metatype inReplacementPerformed, modelica_metatype tmp1)
{
modelica_metatype inVarReplacements = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype inCondition = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_VarTransform_replaceExpCref(thData, inExp, inVarReplacements, inCondition, inReplacementPerformed, tmp1);
}
DLLExport
modelica_metatype omc_VarTransform_replaceExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inVarReplacements, modelica_metatype _inCondition, modelica_boolean *out_replacementPerformed)
{
modelica_metatype _outExp = NULL;
modelica_boolean _replacementPerformed;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outExp = _inExp;
if(omc_VarTransform_replaceExpCond(threadData, _inCondition, _inExp))
{
tmpMeta2 = mmc_mk_box2(0, _inVarReplacements, _inCondition);
_outExp = omc_Expression_traverseExpBottomUp(threadData, _inExp, (modelica_fnptr) mmc_mk_box2(0,closure0_VarTransform_replaceExpCref,tmpMeta2), mmc_mk_boolean(1), NULL);
}
_replacementPerformed = (!referenceEq(_outExp, _inExp));
_return: OMC_LABEL_UNUSED
if (out_replacementPerformed) { *out_replacementPerformed = _replacementPerformed; }
return _outExp;
}
modelica_metatype boxptr_VarTransform_replaceExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inVarReplacements, modelica_metatype _inCondition, modelica_metatype *out_replacementPerformed)
{
modelica_boolean _replacementPerformed;
modelica_metatype _outExp = NULL;
_outExp = omc_VarTransform_replaceExp(threadData, _inExp, _inVarReplacements, _inCondition, &_replacementPerformed);
if (out_replacementPerformed) { *out_replacementPerformed = mmc_mk_icon(_replacementPerformed); }
return _outExp;
}
DLLExport
modelica_metatype omc_VarTransform_replaceExpRepeated2(threadData_t *threadData, modelica_metatype _e, modelica_metatype _repl, modelica_metatype _func, modelica_integer _maxIter, modelica_integer _i, modelica_boolean _equal)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_boolean tmp4_1;
tmp4_1 = _equal;
{
modelica_metatype _e1 = NULL;
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
modelica_boolean tmp6;
tmp6 = (_i > _maxIter);
if (1 != tmp6) goto goto_2;
tmpMeta1 = _e;
goto tmp3_done;
}
case 1: {
if (1 != tmp4_1) goto tmp3_end;
tmpMeta1 = _e;
goto tmp3_done;
}
case 2: {
_e1 = omc_VarTransform_replaceExp(threadData, _e, _repl, _func ,&_b);
tmpMeta1 = omc_VarTransform_replaceExpRepeated2(threadData, _e1, _repl, _func, _maxIter, ((modelica_integer) 1) + _i, (!_b));
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
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
modelica_metatype boxptr_VarTransform_replaceExpRepeated2(threadData_t *threadData, modelica_metatype _e, modelica_metatype _repl, modelica_metatype _func, modelica_metatype _maxIter, modelica_metatype _i, modelica_metatype _equal)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype _outExp = NULL;
tmp1 = mmc_unbox_integer(_maxIter);
tmp2 = mmc_unbox_integer(_i);
tmp3 = mmc_unbox_integer(_equal);
_outExp = omc_VarTransform_replaceExpRepeated2(threadData, _e, _repl, _func, tmp1, tmp2, tmp3);
return _outExp;
}
DLLExport
modelica_metatype omc_VarTransform_replaceExpRepeated(threadData_t *threadData, modelica_metatype _e, modelica_metatype _repl, modelica_metatype _func, modelica_integer _maxIter)
{
modelica_metatype _outExp = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outExp = omc_VarTransform_replaceExpRepeated2(threadData, _e, _repl, _func, _maxIter, ((modelica_integer) 1), 0);
_return: OMC_LABEL_UNUSED
return _outExp;
}
modelica_metatype boxptr_VarTransform_replaceExpRepeated(threadData_t *threadData, modelica_metatype _e, modelica_metatype _repl, modelica_metatype _func, modelica_metatype _maxIter)
{
modelica_integer tmp1;
modelica_metatype _outExp = NULL;
tmp1 = mmc_unbox_integer(_maxIter);
_outExp = omc_VarTransform_replaceExpRepeated(threadData, _e, _repl, _func, tmp1);
return _outExp;
}
DLLExport
modelica_metatype omc_VarTransform_avoidDoubleHashLookup(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inType)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _cr = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,8,0) == 0) goto tmp3_end;
_cr = tmpMeta6;
tmpMeta1 = omc_Expression_makeCrefExp(threadData, _cr, _inType);
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
modelica_metatype omc_VarTransform_replaceExpOpt(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _repl, modelica_metatype _funcOpt)
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
_e = omc_VarTransform_replaceExp(threadData, _e, _repl, _funcOpt, NULL);
tmpMeta1 = mmc_mk_some(_e);
goto tmp3_done;
}
case 1: {
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
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
DLLExport
modelica_metatype omc_VarTransform_getReplacement(threadData_t *threadData, modelica_metatype _inVariableReplacements, modelica_metatype _inComponentRef)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inVariableReplacements;
tmp4_2 = _inComponentRef;
{
modelica_metatype _src = NULL;
modelica_metatype _ht = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_ht = tmpMeta6;
_src = tmp4_2;
tmpMeta1 = omc_BaseHashTable_get(threadData, _src, _ht);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outComponentRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRef;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_makeTransitive2(threadData_t *threadData, modelica_metatype _repl, modelica_metatype _src, modelica_metatype _dst, modelica_metatype *out_outSrc, modelica_metatype *out_outDst)
{
modelica_metatype _outRepl = NULL;
modelica_metatype _outSrc = NULL;
modelica_metatype _outDst = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _dst_1 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_dst_1 = omc_VarTransform_replaceExp(threadData, _dst, _repl, mmc_mk_none(), NULL);
tmpMeta[0+0] = _repl;
tmpMeta[0+1] = _src;
tmpMeta[0+2] = _dst_1;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _repl;
tmpMeta[0+1] = _src;
tmpMeta[0+2] = _dst;
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
_outRepl = tmpMeta[0+0];
_outSrc = tmpMeta[0+1];
_outDst = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outSrc) { *out_outSrc = _outSrc; }
if (out_outDst) { *out_outDst = _outDst; }
return _outRepl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_makeTransitive12(threadData_t *threadData, modelica_metatype _lst, modelica_metatype _repl, modelica_metatype _singleRepl)
{
modelica_metatype _outRepl = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _lst;
tmp4_2 = _repl;
{
modelica_metatype _crDst = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _crs = NULL;
modelica_metatype _repl1 = NULL;
modelica_metatype _ht = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta1 = _repl;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_cr = tmpMeta6;
_crs = tmpMeta7;
_ht = tmpMeta8;
_crDst = omc_BaseHashTable_get(threadData, _cr, _ht);
_crDst = omc_VarTransform_replaceExp(threadData, _crDst, _singleRepl, mmc_mk_none(), NULL);
_repl1 = omc_VarTransform_addReplacementNoTransitive(threadData, _repl, _cr, _crDst);
_lst = _crs;
_repl = _repl1;
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
_outRepl = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outRepl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_makeTransitive1(threadData_t *threadData, modelica_metatype _repl, modelica_metatype _src, modelica_metatype _dst, modelica_metatype *out_outSrc, modelica_metatype *out_outDst)
{
modelica_metatype _outRepl = NULL;
modelica_metatype _outSrc = NULL;
modelica_metatype _outDst = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _repl;
{
modelica_metatype _lst = NULL;
modelica_metatype _repl_1 = NULL;
modelica_metatype _singleRepl = NULL;
modelica_metatype _invHt = NULL;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_invHt = tmpMeta6;
_lst = omc_BaseHashTable_get(threadData, _src, _invHt);
_singleRepl = omc_VarTransform_addReplacementNoTransitive(threadData, omc_VarTransform_emptyReplacementsSized(threadData, ((modelica_integer) 53)), _src, _dst);
_repl_1 = omc_VarTransform_makeTransitive12(threadData, _lst, _repl, _singleRepl);
tmpMeta[0+0] = _repl_1;
tmpMeta[0+1] = _src;
tmpMeta[0+2] = _dst;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _repl;
tmpMeta[0+1] = _src;
tmpMeta[0+2] = _dst;
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
_outRepl = tmpMeta[0+0];
_outSrc = tmpMeta[0+1];
_outDst = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outSrc) { *out_outSrc = _outSrc; }
if (out_outDst) { *out_outDst = _outDst; }
return _outRepl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_makeTransitive(threadData_t *threadData, modelica_metatype _repl, modelica_metatype _src, modelica_metatype _dst, modelica_metatype *out_outSrc, modelica_metatype *out_outDst)
{
modelica_metatype _outRepl = NULL;
modelica_metatype _outSrc = NULL;
modelica_metatype _outDst = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _repl_1 = NULL;
modelica_metatype _repl_2 = NULL;
modelica_metatype _src_1 = NULL;
modelica_metatype _src_2 = NULL;
modelica_metatype _dst_1 = NULL;
modelica_metatype _dst_2 = NULL;
modelica_metatype _dst_3 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_repl_1 = omc_VarTransform_makeTransitive1(threadData, _repl, _src, _dst ,&_src_1 ,&_dst_1);
_repl_2 = omc_VarTransform_makeTransitive2(threadData, _repl_1, _src_1, _dst_1 ,&_src_2 ,&_dst_2);
_dst_3 = omc_ExpressionSimplify_simplify1(threadData, _dst_2, NULL);
tmpMeta[0+0] = _repl_2;
tmpMeta[0+1] = _src_2;
tmpMeta[0+2] = _dst_3;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outRepl = tmpMeta[0+0];
_outSrc = tmpMeta[0+1];
_outDst = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outSrc) { *out_outSrc = _outSrc; }
if (out_outDst) { *out_outDst = _outDst; }
return _outRepl;
}
DLLExport
modelica_metatype omc_VarTransform_addReplacementIfNot(threadData_t *threadData, modelica_boolean _condition, modelica_metatype _repl, modelica_metatype _inSrc, modelica_metatype _inDst)
{
modelica_metatype _outRepl = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _condition;
tmp4_2 = _inSrc;
tmp4_3 = _inDst;
{
modelica_metatype _src = NULL;
modelica_metatype _dst = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (0 != tmp4_1) goto tmp3_end;
_src = tmp4_2;
_dst = tmp4_3;
tmpMeta1 = omc_VarTransform_addReplacement(threadData, _repl, _src, _dst);
goto tmp3_done;
}
case 1: {
if (1 != tmp4_1) goto tmp3_end;
tmpMeta1 = _repl;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outRepl = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outRepl;
}
modelica_metatype boxptr_VarTransform_addReplacementIfNot(threadData_t *threadData, modelica_metatype _condition, modelica_metatype _repl, modelica_metatype _inSrc, modelica_metatype _inDst)
{
modelica_integer tmp1;
modelica_metatype _outRepl = NULL;
tmp1 = mmc_unbox_integer(_condition);
_outRepl = omc_VarTransform_addReplacementIfNot(threadData, tmp1, _repl, _inSrc, _inDst);
return _outRepl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_amortizeUnion(threadData_t *threadData, modelica_metatype _inCrefs)
{
modelica_metatype _crefs = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (!(modelica_integer_mod(listLength(_inCrefs), ((modelica_integer) 7)) == ((modelica_integer) 0))) goto tmp3_end;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_List_union(threadData, tmpMeta6, _inCrefs);
goto tmp3_done;
}
case 1: {
tmpMeta1 = _inCrefs;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_crefs = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _crefs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_addReplacementInv2(threadData_t *threadData, modelica_metatype _invHt, modelica_metatype _dst, modelica_metatype _src)
{
modelica_metatype _outInvHt = NULL;
modelica_metatype _srcs = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(omc_BaseHashTable_hasKey(threadData, _dst, _invHt))
{
_srcs = omc_BaseHashTable_get(threadData, _dst, _invHt);
tmpMeta1 = mmc_mk_cons(_src, _srcs);
_srcs = omc_VarTransform_amortizeUnion(threadData, tmpMeta1);
tmpMeta2 = mmc_mk_box2(0, _dst, _srcs);
_outInvHt = omc_BaseHashTable_add(threadData, tmpMeta2, _invHt);
}
else
{
tmpMeta3 = mmc_mk_cons(_src, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta4 = mmc_mk_box2(0, _dst, tmpMeta3);
_outInvHt = omc_BaseHashTable_add(threadData, tmpMeta4, _invHt);
}
_return: OMC_LABEL_UNUSED
return _outInvHt;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_addReplacementInv(threadData_t *threadData, modelica_metatype _invHt, modelica_metatype _src, modelica_metatype _dst)
{
modelica_metatype _outInvHt = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _dests = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_dests = omc_Expression_extractCrefsFromExp(threadData, _dst);
tmpMeta1 = omc_List_fold1r(threadData, _dests, boxvar_VarTransform_addReplacementInv2, _src, _invHt);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outInvHt = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outInvHt;
}
DLLExport
modelica_metatype omc_VarTransform_addReplacementNoTransitive(threadData_t *threadData, modelica_metatype _repl, modelica_metatype _src, modelica_metatype _dst)
{
modelica_metatype _outRepl = NULL;
modelica_metatype _ht = NULL;
modelica_metatype _invHt = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outRepl = _repl;
tmpMeta1 = _outRepl;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_ht = tmpMeta2;
_invHt = tmpMeta3;
tmpMeta4 = mmc_mk_box2(0, _src, _dst);
_ht = omc_BaseHashTable_add(threadData, tmpMeta4, _ht);
_invHt = omc_VarTransform_addReplacementInv(threadData, _invHt, _src, _dst);
tmpMeta5 = mmc_mk_box3(3, &VarTransform_VariableReplacements_REPLACEMENTS__desc, _ht, _invHt);
_outRepl = tmpMeta5;
_return: OMC_LABEL_UNUSED
return _outRepl;
}
DLLExport
modelica_metatype omc_VarTransform_addReplacement(threadData_t *threadData, modelica_metatype _repl, modelica_metatype _inSrc, modelica_metatype _inDst)
{
modelica_metatype _outRepl = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _repl;
tmp4_2 = _inSrc;
tmp4_3 = _inDst;
{
modelica_metatype _src = NULL;
modelica_metatype _src_1 = NULL;
modelica_metatype _dst = NULL;
modelica_metatype _dst_1 = NULL;
modelica_metatype _ht = NULL;
modelica_metatype _ht_1 = NULL;
modelica_metatype _invHt = NULL;
modelica_metatype _invHt_1 = NULL;
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
_src = tmp4_2;
_dst = tmp4_3;
tmpMeta8 = omc_VarTransform_makeTransitive(threadData, _repl, _src, _dst, &tmpMeta6, &tmpMeta7);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
_ht = tmpMeta9;
_invHt = tmpMeta10;
_src_1 = tmpMeta6;
_dst_1 = tmpMeta7;
tmpMeta11 = mmc_mk_box2(0, _src_1, _dst_1);
_ht_1 = omc_BaseHashTable_add(threadData, tmpMeta11, _ht);
_invHt_1 = omc_VarTransform_addReplacementInv(threadData, _invHt, _src_1, _dst_1);
tmpMeta12 = mmc_mk_box3(3, &VarTransform_VariableReplacements_REPLACEMENTS__desc, _ht_1, _invHt_1);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 1: {
fputs(MMC_STRINGDATA(_OMC_LIT3),stdout);
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
_outRepl = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outRepl;
}
DLLExport
modelica_metatype omc_VarTransform_addReplacementLst(threadData_t *threadData, modelica_metatype _inRepl, modelica_metatype _crs, modelica_metatype _dsts)
{
modelica_metatype _repl = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inRepl;
tmp4_2 = _crs;
tmp4_3 = _dsts;
{
modelica_metatype _cr = NULL;
modelica_metatype _dst = NULL;
modelica_metatype _crrest = NULL;
modelica_metatype _dstrest = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
if (!listEmpty(tmp4_3)) goto tmp3_end;
_repl = tmp4_1;
tmpMeta1 = _repl;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_3);
tmpMeta9 = MMC_CDR(tmp4_3);
_cr = tmpMeta6;
_crrest = tmpMeta7;
_dst = tmpMeta8;
_dstrest = tmpMeta9;
_repl = tmp4_1;
_repl = omc_VarTransform_addReplacement(threadData, _repl, _cr, _dst);
_inRepl = _repl;
_crs = _crrest;
_dsts = _dstrest;
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
_repl = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _repl;
}
DLLExport
modelica_metatype omc_VarTransform_replacementTargets(threadData_t *threadData, modelica_metatype _repl)
{
modelica_metatype _sources = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _repl;
{
modelica_metatype _targets = NULL;
modelica_metatype _ht = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_ht = tmpMeta6;
_targets = omc_BaseHashTable_hashTableValueList(threadData, _ht);
tmpMeta1 = omc_List_flatten(threadData, omc_List_map(threadData, _targets, boxvar_Expression_extractCrefsFromExp));
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_sources = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _sources;
}
DLLExport
modelica_metatype omc_VarTransform_replacementSources(threadData_t *threadData, modelica_metatype _repl)
{
modelica_metatype _sources = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _repl;
{
modelica_metatype _ht = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_ht = tmpMeta6;
tmpMeta1 = omc_BaseHashTable_hashTableKeyList(threadData, _ht);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_sources = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _sources;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_VarTransform_printReplacementTupleStr(threadData_t *threadData, modelica_metatype _tpl)
{
modelica_string _str = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = stringAppend(omc_ComponentReference_printComponentRefStr(threadData, omc_Util_tuple21(threadData, _tpl)),_OMC_LIT4);
tmpMeta2 = stringAppend(tmpMeta1,omc_ExpressionDump_printExpStr(threadData, omc_Util_tuple22(threadData, _tpl)));
_str = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _str;
}
DLLExport
modelica_metatype omc_VarTransform_getAllReplacements(threadData_t *threadData, modelica_metatype _inVariableReplacements, modelica_metatype *out_dsts)
{
modelica_metatype _crefs = NULL;
modelica_metatype _dsts = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inVariableReplacements;
{
modelica_metatype _ht = NULL;
modelica_metatype _tplLst = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_ht = tmpMeta6;
_tplLst = omc_BaseHashTable_hashTableList(threadData, _ht);
_crefs = omc_List_map(threadData, _tplLst, boxvar_Util_tuple21);
_dsts = omc_List_map(threadData, _tplLst, boxvar_Util_tuple22);
tmpMeta[0+0] = _crefs;
tmpMeta[0+1] = _dsts;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_crefs = tmpMeta[0+0];
_dsts = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_dsts) { *out_dsts = _dsts; }
return _crefs;
}
DLLExport
modelica_string omc_VarTransform_dumpReplacementsStr(threadData_t *threadData, modelica_metatype _inVariableReplacements)
{
modelica_string _ostr = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inVariableReplacements;
{
modelica_string _str = NULL;
modelica_metatype _ht = NULL;
modelica_metatype _tplLst = NULL;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_ht = tmpMeta6;
_tplLst = omc_BaseHashTable_hashTableList(threadData, _ht);
_str = stringDelimitList(omc_List_map(threadData, _tplLst, boxvar_VarTransform_printReplacementTupleStr), _OMC_LIT5);
tmpMeta7 = stringAppend(_OMC_LIT6,intString(listLength(_tplLst)));
tmpMeta8 = stringAppend(tmpMeta7,_OMC_LIT7);
tmpMeta9 = stringAppend(tmpMeta8,_str);
tmpMeta10 = stringAppend(tmpMeta9,_OMC_LIT5);
tmp1 = tmpMeta10;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_ostr = tmp1;
_return: OMC_LABEL_UNUSED
return _ostr;
}
DLLExport
void omc_VarTransform_dumpReplacements(threadData_t *threadData, modelica_metatype _inVariableReplacements)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inVariableReplacements;
{
modelica_string _str = NULL;
modelica_string _len_str = NULL;
modelica_integer _len;
modelica_metatype _ht = NULL;
modelica_metatype _tplLst = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_ht = tmpMeta5;
_tplLst = omc_BaseHashTable_hashTableList(threadData, _ht);
_str = stringDelimitList(omc_List_map(threadData, _tplLst, boxvar_VarTransform_printReplacementTupleStr), _OMC_LIT5);
fputs(MMC_STRINGDATA(_OMC_LIT6),stdout);
_len = listLength(_tplLst);
_len_str = intString(_len);
fputs(MMC_STRINGDATA(_len_str),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT8),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT9),stdout);
fputs(MMC_STRINGDATA(_str),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT5),stdout);
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_replaceOptEquationsStmts(threadData_t *threadData, modelica_metatype _optStmt, modelica_metatype _inVariableReplacements, modelica_metatype _condExpFunc, modelica_boolean *out_replacementPerformed)
{
modelica_metatype _outAlgorithmStatementLst = NULL;
modelica_boolean _replacementPerformed;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _optStmt;
{
modelica_metatype _stmt = NULL;
modelica_metatype _stmt2 = NULL;
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
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_stmt = tmpMeta6;
tmpMeta8 = mmc_mk_cons(_stmt, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta9 = omc_VarTransform_replaceEquationsStmts(threadData, tmpMeta8, _inVariableReplacements, _condExpFunc, &tmp7);
if (listEmpty(tmpMeta9)) goto goto_2;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
if (!listEmpty(tmpMeta11)) goto goto_2;
_stmt2 = tmpMeta10;
if (1 != tmp7) goto goto_2;
tmpMeta[0+0] = mmc_mk_some(_stmt2);
tmp1_c1 = 1;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _optStmt;
tmp1_c1 = 0;
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
_outAlgorithmStatementLst = tmpMeta[0+0];
_replacementPerformed = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_replacementPerformed) { *out_replacementPerformed = _replacementPerformed; }
return _outAlgorithmStatementLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_VarTransform_replaceOptEquationsStmts(threadData_t *threadData, modelica_metatype _optStmt, modelica_metatype _inVariableReplacements, modelica_metatype _condExpFunc, modelica_metatype *out_replacementPerformed)
{
modelica_boolean _replacementPerformed;
modelica_metatype _outAlgorithmStatementLst = NULL;
_outAlgorithmStatementLst = omc_VarTransform_replaceOptEquationsStmts(threadData, _optStmt, _inVariableReplacements, _condExpFunc, &_replacementPerformed);
if (out_replacementPerformed) { *out_replacementPerformed = mmc_mk_icon(_replacementPerformed); }
return _outAlgorithmStatementLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_replaceEquationsElse(threadData_t *threadData, modelica_metatype _inElse, modelica_metatype _repl, modelica_metatype _condExpFunc, modelica_boolean *out_replacementPerformed)
{
modelica_metatype _outElse = NULL;
modelica_boolean _replacementPerformed;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inElse;
{
modelica_metatype _e = NULL;
modelica_metatype _e_1 = NULL;
modelica_metatype _st = NULL;
modelica_metatype _st_1 = NULL;
modelica_metatype _el = NULL;
modelica_metatype _el_1 = NULL;
modelica_boolean _b1;
modelica_boolean _b2;
modelica_boolean _b3;
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
modelica_boolean tmp9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e = tmpMeta6;
_st = tmpMeta7;
_el = tmpMeta8;
tmp4 += 1;
_el_1 = omc_VarTransform_replaceEquationsElse(threadData, _el, _repl, _condExpFunc ,&_b1);
_st_1 = omc_VarTransform_replaceEquationsStmts(threadData, _st, _repl, _condExpFunc ,&_b2);
_e_1 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc ,&_b3);
tmp9 = ((_b1 || _b2) || _b3);
if (1 != tmp9) goto goto_2;
tmpMeta10 = mmc_mk_box4(4, &DAE_Else_ELSEIF__desc, _e_1, _st_1, _el_1);
tmpMeta[0+0] = tmpMeta10;
tmp1_c1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_boolean tmp12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_st = tmpMeta11;
tmpMeta13 = omc_VarTransform_replaceEquationsStmts(threadData, _st, _repl, _condExpFunc, &tmp12);
_st_1 = tmpMeta13;
if (1 != tmp12) goto goto_2;
tmpMeta14 = mmc_mk_box2(5, &DAE_Else_ELSE__desc, _st_1);
tmpMeta[0+0] = tmpMeta14;
tmp1_c1 = 1;
goto tmp3_done;
}
case 2: {
tmpMeta[0+0] = _inElse;
tmp1_c1 = 0;
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
_outElse = tmpMeta[0+0];
_replacementPerformed = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_replacementPerformed) { *out_replacementPerformed = _replacementPerformed; }
return _outElse;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_VarTransform_replaceEquationsElse(threadData_t *threadData, modelica_metatype _inElse, modelica_metatype _repl, modelica_metatype _condExpFunc, modelica_metatype *out_replacementPerformed)
{
modelica_boolean _replacementPerformed;
modelica_metatype _outElse = NULL;
_outElse = omc_VarTransform_replaceEquationsElse(threadData, _inElse, _repl, _condExpFunc, &_replacementPerformed);
if (out_replacementPerformed) { *out_replacementPerformed = mmc_mk_icon(_replacementPerformed); }
return _outElse;
}
DLLExport
modelica_metatype omc_VarTransform_replaceEquationsStmts(threadData_t *threadData, modelica_metatype _inAlgorithmStatementLst, modelica_metatype _repl, modelica_metatype _condExpFunc, modelica_boolean *out_replacementPerformed)
{
modelica_metatype _outAlgorithmStatementLst = NULL;
modelica_boolean _replacementPerformed;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inAlgorithmStatementLst;
{
modelica_metatype _e_1 = NULL;
modelica_metatype _e_2 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e3 = NULL;
modelica_metatype _e_3 = NULL;
modelica_metatype _expl1 = NULL;
modelica_metatype _expl2 = NULL;
modelica_metatype _xs_1 = NULL;
modelica_metatype _xs = NULL;
modelica_metatype _stmts = NULL;
modelica_metatype _stmts2 = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _x = NULL;
modelica_boolean _b1;
modelica_boolean _b2;
modelica_boolean _b3;
modelica_string _id1 = NULL;
modelica_metatype _source = NULL;
modelica_metatype _ew = NULL;
modelica_metatype _ew_1 = NULL;
modelica_metatype _conditions = NULL;
modelica_boolean _initialCall;
modelica_boolean _iterIsArray;
modelica_metatype _el = NULL;
modelica_metatype _el_1 = NULL;
modelica_integer _ix;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 13; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp4 += 12;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = tmpMeta6;
tmp1_c1 = 0;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_boolean tmp13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,4) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
_tp = tmpMeta9;
_e2 = tmpMeta10;
_e = tmpMeta11;
_source = tmpMeta12;
_xs = tmpMeta8;
tmp4 += 10;
_e_1 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc ,&_b1);
_e_2 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc ,&_b2);
tmp13 = (_b1 || _b2);
if (1 != tmp13) goto goto_2;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc, NULL);
tmpMeta15 = mmc_mk_box5(3, &DAE_Statement_STMT__ASSIGN__desc, _tp, _e_2, _e_1, _source);
tmpMeta14 = mmc_mk_cons(tmpMeta15, _xs_1);
tmpMeta[0+0] = tmpMeta14;
tmp1_c1 = 1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_boolean tmp22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmp4_1);
tmpMeta17 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,1,4) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 3));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 4));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 5));
_tp = tmpMeta18;
_expl1 = tmpMeta19;
_e = tmpMeta20;
_source = tmpMeta21;
_xs = tmpMeta17;
tmp4 += 9;
_e_1 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc ,&_b1);
_expl2 = omc_VarTransform_replaceExpList(threadData, _expl1, _repl, _condExpFunc ,&_b2);
tmp22 = (_b1 || _b2);
if (1 != tmp22) goto goto_2;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc, NULL);
tmpMeta24 = mmc_mk_box5(4, &DAE_Statement_STMT__TUPLE__ASSIGN__desc, _tp, _expl2, _e_1, _source);
tmpMeta23 = mmc_mk_cons(tmpMeta24, _xs_1);
tmpMeta[0+0] = tmpMeta23;
tmp1_c1 = 1;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_boolean tmp31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta25 = MMC_CAR(tmp4_1);
tmpMeta26 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta25,2,4) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 2));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 3));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 4));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 5));
_tp = tmpMeta27;
_e1 = tmpMeta28;
_e2 = tmpMeta29;
_source = tmpMeta30;
_xs = tmpMeta26;
tmp4 += 8;
_e_1 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc ,&_b1);
_e_2 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc ,&_b2);
tmp31 = (_b1 || _b2);
if (1 != tmp31) goto goto_2;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc, NULL);
tmpMeta33 = mmc_mk_box5(5, &DAE_Statement_STMT__ASSIGN__ARR__desc, _tp, _e_1, _e_2, _source);
tmpMeta32 = mmc_mk_cons(tmpMeta33, _xs_1);
tmpMeta[0+0] = tmpMeta32;
tmp1_c1 = 1;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_boolean tmp40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta34 = MMC_CAR(tmp4_1);
tmpMeta35 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta34,3,4) == 0) goto tmp3_end;
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 2));
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 3));
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 4));
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 5));
_e = tmpMeta36;
_stmts = tmpMeta37;
_el = tmpMeta38;
_source = tmpMeta39;
_xs = tmpMeta35;
tmp4 += 7;
_el_1 = omc_VarTransform_replaceEquationsElse(threadData, _el, _repl, _condExpFunc ,&_b1);
_stmts2 = omc_VarTransform_replaceEquationsStmts(threadData, _stmts, _repl, _condExpFunc ,&_b2);
_e_1 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc ,&_b3);
tmp40 = ((_b1 || _b2) || _b3);
if (1 != tmp40) goto goto_2;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc, NULL);
tmpMeta42 = mmc_mk_box5(6, &DAE_Statement_STMT__IF__desc, _e_1, _stmts2, _el_1, _source);
tmpMeta41 = mmc_mk_cons(tmpMeta42, _xs_1);
tmpMeta[0+0] = tmpMeta41;
tmp1_c1 = 1;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_integer tmp47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_integer tmp50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
modelica_boolean tmp54;
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta43 = MMC_CAR(tmp4_1);
tmpMeta44 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta43,4,7) == 0) goto tmp3_end;
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta43), 2));
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta43), 3));
tmp47 = mmc_unbox_integer(tmpMeta46);
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta43), 4));
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta43), 5));
tmp50 = mmc_unbox_integer(tmpMeta49);
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta43), 6));
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta43), 7));
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta43), 8));
_tp = tmpMeta45;
_iterIsArray = tmp47;
_id1 = tmpMeta48;
_ix = tmp50;
_e = tmpMeta51;
_stmts = tmpMeta52;
_source = tmpMeta53;
_xs = tmpMeta44;
tmp4 += 6;
_stmts2 = omc_VarTransform_replaceEquationsStmts(threadData, _stmts, _repl, _condExpFunc ,&_b1);
_e_1 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc ,&_b2);
tmp54 = (_b1 || _b2);
if (1 != tmp54) goto goto_2;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc, NULL);
tmpMeta56 = mmc_mk_box8(7, &DAE_Statement_STMT__FOR__desc, _tp, mmc_mk_boolean(_iterIsArray), _id1, mmc_mk_integer(_ix), _e_1, _stmts2, _source);
tmpMeta55 = mmc_mk_cons(tmpMeta56, _xs_1);
tmpMeta[0+0] = tmpMeta55;
tmp1_c1 = 1;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta57;
modelica_metatype tmpMeta58;
modelica_metatype tmpMeta59;
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
modelica_boolean tmp62;
modelica_metatype tmpMeta63;
modelica_metatype tmpMeta64;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta57 = MMC_CAR(tmp4_1);
tmpMeta58 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta57,6,3) == 0) goto tmp3_end;
tmpMeta59 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta57), 2));
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta57), 3));
tmpMeta61 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta57), 4));
_e = tmpMeta59;
_stmts = tmpMeta60;
_source = tmpMeta61;
_xs = tmpMeta58;
tmp4 += 5;
_stmts2 = omc_VarTransform_replaceEquationsStmts(threadData, _stmts, _repl, _condExpFunc ,&_b1);
_e_1 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc ,&_b2);
tmp62 = (_b1 || _b2);
if (1 != tmp62) goto goto_2;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc, NULL);
tmpMeta64 = mmc_mk_box4(9, &DAE_Statement_STMT__WHILE__desc, _e_1, _stmts2, _source);
tmpMeta63 = mmc_mk_cons(tmpMeta64, _xs_1);
tmpMeta[0+0] = tmpMeta63;
tmp1_c1 = 1;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
modelica_metatype tmpMeta67;
modelica_metatype tmpMeta68;
modelica_metatype tmpMeta69;
modelica_integer tmp70;
modelica_metatype tmpMeta71;
modelica_metatype tmpMeta72;
modelica_metatype tmpMeta73;
modelica_boolean tmp74;
modelica_metatype tmpMeta75;
modelica_metatype tmpMeta76;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta65 = MMC_CAR(tmp4_1);
tmpMeta66 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta65,7,6) == 0) goto tmp3_end;
tmpMeta67 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta65), 2));
tmpMeta68 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta65), 3));
tmpMeta69 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta65), 4));
tmp70 = mmc_unbox_integer(tmpMeta69);
tmpMeta71 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta65), 5));
tmpMeta72 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta65), 6));
tmpMeta73 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta65), 7));
_e = tmpMeta67;
_conditions = tmpMeta68;
_initialCall = tmp70;
_stmts = tmpMeta71;
_ew = tmpMeta72;
_source = tmpMeta73;
_xs = tmpMeta66;
tmp4 += 4;
_ew_1 = omc_VarTransform_replaceOptEquationsStmts(threadData, _ew, _repl, _condExpFunc ,&_b1);
_stmts2 = omc_VarTransform_replaceEquationsStmts(threadData, _stmts, _repl, _condExpFunc ,&_b2);
_e_1 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc ,&_b3);
tmp74 = ((_b1 || _b2) || _b3);
if (1 != tmp74) goto goto_2;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc, NULL);
tmpMeta76 = mmc_mk_box7(10, &DAE_Statement_STMT__WHEN__desc, _e_1, _conditions, mmc_mk_boolean(_initialCall), _stmts2, _ew_1, _source);
tmpMeta75 = mmc_mk_cons(tmpMeta76, _xs_1);
tmpMeta[0+0] = tmpMeta75;
tmp1_c1 = 1;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta77;
modelica_metatype tmpMeta78;
modelica_metatype tmpMeta79;
modelica_metatype tmpMeta80;
modelica_metatype tmpMeta81;
modelica_metatype tmpMeta82;
modelica_boolean tmp83;
modelica_metatype tmpMeta84;
modelica_metatype tmpMeta85;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta77 = MMC_CAR(tmp4_1);
tmpMeta78 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta77,8,4) == 0) goto tmp3_end;
tmpMeta79 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta77), 2));
tmpMeta80 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta77), 3));
tmpMeta81 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta77), 4));
tmpMeta82 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta77), 5));
_e = tmpMeta79;
_e2 = tmpMeta80;
_e3 = tmpMeta81;
_source = tmpMeta82;
_xs = tmpMeta78;
tmp4 += 3;
_e_1 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc ,&_b1);
_e_2 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc ,&_b2);
_e_3 = omc_VarTransform_replaceExp(threadData, _e3, _repl, _condExpFunc ,&_b3);
tmp83 = ((_b1 || _b2) || _b3);
if (1 != tmp83) goto goto_2;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc, NULL);
tmpMeta85 = mmc_mk_box5(11, &DAE_Statement_STMT__ASSERT__desc, _e_1, _e_2, _e_3, _source);
tmpMeta84 = mmc_mk_cons(tmpMeta85, _xs_1);
tmpMeta[0+0] = tmpMeta84;
tmp1_c1 = 1;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta86;
modelica_metatype tmpMeta87;
modelica_metatype tmpMeta88;
modelica_metatype tmpMeta89;
modelica_boolean tmp90;
modelica_metatype tmpMeta91;
modelica_metatype tmpMeta92;
modelica_metatype tmpMeta93;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta86 = MMC_CAR(tmp4_1);
tmpMeta87 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta86,9,2) == 0) goto tmp3_end;
tmpMeta88 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta86), 2));
tmpMeta89 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta86), 3));
_e = tmpMeta88;
_source = tmpMeta89;
_xs = tmpMeta87;
tmp4 += 2;
tmpMeta91 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc, &tmp90);
_e_1 = tmpMeta91;
if (1 != tmp90) goto goto_2;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc, NULL);
tmpMeta93 = mmc_mk_box3(12, &DAE_Statement_STMT__TERMINATE__desc, _e_1, _source);
tmpMeta92 = mmc_mk_cons(tmpMeta93, _xs_1);
tmpMeta[0+0] = tmpMeta92;
tmp1_c1 = 1;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta94;
modelica_metatype tmpMeta95;
modelica_metatype tmpMeta96;
modelica_metatype tmpMeta97;
modelica_metatype tmpMeta98;
modelica_boolean tmp99;
modelica_metatype tmpMeta100;
modelica_metatype tmpMeta101;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta94 = MMC_CAR(tmp4_1);
tmpMeta95 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta94,10,3) == 0) goto tmp3_end;
tmpMeta96 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta94), 2));
tmpMeta97 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta94), 3));
tmpMeta98 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta94), 4));
_e = tmpMeta96;
_e2 = tmpMeta97;
_source = tmpMeta98;
_xs = tmpMeta95;
tmp4 += 1;
_e_1 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc ,&_b1);
_e_2 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc ,&_b2);
tmp99 = (_b1 || _b2);
if (1 != tmp99) goto goto_2;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc, NULL);
tmpMeta101 = mmc_mk_box4(13, &DAE_Statement_STMT__REINIT__desc, _e_1, _e_2, _source);
tmpMeta100 = mmc_mk_cons(tmpMeta101, _xs_1);
tmpMeta[0+0] = tmpMeta100;
tmp1_c1 = 1;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta102;
modelica_metatype tmpMeta103;
modelica_metatype tmpMeta104;
modelica_metatype tmpMeta105;
modelica_boolean tmp106;
modelica_metatype tmpMeta107;
modelica_metatype tmpMeta108;
modelica_metatype tmpMeta109;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta102 = MMC_CAR(tmp4_1);
tmpMeta103 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta102,11,2) == 0) goto tmp3_end;
tmpMeta104 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta102), 2));
tmpMeta105 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta102), 3));
_e = tmpMeta104;
_source = tmpMeta105;
_xs = tmpMeta103;
tmpMeta107 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc, &tmp106);
_e_1 = tmpMeta107;
if (1 != tmp106) goto goto_2;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc, NULL);
tmpMeta109 = mmc_mk_box3(14, &DAE_Statement_STMT__NORETCALL__desc, _e_1, _source);
tmpMeta108 = mmc_mk_cons(tmpMeta109, _xs_1);
tmpMeta[0+0] = tmpMeta108;
tmp1_c1 = 1;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta110;
modelica_metatype tmpMeta111;
modelica_metatype tmpMeta112;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta110 = MMC_CAR(tmp4_1);
tmpMeta111 = MMC_CDR(tmp4_1);
_x = tmpMeta110;
_xs = tmpMeta111;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc ,&_b1);
tmpMeta112 = mmc_mk_cons(_x, _xs_1);
tmpMeta[0+0] = tmpMeta112;
tmp1_c1 = _b1;
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
if (++tmp4 < 13) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outAlgorithmStatementLst = tmpMeta[0+0];
_replacementPerformed = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_replacementPerformed) { *out_replacementPerformed = _replacementPerformed; }
return _outAlgorithmStatementLst;
}
modelica_metatype boxptr_VarTransform_replaceEquationsStmts(threadData_t *threadData, modelica_metatype _inAlgorithmStatementLst, modelica_metatype _repl, modelica_metatype _condExpFunc, modelica_metatype *out_replacementPerformed)
{
modelica_boolean _replacementPerformed;
modelica_metatype _outAlgorithmStatementLst = NULL;
_outAlgorithmStatementLst = omc_VarTransform_replaceEquationsStmts(threadData, _inAlgorithmStatementLst, _repl, _condExpFunc, &_replacementPerformed);
if (out_replacementPerformed) { *out_replacementPerformed = mmc_mk_icon(_replacementPerformed); }
return _outAlgorithmStatementLst;
}
DLLExport
modelica_metatype omc_VarTransform_emptyReplacementsSized(threadData_t *threadData, modelica_integer _size)
{
modelica_metatype _outVariableReplacements = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _ht = NULL;
modelica_metatype _invHt = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
_ht = omc_HashTable2_emptyHashTableSized(threadData, _size);
_invHt = omc_HashTable3_emptyHashTableSized(threadData, _size);
tmpMeta6 = mmc_mk_box3(3, &VarTransform_VariableReplacements_REPLACEMENTS__desc, _ht, _invHt);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outVariableReplacements = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outVariableReplacements;
}
modelica_metatype boxptr_VarTransform_emptyReplacementsSized(threadData_t *threadData, modelica_metatype _size)
{
modelica_integer tmp1;
modelica_metatype _outVariableReplacements = NULL;
tmp1 = mmc_unbox_integer(_size);
_outVariableReplacements = omc_VarTransform_emptyReplacementsSized(threadData, tmp1);
return _outVariableReplacements;
}
DLLExport
modelica_metatype omc_VarTransform_emptyReplacements(threadData_t *threadData)
{
modelica_metatype _outVariableReplacements = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _ht = NULL;
modelica_metatype _invHt = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
_ht = omc_HashTable2_emptyHashTable(threadData);
_invHt = omc_HashTable3_emptyHashTable(threadData);
tmpMeta6 = mmc_mk_box3(3, &VarTransform_VariableReplacements_REPLACEMENTS__desc, _ht, _invHt);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outVariableReplacements = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outVariableReplacements;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_emptyReplacementsArray2(threadData_t *threadData, modelica_integer _n)
{
modelica_metatype _replLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_integer tmp4_1;
tmp4_1 = _n;
{
modelica_metatype _r = NULL;
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
if (0 != tmp4_1) goto tmp3_end;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp7;
tmp7 = (_n < ((modelica_integer) 0));
if (1 != tmp7) goto goto_2;
fputs(MMC_STRINGDATA(_OMC_LIT10),stdout);
goto goto_2;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp8;
modelica_metatype tmpMeta9;
tmp8 = (_n > ((modelica_integer) 0));
if (1 != tmp8) goto goto_2;
_r = omc_VarTransform_emptyReplacements(threadData);
_replLst = omc_VarTransform_emptyReplacementsArray2(threadData, ((modelica_integer) -1) + _n);
tmpMeta9 = mmc_mk_cons(_r, _replLst);
tmpMeta1 = tmpMeta9;
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
_replLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _replLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_VarTransform_emptyReplacementsArray2(threadData_t *threadData, modelica_metatype _n)
{
modelica_integer tmp1;
modelica_metatype _replLst = NULL;
tmp1 = mmc_unbox_integer(_n);
_replLst = omc_VarTransform_emptyReplacementsArray2(threadData, tmp1);
return _replLst;
}
DLLExport
modelica_metatype omc_VarTransform_emptyReplacementsArray(threadData_t *threadData, modelica_integer _n)
{
modelica_metatype _repl = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_repl = listArray(omc_VarTransform_emptyReplacementsArray2(threadData, _n));
_return: OMC_LABEL_UNUSED
return _repl;
}
modelica_metatype boxptr_VarTransform_emptyReplacementsArray(threadData_t *threadData, modelica_metatype _n)
{
modelica_integer tmp1;
modelica_metatype _repl = NULL;
tmp1 = mmc_unbox_integer(_n);
_repl = omc_VarTransform_emptyReplacementsArray(threadData, tmp1);
return _repl;
}
DLLExport
modelica_metatype omc_VarTransform_applyReplacementsExp(threadData_t *threadData, modelica_metatype _repl, modelica_metatype _inExp1, modelica_metatype _inExp2, modelica_metatype *out_outExp2)
{
modelica_metatype _outExp1 = NULL;
modelica_metatype _outExp2 = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inExp1;
tmp4_2 = _inExp2;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_e1 = tmp4_1;
_e2 = tmp4_2;
_e1 = omc_VarTransform_replaceExp(threadData, _e1, _repl, mmc_mk_none(), NULL);
_e2 = omc_VarTransform_replaceExp(threadData, _e2, _repl, mmc_mk_none(), NULL);
_e1 = omc_ExpressionSimplify_simplify1(threadData, _e1, NULL);
_e2 = omc_ExpressionSimplify_simplify1(threadData, _e2, NULL);
tmpMeta[0+0] = _e1;
tmpMeta[0+1] = _e2;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outExp1 = tmpMeta[0+0];
_outExp2 = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outExp2) { *out_outExp2 = _outExp2; }
return _outExp1;
}
DLLExport
modelica_metatype omc_VarTransform_applyReplacementList(threadData_t *threadData, modelica_metatype _repl, modelica_metatype _increfs)
{
modelica_metatype _ocrefs = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _increfs;
{
modelica_metatype _cr1_1 = NULL;
modelica_metatype _cr1 = NULL;
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
_cr1 = tmpMeta7;
_ocrefs = tmpMeta8;
tmpMeta9 = omc_VarTransform_replaceExp(threadData, omc_Expression_crefExp(threadData, _cr1), _repl, mmc_mk_none(), NULL);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,6,2) == 0) goto goto_2;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
_cr1_1 = tmpMeta10;
_ocrefs = omc_VarTransform_applyReplacementList(threadData, _repl, _ocrefs);
tmpMeta11 = mmc_mk_cons(_cr1_1, _ocrefs);
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
_ocrefs = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _ocrefs;
}
DLLExport
modelica_metatype omc_VarTransform_applyReplacements(threadData_t *threadData, modelica_metatype _inVariableReplacements1, modelica_metatype _inComponentRef2, modelica_metatype _inComponentRef3, modelica_metatype *out_outComponentRef2)
{
modelica_metatype _outComponentRef1 = NULL;
modelica_metatype _outComponentRef2 = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inVariableReplacements1;
tmp4_2 = _inComponentRef2;
tmp4_3 = _inComponentRef3;
{
modelica_metatype _cr1_1 = NULL;
modelica_metatype _cr2_1 = NULL;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
modelica_metatype _repl = NULL;
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
_repl = tmp4_1;
_cr1 = tmp4_2;
_cr2 = tmp4_3;
tmpMeta6 = omc_VarTransform_replaceExp(threadData, omc_Expression_crefExp(threadData, _cr1), _repl, mmc_mk_none(), NULL);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,6,2) == 0) goto goto_2;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_cr1_1 = tmpMeta7;
tmpMeta8 = omc_VarTransform_replaceExp(threadData, omc_Expression_crefExp(threadData, _cr2), _repl, mmc_mk_none(), NULL);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,6,2) == 0) goto goto_2;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
_cr2_1 = tmpMeta9;
tmpMeta[0+0] = _cr1_1;
tmpMeta[0+1] = _cr2_1;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outComponentRef1 = tmpMeta[0+0];
_outComponentRef2 = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outComponentRef2) { *out_outComponentRef2 = _outComponentRef2; }
return _outComponentRef1;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_applyReplacementsVarAttr(threadData_t *threadData, modelica_metatype _attr, modelica_metatype _repl, modelica_metatype _condExpFunc)
{
modelica_metatype _outAttr = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _attr;
{
modelica_metatype _quantity = NULL;
modelica_metatype _unit = NULL;
modelica_metatype _displayUnit = NULL;
modelica_metatype _min = NULL;
modelica_metatype _max = NULL;
modelica_metatype _initial_ = NULL;
modelica_metatype _fixed = NULL;
modelica_metatype _nominal = NULL;
modelica_metatype _startOrigin = NULL;
modelica_metatype _stateSelect = NULL;
modelica_metatype _unc = NULL;
modelica_metatype _dist = NULL;
modelica_metatype _eb = NULL;
modelica_metatype _ip = NULL;
modelica_metatype _fn = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
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
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,15) == 0) goto tmp3_end;
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
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 12));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 13));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 14));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 15));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 16));
_quantity = tmpMeta7;
_unit = tmpMeta8;
_displayUnit = tmpMeta9;
_min = tmpMeta10;
_max = tmpMeta11;
_initial_ = tmpMeta12;
_fixed = tmpMeta13;
_nominal = tmpMeta14;
_stateSelect = tmpMeta15;
_unc = tmpMeta16;
_dist = tmpMeta17;
_eb = tmpMeta18;
_ip = tmpMeta19;
_fn = tmpMeta20;
_startOrigin = tmpMeta21;
_quantity = omc_VarTransform_replaceExpOpt(threadData, _quantity, _repl, _condExpFunc);
_unit = omc_VarTransform_replaceExpOpt(threadData, _unit, _repl, _condExpFunc);
_displayUnit = omc_VarTransform_replaceExpOpt(threadData, _displayUnit, _repl, _condExpFunc);
_min = omc_VarTransform_replaceExpOpt(threadData, _min, _repl, _condExpFunc);
_max = omc_VarTransform_replaceExpOpt(threadData, _max, _repl, _condExpFunc);
_initial_ = omc_VarTransform_replaceExpOpt(threadData, _initial_, _repl, _condExpFunc);
_fixed = omc_VarTransform_replaceExpOpt(threadData, _fixed, _repl, _condExpFunc);
_nominal = omc_VarTransform_replaceExpOpt(threadData, _nominal, _repl, _condExpFunc);
tmpMeta22 = mmc_mk_box16(3, &DAE_VariableAttributes_VAR__ATTR__REAL__desc, _quantity, _unit, _displayUnit, _min, _max, _initial_, _fixed, _nominal, _stateSelect, _unc, _dist, _eb, _ip, _fn, _startOrigin);
tmpMeta1 = mmc_mk_some(tmpMeta22);
goto tmp3_done;
}
case 1: {
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
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta23,1,11) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 2));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 3));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 4));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 5));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 6));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 7));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 8));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 9));
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 10));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 11));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 12));
_quantity = tmpMeta24;
_min = tmpMeta25;
_max = tmpMeta26;
_initial_ = tmpMeta27;
_fixed = tmpMeta28;
_unc = tmpMeta29;
_dist = tmpMeta30;
_eb = tmpMeta31;
_ip = tmpMeta32;
_fn = tmpMeta33;
_startOrigin = tmpMeta34;
_quantity = omc_VarTransform_replaceExpOpt(threadData, _quantity, _repl, _condExpFunc);
_min = omc_VarTransform_replaceExpOpt(threadData, _min, _repl, _condExpFunc);
_max = omc_VarTransform_replaceExpOpt(threadData, _max, _repl, _condExpFunc);
_initial_ = omc_VarTransform_replaceExpOpt(threadData, _initial_, _repl, _condExpFunc);
_fixed = omc_VarTransform_replaceExpOpt(threadData, _fixed, _repl, _condExpFunc);
tmpMeta35 = mmc_mk_box12(4, &DAE_VariableAttributes_VAR__ATTR__INT__desc, _quantity, _min, _max, _initial_, _fixed, _unc, _dist, _eb, _ip, _fn, _startOrigin);
tmpMeta1 = mmc_mk_some(tmpMeta35);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta36,2,7) == 0) goto tmp3_end;
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta36), 2));
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta36), 3));
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta36), 4));
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta36), 5));
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta36), 6));
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta36), 7));
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta36), 8));
_quantity = tmpMeta37;
_initial_ = tmpMeta38;
_fixed = tmpMeta39;
_eb = tmpMeta40;
_ip = tmpMeta41;
_fn = tmpMeta42;
_startOrigin = tmpMeta43;
_quantity = omc_VarTransform_replaceExpOpt(threadData, _quantity, _repl, _condExpFunc);
_initial_ = omc_VarTransform_replaceExpOpt(threadData, _initial_, _repl, _condExpFunc);
_fixed = omc_VarTransform_replaceExpOpt(threadData, _fixed, _repl, _condExpFunc);
tmpMeta44 = mmc_mk_box8(5, &DAE_VariableAttributes_VAR__ATTR__BOOL__desc, _quantity, _initial_, _fixed, _eb, _ip, _fn, _startOrigin);
tmpMeta1 = mmc_mk_some(tmpMeta44);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta45,4,7) == 0) goto tmp3_end;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 2));
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 3));
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 4));
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 5));
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 6));
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 7));
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 8));
_quantity = tmpMeta46;
_initial_ = tmpMeta47;
_fixed = tmpMeta48;
_eb = tmpMeta49;
_ip = tmpMeta50;
_fn = tmpMeta51;
_startOrigin = tmpMeta52;
_quantity = omc_VarTransform_replaceExpOpt(threadData, _quantity, _repl, _condExpFunc);
_initial_ = omc_VarTransform_replaceExpOpt(threadData, _initial_, _repl, _condExpFunc);
_fixed = omc_VarTransform_replaceExpOpt(threadData, _fixed, _repl, _condExpFunc);
tmpMeta53 = mmc_mk_box8(7, &DAE_VariableAttributes_VAR__ATTR__STRING__desc, _quantity, _initial_, _fixed, _eb, _ip, _fn, _startOrigin);
tmpMeta1 = mmc_mk_some(tmpMeta53);
goto tmp3_done;
}
case 4: {
if (!optionNone(tmp4_1)) goto tmp3_end;
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
_outAttr = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAttr;
}
DLLExport
modelica_metatype omc_VarTransform_applyReplacementsDAEElts(threadData_t *threadData, modelica_metatype _inDae, modelica_metatype _repl, modelica_metatype _condExpFunc)
{
modelica_metatype _outDae = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if((omc_BaseHashTable_hashTableCurrentSize(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_repl), 2)))) == ((modelica_integer) 0)))
{
_outDae = _inDae;
goto _return;
}
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype __omcQ_24tmpVar0;
modelica_integer tmp146;
modelica_metatype _elt_loopVar = 0;
modelica_metatype _elt;
_elt_loopVar = _inDae;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar1;
while(1) {
tmp146 = 1;
if (!listEmpty(_elt_loopVar)) {
_elt = MMC_CAR(_elt_loopVar);
_elt_loopVar = MMC_CDR(_elt_loopVar);
tmp146--;
}
if (tmp146 == 0) {
{
modelica_metatype tmp7_1;
tmp7_1 = _elt;
{
modelica_metatype _cr = NULL;
modelica_metatype _cr2 = NULL;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr1_2 = NULL;
modelica_metatype _elist = NULL;
modelica_metatype _elist2 = NULL;
modelica_metatype _elist22 = NULL;
modelica_metatype _elt2 = NULL;
modelica_metatype _kind = NULL;
modelica_metatype _dir = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _bindExp = NULL;
modelica_metatype _bindExp2 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e22 = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e11 = NULL;
modelica_metatype _e3 = NULL;
modelica_metatype _e32 = NULL;
modelica_metatype _dims = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _source = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _io = NULL;
modelica_metatype _idims = NULL;
modelica_string _id = NULL;
modelica_metatype _stmts = NULL;
modelica_metatype _stmts2 = NULL;
modelica_metatype _prl = NULL;
modelica_metatype _prot = NULL;
modelica_metatype _tbs = NULL;
modelica_metatype _tbs_1 = NULL;
modelica_metatype _conds = NULL;
modelica_metatype _conds_1 = NULL;
volatile mmc_switch_type tmp7;
int tmp8;
tmp7 = 0;
for (; tmp7 < 25; tmp7++) {
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
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,0,13) == 0) goto tmp6_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 5));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 6));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 7));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 8));
if (optionNone(tmpMeta15)) goto tmp6_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 1));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 9));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 10));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 11));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 12));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 13));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 14));
_cr = tmpMeta9;
_kind = tmpMeta10;
_dir = tmpMeta11;
_prl = tmpMeta12;
_prot = tmpMeta13;
_tp = tmpMeta14;
_bindExp = tmpMeta16;
_dims = tmpMeta17;
_ct = tmpMeta18;
_source = tmpMeta19;
_attr = tmpMeta20;
_cmt = tmpMeta21;
_io = tmpMeta22;
_bindExp2 = omc_VarTransform_replaceExp(threadData, _bindExp, _repl, _condExpFunc, NULL);
_attr = omc_VarTransform_applyReplacementsVarAttr(threadData, _attr, _repl, _condExpFunc);
tmpMeta23 = mmc_mk_box14(3, &DAE_Element_VAR__desc, _cr, _kind, _dir, _prl, _prot, _tp, mmc_mk_some(_bindExp2), _dims, _ct, _source, _attr, _cmt, _io);
tmpMeta4 = tmpMeta23;
goto tmp6_done;
}
case 1: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,0,13) == 0) goto tmp6_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 5));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 6));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 7));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 8));
if (!optionNone(tmpMeta30)) goto tmp6_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 9));
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 10));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 11));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 12));
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 13));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 14));
_cr = tmpMeta24;
_kind = tmpMeta25;
_dir = tmpMeta26;
_prl = tmpMeta27;
_prot = tmpMeta28;
_tp = tmpMeta29;
_dims = tmpMeta31;
_ct = tmpMeta32;
_source = tmpMeta33;
_attr = tmpMeta34;
_cmt = tmpMeta35;
_io = tmpMeta36;
_attr = omc_VarTransform_applyReplacementsVarAttr(threadData, _attr, _repl, _condExpFunc);
tmpMeta37 = mmc_mk_box14(3, &DAE_Element_VAR__desc, _cr, _kind, _dir, _prl, _prot, _tp, mmc_mk_none(), _dims, _ct, _source, _attr, _cmt, _io);
tmpMeta4 = tmpMeta37;
goto tmp6_done;
}
case 2: {
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,1,3) == 0) goto tmp6_end;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
_cr = tmpMeta38;
_e = tmpMeta39;
_source = tmpMeta40;
_e2 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc, NULL);
tmpMeta41 = omc_VarTransform_replaceExp(threadData, omc_Expression_crefExp(threadData, _cr), _repl, _condExpFunc, NULL);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta41,6,2) == 0) goto goto_5;
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 2));
_cr2 = tmpMeta42;
tmpMeta43 = mmc_mk_box4(4, &DAE_Element_DEFINE__desc, _cr2, _e2, _source);
tmpMeta4 = tmpMeta43;
goto tmp6_done;
}
case 3: {
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,2,3) == 0) goto tmp6_end;
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
_cr = tmpMeta44;
_e = tmpMeta45;
_source = tmpMeta46;
_e2 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc, NULL);
tmpMeta47 = omc_VarTransform_replaceExp(threadData, omc_Expression_crefExp(threadData, _cr), _repl, _condExpFunc, NULL);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta47,6,2) == 0) goto goto_5;
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta47), 2));
_cr2 = tmpMeta48;
tmpMeta49 = mmc_mk_box4(5, &DAE_Element_INITIALDEFINE__desc, _cr2, _e2, _source);
tmpMeta4 = tmpMeta49;
goto tmp6_done;
}
case 4: {
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
modelica_metatype tmpMeta57;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,4,3) == 0) goto tmp6_end;
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
_cr = tmpMeta50;
_cr1 = tmpMeta51;
_source = tmpMeta52;
tmpMeta53 = omc_VarTransform_replaceExp(threadData, omc_Expression_crefExp(threadData, _cr), _repl, _condExpFunc, NULL);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta53,6,2) == 0) goto goto_5;
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta53), 2));
_cr2 = tmpMeta54;
tmpMeta55 = omc_VarTransform_replaceExp(threadData, omc_Expression_crefExp(threadData, _cr1), _repl, _condExpFunc, NULL);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta55,6,2) == 0) goto goto_5;
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta55), 2));
_cr1_2 = tmpMeta56;
tmpMeta57 = mmc_mk_box4(7, &DAE_Element_EQUEQUATION__desc, _cr2, _cr1_2, _source);
tmpMeta4 = tmpMeta57;
goto tmp6_done;
}
case 5: {
modelica_metatype tmpMeta58;
modelica_metatype tmpMeta59;
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,3,3) == 0) goto tmp6_end;
tmpMeta58 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta59 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
_e1 = tmpMeta58;
_e2 = tmpMeta59;
_source = tmpMeta60;
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
_e22 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc, NULL);
tmpMeta61 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _e11, _e22, _source);
tmpMeta4 = tmpMeta61;
goto tmp6_done;
}
case 6: {
modelica_metatype tmpMeta62;
modelica_metatype tmpMeta63;
modelica_metatype tmpMeta64;
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,5,4) == 0) goto tmp6_end;
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta63 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
tmpMeta64 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 5));
_idims = tmpMeta62;
_e1 = tmpMeta63;
_e2 = tmpMeta64;
_source = tmpMeta65;
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
_e22 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc, NULL);
tmpMeta66 = mmc_mk_box5(8, &DAE_Element_ARRAY__EQUATION__desc, _idims, _e11, _e22, _source);
tmpMeta4 = tmpMeta66;
goto tmp6_done;
}
case 7: {
modelica_metatype tmpMeta67;
modelica_metatype tmpMeta68;
modelica_metatype tmpMeta69;
modelica_metatype tmpMeta70;
modelica_metatype tmpMeta71;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,6,4) == 0) goto tmp6_end;
tmpMeta67 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta68 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
tmpMeta69 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
tmpMeta70 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 5));
_idims = tmpMeta67;
_e1 = tmpMeta68;
_e2 = tmpMeta69;
_source = tmpMeta70;
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
_e22 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc, NULL);
tmpMeta71 = mmc_mk_box5(9, &DAE_Element_INITIAL__ARRAY__EQUATION__desc, _idims, _e11, _e22, _source);
tmpMeta4 = tmpMeta71;
goto tmp6_done;
}
case 8: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,10,4) == 0) goto tmp6_end;
tmpMeta72 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta73 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
tmpMeta74 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
if (optionNone(tmpMeta74)) goto tmp6_end;
tmpMeta75 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta74), 1));
tmpMeta76 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 5));
_e1 = tmpMeta72;
_elist = tmpMeta73;
_elt2 = tmpMeta75;
_source = tmpMeta76;
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
tmpMeta77 = mmc_mk_cons(_elt2, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta78 = omc_VarTransform_applyReplacementsDAEElts(threadData, tmpMeta77, _repl, _condExpFunc);
if (listEmpty(tmpMeta78)) goto goto_5;
tmpMeta79 = MMC_CAR(tmpMeta78);
tmpMeta80 = MMC_CDR(tmpMeta78);
if (!listEmpty(tmpMeta80)) goto goto_5;
_elt2 = tmpMeta79;
_elist2 = omc_VarTransform_applyReplacementsDAEElts(threadData, _elist, _repl, _condExpFunc);
tmpMeta81 = mmc_mk_box5(13, &DAE_Element_WHEN__EQUATION__desc, _e11, _elist2, mmc_mk_some(_elt2), _source);
tmpMeta4 = tmpMeta81;
goto tmp6_done;
}
case 9: {
modelica_metatype tmpMeta82;
modelica_metatype tmpMeta83;
modelica_metatype tmpMeta84;
modelica_metatype tmpMeta85;
modelica_metatype tmpMeta86;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,10,4) == 0) goto tmp6_end;
tmpMeta82 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta83 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
tmpMeta84 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
if (!optionNone(tmpMeta84)) goto tmp6_end;
tmpMeta85 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 5));
_e1 = tmpMeta82;
_elist = tmpMeta83;
_source = tmpMeta85;
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
_elist2 = omc_VarTransform_applyReplacementsDAEElts(threadData, _elist, _repl, _condExpFunc);
tmpMeta86 = mmc_mk_box5(13, &DAE_Element_WHEN__EQUATION__desc, _e11, _elist2, mmc_mk_none(), _source);
tmpMeta4 = tmpMeta86;
goto tmp6_done;
}
case 10: {
modelica_metatype tmpMeta87;
modelica_metatype tmpMeta88;
modelica_metatype tmpMeta89;
modelica_metatype tmpMeta90;
modelica_metatype tmpMeta91;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,12,4) == 0) goto tmp6_end;
tmpMeta87 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta88 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
tmpMeta89 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
tmpMeta90 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 5));
_conds = tmpMeta87;
_tbs = tmpMeta88;
_elist2 = tmpMeta89;
_source = tmpMeta90;
_conds_1 = omc_VarTransform_replaceExpList(threadData, _conds, _repl, _condExpFunc, NULL);
_tbs_1 = omc_List_map2(threadData, _tbs, boxvar_VarTransform_applyReplacementsDAEElts, _repl, _condExpFunc);
_elist22 = omc_VarTransform_applyReplacementsDAEElts(threadData, _elist2, _repl, _condExpFunc);
tmpMeta91 = mmc_mk_box5(15, &DAE_Element_IF__EQUATION__desc, _conds_1, _tbs_1, _elist22, _source);
tmpMeta4 = tmpMeta91;
goto tmp6_done;
}
case 11: {
modelica_metatype tmpMeta92;
modelica_metatype tmpMeta93;
modelica_metatype tmpMeta94;
modelica_metatype tmpMeta95;
modelica_metatype tmpMeta96;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,13,4) == 0) goto tmp6_end;
tmpMeta92 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta93 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
tmpMeta94 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
tmpMeta95 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 5));
_conds = tmpMeta92;
_tbs = tmpMeta93;
_elist2 = tmpMeta94;
_source = tmpMeta95;
_conds_1 = omc_VarTransform_replaceExpList(threadData, _conds, _repl, _condExpFunc, NULL);
_tbs_1 = omc_List_map2(threadData, _tbs, boxvar_VarTransform_applyReplacementsDAEElts, _repl, _condExpFunc);
_elist22 = omc_VarTransform_applyReplacementsDAEElts(threadData, _elist2, _repl, _condExpFunc);
tmpMeta96 = mmc_mk_box5(16, &DAE_Element_INITIAL__IF__EQUATION__desc, _conds_1, _tbs_1, _elist22, _source);
tmpMeta4 = tmpMeta96;
goto tmp6_done;
}
case 12: {
modelica_metatype tmpMeta97;
modelica_metatype tmpMeta98;
modelica_metatype tmpMeta99;
modelica_metatype tmpMeta100;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,14,3) == 0) goto tmp6_end;
tmpMeta97 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta98 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
tmpMeta99 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
_e1 = tmpMeta97;
_e2 = tmpMeta98;
_source = tmpMeta99;
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
_e22 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc, NULL);
tmpMeta100 = mmc_mk_box4(17, &DAE_Element_INITIALEQUATION__desc, _e11, _e22, _source);
tmpMeta4 = tmpMeta100;
goto tmp6_done;
}
case 13: {
modelica_metatype tmpMeta101;
modelica_metatype tmpMeta102;
modelica_metatype tmpMeta103;
modelica_metatype tmpMeta104;
modelica_metatype tmpMeta105;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,15,2) == 0) goto tmp6_end;
tmpMeta101 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta102 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta101), 2));
tmpMeta103 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
_stmts = tmpMeta102;
_source = tmpMeta103;
_stmts2 = omc_VarTransform_replaceEquationsStmts(threadData, _stmts, _repl, _condExpFunc, NULL);
tmpMeta104 = mmc_mk_box2(3, &DAE_Algorithm_ALGORITHM__STMTS__desc, _stmts2);
tmpMeta105 = mmc_mk_box3(18, &DAE_Element_ALGORITHM__desc, tmpMeta104, _source);
tmpMeta4 = tmpMeta105;
goto tmp6_done;
}
case 14: {
modelica_metatype tmpMeta106;
modelica_metatype tmpMeta107;
modelica_metatype tmpMeta108;
modelica_metatype tmpMeta109;
modelica_metatype tmpMeta110;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,16,2) == 0) goto tmp6_end;
tmpMeta106 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta107 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta106), 2));
tmpMeta108 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
_stmts = tmpMeta107;
_source = tmpMeta108;
_stmts2 = omc_VarTransform_replaceEquationsStmts(threadData, _stmts, _repl, _condExpFunc, NULL);
tmpMeta109 = mmc_mk_box2(3, &DAE_Algorithm_ALGORITHM__STMTS__desc, _stmts2);
tmpMeta110 = mmc_mk_box3(19, &DAE_Element_INITIALALGORITHM__desc, tmpMeta109, _source);
tmpMeta4 = tmpMeta110;
goto tmp6_done;
}
case 15: {
modelica_metatype tmpMeta111;
modelica_metatype tmpMeta112;
modelica_metatype tmpMeta113;
modelica_metatype tmpMeta114;
modelica_metatype tmpMeta115;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,17,4) == 0) goto tmp6_end;
tmpMeta111 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta112 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
tmpMeta113 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
tmpMeta114 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 5));
_id = tmpMeta111;
_elist = tmpMeta112;
_source = tmpMeta113;
_cmt = tmpMeta114;
_elist = omc_VarTransform_applyReplacementsDAEElts(threadData, _elist, _repl, _condExpFunc);
tmpMeta115 = mmc_mk_box5(20, &DAE_Element_COMP__desc, _id, _elist, _source, _cmt);
tmpMeta4 = tmpMeta115;
goto tmp6_done;
}
case 16: {
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,18,2) == 0) goto tmp6_end;
tmpMeta4 = _elt;
goto tmp6_done;
}
case 17: {
modelica_metatype tmpMeta116;
modelica_metatype tmpMeta117;
modelica_metatype tmpMeta118;
modelica_metatype tmpMeta119;
modelica_metatype tmpMeta120;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,19,4) == 0) goto tmp6_end;
tmpMeta116 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta117 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
tmpMeta118 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
tmpMeta119 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 5));
_e1 = tmpMeta116;
_e2 = tmpMeta117;
_e3 = tmpMeta118;
_source = tmpMeta119;
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
_e22 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc, NULL);
_e32 = omc_VarTransform_replaceExp(threadData, _e3, _repl, _condExpFunc, NULL);
tmpMeta120 = mmc_mk_box5(22, &DAE_Element_ASSERT__desc, _e11, _e22, _e32, _source);
tmpMeta4 = tmpMeta120;
goto tmp6_done;
}
case 18: {
modelica_metatype tmpMeta121;
modelica_metatype tmpMeta122;
modelica_metatype tmpMeta123;
modelica_metatype tmpMeta124;
modelica_metatype tmpMeta125;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,20,4) == 0) goto tmp6_end;
tmpMeta121 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta122 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
tmpMeta123 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
tmpMeta124 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 5));
_e1 = tmpMeta121;
_e2 = tmpMeta122;
_e3 = tmpMeta123;
_source = tmpMeta124;
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
_e22 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc, NULL);
_e32 = omc_VarTransform_replaceExp(threadData, _e3, _repl, _condExpFunc, NULL);
tmpMeta125 = mmc_mk_box5(23, &DAE_Element_INITIAL__ASSERT__desc, _e11, _e22, _e32, _source);
tmpMeta4 = tmpMeta125;
goto tmp6_done;
}
case 19: {
modelica_metatype tmpMeta126;
modelica_metatype tmpMeta127;
modelica_metatype tmpMeta128;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,21,2) == 0) goto tmp6_end;
tmpMeta126 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta127 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
_e1 = tmpMeta126;
_source = tmpMeta127;
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
tmpMeta128 = mmc_mk_box3(24, &DAE_Element_TERMINATE__desc, _e11, _source);
tmpMeta4 = tmpMeta128;
goto tmp6_done;
}
case 20: {
modelica_metatype tmpMeta129;
modelica_metatype tmpMeta130;
modelica_metatype tmpMeta131;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,22,2) == 0) goto tmp6_end;
tmpMeta129 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta130 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
_e1 = tmpMeta129;
_source = tmpMeta130;
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
tmpMeta131 = mmc_mk_box3(25, &DAE_Element_INITIAL__TERMINATE__desc, _e11, _source);
tmpMeta4 = tmpMeta131;
goto tmp6_done;
}
case 21: {
modelica_metatype tmpMeta132;
modelica_metatype tmpMeta133;
modelica_metatype tmpMeta134;
modelica_metatype tmpMeta135;
modelica_metatype tmpMeta136;
modelica_metatype tmpMeta137;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,23,3) == 0) goto tmp6_end;
tmpMeta132 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta133 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
tmpMeta134 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
_cr = tmpMeta132;
_e1 = tmpMeta133;
_source = tmpMeta134;
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
tmpMeta135 = omc_VarTransform_replaceExp(threadData, omc_Expression_crefExp(threadData, _cr), _repl, _condExpFunc, NULL);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta135,6,2) == 0) goto goto_5;
tmpMeta136 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta135), 2));
_cr2 = tmpMeta136;
tmpMeta137 = mmc_mk_box4(26, &DAE_Element_REINIT__desc, _cr2, _e11, _source);
tmpMeta4 = tmpMeta137;
goto tmp6_done;
}
case 22: {
modelica_metatype tmpMeta138;
modelica_metatype tmpMeta139;
modelica_metatype tmpMeta140;
modelica_metatype tmpMeta141;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,8,3) == 0) goto tmp6_end;
tmpMeta138 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta139 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
tmpMeta140 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
_e1 = tmpMeta138;
_e2 = tmpMeta139;
_source = tmpMeta140;
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
_e22 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc, NULL);
tmpMeta141 = mmc_mk_box4(11, &DAE_Element_COMPLEX__EQUATION__desc, _e11, _e22, _source);
tmpMeta4 = tmpMeta141;
goto tmp6_done;
}
case 23: {
modelica_metatype tmpMeta142;
modelica_metatype tmpMeta143;
modelica_metatype tmpMeta144;
modelica_metatype tmpMeta145;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,9,3) == 0) goto tmp6_end;
tmpMeta142 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta143 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
tmpMeta144 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
_e1 = tmpMeta142;
_e2 = tmpMeta143;
_source = tmpMeta144;
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
_e22 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc, NULL);
tmpMeta145 = mmc_mk_box4(12, &DAE_Element_INITIAL__COMPLEX__EQUATION__desc, _e11, _e22, _source);
tmpMeta4 = tmpMeta145;
goto tmp6_done;
}
case 24: {
omc_Error_addInternalError(threadData, _OMC_LIT11, _OMC_LIT12);
goto goto_5;
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
}__omcQ_24tmpVar0 = tmpMeta4;
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp146 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar1;
}
_outDae = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outDae;
}
DLLExport
modelica_metatype omc_VarTransform_applyReplacementsDAE(threadData_t *threadData, modelica_metatype _dae, modelica_metatype _repl, modelica_metatype _condExpFunc)
{
modelica_metatype _outDae = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _dae;
{
modelica_metatype _elts = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_elts = tmpMeta6;
_elts = omc_VarTransform_applyReplacementsDAEElts(threadData, _elts, _repl, _condExpFunc);
tmpMeta7 = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _elts);
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
_outDae = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outDae;
}
