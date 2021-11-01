#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "FNode.c"
#endif
#include "omc_simulation_settings.h"
#include "FNode.h"
#define _OMC_LIT0_data "$ext_"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,5,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,1,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "$imp"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,4,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "$ref"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,4,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "$it"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,3,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "$mod"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,4,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "graphInst"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,9,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "Do graph based instantiation."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,29,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT8,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT7}};
#define _OMC_LIT8 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(77)),_OMC_LIT6,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT8}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "/"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,1,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "[i:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,3,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "] "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,2,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "[p:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,3,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data ", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,2,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data "[n:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,3,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "[d:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,3,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data "]"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,1,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
#define _OMC_LIT18_data "Unhandled node!"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT18,15,_OMC_LIT18_data);
#define _OMC_LIT18 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT18)
#define _OMC_LIT19_data "TOP"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT19,3,_OMC_LIT19_data);
#define _OMC_LIT19 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data "I"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,1,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
#define _OMC_LIT21_data "CE"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT21,2,_OMC_LIT21_data);
#define _OMC_LIT21 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "C"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,1,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
#define _OMC_LIT23_data "c"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT23,1,_OMC_LIT23_data);
#define _OMC_LIT23 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT23)
#define _OMC_LIT24_data "E"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT24,1,_OMC_LIT24_data);
#define _OMC_LIT24 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT24)
#define _OMC_LIT25_data "U"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT25,1,_OMC_LIT25_data);
#define _OMC_LIT25 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "FT"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,2,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data "ALG"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,3,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data "EQ"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,2,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data "OPT"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,3,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
#define _OMC_LIT30_data "ED"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT30,2,_OMC_LIT30_data);
#define _OMC_LIT30 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data "FS"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,2,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
#define _OMC_LIT32_data "FI"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT32,2,_OMC_LIT32_data);
#define _OMC_LIT32 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT32)
#define _OMC_LIT33_data "MS"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT33,2,_OMC_LIT33_data);
#define _OMC_LIT33 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT33)
#define _OMC_LIT34_data "M"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT34,1,_OMC_LIT34_data);
#define _OMC_LIT34 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT34)
#define _OMC_LIT35_data "r"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT35,1,_OMC_LIT35_data);
#define _OMC_LIT35 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT35)
#define _OMC_LIT36_data "CC"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT36,2,_OMC_LIT36_data);
#define _OMC_LIT36 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT36)
#define _OMC_LIT37_data "ND"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT37,2,_OMC_LIT37_data);
#define _OMC_LIT37 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT37)
#define _OMC_LIT38_data "REF"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT38,3,_OMC_LIT38_data);
#define _OMC_LIT38 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT38)
#define _OMC_LIT39_data "VR"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT39,2,_OMC_LIT39_data);
#define _OMC_LIT39 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT39)
#define _OMC_LIT40_data "IM"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT40,2,_OMC_LIT40_data);
#define _OMC_LIT40 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT40)
#define _OMC_LIT41_data "assert("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT41,7,_OMC_LIT41_data);
#define _OMC_LIT41 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT41)
#define _OMC_LIT42_data ")"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT42,1,_OMC_LIT42_data);
#define _OMC_LIT42 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT42)
#define _OMC_LIT43_data "UKNOWN NODE DATA"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT43,16,_OMC_LIT43_data);
#define _OMC_LIT43 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT43)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT44,1,5) {&DAE_Mod_NOMOD__desc,}};
#define _OMC_LIT44 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT44)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT45,1,3) {&FCore_Status_VAR__UNTYPED__desc,}};
#define _OMC_LIT45 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT45)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT46,1,11) {&DAE_Type_T__UNKNOWN__desc,}};
#define _OMC_LIT46 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT46)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT47,1,3) {&DAE_Binding_UNBOUND__desc,}};
#define _OMC_LIT47 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT47)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT48,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT48 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT48)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT49,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT49 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT49)
#define _OMC_LIT50_data "An element with name %s is already declared in this scope."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT50,58,_OMC_LIT50_data);
#define _OMC_LIT50 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT50)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT51,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT50}};
#define _OMC_LIT51 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT51)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT52,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(161)),_OMC_LIT48,_OMC_LIT49,_OMC_LIT51}};
#define _OMC_LIT52 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT52)
#define _OMC_LIT53_data "Qualified import name %s already exists in this scope."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT53,54,_OMC_LIT53_data);
#define _OMC_LIT53 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT53)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT54,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT53}};
#define _OMC_LIT54 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT54)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT55,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(163)),_OMC_LIT48,_OMC_LIT49,_OMC_LIT54}};
#define _OMC_LIT55 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT55)
#include "util/modelica.h"
#include "FNode_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FNode_copyChild(threadData_t *threadData, modelica_string _name, modelica_metatype _inRef);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FNode_copyChild,2,0) {(void*) boxptr_FNode_copyChild,0}};
#define boxvar_FNode_copyChild MMC_REFSTRUCTLIT(boxvar_lit_FNode_copyChild)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FNode_copy(threadData_t *threadData, modelica_metatype _inNode);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FNode_copy,2,0) {(void*) boxptr_FNode_copy,0}};
#define boxvar_FNode_copy MMC_REFSTRUCTLIT(boxvar_lit_FNode_copy)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FNode_updateRefInData(threadData_t *threadData, modelica_metatype _inData, modelica_metatype _inRef);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FNode_updateRefInData,2,0) {(void*) boxptr_FNode_updateRefInData,0}};
#define boxvar_FNode_updateRefInData MMC_REFSTRUCTLIT(boxvar_lit_FNode_updateRefInData)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FNode_updateRefInGraph(threadData_t *threadData, modelica_string _name, modelica_metatype _inRef, modelica_metatype _inTopRefAndGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FNode_updateRefInGraph,2,0) {(void*) boxptr_FNode_updateRefInGraph,0}};
#define boxvar_FNode_updateRefInGraph MMC_REFSTRUCTLIT(boxvar_lit_FNode_updateRefInGraph)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FNode_cloneChild(threadData_t *threadData, modelica_string _name, modelica_metatype _parentRef, modelica_metatype _inRef, modelica_metatype _inGraph, modelica_metatype *out_graph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FNode_cloneChild,2,0) {(void*) boxptr_FNode_cloneChild,0}};
#define boxvar_FNode_cloneChild MMC_REFSTRUCTLIT(boxvar_lit_FNode_cloneChild)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FNode_filter__work(threadData_t *threadData, modelica_string _name, modelica_metatype _ref, modelica_fnptr _filter, modelica_metatype _accum);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FNode_filter__work,2,0) {(void*) boxptr_FNode_filter__work,0}};
#define boxvar_FNode_filter__work MMC_REFSTRUCTLIT(boxvar_lit_FNode_filter__work)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FNode_namesUpToParentName__dispatch(threadData_t *threadData, modelica_metatype _inRef, modelica_string _inName, modelica_metatype _acc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FNode_namesUpToParentName__dispatch,2,0) {(void*) boxptr_FNode_namesUpToParentName__dispatch,0}};
#define boxvar_FNode_namesUpToParentName__dispatch MMC_REFSTRUCTLIT(boxvar_lit_FNode_namesUpToParentName__dispatch)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FNode_printElementConflictError(threadData_t *threadData, modelica_metatype _newRef, modelica_metatype _oldRef, modelica_string _name);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FNode_printElementConflictError,2,0) {(void*) boxptr_FNode_printElementConflictError,0}};
#define boxvar_FNode_printElementConflictError MMC_REFSTRUCTLIT(boxvar_lit_FNode_printElementConflictError)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_FNode_compareQualifiedImportNames(threadData_t *threadData, modelica_metatype _inImport1, modelica_metatype _inImport2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_FNode_compareQualifiedImportNames(threadData_t *threadData, modelica_metatype _inImport1, modelica_metatype _inImport2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FNode_compareQualifiedImportNames,2,0) {(void*) boxptr_FNode_compareQualifiedImportNames,0}};
#define boxvar_FNode_compareQualifiedImportNames MMC_REFSTRUCTLIT(boxvar_lit_FNode_compareQualifiedImportNames)
PROTECTED_FUNCTION_STATIC void omc_FNode_checkUniqueQualifiedImport(threadData_t *threadData, modelica_metatype _inImport, modelica_metatype _inImports, modelica_metatype _inInfo);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FNode_checkUniqueQualifiedImport,2,0) {(void*) boxptr_FNode_checkUniqueQualifiedImport,0}};
#define boxvar_FNode_checkUniqueQualifiedImport MMC_REFSTRUCTLIT(boxvar_lit_FNode_checkUniqueQualifiedImport)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FNode_translateQualifiedImportToNamed(threadData_t *threadData, modelica_metatype _inImport);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FNode_translateQualifiedImportToNamed,2,0) {(void*) boxptr_FNode_translateQualifiedImportToNamed,0}};
#define boxvar_FNode_translateQualifiedImportToNamed MMC_REFSTRUCTLIT(boxvar_lit_FNode_translateQualifiedImportToNamed)
DLLExport
modelica_boolean omc_FNode_scopePathEq(threadData_t *threadData, modelica_metatype _scope1, modelica_metatype _scope2)
{
modelica_boolean _eq;
modelica_boolean tmp1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean __omcQ_24tmpVar1;
modelica_boolean __omcQ_24tmpVar0;
modelica_integer tmp2;
modelica_metatype _r1_loopVar = 0;
modelica_metatype _r1;
modelica_metatype _r2_loopVar = 0;
modelica_metatype _r2;
_r1_loopVar = _scope1;
_r2_loopVar = _scope2;
__omcQ_24tmpVar1 = 1;
while(1) {
tmp2 = 2;
if (!listEmpty(_r1_loopVar)) {
_r1 = MMC_CAR(_r1_loopVar);
_r1_loopVar = MMC_CDR(_r1_loopVar);
tmp2--;
}if (!listEmpty(_r2_loopVar)) {
_r2 = MMC_CAR(_r2_loopVar);
_r2_loopVar = MMC_CDR(_r2_loopVar);
tmp2--;
}
if (tmp2 == 0) {
__omcQ_24tmpVar0 = (stringEqual(omc_FNode_refName(threadData, _r1), omc_FNode_refName(threadData, _r2)));
__omcQ_24tmpVar1 = (__omcQ_24tmpVar0 && __omcQ_24tmpVar1);
} else if (tmp2 == 2) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
tmp1 = __omcQ_24tmpVar1;
}
_eq = tmp1;
_return: OMC_LABEL_UNUSED
return _eq;
}
modelica_metatype boxptr_FNode_scopePathEq(threadData_t *threadData, modelica_metatype _scope1, modelica_metatype _scope2)
{
modelica_boolean _eq;
modelica_metatype out_eq;
_eq = omc_FNode_scopePathEq(threadData, _scope1, _scope2);
out_eq = mmc_mk_icon(_eq);
return out_eq;
}
DLLExport
modelica_integer omc_FNode_scopeHashWork(threadData_t *threadData, modelica_metatype _scope, modelica_integer __omcQ_24in_5Fhash)
{
modelica_integer _hash;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_hash = __omcQ_24in_5Fhash;
{
modelica_metatype _r;
for (tmpMeta1 = _scope; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_r = MMC_CAR(tmpMeta1);
_hash = (((modelica_integer) 31)) * (_hash) + stringHashDjb2(omc_FNode_refName(threadData, _r));
}
}
_return: OMC_LABEL_UNUSED
return _hash;
}
modelica_metatype boxptr_FNode_scopeHashWork(threadData_t *threadData, modelica_metatype _scope, modelica_metatype __omcQ_24in_5Fhash)
{
modelica_integer tmp1;
modelica_integer _hash;
modelica_metatype out_hash;
tmp1 = mmc_unbox_integer(__omcQ_24in_5Fhash);
_hash = omc_FNode_scopeHashWork(threadData, _scope, tmp1);
out_hash = mmc_mk_icon(_hash);
return out_hash;
}
DLLExport
modelica_string omc_FNode_mkExtendsName(threadData_t *threadData, modelica_metatype _inPath)
{
modelica_string _outName = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = stringAppend(_OMC_LIT0,omc_AbsynUtil_pathString(threadData, _inPath, _OMC_LIT1, 1, 0));
_outName = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outName;
}
DLLExport
modelica_metatype omc_FNode_importTable(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_metatype _it = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,2,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_it = tmpMeta7;
tmpMeta1 = _it;
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
_it = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _it;
}
DLLExport
modelica_metatype omc_FNode_refImport(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_metatype _r = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_r = omc_FNode_child(threadData, _inRef, _OMC_LIT2);
_return: OMC_LABEL_UNUSED
return _r;
}
DLLExport
modelica_metatype omc_FNode_refRefTargetScope(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_metatype _sc = NULL;
modelica_metatype _r = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_r = omc_FNode_refRef(threadData, _inRef);
_sc = omc_FNode_targetScope(threadData, omc_FNode_fromRef(threadData, _r));
_return: OMC_LABEL_UNUSED
return _sc;
}
DLLExport
modelica_metatype omc_FNode_refRef(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_metatype _r = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_r = omc_FNode_child(threadData, _inRef, _OMC_LIT3);
_return: OMC_LABEL_UNUSED
return _r;
}
DLLExport
modelica_boolean omc_FNode_isRefRefResolved(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = (!omc_FNode_isRefRefUnresolved(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefRefResolved(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefRefResolved(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefRefUnresolved(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
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
omc_FNode_refRef(threadData, _inRef);
tmp1 = listEmpty(omc_FNode_refRefTargetScope(threadData, _inRef));
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefRefUnresolved(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefRefUnresolved(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_metatype omc_FNode_refInstance(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_metatype _r = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_r = omc_FNode_child(threadData, _inRef, _OMC_LIT4);
_return: OMC_LABEL_UNUSED
return _r;
}
DLLExport
modelica_metatype omc_FNode_refInstVar(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_metatype _v = NULL;
modelica_metatype _r = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_r = omc_FNode_refInstance(threadData, _inRef);
tmpMeta1 = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,1,1) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_v = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _v;
}
DLLExport
modelica_boolean omc_FNode_isImplicitRefName(threadData_t *threadData, modelica_metatype _r)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
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
if (!(!omc_FNode_isRefTop(threadData, _r))) goto tmp3_end;
tmp1 = omc_FCore_isImplicitScope(threadData, omc_FNode_refName(threadData, _r));
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
modelica_metatype boxptr_FNode_isImplicitRefName(threadData_t *threadData, modelica_metatype _r)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isImplicitRefName(threadData, _r);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_metatype omc_FNode_getElementFromRef(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_metatype _outElement = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outElement = omc_FNode_getElement(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _outElement;
}
DLLExport
modelica_metatype omc_FNode_getElement(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_metatype _outElement = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
modelica_metatype _e = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_e = tmpMeta7;
tmpMeta1 = _e;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,4,4) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
_e = tmpMeta9;
tmpMeta1 = _e;
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
_outElement = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outElement;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FNode_copyChild(threadData_t *threadData, modelica_string _name, modelica_metatype _inRef)
{
modelica_metatype _ref = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ref = omc_FNode_copyRefNoUpdate(threadData, _inRef);
_return: OMC_LABEL_UNUSED
return _ref;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FNode_copy(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_metatype _outRef = NULL;
modelica_metatype _node = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_node = _inNode;
{
modelica_metatype tmp4_1;
tmp4_1 = _node;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_node), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[5] = omc_FCore_RefTree_map(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_node), 5))), boxvar_FNode_copyChild);
_node = tmpMeta6;
tmpMeta1 = omc_FNode_toRef(threadData, _node);
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
_outRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outRef;
}
DLLExport
modelica_metatype omc_FNode_copyRefNoUpdate(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_metatype _outRef = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outRef = omc_FNode_copy(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _outRef;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FNode_updateRefInData(threadData_t *threadData, modelica_metatype _inData, modelica_metatype _inRef)
{
modelica_metatype _outData = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inData;
{
modelica_metatype _sc = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,20,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_sc = tmpMeta6;
_sc = omc_List_map1r(threadData, _sc, boxvar_FNode_lookupRefFromRef, _inRef);
tmpMeta7 = mmc_mk_box2(23, &FCore_Data_REF__desc, _sc);
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _inData;
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
_outData = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outData;
}
DLLExport
modelica_metatype omc_FNode_lookupRefFromRef(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _inOldRef)
{
modelica_metatype _outRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _s = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_s = omc_FNode_originalScope(threadData, _inOldRef);
tmpMeta1 = omc_FNode_lookupRef(threadData, _inRef, _s);
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
_outRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outRef;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FNode_updateRefInGraph(threadData_t *threadData, modelica_string _name, modelica_metatype _inRef, modelica_metatype _inTopRefAndGraph)
{
modelica_metatype _outTopRefAndGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inTopRefAndGraph;
{
modelica_metatype _t = NULL;
modelica_metatype _g = NULL;
modelica_string _n = NULL;
modelica_integer _i;
modelica_metatype _p = NULL;
modelica_metatype _c = NULL;
modelica_metatype _d = NULL;
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
modelica_integer tmp11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_t = tmpMeta6;
_g = tmpMeta7;
tmpMeta8 = omc_FNode_fromRef(threadData, _inRef);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
tmp11 = mmc_unbox_integer(tmpMeta10);
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 4));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 5));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 6));
_n = tmpMeta9;
_i = tmp11;
_p = tmpMeta12;
_c = tmpMeta13;
_d = tmpMeta14;
_p = omc_List_map1r(threadData, _p, boxvar_FNode_lookupRefFromRef, _t);
_d = omc_FNode_updateRefInData(threadData, _d, _t);
tmpMeta15 = mmc_mk_box6(3, &FCore_Node_N__desc, _n, mmc_mk_integer(_i), _p, _c, _d);
omc_FNode_updateRef(threadData, _inRef, tmpMeta15);
tmpMeta16 = mmc_mk_box2(0, _t, _g);
tmpMeta1 = tmpMeta16;
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
_outTopRefAndGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outTopRefAndGraph;
}
DLLExport
modelica_metatype omc_FNode_updateRefs(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _inGraph, modelica_metatype *out_outRef)
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
modelica_metatype _g = NULL;
modelica_metatype _r = NULL;
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
_g = tmp4_1;
tmpMeta6 = mmc_mk_box2(0, _inRef, _g);
tmpMeta7 = omc_FNode_apply1(threadData, _inRef, boxvar_FNode_updateRefInGraph, tmpMeta6);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_r = tmpMeta8;
_g = tmpMeta9;
tmpMeta[0+0] = _g;
tmpMeta[0+1] = _r;
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
modelica_metatype omc_FNode_copyRef(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _inGraph, modelica_metatype *out_outRef)
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
modelica_metatype _g = NULL;
modelica_metatype _r = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_g = tmp4_1;
_r = omc_FNode_copyRefNoUpdate(threadData, _inRef);
tmpMeta[0+0] = omc_FNode_updateRefs(threadData, _r, _g, &tmpMeta[0+1]);
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FNode_cloneChild(threadData_t *threadData, modelica_string _name, modelica_metatype _parentRef, modelica_metatype _inRef, modelica_metatype _inGraph, modelica_metatype *out_graph)
{
modelica_metatype _ref = NULL;
modelica_metatype _graph = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_graph = omc_FNode_cloneRef(threadData, _name, _inRef, _parentRef, _inGraph ,&_ref);
_return: OMC_LABEL_UNUSED
if (out_graph) { *out_graph = _graph; }
return _ref;
}
static modelica_metatype closure0_FNode_cloneChild(threadData_t *thData, modelica_metatype closure, modelica_string name, modelica_metatype inRef, modelica_metatype inGraph, modelica_metatype tmp1)
{
modelica_metatype parentRef = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_FNode_cloneChild(thData, name, parentRef, inRef, inGraph, tmp1);
}
DLLExport
modelica_metatype omc_FNode_cloneTree(threadData_t *threadData, modelica_metatype _inChildren, modelica_metatype _inParentRef, modelica_metatype _inGraph, modelica_metatype *out_outChildren)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _outChildren = NULL;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta2 = mmc_mk_box1(0, _inParentRef);
_outChildren = omc_FCore_RefTree_mapFold(threadData, _inChildren, (modelica_fnptr) mmc_mk_box2(0,closure0_FNode_cloneChild,tmpMeta2), _inGraph ,&_outGraph);
_return: OMC_LABEL_UNUSED
if (out_outChildren) { *out_outChildren = _outChildren; }
return _outGraph;
}
DLLExport
modelica_metatype omc_FNode_clone(threadData_t *threadData, modelica_metatype _inNode, modelica_metatype _inParentRef, modelica_metatype _inGraph, modelica_metatype *out_outRef)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _outRef = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inNode;
tmp4_2 = _inGraph;
{
modelica_metatype _n = NULL;
modelica_metatype _g = NULL;
modelica_metatype _r = NULL;
modelica_string _name = NULL;
modelica_integer _id;
modelica_metatype _parents = NULL;
modelica_metatype _children = NULL;
modelica_metatype _data = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
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
modelica_integer tmp16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp8 = mmc_unbox_integer(tmpMeta7);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_name = tmpMeta6;
_id = tmp8;
_parents = tmpMeta9;
_children = tmpMeta10;
_data = tmpMeta11;
_g = tmp4_2;
tmpMeta12 = mmc_mk_cons(_inParentRef, _parents);
_parents = tmpMeta12;
tmpMeta19 = omc_FGraph_node(threadData, _g, _name, _parents, _data, &tmpMeta13);
_g = tmpMeta19;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 3));
tmp16 = mmc_unbox_integer(tmpMeta15);
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 4));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 6));
_n = tmpMeta13;
_name = tmpMeta14;
_id = tmp16;
_parents = tmpMeta17;
_data = tmpMeta18;
_r = omc_FNode_toRef(threadData, _n);
_g = omc_FNode_cloneTree(threadData, _children, _r, _g ,&_children);
tmpMeta20 = mmc_mk_box6(3, &FCore_Node_N__desc, _name, mmc_mk_integer(_id), _parents, _children, _data);
_r = omc_FNode_updateRef(threadData, _r, tmpMeta20);
tmpMeta[0+0] = _g;
tmpMeta[0+1] = _r;
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
modelica_metatype omc_FNode_cloneRef(threadData_t *threadData, modelica_string _inName, modelica_metatype _inRef, modelica_metatype _inParentRef, modelica_metatype _inGraph, modelica_metatype *out_outRef)
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
modelica_metatype _g = NULL;
modelica_metatype _r = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_g = tmp4_1;
_g = omc_FNode_clone(threadData, omc_FNode_fromRef(threadData, _inRef), _inParentRef, _g ,&_r);
omc_FNode_addChildRef(threadData, _inParentRef, _inName, _r, 0);
tmpMeta[0+0] = _g;
tmpMeta[0+1] = _r;
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
modelica_metatype omc_FNode_extendsRefs(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_metatype _outRefs = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _refs = NULL;
modelica_metatype _rd = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!omc_FNode_isRefClass(threadData, _inRef)) goto tmp3_end;
_rd = omc_FNode_derivedRef(threadData, _inRef);
_refs = omc_FNode_filter(threadData, _inRef, boxvar_FNode_isRefExtends);
_refs = omc_List_flatten(threadData, omc_List_map1(threadData, _refs, boxvar_FNode_filter, boxvar_FNode_isRefReference));
tmpMeta1 = listAppend(_rd, _refs);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
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
_outRefs = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outRefs;
}
DLLExport
modelica_metatype omc_FNode_derivedRef(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_metatype _outRefs = NULL;
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
if (!omc_FNode_isRefDerived(threadData, _inRef)) goto tmp3_end;
tmpMeta6 = mmc_mk_cons(omc_FNode_child(threadData, _inRef, _OMC_LIT3), MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
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
_outRefs = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outRefs;
}
DLLExport
modelica_metatype omc_FNode_imports(threadData_t *threadData, modelica_metatype _inNode, modelica_metatype *out_outUnQualifiedImports)
{
modelica_metatype _outQualifiedImports = NULL;
modelica_metatype _outUnQualifiedImports = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _qi = NULL;
modelica_metatype _uqi = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
tmpMeta6 = omc_FNode_importTable(threadData, omc_FNode_fromRef(threadData, omc_FNode_refImport(threadData, omc_FNode_toRef(threadData, _inNode))));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
_qi = tmpMeta7;
_uqi = tmpMeta8;
tmpMeta[0+0] = _qi;
tmpMeta[0+1] = _uqi;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
tmpMeta9 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = tmpMeta9;
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
_outQualifiedImports = tmpMeta[0+0];
_outUnQualifiedImports = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outUnQualifiedImports) { *out_outUnQualifiedImports = _outUnQualifiedImports; }
return _outQualifiedImports;
}
DLLExport
modelica_boolean omc_FNode_hasImports(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _qi = NULL;
modelica_metatype _uqi = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
tmpMeta6 = omc_FNode_importTable(threadData, omc_FNode_fromRef(threadData, omc_FNode_refImport(threadData, omc_FNode_toRef(threadData, _inNode))));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
_qi = tmpMeta7;
_uqi = tmpMeta8;
tmp1 = ((!listEmpty(_qi)) || (!listEmpty(_uqi)));
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
modelica_metatype boxptr_FNode_hasImports(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_hasImports(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_metatype omc_FNode_apply1(threadData_t *threadData, modelica_metatype _inRef, modelica_fnptr _inApply, modelica_metatype _inExtraArg)
{
modelica_metatype _outExtraArg = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outExtraArg = omc_FCore_RefTree_fold(threadData, omc_FNode_children(threadData, omc_FNode_fromRef(threadData, _inRef)), ((modelica_fnptr) _inApply), _inExtraArg);
_outExtraArg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inApply), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_string, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inApply), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inApply), 2))), omc_FNode_refName(threadData, _inRef), _inRef, _outExtraArg) : ((modelica_metatype(*)(threadData_t*, modelica_string, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inApply), 1)))) (threadData, omc_FNode_refName(threadData, _inRef), _inRef, _outExtraArg);
_return: OMC_LABEL_UNUSED
return _outExtraArg;
}
DLLExport
modelica_metatype omc_FNode_dfs(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_metatype _outRefs = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _refs = NULL;
modelica_metatype _c = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
_c = omc_FNode_children(threadData, omc_FNode_fromRef(threadData, _inRef));
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
_refs = omc_FCore_RefTree_listValues(threadData, _c, tmpMeta6);
_refs = omc_List_flatten(threadData, omc_List_map(threadData, _refs, boxvar_FNode_dfs));
tmpMeta7 = mmc_mk_cons(_inRef, _refs);
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
_outRefs = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outRefs;
}
DLLExport
modelica_boolean omc_FNode_isRefIn(threadData_t *threadData, modelica_metatype _inRef, modelica_fnptr _inFunctionRefIs)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isIn(threadData, omc_FNode_fromRef(threadData, _inRef), ((modelica_fnptr) _inFunctionRefIs));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefIn(threadData_t *threadData, modelica_metatype _inRef, modelica_fnptr _inFunctionRefIs)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefIn(threadData, _inRef, _inFunctionRefIs);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefDims(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isDims(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefDims(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefDims(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefVersion(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isVersion(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefVersion(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefVersion(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefClone(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isClone(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefClone(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefClone(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefModHolder(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isModHolder(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefModHolder(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefModHolder(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefMod(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isMod(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefMod(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefMod(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefSection(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isSection(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefSection(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefSection(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefRecord(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isRecord(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefRecord(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefRecord(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefFunction(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isFunction(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefFunction(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefFunction(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefBuiltin(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isBuiltin(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefBuiltin(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefBuiltin(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefBasicType(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isBasicType(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefBasicType(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefBasicType(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefTop(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isTop(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefTop(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefTop(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefUserDefined(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isUserDefined(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefUserDefined(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefUserDefined(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefReference(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isReference(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefReference(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefReference(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefCref(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isCref(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefCref(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefCref(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefClassExtends(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isClassExtends(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefClassExtends(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefClassExtends(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefRedeclare(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isRedeclare(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefRedeclare(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefRedeclare(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefInstance(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isInstance(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefInstance(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefInstance(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefClass(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isClass(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefClass(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefClass(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefConstrainClass(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isConstrainClass(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefConstrainClass(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefConstrainClass(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefComponent(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isComponent(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefComponent(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefComponent(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefDerived(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isDerived(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefDerived(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefDerived(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefExtends(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isExtends(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefExtends(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefExtends(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FNode_filter__work(threadData_t *threadData, modelica_string _name, modelica_metatype _ref, modelica_fnptr _filter, modelica_metatype _accum)
{
modelica_metatype _refs = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_refs = _accum;
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_filter), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_filter), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_filter), 2))), _ref) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_filter), 1)))) (threadData, _ref)))
{
tmpMeta1 = mmc_mk_cons(_ref, _refs);
_refs = tmpMeta1;
}
_return: OMC_LABEL_UNUSED
return _refs;
}
static modelica_metatype closure1_FNode_filter__work(threadData_t *thData, modelica_metatype closure, modelica_string name, modelica_metatype ref, modelica_metatype accum)
{
modelica_fnptr filter = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_FNode_filter__work(thData, name, ref, filter, accum);
}
DLLExport
modelica_metatype omc_FNode_filter(threadData_t *threadData, modelica_metatype _inRef, modelica_fnptr _inFilter)
{
modelica_metatype _filtered = NULL;
modelica_metatype _c = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_c = omc_FNode_children(threadData, omc_FNode_fromRef(threadData, _inRef));
tmpMeta1 = mmc_mk_box1(0, ((modelica_fnptr) _inFilter));
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
_filtered = omc_FCore_RefTree_fold(threadData, _c, (modelica_fnptr) mmc_mk_box2(0,closure1_FNode_filter__work,tmpMeta1), tmpMeta2);
_filtered = listReverse(_filtered);
_return: OMC_LABEL_UNUSED
return _filtered;
}
DLLExport
modelica_metatype omc_FNode_lookupRef__dispatch(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _inScope)
{
modelica_metatype _outRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inScope;
{
modelica_metatype _r = NULL;
modelica_metatype _rest = NULL;
modelica_string _n = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta1 = _inRef;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_r = tmpMeta6;
_rest = tmpMeta7;
_n = omc_FNode_name(threadData, omc_FNode_fromRef(threadData, _r));
_r = omc_FNode_child(threadData, _inRef, _n);
_inRef = _r;
_inScope = _rest;
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
_outRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outRef;
}
DLLExport
modelica_metatype omc_FNode_lookupRef(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _inScope)
{
modelica_metatype _outRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inScope;
{
modelica_metatype _s = NULL;
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (!listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta1 = _inRef;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
_s = tmp4_1;
tmpMeta8 = listReverse(_s);
if (listEmpty(tmpMeta8)) goto goto_2;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
_s = tmpMeta10;
tmpMeta1 = omc_FNode_lookupRef__dispatch(threadData, _inRef, _s);
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
_outRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outRef;
}
DLLExport
modelica_metatype omc_FNode_contextual(threadData_t *threadData, modelica_metatype _inParents)
{
modelica_metatype _outContextual = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outContextual = listHead(_inParents);
_return: OMC_LABEL_UNUSED
return _outContextual;
}
DLLExport
modelica_metatype omc_FNode_contextualScope__dispatch(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _inAcc)
{
modelica_metatype _outScope = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAcc;
{
modelica_metatype _acc = NULL;
modelica_metatype _r = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
_acc = tmp4_1;
if (!omc_FNode_isTop(threadData, omc_FNode_fromRef(threadData, _inRef))) goto tmp3_end;
tmpMeta6 = mmc_mk_cons(_inRef, _acc);
tmpMeta1 = listReverse(tmpMeta6);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
_acc = tmp4_1;
_r = omc_FNode_contextual(threadData, omc_FNode_parents(threadData, omc_FNode_fromRef(threadData, _inRef)));
tmpMeta8 = mmc_mk_cons(_inRef, _acc);
tmpMeta7 = _r;
_inAcc = tmpMeta8;
_inRef = tmpMeta7;
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
_outScope = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outScope;
}
DLLExport
modelica_metatype omc_FNode_contextualScope(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_metatype _outScope = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outScope = omc_FNode_contextualScope__dispatch(threadData, _inRef, tmpMeta1);
_return: OMC_LABEL_UNUSED
return _outScope;
}
DLLExport
modelica_metatype omc_FNode_original(threadData_t *threadData, modelica_metatype _inParents)
{
modelica_metatype _outOriginal = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outOriginal = omc_List_last(threadData, _inParents);
_return: OMC_LABEL_UNUSED
return _outOriginal;
}
DLLExport
modelica_metatype omc_FNode_originalScope__dispatch(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _inAcc)
{
modelica_metatype _outScope = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAcc;
{
modelica_metatype _acc = NULL;
modelica_metatype _r = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
_acc = tmp4_1;
if (!omc_FNode_isTop(threadData, omc_FNode_fromRef(threadData, _inRef))) goto tmp3_end;
tmpMeta6 = mmc_mk_cons(_inRef, _acc);
tmpMeta1 = listReverse(tmpMeta6);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
_acc = tmp4_1;
_r = omc_FNode_original(threadData, omc_FNode_parents(threadData, omc_FNode_fromRef(threadData, _inRef)));
tmpMeta8 = mmc_mk_cons(_inRef, _acc);
tmpMeta7 = _r;
_inAcc = tmpMeta8;
_inRef = tmpMeta7;
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
_outScope = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outScope;
}
DLLExport
modelica_metatype omc_FNode_originalScope(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_metatype _outScope = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outScope = omc_FNode_originalScope__dispatch(threadData, _inRef, tmpMeta1);
_return: OMC_LABEL_UNUSED
return _outScope;
}
DLLExport
modelica_metatype omc_FNode_getModifierTarget(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_metatype _outRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inRef;
{
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
_r = tmp4_1;
if (!omc_FNode_isRefModHolder(threadData, _r)) goto tmp3_end;
_r = omc_FNode_original(threadData, omc_FNode_refParents(threadData, _r));
tmpMeta6 = omc_FNode_refRefTargetScope(threadData, _r);
if (listEmpty(tmpMeta6)) goto goto_2;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
_r = tmpMeta7;
tmpMeta1 = _r;
goto tmp3_done;
}
case 1: {
tmpMeta1 = omc_FNode_getModifierTarget(threadData, omc_FNode_original(threadData, omc_FNode_refParents(threadData, _inRef)));
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
_outRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outRef;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FNode_namesUpToParentName__dispatch(threadData_t *threadData, modelica_metatype _inRef, modelica_string _inName, modelica_metatype _acc)
{
modelica_metatype _outNames = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_string tmp4_2;
tmp4_1 = _inRef;
tmp4_2 = _inName;
{
modelica_metatype _r = NULL;
modelica_string _name = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
_r = tmp4_1;
if (!omc_FNode_isRefTop(threadData, _r)) goto tmp3_end;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 1: {
_r = tmp4_1;
if (!(stringEqual(_inName, omc_FNode_refName(threadData, _r)))) goto tmp3_end;
tmpMeta1 = _acc;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta7;
_r = tmp4_1;
_name = tmp4_2;
tmpMeta7 = mmc_mk_cons(omc_FNode_refName(threadData, _r), _acc);
_inRef = omc_FNode_original(threadData, omc_FNode_refParents(threadData, _r));
_inName = _name;
_acc = tmpMeta7;
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
_outNames = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outNames;
}
DLLExport
modelica_metatype omc_FNode_namesUpToParentName(threadData_t *threadData, modelica_metatype _inRef, modelica_string _inName)
{
modelica_metatype _outNames = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outNames = omc_FNode_namesUpToParentName__dispatch(threadData, _inRef, _inName, tmpMeta1);
_return: OMC_LABEL_UNUSED
return _outNames;
}
DLLExport
modelica_metatype omc_FNode_nonImplicitRefFromScope(threadData_t *threadData, modelica_metatype _inScope)
{
modelica_metatype _outRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inScope;
{
modelica_metatype _r = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
goto goto_2;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_r = tmpMeta6;
if (!(!omc_FNode_isRefImplicitScope(threadData, _r))) goto tmp3_end;
tmpMeta1 = _r;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_1);
tmpMeta9 = MMC_CDR(tmp4_1);
_rest = tmpMeta9;
_inScope = _rest;
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
_outRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outRef;
}
DLLExport
modelica_boolean omc_FNode_isIn(threadData_t *threadData, modelica_metatype _inNode, modelica_fnptr _inFunctionRefIs)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _s = NULL;
modelica_boolean _b1;
modelica_boolean _b2;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_s = omc_FNode_originalScope(threadData, omc_FNode_toRef(threadData, _inNode));
_b1 = mmc_unbox_boolean(omc_List_applyAndFold(threadData, _s, boxvar_boolOr, ((modelica_fnptr) _inFunctionRefIs), mmc_mk_boolean(0)));
_s = omc_FNode_contextualScope(threadData, omc_FNode_toRef(threadData, _inNode));
_b2 = mmc_unbox_boolean(omc_List_applyAndFold(threadData, _s, boxvar_boolOr, ((modelica_fnptr) _inFunctionRefIs), mmc_mk_boolean(0)));
tmp1 = (_b1 || _b2);
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
modelica_metatype boxptr_FNode_isIn(threadData_t *threadData, modelica_metatype _inNode, modelica_fnptr _inFunctionRefIs)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isIn(threadData, _inNode, _inFunctionRefIs);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isDims(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,18,2) == 0) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isDims(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isDims(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isVersion(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,22,4) == 0) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isVersion(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isVersion(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isClone(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
modelica_metatype _r = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
_r = tmpMeta7;
tmp1 = omc_FNode_isRefVersion(threadData, _r);
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
modelica_metatype boxptr_FNode_isClone(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isClone(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isModHolder(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
modelica_string _n = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,15,1) == 0) goto tmp3_end;
_n = tmpMeta6;
tmp1 = (stringEqual(_n, _OMC_LIT5));
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
modelica_metatype boxptr_FNode_isModHolder(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isModHolder(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isMod(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,15,1) == 0) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isMod(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isMod(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isSection(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,8,2) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,9,2) == 0) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isSection(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isSection(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRecord(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = 0;
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
modelica_metatype _e = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_e = tmpMeta7;
if (!omc_SCodeUtil_isRecord(threadData, _e)) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRecord(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRecord(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isFunction(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
modelica_metatype _e = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_e = tmpMeta7;
if (!(omc_SCodeUtil_isFunction(threadData, _e) || omc_SCodeUtil_isOperator(threadData, _e))) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isFunction(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isFunction(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isBuiltin(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,4,4) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,1,0) == 0) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isBuiltin(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isBuiltin(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isBasicType(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,2,0) == 0) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isBasicType(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isBasicType(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isCref(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,17,1) == 0) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isCref(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isCref(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isConstrainClass(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,19,1) == 0) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isConstrainClass(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isConstrainClass(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isComponent(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,4,4) == 0) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isComponent(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isComponent(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isClassExtends(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,2,8) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,2) == 0) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isClassExtends(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isClassExtends(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRedeclare(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,2,8) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,4,4) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,3,8) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 3));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,0,0) == 0) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRedeclare(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRedeclare(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isInstance(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,7,1) == 0) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isInstance(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isInstance(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isClass(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,5) == 0) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isClass(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isClass(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isDerived(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
modelica_metatype _e = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_e = tmpMeta7;
tmp1 = omc_SCodeUtil_isDerivedClass(threadData, _e);
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
modelica_metatype boxptr_FNode_isDerived(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isDerived(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isExtends(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,5,2) == 0) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isExtends(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isExtends(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isTop(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,0) == 0) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isTop(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isTop(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isUserDefined(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,4,4) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (!omc_FNode_hasParents(threadData, _inNode)) goto tmp3_end;
tmpMeta10 = omc_FNode_parents(threadData, _inNode);
if (listEmpty(tmpMeta10)) goto goto_2;
tmpMeta11 = MMC_CAR(tmpMeta10);
tmpMeta12 = MMC_CDR(tmpMeta10);
_p = tmpMeta11;
tmp1 = omc_FNode_isRefUserDefined(threadData, _p);
goto tmp3_done;
}
case 3: {
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
modelica_metatype boxptr_FNode_isUserDefined(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isUserDefined(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isReference(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,20,1) == 0) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isReference(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isReference(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isEncapsulated(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,2,8) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,4,4) == 0) goto tmp3_end;
if (!(((!omc_Config_acceptMetaModelicaGrammar(threadData) && !0) || (omc_Config_acceptMetaModelicaGrammar(threadData) && 0)) && (!omc_Flags_isSet(threadData, _OMC_LIT9)))) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isEncapsulated(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isEncapsulated(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isRefImplicitScope(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_isImplicitScope(threadData, omc_FNode_fromRef(threadData, _inRef));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_isRefImplicitScope(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isRefImplicitScope(threadData, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_isImplicitScope(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 8; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,0) == 0) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,3,5) == 0) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,4,4) == 0) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta9;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,19,1) == 0) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta10;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,12,1) == 0) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta11;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,14,1) == 0) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta12;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,22,4) == 0) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 7: {
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
modelica_metatype boxptr_FNode_isImplicitScope(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_isImplicitScope(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_string omc_FNode_scopeStr(threadData_t *threadData, modelica_metatype _sc)
{
modelica_string _s = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_s = stringDelimitList(omc_List_map(threadData, listReverse(_sc), boxvar_FNode_refName), _OMC_LIT10);
_return: OMC_LABEL_UNUSED
return _s;
}
DLLExport
modelica_string omc_FNode_toPathStr(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_string _outStr = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
modelica_metatype _p = NULL;
modelica_metatype _nr = NULL;
modelica_string _s = NULL;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
tmp1 = omc_FNode_name(threadData, _inNode);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_boolean tmp8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_p = tmpMeta7;
_nr = omc_FNode_contextual(threadData, _p);
tmp8 = omc_FNode_hasParents(threadData, omc_FNode_fromRef(threadData, _nr));
if (1 != tmp8) goto goto_2;
_s = omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _nr));
tmpMeta9 = stringAppend(_s,_OMC_LIT1);
tmpMeta10 = stringAppend(tmpMeta9,omc_FNode_name(threadData, _inNode));
tmp1 = tmpMeta10;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta11;
modelica_boolean tmp12;
modelica_metatype tmpMeta13;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_p = tmpMeta11;
_nr = omc_FNode_contextual(threadData, _p);
tmp12 = omc_FNode_hasParents(threadData, omc_FNode_fromRef(threadData, _nr));
if (0 != tmp12) goto goto_2;
tmpMeta13 = stringAppend(_OMC_LIT1,omc_FNode_name(threadData, _inNode));
tmp1 = tmpMeta13;
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
_outStr = tmp1;
_return: OMC_LABEL_UNUSED
return _outStr;
}
DLLExport
modelica_string omc_FNode_toStr(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_string _outStr = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
modelica_integer _i;
modelica_metatype _p = NULL;
modelica_metatype _d = NULL;
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
modelica_integer tmp7;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp7 = mmc_unbox_integer(tmpMeta6);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_i = tmp7;
_p = tmpMeta8;
_d = tmpMeta9;
tmpMeta10 = stringAppend(_OMC_LIT11,intString(_i));
tmpMeta11 = stringAppend(tmpMeta10,_OMC_LIT12);
tmpMeta12 = stringAppend(tmpMeta11,_OMC_LIT13);
tmpMeta13 = stringAppend(tmpMeta12,stringDelimitList(omc_List_map(threadData, omc_List_map(threadData, omc_List_map(threadData, _p, boxvar_FNode_fromRef), boxvar_FNode_id), boxvar_intString), _OMC_LIT14));
tmpMeta14 = stringAppend(tmpMeta13,_OMC_LIT12);
tmpMeta15 = stringAppend(tmpMeta14,_OMC_LIT15);
tmpMeta16 = stringAppend(tmpMeta15,omc_FNode_name(threadData, _inNode));
tmpMeta17 = stringAppend(tmpMeta16,_OMC_LIT12);
tmpMeta18 = stringAppend(tmpMeta17,_OMC_LIT16);
tmpMeta19 = stringAppend(tmpMeta18,omc_FNode_dataStr(threadData, _d));
tmpMeta20 = stringAppend(tmpMeta19,_OMC_LIT17);
tmp1 = tmpMeta20;
goto tmp3_done;
}
case 1: {
tmp1 = _OMC_LIT18;
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
_outStr = tmp1;
_return: OMC_LABEL_UNUSED
return _outStr;
}
DLLExport
modelica_string omc_FNode_dataStr(threadData_t *threadData, modelica_metatype _inData)
{
modelica_string _outStr = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inData;
{
modelica_string _n = NULL;
modelica_string _m = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 26; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT19;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT20;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,5) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,2,8) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,2) == 0) goto tmp3_end;
tmp1 = _OMC_LIT21;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,5) == 0) goto tmp3_end;
tmp1 = _OMC_LIT22;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,4) == 0) goto tmp3_end;
tmp1 = _OMC_LIT23;
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
tmp1 = _OMC_LIT24;
goto tmp3_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT25;
goto tmp3_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT26;
goto tmp3_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
tmp1 = _OMC_LIT27;
goto tmp3_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,2) == 0) goto tmp3_end;
tmp1 = _OMC_LIT28;
goto tmp3_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,2) == 0) goto tmp3_end;
tmp1 = _OMC_LIT29;
goto tmp3_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT30;
goto tmp3_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT31;
goto tmp3_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT32;
goto tmp3_done;
}
case 14: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,14,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT33;
goto tmp3_done;
}
case 15: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT34;
goto tmp3_done;
}
case 16: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_n = tmpMeta8;
tmp1 = _n;
goto tmp3_done;
}
case 17: {
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_n = tmpMeta9;
tmp1 = _n;
goto tmp3_done;
}
case 18: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT35;
goto tmp3_done;
}
case 19: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,19,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT36;
goto tmp3_done;
}
case 20: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT37;
goto tmp3_done;
}
case 21: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,20,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT38;
goto tmp3_done;
}
case 22: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,4) == 0) goto tmp3_end;
tmp1 = _OMC_LIT39;
goto tmp3_done;
}
case 23: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT40;
goto tmp3_done;
}
case 24: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,23,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_m = tmpMeta10;
tmpMeta11 = stringAppend(_OMC_LIT41,_m);
tmpMeta12 = stringAppend(tmpMeta11,_OMC_LIT42);
tmp1 = tmpMeta12;
goto tmp3_done;
}
case 25: {
tmp1 = _OMC_LIT43;
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
_outStr = tmp1;
_return: OMC_LABEL_UNUSED
return _outStr;
}
DLLExport
modelica_metatype omc_FNode_element2Data(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inKind, modelica_metatype *out_outVar)
{
modelica_metatype _outData = NULL;
modelica_metatype _outVar = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
modelica_string _n = NULL;
modelica_metatype _vis = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _io = NULL;
modelica_metatype _prl = NULL;
modelica_metatype _var = NULL;
modelica_metatype _dir = NULL;
modelica_metatype _nd = NULL;
modelica_metatype _i = NULL;
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
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,8) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 3));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 4));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 5));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 6));
_n = tmpMeta6;
_vis = tmpMeta8;
_io = tmpMeta9;
_ct = tmpMeta11;
_prl = tmpMeta12;
_var = tmpMeta13;
_dir = tmpMeta14;
tmpMeta15 = mmc_mk_box5(7, &FCore_Data_CO__desc, _inElement, _OMC_LIT44, _inKind, _OMC_LIT45);
_nd = tmpMeta15;
tmpMeta16 = mmc_mk_box7(3, &DAE_Attributes_ATTR__desc, omc_DAEUtil_toConnectorTypeNoState(threadData, _ct, mmc_mk_none()), _prl, _var, _dir, _io, _vis);
tmpMeta17 = mmc_mk_box7(3, &DAE_Var_TYPES__VAR__desc, _n, tmpMeta16, _OMC_LIT46, _OMC_LIT47, mmc_mk_boolean(0), mmc_mk_none());
_i = tmpMeta17;
tmpMeta[0+0] = _nd;
tmpMeta[0+1] = _i;
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
_outData = tmpMeta[0+0];
_outVar = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outVar) { *out_outVar = _outVar; }
return _outData;
}
DLLExport
modelica_metatype omc_FNode_childFromNode(threadData_t *threadData, modelica_metatype _inNode, modelica_string _inName)
{
modelica_metatype _outChildRef = NULL;
modelica_metatype _c = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_c = omc_FNode_children(threadData, _inNode);
_outChildRef = omc_FCore_RefTree_get(threadData, _c, _inName);
_return: OMC_LABEL_UNUSED
return _outChildRef;
}
DLLExport
modelica_metatype omc_FNode_child(threadData_t *threadData, modelica_metatype _inParentRef, modelica_string _inName)
{
modelica_metatype _outChildRef = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outChildRef = omc_FNode_childFromNode(threadData, omc_FNode_fromRef(threadData, _inParentRef), _inName);
_return: OMC_LABEL_UNUSED
return _outChildRef;
}
DLLExport
modelica_metatype omc_FNode_setData(threadData_t *threadData, modelica_metatype _inNode, modelica_metatype _inData)
{
modelica_metatype _outNode = NULL;
modelica_string _n = NULL;
modelica_integer _i;
modelica_metatype _p = NULL;
modelica_metatype _c = NULL;
modelica_metatype _d = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_integer tmp4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inNode;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp4 = mmc_unbox_integer(tmpMeta3);
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 5));
_n = tmpMeta2;
_i = tmp4;
_p = tmpMeta5;
_c = tmpMeta6;
tmpMeta7 = mmc_mk_box6(3, &FCore_Node_N__desc, _n, mmc_mk_integer(_i), _p, _c, _inData);
_outNode = tmpMeta7;
_return: OMC_LABEL_UNUSED
return _outNode;
}
DLLExport
modelica_metatype omc_FNode_setChildren(threadData_t *threadData, modelica_metatype _inNode, modelica_metatype _inChildren)
{
modelica_metatype _outNode = NULL;
modelica_string _n = NULL;
modelica_integer _i;
modelica_metatype _p = NULL;
modelica_metatype _c = NULL;
modelica_metatype _d = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_integer tmp4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inNode;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp4 = mmc_unbox_integer(tmpMeta3);
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 5));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 6));
_n = tmpMeta2;
_i = tmp4;
_p = tmpMeta5;
_c = tmpMeta6;
_d = tmpMeta7;
tmpMeta8 = mmc_mk_box6(3, &FCore_Node_N__desc, _n, mmc_mk_integer(_i), _p, _inChildren, _d);
_outNode = tmpMeta8;
_return: OMC_LABEL_UNUSED
return _outNode;
}
DLLExport
modelica_boolean omc_FNode_refHasChild(threadData_t *threadData, modelica_metatype _inRef, modelica_string _inName)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_FNode_hasChild(threadData, omc_FNode_fromRef(threadData, _inRef), _inName);
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_refHasChild(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _inName)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_refHasChild(threadData, _inRef, _inName);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FNode_hasChild(threadData_t *threadData, modelica_metatype _inNode, modelica_string _inName)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
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
omc_FNode_childFromNode(threadData, _inNode, _inName);
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_hasChild(threadData_t *threadData, modelica_metatype _inNode, modelica_metatype _inName)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_hasChild(threadData, _inNode, _inName);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_metatype omc_FNode_children(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_metatype _outChildren = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inNode;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 5));
_outChildren = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _outChildren;
}
DLLExport
modelica_metatype omc_FNode_top(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_metatype _outTop = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outTop = _inRef;
while(1)
{
if(!omc_FNode_hasParents(threadData, omc_FNode_fromRef(threadData, _outTop))) break;
_outTop = omc_FNode_original(threadData, omc_FNode_parents(threadData, omc_FNode_fromRef(threadData, _outTop)));
}
_return: OMC_LABEL_UNUSED
return _outTop;
}
DLLExport
modelica_metatype omc_FNode_refData(threadData_t *threadData, modelica_metatype _r)
{
modelica_metatype _outData = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outData = omc_FNode_data(threadData, omc_FNode_fromRef(threadData, _r));
_return: OMC_LABEL_UNUSED
return _outData;
}
DLLExport
modelica_metatype omc_FNode_data(threadData_t *threadData, modelica_metatype _n)
{
modelica_metatype _d = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _n;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_d = tmpMeta6;
tmpMeta1 = _d;
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
_d = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _d;
}
DLLExport
modelica_string omc_FNode_refName(threadData_t *threadData, modelica_metatype _r)
{
modelica_string _n = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_n = omc_FNode_name(threadData, omc_FNode_fromRef(threadData, _r));
_return: OMC_LABEL_UNUSED
return _n;
}
DLLExport
modelica_string omc_FNode_name(threadData_t *threadData, modelica_metatype _n)
{
modelica_string _name = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _n;
{
modelica_string _s = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_s = tmpMeta6;
tmp1 = _s;
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
_name = tmp1;
_return: OMC_LABEL_UNUSED
return _name;
}
DLLExport
void omc_FNode_addDefinedUnitToRef(threadData_t *threadData, modelica_metatype _ref, modelica_metatype _du)
{
modelica_string _n = NULL;
modelica_integer _id;
modelica_metatype _p = NULL;
modelica_metatype _c = NULL;
modelica_metatype _d = NULL;
modelica_metatype _e = NULL;
modelica_metatype _t = NULL;
modelica_metatype _it = NULL;
modelica_metatype _r = NULL;
modelica_metatype _dus = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_integer tmp4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = omc_FNode_fromRef(threadData, _ref);
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp4 = mmc_unbox_integer(tmpMeta3);
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 5));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,6,1) == 0) MMC_THROW_INTERNAL();
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_n = tmpMeta2;
_id = tmp4;
_p = tmpMeta5;
_c = tmpMeta6;
_dus = tmpMeta8;
tmpMeta9 = mmc_mk_cons(_du, _dus);
tmpMeta10 = mmc_mk_box2(9, &FCore_Data_DU__desc, tmpMeta9);
tmpMeta11 = mmc_mk_box6(3, &FCore_Node_N__desc, _n, mmc_mk_integer(_id), _p, _c, tmpMeta10);
_r = omc_FNode_updateRef(threadData, _ref, tmpMeta11);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_FNode_addIteratorsToRef(threadData_t *threadData, modelica_metatype _ref, modelica_metatype _inIterators)
{
modelica_string _n = NULL;
modelica_integer _id;
modelica_metatype _p = NULL;
modelica_metatype _c = NULL;
modelica_metatype _d = NULL;
modelica_metatype _e = NULL;
modelica_metatype _t = NULL;
modelica_metatype _it = NULL;
modelica_metatype _r = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_integer tmp4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = omc_FNode_fromRef(threadData, _ref);
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp4 = mmc_unbox_integer(tmpMeta3);
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 5));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,12,1) == 0) MMC_THROW_INTERNAL();
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_n = tmpMeta2;
_id = tmp4;
_p = tmpMeta5;
_c = tmpMeta6;
_it = tmpMeta8;
tmpMeta9 = mmc_mk_box2(15, &FCore_Data_FS__desc, listAppend(_it, _inIterators));
tmpMeta10 = mmc_mk_box6(3, &FCore_Node_N__desc, _n, mmc_mk_integer(_id), _p, _c, tmpMeta9);
_r = omc_FNode_updateRef(threadData, _ref, tmpMeta10);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_FNode_addTypesToRef(threadData_t *threadData, modelica_metatype _ref, modelica_metatype _inTys)
{
modelica_string _n = NULL;
modelica_integer _id;
modelica_metatype _p = NULL;
modelica_metatype _c = NULL;
modelica_metatype _d = NULL;
modelica_metatype _e = NULL;
modelica_metatype _t = NULL;
modelica_metatype _it = NULL;
modelica_metatype _tys = NULL;
modelica_metatype _r = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_integer tmp4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = omc_FNode_fromRef(threadData, _ref);
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp4 = mmc_unbox_integer(tmpMeta3);
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 5));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,7,1) == 0) MMC_THROW_INTERNAL();
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_n = tmpMeta2;
_id = tmp4;
_p = tmpMeta5;
_c = tmpMeta6;
_tys = tmpMeta8;
_tys = omc_List_unique(threadData, listAppend(_inTys, _tys));
tmpMeta9 = mmc_mk_box2(10, &FCore_Data_FT__desc, _tys);
tmpMeta10 = mmc_mk_box6(3, &FCore_Node_N__desc, _n, mmc_mk_integer(_id), _p, _c, tmpMeta9);
_r = omc_FNode_updateRef(threadData, _ref, tmpMeta10);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_FNode_addImportToRef(threadData_t *threadData, modelica_metatype _ref, modelica_metatype _imp)
{
modelica_string _n = NULL;
modelica_integer _id;
modelica_metatype _p = NULL;
modelica_metatype _c = NULL;
modelica_metatype _d = NULL;
modelica_metatype _e = NULL;
modelica_metatype _t = NULL;
modelica_metatype _it = NULL;
modelica_metatype _r = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_integer tmp4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = omc_FNode_fromRef(threadData, _ref);
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp4 = mmc_unbox_integer(tmpMeta3);
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 5));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,2,1) == 0) MMC_THROW_INTERNAL();
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_n = tmpMeta2;
_id = tmp4;
_p = tmpMeta5;
_c = tmpMeta6;
_it = tmpMeta8;
_it = omc_FNode_addImport(threadData, _imp, _it);
tmpMeta9 = mmc_mk_box2(5, &FCore_Data_IM__desc, _it);
tmpMeta10 = mmc_mk_box6(3, &FCore_Node_N__desc, _n, mmc_mk_integer(_id), _p, _c, tmpMeta9);
_r = omc_FNode_updateRef(threadData, _ref, tmpMeta10);
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FNode_printElementConflictError(threadData_t *threadData, modelica_metatype _newRef, modelica_metatype _oldRef, modelica_string _name)
{
modelica_metatype _dummy = NULL;
modelica_metatype _info1 = NULL;
modelica_metatype _info2 = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(omc_Config_acceptMetaModelicaGrammar(threadData))
{
_dummy = _newRef;
}
else
{
_info1 = omc_SCodeUtil_elementInfo(threadData, omc_FNode_getElementFromRef(threadData, _newRef));
_info2 = omc_SCodeUtil_elementInfo(threadData, omc_FNode_getElementFromRef(threadData, _oldRef));
tmpMeta1 = mmc_mk_cons(_name, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta2 = mmc_mk_cons(_info2, mmc_mk_cons(_info1, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addMultiSourceMessage(threadData, _OMC_LIT52, tmpMeta1, tmpMeta2);
MMC_THROW_INTERNAL();
}
_return: OMC_LABEL_UNUSED
return _dummy;
}
DLLExport
void omc_FNode_addChildRef(threadData_t *threadData, modelica_metatype _inParentRef, modelica_string _inName, modelica_metatype _inChildRef, modelica_boolean _checkDuplicate)
{
modelica_string _n = NULL;
modelica_integer _i;
modelica_metatype _p = NULL;
modelica_metatype _c = NULL;
modelica_metatype _d = NULL;
modelica_metatype _parent = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_integer tmp4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = omc_FNode_fromRef(threadData, _inParentRef);
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp4 = mmc_unbox_integer(tmpMeta3);
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 5));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 6));
_n = tmpMeta2;
_i = tmp4;
_p = tmpMeta5;
_c = tmpMeta6;
_d = tmpMeta7;
_c = omc_FCore_RefTree_add(threadData, _c, _inName, _inChildRef, (_checkDuplicate?boxvar_FNode_printElementConflictError:boxvar_FCore_RefTree_addConflictReplace));
tmpMeta8 = mmc_mk_box6(3, &FCore_Node_N__desc, _n, mmc_mk_integer(_i), _p, _c, _d);
_parent = omc_FNode_updateRef(threadData, _inParentRef, tmpMeta8);
omc_FGraphStream_edge(threadData, _inName, omc_FNode_fromRef(threadData, _parent), omc_FNode_fromRef(threadData, _inChildRef));
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_FNode_addChildRef(threadData_t *threadData, modelica_metatype _inParentRef, modelica_metatype _inName, modelica_metatype _inChildRef, modelica_metatype _checkDuplicate)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_checkDuplicate);
omc_FNode_addChildRef(threadData, _inParentRef, _inName, _inChildRef, tmp1);
return;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_FNode_compareQualifiedImportNames(threadData_t *threadData, modelica_metatype _inImport1, modelica_metatype _inImport2)
{
modelica_boolean _outEqual;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inImport1;
tmp4_2 = _inImport2;
{
modelica_string _name1 = NULL;
modelica_string _name2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_name1 = tmpMeta6;
_name2 = tmpMeta7;
if (!(stringEqual(_name1, _name2))) goto tmp3_end;
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
_outEqual = tmp1;
_return: OMC_LABEL_UNUSED
return _outEqual;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_FNode_compareQualifiedImportNames(threadData_t *threadData, modelica_metatype _inImport1, modelica_metatype _inImport2)
{
modelica_boolean _outEqual;
modelica_metatype out_outEqual;
_outEqual = omc_FNode_compareQualifiedImportNames(threadData, _inImport1, _inImport2);
out_outEqual = mmc_mk_icon(_outEqual);
return out_outEqual;
}
PROTECTED_FUNCTION_STATIC void omc_FNode_checkUniqueQualifiedImport(threadData_t *threadData, modelica_metatype _inImport, modelica_metatype _inImports, modelica_metatype _inInfo)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inImport;
{
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
modelica_boolean tmp5;
tmp5 = omc_List_isMemberOnTrue(threadData, _inImport, _inImports, boxvar_FNode_compareQualifiedImportNames);
if (0 != tmp5) goto goto_1;
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_name = tmpMeta6;
tmpMeta7 = mmc_mk_cons(_name, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT55, tmpMeta7, _inInfo);
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
return;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FNode_translateQualifiedImportToNamed(threadData_t *threadData, modelica_metatype _inImport)
{
modelica_metatype _outImport = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inImport;
{
modelica_string _name = NULL;
modelica_metatype _path = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta1 = _inImport;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_path = tmpMeta6;
_name = omc_AbsynUtil_pathLastIdent(threadData, _path);
tmpMeta7 = mmc_mk_box3(3, &Absyn_Import_NAMED__IMPORT__desc, _name, _path);
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
_outImport = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outImport;
}
DLLExport
modelica_metatype omc_FNode_addImport(threadData_t *threadData, modelica_metatype _inImport, modelica_metatype _inImportTable)
{
modelica_metatype _outImportTable = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inImport;
tmp4_2 = _inImportTable;
{
modelica_metatype _imp = NULL;
modelica_metatype _qual_imps = NULL;
modelica_metatype _unqual_imps = NULL;
modelica_metatype _info = NULL;
modelica_boolean _hidden;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,2,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp8 = mmc_unbox_integer(tmpMeta7);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_imp = tmpMeta6;
_hidden = tmp8;
_qual_imps = tmpMeta9;
_unqual_imps = tmpMeta10;
_unqual_imps = omc_List_unionElt(threadData, _imp, _unqual_imps);
tmpMeta11 = mmc_mk_box4(3, &FCore_ImportTable_IMPORT__TABLE__desc, mmc_mk_boolean(_hidden), _qual_imps, _unqual_imps);
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_integer tmp15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,3) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp15 = mmc_unbox_integer(tmpMeta14);
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_imp = tmpMeta12;
_info = tmpMeta13;
_hidden = tmp15;
_qual_imps = tmpMeta16;
_unqual_imps = tmpMeta17;
_imp = omc_FNode_translateQualifiedImportToNamed(threadData, _imp);
omc_FNode_checkUniqueQualifiedImport(threadData, _imp, _qual_imps, _info);
_qual_imps = omc_List_unionElt(threadData, _imp, _qual_imps);
tmpMeta18 = mmc_mk_box4(3, &FCore_ImportTable_IMPORT__TABLE__desc, mmc_mk_boolean(_hidden), _qual_imps, _unqual_imps);
tmpMeta1 = tmpMeta18;
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
_outImportTable = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outImportTable;
}
DLLExport
modelica_metatype omc_FNode_new(threadData_t *threadData, modelica_string _inName, modelica_integer _inId, modelica_metatype _inParents, modelica_metatype _inData)
{
modelica_metatype _node = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box6(3, &FCore_Node_N__desc, _inName, mmc_mk_integer(_inId), _inParents, omc_FCore_RefTree_new(threadData), _inData);
_node = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _node;
}
modelica_metatype boxptr_FNode_new(threadData_t *threadData, modelica_metatype _inName, modelica_metatype _inId, modelica_metatype _inParents, modelica_metatype _inData)
{
modelica_integer tmp1;
modelica_metatype _node = NULL;
tmp1 = mmc_unbox_integer(_inId);
_node = omc_FNode_new(threadData, _inName, tmp1, _inParents, _inData);
return _node;
}
DLLExport
modelica_metatype omc_FNode_targetScope(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_metatype _outScope = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,20,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_outScope = tmpMeta7;
tmpMeta1 = _outScope;
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
_outScope = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outScope;
}
DLLExport
modelica_metatype omc_FNode_target(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_metatype _outRef = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = omc_FNode_targetScope(threadData, _inNode);
if (listEmpty(tmpMeta1)) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_CAR(tmpMeta1);
tmpMeta3 = MMC_CDR(tmpMeta1);
_outRef = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _outRef;
}
DLLExport
modelica_metatype omc_FNode_setParents(threadData_t *threadData, modelica_metatype _inNode, modelica_metatype _inParents)
{
modelica_metatype _outNode = NULL;
modelica_string _n = NULL;
modelica_integer _i;
modelica_metatype _p = NULL;
modelica_metatype _c = NULL;
modelica_metatype _d = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_integer tmp4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inNode;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp4 = mmc_unbox_integer(tmpMeta3);
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 5));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 6));
_n = tmpMeta2;
_i = tmp4;
_p = tmpMeta5;
_c = tmpMeta6;
_d = tmpMeta7;
tmpMeta8 = mmc_mk_box6(3, &FCore_Node_N__desc, _n, mmc_mk_integer(_i), _inParents, _c, _d);
_outNode = tmpMeta8;
_return: OMC_LABEL_UNUSED
return _outNode;
}
DLLExport
modelica_metatype omc_FNode_refPushParents(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _inParents)
{
modelica_metatype _outRef = NULL;
modelica_string _n = NULL;
modelica_integer _i;
modelica_metatype _p = NULL;
modelica_metatype _c = NULL;
modelica_metatype _d = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_integer tmp4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = omc_FNode_fromRef(threadData, _inRef);
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp4 = mmc_unbox_integer(tmpMeta3);
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 5));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 6));
_n = tmpMeta2;
_i = tmp4;
_p = tmpMeta5;
_c = tmpMeta6;
_d = tmpMeta7;
_p = listAppend(_inParents, _p);
tmpMeta8 = mmc_mk_box6(3, &FCore_Node_N__desc, _n, mmc_mk_integer(_i), _p, _c, _d);
_outRef = omc_FNode_updateRef(threadData, _inRef, tmpMeta8);
_return: OMC_LABEL_UNUSED
return _outRef;
}
DLLExport
modelica_metatype omc_FNode_refParents(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_metatype _p = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = omc_FNode_fromRef(threadData, _inRef);
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
_p = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _p;
}
DLLExport
modelica_boolean omc_FNode_hasParents(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = (!listEmpty(omc_FNode_parents(threadData, _inNode)));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FNode_hasParents(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FNode_hasParents(threadData, _inNode);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_metatype omc_FNode_parents(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_metatype _p = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inNode;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
_p = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _p;
}
DLLExport
modelica_integer omc_FNode_id(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_integer _id;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inNode;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp3 = mmc_unbox_integer(tmpMeta2);
_id = tmp3;
_return: OMC_LABEL_UNUSED
return _id;
}
modelica_metatype boxptr_FNode_id(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_integer _id;
modelica_metatype out_id;
_id = omc_FNode_id(threadData, _inNode);
out_id = mmc_mk_icon(_id);
return out_id;
}
DLLExport
modelica_metatype omc_FNode_updateRef(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _inNode)
{
modelica_metatype _outRef = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outRef = arrayUpdate(_inRef, ((modelica_integer) 1), _inNode);
_return: OMC_LABEL_UNUSED
return _outRef;
}
DLLExport
modelica_metatype omc_FNode_fromRef(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_metatype _outNode = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outNode = arrayGet(_inRef, ((modelica_integer) 1));
_return: OMC_LABEL_UNUSED
return _outNode;
}
DLLExport
modelica_metatype omc_FNode_toRef(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_metatype _outRef = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outRef = arrayCreate(((modelica_integer) 1), _inNode);
_return: OMC_LABEL_UNUSED
return _outRef;
}
