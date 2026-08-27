#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/VarTransform.c"
#endif
#include "omc_simulation_settings.h"
#include "VarTransform.h"
#define _OMC_LIT0_data "Got exp to replace when condition is not allowing replacements. Check traversal."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,80,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Util/VarTransform.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,69,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT2_6,1602262265.0);
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
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT12_6,1602262265.0);
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
modelica_boolean _acc2;
modelica_boolean _c;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_acc1 = tmpMeta[0];
_acc2 = 0;
{
modelica_metatype _exp;
for (tmpMeta[1] = _inTplExpExpBooleanLstLst; !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_exp = MMC_CAR(tmpMeta[1]);
_exp = omc_VarTransform_replaceExpList(threadData, _exp, _inVariableReplacements, _inFuncTypeExpExpToBooleanOption ,&_c);
_acc2 = (_acc2 || _c);
tmpMeta[2] = mmc_mk_cons(_exp, _acc1);
_acc1 = tmpMeta[2];
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
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
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
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_cond = tmpMeta[0];
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
modelica_boolean _acc2;
modelica_boolean _c;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_acc1 = tmpMeta[0];
_acc2 = 0;
{
modelica_metatype _exp;
for (tmpMeta[1] = _iexpl; !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_exp = MMC_CAR(tmpMeta[1]);
_exp = omc_VarTransform_replaceExp(threadData, _exp, _repl, _cond ,&_c);
_acc2 = (_acc2 || _c);
tmpMeta[2] = mmc_mk_cons(_exp, _acc1);
_acc1 = tmpMeta[2];
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
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_cr = tmpMeta[0];
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
_outExp = omc_VarTransform_getReplacement(threadData, _inVarReplacements, _cr);
_outExp = omc_VarTransform_avoidDoubleHashLookup(threadData, _outExp, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inExp), 3))));
_replacementPerformed = 1;
goto tmp6_done;
}
case 1: {
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
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outExp = _inExp;
if(omc_VarTransform_replaceExpCond(threadData, _inCondition, _inExp))
{
tmpMeta[0] = mmc_mk_box2(0, _inVarReplacements, _inCondition);
_outExp = omc_Expression_traverseExpBottomUp(threadData, _inExp, (modelica_fnptr) mmc_mk_box2(0,closure0_VarTransform_replaceExpCref,tmpMeta[0]), mmc_mk_boolean(1), NULL);
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
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_boolean tmp3_1;
tmp3_1 = _equal;
{
modelica_metatype _e1 = NULL;
modelica_boolean _b;
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
tmp5 = (_i > _maxIter);
if (1 != tmp5) goto goto_1;
tmpMeta[0] = _e;
goto tmp2_done;
}
case 1: {
if (1 != tmp3_1) goto tmp2_end;
tmpMeta[0] = _e;
goto tmp2_done;
}
case 2: {
_e1 = omc_VarTransform_replaceExp(threadData, _e, _repl, _func ,&_b);
tmpMeta[0] = omc_VarTransform_replaceExpRepeated2(threadData, _e1, _repl, _func, _maxIter, ((modelica_integer) 1) + _i, (!_b));
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inExp;
{
modelica_metatype _cr = NULL;
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
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],8,0) == 0) goto tmp2_end;
_cr = tmpMeta[1];
tmpMeta[0] = omc_Expression_makeCrefExp(threadData, _cr, _inType);
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
DLLExport
modelica_metatype omc_VarTransform_replaceExpOpt(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _repl, modelica_metatype _funcOpt)
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
_e = omc_VarTransform_replaceExp(threadData, _e, _repl, _funcOpt, NULL);
tmpMeta[0] = mmc_mk_some(_e);
goto tmp2_done;
}
case 1: {
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
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
DLLExport
modelica_metatype omc_VarTransform_getReplacement(threadData_t *threadData, modelica_metatype _inVariableReplacements, modelica_metatype _inComponentRef)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inVariableReplacements;
tmp3_2 = _inComponentRef;
{
modelica_metatype _src = NULL;
modelica_metatype _ht = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_ht = tmpMeta[1];
_src = tmp3_2;
tmpMeta[0] = omc_BaseHashTable_get(threadData, _src, _ht);
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
_outComponentRef = tmpMeta[0];
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
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _lst;
tmp3_2 = _repl;
{
modelica_metatype _crDst = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _crs = NULL;
modelica_metatype _repl1 = NULL;
modelica_metatype _ht = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = _repl;
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
_cr = tmpMeta[1];
_crs = tmpMeta[2];
_ht = tmpMeta[3];
_crDst = omc_BaseHashTable_get(threadData, _cr, _ht);
_crDst = omc_VarTransform_replaceExp(threadData, _crDst, _singleRepl, mmc_mk_none(), NULL);
_repl1 = omc_VarTransform_addReplacementNoTransitive(threadData, _repl, _cr, _crDst);
_lst = _crs;
_repl = _repl1;
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
_outRepl = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outRepl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_makeTransitive1(threadData_t *threadData, modelica_metatype _repl, modelica_metatype _src, modelica_metatype _dst, modelica_metatype *out_outSrc, modelica_metatype *out_outDst)
{
modelica_metatype _outRepl = NULL;
modelica_metatype _outSrc = NULL;
modelica_metatype _outDst = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
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
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_invHt = tmpMeta[3];
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
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean tmp3_1;modelica_metatype tmp3_2;modelica_metatype tmp3_3;
tmp3_1 = _condition;
tmp3_2 = _inSrc;
tmp3_3 = _inDst;
{
modelica_metatype _src = NULL;
modelica_metatype _dst = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (0 != tmp3_1) goto tmp2_end;
_src = tmp3_2;
_dst = tmp3_3;
tmpMeta[0] = omc_VarTransform_addReplacement(threadData, _repl, _src, _dst);
goto tmp2_done;
}
case 1: {
if (1 != tmp3_1) goto tmp2_end;
tmpMeta[0] = _repl;
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
_outRepl = tmpMeta[0];
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
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!(modelica_integer_mod(listLength(_inCrefs), ((modelica_integer) 7)) == ((modelica_integer) 0))) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = omc_List_union(threadData, tmpMeta[1], _inCrefs);
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _inCrefs;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_addReplacementInv2(threadData_t *threadData, modelica_metatype _invHt, modelica_metatype _dst, modelica_metatype _src)
{
modelica_metatype _outInvHt = NULL;
modelica_metatype _srcs = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(omc_BaseHashTable_hasKey(threadData, _dst, _invHt))
{
_srcs = omc_BaseHashTable_get(threadData, _dst, _invHt);
tmpMeta[0] = mmc_mk_cons(_src, _srcs);
_srcs = omc_VarTransform_amortizeUnion(threadData, tmpMeta[0]);
tmpMeta[0] = mmc_mk_box2(0, _dst, _srcs);
_outInvHt = omc_BaseHashTable_add(threadData, tmpMeta[0], _invHt);
}
else
{
tmpMeta[0] = mmc_mk_cons(_src, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[1] = mmc_mk_box2(0, _dst, tmpMeta[0]);
_outInvHt = omc_BaseHashTable_add(threadData, tmpMeta[1], _invHt);
}
_return: OMC_LABEL_UNUSED
return _outInvHt;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_addReplacementInv(threadData_t *threadData, modelica_metatype _invHt, modelica_metatype _src, modelica_metatype _dst)
{
modelica_metatype _outInvHt = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _dests = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_dests = omc_Expression_extractCrefsFromExp(threadData, _dst);
tmpMeta[0] = omc_List_fold1r(threadData, _dests, boxvar_VarTransform_addReplacementInv2, _src, _invHt);
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
_outInvHt = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outInvHt;
}
DLLExport
modelica_metatype omc_VarTransform_addReplacementNoTransitive(threadData_t *threadData, modelica_metatype _repl, modelica_metatype _src, modelica_metatype _dst)
{
modelica_metatype _outRepl = NULL;
modelica_metatype _ht = NULL;
modelica_metatype _invHt = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outRepl = _repl;
tmpMeta[0] = _outRepl;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_ht = tmpMeta[1];
_invHt = tmpMeta[2];
tmpMeta[0] = mmc_mk_box2(0, _src, _dst);
_ht = omc_BaseHashTable_add(threadData, tmpMeta[0], _ht);
_invHt = omc_VarTransform_addReplacementInv(threadData, _invHt, _src, _dst);
tmpMeta[0] = mmc_mk_box3(3, &VarTransform_VariableReplacements_REPLACEMENTS__desc, _ht, _invHt);
_outRepl = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outRepl;
}
DLLExport
modelica_metatype omc_VarTransform_addReplacement(threadData_t *threadData, modelica_metatype _repl, modelica_metatype _inSrc, modelica_metatype _inDst)
{
modelica_metatype _outRepl = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;volatile modelica_metatype tmp3_3;
tmp3_1 = _repl;
tmp3_2 = _inSrc;
tmp3_3 = _inDst;
{
modelica_metatype _src = NULL;
modelica_metatype _src_1 = NULL;
modelica_metatype _dst = NULL;
modelica_metatype _dst_1 = NULL;
modelica_metatype _ht = NULL;
modelica_metatype _ht_1 = NULL;
modelica_metatype _invHt = NULL;
modelica_metatype _invHt_1 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_src = tmp3_2;
_dst = tmp3_3;
tmpMeta[3] = omc_VarTransform_makeTransitive(threadData, _repl, _src, _dst, &tmpMeta[1], &tmpMeta[2]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
_ht = tmpMeta[4];
_invHt = tmpMeta[5];
_src_1 = tmpMeta[1];
_dst_1 = tmpMeta[2];
tmpMeta[1] = mmc_mk_box2(0, _src_1, _dst_1);
_ht_1 = omc_BaseHashTable_add(threadData, tmpMeta[1], _ht);
_invHt_1 = omc_VarTransform_addReplacementInv(threadData, _invHt, _src_1, _dst_1);
tmpMeta[1] = mmc_mk_box3(3, &VarTransform_VariableReplacements_REPLACEMENTS__desc, _ht_1, _invHt_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
fputs(MMC_STRINGDATA(_OMC_LIT3),stdout);
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
_outRepl = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outRepl;
}
DLLExport
modelica_metatype omc_VarTransform_addReplacementLst(threadData_t *threadData, modelica_metatype _inRepl, modelica_metatype _crs, modelica_metatype _dsts)
{
modelica_metatype _repl = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;modelica_metatype tmp3_3;
tmp3_1 = _inRepl;
tmp3_2 = _crs;
tmp3_3 = _dsts;
{
modelica_metatype _cr = NULL;
modelica_metatype _dst = NULL;
modelica_metatype _crrest = NULL;
modelica_metatype _dstrest = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_2)) goto tmp2_end;
if (!listEmpty(tmp3_3)) goto tmp2_end;
_repl = tmp3_1;
tmpMeta[0] = _repl;
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
if (listEmpty(tmp3_3)) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmp3_3);
tmpMeta[4] = MMC_CDR(tmp3_3);
_cr = tmpMeta[1];
_crrest = tmpMeta[2];
_dst = tmpMeta[3];
_dstrest = tmpMeta[4];
_repl = tmp3_1;
_repl = omc_VarTransform_addReplacement(threadData, _repl, _cr, _dst);
_inRepl = _repl;
_crs = _crrest;
_dsts = _dstrest;
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
_repl = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _repl;
}
DLLExport
modelica_metatype omc_VarTransform_replacementTargets(threadData_t *threadData, modelica_metatype _repl)
{
modelica_metatype _sources = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _repl;
{
modelica_metatype _targets = NULL;
modelica_metatype _ht = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_ht = tmpMeta[1];
_targets = omc_BaseHashTable_hashTableValueList(threadData, _ht);
tmpMeta[0] = omc_List_flatten(threadData, omc_List_map(threadData, _targets, boxvar_Expression_extractCrefsFromExp));
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
_sources = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _sources;
}
DLLExport
modelica_metatype omc_VarTransform_replacementSources(threadData_t *threadData, modelica_metatype _repl)
{
modelica_metatype _sources = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _repl;
{
modelica_metatype _ht = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_ht = tmpMeta[1];
tmpMeta[0] = omc_BaseHashTable_hashTableKeyList(threadData, _ht);
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
_sources = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _sources;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_VarTransform_printReplacementTupleStr(threadData_t *threadData, modelica_metatype _tpl)
{
modelica_string _str = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = stringAppend(omc_ComponentReference_printComponentRefStr(threadData, omc_Util_tuple21(threadData, _tpl)),_OMC_LIT4);
tmpMeta[1] = stringAppend(tmpMeta[0],omc_ExpressionDump_printExpStr(threadData, omc_Util_tuple22(threadData, _tpl)));
_str = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _str;
}
DLLExport
modelica_metatype omc_VarTransform_getAllReplacements(threadData_t *threadData, modelica_metatype _inVariableReplacements, modelica_metatype *out_dsts)
{
modelica_metatype _crefs = NULL;
modelica_metatype _dsts = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
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
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_ht = tmpMeta[2];
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
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
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
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_ht = tmpMeta[0];
_tplLst = omc_BaseHashTable_hashTableList(threadData, _ht);
_str = stringDelimitList(omc_List_map(threadData, _tplLst, boxvar_VarTransform_printReplacementTupleStr), _OMC_LIT5);
tmpMeta[0] = stringAppend(_OMC_LIT6,intString(listLength(_tplLst)));
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT7);
tmpMeta[2] = stringAppend(tmpMeta[1],_str);
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT5);
tmp1 = tmpMeta[3];
goto tmp3_done;
}
}
goto tmp3_end;
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
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
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
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_ht = tmpMeta[0];
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
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
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
modelica_boolean tmp6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_stmt = tmpMeta[2];
tmpMeta[2] = mmc_mk_cons(_stmt, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[3] = omc_VarTransform_replaceEquationsStmts(threadData, tmpMeta[2], _inVariableReplacements, _condExpFunc, &tmp6);
if (listEmpty(tmpMeta[3])) goto goto_2;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (!listEmpty(tmpMeta[5])) goto goto_2;
_stmt2 = tmpMeta[4];
if (1 != tmp6) goto goto_2;
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
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
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
modelica_boolean tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e = tmpMeta[2];
_st = tmpMeta[3];
_el = tmpMeta[4];
tmp4 += 1;
_el_1 = omc_VarTransform_replaceEquationsElse(threadData, _el, _repl, _condExpFunc ,&_b1);
_st_1 = omc_VarTransform_replaceEquationsStmts(threadData, _st, _repl, _condExpFunc ,&_b2);
_e_1 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc ,&_b3);
tmp6 = ((_b1 || _b2) || _b3);
if (1 != tmp6) goto goto_2;
tmpMeta[2] = mmc_mk_box4(4, &DAE_Else_ELSEIF__desc, _e_1, _st_1, _el_1);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_st = tmpMeta[2];
tmpMeta[2] = omc_VarTransform_replaceEquationsStmts(threadData, _st, _repl, _condExpFunc, &tmp7);
_st_1 = tmpMeta[2];
if (1 != tmp7) goto goto_2;
tmpMeta[2] = mmc_mk_box2(5, &DAE_Else_ELSE__desc, _st_1);
tmpMeta[0+0] = tmpMeta[2];
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
modelica_metatype tmpMeta[11] __attribute__((unused)) = {0};
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
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp4 += 12;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 0;
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
_tp = tmpMeta[4];
_e2 = tmpMeta[5];
_e = tmpMeta[6];
_source = tmpMeta[7];
_xs = tmpMeta[3];
tmp4 += 10;
_e_1 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc ,&_b1);
_e_2 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc ,&_b2);
tmp6 = (_b1 || _b2);
if (1 != tmp6) goto goto_2;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box5(3, &DAE_Statement_STMT__ASSIGN__desc, _tp, _e_2, _e_1, _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
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
_tp = tmpMeta[4];
_expl1 = tmpMeta[5];
_e = tmpMeta[6];
_source = tmpMeta[7];
_xs = tmpMeta[3];
tmp4 += 9;
_e_1 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc ,&_b1);
_expl2 = omc_VarTransform_replaceExpList(threadData, _expl1, _repl, _condExpFunc ,&_b2);
tmp7 = (_b1 || _b2);
if (1 != tmp7) goto goto_2;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box5(4, &DAE_Statement_STMT__TUPLE__ASSIGN__desc, _tp, _expl2, _e_1, _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 3: {
modelica_boolean tmp8;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,4) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
_tp = tmpMeta[4];
_e1 = tmpMeta[5];
_e2 = tmpMeta[6];
_source = tmpMeta[7];
_xs = tmpMeta[3];
tmp4 += 8;
_e_1 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc ,&_b1);
_e_2 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc ,&_b2);
tmp8 = (_b1 || _b2);
if (1 != tmp8) goto goto_2;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box5(5, &DAE_Statement_STMT__ASSIGN__ARR__desc, _tp, _e_1, _e_2, _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 4: {
modelica_boolean tmp9;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],3,4) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
_e = tmpMeta[4];
_stmts = tmpMeta[5];
_el = tmpMeta[6];
_source = tmpMeta[7];
_xs = tmpMeta[3];
tmp4 += 7;
_el_1 = omc_VarTransform_replaceEquationsElse(threadData, _el, _repl, _condExpFunc ,&_b1);
_stmts2 = omc_VarTransform_replaceEquationsStmts(threadData, _stmts, _repl, _condExpFunc ,&_b2);
_e_1 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc ,&_b3);
tmp9 = ((_b1 || _b2) || _b3);
if (1 != tmp9) goto goto_2;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box5(6, &DAE_Statement_STMT__IF__desc, _e_1, _stmts2, _el_1, _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 5: {
modelica_integer tmp10;
modelica_integer tmp11;
modelica_boolean tmp12;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],4,7) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmp10 = mmc_unbox_integer(tmpMeta[5]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
tmp11 = mmc_unbox_integer(tmpMeta[7]);
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 6));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 7));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 8));
_tp = tmpMeta[4];
_iterIsArray = tmp10;
_id1 = tmpMeta[6];
_ix = tmp11;
_e = tmpMeta[8];
_stmts = tmpMeta[9];
_source = tmpMeta[10];
_xs = tmpMeta[3];
tmp4 += 6;
_stmts2 = omc_VarTransform_replaceEquationsStmts(threadData, _stmts, _repl, _condExpFunc ,&_b1);
_e_1 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc ,&_b2);
tmp12 = (_b1 || _b2);
if (1 != tmp12) goto goto_2;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box8(7, &DAE_Statement_STMT__FOR__desc, _tp, mmc_mk_boolean(_iterIsArray), _id1, mmc_mk_integer(_ix), _e_1, _stmts2, _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 6: {
modelica_boolean tmp13;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],6,3) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
_e = tmpMeta[4];
_stmts = tmpMeta[5];
_source = tmpMeta[6];
_xs = tmpMeta[3];
tmp4 += 5;
_stmts2 = omc_VarTransform_replaceEquationsStmts(threadData, _stmts, _repl, _condExpFunc ,&_b1);
_e_1 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc ,&_b2);
tmp13 = (_b1 || _b2);
if (1 != tmp13) goto goto_2;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box4(9, &DAE_Statement_STMT__WHILE__desc, _e_1, _stmts2, _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 7: {
modelica_integer tmp14;
modelica_boolean tmp15;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],7,6) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmp14 = mmc_unbox_integer(tmpMeta[6]);
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 6));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 7));
_e = tmpMeta[4];
_conditions = tmpMeta[5];
_initialCall = tmp14;
_stmts = tmpMeta[7];
_ew = tmpMeta[8];
_source = tmpMeta[9];
_xs = tmpMeta[3];
tmp4 += 4;
_ew_1 = omc_VarTransform_replaceOptEquationsStmts(threadData, _ew, _repl, _condExpFunc ,&_b1);
_stmts2 = omc_VarTransform_replaceEquationsStmts(threadData, _stmts, _repl, _condExpFunc ,&_b2);
_e_1 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc ,&_b3);
tmp15 = ((_b1 || _b2) || _b3);
if (1 != tmp15) goto goto_2;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box7(10, &DAE_Statement_STMT__WHEN__desc, _e_1, _conditions, mmc_mk_boolean(_initialCall), _stmts2, _ew_1, _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 8: {
modelica_boolean tmp16;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],8,4) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
_e = tmpMeta[4];
_e2 = tmpMeta[5];
_e3 = tmpMeta[6];
_source = tmpMeta[7];
_xs = tmpMeta[3];
tmp4 += 3;
_e_1 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc ,&_b1);
_e_2 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc ,&_b2);
_e_3 = omc_VarTransform_replaceExp(threadData, _e3, _repl, _condExpFunc ,&_b3);
tmp16 = ((_b1 || _b2) || _b3);
if (1 != tmp16) goto goto_2;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box5(11, &DAE_Statement_STMT__ASSERT__desc, _e_1, _e_2, _e_3, _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 9: {
modelica_boolean tmp17;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],9,2) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
_e = tmpMeta[4];
_source = tmpMeta[5];
_xs = tmpMeta[3];
tmp4 += 2;
tmpMeta[2] = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc, &tmp17);
_e_1 = tmpMeta[2];
if (1 != tmp17) goto goto_2;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box3(12, &DAE_Statement_STMT__TERMINATE__desc, _e_1, _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 10: {
modelica_boolean tmp18;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],10,3) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
_e = tmpMeta[4];
_e2 = tmpMeta[5];
_source = tmpMeta[6];
_xs = tmpMeta[3];
tmp4 += 1;
_e_1 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc ,&_b1);
_e_2 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc ,&_b2);
tmp18 = (_b1 || _b2);
if (1 != tmp18) goto goto_2;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box4(13, &DAE_Statement_STMT__REINIT__desc, _e_1, _e_2, _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 11: {
modelica_boolean tmp19;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],11,2) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
_e = tmpMeta[4];
_source = tmpMeta[5];
_xs = tmpMeta[3];
tmpMeta[2] = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc, &tmp19);
_e_1 = tmpMeta[2];
if (1 != tmp19) goto goto_2;
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box3(14, &DAE_Statement_STMT__NORETCALL__desc, _e_1, _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 12: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
_x = tmpMeta[2];
_xs = tmpMeta[3];
_xs_1 = omc_VarTransform_replaceEquationsStmts(threadData, _xs, _repl, _condExpFunc ,&_b1);
tmpMeta[2] = mmc_mk_cons(_x, _xs_1);
tmpMeta[0+0] = tmpMeta[2];
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
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _ht = NULL;
modelica_metatype _invHt = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_ht = omc_HashTable2_emptyHashTableSized(threadData, _size);
_invHt = omc_HashTable3_emptyHashTableSized(threadData, _size);
tmpMeta[1] = mmc_mk_box3(3, &VarTransform_VariableReplacements_REPLACEMENTS__desc, _ht, _invHt);
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
_outVariableReplacements = tmpMeta[0];
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
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _ht = NULL;
modelica_metatype _invHt = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_ht = omc_HashTable2_emptyHashTable(threadData);
_invHt = omc_HashTable3_emptyHashTable(threadData);
tmpMeta[1] = mmc_mk_box3(3, &VarTransform_VariableReplacements_REPLACEMENTS__desc, _ht, _invHt);
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
_outVariableReplacements = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outVariableReplacements;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_VarTransform_emptyReplacementsArray2(threadData_t *threadData, modelica_integer _n)
{
modelica_metatype _replLst = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_integer tmp3_1;
tmp3_1 = _n;
{
modelica_metatype _r = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (0 != tmp3_1) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
modelica_boolean tmp5;
tmp5 = (_n < ((modelica_integer) 0));
if (1 != tmp5) goto goto_1;
fputs(MMC_STRINGDATA(_OMC_LIT10),stdout);
goto goto_1;
goto tmp2_done;
}
case 2: {
modelica_boolean tmp6;
tmp6 = (_n > ((modelica_integer) 0));
if (1 != tmp6) goto goto_1;
_r = omc_VarTransform_emptyReplacements(threadData);
_replLst = omc_VarTransform_emptyReplacementsArray2(threadData, ((modelica_integer) -1) + _n);
tmpMeta[1] = mmc_mk_cons(_r, _replLst);
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
_replLst = tmpMeta[0];
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _increfs;
{
modelica_metatype _cr1_1 = NULL;
modelica_metatype _cr1 = NULL;
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
_cr1 = tmpMeta[1];
_ocrefs = tmpMeta[2];
tmpMeta[1] = omc_VarTransform_replaceExp(threadData, omc_Expression_crefExp(threadData, _cr1), _repl, mmc_mk_none(), NULL);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,2) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_cr1_1 = tmpMeta[2];
_ocrefs = omc_VarTransform_applyReplacementList(threadData, _repl, _ocrefs);
tmpMeta[1] = mmc_mk_cons(_cr1_1, _ocrefs);
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
_ocrefs = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _ocrefs;
}
DLLExport
modelica_metatype omc_VarTransform_applyReplacements(threadData_t *threadData, modelica_metatype _inVariableReplacements1, modelica_metatype _inComponentRef2, modelica_metatype _inComponentRef3, modelica_metatype *out_outComponentRef2)
{
modelica_metatype _outComponentRef1 = NULL;
modelica_metatype _outComponentRef2 = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
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
_repl = tmp4_1;
_cr1 = tmp4_2;
_cr2 = tmp4_3;
tmpMeta[2] = omc_VarTransform_replaceExp(threadData, omc_Expression_crefExp(threadData, _cr1), _repl, mmc_mk_none(), NULL);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],6,2) == 0) goto goto_2;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_cr1_1 = tmpMeta[3];
tmpMeta[2] = omc_VarTransform_replaceExp(threadData, omc_Expression_crefExp(threadData, _cr2), _repl, mmc_mk_none(), NULL);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],6,2) == 0) goto goto_2;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_cr2_1 = tmpMeta[3];
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
modelica_metatype tmpMeta[17] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _attr;
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
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 9));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 10));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 11));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 12));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 13));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 14));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 15));
tmpMeta[16] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 16));
_quantity = tmpMeta[2];
_unit = tmpMeta[3];
_displayUnit = tmpMeta[4];
_min = tmpMeta[5];
_max = tmpMeta[6];
_initial_ = tmpMeta[7];
_fixed = tmpMeta[8];
_nominal = tmpMeta[9];
_stateSelect = tmpMeta[10];
_unc = tmpMeta[11];
_dist = tmpMeta[12];
_eb = tmpMeta[13];
_ip = tmpMeta[14];
_fn = tmpMeta[15];
_startOrigin = tmpMeta[16];
_quantity = omc_VarTransform_replaceExpOpt(threadData, _quantity, _repl, _condExpFunc);
_unit = omc_VarTransform_replaceExpOpt(threadData, _unit, _repl, _condExpFunc);
_displayUnit = omc_VarTransform_replaceExpOpt(threadData, _displayUnit, _repl, _condExpFunc);
_min = omc_VarTransform_replaceExpOpt(threadData, _min, _repl, _condExpFunc);
_max = omc_VarTransform_replaceExpOpt(threadData, _max, _repl, _condExpFunc);
_initial_ = omc_VarTransform_replaceExpOpt(threadData, _initial_, _repl, _condExpFunc);
_fixed = omc_VarTransform_replaceExpOpt(threadData, _fixed, _repl, _condExpFunc);
_nominal = omc_VarTransform_replaceExpOpt(threadData, _nominal, _repl, _condExpFunc);
tmpMeta[1] = mmc_mk_box16(3, &DAE_VariableAttributes_VAR__ATTR__REAL__desc, _quantity, _unit, _displayUnit, _min, _max, _initial_, _fixed, _nominal, _stateSelect, _unc, _dist, _eb, _ip, _fn, _startOrigin);
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
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 11));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 12));
_quantity = tmpMeta[2];
_min = tmpMeta[3];
_max = tmpMeta[4];
_initial_ = tmpMeta[5];
_fixed = tmpMeta[6];
_unc = tmpMeta[7];
_dist = tmpMeta[8];
_eb = tmpMeta[9];
_ip = tmpMeta[10];
_fn = tmpMeta[11];
_startOrigin = tmpMeta[12];
_quantity = omc_VarTransform_replaceExpOpt(threadData, _quantity, _repl, _condExpFunc);
_min = omc_VarTransform_replaceExpOpt(threadData, _min, _repl, _condExpFunc);
_max = omc_VarTransform_replaceExpOpt(threadData, _max, _repl, _condExpFunc);
_initial_ = omc_VarTransform_replaceExpOpt(threadData, _initial_, _repl, _condExpFunc);
_fixed = omc_VarTransform_replaceExpOpt(threadData, _fixed, _repl, _condExpFunc);
tmpMeta[1] = mmc_mk_box12(4, &DAE_VariableAttributes_VAR__ATTR__INT__desc, _quantity, _min, _max, _initial_, _fixed, _unc, _dist, _eb, _ip, _fn, _startOrigin);
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
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
_quantity = tmpMeta[2];
_initial_ = tmpMeta[3];
_fixed = tmpMeta[4];
_eb = tmpMeta[5];
_ip = tmpMeta[6];
_fn = tmpMeta[7];
_startOrigin = tmpMeta[8];
_quantity = omc_VarTransform_replaceExpOpt(threadData, _quantity, _repl, _condExpFunc);
_initial_ = omc_VarTransform_replaceExpOpt(threadData, _initial_, _repl, _condExpFunc);
_fixed = omc_VarTransform_replaceExpOpt(threadData, _fixed, _repl, _condExpFunc);
tmpMeta[1] = mmc_mk_box8(5, &DAE_VariableAttributes_VAR__ATTR__BOOL__desc, _quantity, _initial_, _fixed, _eb, _ip, _fn, _startOrigin);
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
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
_quantity = tmpMeta[2];
_initial_ = tmpMeta[3];
_fixed = tmpMeta[4];
_eb = tmpMeta[5];
_ip = tmpMeta[6];
_fn = tmpMeta[7];
_startOrigin = tmpMeta[8];
_quantity = omc_VarTransform_replaceExpOpt(threadData, _quantity, _repl, _condExpFunc);
_initial_ = omc_VarTransform_replaceExpOpt(threadData, _initial_, _repl, _condExpFunc);
_fixed = omc_VarTransform_replaceExpOpt(threadData, _fixed, _repl, _condExpFunc);
tmpMeta[1] = mmc_mk_box8(7, &DAE_VariableAttributes_VAR__ATTR__STRING__desc, _quantity, _initial_, _fixed, _eb, _ip, _fn, _startOrigin);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 4: {
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
_outAttr = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAttr;
}
DLLExport
modelica_metatype omc_VarTransform_applyReplacementsDAEElts(threadData_t *threadData, modelica_metatype _inDae, modelica_metatype _repl, modelica_metatype _condExpFunc)
{
modelica_metatype _outDae = NULL;
modelica_metatype tmpMeta[17] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if((omc_BaseHashTable_hashTableCurrentSize(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_repl), 2)))) == ((modelica_integer) 0)))
{
_outDae = _inDae;
goto _return;
}
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp1;
modelica_metatype __omcQ_24tmpVar0;
int tmp6;
modelica_metatype _elt_loopVar = 0;
modelica_metatype _elt;
_elt_loopVar = _inDae;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta[1];
tmp1 = &__omcQ_24tmpVar1;
while(1) {
tmp6 = 1;
if (!listEmpty(_elt_loopVar)) {
_elt = MMC_CAR(_elt_loopVar);
_elt_loopVar = MMC_CDR(_elt_loopVar);
tmp6--;
}
if (tmp6 == 0) {
{
modelica_metatype tmp4_1;
tmp4_1 = _elt;
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
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 25; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
if (optionNone(tmpMeta[9])) goto tmp3_end;
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[9]), 1));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 9));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 10));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 11));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 12));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 13));
tmpMeta[16] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 14));
_cr = tmpMeta[3];
_kind = tmpMeta[4];
_dir = tmpMeta[5];
_prl = tmpMeta[6];
_prot = tmpMeta[7];
_tp = tmpMeta[8];
_bindExp = tmpMeta[10];
_dims = tmpMeta[11];
_ct = tmpMeta[12];
_source = tmpMeta[13];
_attr = tmpMeta[14];
_cmt = tmpMeta[15];
_io = tmpMeta[16];
_bindExp2 = omc_VarTransform_replaceExp(threadData, _bindExp, _repl, _condExpFunc, NULL);
_attr = omc_VarTransform_applyReplacementsVarAttr(threadData, _attr, _repl, _condExpFunc);
tmpMeta[3] = mmc_mk_box14(3, &DAE_Element_VAR__desc, _cr, _kind, _dir, _prl, _prot, _tp, mmc_mk_some(_bindExp2), _dims, _ct, _source, _attr, _cmt, _io);
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
if (!optionNone(tmpMeta[9])) goto tmp3_end;
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 9));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 10));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 11));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 12));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 13));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 14));
_cr = tmpMeta[3];
_kind = tmpMeta[4];
_dir = tmpMeta[5];
_prl = tmpMeta[6];
_prot = tmpMeta[7];
_tp = tmpMeta[8];
_dims = tmpMeta[10];
_ct = tmpMeta[11];
_source = tmpMeta[12];
_attr = tmpMeta[13];
_cmt = tmpMeta[14];
_io = tmpMeta[15];
_attr = omc_VarTransform_applyReplacementsVarAttr(threadData, _attr, _repl, _condExpFunc);
tmpMeta[3] = mmc_mk_box14(3, &DAE_Element_VAR__desc, _cr, _kind, _dir, _prl, _prot, _tp, mmc_mk_none(), _dims, _ct, _source, _attr, _cmt, _io);
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_cr = tmpMeta[3];
_e = tmpMeta[4];
_source = tmpMeta[5];
_e2 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc, NULL);
tmpMeta[3] = omc_VarTransform_replaceExp(threadData, omc_Expression_crefExp(threadData, _cr), _repl, _condExpFunc, NULL);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],6,2) == 0) goto goto_2;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
_cr2 = tmpMeta[4];
tmpMeta[3] = mmc_mk_box4(4, &DAE_Element_DEFINE__desc, _cr2, _e2, _source);
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,3) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_cr = tmpMeta[3];
_e = tmpMeta[4];
_source = tmpMeta[5];
_e2 = omc_VarTransform_replaceExp(threadData, _e, _repl, _condExpFunc, NULL);
tmpMeta[3] = omc_VarTransform_replaceExp(threadData, omc_Expression_crefExp(threadData, _cr), _repl, _condExpFunc, NULL);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],6,2) == 0) goto goto_2;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
_cr2 = tmpMeta[4];
tmpMeta[3] = mmc_mk_box4(5, &DAE_Element_INITIALDEFINE__desc, _cr2, _e2, _source);
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,3) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_cr = tmpMeta[3];
_cr1 = tmpMeta[4];
_source = tmpMeta[5];
tmpMeta[3] = omc_VarTransform_replaceExp(threadData, omc_Expression_crefExp(threadData, _cr), _repl, _condExpFunc, NULL);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],6,2) == 0) goto goto_2;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
_cr2 = tmpMeta[4];
tmpMeta[3] = omc_VarTransform_replaceExp(threadData, omc_Expression_crefExp(threadData, _cr1), _repl, _condExpFunc, NULL);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],6,2) == 0) goto goto_2;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
_cr1_2 = tmpMeta[4];
tmpMeta[3] = mmc_mk_box4(7, &DAE_Element_EQUEQUATION__desc, _cr2, _cr1_2, _source);
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,3) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta[3];
_e2 = tmpMeta[4];
_source = tmpMeta[5];
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
_e22 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _e11, _e22, _source);
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,4) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_idims = tmpMeta[3];
_e1 = tmpMeta[4];
_e2 = tmpMeta[5];
_source = tmpMeta[6];
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
_e22 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box5(8, &DAE_Element_ARRAY__EQUATION__desc, _idims, _e11, _e22, _source);
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,4) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_idims = tmpMeta[3];
_e1 = tmpMeta[4];
_e2 = tmpMeta[5];
_source = tmpMeta[6];
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
_e22 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box5(9, &DAE_Element_INITIAL__ARRAY__EQUATION__desc, _idims, _e11, _e22, _source);
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (optionNone(tmpMeta[5])) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 1));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e1 = tmpMeta[3];
_elist = tmpMeta[4];
_elt2 = tmpMeta[6];
_source = tmpMeta[7];
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_cons(_elt2, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[4] = omc_VarTransform_applyReplacementsDAEElts(threadData, tmpMeta[3], _repl, _condExpFunc);
if (listEmpty(tmpMeta[4])) goto goto_2;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto goto_2;
_elt2 = tmpMeta[5];
_elist2 = omc_VarTransform_applyReplacementsDAEElts(threadData, _elist, _repl, _condExpFunc);
tmpMeta[3] = mmc_mk_box5(13, &DAE_Element_WHEN__EQUATION__desc, _e11, _elist2, mmc_mk_some(_elt2), _source);
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!optionNone(tmpMeta[5])) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e1 = tmpMeta[3];
_elist = tmpMeta[4];
_source = tmpMeta[6];
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
_elist2 = omc_VarTransform_applyReplacementsDAEElts(threadData, _elist, _repl, _condExpFunc);
tmpMeta[3] = mmc_mk_box5(13, &DAE_Element_WHEN__EQUATION__desc, _e11, _elist2, mmc_mk_none(), _source);
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,4) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_conds = tmpMeta[3];
_tbs = tmpMeta[4];
_elist2 = tmpMeta[5];
_source = tmpMeta[6];
_conds_1 = omc_VarTransform_replaceExpList(threadData, _conds, _repl, _condExpFunc, NULL);
_tbs_1 = omc_List_map2(threadData, _tbs, boxvar_VarTransform_applyReplacementsDAEElts, _repl, _condExpFunc);
_elist22 = omc_VarTransform_applyReplacementsDAEElts(threadData, _elist2, _repl, _condExpFunc);
tmpMeta[3] = mmc_mk_box5(15, &DAE_Element_IF__EQUATION__desc, _conds_1, _tbs_1, _elist22, _source);
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,4) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_conds = tmpMeta[3];
_tbs = tmpMeta[4];
_elist2 = tmpMeta[5];
_source = tmpMeta[6];
_conds_1 = omc_VarTransform_replaceExpList(threadData, _conds, _repl, _condExpFunc, NULL);
_tbs_1 = omc_List_map2(threadData, _tbs, boxvar_VarTransform_applyReplacementsDAEElts, _repl, _condExpFunc);
_elist22 = omc_VarTransform_applyReplacementsDAEElts(threadData, _elist2, _repl, _condExpFunc);
tmpMeta[3] = mmc_mk_box5(16, &DAE_Element_INITIAL__IF__EQUATION__desc, _conds_1, _tbs_1, _elist22, _source);
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,14,3) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta[3];
_e2 = tmpMeta[4];
_source = tmpMeta[5];
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
_e22 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box4(17, &DAE_Element_INITIALEQUATION__desc, _e11, _e22, _source);
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,2) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_stmts = tmpMeta[4];
_source = tmpMeta[5];
_stmts2 = omc_VarTransform_replaceEquationsStmts(threadData, _stmts, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box2(3, &DAE_Algorithm_ALGORITHM__STMTS__desc, _stmts2);
tmpMeta[4] = mmc_mk_box3(18, &DAE_Element_ALGORITHM__desc, tmpMeta[3], _source);
tmpMeta[2] = tmpMeta[4];
goto tmp3_done;
}
case 14: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,2) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_stmts = tmpMeta[4];
_source = tmpMeta[5];
_stmts2 = omc_VarTransform_replaceEquationsStmts(threadData, _stmts, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box2(3, &DAE_Algorithm_ALGORITHM__STMTS__desc, _stmts2);
tmpMeta[4] = mmc_mk_box3(19, &DAE_Element_INITIALALGORITHM__desc, tmpMeta[3], _source);
tmpMeta[2] = tmpMeta[4];
goto tmp3_done;
}
case 15: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,4) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta[3];
_elist = tmpMeta[4];
_source = tmpMeta[5];
_cmt = tmpMeta[6];
_elist = omc_VarTransform_applyReplacementsDAEElts(threadData, _elist, _repl, _condExpFunc);
tmpMeta[3] = mmc_mk_box5(20, &DAE_Element_COMP__desc, _id, _elist, _source, _cmt);
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
case 16: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,2) == 0) goto tmp3_end;
tmpMeta[2] = _elt;
goto tmp3_done;
}
case 17: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,19,4) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e1 = tmpMeta[3];
_e2 = tmpMeta[4];
_e3 = tmpMeta[5];
_source = tmpMeta[6];
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
_e22 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc, NULL);
_e32 = omc_VarTransform_replaceExp(threadData, _e3, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box5(22, &DAE_Element_ASSERT__desc, _e11, _e22, _e32, _source);
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
case 18: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,20,4) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e1 = tmpMeta[3];
_e2 = tmpMeta[4];
_e3 = tmpMeta[5];
_source = tmpMeta[6];
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
_e22 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc, NULL);
_e32 = omc_VarTransform_replaceExp(threadData, _e3, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box5(23, &DAE_Element_INITIAL__ASSERT__desc, _e11, _e22, _e32, _source);
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
case 19: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,2) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e1 = tmpMeta[3];
_source = tmpMeta[4];
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box3(24, &DAE_Element_TERMINATE__desc, _e11, _source);
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
case 20: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,2) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e1 = tmpMeta[3];
_source = tmpMeta[4];
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box3(25, &DAE_Element_INITIAL__TERMINATE__desc, _e11, _source);
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
case 21: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,23,3) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_cr = tmpMeta[3];
_e1 = tmpMeta[4];
_source = tmpMeta[5];
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
tmpMeta[3] = omc_VarTransform_replaceExp(threadData, omc_Expression_crefExp(threadData, _cr), _repl, _condExpFunc, NULL);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],6,2) == 0) goto goto_2;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
_cr2 = tmpMeta[4];
tmpMeta[3] = mmc_mk_box4(26, &DAE_Element_REINIT__desc, _cr2, _e11, _source);
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
case 22: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,3) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta[3];
_e2 = tmpMeta[4];
_source = tmpMeta[5];
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
_e22 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box4(11, &DAE_Element_COMPLEX__EQUATION__desc, _e11, _e22, _source);
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
case 23: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta[3];
_e2 = tmpMeta[4];
_source = tmpMeta[5];
_e11 = omc_VarTransform_replaceExp(threadData, _e1, _repl, _condExpFunc, NULL);
_e22 = omc_VarTransform_replaceExp(threadData, _e2, _repl, _condExpFunc, NULL);
tmpMeta[3] = mmc_mk_box4(12, &DAE_Element_INITIAL__COMPLEX__EQUATION__desc, _e11, _e22, _source);
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
case 24: {
omc_Error_addInternalError(threadData, _OMC_LIT11, _OMC_LIT12);
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
}__omcQ_24tmpVar0 = tmpMeta[2];
*tmp1 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp1 = &MMC_CDR(*tmp1);
} else if (tmp6 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp1 = mmc_mk_nil();
tmpMeta[0] = __omcQ_24tmpVar1;
}
_outDae = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outDae;
}
DLLExport
modelica_metatype omc_VarTransform_applyReplacementsDAE(threadData_t *threadData, modelica_metatype _dae, modelica_metatype _repl, modelica_metatype _condExpFunc)
{
modelica_metatype _outDae = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
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
_elts = omc_VarTransform_applyReplacementsDAEElts(threadData, _elts, _repl, _condExpFunc);
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
