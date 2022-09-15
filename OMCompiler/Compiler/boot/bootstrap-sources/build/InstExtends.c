#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "InstExtends.c"
#endif
#include "omc_simulation_settings.h"
#include "InstExtends.h"
#define _OMC_LIT0_data "failtrace"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,9,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "Sets whether to print a failtrace or not."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,41,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT2,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT1}};
#define _OMC_LIT2 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT0,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT2}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "InstExtends.fixModifications failed: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,37,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,10,3) {&SCodeDump_SCodeDumpOptions_OPTIONS__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,1,3) {&SCode_Encapsulated_ENCAPSULATED__desc,}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "InstExtends.lookupVarNoErrorMessage"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,35,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "InstExtends.fixStatement failed: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,33,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "InstExtends.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,14,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT10_6,0.0);
#define _OMC_LIT10_6 MMC_REFREALLIT(_OMC_LIT_STRUCT10_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT9,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1362)),MMC_IMMEDIATE(MMC_TAGFIXNUM(9)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1363)),MMC_IMMEDIATE(MMC_TAGFIXNUM(94)),_OMC_LIT10_6}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "InstExtends.fixClassDef failed: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,32,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT12,1,4) {&SCode_Encapsulated_NOT__ENCAPSULATED__desc,}};
#define _OMC_LIT12 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "InstExtends.fixElement failed: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,31,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT14,1,5) {&DAE_Mod_NOMOD__desc,}};
#define _OMC_LIT14 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data "- InstExtends.updateComponentsAndClassdefs2 failed on:\nenv = "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,61,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "\nmod = "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,7,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data "\ncmod = "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,8,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
#define _OMC_LIT18_data "\nbool = "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT18,8,_OMC_LIT18_data);
#define _OMC_LIT18 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT18)
#define _OMC_LIT19_data "true"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT19,4,_OMC_LIT19_data);
#define _OMC_LIT19 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data "false"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,5,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
#define _OMC_LIT21_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT21,1,_OMC_LIT21_data);
#define _OMC_LIT21 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT21)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT22,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT22 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT22)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT23,1,5) {&ErrorTypes_Severity_WARNING__desc,}};
#define _OMC_LIT23 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT23)
#define _OMC_LIT24_data "Ignoring external declaration of the extended class: %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT24,56,_OMC_LIT24_data);
#define _OMC_LIT24 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT24)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT25,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT24}};
#define _OMC_LIT25 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT25)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT26,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(160)),_OMC_LIT22,_OMC_LIT23,_OMC_LIT25}};
#define _OMC_LIT26 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,0,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT28,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT28 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data "The maximum recursion depth of was reached when instantiating a derived class. Current class %s in scope %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,108,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT30,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT29}};
#define _OMC_LIT30 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT30)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT31,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(534)),_OMC_LIT22,_OMC_LIT28,_OMC_LIT30}};
#define _OMC_LIT31 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT31)
#define _OMC_LIT32_data "- Inst.instDerivedClasses failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT32,33,_OMC_LIT32_data);
#define _OMC_LIT32 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT32)
#define _OMC_LIT33_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT33,1,_OMC_LIT33_data);
#define _OMC_LIT33 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT33)
#define _OMC_LIT34_data "TODO: Make a proper Error message here - Inst.instClassExtendsList2 couldn't find the class to extend"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT34,101,_OMC_LIT34_data);
#define _OMC_LIT34 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT34)
#define _OMC_LIT35_data "$parent."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT35,8,_OMC_LIT35_data);
#define _OMC_LIT35 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT35)
#define _OMC_LIT36_data ".$env."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT36,6,_OMC_LIT36_data);
#define _OMC_LIT36 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT36)
#define _OMC_LIT37_data "- Inst.instClassExtendsList failed "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT37,35,_OMC_LIT37_data);
#define _OMC_LIT37 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT37)
#define _OMC_LIT38_data "  Candidate classes: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT38,21,_OMC_LIT38_data);
#define _OMC_LIT38 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT38)
#define _OMC_LIT39_data ","
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT39,1,_OMC_LIT39_data);
#define _OMC_LIT39 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT39)
#define _OMC_LIT40_data "Duplicate elements:\n %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT40,24,_OMC_LIT40_data);
#define _OMC_LIT40 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT40)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT41,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT40}};
#define _OMC_LIT41 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT41)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT42,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(7025)),_OMC_LIT22,_OMC_LIT28,_OMC_LIT41}};
#define _OMC_LIT42 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT42)
#define _OMC_LIT43_data "Base class %s not found in scope %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT43,36,_OMC_LIT43_data);
#define _OMC_LIT43 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT43)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT44,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT43}};
#define _OMC_LIT44 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT44)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT45,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(39)),_OMC_LIT22,_OMC_LIT28,_OMC_LIT44}};
#define _OMC_LIT45 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT45)
#define _OMC_LIT46_data "permissive"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT46,10,_OMC_LIT46_data);
#define _OMC_LIT46 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT46)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT47,1,3) {&Flags_FlagVisibility_INTERNAL__desc,}};
#define _OMC_LIT47 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT47)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT48,2,4) {&Flags_FlagData_BOOL__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT48 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT48)
#define _OMC_LIT49_data "Disables some error checks to allow erroneous models to compile."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT49,64,_OMC_LIT49_data);
#define _OMC_LIT49 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT49)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT50,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT49}};
#define _OMC_LIT50 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT50)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT51,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(82)),_OMC_LIT46,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT47,_OMC_LIT48,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT50}};
#define _OMC_LIT51 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT51)
#define _OMC_LIT52_data "- Inst.instExtendsList failed on:\n	className: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT52,46,_OMC_LIT52_data);
#define _OMC_LIT52 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT52)
#define _OMC_LIT53_data "\n	"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT53,2,_OMC_LIT53_data);
#define _OMC_LIT53 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT53)
#define _OMC_LIT54_data "env:       "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT54,11,_OMC_LIT54_data);
#define _OMC_LIT54 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT54)
#define _OMC_LIT55_data "mods:      "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT55,11,_OMC_LIT55_data);
#define _OMC_LIT55 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT55)
#define _OMC_LIT56_data "elem:      "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT56,11,_OMC_LIT56_data);
#define _OMC_LIT56 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT56)
#include "util/modelica.h"
#include "InstExtends_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixTuple2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype __omcQ_24in_5Ftpl, modelica_metatype _tree, modelica_fnptr _fixA, modelica_fnptr _fixB);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixTuple2,2,0) {(void*) boxptr_InstExtends_fixTuple2,0}};
#define boxvar_InstExtends_fixTuple2 MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixTuple2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixListTuple2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inRest, modelica_metatype _tree, modelica_fnptr _fixA, modelica_fnptr _fixB);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixListTuple2,2,0) {(void*) boxptr_InstExtends_fixListTuple2,0}};
#define boxvar_InstExtends_fixListTuple2 MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixListTuple2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixListList(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inA, modelica_metatype _tree, modelica_fnptr _fixA);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixListList,2,0) {(void*) boxptr_InstExtends_fixListList,0}};
#define boxvar_InstExtends_fixListList MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixListList)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixList(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inA, modelica_metatype _tree, modelica_fnptr _fixA);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixList,2,0) {(void*) boxptr_InstExtends_fixList,0}};
#define boxvar_InstExtends_fixList MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixList)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixOption(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inA, modelica_metatype _tree, modelica_fnptr _fixA);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixOption,2,0) {(void*) boxptr_InstExtends_fixOption,0}};
#define boxvar_InstExtends_fixOption MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixOption)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixExpTraverse(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype __omcQ_24in_5Ftpl, modelica_metatype *out_tpl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixExpTraverse,2,0) {(void*) boxptr_InstExtends_fixExpTraverse,0}};
#define boxvar_InstExtends_fixExpTraverse MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixExpTraverse)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixExp(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _inEnv, modelica_metatype _inExp, modelica_metatype _tree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixExp,2,0) {(void*) boxptr_InstExtends_fixExp,0}};
#define boxvar_InstExtends_fixExp MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixSubMod(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype __omcQ_24in_5FsubMod, modelica_metatype _tree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixSubMod,2,0) {(void*) boxptr_InstExtends_fixSubMod,0}};
#define boxvar_InstExtends_fixSubMod MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixSubMod)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixModifications(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inMod, modelica_metatype _tree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixModifications,2,0) {(void*) boxptr_InstExtends_fixModifications,0}};
#define boxvar_InstExtends_fixModifications MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixModifications)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixCref(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _inEnv, modelica_metatype _inCref, modelica_metatype _tree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixCref,2,0) {(void*) boxptr_InstExtends_fixCref,0}};
#define boxvar_InstExtends_fixCref MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixCref)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_lookupVarNoErrorMessage(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_string _ident, modelica_string *out_id);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_lookupVarNoErrorMessage,2,0) {(void*) boxptr_InstExtends_lookupVarNoErrorMessage,0}};
#define boxvar_InstExtends_lookupVarNoErrorMessage MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_lookupVarNoErrorMessage)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixPath(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inPath, modelica_metatype _tree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixPath,2,0) {(void*) boxptr_InstExtends_fixPath,0}};
#define boxvar_InstExtends_fixPath MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixPath)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixTypeSpec(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _inEnv, modelica_metatype _inTs, modelica_metatype _tree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixTypeSpec,2,0) {(void*) boxptr_InstExtends_fixTypeSpec,0}};
#define boxvar_InstExtends_fixTypeSpec MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixTypeSpec)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixSubscript(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _inEnv, modelica_metatype _inSub, modelica_metatype _tree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixSubscript,2,0) {(void*) boxptr_InstExtends_fixSubscript,0}};
#define boxvar_InstExtends_fixSubscript MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixSubscript)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixArrayDim(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype __omcQ_24in_5Fads, modelica_metatype _tree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixArrayDim,2,0) {(void*) boxptr_InstExtends_fixArrayDim,0}};
#define boxvar_InstExtends_fixArrayDim MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixArrayDim)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixStatement(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _inEnv, modelica_metatype _inStmt, modelica_metatype _tree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixStatement,2,0) {(void*) boxptr_InstExtends_fixStatement,0}};
#define boxvar_InstExtends_fixStatement MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixStatement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixListAlgorithmItem(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _alg, modelica_metatype _tree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixListAlgorithmItem,2,0) {(void*) boxptr_InstExtends_fixListAlgorithmItem,0}};
#define boxvar_InstExtends_fixListAlgorithmItem MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixListAlgorithmItem)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixConstraint(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inConstrs, modelica_metatype _tree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixConstraint,2,0) {(void*) boxptr_InstExtends_fixConstraint,0}};
#define boxvar_InstExtends_fixConstraint MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixConstraint)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixAlgorithm(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inAlg, modelica_metatype _tree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixAlgorithm,2,0) {(void*) boxptr_InstExtends_fixAlgorithm,0}};
#define boxvar_InstExtends_fixAlgorithm MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixAlgorithm)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixListEquation(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _eeq, modelica_metatype _tree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixListEquation,2,0) {(void*) boxptr_InstExtends_fixListEquation,0}};
#define boxvar_InstExtends_fixListEquation MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixListEquation)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixEquation(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _inEnv, modelica_metatype _inEeq, modelica_metatype _tree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixEquation,2,0) {(void*) boxptr_InstExtends_fixEquation,0}};
#define boxvar_InstExtends_fixEquation MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixEquation)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixClassdef(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _inEnv, modelica_metatype _inCd, modelica_metatype _inTree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixClassdef,2,0) {(void*) boxptr_InstExtends_fixClassdef,0}};
#define boxvar_InstExtends_fixClassdef MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixClassdef)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixElement(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inElt, modelica_metatype _tree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixElement,2,0) {(void*) boxptr_InstExtends_fixElement,0}};
#define boxvar_InstExtends_fixElement MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixLocalIdent(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype __omcQ_24in_5Felt, modelica_metatype _tree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_fixLocalIdent,2,0) {(void*) boxptr_InstExtends_fixLocalIdent,0}};
#define boxvar_InstExtends_fixLocalIdent MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_fixLocalIdent)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_getLocalIdentElement(threadData_t *threadData, modelica_metatype _elt, modelica_metatype __omcQ_24in_5Ftree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_getLocalIdentElement,2,0) {(void*) boxptr_InstExtends_getLocalIdentElement,0}};
#define boxvar_InstExtends_getLocalIdentElement MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_getLocalIdentElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_getLocalIdentElementTpl(threadData_t *threadData, modelica_metatype _eltTpl, modelica_metatype __omcQ_24in_5Ftree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_getLocalIdentElementTpl,2,0) {(void*) boxptr_InstExtends_getLocalIdentElementTpl,0}};
#define boxvar_InstExtends_getLocalIdentElementTpl MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_getLocalIdentElementTpl)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_getLocalIdentList(threadData_t *threadData, modelica_metatype _ielts, modelica_metatype __omcQ_24in_5Ftree, modelica_fnptr _getIdent);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_getLocalIdentList,2,0) {(void*) boxptr_InstExtends_getLocalIdentList,0}};
#define boxvar_InstExtends_getLocalIdentList MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_getLocalIdentList)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_updateComponentsAndClassdefs2(threadData_t *threadData, modelica_metatype _inComponent, modelica_metatype _inEnv, modelica_metatype _inMod, modelica_metatype *out_outRestMod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_updateComponentsAndClassdefs2,2,0) {(void*) boxptr_InstExtends_updateComponentsAndClassdefs2,0}};
#define boxvar_InstExtends_updateComponentsAndClassdefs2 MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_updateComponentsAndClassdefs2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_updateComponentsAndClassdefs(threadData_t *threadData, modelica_metatype _inComponents, modelica_metatype _inMod, modelica_metatype _inEnv, modelica_metatype *out_outRestMod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_updateComponentsAndClassdefs,2,0) {(void*) boxptr_InstExtends_updateComponentsAndClassdefs,0}};
#define boxvar_InstExtends_updateComponentsAndClassdefs MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_updateComponentsAndClassdefs)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_noImportElements(threadData_t *threadData, modelica_metatype _inElements);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_noImportElements,2,0) {(void*) boxptr_InstExtends_noImportElements,0}};
#define boxvar_InstExtends_noImportElements MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_noImportElements)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_instDerivedClassesWork(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inClass, modelica_boolean _inBoolean, modelica_metatype _inInfo, modelica_boolean _overflow, modelica_integer _numIter, modelica_metatype *out_outEnv1, modelica_metatype *out_outIH, modelica_metatype *out_outSCodeElementLst2, modelica_metatype *out_outSCodeEquationLst3, modelica_metatype *out_outSCodeEquationLst4, modelica_metatype *out_outSCodeAlgorithmLst5, modelica_metatype *out_outSCodeAlgorithmLst6, modelica_metatype *out_outMod, modelica_metatype *out_outComments);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstExtends_instDerivedClassesWork(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inClass, modelica_metatype _inBoolean, modelica_metatype _inInfo, modelica_metatype _overflow, modelica_metatype _numIter, modelica_metatype *out_outEnv1, modelica_metatype *out_outIH, modelica_metatype *out_outSCodeElementLst2, modelica_metatype *out_outSCodeEquationLst3, modelica_metatype *out_outSCodeEquationLst4, modelica_metatype *out_outSCodeAlgorithmLst5, modelica_metatype *out_outSCodeAlgorithmLst6, modelica_metatype *out_outMod, modelica_metatype *out_outComments);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_instDerivedClassesWork,2,0) {(void*) boxptr_InstExtends_instDerivedClassesWork,0}};
#define boxvar_InstExtends_instDerivedClassesWork MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_instDerivedClassesWork)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_instClassExtendsList2(threadData_t *threadData, modelica_metatype _inEnv, modelica_metatype _inMod, modelica_string _inName, modelica_metatype _inClassExtendsElt, modelica_metatype _inElements, modelica_metatype *out_outElements);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_instClassExtendsList2,2,0) {(void*) boxptr_InstExtends_instClassExtendsList2,0}};
#define boxvar_InstExtends_instClassExtendsList2 MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_instClassExtendsList2)
PROTECTED_FUNCTION_STATIC modelica_string omc_InstExtends_buildClassExtendsName(threadData_t *threadData, modelica_string _inEnvPath, modelica_string _inClassName);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_buildClassExtendsName,2,0) {(void*) boxptr_InstExtends_buildClassExtendsName,0}};
#define boxvar_InstExtends_buildClassExtendsName MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_buildClassExtendsName)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_instClassExtendsList(threadData_t *threadData, modelica_metatype _inEnv, modelica_metatype _inMod, modelica_metatype _inClassExtendsList, modelica_metatype _inElements, modelica_metatype *out_outElements);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_instClassExtendsList,2,0) {(void*) boxptr_InstExtends_instClassExtendsList,0}};
#define boxvar_InstExtends_instClassExtendsList MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_instClassExtendsList)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_instExtendsAndClassExtendsList2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inExtendsElementLst, modelica_metatype _inClassExtendsElementLst, modelica_metatype _inElementsFromExtendsScope, modelica_metatype _inState, modelica_string _inClassName, modelica_boolean _inImpl, modelica_boolean _isPartialInst, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outMod, modelica_metatype *out_outElements, modelica_metatype *out_outNormalEqs, modelica_metatype *out_outInitialEqs, modelica_metatype *out_outNormalAlgs, modelica_metatype *out_outInitialAlgs, modelica_metatype *out_comments);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstExtends_instExtendsAndClassExtendsList2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inExtendsElementLst, modelica_metatype _inClassExtendsElementLst, modelica_metatype _inElementsFromExtendsScope, modelica_metatype _inState, modelica_metatype _inClassName, modelica_metatype _inImpl, modelica_metatype _isPartialInst, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outMod, modelica_metatype *out_outElements, modelica_metatype *out_outNormalEqs, modelica_metatype *out_outInitialEqs, modelica_metatype *out_outNormalAlgs, modelica_metatype *out_outInitialAlgs, modelica_metatype *out_comments);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_instExtendsAndClassExtendsList2,2,0) {(void*) boxptr_InstExtends_instExtendsAndClassExtendsList2,0}};
#define boxvar_InstExtends_instExtendsAndClassExtendsList2 MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_instExtendsAndClassExtendsList2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_updateElementListVisibility(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _inVisibility);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_updateElementListVisibility,2,0) {(void*) boxptr_InstExtends_updateElementListVisibility,0}};
#define boxvar_InstExtends_updateElementListVisibility MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_updateElementListVisibility)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_lookupBaseClass(threadData_t *threadData, modelica_metatype _inPath, modelica_boolean _inSelfReference, modelica_string _inClassName, modelica_metatype _inEnv, modelica_metatype _inCache, modelica_metatype *out_outElement, modelica_metatype *out_outEnv);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstExtends_lookupBaseClass(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inSelfReference, modelica_metatype _inClassName, modelica_metatype _inEnv, modelica_metatype _inCache, modelica_metatype *out_outElement, modelica_metatype *out_outEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_lookupBaseClass,2,0) {(void*) boxptr_InstExtends_lookupBaseClass,0}};
#define boxvar_InstExtends_lookupBaseClass MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_lookupBaseClass)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_instExtendsList(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inLocalElements, modelica_metatype _inElementsFromExtendsScope, modelica_metatype _inState, modelica_string _inClassName, modelica_boolean _inImpl, modelica_boolean _inPartialInst, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outMod, modelica_metatype *out_outElements, modelica_metatype *out_outNormalEqs, modelica_metatype *out_outInitialEqs, modelica_metatype *out_outNormalAlgs, modelica_metatype *out_outInitialAlgs, modelica_metatype *out_outComments);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstExtends_instExtendsList(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inLocalElements, modelica_metatype _inElementsFromExtendsScope, modelica_metatype _inState, modelica_metatype _inClassName, modelica_metatype _inImpl, modelica_metatype _inPartialInst, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outMod, modelica_metatype *out_outElements, modelica_metatype *out_outNormalEqs, modelica_metatype *out_outInitialEqs, modelica_metatype *out_outNormalAlgs, modelica_metatype *out_outInitialAlgs, modelica_metatype *out_outComments);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstExtends_instExtendsList,2,0) {(void*) boxptr_InstExtends_instExtendsList,0}};
#define boxvar_InstExtends_instExtendsList MMC_REFSTRUCTLIT(boxvar_lit_InstExtends_instExtendsList)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixTuple2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype __omcQ_24in_5Ftpl, modelica_metatype _tree, modelica_fnptr _fixA, modelica_fnptr _fixB)
{
modelica_metatype _tpl = NULL;
modelica_metatype _a1 = NULL;
modelica_metatype _a2 = NULL;
modelica_metatype _b1 = NULL;
modelica_metatype _b2 = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_tpl = __omcQ_24in_5Ftpl;
tmpMeta1 = _tpl;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_a1 = tmpMeta2;
_b1 = tmpMeta3;
_a2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fixA), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fixA), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fixA), 2))), _inCache, _inEnv, _a1, _tree) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fixA), 1)))) (threadData, _inCache, _inEnv, _a1, _tree);
_b2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fixB), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fixB), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fixB), 2))), _inCache, _inEnv, _b1, _tree) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fixB), 1)))) (threadData, _inCache, _inEnv, _b1, _tree);
if((!(referenceEq(_a1, _a2) && referenceEq(_b1, _b2))))
{
tmpMeta4 = mmc_mk_box2(0, _a2, _b2);
_tpl = tmpMeta4;
}
_return: OMC_LABEL_UNUSED
return _tpl;
}
static modelica_metatype closure0_InstExtends_fixTuple2(threadData_t *thData, modelica_metatype closure, modelica_metatype inCache, modelica_metatype inEnv, modelica_metatype $in_tpl, modelica_metatype tree)
{
modelica_fnptr fixA = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_fnptr fixB = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_InstExtends_fixTuple2(thData, inCache, inEnv, $in_tpl, tree, fixA, fixB);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixListTuple2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inRest, modelica_metatype _tree, modelica_fnptr _fixA, modelica_fnptr _fixB)
{
modelica_metatype _outA = NULL;
modelica_metatype _a1 = NULL;
modelica_metatype _a2 = NULL;
modelica_metatype _b1 = NULL;
modelica_metatype _b2 = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box2(0, ((modelica_fnptr) _fixA), ((modelica_fnptr) _fixB));
_outA = omc_InstExtends_fixList(threadData, _inCache, _inEnv, _inRest, _tree, (modelica_fnptr) mmc_mk_box2(0,closure0_InstExtends_fixTuple2,tmpMeta1));
_return: OMC_LABEL_UNUSED
return _outA;
}
static modelica_metatype closure1_InstExtends_fixList(threadData_t *thData, modelica_metatype closure, modelica_metatype inA)
{
modelica_metatype inCache = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype inEnv = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
modelica_metatype tree = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),3));
modelica_fnptr fixA = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),4));
return boxptr_InstExtends_fixList(thData, inCache, inEnv, inA, tree, fixA);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixListList(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inA, modelica_metatype _tree, modelica_fnptr _fixA)
{
modelica_metatype _outA = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outA = tmpMeta1;
if(listEmpty(_inA))
{
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
_outA = tmpMeta2;
goto _return;
}
tmpMeta3 = mmc_mk_box4(0, _inCache, _inEnv, _tree, ((modelica_fnptr) _fixA));
_outA = omc_List_mapCheckReferenceEq(threadData, _inA, (modelica_fnptr) mmc_mk_box2(0,closure1_InstExtends_fixList,tmpMeta3));
_return: OMC_LABEL_UNUSED
return _outA;
}
static modelica_metatype closure2_fixA(threadData_t *thData, modelica_metatype closure, modelica_metatype inA)
{
modelica_metatype inCache = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype inEnv = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
modelica_metatype tree = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),3));
modelica_fnptr _fixA = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),4));
if (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fixA),2))) {
return  ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fixA), 1)))) (thData, MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fixA),2)), inCache, inEnv, inA, tree);
} else {
return  ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fixA), 1)))) (thData, inCache, inEnv, inA, tree);
}
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixList(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inA, modelica_metatype _tree, modelica_fnptr _fixA)
{
modelica_metatype _outA = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(listEmpty(_inA))
{
_outA = _inA;
goto _return;
}
tmpMeta1 = mmc_mk_box4(0, _inCache, _inEnv, _tree, _fixA);
_outA = omc_List_mapCheckReferenceEq(threadData, _inA, (modelica_fnptr) mmc_mk_box2(0,closure2_fixA,tmpMeta1));
_return: OMC_LABEL_UNUSED
return _outA;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixOption(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inA, modelica_metatype _tree, modelica_fnptr _fixA)
{
modelica_metatype _outA = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inA;
{
modelica_metatype _A1 = NULL;
modelica_metatype _A2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
tmpMeta1 = _inA;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_A1 = tmpMeta6;
_A2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fixA), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fixA), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fixA), 2))), _inCache, _inEnv, _A1, _tree) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fixA), 1)))) (threadData, _inCache, _inEnv, _A1, _tree);
tmpMeta1 = (referenceEq(_A1, _A2)?_inA:mmc_mk_some(_A2));
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
_outA = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outA;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixExpTraverse(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype __omcQ_24in_5Ftpl, modelica_metatype *out_tpl)
{
modelica_metatype _exp = NULL;
modelica_metatype _tpl = NULL;
modelica_metatype _inExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_exp = __omcQ_24in_5Fexp;
_tpl = __omcQ_24in_5Ftpl;
_inExp = _exp;
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _exp;
tmp4_2 = _tpl;
{
modelica_metatype _fargs = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _cref1 = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _tree = NULL;
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
modelica_boolean tmp11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_cref = tmpMeta6;
_cache = tmpMeta7;
_env = tmpMeta8;
_tree = tmpMeta9;
_cref1 = omc_InstExtends_fixCref(threadData, _cache, _env, _cref, _tree);
tmp11 = (modelica_boolean)referenceEq(_cref, _cref1);
if(tmp11)
{
tmpMeta12 = _exp;
}
else
{
tmpMeta10 = mmc_mk_box2(5, &Absyn_Exp_CREF__desc, _cref1);
tmpMeta12 = tmpMeta10;
}
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_boolean tmp18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,3) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_cref = tmpMeta13;
_cache = tmpMeta14;
_env = tmpMeta15;
_tree = tmpMeta16;
_cref1 = omc_InstExtends_fixCref(threadData, _cache, _env, _cref, _tree);
tmp18 = (modelica_boolean)referenceEq(_cref, _cref1);
if(tmp18)
{
tmpMeta19 = _exp;
}
else
{
tmpMeta17 = mmc_mk_box4(14, &Absyn_Exp_CALL__desc, _cref1, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 4))));
tmpMeta19 = tmpMeta17;
}
tmpMeta1 = tmpMeta19;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_boolean tmp26;
modelica_metatype tmpMeta27;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,2) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_cref = tmpMeta20;
_fargs = tmpMeta21;
_cache = tmpMeta22;
_env = tmpMeta23;
_tree = tmpMeta24;
_cref1 = omc_InstExtends_fixCref(threadData, _cache, _env, _cref, _tree);
tmp26 = (modelica_boolean)referenceEq(_cref, _cref1);
if(tmp26)
{
tmpMeta27 = _exp;
}
else
{
tmpMeta25 = mmc_mk_box3(15, &Absyn_Exp_PARTEVALFUNCTION__desc, _cref1, _fargs);
tmpMeta27 = tmpMeta25;
}
tmpMeta1 = tmpMeta27;
goto tmp3_done;
}
case 3: {
tmpMeta1 = _exp;
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
_exp = tmpMeta1;
_return: OMC_LABEL_UNUSED
if (out_tpl) { *out_tpl = _tpl; }
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixExp(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _inEnv, modelica_metatype _inExp, modelica_metatype _tree)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box3(0, _cache, _inEnv, _tree);
_outExp = omc_AbsynUtil_traverseExp(threadData, _inExp, boxvar_InstExtends_fixExpTraverse, tmpMeta1, NULL);
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixSubMod(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype __omcQ_24in_5FsubMod, modelica_metatype _tree)
{
modelica_metatype _subMod = NULL;
modelica_string _ident = NULL;
modelica_metatype _mod1 = NULL;
modelica_metatype _mod2 = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_subMod = __omcQ_24in_5FsubMod;
tmpMeta1 = _subMod;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_ident = tmpMeta2;
_mod1 = tmpMeta3;
_mod2 = omc_InstExtends_fixModifications(threadData, _inCache, _inEnv, _mod1, _tree);
if((!referenceEq(_mod1, _mod2)))
{
tmpMeta4 = mmc_mk_box3(3, &SCode_SubMod_NAMEMOD__desc, _ident, _mod2);
_subMod = tmpMeta4;
}
_return: OMC_LABEL_UNUSED
return _subMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixModifications(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inMod, modelica_metatype _tree)
{
modelica_metatype _outMod = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outMod = _inMod;
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _outMod;
{
modelica_metatype _subModLst = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _e = NULL;
modelica_metatype _cdef = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,0) == 0) goto tmp3_end;
tmp4 += 3;
tmpMeta1 = _inMod;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
tmp4 += 2;
_subModLst = omc_InstExtends_fixList(threadData, _inCache, _inEnv, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outMod), 4))), _tree, boxvar_InstExtends_fixSubMod);
if((!referenceEq((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outMod), 4))), _subModLst)))
{
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_outMod), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[4] = _subModLst;
_outMod = tmpMeta6;
}
_exp = omc_InstExtends_fixOption(threadData, _inCache, _inEnv, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outMod), 5))), _tree, boxvar_InstExtends_fixExp);
if((!referenceEq(_exp, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outMod), 5))))))
{
tmpMeta7 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta7), MMC_UNTAGPTR(_outMod), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta7))[5] = _exp;
_outMod = tmpMeta7;
}
tmpMeta1 = _outMod;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,3,8) == 0) goto tmp3_end;
tmp4 += 1;
_e = omc_InstExtends_fixElement(threadData, _inCache, _inEnv, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outMod), 4))), _tree);
if((!referenceEq(_e, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outMod), 4))))))
{
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_outMod), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[4] = _e;
_outMod = tmpMeta9;
}
tmpMeta1 = _outMod;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,2,8) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 7));
_e = tmpMeta10;
_cdef = tmpMeta11;
_cdef = omc_InstExtends_fixClassdef(threadData, _inCache, _inEnv, _cdef, _tree);
if((!referenceEq(_cdef, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 7))))))
{
tmpMeta12 = MMC_TAGPTR(mmc_alloc_words(10));
memcpy(MMC_UNTAGPTR(tmpMeta12), MMC_UNTAGPTR(_e), 10*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta12))[7] = _cdef;
_e = tmpMeta12;
tmpMeta13 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta13), MMC_UNTAGPTR(_outMod), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta13))[4] = _e;
_outMod = tmpMeta13;
}
tmpMeta1 = _outMod;
goto tmp3_done;
}
case 4: {
modelica_boolean tmp14;
modelica_metatype tmpMeta15;
tmp14 = omc_Flags_isSet(threadData, _OMC_LIT3);
if (1 != tmp14) goto goto_2;
tmpMeta15 = stringAppend(_OMC_LIT4,omc_SCodeDump_printModStr(threadData, _inMod, _OMC_LIT5));
omc_Debug_traceln(threadData, tmpMeta15);
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
_outMod = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixCref(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _inEnv, modelica_metatype _inCref, modelica_metatype _tree)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inEnv;
tmp4_2 = _inCref;
{
modelica_string _id = NULL;
modelica_metatype _env = NULL;
modelica_metatype _denv = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _c = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
_env = tmp4_1;
_env = omc_FGraph_topScope(threadData, _inEnv);
tmpMeta1 = omc_InstExtends_fixCref(threadData, _cache, _env, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 2))), _tree);
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
_env = tmp4_1;
_cref = tmp4_2;
_id = omc_AbsynUtil_crefFirstIdent(threadData, _cref);
tmp6 = omc_AvlSetString_hasKey(threadData, _tree, _id);
if (1 != tmp6) goto goto_2;
_cref = omc_FGraph_crefStripGraphScopePrefix(threadData, _cref, _env, 0);
tmpMeta1 = (omc_AbsynUtil_crefEqual(threadData, _cref, _inCref)?_inCref:_cref);
goto tmp3_done;
}
case 2: {
_env = tmp4_1;
_cref = tmp4_2;
_id = omc_AbsynUtil_crefFirstIdent(threadData, _cref);
_denv = omc_InstExtends_lookupVarNoErrorMessage(threadData, arrayGet(_cache, ((modelica_integer) 1)), _env, _id ,&_id);
_denv = omc_FGraph_openScope(threadData, _denv, _OMC_LIT6, _id, mmc_mk_none());
_cref = omc_AbsynUtil_crefReplaceFirstIdent(threadData, _cref, omc_FGraph_getGraphName(threadData, _denv));
_cref = omc_FGraph_crefStripGraphScopePrefix(threadData, _cref, _env, 0);
tmpMeta1 = (omc_AbsynUtil_crefEqual(threadData, _cref, _inCref)?_inCref:_cref);
goto tmp3_done;
}
case 3: {
_env = tmp4_1;
_cref = tmp4_2;
_id = omc_AbsynUtil_crefFirstIdent(threadData, _cref);
omc_Lookup_lookupClassIdent(threadData, arrayGet(_cache, ((modelica_integer) 1)), _env, _id, mmc_mk_none() ,&_c ,&_denv);
_id = omc_SCodeUtil_getElementName(threadData, _c);
_denv = omc_FGraph_openScope(threadData, _denv, _OMC_LIT6, _id, mmc_mk_none());
_cref = omc_AbsynUtil_crefReplaceFirstIdent(threadData, _cref, omc_FGraph_getGraphName(threadData, _denv));
_cref = omc_FGraph_crefStripGraphScopePrefix(threadData, _cref, _env, 0);
tmpMeta1 = (omc_AbsynUtil_crefEqual(threadData, _cref, _inCref)?_inCref:_cref);
goto tmp3_done;
}
case 4: {
tmpMeta1 = _inCref;
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
_outCref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCref;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_lookupVarNoErrorMessage(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_string _ident, modelica_string *out_id)
{
modelica_metatype _outEnv = NULL;
modelica_string _id = NULL;
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
modelica_metatype tmpMeta5;
omc_ErrorExt_setCheckpoint(threadData, _OMC_LIT7);
tmpMeta5 = MMC_REFSTRUCTLIT(mmc_nil);
omc_Lookup_lookupVarIdent(threadData, _inCache, _inEnv, _ident, tmpMeta5 ,NULL ,NULL ,NULL ,NULL ,NULL ,&_outEnv ,NULL ,&_id);
omc_ErrorExt_rollBack(threadData, _OMC_LIT7);
goto tmp2_done;
}
case 1: {
omc_ErrorExt_rollBack(threadData, _OMC_LIT7);
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
if (out_id) { *out_id = _id; }
return _outEnv;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixPath(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inPath, modelica_metatype _tree)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inPath;
{
modelica_string _id = NULL;
modelica_metatype _path = NULL;
modelica_metatype _cache = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta1 = _inPath;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
_id = omc_AbsynUtil_pathFirstIdent(threadData, _inPath);
tmp6 = omc_AvlSetString_hasKey(threadData, _tree, _id);
if (1 != tmp6) goto goto_2;
tmpMeta1 = omc_FGraph_pathStripGraphScopePrefix(threadData, _inPath, _inEnv, 0);
goto tmp3_done;
}
case 2: {
omc_Lookup_lookupClassLocal(threadData, _inEnv, omc_AbsynUtil_pathFirstIdent(threadData, _inPath), NULL);
tmpMeta1 = omc_FGraph_pathStripGraphScopePrefix(threadData, _inPath, _inEnv, 0);
goto tmp3_done;
}
case 3: {
_cache = omc_Inst_makeFullyQualified(threadData, arrayGet(_inCache, ((modelica_integer) 1)), _inEnv, _inPath ,&_path);
_path = omc_FGraph_pathStripGraphScopePrefix(threadData, _path, _inEnv, 0);
arrayUpdate(_inCache, ((modelica_integer) 1), _cache);
tmpMeta1 = _path;
goto tmp3_done;
}
case 4: {
tmpMeta1 = omc_FGraph_pathStripGraphScopePrefix(threadData, _inPath, _inEnv, 0);
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
_outPath = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outPath;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixTypeSpec(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _inEnv, modelica_metatype _inTs, modelica_metatype _tree)
{
modelica_metatype _outTs = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inTs;
{
modelica_metatype _path1 = NULL;
modelica_metatype _path2 = NULL;
modelica_metatype _arrayDim1 = NULL;
modelica_metatype _arrayDim2 = NULL;
modelica_metatype _typeSpecs1 = NULL;
modelica_metatype _typeSpecs2 = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_path1 = tmpMeta6;
_arrayDim1 = tmpMeta7;
_arrayDim2 = omc_InstExtends_fixOption(threadData, _cache, _inEnv, _arrayDim1, _tree, boxvar_InstExtends_fixArrayDim);
_path2 = omc_InstExtends_fixPath(threadData, _cache, _inEnv, _path1, _tree);
tmp9 = (modelica_boolean)(referenceEq(_arrayDim2, _arrayDim1) && referenceEq(_path1, _path2));
if(tmp9)
{
tmpMeta10 = _inTs;
}
else
{
tmpMeta8 = mmc_mk_box3(3, &Absyn_TypeSpec_TPATH__desc, _path2, _arrayDim2);
tmpMeta10 = tmpMeta8;
}
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_boolean tmp15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_path1 = tmpMeta11;
_typeSpecs1 = tmpMeta12;
_arrayDim1 = tmpMeta13;
_arrayDim2 = omc_InstExtends_fixOption(threadData, _cache, _inEnv, _arrayDim1, _tree, boxvar_InstExtends_fixArrayDim);
_path2 = omc_InstExtends_fixPath(threadData, _cache, _inEnv, _path1, _tree);
_typeSpecs2 = omc_InstExtends_fixList(threadData, _cache, _inEnv, _typeSpecs1, _tree, boxvar_InstExtends_fixTypeSpec);
tmp15 = (modelica_boolean)((referenceEq(_arrayDim2, _arrayDim1) && referenceEq(_path1, _path2)) && referenceEq(_typeSpecs1, _typeSpecs2));
if(tmp15)
{
tmpMeta16 = _inTs;
}
else
{
tmpMeta14 = mmc_mk_box4(4, &Absyn_TypeSpec_TCOMPLEX__desc, _path2, _typeSpecs2, _arrayDim2);
tmpMeta16 = tmpMeta14;
}
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
_outTs = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outTs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixSubscript(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _inEnv, modelica_metatype _inSub, modelica_metatype _tree)
{
modelica_metatype _outSub = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inSub;
{
modelica_metatype _exp1 = NULL;
modelica_metatype _exp2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmpMeta1 = _inSub;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_boolean tmp8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_exp1 = tmpMeta6;
_exp2 = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp1, _tree);
tmp8 = (modelica_boolean)referenceEq(_exp1, _exp2);
if(tmp8)
{
tmpMeta9 = _inSub;
}
else
{
tmpMeta7 = mmc_mk_box2(4, &Absyn_Subscript_SUBSCRIPT__desc, _exp2);
tmpMeta9 = tmpMeta7;
}
tmpMeta1 = tmpMeta9;
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
_outSub = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outSub;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixArrayDim(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype __omcQ_24in_5Fads, modelica_metatype _tree)
{
modelica_metatype _ads = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ads = __omcQ_24in_5Fads;
_ads = omc_InstExtends_fixList(threadData, _inCache, _inEnv, _ads, _tree, boxvar_InstExtends_fixSubscript);
_return: OMC_LABEL_UNUSED
return _ads;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixStatement(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _inEnv, modelica_metatype _inStmt, modelica_metatype _tree)
{
modelica_metatype _outStmt = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inStmt;
{
modelica_metatype _exp = NULL;
modelica_metatype _exp_1 = NULL;
modelica_metatype _exp1 = NULL;
modelica_metatype _exp2 = NULL;
modelica_metatype _exp1_1 = NULL;
modelica_metatype _exp2_1 = NULL;
modelica_metatype _optExp1 = NULL;
modelica_metatype _optExp2 = NULL;
modelica_string _iter = NULL;
modelica_metatype _elseifbranch1 = NULL;
modelica_metatype _elseifbranch2 = NULL;
modelica_metatype _whenlst = NULL;
modelica_metatype _truebranch1 = NULL;
modelica_metatype _truebranch2 = NULL;
modelica_metatype _elsebranch1 = NULL;
modelica_metatype _elsebranch2 = NULL;
modelica_metatype _body1 = NULL;
modelica_metatype _body2 = NULL;
modelica_metatype _comment = NULL;
modelica_metatype _info = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 16; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_boolean tmp11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_exp1 = tmpMeta6;
_exp2 = tmpMeta7;
_comment = tmpMeta8;
_info = tmpMeta9;
tmp4 += 14;
_exp1_1 = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp1, _tree);
_exp2_1 = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp2, _tree);
tmp11 = (modelica_boolean)(referenceEq(_exp1, _exp1_1) && referenceEq(_exp2, _exp2_1));
if(tmp11)
{
tmpMeta12 = _inStmt;
}
else
{
tmpMeta10 = mmc_mk_box5(3, &SCode_Statement_ALG__ASSIGN__desc, _exp1_1, _exp2_1, _comment, _info);
tmpMeta12 = tmpMeta10;
}
tmpMeta1 = tmpMeta12;
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
modelica_boolean tmp20;
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,6) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
_exp1 = tmpMeta13;
_truebranch1 = tmpMeta14;
_elseifbranch1 = tmpMeta15;
_elsebranch1 = tmpMeta16;
_comment = tmpMeta17;
_info = tmpMeta18;
tmp4 += 13;
_exp2 = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp1, _tree);
_truebranch2 = omc_InstExtends_fixList(threadData, _cache, _inEnv, _truebranch1, _tree, boxvar_InstExtends_fixStatement);
_elseifbranch2 = omc_InstExtends_fixListTuple2(threadData, _cache, _inEnv, _elseifbranch1, _tree, boxvar_InstExtends_fixExp, boxvar_InstExtends_fixListAlgorithmItem);
_elsebranch2 = omc_InstExtends_fixList(threadData, _cache, _inEnv, _elsebranch1, _tree, boxvar_InstExtends_fixStatement);
tmp20 = (modelica_boolean)(((referenceEq(_exp1, _exp2) && referenceEq(_truebranch1, _truebranch2)) && referenceEq(_elseifbranch1, _elseifbranch2)) && referenceEq(_elsebranch1, _elsebranch2));
if(tmp20)
{
tmpMeta21 = _inStmt;
}
else
{
tmpMeta19 = mmc_mk_box7(4, &SCode_Statement_ALG__IF__desc, _exp2, _truebranch2, _elseifbranch2, _elsebranch2, _comment, _info);
tmpMeta21 = tmpMeta19;
}
tmpMeta1 = tmpMeta21;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_boolean tmp28;
modelica_metatype tmpMeta29;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,5) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_iter = tmpMeta22;
_optExp1 = tmpMeta23;
_body1 = tmpMeta24;
_comment = tmpMeta25;
_info = tmpMeta26;
tmp4 += 12;
_optExp2 = omc_InstExtends_fixOption(threadData, _cache, _inEnv, _optExp1, _tree, boxvar_InstExtends_fixExp);
_body2 = omc_InstExtends_fixList(threadData, _cache, _inEnv, _body1, _tree, boxvar_InstExtends_fixStatement);
tmp28 = (modelica_boolean)(referenceEq(_optExp1, _optExp2) && referenceEq(_body1, _body2));
if(tmp28)
{
tmpMeta29 = _inStmt;
}
else
{
tmpMeta27 = mmc_mk_box6(5, &SCode_Statement_ALG__FOR__desc, _iter, _optExp2, _body2, _comment, _info);
tmpMeta29 = tmpMeta27;
}
tmpMeta1 = tmpMeta29;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_boolean tmp36;
modelica_metatype tmpMeta37;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,5) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_iter = tmpMeta30;
_optExp1 = tmpMeta31;
_body1 = tmpMeta32;
_comment = tmpMeta33;
_info = tmpMeta34;
tmp4 += 11;
_optExp2 = omc_InstExtends_fixOption(threadData, _cache, _inEnv, _optExp1, _tree, boxvar_InstExtends_fixExp);
_body2 = omc_InstExtends_fixList(threadData, _cache, _inEnv, _body1, _tree, boxvar_InstExtends_fixStatement);
tmp36 = (modelica_boolean)(referenceEq(_optExp1, _optExp2) && referenceEq(_body1, _body2));
if(tmp36)
{
tmpMeta37 = _inStmt;
}
else
{
tmpMeta35 = mmc_mk_box6(6, &SCode_Statement_ALG__PARFOR__desc, _iter, _optExp2, _body2, _comment, _info);
tmpMeta37 = tmpMeta35;
}
tmpMeta1 = tmpMeta37;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
modelica_boolean tmp43;
modelica_metatype tmpMeta44;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,4) == 0) goto tmp3_end;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_exp1 = tmpMeta38;
_body1 = tmpMeta39;
_comment = tmpMeta40;
_info = tmpMeta41;
tmp4 += 10;
_exp2 = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp1, _tree);
_body2 = omc_InstExtends_fixList(threadData, _cache, _inEnv, _body1, _tree, boxvar_InstExtends_fixStatement);
tmp43 = (modelica_boolean)(referenceEq(_exp1, _exp2) && referenceEq(_body1, _body2));
if(tmp43)
{
tmpMeta44 = _inStmt;
}
else
{
tmpMeta42 = mmc_mk_box5(7, &SCode_Statement_ALG__WHILE__desc, _exp2, _body2, _comment, _info);
tmpMeta44 = tmpMeta42;
}
tmpMeta1 = tmpMeta44;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,3) == 0) goto tmp3_end;
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_whenlst = tmpMeta45;
_comment = tmpMeta46;
_info = tmpMeta47;
tmp4 += 9;
_whenlst = omc_InstExtends_fixListTuple2(threadData, _cache, _inEnv, _whenlst, _tree, boxvar_InstExtends_fixExp, boxvar_InstExtends_fixListAlgorithmItem);
tmpMeta48 = mmc_mk_box4(8, &SCode_Statement_ALG__WHEN__A__desc, _whenlst, _comment, _info);
tmpMeta1 = tmpMeta48;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_boolean tmp55;
modelica_metatype tmpMeta56;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,5) == 0) goto tmp3_end;
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_exp = tmpMeta49;
_exp1 = tmpMeta50;
_exp2 = tmpMeta51;
_comment = tmpMeta52;
_info = tmpMeta53;
tmp4 += 8;
_exp_1 = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp, _tree);
_exp1_1 = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp1, _tree);
_exp2_1 = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp2, _tree);
tmp55 = (modelica_boolean)((referenceEq(_exp, _exp_1) && referenceEq(_exp1, _exp1_1)) && referenceEq(_exp2, _exp2_1));
if(tmp55)
{
tmpMeta56 = _inStmt;
}
else
{
tmpMeta54 = mmc_mk_box6(9, &SCode_Statement_ALG__ASSERT__desc, _exp_1, _exp1_1, _exp2_1, _comment, _info);
tmpMeta56 = tmpMeta54;
}
tmpMeta1 = tmpMeta56;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta57;
modelica_metatype tmpMeta58;
modelica_metatype tmpMeta59;
modelica_metatype tmpMeta60;
modelica_boolean tmp61;
modelica_metatype tmpMeta62;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta58 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta59 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_exp1 = tmpMeta57;
_comment = tmpMeta58;
_info = tmpMeta59;
tmp4 += 7;
_exp2 = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp1, _tree);
tmp61 = (modelica_boolean)referenceEq(_exp1, _exp2);
if(tmp61)
{
tmpMeta62 = _inStmt;
}
else
{
tmpMeta60 = mmc_mk_box4(10, &SCode_Statement_ALG__TERMINATE__desc, _exp2, _comment, _info);
tmpMeta62 = tmpMeta60;
}
tmpMeta1 = tmpMeta62;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta63;
modelica_metatype tmpMeta64;
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
modelica_metatype tmpMeta67;
modelica_boolean tmp68;
modelica_metatype tmpMeta69;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,4) == 0) goto tmp3_end;
tmpMeta63 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta64 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta66 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_exp1 = tmpMeta63;
_exp2 = tmpMeta64;
_comment = tmpMeta65;
_info = tmpMeta66;
tmp4 += 6;
_exp1_1 = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp1, _tree);
_exp2_1 = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp2, _tree);
tmp68 = (modelica_boolean)(referenceEq(_exp1, _exp1_1) && referenceEq(_exp2, _exp2_1));
if(tmp68)
{
tmpMeta69 = _inStmt;
}
else
{
tmpMeta67 = mmc_mk_box5(11, &SCode_Statement_ALG__REINIT__desc, _exp1_1, _exp2_1, _comment, _info);
tmpMeta69 = tmpMeta67;
}
tmpMeta1 = tmpMeta69;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta70;
modelica_metatype tmpMeta71;
modelica_metatype tmpMeta72;
modelica_metatype tmpMeta73;
modelica_boolean tmp74;
modelica_metatype tmpMeta75;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta70 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta71 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta72 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_exp1 = tmpMeta70;
_comment = tmpMeta71;
_info = tmpMeta72;
tmp4 += 5;
_exp2 = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp1, _tree);
tmp74 = (modelica_boolean)referenceEq(_exp1, _exp2);
if(tmp74)
{
tmpMeta75 = _inStmt;
}
else
{
tmpMeta73 = mmc_mk_box4(12, &SCode_Statement_ALG__NORETCALL__desc, _exp2, _comment, _info);
tmpMeta75 = tmpMeta73;
}
tmpMeta1 = tmpMeta75;
goto tmp3_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,2) == 0) goto tmp3_end;
tmp4 += 4;
tmpMeta1 = _inStmt;
goto tmp3_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,2) == 0) goto tmp3_end;
tmp4 += 3;
tmpMeta1 = _inStmt;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta76;
modelica_metatype tmpMeta77;
modelica_metatype tmpMeta78;
modelica_metatype tmpMeta79;
modelica_boolean tmp80;
modelica_metatype tmpMeta81;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,3) == 0) goto tmp3_end;
tmpMeta76 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta77 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta78 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_body1 = tmpMeta76;
_comment = tmpMeta77;
_info = tmpMeta78;
tmp4 += 2;
_body2 = omc_InstExtends_fixList(threadData, _cache, _inEnv, _body1, _tree, boxvar_InstExtends_fixStatement);
tmp80 = (modelica_boolean)referenceEq(_body1, _body2);
if(tmp80)
{
tmpMeta81 = _inStmt;
}
else
{
tmpMeta79 = mmc_mk_box4(15, &SCode_Statement_ALG__FAILURE__desc, _body2, _comment, _info);
tmpMeta81 = tmpMeta79;
}
tmpMeta1 = tmpMeta81;
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta82;
modelica_metatype tmpMeta83;
modelica_metatype tmpMeta84;
modelica_metatype tmpMeta85;
modelica_metatype tmpMeta86;
modelica_boolean tmp87;
modelica_metatype tmpMeta88;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,4) == 0) goto tmp3_end;
tmpMeta82 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta83 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta84 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta85 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_truebranch1 = tmpMeta82;
_elsebranch1 = tmpMeta83;
_comment = tmpMeta84;
_info = tmpMeta85;
tmp4 += 1;
_truebranch2 = omc_InstExtends_fixList(threadData, _cache, _inEnv, _truebranch1, _tree, boxvar_InstExtends_fixStatement);
_elsebranch2 = omc_InstExtends_fixList(threadData, _cache, _inEnv, _elsebranch1, _tree, boxvar_InstExtends_fixStatement);
tmp87 = (modelica_boolean)(referenceEq(_truebranch1, _truebranch2) && referenceEq(_elsebranch1, _elsebranch2));
if(tmp87)
{
tmpMeta88 = _inStmt;
}
else
{
tmpMeta86 = mmc_mk_box5(16, &SCode_Statement_ALG__TRY__desc, _truebranch2, _elsebranch2, _comment, _info);
tmpMeta88 = tmpMeta86;
}
tmpMeta1 = tmpMeta88;
goto tmp3_done;
}
case 14: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,14,2) == 0) goto tmp3_end;
tmpMeta1 = _inStmt;
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta89;
tmpMeta89 = stringAppend(_OMC_LIT8,omc_Dump_unparseAlgorithmStr(threadData, omc_SCodeUtil_statementToAlgorithmItem(threadData, _inStmt)));
omc_Error_addInternalError(threadData, tmpMeta89, _OMC_LIT10);
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
if (++tmp4 < 16) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outStmt = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStmt;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixListAlgorithmItem(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _alg, modelica_metatype _tree)
{
modelica_metatype _outAlg = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outAlg = omc_InstExtends_fixList(threadData, _cache, _env, _alg, _tree, boxvar_InstExtends_fixStatement);
_return: OMC_LABEL_UNUSED
return _outAlg;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixConstraint(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inConstrs, modelica_metatype _tree)
{
modelica_metatype _outConstrs = NULL;
modelica_metatype _exps = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inConstrs;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_exps = tmpMeta2;
_exps = omc_InstExtends_fixList(threadData, _inCache, _inEnv, _exps, _tree, boxvar_InstExtends_fixExp);
tmpMeta3 = mmc_mk_box2(3, &SCode_ConstraintSection_CONSTRAINTS__desc, _exps);
_outConstrs = tmpMeta3;
_return: OMC_LABEL_UNUSED
return _outConstrs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixAlgorithm(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inAlg, modelica_metatype _tree)
{
modelica_metatype _outAlg = NULL;
modelica_metatype _stmts1 = NULL;
modelica_metatype _stmts2 = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_boolean tmp4;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inAlg;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_stmts1 = tmpMeta2;
_stmts2 = omc_InstExtends_fixList(threadData, _inCache, _inEnv, _stmts1, _tree, boxvar_InstExtends_fixStatement);
tmp4 = (modelica_boolean)referenceEq(_stmts1, _stmts2);
if(tmp4)
{
tmpMeta5 = _inAlg;
}
else
{
tmpMeta3 = mmc_mk_box2(3, &SCode_AlgorithmSection_ALGORITHM__desc, _stmts2);
tmpMeta5 = tmpMeta3;
}
_outAlg = tmpMeta5;
_return: OMC_LABEL_UNUSED
return _outAlg;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixListEquation(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _eeq, modelica_metatype _tree)
{
modelica_metatype _outEeq = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outEeq = omc_InstExtends_fixList(threadData, _cache, _env, _eeq, _tree, boxvar_InstExtends_fixEquation);
_return: OMC_LABEL_UNUSED
return _outEeq;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixEquation(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _inEnv, modelica_metatype _inEeq, modelica_metatype _tree)
{
modelica_metatype _outEeq = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inEeq;
{
modelica_string _id = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _cref1 = NULL;
modelica_metatype _cref2 = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _exp1 = NULL;
modelica_metatype _exp2 = NULL;
modelica_metatype _exp3 = NULL;
modelica_metatype _expl = NULL;
modelica_metatype _eql = NULL;
modelica_metatype _eqll = NULL;
modelica_metatype _whenlst = NULL;
modelica_metatype _comment = NULL;
modelica_metatype _optExp = NULL;
modelica_metatype _info = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_expl = tmpMeta5;
_eqll = tmpMeta6;
_eql = tmpMeta7;
_comment = tmpMeta8;
_info = tmpMeta9;
_expl = omc_InstExtends_fixList(threadData, _cache, _inEnv, _expl, _tree, boxvar_InstExtends_fixExp);
_eqll = omc_InstExtends_fixListList(threadData, _cache, _inEnv, _eqll, _tree, boxvar_InstExtends_fixEquation);
_eql = omc_InstExtends_fixList(threadData, _cache, _inEnv, _eql, _tree, boxvar_InstExtends_fixEquation);
tmpMeta10 = mmc_mk_box6(3, &SCode_Equation_EQ__IF__desc, _expl, _eqll, _eql, _comment, _info);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,4) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_exp1 = tmpMeta11;
_exp2 = tmpMeta12;
_comment = tmpMeta13;
_info = tmpMeta14;
_exp1 = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp1, _tree);
_exp2 = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp2, _tree);
tmpMeta15 = mmc_mk_box5(4, &SCode_Equation_EQ__EQUALS__desc, _exp1, _exp2, _comment, _info);
tmpMeta1 = tmpMeta15;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,5) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_exp1 = tmpMeta16;
_exp2 = tmpMeta17;
_cref = tmpMeta18;
_comment = tmpMeta19;
_info = tmpMeta20;
_exp1 = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp1, _tree);
_exp2 = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp2, _tree);
_cref = omc_InstExtends_fixCref(threadData, _cache, _inEnv, _cref, _tree);
tmpMeta21 = mmc_mk_box6(5, &SCode_Equation_EQ__PDE__desc, _exp1, _exp2, _cref, _comment, _info);
tmpMeta1 = tmpMeta21;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,4) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_cref1 = tmpMeta22;
_cref2 = tmpMeta23;
_comment = tmpMeta24;
_info = tmpMeta25;
_cref1 = omc_InstExtends_fixCref(threadData, _cache, _inEnv, _cref1, _tree);
_cref2 = omc_InstExtends_fixCref(threadData, _cache, _inEnv, _cref2, _tree);
tmpMeta26 = mmc_mk_box5(6, &SCode_Equation_EQ__CONNECT__desc, _cref1, _cref2, _comment, _info);
tmpMeta1 = tmpMeta26;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,5) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_id = tmpMeta27;
_optExp = tmpMeta28;
_eql = tmpMeta29;
_comment = tmpMeta30;
_info = tmpMeta31;
_optExp = omc_InstExtends_fixOption(threadData, _cache, _inEnv, _optExp, _tree, boxvar_InstExtends_fixExp);
_eql = omc_InstExtends_fixList(threadData, _cache, _inEnv, _eql, _tree, boxvar_InstExtends_fixEquation);
tmpMeta32 = mmc_mk_box6(7, &SCode_Equation_EQ__FOR__desc, _id, _optExp, _eql, _comment, _info);
tmpMeta1 = tmpMeta32;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,5) == 0) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_exp = tmpMeta33;
_eql = tmpMeta34;
_whenlst = tmpMeta35;
_comment = tmpMeta36;
_info = tmpMeta37;
_exp = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp, _tree);
_eql = omc_InstExtends_fixList(threadData, _cache, _inEnv, _eql, _tree, boxvar_InstExtends_fixEquation);
_whenlst = omc_InstExtends_fixListTuple2(threadData, _cache, _inEnv, _whenlst, _tree, boxvar_InstExtends_fixExp, boxvar_InstExtends_fixListEquation);
tmpMeta38 = mmc_mk_box6(8, &SCode_Equation_EQ__WHEN__desc, _exp, _eql, _whenlst, _comment, _info);
tmpMeta1 = tmpMeta38;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,5) == 0) goto tmp3_end;
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_exp1 = tmpMeta39;
_exp2 = tmpMeta40;
_exp3 = tmpMeta41;
_comment = tmpMeta42;
_info = tmpMeta43;
_exp1 = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp1, _tree);
_exp2 = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp2, _tree);
_exp3 = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp3, _tree);
tmpMeta44 = mmc_mk_box6(9, &SCode_Equation_EQ__ASSERT__desc, _exp1, _exp2, _exp3, _comment, _info);
tmpMeta1 = tmpMeta44;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_exp = tmpMeta45;
_comment = tmpMeta46;
_info = tmpMeta47;
_exp = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp, _tree);
tmpMeta48 = mmc_mk_box4(10, &SCode_Equation_EQ__TERMINATE__desc, _exp, _comment, _info);
tmpMeta1 = tmpMeta48;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,4) == 0) goto tmp3_end;
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_exp1 = tmpMeta49;
_exp = tmpMeta50;
_comment = tmpMeta51;
_info = tmpMeta52;
_exp1 = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp1, _tree);
_exp = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp, _tree);
tmpMeta53 = mmc_mk_box5(11, &SCode_Equation_EQ__REINIT__desc, _exp1, _exp, _comment, _info);
tmpMeta1 = tmpMeta53;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
modelica_metatype tmpMeta57;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_exp = tmpMeta54;
_comment = tmpMeta55;
_info = tmpMeta56;
_exp = omc_InstExtends_fixExp(threadData, _cache, _inEnv, _exp, _tree);
tmpMeta57 = mmc_mk_box4(12, &SCode_Equation_EQ__NORETCALL__desc, _exp, _comment, _info);
tmpMeta1 = tmpMeta57;
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
_outEeq = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outEeq;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixClassdef(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _inEnv, modelica_metatype _inCd, modelica_metatype _inTree)
{
modelica_metatype _outCd = NULL;
modelica_metatype _tree = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_tree = _inTree;
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inEnv;
tmp4_2 = _inCd;
{
modelica_metatype _elts = NULL;
modelica_metatype _elts_1 = NULL;
modelica_metatype _ne = NULL;
modelica_metatype _ne_1 = NULL;
modelica_metatype _ie = NULL;
modelica_metatype _ie_1 = NULL;
modelica_metatype _na = NULL;
modelica_metatype _na_1 = NULL;
modelica_metatype _ia = NULL;
modelica_metatype _ia_1 = NULL;
modelica_metatype _nc = NULL;
modelica_metatype _nc_1 = NULL;
modelica_metatype _clats = NULL;
modelica_metatype _ed = NULL;
modelica_metatype _ts = NULL;
modelica_metatype _ts_1 = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _mod_1 = NULL;
modelica_metatype _env = NULL;
modelica_metatype _cd = NULL;
modelica_metatype _cd_1 = NULL;
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
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_boolean tmp15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,8) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 6));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 7));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 8));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 9));
_elts = tmpMeta6;
_ne = tmpMeta7;
_ie = tmpMeta8;
_na = tmpMeta9;
_ia = tmpMeta10;
_nc = tmpMeta11;
_clats = tmpMeta12;
_ed = tmpMeta13;
_env = tmp4_1;
tmp4 += 5;
_tree = omc_InstExtends_getLocalIdentList(threadData, _elts, _tree, boxvar_InstExtends_getLocalIdentElement);
_elts_1 = omc_InstExtends_fixList(threadData, _cache, _env, _elts, _tree, boxvar_InstExtends_fixElement);
_ne_1 = omc_InstExtends_fixList(threadData, _cache, _env, _ne, _tree, boxvar_InstExtends_fixEquation);
_ie_1 = omc_InstExtends_fixList(threadData, _cache, _env, _ie, _tree, boxvar_InstExtends_fixEquation);
_na_1 = omc_InstExtends_fixList(threadData, _cache, _env, _na, _tree, boxvar_InstExtends_fixAlgorithm);
_ia_1 = omc_InstExtends_fixList(threadData, _cache, _env, _ia, _tree, boxvar_InstExtends_fixAlgorithm);
_nc_1 = omc_InstExtends_fixList(threadData, _cache, _env, _nc, _tree, boxvar_InstExtends_fixConstraint);
tmp15 = (modelica_boolean)(((((referenceEq(_elts, _elts_1) && referenceEq(_ne, _ne_1)) && referenceEq(_ie, _ie_1)) && referenceEq(_na, _na_1)) && referenceEq(_ia, _ia_1)) && referenceEq(_nc, _nc_1));
if(tmp15)
{
tmpMeta16 = _inCd;
}
else
{
tmpMeta14 = mmc_mk_box9(3, &SCode_ClassDef_PARTS__desc, _elts_1, _ne_1, _ie_1, _na_1, _ia_1, _nc_1, _clats, _ed);
tmpMeta16 = tmpMeta14;
}
tmpMeta1 = tmpMeta16;
goto tmp3_done;
}
case 1: {
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
modelica_boolean tmp28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_boolean tmp31;
modelica_metatype tmpMeta32;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,2) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,0,8) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 3));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 4));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 5));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 6));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 7));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 8));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 9));
_mod = tmpMeta17;
_cd = tmpMeta18;
_elts = tmpMeta19;
_ne = tmpMeta20;
_ie = tmpMeta21;
_na = tmpMeta22;
_ia = tmpMeta23;
_nc = tmpMeta24;
_clats = tmpMeta25;
_ed = tmpMeta26;
_env = tmp4_1;
tmp4 += 4;
_mod_1 = omc_InstExtends_fixModifications(threadData, _cache, _env, _mod, _inTree);
_elts_1 = omc_InstExtends_fixList(threadData, _cache, _env, _elts, _tree, boxvar_InstExtends_fixElement);
_ne_1 = omc_InstExtends_fixList(threadData, _cache, _env, _ne, _tree, boxvar_InstExtends_fixEquation);
_ie_1 = omc_InstExtends_fixList(threadData, _cache, _env, _ie, _tree, boxvar_InstExtends_fixEquation);
_na_1 = omc_InstExtends_fixList(threadData, _cache, _env, _na, _tree, boxvar_InstExtends_fixAlgorithm);
_ia_1 = omc_InstExtends_fixList(threadData, _cache, _env, _ia, _tree, boxvar_InstExtends_fixAlgorithm);
_nc_1 = omc_InstExtends_fixList(threadData, _cache, _env, _nc, _tree, boxvar_InstExtends_fixConstraint);
tmp28 = (modelica_boolean)(((((referenceEq(_elts, _elts_1) && referenceEq(_ne, _ne_1)) && referenceEq(_ie, _ie_1)) && referenceEq(_na, _na_1)) && referenceEq(_ia, _ia_1)) && referenceEq(_nc, _nc_1));
if(tmp28)
{
tmpMeta29 = _cd;
}
else
{
tmpMeta27 = mmc_mk_box9(3, &SCode_ClassDef_PARTS__desc, _elts_1, _ne_1, _ie_1, _na_1, _ia_1, _nc_1, _clats, _ed);
tmpMeta29 = tmpMeta27;
}
_cd_1 = tmpMeta29;
tmp31 = (modelica_boolean)(referenceEq(_cd, _cd_1) && referenceEq(_mod, _mod_1));
if(tmp31)
{
tmpMeta32 = _inCd;
}
else
{
tmpMeta30 = mmc_mk_box3(4, &SCode_ClassDef_CLASS__EXTENDS__desc, _mod_1, _cd_1);
tmpMeta32 = tmpMeta30;
}
tmpMeta1 = tmpMeta32;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_boolean tmp37;
modelica_metatype tmpMeta38;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,3) == 0) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_ts = tmpMeta33;
_mod = tmpMeta34;
_attr = tmpMeta35;
_env = tmp4_1;
tmp4 += 3;
_ts_1 = omc_InstExtends_fixTypeSpec(threadData, _cache, _env, _ts, _tree);
_mod_1 = omc_InstExtends_fixModifications(threadData, _cache, _env, _mod, _tree);
tmp37 = (modelica_boolean)(referenceEq(_ts, _ts_1) && referenceEq(_mod, _mod_1));
if(tmp37)
{
tmpMeta38 = _inCd;
}
else
{
tmpMeta36 = mmc_mk_box4(5, &SCode_ClassDef_DERIVED__desc, _ts_1, _mod_1, _attr);
tmpMeta38 = tmpMeta36;
}
tmpMeta1 = tmpMeta38;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
_cd = tmp4_2;
tmp4 += 2;
tmpMeta1 = _cd;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,1) == 0) goto tmp3_end;
_cd = tmp4_2;
tmp4 += 1;
tmpMeta1 = _cd;
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,2) == 0) goto tmp3_end;
_cd = tmp4_2;
tmpMeta1 = _cd;
goto tmp3_done;
}
case 6: {
modelica_boolean tmp39;
modelica_metatype tmpMeta40;
_cd = tmp4_2;
tmp39 = omc_Flags_isSet(threadData, _OMC_LIT3);
if (1 != tmp39) goto goto_2;
tmpMeta40 = stringAppend(_OMC_LIT11,omc_SCodeDump_classDefStr(threadData, _cd, _OMC_LIT5));
omc_Debug_traceln(threadData, tmpMeta40);
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
_outCd = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCd;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixElement(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inElt, modelica_metatype _tree)
{
modelica_metatype _outElts = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inEnv;
tmp4_2 = _inElt;
{
modelica_string _name = NULL;
modelica_metatype _prefixes = NULL;
modelica_metatype _partialPrefix = NULL;
modelica_metatype _typeSpec1 = NULL;
modelica_metatype _typeSpec2 = NULL;
modelica_metatype _modifications1 = NULL;
modelica_metatype _modifications2 = NULL;
modelica_metatype _comment = NULL;
modelica_metatype _condition = NULL;
modelica_metatype _info = NULL;
modelica_metatype _classDef1 = NULL;
modelica_metatype _classDef2 = NULL;
modelica_metatype _restriction = NULL;
modelica_metatype _optAnnotation = NULL;
modelica_metatype _extendsPath1 = NULL;
modelica_metatype _extendsPath2 = NULL;
modelica_metatype _vis = NULL;
modelica_metatype _ad = NULL;
modelica_metatype _env = NULL;
modelica_metatype _elt = NULL;
modelica_metatype _elt2 = NULL;
modelica_metatype _attr = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,8) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,1) == 0) goto tmp3_end;
_elt = tmp4_2;
_env = tmp4_1;
omc_Lookup_lookupIdentLocal(threadData, arrayGet(_inCache, ((modelica_integer) 1)), _env, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 2))), NULL, &tmpMeta8, NULL, NULL, &tmpMeta17);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,3,8) == 0) goto goto_2;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 5));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 6));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 7));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 8));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 9));
_elt2 = tmpMeta8;
_name = tmpMeta9;
_prefixes = tmpMeta10;
_attr = tmpMeta11;
_typeSpec1 = tmpMeta12;
_modifications1 = tmpMeta13;
_comment = tmpMeta14;
_condition = tmpMeta15;
_info = tmpMeta16;
_env = tmpMeta17;
_modifications2 = omc_InstExtends_fixModifications(threadData, _inCache, _env, _modifications1, _tree);
_typeSpec2 = omc_InstExtends_fixTypeSpec(threadData, _inCache, _env, _typeSpec1, _tree);
_ad = omc_InstExtends_fixArrayDim(threadData, _inCache, _env, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_attr), 2))), _tree);
if((!referenceEq(_ad, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_attr), 2))))))
{
tmpMeta18 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta18), MMC_UNTAGPTR(_attr), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta18))[2] = _ad;
_attr = tmpMeta18;
}
if((!((referenceEq(_ad, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_attr), 2)))) && referenceEq(_typeSpec1, _typeSpec2)) && referenceEq(_modifications1, _modifications2))))
{
tmpMeta19 = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _name, _prefixes, _attr, _typeSpec2, _modifications2, _comment, _condition, _info);
_elt2 = tmpMeta19;
}
tmpMeta1 = _elt2;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,8) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_elt = tmp4_2;
_attr = tmpMeta20;
_env = tmp4_1;
tmp4 += 6;
_modifications2 = omc_InstExtends_fixModifications(threadData, _inCache, _env, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 6))), _tree);
_typeSpec2 = omc_InstExtends_fixTypeSpec(threadData, _inCache, _env, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 5))), _tree);
_ad = omc_InstExtends_fixArrayDim(threadData, _inCache, _env, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_attr), 2))), _tree);
if((!referenceEq(_ad, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_attr), 2))))))
{
tmpMeta21 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta21), MMC_UNTAGPTR(_attr), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta21))[2] = _ad;
_attr = tmpMeta21;
}
if((!((referenceEq(_ad, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_attr), 2)))) && referenceEq((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 5))), _typeSpec2)) && referenceEq((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 6))), _modifications2))))
{
tmpMeta22 = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 3))), _attr, _typeSpec2, _modifications2, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 7))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 8))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 9))));
_elt = tmpMeta22;
}
tmpMeta1 = _elt;
goto tmp3_done;
}
case 2: {
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
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_boolean tmp40;
modelica_metatype tmpMeta41;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,8) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta25,0,1) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,0,0) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 6));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 8));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 9));
_name = tmpMeta23;
_prefixes = tmpMeta24;
_partialPrefix = tmpMeta27;
_restriction = tmpMeta28;
_comment = tmpMeta29;
_info = tmpMeta30;
_env = tmp4_1;
tmpMeta32 = omc_Lookup_lookupClassLocal(threadData, _env, _name, &tmpMeta31);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta32,2,8) == 0) goto goto_2;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 3));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 5));
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 6));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 7));
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 8));
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 9));
_prefixes = tmpMeta33;
_partialPrefix = tmpMeta34;
_restriction = tmpMeta35;
_classDef1 = tmpMeta36;
_comment = tmpMeta37;
_info = tmpMeta38;
_env = tmpMeta31;
_env = omc_FGraph_openScope(threadData, _env, _OMC_LIT6, _name, omc_FGraph_restrictionToScopeType(threadData, _restriction));
_classDef2 = omc_InstExtends_fixClassdef(threadData, _inCache, _env, _classDef1, _tree);
tmp40 = (modelica_boolean)referenceEq(_classDef1, _classDef2);
if(tmp40)
{
tmpMeta41 = _inElt;
}
else
{
tmpMeta39 = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _name, _prefixes, _OMC_LIT6, _partialPrefix, _restriction, _classDef2, _comment, _info);
tmpMeta41 = tmpMeta39;
}
tmpMeta1 = tmpMeta41;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_boolean tmp51;
modelica_metatype tmpMeta52;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,8) == 0) goto tmp3_end;
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta44,0,0) == 0) goto tmp3_end;
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 6));
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 7));
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 8));
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 9));
_name = tmpMeta42;
_prefixes = tmpMeta43;
_partialPrefix = tmpMeta45;
_restriction = tmpMeta46;
_classDef1 = tmpMeta47;
_comment = tmpMeta48;
_info = tmpMeta49;
_env = tmp4_1;
tmp4 += 4;
_env = omc_FGraph_openScope(threadData, _env, _OMC_LIT6, _name, omc_FGraph_restrictionToScopeType(threadData, _restriction));
_classDef2 = omc_InstExtends_fixClassdef(threadData, _inCache, _env, _classDef1, _tree);
tmp51 = (modelica_boolean)referenceEq(_classDef1, _classDef2);
if(tmp51)
{
tmpMeta52 = _inElt;
}
else
{
tmpMeta50 = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _name, _prefixes, _OMC_LIT6, _partialPrefix, _restriction, _classDef2, _comment, _info);
tmpMeta52 = tmpMeta50;
}
tmpMeta1 = tmpMeta52;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
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
modelica_metatype tmpMeta67;
modelica_metatype tmpMeta68;
modelica_metatype tmpMeta69;
modelica_boolean tmp70;
modelica_metatype tmpMeta71;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,8) == 0) goto tmp3_end;
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta54), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta55,0,1) == 0) goto tmp3_end;
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta56,1,0) == 0) goto tmp3_end;
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
tmpMeta58 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 6));
tmpMeta59 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 8));
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 9));
_name = tmpMeta53;
_prefixes = tmpMeta54;
_partialPrefix = tmpMeta57;
_restriction = tmpMeta58;
_comment = tmpMeta59;
_info = tmpMeta60;
_env = tmp4_1;
tmpMeta62 = omc_Lookup_lookupClassLocal(threadData, _env, _name, &tmpMeta61);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta62,2,8) == 0) goto goto_2;
tmpMeta63 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta62), 3));
tmpMeta64 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta62), 5));
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta62), 6));
tmpMeta66 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta62), 7));
tmpMeta67 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta62), 8));
tmpMeta68 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta62), 9));
_prefixes = tmpMeta63;
_partialPrefix = tmpMeta64;
_restriction = tmpMeta65;
_classDef1 = tmpMeta66;
_comment = tmpMeta67;
_info = tmpMeta68;
_env = tmpMeta61;
_env = omc_FGraph_openScope(threadData, _env, _OMC_LIT12, _name, omc_FGraph_restrictionToScopeType(threadData, _restriction));
_classDef2 = omc_InstExtends_fixClassdef(threadData, _inCache, _env, _classDef1, _tree);
tmp70 = (modelica_boolean)referenceEq(_classDef1, _classDef2);
if(tmp70)
{
tmpMeta71 = _inElt;
}
else
{
tmpMeta69 = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _name, _prefixes, _OMC_LIT12, _partialPrefix, _restriction, _classDef2, _comment, _info);
tmpMeta71 = tmpMeta69;
}
tmpMeta1 = tmpMeta71;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta72;
modelica_metatype tmpMeta73;
modelica_metatype tmpMeta74;
modelica_metatype tmpMeta75;
modelica_metatype tmpMeta76;
modelica_metatype tmpMeta77;
modelica_metatype tmpMeta78;
modelica_metatype tmpMeta79;
modelica_metatype tmpMeta80;
modelica_boolean tmp81;
modelica_metatype tmpMeta82;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,8) == 0) goto tmp3_end;
tmpMeta72 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta73 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta74 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta74,1,0) == 0) goto tmp3_end;
tmpMeta75 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
tmpMeta76 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 6));
tmpMeta77 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 7));
tmpMeta78 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 8));
tmpMeta79 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 9));
_name = tmpMeta72;
_prefixes = tmpMeta73;
_partialPrefix = tmpMeta75;
_restriction = tmpMeta76;
_classDef1 = tmpMeta77;
_comment = tmpMeta78;
_info = tmpMeta79;
_env = tmp4_1;
tmp4 += 2;
_env = omc_FGraph_openScope(threadData, _env, _OMC_LIT12, _name, omc_FGraph_restrictionToScopeType(threadData, _restriction));
_classDef2 = omc_InstExtends_fixClassdef(threadData, _inCache, _env, _classDef1, _tree);
tmp81 = (modelica_boolean)referenceEq(_classDef1, _classDef2);
if(tmp81)
{
tmpMeta82 = _inElt;
}
else
{
tmpMeta80 = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _name, _prefixes, _OMC_LIT12, _partialPrefix, _restriction, _classDef2, _comment, _info);
tmpMeta82 = tmpMeta80;
}
tmpMeta1 = tmpMeta82;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta83;
modelica_metatype tmpMeta84;
modelica_metatype tmpMeta85;
modelica_metatype tmpMeta86;
modelica_metatype tmpMeta87;
modelica_metatype tmpMeta88;
modelica_boolean tmp89;
modelica_metatype tmpMeta90;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,5) == 0) goto tmp3_end;
tmpMeta83 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta84 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta85 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta86 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
tmpMeta87 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 6));
_extendsPath1 = tmpMeta83;
_vis = tmpMeta84;
_modifications1 = tmpMeta85;
_optAnnotation = tmpMeta86;
_info = tmpMeta87;
_env = tmp4_1;
tmp4 += 1;
_extendsPath2 = omc_InstExtends_fixPath(threadData, _inCache, _env, _extendsPath1, _tree);
_modifications2 = omc_InstExtends_fixModifications(threadData, _inCache, _env, _modifications1, _tree);
tmp89 = (modelica_boolean)(referenceEq(_extendsPath1, _extendsPath2) && referenceEq(_modifications1, _modifications2));
if(tmp89)
{
tmpMeta90 = _inElt;
}
else
{
tmpMeta88 = mmc_mk_box6(4, &SCode_Element_EXTENDS__desc, _extendsPath2, _vis, _modifications2, _optAnnotation, _info);
tmpMeta90 = tmpMeta88;
}
tmpMeta1 = tmpMeta90;
goto tmp3_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,3) == 0) goto tmp3_end;
tmpMeta1 = _inElt;
goto tmp3_done;
}
case 8: {
modelica_boolean tmp91;
modelica_metatype tmpMeta92;
_elt = tmp4_2;
tmp91 = omc_Flags_isSet(threadData, _OMC_LIT3);
if (1 != tmp91) goto goto_2;
tmpMeta92 = stringAppend(_OMC_LIT13,omc_SCodeDump_unparseElementStr(threadData, _elt, _OMC_LIT5));
omc_Debug_traceln(threadData, tmpMeta92);
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
if (++tmp4 < 9) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outElts = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outElts;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_fixLocalIdent(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype __omcQ_24in_5Felt, modelica_metatype _tree)
{
modelica_metatype _elt = NULL;
modelica_metatype _elt1 = NULL;
modelica_metatype _elt2 = NULL;
modelica_metatype _mod = NULL;
modelica_boolean _b;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_metatype tmpMeta6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_elt = __omcQ_24in_5Felt;
tmpMeta1 = _elt;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp5 = mmc_unbox_integer(tmpMeta4);
_elt1 = tmpMeta2;
_mod = tmpMeta3;
_b = tmp5;
_elt2 = omc_InstExtends_fixElement(threadData, _inCache, _inEnv, _elt1, _tree);
if(((!referenceEq(_elt1, _elt2)) || (!_b)))
{
tmpMeta6 = mmc_mk_box3(0, _elt2, _mod, mmc_mk_boolean(1));
_elt = tmpMeta6;
}
_return: OMC_LABEL_UNUSED
return _elt;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_getLocalIdentElement(threadData_t *threadData, modelica_metatype _elt, modelica_metatype __omcQ_24in_5Ftree)
{
modelica_metatype _tree = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_tree = __omcQ_24in_5Ftree;
{
modelica_metatype tmp4_1;
tmp4_1 = _elt;
{
modelica_string _id = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 6: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,8) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_id = tmpMeta5;
tmpMeta1 = omc_AvlSetString_add(threadData, _tree, _id);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_id = tmpMeta6;
tmpMeta1 = omc_AvlSetString_add(threadData, _tree, _id);
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmpMeta1 = _tree;
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
_tree = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _tree;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_getLocalIdentElementTpl(threadData_t *threadData, modelica_metatype _eltTpl, modelica_metatype __omcQ_24in_5Ftree)
{
modelica_metatype _tree = NULL;
modelica_metatype _elt = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_tree = __omcQ_24in_5Ftree;
tmpMeta1 = _eltTpl;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
_elt = tmpMeta2;
_tree = omc_InstExtends_getLocalIdentElement(threadData, _elt, _tree);
_return: OMC_LABEL_UNUSED
return _tree;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_getLocalIdentList(threadData_t *threadData, modelica_metatype _ielts, modelica_metatype __omcQ_24in_5Ftree, modelica_fnptr _getIdent)
{
modelica_metatype _tree = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_tree = __omcQ_24in_5Ftree;
{
modelica_metatype _elt;
for (tmpMeta1 = _ielts; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_elt = MMC_CAR(tmpMeta1);
_tree = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getIdent), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getIdent), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getIdent), 2))), _elt, _tree) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getIdent), 1)))) (threadData, _elt, _tree);
}
}
_return: OMC_LABEL_UNUSED
return _tree;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_updateComponentsAndClassdefs2(threadData_t *threadData, modelica_metatype _inComponent, modelica_metatype _inEnv, modelica_metatype _inMod, modelica_metatype *out_outRestMod)
{
modelica_metatype _outComponent = NULL;
modelica_metatype _outRestMod = NULL;
modelica_metatype _el = NULL;
modelica_metatype _mod = NULL;
modelica_boolean _b;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inComponent;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp5 = mmc_unbox_integer(tmpMeta4);
_el = tmpMeta2;
_mod = tmpMeta3;
_b = tmp5;
{
volatile modelica_metatype tmp9_1;
tmp9_1 = _el;
{
modelica_metatype _comp = NULL;
modelica_metatype _cmod = NULL;
modelica_metatype _mod_rest = NULL;
volatile mmc_switch_type tmp9;
int tmp10;
tmp9 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp8_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp9 < 6; tmp9++) {
switch (MMC_SWITCH_CAST(tmp9)) {
case 0: {
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp9_1,3,8) == 0) goto tmp8_end;
tmp9 += 4;
_cmod = omc_Mod_lookupCompModificationFromEqu(threadData, _inMod, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_el), 2))));
_cmod = omc_Mod_merge(threadData, _cmod, _mod, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_el), 2))), 0);
_mod_rest = _inMod;
tmpMeta11 = mmc_mk_box3(0, _el, _cmod, mmc_mk_boolean(_b));
tmpMeta[0+0] = tmpMeta11;
tmpMeta[0+1] = _mod_rest;
goto tmp8_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp9_1,1,5) == 0) goto tmp8_end;
tmp9 += 3;
tmpMeta[0+0] = _inComponent;
tmpMeta[0+1] = _inMod;
goto tmp8_done;
}
case 2: {
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp9_1,0,3) == 0) goto tmp8_end;
tmp9 += 2;
tmpMeta12 = mmc_mk_box3(0, _el, _OMC_LIT14, mmc_mk_boolean(_b));
tmpMeta[0+0] = tmpMeta12;
tmpMeta[0+1] = _inMod;
goto tmp8_done;
}
case 3: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp9_1,2,8) == 0) goto tmp8_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp9_1), 3));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,0,1) == 0) goto tmp8_end;
tmpMeta15 = omc_Mod_lookupCompModification(threadData, _inMod, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_el), 2))));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,1,4) == 0) goto goto_7;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 4));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 5));
_comp = tmpMeta16;
_cmod = tmpMeta17;
_mod_rest = _inMod;
_cmod = omc_Mod_merge(threadData, _cmod, _mod, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_el), 2))), 0);
_comp = omc_SCodeUtil_mergeWithOriginal(threadData, _comp, _el);
tmpMeta18 = mmc_mk_box3(0, _comp, _cmod, mmc_mk_boolean(_b));
tmpMeta[0+0] = tmpMeta18;
tmpMeta[0+1] = _mod_rest;
goto tmp8_done;
}
case 4: {
modelica_metatype tmpMeta19;
modelica_boolean tmp20;
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp9_1,2,8) == 0) goto tmp8_end;
_cmod = omc_Mod_lookupCompModification(threadData, _inMod, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_el), 2))));
tmp20 = (modelica_boolean)valueEq(_cmod, _OMC_LIT14);
if(tmp20)
{
tmpMeta21 = _inComponent;
}
else
{
tmpMeta19 = mmc_mk_box3(0, _el, _cmod, mmc_mk_boolean(_b));
tmpMeta21 = tmpMeta19;
}
_outComponent = tmpMeta21;
tmpMeta[0+0] = _outComponent;
tmpMeta[0+1] = _inMod;
goto tmp8_done;
}
case 5: {
modelica_boolean tmp22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
tmp22 = omc_Flags_isSet(threadData, _OMC_LIT3);
if (1 != tmp22) goto goto_7;
tmpMeta23 = stringAppend(_OMC_LIT15,omc_FGraph_printGraphPathStr(threadData, _inEnv));
tmpMeta24 = stringAppend(tmpMeta23,_OMC_LIT16);
tmpMeta25 = stringAppend(tmpMeta24,omc_Mod_printModStr(threadData, _inMod));
tmpMeta26 = stringAppend(tmpMeta25,_OMC_LIT17);
tmpMeta27 = stringAppend(tmpMeta26,omc_Mod_printModStr(threadData, _mod));
tmpMeta28 = stringAppend(tmpMeta27,_OMC_LIT18);
tmpMeta29 = stringAppend(tmpMeta28,(_b?_OMC_LIT19:_OMC_LIT20));
tmpMeta30 = stringAppend(tmpMeta29,_OMC_LIT21);
tmpMeta31 = stringAppend(tmpMeta30,omc_SCodeDump_unparseElementStr(threadData, _el, _OMC_LIT5));
omc_Debug_traceln(threadData, tmpMeta31);
goto goto_7;
goto tmp8_done;
}
}
goto tmp8_end;
tmp8_end: ;
}
goto goto_7;
tmp8_done:
(void)tmp9;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp8_done2;
goto_7:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp9 < 6) {
goto tmp8_top;
}
MMC_THROW_INTERNAL();
tmp8_done2:;
}
}
_outComponent = tmpMeta[0+0];
_outRestMod = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outRestMod) { *out_outRestMod = _outRestMod; }
return _outComponent;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_updateComponentsAndClassdefs(threadData_t *threadData, modelica_metatype _inComponents, modelica_metatype _inMod, modelica_metatype _inEnv, modelica_metatype *out_outRestMod)
{
modelica_metatype _outComponents = NULL;
modelica_metatype _outRestMod = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outComponents = omc_List_map1Fold(threadData, _inComponents, boxvar_InstExtends_updateComponentsAndClassdefs2, _inEnv, _inMod ,&_outRestMod);
_return: OMC_LABEL_UNUSED
if (out_outRestMod) { *out_outRestMod = _outRestMod; }
return _outComponents;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_noImportElements(threadData_t *threadData, modelica_metatype _inElements)
{
modelica_metatype _outElements = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype __omcQ_24tmpVar0;
modelica_integer tmp4;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _inElements;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar1;
while(1) {
tmp4 = 1;
while (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
if ((!omc_SCodeUtil_elementIsImport(threadData, _e))) {
tmp4--;
break;
}
}
if (tmp4 == 0) {
__omcQ_24tmpVar0 = _e;
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp4 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar1;
}
_outElements = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outElements;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_instDerivedClassesWork(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inClass, modelica_boolean _inBoolean, modelica_metatype _inInfo, modelica_boolean _overflow, modelica_integer _numIter, modelica_metatype *out_outEnv1, modelica_metatype *out_outIH, modelica_metatype *out_outSCodeElementLst2, modelica_metatype *out_outSCodeEquationLst3, modelica_metatype *out_outSCodeEquationLst4, modelica_metatype *out_outSCodeAlgorithmLst5, modelica_metatype *out_outSCodeAlgorithmLst6, modelica_metatype *out_outMod, modelica_metatype *out_outComments)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv1 = NULL;
modelica_metatype _outIH = NULL;
modelica_metatype _outSCodeElementLst2 = NULL;
modelica_metatype _outSCodeEquationLst3 = NULL;
modelica_metatype _outSCodeEquationLst4 = NULL;
modelica_metatype _outSCodeAlgorithmLst5 = NULL;
modelica_metatype _outSCodeAlgorithmLst6 = NULL;
modelica_metatype _outMod = NULL;
modelica_metatype _outComments = NULL;
modelica_metatype tmpMeta[10] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;volatile modelica_metatype tmp4_5;volatile modelica_metatype tmp4_6;volatile modelica_boolean tmp4_7;volatile modelica_metatype tmp4_8;volatile modelica_boolean tmp4_9;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inIH;
tmp4_4 = _inMod;
tmp4_5 = _inPrefix;
tmp4_6 = _inClass;
tmp4_7 = _inBoolean;
tmp4_8 = _inInfo;
tmp4_9 = _overflow;
{
modelica_metatype _elt = NULL;
modelica_metatype _env = NULL;
modelica_metatype _cenv = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _daeDMOD = NULL;
modelica_metatype _eq = NULL;
modelica_metatype _ieq = NULL;
modelica_metatype _alg = NULL;
modelica_metatype _ialg = NULL;
modelica_metatype _c = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _dmod = NULL;
modelica_boolean _impl;
modelica_metatype _cache = NULL;
modelica_metatype _ih = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _enumLst = NULL;
modelica_string _n = NULL;
modelica_string _name = NULL;
modelica_string _str1 = NULL;
modelica_string _str2 = NULL;
modelica_metatype _extdecl = NULL;
modelica_metatype _pre = NULL;
modelica_metatype _info = NULL;
modelica_metatype _prefixes = NULL;
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
modelica_boolean tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,2,8) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 2));
_name = tmpMeta6;
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
tmp7 = omc_InstUtil_isBuiltInClass(threadData, _name);
if (1 != tmp7) goto goto_2;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta9 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta11 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta13 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = tmpMeta8;
tmpMeta[0+4] = tmpMeta9;
tmpMeta[0+5] = tmpMeta10;
tmpMeta[0+6] = tmpMeta11;
tmpMeta[0+7] = tmpMeta12;
tmpMeta[0+8] = _inMod;
tmpMeta[0+9] = tmpMeta13;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,2,8) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,0,8) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 3));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 4));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 5));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 6));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 9));
_name = tmpMeta14;
_elt = tmpMeta16;
_eq = tmpMeta17;
_ieq = tmpMeta18;
_alg = tmpMeta19;
_ialg = tmpMeta20;
_extdecl = tmpMeta21;
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_info = tmp4_8;
tmp4 += 2;
tmpMeta22 = mmc_mk_cons(_name, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_assertionOrAddSourceMessage(threadData, isNone(_extdecl), _OMC_LIT26, tmpMeta22, _info);
tmpMeta23 = mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inClass), 8))), MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = _elt;
tmpMeta[0+4] = _eq;
tmpMeta[0+5] = _ieq;
tmpMeta[0+6] = _alg;
tmpMeta[0+7] = _ialg;
tmpMeta[0+8] = _inMod;
tmpMeta[0+9] = tmpMeta23;
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
if (0 != tmp4_9) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,2,8) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta24,2,3) == 0) goto tmp3_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta25,0,2) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 2));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 3));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 9));
_tp = tmpMeta26;
_dmod = tmpMeta27;
_info = tmpMeta28;
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_mod = tmp4_4;
_pre = tmp4_5;
_impl = tmp4_7;
tmp4 += 2;
_cache = omc_Lookup_lookupClass(threadData, _cache, _env, _tp, mmc_mk_some(_info) ,&_c ,&_cenv);
_dmod = omc_InstUtil_chainRedeclares(threadData, _mod, _dmod);
tmpMeta29 = mmc_mk_box2(5, &Mod_ModScope_DERIVED__desc, _tp);
_cache = omc_Mod_elabMod(threadData, _cache, _env, _ih, _pre, _dmod, _impl, tmpMeta29, _info ,&_daeDMOD);
_mod = omc_Mod_merge(threadData, _mod, _daeDMOD, _OMC_LIT27, 1);
_cache = omc_InstExtends_instDerivedClassesWork(threadData, _cache, _cenv, _ih, _mod, _pre, _c, _impl, _info, (_numIter >= ((modelica_integer) 256)), ((modelica_integer) 1) + _numIter ,&_env ,&_ih ,&_elt ,&_eq ,&_ieq ,&_alg ,&_ialg ,&_mod ,&_outComments);
tmpMeta30 = mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inClass), 8))), _outComments);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = _elt;
tmpMeta[0+4] = _eq;
tmpMeta[0+5] = _ieq;
tmpMeta[0+6] = _alg;
tmpMeta[0+7] = _ialg;
tmpMeta[0+8] = _mod;
tmpMeta[0+9] = tmpMeta30;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
if (0 != tmp4_9) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,2,8) == 0) goto tmp3_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 2));
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 3));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta33,3,1) == 0) goto tmp3_end;
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta33), 2));
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 8));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 9));
_n = tmpMeta31;
_prefixes = tmpMeta32;
_enumLst = tmpMeta34;
_cmt = tmpMeta35;
_info = tmpMeta36;
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_mod = tmp4_4;
_pre = tmp4_5;
_impl = tmp4_7;
tmp4 += 1;
_c = omc_SCodeInstUtil_expandEnumeration(threadData, _n, _enumLst, _prefixes, _cmt, _info);
tmpMeta[0+0] = omc_InstExtends_instDerivedClassesWork(threadData, _cache, _env, _ih, _mod, _pre, _c, _impl, _info, (_numIter >= ((modelica_integer) 256)), ((modelica_integer) 1) + _numIter, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3], &tmpMeta[0+4], &tmpMeta[0+5], &tmpMeta[0+6], &tmpMeta[0+7], &tmpMeta[0+8], &tmpMeta[0+9]);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta37;
if (1 != tmp4_9) goto tmp3_end;
_str1 = omc_SCodeDump_unparseElementStr(threadData, _inClass, _OMC_LIT5);
_str2 = omc_FGraph_printGraphPathStr(threadData, _inEnv);
tmpMeta37 = mmc_mk_cons(_str1, mmc_mk_cons(_str2, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT31, tmpMeta37, _inInfo);
goto goto_2;
goto tmp3_done;
}
case 5: {
modelica_boolean tmp38;
tmp38 = omc_Flags_isSet(threadData, _OMC_LIT3);
if (1 != tmp38) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT32);
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
_outCache = tmpMeta[0+0];
_outEnv1 = tmpMeta[0+1];
_outIH = tmpMeta[0+2];
_outSCodeElementLst2 = tmpMeta[0+3];
_outSCodeEquationLst3 = tmpMeta[0+4];
_outSCodeEquationLst4 = tmpMeta[0+5];
_outSCodeAlgorithmLst5 = tmpMeta[0+6];
_outSCodeAlgorithmLst6 = tmpMeta[0+7];
_outMod = tmpMeta[0+8];
_outComments = tmpMeta[0+9];
_return: OMC_LABEL_UNUSED
if (out_outEnv1) { *out_outEnv1 = _outEnv1; }
if (out_outIH) { *out_outIH = _outIH; }
if (out_outSCodeElementLst2) { *out_outSCodeElementLst2 = _outSCodeElementLst2; }
if (out_outSCodeEquationLst3) { *out_outSCodeEquationLst3 = _outSCodeEquationLst3; }
if (out_outSCodeEquationLst4) { *out_outSCodeEquationLst4 = _outSCodeEquationLst4; }
if (out_outSCodeAlgorithmLst5) { *out_outSCodeAlgorithmLst5 = _outSCodeAlgorithmLst5; }
if (out_outSCodeAlgorithmLst6) { *out_outSCodeAlgorithmLst6 = _outSCodeAlgorithmLst6; }
if (out_outMod) { *out_outMod = _outMod; }
if (out_outComments) { *out_outComments = _outComments; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstExtends_instDerivedClassesWork(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inClass, modelica_metatype _inBoolean, modelica_metatype _inInfo, modelica_metatype _overflow, modelica_metatype _numIter, modelica_metatype *out_outEnv1, modelica_metatype *out_outIH, modelica_metatype *out_outSCodeElementLst2, modelica_metatype *out_outSCodeEquationLst3, modelica_metatype *out_outSCodeEquationLst4, modelica_metatype *out_outSCodeAlgorithmLst5, modelica_metatype *out_outSCodeAlgorithmLst6, modelica_metatype *out_outMod, modelica_metatype *out_outComments)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inBoolean);
tmp2 = mmc_unbox_integer(_overflow);
tmp3 = mmc_unbox_integer(_numIter);
_outCache = omc_InstExtends_instDerivedClassesWork(threadData, _inCache, _inEnv, _inIH, _inMod, _inPrefix, _inClass, tmp1, _inInfo, tmp2, tmp3, out_outEnv1, out_outIH, out_outSCodeElementLst2, out_outSCodeEquationLst3, out_outSCodeEquationLst4, out_outSCodeAlgorithmLst5, out_outSCodeAlgorithmLst6, out_outMod, out_outComments);
return _outCache;
}
DLLExport
modelica_metatype omc_InstExtends_instDerivedClasses(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inClass, modelica_boolean _inBoolean, modelica_metatype _inInfo, modelica_metatype *out_outEnv1, modelica_metatype *out_outIH, modelica_metatype *out_outSCodeElementLst2, modelica_metatype *out_outSCodeEquationLst3, modelica_metatype *out_outSCodeEquationLst4, modelica_metatype *out_outSCodeAlgorithmLst5, modelica_metatype *out_outSCodeAlgorithmLst6, modelica_metatype *out_outMod, modelica_metatype *out_outComments)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv1 = NULL;
modelica_metatype _outIH = NULL;
modelica_metatype _outSCodeElementLst2 = NULL;
modelica_metatype _outSCodeEquationLst3 = NULL;
modelica_metatype _outSCodeEquationLst4 = NULL;
modelica_metatype _outSCodeAlgorithmLst5 = NULL;
modelica_metatype _outSCodeAlgorithmLst6 = NULL;
modelica_metatype _outMod = NULL;
modelica_metatype _outComments = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCache = omc_InstExtends_instDerivedClassesWork(threadData, _inCache, _inEnv, _inIH, _inMod, _inPrefix, _inClass, _inBoolean, _inInfo, 0, ((modelica_integer) 0) ,&_outEnv1 ,&_outIH ,&_outSCodeElementLst2 ,&_outSCodeEquationLst3 ,&_outSCodeEquationLst4 ,&_outSCodeAlgorithmLst5 ,&_outSCodeAlgorithmLst6 ,&_outMod ,&_outComments);
_return: OMC_LABEL_UNUSED
if (out_outEnv1) { *out_outEnv1 = _outEnv1; }
if (out_outIH) { *out_outIH = _outIH; }
if (out_outSCodeElementLst2) { *out_outSCodeElementLst2 = _outSCodeElementLst2; }
if (out_outSCodeEquationLst3) { *out_outSCodeEquationLst3 = _outSCodeEquationLst3; }
if (out_outSCodeEquationLst4) { *out_outSCodeEquationLst4 = _outSCodeEquationLst4; }
if (out_outSCodeAlgorithmLst5) { *out_outSCodeAlgorithmLst5 = _outSCodeAlgorithmLst5; }
if (out_outSCodeAlgorithmLst6) { *out_outSCodeAlgorithmLst6 = _outSCodeAlgorithmLst6; }
if (out_outMod) { *out_outMod = _outMod; }
if (out_outComments) { *out_outComments = _outComments; }
return _outCache;
}
modelica_metatype boxptr_InstExtends_instDerivedClasses(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inClass, modelica_metatype _inBoolean, modelica_metatype _inInfo, modelica_metatype *out_outEnv1, modelica_metatype *out_outIH, modelica_metatype *out_outSCodeElementLst2, modelica_metatype *out_outSCodeEquationLst3, modelica_metatype *out_outSCodeEquationLst4, modelica_metatype *out_outSCodeAlgorithmLst5, modelica_metatype *out_outSCodeAlgorithmLst6, modelica_metatype *out_outMod, modelica_metatype *out_outComments)
{
modelica_integer tmp1;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inBoolean);
_outCache = omc_InstExtends_instDerivedClasses(threadData, _inCache, _inEnv, _inIH, _inMod, _inPrefix, _inClass, tmp1, _inInfo, out_outEnv1, out_outIH, out_outSCodeElementLst2, out_outSCodeEquationLst3, out_outSCodeEquationLst4, out_outSCodeAlgorithmLst5, out_outSCodeAlgorithmLst6, out_outMod, out_outComments);
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_instClassExtendsList2(threadData_t *threadData, modelica_metatype _inEnv, modelica_metatype _inMod, modelica_string _inName, modelica_metatype _inClassExtendsElt, modelica_metatype _inElements, modelica_metatype *out_outElements)
{
modelica_metatype _outMod = NULL;
modelica_metatype _outElements = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_string tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;
tmp4_1 = _inMod;
tmp4_2 = _inName;
tmp4_3 = _inClassExtendsElt;
tmp4_4 = _inElements;
{
modelica_metatype _elt = NULL;
modelica_metatype _compelt = NULL;
modelica_metatype _classExtendsElt = NULL;
modelica_metatype _cl = NULL;
modelica_metatype _classDef = NULL;
modelica_metatype _classExtendsCdef = NULL;
modelica_metatype _partialPrefix1 = NULL;
modelica_metatype _partialPrefix2 = NULL;
modelica_metatype _encapsulatedPrefix1 = NULL;
modelica_metatype _encapsulatedPrefix2 = NULL;
modelica_metatype _restriction1 = NULL;
modelica_metatype _restriction2 = NULL;
modelica_metatype _prefixes1 = NULL;
modelica_metatype _prefixes2 = NULL;
modelica_metatype _vis2 = NULL;
modelica_string _name1 = NULL;
modelica_string _name2 = NULL;
modelica_string _env_path = NULL;
modelica_metatype _externalDecl1 = NULL;
modelica_metatype _externalDecl2 = NULL;
modelica_metatype _comment1 = NULL;
modelica_metatype _comment2 = NULL;
modelica_metatype _els1 = NULL;
modelica_metatype _els2 = NULL;
modelica_metatype _nEqn1 = NULL;
modelica_metatype _nEqn2 = NULL;
modelica_metatype _inEqn1 = NULL;
modelica_metatype _inEqn2 = NULL;
modelica_metatype _nAlg1 = NULL;
modelica_metatype _nAlg2 = NULL;
modelica_metatype _inAlg1 = NULL;
modelica_metatype _inAlg2 = NULL;
modelica_metatype _inCons1 = NULL;
modelica_metatype _inCons2 = NULL;
modelica_metatype _clats = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _first = NULL;
modelica_metatype _mods = NULL;
modelica_metatype _derivedMod = NULL;
modelica_metatype _mod1 = NULL;
modelica_metatype _emod = NULL;
modelica_metatype _info1 = NULL;
modelica_metatype _info2 = NULL;
modelica_boolean _b;
modelica_metatype _attrs = NULL;
modelica_metatype _derivedTySpec = NULL;
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
modelica_integer tmp13;
modelica_boolean tmp14;
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
if (listEmpty(tmp4_4)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_4);
tmpMeta7 = MMC_CDR(tmp4_4);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,2,8) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,0,8) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
tmp13 = mmc_unbox_integer(tmpMeta12);
_cl = tmpMeta8;
_name2 = tmpMeta9;
_mod1 = tmpMeta11;
_b = tmp13;
_rest = tmpMeta7;
_emod = tmp4_1;
_name1 = tmp4_2;
_classExtendsElt = tmp4_3;
tmp4 += 1;
tmp14 = (stringEqual(_name1, _name2));
if (1 != tmp14) goto goto_2;
_env_path = omc_AbsynUtil_pathString(threadData, omc_FGraph_getGraphName(threadData, _inEnv), _OMC_LIT33, 1, 0);
_name2 = omc_InstExtends_buildClassExtendsName(threadData, _env_path, _name2);
tmpMeta15 = _cl;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,2,8) == 0) goto goto_2;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 3));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 4));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 5));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 6));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,0,8) == 0) goto goto_2;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 2));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 3));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 4));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 5));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 6));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 7));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 8));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 9));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 8));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 9));
_prefixes2 = tmpMeta16;
_encapsulatedPrefix2 = tmpMeta17;
_partialPrefix2 = tmpMeta18;
_restriction2 = tmpMeta19;
_els2 = tmpMeta21;
_nEqn2 = tmpMeta22;
_inEqn2 = tmpMeta23;
_nAlg2 = tmpMeta24;
_inAlg2 = tmpMeta25;
_inCons2 = tmpMeta26;
_clats = tmpMeta27;
_externalDecl2 = tmpMeta28;
_comment2 = tmpMeta29;
_info2 = tmpMeta30;
tmpMeta31 = _classExtendsElt;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta31,2,8) == 0) goto goto_2;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta31), 3));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta31), 4));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta31), 5));
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta31), 6));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta31), 7));
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta31), 8));
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta31), 9));
_prefixes1 = tmpMeta32;
_encapsulatedPrefix1 = tmpMeta33;
_partialPrefix1 = tmpMeta34;
_restriction1 = tmpMeta35;
_classExtendsCdef = tmpMeta36;
_comment1 = tmpMeta37;
_info1 = tmpMeta38;
tmpMeta39 = _classExtendsCdef;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta39,1,2) == 0) goto goto_2;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 2));
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta41,0,8) == 0) goto goto_2;
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 2));
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 3));
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 4));
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 5));
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 6));
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 7));
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 9));
_mods = tmpMeta40;
_els1 = tmpMeta42;
_nEqn1 = tmpMeta43;
_inEqn1 = tmpMeta44;
_nAlg1 = tmpMeta45;
_inAlg1 = tmpMeta46;
_inCons1 = tmpMeta47;
_externalDecl1 = tmpMeta48;
tmpMeta49 = mmc_mk_box9(3, &SCode_ClassDef_PARTS__desc, _els2, _nEqn2, _inEqn2, _nAlg2, _inAlg2, _inCons2, _clats, _externalDecl2);
_classDef = tmpMeta49;
tmpMeta50 = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _name2, _prefixes2, _encapsulatedPrefix2, _partialPrefix2, _restriction2, _classDef, _comment2, _info2);
_compelt = tmpMeta50;
_vis2 = omc_SCodeUtil_prefixesVisibility(threadData, _prefixes2);
tmpMeta51 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _name2);
tmpMeta52 = mmc_mk_box6(4, &SCode_Element_EXTENDS__desc, tmpMeta51, _vis2, _mods, mmc_mk_none(), _info1);
_elt = tmpMeta52;
tmpMeta53 = mmc_mk_cons(_elt, _els1);
tmpMeta54 = mmc_mk_box9(3, &SCode_ClassDef_PARTS__desc, tmpMeta53, _nEqn1, _inEqn1, _nAlg1, _inAlg1, _inCons1, _clats, _externalDecl1);
_classDef = tmpMeta54;
tmpMeta55 = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _name1, _prefixes1, _encapsulatedPrefix1, _partialPrefix1, _restriction1, _classDef, _comment1, _info1);
_elt = tmpMeta55;
_emod = omc_Mod_renameTopLevelNamedSubMod(threadData, _emod, _name1, _name2);
tmpMeta57 = mmc_mk_box3(0, _compelt, _mod1, mmc_mk_boolean(_b));
tmpMeta59 = mmc_mk_box3(0, _elt, _OMC_LIT14, mmc_mk_boolean(1));
tmpMeta58 = mmc_mk_cons(tmpMeta59, _rest);
tmpMeta56 = mmc_mk_cons(tmpMeta57, tmpMeta58);
tmpMeta[0+0] = _emod;
tmpMeta[0+1] = tmpMeta56;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
modelica_metatype tmpMeta62;
modelica_metatype tmpMeta63;
modelica_metatype tmpMeta64;
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
modelica_integer tmp67;
modelica_boolean tmp68;
modelica_metatype tmpMeta69;
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
modelica_metatype tmpMeta82;
modelica_metatype tmpMeta83;
modelica_metatype tmpMeta84;
modelica_metatype tmpMeta85;
modelica_metatype tmpMeta86;
modelica_metatype tmpMeta87;
modelica_metatype tmpMeta88;
modelica_metatype tmpMeta89;
modelica_metatype tmpMeta90;
modelica_metatype tmpMeta91;
modelica_metatype tmpMeta92;
modelica_metatype tmpMeta93;
modelica_metatype tmpMeta94;
modelica_metatype tmpMeta95;
modelica_metatype tmpMeta96;
modelica_metatype tmpMeta97;
modelica_metatype tmpMeta98;
modelica_metatype tmpMeta99;
modelica_metatype tmpMeta100;
modelica_metatype tmpMeta101;
modelica_metatype tmpMeta102;
modelica_metatype tmpMeta103;
modelica_metatype tmpMeta104;
modelica_metatype tmpMeta105;
modelica_metatype tmpMeta106;
modelica_metatype tmpMeta107;
modelica_metatype tmpMeta108;
modelica_metatype tmpMeta109;
if (listEmpty(tmp4_4)) goto tmp3_end;
tmpMeta60 = MMC_CAR(tmp4_4);
tmpMeta61 = MMC_CDR(tmp4_4);
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta60), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta62,2,8) == 0) goto tmp3_end;
tmpMeta63 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta62), 2));
tmpMeta64 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta62), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta64,2,3) == 0) goto tmp3_end;
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta60), 2));
tmpMeta66 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta60), 3));
tmp67 = mmc_unbox_integer(tmpMeta66);
_cl = tmpMeta62;
_name2 = tmpMeta63;
_mod1 = tmpMeta65;
_b = tmp67;
_rest = tmpMeta61;
_emod = tmp4_1;
_name1 = tmp4_2;
_classExtendsElt = tmp4_3;
tmp68 = (stringEqual(_name1, _name2));
if (1 != tmp68) goto goto_2;
_env_path = omc_AbsynUtil_pathString(threadData, omc_FGraph_getGraphName(threadData, _inEnv), _OMC_LIT33, 1, 0);
_name2 = omc_InstExtends_buildClassExtendsName(threadData, _env_path, _name2);
tmpMeta69 = _cl;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta69,2,8) == 0) goto goto_2;
tmpMeta70 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta69), 3));
tmpMeta71 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta69), 4));
tmpMeta72 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta69), 5));
tmpMeta73 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta69), 6));
tmpMeta74 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta69), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta74,2,3) == 0) goto goto_2;
tmpMeta75 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta74), 2));
tmpMeta76 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta74), 3));
tmpMeta77 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta74), 4));
tmpMeta78 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta69), 8));
tmpMeta79 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta69), 9));
_prefixes2 = tmpMeta70;
_encapsulatedPrefix2 = tmpMeta71;
_partialPrefix2 = tmpMeta72;
_restriction2 = tmpMeta73;
_derivedTySpec = tmpMeta75;
_derivedMod = tmpMeta76;
_attrs = tmpMeta77;
_comment2 = tmpMeta78;
_info2 = tmpMeta79;
tmpMeta80 = _classExtendsElt;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta80,2,8) == 0) goto goto_2;
tmpMeta81 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta80), 3));
tmpMeta82 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta80), 4));
tmpMeta83 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta80), 5));
tmpMeta84 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta80), 6));
tmpMeta85 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta80), 7));
tmpMeta86 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta80), 8));
tmpMeta87 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta80), 9));
_prefixes1 = tmpMeta81;
_encapsulatedPrefix1 = tmpMeta82;
_partialPrefix1 = tmpMeta83;
_restriction1 = tmpMeta84;
_classExtendsCdef = tmpMeta85;
_comment1 = tmpMeta86;
_info1 = tmpMeta87;
tmpMeta88 = _classExtendsCdef;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta88,1,2) == 0) goto goto_2;
tmpMeta89 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta88), 2));
tmpMeta90 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta88), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta90,0,8) == 0) goto goto_2;
tmpMeta91 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta90), 2));
tmpMeta92 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta90), 3));
tmpMeta93 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta90), 4));
tmpMeta94 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta90), 5));
tmpMeta95 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta90), 6));
tmpMeta96 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta90), 7));
tmpMeta97 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta90), 9));
_mods = tmpMeta89;
_els1 = tmpMeta91;
_nEqn1 = tmpMeta92;
_inEqn1 = tmpMeta93;
_nAlg1 = tmpMeta94;
_inAlg1 = tmpMeta95;
_inCons1 = tmpMeta96;
_externalDecl1 = tmpMeta97;
tmpMeta98 = mmc_mk_box4(5, &SCode_ClassDef_DERIVED__desc, _derivedTySpec, _derivedMod, _attrs);
_classDef = tmpMeta98;
tmpMeta99 = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _name2, _prefixes2, _encapsulatedPrefix2, _partialPrefix2, _restriction2, _classDef, _comment2, _info2);
_compelt = tmpMeta99;
_vis2 = omc_SCodeUtil_prefixesVisibility(threadData, _prefixes2);
tmpMeta100 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _name2);
tmpMeta101 = mmc_mk_box6(4, &SCode_Element_EXTENDS__desc, tmpMeta100, _vis2, _mods, mmc_mk_none(), _info1);
_elt = tmpMeta101;
tmpMeta102 = mmc_mk_cons(_elt, _els1);
tmpMeta103 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta104 = mmc_mk_box9(3, &SCode_ClassDef_PARTS__desc, tmpMeta102, _nEqn1, _inEqn1, _nAlg1, _inAlg1, _inCons1, tmpMeta103, _externalDecl1);
_classDef = tmpMeta104;
tmpMeta105 = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _name1, _prefixes1, _encapsulatedPrefix1, _partialPrefix1, _restriction1, _classDef, _comment1, _info1);
_elt = tmpMeta105;
_emod = omc_Mod_renameTopLevelNamedSubMod(threadData, _emod, _name1, _name2);
tmpMeta107 = mmc_mk_box3(0, _compelt, _mod1, mmc_mk_boolean(_b));
tmpMeta109 = mmc_mk_box3(0, _elt, _OMC_LIT14, mmc_mk_boolean(1));
tmpMeta108 = mmc_mk_cons(tmpMeta109, _rest);
tmpMeta106 = mmc_mk_cons(tmpMeta107, tmpMeta108);
tmpMeta[0+0] = _emod;
tmpMeta[0+1] = tmpMeta106;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta110;
modelica_metatype tmpMeta111;
modelica_metatype tmpMeta112;
if (listEmpty(tmp4_4)) goto tmp3_end;
tmpMeta110 = MMC_CAR(tmp4_4);
tmpMeta111 = MMC_CDR(tmp4_4);
_first = tmpMeta110;
_rest = tmpMeta111;
_emod = tmp4_1;
_name1 = tmp4_2;
_classExtendsElt = tmp4_3;
tmp4 += 1;
_emod = omc_InstExtends_instClassExtendsList2(threadData, _inEnv, _emod, _name1, _classExtendsElt, _rest ,&_rest);
tmpMeta112 = mmc_mk_cons(_first, _rest);
tmpMeta[0+0] = _emod;
tmpMeta[0+1] = tmpMeta112;
goto tmp3_done;
}
case 3: {
if (!listEmpty(tmp4_4)) goto tmp3_end;
omc_Debug_traceln(threadData, _OMC_LIT34);
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
_outMod = tmpMeta[0+0];
_outElements = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outElements) { *out_outElements = _outElements; }
return _outMod;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_InstExtends_buildClassExtendsName(threadData_t *threadData, modelica_string _inEnvPath, modelica_string _inClassName)
{
modelica_string _outClassName = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = stringAppend(_OMC_LIT35,_inClassName);
tmpMeta2 = stringAppend(tmpMeta1,_OMC_LIT36);
tmpMeta3 = stringAppend(tmpMeta2,_inEnvPath);
_outClassName = tmpMeta3;
_return: OMC_LABEL_UNUSED
return _outClassName;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_instClassExtendsList(threadData_t *threadData, modelica_metatype _inEnv, modelica_metatype _inMod, modelica_metatype _inClassExtendsList, modelica_metatype _inElements, modelica_metatype *out_outElements)
{
modelica_metatype _outMod = NULL;
modelica_metatype _outElements = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inMod;
tmp4_2 = _inClassExtendsList;
tmp4_3 = _inElements;
{
modelica_metatype _first = NULL;
modelica_metatype _rest = NULL;
modelica_string _name = NULL;
modelica_metatype _els = NULL;
modelica_metatype _compelts = NULL;
modelica_metatype _emod = NULL;
modelica_metatype _names = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
_emod = tmp4_1;
_compelts = tmp4_3;
tmp4 += 2;
tmpMeta[0+0] = _emod;
tmpMeta[0+1] = _compelts;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,2,8) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_first = tmpMeta6;
_name = tmpMeta8;
_rest = tmpMeta7;
_emod = tmp4_1;
_compelts = tmp4_3;
_emod = omc_InstExtends_instClassExtendsList2(threadData, _inEnv, _emod, _name, _first, _compelts ,&_compelts);
tmpMeta[0+0] = omc_InstExtends_instClassExtendsList(threadData, _inEnv, _emod, _rest, _compelts, &tmpMeta[0+1]);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_boolean tmp12;
modelica_metatype tmpMeta13;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmp4_2);
tmpMeta10 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,2,8) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
_name = tmpMeta11;
_compelts = tmp4_3;
tmp12 = omc_Flags_isSet(threadData, _OMC_LIT3);
if (1 != tmp12) goto goto_2;
tmpMeta13 = stringAppend(_OMC_LIT37,_name);
omc_Debug_traceln(threadData, tmpMeta13);
omc_Debug_traceln(threadData, _OMC_LIT38);
_els = omc_List_map(threadData, _compelts, boxvar_Util_tuple31);
_names = omc_List_map(threadData, _els, boxvar_SCodeUtil_elementName);
omc_Debug_traceln(threadData, stringDelimitList(_names, _OMC_LIT39));
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
_outMod = tmpMeta[0+0];
_outElements = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outElements) { *out_outElements = _outElements; }
return _outMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_instExtendsAndClassExtendsList2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inExtendsElementLst, modelica_metatype _inClassExtendsElementLst, modelica_metatype _inElementsFromExtendsScope, modelica_metatype _inState, modelica_string _inClassName, modelica_boolean _inImpl, modelica_boolean _isPartialInst, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outMod, modelica_metatype *out_outElements, modelica_metatype *out_outNormalEqs, modelica_metatype *out_outInitialEqs, modelica_metatype *out_outNormalAlgs, modelica_metatype *out_outInitialAlgs, modelica_metatype *out_comments)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outIH = NULL;
modelica_metatype _outMod = NULL;
modelica_metatype _outElements = NULL;
modelica_metatype _outNormalEqs = NULL;
modelica_metatype _outInitialEqs = NULL;
modelica_metatype _outNormalAlgs = NULL;
modelica_metatype _outInitialAlgs = NULL;
modelica_metatype _comments = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCache = omc_InstExtends_instExtendsList(threadData, _inCache, _inEnv, _inIH, _inMod, _inPrefix, _inExtendsElementLst, _inElementsFromExtendsScope, _inState, _inClassName, _inImpl, _isPartialInst ,&_outEnv ,&_outIH ,&_outMod ,&_outElements ,&_outNormalEqs ,&_outInitialEqs ,&_outNormalAlgs ,&_outInitialAlgs ,&_comments);
_outMod = omc_InstExtends_instClassExtendsList(threadData, _inEnv, _outMod, _inClassExtendsElementLst, _outElements ,&_outElements);
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outIH) { *out_outIH = _outIH; }
if (out_outMod) { *out_outMod = _outMod; }
if (out_outElements) { *out_outElements = _outElements; }
if (out_outNormalEqs) { *out_outNormalEqs = _outNormalEqs; }
if (out_outInitialEqs) { *out_outInitialEqs = _outInitialEqs; }
if (out_outNormalAlgs) { *out_outNormalAlgs = _outNormalAlgs; }
if (out_outInitialAlgs) { *out_outInitialAlgs = _outInitialAlgs; }
if (out_comments) { *out_comments = _comments; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstExtends_instExtendsAndClassExtendsList2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inExtendsElementLst, modelica_metatype _inClassExtendsElementLst, modelica_metatype _inElementsFromExtendsScope, modelica_metatype _inState, modelica_metatype _inClassName, modelica_metatype _inImpl, modelica_metatype _isPartialInst, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outMod, modelica_metatype *out_outElements, modelica_metatype *out_outNormalEqs, modelica_metatype *out_outInitialEqs, modelica_metatype *out_outNormalAlgs, modelica_metatype *out_outInitialAlgs, modelica_metatype *out_comments)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inImpl);
tmp2 = mmc_unbox_integer(_isPartialInst);
_outCache = omc_InstExtends_instExtendsAndClassExtendsList2(threadData, _inCache, _inEnv, _inIH, _inMod, _inPrefix, _inExtendsElementLst, _inClassExtendsElementLst, _inElementsFromExtendsScope, _inState, _inClassName, tmp1, tmp2, out_outEnv, out_outIH, out_outMod, out_outElements, out_outNormalEqs, out_outInitialEqs, out_outNormalAlgs, out_outInitialAlgs, out_comments);
return _outCache;
}
DLLExport
modelica_metatype omc_InstExtends_instExtendsAndClassExtendsList(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inExtendsElementLst, modelica_metatype _inClassExtendsElementLst, modelica_metatype _inElementsFromExtendsScope, modelica_metatype _inState, modelica_string _inClassName, modelica_boolean _inImpl, modelica_boolean _isPartialInst, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outMod, modelica_metatype *out_outElements, modelica_metatype *out_outNormalEqs, modelica_metatype *out_outInitialEqs, modelica_metatype *out_outNormalAlgs, modelica_metatype *out_outInitialAlgs, modelica_metatype *out_outComments)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outIH = NULL;
modelica_metatype _outMod = NULL;
modelica_metatype _outElements = NULL;
modelica_metatype _outNormalEqs = NULL;
modelica_metatype _outInitialEqs = NULL;
modelica_metatype _outNormalAlgs = NULL;
modelica_metatype _outInitialAlgs = NULL;
modelica_metatype _outComments = NULL;
modelica_metatype _elts = NULL;
modelica_metatype _cdefelts = NULL;
modelica_metatype _tmpelts = NULL;
modelica_metatype _extendselts = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_extendselts = omc_List_map(threadData, _inExtendsElementLst, boxvar_SCodeInstUtil_expandEnumerationClass);
_outCache = omc_InstExtends_instExtendsAndClassExtendsList2(threadData, _inCache, _inEnv, _inIH, _inMod, _inPrefix, _extendselts, _inClassExtendsElementLst, _inElementsFromExtendsScope, _inState, _inClassName, _inImpl, _isPartialInst ,&_outEnv ,&_outIH ,&_outMod ,&_elts ,&_outNormalEqs ,&_outInitialEqs ,&_outNormalAlgs ,&_outInitialAlgs ,&_outComments);
_outElements = omc_List_map(threadData, _elts, boxvar_Util_tuple312);
_tmpelts = omc_List_map(threadData, _outElements, boxvar_Util_tuple21);
omc_InstUtil_splitEltsNoComponents(threadData, _tmpelts ,&_cdefelts ,NULL ,NULL);
_outCache = omc_InstUtil_addClassdefsToEnv(threadData, _outCache, _outEnv, _outIH, _inPrefix, _cdefelts, _inImpl, mmc_mk_some(_outMod), 0 ,&_outEnv ,&_outIH);
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outIH) { *out_outIH = _outIH; }
if (out_outMod) { *out_outMod = _outMod; }
if (out_outElements) { *out_outElements = _outElements; }
if (out_outNormalEqs) { *out_outNormalEqs = _outNormalEqs; }
if (out_outInitialEqs) { *out_outInitialEqs = _outInitialEqs; }
if (out_outNormalAlgs) { *out_outNormalAlgs = _outNormalAlgs; }
if (out_outInitialAlgs) { *out_outInitialAlgs = _outInitialAlgs; }
if (out_outComments) { *out_outComments = _outComments; }
return _outCache;
}
modelica_metatype boxptr_InstExtends_instExtendsAndClassExtendsList(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inExtendsElementLst, modelica_metatype _inClassExtendsElementLst, modelica_metatype _inElementsFromExtendsScope, modelica_metatype _inState, modelica_metatype _inClassName, modelica_metatype _inImpl, modelica_metatype _isPartialInst, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outMod, modelica_metatype *out_outElements, modelica_metatype *out_outNormalEqs, modelica_metatype *out_outInitialEqs, modelica_metatype *out_outNormalAlgs, modelica_metatype *out_outInitialAlgs, modelica_metatype *out_outComments)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inImpl);
tmp2 = mmc_unbox_integer(_isPartialInst);
_outCache = omc_InstExtends_instExtendsAndClassExtendsList(threadData, _inCache, _inEnv, _inIH, _inMod, _inPrefix, _inExtendsElementLst, _inClassExtendsElementLst, _inElementsFromExtendsScope, _inState, _inClassName, tmp1, tmp2, out_outEnv, out_outIH, out_outMod, out_outElements, out_outNormalEqs, out_outInitialEqs, out_outNormalAlgs, out_outInitialAlgs, out_outComments);
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_updateElementListVisibility(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _inVisibility)
{
modelica_metatype _outElements = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inVisibility;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmpMeta1 = _inElements;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
{
modelica_metatype __omcQ_24tmpVar3;
modelica_metatype* tmp7;
modelica_metatype tmpMeta8;
modelica_metatype __omcQ_24tmpVar2;
modelica_integer tmp9;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _inElements;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta8;
tmp7 = &__omcQ_24tmpVar3;
while(1) {
tmp9 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp9--;
}
if (tmp9 == 0) {
__omcQ_24tmpVar2 = omc_SCodeUtil_makeElementProtected(threadData, _e);
*tmp7 = mmc_mk_cons(__omcQ_24tmpVar2,0);
tmp7 = &MMC_CDR(*tmp7);
} else if (tmp9 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp7 = mmc_mk_nil();
tmpMeta6 = __omcQ_24tmpVar3;
}
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
_outElements = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outElements;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_lookupBaseClass(threadData_t *threadData, modelica_metatype _inPath, modelica_boolean _inSelfReference, modelica_string _inClassName, modelica_metatype _inEnv, modelica_metatype _inCache, modelica_metatype *out_outElement, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outElement = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_boolean tmp4_2;
tmp4_1 = _inPath;
tmp4_2 = _inSelfReference;
{
modelica_string _name = NULL;
modelica_metatype _elem = NULL;
modelica_metatype _env = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _path = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (1 != tmp4_2) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_name = tmpMeta6;
_elem = omc_Lookup_lookupClassLocal(threadData, _inEnv, _name ,&_env);
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = mmc_mk_some(_elem);
tmpMeta[0+2] = _env;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
tmpMeta7 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _inClassName);
_path = omc_AbsynUtil_removePartialPrefix(threadData, tmpMeta7, _inPath);
_cache = omc_Lookup_lookupClass(threadData, _inCache, _inEnv, _path, mmc_mk_none() ,&_elem ,&_env);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = mmc_mk_some(_elem);
tmpMeta[0+2] = _env;
goto tmp3_done;
}
case 2: {
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = mmc_mk_none();
tmpMeta[0+2] = _inEnv;
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
_outElement = tmpMeta[0+1];
_outEnv = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outElement) { *out_outElement = _outElement; }
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstExtends_lookupBaseClass(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inSelfReference, modelica_metatype _inClassName, modelica_metatype _inEnv, modelica_metatype _inCache, modelica_metatype *out_outElement, modelica_metatype *out_outEnv)
{
modelica_integer tmp1;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inSelfReference);
_outCache = omc_InstExtends_lookupBaseClass(threadData, _inPath, tmp1, _inClassName, _inEnv, _inCache, out_outElement, out_outEnv);
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstExtends_instExtendsList(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inLocalElements, modelica_metatype _inElementsFromExtendsScope, modelica_metatype _inState, modelica_string _inClassName, modelica_boolean _inImpl, modelica_boolean _inPartialInst, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outMod, modelica_metatype *out_outElements, modelica_metatype *out_outNormalEqs, modelica_metatype *out_outInitialEqs, modelica_metatype *out_outNormalAlgs, modelica_metatype *out_outInitialAlgs, modelica_metatype *out_outComments)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outIH = NULL;
modelica_metatype _outMod = NULL;
modelica_metatype _outElements = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _outNormalEqs = NULL;
modelica_metatype tmpMeta2;
modelica_metatype _outInitialEqs = NULL;
modelica_metatype tmpMeta3;
modelica_metatype _outNormalAlgs = NULL;
modelica_metatype tmpMeta4;
modelica_metatype _outInitialAlgs = NULL;
modelica_metatype tmpMeta5;
modelica_metatype _outComments = NULL;
modelica_metatype tmpMeta6;
modelica_metatype _duplicates = NULL;
modelica_metatype tmpMeta7;
modelica_metatype _duplicateUnparseStrings = NULL;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta52;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCache = _inCache;
_outEnv = _inEnv;
_outIH = _inIH;
_outMod = _inMod;
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outElements = tmpMeta1;
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
_outNormalEqs = tmpMeta2;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
_outInitialEqs = tmpMeta3;
tmpMeta4 = MMC_REFSTRUCTLIT(mmc_nil);
_outNormalAlgs = tmpMeta4;
tmpMeta5 = MMC_REFSTRUCTLIT(mmc_nil);
_outInitialAlgs = tmpMeta5;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
_outComments = tmpMeta6;
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
_duplicates = tmpMeta7;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
_duplicateUnparseStrings = tmpMeta8;
_duplicates = omc_List_sortedDuplicates(threadData, omc_List_sort(threadData, _inElementsFromExtendsScope, boxvar_SCodeUtil_elementEqual), boxvar_SCodeUtil_elementEqual);
if(omc_Config_acceptMetaModelicaGrammar(threadData))
{
_duplicates = omc_List_filterOnFalse(threadData, _duplicates, boxvar_SCodeUtil_isTypeVar);
}
if((!listEmpty(_duplicates)))
{
{
modelica_metatype __omcQ_24tmpVar5;
modelica_metatype* tmp10;
modelica_metatype tmpMeta11;
modelica_string __omcQ_24tmpVar4;
modelica_integer tmp12;
modelica_metatype _i_loopVar = 0;
modelica_metatype _i;
_i_loopVar = _duplicates;
tmpMeta11 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar5 = tmpMeta11;
tmp10 = &__omcQ_24tmpVar5;
while(1) {
tmp12 = 1;
if (!listEmpty(_i_loopVar)) {
_i = MMC_CAR(_i_loopVar);
_i_loopVar = MMC_CDR(_i_loopVar);
tmp12--;
}
if (tmp12 == 0) {
__omcQ_24tmpVar4 = omc_SCodeDump_unparseElementStr(threadData, _i, _OMC_LIT5);
*tmp10 = mmc_mk_cons(__omcQ_24tmpVar4,0);
tmp10 = &MMC_CDR(*tmp10);
} else if (tmp12 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp10 = mmc_mk_nil();
tmpMeta9 = __omcQ_24tmpVar5;
}
_duplicateUnparseStrings = tmpMeta9;
if((listLength(_duplicates) > ((modelica_integer) 1)))
{
omc_Error_addMultiSourceMessage(threadData, _OMC_LIT42, _duplicateUnparseStrings, omc_List_map(threadData, _duplicates, boxvar_SCodeUtil_elementInfo));
}
else
{
omc_Error_addSourceMessage(threadData, _OMC_LIT42, _duplicateUnparseStrings, omc_SCodeUtil_elementInfo(threadData, listHead(_duplicates)));
}
MMC_THROW_INTERNAL();
}
{
modelica_metatype _el;
for (tmpMeta13 = listReverse(_inLocalElements); !listEmpty(tmpMeta13); tmpMeta13=MMC_CDR(tmpMeta13))
{
_el = MMC_CAR(tmpMeta13);
{
volatile modelica_metatype tmp16_1;
tmp16_1 = _el;
{
modelica_string _cn = NULL;
modelica_string _bc_str = NULL;
modelica_string _scope_str = NULL;
modelica_string _base_first_id = NULL;
modelica_metatype _emod = NULL;
modelica_boolean _eq_name;
modelica_metatype _ocls = NULL;
modelica_metatype _cls = NULL;
modelica_metatype _cenv = NULL;
modelica_metatype _encf = NULL;
modelica_metatype _els1 = NULL;
modelica_metatype _rest_els = NULL;
modelica_metatype _import_els = NULL;
modelica_metatype _cdef_els = NULL;
modelica_metatype _clsext_els = NULL;
modelica_metatype _els2 = NULL;
modelica_metatype _eq1 = NULL;
modelica_metatype _ieq1 = NULL;
modelica_metatype _eq2 = NULL;
modelica_metatype _ieq2 = NULL;
modelica_metatype _alg1 = NULL;
modelica_metatype _ialg1 = NULL;
modelica_metatype _alg2 = NULL;
modelica_metatype _ialg2 = NULL;
modelica_metatype _comments1 = NULL;
modelica_metatype _comments2 = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _tree = NULL;
modelica_metatype _cacheArr = NULL;
modelica_boolean _htHasEntries;
volatile mmc_switch_type tmp16;
int tmp17;
tmp16 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp15_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp16 < 7; tmp16++) {
switch (MMC_SWITCH_CAST(tmp16)) {
case 0: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_boolean tmp20;
if (mmc__uniontype__metarecord__typedef__equal(tmp16_1,1,5) == 0) goto tmp15_end;
tmpMeta18 = omc_AbsynUtil_makeNotFullyQualified(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_el), 2))));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,1,1) == 0) goto goto_14;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
_cn = tmpMeta19;
tmp20 = omc_InstUtil_isBuiltInClass(threadData, _cn);
if (1 != tmp20) goto goto_14;
goto tmp15_done;
}
case 1: {
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
if (mmc__uniontype__metarecord__typedef__equal(tmp16_1,1,5) == 0) goto tmp15_end;
_emod = omc_InstUtil_chainRedeclares(threadData, _outMod, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_el), 4))));
_base_first_id = omc_AbsynUtil_pathFirstIdent(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_el), 2))));
_eq_name = ((stringEqual(_inClassName, _base_first_id)) && omc_AbsynUtil_pathEqual(threadData, omc_ClassInf_getStateName(threadData, _inState), omc_AbsynUtil_joinPaths(threadData, omc_FGraph_getGraphName(threadData, _outEnv), omc_AbsynUtil_makeIdentPathFromString(threadData, _base_first_id))));
_outCache = omc_InstExtends_lookupBaseClass(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_el), 2))), _eq_name, _inClassName, _outEnv, _outCache ,&_ocls ,&_cenv);
if(isSome(_ocls))
{
tmpMeta21 = _ocls;
if (optionNone(tmpMeta21)) goto goto_14;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 1));
_cls = tmpMeta22;
tmpMeta23 = _cls;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta23,2,8) == 0) goto goto_14;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 2));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 4));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 8));
_cn = tmpMeta24;
_encf = tmpMeta25;
_cmt = tmpMeta26;
}
else
{
if(omc_Flags_getConfigBool(threadData, _OMC_LIT51))
{
_bc_str = omc_AbsynUtil_pathString(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_el), 2))), _OMC_LIT33, 1, 0);
_scope_str = omc_FGraph_printGraphPathStr(threadData, _inEnv);
tmpMeta27 = mmc_mk_cons(_bc_str, mmc_mk_cons(_scope_str, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT45, tmpMeta27, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_el), 6))));
}
goto goto_14;
}
_outCache = omc_InstExtends_instDerivedClasses(threadData, _outCache, _cenv, _outIH, _outMod, _inPrefix, _cls, _inImpl, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_el), 6))) ,&_cenv ,&_outIH ,&_els1 ,&_eq1 ,&_ieq1 ,&_alg1 ,&_ialg1 ,&_mod ,&_comments1);
_els1 = omc_InstExtends_updateElementListVisibility(threadData, _els1, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_el), 3))));
_tree = omc_AvlSetString_new(threadData);
_tree = omc_InstExtends_getLocalIdentList(threadData, omc_InstUtil_constantAndParameterEls(threadData, _inElementsFromExtendsScope), _tree, boxvar_InstExtends_getLocalIdentElement);
_tree = omc_InstExtends_getLocalIdentList(threadData, omc_InstUtil_constantAndParameterEls(threadData, _els1), _tree, boxvar_InstExtends_getLocalIdentElement);
_cacheArr = arrayCreate(((modelica_integer) 1), _outCache);
_emod = omc_InstExtends_fixModifications(threadData, _cacheArr, _inEnv, _emod, _tree);
_cenv = omc_FGraph_openScope(threadData, _cenv, _encf, _cn, omc_FGraph_classInfToScopeType(threadData, _inState));
_import_els = omc_InstUtil_splitEltsNoComponents(threadData, _els1 ,&_cdef_els ,&_clsext_els ,&_rest_els);
_outCache = omc_InstUtil_addClassdefsToEnv(threadData, _outCache, _cenv, _outIH, _inPrefix, _import_els, _inImpl, mmc_mk_none(), 0 ,&_cenv ,&_outIH);
_outCache = omc_InstUtil_addClassdefsToEnv(threadData, _outCache, _cenv, _outIH, _inPrefix, _cdef_els, _inImpl, mmc_mk_some(_mod), 0 ,&_cenv ,&_outIH);
{
modelica_metatype __omcQ_24tmpVar7;
modelica_metatype* tmp29;
modelica_metatype tmpMeta30;
modelica_metatype __omcQ_24tmpVar6;
modelica_integer tmp31;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _rest_els;
tmpMeta30 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar7 = tmpMeta30;
tmp29 = &__omcQ_24tmpVar7;
while(1) {
tmp31 = 1;
while (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
if (omc_SCodeUtil_isRedeclareElement(threadData, _e)) {
tmp31--;
break;
}
}
if (tmp31 == 0) {
__omcQ_24tmpVar6 = _e;
*tmp29 = mmc_mk_cons(__omcQ_24tmpVar6,0);
tmp29 = &MMC_CDR(*tmp29);
} else if (tmp31 == 1) {
break;
} else {
goto goto_14;
}
}
*tmp29 = mmc_mk_nil();
tmpMeta28 = __omcQ_24tmpVar7;
}
_rest_els = omc_SCodeInstUtil_addRedeclareAsElementsToExtends(threadData, _rest_els, tmpMeta28);
tmpMeta32 = mmc_mk_box2(4, &Mod_ModScope_EXTENDS__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_el), 2))));
_outMod = omc_Mod_elabUntypedMod(threadData, _emod, tmpMeta32);
_outMod = omc_Mod_merge(threadData, _mod, _outMod, _OMC_LIT27, 0);
_outCache = omc_InstExtends_instExtendsAndClassExtendsList2(threadData, _outCache, _cenv, _outIH, _outMod, _inPrefix, _rest_els, _clsext_els, _els1, _inState, _inClassName, _inImpl, _inPartialInst ,NULL ,&_outIH ,NULL ,&_els2 ,&_eq2 ,&_ieq2 ,&_alg2 ,&_ialg2 ,&_comments2);
_tree = omc_AvlSetString_new(threadData);
_tree = omc_InstExtends_getLocalIdentList(threadData, _els2, _tree, boxvar_InstExtends_getLocalIdentElementTpl);
_tree = omc_InstExtends_getLocalIdentList(threadData, _cdef_els, _tree, boxvar_InstExtends_getLocalIdentElement);
_tree = omc_InstExtends_getLocalIdentList(threadData, _import_els, _tree, boxvar_InstExtends_getLocalIdentElement);
_htHasEntries = (!omc_AvlSetString_isEmpty(threadData, _tree));
arrayUpdate(_cacheArr, ((modelica_integer) 1), _outCache);
if(_htHasEntries)
{
_els2 = omc_InstExtends_fixList(threadData, _cacheArr, _cenv, _els2, _tree, boxvar_InstExtends_fixLocalIdent);
}
_outElements = listAppend(_els2, _outElements);
_outNormalEqs = omc_List_unionAppendListOnTrue(threadData, listReverse(_eq2), _outNormalEqs, boxvar_valueEq);
_outInitialEqs = omc_List_unionAppendListOnTrue(threadData, listReverse(_ieq2), _outInitialEqs, boxvar_valueEq);
_outNormalAlgs = omc_List_unionAppendListOnTrue(threadData, listReverse(_alg2), _outNormalAlgs, boxvar_valueEq);
_outInitialAlgs = omc_List_unionAppendListOnTrue(threadData, listReverse(_ialg2), _outInitialAlgs, boxvar_valueEq);
tmpMeta33 = mmc_mk_cons(_cmt, _outComments);
_outComments = listAppend(_comments1, listAppend(_comments2, tmpMeta33));
if((!_inPartialInst))
{
if(_htHasEntries)
{
_eq1 = omc_InstExtends_fixList(threadData, _cacheArr, _cenv, _eq1, _tree, boxvar_InstExtends_fixEquation);
_ieq1 = omc_InstExtends_fixList(threadData, _cacheArr, _cenv, _ieq1, _tree, boxvar_InstExtends_fixEquation);
_alg1 = omc_InstExtends_fixList(threadData, _cacheArr, _cenv, _alg1, _tree, boxvar_InstExtends_fixAlgorithm);
_ialg1 = omc_InstExtends_fixList(threadData, _cacheArr, _cenv, _ialg1, _tree, boxvar_InstExtends_fixAlgorithm);
}
_outNormalEqs = omc_List_unionAppendListOnTrue(threadData, listReverse(_eq1), _outNormalEqs, boxvar_valueEq);
_outInitialEqs = omc_List_unionAppendListOnTrue(threadData, listReverse(_ieq1), _outInitialEqs, boxvar_valueEq);
_outNormalAlgs = omc_List_unionAppendListOnTrue(threadData, listReverse(_alg1), _outNormalAlgs, boxvar_valueEq);
_outInitialAlgs = omc_List_unionAppendListOnTrue(threadData, listReverse(_ialg1), _outInitialAlgs, boxvar_valueEq);
}
_outCache = arrayGet(_cacheArr, ((modelica_integer) 1));
goto tmp15_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp16_1,1,5) == 0) goto tmp15_end;
tmp16 += 3;
if (!omc_Flags_getConfigBool(threadData, _OMC_LIT51)) goto tmp15_end;
goto tmp15_done;
}
case 3: {
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
if (mmc__uniontype__metarecord__typedef__equal(tmp16_1,3,8) == 0) goto tmp15_end;
tmp16 += 2;
if((omc_SCodeUtil_isConstant(threadData, omc_SCodeUtil_attrVariability(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_el), 4))))) || (!_inPartialInst)))
{
tmpMeta35 = mmc_mk_box3(0, _el, _OMC_LIT14, mmc_mk_boolean(0));
tmpMeta34 = mmc_mk_cons(tmpMeta35, _outElements);
_outElements = tmpMeta34;
}
goto tmp15_done;
}
case 4: {
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
if (mmc__uniontype__metarecord__typedef__equal(tmp16_1,2,8) == 0) goto tmp15_end;
tmp16 += 1;
tmpMeta37 = mmc_mk_box3(0, _el, _OMC_LIT14, mmc_mk_boolean(0));
tmpMeta36 = mmc_mk_cons(tmpMeta37, _outElements);
_outElements = tmpMeta36;
tmpMeta38 = mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_el), 8))), MMC_REFSTRUCTLIT(mmc_nil));
_outComments = tmpMeta38;
goto tmp15_done;
}
case 5: {
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
if (mmc__uniontype__metarecord__typedef__equal(tmp16_1,0,3) == 0) goto tmp15_end;
tmpMeta40 = mmc_mk_box3(0, _el, _OMC_LIT14, mmc_mk_boolean(0));
tmpMeta39 = mmc_mk_cons(tmpMeta40, _outElements);
_outElements = tmpMeta39;
goto tmp15_done;
}
case 6: {
modelica_boolean tmp41;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
tmp41 = omc_Flags_isSet(threadData, _OMC_LIT3);
if (1 != tmp41) goto goto_14;
tmpMeta42 = stringAppend(_OMC_LIT52,_inClassName);
tmpMeta43 = stringAppend(tmpMeta42,_OMC_LIT53);
tmpMeta44 = stringAppend(tmpMeta43,_OMC_LIT54);
tmpMeta45 = stringAppend(tmpMeta44,omc_FGraph_printGraphPathStr(threadData, _outEnv));
tmpMeta46 = stringAppend(tmpMeta45,_OMC_LIT53);
tmpMeta47 = stringAppend(tmpMeta46,_OMC_LIT55);
tmpMeta48 = stringAppend(tmpMeta47,omc_Mod_printModStr(threadData, _outMod));
tmpMeta49 = stringAppend(tmpMeta48,_OMC_LIT53);
tmpMeta50 = stringAppend(tmpMeta49,_OMC_LIT56);
tmpMeta51 = stringAppend(tmpMeta50,omc_SCodeDump_unparseElementStr(threadData, _el, _OMC_LIT5));
omc_Debug_traceln(threadData, tmpMeta51);
goto goto_14;
goto tmp15_done;
}
}
goto tmp15_end;
tmp15_end: ;
}
goto goto_14;
tmp15_done:
(void)tmp16;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp15_done2;
goto_14:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp16 < 7) {
goto tmp15_top;
}
MMC_THROW_INTERNAL();
tmp15_done2:;
}
}
;
}
}
_outElements = omc_InstExtends_updateComponentsAndClassdefs(threadData, _outElements, _outMod, _inEnv ,&_outMod);
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outIH) { *out_outIH = _outIH; }
if (out_outMod) { *out_outMod = _outMod; }
if (out_outElements) { *out_outElements = _outElements; }
if (out_outNormalEqs) { *out_outNormalEqs = _outNormalEqs; }
if (out_outInitialEqs) { *out_outInitialEqs = _outInitialEqs; }
if (out_outNormalAlgs) { *out_outNormalAlgs = _outNormalAlgs; }
if (out_outInitialAlgs) { *out_outInitialAlgs = _outInitialAlgs; }
if (out_outComments) { *out_outComments = _outComments; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstExtends_instExtendsList(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inLocalElements, modelica_metatype _inElementsFromExtendsScope, modelica_metatype _inState, modelica_metatype _inClassName, modelica_metatype _inImpl, modelica_metatype _inPartialInst, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outMod, modelica_metatype *out_outElements, modelica_metatype *out_outNormalEqs, modelica_metatype *out_outInitialEqs, modelica_metatype *out_outNormalAlgs, modelica_metatype *out_outInitialAlgs, modelica_metatype *out_outComments)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inImpl);
tmp2 = mmc_unbox_integer(_inPartialInst);
_outCache = omc_InstExtends_instExtendsList(threadData, _inCache, _inEnv, _inIH, _inMod, _inPrefix, _inLocalElements, _inElementsFromExtendsScope, _inState, _inClassName, tmp1, tmp2, out_outEnv, out_outIH, out_outMod, out_outElements, out_outNormalEqs, out_outInitialEqs, out_outNormalAlgs, out_outInitialAlgs, out_outComments);
return _outCache;
}
