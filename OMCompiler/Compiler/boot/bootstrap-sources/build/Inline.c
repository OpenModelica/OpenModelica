#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "Inline.c"
#endif
#include "omc_simulation_settings.h"
#include "Inline.h"
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT0,1,7) {&DAE_InlineType_NO__INLINE__desc,}};
#define _OMC_LIT0 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,1,3) {&DAE_TailCall_NO__TAIL__desc,}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT2,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT2 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "Internal error %s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,17,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT4}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(63)),_OMC_LIT2,_OMC_LIT3,_OMC_LIT5}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "Inline.inlineEquationExp failed"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,31,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT8,2,1) {_OMC_LIT7,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT8 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,1,5) {&AvlSetPath_Tree_EMPTY__desc,}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "No inline"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,9,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "Inline after index reduction"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,28,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "Inline as soon as possible"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,26,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "Inline as soon as possible, even if inlining is globally disabled"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,65,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data "Inline before index reduction"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,29,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data "Inline if necessary"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,19,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT16,1,7) {&DAE_ComponentRef_WILD__desc,}};
#define _OMC_LIT16 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data "Inline.getExpFromArgMap failed with empty argmap and cref: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,59,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
#define _OMC_LIT18_data "failtrace"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT18,9,_OMC_LIT18_data);
#define _OMC_LIT18 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT18)
#define _OMC_LIT19_data "Sets whether to print a failtrace or not."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT19,41,_OMC_LIT19_data);
#define _OMC_LIT19 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT19)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT20,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT19}};
#define _OMC_LIT20 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT20)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT21,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT18,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT20}};
#define _OMC_LIT21 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "Inline.getRhsExp failed - cannot inline such a function\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,56,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
#define _OMC_LIT23_data "Inline.getFunctionBody failed for function: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT23,44,_OMC_LIT23_data);
#define _OMC_LIT23 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT23)
#define _OMC_LIT24_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT24,1,_OMC_LIT24_data);
#define _OMC_LIT24 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT24)
#define _OMC_LIT25_data "Inline.extendCrefRecords2 failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT25,33,_OMC_LIT25_data);
#define _OMC_LIT25 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "Inline.extendCrefRecords1 failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,33,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data "Unknown element: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,17,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data "Inline.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,9,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT29_6,0.0);
#define _OMC_LIT29_6 MMC_REFREALLIT(_OMC_LIT_STRUCT29_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT29,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT28,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1144)),MMC_IMMEDIATE(MMC_TAGFIXNUM(9)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1144)),MMC_IMMEDIATE(MMC_TAGFIXNUM(99)),_OMC_LIT29_6}};
#define _OMC_LIT29 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT29)
#define _OMC_LIT30_data " -> "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT30,4,_OMC_LIT30_data);
#define _OMC_LIT30 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,1,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
#define _OMC_LIT32_data "GenerateEvents"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT32,14,_OMC_LIT32_data);
#define _OMC_LIT32 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT32)
#define _OMC_LIT33_data "inlineFunctions"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT33,15,_OMC_LIT33_data);
#define _OMC_LIT33 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT33)
#define _OMC_LIT34_data "Controls if function inlining should be performed."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT34,50,_OMC_LIT34_data);
#define _OMC_LIT34 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT34)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT35,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT34}};
#define _OMC_LIT35 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT35)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT36,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(88)),_OMC_LIT33,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT35}};
#define _OMC_LIT36 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT36)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT37,1,4) {&DAE_InlineType_BUILTIN__EARLY__INLINE__desc,}};
#define _OMC_LIT37 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT37)
#define _OMC_LIT38_data "infoXmlOperations"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT38,17,_OMC_LIT38_data);
#define _OMC_LIT38 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT38)
#define _OMC_LIT39_data "Enables output of the operations in the _info.xml file when translating models."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT39,79,_OMC_LIT39_data);
#define _OMC_LIT39 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT39)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT40,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT39}};
#define _OMC_LIT40 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT40)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT41,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(94)),_OMC_LIT38,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT40}};
#define _OMC_LIT41 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT41)
#define _OMC_LIT42_data "Inline.inlineAlgorithm failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT42,30,_OMC_LIT42_data);
#define _OMC_LIT42 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT42)
#include "util/modelica.h"
#include "Inline_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_getInlineHashTableVarTransform(threadData_t *threadData, modelica_metatype *out_repl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_getInlineHashTableVarTransform,2,0) {(void*) boxptr_Inline_getInlineHashTableVarTransform,0}};
#define boxvar_Inline_getInlineHashTableVarTransform MMC_REFSTRUCTLIT(boxvar_lit_Inline_getInlineHashTableVarTransform)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_getReplacementCheckComplex(threadData_t *threadData, modelica_metatype _repl, modelica_metatype _cr, modelica_metatype _ty);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_getReplacementCheckComplex,2,0) {(void*) boxptr_Inline_getReplacementCheckComplex,0}};
#define boxvar_Inline_getReplacementCheckComplex MMC_REFSTRUCTLIT(boxvar_lit_Inline_getReplacementCheckComplex)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_Inline_removeWilds(threadData_t *threadData, modelica_metatype _inComponentRef);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Inline_removeWilds(threadData_t *threadData, modelica_metatype _inComponentRef);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_removeWilds,2,0) {(void*) boxptr_Inline_removeWilds,0}};
#define boxvar_Inline_removeWilds MMC_REFSTRUCTLIT(boxvar_lit_Inline_removeWilds)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_getInputCrefs(threadData_t *threadData, modelica_metatype _inElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_getInputCrefs,2,0) {(void*) boxptr_Inline_getInputCrefs,0}};
#define boxvar_Inline_getInputCrefs MMC_REFSTRUCTLIT(boxvar_lit_Inline_getInputCrefs)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_getExpFromArgMap(threadData_t *threadData, modelica_metatype _inArgMap, modelica_metatype _inComponentRef);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_getExpFromArgMap,2,0) {(void*) boxptr_Inline_getExpFromArgMap,0}};
#define boxvar_Inline_getExpFromArgMap MMC_REFSTRUCTLIT(boxvar_lit_Inline_getExpFromArgMap)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_functionReferenceType(threadData_t *threadData, modelica_metatype _ty1, modelica_metatype *out_inlineType);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_functionReferenceType,2,0) {(void*) boxptr_Inline_functionReferenceType,0}};
#define boxvar_Inline_functionReferenceType MMC_REFSTRUCTLIT(boxvar_lit_Inline_functionReferenceType)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_boxIfUnboxedFunRef(threadData_t *threadData, modelica_metatype _iexp, modelica_metatype _ty);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_boxIfUnboxedFunRef,2,0) {(void*) boxptr_Inline_boxIfUnboxedFunRef,0}};
#define boxvar_Inline_boxIfUnboxedFunRef MMC_REFSTRUCTLIT(boxvar_lit_Inline_boxIfUnboxedFunRef)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_getRhsExp(threadData_t *threadData, modelica_metatype _inElementList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_getRhsExp,2,0) {(void*) boxptr_Inline_getRhsExp,0}};
#define boxvar_Inline_getRhsExp MMC_REFSTRUCTLIT(boxvar_lit_Inline_getRhsExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_extendCrefRecords2(threadData_t *threadData, modelica_metatype _ev, modelica_metatype _c);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_extendCrefRecords2,2,0) {(void*) boxptr_Inline_extendCrefRecords2,0}};
#define boxvar_Inline_extendCrefRecords2 MMC_REFSTRUCTLIT(boxvar_lit_Inline_extendCrefRecords2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_extendCrefRecords1(threadData_t *threadData, modelica_metatype _ev, modelica_metatype _c, modelica_metatype _e);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_extendCrefRecords1,2,0) {(void*) boxptr_Inline_extendCrefRecords1,0}};
#define boxvar_Inline_extendCrefRecords1 MMC_REFSTRUCTLIT(boxvar_lit_Inline_extendCrefRecords1)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_getCheckCref(threadData_t *threadData, modelica_metatype _inCrefs, modelica_metatype _inCheckCr);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_getCheckCref,2,0) {(void*) boxptr_Inline_getCheckCref,0}};
#define boxvar_Inline_getCheckCref MMC_REFSTRUCTLIT(boxvar_lit_Inline_getCheckCref)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_addReplacement(threadData_t *threadData, modelica_metatype _iCr, modelica_metatype _iExp, modelica_metatype _iRepl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_addReplacement,2,0) {(void*) boxptr_Inline_addReplacement,0}};
#define boxvar_Inline_addReplacement MMC_REFSTRUCTLIT(boxvar_lit_Inline_addReplacement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_addOptBindingReplacements(threadData_t *threadData, modelica_metatype _cr, modelica_metatype _binding, modelica_metatype _iRepl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_addOptBindingReplacements,2,0) {(void*) boxptr_Inline_addOptBindingReplacements,0}};
#define boxvar_Inline_addOptBindingReplacements MMC_REFSTRUCTLIT(boxvar_lit_Inline_addOptBindingReplacements)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_makeComplexBinding(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fbinding, modelica_metatype _ty);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_makeComplexBinding,2,0) {(void*) boxptr_Inline_makeComplexBinding,0}};
#define boxvar_Inline_makeComplexBinding MMC_REFSTRUCTLIT(boxvar_lit_Inline_makeComplexBinding)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_getFunctionInputsOutputBody(threadData_t *threadData, modelica_metatype _fn, modelica_metatype _iRepl, modelica_metatype *out_oOutputs, modelica_metatype *out_oBody, modelica_metatype *out_oRepl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_getFunctionInputsOutputBody,2,0) {(void*) boxptr_Inline_getFunctionInputsOutputBody,0}};
#define boxvar_Inline_getFunctionInputsOutputBody MMC_REFSTRUCTLIT(boxvar_lit_Inline_getFunctionInputsOutputBody)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_addTplAssignToRepl(threadData_t *threadData, modelica_metatype _explst, modelica_integer _indx, modelica_metatype _iExp, modelica_metatype _iRepl);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Inline_addTplAssignToRepl(threadData_t *threadData, modelica_metatype _explst, modelica_metatype _indx, modelica_metatype _iExp, modelica_metatype _iRepl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_addTplAssignToRepl,2,0) {(void*) boxptr_Inline_addTplAssignToRepl,0}};
#define boxvar_Inline_addTplAssignToRepl MMC_REFSTRUCTLIT(boxvar_lit_Inline_addTplAssignToRepl)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_mergeFunctionBody(threadData_t *threadData, modelica_metatype _iStmts, modelica_metatype _iRepl, modelica_metatype _assertStmtsIn, modelica_metatype *out_assertStmtsOut);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_mergeFunctionBody,2,0) {(void*) boxptr_Inline_mergeFunctionBody,0}};
#define boxvar_Inline_mergeFunctionBody MMC_REFSTRUCTLIT(boxvar_lit_Inline_mergeFunctionBody)
PROTECTED_FUNCTION_STATIC void omc_Inline_dumpArgmap(threadData_t *threadData, modelica_metatype _inTpl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_dumpArgmap,2,0) {(void*) boxptr_Inline_dumpArgmap,0}};
#define boxvar_Inline_dumpArgmap MMC_REFSTRUCTLIT(boxvar_lit_Inline_dumpArgmap)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_inlineAssert(threadData_t *threadData, modelica_metatype _assrtIn, modelica_metatype _fns, modelica_metatype _argmap, modelica_metatype _checkcr);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_inlineAssert,2,0) {(void*) boxptr_Inline_inlineAssert,0}};
#define boxvar_Inline_inlineAssert MMC_REFSTRUCTLIT(boxvar_lit_Inline_inlineAssert)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_inlineExpsWork(threadData_t *threadData, modelica_metatype _inExps, modelica_metatype _fns, modelica_metatype _inSource, modelica_metatype _iAcc, modelica_boolean _iInlined, modelica_metatype *out_outSource, modelica_boolean *out_oInlined);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Inline_inlineExpsWork(threadData_t *threadData, modelica_metatype _inExps, modelica_metatype _fns, modelica_metatype _inSource, modelica_metatype _iAcc, modelica_metatype _iInlined, modelica_metatype *out_outSource, modelica_metatype *out_oInlined);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_inlineExpsWork,2,0) {(void*) boxptr_Inline_inlineExpsWork,0}};
#define boxvar_Inline_inlineExpsWork MMC_REFSTRUCTLIT(boxvar_lit_Inline_inlineExpsWork)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_inlineElse(threadData_t *threadData, modelica_metatype _inElse, modelica_metatype _inElementList, modelica_metatype _inSource, modelica_metatype *out_outSource, modelica_boolean *out_inlined);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Inline_inlineElse(threadData_t *threadData, modelica_metatype _inElse, modelica_metatype _inElementList, modelica_metatype _inSource, modelica_metatype *out_outSource, modelica_metatype *out_inlined);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_inlineElse,2,0) {(void*) boxptr_Inline_inlineElse,0}};
#define boxvar_Inline_inlineElse MMC_REFSTRUCTLIT(boxvar_lit_Inline_inlineElse)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_inlineStatement(threadData_t *threadData, modelica_metatype _inStatement, modelica_metatype _inElementList, modelica_boolean *out_inlined);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Inline_inlineStatement(threadData_t *threadData, modelica_metatype _inStatement, modelica_metatype _inElementList, modelica_metatype *out_inlined);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_inlineStatement,2,0) {(void*) boxptr_Inline_inlineStatement,0}};
#define boxvar_Inline_inlineStatement MMC_REFSTRUCTLIT(boxvar_lit_Inline_inlineStatement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_inlineDAEElement(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inFunctions, modelica_boolean *out_inlined);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Inline_inlineDAEElement(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inFunctions, modelica_metatype *out_inlined);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_inlineDAEElement,2,0) {(void*) boxptr_Inline_inlineDAEElement,0}};
#define boxvar_Inline_inlineDAEElement MMC_REFSTRUCTLIT(boxvar_lit_Inline_inlineDAEElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_inlineDAEElements(threadData_t *threadData, modelica_metatype _inElementList, modelica_metatype _inFunctions, modelica_metatype _iAcc, modelica_boolean _iInlined, modelica_boolean *out_OInlined);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Inline_inlineDAEElements(threadData_t *threadData, modelica_metatype _inElementList, modelica_metatype _inFunctions, modelica_metatype _iAcc, modelica_metatype _iInlined, modelica_metatype *out_OInlined);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_inlineDAEElements,2,0) {(void*) boxptr_Inline_inlineDAEElements,0}};
#define boxvar_Inline_inlineDAEElements MMC_REFSTRUCTLIT(boxvar_lit_Inline_inlineDAEElements)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_inlineDAEElementsLst(threadData_t *threadData, modelica_metatype _inElementList, modelica_metatype _inFunctions, modelica_metatype _iAcc, modelica_boolean _iInlined, modelica_boolean *out_OInlined);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Inline_inlineDAEElementsLst(threadData_t *threadData, modelica_metatype _inElementList, modelica_metatype _inFunctions, modelica_metatype _iAcc, modelica_metatype _iInlined, modelica_metatype *out_OInlined);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Inline_inlineDAEElementsLst,2,0) {(void*) boxptr_Inline_inlineDAEElementsLst,0}};
#define boxvar_Inline_inlineDAEElementsLst MMC_REFSTRUCTLIT(boxvar_lit_Inline_inlineDAEElementsLst)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_getInlineHashTableVarTransform(threadData_t *threadData, modelica_metatype *out_repl)
{
modelica_metatype _ht = NULL;
modelica_metatype _repl = NULL;
modelica_metatype _opt = NULL;
modelica_metatype _regRepl = NULL;
modelica_metatype _invRepl = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_opt = getGlobalRoot(((modelica_integer) 22));
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
_ht = tmpMeta7;
_repl = tmpMeta8;
_regRepl = tmpMeta9;
_invRepl = tmpMeta10;
omc_BaseHashTable_clearAssumeNoDelete(threadData, _ht);
omc_BaseHashTable_clearAssumeNoDelete(threadData, _regRepl);
omc_BaseHashTable_clearAssumeNoDelete(threadData, _invRepl);
tmpMeta[0+0] = _ht;
tmpMeta[0+1] = _repl;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
_ht = omc_HashTableCG_emptyHashTable(threadData);
_repl = omc_VarTransform_emptyReplacements(threadData);
tmpMeta11 = mmc_mk_box2(0, _ht, _repl);
setGlobalRoot(((modelica_integer) 22), mmc_mk_some(tmpMeta11));
tmpMeta[0+0] = _ht;
tmpMeta[0+1] = _repl;
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
_ht = tmpMeta[0+0];
_repl = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_repl) { *out_repl = _repl; }
return _ht;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_getReplacementCheckComplex(threadData_t *threadData, modelica_metatype _repl, modelica_metatype _cr, modelica_metatype _ty)
{
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _ty;
{
modelica_metatype _vars = NULL;
modelica_metatype _crs = NULL;
modelica_metatype _exps = NULL;
modelica_metatype _path = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta1 = omc_VarTransform_getReplacement(threadData, _repl, _cr);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_path = tmpMeta7;
_vars = tmpMeta8;
_crs = omc_List_map1(threadData, omc_List_map(threadData, _vars, boxvar_Types_getVarName), boxvar_ComponentReference_appendStringCref, _cr);
_exps = omc_List_map1r(threadData, _crs, boxvar_VarTransform_getReplacement, _repl);
tmpMeta9 = mmc_mk_box8(3, &DAE_CallAttributes_CALL__ATTR__desc, _ty, mmc_mk_boolean(0), mmc_mk_boolean(0), mmc_mk_boolean(0), mmc_mk_boolean(0), _OMC_LIT0, _OMC_LIT1);
tmpMeta10 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _path, _exps, tmpMeta9);
tmpMeta1 = tmpMeta10;
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
_exp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _exp;
}
DLLExport
modelica_metatype omc_Inline_inlineEquationExp(threadData_t *threadData, modelica_metatype _inExp, modelica_fnptr _fn, modelica_metatype _inSource, modelica_metatype *out_source)
{
modelica_metatype _outExp = NULL;
modelica_metatype _source = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_boolean _changed;
modelica_metatype _e = NULL;
modelica_metatype _e_1 = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e1_1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e2_1 = NULL;
modelica_metatype _eq2 = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_e = tmpMeta5;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
_e_1 = omc_Expression_traverseExpBottomUp(threadData, _e, ((modelica_fnptr) _fn), tmpMeta6, NULL);
_changed = (!referenceEq(_e, _e_1));
tmpMeta7 = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _e_1);
_eq2 = tmpMeta7;
tmpMeta8 = mmc_mk_box3(6, &DAE_SymbolicOperation_OP__INLINE__desc, _inExp, _eq2);
_source = omc_ElementSource_condAddSymbolicTransformation(threadData, _changed, _inSource, tmpMeta8);
tmpMeta[0+0] = omc_ExpressionSimplify_condSimplifyAddSymbolicOperation(threadData, _changed, _eq2, _source, &tmpMeta[0+1]);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_e = tmpMeta9;
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
_e_1 = omc_Expression_traverseExpBottomUp(threadData, _e, ((modelica_fnptr) _fn), tmpMeta10, NULL);
_changed = (!referenceEq(_e, _e_1));
tmpMeta11 = mmc_mk_box2(4, &DAE_EquationExp_RESIDUAL__EXP__desc, _e_1);
_eq2 = tmpMeta11;
tmpMeta12 = mmc_mk_box3(6, &DAE_SymbolicOperation_OP__INLINE__desc, _inExp, _eq2);
_source = omc_ElementSource_condAddSymbolicTransformation(threadData, _changed, _inSource, tmpMeta12);
tmpMeta[0+0] = omc_ExpressionSimplify_condSimplifyAddSymbolicOperation(threadData, _changed, _eq2, _source, &tmpMeta[0+1]);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e1 = tmpMeta13;
_e2 = tmpMeta14;
tmpMeta15 = MMC_REFSTRUCTLIT(mmc_nil);
_e1_1 = omc_Expression_traverseExpBottomUp(threadData, _e1, ((modelica_fnptr) _fn), tmpMeta15, NULL);
tmpMeta16 = MMC_REFSTRUCTLIT(mmc_nil);
_e2_1 = omc_Expression_traverseExpBottomUp(threadData, _e2, ((modelica_fnptr) _fn), tmpMeta16, NULL);
_changed = (!(referenceEq(_e1, _e1_1) && referenceEq(_e2, _e2_1)));
tmpMeta17 = mmc_mk_box3(5, &DAE_EquationExp_EQUALITY__EXPS__desc, _e1_1, _e2_1);
_eq2 = tmpMeta17;
tmpMeta18 = mmc_mk_box3(6, &DAE_SymbolicOperation_OP__INLINE__desc, _inExp, _eq2);
_source = omc_ElementSource_condAddSymbolicTransformation(threadData, _changed, _inSource, tmpMeta18);
tmpMeta[0+0] = omc_ExpressionSimplify_condSimplifyAddSymbolicOperation(threadData, _changed, _eq2, _source, &tmpMeta[0+1]);
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
omc_Error_addMessage(threadData, _OMC_LIT6, _OMC_LIT8);
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
_outExp = tmpMeta[0+0];
_source = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_source) { *out_source = _source; }
return _outExp;
}
static modelica_metatype closure0_Inline_forceInlineCall(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_exp, modelica_metatype $in_assrtLst, modelica_metatype tmp1)
{
modelica_metatype fns = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype visitedPaths = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_Inline_forceInlineCall(thData, $in_exp, $in_assrtLst, fns, visitedPaths, tmp1);
}
DLLExport
modelica_metatype omc_Inline_simplifyAndForceInlineEquationExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _fns, modelica_metatype _inSource, modelica_metatype *out_source)
{
modelica_metatype _exp = NULL;
modelica_metatype _source = NULL;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_exp = omc_ExpressionSimplify_simplifyAddSymbolicOperation(threadData, _inExp, _inSource ,&_source);
tmpMeta2 = mmc_mk_box2(0, _fns, _OMC_LIT9);
_exp = omc_Inline_inlineEquationExp(threadData, _exp, (modelica_fnptr) mmc_mk_box2(0,closure0_Inline_forceInlineCall,tmpMeta2), _source ,&_source);
_return: OMC_LABEL_UNUSED
if (out_source) { *out_source = _source; }
return _exp;
}
static modelica_metatype closure1_Inline_inlineCall(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_exp, modelica_metatype $in_assrtLst, modelica_metatype tmp1)
{
modelica_metatype fns = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_Inline_inlineCall(thData, $in_exp, $in_assrtLst, fns, tmp1);
}
DLLExport
modelica_metatype omc_Inline_simplifyAndInlineEquationExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _fns, modelica_metatype _inSource, modelica_metatype *out_source)
{
modelica_metatype _exp = NULL;
modelica_metatype _source = NULL;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_exp = omc_ExpressionSimplify_simplifyAddSymbolicOperation(threadData, _inExp, _inSource ,&_source);
tmpMeta2 = mmc_mk_box1(0, _fns);
_exp = omc_Inline_inlineEquationExp(threadData, _exp, (modelica_fnptr) mmc_mk_box2(0,closure1_Inline_inlineCall,tmpMeta2), _source ,&_source);
_return: OMC_LABEL_UNUSED
if (out_source) { *out_source = _source; }
return _exp;
}
DLLExport
modelica_string omc_Inline_printInlineTypeStr(threadData_t *threadData, modelica_metatype _it)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _it;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 7: {
tmp1 = _OMC_LIT10;
goto tmp3_done;
}
case 8: {
tmp1 = _OMC_LIT11;
goto tmp3_done;
}
case 5: {
tmp1 = _OMC_LIT12;
goto tmp3_done;
}
case 4: {
tmp1 = _OMC_LIT13;
goto tmp3_done;
}
case 3: {
tmp1 = _OMC_LIT14;
goto tmp3_done;
}
case 6: {
tmp1 = _OMC_LIT15;
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
PROTECTED_FUNCTION_STATIC modelica_boolean omc_Inline_removeWilds(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
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
_outBoolean = tmp1;
_return: OMC_LABEL_UNUSED
return _outBoolean;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Inline_removeWilds(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_Inline_removeWilds(threadData, _inComponentRef);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_getInputCrefs(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
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
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,0) == 0) goto tmp3_end;
_cref = tmpMeta6;
tmpMeta1 = _cref;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _OMC_LIT16;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_getExpFromArgMap(threadData_t *threadData, modelica_metatype _inArgMap, modelica_metatype _inComponentRef)
{
jmp_buf *old_mmc_jumper = threadData->mmc_jumper;
modelica_metatype _outExp = NULL;
modelica_metatype _arg = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _key = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_subs = omc_ComponentReference_crefSubs(threadData, _inComponentRef);
_key = omc_ComponentReference_crefStripSubs(threadData, _inComponentRef);
{
modelica_metatype _arg;
for (tmpMeta1 = _inArgMap; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_arg = MMC_CAR(tmpMeta1);
tmpMeta2 = _arg;
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 1));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 2));
_cref = tmpMeta3;
_exp = tmpMeta4;
if(omc_ComponentReference_crefEqual(threadData, _cref, _key))
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
_outExp = omc_Expression_applyExpSubscripts(threadData, _exp, _subs);
goto tmp6_done;
}
case 1: {
continue;
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
goto _return;
}
}
}
if(omc_Flags_isSet(threadData, _OMC_LIT21))
{
tmpMeta10 = stringAppend(_OMC_LIT17,omc_ComponentReference_printComponentRefStr(threadData, _inComponentRef));
omc_Debug_traceln(threadData, tmpMeta10);
}
MMC_THROW_INTERNAL();
_return: OMC_LABEL_UNUSED
threadData->mmc_jumper = old_mmc_jumper;
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_functionReferenceType(threadData_t *threadData, modelica_metatype _ty1, modelica_metatype *out_inlineType)
{
modelica_metatype _ty2 = NULL;
modelica_metatype _inlineType = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _ty1;
{
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,11,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
_ty = tmpMeta7;
_inlineType = tmpMeta9;
tmpMeta[0+0] = omc_Types_simplifyType(threadData, _ty);
tmpMeta[0+1] = _inlineType;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _ty1;
tmpMeta[0+1] = _OMC_LIT0;
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
_ty2 = tmpMeta[0+0];
_inlineType = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_inlineType) { *out_inlineType = _inlineType; }
return _ty2;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_boxIfUnboxedFunRef(threadData_t *threadData, modelica_metatype _iexp, modelica_metatype _ty)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _iexp;
tmp4_2 = _ty;
{
modelica_metatype _t = NULL;
modelica_metatype _exp = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_boolean tmp9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,11,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
_t = tmpMeta7;
_exp = tmp4_1;
tmp9 = (modelica_boolean)omc_Types_isBoxedType(threadData, _t);
if(tmp9)
{
tmpMeta10 = _exp;
}
else
{
tmpMeta8 = mmc_mk_box2(37, &DAE_Exp_BOX__desc, _exp);
tmpMeta10 = tmpMeta8;
}
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _iexp;
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
modelica_metatype omc_Inline_replaceArgs(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTuple, modelica_metatype *out_outTuple)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outTuple = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _inTuple;
{
modelica_metatype _cref = NULL;
modelica_metatype _firstCref = NULL;
modelica_metatype _argmap = NULL;
modelica_metatype _e = NULL;
modelica_metatype _path = NULL;
modelica_metatype _expLst = NULL;
modelica_boolean _tuple_;
modelica_boolean _b;
modelica_boolean _isImpure;
modelica_boolean _isFunctionPointerCall;
modelica_metatype _ty = NULL;
modelica_metatype _ty2 = NULL;
modelica_metatype _inlineType = NULL;
modelica_metatype _tc = NULL;
modelica_metatype _checkcr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 9; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_integer tmp8;
modelica_metatype tmpMeta9;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp8 = mmc_unbox_integer(tmpMeta7);
if (1 != tmp8) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_argmap = tmpMeta6;
_cref = tmpMeta9;
_e = omc_Inline_getExpFromArgMap(threadData, _argmap, _cref);
_e = omc_ExpressionSimplify_simplify(threadData, _e, NULL);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _inTuple;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_integer tmp13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp13 = mmc_unbox_integer(tmpMeta12);
if (1 != tmp13) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_argmap = tmpMeta10;
_checkcr = tmpMeta11;
_cref = tmpMeta14;
if (!omc_BaseHashTable_hasKey(threadData, omc_ComponentReference_crefFirstCref(threadData, _cref), _checkcr)) goto tmp3_end;
tmpMeta15 = mmc_mk_box3(0, _argmap, _checkcr, mmc_mk_boolean(0));
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = tmpMeta15;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_integer tmp18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp18 = mmc_unbox_integer(tmpMeta17);
if (1 != tmp18) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_argmap = tmpMeta16;
_cref = tmpMeta19;
_firstCref = omc_ComponentReference_crefFirstCref(threadData, _cref);
tmpMeta20 = omc_ComponentReference_crefSubs(threadData, _firstCref);
if (!listEmpty(tmpMeta20)) goto goto_2;
_e = omc_Inline_getExpFromArgMap(threadData, _argmap, _firstCref);
while(1)
{
if(!(!omc_ComponentReference_crefIsIdent(threadData, _cref))) break;
_cref = omc_ComponentReference_crefRest(threadData, _cref);
tmpMeta21 = omc_ComponentReference_crefSubs(threadData, _cref);
if (!listEmpty(tmpMeta21)) goto goto_2;
tmpMeta22 = mmc_mk_box5(26, &DAE_Exp_RSUB__desc, _e, mmc_mk_integer(((modelica_integer) -1)), omc_ComponentReference_crefFirstIdent(threadData, _cref), omc_ComponentReference_crefType(threadData, _cref));
_e = tmpMeta22;
}
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _inTuple;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_integer tmp26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp26 = mmc_unbox_integer(tmpMeta25);
if (1 != tmp26) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_argmap = tmpMeta23;
_checkcr = tmpMeta24;
_cref = tmpMeta27;
tmp4 += 4;
omc_Inline_getExpFromArgMap(threadData, _argmap, omc_ComponentReference_crefStripSubs(threadData, omc_ComponentReference_crefFirstCref(threadData, _cref)));
tmpMeta28 = mmc_mk_box3(0, _argmap, _checkcr, mmc_mk_boolean(0));
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = tmpMeta28;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_integer tmp31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_integer tmp37;
modelica_metatype tmpMeta38;
modelica_integer tmp39;
modelica_metatype tmpMeta40;
modelica_integer tmp41;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp31 = mmc_unbox_integer(tmpMeta30);
if (1 != tmp31) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,35,2) == 0) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta32,13,3) == 0) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 2));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 3));
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 4));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta35), 3));
tmp37 = mmc_unbox_integer(tmpMeta36);
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta35), 4));
tmp39 = mmc_unbox_integer(tmpMeta38);
if (0 != tmp39) goto tmp3_end;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta35), 5));
tmp41 = mmc_unbox_integer(tmpMeta40);
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta35), 7));
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta35), 8));
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_argmap = tmpMeta29;
_path = tmpMeta33;
_expLst = tmpMeta34;
_tuple_ = tmp37;
_isImpure = tmp41;
_inlineType = tmpMeta42;
_tc = tmpMeta43;
_ty = tmpMeta44;
_cref = omc_ComponentReference_pathToCref(threadData, _path);
tmpMeta45 = omc_Inline_getExpFromArgMap(threadData, _argmap, _cref);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta45,6,2) == 0) goto goto_2;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 2));
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 3));
_e = tmpMeta45;
_cref = tmpMeta46;
_ty2 = tmpMeta47;
_path = omc_ComponentReference_crefToPath(threadData, _cref);
_expLst = omc_List_map(threadData, _expLst, boxvar_Expression_unboxExp);
_b = omc_Expression_isBuiltinFunctionReference(threadData, _e);
_isFunctionPointerCall = omc_Types_isFunctionReferenceVar(threadData, _ty2);
tmpMeta48 = mmc_mk_box8(3, &DAE_CallAttributes_CALL__ATTR__desc, _ty, mmc_mk_boolean(_tuple_), mmc_mk_boolean(_b), mmc_mk_boolean(_isImpure), mmc_mk_boolean(_isFunctionPointerCall), _inlineType, _tc);
tmpMeta49 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _path, _expLst, tmpMeta48);
_e = tmpMeta49;
_e = omc_ExpressionSimplify_simplify(threadData, _e, NULL);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _inTuple;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
modelica_integer tmp53;
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
modelica_metatype tmpMeta57;
modelica_integer tmp58;
modelica_boolean tmp59;
modelica_metatype tmpMeta60;
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp53 = mmc_unbox_integer(tmpMeta52);
if (1 != tmp53) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,35,2) == 0) goto tmp3_end;
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta54,13,3) == 0) goto tmp3_end;
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta54), 2));
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta54), 4));
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta56), 4));
tmp58 = mmc_unbox_integer(tmpMeta57);
if (0 != tmp58) goto tmp3_end;
_argmap = tmpMeta50;
_checkcr = tmpMeta51;
_e = tmp4_1;
_path = tmpMeta55;
tmp4 += 2;
_cref = omc_ComponentReference_pathToCref(threadData, _path);
tmp59 = omc_BaseHashTable_hasKey(threadData, _cref, _checkcr);
if (1 != tmp59) goto goto_2;
tmpMeta60 = mmc_mk_box3(0, _argmap, _checkcr, mmc_mk_boolean(0));
tmpMeta[0+0] = _e;
tmpMeta[0+1] = tmpMeta60;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta61;
modelica_metatype tmpMeta62;
modelica_integer tmp63;
modelica_metatype tmpMeta64;
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
modelica_metatype tmpMeta67;
modelica_metatype tmpMeta68;
modelica_integer tmp69;
modelica_metatype tmpMeta70;
modelica_integer tmp71;
modelica_metatype tmpMeta72;
modelica_integer tmp73;
modelica_metatype tmpMeta74;
modelica_metatype tmpMeta75;
modelica_metatype tmpMeta76;
modelica_metatype tmpMeta77;
modelica_metatype tmpMeta78;
modelica_metatype tmpMeta79;
tmpMeta61 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp63 = mmc_unbox_integer(tmpMeta62);
if (1 != tmp63) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta64 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta66 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta67 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta66), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta67,25,1) == 0) goto tmp3_end;
tmpMeta68 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta66), 3));
tmp69 = mmc_unbox_integer(tmpMeta68);
tmpMeta70 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta66), 4));
tmp71 = mmc_unbox_integer(tmpMeta70);
if (0 != tmp71) goto tmp3_end;
tmpMeta72 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta66), 5));
tmp73 = mmc_unbox_integer(tmpMeta72);
tmpMeta74 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta66), 8));
_argmap = tmpMeta61;
_path = tmpMeta64;
_expLst = tmpMeta65;
_tuple_ = tmp69;
_isImpure = tmp73;
_tc = tmpMeta74;
_cref = omc_ComponentReference_pathToCref(threadData, _path);
tmpMeta75 = omc_Inline_getExpFromArgMap(threadData, _argmap, _cref);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta75,6,2) == 0) goto goto_2;
tmpMeta76 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta75), 2));
tmpMeta77 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta75), 3));
_e = tmpMeta75;
_cref = tmpMeta76;
_ty = tmpMeta77;
_path = omc_ComponentReference_crefToPath(threadData, _cref);
_expLst = omc_List_map(threadData, _expLst, boxvar_Expression_unboxExp);
_b = omc_Expression_isBuiltinFunctionReference(threadData, _e);
_ty2 = omc_Inline_functionReferenceType(threadData, _ty ,&_inlineType);
_isFunctionPointerCall = omc_Types_isFunctionReferenceVar(threadData, _ty2);
tmpMeta78 = mmc_mk_box8(3, &DAE_CallAttributes_CALL__ATTR__desc, _ty2, mmc_mk_boolean(_tuple_), mmc_mk_boolean(_b), mmc_mk_boolean(_isImpure), mmc_mk_boolean(_isFunctionPointerCall), _inlineType, _tc);
tmpMeta79 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _path, _expLst, tmpMeta78);
_e = tmpMeta79;
_e = omc_Inline_boxIfUnboxedFunRef(threadData, _e, _ty);
_e = omc_ExpressionSimplify_simplify(threadData, _e, NULL);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _inTuple;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta80;
modelica_metatype tmpMeta81;
modelica_metatype tmpMeta82;
modelica_integer tmp83;
modelica_metatype tmpMeta84;
modelica_metatype tmpMeta85;
modelica_metatype tmpMeta86;
modelica_metatype tmpMeta87;
modelica_integer tmp88;
modelica_boolean tmp89;
modelica_metatype tmpMeta90;
tmpMeta80 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta81 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta82 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp83 = mmc_unbox_integer(tmpMeta82);
if (1 != tmp83) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta84 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta85 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta86 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta85), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta86,25,1) == 0) goto tmp3_end;
tmpMeta87 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta85), 4));
tmp88 = mmc_unbox_integer(tmpMeta87);
if (0 != tmp88) goto tmp3_end;
_argmap = tmpMeta80;
_checkcr = tmpMeta81;
_e = tmp4_1;
_path = tmpMeta84;
_cref = omc_ComponentReference_pathToCref(threadData, _path);
tmp89 = omc_BaseHashTable_hasKey(threadData, _cref, _checkcr);
if (1 != tmp89) goto goto_2;
tmpMeta90 = mmc_mk_box3(0, _argmap, _checkcr, mmc_mk_boolean(0));
tmpMeta[0+0] = _e;
tmpMeta[0+1] = tmpMeta90;
goto tmp3_done;
}
case 8: {
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inTuple;
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
if (++tmp4 < 9) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outExp = tmpMeta[0+0];
_outTuple = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outTuple) { *out_outTuple = _outTuple; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_getRhsExp(threadData_t *threadData, modelica_metatype _inElementList)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElementList;
{
modelica_metatype _cdr = NULL;
modelica_metatype _res = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp6 = omc_Flags_isSet(threadData, _OMC_LIT21);
if (1 != tmp6) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT22);
goto goto_2;
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,15,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (listEmpty(tmpMeta10)) goto tmp3_end;
tmpMeta11 = MMC_CAR(tmpMeta10);
tmpMeta12 = MMC_CDR(tmpMeta10);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,0,4) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 4));
if (!listEmpty(tmpMeta12)) goto tmp3_end;
_res = tmpMeta13;
tmpMeta1 = _res;
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta14 = MMC_CAR(tmp4_1);
tmpMeta15 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,15,2) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
if (listEmpty(tmpMeta17)) goto tmp3_end;
tmpMeta18 = MMC_CAR(tmpMeta17);
tmpMeta19 = MMC_CDR(tmpMeta17);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,1,4) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 4));
if (!listEmpty(tmpMeta19)) goto tmp3_end;
_res = tmpMeta20;
tmpMeta1 = _res;
goto tmp3_done;
}
case 3: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta21,15,2) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 2));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 2));
if (listEmpty(tmpMeta24)) goto tmp3_end;
tmpMeta25 = MMC_CAR(tmpMeta24);
tmpMeta26 = MMC_CDR(tmpMeta24);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta25,2,4) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 4));
if (!listEmpty(tmpMeta26)) goto tmp3_end;
_res = tmpMeta27;
tmpMeta1 = _res;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta28 = MMC_CAR(tmp4_1);
tmpMeta29 = MMC_CDR(tmp4_1);
_cdr = tmpMeta29;
_inElementList = _cdr;
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
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
DLLExport
modelica_metatype omc_Inline_getFunctionBody(threadData_t *threadData, modelica_metatype _p, modelica_metatype _fns, modelica_metatype *out_oComment)
{
modelica_metatype _outfn = NULL;
modelica_metatype _oComment = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _fns;
{
modelica_metatype _body = NULL;
modelica_metatype _ftree = NULL;
modelica_metatype _comment = NULL;
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
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (optionNone(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
_ftree = tmpMeta7;
tmpMeta8 = omc_DAE_AvlTreePathFunction_get(threadData, _ftree, _p);
if (optionNone(tmpMeta8)) goto goto_2;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,0,10) == 0) goto goto_2;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 3));
if (listEmpty(tmpMeta10)) goto goto_2;
tmpMeta11 = MMC_CAR(tmpMeta10);
tmpMeta12 = MMC_CDR(tmpMeta10);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,0,1) == 0) goto goto_2;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 11));
_body = tmpMeta13;
_comment = tmpMeta14;
tmpMeta[0+0] = _body;
tmpMeta[0+1] = _comment;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp15;
modelica_metatype tmpMeta16;
tmp15 = omc_Flags_isSet(threadData, _OMC_LIT21);
if (1 != tmp15) goto goto_2;
tmpMeta16 = stringAppend(_OMC_LIT23,omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT24, 1, 0));
omc_Debug_traceln(threadData, tmpMeta16);
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
_outfn = tmpMeta[0+0];
_oComment = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_oComment) { *out_oComment = _oComment; }
return _outfn;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_extendCrefRecords2(threadData_t *threadData, modelica_metatype _ev, modelica_metatype _c)
{
modelica_metatype _outArg = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _ev;
{
modelica_metatype _tp = NULL;
modelica_string _name = NULL;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_name = tmpMeta6;
_tp = tmpMeta7;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_ComponentReference_crefPrependIdent(threadData, _c, _name, tmpMeta8, _tp);
goto tmp3_done;
}
case 1: {
modelica_boolean tmp9;
tmp9 = omc_Flags_isSet(threadData, _OMC_LIT21);
if (1 != tmp9) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT25);
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
_outArg = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outArg;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_extendCrefRecords1(threadData_t *threadData, modelica_metatype _ev, modelica_metatype _c, modelica_metatype _e)
{
modelica_metatype _outArg = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _ev;
{
modelica_metatype _tp = NULL;
modelica_string _name = NULL;
modelica_metatype _c1 = NULL;
modelica_metatype _e1 = NULL;
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_name = tmpMeta6;
_tp = tmpMeta7;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
_c1 = omc_ComponentReference_crefPrependIdent(threadData, _c, _name, tmpMeta8, _tp);
tmpMeta9 = MMC_REFSTRUCTLIT(mmc_nil);
_e1 = omc_ComponentReference_crefPrependIdent(threadData, _e, _name, tmpMeta9, _tp);
_exp = omc_Expression_makeCrefExp(threadData, _e1, _tp);
tmpMeta10 = mmc_mk_box2(0, _c1, _exp);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp11;
tmp11 = omc_Flags_isSet(threadData, _OMC_LIT21);
if (1 != tmp11) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT26);
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
_outArg = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outArg;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_getCheckCref(threadData_t *threadData, modelica_metatype _inCrefs, modelica_metatype _inCheckCr)
{
modelica_metatype _outCheckCr = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inCrefs;
tmp4_2 = _inCheckCr;
{
modelica_metatype _ht = NULL;
modelica_metatype _ht1 = NULL;
modelica_metatype _ht2 = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _crlst = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _varLst = NULL;
modelica_metatype _creftpllst = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_ht = tmp4_2;
tmp4 += 2;
tmpMeta1 = _ht;
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
_cr = tmpMeta6;
_rest = tmpMeta7;
_ht = tmp4_2;
tmpMeta8 = omc_ComponentReference_crefLastType(threadData, _cr);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,9,3) == 0) goto goto_2;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
_varLst = tmpMeta9;
_crlst = omc_List_map1(threadData, _varLst, boxvar_Inline_extendCrefRecords2, _cr);
_ht1 = omc_Inline_getCheckCref(threadData, _crlst, _ht);
_creftpllst = omc_List_map1(threadData, _crlst, boxvar_Util_makeTuple, _cr);
_ht2 = omc_List_fold(threadData, _creftpllst, boxvar_BaseHashTable_add, _ht1);
tmpMeta1 = omc_Inline_getCheckCref(threadData, _rest, _ht2);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
_rest = tmpMeta11;
_ht = tmp4_2;
tmpMeta1 = omc_Inline_getCheckCref(threadData, _rest, _ht);
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
_outCheckCr = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCheckCr;
}
DLLExport
modelica_metatype omc_Inline_extendCrefRecords(threadData_t *threadData, modelica_metatype _inArgmap, modelica_metatype _inCheckCr, modelica_metatype *out_outCheckCr)
{
modelica_metatype _outArgmap = NULL;
modelica_metatype _outCheckCr = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inArgmap;
tmp4_2 = _inCheckCr;
{
modelica_metatype _ht = NULL;
modelica_metatype _ht1 = NULL;
modelica_metatype _ht2 = NULL;
modelica_metatype _ht3 = NULL;
modelica_metatype _res = NULL;
modelica_metatype _res1 = NULL;
modelica_metatype _res2 = NULL;
modelica_metatype _new = NULL;
modelica_metatype _new1 = NULL;
modelica_metatype _c = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _e = NULL;
modelica_metatype _varLst = NULL;
modelica_metatype _expl = NULL;
modelica_metatype _crlst = NULL;
modelica_metatype _creftpllst = NULL;
modelica_metatype _rpath = NULL;
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
if (!listEmpty(tmp4_1)) goto tmp3_end;
_ht = tmp4_2;
tmp4 += 7;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = tmpMeta6;
tmpMeta[0+1] = _ht;
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,20,2) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,9,3) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 3));
_c = tmpMeta9;
_e = tmpMeta12;
_res = tmpMeta8;
_ht = tmp4_2;
tmp4 += 4;
tmpMeta14 = mmc_mk_box2(0, _c, _e);
tmpMeta13 = mmc_mk_cons(tmpMeta14, _res);
tmpMeta[0+0] = omc_Inline_extendCrefRecords(threadData, tmpMeta13, _ht, &tmpMeta[0+1]);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta15 = MMC_CAR(tmp4_1);
tmpMeta16 = MMC_CDR(tmp4_1);
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 1));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,6,2) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,9,3) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 3));
_c = tmpMeta17;
_e = tmpMeta18;
_cref = tmpMeta19;
_varLst = tmpMeta21;
_res = tmpMeta16;
_ht = tmp4_2;
_res1 = omc_Inline_extendCrefRecords(threadData, _res, _ht ,&_ht1);
_new = omc_List_map2(threadData, _varLst, boxvar_Inline_extendCrefRecords1, _c, _cref);
_new1 = omc_Inline_extendCrefRecords(threadData, _new, _ht1 ,&_ht2);
_res2 = listAppend(_new1, _res1);
tmpMeta23 = mmc_mk_box2(0, _c, _e);
tmpMeta22 = mmc_mk_cons(tmpMeta23, _res2);
tmpMeta[0+0] = tmpMeta22;
tmpMeta[0+1] = _ht2;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta24 = MMC_CAR(tmp4_1);
tmpMeta25 = MMC_CDR(tmp4_1);
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 1));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta27,6,2) == 0) goto tmp3_end;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 2));
_c = tmpMeta26;
_e = tmpMeta27;
_cref = tmpMeta28;
_res = tmpMeta25;
_ht = tmp4_2;
tmp4 += 2;
tmpMeta29 = omc_ComponentReference_crefLastType(threadData, _cref);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta29,9,3) == 0) goto goto_2;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta29), 3));
_varLst = tmpMeta30;
_res1 = omc_Inline_extendCrefRecords(threadData, _res, _ht ,&_ht1);
_new = omc_List_map2(threadData, _varLst, boxvar_Inline_extendCrefRecords1, _c, _cref);
_new1 = omc_Inline_extendCrefRecords(threadData, _new, _ht1 ,&_ht2);
_res2 = listAppend(_new1, _res1);
tmpMeta32 = mmc_mk_box2(0, _c, _e);
tmpMeta31 = mmc_mk_cons(tmpMeta32, _res2);
tmpMeta[0+0] = tmpMeta31;
tmpMeta[0+1] = _ht2;
goto tmp3_done;
}
case 4: {
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta33 = MMC_CAR(tmp4_1);
tmpMeta34 = MMC_CDR(tmp4_1);
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta33), 1));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta33), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta36,13,3) == 0) goto tmp3_end;
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta36), 3));
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta36), 4));
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta38), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta39,9,3) == 0) goto tmp3_end;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta40,3,1) == 0) goto tmp3_end;
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta40), 2));
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 3));
_c = tmpMeta35;
_e = tmpMeta36;
_expl = tmpMeta37;
_rpath = tmpMeta41;
_varLst = tmpMeta42;
_res = tmpMeta34;
_ht = tmp4_2;
tmp4 += 1;
if (!omc_AbsynUtil_pathEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 2))), _rpath)) goto tmp3_end;
_res1 = omc_Inline_extendCrefRecords(threadData, _res, _ht ,&_ht1);
_crlst = omc_List_map1(threadData, _varLst, boxvar_Inline_extendCrefRecords2, _c);
_new = omc_List_zip(threadData, _crlst, _expl);
_new1 = omc_Inline_extendCrefRecords(threadData, _new, _ht1 ,&_ht2);
_res2 = listAppend(_new1, _res1);
tmpMeta44 = mmc_mk_box2(0, _c, _e);
tmpMeta43 = mmc_mk_cons(tmpMeta44, _res2);
tmpMeta[0+0] = tmpMeta43;
tmpMeta[0+1] = _ht2;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta45 = MMC_CAR(tmp4_1);
tmpMeta46 = MMC_CDR(tmp4_1);
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 1));
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta48,14,4) == 0) goto tmp3_end;
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta48), 3));
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta48), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta50,9,3) == 0) goto tmp3_end;
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta50), 3));
_c = tmpMeta47;
_e = tmpMeta48;
_expl = tmpMeta49;
_varLst = tmpMeta51;
_res = tmpMeta46;
_ht = tmp4_2;
_res1 = omc_Inline_extendCrefRecords(threadData, _res, _ht ,&_ht1);
_crlst = omc_List_map1(threadData, _varLst, boxvar_Inline_extendCrefRecords2, _c);
_new = omc_List_zip(threadData, _crlst, _expl);
_new1 = omc_Inline_extendCrefRecords(threadData, _new, _ht1 ,&_ht2);
_res2 = listAppend(_new1, _res1);
tmpMeta53 = mmc_mk_box2(0, _c, _e);
tmpMeta52 = mmc_mk_cons(tmpMeta53, _res2);
tmpMeta[0+0] = tmpMeta52;
tmpMeta[0+1] = _ht2;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
modelica_metatype tmpMeta57;
modelica_metatype tmpMeta58;
modelica_metatype tmpMeta59;
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta54 = MMC_CAR(tmp4_1);
tmpMeta55 = MMC_CDR(tmp4_1);
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta54), 1));
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta54), 2));
_c = tmpMeta56;
_e = tmpMeta57;
_res = tmpMeta55;
_ht = tmp4_2;
tmpMeta58 = omc_Expression_typeof(threadData, _e);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta58,9,3) == 0) goto goto_2;
tmpMeta59 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta58), 3));
_varLst = tmpMeta59;
_crlst = omc_List_map1(threadData, _varLst, boxvar_Inline_extendCrefRecords2, _c);
_creftpllst = omc_List_map1(threadData, _crlst, boxvar_Util_makeTuple, _c);
_ht1 = omc_List_fold(threadData, _creftpllst, boxvar_BaseHashTable_add, _ht);
_ht2 = omc_Inline_getCheckCref(threadData, _crlst, _ht1);
_res1 = omc_Inline_extendCrefRecords(threadData, _res, _ht2 ,&_ht3);
tmpMeta61 = mmc_mk_box2(0, _c, _e);
tmpMeta60 = mmc_mk_cons(tmpMeta61, _res1);
tmpMeta[0+0] = tmpMeta60;
tmpMeta[0+1] = _ht3;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta62;
modelica_metatype tmpMeta63;
modelica_metatype tmpMeta64;
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
modelica_metatype tmpMeta67;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta62 = MMC_CAR(tmp4_1);
tmpMeta63 = MMC_CDR(tmp4_1);
tmpMeta64 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta62), 1));
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta62), 2));
_c = tmpMeta64;
_e = tmpMeta65;
_res = tmpMeta63;
_ht = tmp4_2;
_res1 = omc_Inline_extendCrefRecords(threadData, _res, _ht ,&_ht1);
tmpMeta67 = mmc_mk_box2(0, _c, _e);
tmpMeta66 = mmc_mk_cons(tmpMeta67, _res1);
tmpMeta[0+0] = tmpMeta66;
tmpMeta[0+1] = _ht1;
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
_outArgmap = tmpMeta[0+0];
_outCheckCr = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outCheckCr) { *out_outCheckCr = _outCheckCr; }
return _outArgmap;
}
DLLExport
modelica_boolean omc_Inline_checkInlineType(threadData_t *threadData, modelica_metatype _inIT, modelica_metatype _fns)
{
modelica_boolean _outb;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inIT;
tmp4_2 = _fns;
{
modelica_metatype _it = NULL;
modelica_metatype _itlst = NULL;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_it = tmp4_1;
_itlst = tmpMeta6;
tmp1 = listMember(_it, _itlst);
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
_outb = tmp1;
_return: OMC_LABEL_UNUSED
return _outb;
}
modelica_metatype boxptr_Inline_checkInlineType(threadData_t *threadData, modelica_metatype _inIT, modelica_metatype _fns)
{
modelica_boolean _outb;
modelica_metatype out_outb;
_outb = omc_Inline_checkInlineType(threadData, _inIT, _fns);
out_outb = mmc_mk_icon(_outb);
return out_outb;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_addReplacement(threadData_t *threadData, modelica_metatype _iCr, modelica_metatype _iExp, modelica_metatype _iRepl)
{
modelica_metatype _oRepl = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _iCr;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta1 = omc_VarTransform_addReplacement(threadData, _iRepl, _iCr, _iExp);
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
_oRepl = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _oRepl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_addOptBindingReplacements(threadData_t *threadData, modelica_metatype _cr, modelica_metatype _binding, modelica_metatype _iRepl)
{
modelica_metatype _oRepl = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _binding;
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
tmpMeta1 = omc_Inline_addReplacement(threadData, _cr, _e, _iRepl);
goto tmp3_done;
}
case 1: {
if (!optionNone(tmp4_1)) goto tmp3_end;
tmpMeta1 = _iRepl;
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
_oRepl = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _oRepl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_makeComplexBinding(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fbinding, modelica_metatype _ty)
{
modelica_metatype _binding = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_binding = __omcQ_24in_5Fbinding;
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _binding;
tmp4_2 = _ty;
{
modelica_metatype _expl = NULL;
modelica_metatype _strl = NULL;
modelica_metatype _exp = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (!optionNone(tmp4_1)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,9,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
_expl = tmpMeta6;
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
_strl = tmpMeta7;
{
modelica_metatype _var;
for (tmpMeta8 = listReverse((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ty), 3)))); !listEmpty(tmpMeta8); tmpMeta8=MMC_CDR(tmpMeta8))
{
_var = MMC_CAR(tmpMeta8);
{
modelica_metatype tmp11_1;
tmp11_1 = _var;
{
volatile mmc_switch_type tmp11;
int tmp12;
tmp11 = 0;
for (; tmp11 < 2; tmp11++) {
switch (MMC_SWITCH_CAST(tmp11)) {
case 0: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp11_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,1,4) == 0) goto tmp10_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
_exp = tmpMeta14;
tmpMeta15 = mmc_mk_cons(_exp, _expl);
_expl = tmpMeta15;
tmpMeta16 = mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_var), 2))), _strl);
_strl = tmpMeta16;
goto tmp10_done;
}
case 1: {
goto _return;
goto tmp10_done;
}
}
goto tmp10_end;
tmp10_end: ;
}
goto goto_9;
goto_9:;
goto goto_2;
goto tmp10_done;
tmp10_done:;
}
}
;
}
}
tmpMeta18 = mmc_mk_box5(17, &DAE_Exp_RECORD__desc, omc_ClassInf_getStateName(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ty), 2)))), _expl, _strl, _ty);
tmpMeta1 = mmc_mk_some(tmpMeta18);
goto tmp3_done;
}
case 1: {
tmpMeta1 = _binding;
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
_binding = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _binding;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_getFunctionInputsOutputBody(threadData_t *threadData, modelica_metatype _fn, modelica_metatype _iRepl, modelica_metatype *out_oOutputs, modelica_metatype *out_oBody, modelica_metatype *out_oRepl)
{
modelica_metatype _oInputs = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _oOutputs = NULL;
modelica_metatype tmpMeta2;
modelica_metatype _oBody = NULL;
modelica_metatype tmpMeta3;
modelica_metatype _oRepl = NULL;
modelica_metatype _elt = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _binding = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _st = NULL;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta25;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_oInputs = tmpMeta1;
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
_oOutputs = tmpMeta2;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
_oBody = tmpMeta3;
_oRepl = _iRepl;
{
modelica_metatype _elt;
for (tmpMeta4 = _fn; !listEmpty(tmpMeta4); tmpMeta4=MMC_CDR(tmpMeta4))
{
_elt = MMC_CAR(tmpMeta4);
{
modelica_metatype tmp7_1;
tmp7_1 = _elt;
{
volatile mmc_switch_type tmp7;
int tmp8;
tmp7 = 0;
for (; tmp7 < 5; tmp7++) {
switch (MMC_SWITCH_CAST(tmp7)) {
case 0: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,0,13) == 0) goto tmp6_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,0,0) == 0) goto tmp6_end;
_cr = tmpMeta9;
tmpMeta11 = mmc_mk_cons(_cr, _oInputs);
_oInputs = tmpMeta11;
goto tmp6_done;
}
case 1: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,0,13) == 0) goto tmp6_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,1,0) == 0) goto tmp6_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 8));
_cr = tmpMeta12;
_binding = tmpMeta14;
_binding = omc_Inline_makeComplexBinding(threadData, _binding, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 7))));
_oRepl = omc_Inline_addOptBindingReplacements(threadData, _cr, _binding, _oRepl);
tmpMeta15 = mmc_mk_cons(_cr, _oOutputs);
_oOutputs = tmpMeta15;
goto tmp6_done;
}
case 2: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_boolean tmp19;
modelica_boolean tmp20;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,0,13) == 0) goto tmp6_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,1,0) == 0) goto tmp6_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 8));
_cr = tmpMeta16;
_binding = tmpMeta18;
_tp = omc_ComponentReference_crefTypeFull(threadData, _cr);
tmp19 = omc_Expression_isArrayType(threadData, _tp);
if (0 != tmp19) goto goto_5;
tmp20 = omc_Expression_isRecordType(threadData, _tp);
if (0 != tmp20) goto goto_5;
_oRepl = omc_Inline_addOptBindingReplacements(threadData, _cr, _binding, _oRepl);
goto tmp6_done;
}
case 3: {
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,15,2) == 0) goto tmp6_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 2));
_st = tmpMeta22;
_oBody = omc_List_append__reverse(threadData, _st, _oBody);
goto tmp6_done;
}
case 4: {
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
tmpMeta23 = mmc_mk_cons(_elt, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta24 = stringAppend(_OMC_LIT27,omc_DAEDump_dumpElementsStr(threadData, tmpMeta23));
omc_Error_addInternalError(threadData, tmpMeta24, _OMC_LIT29);
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
}
;
}
}
_oInputs = listReverse(_oInputs);
_oOutputs = listReverse(_oOutputs);
_oBody = listReverse(_oBody);
_return: OMC_LABEL_UNUSED
if (out_oOutputs) { *out_oOutputs = _oOutputs; }
if (out_oBody) { *out_oBody = _oBody; }
if (out_oRepl) { *out_oRepl = _oRepl; }
return _oInputs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_addTplAssignToRepl(threadData_t *threadData, modelica_metatype _explst, modelica_integer _indx, modelica_metatype _iExp, modelica_metatype _iRepl)
{
modelica_metatype _oRepl = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _explst;
{
modelica_metatype _repl = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _tp = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta1 = _iRepl;
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
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,6,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
_cr = tmpMeta8;
_tp = tmpMeta9;
_rest = tmpMeta7;
tmpMeta10 = mmc_mk_box4(25, &DAE_Exp_TSUB__desc, _iExp, mmc_mk_integer(_indx), _tp);
_exp = tmpMeta10;
_repl = omc_VarTransform_addReplacementNoTransitive(threadData, _iRepl, _cr, _exp);
_explst = _rest;
_indx = ((modelica_integer) 1) + _indx;
_iRepl = _repl;
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
_oRepl = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _oRepl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Inline_addTplAssignToRepl(threadData_t *threadData, modelica_metatype _explst, modelica_metatype _indx, modelica_metatype _iExp, modelica_metatype _iRepl)
{
modelica_integer tmp1;
modelica_metatype _oRepl = NULL;
tmp1 = mmc_unbox_integer(_indx);
_oRepl = omc_Inline_addTplAssignToRepl(threadData, _explst, tmp1, _iExp, _iRepl);
return _oRepl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_mergeFunctionBody(threadData_t *threadData, modelica_metatype _iStmts, modelica_metatype _iRepl, modelica_metatype _assertStmtsIn, modelica_metatype *out_assertStmtsOut)
{
modelica_metatype _oRepl = NULL;
modelica_metatype _assertStmtsOut = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _iStmts;
{
modelica_metatype _stmts = NULL;
modelica_metatype _repl = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
modelica_metatype _source = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _exp1 = NULL;
modelica_metatype _exp2 = NULL;
modelica_metatype _stmt = NULL;
modelica_metatype _explst = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 7; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0+0] = _iRepl;
tmpMeta[0+1] = _assertStmtsIn;
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
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,4) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,6,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
_cr = tmpMeta9;
_exp = tmpMeta10;
_stmts = tmpMeta7;
_exp = omc_VarTransform_replaceExp(threadData, _exp, _iRepl, mmc_mk_none(), NULL);
_repl = omc_VarTransform_addReplacementNoTransitive(threadData, _iRepl, _cr, _exp);
_iStmts = _stmts;
_iRepl = _repl;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta11 = MMC_CAR(tmp4_1);
tmpMeta12 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,2,4) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,6,2) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 4));
_cr = tmpMeta14;
_exp = tmpMeta15;
_stmts = tmpMeta12;
_exp = omc_VarTransform_replaceExp(threadData, _exp, _iRepl, mmc_mk_none(), NULL);
_repl = omc_VarTransform_addReplacementNoTransitive(threadData, _iRepl, _cr, _exp);
_iStmts = _stmts;
_iRepl = _repl;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmp4_1);
tmpMeta17 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,1,4) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 3));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 4));
_explst = tmpMeta18;
_exp = tmpMeta19;
_stmts = tmpMeta17;
_exp = omc_VarTransform_replaceExp(threadData, _exp, _iRepl, mmc_mk_none(), NULL);
_repl = omc_Inline_addTplAssignToRepl(threadData, _explst, ((modelica_integer) 1), _exp, _iRepl);
_iStmts = _stmts;
_iRepl = _repl;
goto _tailrecursive;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta20 = MMC_CAR(tmp4_1);
tmpMeta21 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,8,4) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 2));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 3));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 4));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 5));
_exp = tmpMeta22;
_exp1 = tmpMeta23;
_exp2 = tmpMeta24;
_source = tmpMeta25;
_stmts = tmpMeta21;
_exp = omc_VarTransform_replaceExp(threadData, _exp, _iRepl, mmc_mk_none(), NULL);
_exp1 = omc_VarTransform_replaceExp(threadData, _exp1, _iRepl, mmc_mk_none(), NULL);
_exp2 = omc_VarTransform_replaceExp(threadData, _exp2, _iRepl, mmc_mk_none(), NULL);
tmpMeta26 = mmc_mk_box5(11, &DAE_Statement_STMT__ASSERT__desc, _exp, _exp1, _exp2, _source);
_stmt = tmpMeta26;
tmpMeta27 = mmc_mk_cons(_stmt, _assertStmtsIn);
_iStmts = _stmts;
_assertStmtsIn = tmpMeta27;
goto _tailrecursive;
goto tmp3_done;
}
case 5: {
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta28 = MMC_CAR(tmp4_1);
tmpMeta29 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta28,3,4) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta28), 2));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta28), 3));
if (listEmpty(tmpMeta31)) goto tmp3_end;
tmpMeta32 = MMC_CAR(tmpMeta31);
tmpMeta33 = MMC_CDR(tmpMeta31);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta32,0,4) == 0) goto tmp3_end;
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta34,6,2) == 0) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 2));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 4));
if (!listEmpty(tmpMeta33)) goto tmp3_end;
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta28), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta37,2,1) == 0) goto tmp3_end;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 2));
if (listEmpty(tmpMeta38)) goto tmp3_end;
tmpMeta39 = MMC_CAR(tmpMeta38);
tmpMeta40 = MMC_CDR(tmpMeta38);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta39,0,4) == 0) goto tmp3_end;
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta41,6,2) == 0) goto tmp3_end;
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 2));
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 4));
if (!listEmpty(tmpMeta40)) goto tmp3_end;
_exp = tmpMeta30;
_cr1 = tmpMeta35;
_exp1 = tmpMeta36;
_cr2 = tmpMeta42;
_exp2 = tmpMeta43;
_stmts = tmpMeta29;
if (!omc_ComponentReference_crefEqual(threadData, _cr1, _cr2)) goto tmp3_end;
_exp = omc_VarTransform_replaceExp(threadData, _exp, _iRepl, mmc_mk_none(), NULL);
_exp1 = omc_VarTransform_replaceExp(threadData, _exp1, _iRepl, mmc_mk_none(), NULL);
_exp2 = omc_VarTransform_replaceExp(threadData, _exp2, _iRepl, mmc_mk_none(), NULL);
tmpMeta44 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _exp, _exp1, _exp2);
_repl = omc_VarTransform_addReplacementNoTransitive(threadData, _iRepl, _cr1, tmpMeta44);
_iStmts = _stmts;
_iRepl = _repl;
goto _tailrecursive;
goto tmp3_done;
}
case 6: {
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta45 = MMC_CAR(tmp4_1);
tmpMeta46 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta45,3,4) == 0) goto tmp3_end;
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 2));
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 3));
if (listEmpty(tmpMeta48)) goto tmp3_end;
tmpMeta49 = MMC_CAR(tmpMeta48);
tmpMeta50 = MMC_CDR(tmpMeta48);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta49,2,4) == 0) goto tmp3_end;
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta49), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta51,6,2) == 0) goto tmp3_end;
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta51), 2));
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta49), 4));
if (!listEmpty(tmpMeta50)) goto tmp3_end;
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta54,2,1) == 0) goto tmp3_end;
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta54), 2));
if (listEmpty(tmpMeta55)) goto tmp3_end;
tmpMeta56 = MMC_CAR(tmpMeta55);
tmpMeta57 = MMC_CDR(tmpMeta55);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta56,2,4) == 0) goto tmp3_end;
tmpMeta58 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta56), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta58,6,2) == 0) goto tmp3_end;
tmpMeta59 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta58), 2));
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta56), 4));
if (!listEmpty(tmpMeta57)) goto tmp3_end;
_exp = tmpMeta47;
_cr1 = tmpMeta52;
_exp1 = tmpMeta53;
_cr2 = tmpMeta59;
_exp2 = tmpMeta60;
_stmts = tmpMeta46;
if (!omc_ComponentReference_crefEqual(threadData, _cr1, _cr2)) goto tmp3_end;
_exp = omc_VarTransform_replaceExp(threadData, _exp, _iRepl, mmc_mk_none(), NULL);
_exp1 = omc_VarTransform_replaceExp(threadData, _exp1, _iRepl, mmc_mk_none(), NULL);
_exp2 = omc_VarTransform_replaceExp(threadData, _exp2, _iRepl, mmc_mk_none(), NULL);
tmpMeta61 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _exp, _exp1, _exp2);
_repl = omc_VarTransform_addReplacementNoTransitive(threadData, _iRepl, _cr1, tmpMeta61);
_iStmts = _stmts;
_iRepl = _repl;
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
_oRepl = tmpMeta[0+0];
_assertStmtsOut = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_assertStmtsOut) { *out_assertStmtsOut = _assertStmtsOut; }
return _oRepl;
}
static modelica_metatype closure2_Inline_forceInlineCall(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_exp, modelica_metatype $in_assrtLst, modelica_metatype tmp23)
{
modelica_metatype fns = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype visitedPaths = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_Inline_forceInlineCall(thData, $in_exp, $in_assrtLst, fns, visitedPaths, tmp23);
}
DLLExport
modelica_metatype omc_Inline_forceInlineCall(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype __omcQ_24in_5FassrtLst, modelica_metatype _fns, modelica_metatype _visitedPaths, modelica_metatype *out_assrtLst)
{
modelica_metatype _exp = NULL;
modelica_metatype _assrtLst = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_exp = __omcQ_24in_5Fexp;
_assrtLst = __omcQ_24in_5FassrtLst;
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _exp;
{
modelica_metatype _fn = NULL;
modelica_metatype _p = NULL;
modelica_metatype _args = NULL;
modelica_metatype _lst_cr = NULL;
modelica_metatype _crefs = NULL;
modelica_metatype _argmap = NULL;
modelica_metatype _newExp = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _inlineType = NULL;
modelica_metatype _checkcr = NULL;
modelica_metatype _stmts = NULL;
modelica_metatype _repl = NULL;
modelica_boolean _generateEvents;
modelica_metatype _comment = NULL;
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
modelica_boolean tmp10;
modelica_boolean tmp11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_boolean tmp17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_integer tmp20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta24;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 7));
_e1 = tmp4_1;
_p = tmpMeta6;
_args = tmpMeta7;
_inlineType = tmpMeta9;
if (!(!omc_AvlSetPath_hasKey(threadData, _visitedPaths, _p))) goto tmp3_end;
tmp10 = omc_Config_acceptMetaModelicaGrammar(threadData);
if (0 != tmp10) goto goto_2;
tmp11 = omc_Inline_checkInlineType(threadData, _inlineType, _fns);
if (1 != tmp11) goto goto_2;
_fn = omc_Inline_getFunctionBody(threadData, _p, _fns ,&_comment);
_checkcr = omc_Inline_getInlineHashTableVarTransform(threadData ,&_repl);
_crefs = omc_Inline_getFunctionInputsOutputBody(threadData, _fn, _repl ,&_lst_cr ,&_stmts ,&_repl);
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
_repl = omc_Inline_mergeFunctionBody(threadData, _stmts, _repl, tmpMeta12, NULL);
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp14;
modelica_metatype tmpMeta15;
modelica_metatype __omcQ_24tmpVar0;
modelica_integer tmp16;
modelica_metatype _cr_loopVar = 0;
modelica_metatype _cr;
_cr_loopVar = _lst_cr;
tmpMeta15 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta15;
tmp14 = &__omcQ_24tmpVar1;
while(1) {
tmp16 = 1;
if (!listEmpty(_cr_loopVar)) {
_cr = MMC_CAR(_cr_loopVar);
_cr_loopVar = MMC_CDR(_cr_loopVar);
tmp16--;
}
if (tmp16 == 0) {
__omcQ_24tmpVar0 = omc_VarTransform_getReplacement(threadData, _repl, _cr);
*tmp14 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp14 = &MMC_CDR(*tmp14);
} else if (tmp16 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp14 = mmc_mk_nil();
tmpMeta13 = __omcQ_24tmpVar1;
}
_newExp = omc_Expression_makeTuple(threadData, tmpMeta13);
tmp17 = omc_Inline_checkExpsTypeEquiv(threadData, _e1, _newExp);
if (1 != tmp17) goto goto_2;
_argmap = omc_List_zip(threadData, _crefs, _args);
_argmap = omc_Inline_extendCrefRecords(threadData, _argmap, _checkcr ,&_checkcr);
_generateEvents = omc_Inline_hasGenerateEventsAnnotation(threadData, _comment);
_newExp = ((!_generateEvents)?omc_Expression_addNoEventToRelationsAndConds(threadData, _newExp):_newExp);
tmpMeta21 = mmc_mk_box3(0, _argmap, _checkcr, mmc_mk_boolean(1));
tmpMeta22 = omc_Expression_traverseExpBottomUp(threadData, _newExp, boxvar_Inline_replaceArgs, tmpMeta21, &tmpMeta18);
_newExp = tmpMeta22;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 3));
tmp20 = mmc_unbox_integer(tmpMeta19);
if (1 != tmp20) goto goto_2;
tmpMeta24 = mmc_mk_box2(0, _fns, omc_AvlSetPath_add(threadData, _visitedPaths, _p));
tmpMeta[0+0] = omc_Expression_traverseExpBottomUp(threadData, _newExp, (modelica_fnptr) mmc_mk_box2(0,closure2_Inline_forceInlineCall,tmpMeta24), _assrtLst, &tmpMeta[0+1]);
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = _assrtLst;
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
_exp = tmpMeta[0+0];
_assrtLst = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_assrtLst) { *out_assrtLst = _assrtLst; }
return _exp;
}
PROTECTED_FUNCTION_STATIC void omc_Inline_dumpArgmap(threadData_t *threadData, modelica_metatype _inTpl)
{
modelica_metatype _cr = NULL;
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inTpl;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_cr = tmpMeta2;
_exp = tmpMeta3;
tmpMeta4 = stringAppend(omc_ComponentReference_printComponentRefStr(threadData, _cr),_OMC_LIT30);
tmpMeta5 = stringAppend(tmpMeta4,omc_ExpressionDump_printExpStr(threadData, _exp));
tmpMeta6 = stringAppend(tmpMeta5,_OMC_LIT31);
fputs(MMC_STRINGDATA(tmpMeta6),stdout);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_boolean omc_Inline_hasGenerateEventsAnnotation(threadData_t *threadData, modelica_metatype _comment)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _comment;
{
modelica_metatype _anno = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (optionNone(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
_anno = tmpMeta8;
tmp1 = omc_SCodeUtil_hasBooleanNamedAnnotation(threadData, _anno, _OMC_LIT32);
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
modelica_metatype boxptr_Inline_hasGenerateEventsAnnotation(threadData_t *threadData, modelica_metatype _comment)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_Inline_hasGenerateEventsAnnotation(threadData, _comment);
out_b = mmc_mk_icon(_b);
return out_b;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_inlineAssert(threadData_t *threadData, modelica_metatype _assrtIn, modelica_metatype _fns, modelica_metatype _argmap, modelica_metatype _checkcr)
{
modelica_metatype _assrtOut = NULL;
modelica_metatype _source = NULL;
modelica_metatype _cond = NULL;
modelica_metatype _msg = NULL;
modelica_metatype _level = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_integer tmp8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_integer tmp13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _assrtIn;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,8,4) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 5));
_cond = tmpMeta2;
_msg = tmpMeta3;
_level = tmpMeta4;
_source = tmpMeta5;
tmpMeta9 = mmc_mk_box3(0, _argmap, _checkcr, mmc_mk_boolean(1));
tmpMeta10 = omc_Expression_traverseExpBottomUp(threadData, _cond, boxvar_Inline_replaceArgs, tmpMeta9, &tmpMeta6);
_cond = tmpMeta10;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
tmp8 = mmc_unbox_integer(tmpMeta7);
if (1 != tmp8) MMC_THROW_INTERNAL();
tmpMeta14 = mmc_mk_box3(0, _argmap, _checkcr, mmc_mk_boolean(1));
tmpMeta15 = omc_Expression_traverseExpBottomUp(threadData, _msg, boxvar_Inline_replaceArgs, tmpMeta14, &tmpMeta11);
_msg = tmpMeta15;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 3));
tmp13 = mmc_unbox_integer(tmpMeta12);
if (1 != tmp13) MMC_THROW_INTERNAL();
tmpMeta16 = mmc_mk_box5(11, &DAE_Statement_STMT__ASSERT__desc, _cond, _msg, _level, _source);
_assrtOut = tmpMeta16;
_return: OMC_LABEL_UNUSED
return _assrtOut;
}
static modelica_metatype closure3_Inline_inlineCall(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_exp, modelica_metatype $in_assrtLst, modelica_metatype tmp23)
{
modelica_metatype fns = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_Inline_inlineCall(thData, $in_exp, $in_assrtLst, fns, tmp23);
}static modelica_metatype closure4_Inline_inlineCall(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_exp, modelica_metatype $in_assrtLst, modelica_metatype tmp36)
{
modelica_metatype fns = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_Inline_inlineCall(thData, $in_exp, $in_assrtLst, fns, tmp36);
}static modelica_metatype closure5_Inline_inlineCall(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_exp, modelica_metatype $in_assrtLst, modelica_metatype tmp50)
{
modelica_metatype fns = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_Inline_inlineCall(thData, $in_exp, $in_assrtLst, fns, tmp50);
}
DLLExport
modelica_metatype omc_Inline_inlineCall(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype __omcQ_24in_5FassrtLst, modelica_metatype _fns, modelica_metatype *out_assrtLst)
{
modelica_metatype _exp = NULL;
modelica_metatype _assrtLst = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_exp = __omcQ_24in_5Fexp;
_assrtLst = __omcQ_24in_5FassrtLst;
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _exp;
{
modelica_metatype _fn = NULL;
modelica_metatype _p = NULL;
modelica_metatype _args = NULL;
modelica_metatype _crefs = NULL;
modelica_metatype _argmap = NULL;
modelica_metatype _lst_cr = NULL;
modelica_metatype _newExp = NULL;
modelica_metatype _newExp1 = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _inlineType = NULL;
modelica_metatype _assrt = NULL;
modelica_metatype _checkcr = NULL;
modelica_metatype _stmts = NULL;
modelica_metatype _assrtStmts = NULL;
modelica_metatype _repl = NULL;
modelica_boolean _generateEvents;
modelica_metatype _comment = NULL;
modelica_metatype _ty = NULL;
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
modelica_boolean tmp8;
modelica_boolean tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 7));
_inlineType = tmpMeta7;
tmp8 = omc_Flags_isSet(threadData, _OMC_LIT36);
if (0 != tmp8) goto goto_2;
tmp9 = valueEq(_OMC_LIT37, _inlineType);
if (0 != tmp9) goto goto_2;
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = _assrtLst;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_boolean tmp15;
modelica_boolean tmp16;
modelica_boolean tmp17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_integer tmp20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_boolean tmp30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_integer tmp33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta37;
modelica_boolean tmp38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_boolean tmp44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_integer tmp47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 7));
_e1 = tmp4_1;
_p = tmpMeta10;
_args = tmpMeta11;
_ty = tmpMeta13;
_inlineType = tmpMeta14;
tmp15 = omc_Inline_checkInlineType(threadData, _inlineType, _fns);
if (1 != tmp15) goto goto_2;
_fn = omc_Inline_getFunctionBody(threadData, _p, _fns ,&_comment);
_checkcr = omc_Inline_getInlineHashTableVarTransform(threadData ,&_repl);
if(omc_Config_acceptMetaModelicaGrammar(threadData))
{
_crefs = omc_List_map(threadData, _fn, boxvar_Inline_getInputCrefs);
_crefs = omc_List_select(threadData, _crefs, boxvar_Inline_removeWilds);
_argmap = omc_List_zip(threadData, _crefs, _args);
tmp16 = omc_List_exist(threadData, _fn, boxvar_DAEUtil_isProtectedVar);
if (0 != tmp16) goto goto_2;
_newExp = omc_Inline_getRhsExp(threadData, _fn);
tmp17 = omc_Inline_checkExpsTypeEquiv(threadData, _e1, _newExp);
if (1 != tmp17) goto goto_2;
_argmap = omc_Inline_extendCrefRecords(threadData, _argmap, _checkcr ,&_checkcr);
_newExp = omc_Expression_addNoEventToRelationsAndConds(threadData, _newExp);
tmpMeta21 = mmc_mk_box3(0, _argmap, _checkcr, mmc_mk_boolean(1));
tmpMeta22 = omc_Expression_traverseExpBottomUp(threadData, _newExp, boxvar_Inline_replaceArgs, tmpMeta21, &tmpMeta18);
_newExp = tmpMeta22;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 3));
tmp20 = mmc_unbox_integer(tmpMeta19);
if (1 != tmp20) goto goto_2;
tmpMeta24 = mmc_mk_box1(0, _fns);
_newExp1 = omc_Expression_traverseExpBottomUp(threadData, _newExp, (modelica_fnptr) mmc_mk_box2(0,closure3_Inline_inlineCall,tmpMeta24), _assrtLst ,&_assrtLst);
}
else
{
_crefs = omc_Inline_getFunctionInputsOutputBody(threadData, _fn, _repl ,&_lst_cr ,&_stmts ,&_repl);
tmpMeta25 = MMC_REFSTRUCTLIT(mmc_nil);
_repl = omc_Inline_mergeFunctionBody(threadData, _stmts, _repl, tmpMeta25 ,&_assrtStmts);
if(listEmpty(_assrtStmts))
{
{
modelica_metatype __omcQ_24tmpVar3;
modelica_metatype* tmp27;
modelica_metatype tmpMeta28;
modelica_metatype __omcQ_24tmpVar2;
modelica_integer tmp29;
modelica_metatype _cr_loopVar = 0;
modelica_metatype _cr;
_cr_loopVar = _lst_cr;
tmpMeta28 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta28;
tmp27 = &__omcQ_24tmpVar3;
while(1) {
tmp29 = 1;
if (!listEmpty(_cr_loopVar)) {
_cr = MMC_CAR(_cr_loopVar);
_cr_loopVar = MMC_CDR(_cr_loopVar);
tmp29--;
}
if (tmp29 == 0) {
__omcQ_24tmpVar2 = omc_Inline_getReplacementCheckComplex(threadData, _repl, _cr, _ty);
*tmp27 = mmc_mk_cons(__omcQ_24tmpVar2,0);
tmp27 = &MMC_CDR(*tmp27);
} else if (tmp29 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp27 = mmc_mk_nil();
tmpMeta26 = __omcQ_24tmpVar3;
}
_newExp = omc_Expression_makeTuple(threadData, tmpMeta26);
tmp30 = omc_Inline_checkExpsTypeEquiv(threadData, _e1, _newExp);
if (1 != tmp30) goto goto_2;
_argmap = omc_List_zip(threadData, _crefs, _args);
_checkcr = omc_Inline_getInlineHashTableVarTransform(threadData, NULL);
_argmap = omc_Inline_extendCrefRecords(threadData, _argmap, _checkcr ,&_checkcr);
_generateEvents = omc_Inline_hasGenerateEventsAnnotation(threadData, _comment);
_newExp = ((!_generateEvents)?omc_Expression_addNoEventToRelationsAndConds(threadData, _newExp):_newExp);
tmpMeta34 = mmc_mk_box3(0, _argmap, _checkcr, mmc_mk_boolean(1));
tmpMeta35 = omc_Expression_traverseExpBottomUp(threadData, _newExp, boxvar_Inline_replaceArgs, tmpMeta34, &tmpMeta31);
_newExp = tmpMeta35;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta31), 3));
tmp33 = mmc_unbox_integer(tmpMeta32);
if (1 != tmp33) goto goto_2;
tmpMeta37 = mmc_mk_box1(0, _fns);
_newExp1 = omc_Expression_traverseExpBottomUp(threadData, _newExp, (modelica_fnptr) mmc_mk_box2(0,closure4_Inline_inlineCall,tmpMeta37), _assrtLst ,&_assrtLst);
}
else
{
tmp38 = (listLength(_assrtStmts) == ((modelica_integer) 1));
if (1 != tmp38) goto goto_2;
_assrt = listHead(_assrtStmts);
tmpMeta39 = _assrt;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta39,8,4) == 0) goto goto_2;
{
modelica_metatype __omcQ_24tmpVar5;
modelica_metatype* tmp41;
modelica_metatype tmpMeta42;
modelica_metatype __omcQ_24tmpVar4;
modelica_integer tmp43;
modelica_metatype _cr_loopVar = 0;
modelica_metatype _cr;
_cr_loopVar = _lst_cr;
tmpMeta42 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar5 = tmpMeta42;
tmp41 = &__omcQ_24tmpVar5;
while(1) {
tmp43 = 1;
if (!listEmpty(_cr_loopVar)) {
_cr = MMC_CAR(_cr_loopVar);
_cr_loopVar = MMC_CDR(_cr_loopVar);
tmp43--;
}
if (tmp43 == 0) {
__omcQ_24tmpVar4 = omc_Inline_getReplacementCheckComplex(threadData, _repl, _cr, _ty);
*tmp41 = mmc_mk_cons(__omcQ_24tmpVar4,0);
tmp41 = &MMC_CDR(*tmp41);
} else if (tmp43 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp41 = mmc_mk_nil();
tmpMeta40 = __omcQ_24tmpVar5;
}
_newExp = omc_Expression_makeTuple(threadData, tmpMeta40);
tmp44 = omc_Inline_checkExpsTypeEquiv(threadData, _e1, _newExp);
if (1 != tmp44) goto goto_2;
_argmap = omc_List_zip(threadData, _crefs, _args);
_argmap = omc_Inline_extendCrefRecords(threadData, _argmap, _checkcr ,&_checkcr);
_generateEvents = omc_Inline_hasGenerateEventsAnnotation(threadData, _comment);
_newExp = ((!_generateEvents)?omc_Expression_addNoEventToRelationsAndConds(threadData, _newExp):_newExp);
tmpMeta48 = mmc_mk_box3(0, _argmap, _checkcr, mmc_mk_boolean(1));
tmpMeta49 = omc_Expression_traverseExpBottomUp(threadData, _newExp, boxvar_Inline_replaceArgs, tmpMeta48, &tmpMeta45);
_newExp = tmpMeta49;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 3));
tmp47 = mmc_unbox_integer(tmpMeta46);
if (1 != tmp47) goto goto_2;
_assrt = omc_Inline_inlineAssert(threadData, _assrt, _fns, _argmap, _checkcr);
tmpMeta51 = mmc_mk_box1(0, _fns);
tmpMeta52 = mmc_mk_cons(_assrt, _assrtLst);
_newExp1 = omc_Expression_traverseExpBottomUp(threadData, _newExp, (modelica_fnptr) mmc_mk_box2(0,closure5_Inline_inlineCall,tmpMeta51), tmpMeta52 ,&_assrtLst);
}
}
tmpMeta[0+0] = _newExp1;
tmpMeta[0+1] = _assrtLst;
goto tmp3_done;
}
case 2: {
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = _assrtLst;
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
_exp = tmpMeta[0+0];
_assrtLst = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_assrtLst) { *out_assrtLst = _assrtLst; }
return _exp;
}
DLLExport
modelica_boolean omc_Inline_checkExpsTypeEquiv(threadData_t *threadData, modelica_metatype _inExp1, modelica_metatype _inExp2)
{
modelica_boolean _bEquiv;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _ty1 = NULL;
modelica_metatype _ty2 = NULL;
modelica_boolean _b;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if(omc_Config_acceptMetaModelicaGrammar(threadData))
{
_b = 1;
}
else
{
_ty1 = omc_Expression_typeof(threadData, _inExp1);
_ty2 = omc_Expression_typeof(threadData, _inExp2);
_ty2 = omc_Types_traverseType(threadData, _ty2, mmc_mk_integer(((modelica_integer) -1)), boxvar_Types_makeExpDimensionsUnknown, NULL);
_b = omc_Types_equivtypesOrRecordSubtypeOf(threadData, _ty1, _ty2);
}
tmp1 = _b;
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
_bEquiv = tmp1;
_return: OMC_LABEL_UNUSED
return _bEquiv;
}
modelica_metatype boxptr_Inline_checkExpsTypeEquiv(threadData_t *threadData, modelica_metatype _inExp1, modelica_metatype _inExp2)
{
modelica_boolean _bEquiv;
modelica_metatype out_bEquiv;
_bEquiv = omc_Inline_checkExpsTypeEquiv(threadData, _inExp1, _inExp2);
out_bEquiv = mmc_mk_icon(_bEquiv);
return out_bEquiv;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_inlineExpsWork(threadData_t *threadData, modelica_metatype _inExps, modelica_metatype _fns, modelica_metatype _inSource, modelica_metatype _iAcc, modelica_boolean _iInlined, modelica_metatype *out_outSource, modelica_boolean *out_oInlined)
{
modelica_metatype _outExps = NULL;
modelica_metatype _outSource = NULL;
modelica_boolean _oInlined;
modelica_boolean tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExps;
{
modelica_metatype _e = NULL;
modelica_metatype _exps = NULL;
modelica_metatype _source = NULL;
modelica_boolean _b;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0+0] = listReverse(_iAcc);
tmpMeta[0+1] = _inSource;
tmp1_c2 = _iInlined;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_e = tmpMeta6;
_exps = tmpMeta7;
_e = omc_Inline_inlineExp(threadData, _e, _fns, _inSource ,&_source ,&_b ,NULL);
tmpMeta8 = mmc_mk_cons(_e, _iAcc);
_inExps = _exps;
_inSource = _source;
_iAcc = tmpMeta8;
_iInlined = (_b || _iInlined);
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
_outExps = tmpMeta[0+0];
_outSource = tmpMeta[0+1];
_oInlined = tmp1_c2;
_return: OMC_LABEL_UNUSED
if (out_outSource) { *out_outSource = _outSource; }
if (out_oInlined) { *out_oInlined = _oInlined; }
return _outExps;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Inline_inlineExpsWork(threadData_t *threadData, modelica_metatype _inExps, modelica_metatype _fns, modelica_metatype _inSource, modelica_metatype _iAcc, modelica_metatype _iInlined, modelica_metatype *out_outSource, modelica_metatype *out_oInlined)
{
modelica_integer tmp1;
modelica_boolean _oInlined;
modelica_metatype _outExps = NULL;
tmp1 = mmc_unbox_integer(_iInlined);
_outExps = omc_Inline_inlineExpsWork(threadData, _inExps, _fns, _inSource, _iAcc, tmp1, out_outSource, &_oInlined);
if (out_oInlined) { *out_oInlined = mmc_mk_icon(_oInlined); }
return _outExps;
}
DLLExport
modelica_metatype omc_Inline_inlineExps(threadData_t *threadData, modelica_metatype _inExps, modelica_metatype _inElementList, modelica_metatype _inSource, modelica_metatype *out_outSource, modelica_boolean *out_inlined)
{
modelica_metatype _outExps = NULL;
modelica_metatype _outSource = NULL;
modelica_boolean _inlined;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outExps = omc_Inline_inlineExpsWork(threadData, _inExps, _inElementList, _inSource, tmpMeta1, 0 ,&_outSource ,&_inlined);
_return: OMC_LABEL_UNUSED
if (out_outSource) { *out_outSource = _outSource; }
if (out_inlined) { *out_inlined = _inlined; }
return _outExps;
}
modelica_metatype boxptr_Inline_inlineExps(threadData_t *threadData, modelica_metatype _inExps, modelica_metatype _inElementList, modelica_metatype _inSource, modelica_metatype *out_outSource, modelica_metatype *out_inlined)
{
modelica_boolean _inlined;
modelica_metatype _outExps = NULL;
_outExps = omc_Inline_inlineExps(threadData, _inExps, _inElementList, _inSource, out_outSource, &_inlined);
if (out_inlined) { *out_inlined = mmc_mk_icon(_inlined); }
return _outExps;
}
static modelica_metatype closure6_Inline_forceInlineCall(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_exp, modelica_metatype $in_assrtLst, modelica_metatype tmp11)
{
modelica_metatype fns = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype visitedPaths = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_Inline_forceInlineCall(thData, $in_exp, $in_assrtLst, fns, visitedPaths, tmp11);
}
DLLExport
modelica_metatype omc_Inline_forceInlineExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inElementList, modelica_metatype _inSource, modelica_metatype *out_outSource, modelica_boolean *out_inlineperformed)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outSource = NULL;
modelica_boolean _inlineperformed;
modelica_boolean tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inExp;
tmp4_2 = _inElementList;
tmp4_3 = _inSource;
{
modelica_metatype _fns = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e_1 = NULL;
modelica_metatype _source = NULL;
modelica_metatype _functionTree = NULL;
modelica_boolean _b;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
if (optionNone(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
_functionTree = tmpMeta7;
_e = tmp4_1;
_source = tmp4_3;
if (!omc_Expression_isConst(threadData, _inExp)) goto tmp3_end;
_e_1 = omc_Ceval_cevalSimpleWithFunctionTreeReturnExp(threadData, _inExp, _functionTree);
tmpMeta8 = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _e);
tmpMeta9 = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _e_1);
tmpMeta10 = mmc_mk_box3(6, &DAE_SymbolicOperation_OP__INLINE__desc, tmpMeta8, tmpMeta9);
_source = omc_ElementSource_addSymbolicTransformation(threadData, _source, tmpMeta10);
tmpMeta[0+0] = _e_1;
tmpMeta[0+1] = _source;
tmp1_c2 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
_e = tmp4_1;
_fns = tmp4_2;
_source = tmp4_3;
tmpMeta12 = mmc_mk_box2(0, _fns, _OMC_LIT9);
tmpMeta13 = MMC_REFSTRUCTLIT(mmc_nil);
_e_1 = omc_Expression_traverseExpBottomUp(threadData, _e, (modelica_fnptr) mmc_mk_box2(0,closure6_Inline_forceInlineCall,tmpMeta12), tmpMeta13, NULL);
_b = (!referenceEq(_e, _e_1));
if(_b)
{
tmpMeta14 = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _e);
tmpMeta15 = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _e_1);
tmpMeta16 = mmc_mk_box3(6, &DAE_SymbolicOperation_OP__INLINE__desc, tmpMeta14, tmpMeta15);
_source = omc_ElementSource_addSymbolicTransformation(threadData, _source, tmpMeta16);
tmpMeta18 = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _e_1);
tmpMeta19 = omc_ExpressionSimplify_simplifyAddSymbolicOperation(threadData, tmpMeta18, _source, &tmpMeta17);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta19,0,1) == 0) goto goto_2;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 2));
_e_1 = tmpMeta20;
_source = tmpMeta17;
}
tmpMeta[0+0] = _e_1;
tmpMeta[0+1] = _source;
tmp1_c2 = _b;
goto tmp3_done;
}
case 2: {
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inSource;
tmp1_c2 = 0;
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
_outSource = tmpMeta[0+1];
_inlineperformed = tmp1_c2;
_return: OMC_LABEL_UNUSED
if (out_outSource) { *out_outSource = _outSource; }
if (out_inlineperformed) { *out_inlineperformed = _inlineperformed; }
return _outExp;
}
modelica_metatype boxptr_Inline_forceInlineExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inElementList, modelica_metatype _inSource, modelica_metatype *out_outSource, modelica_metatype *out_inlineperformed)
{
modelica_boolean _inlineperformed;
modelica_metatype _outExp = NULL;
_outExp = omc_Inline_forceInlineExp(threadData, _inExp, _inElementList, _inSource, out_outSource, &_inlineperformed);
if (out_inlineperformed) { *out_inlineperformed = mmc_mk_icon(_inlineperformed); }
return _outExp;
}
static modelica_metatype closure7_Inline_inlineCall(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_exp, modelica_metatype $in_assrtLst, modelica_metatype tmp8)
{
modelica_metatype fns = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_Inline_inlineCall(thData, $in_exp, $in_assrtLst, fns, tmp8);
}
DLLExport
modelica_metatype omc_Inline_inlineExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inElementList, modelica_metatype _inSource, modelica_metatype *out_outSource, modelica_boolean *out_inlined, modelica_metatype *out_assrtLstOut)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outSource = NULL;
modelica_boolean _inlined;
modelica_metatype _assrtLstOut = NULL;
modelica_boolean tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inExp;
tmp4_2 = _inElementList;
tmp4_3 = _inSource;
{
modelica_metatype _fns = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e_1 = NULL;
modelica_metatype _e_2 = NULL;
modelica_metatype _source = NULL;
modelica_metatype _assrtLst = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,4,0) == 0) goto tmp3_end;
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inSource;
tmp1_c2 = 0;
tmpMeta[0+3] = tmpMeta7;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_boolean tmp11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
_e = tmp4_1;
_fns = tmp4_2;
_source = tmp4_3;
tmpMeta9 = mmc_mk_box1(0, _fns);
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
_e_1 = omc_Expression_traverseExpBottomUp(threadData, _e, (modelica_fnptr) mmc_mk_box2(0,closure7_Inline_inlineCall,tmpMeta9), tmpMeta10 ,&_assrtLst);
tmp11 = referenceEq(_e, _e_1);
if (0 != tmp11) goto goto_2;
if(omc_Flags_isSet(threadData, _OMC_LIT41))
{
tmpMeta12 = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _e);
tmpMeta13 = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _e_1);
tmpMeta14 = mmc_mk_box3(6, &DAE_SymbolicOperation_OP__INLINE__desc, tmpMeta12, tmpMeta13);
_source = omc_ElementSource_addSymbolicTransformation(threadData, _source, tmpMeta14);
tmpMeta16 = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _e_1);
tmpMeta17 = omc_ExpressionSimplify_simplifyAddSymbolicOperation(threadData, tmpMeta16, _source, &tmpMeta15);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,0,1) == 0) goto goto_2;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 2));
_e_2 = tmpMeta18;
_source = tmpMeta15;
}
else
{
_e_2 = omc_ExpressionSimplify_simplify(threadData, _e_1, NULL);
}
tmpMeta[0+0] = _e_2;
tmpMeta[0+1] = _source;
tmp1_c2 = 1;
tmpMeta[0+3] = _assrtLst;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta19;
tmpMeta19 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inSource;
tmp1_c2 = 0;
tmpMeta[0+3] = tmpMeta19;
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
_outExp = tmpMeta[0+0];
_outSource = tmpMeta[0+1];
_inlined = tmp1_c2;
_assrtLstOut = tmpMeta[0+3];
_return: OMC_LABEL_UNUSED
if (out_outSource) { *out_outSource = _outSource; }
if (out_inlined) { *out_inlined = _inlined; }
if (out_assrtLstOut) { *out_assrtLstOut = _assrtLstOut; }
return _outExp;
}
modelica_metatype boxptr_Inline_inlineExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inElementList, modelica_metatype _inSource, modelica_metatype *out_outSource, modelica_metatype *out_inlined, modelica_metatype *out_assrtLstOut)
{
modelica_boolean _inlined;
modelica_metatype _outExp = NULL;
_outExp = omc_Inline_inlineExp(threadData, _inExp, _inElementList, _inSource, out_outSource, &_inlined, out_assrtLstOut);
if (out_inlined) { *out_inlined = mmc_mk_icon(_inlined); }
return _outExp;
}
DLLExport
modelica_metatype omc_Inline_inlineExpOpt(threadData_t *threadData, modelica_metatype _inExpOption, modelica_metatype _inElementList, modelica_metatype _inSource, modelica_metatype *out_outSource, modelica_boolean *out_inlined)
{
modelica_metatype _outExpOption = NULL;
modelica_metatype _outSource = NULL;
modelica_boolean _inlined;
modelica_boolean tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExpOption;
{
modelica_metatype _exp = NULL;
modelica_metatype _source = NULL;
modelica_boolean _b;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0+0] = mmc_mk_none();
tmpMeta[0+1] = _inSource;
tmp1_c2 = 0;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_exp = tmpMeta6;
_exp = omc_Inline_inlineExp(threadData, _exp, _inElementList, _inSource ,&_source ,&_b ,NULL);
tmpMeta[0+0] = mmc_mk_some(_exp);
tmpMeta[0+1] = _source;
tmp1_c2 = _b;
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
_outExpOption = tmpMeta[0+0];
_outSource = tmpMeta[0+1];
_inlined = tmp1_c2;
_return: OMC_LABEL_UNUSED
if (out_outSource) { *out_outSource = _outSource; }
if (out_inlined) { *out_inlined = _inlined; }
return _outExpOption;
}
modelica_metatype boxptr_Inline_inlineExpOpt(threadData_t *threadData, modelica_metatype _inExpOption, modelica_metatype _inElementList, modelica_metatype _inSource, modelica_metatype *out_outSource, modelica_metatype *out_inlined)
{
modelica_boolean _inlined;
modelica_metatype _outExpOption = NULL;
_outExpOption = omc_Inline_inlineExpOpt(threadData, _inExpOption, _inElementList, _inSource, out_outSource, &_inlined);
if (out_inlined) { *out_inlined = mmc_mk_icon(_inlined); }
return _outExpOption;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_inlineElse(threadData_t *threadData, modelica_metatype _inElse, modelica_metatype _inElementList, modelica_metatype _inSource, modelica_metatype *out_outSource, modelica_boolean *out_inlined)
{
modelica_metatype _outElse = NULL;
modelica_metatype _outSource = NULL;
modelica_boolean _inlined;
modelica_boolean tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inElse;
tmp4_2 = _inElementList;
tmp4_3 = _inSource;
{
modelica_metatype _fns = NULL;
modelica_metatype _a_else = NULL;
modelica_metatype _a_else_1 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e_1 = NULL;
modelica_metatype _stmts = NULL;
modelica_metatype _stmts_1 = NULL;
modelica_metatype _source = NULL;
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
modelica_metatype tmpMeta9;
modelica_boolean tmp10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e = tmpMeta6;
_stmts = tmpMeta7;
_a_else = tmpMeta8;
_fns = tmp4_2;
_source = tmp4_3;
tmp4 += 1;
_e_1 = omc_Inline_inlineExp(threadData, _e, _fns, _source ,&_source ,&_b1 ,NULL);
tmpMeta9 = MMC_REFSTRUCTLIT(mmc_nil);
_stmts_1 = omc_Inline_inlineStatements(threadData, _stmts, _fns, tmpMeta9, 0 ,&_b2);
_a_else_1 = omc_Inline_inlineElse(threadData, _a_else, _fns, _source ,&_source ,&_b3);
tmp10 = ((_b1 || _b2) || _b3);
if (1 != tmp10) goto goto_2;
tmpMeta11 = mmc_mk_box4(4, &DAE_Else_ELSEIF__desc, _e_1, _stmts_1, _a_else_1);
tmpMeta[0+0] = tmpMeta11;
tmpMeta[0+1] = _source;
tmp1_c2 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta12;
modelica_boolean tmp13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_stmts = tmpMeta12;
_fns = tmp4_2;
_source = tmp4_3;
tmpMeta14 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta15 = omc_Inline_inlineStatements(threadData, _stmts, _fns, tmpMeta14, 0, &tmp13);
_stmts_1 = tmpMeta15;
if (1 != tmp13) goto goto_2;
tmpMeta16 = mmc_mk_box2(5, &DAE_Else_ELSE__desc, _stmts_1);
tmpMeta[0+0] = tmpMeta16;
tmpMeta[0+1] = _source;
tmp1_c2 = 1;
goto tmp3_done;
}
case 2: {
_a_else = tmp4_1;
_source = tmp4_3;
tmpMeta[0+0] = _a_else;
tmpMeta[0+1] = _source;
tmp1_c2 = 0;
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
_outSource = tmpMeta[0+1];
_inlined = tmp1_c2;
_return: OMC_LABEL_UNUSED
if (out_outSource) { *out_outSource = _outSource; }
if (out_inlined) { *out_inlined = _inlined; }
return _outElse;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Inline_inlineElse(threadData_t *threadData, modelica_metatype _inElse, modelica_metatype _inElementList, modelica_metatype _inSource, modelica_metatype *out_outSource, modelica_metatype *out_inlined)
{
modelica_boolean _inlined;
modelica_metatype _outElse = NULL;
_outElse = omc_Inline_inlineElse(threadData, _inElse, _inElementList, _inSource, out_outSource, &_inlined);
if (out_inlined) { *out_inlined = mmc_mk_icon(_inlined); }
return _outElse;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_inlineStatement(threadData_t *threadData, modelica_metatype _inStatement, modelica_metatype _inElementList, modelica_boolean *out_inlined)
{
modelica_metatype _outStatement = NULL;
modelica_boolean _inlined;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inStatement;
tmp4_2 = _inElementList;
{
modelica_metatype _fns = NULL;
modelica_metatype _stmt = NULL;
modelica_metatype _stmt_1 = NULL;
modelica_metatype _t = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e_1 = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e1_1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e2_1 = NULL;
modelica_metatype _e3 = NULL;
modelica_metatype _e3_1 = NULL;
modelica_metatype _explst = NULL;
modelica_metatype _explst_1 = NULL;
modelica_metatype _a_else = NULL;
modelica_metatype _a_else_1 = NULL;
modelica_metatype _stmts = NULL;
modelica_metatype _stmts_1 = NULL;
modelica_boolean _b;
modelica_boolean _b1;
modelica_boolean _b2;
modelica_boolean _b3;
modelica_string _i = NULL;
modelica_integer _ix;
modelica_metatype _source = NULL;
modelica_metatype _conditions = NULL;
modelica_boolean _initialCall;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 14; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_boolean tmp10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_t = tmpMeta6;
_e1 = tmpMeta7;
_e2 = tmpMeta8;
_source = tmpMeta9;
_fns = tmp4_2;
tmp4 += 12;
_e1_1 = omc_Inline_inlineExp(threadData, _e1, _fns, _source ,&_source ,&_b1 ,NULL);
_e2_1 = omc_Inline_inlineExp(threadData, _e2, _fns, _source ,&_source ,&_b2 ,NULL);
tmp10 = (_b1 || _b2);
if (1 != tmp10) goto goto_2;
tmpMeta11 = mmc_mk_box5(3, &DAE_Statement_STMT__ASSIGN__desc, _t, _e1_1, _e2_1, _source);
tmpMeta[0+0] = tmpMeta11;
tmp1_c1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_boolean tmp16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,4) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_t = tmpMeta12;
_explst = tmpMeta13;
_e = tmpMeta14;
_source = tmpMeta15;
_fns = tmp4_2;
tmp4 += 11;
_explst_1 = omc_Inline_inlineExps(threadData, _explst, _fns, _source ,&_source ,&_b1);
_e_1 = omc_Inline_inlineExp(threadData, _e, _fns, _source ,&_source ,&_b2 ,NULL);
tmp16 = (_b1 || _b2);
if (1 != tmp16) goto goto_2;
tmpMeta17 = mmc_mk_box5(4, &DAE_Statement_STMT__TUPLE__ASSIGN__desc, _t, _explst_1, _e_1, _source);
tmpMeta[0+0] = tmpMeta17;
tmp1_c1 = 1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_boolean tmp22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,4) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_t = tmpMeta18;
_e1 = tmpMeta19;
_e2 = tmpMeta20;
_source = tmpMeta21;
_fns = tmp4_2;
tmp4 += 10;
_e1_1 = omc_Inline_inlineExp(threadData, _e1, _fns, _source ,&_source ,&_b1 ,NULL);
_e2_1 = omc_Inline_inlineExp(threadData, _e2, _fns, _source ,&_source ,&_b2 ,NULL);
tmp22 = (_b1 || _b2);
if (1 != tmp22) goto goto_2;
tmpMeta23 = mmc_mk_box5(5, &DAE_Statement_STMT__ASSIGN__ARR__desc, _t, _e1_1, _e2_1, _source);
tmpMeta[0+0] = tmpMeta23;
tmp1_c1 = 1;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_boolean tmp29;
modelica_metatype tmpMeta30;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,4) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e = tmpMeta24;
_stmts = tmpMeta25;
_a_else = tmpMeta26;
_source = tmpMeta27;
_fns = tmp4_2;
tmp4 += 9;
_e_1 = omc_Inline_inlineExp(threadData, _e, _fns, _source ,&_source ,&_b1 ,NULL);
tmpMeta28 = MMC_REFSTRUCTLIT(mmc_nil);
_stmts_1 = omc_Inline_inlineStatements(threadData, _stmts, _fns, tmpMeta28, 0 ,&_b2);
_a_else_1 = omc_Inline_inlineElse(threadData, _a_else, _fns, _source ,&_source ,&_b3);
tmp29 = ((_b1 || _b2) || _b3);
if (1 != tmp29) goto goto_2;
tmpMeta30 = mmc_mk_box5(6, &DAE_Statement_STMT__IF__desc, _e_1, _stmts_1, _a_else_1, _source);
tmpMeta[0+0] = tmpMeta30;
tmp1_c1 = 1;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_integer tmp33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_integer tmp36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_boolean tmp41;
modelica_metatype tmpMeta42;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,7) == 0) goto tmp3_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp33 = mmc_unbox_integer(tmpMeta32);
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmp36 = mmc_unbox_integer(tmpMeta35);
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_t = tmpMeta31;
_b = tmp33;
_i = tmpMeta34;
_ix = tmp36;
_e = tmpMeta37;
_stmts = tmpMeta38;
_source = tmpMeta39;
_fns = tmp4_2;
tmp4 += 8;
_e_1 = omc_Inline_inlineExp(threadData, _e, _fns, _source ,&_source ,&_b1 ,NULL);
tmpMeta40 = MMC_REFSTRUCTLIT(mmc_nil);
_stmts_1 = omc_Inline_inlineStatements(threadData, _stmts, _fns, tmpMeta40, 0 ,&_b2);
tmp41 = (_b1 || _b2);
if (1 != tmp41) goto goto_2;
tmpMeta42 = mmc_mk_box8(7, &DAE_Statement_STMT__FOR__desc, _t, mmc_mk_boolean(_b), _i, mmc_mk_integer(_ix), _e_1, _stmts_1, _source);
tmpMeta[0+0] = tmpMeta42;
tmp1_c1 = 1;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_boolean tmp47;
modelica_metatype tmpMeta48;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,3) == 0) goto tmp3_end;
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e = tmpMeta43;
_stmts = tmpMeta44;
_source = tmpMeta45;
_fns = tmp4_2;
tmp4 += 7;
_e_1 = omc_Inline_inlineExp(threadData, _e, _fns, _source ,&_source ,&_b1 ,NULL);
tmpMeta46 = MMC_REFSTRUCTLIT(mmc_nil);
_stmts_1 = omc_Inline_inlineStatements(threadData, _stmts, _fns, tmpMeta46, 0 ,&_b2);
tmp47 = (_b1 || _b2);
if (1 != tmp47) goto goto_2;
tmpMeta48 = mmc_mk_box4(9, &DAE_Statement_STMT__WHILE__desc, _e_1, _stmts_1, _source);
tmpMeta[0+0] = tmpMeta48;
tmp1_c1 = 1;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_integer tmp52;
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
modelica_metatype tmpMeta57;
modelica_boolean tmp58;
modelica_metatype tmpMeta59;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,6) == 0) goto tmp3_end;
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmp52 = mmc_unbox_integer(tmpMeta51);
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (optionNone(tmpMeta54)) goto tmp3_end;
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta54), 1));
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
_e = tmpMeta49;
_conditions = tmpMeta50;
_initialCall = tmp52;
_stmts = tmpMeta53;
_stmt = tmpMeta55;
_source = tmpMeta56;
_fns = tmp4_2;
tmp4 += 6;
_e_1 = omc_Inline_inlineExp(threadData, _e, _fns, _source ,&_source ,&_b1 ,NULL);
tmpMeta57 = MMC_REFSTRUCTLIT(mmc_nil);
_stmts_1 = omc_Inline_inlineStatements(threadData, _stmts, _fns, tmpMeta57, 0 ,&_b2);
_stmt_1 = omc_Inline_inlineStatement(threadData, _stmt, _fns ,&_b3);
tmp58 = ((_b1 || _b2) || _b3);
if (1 != tmp58) goto goto_2;
tmpMeta59 = mmc_mk_box7(10, &DAE_Statement_STMT__WHEN__desc, _e_1, _conditions, mmc_mk_boolean(_initialCall), _stmts_1, mmc_mk_some(_stmt_1), _source);
tmpMeta[0+0] = tmpMeta59;
tmp1_c1 = 1;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
modelica_metatype tmpMeta62;
modelica_integer tmp63;
modelica_metatype tmpMeta64;
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
modelica_metatype tmpMeta67;
modelica_boolean tmp68;
modelica_metatype tmpMeta69;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,6) == 0) goto tmp3_end;
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta61 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmp63 = mmc_unbox_integer(tmpMeta62);
tmpMeta64 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (!optionNone(tmpMeta65)) goto tmp3_end;
tmpMeta66 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
_e = tmpMeta60;
_conditions = tmpMeta61;
_initialCall = tmp63;
_stmts = tmpMeta64;
_source = tmpMeta66;
_fns = tmp4_2;
tmp4 += 5;
_e_1 = omc_Inline_inlineExp(threadData, _e, _fns, _source ,&_source ,&_b1 ,NULL);
tmpMeta67 = MMC_REFSTRUCTLIT(mmc_nil);
_stmts_1 = omc_Inline_inlineStatements(threadData, _stmts, _fns, tmpMeta67, 0 ,&_b2);
tmp68 = (_b1 || _b2);
if (1 != tmp68) goto goto_2;
tmpMeta69 = mmc_mk_box7(10, &DAE_Statement_STMT__WHEN__desc, _e_1, _conditions, mmc_mk_boolean(_initialCall), _stmts_1, mmc_mk_none(), _source);
tmpMeta[0+0] = tmpMeta69;
tmp1_c1 = 1;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta70;
modelica_metatype tmpMeta71;
modelica_metatype tmpMeta72;
modelica_metatype tmpMeta73;
modelica_boolean tmp74;
modelica_metatype tmpMeta75;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,4) == 0) goto tmp3_end;
tmpMeta70 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta71 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta72 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta73 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e1 = tmpMeta70;
_e2 = tmpMeta71;
_e3 = tmpMeta72;
_source = tmpMeta73;
_fns = tmp4_2;
tmp4 += 4;
_e1_1 = omc_Inline_inlineExp(threadData, _e1, _fns, _source ,&_source ,&_b1 ,NULL);
_e2_1 = omc_Inline_inlineExp(threadData, _e2, _fns, _source ,&_source ,&_b2 ,NULL);
_e3_1 = omc_Inline_inlineExp(threadData, _e3, _fns, _source ,&_source ,&_b3 ,NULL);
tmp74 = ((_b1 || _b2) || _b3);
if (1 != tmp74) goto goto_2;
tmpMeta75 = mmc_mk_box5(11, &DAE_Statement_STMT__ASSERT__desc, _e1_1, _e2_1, _e3_1, _source);
tmpMeta[0+0] = tmpMeta75;
tmp1_c1 = 1;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta76;
modelica_metatype tmpMeta77;
modelica_metatype tmpMeta78;
modelica_boolean tmp79;
modelica_metatype tmpMeta80;
modelica_metatype tmpMeta81;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,2) == 0) goto tmp3_end;
tmpMeta76 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta77 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmpMeta76;
_source = tmpMeta77;
_fns = tmp4_2;
tmp4 += 3;
tmpMeta80 = omc_Inline_inlineExp(threadData, _e, _fns, _source, &tmpMeta78, &tmp79, NULL);
_e_1 = tmpMeta80;
if (1 != tmp79) goto goto_2;
_source = tmpMeta78;
tmpMeta81 = mmc_mk_box3(12, &DAE_Statement_STMT__TERMINATE__desc, _e_1, _source);
tmpMeta[0+0] = tmpMeta81;
tmp1_c1 = 1;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta82;
modelica_metatype tmpMeta83;
modelica_metatype tmpMeta84;
modelica_boolean tmp85;
modelica_metatype tmpMeta86;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,3) == 0) goto tmp3_end;
tmpMeta82 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta83 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta84 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta82;
_e2 = tmpMeta83;
_source = tmpMeta84;
_fns = tmp4_2;
tmp4 += 2;
_e1_1 = omc_Inline_inlineExp(threadData, _e1, _fns, _source ,&_source ,&_b1 ,NULL);
_e2_1 = omc_Inline_inlineExp(threadData, _e2, _fns, _source ,&_source ,&_b2 ,NULL);
tmp85 = (_b1 || _b2);
if (1 != tmp85) goto goto_2;
tmpMeta86 = mmc_mk_box4(13, &DAE_Statement_STMT__REINIT__desc, _e1_1, _e2_1, _source);
tmpMeta[0+0] = tmpMeta86;
tmp1_c1 = 1;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta87;
modelica_metatype tmpMeta88;
modelica_metatype tmpMeta89;
modelica_boolean tmp90;
modelica_metatype tmpMeta91;
modelica_metatype tmpMeta92;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,2) == 0) goto tmp3_end;
tmpMeta87 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta88 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmpMeta87;
_source = tmpMeta88;
_fns = tmp4_2;
tmp4 += 1;
tmpMeta91 = omc_Inline_inlineExp(threadData, _e, _fns, _source, &tmpMeta89, &tmp90, NULL);
_e_1 = tmpMeta91;
if (1 != tmp90) goto goto_2;
_source = tmpMeta89;
tmpMeta92 = mmc_mk_box3(14, &DAE_Statement_STMT__NORETCALL__desc, _e_1, _source);
tmpMeta[0+0] = tmpMeta92;
tmp1_c1 = 1;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta93;
modelica_metatype tmpMeta94;
modelica_boolean tmp95;
modelica_metatype tmpMeta96;
modelica_metatype tmpMeta97;
modelica_metatype tmpMeta98;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,2) == 0) goto tmp3_end;
tmpMeta93 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta94 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_stmts = tmpMeta93;
_source = tmpMeta94;
_fns = tmp4_2;
tmpMeta96 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta97 = omc_Inline_inlineStatements(threadData, _stmts, _fns, tmpMeta96, 0, &tmp95);
_stmts_1 = tmpMeta97;
if (1 != tmp95) goto goto_2;
tmpMeta98 = mmc_mk_box3(19, &DAE_Statement_STMT__FAILURE__desc, _stmts_1, _source);
tmpMeta[0+0] = tmpMeta98;
tmp1_c1 = 1;
goto tmp3_done;
}
case 13: {
_stmt = tmp4_1;
tmpMeta[0+0] = _stmt;
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
if (++tmp4 < 14) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outStatement = tmpMeta[0+0];
_inlined = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_inlined) { *out_inlined = _inlined; }
return _outStatement;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Inline_inlineStatement(threadData_t *threadData, modelica_metatype _inStatement, modelica_metatype _inElementList, modelica_metatype *out_inlined)
{
modelica_boolean _inlined;
modelica_metatype _outStatement = NULL;
_outStatement = omc_Inline_inlineStatement(threadData, _inStatement, _inElementList, &_inlined);
if (out_inlined) { *out_inlined = mmc_mk_icon(_inlined); }
return _outStatement;
}
DLLExport
modelica_metatype omc_Inline_inlineStatements(threadData_t *threadData, modelica_metatype _inStatements, modelica_metatype _inElementList, modelica_metatype _iAcc, modelica_boolean _iInlined, modelica_boolean *out_OInlined)
{
modelica_metatype _outStatements = NULL;
modelica_boolean _OInlined;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inStatements;
{
modelica_metatype _stmt = NULL;
modelica_metatype _rest = NULL;
modelica_boolean _inlined;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0+0] = listReverse(_iAcc);
tmp1_c1 = _iInlined;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_stmt = tmpMeta6;
_rest = tmpMeta7;
_stmt = omc_Inline_inlineStatement(threadData, _stmt, _inElementList ,&_inlined);
tmpMeta8 = mmc_mk_cons(_stmt, _iAcc);
_inStatements = _rest;
_iAcc = tmpMeta8;
_iInlined = (_inlined || _iInlined);
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
_outStatements = tmpMeta[0+0];
_OInlined = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_OInlined) { *out_OInlined = _OInlined; }
return _outStatements;
}
modelica_metatype boxptr_Inline_inlineStatements(threadData_t *threadData, modelica_metatype _inStatements, modelica_metatype _inElementList, modelica_metatype _iAcc, modelica_metatype _iInlined, modelica_metatype *out_OInlined)
{
modelica_integer tmp1;
modelica_boolean _OInlined;
modelica_metatype _outStatements = NULL;
tmp1 = mmc_unbox_integer(_iInlined);
_outStatements = omc_Inline_inlineStatements(threadData, _inStatements, _inElementList, _iAcc, tmp1, &_OInlined);
if (out_OInlined) { *out_OInlined = mmc_mk_icon(_OInlined); }
return _outStatements;
}
DLLExport
modelica_metatype omc_Inline_inlineAlgorithm(threadData_t *threadData, modelica_metatype _inAlgorithm, modelica_metatype _inElementList, modelica_boolean *out_inlined)
{
modelica_metatype _outAlgorithm = NULL;
modelica_boolean _inlined;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inAlgorithm;
tmp4_2 = _inElementList;
{
modelica_metatype _stmts = NULL;
modelica_metatype _stmts_1 = NULL;
modelica_metatype _fns = NULL;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_stmts = tmpMeta6;
_fns = tmp4_2;
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
_stmts_1 = omc_Inline_inlineStatements(threadData, _stmts, _fns, tmpMeta7, 0 ,&_inlined);
tmpMeta8 = mmc_mk_box2(3, &DAE_Algorithm_ALGORITHM__STMTS__desc, _stmts_1);
tmpMeta[0+0] = tmpMeta8;
tmp1_c1 = _inlined;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp9;
tmp9 = omc_Flags_isSet(threadData, _OMC_LIT21);
if (1 != tmp9) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT42);
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
_outAlgorithm = tmpMeta[0+0];
_inlined = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_inlined) { *out_inlined = _inlined; }
return _outAlgorithm;
}
modelica_metatype boxptr_Inline_inlineAlgorithm(threadData_t *threadData, modelica_metatype _inAlgorithm, modelica_metatype _inElementList, modelica_metatype *out_inlined)
{
modelica_boolean _inlined;
modelica_metatype _outAlgorithm = NULL;
_outAlgorithm = omc_Inline_inlineAlgorithm(threadData, _inAlgorithm, _inElementList, &_inlined);
if (out_inlined) { *out_inlined = mmc_mk_icon(_inlined); }
return _outAlgorithm;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_inlineDAEElement(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inFunctions, modelica_boolean *out_inlined)
{
modelica_metatype _outElement = NULL;
modelica_boolean _inlined;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inElement;
tmp4_2 = _inFunctions;
{
modelica_metatype _fns = NULL;
modelica_metatype _elist = NULL;
modelica_metatype _elist_1 = NULL;
modelica_metatype _dlist = NULL;
modelica_metatype _dlist_1 = NULL;
modelica_metatype _el = NULL;
modelica_metatype _el_1 = NULL;
modelica_metatype _componentRef = NULL;
modelica_metatype _kind = NULL;
modelica_metatype _direction = NULL;
modelica_metatype _parallelism = NULL;
modelica_metatype _protection = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _binding = NULL;
modelica_metatype _binding_1 = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _exp_1 = NULL;
modelica_metatype _exp1 = NULL;
modelica_metatype _exp1_1 = NULL;
modelica_metatype _exp2 = NULL;
modelica_metatype _exp2_1 = NULL;
modelica_metatype _exp3 = NULL;
modelica_metatype _exp3_1 = NULL;
modelica_metatype _dims = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _variableAttributesOption = NULL;
modelica_metatype _absynCommentOption = NULL;
modelica_metatype _innerOuter = NULL;
modelica_metatype _dimension = NULL;
modelica_metatype _alg = NULL;
modelica_metatype _alg_1 = NULL;
modelica_string _i = NULL;
modelica_metatype _explst = NULL;
modelica_metatype _explst_1 = NULL;
modelica_metatype _source = NULL;
modelica_boolean _b1;
modelica_boolean _b2;
modelica_boolean _b3;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 24; tmp4++) {
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
modelica_boolean tmp21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
if (optionNone(tmpMeta12)) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 1));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 9));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 10));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 11));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 12));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 13));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 14));
_componentRef = tmpMeta6;
_kind = tmpMeta7;
_direction = tmpMeta8;
_parallelism = tmpMeta9;
_protection = tmpMeta10;
_ty = tmpMeta11;
_binding = tmpMeta13;
_dims = tmpMeta14;
_ct = tmpMeta15;
_source = tmpMeta16;
_variableAttributesOption = tmpMeta17;
_absynCommentOption = tmpMeta18;
_innerOuter = tmpMeta19;
_fns = tmp4_2;
tmp4 += 22;
tmpMeta22 = omc_Inline_inlineExp(threadData, _binding, _fns, _source, &tmpMeta20, &tmp21, NULL);
_binding_1 = tmpMeta22;
if (1 != tmp21) goto goto_2;
_source = tmpMeta20;
tmpMeta23 = mmc_mk_box14(3, &DAE_Element_VAR__desc, _componentRef, _kind, _direction, _parallelism, _protection, _ty, mmc_mk_some(_binding_1), _dims, _ct, _source, _variableAttributesOption, _absynCommentOption, _innerOuter);
tmpMeta[0+0] = tmpMeta23;
tmp1_c1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_boolean tmp28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_componentRef = tmpMeta24;
_exp = tmpMeta25;
_source = tmpMeta26;
_fns = tmp4_2;
tmp4 += 21;
tmpMeta29 = omc_Inline_inlineExp(threadData, _exp, _fns, _source, &tmpMeta27, &tmp28, NULL);
_exp_1 = tmpMeta29;
if (1 != tmp28) goto goto_2;
_source = tmpMeta27;
tmpMeta30 = mmc_mk_box4(4, &DAE_Element_DEFINE__desc, _componentRef, _exp_1, _source);
tmpMeta[0+0] = tmpMeta30;
tmp1_c1 = 1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_boolean tmp35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,3) == 0) goto tmp3_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_componentRef = tmpMeta31;
_exp = tmpMeta32;
_source = tmpMeta33;
_fns = tmp4_2;
tmp4 += 20;
tmpMeta36 = omc_Inline_inlineExp(threadData, _exp, _fns, _source, &tmpMeta34, &tmp35, NULL);
_exp_1 = tmpMeta36;
if (1 != tmp35) goto goto_2;
_source = tmpMeta34;
tmpMeta37 = mmc_mk_box4(5, &DAE_Element_INITIALDEFINE__desc, _componentRef, _exp_1, _source);
tmpMeta[0+0] = tmpMeta37;
tmp1_c1 = 1;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_boolean tmp41;
modelica_metatype tmpMeta42;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,3) == 0) goto tmp3_end;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_exp1 = tmpMeta38;
_exp2 = tmpMeta39;
_source = tmpMeta40;
_fns = tmp4_2;
tmp4 += 19;
_exp1_1 = omc_Inline_inlineExp(threadData, _exp1, _fns, _source ,&_source ,&_b1 ,NULL);
_exp2_1 = omc_Inline_inlineExp(threadData, _exp2, _fns, _source ,&_source ,&_b2 ,NULL);
tmp41 = (_b1 || _b2);
if (1 != tmp41) goto goto_2;
tmpMeta42 = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp1_1, _exp2_1, _source);
tmpMeta[0+0] = tmpMeta42;
tmp1_c1 = 1;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_boolean tmp47;
modelica_metatype tmpMeta48;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,4) == 0) goto tmp3_end;
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_dimension = tmpMeta43;
_exp1 = tmpMeta44;
_exp2 = tmpMeta45;
_source = tmpMeta46;
_fns = tmp4_2;
tmp4 += 18;
_exp1_1 = omc_Inline_inlineExp(threadData, _exp1, _fns, _source ,&_source ,&_b1 ,NULL);
_exp2_1 = omc_Inline_inlineExp(threadData, _exp2, _fns, _source ,&_source ,&_b2 ,NULL);
tmp47 = (_b1 || _b2);
if (1 != tmp47) goto goto_2;
tmpMeta48 = mmc_mk_box5(8, &DAE_Element_ARRAY__EQUATION__desc, _dimension, _exp1_1, _exp2_1, _source);
tmpMeta[0+0] = tmpMeta48;
tmp1_c1 = 1;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
modelica_boolean tmp53;
modelica_metatype tmpMeta54;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,4) == 0) goto tmp3_end;
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_dimension = tmpMeta49;
_exp1 = tmpMeta50;
_exp2 = tmpMeta51;
_source = tmpMeta52;
_fns = tmp4_2;
tmp4 += 17;
_exp1_1 = omc_Inline_inlineExp(threadData, _exp1, _fns, _source ,&_source ,&_b1 ,NULL);
_exp2_1 = omc_Inline_inlineExp(threadData, _exp2, _fns, _source ,&_source ,&_b2 ,NULL);
tmp53 = (_b1 || _b2);
if (1 != tmp53) goto goto_2;
tmpMeta54 = mmc_mk_box5(9, &DAE_Element_INITIAL__ARRAY__EQUATION__desc, _dimension, _exp1_1, _exp2_1, _source);
tmpMeta[0+0] = tmpMeta54;
tmp1_c1 = 1;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
modelica_metatype tmpMeta57;
modelica_boolean tmp58;
modelica_metatype tmpMeta59;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,3) == 0) goto tmp3_end;
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_exp1 = tmpMeta55;
_exp2 = tmpMeta56;
_source = tmpMeta57;
_fns = tmp4_2;
tmp4 += 16;
_exp1_1 = omc_Inline_inlineExp(threadData, _exp1, _fns, _source ,&_source ,&_b1 ,NULL);
_exp2_1 = omc_Inline_inlineExp(threadData, _exp2, _fns, _source ,&_source ,&_b2 ,NULL);
tmp58 = (_b1 || _b2);
if (1 != tmp58) goto goto_2;
tmpMeta59 = mmc_mk_box4(11, &DAE_Element_COMPLEX__EQUATION__desc, _exp1_1, _exp2_1, _source);
tmpMeta[0+0] = tmpMeta59;
tmp1_c1 = 1;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
modelica_metatype tmpMeta62;
modelica_boolean tmp63;
modelica_metatype tmpMeta64;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta61 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_exp1 = tmpMeta60;
_exp2 = tmpMeta61;
_source = tmpMeta62;
_fns = tmp4_2;
tmp4 += 15;
_exp1_1 = omc_Inline_inlineExp(threadData, _exp1, _fns, _source ,&_source ,&_b1 ,NULL);
_exp2_1 = omc_Inline_inlineExp(threadData, _exp2, _fns, _source ,&_source ,&_b2 ,NULL);
tmp63 = (_b1 || _b2);
if (1 != tmp63) goto goto_2;
tmpMeta64 = mmc_mk_box4(12, &DAE_Element_INITIAL__COMPLEX__EQUATION__desc, _exp1_1, _exp2_1, _source);
tmpMeta[0+0] = tmpMeta64;
tmp1_c1 = 1;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
modelica_metatype tmpMeta67;
modelica_metatype tmpMeta68;
modelica_metatype tmpMeta69;
modelica_metatype tmpMeta70;
modelica_boolean tmp71;
modelica_metatype tmpMeta72;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta66 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta67 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (optionNone(tmpMeta67)) goto tmp3_end;
tmpMeta68 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta67), 1));
tmpMeta69 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_exp = tmpMeta65;
_elist = tmpMeta66;
_el = tmpMeta68;
_source = tmpMeta69;
_fns = tmp4_2;
tmp4 += 14;
_exp_1 = omc_Inline_inlineExp(threadData, _exp, _fns, _source ,&_source ,&_b1 ,NULL);
tmpMeta70 = MMC_REFSTRUCTLIT(mmc_nil);
_elist_1 = omc_Inline_inlineDAEElements(threadData, _elist, _fns, tmpMeta70, 0 ,&_b2);
_el_1 = omc_Inline_inlineDAEElement(threadData, _el, _fns ,&_b3);
tmp71 = ((_b1 || _b2) || _b3);
if (1 != tmp71) goto goto_2;
tmpMeta72 = mmc_mk_box5(13, &DAE_Element_WHEN__EQUATION__desc, _exp_1, _elist_1, mmc_mk_some(_el_1), _source);
tmpMeta[0+0] = tmpMeta72;
tmp1_c1 = 1;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta73;
modelica_metatype tmpMeta74;
modelica_metatype tmpMeta75;
modelica_metatype tmpMeta76;
modelica_metatype tmpMeta77;
modelica_boolean tmp78;
modelica_metatype tmpMeta79;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta73 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta74 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta75 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!optionNone(tmpMeta75)) goto tmp3_end;
tmpMeta76 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_exp = tmpMeta73;
_elist = tmpMeta74;
_source = tmpMeta76;
_fns = tmp4_2;
tmp4 += 13;
_exp_1 = omc_Inline_inlineExp(threadData, _exp, _fns, _source ,&_source ,&_b1 ,NULL);
tmpMeta77 = MMC_REFSTRUCTLIT(mmc_nil);
_elist_1 = omc_Inline_inlineDAEElements(threadData, _elist, _fns, tmpMeta77, 0 ,&_b2);
tmp78 = (_b1 || _b2);
if (1 != tmp78) goto goto_2;
tmpMeta79 = mmc_mk_box5(13, &DAE_Element_WHEN__EQUATION__desc, _exp_1, _elist_1, mmc_mk_none(), _source);
tmpMeta[0+0] = tmpMeta79;
tmp1_c1 = 1;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta80;
modelica_metatype tmpMeta81;
modelica_metatype tmpMeta82;
modelica_metatype tmpMeta83;
modelica_metatype tmpMeta84;
modelica_metatype tmpMeta85;
modelica_boolean tmp86;
modelica_metatype tmpMeta87;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,4) == 0) goto tmp3_end;
tmpMeta80 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta81 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta82 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta83 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_explst = tmpMeta80;
_dlist = tmpMeta81;
_elist = tmpMeta82;
_source = tmpMeta83;
_fns = tmp4_2;
tmp4 += 12;
_explst_1 = omc_Inline_inlineExps(threadData, _explst, _fns, _source ,&_source ,&_b1);
tmpMeta84 = MMC_REFSTRUCTLIT(mmc_nil);
_dlist_1 = omc_Inline_inlineDAEElementsLst(threadData, _dlist, _fns, tmpMeta84, 0 ,&_b2);
tmpMeta85 = MMC_REFSTRUCTLIT(mmc_nil);
_elist_1 = omc_Inline_inlineDAEElements(threadData, _elist, _fns, tmpMeta85, 0 ,&_b3);
tmp86 = ((_b1 || _b2) || _b3);
if (1 != tmp86) goto goto_2;
tmpMeta87 = mmc_mk_box5(15, &DAE_Element_IF__EQUATION__desc, _explst_1, _dlist_1, _elist_1, _source);
tmpMeta[0+0] = tmpMeta87;
tmp1_c1 = 1;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta88;
modelica_metatype tmpMeta89;
modelica_metatype tmpMeta90;
modelica_metatype tmpMeta91;
modelica_metatype tmpMeta92;
modelica_metatype tmpMeta93;
modelica_boolean tmp94;
modelica_metatype tmpMeta95;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,4) == 0) goto tmp3_end;
tmpMeta88 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta89 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta90 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta91 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_explst = tmpMeta88;
_dlist = tmpMeta89;
_elist = tmpMeta90;
_source = tmpMeta91;
_fns = tmp4_2;
tmp4 += 11;
_explst_1 = omc_Inline_inlineExps(threadData, _explst, _fns, _source ,&_source ,&_b1);
tmpMeta92 = MMC_REFSTRUCTLIT(mmc_nil);
_dlist_1 = omc_Inline_inlineDAEElementsLst(threadData, _dlist, _fns, tmpMeta92, 0 ,&_b2);
tmpMeta93 = MMC_REFSTRUCTLIT(mmc_nil);
_elist_1 = omc_Inline_inlineDAEElements(threadData, _elist, _fns, tmpMeta93, 0 ,&_b3);
tmp94 = ((_b1 || _b2) || _b3);
if (1 != tmp94) goto goto_2;
tmpMeta95 = mmc_mk_box5(16, &DAE_Element_INITIAL__IF__EQUATION__desc, _explst_1, _dlist_1, _elist_1, _source);
tmpMeta[0+0] = tmpMeta95;
tmp1_c1 = 1;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta96;
modelica_metatype tmpMeta97;
modelica_metatype tmpMeta98;
modelica_metatype tmpMeta99;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,14,3) == 0) goto tmp3_end;
tmpMeta96 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta97 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta98 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_exp1 = tmpMeta96;
_exp2 = tmpMeta97;
_source = tmpMeta98;
_fns = tmp4_2;
tmp4 += 10;
_exp1_1 = omc_Inline_inlineExp(threadData, _exp1, _fns, _source ,&_source ,NULL ,NULL);
_exp2_1 = omc_Inline_inlineExp(threadData, _exp2, _fns, _source ,&_source ,NULL ,NULL);
tmpMeta99 = mmc_mk_box4(17, &DAE_Element_INITIALEQUATION__desc, _exp1_1, _exp2_1, _source);
tmpMeta[0+0] = tmpMeta99;
tmp1_c1 = 1;
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta100;
modelica_metatype tmpMeta101;
modelica_boolean tmp102;
modelica_metatype tmpMeta103;
modelica_metatype tmpMeta104;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,2) == 0) goto tmp3_end;
tmpMeta100 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta101 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_alg = tmpMeta100;
_source = tmpMeta101;
_fns = tmp4_2;
tmp4 += 9;
tmpMeta103 = omc_Inline_inlineAlgorithm(threadData, _alg, _fns, &tmp102);
_alg_1 = tmpMeta103;
if (1 != tmp102) goto goto_2;
tmpMeta104 = mmc_mk_box3(18, &DAE_Element_ALGORITHM__desc, _alg_1, _source);
tmpMeta[0+0] = tmpMeta104;
tmp1_c1 = 1;
goto tmp3_done;
}
case 14: {
modelica_metatype tmpMeta105;
modelica_metatype tmpMeta106;
modelica_boolean tmp107;
modelica_metatype tmpMeta108;
modelica_metatype tmpMeta109;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,2) == 0) goto tmp3_end;
tmpMeta105 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta106 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_alg = tmpMeta105;
_source = tmpMeta106;
_fns = tmp4_2;
tmp4 += 8;
tmpMeta108 = omc_Inline_inlineAlgorithm(threadData, _alg, _fns, &tmp107);
_alg_1 = tmpMeta108;
if (1 != tmp107) goto goto_2;
tmpMeta109 = mmc_mk_box3(19, &DAE_Element_INITIALALGORITHM__desc, _alg_1, _source);
tmpMeta[0+0] = tmpMeta109;
tmp1_c1 = 1;
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta110;
modelica_metatype tmpMeta111;
modelica_metatype tmpMeta112;
modelica_metatype tmpMeta113;
modelica_boolean tmp114;
modelica_metatype tmpMeta115;
modelica_metatype tmpMeta116;
modelica_metatype tmpMeta117;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,4) == 0) goto tmp3_end;
tmpMeta110 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta111 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta112 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta113 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_i = tmpMeta110;
_elist = tmpMeta111;
_source = tmpMeta112;
_absynCommentOption = tmpMeta113;
_fns = tmp4_2;
tmp4 += 7;
tmpMeta115 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta116 = omc_Inline_inlineDAEElements(threadData, _elist, _fns, tmpMeta115, 0, &tmp114);
_elist_1 = tmpMeta116;
if (1 != tmp114) goto goto_2;
tmpMeta117 = mmc_mk_box5(20, &DAE_Element_COMP__desc, _i, _elist_1, _source, _absynCommentOption);
tmpMeta[0+0] = tmpMeta117;
tmp1_c1 = 1;
goto tmp3_done;
}
case 16: {
modelica_metatype tmpMeta118;
modelica_metatype tmpMeta119;
modelica_metatype tmpMeta120;
modelica_metatype tmpMeta121;
modelica_boolean tmp122;
modelica_metatype tmpMeta123;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,19,4) == 0) goto tmp3_end;
tmpMeta118 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta119 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta120 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta121 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_exp1 = tmpMeta118;
_exp2 = tmpMeta119;
_exp3 = tmpMeta120;
_source = tmpMeta121;
_fns = tmp4_2;
tmp4 += 6;
_exp1_1 = omc_Inline_inlineExp(threadData, _exp1, _fns, _source ,&_source ,&_b1 ,NULL);
_exp2_1 = omc_Inline_inlineExp(threadData, _exp2, _fns, _source ,&_source ,&_b2 ,NULL);
_exp3_1 = omc_Inline_inlineExp(threadData, _exp3, _fns, _source ,&_source ,&_b3 ,NULL);
tmp122 = ((_b1 || _b2) || _b3);
if (1 != tmp122) goto goto_2;
tmpMeta123 = mmc_mk_box5(22, &DAE_Element_ASSERT__desc, _exp1_1, _exp2_1, _exp3_1, _source);
tmpMeta[0+0] = tmpMeta123;
tmp1_c1 = 1;
goto tmp3_done;
}
case 17: {
modelica_metatype tmpMeta124;
modelica_metatype tmpMeta125;
modelica_metatype tmpMeta126;
modelica_metatype tmpMeta127;
modelica_boolean tmp128;
modelica_metatype tmpMeta129;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,20,4) == 0) goto tmp3_end;
tmpMeta124 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta125 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta126 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta127 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_exp1 = tmpMeta124;
_exp2 = tmpMeta125;
_exp3 = tmpMeta126;
_source = tmpMeta127;
_fns = tmp4_2;
tmp4 += 5;
_exp1_1 = omc_Inline_inlineExp(threadData, _exp1, _fns, _source ,&_source ,&_b1 ,NULL);
_exp2_1 = omc_Inline_inlineExp(threadData, _exp2, _fns, _source ,&_source ,&_b2 ,NULL);
_exp3_1 = omc_Inline_inlineExp(threadData, _exp3, _fns, _source ,&_source ,&_b3 ,NULL);
tmp128 = ((_b1 || _b2) || _b3);
if (1 != tmp128) goto goto_2;
tmpMeta129 = mmc_mk_box5(23, &DAE_Element_INITIAL__ASSERT__desc, _exp1_1, _exp2_1, _exp3_1, _source);
tmpMeta[0+0] = tmpMeta129;
tmp1_c1 = 1;
goto tmp3_done;
}
case 18: {
modelica_metatype tmpMeta130;
modelica_metatype tmpMeta131;
modelica_metatype tmpMeta132;
modelica_boolean tmp133;
modelica_metatype tmpMeta134;
modelica_metatype tmpMeta135;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,2) == 0) goto tmp3_end;
tmpMeta130 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta131 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_exp = tmpMeta130;
_source = tmpMeta131;
_fns = tmp4_2;
tmp4 += 4;
tmpMeta134 = omc_Inline_inlineExp(threadData, _exp, _fns, _source, &tmpMeta132, &tmp133, NULL);
_exp_1 = tmpMeta134;
if (1 != tmp133) goto goto_2;
_source = tmpMeta132;
tmpMeta135 = mmc_mk_box3(24, &DAE_Element_TERMINATE__desc, _exp_1, _source);
tmpMeta[0+0] = tmpMeta135;
tmp1_c1 = 1;
goto tmp3_done;
}
case 19: {
modelica_metatype tmpMeta136;
modelica_metatype tmpMeta137;
modelica_metatype tmpMeta138;
modelica_boolean tmp139;
modelica_metatype tmpMeta140;
modelica_metatype tmpMeta141;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,2) == 0) goto tmp3_end;
tmpMeta136 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta137 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_exp = tmpMeta136;
_source = tmpMeta137;
_fns = tmp4_2;
tmp4 += 3;
tmpMeta140 = omc_Inline_inlineExp(threadData, _exp, _fns, _source, &tmpMeta138, &tmp139, NULL);
_exp_1 = tmpMeta140;
if (1 != tmp139) goto goto_2;
_source = tmpMeta138;
tmpMeta141 = mmc_mk_box3(25, &DAE_Element_INITIAL__TERMINATE__desc, _exp_1, _source);
tmpMeta[0+0] = tmpMeta141;
tmp1_c1 = 1;
goto tmp3_done;
}
case 20: {
modelica_metatype tmpMeta142;
modelica_metatype tmpMeta143;
modelica_metatype tmpMeta144;
modelica_metatype tmpMeta145;
modelica_boolean tmp146;
modelica_metatype tmpMeta147;
modelica_metatype tmpMeta148;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,23,3) == 0) goto tmp3_end;
tmpMeta142 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta143 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta144 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_componentRef = tmpMeta142;
_exp = tmpMeta143;
_source = tmpMeta144;
_fns = tmp4_2;
tmp4 += 2;
tmpMeta147 = omc_Inline_inlineExp(threadData, _exp, _fns, _source, &tmpMeta145, &tmp146, NULL);
_exp_1 = tmpMeta147;
if (1 != tmp146) goto goto_2;
_source = tmpMeta145;
tmpMeta148 = mmc_mk_box4(26, &DAE_Element_REINIT__desc, _componentRef, _exp_1, _source);
tmpMeta[0+0] = tmpMeta148;
tmp1_c1 = 1;
goto tmp3_done;
}
case 21: {
modelica_metatype tmpMeta149;
modelica_metatype tmpMeta150;
modelica_metatype tmpMeta151;
modelica_boolean tmp152;
modelica_metatype tmpMeta153;
modelica_metatype tmpMeta154;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,2) == 0) goto tmp3_end;
tmpMeta149 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta150 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_exp = tmpMeta149;
_source = tmpMeta150;
_fns = tmp4_2;
tmp4 += 1;
tmpMeta153 = omc_Inline_inlineExp(threadData, _exp, _fns, _source, &tmpMeta151, &tmp152, NULL);
_exp = tmpMeta153;
if (1 != tmp152) goto goto_2;
_source = tmpMeta151;
tmpMeta154 = mmc_mk_box3(27, &DAE_Element_NORETCALL__desc, _exp, _source);
tmpMeta[0+0] = tmpMeta154;
tmp1_c1 = 1;
goto tmp3_done;
}
case 22: {
modelica_metatype tmpMeta155;
modelica_metatype tmpMeta156;
modelica_metatype tmpMeta157;
modelica_boolean tmp158;
modelica_metatype tmpMeta159;
modelica_metatype tmpMeta160;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,25,2) == 0) goto tmp3_end;
tmpMeta155 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta156 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_exp = tmpMeta155;
_source = tmpMeta156;
_fns = tmp4_2;
tmpMeta159 = omc_Inline_inlineExp(threadData, _exp, _fns, _source, &tmpMeta157, &tmp158, NULL);
_exp = tmpMeta159;
if (1 != tmp158) goto goto_2;
_source = tmpMeta157;
tmpMeta160 = mmc_mk_box3(28, &DAE_Element_INITIAL__NORETCALL__desc, _exp, _source);
tmpMeta[0+0] = tmpMeta160;
tmp1_c1 = 1;
goto tmp3_done;
}
case 23: {
_el = tmp4_1;
tmpMeta[0+0] = _el;
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
if (++tmp4 < 24) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outElement = tmpMeta[0+0];
_inlined = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_inlined) { *out_inlined = _inlined; }
return _outElement;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Inline_inlineDAEElement(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inFunctions, modelica_metatype *out_inlined)
{
modelica_boolean _inlined;
modelica_metatype _outElement = NULL;
_outElement = omc_Inline_inlineDAEElement(threadData, _inElement, _inFunctions, &_inlined);
if (out_inlined) { *out_inlined = mmc_mk_icon(_inlined); }
return _outElement;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_inlineDAEElements(threadData_t *threadData, modelica_metatype _inElementList, modelica_metatype _inFunctions, modelica_metatype _iAcc, modelica_boolean _iInlined, modelica_boolean *out_OInlined)
{
modelica_metatype _outElementList = NULL;
modelica_boolean _OInlined;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElementList;
{
modelica_metatype _elem = NULL;
modelica_metatype _rest = NULL;
modelica_boolean _inlined;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0+0] = listReverse(_iAcc);
tmp1_c1 = _iInlined;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_elem = tmpMeta6;
_rest = tmpMeta7;
_elem = omc_Inline_inlineDAEElement(threadData, _elem, _inFunctions ,&_inlined);
tmpMeta8 = mmc_mk_cons(_elem, _iAcc);
_inElementList = _rest;
_iAcc = tmpMeta8;
_iInlined = (_inlined || _iInlined);
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
_outElementList = tmpMeta[0+0];
_OInlined = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_OInlined) { *out_OInlined = _OInlined; }
return _outElementList;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Inline_inlineDAEElements(threadData_t *threadData, modelica_metatype _inElementList, modelica_metatype _inFunctions, modelica_metatype _iAcc, modelica_metatype _iInlined, modelica_metatype *out_OInlined)
{
modelica_integer tmp1;
modelica_boolean _OInlined;
modelica_metatype _outElementList = NULL;
tmp1 = mmc_unbox_integer(_iInlined);
_outElementList = omc_Inline_inlineDAEElements(threadData, _inElementList, _inFunctions, _iAcc, tmp1, &_OInlined);
if (out_OInlined) { *out_OInlined = mmc_mk_icon(_OInlined); }
return _outElementList;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_inlineDAEElementsLst(threadData_t *threadData, modelica_metatype _inElementList, modelica_metatype _inFunctions, modelica_metatype _iAcc, modelica_boolean _iInlined, modelica_boolean *out_OInlined)
{
modelica_metatype _outElementList = NULL;
modelica_boolean _OInlined;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElementList;
{
modelica_metatype _elem = NULL;
modelica_metatype _rest = NULL;
modelica_boolean _inlined;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0+0] = listReverse(_iAcc);
tmp1_c1 = _iInlined;
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
_elem = tmpMeta6;
_rest = tmpMeta7;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
_elem = omc_Inline_inlineDAEElements(threadData, _elem, _inFunctions, tmpMeta8, 0 ,&_inlined);
tmpMeta9 = mmc_mk_cons(_elem, _iAcc);
_inElementList = _rest;
_iAcc = tmpMeta9;
_iInlined = (_inlined || _iInlined);
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
_outElementList = tmpMeta[0+0];
_OInlined = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_OInlined) { *out_OInlined = _OInlined; }
return _outElementList;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Inline_inlineDAEElementsLst(threadData_t *threadData, modelica_metatype _inElementList, modelica_metatype _inFunctions, modelica_metatype _iAcc, modelica_metatype _iInlined, modelica_metatype *out_OInlined)
{
modelica_integer tmp1;
modelica_boolean _OInlined;
modelica_metatype _outElementList = NULL;
tmp1 = mmc_unbox_integer(_iInlined);
_outElementList = omc_Inline_inlineDAEElementsLst(threadData, _inElementList, _inFunctions, _iAcc, tmp1, &_OInlined);
if (out_OInlined) { *out_OInlined = mmc_mk_icon(_OInlined); }
return _outElementList;
}
DLLExport
modelica_metatype omc_Inline_inlineCallsInFunctions(threadData_t *threadData, modelica_metatype _inElementList, modelica_metatype _inFunctions)
{
modelica_metatype _outElementList = NULL;
modelica_metatype _body = NULL;
modelica_metatype _ext_decl = NULL;
modelica_metatype _fn_def = NULL;
modelica_metatype _fn_defs = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar7;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype __omcQ_24tmpVar6;
modelica_integer tmp27;
modelica_metatype _fn_loopVar = 0;
modelica_metatype _fn;
_fn_loopVar = _inElementList;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar7 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar7;
while(1) {
tmp27 = 1;
if (!listEmpty(_fn_loopVar)) {
_fn = MMC_CAR(_fn_loopVar);
_fn_loopVar = MMC_CDR(_fn_loopVar);
tmp27--;
}
if (tmp27 == 0) {
{
volatile modelica_metatype tmp7_1;
tmp7_1 = _fn;
{
volatile mmc_switch_type tmp7;
int tmp8;
tmp7 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp6_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp7 < 3; tmp7++) {
switch (MMC_SWITCH_CAST(tmp7)) {
case 0: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_boolean tmp12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,0,10) == 0) goto tmp6_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
if (listEmpty(tmpMeta9)) goto tmp6_end;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,0,1) == 0) goto tmp6_end;
_fn_def = tmpMeta10;
_fn_defs = tmpMeta11;
tmp7 += 1;
tmpMeta13 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta14 = omc_Inline_inlineDAEElements(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn_def), 2))), _inFunctions, tmpMeta13, 0, &tmp12);
_body = tmpMeta14;
if (1 != tmp12) goto goto_5;
tmpMeta15 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta15), MMC_UNTAGPTR(_fn_def), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta15))[2] = _body;
_fn_def = tmpMeta15;
tmpMeta17 = mmc_mk_cons(_fn_def, _fn_defs);
tmpMeta16 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta16), MMC_UNTAGPTR(_fn), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta16))[3] = tmpMeta17;
_fn = tmpMeta16;
tmpMeta4 = _fn;
goto tmp6_done;
}
case 1: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_boolean tmp21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,0,10) == 0) goto tmp6_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
if (listEmpty(tmpMeta18)) goto tmp6_end;
tmpMeta19 = MMC_CAR(tmpMeta18);
tmpMeta20 = MMC_CDR(tmpMeta18);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta19,1,2) == 0) goto tmp6_end;
_fn_def = tmpMeta19;
_fn_defs = tmpMeta20;
tmpMeta22 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta23 = omc_Inline_inlineDAEElements(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn_def), 2))), _inFunctions, tmpMeta22, 0, &tmp21);
_body = tmpMeta23;
if (1 != tmp21) goto goto_5;
tmpMeta24 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta24), MMC_UNTAGPTR(_fn_def), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta24))[2] = _body;
_fn_def = tmpMeta24;
tmpMeta26 = mmc_mk_cons(_fn_def, _fn_defs);
tmpMeta25 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta25), MMC_UNTAGPTR(_fn), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta25))[3] = tmpMeta26;
_fn = tmpMeta25;
tmpMeta4 = _fn;
goto tmp6_done;
}
case 2: {
tmpMeta4 = _fn;
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
if (++tmp7 < 3) {
goto tmp6_top;
}
MMC_THROW_INTERNAL();
tmp6_done2:;
}
}__omcQ_24tmpVar6 = tmpMeta4;
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar6,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp27 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar7;
}
_outElementList = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outElementList;
}
DLLExport
modelica_metatype omc_Inline_inlineStartAttribute(threadData_t *threadData, modelica_metatype _inVariableAttributesOption, modelica_metatype _isource, modelica_metatype _fns, modelica_metatype *out_osource, modelica_boolean *out_b)
{
modelica_metatype _outVariableAttributesOption = NULL;
modelica_metatype _osource = NULL;
modelica_boolean _b;
modelica_boolean tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inVariableAttributesOption;
{
modelica_metatype _source = NULL;
modelica_metatype _r = NULL;
modelica_metatype _quantity = NULL;
modelica_metatype _unit = NULL;
modelica_metatype _displayUnit = NULL;
modelica_metatype _fixed = NULL;
modelica_metatype _nominal = NULL;
modelica_metatype _so = NULL;
modelica_metatype _min = NULL;
modelica_metatype _max = NULL;
modelica_metatype _stateSelectOption = NULL;
modelica_metatype _uncertainOption = NULL;
modelica_metatype _distributionOption = NULL;
modelica_metatype _equationBound = NULL;
modelica_metatype _isProtected = NULL;
modelica_metatype _finalPrefix = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 7; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
tmp4 += 5;
tmpMeta[0+0] = mmc_mk_none();
tmpMeta[0+1] = _isource;
tmp1_c2 = 0;
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
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_boolean tmp24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,15) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 6));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 7));
if (optionNone(tmpMeta12)) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 1));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 8));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 9));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 10));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 11));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 12));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 13));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 14));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 15));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 16));
_quantity = tmpMeta7;
_unit = tmpMeta8;
_displayUnit = tmpMeta9;
_min = tmpMeta10;
_max = tmpMeta11;
_r = tmpMeta13;
_fixed = tmpMeta14;
_nominal = tmpMeta15;
_stateSelectOption = tmpMeta16;
_uncertainOption = tmpMeta17;
_distributionOption = tmpMeta18;
_equationBound = tmpMeta19;
_isProtected = tmpMeta20;
_finalPrefix = tmpMeta21;
_so = tmpMeta22;
tmp4 += 4;
tmpMeta25 = omc_Inline_inlineExp(threadData, _r, _fns, _isource, &tmpMeta23, &tmp24, NULL);
_r = tmpMeta25;
if (1 != tmp24) goto goto_2;
_source = tmpMeta23;
tmpMeta26 = mmc_mk_box16(3, &DAE_VariableAttributes_VAR__ATTR__REAL__desc, _quantity, _unit, _displayUnit, _min, _max, mmc_mk_some(_r), _fixed, _nominal, _stateSelectOption, _uncertainOption, _distributionOption, _equationBound, _isProtected, _finalPrefix, _so);
tmpMeta[0+0] = mmc_mk_some(tmpMeta26);
tmpMeta[0+1] = _source;
tmp1_c2 = 1;
goto tmp3_done;
}
case 2: {
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
modelica_boolean tmp41;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta27,1,11) == 0) goto tmp3_end;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 2));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 3));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 4));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 5));
if (optionNone(tmpMeta31)) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta31), 1));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 6));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 7));
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 8));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 9));
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 10));
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 11));
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 12));
_quantity = tmpMeta28;
_min = tmpMeta29;
_max = tmpMeta30;
_r = tmpMeta32;
_fixed = tmpMeta33;
_uncertainOption = tmpMeta34;
_distributionOption = tmpMeta35;
_equationBound = tmpMeta36;
_isProtected = tmpMeta37;
_finalPrefix = tmpMeta38;
_so = tmpMeta39;
tmp4 += 3;
tmpMeta42 = omc_Inline_inlineExp(threadData, _r, _fns, _isource, &tmpMeta40, &tmp41, NULL);
_r = tmpMeta42;
if (1 != tmp41) goto goto_2;
_source = tmpMeta40;
tmpMeta43 = mmc_mk_box12(4, &DAE_VariableAttributes_VAR__ATTR__INT__desc, _quantity, _min, _max, mmc_mk_some(_r), _fixed, _uncertainOption, _distributionOption, _equationBound, _isProtected, _finalPrefix, _so);
tmpMeta[0+0] = mmc_mk_some(tmpMeta43);
tmpMeta[0+1] = _source;
tmp1_c2 = 1;
goto tmp3_done;
}
case 3: {
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
modelica_boolean tmp54;
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta44,2,7) == 0) goto tmp3_end;
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 2));
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 3));
if (optionNone(tmpMeta46)) goto tmp3_end;
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta46), 1));
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 4));
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 5));
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 6));
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 7));
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 8));
_quantity = tmpMeta45;
_r = tmpMeta47;
_fixed = tmpMeta48;
_equationBound = tmpMeta49;
_isProtected = tmpMeta50;
_finalPrefix = tmpMeta51;
_so = tmpMeta52;
tmp4 += 2;
tmpMeta55 = omc_Inline_inlineExp(threadData, _r, _fns, _isource, &tmpMeta53, &tmp54, NULL);
_r = tmpMeta55;
if (1 != tmp54) goto goto_2;
_source = tmpMeta53;
tmpMeta56 = mmc_mk_box8(5, &DAE_VariableAttributes_VAR__ATTR__BOOL__desc, _quantity, mmc_mk_some(_r), _fixed, _equationBound, _isProtected, _finalPrefix, _so);
tmpMeta[0+0] = mmc_mk_some(tmpMeta56);
tmpMeta[0+1] = _source;
tmp1_c2 = 1;
goto tmp3_done;
}
case 4: {
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
modelica_boolean tmp67;
modelica_metatype tmpMeta68;
modelica_metatype tmpMeta69;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta57,4,7) == 0) goto tmp3_end;
tmpMeta58 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta57), 2));
tmpMeta59 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta57), 3));
if (optionNone(tmpMeta59)) goto tmp3_end;
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta59), 1));
tmpMeta61 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta57), 4));
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta57), 5));
tmpMeta63 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta57), 6));
tmpMeta64 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta57), 7));
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta57), 8));
_quantity = tmpMeta58;
_r = tmpMeta60;
_fixed = tmpMeta61;
_equationBound = tmpMeta62;
_isProtected = tmpMeta63;
_finalPrefix = tmpMeta64;
_so = tmpMeta65;
tmp4 += 1;
tmpMeta68 = omc_Inline_inlineExp(threadData, _r, _fns, _isource, &tmpMeta66, &tmp67, NULL);
_r = tmpMeta68;
if (1 != tmp67) goto goto_2;
_source = tmpMeta66;
tmpMeta69 = mmc_mk_box8(7, &DAE_VariableAttributes_VAR__ATTR__STRING__desc, _quantity, mmc_mk_some(_r), _fixed, _equationBound, _isProtected, _finalPrefix, _so);
tmpMeta[0+0] = mmc_mk_some(tmpMeta69);
tmpMeta[0+1] = _source;
tmp1_c2 = 1;
goto tmp3_done;
}
case 5: {
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
modelica_boolean tmp82;
modelica_metatype tmpMeta83;
modelica_metatype tmpMeta84;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta70 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta70,5,9) == 0) goto tmp3_end;
tmpMeta71 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta70), 2));
tmpMeta72 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta70), 3));
tmpMeta73 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta70), 4));
tmpMeta74 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta70), 5));
if (optionNone(tmpMeta74)) goto tmp3_end;
tmpMeta75 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta74), 1));
tmpMeta76 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta70), 6));
tmpMeta77 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta70), 7));
tmpMeta78 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta70), 8));
tmpMeta79 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta70), 9));
tmpMeta80 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta70), 10));
_quantity = tmpMeta71;
_min = tmpMeta72;
_max = tmpMeta73;
_r = tmpMeta75;
_fixed = tmpMeta76;
_equationBound = tmpMeta77;
_isProtected = tmpMeta78;
_finalPrefix = tmpMeta79;
_so = tmpMeta80;
tmpMeta83 = omc_Inline_inlineExp(threadData, _r, _fns, _isource, &tmpMeta81, &tmp82, NULL);
_r = tmpMeta83;
if (1 != tmp82) goto goto_2;
_source = tmpMeta81;
tmpMeta84 = mmc_mk_box10(8, &DAE_VariableAttributes_VAR__ATTR__ENUMERATION__desc, _quantity, _min, _max, mmc_mk_some(_r), _fixed, _equationBound, _isProtected, _finalPrefix, _so);
tmpMeta[0+0] = mmc_mk_some(tmpMeta84);
tmpMeta[0+1] = _source;
tmp1_c2 = 1;
goto tmp3_done;
}
case 6: {
tmpMeta[0+0] = _inVariableAttributesOption;
tmpMeta[0+1] = _isource;
tmp1_c2 = 0;
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
_outVariableAttributesOption = tmpMeta[0+0];
_osource = tmpMeta[0+1];
_b = tmp1_c2;
_return: OMC_LABEL_UNUSED
if (out_osource) { *out_osource = _osource; }
if (out_b) { *out_b = _b; }
return _outVariableAttributesOption;
}
modelica_metatype boxptr_Inline_inlineStartAttribute(threadData_t *threadData, modelica_metatype _inVariableAttributesOption, modelica_metatype _isource, modelica_metatype _fns, modelica_metatype *out_osource, modelica_metatype *out_b)
{
modelica_boolean _b;
modelica_metatype _outVariableAttributesOption = NULL;
_outVariableAttributesOption = omc_Inline_inlineStartAttribute(threadData, _inVariableAttributesOption, _isource, _fns, out_osource, &_b);
if (out_b) { *out_b = mmc_mk_icon(_b); }
return _outVariableAttributesOption;
}
