#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "PrefixUtil.c"
#endif
#include "omc_simulation_settings.h"
#include "PrefixUtil.h"
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT0,1,4) {&DAE_ComponentPrefix_NOCOMPPRE__desc,}};
#define _OMC_LIT0 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "PrefixUtil.removePrefixFromCref :Cref is not qualified but we have prefix to remove: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,85,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "PrefixUtil.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,13,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT3_6,0.0);
#define _OMC_LIT3_6 MMC_REFREALLIT(_OMC_LIT_STRUCT3_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT2,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1544)),MMC_IMMEDIATE(MMC_TAGFIXNUM(7)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1544)),MMC_IMMEDIATE(MMC_TAGFIXNUM(158)),_OMC_LIT3_6}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "PrefixUtil.removePrefixFromCref :failed on cref: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,49,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT5_6,0.0);
#define _OMC_LIT5_6 MMC_REFREALLIT(_OMC_LIT_STRUCT5_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT2,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1549)),MMC_IMMEDIATE(MMC_TAGFIXNUM(7)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1549)),MMC_IMMEDIATE(MMC_TAGFIXNUM(122)),_OMC_LIT5_6}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,0,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT7,0.0);
#define _OMC_LIT7 MMC_REFREALLIT(_OMC_LIT_STRUCT7)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT8,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT6,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT7}};
#define _OMC_LIT8 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "from top scope"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,14,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "from calling scope: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,20,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,1,3) {&DAE_Else_NOELSE__desc,}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT12,1,3) {&DAE_Prefix_NOPRE__desc,}};
#define _OMC_LIT12 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT12)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT13,2,34) {&DAE_Exp_META__OPTION__desc,MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT13 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data "PrefixUtil.prefixExpWork failed on exp: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,40,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data " "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,1,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT16_6,0.0);
#define _OMC_LIT16_6 MMC_REFREALLIT(_OMC_LIT_STRUCT16_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT16,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT2,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(962)),MMC_IMMEDIATE(MMC_TAGFIXNUM(9)),MMC_IMMEDIATE(MMC_TAGFIXNUM(962)),MMC_IMMEDIATE(MMC_TAGFIXNUM(151)),_OMC_LIT16_6}};
#define _OMC_LIT16 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data "PrefixUtil.prefixExp failed on exp: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,36,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT18_6,0.0);
#define _OMC_LIT18_6 MMC_REFREALLIT(_OMC_LIT_STRUCT18_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT18,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT2,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(696)),MMC_IMMEDIATE(MMC_TAGFIXNUM(5)),MMC_IMMEDIATE(MMC_TAGFIXNUM(696)),MMC_IMMEDIATE(MMC_TAGFIXNUM(145)),_OMC_LIT18_6}};
#define _OMC_LIT18 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,1,3) {&DAE_Subscript_WHOLEDIM__desc,}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT20,1,7) {&DAE_ComponentRef_WILD__desc,}};
#define _OMC_LIT20 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT20)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT21,1,11) {&DAE_Type_T__UNKNOWN__desc,}};
#define _OMC_LIT21 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT21)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT22,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT6}};
#define _OMC_LIT22 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT22)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT23,2,3) {&ClassInf_State_UNKNOWN__desc,_OMC_LIT22}};
#define _OMC_LIT23 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT23)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT24,4,12) {&DAE_Type_T__COMPLEX__desc,_OMC_LIT23,MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT24 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT24)
#define _OMC_LIT25_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT25,1,_OMC_LIT25_data);
#define _OMC_LIT25 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "<NO COMPONENT>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,14,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data "<Prefix.NOPRE()>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,16,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data "<Prefix.PREFIX(DAE.NOCOMPPRE())>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,32,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data "["
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,1,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
#define _OMC_LIT30_data ", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT30,2,_OMC_LIT30_data);
#define _OMC_LIT30 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data "]"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,1,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
#define _OMC_LIT32_data "<Prefix.NOCOMPPRE()>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT32,20,_OMC_LIT32_data);
#define _OMC_LIT32 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT32)
#include "util/modelica.h"
#include "PrefixUtil_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_removePrefixFromCref(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inCompPref);
static const MMC_DEFSTRUCTLIT(boxvar_lit_PrefixUtil_removePrefixFromCref,2,0) {(void*) boxptr_PrefixUtil_removePrefixFromCref,0}};
#define boxvar_PrefixUtil_removePrefixFromCref MMC_REFSTRUCTLIT(boxvar_lit_PrefixUtil_removePrefixFromCref)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_removeCompPrefixFromCrefExp(threadData_t *threadData, modelica_metatype _inExp, modelica_boolean _inB, modelica_metatype _inCompPref, modelica_boolean *out_b);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_PrefixUtil_removeCompPrefixFromCrefExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inB, modelica_metatype _inCompPref, modelica_metatype *out_b);
static const MMC_DEFSTRUCTLIT(boxvar_lit_PrefixUtil_removeCompPrefixFromCrefExp,2,0) {(void*) boxptr_PrefixUtil_removeCompPrefixFromCrefExp,0}};
#define boxvar_PrefixUtil_removeCompPrefixFromCrefExp MMC_REFSTRUCTLIT(boxvar_lit_PrefixUtil_removeCompPrefixFromCrefExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixArrayDimensions(threadData_t *threadData, modelica_metatype _ty, modelica_metatype _tpl, modelica_metatype *out_otpl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixArrayDimensions,2,0) {(void*) boxptr_PrefixUtil_prefixArrayDimensions,0}};
#define boxvar_PrefixUtil_prefixArrayDimensions MMC_REFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixArrayDimensions)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixElse(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _inIH, modelica_metatype _elseBranch, modelica_metatype _p, modelica_metatype *out_outElse);
static const MMC_DEFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixElse,2,0) {(void*) boxptr_PrefixUtil_prefixElse,0}};
#define boxvar_PrefixUtil_prefixElse MMC_REFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixElse)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixStatements(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _inIH, modelica_metatype _stmts, modelica_metatype _p, modelica_metatype *out_outStmts);
static const MMC_DEFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixStatements,2,0) {(void*) boxptr_PrefixUtil_prefixStatements,0}};
#define boxvar_PrefixUtil_prefixStatements MMC_REFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixStatements)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixIterators(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _ih, modelica_metatype _inIters, modelica_metatype _pre, modelica_metatype *out_outIters);
static const MMC_DEFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixIterators,2,0) {(void*) boxptr_PrefixUtil_prefixIterators,0}};
#define boxvar_PrefixUtil_prefixIterators MMC_REFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixIterators)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixExpCref2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inIsIter, modelica_metatype _inCref, modelica_metatype _inPrefix, modelica_metatype *out_outCref);
static const MMC_DEFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixExpCref2,2,0) {(void*) boxptr_PrefixUtil_prefixExpCref2,0}};
#define boxvar_PrefixUtil_prefixExpCref2 MMC_REFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixExpCref2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixExpCref(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inCref, modelica_metatype _inPrefix, modelica_metatype *out_outCref);
static const MMC_DEFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixExpCref,2,0) {(void*) boxptr_PrefixUtil_prefixExpCref,0}};
#define boxvar_PrefixUtil_prefixExpCref MMC_REFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixExpCref)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixExpWork(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcache, modelica_metatype _env, modelica_metatype _ih, modelica_metatype _inExp, modelica_metatype _pre, modelica_metatype *out_outExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixExpWork,2,0) {(void*) boxptr_PrefixUtil_prefixExpWork,0}};
#define boxvar_PrefixUtil_prefixExpWork MMC_REFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixExpWork)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixSubscript(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _pre, modelica_metatype _sub, modelica_metatype *out_outSub);
static const MMC_DEFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixSubscript,2,0) {(void*) boxptr_PrefixUtil_prefixSubscript,0}};
#define boxvar_PrefixUtil_prefixSubscript MMC_REFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixSubscript)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixSubscripts(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _pre, modelica_metatype _inSubs, modelica_metatype *out_outSubs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixSubscripts,2,0) {(void*) boxptr_PrefixUtil_prefixSubscripts,0}};
#define boxvar_PrefixUtil_prefixSubscripts MMC_REFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixSubscripts)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixSubscriptsInCrefWork(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _pre, modelica_metatype _inCr, modelica_metatype _acc, modelica_metatype *out_outCr);
static const MMC_DEFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixSubscriptsInCrefWork,2,0) {(void*) boxptr_PrefixUtil_prefixSubscriptsInCrefWork,0}};
#define boxvar_PrefixUtil_prefixSubscriptsInCrefWork MMC_REFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixSubscriptsInCrefWork)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixSubscriptsInCref(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _pre, modelica_metatype _inCr, modelica_metatype *out_outCr);
static const MMC_DEFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixSubscriptsInCref,2,0) {(void*) boxptr_PrefixUtil_prefixSubscriptsInCref,0}};
#define boxvar_PrefixUtil_prefixSubscriptsInCref MMC_REFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixSubscriptsInCref)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixToCref2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPrefix, modelica_metatype _inExpComponentRefOption, modelica_metatype *out_outComponentRef);
static const MMC_DEFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixToCref2,2,0) {(void*) boxptr_PrefixUtil_prefixToCref2,0}};
#define boxvar_PrefixUtil_prefixToCref2 MMC_REFSTRUCTLIT(boxvar_lit_PrefixUtil_prefixToCref2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_compPreStripLast(threadData_t *threadData, modelica_metatype _inCompPrefix);
static const MMC_DEFSTRUCTLIT(boxvar_lit_PrefixUtil_compPreStripLast,2,0) {(void*) boxptr_PrefixUtil_compPreStripLast,0}};
#define boxvar_PrefixUtil_compPreStripLast MMC_REFSTRUCTLIT(boxvar_lit_PrefixUtil_compPreStripLast)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_removePrefixFromCref(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inCompPref)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inCref;
tmp4_2 = _inCompPref;
{
modelica_metatype _cref = NULL;
modelica_metatype _pref = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
tmpMeta1 = _inCref;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta1 = _inCref;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,6) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,0) == 0) goto tmp3_end;
_cref = tmp4_1;
_pref = tmp4_2;
if((stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pref), 2))))))
{
}
else
{
}
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 5)));
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,6) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,6) == 0) goto tmp3_end;
_pref = tmp4_2;
_cref = omc_PrefixUtil_removePrefixFromCref(threadData, _inCref, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pref), 5))));
tmpMeta8 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta8), MMC_UNTAGPTR(_pref), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta8))[5] = _OMC_LIT0;
_pref = tmpMeta8;
_inCref = _cref;
_inCompPref = _pref;
goto _tailrecursive;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,6) == 0) goto tmp3_end;
tmpMeta9 = stringAppend(_OMC_LIT1,omc_ComponentReference_crefStr(threadData, _inCref));
omc_Error_addInternalError(threadData, tmpMeta9, _OMC_LIT3);
goto goto_2;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta10;
tmpMeta10 = stringAppend(_OMC_LIT4,omc_ComponentReference_crefStr(threadData, _inCref));
omc_Error_addInternalError(threadData, tmpMeta10, _OMC_LIT5);
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
_outCref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCref;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_removeCompPrefixFromCrefExp(threadData_t *threadData, modelica_metatype _inExp, modelica_boolean _inB, modelica_metatype _inCompPref, modelica_boolean *out_b)
{
modelica_metatype _outExp = NULL;
modelica_boolean _b;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _exp = NULL;
modelica_metatype _cref = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,4) == 0) goto tmp3_end;
_exp = tmp4_1;
_cref = omc_PrefixUtil_removePrefixFromCref(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 2))), _inCompPref);
tmpMeta7 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta7), MMC_UNTAGPTR(_exp), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta7))[2] = _cref;
_exp = tmpMeta7;
tmpMeta[0+0] = _exp;
tmp1_c1 = 1;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _inExp;
tmp1_c1 = _inB;
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
_b = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_b) { *out_b = _b; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_PrefixUtil_removeCompPrefixFromCrefExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inB, modelica_metatype _inCompPref, modelica_metatype *out_b)
{
modelica_integer tmp1;
modelica_boolean _b;
modelica_metatype _outExp = NULL;
tmp1 = mmc_unbox_integer(_inB);
_outExp = omc_PrefixUtil_removeCompPrefixFromCrefExp(threadData, _inExp, tmp1, _inCompPref, &_b);
if (out_b) { *out_b = mmc_mk_icon(_b); }
return _outExp;
}
static modelica_metatype closure0_PrefixUtil_removeCompPrefixFromCrefExp(threadData_t *thData, modelica_metatype closure, modelica_metatype inExp, modelica_metatype inB, modelica_metatype tmp1)
{
modelica_metatype inCompPref = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_PrefixUtil_removeCompPrefixFromCrefExp(thData, inExp, inB, inCompPref, tmp1);
}
DLLExport
modelica_metatype omc_PrefixUtil_removeCompPrefixFromExps(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inCompPref)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta2 = mmc_mk_box1(0, _inCompPref);
_outExp = omc_Expression_traverseExpBottomUp(threadData, _inExp, (modelica_fnptr) mmc_mk_box2(0,closure0_PrefixUtil_removeCompPrefixFromCrefExp,tmpMeta2), mmc_mk_boolean(0), NULL);
_return: OMC_LABEL_UNUSED
return _outExp;
}
DLLExport
modelica_boolean omc_PrefixUtil_haveSubs(threadData_t *threadData, modelica_metatype _pre)
{
modelica_boolean _ob;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _pre;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
_pre = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pre), 5)));
goto _tailrecursive;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
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
_ob = tmp1;
_return: OMC_LABEL_UNUSED
return _ob;
}
modelica_metatype boxptr_PrefixUtil_haveSubs(threadData_t *threadData, modelica_metatype _pre)
{
modelica_boolean _ob;
modelica_metatype out_ob;
_ob = omc_PrefixUtil_haveSubs(threadData, _pre);
out_ob = mmc_mk_icon(_ob);
return out_ob;
}
DLLExport
void omc_PrefixUtil_writeComponentPrefix(threadData_t *threadData, modelica_complex _file, modelica_metatype _pre, modelica_integer _escape)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _pre;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,6) == 0) goto tmp2_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta5,1,0) == 0) goto tmp2_end;
omc_File_writeEscape(threadData, _file, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pre), 2))), (modelica_integer)_escape);
omc_ComponentReference_writeSubscripts(threadData, _file, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pre), 4))), (modelica_integer)_escape);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,6) == 0) goto tmp2_end;
omc_PrefixUtil_writeComponentPrefix(threadData, _file, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pre), 5))), 1);
omc_File_writeEscape(threadData, _file, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pre), 2))), (modelica_integer)_escape);
omc_ComponentReference_writeSubscripts(threadData, _file, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pre), 4))), (modelica_integer)_escape);
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
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_PrefixUtil_writeComponentPrefix(threadData_t *threadData, modelica_metatype _file, modelica_metatype _pre, modelica_metatype _escape)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_escape);
omc_PrefixUtil_writeComponentPrefix(threadData, _file, _pre, tmp1);
return;
}
DLLExport
modelica_metatype omc_PrefixUtil_componentPrefix(threadData_t *threadData, modelica_metatype _inPrefix)
{
modelica_metatype _outPrefix = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPrefix;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inPrefix), 2)));
goto tmp3_done;
}
case 1: {
tmpMeta1 = _OMC_LIT0;
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
_outPrefix = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outPrefix;
}
DLLExport
modelica_boolean omc_PrefixUtil_componentPrefixPathEqual(threadData_t *threadData, modelica_metatype _pre1, modelica_metatype _pre2)
{
modelica_boolean _eq;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _pre1;
tmp4_2 = _pre2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
modelica_boolean tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,6) == 0) goto tmp3_end;
tmp6 = (modelica_boolean)(stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pre1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pre2), 2)))));
if(tmp6)
{
_pre1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pre1), 5)));
_pre2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pre2), 5)));
goto _tailrecursive;
}
else
{
tmp7 = 0;
}
tmp1 = tmp7;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
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
_eq = tmp1;
_return: OMC_LABEL_UNUSED
return _eq;
}
modelica_metatype boxptr_PrefixUtil_componentPrefixPathEqual(threadData_t *threadData, modelica_metatype _pre1, modelica_metatype _pre2)
{
modelica_boolean _eq;
modelica_metatype out_eq;
_eq = omc_PrefixUtil_componentPrefixPathEqual(threadData, _pre1, _pre2);
out_eq = mmc_mk_icon(_eq);
return out_eq;
}
DLLExport
modelica_integer omc_PrefixUtil_prefixHashWork(threadData_t *threadData, modelica_metatype _inPrefix, modelica_integer __omcQ_24in_5Fhash)
{
modelica_integer _hash;
modelica_integer tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_hash = __omcQ_24in_5Fhash;
{
modelica_metatype tmp4_1;
tmp4_1 = _inPrefix;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta6 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inPrefix), 5)));
__omcQ_24in_5Fhash = (((modelica_integer) 31)) * (_hash) + stringHashDjb2((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inPrefix), 2))));
_inPrefix = tmpMeta6;
goto _tailrecursive;
goto tmp3_done;
}
case 1: {
tmp1 = _hash;
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
_hash = tmp1;
_return: OMC_LABEL_UNUSED
return _hash;
}
modelica_metatype boxptr_PrefixUtil_prefixHashWork(threadData_t *threadData, modelica_metatype _inPrefix, modelica_metatype __omcQ_24in_5Fhash)
{
modelica_integer tmp1;
modelica_integer _hash;
modelica_metatype out_hash;
tmp1 = mmc_unbox_integer(__omcQ_24in_5Fhash);
_hash = omc_PrefixUtil_prefixHashWork(threadData, _inPrefix, tmp1);
out_hash = mmc_mk_icon(_hash);
return out_hash;
}
DLLExport
modelica_metatype omc_PrefixUtil_getPrefixInfo(threadData_t *threadData, modelica_metatype _inPrefix)
{
modelica_metatype _outInfo = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPrefix;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,6) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 7));
_outInfo = tmpMeta7;
tmpMeta1 = _outInfo;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _OMC_LIT8;
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
_outInfo = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outInfo;
}
DLLExport
modelica_metatype omc_PrefixUtil_prefixClockKind(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inClkKind, modelica_metatype _inPrefix, modelica_metatype *out_outClkKind)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outClkKind = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_metatype tmp4_4;modelica_metatype tmp4_5;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inIH;
tmp4_4 = _inClkKind;
tmp4_5 = _inPrefix;
{
modelica_metatype _e = NULL;
modelica_metatype _resolution = NULL;
modelica_metatype _interval = NULL;
modelica_metatype _method = NULL;
modelica_metatype _clkKind = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _ih = NULL;
modelica_metatype _p = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_4))) {
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,0,0) == 0) goto tmp3_end;
_cache = tmp4_1;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _inClkKind;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,1,2) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 3));
_e = tmpMeta5;
_resolution = tmpMeta6;
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_p = tmp4_5;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e, _p ,&_e);
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _resolution, _p ,&_resolution);
tmpMeta7 = mmc_mk_box3(4, &DAE_ClockKind_INTEGER__CLOCK__desc, _e, _resolution);
_clkKind = tmpMeta7;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _clkKind;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,2,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 2));
_e = tmpMeta8;
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_p = tmp4_5;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e, _p ,&_e);
tmpMeta9 = mmc_mk_box2(5, &DAE_ClockKind_REAL__CLOCK__desc, _e);
_clkKind = tmpMeta9;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _clkKind;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,3,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 3));
_e = tmpMeta10;
_interval = tmpMeta11;
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_p = tmp4_5;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e, _p ,&_e);
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _interval, _p ,&_interval);
tmpMeta12 = mmc_mk_box3(6, &DAE_ClockKind_BOOLEAN__CLOCK__desc, _e, _interval);
_clkKind = tmpMeta12;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _clkKind;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,4,2) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 3));
_e = tmpMeta13;
_method = tmpMeta14;
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_p = tmp4_5;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e, _p ,&_e);
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _method, _p ,&_method);
tmpMeta15 = mmc_mk_box3(7, &DAE_ClockKind_SOLVER__CLOCK__desc, _e, _method);
_clkKind = tmpMeta15;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _clkKind;
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
_outCache = tmpMeta[0+0];
_outClkKind = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outClkKind) { *out_outClkKind = _outClkKind; }
return _outCache;
}
DLLExport
modelica_boolean omc_PrefixUtil_isNoPrefix(threadData_t *threadData, modelica_metatype _inPrefix)
{
modelica_boolean _outIsEmpty;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPrefix;
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
_outIsEmpty = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsEmpty;
}
modelica_metatype boxptr_PrefixUtil_isNoPrefix(threadData_t *threadData, modelica_metatype _inPrefix)
{
modelica_boolean _outIsEmpty;
modelica_metatype out_outIsEmpty;
_outIsEmpty = omc_PrefixUtil_isNoPrefix(threadData, _inPrefix);
out_outIsEmpty = mmc_mk_icon(_outIsEmpty);
return out_outIsEmpty;
}
DLLExport
modelica_boolean omc_PrefixUtil_isPrefix(threadData_t *threadData, modelica_metatype _prefix)
{
modelica_boolean _isPrefix;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _prefix;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
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
_isPrefix = tmp1;
_return: OMC_LABEL_UNUSED
return _isPrefix;
}
modelica_metatype boxptr_PrefixUtil_isPrefix(threadData_t *threadData, modelica_metatype _prefix)
{
modelica_boolean _isPrefix;
modelica_metatype out_isPrefix;
_isPrefix = omc_PrefixUtil_isPrefix(threadData, _prefix);
out_isPrefix = mmc_mk_icon(_isPrefix);
return out_isPrefix;
}
DLLExport
modelica_metatype omc_PrefixUtil_prefixDimensions(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPre, modelica_metatype _inDims, modelica_metatype *out_outDims)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outDims = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inDims;
{
modelica_metatype _e = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _new = NULL;
modelica_metatype _d = NULL;
modelica_metatype _cache = NULL;
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
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp4 += 2;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = tmpMeta6;
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
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,3,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_e = tmpMeta9;
_rest = tmpMeta8;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _inCache, _inEnv, _inIH, _e, _inPre ,&_e);
_cache = omc_PrefixUtil_prefixDimensions(threadData, _cache, _inEnv, _inIH, _inPre, _rest ,&_new);
tmpMeta11 = mmc_mk_box2(6, &DAE_Dimension_DIM__EXP__desc, _e);
tmpMeta10 = mmc_mk_cons(tmpMeta11, _new);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta10;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmp4_1);
tmpMeta13 = MMC_CDR(tmp4_1);
_d = tmpMeta12;
_rest = tmpMeta13;
_cache = omc_PrefixUtil_prefixDimensions(threadData, _inCache, _inEnv, _inIH, _inPre, _rest ,&_new);
tmpMeta14 = mmc_mk_cons(_d, _new);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta14;
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
_outDims = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outDims) { *out_outDims = _outDims; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixArrayDimensions(threadData_t *threadData, modelica_metatype _ty, modelica_metatype _tpl, modelica_metatype *out_otpl)
{
modelica_metatype _oty = NULL;
modelica_metatype _otpl = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_oty = _ty;
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _oty;
tmp4_2 = _tpl;
{
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _ih = NULL;
modelica_metatype _pre = NULL;
modelica_metatype _dims = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_cache = tmpMeta6;
_env = tmpMeta7;
_ih = tmpMeta8;
_pre = tmpMeta9;
_cache = omc_PrefixUtil_prefixDimensions(threadData, _cache, _env, _ih, _pre, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_oty), 3))) ,&_dims);
tmpMeta10 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta10), MMC_UNTAGPTR(_oty), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta10))[3] = _dims;
_oty = tmpMeta10;
tmpMeta11 = mmc_mk_box4(0, _cache, _env, _ih, _pre);
tmpMeta[0+0] = _oty;
tmpMeta[0+1] = tmpMeta11;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _oty;
tmpMeta[0+1] = _tpl;
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
_oty = tmpMeta[0+0];
_otpl = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_otpl) { *out_otpl = _otpl; }
return _oty;
}
DLLExport
modelica_metatype omc_PrefixUtil_prefixExpressionsInType(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPre, modelica_metatype _inTy, modelica_metatype *out_outTy)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outTy = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
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
modelica_boolean tmp6;
tmp6 = omc_Config_acceptMetaModelicaGrammar(threadData);
if (1 != tmp6) goto goto_2;
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inTy;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
tmpMeta9 = mmc_mk_box4(0, _inCache, _inEnv, _inIH, _inPre);
tmpMeta10 = omc_Types_traverseType(threadData, _inTy, tmpMeta9, boxvar_PrefixUtil_prefixArrayDimensions, &tmpMeta7);
_outTy = tmpMeta10;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
_outCache = tmpMeta8;
tmpMeta[0+0] = _outCache;
tmpMeta[0+1] = _outTy;
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
_outCache = tmpMeta[0+0];
_outTy = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outTy) { *out_outTy = _outTy; }
return _outCache;
}
DLLExport
modelica_string omc_PrefixUtil_makePrefixString(threadData_t *threadData, modelica_metatype _pre)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _pre;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT9;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
tmpMeta6 = stringAppend(_OMC_LIT10,omc_PrefixUtil_printPrefixStr(threadData, _pre));
tmp1 = tmpMeta6;
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
_str = tmp1;
_return: OMC_LABEL_UNUSED
return _str;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixElse(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _inIH, modelica_metatype _elseBranch, modelica_metatype _p, modelica_metatype *out_outElse)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outElse = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_metatype tmp4_4;modelica_metatype tmp4_5;
tmp4_1 = _cache;
tmp4_2 = _env;
tmp4_3 = _inIH;
tmp4_4 = _elseBranch;
tmp4_5 = _p;
{
modelica_metatype _localCache = NULL;
modelica_metatype _localEnv = NULL;
modelica_metatype _pre = NULL;
modelica_metatype _ih = NULL;
modelica_metatype _e = NULL;
modelica_metatype _lStmt = NULL;
modelica_metatype _el = NULL;
modelica_metatype _stmt = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_4))) {
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,0,0) == 0) goto tmp3_end;
_localCache = tmp4_1;
tmpMeta[0+0] = _localCache;
tmpMeta[0+1] = _OMC_LIT11;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,1,3) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 3));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 4));
_e = tmpMeta5;
_lStmt = tmpMeta6;
_el = tmpMeta7;
_localCache = tmp4_1;
_localEnv = tmp4_2;
_ih = tmp4_3;
_pre = tmp4_5;
_localCache = omc_PrefixUtil_prefixExpWork(threadData, _localCache, _localEnv, _ih, _e, _pre ,&_e);
_localCache = omc_PrefixUtil_prefixElse(threadData, _localCache, _localEnv, _ih, _el, _pre ,&_el);
_localCache = omc_PrefixUtil_prefixStatements(threadData, _localCache, _localEnv, _ih, _lStmt, _pre ,&_lStmt);
tmpMeta8 = mmc_mk_box4(4, &DAE_Else_ELSEIF__desc, _e, _lStmt, _el);
_stmt = tmpMeta8;
tmpMeta[0+0] = _localCache;
tmpMeta[0+1] = _stmt;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,2,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 2));
_lStmt = tmpMeta9;
_localCache = tmp4_1;
_localEnv = tmp4_2;
_ih = tmp4_3;
_pre = tmp4_5;
_localCache = omc_PrefixUtil_prefixStatements(threadData, _localCache, _localEnv, _ih, _lStmt, _pre ,&_lStmt);
tmpMeta10 = mmc_mk_box2(5, &DAE_Else_ELSE__desc, _lStmt);
_stmt = tmpMeta10;
tmpMeta[0+0] = _localCache;
tmpMeta[0+1] = _stmt;
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
_outCache = tmpMeta[0+0];
_outElse = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outElse) { *out_outElse = _outElse; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixStatements(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _inIH, modelica_metatype _stmts, modelica_metatype _p, modelica_metatype *out_outStmts)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outStmts = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta62;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCache = _cache;
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outStmts = tmpMeta1;
{
modelica_metatype _st;
for (tmpMeta2 = _stmts; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_st = MMC_CAR(tmpMeta2);
{
modelica_metatype tmp5_1;
tmp5_1 = _st;
{
modelica_metatype _t = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e3 = NULL;
modelica_metatype _source = NULL;
modelica_metatype _elem = NULL;
modelica_metatype _sList = NULL;
modelica_metatype _b = NULL;
modelica_string _id = NULL;
modelica_metatype _eLst = NULL;
modelica_boolean _bool;
modelica_metatype _elseBranch = NULL;
modelica_integer _ix;
int tmp5;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp5_1))) {
case 3: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,0,4) == 0) goto tmp4_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 5));
_t = tmpMeta6;
_e1 = tmpMeta7;
_e = tmpMeta8;
_source = tmpMeta9;
_outCache = omc_PrefixUtil_prefixExpWork(threadData, _outCache, _env, _inIH, _e1, _p ,&_e1);
_outCache = omc_PrefixUtil_prefixExpWork(threadData, _outCache, _env, _inIH, _e, _p ,&_e);
tmpMeta10 = mmc_mk_box5(3, &DAE_Statement_STMT__ASSIGN__desc, _t, _e1, _e, _source);
_elem = tmpMeta10;
tmpMeta11 = mmc_mk_cons(_elem, _outStmts);
_outStmts = tmpMeta11;
goto tmp4_done;
}
case 4: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,1,4) == 0) goto tmp4_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 3));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 4));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 5));
_t = tmpMeta12;
_eLst = tmpMeta13;
_e = tmpMeta14;
_source = tmpMeta15;
_outCache = omc_PrefixUtil_prefixExpWork(threadData, _outCache, _env, _inIH, _e, _p ,&_e);
_outCache = omc_PrefixUtil_prefixExpList(threadData, _outCache, _env, _inIH, _eLst, _p ,&_eLst);
tmpMeta16 = mmc_mk_box5(4, &DAE_Statement_STMT__TUPLE__ASSIGN__desc, _t, _eLst, _e, _source);
_elem = tmpMeta16;
tmpMeta17 = mmc_mk_cons(_elem, _outStmts);
_outStmts = tmpMeta17;
goto tmp4_done;
}
case 5: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,2,4) == 0) goto tmp4_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 3));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 4));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 5));
_t = tmpMeta18;
_e1 = tmpMeta19;
_e = tmpMeta20;
_source = tmpMeta21;
_outCache = omc_PrefixUtil_prefixExpWork(threadData, _outCache, _env, _inIH, _e1, _p ,&_e1);
_outCache = omc_PrefixUtil_prefixExpWork(threadData, _outCache, _env, _inIH, _e, _p ,&_e);
tmpMeta22 = mmc_mk_box5(5, &DAE_Statement_STMT__ASSIGN__ARR__desc, _t, _e1, _e, _source);
_elem = tmpMeta22;
tmpMeta23 = mmc_mk_cons(_elem, _outStmts);
_outStmts = tmpMeta23;
goto tmp4_done;
}
case 7: {
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_integer tmp26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_integer tmp29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,4,7) == 0) goto tmp4_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 3));
tmp26 = mmc_unbox_integer(tmpMeta25);
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 4));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 5));
tmp29 = mmc_unbox_integer(tmpMeta28);
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 6));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 7));
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 8));
_t = tmpMeta24;
_bool = tmp26;
_id = tmpMeta27;
_ix = tmp29;
_e = tmpMeta30;
_sList = tmpMeta31;
_source = tmpMeta32;
_outCache = omc_PrefixUtil_prefixExpWork(threadData, _outCache, _env, _inIH, _e, _p ,&_e);
_outCache = omc_PrefixUtil_prefixStatements(threadData, _outCache, _env, _inIH, _sList, _p ,&_sList);
tmpMeta33 = mmc_mk_box8(7, &DAE_Statement_STMT__FOR__desc, _t, mmc_mk_boolean(_bool), _id, mmc_mk_integer(_ix), _e, _sList, _source);
_elem = tmpMeta33;
tmpMeta34 = mmc_mk_cons(_elem, _outStmts);
_outStmts = tmpMeta34;
goto tmp4_done;
}
case 6: {
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,3,4) == 0) goto tmp4_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 3));
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 4));
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 5));
_e1 = tmpMeta35;
_sList = tmpMeta36;
_elseBranch = tmpMeta37;
_source = tmpMeta38;
_outCache = omc_PrefixUtil_prefixExpWork(threadData, _outCache, _env, _inIH, _e1, _p ,&_e1);
_outCache = omc_PrefixUtil_prefixStatements(threadData, _outCache, _env, _inIH, _sList, _p ,&_sList);
_outCache = omc_PrefixUtil_prefixElse(threadData, _outCache, _env, _inIH, _elseBranch, _p ,&_elseBranch);
tmpMeta39 = mmc_mk_box5(6, &DAE_Statement_STMT__IF__desc, _e1, _sList, _elseBranch, _source);
_elem = tmpMeta39;
tmpMeta40 = mmc_mk_cons(_elem, _outStmts);
_outStmts = tmpMeta40;
goto tmp4_done;
}
case 9: {
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,6,3) == 0) goto tmp4_end;
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 3));
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 4));
_e1 = tmpMeta41;
_sList = tmpMeta42;
_source = tmpMeta43;
_outCache = omc_PrefixUtil_prefixExpWork(threadData, _outCache, _env, _inIH, _e1, _p ,&_e1);
_outCache = omc_PrefixUtil_prefixStatements(threadData, _outCache, _env, _inIH, _sList, _p ,&_sList);
tmpMeta44 = mmc_mk_box4(9, &DAE_Statement_STMT__WHILE__desc, _e1, _sList, _source);
_elem = tmpMeta44;
tmpMeta45 = mmc_mk_cons(_elem, _outStmts);
_outStmts = tmpMeta45;
goto tmp4_done;
}
case 11: {
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,8,4) == 0) goto tmp4_end;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 3));
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 4));
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 5));
_e1 = tmpMeta46;
_e2 = tmpMeta47;
_e3 = tmpMeta48;
_source = tmpMeta49;
_outCache = omc_PrefixUtil_prefixExpWork(threadData, _outCache, _env, _inIH, _e1, _p ,&_e1);
_outCache = omc_PrefixUtil_prefixExpWork(threadData, _outCache, _env, _inIH, _e2, _p ,&_e2);
_outCache = omc_PrefixUtil_prefixExpWork(threadData, _outCache, _env, _inIH, _e3, _p ,&_e3);
tmpMeta50 = mmc_mk_box5(11, &DAE_Statement_STMT__ASSERT__desc, _e1, _e2, _e3, _source);
_elem = tmpMeta50;
tmpMeta51 = mmc_mk_cons(_elem, _outStmts);
_outStmts = tmpMeta51;
goto tmp4_done;
}
case 19: {
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,16,2) == 0) goto tmp4_end;
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 3));
_b = tmpMeta52;
_source = tmpMeta53;
_outCache = omc_PrefixUtil_prefixStatements(threadData, _outCache, _env, _inIH, _b, _p ,&_b);
tmpMeta54 = mmc_mk_box3(19, &DAE_Statement_STMT__FAILURE__desc, _b, _source);
_elem = tmpMeta54;
tmpMeta55 = mmc_mk_cons(_elem, _outStmts);
_outStmts = tmpMeta55;
goto tmp4_done;
}
case 15: {
modelica_metatype tmpMeta56;
modelica_metatype tmpMeta57;
modelica_metatype tmpMeta58;
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,12,1) == 0) goto tmp4_end;
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
_source = tmpMeta56;
tmpMeta57 = mmc_mk_box2(15, &DAE_Statement_STMT__RETURN__desc, _source);
_elem = tmpMeta57;
tmpMeta58 = mmc_mk_cons(_elem, _outStmts);
_outStmts = tmpMeta58;
goto tmp4_done;
}
case 16: {
modelica_metatype tmpMeta59;
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,13,1) == 0) goto tmp4_end;
tmpMeta59 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
_source = tmpMeta59;
tmpMeta60 = mmc_mk_box2(16, &DAE_Statement_STMT__BREAK__desc, _source);
_elem = tmpMeta60;
tmpMeta61 = mmc_mk_cons(_elem, _outStmts);
_outStmts = tmpMeta61;
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
_outStmts = listReverseInPlace(_outStmts);
_return: OMC_LABEL_UNUSED
if (out_outStmts) { *out_outStmts = _outStmts; }
return _outCache;
}
DLLExport
modelica_metatype omc_PrefixUtil_prefixExpList(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inExpExpLst, modelica_metatype _inPrefix, modelica_metatype *out_outExpExpLst)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outExpExpLst = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _e_1 = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCache = _inCache;
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outExpExpLst = tmpMeta1;
{
modelica_metatype _e;
for (tmpMeta2 = _inExpExpLst; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_e = MMC_CAR(tmpMeta2);
_outCache = omc_PrefixUtil_prefixExpWork(threadData, _outCache, _inEnv, _inIH, _e, _inPrefix ,&_e_1);
tmpMeta3 = mmc_mk_cons(_e_1, _outExpExpLst);
_outExpExpLst = tmpMeta3;
}
}
_outExpExpLst = listReverseInPlace(_outExpExpLst);
_return: OMC_LABEL_UNUSED
if (out_outExpExpLst) { *out_outExpExpLst = _outExpExpLst; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixIterators(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _ih, modelica_metatype _inIters, modelica_metatype _pre, modelica_metatype *out_outIters)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outIters = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inIters;
{
modelica_string _id = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _gexp = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _iter = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _iters = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (!listEmpty(tmp4_3)) goto tmp3_end;
_cache = tmp4_1;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta6;
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
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_3);
tmpMeta8 = MMC_CDR(tmp4_3);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
if (optionNone(tmpMeta11)) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 1));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
_id = tmpMeta9;
_exp = tmpMeta10;
_gexp = tmpMeta12;
_ty = tmpMeta13;
_iters = tmpMeta8;
_cache = tmp4_1;
_env = tmp4_2;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _exp, _pre ,&_exp);
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _gexp, _pre ,&_gexp);
tmpMeta14 = mmc_mk_box5(3, &DAE_ReductionIterator_REDUCTIONITER__desc, _id, _exp, mmc_mk_some(_gexp), _ty);
_iter = tmpMeta14;
_cache = omc_PrefixUtil_prefixIterators(threadData, _cache, _env, _ih, _iters, _pre ,&_iters);
tmpMeta15 = mmc_mk_cons(_iter, _iters);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta15;
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
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmp4_3);
tmpMeta17 = MMC_CDR(tmp4_3);
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 3));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 4));
if (!optionNone(tmpMeta20)) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 5));
_id = tmpMeta18;
_exp = tmpMeta19;
_ty = tmpMeta21;
_iters = tmpMeta17;
_cache = tmp4_1;
_env = tmp4_2;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _exp, _pre ,&_exp);
tmpMeta22 = mmc_mk_box5(3, &DAE_ReductionIterator_REDUCTIONITER__desc, _id, _exp, mmc_mk_none(), _ty);
_iter = tmpMeta22;
_cache = omc_PrefixUtil_prefixIterators(threadData, _cache, _env, _ih, _iters, _pre ,&_iters);
tmpMeta23 = mmc_mk_cons(_iter, _iters);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta23;
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
_outCache = tmpMeta[0+0];
_outIters = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outIters) { *out_outIters = _outIters; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixExpCref2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inIsIter, modelica_metatype _inCref, modelica_metatype _inPrefix, modelica_metatype *out_outCref)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inCache;
tmp4_2 = _inIsIter;
tmp4_3 = _inCref;
{
modelica_metatype _cache = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _exp = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_integer tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,6,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmp9 = mmc_unbox_integer(tmpMeta8);
if (0 != tmp9) goto tmp3_end;
_cr = tmpMeta6;
_ty = tmpMeta7;
_cache = tmp4_1;
_cache = omc_PrefixUtil_prefixCref(threadData, _cache, _inEnv, _inIH, _inPrefix, _cr ,&_cr);
_cache = omc_PrefixUtil_prefixExpressionsInType(threadData, _cache, _inEnv, _inIH, _inPrefix, _ty ,&_ty);
_exp = omc_Expression_makeCrefExp(threadData, _cr, _ty);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _exp;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_integer tmp11;
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmp11 = mmc_unbox_integer(tmpMeta10);
if (1 != tmp11) goto tmp3_end;
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inCref;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (!optionNone(tmp4_2)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,6,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
_cr = tmpMeta12;
_ty = tmpMeta13;
_cache = tmp4_1;
_cache = omc_PrefixUtil_prefixSubscriptsInCref(threadData, _cache, _inEnv, _inIH, _inPrefix, _cr ,&_cr);
_cache = omc_PrefixUtil_prefixExpressionsInType(threadData, _cache, _inEnv, _inIH, _inPrefix, _ty ,&_ty);
_exp = omc_Expression_makeCrefExp(threadData, _cr, _ty);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _exp;
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
_outCache = tmpMeta[0+0];
_outCref = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outCref) { *out_outCref = _outCref; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixExpCref(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inCref, modelica_metatype _inPrefix, modelica_metatype *out_outCref)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outCref = NULL;
modelica_metatype _is_iter = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _cr = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inCref;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,6,2) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_cr = tmpMeta2;
_is_iter = omc_Lookup_isIterator(threadData, _inCache, _inEnv, _cr ,&_cache);
_outCache = omc_PrefixUtil_prefixExpCref2(threadData, _cache, _inEnv, _inIH, _is_iter, _inCref, _inPrefix ,&_outCref);
_return: OMC_LABEL_UNUSED
if (out_outCref) { *out_outCref = _outCref; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixExpWork(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcache, modelica_metatype _env, modelica_metatype _ih, modelica_metatype _inExp, modelica_metatype _pre, modelica_metatype *out_outExp)
{
modelica_metatype _cache = NULL;
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cache = __omcQ_24in_5Fcache;
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _pre;
{
modelica_metatype _e = NULL;
modelica_metatype _e1_1 = NULL;
modelica_metatype _e2_1 = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e3_1 = NULL;
modelica_metatype _e3 = NULL;
modelica_metatype _cref_1 = NULL;
modelica_metatype _dim_1 = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _dim = NULL;
modelica_metatype _start_1 = NULL;
modelica_metatype _stop_1 = NULL;
modelica_metatype _start = NULL;
modelica_metatype _stop = NULL;
modelica_metatype _step_1 = NULL;
modelica_metatype _step = NULL;
modelica_metatype _e_1 = NULL;
modelica_metatype _exp_1 = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _crefExp = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _cr_1 = NULL;
modelica_metatype _o = NULL;
modelica_metatype _es_1 = NULL;
modelica_metatype _es = NULL;
modelica_metatype _f = NULL;
modelica_boolean _sc;
modelica_metatype _x_1 = NULL;
modelica_metatype _x = NULL;
modelica_metatype _xs_1 = NULL;
modelica_metatype _xs = NULL;
modelica_metatype _expl = NULL;
modelica_integer _a;
modelica_metatype _t = NULL;
modelica_metatype _tp = NULL;
modelica_integer _index_;
modelica_metatype _isExpisASUB = NULL;
modelica_metatype _reductionInfo = NULL;
modelica_metatype _riters = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _fieldNames = NULL;
modelica_metatype _clk = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 41; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
_e = tmp4_1;
if (!(!omc_System_getHasInnerOuterDefinitions(threadData))) goto tmp3_end;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _e;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
_e = tmp4_1;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _e;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
_e = tmp4_1;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _e;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
_e = tmp4_1;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _e;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
_e = tmp4_1;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _e;
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
_e = tmp4_1;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _e;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_cr = tmpMeta6;
_t = tmpMeta7;
if((omc_System_getHasInnerOuterDefinitions(threadData) && (!listEmpty(_ih))))
{
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
_cr_1 = omc_InnerOuter_prefixOuterCrefWithTheInnerPrefix(threadData, _ih, _cr, _pre);
_cache = omc_PrefixUtil_prefixExpressionsInType(threadData, _cache, _env, _ih, _pre, _t ,&_t);
_outExp = omc_Expression_makeCrefExp(threadData, _cr_1, _t);
goto _return;
goto tmp9_done;
}
case 1: {
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
}
if(valueEq(_OMC_LIT12, _pre))
{
_crefExp = _inExp;
}
else
{
_cache = omc_PrefixUtil_prefixExpCref(threadData, _cache, _env, _ih, _inExp, _pre ,&_crefExp);
}
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _crefExp;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_clk = tmpMeta12;
_cache = omc_PrefixUtil_prefixClockKind(threadData, _cache, _env, _ih, _clk, _pre ,&_clk);
tmpMeta13 = mmc_mk_box2(7, &DAE_Exp_CLKCONST__desc, _clk);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta13;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,2) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e1 = tmpMeta14;
_expl = tmpMeta15;
_cache = omc_PrefixUtil_prefixExpList(threadData, _cache, _env, _ih, _expl, _pre ,&_es_1);
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e1, _pre ,&_e1);
_e2 = omc_Expression_makeASUB(threadData, _e1, _es_1);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _e2;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_integer tmp18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,3) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp18 = mmc_unbox_integer(tmpMeta17);
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta16;
_index_ = tmp18;
_t = tmpMeta19;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e1, _pre ,&_e1);
tmpMeta20 = mmc_mk_box4(25, &DAE_Exp_TSUB__desc, _e1, mmc_mk_integer(_index_), _t);
_e2 = tmpMeta20;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _e2;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta21;
_o = tmpMeta22;
_e2 = tmpMeta23;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e1, _pre ,&_e1_1);
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e2, _pre ,&_e2_1);
tmpMeta24 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _o, _e2_1);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta24;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_o = tmpMeta25;
_e1 = tmpMeta26;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e1, _pre ,&_e1_1);
tmpMeta27 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _o, _e1_1);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta27;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta28;
_o = tmpMeta29;
_e2 = tmpMeta30;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e1, _pre ,&_e1_1);
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e2, _pre ,&_e2_1);
tmpMeta31 = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, _e1_1, _o, _e2_1);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta31;
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,2) == 0) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_o = tmpMeta32;
_e1 = tmpMeta33;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e1, _pre ,&_e1_1);
tmpMeta34 = mmc_mk_box3(13, &DAE_Exp_LUNARY__desc, _o, _e1_1);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta34;
goto tmp3_done;
}
case 14: {
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_integer tmp39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,5) == 0) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmp39 = mmc_unbox_integer(tmpMeta38);
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_e1 = tmpMeta35;
_o = tmpMeta36;
_e2 = tmpMeta37;
_index_ = tmp39;
_isExpisASUB = tmpMeta40;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e1, _pre ,&_e1_1);
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e2, _pre ,&_e2_1);
tmpMeta41 = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, _e1_1, _o, _e2_1, mmc_mk_integer(_index_), _isExpisASUB);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta41;
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,3) == 0) goto tmp3_end;
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta42;
_e2 = tmpMeta43;
_e3 = tmpMeta44;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e1, _pre ,&_e1_1);
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e2, _pre ,&_e2_1);
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e3, _pre ,&_e3_1);
tmpMeta45 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _e1_1, _e2_1, _e3_1);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta45;
goto tmp3_done;
}
case 16: {
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,2) == 0) goto tmp3_end;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (optionNone(tmpMeta47)) goto tmp3_end;
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta47), 1));
_cref = tmpMeta46;
_dim = tmpMeta48;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _cref, _pre ,&_cref_1);
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _dim, _pre ,&_dim_1);
tmpMeta49 = mmc_mk_box3(27, &DAE_Exp_SIZE__desc, _cref_1, mmc_mk_some(_dim_1));
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta49;
goto tmp3_done;
}
case 17: {
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,2) == 0) goto tmp3_end;
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!optionNone(tmpMeta51)) goto tmp3_end;
_cref = tmpMeta50;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _cref, _pre ,&_cref_1);
tmpMeta52 = mmc_mk_box3(27, &DAE_Exp_SIZE__desc, _cref_1, mmc_mk_none());
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta52;
goto tmp3_done;
}
case 18: {
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_f = tmpMeta53;
_es = tmpMeta54;
_attr = tmpMeta55;
_cache = omc_PrefixUtil_prefixExpList(threadData, _cache, _env, _ih, _es, _pre ,&_es_1);
tmpMeta56 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _f, _es_1, _attr);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta56;
goto tmp3_done;
}
case 19: {
modelica_metatype tmpMeta57;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,4) == 0) goto tmp3_end;
_e = tmp4_1;
_cache = omc_PrefixUtil_prefixExpList(threadData, _cache, _env, _ih, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 3))), _pre ,&_es_1);
tmpMeta57 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta57), MMC_UNTAGPTR(_e), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta57))[3] = _es_1;
_e = tmpMeta57;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _e;
goto tmp3_done;
}
case 20: {
modelica_metatype tmpMeta58;
modelica_metatype tmpMeta59;
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
modelica_metatype tmpMeta62;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,14,4) == 0) goto tmp3_end;
tmpMeta58 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta59 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta61 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_f = tmpMeta58;
_es = tmpMeta59;
_fieldNames = tmpMeta60;
_t = tmpMeta61;
_cache = omc_PrefixUtil_prefixExpList(threadData, _cache, _env, _ih, _es, _pre, NULL);
tmpMeta62 = mmc_mk_box5(17, &DAE_Exp_RECORD__desc, _f, _es, _fieldNames, _t);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta62;
goto tmp3_done;
}
case 21: {
modelica_metatype tmpMeta63;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta63 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta63)) goto tmp3_end;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _inExp;
goto tmp3_done;
}
case 22: {
modelica_metatype tmpMeta64;
modelica_metatype tmpMeta65;
modelica_integer tmp66;
modelica_metatype tmpMeta67;
modelica_metatype tmpMeta68;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta64 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp66 = mmc_unbox_integer(tmpMeta65);
tmpMeta67 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_t = tmpMeta64;
_sc = tmp66;
_es = tmpMeta67;
_cache = omc_PrefixUtil_prefixExpList(threadData, _cache, _env, _ih, _es, _pre ,&_es_1);
tmpMeta68 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _t, mmc_mk_boolean(_sc), _es_1);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta68;
goto tmp3_done;
}
case 23: {
modelica_metatype tmpMeta69;
modelica_metatype tmpMeta70;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,19,1) == 0) goto tmp3_end;
tmpMeta69 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_es = tmpMeta69;
_cache = omc_PrefixUtil_prefixExpList(threadData, _cache, _env, _ih, _es, _pre ,&_es_1);
tmpMeta70 = mmc_mk_box2(22, &DAE_Exp_TUPLE__desc, _es_1);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta70;
goto tmp3_done;
}
case 24: {
modelica_metatype tmpMeta71;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,3) == 0) goto tmp3_end;
tmpMeta71 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta71)) goto tmp3_end;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _inExp;
goto tmp3_done;
}
case 25: {
modelica_metatype tmpMeta72;
modelica_metatype tmpMeta73;
modelica_integer tmp74;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,3) == 0) goto tmp3_end;
tmpMeta72 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta73 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp74 = mmc_unbox_integer(tmpMeta73);
tmpMeta75 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta75)) goto tmp3_end;
tmpMeta76 = MMC_CAR(tmpMeta75);
tmpMeta77 = MMC_CDR(tmpMeta75);
_t = tmpMeta72;
_a = tmp74;
_x = tmpMeta76;
_xs = tmpMeta77;
_cache = omc_PrefixUtil_prefixExpList(threadData, _cache, _env, _ih, _x, _pre ,&_x_1);
tmpMeta81 = mmc_mk_box4(20, &DAE_Exp_MATRIX__desc, _t, mmc_mk_integer(_a), _xs);
tmpMeta82 = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, tmpMeta81, _pre, &tmpMeta78);
_cache = tmpMeta82;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta78,17,3) == 0) goto goto_2;
tmpMeta79 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta78), 2));
tmpMeta80 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta78), 4));
_t = tmpMeta79;
_xs_1 = tmpMeta80;
tmpMeta83 = mmc_mk_cons(_x_1, _xs_1);
tmpMeta84 = mmc_mk_box4(20, &DAE_Exp_MATRIX__desc, _t, mmc_mk_integer(_a), tmpMeta83);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta84;
goto tmp3_done;
}
case 26: {
modelica_metatype tmpMeta85;
modelica_metatype tmpMeta86;
modelica_metatype tmpMeta87;
modelica_metatype tmpMeta88;
modelica_metatype tmpMeta89;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,4) == 0) goto tmp3_end;
tmpMeta85 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta86 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta87 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!optionNone(tmpMeta87)) goto tmp3_end;
tmpMeta88 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_t = tmpMeta85;
_start = tmpMeta86;
_stop = tmpMeta88;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _start, _pre ,&_start_1);
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _stop, _pre ,&_stop_1);
tmpMeta89 = mmc_mk_box5(21, &DAE_Exp_RANGE__desc, _t, _start_1, mmc_mk_none(), _stop_1);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta89;
goto tmp3_done;
}
case 27: {
modelica_metatype tmpMeta90;
modelica_metatype tmpMeta91;
modelica_metatype tmpMeta92;
modelica_metatype tmpMeta93;
modelica_metatype tmpMeta94;
modelica_metatype tmpMeta95;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,4) == 0) goto tmp3_end;
tmpMeta90 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta91 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta92 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (optionNone(tmpMeta92)) goto tmp3_end;
tmpMeta93 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta92), 1));
tmpMeta94 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_t = tmpMeta90;
_start = tmpMeta91;
_step = tmpMeta93;
_stop = tmpMeta94;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _start, _pre ,&_start_1);
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _step, _pre ,&_step_1);
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _stop, _pre ,&_stop_1);
tmpMeta95 = mmc_mk_box5(21, &DAE_Exp_RANGE__desc, _t, _start_1, mmc_mk_some(_step_1), _stop_1);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta95;
goto tmp3_done;
}
case 28: {
modelica_metatype tmpMeta96;
modelica_metatype tmpMeta97;
modelica_metatype tmpMeta98;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,20,2) == 0) goto tmp3_end;
tmpMeta96 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta97 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_tp = tmpMeta96;
_e = tmpMeta97;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e, _pre ,&_e_1);
tmpMeta98 = mmc_mk_box3(23, &DAE_Exp_CAST__desc, _tp, _e_1);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta98;
goto tmp3_done;
}
case 29: {
modelica_metatype tmpMeta99;
modelica_metatype tmpMeta100;
modelica_metatype tmpMeta101;
modelica_metatype tmpMeta102;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,27,3) == 0) goto tmp3_end;
tmpMeta99 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta100 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta101 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_reductionInfo = tmpMeta99;
_exp = tmpMeta100;
_riters = tmpMeta101;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _exp, _pre ,&_exp_1);
_cache = omc_PrefixUtil_prefixIterators(threadData, _cache, _env, _ih, _riters, _pre ,&_riters);
tmpMeta102 = mmc_mk_box4(30, &DAE_Exp_REDUCTION__desc, _reductionInfo, _exp_1, _riters);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta102;
goto tmp3_done;
}
case 30: {
modelica_metatype tmpMeta103;
modelica_metatype tmpMeta104;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,28,1) == 0) goto tmp3_end;
tmpMeta103 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_es = tmpMeta103;
_cache = omc_PrefixUtil_prefixExpList(threadData, _cache, _env, _ih, _es, _pre ,&_es_1);
tmpMeta104 = mmc_mk_box2(31, &DAE_Exp_LIST__desc, _es_1);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta104;
goto tmp3_done;
}
case 31: {
modelica_metatype tmpMeta105;
modelica_metatype tmpMeta106;
modelica_metatype tmpMeta107;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,29,2) == 0) goto tmp3_end;
tmpMeta105 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta106 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e1 = tmpMeta105;
_e2 = tmpMeta106;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e1, _pre ,&_e1);
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e2, _pre ,&_e2);
tmpMeta107 = mmc_mk_box3(32, &DAE_Exp_CONS__desc, _e1, _e2);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta107;
goto tmp3_done;
}
case 32: {
modelica_metatype tmpMeta108;
modelica_metatype tmpMeta109;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,30,1) == 0) goto tmp3_end;
tmpMeta108 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_es = tmpMeta108;
_cache = omc_PrefixUtil_prefixExpList(threadData, _cache, _env, _ih, _es, _pre ,&_es_1);
tmpMeta109 = mmc_mk_box2(33, &DAE_Exp_META__TUPLE__desc, _es_1);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta109;
goto tmp3_done;
}
case 33: {
modelica_metatype tmpMeta110;
modelica_metatype tmpMeta111;
modelica_metatype tmpMeta112;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,31,1) == 0) goto tmp3_end;
tmpMeta110 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (optionNone(tmpMeta110)) goto tmp3_end;
tmpMeta111 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta110), 1));
_e1 = tmpMeta111;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e1, _pre ,&_e1);
tmpMeta112 = mmc_mk_box2(34, &DAE_Exp_META__OPTION__desc, mmc_mk_some(_e1));
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta112;
goto tmp3_done;
}
case 34: {
modelica_metatype tmpMeta113;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,31,1) == 0) goto tmp3_end;
tmpMeta113 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!optionNone(tmpMeta113)) goto tmp3_end;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _OMC_LIT13;
goto tmp3_done;
}
case 35: {
modelica_metatype tmpMeta114;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,32,5) == 0) goto tmp3_end;
_cache = omc_PrefixUtil_prefixExpList(threadData, _cache, _env, _ih, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inExp), 3))), _pre ,&_expl);
tmpMeta114 = mmc_mk_box6(35, &DAE_Exp_METARECORDCALL__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inExp), 2))), _expl, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inExp), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inExp), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inExp), 6))));
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta114;
goto tmp3_done;
}
case 36: {
modelica_metatype tmpMeta115;
modelica_metatype tmpMeta116;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,35,2) == 0) goto tmp3_end;
tmpMeta115 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_e = tmp4_1;
_e1 = tmpMeta115;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e1, _pre ,&_e1);
tmpMeta116 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta116), MMC_UNTAGPTR(_e), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta116))[2] = _e1;
_e = tmpMeta116;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _e;
goto tmp3_done;
}
case 37: {
modelica_metatype tmpMeta117;
modelica_metatype tmpMeta118;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,34,1) == 0) goto tmp3_end;
tmpMeta117 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_e = tmp4_1;
_e1 = tmpMeta117;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _e1, _pre ,&_e1);
tmpMeta118 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta118), MMC_UNTAGPTR(_e), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta118))[2] = _e1;
_e = tmpMeta118;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _e;
goto tmp3_done;
}
case 38: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
_e = tmp4_1;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _e;
goto tmp3_done;
}
case 39: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,26,4) == 0) goto tmp3_end;
_e = tmp4_1;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _e;
goto tmp3_done;
}
case 40: {
modelica_metatype tmpMeta119;
modelica_metatype tmpMeta120;
modelica_metatype tmpMeta121;
tmpMeta119 = stringAppend(_OMC_LIT14,omc_ExpressionDump_printExpStr(threadData, _inExp));
tmpMeta120 = stringAppend(tmpMeta119,_OMC_LIT15);
tmpMeta121 = stringAppend(tmpMeta120,omc_PrefixUtil_makePrefixString(threadData, _pre));
omc_Error_addInternalError(threadData, tmpMeta121, _OMC_LIT16);
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
_cache = tmpMeta[0+0];
_outExp = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outExp) { *out_outExp = _outExp; }
return _cache;
}
DLLExport
modelica_metatype omc_PrefixUtil_prefixExp(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcache, modelica_metatype _env, modelica_metatype _ih, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype _pre, modelica_metatype *out_exp)
{
modelica_metatype _cache = NULL;
modelica_metatype _exp = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cache = __omcQ_24in_5Fcache;
_exp = __omcQ_24in_5Fexp;
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
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _ih, _exp, _pre ,&_exp);
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta5 = stringAppend(_OMC_LIT17,omc_ExpressionDump_printExpStr(threadData, _exp));
tmpMeta6 = stringAppend(tmpMeta5,_OMC_LIT15);
tmpMeta7 = stringAppend(tmpMeta6,omc_PrefixUtil_makePrefixString(threadData, _pre));
omc_Error_addInternalError(threadData, tmpMeta7, _OMC_LIT18);
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
_return: OMC_LABEL_UNUSED
if (out_exp) { *out_exp = _exp; }
return _cache;
}
DLLExport
modelica_metatype omc_PrefixUtil_prefixCrefInnerOuter(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inCref, modelica_metatype _inPrefix, modelica_metatype *out_outCref)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_metatype tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inIH;
tmp4_3 = _inCref;
tmp4_4 = _inPrefix;
{
modelica_metatype _cache = NULL;
modelica_metatype _ih = NULL;
modelica_metatype _pre = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _newCref = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_cache = tmp4_1;
_ih = tmp4_2;
_cref = tmp4_3;
_pre = tmp4_4;
_newCref = omc_InnerOuter_prefixOuterCrefWithTheInnerPrefix(threadData, _ih, _cref, _pre);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _newCref;
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
_outCache = tmpMeta[0+0];
_outCref = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outCref) { *out_outCref = _outCref; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixSubscript(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _pre, modelica_metatype _sub, modelica_metatype *out_outSub)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outSub = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _sub;
{
modelica_metatype _exp = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_3))) {
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,0) == 0) goto tmp3_end;
_cache = tmp4_1;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _OMC_LIT19;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
_exp = tmpMeta5;
_cache = tmp4_1;
_env = tmp4_2;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _inIH, _exp, _pre ,&_exp);
tmpMeta6 = mmc_mk_box2(4, &DAE_Subscript_SLICE__desc, _exp);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta6;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
_exp = tmpMeta7;
_cache = tmp4_1;
_env = tmp4_2;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _inIH, _exp, _pre ,&_exp);
tmpMeta8 = mmc_mk_box2(6, &DAE_Subscript_WHOLE__NONEXP__desc, _exp);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta8;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
_exp = tmpMeta9;
_cache = tmp4_1;
_env = tmp4_2;
_cache = omc_PrefixUtil_prefixExpWork(threadData, _cache, _env, _inIH, _exp, _pre ,&_exp);
tmpMeta10 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, _exp);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta10;
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
_outCache = tmpMeta[0+0];
_outSub = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outSub) { *out_outSub = _outSub; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixSubscripts(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _pre, modelica_metatype _inSubs, modelica_metatype *out_outSubs)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outSubs = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inSubs;
{
modelica_metatype _sub = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _subs = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (!listEmpty(tmp4_3)) goto tmp3_end;
_cache = tmp4_1;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_3);
tmpMeta8 = MMC_CDR(tmp4_3);
_sub = tmpMeta7;
_subs = tmpMeta8;
_cache = tmp4_1;
_env = tmp4_2;
_cache = omc_PrefixUtil_prefixSubscript(threadData, _cache, _env, _inIH, _pre, _sub ,&_sub);
_cache = omc_PrefixUtil_prefixSubscripts(threadData, _cache, _env, _inIH, _pre, _subs ,&_subs);
tmpMeta9 = mmc_mk_cons(_sub, _subs);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta9;
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
_outCache = tmpMeta[0+0];
_outSubs = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outSubs) { *out_outSubs = _outSubs; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixSubscriptsInCrefWork(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _pre, modelica_metatype _inCr, modelica_metatype _acc, modelica_metatype *out_outCr)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outCr = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inCr;
{
modelica_string _id = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _crid = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_3))) {
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,3) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_id = tmpMeta5;
_tp = tmpMeta6;
_subs = tmpMeta7;
_cache = tmp4_1;
_env = tmp4_2;
_cache = omc_PrefixUtil_prefixSubscripts(threadData, _cache, _env, _inIH, _pre, _subs ,&_subs);
_cr = omc_ComponentReference_makeCrefIdent(threadData, _id, _tp, _subs);
tmpMeta8 = mmc_mk_cons(_cr, _acc);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = omc_ComponentReference_implode__reverse(threadData, tmpMeta8);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,4) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 5));
_id = tmpMeta9;
_tp = tmpMeta10;
_subs = tmpMeta11;
_cr = tmpMeta12;
_cache = tmp4_1;
_env = tmp4_2;
_cache = omc_PrefixUtil_prefixSubscripts(threadData, _cache, _env, _inIH, _pre, _subs ,&_subs);
_crid = omc_ComponentReference_makeCrefIdent(threadData, _id, _tp, _subs);
tmpMeta13 = mmc_mk_cons(_crid, _acc);
_inCache = _cache;
_inEnv = _env;
_inCr = _cr;
_acc = tmpMeta13;
goto _tailrecursive;
goto tmp3_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,4,0) == 0) goto tmp3_end;
_cache = tmp4_1;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _OMC_LIT20;
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
_outCache = tmpMeta[0+0];
_outCr = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outCr) { *out_outCr = _outCr; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixSubscriptsInCref(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _pre, modelica_metatype _inCr, modelica_metatype *out_outCr)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outCr = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outCache = omc_PrefixUtil_prefixSubscriptsInCrefWork(threadData, _inCache, _inEnv, _inIH, _pre, _inCr, tmpMeta1 ,&_outCr);
_return: OMC_LABEL_UNUSED
if (out_outCr) { *out_outCr = _outCr; }
return _outCache;
}
DLLExport
modelica_metatype omc_PrefixUtil_makeCrefFromPrefixNoFail(threadData_t *threadData, modelica_metatype _pre)
{
modelica_metatype _cref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _pre;
{
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmp4 += 1;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_ComponentReference_makeCrefIdent(threadData, _OMC_LIT6, _OMC_LIT21, tmpMeta6);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,0) == 0) goto tmp3_end;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_ComponentReference_makeCrefIdent(threadData, _OMC_LIT6, _OMC_LIT21, tmpMeta8);
goto tmp3_done;
}
case 2: {
tmpMeta1 = omc_PrefixUtil_prefixToCref(threadData, _pre);
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
_cref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _cref;
}
DLLExport
modelica_metatype omc_PrefixUtil_prefixToCrefOpt2(threadData_t *threadData, modelica_metatype _inPrefix, modelica_metatype _inExpComponentRefOption)
{
modelica_metatype _outComponentRefOpt = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inPrefix;
tmp4_2 = _inExpComponentRefOption;
{
modelica_metatype _cref = NULL;
modelica_metatype _cref_ = NULL;
modelica_string _i = NULL;
modelica_metatype _s = NULL;
modelica_metatype _xs = NULL;
modelica_metatype _cp = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
if (!optionNone(tmp4_2)) goto tmp3_end;
tmpMeta1 = mmc_mk_none();
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
_cref = tmpMeta6;
tmpMeta1 = mmc_mk_some(_cref);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,0) == 0) goto tmp3_end;
_cref = tmpMeta7;
tmpMeta1 = mmc_mk_some(_cref);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (!optionNone(tmp4_2)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,0,6) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 5));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_i = tmpMeta10;
_s = tmpMeta11;
_xs = tmpMeta12;
_cp = tmpMeta13;
_cref_ = omc_ComponentReference_makeCrefIdent(threadData, _i, _OMC_LIT24, _s);
tmpMeta14 = mmc_mk_box3(4, &DAE_Prefix_PREFIX__desc, _xs, _cp);
_inPrefix = tmpMeta14;
_inExpComponentRefOption = mmc_mk_some(_cref_);
goto _tailrecursive;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,0,6) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 4));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 5));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_cref = tmpMeta15;
_i = tmpMeta17;
_s = tmpMeta18;
_xs = tmpMeta19;
_cp = tmpMeta20;
_cref_ = omc_ComponentReference_makeCrefQual(threadData, _i, _OMC_LIT24, _s, _cref);
tmpMeta21 = mmc_mk_box3(4, &DAE_Prefix_PREFIX__desc, _xs, _cp);
_inPrefix = tmpMeta21;
_inExpComponentRefOption = mmc_mk_some(_cref_);
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
_outComponentRefOpt = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRefOpt;
}
DLLExport
modelica_metatype omc_PrefixUtil_prefixToCrefOpt(threadData_t *threadData, modelica_metatype _pre)
{
modelica_metatype _cref_1 = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cref_1 = omc_PrefixUtil_prefixToCrefOpt2(threadData, _pre, mmc_mk_none());
_return: OMC_LABEL_UNUSED
return _cref_1;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_prefixToCref2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPrefix, modelica_metatype _inExpComponentRefOption, modelica_metatype *out_outComponentRef)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_metatype tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inPrefix;
tmp4_4 = _inExpComponentRefOption;
{
modelica_metatype _cref = NULL;
modelica_metatype _cref_2 = NULL;
modelica_metatype _cref_ = NULL;
modelica_string _i = NULL;
modelica_metatype _s = NULL;
modelica_metatype _ds = NULL;
modelica_metatype _ident_ty = NULL;
modelica_metatype _xs = NULL;
modelica_metatype _cp = NULL;
modelica_metatype _ci_state = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,0) == 0) goto tmp3_end;
if (!optionNone(tmp4_4)) goto tmp3_end;
goto goto_2;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (!optionNone(tmp4_4)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,0) == 0) goto tmp3_end;
goto goto_2;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,0) == 0) goto tmp3_end;
if (optionNone(tmp4_4)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 1));
_cref = tmpMeta7;
_cache = tmp4_1;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _cref;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (optionNone(tmp4_4)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,1,0) == 0) goto tmp3_end;
_cref = tmpMeta8;
_cache = tmp4_1;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _cref;
goto tmp3_done;
}
case 4: {
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
if (!optionNone(tmp4_4)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,0,6) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 3));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 4));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 5));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 6));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
_i = tmpMeta11;
_ds = tmpMeta12;
_s = tmpMeta13;
_xs = tmpMeta14;
_ci_state = tmpMeta15;
_cp = tmpMeta16;
_cache = tmp4_1;
_env = tmp4_2;
tmpMeta17 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta18 = mmc_mk_box4(12, &DAE_Type_T__COMPLEX__desc, _ci_state, tmpMeta17, mmc_mk_none());
_ident_ty = omc_Expression_liftArrayLeftList(threadData, tmpMeta18, _ds);
_cref_ = omc_ComponentReference_makeCrefIdent(threadData, _i, _ident_ty, _s);
tmpMeta19 = mmc_mk_box3(4, &DAE_Prefix_PREFIX__desc, _xs, _cp);
_inCache = _cache;
_inEnv = _env;
_inPrefix = tmpMeta19;
_inExpComponentRefOption = mmc_mk_some(_cref_);
goto _tailrecursive;
goto tmp3_done;
}
case 5: {
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
if (optionNone(tmp4_4)) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,2) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta21,0,6) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 2));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 3));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 4));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 5));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 6));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
_cref = tmpMeta20;
_i = tmpMeta22;
_ds = tmpMeta23;
_s = tmpMeta24;
_xs = tmpMeta25;
_ci_state = tmpMeta26;
_cp = tmpMeta27;
_cache = tmp4_1;
_env = tmp4_2;
_cache = omc_PrefixUtil_prefixSubscriptsInCref(threadData, _cache, _env, _inIH, _inPrefix, _cref ,&_cref);
tmpMeta28 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta29 = mmc_mk_box4(12, &DAE_Type_T__COMPLEX__desc, _ci_state, tmpMeta28, mmc_mk_none());
_ident_ty = omc_Expression_liftArrayLeftList(threadData, tmpMeta29, _ds);
_cref_2 = omc_ComponentReference_makeCrefQual(threadData, _i, _ident_ty, _s, _cref);
tmpMeta30 = mmc_mk_box3(4, &DAE_Prefix_PREFIX__desc, _xs, _cp);
_inCache = _cache;
_inEnv = _env;
_inPrefix = tmpMeta30;
_inExpComponentRefOption = mmc_mk_some(_cref_2);
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
_outCache = tmpMeta[0+0];
_outComponentRef = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outComponentRef) { *out_outComponentRef = _outComponentRef; }
return _outCache;
}
DLLExport
modelica_metatype omc_PrefixUtil_prefixToCref(threadData_t *threadData, modelica_metatype _pre)
{
modelica_metatype _cref_1 = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
omc_PrefixUtil_prefixToCref2(threadData, omc_FCore_noCache(threadData), omc_FGraph_empty(threadData), tmpMeta1, _pre, mmc_mk_none() ,&_cref_1);
_return: OMC_LABEL_UNUSED
return _cref_1;
}
DLLExport
modelica_metatype omc_PrefixUtil_prefixCrefNoContext(threadData_t *threadData, modelica_metatype _inPre, modelica_metatype _inCref)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
omc_PrefixUtil_prefixToCref2(threadData, omc_FCore_noCache(threadData), omc_FGraph_empty(threadData), tmpMeta1, _inPre, mmc_mk_some(_inCref) ,&_outCref);
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_metatype omc_PrefixUtil_prefixCref(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _inIH, modelica_metatype _pre, modelica_metatype _cref, modelica_metatype *out_cref_1)
{
modelica_metatype _outCache = NULL;
modelica_metatype _cref_1 = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCache = omc_PrefixUtil_prefixToCref2(threadData, _cache, _env, _inIH, _pre, mmc_mk_some(_cref) ,&_cref_1);
_return: OMC_LABEL_UNUSED
if (out_cref_1) { *out_cref_1 = _cref_1; }
return _outCache;
}
DLLExport
modelica_metatype omc_PrefixUtil_componentPrefixToPath(threadData_t *threadData, modelica_metatype _pre)
{
modelica_metatype _path = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _pre;
{
modelica_string _s = NULL;
modelica_metatype _ss = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,0) == 0) goto tmp3_end;
_s = tmpMeta6;
tmpMeta8 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _s);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_s = tmpMeta9;
_ss = tmpMeta10;
tmpMeta11 = mmc_mk_box3(3, &Absyn_Path_QUALIFIED__desc, _s, omc_PrefixUtil_componentPrefixToPath(threadData, _ss));
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
_path = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _path;
}
DLLExport
modelica_string omc_PrefixUtil_identAndPrefixToPath(threadData_t *threadData, modelica_string _ident, modelica_metatype _inPrefix)
{
modelica_string _str = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _ident);
_str = omc_AbsynUtil_pathString(threadData, omc_PrefixUtil_prefixPath(threadData, tmpMeta1, _inPrefix), _OMC_LIT25, 1, 0);
_return: OMC_LABEL_UNUSED
return _str;
}
DLLExport
modelica_metatype omc_PrefixUtil_prefixToPath(threadData_t *threadData, modelica_metatype _inPrefix)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPrefix;
{
modelica_metatype _ss = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_ss = tmpMeta6;
tmpMeta1 = omc_PrefixUtil_componentPrefixToPath(threadData, _ss);
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
_outPath = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outPath;
}
DLLExport
modelica_metatype omc_PrefixUtil_prefixPath(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inPrefix)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inPath;
tmp4_2 = _inPrefix;
{
modelica_metatype _p = NULL;
modelica_string _s = NULL;
modelica_metatype _ss = NULL;
modelica_metatype _cp = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
_p = tmp4_1;
tmpMeta1 = _p;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,6) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,0) == 0) goto tmp3_end;
_s = tmpMeta7;
_p = tmp4_1;
tmpMeta9 = mmc_mk_box3(3, &Absyn_Path_QUALIFIED__desc, _s, _p);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,0,6) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 5));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_s = tmpMeta11;
_ss = tmpMeta12;
_cp = tmpMeta13;
_p = tmp4_1;
tmpMeta14 = mmc_mk_box3(3, &Absyn_Path_QUALIFIED__desc, _s, _p);
tmpMeta15 = mmc_mk_box3(4, &DAE_Prefix_PREFIX__desc, _ss, _cp);
_inPath = tmpMeta14;
_inPrefix = tmpMeta15;
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
_outPath = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outPath;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_PrefixUtil_compPreStripLast(threadData_t *threadData, modelica_metatype _inCompPrefix)
{
modelica_metatype _outCompPrefix = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCompPrefix;
{
modelica_metatype _next = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT0;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_next = tmpMeta6;
tmpMeta1 = _next;
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
_outCompPrefix = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCompPrefix;
}
DLLExport
modelica_metatype omc_PrefixUtil_prefixStripLast(threadData_t *threadData, modelica_metatype _inPrefix)
{
modelica_metatype _outPrefix = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPrefix;
{
modelica_metatype _cp = NULL;
modelica_metatype _compPre = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT12;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_compPre = tmpMeta6;
_cp = tmpMeta7;
_compPre = omc_PrefixUtil_compPreStripLast(threadData, _compPre);
tmpMeta8 = mmc_mk_box3(4, &DAE_Prefix_PREFIX__desc, _compPre, _cp);
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
_outPrefix = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outPrefix;
}
DLLExport
modelica_metatype omc_PrefixUtil_prefixLast(threadData_t *threadData, modelica_metatype _inPrefix)
{
modelica_metatype _outPrefix = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inPrefix;
{
modelica_metatype _p = NULL;
modelica_metatype _res = NULL;
modelica_metatype _cp = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,6) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,0) == 0) goto tmp3_end;
_res = tmp4_1;
tmpMeta1 = _res;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,6) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 5));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_p = tmpMeta9;
_cp = tmpMeta10;
tmpMeta11 = mmc_mk_box3(4, &DAE_Prefix_PREFIX__desc, _p, _cp);
tmpMeta1 = omc_PrefixUtil_prefixLast(threadData, tmpMeta11);
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
_outPrefix = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outPrefix;
}
DLLExport
modelica_metatype omc_PrefixUtil_prefixFirstCref(threadData_t *threadData, modelica_metatype _inPrefix)
{
modelica_metatype _outCref = NULL;
modelica_string _name = NULL;
modelica_metatype _subs = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inPrefix;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,1,2) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta2,0,6) == 0) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 2));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 4));
_name = tmpMeta3;
_subs = tmpMeta4;
tmpMeta5 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _name, _OMC_LIT21, _subs);
_outCref = tmpMeta5;
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_metatype omc_PrefixUtil_prefixFirst(threadData_t *threadData, modelica_metatype _inPrefix)
{
modelica_metatype _outPrefix = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPrefix;
{
modelica_string _a = NULL;
modelica_metatype _b = NULL;
modelica_metatype _cp = NULL;
modelica_metatype _ci_state = NULL;
modelica_metatype _pdims = NULL;
modelica_metatype _info = NULL;
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
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,6) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 6));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 7));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_a = tmpMeta7;
_pdims = tmpMeta8;
_b = tmpMeta9;
_ci_state = tmpMeta10;
_info = tmpMeta11;
_cp = tmpMeta12;
tmpMeta13 = mmc_mk_box7(3, &DAE_ComponentPrefix_PRE__desc, _a, _pdims, _b, _OMC_LIT0, _ci_state, _info);
tmpMeta14 = mmc_mk_box3(4, &DAE_Prefix_PREFIX__desc, tmpMeta13, _cp);
tmpMeta1 = tmpMeta14;
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
_outPrefix = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outPrefix;
}
DLLExport
modelica_metatype omc_PrefixUtil_prefixAdd(threadData_t *threadData, modelica_string _inIdent, modelica_metatype _inType, modelica_metatype _inIntegerLst, modelica_metatype _inPrefix, modelica_metatype _vt, modelica_metatype _ci_state, modelica_metatype _inInfo)
{
modelica_metatype _outPrefix = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_string tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inIdent;
tmp4_2 = _inIntegerLst;
tmp4_3 = _inPrefix;
{
modelica_string _i = NULL;
modelica_metatype _s = NULL;
modelica_metatype _p = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
_p = tmpMeta6;
_i = tmp4_1;
_s = tmp4_2;
tmpMeta7 = mmc_mk_box7(3, &DAE_ComponentPrefix_PRE__desc, _i, _inType, _s, _p, _ci_state, _inInfo);
tmpMeta8 = mmc_mk_box2(3, &DAE_ClassPrefix_CLASSPRE__desc, _vt);
tmpMeta9 = mmc_mk_box3(4, &DAE_Prefix_PREFIX__desc, tmpMeta7, tmpMeta8);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,0) == 0) goto tmp3_end;
_i = tmp4_1;
_s = tmp4_2;
tmpMeta10 = mmc_mk_box7(3, &DAE_ComponentPrefix_PRE__desc, _i, _inType, _s, _OMC_LIT0, _ci_state, _inInfo);
tmpMeta11 = mmc_mk_box2(3, &DAE_ClassPrefix_CLASSPRE__desc, _vt);
tmpMeta12 = mmc_mk_box3(4, &DAE_Prefix_PREFIX__desc, tmpMeta10, tmpMeta11);
tmpMeta1 = tmpMeta12;
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
_outPrefix = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outPrefix;
}
DLLExport
void omc_PrefixUtil_printPrefix(threadData_t *threadData, modelica_metatype _p)
{
modelica_string _s = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_s = omc_PrefixUtil_printPrefixStr(threadData, _p);
omc_Print_printBuf(threadData, _s);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_string omc_PrefixUtil_printPrefixStrIgnoreNoPre(threadData_t *threadData, modelica_metatype _inPrefix)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPrefix;
{
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT6;
goto tmp3_done;
}
case 2: {
_p = tmp4_1;
tmp1 = omc_PrefixUtil_printPrefixStr(threadData, _p);
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
modelica_string omc_PrefixUtil_printPrefixStr3(threadData_t *threadData, modelica_metatype _inPrefix)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPrefix;
{
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT26;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT26;
goto tmp3_done;
}
case 2: {
_p = tmp4_1;
tmp1 = omc_PrefixUtil_printPrefixStr(threadData, _p);
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
modelica_string omc_PrefixUtil_printPrefixStr2(threadData_t *threadData, modelica_metatype _inPrefix)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPrefix;
{
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT6;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta7;
_p = tmp4_1;
tmpMeta7 = stringAppend(omc_PrefixUtil_printPrefixStr(threadData, _p),_OMC_LIT25);
tmp1 = tmpMeta7;
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
modelica_string omc_PrefixUtil_printPrefixStr(threadData_t *threadData, modelica_metatype _inPrefix)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inPrefix;
{
modelica_string _str = NULL;
modelica_string _s = NULL;
modelica_string _rest_1 = NULL;
modelica_string _s_1 = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _cp = NULL;
modelica_metatype _ss = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmp4 += 5;
tmp1 = _OMC_LIT27;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,0) == 0) goto tmp3_end;
tmp4 += 4;
tmp1 = _OMC_LIT28;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,6) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
if (!listEmpty(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,1,0) == 0) goto tmp3_end;
_str = tmpMeta8;
tmp1 = _str;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,0,6) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 4));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,1,0) == 0) goto tmp3_end;
_str = tmpMeta12;
_ss = tmpMeta13;
tmpMeta15 = stringAppend(_OMC_LIT29,stringDelimitList(omc_List_map(threadData, _ss, boxvar_ExpressionDump_subscriptString), _OMC_LIT30));
tmpMeta16 = stringAppend(tmpMeta15,_OMC_LIT31);
tmpMeta17 = stringAppend(_str,tmpMeta16);
tmp1 = tmpMeta17;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,0,6) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 4));
if (!listEmpty(tmpMeta20)) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 5));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_str = tmpMeta19;
_rest = tmpMeta21;
_cp = tmpMeta22;
tmpMeta23 = mmc_mk_box3(4, &DAE_Prefix_PREFIX__desc, _rest, _cp);
_rest_1 = omc_PrefixUtil_printPrefixStr(threadData, tmpMeta23);
tmpMeta24 = stringAppend(_rest_1,_OMC_LIT25);
_s = tmpMeta24;
tmpMeta25 = stringAppend(_s,_str);
tmp1 = tmpMeta25;
goto tmp3_done;
}
case 5: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,0,6) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 2));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 4));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 5));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_str = tmpMeta27;
_ss = tmpMeta28;
_rest = tmpMeta29;
_cp = tmpMeta30;
tmpMeta31 = mmc_mk_box3(4, &DAE_Prefix_PREFIX__desc, _rest, _cp);
_rest_1 = omc_PrefixUtil_printPrefixStr(threadData, tmpMeta31);
tmpMeta32 = stringAppend(_rest_1,_OMC_LIT25);
_s = tmpMeta32;
tmpMeta33 = stringAppend(_s,_str);
_s_1 = tmpMeta33;
tmpMeta34 = stringAppend(_OMC_LIT29,stringDelimitList(omc_List_map(threadData, _ss, boxvar_ExpressionDump_subscriptString), _OMC_LIT30));
tmpMeta35 = stringAppend(tmpMeta34,_OMC_LIT31);
tmpMeta36 = stringAppend(_s_1,tmpMeta35);
tmp1 = tmpMeta36;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_PrefixUtil_printComponentPrefixStr(threadData_t *threadData, modelica_metatype _pre)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _pre;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT32;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,0) == 0) goto tmp3_end;
tmp1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pre), 2)));
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,0) == 0) goto tmp3_end;
tmpMeta9 = stringAppend((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pre), 2))),_OMC_LIT29);
tmpMeta10 = stringAppend(tmpMeta9,omc_ExpressionDump_printSubscriptLstStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pre), 4)))));
tmpMeta11 = stringAppend(tmpMeta10,_OMC_LIT31);
tmp1 = tmpMeta11;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta12)) goto tmp3_end;
tmpMeta13 = stringAppend(omc_PrefixUtil_printComponentPrefixStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pre), 5)))),_OMC_LIT25);
tmpMeta14 = stringAppend(tmpMeta13,(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pre), 2))));
tmp1 = tmpMeta14;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta15 = stringAppend(omc_PrefixUtil_printComponentPrefixStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pre), 5)))),_OMC_LIT25);
tmpMeta16 = stringAppend(tmpMeta15,(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pre), 2))));
tmpMeta17 = stringAppend(tmpMeta16,_OMC_LIT29);
tmpMeta18 = stringAppend(tmpMeta17,omc_ExpressionDump_printSubscriptLstStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pre), 4)))));
tmpMeta19 = stringAppend(tmpMeta18,_OMC_LIT31);
tmp1 = tmpMeta19;
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
