#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/SemanticVersion.c"
#endif
#include "omc_simulation_settings.h"
#include "SemanticVersion.h"
#define _OMC_LIT0_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,1,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "-"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,1,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "+"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,1,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "^([0-9][0-9]*\\.?[0-9]*\\.?[0-9]*)([+-][0-9A-Za-z.-]*)?$"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,54,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "0"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,1,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,0,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
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
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
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
if (!listEmpty(tmp4_1)) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[3] = MMC_CAR(tmp4_2);
tmpMeta[4] = MMC_CDR(tmp4_2);
tmp1_c0 = ((modelica_integer) -1);
tmpMeta[0+1] = _l1;
tmpMeta[0+2] = _l2;
goto tmp3_done;
}
case 1: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[3] = MMC_CAR(tmp4_1);
tmpMeta[4] = MMC_CDR(tmp4_1);
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmp1_c0 = ((modelica_integer) 1);
tmpMeta[0+1] = _l1;
tmpMeta[0+2] = _l2;
goto tmp3_done;
}
case 2: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[3] = MMC_CAR(tmp4_1);
tmpMeta[4] = MMC_CDR(tmp4_1);
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[5] = MMC_CAR(tmp4_2);
tmpMeta[6] = MMC_CDR(tmp4_2);
_s1 = tmpMeta[3];
_l1 = tmpMeta[4];
_s2 = tmpMeta[5];
_l2 = tmpMeta[6];
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
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (!listEmpty(tmpMeta[0])) goto tmp3_end;
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (listEmpty(tmpMeta[0])) goto tmp3_end;
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
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
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
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
modelica_string tmp7;
modelica_string tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
tmp6 = modelica_integer_to_modelica_string(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2)))), ((modelica_integer) 0), 1);
tmpMeta[0] = stringAppend(tmp6,_OMC_LIT0);
tmp7 = modelica_integer_to_modelica_string(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))), ((modelica_integer) 0), 1);
tmpMeta[1] = stringAppend(tmpMeta[0],tmp7);
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT0);
tmp8 = modelica_integer_to_modelica_string(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 4)))), ((modelica_integer) 0), 1);
tmpMeta[3] = stringAppend(tmpMeta[2],tmp8);
_out = tmpMeta[3];
if((!listEmpty((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 5))))))
{
tmpMeta[0] = stringAppend(_out,_OMC_LIT1);
tmpMeta[1] = stringAppend(tmpMeta[0],stringDelimitList((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 5))), _OMC_LIT0));
_out = tmpMeta[1];
}
if((!listEmpty((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 6))))))
{
tmpMeta[0] = stringAppend(_out,_OMC_LIT2);
tmpMeta[1] = stringAppend(tmpMeta[0],stringDelimitList((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 6))), _OMC_LIT0));
_out = tmpMeta[1];
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
_c = omc_SemanticVersion_compareIdentifierList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v1), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v2), 5))));
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
modelica_metatype omc_SemanticVersion_parse(threadData_t *threadData, modelica_string _s)
{
modelica_metatype _v = NULL;
modelica_integer _n;
modelica_string _major = NULL;
modelica_string _minor = NULL;
modelica_string _patch = NULL;
modelica_string _prerelease = NULL;
modelica_string _meta = NULL;
modelica_string _nextString = NULL;
modelica_string _versions = NULL;
modelica_metatype _prereleaseLst = NULL;
modelica_metatype _metaLst = NULL;
modelica_metatype _matches = NULL;
modelica_metatype _split = NULL;
modelica_metatype _versionsLst = NULL;
modelica_string _semverRegex = NULL;
modelica_boolean tmp1;
modelica_boolean tmp2;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_semverRegex = _OMC_LIT3;
_n = omc_System_regex(threadData, _s, _OMC_LIT3, ((modelica_integer) 5), 1, 0 ,&_matches);
if((_n < ((modelica_integer) 2)))
{
tmpMeta[0] = mmc_mk_box2(4, &SemanticVersion_Version_NONSEMVER__desc, _s);
_v = tmpMeta[0];
goto _return;
}
tmpMeta[0] = _matches;
if (listEmpty(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
if (listEmpty(tmpMeta[2])) MMC_THROW_INTERNAL();
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
_versions = tmpMeta[3];
_split = tmpMeta[4];
_versionsLst = omc_Util_stringSplitAtChar(threadData, _versions, _OMC_LIT0);
tmpMeta[0] = _versionsLst;
if (listEmpty(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
_major = tmpMeta[1];
_versionsLst = tmpMeta[2];
if((!listEmpty(_versionsLst)))
{
tmpMeta[0] = _versionsLst;
if (listEmpty(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
_minor = tmpMeta[1];
_versionsLst = tmpMeta[2];
}
else
{
_minor = _OMC_LIT4;
}
if((!listEmpty(_versionsLst)))
{
tmpMeta[0] = _versionsLst;
if (listEmpty(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
_patch = tmpMeta[1];
_versionsLst = tmpMeta[2];
}
else
{
_patch = _OMC_LIT4;
}
_nextString = (listEmpty(_split)?_OMC_LIT5:listGet(_split, ((modelica_integer) 1)));
if((stringLength(_nextString) == ((modelica_integer) 0)))
{
_prerelease = _OMC_LIT5;
_meta = _OMC_LIT5;
}
else
{
if((stringEqual(stringGetStringChar(_nextString, ((modelica_integer) 1)), _OMC_LIT2)))
{
_prerelease = _OMC_LIT5;
_meta = _nextString;
}
else
{
_split = omc_Util_stringSplitAtChar(threadData, _nextString, _OMC_LIT2);
tmpMeta[0] = _split;
if (listEmpty(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
_prerelease = tmpMeta[1];
_split = tmpMeta[2];
_meta = (listEmpty(_split)?_OMC_LIT5:listGet(_split, ((modelica_integer) 1)));
}
}
tmp1 = (modelica_boolean)(stringLength(_prerelease) > ((modelica_integer) 0));
if(tmp1)
{
tmpMeta[1] = omc_Util_stringSplitAtChar(threadData, omc_Util_stringRest(threadData, _prerelease), _OMC_LIT0);
}
else
{
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = tmpMeta[0];
}
_prereleaseLst = tmpMeta[1];
tmp2 = (modelica_boolean)(stringLength(_meta) > ((modelica_integer) 0));
if(tmp2)
{
tmpMeta[1] = omc_Util_stringSplitAtChar(threadData, omc_Util_stringRest(threadData, _meta), _OMC_LIT0);
}
else
{
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = tmpMeta[0];
}
_metaLst = tmpMeta[1];
tmpMeta[0] = mmc_mk_box6(3, &SemanticVersion_Version_SEMVER__desc, mmc_mk_integer(stringInt(_major)), mmc_mk_integer(stringInt(_minor)), mmc_mk_integer(stringInt(_patch)), _prereleaseLst, _metaLst);
_v = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _v;
}
