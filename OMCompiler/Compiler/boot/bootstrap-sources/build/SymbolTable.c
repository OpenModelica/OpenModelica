#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/SymbolTable.c"
#endif
#include "omc_simulation_settings.h"
#include "SymbolTable.h"
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT0,1,5) {&AvlTreeStringString_Tree_EMPTY__desc,}};
#define _OMC_LIT0 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "ModelicaBuiltin.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,18,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "MetaModelicaBuiltin.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,22,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,1,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "An element with name %s is already declared in this scope."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,58,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT6}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT8,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(161)),_OMC_LIT4,_OMC_LIT5,_OMC_LIT7}};
#define _OMC_LIT8 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "<interactive>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,13,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,1,11) {&DAE_Type_T__UNKNOWN__desc,}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,1,6) {&DAE_ConnectorType_NON__CONNECTOR__desc,}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT12,1,5) {&SCode_Parallelism_NON__PARALLEL__desc,}};
#define _OMC_LIT12 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT12)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT13,1,3) {&SCode_Variability_VAR__desc,}};
#define _OMC_LIT13 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT13)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT14,1,5) {&Absyn_Direction_BIDIR__desc,}};
#define _OMC_LIT14 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,1,6) {&Absyn_InnerOuter_NOT__INNER__OUTER__desc,}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT16,1,3) {&SCode_Visibility_PUBLIC__desc,}};
#define _OMC_LIT16 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT16)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT17,7,3) {&DAE_Attributes_ATTR__desc,_OMC_LIT11,_OMC_LIT12,_OMC_LIT13,_OMC_LIT14,_OMC_LIT15,_OMC_LIT16}};
#define _OMC_LIT17 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT18,1,3) {&DAE_BindingSource_BINDING__FROM__DEFAULT__VALUE__desc,}};
#define _OMC_LIT18 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,1,4) {&FCore_Status_VAR__TYPED__desc,}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT20,1,4) {&SCode_Redeclare_NOT__REDECLARE__desc,}};
#define _OMC_LIT20 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT20)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT21,1,4) {&SCode_Final_NOT__FINAL__desc,}};
#define _OMC_LIT21 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT21)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT22,1,4) {&SCode_Replaceable_NOT__REPLACEABLE__desc,}};
#define _OMC_LIT22 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT22)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT23,6,3) {&SCode_Prefixes_PREFIXES__desc,_OMC_LIT16,_OMC_LIT20,_OMC_LIT21,_OMC_LIT15,_OMC_LIT22}};
#define _OMC_LIT23 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT23)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT24,1,3) {&SCode_ConnectorType_POTENTIAL__desc,}};
#define _OMC_LIT24 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT24)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT25,1,3) {&Absyn_IsField_NONFIELD__desc,}};
#define _OMC_LIT25 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT25)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT26,7,3) {&SCode_Attributes_ATTR__desc,MMC_REFSTRUCTLIT(mmc_nil),_OMC_LIT24,_OMC_LIT12,_OMC_LIT13,_OMC_LIT14,_OMC_LIT25}};
#define _OMC_LIT26 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,0,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT28,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT27}};
#define _OMC_LIT28 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT28)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT29,3,3) {&Absyn_TypeSpec_TPATH__desc,_OMC_LIT28,MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT29 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT29)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT30,1,5) {&SCode_Mod_NOMOD__desc,}};
#define _OMC_LIT30 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT30)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT31,3,3) {&SCode_Comment_COMMENT__desc,MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT31 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT31)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT32,0.0);
#define _OMC_LIT32 MMC_REFREALLIT(_OMC_LIT_STRUCT32)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT33,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT27,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT32}};
#define _OMC_LIT33 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT33)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT34,1,5) {&DAE_Mod_NOMOD__desc,}};
#define _OMC_LIT34 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT34)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT35,1,3) {&FCore_Status_VAR__UNTYPED__desc,}};
#define _OMC_LIT35 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT35)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT36,1,8) {&ErrorTypes_MessageType_SCRIPTING__desc,}};
#define _OMC_LIT36 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT36)
#define _OMC_LIT37_data "Cannot assign slice to non-initialized array %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT37,48,_OMC_LIT37_data);
#define _OMC_LIT37 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT37)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT38,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT37}};
#define _OMC_LIT38 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT38)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT39,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(250)),_OMC_LIT36,_OMC_LIT5,_OMC_LIT38}};
#define _OMC_LIT39 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT39)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT40,1,4) {&Absyn_Within_TOP__desc,}};
#define _OMC_LIT40 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT40)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT41,3,3) {&Absyn_Program_PROGRAM__desc,MMC_REFSTRUCTLIT(mmc_nil),_OMC_LIT40}};
#define _OMC_LIT41 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT41)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT42,4,3) {&SymbolTable_SYMBOLTABLE__desc,_OMC_LIT41,MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT42 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT42)
#include "util/modelica.h"
#include "SymbolTable_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC void omc_SymbolTable_updateUriMapping(threadData_t *threadData, modelica_metatype _classes);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_updateUriMapping,2,0) {(void*) boxptr_SymbolTable_updateUriMapping,0}};
#define boxvar_SymbolTable_updateUriMapping MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_updateUriMapping)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SymbolTable_addVarToEnv(threadData_t *threadData, modelica_metatype _inVariable, modelica_metatype _inEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_addVarToEnv,2,0) {(void*) boxptr_SymbolTable_addVarToEnv,0}};
#define boxvar_SymbolTable_addVarToEnv MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_addVarToEnv)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SymbolTable_addVarsToEnv(threadData_t *threadData, modelica_metatype _inVariableLst, modelica_metatype _inEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_addVarsToEnv,2,0) {(void*) boxptr_SymbolTable_addVarsToEnv,0}};
#define boxvar_SymbolTable_addVarsToEnv MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_addVarsToEnv)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SymbolTable_addVarToVarList4(threadData_t *threadData, modelica_boolean _inFound, modelica_metatype _inCref, modelica_metatype _inValue, modelica_metatype _inVariables);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SymbolTable_addVarToVarList4(threadData_t *threadData, modelica_metatype _inFound, modelica_metatype _inCref, modelica_metatype _inValue, modelica_metatype _inVariables);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_addVarToVarList4,2,0) {(void*) boxptr_SymbolTable_addVarToVarList4,0}};
#define boxvar_SymbolTable_addVarToVarList4 MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_addVarToVarList4)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SymbolTable_addVarToVarList3(threadData_t *threadData, modelica_boolean _inFound, modelica_metatype _inOldVariable, modelica_metatype _inCref, modelica_metatype _inValue, modelica_metatype _inEnv);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SymbolTable_addVarToVarList3(threadData_t *threadData, modelica_metatype _inFound, modelica_metatype _inOldVariable, modelica_metatype _inCref, modelica_metatype _inValue, modelica_metatype _inEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_addVarToVarList3,2,0) {(void*) boxptr_SymbolTable_addVarToVarList3,0}};
#define boxvar_SymbolTable_addVarToVarList3 MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_addVarToVarList3)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SymbolTable_addVarToVarList2(threadData_t *threadData, modelica_metatype _inOldVariable, modelica_metatype _inCref, modelica_metatype _inValue, modelica_metatype _inEnv, modelica_boolean *out_outFound);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SymbolTable_addVarToVarList2(threadData_t *threadData, modelica_metatype _inOldVariable, modelica_metatype _inCref, modelica_metatype _inValue, modelica_metatype _inEnv, modelica_metatype *out_outFound);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_addVarToVarList2,2,0) {(void*) boxptr_SymbolTable_addVarToVarList2,0}};
#define boxvar_SymbolTable_addVarToVarList2 MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_addVarToVarList2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SymbolTable_addVarToVarList(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inValue, modelica_metatype _inEnv, modelica_metatype _inVariables);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_addVarToVarList,2,0) {(void*) boxptr_SymbolTable_addVarToVarList,0}};
#define boxvar_SymbolTable_addVarToVarList MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_addVarToVarList)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SymbolTable_isVarNamed(threadData_t *threadData, modelica_string _id, modelica_metatype _v);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SymbolTable_isVarNamed(threadData_t *threadData, modelica_metatype _id, modelica_metatype _v);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_isVarNamed,2,0) {(void*) boxptr_SymbolTable_isVarNamed,0}};
#define boxvar_SymbolTable_isVarNamed MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_isVarNamed)
PROTECTED_FUNCTION_STATIC void omc_SymbolTable_updateUriMapping(threadData_t *threadData, modelica_metatype _classes)
{
modelica_metatype _tree = NULL;
modelica_string _name = NULL;
modelica_string _fileName = NULL;
modelica_string _dir = NULL;
modelica_boolean _b;
modelica_metatype _namesAndDirs = NULL;
modelica_metatype _infos = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_tree = _OMC_LIT0;
{
modelica_metatype _cl;
for (tmpMeta[0] = _classes; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_cl = MMC_CAR(tmpMeta[0]);
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
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (13 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT9), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
goto tmp2_done;
}
case 1: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_name = tmpMeta[1];
_fileName = tmpMeta[3];
_dir = omc_System_dirname(threadData, _fileName);
_fileName = omc_System_basename(threadData, _fileName);
_b = (((stringEqual(_fileName, _OMC_LIT1)) || (stringEqual(_fileName, _OMC_LIT2))) || (stringEqual(_dir, _OMC_LIT3)));
if((!_b))
{
if(omc_AvlTreeStringString_hasKey(threadData, _tree, _name))
{
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp5;
modelica_metatype __omcQ_24tmpVar0;
int tmp6;
modelica_metatype _cl_loopVar = 0;
modelica_metatype _cl;
_cl_loopVar = _classes;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta[2];
tmp5 = &__omcQ_24tmpVar1;
while(1) {
tmp6 = 1;
if (!listEmpty(_cl_loopVar)) {
_cl = MMC_CAR(_cl_loopVar);
_cl_loopVar = MMC_CDR(_cl_loopVar);
tmp6--;
}
if (tmp6 == 0) {
__omcQ_24tmpVar0 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cl), 8)));
*tmp5 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp5 = &MMC_CDR(*tmp5);
} else if (tmp6 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp5 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar1;
}
_infos = tmpMeta[1];
tmpMeta[1] = mmc_mk_cons(_name, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMultiSourceMessage(threadData, _OMC_LIT8, tmpMeta[1], _infos);
}
_tree = omc_AvlTreeStringString_add(threadData, _tree, _name, _dir, boxvar_AvlTreeStringString_addConflictDefault);
}
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
}
}
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_namesAndDirs = listArray(omc_List_thread(threadData, omc_AvlTreeStringString_listValues(threadData, _tree, tmpMeta[0]), omc_AvlTreeStringString_listKeys(threadData, _tree, tmpMeta[1]), tmpMeta[2]));
omc_System_updateUriMapping(threadData, _namesAndDirs);
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SymbolTable_addVarToEnv(threadData_t *threadData, modelica_metatype _inVariable, modelica_metatype _inEnv)
{
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inVariable;
tmp3_2 = _inEnv;
{
modelica_metatype _env = NULL;
modelica_metatype _empty_env = NULL;
modelica_string _id = NULL;
modelica_metatype _v = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _cref = NULL;
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
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_id = tmpMeta[1];
_v = tmpMeta[2];
_tp = tmpMeta[3];
_env = tmp3_2;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_cref = omc_ComponentReference_makeCrefIdent(threadData, _id, _OMC_LIT10, tmpMeta[1]);
_empty_env = omc_FGraph_empty(threadData);
omc_Lookup_lookupVar(threadData, omc_FCore_emptyCache(threadData), _env, _cref, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
tmpMeta[1] = mmc_mk_box3(5, &DAE_Binding_VALBOUND__desc, _v, _OMC_LIT18);
tmpMeta[2] = mmc_mk_box7(3, &DAE_Var_TYPES__VAR__desc, _id, _OMC_LIT17, _tp, tmpMeta[1], mmc_mk_boolean(0), mmc_mk_none());
tmpMeta[0] = omc_FGraph_updateComp(threadData, _env, tmpMeta[2], _OMC_LIT19, _empty_env);
goto tmp2_done;
}
case 1: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_id = tmpMeta[1];
_v = tmpMeta[2];
_tp = tmpMeta[3];
_env = tmp3_2;
_empty_env = omc_FGraph_empty(threadData);
tmpMeta[1] = mmc_mk_box3(5, &DAE_Binding_VALBOUND__desc, _v, _OMC_LIT18);
tmpMeta[2] = mmc_mk_box7(3, &DAE_Var_TYPES__VAR__desc, _id, _OMC_LIT17, _tp, tmpMeta[1], mmc_mk_boolean(0), mmc_mk_none());
tmpMeta[3] = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _id, _OMC_LIT23, _OMC_LIT26, _OMC_LIT29, _OMC_LIT30, _OMC_LIT31, mmc_mk_none(), _OMC_LIT33);
tmpMeta[0] = omc_FGraph_mkComponentNode(threadData, _env, tmpMeta[2], tmpMeta[3], _OMC_LIT34, _OMC_LIT35, _empty_env);
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
_outEnv = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outEnv;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SymbolTable_addVarsToEnv(threadData_t *threadData, modelica_metatype _inVariableLst, modelica_metatype _inEnv)
{
modelica_metatype _outEnv = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outEnv = omc_List_fold(threadData, _inVariableLst, boxvar_SymbolTable_addVarToEnv, _inEnv);
_return: OMC_LABEL_UNUSED
return _outEnv;
}
DLLExport
modelica_metatype omc_SymbolTable_buildEnv(threadData_t *threadData)
{
modelica_metatype _env = NULL;
modelica_metatype _table = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_table = omc_SymbolTable_get(threadData);
omc_Inst_makeEnvFromProgram(threadData, omc_SymbolTable_getSCode(threadData) ,&_env);
_env = omc_SymbolTable_addVarsToEnv(threadData, listReverse((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_table), 4)))), _env);
_return: OMC_LABEL_UNUSED
return _env;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SymbolTable_addVarToVarList4(threadData_t *threadData, modelica_boolean _inFound, modelica_metatype _inCref, modelica_metatype _inValue, modelica_metatype _inVariables)
{
modelica_metatype _outVariables = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inFound;
tmp3_2 = _inCref;
{
modelica_string _id = NULL;
modelica_metatype _ty = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (1 != tmp3_1) goto tmp2_end;
tmpMeta[0] = _inVariables;
goto tmp2_done;
}
case 1: {
if (0 != tmp3_1) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
_id = tmpMeta[1];
_ty = tmpMeta[2];
tmpMeta[2] = mmc_mk_box4(3, &GlobalScript_Variable_IVAR__desc, _id, _inValue, _ty);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _inVariables);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (0 != tmp3_1) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
if (listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
_id = tmpMeta[1];
tmpMeta[1] = mmc_mk_cons(_id, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMessage(threadData, _OMC_LIT39, tmpMeta[1]);
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
_outVariables = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outVariables;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SymbolTable_addVarToVarList4(threadData_t *threadData, modelica_metatype _inFound, modelica_metatype _inCref, modelica_metatype _inValue, modelica_metatype _inVariables)
{
modelica_integer tmp1;
modelica_metatype _outVariables = NULL;
tmp1 = mmc_unbox_integer(_inFound);
_outVariables = omc_SymbolTable_addVarToVarList4(threadData, tmp1, _inCref, _inValue, _inVariables);
return _outVariables;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SymbolTable_addVarToVarList3(threadData_t *threadData, modelica_boolean _inFound, modelica_metatype _inOldVariable, modelica_metatype _inCref, modelica_metatype _inValue, modelica_metatype _inEnv)
{
modelica_metatype _outVariable = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean tmp3_1;modelica_metatype tmp3_2;modelica_metatype tmp3_3;
tmp3_1 = _inFound;
tmp3_2 = _inOldVariable;
tmp3_3 = _inCref;
{
modelica_string _id = NULL;
modelica_metatype _val = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _subs = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (0 != tmp3_1) goto tmp2_end;
tmpMeta[0] = _inOldVariable;
goto tmp2_done;
}
case 1: {
if (1 != tmp3_1) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,1,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
_id = tmpMeta[1];
_ty = tmpMeta[2];
tmpMeta[1] = mmc_mk_box4(3, &GlobalScript_Variable_IVAR__desc, _id, _inValue, _ty);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (1 != tmp3_1) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,1,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_subs = tmpMeta[1];
_id = tmpMeta[2];
_val = tmpMeta[3];
_ty = tmpMeta[4];
omc_CevalFunction_assignVector(threadData, _inValue, _val, _subs, omc_FCore_emptyCache(threadData), _inEnv ,&_val);
tmpMeta[1] = mmc_mk_box4(3, &GlobalScript_Variable_IVAR__desc, _id, _val, _ty);
tmpMeta[0] = tmpMeta[1];
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
_outVariable = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outVariable;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SymbolTable_addVarToVarList3(threadData_t *threadData, modelica_metatype _inFound, modelica_metatype _inOldVariable, modelica_metatype _inCref, modelica_metatype _inValue, modelica_metatype _inEnv)
{
modelica_integer tmp1;
modelica_metatype _outVariable = NULL;
tmp1 = mmc_unbox_integer(_inFound);
_outVariable = omc_SymbolTable_addVarToVarList3(threadData, tmp1, _inOldVariable, _inCref, _inValue, _inEnv);
return _outVariable;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SymbolTable_addVarToVarList2(threadData_t *threadData, modelica_metatype _inOldVariable, modelica_metatype _inCref, modelica_metatype _inValue, modelica_metatype _inEnv, modelica_boolean *out_outFound)
{
modelica_metatype _outVariable = NULL;
modelica_boolean _outFound;
modelica_string _id1 = NULL;
modelica_string _id2 = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inOldVariable;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_id1 = tmpMeta[1];
tmpMeta[0] = _inCref;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,3) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_id2 = tmpMeta[1];
_outFound = (stringEqual(_id1, _id2));
_outVariable = omc_SymbolTable_addVarToVarList3(threadData, _outFound, _inOldVariable, _inCref, _inValue, _inEnv);
_return: OMC_LABEL_UNUSED
if (out_outFound) { *out_outFound = _outFound; }
return _outVariable;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SymbolTable_addVarToVarList2(threadData_t *threadData, modelica_metatype _inOldVariable, modelica_metatype _inCref, modelica_metatype _inValue, modelica_metatype _inEnv, modelica_metatype *out_outFound)
{
modelica_boolean _outFound;
modelica_metatype _outVariable = NULL;
_outVariable = omc_SymbolTable_addVarToVarList2(threadData, _inOldVariable, _inCref, _inValue, _inEnv, &_outFound);
if (out_outFound) { *out_outFound = mmc_mk_icon(_outFound); }
return _outVariable;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SymbolTable_addVarToVarList(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inValue, modelica_metatype _inEnv, modelica_metatype _inVariables)
{
modelica_metatype _outVariables = NULL;
modelica_boolean _found;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outVariables = omc_List_findMap3(threadData, _inVariables, boxvar_SymbolTable_addVarToVarList2, _inCref, _inValue, _inEnv ,&_found);
_outVariables = omc_SymbolTable_addVarToVarList4(threadData, _found, _inCref, _inValue, _outVariables);
_return: OMC_LABEL_UNUSED
return _outVariables;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SymbolTable_isVarNamed(threadData_t *threadData, modelica_string _id, modelica_metatype _v)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = (stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))), _id));
_return: OMC_LABEL_UNUSED
return _b;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SymbolTable_isVarNamed(threadData_t *threadData, modelica_metatype _id, modelica_metatype _v)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_SymbolTable_isVarNamed(threadData, _id, _v);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
void omc_SymbolTable_deleteVarFirstEntry(threadData_t *threadData, modelica_string _inIdent)
{
modelica_metatype _table = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_table = omc_SymbolTable_get(threadData);
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_table), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = omc_List_deleteMemberOnTrue(threadData, _inIdent, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_table), 4))), boxvar_SymbolTable_isVarNamed, NULL);
_table = tmpMeta[0];
omc_SymbolTable_update(threadData, _table);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_SymbolTable_appendVar(threadData_t *threadData, modelica_string _inIdent, modelica_metatype _inValue, modelica_metatype _inType)
{
modelica_metatype _table = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_table = omc_SymbolTable_get(threadData);
tmpMeta[2] = mmc_mk_box4(3, &GlobalScript_Variable_IVAR__desc, _inIdent, _inValue, _inType);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_table), 4))));
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_table), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = tmpMeta[1];
_table = tmpMeta[0];
omc_SymbolTable_update(threadData, _table);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_SymbolTable_addVar(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inValue, modelica_metatype _inEnv)
{
modelica_metatype _vars = NULL;
modelica_metatype _table = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_table = omc_SymbolTable_get(threadData);
_vars = omc_SymbolTable_addVarToVarList(threadData, _inCref, _inValue, _inEnv, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_table), 4))));
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_table), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = omc_SymbolTable_addVarToVarList(threadData, _inCref, _inValue, _inEnv, _vars);
_table = tmpMeta[0];
omc_SymbolTable_update(threadData, _table);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_SymbolTable_addVars(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inValues, modelica_metatype _inEnv)
{
modelica_metatype _crefs = NULL;
modelica_metatype _vals = NULL;
modelica_metatype _v = NULL;
modelica_metatype _cr = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_crefs = _inCref;
_vals = _inValues;
while(1)
{
if(!(!listEmpty(_crefs))) break;
tmpMeta[0] = _crefs;
if (listEmpty(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
_cr = tmpMeta[1];
_crefs = tmpMeta[2];
tmpMeta[0] = _vals;
if (listEmpty(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
_v = tmpMeta[1];
_vals = tmpMeta[2];
omc_SymbolTable_addVar(threadData, _cr, _v, _inEnv);
}
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_SymbolTable_setVars(threadData_t *threadData, modelica_metatype _vars)
{
modelica_metatype _table = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_table = omc_SymbolTable_get(threadData);
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_table), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = _vars;
_table = tmpMeta[0];
omc_SymbolTable_update(threadData, _table);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_metatype omc_SymbolTable_getVars(threadData_t *threadData)
{
modelica_metatype _vars = NULL;
modelica_metatype _table = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_table = omc_SymbolTable_get(threadData);
_vars = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_table), 4)));
_return: OMC_LABEL_UNUSED
return _vars;
}
DLLExport
void omc_SymbolTable_clearProgram(threadData_t *threadData)
{
modelica_metatype _table = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_table = omc_SymbolTable_get(threadData);
omc_SymbolTable_reset(threadData);
omc_SymbolTable_setVars(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_table), 4))));
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_SymbolTable_clearSCode(threadData_t *threadData)
{
modelica_metatype _table = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_table = omc_SymbolTable_get(threadData);
if(isSome((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_table), 3)))))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_table), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = mmc_mk_none();
_table = tmpMeta[0];
omc_SymbolTable_update(threadData, _table);
}
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_SymbolTable_setSCode(threadData_t *threadData, modelica_metatype _ast)
{
modelica_metatype _table = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_table = omc_SymbolTable_get(threadData);
if(referenceEq((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_table), 3))), _ast))
{
goto _return;
}
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_table), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = _ast;
_table = tmpMeta[0];
omc_SymbolTable_update(threadData, _table);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_metatype omc_SymbolTable_getSCode(threadData_t *threadData)
{
modelica_metatype _ast = NULL;
modelica_metatype _table = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_table = omc_SymbolTable_get(threadData);
if(isNone((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_table), 3)))))
{
_ast = omc_AbsynToSCode_translateAbsyn2SCode(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_table), 2))));
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_table), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = mmc_mk_some(_ast);
_table = tmpMeta[0];
omc_SymbolTable_update(threadData, _table);
}
else
{
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_table), 3)));
if (optionNone(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
_ast = tmpMeta[1];
}
_return: OMC_LABEL_UNUSED
return _ast;
}
DLLExport
void omc_SymbolTable_setAbsyn(threadData_t *threadData, modelica_metatype _ast)
{
modelica_metatype _table = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_table = omc_SymbolTable_get(threadData);
if(referenceEq((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_table), 2))), _ast))
{
goto _return;
}
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_table), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _ast;
_table = tmpMeta[0];
omc_SymbolTable_updateUriMapping(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ast), 2))));
if(isSome((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_table), 3)))))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_table), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = mmc_mk_none();
_table = tmpMeta[0];
}
omc_SymbolTable_update(threadData, _table);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_metatype omc_SymbolTable_getAbsyn(threadData_t *threadData)
{
modelica_metatype _ast = NULL;
modelica_metatype _table = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_table = omc_SymbolTable_get(threadData);
_ast = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_table), 2)));
_return: OMC_LABEL_UNUSED
return _ast;
}
DLLExport
modelica_metatype omc_SymbolTable_get(threadData_t *threadData)
{
modelica_metatype _table = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_table = getGlobalRoot(((modelica_integer) 3));
_return: OMC_LABEL_UNUSED
return _table;
}
DLLExport
void omc_SymbolTable_update(threadData_t *threadData, modelica_metatype _table)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
setGlobalRoot(((modelica_integer) 3), _table);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_SymbolTable_reset(threadData_t *threadData)
{
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
setGlobalRoot(((modelica_integer) 3), _OMC_LIT42);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
omc_SymbolTable_updateUriMapping(threadData, tmpMeta[0]);
_return: OMC_LABEL_UNUSED
return;
}
