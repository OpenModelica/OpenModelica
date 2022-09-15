#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "SemanticVersion.c"
#endif
#include "omc_simulation_settings.h"
#include "SemanticVersion.h"
#define _OMC_LIT0_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,1,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "+"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,1,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,0,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "-"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,1,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "^([0-9][0-9]*\\.?[0-9]*\\.?[0-9]*)([+-][0-9A-Za-z.-]*)?$"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,54,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,2,4) {&SemanticVersion_Version_NONSEMVER__desc,_OMC_LIT2}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "0"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,1,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#include "util/modelica.h"
#include "SemanticVersion_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_integer omc_SemanticVersion_compareIdentifier(threadData_t *threadData, modelica_string _s1, modelica_string _s2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SemanticVersion_compareIdentifier(threadData_t *threadData, modelica_metatype _s1, modelica_metatype _s2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SemanticVersion_compareIdentifier,2,0) {(void*) boxptr_SemanticVersion_compareIdentifier,0}};
#define boxvar_SemanticVersion_compareIdentifier MMC_REFSTRUCTLIT(boxvar_lit_SemanticVersion_compareIdentifier)
PROTECTED_FUNCTION_STATIC modelica_integer omc_SemanticVersion_compareIdentifierList(threadData_t *threadData, modelica_metatype _w1, modelica_metatype _w2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SemanticVersion_compareIdentifierList(threadData_t *threadData, modelica_metatype _w1, modelica_metatype _w2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SemanticVersion_compareIdentifierList,2,0) {(void*) boxptr_SemanticVersion_compareIdentifierList,0}};
#define boxvar_SemanticVersion_compareIdentifierList MMC_REFSTRUCTLIT(boxvar_lit_SemanticVersion_compareIdentifierList)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SemanticVersion_splitPrereleaseAndMeta(threadData_t *threadData, modelica_string _s, modelica_metatype *out_metaLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SemanticVersion_splitPrereleaseAndMeta,2,0) {(void*) boxptr_SemanticVersion_splitPrereleaseAndMeta,0}};
#define boxvar_SemanticVersion_splitPrereleaseAndMeta MMC_REFSTRUCTLIT(boxvar_lit_SemanticVersion_splitPrereleaseAndMeta)
PROTECTED_FUNCTION_STATIC modelica_integer omc_SemanticVersion_compareIdentifier(threadData_t *threadData, modelica_string _s1, modelica_string _s2)
{
modelica_integer _c;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(omc_Util_isIntegerString(threadData, _s1))
{
_c = (omc_Util_isIntegerString(threadData, _s2)?omc_Util_intCompare(threadData, stringInt(_s1), stringInt(_s2)):((modelica_integer) -1));
goto _return;
}
if(omc_Util_isIntegerString(threadData, _s2))
{
_c = ((modelica_integer) 1);
}
_c = stringCompare(_s1, _s2);
_return: OMC_LABEL_UNUSED
return _c;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SemanticVersion_compareIdentifier(threadData_t *threadData, modelica_metatype _s1, modelica_metatype _s2)
{
modelica_integer _c;
modelica_metatype out_c;
_c = omc_SemanticVersion_compareIdentifier(threadData, _s1, _s2);
out_c = mmc_mk_icon(_c);
return out_c;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_SemanticVersion_compareIdentifierList(threadData_t *threadData, modelica_metatype _w1, modelica_metatype _w2)
{
modelica_integer _c;
modelica_metatype _l1 = NULL;
modelica_metatype _l2 = NULL;
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
modelica_integer tmp1_c0 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_l1 = _w1;
_l2 = _w2;
if((listEmpty(_l1) && (!listEmpty(_l2))))
{
_c = ((modelica_integer) 1);
}
if((listEmpty(_l2) && (!listEmpty(_l1))))
{
_c = ((modelica_integer) -1);
}
while(1)
{
if(!(!(listEmpty(_l1) && listEmpty(_l2)))) break;
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _l1;
tmp4_2 = _l2;
{
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
tmp1_c0 = ((modelica_integer) -1);
tmpMeta[0+1] = _l1;
tmpMeta[0+2] = _l2;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_1);
tmpMeta9 = MMC_CDR(tmp4_1);
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmp1_c0 = ((modelica_integer) 1);
tmpMeta[0+1] = _l1;
tmpMeta[0+2] = _l2;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmp4_2);
tmpMeta13 = MMC_CDR(tmp4_2);
_s1 = tmpMeta10;
_l1 = tmpMeta11;
_s2 = tmpMeta12;
_l2 = tmpMeta13;
tmp1_c0 = omc_SemanticVersion_compareIdentifier(threadData, _s1, _s2);
tmpMeta[0+1] = _l1;
tmpMeta[0+2] = _l2;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_c = tmp1_c0;
_l1 = tmpMeta[0+1];
_l2 = tmpMeta[0+2];
if((_c != ((modelica_integer) 0)))
{
goto _return;
}
}
_c = ((modelica_integer) 0);
_return: OMC_LABEL_UNUSED
return _c;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SemanticVersion_compareIdentifierList(threadData_t *threadData, modelica_metatype _w1, modelica_metatype _w2)
{
modelica_integer _c;
modelica_metatype out_c;
_c = omc_SemanticVersion_compareIdentifierList(threadData, _w1, _w2);
out_c = mmc_mk_icon(_c);
return out_c;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SemanticVersion_splitPrereleaseAndMeta(threadData_t *threadData, modelica_string _s, modelica_metatype *out_metaLst)
{
modelica_metatype _prereleaseLst = NULL;
modelica_metatype _metaLst = NULL;
modelica_string _meta = NULL;
modelica_string _prerelease = NULL;
modelica_metatype _split = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_boolean tmp4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_boolean tmp10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_boolean tmp13;
modelica_metatype tmpMeta14;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_prereleaseLst = tmpMeta1;
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
_metaLst = tmpMeta2;
if((stringLength(_s) == ((modelica_integer) 0)))
{
goto _return;
}
if((stringEqual(stringGetStringChar(_s, ((modelica_integer) 1)), _OMC_LIT1)))
{
tmp4 = (modelica_boolean)(stringLength(_s) > ((modelica_integer) 1));
if(tmp4)
{
tmpMeta5 = omc_Util_stringSplitAtChar(threadData, omc_Util_stringRest(threadData, _s), _OMC_LIT0);
}
else
{
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta5 = tmpMeta3;
}
_metaLst = tmpMeta5;
goto _return;
}
_split = omc_Util_stringSplitAtChar(threadData, _s, _OMC_LIT1);
tmpMeta6 = _split;
if (listEmpty(tmpMeta6)) MMC_THROW_INTERNAL();
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
_prerelease = tmpMeta7;
_split = tmpMeta8;
_meta = (listEmpty(_split)?_OMC_LIT2:listGet(_split, ((modelica_integer) 1)));
if((stringEqual(stringGetStringChar(_prerelease, ((modelica_integer) 1)), _OMC_LIT3)))
{
_prerelease = omc_Util_stringRest(threadData, _prerelease);
}
tmp10 = (modelica_boolean)(stringLength(_prerelease) > ((modelica_integer) 0));
if(tmp10)
{
tmpMeta11 = omc_Util_stringSplitAtChar(threadData, _prerelease, _OMC_LIT0);
}
else
{
tmpMeta9 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta11 = tmpMeta9;
}
_prereleaseLst = tmpMeta11;
tmp13 = (modelica_boolean)(stringLength(_meta) > ((modelica_integer) 0));
if(tmp13)
{
tmpMeta14 = omc_Util_stringSplitAtChar(threadData, _meta, _OMC_LIT0);
}
else
{
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta14 = tmpMeta12;
}
_metaLst = tmpMeta14;
_return: OMC_LABEL_UNUSED
if (out_metaLst) { *out_metaLst = _metaLst; }
return _prereleaseLst;
}
DLLExport
modelica_boolean omc_SemanticVersion_isSemVer(threadData_t *threadData, modelica_metatype _v)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _v;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
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
modelica_metatype boxptr_SemanticVersion_isSemVer(threadData_t *threadData, modelica_metatype _v)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_SemanticVersion_isSemVer(threadData, _v);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_SemanticVersion_hasMetaInformation(threadData_t *threadData, modelica_metatype _v)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _v;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 2: {
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
modelica_metatype boxptr_SemanticVersion_hasMetaInformation(threadData_t *threadData, modelica_metatype _v)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_SemanticVersion_hasMetaInformation(threadData, _v);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_SemanticVersion_isPrerelease(threadData_t *threadData, modelica_metatype _v)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _v;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
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
modelica_metatype boxptr_SemanticVersion_isPrerelease(threadData_t *threadData, modelica_metatype _v)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_SemanticVersion_isPrerelease(threadData, _v);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_string omc_SemanticVersion_toString(threadData_t *threadData, modelica_metatype _v)
{
modelica_string _out = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _v;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_string tmp6;
modelica_metatype tmpMeta7;
modelica_string tmp8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_string tmp11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
tmp6 = modelica_integer_to_modelica_string(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2)))), ((modelica_integer) 0), 1);
tmpMeta7 = stringAppend(tmp6,_OMC_LIT0);
tmp8 = modelica_integer_to_modelica_string(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))), ((modelica_integer) 0), 1);
tmpMeta9 = stringAppend(tmpMeta7,tmp8);
tmpMeta10 = stringAppend(tmpMeta9,_OMC_LIT0);
tmp11 = modelica_integer_to_modelica_string(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 4)))), ((modelica_integer) 0), 1);
tmpMeta12 = stringAppend(tmpMeta10,tmp11);
_out = tmpMeta12;
if((!listEmpty((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 5))))))
{
tmpMeta13 = stringAppend(_out,_OMC_LIT3);
tmpMeta14 = stringAppend(tmpMeta13,stringDelimitList((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 5))), _OMC_LIT0));
_out = tmpMeta14;
}
if((!listEmpty((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 6))))))
{
tmpMeta15 = stringAppend(_out,_OMC_LIT1);
tmpMeta16 = stringAppend(tmpMeta15,stringDelimitList((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 6))), _OMC_LIT0));
_out = tmpMeta16;
}
tmp1 = _out;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmp1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2)));
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_out = tmp1;
_return: OMC_LABEL_UNUSED
return _out;
}
DLLExport
modelica_integer omc_SemanticVersion_compare(threadData_t *threadData, modelica_metatype _v1, modelica_metatype _v2, modelica_boolean _comparePrerelease, modelica_boolean _compareBuildInformation)
{
modelica_integer _c;
modelica_integer tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _v1;
tmp4_2 = _v2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmp1 = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v2), 2))));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) -1);
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 1);
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,5) == 0) goto tmp3_end;
if(((((mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v1), 2)))) == ((modelica_integer) 0)) && (mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v1), 3)))) == ((modelica_integer) 0))) && (mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v1), 4)))) == ((modelica_integer) 0))) || (((mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v2), 2)))) == ((modelica_integer) 0)) && (mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v2), 3)))) == ((modelica_integer) 0))) && (mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v2), 4)))) == ((modelica_integer) 0)))))
{
_c = ((modelica_integer) 0);
}
else
{
_c = omc_Util_intCompare(threadData, mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v1), 2)))), mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v2), 2)))));
if((_c != ((modelica_integer) 0)))
{
goto _return;
}
_c = omc_Util_intCompare(threadData, mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v1), 3)))), mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v2), 3)))));
if((_c != ((modelica_integer) 0)))
{
goto _return;
}
_c = omc_Util_intCompare(threadData, mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v1), 4)))), mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v2), 4)))));
if((_c != ((modelica_integer) 0)))
{
goto _return;
}
}
if(_comparePrerelease)
{
_c = omc_SemanticVersion_compareIdentifierList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v1), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v2), 5))));
}
if(((_c == ((modelica_integer) 0)) && _compareBuildInformation))
{
_c = omc_SemanticVersion_compareIdentifierList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v1), 6))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v2), 6))));
}
tmp1 = _c;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_c = tmp1;
_return: OMC_LABEL_UNUSED
return _c;
}
modelica_metatype boxptr_SemanticVersion_compare(threadData_t *threadData, modelica_metatype _v1, modelica_metatype _v2, modelica_metatype _comparePrerelease, modelica_metatype _compareBuildInformation)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer _c;
modelica_metatype out_c;
tmp1 = mmc_unbox_integer(_comparePrerelease);
tmp2 = mmc_unbox_integer(_compareBuildInformation);
_c = omc_SemanticVersion_compare(threadData, _v1, _v2, tmp1, tmp2);
out_c = mmc_mk_icon(_c);
return out_c;
}
DLLExport
modelica_metatype omc_SemanticVersion_parse(threadData_t *threadData, modelica_string _s, modelica_boolean _nonsemverAsZeroZeroZero)
{
modelica_metatype _v = NULL;
modelica_integer _n;
modelica_string _major = NULL;
modelica_string _minor = NULL;
modelica_string _patch = NULL;
modelica_string _nextString = NULL;
modelica_string _versions = NULL;
modelica_metatype _prereleaseLst = NULL;
modelica_metatype _metaLst = NULL;
modelica_metatype _matches = NULL;
modelica_metatype _split = NULL;
modelica_metatype _versionsLst = NULL;
modelica_string _semverRegex = NULL;
modelica_metatype tmpMeta1;
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
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_semverRegex = _OMC_LIT4;
_n = omc_System_regex(threadData, _s, _OMC_LIT4, ((modelica_integer) 5), 1, 0 ,&_matches);
if((_n < ((modelica_integer) 2)))
{
if((stringLength(_s) == ((modelica_integer) 0)))
{
_v = _OMC_LIT5;
goto _return;
}
if(_nonsemverAsZeroZeroZero)
{
_prereleaseLst = omc_SemanticVersion_splitPrereleaseAndMeta(threadData, _s ,&_metaLst);
tmpMeta1 = mmc_mk_box6(3, &SemanticVersion_Version_SEMVER__desc, mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), _prereleaseLst, _metaLst);
_v = tmpMeta1;
}
else
{
tmpMeta2 = mmc_mk_box2(4, &SemanticVersion_Version_NONSEMVER__desc, _s);
_v = tmpMeta2;
}
goto _return;
}
tmpMeta3 = _matches;
if (listEmpty(tmpMeta3)) MMC_THROW_INTERNAL();
tmpMeta4 = MMC_CAR(tmpMeta3);
tmpMeta5 = MMC_CDR(tmpMeta3);
if (listEmpty(tmpMeta5)) MMC_THROW_INTERNAL();
tmpMeta6 = MMC_CAR(tmpMeta5);
tmpMeta7 = MMC_CDR(tmpMeta5);
_versions = tmpMeta6;
_split = tmpMeta7;
_versionsLst = omc_Util_stringSplitAtChar(threadData, _versions, _OMC_LIT0);
tmpMeta8 = _versionsLst;
if (listEmpty(tmpMeta8)) MMC_THROW_INTERNAL();
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
_major = tmpMeta9;
_versionsLst = tmpMeta10;
if((!listEmpty(_versionsLst)))
{
tmpMeta11 = _versionsLst;
if (listEmpty(tmpMeta11)) MMC_THROW_INTERNAL();
tmpMeta12 = MMC_CAR(tmpMeta11);
tmpMeta13 = MMC_CDR(tmpMeta11);
_minor = tmpMeta12;
_versionsLst = tmpMeta13;
}
else
{
_minor = _OMC_LIT6;
}
if((!listEmpty(_versionsLst)))
{
tmpMeta14 = _versionsLst;
if (listEmpty(tmpMeta14)) MMC_THROW_INTERNAL();
tmpMeta15 = MMC_CAR(tmpMeta14);
tmpMeta16 = MMC_CDR(tmpMeta14);
_patch = tmpMeta15;
_versionsLst = tmpMeta16;
}
else
{
_patch = _OMC_LIT6;
}
_prereleaseLst = omc_SemanticVersion_splitPrereleaseAndMeta(threadData, (listEmpty(_split)?_OMC_LIT2:listGet(_split, ((modelica_integer) 1))) ,&_metaLst);
tmpMeta17 = mmc_mk_box6(3, &SemanticVersion_Version_SEMVER__desc, mmc_mk_integer(stringInt(_major)), mmc_mk_integer(stringInt(_minor)), mmc_mk_integer(stringInt(_patch)), _prereleaseLst, _metaLst);
_v = tmpMeta17;
_return: OMC_LABEL_UNUSED
return _v;
}
modelica_metatype boxptr_SemanticVersion_parse(threadData_t *threadData, modelica_metatype _s, modelica_metatype _nonsemverAsZeroZeroZero)
{
modelica_integer tmp1;
modelica_metatype _v = NULL;
tmp1 = mmc_unbox_integer(_nonsemverAsZeroZeroZero);
_v = omc_SemanticVersion_parse(threadData, _s, tmp1);
return _v;
}
