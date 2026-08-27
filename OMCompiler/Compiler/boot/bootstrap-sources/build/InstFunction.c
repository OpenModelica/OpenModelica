#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/InstFunction.c"
#endif
#include "omc_simulation_settings.h"
#include "InstFunction.h"
#define _OMC_LIT0_data "constructor"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,11,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT0}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,1,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "Function %s returns an external object, but the only function allowed to return this object is %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,98,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT5}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(546)),_OMC_LIT3,_OMC_LIT4,_OMC_LIT6}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT8,1,6) {&DAE_InlineType_DEFAULT__INLINE__desc,}};
#define _OMC_LIT8 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,1,3) {&DAE_FunctionBuiltin_FUNCTION__NOT__BUILTIN__desc,}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,1,3) {&DAE_FunctionParallelism_FP__NON__PARALLEL__desc,}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,7,3) {&DAE_FunctionAttributes_FUNCTION__ATTRIBUTES__desc,_OMC_LIT8,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT9,_OMC_LIT10}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,0,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT13,0.0);
#define _OMC_LIT13 MMC_REFREALLIT(_OMC_LIT_STRUCT13)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT14,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT12,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT13}};
#define _OMC_LIT14 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,1,4) {&DAE_ComponentPrefix_NOCOMPPRE__desc,}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT16,8,3) {&DAE_ElementSource_SOURCE__desc,_OMC_LIT14,MMC_REFSTRUCTLIT(mmc_nil),_OMC_LIT15,MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT16 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT16)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT17,1,4) {&SCode_Partial_NOT__PARTIAL__desc,}};
#define _OMC_LIT17 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT18,1,5) {&DAE_Mod_NOMOD__desc,}};
#define _OMC_LIT18 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,1,3) {&DAE_Prefix_NOPRE__desc,}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT20,1,4) {&InstTypes_CallingScope_INNER__CALL__desc,}};
#define _OMC_LIT20 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT20)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT21,7,3) {&ConnectionGraph_ConnectionGraph_GRAPH__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT21 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT21)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT22,1,7) {&DAE_ComponentRef_WILD__desc,}};
#define _OMC_LIT22 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT22)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT23,5,3) {&DAE_Connect_SetTrieNode_SET__TRIE__NODE__desc,_OMC_LIT12,_OMC_LIT22,MMC_REFSTRUCTLIT(mmc_nil),MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT23 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT23)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT24,5,3) {&DAE_Connect_Sets_SETS__desc,_OMC_LIT23,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT24 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT24)
#define _OMC_LIT25_data "failtrace"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT25,9,_OMC_LIT25_data);
#define _OMC_LIT25 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "Sets whether to print a failtrace or not."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,41,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT27,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT26}};
#define _OMC_LIT27 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT27)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT28,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT25,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT27}};
#define _OMC_LIT28 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data "InstFunction.getRecordConstructorFunction failed for "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,53,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT30,1,6) {&DAE_ExtArg_NOEXTARG__desc,}};
#define _OMC_LIT30 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data "builtin"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,7,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT32,1,5) {&ErrorTypes_Severity_WARNING__desc,}};
#define _OMC_LIT32 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT32)
#define _OMC_LIT33_data "An external declaration with a single output without explicit mapping is defined as having the output as the lhs, but language %s does not support this for array variables. OpenModelica will put the output as an input (as is done when there is more than 1 output), but this is not according to the Modelica Specification. Use an explicit mapping instead of the implicit one to suppress this warning."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT33,399,_OMC_LIT33_data);
#define _OMC_LIT33 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT33)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT34,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT33}};
#define _OMC_LIT34 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT34)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT35,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(290)),_OMC_LIT3,_OMC_LIT32,_OMC_LIT34}};
#define _OMC_LIT35 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT35)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT36,1,4) {&Absyn_Direction_OUTPUT__desc,}};
#define _OMC_LIT36 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT36)
#define _OMC_LIT37_data "instExtMakeDefaultExternalCall failed for "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT37,42,_OMC_LIT37_data);
#define _OMC_LIT37 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT37)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT38,1,3) {&Absyn_Direction_INPUT__desc,}};
#define _OMC_LIT38 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT38)
#define _OMC_LIT39_data "- Inst.instOverloaded_functions failed "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT39,39,_OMC_LIT39_data);
#define _OMC_LIT39 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT39)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT40,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT12}};
#define _OMC_LIT40 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT40)
#define _OMC_LIT41_data "- Inst.implicitFunctionTypeInstantiation failed "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT41,48,_OMC_LIT41_data);
#define _OMC_LIT41 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT41)
#define _OMC_LIT42_data "\nenv: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT42,6,_OMC_LIT42_data);
#define _OMC_LIT42 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT42)
#define _OMC_LIT43_data "\nelelement: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT43,12,_OMC_LIT43_data);
#define _OMC_LIT43 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT43)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT44,10,3) {&SCodeDump_SCodeDumpOptions_OPTIONS__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT44 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT44)
#define _OMC_LIT45_data "Function %s not found in scope %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT45,34,_OMC_LIT45_data);
#define _OMC_LIT45 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT45)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT46,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT45}};
#define _OMC_LIT46 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT46)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT47,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(165)),_OMC_LIT3,_OMC_LIT4,_OMC_LIT46}};
#define _OMC_LIT47 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT47)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT48,1,5) {&InstTypes_CallingScope_TYPE__CALL__desc,}};
#define _OMC_LIT48 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT48)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT49,1,11) {&DAE_Type_T__UNKNOWN__desc,}};
#define _OMC_LIT49 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT49)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT50,4,4) {&DAE_ComponentRef_CREF__IDENT__desc,_OMC_LIT12,_OMC_LIT49,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT50 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT50)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT51,2,0) {_OMC_LIT50,_OMC_LIT50}};
#define _OMC_LIT51 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT51)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT52,1,3) {&SCode_Visibility_PUBLIC__desc,}};
#define _OMC_LIT52 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT52)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT53,1,4) {&UnitAbsyn_InstStore_NOSTORE__desc,}};
#define _OMC_LIT53 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT53)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT54,1,7) {&DAE_InlineType_NO__INLINE__desc,}};
#define _OMC_LIT54 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT54)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT55,2,3) {&DAE_FunctionDefinition_FUNCTION__DEF__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT55 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT55)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT56,2,1) {_OMC_LIT55,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT56 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT56)
#define _OMC_LIT57_data "- Inst.implicitFunctionInstantiation2 failed "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT57,45,_OMC_LIT57_data);
#define _OMC_LIT57 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT57)
#define _OMC_LIT58_data "  Scope: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT58,9,_OMC_LIT58_data);
#define _OMC_LIT58 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT58)
#define _OMC_LIT59_data "- Inst.implicitFunctionInstantiation failed "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT59,44,_OMC_LIT59_data);
#define _OMC_LIT59 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT59)
#define _OMC_LIT60_data "- InstFunction.instantiateExternalObjectConstructor failed.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT60,60,_OMC_LIT60_data);
#define _OMC_LIT60 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT60)
#define _OMC_LIT61_data "- InstFunction.instantiateExternalObjectDestructor failed.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT61,59,_OMC_LIT61_data);
#define _OMC_LIT61 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT61)
#define _OMC_LIT62_data "Modified element %s not found in class %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT62,42,_OMC_LIT62_data);
#define _OMC_LIT62 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT62)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT63,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT62}};
#define _OMC_LIT63 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT63)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT64,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(214)),_OMC_LIT3,_OMC_LIT4,_OMC_LIT63}};
#define _OMC_LIT64 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT64)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT65,2,3) {&DAE_DAElist_DAE__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT65 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT65)
#define _OMC_LIT66_data "- InstFunction.instantiateExternalObject failed.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT66,49,_OMC_LIT66_data);
#define _OMC_LIT66 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT66)
#include "util/modelica.h"
#include "InstFunction_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstFunction_checkExtObjOutputWork(threadData_t *threadData, modelica_metatype _ty, modelica_metatype _inTpl, modelica_metatype *out_outTpl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstFunction_checkExtObjOutputWork,2,0) {(void*) boxptr_InstFunction_checkExtObjOutputWork,0}};
#define boxvar_InstFunction_checkExtObjOutputWork MMC_REFSTRUCTLIT(boxvar_lit_InstFunction_checkExtObjOutputWork)
PROTECTED_FUNCTION_STATIC void omc_InstFunction_checkExtObjOutput(threadData_t *threadData, modelica_metatype _inType, modelica_metatype _info);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstFunction_checkExtObjOutput,2,0) {(void*) boxptr_InstFunction_checkExtObjOutput,0}};
#define boxvar_InstFunction_checkExtObjOutput MMC_REFSTRUCTLIT(boxvar_lit_InstFunction_checkExtObjOutput)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_InstFunction_isElementImportantForFunction(threadData_t *threadData, modelica_metatype _elt);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstFunction_isElementImportantForFunction(threadData_t *threadData, modelica_metatype _elt);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstFunction_isElementImportantForFunction,2,0) {(void*) boxptr_InstFunction_isElementImportantForFunction,0}};
#define boxvar_InstFunction_isElementImportantForFunction MMC_REFSTRUCTLIT(boxvar_lit_InstFunction_isElementImportantForFunction)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstFunction_addExtVarToCall(threadData_t *threadData, modelica_metatype _cr, modelica_metatype _dir, modelica_metatype _dims, modelica_metatype __omcQ_24in_5Ffargs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstFunction_addExtVarToCall,2,0) {(void*) boxptr_InstFunction_addExtVarToCall,0}};
#define boxvar_InstFunction_addExtVarToCall MMC_REFSTRUCTLIT(boxvar_lit_InstFunction_addExtVarToCall)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstFunction_instExtMakeDefaultExternalCall(threadData_t *threadData, modelica_metatype _elements, modelica_metatype _funcType, modelica_string _lang, modelica_metatype _info, modelica_metatype *out_rettype);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstFunction_instExtMakeDefaultExternalCall,2,0) {(void*) boxptr_InstFunction_instExtMakeDefaultExternalCall,0}};
#define boxvar_InstFunction_instExtMakeDefaultExternalCall MMC_REFSTRUCTLIT(boxvar_lit_InstFunction_instExtMakeDefaultExternalCall)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstFunction_instExtDecl(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcache, modelica_metatype _env, modelica_metatype __omcQ_24in_5FiH, modelica_string _name, modelica_metatype _inScExtDecl, modelica_metatype _inElements, modelica_metatype _funcType, modelica_boolean _impl, modelica_metatype _pre, modelica_metatype _info, modelica_metatype *out_iH, modelica_metatype *out_daeextdecl);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstFunction_instExtDecl(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcache, modelica_metatype _env, modelica_metatype __omcQ_24in_5FiH, modelica_metatype _name, modelica_metatype _inScExtDecl, modelica_metatype _inElements, modelica_metatype _funcType, modelica_metatype _impl, modelica_metatype _pre, modelica_metatype _info, modelica_metatype *out_iH, modelica_metatype *out_daeextdecl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstFunction_instExtDecl,2,0) {(void*) boxptr_InstFunction_instExtDecl,0}};
#define boxvar_InstFunction_instExtDecl MMC_REFSTRUCTLIT(boxvar_lit_InstFunction_instExtDecl)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstFunction_instOverloadedFunctions(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _pre, modelica_metatype _inAbsynPathLst, modelica_metatype _inInfo, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outFns);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstFunction_instOverloadedFunctions,2,0) {(void*) boxptr_InstFunction_instOverloadedFunctions,0}};
#define boxvar_InstFunction_instOverloadedFunctions MMC_REFSTRUCTLIT(boxvar_lit_InstFunction_instOverloadedFunctions)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstFunction_instantiateDerivativeFuncs2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPaths, modelica_metatype _path, modelica_metatype _info);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstFunction_instantiateDerivativeFuncs2,2,0) {(void*) boxptr_InstFunction_instantiateDerivativeFuncs2,0}};
#define boxvar_InstFunction_instantiateDerivativeFuncs2 MMC_REFSTRUCTLIT(boxvar_lit_InstFunction_instantiateDerivativeFuncs2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstFunction_instantiateDerivativeFuncs(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _ih, modelica_metatype _funcs, modelica_metatype _path, modelica_metatype _info);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstFunction_instantiateDerivativeFuncs,2,0) {(void*) boxptr_InstFunction_instantiateDerivativeFuncs,0}};
#define boxvar_InstFunction_instantiateDerivativeFuncs MMC_REFSTRUCTLIT(boxvar_lit_InstFunction_instantiateDerivativeFuncs)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstFunction_implicitFunctionInstantiation2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inClass, modelica_metatype _inInstDims, modelica_boolean _instFunctionTypeOnly, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_funcs);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstFunction_implicitFunctionInstantiation2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inClass, modelica_metatype _inInstDims, modelica_metatype _instFunctionTypeOnly, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_funcs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstFunction_implicitFunctionInstantiation2,2,0) {(void*) boxptr_InstFunction_implicitFunctionInstantiation2,0}};
#define boxvar_InstFunction_implicitFunctionInstantiation2 MMC_REFSTRUCTLIT(boxvar_lit_InstFunction_implicitFunctionInstantiation2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstFunction_instantiateExternalObjectConstructor(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _env, modelica_metatype _inIH, modelica_metatype _cl, modelica_metatype *out_outIH, modelica_metatype *out_outType);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstFunction_instantiateExternalObjectConstructor,2,0) {(void*) boxptr_InstFunction_instantiateExternalObjectConstructor,0}};
#define boxvar_InstFunction_instantiateExternalObjectConstructor MMC_REFSTRUCTLIT(boxvar_lit_InstFunction_instantiateExternalObjectConstructor)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstFunction_instantiateExternalObjectDestructor(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _env, modelica_metatype _inIH, modelica_metatype _cl, modelica_metatype *out_outIH);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstFunction_instantiateExternalObjectDestructor,2,0) {(void*) boxptr_InstFunction_instantiateExternalObjectDestructor,0}};
#define boxvar_InstFunction_instantiateExternalObjectDestructor MMC_REFSTRUCTLIT(boxvar_lit_InstFunction_instantiateExternalObjectDestructor)
PROTECTED_FUNCTION_STATIC void omc_InstFunction_checkExternalObjectMod(threadData_t *threadData, modelica_metatype _inMod, modelica_string _inClassName);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstFunction_checkExternalObjectMod,2,0) {(void*) boxptr_InstFunction_checkExternalObjectMod,0}};
#define boxvar_InstFunction_checkExternalObjectMod MMC_REFSTRUCTLIT(boxvar_lit_InstFunction_checkExternalObjectMod)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstFunction_checkExtObjOutputWork(threadData_t *threadData, modelica_metatype _ty, modelica_metatype _inTpl, modelica_metatype *out_outTpl)
{
modelica_metatype _oty = NULL;
modelica_metatype _outTpl = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_oty = _ty;
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _ty;
tmp3_2 = _inTpl;
{
modelica_metatype _path1 = NULL;
modelica_metatype _path2 = NULL;
modelica_metatype _info = NULL;
modelica_string _str1 = NULL;
modelica_string _str2 = NULL;
modelica_boolean _b;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
modelica_boolean tmp6;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmp5 = mmc_unbox_integer(tmpMeta[3]);
if (1 != tmp5) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,9,3) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],17,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
_path2 = tmpMeta[1];
_info = tmpMeta[2];
_path1 = tmpMeta[5];
_path1 = omc_AbsynUtil_joinPaths(threadData, _path1, _OMC_LIT1);
_str1 = omc_AbsynUtil_pathStringNoQual(threadData, _path2, _OMC_LIT2, 0, 0);
_str2 = omc_AbsynUtil_pathStringNoQual(threadData, _path1, _OMC_LIT2, 0, 0);
_b = omc_AbsynUtil_pathEqual(threadData, _path1, _path2);
tmpMeta[1] = mmc_mk_cons(_str1, mmc_mk_cons(_str2, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_assertionOrAddSourceMessage(threadData, _b, _OMC_LIT7, tmpMeta[1], _info);
tmp6 = (modelica_boolean)_b;
if(tmp6)
{
tmpMeta[2] = _inTpl;
}
else
{
tmpMeta[1] = mmc_mk_box3(0, _path2, _info, mmc_mk_boolean(0));
tmpMeta[2] = tmpMeta[1];
}
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _inTpl;
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
_outTpl = tmpMeta[0];
_return: OMC_LABEL_UNUSED
if (out_outTpl) { *out_outTpl = _outTpl; }
return _oty;
}
PROTECTED_FUNCTION_STATIC void omc_InstFunction_checkExtObjOutput(threadData_t *threadData, modelica_metatype _inType, modelica_metatype _info)
{
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inType;
{
modelica_metatype _path = NULL;
modelica_metatype _ty = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,11,4) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_ty = tmpMeta[0];
_path = tmpMeta[1];
tmpMeta[2] = mmc_mk_box3(0, _path, _info, mmc_mk_boolean(1));
omc_Types_traverseType(threadData, _ty, tmpMeta[2], boxvar_InstFunction_checkExtObjOutputWork, &tmpMeta[0]);
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
if (1 != tmp5) goto goto_1;
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
PROTECTED_FUNCTION_STATIC modelica_boolean omc_InstFunction_isElementImportantForFunction(threadData_t *threadData, modelica_metatype _elt)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _elt;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,0) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,0) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],2,0) == 0) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstFunction_isElementImportantForFunction(threadData_t *threadData, modelica_metatype _elt)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_InstFunction_isElementImportantForFunction(threadData, _elt);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_metatype omc_InstFunction_addRecordConstructorFunction(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inType, modelica_metatype _inInfo)
{
modelica_metatype _outCache = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inCache;
tmp3_2 = _inType;
{
modelica_metatype _vars = NULL;
modelica_metatype _inputs = NULL;
modelica_metatype _locals = NULL;
modelica_metatype _fixedTy = NULL;
modelica_metatype _funcTy = NULL;
modelica_metatype _eqCo = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _path = NULL;
modelica_metatype _func = NULL;
modelica_metatype _fargs = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,9,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_path = tmpMeta[2];
_cache = tmp3_1;
_path = omc_AbsynUtil_makeFullyQualified(threadData, _path);
tmpMeta[0] = omc_InstFunction_getRecordConstructorFunction(threadData, _cache, _inEnv, _path, NULL);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,9,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_path = tmpMeta[2];
_vars = tmpMeta[3];
_eqCo = tmpMeta[4];
_cache = tmp3_1;
_path = omc_AbsynUtil_makeFullyQualified(threadData, _path);
_vars = omc_Types_filterRecordComponents(threadData, _vars, _inInfo);
_inputs = omc_List_extractOnTrue(threadData, _vars, boxvar_Types_isModifiableTypesVar ,&_locals);
_inputs = omc_List_map(threadData, _inputs, boxvar_Types_setVarDefaultInput);
_locals = omc_List_map(threadData, _locals, boxvar_Types_setVarProtected);
_vars = listAppend(_inputs, _locals);
tmpMeta[1] = mmc_mk_box2(6, &ClassInf_State_RECORD__desc, _path);
tmpMeta[2] = mmc_mk_box4(12, &DAE_Type_T__COMPLEX__desc, tmpMeta[1], _vars, _eqCo);
_fixedTy = tmpMeta[2];
_fargs = omc_Types_makeFargsList(threadData, _inputs);
tmpMeta[1] = mmc_mk_box5(14, &DAE_Type_T__FUNCTION__desc, _fargs, _fixedTy, _OMC_LIT11, _path);
_funcTy = tmpMeta[1];
tmpMeta[1] = mmc_mk_box4(4, &DAE_Function_RECORD__CONSTRUCTOR__desc, _path, _funcTy, _OMC_LIT16);
_func = tmpMeta[1];
tmpMeta[1] = mmc_mk_cons(_func, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_InstUtil_addFunctionsToDAE(threadData, _cache, tmpMeta[1], _OMC_LIT17);
goto tmp2_done;
}
case 2: {
tmpMeta[0] = _inCache;
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
_outCache = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outCache;
}
DLLExport
modelica_metatype omc_InstFunction_getRecordConstructorFunction(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inPath, modelica_metatype *out_outFunc)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outFunc = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _path = NULL;
modelica_metatype _recordCl = NULL;
modelica_metatype _recordEnv = NULL;
modelica_metatype _func = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _recType = NULL;
modelica_metatype _fixedTy = NULL;
modelica_metatype _funcTy = NULL;
modelica_metatype _vars = NULL;
modelica_metatype _inputs = NULL;
modelica_metatype _locals = NULL;
modelica_metatype _fargs = NULL;
modelica_metatype _eqCo = NULL;
modelica_string _name = NULL;
modelica_string _newName = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_path = omc_AbsynUtil_makeFullyQualified(threadData, _inPath);
_func = omc_FCore_getCachedInstFunc(threadData, _inCache, _path);
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _func;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
omc_Lookup_lookupClass(threadData, _inCache, _inEnv, _inPath, mmc_mk_none() ,&_recordCl ,&_recordEnv);
tmp6 = omc_SCodeUtil_isRecord(threadData, _recordCl);
if (1 != tmp6) goto goto_2;
_name = omc_SCodeUtil_getElementName(threadData, _recordCl);
_newName = omc_FGraph_getInstanceOriginalName(threadData, _recordEnv, _name);
_recordCl = omc_SCodeUtil_setClassName(threadData, _newName, _recordCl);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_Inst_instClass(threadData, _inCache, _recordEnv, tmpMeta[2], omc_UnitAbsynBuilder_emptyInstStore(threadData), _OMC_LIT18, _OMC_LIT19, _recordCl, tmpMeta[3], 1, _OMC_LIT20, _OMC_LIT21, _OMC_LIT24 ,NULL ,NULL ,NULL ,NULL ,NULL ,&_recType ,NULL ,NULL ,NULL);
tmpMeta[2] = _recType;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],9,3) == 0) goto goto_2;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],3,1) == 0) goto goto_2;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
_path = tmpMeta[4];
_vars = tmpMeta[5];
_eqCo = tmpMeta[6];
_vars = omc_Types_filterRecordComponents(threadData, _vars, omc_SCodeUtil_elementInfo(threadData, _recordCl));
_inputs = omc_List_extractOnTrue(threadData, _vars, boxvar_Types_isModifiableTypesVar ,&_locals);
_inputs = omc_List_map(threadData, _inputs, boxvar_Types_setVarDefaultInput);
_locals = omc_List_map(threadData, _locals, boxvar_Types_setVarProtected);
_vars = listAppend(_inputs, _locals);
_path = omc_AbsynUtil_makeFullyQualified(threadData, _path);
tmpMeta[2] = mmc_mk_box2(6, &ClassInf_State_RECORD__desc, _path);
tmpMeta[3] = mmc_mk_box4(12, &DAE_Type_T__COMPLEX__desc, tmpMeta[2], _vars, _eqCo);
_fixedTy = tmpMeta[3];
_fargs = omc_Types_makeFargsList(threadData, _inputs);
tmpMeta[2] = mmc_mk_box5(14, &DAE_Type_T__FUNCTION__desc, _fargs, _fixedTy, _OMC_LIT11, _path);
_funcTy = tmpMeta[2];
tmpMeta[2] = mmc_mk_box4(4, &DAE_Function_RECORD__CONSTRUCTOR__desc, _path, _funcTy, _OMC_LIT16);
_func = tmpMeta[2];
tmpMeta[2] = mmc_mk_cons(_func, MMC_REFSTRUCTLIT(mmc_nil));
_cache = omc_InstUtil_addFunctionsToDAE(threadData, _cache, tmpMeta[2], _OMC_LIT17);
_path = omc_AbsynUtil_pathSetLastIdent(threadData, _path, omc_AbsynUtil_makeIdentPathFromString(threadData, _name));
tmpMeta[2] = mmc_mk_box2(6, &ClassInf_State_RECORD__desc, _path);
tmpMeta[3] = mmc_mk_box4(12, &DAE_Type_T__COMPLEX__desc, tmpMeta[2], _vars, _eqCo);
_fixedTy = tmpMeta[3];
_fargs = omc_Types_makeFargsList(threadData, _inputs);
tmpMeta[2] = mmc_mk_box5(14, &DAE_Type_T__FUNCTION__desc, _fargs, _fixedTy, _OMC_LIT11, _path);
_funcTy = tmpMeta[2];
tmpMeta[2] = mmc_mk_box4(4, &DAE_Function_RECORD__CONSTRUCTOR__desc, _path, _funcTy, _OMC_LIT16);
_func = tmpMeta[2];
tmpMeta[2] = mmc_mk_cons(_func, MMC_REFSTRUCTLIT(mmc_nil));
_cache = omc_InstUtil_addFunctionsToDAE(threadData, _cache, tmpMeta[2], _OMC_LIT17);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _func;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp7;
tmp7 = omc_Flags_isSet(threadData, _OMC_LIT28);
if (1 != tmp7) goto goto_2;
tmpMeta[2] = stringAppend(_OMC_LIT29,omc_AbsynUtil_pathString(threadData, _inPath, _OMC_LIT2, 1, 0));
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
if (++tmp4 < 3) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outCache = tmpMeta[0+0];
_outFunc = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outFunc) { *out_outFunc = _outFunc; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstFunction_addExtVarToCall(threadData_t *threadData, modelica_metatype _cr, modelica_metatype _dir, modelica_metatype _dims, modelica_metatype __omcQ_24in_5Ffargs)
{
modelica_metatype _fargs = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_fargs = __omcQ_24in_5Ffargs;
tmpMeta[1] = mmc_mk_box4(3, &DAE_ExtArg_EXTARG__desc, _cr, _dir, omc_ComponentReference_crefTypeFull(threadData, _cr));
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], _fargs);
_fargs = tmpMeta[0];
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = listLength(_dims);
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _dim;
for(_dim = ((modelica_integer) 1); in_range_integer(_dim, tmp1, tmp3); _dim += tmp2)
{
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_dim));
tmpMeta[2] = mmc_mk_box4(5, &DAE_ExtArg_EXTARGSIZE__desc, _cr, omc_ComponentReference_crefTypeFull(threadData, _cr), tmpMeta[1]);
tmpMeta[0] = mmc_mk_cons(tmpMeta[2], _fargs);
_fargs = tmpMeta[0];
}
}
_return: OMC_LABEL_UNUSED
return _fargs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstFunction_instExtMakeDefaultExternalCall(threadData_t *threadData, modelica_metatype _elements, modelica_metatype _funcType, modelica_string _lang, modelica_metatype _info, modelica_metatype *out_rettype)
{
modelica_metatype _fargs = NULL;
modelica_metatype _rettype = NULL;
modelica_metatype _ty = NULL;
modelica_boolean _singleOutput;
modelica_metatype _cr = NULL;
modelica_metatype _e = NULL;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_fargs = tmpMeta[0];
if((stringEqual(_lang, _OMC_LIT31)))
{
_rettype = _OMC_LIT30;
goto _return;
}
{
modelica_metatype tmp4_1;
tmp4_1 = _funcType;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],6,2) == 0) goto tmp3_end;
if((!stringEqual(_lang, _OMC_LIT31)))
{
tmpMeta[2] = mmc_mk_cons(_lang, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT35, tmpMeta[2], _info);
}
tmpMeta[0+0] = _OMC_LIT30;
tmp1_c1 = 0;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],14,2) == 0) goto tmp3_end;
tmpMeta[0+0] = _OMC_LIT30;
tmp1_c1 = 0;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],7,0) == 0) goto tmp3_end;
tmpMeta[0+0] = _OMC_LIT30;
tmp1_c1 = 0;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_ty = tmpMeta[2];
tmpMeta[2] = mmc_mk_box4(3, &DAE_ExtArg_EXTARG__desc, omc_DAEUtil_varCref(threadData, omc_List_find(threadData, _elements, boxvar_DAEUtil_isOutputVar)), _OMC_LIT36, _ty);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 4: {
tmpMeta[2] = stringAppend(_OMC_LIT37,omc_Types_unparseType(threadData, _funcType));
omc_Error_addInternalError(threadData, tmpMeta[2], _info);
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
_rettype = tmpMeta[0+0];
_singleOutput = tmp1_c1;
{
modelica_metatype _elt;
for (tmpMeta[0] = _elements; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_elt = MMC_CAR(tmpMeta[0]);
{
modelica_metatype tmp8_1;
tmp8_1 = _elt;
{
volatile mmc_switch_type tmp8;
int tmp9;
tmp8 = 0;
for (; tmp8 < 4; tmp8++) {
switch (MMC_SWITCH_CAST(tmp8)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,0,13) == 0) goto tmp7_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,0) == 0) goto tmp7_end;
if (!(!_singleOutput)) goto tmp7_end;
tmpMeta[1] = omc_InstFunction_addExtVarToCall(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 2))), _OMC_LIT36, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 9))), _fargs);
goto tmp7_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,0,13) == 0) goto tmp7_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,0) == 0) goto tmp7_end;
tmpMeta[1] = omc_InstFunction_addExtVarToCall(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 2))), _OMC_LIT38, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 9))), _fargs);
goto tmp7_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,0,13) == 0) goto tmp7_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,0) == 0) goto tmp7_end;
tmpMeta[1] = omc_InstFunction_addExtVarToCall(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 2))), _OMC_LIT36, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 9))), _fargs);
goto tmp7_done;
}
case 3: {
tmpMeta[1] = _fargs;
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
_fargs = tmpMeta[1];
}
}
_fargs = listReverse(_fargs);
_return: OMC_LABEL_UNUSED
if (out_rettype) { *out_rettype = _rettype; }
return _fargs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstFunction_instExtDecl(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcache, modelica_metatype _env, modelica_metatype __omcQ_24in_5FiH, modelica_string _name, modelica_metatype _inScExtDecl, modelica_metatype _inElements, modelica_metatype _funcType, modelica_boolean _impl, modelica_metatype _pre, modelica_metatype _info, modelica_metatype *out_iH, modelica_metatype *out_daeextdecl)
{
modelica_metatype _cache = NULL;
modelica_metatype _iH = NULL;
modelica_metatype _daeextdecl = NULL;
modelica_string _fname = NULL;
modelica_string _lang = NULL;
modelica_metatype _fargs = NULL;
modelica_metatype _rettype = NULL;
modelica_metatype _ann = NULL;
modelica_metatype _extdecl = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cache = __omcQ_24in_5Fcache;
_iH = __omcQ_24in_5FiH;
_extdecl = _inScExtDecl;
_ann = omc_InstUtil_instExtGetAnnotation(threadData, _extdecl);
_lang = omc_InstUtil_instExtGetLang(threadData, _extdecl);
_fname = omc_InstUtil_instExtGetFname(threadData, _extdecl, _name);
if((!omc_InstUtil_isExtExplicitCall(threadData, _extdecl)))
{
_fargs = omc_InstFunction_instExtMakeDefaultExternalCall(threadData, _inElements, _funcType, _lang, _info ,&_rettype);
}
else
{
_cache = omc_InstUtil_instExtGetFargs(threadData, _cache, _env, _extdecl, _impl, _pre, _info ,&_fargs);
_cache = omc_InstUtil_instExtGetRettype(threadData, _cache, _env, _extdecl, _impl, _pre, _info ,&_rettype);
}
tmpMeta[0] = mmc_mk_box6(3, &DAE_ExternalDecl_EXTERNALDECL__desc, _fname, _fargs, _rettype, _lang, _ann);
_daeextdecl = tmpMeta[0];
_return: OMC_LABEL_UNUSED
if (out_iH) { *out_iH = _iH; }
if (out_daeextdecl) { *out_daeextdecl = _daeextdecl; }
return _cache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstFunction_instExtDecl(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcache, modelica_metatype _env, modelica_metatype __omcQ_24in_5FiH, modelica_metatype _name, modelica_metatype _inScExtDecl, modelica_metatype _inElements, modelica_metatype _funcType, modelica_metatype _impl, modelica_metatype _pre, modelica_metatype _info, modelica_metatype *out_iH, modelica_metatype *out_daeextdecl)
{
modelica_integer tmp1;
modelica_metatype _cache = NULL;
tmp1 = mmc_unbox_integer(_impl);
_cache = omc_InstFunction_instExtDecl(threadData, __omcQ_24in_5Fcache, _env, __omcQ_24in_5FiH, _name, _inScExtDecl, _inElements, _funcType, tmp1, _pre, _info, out_iH, out_daeextdecl);
return _cache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstFunction_instOverloadedFunctions(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _pre, modelica_metatype _inAbsynPathLst, modelica_metatype _inInfo, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outFns)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outIH = NULL;
modelica_metatype _outFns = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inIH;
tmp4_4 = _inAbsynPathLst;
{
modelica_metatype _env = NULL;
modelica_metatype _cenv = NULL;
modelica_metatype _c = NULL;
modelica_metatype _fn = NULL;
modelica_metatype _fns = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _ih = NULL;
modelica_metatype _resfns1 = NULL;
modelica_metatype _resfns2 = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_4)) goto tmp3_end;
_cache = tmp4_1;
_ih = tmp4_3;
tmp4 += 2;
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _inEnv;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = tmpMeta[4];
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
if (listEmpty(tmp4_4)) goto tmp3_end;
tmpMeta[4] = MMC_CAR(tmp4_4);
tmpMeta[5] = MMC_CDR(tmp4_4);
_fn = tmpMeta[4];
_fns = tmpMeta[5];
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
tmpMeta[7] = omc_Lookup_lookupClass(threadData, _cache, _env, _fn, mmc_mk_some(_inInfo), &tmpMeta[4], &tmpMeta[6]);
_cache = tmpMeta[7];
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],2,8) == 0) goto goto_2;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 6));
_c = tmpMeta[4];
_rest = tmpMeta[5];
_cenv = tmpMeta[6];
tmp6 = omc_SCodeUtil_isFunctionRestriction(threadData, _rest);
if (1 != tmp6) goto goto_2;
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_InstFunction_implicitFunctionInstantiation2(threadData, _inCache, _cenv, _inIH, _OMC_LIT18, _pre, _c, tmpMeta[4], 0 ,&_env ,&_ih ,&_resfns1);
_cache = omc_InstFunction_instOverloadedFunctions(threadData, _cache, _env, _ih, _pre, _fns, _inInfo ,&_env ,&_ih ,&_resfns2);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = listAppend(_resfns1, _resfns2);
goto tmp3_done;
}
case 2: {
modelica_boolean tmp7;
if (listEmpty(tmp4_4)) goto tmp3_end;
tmpMeta[4] = MMC_CAR(tmp4_4);
tmpMeta[5] = MMC_CDR(tmp4_4);
_fn = tmpMeta[4];
tmp7 = omc_Flags_isSet(threadData, _OMC_LIT28);
if (1 != tmp7) goto goto_2;
tmpMeta[4] = stringAppend(_OMC_LIT39,omc_AbsynUtil_pathString(threadData, _fn, _OMC_LIT2, 1, 0));
omc_Debug_traceln(threadData, tmpMeta[4]);
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
_outCache = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_outIH = tmpMeta[0+2];
_outFns = tmpMeta[0+3];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outIH) { *out_outIH = _outIH; }
if (out_outFns) { *out_outFns = _outFns; }
return _outCache;
}
DLLExport
modelica_metatype omc_InstFunction_implicitFunctionTypeInstantiation(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inClass, modelica_metatype *out_outEnv, modelica_metatype *out_outIH)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outIH = NULL;
modelica_metatype tmpMeta[13] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inIH;
tmp4_4 = _inClass;
{
modelica_metatype _stripped_class = NULL;
modelica_metatype _env_1 = NULL;
modelica_metatype _env = NULL;
modelica_string _id = NULL;
modelica_metatype _p = NULL;
modelica_metatype _e = NULL;
modelica_metatype _r = NULL;
modelica_metatype _extDecl = NULL;
modelica_metatype _elts = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _ih = NULL;
modelica_metatype _info = NULL;
modelica_metatype _funs = NULL;
modelica_metatype _cn = NULL;
modelica_metatype _fpath = NULL;
modelica_metatype _mod1 = NULL;
modelica_metatype _mod2 = NULL;
modelica_metatype _cenv = NULL;
modelica_metatype _c = NULL;
modelica_metatype _ty1 = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _prefixes = NULL;
modelica_metatype _cmt = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,2,8) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],9,1) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,1) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],0,8) == 0) goto tmp3_end;
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_InstFunction_implicitFunctionInstantiation2(threadData, _cache, _env, _ih, _OMC_LIT18, _OMC_LIT19, _inClass, tmpMeta[3], 1 ,&_env_1 ,&_ih ,&_funs);
_cache = omc_FCore_addDaeExtFunction(threadData, _cache, _funs);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env_1;
tmpMeta[0+2] = _ih;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,2,8) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 5));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 6));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],0,8) == 0) goto tmp3_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 2));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 9));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 8));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 9));
_id = tmpMeta[3];
_prefixes = tmpMeta[4];
_e = tmpMeta[5];
_p = tmpMeta[6];
_r = tmpMeta[7];
_elts = tmpMeta[9];
_extDecl = tmpMeta[10];
_cmt = tmpMeta[11];
_info = tmpMeta[12];
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
tmp4 += 2;
_elts = omc_List_select(threadData, _elts, boxvar_InstFunction_isElementImportantForFunction);
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[5] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[6] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[7] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[8] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[9] = mmc_mk_box9(3, &SCode_ClassDef_PARTS__desc, _elts, tmpMeta[3], tmpMeta[4], tmpMeta[5], tmpMeta[6], tmpMeta[7], tmpMeta[8], _extDecl);
tmpMeta[10] = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _id, _prefixes, _e, _p, _r, tmpMeta[9], _cmt, _info);
_stripped_class = tmpMeta[10];
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_InstFunction_implicitFunctionInstantiation2(threadData, _cache, _env, _ih, _OMC_LIT18, _OMC_LIT19, _stripped_class, tmpMeta[3], 1 ,&_env_1 ,&_ih ,NULL);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env_1;
tmpMeta[0+2] = _ih;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,2,8) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],2,3) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],0,2) == 0) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 9));
_id = tmpMeta[3];
_cn = tmpMeta[6];
_mod1 = tmpMeta[7];
_info = tmpMeta[8];
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
tmp4 += 1;
tmpMeta[5] = omc_Lookup_lookupClass(threadData, _cache, _env, _cn, mmc_mk_none(), &tmpMeta[3], &tmpMeta[4]);
_cache = tmpMeta[5];
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],2,8) == 0) goto goto_2;
_c = tmpMeta[3];
_cenv = tmpMeta[4];
tmpMeta[3] = mmc_mk_box2(5, &Mod_ModScope_DERIVED__desc, _cn);
_cache = omc_Mod_elabMod(threadData, _cache, _env, _ih, _OMC_LIT19, _mod1, 0, tmpMeta[3], _info ,&_mod2);
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_Inst_instClass(threadData, _cache, _cenv, _ih, omc_UnitAbsynBuilder_emptyInstStore(threadData), _mod2, _OMC_LIT19, _c, tmpMeta[3], 1, _OMC_LIT20, _OMC_LIT21, _OMC_LIT24 ,NULL ,&_ih ,NULL ,NULL ,NULL ,&_ty ,NULL ,NULL ,NULL);
_env_1 = _env;
_cache = omc_Inst_makeFullyQualifiedIdent(threadData, _cache, _env_1, _id, _OMC_LIT40 ,&_fpath);
_ty1 = omc_InstUtil_setFullyQualifiedTypename(threadData, _ty, _fpath);
_env_1 = omc_FGraph_mkTypeNode(threadData, _env_1, _id, _ty1);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env_1;
tmpMeta[0+2] = _ih;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,2,8) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],4,1) == 0) goto tmp3_end;
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_InstFunction_implicitFunctionInstantiation2(threadData, _cache, _env, _ih, _OMC_LIT18, _OMC_LIT19, _inClass, tmpMeta[3], 1 ,&_env ,&_ih ,NULL);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = _ih;
goto tmp3_done;
}
case 4: {
modelica_boolean tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,2,8) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 2));
_id = tmpMeta[3];
tmp6 = omc_Flags_isSet(threadData, _OMC_LIT28);
if (1 != tmp6) goto goto_2;
tmpMeta[3] = stringAppend(_OMC_LIT41,_id);
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT42);
tmpMeta[5] = stringAppend(tmpMeta[4],omc_FGraph_getGraphNameStr(threadData, _inEnv));
tmpMeta[6] = stringAppend(tmpMeta[5],_OMC_LIT43);
tmpMeta[7] = stringAppend(tmpMeta[6],omc_SCodeDump_unparseElementStr(threadData, _inClass, _OMC_LIT44));
omc_Debug_traceln(threadData, tmpMeta[7]);
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
_outCache = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_outIH = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outIH) { *out_outIH = _outIH; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstFunction_instantiateDerivativeFuncs2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPaths, modelica_metatype _path, modelica_metatype _info)
{
modelica_metatype _outCache = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;volatile modelica_metatype tmp3_3;volatile modelica_metatype tmp3_4;
tmp3_1 = _inCache;
tmp3_2 = _inEnv;
tmp3_3 = _inIH;
tmp3_4 = _inPaths;
{
modelica_metatype _funcs = NULL;
modelica_metatype _p = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _cenv = NULL;
modelica_metatype _env = NULL;
modelica_metatype _ih = NULL;
modelica_metatype _cdef = NULL;
modelica_metatype _paths = NULL;
modelica_string _fun = NULL;
modelica_string _scope = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_4)) goto tmp2_end;
_cache = tmp3_1;
tmp3 += 1;
tmpMeta[0] = _cache;
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_4)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_4);
tmpMeta[2] = MMC_CDR(tmp3_4);
_p = tmpMeta[1];
_paths = tmpMeta[2];
_cache = tmp3_1;
_env = tmp3_2;
_ih = tmp3_3;
_cache = omc_Lookup_lookupClass(threadData, _cache, _env, _p, mmc_mk_some(_info) ,&_cdef ,&_cenv);
_cache = omc_Inst_makeFullyQualified(threadData, _cache, _cenv, _p ,&_p);
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
omc_FCore_checkCachedInstFuncGuard(threadData, _cache, _p);
goto tmp6_done;
}
case 1: {
_cache = omc_FCore_addCachedInstFuncGuard(threadData, _cache, _p);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_InstFunction_implicitFunctionInstantiation2(threadData, _cache, _cenv, _ih, _OMC_LIT18, _OMC_LIT19, _cdef, tmpMeta[1], 0 ,NULL ,&_ih ,&_funcs);
_funcs = omc_InstUtil_addNameToDerivativeMapping(threadData, _funcs, _path);
_cache = omc_FCore_addDaeFunction(threadData, _cache, _funcs);
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
tmpMeta[0] = omc_InstFunction_instantiateDerivativeFuncs2(threadData, _cache, _env, _ih, _paths, _path, _info);
goto tmp2_done;
}
case 2: {
tmpMeta[1] = _inPaths;
if (listEmpty(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
_p = tmpMeta[2];
_fun = omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT2, 1, 0);
_scope = omc_FGraph_printGraphPathStr(threadData, _inEnv);
tmpMeta[1] = mmc_mk_cons(_fun, mmc_mk_cons(_scope, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT47, tmpMeta[1], _info);
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
if (++tmp3 < 3) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outCache = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstFunction_instantiateDerivativeFuncs(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _ih, modelica_metatype _funcs, modelica_metatype _path, modelica_metatype _info)
{
modelica_metatype _outCache = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCache = omc_InstFunction_instantiateDerivativeFuncs2(threadData, _cache, _env, _ih, omc_DAEUtil_getDerivativePaths(threadData, _funcs), _path, _info);
_return: OMC_LABEL_UNUSED
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstFunction_implicitFunctionInstantiation2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inClass, modelica_metatype _inInstDims, modelica_boolean _instFunctionTypeOnly, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_funcs)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outIH = NULL;
modelica_metatype _funcs = NULL;
modelica_metatype tmpMeta[16] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;volatile modelica_metatype tmp4_5;volatile modelica_metatype tmp4_6;volatile modelica_metatype tmp4_7;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inIH;
tmp4_4 = _inMod;
tmp4_5 = _inPrefix;
tmp4_6 = _inClass;
tmp4_7 = _inInstDims;
{
modelica_metatype _ty = NULL;
modelica_metatype _ty1 = NULL;
modelica_metatype _env_1 = NULL;
modelica_metatype _env = NULL;
modelica_metatype _tempenv = NULL;
modelica_metatype _cenv = NULL;
modelica_metatype _fpath = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _pre = NULL;
modelica_metatype _c = NULL;
modelica_string _n = NULL;
modelica_metatype _inst_dims = NULL;
modelica_metatype _vis = NULL;
modelica_metatype _partialPrefix = NULL;
modelica_metatype _encapsulatedPrefix = NULL;
modelica_metatype _scExtdecl = NULL;
modelica_metatype _extdecl = NULL;
modelica_metatype _restr = NULL;
modelica_metatype _parts = NULL;
modelica_metatype _funcnames = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _ih = NULL;
modelica_metatype _source = NULL;
modelica_metatype _daeElts = NULL;
modelica_metatype _resfns = NULL;
modelica_metatype _derFuncs = NULL;
modelica_metatype _info = NULL;
modelica_metatype _inlineType = NULL;
modelica_metatype _cd = NULL;
modelica_boolean _partialPrefixBool;
modelica_boolean _isImpure;
modelica_metatype _cmt = NULL;
modelica_metatype _funcRest = NULL;
modelica_metatype _cs = NULL;
modelica_metatype _visibility = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,2,8) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 5));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],9,1) == 0) goto tmp3_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 2));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 7));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 9));
_n = tmpMeta[4];
_visibility = tmpMeta[6];
_partialPrefix = tmpMeta[7];
_funcRest = tmpMeta[9];
_cd = tmpMeta[10];
_info = tmpMeta[11];
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_mod = tmp4_4;
_pre = tmp4_5;
_inst_dims = tmp4_7;
tmp6 = omc_SCodeUtil_isExternalFunctionRestriction(threadData, _funcRest);
if (0 != tmp6) goto goto_2;
_isImpure = omc_SCodeUtil_isImpureFunctionRestriction(threadData, _funcRest);
_c = (omc_Config_acceptMetaModelicaGrammar(threadData)?_inClass:omc_SCodeUtil_setClassPartialPrefix(threadData, _OMC_LIT17, _inClass));
_cs = (_instFunctionTypeOnly?_OMC_LIT48:_OMC_LIT20);
tmpMeta[9] = omc_Inst_instClass(threadData, _cache, _env, _ih, omc_UnitAbsynBuilder_emptyInstStore(threadData), _mod, _pre, _c, _inst_dims, 1, _cs, _OMC_LIT21, _OMC_LIT24, &tmpMeta[4], &tmpMeta[5], NULL, &tmpMeta[6], NULL, &tmpMeta[8], NULL, NULL, NULL);
_cache = tmpMeta[9];
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
_cenv = tmpMeta[4];
_ih = tmpMeta[5];
_daeElts = tmpMeta[7];
_ty = tmpMeta[8];
omc_List_map2__0(threadData, _daeElts, boxvar_InstUtil_checkFunctionElement, mmc_mk_boolean(0), _info);
_env_1 = _env;
_cache = omc_Inst_makeFullyQualifiedIdent(threadData, _cache, _env_1, _n, _OMC_LIT40 ,&_fpath);
_cmt = omc_InstUtil_extractComment(threadData, _daeElts);
_derFuncs = omc_InstUtil_getDeriveAnnotation(threadData, _cd, _cmt, _fpath, _cache, _cenv, _ih, _pre, _info);
_cache = omc_InstFunction_instantiateDerivativeFuncs(threadData, _cache, _env, _ih, _derFuncs, _fpath, _info);
_ty1 = omc_InstUtil_setFullyQualifiedTypename(threadData, _ty, _fpath);
omc_InstFunction_checkExtObjOutput(threadData, _ty1, _info);
_env_1 = omc_FGraph_mkTypeNode(threadData, _env_1, _n, _ty1);
_source = omc_ElementSource_createElementSource(threadData, _info, omc_FGraph_getScopePath(threadData, _env), _pre, _OMC_LIT51);
_inlineType = omc_InstUtil_commentIsInlineFunc(threadData, _cmt);
_partialPrefixBool = omc_SCodeUtil_partialBool(threadData, _partialPrefix);
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[5] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[6] = MMC_REFSTRUCTLIT(mmc_nil);
_daeElts = omc_InstUtil_optimizeFunctionCheckForLocals(threadData, _fpath, _daeElts, mmc_mk_none(), tmpMeta[4], tmpMeta[5], tmpMeta[6]);
omc_InstUtil_checkFunctionDefUse(threadData, _daeElts, _info);
{
modelica_metatype __omcQ_24tmpVar3;
modelica_metatype* tmp7;
modelica_metatype __omcQ_24tmpVar2;
int tmp8;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _daeElts;
tmpMeta[7] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta[7];
tmp7 = &__omcQ_24tmpVar3;
while(1) {
tmp8 = 1;
while (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
if ((!omc_DAEUtil_isComment(threadData, _e))) {
tmp8--;
break;
}
}
if (tmp8 == 0) {
__omcQ_24tmpVar2 = _e;
*tmp7 = mmc_mk_cons(__omcQ_24tmpVar2,0);
tmp7 = &MMC_CDR(*tmp7);
} else if (tmp8 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp7 = mmc_mk_nil();
tmpMeta[6] = __omcQ_24tmpVar3;
}
tmpMeta[8] = mmc_mk_box2(3, &DAE_FunctionDefinition_FUNCTION__DEF__desc, tmpMeta[6]);
tmpMeta[5] = mmc_mk_cons(tmpMeta[8], _derFuncs);
tmpMeta[9] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[10] = mmc_mk_box11(3, &DAE_Function_FUNCTION__desc, _fpath, tmpMeta[5], _ty1, _visibility, mmc_mk_boolean(_partialPrefixBool), mmc_mk_boolean(_isImpure), _inlineType, tmpMeta[9], _source, mmc_mk_some(_cmt));
tmpMeta[4] = mmc_mk_cons(tmpMeta[10], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env_1;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = tmpMeta[4];
goto tmp3_done;
}
case 1: {
modelica_integer tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,2,8) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 4));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 5));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[9],9,1) == 0) goto tmp3_end;
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[9]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[10],1,1) == 0) goto tmp3_end;
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[10]), 2));
tmp9 = mmc_unbox_integer(tmpMeta[11]);
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[12],0,8) == 0) goto tmp3_end;
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[12]), 9));
if (optionNone(tmpMeta[13])) goto tmp3_end;
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[13]), 1));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 9));
_c = tmp4_6;
_n = tmpMeta[4];
_visibility = tmpMeta[6];
_encapsulatedPrefix = tmpMeta[7];
_partialPrefix = tmpMeta[8];
_restr = tmpMeta[9];
_isImpure = tmp9;
_cd = tmpMeta[12];
_parts = tmpMeta[12];
_scExtdecl = tmpMeta[14];
_info = tmpMeta[15];
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_mod = tmp4_4;
_pre = tmp4_5;
_inst_dims = tmp4_7;
tmp4 += 1;
tmpMeta[9] = omc_Inst_instClass(threadData, _cache, _env, _ih, omc_UnitAbsynBuilder_emptyInstStore(threadData), _mod, _pre, _c, _inst_dims, 1, _OMC_LIT20, _OMC_LIT21, _OMC_LIT24, &tmpMeta[4], &tmpMeta[5], NULL, &tmpMeta[6], NULL, &tmpMeta[8], NULL, NULL, NULL);
_cache = tmpMeta[9];
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
_cenv = tmpMeta[4];
_ih = tmpMeta[5];
_daeElts = tmpMeta[7];
_ty = tmpMeta[8];
omc_List_map2__0(threadData, _daeElts, boxvar_InstUtil_checkFunctionElement, mmc_mk_boolean(1), _info);
_cache = omc_Inst_makeFullyQualifiedIdent(threadData, _cache, _env, _n, _OMC_LIT40 ,&_fpath);
_cmt = omc_InstUtil_extractComment(threadData, _daeElts);
_derFuncs = omc_InstUtil_getDeriveAnnotation(threadData, _cd, _cmt, _fpath, _cache, _env, _ih, _pre, _info);
_cache = omc_InstFunction_instantiateDerivativeFuncs(threadData, _cache, _env, _ih, _derFuncs, _fpath, _info);
_ty1 = omc_InstUtil_setFullyQualifiedTypename(threadData, _ty, _fpath);
omc_InstFunction_checkExtObjOutput(threadData, _ty1, _info);
_env_1 = omc_FGraph_mkTypeNode(threadData, _cenv, _n, _ty1);
_vis = _OMC_LIT52;
tmpMeta[4] = mmc_mk_box3(11, &ClassInf_State_FUNCTION__desc, _fpath, mmc_mk_boolean(_isImpure));
_cache = omc_Inst_instClassdef(threadData, _cache, _env_1, _ih, _OMC_LIT53, _mod, _pre, tmpMeta[4], _n, _parts, _restr, _vis, _partialPrefix, _encapsulatedPrefix, _inst_dims, 1, _OMC_LIT20, _OMC_LIT21, _OMC_LIT24, mmc_mk_none(), _cmt, _info ,&_tempenv ,&_ih ,NULL ,NULL ,NULL ,NULL ,NULL ,NULL ,NULL ,NULL ,NULL);
_cache = omc_InstFunction_instExtDecl(threadData, _cache, _tempenv, _ih, _n, _scExtdecl, _daeElts, _ty1, 1, _pre, _info ,&_ih ,&_extdecl);
_source = omc_ElementSource_createElementSource(threadData, _info, omc_FGraph_getScopePath(threadData, _env), _pre, _OMC_LIT51);
_partialPrefixBool = omc_SCodeUtil_partialBool(threadData, _partialPrefix);
omc_InstUtil_checkExternalFunction(threadData, _daeElts, _extdecl, omc_AbsynUtil_pathString(threadData, _fpath, _OMC_LIT2, 1, 0));
tmpMeta[6] = mmc_mk_box3(4, &DAE_FunctionDefinition_FUNCTION__EXT__desc, _daeElts, _extdecl);
tmpMeta[5] = mmc_mk_cons(tmpMeta[6], _derFuncs);
tmpMeta[7] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[8] = mmc_mk_box11(3, &DAE_Function_FUNCTION__desc, _fpath, tmpMeta[5], _ty1, _visibility, mmc_mk_boolean(_partialPrefixBool), mmc_mk_boolean(_isImpure), _OMC_LIT54, tmpMeta[7], _source, mmc_mk_some(_cmt));
tmpMeta[4] = mmc_mk_cons(tmpMeta[8], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env_1;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = tmpMeta[4];
goto tmp3_done;
}
case 2: {
modelica_integer tmp10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,2,8) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],9,1) == 0) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],0,1) == 0) goto tmp3_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 2));
tmp10 = mmc_unbox_integer(tmpMeta[9]);
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[10],4,1) == 0) goto tmp3_end;
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[10]), 2));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 8));
_n = tmpMeta[4];
_visibility = tmpMeta[6];
_isImpure = tmp10;
_funcnames = tmpMeta[11];
_cmt = tmpMeta[12];
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_pre = tmp4_5;
_cache = omc_InstFunction_instOverloadedFunctions(threadData, _cache, _env, _ih, _pre, _funcnames, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inClass), 9))) ,&_env ,&_ih ,&_resfns);
_cache = omc_Inst_makeFullyQualifiedIdent(threadData, _cache, _env, _n, _OMC_LIT40 ,&_fpath);
tmpMeta[5] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[6] = mmc_mk_box11(3, &DAE_Function_FUNCTION__desc, _fpath, _OMC_LIT56, _OMC_LIT49, _visibility, mmc_mk_boolean(1), mmc_mk_boolean(_isImpure), _OMC_LIT54, tmpMeta[5], _OMC_LIT16, mmc_mk_some(_cmt));
tmpMeta[4] = mmc_mk_cons(tmpMeta[6], _resfns);
_resfns = tmpMeta[4];
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = _resfns;
goto tmp3_done;
}
case 3: {
modelica_boolean tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,2,8) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 2));
_n = tmpMeta[4];
_env = tmp4_2;
tmp11 = omc_Flags_isSet(threadData, _OMC_LIT28);
if (1 != tmp11) goto goto_2;
tmpMeta[4] = stringAppend(_OMC_LIT57,_n);
omc_Debug_traceln(threadData, tmpMeta[4]);
tmpMeta[4] = stringAppend(_OMC_LIT58,omc_FGraph_printGraphPathStr(threadData, _env));
omc_Debug_traceln(threadData, tmpMeta[4]);
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
_outCache = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_outIH = tmpMeta[0+2];
_funcs = tmpMeta[0+3];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outIH) { *out_outIH = _outIH; }
if (out_funcs) { *out_funcs = _funcs; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstFunction_implicitFunctionInstantiation2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inClass, modelica_metatype _inInstDims, modelica_metatype _instFunctionTypeOnly, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_funcs)
{
modelica_integer tmp1;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_instFunctionTypeOnly);
_outCache = omc_InstFunction_implicitFunctionInstantiation2(threadData, _inCache, _inEnv, _inIH, _inMod, _inPrefix, _inClass, _inInstDims, tmp1, out_outEnv, out_outIH, out_funcs);
return _outCache;
}
DLLExport
modelica_metatype omc_InstFunction_implicitFunctionInstantiation(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inClass, modelica_metatype _inInstDims, modelica_metatype *out_outEnv, modelica_metatype *out_outIH)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outIH = NULL;
modelica_metatype tmpMeta[12] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_metatype tmp4_4;modelica_metatype tmp4_5;modelica_metatype tmp4_6;modelica_metatype tmp4_7;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inIH;
tmp4_4 = _inMod;
tmp4_5 = _inPrefix;
tmp4_6 = _inClass;
tmp4_7 = _inInstDims;
{
modelica_metatype _ty1 = NULL;
modelica_metatype _env = NULL;
modelica_metatype _cenv = NULL;
modelica_metatype _fpath = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _pre = NULL;
modelica_metatype _c = NULL;
modelica_string _n = NULL;
modelica_metatype _inst_dims = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _ih = NULL;
modelica_metatype _source = NULL;
modelica_metatype _funs = NULL;
modelica_metatype _fun = NULL;
modelica_metatype _r = NULL;
modelica_metatype _pPrefix = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,2,8) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],3,1) == 0) goto tmp3_end;
_c = tmp4_6;
_n = tmpMeta[3];
_pPrefix = tmpMeta[4];
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_mod = tmp4_4;
_pre = tmp4_5;
_inst_dims = tmp4_7;
tmpMeta[3] = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _n);
_cache = omc_Lookup_lookupRecordConstructorClass(threadData, _cache, _env, tmpMeta[3] ,&_c ,&_cenv);
tmpMeta[11] = omc_InstFunction_implicitFunctionInstantiation2(threadData, _cache, _cenv, _ih, _mod, _pre, _c, _inst_dims, 1, &tmpMeta[3], &tmpMeta[4], &tmpMeta[5]);
_cache = tmpMeta[11];
if (listEmpty(tmpMeta[5])) goto goto_2;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],0,10) == 0) goto goto_2;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 4));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 10));
if (!listEmpty(tmpMeta[7])) goto goto_2;
_env = tmpMeta[3];
_ih = tmpMeta[4];
_fpath = tmpMeta[8];
_ty1 = tmpMeta[9];
_source = tmpMeta[10];
tmpMeta[3] = mmc_mk_box4(4, &DAE_Function_RECORD__CONSTRUCTOR__desc, _fpath, _ty1, _source);
_fun = tmpMeta[3];
tmpMeta[3] = mmc_mk_cons(_fun, MMC_REFSTRUCTLIT(mmc_nil));
_cache = omc_InstUtil_addFunctionsToDAE(threadData, _cache, tmpMeta[3], _pPrefix);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = _ih;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,2,8) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 6));
_c = tmp4_6;
_pPrefix = tmpMeta[3];
_r = tmpMeta[4];
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_mod = tmp4_4;
_pre = tmp4_5;
_inst_dims = tmp4_7;
tmp6 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmpMeta[3] = _r;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],3,1) == 0) goto goto_7;
tmp6 = 1;
goto goto_7;
goto_7:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp6) {goto goto_2;}
_cache = omc_InstFunction_implicitFunctionInstantiation2(threadData, _cache, _env, _ih, _mod, _pre, _c, _inst_dims, 0 ,&_env ,&_ih ,&_funs);
_cache = omc_InstUtil_addFunctionsToDAE(threadData, _cache, _funs, _pPrefix);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = _ih;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,2,8) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 2));
_n = tmpMeta[3];
_env = tmp4_2;
tmp8 = omc_Flags_isSet(threadData, _OMC_LIT28);
if (1 != tmp8) goto goto_2;
tmpMeta[3] = stringAppend(_OMC_LIT59,_n);
omc_Debug_traceln(threadData, tmpMeta[3]);
tmpMeta[3] = stringAppend(_OMC_LIT58,omc_FGraph_printGraphPathStr(threadData, _env));
omc_Debug_traceln(threadData, tmpMeta[3]);
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
_outCache = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_outIH = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outIH) { *out_outIH = _outIH; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstFunction_instantiateExternalObjectConstructor(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _env, modelica_metatype _inIH, modelica_metatype _cl, modelica_metatype *out_outIH, modelica_metatype *out_outType)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outIH = NULL;
modelica_metatype _outType = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inCache;
tmp4_2 = _inIH;
{
modelica_metatype _cache = NULL;
modelica_metatype _env1 = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _ih = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_cache = tmp4_1;
_ih = tmp4_2;
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_InstFunction_implicitFunctionInstantiation(threadData, _cache, _env, _ih, _OMC_LIT18, _OMC_LIT19, _cl, tmpMeta[3] ,&_env1 ,&_ih);
_cache = omc_Lookup_lookupType(threadData, _cache, _env1, _OMC_LIT1, mmc_mk_none() ,&_ty ,NULL);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _ih;
tmpMeta[0+2] = _ty;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
tmp6 = omc_Flags_isSet(threadData, _OMC_LIT28);
if (1 != tmp6) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT60);
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
_outCache = tmpMeta[0+0];
_outIH = tmpMeta[0+1];
_outType = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outIH) { *out_outIH = _outIH; }
if (out_outType) { *out_outType = _outType; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstFunction_instantiateExternalObjectDestructor(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _env, modelica_metatype _inIH, modelica_metatype _cl, modelica_metatype *out_outIH)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outIH = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inCache;
tmp4_2 = _inIH;
{
modelica_metatype _cache = NULL;
modelica_metatype _ih = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_cache = tmp4_1;
_ih = tmp4_2;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_InstFunction_implicitFunctionInstantiation(threadData, _cache, _env, _ih, _OMC_LIT18, _OMC_LIT19, _cl, tmpMeta[2] ,NULL ,&_ih);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _ih;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
tmp6 = omc_Flags_isSet(threadData, _OMC_LIT28);
if (1 != tmp6) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT61);
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
_outCache = tmpMeta[0+0];
_outIH = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outIH) { *out_outIH = _outIH; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC void omc_InstFunction_checkExternalObjectMod(threadData_t *threadData, modelica_metatype _inMod, modelica_string _inClassName)
{
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inMod;
{
modelica_string _id = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _info = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,5) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (!listEmpty(tmpMeta[0])) goto tmp2_end;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,5) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (listEmpty(tmpMeta[0])) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_id = tmpMeta[3];
_mod = tmpMeta[4];
_info = omc_Mod_getModInfo(threadData, _mod);
tmpMeta[0] = mmc_mk_cons(_id, mmc_mk_cons(_inClassName, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT64, tmpMeta[0], _info);
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
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_metatype omc_InstFunction_instantiateExternalObject(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _els, modelica_metatype _inMod, modelica_boolean _impl, modelica_metatype _comment, modelica_metatype _info, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_dae, modelica_metatype *out_ciState)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outIH = NULL;
modelica_metatype _dae = NULL;
modelica_metatype _ciState = NULL;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_boolean tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inIH;
tmp4_4 = _impl;
{
modelica_metatype _destr = NULL;
modelica_metatype _constr = NULL;
modelica_metatype _cache = NULL;
modelica_string _className = NULL;
modelica_metatype _classNameFQ = NULL;
modelica_metatype _functp = NULL;
modelica_metatype _env = NULL;
modelica_metatype _r = NULL;
modelica_metatype _ih = NULL;
modelica_metatype _source = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (0 != tmp4_4) goto tmp3_end;
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
tmp4 += 1;
_className = omc_FNode_refName(threadData, omc_FGraph_lastScopeRef(threadData, _env));
omc_InstFunction_checkExternalObjectMod(threadData, _inMod, _className);
_destr = omc_SCodeUtil_getExternalObjectDestructor(threadData, _els);
_constr = omc_SCodeUtil_getExternalObjectConstructor(threadData, _els);
_env = omc_FGraph_mkClassNode(threadData, _env, _destr, _OMC_LIT19, _inMod, 0);
_env = omc_FGraph_mkClassNode(threadData, _env, _constr, _OMC_LIT19, _inMod, 0);
_cache = omc_InstFunction_instantiateExternalObjectDestructor(threadData, _cache, _env, _ih, _destr ,&_ih);
_cache = omc_InstFunction_instantiateExternalObjectConstructor(threadData, _cache, _env, _ih, _constr ,&_ih ,&_functp);
tmpMeta[5] = omc_FGraph_getScopePath(threadData, _env);
if (optionNone(tmpMeta[5])) goto goto_2;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 1));
_classNameFQ = tmpMeta[6];
_env = omc_FGraph_stripLastScopeRef(threadData, _env ,&_r);
_env = omc_FGraph_mkTypeNode(threadData, _env, _className, _functp);
_env = omc_FGraph_pushScopeRef(threadData, _env, _r);
_source = omc_ElementSource_addElementSourcePartOfOpt(threadData, _OMC_LIT16, omc_FGraph_getScopePath(threadData, _env));
_source = omc_ElementSource_addCommentToSource(threadData, _source, mmc_mk_some(_comment));
_source = omc_ElementSource_addElementSourceFileInfo(threadData, _source, _info);
tmpMeta[6] = mmc_mk_box3(21, &DAE_Element_EXTOBJECTCLASS__desc, _classNameFQ, _source);
tmpMeta[5] = mmc_mk_cons(tmpMeta[6], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[7] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta[5]);
tmpMeta[8] = mmc_mk_box2(20, &ClassInf_State_EXTERNAL__OBJ__desc, _classNameFQ);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = tmpMeta[7];
tmpMeta[0+4] = tmpMeta[8];
goto tmp3_done;
}
case 1: {
if (1 != tmp4_4) goto tmp3_end;
_cache = tmp4_1;
_ih = tmp4_3;
tmpMeta[5] = omc_FGraph_getScopePath(threadData, _inEnv);
if (optionNone(tmpMeta[5])) goto goto_2;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 1));
_classNameFQ = tmpMeta[6];
tmpMeta[5] = mmc_mk_box2(20, &ClassInf_State_EXTERNAL__OBJ__desc, _classNameFQ);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _inEnv;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = _OMC_LIT65;
tmpMeta[0+4] = tmpMeta[5];
goto tmp3_done;
}
case 2: {
modelica_boolean tmp6;
tmp6 = omc_Flags_isSet(threadData, _OMC_LIT28);
if (1 != tmp6) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT66);
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
_outCache = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_outIH = tmpMeta[0+2];
_dae = tmpMeta[0+3];
_ciState = tmpMeta[0+4];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outIH) { *out_outIH = _outIH; }
if (out_dae) { *out_dae = _dae; }
if (out_ciState) { *out_ciState = _ciState; }
return _outCache;
}
modelica_metatype boxptr_InstFunction_instantiateExternalObject(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _els, modelica_metatype _inMod, modelica_metatype _impl, modelica_metatype _comment, modelica_metatype _info, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_dae, modelica_metatype *out_ciState)
{
modelica_integer tmp1;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_impl);
_outCache = omc_InstFunction_instantiateExternalObject(threadData, _inCache, _inEnv, _inIH, _els, _inMod, tmp1, _comment, _info, out_outEnv, out_outIH, out_dae, out_ciState);
return _outCache;
}
