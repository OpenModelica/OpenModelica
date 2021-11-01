#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "FGraph.c"
#endif
#include "omc_simulation_settings.h"
#include "FGraph.h"
#define _OMC_LIT0_data "$status"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,7,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "FGraph.setStatus failed on: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,28,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data " element: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,10,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,1,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,1,3) {&DAE_Prefix_NOPRE__desc,}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,1,6) {&SCode_Variability_CONST__desc,}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,0,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT6}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT8,2,3) {&ClassInf_State_UNKNOWN__desc,_OMC_LIT7}};
#define _OMC_LIT8 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT9,0.0);
#define _OMC_LIT9 MMC_REFREALLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT6,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT9}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "$"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,1,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "OpenModelica"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,12,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "FGraph.mkVersionNode: failed to create version node:\nInstance: CL("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,66,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data ").CO("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,5,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data ").CL("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,5,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,1,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT17,10,3) {&SCodeDump_SCodeDumpOptions_OPTIONS__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT17 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT17)
#define _OMC_LIT18_data ")\n	"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT18,3,_OMC_LIT18_data);
#define _OMC_LIT18 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,1,3) {&FCore_ScopeType_FUNCTION__SCOPE__desc,}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT20,1,1) {_OMC_LIT19}};
#define _OMC_LIT20 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT20)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT21,1,5) {&FCore_ScopeType_PARALLEL__SCOPE__desc,}};
#define _OMC_LIT21 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT21)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT22,1,1) {_OMC_LIT21}};
#define _OMC_LIT22 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT22)
#define _OMC_LIT23_data "NOT IMPLEMENTED YET"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT23,19,_OMC_LIT23_data);
#define _OMC_LIT23 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT23)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT24,1,4) {&FCore_ScopeType_CLASS__SCOPE__desc,}};
#define _OMC_LIT24 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT24)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT25,1,1) {_OMC_LIT24}};
#define _OMC_LIT25 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT25)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT26,1,3) {&FCore_Kind_USERDEFINED__desc,}};
#define _OMC_LIT26 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data "FGraph.mkComponentNode: The component name: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,44,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data " is not the same as its DAE.TYPES_VAR: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,39,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data "stripPrefix"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,11,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
#define _OMC_LIT30_data "Strips the environment prefix from path/crefs. Defaults to true."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT30,64,_OMC_LIT30_data);
#define _OMC_LIT30 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT30)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT31,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT30}};
#define _OMC_LIT31 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT31)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT32,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(106)),_OMC_LIT29,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT31}};
#define _OMC_LIT32 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT32)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT33,1,7) {&SCode_FunctionRestriction_FR__PARALLEL__FUNCTION__desc,}};
#define _OMC_LIT33 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT33)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT34,2,12) {&SCode_Restriction_R__FUNCTION__desc,_OMC_LIT33}};
#define _OMC_LIT34 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT34)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT35,2,3) {&SCode_FunctionRestriction_FR__NORMAL__FUNCTION__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT35 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT35)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT36,2,12) {&SCode_Restriction_R__FUNCTION__desc,_OMC_LIT35}};
#define _OMC_LIT36 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT36)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT37,1,3) {&SCode_Restriction_R__CLASS__desc,}};
#define _OMC_LIT37 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT37)
#define _OMC_LIT38_data "$foriter loop scope$"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT38,20,_OMC_LIT38_data);
#define _OMC_LIT38 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT38)
#define _OMC_LIT39_data "$parforiter loop scope$"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT39,23,_OMC_LIT39_data);
#define _OMC_LIT39 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT39)
#define _OMC_LIT40_data "$for loop scope$"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT40,16,_OMC_LIT40_data);
#define _OMC_LIT40 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT40)
#define _OMC_LIT41_data "FGraph.openScope: failed to open new scope in scope: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT41,53,_OMC_LIT41_data);
#define _OMC_LIT41 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT41)
#define _OMC_LIT42_data " name: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT42,7,_OMC_LIT42_data);
#define _OMC_LIT42 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT42)
#define _OMC_LIT43_data "FGraph.openNewScope: failed to open new scope in scope: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT43,56,_OMC_LIT43_data);
#define _OMC_LIT43 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT43)
#define _OMC_LIT44_data "<global scope>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT44,14,_OMC_LIT44_data);
#define _OMC_LIT44 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT44)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT45,1,3) {&SCode_Visibility_PUBLIC__desc,}};
#define _OMC_LIT45 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT45)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT46,1,4) {&SCode_Redeclare_NOT__REDECLARE__desc,}};
#define _OMC_LIT46 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT46)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT47,1,4) {&SCode_Final_NOT__FINAL__desc,}};
#define _OMC_LIT47 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT47)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT48,1,6) {&Absyn_InnerOuter_NOT__INNER__OUTER__desc,}};
#define _OMC_LIT48 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT48)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT49,1,4) {&SCode_Replaceable_NOT__REPLACEABLE__desc,}};
#define _OMC_LIT49 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT49)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT50,6,3) {&SCode_Prefixes_PREFIXES__desc,_OMC_LIT45,_OMC_LIT46,_OMC_LIT47,_OMC_LIT48,_OMC_LIT49}};
#define _OMC_LIT50 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT50)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT51,1,3) {&SCode_ConnectorType_POTENTIAL__desc,}};
#define _OMC_LIT51 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT51)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT52,1,5) {&SCode_Parallelism_NON__PARALLEL__desc,}};
#define _OMC_LIT52 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT52)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT53,1,5) {&Absyn_Direction_BIDIR__desc,}};
#define _OMC_LIT53 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT53)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT54,1,3) {&Absyn_IsField_NONFIELD__desc,}};
#define _OMC_LIT54 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT54)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT55,7,3) {&SCode_Attributes_ATTR__desc,MMC_REFSTRUCTLIT(mmc_nil),_OMC_LIT51,_OMC_LIT52,_OMC_LIT5,_OMC_LIT53,_OMC_LIT54}};
#define _OMC_LIT55 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT55)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT56,3,3) {&Absyn_TypeSpec_TPATH__desc,_OMC_LIT7,MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT56 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT56)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT57,1,5) {&SCode_Mod_NOMOD__desc,}};
#define _OMC_LIT57 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT57)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT58,3,3) {&SCode_Comment_COMMENT__desc,MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT58 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT58)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT59,1,6) {&DAE_ConnectorType_NON__CONNECTOR__desc,}};
#define _OMC_LIT59 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT59)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT60,1,4) {&FCore_Kind_BUILTIN__desc,}};
#define _OMC_LIT60 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT60)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT61,1,5) {&DAE_Mod_NOMOD__desc,}};
#define _OMC_LIT61 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT61)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT62,1,3) {&FCore_Status_VAR__UNTYPED__desc,}};
#define _OMC_LIT62 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT62)
#define _OMC_LIT63_data "FGraph.updateInstance failed for node: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT63,39,_OMC_LIT63_data);
#define _OMC_LIT63 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT63)
#define _OMC_LIT64_data " variable:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT64,10,_OMC_LIT64_data);
#define _OMC_LIT64 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT64)
#define _OMC_LIT65_data "FNode.updateSourceTargetScope: node does not yet have a reference child: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT65,73,_OMC_LIT65_data);
#define _OMC_LIT65 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT65)
#define _OMC_LIT66_data " target scope: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT66,15,_OMC_LIT66_data);
#define _OMC_LIT66 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT66)
#define _OMC_LIT67_data "empty"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT67,5,_OMC_LIT67_data);
#define _OMC_LIT67 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT67)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT68,2,4) {&FCore_Graph_EG__desc,_OMC_LIT67}};
#define _OMC_LIT68 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT68)
#define _OMC_LIT69_data "$top"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT69,4,_OMC_LIT69_data);
#define _OMC_LIT69 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT69)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT70,1,3) {&FCore_Data_TOP__desc,}};
#define _OMC_LIT70 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT70)
#include "util/modelica.h"
#include "FGraph_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraph_getGraphPathNoImplicitScope__dispatch(threadData_t *threadData, modelica_metatype _inScope);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_getGraphPathNoImplicitScope__dispatch,2,0) {(void*) boxptr_FGraph_getGraphPathNoImplicitScope__dispatch,0}};
#define boxvar_FGraph_getGraphPathNoImplicitScope__dispatch MMC_REFSTRUCTLIT(boxvar_lit_FGraph_getGraphPathNoImplicitScope__dispatch)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraph_pathStripGraphScopePrefix2(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inEnvPath, modelica_boolean _stripPartial);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_FGraph_pathStripGraphScopePrefix2(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inEnvPath, modelica_metatype _stripPartial);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_pathStripGraphScopePrefix2,2,0) {(void*) boxptr_FGraph_pathStripGraphScopePrefix2,0}};
#define boxvar_FGraph_pathStripGraphScopePrefix2 MMC_REFSTRUCTLIT(boxvar_lit_FGraph_pathStripGraphScopePrefix2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraph_crefStripGraphScopePrefix2(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inEnvPath, modelica_boolean _stripPartial);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_FGraph_crefStripGraphScopePrefix2(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inEnvPath, modelica_metatype _stripPartial);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_crefStripGraphScopePrefix2,2,0) {(void*) boxptr_FGraph_crefStripGraphScopePrefix2,0}};
#define boxvar_FGraph_crefStripGraphScopePrefix2 MMC_REFSTRUCTLIT(boxvar_lit_FGraph_crefStripGraphScopePrefix2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraph_updateVarAndMod(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inVar, modelica_metatype _inMod, modelica_metatype _instStatus, modelica_metatype _inTargetGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_updateVarAndMod,2,0) {(void*) boxptr_FGraph_updateVarAndMod,0}};
#define boxvar_FGraph_updateVarAndMod MMC_REFSTRUCTLIT(boxvar_lit_FGraph_updateVarAndMod)
DLLExport
modelica_boolean omc_FGraph_isPartialScope(threadData_t *threadData, modelica_metatype _inEnv)
{
modelica_boolean _outIsPartial;
modelica_metatype _el = NULL;
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
tmpMeta5 = omc_FNode_fromRef(threadData, omc_FGraph_lastScopeRef(threadData, _inEnv));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,5) == 0) goto goto_1;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_el = tmpMeta7;
_outIsPartial = omc_SCodeUtil_isPartial(threadData, _el);
goto tmp2_done;
}
case 1: {
_outIsPartial = 0;
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
return _outIsPartial;
}
modelica_metatype boxptr_FGraph_isPartialScope(threadData_t *threadData, modelica_metatype _inEnv)
{
modelica_boolean _outIsPartial;
modelica_metatype out_outIsPartial;
_outIsPartial = omc_FGraph_isPartialScope(threadData, _inEnv);
out_outIsPartial = mmc_mk_icon(_outIsPartial);
return out_outIsPartial;
}
DLLExport
modelica_metatype omc_FGraph_makeScopePartial(threadData_t *threadData, modelica_metatype _inEnv)
{
modelica_metatype _outEnv = NULL;
modelica_metatype _node = NULL;
modelica_metatype _data = NULL;
modelica_metatype _el = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outEnv = _inEnv;
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
_node = omc_FNode_fromRef(threadData, omc_FGraph_lastScopeRef(threadData, _inEnv));
{
modelica_metatype tmp8_1;
tmp8_1 = _node;
{
volatile mmc_switch_type tmp8;
int tmp9;
tmp8 = 0;
for (; tmp8 < 2; tmp8++) {
switch (MMC_SWITCH_CAST(tmp8)) {
case 0: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,3,5) == 0) goto tmp7_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_data = tmpMeta10;
_el = tmpMeta11;
_el = omc_SCodeUtil_makeClassPartial(threadData, _el);
tmpMeta12 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta12), MMC_UNTAGPTR(_data), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta12))[2] = _el;
_data = tmpMeta12;
tmpMeta13 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta13), MMC_UNTAGPTR(_node), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta13))[6] = _data;
_node = tmpMeta13;
tmpMeta5 = _node;
goto tmp7_done;
}
case 1: {
tmpMeta5 = _node;
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
_node = tmpMeta5;
_outEnv = omc_FGraph_setLastScopeRef(threadData, omc_FNode_toRef(threadData, _node), _outEnv);
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
return _outEnv;
}
DLLExport
modelica_metatype omc_FGraph_selectScope(threadData_t *threadData, modelica_metatype _inEnv, modelica_metatype _inPath)
{
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _pl = NULL;
modelica_integer _lp;
modelica_integer _le;
modelica_integer _diff;
modelica_metatype _cs = NULL;
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
_p = omc_AbsynUtil_stripLast(threadData, _inPath);
tmp6 = omc_AbsynUtil_pathPrefixOf(threadData, _p, omc_FGraph_getGraphName(threadData, _inEnv));
if (1 != tmp6) goto goto_2;
_pl = omc_AbsynUtil_pathToStringList(threadData, _p);
_lp = listLength(_pl);
_cs = omc_FGraph_currentScope(threadData, _inEnv);
_le = ((modelica_integer) -1) + listLength(_cs);
_diff = _le - _lp;
_cs = omc_List_stripN(threadData, _cs, _diff);
tmpMeta1 = omc_FGraph_setScope(threadData, _inEnv, _cs);
goto tmp3_done;
}
}
goto tmp3_end;
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
modelica_metatype omc_FGraph_getStatus(threadData_t *threadData, modelica_metatype _inEnv, modelica_string _inName)
{
modelica_metatype _outStatus = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inEnv;
{
modelica_metatype _g = NULL;
modelica_metatype _ref = NULL;
modelica_metatype _refParent = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
modelica_boolean tmp7;
_g = tmp4_1;
_refParent = omc_FGraph_lastScopeRef(threadData, _g);
tmp6 = omc_FNode_refHasChild(threadData, _refParent, _inName);
if (1 != tmp6) goto goto_2;
_ref = omc_FNode_child(threadData, _refParent, _inName);
tmp7 = omc_FNode_refHasChild(threadData, _ref, _OMC_LIT0);
if (1 != tmp7) goto goto_2;
_ref = omc_FNode_child(threadData, _ref, _OMC_LIT0);
tmpMeta1 = omc_FNode_refData(threadData, _ref);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outStatus = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStatus;
}
DLLExport
modelica_metatype omc_FGraph_setStatus(threadData_t *threadData, modelica_metatype _inEnv, modelica_string _inName, modelica_metatype _inStatus)
{
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inEnv;
{
modelica_metatype _g = NULL;
modelica_metatype _n = NULL;
modelica_metatype _ref = NULL;
modelica_metatype _refParent = NULL;
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
_g = tmp4_1;
_refParent = omc_FGraph_lastScopeRef(threadData, _g);
if(omc_FNode_refHasChild(threadData, _refParent, _inName))
{
_ref = omc_FNode_child(threadData, _refParent, _inName);
if(omc_FNode_refHasChild(threadData, _ref, _OMC_LIT0))
{
_ref = omc_FNode_child(threadData, _ref, _OMC_LIT0);
_n = omc_FNode_setData(threadData, omc_FNode_fromRef(threadData, _ref), _inStatus);
_ref = omc_FNode_updateRef(threadData, _ref, _n);
}
else
{
tmpMeta6 = mmc_mk_cons(_ref, MMC_REFSTRUCTLIT(mmc_nil));
_g = omc_FGraph_node(threadData, _g, _OMC_LIT0, tmpMeta6, _inStatus ,&_n);
omc_FNode_addChildRef(threadData, _ref, _OMC_LIT0, omc_FNode_toRef(threadData, _n), 0);
}
}
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
_g = tmp4_1;
tmpMeta7 = stringAppend(_OMC_LIT1,omc_FGraph_getGraphNameStr(threadData, _g));
tmpMeta8 = stringAppend(tmpMeta7,_OMC_LIT2);
tmpMeta9 = stringAppend(tmpMeta8,_inName);
tmpMeta10 = stringAppend(tmpMeta9,_OMC_LIT3);
fputs(MMC_STRINGDATA(tmpMeta10),stdout);
tmpMeta1 = _g;
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
_outEnv = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outEnv;
}
DLLExport
modelica_boolean omc_FGraph_graphPrefixOf2(threadData_t *threadData, modelica_metatype _inPrefixEnv, modelica_metatype _inEnv)
{
modelica_boolean _outIsPrefix;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inPrefixEnv;
tmp4_2 = _inEnv;
{
modelica_metatype _rest1 = NULL;
modelica_metatype _rest2 = NULL;
modelica_metatype _r1 = NULL;
modelica_metatype _r2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (!listEmpty(tmp4_1)) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
tmp1 = 1;
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
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_2);
tmpMeta11 = MMC_CDR(tmp4_2);
_r1 = tmpMeta8;
_rest1 = tmpMeta9;
_r2 = tmpMeta10;
_rest2 = tmpMeta11;
if (!(stringEqual(omc_FNode_refName(threadData, _r1), omc_FNode_refName(threadData, _r2)))) goto tmp3_end;
_inPrefixEnv = _rest1;
_inEnv = _rest2;
goto _tailrecursive;
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
_outIsPrefix = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsPrefix;
}
modelica_metatype boxptr_FGraph_graphPrefixOf2(threadData_t *threadData, modelica_metatype _inPrefixEnv, modelica_metatype _inEnv)
{
modelica_boolean _outIsPrefix;
modelica_metatype out_outIsPrefix;
_outIsPrefix = omc_FGraph_graphPrefixOf2(threadData, _inPrefixEnv, _inEnv);
out_outIsPrefix = mmc_mk_icon(_outIsPrefix);
return out_outIsPrefix;
}
DLLExport
modelica_boolean omc_FGraph_graphPrefixOf(threadData_t *threadData, modelica_metatype _inPrefixEnv, modelica_metatype _inEnv)
{
modelica_boolean _outIsPrefix;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outIsPrefix = omc_FGraph_graphPrefixOf2(threadData, listReverse(omc_FGraph_currentScope(threadData, _inPrefixEnv)), listReverse(omc_FGraph_currentScope(threadData, _inEnv)));
_return: OMC_LABEL_UNUSED
return _outIsPrefix;
}
modelica_metatype boxptr_FGraph_graphPrefixOf(threadData_t *threadData, modelica_metatype _inPrefixEnv, modelica_metatype _inEnv)
{
modelica_boolean _outIsPrefix;
modelica_metatype out_outIsPrefix;
_outIsPrefix = omc_FGraph_graphPrefixOf(threadData, _inPrefixEnv, _inEnv);
out_outIsPrefix = mmc_mk_icon(_outIsPrefix);
return out_outIsPrefix;
}
DLLExport
modelica_string omc_FGraph_getInstanceOriginalName(threadData_t *threadData, modelica_metatype _inEnv, modelica_string _inName)
{
modelica_string _outName = NULL;
modelica_string tmp1 = 0;
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
tmpMeta6 = omc_FNode_refData(threadData, omc_FNode_child(threadData, omc_FGraph_lastScopeRef(threadData, _inEnv), _inName));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,5) == 0) goto goto_2;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,7,1) == 0) goto goto_2;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_outName = tmpMeta8;
tmp1 = _outName;
goto tmp3_done;
}
case 1: {
tmp1 = _inName;
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
_outName = tmp1;
_return: OMC_LABEL_UNUSED
return _outName;
}
DLLExport
modelica_boolean omc_FGraph_isInstance(threadData_t *threadData, modelica_metatype _inEnv, modelica_string _inName)
{
modelica_boolean _yes;
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = omc_FNode_refData(threadData, omc_FNode_child(threadData, omc_FGraph_lastScopeRef(threadData, _inEnv), _inName));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,5) == 0) goto goto_2;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,7,1) == 0) goto goto_2;
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
_yes = tmp1;
_return: OMC_LABEL_UNUSED
return _yes;
}
modelica_metatype boxptr_FGraph_isInstance(threadData_t *threadData, modelica_metatype _inEnv, modelica_metatype _inName)
{
modelica_boolean _yes;
modelica_metatype out_yes;
_yes = omc_FGraph_isInstance(threadData, _inEnv, _inName);
out_yes = mmc_mk_icon(_yes);
return out_yes;
}
DLLExport
modelica_metatype omc_FGraph_getClassPrefix(threadData_t *threadData, modelica_metatype _inEnv, modelica_string _inClassName)
{
modelica_metatype _outPrefix = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _p = NULL;
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
_r = omc_FNode_child(threadData, omc_FGraph_lastScopeRef(threadData, _inEnv), _inClassName);
tmpMeta6 = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,5) == 0) goto goto_2;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
_p = tmpMeta7;
tmpMeta1 = _p;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _OMC_LIT4;
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
modelica_string omc_FGraph_mkVersionName(threadData_t *threadData, modelica_metatype _inSourceEnv, modelica_string _inSourceName, modelica_metatype _inPrefix, modelica_metatype _inMod, modelica_metatype _inTargetClassEnv, modelica_string _inTargetClassName, modelica_metatype *out_outCrefPrefix)
{
modelica_string _outName = NULL;
modelica_metatype _outCrefPrefix = NULL;
modelica_string tmp1_c0 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _crefPrefix = NULL;
modelica_string _name = NULL;
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
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
_crefPrefix = omc_PrefixUtil_prefixAdd(threadData, _inSourceName, tmpMeta6, tmpMeta7, _inPrefix, _OMC_LIT5, _OMC_LIT8, _OMC_LIT10);
tmpMeta8 = stringAppend(_inTargetClassName,_OMC_LIT11);
tmpMeta9 = stringAppend(tmpMeta8,omc_AbsynUtil_pathString(threadData, omc_AbsynUtil_stringListPath(threadData, listReverse(omc_AbsynUtil_pathToStringList(threadData, omc_PrefixUtil_prefixToPath(threadData, _crefPrefix)))), _OMC_LIT11, 0, 0));
_name = tmpMeta9;
tmp1_c0 = _name;
tmpMeta[0+1] = _crefPrefix;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outName = tmp1_c0;
_outCrefPrefix = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outCrefPrefix) { *out_outCrefPrefix = _outCrefPrefix; }
return _outName;
}
DLLExport
modelica_boolean omc_FGraph_isTargetClassBuiltin(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inClass)
{
modelica_boolean _yes;
modelica_boolean tmp1 = 0;
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
_r = omc_FNode_child(threadData, omc_FGraph_lastScopeRef(threadData, _inGraph), omc_SCodeUtil_elementName(threadData, _inClass));
tmp1 = (omc_FNode_isRefBasicType(threadData, _r) || omc_FNode_isRefBuiltin(threadData, _r));
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
_yes = tmp1;
_return: OMC_LABEL_UNUSED
return _yes;
}
modelica_metatype boxptr_FGraph_isTargetClassBuiltin(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inClass)
{
modelica_boolean _yes;
modelica_metatype out_yes;
_yes = omc_FGraph_isTargetClassBuiltin(threadData, _inGraph, _inClass);
out_yes = mmc_mk_icon(_yes);
return out_yes;
}
DLLExport
modelica_metatype omc_FGraph_createVersionScope(threadData_t *threadData, modelica_metatype _inSourceEnv, modelica_string _inSourceName, modelica_metatype _inPrefix, modelica_metatype _inMod, modelica_metatype _inTargetClassEnv, modelica_metatype _inTargetClass, modelica_metatype _inIH, modelica_metatype *out_outVersionedTargetClass, modelica_metatype *out_outIH)
{
modelica_metatype _outVersionedTargetClassEnv = NULL;
modelica_metatype _outVersionedTargetClass = NULL;
modelica_metatype _outIH = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inMod;
{
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
tmp4 += 1;
tmpMeta[0+0] = _inTargetClassEnv;
tmpMeta[0+1] = _inTargetClass;
tmpMeta[0+2] = _inIH;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta[0+0] = _inTargetClassEnv;
tmpMeta[0+1] = _inTargetClass;
tmpMeta[0+2] = _inIH;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp7;
tmp7 = (((omc_Config_acceptMetaModelicaGrammar(threadData) || omc_FGraph_isTargetClassBuiltin(threadData, _inTargetClassEnv, _inTargetClass)) || omc_FGraph_inFunctionScope(threadData, _inSourceEnv)) || omc_SCodeUtil_isOperatorRecord(threadData, _inTargetClass));
if (1 != tmp7) goto goto_2;
tmpMeta[0+0] = _inTargetClassEnv;
tmpMeta[0+1] = _inTargetClass;
tmpMeta[0+2] = _inIH;
goto tmp3_done;
}
case 3: {
modelica_boolean tmp8;
tmp8 = (stringEqual(omc_AbsynUtil_pathFirstIdent(threadData, omc_FGraph_getGraphName(threadData, _inTargetClassEnv)), _OMC_LIT12));
if (1 != tmp8) goto goto_2;
tmpMeta[0+0] = _inTargetClassEnv;
tmpMeta[0+1] = _inTargetClass;
tmpMeta[0+2] = _inIH;
goto tmp3_done;
}
case 4: {
tmpMeta[0+0] = omc_FGraph_mkVersionNode(threadData, _inSourceEnv, _inSourceName, _inPrefix, _inMod, _inTargetClassEnv, _inTargetClass, _inIH, &tmpMeta[0+1], &tmpMeta[0+2]);
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
_outVersionedTargetClassEnv = tmpMeta[0+0];
_outVersionedTargetClass = tmpMeta[0+1];
_outIH = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outVersionedTargetClass) { *out_outVersionedTargetClass = _outVersionedTargetClass; }
if (out_outIH) { *out_outIH = _outIH; }
return _outVersionedTargetClassEnv;
}
DLLExport
modelica_metatype omc_FGraph_mkVersionNode(threadData_t *threadData, modelica_metatype _inSourceEnv, modelica_string _inSourceName, modelica_metatype _inPrefix, modelica_metatype _inMod, modelica_metatype _inTargetClassEnv, modelica_metatype _inTargetClass, modelica_metatype _inIH, modelica_metatype *out_outVersionedTargetClass, modelica_metatype *out_outIH)
{
modelica_metatype _outVersionedTargetClassEnv = NULL;
modelica_metatype _outVersionedTargetClass = NULL;
modelica_metatype _outIH = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _gclass = NULL;
modelica_metatype _classRef = NULL;
modelica_metatype _sourceRef = NULL;
modelica_metatype _targetClassParentRef = NULL;
modelica_metatype _crefPrefix = NULL;
modelica_metatype _c = NULL;
modelica_string _targetClassName = NULL;
modelica_string _newTargetClassName = NULL;
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
_c = _inTargetClass;
_gclass = _inTargetClassEnv;
_targetClassName = omc_SCodeUtil_elementName(threadData, _c);
_newTargetClassName = omc_FGraph_mkVersionName(threadData, _inSourceEnv, _inSourceName, _inPrefix, _inMod, _inTargetClassEnv, _targetClassName ,&_crefPrefix);
_sourceRef = omc_FNode_child(threadData, omc_FGraph_lastScopeRef(threadData, _inSourceEnv), _inSourceName);
tmpMeta6 = mmc_mk_cons(_sourceRef, omc_FGraph_currentScope(threadData, _inSourceEnv));
_targetClassParentRef = omc_FGraph_lastScopeRef(threadData, _inTargetClassEnv);
_classRef = omc_FNode_child(threadData, _targetClassParentRef, _targetClassName);
_classRef = omc_FNode_copyRefNoUpdate(threadData, _classRef);
tmpMeta7 = omc_FNode_refData(threadData, _classRef);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,3,5) == 0) goto goto_2;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_c = tmpMeta8;
_c = omc_SCodeUtil_setClassName(threadData, _newTargetClassName, _c);
tmpMeta9 = mmc_mk_box2(10, &FCore_Status_CLS__INSTANCE__desc, _targetClassName);
_classRef = omc_FGraph_updateClassElement(threadData, _classRef, _c, _crefPrefix, _inMod, tmpMeta9, omc_FGraph_empty(threadData));
omc_FNode_addChildRef(threadData, _targetClassParentRef, _newTargetClassName, _classRef, 0);
tmpMeta10 = mmc_mk_cons(_classRef, omc_FGraph_currentScope(threadData, _gclass));
_sourceRef = omc_FGraph_updateSourceTargetScope(threadData, _sourceRef, tmpMeta10);
_ih = _inIH;
tmpMeta[0+0] = _gclass;
tmpMeta[0+1] = _c;
tmpMeta[0+2] = _ih;
goto tmp3_done;
}
case 1: {
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
_c = _inTargetClass;
_targetClassName = omc_SCodeUtil_elementName(threadData, _c);
_newTargetClassName = omc_FGraph_mkVersionName(threadData, _inSourceEnv, _inSourceName, _inPrefix, _inMod, _inTargetClassEnv, _targetClassName, NULL);
tmpMeta11 = stringAppend(_OMC_LIT13,omc_FGraph_getGraphNameStr(threadData, _inSourceEnv));
tmpMeta12 = stringAppend(tmpMeta11,_OMC_LIT14);
tmpMeta13 = stringAppend(tmpMeta12,_inSourceName);
tmpMeta14 = stringAppend(tmpMeta13,_OMC_LIT15);
tmpMeta15 = stringAppend(tmpMeta14,omc_FGraph_getGraphNameStr(threadData, _inTargetClassEnv));
tmpMeta16 = stringAppend(tmpMeta15,_OMC_LIT16);
tmpMeta17 = stringAppend(tmpMeta16,_targetClassName);
tmpMeta18 = stringAppend(tmpMeta17,omc_SCodeDump_printModStr(threadData, omc_Mod_unelabMod(threadData, _inMod), _OMC_LIT17));
tmpMeta19 = stringAppend(tmpMeta18,_OMC_LIT18);
tmpMeta20 = stringAppend(tmpMeta19,_newTargetClassName);
tmpMeta21 = stringAppend(tmpMeta20,_OMC_LIT3);
omc_Error_addCompilerWarning(threadData, tmpMeta21);
tmpMeta[0+0] = _inTargetClassEnv;
tmpMeta[0+1] = _inTargetClass;
tmpMeta[0+2] = _inIH;
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
_outVersionedTargetClassEnv = tmpMeta[0+0];
_outVersionedTargetClass = tmpMeta[0+1];
_outIH = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outVersionedTargetClass) { *out_outVersionedTargetClass = _outVersionedTargetClass; }
if (out_outIH) { *out_outIH = _outIH; }
return _outVersionedTargetClassEnv;
}
DLLExport
modelica_metatype omc_FGraph_updateScope(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outGraph = _inGraph;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraph_cloneLastScopeRef(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _r = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outGraph = omc_FGraph_stripLastScopeRef(threadData, _inGraph ,&_r);
_r = omc_FNode_copyRefNoUpdate(threadData, _r);
_outGraph = omc_FGraph_pushScopeRef(threadData, _outGraph, _r);
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraph_removeComponentsFromScope(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _r = NULL;
modelica_metatype _n = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_r = omc_FGraph_lastScopeRef(threadData, _inGraph);
_r = omc_FNode_copyRefNoUpdate(threadData, _r);
_n = omc_FNode_fromRef(threadData, _r);
_n = omc_FNode_setChildren(threadData, _n, omc_FCore_RefTree_new(threadData));
_r = omc_FNode_updateRef(threadData, _r, _n);
_outGraph = omc_FGraph_stripLastScopeRef(threadData, _inGraph, NULL);
_outGraph = omc_FGraph_pushScopeRef(threadData, _outGraph, _r);
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraph_getVariablesFromGraphScope(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_metatype _variables = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
{
modelica_metatype _r = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
_r = tmpMeta10;
tmpMeta1 = omc_List_map(threadData, omc_FNode_filter(threadData, _r, boxvar_FNode_isRefComponent), boxvar_FNode_refName);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_variables = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _variables;
}
DLLExport
modelica_metatype omc_FGraph_splitGraphScope__dispatch(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inAcc, modelica_metatype *out_outForScope)
{
modelica_metatype _outRealGraph = NULL;
modelica_metatype _outForScope = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
{
modelica_metatype _g = NULL;
modelica_metatype _r = NULL;
modelica_metatype _s = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta[0+0] = _inGraph;
tmpMeta[0+1] = listReverse(_inAcc);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
_r = tmpMeta7;
if(omc_FNode_isImplicitRefName(threadData, _r))
{
_g = omc_FGraph_stripLastScopeRef(threadData, _inGraph, NULL);
tmpMeta9 = mmc_mk_cons(_r, _inAcc);
_g = omc_FGraph_splitGraphScope__dispatch(threadData, _g, tmpMeta9 ,&_s);
}
else
{
_g = _inGraph;
_s = listReverse(_inAcc);
}
tmpMeta[0+0] = _g;
tmpMeta[0+1] = _s;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outRealGraph = tmpMeta[0+0];
_outForScope = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outForScope) { *out_outForScope = _outForScope; }
return _outRealGraph;
}
DLLExport
modelica_metatype omc_FGraph_splitGraphScope(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype *out_outForScope)
{
modelica_metatype _outRealGraph = NULL;
modelica_metatype _outForScope = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outRealGraph = omc_FGraph_splitGraphScope__dispatch(threadData, _inGraph, tmpMeta1 ,&_outForScope);
_return: OMC_LABEL_UNUSED
if (out_outForScope) { *out_outForScope = _outForScope; }
return _outRealGraph;
}
DLLExport
modelica_metatype omc_FGraph_joinScopePath(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inPath)
{
modelica_metatype _outPath = NULL;
modelica_metatype _opath = NULL;
modelica_metatype _envPath = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_opath = omc_FGraph_getScopePath(threadData, _inGraph);
if(isSome(_opath))
{
tmpMeta1 = _opath;
if (optionNone(tmpMeta1)) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
_envPath = tmpMeta2;
_outPath = omc_AbsynUtil_joinPaths(threadData, _envPath, _inPath);
}
else
{
_outPath = _inPath;
}
_return: OMC_LABEL_UNUSED
return _outPath;
}
DLLExport
modelica_boolean omc_FGraph_isImplicitScope(threadData_t *threadData, modelica_string _inName)
{
modelica_boolean _isImplicit;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_isImplicit = omc_FCore_isImplicitScope(threadData, _inName);
_return: OMC_LABEL_UNUSED
return _isImplicit;
}
modelica_metatype boxptr_FGraph_isImplicitScope(threadData_t *threadData, modelica_metatype _inName)
{
modelica_boolean _isImplicit;
modelica_metatype out_isImplicit;
_isImplicit = omc_FGraph_isImplicitScope(threadData, _inName);
out_isImplicit = mmc_mk_icon(_isImplicit);
return out_isImplicit;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraph_getGraphPathNoImplicitScope__dispatch(threadData_t *threadData, modelica_metatype _inScope)
{
modelica_metatype _outAbsynPathOption = NULL;
modelica_metatype _opath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inScope;
{
modelica_string _id = NULL;
modelica_metatype _path = NULL;
modelica_metatype _path_1 = NULL;
modelica_metatype _rest = NULL;
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
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_ref = tmpMeta6;
_rest = tmpMeta7;
if (!(!omc_FNode_isRefTop(threadData, _ref))) goto tmp3_end;
_id = omc_FNode_refName(threadData, _ref);
if(omc_FGraph_isImplicitScope(threadData, _id))
{
_opath = omc_FGraph_getGraphPathNoImplicitScope__dispatch(threadData, _rest);
}
else
{
_opath = omc_FGraph_getGraphPathNoImplicitScope__dispatch(threadData, _rest);
if(isSome(_opath))
{
tmpMeta8 = _opath;
if (optionNone(tmpMeta8)) goto goto_2;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 1));
_path = tmpMeta9;
tmpMeta10 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _id);
_path_1 = omc_AbsynUtil_joinPaths(threadData, _path, tmpMeta10);
_opath = mmc_mk_some(_path_1);
}
else
{
tmpMeta11 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _id);
_opath = mmc_mk_some(tmpMeta11);
}
}
tmpMeta1 = _opath;
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
_outAbsynPathOption = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynPathOption;
}
DLLExport
modelica_metatype omc_FGraph_getGraphPathNoImplicitScope(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_metatype _outAbsynPathOption = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outAbsynPathOption = omc_FGraph_getGraphPathNoImplicitScope__dispatch(threadData, omc_FGraph_currentScope(threadData, _inGraph));
_return: OMC_LABEL_UNUSED
return _outAbsynPathOption;
}
DLLExport
modelica_metatype omc_FGraph_getScopeRestriction(threadData_t *threadData, modelica_metatype _inScope)
{
modelica_metatype _outRestriction = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inScope;
{
modelica_metatype _r = NULL;
modelica_metatype _st = NULL;
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_r = tmpMeta6;
if (!omc_FNode_isRefClass(threadData, _r)) goto tmp3_end;
tmpMeta1 = omc_SCodeUtil_getClassRestriction(threadData, omc_FNode_getElement(threadData, omc_FNode_fromRef(threadData, _r)));
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_1);
tmpMeta9 = MMC_CDR(tmp4_1);
_r = tmpMeta8;
tmpMeta10 = omc_FNode_fromRef(threadData, _r);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,21,1) == 0) goto goto_2;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
if (optionNone(tmpMeta12)) goto goto_2;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 1));
_st = tmpMeta13;
tmpMeta1 = omc_FGraph_scopeTypeToRestriction(threadData, _st);
goto tmp3_done;
}
case 2: {
tmpMeta1 = omc_FGraph_getScopeRestriction(threadData, listRest(_inScope));
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
_outRestriction = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outRestriction;
}
DLLExport
modelica_metatype omc_FGraph_lastScopeRestriction(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_metatype _outRestriction = NULL;
modelica_metatype _s = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inGraph;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,0,2) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_s = tmpMeta2;
_outRestriction = omc_FGraph_getScopeRestriction(threadData, _s);
_return: OMC_LABEL_UNUSED
return _outRestriction;
}
DLLExport
modelica_boolean omc_FGraph_checkScopeType(threadData_t *threadData, modelica_metatype _inScope, modelica_metatype _inScopeType)
{
modelica_boolean _yes;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inScope;
{
modelica_metatype _r = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _restr = NULL;
modelica_metatype _st = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp4 += 3;
tmp1 = 0;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_boolean tmp8;
modelica_boolean tmp9;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_r = tmpMeta6;
tmp8 = omc_FNode_isRefClass(threadData, _r);
if (1 != tmp8) goto goto_2;
_restr = omc_SCodeUtil_getClassRestriction(threadData, omc_FNode_getElement(threadData, omc_FNode_fromRef(threadData, _r)));
tmp9 = valueEq(omc_FGraph_restrictionToScopeType(threadData, _restr), _inScopeType);
if (1 != tmp9) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_boolean tmp15;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
_r = tmpMeta10;
tmpMeta12 = omc_FNode_fromRef(threadData, _r);
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,21,1) == 0) goto goto_2;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
_st = tmpMeta14;
tmp15 = valueEq(_st, _inScopeType);
if (1 != tmp15) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmp4_1);
tmpMeta17 = MMC_CDR(tmp4_1);
_rest = tmpMeta17;
tmp1 = omc_FGraph_checkScopeType(threadData, _rest, _inScopeType);
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
_yes = tmp1;
_return: OMC_LABEL_UNUSED
return _yes;
}
modelica_metatype boxptr_FGraph_checkScopeType(threadData_t *threadData, modelica_metatype _inScope, modelica_metatype _inScopeType)
{
modelica_boolean _yes;
modelica_metatype out_yes;
_yes = omc_FGraph_checkScopeType(threadData, _inScope, _inScopeType);
out_yes = mmc_mk_icon(_yes);
return out_yes;
}
DLLExport
modelica_string omc_FGraph_getScopeName(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_string _name = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _r = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
_r = omc_FGraph_lastScopeRef(threadData, _inGraph);
tmp6 = omc_FNode_isRefTop(threadData, _r);
if (0 != tmp6) goto goto_2;
tmp1 = omc_FNode_refName(threadData, _r);
goto tmp3_done;
}
}
goto tmp3_end;
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
modelica_boolean omc_FGraph_inFunctionScope(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_boolean _inFunction;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
{
modelica_metatype _s = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_s = tmpMeta6;
if (!(omc_FGraph_checkScopeType(threadData, _s, _OMC_LIT20) || omc_FGraph_checkScopeType(threadData, _s, _OMC_LIT22))) goto tmp3_end;
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
_inFunction = tmp1;
_return: OMC_LABEL_UNUSED
return _inFunction;
}
modelica_metatype boxptr_FGraph_inFunctionScope(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_boolean _inFunction;
modelica_metatype out_inFunction;
_inFunction = omc_FGraph_inFunctionScope(threadData, _inGraph);
out_inFunction = mmc_mk_icon(_inFunction);
return out_inFunction;
}
DLLExport
modelica_string omc_FGraph_printGraphStr(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_string _s = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_s = _OMC_LIT23;
_return: OMC_LABEL_UNUSED
return _s;
}
DLLExport
modelica_boolean omc_FGraph_isEmptyScope(threadData_t *threadData, modelica_metatype _graph)
{
modelica_boolean _isEmpty;
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
_isEmpty = omc_FCore_RefTree_isEmpty(threadData, omc_FNode_children(threadData, omc_FNode_fromRef(threadData, omc_FGraph_lastScopeRef(threadData, _graph))));
goto tmp2_done;
}
case 1: {
_isEmpty = 1;
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
return _isEmpty;
}
modelica_metatype boxptr_FGraph_isEmptyScope(threadData_t *threadData, modelica_metatype _graph)
{
modelica_boolean _isEmpty;
modelica_metatype out_isEmpty;
_isEmpty = omc_FGraph_isEmptyScope(threadData, _graph);
out_isEmpty = mmc_mk_icon(_isEmpty);
return out_isEmpty;
}
DLLExport
modelica_boolean omc_FGraph_isNotEmpty(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = (!omc_FGraph_isEmpty(threadData, _inGraph));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FGraph_isNotEmpty(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FGraph_isNotEmpty(threadData, _inGraph);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_FGraph_isEmpty(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FGraph_isEmpty(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FGraph_isEmpty(threadData, _inGraph);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_metatype omc_FGraph_classInfToScopeType(threadData_t *threadData, modelica_metatype _inState)
{
modelica_metatype _outType = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inState;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT20;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _OMC_LIT25;
goto tmp3_done;
}
}
goto tmp3_end;
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
DLLExport
modelica_metatype omc_FGraph_mkDefunitNode(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inDu)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
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
_r = omc_FGraph_lastScopeRef(threadData, _g);
tmpMeta1 = omc_FGraphBuildEnv_mkElementNode(threadData, _inDu, _r, _OMC_LIT26, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraph_mkImportNode(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inImport)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
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
_r = omc_FGraph_lastScopeRef(threadData, _g);
tmpMeta1 = omc_FGraphBuildEnv_mkElementNode(threadData, _inImport, _r, _OMC_LIT26, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraph_mkTypeNode(threadData_t *threadData, modelica_metatype _inGraph, modelica_string _inName, modelica_metatype _inType)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
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
_g = tmp4_1;
_r = omc_FGraph_lastScopeRef(threadData, _g);
tmpMeta6 = mmc_mk_cons(_inType, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_FGraphBuildEnv_mkTypeNode(threadData, tmpMeta6, _r, _inName, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraph_mkClassNode(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inClass, modelica_metatype _inPrefix, modelica_metatype _inMod, modelica_boolean _checkDuplicate)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inGraph;
tmp4_2 = _inClass;
{
modelica_string _n = NULL;
modelica_metatype _g = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,8) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_n = tmpMeta6;
_g = tmp4_1;
_r = omc_FGraph_lastScopeRef(threadData, _g);
_r = omc_FNode_child(threadData, _r, _n);
tmpMeta7 = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,3,5) == 0) goto goto_2;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,7,1) == 0) goto goto_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,8) == 0) goto tmp3_end;
_g = tmp4_1;
_r = omc_FGraph_lastScopeRef(threadData, _g);
tmpMeta1 = omc_FGraphBuildEnv_mkClassNode(threadData, _inClass, _inPrefix, _inMod, _r, _OMC_LIT26, _g, _checkDuplicate);
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
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
modelica_metatype boxptr_FGraph_mkClassNode(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inClass, modelica_metatype _inPrefix, modelica_metatype _inMod, modelica_metatype _checkDuplicate)
{
modelica_integer tmp1;
modelica_metatype _outGraph = NULL;
tmp1 = mmc_unbox_integer(_checkDuplicate);
_outGraph = omc_FGraph_mkClassNode(threadData, _inGraph, _inClass, _inPrefix, _inMod, tmp1);
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraph_mkComponentNode(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inVar, modelica_metatype _inVarEl, modelica_metatype _inMod, modelica_metatype _instStatus, modelica_metatype _inCompGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;volatile modelica_metatype tmp4_5;volatile modelica_metatype tmp4_6;
tmp4_1 = _inGraph;
tmp4_2 = _inVar;
tmp4_3 = _inVarEl;
tmp4_4 = _inMod;
tmp4_5 = _instStatus;
tmp4_6 = _inCompGraph;
{
modelica_metatype _v = NULL;
modelica_string _n = NULL;
modelica_metatype _c = NULL;
modelica_metatype _g = NULL;
modelica_metatype _cg = NULL;
modelica_metatype _m = NULL;
modelica_metatype _r = NULL;
modelica_metatype _i = NULL;
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
modelica_boolean tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_n = tmpMeta6;
_c = tmp4_3;
tmp7 = (stringEqual(_n, omc_SCodeUtil_elementName(threadData, _c)));
if (0 != tmp7) goto goto_2;
tmpMeta8 = stringAppend(_OMC_LIT27,omc_SCodeUtil_elementName(threadData, _c));
tmpMeta9 = stringAppend(tmpMeta8,_OMC_LIT28);
tmpMeta10 = stringAppend(tmpMeta9,_n);
tmpMeta11 = stringAppend(tmpMeta10,_OMC_LIT3);
omc_Error_addCompilerError(threadData, tmpMeta11);
goto goto_2;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta12;
modelica_boolean tmp13;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_g = tmp4_1;
_v = tmp4_2;
_n = tmpMeta12;
_c = tmp4_3;
_m = tmp4_4;
_i = tmp4_5;
_cg = tmp4_6;
tmp13 = (stringEqual(_n, omc_SCodeUtil_elementName(threadData, _c)));
if (1 != tmp13) goto goto_2;
_r = omc_FGraph_lastScopeRef(threadData, _g);
_g = omc_FGraphBuildEnv_mkCompNode(threadData, _c, _r, _OMC_LIT26, _g);
tmpMeta1 = omc_FGraph_updateVarAndMod(threadData, _g, _v, _m, _i, _cg);
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
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraph_pathStripGraphScopePrefix2(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inEnvPath, modelica_boolean _stripPartial)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_boolean tmp4_3;
tmp4_1 = _inPath;
tmp4_2 = _inEnvPath;
tmp4_3 = _stripPartial;
{
modelica_string _id1 = NULL;
modelica_string _id2 = NULL;
modelica_metatype _path = NULL;
modelica_metatype _env_path = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_id1 = tmpMeta6;
_path = tmpMeta7;
_id2 = tmpMeta8;
_env_path = tmpMeta9;
if (!(stringEqual(_id1, _id2))) goto tmp3_end;
_inPath = _path;
_inEnvPath = _env_path;
goto _tailrecursive;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_id1 = tmpMeta10;
_path = tmpMeta11;
_id2 = tmpMeta12;
if (!(stringEqual(_id1, _id2))) goto tmp3_end;
tmpMeta1 = _path;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
if (1 != tmp4_3) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_id1 = tmpMeta13;
_env_path = tmp4_2;
if (!(!(stringEqual(_id1, omc_AbsynUtil_pathFirstIdent(threadData, _env_path))))) goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_FGraph_pathStripGraphScopePrefix2(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inEnvPath, modelica_metatype _stripPartial)
{
modelica_integer tmp1;
modelica_metatype _outPath = NULL;
tmp1 = mmc_unbox_integer(_stripPartial);
_outPath = omc_FGraph_pathStripGraphScopePrefix2(threadData, _inPath, _inEnvPath, tmp1);
return _outPath;
}
DLLExport
modelica_metatype omc_FGraph_pathStripGraphScopePrefix(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inEnv, modelica_boolean _stripPartial)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _env_path = NULL;
modelica_metatype _path1 = NULL;
modelica_metatype _path2 = NULL;
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
tmp6 = omc_Flags_isSet(threadData, _OMC_LIT32);
if (0 != tmp6) goto goto_2;
tmpMeta1 = _inPath;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_boolean tmp9;
tmpMeta7 = omc_FGraph_getScopePath(threadData, _inEnv);
if (optionNone(tmpMeta7)) goto goto_2;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
_env_path = tmpMeta8;
_path1 = omc_AbsynUtil_makeNotFullyQualified(threadData, _inPath);
_env_path = omc_AbsynUtil_makeNotFullyQualified(threadData, _env_path);
_path2 = omc_FGraph_pathStripGraphScopePrefix2(threadData, _path1, _env_path, _stripPartial);
tmp9 = omc_AbsynUtil_pathEqual(threadData, _path1, _path2);
if (0 != tmp9) goto goto_2;
tmpMeta1 = _path2;
goto tmp3_done;
}
case 2: {
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
if (++tmp4 < 3) {
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
modelica_metatype boxptr_FGraph_pathStripGraphScopePrefix(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inEnv, modelica_metatype _stripPartial)
{
modelica_integer tmp1;
modelica_metatype _outPath = NULL;
tmp1 = mmc_unbox_integer(_stripPartial);
_outPath = omc_FGraph_pathStripGraphScopePrefix(threadData, _inPath, _inEnv, tmp1);
return _outPath;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraph_crefStripGraphScopePrefix2(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inEnvPath, modelica_boolean _stripPartial)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_boolean tmp4_3;
tmp4_1 = _inCref;
tmp4_2 = _inEnvPath;
tmp4_3 = _stripPartial;
{
modelica_string _id1 = NULL;
modelica_string _id2 = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _env_path = NULL;
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
modelica_boolean tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!listEmpty(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id2 = tmpMeta6;
_env_path = tmpMeta7;
_id1 = tmpMeta8;
_cref = tmpMeta10;
tmp4 += 1;
tmp11 = (stringEqual(_id1, _id2));
if (1 != tmp11) goto goto_2;
tmpMeta1 = omc_FGraph_crefStripGraphScopePrefix2(threadData, _cref, _env_path, _stripPartial);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_boolean tmp16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!listEmpty(tmpMeta14)) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id2 = tmpMeta12;
_id1 = tmpMeta13;
_cref = tmpMeta15;
tmp16 = (stringEqual(_id1, _id2));
if (1 != tmp16) goto goto_2;
tmpMeta1 = _cref;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_boolean tmp19;
if (1 != tmp4_3) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!listEmpty(tmpMeta18)) goto tmp3_end;
_id1 = tmpMeta17;
_env_path = tmp4_2;
tmp19 = (stringEqual(_id1, omc_AbsynUtil_pathFirstIdent(threadData, _env_path)));
if (0 != tmp19) goto goto_2;
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_FGraph_crefStripGraphScopePrefix2(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inEnvPath, modelica_metatype _stripPartial)
{
modelica_integer tmp1;
modelica_metatype _outCref = NULL;
tmp1 = mmc_unbox_integer(_stripPartial);
_outCref = omc_FGraph_crefStripGraphScopePrefix2(threadData, _inCref, _inEnvPath, tmp1);
return _outCref;
}
DLLExport
modelica_metatype omc_FGraph_crefStripGraphScopePrefix(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inEnv, modelica_boolean _stripPartial)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _env_path = NULL;
modelica_metatype _cref1 = NULL;
modelica_metatype _cref2 = NULL;
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
tmp6 = omc_Flags_isSet(threadData, _OMC_LIT32);
if (0 != tmp6) goto goto_2;
tmpMeta1 = _inCref;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_boolean tmp9;
tmpMeta7 = omc_FGraph_getScopePath(threadData, _inEnv);
if (optionNone(tmpMeta7)) goto goto_2;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
_env_path = tmpMeta8;
_cref1 = omc_AbsynUtil_unqualifyCref(threadData, _inCref);
_env_path = omc_AbsynUtil_makeNotFullyQualified(threadData, _env_path);
_cref2 = omc_FGraph_crefStripGraphScopePrefix2(threadData, _cref1, _env_path, _stripPartial);
tmp9 = omc_AbsynUtil_crefEqual(threadData, _cref1, _cref2);
if (0 != tmp9) goto goto_2;
tmpMeta1 = _cref2;
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
modelica_metatype boxptr_FGraph_crefStripGraphScopePrefix(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inEnv, modelica_metatype _stripPartial)
{
modelica_integer tmp1;
modelica_metatype _outCref = NULL;
tmp1 = mmc_unbox_integer(_stripPartial);
_outCref = omc_FGraph_crefStripGraphScopePrefix(threadData, _inCref, _inEnv, tmp1);
return _outCref;
}
DLLExport
modelica_boolean omc_FGraph_isTopScope(threadData_t *threadData, modelica_metatype _graph)
{
modelica_boolean _isTop;
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
modelica_boolean tmp6;
tmp6 = omc_FNode_isRefTop(threadData, omc_FGraph_lastScopeRef(threadData, _graph));
if (1 != tmp6) goto goto_2;
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
_isTop = tmp1;
_return: OMC_LABEL_UNUSED
return _isTop;
}
modelica_metatype boxptr_FGraph_isTopScope(threadData_t *threadData, modelica_metatype _graph)
{
modelica_boolean _isTop;
modelica_metatype out_isTop;
_isTop = omc_FGraph_isTopScope(threadData, _graph);
out_isTop = mmc_mk_icon(_isTop);
return out_isTop;
}
DLLExport
modelica_metatype omc_FGraph_scopeTypeToRestriction(threadData_t *threadData, modelica_metatype _inScopeType)
{
modelica_metatype _outRestriction = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inScopeType;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
tmpMeta1 = _OMC_LIT34;
goto tmp3_done;
}
case 3: {
tmpMeta1 = _OMC_LIT36;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmpMeta1 = _OMC_LIT37;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outRestriction = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outRestriction;
}
DLLExport
modelica_metatype omc_FGraph_restrictionToScopeType(threadData_t *threadData, modelica_metatype _inRestriction)
{
modelica_metatype _outType = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inRestriction;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,4,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT22;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,5,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT22;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT20;
goto tmp3_done;
}
case 3: {
tmpMeta1 = _OMC_LIT25;
goto tmp3_done;
}
}
goto tmp3_end;
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
DLLExport
modelica_metatype omc_FGraph_setScope(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fgraph, modelica_metatype _inScope)
{
modelica_metatype _graph = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_graph = __omcQ_24in_5Fgraph;
{
modelica_metatype tmp3_1;
tmp3_1 = _graph;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_graph), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[3] = _inScope;
_graph = tmpMeta5;
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
return _graph;
}
DLLExport
modelica_metatype omc_FGraph_pushScope(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fgraph, modelica_metatype _inScope)
{
modelica_metatype _graph = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_graph = __omcQ_24in_5Fgraph;
{
modelica_metatype tmp3_1;
tmp3_1 = _graph;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_graph), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[3] = listAppend(_inScope, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_graph), 3))));
_graph = tmpMeta5;
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
return _graph;
}
DLLExport
modelica_metatype omc_FGraph_pushScopeRef(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fgraph, modelica_metatype _inRef)
{
modelica_metatype _graph = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_graph = __omcQ_24in_5Fgraph;
{
modelica_metatype tmp3_1;
tmp3_1 = _graph;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
tmpMeta6 = mmc_mk_cons(_inRef, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_graph), 3))));
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_graph), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[3] = tmpMeta6;
_graph = tmpMeta5;
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
return _graph;
}
DLLExport
modelica_metatype omc_FGraph_getGraphNameNoImplicitScopes(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_metatype _outPath = NULL;
modelica_metatype _p = NULL;
modelica_metatype _s = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = listReverse(omc_FGraph_currentScope(threadData, _inGraph));
if (listEmpty(tmpMeta1)) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_CAR(tmpMeta1);
tmpMeta3 = MMC_CDR(tmpMeta1);
_s = tmpMeta3;
{
modelica_metatype __omcQ_24tmpVar3;
modelica_metatype* tmp5;
modelica_metatype tmpMeta6;
modelica_string __omcQ_24tmpVar2;
modelica_integer tmp7;
modelica_metatype _str_loopVar = 0;
modelica_metatype tmpMeta8;
modelica_metatype _str;
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp9;
modelica_metatype tmpMeta10;
modelica_string __omcQ_24tmpVar0;
modelica_integer tmp11;
modelica_metatype _n_loopVar = 0;
modelica_metatype _n;
_n_loopVar = _s;
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta10;
tmp9 = &__omcQ_24tmpVar1;
while(1) {
tmp11 = 1;
if (!listEmpty(_n_loopVar)) {
_n = MMC_CAR(_n_loopVar);
_n_loopVar = MMC_CDR(_n_loopVar);
tmp11--;
}
if (tmp11 == 0) {
__omcQ_24tmpVar0 = omc_FNode_refName(threadData, _n);
*tmp9 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp9 = &MMC_CDR(*tmp9);
} else if (tmp11 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp9 = mmc_mk_nil();
tmpMeta8 = __omcQ_24tmpVar1;
}
_str_loopVar = tmpMeta8;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta6;
tmp5 = &__omcQ_24tmpVar3;
while(1) {
tmp7 = 1;
while (!listEmpty(_str_loopVar)) {
_str = MMC_CAR(_str_loopVar);
_str_loopVar = MMC_CDR(_str_loopVar);
if ((stringGet(_str, ((modelica_integer) 1)) != ((modelica_integer) 36))) {
tmp7--;
break;
}
}
if (tmp7 == 0) {
__omcQ_24tmpVar2 = _str;
*tmp5 = mmc_mk_cons(__omcQ_24tmpVar2,0);
tmp5 = &MMC_CDR(*tmp5);
} else if (tmp7 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp5 = mmc_mk_nil();
tmpMeta4 = __omcQ_24tmpVar3;
}
_outPath = omc_AbsynUtil_stringListPath(threadData, tmpMeta4);
_return: OMC_LABEL_UNUSED
return _outPath;
}
DLLExport
modelica_metatype omc_FGraph_getGraphName(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_metatype _outPath = NULL;
modelica_metatype _p = NULL;
modelica_metatype _s = NULL;
modelica_metatype _r = NULL;
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
tmpMeta1 = omc_FGraph_currentScope(threadData, _inGraph);
if (listEmpty(tmpMeta1)) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_CAR(tmpMeta1);
tmpMeta3 = MMC_CDR(tmpMeta1);
_r = tmpMeta2;
_s = tmpMeta3;
_p = omc_AbsynUtil_makeIdentPathFromString(threadData, omc_FNode_refName(threadData, _r));
{
modelica_metatype _r;
for (tmpMeta4 = _s; !listEmpty(tmpMeta4); tmpMeta4=MMC_CDR(tmpMeta4))
{
_r = MMC_CAR(tmpMeta4);
tmpMeta5 = mmc_mk_box3(3, &Absyn_Path_QUALIFIED__desc, omc_FNode_refName(threadData, _r), _p);
_p = tmpMeta5;
}
}
tmpMeta7 = _p;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,2) == 0) MMC_THROW_INTERNAL();
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
_outPath = tmpMeta8;
_return: OMC_LABEL_UNUSED
return _outPath;
}
DLLExport
modelica_string omc_FGraph_getGraphNameStr(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
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
tmp1 = omc_AbsynUtil_pathString(threadData, omc_FGraph_getGraphName(threadData, _inGraph), _OMC_LIT16, 1, 0);
goto tmp3_done;
}
case 1: {
tmp1 = _OMC_LIT16;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_metatype omc_FGraph_getScopePath(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _p = NULL;
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
modelica_boolean tmp9;
tmpMeta6 = omc_FGraph_currentScope(threadData, _inGraph);
if (listEmpty(tmpMeta6)) goto goto_2;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
if (!listEmpty(tmpMeta8)) goto goto_2;
_r = tmpMeta7;
tmp9 = omc_FNode_isRefTop(threadData, _r);
if (1 != tmp9) goto goto_2;
tmpMeta1 = mmc_mk_none();
goto tmp3_done;
}
case 1: {
_p = omc_FGraph_getGraphName(threadData, _inGraph);
tmpMeta1 = mmc_mk_some(_p);
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
modelica_boolean omc_FGraph_inForOrParforIterLoopScope(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
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
modelica_boolean tmp6;
_name = omc_FNode_refName(threadData, listHead(omc_FGraph_currentScope(threadData, _inGraph)));
tmp6 = ((stringEqual(_name, _OMC_LIT38)) || (stringEqual(_name, _OMC_LIT39)));
if (1 != tmp6) goto goto_2;
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_FGraph_inForOrParforIterLoopScope(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_FGraph_inForOrParforIterLoopScope(threadData, _inGraph);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_boolean omc_FGraph_inForLoopScope(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
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
modelica_boolean tmp6;
_name = omc_FNode_refName(threadData, listHead(omc_FGraph_currentScope(threadData, _inGraph)));
tmp6 = (stringEqual(_name, _OMC_LIT40));
if (1 != tmp6) goto goto_2;
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_FGraph_inForLoopScope(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_FGraph_inForLoopScope(threadData, _inGraph);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_metatype omc_FGraph_openScope(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _encapsulatedPrefix, modelica_string _inName, modelica_metatype _inScopeType)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _p = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_p = omc_FGraph_lastScopeRef(threadData, _inGraph);
{
volatile modelica_metatype tmp4_1;volatile modelica_string tmp4_2;
tmp4_1 = _inGraph;
tmp4_2 = _inName;
{
modelica_metatype _g = NULL;
modelica_string _n = NULL;
modelica_metatype _no = NULL;
modelica_metatype _r = NULL;
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
_g = tmp4_1;
_n = tmp4_2;
_r = omc_FNode_child(threadData, _p, _n);
tmpMeta6 = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,5) == 0) goto goto_2;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,7,1) == 0) goto goto_2;
omc_FNode_addChildRef(threadData, _p, _n, _r, 0);
tmpMeta1 = omc_FGraph_pushScopeRef(threadData, _g, _r);
goto tmp3_done;
}
case 1: {
_g = tmp4_1;
_n = tmp4_2;
_r = omc_FNode_child(threadData, _p, _n);
_r = omc_FNode_copyRefNoUpdate(threadData, _r);
tmpMeta1 = omc_FGraph_pushScopeRef(threadData, _g, _r);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
_g = tmp4_1;
_n = tmp4_2;
tmpMeta8 = mmc_mk_cons(_p, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta9 = mmc_mk_box2(24, &FCore_Data_ND__desc, _inScopeType);
_g = omc_FGraph_node(threadData, _g, _n, tmpMeta8, tmpMeta9 ,&_no);
_r = omc_FNode_toRef(threadData, _no);
tmpMeta1 = omc_FGraph_pushScopeRef(threadData, _g, _r);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
tmpMeta10 = stringAppend(_OMC_LIT41,omc_FGraph_getGraphNameStr(threadData, _inGraph));
tmpMeta11 = stringAppend(tmpMeta10,_OMC_LIT42);
tmpMeta12 = stringAppend(tmpMeta11,_inName);
tmpMeta13 = stringAppend(tmpMeta12,_OMC_LIT3);
omc_Error_addCompilerError(threadData, tmpMeta13);
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
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraph_openNewScope(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _encapsulatedPrefix, modelica_metatype _inName, modelica_metatype _inScopeType)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inGraph;
tmp4_2 = _inName;
{
modelica_metatype _g = NULL;
modelica_string _n = NULL;
modelica_metatype _no = NULL;
modelica_metatype _r = NULL;
modelica_metatype _p = NULL;
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
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
_n = tmpMeta6;
_g = tmp4_1;
_p = omc_FGraph_lastScopeRef(threadData, _g);
tmpMeta7 = mmc_mk_cons(_p, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta8 = mmc_mk_box2(24, &FCore_Data_ND__desc, _inScopeType);
_g = omc_FGraph_node(threadData, _g, _n, tmpMeta7, tmpMeta8 ,&_no);
_r = omc_FNode_toRef(threadData, _no);
tmpMeta1 = omc_FGraph_pushScopeRef(threadData, _g, _r);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
tmpMeta9 = stringAppend(_OMC_LIT43,omc_FGraph_getGraphNameStr(threadData, _inGraph));
tmpMeta10 = stringAppend(tmpMeta9,_OMC_LIT42);
tmpMeta11 = stringAppend(tmpMeta10,omc_Util_stringOption(threadData, _inName));
tmpMeta12 = stringAppend(tmpMeta11,_OMC_LIT3);
omc_Error_addCompilerError(threadData, tmpMeta12);
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
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_string omc_FGraph_printGraphPathStr(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
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
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
if (listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
_s = tmpMeta6;
tmpMeta11 = listReverse(_s);
if (listEmpty(tmpMeta11)) goto goto_2;
tmpMeta12 = MMC_CAR(tmpMeta11);
tmpMeta13 = MMC_CDR(tmpMeta11);
_s = tmpMeta13;
tmp1 = stringDelimitList(omc_List_map(threadData, _s, boxvar_FNode_refName), _OMC_LIT16);
goto tmp3_done;
}
case 1: {
tmp1 = _OMC_LIT44;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_metatype omc_FGraph_addForIterator(threadData_t *threadData, modelica_metatype _inGraph, modelica_string _name, modelica_metatype _ty, modelica_metatype _binding, modelica_metatype _variability, modelica_metatype _constOfForIteratorRange)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
{
modelica_metatype _g = NULL;
modelica_metatype _r = NULL;
modelica_metatype _c = NULL;
modelica_metatype _v = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
_g = tmp4_1;
tmpMeta6 = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _name, _OMC_LIT50, _OMC_LIT55, _OMC_LIT56, _OMC_LIT57, _OMC_LIT58, mmc_mk_none(), _OMC_LIT10);
_c = tmpMeta6;
tmpMeta7 = mmc_mk_box7(3, &DAE_Attributes_ATTR__desc, _OMC_LIT59, _OMC_LIT52, _variability, _OMC_LIT53, _OMC_LIT48, _OMC_LIT45);
tmpMeta8 = mmc_mk_box7(3, &DAE_Var_TYPES__VAR__desc, _name, tmpMeta7, _ty, _binding, mmc_mk_boolean(0), _constOfForIteratorRange);
_v = tmpMeta8;
_r = omc_FGraph_lastScopeRef(threadData, _g);
_g = omc_FGraphBuildEnv_mkCompNode(threadData, _c, _r, _OMC_LIT60, _g);
tmpMeta1 = omc_FGraph_updateVarAndMod(threadData, _g, _v, _OMC_LIT61, _OMC_LIT62, omc_FGraph_empty(threadData));
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraph_updateClassElement(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _inElement, modelica_metatype _inPrefix, modelica_metatype _inMod, modelica_metatype _instStatus, modelica_metatype _inTargetGraph)
{
modelica_metatype _outRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inRef;
tmp4_2 = _inElement;
{
modelica_metatype _r = NULL;
modelica_string _n = NULL;
modelica_integer _id;
modelica_metatype _p = NULL;
modelica_metatype _c = NULL;
modelica_metatype _e = NULL;
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
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,8) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_e = tmp4_2;
_n = tmpMeta6;
_r = tmp4_1;
tmpMeta7 = omc_FNode_fromRef(threadData, _r);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
tmp9 = mmc_unbox_integer(tmpMeta8);
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,3,5) == 0) goto goto_2;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 5));
_id = tmp9;
_p = tmpMeta10;
_c = tmpMeta11;
_k = tmpMeta13;
tmpMeta14 = mmc_mk_box6(6, &FCore_Data_CL__desc, _e, _inPrefix, _inMod, _k, _instStatus);
tmpMeta15 = mmc_mk_box6(3, &FCore_Node_N__desc, _n, mmc_mk_integer(_id), _p, _c, tmpMeta14);
tmpMeta1 = omc_FNode_updateRef(threadData, _r, tmpMeta15);
goto tmp3_done;
}
}
goto tmp3_end;
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
modelica_metatype omc_FGraph_updateClass(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inElement, modelica_metatype _inPrefix, modelica_metatype _inMod, modelica_metatype _instStatus, modelica_metatype _inTargetGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inGraph;
tmp4_2 = _inElement;
{
modelica_metatype _pr = NULL;
modelica_metatype _r = NULL;
modelica_string _n = NULL;
modelica_integer _id;
modelica_metatype _p = NULL;
modelica_metatype _c = NULL;
modelica_metatype _e = NULL;
modelica_metatype _k = NULL;
modelica_metatype _g = NULL;
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
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,8) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_e = tmp4_2;
_n = tmpMeta6;
_g = tmp4_1;
_pr = omc_FGraph_lastScopeRef(threadData, _g);
_r = omc_FNode_child(threadData, _pr, _n);
tmpMeta7 = omc_FNode_fromRef(threadData, _r);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
tmp10 = mmc_unbox_integer(tmpMeta9);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,3,5) == 0) goto goto_2;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 5));
_n = tmpMeta8;
_id = tmp10;
_p = tmpMeta11;
_c = tmpMeta12;
_k = tmpMeta14;
tmpMeta15 = mmc_mk_box6(6, &FCore_Data_CL__desc, _e, _inPrefix, _inMod, _k, _instStatus);
tmpMeta16 = mmc_mk_box6(3, &FCore_Node_N__desc, _n, mmc_mk_integer(_id), _p, _c, tmpMeta15);
_r = omc_FNode_updateRef(threadData, _r, tmpMeta16);
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp17;
_g = tmp4_1;
_e = tmp4_2;
_pr = omc_FGraph_lastScopeRef(threadData, _g);
tmp17 = omc_FNode_isImplicitRefName(threadData, _pr);
if (1 != tmp17) goto goto_2;
_g = omc_FGraph_stripLastScopeRef(threadData, _g, NULL);
tmpMeta1 = omc_FGraph_updateClass(threadData, _g, _e, _inPrefix, _inMod, _instStatus, _inTargetGraph);
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
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FGraph_updateVarAndMod(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inVar, modelica_metatype _inMod, modelica_metatype _instStatus, modelica_metatype _inTargetGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inGraph;
tmp4_2 = _inVar;
{
modelica_metatype _pr = NULL;
modelica_metatype _r = NULL;
modelica_string _n = NULL;
modelica_integer _id;
modelica_metatype _p = NULL;
modelica_metatype _c = NULL;
modelica_metatype _e = NULL;
modelica_metatype _v = NULL;
modelica_metatype _k = NULL;
modelica_metatype _g = NULL;
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
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_g = tmp4_1;
_v = tmp4_2;
_n = tmpMeta6;
_pr = omc_FGraph_lastScopeRef(threadData, _g);
_r = omc_FNode_child(threadData, _pr, _n);
tmpMeta7 = omc_FNode_fromRef(threadData, _r);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
tmp10 = mmc_unbox_integer(tmpMeta9);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,4,4) == 0) goto goto_2;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 4));
_n = tmpMeta8;
_id = tmp10;
_p = tmpMeta11;
_c = tmpMeta12;
_e = tmpMeta14;
_k = tmpMeta15;
tmpMeta16 = mmc_mk_box5(7, &FCore_Data_CO__desc, _e, _inMod, _k, _instStatus);
tmpMeta17 = mmc_mk_box6(3, &FCore_Node_N__desc, _n, mmc_mk_integer(_id), _p, _c, tmpMeta16);
_r = omc_FNode_updateRef(threadData, _r, tmpMeta17);
_r = omc_FGraph_updateSourceTargetScope(threadData, _r, omc_FGraph_currentScope(threadData, _inTargetGraph));
_r = omc_FGraph_updateInstance(threadData, _r, _v);
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp18;
_g = tmp4_1;
_v = tmp4_2;
_pr = omc_FGraph_lastScopeRef(threadData, _g);
tmp18 = omc_FNode_isImplicitRefName(threadData, _pr);
if (1 != tmp18) goto goto_2;
_g = omc_FGraph_stripLastScopeRef(threadData, _g, NULL);
tmpMeta1 = omc_FGraph_updateVarAndMod(threadData, _g, _v, _inMod, _instStatus, _inTargetGraph);
goto tmp3_done;
}
case 2: {
tmpMeta1 = _inGraph;
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
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraph_updateInstance(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _inVar)
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
_r = tmp4_1;
_r = omc_FNode_refInstance(threadData, _r);
tmpMeta6 = mmc_mk_box2(4, &FCore_Data_IT__desc, _inVar);
_r = omc_FNode_updateRef(threadData, _r, omc_FNode_setData(threadData, omc_FNode_fromRef(threadData, _r), tmpMeta6));
tmpMeta1 = _inRef;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
tmpMeta7 = stringAppend(_OMC_LIT63,omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _inRef)));
tmpMeta8 = stringAppend(tmpMeta7,_OMC_LIT64);
tmpMeta9 = stringAppend(tmpMeta8,omc_Types_printVarStr(threadData, _inVar));
omc_Error_addCompilerError(threadData, tmpMeta9);
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
_outRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outRef;
}
DLLExport
modelica_metatype omc_FGraph_updateSourceTargetScope(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _inTargetScope)
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
_r = tmp4_1;
_r = omc_FNode_refRef(threadData, _r);
tmpMeta6 = mmc_mk_box2(23, &FCore_Data_REF__desc, _inTargetScope);
_r = omc_FNode_updateRef(threadData, _r, omc_FNode_setData(threadData, omc_FNode_fromRef(threadData, _r), tmpMeta6));
tmpMeta1 = _inRef;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
_r = tmp4_1;
tmpMeta7 = stringAppend(_OMC_LIT65,omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _r)));
tmpMeta8 = stringAppend(tmpMeta7,_OMC_LIT66);
tmpMeta9 = stringAppend(tmpMeta8,omc_FNode_scopeStr(threadData, _inTargetScope));
tmpMeta10 = stringAppend(tmpMeta9,_OMC_LIT3);
omc_Error_addCompilerWarning(threadData, tmpMeta10);
tmpMeta1 = _inRef;
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
modelica_metatype omc_FGraph_updateComp(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inVar, modelica_metatype _instStatus, modelica_metatype _inTargetGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inGraph;
tmp4_2 = _inVar;
{
modelica_metatype _pr = NULL;
modelica_metatype _r = NULL;
modelica_string _n = NULL;
modelica_integer _id;
modelica_metatype _p = NULL;
modelica_metatype _c = NULL;
modelica_metatype _e = NULL;
modelica_metatype _v = NULL;
modelica_metatype _m = NULL;
modelica_metatype _k = NULL;
modelica_metatype _g = NULL;
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
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_g = tmp4_1;
_v = tmp4_2;
_n = tmpMeta6;
_pr = omc_FGraph_lastScopeRef(threadData, _g);
_r = omc_FNode_child(threadData, _pr, _n);
tmpMeta7 = omc_FNode_fromRef(threadData, _r);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
tmp10 = mmc_unbox_integer(tmpMeta9);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,4,4) == 0) goto goto_2;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 3));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 4));
_n = tmpMeta8;
_id = tmp10;
_p = tmpMeta11;
_c = tmpMeta12;
_e = tmpMeta14;
_m = tmpMeta15;
_k = tmpMeta16;
tmpMeta17 = mmc_mk_box5(7, &FCore_Data_CO__desc, _e, _m, _k, _instStatus);
tmpMeta18 = mmc_mk_box6(3, &FCore_Node_N__desc, _n, mmc_mk_integer(_id), _p, _c, tmpMeta17);
_r = omc_FNode_updateRef(threadData, _r, tmpMeta18);
_r = omc_FGraph_updateSourceTargetScope(threadData, _r, omc_FGraph_currentScope(threadData, _inTargetGraph));
_r = omc_FGraph_updateInstance(threadData, _r, _v);
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp19;
_g = tmp4_1;
_v = tmp4_2;
_pr = omc_FGraph_lastScopeRef(threadData, _g);
tmp19 = omc_FNode_isImplicitRefName(threadData, _pr);
if (1 != tmp19) goto goto_2;
_g = omc_FGraph_stripLastScopeRef(threadData, _g, NULL);
tmpMeta1 = omc_FGraph_updateComp(threadData, _g, _v, _instStatus, _inTargetGraph);
goto tmp3_done;
}
case 2: {
tmpMeta1 = _inGraph;
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
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraph_clone(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
{
modelica_metatype _g = NULL;
modelica_metatype _t = NULL;
modelica_metatype _nt = NULL;
modelica_metatype _s = NULL;
modelica_metatype _ag = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_t = tmpMeta6;
_s = tmpMeta7;
_nt = omc_FNode_toRef(threadData, omc_FNode_fromRef(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_t), 4)))));
_g = omc_FNode_copyRef(threadData, _nt, _inGraph ,&_nt);
_s = omc_List_map1r(threadData, _s, boxvar_FNode_lookupRefFromRef, _nt);
_ag = arrayCreate(((modelica_integer) 1), _OMC_LIT68);
tmpMeta8 = mmc_mk_box5(3, &FCore_Top_GTOP__desc, _ag, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_t), 3))), _nt, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_t), 5))));
_t = tmpMeta8;
tmpMeta9 = mmc_mk_box3(3, &FCore_Graph_G__desc, _t, _s);
_g = tmpMeta9;
arrayUpdate(_ag, ((modelica_integer) 1), _g);
tmpMeta1 = _g;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraph_node(threadData_t *threadData, modelica_metatype _inGraph, modelica_string _inName, modelica_metatype _inParents, modelica_metatype _inData, modelica_metatype *out_outNode)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _outNode = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
{
modelica_integer _i;
modelica_metatype _g = NULL;
modelica_metatype _n = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_g = tmp4_1;
_i = omc_System_tmpTickIndex(threadData, ((modelica_integer) 22));
_n = omc_FNode_new(threadData, _inName, _i, _inParents, _inData);
omc_FGraphStream_node(threadData, _n);
tmpMeta[0+0] = _g;
tmpMeta[0+1] = _n;
goto tmp3_done;
}
}
goto tmp3_end;
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
_outNode = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outNode) { *out_outNode = _outNode; }
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraph_new(threadData_t *threadData, modelica_string _inGraphName, modelica_metatype _inPath)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _n = NULL;
modelica_metatype _s = NULL;
modelica_metatype _v = NULL;
modelica_metatype _nr = NULL;
modelica_integer _next;
modelica_integer _id;
modelica_metatype _ag = NULL;
modelica_metatype _top = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_id = omc_System_tmpTickIndex(threadData, ((modelica_integer) 22));
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_n = omc_FNode_new(threadData, _OMC_LIT69, _id, tmpMeta1, _OMC_LIT70);
_nr = omc_FNode_toRef(threadData, _n);
tmpMeta2 = mmc_mk_cons(_nr, MMC_REFSTRUCTLIT(mmc_nil));
_s = tmpMeta2;
_ag = arrayCreateNoInit(((modelica_integer) 1), _OMC_LIT68);
tmpMeta3 = mmc_mk_box2(3, &FCore_Extra_EXTRA__desc, _inPath);
tmpMeta4 = mmc_mk_box5(3, &FCore_Top_GTOP__desc, _ag, _inGraphName, _nr, tmpMeta3);
_top = tmpMeta4;
tmpMeta5 = mmc_mk_box3(3, &FCore_Graph_G__desc, _top, _s);
_outGraph = tmpMeta5;
tmpMeta6 = mmc_mk_cons(_nr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta7 = mmc_mk_box3(3, &FCore_Graph_G__desc, _top, tmpMeta6);
arrayUpdate(_ag, ((modelica_integer) 1), tmpMeta7);
omc_FGraphStream_node(threadData, _n);
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraph_empty(threadData_t *threadData)
{
modelica_metatype _outGraph = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outGraph = _OMC_LIT68;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraph_topScope(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _t = NULL;
modelica_metatype _r = NULL;
modelica_metatype _s = NULL;
modelica_string _gn = NULL;
modelica_metatype _v = NULL;
modelica_metatype _e = NULL;
modelica_integer _next;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta1 = arrayGet((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inGraph), 2)))), 2))), ((modelica_integer) 1));
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraph_stripLastScopeRef(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype *out_outRef)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _outRef = NULL;
modelica_metatype _t = NULL;
modelica_metatype _s = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inGraph;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,0,2) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
if (listEmpty(tmpMeta3)) MMC_THROW_INTERNAL();
tmpMeta4 = MMC_CAR(tmpMeta3);
tmpMeta5 = MMC_CDR(tmpMeta3);
_t = tmpMeta2;
_outRef = tmpMeta4;
_s = tmpMeta5;
tmpMeta6 = mmc_mk_box3(3, &FCore_Graph_G__desc, _t, _s);
_outGraph = tmpMeta6;
_return: OMC_LABEL_UNUSED
if (out_outRef) { *out_outRef = _outRef; }
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraph_setLastScopeRef(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outGraph = _inGraph;
{
modelica_metatype tmp4_1;
tmp4_1 = _outGraph;
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
tmpMeta7 = mmc_mk_cons(_inRef, listRest((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outGraph), 3)))));
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_outGraph), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[3] = tmpMeta7;
_outGraph = tmpMeta6;
tmpMeta1 = _outGraph;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _outGraph;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FGraph_lastScopeRef(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_metatype _outRef = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outRef = listHead(omc_FGraph_currentScope(threadData, _inGraph));
_return: OMC_LABEL_UNUSED
return _outRef;
}
DLLExport
modelica_metatype omc_FGraph_currentScope(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_metatype _outScope = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
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
_outScope = tmpMeta6;
tmpMeta1 = _outScope;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
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
_outScope = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outScope;
}
DLLExport
modelica_metatype omc_FGraph_extra(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_metatype _outExtra = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inGraph), 2)))), 5)));
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outExtra = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExtra;
}
DLLExport
modelica_metatype omc_FGraph_top(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_metatype _outRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inGraph), 2)))), 4)));
goto tmp3_done;
}
}
goto tmp3_end;
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
