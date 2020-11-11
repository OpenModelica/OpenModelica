#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/SCodeInstUtil.c"
#endif
#include "omc_simulation_settings.h"
#include "SCodeInstUtil.h"
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT0,1,4) {&SCode_Encapsulated_NOT__ENCAPSULATED__desc,}};
#define _OMC_LIT0 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,1,4) {&SCode_Partial_NOT__PARTIAL__desc,}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT2,1,13) {&SCode_Restriction_R__ENUMERATION__desc,}};
#define _OMC_LIT2 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "- AbsynToSCode.makeElementsIntoSubMods ignoring class-extends redeclare-as-element: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,84,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,10,3) {&SCodeDump_SCodeDumpOptions_OPTIONS__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,1,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "- AbsynToSCode.makeElementsIntoSubMods ignoring redeclare-as-element redeclaration: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,84,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,1,4) {&SCode_Final_NOT__FINAL__desc,}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT8,1,4) {&SCode_Each_NOT__EACH__desc,}};
#define _OMC_LIT8 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT8)
#include "util/modelica.h"
#include "SCodeInstUtil_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeInstUtil_makeEnumComponents(threadData_t *threadData, modelica_metatype _inEnumLst, modelica_metatype _info);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeInstUtil_makeEnumComponents,2,0) {(void*) boxptr_SCodeInstUtil_makeEnumComponents,0}};
#define boxvar_SCodeInstUtil_makeEnumComponents MMC_REFSTRUCTLIT(boxvar_lit_SCodeInstUtil_makeEnumComponents)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeInstUtil_makeEnumParts(threadData_t *threadData, modelica_metatype _inEnumLst, modelica_metatype _info);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeInstUtil_makeEnumParts,2,0) {(void*) boxptr_SCodeInstUtil_makeEnumParts,0}};
#define boxvar_SCodeInstUtil_makeEnumParts MMC_REFSTRUCTLIT(boxvar_lit_SCodeInstUtil_makeEnumParts)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeInstUtil_expandEnumerationSubMod(threadData_t *threadData, modelica_metatype _inSubMod, modelica_boolean _inChanged, modelica_boolean *out_outChanged);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeInstUtil_expandEnumerationSubMod(threadData_t *threadData, modelica_metatype _inSubMod, modelica_metatype _inChanged, modelica_metatype *out_outChanged);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeInstUtil_expandEnumerationSubMod,2,0) {(void*) boxptr_SCodeInstUtil_expandEnumerationSubMod,0}};
#define boxvar_SCodeInstUtil_expandEnumerationSubMod MMC_REFSTRUCTLIT(boxvar_lit_SCodeInstUtil_expandEnumerationSubMod)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeInstUtil_removeSelfReferenceFromSubMod(threadData_t *threadData, modelica_metatype _inSl, modelica_metatype _inCref);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeInstUtil_removeSelfReferenceFromSubMod,2,0) {(void*) boxptr_SCodeInstUtil_removeSelfReferenceFromSubMod,0}};
#define boxvar_SCodeInstUtil_removeSelfReferenceFromSubMod MMC_REFSTRUCTLIT(boxvar_lit_SCodeInstUtil_removeSelfReferenceFromSubMod)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeInstUtil_removeReferenceInBinding(threadData_t *threadData, modelica_metatype _inBinding, modelica_metatype _inCref);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeInstUtil_removeReferenceInBinding,2,0) {(void*) boxptr_SCodeInstUtil_removeReferenceInBinding,0}};
#define boxvar_SCodeInstUtil_removeReferenceInBinding MMC_REFSTRUCTLIT(boxvar_lit_SCodeInstUtil_removeReferenceInBinding)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeInstUtil_makeElementsIntoSubMods(threadData_t *threadData, modelica_metatype _inFinal, modelica_metatype _inEach, modelica_metatype _inElements);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeInstUtil_makeElementsIntoSubMods,2,0) {(void*) boxptr_SCodeInstUtil_makeElementsIntoSubMods,0}};
#define boxvar_SCodeInstUtil_makeElementsIntoSubMods MMC_REFSTRUCTLIT(boxvar_lit_SCodeInstUtil_makeElementsIntoSubMods)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeInstUtil_removeNonConstantBindingsKeepRedeclaresFromSubMod(threadData_t *threadData, modelica_metatype _inSl, modelica_boolean _onlyRedeclares);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeInstUtil_removeNonConstantBindingsKeepRedeclaresFromSubMod(threadData_t *threadData, modelica_metatype _inSl, modelica_metatype _onlyRedeclares);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeInstUtil_removeNonConstantBindingsKeepRedeclaresFromSubMod,2,0) {(void*) boxptr_SCodeInstUtil_removeNonConstantBindingsKeepRedeclaresFromSubMod,0}};
#define boxvar_SCodeInstUtil_removeNonConstantBindingsKeepRedeclaresFromSubMod MMC_REFSTRUCTLIT(boxvar_lit_SCodeInstUtil_removeNonConstantBindingsKeepRedeclaresFromSubMod)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeInstUtil_constantBindingOrNone(threadData_t *threadData, modelica_metatype _inBinding);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeInstUtil_constantBindingOrNone,2,0) {(void*) boxptr_SCodeInstUtil_constantBindingOrNone,0}};
#define boxvar_SCodeInstUtil_constantBindingOrNone MMC_REFSTRUCTLIT(boxvar_lit_SCodeInstUtil_constantBindingOrNone)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeInstUtil_makeEnumComponents(threadData_t *threadData, modelica_metatype _inEnumLst, modelica_metatype _info)
{
modelica_metatype _outSCodeElementLst = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp1;
modelica_metatype __omcQ_24tmpVar0;
int tmp2;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _inEnumLst;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta[1];
tmp1 = &__omcQ_24tmpVar1;
while(1) {
tmp2 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp2--;
}
if (tmp2 == 0) {
__omcQ_24tmpVar0 = omc_SCodeUtil_makeEnumType(threadData, _e, _info);
*tmp1 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp1 = &MMC_CDR(*tmp1);
} else if (tmp2 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp1 = mmc_mk_nil();
tmpMeta[0] = __omcQ_24tmpVar1;
}
_outSCodeElementLst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outSCodeElementLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeInstUtil_makeEnumParts(threadData_t *threadData, modelica_metatype _inEnumLst, modelica_metatype _info)
{
modelica_metatype _classDef = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[5] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[6] = mmc_mk_box9(3, &SCode_ClassDef_PARTS__desc, omc_SCodeInstUtil_makeEnumComponents(threadData, _inEnumLst, _info), tmpMeta[0], tmpMeta[1], tmpMeta[2], tmpMeta[3], tmpMeta[4], tmpMeta[5], mmc_mk_none());
_classDef = tmpMeta[6];
_return: OMC_LABEL_UNUSED
return _classDef;
}
DLLExport
modelica_metatype omc_SCodeInstUtil_expandEnumeration(threadData_t *threadData, modelica_string _n, modelica_metatype _l, modelica_metatype _prefixes, modelica_metatype _cmt, modelica_metatype _info)
{
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _n, _prefixes, _OMC_LIT0, _OMC_LIT1, _OMC_LIT2, omc_SCodeInstUtil_makeEnumParts(threadData, _l, _info), _cmt, _info);
_outClass = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outClass;
}
DLLExport
modelica_metatype omc_SCodeInstUtil_expandEnumerationClass(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_metatype _outElement = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inElement;
{
modelica_string _n = NULL;
modelica_metatype _l = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _info = NULL;
modelica_metatype _prefixes = NULL;
modelica_metatype _m = NULL;
modelica_metatype _m1 = NULL;
modelica_metatype _p = NULL;
modelica_metatype _v = NULL;
modelica_metatype _ann = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],7,0) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],3,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
_n = tmpMeta[1];
_prefixes = tmpMeta[2];
_l = tmpMeta[5];
_cmt = tmpMeta[6];
_info = tmpMeta[7];
tmpMeta[0] = omc_SCodeInstUtil_expandEnumeration(threadData, _n, _l, _prefixes, _cmt, _info);
goto tmp2_done;
}
case 1: {
modelica_boolean tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_p = tmpMeta[1];
_v = tmpMeta[2];
_m = tmpMeta[3];
_ann = tmpMeta[4];
_info = tmpMeta[5];
_m1 = omc_SCodeInstUtil_expandEnumerationMod(threadData, _m);
tmp5 = (modelica_boolean)referenceEq(_m, _m1);
if(tmp5)
{
tmpMeta[2] = _inElement;
}
else
{
tmpMeta[1] = mmc_mk_box6(4, &SCode_Element_EXTENDS__desc, _p, _v, _m1, _ann, _info);
tmpMeta[2] = tmpMeta[1];
}
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 2: {
tmpMeta[0] = _inElement;
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
_outElement = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outElement;
}
DLLExport
modelica_metatype omc_SCodeInstUtil_expandEnumerationMod(threadData_t *threadData, modelica_metatype _inMod)
{
modelica_metatype _outMod = NULL;
modelica_metatype _f = NULL;
modelica_metatype _e = NULL;
modelica_metatype _el = NULL;
modelica_metatype _el1 = NULL;
modelica_metatype _submod = NULL;
modelica_metatype _binding = NULL;
modelica_metatype _info = NULL;
modelica_boolean _changed;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inMod;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 4: {
modelica_boolean tmp4;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_f = tmpMeta[1];
_e = tmpMeta[2];
_el = tmpMeta[3];
_el1 = omc_SCodeInstUtil_expandEnumerationClass(threadData, _el);
tmp4 = (modelica_boolean)referenceEq(_el, _el1);
if(tmp4)
{
tmpMeta[2] = _inMod;
}
else
{
tmpMeta[1] = mmc_mk_box4(4, &SCode_Mod_REDECL__desc, _f, _e, _el1);
tmpMeta[2] = tmpMeta[1];
}
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 3: {
modelica_integer tmp5;
modelica_boolean tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_f = tmpMeta[1];
_e = tmpMeta[2];
_submod = tmpMeta[3];
_binding = tmpMeta[4];
_info = tmpMeta[5];
tmpMeta[2] = omc_List_mapFold(threadData, _submod, boxvar_SCodeInstUtil_expandEnumerationSubMod, mmc_mk_boolean(0), &tmpMeta[1]);
_submod = tmpMeta[2];
tmp5 = mmc_unbox_integer(tmpMeta[1]);
_changed = tmp5;
tmp6 = (modelica_boolean)_changed;
if(tmp6)
{
tmpMeta[1] = mmc_mk_box6(3, &SCode_Mod_MOD__desc, _f, _e, _submod, _binding, _info);
tmpMeta[2] = tmpMeta[1];
}
else
{
tmpMeta[2] = _inMod;
}
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
tmpMeta[0] = _inMod;
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
_outMod = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeInstUtil_expandEnumerationSubMod(threadData_t *threadData, modelica_metatype _inSubMod, modelica_boolean _inChanged, modelica_boolean *out_outChanged)
{
modelica_metatype _outSubMod = NULL;
modelica_boolean _outChanged;
modelica_integer tmp6;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inSubMod;
{
modelica_metatype _mod = NULL;
modelica_metatype _mod1 = NULL;
modelica_string _ident = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_ident = tmpMeta[1];
_mod = tmpMeta[2];
_mod1 = omc_SCodeInstUtil_expandEnumerationMod(threadData, _mod);
tmp5 = (modelica_boolean)referenceEq(_mod, _mod1);
if(tmp5)
{
tmpMeta[1] = mmc_mk_box2(0, _inSubMod, mmc_mk_boolean(_inChanged));
tmpMeta[4] = tmpMeta[1];
}
else
{
tmpMeta[2] = mmc_mk_box3(3, &SCode_SubMod_NAMEMOD__desc, _ident, _mod1);
tmpMeta[3] = mmc_mk_box2(0, tmpMeta[2], mmc_mk_boolean(1));
tmpMeta[4] = tmpMeta[3];
}
tmpMeta[0] = tmpMeta[4];
goto tmp2_done;
}
case 1: {
tmpMeta[1] = mmc_mk_box2(0, _inSubMod, mmc_mk_boolean(_inChanged));
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
tmpMeta[2] = tmpMeta[0];
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp6 = mmc_unbox_integer(tmpMeta[4]);
_outSubMod = tmpMeta[3];
_outChanged = tmp6;
_return: OMC_LABEL_UNUSED
if (out_outChanged) { *out_outChanged = _outChanged; }
return _outSubMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeInstUtil_expandEnumerationSubMod(threadData_t *threadData, modelica_metatype _inSubMod, modelica_metatype _inChanged, modelica_metatype *out_outChanged)
{
modelica_integer tmp1;
modelica_boolean _outChanged;
modelica_metatype _outSubMod = NULL;
tmp1 = mmc_unbox_integer(_inChanged);
_outSubMod = omc_SCodeInstUtil_expandEnumerationSubMod(threadData, _inSubMod, tmp1, &_outChanged);
if (out_outChanged) { *out_outChanged = mmc_mk_icon(_outChanged); }
return _outSubMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeInstUtil_removeSelfReferenceFromSubMod(threadData_t *threadData, modelica_metatype _inSl, modelica_metatype _inCref)
{
modelica_metatype _outSl = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inSl;
{
modelica_string _n = NULL;
modelica_metatype _sl = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _m = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_n = tmpMeta[3];
_m = tmpMeta[4];
_rest = tmpMeta[2];
_m = omc_SCodeInstUtil_removeSelfReferenceFromMod(threadData, _m, _inCref);
_sl = omc_SCodeInstUtil_removeSelfReferenceFromSubMod(threadData, _rest, _inCref);
tmpMeta[2] = mmc_mk_box3(3, &SCode_SubMod_NAMEMOD__desc, _n, _m);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _sl);
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
_outSl = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outSl;
}
DLLExport
modelica_metatype omc_SCodeInstUtil_removeSelfReferenceFromMod(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _inCref)
{
modelica_metatype _outMod = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inMod;
{
modelica_metatype _sl = NULL;
modelica_metatype _fp = NULL;
modelica_metatype _ep = NULL;
modelica_metatype _i = NULL;
modelica_metatype _binding = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_fp = tmpMeta[1];
_ep = tmpMeta[2];
_sl = tmpMeta[3];
_binding = tmpMeta[4];
_i = tmpMeta[5];
_binding = omc_SCodeInstUtil_removeReferenceInBinding(threadData, _binding, _inCref);
_sl = omc_SCodeInstUtil_removeSelfReferenceFromSubMod(threadData, _sl, _inCref);
tmpMeta[1] = mmc_mk_box6(3, &SCode_Mod_MOD__desc, _fp, _ep, _sl, _binding, _i);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
tmpMeta[0] = _inMod;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
tmpMeta[0] = _inMod;
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
_outMod = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeInstUtil_removeReferenceInBinding(threadData_t *threadData, modelica_metatype _inBinding, modelica_metatype _inCref)
{
modelica_metatype _outBinding = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inBinding;
{
modelica_metatype _e = NULL;
modelica_metatype _crlst1 = NULL;
modelica_metatype _crlst2 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
_e = tmpMeta[1];
_crlst1 = omc_AbsynUtil_getCrefFromExp(threadData, _e, 1, 1);
_crlst2 = omc_AbsynUtil_removeCrefFromCrefs(threadData, _crlst1, _inCref);
tmpMeta[0] = ((listLength(_crlst1) == listLength(_crlst2))?_inBinding:mmc_mk_none());
goto tmp2_done;
}
case 1: {
tmpMeta[0] = mmc_mk_none();
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
_outBinding = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outBinding;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeInstUtil_makeElementsIntoSubMods(threadData_t *threadData, modelica_metatype _inFinal, modelica_metatype _inEach, modelica_metatype _inElements)
{
modelica_metatype _outSubMods = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;modelica_metatype tmp3_3;
tmp3_1 = _inFinal;
tmp3_2 = _inEach;
tmp3_3 = _inElements;
{
modelica_metatype _el = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _f = NULL;
modelica_metatype _e = NULL;
modelica_string _n = NULL;
modelica_metatype _newSubMods = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 5; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_3)) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_3)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_3);
tmpMeta[2] = MMC_CDR(tmp3_3);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,8) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],1,2) == 0) goto tmp2_end;
_el = tmpMeta[1];
_rest = tmpMeta[2];
_f = tmp3_1;
_e = tmp3_2;
tmpMeta[1] = stringAppend(_OMC_LIT3,omc_SCodeDump_unparseElementStr(threadData, _el, _OMC_LIT4));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT5);
fputs(MMC_STRINGDATA(tmpMeta[2]),stdout);
_inFinal = _f;
_inEach = _e;
_inElements = _rest;
goto _tailrecursive;
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_3)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_3);
tmpMeta[2] = MMC_CDR(tmp3_3);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,8) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_el = tmpMeta[1];
_n = tmpMeta[3];
_rest = tmpMeta[2];
_f = tmp3_1;
_e = tmp3_2;
_newSubMods = omc_SCodeInstUtil_makeElementsIntoSubMods(threadData, _f, _e, _rest);
tmpMeta[2] = mmc_mk_box4(4, &SCode_Mod_REDECL__desc, _f, _e, _el);
tmpMeta[3] = mmc_mk_box3(3, &SCode_SubMod_NAMEMOD__desc, _n, tmpMeta[2]);
tmpMeta[1] = mmc_mk_cons(tmpMeta[3], _newSubMods);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 3: {
if (listEmpty(tmp3_3)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_3);
tmpMeta[2] = MMC_CDR(tmp3_3);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,8) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_el = tmpMeta[1];
_n = tmpMeta[3];
_rest = tmpMeta[2];
_f = tmp3_1;
_e = tmp3_2;
_newSubMods = omc_SCodeInstUtil_makeElementsIntoSubMods(threadData, _f, _e, _rest);
tmpMeta[2] = mmc_mk_box4(4, &SCode_Mod_REDECL__desc, _f, _e, _el);
tmpMeta[3] = mmc_mk_box3(3, &SCode_SubMod_NAMEMOD__desc, _n, tmpMeta[2]);
tmpMeta[1] = mmc_mk_cons(tmpMeta[3], _newSubMods);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
if (listEmpty(tmp3_3)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_3);
tmpMeta[2] = MMC_CDR(tmp3_3);
_el = tmpMeta[1];
_rest = tmpMeta[2];
_f = tmp3_1;
_e = tmp3_2;
tmpMeta[1] = stringAppend(_OMC_LIT6,omc_SCodeDump_unparseElementStr(threadData, _el, _OMC_LIT4));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT5);
fputs(MMC_STRINGDATA(tmpMeta[2]),stdout);
_inFinal = _f;
_inEach = _e;
_inElements = _rest;
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
_outSubMods = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outSubMods;
}
DLLExport
modelica_metatype omc_SCodeInstUtil_addRedeclareAsElementsToExtends(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _redeclareElements)
{
modelica_metatype _outExtendsElements = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inElements;
tmp3_2 = _redeclareElements;
{
modelica_metatype _el = NULL;
modelica_metatype _redecls = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _out = NULL;
modelica_metatype _baseClassPath = NULL;
modelica_metatype _visibility = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _ann = NULL;
modelica_metatype _info = NULL;
modelica_metatype _redeclareMod = NULL;
modelica_metatype _submods = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[0] = _inElements;
goto tmp2_done;
}
case 1: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,5) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
_baseClassPath = tmpMeta[3];
_visibility = tmpMeta[4];
_mod = tmpMeta[5];
_ann = tmpMeta[6];
_info = tmpMeta[7];
_rest = tmpMeta[2];
_redecls = tmp3_2;
_submods = omc_SCodeInstUtil_makeElementsIntoSubMods(threadData, _OMC_LIT7, _OMC_LIT8, _redecls);
tmpMeta[1] = mmc_mk_box6(3, &SCode_Mod_MOD__desc, _OMC_LIT7, _OMC_LIT8, _submods, mmc_mk_none(), _info);
_redeclareMod = tmpMeta[1];
_mod = omc_SCodeUtil_mergeSCodeMods(threadData, _redeclareMod, _mod);
_out = omc_SCodeInstUtil_addRedeclareAsElementsToExtends(threadData, _rest, _redecls);
tmpMeta[2] = mmc_mk_box6(4, &SCode_Element_EXTENDS__desc, _baseClassPath, _visibility, _mod, _ann, _info);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _out);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 3: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_el = tmpMeta[1];
_rest = tmpMeta[2];
_redecls = tmp3_2;
_out = omc_SCodeInstUtil_addRedeclareAsElementsToExtends(threadData, _rest, _redecls);
tmpMeta[1] = mmc_mk_cons(_el, _out);
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
_outExtendsElements = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExtendsElements;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeInstUtil_removeNonConstantBindingsKeepRedeclaresFromSubMod(threadData_t *threadData, modelica_metatype _inSl, modelica_boolean _onlyRedeclares)
{
modelica_metatype _outSl = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inSl;
{
modelica_string _n = NULL;
modelica_metatype _sl = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _m = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_n = tmpMeta[3];
_m = tmpMeta[4];
_rest = tmpMeta[2];
_m = omc_SCodeInstUtil_removeNonConstantBindingsKeepRedeclares(threadData, _m, _onlyRedeclares);
_sl = omc_SCodeInstUtil_removeNonConstantBindingsKeepRedeclaresFromSubMod(threadData, _rest, _onlyRedeclares);
tmpMeta[2] = mmc_mk_box3(3, &SCode_SubMod_NAMEMOD__desc, _n, _m);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _sl);
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
_outSl = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outSl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeInstUtil_removeNonConstantBindingsKeepRedeclaresFromSubMod(threadData_t *threadData, modelica_metatype _inSl, modelica_metatype _onlyRedeclares)
{
modelica_integer tmp1;
modelica_metatype _outSl = NULL;
tmp1 = mmc_unbox_integer(_onlyRedeclares);
_outSl = omc_SCodeInstUtil_removeNonConstantBindingsKeepRedeclaresFromSubMod(threadData, _inSl, tmp1);
return _outSl;
}
DLLExport
modelica_metatype omc_SCodeInstUtil_removeNonConstantBindingsKeepRedeclares(threadData_t *threadData, modelica_metatype _inMod, modelica_boolean _onlyRedeclares)
{
modelica_metatype _outMod = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inMod;
{
modelica_metatype _sl = NULL;
modelica_metatype _fp = NULL;
modelica_metatype _ep = NULL;
modelica_metatype _i = NULL;
modelica_metatype _binding = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_fp = tmpMeta[1];
_ep = tmpMeta[2];
_sl = tmpMeta[3];
_binding = tmpMeta[4];
_i = tmpMeta[5];
_binding = (_onlyRedeclares?mmc_mk_none():omc_SCodeInstUtil_constantBindingOrNone(threadData, _binding));
_sl = omc_SCodeInstUtil_removeNonConstantBindingsKeepRedeclaresFromSubMod(threadData, _sl, _onlyRedeclares);
tmpMeta[1] = mmc_mk_box6(3, &SCode_Mod_MOD__desc, _fp, _ep, _sl, _binding, _i);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
tmpMeta[0] = _inMod;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
tmpMeta[0] = _inMod;
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
_outMod = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outMod;
}
modelica_metatype boxptr_SCodeInstUtil_removeNonConstantBindingsKeepRedeclares(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _onlyRedeclares)
{
modelica_integer tmp1;
modelica_metatype _outMod = NULL;
tmp1 = mmc_unbox_integer(_onlyRedeclares);
_outMod = omc_SCodeInstUtil_removeNonConstantBindingsKeepRedeclares(threadData, _inMod, tmp1);
return _outMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeInstUtil_constantBindingOrNone(threadData_t *threadData, modelica_metatype _inBinding)
{
modelica_metatype _outBinding = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inBinding;
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
tmpMeta[0] = (listEmpty(omc_AbsynUtil_getCrefFromExp(threadData, _e, 1, 1))?_inBinding:mmc_mk_none());
goto tmp2_done;
}
case 1: {
tmpMeta[0] = mmc_mk_none();
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
_outBinding = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outBinding;
}
