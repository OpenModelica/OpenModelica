#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "InstVar.c"
#endif
#include "omc_simulation_settings.h"
#include "InstVar.h"
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT0,2,3) {&DAE_DAElist_DAE__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT0 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,1,11) {&DAE_Type_T__UNKNOWN__desc,}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,0,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,1,4) {&InstTypes_CallingScope_INNER__CALL__desc,}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,1,5) {&DAE_Const_C__VAR__desc,}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,4,4) {&DAE_ComponentRef_CREF__IDENT__desc,_OMC_LIT2,_OMC_LIT1,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,2,0) {_OMC_LIT5,_OMC_LIT5}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,1,4) {&SCode_Initial_NON__INITIAL__desc,}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "instArray Real[0]"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,17,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,2,3) {&DAE_Exp_ICONST__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,2,6) {&DAE_Exp_BCONST__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,2,6) {&DAE_Exp_BCONST__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1))}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT12,2,5) {&DAE_Subscript_INDEX__desc,_OMC_LIT10}};
#define _OMC_LIT12 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT12)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT13,2,5) {&DAE_Subscript_INDEX__desc,_OMC_LIT11}};
#define _OMC_LIT13 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT13)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT14,1,3) {&SCode_Variability_VAR__desc,}};
#define _OMC_LIT14 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data "["
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,1,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data ", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,2,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data "]"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,1,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
#define _OMC_LIT18_data "("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT18,1,_OMC_LIT18_data);
#define _OMC_LIT18 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT18)
#define _OMC_LIT19_data "="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT19,1,_OMC_LIT19_data);
#define _OMC_LIT19 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data ")"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,1,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT21,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT21 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT21)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT22,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT22 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT22)
#define _OMC_LIT23_data "Instantiation of array component: %s failed because index modification: %s is invalid.\n	Array component: %s has more dimensions than binding %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT23,144,_OMC_LIT23_data);
#define _OMC_LIT23 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT23)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT24,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT23}};
#define _OMC_LIT24 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT24)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT25,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(140)),_OMC_LIT21,_OMC_LIT22,_OMC_LIT24}};
#define _OMC_LIT25 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "failtrace"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,9,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data "Sets whether to print a failtrace or not."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,41,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT28,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT27}};
#define _OMC_LIT28 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT28)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT29,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT26,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT28}};
#define _OMC_LIT29 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT29)
#define _OMC_LIT30_data "- Inst.instArray failed: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT30,25,_OMC_LIT30_data);
#define _OMC_LIT30 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data "Array dimension mismatch, expression %s has type %s, expected array dimensions [%s]."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,84,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT32,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT31}};
#define _OMC_LIT32 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT32)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT33,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(43)),_OMC_LIT21,_OMC_LIT22,_OMC_LIT32}};
#define _OMC_LIT33 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT33)
#define _OMC_LIT34_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT34,1,_OMC_LIT34_data);
#define _OMC_LIT34 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT34)
#define _OMC_LIT35_data "quantity"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT35,8,_OMC_LIT35_data);
#define _OMC_LIT35 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT35)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT36,2,4) {&DAE_Type_T__REAL__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT36 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT36)
#define _OMC_LIT37_data "Negative dimension index (%s) for component %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT37,47,_OMC_LIT37_data);
#define _OMC_LIT37 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT37)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT38,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT37}};
#define _OMC_LIT38 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT38)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT39,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(265)),_OMC_LIT21,_OMC_LIT22,_OMC_LIT38}};
#define _OMC_LIT39 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT39)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT40,1,4) {&DAE_Connect_Face_OUTSIDE__desc,}};
#define _OMC_LIT40 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT40)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT41,1,5) {&Absyn_Direction_BIDIR__desc,}};
#define _OMC_LIT41 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT41)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT42,9,3) {&SCode_ClassDef_PARTS__desc,MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT42 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT42)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT43,1,5) {&DAE_Mod_NOMOD__desc,}};
#define _OMC_LIT43 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT43)
#define _OMC_LIT44_data "useLocalDirection"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT44,17,_OMC_LIT44_data);
#define _OMC_LIT44 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT44)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT45,1,4) {&Flags_FlagVisibility_EXTERNAL__desc,}};
#define _OMC_LIT45 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT45)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT46,2,4) {&Flags_FlagData_BOOL__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT46 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT46)
#define _OMC_LIT47_data "Keeps the input/output prefix for all variables in the flat model, not only top-level ones."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT47,91,_OMC_LIT47_data);
#define _OMC_LIT47 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT47)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT48,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT47}};
#define _OMC_LIT48 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT48)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT49,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(74)),_OMC_LIT44,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT45,_OMC_LIT46,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT48}};
#define _OMC_LIT49 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT49)
#define _OMC_LIT50_data "- Inst.instScalar failed on "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT50,28,_OMC_LIT50_data);
#define _OMC_LIT50 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT50)
#define _OMC_LIT51_data " in scope "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT51,10,_OMC_LIT51_data);
#define _OMC_LIT51 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT51)
#define _OMC_LIT52_data " env: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT52,6,_OMC_LIT52_data);
#define _OMC_LIT52 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT52)
#define _OMC_LIT53_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT53,1,_OMC_LIT53_data);
#define _OMC_LIT53 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT53)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT54,7,3) {&ConnectionGraph_ConnectionGraph_GRAPH__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT54 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT54)
#define _OMC_LIT55_data "Failed to deduce dimension %s of %s due to missing binding equation."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT55,68,_OMC_LIT55_data);
#define _OMC_LIT55 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT55)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT56,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT55}};
#define _OMC_LIT56 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT56)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT57,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(188)),_OMC_LIT21,_OMC_LIT22,_OMC_LIT56}};
#define _OMC_LIT57 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT57)
#define _OMC_LIT58_data "- InstVar.instVar2 failed: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT58,27,_OMC_LIT58_data);
#define _OMC_LIT58 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT58)
#define _OMC_LIT59_data ")\n  Scope: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT59,11,_OMC_LIT59_data);
#define _OMC_LIT59 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT59)
#define _OMC_LIT60_data "Identifier %s is reserved for the built-in element with the same name."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT60,70,_OMC_LIT60_data);
#define _OMC_LIT60 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT60)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT61,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT60}};
#define _OMC_LIT61 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT61)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT62,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(278)),_OMC_LIT21,_OMC_LIT22,_OMC_LIT61}};
#define _OMC_LIT62 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT62)
#define _OMC_LIT63_data "Integer"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT63,7,_OMC_LIT63_data);
#define _OMC_LIT63 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT63)
#define _OMC_LIT64_data "Real"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT64,4,_OMC_LIT64_data);
#define _OMC_LIT64 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT64)
#define _OMC_LIT65_data "Boolean"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT65,7,_OMC_LIT65_data);
#define _OMC_LIT65 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT65)
#define _OMC_LIT66_data "String"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT66,6,_OMC_LIT66_data);
#define _OMC_LIT66 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT66)
#define _OMC_LIT67_data "time"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT67,4,_OMC_LIT67_data);
#define _OMC_LIT67 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT67)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT68,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT2}};
#define _OMC_LIT68 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT68)
#define _OMC_LIT69_data " "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT69,1,_OMC_LIT69_data);
#define _OMC_LIT69 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT69)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT70,1,5) {&ErrorTypes_Severity_WARNING__desc,}};
#define _OMC_LIT70 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT70)
#define _OMC_LIT71_data "Ignoring the modification on outer element: %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT71,47,_OMC_LIT71_data);
#define _OMC_LIT71 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT71)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT72,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT71}};
#define _OMC_LIT72 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT72)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT73,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(512)),_OMC_LIT21,_OMC_LIT70,_OMC_LIT72}};
#define _OMC_LIT73 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT73)
#define _OMC_LIT74_data "No corresponding 'inner' declaration found for component %s declared as '%s'.\n  The existing 'inner' components are:\n    %s\n  Check if you have not misspelled the 'outer' component name.\n  Please declare an 'inner' component with the same name in the top scope.\n  Continuing flattening by only considering the 'outer' component declaration."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT74,340,_OMC_LIT74_data);
#define _OMC_LIT74 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT74)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT75,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT74}};
#define _OMC_LIT75 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT75)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT76,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(108)),_OMC_LIT21,_OMC_LIT70,_OMC_LIT75}};
#define _OMC_LIT76 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT76)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT77,1,3) {&DAE_Prefix_NOPRE__desc,}};
#define _OMC_LIT77 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT77)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT78,2,1) {_OMC_LIT77,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT78 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT78)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT79,1,4) {&Absyn_InnerOuter_OUTER__desc,}};
#define _OMC_LIT79 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT79)
#define _OMC_LIT80_data "- InstVar.instVar failed while instatiating variable: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT80,54,_OMC_LIT80_data);
#define _OMC_LIT80 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT80)
#define _OMC_LIT81_data "\nin scope: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT81,11,_OMC_LIT81_data);
#define _OMC_LIT81 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT81)
#define _OMC_LIT82_data " class:\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT82,8,_OMC_LIT82_data);
#define _OMC_LIT82 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT82)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT83,10,3) {&SCodeDump_SCodeDumpOptions_OPTIONS__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT83 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT83)
#include "util/modelica.h"
#include "InstVar_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_instArrayDimEnum(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_string _inName, modelica_metatype _inClass, modelica_metatype _inAttributes, modelica_metatype _inPrefixes, modelica_metatype _inDimension, modelica_metatype _inRestDimensions, modelica_metatype _inSubscripts, modelica_metatype _inInstDims, modelica_boolean _inImpl, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstVar_instArrayDimEnum(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inName, modelica_metatype _inClass, modelica_metatype _inAttributes, modelica_metatype _inPrefixes, modelica_metatype _inDimension, modelica_metatype _inRestDimensions, modelica_metatype _inSubscripts, modelica_metatype _inInstDims, modelica_metatype _inImpl, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstVar_instArrayDimEnum,2,0) {(void*) boxptr_InstVar_instArrayDimEnum,0}};
#define boxvar_InstVar_instArrayDimEnum MMC_REFSTRUCTLIT(boxvar_lit_InstVar_instArrayDimEnum)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_instArrayDimInteger(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_string _inName, modelica_metatype _inElement, modelica_metatype _inPrefixes, modelica_integer _inDimensionSize, modelica_metatype _inRestDimensions, modelica_metatype _inSubscripts, modelica_metatype _inInstDims, modelica_boolean _inImpl, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstVar_instArrayDimInteger(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inName, modelica_metatype _inElement, modelica_metatype _inPrefixes, modelica_metatype _inDimensionSize, modelica_metatype _inRestDimensions, modelica_metatype _inSubscripts, modelica_metatype _inInstDims, modelica_metatype _inImpl, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstVar_instArrayDimInteger,2,0) {(void*) boxptr_InstVar_instArrayDimInteger,0}};
#define boxvar_InstVar_instArrayDimInteger MMC_REFSTRUCTLIT(boxvar_lit_InstVar_instArrayDimInteger)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_instArray(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_string _inIdent, modelica_metatype _inElement, modelica_metatype _inPrefixes, modelica_integer _inInteger, modelica_metatype _inDimension, modelica_metatype _inDimensionLst, modelica_metatype _inIntegerLst, modelica_metatype _inInstDims, modelica_boolean _inBoolean, modelica_metatype _inComment, modelica_metatype _info, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstVar_instArray(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inIdent, modelica_metatype _inElement, modelica_metatype _inPrefixes, modelica_metatype _inInteger, modelica_metatype _inDimension, modelica_metatype _inDimensionLst, modelica_metatype _inIntegerLst, modelica_metatype _inInstDims, modelica_metatype _inBoolean, modelica_metatype _inComment, modelica_metatype _info, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstVar_instArray,2,0) {(void*) boxptr_InstVar_instArray,0}};
#define boxvar_InstVar_instArray MMC_REFSTRUCTLIT(boxvar_lit_InstVar_instArray)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_InstVar_checkArrayModBindingDimSize(threadData_t *threadData, modelica_metatype _inBinding, modelica_metatype _inDimension, modelica_metatype _inPrefix, modelica_string _inIdent, modelica_metatype _inInfo);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstVar_checkArrayModBindingDimSize(threadData_t *threadData, modelica_metatype _inBinding, modelica_metatype _inDimension, modelica_metatype _inPrefix, modelica_metatype _inIdent, modelica_metatype _inInfo);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstVar_checkArrayModBindingDimSize,2,0) {(void*) boxptr_InstVar_checkArrayModBindingDimSize,0}};
#define boxvar_InstVar_checkArrayModBindingDimSize MMC_REFSTRUCTLIT(boxvar_lit_InstVar_checkArrayModBindingDimSize)
PROTECTED_FUNCTION_STATIC void omc_InstVar_checkArraySubModDimSize(threadData_t *threadData, modelica_metatype _inSubMod, modelica_metatype _inDimension, modelica_metatype _inPrefix, modelica_string _inIdent, modelica_metatype _inInfo);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstVar_checkArraySubModDimSize,2,0) {(void*) boxptr_InstVar_checkArraySubModDimSize,0}};
#define boxvar_InstVar_checkArraySubModDimSize MMC_REFSTRUCTLIT(boxvar_lit_InstVar_checkArraySubModDimSize)
PROTECTED_FUNCTION_STATIC void omc_InstVar_checkArrayModDimSize(threadData_t *threadData, modelica_metatype _mod, modelica_metatype _inDimension, modelica_metatype _inPrefix, modelica_string _inIdent, modelica_metatype _inInfo);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstVar_checkArrayModDimSize,2,0) {(void*) boxptr_InstVar_checkArrayModDimSize,0}};
#define boxvar_InstVar_checkArrayModDimSize MMC_REFSTRUCTLIT(boxvar_lit_InstVar_checkArrayModDimSize)
PROTECTED_FUNCTION_STATIC void omc_InstVar_checkDimensionGreaterThanZero(threadData_t *threadData, modelica_metatype _inDim, modelica_metatype _inPrefix, modelica_string _inIdent, modelica_metatype _info);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstVar_checkDimensionGreaterThanZero,2,0) {(void*) boxptr_InstVar_checkDimensionGreaterThanZero,0}};
#define boxvar_InstVar_checkDimensionGreaterThanZero MMC_REFSTRUCTLIT(boxvar_lit_InstVar_checkDimensionGreaterThanZero)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_stripRecordDefaultBindingsFromElement(threadData_t *threadData, modelica_metatype _inVar, modelica_metatype _inEqs, modelica_metatype *out_outEqs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstVar_stripRecordDefaultBindingsFromElement,2,0) {(void*) boxptr_InstVar_stripRecordDefaultBindingsFromElement,0}};
#define boxvar_InstVar_stripRecordDefaultBindingsFromElement MMC_REFSTRUCTLIT(boxvar_lit_InstVar_stripRecordDefaultBindingsFromElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_stripRecordDefaultBindingsFromDAE(threadData_t *threadData, modelica_metatype _inClassDAE, modelica_metatype _inType, modelica_metatype _inEqDAE);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstVar_stripRecordDefaultBindingsFromDAE,2,0) {(void*) boxptr_InstVar_stripRecordDefaultBindingsFromDAE,0}};
#define boxvar_InstVar_stripRecordDefaultBindingsFromDAE MMC_REFSTRUCTLIT(boxvar_lit_InstVar_stripRecordDefaultBindingsFromDAE)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_instScalar2(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inType, modelica_metatype _inVariability, modelica_metatype _inMod, modelica_metatype _inDae, modelica_metatype _inClassDae, modelica_metatype _inSource, modelica_boolean _inImpl);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstVar_instScalar2(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inType, modelica_metatype _inVariability, modelica_metatype _inMod, modelica_metatype _inDae, modelica_metatype _inClassDae, modelica_metatype _inSource, modelica_metatype _inImpl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstVar_instScalar2,2,0) {(void*) boxptr_InstVar_instScalar2,0}};
#define boxvar_InstVar_instScalar2 MMC_REFSTRUCTLIT(boxvar_lit_InstVar_instScalar2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_stripVarAttrDirection(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _ih, modelica_metatype _inState, modelica_metatype _inPrefix, modelica_metatype _inAttributes);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstVar_stripVarAttrDirection,2,0) {(void*) boxptr_InstVar_stripVarAttrDirection,0}};
#define boxvar_InstVar_stripVarAttrDirection MMC_REFSTRUCTLIT(boxvar_lit_InstVar_stripVarAttrDirection)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_instVar2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_string _inName, modelica_metatype _inClass, modelica_metatype _inAttributes, modelica_metatype _inPrefixes, modelica_metatype _inDimensions, modelica_metatype _inSubscripts, modelica_metatype _inInstDims, modelica_boolean _inImpl, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstVar_instVar2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inName, modelica_metatype _inClass, modelica_metatype _inAttributes, modelica_metatype _inPrefixes, modelica_metatype _inDimensions, modelica_metatype _inSubscripts, modelica_metatype _inInstDims, modelica_metatype _inImpl, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstVar_instVar2,2,0) {(void*) boxptr_InstVar_instVar2,0}};
#define boxvar_InstVar_instVar2 MMC_REFSTRUCTLIT(boxvar_lit_InstVar_instVar2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_addArrayVarEquation(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inState, modelica_metatype _inDae, modelica_metatype _inType, modelica_metatype _mod, modelica_metatype _const, modelica_metatype _pre, modelica_string _n, modelica_metatype _source, modelica_metatype *out_outDae);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstVar_addArrayVarEquation,2,0) {(void*) boxptr_InstVar_addArrayVarEquation,0}};
#define boxvar_InstVar_addArrayVarEquation MMC_REFSTRUCTLIT(boxvar_lit_InstVar_addArrayVarEquation)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_liftUserTypeEqMod(threadData_t *threadData, modelica_metatype _inEqMod, modelica_metatype _inDims);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstVar_liftUserTypeEqMod,2,0) {(void*) boxptr_InstVar_liftUserTypeEqMod,0}};
#define boxvar_InstVar_liftUserTypeEqMod MMC_REFSTRUCTLIT(boxvar_lit_InstVar_liftUserTypeEqMod)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_liftUserTypeSubMod(threadData_t *threadData, modelica_metatype _inSubMod, modelica_metatype _inDims);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstVar_liftUserTypeSubMod,2,0) {(void*) boxptr_InstVar_liftUserTypeSubMod,0}};
#define boxvar_InstVar_liftUserTypeSubMod MMC_REFSTRUCTLIT(boxvar_lit_InstVar_liftUserTypeSubMod)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_liftUserTypeMod(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _inDims);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstVar_liftUserTypeMod,2,0) {(void*) boxptr_InstVar_liftUserTypeMod,0}};
#define boxvar_InstVar_liftUserTypeMod MMC_REFSTRUCTLIT(boxvar_lit_InstVar_liftUserTypeMod)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_instVar__dispatch(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_string _inName, modelica_metatype _inClass, modelica_metatype _inAttributes, modelica_metatype _inPrefixes, modelica_metatype _inDimensions, modelica_metatype _inIndices, modelica_metatype _inInstDims, modelica_boolean _inImpl, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstVar_instVar__dispatch(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inName, modelica_metatype _inClass, modelica_metatype _inAttributes, modelica_metatype _inPrefixes, modelica_metatype _inDimensions, modelica_metatype _inIndices, modelica_metatype _inInstDims, modelica_metatype _inImpl, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstVar_instVar__dispatch,2,0) {(void*) boxptr_InstVar_instVar__dispatch,0}};
#define boxvar_InstVar_instVar__dispatch MMC_REFSTRUCTLIT(boxvar_lit_InstVar_instVar__dispatch)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_instArrayDimEnum(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_string _inName, modelica_metatype _inClass, modelica_metatype _inAttributes, modelica_metatype _inPrefixes, modelica_metatype _inDimension, modelica_metatype _inRestDimensions, modelica_metatype _inSubscripts, modelica_metatype _inInstDims, modelica_boolean _inImpl, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outIH = NULL;
modelica_metatype _outStore = NULL;
modelica_metatype _outDae = NULL;
modelica_metatype _outSets = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _outGraph = NULL;
modelica_metatype _enum_path = NULL;
modelica_metatype _enum_lit_path = NULL;
modelica_metatype _literals = NULL;
modelica_integer _i;
modelica_metatype _e = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _dae = NULL;
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
_outCache = _inCache;
_outEnv = _inEnv;
_outIH = _inIH;
_outStore = _inStore;
_outDae = _OMC_LIT0;
_outSets = _inSets;
_outType = _OMC_LIT1;
_outGraph = _inGraph;
_i = ((modelica_integer) 1);
tmpMeta1 = _inDimension;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,2,3) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_enum_path = tmpMeta2;
_literals = tmpMeta3;
{
modelica_metatype _lit;
for (tmpMeta4 = _literals; !listEmpty(tmpMeta4); tmpMeta4=MMC_CDR(tmpMeta4))
{
_lit = MMC_CAR(tmpMeta4);
tmpMeta5 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _lit);
_enum_lit_path = omc_AbsynUtil_joinPaths(threadData, _enum_path, tmpMeta5);
tmpMeta6 = mmc_mk_box3(8, &DAE_Exp_ENUM__LITERAL__desc, _enum_lit_path, mmc_mk_integer(_i));
_e = tmpMeta6;
_mod = omc_Mod_lookupIdxModification(threadData, _inMod, _e);
_i = ((modelica_integer) 1) + _i;
tmpMeta8 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, _e);
tmpMeta7 = mmc_mk_cons(tmpMeta8, _inSubscripts);
_outCache = omc_InstVar_instVar2(threadData, _outCache, _inEnv, _outIH, _outStore, _inState, _mod, _inPrefix, _inName, _inClass, _inAttributes, _inPrefixes, _inRestDimensions, tmpMeta7, _inInstDims, _inImpl, _inComment, _inInfo, _outGraph, _outSets ,&_outEnv ,&_outIH ,&_outStore ,&_dae ,&_outSets ,&_outType ,&_outGraph);
_outDae = omc_DAEUtil_joinDaes(threadData, _outDae, _dae);
}
}
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outIH) { *out_outIH = _outIH; }
if (out_outStore) { *out_outStore = _outStore; }
if (out_outDae) { *out_outDae = _outDae; }
if (out_outSets) { *out_outSets = _outSets; }
if (out_outType) { *out_outType = _outType; }
if (out_outGraph) { *out_outGraph = _outGraph; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstVar_instArrayDimEnum(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inName, modelica_metatype _inClass, modelica_metatype _inAttributes, modelica_metatype _inPrefixes, modelica_metatype _inDimension, modelica_metatype _inRestDimensions, modelica_metatype _inSubscripts, modelica_metatype _inInstDims, modelica_metatype _inImpl, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph)
{
modelica_integer tmp1;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inImpl);
_outCache = omc_InstVar_instArrayDimEnum(threadData, _inCache, _inEnv, _inIH, _inStore, _inState, _inMod, _inPrefix, _inName, _inClass, _inAttributes, _inPrefixes, _inDimension, _inRestDimensions, _inSubscripts, _inInstDims, tmp1, _inComment, _inInfo, _inGraph, _inSets, out_outEnv, out_outIH, out_outStore, out_outDae, out_outSets, out_outType, out_outGraph);
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_instArrayDimInteger(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_string _inName, modelica_metatype _inElement, modelica_metatype _inPrefixes, modelica_integer _inDimensionSize, modelica_metatype _inRestDimensions, modelica_metatype _inSubscripts, modelica_metatype _inInstDims, modelica_boolean _inImpl, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outIH = NULL;
modelica_metatype _outStore = NULL;
modelica_metatype _outDae = NULL;
modelica_metatype _outSets = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _outGraph = NULL;
modelica_metatype _c = NULL;
modelica_metatype _cls = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _imod = NULL;
modelica_metatype _cls_path = NULL;
modelica_metatype _smod = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _e = NULL;
modelica_metatype _s = NULL;
modelica_metatype _inst_dims = NULL;
modelica_metatype _dae = NULL;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_integer tmp21;
modelica_integer tmp22;
modelica_integer tmp23;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCache = _inCache;
_outEnv = _inEnv;
_outIH = _inIH;
_outStore = _inStore;
_outDae = _OMC_LIT0;
_outSets = _inSets;
_outType = _OMC_LIT1;
_outGraph = _inGraph;
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
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,2,8) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,2,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
if (optionNone(tmpMeta10)) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 1));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_c = tmpMeta6;
_cls_path = tmpMeta9;
_smod = tmpMeta12;
_attr = tmpMeta13;
omc_Lookup_lookupClass(threadData, _outCache, _outEnv, _cls_path, mmc_mk_some((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_c), 9)))) ,&_cls ,NULL);
_smod = omc_InstUtil_chainRedeclares(threadData, _inMod, _smod);
tmpMeta14 = mmc_mk_box2(5, &Mod_ModScope_DERIVED__desc, _cls_path);
omc_Mod_elabMod(threadData, _outCache, _outEnv, _outIH, _inPrefix, _smod, _inImpl, tmpMeta14, _inInfo ,&_mod);
_mod = omc_Mod_merge(threadData, _inMod, _mod, _OMC_LIT2, 1);
tmpMeta15 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = _cls;
tmpMeta[0+1] = _mod;
tmpMeta[0+2] = _attr;
tmpMeta[0+3] = tmpMeta15;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cls = tmpMeta16;
_attr = tmpMeta17;
tmpMeta[0+0] = _cls;
tmpMeta[0+1] = _inMod;
tmpMeta[0+2] = _attr;
tmpMeta[0+3] = _inInstDims;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_cls = tmpMeta[0+0];
_mod = tmpMeta[0+1];
_attr = tmpMeta[0+2];
_inst_dims = tmpMeta[0+3];
tmp21 = _inDimensionSize; tmp22 = ((modelica_integer) -1); tmp23 = ((modelica_integer) 1);
if(!(((tmp22 > 0) && (tmp21 > tmp23)) || ((tmp22 < 0) && (tmp21 < tmp23))))
{
modelica_integer _i;
for(_i = _inDimensionSize; in_range_integer(_i, tmp21, tmp23); _i += tmp22)
{
tmpMeta18 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
_e = tmpMeta18;
_imod = omc_Mod_lookupIdxModification(threadData, _mod, _e);
tmpMeta19 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, _e);
_s = tmpMeta19;
tmpMeta20 = mmc_mk_cons(_s, _inSubscripts);
_outCache = omc_InstVar_instVar2(threadData, _outCache, _inEnv, _outIH, _outStore, _inState, _imod, _inPrefix, _inName, _cls, _attr, _inPrefixes, _inRestDimensions, tmpMeta20, _inst_dims, _inImpl, _inComment, _inInfo, _outGraph, _outSets ,&_outEnv ,&_outIH ,&_outStore ,&_dae ,&_outSets ,&_outType ,&_outGraph);
_outDae = omc_DAEUtil_joinDaes(threadData, _dae, _outDae);
}
}
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outIH) { *out_outIH = _outIH; }
if (out_outStore) { *out_outStore = _outStore; }
if (out_outDae) { *out_outDae = _outDae; }
if (out_outSets) { *out_outSets = _outSets; }
if (out_outType) { *out_outType = _outType; }
if (out_outGraph) { *out_outGraph = _outGraph; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstVar_instArrayDimInteger(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inName, modelica_metatype _inElement, modelica_metatype _inPrefixes, modelica_metatype _inDimensionSize, modelica_metatype _inRestDimensions, modelica_metatype _inSubscripts, modelica_metatype _inInstDims, modelica_metatype _inImpl, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inDimensionSize);
tmp2 = mmc_unbox_integer(_inImpl);
_outCache = omc_InstVar_instArrayDimInteger(threadData, _inCache, _inEnv, _inIH, _inStore, _inState, _inMod, _inPrefix, _inName, _inElement, _inPrefixes, tmp1, _inRestDimensions, _inSubscripts, _inInstDims, tmp2, _inComment, _inInfo, _inGraph, _inSets, out_outEnv, out_outIH, out_outStore, out_outDae, out_outSets, out_outType, out_outGraph);
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_instArray(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_string _inIdent, modelica_metatype _inElement, modelica_metatype _inPrefixes, modelica_integer _inInteger, modelica_metatype _inDimension, modelica_metatype _inDimensionLst, modelica_metatype _inIntegerLst, modelica_metatype _inInstDims, modelica_boolean _inBoolean, modelica_metatype _inComment, modelica_metatype _info, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outIH = NULL;
modelica_metatype _outStore = NULL;
modelica_metatype _outDae = NULL;
modelica_metatype _outSets = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_InstVar_checkDimensionGreaterThanZero(threadData, _inDimension, _inPrefix, _inIdent, _info);
omc_InstVar_checkArrayModDimSize(threadData, _inMod, _inDimension, _inPrefix, _inIdent, _info);
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;volatile modelica_metatype tmp4_5;volatile modelica_metatype tmp4_6;volatile modelica_metatype tmp4_7;volatile modelica_string tmp4_8;volatile modelica_metatype tmp4_9;volatile modelica_metatype tmp4_10;volatile modelica_integer tmp4_11;volatile modelica_metatype tmp4_12;volatile modelica_metatype tmp4_13;volatile modelica_metatype tmp4_14;volatile modelica_metatype tmp4_15;volatile modelica_boolean tmp4_16;volatile modelica_metatype tmp4_17;volatile modelica_metatype tmp4_18;volatile modelica_metatype tmp4_19;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inIH;
tmp4_4 = _inStore;
tmp4_5 = _inState;
tmp4_6 = _inMod;
tmp4_7 = _inPrefix;
tmp4_8 = _inIdent;
tmp4_9 = _inElement;
tmp4_10 = _inPrefixes;
tmp4_11 = _inInteger;
tmp4_12 = _inDimension;
tmp4_13 = _inDimensionLst;
tmp4_14 = _inIntegerLst;
tmp4_15 = _inInstDims;
tmp4_16 = _inBoolean;
tmp4_17 = _inComment;
tmp4_18 = _inGraph;
tmp4_19 = _inSets;
{
modelica_metatype _e = NULL;
modelica_metatype _lhs = NULL;
modelica_metatype _rhs = NULL;
modelica_metatype _p = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env_1 = NULL;
modelica_metatype _env = NULL;
modelica_metatype _compenv = NULL;
modelica_metatype _csets = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _ci_state = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _ty_1 = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _mod_1 = NULL;
modelica_metatype _mod_2 = NULL;
modelica_metatype _pre = NULL;
modelica_string _n = NULL;
modelica_string _str1 = NULL;
modelica_string _str2 = NULL;
modelica_string _str3 = NULL;
modelica_string _str4 = NULL;
modelica_metatype _cl = NULL;
modelica_metatype _attr = NULL;
modelica_integer _i;
modelica_integer _stop;
modelica_metatype _dim = NULL;
modelica_metatype _dims = NULL;
modelica_metatype _idxs = NULL;
modelica_metatype _inst_dims = NULL;
modelica_boolean _impl;
modelica_metatype _comment = NULL;
modelica_metatype _dae = NULL;
modelica_metatype _dae1 = NULL;
modelica_metatype _dae2 = NULL;
modelica_metatype _daeLst = NULL;
modelica_metatype _graph = NULL;
modelica_metatype _ih = NULL;
modelica_metatype _source = NULL;
modelica_metatype _s = NULL;
modelica_metatype _pf = NULL;
modelica_metatype _store = NULL;
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
modelica_boolean tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_5,8,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_9), 1));
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_store = tmp4_4;
_mod = tmp4_6;
_pre = tmp4_7;
_n = tmp4_8;
_cl = tmpMeta6;
_dim = tmp4_12;
_inst_dims = tmp4_15;
_graph = tmp4_18;
_csets = tmp4_19;
tmp7 = omc_Expression_dimensionUnknownOrExp(threadData, _dim);
if (1 != tmp7) goto goto_2;
tmpMeta8 = omc_Mod_modEquation(threadData, _mod);
if (optionNone(tmpMeta8)) goto goto_2;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,0,5) == 0) goto goto_2;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 4));
_e = tmpMeta10;
_p = tmpMeta11;
_cache = omc_Inst_instClass(threadData, _cache, _env, _ih, _store, _mod, _pre, _cl, _inst_dims, 1, _OMC_LIT3, _graph, _csets ,&_env_1 ,&_ih ,&_store ,NULL ,NULL ,&_ty ,NULL ,NULL ,&_graph);
_ty_1 = omc_Types_simplifyType(threadData, _ty);
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_PrefixUtil_prefixCref(threadData, _cache, _env, _ih, _pre, omc_ComponentReference_makeCrefIdent(threadData, _n, _ty_1, tmpMeta12) ,&_cr);
tmpMeta13 = mmc_mk_box3(3, &DAE_Properties_PROP__desc, _ty, _OMC_LIT4);
_rhs = omc_Types_matchProp(threadData, _e, _p, tmpMeta13, 1, NULL);
_source = omc_ElementSource_createElementSource(threadData, _info, omc_FGraph_getScopePath(threadData, _env), _pre, _OMC_LIT6);
_lhs = omc_Expression_makeCrefExp(threadData, _cr, _ty_1);
_dae = omc_InstSection_makeDaeEquation(threadData, _lhs, _rhs, _source, _OMC_LIT7);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env_1;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = _store;
tmpMeta[0+4] = _dae;
tmpMeta[0+5] = _inSets;
tmpMeta[0+6] = _ty;
tmpMeta[0+7] = _graph;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_boolean tmp16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_9), 1));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_9), 2));
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_store = tmp4_4;
_ci_state = tmp4_5;
_mod = tmp4_6;
_pre = tmp4_7;
_n = tmp4_8;
_cl = tmpMeta14;
_attr = tmpMeta15;
_pf = tmp4_10;
_i = tmp4_11;
_dims = tmp4_13;
_idxs = tmp4_14;
_inst_dims = tmp4_15;
_impl = tmp4_16;
_comment = tmp4_17;
_graph = tmp4_18;
_csets = tmp4_19;
tmp16 = omc_Expression_dimensionKnown(threadData, _inDimension);
if (0 != tmp16) goto goto_2;
tmpMeta17 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
_e = tmpMeta17;
tmpMeta18 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, _e);
_s = tmpMeta18;
_mod = omc_Mod_lookupIdxModification(threadData, _mod, _e);
tmpMeta19 = mmc_mk_cons(_s, _idxs);
tmpMeta[0+0] = omc_InstVar_instVar2(threadData, _cache, _env, _ih, _store, _ci_state, _mod, _pre, _n, _cl, _attr, _pf, _dims, tmpMeta19, _inst_dims, _impl, _comment, _info, _graph, _csets, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3], &tmpMeta[0+4], &tmpMeta[0+5], &tmpMeta[0+6], &tmpMeta[0+7]);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta20;
modelica_integer tmp21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_12,0,1) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_12), 2));
tmp21 = mmc_unbox_integer(tmpMeta20);
if (0 != tmp21) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_9), 1));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_9), 2));
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_store = tmp4_4;
_ci_state = tmp4_5;
_pre = tmp4_7;
_n = tmp4_8;
_cl = tmpMeta22;
_attr = tmpMeta23;
_pf = tmp4_10;
_dims = tmp4_13;
_idxs = tmp4_14;
_inst_dims = tmp4_15;
_impl = tmp4_16;
_comment = tmp4_17;
_graph = tmp4_18;
_csets = tmp4_19;
omc_ErrorExt_setCheckpoint(threadData, _OMC_LIT8);
_e = _OMC_LIT9;
tmpMeta24 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, _e);
_s = tmpMeta24;
_mod = omc_Mod_filterRedeclares(threadData, _inMod);
_mod = omc_Mod_lookupIdxModification(threadData, _mod, _e);
tmpMeta25 = mmc_mk_cons(_s, _idxs);
_cache = omc_InstVar_instVar2(threadData, _cache, _env, _ih, _store, _ci_state, _mod, _pre, _n, _cl, _attr, _pf, _dims, tmpMeta25, _inst_dims, _impl, _comment, _info, _graph, _csets ,&_compenv ,&_ih ,&_store ,NULL ,&_csets ,&_ty ,&_graph);
omc_ErrorExt_rollBack(threadData, _OMC_LIT8);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _compenv;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = _store;
tmpMeta[0+4] = _OMC_LIT0;
tmpMeta[0+5] = _csets;
tmpMeta[0+6] = _ty;
tmpMeta[0+7] = _graph;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta26;
modelica_integer tmp27;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_12,0,1) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_12), 2));
tmp27 = mmc_unbox_integer(tmpMeta26);
if (0 != tmp27) goto tmp3_end;
omc_ErrorExt_delCheckpoint(threadData, _OMC_LIT8);
goto goto_2;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta28;
modelica_integer tmp29;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_12,0,1) == 0) goto tmp3_end;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_12), 2));
tmp29 = mmc_unbox_integer(tmpMeta28);
_stop = tmp29;
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_store = tmp4_4;
_ci_state = tmp4_5;
_graph = tmp4_18;
_csets = tmp4_19;
tmp4 += 2;
tmpMeta[0+0] = omc_InstVar_instArrayDimInteger(threadData, _cache, _env, _ih, _store, _ci_state, _inMod, _inPrefix, _inIdent, _inElement, _inPrefixes, _stop, _inDimensionLst, _inIntegerLst, _inInstDims, _inBoolean, _inComment, _info, _graph, _csets, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3], &tmpMeta[0+4], &tmpMeta[0+5], &tmpMeta[0+6], &tmpMeta[0+7]);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_12,2,3) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_9), 1));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_9), 2));
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_store = tmp4_4;
_ci_state = tmp4_5;
_mod = tmp4_6;
_pre = tmp4_7;
_n = tmp4_8;
_cl = tmpMeta30;
_attr = tmpMeta31;
_pf = tmp4_10;
_dims = tmp4_13;
_idxs = tmp4_14;
_inst_dims = tmp4_15;
_impl = tmp4_16;
_comment = tmp4_17;
_graph = tmp4_18;
_csets = tmp4_19;
tmp4 += 1;
tmpMeta[0+0] = omc_InstVar_instArrayDimEnum(threadData, _cache, _env, _ih, _store, _ci_state, _mod, _pre, _n, _cl, _attr, _pf, _inDimension, _dims, _idxs, _inst_dims, _impl, _comment, _info, _graph, _csets, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3], &tmpMeta[0+4], &tmpMeta[0+5], &tmpMeta[0+6], &tmpMeta[0+7]);
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_12,1,0) == 0) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_9), 1));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_9), 2));
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_store = tmp4_4;
_ci_state = tmp4_5;
_mod = tmp4_6;
_pre = tmp4_7;
_n = tmp4_8;
_cl = tmpMeta32;
_attr = tmpMeta33;
_pf = tmp4_10;
_dims = tmp4_13;
_idxs = tmp4_14;
_inst_dims = tmp4_15;
_impl = tmp4_16;
_comment = tmp4_17;
_graph = tmp4_18;
_csets = tmp4_19;
_mod_1 = omc_Mod_lookupIdxModification(threadData, _mod, _OMC_LIT10);
_mod_2 = omc_Mod_lookupIdxModification(threadData, _mod, _OMC_LIT11);
tmpMeta34 = mmc_mk_cons(_OMC_LIT12, _idxs);
_cache = omc_InstVar_instVar2(threadData, _cache, _env, _ih, _store, _ci_state, _mod_1, _pre, _n, _cl, _attr, _pf, _dims, tmpMeta34, _inst_dims, _impl, _comment, _info, _graph, _csets ,&_env_1 ,&_ih ,&_store ,&_dae1 ,&_csets ,&_ty ,&_graph);
tmpMeta35 = mmc_mk_cons(_OMC_LIT13, _idxs);
_cache = omc_InstVar_instVar2(threadData, _cache, _env, _ih, _store, _ci_state, _mod_2, _pre, _n, _cl, _attr, _pf, _dims, tmpMeta35, _inst_dims, _impl, _comment, _info, _graph, _csets ,NULL ,&_ih ,&_store ,&_dae2 ,&_csets ,&_ty ,&_graph);
_daeLst = omc_DAEUtil_joinDaes(threadData, _dae1, _dae2);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env_1;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = _store;
tmpMeta[0+4] = _daeLst;
tmpMeta[0+5] = _csets;
tmpMeta[0+6] = _ty;
tmpMeta[0+7] = _graph;
goto tmp3_done;
}
case 7: {
modelica_boolean tmp36;
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
_ci_state = tmp4_5;
_mod = tmp4_6;
_pre = tmp4_7;
_n = tmp4_8;
_i = tmp4_11;
_idxs = tmp4_14;
tmp36 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmpMeta38 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
omc_Mod_lookupIdxModification(threadData, _mod, tmpMeta38);
tmp36 = 1;
goto goto_37;
goto_37:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp36) {goto goto_2;}
tmpMeta39 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta40 = MMC_REFSTRUCTLIT(mmc_nil);
_str1 = omc_PrefixUtil_printPrefixStrIgnoreNoPre(threadData, omc_PrefixUtil_prefixAdd(threadData, _n, tmpMeta39, tmpMeta40, _pre, _OMC_LIT14, _ci_state, _info));
tmpMeta41 = stringAppend(_OMC_LIT15,stringDelimitList(omc_List_map(threadData, _idxs, boxvar_ExpressionDump_printSubscriptStr), _OMC_LIT16));
tmpMeta42 = stringAppend(tmpMeta41,_OMC_LIT17);
_str2 = tmpMeta42;
_str3 = omc_Mod_prettyPrintMod(threadData, _mod, ((modelica_integer) 1));
tmpMeta43 = stringAppend(omc_PrefixUtil_printPrefixStrIgnoreNoPre(threadData, _pre),_OMC_LIT18);
tmpMeta44 = stringAppend(tmpMeta43,_n);
tmpMeta45 = stringAppend(tmpMeta44,_str2);
tmpMeta46 = stringAppend(tmpMeta45,_OMC_LIT19);
tmpMeta47 = stringAppend(tmpMeta46,_str3);
tmpMeta48 = stringAppend(tmpMeta47,_OMC_LIT20);
_str4 = tmpMeta48;
tmpMeta49 = stringAppend(_str1,_str2);
_str2 = tmpMeta49;
tmpMeta50 = mmc_mk_cons(_str1, mmc_mk_cons(_str4, mmc_mk_cons(_str2, mmc_mk_cons(_str3, MMC_REFSTRUCTLIT(mmc_nil)))));
omc_Error_addSourceMessage(threadData, _OMC_LIT25, tmpMeta50, _info);
goto goto_2;
goto tmp3_done;
}
case 8: {
modelica_boolean tmp51;
modelica_metatype tmpMeta52;
tmp51 = omc_Flags_isSet(threadData, _OMC_LIT29);
if (1 != tmp51) goto goto_2;
tmpMeta52 = stringAppend(_OMC_LIT30,_inIdent);
omc_Debug_traceln(threadData, tmpMeta52);
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
_outCache = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_outIH = tmpMeta[0+2];
_outStore = tmpMeta[0+3];
_outDae = tmpMeta[0+4];
_outSets = tmpMeta[0+5];
_outType = tmpMeta[0+6];
_outGraph = tmpMeta[0+7];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outIH) { *out_outIH = _outIH; }
if (out_outStore) { *out_outStore = _outStore; }
if (out_outDae) { *out_outDae = _outDae; }
if (out_outSets) { *out_outSets = _outSets; }
if (out_outType) { *out_outType = _outType; }
if (out_outGraph) { *out_outGraph = _outGraph; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstVar_instArray(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inIdent, modelica_metatype _inElement, modelica_metatype _inPrefixes, modelica_metatype _inInteger, modelica_metatype _inDimension, modelica_metatype _inDimensionLst, modelica_metatype _inIntegerLst, modelica_metatype _inInstDims, modelica_metatype _inBoolean, modelica_metatype _inComment, modelica_metatype _info, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inInteger);
tmp2 = mmc_unbox_integer(_inBoolean);
_outCache = omc_InstVar_instArray(threadData, _inCache, _inEnv, _inIH, _inStore, _inState, _inMod, _inPrefix, _inIdent, _inElement, _inPrefixes, tmp1, _inDimension, _inDimensionLst, _inIntegerLst, _inInstDims, tmp2, _inComment, _info, _inGraph, _inSets, out_outEnv, out_outIH, out_outStore, out_outDae, out_outSets, out_outType, out_outGraph);
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_InstVar_checkArrayModBindingDimSize(threadData_t *threadData, modelica_metatype _inBinding, modelica_metatype _inDimension, modelica_metatype _inPrefix, modelica_string _inIdent, modelica_metatype _inInfo)
{
modelica_boolean _outIsCorrect;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inBinding;
{
modelica_metatype _exp = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _ty_dim = NULL;
modelica_integer _dim_size1;
modelica_integer _dim_size2;
modelica_string _exp_str = NULL;
modelica_string _exp_ty_str = NULL;
modelica_string _dims_str = NULL;
modelica_metatype _ty_dims = NULL;
modelica_metatype _info = NULL;
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
modelica_boolean tmp11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 6));
_exp = tmpMeta7;
_ty = tmpMeta9;
_info = tmpMeta10;
_ty_dim = omc_Types_getDimensionNth(threadData, _ty, ((modelica_integer) 1));
_dim_size1 = omc_Expression_dimensionSize(threadData, _inDimension);
_dim_size2 = omc_Expression_dimensionSize(threadData, _ty_dim);
tmp11 = (_dim_size1 != _dim_size2);
if (1 != tmp11) goto goto_2;
_exp_str = omc_ExpressionDump_printExpStr(threadData, _exp);
_exp_ty_str = omc_Types_unparseType(threadData, _ty);
tmpMeta12 = omc_Types_getDimensions(threadData, _ty);
if (listEmpty(tmpMeta12)) goto goto_2;
tmpMeta13 = MMC_CAR(tmpMeta12);
tmpMeta14 = MMC_CDR(tmpMeta12);
_ty_dims = tmpMeta14;
tmpMeta15 = mmc_mk_cons(_inDimension, _ty_dims);
_dims_str = omc_ExpressionDump_dimensionsString(threadData, tmpMeta15);
tmpMeta16 = mmc_mk_cons(_exp_str, mmc_mk_cons(_exp_ty_str, mmc_mk_cons(_dims_str, MMC_REFSTRUCTLIT(mmc_nil))));
tmpMeta17 = mmc_mk_cons(_info, mmc_mk_cons(_inInfo, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addMultiSourceMessage(threadData, _OMC_LIT33, tmpMeta16, tmpMeta17);
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
_outIsCorrect = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsCorrect;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstVar_checkArrayModBindingDimSize(threadData_t *threadData, modelica_metatype _inBinding, modelica_metatype _inDimension, modelica_metatype _inPrefix, modelica_metatype _inIdent, modelica_metatype _inInfo)
{
modelica_boolean _outIsCorrect;
modelica_metatype out_outIsCorrect;
_outIsCorrect = omc_InstVar_checkArrayModBindingDimSize(threadData, _inBinding, _inDimension, _inPrefix, _inIdent, _inInfo);
out_outIsCorrect = mmc_mk_icon(_outIsCorrect);
return out_outIsCorrect;
}
PROTECTED_FUNCTION_STATIC void omc_InstVar_checkArraySubModDimSize(threadData_t *threadData, modelica_metatype _inSubMod, modelica_metatype _inDimension, modelica_metatype _inPrefix, modelica_string _inIdent, modelica_metatype _inInfo)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inSubMod;
{
modelica_string _name = NULL;
modelica_metatype _eqmod = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (8 != MMC_STRLEN(tmpMeta5) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmpMeta5)) != 0) goto tmp2_end;
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_boolean tmp12;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,5) == 0) goto tmp2_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,0) == 0) goto tmp2_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
_name = tmpMeta6;
_eqmod = tmpMeta9;
tmpMeta10 = stringAppend(_inIdent,_OMC_LIT34);
tmpMeta11 = stringAppend(tmpMeta10,_name);
_name = tmpMeta11;
tmp12 = omc_InstVar_checkArrayModBindingDimSize(threadData, _eqmod, _inDimension, _inPrefix, _name, _inInfo);
if (1 != tmp12) goto goto_1;
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
PROTECTED_FUNCTION_STATIC void omc_InstVar_checkArrayModDimSize(threadData_t *threadData, modelica_metatype _mod, modelica_metatype _inDimension, modelica_metatype _inPrefix, modelica_string _inIdent, modelica_metatype _inInfo)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _mod;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,5) == 0) goto tmp2_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta5,1,0) == 0) goto tmp2_end;
omc_List_map4__0(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_mod), 4))), boxvar_InstVar_checkArraySubModDimSize, _inDimension, _inPrefix, _inIdent, _inInfo);
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
return;
}
PROTECTED_FUNCTION_STATIC void omc_InstVar_checkDimensionGreaterThanZero(threadData_t *threadData, modelica_metatype _inDim, modelica_metatype _inPrefix, modelica_string _inIdent, modelica_metatype _info)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inDim;
{
modelica_string _dim_str = NULL;
modelica_string _cr_str = NULL;
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
if((mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inDim), 2)))) < ((modelica_integer) 0)))
{
_dim_str = omc_ExpressionDump_dimensionString(threadData, _inDim);
tmpMeta5 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta6 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _inIdent, _OMC_LIT36, tmpMeta5);
_cr = tmpMeta6;
_cr_str = omc_ComponentReference_printComponentRefStr(threadData, omc_PrefixUtil_prefixCrefNoContext(threadData, _inPrefix, _cr));
tmpMeta7 = mmc_mk_cons(_dim_str, mmc_mk_cons(_cr_str, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessageAndFail(threadData, _OMC_LIT39, tmpMeta7, _info);
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
return;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_stripRecordDefaultBindingsFromElement(threadData_t *threadData, modelica_metatype _inVar, modelica_metatype _inEqs, modelica_metatype *out_outEqs)
{
modelica_metatype _outVar = NULL;
modelica_metatype _outEqs = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inVar;
tmp4_2 = _inEqs;
{
modelica_metatype _var_cr = NULL;
modelica_metatype _eq_cr = NULL;
modelica_metatype _rest_eqs = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_2);
tmpMeta8 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,3,3) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,6,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
_var_cr = tmpMeta6;
_eq_cr = tmpMeta10;
_rest_eqs = tmpMeta8;
if (!omc_ComponentReference_crefEqual(threadData, _var_cr, _eq_cr)) goto tmp3_end;
tmpMeta[0+0] = omc_DAEUtil_setElementVarBinding(threadData, _inVar, mmc_mk_none());
tmpMeta[0+1] = _rest_eqs;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmp4_2);
tmpMeta13 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,8,3) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,6,2) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
_var_cr = tmpMeta11;
_eq_cr = tmpMeta15;
if (!omc_ComponentReference_crefPrefixOf(threadData, _eq_cr, _var_cr)) goto tmp3_end;
tmpMeta[0+0] = omc_DAEUtil_setElementVarBinding(threadData, _inVar, mmc_mk_none());
tmpMeta[0+1] = _inEqs;
goto tmp3_done;
}
case 2: {
tmpMeta[0+0] = _inVar;
tmpMeta[0+1] = _inEqs;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outVar = tmpMeta[0+0];
_outEqs = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outEqs) { *out_outEqs = _outEqs; }
return _outVar;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_stripRecordDefaultBindingsFromDAE(threadData_t *threadData, modelica_metatype _inClassDAE, modelica_metatype _inType, modelica_metatype _inEqDAE)
{
modelica_metatype _outClassDAE = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inClassDAE;
tmp4_2 = _inType;
tmp4_3 = _inEqDAE;
{
modelica_metatype _els = NULL;
modelica_metatype _eqs = NULL;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,9,3) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,3,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_eqs = tmpMeta6;
_els = tmpMeta10;
_els = omc_List_mapFold(threadData, _els, boxvar_InstVar_stripRecordDefaultBindingsFromElement, _eqs, NULL);
tmpMeta11 = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _els);
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _inClassDAE;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outClassDAE = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outClassDAE;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_instScalar2(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inType, modelica_metatype _inVariability, modelica_metatype _inMod, modelica_metatype _inDae, modelica_metatype _inClassDae, modelica_metatype _inSource, modelica_boolean _inImpl)
{
modelica_metatype _outDae = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inType;
tmp4_2 = _inVariability;
tmp4_3 = _inMod;
{
modelica_metatype _dae = NULL;
modelica_metatype _cls_dae = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,5) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 5));
if (optionNone(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,5) == 0) goto tmp3_end;
tmpMeta1 = omc_DAEUtil_joinDaes(threadData, _inClassDae, _inDae);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,5) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 5));
if (optionNone(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,0,5) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,6,2) == 0) goto tmp3_end;
_dae = omc_InstBinding_instModEquation(threadData, _inCref, _inType, _inMod, _inSource, _inImpl);
_dae = omc_InstUtil_moveBindings(threadData, _dae, _inClassDae);
tmpMeta1 = omc_DAEUtil_joinDaes(threadData, _dae, _inDae);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,5) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 5));
if (optionNone(tmpMeta13)) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,0,5) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,20,2) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,6,2) == 0) goto tmp3_end;
_dae = omc_InstBinding_instModEquation(threadData, _inCref, _inType, _inMod, _inSource, _inImpl);
_dae = omc_InstUtil_moveBindings(threadData, _dae, _inClassDae);
tmpMeta1 = omc_DAEUtil_joinDaes(threadData, _dae, _inDae);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,5) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 5));
if (optionNone(tmpMeta17)) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,0,5) == 0) goto tmp3_end;
_dae = omc_InstBinding_instModEquation(threadData, _inCref, _inType, _inMod, _inSource, _inImpl);
_dae = omc_InstUtil_propagateBinding(threadData, _inClassDae, _dae);
tmpMeta1 = omc_DAEUtil_joinDaes(threadData, _dae, _inDae);
goto tmp3_done;
}
case 4: {
_dae = (omc_Types_isComplexType(threadData, _inType)?omc_InstBinding_instModEquation(threadData, _inCref, _inType, _inMod, _inSource, _inImpl):_OMC_LIT0);
_cls_dae = omc_InstVar_stripRecordDefaultBindingsFromDAE(threadData, _inClassDae, _inType, _dae);
_dae = omc_DAEUtil_joinDaes(threadData, _dae, _inDae);
tmpMeta1 = omc_DAEUtil_joinDaes(threadData, _cls_dae, _dae);
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstVar_instScalar2(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inType, modelica_metatype _inVariability, modelica_metatype _inMod, modelica_metatype _inDae, modelica_metatype _inClassDae, modelica_metatype _inSource, modelica_metatype _inImpl)
{
modelica_integer tmp1;
modelica_metatype _outDae = NULL;
tmp1 = mmc_unbox_integer(_inImpl);
_outDae = omc_InstVar_instScalar2(threadData, _inCref, _inType, _inVariability, _inMod, _inDae, _inClassDae, _inSource, tmp1);
return _outDae;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_stripVarAttrDirection(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _ih, modelica_metatype _inState, modelica_metatype _inPrefix, modelica_metatype _inAttributes)
{
modelica_metatype _outAttributes = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inCref;
tmp4_2 = _inState;
tmp4_3 = _inAttributes;
{
modelica_metatype _cref = NULL;
modelica_metatype _topInstance = NULL;
modelica_metatype _sm = NULL;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,2,0) == 0) goto tmp3_end;
tmpMeta1 = _inAttributes;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta1 = _inAttributes;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,2) == 0) goto tmp3_end;
if (!omc_ConnectUtil_faceEqual(threadData, omc_ConnectUtil_componentFaceType(threadData, _inCref), _OMC_LIT40)) goto tmp3_end;
tmpMeta1 = _inAttributes;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_boolean tmp9;
modelica_boolean tmp10;
_topInstance = listHead(_ih);
tmpMeta7 = _topInstance;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
_sm = tmpMeta8;
tmp9 = (omc_BaseHashSet_currentSize(threadData, _sm) > ((modelica_integer) 0));
if (1 != tmp9) goto goto_2;
_cref = omc_PrefixUtil_prefixToCref(threadData, _inPrefix);
tmp10 = omc_BaseHashSet_has(threadData, _cref, _sm);
if (1 != tmp10) goto goto_2;
tmpMeta1 = _inAttributes;
goto tmp3_done;
}
case 4: {
tmpMeta1 = omc_SCodeUtil_setAttributesDirection(threadData, _inAttributes, _OMC_LIT41);
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
_outAttributes = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAttributes;
}
DLLExport
modelica_metatype omc_InstVar_instScalar(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_string _inName, modelica_metatype _inClass, modelica_metatype _inAttributes, modelica_metatype _inPrefixes, modelica_metatype _inSubscripts, modelica_metatype _inInstDims, modelica_boolean _inImpl, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outIH = NULL;
modelica_metatype _outStore = NULL;
modelica_metatype _outDae = NULL;
modelica_metatype _outSets = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;volatile modelica_metatype tmp4_5;volatile modelica_metatype tmp4_6;volatile modelica_metatype tmp4_7;volatile modelica_metatype tmp4_8;volatile modelica_metatype tmp4_9;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inIH;
tmp4_4 = _inStore;
tmp4_5 = _inMod;
tmp4_6 = _inClass;
tmp4_7 = _inAttributes;
tmp4_8 = _inPrefixes;
tmp4_9 = _inSubscripts;
{
modelica_metatype _io = NULL;
modelica_boolean _implicitInstantiation;
modelica_boolean _inStateAndClassNameIsEqual;
modelica_metatype _ci_state = NULL;
modelica_metatype _csets = NULL;
modelica_metatype _graph = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _dae = NULL;
modelica_metatype _dae1 = NULL;
modelica_metatype _dae2 = NULL;
modelica_metatype _source = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _pre = NULL;
modelica_metatype _start = NULL;
modelica_metatype _ident_ty = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _env_1 = NULL;
modelica_metatype _ih = NULL;
modelica_metatype _opt_binding = NULL;
modelica_metatype _dae_var_attr = NULL;
modelica_metatype _opt_attr = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _classWithElementsRemoved = NULL;
modelica_metatype _fin = NULL;
modelica_metatype _res = NULL;
modelica_metatype _vt = NULL;
modelica_metatype _vis = NULL;
modelica_string _cls_name = NULL;
modelica_string _stateName = NULL;
modelica_metatype _store = NULL;
modelica_metatype _predims = NULL;
modelica_metatype _idxs = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
_implicitInstantiation = 0;
_inStateAndClassNameIsEqual = 0;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,2,8) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 6));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_7), 5));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_8), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_8), 4));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_8), 5));
_cls_name = tmpMeta6;
_res = tmpMeta7;
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_store = tmp4_4;
_mod = tmp4_5;
_vt = tmpMeta8;
_vis = tmpMeta9;
_fin = tmpMeta10;
_io = tmpMeta11;
_idxs = tmp4_9;
_idxs = listReverse(_idxs);
tmpMeta12 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _cls_name);
_ci_state = omc_ClassInf_start(threadData, _res, tmpMeta12);
_predims = omc_List_lastListOrEmpty(threadData, _inInstDims);
_pre = omc_PrefixUtil_prefixAdd(threadData, _inName, _predims, _idxs, _inPrefix, _vt, _ci_state, _inInfo);
if(omc_Config_acceptMetaModelicaGrammar(threadData))
{
_stateName = omc_AbsynUtil_pathString(threadData, omc_ClassInf_getStateName(threadData, _inState), _OMC_LIT2, 1, 0);
_inStateAndClassNameIsEqual = (stringEqual(_stateName, _cls_name));
_implicitInstantiation = ((omc_SCodeUtil_isUniontype(threadData, _inClass) && omc_SCodeUtil_isConstant(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inAttributes), 5))))) && _inStateAndClassNameIsEqual);
if(_implicitInstantiation)
{
_classWithElementsRemoved = omc_SCodeUtil_setElementClassDefinition(threadData, _OMC_LIT42, _inClass);
omc_Inst_instClass(threadData, _cache, _env, _ih, _store, _inMod, _pre, _classWithElementsRemoved, _inInstDims, _inImpl, _OMC_LIT3, _inGraph, _inSets ,&_env_1 ,&_ih ,&_store ,&_dae1 ,&_csets ,&_ty ,NULL ,&_opt_attr ,&_graph);
}
else
{
_cache = omc_Inst_instClass(threadData, _cache, _env, _ih, _store, _inMod, _pre, _inClass, _inInstDims, _inImpl, _OMC_LIT3, _inGraph, _inSets ,&_env_1 ,&_ih ,&_store ,&_dae1 ,&_csets ,&_ty ,NULL ,&_opt_attr ,&_graph);
}
}
else
{
_cache = omc_Inst_instClass(threadData, _cache, _env, _ih, _store, _inMod, _pre, _inClass, _inInstDims, _inImpl, _OMC_LIT3, _inGraph, _inSets ,&_env_1 ,&_ih ,&_store ,&_dae1 ,&_csets ,&_ty ,NULL ,&_opt_attr ,&_graph);
}
tmpMeta13 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_InstBinding_instDaeVariableAttributes(threadData, _cache, _env_1, _inMod, _ty, tmpMeta13 ,&_dae_var_attr);
_attr = omc_InstUtil_propagateAbSCDirection(threadData, _vt, _inAttributes, _opt_attr, _inInfo);
_attr = omc_SCodeUtil_removeAttributeDimensions(threadData, _attr);
_ident_ty = omc_InstUtil_makeCrefBaseType(threadData, _ty, _inInstDims);
_cr = omc_ComponentReference_makeCrefIdent(threadData, _inName, _ident_ty, _idxs);
_cache = omc_PrefixUtil_prefixCref(threadData, _cache, _env, _ih, _inPrefix, _cr ,&_cr);
omc_InstUtil_checkModificationOnOuter(threadData, _cache, _env_1, _ih, _inPrefix, _inName, _cr, _inMod, _vt, _io, _inImpl, _inInfo);
_source = omc_ElementSource_createElementSource(threadData, _inInfo, omc_FGraph_getScopePath(threadData, _env_1), _inPrefix, _OMC_LIT6);
_mod = (((((((!listEmpty(_inSubscripts)) && (!omc_SCodeUtil_isParameterOrConst(threadData, _vt))) && (!omc_ClassInf_isFunctionOrRecord(threadData, _inState))) && (!omc_Types_isComplexType(threadData, omc_Types_arrayElementType(threadData, _ty)))) && (!omc_Types_isExternalObject(threadData, omc_Types_arrayElementType(threadData, _ty)))) && (!omc_Config_scalarizeBindings(threadData)))?_OMC_LIT43:_inMod);
_opt_binding = omc_InstBinding_makeVariableBinding(threadData, _ty, _mod, omc_NFInstUtil_toConst(threadData, _vt), _inPrefix, _inName);
_start = omc_InstBinding_instStartBindingExp(threadData, _inMod, _ty, _vt);
if((!omc_Flags_getConfigBool(threadData, _OMC_LIT49)))
{
_attr = omc_InstVar_stripVarAttrDirection(threadData, _cr, _ih, _inState, _inPrefix, _attr);
}
_dae1 = omc_InstUtil_propagateAttributes(threadData, _dae1, _attr, _inPrefixes, _inInfo);
_dae2 = omc_InstDAE_daeDeclare(threadData, _cache, _env, _env_1, _cr, _inState, _ty, _attr, _vis, _opt_binding, _inInstDims, _start, _dae_var_attr, _inComment, _io, _fin, _source, 0);
_store = omc_UnitAbsynBuilder_instAddStore(threadData, _store, _ty, _cr);
_dae = omc_InstVar_instScalar2(threadData, _cr, _ty, _vt, _inMod, _dae2, _dae1, _source, _inImpl);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env_1;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = _store;
tmpMeta[0+4] = _dae;
tmpMeta[0+5] = _csets;
tmpMeta[0+6] = _ty;
tmpMeta[0+7] = _graph;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
tmp14 = omc_Flags_isSet(threadData, _OMC_LIT29);
if (1 != tmp14) goto goto_2;
tmpMeta15 = stringAppend(_OMC_LIT50,_inName);
tmpMeta16 = stringAppend(tmpMeta15,_OMC_LIT51);
tmpMeta17 = stringAppend(tmpMeta16,omc_PrefixUtil_printPrefixStr(threadData, _inPrefix));
tmpMeta18 = stringAppend(tmpMeta17,_OMC_LIT52);
tmpMeta19 = stringAppend(tmpMeta18,omc_FGraph_printGraphPathStr(threadData, _inEnv));
tmpMeta20 = stringAppend(tmpMeta19,_OMC_LIT53);
omc_Debug_traceln(threadData, tmpMeta20);
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
_outEnv = tmpMeta[0+1];
_outIH = tmpMeta[0+2];
_outStore = tmpMeta[0+3];
_outDae = tmpMeta[0+4];
_outSets = tmpMeta[0+5];
_outType = tmpMeta[0+6];
_outGraph = tmpMeta[0+7];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outIH) { *out_outIH = _outIH; }
if (out_outStore) { *out_outStore = _outStore; }
if (out_outDae) { *out_outDae = _outDae; }
if (out_outSets) { *out_outSets = _outSets; }
if (out_outType) { *out_outType = _outType; }
if (out_outGraph) { *out_outGraph = _outGraph; }
return _outCache;
}
modelica_metatype boxptr_InstVar_instScalar(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inName, modelica_metatype _inClass, modelica_metatype _inAttributes, modelica_metatype _inPrefixes, modelica_metatype _inSubscripts, modelica_metatype _inInstDims, modelica_metatype _inImpl, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph)
{
modelica_integer tmp1;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inImpl);
_outCache = omc_InstVar_instScalar(threadData, _inCache, _inEnv, _inIH, _inStore, _inState, _inMod, _inPrefix, _inName, _inClass, _inAttributes, _inPrefixes, _inSubscripts, _inInstDims, tmp1, _inComment, _inInfo, _inGraph, _inSets, out_outEnv, out_outIH, out_outStore, out_outDae, out_outSets, out_outType, out_outGraph);
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_instVar2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_string _inName, modelica_metatype _inClass, modelica_metatype _inAttributes, modelica_metatype _inPrefixes, modelica_metatype _inDimensions, modelica_metatype _inSubscripts, modelica_metatype _inInstDims, modelica_boolean _inImpl, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outIH = NULL;
modelica_metatype _outStore = NULL;
modelica_metatype _outDae = NULL;
modelica_metatype _outSets = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;volatile modelica_metatype tmp4_5;volatile modelica_metatype tmp4_6;volatile modelica_metatype tmp4_7;volatile modelica_string tmp4_8;volatile modelica_metatype tmp4_9;volatile modelica_metatype tmp4_10;volatile modelica_metatype tmp4_11;volatile modelica_metatype tmp4_12;volatile modelica_metatype tmp4_13;volatile modelica_metatype tmp4_14;volatile modelica_boolean tmp4_15;volatile modelica_metatype tmp4_16;volatile modelica_metatype tmp4_17;volatile modelica_metatype tmp4_18;volatile modelica_metatype tmp4_19;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inIH;
tmp4_4 = _inStore;
tmp4_5 = _inState;
tmp4_6 = _inMod;
tmp4_7 = _inPrefix;
tmp4_8 = _inName;
tmp4_9 = _inClass;
tmp4_10 = _inAttributes;
tmp4_11 = _inPrefixes;
tmp4_12 = _inDimensions;
tmp4_13 = _inSubscripts;
tmp4_14 = _inInstDims;
tmp4_15 = _inImpl;
tmp4_16 = _inComment;
tmp4_17 = _inInfo;
tmp4_18 = _inGraph;
tmp4_19 = _inSets;
{
modelica_metatype _inst_dims = NULL;
modelica_metatype _inst_dims_1 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e_1 = NULL;
modelica_metatype _p = NULL;
modelica_metatype _env_1 = NULL;
modelica_metatype _env = NULL;
modelica_metatype _compenv = NULL;
modelica_metatype _csets = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _ty_1 = NULL;
modelica_metatype _arrty = NULL;
modelica_metatype _ci_state = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _ty_2 = NULL;
modelica_metatype _dae = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _pre = NULL;
modelica_string _n = NULL;
modelica_metatype _cl = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _dims = NULL;
modelica_metatype _idxs = NULL;
modelica_boolean _impl;
modelica_metatype _comment = NULL;
modelica_metatype _dae_var_attr = NULL;
modelica_metatype _dime = NULL;
modelica_metatype _dim = NULL;
modelica_metatype _dim2 = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _vis = NULL;
modelica_metatype _graph = NULL;
modelica_metatype _ih = NULL;
modelica_metatype _source = NULL;
modelica_metatype _dime2 = NULL;
modelica_metatype _pf = NULL;
modelica_metatype _fin = NULL;
modelica_metatype _info = NULL;
modelica_metatype _io = NULL;
modelica_metatype _store = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 10; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_boolean tmp8;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,0,5) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 5));
if (!optionNone(tmpMeta6)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_9,2,8) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_9), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,3,1) == 0) goto tmp3_end;
_mod = tmp4_6;
_cl = tmp4_9;
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_store = tmp4_4;
_ci_state = tmp4_5;
_pre = tmp4_7;
_n = tmp4_8;
_attr = tmp4_10;
_pf = tmp4_11;
_dims = tmp4_12;
_inst_dims = tmp4_14;
_impl = tmp4_15;
_comment = tmp4_16;
_info = tmp4_17;
_graph = tmp4_18;
_csets = tmp4_19;
tmp4 += 1;
tmp8 = omc_ClassInf_isFunction(threadData, _ci_state);
if (1 != tmp8) goto goto_2;
omc_InstUtil_checkFunctionVar(threadData, _n, _attr, _pf, _info);
_cache = omc_Inst_instClass(threadData, _cache, _env, _ih, _store, _OMC_LIT43, _pre, _cl, _inst_dims, _impl, _OMC_LIT3, _graph, _csets ,&_env_1 ,&_ih ,&_store ,NULL ,&_csets ,&_ty ,NULL ,NULL ,&_graph);
_ty_1 = omc_InstUtil_makeArrayType(threadData, _dims, _ty);
omc_InstUtil_checkFunctionVarType(threadData, _ty_1, _ci_state, _n, _info);
tmpMeta9 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_InstBinding_instDaeVariableAttributes(threadData, _cache, _env, _mod, _ty, tmpMeta9 ,&_dae_var_attr);
_ty_2 = omc_Types_simplifyType(threadData, _ty_1);
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_PrefixUtil_prefixCref(threadData, _cache, _env, _ih, _pre, omc_ComponentReference_makeCrefIdent(threadData, _n, _ty_2, tmpMeta10) ,&_cr);
tmpMeta13 = omc_InstBinding_makeBinding(threadData, _cache, _env, _attr, _mod, _ty_2, _pre, _n, _info, &tmpMeta11);
_cache = tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,1,4) == 0) goto goto_2;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
_e = tmpMeta12;
_source = omc_ElementSource_createElementSource(threadData, _info, omc_FGraph_getScopePath(threadData, _env), _pre, _OMC_LIT6);
tmpMeta14 = _pf;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 4));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 5));
_vis = tmpMeta15;
_fin = tmpMeta16;
_io = tmpMeta17;
tmpMeta18 = mmc_mk_cons(_dims, MMC_REFSTRUCTLIT(mmc_nil));
_dae = omc_InstDAE_daeDeclare(threadData, _cache, _env, _env_1, _cr, _ci_state, _ty, _attr, _vis, mmc_mk_some(_e), tmpMeta18, mmc_mk_none(), _dae_var_attr, mmc_mk_some(_comment), _io, _fin, _source, 1);
_store = omc_UnitAbsynBuilder_instAddStore(threadData, _store, _ty, _cr);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env_1;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = _store;
tmpMeta[0+4] = _dae;
tmpMeta[0+5] = _csets;
tmpMeta[0+6] = _ty_1;
tmpMeta[0+7] = _graph;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_boolean tmp21;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,0,5) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 5));
if (optionNone(tmpMeta19)) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 1));
_mod = tmp4_6;
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_store = tmp4_4;
_ci_state = tmp4_5;
_pre = tmp4_7;
_n = tmp4_8;
_cl = tmp4_9;
_attr = tmp4_10;
_pf = tmp4_11;
_dims = tmp4_12;
_inst_dims = tmp4_14;
_impl = tmp4_15;
_comment = tmp4_16;
_info = tmp4_17;
_graph = tmp4_18;
_csets = tmp4_19;
tmp21 = omc_ClassInf_isFunction(threadData, _ci_state);
if (1 != tmp21) goto goto_2;
omc_InstUtil_checkFunctionVar(threadData, _n, _attr, _pf, _info);
tmpMeta22 = omc_Mod_modEquation(threadData, _mod);
if (optionNone(tmpMeta22)) goto goto_2;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta23,0,5) == 0) goto goto_2;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 2));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 4));
_e = tmpMeta24;
_p = tmpMeta25;
_cache = omc_Inst_instClass(threadData, _cache, _env, _ih, _store, _OMC_LIT43, _pre, _cl, _inst_dims, _impl, _OMC_LIT3, _graph, _csets ,&_env_1 ,&_ih ,&_store ,NULL ,&_csets ,&_ty ,NULL ,NULL ,&_graph);
_ty_1 = omc_InstUtil_makeArrayType(threadData, _dims, _ty);
omc_InstUtil_checkFunctionVarType(threadData, _ty_1, _ci_state, _n, _info);
tmpMeta26 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_InstBinding_instDaeVariableAttributes(threadData, _cache, _env, _mod, _ty, tmpMeta26 ,&_dae_var_attr);
tmpMeta27 = mmc_mk_box3(3, &DAE_Properties_PROP__desc, _ty_1, _OMC_LIT4);
_e_1 = omc_Types_matchProp(threadData, _e, _p, tmpMeta27, 1, NULL);
_ty_2 = omc_Types_simplifyType(threadData, _ty_1);
tmpMeta28 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_PrefixUtil_prefixCref(threadData, _cache, _env, _ih, _pre, omc_ComponentReference_makeCrefIdent(threadData, _n, _ty_2, tmpMeta28) ,&_cr);
_source = omc_ElementSource_createElementSource(threadData, _info, omc_FGraph_getScopePath(threadData, _env), _pre, _OMC_LIT6);
tmpMeta29 = _pf;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta29), 2));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta29), 4));
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta29), 5));
_vis = tmpMeta30;
_fin = tmpMeta31;
_io = tmpMeta32;
tmpMeta33 = mmc_mk_cons(_dims, MMC_REFSTRUCTLIT(mmc_nil));
_dae = omc_InstDAE_daeDeclare(threadData, _cache, _env, _env_1, _cr, _ci_state, _ty, _attr, _vis, mmc_mk_some(_e_1), tmpMeta33, mmc_mk_none(), _dae_var_attr, mmc_mk_some(_comment), _io, _fin, _source, 1);
_store = omc_UnitAbsynBuilder_instAddStore(threadData, _store, _ty, _cr);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env_1;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = _store;
tmpMeta[0+4] = _dae;
tmpMeta[0+5] = _csets;
tmpMeta[0+6] = _ty_1;
tmpMeta[0+7] = _graph;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_9,2,8) == 0) goto tmp3_end;
_cl = tmp4_9;
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_store = tmp4_4;
_ci_state = tmp4_5;
_mod = tmp4_6;
_pre = tmp4_7;
_n = tmp4_8;
_attr = tmp4_10;
_pf = tmp4_11;
_dims = tmp4_12;
_inst_dims = tmp4_14;
_impl = tmp4_15;
_comment = tmp4_16;
_info = tmp4_17;
_graph = tmp4_18;
_csets = tmp4_19;
tmp34 = omc_ClassInf_isFunction(threadData, _ci_state);
if (1 != tmp34) goto goto_2;
omc_InstUtil_checkFunctionVar(threadData, _n, _attr, _pf, _info);
_cache = omc_Inst_instClass(threadData, _cache, _env, _ih, _store, _mod, _pre, _cl, _inst_dims, _impl, _OMC_LIT3, _OMC_LIT54, _csets ,&_env_1 ,&_ih ,&_store ,NULL ,&_csets ,&_ty ,NULL ,NULL ,NULL);
_arrty = omc_InstUtil_makeArrayType(threadData, _dims, _ty);
omc_InstUtil_checkFunctionVarType(threadData, _arrty, _ci_state, _n, _info);
tmpMeta35 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_PrefixUtil_prefixCref(threadData, _cache, _env, _ih, _pre, omc_ComponentReference_makeCrefIdent(threadData, _n, _arrty, tmpMeta35) ,&_cr);
tmpMeta36 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_InstBinding_instDaeVariableAttributes(threadData, _cache, _env, _mod, _ty, tmpMeta36 ,&_dae_var_attr);
_source = omc_ElementSource_createElementSource(threadData, _info, omc_FGraph_getScopePath(threadData, _env), _pre, _OMC_LIT6);
tmpMeta37 = _pf;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 2));
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 4));
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 5));
_vis = tmpMeta38;
_fin = tmpMeta39;
_io = tmpMeta40;
tmpMeta41 = mmc_mk_cons(_dims, MMC_REFSTRUCTLIT(mmc_nil));
_dae = omc_InstDAE_daeDeclare(threadData, _cache, _env, _env_1, _cr, _ci_state, _ty, _attr, _vis, mmc_mk_none(), tmpMeta41, mmc_mk_none(), _dae_var_attr, mmc_mk_some(_comment), _io, _fin, _source, 1);
_store = omc_UnitAbsynBuilder_instAddStore(threadData, _store, _ty, _cr);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env_1;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = _store;
tmpMeta[0+4] = _dae;
tmpMeta[0+5] = _csets;
tmpMeta[0+6] = _arrty;
tmpMeta[0+7] = _graph;
goto tmp3_done;
}
case 3: {
modelica_boolean tmp42;
if (!listEmpty(tmp4_12)) goto tmp3_end;
tmp4 += 5;
tmp42 = omc_ClassInf_isFunction(threadData, _inState);
if (0 != tmp42) goto goto_2;
tmpMeta[0+0] = omc_InstVar_instScalar(threadData, _inCache, _inEnv, _inIH, _inStore, _inState, _inMod, _inPrefix, _inName, _inClass, _inAttributes, _inPrefixes, _inSubscripts, _inInstDims, _inImpl, mmc_mk_some(_inComment), _inInfo, _inGraph, _inSets, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3], &tmpMeta[0+4], &tmpMeta[0+5], &tmpMeta[0+6], &tmpMeta[0+7]);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_boolean tmp47;
modelica_boolean tmp48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
if (listEmpty(tmp4_12)) goto tmp3_end;
tmpMeta43 = MMC_CAR(tmp4_12);
tmpMeta44 = MMC_CDR(tmp4_12);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta43,4,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,0,5) == 0) goto tmp3_end;
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 5));
if (optionNone(tmpMeta45)) goto tmp3_end;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta46,0,5) == 0) goto tmp3_end;
_dim = tmpMeta43;
_dims = tmpMeta44;
_mod = tmp4_6;
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_store = tmp4_4;
_ci_state = tmp4_5;
_pre = tmp4_7;
_n = tmp4_8;
_cl = tmp4_9;
_attr = tmp4_10;
_pf = tmp4_11;
_idxs = tmp4_13;
_inst_dims = tmp4_14;
_impl = tmp4_15;
_comment = tmp4_16;
_info = tmp4_17;
_graph = tmp4_18;
_csets = tmp4_19;
tmp47 = omc_Config_splitArrays(threadData);
if (1 != tmp47) goto goto_2;
tmp48 = omc_ClassInf_isFunction(threadData, _ci_state);
if (0 != tmp48) goto goto_2;
_dim2 = omc_InstUtil_instWholeDimFromMod(threadData, _dim, _mod, _n, _info);
tmpMeta49 = mmc_mk_cons(_dim2, MMC_REFSTRUCTLIT(mmc_nil));
_inst_dims_1 = omc_List_appendLastList(threadData, _inst_dims, tmpMeta49);
tmpMeta50 = mmc_mk_box2(0, _cl, _attr);
_cache = omc_InstVar_instArray(threadData, _cache, _env, _ih, _store, _ci_state, _mod, _pre, _n, tmpMeta50, _pf, ((modelica_integer) 1), _dim2, _dims, _idxs, _inst_dims_1, _impl, _comment, _info, _graph, _csets ,&_compenv ,&_ih ,&_store ,&_dae ,&_csets ,&_ty ,&_graph);
_ty_1 = omc_InstUtil_liftNonBasicTypes(threadData, _ty, _dim2);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _compenv;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = _store;
tmpMeta[0+4] = _dae;
tmpMeta[0+5] = _csets;
tmpMeta[0+6] = _ty_1;
tmpMeta[0+7] = _graph;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_boolean tmp55;
modelica_boolean tmp56;
modelica_metatype tmpMeta57;
modelica_metatype tmpMeta58;
if (listEmpty(tmp4_12)) goto tmp3_end;
tmpMeta51 = MMC_CAR(tmp4_12);
tmpMeta52 = MMC_CDR(tmp4_12);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta51,4,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,0,5) == 0) goto tmp3_end;
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_6), 5));
if (optionNone(tmpMeta53)) goto tmp3_end;
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta53), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta54,0,5) == 0) goto tmp3_end;
_dim = tmpMeta51;
_dims = tmpMeta52;
_mod = tmp4_6;
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_store = tmp4_4;
_ci_state = tmp4_5;
_pre = tmp4_7;
_n = tmp4_8;
_cl = tmp4_9;
_attr = tmp4_10;
_pf = tmp4_11;
_idxs = tmp4_13;
_inst_dims = tmp4_14;
_impl = tmp4_15;
_comment = tmp4_16;
_info = tmp4_17;
_graph = tmp4_18;
_csets = tmp4_19;
tmp55 = omc_Config_splitArrays(threadData);
if (0 != tmp55) goto goto_2;
tmp56 = omc_ClassInf_isFunction(threadData, _ci_state);
if (0 != tmp56) goto goto_2;
_dim2 = omc_InstUtil_instWholeDimFromMod(threadData, _dim, _mod, _n, _info);
tmpMeta57 = mmc_mk_cons(_dim2, MMC_REFSTRUCTLIT(mmc_nil));
_inst_dims_1 = omc_List_appendLastList(threadData, _inst_dims, tmpMeta57);
_dime2 = omc_Expression_dimensionSubscript(threadData, _dim2);
tmpMeta58 = mmc_mk_cons(_dime2, _idxs);
_cache = omc_InstVar_instVar2(threadData, _cache, _env, _ih, _store, _ci_state, _mod, _pre, _n, _cl, _attr, _pf, _dims, tmpMeta58, _inst_dims_1, _impl, _comment, _info, _graph, _csets ,&_compenv ,&_ih ,&_store ,&_dae ,&_csets ,&_ty ,&_graph);
_ty_1 = omc_InstUtil_liftNonBasicTypes(threadData, _ty, _dim2);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _compenv;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = _store;
tmpMeta[0+4] = _dae;
tmpMeta[0+5] = _csets;
tmpMeta[0+6] = _ty_1;
tmpMeta[0+7] = _graph;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta59;
modelica_metatype tmpMeta60;
modelica_boolean tmp61;
modelica_boolean tmp62;
modelica_metatype tmpMeta63;
modelica_metatype tmpMeta64;
if (listEmpty(tmp4_12)) goto tmp3_end;
tmpMeta59 = MMC_CAR(tmp4_12);
tmpMeta60 = MMC_CDR(tmp4_12);
_dim = tmpMeta59;
_dims = tmpMeta60;
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_store = tmp4_4;
_ci_state = tmp4_5;
_mod = tmp4_6;
_pre = tmp4_7;
_n = tmp4_8;
_cl = tmp4_9;
_attr = tmp4_10;
_pf = tmp4_11;
_idxs = tmp4_13;
_inst_dims = tmp4_14;
_impl = tmp4_15;
_comment = tmp4_16;
_info = tmp4_17;
_graph = tmp4_18;
_csets = tmp4_19;
tmp61 = omc_Config_splitArrays(threadData);
if (1 != tmp61) goto goto_2;
tmp62 = omc_ClassInf_isFunction(threadData, _ci_state);
if (0 != tmp62) goto goto_2;
tmpMeta63 = mmc_mk_cons(_dim, MMC_REFSTRUCTLIT(mmc_nil));
_inst_dims_1 = omc_List_appendLastList(threadData, _inst_dims, tmpMeta63);
tmpMeta64 = mmc_mk_box2(0, _cl, _attr);
_cache = omc_InstVar_instArray(threadData, _cache, _env, _ih, _store, _ci_state, _mod, _pre, _n, tmpMeta64, _pf, ((modelica_integer) 1), _dim, _dims, _idxs, _inst_dims_1, _impl, _comment, _info, _graph, _csets ,&_compenv ,&_ih ,&_store ,&_dae ,&_csets ,&_ty ,&_graph);
_ty_1 = omc_InstUtil_liftNonBasicTypes(threadData, _ty, _dim);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _compenv;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = _store;
tmpMeta[0+4] = _dae;
tmpMeta[0+5] = _csets;
tmpMeta[0+6] = _ty_1;
tmpMeta[0+7] = _graph;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
modelica_boolean tmp67;
modelica_boolean tmp68;
modelica_metatype tmpMeta69;
modelica_metatype tmpMeta70;
if (listEmpty(tmp4_12)) goto tmp3_end;
tmpMeta65 = MMC_CAR(tmp4_12);
tmpMeta66 = MMC_CDR(tmp4_12);
_dim = tmpMeta65;
_dims = tmpMeta66;
_cache = tmp4_1;
_env = tmp4_2;
_ih = tmp4_3;
_store = tmp4_4;
_ci_state = tmp4_5;
_mod = tmp4_6;
_pre = tmp4_7;
_n = tmp4_8;
_cl = tmp4_9;
_attr = tmp4_10;
_pf = tmp4_11;
_idxs = tmp4_13;
_inst_dims = tmp4_14;
_impl = tmp4_15;
_comment = tmp4_16;
_info = tmp4_17;
_graph = tmp4_18;
_csets = tmp4_19;
tmp67 = omc_Config_splitArrays(threadData);
if (0 != tmp67) goto goto_2;
tmp68 = omc_ClassInf_isFunction(threadData, _ci_state);
if (0 != tmp68) goto goto_2;
tmpMeta69 = mmc_mk_cons(_dim, MMC_REFSTRUCTLIT(mmc_nil));
_inst_dims_1 = omc_List_appendLastList(threadData, _inst_dims, tmpMeta69);
_dime = omc_Expression_dimensionSubscript(threadData, _dim);
tmpMeta70 = mmc_mk_cons(_dime, _idxs);
tmpMeta[0+0] = omc_InstVar_instVar2(threadData, _cache, _env, _ih, _store, _ci_state, _mod, _pre, _n, _cl, _attr, _pf, _dims, tmpMeta70, _inst_dims_1, _impl, _comment, _info, _graph, _csets, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3], &tmpMeta[0+4], &tmpMeta[0+5], &tmpMeta[0+6], &tmpMeta[0+7]);
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta71;
modelica_metatype tmpMeta72;
modelica_metatype tmpMeta73;
modelica_string tmp74;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,2,0) == 0) goto tmp3_end;
if (listEmpty(tmp4_12)) goto tmp3_end;
tmpMeta71 = MMC_CAR(tmp4_12);
tmpMeta72 = MMC_CDR(tmp4_12);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta71,4,0) == 0) goto tmp3_end;
_n = tmp4_8;
_info = tmp4_17;
tmp74 = modelica_integer_to_modelica_string(((modelica_integer) 1) + listLength(_inSubscripts), ((modelica_integer) 0), 1);
tmpMeta73 = mmc_mk_cons(tmp74, mmc_mk_cons(_n, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT57, tmpMeta73, _info);
goto goto_2;
goto tmp3_done;
}
case 9: {
modelica_boolean tmp75;
modelica_metatype tmpMeta76;
modelica_metatype tmpMeta77;
modelica_metatype tmpMeta78;
modelica_metatype tmpMeta79;
modelica_metatype tmpMeta80;
modelica_metatype tmpMeta81;
modelica_metatype tmpMeta82;
_env = tmp4_2;
_mod = tmp4_6;
_pre = tmp4_7;
_n = tmp4_8;
tmp75 = omc_Flags_isSet(threadData, _OMC_LIT29);
if (1 != tmp75) goto goto_2;
tmpMeta76 = stringAppend(_OMC_LIT58,omc_PrefixUtil_printPrefixStr(threadData, _pre));
tmpMeta77 = stringAppend(tmpMeta76,_OMC_LIT34);
tmpMeta78 = stringAppend(tmpMeta77,_n);
tmpMeta79 = stringAppend(tmpMeta78,_OMC_LIT18);
tmpMeta80 = stringAppend(tmpMeta79,omc_Mod_prettyPrintMod(threadData, _mod, ((modelica_integer) 0)));
tmpMeta81 = stringAppend(tmpMeta80,_OMC_LIT59);
tmpMeta82 = stringAppend(tmpMeta81,omc_FGraph_printGraphPathStr(threadData, _env));
omc_Debug_traceln(threadData, tmpMeta82);
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
if (++tmp4 < 10) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outCache = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_outIH = tmpMeta[0+2];
_outStore = tmpMeta[0+3];
_outDae = tmpMeta[0+4];
_outSets = tmpMeta[0+5];
_outType = tmpMeta[0+6];
_outGraph = tmpMeta[0+7];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outIH) { *out_outIH = _outIH; }
if (out_outStore) { *out_outStore = _outStore; }
if (out_outDae) { *out_outDae = _outDae; }
if (out_outSets) { *out_outSets = _outSets; }
if (out_outType) { *out_outType = _outType; }
if (out_outGraph) { *out_outGraph = _outGraph; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstVar_instVar2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inName, modelica_metatype _inClass, modelica_metatype _inAttributes, modelica_metatype _inPrefixes, modelica_metatype _inDimensions, modelica_metatype _inSubscripts, modelica_metatype _inInstDims, modelica_metatype _inImpl, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph)
{
modelica_integer tmp1;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inImpl);
_outCache = omc_InstVar_instVar2(threadData, _inCache, _inEnv, _inIH, _inStore, _inState, _inMod, _inPrefix, _inName, _inClass, _inAttributes, _inPrefixes, _inDimensions, _inSubscripts, _inInstDims, tmp1, _inComment, _inInfo, _inGraph, _inSets, out_outEnv, out_outIH, out_outStore, out_outDae, out_outSets, out_outType, out_outGraph);
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_addArrayVarEquation(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inState, modelica_metatype _inDae, modelica_metatype _inType, modelica_metatype _mod, modelica_metatype _const, modelica_metatype _pre, modelica_string _n, modelica_metatype _source, modelica_metatype *out_outDae)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outDae = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inDae;
tmp4_2 = _const;
{
modelica_metatype _cache = NULL;
modelica_metatype _dae = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _eq = NULL;
modelica_metatype _dims = NULL;
modelica_metatype _cr = NULL;
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
tmp6 = omc_Config_scalarizeBindings(threadData);
if (1 != tmp6) goto goto_2;
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inDae;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_boolean tmp8;
modelica_boolean tmp9;
modelica_boolean tmp10;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,0) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_dae = tmpMeta7;
tmp8 = omc_ClassInf_isFunctionOrRecord(threadData, _inState);
if (0 != tmp8) goto goto_2;
_ty = omc_Types_simplifyType(threadData, _inType);
tmp9 = omc_Types_isExternalObject(threadData, omc_Types_arrayElementType(threadData, _ty));
if (0 != tmp9) goto goto_2;
tmp10 = omc_Types_isComplexType(threadData, omc_Types_arrayElementType(threadData, _ty));
if (0 != tmp10) goto goto_2;
tmpMeta11 = omc_Types_getDimensions(threadData, _ty);
if (listEmpty(tmpMeta11)) goto goto_2;
tmpMeta12 = MMC_CAR(tmpMeta11);
tmpMeta13 = MMC_CDR(tmpMeta11);
_dims = tmpMeta11;
tmpMeta14 = omc_InstBinding_makeVariableBinding(threadData, _ty, _mod, _const, _pre, _n);
if (optionNone(tmpMeta14)) goto goto_2;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 1));
_exp = tmpMeta15;
tmpMeta16 = MMC_REFSTRUCTLIT(mmc_nil);
_cr = omc_ComponentReference_makeCrefIdent(threadData, _n, _ty, tmpMeta16);
_cache = omc_PrefixUtil_prefixCref(threadData, _inCache, _inEnv, _inIH, _pre, _cr ,&_cr);
tmpMeta17 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _cr, _ty);
tmpMeta18 = mmc_mk_box5(8, &DAE_Element_ARRAY__EQUATION__desc, _dims, tmpMeta17, _exp, _source);
_eq = tmpMeta18;
tmpMeta19 = mmc_mk_cons(_eq, _dae);
tmpMeta20 = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta19);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta20;
goto tmp3_done;
}
case 2: {
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inDae;
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
_outDae = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outDae) { *out_outDae = _outDae; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_liftUserTypeEqMod(threadData_t *threadData, modelica_metatype _inEqMod, modelica_metatype _inDims)
{
modelica_metatype _outEqMod = NULL;
modelica_metatype _eq = NULL;
modelica_metatype _ty = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(isNone(_inEqMod))
{
_outEqMod = _inEqMod;
goto _return;
}
tmpMeta1 = _inEqMod;
if (optionNone(tmpMeta1)) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
_eq = tmpMeta2;
{
modelica_metatype tmp6_1;
tmp6_1 = _eq;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,5) == 0) goto tmp5_end;
tmpMeta8 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta8), MMC_UNTAGPTR(_eq), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta8))[2] = omc_Expression_liftExpList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 2))), _inDims);
_eq = tmpMeta8;
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_eq), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[3] = omc_Util_applyOption1(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 3))), boxvar_ValuesUtil_liftValueList, _inDims);
_eq = tmpMeta9;
_ty = omc_Types_getPropType(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 4))));
tmpMeta10 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta10), MMC_UNTAGPTR(_eq), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta10))[4] = omc_Types_setPropType(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 4))), omc_Types_liftArrayListDims(threadData, _ty, _inDims));
_eq = tmpMeta10;
tmpMeta3 = _eq;
goto tmp5_done;
}
case 1: {
tmpMeta3 = _eq;
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
_eq = tmpMeta3;
_outEqMod = mmc_mk_some(_eq);
_return: OMC_LABEL_UNUSED
return _outEqMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_liftUserTypeSubMod(threadData_t *threadData, modelica_metatype _inSubMod, modelica_metatype _inDims)
{
modelica_metatype _outSubMod = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outSubMod = _inSubMod;
{
modelica_metatype tmp4_1;
tmp4_1 = _outSubMod;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_outSubMod), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[3] = omc_InstVar_liftUserTypeMod(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outSubMod), 3))), _inDims);
_outSubMod = tmpMeta6;
tmpMeta1 = _outSubMod;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outSubMod = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outSubMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_liftUserTypeMod(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _inDims)
{
jmp_buf *old_mmc_jumper = threadData->mmc_jumper;
modelica_metatype _outMod = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outMod = _inMod;
if(listEmpty(_inDims))
{
goto _return;
}
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _outMod;
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
if((!omc_SCodeUtil_eachBool(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outMod), 3))))))
{
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_outMod), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[5] = omc_InstVar_liftUserTypeEqMod(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outMod), 5))), _inDims);
_outMod = tmpMeta6;
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp9;
modelica_metatype tmpMeta10;
modelica_metatype __omcQ_24tmpVar0;
modelica_integer tmp11;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outMod), 4)));
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta10;
tmp9 = &__omcQ_24tmpVar1;
while(1) {
tmp11 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp11--;
}
if (tmp11 == 0) {
__omcQ_24tmpVar0 = omc_InstVar_liftUserTypeSubMod(threadData, _s, _inDims);
*tmp9 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp9 = &MMC_CDR(*tmp9);
} else if (tmp11 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp9 = mmc_mk_nil();
tmpMeta8 = __omcQ_24tmpVar1;
}
tmpMeta7 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta7), MMC_UNTAGPTR(_outMod), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta7))[4] = tmpMeta8;
_outMod = tmpMeta7;
}
tmpMeta1 = _outMod;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _outMod;
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
_outMod = tmpMeta1;
_return: OMC_LABEL_UNUSED
threadData->mmc_jumper = old_mmc_jumper;
return _outMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstVar_instVar__dispatch(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_string _inName, modelica_metatype _inClass, modelica_metatype _inAttributes, modelica_metatype _inPrefixes, modelica_metatype _inDimensions, modelica_metatype _inIndices, modelica_metatype _inInstDims, modelica_boolean _inImpl, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outIH = NULL;
modelica_metatype _outStore = NULL;
modelica_metatype _outDae = NULL;
modelica_metatype _outSets = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _outGraph = NULL;
modelica_string _comp_name = NULL;
modelica_metatype _dims = NULL;
modelica_metatype _cls = NULL;
modelica_metatype _type_mods = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _source = NULL;
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
omc_Error_updateCurrentComponent(threadData, _inPrefix, _inName, _inInfo, boxvar_PrefixUtil_identAndPrefixToPath);
_outCache = omc_InstUtil_getUsertypeDimensions(threadData, _inCache, _inEnv, _inIH, _inPrefix, _inClass, _inInstDims, _inImpl ,&_dims ,&_cls ,&_type_mods);
if(listEmpty(_dims))
{
_dims = _inDimensions;
_cls = _inClass;
_mod = _inMod;
_attr = _inAttributes;
}
else
{
_type_mods = omc_InstVar_liftUserTypeMod(threadData, _type_mods, _inDimensions);
_dims = listAppend(_inDimensions, _dims);
_mod = omc_Mod_merge(threadData, _inMod, _type_mods, _OMC_LIT2, 1);
_attr = omc_InstUtil_propagateClassPrefix(threadData, _inAttributes, _inPrefix);
}
_outCache = omc_InstVar_instVar2(threadData, _outCache, _inEnv, _inIH, _inStore, _inState, _mod, _inPrefix, _inName, _cls, _attr, _inPrefixes, _dims, _inIndices, _inInstDims, _inImpl, _inComment, _inInfo, _inGraph, _inSets ,&_outEnv ,&_outIH ,&_outStore ,&_outDae ,&_outSets ,&_outType ,&_outGraph);
_source = omc_ElementSource_createElementSource(threadData, _inInfo, omc_FGraph_getScopePath(threadData, _inEnv), _inPrefix, _OMC_LIT6);
_outCache = omc_InstVar_addArrayVarEquation(threadData, _outCache, _inEnv, _outIH, _inState, _outDae, _outType, _mod, omc_NFInstUtil_toConst(threadData, omc_SCodeUtil_attrVariability(threadData, _attr)), _inPrefix, _inName, _source ,&_outDae);
_outCache = omc_InstFunction_addRecordConstructorFunction(threadData, _outCache, _inEnv, omc_Types_arrayElementType(threadData, _outType), omc_SCodeUtil_elementInfo(threadData, _inClass));
omc_Error_clearCurrentComponent(threadData);
goto tmp2_done;
}
case 1: {
omc_Error_clearCurrentComponent(threadData);
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
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outIH) { *out_outIH = _outIH; }
if (out_outStore) { *out_outStore = _outStore; }
if (out_outDae) { *out_outDae = _outDae; }
if (out_outSets) { *out_outSets = _outSets; }
if (out_outType) { *out_outType = _outType; }
if (out_outGraph) { *out_outGraph = _outGraph; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstVar_instVar__dispatch(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inName, modelica_metatype _inClass, modelica_metatype _inAttributes, modelica_metatype _inPrefixes, modelica_metatype _inDimensions, modelica_metatype _inIndices, modelica_metatype _inInstDims, modelica_metatype _inImpl, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph)
{
modelica_integer tmp1;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inImpl);
_outCache = omc_InstVar_instVar__dispatch(threadData, _inCache, _inEnv, _inIH, _inStore, _inState, _inMod, _inPrefix, _inName, _inClass, _inAttributes, _inPrefixes, _inDimensions, _inIndices, _inInstDims, tmp1, _inComment, _inInfo, _inGraph, _inSets, out_outEnv, out_outIH, out_outStore, out_outDae, out_outSets, out_outType, out_outGraph);
return _outCache;
}
DLLExport
modelica_metatype omc_InstVar_instVar(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_string _inIdent, modelica_metatype _inClass, modelica_metatype _inAttributes, modelica_metatype _inPrefixes, modelica_metatype _inDimensionLst, modelica_metatype _inIntegerLst, modelica_metatype _inInstDims, modelica_boolean _inImpl, modelica_metatype _inComment, modelica_metatype _info, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype _componentDefinitionParentEnv, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outIH = NULL;
modelica_metatype _outStore = NULL;
modelica_metatype _outDae = NULL;
modelica_metatype _outSets = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _outGraph = NULL;
modelica_metatype _io = NULL;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_string tmp4_1;
tmp4_1 = _inIdent;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (7 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT63), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (4 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT64), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
if (7 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT65), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
if (6 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT66), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 4: {
if (4 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT67), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
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
if(tmp1)
{
tmpMeta6 = mmc_mk_cons(_inIdent, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT62, tmpMeta6, _info);
MMC_THROW_INTERNAL();
}
_io = omc_SCodeUtil_prefixesInnerOuter(threadData, _inPrefixes);
{
volatile modelica_metatype tmp10_1;volatile modelica_metatype tmp10_2;volatile modelica_metatype tmp10_3;volatile modelica_metatype tmp10_4;volatile modelica_metatype tmp10_5;volatile modelica_metatype tmp10_6;volatile modelica_metatype tmp10_7;volatile modelica_string tmp10_8;volatile modelica_metatype tmp10_9;volatile modelica_metatype tmp10_10;volatile modelica_metatype tmp10_11;volatile modelica_metatype tmp10_12;volatile modelica_metatype tmp10_13;volatile modelica_metatype tmp10_14;volatile modelica_boolean tmp10_15;volatile modelica_metatype tmp10_16;volatile modelica_metatype tmp10_17;volatile modelica_metatype tmp10_18;
tmp10_1 = _inCache;
tmp10_2 = _inEnv;
tmp10_3 = _inIH;
tmp10_4 = _inStore;
tmp10_5 = _inState;
tmp10_6 = _inMod;
tmp10_7 = _inPrefix;
tmp10_8 = _inIdent;
tmp10_9 = _inClass;
tmp10_10 = _inAttributes;
tmp10_11 = _inPrefixes;
tmp10_12 = _inDimensionLst;
tmp10_13 = _inIntegerLst;
tmp10_14 = _inInstDims;
tmp10_15 = _inImpl;
tmp10_16 = _inComment;
tmp10_17 = _inGraph;
tmp10_18 = _inSets;
{
modelica_metatype _dims = NULL;
modelica_metatype _compenv = NULL;
modelica_metatype _env = NULL;
modelica_metatype _innerCompEnv = NULL;
modelica_metatype _outerCompEnv = NULL;
modelica_metatype _dae = NULL;
modelica_metatype _outerDAE = NULL;
modelica_metatype _innerDAE = NULL;
modelica_metatype _csets = NULL;
modelica_metatype _csetsInner = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _ci_state = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _pre = NULL;
modelica_metatype _innerPrefix = NULL;
modelica_string _n = NULL;
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
modelica_string _s3 = NULL;
modelica_string _s = NULL;
modelica_metatype _cl = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _idxs = NULL;
modelica_metatype _inst_dims = NULL;
modelica_boolean _impl;
modelica_metatype _comment = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _graph = NULL;
modelica_metatype _ih = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _crefOuter = NULL;
modelica_metatype _crefInner = NULL;
modelica_metatype _outers = NULL;
modelica_string _nInner = NULL;
modelica_string _typeName = NULL;
modelica_string _fullName = NULL;
modelica_metatype _typePath = NULL;
modelica_string _innerScope = NULL;
modelica_metatype _ioInner = NULL;
modelica_metatype _instResult = NULL;
modelica_metatype _pf = NULL;
modelica_metatype _store = NULL;
modelica_metatype _topInstance = NULL;
modelica_metatype _sm = NULL;
volatile mmc_switch_type tmp10;
int tmp11;
tmp10 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp9_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp10 < 10; tmp10++) {
switch (MMC_SWITCH_CAST(tmp10)) {
case 0: {
modelica_metatype tmpMeta12;
modelica_boolean tmp13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp10_9,2,8) == 0) goto tmp9_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp10_9), 2));
_cl = tmp10_9;
_typeName = tmpMeta12;
_cache = tmp10_1;
_env = tmp10_2;
_ih = tmp10_3;
_store = tmp10_4;
_ci_state = tmp10_5;
_mod = tmp10_6;
_pre = tmp10_7;
_n = tmp10_8;
_attr = tmp10_10;
_pf = tmp10_11;
_dims = tmp10_12;
_idxs = tmp10_13;
_inst_dims = tmp10_14;
_impl = tmp10_15;
_comment = tmp10_16;
_graph = tmp10_17;
_csets = tmp10_18;
tmp13 = omc_AbsynUtil_isOnlyInner(threadData, _io);
if (1 != tmp13) goto goto_8;
_cache = omc_InstVar_instVar__dispatch(threadData, _cache, _env, _ih, _store, _ci_state, _mod, _pre, _n, _cl, _attr, _pf, _dims, _idxs, _inst_dims, _impl, _comment, _info, _graph, _csets ,&_innerCompEnv ,&_ih ,&_store ,&_dae ,&_csets ,&_ty ,&_graph);
tmpMeta14 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_PrefixUtil_prefixCref(threadData, _cache, _env, _ih, _pre, omc_ComponentReference_makeCrefIdent(threadData, _n, _OMC_LIT1, tmpMeta14) ,&_cref);
_fullName = omc_ComponentReference_printComponentRefStr(threadData, _cref);
_cache = omc_Inst_makeFullyQualifiedIdent(threadData, _cache, _env, _typeName, _OMC_LIT68 ,&_typePath);
_outerCompEnv = omc_InnerOuter_switchInnerToOuterInGraph(threadData, _innerCompEnv, _cref);
_outerDAE = _OMC_LIT0;
_innerScope = omc_FGraph_printGraphPathStr(threadData, _componentDefinitionParentEnv);
tmpMeta15 = mmc_mk_box8(3, &InnerOuter_InstResult_INST__RESULT__desc, _cache, _outerCompEnv, _store, _outerDAE, _csets, _ty, _graph);
tmpMeta16 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta17 = mmc_mk_box10(3, &InnerOuter_InstInner_INST__INNER__desc, _pre, _n, _io, _fullName, _typePath, _innerScope, mmc_mk_some(tmpMeta15), tmpMeta16, mmc_mk_none());
_ih = omc_InnerOuter_updateInstHierarchy(threadData, _ih, _pre, _io, tmpMeta17);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _innerCompEnv;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = _store;
tmpMeta[0+4] = _dae;
tmpMeta[0+5] = _csets;
tmpMeta[0+6] = _ty;
tmpMeta[0+7] = _graph;
goto tmp9_done;
}
case 1: {
modelica_boolean tmp18;
modelica_boolean tmp19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
_cache = tmp10_1;
_env = tmp10_2;
_ih = tmp10_3;
_store = tmp10_4;
_ci_state = tmp10_5;
_mod = tmp10_6;
_pre = tmp10_7;
_n = tmp10_8;
_cl = tmp10_9;
_attr = tmp10_10;
_pf = tmp10_11;
_dims = tmp10_12;
_idxs = tmp10_13;
_inst_dims = tmp10_14;
_impl = tmp10_15;
_comment = tmp10_16;
_graph = tmp10_17;
_csets = tmp10_18;
tmp18 = omc_AbsynUtil_isOnlyOuter(threadData, _io);
if (1 != tmp18) goto goto_8;
tmp19 = omc_Mod_modEqual(threadData, _mod, _OMC_LIT43);
if (0 != tmp19) goto goto_8;
tmpMeta20 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_PrefixUtil_prefixCref(threadData, _cache, _env, _ih, _pre, omc_ComponentReference_makeCrefIdent(threadData, _n, _OMC_LIT1, tmpMeta20) ,&_cref);
_s1 = omc_ComponentReference_printComponentRefStr(threadData, _cref);
_s2 = omc_Mod_prettyPrintMod(threadData, _mod, ((modelica_integer) 0));
tmpMeta21 = stringAppend(_s1,_OMC_LIT69);
tmpMeta22 = stringAppend(tmpMeta21,_s2);
_s = tmpMeta22;
tmpMeta23 = mmc_mk_cons(_s, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT73, tmpMeta23, _info);
tmpMeta[0+0] = omc_InstVar_instVar(threadData, _cache, _env, _ih, _store, _ci_state, _OMC_LIT43, _pre, _n, _cl, _attr, _pf, _dims, _idxs, _inst_dims, _impl, _comment, _info, _graph, _csets, _componentDefinitionParentEnv, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3], &tmpMeta[0+4], &tmpMeta[0+5], &tmpMeta[0+6], &tmpMeta[0+7]);
goto tmp9_done;
}
case 2: {
modelica_metatype tmpMeta24;
modelica_boolean tmp25;
modelica_boolean tmp26;
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
modelica_boolean tmp37;
modelica_boolean tmp38;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp10_10), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta24,1,0) == 0) goto tmp9_end;
_attr = tmp10_10;
_cache = tmp10_1;
_env = tmp10_2;
_ih = tmp10_3;
_store = tmp10_4;
_ci_state = tmp10_5;
_mod = tmp10_6;
_pre = tmp10_7;
_n = tmp10_8;
_cl = tmp10_9;
_pf = tmp10_11;
_dims = tmp10_12;
_idxs = tmp10_13;
_inst_dims = tmp10_14;
_impl = tmp10_15;
_comment = tmp10_16;
_graph = tmp10_17;
_csets = tmp10_18;
tmp25 = omc_AbsynUtil_isOnlyOuter(threadData, _io);
if (1 != tmp25) goto goto_8;
tmp26 = omc_Mod_modEqual(threadData, _mod, _OMC_LIT43);
if (1 != tmp26) goto goto_8;
tmpMeta27 = omc_InnerOuter_lookupInnerVar(threadData, _cache, _env, _ih, _pre, _n, _io);
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 8));
if (optionNone(tmpMeta28)) goto goto_8;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta28), 1));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta29), 2));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta29), 3));
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta29), 4));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta29), 7));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta29), 8));
_cache = tmpMeta30;
_compenv = tmpMeta31;
_store = tmpMeta32;
_ty = tmpMeta33;
_graph = tmpMeta34;
_topInstance = listHead(_ih);
tmpMeta35 = _topInstance;
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta35), 5));
_sm = tmpMeta36;
tmp37 = (omc_BaseHashSet_currentSize(threadData, _sm) > ((modelica_integer) 0));
if (1 != tmp37) goto goto_8;
_cref = omc_PrefixUtil_prefixToCref(threadData, _inPrefix);
tmp38 = omc_BaseHashSet_has(threadData, _cref, _sm);
if (1 != tmp38) goto goto_8;
_cache = omc_InstVar_instVar__dispatch(threadData, _cache, _env, _ih, _store, _ci_state, _mod, _pre, _n, _cl, _attr, _pf, _dims, _idxs, _inst_dims, _impl, _comment, _info, _graph, _csets ,&_compenv ,&_ih ,&_store ,&_dae ,&_csets ,&_ty ,&_graph);
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _compenv;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = _store;
tmpMeta[0+4] = _dae;
tmpMeta[0+5] = _csets;
tmpMeta[0+6] = _ty;
tmpMeta[0+7] = _graph;
goto tmp9_done;
}
case 3: {
modelica_boolean tmp39;
modelica_boolean tmp40;
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
_cache = tmp10_1;
_env = tmp10_2;
_ih = tmp10_3;
_store = tmp10_4;
_mod = tmp10_6;
_pre = tmp10_7;
_n = tmp10_8;
_graph = tmp10_17;
_csets = tmp10_18;
tmp39 = omc_AbsynUtil_isOnlyOuter(threadData, _io);
if (1 != tmp39) goto goto_8;
tmp40 = omc_Mod_modEqual(threadData, _mod, _OMC_LIT43);
if (1 != tmp40) goto goto_8;
tmpMeta41 = omc_InnerOuter_lookupInnerVar(threadData, _cache, _env, _ih, _pre, _n, _io);
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 2));
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 3));
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 4));
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 5));
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 6));
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 7));
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 8));
if (optionNone(tmpMeta48)) goto goto_8;
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta48), 1));
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta49), 2));
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta49), 3));
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta49), 4));
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta49), 5));
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta49), 7));
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta49), 8));
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 9));
_innerPrefix = tmpMeta42;
_nInner = tmpMeta43;
_ioInner = tmpMeta44;
_fullName = tmpMeta45;
_typePath = tmpMeta46;
_innerScope = tmpMeta47;
_instResult = tmpMeta48;
_cache = tmpMeta50;
_compenv = tmpMeta51;
_store = tmpMeta52;
_outerDAE = tmpMeta53;
_ty = tmpMeta54;
_graph = tmpMeta55;
_outers = tmpMeta56;
tmpMeta57 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_PrefixUtil_prefixCref(threadData, _cache, _env, _ih, _pre, omc_ComponentReference_makeCrefIdent(threadData, _n, _OMC_LIT1, tmpMeta57) ,&_crefOuter);
tmpMeta58 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_PrefixUtil_prefixCref(threadData, _cache, _env, _ih, _innerPrefix, omc_ComponentReference_makeCrefIdent(threadData, _n, _OMC_LIT1, tmpMeta58) ,&_crefInner);
_ih = omc_InnerOuter_addOuterPrefixToIH(threadData, _ih, _crefOuter, _crefInner);
_outers = omc_List_unionElt(threadData, _crefOuter, _outers);
tmpMeta59 = mmc_mk_box10(3, &InnerOuter_InstInner_INST__INNER__desc, _innerPrefix, _nInner, _ioInner, _fullName, _typePath, _innerScope, _instResult, _outers, mmc_mk_none());
_ih = omc_InnerOuter_updateInstHierarchy(threadData, _ih, _innerPrefix, _ioInner, tmpMeta59);
_outerDAE = _OMC_LIT0;
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _compenv;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = _store;
tmpMeta[0+4] = _outerDAE;
tmpMeta[0+5] = _csets;
tmpMeta[0+6] = _ty;
tmpMeta[0+7] = _graph;
goto tmp9_done;
}
case 4: {
modelica_boolean tmp60;
modelica_boolean tmp61;
modelica_metatype tmpMeta62;
modelica_metatype tmpMeta63;
modelica_metatype tmpMeta64;
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
modelica_metatype tmpMeta67;
modelica_metatype tmpMeta68;
_cache = tmp10_1;
_env = tmp10_2;
_ih = tmp10_3;
_store = tmp10_4;
_ci_state = tmp10_5;
_mod = tmp10_6;
_pre = tmp10_7;
_n = tmp10_8;
_cl = tmp10_9;
_attr = tmp10_10;
_pf = tmp10_11;
_dims = tmp10_12;
_idxs = tmp10_13;
_inst_dims = tmp10_14;
_impl = tmp10_15;
_comment = tmp10_16;
_graph = tmp10_17;
_csets = tmp10_18;
tmp60 = omc_AbsynUtil_isOnlyOuter(threadData, _io);
if (1 != tmp60) goto goto_8;
tmp61 = omc_Mod_modEqual(threadData, _mod, _OMC_LIT43);
if (1 != tmp61) goto goto_8;
tmpMeta62 = omc_InnerOuter_lookupInnerVar(threadData, _cache, _env, _ih, _pre, _n, _io);
tmpMeta63 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta62), 6));
tmpMeta64 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta62), 8));
if (!optionNone(tmpMeta64)) goto goto_8;
_typePath = tmpMeta63;
tmpMeta65 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_PrefixUtil_prefixCref(threadData, _cache, _env, _ih, _pre, omc_ComponentReference_makeCrefIdent(threadData, _n, _OMC_LIT1, tmpMeta65) ,&_crefOuter);
_typeName = omc_SCodeUtil_className(threadData, _cl);
_cache = omc_Inst_makeFullyQualifiedIdent(threadData, _cache, _env, _typeName, _OMC_LIT68 ,&_typePath);
if(((!(_impl && listMember(_pre, _OMC_LIT78))) && (!omc_Config_getGraphicsExpMode(threadData))))
{
_s1 = omc_ComponentReference_printComponentRefStr(threadData, _crefOuter);
_s2 = omc_Dump_unparseInnerouterStr(threadData, _io);
_s3 = omc_InnerOuter_getExistingInnerDeclarations(threadData, _ih, _componentDefinitionParentEnv);
tmpMeta66 = stringAppend(omc_AbsynUtil_pathString(threadData, _typePath, _OMC_LIT34, 1, 0),_OMC_LIT69);
tmpMeta67 = stringAppend(tmpMeta66,_s1);
_s1 = tmpMeta67;
tmpMeta68 = mmc_mk_cons(_s1, mmc_mk_cons(_s2, mmc_mk_cons(_s3, MMC_REFSTRUCTLIT(mmc_nil))));
omc_Error_addSourceMessage(threadData, _OMC_LIT76, tmpMeta68, _info);
}
_cache = omc_InstVar_instVar__dispatch(threadData, _cache, _env, _ih, _store, _ci_state, _mod, _pre, _n, _cl, _attr, _pf, _dims, _idxs, _inst_dims, _impl, _comment, _info, _graph, _csets ,&_compenv ,&_ih ,&_store ,&_dae ,NULL ,&_ty ,&_graph);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _compenv;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = _store;
tmpMeta[0+4] = _dae;
tmpMeta[0+5] = _csets;
tmpMeta[0+6] = _ty;
tmpMeta[0+7] = _graph;
goto tmp9_done;
}
case 5: {
modelica_boolean tmp69;
modelica_boolean tmp70;
modelica_boolean tmp71;
modelica_metatype tmpMeta73;
modelica_metatype tmpMeta74;
modelica_metatype tmpMeta75;
modelica_metatype tmpMeta76;
_cache = tmp10_1;
_env = tmp10_2;
_ih = tmp10_3;
_store = tmp10_4;
_ci_state = tmp10_5;
_mod = tmp10_6;
_pre = tmp10_7;
_n = tmp10_8;
_cl = tmp10_9;
_attr = tmp10_10;
_pf = tmp10_11;
_dims = tmp10_12;
_idxs = tmp10_13;
_inst_dims = tmp10_14;
_impl = tmp10_15;
_comment = tmp10_16;
_graph = tmp10_17;
_csets = tmp10_18;
tmp69 = omc_AbsynUtil_isOnlyOuter(threadData, _io);
if (1 != tmp69) goto goto_8;
tmp70 = omc_Mod_modEqual(threadData, _mod, _OMC_LIT43);
if (1 != tmp70) goto goto_8;
tmp71 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_InnerOuter_lookupInnerVar(threadData, _cache, _env, _ih, _pre, _n, _io);
tmp71 = 1;
goto goto_72;
goto_72:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp71) {goto goto_8;}
tmpMeta73 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_PrefixUtil_prefixCref(threadData, _cache, _env, _ih, _pre, omc_ComponentReference_makeCrefIdent(threadData, _n, _OMC_LIT1, tmpMeta73) ,&_crefOuter);
_typeName = omc_SCodeUtil_className(threadData, _cl);
_cache = omc_Inst_makeFullyQualifiedIdent(threadData, _cache, _env, _typeName, _OMC_LIT68 ,&_typePath);
if(((!(_impl && listMember(_pre, _OMC_LIT78))) && (!omc_Config_getGraphicsExpMode(threadData))))
{
_s1 = omc_ComponentReference_printComponentRefStr(threadData, _crefOuter);
_s2 = omc_Dump_unparseInnerouterStr(threadData, _io);
_s3 = omc_InnerOuter_getExistingInnerDeclarations(threadData, _ih, _componentDefinitionParentEnv);
tmpMeta74 = stringAppend(omc_AbsynUtil_pathString(threadData, _typePath, _OMC_LIT34, 1, 0),_OMC_LIT69);
tmpMeta75 = stringAppend(tmpMeta74,_s1);
_s1 = tmpMeta75;
tmpMeta76 = mmc_mk_cons(_s1, mmc_mk_cons(_s2, mmc_mk_cons(_s3, MMC_REFSTRUCTLIT(mmc_nil))));
omc_Error_addSourceMessage(threadData, _OMC_LIT76, tmpMeta76, _info);
}
_cache = omc_InstVar_instVar__dispatch(threadData, _cache, _env, _ih, _store, _ci_state, _mod, _pre, _n, _cl, _attr, _pf, _dims, _idxs, _inst_dims, _impl, _comment, _info, _graph, _csets ,&_compenv ,&_ih ,&_store ,&_dae ,NULL ,&_ty ,&_graph);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _compenv;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = _store;
tmpMeta[0+4] = _dae;
tmpMeta[0+5] = _csets;
tmpMeta[0+6] = _ty;
tmpMeta[0+7] = _graph;
goto tmp9_done;
}
case 6: {
modelica_metatype tmpMeta77;
modelica_metatype tmpMeta78;
modelica_boolean tmp79;
modelica_metatype tmpMeta80;
modelica_metatype tmpMeta81;
modelica_boolean tmp82;
modelica_boolean tmp83;
modelica_metatype tmpMeta84;
modelica_metatype tmpMeta85;
modelica_metatype tmpMeta86;
modelica_metatype tmpMeta87;
if (mmc__uniontype__metarecord__typedef__equal(tmp10_9,2,8) == 0) goto tmp9_end;
tmpMeta77 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp10_9), 2));
tmpMeta78 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp10_10), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta78,1,0) == 0) goto tmp9_end;
_cl = tmp10_9;
_typeName = tmpMeta77;
_attr = tmp10_10;
_cache = tmp10_1;
_env = tmp10_2;
_ih = tmp10_3;
_store = tmp10_4;
_ci_state = tmp10_5;
_mod = tmp10_6;
_pre = tmp10_7;
_n = tmp10_8;
_pf = tmp10_11;
_dims = tmp10_12;
_idxs = tmp10_13;
_inst_dims = tmp10_14;
_impl = tmp10_15;
_comment = tmp10_16;
_graph = tmp10_17;
_csets = tmp10_18;
tmp79 = omc_AbsynUtil_isInnerOuter(threadData, _io);
if (1 != tmp79) goto goto_8;
_topInstance = listHead(_ih);
tmpMeta80 = _topInstance;
tmpMeta81 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta80), 5));
_sm = tmpMeta81;
tmp82 = (omc_BaseHashSet_currentSize(threadData, _sm) > ((modelica_integer) 0));
if (1 != tmp82) goto goto_8;
_cref = omc_PrefixUtil_prefixToCref(threadData, _inPrefix);
tmp83 = omc_BaseHashSet_has(threadData, _cref, _sm);
if (1 != tmp83) goto goto_8;
_cache = omc_InstVar_instVar__dispatch(threadData, _cache, _env, _ih, _store, _ci_state, _mod, _pre, _n, _cl, _attr, _pf, _dims, _idxs, _inst_dims, _impl, _comment, _info, _graph, _csets ,&_innerCompEnv ,&_ih ,&_store ,&_dae ,&_csetsInner ,&_ty ,&_graph);
tmpMeta84 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_PrefixUtil_prefixCref(threadData, _cache, _env, _ih, _pre, omc_ComponentReference_makeCrefIdent(threadData, _n, _OMC_LIT1, tmpMeta84) ,&_cref);
_fullName = omc_ComponentReference_printComponentRefStr(threadData, _cref);
_cache = omc_Inst_makeFullyQualifiedIdent(threadData, _cache, _env, _typeName, _OMC_LIT68 ,&_typePath);
_outerCompEnv = omc_InnerOuter_switchInnerToOuterInGraph(threadData, _innerCompEnv, _cref);
_innerDAE = _dae;
_innerScope = omc_FGraph_printGraphPathStr(threadData, _componentDefinitionParentEnv);
tmpMeta85 = mmc_mk_box8(3, &InnerOuter_InstResult_INST__RESULT__desc, _cache, _outerCompEnv, _store, _innerDAE, _csetsInner, _ty, _graph);
tmpMeta86 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta87 = mmc_mk_box10(3, &InnerOuter_InstInner_INST__INNER__desc, _pre, _n, _io, _fullName, _typePath, _innerScope, mmc_mk_some(tmpMeta85), tmpMeta86, mmc_mk_none());
_ih = omc_InnerOuter_updateInstHierarchy(threadData, _ih, _pre, _io, tmpMeta87);
_cache = omc_InstVar_instVar__dispatch(threadData, _cache, _env, _ih, _store, _ci_state, _OMC_LIT43, _pre, _n, _cl, _attr, _pf, _dims, _idxs, _inst_dims, _impl, _comment, _info, _graph, _csets ,&_compenv ,&_ih ,&_store ,&_dae ,NULL ,&_ty ,&_graph);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _compenv;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = _store;
tmpMeta[0+4] = _dae;
tmpMeta[0+5] = _csetsInner;
tmpMeta[0+6] = _ty;
tmpMeta[0+7] = _graph;
goto tmp9_done;
}
case 7: {
modelica_metatype tmpMeta88;
modelica_boolean tmp89;
modelica_metatype tmpMeta90;
modelica_metatype tmpMeta91;
modelica_metatype tmpMeta92;
modelica_metatype tmpMeta93;
if (mmc__uniontype__metarecord__typedef__equal(tmp10_9,2,8) == 0) goto tmp9_end;
tmpMeta88 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp10_9), 2));
_cl = tmp10_9;
_typeName = tmpMeta88;
_cache = tmp10_1;
_env = tmp10_2;
_ih = tmp10_3;
_store = tmp10_4;
_ci_state = tmp10_5;
_mod = tmp10_6;
_pre = tmp10_7;
_n = tmp10_8;
_attr = tmp10_10;
_pf = tmp10_11;
_dims = tmp10_12;
_idxs = tmp10_13;
_inst_dims = tmp10_14;
_impl = tmp10_15;
_comment = tmp10_16;
_graph = tmp10_17;
_csets = tmp10_18;
tmp89 = omc_AbsynUtil_isInnerOuter(threadData, _io);
if (1 != tmp89) goto goto_8;
_cache = omc_InstVar_instVar__dispatch(threadData, _cache, _env, _ih, _store, _ci_state, _mod, _pre, _n, _cl, _attr, _pf, _dims, _idxs, _inst_dims, _impl, _comment, _info, _graph, _csets ,&_innerCompEnv ,&_ih ,&_store ,&_dae ,&_csetsInner ,&_ty ,&_graph);
tmpMeta90 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_PrefixUtil_prefixCref(threadData, _cache, _env, _ih, _pre, omc_ComponentReference_makeCrefIdent(threadData, _n, _OMC_LIT1, tmpMeta90) ,&_cref);
_fullName = omc_ComponentReference_printComponentRefStr(threadData, _cref);
_cache = omc_Inst_makeFullyQualifiedIdent(threadData, _cache, _env, _typeName, _OMC_LIT68 ,&_typePath);
_outerCompEnv = omc_InnerOuter_switchInnerToOuterInGraph(threadData, _innerCompEnv, _cref);
_innerDAE = _dae;
_innerScope = omc_FGraph_printGraphPathStr(threadData, _componentDefinitionParentEnv);
tmpMeta91 = mmc_mk_box8(3, &InnerOuter_InstResult_INST__RESULT__desc, _cache, _outerCompEnv, _store, _innerDAE, _csetsInner, _ty, _graph);
tmpMeta92 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta93 = mmc_mk_box10(3, &InnerOuter_InstInner_INST__INNER__desc, _pre, _n, _io, _fullName, _typePath, _innerScope, mmc_mk_some(tmpMeta91), tmpMeta92, mmc_mk_none());
_ih = omc_InnerOuter_updateInstHierarchy(threadData, _ih, _pre, _io, tmpMeta93);
_pf = omc_SCodeUtil_prefixesSetInnerOuter(threadData, _pf, _OMC_LIT79);
_cache = omc_InstVar_instVar(threadData, _cache, _env, _ih, _store, _ci_state, _OMC_LIT43, _pre, _n, _cl, _attr, _pf, _dims, _idxs, _inst_dims, _impl, _comment, _info, _graph, _csets, _componentDefinitionParentEnv ,&_compenv ,&_ih ,&_store ,&_dae ,NULL ,&_ty ,&_graph);
_outerDAE = _dae;
_dae = omc_DAEUtil_joinDaes(threadData, _outerDAE, _innerDAE);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _compenv;
tmpMeta[0+2] = _ih;
tmpMeta[0+3] = _store;
tmpMeta[0+4] = _dae;
tmpMeta[0+5] = _csetsInner;
tmpMeta[0+6] = _ty;
tmpMeta[0+7] = _graph;
goto tmp9_done;
}
case 8: {
modelica_boolean tmp94;
_cache = tmp10_1;
_env = tmp10_2;
_ih = tmp10_3;
_store = tmp10_4;
_ci_state = tmp10_5;
_mod = tmp10_6;
_pre = tmp10_7;
_n = tmp10_8;
_cl = tmp10_9;
_attr = tmp10_10;
_pf = tmp10_11;
_dims = tmp10_12;
_idxs = tmp10_13;
_inst_dims = tmp10_14;
_impl = tmp10_15;
_comment = tmp10_16;
_graph = tmp10_17;
_csets = tmp10_18;
tmp94 = omc_AbsynUtil_isNotInnerOuter(threadData, _io);
if (1 != tmp94) goto goto_8;
tmpMeta[0+0] = omc_InstVar_instVar__dispatch(threadData, _cache, _env, _ih, _store, _ci_state, _mod, _pre, _n, _cl, _attr, _pf, _dims, _idxs, _inst_dims, _impl, _comment, _info, _graph, _csets, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3], &tmpMeta[0+4], &tmpMeta[0+5], &tmpMeta[0+6], &tmpMeta[0+7]);
goto tmp9_done;
}
case 9: {
modelica_boolean tmp95;
modelica_metatype tmpMeta96;
modelica_metatype tmpMeta97;
modelica_metatype tmpMeta98;
modelica_metatype tmpMeta99;
modelica_metatype tmpMeta100;
modelica_metatype tmpMeta101;
modelica_metatype tmpMeta102;
modelica_metatype tmpMeta103;
_cache = tmp10_1;
_env = tmp10_2;
_ih = tmp10_3;
_mod = tmp10_6;
_pre = tmp10_7;
_n = tmp10_8;
_cl = tmp10_9;
tmp95 = omc_Flags_isSet(threadData, _OMC_LIT29);
if (1 != tmp95) goto goto_8;
tmpMeta96 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_PrefixUtil_prefixCref(threadData, _cache, _env, _ih, _pre, omc_ComponentReference_makeCrefIdent(threadData, _n, _OMC_LIT1, tmpMeta96) ,&_cref);
tmpMeta97 = stringAppend(_OMC_LIT80,omc_ComponentReference_printComponentRefStr(threadData, _cref));
tmpMeta98 = stringAppend(tmpMeta97,_OMC_LIT69);
tmpMeta99 = stringAppend(tmpMeta98,omc_Mod_prettyPrintMod(threadData, _mod, ((modelica_integer) 0)));
tmpMeta100 = stringAppend(tmpMeta99,_OMC_LIT81);
tmpMeta101 = stringAppend(tmpMeta100,omc_FGraph_printGraphPathStr(threadData, _env));
tmpMeta102 = stringAppend(tmpMeta101,_OMC_LIT82);
tmpMeta103 = stringAppend(tmpMeta102,omc_SCodeDump_unparseElementStr(threadData, _cl, _OMC_LIT83));
omc_Debug_traceln(threadData, tmpMeta103);
goto goto_8;
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
if (++tmp10 < 10) {
goto tmp9_top;
}
MMC_THROW_INTERNAL();
tmp9_done2:;
}
}
_outCache = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_outIH = tmpMeta[0+2];
_outStore = tmpMeta[0+3];
_outDae = tmpMeta[0+4];
_outSets = tmpMeta[0+5];
_outType = tmpMeta[0+6];
_outGraph = tmpMeta[0+7];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outIH) { *out_outIH = _outIH; }
if (out_outStore) { *out_outStore = _outStore; }
if (out_outDae) { *out_outDae = _outDae; }
if (out_outSets) { *out_outSets = _outSets; }
if (out_outType) { *out_outType = _outType; }
if (out_outGraph) { *out_outGraph = _outGraph; }
return _outCache;
}
modelica_metatype boxptr_InstVar_instVar(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inStore, modelica_metatype _inState, modelica_metatype _inMod, modelica_metatype _inPrefix, modelica_metatype _inIdent, modelica_metatype _inClass, modelica_metatype _inAttributes, modelica_metatype _inPrefixes, modelica_metatype _inDimensionLst, modelica_metatype _inIntegerLst, modelica_metatype _inInstDims, modelica_metatype _inImpl, modelica_metatype _inComment, modelica_metatype _info, modelica_metatype _inGraph, modelica_metatype _inSets, modelica_metatype _componentDefinitionParentEnv, modelica_metatype *out_outEnv, modelica_metatype *out_outIH, modelica_metatype *out_outStore, modelica_metatype *out_outDae, modelica_metatype *out_outSets, modelica_metatype *out_outType, modelica_metatype *out_outGraph)
{
modelica_integer tmp1;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inImpl);
_outCache = omc_InstVar_instVar(threadData, _inCache, _inEnv, _inIH, _inStore, _inState, _inMod, _inPrefix, _inIdent, _inClass, _inAttributes, _inPrefixes, _inDimensionLst, _inIntegerLst, _inInstDims, tmp1, _inComment, _info, _inGraph, _inSets, _componentDefinitionParentEnv, out_outEnv, out_outIH, out_outStore, out_outDae, out_outSets, out_outType, out_outGraph);
return _outCache;
}
