#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "InnerOuter.c"
#endif
#include "omc_simulation_settings.h"
#include "InnerOuter.h"
#define _OMC_LIT0_data "-InstHierarchyHashTable.valueArrayClearnth failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,50,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "-InstHierarchyHashTable.valueArraySetnth failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,48,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "-InstHierarchyHashTable.valueArrayAdd failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,45,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "-InstHierarchyHashTable.delete failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,38,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "content:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,8,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "- InnerOuter.addNoUpdCheck failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,34,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "- InnerOuter.add failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,24,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "{"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,1,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data " opaque InstInner for now, implement printing. "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,47,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "}\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,2,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "InstHierarchyHashTable:\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,24,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,1,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "There are no 'inner' components defined in the model in any of the parent scopes of 'outer' component's scope: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,111,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,1,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data "\n    "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,5,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,0,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data " Referenced by 'outer' components: {"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,36,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data ", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,2,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
#define _OMC_LIT18_data "}"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT18,1,_OMC_LIT18_data);
#define _OMC_LIT18 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT18)
#define _OMC_LIT19_data " "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT19,1,_OMC_LIT19_data);
#define _OMC_LIT19 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data "; defined in scope: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,20,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
#define _OMC_LIT21_data "failtrace"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT21,9,_OMC_LIT21_data);
#define _OMC_LIT21 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "Sets whether to print a failtrace or not."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,41,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT23,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT22}};
#define _OMC_LIT23 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT23)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT24,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT21,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT23}};
#define _OMC_LIT24 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT24)
#define _OMC_LIT25_data "InnerOuter.addOuterPrefix failed to add: outer cref: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT25,53,_OMC_LIT25_data);
#define _OMC_LIT25 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data " refers to inner cref: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,23,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data " to IH"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,6,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data "instance"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,8,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data "Prints extra failtrace from InstanceHierarchy."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,46,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT30,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT29}};
#define _OMC_LIT30 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT30)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT31,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(16)),_OMC_LIT28,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT30}};
#define _OMC_LIT31 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT31)
#define _OMC_LIT32_data "InnerOuter.updateSMHierarchy failure for: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT32,42,_OMC_LIT32_data);
#define _OMC_LIT32 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT32)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT33,1,11) {&DAE_Type_T__UNKNOWN__desc,}};
#define _OMC_LIT33 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT33)
#define _OMC_LIT34_data "InnerOuter.lookupInnerVar failed on component: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT34,47,_OMC_LIT34_data);
#define _OMC_LIT34 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT34)
#define _OMC_LIT35_data "/"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT35,1,_OMC_LIT35_data);
#define _OMC_LIT35 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT35)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT36,1,6) {&Absyn_InnerOuter_NOT__INNER__OUTER__desc,}};
#define _OMC_LIT36 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT36)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT37,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT15}};
#define _OMC_LIT37 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT37)
#define _OMC_LIT38_data "$it"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT38,3,_OMC_LIT38_data);
#define _OMC_LIT38 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT38)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT39,1,4) {&Absyn_InnerOuter_OUTER__desc,}};
#define _OMC_LIT39 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT39)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT40,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT40 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT40)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT41,1,5) {&ErrorTypes_Severity_WARNING__desc,}};
#define _OMC_LIT41 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT41)
#define _OMC_LIT42_data "Ignoring the modification on outer element: %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT42,47,_OMC_LIT42_data);
#define _OMC_LIT42 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT42)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT43,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT42}};
#define _OMC_LIT43 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT43)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT44,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(512)),_OMC_LIT40,_OMC_LIT41,_OMC_LIT43}};
#define _OMC_LIT44 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT44)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT45,1,3) {&DAE_Prefix_NOPRE__desc,}};
#define _OMC_LIT45 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT45)
#define _OMC_LIT46_data "checkModel"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT46,10,_OMC_LIT46_data);
#define _OMC_LIT46 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT46)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT47,1,3) {&Flags_FlagVisibility_INTERNAL__desc,}};
#define _OMC_LIT47 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT47)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT48,2,4) {&Flags_FlagData_BOOL__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT48 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT48)
#define _OMC_LIT49_data "Set when checkModel is used to turn on specific features for checking."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT49,70,_OMC_LIT49_data);
#define _OMC_LIT49 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT49)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT50,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT49}};
#define _OMC_LIT50 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT50)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT51,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(31)),_OMC_LIT46,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT47,_OMC_LIT48,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT50}};
#define _OMC_LIT51 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT51)
#define _OMC_LIT52_data "No corresponding 'inner' declaration found for component %s declared as '%s'.\n  The existing 'inner' components are:\n    %s\n  Check if you have not misspelled the 'outer' component name.\n  Please declare an 'inner' component with the same name in the top scope.\n  Continuing flattening by only considering the 'outer' component declaration."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT52,340,_OMC_LIT52_data);
#define _OMC_LIT52 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT52)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT53,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT52}};
#define _OMC_LIT53 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT53)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT54,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(108)),_OMC_LIT40,_OMC_LIT41,_OMC_LIT53}};
#define _OMC_LIT54 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT54)
#define _OMC_LIT55_data "lookupVarInnerOuterAttr"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT55,23,_OMC_LIT55_data);
#define _OMC_LIT55 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT55)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT56,1,3) {&Absyn_InnerOuter_INNER__desc,}};
#define _OMC_LIT56 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT56)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT57,7,3) {&ConnectionGraph_ConnectionGraph_GRAPH__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT57 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT57)
#define _OMC_LIT58_data "failure in: addOuterConnectIfEmptyNOENV\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT58,40,_OMC_LIT58_data);
#define _OMC_LIT58 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT58)
#define _OMC_LIT59_data "- InnerOuter.handleInnerOuterEquations failed!\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT59,47,_OMC_LIT59_data);
#define _OMC_LIT59 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT59)
#include "util/modelica.h"
#include "InnerOuter_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_searchForInnerPrefix(threadData_t *threadData, modelica_metatype _fullCref, modelica_metatype _inOuterCref, modelica_metatype _outerPrefixes, modelica_metatype *out_innerCrefPrefix);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InnerOuter_searchForInnerPrefix,2,0) {(void*) boxptr_InnerOuter_searchForInnerPrefix,0}};
#define boxvar_InnerOuter_searchForInnerPrefix MMC_REFSTRUCTLIT(boxvar_lit_InnerOuter_searchForInnerPrefix)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_changeOuterReferenceToInnerReference(threadData_t *threadData, modelica_metatype _inFullCref, modelica_metatype _inOuterCrefPrefix, modelica_metatype _inInnerCrefPrefix);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InnerOuter_changeOuterReferenceToInnerReference,2,0) {(void*) boxptr_InnerOuter_changeOuterReferenceToInnerReference,0}};
#define boxvar_InnerOuter_changeOuterReferenceToInnerReference MMC_REFSTRUCTLIT(boxvar_lit_InnerOuter_changeOuterReferenceToInnerReference)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_switchInnerToOuterInChildrenValue(threadData_t *threadData, modelica_metatype _inNode, modelica_metatype _inCr);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InnerOuter_switchInnerToOuterInChildrenValue,2,0) {(void*) boxptr_InnerOuter_switchInnerToOuterInChildrenValue,0}};
#define boxvar_InnerOuter_switchInnerToOuterInChildrenValue MMC_REFSTRUCTLIT(boxvar_lit_InnerOuter_switchInnerToOuterInChildrenValue)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_switchInnerToOuterInChild(threadData_t *threadData, modelica_string _name, modelica_metatype _cr, modelica_metatype _inRef);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InnerOuter_switchInnerToOuterInChild,2,0) {(void*) boxptr_InnerOuter_switchInnerToOuterInChild,0}};
#define boxvar_InnerOuter_switchInnerToOuterInChild MMC_REFSTRUCTLIT(boxvar_lit_InnerOuter_switchInnerToOuterInChild)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_switchInnerToOuterInNode(threadData_t *threadData, modelica_metatype _inNode, modelica_metatype _inCr);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InnerOuter_switchInnerToOuterInNode,2,0) {(void*) boxptr_InnerOuter_switchInnerToOuterInNode,0}};
#define boxvar_InnerOuter_switchInnerToOuterInNode MMC_REFSTRUCTLIT(boxvar_lit_InnerOuter_switchInnerToOuterInNode)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_lookupInnerInIH(threadData_t *threadData, modelica_metatype _inTIH, modelica_metatype _inPrefix, modelica_string _inComponentIdent);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InnerOuter_lookupInnerInIH,2,0) {(void*) boxptr_InnerOuter_lookupInnerInIH,0}};
#define boxvar_InnerOuter_lookupInnerInIH MMC_REFSTRUCTLIT(boxvar_lit_InnerOuter_lookupInnerInIH)
PROTECTED_FUNCTION_STATIC void omc_InnerOuter_checkMissingInnerDecl2(threadData_t *threadData, modelica_metatype _outerVar, modelica_metatype _innerVars);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InnerOuter_checkMissingInnerDecl2,2,0) {(void*) boxptr_InnerOuter_checkMissingInnerDecl2,0}};
#define boxvar_InnerOuter_checkMissingInnerDecl2 MMC_REFSTRUCTLIT(boxvar_lit_InnerOuter_checkMissingInnerDecl2)
PROTECTED_FUNCTION_STATIC void omc_InnerOuter_checkMissingInnerDecl1(threadData_t *threadData, modelica_metatype _innerVarsDae, modelica_metatype _outerVarsDae);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InnerOuter_checkMissingInnerDecl1,2,0) {(void*) boxptr_InnerOuter_checkMissingInnerDecl1,0}};
#define boxvar_InnerOuter_checkMissingInnerDecl1 MMC_REFSTRUCTLIT(boxvar_lit_InnerOuter_checkMissingInnerDecl1)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_InnerOuter_lookupVarInnerOuterAttr(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _inIH, modelica_metatype _cr1, modelica_metatype _cr2, modelica_boolean *out_isOuter);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InnerOuter_lookupVarInnerOuterAttr(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _inIH, modelica_metatype _cr1, modelica_metatype _cr2, modelica_metatype *out_isOuter);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InnerOuter_lookupVarInnerOuterAttr,2,0) {(void*) boxptr_InnerOuter_lookupVarInnerOuterAttr,0}};
#define boxvar_InnerOuter_lookupVarInnerOuterAttr MMC_REFSTRUCTLIT(boxvar_lit_InnerOuter_lookupVarInnerOuterAttr)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_removeOuter(threadData_t *threadData, modelica_metatype _io);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InnerOuter_removeOuter,2,0) {(void*) boxptr_InnerOuter_removeOuter,0}};
#define boxvar_InnerOuter_removeOuter MMC_REFSTRUCTLIT(boxvar_lit_InnerOuter_removeOuter)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_addOuterConnectIfEmptyNoEnv(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPre, modelica_metatype _inSets, modelica_boolean _added, modelica_metatype _cr1, modelica_metatype _iio1, modelica_metatype _f1, modelica_metatype _cr2, modelica_metatype _iio2, modelica_metatype _f2, modelica_metatype _info);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InnerOuter_addOuterConnectIfEmptyNoEnv(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPre, modelica_metatype _inSets, modelica_metatype _added, modelica_metatype _cr1, modelica_metatype _iio1, modelica_metatype _f1, modelica_metatype _cr2, modelica_metatype _iio2, modelica_metatype _f2, modelica_metatype _info);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InnerOuter_addOuterConnectIfEmptyNoEnv,2,0) {(void*) boxptr_InnerOuter_addOuterConnectIfEmptyNoEnv,0}};
#define boxvar_InnerOuter_addOuterConnectIfEmptyNoEnv MMC_REFSTRUCTLIT(boxvar_lit_InnerOuter_addOuterConnectIfEmptyNoEnv)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_addOuterConnectIfEmpty(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _pre, modelica_metatype _inSets, modelica_boolean _added, modelica_metatype _cr1, modelica_metatype _iio1, modelica_metatype _f1, modelica_metatype _cr2, modelica_metatype _iio2, modelica_metatype _f2, modelica_metatype _info, modelica_metatype _inCGraph, modelica_metatype *out_outCGraph);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InnerOuter_addOuterConnectIfEmpty(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _pre, modelica_metatype _inSets, modelica_metatype _added, modelica_metatype _cr1, modelica_metatype _iio1, modelica_metatype _f1, modelica_metatype _cr2, modelica_metatype _iio2, modelica_metatype _f2, modelica_metatype _info, modelica_metatype _inCGraph, modelica_metatype *out_outCGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InnerOuter_addOuterConnectIfEmpty,2,0) {(void*) boxptr_InnerOuter_addOuterConnectIfEmpty,0}};
#define boxvar_InnerOuter_addOuterConnectIfEmpty MMC_REFSTRUCTLIT(boxvar_lit_InnerOuter_addOuterConnectIfEmpty)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_convertInnerOuterInnerToOuter(threadData_t *threadData, modelica_metatype _io);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InnerOuter_convertInnerOuterInnerToOuter,2,0) {(void*) boxptr_InnerOuter_convertInnerOuterInnerToOuter,0}};
#define boxvar_InnerOuter_convertInnerOuterInnerToOuter MMC_REFSTRUCTLIT(boxvar_lit_InnerOuter_convertInnerOuterInnerToOuter)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_retrieveOuterConnections2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPrefix, modelica_metatype _inOuterConnects, modelica_metatype _inSets, modelica_boolean _inTopCall, modelica_metatype _inCGraph, modelica_metatype *out_outSets, modelica_metatype *out_outInnerOuterConnects, modelica_metatype *out_outCGraph);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InnerOuter_retrieveOuterConnections2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPrefix, modelica_metatype _inOuterConnects, modelica_metatype _inSets, modelica_metatype _inTopCall, modelica_metatype _inCGraph, modelica_metatype *out_outSets, modelica_metatype *out_outInnerOuterConnects, modelica_metatype *out_outCGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InnerOuter_retrieveOuterConnections2,2,0) {(void*) boxptr_InnerOuter_retrieveOuterConnections2,0}};
#define boxvar_InnerOuter_retrieveOuterConnections2 MMC_REFSTRUCTLIT(boxvar_lit_InnerOuter_retrieveOuterConnections2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_removeInnerPrefixFromCref(threadData_t *threadData, modelica_metatype _inPrefix, modelica_metatype _inCref);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InnerOuter_removeInnerPrefixFromCref,2,0) {(void*) boxptr_InnerOuter_removeInnerPrefixFromCref,0}};
#define boxvar_InnerOuter_removeInnerPrefixFromCref MMC_REFSTRUCTLIT(boxvar_lit_InnerOuter_removeInnerPrefixFromCref)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_extractCommonPart(threadData_t *threadData, modelica_metatype _prefixedCref, modelica_metatype _innerCref);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InnerOuter_extractCommonPart,2,0) {(void*) boxptr_InnerOuter_extractCommonPart,0}};
#define boxvar_InnerOuter_extractCommonPart MMC_REFSTRUCTLIT(boxvar_lit_InnerOuter_extractCommonPart)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_stripCommonCrefPart(threadData_t *threadData, modelica_metatype _outerCr, modelica_metatype _innerCr, modelica_metatype *out_outInnerCr);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InnerOuter_stripCommonCrefPart,2,0) {(void*) boxptr_InnerOuter_stripCommonCrefPart,0}};
#define boxvar_InnerOuter_stripCommonCrefPart MMC_REFSTRUCTLIT(boxvar_lit_InnerOuter_stripCommonCrefPart)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_InnerOuter_isInnerOuterMatch(threadData_t *threadData, modelica_metatype _outerCr, modelica_metatype _innerCr);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InnerOuter_isInnerOuterMatch(threadData_t *threadData, modelica_metatype _outerCr, modelica_metatype _innerCr);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InnerOuter_isInnerOuterMatch,2,0) {(void*) boxptr_InnerOuter_isInnerOuterMatch,0}};
#define boxvar_InnerOuter_isInnerOuterMatch MMC_REFSTRUCTLIT(boxvar_lit_InnerOuter_isInnerOuterMatch)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_buildInnerOuterReplVar(threadData_t *threadData, modelica_metatype _innerVar, modelica_metatype _outerVars, modelica_metatype _inRepl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InnerOuter_buildInnerOuterReplVar,2,0) {(void*) boxptr_InnerOuter_buildInnerOuterReplVar,0}};
#define boxvar_InnerOuter_buildInnerOuterReplVar MMC_REFSTRUCTLIT(boxvar_lit_InnerOuter_buildInnerOuterReplVar)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_buildInnerOuterRepl(threadData_t *threadData, modelica_metatype _innerVars, modelica_metatype _outerVars, modelica_metatype _inRepl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InnerOuter_buildInnerOuterRepl,2,0) {(void*) boxptr_InnerOuter_buildInnerOuterRepl,0}};
#define boxvar_InnerOuter_buildInnerOuterRepl MMC_REFSTRUCTLIT(boxvar_lit_InnerOuter_buildInnerOuterRepl)
DLLExport
modelica_metatype omc_InnerOuter_valueArrayNth(threadData_t *threadData, modelica_metatype _valueArray, modelica_integer _pos, modelica_metatype *out_value)
{
modelica_metatype _key = NULL;
modelica_metatype _value = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _valueArray;
{
modelica_metatype _k = NULL;
modelica_metatype _v = NULL;
modelica_integer _n;
modelica_metatype _arr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_n = tmp7;
_arr = tmpMeta8;
if((!(_pos < _n)))
{
goto goto_2;
}
tmpMeta9 = arrayGet(_arr,((modelica_integer) 1) + _pos);
if (optionNone(tmpMeta9)) goto goto_2;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 1));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 1));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_k = tmpMeta11;
_v = tmpMeta12;
tmpMeta[0+0] = _k;
tmpMeta[0+1] = _v;
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
_key = tmpMeta[0+0];
_value = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_value) { *out_value = _value; }
return _key;
}
modelica_metatype boxptr_InnerOuter_valueArrayNth(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _pos, modelica_metatype *out_value)
{
modelica_integer tmp1;
modelica_metatype _key = NULL;
tmp1 = mmc_unbox_integer(_pos);
_key = omc_InnerOuter_valueArrayNth(threadData, _valueArray, tmp1, out_value);
return _key;
}
DLLExport
modelica_metatype omc_InnerOuter_valueArrayClearnth(threadData_t *threadData, modelica_metatype _valueArray, modelica_integer _pos)
{
modelica_metatype _outValueArray = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _valueArray;
{
modelica_metatype _arr = NULL;
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
_arr = tmpMeta6;
if((!(_pos < arrayLength(_arr))))
{
goto goto_2;
}
arrayUpdate(_arr, ((modelica_integer) 1) + _pos, mmc_mk_none());
tmpMeta1 = _valueArray;
goto tmp3_done;
}
case 1: {
fputs(MMC_STRINGDATA(_OMC_LIT0),stdout);
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
_outValueArray = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outValueArray;
}
modelica_metatype boxptr_InnerOuter_valueArrayClearnth(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _pos)
{
modelica_integer tmp1;
modelica_metatype _outValueArray = NULL;
tmp1 = mmc_unbox_integer(_pos);
_outValueArray = omc_InnerOuter_valueArrayClearnth(threadData, _valueArray, tmp1);
return _outValueArray;
}
DLLExport
modelica_metatype omc_InnerOuter_valueArraySetnth(threadData_t *threadData, modelica_metatype _valueArray, modelica_integer _pos, modelica_metatype _entry)
{
modelica_metatype _outValueArray = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _valueArray;
{
modelica_metatype _arr = NULL;
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
_arr = tmpMeta6;
if((!(_pos < arrayLength(_arr))))
{
goto goto_2;
}
arrayUpdate(_arr, ((modelica_integer) 1) + _pos, mmc_mk_some(_entry));
tmpMeta1 = _valueArray;
goto tmp3_done;
}
case 1: {
fputs(MMC_STRINGDATA(_OMC_LIT1),stdout);
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
_outValueArray = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outValueArray;
}
modelica_metatype boxptr_InnerOuter_valueArraySetnth(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _pos, modelica_metatype _entry)
{
modelica_integer tmp1;
modelica_metatype _outValueArray = NULL;
tmp1 = mmc_unbox_integer(_pos);
_outValueArray = omc_InnerOuter_valueArraySetnth(threadData, _valueArray, tmp1, _entry);
return _outValueArray;
}
DLLExport
modelica_metatype omc_InnerOuter_valueArrayAdd(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _entry)
{
modelica_metatype _outValueArray = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _valueArray;
{
modelica_integer _n_1;
modelica_integer _n;
modelica_integer _size;
modelica_integer _expandsize;
modelica_integer _expandsize_1;
modelica_metatype _arr_1 = NULL;
modelica_metatype _arr = NULL;
modelica_metatype _arr_2 = NULL;
modelica_real _rsize;
modelica_real _rexpandsize;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_n = tmp7;
_arr = tmpMeta8;
if((!(_n < arrayLength(_arr))))
{
goto goto_2;
}
_n_1 = ((modelica_integer) 1) + _n;
_arr_1 = arrayUpdate(_arr, ((modelica_integer) 1) + _n, mmc_mk_some(_entry));
tmpMeta9 = mmc_mk_box3(3, &InnerOuter_ValueArray_VALUE__ARRAY__desc, mmc_mk_integer(_n_1), _arr_1);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_integer tmp11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp11 = mmc_unbox_integer(tmpMeta10);
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_n = tmp11;
_arr = tmpMeta12;
_size = arrayLength(_arr);
if((_n < _size))
{
goto goto_2;
}
_rsize = ((modelica_real)_size);
_rexpandsize = (0.4) * (_rsize);
_expandsize = ((modelica_integer)floor(_rexpandsize));
_expandsize_1 = modelica_integer_max((modelica_integer)(_expandsize),(modelica_integer)(((modelica_integer) 1)));
_arr_1 = omc_Array_expand(threadData, _expandsize_1, _arr, mmc_mk_none());
_n_1 = ((modelica_integer) 1) + _n;
_arr_2 = arrayUpdate(_arr_1, ((modelica_integer) 1) + _n, mmc_mk_some(_entry));
tmpMeta13 = mmc_mk_box3(3, &InnerOuter_ValueArray_VALUE__ARRAY__desc, mmc_mk_integer(_n_1), _arr_2);
tmpMeta1 = tmpMeta13;
goto tmp3_done;
}
case 2: {
fputs(MMC_STRINGDATA(_OMC_LIT2),stdout);
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
_outValueArray = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outValueArray;
}
DLLExport
modelica_integer omc_InnerOuter_valueArrayLength(threadData_t *threadData, modelica_metatype _valueArray)
{
modelica_integer _size;
modelica_integer tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _valueArray;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
_size = tmp7;
tmp1 = _size;
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
_size = tmp1;
_return: OMC_LABEL_UNUSED
return _size;
}
modelica_metatype boxptr_InnerOuter_valueArrayLength(threadData_t *threadData, modelica_metatype _valueArray)
{
modelica_integer _size;
modelica_metatype out_size;
_size = omc_InnerOuter_valueArrayLength(threadData, _valueArray);
out_size = mmc_mk_icon(_size);
return out_size;
}
DLLExport
modelica_metatype omc_InnerOuter_valueArrayList2(threadData_t *threadData, modelica_metatype _inVarOptionArray1, modelica_integer _inInteger2, modelica_integer _inInteger3)
{
modelica_metatype _outVarLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_integer tmp4_2;volatile modelica_integer tmp4_3;
tmp4_1 = _inVarOptionArray1;
tmp4_2 = _inInteger2;
tmp4_3 = _inInteger3;
{
modelica_metatype _v = NULL;
modelica_metatype _arr = NULL;
modelica_integer _pos;
modelica_integer _lastpos;
modelica_integer _pos_1;
modelica_metatype _res = NULL;
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
_arr = tmp4_1;
_pos = tmp4_2;
_lastpos = tmp4_3;
if((!(_pos == _lastpos)))
{
goto goto_2;
}
tmpMeta6 = arrayGet(_arr,((modelica_integer) 1) + _pos);
if (optionNone(tmpMeta6)) goto goto_2;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
_v = tmpMeta7;
tmpMeta8 = mmc_mk_cons(_v, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
_arr = tmp4_1;
_pos = tmp4_2;
_lastpos = tmp4_3;
_pos_1 = ((modelica_integer) 1) + _pos;
tmpMeta9 = arrayGet(_arr,((modelica_integer) 1) + _pos);
if (optionNone(tmpMeta9)) goto goto_2;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 1));
_v = tmpMeta10;
_res = omc_InnerOuter_valueArrayList2(threadData, _arr, _pos_1, _lastpos);
tmpMeta11 = mmc_mk_cons(_v, _res);
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
_arr = tmp4_1;
_pos = tmp4_2;
_lastpos = tmp4_3;
_pos_1 = ((modelica_integer) 1) + _pos;
tmpMeta12 = arrayGet(_arr,((modelica_integer) 1) + _pos);
if (!optionNone(tmpMeta12)) goto goto_2;
tmpMeta1 = omc_InnerOuter_valueArrayList2(threadData, _arr, _pos_1, _lastpos);
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
_outVarLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outVarLst;
}
modelica_metatype boxptr_InnerOuter_valueArrayList2(threadData_t *threadData, modelica_metatype _inVarOptionArray1, modelica_metatype _inInteger2, modelica_metatype _inInteger3)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outVarLst = NULL;
tmp1 = mmc_unbox_integer(_inInteger2);
tmp2 = mmc_unbox_integer(_inInteger3);
_outVarLst = omc_InnerOuter_valueArrayList2(threadData, _inVarOptionArray1, tmp1, tmp2);
return _outVarLst;
}
DLLExport
modelica_metatype omc_InnerOuter_valueArrayList(threadData_t *threadData, modelica_metatype _valueArray)
{
modelica_metatype _tplLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _valueArray;
{
modelica_metatype _arr = NULL;
modelica_metatype _elt = NULL;
modelica_integer _lastpos;
modelica_integer _n;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
if (0 != tmp7) goto tmp3_end;
tmp4 += 1;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_integer tmp10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp10 = mmc_unbox_integer(tmpMeta9);
if (1 != tmp10) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_arr = tmpMeta11;
tmpMeta12 = arrayGet(_arr,((modelica_integer) 1));
if (optionNone(tmpMeta12)) goto goto_2;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 1));
_elt = tmpMeta13;
tmpMeta14 = mmc_mk_cons(_elt, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta14;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta15;
modelica_integer tmp16;
modelica_metatype tmpMeta17;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp16 = mmc_unbox_integer(tmpMeta15);
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_n = tmp16;
_arr = tmpMeta17;
_lastpos = ((modelica_integer) -1) + _n;
tmpMeta1 = omc_InnerOuter_valueArrayList2(threadData, _arr, ((modelica_integer) 0), _lastpos);
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
_tplLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _tplLst;
}
DLLExport
modelica_metatype omc_InnerOuter_hashTableList(threadData_t *threadData, modelica_metatype _hashTable)
{
modelica_metatype _tplLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _hashTable;
{
modelica_metatype _varr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_varr = tmpMeta6;
tmpMeta1 = omc_InnerOuter_valueArrayList(threadData, _varr);
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
_tplLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _tplLst;
}
DLLExport
modelica_metatype omc_InnerOuter_hashTableKeyList(threadData_t *threadData, modelica_metatype _hashTable)
{
modelica_metatype _valLst = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_valLst = omc_List_map(threadData, omc_InnerOuter_hashTableList(threadData, _hashTable), boxvar_Util_tuple21);
_return: OMC_LABEL_UNUSED
return _valLst;
}
DLLExport
modelica_metatype omc_InnerOuter_hashTableValueList(threadData_t *threadData, modelica_metatype _hashTable)
{
modelica_metatype _valLst = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_valLst = omc_List_map(threadData, omc_InnerOuter_hashTableList(threadData, _hashTable), boxvar_Util_tuple22);
_return: OMC_LABEL_UNUSED
return _valLst;
}
DLLExport
modelica_integer omc_InnerOuter_get2(threadData_t *threadData, modelica_metatype _key, modelica_metatype _keyIndices)
{
modelica_integer _index;
modelica_integer tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _keyIndices;
{
modelica_metatype _key2 = NULL;
modelica_metatype _xs = NULL;
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
modelica_integer tmp10;
modelica_boolean tmp11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmp10 = mmc_unbox_integer(tmpMeta9);
_key2 = tmpMeta8;
_index = tmp10;
tmp11 = omc_InnerOuter_keyEqual(threadData, _key, _key2);
if (1 != tmp11) goto goto_2;
tmp1 = _index;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmp4_1);
tmpMeta13 = MMC_CDR(tmp4_1);
_xs = tmpMeta13;
tmp1 = omc_InnerOuter_get2(threadData, _key, _xs);
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
_index = tmp1;
_return: OMC_LABEL_UNUSED
return _index;
}
modelica_metatype boxptr_InnerOuter_get2(threadData_t *threadData, modelica_metatype _key, modelica_metatype _keyIndices)
{
modelica_integer _index;
modelica_metatype out_index;
_index = omc_InnerOuter_get2(threadData, _key, _keyIndices);
out_index = mmc_mk_icon(_index);
return out_index;
}
DLLExport
modelica_metatype omc_InnerOuter_get1(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashTable, modelica_integer *out_indx)
{
modelica_metatype _value = NULL;
modelica_integer _indx;
modelica_integer tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _hashTable;
{
modelica_integer _hval;
modelica_integer _hashindx;
modelica_integer _bsize;
modelica_metatype _indexes = NULL;
modelica_metatype _v = NULL;
modelica_metatype _hashvec = NULL;
modelica_metatype _varr = NULL;
modelica_metatype _k = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_integer tmp9;
modelica_boolean tmp10;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmp9 = mmc_unbox_integer(tmpMeta8);
_hashvec = tmpMeta6;
_varr = tmpMeta7;
_bsize = tmp9;
_hval = omc_InnerOuter_hashFunc(threadData, _key);
_hashindx = modelica_integer_mod(_hval, _bsize);
_indexes = arrayGet(_hashvec,((modelica_integer) 1) + _hashindx);
_indx = omc_InnerOuter_get2(threadData, _key, _indexes);
_k = omc_InnerOuter_valueArrayNth(threadData, _varr, _indx ,&_v);
tmp10 = omc_InnerOuter_keyEqual(threadData, _k, _key);
if (1 != tmp10) goto goto_2;
tmpMeta[0+0] = _v;
tmp1_c1 = _indx;
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
_value = tmpMeta[0+0];
_indx = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_indx) { *out_indx = _indx; }
return _value;
}
modelica_metatype boxptr_InnerOuter_get1(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashTable, modelica_metatype *out_indx)
{
modelica_integer _indx;
modelica_metatype _value = NULL;
_value = omc_InnerOuter_get1(threadData, _key, _hashTable, &_indx);
if (out_indx) { *out_indx = mmc_mk_icon(_indx); }
return _value;
}
DLLExport
modelica_metatype omc_InnerOuter_get(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashTable)
{
modelica_metatype _value = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_value = omc_InnerOuter_get1(threadData, _key, _hashTable, NULL);
_return: OMC_LABEL_UNUSED
return _value;
}
DLLExport
modelica_metatype omc_InnerOuter_delete(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashTable)
{
modelica_metatype _outHashTable = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _hashTable;
{
modelica_integer _indx;
modelica_integer _n;
modelica_integer _bsize;
modelica_metatype _varr_1 = NULL;
modelica_metatype _varr = NULL;
modelica_metatype _hashvec = NULL;
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
modelica_integer tmp9;
modelica_metatype tmpMeta10;
modelica_integer tmp11;
modelica_metatype tmpMeta12;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmp9 = mmc_unbox_integer(tmpMeta8);
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmp11 = mmc_unbox_integer(tmpMeta10);
_hashvec = tmpMeta6;
_varr = tmpMeta7;
_bsize = tmp9;
_n = tmp11;
omc_InnerOuter_get1(threadData, _key, _hashTable ,&_indx);
_varr_1 = omc_InnerOuter_valueArrayClearnth(threadData, _varr, _indx);
tmpMeta12 = mmc_mk_box5(3, &InnerOuter_InstHierarchyHashTable_HASHTABLE__desc, _hashvec, _varr_1, mmc_mk_integer(_bsize), mmc_mk_integer(_n));
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 1: {
fputs(MMC_STRINGDATA(_OMC_LIT3),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT4),stdout);
omc_InnerOuter_dumpInstHierarchyHashTable(threadData, _hashTable);
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
_outHashTable = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outHashTable;
}
DLLExport
modelica_metatype omc_InnerOuter_addNoUpdCheck(threadData_t *threadData, modelica_metatype _entry, modelica_metatype _hashTable)
{
modelica_metatype _outHashTable = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _entry;
tmp4_2 = _hashTable;
{
modelica_integer _hval;
modelica_integer _indx;
modelica_integer _newpos;
modelica_integer _n_1;
modelica_integer _bsize;
modelica_metatype _varr_1 = NULL;
modelica_metatype _varr = NULL;
modelica_metatype _indexes = NULL;
modelica_metatype _hashvec_1 = NULL;
modelica_metatype _hashvec = NULL;
modelica_metatype _v = NULL;
modelica_metatype _key = NULL;
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
modelica_integer tmp10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmp10 = mmc_unbox_integer(tmpMeta9);
_v = tmp4_1;
_key = tmpMeta6;
_hashvec = tmpMeta7;
_varr = tmpMeta8;
_bsize = tmp10;
_hval = omc_InnerOuter_hashFunc(threadData, _key);
_indx = modelica_integer_mod(_hval, _bsize);
_newpos = omc_InnerOuter_valueArrayLength(threadData, _varr);
_varr_1 = omc_InnerOuter_valueArrayAdd(threadData, _varr, _v);
_indexes = arrayGet(_hashvec,((modelica_integer) 1) + _indx);
tmpMeta12 = mmc_mk_box2(0, _key, mmc_mk_integer(_newpos));
tmpMeta11 = mmc_mk_cons(tmpMeta12, _indexes);
_hashvec_1 = arrayUpdate(_hashvec, ((modelica_integer) 1) + _indx, tmpMeta11);
_n_1 = omc_InnerOuter_valueArrayLength(threadData, _varr_1);
tmpMeta13 = mmc_mk_box5(3, &InnerOuter_InstHierarchyHashTable_HASHTABLE__desc, _hashvec_1, _varr_1, mmc_mk_integer(_bsize), mmc_mk_integer(_n_1));
tmpMeta1 = tmpMeta13;
goto tmp3_done;
}
case 1: {
fputs(MMC_STRINGDATA(_OMC_LIT5),stdout);
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
_outHashTable = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outHashTable;
}
DLLExport
modelica_metatype omc_InnerOuter_add(threadData_t *threadData, modelica_metatype _entry, modelica_metatype _hashTable)
{
modelica_metatype _outHashTable = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _entry;
tmp4_2 = _hashTable;
{
modelica_integer _hval;
modelica_integer _indx;
modelica_integer _newpos;
modelica_integer _n;
modelica_integer _n_1;
modelica_integer _bsize;
modelica_metatype _varr_1 = NULL;
modelica_metatype _varr = NULL;
modelica_metatype _indexes = NULL;
modelica_metatype _hashvec_1 = NULL;
modelica_metatype _hashvec = NULL;
modelica_metatype _v = NULL;
modelica_metatype _newv = NULL;
modelica_metatype _key = NULL;
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
modelica_integer tmp10;
modelica_boolean tmp11;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmp10 = mmc_unbox_integer(tmpMeta9);
_v = tmp4_1;
_key = tmpMeta6;
_hashvec = tmpMeta7;
_varr = tmpMeta8;
_bsize = tmp10;
tmp11 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_InnerOuter_get(threadData, _key, _hashTable);
tmp11 = 1;
goto goto_12;
goto_12:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp11) {goto goto_2;}
_hval = omc_InnerOuter_hashFunc(threadData, _key);
_indx = modelica_integer_mod(_hval, _bsize);
_newpos = omc_InnerOuter_valueArrayLength(threadData, _varr);
_varr_1 = omc_InnerOuter_valueArrayAdd(threadData, _varr, _v);
_indexes = arrayGet(_hashvec,((modelica_integer) 1) + _indx);
tmpMeta14 = mmc_mk_box2(0, _key, mmc_mk_integer(_newpos));
tmpMeta13 = mmc_mk_cons(tmpMeta14, _indexes);
_hashvec_1 = arrayUpdate(_hashvec, ((modelica_integer) 1) + _indx, tmpMeta13);
_n_1 = omc_InnerOuter_valueArrayLength(threadData, _varr_1);
tmpMeta15 = mmc_mk_box5(3, &InnerOuter_InstHierarchyHashTable_HASHTABLE__desc, _hashvec_1, _varr_1, mmc_mk_integer(_bsize), mmc_mk_integer(_n_1));
tmpMeta1 = tmpMeta15;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_integer tmp20;
modelica_metatype tmpMeta21;
modelica_integer tmp22;
modelica_metatype tmpMeta23;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmp20 = mmc_unbox_integer(tmpMeta19);
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
tmp22 = mmc_unbox_integer(tmpMeta21);
_newv = tmp4_1;
_key = tmpMeta16;
_hashvec = tmpMeta17;
_varr = tmpMeta18;
_bsize = tmp20;
_n = tmp22;
omc_InnerOuter_get1(threadData, _key, _hashTable ,&_indx);
_varr_1 = omc_InnerOuter_valueArraySetnth(threadData, _varr, _indx, _newv);
tmpMeta23 = mmc_mk_box5(3, &InnerOuter_InstHierarchyHashTable_HASHTABLE__desc, _hashvec, _varr_1, mmc_mk_integer(_bsize), mmc_mk_integer(_n));
tmpMeta1 = tmpMeta23;
goto tmp3_done;
}
case 2: {
fputs(MMC_STRINGDATA(_OMC_LIT6),stdout);
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
_outHashTable = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outHashTable;
}
DLLExport
modelica_boolean omc_InnerOuter_isEmpty(threadData_t *threadData, modelica_metatype _hashTable)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _hashTable;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmp7 = mmc_unbox_integer(tmpMeta6);
if (0 != tmp7) goto tmp3_end;
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
modelica_metatype boxptr_InnerOuter_isEmpty(threadData_t *threadData, modelica_metatype _hashTable)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_InnerOuter_isEmpty(threadData, _hashTable);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_metatype omc_InnerOuter_emptyInstHierarchyHashTable(threadData_t *threadData)
{
modelica_metatype _hashTable = NULL;
modelica_metatype _arr = NULL;
modelica_metatype _lst = NULL;
modelica_metatype _emptyarr = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_arr = arrayCreate(((modelica_integer) 1000), tmpMeta1);
_emptyarr = arrayCreate(((modelica_integer) 100), mmc_mk_none());
tmpMeta2 = mmc_mk_box3(3, &InnerOuter_ValueArray_VALUE__ARRAY__desc, mmc_mk_integer(((modelica_integer) 0)), _emptyarr);
tmpMeta3 = mmc_mk_box5(3, &InnerOuter_InstHierarchyHashTable_HASHTABLE__desc, _arr, tmpMeta2, mmc_mk_integer(((modelica_integer) 1000)), mmc_mk_integer(((modelica_integer) 0)));
_hashTable = tmpMeta3;
_return: OMC_LABEL_UNUSED
return _hashTable;
}
DLLExport
modelica_metatype omc_InnerOuter_cloneInstHierarchyHashTable(threadData_t *threadData, modelica_metatype _inHash)
{
modelica_metatype _outHash = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inHash;
{
modelica_metatype _arg1 = NULL;
modelica_metatype _arg1_2 = NULL;
modelica_integer _arg3;
modelica_integer _arg4;
modelica_integer _arg3_2;
modelica_integer _arg4_2;
modelica_integer _arg21;
modelica_integer _arg21_2;
modelica_metatype _arg22 = NULL;
modelica_metatype _arg22_2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_integer tmp9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_integer tmp12;
modelica_metatype tmpMeta13;
modelica_integer tmp14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmp9 = mmc_unbox_integer(tmpMeta8);
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmp12 = mmc_unbox_integer(tmpMeta11);
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmp14 = mmc_unbox_integer(tmpMeta13);
_arg1 = tmpMeta6;
_arg21 = tmp9;
_arg22 = tmpMeta10;
_arg3 = tmp12;
_arg4 = tmp14;
_arg1_2 = arrayCopy(_arg1);
_arg21_2 = _arg21;
_arg22_2 = arrayCopy(_arg22);
_arg3_2 = _arg3;
_arg4_2 = _arg4;
tmpMeta15 = mmc_mk_box3(3, &InnerOuter_ValueArray_VALUE__ARRAY__desc, mmc_mk_integer(_arg21_2), _arg22_2);
tmpMeta16 = mmc_mk_box5(3, &InnerOuter_InstHierarchyHashTable_HASHTABLE__desc, _arg1_2, tmpMeta15, mmc_mk_integer(_arg3_2), mmc_mk_integer(_arg4_2));
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
_outHash = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outHash;
}
DLLExport
modelica_string omc_InnerOuter_dumpTuple(threadData_t *threadData, modelica_metatype _tpl)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _tpl;
{
modelica_metatype _k = NULL;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_k = tmpMeta6;
tmpMeta7 = stringAppend(_OMC_LIT7,omc_ComponentReference_crefStr(threadData, _k));
tmpMeta8 = stringAppend(tmpMeta7,_OMC_LIT8);
tmpMeta9 = stringAppend(tmpMeta8,_OMC_LIT9);
tmp1 = tmpMeta9;
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
DLLExport
void omc_InnerOuter_dumpInstHierarchyHashTable(threadData_t *threadData, modelica_metatype _t)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
fputs(MMC_STRINGDATA(_OMC_LIT10),stdout);
fputs(MMC_STRINGDATA(stringDelimitList(omc_List_map(threadData, omc_InnerOuter_hashTableList(threadData, _t), boxvar_InnerOuter_dumpTuple), _OMC_LIT11)),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT11),stdout);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_boolean omc_InnerOuter_keyEqual(threadData_t *threadData, modelica_metatype _key1, modelica_metatype _key2)
{
modelica_boolean _res;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = omc_ComponentReference_crefEqualNoStringCompare(threadData, _key1, _key2);
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_InnerOuter_keyEqual(threadData_t *threadData, modelica_metatype _key1, modelica_metatype _key2)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_InnerOuter_keyEqual(threadData, _key1, _key2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_integer omc_InnerOuter_hashFunc(threadData_t *threadData, modelica_metatype _k)
{
modelica_integer _res;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = stringHashDjb2(omc_ComponentReference_printComponentRefStr(threadData, _k));
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_InnerOuter_hashFunc(threadData_t *threadData, modelica_metatype _k)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_InnerOuter_hashFunc(threadData, _k);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_metatype omc_InnerOuter_getValue(threadData_t *threadData, modelica_metatype _tpl)
{
modelica_metatype _v = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _tpl;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_v = tmpMeta6;
tmpMeta1 = _v;
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
_v = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _v;
}
DLLExport
modelica_metatype omc_InnerOuter_getInnersFromInstHierarchyHashTable(threadData_t *threadData, modelica_metatype _t)
{
modelica_metatype _inners = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_inners = omc_List_map(threadData, omc_InnerOuter_hashTableList(threadData, _t), boxvar_InnerOuter_getValue);
_return: OMC_LABEL_UNUSED
return _inners;
}
DLLExport
modelica_string omc_InnerOuter_getExistingInnerDeclarations(threadData_t *threadData, modelica_metatype _inIH, modelica_metatype _inEnv)
{
modelica_string _innerDeclarations = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inIH;
{
modelica_metatype _ht = NULL;
modelica_metatype _inners = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = stringAppend(_OMC_LIT12,omc_FGraph_printGraphPathStr(threadData, _inEnv));
tmpMeta7 = stringAppend(tmpMeta6,_OMC_LIT13);
tmp1 = tmpMeta7;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_1);
tmpMeta9 = MMC_CDR(tmp4_1);
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
_ht = tmpMeta10;
_inners = omc_InnerOuter_getInnersFromInstHierarchyHashTable(threadData, _ht);
tmp1 = stringDelimitList(omc_List_map(threadData, _inners, boxvar_InnerOuter_printInnerDefStr), _OMC_LIT14);
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
_innerDeclarations = tmp1;
_return: OMC_LABEL_UNUSED
return _innerDeclarations;
}
DLLExport
modelica_string omc_InnerOuter_printInnerDefStr(threadData_t *threadData, modelica_metatype _inInstInner)
{
modelica_string _outStr = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inInstInner;
{
modelica_string _fullName = NULL;
modelica_metatype _typePath = NULL;
modelica_string _scope = NULL;
modelica_metatype _outers = NULL;
modelica_string _strOuters = NULL;
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
modelica_boolean tmp12;
modelica_string tmp13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 9));
_fullName = tmpMeta6;
_typePath = tmpMeta7;
_scope = tmpMeta8;
_outers = tmpMeta9;
_outers = omc_List_uniqueOnTrue(threadData, _outers, boxvar_ComponentReference_crefEqualNoStringCompare);
tmp12 = (modelica_boolean)listEmpty(_outers);
if(tmp12)
{
tmp13 = _OMC_LIT15;
}
else
{
tmpMeta10 = stringAppend(_OMC_LIT16,stringDelimitList(omc_List_map(threadData, _outers, boxvar_ComponentReference_printComponentRefStr), _OMC_LIT17));
tmpMeta11 = stringAppend(tmpMeta10,_OMC_LIT18);
tmp13 = tmpMeta11;
}
_strOuters = tmp13;
tmpMeta14 = stringAppend(omc_AbsynUtil_pathString(threadData, _typePath, _OMC_LIT13, 1, 0),_OMC_LIT19);
tmpMeta15 = stringAppend(tmpMeta14,_fullName);
tmpMeta16 = stringAppend(tmpMeta15,_OMC_LIT20);
tmpMeta17 = stringAppend(tmpMeta16,_scope);
tmpMeta18 = stringAppend(tmpMeta17,_OMC_LIT13);
tmpMeta19 = stringAppend(tmpMeta18,_strOuters);
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
_outStr = tmp1;
_return: OMC_LABEL_UNUSED
return _outStr;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_searchForInnerPrefix(threadData_t *threadData, modelica_metatype _fullCref, modelica_metatype _inOuterCref, modelica_metatype _outerPrefixes, modelica_metatype *out_innerCrefPrefix)
{
modelica_metatype _outerCrefPrefix = NULL;
modelica_metatype _innerCrefPrefix = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _id = NULL;
modelica_boolean _b1;
modelica_boolean _b2;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b1 = 0;
_b2 = 0;
{
modelica_metatype _op;
for (tmpMeta1 = _outerPrefixes; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_op = MMC_CAR(tmpMeta1);
tmpMeta2 = _op;
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 2));
_outerCrefPrefix = tmpMeta3;
_b1 = omc_ComponentReference_crefPrefixOfIgnoreSubscripts(threadData, _outerCrefPrefix, _fullCref);
if((!_b1))
{
_cr = omc_ComponentReference_crefStripLastIdent(threadData, _outerCrefPrefix);
_b2 = ((stringEqual(omc_ComponentReference_crefLastIdent(threadData, _outerCrefPrefix), omc_ComponentReference_crefFirstIdent(threadData, _inOuterCref))) && omc_ComponentReference_crefPrefixOfIgnoreSubscripts(threadData, _cr, _fullCref));
}
if((_b1 || _b2))
{
tmpMeta4 = _op;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta4), 3));
_innerCrefPrefix = tmpMeta5;
goto _return;
}
}
}
MMC_THROW_INTERNAL();
_return: OMC_LABEL_UNUSED
if (out_innerCrefPrefix) { *out_innerCrefPrefix = _innerCrefPrefix; }
return _outerCrefPrefix;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_changeOuterReferenceToInnerReference(threadData_t *threadData, modelica_metatype _inFullCref, modelica_metatype _inOuterCrefPrefix, modelica_metatype _inInnerCrefPrefix)
{
modelica_metatype _outInnerCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inFullCref;
tmp4_2 = _inOuterCrefPrefix;
tmp4_3 = _inInnerCrefPrefix;
{
modelica_metatype _ifull = NULL;
modelica_metatype _ocp = NULL;
modelica_metatype _icp = NULL;
modelica_metatype _eifull = NULL;
modelica_metatype _eocp = NULL;
modelica_metatype _eicp = NULL;
modelica_metatype _epre = NULL;
modelica_metatype _erest = NULL;
modelica_metatype _esuffix = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
_ifull = tmp4_1;
_ocp = tmp4_2;
_icp = tmp4_3;
_eifull = omc_ComponentReference_explode(threadData, _ifull);
_eicp = omc_ComponentReference_explode(threadData, _icp);
_eocp = omc_List_split(threadData, _eifull, omc_ComponentReference_identifierCount(threadData, _ocp) ,&_esuffix);
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
_epre = omc_List_splitEqualPrefix(threadData, _eocp, _eicp, boxvar_ComponentReference_crefFirstIdentEqual, tmpMeta6 ,&_erest);
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
omc_List_splitEqualPrefix(threadData, _eicp, _epre, boxvar_ComponentReference_crefFirstIdentEqual, tmpMeta7 ,&_eicp);
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
_erest = omc_List_splitEqualPrefix(threadData, listReverse(_erest), listReverse(_eicp), boxvar_ComponentReference_crefFirstIdentEqual, tmpMeta8, NULL);
_erest = omc_List_append__reverse(threadData, _erest, _esuffix);
_eifull = listAppend(_epre, _erest);
tmpMeta1 = omc_ComponentReference_implode(threadData, _eifull);
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
_outInnerCref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outInnerCref;
}
DLLExport
modelica_metatype omc_InnerOuter_prefixOuterCrefWithTheInnerPrefix(threadData_t *threadData, modelica_metatype _inIH, modelica_metatype _inOuterComponentRef, modelica_metatype _inPrefix)
{
modelica_metatype _outInnerComponentRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inIH;
{
modelica_metatype _outerCrefPrefix = NULL;
modelica_metatype _fullCref = NULL;
modelica_metatype _innerCrefPrefix = NULL;
modelica_metatype _outerPrefixes = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
goto goto_2;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
if (listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
if (!listEmpty(tmpMeta7)) goto tmp3_end;
_outerPrefixes = tmpMeta8;
tmpMeta11 = MMC_REFSTRUCTLIT(mmc_nil);
omc_PrefixUtil_prefixCref(threadData, omc_FCore_emptyCache(threadData), omc_FGraph_empty(threadData), tmpMeta11, _inPrefix, _inOuterComponentRef ,&_fullCref);
_outerCrefPrefix = omc_InnerOuter_searchForInnerPrefix(threadData, _fullCref, _inOuterComponentRef, _outerPrefixes ,&_innerCrefPrefix);
tmpMeta1 = omc_InnerOuter_changeOuterReferenceToInnerReference(threadData, _fullCref, _outerCrefPrefix, _innerCrefPrefix);
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
_outInnerComponentRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outInnerComponentRef;
}
DLLExport
modelica_metatype omc_InnerOuter_addOuterPrefixToIH(threadData_t *threadData, modelica_metatype _inIH, modelica_metatype _inOuterComponentRef, modelica_metatype _inInnerComponentRef)
{
modelica_metatype _outIH = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inIH;
{
modelica_metatype _tih = NULL;
modelica_metatype _restIH = NULL;
modelica_metatype _ht = NULL;
modelica_metatype _pathOpt = NULL;
modelica_metatype _outerPrefixes = NULL;
modelica_metatype _sm = NULL;
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
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp4 += 1;
_ht = omc_InnerOuter_emptyInstHierarchyHashTable(threadData);
_sm = omc_HashSet_emptyHashSet(threadData);
tmpMeta7 = mmc_mk_box3(3, &InnerOuter_OuterPrefix_OUTER__desc, omc_ComponentReference_crefStripSubs(threadData, _inOuterComponentRef), _inInnerComponentRef);
tmpMeta6 = mmc_mk_cons(tmpMeta7, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta8 = mmc_mk_box5(3, &InnerOuter_TopInstance_TOP__INSTANCE__desc, mmc_mk_none(), _ht, tmpMeta6, _sm);
_tih = tmpMeta8;
tmpMeta9 = mmc_mk_cons(_tih, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 3));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 4));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 5));
_pathOpt = tmpMeta12;
_ht = tmpMeta13;
_outerPrefixes = tmpMeta14;
_sm = tmpMeta15;
_restIH = tmpMeta11;
tmpMeta16 = mmc_mk_box3(3, &InnerOuter_OuterPrefix_OUTER__desc, omc_ComponentReference_crefStripSubs(threadData, _inOuterComponentRef), _inInnerComponentRef);
_outerPrefixes = omc_List_unionElt(threadData, tmpMeta16, _outerPrefixes);
tmpMeta18 = mmc_mk_box5(3, &InnerOuter_TopInstance_TOP__INSTANCE__desc, _pathOpt, _ht, _outerPrefixes, _sm);
tmpMeta17 = mmc_mk_cons(tmpMeta18, _restIH);
tmpMeta1 = tmpMeta17;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
tmp19 = omc_Flags_isSet(threadData, _OMC_LIT24);
if (1 != tmp19) goto goto_2;
tmpMeta20 = stringAppend(_OMC_LIT25,omc_ComponentReference_printComponentRefStr(threadData, _inOuterComponentRef));
tmpMeta21 = stringAppend(tmpMeta20,_OMC_LIT26);
tmpMeta22 = stringAppend(tmpMeta21,omc_ComponentReference_printComponentRefStr(threadData, _inInnerComponentRef));
tmpMeta23 = stringAppend(tmpMeta22,_OMC_LIT27);
omc_Debug_traceln(threadData, tmpMeta23);
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
_outIH = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outIH;
}
DLLExport
modelica_metatype omc_InnerOuter_addClassIfInner(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inPrefix, modelica_metatype _inScope, modelica_metatype _inIH)
{
modelica_metatype _outIH = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
modelica_string _name = NULL;
modelica_string _scopeName = NULL;
modelica_metatype _io = NULL;
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
modelica_boolean tmp9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
_name = tmpMeta6;
_io = tmpMeta8;
tmp9 = omc_AbsynUtil_isInner(threadData, _io);
if (1 != tmp9) goto goto_2;
_scopeName = omc_FGraph_getGraphNameStr(threadData, _inScope);
tmpMeta10 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _name);
tmpMeta11 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta12 = mmc_mk_box10(3, &InnerOuter_InstInner_INST__INNER__desc, _inPrefix, _name, _io, _name, tmpMeta10, _scopeName, mmc_mk_none(), tmpMeta11, mmc_mk_some(_inClass));
tmpMeta1 = omc_InnerOuter_updateInstHierarchy(threadData, _inIH, _inPrefix, _io, tmpMeta12);
goto tmp3_done;
}
case 1: {
tmpMeta1 = _inIH;
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
_outIH = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outIH;
}
DLLExport
modelica_metatype omc_InnerOuter_updateSMHierarchy(threadData_t *threadData, modelica_metatype _smState, modelica_metatype _inIH)
{
modelica_metatype _outIH = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _smState;
tmp4_2 = _inIH;
{
modelica_metatype _tih = NULL;
modelica_metatype _restIH = NULL;
modelica_metatype _cref = NULL;
modelica_string _name = NULL;
modelica_metatype _ht = NULL;
modelica_metatype _pathOpt = NULL;
modelica_metatype _outerPrefixes = NULL;
modelica_metatype _sm = NULL;
modelica_metatype _sm2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (!listEmpty(tmp4_2)) goto tmp3_end;
_ht = omc_InnerOuter_emptyInstHierarchyHashTable(threadData);
_sm = omc_HashSet_emptyHashSet(threadData);
_sm2 = omc_BaseHashSet_add(threadData, _smState, _sm);
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta7 = mmc_mk_box5(3, &InnerOuter_TopInstance_TOP__INSTANCE__desc, mmc_mk_none(), _ht, tmpMeta6, _sm2);
_tih = tmpMeta7;
tmpMeta8 = mmc_mk_cons(_tih, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmp4_2);
tmpMeta10 = MMC_CDR(tmp4_2);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 3));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 4));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 5));
_pathOpt = tmpMeta11;
_ht = tmpMeta12;
_outerPrefixes = tmpMeta13;
_sm = tmpMeta14;
_restIH = tmpMeta10;
_cref = tmp4_1;
_sm = omc_BaseHashSet_add(threadData, _cref, _sm);
tmpMeta16 = mmc_mk_box5(3, &InnerOuter_TopInstance_TOP__INSTANCE__desc, _pathOpt, _ht, _outerPrefixes, _sm);
tmpMeta15 = mmc_mk_cons(tmpMeta16, _restIH);
tmpMeta1 = tmpMeta15;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta17;
modelica_boolean tmp18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_name = tmpMeta17;
tmp18 = omc_Flags_isSet(threadData, _OMC_LIT31);
if (1 != tmp18) goto goto_2;
tmpMeta19 = stringAppend(_OMC_LIT32,_name);
omc_Debug_traceln(threadData, tmpMeta19);
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
_outIH = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outIH;
}
DLLExport
modelica_metatype omc_InnerOuter_updateInstHierarchy(threadData_t *threadData, modelica_metatype _inIH, modelica_metatype _inPrefix, modelica_metatype _inInnerOuter, modelica_metatype _inInstInner)
{
modelica_metatype _outIH = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inIH;
tmp4_2 = _inInstInner;
{
modelica_metatype _tih = NULL;
modelica_metatype _restIH = NULL;
modelica_metatype _cref = NULL;
modelica_string _name = NULL;
modelica_metatype _ht = NULL;
modelica_metatype _pathOpt = NULL;
modelica_metatype _outerPrefixes = NULL;
modelica_metatype _cref_ = NULL;
modelica_metatype _sm = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (!listEmpty(tmp4_1)) goto tmp3_end;
_ht = omc_InnerOuter_emptyInstHierarchyHashTable(threadData);
_sm = omc_HashSet_emptyHashSet(threadData);
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta7 = mmc_mk_box5(3, &InnerOuter_TopInstance_TOP__INSTANCE__desc, mmc_mk_none(), _ht, tmpMeta6, _sm);
_tih = tmpMeta7;
tmpMeta8 = mmc_mk_cons(_tih, MMC_REFSTRUCTLIT(mmc_nil));
_inIH = tmpMeta8;
goto _tailrecursive;
goto tmp3_done;
}
case 1: {
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmp4_1);
tmpMeta10 = MMC_CDR(tmp4_1);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 3));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 4));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 5));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_pathOpt = tmpMeta11;
_ht = tmpMeta12;
_outerPrefixes = tmpMeta13;
_sm = tmpMeta14;
_restIH = tmpMeta10;
_name = tmpMeta15;
tmpMeta16 = MMC_REFSTRUCTLIT(mmc_nil);
_cref_ = omc_ComponentReference_makeCrefIdent(threadData, _name, _OMC_LIT33, tmpMeta16);
tmpMeta17 = MMC_REFSTRUCTLIT(mmc_nil);
omc_PrefixUtil_prefixCref(threadData, omc_FCore_emptyCache(threadData), omc_FGraph_empty(threadData), tmpMeta17, _inPrefix, _cref_ ,&_cref);
tmpMeta18 = mmc_mk_box2(0, _cref, _inInstInner);
_ht = omc_InnerOuter_add(threadData, tmpMeta18, _ht);
tmpMeta20 = mmc_mk_box5(3, &InnerOuter_TopInstance_TOP__INSTANCE__desc, _pathOpt, _ht, _outerPrefixes, _sm);
tmpMeta19 = mmc_mk_cons(tmpMeta20, _restIH);
tmpMeta1 = tmpMeta19;
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
_outIH = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outIH;
}
DLLExport
modelica_metatype omc_InnerOuter_lookupInnerVar(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPrefix, modelica_string _inIdent, modelica_metatype _io)
{
modelica_metatype _outInstInner = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_string tmp4_3;
tmp4_1 = _inIH;
tmp4_2 = _inPrefix;
tmp4_3 = _inIdent;
{
modelica_string _n = NULL;
modelica_metatype _pre = NULL;
modelica_metatype _tih = NULL;
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
_tih = tmpMeta6;
_pre = tmp4_2;
_n = tmp4_3;
tmpMeta1 = omc_InnerOuter_lookupInnerInIH(threadData, _tih, _pre, _n);
goto tmp3_done;
}
case 1: {
modelica_boolean tmp8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
_pre = tmp4_2;
_n = tmp4_3;
tmp8 = omc_Flags_isSet(threadData, _OMC_LIT24);
if (1 != tmp8) goto goto_2;
tmpMeta9 = stringAppend(_OMC_LIT34,omc_PrefixUtil_printPrefixStr(threadData, _pre));
tmpMeta10 = stringAppend(tmpMeta9,_OMC_LIT35);
tmpMeta11 = stringAppend(tmpMeta10,_n);
omc_Debug_traceln(threadData, tmpMeta11);
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
_outInstInner = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outInstInner;
}
DLLExport
modelica_metatype omc_InnerOuter_emptyInstInner(threadData_t *threadData, modelica_metatype _innerPrefix, modelica_string _name)
{
modelica_metatype _outInstInner = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta2 = mmc_mk_box10(3, &InnerOuter_InstInner_INST__INNER__desc, _innerPrefix, _name, _OMC_LIT36, _OMC_LIT15, _OMC_LIT37, _OMC_LIT15, mmc_mk_none(), tmpMeta1, mmc_mk_none());
_outInstInner = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _outInstInner;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_switchInnerToOuterInChildrenValue(threadData_t *threadData, modelica_metatype _inNode, modelica_metatype _inCr)
{
modelica_metatype _outNode = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
modelica_metatype _r = NULL;
modelica_metatype _node = NULL;
modelica_string _name = NULL;
modelica_metatype _attributes = NULL;
modelica_metatype _visibility = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _binding = NULL;
modelica_boolean _bndsrc;
modelica_metatype _ct = NULL;
modelica_metatype _parallelism = NULL;
modelica_metatype _variability = NULL;
modelica_metatype _direction = NULL;
modelica_metatype _cnstForRange = NULL;
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
modelica_integer tmp13;
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
modelica_metatype tmpMeta24;
_node = tmp4_1;
_r = omc_FNode_childFromNode(threadData, _node, _OMC_LIT38);
tmpMeta6 = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,1) == 0) goto goto_2;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 6));
tmp13 = mmc_unbox_integer(tmpMeta12);
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 7));
_name = tmpMeta8;
_attributes = tmpMeta9;
_ty = tmpMeta10;
_binding = tmpMeta11;
_bndsrc = tmp13;
_cnstForRange = tmpMeta14;
tmpMeta15 = _attributes;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 3));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 4));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 5));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,0,0) == 0) goto goto_2;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 7));
_ct = tmpMeta16;
_parallelism = tmpMeta17;
_variability = tmpMeta18;
_direction = tmpMeta19;
_visibility = tmpMeta21;
tmpMeta22 = mmc_mk_box7(3, &DAE_Attributes_ATTR__desc, _ct, _parallelism, _variability, _direction, _OMC_LIT39, _visibility);
_attributes = tmpMeta22;
tmpMeta23 = mmc_mk_box7(3, &DAE_Var_TYPES__VAR__desc, _name, _attributes, _ty, _binding, mmc_mk_boolean(_bndsrc), _cnstForRange);
tmpMeta24 = mmc_mk_box2(4, &FCore_Data_IT__desc, tmpMeta23);
_r = omc_FNode_updateRef(threadData, _r, omc_FNode_setData(threadData, omc_FNode_fromRef(threadData, _r), tmpMeta24));
tmpMeta1 = _node;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_integer tmp32;
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
_node = tmp4_1;
_r = omc_FNode_childFromNode(threadData, _node, _OMC_LIT38);
tmpMeta25 = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta25,1,1) == 0) goto goto_2;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 2));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 2));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 3));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 4));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 5));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 6));
tmp32 = mmc_unbox_integer(tmpMeta31);
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 7));
_name = tmpMeta27;
_attributes = tmpMeta28;
_ty = tmpMeta29;
_binding = tmpMeta30;
_bndsrc = tmp32;
_cnstForRange = tmpMeta33;
tmpMeta34 = _attributes;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 2));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 3));
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 4));
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 5));
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta39,2,0) == 0) goto goto_2;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 7));
_ct = tmpMeta35;
_parallelism = tmpMeta36;
_variability = tmpMeta37;
_direction = tmpMeta38;
_visibility = tmpMeta40;
tmpMeta41 = mmc_mk_box7(3, &DAE_Attributes_ATTR__desc, _ct, _parallelism, _variability, _direction, _OMC_LIT39, _visibility);
_attributes = tmpMeta41;
tmpMeta42 = mmc_mk_box7(3, &DAE_Var_TYPES__VAR__desc, _name, _attributes, _ty, _binding, mmc_mk_boolean(_bndsrc), _cnstForRange);
tmpMeta43 = mmc_mk_box2(4, &FCore_Data_IT__desc, tmpMeta42);
_r = omc_FNode_updateRef(threadData, _r, omc_FNode_setData(threadData, omc_FNode_fromRef(threadData, _r), tmpMeta43));
tmpMeta1 = _node;
goto tmp3_done;
}
case 2: {
tmpMeta1 = _inNode;
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
_outNode = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outNode;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_switchInnerToOuterInChild(threadData_t *threadData, modelica_string _name, modelica_metatype _cr, modelica_metatype _inRef)
{
modelica_metatype _ref = NULL;
modelica_metatype _n = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_n = omc_FNode_fromRef(threadData, _inRef);
_n = omc_InnerOuter_switchInnerToOuterInChildrenValue(threadData, _n, _cr);
_ref = omc_FNode_updateRef(threadData, _inRef, _n);
_return: OMC_LABEL_UNUSED
return _ref;
}
static modelica_metatype closure0_InnerOuter_switchInnerToOuterInChild(threadData_t *thData, modelica_metatype closure, modelica_string name, modelica_metatype inRef)
{
modelica_metatype cr = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_InnerOuter_switchInnerToOuterInChild(thData, name, cr, inRef);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_switchInnerToOuterInNode(threadData_t *threadData, modelica_metatype _inNode, modelica_metatype _inCr)
{
modelica_metatype _outNode = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outNode = _inNode;
{
modelica_metatype tmp3_1;
tmp3_1 = _outNode;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
tmpMeta6 = mmc_mk_box1(0, _inCr);
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_outNode), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[5] = omc_FCore_RefTree_map(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outNode), 5))), (modelica_fnptr) mmc_mk_box2(0,closure0_InnerOuter_switchInnerToOuterInChild,tmpMeta6));
_outNode = tmpMeta5;
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
return _outNode;
}
DLLExport
modelica_metatype omc_InnerOuter_switchInnerToOuterInGraph(threadData_t *threadData, modelica_metatype _inEnv, modelica_metatype _inCr)
{
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inEnv;
tmp4_2 = _inCr;
{
modelica_metatype _cr = NULL;
modelica_metatype _r = NULL;
modelica_metatype _n = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta1 = _inEnv;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta1 = _inEnv;
goto tmp3_done;
}
case 2: {
_cr = tmp4_2;
_r = omc_FGraph_lastScopeRef(threadData, _inEnv);
_n = omc_FNode_fromRef(threadData, _r);
_n = omc_InnerOuter_switchInnerToOuterInNode(threadData, _n, _cr);
_r = omc_FNode_updateRef(threadData, _r, _n);
tmpMeta1 = _inEnv;
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
_outEnv = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outEnv;
}
DLLExport
modelica_metatype omc_InnerOuter_prefixOuterDaeVars(threadData_t *threadData, modelica_metatype _inDae, modelica_metatype _crefPrefix)
{
modelica_metatype _outDae = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inDae;
{
modelica_metatype _lst = NULL;
modelica_metatype _r_1 = NULL;
modelica_metatype _r = NULL;
modelica_metatype _lst_1 = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _vk = NULL;
modelica_metatype _t = NULL;
modelica_metatype _e = NULL;
modelica_metatype _id = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _dae_var_attr = NULL;
modelica_metatype _comment = NULL;
modelica_metatype _dir = NULL;
modelica_metatype _prl = NULL;
modelica_metatype _x = NULL;
modelica_metatype _io = NULL;
modelica_metatype _prot = NULL;
modelica_string _idName = NULL;
modelica_metatype _source = NULL;
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
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp4 += 3;
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
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,13) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 6));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 7));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 8));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 9));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 10));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 11));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 12));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 13));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 14));
_cr = tmpMeta9;
_vk = tmpMeta10;
_dir = tmpMeta11;
_prl = tmpMeta12;
_prot = tmpMeta13;
_t = tmpMeta14;
_e = tmpMeta15;
_id = tmpMeta16;
_ct = tmpMeta17;
_source = tmpMeta18;
_dae_var_attr = tmpMeta19;
_comment = tmpMeta20;
_io = tmpMeta21;
_r = tmpMeta8;
tmp4 += 1;
tmpMeta22 = MMC_REFSTRUCTLIT(mmc_nil);
omc_PrefixUtil_prefixCref(threadData, omc_FCore_emptyCache(threadData), omc_FGraph_empty(threadData), tmpMeta22, _crefPrefix, _cr ,&_cr);
_r_1 = omc_InnerOuter_prefixOuterDaeVars(threadData, _r, _crefPrefix);
tmpMeta24 = mmc_mk_box14(3, &DAE_Element_VAR__desc, _cr, _vk, _dir, _prl, _prot, _t, _e, _id, _ct, _source, _dae_var_attr, _comment, _io);
tmpMeta23 = mmc_mk_cons(tmpMeta24, _r_1);
tmpMeta1 = tmpMeta23;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta25 = MMC_CAR(tmp4_1);
tmpMeta26 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta25,17,4) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 2));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 3));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 4));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 5));
_idName = tmpMeta27;
_lst = tmpMeta28;
_source = tmpMeta29;
_comment = tmpMeta30;
_r = tmpMeta26;
_lst_1 = omc_InnerOuter_prefixOuterDaeVars(threadData, _lst, _crefPrefix);
_r_1 = omc_InnerOuter_prefixOuterDaeVars(threadData, _r, _crefPrefix);
tmpMeta32 = mmc_mk_box5(20, &DAE_Element_COMP__desc, _idName, _lst_1, _source, _comment);
tmpMeta31 = mmc_mk_cons(tmpMeta32, _r_1);
tmpMeta1 = tmpMeta31;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta33 = MMC_CAR(tmp4_1);
tmpMeta34 = MMC_CDR(tmp4_1);
_x = tmpMeta33;
_r = tmpMeta34;
_r_1 = omc_InnerOuter_prefixOuterDaeVars(threadData, _r, _crefPrefix);
tmpMeta35 = mmc_mk_cons(_x, _r_1);
tmpMeta1 = tmpMeta35;
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
_outDae = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outDae;
}
DLLExport
modelica_metatype omc_InnerOuter_switchInnerToOuterAndPrefix(threadData_t *threadData, modelica_metatype _inDae, modelica_metatype _io, modelica_metatype _pre)
{
modelica_metatype _outDae = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inDae;
tmp4_2 = _io;
{
modelica_metatype _lst = NULL;
modelica_metatype _r_1 = NULL;
modelica_metatype _r = NULL;
modelica_metatype _lst_1 = NULL;
modelica_metatype _v = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _vk = NULL;
modelica_metatype _t = NULL;
modelica_metatype _e = NULL;
modelica_metatype _id = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _dae_var_attr = NULL;
modelica_metatype _comment = NULL;
modelica_metatype _dir = NULL;
modelica_metatype _prl = NULL;
modelica_metatype _x = NULL;
modelica_metatype _prot = NULL;
modelica_string _idName = NULL;
modelica_metatype _source = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,0) == 0) goto tmp3_end;
_lst = tmp4_1;
tmpMeta1 = _lst;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp4 += 4;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 2: {
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
modelica_metatype tmpMeta24;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,13) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 6));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 7));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 8));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 9));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 10));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 11));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 12));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 13));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 14));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta21,0,0) == 0) goto tmp3_end;
_cr = tmpMeta9;
_vk = tmpMeta10;
_dir = tmpMeta11;
_prl = tmpMeta12;
_prot = tmpMeta13;
_t = tmpMeta14;
_e = tmpMeta15;
_id = tmpMeta16;
_ct = tmpMeta17;
_source = tmpMeta18;
_dae_var_attr = tmpMeta19;
_comment = tmpMeta20;
_r = tmpMeta8;
tmpMeta22 = MMC_REFSTRUCTLIT(mmc_nil);
omc_PrefixUtil_prefixCref(threadData, omc_FCore_emptyCache(threadData), omc_FGraph_empty(threadData), tmpMeta22, _pre, _cr ,&_cr);
_r_1 = omc_InnerOuter_switchInnerToOuterAndPrefix(threadData, _r, _io, _pre);
tmpMeta24 = mmc_mk_box14(3, &DAE_Element_VAR__desc, _cr, _vk, _dir, _prl, _prot, _t, _e, _id, _ct, _source, _dae_var_attr, _comment, _io);
tmpMeta23 = mmc_mk_cons(tmpMeta24, _r_1);
tmpMeta1 = tmpMeta23;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta25 = MMC_CAR(tmp4_1);
tmpMeta26 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta25,0,13) == 0) goto tmp3_end;
_v = tmpMeta25;
_r = tmpMeta26;
tmp4 += 1;
_r_1 = omc_InnerOuter_switchInnerToOuterAndPrefix(threadData, _r, _io, _pre);
tmpMeta27 = mmc_mk_cons(_v, _r_1);
tmpMeta1 = tmpMeta27;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta28 = MMC_CAR(tmp4_1);
tmpMeta29 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta28,17,4) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta28), 2));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta28), 3));
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta28), 4));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta28), 5));
_idName = tmpMeta30;
_lst = tmpMeta31;
_source = tmpMeta32;
_comment = tmpMeta33;
_r = tmpMeta29;
_lst_1 = omc_InnerOuter_switchInnerToOuterAndPrefix(threadData, _lst, _io, _pre);
_r_1 = omc_InnerOuter_switchInnerToOuterAndPrefix(threadData, _r, _io, _pre);
tmpMeta35 = mmc_mk_box5(20, &DAE_Element_COMP__desc, _idName, _lst_1, _source, _comment);
tmpMeta34 = mmc_mk_cons(tmpMeta35, _r_1);
tmpMeta1 = tmpMeta34;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta36 = MMC_CAR(tmp4_1);
tmpMeta37 = MMC_CDR(tmp4_1);
_x = tmpMeta36;
_r = tmpMeta37;
_r_1 = omc_InnerOuter_switchInnerToOuterAndPrefix(threadData, _r, _io, _pre);
tmpMeta38 = mmc_mk_cons(_x, _r_1);
tmpMeta1 = tmpMeta38;
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
_outDae = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outDae;
}
DLLExport
modelica_boolean omc_InnerOuter_modificationOnOuter(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _ih, modelica_metatype _prefix, modelica_string _componentName, modelica_metatype _cr, modelica_metatype _inMod, modelica_metatype _io, modelica_boolean _impl, modelica_metatype _inInfo)
{
modelica_boolean _modd;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inMod;
tmp4_2 = _io;
{
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
modelica_string _s = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
_s1 = omc_ComponentReference_printComponentRefStr(threadData, _cr);
_s2 = omc_Mod_prettyPrintMod(threadData, _inMod, ((modelica_integer) 0));
tmpMeta6 = stringAppend(_s1,_OMC_LIT19);
tmpMeta7 = stringAppend(tmpMeta6,_s2);
_s = tmpMeta7;
tmpMeta8 = mmc_mk_cons(_s, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT44, tmpMeta8, _inInfo);
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
_modd = tmp1;
_return: OMC_LABEL_UNUSED
return _modd;
}
modelica_metatype boxptr_InnerOuter_modificationOnOuter(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _ih, modelica_metatype _prefix, modelica_metatype _componentName, modelica_metatype _cr, modelica_metatype _inMod, modelica_metatype _io, modelica_metatype _impl, modelica_metatype _inInfo)
{
modelica_integer tmp1;
modelica_boolean _modd;
modelica_metatype out_modd;
tmp1 = mmc_unbox_integer(_impl);
_modd = omc_InnerOuter_modificationOnOuter(threadData, _cache, _env, _ih, _prefix, _componentName, _cr, _inMod, _io, tmp1, _inInfo);
out_modd = mmc_mk_icon(_modd);
return out_modd;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_lookupInnerInIH(threadData_t *threadData, modelica_metatype _inTIH, modelica_metatype _inPrefix, modelica_string _inComponentIdent)
{
modelica_metatype _outInstInner = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_string tmp4_3;
tmp4_1 = _inTIH;
tmp4_2 = _inPrefix;
tmp4_3 = _inComponentIdent;
{
modelica_string _name = NULL;
modelica_metatype _prefix = NULL;
modelica_metatype _ht = NULL;
modelica_metatype _cref = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,0) == 0) goto tmp3_end;
tmp4 += 1;
tmpMeta1 = omc_InnerOuter_lookupInnerInIH(threadData, _inTIH, _OMC_LIT45, _inComponentIdent);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
_name = tmp4_3;
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta8 = mmc_mk_box10(3, &InnerOuter_InstInner_INST__INNER__desc, _OMC_LIT45, _name, _OMC_LIT36, _OMC_LIT15, _OMC_LIT37, _OMC_LIT15, mmc_mk_none(), tmpMeta7, mmc_mk_none());
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_ht = tmpMeta9;
_name = tmp4_3;
_prefix = omc_PrefixUtil_prefixStripLast(threadData, _inPrefix);
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta11 = MMC_REFSTRUCTLIT(mmc_nil);
omc_PrefixUtil_prefixCref(threadData, omc_FCore_emptyCache(threadData), omc_FGraph_empty(threadData), tmpMeta10, _prefix, omc_ComponentReference_makeCrefIdent(threadData, _name, _OMC_LIT33, tmpMeta11) ,&_cref);
tmpMeta1 = omc_InnerOuter_get(threadData, _cref, _ht);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_boolean tmp15;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_ht = tmpMeta12;
_name = tmp4_3;
_prefix = omc_PrefixUtil_prefixStripLast(threadData, _inPrefix);
tmpMeta13 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta14 = MMC_REFSTRUCTLIT(mmc_nil);
omc_PrefixUtil_prefixCref(threadData, omc_FCore_emptyCache(threadData), omc_FGraph_empty(threadData), tmpMeta13, _prefix, omc_ComponentReference_makeCrefIdent(threadData, _name, _OMC_LIT33, tmpMeta14) ,&_cref);
tmp15 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_InnerOuter_get(threadData, _cref, _ht);
tmp15 = 1;
goto goto_16;
goto_16:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp15) {goto goto_2;}
tmpMeta1 = omc_InnerOuter_lookupInnerInIH(threadData, _inTIH, _prefix, _name);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
_prefix = tmp4_2;
_name = tmp4_3;
tmpMeta17 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta18 = mmc_mk_box10(3, &InnerOuter_InstInner_INST__INNER__desc, _prefix, _name, _OMC_LIT36, _OMC_LIT15, _OMC_LIT37, _OMC_LIT15, mmc_mk_none(), tmpMeta17, mmc_mk_none());
tmpMeta1 = tmpMeta18;
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
_outInstInner = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outInstInner;
}
DLLExport
modelica_boolean omc_InnerOuter_outerConnection(threadData_t *threadData, modelica_metatype _io1, modelica_metatype _io2)
{
modelica_boolean _isOuter;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _io1;
tmp4_2 = _io2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 4: {
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
_isOuter = tmp1;
_return: OMC_LABEL_UNUSED
return _isOuter;
}
modelica_metatype boxptr_InnerOuter_outerConnection(threadData_t *threadData, modelica_metatype _io1, modelica_metatype _io2)
{
modelica_boolean _isOuter;
modelica_metatype out_isOuter;
_isOuter = omc_InnerOuter_outerConnection(threadData, _io1, _io2);
out_isOuter = mmc_mk_icon(_isOuter);
return out_isOuter;
}
DLLExport
modelica_boolean omc_InnerOuter_referOuter(threadData_t *threadData, modelica_metatype _io1, modelica_metatype _io2, modelica_boolean *out_prefix2)
{
modelica_boolean _prefix1;
modelica_boolean _prefix2;
modelica_boolean tmp1_c0 __attribute__((unused)) = 0;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _io1;
tmp4_2 = _io2;
{
modelica_boolean _b1;
modelica_boolean _b2;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,0) == 0) goto tmp3_end;
tmp1_c0 = 1;
tmp1_c1 = 0;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
tmp1_c0 = 0;
tmp1_c1 = 1;
goto tmp3_done;
}
case 2: {
omc_InnerOuter_innerOuterBooleans(threadData, _io1 ,&_b1);
omc_InnerOuter_innerOuterBooleans(threadData, _io2 ,&_b2);
tmp1_c0 = _b1;
tmp1_c1 = _b2;
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
_prefix1 = tmp1_c0;
_prefix2 = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_prefix2) { *out_prefix2 = _prefix2; }
return _prefix1;
}
modelica_metatype boxptr_InnerOuter_referOuter(threadData_t *threadData, modelica_metatype _io1, modelica_metatype _io2, modelica_metatype *out_prefix2)
{
modelica_boolean _prefix2;
modelica_boolean _prefix1;
modelica_metatype out_prefix1;
_prefix1 = omc_InnerOuter_referOuter(threadData, _io1, _io2, &_prefix2);
out_prefix1 = mmc_mk_icon(_prefix1);
if (out_prefix2) { *out_prefix2 = mmc_mk_icon(_prefix2); }
return out_prefix1;
}
DLLExport
modelica_boolean omc_InnerOuter_innerOuterBooleans(threadData_t *threadData, modelica_metatype _io, modelica_boolean *out_outer1)
{
modelica_boolean _inner1;
modelica_boolean _outer1;
modelica_boolean tmp1_c0 __attribute__((unused)) = 0;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _io;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1_c0 = 1;
tmp1_c1 = 0;
goto tmp3_done;
}
case 4: {
tmp1_c0 = 0;
tmp1_c1 = 1;
goto tmp3_done;
}
case 5: {
tmp1_c0 = 1;
tmp1_c1 = 1;
goto tmp3_done;
}
case 6: {
tmp1_c0 = 0;
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
_inner1 = tmp1_c0;
_outer1 = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_outer1) { *out_outer1 = _outer1; }
return _inner1;
}
modelica_metatype boxptr_InnerOuter_innerOuterBooleans(threadData_t *threadData, modelica_metatype _io, modelica_metatype *out_outer1)
{
modelica_boolean _outer1;
modelica_boolean _inner1;
modelica_metatype out_inner1;
_inner1 = omc_InnerOuter_innerOuterBooleans(threadData, _io, &_outer1);
out_inner1 = mmc_mk_icon(_inner1);
if (out_outer1) { *out_outer1 = mmc_mk_icon(_outer1); }
return out_inner1;
}
DLLExport
void omc_InnerOuter_failExceptForCheck(threadData_t *threadData)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
tmp5 = omc_Flags_getConfigBool(threadData, _OMC_LIT51);
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
PROTECTED_FUNCTION_STATIC void omc_InnerOuter_checkMissingInnerDecl2(threadData_t *threadData, modelica_metatype _outerVar, modelica_metatype _innerVars)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _outerVar;
{
modelica_string _str = NULL;
modelica_string _str2 = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _crs = NULL;
modelica_metatype _res = NULL;
modelica_metatype _io = NULL;
modelica_metatype _source = NULL;
modelica_metatype _info = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 11));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 14));
_cr = tmpMeta5;
_source = tmpMeta6;
_io = tmpMeta7;
_crs = omc_List_map(threadData, _innerVars, boxvar_DAEUtil_varCref);
_res = omc_List_select1(threadData, _crs, boxvar_InnerOuter_isInnerOuterMatch, _cr);
if(listEmpty(_res))
{
if((!omc_Flags_getConfigBool(threadData, _OMC_LIT51)))
{
_str2 = omc_Dump_unparseInnerouterStr(threadData, _io);
_str = omc_ComponentReference_printComponentRefStr(threadData, _cr);
_info = omc_ElementSource_getElementSourceFileInfo(threadData, _source);
tmpMeta8 = mmc_mk_cons(_str, mmc_mk_cons(_str2, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT54, tmpMeta8, _info);
goto goto_1;
}
}
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
PROTECTED_FUNCTION_STATIC void omc_InnerOuter_checkMissingInnerDecl1(threadData_t *threadData, modelica_metatype _innerVarsDae, modelica_metatype _outerVarsDae)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_List_map1__0(threadData, omc_DAEUtil_daeElements(threadData, _outerVarsDae), boxvar_InnerOuter_checkMissingInnerDecl2, omc_DAEUtil_daeElements(threadData, _innerVarsDae));
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_InnerOuter_checkMissingInnerDecl(threadData_t *threadData, modelica_metatype _inDae, modelica_boolean _callScope)
{
modelica_metatype _innerVars = NULL;
modelica_metatype _outerVars = NULL;
modelica_metatype _allVars = NULL;
modelica_metatype _repl = NULL;
modelica_metatype _srcs = NULL;
modelica_metatype _targets = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_boolean tmp3_1;
tmp3_1 = _callScope;
{
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
tmp5 = omc_System_getHasInnerOuterDefinitions(threadData);
if (0 != tmp5) goto goto_1;
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (1 != tmp3_1) goto tmp2_end;
tmp3 += 1;
tmpMeta8 = omc_DAEUtil_findAllMatchingElements(threadData, _inDae, boxvar_DAEUtil_isInnerVar, boxvar_DAEUtil_isOuterVar, &tmpMeta6);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
_innerVars = tmpMeta9;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_outerVars = tmpMeta7;
tmpMeta10 = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _innerVars);
tmpMeta11 = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _outerVars);
omc_InnerOuter_checkMissingInnerDecl1(threadData, tmpMeta10, tmpMeta11);
goto tmp2_done;
}
case 2: {
if (0 != tmp3_1) goto tmp2_end;
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
;
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_InnerOuter_checkMissingInnerDecl(threadData_t *threadData, modelica_metatype _inDae, modelica_metatype _callScope)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_callScope);
omc_InnerOuter_checkMissingInnerDecl(threadData, _inDae, tmp1);
return;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_InnerOuter_lookupVarInnerOuterAttr(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _inIH, modelica_metatype _cr1, modelica_metatype _cr2, modelica_boolean *out_isOuter)
{
modelica_boolean _isInner;
modelica_boolean _isOuter;
modelica_boolean tmp1_c0 __attribute__((unused)) = 0;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _io = NULL;
modelica_metatype _io1 = NULL;
modelica_metatype _io2 = NULL;
modelica_boolean _isInner1;
modelica_boolean _isInner2;
modelica_boolean _isOuter1;
modelica_boolean _isOuter2;
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
omc_ErrorExt_setCheckpoint(threadData, _OMC_LIT55);
omc_Lookup_lookupVar(threadData, _cache, _env, _cr1, &tmpMeta6, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 6));
_io1 = tmpMeta7;
omc_Lookup_lookupVar(threadData, _cache, _env, _cr2, &tmpMeta8, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 6));
_io2 = tmpMeta9;
_isInner1 = omc_InnerOuter_innerOuterBooleans(threadData, _io1 ,&_isOuter1);
_isInner2 = omc_InnerOuter_innerOuterBooleans(threadData, _io2 ,&_isOuter2);
_isInner = (_isInner1 || _isInner2);
_isOuter = (_isOuter1 || _isOuter2);
omc_ErrorExt_rollBack(threadData, _OMC_LIT55);
tmp1_c0 = _isInner;
tmp1_c1 = _isOuter;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
omc_Lookup_lookupVar(threadData, _cache, _env, _cr1, &tmpMeta10, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 6));
_io = tmpMeta11;
_isInner = omc_InnerOuter_innerOuterBooleans(threadData, _io ,&_isOuter);
omc_ErrorExt_rollBack(threadData, _OMC_LIT55);
tmp1_c0 = _isInner;
tmp1_c1 = _isOuter;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
omc_Lookup_lookupVar(threadData, _cache, _env, _cr2, &tmpMeta12, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 6));
_io = tmpMeta13;
_isInner = omc_InnerOuter_innerOuterBooleans(threadData, _io ,&_isOuter);
omc_ErrorExt_rollBack(threadData, _OMC_LIT55);
tmp1_c0 = _isInner;
tmp1_c1 = _isOuter;
goto tmp3_done;
}
case 3: {
omc_ErrorExt_rollBack(threadData, _OMC_LIT55);
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
_isInner = tmp1_c0;
_isOuter = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_isOuter) { *out_isOuter = _isOuter; }
return _isInner;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InnerOuter_lookupVarInnerOuterAttr(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _inIH, modelica_metatype _cr1, modelica_metatype _cr2, modelica_metatype *out_isOuter)
{
modelica_boolean _isOuter;
modelica_boolean _isInner;
modelica_metatype out_isInner;
_isInner = omc_InnerOuter_lookupVarInnerOuterAttr(threadData, _cache, _env, _inIH, _cr1, _cr2, &_isOuter);
out_isInner = mmc_mk_icon(_isInner);
if (out_isOuter) { *out_isOuter = mmc_mk_icon(_isOuter); }
return out_isInner;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_removeOuter(threadData_t *threadData, modelica_metatype _io)
{
modelica_metatype _outIo = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _io;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
tmpMeta1 = _OMC_LIT36;
goto tmp3_done;
}
case 3: {
tmpMeta1 = _OMC_LIT56;
goto tmp3_done;
}
case 5: {
tmpMeta1 = _OMC_LIT56;
goto tmp3_done;
}
case 6: {
tmpMeta1 = _OMC_LIT36;
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
_outIo = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outIo;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_addOuterConnectIfEmptyNoEnv(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPre, modelica_metatype _inSets, modelica_boolean _added, modelica_metatype _cr1, modelica_metatype _iio1, modelica_metatype _f1, modelica_metatype _cr2, modelica_metatype _iio2, modelica_metatype _f2, modelica_metatype _info)
{
modelica_metatype _outSets = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;volatile modelica_boolean tmp4_5;volatile modelica_metatype tmp4_6;volatile modelica_metatype tmp4_7;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inIH;
tmp4_4 = _inSets;
tmp4_5 = _added;
tmp4_6 = _iio1;
tmp4_7 = _iio2;
{
modelica_metatype _vt1 = NULL;
modelica_metatype _vt2 = NULL;
modelica_metatype _t1 = NULL;
modelica_metatype _t2 = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _ih = NULL;
modelica_metatype _sets = NULL;
modelica_integer _sc;
modelica_metatype _cl = NULL;
modelica_metatype _oc = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _io1 = NULL;
modelica_metatype _io2 = NULL;
modelica_metatype _pre = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (1 != tmp4_5) goto tmp3_end;
tmp4 += 2;
tmpMeta1 = _inSets;
goto tmp3_done;
}
case 1: {
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
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_integer tmp21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
if (0 != tmp4_5) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 3));
tmp8 = mmc_unbox_integer(tmpMeta7);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 4));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 5));
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_sets = tmpMeta6;
_sc = tmp8;
_cl = tmpMeta9;
_oc = tmpMeta10;
_io1 = tmp4_6;
_io2 = tmp4_7;
tmpMeta15 = omc_Lookup_lookupVar(threadData, _cache, _env, _cr1, &tmpMeta11, &tmpMeta14, NULL, NULL, NULL, NULL, NULL, NULL);
_cache = tmpMeta15;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 4));
_ct = tmpMeta12;
_vt1 = tmpMeta13;
_t1 = tmpMeta14;
_pre = _OMC_LIT45;
_t2 = _t1;
_vt2 = _vt1;
_io1 = omc_InnerOuter_removeOuter(threadData, _io1);
_io2 = omc_InnerOuter_removeOuter(threadData, _io2);
tmpMeta23 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta24 = mmc_mk_box5(3, &DAE_Connect_Sets_SETS__desc, _sets, mmc_mk_integer(_sc), _cl, tmpMeta23);
tmpMeta25 = omc_InstSection_connectComponents(threadData, _cache, _env, _ih, tmpMeta24, _pre, _cr1, _f1, _t1, _vt1, _cr2, _f2, _t2, _vt2, _ct, _io1, _io2, _OMC_LIT57, _info, &tmpMeta16, &tmpMeta17, &tmpMeta18, NULL, NULL);
_cache = tmpMeta25;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 3));
tmp21 = mmc_unbox_integer(tmpMeta20);
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 4));
_env = tmpMeta16;
_ih = tmpMeta17;
_sets = tmpMeta19;
_sc = tmp21;
_cl = tmpMeta22;
tmpMeta26 = mmc_mk_box5(3, &DAE_Connect_Sets_SETS__desc, _sets, mmc_mk_integer(_sc), _cl, _oc);
tmpMeta1 = tmpMeta26;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_integer tmp29;
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
modelica_integer tmp42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
if (0 != tmp4_5) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 2));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 3));
tmp29 = mmc_unbox_integer(tmpMeta28);
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 4));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 5));
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_sets = tmpMeta27;
_sc = tmp29;
_cl = tmpMeta30;
_oc = tmpMeta31;
_io1 = tmp4_6;
_io2 = tmp4_7;
_pre = _OMC_LIT45;
tmpMeta36 = omc_Lookup_lookupVar(threadData, _cache, _env, _cr2, &tmpMeta32, &tmpMeta35, NULL, NULL, NULL, NULL, NULL, NULL);
_cache = tmpMeta36;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 2));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 4));
_ct = tmpMeta33;
_vt2 = tmpMeta34;
_t2 = tmpMeta35;
_t1 = _t2;
_vt1 = _vt2;
_io1 = omc_InnerOuter_removeOuter(threadData, _io1);
_io2 = omc_InnerOuter_removeOuter(threadData, _io2);
tmpMeta44 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta45 = mmc_mk_box5(3, &DAE_Connect_Sets_SETS__desc, _sets, mmc_mk_integer(_sc), _cl, tmpMeta44);
tmpMeta46 = omc_InstSection_connectComponents(threadData, _cache, _env, _ih, tmpMeta45, _pre, _cr1, _f1, _t1, _vt1, _cr2, _f2, _t2, _vt2, _ct, _io1, _io2, _OMC_LIT57, _info, &tmpMeta37, &tmpMeta38, &tmpMeta39, NULL, NULL);
_cache = tmpMeta46;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 2));
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 3));
tmp42 = mmc_unbox_integer(tmpMeta41);
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 4));
_env = tmpMeta37;
_ih = tmpMeta38;
_sets = tmpMeta40;
_sc = tmp42;
_cl = tmpMeta43;
tmpMeta47 = mmc_mk_box5(3, &DAE_Connect_Sets_SETS__desc, _sets, mmc_mk_integer(_sc), _cl, _oc);
tmpMeta1 = tmpMeta47;
goto tmp3_done;
}
case 3: {
fputs(MMC_STRINGDATA(_OMC_LIT58),stdout);
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
_outSets = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outSets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InnerOuter_addOuterConnectIfEmptyNoEnv(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPre, modelica_metatype _inSets, modelica_metatype _added, modelica_metatype _cr1, modelica_metatype _iio1, modelica_metatype _f1, modelica_metatype _cr2, modelica_metatype _iio2, modelica_metatype _f2, modelica_metatype _info)
{
modelica_integer tmp1;
modelica_metatype _outSets = NULL;
tmp1 = mmc_unbox_integer(_added);
_outSets = omc_InnerOuter_addOuterConnectIfEmptyNoEnv(threadData, _inCache, _inEnv, _inIH, _inPre, _inSets, tmp1, _cr1, _iio1, _f1, _cr2, _iio2, _f2, _info);
return _outSets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_addOuterConnectIfEmpty(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _pre, modelica_metatype _inSets, modelica_boolean _added, modelica_metatype _cr1, modelica_metatype _iio1, modelica_metatype _f1, modelica_metatype _cr2, modelica_metatype _iio2, modelica_metatype _f2, modelica_metatype _info, modelica_metatype _inCGraph, modelica_metatype *out_outCGraph)
{
modelica_metatype _outSets = NULL;
modelica_metatype _outCGraph = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_metatype tmp4_4;modelica_boolean tmp4_5;modelica_metatype tmp4_6;modelica_metatype tmp4_7;modelica_metatype tmp4_8;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inIH;
tmp4_4 = _inSets;
tmp4_5 = _added;
tmp4_6 = _iio1;
tmp4_7 = _iio2;
tmp4_8 = _inCGraph;
{
modelica_metatype _vt1 = NULL;
modelica_metatype _vt2 = NULL;
modelica_metatype _t1 = NULL;
modelica_metatype _t2 = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _ih = NULL;
modelica_metatype _sets = NULL;
modelica_integer _sc;
modelica_metatype _cl = NULL;
modelica_metatype _oc = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _io1 = NULL;
modelica_metatype _io2 = NULL;
modelica_metatype _graph = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (1 != tmp4_5) goto tmp3_end;
tmpMeta[0+0] = _inSets;
tmpMeta[0+1] = _inCGraph;
goto tmp3_done;
}
case 1: {
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
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_integer tmp25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
if (0 != tmp4_5) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 3));
tmp8 = mmc_unbox_integer(tmpMeta7);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 4));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 5));
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_sets = tmpMeta6;
_sc = tmp8;
_cl = tmpMeta9;
_oc = tmpMeta10;
_io1 = tmp4_6;
_io2 = tmp4_7;
_graph = tmp4_8;
tmpMeta15 = omc_Lookup_lookupVar(threadData, _cache, _env, _cr1, &tmpMeta11, &tmpMeta14, NULL, NULL, NULL, NULL, NULL, NULL);
_cache = tmpMeta15;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 4));
_ct = tmpMeta12;
_vt1 = tmpMeta13;
_t1 = tmpMeta14;
tmpMeta19 = omc_Lookup_lookupVar(threadData, _cache, _env, _cr2, &tmpMeta16, &tmpMeta18, NULL, NULL, NULL, NULL, NULL, NULL);
_cache = tmpMeta19;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 4));
_vt2 = tmpMeta17;
_t2 = tmpMeta18;
_io1 = omc_InnerOuter_removeOuter(threadData, _io1);
_io2 = omc_InnerOuter_removeOuter(threadData, _io2);
tmpMeta28 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta29 = mmc_mk_box5(3, &DAE_Connect_Sets_SETS__desc, _sets, mmc_mk_integer(_sc), _cl, tmpMeta28);
tmpMeta30 = omc_InstSection_connectComponents(threadData, _cache, _env, _ih, tmpMeta29, _pre, _cr1, _f1, _t1, _vt1, _cr2, _f2, _t2, _vt2, _ct, _io1, _io2, _graph, _info, &tmpMeta20, &tmpMeta21, &tmpMeta22, NULL, &tmpMeta27);
_cache = tmpMeta30;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 2));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 3));
tmp25 = mmc_unbox_integer(tmpMeta24);
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 4));
_env = tmpMeta20;
_ih = tmpMeta21;
_sets = tmpMeta23;
_sc = tmp25;
_cl = tmpMeta26;
_graph = tmpMeta27;
tmpMeta31 = mmc_mk_box5(3, &DAE_Connect_Sets_SETS__desc, _sets, mmc_mk_integer(_sc), _cl, _oc);
tmpMeta[0+0] = tmpMeta31;
tmpMeta[0+1] = _graph;
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
_outSets = tmpMeta[0+0];
_outCGraph = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outCGraph) { *out_outCGraph = _outCGraph; }
return _outSets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InnerOuter_addOuterConnectIfEmpty(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _pre, modelica_metatype _inSets, modelica_metatype _added, modelica_metatype _cr1, modelica_metatype _iio1, modelica_metatype _f1, modelica_metatype _cr2, modelica_metatype _iio2, modelica_metatype _f2, modelica_metatype _info, modelica_metatype _inCGraph, modelica_metatype *out_outCGraph)
{
modelica_integer tmp1;
modelica_metatype _outSets = NULL;
tmp1 = mmc_unbox_integer(_added);
_outSets = omc_InnerOuter_addOuterConnectIfEmpty(threadData, _inCache, _inEnv, _inIH, _pre, _inSets, tmp1, _cr1, _iio1, _f1, _cr2, _iio2, _f2, _info, _inCGraph, out_outCGraph);
return _outSets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_convertInnerOuterInnerToOuter(threadData_t *threadData, modelica_metatype _io)
{
modelica_metatype _oio = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _io;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT39;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _io;
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
_oio = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _oio;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_retrieveOuterConnections2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPrefix, modelica_metatype _inOuterConnects, modelica_metatype _inSets, modelica_boolean _inTopCall, modelica_metatype _inCGraph, modelica_metatype *out_outSets, modelica_metatype *out_outInnerOuterConnects, modelica_metatype *out_outCGraph)
{
modelica_metatype _outOuterConnects = NULL;
modelica_metatype _outSets = NULL;
modelica_metatype _outInnerOuterConnects = NULL;
modelica_metatype _outCGraph = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_boolean tmp4_3;volatile modelica_metatype tmp4_4;
tmp4_1 = _inOuterConnects;
tmp4_2 = _inSets;
tmp4_3 = _inTopCall;
tmp4_4 = _inCGraph;
{
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
modelica_metatype _io1 = NULL;
modelica_metatype _io2 = NULL;
modelica_metatype _f1 = NULL;
modelica_metatype _f2 = NULL;
modelica_metatype _oc = NULL;
modelica_metatype _rest_oc = NULL;
modelica_metatype _ioc = NULL;
modelica_boolean _inner1;
modelica_boolean _inner2;
modelica_boolean _outer1;
modelica_boolean _outer2;
modelica_boolean _added;
modelica_metatype _scope = NULL;
modelica_metatype _source = NULL;
modelica_metatype _info = NULL;
modelica_metatype _sets = NULL;
modelica_metatype _graph = NULL;
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
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp4 += 3;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = _inOuterConnects;
tmpMeta[0+1] = _inSets;
tmpMeta[0+2] = tmpMeta6;
tmpMeta[0+3] = _inCGraph;
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
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_boolean tmp18;
modelica_boolean tmp19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_boolean tmp22;
modelica_metatype tmpMeta23;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 6));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 7));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 8));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 9));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
_scope = tmpMeta9;
_cr1 = tmpMeta10;
_io1 = tmpMeta11;
_f1 = tmpMeta12;
_cr2 = tmpMeta13;
_io2 = tmpMeta14;
_f2 = tmpMeta15;
_source = tmpMeta16;
_info = tmpMeta17;
_rest_oc = tmpMeta8;
_sets = tmp4_2;
_graph = tmp4_4;
_inner1 = omc_InnerOuter_lookupVarInnerOuterAttr(threadData, _inCache, _inEnv, _inIH, _cr1, _cr2 ,&_outer1);
tmp18 = _inner1;
if (1 != tmp18) goto goto_2;
tmp19 = _outer1;
if (0 != tmp19) goto goto_2;
_cr1 = omc_InnerOuter_removeInnerPrefixFromCref(threadData, _inPrefix, _cr1);
_cr2 = omc_InnerOuter_removeInnerPrefixFromCref(threadData, _inPrefix, _cr2);
_sets = omc_ConnectUtil_addOuterConnectToSets(threadData, _cr1, _cr2, _io1, _io2, _f1, _f2, _sets, _info ,&_added);
_sets = omc_InnerOuter_addOuterConnectIfEmpty(threadData, _inCache, _inEnv, _inIH, _inPrefix, _sets, _added, _cr1, _io1, _f1, _cr2, _io2, _f2, _info, _graph ,&_graph);
_rest_oc = omc_InnerOuter_retrieveOuterConnections2(threadData, _inCache, _inEnv, _inIH, _inPrefix, _rest_oc, _sets, _inTopCall, _graph ,&_sets ,&_ioc ,&_graph);
tmp22 = (modelica_boolean)_outer1;
if(tmp22)
{
tmpMeta21 = mmc_mk_box9(3, &DAE_Connect_OuterConnect_OUTERCONNECT__desc, _scope, _cr1, _io1, _f1, _cr2, _io2, _f2, _source);
tmpMeta20 = mmc_mk_cons(tmpMeta21, _rest_oc);
tmpMeta23 = tmpMeta20;
}
else
{
tmpMeta23 = _rest_oc;
}
_rest_oc = tmpMeta23;
tmpMeta[0+0] = _rest_oc;
tmpMeta[0+1] = _sets;
tmpMeta[0+2] = _ioc;
tmpMeta[0+3] = _graph;
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
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_boolean tmp34;
modelica_boolean tmp35;
if (1 != tmp4_3) goto tmp3_end;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta24 = MMC_CAR(tmp4_1);
tmpMeta25 = MMC_CDR(tmp4_1);
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 3));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 4));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 5));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 6));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 7));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 8));
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 9));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 2));
_cr1 = tmpMeta26;
_io1 = tmpMeta27;
_f1 = tmpMeta28;
_cr2 = tmpMeta29;
_io2 = tmpMeta30;
_f2 = tmpMeta31;
_info = tmpMeta33;
_rest_oc = tmpMeta25;
_sets = tmp4_2;
_graph = tmp4_4;
_inner1 = omc_InnerOuter_innerOuterBooleans(threadData, _io1 ,&_outer1);
_inner2 = omc_InnerOuter_innerOuterBooleans(threadData, _io2 ,&_outer2);
tmp34 = (_inner1 || _inner2);
if (1 != tmp34) goto goto_2;
tmp35 = (_outer1 || _outer2);
if (0 != tmp35) goto goto_2;
_io1 = omc_InnerOuter_convertInnerOuterInnerToOuter(threadData, _io1);
_io2 = omc_InnerOuter_convertInnerOuterInnerToOuter(threadData, _io2);
_sets = omc_ConnectUtil_addOuterConnectToSets(threadData, _cr1, _cr2, _io1, _io2, _f1, _f2, _sets, _info ,&_added);
_sets = omc_InnerOuter_addOuterConnectIfEmpty(threadData, _inCache, _inEnv, _inIH, _inPrefix, _sets, _added, _cr1, _io1, _f1, _cr2, _io2, _f2, _info, _graph ,&_graph);
tmpMeta[0+0] = omc_InnerOuter_retrieveOuterConnections2(threadData, _inCache, _inEnv, _inIH, _inPrefix, _rest_oc, _sets, 1, _graph, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3]);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta36 = MMC_CAR(tmp4_1);
tmpMeta37 = MMC_CDR(tmp4_1);
_oc = tmpMeta36;
_rest_oc = tmpMeta37;
_sets = tmp4_2;
_graph = tmp4_4;
_rest_oc = omc_InnerOuter_retrieveOuterConnections2(threadData, _inCache, _inEnv, _inIH, _inPrefix, _rest_oc, _sets, _inTopCall, _graph ,&_sets ,&_ioc ,&_graph);
tmpMeta38 = mmc_mk_cons(_oc, _rest_oc);
tmpMeta[0+0] = tmpMeta38;
tmpMeta[0+1] = _sets;
tmpMeta[0+2] = _ioc;
tmpMeta[0+3] = _graph;
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
_outOuterConnects = tmpMeta[0+0];
_outSets = tmpMeta[0+1];
_outInnerOuterConnects = tmpMeta[0+2];
_outCGraph = tmpMeta[0+3];
_return: OMC_LABEL_UNUSED
if (out_outSets) { *out_outSets = _outSets; }
if (out_outInnerOuterConnects) { *out_outInnerOuterConnects = _outInnerOuterConnects; }
if (out_outCGraph) { *out_outCGraph = _outCGraph; }
return _outOuterConnects;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InnerOuter_retrieveOuterConnections2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPrefix, modelica_metatype _inOuterConnects, modelica_metatype _inSets, modelica_metatype _inTopCall, modelica_metatype _inCGraph, modelica_metatype *out_outSets, modelica_metatype *out_outInnerOuterConnects, modelica_metatype *out_outCGraph)
{
modelica_integer tmp1;
modelica_metatype _outOuterConnects = NULL;
tmp1 = mmc_unbox_integer(_inTopCall);
_outOuterConnects = omc_InnerOuter_retrieveOuterConnections2(threadData, _inCache, _inEnv, _inIH, _inPrefix, _inOuterConnects, _inSets, tmp1, _inCGraph, out_outSets, out_outInnerOuterConnects, out_outCGraph);
return _outOuterConnects;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_removeInnerPrefixFromCref(threadData_t *threadData, modelica_metatype _inPrefix, modelica_metatype _inCref)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inPrefix;
{
modelica_metatype _crefPrefix = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmpMeta1 = _inCref;
goto tmp3_done;
}
case 1: {
_crefPrefix = omc_PrefixUtil_prefixToCref(threadData, _inPrefix);
tmpMeta1 = omc_ComponentReference_crefStripPrefix(threadData, _inCref, _crefPrefix);
goto tmp3_done;
}
case 2: {
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
if (++tmp4 < 3) {
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
DLLExport
modelica_metatype omc_InnerOuter_retrieveOuterConnections(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPrefix, modelica_metatype _inSets, modelica_boolean _inTopCall, modelica_metatype _inCGraph, modelica_metatype *out_outInnerOuterConnects, modelica_metatype *out_outCGraph)
{
modelica_metatype _outSets = NULL;
modelica_metatype _outInnerOuterConnects = NULL;
modelica_metatype _outCGraph = NULL;
modelica_metatype _oc = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inSets;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 5));
_oc = tmpMeta2;
_oc = omc_InnerOuter_retrieveOuterConnections2(threadData, _inCache, _inEnv, _inIH, _inPrefix, _oc, _inSets, _inTopCall, _inCGraph ,&_outSets ,&_outInnerOuterConnects ,&_outCGraph);
tmpMeta3 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta3), MMC_UNTAGPTR(_outSets), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta3))[5] = _oc;
_outSets = tmpMeta3;
_return: OMC_LABEL_UNUSED
if (out_outInnerOuterConnects) { *out_outInnerOuterConnects = _outInnerOuterConnects; }
if (out_outCGraph) { *out_outCGraph = _outCGraph; }
return _outSets;
}
modelica_metatype boxptr_InnerOuter_retrieveOuterConnections(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPrefix, modelica_metatype _inSets, modelica_metatype _inTopCall, modelica_metatype _inCGraph, modelica_metatype *out_outInnerOuterConnects, modelica_metatype *out_outCGraph)
{
modelica_integer tmp1;
modelica_metatype _outSets = NULL;
tmp1 = mmc_unbox_integer(_inTopCall);
_outSets = omc_InnerOuter_retrieveOuterConnections(threadData, _inCache, _inEnv, _inIH, _inPrefix, _inSets, tmp1, _inCGraph, out_outInnerOuterConnects, out_outCGraph);
return _outSets;
}
DLLExport
modelica_metatype omc_InnerOuter_renameUniqueVarsInTopScope(threadData_t *threadData, modelica_boolean _isTopScope, modelica_metatype _dae)
{
modelica_metatype _odae = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_boolean tmp4_1;
tmp4_1 = _isTopScope;
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
tmp6 = omc_System_getHasInnerOuterDefinitions(threadData);
if (0 != tmp6) goto goto_2;
tmpMeta1 = _dae;
goto tmp3_done;
}
case 1: {
if (1 != tmp4_1) goto tmp3_end;
tmp4 += 1;
tmpMeta1 = omc_DAEUtil_renameUniqueOuterVars(threadData, _dae);
goto tmp3_done;
}
case 2: {
if (0 != tmp4_1) goto tmp3_end;
tmpMeta1 = _dae;
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
_odae = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _odae;
}
modelica_metatype boxptr_InnerOuter_renameUniqueVarsInTopScope(threadData_t *threadData, modelica_metatype _isTopScope, modelica_metatype _dae)
{
modelica_integer tmp1;
modelica_metatype _odae = NULL;
tmp1 = mmc_unbox_integer(_isTopScope);
_odae = omc_InnerOuter_renameUniqueVarsInTopScope(threadData, tmp1, _dae);
return _odae;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_extractCommonPart(threadData_t *threadData, modelica_metatype _prefixedCref, modelica_metatype _innerCref)
{
modelica_metatype _cr3 = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _c1 = NULL;
modelica_metatype _c2 = NULL;
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
_c1 = omc_ComponentReference_crefLastCref(threadData, _prefixedCref);
_c2 = omc_ComponentReference_crefLastCref(threadData, _innerCref);
tmp6 = omc_ComponentReference_crefEqual(threadData, _c1, _c2);
if (1 != tmp6) goto goto_2;
tmpMeta1 = omc_ComponentReference_crefSetLastType(threadData, _innerCref, omc_ComponentReference_crefLastType(threadData, _prefixedCref));
goto tmp3_done;
}
case 1: {
_c2 = omc_ComponentReference_crefStripLastIdent(threadData, _innerCref);
tmpMeta1 = omc_InnerOuter_extractCommonPart(threadData, _prefixedCref, _c2);
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
_cr3 = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _cr3;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_stripCommonCrefPart(threadData_t *threadData, modelica_metatype _outerCr, modelica_metatype _innerCr, modelica_metatype *out_outInnerCr)
{
modelica_metatype _outOuterCr = NULL;
modelica_metatype _outInnerCr = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _outerCr;
tmp4_2 = _innerCr;
{
modelica_string _id1 = NULL;
modelica_string _id2 = NULL;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
_id1 = tmpMeta6;
_cr1 = tmpMeta7;
_id2 = tmpMeta8;
_cr2 = tmpMeta9;
tmp10 = (stringEqual(_id1, _id2));
if (1 != tmp10) goto goto_2;
tmpMeta[0+0] = omc_InnerOuter_stripCommonCrefPart(threadData, _cr1, _cr2, &tmpMeta[0+1]);
goto tmp3_done;
}
case 1: {
_cr1 = tmp4_1;
_cr2 = tmp4_2;
tmpMeta[0+0] = _cr1;
tmpMeta[0+1] = _cr2;
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
_outOuterCr = tmpMeta[0+0];
_outInnerCr = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outInnerCr) { *out_outInnerCr = _outInnerCr; }
return _outOuterCr;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_InnerOuter_isInnerOuterMatch(threadData_t *threadData, modelica_metatype _outerCr, modelica_metatype _innerCr)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _innerCr1 = NULL;
modelica_metatype _outerCr1 = NULL;
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
tmp6 = omc_ComponentReference_crefLastIdentEqual(threadData, _outerCr, _innerCr);
if (0 != tmp6) goto goto_2;
tmp1 = 0;
goto tmp3_done;
}
case 1: {
_outerCr1 = omc_InnerOuter_stripCommonCrefPart(threadData, _outerCr, _innerCr ,&_innerCr1);
tmp1 = omc_ComponentReference_crefContainedIn(threadData, _outerCr1, _innerCr1);
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InnerOuter_isInnerOuterMatch(threadData_t *threadData, modelica_metatype _outerCr, modelica_metatype _innerCr)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_InnerOuter_isInnerOuterMatch(threadData, _outerCr, _innerCr);
out_res = mmc_mk_icon(_res);
return out_res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_buildInnerOuterReplVar(threadData_t *threadData, modelica_metatype _innerVar, modelica_metatype _outerVars, modelica_metatype _inRepl)
{
modelica_metatype _outRepl = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _innerVar;
tmp4_2 = _inRepl;
{
modelica_metatype _outerCrs = NULL;
modelica_metatype _ourOuterCrs = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _repl = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 14));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,2,0) == 0) goto tmp3_end;
_cr = tmpMeta6;
_repl = tmp4_2;
_outerCrs = omc_List_map(threadData, _outerVars, boxvar_DAEUtil_varCref);
_ourOuterCrs = omc_List_select1(threadData, _outerCrs, boxvar_InnerOuter_isInnerOuterMatch, _cr);
_cr = omc_DAEUtil_nameInnerouterUniqueCref(threadData, _cr);
tmpMeta1 = omc_List_fold1r(threadData, _ourOuterCrs, boxvar_VarTransform_addReplacement, omc_Expression_crefExp(threadData, _cr), _repl);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cr = tmpMeta8;
_repl = tmp4_2;
_outerCrs = omc_List_map(threadData, _outerVars, boxvar_DAEUtil_varCref);
_ourOuterCrs = omc_List_select1(threadData, _outerCrs, boxvar_InnerOuter_isInnerOuterMatch, _cr);
tmpMeta1 = omc_List_fold1r(threadData, _ourOuterCrs, boxvar_VarTransform_addReplacement, omc_Expression_crefExp(threadData, _cr), _repl);
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InnerOuter_buildInnerOuterRepl(threadData_t *threadData, modelica_metatype _innerVars, modelica_metatype _outerVars, modelica_metatype _inRepl)
{
modelica_metatype _outRepl = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _innerVars;
tmp4_2 = _inRepl;
{
modelica_metatype _repl = NULL;
modelica_metatype _v = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_repl = tmp4_2;
tmpMeta1 = _repl;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_v = tmpMeta6;
_rest = tmpMeta7;
_repl = tmp4_2;
_repl = omc_InnerOuter_buildInnerOuterReplVar(threadData, _v, _outerVars, _repl);
_innerVars = _rest;
_inRepl = _repl;
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
DLLExport
modelica_metatype omc_InnerOuter_changeInnerOuterInOuterConnect2(threadData_t *threadData, modelica_metatype _inOC)
{
modelica_metatype _outOC = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inOC;
{
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
modelica_metatype _ncr1 = NULL;
modelica_metatype _ncr2 = NULL;
modelica_metatype _io1 = NULL;
modelica_metatype _io2 = NULL;
modelica_metatype _f1 = NULL;
modelica_metatype _f2 = NULL;
modelica_metatype _scope = NULL;
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_boolean tmp14;
modelica_boolean tmp15;
modelica_metatype tmpMeta16;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 9));
_scope = tmpMeta6;
_cr1 = tmpMeta7;
_io1 = tmpMeta8;
_f1 = tmpMeta9;
_cr2 = tmpMeta10;
_io2 = tmpMeta11;
_f2 = tmpMeta12;
_source = tmpMeta13;
omc_InnerOuter_innerOuterBooleans(threadData, _io1, &tmp14);
if (1 != tmp14) goto goto_2;
_ncr1 = omc_PrefixUtil_prefixToCref(threadData, _scope);
tmp15 = omc_ComponentReference_crefFirstCrefLastCrefEqual(threadData, _ncr1, _cr1);
if (0 != tmp15) goto goto_2;
tmpMeta16 = mmc_mk_box9(3, &DAE_Connect_OuterConnect_OUTERCONNECT__desc, _scope, _cr1, _OMC_LIT56, _f1, _cr2, _io2, _f2, _source);
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
modelica_boolean tmp25;
modelica_boolean tmp26;
modelica_metatype tmpMeta27;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 9));
_scope = tmpMeta17;
_cr1 = tmpMeta18;
_io1 = tmpMeta19;
_f1 = tmpMeta20;
_cr2 = tmpMeta21;
_io2 = tmpMeta22;
_f2 = tmpMeta23;
_source = tmpMeta24;
omc_InnerOuter_innerOuterBooleans(threadData, _io2, &tmp25);
if (1 != tmp25) goto goto_2;
_ncr2 = omc_PrefixUtil_prefixToCref(threadData, _scope);
tmp26 = omc_ComponentReference_crefFirstCrefLastCrefEqual(threadData, _ncr2, _cr2);
if (0 != tmp26) goto goto_2;
tmpMeta27 = mmc_mk_box9(3, &DAE_Connect_OuterConnect_OUTERCONNECT__desc, _scope, _cr1, _io1, _f1, _cr2, _OMC_LIT56, _f2, _source);
tmpMeta1 = tmpMeta27;
goto tmp3_done;
}
case 2: {
tmpMeta1 = _inOC;
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
_outOC = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outOC;
}
DLLExport
modelica_metatype omc_InnerOuter_changeInnerOuterInOuterConnect(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsets)
{
modelica_metatype _sets = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
tmpMeta1 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta1), MMC_UNTAGPTR(_sets), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta1))[5] = omc_List_map(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 5))), boxvar_InnerOuter_changeInnerOuterInOuterConnect2);
_sets = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _sets;
}
DLLExport
modelica_metatype omc_InnerOuter_handleInnerOuterEquations(threadData_t *threadData, modelica_metatype _io, modelica_metatype _inDae, modelica_metatype _inIH, modelica_metatype _inGraphNew, modelica_metatype _inGraph, modelica_metatype *out_outIH, modelica_metatype *out_outGraph)
{
modelica_metatype _odae = NULL;
modelica_metatype _outIH = NULL;
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;volatile modelica_metatype tmp4_5;
tmp4_1 = _io;
tmp4_2 = _inDae;
tmp4_3 = _inIH;
tmp4_4 = _inGraphNew;
tmp4_5 = _inGraph;
{
modelica_metatype _dae1 = NULL;
modelica_metatype _dae2 = NULL;
modelica_metatype _dae = NULL;
modelica_metatype _graphNew = NULL;
modelica_metatype _graph = NULL;
modelica_metatype _ih = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
_dae = tmp4_2;
_ih = tmp4_3;
_graph = tmp4_5;
tmp4 += 3;
_odae = omc_DAEUtil_splitDAEIntoVarsAndEquations(threadData, _dae, NULL);
tmpMeta[0+0] = _odae;
tmpMeta[0+1] = _ih;
tmpMeta[0+2] = _graph;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,0) == 0) goto tmp3_end;
_dae = tmp4_2;
_ih = tmp4_3;
_graph = tmp4_5;
tmp4 += 2;
_dae1 = omc_DAEUtil_splitDAEIntoVarsAndEquations(threadData, _dae ,&_dae2);
_dae2 = omc_DAEUtil_nameUniqueOuterVars(threadData, _dae2);
_dae = omc_DAEUtil_joinDaes(threadData, _dae1, _dae2);
tmpMeta[0+0] = _dae;
tmpMeta[0+1] = _ih;
tmpMeta[0+2] = _graph;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
_dae = tmp4_2;
_ih = tmp4_3;
_graphNew = tmp4_4;
tmp4 += 1;
tmpMeta[0+0] = _dae;
tmpMeta[0+1] = _ih;
tmpMeta[0+2] = _graphNew;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,0) == 0) goto tmp3_end;
_dae = tmp4_2;
_ih = tmp4_3;
_graphNew = tmp4_4;
tmpMeta[0+0] = _dae;
tmpMeta[0+1] = _ih;
tmpMeta[0+2] = _graphNew;
goto tmp3_done;
}
case 4: {
fputs(MMC_STRINGDATA(_OMC_LIT59),stdout);
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
_odae = tmpMeta[0+0];
_outIH = tmpMeta[0+1];
_outGraph = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outIH) { *out_outIH = _outIH; }
if (out_outGraph) { *out_outGraph = _outGraph; }
return _odae;
}
