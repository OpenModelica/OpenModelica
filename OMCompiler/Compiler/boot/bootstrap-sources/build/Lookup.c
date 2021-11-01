#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "Lookup.c"
#endif
#include "omc_simulation_settings.h"
#include "Lookup.h"
#define _OMC_LIT0_data "functionViaComponentRef10"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,25,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,1,4) {&SCode_Encapsulated_NOT__ENCAPSULATED__desc,}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT2,1,4) {&FCore_ScopeType_CLASS__SCOPE__desc,}};
#define _OMC_LIT2 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,1,1) {_OMC_LIT2}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,1,4) {&UnitAbsyn_InstStore_NOSTORE__desc,}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,1,5) {&DAE_Mod_NOMOD__desc,}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,1,3) {&DAE_Prefix_NOPRE__desc,}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,0,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT8,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT7}};
#define _OMC_LIT8 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,2,24) {&ClassInf_State_META__RECORD__desc,_OMC_LIT8}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,1,4) {&InstTypes_CallingScope_INNER__CALL__desc,}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,7,3) {&ConnectionGraph_ConnectionGraph_GRAPH__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT12,1,7) {&DAE_ComponentRef_WILD__desc,}};
#define _OMC_LIT12 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT12)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT13,5,3) {&DAE_Connect_SetTrieNode_SET__TRIE__NODE__desc,_OMC_LIT7,_OMC_LIT12,MMC_REFSTRUCTLIT(mmc_nil),MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT13 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT13)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT14,5,3) {&DAE_Connect_Sets_SETS__desc,_OMC_LIT13,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT14 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,2,3) {&DAE_Type_T__INTEGER__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT16,2,3) {&DAE_Exp_ICONST__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT16 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT16)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT17,2,1) {_OMC_LIT16,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT17 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT18,4,19) {&DAE_Exp_ARRAY__desc,_OMC_LIT15,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT17}};
#define _OMC_LIT18 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,2,4) {&DAE_Subscript_SLICE__desc,_OMC_LIT18}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT20,2,3) {&DAE_Exp_ICONST__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1))}};
#define _OMC_LIT20 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT20)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT21,2,6) {&DAE_Exp_BCONST__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT21 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT21)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT22,2,6) {&DAE_Exp_BCONST__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1))}};
#define _OMC_LIT22 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT22)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT23,2,1) {_OMC_LIT22,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT23 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT23)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT24,2,1) {_OMC_LIT21,_OMC_LIT23}};
#define _OMC_LIT24 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT24)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT25,2,6) {&DAE_Type_T__BOOL__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT25 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT25)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT26,1,3) {&DAE_Const_C__CONST__desc,}};
#define _OMC_LIT26 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data "failtrace"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,9,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data "Sets whether to print a failtrace or not."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,41,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT29,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT28}};
#define _OMC_LIT29 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT29)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT30,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT27,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT29}};
#define _OMC_LIT30 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data "- Lookup.checkSubscripts failed (tp: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,37,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
#define _OMC_LIT32_data " subs:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT32,6,_OMC_LIT32_data);
#define _OMC_LIT32 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT32)
#define _OMC_LIT33_data ","
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT33,1,_OMC_LIT33_data);
#define _OMC_LIT33 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT33)
#define _OMC_LIT34_data ")\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT34,2,_OMC_LIT34_data);
#define _OMC_LIT34 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT34)
#define _OMC_LIT35_data " = "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT35,3,_OMC_LIT35_data);
#define _OMC_LIT35 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT35)
#define _OMC_LIT36_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT36,1,_OMC_LIT36_data);
#define _OMC_LIT36 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT36)
#define _OMC_LIT37_data "- Lookup.lookupVar2 failed because we found a class instead of a variable: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT37,75,_OMC_LIT37_data);
#define _OMC_LIT37 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT37)
#define _OMC_LIT38_data "lookup"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT38,6,_OMC_LIT38_data);
#define _OMC_LIT38 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT38)
#define _OMC_LIT39_data "Print extra failtrace from lookup."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT39,34,_OMC_LIT39_data);
#define _OMC_LIT39 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT39)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT40,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT39}};
#define _OMC_LIT40 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT40)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT41,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(20)),_OMC_LIT38,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT40}};
#define _OMC_LIT41 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT41)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT42,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT42 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT42)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT43,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT43 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT43)
#define _OMC_LIT44_data "%s found in several unqualified import statements."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT44,50,_OMC_LIT44_data);
#define _OMC_LIT44 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT44)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT45,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT44}};
#define _OMC_LIT45 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT45)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT46,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(57)),_OMC_LIT42,_OMC_LIT43,_OMC_LIT45}};
#define _OMC_LIT46 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT46)
#define _OMC_LIT47_data "Class %s not found in scope %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT47,31,_OMC_LIT47_data);
#define _OMC_LIT47 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT47)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT48,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT47}};
#define _OMC_LIT48 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT48)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT49,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(3)),_OMC_LIT42,_OMC_LIT43,_OMC_LIT48}};
#define _OMC_LIT49 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT49)
#define _OMC_LIT50_data "result"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT50,6,_OMC_LIT50_data);
#define _OMC_LIT50 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT50)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT51,1,3) {&SCode_Visibility_PUBLIC__desc,}};
#define _OMC_LIT51 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT51)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT52,1,4) {&SCode_Redeclare_NOT__REDECLARE__desc,}};
#define _OMC_LIT52 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT52)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT53,1,4) {&SCode_Final_NOT__FINAL__desc,}};
#define _OMC_LIT53 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT53)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT54,1,6) {&Absyn_InnerOuter_NOT__INNER__OUTER__desc,}};
#define _OMC_LIT54 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT54)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT55,1,4) {&SCode_Replaceable_NOT__REPLACEABLE__desc,}};
#define _OMC_LIT55 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT55)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT56,6,3) {&SCode_Prefixes_PREFIXES__desc,_OMC_LIT51,_OMC_LIT52,_OMC_LIT53,_OMC_LIT54,_OMC_LIT55}};
#define _OMC_LIT56 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT56)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT57,1,3) {&SCode_ConnectorType_POTENTIAL__desc,}};
#define _OMC_LIT57 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT57)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT58,1,5) {&SCode_Parallelism_NON__PARALLEL__desc,}};
#define _OMC_LIT58 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT58)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT59,1,3) {&SCode_Variability_VAR__desc,}};
#define _OMC_LIT59 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT59)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT60,1,4) {&Absyn_Direction_OUTPUT__desc,}};
#define _OMC_LIT60 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT60)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT61,1,3) {&Absyn_IsField_NONFIELD__desc,}};
#define _OMC_LIT61 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT61)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT62,7,3) {&SCode_Attributes_ATTR__desc,MMC_REFSTRUCTLIT(mmc_nil),_OMC_LIT57,_OMC_LIT58,_OMC_LIT59,_OMC_LIT60,_OMC_LIT61}};
#define _OMC_LIT62 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT62)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT63,1,5) {&SCode_Mod_NOMOD__desc,}};
#define _OMC_LIT63 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT63)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT64,3,3) {&SCode_Comment_COMMENT__desc,MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT64 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT64)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT65,1,5) {&Absyn_Direction_BIDIR__desc,}};
#define _OMC_LIT65 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT65)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT66,1,4) {&SCode_Visibility_PROTECTED__desc,}};
#define _OMC_LIT66 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT66)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT67,1,3) {&Absyn_Direction_INPUT__desc,}};
#define _OMC_LIT67 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT67)
#define _OMC_LIT68_data "- Lookup.buildRecordConstructorElts failed "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT68,43,_OMC_LIT68_data);
#define _OMC_LIT68 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT68)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT69,10,3) {&SCodeDump_SCodeDumpOptions_OPTIONS__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT69 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT69)
#define _OMC_LIT70_data " with mod: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT70,11,_OMC_LIT70_data);
#define _OMC_LIT70 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT70)
#define _OMC_LIT71_data " and: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT71,6,_OMC_LIT71_data);
#define _OMC_LIT71 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT71)
#define _OMC_LIT72_data "buildRecordConstructorClass2 failed, cl:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT72,40,_OMC_LIT72_data);
#define _OMC_LIT72 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT72)
#define _OMC_LIT73_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT73,1,_OMC_LIT73_data);
#define _OMC_LIT73 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT73)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT74,1,4) {&SCode_Partial_NOT__PARTIAL__desc,}};
#define _OMC_LIT74 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT74)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT75,1,6) {&SCode_FunctionRestriction_FR__RECORD__CONSTRUCTOR__desc,}};
#define _OMC_LIT75 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT75)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT76,2,12) {&SCode_Restriction_R__FUNCTION__desc,_OMC_LIT75}};
#define _OMC_LIT76 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT76)
#define _OMC_LIT77_data "buildRecordConstructorClass failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT77,35,_OMC_LIT77_data);
#define _OMC_LIT77 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT77)
#define _OMC_LIT78_data "Found a component with same name when looking for type %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT78,58,_OMC_LIT78_data);
#define _OMC_LIT78 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT78)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT79,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT78}};
#define _OMC_LIT79 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT79)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT80,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(58)),_OMC_LIT42,_OMC_LIT43,_OMC_LIT79}};
#define _OMC_LIT80 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT80)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT81,1,3) {&InstTypes_CallingScope_TOP__CALL__desc,}};
#define _OMC_LIT81 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT81)
#define _OMC_LIT82_data "$ty"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT82,3,_OMC_LIT82_data);
#define _OMC_LIT82 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT82)
#define _OMC_LIT83_data "x"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT83,1,_OMC_LIT83_data);
#define _OMC_LIT83 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT83)
#define _OMC_LIT84_data "$$"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT84,2,_OMC_LIT84_data);
#define _OMC_LIT84 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT84)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT85,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT84}};
#define _OMC_LIT85 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT85)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT86,3,8) {&ClassInf_State_CONNECTOR__desc,_OMC_LIT85,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT86 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT86)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT87,4,12) {&DAE_Type_T__COMPLEX__desc,_OMC_LIT86,MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT87 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT87)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT88,1,5) {&DAE_Const_C__VAR__desc,}};
#define _OMC_LIT88 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT88)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT89,1,5) {&DAE_VarParallelism_NON__PARALLEL__desc,}};
#define _OMC_LIT89 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT89)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT90,6,3) {&DAE_FuncArg_FUNCARG__desc,_OMC_LIT83,_OMC_LIT87,_OMC_LIT88,_OMC_LIT89,MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT90 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT90)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT91,2,1) {_OMC_LIT90,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT91 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT91)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT92,1,6) {&DAE_InlineType_DEFAULT__INLINE__desc,}};
#define _OMC_LIT92 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT92)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT93,1,3) {&DAE_FunctionBuiltin_FUNCTION__NOT__BUILTIN__desc,}};
#define _OMC_LIT93 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT93)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT94,1,3) {&DAE_FunctionParallelism_FP__NON__PARALLEL__desc,}};
#define _OMC_LIT94 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT94)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT95,7,3) {&DAE_FunctionAttributes_FUNCTION__ATTRIBUTES__desc,_OMC_LIT92,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT93,_OMC_LIT94}};
#define _OMC_LIT95 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT95)
#define _OMC_LIT96_data "cardinality"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT96,11,_OMC_LIT96_data);
#define _OMC_LIT96 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT96)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT97,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT96}};
#define _OMC_LIT97 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT97)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT98,5,14) {&DAE_Type_T__FUNCTION__desc,_OMC_LIT91,_OMC_LIT15,_OMC_LIT95,_OMC_LIT97}};
#define _OMC_LIT98 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT98)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT99,3,8) {&ClassInf_State_CONNECTOR__desc,_OMC_LIT85,MMC_IMMEDIATE(MMC_TAGFIXNUM(1))}};
#define _OMC_LIT99 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT99)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT100,4,12) {&DAE_Type_T__COMPLEX__desc,_OMC_LIT99,MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT100 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT100)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT101,6,3) {&DAE_FuncArg_FUNCARG__desc,_OMC_LIT83,_OMC_LIT100,_OMC_LIT88,_OMC_LIT89,MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT101 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT101)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT102,2,1) {_OMC_LIT101,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT102 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT102)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT103,5,14) {&DAE_Type_T__FUNCTION__desc,_OMC_LIT102,_OMC_LIT15,_OMC_LIT95,_OMC_LIT97}};
#define _OMC_LIT103 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT103)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT104,2,1) {_OMC_LIT103,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT104 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT104)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT105,2,1) {_OMC_LIT98,_OMC_LIT104}};
#define _OMC_LIT105 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT105)
#define _OMC_LIT106_data " not found in scope: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT106,21,_OMC_LIT106_data);
#define _OMC_LIT106 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT106)
#define _OMC_LIT107_data "Internal error %s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT107,17,_OMC_LIT107_data);
#define _OMC_LIT107 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT107)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT108,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT107}};
#define _OMC_LIT108 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT108)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT109,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(63)),_OMC_LIT42,_OMC_LIT43,_OMC_LIT108}};
#define _OMC_LIT109 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT109)
#define _OMC_LIT110_data "functionViaComponentRef"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT110,23,_OMC_LIT110_data);
#define _OMC_LIT110 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT110)
#define _OMC_LIT111_data "OpenModelica"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT111,12,_OMC_LIT111_data);
#define _OMC_LIT111 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT111)
#define _OMC_LIT112_data "Internal"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT112,8,_OMC_LIT112_data);
#define _OMC_LIT112 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT112)
#define _OMC_LIT113_data "ClockConstructor"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT113,16,_OMC_LIT113_data);
#define _OMC_LIT113 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT113)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT114,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT113}};
#define _OMC_LIT114 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT114)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT115,3,3) {&Absyn_Path_QUALIFIED__desc,_OMC_LIT112,_OMC_LIT114}};
#define _OMC_LIT115 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT115)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT116,3,3) {&Absyn_Path_QUALIFIED__desc,_OMC_LIT111,_OMC_LIT115}};
#define _OMC_LIT116 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT116)
#define _OMC_LIT117_data "Clock"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT117,5,_OMC_LIT117_data);
#define _OMC_LIT117 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT117)
#define _OMC_LIT118_data "lookupFunctionsInEnv failed on: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT118,32,_OMC_LIT118_data);
#define _OMC_LIT118 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT118)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT119,1,3) {&InstTypes_SearchStrategy_SEARCH__LOCAL__ONLY__desc,}};
#define _OMC_LIT119 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT119)
#define _OMC_LIT120_data "Variable %s in package %s is not constant."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT120,42,_OMC_LIT120_data);
#define _OMC_LIT120 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT120)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT121,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT120}};
#define _OMC_LIT121 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT121)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT122,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(91)),_OMC_LIT42,_OMC_LIT43,_OMC_LIT121}};
#define _OMC_LIT122 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT122)
#define _OMC_LIT123_data "- Lookup.checkPackageVariableConstant failed: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT123,46,_OMC_LIT123_data);
#define _OMC_LIT123 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT123)
#define _OMC_LIT124_data " in "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT124,4,_OMC_LIT124_data);
#define _OMC_LIT124 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT124)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT125,1,4) {&InstTypes_SearchStrategy_SEARCH__ALSO__BUILTIN__desc,}};
#define _OMC_LIT125 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT125)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT126,1,11) {&DAE_Type_T__UNKNOWN__desc,}};
#define _OMC_LIT126 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT126)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT127,1,6) {&DAE_ConnectorType_NON__CONNECTOR__desc,}};
#define _OMC_LIT127 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT127)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT128,1,6) {&SCode_Variability_CONST__desc,}};
#define _OMC_LIT128 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT128)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT129,7,3) {&DAE_Attributes_ATTR__desc,_OMC_LIT127,_OMC_LIT58,_OMC_LIT128,_OMC_LIT65,_OMC_LIT54,_OMC_LIT51}};
#define _OMC_LIT129 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT129)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT130,1,3) {&DAE_Binding_UNBOUND__desc,}};
#define _OMC_LIT130 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT130)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT131,3,3) {&InstTypes_SplicedExpData_SPLICEDEXPDATA__desc,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT126}};
#define _OMC_LIT131 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT131)
#define _OMC_LIT132_data "#varNotFound#"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT132,13,_OMC_LIT132_data);
#define _OMC_LIT132 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT132)
#define _OMC_LIT133_data "%s is partial, name lookup is not allowed in partial classes."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT133,61,_OMC_LIT133_data);
#define _OMC_LIT133 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT133)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT134,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT133}};
#define _OMC_LIT134 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT134)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT135,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(107)),_OMC_LIT42,_OMC_LIT43,_OMC_LIT134}};
#define _OMC_LIT135 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT135)
#define _OMC_LIT136_data "component %s contains the definition of a partial class %s.\nPlease redeclare it to any package compatible with %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT136,114,_OMC_LIT136_data);
#define _OMC_LIT136 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT136)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT137,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT136}};
#define _OMC_LIT137 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT137)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT138,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(285)),_OMC_LIT42,_OMC_LIT43,_OMC_LIT137}};
#define _OMC_LIT138 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT138)
#define _OMC_LIT139_data "functionViaComponentRef2"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT139,24,_OMC_LIT139_data);
#define _OMC_LIT139 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT139)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT140,0.0);
#define _OMC_LIT140 MMC_REFREALLIT(_OMC_LIT_STRUCT140)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT141,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT7,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT140}};
#define _OMC_LIT141 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT141)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT142,1,1) {_OMC_LIT141}};
#define _OMC_LIT142 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT142)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT143,2,4) {&DAE_Type_T__REAL__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT143 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT143)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT144,2,5) {&DAE_Type_T__STRING__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT144 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT144)
#define _OMC_LIT145_data "Real"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT145,4,_OMC_LIT145_data);
#define _OMC_LIT145 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT145)
#define _OMC_LIT146_data "Integer"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT146,7,_OMC_LIT146_data);
#define _OMC_LIT146 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT146)
#define _OMC_LIT147_data "Boolean"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT147,7,_OMC_LIT147_data);
#define _OMC_LIT147 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT147)
#define _OMC_LIT148_data "String"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT148,6,_OMC_LIT148_data);
#define _OMC_LIT148 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT148)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT149,2,19) {&DAE_Type_T__ANYTYPE__desc,MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT149 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT149)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT150,6,3) {&DAE_FuncArg_FUNCARG__desc,_OMC_LIT83,_OMC_LIT149,_OMC_LIT88,_OMC_LIT89,MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT150 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT150)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT151,2,1) {_OMC_LIT150,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT151 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT151)
#define _OMC_LIT152_data "rooted"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT152,6,_OMC_LIT152_data);
#define _OMC_LIT152 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT152)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT153,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT152}};
#define _OMC_LIT153 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT153)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT154,5,14) {&DAE_Type_T__FUNCTION__desc,_OMC_LIT151,_OMC_LIT25,_OMC_LIT95,_OMC_LIT153}};
#define _OMC_LIT154 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT154)
#define _OMC_LIT155_data " (its type) "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT155,12,_OMC_LIT155_data);
#define _OMC_LIT155 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT155)
#define _OMC_LIT156_data "roots"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT156,5,_OMC_LIT156_data);
#define _OMC_LIT156 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT156)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT157,1,7) {&DAE_Dimension_DIM__UNKNOWN__desc,}};
#define _OMC_LIT157 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT157)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT158,2,1) {_OMC_LIT157,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT158 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT158)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT159,3,9) {&DAE_Type_T__ARRAY__desc,_OMC_LIT149,_OMC_LIT158}};
#define _OMC_LIT159 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT159)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT160,6,3) {&DAE_FuncArg_FUNCARG__desc,_OMC_LIT156,_OMC_LIT159,_OMC_LIT88,_OMC_LIT89,MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT160 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT160)
#define _OMC_LIT161_data "nodes"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT161,5,_OMC_LIT161_data);
#define _OMC_LIT161 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT161)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT162,6,3) {&DAE_FuncArg_FUNCARG__desc,_OMC_LIT161,_OMC_LIT159,_OMC_LIT88,_OMC_LIT89,MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT162 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT162)
#define _OMC_LIT163_data "message"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT163,7,_OMC_LIT163_data);
#define _OMC_LIT163 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT163)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT164,6,3) {&DAE_FuncArg_FUNCARG__desc,_OMC_LIT163,_OMC_LIT144,_OMC_LIT88,_OMC_LIT89,MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT164 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT164)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT165,2,1) {_OMC_LIT164,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT165 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT165)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT166,2,1) {_OMC_LIT162,_OMC_LIT165}};
#define _OMC_LIT166 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT166)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT167,2,1) {_OMC_LIT160,_OMC_LIT166}};
#define _OMC_LIT167 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT167)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT168,3,9) {&DAE_Type_T__ARRAY__desc,_OMC_LIT15,_OMC_LIT158}};
#define _OMC_LIT168 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT168)
#define _OMC_LIT169_data "Connections"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT169,11,_OMC_LIT169_data);
#define _OMC_LIT169 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT169)
#define _OMC_LIT170_data "isRoot"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT170,6,_OMC_LIT170_data);
#define _OMC_LIT170 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT170)
#define _OMC_LIT171_data "uniqueRootIndices"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT171,17,_OMC_LIT171_data);
#define _OMC_LIT171 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT171)
#include "util/modelica.h"
#include "Lookup_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_prefixSplicedExp(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inSplicedExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_prefixSplicedExp,2,0) {(void*) boxptr_Lookup_prefixSplicedExp,0}};
#define boxvar_Lookup_prefixSplicedExp MMC_REFSTRUCTLIT(boxvar_lit_Lookup_prefixSplicedExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_sliceDimensionType(threadData_t *threadData, modelica_metatype _inTypeD, modelica_metatype _inTypeL);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_sliceDimensionType,2,0) {(void*) boxptr_Lookup_sliceDimensionType,0}};
#define boxvar_Lookup_sliceDimensionType MMC_REFSTRUCTLIT(boxvar_lit_Lookup_sliceDimensionType)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_expandWholeDimSubScript(threadData_t *threadData, modelica_metatype _inSubs, modelica_metatype _inSlice);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_expandWholeDimSubScript,2,0) {(void*) boxptr_Lookup_expandWholeDimSubScript,0}};
#define boxvar_Lookup_expandWholeDimSubScript MMC_REFSTRUCTLIT(boxvar_lit_Lookup_expandWholeDimSubScript)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_makeEnumLiteralIndices(threadData_t *threadData, modelica_metatype _enumTypeName, modelica_metatype _enumLiterals, modelica_integer _enumIndex);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Lookup_makeEnumLiteralIndices(threadData_t *threadData, modelica_metatype _enumTypeName, modelica_metatype _enumLiterals, modelica_metatype _enumIndex);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_makeEnumLiteralIndices,2,0) {(void*) boxptr_Lookup_makeEnumLiteralIndices,0}};
#define boxvar_Lookup_makeEnumLiteralIndices MMC_REFSTRUCTLIT(boxvar_lit_Lookup_makeEnumLiteralIndices)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_makeDimensionSubscript(threadData_t *threadData, modelica_metatype _inDim);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_makeDimensionSubscript,2,0) {(void*) boxptr_Lookup_makeDimensionSubscript,0}};
#define boxvar_Lookup_makeDimensionSubscript MMC_REFSTRUCTLIT(boxvar_lit_Lookup_makeDimensionSubscript)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_addArrayDimensions(threadData_t *threadData, modelica_metatype _tySub, modelica_metatype _ss);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_addArrayDimensions,2,0) {(void*) boxptr_Lookup_addArrayDimensions,0}};
#define boxvar_Lookup_addArrayDimensions MMC_REFSTRUCTLIT(boxvar_lit_Lookup_addArrayDimensions)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_elabComponentRecursive(threadData_t *threadData, modelica_metatype _oCref);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_elabComponentRecursive,2,0) {(void*) boxptr_Lookup_elabComponentRecursive,0}};
#define boxvar_Lookup_elabComponentRecursive MMC_REFSTRUCTLIT(boxvar_lit_Lookup_elabComponentRecursive)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupBinding(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inParentType, modelica_metatype _inChildType, modelica_metatype _inParentBinding, modelica_metatype _inChildBinding);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupBinding,2,0) {(void*) boxptr_Lookup_lookupBinding,0}};
#define boxvar_Lookup_lookupBinding MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupBinding)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupVarFMetaModelica(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _cr, modelica_metatype _inType, modelica_metatype *out_attr, modelica_metatype *out_ty, modelica_metatype *out_binding, modelica_metatype *out_cnstForRange, modelica_string *out_name);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupVarFMetaModelica,2,0) {(void*) boxptr_Lookup_lookupVarFMetaModelica,0}};
#define boxvar_Lookup_lookupVarFMetaModelica MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupVarFMetaModelica)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupVarFIdent(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcache, modelica_metatype _ht, modelica_string _ident, modelica_metatype _ss, modelica_metatype _inEnv, modelica_metatype *out_attr, modelica_metatype *out_ty_1, modelica_metatype *out_bind, modelica_metatype *out_cnstForRange, modelica_metatype *out_splicedExpData, modelica_metatype *out_componentEnv, modelica_string *out_name);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupVarFIdent,2,0) {(void*) boxptr_Lookup_lookupVarFIdent,0}};
#define boxvar_Lookup_lookupVarFIdent MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupVarFIdent)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupVarF(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inBinTree, modelica_metatype _inComponentRef, modelica_metatype _inEnv, modelica_metatype *out_outAttributes, modelica_metatype *out_outType, modelica_metatype *out_outBinding, modelica_metatype *out_constOfForIteratorRange, modelica_metatype *out_splicedExpData, modelica_metatype *out_outComponentEnv, modelica_string *out_name);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupVarF,2,0) {(void*) boxptr_Lookup_lookupVarF,0}};
#define boxvar_Lookup_lookupVarF MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupVarF)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_checkSubscripts(threadData_t *threadData, modelica_metatype _inType, modelica_metatype _inExpSubscriptLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_checkSubscripts,2,0) {(void*) boxptr_Lookup_checkSubscripts,0}};
#define boxvar_Lookup_checkSubscripts MMC_REFSTRUCTLIT(boxvar_lit_Lookup_checkSubscripts)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupVar2(threadData_t *threadData, modelica_metatype _inBinTree, modelica_string _inIdent, modelica_metatype _inGraph, modelica_metatype *out_outElement, modelica_metatype *out_outMod, modelica_metatype *out_instStatus, modelica_metatype *out_outEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupVar2,2,0) {(void*) boxptr_Lookup_lookupVar2,0}};
#define boxvar_Lookup_lookupVar2 MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupVar2)
PROTECTED_FUNCTION_STATIC void omc_Lookup_reportSeveralNamesError(threadData_t *threadData, modelica_boolean _unique, modelica_string _name);
PROTECTED_FUNCTION_STATIC void boxptr_Lookup_reportSeveralNamesError(threadData_t *threadData, modelica_metatype _unique, modelica_metatype _name);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_reportSeveralNamesError,2,0) {(void*) boxptr_Lookup_reportSeveralNamesError,0}};
#define boxvar_Lookup_reportSeveralNamesError MMC_REFSTRUCTLIT(boxvar_lit_Lookup_reportSeveralNamesError)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupClassInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inFrame, modelica_metatype _inEnv, modelica_string _inIdent, modelica_metatype _inPrevFrames, modelica_metatype _inState, modelica_metatype _inInfo, modelica_metatype *out_outClass, modelica_metatype *out_outEnv, modelica_metatype *out_outPrevFrames);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupClassInFrame,2,0) {(void*) boxptr_Lookup_lookupClassInFrame,0}};
#define boxvar_Lookup_lookupClassInFrame MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupClassInFrame)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupClassInEnv(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_string _id, modelica_metatype _inPrevFrames, modelica_metatype _inState, modelica_metatype _inInfo, modelica_metatype *out_outClass, modelica_metatype *out_outEnv, modelica_metatype *out_outPrevFrames);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupClassInEnv,2,0) {(void*) boxptr_Lookup_lookupClassInEnv,0}};
#define boxvar_Lookup_lookupClassInEnv MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupClassInEnv)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_buildRecordConstructorResultElt(threadData_t *threadData, modelica_metatype _elts, modelica_string _id, modelica_metatype _env, modelica_metatype _info);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_buildRecordConstructorResultElt,2,0) {(void*) boxptr_Lookup_buildRecordConstructorResultElt,0}};
#define boxvar_Lookup_buildRecordConstructorResultElt MMC_REFSTRUCTLIT(boxvar_lit_Lookup_buildRecordConstructorResultElt)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_buildRecordConstructorElts(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inSCodeElementLst, modelica_metatype _mods, modelica_metatype *out_outEnv, modelica_metatype *out_outSCodeElementLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_buildRecordConstructorElts,2,0) {(void*) boxptr_Lookup_buildRecordConstructorElts,0}};
#define boxvar_Lookup_buildRecordConstructorElts MMC_REFSTRUCTLIT(boxvar_lit_Lookup_buildRecordConstructorElts)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_selectModifier(threadData_t *threadData, modelica_metatype _inModID, modelica_metatype _inModNoID);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_selectModifier,2,0) {(void*) boxptr_Lookup_selectModifier,0}};
#define boxvar_Lookup_selectModifier MMC_REFSTRUCTLIT(boxvar_lit_Lookup_selectModifier)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_buildRecordConstructorClass2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _cl, modelica_metatype _mods, modelica_metatype *out_outEnv, modelica_metatype *out_funcelts, modelica_metatype *out_elts);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_buildRecordConstructorClass2,2,0) {(void*) boxptr_Lookup_buildRecordConstructorClass2,0}};
#define boxvar_Lookup_buildRecordConstructorClass2 MMC_REFSTRUCTLIT(boxvar_lit_Lookup_buildRecordConstructorClass2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_buildRecordConstructorClass(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inClass, modelica_metatype *out_outEnv, modelica_metatype *out_outClass);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_buildRecordConstructorClass,2,0) {(void*) boxptr_Lookup_buildRecordConstructorClass,0}};
#define boxvar_Lookup_buildRecordConstructorClass MMC_REFSTRUCTLIT(boxvar_lit_Lookup_buildRecordConstructorClass)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_buildRecordType(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _icdef, modelica_metatype *out_outEnv, modelica_metatype *out_ftype);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_buildRecordType,2,0) {(void*) boxptr_Lookup_buildRecordType,0}};
#define boxvar_Lookup_buildRecordType MMC_REFSTRUCTLIT(boxvar_lit_Lookup_buildRecordType)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupFunctionsInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inClasses, modelica_metatype _inFuncTypes, modelica_metatype _inEnv, modelica_string _inFuncName, modelica_metatype _inInfo, modelica_metatype *out_outFuncTypes);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupFunctionsInFrame,2,0) {(void*) boxptr_Lookup_lookupFunctionsInFrame,0}};
#define boxvar_Lookup_lookupFunctionsInFrame MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupFunctionsInFrame)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupTypeInFrame2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _item, modelica_metatype _inEnv3, modelica_string _inIdent4, modelica_metatype *out_outType, modelica_metatype *out_outEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupTypeInFrame2,2,0) {(void*) boxptr_Lookup_lookupTypeInFrame2,0}};
#define boxvar_Lookup_lookupTypeInFrame2 MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupTypeInFrame2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupTypeInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inBinTree1, modelica_metatype _inBinTree2, modelica_metatype _inEnv3, modelica_string _inIdent4, modelica_metatype *out_outType, modelica_metatype *out_outEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupTypeInFrame,2,0) {(void*) boxptr_Lookup_lookupTypeInFrame,0}};
#define boxvar_Lookup_lookupTypeInFrame MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupTypeInFrame)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_getHtTypes(threadData_t *threadData, modelica_metatype _inParentRef);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_getHtTypes,2,0) {(void*) boxptr_Lookup_getHtTypes,0}};
#define boxvar_Lookup_getHtTypes MMC_REFSTRUCTLIT(boxvar_lit_Lookup_getHtTypes)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupTypeInEnv(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_string _id, modelica_metatype *out_outType, modelica_metatype *out_outEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupTypeInEnv,2,0) {(void*) boxptr_Lookup_lookupTypeInEnv,0}};
#define boxvar_Lookup_lookupTypeInEnv MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupTypeInEnv)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_createGenericBuiltinFunctions(threadData_t *threadData, modelica_metatype _inEnv, modelica_string _inString);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_createGenericBuiltinFunctions,2,0) {(void*) boxptr_Lookup_createGenericBuiltinFunctions,0}};
#define boxvar_Lookup_createGenericBuiltinFunctions MMC_REFSTRUCTLIT(boxvar_lit_Lookup_createGenericBuiltinFunctions)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupFunctionsInEnv2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inPath, modelica_boolean _followedQual, modelica_metatype _info, modelica_metatype *out_outTypesTypeLst);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Lookup_lookupFunctionsInEnv2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inPath, modelica_metatype _followedQual, modelica_metatype _info, modelica_metatype *out_outTypesTypeLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupFunctionsInEnv2,2,0) {(void*) boxptr_Lookup_lookupFunctionsInEnv2,0}};
#define boxvar_Lookup_lookupFunctionsInEnv2 MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupFunctionsInEnv2)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_Lookup_frameIsImplAddedScope(threadData_t *threadData, modelica_metatype _f);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Lookup_frameIsImplAddedScope(threadData_t *threadData, modelica_metatype _f);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_frameIsImplAddedScope,2,0) {(void*) boxptr_Lookup_frameIsImplAddedScope,0}};
#define boxvar_Lookup_frameIsImplAddedScope MMC_REFSTRUCTLIT(boxvar_lit_Lookup_frameIsImplAddedScope)
PROTECTED_FUNCTION_STATIC void omc_Lookup_checkPackageVariableConstant(threadData_t *threadData, modelica_metatype _parentEnv, modelica_metatype _classEnv, modelica_metatype _componentEnv, modelica_metatype _attr, modelica_metatype _tp, modelica_metatype _cref);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_checkPackageVariableConstant,2,0) {(void*) boxptr_Lookup_checkPackageVariableConstant,0}};
#define boxvar_Lookup_checkPackageVariableConstant MMC_REFSTRUCTLIT(boxvar_lit_Lookup_checkPackageVariableConstant)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupConnectorVar2(threadData_t *threadData, modelica_metatype _env, modelica_string _name, modelica_metatype *out_status, modelica_metatype *out_compEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupConnectorVar2,2,0) {(void*) boxptr_Lookup_lookupConnectorVar2,0}};
#define boxvar_Lookup_lookupConnectorVar2 MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupConnectorVar2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupUnqualifiedImportedClassInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inImports, modelica_metatype _inEnv, modelica_string _inIdent, modelica_metatype _inInfo, modelica_metatype *out_outClass, modelica_metatype *out_outEnv, modelica_metatype *out_outPrevFrames, modelica_boolean *out_outBoolean);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Lookup_lookupUnqualifiedImportedClassInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inImports, modelica_metatype _inEnv, modelica_metatype _inIdent, modelica_metatype _inInfo, modelica_metatype *out_outClass, modelica_metatype *out_outEnv, modelica_metatype *out_outPrevFrames, modelica_metatype *out_outBoolean);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupUnqualifiedImportedClassInFrame,2,0) {(void*) boxptr_Lookup_lookupUnqualifiedImportedClassInFrame,0}};
#define boxvar_Lookup_lookupUnqualifiedImportedClassInFrame MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupUnqualifiedImportedClassInFrame)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_moreLookupUnqualifiedImportedClassInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inImports, modelica_metatype _inEnv, modelica_string _inIdent, modelica_boolean *out_outBoolean);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Lookup_moreLookupUnqualifiedImportedClassInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inImports, modelica_metatype _inEnv, modelica_metatype _inIdent, modelica_metatype *out_outBoolean);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_moreLookupUnqualifiedImportedClassInFrame,2,0) {(void*) boxptr_Lookup_moreLookupUnqualifiedImportedClassInFrame,0}};
#define boxvar_Lookup_moreLookupUnqualifiedImportedClassInFrame MMC_REFSTRUCTLIT(boxvar_lit_Lookup_moreLookupUnqualifiedImportedClassInFrame)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupQualifiedImportedClassInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inImport, modelica_metatype _inEnv, modelica_string _inIdent, modelica_metatype _inState, modelica_metatype _inInfo, modelica_metatype *out_outClass, modelica_metatype *out_outEnv, modelica_metatype *out_outPrevFrames);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupQualifiedImportedClassInFrame,2,0) {(void*) boxptr_Lookup_lookupQualifiedImportedClassInFrame,0}};
#define boxvar_Lookup_lookupQualifiedImportedClassInFrame MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupQualifiedImportedClassInFrame)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupUnqualifiedImportedVarInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inImports, modelica_metatype _inEnv, modelica_string _inIdent, modelica_metatype *out_outClassEnv, modelica_metatype *out_outAttributes, modelica_metatype *out_outType, modelica_metatype *out_outBinding, modelica_metatype *out_constOfForIteratorRange, modelica_boolean *out_outBoolean, modelica_metatype *out_splicedExpData, modelica_metatype *out_outComponentEnv, modelica_string *out_name);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Lookup_lookupUnqualifiedImportedVarInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inImports, modelica_metatype _inEnv, modelica_metatype _inIdent, modelica_metatype *out_outClassEnv, modelica_metatype *out_outAttributes, modelica_metatype *out_outType, modelica_metatype *out_outBinding, modelica_metatype *out_constOfForIteratorRange, modelica_metatype *out_outBoolean, modelica_metatype *out_splicedExpData, modelica_metatype *out_outComponentEnv, modelica_metatype *out_name);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupUnqualifiedImportedVarInFrame,2,0) {(void*) boxptr_Lookup_lookupUnqualifiedImportedVarInFrame,0}};
#define boxvar_Lookup_lookupUnqualifiedImportedVarInFrame MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupUnqualifiedImportedVarInFrame)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_moreLookupUnqualifiedImportedVarInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inImports, modelica_metatype _inEnv, modelica_string _inIdent, modelica_boolean *out_outBoolean);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Lookup_moreLookupUnqualifiedImportedVarInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inImports, modelica_metatype _inEnv, modelica_metatype _inIdent, modelica_metatype *out_outBoolean);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_moreLookupUnqualifiedImportedVarInFrame,2,0) {(void*) boxptr_Lookup_moreLookupUnqualifiedImportedVarInFrame,0}};
#define boxvar_Lookup_moreLookupUnqualifiedImportedVarInFrame MMC_REFSTRUCTLIT(boxvar_lit_Lookup_moreLookupUnqualifiedImportedVarInFrame)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupQualifiedImportedVarInFrame(threadData_t *threadData, modelica_metatype _inImports, modelica_string _ident);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupQualifiedImportedVarInFrame,2,0) {(void*) boxptr_Lookup_lookupQualifiedImportedVarInFrame,0}};
#define boxvar_Lookup_lookupQualifiedImportedVarInFrame MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupQualifiedImportedVarInFrame)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupPrevFrames(threadData_t *threadData, modelica_string _id, modelica_metatype _inPrevFrames, modelica_metatype *out_outPrevFrames);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupPrevFrames,2,0) {(void*) boxptr_Lookup_lookupPrevFrames,0}};
#define boxvar_Lookup_lookupPrevFrames MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupPrevFrames)
PROTECTED_FUNCTION_STATIC modelica_string omc_Lookup_getConstrainingClass(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inEnv, modelica_metatype _inCache);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_getConstrainingClass,2,0) {(void*) boxptr_Lookup_getConstrainingClass,0}};
#define boxvar_Lookup_getConstrainingClass MMC_REFSTRUCTLIT(boxvar_lit_Lookup_getConstrainingClass)
PROTECTED_FUNCTION_STATIC void omc_Lookup_checkPartialScope(threadData_t *threadData, modelica_metatype _inEnv, modelica_metatype _inParentEnv, modelica_metatype _inCache, modelica_metatype _inInfo);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_checkPartialScope,2,0) {(void*) boxptr_Lookup_checkPartialScope,0}};
#define boxvar_Lookup_checkPartialScope MMC_REFSTRUCTLIT(boxvar_lit_Lookup_checkPartialScope)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupClassQualified2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _path, modelica_metatype _inC, modelica_metatype _optFrame, modelica_metatype _inPrevFrames, modelica_metatype _inState, modelica_metatype _inInfo, modelica_metatype *out_outClass, modelica_metatype *out_outEnv, modelica_metatype *out_outPrevFrames);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupClassQualified2,2,0) {(void*) boxptr_Lookup_lookupClassQualified2,0}};
#define boxvar_Lookup_lookupClassQualified2 MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupClassQualified2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupClassQualified(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_string _id, modelica_metatype _path, modelica_metatype _inOptFrame, modelica_metatype _inPrevFrames, modelica_metatype _inState, modelica_metatype _inInfo, modelica_metatype *out_outClass, modelica_metatype *out_outEnv, modelica_metatype *out_outPrevFrames);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupClassQualified,2,0) {(void*) boxptr_Lookup_lookupClassQualified,0}};
#define boxvar_Lookup_lookupClassQualified MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupClassQualified)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupClass2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inPath, modelica_metatype _inPrevFrames, modelica_metatype _inState, modelica_metatype _inInfo, modelica_metatype *out_outClass, modelica_metatype *out_outEnv, modelica_metatype *out_outPrevFrames);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupClass2,2,0) {(void*) boxptr_Lookup_lookupClass2,0}};
#define boxvar_Lookup_lookupClass2 MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupClass2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupClass1(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inPath, modelica_metatype _inPrevFrames, modelica_metatype _inState, modelica_metatype _inInfo, modelica_metatype *out_outClass, modelica_metatype *out_outEnv, modelica_metatype *out_outPrevFrames);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupClass1,2,0) {(void*) boxptr_Lookup_lookupClass1,0}};
#define boxvar_Lookup_lookupClass1 MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupClass1)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupMetarecordsRecursive3(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _path, modelica_string _str, modelica_metatype _inHt, modelica_metatype _inAcc, modelica_metatype *out_outHt, modelica_metatype *out_outMetarecordTypes);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupMetarecordsRecursive3,2,0) {(void*) boxptr_Lookup_lookupMetarecordsRecursive3,0}};
#define boxvar_Lookup_lookupMetarecordsRecursive3 MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupMetarecordsRecursive3)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupMetarecordsRecursive2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inUniontypePaths, modelica_metatype _inHt, modelica_metatype _inAcc, modelica_metatype *out_outHt, modelica_metatype *out_outMetarecordTypes);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupMetarecordsRecursive2,2,0) {(void*) boxptr_Lookup_lookupMetarecordsRecursive2,0}};
#define boxvar_Lookup_lookupMetarecordsRecursive2 MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupMetarecordsRecursive2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupType2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inClass, modelica_metatype *out_outType, modelica_metatype *out_outEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupType2,2,0) {(void*) boxptr_Lookup_lookupType2,0}};
#define boxvar_Lookup_lookupType2 MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupType2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupTypeQual(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inPath, modelica_metatype _msg, modelica_metatype *out_outType, modelica_metatype *out_outEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Lookup_lookupTypeQual,2,0) {(void*) boxptr_Lookup_lookupTypeQual,0}};
#define boxvar_Lookup_lookupTypeQual MMC_REFSTRUCTLIT(boxvar_lit_Lookup_lookupTypeQual)
DLLExport
modelica_metatype omc_Lookup_isArrayType(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inPath, modelica_boolean *out_outIsArray)
{
modelica_metatype _outCache = NULL;
modelica_boolean _outIsArray;
modelica_metatype _el = NULL;
modelica_metatype _p = NULL;
modelica_metatype _env = NULL;
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
modelica_boolean tmp5 = 0;
_outCache = omc_Lookup_lookupClass(threadData, _inCache, _inEnv, _inPath, mmc_mk_none() ,&_el ,&_env);
{
modelica_metatype tmp8_1;
tmp8_1 = _el;
{
volatile mmc_switch_type tmp8;
int tmp9;
tmp8 = 0;
for (; tmp8 < 4; tmp8++) {
switch (MMC_SWITCH_CAST(tmp8)) {
case 0: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,2,8) == 0) goto tmp7_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,2,3) == 0) goto tmp7_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,0,2) == 0) goto tmp7_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 3));
if (optionNone(tmpMeta12)) goto tmp7_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 1));
tmp5 = 1;
goto tmp7_done;
}
case 1: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,2,8) == 0) goto tmp7_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,2,3) == 0) goto tmp7_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 4));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
if (listEmpty(tmpMeta16)) goto tmp7_end;
tmpMeta17 = MMC_CAR(tmpMeta16);
tmpMeta18 = MMC_CDR(tmpMeta16);
tmp5 = 1;
goto tmp7_done;
}
case 2: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,2,8) == 0) goto tmp7_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta19,2,3) == 0) goto tmp7_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,0,2) == 0) goto tmp7_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 2));
_p = tmpMeta21;
_outCache = omc_Lookup_isArrayType(threadData, _outCache, _env, _p ,&_outIsArray);
tmp5 = _outIsArray;
goto tmp7_done;
}
case 3: {
tmp5 = 0;
goto tmp7_done;
}
}
goto tmp7_end;
tmp7_end: ;
}
goto goto_6;
goto_6:;
goto goto_1;
goto tmp7_done;
tmp7_done:;
}
}
_outIsArray = tmp5;
goto tmp2_done;
}
case 1: {
_outIsArray = 0;
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
if (out_outIsArray) { *out_outIsArray = _outIsArray; }
return _outCache;
}
modelica_metatype boxptr_Lookup_isArrayType(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inPath, modelica_metatype *out_outIsArray)
{
modelica_boolean _outIsArray;
modelica_metatype _outCache = NULL;
_outCache = omc_Lookup_isArrayType(threadData, _inCache, _inEnv, _inPath, &_outIsArray);
if (out_outIsArray) { *out_outIsArray = mmc_mk_icon(_outIsArray); }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_prefixSplicedExp(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inSplicedExp)
{
modelica_metatype _outSplicedExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inSplicedExp;
{
modelica_metatype _ety = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _cref = NULL;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (optionNone(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,6,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_cref = tmpMeta8;
_ety = tmpMeta9;
_ty = tmpMeta10;
_cref = omc_ComponentReference_joinCrefs(threadData, _inCref, _cref);
tmpMeta11 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _cref, _ety);
tmpMeta12 = mmc_mk_box3(3, &InstTypes_SplicedExpData_SPLICEDEXPDATA__desc, mmc_mk_some(tmpMeta11), _ty);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _inSplicedExp;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outSplicedExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outSplicedExp;
}
DLLExport
modelica_boolean omc_Lookup_isFunctionCallViaComponent(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inPath)
{
modelica_boolean _yes;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inPath;
{
modelica_string _name = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_name = tmpMeta6;
omc_ErrorExt_setCheckpoint(threadData, _OMC_LIT0);
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
omc_Lookup_lookupVarIdent(threadData, _inCache, _inEnv, _name, tmpMeta7, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
omc_ErrorExt_rollBack(threadData, _OMC_LIT0);
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
omc_ErrorExt_rollBack(threadData, _OMC_LIT0);
goto goto_2;
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
_yes = tmp1;
_return: OMC_LABEL_UNUSED
return _yes;
}
modelica_metatype boxptr_Lookup_isFunctionCallViaComponent(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inPath)
{
modelica_boolean _yes;
modelica_metatype out_yes;
_yes = omc_Lookup_isFunctionCallViaComponent(threadData, _inCache, _inEnv, _inPath);
out_yes = mmc_mk_icon(_yes);
return out_yes;
}
DLLExport
modelica_metatype omc_Lookup_isIterator(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inCref, modelica_metatype *out_outCache)
{
modelica_metatype _outIsIterator = NULL;
modelica_metatype _outCache = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
{
modelica_string _id = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _ht = NULL;
modelica_metatype _ic = NULL;
modelica_metatype _ref = NULL;
modelica_boolean _b;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
_ref = tmpMeta7;
_cache = tmp4_1;
_ht = omc_FNode_children(threadData, omc_FNode_fromRef(threadData, _ref));
_id = omc_ComponentReference_crefFirstIdent(threadData, _inCref);
tmpMeta9 = omc_Lookup_lookupVar2(threadData, _ht, _id, _inEnv, NULL, NULL, NULL, NULL);
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 7));
_ic = tmpMeta10;
_b = isSome(_ic);
tmpMeta[0+0] = mmc_mk_some(mmc_mk_boolean(_b));
tmpMeta[0+1] = _cache;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_boolean tmp14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta11)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmpMeta11);
tmpMeta13 = MMC_CDR(tmpMeta11);
_ref = tmpMeta12;
_cache = tmp4_1;
tmp14 = omc_Lookup_frameIsImplAddedScope(threadData, omc_FNode_fromRef(threadData, _ref));
if (1 != tmp14) goto goto_2;
_env = omc_FGraph_stripLastScopeRef(threadData, _inEnv, NULL);
tmpMeta[0+0] = omc_Lookup_isIterator(threadData, _cache, _env, _inCref, &tmpMeta[0+1]);
goto tmp3_done;
}
case 2: {
tmpMeta[0+0] = mmc_mk_none();
tmpMeta[0+1] = _inCache;
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
_outIsIterator = tmpMeta[0+0];
_outCache = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outCache) { *out_outCache = _outCache; }
return _outIsIterator;
}
DLLExport
modelica_metatype omc_Lookup_buildMetaRecordType(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _cdef, modelica_metatype *out_outEnv, modelica_metatype *out_ftype)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _ftype = NULL;
modelica_string _id = NULL;
modelica_metatype _env_1 = NULL;
modelica_metatype _env = NULL;
modelica_metatype _utPath = NULL;
modelica_metatype _path = NULL;
modelica_integer _index;
modelica_metatype _varlst = NULL;
modelica_metatype _els = NULL;
modelica_boolean _singleton;
modelica_metatype _cache = NULL;
modelica_metatype _typeVarsType = NULL;
modelica_metatype _typeVars = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_integer tmp6;
modelica_metatype tmpMeta7;
modelica_integer tmp8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta20;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _cdef;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,2,8) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta3,17,5) == 0) MMC_THROW_INTERNAL();
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 2));
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 3));
tmp6 = mmc_unbox_integer(tmpMeta5);
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 4));
tmp8 = mmc_unbox_integer(tmpMeta7);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 6));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,0,8) == 0) MMC_THROW_INTERNAL();
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_id = tmpMeta2;
_utPath = tmpMeta4;
_index = tmp6;
_singleton = tmp8;
_typeVars = tmpMeta9;
_els = tmpMeta11;
_env = omc_FGraph_openScope(threadData, _inEnv, _OMC_LIT1, _id, _OMC_LIT3);
_cache = omc_Inst_makeFullyQualified(threadData, _inCache, _env, _utPath ,&_utPath);
tmpMeta12 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _id);
_path = omc_AbsynUtil_joinPaths(threadData, _utPath, tmpMeta12);
tmpMeta13 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta14 = MMC_REFSTRUCTLIT(mmc_nil);
_outCache = omc_Inst_instElementList(threadData, _cache, _env, tmpMeta13, _OMC_LIT4, _OMC_LIT5, _OMC_LIT6, _OMC_LIT9, omc_List_map1(threadData, _els, boxvar_Util_makeTuple, _OMC_LIT5), tmpMeta14, 0, _OMC_LIT10, _OMC_LIT11, _OMC_LIT14, 1 ,&_outEnv ,NULL ,NULL ,NULL ,NULL ,NULL ,&_varlst ,NULL ,NULL);
_varlst = omc_Types_boxVarLst(threadData, _varlst);
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype __omcQ_24tmpVar0;
modelica_integer tmp19;
modelica_metatype _tv_loopVar = 0;
modelica_metatype _tv;
_tv_loopVar = _typeVars;
tmpMeta17 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta17;
tmp16 = &__omcQ_24tmpVar1;
while(1) {
tmp19 = 1;
if (!listEmpty(_tv_loopVar)) {
_tv = MMC_CAR(_tv_loopVar);
_tv_loopVar = MMC_CDR(_tv_loopVar);
tmp19--;
}
if (tmp19 == 0) {
tmpMeta18 = mmc_mk_box2(27, &DAE_Type_T__METAPOLYMORPHIC__desc, _tv);
__omcQ_24tmpVar0 = tmpMeta18;
*tmp16 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp16 = &MMC_CDR(*tmp16);
} else if (tmp19 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp16 = mmc_mk_nil();
tmpMeta15 = __omcQ_24tmpVar1;
}
_typeVarsType = tmpMeta15;
tmpMeta20 = mmc_mk_box7(24, &DAE_Type_T__METARECORD__desc, _path, _utPath, _typeVarsType, mmc_mk_integer(_index), _varlst, mmc_mk_boolean(_singleton));
_ftype = tmpMeta20;
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_ftype) { *out_ftype = _ftype; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_sliceDimensionType(threadData_t *threadData, modelica_metatype _inTypeD, modelica_metatype _inTypeL)
{
modelica_metatype _outType = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inTypeD;
tmp4_2 = _inTypeL;
{
modelica_metatype _t = NULL;
modelica_metatype _tOrg = NULL;
modelica_metatype _dimensions = NULL;
modelica_metatype _dim2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_t = tmp4_1;
_tOrg = tmp4_2;
_dimensions = omc_Types_getDimensionSizes(threadData, _t);
_dim2 = omc_List_map(threadData, _dimensions, boxvar_Expression_intDimension);
_dim2 = listReverse(_dim2);
tmpMeta1 = omc_List_foldr(threadData, _dim2, boxvar_Types_liftArray, _tOrg);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outType = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outType;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_expandWholeDimSubScript(threadData_t *threadData, modelica_metatype _inSubs, modelica_metatype _inSlice)
{
modelica_metatype _outSubs = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inSubs;
tmp4_2 = _inSlice;
{
modelica_metatype _sub1 = NULL;
modelica_metatype _sub2 = NULL;
modelica_metatype _subs1 = NULL;
modelica_metatype _subs2 = NULL;
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
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,2,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,6,2) == 0) goto tmp3_end;
_sub1 = tmpMeta6;
_subs1 = tmpMeta7;
_subs2 = tmp4_2;
_subs2 = omc_Lookup_expandWholeDimSubScript(threadData, _subs1, _subs2);
tmpMeta9 = mmc_mk_cons(_sub1, _subs2);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 2: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_subs2 = tmp4_2;
tmp4 += 2;
tmpMeta1 = _subs2;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta11 = MMC_CAR(tmp4_2);
tmpMeta12 = MMC_CDR(tmp4_2);
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta13 = MMC_CAR(tmp4_1);
tmpMeta14 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,0,0) == 0) goto tmp3_end;
_sub2 = tmpMeta11;
_subs2 = tmpMeta12;
_subs1 = tmpMeta14;
_subs2 = omc_Lookup_expandWholeDimSubScript(threadData, _subs1, _subs2);
tmpMeta15 = mmc_mk_cons(_sub2, _subs2);
tmpMeta1 = tmpMeta15;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmp4_1);
tmpMeta17 = MMC_CDR(tmp4_1);
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta18 = MMC_CAR(tmp4_2);
tmpMeta19 = MMC_CDR(tmp4_2);
_sub1 = tmpMeta16;
_subs1 = tmpMeta17;
_subs2 = tmpMeta19;
_subs2 = omc_Lookup_expandWholeDimSubScript(threadData, _subs1, _subs2);
tmpMeta20 = mmc_mk_cons(_sub1, _subs2);
tmpMeta1 = tmpMeta20;
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
_outSubs = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outSubs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_makeEnumLiteralIndices(threadData_t *threadData, modelica_metatype _enumTypeName, modelica_metatype _enumLiterals, modelica_integer _enumIndex)
{
modelica_metatype _enumIndices = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _enumLiterals;
{
modelica_string _l = NULL;
modelica_metatype _ls = NULL;
modelica_metatype _e = NULL;
modelica_metatype _expl = NULL;
modelica_metatype _enum_type_name = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
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
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
_l = tmpMeta7;
_ls = tmpMeta8;
tmpMeta9 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _l);
_enum_type_name = omc_AbsynUtil_joinPaths(threadData, _enumTypeName, tmpMeta9);
tmpMeta10 = mmc_mk_box3(8, &DAE_Exp_ENUM__LITERAL__desc, _enum_type_name, mmc_mk_integer(_enumIndex));
_e = tmpMeta10;
_expl = omc_Lookup_makeEnumLiteralIndices(threadData, _enumTypeName, _ls, ((modelica_integer) 1) + _enumIndex);
tmpMeta11 = mmc_mk_cons(_e, _expl);
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
_enumIndices = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _enumIndices;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Lookup_makeEnumLiteralIndices(threadData_t *threadData, modelica_metatype _enumTypeName, modelica_metatype _enumLiterals, modelica_metatype _enumIndex)
{
modelica_integer tmp1;
modelica_metatype _enumIndices = NULL;
tmp1 = mmc_unbox_integer(_enumIndex);
_enumIndices = omc_Lookup_makeEnumLiteralIndices(threadData, _enumTypeName, _enumLiterals, tmp1);
return _enumIndices;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_makeDimensionSubscript(threadData_t *threadData, modelica_metatype _inDim)
{
modelica_metatype _outSub = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inDim;
{
modelica_metatype _expl = NULL;
modelica_metatype _enum_name = NULL;
modelica_metatype _l = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
if (0 != tmp7) goto tmp3_end;
tmpMeta1 = _OMC_LIT19;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta9 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inDim), 2))));
tmpMeta8 = mmc_mk_cons(tmpMeta9, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta10 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT15, tmpMeta8);
tmpMeta11 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inDim), 2))));
tmpMeta12 = mmc_mk_box5(21, &DAE_Exp_RANGE__desc, tmpMeta10, _OMC_LIT20, mmc_mk_none(), tmpMeta11);
tmpMeta13 = mmc_mk_box2(4, &DAE_Subscript_SLICE__desc, tmpMeta12);
tmpMeta1 = tmpMeta13;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
_expl = _OMC_LIT24;
tmpMeta14 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _OMC_LIT25, mmc_mk_boolean(1), _expl);
tmpMeta15 = mmc_mk_box2(4, &DAE_Subscript_SLICE__desc, tmpMeta14);
tmpMeta1 = tmpMeta15;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,3) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_enum_name = tmpMeta16;
_l = tmpMeta17;
_expl = omc_Lookup_makeEnumLiteralIndices(threadData, _enum_name, _l, ((modelica_integer) 1));
tmpMeta18 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta19 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta20 = mmc_mk_box6(8, &DAE_Type_T__ENUMERATION__desc, mmc_mk_none(), _enum_name, _l, tmpMeta18, tmpMeta19);
tmpMeta21 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, tmpMeta20, mmc_mk_boolean(1), _expl);
tmpMeta22 = mmc_mk_box2(4, &DAE_Subscript_SLICE__desc, tmpMeta21);
tmpMeta1 = tmpMeta22;
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_addArrayDimensions(threadData_t *threadData, modelica_metatype _tySub, modelica_metatype _ss)
{
modelica_metatype _outType = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _subs = NULL;
modelica_metatype _dims = NULL;
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
tmp6 = omc_Types_isArray(threadData, _tySub);
if (1 != tmp6) goto goto_2;
_dims = omc_Types_getDimensions(threadData, _tySub);
_subs = omc_List_map(threadData, _dims, boxvar_Lookup_makeDimensionSubscript);
tmpMeta1 = omc_Lookup_expandWholeDimSubScript(threadData, _ss, _subs);
goto tmp3_done;
}
case 1: {
tmpMeta1 = _ss;
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
_outType = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outType;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_elabComponentRecursive(threadData_t *threadData, modelica_metatype _oCref)
{
modelica_metatype _lref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _oCref;
{
modelica_metatype _ecpr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,6,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,3) == 0) goto tmp3_end;
_ecpr = tmpMeta7;
tmpMeta8 = mmc_mk_cons(_ecpr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,6,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,0,4) == 0) goto tmp3_end;
_ecpr = tmpMeta10;
tmpMeta11 = mmc_mk_cons(_ecpr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 2: {
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
_lref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _lref;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupBinding(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inParentType, modelica_metatype _inChildType, modelica_metatype _inParentBinding, modelica_metatype _inChildBinding)
{
modelica_metatype _outBinding = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inCref;
tmp4_2 = _inParentBinding;
{
modelica_metatype _tyElement = NULL;
modelica_metatype _e = NULL;
modelica_metatype _v = NULL;
modelica_metatype _c = NULL;
modelica_metatype _s = NULL;
modelica_metatype _ss = NULL;
modelica_string _cId = NULL;
modelica_metatype _exps = NULL;
modelica_metatype _comp = NULL;
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
modelica_boolean tmp13;
modelica_boolean tmp14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,1,3) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 4));
if (!listEmpty(tmpMeta12)) goto tmp3_end;
_e = tmpMeta6;
_c = tmpMeta7;
_s = tmpMeta8;
_ss = tmpMeta9;
_cId = tmpMeta11;
tmp4 += 1;
tmp13 = omc_Types_isArray(threadData, _inParentType);
if (1 != tmp13) goto goto_2;
_tyElement = omc_Types_arrayElementType(threadData, _inParentType);
tmp14 = omc_Types_isRecord(threadData, _tyElement);
if (1 != tmp14) goto goto_2;
tmpMeta15 = omc_Expression_applyExpSubscripts(threadData, _e, _ss);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,14,4) == 0) goto goto_2;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 3));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 4));
_exps = tmpMeta16;
_comp = tmpMeta17;
_e = listGet(_exps, omc_List_position(threadData, _cId, _comp));
tmpMeta18 = mmc_mk_box5(4, &DAE_Binding_EQBOUND__desc, _e, mmc_mk_none(), _c, _s);
tmpMeta1 = tmpMeta18;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_boolean tmp25;
modelica_boolean tmp26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,2) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta22,1,3) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 2));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 4));
if (!listEmpty(tmpMeta24)) goto tmp3_end;
_v = tmpMeta19;
_s = tmpMeta20;
_ss = tmpMeta21;
_cId = tmpMeta23;
tmp25 = omc_Types_isArray(threadData, _inParentType);
if (1 != tmp25) goto goto_2;
_tyElement = omc_Types_arrayElementType(threadData, _inParentType);
tmp26 = omc_Types_isRecord(threadData, _tyElement);
if (1 != tmp26) goto goto_2;
_e = omc_ValuesUtil_valueExp(threadData, _v, mmc_mk_none());
tmpMeta27 = omc_Expression_applyExpSubscripts(threadData, _e, _ss);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta27,14,4) == 0) goto goto_2;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 3));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 4));
_exps = tmpMeta28;
_comp = tmpMeta29;
_e = listGet(_exps, omc_List_position(threadData, _cId, _comp));
tmpMeta30 = mmc_mk_box5(4, &DAE_Binding_EQBOUND__desc, _e, mmc_mk_none(), _OMC_LIT26, _s);
tmpMeta1 = tmpMeta30;
goto tmp3_done;
}
case 2: {
tmpMeta1 = _inChildBinding;
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
_outBinding = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outBinding;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupVarFMetaModelica(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _cr, modelica_metatype _inType, modelica_metatype *out_attr, modelica_metatype *out_ty, modelica_metatype *out_binding, modelica_metatype *out_cnstForRange, modelica_string *out_name)
{
modelica_metatype _cache = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _binding = NULL;
modelica_metatype _cnstForRange = NULL;
modelica_string _name = NULL;
modelica_string tmp1_c4 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cache = _inCache;
{
modelica_metatype tmp4_1;
tmp4_1 = _cr;
{
modelica_metatype _fields = NULL;
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
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
_fields = omc_Types_getMetaRecordFields(threadData, _inType);
tmpMeta6 = listGet(_fields, ((modelica_integer) 1) + omc_Types_findVarIndex(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr), 2))), _fields));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 7));
_name = tmpMeta7;
_attr = tmpMeta8;
_ty = tmpMeta9;
_binding = tmpMeta10;
_cnstForRange = tmpMeta11;
{
modelica_metatype _s;
for (tmpMeta12 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr), 4))); !listEmpty(tmpMeta12); tmpMeta12=MMC_CDR(tmpMeta12))
{
_s = MMC_CAR(tmpMeta12);
{
modelica_metatype tmp16_1;
tmp16_1 = _ty;
{
volatile mmc_switch_type tmp16;
int tmp17;
tmp16 = 0;
for (; tmp16 < 1; tmp16++) {
switch (MMC_SWITCH_CAST(tmp16)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp16_1,22,1) == 0) goto tmp15_end;
tmpMeta13 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ty), 2)));
goto tmp15_done;
}
}
goto tmp15_end;
tmp15_end: ;
}
goto goto_14;
goto_14:;
goto goto_2;
goto tmp15_done;
tmp15_done:;
}
}
_ty = tmpMeta13;
}
}
_ty = omc_Types_getMetaRecordIfSingleton(threadData, _ty);
tmpMeta[0+0] = _attr;
tmpMeta[0+1] = _ty;
tmpMeta[0+2] = _binding;
tmpMeta[0+3] = _cnstForRange;
tmp1_c4 = _name;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta31;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
_fields = omc_Types_getMetaRecordFields(threadData, _inType);
tmpMeta19 = listGet(_fields, ((modelica_integer) 1) + omc_Types_findVarIndex(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr), 2))), _fields));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 2));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 3));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 4));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 5));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 7));
_name = tmpMeta20;
_attr = tmpMeta21;
_ty = tmpMeta22;
_binding = tmpMeta23;
_cnstForRange = tmpMeta24;
{
modelica_metatype _s;
for (tmpMeta25 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr), 4))); !listEmpty(tmpMeta25); tmpMeta25=MMC_CDR(tmpMeta25))
{
_s = MMC_CAR(tmpMeta25);
{
modelica_metatype tmp29_1;
tmp29_1 = _ty;
{
volatile mmc_switch_type tmp29;
int tmp30;
tmp29 = 0;
for (; tmp29 < 1; tmp29++) {
switch (MMC_SWITCH_CAST(tmp29)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp29_1,22,1) == 0) goto tmp28_end;
tmpMeta26 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ty), 2)));
goto tmp28_done;
}
}
goto tmp28_end;
tmp28_end: ;
}
goto goto_27;
goto_27:;
goto goto_2;
goto tmp28_done;
tmp28_done:;
}
}
_ty = tmpMeta26;
}
}
_ty = omc_Types_getMetaRecordIfSingleton(threadData, _ty);
_cache = omc_Lookup_lookupVarFMetaModelica(threadData, _cache, _inEnv, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr), 5))), _ty ,&_attr ,&_ty ,&_binding ,&_cnstForRange ,&_name);
tmpMeta[0+0] = _attr;
tmpMeta[0+1] = _ty;
tmpMeta[0+2] = _binding;
tmpMeta[0+3] = _cnstForRange;
tmp1_c4 = _name;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_attr = tmpMeta[0+0];
_ty = tmpMeta[0+1];
_binding = tmpMeta[0+2];
_cnstForRange = tmpMeta[0+3];
_name = tmp1_c4;
_return: OMC_LABEL_UNUSED
if (out_attr) { *out_attr = _attr; }
if (out_ty) { *out_ty = _ty; }
if (out_binding) { *out_binding = _binding; }
if (out_cnstForRange) { *out_cnstForRange = _cnstForRange; }
if (out_name) { *out_name = _name; }
return _cache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupVarFIdent(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcache, modelica_metatype _ht, modelica_string _ident, modelica_metatype _ss, modelica_metatype _inEnv, modelica_metatype *out_attr, modelica_metatype *out_ty_1, modelica_metatype *out_bind, modelica_metatype *out_cnstForRange, modelica_metatype *out_splicedExpData, modelica_metatype *out_componentEnv, modelica_string *out_name)
{
modelica_metatype _cache = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _ty_1 = NULL;
modelica_metatype _bind = NULL;
modelica_metatype _cnstForRange = NULL;
modelica_metatype _splicedExpData = NULL;
modelica_metatype _componentEnv = NULL;
modelica_string _name = NULL;
modelica_metatype _tty = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _ss_1 = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cache = __omcQ_24in_5Fcache;
tmpMeta2 = omc_Lookup_lookupVar2(threadData, _ht, _ident, _inEnv, NULL, NULL, NULL, &tmpMeta1);
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 2));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 3));
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 4));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 5));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 7));
_name = tmpMeta3;
_attr = tmpMeta4;
_ty = tmpMeta5;
_bind = tmpMeta6;
_cnstForRange = tmpMeta7;
_componentEnv = tmpMeta1;
_ty_1 = omc_Lookup_checkSubscripts(threadData, _ty, _ss);
_tty = omc_Types_simplifyType(threadData, _ty);
_ss_1 = omc_Lookup_addArrayDimensions(threadData, _tty, _ss);
tmpMeta8 = mmc_mk_box3(3, &InstTypes_SplicedExpData_SPLICEDEXPDATA__desc, mmc_mk_some(omc_Expression_makeCrefExp(threadData, omc_ComponentReference_makeCrefIdent(threadData, _ident, _tty, _ss_1), _tty)), _ty);
_splicedExpData = tmpMeta8;
_return: OMC_LABEL_UNUSED
if (out_attr) { *out_attr = _attr; }
if (out_ty_1) { *out_ty_1 = _ty_1; }
if (out_bind) { *out_bind = _bind; }
if (out_cnstForRange) { *out_cnstForRange = _cnstForRange; }
if (out_splicedExpData) { *out_splicedExpData = _splicedExpData; }
if (out_componentEnv) { *out_componentEnv = _componentEnv; }
if (out_name) { *out_name = _name; }
return _cache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupVarF(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inBinTree, modelica_metatype _inComponentRef, modelica_metatype _inEnv, modelica_metatype *out_outAttributes, modelica_metatype *out_outType, modelica_metatype *out_outBinding, modelica_metatype *out_constOfForIteratorRange, modelica_metatype *out_splicedExpData, modelica_metatype *out_outComponentEnv, modelica_string *out_name)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outAttributes = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _outBinding = NULL;
modelica_metatype _constOfForIteratorRange = NULL;
modelica_metatype _splicedExpData = NULL;
modelica_metatype _outComponentEnv = NULL;
modelica_string _name = NULL;
modelica_string tmp1_c7 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[14] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inCache;
tmp4_2 = _inBinTree;
tmp4_3 = _inComponentRef;
{
modelica_string _id = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _prl = NULL;
modelica_metatype _vt = NULL;
modelica_metatype _vt2 = NULL;
modelica_metatype _di = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _idTp = NULL;
modelica_metatype _ty2_2 = NULL;
modelica_metatype _tyParent = NULL;
modelica_metatype _tyChild = NULL;
modelica_metatype _ty1 = NULL;
modelica_metatype _binding = NULL;
modelica_metatype _parentBinding = NULL;
modelica_metatype _ht = NULL;
modelica_metatype _ss = NULL;
modelica_metatype _componentEnv = NULL;
modelica_metatype _ids = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _io = NULL;
modelica_metatype _texp = NULL;
modelica_metatype _xCref = NULL;
modelica_metatype _tCref = NULL;
modelica_metatype _ltCref = NULL;
modelica_metatype _splicedExp = NULL;
modelica_metatype _eType = NULL;
modelica_metatype _cnstForRange = NULL;
modelica_metatype _vis = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _oSplicedExp = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_id = tmpMeta6;
_ss = tmpMeta7;
tmpMeta[0+0] = omc_Lookup_lookupVarFIdent(threadData, _inCache, _inBinTree, _id, _ss, _inEnv, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3], &tmpMeta[0+4], &tmpMeta[0+5], &tmpMeta[0+6], &tmp1_c7);
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
modelica_string tmp17_c5 __attribute__((unused)) = 0;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,4) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 5));
_id = tmpMeta8;
_ss = tmpMeta9;
_ids = tmpMeta10;
_cache = tmp4_1;
_ht = tmp4_2;
tmpMeta12 = omc_Lookup_lookupVar2(threadData, _ht, _id, _inEnv, NULL, NULL, NULL, &tmpMeta11);
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 3));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 4));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 4));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 5));
_vt2 = tmpMeta14;
_tyParent = tmpMeta15;
_parentBinding = tmpMeta16;
_componentEnv = tmpMeta11;
{
modelica_metatype tmp20_1;
tmp20_1 = _tyParent;
{
volatile mmc_switch_type tmp20;
int tmp21;
tmp20 = 0;
for (; tmp20 < 3; tmp20++) {
switch (MMC_SWITCH_CAST(tmp20)) {
case 0: {
modelica_boolean tmp22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp20_1,22,1) == 0) goto tmp19_end;
tmp22 = (listLength(omc_Types_getDimensions(threadData, _tyParent)) == listLength(_ss));
if (1 != tmp22) goto goto_18;
_cache = omc_Lookup_lookupVarFMetaModelica(threadData, _cache, _componentEnv, _ids, omc_Types_metaArrayElementType(threadData, _tyParent) ,&_attr ,&_ty ,&_binding ,&_cnstForRange ,&_name);
tmpMeta23 = mmc_mk_box3(3, &InstTypes_SplicedExpData_SPLICEDEXPDATA__desc, mmc_mk_none(), _ty);
_splicedExpData = tmpMeta23;
tmpMeta[8+0] = _attr;
tmpMeta[8+1] = _ty;
tmpMeta[8+2] = _binding;
tmpMeta[8+3] = _cnstForRange;
tmpMeta[8+4] = _componentEnv;
tmp17_c5 = _name;
goto tmp19_done;
}
case 1: {
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
if (!(omc_Types_isBoxedType(threadData, _tyParent) && (!omc_Types_isUnknownType(threadData, _tyParent)))) goto tmp19_end;
tmpMeta24 = _ss;
if (!listEmpty(tmpMeta24)) goto goto_18;
_cache = omc_Lookup_lookupVarFMetaModelica(threadData, _cache, _componentEnv, _ids, _tyParent ,&_attr ,&_ty ,&_binding ,&_cnstForRange ,&_name);
tmpMeta25 = mmc_mk_box3(3, &InstTypes_SplicedExpData_SPLICEDEXPDATA__desc, mmc_mk_none(), _ty);
_splicedExpData = tmpMeta25;
tmpMeta[8+0] = _attr;
tmpMeta[8+1] = _ty;
tmpMeta[8+2] = _binding;
tmpMeta[8+3] = _cnstForRange;
tmpMeta[8+4] = _componentEnv;
tmp17_c5 = _name;
goto tmp19_done;
}
case 2: {
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
modelica_string tmp40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
tmpMeta41 = omc_Lookup_lookupVar(threadData, _cache, _componentEnv, _ids, &tmpMeta26, &tmpMeta33, &tmpMeta34, &tmpMeta35, &tmpMeta36, NULL, &tmpMeta39, &tmp40);
_cache = tmpMeta41;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 2));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 3));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 4));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 5));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 6));
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 7));
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta36), 2));
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta36), 3));
_ct = tmpMeta27;
_prl = tmpMeta28;
_vt = tmpMeta29;
_di = tmpMeta30;
_io = tmpMeta31;
_vis = tmpMeta32;
_tyChild = tmpMeta33;
_binding = tmpMeta34;
_cnstForRange = tmpMeta35;
_texp = tmpMeta37;
_idTp = tmpMeta38;
_componentEnv = tmpMeta39;
_name = tmp40;
_ltCref = omc_Lookup_elabComponentRecursive(threadData, _texp);
_ty = _tyChild;
{
modelica_metatype tmp45_1;
tmp45_1 = _ltCref;
{
volatile mmc_switch_type tmp45;
int tmp46;
tmp45 = 0;
for (; tmp45 < 2; tmp45++) {
switch (MMC_SWITCH_CAST(tmp45)) {
case 0: {
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
if (listEmpty(tmp45_1)) goto tmp44_end;
tmpMeta47 = MMC_CAR(tmp45_1);
tmpMeta48 = MMC_CDR(tmp45_1);
_tCref = tmpMeta47;
_ty1 = omc_Lookup_checkSubscripts(threadData, _tyParent, _ss);
_ty = omc_Lookup_sliceDimensionType(threadData, _ty1, _tyChild);
_ty2_2 = omc_Types_simplifyType(threadData, _tyParent);
_ss = omc_Lookup_addArrayDimensions(threadData, _ty2_2, _ss);
_xCref = omc_ComponentReference_makeCrefQual(threadData, _id, _ty2_2, _ss, _tCref);
_eType = omc_Types_simplifyType(threadData, _ty);
_splicedExp = omc_Expression_makeCrefExp(threadData, _xCref, _eType);
tmpMeta42 = mmc_mk_some(_splicedExp);
goto tmp44_done;
}
case 1: {
if (!listEmpty(tmp45_1)) goto tmp44_end;
tmpMeta42 = mmc_mk_none();
goto tmp44_done;
}
}
goto tmp44_end;
tmp44_end: ;
}
goto goto_43;
goto_43:;
goto goto_18;
goto tmp44_done;
tmp44_done:;
}
}
_oSplicedExp = tmpMeta42;
_vt = omc_SCodeUtil_variabilityOr(threadData, _vt, _vt2);
_binding = omc_Lookup_lookupBinding(threadData, _inComponentRef, _tyParent, _ty, _parentBinding, _binding);
tmpMeta49 = mmc_mk_box3(3, &InstTypes_SplicedExpData_SPLICEDEXPDATA__desc, _oSplicedExp, _idTp);
_splicedExpData = tmpMeta49;
tmpMeta50 = mmc_mk_box7(3, &DAE_Attributes_ATTR__desc, _ct, _prl, _vt, _di, _io, _vis);
tmpMeta[8+0] = tmpMeta50;
tmpMeta[8+1] = _ty;
tmpMeta[8+2] = _binding;
tmpMeta[8+3] = _cnstForRange;
tmpMeta[8+4] = _componentEnv;
tmp17_c5 = _name;
goto tmp19_done;
}
}
goto tmp19_end;
tmp19_end: ;
}
goto goto_18;
goto_18:;
goto goto_2;
goto tmp19_done;
tmp19_done:;
}
}
_attr = tmpMeta[8+0];
_ty = tmpMeta[8+1];
_binding = tmpMeta[8+2];
_cnstForRange = tmpMeta[8+3];
_componentEnv = tmpMeta[8+4];
_name = tmp17_c5;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _attr;
tmpMeta[0+2] = _ty;
tmpMeta[0+3] = _binding;
tmpMeta[0+4] = _cnstForRange;
tmpMeta[0+5] = _splicedExpData;
tmpMeta[0+6] = _componentEnv;
tmp1_c7 = _name;
goto tmp3_done;
}
}
goto tmp3_end;
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
_outAttributes = tmpMeta[0+1];
_outType = tmpMeta[0+2];
_outBinding = tmpMeta[0+3];
_constOfForIteratorRange = tmpMeta[0+4];
_splicedExpData = tmpMeta[0+5];
_outComponentEnv = tmpMeta[0+6];
_name = tmp1_c7;
_return: OMC_LABEL_UNUSED
if (out_outAttributes) { *out_outAttributes = _outAttributes; }
if (out_outType) { *out_outType = _outType; }
if (out_outBinding) { *out_outBinding = _outBinding; }
if (out_constOfForIteratorRange) { *out_constOfForIteratorRange = _constOfForIteratorRange; }
if (out_splicedExpData) { *out_splicedExpData = _splicedExpData; }
if (out_outComponentEnv) { *out_outComponentEnv = _outComponentEnv; }
if (out_name) { *out_name = _name; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_checkSubscripts(threadData_t *threadData, modelica_metatype _inType, modelica_metatype _inExpSubscriptLst)
{
modelica_metatype _outType = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inType;
tmp4_2 = _inExpSubscriptLst;
{
modelica_metatype _t = NULL;
modelica_metatype _t_1 = NULL;
modelica_metatype _dim = NULL;
modelica_metatype _ys = NULL;
modelica_metatype _s = NULL;
modelica_integer _sz;
modelica_integer _ind;
modelica_integer _dim_int;
modelica_metatype _se = NULL;
modelica_metatype _e = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 15; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
_t = tmp4_1;
tmp4 += 9;
tmpMeta1 = _t;
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
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
if (!listEmpty(tmpMeta11)) goto tmp3_end;
_ys = tmpMeta7;
_t = tmpMeta8;
_dim = tmpMeta10;
tmp4 += 7;
_t_1 = omc_Lookup_checkSubscripts(threadData, _t, _ys);
tmpMeta12 = mmc_mk_cons(_dim, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta13 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _t_1, tmpMeta12);
tmpMeta1 = tmpMeta13;
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
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta15)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmpMeta15);
tmpMeta17 = MMC_CDR(tmpMeta15);
if (!listEmpty(tmpMeta17)) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta18 = MMC_CAR(tmp4_2);
tmpMeta19 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,1,1) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,18,4) == 0) goto tmp3_end;
_t = tmpMeta14;
_e = tmpMeta20;
_ys = tmpMeta19;
tmp4 += 1;
_t_1 = omc_Lookup_checkSubscripts(threadData, _t, _ys);
_dim_int = omc_Expression_rangeSize(threadData, _e);
tmpMeta22 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_dim_int));
tmpMeta21 = mmc_mk_cons(tmpMeta22, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta23 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _t_1, tmpMeta21);
tmpMeta1 = tmpMeta23;
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
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta25)) goto tmp3_end;
tmpMeta26 = MMC_CAR(tmpMeta25);
tmpMeta27 = MMC_CDR(tmpMeta25);
if (!listEmpty(tmpMeta27)) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta28 = MMC_CAR(tmp4_2);
tmpMeta29 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta28,1,1) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta28), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta30,16,3) == 0) goto tmp3_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 4));
_t = tmpMeta24;
_dim = tmpMeta26;
_se = tmpMeta31;
_ys = tmpMeta29;
omc_Expression_dimensionSize(threadData, _dim);
_t_1 = omc_Lookup_checkSubscripts(threadData, _t, _ys);
_dim_int = listLength(_se);
tmpMeta33 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_dim_int));
tmpMeta32 = mmc_mk_cons(tmpMeta33, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta34 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _t_1, tmpMeta32);
tmpMeta1 = tmpMeta34;
goto tmp3_done;
}
case 4: {
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
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta35 = MMC_CAR(tmp4_2);
tmpMeta36 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta35,1,1) == 0) goto tmp3_end;
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta35), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta39)) goto tmp3_end;
tmpMeta40 = MMC_CAR(tmpMeta39);
tmpMeta41 = MMC_CDR(tmpMeta39);
if (!listEmpty(tmpMeta41)) goto tmp3_end;
_e = tmpMeta37;
_ys = tmpMeta36;
_t = tmpMeta38;
tmp4 += 9;
tmpMeta42 = omc_Expression_typeof(threadData, _e);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta42,6,2) == 0) goto goto_2;
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta42), 3));
if (listEmpty(tmpMeta43)) goto goto_2;
tmpMeta44 = MMC_CAR(tmpMeta43);
tmpMeta45 = MMC_CDR(tmpMeta43);
if (!listEmpty(tmpMeta45)) goto goto_2;
_dim = tmpMeta44;
_t_1 = omc_Lookup_checkSubscripts(threadData, _t, _ys);
tmpMeta46 = mmc_mk_cons(_dim, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta47 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _t_1, tmpMeta46);
tmpMeta1 = tmpMeta47;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
modelica_integer tmp56;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta49)) goto tmp3_end;
tmpMeta50 = MMC_CAR(tmpMeta49);
tmpMeta51 = MMC_CDR(tmpMeta49);
if (!listEmpty(tmpMeta51)) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta52 = MMC_CAR(tmp4_2);
tmpMeta53 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta52,2,1) == 0) goto tmp3_end;
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta52), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta54,0,1) == 0) goto tmp3_end;
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta54), 2));
tmp56 = mmc_unbox_integer(tmpMeta55);
_t = tmpMeta48;
_dim = tmpMeta50;
_ind = tmp56;
_ys = tmpMeta53;
_sz = omc_Expression_dimensionSize(threadData, _dim);
if((!(_ind > ((modelica_integer) 0))))
{
goto goto_2;
}
if((!(_ind <= _sz)))
{
goto goto_2;
}
tmpMeta1 = omc_Lookup_checkSubscripts(threadData, _t, _ys);
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta57;
modelica_metatype tmpMeta58;
modelica_metatype tmpMeta59;
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
modelica_metatype tmpMeta62;
modelica_boolean tmp63;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta57 = MMC_CAR(tmp4_2);
tmpMeta58 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta57,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta59 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta60)) goto tmp3_end;
tmpMeta61 = MMC_CAR(tmpMeta60);
tmpMeta62 = MMC_CDR(tmpMeta60);
if (!listEmpty(tmpMeta62)) goto tmp3_end;
_ys = tmpMeta58;
_t = tmpMeta59;
_dim = tmpMeta61;
tmp63 = omc_Expression_dimensionKnown(threadData, _dim);
if (1 != tmp63) goto goto_2;
tmpMeta1 = omc_Lookup_checkSubscripts(threadData, _t, _ys);
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta64;
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
modelica_metatype tmpMeta67;
modelica_metatype tmpMeta68;
modelica_metatype tmpMeta69;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta64 = MMC_CAR(tmp4_2);
tmpMeta65 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta64,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta66 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta67 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta67)) goto tmp3_end;
tmpMeta68 = MMC_CAR(tmpMeta67);
tmpMeta69 = MMC_CDR(tmpMeta67);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta68,4,0) == 0) goto tmp3_end;
if (!listEmpty(tmpMeta69)) goto tmp3_end;
_ys = tmpMeta65;
_t = tmpMeta66;
tmp4 += 6;
tmpMeta1 = omc_Lookup_checkSubscripts(threadData, _t, _ys);
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta70;
modelica_metatype tmpMeta71;
modelica_metatype tmpMeta72;
modelica_metatype tmpMeta73;
modelica_metatype tmpMeta74;
modelica_metatype tmpMeta75;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta70 = MMC_CAR(tmp4_2);
tmpMeta71 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta70,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta72 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta73 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta73)) goto tmp3_end;
tmpMeta74 = MMC_CAR(tmpMeta73);
tmpMeta75 = MMC_CDR(tmpMeta73);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta74,3,1) == 0) goto tmp3_end;
if (!listEmpty(tmpMeta75)) goto tmp3_end;
_ys = tmpMeta71;
_t = tmpMeta72;
tmp4 += 5;
tmpMeta1 = omc_Lookup_checkSubscripts(threadData, _t, _ys);
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta76;
modelica_metatype tmpMeta77;
modelica_metatype tmpMeta78;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta76 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta77 = MMC_CAR(tmp4_2);
tmpMeta78 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta77,0,0) == 0) goto tmp3_end;
_t = tmpMeta76;
_ys = tmpMeta78;
tmp4 += 4;
tmpMeta1 = omc_Lookup_checkSubscripts(threadData, _t, _ys);
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta79;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta79 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_t = tmpMeta79;
_ys = tmp4_2;
tmp4 += 3;
tmpMeta1 = omc_Lookup_checkSubscripts(threadData, _t, _ys);
goto tmp3_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,0) == 0) goto tmp3_end;
_t = tmp4_1;
tmp4 += 2;
tmpMeta1 = _t;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta80;
modelica_metatype tmpMeta81;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,1) == 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta80 = MMC_CAR(tmp4_2);
tmpMeta81 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta80,2,1) == 0) goto tmp3_end;
if (!listEmpty(tmpMeta81)) goto tmp3_end;
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inType), 2)));
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta82;
modelica_metatype tmpMeta83;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,1) == 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta82 = MMC_CAR(tmp4_2);
tmpMeta83 = MMC_CDR(tmp4_2);
if (!listEmpty(tmpMeta83)) goto tmp3_end;
tmpMeta1 = _inType;
goto tmp3_done;
}
case 14: {
modelica_boolean tmp84;
_t = tmp4_1;
_s = tmp4_2;
tmp84 = omc_Flags_isSet(threadData, _OMC_LIT30);
if (1 != tmp84) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT31);
omc_Debug_trace(threadData, omc_Types_printTypeStr(threadData, _t));
omc_Debug_trace(threadData, _OMC_LIT32);
omc_Debug_trace(threadData, stringDelimitList(omc_List_map(threadData, _s, boxvar_ExpressionDump_printSubscriptStr), _OMC_LIT33));
omc_Debug_trace(threadData, _OMC_LIT34);
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
if (++tmp4 < 15) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outType = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outType;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupVar2(threadData_t *threadData, modelica_metatype _inBinTree, modelica_string _inIdent, modelica_metatype _inGraph, modelica_metatype *out_outElement, modelica_metatype *out_outMod, modelica_metatype *out_instStatus, modelica_metatype *out_outEnv)
{
modelica_metatype _outVar = NULL;
modelica_metatype _outElement = NULL;
modelica_metatype _outMod = NULL;
modelica_metatype _instStatus = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _r = NULL;
modelica_metatype _s = NULL;
modelica_metatype _n = NULL;
modelica_string _name = NULL;
modelica_boolean tmp1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
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
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_r = omc_FCore_RefTree_get(threadData, _inBinTree, _inIdent);
_outVar = omc_FNode_refInstVar(threadData, _r);
_s = omc_FNode_refRefTargetScope(threadData, _r);
_n = omc_FNode_fromRef(threadData, _r);
if(((!omc_FNode_isComponent(threadData, _n)) && omc_Flags_isSet(threadData, _OMC_LIT41)))
{
tmp1 = omc_Config_acceptMetaModelicaGrammar(threadData);
if (0 != tmp1) MMC_THROW_INTERNAL();
tmpMeta2 = _n;
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta3,3,5) == 0) MMC_THROW_INTERNAL();
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta4,2,8) == 0) MMC_THROW_INTERNAL();
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta4), 2));
_name = tmpMeta5;
tmpMeta6 = stringAppend(_inIdent,_OMC_LIT35);
tmpMeta7 = stringAppend(tmpMeta6,omc_FGraph_printGraphPathStr(threadData, _inGraph));
tmpMeta8 = stringAppend(tmpMeta7,_OMC_LIT36);
tmpMeta9 = stringAppend(tmpMeta8,_name);
_name = tmpMeta9;
tmpMeta10 = stringAppend(_OMC_LIT37,_name);
omc_Debug_traceln(threadData, tmpMeta10);
MMC_THROW_INTERNAL();
}
tmpMeta11 = _n;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,4,4) == 0) MMC_THROW_INTERNAL();
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 3));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 5));
_outElement = tmpMeta13;
_outMod = tmpMeta14;
_instStatus = tmpMeta15;
_outEnv = omc_FGraph_setScope(threadData, _inGraph, _s);
_return: OMC_LABEL_UNUSED
if (out_outElement) { *out_outElement = _outElement; }
if (out_outMod) { *out_outMod = _outMod; }
if (out_instStatus) { *out_instStatus = _instStatus; }
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outVar;
}
PROTECTED_FUNCTION_STATIC void omc_Lookup_reportSeveralNamesError(threadData_t *threadData, modelica_boolean _unique, modelica_string _name)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean tmp3_1;
tmp3_1 = _unique;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (1 != tmp3_1) goto tmp2_end;
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta5;
if (0 != tmp3_1) goto tmp2_end;
tmpMeta5 = mmc_mk_cons(_name, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMessage(threadData, _OMC_LIT46, tmpMeta5);
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
PROTECTED_FUNCTION_STATIC void boxptr_Lookup_reportSeveralNamesError(threadData_t *threadData, modelica_metatype _unique, modelica_metatype _name)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_unique);
omc_Lookup_reportSeveralNamesError(threadData, tmp1, _name);
return;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupClassInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inFrame, modelica_metatype _inEnv, modelica_string _inIdent, modelica_metatype _inPrevFrames, modelica_metatype _inState, modelica_metatype _inInfo, modelica_metatype *out_outClass, modelica_metatype *out_outEnv, modelica_metatype *out_outPrevFrames)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outClass = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outPrevFrames = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_string tmp4_4;volatile modelica_metatype tmp4_5;
tmp4_1 = _inCache;
tmp4_2 = _inFrame;
tmp4_3 = _inEnv;
tmp4_4 = _inIdent;
tmp4_5 = _inPrevFrames;
{
modelica_metatype _c = NULL;
modelica_metatype _totenv = NULL;
modelica_metatype _env_1 = NULL;
modelica_metatype _prevFrames = NULL;
modelica_metatype _r = NULL;
modelica_metatype _ht = NULL;
modelica_string _name = NULL;
modelica_metatype _qimports = NULL;
modelica_metatype _uqimports = NULL;
modelica_metatype _cache = NULL;
modelica_boolean _unique;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
_cache = tmp4_1;
_ht = tmpMeta6;
_totenv = tmp4_3;
_name = tmp4_4;
_prevFrames = tmp4_5;
_r = omc_FCore_RefTree_get(threadData, _ht, _name);
tmpMeta7 = omc_FNode_fromRef(threadData, _r);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,3,5) == 0) goto goto_2;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
_c = tmpMeta9;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _c;
tmpMeta[0+2] = _totenv;
tmpMeta[0+3] = _prevFrames;
goto tmp3_done;
}
case 1: {
_cache = tmp4_1;
_totenv = tmp4_3;
_name = tmp4_4;
_qimports = omc_FNode_imports(threadData, _inFrame ,&_uqimports);
{
volatile modelica_metatype tmp12_1;volatile modelica_metatype tmp12_2;
tmp12_1 = _qimports;
tmp12_2 = _uqimports;
{
volatile mmc_switch_type tmp12;
int tmp13;
tmp12 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp11_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp12 < 2; tmp12++) {
switch (MMC_SWITCH_CAST(tmp12)) {
case 0: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (listEmpty(tmp12_1)) goto tmp11_end;
tmpMeta14 = MMC_CAR(tmp12_1);
tmpMeta15 = MMC_CDR(tmp12_1);
_cache = omc_Lookup_lookupQualifiedImportedClassInFrame(threadData, _cache, _qimports, _totenv, _name, _inState, _inInfo ,&_c ,&_env_1 ,&_prevFrames);
goto tmp11_done;
}
case 1: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (listEmpty(tmp12_2)) goto tmp11_end;
tmpMeta16 = MMC_CAR(tmp12_2);
tmpMeta17 = MMC_CDR(tmp12_2);
_cache = omc_Lookup_lookupUnqualifiedImportedClassInFrame(threadData, _cache, _uqimports, _totenv, _name, _inInfo ,&_c ,&_env_1 ,&_prevFrames ,&_unique);
omc_Mutable_update(threadData, _inState, mmc_mk_boolean(1));
omc_Lookup_reportSeveralNamesError(threadData, _unique, _name);
goto tmp11_done;
}
}
goto tmp11_end;
tmp11_end: ;
}
goto goto_10;
tmp11_done:
(void)tmp12;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp11_done2;
goto_10:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp12 < 2) {
goto tmp11_top;
}
goto goto_2;
tmp11_done2:;
}
}
;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _c;
tmpMeta[0+2] = _env_1;
tmpMeta[0+3] = _prevFrames;
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
_outClass = tmpMeta[0+1];
_outEnv = tmpMeta[0+2];
_outPrevFrames = tmpMeta[0+3];
_return: OMC_LABEL_UNUSED
if (out_outClass) { *out_outClass = _outClass; }
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outPrevFrames) { *out_outPrevFrames = _outPrevFrames; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupClassInEnv(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_string _id, modelica_metatype _inPrevFrames, modelica_metatype _inState, modelica_metatype _inInfo, modelica_metatype *out_outClass, modelica_metatype *out_outEnv, modelica_metatype *out_outPrevFrames)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outClass = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outPrevFrames = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inPrevFrames;
tmp4_4 = _inInfo;
{
modelica_metatype _c = NULL;
modelica_metatype _env_1 = NULL;
modelica_metatype _env = NULL;
modelica_metatype _i_env = NULL;
modelica_metatype _prevFrames = NULL;
modelica_metatype _frame = NULL;
modelica_metatype _r = NULL;
modelica_string _sid = NULL;
modelica_string _scope = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _info = NULL;
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
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
_env = tmp4_2;
_r = tmpMeta7;
_cache = tmp4_1;
_prevFrames = tmp4_3;
_frame = omc_FNode_fromRef(threadData, _r);
_cache = omc_Lookup_lookupClassInFrame(threadData, _cache, _frame, _env, _id, _prevFrames, _inState, _inInfo ,&_c ,&_env_1 ,&_prevFrames);
omc_Mutable_update(threadData, _inState, mmc_mk_boolean(1));
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _c;
tmpMeta[0+2] = _env_1;
tmpMeta[0+3] = _prevFrames;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_boolean tmp12;
modelica_boolean tmp13;
modelica_boolean tmp14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
_env = tmp4_2;
_r = tmpMeta10;
_cache = tmp4_1;
_prevFrames = tmp4_3;
tmp12 = omc_FNode_isRefTop(threadData, _r);
if (0 != tmp12) goto goto_2;
_frame = omc_FNode_fromRef(threadData, _r);
_sid = omc_FNode_refName(threadData, _r);
tmp13 = omc_FNode_isEncapsulated(threadData, _frame);
if (1 != tmp13) goto goto_2;
tmp14 = (stringEqual(_id, _sid));
if (1 != tmp14) goto goto_2;
_env = omc_FGraph_stripLastScopeRef(threadData, _env, NULL);
tmpMeta15 = mmc_mk_cons(_r, _prevFrames);
_cache = omc_Lookup_lookupClassInEnv(threadData, _cache, _env, _id, tmpMeta15, _inState, _inInfo ,&_c ,&_env ,&_prevFrames);
omc_Mutable_update(threadData, _inState, mmc_mk_boolean(1));
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _c;
tmpMeta[0+2] = _env;
tmpMeta[0+3] = _prevFrames;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_boolean tmp20;
modelica_boolean tmp21;
modelica_boolean tmp22;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
if (optionNone(tmp4_4)) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta17)) goto tmp3_end;
tmpMeta18 = MMC_CAR(tmpMeta17);
tmpMeta19 = MMC_CDR(tmpMeta17);
_info = tmpMeta16;
_env = tmp4_2;
_r = tmpMeta18;
_cache = tmp4_1;
tmp20 = omc_FNode_isRefTop(threadData, _r);
if (0 != tmp20) goto goto_2;
_frame = omc_FNode_fromRef(threadData, _r);
tmp21 = omc_FNode_isEncapsulated(threadData, _frame);
if (1 != tmp21) goto goto_2;
_i_env = omc_FGraph_topScope(threadData, _env);
tmp22 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmpMeta24 = MMC_REFSTRUCTLIT(mmc_nil);
omc_Lookup_lookupClassInEnv(threadData, _cache, _i_env, _id, tmpMeta24, _inState, mmc_mk_none(), NULL, NULL, NULL);
tmp22 = 1;
goto goto_23;
goto_23:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp22) {goto goto_2;}
_scope = omc_FGraph_printGraphPathStr(threadData, _env);
tmpMeta25 = mmc_mk_cons(_id, mmc_mk_cons(_scope, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT49, tmpMeta25, _info);
goto goto_2;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_boolean tmp29;
modelica_metatype tmpMeta30;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta26)) goto tmp3_end;
tmpMeta27 = MMC_CAR(tmpMeta26);
tmpMeta28 = MMC_CDR(tmpMeta26);
_env = tmp4_2;
_r = tmpMeta27;
_cache = tmp4_1;
_prevFrames = tmp4_3;
_frame = omc_FNode_fromRef(threadData, _r);
tmp29 = omc_FNode_isEncapsulated(threadData, _frame);
if (1 != tmp29) goto goto_2;
_i_env = omc_FGraph_topScope(threadData, _env);
tmpMeta30 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_Lookup_lookupClassInEnv(threadData, _cache, _i_env, _id, tmpMeta30, _inState, _inInfo ,&_c ,&_env_1 ,&_prevFrames);
omc_Mutable_update(threadData, _inState, mmc_mk_boolean(1));
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _c;
tmpMeta[0+2] = _env_1;
tmpMeta[0+3] = _prevFrames;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_boolean tmp34;
modelica_boolean tmp35;
modelica_metatype tmpMeta36;
modelica_integer tmp37;
modelica_metatype tmpMeta38;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta31)) goto tmp3_end;
tmpMeta32 = MMC_CAR(tmpMeta31);
tmpMeta33 = MMC_CDR(tmpMeta31);
_env = tmp4_2;
_r = tmpMeta32;
_cache = tmp4_1;
_prevFrames = tmp4_3;
tmp34 = omc_FNode_isRefTop(threadData, _r);
if (0 != tmp34) goto goto_2;
_frame = omc_FNode_fromRef(threadData, _r);
tmp35 = omc_FNode_isEncapsulated(threadData, _frame);
if (0 != tmp35) goto goto_2;
tmpMeta36 = omc_Mutable_access(threadData, _inState);
tmp37 = mmc_unbox_integer(tmpMeta36);
if (0 != tmp37) goto goto_2;
_env = omc_FGraph_stripLastScopeRef(threadData, _env, NULL);
tmpMeta38 = mmc_mk_cons(_r, _prevFrames);
_cache = omc_Lookup_lookupClassInEnv(threadData, _cache, _env, _id, tmpMeta38, _inState, _inInfo ,&_c ,&_env_1 ,&_prevFrames);
omc_Mutable_update(threadData, _inState, mmc_mk_boolean(1));
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _c;
tmpMeta[0+2] = _env_1;
tmpMeta[0+3] = _prevFrames;
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
_outClass = tmpMeta[0+1];
_outEnv = tmpMeta[0+2];
_outPrevFrames = tmpMeta[0+3];
_return: OMC_LABEL_UNUSED
if (out_outClass) { *out_outClass = _outClass; }
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outPrevFrames) { *out_outPrevFrames = _outPrevFrames; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_buildRecordConstructorResultElt(threadData_t *threadData, modelica_metatype _elts, modelica_string _id, modelica_metatype _env, modelica_metatype _info)
{
modelica_metatype _outElement = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _id);
tmpMeta2 = mmc_mk_box3(3, &Absyn_TypeSpec_TPATH__desc, tmpMeta1, mmc_mk_none());
tmpMeta3 = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _OMC_LIT50, _OMC_LIT56, _OMC_LIT62, tmpMeta2, _OMC_LIT63, _OMC_LIT64, mmc_mk_none(), _info);
_outElement = tmpMeta3;
_return: OMC_LABEL_UNUSED
return _outElement;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_buildRecordConstructorElts(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inSCodeElementLst, modelica_metatype _mods, modelica_metatype *out_outEnv, modelica_metatype *out_outSCodeElementLst)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outSCodeElementLst = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inSCodeElementLst;
{
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _res = NULL;
modelica_metatype _comp = NULL;
modelica_string _id = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _repl = NULL;
modelica_metatype _vis = NULL;
modelica_metatype _f = NULL;
modelica_metatype _redecl = NULL;
modelica_metatype _io = NULL;
modelica_metatype _d = NULL;
modelica_metatype _prl = NULL;
modelica_metatype _var = NULL;
modelica_metatype _isf = NULL;
modelica_metatype _dir = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _comment = NULL;
modelica_metatype _cond = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _umod = NULL;
modelica_metatype _mod_1 = NULL;
modelica_metatype _compMod = NULL;
modelica_metatype _fullMod = NULL;
modelica_metatype _selectedMod = NULL;
modelica_metatype _cmod = NULL;
modelica_metatype _info = NULL;
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
if (!listEmpty(tmp4_3)) goto tmp3_end;
_cache = tmp4_1;
_env = tmp4_2;
tmp4 += 5;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = tmpMeta6;
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
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_3);
tmpMeta8 = MMC_CDR(tmp4_3);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,3,8) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 3));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 3));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,0,0) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 5));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 6));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 4));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 3));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 4));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 5));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 7));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 5));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 6));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 7));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 8));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 9));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_id = tmpMeta10;
_redecl = tmpMeta12;
_f = tmpMeta13;
_io = tmpMeta14;
_repl = tmpMeta15;
_d = tmpMeta17;
_ct = tmpMeta18;
_prl = tmpMeta19;
_var = tmpMeta20;
_isf = tmpMeta21;
_tp = tmpMeta22;
_mod = tmpMeta23;
_comment = tmpMeta24;
_cond = tmpMeta25;
_info = tmpMeta26;
_cmod = tmpMeta27;
_rest = tmpMeta8;
_cache = tmp4_1;
_env = tmp4_2;
tmpMeta28 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta29 = mmc_mk_box2(3, &Mod_ModScope_COMPONENT__desc, _id);
_cache = omc_Mod_elabMod(threadData, _cache, _env, tmpMeta28, _OMC_LIT6, _mod, 1, tmpMeta29, _info ,&_mod_1);
_mod_1 = omc_Mod_merge(threadData, _mods, _mod_1, _OMC_LIT7, 1);
_compMod = omc_Mod_lookupCompModification(threadData, _mod_1, _id);
_fullMod = _mod_1;
_selectedMod = omc_Lookup_selectModifier(threadData, _compMod, _fullMod);
tmpMeta30 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_Mod_updateMod(threadData, _cache, _env, tmpMeta30, _OMC_LIT6, _cmod, 1, _info ,&_cmod);
_selectedMod = omc_Mod_merge(threadData, _cmod, _selectedMod, _OMC_LIT7, 1);
_umod = omc_Mod_unelabMod(threadData, _selectedMod);
_cache = omc_Lookup_buildRecordConstructorElts(threadData, _cache, _env, _rest, _mods ,&_env ,&_res);
_dir = _OMC_LIT65;
_vis = _OMC_LIT66;
tmpMeta32 = mmc_mk_box6(3, &SCode_Prefixes_PREFIXES__desc, _vis, _redecl, _f, _io, _repl);
tmpMeta33 = mmc_mk_box7(3, &SCode_Attributes_ATTR__desc, _d, _ct, _prl, _var, _dir, _isf);
tmpMeta34 = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _id, tmpMeta32, tmpMeta33, _tp, _umod, _comment, _cond, _info);
tmpMeta31 = mmc_mk_cons(tmpMeta34, _res);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = tmpMeta31;
goto tmp3_done;
}
case 2: {
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
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
modelica_metatype tmpMeta62;
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta35 = MMC_CAR(tmp4_3);
tmpMeta36 = MMC_CDR(tmp4_3);
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta35), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta37,3,8) == 0) goto tmp3_end;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 2));
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 3));
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 2));
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 3));
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 5));
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 6));
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 4));
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 2));
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 3));
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 4));
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta48,3,0) == 0) goto tmp3_end;
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 7));
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 5));
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta51,2,0) == 0) goto tmp3_end;
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 7));
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 8));
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 9));
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta35), 2));
_id = tmpMeta38;
_vis = tmpMeta40;
_redecl = tmpMeta41;
_io = tmpMeta42;
_repl = tmpMeta43;
_d = tmpMeta45;
_ct = tmpMeta46;
_prl = tmpMeta47;
_isf = tmpMeta49;
_tp = tmpMeta50;
_mod = tmpMeta51;
_comment = tmpMeta52;
_cond = tmpMeta53;
_info = tmpMeta54;
_cmod = tmpMeta55;
_rest = tmpMeta36;
_cache = tmp4_1;
_env = tmp4_2;
tmpMeta56 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta57 = mmc_mk_box2(3, &Mod_ModScope_COMPONENT__desc, _id);
_cache = omc_Mod_elabMod(threadData, _cache, _env, tmpMeta56, _OMC_LIT6, _mod, 1, tmpMeta57, _info ,&_mod_1);
_mod_1 = omc_Mod_merge(threadData, _mods, _mod_1, _OMC_LIT7, 1);
_compMod = omc_Mod_lookupCompModification(threadData, _mod_1, _id);
_fullMod = _mod_1;
_selectedMod = omc_Lookup_selectModifier(threadData, _compMod, _fullMod);
tmpMeta58 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_Mod_updateMod(threadData, _cache, _env, tmpMeta58, _OMC_LIT6, _cmod, 1, _info ,&_cmod);
_selectedMod = omc_Mod_merge(threadData, _cmod, _selectedMod, _OMC_LIT7, 1);
_umod = omc_Mod_unelabMod(threadData, _selectedMod);
_cache = omc_Lookup_buildRecordConstructorElts(threadData, _cache, _env, _rest, _mods ,&_env ,&_res);
_var = _OMC_LIT59;
_dir = _OMC_LIT67;
_vis = _OMC_LIT51;
_f = _OMC_LIT53;
tmpMeta60 = mmc_mk_box6(3, &SCode_Prefixes_PREFIXES__desc, _vis, _redecl, _f, _io, _repl);
tmpMeta61 = mmc_mk_box7(3, &SCode_Attributes_ATTR__desc, _d, _ct, _prl, _var, _dir, _isf);
tmpMeta62 = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _id, tmpMeta60, tmpMeta61, _tp, _umod, _comment, _cond, _info);
tmpMeta59 = mmc_mk_cons(tmpMeta62, _res);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = tmpMeta59;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta63;
modelica_metatype tmpMeta64;
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
modelica_metatype tmpMeta67;
modelica_metatype tmpMeta68;
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
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta63 = MMC_CAR(tmp4_3);
tmpMeta64 = MMC_CDR(tmp4_3);
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta63), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta65,3,8) == 0) goto tmp3_end;
tmpMeta66 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta65), 2));
tmpMeta67 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta65), 3));
tmpMeta68 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta67), 3));
tmpMeta69 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta67), 4));
tmpMeta70 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta67), 5));
tmpMeta71 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta67), 6));
tmpMeta72 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta65), 4));
tmpMeta73 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta72), 2));
tmpMeta74 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta72), 3));
tmpMeta75 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta72), 4));
tmpMeta76 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta72), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta76,3,0) == 0) goto tmp3_end;
tmpMeta77 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta72), 7));
tmpMeta78 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta65), 5));
tmpMeta79 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta65), 6));
tmpMeta80 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta65), 7));
tmpMeta81 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta65), 8));
tmpMeta82 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta65), 9));
tmpMeta83 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta63), 2));
_id = tmpMeta66;
_redecl = tmpMeta68;
_f = tmpMeta69;
_io = tmpMeta70;
_repl = tmpMeta71;
_d = tmpMeta73;
_ct = tmpMeta74;
_prl = tmpMeta75;
_var = tmpMeta76;
_isf = tmpMeta77;
_tp = tmpMeta78;
_mod = tmpMeta79;
_comment = tmpMeta80;
_cond = tmpMeta81;
_info = tmpMeta82;
_cmod = tmpMeta83;
_rest = tmpMeta64;
_cache = tmp4_1;
_env = tmp4_2;
tmpMeta84 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta85 = mmc_mk_box2(3, &Mod_ModScope_COMPONENT__desc, _id);
_cache = omc_Mod_elabMod(threadData, _cache, _env, tmpMeta84, _OMC_LIT6, _mod, 1, tmpMeta85, _info ,&_mod_1);
_mod_1 = omc_Mod_merge(threadData, _mods, _mod_1, _OMC_LIT7, 1);
_compMod = omc_Mod_lookupCompModification(threadData, _mod_1, _id);
_fullMod = _mod_1;
_selectedMod = omc_Lookup_selectModifier(threadData, _compMod, _fullMod);
tmpMeta86 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_Mod_updateMod(threadData, _cache, _env, tmpMeta86, _OMC_LIT6, _cmod, 1, _info ,&_cmod);
_selectedMod = omc_Mod_merge(threadData, _cmod, _selectedMod, _OMC_LIT7, 1);
_umod = omc_Mod_unelabMod(threadData, _selectedMod);
_cache = omc_Lookup_buildRecordConstructorElts(threadData, _cache, _env, _rest, _mods ,&_env ,&_res);
_dir = _OMC_LIT65;
_vis = _OMC_LIT66;
tmpMeta88 = mmc_mk_box6(3, &SCode_Prefixes_PREFIXES__desc, _vis, _redecl, _f, _io, _repl);
tmpMeta89 = mmc_mk_box7(3, &SCode_Attributes_ATTR__desc, _d, _ct, _prl, _var, _dir, _isf);
tmpMeta90 = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _id, tmpMeta88, tmpMeta89, _tp, _umod, _comment, _cond, _info);
tmpMeta87 = mmc_mk_cons(tmpMeta90, _res);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = tmpMeta87;
goto tmp3_done;
}
case 4: {
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
modelica_metatype tmpMeta110;
modelica_metatype tmpMeta111;
modelica_metatype tmpMeta112;
modelica_metatype tmpMeta113;
modelica_metatype tmpMeta114;
modelica_metatype tmpMeta115;
modelica_metatype tmpMeta116;
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta91 = MMC_CAR(tmp4_3);
tmpMeta92 = MMC_CDR(tmp4_3);
tmpMeta93 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta91), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta93,3,8) == 0) goto tmp3_end;
tmpMeta94 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta93), 2));
tmpMeta95 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta93), 3));
tmpMeta96 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta95), 3));
tmpMeta97 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta95), 5));
tmpMeta98 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta95), 6));
tmpMeta99 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta93), 4));
tmpMeta100 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta99), 2));
tmpMeta101 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta99), 3));
tmpMeta102 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta99), 4));
tmpMeta103 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta99), 7));
tmpMeta104 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta93), 5));
tmpMeta105 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta93), 6));
tmpMeta106 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta93), 7));
tmpMeta107 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta93), 8));
tmpMeta108 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta93), 9));
tmpMeta109 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta91), 2));
_id = tmpMeta94;
_redecl = tmpMeta96;
_io = tmpMeta97;
_repl = tmpMeta98;
_d = tmpMeta100;
_ct = tmpMeta101;
_prl = tmpMeta102;
_isf = tmpMeta103;
_tp = tmpMeta104;
_mod = tmpMeta105;
_comment = tmpMeta106;
_cond = tmpMeta107;
_info = tmpMeta108;
_cmod = tmpMeta109;
_rest = tmpMeta92;
_cache = tmp4_1;
_env = tmp4_2;
tmpMeta110 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta111 = mmc_mk_box2(3, &Mod_ModScope_COMPONENT__desc, _id);
_cache = omc_Mod_elabMod(threadData, _cache, _env, tmpMeta110, _OMC_LIT6, _mod, 1, tmpMeta111, _info ,&_mod_1);
_mod_1 = omc_Mod_merge(threadData, _mods, _mod_1, _OMC_LIT7, 1);
_compMod = omc_Mod_lookupCompModification(threadData, _mod_1, _id);
_fullMod = _mod_1;
_selectedMod = omc_Lookup_selectModifier(threadData, _compMod, _fullMod);
tmpMeta112 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_Mod_updateMod(threadData, _cache, _env, tmpMeta112, _OMC_LIT6, _cmod, 1, _info ,&_cmod);
_selectedMod = omc_Mod_merge(threadData, _cmod, _selectedMod, _OMC_LIT7, 1);
_umod = omc_Mod_unelabMod(threadData, _selectedMod);
_cache = omc_Lookup_buildRecordConstructorElts(threadData, _cache, _env, _rest, _mods ,&_env ,&_res);
_var = _OMC_LIT59;
_vis = _OMC_LIT51;
_f = _OMC_LIT53;
_dir = _OMC_LIT67;
tmpMeta114 = mmc_mk_box6(3, &SCode_Prefixes_PREFIXES__desc, _vis, _redecl, _f, _io, _repl);
tmpMeta115 = mmc_mk_box7(3, &SCode_Attributes_ATTR__desc, _d, _ct, _prl, _var, _dir, _isf);
tmpMeta116 = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _id, tmpMeta114, tmpMeta115, _tp, _umod, _comment, _cond, _info);
tmpMeta113 = mmc_mk_cons(tmpMeta116, _res);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = tmpMeta113;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta117;
modelica_metatype tmpMeta118;
modelica_metatype tmpMeta119;
modelica_metatype tmpMeta120;
modelica_boolean tmp121;
modelica_metatype tmpMeta122;
modelica_metatype tmpMeta123;
modelica_metatype tmpMeta124;
modelica_metatype tmpMeta125;
modelica_metatype tmpMeta126;
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta117 = MMC_CAR(tmp4_3);
tmpMeta118 = MMC_CDR(tmp4_3);
tmpMeta119 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta117), 1));
tmpMeta120 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta117), 2));
_comp = tmpMeta119;
_cmod = tmpMeta120;
tmp121 = omc_Flags_isSet(threadData, _OMC_LIT30);
if (1 != tmp121) goto goto_2;
tmpMeta122 = stringAppend(_OMC_LIT68,omc_SCodeDump_unparseElementStr(threadData, _comp, _OMC_LIT69));
tmpMeta123 = stringAppend(tmpMeta122,_OMC_LIT70);
tmpMeta124 = stringAppend(tmpMeta123,omc_Mod_printModStr(threadData, _cmod));
tmpMeta125 = stringAppend(tmpMeta124,_OMC_LIT71);
tmpMeta126 = stringAppend(tmpMeta125,omc_Mod_printModStr(threadData, _mods));
omc_Debug_traceln(threadData, tmpMeta126);
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
_outEnv = tmpMeta[0+1];
_outSCodeElementLst = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outSCodeElementLst) { *out_outSCodeElementLst = _outSCodeElementLst; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_selectModifier(threadData_t *threadData, modelica_metatype _inModID, modelica_metatype _inModNoID)
{
modelica_metatype _outMod = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inModID;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,0) == 0) goto tmp3_end;
tmpMeta1 = _inModNoID;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _inModID;
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
return _outMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_buildRecordConstructorClass2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _cl, modelica_metatype _mods, modelica_metatype *out_outEnv, modelica_metatype *out_funcelts, modelica_metatype *out_elts)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _funcelts = NULL;
modelica_metatype _elts = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _cl;
{
modelica_metatype _cdefelts = NULL;
modelica_metatype _classExtendsElts = NULL;
modelica_metatype _extendsElts = NULL;
modelica_metatype _compElts = NULL;
modelica_metatype _eltsMods = NULL;
modelica_string _name = NULL;
modelica_metatype _fpath = NULL;
modelica_metatype _info = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _env1 = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,8) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 9));
_name = tmpMeta6;
_info = tmpMeta7;
_cache = tmp4_1;
_env = tmp4_2;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_InstExtends_instDerivedClasses(threadData, _cache, _env, tmpMeta8, _OMC_LIT5, _OMC_LIT6, _cl, 1, _info ,&_env ,NULL ,&_elts ,NULL ,NULL ,NULL ,NULL ,NULL, NULL);
_env = omc_FGraph_openScope(threadData, _env, _OMC_LIT1, _name, _OMC_LIT3);
_fpath = omc_FGraph_getGraphName(threadData, _env);
_cdefelts = omc_InstUtil_splitElts(threadData, _elts ,&_classExtendsElts ,&_extendsElts ,&_compElts);
tmpMeta9 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta10 = mmc_mk_box2(6, &ClassInf_State_RECORD__desc, _fpath);
_cache = omc_InstExtends_instExtendsAndClassExtendsList(threadData, _cache, _env, tmpMeta9, _OMC_LIT5, _OMC_LIT6, _extendsElts, _classExtendsElts, _elts, tmpMeta10, _name, 1, 0 ,&_env ,NULL ,NULL ,&_eltsMods ,NULL ,NULL ,NULL ,NULL, NULL);
_eltsMods = listAppend(_eltsMods, omc_InstUtil_addNomod(threadData, _compElts));
tmpMeta11 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_InstUtil_addClassdefsToEnv(threadData, _cache, _env, tmpMeta11, _OMC_LIT6, _cdefelts, 0, mmc_mk_none(), 0 ,&_env1 ,NULL);
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta13 = mmc_mk_box2(6, &ClassInf_State_RECORD__desc, _fpath);
_cache = omc_InstUtil_addComponentsToEnv(threadData, _cache, _env1, tmpMeta12, _mods, _OMC_LIT6, tmpMeta13, _eltsMods, 1 ,&_env1 ,NULL);
_cache = omc_Lookup_buildRecordConstructorElts(threadData, _cache, _env1, _eltsMods, _mods ,&_env1 ,&_funcelts);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env1;
tmpMeta[0+2] = _funcelts;
tmpMeta[0+3] = _elts;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
tmpMeta14 = stringAppend(_OMC_LIT72,omc_SCodeDump_unparseElementStr(threadData, _cl, _OMC_LIT69));
tmpMeta15 = stringAppend(tmpMeta14,_OMC_LIT73);
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
if (++tmp4 < 2) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outCache = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_funcelts = tmpMeta[0+2];
_elts = tmpMeta[0+3];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_funcelts) { *out_funcelts = _funcelts; }
if (out_elts) { *out_elts = _elts; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_buildRecordConstructorClass(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inClass, modelica_metatype *out_outEnv, modelica_metatype *out_outClass)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inClass;
{
modelica_metatype _funcelts = NULL;
modelica_metatype _reselt = NULL;
modelica_metatype _cl = NULL;
modelica_string _id = NULL;
modelica_metatype _info = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
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
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,8) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 9));
_cl = tmp4_3;
_id = tmpMeta6;
_info = tmpMeta7;
_cache = tmp4_1;
_env = tmp4_2;
_cache = omc_Lookup_buildRecordConstructorClass2(threadData, _cache, _env, _cl, _OMC_LIT5 ,&_env ,&_funcelts ,NULL);
tmpMeta8 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _id);
tmpMeta9 = mmc_mk_box3(3, &Absyn_TypeSpec_TPATH__desc, tmpMeta8, mmc_mk_none());
tmpMeta10 = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _OMC_LIT50, _OMC_LIT56, _OMC_LIT62, tmpMeta9, _OMC_LIT63, _OMC_LIT64, mmc_mk_none(), _info);
_reselt = tmpMeta10;
tmpMeta11 = mmc_mk_cons(_reselt, _funcelts);
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta13 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta14 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta15 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta16 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta17 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta18 = mmc_mk_box9(3, &SCode_ClassDef_PARTS__desc, tmpMeta11, tmpMeta12, tmpMeta13, tmpMeta14, tmpMeta15, tmpMeta16, tmpMeta17, mmc_mk_none());
tmpMeta19 = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _id, _OMC_LIT56, _OMC_LIT1, _OMC_LIT74, _OMC_LIT76, tmpMeta18, _OMC_LIT64, _info);
_cl = tmpMeta19;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = _cl;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp20;
tmp20 = omc_Flags_isSet(threadData, _OMC_LIT30);
if (1 != tmp20) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT77);
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
_outClass = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outClass) { *out_outClass = _outClass; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_buildRecordType(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _icdef, modelica_metatype *out_outEnv, modelica_metatype *out_ftype)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _ftype = NULL;
modelica_string _name = NULL;
modelica_metatype _env_1 = NULL;
modelica_metatype _cdef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCache = omc_Lookup_buildRecordConstructorClass(threadData, _cache, _env, _icdef ,NULL ,&_cdef);
_name = omc_SCodeUtil_className(threadData, _cdef);
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outCache = omc_InstFunction_implicitFunctionTypeInstantiation(threadData, _outCache, _env, tmpMeta1, _cdef ,&_outEnv ,NULL);
_outCache = omc_Lookup_lookupTypeInEnv(threadData, _outCache, _outEnv, _name ,&_ftype ,NULL);
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_ftype) { *out_ftype = _ftype; }
return _outCache;
}
DLLExport
modelica_metatype omc_Lookup_selectUpdatedEnv(threadData_t *threadData, modelica_metatype _inNewEnv, modelica_metatype _inOldEnv)
{
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta1;
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
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
tmp6 = omc_FGraph_isTopScope(threadData, _inNewEnv);
if (1 != tmp6) goto goto_2;
tmpMeta1 = _inOldEnv;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp7;
tmp7 = (stringEqual(omc_FGraph_getGraphNameStr(threadData, _inNewEnv), omc_FGraph_getGraphNameStr(threadData, _inOldEnv)));
if (1 != tmp7) goto goto_2;
tmpMeta1 = _inNewEnv;
goto tmp3_done;
}
case 2: {
tmpMeta1 = _inOldEnv;
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
_outEnv = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outEnv;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupFunctionsInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inClasses, modelica_metatype _inFuncTypes, modelica_metatype _inEnv, modelica_string _inFuncName, modelica_metatype _inInfo, modelica_metatype *out_outFuncTypes)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outFuncTypes = NULL;
modelica_metatype _r = NULL;
modelica_metatype _data = NULL;
modelica_metatype _ty = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
_r = omc_FCore_RefTree_get(threadData, _inFuncTypes, _inFuncName);
tmpMeta5 = omc_FNode_fromRef(threadData, _r);
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,7,1) == 0) goto goto_1;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_outFuncTypes = tmpMeta7;
_outCache = _inCache;
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
_r = omc_FCore_RefTree_get(threadData, _inClasses, _inFuncName);
tmpMeta8 = omc_FNode_fromRef(threadData, _r);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 6));
_data = tmpMeta9;
{
volatile modelica_metatype tmp13_1;
tmp13_1 = _data;
{
modelica_metatype _cl = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
volatile mmc_switch_type tmp13;
int tmp14;
tmp13 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp12_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp13 < 5; tmp13++) {
switch (MMC_SWITCH_CAST(tmp13)) {
case 0: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta24;
tmpMeta15 = omc_FNode_refInstVar(threadData, _r);
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 4));
_ty = tmpMeta16;
{
modelica_metatype tmp20_1;
tmp20_1 = _ty;
{
volatile mmc_switch_type tmp20;
int tmp21;
tmp20 = 0;
for (; tmp20 < 1; tmp20++) {
switch (MMC_SWITCH_CAST(tmp20)) {
case 0: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp20_1,11,4) == 0) goto tmp19_end;
tmpMeta23 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _inFuncName);
tmpMeta22 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta22), MMC_UNTAGPTR(_ty), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta22))[5] = tmpMeta23;
_ty = tmpMeta22;
tmpMeta17 = _ty;
goto tmp19_done;
}
}
goto tmp19_end;
tmp19_end: ;
}
goto goto_18;
goto_18:;
goto goto_11;
goto tmp19_done;
tmp19_done:;
}
}
_ty = tmpMeta17;
tmpMeta24 = mmc_mk_cons(_ty, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = tmpMeta24;
goto tmp12_done;
}
case 1: {
modelica_metatype tmpMeta25;
if (mmc__uniontype__metarecord__typedef__equal(tmp13_1,4,4) == 0) goto tmp12_end;
tmp13 += 3;
tmpMeta25 = mmc_mk_cons(_inFuncName, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT80, tmpMeta25, _inInfo);
goto goto_11;
goto tmp12_done;
}
case 2: {
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
if (mmc__uniontype__metarecord__typedef__equal(tmp13_1,3,5) == 0) goto tmp12_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp13_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,2,8) == 0) goto tmp12_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta27,3,1) == 0) goto tmp12_end;
_cl = tmpMeta26;
_cache = omc_Lookup_buildRecordType(threadData, _inCache, _inEnv, _cl ,NULL ,&_ty);
tmpMeta28 = mmc_mk_cons(_ty, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta28;
goto tmp12_done;
}
case 3: {
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
if (mmc__uniontype__metarecord__typedef__equal(tmp13_1,3,5) == 0) goto tmp12_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp13_1), 2));
_cl = tmpMeta29;
if (!omc_SCodeUtil_isFunction(threadData, _cl)) goto tmp12_end;
tmpMeta30 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_InstFunction_implicitFunctionTypeInstantiation(threadData, _inCache, _inEnv, tmpMeta30, _cl ,&_env, NULL);
tmpMeta31 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _inFuncName);
tmpMeta[0+0] = omc_Lookup_lookupFunctionsInEnv2(threadData, _cache, _env, tmpMeta31, 1, _inInfo, &tmpMeta[0+1]);
goto tmp12_done;
}
case 4: {
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
if (mmc__uniontype__metarecord__typedef__equal(tmp13_1,3,5) == 0) goto tmp12_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp13_1), 2));
_cl = tmpMeta32;
if (!omc_SCodeUtil_classIsExternalObject(threadData, _cl)) goto tmp12_end;
tmpMeta33 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta34 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_Inst_instClass(threadData, _inCache, _inEnv, tmpMeta33, _OMC_LIT4, _OMC_LIT5, _OMC_LIT6, _cl, tmpMeta34, 0, _OMC_LIT81, _OMC_LIT11, _OMC_LIT14 ,&_env, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
_cache = omc_Lookup_lookupTypeInEnv(threadData, _cache, _env, _inFuncName ,&_ty, NULL);
tmpMeta35 = mmc_mk_cons(_ty, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta35;
goto tmp12_done;
}
}
goto tmp12_end;
tmp12_end: ;
}
goto goto_11;
tmp12_done:
(void)tmp13;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp12_done2;
goto_11:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp13 < 5) {
goto tmp12_top;
}
goto goto_1;
tmp12_done2:;
}
}
_outCache = tmpMeta[0+0];
_outFuncTypes = tmpMeta[0+1];
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
if (out_outFuncTypes) { *out_outFuncTypes = _outFuncTypes; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupTypeInFrame2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _item, modelica_metatype _inEnv3, modelica_string _inIdent4, modelica_metatype *out_outType, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_string tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _item;
tmp4_3 = _inEnv3;
tmp4_4 = _inIdent4;
{
modelica_metatype _t = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _env = NULL;
modelica_metatype _cenv = NULL;
modelica_metatype _env_1 = NULL;
modelica_metatype _env_3 = NULL;
modelica_string _id = NULL;
modelica_metatype _cdef = NULL;
modelica_metatype _comp = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _info = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,7,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmpMeta7);
tmpMeta9 = MMC_CDR(tmpMeta7);
_t = tmpMeta8;
_cache = tmp4_1;
_env = tmp4_3;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _t;
tmpMeta[0+2] = _env;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,4,4) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_comp = tmpMeta11;
_id = tmp4_4;
_info = omc_SCodeUtil_elementInfo(threadData, _comp);
tmpMeta12 = mmc_mk_cons(_id, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT80, tmpMeta12, _info);
goto goto_2;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,3,5) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,2,8) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,3,1) == 0) goto tmp3_end;
_cdef = tmpMeta14;
_cache = tmp4_1;
_env = tmp4_3;
_cache = omc_Lookup_buildRecordType(threadData, _cache, _env, _cdef ,&_env_3 ,&_ty);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _ty;
tmpMeta[0+2] = _env_3;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,3,5) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,2,8) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,17,5) == 0) goto tmp3_end;
_cdef = tmpMeta17;
_cache = tmp4_1;
_env = tmp4_3;
_cache = omc_Lookup_buildMetaRecordType(threadData, _cache, _env, _cdef ,&_env_3 ,&_ty);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _ty;
tmpMeta[0+2] = _env_3;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta19,3,5) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,2,8) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta21,9,1) == 0) goto tmp3_end;
_cdef = tmpMeta20;
_cache = tmp4_1;
_env = tmp4_3;
_id = tmp4_4;
_cenv = _env;
tmpMeta22 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta23 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_InstFunction_implicitFunctionInstantiation(threadData, _cache, _cenv, tmpMeta22, _OMC_LIT5, _OMC_LIT6, _cdef, tmpMeta23 ,&_env_1 ,NULL);
tmpMeta[0+0] = omc_Lookup_lookupTypeInEnv(threadData, _cache, _env_1, _id, &tmpMeta[0+1], &tmpMeta[0+2]);
goto tmp3_done;
}
}
goto tmp3_end;
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
_outType = tmpMeta[0+1];
_outEnv = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outType) { *out_outType = _outType; }
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupTypeInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inBinTree1, modelica_metatype _inBinTree2, modelica_metatype _inEnv3, modelica_string _inIdent4, modelica_metatype *out_outType, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_string tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inBinTree2;
tmp4_3 = _inEnv3;
tmp4_4 = _inIdent4;
{
modelica_metatype _httypes = NULL;
modelica_metatype _env = NULL;
modelica_string _id = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _item = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_cache = tmp4_1;
_httypes = tmp4_2;
_env = tmp4_3;
_id = tmp4_4;
_item = omc_FNode_fromRef(threadData, omc_FCore_RefTree_get(threadData, _httypes, _id));
tmpMeta[0+0] = omc_Lookup_lookupTypeInFrame2(threadData, _cache, _item, _env, _id, &tmpMeta[0+1], &tmpMeta[0+2]);
goto tmp3_done;
}
}
goto tmp3_end;
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
_outType = tmpMeta[0+1];
_outEnv = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outType) { *out_outType = _outType; }
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_getHtTypes(threadData_t *threadData, modelica_metatype _inParentRef)
{
modelica_metatype _ht = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
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
_r = omc_FNode_child(threadData, _inParentRef, _OMC_LIT82);
tmpMeta1 = omc_FNode_children(threadData, omc_FNode_fromRef(threadData, _r));
goto tmp3_done;
}
case 1: {
tmpMeta1 = omc_FCore_RefTree_new(threadData);
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
_ht = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _ht;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupTypeInEnv(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_string _id, modelica_metatype *out_outType, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
{
modelica_metatype _c = NULL;
modelica_metatype _env_1 = NULL;
modelica_metatype _env = NULL;
modelica_metatype _httypes = NULL;
modelica_metatype _ht = NULL;
modelica_metatype _cache = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
_env = tmp4_2;
_r = tmpMeta7;
_cache = tmp4_1;
_ht = omc_FNode_children(threadData, omc_FNode_fromRef(threadData, _r));
_httypes = omc_Lookup_getHtTypes(threadData, _r);
tmpMeta[0+0] = omc_Lookup_lookupTypeInFrame(threadData, _cache, _ht, _httypes, _env, _id, &tmpMeta[0+1], &tmpMeta[0+2]);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
_env = tmp4_2;
_r = tmpMeta10;
_cache = tmp4_1;
_env = omc_FGraph_stripLastScopeRef(threadData, _env, NULL);
_cache = omc_Lookup_lookupTypeInEnv(threadData, _cache, _env, _id ,&_c ,&_env_1);
_env_1 = omc_FGraph_pushScopeRef(threadData, _env_1, _r);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _c;
tmpMeta[0+2] = _env_1;
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
_outType = tmpMeta[0+1];
_outEnv = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outType) { *out_outType = _outType; }
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_createGenericBuiltinFunctions(threadData_t *threadData, modelica_metatype _inEnv, modelica_string _inString)
{
modelica_metatype _outTypesTypeLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_string tmp4_1;
tmp4_1 = _inString;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (11 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT96), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT105;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outTypesTypeLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outTypesTypeLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupFunctionsInEnv2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inPath, modelica_boolean _followedQual, modelica_metatype _info, modelica_metatype *out_outTypesTypeLst)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outTypesTypeLst = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_boolean tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inPath;
tmp4_4 = _followedQual;
{
modelica_metatype _id = NULL;
modelica_metatype _path = NULL;
modelica_metatype _httypes = NULL;
modelica_metatype _ht = NULL;
modelica_metatype _res = NULL;
modelica_metatype _env = NULL;
modelica_metatype _env_1 = NULL;
modelica_metatype _env2 = NULL;
modelica_metatype _env_2 = NULL;
modelica_string _pack = NULL;
modelica_string _str = NULL;
modelica_metatype _c = NULL;
modelica_metatype _encflag = NULL;
modelica_metatype _restr = NULL;
modelica_metatype _ci_state = NULL;
modelica_metatype _r = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _mod = NULL;
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
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmpMeta7);
tmpMeta9 = MMC_CDR(tmpMeta7);
_str = tmpMeta6;
_r = tmpMeta8;
_cache = tmp4_1;
_ht = omc_FNode_children(threadData, omc_FNode_fromRef(threadData, _r));
_httypes = omc_Lookup_getHtTypes(threadData, _r);
tmpMeta13 = omc_Lookup_lookupFunctionsInFrame(threadData, _cache, _ht, _httypes, _inEnv, _str, _info, &tmpMeta10);
_cache = tmpMeta13;
if (listEmpty(tmpMeta10)) goto goto_2;
tmpMeta11 = MMC_CAR(tmpMeta10);
tmpMeta12 = MMC_CDR(tmpMeta10);
_res = tmpMeta10;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _res;
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
modelica_metatype tmpMeta32;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta14)) goto tmp3_end;
tmpMeta15 = MMC_CAR(tmpMeta14);
tmpMeta16 = MMC_CDR(tmpMeta14);
_id = tmp4_3;
_r = tmpMeta15;
_cache = tmp4_1;
tmp4 += 1;
tmpMeta21 = omc_Lookup_lookupClass(threadData, _cache, _inEnv, _id, mmc_mk_none(), &tmpMeta17, &tmpMeta20);
_cache = tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,2,8) == 0) goto goto_2;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 2));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 6));
_c = tmpMeta17;
_str = tmpMeta18;
_restr = tmpMeta19;
_env_1 = tmpMeta20;
tmp22 = omc_SCodeUtil_isFunctionRestriction(threadData, _restr);
if (1 != tmp22) goto goto_2;
tmpMeta27 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta28 = omc_InstFunction_implicitFunctionTypeInstantiation(threadData, _cache, _env_1, tmpMeta27, _c, &tmpMeta23, NULL);
_cache = tmpMeta28;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta23,0,2) == 0) goto goto_2;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 3));
if (listEmpty(tmpMeta24)) goto goto_2;
tmpMeta25 = MMC_CAR(tmpMeta24);
tmpMeta26 = MMC_CDR(tmpMeta24);
_env_2 = tmpMeta23;
_r = tmpMeta25;
_ht = omc_FNode_children(threadData, omc_FNode_fromRef(threadData, _r));
_httypes = omc_Lookup_getHtTypes(threadData, _r);
tmpMeta32 = omc_Lookup_lookupFunctionsInFrame(threadData, _cache, _ht, _httypes, _env_2, _str, _info, &tmpMeta29);
_cache = tmpMeta32;
if (listEmpty(tmpMeta29)) goto goto_2;
tmpMeta30 = MMC_CAR(tmpMeta29);
tmpMeta31 = MMC_CDR(tmpMeta29);
_res = tmpMeta29;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _res;
goto tmp3_done;
}
case 2: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,2) == 0) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta35)) goto tmp3_end;
tmpMeta36 = MMC_CAR(tmpMeta35);
tmpMeta37 = MMC_CDR(tmpMeta35);
_pack = tmpMeta33;
_path = tmpMeta34;
_r = tmpMeta36;
_cache = tmp4_1;
tmpMeta43 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _pack);
tmpMeta44 = omc_Lookup_lookupClass(threadData, _cache, _inEnv, tmpMeta43, mmc_mk_none(), &tmpMeta38, &tmpMeta42);
_cache = tmpMeta44;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta38,2,8) == 0) goto goto_2;
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta38), 2));
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta38), 4));
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta38), 6));
_c = tmpMeta38;
_str = tmpMeta39;
_encflag = tmpMeta40;
_restr = tmpMeta41;
_env_1 = tmpMeta42;
_r = omc_FNode_child(threadData, omc_FGraph_lastScopeRef(threadData, _env_1), _str);
if(omc_FNode_isRefInstance(threadData, _r))
{
_cache = omc_Inst_getCachedInstance(threadData, _cache, _env_1, _str, _r ,&_env2);
}
else
{
_env2 = omc_FGraph_openScope(threadData, _env_1, _encflag, _str, omc_FGraph_restrictionToScopeType(threadData, _restr));
_ci_state = omc_ClassInf_start(threadData, _restr, omc_FGraph_getGraphName(threadData, _env2));
_mod = omc_Mod_getClassModifier(threadData, _env_1, _str);
tmpMeta45 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta46 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_Inst_partialInstClassIn(threadData, _cache, _env2, tmpMeta45, _mod, _OMC_LIT6, _ci_state, _c, _OMC_LIT51, tmpMeta46, ((modelica_integer) 0) ,&_env2 ,NULL ,NULL ,NULL);
}
tmpMeta[0+0] = omc_Lookup_lookupFunctionsInEnv2(threadData, _cache, _env2, _path, 1, _info, &tmpMeta[0+1]);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_boolean tmp50;
if (0 != tmp4_4) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta47)) goto tmp3_end;
tmpMeta48 = MMC_CAR(tmpMeta47);
tmpMeta49 = MMC_CDR(tmpMeta47);
_r = tmpMeta48;
_cache = tmp4_1;
_id = tmp4_3;
tmp50 = omc_FNode_isEncapsulated(threadData, omc_FNode_fromRef(threadData, _r));
if (0 != tmp50) goto goto_2;
_env = omc_FGraph_stripLastScopeRef(threadData, _inEnv, NULL);
tmpMeta[0+0] = omc_Lookup_lookupFunctionsInEnv2(threadData, _cache, _env, _id, 0, _info, &tmpMeta[0+1]);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
modelica_boolean tmp54;
if (0 != tmp4_4) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta51)) goto tmp3_end;
tmpMeta52 = MMC_CAR(tmpMeta51);
tmpMeta53 = MMC_CDR(tmpMeta51);
_id = tmp4_3;
_r = tmpMeta52;
_cache = tmp4_1;
tmp54 = omc_FNode_isEncapsulated(threadData, omc_FNode_fromRef(threadData, _r));
if (1 != tmp54) goto goto_2;
_env = omc_FGraph_topScope(threadData, _inEnv);
tmpMeta[0+0] = omc_Lookup_lookupFunctionsInEnv2(threadData, _cache, _env, _id, 1, _info, &tmpMeta[0+1]);
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
_outTypesTypeLst = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outTypesTypeLst) { *out_outTypesTypeLst = _outTypesTypeLst; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Lookup_lookupFunctionsInEnv2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inPath, modelica_metatype _followedQual, modelica_metatype _info, modelica_metatype *out_outTypesTypeLst)
{
modelica_integer tmp1;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_followedQual);
_outCache = omc_Lookup_lookupFunctionsInEnv2(threadData, _inCache, _inEnv, _inPath, tmp1, _info, out_outTypesTypeLst);
return _outCache;
}
DLLExport
modelica_metatype omc_Lookup_lookupFunctionsListInEnv(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIds, modelica_metatype _info, modelica_metatype _inAcc, modelica_metatype *out_outTypesTypeLst)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outTypesTypeLst = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inIds;
tmp4_4 = _inAcc;
{
modelica_metatype _id = NULL;
modelica_metatype _res = NULL;
modelica_string _str = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _ids = NULL;
modelica_metatype _acc = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_3)) goto tmp3_end;
_cache = tmp4_1;
_acc = tmp4_4;
tmp4 += 2;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = listReverse(_acc);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_3);
tmpMeta7 = MMC_CDR(tmp4_3);
_id = tmpMeta6;
_ids = tmpMeta7;
_cache = tmp4_1;
_env = tmp4_2;
_acc = tmp4_4;
tmpMeta11 = omc_Lookup_lookupFunctionsInEnv(threadData, _cache, _env, _id, _info, &tmpMeta8);
_cache = tmpMeta11;
if (listEmpty(tmpMeta8)) goto goto_2;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
_res = tmpMeta8;
tmpMeta[0+0] = omc_Lookup_lookupFunctionsListInEnv(threadData, _cache, _env, _ids, _info, listAppend(_res, _acc), &tmpMeta[0+1]);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmp4_3);
tmpMeta13 = MMC_CDR(tmp4_3);
_id = tmpMeta12;
_env = tmp4_2;
tmpMeta14 = stringAppend(omc_AbsynUtil_pathString(threadData, _id, _OMC_LIT36, 1, 0),_OMC_LIT106);
tmpMeta15 = stringAppend(tmpMeta14,omc_FGraph_printGraphPathStr(threadData, _env));
_str = tmpMeta15;
tmpMeta16 = mmc_mk_cons(_str, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT109, tmpMeta16, _info);
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
_outTypesTypeLst = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outTypesTypeLst) { *out_outTypesTypeLst = _outTypesTypeLst; }
return _outCache;
}
DLLExport
modelica_metatype omc_Lookup_lookupFunctionsInEnv(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inId, modelica_metatype _inInfo, modelica_metatype *out_outTypesTypeLst)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outTypesTypeLst = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inId;
tmp4_4 = _inInfo;
{
modelica_metatype _env_1 = NULL;
modelica_metatype _cenv = NULL;
modelica_metatype _env = NULL;
modelica_metatype _res = NULL;
modelica_metatype _names = NULL;
modelica_metatype _httypes = NULL;
modelica_metatype _ht = NULL;
modelica_string _str = NULL;
modelica_string _name = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _id = NULL;
modelica_metatype _info = NULL;
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
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
_name = tmpMeta6;
_id = tmpMeta7;
_cache = tmp4_1;
_env = tmp4_2;
_info = tmp4_4;
omc_ErrorExt_setCheckpoint(threadData, _OMC_LIT110);
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_Lookup_lookupVarIdent(threadData, _cache, _env, _name, tmpMeta8 ,NULL ,NULL ,NULL ,NULL ,NULL ,NULL ,&_cenv ,NULL);
_cache = omc_Lookup_lookupFunctionsInEnv(threadData, _cache, _cenv, _id, _info ,&_res);
omc_ErrorExt_rollBack(threadData, _OMC_LIT110);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _res;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,2) == 0) goto tmp3_end;
omc_ErrorExt_rollBack(threadData, _OMC_LIT110);
goto goto_2;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta9;
_cache = tmp4_1;
_env = tmp4_2;
_id = tmp4_3;
_env = omc_FGraph_selectScope(threadData, _env, _id);
_name = omc_AbsynUtil_pathLastIdent(threadData, _id);
tmpMeta9 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _name);
tmpMeta[0+0] = omc_Lookup_lookupFunctionsInEnv(threadData, _cache, _env, tmpMeta9, _inInfo, &tmpMeta[0+1]);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
_str = tmpMeta10;
_cache = tmp4_1;
_env = tmp4_2;
_info = tmp4_4;
omc_Static_elabBuiltinHandler(threadData, _str);
_env = omc_FGraph_topScope(threadData, _env);
_ht = omc_FNode_children(threadData, omc_FNode_fromRef(threadData, omc_FGraph_lastScopeRef(threadData, _env)));
_httypes = omc_Lookup_getHtTypes(threadData, omc_FGraph_lastScopeRef(threadData, _env));
tmpMeta[0+0] = omc_Lookup_lookupFunctionsInFrame(threadData, _cache, _ht, _httypes, _env, _str, _info, &tmpMeta[0+1]);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (11 != MMC_STRLEN(tmpMeta11) || strcmp(MMC_STRINGDATA(_OMC_LIT96), MMC_STRINGDATA(tmpMeta11)) != 0) goto tmp3_end;
_str = tmpMeta11;
_cache = tmp4_1;
_env = tmp4_2;
_env = omc_FGraph_topScope(threadData, _env);
_res = omc_Lookup_createGenericBuiltinFunctions(threadData, _env, _str);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _res;
goto tmp3_done;
}
case 5: {
modelica_boolean tmp12;
modelica_metatype tmpMeta14;
_cache = tmp4_1;
_env = tmp4_2;
_id = tmp4_3;
_info = tmp4_4;
tmp12 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmpMeta14 = _id;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,2,1) == 0) goto goto_13;
tmp12 = 1;
goto goto_13;
goto_13:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp12) {goto goto_2;}
tmpMeta[0+0] = omc_Lookup_lookupFunctionsInEnv2(threadData, _cache, _env, _id, 0, _info, &tmpMeta[0+1]);
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
_id = tmpMeta15;
_cache = tmp4_1;
_env = tmp4_2;
_info = tmp4_4;
_env = omc_FGraph_topScope(threadData, _env);
tmpMeta[0+0] = omc_Lookup_lookupFunctionsInEnv2(threadData, _cache, _env, _id, 1, _info, &tmpMeta[0+1]);
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
_cache = tmp4_1;
_env = tmp4_2;
_id = tmp4_3;
{
modelica_metatype tmp19_1;
tmp19_1 = _id;
{
volatile mmc_switch_type tmp19;
int tmp20;
tmp19 = 0;
for (; tmp19 < 2; tmp19++) {
switch (MMC_SWITCH_CAST(tmp19)) {
case 0: {
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp19_1,1,1) == 0) goto tmp18_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp19_1), 2));
if (5 != MMC_STRLEN(tmpMeta21) || strcmp(MMC_STRINGDATA(_OMC_LIT117), MMC_STRINGDATA(tmpMeta21)) != 0) goto tmp18_end;
tmpMeta16 = _OMC_LIT116;
goto tmp18_done;
}
case 1: {
tmpMeta16 = _id;
goto tmp18_done;
}
}
goto tmp18_end;
tmp18_end: ;
}
goto goto_17;
goto_17:;
goto goto_2;
goto tmp18_done;
tmp18_done:;
}
}
_id = tmpMeta16;
tmpMeta27 = omc_Lookup_lookupClass(threadData, _cache, _env, _id, mmc_mk_none(), &tmpMeta22, &tmpMeta26);
_cache = tmpMeta27;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta22,2,8) == 0) goto goto_2;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta23,4,1) == 0) goto goto_2;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 2));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 9));
_names = tmpMeta24;
_info = tmpMeta25;
_env_1 = tmpMeta26;
tmpMeta28 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = omc_Lookup_lookupFunctionsListInEnv(threadData, _cache, _env_1, _names, _info, tmpMeta28, &tmpMeta[0+1]);
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta29;
_cache = tmp4_1;
tmpMeta29 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta29;
goto tmp3_done;
}
case 9: {
modelica_boolean tmp30;
modelica_metatype tmpMeta31;
_id = tmp4_3;
tmp30 = omc_Flags_isSet(threadData, _OMC_LIT30);
if (1 != tmp30) goto goto_2;
tmpMeta31 = stringAppend(_OMC_LIT118,omc_AbsynUtil_pathString(threadData, _id, _OMC_LIT36, 1, 0));
omc_Debug_traceln(threadData, tmpMeta31);
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
_outTypesTypeLst = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outTypesTypeLst) { *out_outTypesTypeLst = _outTypesTypeLst; }
return _outCache;
}
DLLExport
modelica_metatype omc_Lookup_lookupIdent(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_string _inIdent, modelica_metatype *out_outVar, modelica_metatype *out_outElement, modelica_metatype *out_outMod, modelica_metatype *out_instStatus, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outVar = NULL;
modelica_metatype _outElement = NULL;
modelica_metatype _outMod = NULL;
modelica_metatype _instStatus = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_string tmp4_3;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inIdent;
{
modelica_metatype _fv = NULL;
modelica_metatype _c = NULL;
modelica_metatype _m = NULL;
modelica_metatype _i = NULL;
modelica_metatype _ht = NULL;
modelica_string _id = NULL;
modelica_metatype _e = NULL;
modelica_metatype _cache = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
_r = tmpMeta7;
_cache = tmp4_1;
_id = tmp4_3;
_ht = omc_FNode_children(threadData, omc_FNode_fromRef(threadData, _r));
_fv = omc_Lookup_lookupVar2(threadData, _ht, _id, _inEnv ,&_c ,&_m ,&_i ,NULL);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _fv;
tmpMeta[0+2] = _c;
tmpMeta[0+3] = _m;
tmpMeta[0+4] = _i;
tmpMeta[0+5] = _inEnv;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
_cache = tmp4_1;
_id = tmp4_3;
_e = omc_FGraph_stripLastScopeRef(threadData, _inEnv, NULL);
tmpMeta[0+0] = omc_Lookup_lookupIdent(threadData, _cache, _e, _id, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3], &tmpMeta[0+4], &tmpMeta[0+5]);
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
_outVar = tmpMeta[0+1];
_outElement = tmpMeta[0+2];
_outMod = tmpMeta[0+3];
_instStatus = tmpMeta[0+4];
_outEnv = tmpMeta[0+5];
_return: OMC_LABEL_UNUSED
if (out_outVar) { *out_outVar = _outVar; }
if (out_outElement) { *out_outElement = _outElement; }
if (out_outMod) { *out_outMod = _outMod; }
if (out_instStatus) { *out_instStatus = _instStatus; }
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
DLLExport
modelica_metatype omc_Lookup_lookupClassLocal(threadData_t *threadData, modelica_metatype _inEnv, modelica_string _inIdent, modelica_metatype *out_outEnv)
{
modelica_metatype _outClass = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_string tmp4_2;
tmp4_1 = _inEnv;
tmp4_2 = _inIdent;
{
modelica_metatype _cl = NULL;
modelica_metatype _env = NULL;
modelica_metatype _ht = NULL;
modelica_string _id = NULL;
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
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
_env = tmp4_1;
_r = tmpMeta7;
_id = tmp4_2;
_ht = omc_FNode_children(threadData, omc_FNode_fromRef(threadData, _r));
_r = omc_FCore_RefTree_get(threadData, _ht, _id);
tmpMeta9 = omc_FNode_fromRef(threadData, _r);
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,3,5) == 0) goto goto_2;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_cl = tmpMeta11;
tmpMeta[0+0] = _cl;
tmpMeta[0+1] = _env;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outClass = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outClass;
}
DLLExport
modelica_metatype omc_Lookup_lookupIdentLocal(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_string _inIdent, modelica_metatype *out_outVar, modelica_metatype *out_outElement, modelica_metatype *out_outMod, modelica_metatype *out_instStatus, modelica_metatype *out_outComponentEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outVar = NULL;
modelica_metatype _outElement = NULL;
modelica_metatype _outMod = NULL;
modelica_metatype _instStatus = NULL;
modelica_metatype _outComponentEnv = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_string tmp4_3;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inIdent;
{
modelica_metatype _fv = NULL;
modelica_metatype _c = NULL;
modelica_metatype _m = NULL;
modelica_metatype _i = NULL;
modelica_metatype _r = NULL;
modelica_metatype _env = NULL;
modelica_metatype _componentEnv = NULL;
modelica_metatype _ht = NULL;
modelica_string _id = NULL;
modelica_metatype _cache = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
_r = tmpMeta7;
_cache = tmp4_1;
_id = tmp4_3;
_ht = omc_FNode_children(threadData, omc_FNode_fromRef(threadData, _r));
_fv = omc_Lookup_lookupVar2(threadData, _ht, _id, _inEnv ,&_c ,&_m ,&_i ,&_componentEnv);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _fv;
tmpMeta[0+2] = _c;
tmpMeta[0+3] = _m;
tmpMeta[0+4] = _i;
tmpMeta[0+5] = _componentEnv;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_boolean tmp12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
_r = tmpMeta10;
_cache = tmp4_1;
_id = tmp4_3;
tmp12 = omc_FNode_isImplicitRefName(threadData, _r);
if (1 != tmp12) goto goto_2;
_env = omc_FGraph_stripLastScopeRef(threadData, _inEnv, NULL);
tmpMeta[0+0] = omc_Lookup_lookupIdentLocal(threadData, _cache, _env, _id, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3], &tmpMeta[0+4], &tmpMeta[0+5]);
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
_outVar = tmpMeta[0+1];
_outElement = tmpMeta[0+2];
_outMod = tmpMeta[0+3];
_instStatus = tmpMeta[0+4];
_outComponentEnv = tmpMeta[0+5];
_return: OMC_LABEL_UNUSED
if (out_outVar) { *out_outVar = _outVar; }
if (out_outElement) { *out_outElement = _outElement; }
if (out_outMod) { *out_outMod = _outMod; }
if (out_instStatus) { *out_instStatus = _instStatus; }
if (out_outComponentEnv) { *out_outComponentEnv = _outComponentEnv; }
return _outCache;
}
DLLExport
modelica_metatype omc_Lookup_lookupVarLocal(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inComponentRef, modelica_metatype *out_outAttributes, modelica_metatype *out_outType, modelica_metatype *out_outBinding, modelica_metatype *out_constOfForIteratorRange, modelica_metatype *out_splicedExpData, modelica_metatype *out_outClassEnv, modelica_metatype *out_outComponentEnv, modelica_string *out_name)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outAttributes = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _outBinding = NULL;
modelica_metatype _constOfForIteratorRange = NULL;
modelica_metatype _splicedExpData = NULL;
modelica_metatype _outClassEnv = NULL;
modelica_metatype _outComponentEnv = NULL;
modelica_string _name = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCache = omc_Lookup_lookupVarInternal(threadData, _inCache, _inEnv, _inComponentRef, _OMC_LIT119 ,&_outAttributes ,&_outType ,&_outBinding ,&_constOfForIteratorRange ,&_splicedExpData ,&_outClassEnv ,&_outComponentEnv ,&_name);
_return: OMC_LABEL_UNUSED
if (out_outAttributes) { *out_outAttributes = _outAttributes; }
if (out_outType) { *out_outType = _outType; }
if (out_outBinding) { *out_outBinding = _outBinding; }
if (out_constOfForIteratorRange) { *out_constOfForIteratorRange = _constOfForIteratorRange; }
if (out_splicedExpData) { *out_splicedExpData = _splicedExpData; }
if (out_outClassEnv) { *out_outClassEnv = _outClassEnv; }
if (out_outComponentEnv) { *out_outComponentEnv = _outComponentEnv; }
if (out_name) { *out_name = _name; }
return _outCache;
}
DLLExport
modelica_metatype omc_Lookup_lookupVarInPackagesIdent(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_string _id, modelica_metatype _ss, modelica_metatype _inPrevFrames, modelica_metatype _inState, modelica_metatype *out_outClassEnv, modelica_metatype *out_outAttributes, modelica_metatype *out_outType, modelica_metatype *out_outBinding, modelica_metatype *out_constOfForIteratorRange, modelica_metatype *out_splicedExpData, modelica_metatype *out_outComponentEnv, modelica_string *out_name)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outClassEnv = NULL;
modelica_metatype _outAttributes = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _outBinding = NULL;
modelica_metatype _constOfForIteratorRange = NULL;
modelica_metatype _splicedExpData = NULL;
modelica_metatype _outComponentEnv = NULL;
modelica_string _name = NULL;
modelica_string tmp1_c8 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inPrevFrames;
{
modelica_metatype _env = NULL;
modelica_metatype _p_env = NULL;
modelica_metatype _componentEnv = NULL;
modelica_metatype _prevFrames = NULL;
modelica_metatype _fs = NULL;
modelica_metatype _node = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _bind = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _f = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _cnstForRange = NULL;
modelica_boolean _unique;
modelica_metatype _ht = NULL;
modelica_metatype _qimports = NULL;
modelica_metatype _uqimports = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_cache = tmp4_1;
_env = tmp4_2;
_cache = omc_Lookup_lookupVarInternalIdent(threadData, _cache, _env, _id, _ss, _OMC_LIT119 ,&_attr ,&_ty ,&_bind ,&_cnstForRange ,&_splicedExpData ,NULL ,&_componentEnv ,&_name);
omc_Mutable_update(threadData, _inState, mmc_mk_boolean(1));
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = _attr;
tmpMeta[0+3] = _ty;
tmpMeta[0+4] = _bind;
tmpMeta[0+5] = _cnstForRange;
tmpMeta[0+6] = _splicedExpData;
tmpMeta[0+7] = _componentEnv;
tmp1_c8 = _name;
goto tmp3_done;
}
case 1: {
_cache = tmp4_1;
_env = tmp4_2;
_ht = omc_FNode_children(threadData, omc_FNode_fromRef(threadData, omc_FGraph_lastScopeRef(threadData, _env)));
_cache = omc_Lookup_lookupVarFIdent(threadData, _cache, _ht, _id, _ss, _env ,&_attr ,&_ty ,&_bind ,&_cnstForRange ,&_splicedExpData ,&_componentEnv ,&_name);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = _attr;
tmpMeta[0+3] = _ty;
tmpMeta[0+4] = _bind;
tmpMeta[0+5] = _cnstForRange;
tmpMeta[0+6] = _splicedExpData;
tmpMeta[0+7] = _componentEnv;
tmp1_c8 = _name;
goto tmp3_done;
}
case 2: {
_cache = tmp4_1;
_env = tmp4_2;
_prevFrames = tmp4_3;
_node = omc_FNode_fromRef(threadData, omc_FGraph_lastScopeRef(threadData, _env));
_qimports = omc_FNode_imports(threadData, _node ,&_uqimports);
{
volatile modelica_metatype tmp8_1;volatile modelica_metatype tmp8_2;
tmp8_1 = _qimports;
tmp8_2 = _uqimports;
{
volatile mmc_switch_type tmp8;
int tmp9;
tmp8 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp7_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp8 < 2; tmp8++) {
switch (MMC_SWITCH_CAST(tmp8)) {
case 0: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (listEmpty(tmp8_1)) goto tmp7_end;
tmpMeta10 = MMC_CAR(tmp8_1);
tmpMeta11 = MMC_CDR(tmp8_1);
_cr = omc_Lookup_lookupQualifiedImportedVarInFrame(threadData, _qimports, _id);
omc_Mutable_update(threadData, _inState, mmc_mk_boolean(1));
_cr = ((stringEqual(omc_FNode_name(threadData, omc_FNode_fromRef(threadData, omc_FGraph_lastScopeRef(threadData, _env))), omc_ComponentReference_crefFirstIdent(threadData, _cr)))?omc_ComponentReference_crefStripFirstIdent(threadData, _cr):_cr);
tmpMeta12 = listReverse(omc_FGraph_currentScope(threadData, _env));
if (listEmpty(tmpMeta12)) goto goto_6;
tmpMeta13 = MMC_CAR(tmpMeta12);
tmpMeta14 = MMC_CDR(tmpMeta12);
_f = tmpMeta13;
_prevFrames = tmpMeta14;
tmpMeta15 = mmc_mk_cons(_f, MMC_REFSTRUCTLIT(mmc_nil));
_env = omc_FGraph_setScope(threadData, _env, tmpMeta15);
_cache = omc_Lookup_lookupVarInPackages(threadData, _cache, _env, _cr, _prevFrames, _inState ,&_p_env ,&_attr ,&_ty ,&_bind ,&_cnstForRange ,&_splicedExpData ,&_componentEnv ,&_name);
goto tmp7_done;
}
case 1: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (listEmpty(tmp8_2)) goto tmp7_end;
tmpMeta16 = MMC_CAR(tmp8_2);
tmpMeta17 = MMC_CDR(tmp8_2);
_cache = omc_Lookup_lookupUnqualifiedImportedVarInFrame(threadData, _cache, _uqimports, _env, _id ,&_p_env ,&_attr ,&_ty ,&_bind ,&_cnstForRange ,&_unique ,&_splicedExpData ,&_componentEnv ,&_name);
omc_Lookup_reportSeveralNamesError(threadData, _unique, _id);
omc_Mutable_update(threadData, _inState, mmc_mk_boolean(1));
goto tmp7_done;
}
}
goto tmp7_end;
tmp7_end: ;
}
goto goto_6;
tmp7_done:
(void)tmp8;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp7_done2;
goto_6:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp8 < 2) {
goto tmp7_top;
}
goto goto_2;
tmp7_done2:;
}
}
;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _p_env;
tmpMeta[0+2] = _attr;
tmpMeta[0+3] = _ty;
tmpMeta[0+4] = _bind;
tmpMeta[0+5] = _cnstForRange;
tmpMeta[0+6] = _splicedExpData;
tmpMeta[0+7] = _componentEnv;
tmp1_c8 = _name;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_integer tmp22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta18)) goto tmp3_end;
tmpMeta19 = MMC_CAR(tmpMeta18);
tmpMeta20 = MMC_CDR(tmpMeta18);
_f = tmpMeta19;
_fs = tmpMeta20;
_cache = tmp4_1;
_prevFrames = tmp4_3;
tmpMeta21 = omc_Mutable_access(threadData, _inState);
tmp22 = mmc_unbox_integer(tmpMeta21);
if (0 != tmp22) goto goto_2;
_env = omc_FGraph_setScope(threadData, _inEnv, _fs);
tmpMeta23 = mmc_mk_cons(_f, _prevFrames);
tmpMeta[0+0] = omc_Lookup_lookupVarInPackagesIdent(threadData, _cache, _env, _id, _ss, tmpMeta23, _inState, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3], &tmpMeta[0+4], &tmpMeta[0+5], &tmpMeta[0+6], &tmpMeta[0+7], &tmp1_c8);
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
_outClassEnv = tmpMeta[0+1];
_outAttributes = tmpMeta[0+2];
_outType = tmpMeta[0+3];
_outBinding = tmpMeta[0+4];
_constOfForIteratorRange = tmpMeta[0+5];
_splicedExpData = tmpMeta[0+6];
_outComponentEnv = tmpMeta[0+7];
_name = tmp1_c8;
_return: OMC_LABEL_UNUSED
if (out_outClassEnv) { *out_outClassEnv = _outClassEnv; }
if (out_outAttributes) { *out_outAttributes = _outAttributes; }
if (out_outType) { *out_outType = _outType; }
if (out_outBinding) { *out_outBinding = _outBinding; }
if (out_constOfForIteratorRange) { *out_constOfForIteratorRange = _constOfForIteratorRange; }
if (out_splicedExpData) { *out_splicedExpData = _splicedExpData; }
if (out_outComponentEnv) { *out_outComponentEnv = _outComponentEnv; }
if (out_name) { *out_name = _name; }
return _outCache;
}
DLLExport
modelica_metatype omc_Lookup_lookupVarInPackages(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inComponentRef, modelica_metatype _inPrevFrames, modelica_metatype _inState, modelica_metatype *out_outClassEnv, modelica_metatype *out_outAttributes, modelica_metatype *out_outType, modelica_metatype *out_outBinding, modelica_metatype *out_constOfForIteratorRange, modelica_metatype *out_splicedExpData, modelica_metatype *out_outComponentEnv, modelica_string *out_name)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outClassEnv = NULL;
modelica_metatype _outAttributes = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _outBinding = NULL;
modelica_metatype _constOfForIteratorRange = NULL;
modelica_metatype _splicedExpData = NULL;
modelica_metatype _outComponentEnv = NULL;
modelica_string _name = NULL;
modelica_string tmp1_c8 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inComponentRef;
tmp4_4 = _inPrevFrames;
{
modelica_metatype _c = NULL;
modelica_string _n = NULL;
modelica_string _id = NULL;
modelica_metatype _encflag = NULL;
modelica_metatype _r = NULL;
modelica_metatype _env2 = NULL;
modelica_metatype _env3 = NULL;
modelica_metatype _env5 = NULL;
modelica_metatype _env = NULL;
modelica_metatype _p_env = NULL;
modelica_metatype _componentEnv = NULL;
modelica_metatype _prevFrames = NULL;
modelica_metatype _fs = NULL;
modelica_metatype _ci_state = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _bind = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _f = NULL;
modelica_metatype _rr = NULL;
modelica_metatype _of = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _cnstForRange = NULL;
modelica_metatype _ht = NULL;
modelica_metatype _mod = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
if (!listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 5));
_id = tmpMeta6;
_cref = tmpMeta8;
_cache = tmp4_1;
_env = tmp4_2;
_prevFrames = tmp4_4;
tmp4 += 1;
_of = omc_Lookup_lookupPrevFrames(threadData, _id, _prevFrames ,&_prevFrames);
{
modelica_metatype tmp11_1;
tmp11_1 = _of;
{
volatile mmc_switch_type tmp11;
int tmp12;
tmp11 = 0;
for (; tmp11 < 2; tmp11++) {
switch (MMC_SWITCH_CAST(tmp11)) {
case 0: {
modelica_metatype tmpMeta13;
if (optionNone(tmp11_1)) goto tmp10_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp11_1), 1));
_f = tmpMeta13;
omc_Mutable_update(threadData, _inState, mmc_mk_boolean(1));
_env5 = omc_FGraph_pushScopeRef(threadData, _env, _f);
goto tmp10_done;
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
if (!optionNone(tmp11_1)) goto tmp10_end;
tmpMeta20 = omc_Lookup_lookupClassInEnv(threadData, _cache, _env, _id, _prevFrames, omc_Mutable_create(threadData, mmc_mk_boolean(1)), mmc_mk_none(), &tmpMeta14, &tmpMeta18, &tmpMeta19);
_cache = tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,2,8) == 0) goto goto_9;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 4));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 6));
_c = tmpMeta14;
_n = tmpMeta15;
_encflag = tmpMeta16;
_r = tmpMeta17;
_env2 = tmpMeta18;
_prevFrames = tmpMeta19;
omc_Mutable_update(threadData, _inState, mmc_mk_boolean(1));
_rr = omc_FNode_child(threadData, omc_FGraph_lastScopeRef(threadData, _env2), _id);
if(omc_FNode_isRefInstance(threadData, _rr))
{
_cache = omc_Inst_getCachedInstance(threadData, _cache, _env2, _id, _rr ,&_env5);
}
else
{
_env3 = omc_FGraph_openScope(threadData, _env2, _encflag, _n, omc_FGraph_restrictionToScopeType(threadData, _r));
_ci_state = omc_ClassInf_start(threadData, _r, omc_FGraph_getGraphName(threadData, _env3));
_mod = omc_Mod_getClassModifier(threadData, _env2, _n);
tmpMeta21 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta22 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_Inst_instClassIn(threadData, _cache, _env3, tmpMeta21, _OMC_LIT4, _mod, _OMC_LIT6, _ci_state, _c, _OMC_LIT51, tmpMeta22, 0, _OMC_LIT10, _OMC_LIT11, _OMC_LIT14, mmc_mk_none() ,&_env5 ,NULL ,NULL ,NULL ,NULL ,NULL ,NULL ,NULL ,NULL ,NULL ,NULL);
}
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
_cache = omc_Lookup_lookupVarInPackages(threadData, _cache, _env5, _cref, _prevFrames, _inState ,&_p_env ,&_attr ,&_ty ,&_bind ,&_cnstForRange ,&_splicedExpData ,&_componentEnv ,&_name);
_splicedExpData = omc_Lookup_prefixSplicedExp(threadData, omc_ComponentReference_crefFirstCref(threadData, _inComponentRef), _splicedExpData);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _p_env;
tmpMeta[0+2] = _attr;
tmpMeta[0+3] = _ty;
tmpMeta[0+4] = _bind;
tmpMeta[0+5] = _cnstForRange;
tmpMeta[0+6] = _splicedExpData;
tmpMeta[0+7] = _componentEnv;
tmp1_c8 = _name;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,3) == 0) goto tmp3_end;
_cr = tmp4_3;
_cache = tmp4_1;
_env = tmp4_2;
tmp4 += 2;
tmpMeta[0+0] = omc_Lookup_lookupVarInPackagesIdent(threadData, _cache, _env, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr), 4))), _inPrevFrames, _inState, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3], &tmpMeta[0+4], &tmpMeta[0+5], &tmpMeta[0+6], &tmpMeta[0+7], &tmp1_c8);
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,4) == 0) goto tmp3_end;
_cr = tmp4_3;
_cache = tmp4_1;
_env = tmp4_2;
_ht = omc_FNode_children(threadData, omc_FNode_fromRef(threadData, omc_FGraph_lastScopeRef(threadData, _env)));
_cache = omc_Lookup_lookupVarF(threadData, _cache, _ht, _cr, _env ,&_attr ,&_ty ,&_bind ,&_cnstForRange ,&_splicedExpData ,&_componentEnv ,&_name);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = _attr;
tmpMeta[0+3] = _ty;
tmpMeta[0+4] = _bind;
tmpMeta[0+5] = _cnstForRange;
tmpMeta[0+6] = _splicedExpData;
tmpMeta[0+7] = _componentEnv;
tmp1_c8 = _name;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_integer tmp27;
modelica_metatype tmpMeta28;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta23)) goto tmp3_end;
tmpMeta24 = MMC_CAR(tmpMeta23);
tmpMeta25 = MMC_CDR(tmpMeta23);
_cr = tmp4_3;
_f = tmpMeta24;
_fs = tmpMeta25;
_cache = tmp4_1;
_prevFrames = tmp4_4;
tmpMeta26 = omc_Mutable_access(threadData, _inState);
tmp27 = mmc_unbox_integer(tmpMeta26);
if (0 != tmp27) goto goto_2;
_env = omc_FGraph_setScope(threadData, _inEnv, _fs);
tmpMeta28 = mmc_mk_cons(_f, _prevFrames);
tmpMeta[0+0] = omc_Lookup_lookupVarInPackages(threadData, _cache, _env, _cr, tmpMeta28, _inState, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3], &tmpMeta[0+4], &tmpMeta[0+5], &tmpMeta[0+6], &tmpMeta[0+7], &tmp1_c8);
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
_outClassEnv = tmpMeta[0+1];
_outAttributes = tmpMeta[0+2];
_outType = tmpMeta[0+3];
_outBinding = tmpMeta[0+4];
_constOfForIteratorRange = tmpMeta[0+5];
_splicedExpData = tmpMeta[0+6];
_outComponentEnv = tmpMeta[0+7];
_name = tmp1_c8;
_return: OMC_LABEL_UNUSED
if (out_outClassEnv) { *out_outClassEnv = _outClassEnv; }
if (out_outAttributes) { *out_outAttributes = _outAttributes; }
if (out_outType) { *out_outType = _outType; }
if (out_outBinding) { *out_outBinding = _outBinding; }
if (out_constOfForIteratorRange) { *out_constOfForIteratorRange = _constOfForIteratorRange; }
if (out_splicedExpData) { *out_splicedExpData = _splicedExpData; }
if (out_outComponentEnv) { *out_outComponentEnv = _outComponentEnv; }
if (out_name) { *out_name = _name; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_Lookup_frameIsImplAddedScope(threadData_t *threadData, modelica_metatype _f)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _f;
{
modelica_string _oname = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_oname = tmpMeta6;
tmp1 = omc_FCore_isImplicitScope(threadData, _oname);
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Lookup_frameIsImplAddedScope(threadData_t *threadData, modelica_metatype _f)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_Lookup_frameIsImplAddedScope(threadData, _f);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_metatype omc_Lookup_lookupVarInternalIdent(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_string _ident, modelica_metatype _ss, modelica_metatype _searchStrategy, modelica_metatype *out_outAttributes, modelica_metatype *out_outType, modelica_metatype *out_outBinding, modelica_metatype *out_constOfForIteratorRange, modelica_metatype *out_splicedExpData, modelica_metatype *out_outClassEnv, modelica_metatype *out_outComponentEnv, modelica_string *out_name)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outAttributes = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _outBinding = NULL;
modelica_metatype _constOfForIteratorRange = NULL;
modelica_metatype _splicedExpData = NULL;
modelica_metatype _outClassEnv = NULL;
modelica_metatype _outComponentEnv = NULL;
modelica_string _name = NULL;
modelica_string tmp1_c8 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _searchStrategy;
{
modelica_metatype _attr = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _binding = NULL;
modelica_metatype _ht = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _cnstForRange = NULL;
modelica_metatype _env = NULL;
modelica_metatype _componentEnv = NULL;
modelica_metatype _r = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
_r = tmpMeta7;
_cache = tmp4_1;
_ht = omc_FNode_children(threadData, omc_FNode_fromRef(threadData, _r));
_cache = omc_Lookup_lookupVarFIdent(threadData, _cache, _ht, _ident, _ss, _inEnv ,&_attr ,&_ty ,&_binding ,&_cnstForRange ,&_splicedExpData ,&_componentEnv ,&_name);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _attr;
tmpMeta[0+2] = _ty;
tmpMeta[0+3] = _binding;
tmpMeta[0+4] = _cnstForRange;
tmpMeta[0+5] = _splicedExpData;
tmpMeta[0+6] = _inEnv;
tmpMeta[0+7] = _componentEnv;
tmp1_c8 = _name;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_boolean tmp12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
_r = tmpMeta10;
_cache = tmp4_1;
tmp12 = omc_FNode_isImplicitRefName(threadData, _r);
if (1 != tmp12) goto goto_2;
_env = omc_FGraph_stripLastScopeRef(threadData, _inEnv, NULL);
tmpMeta[0+0] = omc_Lookup_lookupVarInternalIdent(threadData, _cache, _env, _ident, _ss, _searchStrategy, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3], &tmpMeta[0+4], &tmpMeta[0+5], &tmpMeta[0+6], &tmpMeta[0+7], &tmp1_c8);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_boolean tmp18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta13)) goto tmp3_end;
tmpMeta14 = MMC_CAR(tmpMeta13);
tmpMeta15 = MMC_CDR(tmpMeta13);
if (listEmpty(tmpMeta15)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmpMeta15);
tmpMeta17 = MMC_CDR(tmpMeta15);
_cache = tmp4_1;
tmp18 = omc_Builtin_variableNameIsBuiltin(threadData, _ident);
if (1 != tmp18) goto goto_2;
_env = omc_FGraph_topScope(threadData, _inEnv);
_ht = omc_FNode_children(threadData, omc_FNode_fromRef(threadData, omc_FGraph_lastScopeRef(threadData, _env)));
_cache = omc_Lookup_lookupVarFIdent(threadData, _cache, _ht, _ident, _ss, _env ,&_attr ,&_ty ,&_binding ,&_cnstForRange ,&_splicedExpData ,&_componentEnv ,&_name);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _attr;
tmpMeta[0+2] = _ty;
tmpMeta[0+3] = _binding;
tmpMeta[0+4] = _cnstForRange;
tmpMeta[0+5] = _splicedExpData;
tmpMeta[0+6] = _env;
tmpMeta[0+7] = _componentEnv;
tmp1_c8 = _name;
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
_outAttributes = tmpMeta[0+1];
_outType = tmpMeta[0+2];
_outBinding = tmpMeta[0+3];
_constOfForIteratorRange = tmpMeta[0+4];
_splicedExpData = tmpMeta[0+5];
_outClassEnv = tmpMeta[0+6];
_outComponentEnv = tmpMeta[0+7];
_name = tmp1_c8;
_return: OMC_LABEL_UNUSED
if (out_outAttributes) { *out_outAttributes = _outAttributes; }
if (out_outType) { *out_outType = _outType; }
if (out_outBinding) { *out_outBinding = _outBinding; }
if (out_constOfForIteratorRange) { *out_constOfForIteratorRange = _constOfForIteratorRange; }
if (out_splicedExpData) { *out_splicedExpData = _splicedExpData; }
if (out_outClassEnv) { *out_outClassEnv = _outClassEnv; }
if (out_outComponentEnv) { *out_outComponentEnv = _outComponentEnv; }
if (out_name) { *out_name = _name; }
return _outCache;
}
DLLExport
modelica_metatype omc_Lookup_lookupVarInternal(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inComponentRef, modelica_metatype _searchStrategy, modelica_metatype *out_outAttributes, modelica_metatype *out_outType, modelica_metatype *out_outBinding, modelica_metatype *out_constOfForIteratorRange, modelica_metatype *out_splicedExpData, modelica_metatype *out_outClassEnv, modelica_metatype *out_outComponentEnv, modelica_string *out_name)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outAttributes = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _outBinding = NULL;
modelica_metatype _constOfForIteratorRange = NULL;
modelica_metatype _splicedExpData = NULL;
modelica_metatype _outClassEnv = NULL;
modelica_metatype _outComponentEnv = NULL;
modelica_string _name = NULL;
modelica_string tmp1_c8 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inComponentRef;
tmp4_4 = _searchStrategy;
{
modelica_metatype _attr = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _binding = NULL;
modelica_metatype _ht = NULL;
modelica_metatype _ref = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _cnstForRange = NULL;
modelica_metatype _env = NULL;
modelica_metatype _componentEnv = NULL;
modelica_metatype _r = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
_r = tmpMeta7;
_cache = tmp4_1;
_ref = tmp4_3;
_ht = omc_FNode_children(threadData, omc_FNode_fromRef(threadData, _r));
_cache = omc_Lookup_lookupVarF(threadData, _cache, _ht, _ref, _inEnv ,&_attr ,&_ty ,&_binding ,&_cnstForRange ,&_splicedExpData ,&_componentEnv ,&_name);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _attr;
tmpMeta[0+2] = _ty;
tmpMeta[0+3] = _binding;
tmpMeta[0+4] = _cnstForRange;
tmpMeta[0+5] = _splicedExpData;
tmpMeta[0+6] = _inEnv;
tmpMeta[0+7] = _componentEnv;
tmp1_c8 = _name;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_boolean tmp12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
_r = tmpMeta10;
_cache = tmp4_1;
_ref = tmp4_3;
tmp12 = omc_FNode_isImplicitRefName(threadData, _r);
if (1 != tmp12) goto goto_2;
_env = omc_FGraph_stripLastScopeRef(threadData, _inEnv, NULL);
tmpMeta[0+0] = omc_Lookup_lookupVarInternal(threadData, _cache, _env, _ref, _searchStrategy, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3], &tmpMeta[0+4], &tmpMeta[0+5], &tmpMeta[0+6], &tmpMeta[0+7], &tmp1_c8);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_boolean tmp18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,1,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta13)) goto tmp3_end;
tmpMeta14 = MMC_CAR(tmpMeta13);
tmpMeta15 = MMC_CDR(tmpMeta13);
if (listEmpty(tmpMeta15)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmpMeta15);
tmpMeta17 = MMC_CDR(tmpMeta15);
_cache = tmp4_1;
_ref = tmp4_3;
tmp18 = omc_Builtin_variableIsBuiltin(threadData, _ref);
if (1 != tmp18) goto goto_2;
_env = omc_FGraph_topScope(threadData, _inEnv);
_ht = omc_FNode_children(threadData, omc_FNode_fromRef(threadData, omc_FGraph_lastScopeRef(threadData, _env)));
_cache = omc_Lookup_lookupVarF(threadData, _cache, _ht, _ref, _env ,&_attr ,&_ty ,&_binding ,&_cnstForRange ,&_splicedExpData ,&_componentEnv ,&_name);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _attr;
tmpMeta[0+2] = _ty;
tmpMeta[0+3] = _binding;
tmpMeta[0+4] = _cnstForRange;
tmpMeta[0+5] = _splicedExpData;
tmpMeta[0+6] = _env;
tmpMeta[0+7] = _componentEnv;
tmp1_c8 = _name;
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
_outAttributes = tmpMeta[0+1];
_outType = tmpMeta[0+2];
_outBinding = tmpMeta[0+3];
_constOfForIteratorRange = tmpMeta[0+4];
_splicedExpData = tmpMeta[0+5];
_outClassEnv = tmpMeta[0+6];
_outComponentEnv = tmpMeta[0+7];
_name = tmp1_c8;
_return: OMC_LABEL_UNUSED
if (out_outAttributes) { *out_outAttributes = _outAttributes; }
if (out_outType) { *out_outType = _outType; }
if (out_outBinding) { *out_outBinding = _outBinding; }
if (out_constOfForIteratorRange) { *out_constOfForIteratorRange = _constOfForIteratorRange; }
if (out_splicedExpData) { *out_splicedExpData = _splicedExpData; }
if (out_outClassEnv) { *out_outClassEnv = _outClassEnv; }
if (out_outComponentEnv) { *out_outComponentEnv = _outComponentEnv; }
if (out_name) { *out_name = _name; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC void omc_Lookup_checkPackageVariableConstant(threadData_t *threadData, modelica_metatype _parentEnv, modelica_metatype _classEnv, modelica_metatype _componentEnv, modelica_metatype _attr, modelica_metatype _tp, modelica_metatype _cref)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _attr;
{
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
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
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta5,3,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_boolean tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
_s1 = omc_ComponentReference_printComponentRefStr(threadData, _cref);
_s2 = omc_FGraph_printGraphPathStr(threadData, _classEnv);
tmpMeta6 = mmc_mk_cons(_s1, mmc_mk_cons(_s2, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addMessage(threadData, _OMC_LIT122, tmpMeta6);
tmp7 = omc_Flags_isSet(threadData, _OMC_LIT30);
if (1 != tmp7) goto goto_1;
tmpMeta8 = stringAppend(_OMC_LIT123,_s1);
tmpMeta9 = stringAppend(tmpMeta8,_OMC_LIT124);
tmpMeta10 = stringAppend(tmpMeta9,_s2);
omc_Debug_traceln(threadData, tmpMeta10);
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
DLLExport
modelica_metatype omc_Lookup_lookupVarIdent(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_string _ident, modelica_metatype _ss, modelica_metatype *out_outAttributes, modelica_metatype *out_outType, modelica_metatype *out_outBinding, modelica_metatype *out_constOfForIteratorRange, modelica_metatype *out_outSplicedExpData, modelica_metatype *out_outClassEnv, modelica_metatype *out_outComponentEnv, modelica_string *out_name)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outAttributes = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _outBinding = NULL;
modelica_metatype _constOfForIteratorRange = NULL;
modelica_metatype _outSplicedExpData = NULL;
modelica_metatype _outClassEnv = NULL;
modelica_metatype _outComponentEnv = NULL;
modelica_string _name = NULL;
modelica_string tmp1_c8 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
{
modelica_metatype _attr = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _binding = NULL;
modelica_metatype _env = NULL;
modelica_metatype _componentEnv = NULL;
modelica_metatype _classEnv = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _splicedExpData = NULL;
modelica_metatype _cnstForRange = NULL;
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
_env = tmp4_2;
tmpMeta[0+0] = omc_Lookup_lookupVarInternalIdent(threadData, _cache, _env, _ident, _ss, _OMC_LIT125, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3], &tmpMeta[0+4], &tmpMeta[0+5], &tmpMeta[0+6], &tmpMeta[0+7], &tmp1_c8);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
_cache = tmp4_1;
_env = tmp4_2;
_cref = omc_ComponentReference_makeCrefIdent(threadData, _ident, _OMC_LIT126, _ss);
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_Lookup_lookupVarInPackages(threadData, _cache, _env, _cref, tmpMeta6, omc_Mutable_create(threadData, mmc_mk_boolean(0)) ,&_classEnv ,&_attr ,&_ty ,&_binding ,&_cnstForRange ,&_splicedExpData ,&_componentEnv ,&_name);
omc_Lookup_checkPackageVariableConstant(threadData, _env, _classEnv, _componentEnv, _attr, _ty, _cref);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _attr;
tmpMeta[0+2] = _ty;
tmpMeta[0+3] = _binding;
tmpMeta[0+4] = _cnstForRange;
tmpMeta[0+5] = _splicedExpData;
tmpMeta[0+6] = _classEnv;
tmpMeta[0+7] = _componentEnv;
tmp1_c8 = _name;
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
_outAttributes = tmpMeta[0+1];
_outType = tmpMeta[0+2];
_outBinding = tmpMeta[0+3];
_constOfForIteratorRange = tmpMeta[0+4];
_outSplicedExpData = tmpMeta[0+5];
_outClassEnv = tmpMeta[0+6];
_outComponentEnv = tmpMeta[0+7];
_name = tmp1_c8;
_return: OMC_LABEL_UNUSED
if (out_outAttributes) { *out_outAttributes = _outAttributes; }
if (out_outType) { *out_outType = _outType; }
if (out_outBinding) { *out_outBinding = _outBinding; }
if (out_constOfForIteratorRange) { *out_constOfForIteratorRange = _constOfForIteratorRange; }
if (out_outSplicedExpData) { *out_outSplicedExpData = _outSplicedExpData; }
if (out_outClassEnv) { *out_outClassEnv = _outClassEnv; }
if (out_outComponentEnv) { *out_outComponentEnv = _outComponentEnv; }
if (out_name) { *out_name = _name; }
return _outCache;
}
DLLExport
modelica_metatype omc_Lookup_lookupVar(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inComponentRef, modelica_metatype *out_outAttributes, modelica_metatype *out_outType, modelica_metatype *out_outBinding, modelica_metatype *out_constOfForIteratorRange, modelica_metatype *out_outSplicedExpData, modelica_metatype *out_outClassEnv, modelica_metatype *out_outComponentEnv, modelica_string *out_name)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outAttributes = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _outBinding = NULL;
modelica_metatype _constOfForIteratorRange = NULL;
modelica_metatype _outSplicedExpData = NULL;
modelica_metatype _outClassEnv = NULL;
modelica_metatype _outComponentEnv = NULL;
modelica_string _name = NULL;
modelica_string tmp1_c8 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inComponentRef;
{
modelica_metatype _attr = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _binding = NULL;
modelica_metatype _env = NULL;
modelica_metatype _componentEnv = NULL;
modelica_metatype _classEnv = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _splicedExpData = NULL;
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
_cache = tmp4_1;
_env = tmp4_2;
_cref = tmp4_3;
tmpMeta[0+0] = omc_Lookup_lookupVarInternal(threadData, _cache, _env, _cref, _OMC_LIT125, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3], &tmpMeta[0+4], &tmpMeta[0+5], &tmpMeta[0+6], &tmpMeta[0+7], &tmp1_c8);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
_cache = tmp4_1;
_env = tmp4_2;
_cref = tmp4_3;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_Lookup_lookupVarInPackages(threadData, _cache, _env, _cref, tmpMeta6, omc_Mutable_create(threadData, mmc_mk_boolean(0)) ,&_classEnv ,&_attr ,&_ty ,&_binding ,&_cnstForRange ,&_splicedExpData ,&_componentEnv ,&_name);
omc_Lookup_checkPackageVariableConstant(threadData, _env, _classEnv, _componentEnv, _attr, _ty, _cref);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _attr;
tmpMeta[0+2] = _ty;
tmpMeta[0+3] = _binding;
tmpMeta[0+4] = _cnstForRange;
tmpMeta[0+5] = _splicedExpData;
tmpMeta[0+6] = _classEnv;
tmpMeta[0+7] = _componentEnv;
tmp1_c8 = _name;
goto tmp3_done;
}
case 2: {
_cache = tmp4_1;
_env = tmp4_2;
if (!omc_Config_getGraphicsExpMode(threadData)) goto tmp3_end;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _OMC_LIT129;
tmpMeta[0+2] = _OMC_LIT126;
tmpMeta[0+3] = _OMC_LIT130;
tmpMeta[0+4] = mmc_mk_none();
tmpMeta[0+5] = _OMC_LIT131;
tmpMeta[0+6] = _env;
tmpMeta[0+7] = _env;
tmp1_c8 = _OMC_LIT132;
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
_outAttributes = tmpMeta[0+1];
_outType = tmpMeta[0+2];
_outBinding = tmpMeta[0+3];
_constOfForIteratorRange = tmpMeta[0+4];
_outSplicedExpData = tmpMeta[0+5];
_outClassEnv = tmpMeta[0+6];
_outComponentEnv = tmpMeta[0+7];
_name = tmp1_c8;
_return: OMC_LABEL_UNUSED
if (out_outAttributes) { *out_outAttributes = _outAttributes; }
if (out_outType) { *out_outType = _outType; }
if (out_outBinding) { *out_outBinding = _outBinding; }
if (out_constOfForIteratorRange) { *out_constOfForIteratorRange = _constOfForIteratorRange; }
if (out_outSplicedExpData) { *out_outSplicedExpData = _outSplicedExpData; }
if (out_outClassEnv) { *out_outClassEnv = _outClassEnv; }
if (out_outComponentEnv) { *out_outComponentEnv = _outComponentEnv; }
if (out_name) { *out_name = _name; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupConnectorVar2(threadData_t *threadData, modelica_metatype _env, modelica_string _name, modelica_metatype *out_status, modelica_metatype *out_compEnv)
{
jmp_buf *old_mmc_jumper = threadData->mmc_jumper;
modelica_metatype _var = NULL;
modelica_metatype _status = NULL;
modelica_metatype _compEnv = NULL;
modelica_metatype _scope = NULL;
modelica_metatype _ht = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta9;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _env;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,0,2) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_scope = tmpMeta2;
{
modelica_metatype _r;
for (tmpMeta3 = _scope; !listEmpty(tmpMeta3); tmpMeta3=MMC_CDR(tmpMeta3))
{
_r = MMC_CAR(tmpMeta3);
_ht = omc_FNode_children(threadData, omc_FNode_fromRef(threadData, _r));
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
_var = omc_Lookup_lookupVar2(threadData, _ht, _name, _env ,NULL ,NULL ,&_status ,&_compEnv);
goto _return;
goto tmp5_done;
}
case 1: {
modelica_boolean tmp8;
tmp8 = omc_FNode_isImplicitRefName(threadData, _r);
if (1 != tmp8) goto goto_4;
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
MMC_THROW_INTERNAL();
_return: OMC_LABEL_UNUSED
if (out_status) { *out_status = _status; }
if (out_compEnv) { *out_compEnv = _compEnv; }
threadData->mmc_jumper = old_mmc_jumper;
return _var;
}
DLLExport
modelica_metatype omc_Lookup_lookupConnectorVar(threadData_t *threadData, modelica_metatype _env, modelica_metatype _cr, modelica_boolean _firstId, modelica_metatype *out_ty, modelica_metatype *out_status, modelica_boolean *out_isExpandable)
{
modelica_metatype _attr = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _status = NULL;
modelica_boolean _isExpandable;
modelica_metatype _comp_env = NULL;
modelica_metatype _parent_attr = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_isExpandable = 0;
{
modelica_metatype tmp4_1;
tmp4_1 = _cr;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta7 = omc_Lookup_lookupConnectorVar2(threadData, _env, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr), 2))), &tmpMeta6, NULL);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
_attr = tmpMeta8;
_ty = tmpMeta9;
_status = tmpMeta6;
_ty = omc_Lookup_checkSubscripts(threadData, _ty, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr), 4))));
tmpMeta[0+0] = _attr;
tmpMeta[0+1] = _ty;
tmpMeta[0+2] = _status;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta12 = omc_Lookup_lookupConnectorVar2(threadData, _env, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr), 2))), &tmpMeta10, &tmpMeta11);
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 3));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 4));
_parent_attr = tmpMeta13;
_ty = tmpMeta14;
_status = tmpMeta10;
_comp_env = tmpMeta11;
if(omc_FCore_isDeletedComp(threadData, _status))
{
_attr = _parent_attr;
}
else
{
{
{
volatile mmc_switch_type tmp17;
int tmp18;
tmp17 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp16_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp17 < 2; tmp17++) {
switch (MMC_SWITCH_CAST(tmp17)) {
case 0: {
_attr = omc_Lookup_lookupConnectorVar(threadData, _comp_env, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr), 5))), 0 ,&_ty ,&_status ,&_isExpandable);
goto tmp16_done;
}
case 1: {
if(omc_Types_isExpandableConnector(threadData, _ty))
{
_attr = _parent_attr;
_isExpandable = 1;
}
else
{
goto goto_15;
}
goto tmp16_done;
}
}
goto tmp16_end;
tmp16_end: ;
}
goto goto_15;
tmp16_done:
(void)tmp17;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp16_done2;
goto_15:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp17 < 2) {
goto tmp16_top;
}
goto goto_2;
tmp16_done2:;
}
}
;
_attr = omc_DAEUtil_setAttrVariability(threadData, _attr, omc_SCodeUtil_variabilityOr(threadData, omc_DAEUtil_getAttrVariability(threadData, _attr), omc_DAEUtil_getAttrVariability(threadData, _parent_attr)));
if(_firstId)
{
_attr = omc_DAEUtil_setAttrInnerOuter(threadData, _attr, omc_DAEUtil_getAttrInnerOuter(threadData, _parent_attr));
}
}
tmpMeta[0+0] = _attr;
tmpMeta[0+1] = _ty;
tmpMeta[0+2] = _status;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_attr = tmpMeta[0+0];
_ty = tmpMeta[0+1];
_status = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_ty) { *out_ty = _ty; }
if (out_status) { *out_status = _status; }
if (out_isExpandable) { *out_isExpandable = _isExpandable; }
return _attr;
}
modelica_metatype boxptr_Lookup_lookupConnectorVar(threadData_t *threadData, modelica_metatype _env, modelica_metatype _cr, modelica_metatype _firstId, modelica_metatype *out_ty, modelica_metatype *out_status, modelica_metatype *out_isExpandable)
{
modelica_integer tmp1;
modelica_boolean _isExpandable;
modelica_metatype _attr = NULL;
tmp1 = mmc_unbox_integer(_firstId);
_attr = omc_Lookup_lookupConnectorVar(threadData, _env, _cr, tmp1, out_ty, out_status, &_isExpandable);
if (out_isExpandable) { *out_isExpandable = mmc_mk_icon(_isExpandable); }
return _attr;
}
DLLExport
modelica_metatype omc_Lookup_lookupRecordConstructorClass(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inPath, modelica_metatype *out_outClass, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outClass = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inPath;
{
modelica_metatype _c = NULL;
modelica_metatype _env = NULL;
modelica_metatype _env_1 = NULL;
modelica_metatype _path = NULL;
modelica_metatype _cache = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
_cache = tmp4_1;
_env = tmp4_2;
_path = tmp4_3;
_cache = omc_Lookup_lookupClass(threadData, _cache, _env, _path, mmc_mk_none() ,&_c ,&_env_1);
tmpMeta6 = _c;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,2,8) == 0) goto goto_2;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,3,1) == 0) goto goto_2;
_cache = omc_Lookup_buildRecordConstructorClass(threadData, _cache, _env_1, _c ,NULL ,&_c);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _c;
tmpMeta[0+2] = _env_1;
goto tmp3_done;
}
}
goto tmp3_end;
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
_outClass = tmpMeta[0+1];
_outEnv = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outClass) { *out_outClass = _outClass; }
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupUnqualifiedImportedClassInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inImports, modelica_metatype _inEnv, modelica_string _inIdent, modelica_metatype _inInfo, modelica_metatype *out_outClass, modelica_metatype *out_outEnv, modelica_metatype *out_outPrevFrames, modelica_boolean *out_outBoolean)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outClass = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outPrevFrames = NULL;
modelica_boolean _outBoolean;
modelica_boolean tmp1_c4 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_string tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inImports;
tmp4_3 = _inEnv;
tmp4_4 = _inIdent;
{
modelica_metatype _r = NULL;
modelica_metatype _c = NULL;
modelica_metatype _c_1 = NULL;
modelica_string _id = NULL;
modelica_string _ident = NULL;
modelica_metatype _encflag = NULL;
modelica_boolean _more;
modelica_boolean _unique;
modelica_metatype _restr = NULL;
modelica_metatype _env_1 = NULL;
modelica_metatype _env2 = NULL;
modelica_metatype _env = NULL;
modelica_metatype _env3 = NULL;
modelica_metatype _prevFrames = NULL;
modelica_metatype _ci_state = NULL;
modelica_metatype _path = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _mod = NULL;
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
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,2,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_path = tmpMeta8;
_rest = tmpMeta7;
_cache = tmp4_1;
_env = tmp4_3;
_ident = tmp4_4;
tmpMeta9 = listReverse(omc_FGraph_currentScope(threadData, _env));
if (listEmpty(tmpMeta9)) goto goto_2;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
_r = tmpMeta10;
_prevFrames = tmpMeta11;
tmpMeta12 = mmc_mk_cons(_r, MMC_REFSTRUCTLIT(mmc_nil));
_env3 = omc_FGraph_setScope(threadData, _env, tmpMeta12);
tmpMeta19 = omc_Lookup_lookupClass2(threadData, _cache, _env3, _path, _prevFrames, omc_Mutable_create(threadData, mmc_mk_boolean(0)), _inInfo, &tmpMeta13, &tmpMeta17, &tmpMeta18);
_cache = tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,2,8) == 0) goto goto_2;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 4));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 6));
_c = tmpMeta13;
_id = tmpMeta14;
_encflag = tmpMeta15;
_restr = tmpMeta16;
_env_1 = tmpMeta17;
_prevFrames = tmpMeta18;
_env2 = omc_FGraph_openScope(threadData, _env_1, _encflag, _id, omc_FGraph_restrictionToScopeType(threadData, _restr));
_ci_state = omc_ClassInf_start(threadData, _restr, omc_FGraph_getGraphName(threadData, _env2));
_mod = omc_Mod_getClassModifier(threadData, _env_1, _id);
tmpMeta20 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta21 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_Inst_partialInstClassIn(threadData, _cache, _env2, tmpMeta20, _mod, _OMC_LIT6, _ci_state, _c, _OMC_LIT51, tmpMeta21, ((modelica_integer) 0) ,&_env2 ,NULL ,NULL ,NULL);
_cache = omc_Lookup_lookupClassInEnv(threadData, _cache, _env2, _ident, _prevFrames, omc_Mutable_create(threadData, mmc_mk_boolean(1)), _inInfo ,&_c_1 ,&_env2 ,&_prevFrames);
_cache = omc_Lookup_moreLookupUnqualifiedImportedClassInFrame(threadData, _cache, _rest, _env, _ident ,&_more);
_unique = (!_more);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _c_1;
tmpMeta[0+2] = _env2;
tmpMeta[0+3] = _prevFrames;
tmp1_c4 = _unique;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta22 = MMC_CAR(tmp4_2);
tmpMeta23 = MMC_CDR(tmp4_2);
_rest = tmpMeta23;
_cache = tmp4_1;
_env = tmp4_3;
_ident = tmp4_4;
tmpMeta[0+0] = omc_Lookup_lookupUnqualifiedImportedClassInFrame(threadData, _cache, _rest, _env, _ident, _inInfo, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3], &tmp1_c4);
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
_outClass = tmpMeta[0+1];
_outEnv = tmpMeta[0+2];
_outPrevFrames = tmpMeta[0+3];
_outBoolean = tmp1_c4;
_return: OMC_LABEL_UNUSED
if (out_outClass) { *out_outClass = _outClass; }
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outPrevFrames) { *out_outPrevFrames = _outPrevFrames; }
if (out_outBoolean) { *out_outBoolean = _outBoolean; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Lookup_lookupUnqualifiedImportedClassInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inImports, modelica_metatype _inEnv, modelica_metatype _inIdent, modelica_metatype _inInfo, modelica_metatype *out_outClass, modelica_metatype *out_outEnv, modelica_metatype *out_outPrevFrames, modelica_metatype *out_outBoolean)
{
modelica_boolean _outBoolean;
modelica_metatype _outCache = NULL;
_outCache = omc_Lookup_lookupUnqualifiedImportedClassInFrame(threadData, _inCache, _inImports, _inEnv, _inIdent, _inInfo, out_outClass, out_outEnv, out_outPrevFrames, &_outBoolean);
if (out_outBoolean) { *out_outBoolean = mmc_mk_icon(_outBoolean); }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_moreLookupUnqualifiedImportedClassInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inImports, modelica_metatype _inEnv, modelica_string _inIdent, modelica_boolean *out_outBoolean)
{
modelica_metatype _outCache = NULL;
modelica_boolean _outBoolean;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_string tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inImports;
tmp4_3 = _inEnv;
tmp4_4 = _inIdent;
{
modelica_metatype _c = NULL;
modelica_string _id = NULL;
modelica_string _ident = NULL;
modelica_metatype _encflag = NULL;
modelica_metatype _restr = NULL;
modelica_metatype _env_1 = NULL;
modelica_metatype _env2 = NULL;
modelica_metatype _env = NULL;
modelica_metatype _ci_state = NULL;
modelica_metatype _path = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _r = NULL;
modelica_metatype _mod = NULL;
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
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,2,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_path = tmpMeta8;
_cache = tmp4_1;
_env = tmp4_3;
_ident = tmp4_4;
_env = omc_FGraph_topScope(threadData, _env);
tmpMeta14 = omc_Lookup_lookupClass(threadData, _cache, _env, _path, mmc_mk_none(), &tmpMeta9, &tmpMeta13);
_cache = tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,2,8) == 0) goto goto_2;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 6));
_c = tmpMeta9;
_id = tmpMeta10;
_encflag = tmpMeta11;
_restr = tmpMeta12;
_env_1 = tmpMeta13;
_env2 = omc_FGraph_openScope(threadData, _env_1, _encflag, _id, omc_FGraph_restrictionToScopeType(threadData, _restr));
_ci_state = omc_ClassInf_start(threadData, _restr, omc_FGraph_getGraphName(threadData, _env2));
_mod = omc_Mod_getClassModifier(threadData, _env_1, _id);
tmpMeta15 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta16 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_Inst_partialInstClassIn(threadData, _cache, _env2, tmpMeta15, _mod, _OMC_LIT6, _ci_state, _c, _OMC_LIT51, tmpMeta16, ((modelica_integer) 0) ,&_env ,NULL ,NULL ,NULL);
_r = omc_FGraph_lastScopeRef(threadData, _env);
tmpMeta17 = mmc_mk_cons(_r, MMC_REFSTRUCTLIT(mmc_nil));
_env = omc_FGraph_setScope(threadData, _env, tmpMeta17);
tmpMeta18 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _ident);
_cache = omc_Lookup_lookupClass(threadData, _cache, _env, tmpMeta18, mmc_mk_none(), NULL, NULL);
tmpMeta[0+0] = _cache;
tmp1_c1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta19 = MMC_CAR(tmp4_2);
tmpMeta20 = MMC_CDR(tmp4_2);
_rest = tmpMeta20;
_cache = tmp4_1;
_env = tmp4_3;
_ident = tmp4_4;
tmp4 += 1;
tmpMeta[0+0] = omc_Lookup_moreLookupUnqualifiedImportedClassInFrame(threadData, _cache, _rest, _env, _ident, &tmp1_c1);
goto tmp3_done;
}
case 2: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
_cache = tmp4_1;
tmpMeta[0+0] = _cache;
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
_outCache = tmpMeta[0+0];
_outBoolean = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_outBoolean) { *out_outBoolean = _outBoolean; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Lookup_moreLookupUnqualifiedImportedClassInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inImports, modelica_metatype _inEnv, modelica_metatype _inIdent, modelica_metatype *out_outBoolean)
{
modelica_boolean _outBoolean;
modelica_metatype _outCache = NULL;
_outCache = omc_Lookup_moreLookupUnqualifiedImportedClassInFrame(threadData, _inCache, _inImports, _inEnv, _inIdent, &_outBoolean);
if (out_outBoolean) { *out_outBoolean = mmc_mk_icon(_outBoolean); }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupQualifiedImportedClassInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inImport, modelica_metatype _inEnv, modelica_string _inIdent, modelica_metatype _inState, modelica_metatype _inInfo, modelica_metatype *out_outClass, modelica_metatype *out_outEnv, modelica_metatype *out_outPrevFrames)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outClass = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outPrevFrames = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_string tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inImport;
tmp4_3 = _inEnv;
tmp4_4 = _inIdent;
{
modelica_metatype _r = NULL;
modelica_metatype _env = NULL;
modelica_metatype _prevFrames = NULL;
modelica_string _id = NULL;
modelica_string _ident = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _path = NULL;
modelica_metatype _cache = NULL;
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
modelica_boolean tmp10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
_id = tmpMeta9;
_cache = tmp4_1;
_env = tmp4_3;
_ident = tmp4_4;
tmp10 = (stringEqual(_id, _ident));
if (1 != tmp10) goto goto_2;
omc_Mutable_update(threadData, _inState, mmc_mk_boolean(1));
tmpMeta11 = listReverse(omc_FGraph_currentScope(threadData, _env));
if (listEmpty(tmpMeta11)) goto goto_2;
tmpMeta12 = MMC_CAR(tmpMeta11);
tmpMeta13 = MMC_CDR(tmpMeta11);
_r = tmpMeta12;
_prevFrames = tmpMeta13;
tmpMeta14 = mmc_mk_cons(_r, MMC_REFSTRUCTLIT(mmc_nil));
_env = omc_FGraph_setScope(threadData, _env, tmpMeta14);
tmpMeta[0+0] = omc_Lookup_lookupClassInEnv(threadData, _cache, _env, _id, _prevFrames, omc_Mutable_create(threadData, mmc_mk_boolean(0)), _inInfo, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3]);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_boolean tmp18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta15 = MMC_CAR(tmp4_2);
tmpMeta16 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,1,1) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
_path = tmpMeta17;
_cache = tmp4_1;
_env = tmp4_3;
_ident = tmp4_4;
tmp4 += 1;
_id = omc_AbsynUtil_pathLastIdent(threadData, _path);
tmp18 = (stringEqual(_id, _ident));
if (1 != tmp18) goto goto_2;
omc_Mutable_update(threadData, _inState, mmc_mk_boolean(1));
tmpMeta19 = listReverse(omc_FGraph_currentScope(threadData, _env));
if (listEmpty(tmpMeta19)) goto goto_2;
tmpMeta20 = MMC_CAR(tmpMeta19);
tmpMeta21 = MMC_CDR(tmpMeta19);
_r = tmpMeta20;
_prevFrames = tmpMeta21;
tmpMeta22 = mmc_mk_cons(_r, MMC_REFSTRUCTLIT(mmc_nil));
_env = omc_FGraph_setScope(threadData, _env, tmpMeta22);
tmpMeta[0+0] = omc_Lookup_lookupClass2(threadData, _cache, _env, _path, _prevFrames, omc_Mutable_create(threadData, mmc_mk_boolean(0)), _inInfo, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3]);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_boolean tmp27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta23 = MMC_CAR(tmp4_2);
tmpMeta24 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta23,0,2) == 0) goto tmp3_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 2));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 3));
_id = tmpMeta25;
_path = tmpMeta26;
_cache = tmp4_1;
_env = tmp4_3;
_ident = tmp4_4;
tmp27 = (stringEqual(_id, _ident));
if (1 != tmp27) goto goto_2;
omc_Mutable_update(threadData, _inState, mmc_mk_boolean(1));
tmpMeta28 = listReverse(omc_FGraph_currentScope(threadData, _env));
if (listEmpty(tmpMeta28)) goto goto_2;
tmpMeta29 = MMC_CAR(tmpMeta28);
tmpMeta30 = MMC_CDR(tmpMeta28);
_r = tmpMeta29;
_prevFrames = tmpMeta30;
tmpMeta31 = mmc_mk_cons(_r, MMC_REFSTRUCTLIT(mmc_nil));
_env = omc_FGraph_setScope(threadData, _env, tmpMeta31);
tmpMeta[0+0] = omc_Lookup_lookupClass2(threadData, _cache, _env, _path, _prevFrames, omc_Mutable_create(threadData, mmc_mk_boolean(0)), _inInfo, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3]);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta32 = MMC_CAR(tmp4_2);
tmpMeta33 = MMC_CDR(tmp4_2);
_rest = tmpMeta33;
_cache = tmp4_1;
_env = tmp4_3;
_ident = tmp4_4;
tmpMeta[0+0] = omc_Lookup_lookupQualifiedImportedClassInFrame(threadData, _cache, _rest, _env, _ident, _inState, _inInfo, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3]);
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
_outClass = tmpMeta[0+1];
_outEnv = tmpMeta[0+2];
_outPrevFrames = tmpMeta[0+3];
_return: OMC_LABEL_UNUSED
if (out_outClass) { *out_outClass = _outClass; }
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outPrevFrames) { *out_outPrevFrames = _outPrevFrames; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupUnqualifiedImportedVarInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inImports, modelica_metatype _inEnv, modelica_string _inIdent, modelica_metatype *out_outClassEnv, modelica_metatype *out_outAttributes, modelica_metatype *out_outType, modelica_metatype *out_outBinding, modelica_metatype *out_constOfForIteratorRange, modelica_boolean *out_outBoolean, modelica_metatype *out_splicedExpData, modelica_metatype *out_outComponentEnv, modelica_string *out_name)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outClassEnv = NULL;
modelica_metatype _outAttributes = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _outBinding = NULL;
modelica_metatype _constOfForIteratorRange = NULL;
modelica_boolean _outBoolean;
modelica_metatype _splicedExpData = NULL;
modelica_metatype _outComponentEnv = NULL;
modelica_string _name = NULL;
modelica_boolean tmp1_c6 __attribute__((unused)) = 0;
modelica_string tmp1_c9 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[10] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_string tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inImports;
tmp4_3 = _inEnv;
tmp4_4 = _inIdent;
{
modelica_metatype _f = NULL;
modelica_metatype _cref = NULL;
modelica_string _ident = NULL;
modelica_boolean _more;
modelica_boolean _unique;
modelica_metatype _env = NULL;
modelica_metatype _classEnv = NULL;
modelica_metatype _componentEnv = NULL;
modelica_metatype _env2 = NULL;
modelica_metatype _prevFrames = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _bind = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _path = NULL;
modelica_metatype _cnstForRange = NULL;
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
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,2,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_path = tmpMeta8;
_rest = tmpMeta7;
_cache = tmp4_1;
_env = tmp4_3;
_ident = tmp4_4;
tmpMeta9 = listReverse(omc_FGraph_currentScope(threadData, _env));
if (listEmpty(tmpMeta9)) goto goto_2;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
_f = tmpMeta10;
_prevFrames = tmpMeta11;
_cref = omc_ComponentReference_pathToCref(threadData, _path);
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
_cref = omc_ComponentReference_crefPrependIdent(threadData, _cref, _ident, tmpMeta12, _OMC_LIT126);
tmpMeta13 = mmc_mk_cons(_f, MMC_REFSTRUCTLIT(mmc_nil));
_env2 = omc_FGraph_setScope(threadData, _env, tmpMeta13);
_cache = omc_Lookup_lookupVarInPackages(threadData, _cache, _env2, _cref, _prevFrames, omc_Mutable_create(threadData, mmc_mk_boolean(0)) ,&_classEnv ,&_attr ,&_ty ,&_bind ,&_cnstForRange ,&_splicedExpData ,&_componentEnv ,&_name);
_cache = omc_Lookup_moreLookupUnqualifiedImportedVarInFrame(threadData, _cache, _rest, _env, _ident ,&_more);
_unique = (!_more);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _classEnv;
tmpMeta[0+2] = _attr;
tmpMeta[0+3] = _ty;
tmpMeta[0+4] = _bind;
tmpMeta[0+5] = _cnstForRange;
tmp1_c6 = _unique;
tmpMeta[0+7] = _splicedExpData;
tmpMeta[0+8] = _componentEnv;
tmp1_c9 = _name;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta14 = MMC_CAR(tmp4_2);
tmpMeta15 = MMC_CDR(tmp4_2);
_rest = tmpMeta15;
_cache = tmp4_1;
_env = tmp4_3;
_ident = tmp4_4;
tmpMeta[0+0] = omc_Lookup_lookupUnqualifiedImportedVarInFrame(threadData, _cache, _rest, _env, _ident, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3], &tmpMeta[0+4], &tmpMeta[0+5], &tmp1_c6, &tmpMeta[0+7], &tmpMeta[0+8], &tmp1_c9);
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
_outClassEnv = tmpMeta[0+1];
_outAttributes = tmpMeta[0+2];
_outType = tmpMeta[0+3];
_outBinding = tmpMeta[0+4];
_constOfForIteratorRange = tmpMeta[0+5];
_outBoolean = tmp1_c6;
_splicedExpData = tmpMeta[0+7];
_outComponentEnv = tmpMeta[0+8];
_name = tmp1_c9;
_return: OMC_LABEL_UNUSED
if (out_outClassEnv) { *out_outClassEnv = _outClassEnv; }
if (out_outAttributes) { *out_outAttributes = _outAttributes; }
if (out_outType) { *out_outType = _outType; }
if (out_outBinding) { *out_outBinding = _outBinding; }
if (out_constOfForIteratorRange) { *out_constOfForIteratorRange = _constOfForIteratorRange; }
if (out_outBoolean) { *out_outBoolean = _outBoolean; }
if (out_splicedExpData) { *out_splicedExpData = _splicedExpData; }
if (out_outComponentEnv) { *out_outComponentEnv = _outComponentEnv; }
if (out_name) { *out_name = _name; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Lookup_lookupUnqualifiedImportedVarInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inImports, modelica_metatype _inEnv, modelica_metatype _inIdent, modelica_metatype *out_outClassEnv, modelica_metatype *out_outAttributes, modelica_metatype *out_outType, modelica_metatype *out_outBinding, modelica_metatype *out_constOfForIteratorRange, modelica_metatype *out_outBoolean, modelica_metatype *out_splicedExpData, modelica_metatype *out_outComponentEnv, modelica_metatype *out_name)
{
modelica_boolean _outBoolean;
modelica_metatype _outCache = NULL;
_outCache = omc_Lookup_lookupUnqualifiedImportedVarInFrame(threadData, _inCache, _inImports, _inEnv, _inIdent, out_outClassEnv, out_outAttributes, out_outType, out_outBinding, out_constOfForIteratorRange, &_outBoolean, out_splicedExpData, out_outComponentEnv, out_name);
if (out_outBoolean) { *out_outBoolean = mmc_mk_icon(_outBoolean); }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_moreLookupUnqualifiedImportedVarInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inImports, modelica_metatype _inEnv, modelica_string _inIdent, modelica_boolean *out_outBoolean)
{
modelica_metatype _outCache = NULL;
modelica_boolean _outBoolean;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_string tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inImports;
tmp4_3 = _inEnv;
tmp4_4 = _inIdent;
{
modelica_metatype _f = NULL;
modelica_string _ident = NULL;
modelica_metatype _env = NULL;
modelica_metatype _prevFrames = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _path = NULL;
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
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,2,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_path = tmpMeta8;
_cache = tmp4_1;
_env = tmp4_3;
_ident = tmp4_4;
tmpMeta9 = listReverse(omc_FGraph_currentScope(threadData, _env));
if (listEmpty(tmpMeta9)) goto goto_2;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
_f = tmpMeta10;
_prevFrames = tmpMeta11;
_cref = omc_ComponentReference_pathToCref(threadData, _path);
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
_cref = omc_ComponentReference_crefPrependIdent(threadData, _cref, _ident, tmpMeta12, _OMC_LIT126);
tmpMeta13 = mmc_mk_cons(_f, MMC_REFSTRUCTLIT(mmc_nil));
_env = omc_FGraph_setScope(threadData, _env, tmpMeta13);
_cache = omc_Lookup_lookupVarInPackages(threadData, _cache, _env, _cref, _prevFrames, omc_Mutable_create(threadData, mmc_mk_boolean(0)), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
tmpMeta[0+0] = _cache;
tmp1_c1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta14 = MMC_CAR(tmp4_2);
tmpMeta15 = MMC_CDR(tmp4_2);
_rest = tmpMeta15;
_cache = tmp4_1;
_env = tmp4_3;
_ident = tmp4_4;
tmp4 += 1;
tmpMeta[0+0] = omc_Lookup_moreLookupUnqualifiedImportedVarInFrame(threadData, _cache, _rest, _env, _ident, &tmp1_c1);
goto tmp3_done;
}
case 2: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
_cache = tmp4_1;
tmpMeta[0+0] = _cache;
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
_outCache = tmpMeta[0+0];
_outBoolean = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_outBoolean) { *out_outBoolean = _outBoolean; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Lookup_moreLookupUnqualifiedImportedVarInFrame(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inImports, modelica_metatype _inEnv, modelica_metatype _inIdent, modelica_metatype *out_outBoolean)
{
modelica_boolean _outBoolean;
modelica_metatype _outCache = NULL;
_outCache = omc_Lookup_moreLookupUnqualifiedImportedVarInFrame(threadData, _inCache, _inImports, _inEnv, _inIdent, &_outBoolean);
if (out_outBoolean) { *out_outBoolean = mmc_mk_icon(_outBoolean); }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupQualifiedImportedVarInFrame(threadData_t *threadData, modelica_metatype _inImports, modelica_string _ident)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inImports;
{
modelica_string _id = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _path = NULL;
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
modelica_boolean tmp9;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_path = tmpMeta8;
tmp4 += 1;
_id = omc_AbsynUtil_pathLastIdent(threadData, _path);
tmp9 = (stringEqual(_id, _ident));
if (1 != tmp9) goto goto_2;
tmpMeta1 = omc_ComponentReference_pathToCref(threadData, _path);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_boolean tmp14;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,0,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 3));
_id = tmpMeta12;
_path = tmpMeta13;
tmp14 = (stringEqual(_id, _ident));
if (1 != tmp14) goto goto_2;
tmpMeta1 = omc_ComponentReference_pathToCref(threadData, _path);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta15 = MMC_CAR(tmp4_1);
tmpMeta16 = MMC_CDR(tmp4_1);
_rest = tmpMeta16;
tmpMeta1 = omc_Lookup_lookupQualifiedImportedVarInFrame(threadData, _rest, _ident);
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupPrevFrames(threadData_t *threadData, modelica_string _id, modelica_metatype _inPrevFrames, modelica_metatype *out_outPrevFrames)
{
modelica_metatype _outFrame = NULL;
modelica_metatype _outPrevFrames = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inPrevFrames;
{
modelica_string _sid = NULL;
modelica_metatype _prevFrames = NULL;
modelica_metatype _ref = NULL;
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
modelica_boolean tmp8;
modelica_boolean tmp9;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_ref = tmpMeta6;
_prevFrames = tmpMeta7;
tmp8 = omc_FNode_isRefTop(threadData, _ref);
if (0 != tmp8) goto goto_2;
_sid = omc_FNode_refName(threadData, _ref);
tmp9 = (stringEqual(_id, _sid));
if (1 != tmp9) goto goto_2;
tmpMeta[0+0] = mmc_mk_some(_ref);
tmpMeta[0+1] = _prevFrames;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = mmc_mk_none();
tmpMeta[0+1] = tmpMeta10;
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
_outFrame = tmpMeta[0+0];
_outPrevFrames = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outPrevFrames) { *out_outPrevFrames = _outPrevFrames; }
return _outFrame;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_Lookup_getConstrainingClass(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inEnv, modelica_metatype _inCache)
{
modelica_string _outPath = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
modelica_metatype _cc_path = NULL;
modelica_metatype _ts = NULL;
modelica_metatype _el = NULL;
modelica_metatype _env = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (optionNone(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 1));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
_cc_path = tmpMeta10;
tmp1 = omc_AbsynUtil_pathString(threadData, _cc_path, _OMC_LIT36, 1, 0);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,2,3) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
_ts = tmpMeta12;
omc_Lookup_lookupClass(threadData, _inCache, _inEnv, omc_AbsynUtil_typeSpecPath(threadData, _ts), mmc_mk_none() ,&_el ,&_env);
tmp1 = omc_Lookup_getConstrainingClass(threadData, _el, _env, _inCache);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
tmpMeta13 = stringAppend(omc_FGraph_printGraphPathStr(threadData, _inEnv),_OMC_LIT36);
tmpMeta14 = stringAppend(tmpMeta13,omc_SCodeUtil_elementName(threadData, _inClass));
tmp1 = tmpMeta14;
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
_outPath = tmp1;
_return: OMC_LABEL_UNUSED
return _outPath;
}
PROTECTED_FUNCTION_STATIC void omc_Lookup_checkPartialScope(threadData_t *threadData, modelica_metatype _inEnv, modelica_metatype _inParentEnv, modelica_metatype _inCache, modelica_metatype _inInfo)
{
modelica_metatype _el = NULL;
modelica_metatype _pre = NULL;
modelica_string _name = NULL;
modelica_string _pre_str = NULL;
modelica_string _cc_str = NULL;
modelica_metatype _cls_info = NULL;
modelica_metatype _pre_info = NULL;
modelica_metatype _info = NULL;
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
if(((isSome(_inInfo) && omc_FGraph_isPartialScope(threadData, _inEnv)) && omc_Config_languageStandardAtLeast(threadData, 5)))
{
tmpMeta1 = omc_FNode_fromRef(threadData, omc_FGraph_lastScopeRef(threadData, _inEnv));
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta2,3,5) == 0) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 2));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 3));
_el = tmpMeta3;
_pre = tmpMeta4;
_name = omc_SCodeUtil_elementName(threadData, _el);
if((omc_FGraph_graphPrefixOf(threadData, _inParentEnv, _inEnv) && (!omc_PrefixUtil_isNoPrefix(threadData, _pre))))
{
_pre_str = omc_PrefixUtil_printPrefixStr(threadData, _pre);
_cls_info = omc_SCodeUtil_elementInfo(threadData, _el);
_pre_info = omc_PrefixUtil_getPrefixInfo(threadData, _pre);
_cc_str = omc_Lookup_getConstrainingClass(threadData, _el, omc_FGraph_stripLastScopeRef(threadData, _inEnv, NULL), _inCache);
tmpMeta5 = mmc_mk_cons(_pre_str, mmc_mk_cons(_name, mmc_mk_cons(_cc_str, MMC_REFSTRUCTLIT(mmc_nil))));
tmpMeta6 = mmc_mk_cons(_cls_info, mmc_mk_cons(_pre_info, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addMultiSourceMessage(threadData, _OMC_LIT138, tmpMeta5, tmpMeta6);
MMC_THROW_INTERNAL();
}
else
{
tmpMeta7 = _inInfo;
if (optionNone(tmpMeta7)) MMC_THROW_INTERNAL();
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
_info = tmpMeta8;
if((!omc_Config_getGraphicsExpMode(threadData)))
{
tmpMeta9 = mmc_mk_cons(_name, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT135, tmpMeta9, _info);
}
}
}
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupClassQualified2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _path, modelica_metatype _inC, modelica_metatype _optFrame, modelica_metatype _inPrevFrames, modelica_metatype _inState, modelica_metatype _inInfo, modelica_metatype *out_outClass, modelica_metatype *out_outEnv, modelica_metatype *out_outPrevFrames)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outClass = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outPrevFrames = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;volatile modelica_metatype tmp4_5;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inC;
tmp4_4 = _optFrame;
tmp4_5 = _inPrevFrames;
{
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _prevFrames = NULL;
modelica_metatype _frame = NULL;
modelica_metatype _restr = NULL;
modelica_metatype _ci_state = NULL;
modelica_metatype _encflag = NULL;
modelica_string _id = NULL;
modelica_metatype _r = NULL;
modelica_metatype _mod = NULL;
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
if (optionNone(tmp4_4)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 1));
_frame = tmpMeta6;
_cache = tmp4_1;
_env = tmp4_2;
_prevFrames = tmp4_5;
tmp4 += 2;
_env = omc_FGraph_pushScopeRef(threadData, _env, _frame);
tmpMeta[0+0] = omc_Lookup_lookupClass2(threadData, _cache, _env, _path, _prevFrames, _inState, _inInfo, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3]);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,8) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (!optionNone(tmp4_4)) goto tmp3_end;
_id = tmpMeta7;
_cache = tmp4_1;
_env = tmp4_2;
_r = omc_FNode_child(threadData, omc_FGraph_lastScopeRef(threadData, _env), _id);
tmpMeta8 = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,3,5) == 0) goto goto_2;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,7,1) == 0) goto goto_2;
_cache = omc_Inst_getCachedInstance(threadData, _cache, _env, _id, _r ,&_env);
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = omc_Lookup_lookupClass2(threadData, _cache, _env, _path, tmpMeta10, _inState, _inInfo, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3]);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,8) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 6));
if (!optionNone(tmp4_4)) goto tmp3_end;
_id = tmpMeta11;
_encflag = tmpMeta12;
_restr = tmpMeta13;
_cache = tmp4_1;
_env = tmp4_2;
_env = omc_FGraph_openScope(threadData, _env, _encflag, _id, omc_FGraph_restrictionToScopeType(threadData, _restr));
_ci_state = omc_ClassInf_start(threadData, _restr, omc_FGraph_getGraphName(threadData, _env));
_mod = omc_Mod_getClassModifier(threadData, _inEnv, _id);
tmpMeta14 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta15 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_Inst_partialInstClassIn(threadData, _cache, _env, tmpMeta14, _mod, _OMC_LIT6, _ci_state, _inC, _OMC_LIT51, tmpMeta15, ((modelica_integer) 0) ,&_env ,NULL ,NULL ,NULL);
omc_Lookup_checkPartialScope(threadData, _env, _inEnv, _cache, _inInfo);
tmpMeta16 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = omc_Lookup_lookupClass2(threadData, _cache, _env, _path, tmpMeta16, _inState, _inInfo, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3]);
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
_outClass = tmpMeta[0+1];
_outEnv = tmpMeta[0+2];
_outPrevFrames = tmpMeta[0+3];
_return: OMC_LABEL_UNUSED
if (out_outClass) { *out_outClass = _outClass; }
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outPrevFrames) { *out_outPrevFrames = _outPrevFrames; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupClassQualified(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_string _id, modelica_metatype _path, modelica_metatype _inOptFrame, modelica_metatype _inPrevFrames, modelica_metatype _inState, modelica_metatype _inInfo, modelica_metatype *out_outClass, modelica_metatype *out_outEnv, modelica_metatype *out_outPrevFrames)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outClass = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outPrevFrames = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_metatype tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inOptFrame;
tmp4_4 = _inPrevFrames;
{
modelica_metatype _c = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _prevFrames = NULL;
modelica_metatype _frame = NULL;
modelica_metatype _optFrame = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (optionNone(tmp4_3)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 1));
_frame = tmpMeta6;
_cache = tmp4_1;
_env = tmp4_2;
_prevFrames = tmp4_4;
omc_Mutable_update(threadData, _inState, mmc_mk_boolean(1));
_env = omc_FGraph_pushScopeRef(threadData, _env, _frame);
tmpMeta[0+0] = omc_Lookup_lookupClass2(threadData, _cache, _env, _path, _prevFrames, _inState, _inInfo, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3]);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (!optionNone(tmp4_3)) goto tmp3_end;
_cache = tmp4_1;
_env = tmp4_2;
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_Lookup_lookupClassInEnv(threadData, _cache, _env, _id, tmpMeta7, _inState, _inInfo ,&_c ,&_env ,&_prevFrames);
_optFrame = omc_Lookup_lookupPrevFrames(threadData, _id, _prevFrames ,&_prevFrames);
tmpMeta[0+0] = omc_Lookup_lookupClassQualified2(threadData, _cache, _env, _path, _c, _optFrame, _prevFrames, _inState, _inInfo, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3]);
goto tmp3_done;
}
}
goto tmp3_end;
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
_outClass = tmpMeta[0+1];
_outEnv = tmpMeta[0+2];
_outPrevFrames = tmpMeta[0+3];
_return: OMC_LABEL_UNUSED
if (out_outClass) { *out_outClass = _outClass; }
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outPrevFrames) { *out_outPrevFrames = _outPrevFrames; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupClass2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inPath, modelica_metatype _inPrevFrames, modelica_metatype _inState, modelica_metatype _inInfo, modelica_metatype *out_outClass, modelica_metatype *out_outEnv, modelica_metatype *out_outPrevFrames)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outClass = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outPrevFrames = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_metatype tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inPath;
tmp4_4 = _inPrevFrames;
{
modelica_metatype _r = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _prevFrames = NULL;
modelica_metatype _path = NULL;
modelica_string _id = NULL;
modelica_string _pack = NULL;
modelica_metatype _optFrame = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_3))) {
case 5: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (!listEmpty(tmp4_4)) goto tmp3_end;
_path = tmpMeta5;
_cache = tmp4_1;
_env = tmp4_2;
tmpMeta6 = listReverse(omc_FGraph_currentScope(threadData, _env));
if (listEmpty(tmpMeta6)) goto goto_2;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
_r = tmpMeta7;
_prevFrames = tmpMeta8;
omc_Mutable_update(threadData, _inState, mmc_mk_boolean(1));
tmpMeta9 = mmc_mk_cons(_r, MMC_REFSTRUCTLIT(mmc_nil));
_env = omc_FGraph_setScope(threadData, _env, tmpMeta9);
_inCache = _cache;
_inEnv = _env;
_inPath = _path;
_inPrevFrames = _prevFrames;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
_pack = tmpMeta10;
_path = tmpMeta11;
_cache = tmp4_1;
_env = tmp4_2;
_prevFrames = tmp4_4;
_optFrame = omc_Lookup_lookupPrevFrames(threadData, _pack, _prevFrames ,&_prevFrames);
tmpMeta[0+0] = omc_Lookup_lookupClassQualified(threadData, _cache, _env, _pack, _path, _optFrame, _prevFrames, _inState, _inInfo, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3]);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
_id = tmpMeta12;
_cache = tmp4_1;
_env = tmp4_2;
_prevFrames = tmp4_4;
tmpMeta[0+0] = omc_Lookup_lookupClassInEnv(threadData, _cache, _env, _id, _prevFrames, _inState, _inInfo, &tmpMeta[0+1], &tmpMeta[0+2], &tmpMeta[0+3]);
goto tmp3_done;
}
}
goto tmp3_end;
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
_outClass = tmpMeta[0+1];
_outEnv = tmpMeta[0+2];
_outPrevFrames = tmpMeta[0+3];
_return: OMC_LABEL_UNUSED
if (out_outClass) { *out_outClass = _outClass; }
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outPrevFrames) { *out_outPrevFrames = _outPrevFrames; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupClass1(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inPath, modelica_metatype _inPrevFrames, modelica_metatype _inState, modelica_metatype _inInfo, modelica_metatype *out_outClass, modelica_metatype *out_outEnv, modelica_metatype *out_outPrevFrames)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outClass = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outPrevFrames = NULL;
modelica_integer _errors;
modelica_metatype _info = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_errors = omc_Error_getNumErrorMessages(threadData);
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
_outCache = omc_Lookup_lookupClass2(threadData, _inCache, _inEnv, _inPath, _inPrevFrames, _inState, _inInfo ,&_outClass ,&_outEnv ,&_outPrevFrames);
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta5;
if((isSome(_inInfo) && (_errors == omc_Error_getNumErrorMessages(threadData))))
{
tmpMeta5 = mmc_mk_cons(omc_AbsynUtil_pathString(threadData, _inPath, _OMC_LIT36, 1, 0), mmc_mk_cons(omc_FGraph_printGraphPathStr(threadData, _inEnv), MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT49, tmpMeta5, omc_Util_getOption(threadData, _inInfo));
}
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
if (out_outClass) { *out_outClass = _outClass; }
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outPrevFrames) { *out_outPrevFrames = _outPrevFrames; }
return _outCache;
}
DLLExport
modelica_metatype omc_Lookup_lookupClassIdent(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_string _ident, modelica_metatype _inInfo, modelica_metatype *out_outClass, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outClass = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outCache = omc_Lookup_lookupClassInEnv(threadData, _inCache, _inEnv, _ident, tmpMeta1, omc_Mutable_create(threadData, mmc_mk_boolean(0)), _inInfo ,&_outClass ,&_outEnv, NULL);
_return: OMC_LABEL_UNUSED
if (out_outClass) { *out_outClass = _outClass; }
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
DLLExport
modelica_metatype omc_Lookup_lookupClass(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inPath, modelica_metatype _inInfo, modelica_metatype *out_outClass, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outClass = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inPath;
{
modelica_metatype _id = NULL;
modelica_string _name = NULL;
modelica_metatype _cenv = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_name = tmpMeta6;
_id = tmpMeta7;
omc_ErrorExt_setCheckpoint(threadData, _OMC_LIT139);
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
_outCache = omc_Lookup_lookupVarIdent(threadData, _inCache, _inEnv, _name, tmpMeta8 ,NULL ,NULL ,NULL ,NULL ,NULL ,NULL ,&_cenv ,NULL);
_outCache = omc_Lookup_lookupClass(threadData, _outCache, _cenv, _id, mmc_mk_none() ,&_outClass ,&_outEnv);
omc_ErrorExt_rollBack(threadData, _OMC_LIT139);
tmpMeta[0+0] = _outCache;
tmpMeta[0+1] = _outClass;
tmpMeta[0+2] = _outEnv;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
omc_ErrorExt_rollBack(threadData, _OMC_LIT139);
goto goto_2;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta9;
tmpMeta9 = MMC_REFSTRUCTLIT(mmc_nil);
_outCache = omc_Lookup_lookupClass1(threadData, _inCache, _inEnv, _inPath, tmpMeta9, omc_Mutable_create(threadData, mmc_mk_boolean(0)), _inInfo ,&_outClass ,&_outEnv ,NULL);
tmpMeta[0+0] = _outCache;
tmpMeta[0+1] = _outClass;
tmpMeta[0+2] = _outEnv;
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
_outClass = tmpMeta[0+1];
_outEnv = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outClass) { *out_outClass = _outClass; }
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupMetarecordsRecursive3(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _path, modelica_string _str, modelica_metatype _inHt, modelica_metatype _inAcc, modelica_metatype *out_outHt, modelica_metatype *out_outMetarecordTypes)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outHt = NULL;
modelica_metatype _outMetarecordTypes = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_metatype tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inHt;
tmp4_4 = _inAcc;
{
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _uniontypePaths = NULL;
modelica_metatype _uniontypeTypes = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _acc = NULL;
modelica_metatype _ht = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_cache = tmp4_1;
_ht = tmp4_3;
_acc = tmp4_4;
if (!omc_BaseHashTable_hasKey(threadData, _str, _ht)) goto tmp3_end;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _ht;
tmpMeta[0+2] = _acc;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
_cache = tmp4_1;
_env = tmp4_2;
_ht = tmp4_3;
_acc = tmp4_4;
tmpMeta6 = mmc_mk_box2(0, _str, _path);
_ht = omc_BaseHashTable_add(threadData, tmpMeta6, _ht);
_cache = omc_Lookup_lookupType(threadData, _cache, _env, _path, _OMC_LIT142 ,&_ty ,NULL);
tmpMeta7 = mmc_mk_cons(_ty, _acc);
_acc = tmpMeta7;
_uniontypeTypes = omc_Types_getAllInnerTypesOfType(threadData, _ty, boxvar_Types_uniontypeFilter);
_uniontypePaths = omc_List_flatten(threadData, omc_List_map(threadData, _uniontypeTypes, boxvar_Types_getUniontypePaths));
tmpMeta[0+0] = omc_Lookup_lookupMetarecordsRecursive2(threadData, _cache, _env, _uniontypePaths, _ht, _acc, &tmpMeta[0+1], &tmpMeta[0+2]);
goto tmp3_done;
}
}
goto tmp3_end;
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
_outHt = tmpMeta[0+1];
_outMetarecordTypes = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outHt) { *out_outHt = _outHt; }
if (out_outMetarecordTypes) { *out_outMetarecordTypes = _outMetarecordTypes; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupMetarecordsRecursive2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inUniontypePaths, modelica_metatype _inHt, modelica_metatype _inAcc, modelica_metatype *out_outHt, modelica_metatype *out_outMetarecordTypes)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outHt = NULL;
modelica_metatype _outMetarecordTypes = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_metatype tmp4_4;modelica_metatype tmp4_5;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inUniontypePaths;
tmp4_4 = _inHt;
tmp4_5 = _inAcc;
{
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _first = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _ht = NULL;
modelica_metatype _acc = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_3)) goto tmp3_end;
_cache = tmp4_1;
_ht = tmp4_4;
_acc = tmp4_5;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _ht;
tmpMeta[0+2] = _acc;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_3);
tmpMeta7 = MMC_CDR(tmp4_3);
_first = tmpMeta6;
_rest = tmpMeta7;
_cache = tmp4_1;
_env = tmp4_2;
_ht = tmp4_4;
_acc = tmp4_5;
_cache = omc_Lookup_lookupMetarecordsRecursive3(threadData, _cache, _env, _first, omc_AbsynUtil_pathString(threadData, _first, _OMC_LIT36, 1, 0), _ht, _acc ,&_ht ,&_acc);
_inCache = _cache;
_inEnv = _env;
_inUniontypePaths = _rest;
_inHt = _ht;
_inAcc = _acc;
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
_outHt = tmpMeta[0+1];
_outMetarecordTypes = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outHt) { *out_outHt = _outHt; }
if (out_outMetarecordTypes) { *out_outMetarecordTypes = _outMetarecordTypes; }
return _outCache;
}
DLLExport
modelica_metatype omc_Lookup_lookupMetarecordsRecursive(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inUniontypePaths, modelica_metatype *out_outMetarecordTypes)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outMetarecordTypes = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outCache = omc_Lookup_lookupMetarecordsRecursive2(threadData, _inCache, _inEnv, _inUniontypePaths, omc_HashTableStringToPath_emptyHashTable(threadData), tmpMeta1 ,NULL ,&_outMetarecordTypes);
_return: OMC_LABEL_UNUSED
if (out_outMetarecordTypes) { *out_outMetarecordTypes = _outMetarecordTypes; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupType2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inClass, modelica_metatype *out_outType, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inClass;
{
modelica_metatype _t = NULL;
modelica_metatype _env_1 = NULL;
modelica_metatype _env_2 = NULL;
modelica_metatype _env_3 = NULL;
modelica_metatype _path = NULL;
modelica_metatype _c = NULL;
modelica_string _id = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _r = NULL;
modelica_metatype _types = NULL;
modelica_metatype _names = NULL;
modelica_metatype _ci_state = NULL;
modelica_metatype _encflag = NULL;
modelica_metatype _mod = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,8) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,1) == 0) goto tmp3_end;
_c = tmp4_3;
_cache = tmp4_1;
_env_1 = tmp4_2;
tmp4 += 6;
_cache = omc_Lookup_buildRecordType(threadData, _cache, _env_1, _c ,&_env_1 ,&_t);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _t;
tmpMeta[0+2] = _env_1;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,8) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,10,0) == 0) goto tmp3_end;
_c = tmp4_3;
_id = tmpMeta7;
_encflag = tmpMeta8;
_r = tmpMeta9;
_cache = tmp4_1;
_env_1 = tmp4_2;
tmp4 += 5;
_env_2 = omc_FGraph_openScope(threadData, _env_1, _encflag, _id, _OMC_LIT3);
_ci_state = omc_ClassInf_start(threadData, _r, omc_FGraph_getGraphName(threadData, _env_2));
_mod = omc_Mod_getClassModifier(threadData, _env_1, _id);
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta11 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_Inst_instClassIn(threadData, _cache, _env_2, tmpMeta10, _OMC_LIT4, _mod, _OMC_LIT6, _ci_state, _c, _OMC_LIT51, tmpMeta11, 0, _OMC_LIT10, _OMC_LIT11, _OMC_LIT14, mmc_mk_none() ,&_env_3 ,NULL ,NULL ,NULL ,NULL ,NULL ,&_types ,NULL ,NULL ,NULL ,NULL);
omc_SCodeUtil_getClassComponents(threadData, _c ,&_names);
omc_Types_checkEnumDuplicateLiterals(threadData, _names, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_c), 9))));
_path = omc_FGraph_getGraphName(threadData, _env_3);
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta13 = mmc_mk_box6(8, &DAE_Type_T__ENUMERATION__desc, mmc_mk_none(), _path, _names, _types, tmpMeta12);
_t = tmpMeta13;
_env_3 = omc_FGraph_mkTypeNode(threadData, _env_3, _id, _t);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _t;
tmpMeta[0+2] = _env_3;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,8) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,7,0) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,2,3) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,0,2) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,1,1) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 2));
if (4 != MMC_STRLEN(tmpMeta18) || strcmp(MMC_STRINGDATA(_OMC_LIT145), MMC_STRINGDATA(tmpMeta18)) != 0) goto tmp3_end;
_cache = tmp4_1;
_env_1 = tmp4_2;
tmp4 += 4;
_t = _OMC_LIT143;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _t;
tmpMeta[0+2] = _env_1;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,8) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta19,7,0) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,2,3) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta21,0,2) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta22,1,1) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 2));
if (7 != MMC_STRLEN(tmpMeta23) || strcmp(MMC_STRINGDATA(_OMC_LIT146), MMC_STRINGDATA(tmpMeta23)) != 0) goto tmp3_end;
_cache = tmp4_1;
_env_1 = tmp4_2;
tmp4 += 3;
_t = _OMC_LIT15;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _t;
tmpMeta[0+2] = _env_1;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,8) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta24,7,0) == 0) goto tmp3_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta25,2,3) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,0,2) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta27,1,1) == 0) goto tmp3_end;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 2));
if (7 != MMC_STRLEN(tmpMeta28) || strcmp(MMC_STRINGDATA(_OMC_LIT147), MMC_STRINGDATA(tmpMeta28)) != 0) goto tmp3_end;
_cache = tmp4_1;
_env_1 = tmp4_2;
tmp4 += 2;
_t = _OMC_LIT25;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _t;
tmpMeta[0+2] = _env_1;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,8) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta29,7,0) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta30,2,3) == 0) goto tmp3_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta31,0,2) == 0) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta31), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta32,1,1) == 0) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 2));
if (6 != MMC_STRLEN(tmpMeta33) || strcmp(MMC_STRINGDATA(_OMC_LIT148), MMC_STRINGDATA(tmpMeta33)) != 0) goto tmp3_end;
_cache = tmp4_1;
_env_1 = tmp4_2;
tmp4 += 1;
_t = _OMC_LIT144;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _t;
tmpMeta[0+2] = _env_1;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta34;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,8) == 0) goto tmp3_end;
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta34,17,5) == 0) goto tmp3_end;
_c = tmp4_3;
_cache = tmp4_1;
_env_1 = tmp4_2;
_cache = omc_Lookup_buildMetaRecordType(threadData, _cache, _env_1, _c ,&_env_2 ,&_t);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _t;
tmpMeta[0+2] = _env_2;
goto tmp3_done;
}
case 7: {
modelica_boolean tmp35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
_cache = tmp4_1;
_env_1 = tmp4_2;
_c = tmp4_3;
tmp35 = omc_SCodeUtil_classIsExternalObject(threadData, _c);
if (1 != tmp35) goto goto_2;
tmpMeta36 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta37 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_Inst_instClass(threadData, _cache, _env_1, tmpMeta36, _OMC_LIT4, _OMC_LIT5, _OMC_LIT6, _c, tmpMeta37, 0, _OMC_LIT81, _OMC_LIT11, _OMC_LIT14 ,&_env_1 ,NULL ,NULL ,NULL ,NULL ,NULL ,NULL ,NULL ,NULL);
tmpMeta38 = _c;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta38,2,8) == 0) goto goto_2;
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta38), 2));
_id = tmpMeta39;
_env_1 = omc_FGraph_stripLastScopeRef(threadData, _env_1, NULL);
tmpMeta[0+0] = omc_Lookup_lookupTypeInEnv(threadData, _cache, _env_1, _id, &tmpMeta[0+1], &tmpMeta[0+2]);
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,8) == 0) goto tmp3_end;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta41,9,1) == 0) goto tmp3_end;
_c = tmp4_3;
_id = tmpMeta40;
_cache = tmp4_1;
_env_1 = tmp4_2;
tmpMeta42 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_InstFunction_implicitFunctionTypeInstantiation(threadData, _cache, _env_1, tmpMeta42, _c ,&_env_2 ,NULL);
tmpMeta[0+0] = omc_Lookup_lookupTypeInEnv(threadData, _cache, _env_2, _id, &tmpMeta[0+1], &tmpMeta[0+2]);
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
_outType = tmpMeta[0+1];
_outEnv = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outType) { *out_outType = _outType; }
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
DLLExport
modelica_metatype omc_Lookup_lookupTypeIdent(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_string _ident, modelica_metatype _msg, modelica_metatype *out_outType, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_string tmp4_3;volatile modelica_metatype tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _ident;
tmp4_4 = _msg;
{
modelica_metatype _t = NULL;
modelica_metatype _env_1 = NULL;
modelica_metatype _env = NULL;
modelica_metatype _c = NULL;
modelica_string _classname = NULL;
modelica_string _scope = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _info = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (6 != MMC_STRLEN(tmp4_3) || strcmp(MMC_STRINGDATA(_OMC_LIT152), MMC_STRINGDATA(tmp4_3)) != 0) goto tmp3_end;
_cache = tmp4_1;
_env = tmp4_2;
_t = _OMC_LIT154;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _t;
tmpMeta[0+2] = _env;
goto tmp3_done;
}
case 1: {
_cache = tmp4_1;
_env = tmp4_2;
tmpMeta[0+0] = omc_Lookup_lookupTypeInEnv(threadData, _cache, _env, _ident, &tmpMeta[0+1], &tmpMeta[0+2]);
goto tmp3_done;
}
case 2: {
_cache = tmp4_1;
_env = tmp4_2;
_cache = omc_Lookup_lookupClassIdent(threadData, _cache, _env, _ident, mmc_mk_none() ,&_c ,&_env_1);
tmpMeta[0+0] = omc_Lookup_lookupType2(threadData, _cache, _env_1, _c, &tmpMeta[0+1], &tmpMeta[0+2]);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (optionNone(tmp4_4)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 1));
_info = tmpMeta6;
_env = tmp4_2;
tmpMeta7 = stringAppend(_ident,_OMC_LIT155);
_classname = tmpMeta7;
_scope = omc_FGraph_printGraphPathStr(threadData, _env);
tmpMeta8 = mmc_mk_cons(_classname, mmc_mk_cons(_scope, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT49, tmpMeta8, _info);
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
_outType = tmpMeta[0+1];
_outEnv = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outType) { *out_outType = _outType; }
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Lookup_lookupTypeQual(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inPath, modelica_metatype _msg, modelica_metatype *out_outType, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inPath;
tmp4_4 = _msg;
{
modelica_metatype _t = NULL;
modelica_metatype _env_1 = NULL;
modelica_metatype _env = NULL;
modelica_metatype _path = NULL;
modelica_metatype _c = NULL;
modelica_string _classname = NULL;
modelica_string _scope = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _info = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (11 != MMC_STRLEN(tmpMeta6) || strcmp(MMC_STRINGDATA(_OMC_LIT169), MMC_STRINGDATA(tmpMeta6)) != 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (6 != MMC_STRLEN(tmpMeta8) || strcmp(MMC_STRINGDATA(_OMC_LIT170), MMC_STRINGDATA(tmpMeta8)) != 0) goto tmp3_end;
_cache = tmp4_1;
_env = tmp4_2;
tmp4 += 1;
tmpMeta9 = mmc_mk_box5(14, &DAE_Type_T__FUNCTION__desc, _OMC_LIT151, _OMC_LIT25, _OMC_LIT95, _inPath);
_t = tmpMeta9;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _t;
tmpMeta[0+2] = _env;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (11 != MMC_STRLEN(tmpMeta10) || strcmp(MMC_STRINGDATA(_OMC_LIT169), MMC_STRINGDATA(tmpMeta10)) != 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,1,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
if (17 != MMC_STRLEN(tmpMeta12) || strcmp(MMC_STRINGDATA(_OMC_LIT171), MMC_STRINGDATA(tmpMeta12)) != 0) goto tmp3_end;
_cache = tmp4_1;
_env = tmp4_2;
tmpMeta13 = mmc_mk_box5(14, &DAE_Type_T__FUNCTION__desc, _OMC_LIT167, _OMC_LIT168, _OMC_LIT95, _inPath);
_t = tmpMeta13;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _t;
tmpMeta[0+2] = _env;
goto tmp3_done;
}
case 2: {
_cache = tmp4_1;
_env = tmp4_2;
_path = tmp4_3;
_cache = omc_Lookup_lookupClass(threadData, _cache, _env, _path, mmc_mk_none() ,&_c ,&_env_1);
tmpMeta[0+0] = omc_Lookup_lookupType2(threadData, _cache, _env_1, _c, &tmpMeta[0+1], &tmpMeta[0+2]);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (optionNone(tmp4_4)) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 1));
_info = tmpMeta14;
_env = tmp4_2;
_path = tmp4_3;
_classname = omc_AbsynUtil_pathString(threadData, _path, _OMC_LIT36, 1, 0);
tmpMeta15 = stringAppend(_classname,_OMC_LIT155);
_classname = tmpMeta15;
_scope = omc_FGraph_printGraphPathStr(threadData, _env);
tmpMeta16 = mmc_mk_cons(_classname, mmc_mk_cons(_scope, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT49, tmpMeta16, _info);
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
_outType = tmpMeta[0+1];
_outEnv = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outType) { *out_outType = _outType; }
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
DLLExport
modelica_metatype omc_Lookup_lookupType(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inPath, modelica_metatype _msg, modelica_metatype *out_t, modelica_metatype *out_env)
{
modelica_metatype _cache = NULL;
modelica_metatype _t = NULL;
modelica_metatype _env = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
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
tmpMeta[0+0] = omc_Lookup_lookupTypeIdent(threadData, _inCache, _inEnv, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inPath), 2))), _msg, &tmpMeta[0+1], &tmpMeta[0+2]);
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = omc_Lookup_lookupTypeQual(threadData, _inCache, _inEnv, _inPath, _msg, &tmpMeta[0+1], &tmpMeta[0+2]);
goto tmp3_done;
}
}
goto tmp3_end;
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
_t = tmpMeta[0+1];
_env = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_t) { *out_t = _t; }
if (out_env) { *out_env = _env; }
return _cache;
}
