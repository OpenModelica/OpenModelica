#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "AbsynUtil.c"
#endif
#include "omc_simulation_settings.h"
#include "AbsynUtil.h"
#define _OMC_LIT0_data "choice"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,6,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT0}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "choices"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,7,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT2}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,1,3) {&Absyn_EqMod_NOMOD__desc,}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,1,5) {&Absyn_Direction_BIDIR__desc,}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "-traverse_classes2 failed on class:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,35,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,1,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,1,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "interaction"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,11,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "graphics"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,8,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,1,4) {&Absyn_Msg_NO__MSG__desc,}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,0,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data ", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,2,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data "<"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,1,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data ">"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,1,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "initial"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,7,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT17,1,6) {&Absyn_InnerOuter_NOT__INNER__OUTER__desc,}};
#define _OMC_LIT17 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT17)
#define _OMC_LIT18_data "der"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT18,3,_OMC_LIT18_data);
#define _OMC_LIT18 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT18)
#define _OMC_LIT19_data "inner outer"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT19,11,_OMC_LIT19_data);
#define _OMC_LIT19 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data "inner"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,5,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
#define _OMC_LIT21_data "outer"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT21,5,_OMC_LIT21_data);
#define _OMC_LIT21 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "within ;"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,8,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
#define _OMC_LIT23_data "within "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT23,7,_OMC_LIT23_data);
#define _OMC_LIT23 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT23)
#define _OMC_LIT24_data ";"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT24,1,_OMC_LIT24_data);
#define _OMC_LIT24 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT24)
#define _OMC_LIT25_data "DynamicSelect"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT25,13,_OMC_LIT25_data);
#define _OMC_LIT25 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "LinePattern"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,11,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data "Arrow"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,5,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data "FillPattern"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,11,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data "BorderPattern"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,13,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
#define _OMC_LIT30_data "TextStyle"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT30,9,_OMC_LIT30_data);
#define _OMC_LIT30 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data "Smooth"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,6,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
#define _OMC_LIT32_data "TextAlignment"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT32,13,_OMC_LIT32_data);
#define _OMC_LIT32 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT32)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT33,2,1) {_OMC_LIT32,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT33 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT33)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT34,2,1) {_OMC_LIT31,_OMC_LIT33}};
#define _OMC_LIT34 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT34)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT35,2,1) {_OMC_LIT30,_OMC_LIT34}};
#define _OMC_LIT35 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT35)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT36,2,1) {_OMC_LIT29,_OMC_LIT35}};
#define _OMC_LIT36 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT36)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT37,2,1) {_OMC_LIT28,_OMC_LIT36}};
#define _OMC_LIT37 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT37)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT38,2,1) {_OMC_LIT27,_OMC_LIT37}};
#define _OMC_LIT38 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT38)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT39,2,1) {_OMC_LIT26,_OMC_LIT38}};
#define _OMC_LIT39 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT39)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT40,2,1) {MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT40 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT40)
#define _OMC_LIT41_data "CLASS"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT41,5,_OMC_LIT41_data);
#define _OMC_LIT41 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT41)
#define _OMC_LIT42_data "OPTIMIZATION"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT42,12,_OMC_LIT42_data);
#define _OMC_LIT42 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT42)
#define _OMC_LIT43_data "MODEL"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT43,5,_OMC_LIT43_data);
#define _OMC_LIT43 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT43)
#define _OMC_LIT44_data "RECORD"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT44,6,_OMC_LIT44_data);
#define _OMC_LIT44 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT44)
#define _OMC_LIT45_data "BLOCK"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT45,5,_OMC_LIT45_data);
#define _OMC_LIT45 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT45)
#define _OMC_LIT46_data "CONNECTOR"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT46,9,_OMC_LIT46_data);
#define _OMC_LIT46 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT46)
#define _OMC_LIT47_data "EXPANDABLE CONNECTOR"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT47,20,_OMC_LIT47_data);
#define _OMC_LIT47 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT47)
#define _OMC_LIT48_data "TYPE"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT48,4,_OMC_LIT48_data);
#define _OMC_LIT48 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT48)
#define _OMC_LIT49_data "PACKAGE"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT49,7,_OMC_LIT49_data);
#define _OMC_LIT49 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT49)
#define _OMC_LIT50_data "PURE FUNCTION"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT50,13,_OMC_LIT50_data);
#define _OMC_LIT50 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT50)
#define _OMC_LIT51_data "IMPURE FUNCTION"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT51,15,_OMC_LIT51_data);
#define _OMC_LIT51 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT51)
#define _OMC_LIT52_data "FUNCTION"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT52,8,_OMC_LIT52_data);
#define _OMC_LIT52 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT52)
#define _OMC_LIT53_data "OPERATOR FUNCTION"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT53,17,_OMC_LIT53_data);
#define _OMC_LIT53 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT53)
#define _OMC_LIT54_data "PREDEFINED_INT"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT54,14,_OMC_LIT54_data);
#define _OMC_LIT54 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT54)
#define _OMC_LIT55_data "PREDEFINED_REAL"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT55,15,_OMC_LIT55_data);
#define _OMC_LIT55 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT55)
#define _OMC_LIT56_data "PREDEFINED_STRING"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT56,17,_OMC_LIT56_data);
#define _OMC_LIT56 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT56)
#define _OMC_LIT57_data "PREDEFINED_BOOL"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT57,15,_OMC_LIT57_data);
#define _OMC_LIT57 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT57)
#define _OMC_LIT58_data "PREDEFINED_CLOCK"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT58,16,_OMC_LIT58_data);
#define _OMC_LIT58 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT58)
#define _OMC_LIT59_data "UNIONTYPE"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT59,9,_OMC_LIT59_data);
#define _OMC_LIT59 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT59)
#define _OMC_LIT60_data "* Unknown restriction *"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT60,23,_OMC_LIT60_data);
#define _OMC_LIT60 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT60)
#define _OMC_LIT61_data "AbsynUtil.getCrefFromExp failed "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT61,32,_OMC_LIT61_data);
#define _OMC_LIT61 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT61)
#define _OMC_LIT62_data "AbsynUtil.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT62,12,_OMC_LIT62_data);
#define _OMC_LIT62 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT62)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT63_6,0.0);
#define _OMC_LIT63_6 MMC_REFREALLIT(_OMC_LIT_STRUCT63_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT63,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT62,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1924)),MMC_IMMEDIATE(MMC_TAGFIXNUM(9)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1924)),MMC_IMMEDIATE(MMC_TAGFIXNUM(103)),_OMC_LIT63_6}};
#define _OMC_LIT63 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT63)
#define _OMC_LIT64_data "in traverseExpBidirSubExps("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT64,27,_OMC_LIT64_data);
#define _OMC_LIT64 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT64)
#define _OMC_LIT65_data ") - Unknown expression: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT65,24,_OMC_LIT65_data);
#define _OMC_LIT65 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT65)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT66,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT66 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT66)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT67,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT67 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT67)
#define _OMC_LIT68_data "Internal error %s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT68,17,_OMC_LIT68_data);
#define _OMC_LIT68 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT68)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT69,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT68}};
#define _OMC_LIT69 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT69)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT70,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(63)),_OMC_LIT66,_OMC_LIT67,_OMC_LIT69}};
#define _OMC_LIT70 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT70)
#include "util/modelica.h"
#include "AbsynUtil_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseElementItem(threadData_t *threadData, modelica_metatype _inItem, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_boolean *out_outContinue);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseElementItem(threadData_t *threadData, modelica_metatype _inItem, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_metatype *out_outContinue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseElementItem,2,0) {(void*) boxptr_AbsynUtil_traverseElementItem,0}};
#define boxvar_AbsynUtil_traverseElementItem MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseElementItem)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseClassPartElements(threadData_t *threadData, modelica_metatype _inClassPart, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_boolean *out_outContinue);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseClassPartElements(threadData_t *threadData, modelica_metatype _inClassPart, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_metatype *out_outContinue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseClassPartElements,2,0) {(void*) boxptr_AbsynUtil_traverseClassPartElements,0}};
#define boxvar_AbsynUtil_traverseClassPartElements MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseClassPartElements)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseInnerClassElementspec(threadData_t *threadData, modelica_metatype _inElementSpec, modelica_metatype _inPath, modelica_fnptr _visitor, modelica_metatype _inArg, modelica_boolean _visitProtected);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseInnerClassElementspec(threadData_t *threadData, modelica_metatype _inElementSpec, modelica_metatype _inPath, modelica_fnptr _visitor, modelica_metatype _inArg, modelica_metatype _visitProtected);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseInnerClassElementspec,2,0) {(void*) boxptr_AbsynUtil_traverseInnerClassElementspec,0}};
#define boxvar_AbsynUtil_traverseInnerClassElementspec MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseInnerClassElementspec)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseInnerClassElements(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _inPath, modelica_fnptr _visitor, modelica_metatype _inArg, modelica_boolean _visitProtected);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseInnerClassElements(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _inPath, modelica_fnptr _visitor, modelica_metatype _inArg, modelica_metatype _visitProtected);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseInnerClassElements,2,0) {(void*) boxptr_AbsynUtil_traverseInnerClassElements,0}};
#define boxvar_AbsynUtil_traverseInnerClassElements MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseInnerClassElements)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseInnerClassParts(threadData_t *threadData, modelica_metatype _inClassParts, modelica_metatype _inPath, modelica_fnptr _visitor, modelica_metatype _inArg, modelica_boolean _visitProtected);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseInnerClassParts(threadData_t *threadData, modelica_metatype _inClassParts, modelica_metatype _inPath, modelica_fnptr _visitor, modelica_metatype _inArg, modelica_metatype _visitProtected);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseInnerClassParts,2,0) {(void*) boxptr_AbsynUtil_traverseInnerClassParts,0}};
#define boxvar_AbsynUtil_traverseInnerClassParts MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseInnerClassParts)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseInnerClass(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _path, modelica_fnptr _visitor, modelica_metatype _arg, modelica_boolean _visitProtected);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseInnerClass(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _path, modelica_fnptr _visitor, modelica_metatype _arg, modelica_metatype _visitProtected);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseInnerClass,2,0) {(void*) boxptr_AbsynUtil_traverseInnerClass,0}};
#define boxvar_AbsynUtil_traverseInnerClass MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseInnerClass)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_AbsynUtil_eltsHasLocalClass(threadData_t *threadData, modelica_metatype _inElts);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_eltsHasLocalClass(threadData_t *threadData, modelica_metatype _inElts);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_eltsHasLocalClass,2,0) {(void*) boxptr_AbsynUtil_eltsHasLocalClass,0}};
#define boxvar_AbsynUtil_eltsHasLocalClass MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_eltsHasLocalClass)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_AbsynUtil_partsHasLocalClass(threadData_t *threadData, modelica_metatype _inParts);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_partsHasLocalClass(threadData_t *threadData, modelica_metatype _inParts);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_partsHasLocalClass,2,0) {(void*) boxptr_AbsynUtil_partsHasLocalClass,0}};
#define boxvar_AbsynUtil_partsHasLocalClass MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_partsHasLocalClass)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_AbsynUtil_classHasLocalClasses(threadData_t *threadData, modelica_metatype _cl);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_classHasLocalClasses(threadData_t *threadData, modelica_metatype _cl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_classHasLocalClasses,2,0) {(void*) boxptr_AbsynUtil_classHasLocalClasses,0}};
#define boxvar_AbsynUtil_classHasLocalClasses MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_classHasLocalClasses)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseClasses2(threadData_t *threadData, modelica_metatype _inClasses, modelica_metatype _inPath, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_boolean _inVisitProtected);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseClasses2(threadData_t *threadData, modelica_metatype _inClasses, modelica_metatype _inPath, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype _inVisitProtected);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseClasses2,2,0) {(void*) boxptr_AbsynUtil_traverseClasses2,0}};
#define boxvar_AbsynUtil_traverseClasses2 MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseClasses2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseExpShallowIterator(threadData_t *threadData, modelica_metatype _inIterator, modelica_metatype _inArg, modelica_fnptr _inFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseExpShallowIterator,2,0) {(void*) boxptr_AbsynUtil_traverseExpShallowIterator,0}};
#define boxvar_AbsynUtil_traverseExpShallowIterator MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseExpShallowIterator)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseExpShallowFuncArgs(threadData_t *threadData, modelica_metatype _inArgs, modelica_metatype _inArg, modelica_fnptr _inFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseExpShallowFuncArgs,2,0) {(void*) boxptr_AbsynUtil_traverseExpShallowFuncArgs,0}};
#define boxvar_AbsynUtil_traverseExpShallowFuncArgs MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseExpShallowFuncArgs)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseClassDef(threadData_t *threadData, modelica_metatype _inClassDef, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_boolean *out_outContinue);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseClassDef(threadData_t *threadData, modelica_metatype _inClassDef, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_metatype *out_outContinue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseClassDef,2,0) {(void*) boxptr_AbsynUtil_traverseClassDef,0}};
#define boxvar_AbsynUtil_traverseClassDef MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseClassDef)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseElementSpecComponents(threadData_t *threadData, modelica_metatype _inSpec, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_boolean *out_outContinue);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseElementSpecComponents(threadData_t *threadData, modelica_metatype _inSpec, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_metatype *out_outContinue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseElementSpecComponents,2,0) {(void*) boxptr_AbsynUtil_traverseElementSpecComponents,0}};
#define boxvar_AbsynUtil_traverseElementSpecComponents MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseElementSpecComponents)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseElementComponents(threadData_t *threadData, modelica_metatype _inElement, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_boolean *out_outContinue);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseElementComponents(threadData_t *threadData, modelica_metatype _inElement, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_metatype *out_outContinue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseElementComponents,2,0) {(void*) boxptr_AbsynUtil_traverseElementComponents,0}};
#define boxvar_AbsynUtil_traverseElementComponents MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseElementComponents)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseElementItemComponents(threadData_t *threadData, modelica_metatype _inItem, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_boolean *out_outContinue);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseElementItemComponents(threadData_t *threadData, modelica_metatype _inItem, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_metatype *out_outContinue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseElementItemComponents,2,0) {(void*) boxptr_AbsynUtil_traverseElementItemComponents,0}};
#define boxvar_AbsynUtil_traverseElementItemComponents MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseElementItemComponents)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseClassPartComponents(threadData_t *threadData, modelica_metatype _inClassPart, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_boolean *out_outContinue);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseClassPartComponents(threadData_t *threadData, modelica_metatype _inClassPart, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_metatype *out_outContinue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseClassPartComponents,2,0) {(void*) boxptr_AbsynUtil_traverseClassPartComponents,0}};
#define boxvar_AbsynUtil_traverseClassPartComponents MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseClassPartComponents)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseListGeneric(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_boolean *out_outContinue);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseListGeneric(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_metatype *out_outContinue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseListGeneric,2,0) {(void*) boxptr_AbsynUtil_traverseListGeneric,0}};
#define boxvar_AbsynUtil_traverseListGeneric MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseListGeneric)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_dummyTraverseExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inArg, modelica_metatype *out_outArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_dummyTraverseExp,2,0) {(void*) boxptr_AbsynUtil_dummyTraverseExp,0}};
#define boxvar_AbsynUtil_dummyTraverseExp MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_dummyTraverseExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_getNamedAnnotationStr(threadData_t *threadData, modelica_metatype _inAbsynElementArgLst, modelica_metatype _id, modelica_fnptr _f);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_getNamedAnnotationStr,2,0) {(void*) boxptr_AbsynUtil_getNamedAnnotationStr,0}};
#define boxvar_AbsynUtil_getNamedAnnotationStr MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_getNamedAnnotationStr)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_mergeAnnotations2(threadData_t *threadData, modelica_metatype _oldmods, modelica_metatype _newmods);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_mergeAnnotations2,2,0) {(void*) boxptr_AbsynUtil_mergeAnnotations2,0}};
#define boxvar_AbsynUtil_mergeAnnotations2 MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_mergeAnnotations2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_isInitialTraverseHelper(threadData_t *threadData, modelica_metatype _inExp, modelica_boolean _inBool, modelica_boolean *out_outBool);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_isInitialTraverseHelper(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inBool, modelica_metatype *out_outBool);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_isInitialTraverseHelper,2,0) {(void*) boxptr_AbsynUtil_isInitialTraverseHelper,0}};
#define boxvar_AbsynUtil_isInitialTraverseHelper MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_isInitialTraverseHelper)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_filterNestedClassesParts(threadData_t *threadData, modelica_metatype _classPart, modelica_metatype _inClassParts);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_filterNestedClassesParts,2,0) {(void*) boxptr_AbsynUtil_filterNestedClassesParts,0}};
#define boxvar_AbsynUtil_filterNestedClassesParts MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_filterNestedClassesParts)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_AbsynUtil_filterAnnotationItem(threadData_t *threadData, modelica_metatype _elt);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_filterAnnotationItem(threadData_t *threadData, modelica_metatype _elt);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_filterAnnotationItem,2,0) {(void*) boxptr_AbsynUtil_filterAnnotationItem,0}};
#define boxvar_AbsynUtil_filterAnnotationItem MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_filterAnnotationItem)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_getFunctionInterfaceParts(threadData_t *threadData, modelica_metatype _part, modelica_metatype _elts);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_getFunctionInterfaceParts,2,0) {(void*) boxptr_AbsynUtil_getFunctionInterfaceParts,0}};
#define boxvar_AbsynUtil_getFunctionInterfaceParts MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_getFunctionInterfaceParts)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_stripClassDefComment(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_stripClassDefComment,2,0) {(void*) boxptr_AbsynUtil_stripClassDefComment,0}};
#define boxvar_AbsynUtil_stripClassDefComment MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_stripClassDefComment)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_onlyLiteralsInExpExit(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inLst, modelica_metatype *out_outLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_onlyLiteralsInExpExit,2,0) {(void*) boxptr_AbsynUtil_onlyLiteralsInExpExit,0}};
#define boxvar_AbsynUtil_onlyLiteralsInExpExit MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_onlyLiteralsInExpExit)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_onlyLiteralsInExpEnter(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inLst, modelica_metatype *out_outLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_onlyLiteralsInExpEnter,2,0) {(void*) boxptr_AbsynUtil_onlyLiteralsInExpEnter,0}};
#define boxvar_AbsynUtil_onlyLiteralsInExpEnter MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_onlyLiteralsInExpEnter)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_getIteratorIndexedCrefs(threadData_t *threadData, modelica_metatype _inCref, modelica_string _inIterator, modelica_metatype _inCrefs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_getIteratorIndexedCrefs,2,0) {(void*) boxptr_AbsynUtil_getIteratorIndexedCrefs,0}};
#define boxvar_AbsynUtil_getIteratorIndexedCrefs MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_getIteratorIndexedCrefs)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_AbsynUtil_iteratorIndexedCrefsEqual(threadData_t *threadData, modelica_metatype _inCref1, modelica_metatype _inCref2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_iteratorIndexedCrefsEqual(threadData_t *threadData, modelica_metatype _inCref1, modelica_metatype _inCref2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_iteratorIndexedCrefsEqual,2,0) {(void*) boxptr_AbsynUtil_iteratorIndexedCrefsEqual,0}};
#define boxvar_AbsynUtil_iteratorIndexedCrefsEqual MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_iteratorIndexedCrefsEqual)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_findIteratorIndexedCrefs__traverser(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inCrefs, modelica_string _inIterator, modelica_metatype *out_outCrefs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_findIteratorIndexedCrefs__traverser,2,0) {(void*) boxptr_AbsynUtil_findIteratorIndexedCrefs__traverser,0}};
#define boxvar_AbsynUtil_findIteratorIndexedCrefs__traverser MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_findIteratorIndexedCrefs__traverser)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_stripCommentExpressionsHelper(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype __omcQ_24in_5Fextra, modelica_metatype *out_extra);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_stripCommentExpressionsHelper,2,0) {(void*) boxptr_AbsynUtil_stripCommentExpressionsHelper,0}};
#define boxvar_AbsynUtil_stripCommentExpressionsHelper MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_stripCommentExpressionsHelper)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_getCrefFromNarg(threadData_t *threadData, modelica_metatype _inNamedArg, modelica_boolean _includeSubs, modelica_boolean _includeFunctions);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_getCrefFromNarg(threadData_t *threadData, modelica_metatype _inNamedArg, modelica_metatype _includeSubs, modelica_metatype _includeFunctions);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_getCrefFromNarg,2,0) {(void*) boxptr_AbsynUtil_getCrefFromNarg,0}};
#define boxvar_AbsynUtil_getCrefFromNarg MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_getCrefFromNarg)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_pathToStringListWork(threadData_t *threadData, modelica_metatype _path, modelica_metatype _acc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_pathToStringListWork,2,0) {(void*) boxptr_AbsynUtil_pathToStringListWork,0}};
#define boxvar_AbsynUtil_pathToStringListWork MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_pathToStringListWork)
PROTECTED_FUNCTION_STATIC modelica_string omc_AbsynUtil_pathStringWork(threadData_t *threadData, modelica_metatype _inPath, modelica_integer _len, modelica_string _delimiter, modelica_integer _dlen, modelica_boolean _reverse);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_pathStringWork(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _len, modelica_metatype _delimiter, modelica_metatype _dlen, modelica_metatype _reverse);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_pathStringWork,2,0) {(void*) boxptr_AbsynUtil_pathStringWork,0}};
#define boxvar_AbsynUtil_pathStringWork MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_pathStringWork)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseAlgorithmBidir(threadData_t *threadData, modelica_metatype __omcQ_24in_5Falg, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseAlgorithmBidir,2,0) {(void*) boxptr_AbsynUtil_traverseAlgorithmBidir,0}};
#define boxvar_AbsynUtil_traverseAlgorithmBidir MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseAlgorithmBidir)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseAlgorithmBidirElse(threadData_t *threadData, modelica_metatype _inElse, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype _inArg, modelica_metatype *out_arg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseAlgorithmBidirElse,2,0) {(void*) boxptr_AbsynUtil_traverseAlgorithmBidirElse,0}};
#define boxvar_AbsynUtil_traverseAlgorithmBidirElse MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseAlgorithmBidirElse)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseEquationBidirElse(threadData_t *threadData, modelica_metatype _inElse, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype _inArg, modelica_metatype *out_arg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseEquationBidirElse,2,0) {(void*) boxptr_AbsynUtil_traverseEquationBidirElse,0}};
#define boxvar_AbsynUtil_traverseEquationBidirElse MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseEquationBidirElse)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseEquationItemBidir(threadData_t *threadData, modelica_metatype __omcQ_24in_5FequationItem, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseEquationItemBidir,2,0) {(void*) boxptr_AbsynUtil_traverseEquationItemBidir,0}};
#define boxvar_AbsynUtil_traverseEquationItemBidir MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseEquationItemBidir)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseAlgorithmItemBidir(threadData_t *threadData, modelica_metatype __omcQ_24in_5FalgorithmItem, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseAlgorithmItemBidir,2,0) {(void*) boxptr_AbsynUtil_traverseAlgorithmItemBidir,0}};
#define boxvar_AbsynUtil_traverseAlgorithmItemBidir MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseAlgorithmItemBidir)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseAlgorithmItemListBidir(threadData_t *threadData, modelica_metatype _inAlgs, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype _inArg, modelica_metatype *out_outArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseAlgorithmItemListBidir,2,0) {(void*) boxptr_AbsynUtil_traverseAlgorithmItemListBidir,0}};
#define boxvar_AbsynUtil_traverseAlgorithmItemListBidir MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseAlgorithmItemListBidir)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseEquationItemListBidir(threadData_t *threadData, modelica_metatype _inEquationItems, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype _inArg, modelica_metatype *out_outArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseEquationItemListBidir,2,0) {(void*) boxptr_AbsynUtil_traverseEquationItemListBidir,0}};
#define boxvar_AbsynUtil_traverseEquationItemListBidir MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseEquationItemListBidir)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseClassPartBidir(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcp, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseClassPartBidir,2,0) {(void*) boxptr_AbsynUtil_traverseClassPartBidir,0}};
#define boxvar_AbsynUtil_traverseClassPartBidir MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseClassPartBidir)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseExpBidirSubExps(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseExpBidirSubExps,2,0) {(void*) boxptr_AbsynUtil_traverseExpBidirSubExps,0}};
#define boxvar_AbsynUtil_traverseExpBidirSubExps MMC_REFSTRUCTLIT(boxvar_lit_AbsynUtil_traverseExpBidirSubExps)
DLLExport
modelica_metatype omc_AbsynUtil_mapSubscriptExp(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsub, modelica_fnptr _func)
{
modelica_metatype _sub = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sub = __omcQ_24in_5Fsub;
{
modelica_metatype tmp3_1;
tmp3_1 = _sub;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_sub), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[2] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sub), 2)))) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sub), 2))));
_sub = tmpMeta5;
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
return _sub;
}
DLLExport
modelica_metatype omc_AbsynUtil_mapCrefExps(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcref, modelica_fnptr _func)
{
modelica_metatype _cref = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cref = __omcQ_24in_5Fcref;
{
modelica_metatype tmp3_1;
tmp3_1 = _cref;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 5: {
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp6;
modelica_metatype tmpMeta7;
modelica_metatype __omcQ_24tmpVar0;
modelica_integer tmp8;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 3)));
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta7;
tmp6 = &__omcQ_24tmpVar1;
while(1) {
tmp8 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp8--;
}
if (tmp8 == 0) {
__omcQ_24tmpVar0 = omc_AbsynUtil_mapSubscriptExp(threadData, _s, ((modelica_fnptr) _func));
*tmp6 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp6 = &MMC_CDR(*tmp6);
} else if (tmp8 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp6 = mmc_mk_nil();
tmpMeta5 = __omcQ_24tmpVar1;
}
tmpMeta4 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta4), MMC_UNTAGPTR(_cref), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta4))[3] = tmpMeta5;
_cref = tmpMeta4;
goto tmp2_done;
}
case 4: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
{
modelica_metatype __omcQ_24tmpVar3;
modelica_metatype* tmp11;
modelica_metatype tmpMeta12;
modelica_metatype __omcQ_24tmpVar2;
modelica_integer tmp13;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 3)));
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta12;
tmp11 = &__omcQ_24tmpVar3;
while(1) {
tmp13 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp13--;
}
if (tmp13 == 0) {
__omcQ_24tmpVar2 = omc_AbsynUtil_mapSubscriptExp(threadData, _s, ((modelica_fnptr) _func));
*tmp11 = mmc_mk_cons(__omcQ_24tmpVar2,0);
tmp11 = &MMC_CDR(*tmp11);
} else if (tmp13 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp11 = mmc_mk_nil();
tmpMeta10 = __omcQ_24tmpVar3;
}
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_cref), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[3] = tmpMeta10;
_cref = tmpMeta9;
goto tmp2_done;
}
case 3: {
modelica_metatype tmpMeta14;
tmpMeta14 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta14), MMC_UNTAGPTR(_cref), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta14))[2] = omc_AbsynUtil_mapCrefExps(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2))), ((modelica_fnptr) _func));
_cref = tmpMeta14;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
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
return _cref;
}
DLLExport
modelica_metatype omc_AbsynUtil_createChoiceArray(threadData_t *threadData, modelica_metatype _inChoices)
{
modelica_metatype _outChoices = NULL;
modelica_metatype _choices = NULL;
modelica_metatype _choice = NULL;
modelica_metatype _acc_choice = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _acc = NULL;
modelica_metatype tmpMeta2;
modelica_metatype _args = NULL;
modelica_metatype _c = NULL;
modelica_metatype _el = NULL;
modelica_metatype _info1 = NULL;
modelica_metatype _info2 = NULL;
modelica_metatype _cmt1 = NULL;
modelica_metatype _cmt2 = NULL;
modelica_boolean _fp1;
modelica_boolean _fp2;
modelica_metatype _ep1 = NULL;
modelica_metatype _ep2 = NULL;
modelica_metatype _choiceArray = NULL;
modelica_metatype tmpMeta3;
modelica_string _s = NULL;
modelica_metatype _e = NULL;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outChoices = _inChoices;
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_acc_choice = tmpMeta1;
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
_acc = tmpMeta2;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
_choiceArray = tmpMeta3;
{
modelica_metatype tmp7_1;
tmp7_1 = _inChoices;
{
volatile mmc_switch_type tmp7;
int tmp8;
tmp7 = 0;
for (; tmp7 < 2; tmp7++) {
switch (MMC_SWITCH_CAST(tmp7)) {
case 0: {
modelica_metatype tmpMeta9;
modelica_integer tmp10;
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
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
modelica_metatype tmpMeta62;
modelica_metatype tmpMeta63;
modelica_metatype tmpMeta64;
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
modelica_metatype tmpMeta67;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,0,6) == 0) goto tmp6_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
tmp10 = mmc_unbox_integer(tmpMeta9);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 3));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,1,1) == 0) goto tmp6_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
if (7 != MMC_STRLEN(tmpMeta13) || strcmp(MMC_STRINGDATA(_OMC_LIT2), MMC_STRINGDATA(tmpMeta13)) != 0) goto tmp6_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 5));
if (optionNone(tmpMeta14)) goto tmp6_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 1));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,0,0) == 0) goto tmp6_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 6));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 7));
_fp1 = tmp10;
_ep1 = tmpMeta11;
_choice = tmpMeta16;
_cmt1 = tmpMeta18;
_info1 = tmpMeta19;
{
modelica_metatype _m;
for (tmpMeta20 = _choice; !listEmpty(tmpMeta20); tmpMeta20=MMC_CDR(tmpMeta20))
{
_m = MMC_CAR(tmpMeta20);
{
modelica_metatype tmp24_1;
tmp24_1 = _m;
{
volatile mmc_switch_type tmp24;
int tmp25;
tmp24 = 0;
for (; tmp24 < 3; tmp24++) {
switch (MMC_SWITCH_CAST(tmp24)) {
case 0: {
modelica_metatype tmpMeta26;
modelica_integer tmp27;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp24_1,0,6) == 0) goto tmp23_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp24_1), 2));
tmp27 = mmc_unbox_integer(tmpMeta26);
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp24_1), 3));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp24_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta29,1,1) == 0) goto tmp23_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta29), 2));
if (6 != MMC_STRLEN(tmpMeta30) || strcmp(MMC_STRINGDATA(_OMC_LIT0), MMC_STRINGDATA(tmpMeta30)) != 0) goto tmp23_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp24_1), 5));
if (optionNone(tmpMeta31)) goto tmp23_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta31), 1));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 2));
if (listEmpty(tmpMeta33)) goto tmp23_end;
tmpMeta34 = MMC_CAR(tmpMeta33);
tmpMeta35 = MMC_CDR(tmpMeta33);
if (!listEmpty(tmpMeta35)) goto tmp23_end;
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta36,0,0) == 0) goto tmp23_end;
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp24_1), 6));
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp24_1), 7));
_fp2 = tmp27;
_ep2 = tmpMeta28;
_el = tmpMeta34;
_cmt2 = tmpMeta37;
_info2 = tmpMeta38;
_s = omc_Dump_unparseElementArgStr(threadData, _el);
tmpMeta39 = mmc_mk_cons(_s, _choiceArray);
tmpMeta[0+0] = tmpMeta39;
tmpMeta[0+1] = _acc;
goto tmp23_done;
}
case 1: {
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
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
if (mmc__uniontype__metarecord__typedef__equal(tmp24_1,0,6) == 0) goto tmp23_end;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp24_1), 2));
tmp41 = mmc_unbox_integer(tmpMeta40);
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp24_1), 3));
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp24_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta43,1,1) == 0) goto tmp23_end;
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta43), 2));
if (6 != MMC_STRLEN(tmpMeta44) || strcmp(MMC_STRINGDATA(_OMC_LIT0), MMC_STRINGDATA(tmpMeta44)) != 0) goto tmp23_end;
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp24_1), 5));
if (optionNone(tmpMeta45)) goto tmp23_end;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 1));
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta46), 2));
if (!listEmpty(tmpMeta47)) goto tmp23_end;
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta46), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta48,1,2) == 0) goto tmp23_end;
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta48), 2));
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp24_1), 6));
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp24_1), 7));
_fp2 = tmp41;
_ep2 = tmpMeta42;
_e = tmpMeta49;
_cmt2 = tmpMeta50;
_info2 = tmpMeta51;
_s = omc_Dump_printExpStr(threadData, _e);
tmpMeta52 = mmc_mk_cons(_s, _choiceArray);
tmpMeta[0+0] = tmpMeta52;
tmpMeta[0+1] = _acc;
goto tmp23_done;
}
case 2: {
modelica_metatype tmpMeta53;
tmpMeta53 = mmc_mk_cons(_m, _acc);
tmpMeta[0+0] = _choiceArray;
tmpMeta[0+1] = tmpMeta53;
goto tmp23_done;
}
}
goto tmp23_end;
tmp23_end: ;
}
goto goto_22;
goto_22:;
goto goto_5;
goto tmp23_done;
tmp23_done:;
}
}
_choiceArray = tmpMeta[0+0];
_acc = tmpMeta[0+1];
}
}
if((!listEmpty(_choiceArray)))
{
{
modelica_metatype __omcQ_24tmpVar5;
modelica_metatype* tmp56;
modelica_metatype tmpMeta57;
modelica_metatype tmpMeta58;
modelica_metatype __omcQ_24tmpVar4;
modelica_integer tmp59;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = listReverse(_choiceArray);
tmpMeta57 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar5 = tmpMeta57;
tmp56 = &__omcQ_24tmpVar5;
while(1) {
tmp59 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp59--;
}
if (tmp59 == 0) {
tmpMeta58 = mmc_mk_box2(6, &Absyn_Exp_STRING__desc, _s);
__omcQ_24tmpVar4 = tmpMeta58;
*tmp56 = mmc_mk_cons(__omcQ_24tmpVar4,0);
tmp56 = &MMC_CDR(*tmp56);
} else if (tmp59 == 1) {
break;
} else {
goto goto_5;
}
}
*tmp56 = mmc_mk_nil();
tmpMeta55 = __omcQ_24tmpVar5;
}
tmpMeta60 = mmc_mk_box2(16, &Absyn_Exp_ARRAY__desc, tmpMeta55);
_e = tmpMeta60;
tmpMeta61 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta62 = mmc_mk_box3(4, &Absyn_EqMod_EQMOD__desc, _e, _info2);
tmpMeta63 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, tmpMeta61, tmpMeta62);
tmpMeta64 = mmc_mk_box7(3, &Absyn_ElementArg_MODIFICATION__desc, mmc_mk_boolean(_fp2), _ep2, _OMC_LIT1, mmc_mk_some(tmpMeta63), _cmt2, _info2);
_c = tmpMeta64;
tmpMeta65 = mmc_mk_cons(_c, _acc);
_args = listReverse(tmpMeta65);
}
else
{
_args = listReverse(_acc);
}
tmpMeta66 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _args, _OMC_LIT4);
tmpMeta67 = mmc_mk_box7(3, &Absyn_ElementArg_MODIFICATION__desc, mmc_mk_boolean(_fp1), _ep1, _OMC_LIT3, mmc_mk_some(tmpMeta66), _cmt1, _info1);
tmpMeta4 = tmpMeta67;
goto tmp6_done;
}
case 1: {
tmpMeta4 = _inChoices;
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
_outChoices = tmpMeta4;
_return: OMC_LABEL_UNUSED
return _outChoices;
}
DLLExport
modelica_metatype omc_AbsynUtil_mapAnnotationBindingInEqMod(threadData_t *threadData, modelica_metatype __omcQ_24in_5FeqMod, modelica_fnptr _func)
{
modelica_metatype _eqMod = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_eqMod = __omcQ_24in_5FeqMod;
{
modelica_metatype tmp3_1;
tmp3_1 = _eqMod;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,2) == 0) goto tmp2_end;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_eqMod), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[2] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eqMod), 2)))) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eqMod), 2))));
_eqMod = tmpMeta5;
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
return _eqMod;
}
static modelica_metatype closure0_AbsynUtil_mapAnnotationBindingInArg(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_arg, modelica_metatype tmp8)
{
modelica_metatype path = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_fnptr func = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_AbsynUtil_mapAnnotationBindingInArg(thData, $in_arg, path, func, tmp8);
}
DLLExport
modelica_metatype omc_AbsynUtil_mapAnnotationBindingInArg(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farg, modelica_metatype _path, modelica_fnptr _func, modelica_boolean *out_found)
{
modelica_metatype _arg = NULL;
modelica_boolean _found;
modelica_metatype _mod = NULL;
modelica_metatype _mod_args = NULL;
modelica_metatype _mod_eq = NULL;
modelica_metatype _rest_path = NULL;
modelica_integer _arg_path_len;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_arg = __omcQ_24in_5Farg;
_found = 0;
{
modelica_metatype tmp3_1;
tmp3_1 = _arg;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,6) == 0) goto tmp2_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
if (optionNone(tmpMeta5)) goto tmp2_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 1));
_mod = tmpMeta6;
if(omc_AbsynUtil_pathPrefixOf(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 4))), _path))
{
_arg_path_len = omc_AbsynUtil_pathPartCount(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 4))), ((modelica_integer) 0));
if((_arg_path_len == omc_AbsynUtil_pathPartCount(threadData, _path, ((modelica_integer) 0))))
{
_mod_eq = omc_AbsynUtil_mapAnnotationBindingInEqMod(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_mod), 3))), ((modelica_fnptr) _func));
tmpMeta7 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta7), MMC_UNTAGPTR(_mod), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta7))[3] = _mod_eq;
_mod = tmpMeta7;
_found = 1;
}
else
{
_rest_path = omc_Util_foldcallN(threadData, _arg_path_len, boxvar_AbsynUtil_pathRest, _path);
tmpMeta9 = mmc_mk_box2(0, _rest_path, ((modelica_fnptr) _func));
_mod_args = omc_List_findMap(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_mod), 2))), (modelica_fnptr) mmc_mk_box2(0,closure0_AbsynUtil_mapAnnotationBindingInArg,tmpMeta9) ,&_found);
tmpMeta10 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta10), MMC_UNTAGPTR(_mod), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta10))[2] = _mod_args;
_mod = tmpMeta10;
}
if(_found)
{
tmpMeta11 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta11), MMC_UNTAGPTR(_arg), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta11))[5] = mmc_mk_some(_mod);
_arg = tmpMeta11;
}
}
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
if (out_found) { *out_found = _found; }
return _arg;
}
modelica_metatype boxptr_AbsynUtil_mapAnnotationBindingInArg(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farg, modelica_metatype _path, modelica_fnptr _func, modelica_metatype *out_found)
{
modelica_boolean _found;
modelica_metatype _arg = NULL;
_arg = omc_AbsynUtil_mapAnnotationBindingInArg(threadData, __omcQ_24in_5Farg, _path, _func, &_found);
if (out_found) { *out_found = mmc_mk_icon(_found); }
return _arg;
}
static modelica_metatype closure1_AbsynUtil_mapAnnotationBindingInArg(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_arg, modelica_metatype tmp1)
{
modelica_metatype path = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_fnptr func = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_AbsynUtil_mapAnnotationBindingInArg(thData, $in_arg, path, func, tmp1);
}
DLLExport
modelica_metatype omc_AbsynUtil_mapAnnotationBinding(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fann, modelica_metatype _path, modelica_fnptr _func, modelica_boolean *out_found)
{
modelica_metatype _ann = NULL;
modelica_boolean _found;
modelica_metatype _args = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ann = __omcQ_24in_5Fann;
_args = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ann), 2)));
tmpMeta2 = mmc_mk_box2(0, _path, ((modelica_fnptr) _func));
_args = omc_List_findMap(threadData, _args, (modelica_fnptr) mmc_mk_box2(0,closure1_AbsynUtil_mapAnnotationBindingInArg,tmpMeta2) ,&_found);
tmpMeta3 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta3), MMC_UNTAGPTR(_ann), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta3))[2] = _args;
_ann = tmpMeta3;
_return: OMC_LABEL_UNUSED
if (out_found) { *out_found = _found; }
return _ann;
}
modelica_metatype boxptr_AbsynUtil_mapAnnotationBinding(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fann, modelica_metatype _path, modelica_fnptr _func, modelica_metatype *out_found)
{
modelica_boolean _found;
modelica_metatype _ann = NULL;
_ann = omc_AbsynUtil_mapAnnotationBinding(threadData, __omcQ_24in_5Fann, _path, _func, &_found);
if (out_found) { *out_found = mmc_mk_icon(_found); }
return _ann;
}
DLLExport
modelica_metatype omc_AbsynUtil_setCommentAnnotation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcomment, modelica_metatype _ann)
{
modelica_metatype _comment = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_comment = __omcQ_24in_5Fcomment;
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _comment;
tmp4_2 = _ann;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
if (!optionNone(tmp4_2)) goto tmp3_end;
tmpMeta1 = _comment;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (!optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = mmc_mk_box3(3, &Absyn_Comment_COMMENT__desc, _ann, mmc_mk_none());
tmpMeta1 = mmc_mk_some(tmpMeta6);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
_cmt = tmpMeta8;
tmpMeta9 = mmc_mk_box3(3, &Absyn_Comment_COMMENT__desc, _ann, _cmt);
tmpMeta1 = mmc_mk_some(tmpMeta9);
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
_comment = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _comment;
}
DLLExport
modelica_metatype omc_AbsynUtil_setClassDefAnnotation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcdef, modelica_metatype _ann)
{
modelica_metatype _cdef = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cdef = __omcQ_24in_5Fcdef;
{
modelica_metatype tmp3_1;
tmp3_1 = _cdef;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if((!listEmpty((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5))))))
{
tmpMeta4 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta4), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta4))[5] = listRest((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5))));
_cdef = tmpMeta4;
}
if(isSome(_ann))
{
tmpMeta6 = mmc_mk_cons(omc_Util_getOption(threadData, _ann), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5))));
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[5] = tmpMeta6;
_cdef = tmpMeta5;
}
goto tmp2_done;
}
case 4: {
modelica_metatype tmpMeta7;
tmpMeta7 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta7), MMC_UNTAGPTR(_cdef), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta7))[5] = omc_AbsynUtil_setCommentAnnotation(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5))), _ann);
_cdef = tmpMeta7;
goto tmp2_done;
}
case 5: {
modelica_metatype tmpMeta8;
tmpMeta8 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta8), MMC_UNTAGPTR(_cdef), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta8))[3] = omc_AbsynUtil_setCommentAnnotation(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 3))), _ann);
_cdef = tmpMeta8;
goto tmp2_done;
}
case 6: {
modelica_metatype tmpMeta9;
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_cdef), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[3] = omc_AbsynUtil_setCommentAnnotation(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 3))), _ann);
_cdef = tmpMeta9;
goto tmp2_done;
}
case 7: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if((!listEmpty((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 6))))))
{
tmpMeta10 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta10), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta10))[6] = listRest((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 6))));
_cdef = tmpMeta10;
}
if(isSome(_ann))
{
tmpMeta12 = mmc_mk_cons(omc_Util_getOption(threadData, _ann), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 6))));
tmpMeta11 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta11), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta11))[6] = tmpMeta12;
_cdef = tmpMeta11;
}
goto tmp2_done;
}
case 8: {
modelica_metatype tmpMeta13;
tmpMeta13 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta13), MMC_UNTAGPTR(_cdef), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta13))[4] = omc_AbsynUtil_setCommentAnnotation(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 4))), _ann);
_cdef = tmpMeta13;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
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
return _cdef;
}
DLLExport
modelica_metatype omc_AbsynUtil_setClassAnnotation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcls, modelica_metatype _ann)
{
modelica_metatype _cls = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cls = __omcQ_24in_5Fcls;
tmpMeta1 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta1), MMC_UNTAGPTR(_cls), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta1))[7] = omc_AbsynUtil_setClassDefAnnotation(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cls), 7))), _ann);
_cls = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _cls;
}
DLLExport
modelica_metatype omc_AbsynUtil_getClassDefAnnotation(threadData_t *threadData, modelica_metatype _cdef)
{
modelica_metatype _ann = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cdef;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 7; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
tmpMeta1 = (listEmpty((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5))))?mmc_mk_none():mmc_mk_some(listHead((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5))))));
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (optionNone(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_ann = tmpMeta8;
tmpMeta1 = _ann;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (optionNone(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 1));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_ann = tmpMeta11;
tmpMeta1 = _ann;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (optionNone(tmpMeta12)) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 1));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
_ann = tmpMeta14;
tmpMeta1 = _ann;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,5) == 0) goto tmp3_end;
tmpMeta1 = (listEmpty((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 6))))?mmc_mk_none():mmc_mk_some(listHead((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 6))))));
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,3) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (optionNone(tmpMeta15)) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 1));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
_ann = tmpMeta17;
tmpMeta1 = _ann;
goto tmp3_done;
}
case 6: {
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
_ann = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _ann;
}
DLLExport
modelica_metatype omc_AbsynUtil_getClassAnnotation(threadData_t *threadData, modelica_metatype _cls)
{
modelica_metatype _ann = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ann = omc_AbsynUtil_getClassDefAnnotation(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cls), 7))));
_return: OMC_LABEL_UNUSED
return _ann;
}
DLLExport
modelica_boolean omc_AbsynUtil_pathContains(threadData_t *threadData, modelica_metatype _path, modelica_string _name)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _path;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
tmp1 = (stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2))), _name));
goto tmp3_done;
}
case 3: {
tmp1 = ((stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2))), _name)) || omc_AbsynUtil_pathContains(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 3))), _name));
goto tmp3_done;
}
case 5: {
_path = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2)));
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_AbsynUtil_pathContains(threadData_t *threadData, modelica_metatype _path, modelica_metatype _name)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_AbsynUtil_pathContains(threadData, _path, _name);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_metatype omc_AbsynUtil_pathReplaceFirst(threadData_t *threadData, modelica_metatype _path, modelica_metatype _prefix)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _path;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
tmpMeta1 = _prefix;
goto tmp3_done;
}
case 3: {
tmpMeta1 = omc_AbsynUtil_joinPaths(threadData, _prefix, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 3))));
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta5;
tmpMeta5 = mmc_mk_box2(5, &Absyn_Path_FULLYQUALIFIED__desc, omc_AbsynUtil_pathReplaceFirst(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2))), _prefix));
tmpMeta1 = tmpMeta5;
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
modelica_metatype omc_AbsynUtil_setClassCommentsAfterEnd(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcl, modelica_metatype _comments)
{
modelica_metatype _cl = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cl = __omcQ_24in_5Fcl;
tmpMeta1 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta1), MMC_UNTAGPTR(_cl), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta1))[9] = _comments;
_cl = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _cl;
}
DLLExport
modelica_metatype omc_AbsynUtil_makeCall(threadData_t *threadData, modelica_metatype _name, modelica_metatype _posArgs, modelica_metatype _namedArgs)
{
modelica_metatype _callExp = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box3(3, &Absyn_FunctionArgs_FUNCTIONARGS__desc, _posArgs, _namedArgs);
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta3 = mmc_mk_box4(14, &Absyn_Exp_CALL__desc, _name, tmpMeta1, tmpMeta2);
_callExp = tmpMeta3;
_return: OMC_LABEL_UNUSED
return _callExp;
}
DLLExport
modelica_boolean omc_AbsynUtil_crefIsWild(threadData_t *threadData, modelica_metatype _cref)
{
modelica_boolean _wild;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cref;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 6: {
tmp1 = 1;
goto tmp3_done;
}
case 7: {
tmp1 = 1;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
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
_wild = tmp1;
_return: OMC_LABEL_UNUSED
return _wild;
}
modelica_metatype boxptr_AbsynUtil_crefIsWild(threadData_t *threadData, modelica_metatype _cref)
{
modelica_boolean _wild;
modelica_metatype out_wild;
_wild = omc_AbsynUtil_crefIsWild(threadData, _cref);
out_wild = mmc_mk_icon(_wild);
return out_wild;
}
DLLExport
modelica_boolean omc_AbsynUtil_isNotPartial(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _outBoolean;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outBoolean = (!omc_AbsynUtil_isPartial(threadData, _inClass));
_return: OMC_LABEL_UNUSED
return _outBoolean;
}
modelica_metatype boxptr_AbsynUtil_isNotPartial(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_AbsynUtil_isNotPartial(threadData, _inClass);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_boolean omc_AbsynUtil_isPartial(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _outBoolean;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inClass;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp3 = mmc_unbox_integer(tmpMeta2);
_outBoolean = tmp3;
_return: OMC_LABEL_UNUSED
return _outBoolean;
}
modelica_metatype boxptr_AbsynUtil_isPartial(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_AbsynUtil_isPartial(threadData, _inClass);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_boolean omc_AbsynUtil_isClassOrComponentElementSpec(threadData_t *threadData, modelica_metatype _inElementSpec)
{
modelica_boolean _yes;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_yes = 0;
{
modelica_metatype tmp4_1;
tmp4_1 = _inElementSpec;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmpMeta7);
tmpMeta9 = MMC_CDR(tmpMeta7);
if (!listEmpty(tmpMeta9)) goto tmp3_end;
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
_yes = tmp1;
_return: OMC_LABEL_UNUSED
return _yes;
}
modelica_metatype boxptr_AbsynUtil_isClassOrComponentElementSpec(threadData_t *threadData, modelica_metatype _inElementSpec)
{
modelica_boolean _yes;
modelica_metatype out_yes;
_yes = omc_AbsynUtil_isClassOrComponentElementSpec(threadData, _inElementSpec);
out_yes = mmc_mk_icon(_yes);
return out_yes;
}
DLLExport
modelica_metatype omc_AbsynUtil_elementSpec(threadData_t *threadData, modelica_metatype _el)
{
modelica_metatype _elSpec = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _el;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,0,6) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 5));
_elSpec = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _elSpec;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseElementItem(threadData_t *threadData, modelica_metatype _inItem, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_boolean *out_outContinue)
{
modelica_metatype _outItem = NULL;
modelica_metatype _outArg = NULL;
modelica_boolean _outContinue;
modelica_boolean tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inItem;
{
modelica_metatype _elem = NULL;
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
modelica_boolean tmp11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta9 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inItem), 2))), _inArg, &tmpMeta6, &tmpMeta7) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inItem), 2))), _inArg, &tmpMeta6, &tmpMeta7);
_elem = tmpMeta9;
tmp8 = mmc_unbox_integer(tmpMeta7);
_outArg = tmpMeta6;
_outContinue = tmp8;
tmp11 = (modelica_boolean)referenceEq(_elem, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inItem), 2))));
if(tmp11)
{
tmpMeta12 = _inItem;
}
else
{
tmpMeta10 = mmc_mk_box2(3, &Absyn_ElementItem_ELEMENTITEM__desc, _elem);
tmpMeta12 = tmpMeta10;
}
_outItem = tmpMeta12;
tmpMeta[0+0] = _outItem;
tmpMeta[0+1] = _outArg;
tmp1_c2 = _outContinue;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _inItem;
tmpMeta[0+1] = _inArg;
tmp1_c2 = 1;
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
_outItem = tmpMeta[0+0];
_outArg = tmpMeta[0+1];
_outContinue = tmp1_c2;
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
if (out_outContinue) { *out_outContinue = _outContinue; }
return _outItem;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseElementItem(threadData_t *threadData, modelica_metatype _inItem, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_metatype *out_outContinue)
{
modelica_boolean _outContinue;
modelica_metatype _outItem = NULL;
_outItem = omc_AbsynUtil_traverseElementItem(threadData, _inItem, _inFunc, _inArg, out_outArg, &_outContinue);
if (out_outContinue) { *out_outContinue = mmc_mk_icon(_outContinue); }
return _outItem;
}
static modelica_metatype closure2_AbsynUtil_traverseElementItem(threadData_t *thData, modelica_metatype closure, modelica_metatype inItem, modelica_metatype inArg, modelica_metatype tmp4, modelica_metatype tmp5)
{
modelica_fnptr inFunc = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_AbsynUtil_traverseElementItem(thData, inItem, inFunc, inArg, tmp4, tmp5);
}static modelica_metatype closure3_AbsynUtil_traverseElementItem(threadData_t *thData, modelica_metatype closure, modelica_metatype inItem, modelica_metatype inArg, modelica_metatype tmp8, modelica_metatype tmp9)
{
modelica_fnptr inFunc = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_AbsynUtil_traverseElementItem(thData, inItem, inFunc, inArg, tmp8, tmp9);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseClassPartElements(threadData_t *threadData, modelica_metatype _inClassPart, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_boolean *out_outContinue)
{
modelica_metatype _outClassPart = NULL;
modelica_metatype _outArg = NULL;
modelica_boolean _outContinue;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outClassPart = _inClassPart;
_outArg = _inArg;
_outContinue = 1;
{
modelica_metatype tmp3_1;
tmp3_1 = _outClassPart;
{
modelica_metatype _items = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = mmc_mk_box1(0, ((modelica_fnptr) _inFunc));
_items = omc_AbsynUtil_traverseListGeneric(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outClassPart), 2))), (modelica_fnptr) mmc_mk_box2(0,closure2_AbsynUtil_traverseElementItem,tmpMeta6), _inArg ,&_outArg ,&_outContinue);
tmpMeta7 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta7), MMC_UNTAGPTR(_outClassPart), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta7))[2] = _items;
_outClassPart = tmpMeta7;
goto tmp2_done;
}
case 4: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
tmpMeta10 = mmc_mk_box1(0, ((modelica_fnptr) _inFunc));
_items = omc_AbsynUtil_traverseListGeneric(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outClassPart), 2))), (modelica_fnptr) mmc_mk_box2(0,closure3_AbsynUtil_traverseElementItem,tmpMeta10), _inArg ,&_outArg ,&_outContinue);
tmpMeta11 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta11), MMC_UNTAGPTR(_outClassPart), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta11))[2] = _items;
_outClassPart = tmpMeta11;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
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
if (out_outArg) { *out_outArg = _outArg; }
if (out_outContinue) { *out_outContinue = _outContinue; }
return _outClassPart;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseClassPartElements(threadData_t *threadData, modelica_metatype _inClassPart, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_metatype *out_outContinue)
{
modelica_boolean _outContinue;
modelica_metatype _outClassPart = NULL;
_outClassPart = omc_AbsynUtil_traverseClassPartElements(threadData, _inClassPart, _inFunc, _inArg, out_outArg, &_outContinue);
if (out_outContinue) { *out_outContinue = mmc_mk_icon(_outContinue); }
return _outClassPart;
}
static modelica_metatype closure4_AbsynUtil_traverseClassPartElements(threadData_t *thData, modelica_metatype closure, modelica_metatype inClassPart, modelica_metatype inArg, modelica_metatype tmp6, modelica_metatype tmp7)
{
modelica_fnptr inFunc = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_AbsynUtil_traverseClassPartElements(thData, inClassPart, inFunc, inArg, tmp6, tmp7);
}
DLLExport
modelica_metatype omc_AbsynUtil_traverseClassElements(threadData_t *threadData, modelica_metatype _inClass, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outClass = NULL;
modelica_metatype _outArg = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outClass = _inClass;
{
modelica_metatype tmp4_1;
tmp4_1 = _outClass;
{
modelica_metatype _body = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
tmpMeta8 = mmc_mk_box1(0, ((modelica_fnptr) _inFunc));
_body = omc_AbsynUtil_traverseClassDef(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outClass), 7))), (modelica_fnptr) mmc_mk_box2(0,closure4_AbsynUtil_traverseClassPartElements,tmpMeta8), _inArg ,&_outArg, NULL);
if((!referenceEq(_body, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outClass), 7))))))
{
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_outClass), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[7] = _body;
_outClass = tmpMeta9;
}
tmpMeta1 = _outClass;
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
_outClass = tmpMeta1;
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outClass;
}
DLLExport
modelica_boolean omc_AbsynUtil_isUniontype(threadData_t *threadData, modelica_metatype _cls)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cls), 6)));
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,19,0) == 0) goto tmp3_end;
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
modelica_metatype boxptr_AbsynUtil_isUniontype(threadData_t *threadData, modelica_metatype _cls)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_AbsynUtil_isUniontype(threadData, _cls);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_AbsynUtil_isNamedPathIdent(threadData_t *threadData, modelica_metatype _path, modelica_string _name)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _path;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmp1 = (stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2))), _name));
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
modelica_metatype boxptr_AbsynUtil_isNamedPathIdent(threadData_t *threadData, modelica_metatype _path, modelica_metatype _name)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_AbsynUtil_isNamedPathIdent(threadData, _path, _name);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_metatype omc_AbsynUtil_getDirection(threadData_t *threadData, modelica_metatype _elementItem)
{
modelica_metatype _oDirection = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _elementItem;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,6) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,3,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 6));
_oDirection = tmpMeta9;
tmpMeta1 = _oDirection;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _OMC_LIT5;
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
_oDirection = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _oDirection;
}
DLLExport
modelica_metatype omc_AbsynUtil_getComponentItemsFromElementItem(threadData_t *threadData, modelica_metatype _inElementItem)
{
modelica_metatype _componentItems = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = omc_AbsynUtil_getElementSpecificationFromElementItemOpt(threadData, _inElementItem);
{
modelica_metatype _elementSpec = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_elementSpec = tmpMeta6;
tmpMeta1 = omc_AbsynUtil_getComponentItemsFromElementSpec(threadData, _elementSpec);
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
_componentItems = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _componentItems;
}
DLLExport
modelica_metatype omc_AbsynUtil_getComponentItemsFromElementSpec(threadData_t *threadData, modelica_metatype _elemSpec)
{
modelica_metatype _componentItems = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _elemSpec;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,3) == 0) goto tmp3_end;
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elemSpec), 4)));
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
_componentItems = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _componentItems;
}
DLLExport
modelica_metatype omc_AbsynUtil_getElementSpecificationFromElementItemOpt(threadData_t *threadData, modelica_metatype _inElementItem)
{
modelica_metatype _outSpec = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElementItem;
{
modelica_metatype _spec = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,6) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
_spec = tmpMeta7;
tmpMeta1 = mmc_mk_some(_spec);
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
_outSpec = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outSpec;
}
DLLExport
modelica_metatype omc_AbsynUtil_getTypeSpecFromElementItemOpt(threadData_t *threadData, modelica_metatype _inElementItem)
{
modelica_metatype _outTypeSpec = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElementItem;
{
modelica_metatype _ty_spec = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,6) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,3,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
_ty_spec = tmpMeta8;
tmpMeta1 = mmc_mk_some(_ty_spec);
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
_outTypeSpec = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outTypeSpec;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseInnerClassElementspec(threadData_t *threadData, modelica_metatype _inElementSpec, modelica_metatype _inPath, modelica_fnptr _visitor, modelica_metatype _inArg, modelica_boolean _visitProtected)
{
modelica_metatype _outTpl = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inElementSpec;
tmp4_2 = _inPath;
tmp4_3 = _inArg;
{
modelica_metatype _cl = NULL;
modelica_metatype _pa = NULL;
modelica_metatype _args = NULL;
modelica_boolean _repl;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta5;
modelica_integer tmp6;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp6 = mmc_unbox_integer(tmpMeta5);
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_repl = tmp6;
_cl = tmpMeta7;
_pa = tmp4_2;
_args = tmp4_3;
tmpMeta8 = mmc_mk_box3(0, _cl, _pa, _args);
tmpMeta9 = mmc_mk_box3(0, _cl, _pa, _args);
tmpMeta10 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_visitor), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_visitor), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_visitor), 2))), tmpMeta9) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_visitor), 1)))) (threadData, tmpMeta8);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 1));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 3));
_cl = tmpMeta11;
_args = tmpMeta12;
tmpMeta13 = omc_AbsynUtil_traverseInnerClass(threadData, _cl, _pa, ((modelica_fnptr) _visitor), _args, _visitProtected);
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 1));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 3));
_cl = tmpMeta14;
_pa = tmpMeta15;
_args = tmpMeta16;
tmpMeta17 = mmc_mk_box3(3, &Absyn_ElementSpec_CLASSDEF__desc, mmc_mk_boolean(_repl), _cl);
tmpMeta18 = mmc_mk_box3(0, tmpMeta17, _pa, _args);
tmpMeta1 = tmpMeta18;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
_pa = tmp4_2;
_args = tmp4_3;
tmpMeta19 = mmc_mk_box3(0, _inElementSpec, _pa, _args);
tmpMeta1 = tmpMeta19;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,3) == 0) goto tmp3_end;
_pa = tmp4_2;
_args = tmp4_3;
tmpMeta20 = mmc_mk_box3(0, _inElementSpec, _pa, _args);
tmpMeta1 = tmpMeta20;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,3) == 0) goto tmp3_end;
_pa = tmp4_2;
_args = tmp4_3;
tmpMeta21 = mmc_mk_box3(0, _inElementSpec, _pa, _args);
tmpMeta1 = tmpMeta21;
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
_outTpl = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outTpl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseInnerClassElementspec(threadData_t *threadData, modelica_metatype _inElementSpec, modelica_metatype _inPath, modelica_fnptr _visitor, modelica_metatype _inArg, modelica_metatype _visitProtected)
{
modelica_integer tmp1;
modelica_metatype _outTpl = NULL;
tmp1 = mmc_unbox_integer(_visitProtected);
_outTpl = omc_AbsynUtil_traverseInnerClassElementspec(threadData, _inElementSpec, _inPath, _visitor, _inArg, tmp1);
return _outTpl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseInnerClassElements(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _inPath, modelica_fnptr _visitor, modelica_metatype _inArg, modelica_boolean _visitProtected)
{
modelica_metatype _outTpl = NULL;
modelica_metatype _elts = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _el = NULL;
modelica_metatype _arg = NULL;
modelica_metatype _spec = NULL;
modelica_metatype _cl = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_elts = tmpMeta1;
_arg = _inArg;
{
modelica_metatype _e;
for (tmpMeta2 = _inElements; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_e = MMC_CAR(tmpMeta2);
{
modelica_metatype tmp6_1;
tmp6_1 = _e;
{
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
for (; tmp6 < 4; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,1) == 0) goto tmp5_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,6) == 0) goto tmp5_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 5));
_el = tmpMeta8;
_spec = tmpMeta9;
tmpMeta10 = omc_AbsynUtil_traverseInnerClassElementspec(threadData, _spec, _inPath, ((modelica_fnptr) _visitor), _arg, _visitProtected);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 1));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 3));
_spec = tmpMeta11;
_arg = tmpMeta12;
tmpMeta13 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta13), MMC_UNTAGPTR(_el), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta13))[5] = _spec;
_el = tmpMeta13;
tmpMeta14 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta14), MMC_UNTAGPTR(_e), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta14))[2] = _el;
_e = tmpMeta14;
tmpMeta15 = mmc_mk_cons(_e, _elts);
tmpMeta3 = tmpMeta15;
goto tmp5_done;
}
case 1: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,1) == 0) goto tmp5_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,0,6) == 0) goto tmp5_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,0,2) == 0) goto tmp5_end;
_el = tmpMeta16;
_spec = tmpMeta17;
tmpMeta18 = omc_AbsynUtil_traverseInnerClass(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_spec), 3))), _inPath, ((modelica_fnptr) _visitor), _arg, _visitProtected);
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 1));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 3));
_cl = tmpMeta19;
_arg = tmpMeta20;
tmpMeta21 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta21), MMC_UNTAGPTR(_spec), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta21))[3] = _cl;
_spec = tmpMeta21;
tmpMeta22 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta22), MMC_UNTAGPTR(_el), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta22))[5] = _spec;
_el = tmpMeta22;
tmpMeta23 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta23), MMC_UNTAGPTR(_e), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta23))[2] = _el;
_e = tmpMeta23;
tmpMeta24 = mmc_mk_cons(_e, _elts);
tmpMeta3 = tmpMeta24;
goto tmp5_done;
}
case 2: {
modelica_metatype tmpMeta25;
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,1) == 0) goto tmp5_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta25,0,6) == 0) goto tmp5_end;
tmpMeta3 = _elts;
goto tmp5_done;
}
case 3: {
modelica_metatype tmpMeta26;
tmpMeta26 = mmc_mk_cons(_e, _elts);
tmpMeta3 = tmpMeta26;
goto tmp5_done;
}
}
goto tmp5_end;
tmp5_end: ;
}
goto goto_4;
goto_4:;
MMC_THROW_INTERNAL();
goto tmp5_done;
tmp5_done:;
}
}
_elts = tmpMeta3;
}
}
_elts = listReverseInPlace(_elts);
tmpMeta28 = mmc_mk_box3(0, _elts, _inPath, _arg);
_outTpl = tmpMeta28;
_return: OMC_LABEL_UNUSED
return _outTpl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseInnerClassElements(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _inPath, modelica_fnptr _visitor, modelica_metatype _inArg, modelica_metatype _visitProtected)
{
modelica_integer tmp1;
modelica_metatype _outTpl = NULL;
tmp1 = mmc_unbox_integer(_visitProtected);
_outTpl = omc_AbsynUtil_traverseInnerClassElements(threadData, _inElements, _inPath, _visitor, _inArg, tmp1);
return _outTpl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseInnerClassParts(threadData_t *threadData, modelica_metatype _inClassParts, modelica_metatype _inPath, modelica_fnptr _visitor, modelica_metatype _inArg, modelica_boolean _visitProtected)
{
modelica_metatype _outTpl = NULL;
modelica_metatype _parts = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _elts = NULL;
modelica_metatype _arg = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta19;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_parts = tmpMeta1;
_arg = _inArg;
{
modelica_metatype __omcQ_24tmpVar7;
modelica_metatype* tmp3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype __omcQ_24tmpVar6;
modelica_integer tmp18;
modelica_metatype _p_loopVar = 0;
modelica_metatype _p;
_p_loopVar = _inClassParts;
tmpMeta4 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar7 = tmpMeta4;
tmp3 = &__omcQ_24tmpVar7;
while(1) {
tmp18 = 1;
if (!listEmpty(_p_loopVar)) {
_p = MMC_CAR(_p_loopVar);
_p_loopVar = MMC_CDR(_p_loopVar);
tmp18--;
}
if (tmp18 == 0) {
{
modelica_metatype tmp8_1;
tmp8_1 = _p;
{
volatile mmc_switch_type tmp8;
int tmp9;
tmp8 = 0;
for (; tmp8 < 3; tmp8++) {
switch (MMC_SWITCH_CAST(tmp8)) {
case 0: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,0,1) == 0) goto tmp7_end;
tmpMeta10 = omc_AbsynUtil_traverseInnerClassElements(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2))), _inPath, ((modelica_fnptr) _visitor), _arg, _visitProtected);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 1));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 3));
_elts = tmpMeta11;
_arg = tmpMeta12;
tmpMeta13 = mmc_mk_box2(3, &Absyn_ClassPart_PUBLIC__desc, _elts);
tmpMeta5 = tmpMeta13;
goto tmp7_done;
}
case 1: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,1,1) == 0) goto tmp7_end;
if (!_visitProtected) goto tmp7_end;
tmpMeta14 = omc_AbsynUtil_traverseInnerClassElements(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2))), _inPath, ((modelica_fnptr) _visitor), _arg, 1);
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 1));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 3));
_elts = tmpMeta15;
_arg = tmpMeta16;
tmpMeta17 = mmc_mk_box2(4, &Absyn_ClassPart_PROTECTED__desc, _elts);
tmpMeta5 = tmpMeta17;
goto tmp7_done;
}
case 2: {
tmpMeta5 = _p;
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
}__omcQ_24tmpVar6 = tmpMeta5;
*tmp3 = mmc_mk_cons(__omcQ_24tmpVar6,0);
tmp3 = &MMC_CDR(*tmp3);
} else if (tmp18 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp3 = mmc_mk_nil();
tmpMeta2 = __omcQ_24tmpVar7;
}
_parts = tmpMeta2;
tmpMeta19 = mmc_mk_box3(0, _parts, _inPath, _arg);
_outTpl = tmpMeta19;
_return: OMC_LABEL_UNUSED
return _outTpl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseInnerClassParts(threadData_t *threadData, modelica_metatype _inClassParts, modelica_metatype _inPath, modelica_fnptr _visitor, modelica_metatype _inArg, modelica_metatype _visitProtected)
{
modelica_integer tmp1;
modelica_metatype _outTpl = NULL;
tmp1 = mmc_unbox_integer(_visitProtected);
_outTpl = omc_AbsynUtil_traverseInnerClassParts(threadData, _inClassParts, _inPath, _visitor, _inArg, tmp1);
return _outTpl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseInnerClass(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _path, modelica_fnptr _visitor, modelica_metatype _arg, modelica_boolean _visitProtected)
{
modelica_metatype _outTpl = NULL;
modelica_metatype _cls = NULL;
modelica_metatype _cdef = NULL;
modelica_metatype _pa = NULL;
modelica_metatype _opt_pa = NULL;
modelica_metatype _parts = NULL;
modelica_metatype _args = NULL;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cls = _inClass;
_cdef = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inClass), 7)));
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _cdef;
tmp4_2 = _path;
{
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
_pa = tmpMeta6;
tmp4 += 1;
tmpMeta7 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cls), 2))));
_pa = omc_AbsynUtil_joinPaths(threadData, _pa, tmpMeta7);
tmpMeta8 = omc_AbsynUtil_traverseInnerClassParts(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 4))), mmc_mk_some(_pa), ((modelica_fnptr) _visitor), _arg, _visitProtected);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 1));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
_parts = tmpMeta9;
_opt_pa = tmpMeta10;
_args = tmpMeta11;
tmpMeta12 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta12), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta12))[4] = _parts;
_cdef = tmpMeta12;
tmpMeta[0+0] = _cdef;
tmpMeta[0+1] = _opt_pa;
tmpMeta[0+2] = _args;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
if (!optionNone(tmp4_2)) goto tmp3_end;
tmpMeta13 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cls), 2))));
tmpMeta14 = omc_AbsynUtil_traverseInnerClassParts(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 4))), mmc_mk_some(tmpMeta13), ((modelica_fnptr) _visitor), _arg, _visitProtected);
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 1));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 3));
_parts = tmpMeta15;
_opt_pa = tmpMeta16;
_args = tmpMeta17;
tmpMeta18 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta18), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta18))[4] = _parts;
_cdef = tmpMeta18;
tmpMeta[0+0] = _cdef;
tmpMeta[0+1] = _opt_pa;
tmpMeta[0+2] = _args;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
_opt_pa = tmp4_2;
tmp4 += 3;
tmpMeta19 = omc_AbsynUtil_traverseInnerClassParts(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 4))), _opt_pa, ((modelica_fnptr) _visitor), _arg, _visitProtected);
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 1));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 2));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 3));
_parts = tmpMeta20;
_opt_pa = tmpMeta21;
_args = tmpMeta22;
tmpMeta23 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta23), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta23))[4] = _parts;
_cdef = tmpMeta23;
tmpMeta[0+0] = _cdef;
tmpMeta[0+1] = _opt_pa;
tmpMeta[0+2] = _args;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,5) == 0) goto tmp3_end;
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
_pa = tmpMeta24;
tmp4 += 1;
tmpMeta25 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cls), 2))));
_pa = omc_AbsynUtil_joinPaths(threadData, _pa, tmpMeta25);
tmpMeta26 = omc_AbsynUtil_traverseInnerClassParts(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5))), mmc_mk_some(_pa), ((modelica_fnptr) _visitor), _arg, _visitProtected);
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 1));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 2));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 3));
_parts = tmpMeta27;
_opt_pa = tmpMeta28;
_args = tmpMeta29;
tmpMeta30 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta30), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta30))[5] = _parts;
_cdef = tmpMeta30;
tmpMeta[0+0] = _cdef;
tmpMeta[0+1] = _opt_pa;
tmpMeta[0+2] = _args;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,5) == 0) goto tmp3_end;
if (!optionNone(tmp4_2)) goto tmp3_end;
tmpMeta31 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cls), 2))));
tmpMeta32 = omc_AbsynUtil_traverseInnerClassParts(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5))), mmc_mk_some(tmpMeta31), ((modelica_fnptr) _visitor), _arg, _visitProtected);
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 1));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 2));
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 3));
_parts = tmpMeta33;
_opt_pa = tmpMeta34;
_args = tmpMeta35;
tmpMeta36 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta36), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta36))[5] = _parts;
_cdef = tmpMeta36;
tmpMeta[0+0] = _cdef;
tmpMeta[0+1] = _opt_pa;
tmpMeta[0+2] = _args;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,5) == 0) goto tmp3_end;
_opt_pa = tmp4_2;
tmpMeta37 = omc_AbsynUtil_traverseInnerClassParts(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5))), _opt_pa, ((modelica_fnptr) _visitor), _arg, _visitProtected);
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 1));
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 2));
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 3));
_parts = tmpMeta38;
_opt_pa = tmpMeta39;
_args = tmpMeta40;
tmpMeta41 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta41), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta41))[5] = _parts;
_cdef = tmpMeta41;
tmpMeta[0+0] = _cdef;
tmpMeta[0+1] = _opt_pa;
tmpMeta[0+2] = _args;
goto tmp3_done;
}
case 6: {
tmpMeta[0+0] = _cdef;
tmpMeta[0+1] = _path;
tmpMeta[0+2] = _arg;
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
_cdef = tmpMeta[0+0];
_opt_pa = tmpMeta[0+1];
_args = tmpMeta[0+2];
tmpMeta42 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta42), MMC_UNTAGPTR(_cls), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta42))[7] = _cdef;
_cls = tmpMeta42;
tmpMeta43 = mmc_mk_box3(0, _cls, _opt_pa, _args);
_outTpl = tmpMeta43;
_return: OMC_LABEL_UNUSED
return _outTpl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseInnerClass(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _path, modelica_fnptr _visitor, modelica_metatype _arg, modelica_metatype _visitProtected)
{
modelica_integer tmp1;
modelica_metatype _outTpl = NULL;
tmp1 = mmc_unbox_integer(_visitProtected);
_outTpl = omc_AbsynUtil_traverseInnerClass(threadData, _inClass, _path, _visitor, _arg, tmp1);
return _outTpl;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_AbsynUtil_eltsHasLocalClass(threadData_t *threadData, modelica_metatype _inElts)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inElts;
{
modelica_metatype _elts = NULL;
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,6) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,0,2) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
_elts = tmpMeta11;
tmp1 = omc_AbsynUtil_eltsHasLocalClass(threadData, _elts);
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_eltsHasLocalClass(threadData_t *threadData, modelica_metatype _inElts)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_AbsynUtil_eltsHasLocalClass(threadData, _inElts);
out_res = mmc_mk_icon(_res);
return out_res;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_AbsynUtil_partsHasLocalClass(threadData_t *threadData, modelica_metatype _inParts)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inParts;
{
modelica_metatype _elts = NULL;
modelica_metatype _parts = NULL;
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
modelica_boolean tmp9;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_elts = tmpMeta8;
tmp4 += 1;
tmp9 = omc_AbsynUtil_eltsHasLocalClass(threadData, _elts);
if (1 != tmp9) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_boolean tmp13;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,1,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_elts = tmpMeta12;
tmp13 = omc_AbsynUtil_eltsHasLocalClass(threadData, _elts);
if (1 != tmp13) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta14 = MMC_CAR(tmp4_1);
tmpMeta15 = MMC_CDR(tmp4_1);
_parts = tmpMeta15;
tmp1 = omc_AbsynUtil_partsHasLocalClass(threadData, _parts);
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_partsHasLocalClass(threadData_t *threadData, modelica_metatype _inParts)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_AbsynUtil_partsHasLocalClass(threadData, _inParts);
out_res = mmc_mk_icon(_res);
return out_res;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_AbsynUtil_classHasLocalClasses(threadData_t *threadData, modelica_metatype _cl)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cl;
{
modelica_metatype _parts = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
_parts = tmpMeta7;
tmp1 = omc_AbsynUtil_partsHasLocalClass(threadData, _parts);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,4,5) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 5));
_parts = tmpMeta9;
tmp1 = omc_AbsynUtil_partsHasLocalClass(threadData, _parts);
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_classHasLocalClasses(threadData_t *threadData, modelica_metatype _cl)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_AbsynUtil_classHasLocalClasses(threadData, _cl);
out_res = mmc_mk_icon(_res);
return out_res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseClasses2(threadData_t *threadData, modelica_metatype _inClasses, modelica_metatype _inPath, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_boolean _inVisitProtected)
{
modelica_metatype _outTpl = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_fnptr tmp4_3;volatile modelica_metatype tmp4_4;volatile modelica_boolean tmp4_5;
tmp4_1 = _inClasses;
tmp4_2 = _inPath;
tmp4_3 = ((modelica_fnptr) _inFunc);
tmp4_4 = _inArg;
tmp4_5 = _inVisitProtected;
{
modelica_metatype _pa = NULL;
modelica_metatype _pa_3 = NULL;
modelica_fnptr _visitor;
modelica_metatype _args = NULL;
modelica_metatype _args_1 = NULL;
modelica_metatype _args_2 = NULL;
modelica_metatype _args_3 = NULL;
modelica_metatype _class_1 = NULL;
modelica_metatype _class_2 = NULL;
modelica_metatype _class_ = NULL;
modelica_metatype _classes_1 = NULL;
modelica_metatype _classes = NULL;
modelica_boolean _traverse_prot;
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
modelica_metatype tmpMeta7;
if (!listEmpty(tmp4_1)) goto tmp3_end;
_pa = tmp4_2;
_args = tmp4_4;
tmp4 += 4;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta7 = mmc_mk_box3(0, tmpMeta6, _pa, _args);
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 1: {
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_1);
tmpMeta9 = MMC_CDR(tmp4_1);
_class_ = tmpMeta8;
_classes = tmpMeta9;
_pa = tmp4_2;
_visitor = tmp4_3;
_args = tmp4_4;
_traverse_prot = tmp4_5;
tmpMeta10 = mmc_mk_box3(0, _class_, _pa, _args);
tmpMeta11 = mmc_mk_box3(0, _class_, _pa, _args);
tmpMeta12 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_visitor), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_visitor), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_visitor), 2))), tmpMeta11) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_visitor), 1)))) (threadData, tmpMeta10);
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 1));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 3));
_class_1 = tmpMeta13;
_args_1 = tmpMeta14;
tmpMeta15 = omc_AbsynUtil_traverseInnerClass(threadData, _class_1, _pa, ((modelica_fnptr) _visitor), _args_1, _traverse_prot);
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 1));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 3));
_class_2 = tmpMeta16;
_args_2 = tmpMeta17;
tmpMeta18 = omc_AbsynUtil_traverseClasses2(threadData, _classes, _pa, ((modelica_fnptr) _visitor), _args_2, _traverse_prot);
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 1));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 3));
_classes_1 = tmpMeta19;
_pa_3 = tmpMeta20;
_args_3 = tmpMeta21;
tmpMeta22 = mmc_mk_cons(_class_2, _classes_1);
tmpMeta23 = mmc_mk_box3(0, tmpMeta22, _pa_3, _args_3);
tmpMeta1 = tmpMeta23;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_boolean tmp29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta24 = MMC_CAR(tmp4_1);
tmpMeta25 = MMC_CDR(tmp4_1);
_class_ = tmpMeta24;
_classes = tmpMeta25;
_pa = tmp4_2;
_visitor = tmp4_3;
_args = tmp4_4;
_traverse_prot = tmp4_5;
tmpMeta26 = omc_AbsynUtil_traverseInnerClass(threadData, _class_, _pa, ((modelica_fnptr) _visitor), _args, _traverse_prot);
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 1));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 3));
_class_2 = tmpMeta27;
_args_2 = tmpMeta28;
tmp29 = omc_AbsynUtil_classHasLocalClasses(threadData, _class_2);
if (1 != tmp29) goto goto_2;
tmpMeta30 = omc_AbsynUtil_traverseClasses2(threadData, _classes, _pa, ((modelica_fnptr) _visitor), _args_2, _traverse_prot);
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 1));
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 2));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 3));
_classes_1 = tmpMeta31;
_pa_3 = tmpMeta32;
_args_3 = tmpMeta33;
tmpMeta34 = mmc_mk_cons(_class_2, _classes_1);
tmpMeta35 = mmc_mk_box3(0, tmpMeta34, _pa_3, _args_3);
tmpMeta1 = tmpMeta35;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta36 = MMC_CAR(tmp4_1);
tmpMeta37 = MMC_CDR(tmp4_1);
_classes = tmpMeta37;
_pa = tmp4_2;
_visitor = tmp4_3;
_args = tmp4_4;
_traverse_prot = tmp4_5;
tmpMeta38 = omc_AbsynUtil_traverseClasses2(threadData, _classes, _pa, ((modelica_fnptr) _visitor), _args, _traverse_prot);
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta38), 1));
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta38), 2));
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta38), 3));
_classes_1 = tmpMeta39;
_pa_3 = tmpMeta40;
_args_3 = tmpMeta41;
tmpMeta42 = mmc_mk_box3(0, _classes_1, _pa_3, _args_3);
tmpMeta1 = tmpMeta42;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta43 = MMC_CAR(tmp4_1);
tmpMeta44 = MMC_CDR(tmp4_1);
_class_ = tmpMeta43;
fputs(MMC_STRINGDATA(_OMC_LIT6),stdout);
fputs(MMC_STRINGDATA(omc_AbsynUtil_pathString(threadData, omc_AbsynUtil_className(threadData, _class_), _OMC_LIT7, 1, 0)),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT8),stdout);
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
_outTpl = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outTpl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseClasses2(threadData_t *threadData, modelica_metatype _inClasses, modelica_metatype _inPath, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype _inVisitProtected)
{
modelica_integer tmp1;
modelica_metatype _outTpl = NULL;
tmp1 = mmc_unbox_integer(_inVisitProtected);
_outTpl = omc_AbsynUtil_traverseClasses2(threadData, _inClasses, _inPath, _inFunc, _inArg, tmp1);
return _outTpl;
}
DLLExport
modelica_metatype omc_AbsynUtil_traverseClasses(threadData_t *threadData, modelica_metatype _inProgram, modelica_metatype _inPath, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_boolean _inVisitProtected)
{
modelica_metatype _outTpl = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inProgram;
{
modelica_metatype _classes = NULL;
modelica_metatype _pa = NULL;
modelica_metatype _arg = NULL;
modelica_metatype _p = NULL;
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
_p = tmp4_1;
tmpMeta6 = omc_AbsynUtil_traverseClasses2(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2))), _inPath, ((modelica_fnptr) _inFunc), _inArg, _inVisitProtected);
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
_classes = tmpMeta7;
_pa = tmpMeta8;
_arg = tmpMeta9;
tmpMeta10 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta10), MMC_UNTAGPTR(_p), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta10))[2] = _classes;
_p = tmpMeta10;
tmpMeta11 = mmc_mk_box3(0, _p, _pa, _arg);
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
_outTpl = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outTpl;
}
modelica_metatype boxptr_AbsynUtil_traverseClasses(threadData_t *threadData, modelica_metatype _inProgram, modelica_metatype _inPath, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype _inVisitProtected)
{
modelica_integer tmp1;
modelica_metatype _outTpl = NULL;
tmp1 = mmc_unbox_integer(_inVisitProtected);
_outTpl = omc_AbsynUtil_traverseClasses(threadData, _inProgram, _inPath, _inFunc, _inArg, tmp1);
return _outTpl;
}
DLLExport
modelica_metatype omc_AbsynUtil_stripGraphicsAndInteractionModification(threadData_t *threadData, modelica_metatype _inAbsynElementArgLst, modelica_metatype *out_outAbsynElementArgLst2)
{
modelica_metatype _outAbsynElementArgLst1 = NULL;
modelica_metatype _outAbsynElementArgLst2 = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inAbsynElementArgLst;
{
modelica_metatype _mod = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _l1 = NULL;
modelica_metatype _l2 = NULL;
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
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp4 += 5;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = tmpMeta6;
tmpMeta[0+1] = tmpMeta7;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_1);
tmpMeta9 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,6) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,1,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
if (11 != MMC_STRLEN(tmpMeta11) || strcmp(MMC_STRINGDATA(_OMC_LIT9), MMC_STRINGDATA(tmpMeta11)) != 0) goto tmp3_end;
_rest = tmpMeta9;
tmp4 += 3;
tmpMeta[0+0] = omc_AbsynUtil_stripGraphicsAndInteractionModification(threadData, _rest, &tmpMeta[0+1]);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmp4_1);
tmpMeta13 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,0,6) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,1,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
if (8 != MMC_STRLEN(tmpMeta15) || strcmp(MMC_STRINGDATA(_OMC_LIT10), MMC_STRINGDATA(tmpMeta15)) != 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 5));
if (!optionNone(tmpMeta16)) goto tmp3_end;
_rest = tmpMeta13;
tmp4 += 2;
tmpMeta[0+0] = omc_AbsynUtil_stripGraphicsAndInteractionModification(threadData, _rest, &tmpMeta[0+1]);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta17 = MMC_CAR(tmp4_1);
tmpMeta18 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,0,6) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta19,1,1) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 2));
if (8 != MMC_STRLEN(tmpMeta20) || strcmp(MMC_STRINGDATA(_OMC_LIT10), MMC_STRINGDATA(tmpMeta20)) != 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 5));
if (optionNone(tmpMeta21)) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 1));
_mod = tmpMeta17;
_rest = tmpMeta18;
tmp4 += 1;
_l1 = omc_AbsynUtil_stripGraphicsAndInteractionModification(threadData, _rest ,&_l2);
tmpMeta23 = mmc_mk_cons(_mod, _l2);
tmpMeta[0+0] = _l1;
tmpMeta[0+1] = tmpMeta23;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta24 = MMC_CAR(tmp4_1);
tmpMeta25 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta24,0,6) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,1,1) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 2));
if (6 != MMC_STRLEN(tmpMeta27) || strcmp(MMC_STRINGDATA(_OMC_LIT0), MMC_STRINGDATA(tmpMeta27)) != 0) goto tmp3_end;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 5));
if (optionNone(tmpMeta28)) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta28), 1));
_mod = tmpMeta24;
_rest = tmpMeta25;
_l1 = omc_AbsynUtil_stripGraphicsAndInteractionModification(threadData, _rest ,&_l2);
tmpMeta30 = mmc_mk_cons(_mod, _l2);
tmpMeta[0+0] = _l1;
tmpMeta[0+1] = tmpMeta30;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta31 = MMC_CAR(tmp4_1);
tmpMeta32 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta31,0,6) == 0) goto tmp3_end;
_mod = tmpMeta31;
_rest = tmpMeta32;
_l1 = omc_AbsynUtil_stripGraphicsAndInteractionModification(threadData, _rest ,&_l2);
tmpMeta33 = mmc_mk_cons(_mod, _l1);
tmpMeta[0+0] = tmpMeta33;
tmpMeta[0+1] = _l2;
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
_outAbsynElementArgLst1 = tmpMeta[0+0];
_outAbsynElementArgLst2 = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outAbsynElementArgLst2) { *out_outAbsynElementArgLst2 = _outAbsynElementArgLst2; }
return _outAbsynElementArgLst1;
}
DLLExport
modelica_metatype omc_AbsynUtil_getAnnotationsFromItems(threadData_t *threadData, modelica_metatype _inComponentItems, modelica_metatype _ccAnnotations)
{
modelica_metatype _outLst = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _annotations = NULL;
modelica_metatype _res = NULL;
modelica_string _str = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outLst = tmpMeta1;
{
modelica_metatype _comp;
for (tmpMeta2 = listReverse(_inComponentItems); !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_comp = MMC_CAR(tmpMeta2);
{
modelica_metatype tmp6_1;
tmp6_1 = _comp;
{
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
for (; tmp6 < 2; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 4));
if (optionNone(tmpMeta8)) goto tmp5_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 1));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (optionNone(tmpMeta10)) goto tmp5_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 1));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
_annotations = tmpMeta12;
tmpMeta3 = listAppend(_annotations, _ccAnnotations);
goto tmp5_done;
}
case 1: {
tmpMeta3 = _ccAnnotations;
goto tmp5_done;
}
}
goto tmp5_end;
tmp5_end: ;
}
goto goto_4;
goto_4:;
MMC_THROW_INTERNAL();
goto tmp5_done;
tmp5_done:;
}
}
_annotations = tmpMeta3;
tmpMeta13 = mmc_mk_cons(_annotations, _outLst);
_outLst = tmpMeta13;
}
}
_return: OMC_LABEL_UNUSED
return _outLst;
}
DLLExport
modelica_metatype omc_AbsynUtil_getAnnotationsFromConstraintClass(threadData_t *threadData, modelica_metatype _inCC)
{
modelica_metatype _elementArgs = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCC;
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
modelica_metatype tmpMeta11;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
if (optionNone(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
if (optionNone(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 1));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_elementArgs = tmpMeta11;
tmpMeta1 = _elementArgs;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta12;
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
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
_elementArgs = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _elementArgs;
}
DLLExport
modelica_integer omc_AbsynUtil_pathPartCount(threadData_t *threadData, modelica_metatype _path, modelica_integer _partsAccum)
{
modelica_integer _parts;
modelica_integer tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _path;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
tmp1 = ((modelica_integer) 1) + _partsAccum;
goto tmp3_done;
}
case 3: {
_path = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 3)));
_partsAccum = ((modelica_integer) 1) + _partsAccum;
goto _tailrecursive;
goto tmp3_done;
}
case 5: {
_path = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2)));
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
_parts = tmp1;
_return: OMC_LABEL_UNUSED
return _parts;
}
modelica_metatype boxptr_AbsynUtil_pathPartCount(threadData_t *threadData, modelica_metatype _path, modelica_metatype _partsAccum)
{
modelica_integer tmp1;
modelica_integer _parts;
modelica_metatype out_parts;
tmp1 = mmc_unbox_integer(_partsAccum);
_parts = omc_AbsynUtil_pathPartCount(threadData, _path, tmp1);
out_parts = mmc_mk_icon(_parts);
return out_parts;
}
DLLExport
modelica_metatype omc_AbsynUtil_isInvariantExpNoTraverse(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fe, modelica_boolean __omcQ_24in_5Fb, modelica_boolean *out_b)
{
modelica_metatype _e = NULL;
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_e = __omcQ_24in_5Fe;
_b = __omcQ_24in_5Fb;
if((!_b))
{
goto _return;
}
{
modelica_metatype tmp4_1;
tmp4_1 = _e;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 18; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,3) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,14,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 14: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,3) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 15: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,20,2) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 16: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 17: {
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
if (out_b) { *out_b = _b; }
return _e;
}
modelica_metatype boxptr_AbsynUtil_isInvariantExpNoTraverse(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fe, modelica_metatype __omcQ_24in_5Fb, modelica_metatype *out_b)
{
modelica_integer tmp1;
modelica_boolean _b;
modelica_metatype _e = NULL;
tmp1 = mmc_unbox_integer(__omcQ_24in_5Fb);
_e = omc_AbsynUtil_isInvariantExpNoTraverse(threadData, __omcQ_24in_5Fe, tmp1, &_b);
if (out_b) { *out_b = mmc_mk_icon(_b); }
return _e;
}
DLLExport
modelica_boolean omc_AbsynUtil_isEmptyClassPart(threadData_t *threadData, modelica_metatype _inClassPart)
{
modelica_boolean _outIsEmpty;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClassPart;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 8; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta7)) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta8)) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta9)) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta10)) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta11)) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta12)) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 7: {
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
modelica_metatype boxptr_AbsynUtil_isEmptyClassPart(threadData_t *threadData, modelica_metatype _inClassPart)
{
modelica_boolean _outIsEmpty;
modelica_metatype out_outIsEmpty;
_outIsEmpty = omc_AbsynUtil_isEmptyClassPart(threadData, _inClassPart);
out_outIsEmpty = mmc_mk_icon(_outIsEmpty);
return out_outIsEmpty;
}
DLLExport
modelica_boolean omc_AbsynUtil_isElementItemClassNamed(threadData_t *threadData, modelica_string _inName, modelica_metatype _inElement)
{
modelica_boolean _outIsNamed;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
modelica_string _name = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,6) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
_name = tmpMeta9;
tmp1 = (stringEqual(_name, _inName));
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
_outIsNamed = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsNamed;
}
modelica_metatype boxptr_AbsynUtil_isElementItemClassNamed(threadData_t *threadData, modelica_metatype _inName, modelica_metatype _inElement)
{
modelica_boolean _outIsNamed;
modelica_metatype out_outIsNamed;
_outIsNamed = omc_AbsynUtil_isElementItemClassNamed(threadData, _inName, _inElement);
out_outIsNamed = mmc_mk_icon(_outIsNamed);
return out_outIsNamed;
}
DLLExport
modelica_boolean omc_AbsynUtil_isAlgorithmItem(threadData_t *threadData, modelica_metatype _inAlg)
{
modelica_boolean _outIsClass;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAlg;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,3) == 0) goto tmp3_end;
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
_outIsClass = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsClass;
}
modelica_metatype boxptr_AbsynUtil_isAlgorithmItem(threadData_t *threadData, modelica_metatype _inAlg)
{
modelica_boolean _outIsClass;
modelica_metatype out_outIsClass;
_outIsClass = omc_AbsynUtil_isAlgorithmItem(threadData, _inAlg);
out_outIsClass = mmc_mk_icon(_outIsClass);
return out_outIsClass;
}
DLLExport
modelica_boolean omc_AbsynUtil_isElementItem(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsClass;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
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
_outIsClass = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsClass;
}
modelica_metatype boxptr_AbsynUtil_isElementItem(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsClass;
modelica_metatype out_outIsClass;
_outIsClass = omc_AbsynUtil_isElementItem(threadData, _inElement);
out_outIsClass = mmc_mk_icon(_outIsClass);
return out_outIsClass;
}
DLLExport
modelica_boolean omc_AbsynUtil_isElementItemClass(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsClass;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,6) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,2) == 0) goto tmp3_end;
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
_outIsClass = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsClass;
}
modelica_metatype boxptr_AbsynUtil_isElementItemClass(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsClass;
modelica_metatype out_outIsClass;
_outIsClass = omc_AbsynUtil_isElementItemClass(threadData, _inElement);
out_outIsClass = mmc_mk_icon(_outIsClass);
return out_outIsClass;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseExpShallowIterator(threadData_t *threadData, modelica_metatype _inIterator, modelica_metatype _inArg, modelica_fnptr _inFunc)
{
modelica_metatype _outIterator = NULL;
modelica_string _name = NULL;
modelica_metatype _guard_exp = NULL;
modelica_metatype _range_exp = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inIterator;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
_name = tmpMeta2;
_guard_exp = tmpMeta3;
_range_exp = tmpMeta4;
_guard_exp = omc_Util_applyOption1(threadData, _guard_exp, ((modelica_fnptr) _inFunc), _inArg);
_range_exp = omc_Util_applyOption1(threadData, _range_exp, ((modelica_fnptr) _inFunc), _inArg);
tmpMeta5 = mmc_mk_box4(3, &Absyn_ForIterator_ITERATOR__desc, _name, _guard_exp, _range_exp);
_outIterator = tmpMeta5;
_return: OMC_LABEL_UNUSED
return _outIterator;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseExpShallowFuncArgs(threadData_t *threadData, modelica_metatype _inArgs, modelica_metatype _inArg, modelica_fnptr _inFunc)
{
modelica_metatype _outArgs = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outArgs = _inArgs;
{
modelica_metatype tmp4_1;
tmp4_1 = _outArgs;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
{
modelica_metatype __omcQ_24tmpVar9;
modelica_metatype* tmp8;
modelica_metatype tmpMeta9;
modelica_metatype __omcQ_24tmpVar8;
modelica_integer tmp10;
modelica_metatype _arg_loopVar = 0;
modelica_metatype _arg;
_arg_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outArgs), 2)));
tmpMeta9 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar9 = tmpMeta9;
tmp8 = &__omcQ_24tmpVar9;
while(1) {
tmp10 = 1;
if (!listEmpty(_arg_loopVar)) {
_arg = MMC_CAR(_arg_loopVar);
_arg_loopVar = MMC_CDR(_arg_loopVar);
tmp10--;
}
if (tmp10 == 0) {
__omcQ_24tmpVar8 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), _arg, _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, _arg, _inArg);
*tmp8 = mmc_mk_cons(__omcQ_24tmpVar8,0);
tmp8 = &MMC_CDR(*tmp8);
} else if (tmp10 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp8 = mmc_mk_nil();
tmpMeta7 = __omcQ_24tmpVar9;
}
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_outArgs), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[2] = tmpMeta7;
_outArgs = tmpMeta6;
tmpMeta1 = _outArgs;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta11 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta11), MMC_UNTAGPTR(_outArgs), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta11))[2] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outArgs), 2))), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outArgs), 2))), _inArg);
_outArgs = tmpMeta11;
{
modelica_metatype __omcQ_24tmpVar11;
modelica_metatype* tmp14;
modelica_metatype tmpMeta15;
modelica_metatype __omcQ_24tmpVar10;
modelica_integer tmp16;
modelica_metatype _it_loopVar = 0;
modelica_metatype _it;
_it_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outArgs), 4)));
tmpMeta15 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar11 = tmpMeta15;
tmp14 = &__omcQ_24tmpVar11;
while(1) {
tmp16 = 1;
if (!listEmpty(_it_loopVar)) {
_it = MMC_CAR(_it_loopVar);
_it_loopVar = MMC_CDR(_it_loopVar);
tmp16--;
}
if (tmp16 == 0) {
__omcQ_24tmpVar10 = omc_AbsynUtil_traverseExpShallowIterator(threadData, _it, _inArg, ((modelica_fnptr) _inFunc));
*tmp14 = mmc_mk_cons(__omcQ_24tmpVar10,0);
tmp14 = &MMC_CDR(*tmp14);
} else if (tmp16 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp14 = mmc_mk_nil();
tmpMeta13 = __omcQ_24tmpVar11;
}
tmpMeta12 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta12), MMC_UNTAGPTR(_outArgs), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta12))[4] = tmpMeta13;
_outArgs = tmpMeta12;
tmpMeta1 = _outArgs;
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
_outArgs = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outArgs;
}
DLLExport
modelica_metatype omc_AbsynUtil_traverseExpShallow(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inArg, modelica_fnptr _inFunc)
{
modelica_metatype _outExp = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outExp = _inExp;
{
modelica_metatype tmp3_1;
tmp3_1 = _outExp;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 8: {
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
tmpMeta4 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta4), MMC_UNTAGPTR(_outExp), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta4))[2] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 2))), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 2))), _inArg);
_outExp = tmpMeta4;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_outExp), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[4] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 4))), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 4))), _inArg);
_outExp = tmpMeta5;
goto tmp2_done;
}
case 9: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_outExp), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[3] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 3))), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 3))), _inArg);
_outExp = tmpMeta6;
goto tmp2_done;
}
case 10: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
tmpMeta7 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta7), MMC_UNTAGPTR(_outExp), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta7))[2] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 2))), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 2))), _inArg);
_outExp = tmpMeta7;
tmpMeta8 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta8), MMC_UNTAGPTR(_outExp), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta8))[4] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 4))), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 4))), _inArg);
_outExp = tmpMeta8;
goto tmp2_done;
}
case 11: {
modelica_metatype tmpMeta9;
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_outExp), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[3] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 3))), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 3))), _inArg);
_outExp = tmpMeta9;
goto tmp2_done;
}
case 12: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
tmpMeta10 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta10), MMC_UNTAGPTR(_outExp), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta10))[2] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 2))), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 2))), _inArg);
_outExp = tmpMeta10;
tmpMeta11 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta11), MMC_UNTAGPTR(_outExp), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta11))[4] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 4))), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 4))), _inArg);
_outExp = tmpMeta11;
goto tmp2_done;
}
case 13: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
tmpMeta12 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta12), MMC_UNTAGPTR(_outExp), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta12))[2] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 2))), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 2))), _inArg);
_outExp = tmpMeta12;
tmpMeta13 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta13), MMC_UNTAGPTR(_outExp), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta13))[3] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 3))), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 3))), _inArg);
_outExp = tmpMeta13;
tmpMeta14 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta14), MMC_UNTAGPTR(_outExp), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta14))[4] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 4))), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 4))), _inArg);
_outExp = tmpMeta14;
{
modelica_metatype __omcQ_24tmpVar13;
modelica_metatype* tmp17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype __omcQ_24tmpVar12;
modelica_integer tmp20;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 5)));
tmpMeta18 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar13 = tmpMeta18;
tmp17 = &__omcQ_24tmpVar13;
while(1) {
tmp20 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp20--;
}
if (tmp20 == 0) {
tmpMeta19 = mmc_mk_box2(0, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), omc_Util_tuple21(threadData, _e), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, omc_Util_tuple21(threadData, _e), _inArg), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), omc_Util_tuple22(threadData, _e), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, omc_Util_tuple22(threadData, _e), _inArg));
__omcQ_24tmpVar12 = tmpMeta19;
*tmp17 = mmc_mk_cons(__omcQ_24tmpVar12,0);
tmp17 = &MMC_CDR(*tmp17);
} else if (tmp20 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp17 = mmc_mk_nil();
tmpMeta16 = __omcQ_24tmpVar13;
}
tmpMeta15 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta15), MMC_UNTAGPTR(_outExp), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta15))[5] = tmpMeta16;
_outExp = tmpMeta15;
goto tmp2_done;
}
case 14: {
modelica_metatype tmpMeta21;
tmpMeta21 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta21), MMC_UNTAGPTR(_outExp), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta21))[3] = omc_AbsynUtil_traverseExpShallowFuncArgs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 3))), _inArg, ((modelica_fnptr) _inFunc));
_outExp = tmpMeta21;
goto tmp2_done;
}
case 15: {
modelica_metatype tmpMeta22;
tmpMeta22 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta22), MMC_UNTAGPTR(_outExp), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta22))[3] = omc_AbsynUtil_traverseExpShallowFuncArgs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 3))), _inArg, ((modelica_fnptr) _inFunc));
_outExp = tmpMeta22;
goto tmp2_done;
}
case 16: {
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
{
modelica_metatype __omcQ_24tmpVar15;
modelica_metatype* tmp25;
modelica_metatype tmpMeta26;
modelica_metatype __omcQ_24tmpVar14;
modelica_integer tmp27;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 2)));
tmpMeta26 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar15 = tmpMeta26;
tmp25 = &__omcQ_24tmpVar15;
while(1) {
tmp27 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp27--;
}
if (tmp27 == 0) {
__omcQ_24tmpVar14 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), _e, _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, _e, _inArg);
*tmp25 = mmc_mk_cons(__omcQ_24tmpVar14,0);
tmp25 = &MMC_CDR(*tmp25);
} else if (tmp27 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp25 = mmc_mk_nil();
tmpMeta24 = __omcQ_24tmpVar15;
}
tmpMeta23 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta23), MMC_UNTAGPTR(_outExp), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta23))[2] = tmpMeta24;
_outExp = tmpMeta23;
goto tmp2_done;
}
case 17: {
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
{
modelica_metatype __omcQ_24tmpVar19;
modelica_metatype* tmp30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype __omcQ_24tmpVar18;
modelica_integer tmp36;
modelica_metatype _lst_loopVar = 0;
modelica_metatype _lst;
_lst_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 2)));
tmpMeta31 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar19 = tmpMeta31;
tmp30 = &__omcQ_24tmpVar19;
while(1) {
tmp36 = 1;
if (!listEmpty(_lst_loopVar)) {
_lst = MMC_CAR(_lst_loopVar);
_lst_loopVar = MMC_CDR(_lst_loopVar);
tmp36--;
}
if (tmp36 == 0) {
{
modelica_metatype __omcQ_24tmpVar17;
modelica_metatype* tmp33;
modelica_metatype tmpMeta34;
modelica_metatype __omcQ_24tmpVar16;
modelica_integer tmp35;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _lst;
tmpMeta34 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar17 = tmpMeta34;
tmp33 = &__omcQ_24tmpVar17;
while(1) {
tmp35 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp35--;
}
if (tmp35 == 0) {
__omcQ_24tmpVar16 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), _e, _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, _e, _inArg);
*tmp33 = mmc_mk_cons(__omcQ_24tmpVar16,0);
tmp33 = &MMC_CDR(*tmp33);
} else if (tmp35 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp33 = mmc_mk_nil();
tmpMeta32 = __omcQ_24tmpVar17;
}
__omcQ_24tmpVar18 = tmpMeta32;
*tmp30 = mmc_mk_cons(__omcQ_24tmpVar18,0);
tmp30 = &MMC_CDR(*tmp30);
} else if (tmp36 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp30 = mmc_mk_nil();
tmpMeta29 = __omcQ_24tmpVar19;
}
tmpMeta28 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta28), MMC_UNTAGPTR(_outExp), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta28))[2] = tmpMeta29;
_outExp = tmpMeta28;
goto tmp2_done;
}
case 18: {
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
tmpMeta37 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta37), MMC_UNTAGPTR(_outExp), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta37))[2] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 2))), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 2))), _inArg);
_outExp = tmpMeta37;
tmpMeta38 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta38), MMC_UNTAGPTR(_outExp), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta38))[3] = omc_Util_applyOption1(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 3))), ((modelica_fnptr) _inFunc), _inArg);
_outExp = tmpMeta38;
tmpMeta39 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta39), MMC_UNTAGPTR(_outExp), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta39))[4] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 4))), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 4))), _inArg);
_outExp = tmpMeta39;
goto tmp2_done;
}
case 19: {
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
{
modelica_metatype __omcQ_24tmpVar21;
modelica_metatype* tmp42;
modelica_metatype tmpMeta43;
modelica_metatype __omcQ_24tmpVar20;
modelica_integer tmp44;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 2)));
tmpMeta43 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar21 = tmpMeta43;
tmp42 = &__omcQ_24tmpVar21;
while(1) {
tmp44 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp44--;
}
if (tmp44 == 0) {
__omcQ_24tmpVar20 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), _e, _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, _e, _inArg);
*tmp42 = mmc_mk_cons(__omcQ_24tmpVar20,0);
tmp42 = &MMC_CDR(*tmp42);
} else if (tmp44 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp42 = mmc_mk_nil();
tmpMeta41 = __omcQ_24tmpVar21;
}
tmpMeta40 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta40), MMC_UNTAGPTR(_outExp), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta40))[2] = tmpMeta41;
_outExp = tmpMeta40;
goto tmp2_done;
}
case 22: {
modelica_metatype tmpMeta45;
tmpMeta45 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta45), MMC_UNTAGPTR(_outExp), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta45))[3] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 3))), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 3))), _inArg);
_outExp = tmpMeta45;
goto tmp2_done;
}
case 23: {
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
tmpMeta46 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta46), MMC_UNTAGPTR(_outExp), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta46))[2] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 2))), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 2))), _inArg);
_outExp = tmpMeta46;
tmpMeta47 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta47), MMC_UNTAGPTR(_outExp), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta47))[3] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 3))), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 3))), _inArg);
_outExp = tmpMeta47;
goto tmp2_done;
}
case 25: {
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
{
modelica_metatype __omcQ_24tmpVar23;
modelica_metatype* tmp50;
modelica_metatype tmpMeta51;
modelica_metatype __omcQ_24tmpVar22;
modelica_integer tmp52;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 2)));
tmpMeta51 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar23 = tmpMeta51;
tmp50 = &__omcQ_24tmpVar23;
while(1) {
tmp52 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp52--;
}
if (tmp52 == 0) {
__omcQ_24tmpVar22 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), _e, _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, _e, _inArg);
*tmp50 = mmc_mk_cons(__omcQ_24tmpVar22,0);
tmp50 = &MMC_CDR(*tmp50);
} else if (tmp52 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp50 = mmc_mk_nil();
tmpMeta49 = __omcQ_24tmpVar23;
}
tmpMeta48 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta48), MMC_UNTAGPTR(_outExp), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta48))[2] = tmpMeta49;
_outExp = tmpMeta48;
goto tmp2_done;
}
case 26: {
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
tmpMeta53 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta53), MMC_UNTAGPTR(_outExp), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta53))[2] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 2))), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 2))), _inArg);
_outExp = tmpMeta53;
tmpMeta54 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta54), MMC_UNTAGPTR(_outExp), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta54))[3] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 3))), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outExp), 3))), _inArg);
_outExp = tmpMeta54;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
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
return _outExp;
}
DLLExport
modelica_metatype omc_AbsynUtil_crefExplode(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inAccum)
{
modelica_metatype _outCrefParts = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
tmpMeta6 = mmc_mk_cons(omc_AbsynUtil_crefFirstCref(threadData, _inCref), _inAccum);
tmpMeta5 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 4)));
_inAccum = tmpMeta6;
_inCref = tmpMeta5;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
_inCref = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 2)));
goto _tailrecursive;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
modelica_metatype tmpMeta7;
tmpMeta7 = mmc_mk_cons(_inCref, _inAccum);
tmpMeta1 = listReverse(tmpMeta7);
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
_outCrefParts = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCrefParts;
}
DLLExport
modelica_metatype omc_AbsynUtil_makeIntegerSubscript(threadData_t *threadData, modelica_integer _n)
{
modelica_metatype _sub = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box2(3, &Absyn_Exp_INTEGER__desc, mmc_mk_integer(_n));
tmpMeta2 = mmc_mk_box2(4, &Absyn_Subscript_SUBSCRIPT__desc, tmpMeta1);
_sub = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _sub;
}
modelica_metatype boxptr_AbsynUtil_makeIntegerSubscript(threadData_t *threadData, modelica_metatype _n)
{
modelica_integer tmp1;
modelica_metatype _sub = NULL;
tmp1 = mmc_unbox_integer(_n);
_sub = omc_AbsynUtil_makeIntegerSubscript(threadData, tmp1);
return _sub;
}
DLLExport
modelica_metatype omc_AbsynUtil_makeSubscript(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outSubscript = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box2(4, &Absyn_Subscript_SUBSCRIPT__desc, _inExp);
_outSubscript = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outSubscript;
}
DLLExport
modelica_metatype omc_AbsynUtil_optMsg(threadData_t *threadData, modelica_boolean _inShowMessage, modelica_metatype _inInfo)
{
modelica_metatype _outMsg = NULL;
modelica_metatype tmpMeta1;
modelica_boolean tmp2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmp2 = (modelica_boolean)_inShowMessage;
if(tmp2)
{
tmpMeta1 = mmc_mk_box2(3, &Absyn_Msg_MSG__desc, _inInfo);
tmpMeta3 = tmpMeta1;
}
else
{
tmpMeta3 = _OMC_LIT11;
}
_outMsg = tmpMeta3;
_return: OMC_LABEL_UNUSED
return _outMsg;
}
modelica_metatype boxptr_AbsynUtil_optMsg(threadData_t *threadData, modelica_metatype _inShowMessage, modelica_metatype _inInfo)
{
modelica_integer tmp1;
modelica_metatype _outMsg = NULL;
tmp1 = mmc_unbox_integer(_inShowMessage);
_outMsg = omc_AbsynUtil_optMsg(threadData, tmp1, _inInfo);
return _outMsg;
}
DLLExport
modelica_boolean omc_AbsynUtil_elementArgEqualName(threadData_t *threadData, modelica_metatype _inArg1, modelica_metatype _inArg2)
{
modelica_boolean _outEqual;
modelica_metatype _name1 = NULL;
modelica_metatype _name2 = NULL;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inArg1;
tmp4_2 = _inArg2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,6) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_name1 = tmpMeta6;
_name2 = tmpMeta7;
tmp1 = omc_AbsynUtil_pathEqual(threadData, _name1, _name2);
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
modelica_metatype boxptr_AbsynUtil_elementArgEqualName(threadData_t *threadData, modelica_metatype _inArg1, modelica_metatype _inArg2)
{
modelica_boolean _outEqual;
modelica_metatype out_outEqual;
_outEqual = omc_AbsynUtil_elementArgEqualName(threadData, _inArg1, _inArg2);
out_outEqual = mmc_mk_icon(_outEqual);
return out_outEqual;
}
DLLExport
modelica_metatype omc_AbsynUtil_elementArgName(threadData_t *threadData, modelica_metatype _inArg)
{
modelica_metatype _outName = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inArg;
{
modelica_metatype _e = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_outName = tmpMeta6;
tmpMeta1 = _outName;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,6) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e = tmpMeta7;
tmpMeta1 = omc_AbsynUtil_makeIdentPathFromString(threadData, omc_AbsynUtil_elementSpecName(threadData, _e));
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
_outName = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outName;
}
DLLExport
modelica_boolean omc_AbsynUtil_isEmptySubMod(threadData_t *threadData, modelica_metatype _inSubMod)
{
modelica_boolean _outIsEmpty;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inSubMod;
{
modelica_metatype _mod = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (!optionNone(tmpMeta6)) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (optionNone(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
_mod = tmpMeta8;
tmp1 = omc_AbsynUtil_isEmptyMod(threadData, _mod);
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
modelica_metatype boxptr_AbsynUtil_isEmptySubMod(threadData_t *threadData, modelica_metatype _inSubMod)
{
modelica_boolean _outIsEmpty;
modelica_metatype out_outIsEmpty;
_outIsEmpty = omc_AbsynUtil_isEmptySubMod(threadData, _inSubMod);
out_outIsEmpty = mmc_mk_icon(_outIsEmpty);
return out_outIsEmpty;
}
DLLExport
modelica_boolean omc_AbsynUtil_isEmptyMod(threadData_t *threadData, modelica_metatype _inMod)
{
modelica_boolean _outIsEmpty;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inMod;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,1,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,16,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
if (!listEmpty(tmpMeta11)) goto tmp3_end;
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
_outIsEmpty = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsEmpty;
}
modelica_metatype boxptr_AbsynUtil_isEmptyMod(threadData_t *threadData, modelica_metatype _inMod)
{
modelica_boolean _outIsEmpty;
modelica_metatype out_outIsEmpty;
_outIsEmpty = omc_AbsynUtil_isEmptyMod(threadData, _inMod);
out_outIsEmpty = mmc_mk_icon(_outIsEmpty);
return out_outIsEmpty;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseClassDef(threadData_t *threadData, modelica_metatype _inClassDef, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_boolean *out_outContinue)
{
modelica_metatype _outClassDef = NULL;
modelica_metatype _outArg = NULL;
modelica_boolean _outContinue;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outClassDef = _inClassDef;
_outArg = _inArg;
_outContinue = 1;
{
modelica_metatype tmp3_1;
tmp3_1 = _outClassDef;
{
modelica_metatype _parts = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
modelica_metatype tmpMeta4;
_parts = omc_AbsynUtil_traverseListGeneric(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outClassDef), 4))), ((modelica_fnptr) _inFunc), _inArg ,&_outArg ,&_outContinue);
tmpMeta4 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta4), MMC_UNTAGPTR(_outClassDef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta4))[4] = _parts;
_outClassDef = tmpMeta4;
goto tmp2_done;
}
case 7: {
modelica_metatype tmpMeta5;
_parts = omc_AbsynUtil_traverseListGeneric(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outClassDef), 5))), ((modelica_fnptr) _inFunc), _inArg ,&_outArg ,&_outContinue);
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_outClassDef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[5] = _parts;
_outClassDef = tmpMeta5;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
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
if (out_outArg) { *out_outArg = _outArg; }
if (out_outContinue) { *out_outContinue = _outContinue; }
return _outClassDef;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseClassDef(threadData_t *threadData, modelica_metatype _inClassDef, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_metatype *out_outContinue)
{
modelica_boolean _outContinue;
modelica_metatype _outClassDef = NULL;
_outClassDef = omc_AbsynUtil_traverseClassDef(threadData, _inClassDef, _inFunc, _inArg, out_outArg, &_outContinue);
if (out_outContinue) { *out_outContinue = mmc_mk_icon(_outContinue); }
return _outClassDef;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseElementSpecComponents(threadData_t *threadData, modelica_metatype _inSpec, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_boolean *out_outContinue)
{
modelica_metatype _outSpec = NULL;
modelica_metatype _outArg = NULL;
modelica_boolean _outContinue;
modelica_boolean tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outSpec = _inSpec;
{
modelica_metatype tmp4_1;
tmp4_1 = _outSpec;
{
modelica_metatype _comps = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,3) == 0) goto tmp3_end;
tmpMeta9 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outSpec), 4))), _inArg, &tmpMeta6, &tmpMeta7) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outSpec), 4))), _inArg, &tmpMeta6, &tmpMeta7);
_comps = tmpMeta9;
tmp8 = mmc_unbox_integer(tmpMeta7);
_outArg = tmpMeta6;
_outContinue = tmp8;
if((!referenceEq(_comps, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outSpec), 4))))))
{
tmpMeta10 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta10), MMC_UNTAGPTR(_outSpec), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta10))[4] = _comps;
_outSpec = tmpMeta10;
}
tmpMeta[0+0] = _outSpec;
tmpMeta[0+1] = _outArg;
tmp1_c2 = _outContinue;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _inSpec;
tmpMeta[0+1] = _inArg;
tmp1_c2 = 1;
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
_outSpec = tmpMeta[0+0];
_outArg = tmpMeta[0+1];
_outContinue = tmp1_c2;
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
if (out_outContinue) { *out_outContinue = _outContinue; }
return _outSpec;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseElementSpecComponents(threadData_t *threadData, modelica_metatype _inSpec, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_metatype *out_outContinue)
{
modelica_boolean _outContinue;
modelica_metatype _outSpec = NULL;
_outSpec = omc_AbsynUtil_traverseElementSpecComponents(threadData, _inSpec, _inFunc, _inArg, out_outArg, &_outContinue);
if (out_outContinue) { *out_outContinue = mmc_mk_icon(_outContinue); }
return _outSpec;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseElementComponents(threadData_t *threadData, modelica_metatype _inElement, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_boolean *out_outContinue)
{
modelica_metatype _outElement = NULL;
modelica_metatype _outArg = NULL;
modelica_boolean _outContinue;
modelica_boolean tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outElement = _inElement;
{
modelica_metatype tmp4_1;
tmp4_1 = _outElement;
{
modelica_metatype _spec = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
_spec = omc_AbsynUtil_traverseElementSpecComponents(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outElement), 5))), ((modelica_fnptr) _inFunc), _inArg ,&_outArg ,&_outContinue);
if((!referenceEq(_spec, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outElement), 5))))))
{
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_outElement), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[5] = _spec;
_outElement = tmpMeta6;
}
tmpMeta[0+0] = _outElement;
tmpMeta[0+1] = _outArg;
tmp1_c2 = _outContinue;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _inElement;
tmpMeta[0+1] = _inArg;
tmp1_c2 = 1;
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
_outElement = tmpMeta[0+0];
_outArg = tmpMeta[0+1];
_outContinue = tmp1_c2;
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
if (out_outContinue) { *out_outContinue = _outContinue; }
return _outElement;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseElementComponents(threadData_t *threadData, modelica_metatype _inElement, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_metatype *out_outContinue)
{
modelica_boolean _outContinue;
modelica_metatype _outElement = NULL;
_outElement = omc_AbsynUtil_traverseElementComponents(threadData, _inElement, _inFunc, _inArg, out_outArg, &_outContinue);
if (out_outContinue) { *out_outContinue = mmc_mk_icon(_outContinue); }
return _outElement;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseElementItemComponents(threadData_t *threadData, modelica_metatype _inItem, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_boolean *out_outContinue)
{
modelica_metatype _outItem = NULL;
modelica_metatype _outArg = NULL;
modelica_boolean _outContinue;
modelica_boolean tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inItem;
{
modelica_metatype _elem = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_boolean tmp7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
_elem = omc_AbsynUtil_traverseElementComponents(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inItem), 2))), ((modelica_fnptr) _inFunc), _inArg ,&_outArg ,&_outContinue);
tmp7 = (modelica_boolean)referenceEq(_elem, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inItem), 2))));
if(tmp7)
{
tmpMeta8 = _inItem;
}
else
{
tmpMeta6 = mmc_mk_box2(3, &Absyn_ElementItem_ELEMENTITEM__desc, _elem);
tmpMeta8 = tmpMeta6;
}
_outItem = tmpMeta8;
tmpMeta[0+0] = _outItem;
tmpMeta[0+1] = _outArg;
tmp1_c2 = _outContinue;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _inItem;
tmpMeta[0+1] = _inArg;
tmp1_c2 = 1;
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
_outItem = tmpMeta[0+0];
_outArg = tmpMeta[0+1];
_outContinue = tmp1_c2;
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
if (out_outContinue) { *out_outContinue = _outContinue; }
return _outItem;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseElementItemComponents(threadData_t *threadData, modelica_metatype _inItem, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_metatype *out_outContinue)
{
modelica_boolean _outContinue;
modelica_metatype _outItem = NULL;
_outItem = omc_AbsynUtil_traverseElementItemComponents(threadData, _inItem, _inFunc, _inArg, out_outArg, &_outContinue);
if (out_outContinue) { *out_outContinue = mmc_mk_icon(_outContinue); }
return _outItem;
}
static modelica_metatype closure5_AbsynUtil_traverseElementItemComponents(threadData_t *thData, modelica_metatype closure, modelica_metatype inItem, modelica_metatype inArg, modelica_metatype tmp4, modelica_metatype tmp5)
{
modelica_fnptr inFunc = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_AbsynUtil_traverseElementItemComponents(thData, inItem, inFunc, inArg, tmp4, tmp5);
}static modelica_metatype closure6_AbsynUtil_traverseElementItemComponents(threadData_t *thData, modelica_metatype closure, modelica_metatype inItem, modelica_metatype inArg, modelica_metatype tmp8, modelica_metatype tmp9)
{
modelica_fnptr inFunc = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_AbsynUtil_traverseElementItemComponents(thData, inItem, inFunc, inArg, tmp8, tmp9);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseClassPartComponents(threadData_t *threadData, modelica_metatype _inClassPart, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_boolean *out_outContinue)
{
modelica_metatype _outClassPart = NULL;
modelica_metatype _outArg = NULL;
modelica_boolean _outContinue;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outClassPart = _inClassPart;
_outArg = _inArg;
_outContinue = 1;
{
modelica_metatype tmp3_1;
tmp3_1 = _outClassPart;
{
modelica_metatype _items = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = mmc_mk_box1(0, ((modelica_fnptr) _inFunc));
_items = omc_AbsynUtil_traverseListGeneric(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outClassPart), 2))), (modelica_fnptr) mmc_mk_box2(0,closure5_AbsynUtil_traverseElementItemComponents,tmpMeta6), _inArg ,&_outArg ,&_outContinue);
tmpMeta7 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta7), MMC_UNTAGPTR(_outClassPart), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta7))[2] = _items;
_outClassPart = tmpMeta7;
goto tmp2_done;
}
case 4: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
tmpMeta10 = mmc_mk_box1(0, ((modelica_fnptr) _inFunc));
_items = omc_AbsynUtil_traverseListGeneric(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outClassPart), 2))), (modelica_fnptr) mmc_mk_box2(0,closure6_AbsynUtil_traverseElementItemComponents,tmpMeta10), _inArg ,&_outArg ,&_outContinue);
tmpMeta11 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta11), MMC_UNTAGPTR(_outClassPart), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta11))[2] = _items;
_outClassPart = tmpMeta11;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
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
if (out_outArg) { *out_outArg = _outArg; }
if (out_outContinue) { *out_outContinue = _outContinue; }
return _outClassPart;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseClassPartComponents(threadData_t *threadData, modelica_metatype _inClassPart, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_metatype *out_outContinue)
{
modelica_boolean _outContinue;
modelica_metatype _outClassPart = NULL;
_outClassPart = omc_AbsynUtil_traverseClassPartComponents(threadData, _inClassPart, _inFunc, _inArg, out_outArg, &_outContinue);
if (out_outContinue) { *out_outContinue = mmc_mk_icon(_outContinue); }
return _outClassPart;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseListGeneric(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_boolean *out_outContinue)
{
modelica_metatype _outList = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _outArg = NULL;
modelica_boolean _outContinue;
modelica_boolean _eq;
modelica_boolean _changed;
modelica_metatype _e = NULL;
modelica_metatype _new_e = NULL;
modelica_metatype _rest_e = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outList = tmpMeta1;
_outArg = _inArg;
_outContinue = 1;
_changed = 0;
_rest_e = _inList;
while(1)
{
if(!(!listEmpty(_rest_e))) break;
tmpMeta2 = _rest_e;
if (listEmpty(tmpMeta2)) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_CAR(tmpMeta2);
tmpMeta4 = MMC_CDR(tmpMeta2);
_e = tmpMeta3;
_rest_e = tmpMeta4;
tmpMeta8 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), _e, _outArg, &tmpMeta5, &tmpMeta6) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, _e, _outArg, &tmpMeta5, &tmpMeta6);
_new_e = tmpMeta8;
tmp7 = mmc_unbox_integer(tmpMeta6);
_outArg = tmpMeta5;
_outContinue = tmp7;
_eq = referenceEq(_new_e, _e);
tmpMeta9 = mmc_mk_cons((_eq?_e:_new_e), _outList);
_outList = tmpMeta9;
_changed = (_changed || (!_eq));
if((!_outContinue))
{
break;
}
}
if(_changed)
{
_outList = omc_List_append__reverse(threadData, _outList, _rest_e);
}
else
{
_outList = _inList;
}
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
if (out_outContinue) { *out_outContinue = _outContinue; }
return _outList;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_traverseListGeneric(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg, modelica_metatype *out_outContinue)
{
modelica_boolean _outContinue;
modelica_metatype _outList = NULL;
modelica_metatype tmpMeta1;
_outList = omc_AbsynUtil_traverseListGeneric(threadData, _inList, _inFunc, _inArg, out_outArg, &_outContinue);
if (out_outContinue) { *out_outContinue = mmc_mk_icon(_outContinue); }
return _outList;
}
static modelica_metatype closure7_AbsynUtil_traverseClassPartComponents(threadData_t *thData, modelica_metatype closure, modelica_metatype inClassPart, modelica_metatype inArg, modelica_metatype tmp6, modelica_metatype tmp7)
{
modelica_fnptr inFunc = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_AbsynUtil_traverseClassPartComponents(thData, inClassPart, inFunc, inArg, tmp6, tmp7);
}
DLLExport
modelica_metatype omc_AbsynUtil_traverseClassComponents(threadData_t *threadData, modelica_metatype _inClass, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outClass = NULL;
modelica_metatype _outArg = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outClass = _inClass;
{
modelica_metatype tmp4_1;
tmp4_1 = _outClass;
{
modelica_metatype _body = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
tmpMeta8 = mmc_mk_box1(0, ((modelica_fnptr) _inFunc));
_body = omc_AbsynUtil_traverseClassDef(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outClass), 7))), (modelica_fnptr) mmc_mk_box2(0,closure7_AbsynUtil_traverseClassPartComponents,tmpMeta8), _inArg ,&_outArg, NULL);
if((!referenceEq(_body, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outClass), 7))))))
{
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_outClass), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[7] = _body;
_outClass = tmpMeta9;
}
tmpMeta1 = _outClass;
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
_outClass = tmpMeta1;
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outClass;
}
DLLExport
modelica_metatype omc_AbsynUtil_getElementItemsInClassPart(threadData_t *threadData, modelica_metatype _inClassPart)
{
modelica_metatype _outElements = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClassPart;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inClassPart), 2)));
goto tmp3_done;
}
case 4: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inClassPart), 2)));
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
modelica_metatype tmpMeta5;
tmpMeta5 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta5;
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
DLLExport
modelica_metatype omc_AbsynUtil_getElementItemsInClass(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_metatype _outElements = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
modelica_metatype _parts = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
_parts = tmpMeta7;
tmpMeta1 = omc_List_mapFlat(threadData, _parts, boxvar_AbsynUtil_getElementItemsInClassPart);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,4,5) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 5));
_parts = tmpMeta9;
tmpMeta1 = omc_List_mapFlat(threadData, _parts, boxvar_AbsynUtil_getElementItemsInClassPart);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta10;
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
DLLExport
modelica_metatype omc_AbsynUtil_getDefineUnitsInElements(threadData_t *threadData, modelica_metatype _elts)
{
modelica_metatype _outElts = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta10;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outElts = tmpMeta1;
{
modelica_metatype _i;
for (tmpMeta2 = _elts; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_i = MMC_CAR(tmpMeta2);
{
modelica_metatype tmp6_1;
tmp6_1 = _i;
{
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
for (; tmp6 < 2; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,1) == 0) goto tmp5_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,3) == 0) goto tmp5_end;
tmpMeta9 = mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_i), 2))), _outElts);
tmpMeta3 = tmpMeta9;
goto tmp5_done;
}
case 1: {
tmpMeta3 = _outElts;
goto tmp5_done;
}
}
goto tmp5_end;
tmp5_end: ;
}
goto goto_4;
goto_4:;
MMC_THROW_INTERNAL();
goto tmp5_done;
tmp5_done:;
}
}
_outElts = tmpMeta3;
}
}
_outElts = listReverseInPlace(_outElts);
_return: OMC_LABEL_UNUSED
return _outElts;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_dummyTraverseExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outArg = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outExp = _inExp;
_outArg = _inArg;
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outExp;
}
DLLExport
modelica_boolean omc_AbsynUtil_opIsElementWise(threadData_t *threadData, modelica_metatype _op)
{
modelica_boolean _isElementWise;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _op;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 10: {
tmp1 = 1;
goto tmp3_done;
}
case 11: {
tmp1 = 1;
goto tmp3_done;
}
case 12: {
tmp1 = 1;
goto tmp3_done;
}
case 13: {
tmp1 = 1;
goto tmp3_done;
}
case 14: {
tmp1 = 1;
goto tmp3_done;
}
case 15: {
tmp1 = 1;
goto tmp3_done;
}
case 16: {
tmp1 = 1;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
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
_isElementWise = tmp1;
_return: OMC_LABEL_UNUSED
return _isElementWise;
}
modelica_metatype boxptr_AbsynUtil_opIsElementWise(threadData_t *threadData, modelica_metatype _op)
{
modelica_boolean _isElementWise;
modelica_metatype out_isElementWise;
_isElementWise = omc_AbsynUtil_opIsElementWise(threadData, _op);
out_isElementWise = mmc_mk_icon(_isElementWise);
return out_isElementWise;
}
DLLExport
modelica_boolean omc_AbsynUtil_opEqual(threadData_t *threadData, modelica_metatype _op1, modelica_metatype _op2)
{
modelica_boolean _isEqual;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_isEqual = valueEq(_op1, _op2);
_return: OMC_LABEL_UNUSED
return _isEqual;
}
modelica_metatype boxptr_AbsynUtil_opEqual(threadData_t *threadData, modelica_metatype _op1, modelica_metatype _op2)
{
modelica_boolean _isEqual;
modelica_metatype out_isEqual;
_isEqual = omc_AbsynUtil_opEqual(threadData, _op1, _op2);
out_isEqual = mmc_mk_icon(_isEqual);
return out_isEqual;
}
DLLExport
modelica_metatype omc_AbsynUtil_mapCrefParts(threadData_t *threadData, modelica_metatype _inCref, modelica_fnptr _inMapFunc)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
modelica_string _name = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _rest_cref = NULL;
modelica_metatype _cref = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_name = tmpMeta5;
_subs = tmpMeta6;
_rest_cref = tmpMeta7;
tmpMeta8 = mmc_mk_box3(5, &Absyn_ComponentRef_CREF__IDENT__desc, _name, _subs);
_cref = tmpMeta8;
tmpMeta9 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inMapFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inMapFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inMapFunc), 2))), _cref) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inMapFunc), 1)))) (threadData, _cref);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,2,2) == 0) goto goto_2;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 3));
_name = tmpMeta10;
_subs = tmpMeta11;
_rest_cref = omc_AbsynUtil_mapCrefParts(threadData, _rest_cref, ((modelica_fnptr) _inMapFunc));
tmpMeta12 = mmc_mk_box4(4, &Absyn_ComponentRef_CREF__QUAL__desc, _name, _subs, _rest_cref);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cref = tmpMeta13;
_cref = omc_AbsynUtil_mapCrefParts(threadData, _cref, ((modelica_fnptr) _inMapFunc));
tmpMeta14 = mmc_mk_box2(3, &Absyn_ComponentRef_CREF__FULLYQUALIFIED__desc, _cref);
tmpMeta1 = tmpMeta14;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inMapFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inMapFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inMapFunc), 2))), _inCref) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inMapFunc), 1)))) (threadData, _inCref);
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_getNamedAnnotationStr(threadData_t *threadData, modelica_metatype _inAbsynElementArgLst, modelica_metatype _id, modelica_fnptr _f)
{
modelica_metatype _outString = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inAbsynElementArgLst;
tmp4_2 = _id;
{
modelica_metatype _str = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _xs = NULL;
modelica_string _id1 = NULL;
modelica_string _id2 = NULL;
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_boolean tmp12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,6) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,1,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
_id2 = tmpMeta6;
_id1 = tmpMeta10;
_mod = tmpMeta11;
tmp4 += 1;
tmp12 = (stringEqual(_id1, _id2));
if (1 != tmp12) goto goto_2;
_str = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_f), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_f), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_f), 2))), _mod) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_f), 1)))) (threadData, _mod);
tmpMeta1 = mmc_mk_some(_str);
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
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_boolean tmp22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta15 = MMC_CAR(tmp4_1);
tmpMeta16 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,0,6) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,1,1) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 2));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 5));
if (optionNone(tmpMeta19)) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 1));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 2));
_id2 = tmpMeta13;
_rest = tmpMeta14;
_id1 = tmpMeta18;
_xs = tmpMeta21;
tmp22 = (stringEqual(_id1, _id2));
if (1 != tmp22) goto goto_2;
tmpMeta1 = omc_AbsynUtil_getNamedAnnotationStr(threadData, _xs, _rest, ((modelica_fnptr) _f));
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta23 = MMC_CAR(tmp4_1);
tmpMeta24 = MMC_CDR(tmp4_1);
_xs = tmpMeta24;
tmpMeta1 = omc_AbsynUtil_getNamedAnnotationStr(threadData, _xs, _id, ((modelica_fnptr) _f));
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
_outString = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_metatype omc_AbsynUtil_getNamedAnnotationInClass(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _id, modelica_fnptr _f)
{
modelica_metatype _outString = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
modelica_metatype _annlst = NULL;
modelica_metatype _ann = NULL;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
_ann = tmpMeta7;
tmp4 += 4;
_annlst = omc_List_flatten(threadData, omc_List_map(threadData, _ann, boxvar_AbsynUtil_annotationToElementArgs));
tmpMeta1 = omc_AbsynUtil_getNamedAnnotationStr(threadData, _annlst, _id, ((modelica_fnptr) _f));
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,4,5) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 6));
_ann = tmpMeta9;
tmp4 += 3;
_annlst = omc_List_flatten(threadData, omc_List_map(threadData, _ann, boxvar_AbsynUtil_annotationToElementArgs));
tmpMeta1 = omc_AbsynUtil_getNamedAnnotationStr(threadData, _annlst, _id, ((modelica_fnptr) _f));
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,1,4) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 5));
if (optionNone(tmpMeta11)) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 1));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
if (optionNone(tmpMeta13)) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 1));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
_annlst = tmpMeta15;
tmp4 += 2;
tmpMeta1 = omc_AbsynUtil_getNamedAnnotationStr(threadData, _annlst, _id, ((modelica_fnptr) _f));
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,2,2) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 3));
if (optionNone(tmpMeta17)) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 1));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
if (optionNone(tmpMeta19)) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 1));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 2));
_annlst = tmpMeta21;
tmp4 += 1;
tmpMeta1 = omc_AbsynUtil_getNamedAnnotationStr(threadData, _annlst, _id, ((modelica_fnptr) _f));
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta22,3,2) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 3));
if (optionNone(tmpMeta23)) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 1));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 2));
if (optionNone(tmpMeta25)) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 1));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 2));
_annlst = tmpMeta27;
tmpMeta1 = omc_AbsynUtil_getNamedAnnotationStr(threadData, _annlst, _id, ((modelica_fnptr) _f));
goto tmp3_done;
}
case 5: {
tmpMeta1 = mmc_mk_none();
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
_outString = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_metatype omc_AbsynUtil_removeCrefFromCrefs(threadData_t *threadData, modelica_metatype _inAbsynComponentRefLst, modelica_metatype _inComponentRef)
{
modelica_metatype _outAbsynComponentRefLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inAbsynComponentRefLst;
tmp4_2 = _inComponentRef;
{
modelica_string _n1 = NULL;
modelica_string _n2 = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
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
modelica_boolean tmp15;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
_cr1 = tmpMeta7;
_rest = tmpMeta8;
_cr2 = tmp4_2;
tmpMeta9 = _cr1;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,2,2) == 0) goto goto_2;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 3));
if (!listEmpty(tmpMeta11)) goto goto_2;
_n1 = tmpMeta10;
tmpMeta12 = _cr2;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,2,2) == 0) goto goto_2;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 3));
if (!listEmpty(tmpMeta14)) goto goto_2;
_n2 = tmpMeta13;
tmp15 = (stringEqual(_n1, _n2));
if (1 != tmp15) goto goto_2;
tmpMeta1 = omc_AbsynUtil_removeCrefFromCrefs(threadData, _rest, _cr2);
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmp4_1);
tmpMeta17 = MMC_CDR(tmp4_1);
_cr1 = tmpMeta16;
_rest = tmpMeta17;
_cr2 = tmp4_2;
tmpMeta18 = _cr1;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,1,3) == 0) goto goto_2;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
_n1 = tmpMeta19;
tmpMeta20 = _cr2;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,2,2) == 0) goto goto_2;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 2));
_n2 = tmpMeta21;
tmp22 = (stringEqual(_n1, _n2));
if (1 != tmp22) goto goto_2;
tmpMeta1 = omc_AbsynUtil_removeCrefFromCrefs(threadData, _rest, _cr2);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta23 = MMC_CAR(tmp4_1);
tmpMeta24 = MMC_CDR(tmp4_1);
_cr1 = tmpMeta23;
_rest = tmpMeta24;
_cr2 = tmp4_2;
_rest = omc_AbsynUtil_removeCrefFromCrefs(threadData, _rest, _cr2);
tmpMeta25 = mmc_mk_cons(_cr1, _rest);
tmpMeta1 = tmpMeta25;
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
_outAbsynComponentRefLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynComponentRefLst;
}
DLLExport
modelica_metatype omc_AbsynUtil_getArrayDimOptAsList(threadData_t *threadData, modelica_metatype _inArrayDim)
{
modelica_metatype _outArrayDim = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inArrayDim;
{
modelica_metatype _ad = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_ad = tmpMeta6;
tmpMeta1 = _ad;
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
_outArrayDim = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outArrayDim;
}
DLLExport
modelica_string omc_AbsynUtil_refStringBrief(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_string _outStr = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inRef;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = omc_AbsynUtil_crefStringIgnoreSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inRef), 2))));
goto tmp3_done;
}
case 4: {
tmp1 = omc_AbsynUtil_typeSpecStringNoQualNoDims(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inRef), 2))));
goto tmp3_done;
}
case 5: {
tmp1 = omc_AbsynUtil_importString(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inRef), 2))));
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
modelica_string omc_AbsynUtil_refString(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_string _outStr = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inRef;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = omc_AbsynUtil_crefString(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inRef), 2))));
goto tmp3_done;
}
case 4: {
tmp1 = omc_AbsynUtil_typeSpecString(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inRef), 2))));
goto tmp3_done;
}
case 5: {
tmp1 = omc_AbsynUtil_importString(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inRef), 2))));
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
modelica_string omc_AbsynUtil_importString(threadData_t *threadData, modelica_metatype _inImp)
{
modelica_string _outStr = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outStr = omc_Dump_unparseImportStr(threadData, _inImp);
_return: OMC_LABEL_UNUSED
return _outStr;
}
DLLExport
modelica_string omc_AbsynUtil_crefStringIgnoreSubs(threadData_t *threadData, modelica_metatype _inCr)
{
modelica_string _outStr = NULL;
modelica_metatype _p = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_p = omc_AbsynUtil_crefToPathIgnoreSubs(threadData, _inCr);
_outStr = omc_AbsynUtil_pathString(threadData, omc_AbsynUtil_makeNotFullyQualified(threadData, _p), _OMC_LIT7, 1, 0);
_return: OMC_LABEL_UNUSED
return _outStr;
}
DLLExport
modelica_string omc_AbsynUtil_typeSpecStringNoQualNoDimsLst(threadData_t *threadData, modelica_metatype _inTypeSpecLst)
{
modelica_string _outString = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outString = omc_List_toString(threadData, _inTypeSpecLst, boxvar_AbsynUtil_typeSpecStringNoQualNoDims, _OMC_LIT12, _OMC_LIT12, _OMC_LIT13, _OMC_LIT12, 0, ((modelica_integer) 0));
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_AbsynUtil_typeSpecStringNoQualNoDims(threadData_t *threadData, modelica_metatype _inTs)
{
modelica_string _outStr = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inTs;
{
modelica_string _str1 = NULL;
modelica_string _str2 = NULL;
modelica_metatype _path = NULL;
modelica_metatype _typeSpecLst = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_path = tmpMeta6;
tmp1 = omc_AbsynUtil_pathString(threadData, omc_AbsynUtil_makeNotFullyQualified(threadData, _path), _OMC_LIT7, 1, 0);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_path = tmpMeta7;
_typeSpecLst = tmpMeta8;
_str1 = omc_AbsynUtil_pathString(threadData, omc_AbsynUtil_makeNotFullyQualified(threadData, _path), _OMC_LIT7, 1, 0);
_str2 = omc_AbsynUtil_typeSpecStringNoQualNoDimsLst(threadData, _typeSpecLst);
tmpMeta9 = mmc_mk_cons(_str1, mmc_mk_cons(_OMC_LIT14, mmc_mk_cons(_str2, mmc_mk_cons(_OMC_LIT15, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp1 = stringAppendList(tmpMeta9);
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
modelica_string omc_AbsynUtil_crefString(threadData_t *threadData, modelica_metatype _inCr)
{
modelica_string _outStr = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outStr = omc_Dump_printComponentRefStr(threadData, _inCr);
_return: OMC_LABEL_UNUSED
return _outStr;
}
DLLExport
modelica_string omc_AbsynUtil_typeSpecString(threadData_t *threadData, modelica_metatype _inTs)
{
modelica_string _outStr = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outStr = omc_Dump_unparseTypeSpec(threadData, _inTs);
_return: OMC_LABEL_UNUSED
return _outStr;
}
DLLExport
modelica_metatype omc_AbsynUtil_pathToTypeSpec(threadData_t *threadData, modelica_metatype _inPath)
{
modelica_metatype _outTypeSpec = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box3(3, &Absyn_TypeSpec_TPATH__desc, _inPath, mmc_mk_none());
_outTypeSpec = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outTypeSpec;
}
DLLExport
modelica_metatype omc_AbsynUtil_annotationToElementArgs(threadData_t *threadData, modelica_metatype _ann)
{
modelica_metatype _args = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _ann;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_args = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _args;
}
static modelica_metatype closure8_AbsynUtil_isModificationOfPath(threadData_t *thData, modelica_metatype closure, modelica_metatype mod)
{
modelica_metatype path = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_AbsynUtil_isModificationOfPath(thData, mod, path);
}
DLLExport
modelica_metatype omc_AbsynUtil_subModsInSameOrder(threadData_t *threadData, modelica_metatype _oldmod, modelica_metatype _newmod)
{
modelica_metatype _mod = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _oldmod;
tmp4_2 = _newmod;
{
modelica_metatype _args1 = NULL;
modelica_metatype _args2 = NULL;
modelica_metatype _res = NULL;
modelica_metatype _arg2 = NULL;
modelica_metatype _eq2 = NULL;
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,6) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
if (!optionNone(tmpMeta6)) goto tmp3_end;
tmpMeta1 = _newmod;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (!optionNone(tmpMeta7)) goto tmp3_end;
tmpMeta1 = _newmod;
goto tmp3_done;
}
case 2: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (optionNone(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 1));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,6) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
if (optionNone(tmpMeta11)) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 1));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 3));
_args1 = tmpMeta10;
_arg2 = tmp4_2;
_args2 = tmpMeta13;
_eq2 = tmpMeta14;
tmpMeta15 = MMC_REFSTRUCTLIT(mmc_nil);
_res = tmpMeta15;
{
modelica_metatype _arg1;
for (tmpMeta16 = _args1; !listEmpty(tmpMeta16); tmpMeta16=MMC_CDR(tmpMeta16))
{
_arg1 = MMC_CAR(tmpMeta16);
tmpMeta17 = _arg1;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,0,6) == 0) goto goto_2;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 4));
_p = tmpMeta18;
tmpMeta19 = mmc_mk_box1(0, _p);
if(omc_List_exist(threadData, _args2, (modelica_fnptr) mmc_mk_box2(0,closure8_AbsynUtil_isModificationOfPath,tmpMeta19)))
{
tmpMeta20 = mmc_mk_cons(_arg1, _res);
_res = tmpMeta20;
}
}
}
_res = listReverse(_res);
_res = omc_AbsynUtil_mergeAnnotations2(threadData, _res, _args2);
tmpMeta23 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _res, _eq2);
tmpMeta22 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta22), MMC_UNTAGPTR(_arg2), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta22))[5] = mmc_mk_some(tmpMeta23);
_arg2 = tmpMeta22;
tmpMeta1 = _arg2;
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
_mod = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _mod;
}
DLLExport
modelica_boolean omc_AbsynUtil_isModificationOfPath(threadData_t *threadData, modelica_metatype _mod, modelica_metatype _path)
{
modelica_boolean _yes;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _mod;
tmp4_2 = _path;
{
modelica_string _id1 = NULL;
modelica_string _id2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_id2 = tmpMeta6;
_id1 = tmpMeta8;
tmp1 = (stringEqual(_id1, _id2));
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
_yes = tmp1;
_return: OMC_LABEL_UNUSED
return _yes;
}
modelica_metatype boxptr_AbsynUtil_isModificationOfPath(threadData_t *threadData, modelica_metatype _mod, modelica_metatype _path)
{
modelica_boolean _yes;
modelica_metatype out_yes;
_yes = omc_AbsynUtil_isModificationOfPath(threadData, _mod, _path);
out_yes = mmc_mk_icon(_yes);
return out_yes;
}
DLLExport
modelica_metatype omc_AbsynUtil_mergeCommentAnnotation(threadData_t *threadData, modelica_metatype _inAnnotation, modelica_metatype _inComment)
{
modelica_metatype _outComment = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComment;
{
modelica_metatype _ann = NULL;
modelica_metatype _cmt = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (!optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = mmc_mk_box3(3, &Absyn_Comment_COMMENT__desc, mmc_mk_some(_inAnnotation), mmc_mk_none());
tmpMeta1 = mmc_mk_some(tmpMeta6);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (!optionNone(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
_cmt = tmpMeta9;
tmpMeta10 = mmc_mk_box3(3, &Absyn_Comment_COMMENT__desc, mmc_mk_some(_inAnnotation), _cmt);
tmpMeta1 = mmc_mk_some(tmpMeta10);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
if (optionNone(tmpMeta12)) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 1));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 3));
_ann = tmpMeta13;
_cmt = tmpMeta14;
tmpMeta15 = mmc_mk_box3(3, &Absyn_Comment_COMMENT__desc, mmc_mk_some(omc_AbsynUtil_mergeAnnotations(threadData, _ann, _inAnnotation)), _cmt);
tmpMeta1 = mmc_mk_some(tmpMeta15);
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
_outComment = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComment;
}
static modelica_metatype closure9_AbsynUtil_isModificationOfPath(threadData_t *thData, modelica_metatype closure, modelica_metatype mod)
{
modelica_metatype path = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_AbsynUtil_isModificationOfPath(thData, mod, path);
}static modelica_metatype closure10_AbsynUtil_isModificationOfPath(threadData_t *thData, modelica_metatype closure, modelica_metatype mod)
{
modelica_metatype path = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_AbsynUtil_isModificationOfPath(thData, mod, path);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_mergeAnnotations2(threadData_t *threadData, modelica_metatype _oldmods, modelica_metatype _newmods)
{
modelica_metatype _res = NULL;
modelica_metatype _mods = NULL;
modelica_boolean _b;
modelica_metatype _p = NULL;
modelica_metatype _mod1 = NULL;
modelica_metatype _mod2 = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta13;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = listReverse(_oldmods);
{
modelica_metatype _mod;
for (tmpMeta1 = _newmods; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_mod = MMC_CAR(tmpMeta1);
tmpMeta2 = _mod;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta2,0,6) == 0) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 4));
_p = tmpMeta3;
{
{
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp5_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp6 < 2; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
modelica_metatype tmpMeta8;
modelica_boolean tmp9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
tmpMeta8 = mmc_mk_box1(0, _p);
_mod2 = omc_List_find(threadData, _res, (modelica_fnptr) mmc_mk_box2(0,closure9_AbsynUtil_isModificationOfPath,tmpMeta8));
_mod1 = omc_AbsynUtil_subModsInSameOrder(threadData, _mod2, _mod);
tmpMeta10 = mmc_mk_box1(0, _p);
tmpMeta11 = omc_List_replaceOnTrue(threadData, _mod1, _res, (modelica_fnptr) mmc_mk_box2(0,closure10_AbsynUtil_isModificationOfPath,tmpMeta10), &tmp9);
_res = tmpMeta11;
if (1 != tmp9) goto goto_4;
goto tmp5_done;
}
case 1: {
modelica_metatype tmpMeta12;
tmpMeta12 = mmc_mk_cons(_mod, _res);
_res = tmpMeta12;
goto tmp5_done;
}
}
goto tmp5_end;
tmp5_end: ;
}
goto goto_4;
tmp5_done:
(void)tmp6;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp5_done2;
goto_4:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp6 < 2) {
goto tmp5_top;
}
MMC_THROW_INTERNAL();
tmp5_done2:;
}
}
;
}
}
_res = listReverse(_res);
_return: OMC_LABEL_UNUSED
return _res;
}
DLLExport
modelica_metatype omc_AbsynUtil_mergeAnnotations(threadData_t *threadData, modelica_metatype _inAnnotation1, modelica_metatype _inAnnotation2)
{
modelica_metatype _outAnnotation = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inAnnotation1;
tmp4_2 = _inAnnotation2;
{
modelica_metatype _oldmods = NULL;
modelica_metatype _newmods = NULL;
modelica_metatype _a = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
_a = tmp4_2;
tmpMeta1 = _a;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_oldmods = tmpMeta7;
_newmods = tmpMeta8;
tmpMeta9 = mmc_mk_box2(3, &Absyn_Annotation_ANNOTATION__desc, omc_AbsynUtil_mergeAnnotations2(threadData, _oldmods, _newmods));
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
_outAnnotation = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAnnotation;
}
DLLExport
modelica_string omc_AbsynUtil_importName(threadData_t *threadData, modelica_metatype _inImport)
{
modelica_string _outName = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inImport;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmp1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inImport), 2)));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmp1 = omc_AbsynUtil_pathLastIdent(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inImport), 2))));
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
_outName = tmp1;
_return: OMC_LABEL_UNUSED
return _outName;
}
DLLExport
modelica_metatype omc_AbsynUtil_importPath(threadData_t *threadData, modelica_metatype _inImport)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inImport;
{
modelica_metatype _path = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_path = tmpMeta5;
tmpMeta1 = _path;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_path = tmpMeta6;
tmpMeta1 = _path;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_path = tmpMeta7;
tmpMeta1 = _path;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_path = tmpMeta8;
tmpMeta1 = _path;
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
modelica_boolean omc_AbsynUtil_isInitial(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_boolean _hasReinit;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,2,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (7 != MMC_STRLEN(tmpMeta7) || strcmp(MMC_STRINGDATA(_OMC_LIT16), MMC_STRINGDATA(tmpMeta7)) != 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,2,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (7 != MMC_STRLEN(tmpMeta10) || strcmp(MMC_STRINGDATA(_OMC_LIT16), MMC_STRINGDATA(tmpMeta10)) != 0) goto tmp3_end;
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
_hasReinit = tmp1;
_return: OMC_LABEL_UNUSED
return _hasReinit;
}
modelica_metatype boxptr_AbsynUtil_isInitial(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_boolean _hasReinit;
modelica_metatype out_hasReinit;
_hasReinit = omc_AbsynUtil_isInitial(threadData, _inExp);
out_hasReinit = mmc_mk_icon(_hasReinit);
return out_hasReinit;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_isInitialTraverseHelper(threadData_t *threadData, modelica_metatype _inExp, modelica_boolean _inBool, modelica_boolean *out_outBool)
{
modelica_metatype _outExp = NULL;
modelica_boolean _outBool;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _e = NULL;
modelica_boolean _b;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,16,0) == 0) goto tmp3_end;
tmpMeta[0+0] = _inExp;
tmp1_c1 = _inBool;
goto tmp3_done;
}
case 1: {
_e = tmp4_1;
_b = omc_AbsynUtil_isInitial(threadData, _e);
tmpMeta[0+0] = _e;
tmp1_c1 = _b;
goto tmp3_done;
}
case 2: {
tmpMeta[0+0] = _inExp;
tmp1_c1 = _inBool;
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
_outBool = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_outBool) { *out_outBool = _outBool; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_isInitialTraverseHelper(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inBool, modelica_metatype *out_outBool)
{
modelica_integer tmp1;
modelica_boolean _outBool;
modelica_metatype _outExp = NULL;
tmp1 = mmc_unbox_integer(_inBool);
_outExp = omc_AbsynUtil_isInitialTraverseHelper(threadData, _inExp, tmp1, &_outBool);
if (out_outBool) { *out_outBool = mmc_mk_icon(_outBool); }
return _outExp;
}
DLLExport
modelica_boolean omc_AbsynUtil_expContainsInitial(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_boolean _hasInitial;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_boolean _b;
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
omc_AbsynUtil_traverseExp(threadData, _inExp, boxvar_AbsynUtil_isInitialTraverseHelper, mmc_mk_boolean(0), &tmpMeta6);
tmp7 = mmc_unbox_integer(tmpMeta6);
_b = tmp7;
tmp1 = _b;
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
_hasInitial = tmp1;
_return: OMC_LABEL_UNUSED
return _hasInitial;
}
modelica_metatype boxptr_AbsynUtil_expContainsInitial(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_boolean _hasInitial;
modelica_metatype out_hasInitial;
_hasInitial = omc_AbsynUtil_expContainsInitial(threadData, _inExp);
out_hasInitial = mmc_mk_icon(_hasInitial);
return out_hasInitial;
}
DLLExport
modelica_string omc_AbsynUtil_componentName(threadData_t *threadData, modelica_metatype _c)
{
modelica_string _name = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _c;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 2));
_name = tmpMeta3;
_return: OMC_LABEL_UNUSED
return _name;
}
DLLExport
modelica_metatype omc_AbsynUtil_makeClassElement(threadData_t *threadData, modelica_metatype _cl)
{
modelica_metatype _el = NULL;
modelica_metatype _info = NULL;
modelica_boolean _fp;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _cl;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
tmp3 = mmc_unbox_integer(tmpMeta2);
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 10));
_fp = tmp3;
_info = tmpMeta4;
tmpMeta5 = mmc_mk_box3(3, &Absyn_ElementSpec_CLASSDEF__desc, mmc_mk_boolean(0), _cl);
tmpMeta6 = mmc_mk_box7(3, &Absyn_Element_ELEMENT__desc, mmc_mk_boolean(_fp), mmc_mk_none(), _OMC_LIT17, tmpMeta5, _info, mmc_mk_none());
tmpMeta7 = mmc_mk_box2(3, &Absyn_ElementItem_ELEMENTITEM__desc, tmpMeta6);
_el = tmpMeta7;
_return: OMC_LABEL_UNUSED
return _el;
}
DLLExport
modelica_boolean omc_AbsynUtil_isParts(threadData_t *threadData, modelica_metatype _cl)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cl;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
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
modelica_metatype boxptr_AbsynUtil_isParts(threadData_t *threadData, modelica_metatype _cl)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_AbsynUtil_isParts(threadData, _cl);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_AbsynUtil_isExternalPart(threadData_t *threadData, modelica_metatype _inClassPart)
{
modelica_boolean _outFound;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClassPart;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,2) == 0) goto tmp3_end;
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
_outFound = tmp1;
_return: OMC_LABEL_UNUSED
return _outFound;
}
modelica_metatype boxptr_AbsynUtil_isExternalPart(threadData_t *threadData, modelica_metatype _inClassPart)
{
modelica_boolean _outFound;
modelica_metatype out_outFound;
_outFound = omc_AbsynUtil_isExternalPart(threadData, _inClassPart);
out_outFound = mmc_mk_icon(_outFound);
return out_outFound;
}
DLLExport
modelica_metatype omc_AbsynUtil_getExternalDecl(threadData_t *threadData, modelica_metatype _inCls)
{
modelica_metatype _outExternal = NULL;
modelica_metatype _cp = NULL;
modelica_metatype _class_parts = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inCls;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta2,0,5) == 0) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 4));
_class_parts = tmpMeta3;
_outExternal = omc_List_find(threadData, _class_parts, boxvar_AbsynUtil_isExternalPart);
_return: OMC_LABEL_UNUSED
return _outExternal;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_filterNestedClassesParts(threadData_t *threadData, modelica_metatype _classPart, modelica_metatype _inClassParts)
{
modelica_metatype _outClassPart = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _classPart;
tmp4_2 = _inClassParts;
{
modelica_metatype _classParts = NULL;
modelica_metatype _elts = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_elts = tmpMeta5;
_classParts = tmp4_2;
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_classPart), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[2] = omc_List_filterOnFalse(threadData, _elts, boxvar_AbsynUtil_isElementItemClass);
_classPart = tmpMeta6;
tmpMeta7 = mmc_mk_cons(_classPart, _classParts);
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_elts = tmpMeta8;
_classParts = tmp4_2;
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_classPart), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[2] = omc_List_filterOnFalse(threadData, _elts, boxvar_AbsynUtil_isElementItemClass);
_classPart = tmpMeta9;
tmpMeta10 = mmc_mk_cons(_classPart, _classParts);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
modelica_metatype tmpMeta11;
tmpMeta11 = mmc_mk_cons(_classPart, _inClassParts);
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
_outClassPart = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outClassPart;
}
DLLExport
modelica_metatype omc_AbsynUtil_filterNestedClasses(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcl)
{
modelica_metatype _cl = NULL;
modelica_metatype _def = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cl = __omcQ_24in_5Fcl;
{
modelica_metatype tmp3_1;
tmp3_1 = _cl;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta5,0,5) == 0) goto tmp2_end;
_def = tmpMeta5;
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_def), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[4] = omc_List_fold(threadData, listReverse((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_def), 4)))), boxvar_AbsynUtil_filterNestedClassesParts, tmpMeta7);
_def = tmpMeta6;
tmpMeta8 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta8), MMC_UNTAGPTR(_cl), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta8))[7] = _def;
_cl = tmpMeta8;
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
return _cl;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_AbsynUtil_filterAnnotationItem(threadData_t *threadData, modelica_metatype _elt)
{
modelica_boolean _outB;
modelica_boolean tmp1 = 0;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
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
_outB = tmp1;
_return: OMC_LABEL_UNUSED
return _outB;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_filterAnnotationItem(threadData_t *threadData, modelica_metatype _elt)
{
modelica_boolean _outB;
modelica_metatype out_outB;
_outB = omc_AbsynUtil_filterAnnotationItem(threadData, _elt);
out_outB = mmc_mk_icon(_outB);
return out_outB;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_getFunctionInterfaceParts(threadData_t *threadData, modelica_metatype _part, modelica_metatype _elts)
{
modelica_metatype _oelts = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _part;
tmp4_2 = _elts;
{
modelica_metatype _elts1 = NULL;
modelica_metatype _elts2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_elts1 = tmpMeta6;
_elts2 = tmp4_2;
_elts1 = omc_List_filterOnTrue(threadData, _elts1, boxvar_AbsynUtil_filterAnnotationItem);
tmpMeta1 = listAppend(_elts1, _elts2);
goto tmp3_done;
}
case 1: {
tmpMeta1 = _elts;
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
_oelts = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _oelts;
}
DLLExport
modelica_metatype omc_AbsynUtil_getFunctionInterface(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcl)
{
modelica_metatype _cl = NULL;
modelica_metatype _def = NULL;
modelica_metatype _elts = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cl = __omcQ_24in_5Fcl;
{
modelica_metatype tmp3_1;
tmp3_1 = _cl;
{
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
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta5,9,1) == 0) goto tmp2_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,5) == 0) goto tmp2_end;
_def = tmpMeta6;
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta8 = omc_List_fold(threadData, listReverse((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_def), 4)))), boxvar_AbsynUtil_getFunctionInterfaceParts, tmpMeta7);
if (listEmpty(tmpMeta8)) goto goto_1;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
_elts = tmpMeta8;
tmpMeta13 = mmc_mk_box2(3, &Absyn_ClassPart_PUBLIC__desc, _elts);
tmpMeta12 = mmc_mk_cons(tmpMeta13, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta14 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta15 = mmc_mk_box6(3, &Absyn_ClassDef_PARTS__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_def), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_def), 3))), tmpMeta12, tmpMeta14, mmc_mk_none());
tmpMeta11 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta11), MMC_UNTAGPTR(_cl), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta11))[7] = tmpMeta15;
_cl = tmpMeta11;
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
return _cl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_stripClassDefComment(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcl)
{
modelica_metatype _cl = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cl = __omcQ_24in_5Fcl;
{
modelica_metatype tmp3_1;
tmp3_1 = _cl;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
modelica_metatype tmpMeta4;
tmpMeta4 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta4), MMC_UNTAGPTR(_cl), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta4))[6] = mmc_mk_none();
_cl = tmpMeta4;
goto tmp2_done;
}
case 4: {
modelica_metatype tmpMeta5;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_cl), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[5] = mmc_mk_none();
_cl = tmpMeta5;
goto tmp2_done;
}
case 5: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_cl), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[3] = mmc_mk_none();
_cl = tmpMeta6;
goto tmp2_done;
}
case 6: {
modelica_metatype tmpMeta7;
tmpMeta7 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta7), MMC_UNTAGPTR(_cl), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta7))[3] = mmc_mk_none();
_cl = tmpMeta7;
goto tmp2_done;
}
case 7: {
modelica_metatype tmpMeta8;
tmpMeta8 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta8), MMC_UNTAGPTR(_cl), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta8))[4] = mmc_mk_none();
_cl = tmpMeta8;
goto tmp2_done;
}
case 8: {
modelica_metatype tmpMeta9;
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_cl), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[4] = mmc_mk_none();
_cl = tmpMeta9;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
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
return _cl;
}
DLLExport
modelica_metatype omc_AbsynUtil_getShortClass(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcl)
{
modelica_metatype _cl = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cl = __omcQ_24in_5Fcl;
{
modelica_metatype tmp3_1;
tmp3_1 = _cl;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta5,0,5) == 0) goto tmp2_end;
goto goto_1;
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,4,5) == 0) goto tmp2_end;
goto goto_1;
goto tmp2_done;
}
case 2: {
modelica_metatype tmpMeta7;
tmpMeta7 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta7), MMC_UNTAGPTR(_cl), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta7))[7] = omc_AbsynUtil_stripClassDefComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cl), 7))));
_cl = tmpMeta7;
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
return _cl;
}
DLLExport
modelica_boolean omc_AbsynUtil_pathGe(threadData_t *threadData, modelica_metatype _path1, modelica_metatype _path2)
{
modelica_boolean _ge;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ge = (!omc_AbsynUtil_pathLt(threadData, _path1, _path2));
_return: OMC_LABEL_UNUSED
return _ge;
}
modelica_metatype boxptr_AbsynUtil_pathGe(threadData_t *threadData, modelica_metatype _path1, modelica_metatype _path2)
{
modelica_boolean _ge;
modelica_metatype out_ge;
_ge = omc_AbsynUtil_pathGe(threadData, _path1, _path2);
out_ge = mmc_mk_icon(_ge);
return out_ge;
}
DLLExport
modelica_boolean omc_AbsynUtil_pathLt(threadData_t *threadData, modelica_metatype _path1, modelica_metatype _path2)
{
modelica_boolean _lt;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_lt = (stringCompare(omc_AbsynUtil_pathString(threadData, _path1, _OMC_LIT7, 1, 0), omc_AbsynUtil_pathString(threadData, _path2, _OMC_LIT7, 1, 0)) < ((modelica_integer) 0));
_return: OMC_LABEL_UNUSED
return _lt;
}
modelica_metatype boxptr_AbsynUtil_pathLt(threadData_t *threadData, modelica_metatype _path1, modelica_metatype _path2)
{
modelica_boolean _lt;
modelica_metatype out_lt;
_lt = omc_AbsynUtil_pathLt(threadData, _path1, _path2);
out_lt = mmc_mk_icon(_lt);
return out_lt;
}
DLLExport
modelica_boolean omc_AbsynUtil_isFieldEqual(threadData_t *threadData, modelica_metatype _isField1, modelica_metatype _isField2)
{
modelica_boolean _outEqual;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _isField1;
tmp4_2 = _isField2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
tmp1 = 1;
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
_outEqual = tmp1;
_return: OMC_LABEL_UNUSED
return _outEqual;
}
modelica_metatype boxptr_AbsynUtil_isFieldEqual(threadData_t *threadData, modelica_metatype _isField1, modelica_metatype _isField2)
{
modelica_boolean _outEqual;
modelica_metatype out_outEqual;
_outEqual = omc_AbsynUtil_isFieldEqual(threadData, _isField1, _isField2);
out_outEqual = mmc_mk_icon(_outEqual);
return out_outEqual;
}
DLLExport
modelica_boolean omc_AbsynUtil_directionEqual(threadData_t *threadData, modelica_metatype _inDirection1, modelica_metatype _inDirection2)
{
modelica_boolean _outEqual;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inDirection1;
tmp4_2 = _inDirection2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,0) == 0) goto tmp3_end;
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
_outEqual = tmp1;
_return: OMC_LABEL_UNUSED
return _outEqual;
}
modelica_metatype boxptr_AbsynUtil_directionEqual(threadData_t *threadData, modelica_metatype _inDirection1, modelica_metatype _inDirection2)
{
modelica_boolean _outEqual;
modelica_metatype out_outEqual;
_outEqual = omc_AbsynUtil_directionEqual(threadData, _inDirection1, _inDirection2);
out_outEqual = mmc_mk_icon(_outEqual);
return out_outEqual;
}
DLLExport
modelica_boolean omc_AbsynUtil_isOutput(threadData_t *threadData, modelica_metatype _inDirection)
{
modelica_boolean _outIsOutput;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inDirection;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
tmp1 = 1;
goto tmp3_done;
}
case 6: {
tmp1 = 1;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
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
_outIsOutput = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsOutput;
}
modelica_metatype boxptr_AbsynUtil_isOutput(threadData_t *threadData, modelica_metatype _inDirection)
{
modelica_boolean _outIsOutput;
modelica_metatype out_outIsOutput;
_outIsOutput = omc_AbsynUtil_isOutput(threadData, _inDirection);
out_outIsOutput = mmc_mk_icon(_outIsOutput);
return out_outIsOutput;
}
DLLExport
modelica_boolean omc_AbsynUtil_isInput(threadData_t *threadData, modelica_metatype _inDirection)
{
modelica_boolean _outIsInput;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inDirection;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = 1;
goto tmp3_done;
}
case 6: {
tmp1 = 1;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
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
_outIsInput = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsInput;
}
modelica_metatype boxptr_AbsynUtil_isInput(threadData_t *threadData, modelica_metatype _inDirection)
{
modelica_boolean _outIsInput;
modelica_metatype out_outIsInput;
_outIsInput = omc_AbsynUtil_isInput(threadData, _inDirection);
out_outIsInput = mmc_mk_icon(_outIsInput);
return out_outIsInput;
}
DLLExport
modelica_boolean omc_AbsynUtil_isInputOrOutput(threadData_t *threadData, modelica_metatype _direction)
{
modelica_boolean _isIorO;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _direction;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = 1;
goto tmp3_done;
}
case 4: {
tmp1 = 1;
goto tmp3_done;
}
case 6: {
tmp1 = 1;
goto tmp3_done;
}
case 5: {
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
_isIorO = tmp1;
_return: OMC_LABEL_UNUSED
return _isIorO;
}
modelica_metatype boxptr_AbsynUtil_isInputOrOutput(threadData_t *threadData, modelica_metatype _direction)
{
modelica_boolean _isIorO;
modelica_metatype out_isIorO;
_isIorO = omc_AbsynUtil_isInputOrOutput(threadData, _direction);
out_isIorO = mmc_mk_icon(_isIorO);
return out_isIorO;
}
DLLExport
modelica_boolean omc_AbsynUtil_getExpsFromArrayDim__tail(threadData_t *threadData, modelica_metatype _inAd, modelica_metatype _inAccumulator, modelica_metatype *out_outExps)
{
modelica_boolean _hasUnknownDimensions;
modelica_metatype _outExps = NULL;
modelica_boolean tmp1_c0 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inAd;
tmp4_2 = _inAccumulator;
{
modelica_metatype _rest = NULL;
modelica_metatype _e = NULL;
modelica_metatype _exps = NULL;
modelica_metatype _acc = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_acc = tmp4_2;
tmp1_c0 = 0;
tmpMeta[0+1] = listReverse(_acc);
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
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_e = tmpMeta8;
_rest = tmpMeta7;
_acc = tmp4_2;
tmpMeta9 = mmc_mk_cons(_e, _acc);
_inAd = _rest;
_inAccumulator = tmpMeta9;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,0,0) == 0) goto tmp3_end;
_rest = tmpMeta11;
_acc = tmp4_2;
omc_AbsynUtil_getExpsFromArrayDim__tail(threadData, _rest, _acc ,&_exps);
tmp1_c0 = 1;
tmpMeta[0+1] = _exps;
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
_hasUnknownDimensions = tmp1_c0;
_outExps = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outExps) { *out_outExps = _outExps; }
return _hasUnknownDimensions;
}
modelica_metatype boxptr_AbsynUtil_getExpsFromArrayDim__tail(threadData_t *threadData, modelica_metatype _inAd, modelica_metatype _inAccumulator, modelica_metatype *out_outExps)
{
modelica_boolean _hasUnknownDimensions;
modelica_metatype out_hasUnknownDimensions;
_hasUnknownDimensions = omc_AbsynUtil_getExpsFromArrayDim__tail(threadData, _inAd, _inAccumulator, out_outExps);
out_hasUnknownDimensions = mmc_mk_icon(_hasUnknownDimensions);
return out_hasUnknownDimensions;
}
DLLExport
modelica_boolean omc_AbsynUtil_getExpsFromArrayDimOpt(threadData_t *threadData, modelica_metatype _inAdO, modelica_metatype *out_outExps)
{
modelica_boolean _hasUnknownDimensions;
modelica_metatype _outExps = NULL;
modelica_boolean tmp1_c0 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAdO;
{
modelica_metatype _ad = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (!optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmp1_c0 = 0;
tmpMeta[0+1] = tmpMeta6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_ad = tmpMeta7;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
tmp1_c0 = omc_AbsynUtil_getExpsFromArrayDim__tail(threadData, _ad, tmpMeta8, &tmpMeta[0+1]);
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
_hasUnknownDimensions = tmp1_c0;
_outExps = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outExps) { *out_outExps = _outExps; }
return _hasUnknownDimensions;
}
modelica_metatype boxptr_AbsynUtil_getExpsFromArrayDimOpt(threadData_t *threadData, modelica_metatype _inAdO, modelica_metatype *out_outExps)
{
modelica_boolean _hasUnknownDimensions;
modelica_metatype out_hasUnknownDimensions;
_hasUnknownDimensions = omc_AbsynUtil_getExpsFromArrayDimOpt(threadData, _inAdO, out_outExps);
out_hasUnknownDimensions = mmc_mk_icon(_hasUnknownDimensions);
return out_hasUnknownDimensions;
}
DLLExport
modelica_boolean omc_AbsynUtil_getExpsFromArrayDim(threadData_t *threadData, modelica_metatype _inAd, modelica_metatype *out_outExps)
{
modelica_boolean _hasUnknownDimensions;
modelica_metatype _outExps = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_hasUnknownDimensions = omc_AbsynUtil_getExpsFromArrayDim__tail(threadData, _inAd, tmpMeta1 ,&_outExps);
_return: OMC_LABEL_UNUSED
if (out_outExps) { *out_outExps = _outExps; }
return _hasUnknownDimensions;
}
modelica_metatype boxptr_AbsynUtil_getExpsFromArrayDim(threadData_t *threadData, modelica_metatype _inAd, modelica_metatype *out_outExps)
{
modelica_boolean _hasUnknownDimensions;
modelica_metatype out_hasUnknownDimensions;
_hasUnknownDimensions = omc_AbsynUtil_getExpsFromArrayDim(threadData, _inAd, out_outExps);
out_hasUnknownDimensions = mmc_mk_icon(_hasUnknownDimensions);
return out_hasUnknownDimensions;
}
DLLExport
void omc_AbsynUtil_isDerCrefFail(threadData_t *threadData, modelica_metatype _exp)
{
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _exp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,11,3) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta2,2,2) == 0) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 2));
if (3 != MMC_STRLEN(tmpMeta3) || strcmp("der", MMC_STRINGDATA(tmpMeta3)) != 0) MMC_THROW_INTERNAL();
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 3));
if (!listEmpty(tmpMeta4)) MMC_THROW_INTERNAL();
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta5,0,2) == 0) MMC_THROW_INTERNAL();
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 2));
if (listEmpty(tmpMeta6)) MMC_THROW_INTERNAL();
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,2,1) == 0) MMC_THROW_INTERNAL();
if (!listEmpty(tmpMeta8)) MMC_THROW_INTERNAL();
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 3));
if (!listEmpty(tmpMeta9)) MMC_THROW_INTERNAL();
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_boolean omc_AbsynUtil_isDerCref(threadData_t *threadData, modelica_metatype _exp)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _exp;
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
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,2,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (3 != MMC_STRLEN(tmpMeta7) || strcmp(MMC_STRINGDATA(_OMC_LIT18), MMC_STRINGDATA(tmpMeta7)) != 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
if (!listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,0,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (listEmpty(tmpMeta10)) goto tmp3_end;
tmpMeta11 = MMC_CAR(tmpMeta10);
tmpMeta12 = MMC_CDR(tmpMeta10);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,2,1) == 0) goto tmp3_end;
if (!listEmpty(tmpMeta12)) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 3));
if (!listEmpty(tmpMeta13)) goto tmp3_end;
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
modelica_metatype boxptr_AbsynUtil_isDerCref(threadData_t *threadData, modelica_metatype _exp)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_AbsynUtil_isDerCref(threadData, _exp);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_AbsynUtil_complexIsCref(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 19: {
tmp1 = omc_AbsynUtil_allFieldsAreCrefs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inExp), 2))));
goto tmp3_done;
}
case 23: {
tmp1 = (omc_AbsynUtil_complexIsCref(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inExp), 2)))) && omc_AbsynUtil_complexIsCref(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inExp), 3)))));
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmp1 = omc_AbsynUtil_isCref(threadData, _inExp);
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
modelica_metatype boxptr_AbsynUtil_complexIsCref(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_AbsynUtil_complexIsCref(threadData, _inExp);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_AbsynUtil_allFieldsAreCrefs(threadData_t *threadData, modelica_metatype _expLst)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_List_mapAllValueBool(threadData, _expLst, boxvar_AbsynUtil_complexIsCref, mmc_mk_boolean(1));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_AbsynUtil_allFieldsAreCrefs(threadData_t *threadData, modelica_metatype _expLst)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_AbsynUtil_allFieldsAreCrefs(threadData, _expLst);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_AbsynUtil_isTuple(threadData_t *threadData, modelica_metatype _exp)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _exp;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,1) == 0) goto tmp3_end;
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
modelica_metatype boxptr_AbsynUtil_isTuple(threadData_t *threadData, modelica_metatype _exp)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_AbsynUtil_isTuple(threadData, _exp);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_AbsynUtil_isCref(threadData_t *threadData, modelica_metatype _exp)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _exp;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
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
modelica_metatype boxptr_AbsynUtil_isCref(threadData_t *threadData, modelica_metatype _exp)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_AbsynUtil_isCref(threadData, _exp);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_metatype omc_AbsynUtil_crefInsertSubscriptLstLst2(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inSubs)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inCref;
tmp4_2 = _inSubs;
{
modelica_metatype _cref = NULL;
modelica_metatype _cref2 = NULL;
modelica_string _n = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _s = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
_cref = tmp4_1;
tmp4 += 2;
tmpMeta1 = _cref;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_2);
tmpMeta8 = MMC_CDR(tmp4_2);
if (!listEmpty(tmpMeta8)) goto tmp3_end;
_n = tmpMeta6;
_s = tmpMeta7;
tmp4 += 2;
tmpMeta9 = mmc_mk_box3(5, &Absyn_ComponentRef_CREF__IDENT__desc, _n, _s);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmp4_2);
tmpMeta13 = MMC_CDR(tmp4_2);
_n = tmpMeta10;
_cref = tmpMeta11;
_s = tmpMeta12;
_subs = tmpMeta13;
tmp4 += 1;
_cref2 = omc_AbsynUtil_crefInsertSubscriptLstLst2(threadData, _cref, _subs);
tmpMeta14 = mmc_mk_box4(4, &Absyn_ComponentRef_CREF__QUAL__desc, _n, _s, _cref2);
tmpMeta1 = tmpMeta14;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cref = tmpMeta15;
_subs = tmp4_2;
_cref2 = omc_AbsynUtil_crefInsertSubscriptLstLst2(threadData, _cref, _subs);
tmpMeta1 = omc_AbsynUtil_crefMakeFullyQualified(threadData, _cref2);
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
_outCref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_metatype omc_AbsynUtil_crefInsertSubscriptLstLst(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inLst, modelica_metatype *out_outLst)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outLst = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _inLst;
{
modelica_metatype _cref = NULL;
modelica_metatype _cref2 = NULL;
modelica_metatype _subs = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cref = tmpMeta6;
_subs = tmp4_2;
_cref2 = omc_AbsynUtil_crefInsertSubscriptLstLst2(threadData, _cref, _subs);
tmpMeta7 = mmc_mk_box2(5, &Absyn_Exp_CREF__desc, _cref2);
tmpMeta[0+0] = tmpMeta7;
tmpMeta[0+1] = _subs;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inLst;
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
_outExp = tmpMeta[0+0];
_outLst = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outLst) { *out_outLst = _outLst; }
return _outExp;
}
DLLExport
modelica_metatype omc_AbsynUtil_subscriptExpOpt(threadData_t *threadData, modelica_metatype _inSub)
{
modelica_metatype _outExpOpt = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inSub;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta1 = mmc_mk_some((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inSub), 2))));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
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
_outExpOpt = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExpOpt;
}
DLLExport
modelica_string omc_AbsynUtil_innerOuterStr(threadData_t *threadData, modelica_metatype _io)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _io;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
tmp1 = _OMC_LIT19;
goto tmp3_done;
}
case 3: {
tmp1 = _OMC_LIT20;
goto tmp3_done;
}
case 4: {
tmp1 = _OMC_LIT21;
goto tmp3_done;
}
case 6: {
tmp1 = _OMC_LIT12;
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
modelica_metatype omc_AbsynUtil_joinWithinPath(threadData_t *threadData, modelica_metatype _within_, modelica_metatype _path)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _within_;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
tmpMeta1 = _path;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta1 = omc_AbsynUtil_joinPaths(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_within_), 2))), _path);
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
modelica_string omc_AbsynUtil_withinString(threadData_t *threadData, modelica_metatype _w1)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _w1;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT22;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta6 = stringAppend(_OMC_LIT23,omc_AbsynUtil_pathString(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_w1), 2))), _OMC_LIT7, 1, 0));
tmpMeta7 = stringAppend(tmpMeta6,_OMC_LIT24);
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
_str = tmp1;
_return: OMC_LABEL_UNUSED
return _str;
}
DLLExport
modelica_boolean omc_AbsynUtil_withinEqualCaseInsensitive(threadData_t *threadData, modelica_metatype _within1, modelica_metatype _within2)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _within1;
tmp4_2 = _within2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmp1 = omc_AbsynUtil_pathEqualCaseInsensitive(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_within1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_within2), 2))));
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
modelica_metatype boxptr_AbsynUtil_withinEqualCaseInsensitive(threadData_t *threadData, modelica_metatype _within1, modelica_metatype _within2)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_AbsynUtil_withinEqualCaseInsensitive(threadData, _within1, _within2);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_AbsynUtil_withinEqual(threadData_t *threadData, modelica_metatype _within1, modelica_metatype _within2)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _within1;
tmp4_2 = _within2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmp1 = omc_AbsynUtil_pathEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_within1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_within2), 2))));
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
modelica_metatype boxptr_AbsynUtil_withinEqual(threadData_t *threadData, modelica_metatype _within1, modelica_metatype _within2)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_AbsynUtil_withinEqual(threadData, _within1, _within2);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_AbsynUtil_pathIsQual(threadData_t *threadData, modelica_metatype _inPath)
{
modelica_boolean _outIsQual;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPath;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
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
_outIsQual = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsQual;
}
modelica_metatype boxptr_AbsynUtil_pathIsQual(threadData_t *threadData, modelica_metatype _inPath)
{
modelica_boolean _outIsQual;
modelica_metatype out_outIsQual;
_outIsQual = omc_AbsynUtil_pathIsQual(threadData, _inPath);
out_outIsQual = mmc_mk_icon(_outIsQual);
return out_outIsQual;
}
DLLExport
modelica_boolean omc_AbsynUtil_pathIsIdent(threadData_t *threadData, modelica_metatype _inPath)
{
modelica_boolean _outIsIdent;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPath;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
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
_outIsIdent = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsIdent;
}
modelica_metatype boxptr_AbsynUtil_pathIsIdent(threadData_t *threadData, modelica_metatype _inPath)
{
modelica_boolean _outIsIdent;
modelica_metatype out_outIsIdent;
_outIsIdent = omc_AbsynUtil_pathIsIdent(threadData, _inPath);
out_outIsIdent = mmc_mk_icon(_outIsIdent);
return out_outIsIdent;
}
DLLExport
modelica_boolean omc_AbsynUtil_pathIsFullyQualified(threadData_t *threadData, modelica_metatype _inPath)
{
modelica_boolean _outIsQualified;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPath;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
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
_outIsQualified = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsQualified;
}
modelica_metatype boxptr_AbsynUtil_pathIsFullyQualified(threadData_t *threadData, modelica_metatype _inPath)
{
modelica_boolean _outIsQualified;
modelica_metatype out_outIsQualified;
_outIsQualified = omc_AbsynUtil_pathIsFullyQualified(threadData, _inPath);
out_outIsQualified = mmc_mk_icon(_outIsQualified);
return out_outIsQualified;
}
DLLExport
modelica_metatype omc_AbsynUtil_unqualifyCref(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 2)));
goto tmp3_done;
}
case 1: {
tmpMeta1 = _inCref;
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
DLLExport
modelica_metatype omc_AbsynUtil_unqotePathIdents(threadData_t *threadData, modelica_metatype _inPath)
{
modelica_metatype _path = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_path = omc_AbsynUtil_stringListPath(threadData, omc_List_map(threadData, omc_AbsynUtil_pathToStringList(threadData, _inPath), boxvar_System_unquoteIdentifier));
_return: OMC_LABEL_UNUSED
return _path;
}
DLLExport
modelica_string omc_AbsynUtil_crefIdent(threadData_t *threadData, modelica_metatype _cr)
{
modelica_string _str = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _cr;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,2,2) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
if (!listEmpty(tmpMeta3)) MMC_THROW_INTERNAL();
_str = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _str;
}
DLLExport
modelica_metatype omc_AbsynUtil_makeCons(threadData_t *threadData, modelica_metatype _e1, modelica_metatype _e2)
{
modelica_metatype _e = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box3(23, &Absyn_Exp_CONS__desc, _e1, _e2);
_e = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _e;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_onlyLiteralsInExpExit(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inLst, modelica_metatype *out_outLst)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outLst = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _inLst;
{
modelica_metatype _lst = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,2,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (13 != MMC_STRLEN(tmpMeta7) || strcmp(MMC_STRINGDATA(_OMC_LIT25), MMC_STRINGDATA(tmpMeta7)) != 0) goto tmp3_end;
_lst = tmp4_2;
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _lst;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inLst;
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
_outLst = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outLst) { *out_outLst = _outLst; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_onlyLiteralsInExpEnter(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inLst, modelica_metatype *out_outLst)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outLst = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _inLst;
{
modelica_boolean _b;
modelica_metatype _e = NULL;
modelica_metatype _lst = NULL;
modelica_metatype _rest = NULL;
modelica_string _name = NULL;
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
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,3) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
_lst = tmpMeta6;
_rest = tmpMeta7;
_e = tmp4_1;
_name = tmpMeta9;
_b = listMember(_name, _OMC_LIT39);
_lst = omc_List_consOnTrue(threadData, (!_b), _e, _lst);
tmpMeta10 = mmc_mk_cons(_lst, _rest);
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = tmpMeta10;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta11 = MMC_CAR(tmp4_2);
tmpMeta12 = MMC_CDR(tmp4_2);
_lst = tmpMeta11;
_rest = tmpMeta12;
tmpMeta14 = mmc_mk_cons(_inExp, _lst);
tmpMeta13 = mmc_mk_cons(tmpMeta14, _rest);
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = tmpMeta13;
goto tmp3_done;
}
case 2: {
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inLst;
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
_outLst = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outLst) { *out_outLst = _outLst; }
return _outExp;
}
DLLExport
modelica_boolean omc_AbsynUtil_onlyLiteralsInEqMod(threadData_t *threadData, modelica_metatype _eqMod)
{
modelica_boolean _onlyLiterals;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _eqMod;
{
modelica_metatype _lst = NULL;
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
omc_AbsynUtil_traverseExpBidir(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eqMod), 2))), boxvar_AbsynUtil_onlyLiteralsInExpEnter, boxvar_AbsynUtil_onlyLiteralsInExpExit, _OMC_LIT40, &tmpMeta6);
if (listEmpty(tmpMeta6)) goto goto_2;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
if (!listEmpty(tmpMeta8)) goto goto_2;
_lst = tmpMeta7;
tmp1 = listEmpty(_lst);
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
_onlyLiterals = tmp1;
_return: OMC_LABEL_UNUSED
return _onlyLiterals;
}
modelica_metatype boxptr_AbsynUtil_onlyLiteralsInEqMod(threadData_t *threadData, modelica_metatype _eqMod)
{
modelica_boolean _onlyLiterals;
modelica_metatype out_onlyLiterals;
_onlyLiterals = omc_AbsynUtil_onlyLiteralsInEqMod(threadData, _eqMod);
out_onlyLiterals = mmc_mk_icon(_onlyLiterals);
return out_onlyLiterals;
}
DLLExport
modelica_boolean omc_AbsynUtil_onlyLiteralsInAnnotationMod(threadData_t *threadData, modelica_metatype _inMod)
{
modelica_boolean _onlyLiterals;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inMod;
{
modelica_metatype _dive = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _eqMod = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp4 += 3;
tmp1 = 1;
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
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,6) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
if (11 != MMC_STRLEN(tmpMeta9) || strcmp(MMC_STRINGDATA(_OMC_LIT9), MMC_STRINGDATA(tmpMeta9)) != 0) goto tmp3_end;
_rest = tmpMeta7;
tmp1 = omc_AbsynUtil_onlyLiteralsInAnnotationMod(threadData, _rest);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,0,6) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 5));
if (optionNone(tmpMeta12)) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 1));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 3));
_dive = tmpMeta14;
_eqMod = tmpMeta15;
_rest = tmpMeta11;
tmp1 = ((omc_AbsynUtil_onlyLiteralsInEqMod(threadData, _eqMod) && omc_AbsynUtil_onlyLiteralsInAnnotationMod(threadData, _dive)) && omc_AbsynUtil_onlyLiteralsInAnnotationMod(threadData, _rest));
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmp4_1);
tmpMeta17 = MMC_CDR(tmp4_1);
_rest = tmpMeta17;
tmp1 = omc_AbsynUtil_onlyLiteralsInAnnotationMod(threadData, _rest);
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
_onlyLiterals = tmp1;
_return: OMC_LABEL_UNUSED
return _onlyLiterals;
}
modelica_metatype boxptr_AbsynUtil_onlyLiteralsInAnnotationMod(threadData_t *threadData, modelica_metatype _inMod)
{
modelica_boolean _onlyLiterals;
modelica_metatype out_onlyLiterals;
_onlyLiterals = omc_AbsynUtil_onlyLiteralsInAnnotationMod(threadData, _inMod);
out_onlyLiterals = mmc_mk_icon(_onlyLiterals);
return out_onlyLiterals;
}
DLLExport
modelica_metatype omc_AbsynUtil_canonIfExp(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _cond = NULL;
modelica_metatype _tb = NULL;
modelica_metatype _eb = NULL;
modelica_metatype _ei_cond = NULL;
modelica_metatype _ei_tb = NULL;
modelica_metatype _e = NULL;
modelica_metatype _eib = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta1 = _inExp;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (listEmpty(tmpMeta10)) goto tmp3_end;
tmpMeta11 = MMC_CAR(tmpMeta10);
tmpMeta12 = MMC_CDR(tmpMeta10);
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 1));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
_cond = tmpMeta7;
_tb = tmpMeta8;
_eb = tmpMeta9;
_ei_cond = tmpMeta13;
_ei_tb = tmpMeta14;
_eib = tmpMeta12;
tmpMeta15 = mmc_mk_box5(13, &Absyn_Exp_IFEXP__desc, _ei_cond, _ei_tb, _eb, _eib);
_e = omc_AbsynUtil_canonIfExp(threadData, tmpMeta15);
tmpMeta16 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta17 = mmc_mk_box5(13, &Absyn_Exp_IFEXP__desc, _cond, _tb, _e, tmpMeta16);
tmpMeta1 = tmpMeta17;
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
modelica_boolean omc_AbsynUtil_importEqual(threadData_t *threadData, modelica_metatype _im1, modelica_metatype _im2)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _im1;
tmp4_2 = _im2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmp1 = ((stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_im1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_im2), 2))))) && omc_AbsynUtil_pathEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_im1), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_im2), 3)))));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmp1 = omc_AbsynUtil_pathEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_im1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_im2), 2))));
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
tmp1 = omc_AbsynUtil_pathEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_im1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_im2), 2))));
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
_outBoolean = tmp1;
_return: OMC_LABEL_UNUSED
return _outBoolean;
}
modelica_metatype boxptr_AbsynUtil_importEqual(threadData_t *threadData, modelica_metatype _im1, modelica_metatype _im2)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_AbsynUtil_importEqual(threadData, _im1, _im2);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_metatype omc_AbsynUtil_makeNotFullyQualified(threadData_t *threadData, modelica_metatype _inPath)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPath;
{
modelica_metatype _path = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_path = tmpMeta6;
tmpMeta1 = _path;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _inPath;
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
modelica_metatype omc_AbsynUtil_makeFullyQualified(threadData_t *threadData, modelica_metatype _inPath)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPath;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta1 = _inPath;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
tmpMeta6 = mmc_mk_box2(5, &Absyn_Path_FULLYQUALIFIED__desc, _inPath);
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
_outPath = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outPath;
}
DLLExport
modelica_boolean omc_AbsynUtil_innerOuterEqual(threadData_t *threadData, modelica_metatype _io1, modelica_metatype _io2)
{
modelica_boolean _res;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,0) == 0) goto tmp3_end;
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_AbsynUtil_innerOuterEqual(threadData_t *threadData, modelica_metatype _io1, modelica_metatype _io2)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_AbsynUtil_innerOuterEqual(threadData, _io1, _io2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_boolean omc_AbsynUtil_isNotInnerOuter(threadData_t *threadData, modelica_metatype _inIO)
{
modelica_boolean _outIsNotInnerOuter;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inIO;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,0) == 0) goto tmp3_end;
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
_outIsNotInnerOuter = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsNotInnerOuter;
}
modelica_metatype boxptr_AbsynUtil_isNotInnerOuter(threadData_t *threadData, modelica_metatype _inIO)
{
modelica_boolean _outIsNotInnerOuter;
modelica_metatype out_outIsNotInnerOuter;
_outIsNotInnerOuter = omc_AbsynUtil_isNotInnerOuter(threadData, _inIO);
out_outIsNotInnerOuter = mmc_mk_icon(_outIsNotInnerOuter);
return out_outIsNotInnerOuter;
}
DLLExport
modelica_boolean omc_AbsynUtil_isInnerOuter(threadData_t *threadData, modelica_metatype _inIO)
{
modelica_boolean _outIsInnerOuter;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inIO;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,0) == 0) goto tmp3_end;
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
_outIsInnerOuter = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsInnerOuter;
}
modelica_metatype boxptr_AbsynUtil_isInnerOuter(threadData_t *threadData, modelica_metatype _inIO)
{
modelica_boolean _outIsInnerOuter;
modelica_metatype out_outIsInnerOuter;
_outIsInnerOuter = omc_AbsynUtil_isInnerOuter(threadData, _inIO);
out_outIsInnerOuter = mmc_mk_icon(_outIsInnerOuter);
return out_outIsInnerOuter;
}
DLLExport
modelica_boolean omc_AbsynUtil_isOnlyOuter(threadData_t *threadData, modelica_metatype _inIO)
{
modelica_boolean _outOnlyOuter;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inIO;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
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
_outOnlyOuter = tmp1;
_return: OMC_LABEL_UNUSED
return _outOnlyOuter;
}
modelica_metatype boxptr_AbsynUtil_isOnlyOuter(threadData_t *threadData, modelica_metatype _inIO)
{
modelica_boolean _outOnlyOuter;
modelica_metatype out_outOnlyOuter;
_outOnlyOuter = omc_AbsynUtil_isOnlyOuter(threadData, _inIO);
out_outOnlyOuter = mmc_mk_icon(_outOnlyOuter);
return out_outOnlyOuter;
}
DLLExport
modelica_boolean omc_AbsynUtil_isOnlyInner(threadData_t *threadData, modelica_metatype _inIO)
{
modelica_boolean _outOnlyInner;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inIO;
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
_outOnlyInner = tmp1;
_return: OMC_LABEL_UNUSED
return _outOnlyInner;
}
modelica_metatype boxptr_AbsynUtil_isOnlyInner(threadData_t *threadData, modelica_metatype _inIO)
{
modelica_boolean _outOnlyInner;
modelica_metatype out_outOnlyInner;
_outOnlyInner = omc_AbsynUtil_isOnlyInner(threadData, _inIO);
out_outOnlyInner = mmc_mk_icon(_outOnlyInner);
return out_outOnlyInner;
}
DLLExport
modelica_boolean omc_AbsynUtil_isInner(threadData_t *threadData, modelica_metatype _io)
{
modelica_boolean _isItAnInner;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _io;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
tmp1 = 1;
goto tmp3_done;
}
case 3: {
tmp1 = 1;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
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
_isItAnInner = tmp1;
_return: OMC_LABEL_UNUSED
return _isItAnInner;
}
modelica_metatype boxptr_AbsynUtil_isInner(threadData_t *threadData, modelica_metatype _io)
{
modelica_boolean _isItAnInner;
modelica_metatype out_isItAnInner;
_isItAnInner = omc_AbsynUtil_isInner(threadData, _io);
out_isItAnInner = mmc_mk_icon(_isItAnInner);
return out_isItAnInner;
}
DLLExport
modelica_boolean omc_AbsynUtil_isOuter(threadData_t *threadData, modelica_metatype _io)
{
modelica_boolean _isItAnOuter;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _io;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
tmp1 = 1;
goto tmp3_done;
}
case 4: {
tmp1 = 1;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
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
_isItAnOuter = tmp1;
_return: OMC_LABEL_UNUSED
return _isItAnOuter;
}
modelica_metatype boxptr_AbsynUtil_isOuter(threadData_t *threadData, modelica_metatype _io)
{
modelica_boolean _isItAnOuter;
modelica_metatype out_isItAnOuter;
_isItAnOuter = omc_AbsynUtil_isOuter(threadData, _io);
out_isItAnOuter = mmc_mk_icon(_isItAnOuter);
return out_isItAnOuter;
}
DLLExport
modelica_string omc_AbsynUtil_getFileNameFromInfo(threadData_t *threadData, modelica_metatype _inInfo)
{
modelica_string _inFileName = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inInfo;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_inFileName = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _inFileName;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_getIteratorIndexedCrefs(threadData_t *threadData, modelica_metatype _inCref, modelica_string _inIterator, modelica_metatype _inCrefs)
{
modelica_metatype _outCrefs = NULL;
modelica_metatype _crefs = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCrefs = _inCrefs;
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
modelica_metatype _subs = NULL;
modelica_integer _idx;
modelica_string _name = NULL;
modelica_string _id = NULL;
modelica_metatype _cref = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_id = tmpMeta5;
_subs = tmpMeta6;
_idx = ((modelica_integer) 1);
{
modelica_metatype _sub;
for (tmpMeta7 = _subs; !listEmpty(tmpMeta7); tmpMeta7=MMC_CDR(tmpMeta7))
{
_sub = MMC_CAR(tmpMeta7);
{
modelica_metatype tmp10_1;
tmp10_1 = _sub;
{
volatile mmc_switch_type tmp10;
int tmp11;
tmp10 = 0;
for (; tmp10 < 2; tmp10++) {
switch (MMC_SWITCH_CAST(tmp10)) {
case 0: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp10_1,1,1) == 0) goto tmp9_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp10_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,2,1) == 0) goto tmp9_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,2,2) == 0) goto tmp9_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 3));
if (!listEmpty(tmpMeta15)) goto tmp9_end;
_name = tmpMeta14;
if((stringEqual(_name, _inIterator)))
{
tmpMeta17 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta18 = mmc_mk_box3(5, &Absyn_ComponentRef_CREF__IDENT__desc, _id, tmpMeta17);
tmpMeta19 = mmc_mk_box2(0, tmpMeta18, mmc_mk_integer(_idx));
tmpMeta16 = mmc_mk_cons(tmpMeta19, _outCrefs);
_outCrefs = tmpMeta16;
}
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
goto_8:;
goto goto_2;
goto tmp9_done;
tmp9_done:;
}
}
;
_idx = ((modelica_integer) 1) + _idx;
}
}
tmpMeta1 = _outCrefs;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_integer tmp29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id = tmpMeta21;
_subs = tmpMeta22;
_cref = tmpMeta23;
tmpMeta24 = MMC_REFSTRUCTLIT(mmc_nil);
_crefs = omc_AbsynUtil_getIteratorIndexedCrefs(threadData, _cref, _inIterator, tmpMeta24);
{
modelica_metatype _cr;
for (tmpMeta25 = _crefs; !listEmpty(tmpMeta25); tmpMeta25=MMC_CDR(tmpMeta25))
{
_cr = MMC_CAR(tmpMeta25);
tmpMeta26 = _cr;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 1));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 2));
tmp29 = mmc_unbox_integer(tmpMeta28);
_cref = tmpMeta27;
_idx = tmp29;
tmpMeta31 = mmc_mk_box4(4, &Absyn_ComponentRef_CREF__QUAL__desc, _id, _subs, _cref);
tmpMeta32 = mmc_mk_box2(0, tmpMeta31, mmc_mk_integer(_idx));
tmpMeta30 = mmc_mk_cons(tmpMeta32, _outCrefs);
_outCrefs = tmpMeta30;
}
}
tmpMeta34 = mmc_mk_box3(5, &Absyn_ComponentRef_CREF__IDENT__desc, _id, _subs);
_inCref = tmpMeta34;
_inCrefs = _outCrefs;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_integer tmp41;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cref = tmpMeta35;
tmpMeta36 = MMC_REFSTRUCTLIT(mmc_nil);
_crefs = omc_AbsynUtil_getIteratorIndexedCrefs(threadData, _cref, _inIterator, tmpMeta36);
{
modelica_metatype _cr;
for (tmpMeta37 = _crefs; !listEmpty(tmpMeta37); tmpMeta37=MMC_CDR(tmpMeta37))
{
_cr = MMC_CAR(tmpMeta37);
tmpMeta38 = _cr;
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta38), 1));
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta38), 2));
tmp41 = mmc_unbox_integer(tmpMeta40);
_cref = tmpMeta39;
_idx = tmp41;
tmpMeta43 = mmc_mk_box2(3, &Absyn_ComponentRef_CREF__FULLYQUALIFIED__desc, _cref);
tmpMeta44 = mmc_mk_box2(0, tmpMeta43, mmc_mk_integer(_idx));
tmpMeta42 = mmc_mk_cons(tmpMeta44, _outCrefs);
_outCrefs = tmpMeta42;
}
}
tmpMeta1 = _outCrefs;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
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
_outCrefs = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCrefs;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_AbsynUtil_iteratorIndexedCrefsEqual(threadData_t *threadData, modelica_metatype _inCref1, modelica_metatype _inCref2)
{
modelica_boolean _outEqual;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
modelica_integer _idx1;
modelica_integer _idx2;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_integer tmp4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_integer tmp8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inCref1;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmp4 = mmc_unbox_integer(tmpMeta3);
_cr1 = tmpMeta2;
_idx1 = tmp4;
tmpMeta5 = _inCref2;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 2));
tmp8 = mmc_unbox_integer(tmpMeta7);
_cr2 = tmpMeta6;
_idx2 = tmp8;
_outEqual = ((_idx1 == _idx2) && omc_AbsynUtil_crefEqual(threadData, _cr1, _cr2));
_return: OMC_LABEL_UNUSED
return _outEqual;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_iteratorIndexedCrefsEqual(threadData_t *threadData, modelica_metatype _inCref1, modelica_metatype _inCref2)
{
modelica_boolean _outEqual;
modelica_metatype out_outEqual;
_outEqual = omc_AbsynUtil_iteratorIndexedCrefsEqual(threadData, _inCref1, _inCref2);
out_outEqual = mmc_mk_icon(_outEqual);
return out_outEqual;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_findIteratorIndexedCrefs__traverser(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inCrefs, modelica_string _inIterator, modelica_metatype *out_outCrefs)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outCrefs = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outExp = _inExp;
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta1 = omc_AbsynUtil_getIteratorIndexedCrefs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inExp), 2))), _inIterator, _inCrefs);
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
_outCrefs = tmpMeta1;
_return: OMC_LABEL_UNUSED
if (out_outCrefs) { *out_outCrefs = _outCrefs; }
return _outExp;
}
static modelica_metatype closure11_AbsynUtil_findIteratorIndexedCrefs__traverser(threadData_t *thData, modelica_metatype closure, modelica_metatype inExp, modelica_metatype inCrefs, modelica_metatype tmp1)
{
modelica_string inIterator = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_AbsynUtil_findIteratorIndexedCrefs__traverser(thData, inExp, inCrefs, inIterator, tmp1);
}static modelica_metatype closure12_List_unionEltOnTrue(threadData_t *thData, modelica_metatype closure, modelica_metatype inElement, modelica_metatype inList)
{
modelica_fnptr inCompFunc = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_List_unionEltOnTrue(thData, inElement, inList, inCompFunc);
}
DLLExport
modelica_metatype omc_AbsynUtil_findIteratorIndexedCrefs(threadData_t *threadData, modelica_metatype _inExp, modelica_string _inIterator, modelica_metatype _inCrefs)
{
modelica_metatype _outCrefs = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta2 = mmc_mk_box1(0, _inIterator);
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
omc_AbsynUtil_traverseExp(threadData, _inExp, (modelica_fnptr) mmc_mk_box2(0,closure11_AbsynUtil_findIteratorIndexedCrefs__traverser,tmpMeta2), tmpMeta3 ,&_outCrefs);
tmpMeta4 = mmc_mk_box1(0, boxvar_AbsynUtil_iteratorIndexedCrefsEqual);
_outCrefs = omc_List_fold(threadData, _outCrefs, (modelica_fnptr) mmc_mk_box2(0,closure12_List_unionEltOnTrue,tmpMeta4), _inCrefs);
_return: OMC_LABEL_UNUSED
return _outCrefs;
}
DLLExport
modelica_string omc_AbsynUtil_getClassName(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_string _outName = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inClass;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_outName = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _outName;
}
DLLExport
modelica_boolean omc_AbsynUtil_expEqual(threadData_t *threadData, modelica_metatype _exp1, modelica_metatype _exp2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _exp1;
tmp4_2 = _exp2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmp1 = (((modelica_real)mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp1), 2))))) == stringReal((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp2), 2)))));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmp1 = (((modelica_real)mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp2), 2))))) == stringReal((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp1), 2)))));
goto tmp3_done;
}
case 2: {
tmp1 = valueEq(_exp1, _exp2);
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
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
modelica_metatype boxptr_AbsynUtil_expEqual(threadData_t *threadData, modelica_metatype _exp1, modelica_metatype _exp2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_AbsynUtil_expEqual(threadData, _exp1, _exp2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_boolean omc_AbsynUtil_isFunctionRestriction(threadData_t *threadData, modelica_metatype _inRestriction)
{
modelica_boolean _outIsFunction;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inRestriction;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
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
_outIsFunction = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsFunction;
}
modelica_metatype boxptr_AbsynUtil_isFunctionRestriction(threadData_t *threadData, modelica_metatype _inRestriction)
{
modelica_boolean _outIsFunction;
modelica_metatype out_outIsFunction;
_outIsFunction = omc_AbsynUtil_isFunctionRestriction(threadData, _inRestriction);
out_outIsFunction = mmc_mk_icon(_outIsFunction);
return out_outIsFunction;
}
DLLExport
modelica_boolean omc_AbsynUtil_isPackageRestriction(threadData_t *threadData, modelica_metatype _inRestriction)
{
modelica_boolean _outIsPackage;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inRestriction;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,0) == 0) goto tmp3_end;
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
_outIsPackage = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsPackage;
}
modelica_metatype boxptr_AbsynUtil_isPackageRestriction(threadData_t *threadData, modelica_metatype _inRestriction)
{
modelica_boolean _outIsPackage;
modelica_metatype out_outIsPackage;
_outIsPackage = omc_AbsynUtil_isPackageRestriction(threadData, _inRestriction);
out_outIsPackage = mmc_mk_icon(_outIsPackage);
return out_outIsPackage;
}
DLLExport
modelica_boolean omc_AbsynUtil_crefEqualNoSubs(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _cr1;
tmp4_2 = _cr2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,2) == 0) goto tmp3_end;
tmp1 = (stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2)))));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmp1 = ((stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))))) && omc_AbsynUtil_crefEqualNoSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4)))));
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
_cr1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2)));
_cr2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2)));
goto _tailrecursive;
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
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
modelica_metatype boxptr_AbsynUtil_crefEqualNoSubs(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_AbsynUtil_crefEqualNoSubs(threadData, _cr1, _cr2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_boolean omc_AbsynUtil_subscriptsEqual(threadData_t *threadData, modelica_metatype _inSubList1, modelica_metatype _inSubList2)
{
modelica_boolean _outIsEqual;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outIsEqual = omc_List_isEqualOnTrue(threadData, _inSubList1, _inSubList2, boxvar_AbsynUtil_subscriptEqual);
_return: OMC_LABEL_UNUSED
return _outIsEqual;
}
modelica_metatype boxptr_AbsynUtil_subscriptsEqual(threadData_t *threadData, modelica_metatype _inSubList1, modelica_metatype _inSubList2)
{
modelica_boolean _outIsEqual;
modelica_metatype out_outIsEqual;
_outIsEqual = omc_AbsynUtil_subscriptsEqual(threadData, _inSubList1, _inSubList2);
out_outIsEqual = mmc_mk_icon(_outIsEqual);
return out_outIsEqual;
}
DLLExport
modelica_boolean omc_AbsynUtil_subscriptEqual(threadData_t *threadData, modelica_metatype _inSubscript1, modelica_metatype _inSubscript2)
{
modelica_boolean _outIsEqual;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inSubscript1;
tmp4_2 = _inSubscript2;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_e1 = tmpMeta6;
_e2 = tmpMeta7;
tmp1 = omc_AbsynUtil_expEqual(threadData, _e1, _e2);
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
_outIsEqual = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsEqual;
}
modelica_metatype boxptr_AbsynUtil_subscriptEqual(threadData_t *threadData, modelica_metatype _inSubscript1, modelica_metatype _inSubscript2)
{
modelica_boolean _outIsEqual;
modelica_metatype out_outIsEqual;
_outIsEqual = omc_AbsynUtil_subscriptEqual(threadData, _inSubscript1, _inSubscript2);
out_outIsEqual = mmc_mk_icon(_outIsEqual);
return out_outIsEqual;
}
DLLExport
modelica_boolean omc_AbsynUtil_crefFirstEqual(threadData_t *threadData, modelica_metatype _iCr1, modelica_metatype _iCr2)
{
modelica_boolean _outBoolean;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outBoolean = (stringEqual(omc_AbsynUtil_crefFirstIdent(threadData, _iCr1), omc_AbsynUtil_crefFirstIdent(threadData, _iCr2)));
_return: OMC_LABEL_UNUSED
return _outBoolean;
}
modelica_metatype boxptr_AbsynUtil_crefFirstEqual(threadData_t *threadData, modelica_metatype _iCr1, modelica_metatype _iCr2)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_AbsynUtil_crefFirstEqual(threadData, _iCr1, _iCr2);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_boolean omc_AbsynUtil_crefEqual(threadData_t *threadData, modelica_metatype _cref1, modelica_metatype _cref2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _cref1;
tmp4_2 = _cref2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,2) == 0) goto tmp3_end;
tmp1 = ((stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref2), 2))))) && omc_AbsynUtil_subscriptsEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref1), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref2), 3)))));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmp1 = (((stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref2), 2))))) && omc_AbsynUtil_subscriptsEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref1), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref2), 3))))) && omc_AbsynUtil_crefEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref2), 4)))));
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
_cref1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref1), 2)));
_cref2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref2), 2)));
goto _tailrecursive;
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
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
modelica_metatype boxptr_AbsynUtil_crefEqual(threadData_t *threadData, modelica_metatype _cref1, modelica_metatype _cref2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_AbsynUtil_crefEqual(threadData, _cref1, _cref2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_metatype omc_AbsynUtil_setClassBody(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inBody)
{
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outClass = _inClass;
{
modelica_metatype tmp4_1;
tmp4_1 = _outClass;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_outClass), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[7] = _inBody;
_outClass = tmpMeta6;
tmpMeta1 = _outClass;
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
_outClass = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outClass;
}
DLLExport
modelica_metatype omc_AbsynUtil_setClassName(threadData_t *threadData, modelica_metatype _inClass, modelica_string _newName)
{
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outClass = _inClass;
{
modelica_metatype tmp4_1;
tmp4_1 = _outClass;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_outClass), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[2] = _newName;
_outClass = tmpMeta6;
tmpMeta1 = _outClass;
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
_outClass = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outClass;
}
DLLExport
modelica_metatype omc_AbsynUtil_setClassFilename(threadData_t *threadData, modelica_metatype _inClass, modelica_string _fileName)
{
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
modelica_metatype _info = NULL;
modelica_metatype _cl = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 10));
_cl = tmp4_1;
_info = tmpMeta6;
tmpMeta7 = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta7), MMC_UNTAGPTR(_info), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta7))[2] = _fileName;
_info = tmpMeta7;
tmpMeta8 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta8), MMC_UNTAGPTR(_cl), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta8))[10] = _info;
_cl = tmpMeta8;
tmpMeta1 = _cl;
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
_outClass = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outClass;
}
DLLExport
modelica_string omc_AbsynUtil_classFilename(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_string _outFilename = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inClass;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 10));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 2));
_outFilename = tmpMeta3;
_return: OMC_LABEL_UNUSED
return _outFilename;
}
DLLExport
modelica_metatype omc_AbsynUtil_lastClassname(threadData_t *threadData, modelica_metatype _inProgram)
{
modelica_metatype _outPath = NULL;
modelica_metatype _lst = NULL;
modelica_string _id = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inProgram;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_lst = tmpMeta2;
tmpMeta3 = omc_List_last(threadData, _lst);
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 2));
_id = tmpMeta4;
tmpMeta5 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _id);
_outPath = tmpMeta5;
_return: OMC_LABEL_UNUSED
return _outPath;
}
DLLExport
modelica_string omc_AbsynUtil_restrString(threadData_t *threadData, modelica_metatype _inRestriction)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inRestriction;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 20; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT41;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT42;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT43;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT44;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT45;
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT46;
goto tmp3_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT47;
goto tmp3_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT48;
goto tmp3_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT49;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT50;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,1,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT51;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,0,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,2,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT52;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,1,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT53;
goto tmp3_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT54;
goto tmp3_done;
}
case 14: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,14,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT55;
goto tmp3_done;
}
case 15: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT56;
goto tmp3_done;
}
case 16: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT57;
goto tmp3_done;
}
case 17: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT58;
goto tmp3_done;
}
case 18: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,19,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT59;
goto tmp3_done;
}
case 19: {
tmp1 = _OMC_LIT60;
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
modelica_metatype omc_AbsynUtil_crefMakeFullyQualified(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta1 = _inComponentRef;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
tmpMeta6 = mmc_mk_box2(3, &Absyn_ComponentRef_CREF__FULLYQUALIFIED__desc, _inComponentRef);
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
_outComponentRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRef;
}
DLLExport
modelica_boolean omc_AbsynUtil_crefIsFullyQualified(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_boolean _outIsFullyQualified;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
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
_outIsFullyQualified = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsFullyQualified;
}
modelica_metatype boxptr_AbsynUtil_crefIsFullyQualified(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_boolean _outIsFullyQualified;
modelica_metatype out_outIsFullyQualified;
_outIsFullyQualified = omc_AbsynUtil_crefIsFullyQualified(threadData, _inCref);
out_outIsFullyQualified = mmc_mk_icon(_outIsFullyQualified);
return out_outIsFullyQualified;
}
DLLExport
modelica_metatype omc_AbsynUtil_crefStripFirst(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_cr = tmpMeta6;
tmpMeta1 = _cr;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cr = tmpMeta7;
_inComponentRef = _cr;
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
_outComponentRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRef;
}
DLLExport
modelica_metatype omc_AbsynUtil_crefFirstCref(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
modelica_metatype tmpMeta5;
tmpMeta5 = mmc_mk_box3(5, &Absyn_ComponentRef_CREF__IDENT__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 3))));
tmpMeta1 = tmpMeta5;
goto tmp3_done;
}
case 3: {
_inCref = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 2)));
goto _tailrecursive;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmpMeta1 = _inCref;
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
DLLExport
modelica_string omc_AbsynUtil_crefSecondIdent(threadData_t *threadData, modelica_metatype _cref)
{
modelica_string _ident = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cref;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmp1 = omc_AbsynUtil_crefFirstIdent(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 4))));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
_cref = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2)));
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
_ident = tmp1;
_return: OMC_LABEL_UNUSED
return _ident;
}
DLLExport
modelica_metatype omc_AbsynUtil_crefSetFirstIdent(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcref, modelica_string _ident)
{
modelica_metatype _cref = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cref = __omcQ_24in_5Fcref;
{
modelica_metatype tmp3_1;
tmp3_1 = _cref;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 5: {
modelica_metatype tmpMeta4;
tmpMeta4 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta4), MMC_UNTAGPTR(_cref), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta4))[2] = _ident;
_cref = tmpMeta4;
goto tmp2_done;
}
case 4: {
modelica_metatype tmpMeta5;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_cref), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[2] = _ident;
_cref = tmpMeta5;
goto tmp2_done;
}
case 3: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_cref), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[2] = omc_AbsynUtil_crefSetFirstIdent(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2))), _ident);
_cref = tmpMeta6;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
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
return _cref;
}
DLLExport
modelica_string omc_AbsynUtil_crefFirstIdent(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_string _outIdent = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
tmp1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 2)));
goto tmp3_done;
}
case 4: {
tmp1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 2)));
goto tmp3_done;
}
case 3: {
_inCref = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 2)));
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
_outIdent = tmp1;
_return: OMC_LABEL_UNUSED
return _outIdent;
}
DLLExport
modelica_metatype omc_AbsynUtil_joinCrefs(threadData_t *threadData, modelica_metatype _inComponentRef1, modelica_metatype _inComponentRef2)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inComponentRef1;
tmp4_2 = _inComponentRef2;
{
modelica_string _id = NULL;
modelica_metatype _sub = NULL;
modelica_metatype _cr2 = NULL;
modelica_metatype _cr_1 = NULL;
modelica_metatype _cr = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_boolean tmp7;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_id = tmpMeta5;
_sub = tmpMeta6;
_cr2 = tmp4_2;
tmp7 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmpMeta9 = _cr2;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,0,1) == 0) goto goto_8;
tmp7 = 1;
goto goto_8;
goto_8:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp7) {goto goto_2;}
tmpMeta10 = mmc_mk_box4(4, &Absyn_ComponentRef_CREF__QUAL__desc, _id, _sub, _cr2);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id = tmpMeta11;
_sub = tmpMeta12;
_cr = tmpMeta13;
_cr2 = tmp4_2;
_cr_1 = omc_AbsynUtil_joinCrefs(threadData, _cr, _cr2);
tmpMeta14 = mmc_mk_box4(4, &Absyn_ComponentRef_CREF__QUAL__desc, _id, _sub, _cr_1);
tmpMeta1 = tmpMeta14;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cr = tmpMeta15;
_cr2 = tmp4_2;
_cr_1 = omc_AbsynUtil_joinCrefs(threadData, _cr, _cr2);
tmpMeta1 = omc_AbsynUtil_crefMakeFullyQualified(threadData, _cr_1);
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
DLLExport
modelica_metatype omc_AbsynUtil_crefStripLastSubs(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcref)
{
modelica_metatype _cref = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cref = __omcQ_24in_5Fcref;
{
modelica_metatype tmp3_1;
tmp3_1 = _cref;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 5: {
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
tmpMeta5 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta4 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta4), MMC_UNTAGPTR(_cref), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta4))[3] = tmpMeta5;
_cref = tmpMeta4;
goto tmp2_done;
}
case 4: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_cref), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[4] = omc_AbsynUtil_crefStripLastSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 4))));
_cref = tmpMeta6;
goto tmp2_done;
}
case 3: {
modelica_metatype tmpMeta7;
tmpMeta7 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta7), MMC_UNTAGPTR(_cref), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta7))[2] = omc_AbsynUtil_crefStripLastSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2))));
_cref = tmpMeta7;
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
return _cref;
}
DLLExport
modelica_metatype omc_AbsynUtil_crefGetLastSubs(threadData_t *threadData, modelica_metatype _cref)
{
modelica_metatype _subscripts = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cref;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 3)));
goto tmp3_done;
}
case 4: {
_cref = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 4)));
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
_cref = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2)));
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
_subscripts = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _subscripts;
}
DLLExport
modelica_string omc_AbsynUtil_crefGetLastIdent(threadData_t *threadData, modelica_metatype _cref)
{
modelica_string _ident = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cref;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
tmp1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2)));
goto tmp3_done;
}
case 4: {
_cref = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 4)));
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
_cref = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2)));
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
_ident = tmp1;
_return: OMC_LABEL_UNUSED
return _ident;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_stripCommentExpressionsHelper(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype __omcQ_24in_5Fextra, modelica_metatype *out_extra)
{
modelica_metatype _exp = NULL;
modelica_metatype _extra = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_exp = __omcQ_24in_5Fexp;
_extra = __omcQ_24in_5Fextra;
{
modelica_metatype tmp4_1;
tmp4_1 = _exp;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
if (!listEmpty(tmpMeta8)) goto tmp3_end;
_exp = tmpMeta7;
tmpMeta1 = _exp;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,3) == 0) goto tmp3_end;
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 3)));
goto tmp3_done;
}
case 2: {
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
if (out_extra) { *out_extra = _extra; }
return _exp;
}
DLLExport
modelica_metatype omc_AbsynUtil_stripCommentExpressions(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp)
{
modelica_metatype _exp = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_exp = __omcQ_24in_5Fexp;
_exp = omc_AbsynUtil_traverseExp(threadData, _exp, boxvar_AbsynUtil_stripCommentExpressionsHelper, mmc_mk_boolean(1), NULL);
_return: OMC_LABEL_UNUSED
return _exp;
}
DLLExport
modelica_string omc_AbsynUtil_getString(threadData_t *threadData, modelica_metatype _exp)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _exp;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,3) == 0) goto tmp3_end;
_exp = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 3)));
goto _tailrecursive;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_str = tmpMeta6;
tmp1 = _str;
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
modelica_metatype omc_AbsynUtil_getSubsFromCref(threadData_t *threadData, modelica_metatype _cr, modelica_boolean _includeSubs, modelica_boolean _includeFunctions)
{
modelica_metatype _subscripts = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cr;
{
modelica_metatype _subs2 = NULL;
modelica_metatype _child = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_subs2 = tmpMeta5;
tmpMeta1 = _subs2;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_subs2 = tmpMeta6;
_child = tmpMeta7;
_subscripts = omc_AbsynUtil_getSubsFromCref(threadData, _child, _includeSubs, _includeFunctions);
tmpMeta1 = omc_List_unionOnTrue(threadData, _subscripts, _subs2, boxvar_AbsynUtil_subscriptEqual);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_child = tmpMeta8;
_cr = _child;
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
_subscripts = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _subscripts;
}
modelica_metatype boxptr_AbsynUtil_getSubsFromCref(threadData_t *threadData, modelica_metatype _cr, modelica_metatype _includeSubs, modelica_metatype _includeFunctions)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _subscripts = NULL;
tmp1 = mmc_unbox_integer(_includeSubs);
tmp2 = mmc_unbox_integer(_includeFunctions);
_subscripts = omc_AbsynUtil_getSubsFromCref(threadData, _cr, tmp1, tmp2);
return _subscripts;
}
DLLExport
modelica_boolean omc_AbsynUtil_crefHasSubscripts(threadData_t *threadData, modelica_metatype _cref)
{
modelica_boolean _hasSubscripts;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cref;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmp1 = (!listEmpty((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 3)))));
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
_cref = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 4)));
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
_cref = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2)));
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,0) == 0) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,0) == 0) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 5: {
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
_hasSubscripts = tmp1;
_return: OMC_LABEL_UNUSED
return _hasSubscripts;
}
modelica_metatype boxptr_AbsynUtil_crefHasSubscripts(threadData_t *threadData, modelica_metatype _cref)
{
modelica_boolean _hasSubscripts;
modelica_metatype out_hasSubscripts;
_hasSubscripts = omc_AbsynUtil_crefHasSubscripts(threadData, _cref);
out_hasSubscripts = mmc_mk_icon(_hasSubscripts);
return out_hasSubscripts;
}
DLLExport
modelica_metatype omc_AbsynUtil_crefSetLastSubs(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcref, modelica_metatype _inSubscripts)
{
modelica_metatype _cref = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cref = __omcQ_24in_5Fcref;
{
modelica_metatype tmp3_1;
tmp3_1 = _cref;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 5: {
modelica_metatype tmpMeta4;
tmpMeta4 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta4), MMC_UNTAGPTR(_cref), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta4))[3] = _inSubscripts;
_cref = tmpMeta4;
goto tmp2_done;
}
case 4: {
modelica_metatype tmpMeta5;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_cref), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[4] = omc_AbsynUtil_crefSetLastSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 4))), _inSubscripts);
_cref = tmpMeta5;
goto tmp2_done;
}
case 3: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_cref), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[2] = omc_AbsynUtil_crefSetLastSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2))), _inSubscripts);
_cref = tmpMeta6;
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
return _cref;
}
DLLExport
modelica_metatype omc_AbsynUtil_crefSetFirstSubs(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcref, modelica_metatype _subscripts)
{
modelica_metatype _cref = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cref = __omcQ_24in_5Fcref;
{
modelica_metatype tmp3_1;
tmp3_1 = _cref;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 5: {
modelica_metatype tmpMeta4;
tmpMeta4 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta4), MMC_UNTAGPTR(_cref), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta4))[3] = _subscripts;
_cref = tmpMeta4;
goto tmp2_done;
}
case 4: {
modelica_metatype tmpMeta5;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_cref), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[3] = _subscripts;
_cref = tmpMeta5;
goto tmp2_done;
}
case 3: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_cref), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[2] = omc_AbsynUtil_crefSetFirstSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2))), _subscripts);
_cref = tmpMeta6;
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
return _cref;
}
DLLExport
modelica_metatype omc_AbsynUtil_crefLastSubs(threadData_t *threadData, modelica_metatype _cref)
{
modelica_metatype _subscripts = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cref;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 3)));
goto tmp3_done;
}
case 4: {
_cref = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 4)));
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
_cref = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2)));
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
_subscripts = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _subscripts;
}
DLLExport
modelica_metatype omc_AbsynUtil_crefFirstSubs(threadData_t *threadData, modelica_metatype _cref)
{
modelica_metatype _subscripts = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cref;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 3)));
goto tmp3_done;
}
case 4: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 3)));
goto tmp3_done;
}
case 3: {
_cref = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2)));
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
_subscripts = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _subscripts;
}
DLLExport
modelica_boolean omc_AbsynUtil_crefIsQual(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_boolean _outIsQual;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
tmp1 = 1;
goto tmp3_done;
}
case 3: {
tmp1 = 1;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
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
_outIsQual = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsQual;
}
modelica_metatype boxptr_AbsynUtil_crefIsQual(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_boolean _outIsQual;
modelica_metatype out_outIsQual;
_outIsQual = omc_AbsynUtil_crefIsQual(threadData, _inComponentRef);
out_outIsQual = mmc_mk_icon(_outIsQual);
return out_outIsQual;
}
DLLExport
modelica_boolean omc_AbsynUtil_crefIsIdent(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_boolean _outIsIdent;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
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
_outIsIdent = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsIdent;
}
modelica_metatype boxptr_AbsynUtil_crefIsIdent(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_boolean _outIsIdent;
modelica_metatype out_outIsIdent;
_outIsIdent = omc_AbsynUtil_crefIsIdent(threadData, _inComponentRef);
out_outIsIdent = mmc_mk_icon(_outIsIdent);
return out_outIsIdent;
}
DLLExport
modelica_string omc_AbsynUtil_crefFirstIdentNoSubs(threadData_t *threadData, modelica_metatype _cref)
{
modelica_string _outIdent = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cref;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!listEmpty(tmpMeta5)) goto tmp3_end;
tmp1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2)));
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
tmp1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2)));
goto tmp3_done;
}
case 3: {
_cref = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2)));
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
_outIdent = tmp1;
_return: OMC_LABEL_UNUSED
return _outIdent;
}
DLLExport
modelica_string omc_AbsynUtil_crefLastIdent(threadData_t *threadData, modelica_metatype _cref)
{
modelica_string _outIdent = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cref;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
tmp1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2)));
goto tmp3_done;
}
case 4: {
_cref = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 4)));
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
_cref = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2)));
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
_outIdent = tmp1;
_return: OMC_LABEL_UNUSED
return _outIdent;
}
DLLExport
modelica_metatype omc_AbsynUtil_pathToCrefWithSubs(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inSubs)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPath;
{
modelica_string _i = NULL;
modelica_metatype _c = NULL;
modelica_metatype _p = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_i = tmpMeta5;
tmpMeta6 = mmc_mk_box3(5, &Absyn_ComponentRef_CREF__IDENT__desc, _i, _inSubs);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_i = tmpMeta7;
_p = tmpMeta8;
_c = omc_AbsynUtil_pathToCrefWithSubs(threadData, _p, _inSubs);
tmpMeta9 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta10 = mmc_mk_box4(4, &Absyn_ComponentRef_CREF__QUAL__desc, _i, tmpMeta9, _c);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta11;
_c = omc_AbsynUtil_pathToCrefWithSubs(threadData, _p, _inSubs);
tmpMeta1 = omc_AbsynUtil_crefMakeFullyQualified(threadData, _c);
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
DLLExport
modelica_metatype omc_AbsynUtil_pathToCref(threadData_t *threadData, modelica_metatype _inPath)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPath;
{
modelica_string _i = NULL;
modelica_metatype _c = NULL;
modelica_metatype _p = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_i = tmpMeta5;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta7 = mmc_mk_box3(5, &Absyn_ComponentRef_CREF__IDENT__desc, _i, tmpMeta6);
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_i = tmpMeta8;
_p = tmpMeta9;
_c = omc_AbsynUtil_pathToCref(threadData, _p);
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta11 = mmc_mk_box4(4, &Absyn_ComponentRef_CREF__QUAL__desc, _i, tmpMeta10, _c);
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta12;
_c = omc_AbsynUtil_pathToCref(threadData, _p);
tmpMeta1 = omc_AbsynUtil_crefMakeFullyQualified(threadData, _c);
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
DLLExport
modelica_metatype omc_AbsynUtil_crefToPathIgnoreSubs(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_string _i = NULL;
modelica_metatype _p = NULL;
modelica_metatype _c = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_i = tmpMeta5;
tmpMeta6 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _i);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_i = tmpMeta7;
_c = tmpMeta8;
_p = omc_AbsynUtil_crefToPathIgnoreSubs(threadData, _c);
tmpMeta9 = mmc_mk_box3(3, &Absyn_Path_QUALIFIED__desc, _i, _p);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_c = tmpMeta10;
_p = omc_AbsynUtil_crefToPathIgnoreSubs(threadData, _c);
tmpMeta11 = mmc_mk_box2(5, &Absyn_Path_FULLYQUALIFIED__desc, _p);
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
_outPath = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outPath;
}
DLLExport
modelica_metatype omc_AbsynUtil_elementSpecToPath(threadData_t *threadData, modelica_metatype _inElementSpec)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inElementSpec;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,1,3) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_outPath = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _outPath;
}
DLLExport
modelica_metatype omc_AbsynUtil_crefToPath(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_string _i = NULL;
modelica_metatype _p = NULL;
modelica_metatype _c = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
_i = tmpMeta5;
tmpMeta7 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _i);
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!listEmpty(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_i = tmpMeta8;
_c = tmpMeta10;
_p = omc_AbsynUtil_crefToPath(threadData, _c);
tmpMeta11 = mmc_mk_box3(3, &Absyn_Path_QUALIFIED__desc, _i, _p);
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_c = tmpMeta12;
_p = omc_AbsynUtil_crefToPath(threadData, _c);
tmpMeta13 = mmc_mk_box2(5, &Absyn_Path_FULLYQUALIFIED__desc, _p);
tmpMeta1 = tmpMeta13;
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
modelica_metatype omc_AbsynUtil_splitQualAndIdentPath(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype *out_outPath2)
{
modelica_metatype _outPath1 = NULL;
modelica_metatype _outPath2 = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPath;
{
modelica_metatype _qPath = NULL;
modelica_metatype _curPath = NULL;
modelica_metatype _identPath = NULL;
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_s1 = tmpMeta6;
_s2 = tmpMeta8;
tmpMeta9 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _s1);
tmpMeta10 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _s2);
tmpMeta[0+0] = tmpMeta9;
tmpMeta[0+1] = tmpMeta10;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_s1 = tmpMeta11;
_qPath = tmpMeta12;
_curPath = omc_AbsynUtil_splitQualAndIdentPath(threadData, _qPath ,&_identPath);
tmpMeta13 = mmc_mk_box3(3, &Absyn_Path_QUALIFIED__desc, _s1, _curPath);
tmpMeta[0+0] = tmpMeta13;
tmpMeta[0+1] = _identPath;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_qPath = tmpMeta14;
_inPath = _qPath;
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
_outPath1 = tmpMeta[0+0];
_outPath2 = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outPath2) { *out_outPath2 = _outPath2; }
return _outPath1;
}
DLLExport
modelica_metatype omc_AbsynUtil_crefStripLast(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
modelica_string _str = NULL;
modelica_metatype _c_1 = NULL;
modelica_metatype _c = NULL;
modelica_metatype _subs = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
goto goto_2;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,2,2) == 0) goto tmp3_end;
_str = tmpMeta6;
_subs = tmpMeta7;
tmpMeta9 = mmc_mk_box3(5, &Absyn_ComponentRef_CREF__IDENT__desc, _str, _subs);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_str = tmpMeta10;
_subs = tmpMeta11;
_c = tmpMeta12;
_c_1 = omc_AbsynUtil_crefStripLast(threadData, _c);
tmpMeta13 = mmc_mk_box4(4, &Absyn_ComponentRef_CREF__QUAL__desc, _str, _subs, _c_1);
tmpMeta1 = tmpMeta13;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_c = tmpMeta14;
_c_1 = omc_AbsynUtil_crefStripLast(threadData, _c);
tmpMeta1 = omc_AbsynUtil_crefMakeFullyQualified(threadData, _c_1);
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
DLLExport
modelica_metatype omc_AbsynUtil_stripLast(threadData_t *threadData, modelica_metatype _inPath)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPath;
{
modelica_string _str = NULL;
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,1) == 0) goto tmp3_end;
_str = tmpMeta6;
tmpMeta8 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _str);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_str = tmpMeta9;
_p = tmpMeta10;
_p = omc_AbsynUtil_stripLast(threadData, _p);
tmpMeta11 = mmc_mk_box3(3, &Absyn_Path_QUALIFIED__desc, _str, _p);
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta12;
_p = omc_AbsynUtil_stripLast(threadData, _p);
tmpMeta13 = mmc_mk_box2(5, &Absyn_Path_FULLYQUALIFIED__desc, _p);
tmpMeta1 = tmpMeta13;
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
modelica_metatype omc_AbsynUtil_joinPathsOptSuffix(threadData_t *threadData, modelica_metatype _inPath1, modelica_metatype _inPath2)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPath2;
{
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_p = tmpMeta6;
tmpMeta1 = omc_AbsynUtil_joinPaths(threadData, _inPath1, _p);
goto tmp3_done;
}
case 1: {
tmpMeta1 = _inPath1;
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
modelica_metatype omc_AbsynUtil_joinPathsOpt(threadData_t *threadData, modelica_metatype _inPath1, modelica_metatype _inPath2)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPath1;
{
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
tmpMeta1 = _inPath2;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_p = tmpMeta6;
tmpMeta1 = omc_AbsynUtil_joinPaths(threadData, _p, _inPath2);
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
modelica_metatype omc_AbsynUtil_joinPaths(threadData_t *threadData, modelica_metatype _inPath1, modelica_metatype _inPath2)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inPath1;
tmp4_2 = _inPath2;
{
modelica_string _str = NULL;
modelica_metatype _p2 = NULL;
modelica_metatype _p_1 = NULL;
modelica_metatype _p = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_str = tmpMeta5;
_p2 = tmp4_2;
tmpMeta6 = mmc_mk_box3(3, &Absyn_Path_QUALIFIED__desc, _str, _p2);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_str = tmpMeta7;
_p = tmpMeta8;
_p2 = tmp4_2;
_p_1 = omc_AbsynUtil_joinPaths(threadData, _p, _p2);
tmpMeta9 = mmc_mk_box3(3, &Absyn_Path_QUALIFIED__desc, _str, _p_1);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta10;
_p2 = tmp4_2;
_inPath1 = _p;
_inPath2 = _p2;
goto _tailrecursive;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_p2 = tmpMeta11;
_p = tmp4_1;
_inPath1 = _p;
_inPath2 = _p2;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_getCrefFromNarg(threadData_t *threadData, modelica_metatype _inNamedArg, modelica_boolean _includeSubs, modelica_boolean _includeFunctions)
{
modelica_metatype _outComponentRefLst = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outComponentRefLst = omc_AbsynUtil_getCrefFromExp(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inNamedArg), 3))), _includeSubs, _includeFunctions);
_return: OMC_LABEL_UNUSED
return _outComponentRefLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_getCrefFromNarg(threadData_t *threadData, modelica_metatype _inNamedArg, modelica_metatype _includeSubs, modelica_metatype _includeFunctions)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outComponentRefLst = NULL;
tmp1 = mmc_unbox_integer(_includeSubs);
tmp2 = mmc_unbox_integer(_includeFunctions);
_outComponentRefLst = omc_AbsynUtil_getCrefFromNarg(threadData, _inNamedArg, tmp1, tmp2);
return _outComponentRefLst;
}
DLLExport
modelica_metatype omc_AbsynUtil_getNamedFuncArgNamesAndValues(threadData_t *threadData, modelica_metatype _namedArgs, modelica_metatype *out_values)
{
modelica_metatype _names = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _values = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_names = tmpMeta1;
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
_values = tmpMeta2;
{
modelica_metatype _arg;
for (tmpMeta3 = listReverse(_namedArgs); !listEmpty(tmpMeta3); tmpMeta3=MMC_CDR(tmpMeta3))
{
_arg = MMC_CAR(tmpMeta3);
tmpMeta4 = mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 2))), _names);
_names = tmpMeta4;
tmpMeta5 = mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 3))), _values);
_values = tmpMeta5;
}
}
_return: OMC_LABEL_UNUSED
if (out_values) { *out_values = _values; }
return _names;
}
DLLExport
modelica_metatype omc_AbsynUtil_iteratorGuard(threadData_t *threadData, modelica_metatype _iterator)
{
modelica_metatype _guardExp = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _iterator;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_guardExp = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _guardExp;
}
DLLExport
modelica_metatype omc_AbsynUtil_iteratorRange(threadData_t *threadData, modelica_metatype _iterator)
{
modelica_metatype _range = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _iterator;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
_range = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _range;
}
DLLExport
modelica_string omc_AbsynUtil_iteratorName(threadData_t *threadData, modelica_metatype _iterator)
{
modelica_string _name = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _iterator;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_name = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _name;
}
DLLExport
modelica_metatype omc_AbsynUtil_getCrefFromFarg(threadData_t *threadData, modelica_metatype _inFunctionArgs, modelica_boolean _includeSubs, modelica_boolean _includeFunctions)
{
modelica_metatype _outComponentRefLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inFunctionArgs;
{
modelica_metatype _l1 = NULL;
modelica_metatype _l2 = NULL;
modelica_metatype _fl1 = NULL;
modelica_metatype _fl2 = NULL;
modelica_metatype _fl3 = NULL;
modelica_metatype _expl = NULL;
modelica_metatype _nargl = NULL;
modelica_metatype _iterators = NULL;
modelica_metatype _exp = NULL;
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
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_expl = tmpMeta6;
_nargl = tmpMeta7;
_l1 = omc_List_map2(threadData, _expl, boxvar_AbsynUtil_getCrefFromExp, mmc_mk_boolean(_includeSubs), mmc_mk_boolean(_includeFunctions));
_fl1 = omc_List_flatten(threadData, _l1);
_l2 = omc_List_map2(threadData, _nargl, boxvar_AbsynUtil_getCrefFromNarg, mmc_mk_boolean(_includeSubs), mmc_mk_boolean(_includeFunctions));
_fl2 = omc_List_flatten(threadData, _l2);
tmpMeta1 = listAppend(_fl1, _fl2);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_exp = tmpMeta8;
_iterators = tmpMeta9;
_l1 = omc_List_map2Option(threadData, omc_List_map(threadData, _iterators, boxvar_AbsynUtil_iteratorRange), boxvar_AbsynUtil_getCrefFromExp, mmc_mk_boolean(_includeSubs), mmc_mk_boolean(_includeFunctions));
_l2 = omc_List_map2Option(threadData, omc_List_map(threadData, _iterators, boxvar_AbsynUtil_iteratorGuard), boxvar_AbsynUtil_getCrefFromExp, mmc_mk_boolean(_includeSubs), mmc_mk_boolean(_includeFunctions));
_fl1 = omc_List_flatten(threadData, _l1);
_fl2 = omc_List_flatten(threadData, _l2);
_fl3 = omc_AbsynUtil_getCrefFromExp(threadData, _exp, _includeSubs, _includeFunctions);
tmpMeta1 = listAppend(_fl1, listAppend(_fl2, _fl3));
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
_outComponentRefLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRefLst;
}
modelica_metatype boxptr_AbsynUtil_getCrefFromFarg(threadData_t *threadData, modelica_metatype _inFunctionArgs, modelica_metatype _includeSubs, modelica_metatype _includeFunctions)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outComponentRefLst = NULL;
tmp1 = mmc_unbox_integer(_includeSubs);
tmp2 = mmc_unbox_integer(_includeFunctions);
_outComponentRefLst = omc_AbsynUtil_getCrefFromFarg(threadData, _inFunctionArgs, tmp1, tmp2);
return _outComponentRefLst;
}
DLLExport
modelica_metatype omc_AbsynUtil_getCrefFromExp(threadData_t *threadData, modelica_metatype _inExp, modelica_boolean _includeSubs, modelica_boolean _includeFunctions)
{
modelica_metatype _outComponentRefLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_boolean tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _includeSubs;
{
modelica_metatype _cr = NULL;
modelica_metatype _l1 = NULL;
modelica_metatype _l2 = NULL;
modelica_metatype _res = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e3 = NULL;
modelica_metatype _farg = NULL;
modelica_metatype _expl = NULL;
modelica_metatype _expll = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _lstres1 = NULL;
modelica_metatype _crefll = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 30; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,4,0) == 0) goto tmp3_end;
tmpMeta11 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,3,0) == 0) goto tmp3_end;
tmpMeta13 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta13;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (0 != tmp4_2) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cr = tmpMeta14;
tmpMeta15 = mmc_mk_cons(_cr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta15;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (1 != tmp4_2) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cr = tmpMeta16;
_subs = omc_AbsynUtil_getSubsFromCref(threadData, _cr, _includeSubs, _includeFunctions);
_l1 = omc_AbsynUtil_getCrefsFromSubs(threadData, _subs, _includeSubs, _includeFunctions);
tmpMeta17 = mmc_mk_cons(_cr, _l1);
tmpMeta1 = tmpMeta17;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,3) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta18;
_e2 = tmpMeta19;
_l1 = omc_AbsynUtil_getCrefFromExp(threadData, _e1, _includeSubs, _includeFunctions);
_l2 = omc_AbsynUtil_getCrefFromExp(threadData, _e2, _includeSubs, _includeFunctions);
tmpMeta1 = listAppend(_l1, _l2);
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e1 = tmpMeta20;
_inExp = _e1;
goto _tailrecursive;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta21;
_e2 = tmpMeta22;
_l1 = omc_AbsynUtil_getCrefFromExp(threadData, _e1, _includeSubs, _includeFunctions);
_l2 = omc_AbsynUtil_getCrefFromExp(threadData, _e2, _includeSubs, _includeFunctions);
tmpMeta1 = listAppend(_l1, _l2);
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e1 = tmpMeta23;
_inExp = _e1;
goto _tailrecursive;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta24;
_e2 = tmpMeta25;
_l1 = omc_AbsynUtil_getCrefFromExp(threadData, _e1, _includeSubs, _includeFunctions);
_l2 = omc_AbsynUtil_getCrefFromExp(threadData, _e2, _includeSubs, _includeFunctions);
tmpMeta1 = listAppend(_l1, _l2);
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta26;
_e2 = tmpMeta27;
_e3 = tmpMeta28;
tmpMeta29 = mmc_mk_cons(omc_AbsynUtil_getCrefFromExp(threadData, _e1, _includeSubs, _includeFunctions), mmc_mk_cons(omc_AbsynUtil_getCrefFromExp(threadData, _e2, _includeSubs, _includeFunctions), mmc_mk_cons(omc_AbsynUtil_getCrefFromExp(threadData, _e3, _includeSubs, _includeFunctions), MMC_REFSTRUCTLIT(mmc_nil))));
tmpMeta1 = omc_List_flatten(threadData, tmpMeta29);
goto tmp3_done;
}
case 14: {
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_boolean tmp33;
modelica_metatype tmpMeta34;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,3) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_cr = tmpMeta30;
_farg = tmpMeta31;
_res = omc_AbsynUtil_getCrefFromFarg(threadData, _farg, _includeSubs, _includeFunctions);
tmp33 = (modelica_boolean)_includeFunctions;
if(tmp33)
{
tmpMeta32 = mmc_mk_cons(_cr, _res);
tmpMeta34 = tmpMeta32;
}
else
{
tmpMeta34 = _res;
}
tmpMeta1 = tmpMeta34;
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_boolean tmp38;
modelica_metatype tmpMeta39;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,2) == 0) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_cr = tmpMeta35;
_farg = tmpMeta36;
_res = omc_AbsynUtil_getCrefFromFarg(threadData, _farg, _includeSubs, _includeFunctions);
tmp38 = (modelica_boolean)_includeFunctions;
if(tmp38)
{
tmpMeta37 = mmc_mk_cons(_cr, _res);
tmpMeta39 = tmpMeta37;
}
else
{
tmpMeta39 = _res;
}
tmpMeta1 = tmpMeta39;
goto tmp3_done;
}
case 16: {
modelica_metatype tmpMeta40;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,1) == 0) goto tmp3_end;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_expl = tmpMeta40;
_lstres1 = omc_List_map2(threadData, _expl, boxvar_AbsynUtil_getCrefFromExp, mmc_mk_boolean(_includeSubs), mmc_mk_boolean(_includeFunctions));
tmpMeta1 = omc_List_flatten(threadData, _lstres1);
goto tmp3_done;
}
case 17: {
modelica_metatype tmpMeta41;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,14,1) == 0) goto tmp3_end;
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_expll = tmpMeta41;
tmpMeta1 = omc_List_flatten(threadData, omc_List_flatten(threadData, omc_List_map2List(threadData, _expll, boxvar_AbsynUtil_getCrefFromExp, mmc_mk_boolean(_includeSubs), mmc_mk_boolean(_includeFunctions))));
goto tmp3_done;
}
case 18: {
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,3) == 0) goto tmp3_end;
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (optionNone(tmpMeta43)) goto tmp3_end;
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta43), 1));
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta42;
_e3 = tmpMeta44;
_e2 = tmpMeta45;
_l1 = omc_AbsynUtil_getCrefFromExp(threadData, _e1, _includeSubs, _includeFunctions);
_l2 = omc_AbsynUtil_getCrefFromExp(threadData, _e2, _includeSubs, _includeFunctions);
_l2 = listAppend(_l1, _l2);
_l1 = omc_AbsynUtil_getCrefFromExp(threadData, _e3, _includeSubs, _includeFunctions);
tmpMeta1 = listAppend(_l1, _l2);
goto tmp3_done;
}
case 19: {
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,3) == 0) goto tmp3_end;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!optionNone(tmpMeta47)) goto tmp3_end;
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta46;
_e2 = tmpMeta48;
_l1 = omc_AbsynUtil_getCrefFromExp(threadData, _e1, _includeSubs, _includeFunctions);
_l2 = omc_AbsynUtil_getCrefFromExp(threadData, _e2, _includeSubs, _includeFunctions);
tmpMeta1 = listAppend(_l1, _l2);
goto tmp3_done;
}
case 20: {
modelica_metatype tmpMeta49;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,0) == 0) goto tmp3_end;
tmpMeta49 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta49;
goto tmp3_done;
}
case 21: {
modelica_metatype tmpMeta50;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,1) == 0) goto tmp3_end;
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_expl = tmpMeta50;
_crefll = omc_List_map2(threadData, _expl, boxvar_AbsynUtil_getCrefFromExp, mmc_mk_boolean(_includeSubs), mmc_mk_boolean(_includeFunctions));
tmpMeta1 = omc_List_flatten(threadData, _crefll);
goto tmp3_done;
}
case 22: {
modelica_metatype tmpMeta51;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,1) == 0) goto tmp3_end;
tmpMeta51 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta51;
goto tmp3_done;
}
case 23: {
modelica_metatype tmpMeta52;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,19,2) == 0) goto tmp3_end;
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e1 = tmpMeta52;
_inExp = _e1;
goto _tailrecursive;
goto tmp3_done;
}
case 24: {
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,20,2) == 0) goto tmp3_end;
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e1 = tmpMeta53;
_e2 = tmpMeta54;
_l1 = omc_AbsynUtil_getCrefFromExp(threadData, _e1, _includeSubs, _includeFunctions);
_l2 = omc_AbsynUtil_getCrefFromExp(threadData, _e2, _includeSubs, _includeFunctions);
tmpMeta1 = listAppend(_l1, _l2);
goto tmp3_done;
}
case 25: {
modelica_metatype tmpMeta55;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,1) == 0) goto tmp3_end;
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_expl = tmpMeta55;
_crefll = omc_List_map2(threadData, _expl, boxvar_AbsynUtil_getCrefFromExp, mmc_mk_boolean(_includeSubs), mmc_mk_boolean(_includeFunctions));
tmpMeta1 = omc_List_flatten(threadData, _crefll);
goto tmp3_done;
}
case 26: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,5) == 0) goto tmp3_end;
goto goto_2;
goto tmp3_done;
}
case 27: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,23,2) == 0) goto tmp3_end;
_inExp = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inExp), 2)));
goto _tailrecursive;
goto tmp3_done;
}
case 28: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,3) == 0) goto tmp3_end;
_inExp = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inExp), 3)));
goto _tailrecursive;
goto tmp3_done;
}
case 29: {
modelica_metatype tmpMeta56;
tmpMeta56 = stringAppend(_OMC_LIT61,omc_Dump_printExpStr(threadData, _inExp));
omc_Error_addInternalError(threadData, tmpMeta56, _OMC_LIT63);
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
_outComponentRefLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRefLst;
}
modelica_metatype boxptr_AbsynUtil_getCrefFromExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _includeSubs, modelica_metatype _includeFunctions)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outComponentRefLst = NULL;
tmp1 = mmc_unbox_integer(_includeSubs);
tmp2 = mmc_unbox_integer(_includeFunctions);
_outComponentRefLst = omc_AbsynUtil_getCrefFromExp(threadData, _inExp, tmp1, tmp2);
return _outComponentRefLst;
}
DLLExport
modelica_metatype omc_AbsynUtil_getCrefsFromSubs(threadData_t *threadData, modelica_metatype _isubs, modelica_boolean _includeSubs, modelica_boolean _includeFunctions)
{
modelica_metatype _crefs = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _isubs;
{
modelica_metatype _crefs1 = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _subs = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,0) == 0) goto tmp3_end;
_subs = tmpMeta8;
_isubs = _subs;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmp4_1);
tmpMeta10 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,1,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
_exp = tmpMeta11;
_subs = tmpMeta10;
_crefs1 = omc_AbsynUtil_getCrefsFromSubs(threadData, _subs, _includeSubs, _includeFunctions);
_crefs = omc_AbsynUtil_getCrefFromExp(threadData, _exp, _includeSubs, _includeFunctions);
tmpMeta1 = listAppend(_crefs, _crefs1);
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
modelica_metatype boxptr_AbsynUtil_getCrefsFromSubs(threadData_t *threadData, modelica_metatype _isubs, modelica_metatype _includeSubs, modelica_metatype _includeFunctions)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _crefs = NULL;
tmp1 = mmc_unbox_integer(_includeSubs);
tmp2 = mmc_unbox_integer(_includeFunctions);
_crefs = omc_AbsynUtil_getCrefsFromSubs(threadData, _isubs, tmp1, tmp2);
return _crefs;
}
DLLExport
modelica_metatype omc_AbsynUtil_removePartialPrefix(threadData_t *threadData, modelica_metatype _inPrefix, modelica_metatype _inPath)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inPrefix;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta1 = omc_AbsynUtil_removePrefix(threadData, _inPrefix, _inPath);
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmp4 += 1;
tmpMeta1 = omc_AbsynUtil_removePrefix(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inPrefix), 3))), _inPath);
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta1 = omc_AbsynUtil_removePartialPrefix(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inPrefix), 2))), _inPath);
goto tmp3_done;
}
case 3: {
tmpMeta1 = _inPath;
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
_outPath = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outPath;
}
DLLExport
modelica_metatype omc_AbsynUtil_removePrefix(threadData_t *threadData, modelica_metatype _prefix_path, modelica_metatype _path)
{
modelica_metatype _newPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _prefix_path;
tmp4_2 = _path;
{
modelica_metatype _p = NULL;
modelica_metatype _p2 = NULL;
modelica_string _id1 = NULL;
modelica_string _id2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_p2 = tmpMeta6;
_p = tmp4_1;
_prefix_path = _p;
_path = _p2;
goto _tailrecursive;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_boolean tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_id1 = tmpMeta7;
_p = tmpMeta8;
_id2 = tmpMeta9;
_p2 = tmpMeta10;
tmp11 = (stringEqual(_id1, _id2));
if (1 != tmp11) goto goto_2;
_prefix_path = _p;
_path = _p2;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_boolean tmp15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_id1 = tmpMeta12;
_id2 = tmpMeta13;
_p2 = tmpMeta14;
tmp15 = (stringEqual(_id1, _id2));
if (1 != tmp15) goto goto_2;
tmpMeta1 = _p2;
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
_newPath = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _newPath;
}
DLLExport
modelica_boolean omc_AbsynUtil_pathPrefixOf(threadData_t *threadData, modelica_metatype _prefixPath, modelica_metatype _path)
{
modelica_boolean _isPrefix;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _prefixPath;
tmp4_2 = _path;
{
modelica_metatype _p = NULL;
modelica_metatype _p2 = NULL;
modelica_string _id = NULL;
modelica_string _id2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta6;
_p2 = tmp4_2;
_prefixPath = _p;
_path = _p2;
goto _tailrecursive;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_p2 = tmpMeta7;
_p = tmp4_1;
_prefixPath = _p;
_path = _p2;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_id = tmpMeta8;
_id2 = tmpMeta9;
tmp1 = (stringEqual(_id, _id2));
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_id = tmpMeta10;
_id2 = tmpMeta11;
tmp1 = (stringEqual(_id, _id2));
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_id = tmpMeta12;
_p = tmpMeta13;
_id2 = tmpMeta14;
_p2 = tmpMeta15;
tmp1 = ((stringEqual(_id, _id2)) && omc_AbsynUtil_pathPrefixOf(threadData, _p, _p2));
goto tmp3_done;
}
case 5: {
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
modelica_metatype boxptr_AbsynUtil_pathPrefixOf(threadData_t *threadData, modelica_metatype _prefixPath, modelica_metatype _path)
{
modelica_boolean _isPrefix;
modelica_metatype out_isPrefix;
_isPrefix = omc_AbsynUtil_pathPrefixOf(threadData, _prefixPath, _path);
out_isPrefix = mmc_mk_icon(_isPrefix);
return out_isPrefix;
}
DLLExport
modelica_metatype omc_AbsynUtil_crefReplaceFirstIdent(threadData_t *threadData, modelica_metatype _icref, modelica_metatype _replPath)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _icref;
{
modelica_metatype _subs = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _cref = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cr = tmpMeta5;
_cr = omc_AbsynUtil_crefReplaceFirstIdent(threadData, _cr, _replPath);
tmpMeta1 = omc_AbsynUtil_crefMakeFullyQualified(threadData, _cr);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_subs = tmpMeta6;
_cr = tmpMeta7;
_cref = omc_AbsynUtil_pathToCref(threadData, _replPath);
_cref = omc_AbsynUtil_addSubscriptsLast(threadData, _cref, _subs);
tmpMeta1 = omc_AbsynUtil_joinCrefs(threadData, _cref, _cr);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_subs = tmpMeta8;
_cref = omc_AbsynUtil_pathToCref(threadData, _replPath);
tmpMeta1 = omc_AbsynUtil_addSubscriptsLast(threadData, _cref, _subs);
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
DLLExport
modelica_metatype omc_AbsynUtil_crefReplaceFirst(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _replacement)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cref;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
tmpMeta1 = _replacement;
goto tmp3_done;
}
case 4: {
tmpMeta1 = omc_AbsynUtil_joinCrefs(threadData, _replacement, omc_AbsynUtil_crefStripFirst(threadData, _cref));
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta5;
tmpMeta5 = mmc_mk_box2(3, &Absyn_ComponentRef_CREF__FULLYQUALIFIED__desc, omc_AbsynUtil_crefReplaceFirst(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2))), _replacement));
tmpMeta1 = tmpMeta5;
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
DLLExport
modelica_metatype omc_AbsynUtil_addSubscriptsLast(threadData_t *threadData, modelica_metatype _icr, modelica_metatype _i)
{
modelica_metatype _ocr = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _icr;
{
modelica_metatype _subs = NULL;
modelica_string _id = NULL;
modelica_metatype _cr = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_id = tmpMeta5;
_subs = tmpMeta6;
tmpMeta7 = mmc_mk_box3(5, &Absyn_ComponentRef_CREF__IDENT__desc, _id, listAppend(_subs, _i));
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id = tmpMeta8;
_subs = tmpMeta9;
_cr = tmpMeta10;
_cr = omc_AbsynUtil_addSubscriptsLast(threadData, _cr, _i);
tmpMeta11 = mmc_mk_box4(4, &Absyn_ComponentRef_CREF__QUAL__desc, _id, _subs, _cr);
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cr = tmpMeta12;
_cr = omc_AbsynUtil_addSubscriptsLast(threadData, _cr, _i);
tmpMeta1 = omc_AbsynUtil_crefMakeFullyQualified(threadData, _cr);
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
_ocr = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _ocr;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_pathToStringListWork(threadData_t *threadData, modelica_metatype _path, modelica_metatype _acc)
{
modelica_metatype _outPaths = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _path;
{
modelica_string _n = NULL;
modelica_metatype _p = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_n = tmpMeta5;
tmpMeta6 = mmc_mk_cons(_n, _acc);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta7;
_path = _p;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_n = tmpMeta8;
_p = tmpMeta9;
tmpMeta10 = mmc_mk_cons(_n, _acc);
_path = _p;
_acc = tmpMeta10;
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
_outPaths = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outPaths;
}
DLLExport
modelica_metatype omc_AbsynUtil_pathToStringList(threadData_t *threadData, modelica_metatype _path)
{
modelica_metatype _outPaths = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outPaths = listReverse(omc_AbsynUtil_pathToStringListWork(threadData, _path, tmpMeta1));
_return: OMC_LABEL_UNUSED
return _outPaths;
}
DLLExport
modelica_boolean omc_AbsynUtil_pathSuffixOfr(threadData_t *threadData, modelica_metatype _path, modelica_metatype _suffix_path)
{
modelica_boolean _res;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = omc_AbsynUtil_pathSuffixOf(threadData, _suffix_path, _path);
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_AbsynUtil_pathSuffixOfr(threadData_t *threadData, modelica_metatype _path, modelica_metatype _suffix_path)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_AbsynUtil_pathSuffixOfr(threadData, _path, _suffix_path);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_boolean omc_AbsynUtil_pathSuffixOf(threadData_t *threadData, modelica_metatype _suffix_path, modelica_metatype _path)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _path;
{
modelica_metatype _p = NULL;
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
tmp6 = omc_AbsynUtil_pathEqual(threadData, _suffix_path, _path);
if (1 != tmp6) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta7;
tmp4 += 1;
tmp1 = omc_AbsynUtil_pathSuffixOf(threadData, _suffix_path, _p);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_p = tmpMeta8;
tmp1 = omc_AbsynUtil_pathSuffixOf(threadData, _suffix_path, _p);
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_AbsynUtil_pathSuffixOf(threadData_t *threadData, modelica_metatype _suffix_path, modelica_metatype _path)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_AbsynUtil_pathSuffixOf(threadData, _suffix_path, _path);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_metatype omc_AbsynUtil_suffixPath(threadData_t *threadData, modelica_metatype _inPath, modelica_string _inSuffix)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPath;
{
modelica_string _name = NULL;
modelica_metatype _path = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_name = tmpMeta5;
tmpMeta6 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _inSuffix);
tmpMeta7 = mmc_mk_box3(3, &Absyn_Path_QUALIFIED__desc, _name, tmpMeta6);
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_name = tmpMeta8;
_path = tmpMeta9;
_path = omc_AbsynUtil_suffixPath(threadData, _path, _inSuffix);
tmpMeta10 = mmc_mk_box3(3, &Absyn_Path_QUALIFIED__desc, _name, _path);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_path = tmpMeta11;
_path = omc_AbsynUtil_suffixPath(threadData, _path, _inSuffix);
tmpMeta12 = mmc_mk_box2(5, &Absyn_Path_FULLYQUALIFIED__desc, _path);
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
_outPath = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outPath;
}
DLLExport
modelica_metatype omc_AbsynUtil_prefixPath(threadData_t *threadData, modelica_string _prefix, modelica_metatype _path)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box3(3, &Absyn_Path_QUALIFIED__desc, _prefix, _path);
_outPath = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outPath;
}
DLLExport
modelica_metatype omc_AbsynUtil_pathPrefix(threadData_t *threadData, modelica_metatype _path)
{
modelica_metatype _prefix = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _path;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
_path = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2)));
goto _tailrecursive;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,1) == 0) goto tmp3_end;
tmpMeta7 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2))));
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta8 = mmc_mk_box3(3, &Absyn_Path_QUALIFIED__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2))), omc_AbsynUtil_pathPrefix(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 3)))));
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
_prefix = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _prefix;
}
DLLExport
modelica_metatype omc_AbsynUtil_pathStripSamePrefix(threadData_t *threadData, modelica_metatype _inPath1, modelica_metatype _inPath2)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_string _ident1 = NULL;
modelica_string _ident2 = NULL;
modelica_metatype _path1 = NULL;
modelica_metatype _path2 = NULL;
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
_ident1 = omc_AbsynUtil_pathFirstIdent(threadData, _inPath1);
_ident2 = omc_AbsynUtil_pathFirstIdent(threadData, _inPath2);
tmp6 = (stringEqual(_ident1, _ident2));
if (1 != tmp6) goto goto_2;
_path1 = omc_AbsynUtil_pathRest(threadData, _inPath1);
_path2 = omc_AbsynUtil_pathRest(threadData, _inPath2);
tmpMeta1 = omc_AbsynUtil_pathStripSamePrefix(threadData, _path1, _path2);
goto tmp3_done;
}
case 1: {
tmpMeta1 = _inPath1;
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
_outPath = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outPath;
}
DLLExport
modelica_metatype omc_AbsynUtil_pathRest(threadData_t *threadData, modelica_metatype _inPath)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPath;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_outPath = tmpMeta6;
tmpMeta1 = _outPath;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_outPath = tmpMeta7;
_inPath = _outPath;
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
DLLExport
modelica_metatype omc_AbsynUtil_pathSetNthIdent(threadData_t *threadData, modelica_metatype _path, modelica_string _ident, modelica_integer _n)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if((_n == ((modelica_integer) 1)))
{
_outPath = omc_AbsynUtil_pathSetFirstIdent(threadData, _path, _ident);
}
else
{
{
modelica_metatype tmp4_1;
tmp4_1 = _path;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = mmc_mk_box3(3, &Absyn_Path_QUALIFIED__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2))), omc_AbsynUtil_pathSetNthIdent(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 3))), _ident, ((modelica_integer) -1) + _n));
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta7 = mmc_mk_box2(5, &Absyn_Path_FULLYQUALIFIED__desc, omc_AbsynUtil_pathSetNthIdent(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2))), _ident, _n));
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
_outPath = tmpMeta1;
}
_return: OMC_LABEL_UNUSED
return _outPath;
}
modelica_metatype boxptr_AbsynUtil_pathSetNthIdent(threadData_t *threadData, modelica_metatype _path, modelica_metatype _ident, modelica_metatype _n)
{
modelica_integer tmp1;
modelica_metatype _outPath = NULL;
tmp1 = mmc_unbox_integer(_n);
_outPath = omc_AbsynUtil_pathSetNthIdent(threadData, _path, _ident, tmp1);
return _outPath;
}
DLLExport
modelica_string omc_AbsynUtil_pathNthIdent(threadData_t *threadData, modelica_metatype _path, modelica_integer _n)
{
modelica_string _ident = NULL;
modelica_metatype _p = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_p = omc_AbsynUtil_makeNotFullyQualified(threadData, _path);
tmp3 = ((modelica_integer) 2); tmp4 = 1; tmp5 = _n;
if(!(((tmp4 > 0) && (tmp3 > tmp5)) || ((tmp4 < 0) && (tmp3 < tmp5))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 2); in_range_integer(_i, tmp3, tmp5); _i += tmp4)
{
tmpMeta1 = _p;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,0,2) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_p = tmpMeta2;
}
}
_ident = omc_AbsynUtil_pathFirstIdent(threadData, _p);
_return: OMC_LABEL_UNUSED
return _ident;
}
modelica_metatype boxptr_AbsynUtil_pathNthIdent(threadData_t *threadData, modelica_metatype _path, modelica_metatype _n)
{
modelica_integer tmp1;
modelica_string _ident = NULL;
tmp1 = mmc_unbox_integer(_n);
_ident = omc_AbsynUtil_pathNthIdent(threadData, _path, tmp1);
return _ident;
}
DLLExport
modelica_string omc_AbsynUtil_pathSecondIdent(threadData_t *threadData, modelica_metatype _inPath)
{
modelica_string _outIdent = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPath;
{
modelica_string _n = NULL;
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_n = tmpMeta7;
tmp1 = _n;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
_n = tmpMeta9;
tmp1 = _n;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta10;
_inPath = _p;
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
_outIdent = tmp1;
_return: OMC_LABEL_UNUSED
return _outIdent;
}
DLLExport
modelica_metatype omc_AbsynUtil_pathFirstPath(threadData_t *threadData, modelica_metatype _path)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _path;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
tmpMeta1 = _path;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta5;
tmpMeta5 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2))));
tmpMeta1 = tmpMeta5;
goto tmp3_done;
}
case 5: {
_path = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2)));
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
DLLExport
modelica_metatype omc_AbsynUtil_pathSetFirstIdent(threadData_t *threadData, modelica_metatype _path, modelica_string _ident)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _path;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
modelica_metatype tmpMeta5;
tmpMeta5 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _ident);
tmpMeta1 = tmpMeta5;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta6;
tmpMeta6 = mmc_mk_box3(3, &Absyn_Path_QUALIFIED__desc, _ident, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 3))));
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta7;
tmpMeta7 = mmc_mk_box2(5, &Absyn_Path_FULLYQUALIFIED__desc, omc_AbsynUtil_pathSetFirstIdent(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2))), _ident));
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
_outPath = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outPath;
}
DLLExport
modelica_string omc_AbsynUtil_pathFirstIdent(threadData_t *threadData, modelica_metatype _path)
{
modelica_string _outIdent = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _path;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
_path = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2)));
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
tmp1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2)));
goto tmp3_done;
}
case 4: {
tmp1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2)));
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
_outIdent = tmp1;
_return: OMC_LABEL_UNUSED
return _outIdent;
}
DLLExport
modelica_metatype omc_AbsynUtil_pathLast(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fpath)
{
modelica_metatype _path = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_path = __omcQ_24in_5Fpath;
{
modelica_metatype tmp4_1;
tmp4_1 = _path;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
__omcQ_24in_5Fpath = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 3)));
goto _tailrecursive;
goto tmp3_done;
}
case 4: {
tmpMeta1 = _path;
goto tmp3_done;
}
case 5: {
__omcQ_24in_5Fpath = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2)));
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
_path = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _path;
}
DLLExport
modelica_metatype omc_AbsynUtil_pathSetLastIdent(threadData_t *threadData, modelica_metatype _path, modelica_string _ident)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _path;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
modelica_metatype tmpMeta5;
tmpMeta5 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _ident);
tmpMeta1 = tmpMeta5;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta6;
tmpMeta6 = mmc_mk_box3(3, &Absyn_Path_QUALIFIED__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2))), omc_AbsynUtil_pathSetLastIdent(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 3))), _ident));
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta7;
tmpMeta7 = mmc_mk_box2(5, &Absyn_Path_FULLYQUALIFIED__desc, omc_AbsynUtil_pathSetLastIdent(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2))), _ident));
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
_outPath = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outPath;
}
DLLExport
modelica_string omc_AbsynUtil_pathLastIdent(threadData_t *threadData, modelica_metatype _path)
{
modelica_string _outIdent = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _path;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
_path = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 3)));
goto _tailrecursive;
goto tmp3_done;
}
case 4: {
tmp1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2)));
goto tmp3_done;
}
case 5: {
_path = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2)));
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
_outIdent = tmp1;
_return: OMC_LABEL_UNUSED
return _outIdent;
}
DLLExport
modelica_metatype omc_AbsynUtil_stringListPathReversed(threadData_t *threadData, modelica_metatype _inStrings)
{
modelica_metatype _outPath = NULL;
modelica_string _id = NULL;
modelica_metatype _rest_str = NULL;
modelica_metatype _path = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inStrings;
if (listEmpty(tmpMeta1)) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_CAR(tmpMeta1);
tmpMeta3 = MMC_CDR(tmpMeta1);
_id = tmpMeta2;
_rest_str = tmpMeta3;
tmpMeta4 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _id);
_outPath = tmpMeta4;
{
modelica_metatype _s;
for (tmpMeta5 = _rest_str; !listEmpty(tmpMeta5); tmpMeta5=MMC_CDR(tmpMeta5))
{
_s = MMC_CAR(tmpMeta5);
tmpMeta6 = mmc_mk_box3(3, &Absyn_Path_QUALIFIED__desc, _s, _outPath);
_outPath = tmpMeta6;
}
}
_return: OMC_LABEL_UNUSED
return _outPath;
}
DLLExport
modelica_metatype omc_AbsynUtil_stringListPath(threadData_t *threadData, modelica_metatype _paths)
{
modelica_metatype _qualifiedPath = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_qualifiedPath = omc_AbsynUtil_stringListPathReversed(threadData, listReverse(_paths));
_return: OMC_LABEL_UNUSED
return _qualifiedPath;
}
DLLExport
modelica_metatype omc_AbsynUtil_stringPath(threadData_t *threadData, modelica_string _str)
{
modelica_metatype _qualifiedPath = NULL;
modelica_metatype _paths = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_paths = omc_Util_stringSplitAtChar(threadData, _str, _OMC_LIT7);
_qualifiedPath = omc_AbsynUtil_stringListPath(threadData, _paths);
_return: OMC_LABEL_UNUSED
return _qualifiedPath;
}
DLLExport
modelica_string omc_AbsynUtil_pathStringUnquoteReplaceDot(threadData_t *threadData, modelica_metatype _inPath, modelica_string _repStr)
{
modelica_string _outString = NULL;
modelica_metatype _strlst = NULL;
modelica_string _rep_rep = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = stringAppend(_repStr,_repStr);
_rep_rep = tmpMeta1;
_strlst = omc_AbsynUtil_pathToStringList(threadData, _inPath);
_strlst = omc_List_map2(threadData, _strlst, boxvar_System_stringReplace, _repStr, _rep_rep);
_strlst = omc_List_map(threadData, _strlst, boxvar_System_unquoteIdentifier);
_outString = stringDelimitList(_strlst, _repStr);
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_AbsynUtil_optPathString(threadData_t *threadData, modelica_metatype _inPathOption)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPathOption;
{
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
tmp1 = _OMC_LIT12;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_p = tmpMeta6;
tmp1 = omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT7, 1, 0);
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
modelica_integer omc_AbsynUtil_pathHashModWork(threadData_t *threadData, modelica_metatype _path, modelica_integer _acc)
{
modelica_integer _hash;
modelica_integer tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _path;
{
modelica_metatype _p = NULL;
modelica_string _s = NULL;
modelica_integer _i;
modelica_integer _i2;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta5;
_path = _p;
_acc = ((modelica_integer) 46) + (((modelica_integer) 31)) * (_acc);
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_s = tmpMeta6;
_p = tmpMeta7;
_i = stringHashDjb2(_s);
_i2 = ((modelica_integer) 46) + (((modelica_integer) 31)) * (_acc);
_path = _p;
_acc = (((modelica_integer) 31)) * (_i2) + _i;
goto _tailrecursive;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_s = tmpMeta8;
_i = stringHashDjb2(_s);
_i2 = ((modelica_integer) 46) + (((modelica_integer) 31)) * (_acc);
tmp1 = (((modelica_integer) 31)) * (_i2) + _i;
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
modelica_metatype boxptr_AbsynUtil_pathHashModWork(threadData_t *threadData, modelica_metatype _path, modelica_metatype _acc)
{
modelica_integer tmp1;
modelica_integer _hash;
modelica_metatype out_hash;
tmp1 = mmc_unbox_integer(_acc);
_hash = omc_AbsynUtil_pathHashModWork(threadData, _path, tmp1);
out_hash = mmc_mk_icon(_hash);
return out_hash;
}
DLLExport
modelica_integer omc_AbsynUtil_pathHashMod(threadData_t *threadData, modelica_metatype _path, modelica_integer _mod)
{
modelica_integer _hash;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_hash = labs(modelica_integer_mod(omc_AbsynUtil_pathHashModWork(threadData, _path, ((modelica_integer) 5381)), _mod));
_return: OMC_LABEL_UNUSED
return _hash;
}
modelica_metatype boxptr_AbsynUtil_pathHashMod(threadData_t *threadData, modelica_metatype _path, modelica_metatype _mod)
{
modelica_integer tmp1;
modelica_integer _hash;
modelica_metatype out_hash;
tmp1 = mmc_unbox_integer(_mod);
_hash = omc_AbsynUtil_pathHashMod(threadData, _path, tmp1);
out_hash = mmc_mk_icon(_hash);
return out_hash;
}
DLLExport
modelica_integer omc_AbsynUtil_pathCompareNoQual(threadData_t *threadData, modelica_metatype _ip1, modelica_metatype _ip2)
{
modelica_integer _o;
modelica_integer tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _ip1;
tmp4_2 = _ip2;
{
modelica_metatype _p1 = NULL;
modelica_metatype _p2 = NULL;
modelica_string _i1 = NULL;
modelica_string _i2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p1 = tmpMeta6;
_p2 = tmp4_2;
_ip1 = _p1;
_ip2 = _p2;
goto _tailrecursive;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_p2 = tmpMeta7;
_p1 = tmp4_1;
_ip1 = _p1;
_ip2 = _p2;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_i1 = tmpMeta8;
_p1 = tmpMeta9;
_i2 = tmpMeta10;
_p2 = tmpMeta11;
_o = stringCompare(_i1, _i2);
tmp1 = ((_o == ((modelica_integer) 0))?omc_AbsynUtil_pathCompare(threadData, _p1, _p2):_o);
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 1);
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) -1);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_i1 = tmpMeta12;
_i2 = tmpMeta13;
tmp1 = stringCompare(_i1, _i2);
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
_o = tmp1;
_return: OMC_LABEL_UNUSED
return _o;
}
modelica_metatype boxptr_AbsynUtil_pathCompareNoQual(threadData_t *threadData, modelica_metatype _ip1, modelica_metatype _ip2)
{
modelica_integer _o;
modelica_metatype out_o;
_o = omc_AbsynUtil_pathCompareNoQual(threadData, _ip1, _ip2);
out_o = mmc_mk_icon(_o);
return out_o;
}
DLLExport
modelica_integer omc_AbsynUtil_pathCompare(threadData_t *threadData, modelica_metatype _ip1, modelica_metatype _ip2)
{
modelica_integer _o;
modelica_integer tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _ip1;
tmp4_2 = _ip2;
{
modelica_metatype _p1 = NULL;
modelica_metatype _p2 = NULL;
modelica_string _i1 = NULL;
modelica_string _i2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 7; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_p1 = tmpMeta6;
_p2 = tmpMeta7;
_ip1 = _p1;
_ip2 = _p2;
goto _tailrecursive;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 1);
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) -1);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_boolean tmp12;
modelica_integer tmp13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_i1 = tmpMeta8;
_p1 = tmpMeta9;
_i2 = tmpMeta10;
_p2 = tmpMeta11;
_o = stringCompare(_i1, _i2);
tmp12 = (modelica_boolean)(_o == ((modelica_integer) 0));
if(tmp12)
{
_ip1 = _p1;
_ip2 = _p2;
goto _tailrecursive;
}
else
{
tmp13 = _o;
}
tmp1 = tmp13;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 1);
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) -1);
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_i1 = tmpMeta14;
_i2 = tmpMeta15;
tmp1 = stringCompare(_i1, _i2);
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
_o = tmp1;
_return: OMC_LABEL_UNUSED
return _o;
}
modelica_metatype boxptr_AbsynUtil_pathCompare(threadData_t *threadData, modelica_metatype _ip1, modelica_metatype _ip2)
{
modelica_integer _o;
modelica_metatype out_o;
_o = omc_AbsynUtil_pathCompare(threadData, _ip1, _ip2);
out_o = mmc_mk_icon(_o);
return out_o;
}
DLLExport
modelica_boolean omc_AbsynUtil_classNameGreater(threadData_t *threadData, modelica_metatype _c1, modelica_metatype _c2)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = (stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_c1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_c2), 2)))) > ((modelica_integer) 0));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_AbsynUtil_classNameGreater(threadData_t *threadData, modelica_metatype _c1, modelica_metatype _c2)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_AbsynUtil_classNameGreater(threadData, _c1, _c2);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_integer omc_AbsynUtil_classNameCompare(threadData_t *threadData, modelica_metatype _c1, modelica_metatype _c2)
{
modelica_integer _o;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_o = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_c1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_c2), 2))));
_return: OMC_LABEL_UNUSED
return _o;
}
modelica_metatype boxptr_AbsynUtil_classNameCompare(threadData_t *threadData, modelica_metatype _c1, modelica_metatype _c2)
{
modelica_integer _o;
modelica_metatype out_o;
_o = omc_AbsynUtil_classNameCompare(threadData, _c1, _c2);
out_o = mmc_mk_icon(_o);
return out_o;
}
DLLExport
modelica_string omc_AbsynUtil_pathStringDefault(threadData_t *threadData, modelica_metatype _path)
{
modelica_string _s = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_s = omc_AbsynUtil_pathString(threadData, _path, _OMC_LIT7, 1, 0);
_return: OMC_LABEL_UNUSED
return _s;
}
DLLExport
modelica_string omc_AbsynUtil_pathStringNoQual(threadData_t *threadData, modelica_metatype _path, modelica_string _delimiter, modelica_boolean _usefq, modelica_boolean _reverse)
{
modelica_string _s = NULL;
modelica_metatype _p1 = NULL;
modelica_metatype _p2 = NULL;
modelica_integer _count;
modelica_integer _len;
modelica_integer _dlen;
modelica_boolean _b;
modelica_integer tmp5_c1 __attribute__((unused)) = 0;
modelica_integer tmp5_c2 __attribute__((unused)) = 0;
modelica_boolean tmp5_c3 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_count = ((modelica_integer) 0);
_len = ((modelica_integer) 0);
_dlen = stringLength(_delimiter);
_p1 = (_usefq?_path:omc_AbsynUtil_makeNotFullyQualified(threadData, _path));
{
modelica_metatype tmp3_1;
tmp3_1 = _p1;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
_s = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p1), 2)));
goto _return;
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
_p2 = _p1;
_b = 1;
while(1)
{
if(!_b) break;
{
modelica_metatype tmp8_1;
tmp8_1 = _p2;
{
int tmp8;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp8_1))) {
case 4: {
tmpMeta[0+0] = _p2;
tmp5_c1 = ((modelica_integer) 1) + _len;
tmp5_c2 = _count + stringLength((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p2), 2))));
tmp5_c3 = 0;
goto tmp7_done;
}
case 3: {
tmpMeta[0+0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p2), 3)));
tmp5_c1 = ((modelica_integer) 1) + _len;
tmp5_c2 = _count + stringLength((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p2), 2))));
tmp5_c3 = 1;
goto tmp7_done;
}
case 5: {
tmpMeta[0+0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p2), 2)));
tmp5_c1 = ((modelica_integer) 1) + _len;
tmp5_c2 = _count;
tmp5_c3 = 1;
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
_p2 = tmpMeta[0+0];
_len = tmp5_c1;
_count = tmp5_c2;
_b = tmp5_c3;
}
_s = omc_AbsynUtil_pathStringWork(threadData, _p1, (((modelica_integer) -1) + _len) * (_dlen) + _count, _delimiter, _dlen, _reverse);
_return: OMC_LABEL_UNUSED
return _s;
}
modelica_metatype boxptr_AbsynUtil_pathStringNoQual(threadData_t *threadData, modelica_metatype _path, modelica_metatype _delimiter, modelica_metatype _usefq, modelica_metatype _reverse)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_string _s = NULL;
tmp1 = mmc_unbox_integer(_usefq);
tmp2 = mmc_unbox_integer(_reverse);
_s = omc_AbsynUtil_pathStringNoQual(threadData, _path, _delimiter, tmp1, tmp2);
return _s;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_AbsynUtil_pathStringWork(threadData_t *threadData, modelica_metatype _inPath, modelica_integer _len, modelica_string _delimiter, modelica_integer _dlen, modelica_boolean _reverse)
{
modelica_string _s = NULL;
modelica_metatype _p = NULL;
modelica_boolean _b;
modelica_integer _count;
modelica_complex _sb;
modelica_integer tmp1_c1 __attribute__((unused)) = 0;
modelica_boolean tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_s = _OMC_LIT12;
_p = _inPath;
_b = 1;
_count = ((modelica_integer) 0);
_sb = omc_System_StringAllocator_constructor(threadData, _len);
while(1)
{
if(!_b) break;
{
modelica_metatype tmp4_1;
tmp4_1 = _p;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
omc_System_stringAllocatorStringCopy(threadData, _sb, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2))), (_reverse?_len + (-_count) - stringLength((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2)))):_count));
tmpMeta[0+0] = _p;
tmp1_c1 = _count + stringLength((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2))));
tmp1_c2 = 0;
goto tmp3_done;
}
case 3: {
omc_System_stringAllocatorStringCopy(threadData, _sb, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2))), (_reverse?_len + (-_dlen) - stringLength((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2)))) - _count:_count));
omc_System_stringAllocatorStringCopy(threadData, _sb, _delimiter, (_reverse?_len + (-_count) - _dlen:_count + stringLength((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2))))));
tmpMeta[0+0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 3)));
tmp1_c1 = _count + stringLength((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2)))) + _dlen;
tmp1_c2 = 1;
goto tmp3_done;
}
case 5: {
omc_System_stringAllocatorStringCopy(threadData, _sb, _delimiter, (_reverse?_len + (-_count) - _dlen:_count));
tmpMeta[0+0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2)));
tmp1_c1 = _count + _dlen;
tmp1_c2 = 1;
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
_p = tmpMeta[0+0];
_count = tmp1_c1;
_b = tmp1_c2;
}
_s = omc_System_stringAllocatorResult(threadData, _sb, _s);
_return: OMC_LABEL_UNUSED
omc_System_StringAllocator_destructor(threadData,_sb);
return _s;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynUtil_pathStringWork(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _len, modelica_metatype _delimiter, modelica_metatype _dlen, modelica_metatype _reverse)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_string _s = NULL;
tmp1 = mmc_unbox_integer(_len);
tmp2 = mmc_unbox_integer(_dlen);
tmp3 = mmc_unbox_integer(_reverse);
_s = omc_AbsynUtil_pathStringWork(threadData, _inPath, tmp1, _delimiter, tmp2, tmp3);
return _s;
}
DLLExport
modelica_string omc_AbsynUtil_pathString(threadData_t *threadData, modelica_metatype _path, modelica_string _delimiter, modelica_boolean _usefq, modelica_boolean _reverse)
{
modelica_string _s = NULL;
modelica_metatype _p1 = NULL;
modelica_metatype _p2 = NULL;
modelica_integer _count;
modelica_integer _len;
modelica_integer _dlen;
modelica_boolean _b;
modelica_integer tmp5_c1 __attribute__((unused)) = 0;
modelica_integer tmp5_c2 __attribute__((unused)) = 0;
modelica_boolean tmp5_c3 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_count = ((modelica_integer) 0);
_len = ((modelica_integer) 0);
_dlen = stringLength(_delimiter);
_p1 = (_usefq?_path:omc_AbsynUtil_makeNotFullyQualified(threadData, _path));
{
modelica_metatype tmp3_1;
tmp3_1 = _p1;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
_s = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p1), 2)));
goto _return;
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
_p2 = _p1;
_b = 1;
while(1)
{
if(!_b) break;
{
modelica_metatype tmp8_1;
tmp8_1 = _p2;
{
int tmp8;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp8_1))) {
case 4: {
tmpMeta[0+0] = _p2;
tmp5_c1 = ((modelica_integer) 1) + _len;
tmp5_c2 = _count + stringLength((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p2), 2))));
tmp5_c3 = 0;
goto tmp7_done;
}
case 3: {
tmpMeta[0+0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p2), 3)));
tmp5_c1 = ((modelica_integer) 1) + _len;
tmp5_c2 = _count + stringLength((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p2), 2))));
tmp5_c3 = 1;
goto tmp7_done;
}
case 5: {
tmpMeta[0+0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p2), 2)));
tmp5_c1 = ((modelica_integer) 1) + _len;
tmp5_c2 = _count;
tmp5_c3 = 1;
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
_p2 = tmpMeta[0+0];
_len = tmp5_c1;
_count = tmp5_c2;
_b = tmp5_c3;
}
_s = omc_AbsynUtil_pathStringWork(threadData, _p1, (((modelica_integer) -1) + _len) * (_dlen) + _count, _delimiter, _dlen, _reverse);
_return: OMC_LABEL_UNUSED
return _s;
}
modelica_metatype boxptr_AbsynUtil_pathString(threadData_t *threadData, modelica_metatype _path, modelica_metatype _delimiter, modelica_metatype _usefq, modelica_metatype _reverse)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_string _s = NULL;
tmp1 = mmc_unbox_integer(_usefq);
tmp2 = mmc_unbox_integer(_reverse);
_s = omc_AbsynUtil_pathString(threadData, _path, _delimiter, tmp1, tmp2);
return _s;
}
DLLExport
modelica_metatype omc_AbsynUtil_typeSpecDimensions(threadData_t *threadData, modelica_metatype _inTypeSpec)
{
modelica_metatype _outDimensions = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inTypeSpec;
{
modelica_metatype _dim = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (optionNone(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
_dim = tmpMeta7;
tmpMeta1 = _dim;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (optionNone(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 1));
_dim = tmpMeta9;
tmpMeta1 = _dim;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta10;
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
_outDimensions = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outDimensions;
}
DLLExport
modelica_metatype omc_AbsynUtil_typeSpecPath(threadData_t *threadData, modelica_metatype _tp)
{
modelica_metatype _op = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _tp;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_tp), 2)));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_tp), 2)));
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
_op = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _op;
}
DLLExport
modelica_string omc_AbsynUtil_typeSpecPathString(threadData_t *threadData, modelica_metatype _tp)
{
modelica_string _s = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_s = omc_AbsynUtil_pathString(threadData, omc_AbsynUtil_typeSpecPath(threadData, _tp), _OMC_LIT7, 1, 0);
_return: OMC_LABEL_UNUSED
return _s;
}
DLLExport
modelica_boolean omc_AbsynUtil_optArrayDimEqual(threadData_t *threadData, modelica_metatype _oad1, modelica_metatype _oad2)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _oad1;
tmp4_2 = _oad2;
{
modelica_metatype _ad1 = NULL;
modelica_metatype _ad2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
_ad1 = tmpMeta6;
_ad2 = tmpMeta7;
tmp1 = omc_List_isEqualOnTrue(threadData, _ad1, _ad2, boxvar_AbsynUtil_subscriptEqual);
goto tmp3_done;
}
case 1: {
if (!optionNone(tmp4_1)) goto tmp3_end;
if (!optionNone(tmp4_2)) goto tmp3_end;
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
modelica_metatype boxptr_AbsynUtil_optArrayDimEqual(threadData_t *threadData, modelica_metatype _oad1, modelica_metatype _oad2)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_AbsynUtil_optArrayDimEqual(threadData, _oad1, _oad2);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_AbsynUtil_typeSpecEqual(threadData_t *threadData, modelica_metatype _a, modelica_metatype _b)
{
modelica_boolean _ob;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _a;
tmp4_2 = _b;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmp1 = (omc_AbsynUtil_pathEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_a), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_b), 2)))) && omc_AbsynUtil_optArrayDimEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_a), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_b), 3)))));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmp1 = ((omc_AbsynUtil_pathEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_a), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_b), 2)))) && omc_List_isEqualOnTrue(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_a), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_b), 3))), boxvar_AbsynUtil_typeSpecEqual)) && omc_AbsynUtil_optArrayDimEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_a), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_b), 4)))));
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
modelica_metatype boxptr_AbsynUtil_typeSpecEqual(threadData_t *threadData, modelica_metatype _a, modelica_metatype _b)
{
modelica_boolean _ob;
modelica_metatype out_ob;
_ob = omc_AbsynUtil_typeSpecEqual(threadData, _a, _b);
out_ob = mmc_mk_icon(_ob);
return out_ob;
}
DLLExport
modelica_boolean omc_AbsynUtil_pathEqualCaseInsensitive(threadData_t *threadData, modelica_metatype _path1, modelica_metatype _path2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _path1;
tmp4_2 = _path2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
_path1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path1), 2)));
goto _tailrecursive;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
_path2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path2), 2)));
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmp1 = (stringEqual(omc_System_tolower(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path1), 2)))), omc_System_tolower(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path2), 2))))));
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmp1 = ((stringEqual(omc_System_tolower(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path1), 2)))), omc_System_tolower(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path2), 2)))))) && omc_AbsynUtil_pathEqualCaseInsensitive(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path1), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path2), 3)))));
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
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
modelica_metatype boxptr_AbsynUtil_pathEqualCaseInsensitive(threadData_t *threadData, modelica_metatype _path1, modelica_metatype _path2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_AbsynUtil_pathEqualCaseInsensitive(threadData, _path1, _path2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_boolean omc_AbsynUtil_pathEqual(threadData_t *threadData, modelica_metatype _path1, modelica_metatype _path2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _path1;
tmp4_2 = _path2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
_path1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path1), 2)));
goto _tailrecursive;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
_path2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path2), 2)));
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmp1 = (stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path2), 2)))));
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmp1 = ((stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path2), 2))))) && omc_AbsynUtil_pathEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path1), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path2), 3)))));
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
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
modelica_metatype boxptr_AbsynUtil_pathEqual(threadData_t *threadData, modelica_metatype _path1, modelica_metatype _path2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_AbsynUtil_pathEqual(threadData, _path1, _path2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_metatype omc_AbsynUtil_crefExp(threadData_t *threadData, modelica_metatype _cr)
{
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box2(5, &Absyn_Exp_CREF__desc, _cr);
_exp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _exp;
}
DLLExport
modelica_metatype omc_AbsynUtil_expCref(threadData_t *threadData, modelica_metatype _exp)
{
modelica_metatype _cr = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _exp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,2,1) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_cr = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _cr;
}
DLLExport
modelica_string omc_AbsynUtil_expString(threadData_t *threadData, modelica_metatype _exp)
{
modelica_string _str = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _exp;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,3,1) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_str = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _str;
}
DLLExport
modelica_string omc_AbsynUtil_printImportString(threadData_t *threadData, modelica_metatype _imp)
{
modelica_string _ostring = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _imp;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_imp), 2)));
goto tmp3_done;
}
case 4: {
tmp1 = omc_AbsynUtil_pathString(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_imp), 2))), _OMC_LIT7, 1, 0);
goto tmp3_done;
}
case 5: {
tmp1 = omc_AbsynUtil_pathString(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_imp), 2))), _OMC_LIT7, 1, 0);
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
_ostring = tmp1;
_return: OMC_LABEL_UNUSED
return _ostring;
}
DLLExport
modelica_boolean omc_AbsynUtil_isClassdef(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,2) == 0) goto tmp3_end;
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
modelica_metatype boxptr_AbsynUtil_isClassdef(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_AbsynUtil_isClassdef(threadData, _inElement);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_string omc_AbsynUtil_elementSpecName(threadData_t *threadData, modelica_metatype _inElementSpec)
{
modelica_string _outIdent = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElementSpec;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_n = tmpMeta7;
tmp1 = _n;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
if (!listEmpty(tmpMeta10)) goto tmp3_end;
_n = tmpMeta12;
tmp1 = _n;
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
_outIdent = tmp1;
_return: OMC_LABEL_UNUSED
return _outIdent;
}
DLLExport
modelica_boolean omc_AbsynUtil_isClassNamed(threadData_t *threadData, modelica_string _inName, modelica_metatype _inClass)
{
modelica_boolean _outIsNamed;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmp1 = (stringEqual(_inName, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inClass), 2)))));
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
_outIsNamed = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsNamed;
}
modelica_metatype boxptr_AbsynUtil_isClassNamed(threadData_t *threadData, modelica_metatype _inName, modelica_metatype _inClass)
{
modelica_boolean _outIsNamed;
modelica_metatype out_outIsNamed;
_outIsNamed = omc_AbsynUtil_isClassNamed(threadData, _inName, _inClass);
out_outIsNamed = mmc_mk_icon(_outIsNamed);
return out_outIsNamed;
}
DLLExport
modelica_metatype omc_AbsynUtil_className(threadData_t *threadData, modelica_metatype _cl)
{
modelica_metatype _name = NULL;
modelica_string _id = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _cl;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_id = tmpMeta2;
tmpMeta3 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _id);
_name = tmpMeta3;
_return: OMC_LABEL_UNUSED
return _name;
}
DLLExport
modelica_metatype omc_AbsynUtil_makeQualifiedPathFromStrings(threadData_t *threadData, modelica_string _s1, modelica_string _s2)
{
modelica_metatype _p = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _s2);
tmpMeta2 = mmc_mk_box3(3, &Absyn_Path_QUALIFIED__desc, _s1, tmpMeta1);
_p = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _p;
}
DLLExport
modelica_metatype omc_AbsynUtil_makeIdentPathFromString(threadData_t *threadData, modelica_string _s)
{
modelica_metatype _p = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _s);
_p = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _p;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseAlgorithmBidir(threadData_t *threadData, modelica_metatype __omcQ_24in_5Falg, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg)
{
modelica_metatype _alg = NULL;
modelica_metatype _arg = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_alg = __omcQ_24in_5Falg;
_arg = __omcQ_24in_5Farg;
{
modelica_metatype tmp4_1;
tmp4_1 = _alg;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _algs1 = NULL;
modelica_metatype _algs2 = NULL;
modelica_metatype _else_branch = NULL;
modelica_metatype _cref1 = NULL;
modelica_metatype _iters = NULL;
modelica_metatype _func_args = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e1 = tmpMeta5;
_e2 = tmpMeta6;
_e1 = omc_AbsynUtil_traverseExpBidir(threadData, _e1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_e2 = omc_AbsynUtil_traverseExpBidir(threadData, _e2, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta7 = mmc_mk_box3(3, &Absyn_Algorithm_ALG__ASSIGN__desc, _e1, _e2);
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,4) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e1 = tmpMeta8;
_algs1 = tmpMeta9;
_else_branch = tmpMeta10;
_algs2 = tmpMeta11;
_e1 = omc_AbsynUtil_traverseExpBidir(threadData, _e1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_algs1 = omc_AbsynUtil_traverseAlgorithmItemListBidir(threadData, _algs1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_else_branch = omc_List_map2FoldCheckReferenceEq(threadData, _else_branch, boxvar_AbsynUtil_traverseAlgorithmBidirElse, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_algs2 = omc_AbsynUtil_traverseAlgorithmItemListBidir(threadData, _algs2, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta12 = mmc_mk_box5(4, &Absyn_Algorithm_ALG__IF__desc, _e1, _algs1, _else_branch, _algs2);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_iters = tmpMeta13;
_algs1 = tmpMeta14;
_iters = omc_List_map2FoldCheckReferenceEq(threadData, _iters, boxvar_AbsynUtil_traverseExpBidirIterator, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_algs1 = omc_AbsynUtil_traverseAlgorithmItemListBidir(threadData, _algs1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta15 = mmc_mk_box3(5, &Absyn_Algorithm_ALG__FOR__desc, _iters, _algs1);
tmpMeta1 = tmpMeta15;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,2) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_iters = tmpMeta16;
_algs1 = tmpMeta17;
_iters = omc_List_map2FoldCheckReferenceEq(threadData, _iters, boxvar_AbsynUtil_traverseExpBidirIterator, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_algs1 = omc_AbsynUtil_traverseAlgorithmItemListBidir(threadData, _algs1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta18 = mmc_mk_box3(6, &Absyn_Algorithm_ALG__PARFOR__desc, _iters, _algs1);
tmpMeta1 = tmpMeta18;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,2) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e1 = tmpMeta19;
_algs1 = tmpMeta20;
_e1 = omc_AbsynUtil_traverseExpBidir(threadData, _e1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_algs1 = omc_AbsynUtil_traverseAlgorithmItemListBidir(threadData, _algs1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta21 = mmc_mk_box3(7, &Absyn_Algorithm_ALG__WHILE__desc, _e1, _algs1);
tmpMeta1 = tmpMeta21;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,3) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta22;
_algs1 = tmpMeta23;
_else_branch = tmpMeta24;
_e1 = omc_AbsynUtil_traverseExpBidir(threadData, _e1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_algs1 = omc_AbsynUtil_traverseAlgorithmItemListBidir(threadData, _algs1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_else_branch = omc_List_map2FoldCheckReferenceEq(threadData, _else_branch, boxvar_AbsynUtil_traverseAlgorithmBidirElse, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta25 = mmc_mk_box4(8, &Absyn_Algorithm_ALG__WHEN__A__desc, _e1, _algs1, _else_branch);
tmpMeta1 = tmpMeta25;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_cref1 = tmpMeta26;
_func_args = tmpMeta27;
_cref1 = omc_AbsynUtil_traverseExpBidirCref(threadData, _cref1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_func_args = omc_AbsynUtil_traverseExpBidirFunctionArgs(threadData, _func_args, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta28 = mmc_mk_box3(9, &Absyn_Algorithm_ALG__NORETCALL__desc, _cref1, _func_args);
tmpMeta1 = tmpMeta28;
goto tmp3_done;
}
case 10: {
tmpMeta1 = _alg;
goto tmp3_done;
}
case 11: {
tmpMeta1 = _alg;
goto tmp3_done;
}
case 14: {
tmpMeta1 = _alg;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_algs1 = tmpMeta29;
_algs1 = omc_AbsynUtil_traverseAlgorithmItemListBidir(threadData, _algs1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta30 = mmc_mk_box2(12, &Absyn_Algorithm_ALG__FAILURE__desc, _algs1);
tmpMeta1 = tmpMeta30;
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,2) == 0) goto tmp3_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_algs1 = tmpMeta31;
_algs2 = tmpMeta32;
_algs1 = omc_AbsynUtil_traverseAlgorithmItemListBidir(threadData, _algs1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_algs2 = omc_AbsynUtil_traverseAlgorithmItemListBidir(threadData, _algs2, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta33 = mmc_mk_box3(13, &Absyn_Algorithm_ALG__TRY__desc, _algs1, _algs2);
tmpMeta1 = tmpMeta33;
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
_alg = tmpMeta1;
_return: OMC_LABEL_UNUSED
if (out_arg) { *out_arg = _arg; }
return _alg;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseAlgorithmBidirElse(threadData_t *threadData, modelica_metatype _inElse, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype _inArg, modelica_metatype *out_arg)
{
modelica_metatype _outElse = NULL;
modelica_metatype _arg = NULL;
modelica_metatype _e = NULL;
modelica_metatype _algs = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inElse;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_e = tmpMeta2;
_algs = tmpMeta3;
_e = omc_AbsynUtil_traverseExpBidir(threadData, _e, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _inArg ,&_arg);
_algs = omc_AbsynUtil_traverseAlgorithmItemListBidir(threadData, _algs, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta4 = mmc_mk_box2(0, _e, _algs);
_outElse = tmpMeta4;
_return: OMC_LABEL_UNUSED
if (out_arg) { *out_arg = _arg; }
return _outElse;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseEquationBidirElse(threadData_t *threadData, modelica_metatype _inElse, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype _inArg, modelica_metatype *out_arg)
{
modelica_metatype _outElse = NULL;
modelica_metatype _arg = NULL;
modelica_metatype _e = NULL;
modelica_metatype _eqil = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inElse;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_e = tmpMeta2;
_eqil = tmpMeta3;
_e = omc_AbsynUtil_traverseExpBidir(threadData, _e, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _inArg ,&_arg);
_eqil = omc_AbsynUtil_traverseEquationItemListBidir(threadData, _eqil, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta4 = mmc_mk_box2(0, _e, _eqil);
_outElse = tmpMeta4;
_return: OMC_LABEL_UNUSED
if (out_arg) { *out_arg = _arg; }
return _outElse;
}
DLLExport
modelica_metatype omc_AbsynUtil_traverseEquationBidir(threadData_t *threadData, modelica_metatype __omcQ_24in_5Feq, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg)
{
modelica_metatype _eq = NULL;
modelica_metatype _arg = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_eq = __omcQ_24in_5Feq;
_arg = __omcQ_24in_5Farg;
{
modelica_metatype tmp4_1;
tmp4_1 = _eq;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _eqil1 = NULL;
modelica_metatype _eqil2 = NULL;
modelica_metatype _else_branch = NULL;
modelica_metatype _cref1 = NULL;
modelica_metatype _cref2 = NULL;
modelica_metatype _iters = NULL;
modelica_metatype _func_args = NULL;
modelica_metatype _eq1 = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e1 = tmpMeta5;
_eqil1 = tmpMeta6;
_else_branch = tmpMeta7;
_eqil2 = tmpMeta8;
_e1 = omc_AbsynUtil_traverseExpBidir(threadData, _e1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_eqil1 = omc_AbsynUtil_traverseEquationItemListBidir(threadData, _eqil1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_else_branch = omc_List_map2FoldCheckReferenceEq(threadData, _else_branch, boxvar_AbsynUtil_traverseEquationBidirElse, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_eqil2 = omc_AbsynUtil_traverseEquationItemListBidir(threadData, _eqil2, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta9 = mmc_mk_box5(3, &Absyn_Equation_EQ__IF__desc, _e1, _eqil1, _else_branch, _eqil2);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e1 = tmpMeta10;
_e2 = tmpMeta11;
_e1 = omc_AbsynUtil_traverseExpBidir(threadData, _e1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_e2 = omc_AbsynUtil_traverseExpBidir(threadData, _e2, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta12 = mmc_mk_box3(4, &Absyn_Equation_EQ__EQUALS__desc, _e1, _e2);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,3) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta13;
_e2 = tmpMeta14;
_cref1 = tmpMeta15;
_e1 = omc_AbsynUtil_traverseExpBidir(threadData, _e1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_e2 = omc_AbsynUtil_traverseExpBidir(threadData, _e2, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_cref1 = omc_AbsynUtil_traverseExpBidirCref(threadData, _cref1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg, NULL);
tmpMeta16 = mmc_mk_box4(5, &Absyn_Equation_EQ__PDE__desc, _e1, _e2, _cref1);
tmpMeta1 = tmpMeta16;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,2) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_cref1 = tmpMeta17;
_cref2 = tmpMeta18;
_cref1 = omc_AbsynUtil_traverseExpBidirCref(threadData, _cref1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_cref2 = omc_AbsynUtil_traverseExpBidirCref(threadData, _cref2, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta19 = mmc_mk_box3(6, &Absyn_Equation_EQ__CONNECT__desc, _cref1, _cref2);
tmpMeta1 = tmpMeta19;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,2) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_iters = tmpMeta20;
_eqil1 = tmpMeta21;
_iters = omc_List_map2FoldCheckReferenceEq(threadData, _iters, boxvar_AbsynUtil_traverseExpBidirIterator, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_eqil1 = omc_AbsynUtil_traverseEquationItemListBidir(threadData, _eqil1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta22 = mmc_mk_box3(7, &Absyn_Equation_EQ__FOR__desc, _iters, _eqil1);
tmpMeta1 = tmpMeta22;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,3) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta23;
_eqil1 = tmpMeta24;
_else_branch = tmpMeta25;
_e1 = omc_AbsynUtil_traverseExpBidir(threadData, _e1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_eqil1 = omc_AbsynUtil_traverseEquationItemListBidir(threadData, _eqil1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_else_branch = omc_List_map2FoldCheckReferenceEq(threadData, _else_branch, boxvar_AbsynUtil_traverseEquationBidirElse, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta26 = mmc_mk_box4(8, &Absyn_Equation_EQ__WHEN__E__desc, _e1, _eqil1, _else_branch);
tmpMeta1 = tmpMeta26;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_cref1 = tmpMeta27;
_func_args = tmpMeta28;
_cref1 = omc_AbsynUtil_traverseExpBidirCref(threadData, _cref1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_func_args = omc_AbsynUtil_traverseExpBidirFunctionArgs(threadData, _func_args, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta29 = mmc_mk_box3(9, &Absyn_Equation_EQ__NORETCALL__desc, _cref1, _func_args);
tmpMeta1 = tmpMeta29;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,1) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_eq1 = tmpMeta30;
_eq1 = omc_AbsynUtil_traverseEquationItemBidir(threadData, _eq1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta31 = mmc_mk_box2(10, &Absyn_Equation_EQ__FAILURE__desc, _eq1);
tmpMeta1 = tmpMeta31;
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
_eq = tmpMeta1;
_return: OMC_LABEL_UNUSED
if (out_arg) { *out_arg = _arg; }
return _eq;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseEquationItemBidir(threadData_t *threadData, modelica_metatype __omcQ_24in_5FequationItem, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg)
{
modelica_metatype _equationItem = NULL;
modelica_metatype _arg = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_equationItem = __omcQ_24in_5FequationItem;
_arg = __omcQ_24in_5Farg;
{
modelica_metatype tmp3_1;
tmp3_1 = _equationItem;
{
modelica_metatype _eq = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,3) == 0) goto tmp2_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_eq = tmpMeta5;
_eq = omc_AbsynUtil_traverseEquationBidir(threadData, _eq, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_equationItem), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[2] = _eq;
_equationItem = tmpMeta6;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
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
if (out_arg) { *out_arg = _arg; }
return _equationItem;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseAlgorithmItemBidir(threadData_t *threadData, modelica_metatype __omcQ_24in_5FalgorithmItem, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg)
{
modelica_metatype _algorithmItem = NULL;
modelica_metatype _arg = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_algorithmItem = __omcQ_24in_5FalgorithmItem;
_arg = __omcQ_24in_5Farg;
{
modelica_metatype tmp3_1;
tmp3_1 = _algorithmItem;
{
modelica_metatype _alg = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,3) == 0) goto tmp2_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_alg = tmpMeta5;
_alg = omc_AbsynUtil_traverseAlgorithmBidir(threadData, _alg, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_algorithmItem), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[2] = _alg;
_algorithmItem = tmpMeta6;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
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
if (out_arg) { *out_arg = _arg; }
return _algorithmItem;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseAlgorithmItemListBidir(threadData_t *threadData, modelica_metatype _inAlgs, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outAlgs = NULL;
modelica_metatype _outArg = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outAlgs = omc_List_map2FoldCheckReferenceEq(threadData, _inAlgs, boxvar_AbsynUtil_traverseAlgorithmItemBidir, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _inArg ,&_outArg);
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outAlgs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseEquationItemListBidir(threadData_t *threadData, modelica_metatype _inEquationItems, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outEquationItems = NULL;
modelica_metatype _outArg = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outEquationItems = omc_List_map2FoldCheckReferenceEq(threadData, _inEquationItems, boxvar_AbsynUtil_traverseEquationItemBidir, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _inArg ,&_outArg);
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outEquationItems;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseClassPartBidir(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcp, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg)
{
modelica_metatype _cp = NULL;
modelica_metatype _arg = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cp = __omcQ_24in_5Fcp;
_arg = __omcQ_24in_5Farg;
{
modelica_metatype tmp4_1;
tmp4_1 = _cp;
{
modelica_metatype _algs = NULL;
modelica_metatype _eqs = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_algs = tmpMeta6;
_algs = omc_List_map2FoldCheckReferenceEq(threadData, _algs, boxvar_AbsynUtil_traverseAlgorithmItemBidir, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta7 = mmc_mk_box2(8, &Absyn_ClassPart_ALGORITHMS__desc, _algs);
tmpMeta[0+0] = tmpMeta7;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_eqs = tmpMeta8;
_eqs = omc_List_map2FoldCheckReferenceEq(threadData, _eqs, boxvar_AbsynUtil_traverseEquationItemBidir, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta9 = mmc_mk_box2(6, &Absyn_ClassPart_EQUATIONS__desc, _eqs);
tmpMeta[0+0] = tmpMeta9;
tmpMeta[0+1] = _arg;
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
_cp = tmpMeta[0+0];
_arg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_arg) { *out_arg = _arg; }
return _cp;
}
DLLExport
modelica_metatype omc_AbsynUtil_traverseMatchCase(threadData_t *threadData, modelica_metatype __omcQ_24in_5FmatchCase, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg)
{
modelica_metatype _matchCase = NULL;
modelica_metatype _arg = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_matchCase = __omcQ_24in_5FmatchCase;
_arg = __omcQ_24in_5Farg;
{
modelica_metatype tmp4_1;
tmp4_1 = _matchCase;
{
modelica_metatype _pattern = NULL;
modelica_metatype _result = NULL;
modelica_metatype _info = NULL;
modelica_metatype _resultInfo = NULL;
modelica_metatype _pinfo = NULL;
modelica_metatype _ldecls = NULL;
modelica_metatype _cp = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _patternGuard = NULL;
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
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,9) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 9));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 10));
_pattern = tmpMeta6;
_patternGuard = tmpMeta7;
_pinfo = tmpMeta8;
_ldecls = tmpMeta9;
_cp = tmpMeta10;
_result = tmpMeta11;
_resultInfo = tmpMeta12;
_cmt = tmpMeta13;
_info = tmpMeta14;
_pattern = omc_AbsynUtil_traverseExpBidir(threadData, _pattern, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_patternGuard = omc_AbsynUtil_traverseExpOptBidir(threadData, _patternGuard, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_cp = omc_AbsynUtil_traverseClassPartBidir(threadData, _cp, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_result = omc_AbsynUtil_traverseExpBidir(threadData, _result, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta15 = mmc_mk_box10(3, &Absyn_Case_CASE__desc, _pattern, _patternGuard, _pinfo, _ldecls, _cp, _result, _resultInfo, _cmt, _info);
tmpMeta[0+0] = tmpMeta15;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,6) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
_ldecls = tmpMeta16;
_cp = tmpMeta17;
_result = tmpMeta18;
_resultInfo = tmpMeta19;
_cmt = tmpMeta20;
_info = tmpMeta21;
_cp = omc_AbsynUtil_traverseClassPartBidir(threadData, _cp, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_result = omc_AbsynUtil_traverseExpBidir(threadData, _result, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta22 = mmc_mk_box7(4, &Absyn_Case_ELSE__desc, _ldecls, _cp, _result, _resultInfo, _cmt, _info);
tmpMeta[0+0] = tmpMeta22;
tmpMeta[0+1] = _arg;
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
_matchCase = tmpMeta[0+0];
_arg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_arg) { *out_arg = _arg; }
return _matchCase;
}
DLLExport
modelica_metatype omc_AbsynUtil_traverseExpBidirIterator(threadData_t *threadData, modelica_metatype _inIterator, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outIterator = NULL;
modelica_metatype _outArg = NULL;
modelica_string _name = NULL;
modelica_metatype _guardExp1 = NULL;
modelica_metatype _guardExp2 = NULL;
modelica_metatype _range1 = NULL;
modelica_metatype _range2 = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_boolean tmp6;
modelica_metatype tmpMeta7;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inIterator;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
_name = tmpMeta2;
_guardExp1 = tmpMeta3;
_range1 = tmpMeta4;
_guardExp2 = omc_AbsynUtil_traverseExpOptBidir(threadData, _guardExp1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _inArg ,&_outArg);
_range2 = omc_AbsynUtil_traverseExpOptBidir(threadData, _range1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _outArg ,&_outArg);
tmp6 = (modelica_boolean)(referenceEq(_guardExp1, _guardExp2) && referenceEq(_range1, _range2));
if(tmp6)
{
tmpMeta7 = _inIterator;
}
else
{
tmpMeta5 = mmc_mk_box4(3, &Absyn_ForIterator_ITERATOR__desc, _name, _guardExp2, _range2);
tmpMeta7 = tmpMeta5;
}
_outIterator = tmpMeta7;
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outIterator;
}
DLLExport
modelica_metatype omc_AbsynUtil_traverseExpBidirNamedArg(threadData_t *threadData, modelica_metatype _inArg, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype _inExtra, modelica_metatype *out_outExtra)
{
modelica_metatype _outArg = NULL;
modelica_metatype _outExtra = NULL;
modelica_string _name = NULL;
modelica_metatype _value1 = NULL;
modelica_metatype _value2 = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_boolean tmp5;
modelica_metatype tmpMeta6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inArg;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_name = tmpMeta2;
_value1 = tmpMeta3;
_value2 = omc_AbsynUtil_traverseExpBidir(threadData, _value1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _inExtra ,&_outExtra);
tmp5 = (modelica_boolean)referenceEq(_value1, _value2);
if(tmp5)
{
tmpMeta6 = _inArg;
}
else
{
tmpMeta4 = mmc_mk_box3(3, &Absyn_NamedArg_NAMEDARG__desc, _name, _value2);
tmpMeta6 = tmpMeta4;
}
_outArg = tmpMeta6;
_return: OMC_LABEL_UNUSED
if (out_outExtra) { *out_outExtra = _outExtra; }
return _outArg;
}
DLLExport
modelica_metatype omc_AbsynUtil_traverseExpBidirFunctionArgs(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fargs, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg)
{
modelica_metatype _args = NULL;
modelica_metatype _arg = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_args = __omcQ_24in_5Fargs;
_arg = __omcQ_24in_5Farg;
{
modelica_metatype tmp4_1;
tmp4_1 = _args;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _expl1 = NULL;
modelica_metatype _expl2 = NULL;
modelica_metatype _named_args1 = NULL;
modelica_metatype _named_args2 = NULL;
modelica_metatype _iters1 = NULL;
modelica_metatype _iters2 = NULL;
modelica_metatype _iterType = NULL;
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
_expl1 = tmpMeta6;
_named_args1 = tmpMeta7;
_expl2 = omc_AbsynUtil_traverseExpListBidir(threadData, _expl1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_named_args2 = omc_List_map2FoldCheckReferenceEq(threadData, _named_args1, boxvar_AbsynUtil_traverseExpBidirNamedArg, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmp9 = (modelica_boolean)(referenceEq(_expl1, _expl2) && referenceEq(_named_args1, _named_args2));
if(tmp9)
{
tmpMeta10 = _args;
}
else
{
tmpMeta8 = mmc_mk_box3(3, &Absyn_FunctionArgs_FUNCTIONARGS__desc, _expl2, _named_args2);
tmpMeta10 = tmpMeta8;
}
tmpMeta[0+0] = tmpMeta10;
tmpMeta[0+1] = _arg;
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
_e1 = tmpMeta11;
_iterType = tmpMeta12;
_iters1 = tmpMeta13;
_e2 = omc_AbsynUtil_traverseExpBidir(threadData, _e1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_iters2 = omc_List_map2FoldCheckReferenceEq(threadData, _iters1, boxvar_AbsynUtil_traverseExpBidirIterator, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmp15 = (modelica_boolean)(referenceEq(_e1, _e2) && referenceEq(_iters1, _iters2));
if(tmp15)
{
tmpMeta16 = _args;
}
else
{
tmpMeta14 = mmc_mk_box4(4, &Absyn_FunctionArgs_FOR__ITER__FARG__desc, _e2, _iterType, _iters2);
tmpMeta16 = tmpMeta14;
}
tmpMeta[0+0] = tmpMeta16;
tmpMeta[0+1] = _arg;
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
_args = tmpMeta[0+0];
_arg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_arg) { *out_arg = _arg; }
return _args;
}
DLLExport
modelica_metatype omc_AbsynUtil_traverseExpBidirElseIf(threadData_t *threadData, modelica_metatype _inElseIf, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype _inArg, modelica_metatype *out_arg)
{
modelica_metatype _outElseIf = NULL;
modelica_metatype _arg = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inElseIf;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_e1 = tmpMeta2;
_e2 = tmpMeta3;
_e1 = omc_AbsynUtil_traverseExpBidir(threadData, _e1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _inArg ,&_arg);
_e2 = omc_AbsynUtil_traverseExpBidir(threadData, _e2, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta4 = mmc_mk_box2(0, _e1, _e2);
_outElseIf = tmpMeta4;
_return: OMC_LABEL_UNUSED
if (out_arg) { *out_arg = _arg; }
return _outElseIf;
}
DLLExport
modelica_metatype omc_AbsynUtil_traverseExpBidirSubs(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsubscript, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg)
{
modelica_metatype _subscript = NULL;
modelica_metatype _arg = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_subscript = __omcQ_24in_5Fsubscript;
_arg = __omcQ_24in_5Farg;
{
modelica_metatype tmp4_1;
tmp4_1 = _subscript;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_boolean tmp8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_e1 = tmpMeta6;
_e2 = omc_AbsynUtil_traverseExpBidir(threadData, _e1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmp8 = (modelica_boolean)referenceEq(_e1, _e2);
if(tmp8)
{
tmpMeta9 = _subscript;
}
else
{
tmpMeta7 = mmc_mk_box2(4, &Absyn_Subscript_SUBSCRIPT__desc, _e2);
tmpMeta9 = tmpMeta7;
}
tmpMeta[0+0] = tmpMeta9;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmpMeta[0+0] = _subscript;
tmpMeta[0+1] = _arg;
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
_subscript = tmpMeta[0+0];
_arg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_arg) { *out_arg = _arg; }
return _subscript;
}
DLLExport
modelica_metatype omc_AbsynUtil_traverseExpBidirCref(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcref, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg)
{
modelica_metatype _cref = NULL;
modelica_metatype _arg = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cref = __omcQ_24in_5Fcref;
_arg = __omcQ_24in_5Farg;
{
modelica_metatype tmp4_1;
tmp4_1 = _cref;
{
modelica_string _name = NULL;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
modelica_metatype _subs1 = NULL;
modelica_metatype _subs2 = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cr1 = tmpMeta5;
_cr2 = omc_AbsynUtil_traverseExpBidirCref(threadData, _cr1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta[0+0] = (referenceEq(_cr1, _cr2)?_cref:omc_AbsynUtil_crefMakeFullyQualified(threadData, _cr2));
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 4: {
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
_name = tmpMeta6;
_subs1 = tmpMeta7;
_cr1 = tmpMeta8;
_subs2 = omc_List_map2FoldCheckReferenceEq(threadData, _subs1, boxvar_AbsynUtil_traverseExpBidirSubs, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_cr2 = omc_AbsynUtil_traverseExpBidirCref(threadData, _cr1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmp10 = (modelica_boolean)(referenceEq(_cr1, _cr2) && referenceEq(_subs1, _subs2));
if(tmp10)
{
tmpMeta11 = _cref;
}
else
{
tmpMeta9 = mmc_mk_box4(4, &Absyn_ComponentRef_CREF__QUAL__desc, _name, _subs2, _cr2);
tmpMeta11 = tmpMeta9;
}
tmpMeta[0+0] = tmpMeta11;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_boolean tmp15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_name = tmpMeta12;
_subs1 = tmpMeta13;
_subs2 = omc_List_map2FoldCheckReferenceEq(threadData, _subs1, boxvar_AbsynUtil_traverseExpBidirSubs, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmp15 = (modelica_boolean)referenceEq(_subs1, _subs2);
if(tmp15)
{
tmpMeta16 = _cref;
}
else
{
tmpMeta14 = mmc_mk_box3(5, &Absyn_ComponentRef_CREF__IDENT__desc, _name, _subs2);
tmpMeta16 = tmpMeta14;
}
tmpMeta[0+0] = tmpMeta16;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 7: {
tmpMeta[0+0] = _cref;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 6: {
tmpMeta[0+0] = _cref;
tmpMeta[0+1] = _arg;
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
_cref = tmpMeta[0+0];
_arg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_arg) { *out_arg = _arg; }
return _cref;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynUtil_traverseExpBidirSubExps(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg)
{
modelica_metatype _exp = NULL;
modelica_metatype _arg = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_exp = __omcQ_24in_5Fexp;
_arg = __omcQ_24in_5Farg;
{
modelica_metatype tmp4_1;
tmp4_1 = _exp;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e1m = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e2m = NULL;
modelica_metatype _e3 = NULL;
modelica_metatype _e3m = NULL;
modelica_metatype _oe1 = NULL;
modelica_metatype _oe1m = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _crefm = NULL;
modelica_metatype _else_ifs1 = NULL;
modelica_metatype _else_ifs2 = NULL;
modelica_metatype _expl1 = NULL;
modelica_metatype _expl2 = NULL;
modelica_metatype _mat_expl = NULL;
modelica_metatype _fargs1 = NULL;
modelica_metatype _fargs2 = NULL;
modelica_string _error_msg = NULL;
modelica_string _id = NULL;
modelica_string _enterName = NULL;
modelica_string _exitName = NULL;
modelica_metatype _match_cases = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 4: {
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 6: {
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 7: {
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_boolean tmp7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cref = tmpMeta5;
_crefm = omc_AbsynUtil_traverseExpBidirCref(threadData, _cref, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmp7 = (modelica_boolean)referenceEq(_cref, _crefm);
if(tmp7)
{
tmpMeta8 = _exp;
}
else
{
tmpMeta6 = mmc_mk_box2(5, &Absyn_Exp_CREF__desc, _crefm);
tmpMeta8 = tmpMeta6;
}
tmpMeta[0+0] = tmpMeta8;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_boolean tmp12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,3) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta9;
_e2 = tmpMeta10;
_e1m = omc_AbsynUtil_traverseExpBidir(threadData, _e1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_e2m = omc_AbsynUtil_traverseExpBidir(threadData, _e2, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmp12 = (modelica_boolean)(referenceEq(_e1, _e1m) && referenceEq(_e2, _e2m));
if(tmp12)
{
tmpMeta13 = _exp;
}
else
{
tmpMeta11 = mmc_mk_box4(8, &Absyn_Exp_BINARY__desc, _e1m, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 3))), _e2m);
tmpMeta13 = tmpMeta11;
}
tmpMeta[0+0] = tmpMeta13;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_boolean tmp16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e1 = tmpMeta14;
_e1m = omc_AbsynUtil_traverseExpBidir(threadData, _e1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmp16 = (modelica_boolean)referenceEq(_e1, _e1m);
if(tmp16)
{
tmpMeta17 = _exp;
}
else
{
tmpMeta15 = mmc_mk_box3(9, &Absyn_Exp_UNARY__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 2))), _e1m);
tmpMeta17 = tmpMeta15;
}
tmpMeta[0+0] = tmpMeta17;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_boolean tmp21;
modelica_metatype tmpMeta22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta18;
_e2 = tmpMeta19;
_e1m = omc_AbsynUtil_traverseExpBidir(threadData, _e1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_e2m = omc_AbsynUtil_traverseExpBidir(threadData, _e2, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmp21 = (modelica_boolean)(referenceEq(_e1, _e1m) && referenceEq(_e2, _e2m));
if(tmp21)
{
tmpMeta22 = _exp;
}
else
{
tmpMeta20 = mmc_mk_box4(10, &Absyn_Exp_LBINARY__desc, _e1m, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 3))), _e2m);
tmpMeta22 = tmpMeta20;
}
tmpMeta[0+0] = tmpMeta22;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_boolean tmp25;
modelica_metatype tmpMeta26;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e1 = tmpMeta23;
_e1m = omc_AbsynUtil_traverseExpBidir(threadData, _e1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmp25 = (modelica_boolean)referenceEq(_e1, _e1m);
if(tmp25)
{
tmpMeta26 = _exp;
}
else
{
tmpMeta24 = mmc_mk_box3(11, &Absyn_Exp_LUNARY__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 2))), _e1m);
tmpMeta26 = tmpMeta24;
}
tmpMeta[0+0] = tmpMeta26;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_boolean tmp30;
modelica_metatype tmpMeta31;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta27;
_e2 = tmpMeta28;
_e1m = omc_AbsynUtil_traverseExpBidir(threadData, _e1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_e2m = omc_AbsynUtil_traverseExpBidir(threadData, _e2, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmp30 = (modelica_boolean)(referenceEq(_e1, _e1m) && referenceEq(_e2, _e2m));
if(tmp30)
{
tmpMeta31 = _exp;
}
else
{
tmpMeta29 = mmc_mk_box4(12, &Absyn_Exp_RELATION__desc, _e1m, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 3))), _e2m);
tmpMeta31 = tmpMeta29;
}
tmpMeta[0+0] = tmpMeta31;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_boolean tmp37;
modelica_metatype tmpMeta38;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e1 = tmpMeta32;
_e2 = tmpMeta33;
_e3 = tmpMeta34;
_else_ifs1 = tmpMeta35;
_e1m = omc_AbsynUtil_traverseExpBidir(threadData, _e1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_e2m = omc_AbsynUtil_traverseExpBidir(threadData, _e2, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_e3m = omc_AbsynUtil_traverseExpBidir(threadData, _e3, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_else_ifs2 = omc_List_map2FoldCheckReferenceEq(threadData, _else_ifs1, boxvar_AbsynUtil_traverseExpBidirElseIf, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmp37 = (modelica_boolean)(((referenceEq(_e1, _e1m) && referenceEq(_e2, _e2m)) && referenceEq(_e3, _e3m)) && referenceEq(_else_ifs1, _else_ifs2));
if(tmp37)
{
tmpMeta38 = _exp;
}
else
{
tmpMeta36 = mmc_mk_box5(13, &Absyn_Exp_IFEXP__desc, _e1m, _e2m, _e3m, _else_ifs2);
tmpMeta38 = tmpMeta36;
}
tmpMeta[0+0] = tmpMeta38;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 14: {
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_boolean tmp42;
modelica_metatype tmpMeta43;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,3) == 0) goto tmp3_end;
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_cref = tmpMeta39;
_fargs1 = tmpMeta40;
_fargs2 = omc_AbsynUtil_traverseExpBidirFunctionArgs(threadData, _fargs1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmp42 = (modelica_boolean)referenceEq(_fargs1, _fargs2);
if(tmp42)
{
tmpMeta43 = _exp;
}
else
{
tmpMeta41 = mmc_mk_box4(14, &Absyn_Exp_CALL__desc, _cref, _fargs2, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 4))));
tmpMeta43 = tmpMeta41;
}
tmpMeta[0+0] = tmpMeta43;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_boolean tmp47;
modelica_metatype tmpMeta48;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,2) == 0) goto tmp3_end;
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_cref = tmpMeta44;
_fargs1 = tmpMeta45;
_fargs2 = omc_AbsynUtil_traverseExpBidirFunctionArgs(threadData, _fargs1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmp47 = (modelica_boolean)referenceEq(_fargs1, _fargs2);
if(tmp47)
{
tmpMeta48 = _exp;
}
else
{
tmpMeta46 = mmc_mk_box3(15, &Absyn_Exp_PARTEVALFUNCTION__desc, _cref, _fargs2);
tmpMeta48 = tmpMeta46;
}
tmpMeta[0+0] = tmpMeta48;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 16: {
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_boolean tmp51;
modelica_metatype tmpMeta52;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,1) == 0) goto tmp3_end;
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_expl1 = tmpMeta49;
_expl2 = omc_AbsynUtil_traverseExpListBidir(threadData, _expl1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmp51 = (modelica_boolean)referenceEq(_expl1, _expl2);
if(tmp51)
{
tmpMeta52 = _exp;
}
else
{
tmpMeta50 = mmc_mk_box2(16, &Absyn_Exp_ARRAY__desc, _expl2);
tmpMeta52 = tmpMeta50;
}
tmpMeta[0+0] = tmpMeta52;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 17: {
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,14,1) == 0) goto tmp3_end;
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_mat_expl = tmpMeta53;
_mat_expl = omc_List_map2FoldCheckReferenceEq(threadData, _mat_expl, boxvar_AbsynUtil_traverseExpListBidir, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta54 = mmc_mk_box2(17, &Absyn_Exp_MATRIX__desc, _mat_expl);
tmpMeta[0+0] = tmpMeta54;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 18: {
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
modelica_metatype tmpMeta57;
modelica_metatype tmpMeta58;
modelica_boolean tmp59;
modelica_metatype tmpMeta60;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,3) == 0) goto tmp3_end;
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta55;
_oe1 = tmpMeta56;
_e2 = tmpMeta57;
_e1m = omc_AbsynUtil_traverseExpBidir(threadData, _e1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_oe1m = omc_AbsynUtil_traverseExpOptBidir(threadData, _oe1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_e2m = omc_AbsynUtil_traverseExpBidir(threadData, _e2, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmp59 = (modelica_boolean)((referenceEq(_e1, _e1m) && referenceEq(_e2, _e2m)) && referenceEq(_oe1, _oe1m));
if(tmp59)
{
tmpMeta60 = _exp;
}
else
{
tmpMeta58 = mmc_mk_box4(18, &Absyn_Exp_RANGE__desc, _e1m, _oe1m, _e2m);
tmpMeta60 = tmpMeta58;
}
tmpMeta[0+0] = tmpMeta60;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 20: {
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 19: {
modelica_metatype tmpMeta61;
modelica_metatype tmpMeta62;
modelica_boolean tmp63;
modelica_metatype tmpMeta64;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,1) == 0) goto tmp3_end;
tmpMeta61 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_expl1 = tmpMeta61;
_expl2 = omc_AbsynUtil_traverseExpListBidir(threadData, _expl1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmp63 = (modelica_boolean)referenceEq(_expl1, _expl2);
if(tmp63)
{
tmpMeta64 = _exp;
}
else
{
tmpMeta62 = mmc_mk_box2(19, &Absyn_Exp_TUPLE__desc, _expl2);
tmpMeta64 = tmpMeta62;
}
tmpMeta[0+0] = tmpMeta64;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 22: {
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
modelica_metatype tmpMeta67;
modelica_boolean tmp68;
modelica_metatype tmpMeta69;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,19,2) == 0) goto tmp3_end;
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta66 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_id = tmpMeta65;
_e1 = tmpMeta66;
_e1m = omc_AbsynUtil_traverseExpBidir(threadData, _e1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmp68 = (modelica_boolean)referenceEq(_e1, _e1m);
if(tmp68)
{
tmpMeta69 = _exp;
}
else
{
tmpMeta67 = mmc_mk_box3(22, &Absyn_Exp_AS__desc, _id, _e1m);
tmpMeta69 = tmpMeta67;
}
tmpMeta[0+0] = tmpMeta69;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 23: {
modelica_metatype tmpMeta70;
modelica_metatype tmpMeta71;
modelica_metatype tmpMeta72;
modelica_boolean tmp73;
modelica_metatype tmpMeta74;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,20,2) == 0) goto tmp3_end;
tmpMeta70 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta71 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e1 = tmpMeta70;
_e2 = tmpMeta71;
_e1m = omc_AbsynUtil_traverseExpBidir(threadData, _e1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_e2m = omc_AbsynUtil_traverseExpBidir(threadData, _e2, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmp73 = (modelica_boolean)(referenceEq(_e1, _e1m) && referenceEq(_e2, _e2m));
if(tmp73)
{
tmpMeta74 = _exp;
}
else
{
tmpMeta72 = mmc_mk_box3(23, &Absyn_Exp_CONS__desc, _e1m, _e2m);
tmpMeta74 = tmpMeta72;
}
tmpMeta[0+0] = tmpMeta74;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 24: {
modelica_metatype tmpMeta75;
modelica_metatype tmpMeta76;
modelica_metatype tmpMeta77;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,5) == 0) goto tmp3_end;
tmpMeta75 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta76 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e1 = tmpMeta75;
_match_cases = tmpMeta76;
_e1 = omc_AbsynUtil_traverseExpBidir(threadData, _e1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_match_cases = omc_List_map2FoldCheckReferenceEq(threadData, _match_cases, boxvar_AbsynUtil_traverseMatchCase, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmpMeta77 = mmc_mk_box6(24, &Absyn_Exp_MATCHEXP__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 2))), _e1, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 4))), _match_cases, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 6))));
tmpMeta[0+0] = tmpMeta77;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 25: {
modelica_metatype tmpMeta78;
modelica_metatype tmpMeta79;
modelica_boolean tmp80;
modelica_metatype tmpMeta81;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,1) == 0) goto tmp3_end;
tmpMeta78 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_expl1 = tmpMeta78;
_expl2 = omc_AbsynUtil_traverseExpListBidir(threadData, _expl1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmp80 = (modelica_boolean)referenceEq(_expl1, _expl2);
if(tmp80)
{
tmpMeta81 = _exp;
}
else
{
tmpMeta79 = mmc_mk_box2(25, &Absyn_Exp_LIST__desc, _expl2);
tmpMeta81 = tmpMeta79;
}
tmpMeta[0+0] = tmpMeta81;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 21: {
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 26: {
modelica_metatype tmpMeta82;
modelica_boolean tmp83;
modelica_metatype tmpMeta84;
_e1 = omc_AbsynUtil_traverseExpBidir(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 2))), ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_e2 = omc_AbsynUtil_traverseExpBidir(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 3))), ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmp83 = (modelica_boolean)(referenceEq((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 2))), _e1) && referenceEq((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 3))), _e2));
if(tmp83)
{
tmpMeta84 = _exp;
}
else
{
tmpMeta82 = mmc_mk_box3(26, &Absyn_Exp_DOT__desc, _e1, _e2);
tmpMeta84 = tmpMeta82;
}
tmpMeta[0+0] = tmpMeta84;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 27: {
modelica_metatype tmpMeta85;
modelica_boolean tmp86;
modelica_metatype tmpMeta87;
_e1 = omc_AbsynUtil_traverseExpBidir(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 3))), ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
tmp86 = (modelica_boolean)referenceEq((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 3))), _e1);
if(tmp86)
{
tmpMeta87 = _exp;
}
else
{
tmpMeta85 = mmc_mk_box4(27, &Absyn_Exp_EXPRESSIONCOMMENT__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 2))), _e1, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 4))));
tmpMeta87 = tmpMeta85;
}
tmpMeta[0+0] = tmpMeta87;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
modelica_metatype tmpMeta88;
modelica_metatype tmpMeta89;
modelica_metatype tmpMeta90;
modelica_metatype tmpMeta91;
modelica_metatype tmpMeta92;
modelica_metatype tmpMeta93;
omc_System_dladdr(threadData, ((modelica_fnptr) _enterFunc) ,NULL ,&_enterName);
omc_System_dladdr(threadData, ((modelica_fnptr) _exitFunc) ,NULL ,&_exitName);
tmpMeta88 = stringAppend(_OMC_LIT64,_enterName);
tmpMeta89 = stringAppend(tmpMeta88,_OMC_LIT13);
tmpMeta90 = stringAppend(tmpMeta89,_exitName);
tmpMeta91 = stringAppend(tmpMeta90,_OMC_LIT65);
_error_msg = tmpMeta91;
tmpMeta92 = stringAppend(_error_msg,omc_Dump_printExpStr(threadData, _exp));
_error_msg = tmpMeta92;
tmpMeta93 = mmc_mk_cons(_error_msg, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMessage(threadData, _OMC_LIT70, tmpMeta93);
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
_exp = tmpMeta[0+0];
_arg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_arg) { *out_arg = _arg; }
return _exp;
}
DLLExport
modelica_metatype omc_AbsynUtil_traverseExpOptBidir(threadData_t *threadData, modelica_metatype _inExp, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype _inArg, modelica_metatype *out_arg)
{
modelica_metatype _outExp = NULL;
modelica_metatype _arg = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_e1 = tmpMeta6;
_e2 = omc_AbsynUtil_traverseExpBidir(threadData, _e1, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _inArg ,&_arg);
tmpMeta[0+0] = (referenceEq(_e1, _e2)?_inExp:mmc_mk_some(_e2));
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inArg;
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
_arg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_arg) { *out_arg = _arg; }
return _outExp;
}
DLLExport
modelica_metatype omc_AbsynUtil_traverseExpBidir(threadData_t *threadData, modelica_metatype _inExp, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype _inArg, modelica_metatype *out_arg)
{
modelica_metatype _e = NULL;
modelica_metatype _arg = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_e = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_enterFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_enterFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_enterFunc), 2))), _inExp, _inArg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_enterFunc), 1)))) (threadData, _inExp, _inArg ,&_arg);
_e = omc_AbsynUtil_traverseExpBidirSubExps(threadData, _e, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _arg ,&_arg);
_e = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exitFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exitFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exitFunc), 2))), _e, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exitFunc), 1)))) (threadData, _e, _arg ,&_arg);
_return: OMC_LABEL_UNUSED
if (out_arg) { *out_arg = _arg; }
return _e;
}
DLLExport
modelica_metatype omc_AbsynUtil_traverseExpListBidir(threadData_t *threadData, modelica_metatype _inExpl, modelica_fnptr _enterFunc, modelica_fnptr _exitFunc, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outExpl = NULL;
modelica_metatype _outArg = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outExpl = omc_List_map2FoldCheckReferenceEq(threadData, _inExpl, boxvar_AbsynUtil_traverseExpBidir, ((modelica_fnptr) _enterFunc), ((modelica_fnptr) _exitFunc), _inArg ,&_outArg);
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outExpl;
}
DLLExport
modelica_metatype omc_AbsynUtil_traverseExpList(threadData_t *threadData, modelica_metatype _inExpList, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outExpList = NULL;
modelica_metatype _outArg = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outExpList = omc_AbsynUtil_traverseExpListBidir(threadData, _inExpList, boxvar_AbsynUtil_dummyTraverseExp, ((modelica_fnptr) _inFunc), _inArg ,&_outArg);
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outExpList;
}
DLLExport
modelica_metatype omc_AbsynUtil_traverseExpTopDown(threadData_t *threadData, modelica_metatype _inExp, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outArg = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outExp = omc_AbsynUtil_traverseExpBidir(threadData, _inExp, ((modelica_fnptr) _inFunc), boxvar_AbsynUtil_dummyTraverseExp, _inArg ,&_outArg);
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outExp;
}
DLLExport
modelica_metatype omc_AbsynUtil_traverseExp(threadData_t *threadData, modelica_metatype _inExp, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outArg = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outExp = omc_AbsynUtil_traverseExpBidir(threadData, _inExp, boxvar_AbsynUtil_dummyTraverseExp, ((modelica_fnptr) _inFunc), _inArg ,&_outArg);
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outExp;
}
