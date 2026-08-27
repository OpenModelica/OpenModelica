#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/Inline.c"
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
#define _OMC_LIT28_data "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/FrontEnd/Inline.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,67,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT29_6,1605787387.0);
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
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT36,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(89)),_OMC_LIT33,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT35}};
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
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT41,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(95)),_OMC_LIT38,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT40}};
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
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
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
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
_ht = tmpMeta[3];
_repl = tmpMeta[4];
_regRepl = tmpMeta[5];
_invRepl = tmpMeta[6];
omc_BaseHashTable_clearAssumeNoDelete(threadData, _ht);
omc_BaseHashTable_clearAssumeNoDelete(threadData, _regRepl);
omc_BaseHashTable_clearAssumeNoDelete(threadData, _invRepl);
tmpMeta[0+0] = _ht;
tmpMeta[0+1] = _repl;
goto tmp3_done;
}
case 1: {
_ht = omc_HashTableCG_emptyHashTable(threadData);
_repl = omc_VarTransform_emptyReplacements(threadData);
tmpMeta[2] = mmc_mk_box2(0, _ht, _repl);
setGlobalRoot(((modelica_integer) 22), mmc_mk_some(tmpMeta[2]));
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
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _ty;
{
modelica_metatype _vars = NULL;
modelica_metatype _crs = NULL;
modelica_metatype _exps = NULL;
modelica_metatype _path = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[0] = omc_VarTransform_getReplacement(threadData, _repl, _cr);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,9,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_path = tmpMeta[2];
_vars = tmpMeta[3];
_crs = omc_List_map1(threadData, omc_List_map(threadData, _vars, boxvar_Types_getVarName), boxvar_ComponentReference_appendStringCref, _cr);
_exps = omc_List_map1r(threadData, _crs, boxvar_VarTransform_getReplacement, _repl);
tmpMeta[1] = mmc_mk_box8(3, &DAE_CallAttributes_CALL__ATTR__desc, _ty, mmc_mk_boolean(0), mmc_mk_boolean(0), mmc_mk_boolean(0), mmc_mk_boolean(0), _OMC_LIT0, _OMC_LIT1);
tmpMeta[2] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _path, _exps, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
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
_exp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _exp;
}
DLLExport
modelica_metatype omc_Inline_inlineEquationExp(threadData_t *threadData, modelica_metatype _inExp, modelica_fnptr _fn, modelica_metatype _inSource, modelica_metatype *out_source)
{
modelica_metatype _outExp = NULL;
modelica_metatype _source = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_e = tmpMeta[2];
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_e_1 = omc_Expression_traverseExpBottomUp(threadData, _e, ((modelica_fnptr) _fn), tmpMeta[2], NULL);
_changed = (!referenceEq(_e, _e_1));
tmpMeta[2] = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _e_1);
_eq2 = tmpMeta[2];
tmpMeta[2] = mmc_mk_box3(6, &DAE_SymbolicOperation_OP__INLINE__desc, _inExp, _eq2);
_source = omc_ElementSource_condAddSymbolicTransformation(threadData, _changed, _inSource, tmpMeta[2]);
tmpMeta[0+0] = omc_ExpressionSimplify_condSimplifyAddSymbolicOperation(threadData, _changed, _eq2, _source, &tmpMeta[0+1]);
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_e = tmpMeta[2];
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_e_1 = omc_Expression_traverseExpBottomUp(threadData, _e, ((modelica_fnptr) _fn), tmpMeta[2], NULL);
_changed = (!referenceEq(_e, _e_1));
tmpMeta[2] = mmc_mk_box2(4, &DAE_EquationExp_RESIDUAL__EXP__desc, _e_1);
_eq2 = tmpMeta[2];
tmpMeta[2] = mmc_mk_box3(6, &DAE_SymbolicOperation_OP__INLINE__desc, _inExp, _eq2);
_source = omc_ElementSource_condAddSymbolicTransformation(threadData, _changed, _inSource, tmpMeta[2]);
tmpMeta[0+0] = omc_ExpressionSimplify_condSimplifyAddSymbolicOperation(threadData, _changed, _eq2, _source, &tmpMeta[0+1]);
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e1 = tmpMeta[2];
_e2 = tmpMeta[3];
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_e1_1 = omc_Expression_traverseExpBottomUp(threadData, _e1, ((modelica_fnptr) _fn), tmpMeta[2], NULL);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_e2_1 = omc_Expression_traverseExpBottomUp(threadData, _e2, ((modelica_fnptr) _fn), tmpMeta[2], NULL);
_changed = (!(referenceEq(_e1, _e1_1) && referenceEq(_e2, _e2_1)));
tmpMeta[2] = mmc_mk_box3(5, &DAE_EquationExp_EQUALITY__EXPS__desc, _e1_1, _e2_1);
_eq2 = tmpMeta[2];
tmpMeta[2] = mmc_mk_box3(6, &DAE_SymbolicOperation_OP__INLINE__desc, _inExp, _eq2);
_source = omc_ElementSource_condAddSymbolicTransformation(threadData, _changed, _inSource, tmpMeta[2]);
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
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_exp = omc_ExpressionSimplify_simplifyAddSymbolicOperation(threadData, _inExp, _inSource ,&_source);
tmpMeta[0] = mmc_mk_box2(0, _fns, _OMC_LIT9);
_exp = omc_Inline_inlineEquationExp(threadData, _exp, (modelica_fnptr) mmc_mk_box2(0,closure0_Inline_forceInlineCall,tmpMeta[0]), _source ,&_source);
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
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_exp = omc_ExpressionSimplify_simplifyAddSymbolicOperation(threadData, _inExp, _inSource ,&_source);
tmpMeta[0] = mmc_mk_box1(0, _fns);
_exp = omc_Inline_inlineEquationExp(threadData, _exp, (modelica_fnptr) mmc_mk_box2(0,closure1_Inline_inlineCall,tmpMeta[0]), _source ,&_source);
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inElement;
{
modelica_metatype _cref = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,0) == 0) goto tmp2_end;
_cref = tmpMeta[1];
tmpMeta[0] = _cref;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _OMC_LIT16;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_getExpFromArgMap(threadData_t *threadData, modelica_metatype _inArgMap, modelica_metatype _inComponentRef)
{
jmp_buf *old_mmc_jumper = threadData->mmc_jumper;
modelica_metatype _outExp = NULL;
modelica_metatype _arg = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _key = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_subs = omc_ComponentReference_crefSubs(threadData, _inComponentRef);
_key = omc_ComponentReference_crefStripSubs(threadData, _inComponentRef);
{
modelica_metatype _arg;
for (tmpMeta[0] = _inArgMap; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_arg = MMC_CAR(tmpMeta[0]);
tmpMeta[1] = _arg;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_cref = tmpMeta[2];
_exp = tmpMeta[3];
if(omc_ComponentReference_crefEqual(threadData, _cref, _key))
{
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
_outExp = omc_Expression_applyExpSubscripts(threadData, _exp, _subs);
goto tmp2_done;
}
case 1: {
continue;
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
goto _return;
}
}
}
if(omc_Flags_isSet(threadData, _OMC_LIT21))
{
tmpMeta[0] = stringAppend(_OMC_LIT17,omc_ComponentReference_printComponentRefStr(threadData, _inComponentRef));
omc_Debug_traceln(threadData, tmpMeta[0]);
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
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],11,4) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
_ty = tmpMeta[3];
_inlineType = tmpMeta[5];
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _iexp;
tmp3_2 = _ty;
{
modelica_metatype _t = NULL;
modelica_metatype _exp = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],11,4) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_t = tmpMeta[2];
_exp = tmp3_1;
tmp5 = (modelica_boolean)omc_Types_isBoxedType(threadData, _t);
if(tmp5)
{
tmpMeta[2] = _exp;
}
else
{
tmpMeta[1] = mmc_mk_box2(37, &DAE_Exp_BOX__desc, _exp);
tmpMeta[2] = tmpMeta[1];
}
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _iexp;
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
modelica_metatype omc_Inline_replaceArgs(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTuple, modelica_metatype *out_outTuple)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outTuple = NULL;
modelica_metatype tmpMeta[14] __attribute__((unused)) = {0};
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
modelica_integer tmp6;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp6 = mmc_unbox_integer(tmpMeta[3]);
if (1 != tmp6) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_argmap = tmpMeta[2];
_cref = tmpMeta[4];
_e = omc_Inline_getExpFromArgMap(threadData, _argmap, _cref);
_e = omc_ExpressionSimplify_simplify(threadData, _e, NULL);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _inTuple;
goto tmp3_done;
}
case 1: {
modelica_integer tmp7;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp7 = mmc_unbox_integer(tmpMeta[4]);
if (1 != tmp7) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_argmap = tmpMeta[2];
_checkcr = tmpMeta[3];
_cref = tmpMeta[5];
if (!omc_BaseHashTable_hasKey(threadData, omc_ComponentReference_crefFirstCref(threadData, _cref), _checkcr)) goto tmp3_end;
tmpMeta[2] = mmc_mk_box3(0, _argmap, _checkcr, mmc_mk_boolean(0));
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = tmpMeta[2];
goto tmp3_done;
}
case 2: {
modelica_integer tmp8;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp8 = mmc_unbox_integer(tmpMeta[3]);
if (1 != tmp8) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_argmap = tmpMeta[2];
_cref = tmpMeta[4];
_firstCref = omc_ComponentReference_crefFirstCref(threadData, _cref);
tmpMeta[2] = omc_ComponentReference_crefSubs(threadData, _firstCref);
if (!listEmpty(tmpMeta[2])) goto goto_2;
_e = omc_Inline_getExpFromArgMap(threadData, _argmap, _firstCref);
while(1)
{
if(!(!omc_ComponentReference_crefIsIdent(threadData, _cref))) break;
_cref = omc_ComponentReference_crefRest(threadData, _cref);
tmpMeta[2] = omc_ComponentReference_crefSubs(threadData, _cref);
if (!listEmpty(tmpMeta[2])) goto goto_2;
tmpMeta[2] = mmc_mk_box5(26, &DAE_Exp_RSUB__desc, _e, mmc_mk_integer(((modelica_integer) -1)), omc_ComponentReference_crefFirstIdent(threadData, _cref), omc_ComponentReference_crefType(threadData, _cref));
_e = tmpMeta[2];
}
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _inTuple;
goto tmp3_done;
}
case 3: {
modelica_integer tmp9;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp9 = mmc_unbox_integer(tmpMeta[4]);
if (1 != tmp9) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_argmap = tmpMeta[2];
_checkcr = tmpMeta[3];
_cref = tmpMeta[5];
tmp4 += 4;
omc_Inline_getExpFromArgMap(threadData, _argmap, omc_ComponentReference_crefStripSubs(threadData, omc_ComponentReference_crefFirstCref(threadData, _cref)));
tmpMeta[2] = mmc_mk_box3(0, _argmap, _checkcr, mmc_mk_boolean(0));
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = tmpMeta[2];
goto tmp3_done;
}
case 4: {
modelica_integer tmp10;
modelica_integer tmp11;
modelica_integer tmp12;
modelica_integer tmp13;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp10 = mmc_unbox_integer(tmpMeta[3]);
if (1 != tmp10) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,35,2) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],13,3) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 3));
tmp11 = mmc_unbox_integer(tmpMeta[8]);
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 4));
tmp12 = mmc_unbox_integer(tmpMeta[9]);
if (0 != tmp12) goto tmp3_end;
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 5));
tmp13 = mmc_unbox_integer(tmpMeta[10]);
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 7));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 8));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_argmap = tmpMeta[2];
_path = tmpMeta[5];
_expLst = tmpMeta[6];
_tuple_ = tmp11;
_isImpure = tmp13;
_inlineType = tmpMeta[11];
_tc = tmpMeta[12];
_ty = tmpMeta[13];
_cref = omc_ComponentReference_pathToCref(threadData, _path);
tmpMeta[2] = omc_Inline_getExpFromArgMap(threadData, _argmap, _cref);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],6,2) == 0) goto goto_2;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
_e = tmpMeta[2];
_cref = tmpMeta[3];
_ty2 = tmpMeta[4];
_path = omc_ComponentReference_crefToPath(threadData, _cref);
_expLst = omc_List_map(threadData, _expLst, boxvar_Expression_unboxExp);
_b = omc_Expression_isBuiltinFunctionReference(threadData, _e);
_isFunctionPointerCall = omc_Types_isFunctionReferenceVar(threadData, _ty2);
tmpMeta[2] = mmc_mk_box8(3, &DAE_CallAttributes_CALL__ATTR__desc, _ty, mmc_mk_boolean(_tuple_), mmc_mk_boolean(_b), mmc_mk_boolean(_isImpure), mmc_mk_boolean(_isFunctionPointerCall), _inlineType, _tc);
tmpMeta[3] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _path, _expLst, tmpMeta[2]);
_e = tmpMeta[3];
_e = omc_ExpressionSimplify_simplify(threadData, _e, NULL);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _inTuple;
goto tmp3_done;
}
case 5: {
modelica_integer tmp14;
modelica_integer tmp15;
modelica_boolean tmp16;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp14 = mmc_unbox_integer(tmpMeta[4]);
if (1 != tmp14) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,35,2) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],13,3) == 0) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 4));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 4));
tmp15 = mmc_unbox_integer(tmpMeta[8]);
if (0 != tmp15) goto tmp3_end;
_argmap = tmpMeta[2];
_checkcr = tmpMeta[3];
_e = tmp4_1;
_path = tmpMeta[6];
tmp4 += 2;
_cref = omc_ComponentReference_pathToCref(threadData, _path);
tmp16 = omc_BaseHashTable_hasKey(threadData, _cref, _checkcr);
if (1 != tmp16) goto goto_2;
tmpMeta[2] = mmc_mk_box3(0, _argmap, _checkcr, mmc_mk_boolean(0));
tmpMeta[0+0] = _e;
tmpMeta[0+1] = tmpMeta[2];
goto tmp3_done;
}
case 6: {
modelica_integer tmp17;
modelica_integer tmp18;
modelica_integer tmp19;
modelica_integer tmp20;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp17 = mmc_unbox_integer(tmpMeta[3]);
if (1 != tmp17) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],25,1) == 0) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 3));
tmp18 = mmc_unbox_integer(tmpMeta[8]);
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 4));
tmp19 = mmc_unbox_integer(tmpMeta[9]);
if (0 != tmp19) goto tmp3_end;
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 5));
tmp20 = mmc_unbox_integer(tmpMeta[10]);
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 8));
_argmap = tmpMeta[2];
_path = tmpMeta[4];
_expLst = tmpMeta[5];
_tuple_ = tmp18;
_isImpure = tmp20;
_tc = tmpMeta[11];
_cref = omc_ComponentReference_pathToCref(threadData, _path);
tmpMeta[2] = omc_Inline_getExpFromArgMap(threadData, _argmap, _cref);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],6,2) == 0) goto goto_2;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
_e = tmpMeta[2];
_cref = tmpMeta[3];
_ty = tmpMeta[4];
_path = omc_ComponentReference_crefToPath(threadData, _cref);
_expLst = omc_List_map(threadData, _expLst, boxvar_Expression_unboxExp);
_b = omc_Expression_isBuiltinFunctionReference(threadData, _e);
_ty2 = omc_Inline_functionReferenceType(threadData, _ty ,&_inlineType);
_isFunctionPointerCall = omc_Types_isFunctionReferenceVar(threadData, _ty2);
tmpMeta[2] = mmc_mk_box8(3, &DAE_CallAttributes_CALL__ATTR__desc, _ty2, mmc_mk_boolean(_tuple_), mmc_mk_boolean(_b), mmc_mk_boolean(_isImpure), mmc_mk_boolean(_isFunctionPointerCall), _inlineType, _tc);
tmpMeta[3] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _path, _expLst, tmpMeta[2]);
_e = tmpMeta[3];
_e = omc_Inline_boxIfUnboxedFunRef(threadData, _e, _ty);
_e = omc_ExpressionSimplify_simplify(threadData, _e, NULL);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _inTuple;
goto tmp3_done;
}
case 7: {
modelica_integer tmp21;
modelica_integer tmp22;
modelica_boolean tmp23;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp21 = mmc_unbox_integer(tmpMeta[4]);
if (1 != tmp21) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],25,1) == 0) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 4));
tmp22 = mmc_unbox_integer(tmpMeta[8]);
if (0 != tmp22) goto tmp3_end;
_argmap = tmpMeta[2];
_checkcr = tmpMeta[3];
_e = tmp4_1;
_path = tmpMeta[5];
_cref = omc_ComponentReference_pathToCref(threadData, _path);
tmp23 = omc_BaseHashTable_hasKey(threadData, _cref, _checkcr);
if (1 != tmp23) goto goto_2;
tmpMeta[2] = mmc_mk_box3(0, _argmap, _checkcr, mmc_mk_boolean(0));
tmpMeta[0+0] = _e;
tmpMeta[0+1] = tmpMeta[2];
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
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inElementList;
{
modelica_metatype _cdr = NULL;
modelica_metatype _res = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 5; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmp5 = omc_Flags_isSet(threadData, _OMC_LIT21);
if (1 != tmp5) goto goto_1;
omc_Debug_trace(threadData, _OMC_LIT22);
goto goto_1;
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],15,2) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],0,4) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 4));
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
_res = tmpMeta[7];
tmpMeta[0] = _res;
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],15,2) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],1,4) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 4));
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
_res = tmpMeta[7];
tmpMeta[0] = _res;
goto tmp2_done;
}
case 3: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],15,2) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],2,4) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 4));
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
_res = tmpMeta[7];
tmpMeta[0] = _res;
goto tmp2_done;
}
case 4: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_cdr = tmpMeta[2];
_inElementList = _cdr;
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
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
DLLExport
modelica_metatype omc_Inline_getFunctionBody(threadData_t *threadData, modelica_metatype _p, modelica_metatype _fns, modelica_metatype *out_oComment)
{
modelica_metatype _outfn = NULL;
modelica_metatype _oComment = NULL;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
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
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (optionNone(tmpMeta[2])) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_ftree = tmpMeta[3];
tmpMeta[2] = omc_DAE_AvlTreePathFunction_get(threadData, _ftree, _p);
if (optionNone(tmpMeta[2])) goto goto_2;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,10) == 0) goto goto_2;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
if (listEmpty(tmpMeta[4])) goto goto_2;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],0,1) == 0) goto goto_2;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 11));
_body = tmpMeta[7];
_comment = tmpMeta[8];
tmpMeta[0+0] = _body;
tmpMeta[0+1] = _comment;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
tmp6 = omc_Flags_isSet(threadData, _OMC_LIT21);
if (1 != tmp6) goto goto_2;
tmpMeta[2] = stringAppend(_OMC_LIT23,omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT24, 1, 0));
omc_Debug_traceln(threadData, tmpMeta[2]);
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _ev;
{
modelica_metatype _tp = NULL;
modelica_string _name = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_name = tmpMeta[1];
_tp = tmpMeta[2];
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = omc_ComponentReference_crefPrependIdent(threadData, _c, _name, tmpMeta[1], _tp);
goto tmp2_done;
}
case 1: {
modelica_boolean tmp5;
tmp5 = omc_Flags_isSet(threadData, _OMC_LIT21);
if (1 != tmp5) goto goto_1;
omc_Debug_trace(threadData, _OMC_LIT25);
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
_outArg = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outArg;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_extendCrefRecords1(threadData_t *threadData, modelica_metatype _ev, modelica_metatype _c, modelica_metatype _e)
{
modelica_metatype _outArg = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _ev;
{
modelica_metatype _tp = NULL;
modelica_string _name = NULL;
modelica_metatype _c1 = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _exp = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_name = tmpMeta[1];
_tp = tmpMeta[2];
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_c1 = omc_ComponentReference_crefPrependIdent(threadData, _c, _name, tmpMeta[1], _tp);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_e1 = omc_ComponentReference_crefPrependIdent(threadData, _e, _name, tmpMeta[1], _tp);
_exp = omc_Expression_makeCrefExp(threadData, _e1, _tp);
tmpMeta[1] = mmc_mk_box2(0, _c1, _exp);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
modelica_boolean tmp5;
tmp5 = omc_Flags_isSet(threadData, _OMC_LIT21);
if (1 != tmp5) goto goto_1;
omc_Debug_trace(threadData, _OMC_LIT26);
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
_outArg = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outArg;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_getCheckCref(threadData_t *threadData, modelica_metatype _inCrefs, modelica_metatype _inCheckCr)
{
modelica_metatype _outCheckCr = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inCrefs;
tmp3_2 = _inCheckCr;
{
modelica_metatype _ht = NULL;
modelica_metatype _ht1 = NULL;
modelica_metatype _ht2 = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _crlst = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _varLst = NULL;
modelica_metatype _creftpllst = NULL;
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
_ht = tmp3_2;
tmp3 += 2;
tmpMeta[0] = _ht;
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_cr = tmpMeta[1];
_rest = tmpMeta[2];
_ht = tmp3_2;
tmpMeta[1] = omc_ComponentReference_crefLastType(threadData, _cr);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],9,3) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_varLst = tmpMeta[2];
_crlst = omc_List_map1(threadData, _varLst, boxvar_Inline_extendCrefRecords2, _cr);
_ht1 = omc_Inline_getCheckCref(threadData, _crlst, _ht);
_creftpllst = omc_List_map1(threadData, _crlst, boxvar_Util_makeTuple, _cr);
_ht2 = omc_List_fold(threadData, _creftpllst, boxvar_BaseHashTable_add, _ht1);
tmpMeta[0] = omc_Inline_getCheckCref(threadData, _rest, _ht2);
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_rest = tmpMeta[2];
_ht = tmp3_2;
tmpMeta[0] = omc_Inline_getCheckCref(threadData, _rest, _ht);
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
_outCheckCr = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outCheckCr;
}
DLLExport
modelica_metatype omc_Inline_extendCrefRecords(threadData_t *threadData, modelica_metatype _inArgmap, modelica_metatype _inCheckCr, modelica_metatype *out_outCheckCr)
{
modelica_metatype _outArgmap = NULL;
modelica_metatype _outCheckCr = NULL;
modelica_metatype tmpMeta[12] __attribute__((unused)) = {0};
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
if (!listEmpty(tmp4_1)) goto tmp3_end;
_ht = tmp4_2;
tmp4 += 7;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _ht;
goto tmp3_done;
}
case 1: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],20,2) == 0) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],9,3) == 0) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
_c = tmpMeta[4];
_e = tmpMeta[7];
_res = tmpMeta[3];
_ht = tmp4_2;
tmp4 += 4;
tmpMeta[3] = mmc_mk_box2(0, _c, _e);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _res);
tmpMeta[0+0] = omc_Inline_extendCrefRecords(threadData, tmpMeta[2], _ht, &tmpMeta[0+1]);
goto tmp3_done;
}
case 2: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],6,2) == 0) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],9,3) == 0) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 3));
_c = tmpMeta[4];
_e = tmpMeta[5];
_cref = tmpMeta[6];
_varLst = tmpMeta[8];
_res = tmpMeta[3];
_ht = tmp4_2;
_res1 = omc_Inline_extendCrefRecords(threadData, _res, _ht ,&_ht1);
_new = omc_List_map2(threadData, _varLst, boxvar_Inline_extendCrefRecords1, _c, _cref);
_new1 = omc_Inline_extendCrefRecords(threadData, _new, _ht1 ,&_ht2);
_res2 = listAppend(_new1, _res1);
tmpMeta[3] = mmc_mk_box2(0, _c, _e);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _res2);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _ht2;
goto tmp3_done;
}
case 3: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],6,2) == 0) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
_c = tmpMeta[4];
_e = tmpMeta[5];
_cref = tmpMeta[6];
_res = tmpMeta[3];
_ht = tmp4_2;
tmp4 += 2;
tmpMeta[2] = omc_ComponentReference_crefLastType(threadData, _cref);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],9,3) == 0) goto goto_2;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
_varLst = tmpMeta[3];
_res1 = omc_Inline_extendCrefRecords(threadData, _res, _ht ,&_ht1);
_new = omc_List_map2(threadData, _varLst, boxvar_Inline_extendCrefRecords1, _c, _cref);
_new1 = omc_Inline_extendCrefRecords(threadData, _new, _ht1 ,&_ht2);
_res2 = listAppend(_new1, _res1);
tmpMeta[3] = mmc_mk_box2(0, _c, _e);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _res2);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _ht2;
goto tmp3_done;
}
case 4: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],13,3) == 0) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 4));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],9,3) == 0) goto tmp3_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[9],3,1) == 0) goto tmp3_end;
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[9]), 2));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 3));
_c = tmpMeta[4];
_e = tmpMeta[5];
_expl = tmpMeta[6];
_rpath = tmpMeta[10];
_varLst = tmpMeta[11];
_res = tmpMeta[3];
_ht = tmp4_2;
tmp4 += 1;
if (!omc_AbsynUtil_pathEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 2))), _rpath)) goto tmp3_end;
_res1 = omc_Inline_extendCrefRecords(threadData, _res, _ht ,&_ht1);
_crlst = omc_List_map1(threadData, _varLst, boxvar_Inline_extendCrefRecords2, _c);
_new = omc_List_zip(threadData, _crlst, _expl);
_new1 = omc_Inline_extendCrefRecords(threadData, _new, _ht1 ,&_ht2);
_res2 = listAppend(_new1, _res1);
tmpMeta[3] = mmc_mk_box2(0, _c, _e);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _res2);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _ht2;
goto tmp3_done;
}
case 5: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],14,4) == 0) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],9,3) == 0) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 3));
_c = tmpMeta[4];
_e = tmpMeta[5];
_expl = tmpMeta[6];
_varLst = tmpMeta[8];
_res = tmpMeta[3];
_ht = tmp4_2;
_res1 = omc_Inline_extendCrefRecords(threadData, _res, _ht ,&_ht1);
_crlst = omc_List_map1(threadData, _varLst, boxvar_Inline_extendCrefRecords2, _c);
_new = omc_List_zip(threadData, _crlst, _expl);
_new1 = omc_Inline_extendCrefRecords(threadData, _new, _ht1 ,&_ht2);
_res2 = listAppend(_new1, _res1);
tmpMeta[3] = mmc_mk_box2(0, _c, _e);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _res2);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _ht2;
goto tmp3_done;
}
case 6: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_c = tmpMeta[4];
_e = tmpMeta[5];
_res = tmpMeta[3];
_ht = tmp4_2;
tmpMeta[2] = omc_Expression_typeof(threadData, _e);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],9,3) == 0) goto goto_2;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
_varLst = tmpMeta[3];
_crlst = omc_List_map1(threadData, _varLst, boxvar_Inline_extendCrefRecords2, _c);
_creftpllst = omc_List_map1(threadData, _crlst, boxvar_Util_makeTuple, _c);
_ht1 = omc_List_fold(threadData, _creftpllst, boxvar_BaseHashTable_add, _ht);
_ht2 = omc_Inline_getCheckCref(threadData, _crlst, _ht1);
_res1 = omc_Inline_extendCrefRecords(threadData, _res, _ht2 ,&_ht3);
tmpMeta[3] = mmc_mk_box2(0, _c, _e);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _res1);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _ht3;
goto tmp3_done;
}
case 7: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_c = tmpMeta[4];
_e = tmpMeta[5];
_res = tmpMeta[3];
_ht = tmp4_2;
_res1 = omc_Inline_extendCrefRecords(threadData, _res, _ht ,&_ht1);
tmpMeta[3] = mmc_mk_box2(0, _c, _e);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _res1);
tmpMeta[0+0] = tmpMeta[2];
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
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
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
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_it = tmp4_1;
_itlst = tmpMeta[0];
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
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _iCr;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta[0] = omc_VarTransform_addReplacement(threadData, _iRepl, _iCr, _iExp);
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
_oRepl = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _oRepl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_addOptBindingReplacements(threadData_t *threadData, modelica_metatype _cr, modelica_metatype _binding, modelica_metatype _iRepl)
{
modelica_metatype _oRepl = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _binding;
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
tmpMeta[0] = omc_Inline_addReplacement(threadData, _cr, _e, _iRepl);
goto tmp2_done;
}
case 1: {
if (!optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[0] = _iRepl;
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
_oRepl = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _oRepl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_makeComplexBinding(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fbinding, modelica_metatype _ty)
{
modelica_metatype _binding = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_binding = __omcQ_24in_5Fbinding;
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _binding;
tmp3_2 = _ty;
{
modelica_metatype _expl = NULL;
modelica_metatype _strl = NULL;
modelica_metatype _exp = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!optionNone(tmp3_1)) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,9,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_expl = tmpMeta[1];
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_strl = tmpMeta[1];
{
modelica_metatype _var;
for (tmpMeta[1] = listReverse((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ty), 3)))); !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_var = MMC_CAR(tmpMeta[1]);
{
modelica_metatype tmp7_1;
tmp7_1 = _var;
{
volatile mmc_switch_type tmp7;
int tmp8;
tmp7 = 0;
for (; tmp7 < 2; tmp7++) {
switch (MMC_SWITCH_CAST(tmp7)) {
case 0: {
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,4) == 0) goto tmp6_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_exp = tmpMeta[3];
tmpMeta[2] = mmc_mk_cons(_exp, _expl);
_expl = tmpMeta[2];
tmpMeta[2] = mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_var), 2))), _strl);
_strl = tmpMeta[2];
goto tmp6_done;
}
case 1: {
goto _return;
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
}
}
tmpMeta[1] = mmc_mk_box5(17, &DAE_Exp_RECORD__desc, omc_ClassInf_getStateName(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ty), 2)))), _expl, _strl, _ty);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _binding;
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
_binding = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _binding;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Inline_getFunctionInputsOutputBody(threadData_t *threadData, modelica_metatype _fn, modelica_metatype _iRepl, modelica_metatype *out_oOutputs, modelica_metatype *out_oBody, modelica_metatype *out_oRepl)
{
modelica_metatype _oInputs = NULL;
modelica_metatype _oOutputs = NULL;
modelica_metatype _oBody = NULL;
modelica_metatype _oRepl = NULL;
modelica_metatype _elt = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _binding = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _st = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_oInputs = tmpMeta[0];
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_oOutputs = tmpMeta[1];
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_oBody = tmpMeta[2];
_oRepl = _iRepl;
{
modelica_metatype _elt;
for (tmpMeta[3] = _fn; !listEmpty(tmpMeta[3]); tmpMeta[3]=MMC_CDR(tmpMeta[3]))
{
_elt = MMC_CAR(tmpMeta[3]);
{
modelica_metatype tmp3_1;
tmp3_1 = _elt;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 5; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],0,0) == 0) goto tmp2_end;
_cr = tmpMeta[4];
tmpMeta[4] = mmc_mk_cons(_cr, _oInputs);
_oInputs = tmpMeta[4];
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],1,0) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
_cr = tmpMeta[4];
_binding = tmpMeta[6];
_binding = omc_Inline_makeComplexBinding(threadData, _binding, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 7))));
_oRepl = omc_Inline_addOptBindingReplacements(threadData, _cr, _binding, _oRepl);
tmpMeta[4] = mmc_mk_cons(_cr, _oOutputs);
_oOutputs = tmpMeta[4];
goto tmp2_done;
}
case 2: {
modelica_boolean tmp5;
modelica_boolean tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],1,0) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
_cr = tmpMeta[4];
_binding = tmpMeta[6];
_tp = omc_ComponentReference_crefTypeFull(threadData, _cr);
tmp5 = omc_Expression_isArrayType(threadData, _tp);
if (0 != tmp5) goto goto_1;
tmp6 = omc_Expression_isRecordType(threadData, _tp);
if (0 != tmp6) goto goto_1;
_oRepl = omc_Inline_addOptBindingReplacements(threadData, _cr, _binding, _oRepl);
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,15,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
_st = tmpMeta[5];
_oBody = omc_List_append__reverse(threadData, _st, _oBody);
goto tmp2_done;
}
case 4: {
tmpMeta[4] = mmc_mk_cons(_elt, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[5] = stringAppend(_OMC_LIT27,omc_DAEDump_dumpElementsStr(threadData, tmpMeta[4]));
omc_Error_addInternalError(threadData, tmpMeta[5], _OMC_LIT29);
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
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _explst;
{
modelica_metatype _repl = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _tp = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = _iRepl;
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,2) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_cr = tmpMeta[3];
_tp = tmpMeta[4];
_rest = tmpMeta[2];
tmpMeta[1] = mmc_mk_box4(25, &DAE_Exp_TSUB__desc, _iExp, mmc_mk_integer(_indx), _tp);
_exp = tmpMeta[1];
_repl = omc_VarTransform_addReplacementNoTransitive(threadData, _iRepl, _cr, _exp);
_explst = _rest;
_indx = ((modelica_integer) 1) + _indx;
_iRepl = _repl;
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
_oRepl = tmpMeta[0];
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
modelica_metatype tmpMeta[18] __attribute__((unused)) = {0};
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,4) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],6,2) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
_cr = tmpMeta[5];
_exp = tmpMeta[6];
_stmts = tmpMeta[3];
_exp = omc_VarTransform_replaceExp(threadData, _exp, _iRepl, mmc_mk_none(), NULL);
_repl = omc_VarTransform_addReplacementNoTransitive(threadData, _iRepl, _cr, _exp);
_iStmts = _stmts;
_iRepl = _repl;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,4) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],6,2) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
_cr = tmpMeta[5];
_exp = tmpMeta[6];
_stmts = tmpMeta[3];
_exp = omc_VarTransform_replaceExp(threadData, _exp, _iRepl, mmc_mk_none(), NULL);
_repl = omc_VarTransform_addReplacementNoTransitive(threadData, _iRepl, _cr, _exp);
_iStmts = _stmts;
_iRepl = _repl;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,4) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
_explst = tmpMeta[4];
_exp = tmpMeta[5];
_stmts = tmpMeta[3];
_exp = omc_VarTransform_replaceExp(threadData, _exp, _iRepl, mmc_mk_none(), NULL);
_repl = omc_Inline_addTplAssignToRepl(threadData, _explst, ((modelica_integer) 1), _exp, _iRepl);
_iStmts = _stmts;
_iRepl = _repl;
goto _tailrecursive;
goto tmp3_done;
}
case 4: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],8,4) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
_exp = tmpMeta[4];
_exp1 = tmpMeta[5];
_exp2 = tmpMeta[6];
_source = tmpMeta[7];
_stmts = tmpMeta[3];
_exp = omc_VarTransform_replaceExp(threadData, _exp, _iRepl, mmc_mk_none(), NULL);
_exp1 = omc_VarTransform_replaceExp(threadData, _exp1, _iRepl, mmc_mk_none(), NULL);
_exp2 = omc_VarTransform_replaceExp(threadData, _exp2, _iRepl, mmc_mk_none(), NULL);
tmpMeta[2] = mmc_mk_box5(11, &DAE_Statement_STMT__ASSERT__desc, _exp, _exp1, _exp2, _source);
_stmt = tmpMeta[2];
tmpMeta[2] = mmc_mk_cons(_stmt, _assertStmtsIn);
_iStmts = _stmts;
_assertStmtsIn = tmpMeta[2];
goto _tailrecursive;
goto tmp3_done;
}
case 5: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],3,4) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
if (listEmpty(tmpMeta[5])) goto tmp3_end;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],0,4) == 0) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],6,2) == 0) goto tmp3_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 2));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 4));
if (!listEmpty(tmpMeta[7])) goto tmp3_end;
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[11],2,1) == 0) goto tmp3_end;
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[11]), 2));
if (listEmpty(tmpMeta[12])) goto tmp3_end;
tmpMeta[13] = MMC_CAR(tmpMeta[12]);
tmpMeta[14] = MMC_CDR(tmpMeta[12]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[13],0,4) == 0) goto tmp3_end;
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[13]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[15],6,2) == 0) goto tmp3_end;
tmpMeta[16] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[15]), 2));
tmpMeta[17] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[13]), 4));
if (!listEmpty(tmpMeta[14])) goto tmp3_end;
_exp = tmpMeta[4];
_cr1 = tmpMeta[9];
_exp1 = tmpMeta[10];
_cr2 = tmpMeta[16];
_exp2 = tmpMeta[17];
_stmts = tmpMeta[3];
if (!omc_ComponentReference_crefEqual(threadData, _cr1, _cr2)) goto tmp3_end;
_exp = omc_VarTransform_replaceExp(threadData, _exp, _iRepl, mmc_mk_none(), NULL);
_exp1 = omc_VarTransform_replaceExp(threadData, _exp1, _iRepl, mmc_mk_none(), NULL);
_exp2 = omc_VarTransform_replaceExp(threadData, _exp2, _iRepl, mmc_mk_none(), NULL);
tmpMeta[2] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _exp, _exp1, _exp2);
_repl = omc_VarTransform_addReplacementNoTransitive(threadData, _iRepl, _cr1, tmpMeta[2]);
_iStmts = _stmts;
_iRepl = _repl;
goto _tailrecursive;
goto tmp3_done;
}
case 6: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],3,4) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
if (listEmpty(tmpMeta[5])) goto tmp3_end;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],2,4) == 0) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],6,2) == 0) goto tmp3_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 2));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 4));
if (!listEmpty(tmpMeta[7])) goto tmp3_end;
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[11],2,1) == 0) goto tmp3_end;
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[11]), 2));
if (listEmpty(tmpMeta[12])) goto tmp3_end;
tmpMeta[13] = MMC_CAR(tmpMeta[12]);
tmpMeta[14] = MMC_CDR(tmpMeta[12]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[13],2,4) == 0) goto tmp3_end;
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[13]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[15],6,2) == 0) goto tmp3_end;
tmpMeta[16] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[15]), 2));
tmpMeta[17] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[13]), 4));
if (!listEmpty(tmpMeta[14])) goto tmp3_end;
_exp = tmpMeta[4];
_cr1 = tmpMeta[9];
_exp1 = tmpMeta[10];
_cr2 = tmpMeta[16];
_exp2 = tmpMeta[17];
_stmts = tmpMeta[3];
if (!omc_ComponentReference_crefEqual(threadData, _cr1, _cr2)) goto tmp3_end;
_exp = omc_VarTransform_replaceExp(threadData, _exp, _iRepl, mmc_mk_none(), NULL);
_exp1 = omc_VarTransform_replaceExp(threadData, _exp1, _iRepl, mmc_mk_none(), NULL);
_exp2 = omc_VarTransform_replaceExp(threadData, _exp2, _iRepl, mmc_mk_none(), NULL);
tmpMeta[2] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _exp, _exp1, _exp2);
_repl = omc_VarTransform_addReplacementNoTransitive(threadData, _iRepl, _cr1, tmpMeta[2]);
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
static modelica_metatype closure2_Inline_forceInlineCall(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_exp, modelica_metatype $in_assrtLst, modelica_metatype tmp12)
{
modelica_metatype fns = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype visitedPaths = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_Inline_forceInlineCall(thData, $in_exp, $in_assrtLst, fns, visitedPaths, tmp12);
}
DLLExport
modelica_metatype omc_Inline_forceInlineCall(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype __omcQ_24in_5FassrtLst, modelica_metatype _fns, modelica_metatype _visitedPaths, modelica_metatype *out_assrtLst)
{
modelica_metatype _exp = NULL;
modelica_metatype _assrtLst = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
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
modelica_boolean tmp6;
modelica_boolean tmp7;
modelica_boolean tmp10;
modelica_integer tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 7));
_e1 = tmp4_1;
_p = tmpMeta[2];
_args = tmpMeta[3];
_inlineType = tmpMeta[5];
if (!(!omc_AvlSetPath_hasKey(threadData, _visitedPaths, _p))) goto tmp3_end;
tmp6 = omc_Config_acceptMetaModelicaGrammar(threadData);
if (0 != tmp6) goto goto_2;
tmp7 = omc_Inline_checkInlineType(threadData, _inlineType, _fns);
if (1 != tmp7) goto goto_2;
_fn = omc_Inline_getFunctionBody(threadData, _p, _fns ,&_comment);
_checkcr = omc_Inline_getInlineHashTableVarTransform(threadData ,&_repl);
_crefs = omc_Inline_getFunctionInputsOutputBody(threadData, _fn, _repl ,&_lst_cr ,&_stmts ,&_repl);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_repl = omc_Inline_mergeFunctionBody(threadData, _stmts, _repl, tmpMeta[2], NULL);
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp8;
modelica_metatype __omcQ_24tmpVar0;
int tmp9;
modelica_metatype _cr_loopVar = 0;
modelica_metatype _cr;
_cr_loopVar = _lst_cr;
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta[3];
tmp8 = &__omcQ_24tmpVar1;
while(1) {
tmp9 = 1;
if (!listEmpty(_cr_loopVar)) {
_cr = MMC_CAR(_cr_loopVar);
_cr_loopVar = MMC_CDR(_cr_loopVar);
tmp9--;
}
if (tmp9 == 0) {
__omcQ_24tmpVar0 = omc_VarTransform_getReplacement(threadData, _repl, _cr);
*tmp8 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp8 = &MMC_CDR(*tmp8);
} else if (tmp9 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp8 = mmc_mk_nil();
tmpMeta[2] = __omcQ_24tmpVar1;
}
_newExp = omc_Expression_makeTuple(threadData, tmpMeta[2]);
tmp10 = omc_Inline_checkExpsTypeEquiv(threadData, _e1, _newExp);
if (1 != tmp10) goto goto_2;
_argmap = omc_List_zip(threadData, _crefs, _args);
_argmap = omc_Inline_extendCrefRecords(threadData, _argmap, _checkcr ,&_checkcr);
_generateEvents = omc_Inline_hasGenerateEventsAnnotation(threadData, _comment);
_newExp = ((!_generateEvents)?omc_Expression_addNoEventToRelationsAndConds(threadData, _newExp):_newExp);
tmpMeta[4] = mmc_mk_box3(0, _argmap, _checkcr, mmc_mk_boolean(1));
tmpMeta[5] = omc_Expression_traverseExpBottomUp(threadData, _newExp, boxvar_Inline_replaceArgs, tmpMeta[4], &tmpMeta[2]);
_newExp = tmpMeta[5];
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmp11 = mmc_unbox_integer(tmpMeta[3]);
if (1 != tmp11) goto goto_2;
tmpMeta[2] = mmc_mk_box2(0, _fns, omc_AvlSetPath_add(threadData, _visitedPaths, _p));
tmpMeta[0+0] = omc_Expression_traverseExpBottomUp(threadData, _newExp, (modelica_fnptr) mmc_mk_box2(0,closure2_Inline_forceInlineCall,tmpMeta[2]), _assrtLst, &tmpMeta[0+1]);
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inTpl;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_cr = tmpMeta[1];
_exp = tmpMeta[2];
tmpMeta[0] = stringAppend(omc_ComponentReference_printComponentRefStr(threadData, _cr),_OMC_LIT30);
tmpMeta[1] = stringAppend(tmpMeta[0],omc_ExpressionDump_printExpStr(threadData, _exp));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT31);
fputs(MMC_STRINGDATA(tmpMeta[2]),stdout);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_boolean omc_Inline_hasGenerateEventsAnnotation(threadData_t *threadData, modelica_metatype _comment)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
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
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_anno = tmpMeta[2];
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
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _assrtIn;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],8,4) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
_cond = tmpMeta[1];
_msg = tmpMeta[2];
_level = tmpMeta[3];
_source = tmpMeta[4];
tmpMeta[2] = mmc_mk_box3(0, _argmap, _checkcr, mmc_mk_boolean(1));
tmpMeta[3] = omc_Expression_traverseExpBottomUp(threadData, _cond, boxvar_Inline_replaceArgs, tmpMeta[2], &tmpMeta[0]);
_cond = tmpMeta[3];
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmp1 = mmc_unbox_integer(tmpMeta[1]);
if (1 != tmp1) MMC_THROW_INTERNAL();
tmpMeta[2] = mmc_mk_box3(0, _argmap, _checkcr, mmc_mk_boolean(1));
tmpMeta[3] = omc_Expression_traverseExpBottomUp(threadData, _msg, boxvar_Inline_replaceArgs, tmpMeta[2], &tmpMeta[0]);
_msg = tmpMeta[3];
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmp2 = mmc_unbox_integer(tmpMeta[1]);
if (1 != tmp2) MMC_THROW_INTERNAL();
tmpMeta[0] = mmc_mk_box5(11, &DAE_Statement_STMT__ASSERT__desc, _cond, _msg, _level, _source);
_assrtOut = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _assrtOut;
}
static modelica_metatype closure3_Inline_inlineCall(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_exp, modelica_metatype $in_assrtLst, modelica_metatype tmp12)
{
modelica_metatype fns = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_Inline_inlineCall(thData, $in_exp, $in_assrtLst, fns, tmp12);
}static modelica_metatype closure4_Inline_inlineCall(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_exp, modelica_metatype $in_assrtLst, modelica_metatype tmp17)
{
modelica_metatype fns = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_Inline_inlineCall(thData, $in_exp, $in_assrtLst, fns, tmp17);
}static modelica_metatype closure5_Inline_inlineCall(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_exp, modelica_metatype $in_assrtLst, modelica_metatype tmp23)
{
modelica_metatype fns = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_Inline_inlineCall(thData, $in_exp, $in_assrtLst, fns, tmp23);
}
DLLExport
modelica_metatype omc_Inline_inlineCall(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype __omcQ_24in_5FassrtLst, modelica_metatype _fns, modelica_metatype *out_assrtLst)
{
modelica_metatype _exp = NULL;
modelica_metatype _assrtLst = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
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
modelica_boolean tmp6;
modelica_boolean tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 7));
_inlineType = tmpMeta[3];
tmp6 = omc_Flags_isSet(threadData, _OMC_LIT36);
if (0 != tmp6) goto goto_2;
tmp7 = valueEq(_OMC_LIT37, _inlineType);
if (0 != tmp7) goto goto_2;
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = _assrtLst;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp8;
modelica_boolean tmp9;
modelica_boolean tmp10;
modelica_integer tmp11;
modelica_boolean tmp15;
modelica_integer tmp16;
modelica_boolean tmp18;
modelica_boolean tmp21;
modelica_integer tmp22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 7));
_e1 = tmp4_1;
_p = tmpMeta[2];
_args = tmpMeta[3];
_ty = tmpMeta[5];
_inlineType = tmpMeta[6];
tmp8 = omc_Inline_checkInlineType(threadData, _inlineType, _fns);
if (1 != tmp8) goto goto_2;
_fn = omc_Inline_getFunctionBody(threadData, _p, _fns ,&_comment);
_checkcr = omc_Inline_getInlineHashTableVarTransform(threadData ,&_repl);
if(omc_Config_acceptMetaModelicaGrammar(threadData))
{
_crefs = omc_List_map(threadData, _fn, boxvar_Inline_getInputCrefs);
_crefs = omc_List_select(threadData, _crefs, boxvar_Inline_removeWilds);
_argmap = omc_List_zip(threadData, _crefs, _args);
tmp9 = omc_List_exist(threadData, _fn, boxvar_DAEUtil_isProtectedVar);
if (0 != tmp9) goto goto_2;
_newExp = omc_Inline_getRhsExp(threadData, _fn);
tmp10 = omc_Inline_checkExpsTypeEquiv(threadData, _e1, _newExp);
if (1 != tmp10) goto goto_2;
_argmap = omc_Inline_extendCrefRecords(threadData, _argmap, _checkcr ,&_checkcr);
_newExp = omc_Expression_addNoEventToRelationsAndConds(threadData, _newExp);
tmpMeta[4] = mmc_mk_box3(0, _argmap, _checkcr, mmc_mk_boolean(1));
tmpMeta[5] = omc_Expression_traverseExpBottomUp(threadData, _newExp, boxvar_Inline_replaceArgs, tmpMeta[4], &tmpMeta[2]);
_newExp = tmpMeta[5];
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmp11 = mmc_unbox_integer(tmpMeta[3]);
if (1 != tmp11) goto goto_2;
tmpMeta[2] = mmc_mk_box1(0, _fns);
_newExp1 = omc_Expression_traverseExpBottomUp(threadData, _newExp, (modelica_fnptr) mmc_mk_box2(0,closure3_Inline_inlineCall,tmpMeta[2]), _assrtLst ,&_assrtLst);
}
else
{
_crefs = omc_Inline_getFunctionInputsOutputBody(threadData, _fn, _repl ,&_lst_cr ,&_stmts ,&_repl);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_repl = omc_Inline_mergeFunctionBody(threadData, _stmts, _repl, tmpMeta[2] ,&_assrtStmts);
if(listEmpty(_assrtStmts))
{
{
modelica_metatype __omcQ_24tmpVar3;
modelica_metatype* tmp13;
modelica_metatype __omcQ_24tmpVar2;
int tmp14;
modelica_metatype _cr_loopVar = 0;
modelica_metatype _cr;
_cr_loopVar = _lst_cr;
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta[3];
tmp13 = &__omcQ_24tmpVar3;
while(1) {
tmp14 = 1;
if (!listEmpty(_cr_loopVar)) {
_cr = MMC_CAR(_cr_loopVar);
_cr_loopVar = MMC_CDR(_cr_loopVar);
tmp14--;
}
if (tmp14 == 0) {
__omcQ_24tmpVar2 = omc_Inline_getReplacementCheckComplex(threadData, _repl, _cr, _ty);
*tmp13 = mmc_mk_cons(__omcQ_24tmpVar2,0);
tmp13 = &MMC_CDR(*tmp13);
} else if (tmp14 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp13 = mmc_mk_nil();
tmpMeta[2] = __omcQ_24tmpVar3;
}
_newExp = omc_Expression_makeTuple(threadData, tmpMeta[2]);
tmp15 = omc_Inline_checkExpsTypeEquiv(threadData, _e1, _newExp);
if (1 != tmp15) goto goto_2;
_argmap = omc_List_zip(threadData, _crefs, _args);
_checkcr = omc_Inline_getInlineHashTableVarTransform(threadData, NULL);
_argmap = omc_Inline_extendCrefRecords(threadData, _argmap, _checkcr ,&_checkcr);
_generateEvents = omc_Inline_hasGenerateEventsAnnotation(threadData, _comment);
_newExp = ((!_generateEvents)?omc_Expression_addNoEventToRelationsAndConds(threadData, _newExp):_newExp);
tmpMeta[4] = mmc_mk_box3(0, _argmap, _checkcr, mmc_mk_boolean(1));
tmpMeta[5] = omc_Expression_traverseExpBottomUp(threadData, _newExp, boxvar_Inline_replaceArgs, tmpMeta[4], &tmpMeta[2]);
_newExp = tmpMeta[5];
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmp16 = mmc_unbox_integer(tmpMeta[3]);
if (1 != tmp16) goto goto_2;
tmpMeta[2] = mmc_mk_box1(0, _fns);
_newExp1 = omc_Expression_traverseExpBottomUp(threadData, _newExp, (modelica_fnptr) mmc_mk_box2(0,closure4_Inline_inlineCall,tmpMeta[2]), _assrtLst ,&_assrtLst);
}
else
{
tmp18 = (listLength(_assrtStmts) == ((modelica_integer) 1));
if (1 != tmp18) goto goto_2;
_assrt = listHead(_assrtStmts);
tmpMeta[2] = _assrt;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],8,4) == 0) goto goto_2;
{
modelica_metatype __omcQ_24tmpVar5;
modelica_metatype* tmp19;
modelica_metatype __omcQ_24tmpVar4;
int tmp20;
modelica_metatype _cr_loopVar = 0;
modelica_metatype _cr;
_cr_loopVar = _lst_cr;
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar5 = tmpMeta[3];
tmp19 = &__omcQ_24tmpVar5;
while(1) {
tmp20 = 1;
if (!listEmpty(_cr_loopVar)) {
_cr = MMC_CAR(_cr_loopVar);
_cr_loopVar = MMC_CDR(_cr_loopVar);
tmp20--;
}
if (tmp20 == 0) {
__omcQ_24tmpVar4 = omc_Inline_getReplacementCheckComplex(threadData, _repl, _cr, _ty);
*tmp19 = mmc_mk_cons(__omcQ_24tmpVar4,0);
tmp19 = &MMC_CDR(*tmp19);
} else if (tmp20 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp19 = mmc_mk_nil();
tmpMeta[2] = __omcQ_24tmpVar5;
}
_newExp = omc_Expression_makeTuple(threadData, tmpMeta[2]);
tmp21 = omc_Inline_checkExpsTypeEquiv(threadData, _e1, _newExp);
if (1 != tmp21) goto goto_2;
_argmap = omc_List_zip(threadData, _crefs, _args);
_argmap = omc_Inline_extendCrefRecords(threadData, _argmap, _checkcr ,&_checkcr);
_generateEvents = omc_Inline_hasGenerateEventsAnnotation(threadData, _comment);
_newExp = ((!_generateEvents)?omc_Expression_addNoEventToRelationsAndConds(threadData, _newExp):_newExp);
tmpMeta[4] = mmc_mk_box3(0, _argmap, _checkcr, mmc_mk_boolean(1));
tmpMeta[5] = omc_Expression_traverseExpBottomUp(threadData, _newExp, boxvar_Inline_replaceArgs, tmpMeta[4], &tmpMeta[2]);
_newExp = tmpMeta[5];
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmp22 = mmc_unbox_integer(tmpMeta[3]);
if (1 != tmp22) goto goto_2;
_assrt = omc_Inline_inlineAssert(threadData, _assrt, _fns, _argmap, _checkcr);
tmpMeta[2] = mmc_mk_box1(0, _fns);
tmpMeta[3] = mmc_mk_cons(_assrt, _assrtLst);
_newExp1 = omc_Expression_traverseExpBottomUp(threadData, _newExp, (modelica_fnptr) mmc_mk_box2(0,closure5_Inline_inlineCall,tmpMeta[2]), tmpMeta[3] ,&_assrtLst);
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
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[3] = MMC_CAR(tmp4_1);
tmpMeta[4] = MMC_CDR(tmp4_1);
_e = tmpMeta[3];
_exps = tmpMeta[4];
_e = omc_Inline_inlineExp(threadData, _e, _fns, _inSource ,&_source ,&_b ,NULL);
tmpMeta[3] = mmc_mk_cons(_e, _iAcc);
_inExps = _exps;
_inSource = _source;
_iAcc = tmpMeta[3];
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
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outExps = omc_Inline_inlineExpsWork(threadData, _inExps, _inElementList, _inSource, tmpMeta[0], 0 ,&_outSource ,&_inlined);
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
static modelica_metatype closure6_Inline_forceInlineCall(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_exp, modelica_metatype $in_assrtLst, modelica_metatype tmp6)
{
modelica_metatype fns = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype visitedPaths = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_Inline_forceInlineCall(thData, $in_exp, $in_assrtLst, fns, visitedPaths, tmp6);
}
DLLExport
modelica_metatype omc_Inline_forceInlineExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inElementList, modelica_metatype _inSource, modelica_metatype *out_outSource, modelica_boolean *out_inlineperformed)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outSource = NULL;
modelica_boolean _inlineperformed;
modelica_boolean tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
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
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
if (optionNone(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
_functionTree = tmpMeta[4];
_e = tmp4_1;
_source = tmp4_3;
if (!omc_Expression_isConst(threadData, _inExp)) goto tmp3_end;
_e_1 = omc_Ceval_cevalSimpleWithFunctionTreeReturnExp(threadData, _inExp, _functionTree);
tmpMeta[3] = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _e);
tmpMeta[4] = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _e_1);
tmpMeta[5] = mmc_mk_box3(6, &DAE_SymbolicOperation_OP__INLINE__desc, tmpMeta[3], tmpMeta[4]);
_source = omc_ElementSource_addSymbolicTransformation(threadData, _source, tmpMeta[5]);
tmpMeta[0+0] = _e_1;
tmpMeta[0+1] = _source;
tmp1_c2 = 1;
goto tmp3_done;
}
case 1: {
_e = tmp4_1;
_fns = tmp4_2;
_source = tmp4_3;
tmpMeta[3] = mmc_mk_box2(0, _fns, _OMC_LIT9);
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
_e_1 = omc_Expression_traverseExpBottomUp(threadData, _e, (modelica_fnptr) mmc_mk_box2(0,closure6_Inline_forceInlineCall,tmpMeta[3]), tmpMeta[4], NULL);
_b = (!referenceEq(_e, _e_1));
if(_b)
{
tmpMeta[3] = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _e);
tmpMeta[4] = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _e_1);
tmpMeta[5] = mmc_mk_box3(6, &DAE_SymbolicOperation_OP__INLINE__desc, tmpMeta[3], tmpMeta[4]);
_source = omc_ElementSource_addSymbolicTransformation(threadData, _source, tmpMeta[5]);
tmpMeta[4] = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _e_1);
tmpMeta[5] = omc_ExpressionSimplify_simplifyAddSymbolicOperation(threadData, tmpMeta[4], _source, &tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],0,1) == 0) goto goto_2;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
_e_1 = tmpMeta[6];
_source = tmpMeta[3];
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
static modelica_metatype closure7_Inline_inlineCall(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_exp, modelica_metatype $in_assrtLst, modelica_metatype tmp6)
{
modelica_metatype fns = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_Inline_inlineCall(thData, $in_exp, $in_assrtLst, fns, tmp6);
}
DLLExport
modelica_metatype omc_Inline_inlineExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inElementList, modelica_metatype _inSource, modelica_metatype *out_outSource, modelica_boolean *out_inlined, modelica_metatype *out_assrtLstOut)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outSource = NULL;
modelica_boolean _inlined;
modelica_metatype _assrtLstOut = NULL;
modelica_boolean tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],4,0) == 0) goto tmp3_end;
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inSource;
tmp1_c2 = 0;
tmpMeta[0+3] = tmpMeta[4];
goto tmp3_done;
}
case 1: {
modelica_boolean tmp7;
_e = tmp4_1;
_fns = tmp4_2;
_source = tmp4_3;
tmpMeta[4] = mmc_mk_box1(0, _fns);
tmpMeta[5] = MMC_REFSTRUCTLIT(mmc_nil);
_e_1 = omc_Expression_traverseExpBottomUp(threadData, _e, (modelica_fnptr) mmc_mk_box2(0,closure7_Inline_inlineCall,tmpMeta[4]), tmpMeta[5] ,&_assrtLst);
tmp7 = referenceEq(_e, _e_1);
if (0 != tmp7) goto goto_2;
if(omc_Flags_isSet(threadData, _OMC_LIT41))
{
tmpMeta[4] = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _e);
tmpMeta[5] = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _e_1);
tmpMeta[6] = mmc_mk_box3(6, &DAE_SymbolicOperation_OP__INLINE__desc, tmpMeta[4], tmpMeta[5]);
_source = omc_ElementSource_addSymbolicTransformation(threadData, _source, tmpMeta[6]);
tmpMeta[5] = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _e_1);
tmpMeta[6] = omc_ExpressionSimplify_simplifyAddSymbolicOperation(threadData, tmpMeta[5], _source, &tmpMeta[4]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],0,1) == 0) goto goto_2;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
_e_2 = tmpMeta[7];
_source = tmpMeta[4];
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
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inSource;
tmp1_c2 = 0;
tmpMeta[0+3] = tmpMeta[4];
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
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
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
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_exp = tmpMeta[3];
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
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
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
modelica_boolean tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e = tmpMeta[3];
_stmts = tmpMeta[4];
_a_else = tmpMeta[5];
_fns = tmp4_2;
_source = tmp4_3;
tmp4 += 1;
_e_1 = omc_Inline_inlineExp(threadData, _e, _fns, _source ,&_source ,&_b1 ,NULL);
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
_stmts_1 = omc_Inline_inlineStatements(threadData, _stmts, _fns, tmpMeta[3], 0 ,&_b2);
_a_else_1 = omc_Inline_inlineElse(threadData, _a_else, _fns, _source ,&_source ,&_b3);
tmp6 = ((_b1 || _b2) || _b3);
if (1 != tmp6) goto goto_2;
tmpMeta[3] = mmc_mk_box4(4, &DAE_Else_ELSEIF__desc, _e_1, _stmts_1, _a_else_1);
tmpMeta[0+0] = tmpMeta[3];
tmpMeta[0+1] = _source;
tmp1_c2 = 1;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_stmts = tmpMeta[3];
_fns = tmp4_2;
_source = tmp4_3;
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[4] = omc_Inline_inlineStatements(threadData, _stmts, _fns, tmpMeta[3], 0, &tmp7);
_stmts_1 = tmpMeta[4];
if (1 != tmp7) goto goto_2;
tmpMeta[3] = mmc_mk_box2(5, &DAE_Else_ELSE__desc, _stmts_1);
tmpMeta[0+0] = tmpMeta[3];
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
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
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
modelica_boolean tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_t = tmpMeta[2];
_e1 = tmpMeta[3];
_e2 = tmpMeta[4];
_source = tmpMeta[5];
_fns = tmp4_2;
tmp4 += 12;
_e1_1 = omc_Inline_inlineExp(threadData, _e1, _fns, _source ,&_source ,&_b1 ,NULL);
_e2_1 = omc_Inline_inlineExp(threadData, _e2, _fns, _source ,&_source ,&_b2 ,NULL);
tmp6 = (_b1 || _b2);
if (1 != tmp6) goto goto_2;
tmpMeta[2] = mmc_mk_box5(3, &DAE_Statement_STMT__ASSIGN__desc, _t, _e1_1, _e2_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_t = tmpMeta[2];
_explst = tmpMeta[3];
_e = tmpMeta[4];
_source = tmpMeta[5];
_fns = tmp4_2;
tmp4 += 11;
_explst_1 = omc_Inline_inlineExps(threadData, _explst, _fns, _source ,&_source ,&_b1);
_e_1 = omc_Inline_inlineExp(threadData, _e, _fns, _source ,&_source ,&_b2 ,NULL);
tmp7 = (_b1 || _b2);
if (1 != tmp7) goto goto_2;
tmpMeta[2] = mmc_mk_box5(4, &DAE_Statement_STMT__TUPLE__ASSIGN__desc, _t, _explst_1, _e_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_t = tmpMeta[2];
_e1 = tmpMeta[3];
_e2 = tmpMeta[4];
_source = tmpMeta[5];
_fns = tmp4_2;
tmp4 += 10;
_e1_1 = omc_Inline_inlineExp(threadData, _e1, _fns, _source ,&_source ,&_b1 ,NULL);
_e2_1 = omc_Inline_inlineExp(threadData, _e2, _fns, _source ,&_source ,&_b2 ,NULL);
tmp8 = (_b1 || _b2);
if (1 != tmp8) goto goto_2;
tmpMeta[2] = mmc_mk_box5(5, &DAE_Statement_STMT__ASSIGN__ARR__desc, _t, _e1_1, _e2_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 3: {
modelica_boolean tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e = tmpMeta[2];
_stmts = tmpMeta[3];
_a_else = tmpMeta[4];
_source = tmpMeta[5];
_fns = tmp4_2;
tmp4 += 9;
_e_1 = omc_Inline_inlineExp(threadData, _e, _fns, _source ,&_source ,&_b1 ,NULL);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_stmts_1 = omc_Inline_inlineStatements(threadData, _stmts, _fns, tmpMeta[2], 0 ,&_b2);
_a_else_1 = omc_Inline_inlineElse(threadData, _a_else, _fns, _source ,&_source ,&_b3);
tmp9 = ((_b1 || _b2) || _b3);
if (1 != tmp9) goto goto_2;
tmpMeta[2] = mmc_mk_box5(6, &DAE_Statement_STMT__IF__desc, _e_1, _stmts_1, _a_else_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 4: {
modelica_integer tmp10;
modelica_integer tmp11;
modelica_boolean tmp12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,7) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp10 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmp11 = mmc_unbox_integer(tmpMeta[5]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_t = tmpMeta[2];
_b = tmp10;
_i = tmpMeta[4];
_ix = tmp11;
_e = tmpMeta[6];
_stmts = tmpMeta[7];
_source = tmpMeta[8];
_fns = tmp4_2;
tmp4 += 8;
_e_1 = omc_Inline_inlineExp(threadData, _e, _fns, _source ,&_source ,&_b1 ,NULL);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_stmts_1 = omc_Inline_inlineStatements(threadData, _stmts, _fns, tmpMeta[2], 0 ,&_b2);
tmp12 = (_b1 || _b2);
if (1 != tmp12) goto goto_2;
tmpMeta[2] = mmc_mk_box8(7, &DAE_Statement_STMT__FOR__desc, _t, mmc_mk_boolean(_b), _i, mmc_mk_integer(_ix), _e_1, _stmts_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 5: {
modelica_boolean tmp13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e = tmpMeta[2];
_stmts = tmpMeta[3];
_source = tmpMeta[4];
_fns = tmp4_2;
tmp4 += 7;
_e_1 = omc_Inline_inlineExp(threadData, _e, _fns, _source ,&_source ,&_b1 ,NULL);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_stmts_1 = omc_Inline_inlineStatements(threadData, _stmts, _fns, tmpMeta[2], 0 ,&_b2);
tmp13 = (_b1 || _b2);
if (1 != tmp13) goto goto_2;
tmpMeta[2] = mmc_mk_box4(9, &DAE_Statement_STMT__WHILE__desc, _e_1, _stmts_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 6: {
modelica_integer tmp14;
modelica_boolean tmp15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,6) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmp14 = mmc_unbox_integer(tmpMeta[4]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (optionNone(tmpMeta[6])) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 1));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
_e = tmpMeta[2];
_conditions = tmpMeta[3];
_initialCall = tmp14;
_stmts = tmpMeta[5];
_stmt = tmpMeta[7];
_source = tmpMeta[8];
_fns = tmp4_2;
tmp4 += 6;
_e_1 = omc_Inline_inlineExp(threadData, _e, _fns, _source ,&_source ,&_b1 ,NULL);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_stmts_1 = omc_Inline_inlineStatements(threadData, _stmts, _fns, tmpMeta[2], 0 ,&_b2);
_stmt_1 = omc_Inline_inlineStatement(threadData, _stmt, _fns ,&_b3);
tmp15 = ((_b1 || _b2) || _b3);
if (1 != tmp15) goto goto_2;
tmpMeta[2] = mmc_mk_box7(10, &DAE_Statement_STMT__WHEN__desc, _e_1, _conditions, mmc_mk_boolean(_initialCall), _stmts_1, mmc_mk_some(_stmt_1), _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 7: {
modelica_integer tmp16;
modelica_boolean tmp17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,6) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmp16 = mmc_unbox_integer(tmpMeta[4]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (!optionNone(tmpMeta[6])) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
_e = tmpMeta[2];
_conditions = tmpMeta[3];
_initialCall = tmp16;
_stmts = tmpMeta[5];
_source = tmpMeta[7];
_fns = tmp4_2;
tmp4 += 5;
_e_1 = omc_Inline_inlineExp(threadData, _e, _fns, _source ,&_source ,&_b1 ,NULL);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_stmts_1 = omc_Inline_inlineStatements(threadData, _stmts, _fns, tmpMeta[2], 0 ,&_b2);
tmp17 = (_b1 || _b2);
if (1 != tmp17) goto goto_2;
tmpMeta[2] = mmc_mk_box7(10, &DAE_Statement_STMT__WHEN__desc, _e_1, _conditions, mmc_mk_boolean(_initialCall), _stmts_1, mmc_mk_none(), _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 8: {
modelica_boolean tmp18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e1 = tmpMeta[2];
_e2 = tmpMeta[3];
_e3 = tmpMeta[4];
_source = tmpMeta[5];
_fns = tmp4_2;
tmp4 += 4;
_e1_1 = omc_Inline_inlineExp(threadData, _e1, _fns, _source ,&_source ,&_b1 ,NULL);
_e2_1 = omc_Inline_inlineExp(threadData, _e2, _fns, _source ,&_source ,&_b2 ,NULL);
_e3_1 = omc_Inline_inlineExp(threadData, _e3, _fns, _source ,&_source ,&_b3 ,NULL);
tmp18 = ((_b1 || _b2) || _b3);
if (1 != tmp18) goto goto_2;
tmpMeta[2] = mmc_mk_box5(11, &DAE_Statement_STMT__ASSERT__desc, _e1_1, _e2_1, _e3_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 9: {
modelica_boolean tmp19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmpMeta[2];
_source = tmpMeta[3];
_fns = tmp4_2;
tmp4 += 3;
tmpMeta[3] = omc_Inline_inlineExp(threadData, _e, _fns, _source, &tmpMeta[2], &tmp19, NULL);
_e_1 = tmpMeta[3];
if (1 != tmp19) goto goto_2;
_source = tmpMeta[2];
tmpMeta[2] = mmc_mk_box3(12, &DAE_Statement_STMT__TERMINATE__desc, _e_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 10: {
modelica_boolean tmp20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta[2];
_e2 = tmpMeta[3];
_source = tmpMeta[4];
_fns = tmp4_2;
tmp4 += 2;
_e1_1 = omc_Inline_inlineExp(threadData, _e1, _fns, _source ,&_source ,&_b1 ,NULL);
_e2_1 = omc_Inline_inlineExp(threadData, _e2, _fns, _source ,&_source ,&_b2 ,NULL);
tmp20 = (_b1 || _b2);
if (1 != tmp20) goto goto_2;
tmpMeta[2] = mmc_mk_box4(13, &DAE_Statement_STMT__REINIT__desc, _e1_1, _e2_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 11: {
modelica_boolean tmp21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmpMeta[2];
_source = tmpMeta[3];
_fns = tmp4_2;
tmp4 += 1;
tmpMeta[3] = omc_Inline_inlineExp(threadData, _e, _fns, _source, &tmpMeta[2], &tmp21, NULL);
_e_1 = tmpMeta[3];
if (1 != tmp21) goto goto_2;
_source = tmpMeta[2];
tmpMeta[2] = mmc_mk_box3(14, &DAE_Statement_STMT__NORETCALL__desc, _e_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 12: {
modelica_boolean tmp22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_stmts = tmpMeta[2];
_source = tmpMeta[3];
_fns = tmp4_2;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[3] = omc_Inline_inlineStatements(threadData, _stmts, _fns, tmpMeta[2], 0, &tmp22);
_stmts_1 = tmpMeta[3];
if (1 != tmp22) goto goto_2;
tmpMeta[2] = mmc_mk_box3(19, &DAE_Statement_STMT__FAILURE__desc, _stmts_1, _source);
tmpMeta[0+0] = tmpMeta[2];
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
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
_stmt = tmpMeta[2];
_rest = tmpMeta[3];
_stmt = omc_Inline_inlineStatement(threadData, _stmt, _inElementList ,&_inlined);
tmpMeta[2] = mmc_mk_cons(_stmt, _iAcc);
_inStatements = _rest;
_iAcc = tmpMeta[2];
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
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
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_stmts = tmpMeta[2];
_fns = tmp4_2;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_stmts_1 = omc_Inline_inlineStatements(threadData, _stmts, _fns, tmpMeta[2], 0 ,&_inlined);
tmpMeta[2] = mmc_mk_box2(3, &DAE_Algorithm_ALGORITHM__STMTS__desc, _stmts_1);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = _inlined;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
tmp6 = omc_Flags_isSet(threadData, _OMC_LIT21);
if (1 != tmp6) goto goto_2;
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
modelica_metatype tmpMeta[16] __attribute__((unused)) = {0};
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
modelica_boolean tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
if (optionNone(tmpMeta[8])) goto tmp3_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 1));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 9));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 10));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 11));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 12));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 13));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 14));
_componentRef = tmpMeta[2];
_kind = tmpMeta[3];
_direction = tmpMeta[4];
_parallelism = tmpMeta[5];
_protection = tmpMeta[6];
_ty = tmpMeta[7];
_binding = tmpMeta[9];
_dims = tmpMeta[10];
_ct = tmpMeta[11];
_source = tmpMeta[12];
_variableAttributesOption = tmpMeta[13];
_absynCommentOption = tmpMeta[14];
_innerOuter = tmpMeta[15];
_fns = tmp4_2;
tmp4 += 22;
tmpMeta[3] = omc_Inline_inlineExp(threadData, _binding, _fns, _source, &tmpMeta[2], &tmp6, NULL);
_binding_1 = tmpMeta[3];
if (1 != tmp6) goto goto_2;
_source = tmpMeta[2];
tmpMeta[2] = mmc_mk_box14(3, &DAE_Element_VAR__desc, _componentRef, _kind, _direction, _parallelism, _protection, _ty, mmc_mk_some(_binding_1), _dims, _ct, _source, _variableAttributesOption, _absynCommentOption, _innerOuter);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_componentRef = tmpMeta[2];
_exp = tmpMeta[3];
_source = tmpMeta[4];
_fns = tmp4_2;
tmp4 += 21;
tmpMeta[3] = omc_Inline_inlineExp(threadData, _exp, _fns, _source, &tmpMeta[2], &tmp7, NULL);
_exp_1 = tmpMeta[3];
if (1 != tmp7) goto goto_2;
_source = tmpMeta[2];
tmpMeta[2] = mmc_mk_box4(4, &DAE_Element_DEFINE__desc, _componentRef, _exp_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_componentRef = tmpMeta[2];
_exp = tmpMeta[3];
_source = tmpMeta[4];
_fns = tmp4_2;
tmp4 += 20;
tmpMeta[3] = omc_Inline_inlineExp(threadData, _exp, _fns, _source, &tmpMeta[2], &tmp8, NULL);
_exp_1 = tmpMeta[3];
if (1 != tmp8) goto goto_2;
_source = tmpMeta[2];
tmpMeta[2] = mmc_mk_box4(5, &DAE_Element_INITIALDEFINE__desc, _componentRef, _exp_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 3: {
modelica_boolean tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_exp1 = tmpMeta[2];
_exp2 = tmpMeta[3];
_source = tmpMeta[4];
_fns = tmp4_2;
tmp4 += 19;
_exp1_1 = omc_Inline_inlineExp(threadData, _exp1, _fns, _source ,&_source ,&_b1 ,NULL);
_exp2_1 = omc_Inline_inlineExp(threadData, _exp2, _fns, _source ,&_source ,&_b2 ,NULL);
tmp9 = (_b1 || _b2);
if (1 != tmp9) goto goto_2;
tmpMeta[2] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _exp1_1, _exp2_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 4: {
modelica_boolean tmp10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_dimension = tmpMeta[2];
_exp1 = tmpMeta[3];
_exp2 = tmpMeta[4];
_source = tmpMeta[5];
_fns = tmp4_2;
tmp4 += 18;
_exp1_1 = omc_Inline_inlineExp(threadData, _exp1, _fns, _source ,&_source ,&_b1 ,NULL);
_exp2_1 = omc_Inline_inlineExp(threadData, _exp2, _fns, _source ,&_source ,&_b2 ,NULL);
tmp10 = (_b1 || _b2);
if (1 != tmp10) goto goto_2;
tmpMeta[2] = mmc_mk_box5(8, &DAE_Element_ARRAY__EQUATION__desc, _dimension, _exp1_1, _exp2_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 5: {
modelica_boolean tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_dimension = tmpMeta[2];
_exp1 = tmpMeta[3];
_exp2 = tmpMeta[4];
_source = tmpMeta[5];
_fns = tmp4_2;
tmp4 += 17;
_exp1_1 = omc_Inline_inlineExp(threadData, _exp1, _fns, _source ,&_source ,&_b1 ,NULL);
_exp2_1 = omc_Inline_inlineExp(threadData, _exp2, _fns, _source ,&_source ,&_b2 ,NULL);
tmp11 = (_b1 || _b2);
if (1 != tmp11) goto goto_2;
tmpMeta[2] = mmc_mk_box5(9, &DAE_Element_INITIAL__ARRAY__EQUATION__desc, _dimension, _exp1_1, _exp2_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 6: {
modelica_boolean tmp12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_exp1 = tmpMeta[2];
_exp2 = tmpMeta[3];
_source = tmpMeta[4];
_fns = tmp4_2;
tmp4 += 16;
_exp1_1 = omc_Inline_inlineExp(threadData, _exp1, _fns, _source ,&_source ,&_b1 ,NULL);
_exp2_1 = omc_Inline_inlineExp(threadData, _exp2, _fns, _source ,&_source ,&_b2 ,NULL);
tmp12 = (_b1 || _b2);
if (1 != tmp12) goto goto_2;
tmpMeta[2] = mmc_mk_box4(11, &DAE_Element_COMPLEX__EQUATION__desc, _exp1_1, _exp2_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 7: {
modelica_boolean tmp13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_exp1 = tmpMeta[2];
_exp2 = tmpMeta[3];
_source = tmpMeta[4];
_fns = tmp4_2;
tmp4 += 15;
_exp1_1 = omc_Inline_inlineExp(threadData, _exp1, _fns, _source ,&_source ,&_b1 ,NULL);
_exp2_1 = omc_Inline_inlineExp(threadData, _exp2, _fns, _source ,&_source ,&_b2 ,NULL);
tmp13 = (_b1 || _b2);
if (1 != tmp13) goto goto_2;
tmpMeta[2] = mmc_mk_box4(12, &DAE_Element_INITIAL__COMPLEX__EQUATION__desc, _exp1_1, _exp2_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 8: {
modelica_boolean tmp14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (optionNone(tmpMeta[4])) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 1));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_exp = tmpMeta[2];
_elist = tmpMeta[3];
_el = tmpMeta[5];
_source = tmpMeta[6];
_fns = tmp4_2;
tmp4 += 14;
_exp_1 = omc_Inline_inlineExp(threadData, _exp, _fns, _source ,&_source ,&_b1 ,NULL);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_elist_1 = omc_Inline_inlineDAEElements(threadData, _elist, _fns, tmpMeta[2], 0 ,&_b2);
_el_1 = omc_Inline_inlineDAEElement(threadData, _el, _fns ,&_b3);
tmp14 = ((_b1 || _b2) || _b3);
if (1 != tmp14) goto goto_2;
tmpMeta[2] = mmc_mk_box5(13, &DAE_Element_WHEN__EQUATION__desc, _exp_1, _elist_1, mmc_mk_some(_el_1), _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 9: {
modelica_boolean tmp15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!optionNone(tmpMeta[4])) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_exp = tmpMeta[2];
_elist = tmpMeta[3];
_source = tmpMeta[5];
_fns = tmp4_2;
tmp4 += 13;
_exp_1 = omc_Inline_inlineExp(threadData, _exp, _fns, _source ,&_source ,&_b1 ,NULL);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_elist_1 = omc_Inline_inlineDAEElements(threadData, _elist, _fns, tmpMeta[2], 0 ,&_b2);
tmp15 = (_b1 || _b2);
if (1 != tmp15) goto goto_2;
tmpMeta[2] = mmc_mk_box5(13, &DAE_Element_WHEN__EQUATION__desc, _exp_1, _elist_1, mmc_mk_none(), _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 10: {
modelica_boolean tmp16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_explst = tmpMeta[2];
_dlist = tmpMeta[3];
_elist = tmpMeta[4];
_source = tmpMeta[5];
_fns = tmp4_2;
tmp4 += 12;
_explst_1 = omc_Inline_inlineExps(threadData, _explst, _fns, _source ,&_source ,&_b1);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_dlist_1 = omc_Inline_inlineDAEElementsLst(threadData, _dlist, _fns, tmpMeta[2], 0 ,&_b2);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_elist_1 = omc_Inline_inlineDAEElements(threadData, _elist, _fns, tmpMeta[2], 0 ,&_b3);
tmp16 = ((_b1 || _b2) || _b3);
if (1 != tmp16) goto goto_2;
tmpMeta[2] = mmc_mk_box5(15, &DAE_Element_IF__EQUATION__desc, _explst_1, _dlist_1, _elist_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 11: {
modelica_boolean tmp17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_explst = tmpMeta[2];
_dlist = tmpMeta[3];
_elist = tmpMeta[4];
_source = tmpMeta[5];
_fns = tmp4_2;
tmp4 += 11;
_explst_1 = omc_Inline_inlineExps(threadData, _explst, _fns, _source ,&_source ,&_b1);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_dlist_1 = omc_Inline_inlineDAEElementsLst(threadData, _dlist, _fns, tmpMeta[2], 0 ,&_b2);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_elist_1 = omc_Inline_inlineDAEElements(threadData, _elist, _fns, tmpMeta[2], 0 ,&_b3);
tmp17 = ((_b1 || _b2) || _b3);
if (1 != tmp17) goto goto_2;
tmpMeta[2] = mmc_mk_box5(16, &DAE_Element_INITIAL__IF__EQUATION__desc, _explst_1, _dlist_1, _elist_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,14,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_exp1 = tmpMeta[2];
_exp2 = tmpMeta[3];
_source = tmpMeta[4];
_fns = tmp4_2;
tmp4 += 10;
_exp1_1 = omc_Inline_inlineExp(threadData, _exp1, _fns, _source ,&_source ,NULL ,NULL);
_exp2_1 = omc_Inline_inlineExp(threadData, _exp2, _fns, _source ,&_source ,NULL ,NULL);
tmpMeta[2] = mmc_mk_box4(17, &DAE_Element_INITIALEQUATION__desc, _exp1_1, _exp2_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 13: {
modelica_boolean tmp18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_alg = tmpMeta[2];
_source = tmpMeta[3];
_fns = tmp4_2;
tmp4 += 9;
tmpMeta[2] = omc_Inline_inlineAlgorithm(threadData, _alg, _fns, &tmp18);
_alg_1 = tmpMeta[2];
if (1 != tmp18) goto goto_2;
tmpMeta[2] = mmc_mk_box3(18, &DAE_Element_ALGORITHM__desc, _alg_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 14: {
modelica_boolean tmp19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_alg = tmpMeta[2];
_source = tmpMeta[3];
_fns = tmp4_2;
tmp4 += 8;
tmpMeta[2] = omc_Inline_inlineAlgorithm(threadData, _alg, _fns, &tmp19);
_alg_1 = tmpMeta[2];
if (1 != tmp19) goto goto_2;
tmpMeta[2] = mmc_mk_box3(19, &DAE_Element_INITIALALGORITHM__desc, _alg_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 15: {
modelica_boolean tmp20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_i = tmpMeta[2];
_elist = tmpMeta[3];
_source = tmpMeta[4];
_absynCommentOption = tmpMeta[5];
_fns = tmp4_2;
tmp4 += 7;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[3] = omc_Inline_inlineDAEElements(threadData, _elist, _fns, tmpMeta[2], 0, &tmp20);
_elist_1 = tmpMeta[3];
if (1 != tmp20) goto goto_2;
tmpMeta[2] = mmc_mk_box5(20, &DAE_Element_COMP__desc, _i, _elist_1, _source, _absynCommentOption);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 16: {
modelica_boolean tmp21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,19,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_exp1 = tmpMeta[2];
_exp2 = tmpMeta[3];
_exp3 = tmpMeta[4];
_source = tmpMeta[5];
_fns = tmp4_2;
tmp4 += 6;
_exp1_1 = omc_Inline_inlineExp(threadData, _exp1, _fns, _source ,&_source ,&_b1 ,NULL);
_exp2_1 = omc_Inline_inlineExp(threadData, _exp2, _fns, _source ,&_source ,&_b2 ,NULL);
_exp3_1 = omc_Inline_inlineExp(threadData, _exp3, _fns, _source ,&_source ,&_b3 ,NULL);
tmp21 = ((_b1 || _b2) || _b3);
if (1 != tmp21) goto goto_2;
tmpMeta[2] = mmc_mk_box5(22, &DAE_Element_ASSERT__desc, _exp1_1, _exp2_1, _exp3_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 17: {
modelica_boolean tmp22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,20,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_exp1 = tmpMeta[2];
_exp2 = tmpMeta[3];
_exp3 = tmpMeta[4];
_source = tmpMeta[5];
_fns = tmp4_2;
tmp4 += 5;
_exp1_1 = omc_Inline_inlineExp(threadData, _exp1, _fns, _source ,&_source ,&_b1 ,NULL);
_exp2_1 = omc_Inline_inlineExp(threadData, _exp2, _fns, _source ,&_source ,&_b2 ,NULL);
_exp3_1 = omc_Inline_inlineExp(threadData, _exp3, _fns, _source ,&_source ,&_b3 ,NULL);
tmp22 = ((_b1 || _b2) || _b3);
if (1 != tmp22) goto goto_2;
tmpMeta[2] = mmc_mk_box5(23, &DAE_Element_INITIAL__ASSERT__desc, _exp1_1, _exp2_1, _exp3_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 18: {
modelica_boolean tmp23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_exp = tmpMeta[2];
_source = tmpMeta[3];
_fns = tmp4_2;
tmp4 += 4;
tmpMeta[3] = omc_Inline_inlineExp(threadData, _exp, _fns, _source, &tmpMeta[2], &tmp23, NULL);
_exp_1 = tmpMeta[3];
if (1 != tmp23) goto goto_2;
_source = tmpMeta[2];
tmpMeta[2] = mmc_mk_box3(24, &DAE_Element_TERMINATE__desc, _exp_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 19: {
modelica_boolean tmp24;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_exp = tmpMeta[2];
_source = tmpMeta[3];
_fns = tmp4_2;
tmp4 += 3;
tmpMeta[3] = omc_Inline_inlineExp(threadData, _exp, _fns, _source, &tmpMeta[2], &tmp24, NULL);
_exp_1 = tmpMeta[3];
if (1 != tmp24) goto goto_2;
_source = tmpMeta[2];
tmpMeta[2] = mmc_mk_box3(25, &DAE_Element_INITIAL__TERMINATE__desc, _exp_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 20: {
modelica_boolean tmp25;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,23,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_componentRef = tmpMeta[2];
_exp = tmpMeta[3];
_source = tmpMeta[4];
_fns = tmp4_2;
tmp4 += 2;
tmpMeta[3] = omc_Inline_inlineExp(threadData, _exp, _fns, _source, &tmpMeta[2], &tmp25, NULL);
_exp_1 = tmpMeta[3];
if (1 != tmp25) goto goto_2;
_source = tmpMeta[2];
tmpMeta[2] = mmc_mk_box4(26, &DAE_Element_REINIT__desc, _componentRef, _exp_1, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 21: {
modelica_boolean tmp26;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_exp = tmpMeta[2];
_source = tmpMeta[3];
_fns = tmp4_2;
tmp4 += 1;
tmpMeta[3] = omc_Inline_inlineExp(threadData, _exp, _fns, _source, &tmpMeta[2], &tmp26, NULL);
_exp = tmpMeta[3];
if (1 != tmp26) goto goto_2;
_source = tmpMeta[2];
tmpMeta[2] = mmc_mk_box3(27, &DAE_Element_NORETCALL__desc, _exp, _source);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 22: {
modelica_boolean tmp27;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,25,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_exp = tmpMeta[2];
_source = tmpMeta[3];
_fns = tmp4_2;
tmpMeta[3] = omc_Inline_inlineExp(threadData, _exp, _fns, _source, &tmpMeta[2], &tmp27, NULL);
_exp = tmpMeta[3];
if (1 != tmp27) goto goto_2;
_source = tmpMeta[2];
tmpMeta[2] = mmc_mk_box3(28, &DAE_Element_INITIAL__NORETCALL__desc, _exp, _source);
tmpMeta[0+0] = tmpMeta[2];
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
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
_elem = tmpMeta[2];
_rest = tmpMeta[3];
_elem = omc_Inline_inlineDAEElement(threadData, _elem, _inFunctions ,&_inlined);
tmpMeta[2] = mmc_mk_cons(_elem, _iAcc);
_inElementList = _rest;
_iAcc = tmpMeta[2];
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
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
_elem = tmpMeta[2];
_rest = tmpMeta[3];
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_elem = omc_Inline_inlineDAEElements(threadData, _elem, _inFunctions, tmpMeta[2], 0 ,&_inlined);
tmpMeta[2] = mmc_mk_cons(_elem, _iAcc);
_inElementList = _rest;
_iAcc = tmpMeta[2];
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
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar7;
modelica_metatype* tmp1;
modelica_metatype __omcQ_24tmpVar6;
int tmp8;
modelica_metatype _fn_loopVar = 0;
modelica_metatype _fn;
_fn_loopVar = _inElementList;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar7 = tmpMeta[1];
tmp1 = &__omcQ_24tmpVar7;
while(1) {
tmp8 = 1;
if (!listEmpty(_fn_loopVar)) {
_fn = MMC_CAR(_fn_loopVar);
_fn_loopVar = MMC_CDR(_fn_loopVar);
tmp8--;
}
if (tmp8 == 0) {
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _fn;
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
modelica_boolean tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,10) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,1) == 0) goto tmp3_end;
_fn_def = tmpMeta[4];
_fn_defs = tmpMeta[5];
tmp4 += 1;
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[4] = omc_Inline_inlineDAEElements(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn_def), 2))), _inFunctions, tmpMeta[3], 0, &tmp6);
_body = tmpMeta[4];
if (1 != tmp6) goto goto_2;
tmpMeta[3] = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta[3]), MMC_UNTAGPTR(_fn_def), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[3]))[2] = _body;
_fn_def = tmpMeta[3];
tmpMeta[4] = mmc_mk_cons(_fn_def, _fn_defs);
tmpMeta[3] = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta[3]), MMC_UNTAGPTR(_fn), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[3]))[3] = tmpMeta[4];
_fn = tmpMeta[3];
tmpMeta[2] = _fn;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,10) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,2) == 0) goto tmp3_end;
_fn_def = tmpMeta[4];
_fn_defs = tmpMeta[5];
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[4] = omc_Inline_inlineDAEElements(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn_def), 2))), _inFunctions, tmpMeta[3], 0, &tmp7);
_body = tmpMeta[4];
if (1 != tmp7) goto goto_2;
tmpMeta[3] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[3]), MMC_UNTAGPTR(_fn_def), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[3]))[2] = _body;
_fn_def = tmpMeta[3];
tmpMeta[4] = mmc_mk_cons(_fn_def, _fn_defs);
tmpMeta[3] = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta[3]), MMC_UNTAGPTR(_fn), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[3]))[3] = tmpMeta[4];
_fn = tmpMeta[3];
tmpMeta[2] = _fn;
goto tmp3_done;
}
case 2: {
tmpMeta[2] = _fn;
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
}__omcQ_24tmpVar6 = tmpMeta[2];
*tmp1 = mmc_mk_cons(__omcQ_24tmpVar6,0);
tmp1 = &MMC_CDR(*tmp1);
} else if (tmp8 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp1 = mmc_mk_nil();
tmpMeta[0] = __omcQ_24tmpVar7;
}
_outElementList = tmpMeta[0];
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
modelica_metatype tmpMeta[20] __attribute__((unused)) = {0};
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
modelica_boolean tmp6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,15) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 5));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 6));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 7));
if (optionNone(tmpMeta[9])) goto tmp3_end;
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[9]), 1));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 8));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 9));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 10));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 11));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 12));
tmpMeta[16] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 13));
tmpMeta[17] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 14));
tmpMeta[18] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 15));
tmpMeta[19] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 16));
_quantity = tmpMeta[4];
_unit = tmpMeta[5];
_displayUnit = tmpMeta[6];
_min = tmpMeta[7];
_max = tmpMeta[8];
_r = tmpMeta[10];
_fixed = tmpMeta[11];
_nominal = tmpMeta[12];
_stateSelectOption = tmpMeta[13];
_uncertainOption = tmpMeta[14];
_distributionOption = tmpMeta[15];
_equationBound = tmpMeta[16];
_isProtected = tmpMeta[17];
_finalPrefix = tmpMeta[18];
_so = tmpMeta[19];
tmp4 += 4;
tmpMeta[4] = omc_Inline_inlineExp(threadData, _r, _fns, _isource, &tmpMeta[3], &tmp6, NULL);
_r = tmpMeta[4];
if (1 != tmp6) goto goto_2;
_source = tmpMeta[3];
tmpMeta[3] = mmc_mk_box16(3, &DAE_VariableAttributes_VAR__ATTR__REAL__desc, _quantity, _unit, _displayUnit, _min, _max, mmc_mk_some(_r), _fixed, _nominal, _stateSelectOption, _uncertainOption, _distributionOption, _equationBound, _isProtected, _finalPrefix, _so);
tmpMeta[0+0] = mmc_mk_some(tmpMeta[3]);
tmpMeta[0+1] = _source;
tmp1_c2 = 1;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp7;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],1,11) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 5));
if (optionNone(tmpMeta[7])) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 1));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 6));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 7));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 8));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 9));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 10));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 11));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 12));
_quantity = tmpMeta[4];
_min = tmpMeta[5];
_max = tmpMeta[6];
_r = tmpMeta[8];
_fixed = tmpMeta[9];
_uncertainOption = tmpMeta[10];
_distributionOption = tmpMeta[11];
_equationBound = tmpMeta[12];
_isProtected = tmpMeta[13];
_finalPrefix = tmpMeta[14];
_so = tmpMeta[15];
tmp4 += 3;
tmpMeta[4] = omc_Inline_inlineExp(threadData, _r, _fns, _isource, &tmpMeta[3], &tmp7, NULL);
_r = tmpMeta[4];
if (1 != tmp7) goto goto_2;
_source = tmpMeta[3];
tmpMeta[3] = mmc_mk_box12(4, &DAE_VariableAttributes_VAR__ATTR__INT__desc, _quantity, _min, _max, mmc_mk_some(_r), _fixed, _uncertainOption, _distributionOption, _equationBound, _isProtected, _finalPrefix, _so);
tmpMeta[0+0] = mmc_mk_some(tmpMeta[3]);
tmpMeta[0+1] = _source;
tmp1_c2 = 1;
goto tmp3_done;
}
case 3: {
modelica_boolean tmp8;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],2,7) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
if (optionNone(tmpMeta[5])) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 1));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 4));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 5));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 6));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 7));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 8));
_quantity = tmpMeta[4];
_r = tmpMeta[6];
_fixed = tmpMeta[7];
_equationBound = tmpMeta[8];
_isProtected = tmpMeta[9];
_finalPrefix = tmpMeta[10];
_so = tmpMeta[11];
tmp4 += 2;
tmpMeta[4] = omc_Inline_inlineExp(threadData, _r, _fns, _isource, &tmpMeta[3], &tmp8, NULL);
_r = tmpMeta[4];
if (1 != tmp8) goto goto_2;
_source = tmpMeta[3];
tmpMeta[3] = mmc_mk_box8(5, &DAE_VariableAttributes_VAR__ATTR__BOOL__desc, _quantity, mmc_mk_some(_r), _fixed, _equationBound, _isProtected, _finalPrefix, _so);
tmpMeta[0+0] = mmc_mk_some(tmpMeta[3]);
tmpMeta[0+1] = _source;
tmp1_c2 = 1;
goto tmp3_done;
}
case 4: {
modelica_boolean tmp9;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],4,7) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
if (optionNone(tmpMeta[5])) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 1));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 4));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 5));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 6));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 7));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 8));
_quantity = tmpMeta[4];
_r = tmpMeta[6];
_fixed = tmpMeta[7];
_equationBound = tmpMeta[8];
_isProtected = tmpMeta[9];
_finalPrefix = tmpMeta[10];
_so = tmpMeta[11];
tmp4 += 1;
tmpMeta[4] = omc_Inline_inlineExp(threadData, _r, _fns, _isource, &tmpMeta[3], &tmp9, NULL);
_r = tmpMeta[4];
if (1 != tmp9) goto goto_2;
_source = tmpMeta[3];
tmpMeta[3] = mmc_mk_box8(7, &DAE_VariableAttributes_VAR__ATTR__STRING__desc, _quantity, mmc_mk_some(_r), _fixed, _equationBound, _isProtected, _finalPrefix, _so);
tmpMeta[0+0] = mmc_mk_some(tmpMeta[3]);
tmpMeta[0+1] = _source;
tmp1_c2 = 1;
goto tmp3_done;
}
case 5: {
modelica_boolean tmp10;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],5,9) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 5));
if (optionNone(tmpMeta[7])) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 1));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 6));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 7));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 8));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 9));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 10));
_quantity = tmpMeta[4];
_min = tmpMeta[5];
_max = tmpMeta[6];
_r = tmpMeta[8];
_fixed = tmpMeta[9];
_equationBound = tmpMeta[10];
_isProtected = tmpMeta[11];
_finalPrefix = tmpMeta[12];
_so = tmpMeta[13];
tmpMeta[4] = omc_Inline_inlineExp(threadData, _r, _fns, _isource, &tmpMeta[3], &tmp10, NULL);
_r = tmpMeta[4];
if (1 != tmp10) goto goto_2;
_source = tmpMeta[3];
tmpMeta[3] = mmc_mk_box10(8, &DAE_VariableAttributes_VAR__ATTR__ENUMERATION__desc, _quantity, _min, _max, mmc_mk_some(_r), _fixed, _equationBound, _isProtected, _finalPrefix, _so);
tmpMeta[0+0] = mmc_mk_some(tmpMeta[3]);
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
