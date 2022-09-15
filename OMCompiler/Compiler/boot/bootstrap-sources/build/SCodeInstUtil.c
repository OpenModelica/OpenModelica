#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "SCodeInstUtil.c"
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
_e_loopVar = _inEnumLst;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar1;
while(1) {
tmp4 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp4--;
}
if (tmp4 == 0) {
__omcQ_24tmpVar0 = omc_SCodeUtil_makeEnumType(threadData, _e, _info);
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
_outSCodeElementLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outSCodeElementLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeInstUtil_makeEnumParts(threadData_t *threadData, modelica_metatype _inEnumLst, modelica_metatype _info)
{
modelica_metatype _classDef = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta4 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta5 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta7 = mmc_mk_box9(3, &SCode_ClassDef_PARTS__desc, omc_SCodeInstUtil_makeEnumComponents(threadData, _inEnumLst, _info), tmpMeta1, tmpMeta2, tmpMeta3, tmpMeta4, tmpMeta5, tmpMeta6, mmc_mk_none());
_classDef = tmpMeta7;
_return: OMC_LABEL_UNUSED
return _classDef;
}
DLLExport
modelica_metatype omc_SCodeInstUtil_expandEnumeration(threadData_t *threadData, modelica_string _n, modelica_metatype _l, modelica_metatype _prefixes, modelica_metatype _cmt, modelica_metatype _info)
{
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _n, _prefixes, _OMC_LIT0, _OMC_LIT1, _OMC_LIT2, omc_SCodeInstUtil_makeEnumParts(threadData, _l, _info), _cmt, _info);
_outClass = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outClass;
}
DLLExport
modelica_metatype omc_SCodeInstUtil_expandEnumerationClass(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_metatype _outElement = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
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
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,7,0) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,3,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 9));
_n = tmpMeta6;
_prefixes = tmpMeta7;
_l = tmpMeta10;
_cmt = tmpMeta11;
_info = tmpMeta12;
tmpMeta1 = omc_SCodeInstUtil_expandEnumeration(threadData, _n, _l, _prefixes, _cmt, _info);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_boolean tmp19;
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_p = tmpMeta13;
_v = tmpMeta14;
_m = tmpMeta15;
_ann = tmpMeta16;
_info = tmpMeta17;
_m1 = omc_SCodeInstUtil_expandEnumerationMod(threadData, _m);
tmp19 = (modelica_boolean)referenceEq(_m, _m1);
if(tmp19)
{
tmpMeta20 = _inElement;
}
else
{
tmpMeta18 = mmc_mk_box6(4, &SCode_Element_EXTENDS__desc, _p, _v, _m1, _ann, _info);
tmpMeta20 = tmpMeta18;
}
tmpMeta1 = tmpMeta20;
goto tmp3_done;
}
case 2: {
tmpMeta1 = _inElement;
goto tmp3_done;
}
}
goto tmp3_end;
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inMod;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_boolean tmp9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_f = tmpMeta5;
_e = tmpMeta6;
_el = tmpMeta7;
_el1 = omc_SCodeInstUtil_expandEnumerationClass(threadData, _el);
tmp9 = (modelica_boolean)referenceEq(_el, _el1);
if(tmp9)
{
tmpMeta10 = _inMod;
}
else
{
tmpMeta8 = mmc_mk_box4(4, &SCode_Mod_REDECL__desc, _f, _e, _el1);
tmpMeta10 = tmpMeta8;
}
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_integer tmp17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_boolean tmp20;
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_f = tmpMeta11;
_e = tmpMeta12;
_submod = tmpMeta13;
_binding = tmpMeta14;
_info = tmpMeta15;
tmpMeta18 = omc_List_mapFold(threadData, _submod, boxvar_SCodeInstUtil_expandEnumerationSubMod, mmc_mk_boolean(0), &tmpMeta16);
_submod = tmpMeta18;
tmp17 = mmc_unbox_integer(tmpMeta16);
_changed = tmp17;
tmp20 = (modelica_boolean)_changed;
if(tmp20)
{
tmpMeta19 = mmc_mk_box6(3, &SCode_Mod_MOD__desc, _f, _e, _submod, _binding, _info);
tmpMeta21 = tmpMeta19;
}
else
{
tmpMeta21 = _inMod;
}
tmpMeta1 = tmpMeta21;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmpMeta1 = _inMod;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outMod = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeInstUtil_expandEnumerationSubMod(threadData_t *threadData, modelica_metatype _inSubMod, modelica_boolean _inChanged, modelica_boolean *out_outChanged)
{
modelica_metatype _outSubMod = NULL;
modelica_boolean _outChanged;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_integer tmp17;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inSubMod;
{
modelica_metatype _mod = NULL;
modelica_metatype _mod1 = NULL;
modelica_string _ident = NULL;
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
modelica_boolean tmp11;
modelica_metatype tmpMeta12;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_ident = tmpMeta6;
_mod = tmpMeta7;
_mod1 = omc_SCodeInstUtil_expandEnumerationMod(threadData, _mod);
tmp11 = (modelica_boolean)referenceEq(_mod, _mod1);
if(tmp11)
{
tmpMeta8 = mmc_mk_box2(0, _inSubMod, mmc_mk_boolean(_inChanged));
tmpMeta12 = tmpMeta8;
}
else
{
tmpMeta9 = mmc_mk_box3(3, &SCode_SubMod_NAMEMOD__desc, _ident, _mod1);
tmpMeta10 = mmc_mk_box2(0, tmpMeta9, mmc_mk_boolean(1));
tmpMeta12 = tmpMeta10;
}
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta13;
tmpMeta13 = mmc_mk_box2(0, _inSubMod, mmc_mk_boolean(_inChanged));
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
tmpMeta14 = tmpMeta1;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 1));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
tmp17 = mmc_unbox_integer(tmpMeta16);
_outSubMod = tmpMeta15;
_outChanged = tmp17;
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inSl;
{
modelica_string _n = NULL;
modelica_metatype _sl = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _m = NULL;
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
modelica_metatype tmpMeta12;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
_n = tmpMeta9;
_m = tmpMeta10;
_rest = tmpMeta8;
_m = omc_SCodeInstUtil_removeSelfReferenceFromMod(threadData, _m, _inCref);
_sl = omc_SCodeInstUtil_removeSelfReferenceFromSubMod(threadData, _rest, _inCref);
tmpMeta12 = mmc_mk_box3(3, &SCode_SubMod_NAMEMOD__desc, _n, _m);
tmpMeta11 = mmc_mk_cons(tmpMeta12, _sl);
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
_outSl = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outSl;
}
DLLExport
modelica_metatype omc_SCodeInstUtil_removeSelfReferenceFromMod(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _inCref)
{
modelica_metatype _outMod = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inMod;
{
modelica_metatype _sl = NULL;
modelica_metatype _fp = NULL;
modelica_metatype _ep = NULL;
modelica_metatype _i = NULL;
modelica_metatype _binding = NULL;
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
_fp = tmpMeta5;
_ep = tmpMeta6;
_sl = tmpMeta7;
_binding = tmpMeta8;
_i = tmpMeta9;
_binding = omc_SCodeInstUtil_removeReferenceInBinding(threadData, _binding, _inCref);
_sl = omc_SCodeInstUtil_removeSelfReferenceFromSubMod(threadData, _sl, _inCref);
tmpMeta10 = mmc_mk_box6(3, &SCode_Mod_MOD__desc, _fp, _ep, _sl, _binding, _i);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 4: {
tmpMeta1 = _inMod;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmpMeta1 = _inMod;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outMod = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeInstUtil_removeReferenceInBinding(threadData_t *threadData, modelica_metatype _inBinding, modelica_metatype _inCref)
{
modelica_metatype _outBinding = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inBinding;
{
modelica_metatype _e = NULL;
modelica_metatype _crlst1 = NULL;
modelica_metatype _crlst2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_e = tmpMeta6;
_crlst1 = omc_AbsynUtil_getCrefFromExp(threadData, _e, 1, 1);
_crlst2 = omc_AbsynUtil_removeCrefFromCrefs(threadData, _crlst1, _inCref);
tmpMeta1 = ((listLength(_crlst1) == listLength(_crlst2))?_inBinding:mmc_mk_none());
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
_outBinding = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outBinding;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeInstUtil_makeElementsIntoSubMods(threadData_t *threadData, modelica_metatype _inFinal, modelica_metatype _inEach, modelica_metatype _inElements)
{
modelica_metatype _outSubMods = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inFinal;
tmp4_2 = _inEach;
tmp4_3 = _inElements;
{
modelica_metatype _el = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _f = NULL;
modelica_metatype _e = NULL;
modelica_string _n = NULL;
modelica_metatype _newSubMods = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (!listEmpty(tmp4_3)) goto tmp3_end;
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
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_3);
tmpMeta8 = MMC_CDR(tmp4_3);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,2,8) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,1,2) == 0) goto tmp3_end;
_el = tmpMeta7;
_rest = tmpMeta8;
_f = tmp4_1;
_e = tmp4_2;
tmpMeta10 = stringAppend(_OMC_LIT3,omc_SCodeDump_unparseElementStr(threadData, _el, _OMC_LIT4));
tmpMeta11 = stringAppend(tmpMeta10,_OMC_LIT5);
fputs(MMC_STRINGDATA(tmpMeta11),stdout);
_inFinal = _f;
_inEach = _e;
_inElements = _rest;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmp4_3);
tmpMeta13 = MMC_CDR(tmp4_3);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,3,8) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
_el = tmpMeta12;
_n = tmpMeta14;
_rest = tmpMeta13;
_f = tmp4_1;
_e = tmp4_2;
_newSubMods = omc_SCodeInstUtil_makeElementsIntoSubMods(threadData, _f, _e, _rest);
tmpMeta16 = mmc_mk_box4(4, &SCode_Mod_REDECL__desc, _f, _e, _el);
tmpMeta17 = mmc_mk_box3(3, &SCode_SubMod_NAMEMOD__desc, _n, tmpMeta16);
tmpMeta15 = mmc_mk_cons(tmpMeta17, _newSubMods);
tmpMeta1 = tmpMeta15;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta18 = MMC_CAR(tmp4_3);
tmpMeta19 = MMC_CDR(tmp4_3);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,2,8) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
_el = tmpMeta18;
_n = tmpMeta20;
_rest = tmpMeta19;
_f = tmp4_1;
_e = tmp4_2;
_newSubMods = omc_SCodeInstUtil_makeElementsIntoSubMods(threadData, _f, _e, _rest);
tmpMeta22 = mmc_mk_box4(4, &SCode_Mod_REDECL__desc, _f, _e, _el);
tmpMeta23 = mmc_mk_box3(3, &SCode_SubMod_NAMEMOD__desc, _n, tmpMeta22);
tmpMeta21 = mmc_mk_cons(tmpMeta23, _newSubMods);
tmpMeta1 = tmpMeta21;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta24 = MMC_CAR(tmp4_3);
tmpMeta25 = MMC_CDR(tmp4_3);
_el = tmpMeta24;
_rest = tmpMeta25;
_f = tmp4_1;
_e = tmp4_2;
tmpMeta26 = stringAppend(_OMC_LIT6,omc_SCodeDump_unparseElementStr(threadData, _el, _OMC_LIT4));
tmpMeta27 = stringAppend(tmpMeta26,_OMC_LIT5);
fputs(MMC_STRINGDATA(tmpMeta27),stdout);
_inFinal = _f;
_inEach = _e;
_inElements = _rest;
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
_outSubMods = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outSubMods;
}
DLLExport
modelica_metatype omc_SCodeInstUtil_addRedeclareAsElementsToExtends(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _redeclareElements)
{
modelica_metatype _outExtendsElements = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inElements;
tmp4_2 = _redeclareElements;
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
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta1 = _inElements;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (!listEmpty(tmp4_1)) goto tmp3_end;
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,5) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 6));
_baseClassPath = tmpMeta9;
_visibility = tmpMeta10;
_mod = tmpMeta11;
_ann = tmpMeta12;
_info = tmpMeta13;
_rest = tmpMeta8;
_redecls = tmp4_2;
_submods = omc_SCodeInstUtil_makeElementsIntoSubMods(threadData, _OMC_LIT7, _OMC_LIT8, _redecls);
tmpMeta14 = mmc_mk_box6(3, &SCode_Mod_MOD__desc, _OMC_LIT7, _OMC_LIT8, _submods, mmc_mk_none(), _info);
_redeclareMod = tmpMeta14;
_mod = omc_SCodeUtil_mergeSCodeMods(threadData, _redeclareMod, _mod);
_out = omc_SCodeInstUtil_addRedeclareAsElementsToExtends(threadData, _rest, _redecls);
tmpMeta16 = mmc_mk_box6(4, &SCode_Element_EXTENDS__desc, _baseClassPath, _visibility, _mod, _ann, _info);
tmpMeta15 = mmc_mk_cons(tmpMeta16, _out);
tmpMeta1 = tmpMeta15;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta17 = MMC_CAR(tmp4_1);
tmpMeta18 = MMC_CDR(tmp4_1);
_el = tmpMeta17;
_rest = tmpMeta18;
_redecls = tmp4_2;
_out = omc_SCodeInstUtil_addRedeclareAsElementsToExtends(threadData, _rest, _redecls);
tmpMeta19 = mmc_mk_cons(_el, _out);
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
_outExtendsElements = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExtendsElements;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeInstUtil_removeNonConstantBindingsKeepRedeclaresFromSubMod(threadData_t *threadData, modelica_metatype _inSl, modelica_boolean _onlyRedeclares)
{
modelica_metatype _outSl = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inSl;
{
modelica_string _n = NULL;
modelica_metatype _sl = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _m = NULL;
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
modelica_metatype tmpMeta12;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
_n = tmpMeta9;
_m = tmpMeta10;
_rest = tmpMeta8;
_m = omc_SCodeInstUtil_removeNonConstantBindingsKeepRedeclares(threadData, _m, _onlyRedeclares);
_sl = omc_SCodeInstUtil_removeNonConstantBindingsKeepRedeclaresFromSubMod(threadData, _rest, _onlyRedeclares);
tmpMeta12 = mmc_mk_box3(3, &SCode_SubMod_NAMEMOD__desc, _n, _m);
tmpMeta11 = mmc_mk_cons(tmpMeta12, _sl);
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
_outSl = tmpMeta1;
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inMod;
{
modelica_metatype _sl = NULL;
modelica_metatype _fp = NULL;
modelica_metatype _ep = NULL;
modelica_metatype _i = NULL;
modelica_metatype _binding = NULL;
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
_fp = tmpMeta5;
_ep = tmpMeta6;
_sl = tmpMeta7;
_binding = tmpMeta8;
_i = tmpMeta9;
_binding = (_onlyRedeclares?mmc_mk_none():omc_SCodeInstUtil_constantBindingOrNone(threadData, _binding));
_sl = omc_SCodeInstUtil_removeNonConstantBindingsKeepRedeclaresFromSubMod(threadData, _sl, _onlyRedeclares);
tmpMeta10 = mmc_mk_box6(3, &SCode_Mod_MOD__desc, _fp, _ep, _sl, _binding, _i);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 4: {
tmpMeta1 = _inMod;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmpMeta1 = _inMod;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outMod = tmpMeta1;
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inBinding;
{
modelica_metatype _e = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_e = tmpMeta6;
tmpMeta1 = (listEmpty(omc_AbsynUtil_getCrefFromExp(threadData, _e, 1, 1))?_inBinding:mmc_mk_none());
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
_outBinding = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outBinding;
}
