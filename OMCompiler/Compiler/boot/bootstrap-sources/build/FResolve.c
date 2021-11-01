#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "FResolve.c"
#endif
#include "omc_simulation_settings.h"
#include "FResolve.h"
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT0,4,3) {&FLookup_Options_OPTIONS__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1))}};
#define _OMC_LIT0 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "$ref"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,4,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "FResolve.elred_one: redeclare as element: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,42,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data " scope: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,8,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data " not found in extends of: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,26,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data ":\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,2,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "	"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,1,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "\n	"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,2,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,1,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "$mod"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,4,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,4,3) {&FLookup_Options_OPTIONS__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "FResolve.mod_one: modifier: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,28,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data " not found in: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,15,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "!\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,2,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data "FResolve.cr_one: component reference: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,38,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data "FResolve.clsext_one: class extends: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,36,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "FResolve.cc_one: constrained class: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,36,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,1,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
#define _OMC_LIT18_data "FResolve.ty_one: component type path: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT18,38,_OMC_LIT18_data);
#define _OMC_LIT18 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT18)
#define _OMC_LIT19_data "FResolve.derived_one: baseclass: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT19,33,_OMC_LIT19_data);
#define _OMC_LIT19 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data "FResolve.ext_one: baseclass: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,29,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
#include "util/modelica.h"
#include "FResolve_includes.h"
DLLExport
modelica_metatype omc_FResolve_elred__one(threadData_t *threadData, modelica_string _name, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inRef;
tmp4_2 = _ig;
{
modelica_metatype _r = NULL;
modelica_metatype _rr = NULL;
modelica_metatype _p = NULL;
modelica_string _id = NULL;
modelica_metatype _g = NULL;
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
modelica_boolean tmp7;
modelica_boolean tmp8;
_r = tmp4_1;
_g = tmp4_2;
tmp6 = omc_FNode_isRefRedeclare(threadData, _r);
if (1 != tmp6) goto goto_2;
tmp7 = ((omc_FNode_isRefClass(threadData, _r) && (!omc_FNode_isRefClassExtends(threadData, _r))) || omc_FNode_isRefComponent(threadData, _r));
if (1 != tmp7) goto goto_2;
tmp8 = omc_FNode_isRefRefResolved(threadData, _r);
if (1 != tmp8) goto goto_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp9;
modelica_boolean tmp10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
_r = tmp4_1;
_g = tmp4_2;
tmp9 = omc_FNode_isRefRedeclare(threadData, _r);
if (1 != tmp9) goto goto_2;
tmp10 = ((omc_FNode_isRefClass(threadData, _r) && (!omc_FNode_isRefClassExtends(threadData, _r))) || omc_FNode_isRefComponent(threadData, _r));
if (1 != tmp10) goto goto_2;
_id = omc_SCodeUtil_elementName(threadData, omc_FNode_getElement(threadData, omc_FNode_fromRef(threadData, _r)));
tmpMeta11 = omc_FNode_parents(threadData, omc_FNode_fromRef(threadData, _r));
if (listEmpty(tmpMeta11)) goto goto_2;
tmpMeta12 = MMC_CAR(tmpMeta11);
tmpMeta13 = MMC_CDR(tmpMeta11);
_p = tmpMeta12;
_g = omc_FLookup_ext(threadData, _g, _p, _id, _OMC_LIT0, mmc_mk_none() ,&_rr);
tmpMeta14 = mmc_mk_cons(_rr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta14, _r, _g);
goto tmp3_done;
}
case 2: {
modelica_boolean tmp15;
modelica_boolean tmp16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_boolean tmp20;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
_r = tmp4_1;
_g = tmp4_2;
tmp15 = omc_FNode_isRefRedeclare(threadData, _r);
if (1 != tmp15) goto goto_2;
tmp16 = ((omc_FNode_isRefClass(threadData, _r) && (!omc_FNode_isRefClassExtends(threadData, _r))) || omc_FNode_isRefComponent(threadData, _r));
if (1 != tmp16) goto goto_2;
_id = omc_SCodeUtil_elementName(threadData, omc_FNode_getElement(threadData, omc_FNode_fromRef(threadData, _r)));
tmpMeta17 = omc_FNode_parents(threadData, omc_FNode_fromRef(threadData, _r));
if (listEmpty(tmpMeta17)) goto goto_2;
tmpMeta18 = MMC_CAR(tmpMeta17);
tmpMeta19 = MMC_CDR(tmpMeta17);
_p = tmpMeta18;
tmp20 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_FLookup_ext(threadData, _g, _p, _id, _OMC_LIT0, mmc_mk_none(), NULL);
tmp20 = 1;
goto goto_21;
goto_21:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp20) {goto goto_2;}
tmpMeta22 = stringAppend(_OMC_LIT2,_id);
tmpMeta23 = stringAppend(tmpMeta22,_OMC_LIT3);
tmpMeta24 = stringAppend(tmpMeta23,omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _r)));
tmpMeta25 = stringAppend(tmpMeta24,_OMC_LIT4);
tmpMeta26 = stringAppend(tmpMeta25,omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _p)));
tmpMeta27 = stringAppend(tmpMeta26,_OMC_LIT5);
fputs(MMC_STRINGDATA(tmpMeta27),stdout);
tmpMeta28 = stringAppend(_OMC_LIT6,stringDelimitList(omc_List_map(threadData, omc_List_map(threadData, omc_FNode_extendsRefs(threadData, _p), boxvar_FNode_fromRef), boxvar_FNode_toPathStr), _OMC_LIT7));
tmpMeta29 = stringAppend(tmpMeta28,_OMC_LIT8);
fputs(MMC_STRINGDATA(tmpMeta29),stdout);
tmpMeta30 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta30, _r, _g);
goto tmp3_done;
}
case 3: {
tmpMeta1 = _ig;
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
_og = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_elred(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _ig;
{
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_g = tmp4_1;
tmpMeta1 = omc_FNode_apply1(threadData, _inRef, boxvar_FResolve_elred__one, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_og = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_mod__one(threadData_t *threadData, modelica_string _name, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inRef;
tmp4_2 = _ig;
{
modelica_metatype _r = NULL;
modelica_metatype _rr = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _g = NULL;
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
modelica_boolean tmp7;
_r = tmp4_1;
_g = tmp4_2;
tmp6 = ((omc_FNode_isRefMod(threadData, _r) && (!omc_FNode_isRefModHolder(threadData, _r))) && (!omc_ClassInf_isBasicTypeComponentName(threadData, omc_FNode_refName(threadData, _r))));
if (1 != tmp6) goto goto_2;
tmp7 = omc_FNode_isRefRefResolved(threadData, _r);
if (1 != tmp7) goto goto_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp8;
modelica_metatype tmpMeta9;
_r = tmp4_1;
_g = tmp4_2;
tmp8 = ((omc_FNode_isRefMod(threadData, _r) && (!omc_FNode_isRefModHolder(threadData, _r))) && (!omc_ClassInf_isBasicTypeComponentName(threadData, omc_FNode_refName(threadData, _r))));
if (1 != tmp8) goto goto_2;
_cr = omc_AbsynUtil_pathToCref(threadData, omc_AbsynUtil_stringListPath(threadData, omc_FNode_namesUpToParentName(threadData, _r, _OMC_LIT9)));
_g = omc_FLookup_cr(threadData, _g, omc_FNode_getModifierTarget(threadData, _r), _cr, _OMC_LIT10, mmc_mk_none() ,&_rr);
tmpMeta9 = mmc_mk_cons(_rr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta9, _r, _g);
goto tmp3_done;
}
case 2: {
modelica_boolean tmp10;
modelica_boolean tmp11;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
_r = tmp4_1;
_g = tmp4_2;
tmp10 = ((omc_FNode_isRefMod(threadData, _r) && (!omc_FNode_isRefModHolder(threadData, _r))) && (!omc_ClassInf_isBasicTypeComponentName(threadData, omc_FNode_refName(threadData, _r))));
if (1 != tmp10) goto goto_2;
_cr = omc_AbsynUtil_pathToCref(threadData, omc_AbsynUtil_stringListPath(threadData, omc_FNode_namesUpToParentName(threadData, _r, _OMC_LIT9)));
tmp11 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_FLookup_cr(threadData, _g, omc_FNode_getModifierTarget(threadData, _r), _cr, _OMC_LIT10, mmc_mk_none(), NULL);
tmp11 = 1;
goto goto_12;
goto_12:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp11) {goto goto_2;}
tmpMeta13 = stringAppend(_OMC_LIT11,omc_AbsynUtil_crefString(threadData, _cr));
tmpMeta14 = stringAppend(tmpMeta13,_OMC_LIT12);
tmpMeta15 = stringAppend(tmpMeta14,omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _r)));
tmpMeta16 = stringAppend(tmpMeta15,_OMC_LIT13);
fputs(MMC_STRINGDATA(tmpMeta16),stdout);
tmpMeta17 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta17, _r, _g);
goto tmp3_done;
}
case 3: {
tmpMeta1 = _ig;
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
_og = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_mod(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _ig;
{
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_g = tmp4_1;
tmpMeta1 = omc_FNode_apply1(threadData, _inRef, boxvar_FResolve_mod__one, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_og = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_cr__one(threadData_t *threadData, modelica_string _name, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inRef;
tmp4_2 = _ig;
{
modelica_metatype _r = NULL;
modelica_metatype _rr = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _g = NULL;
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
modelica_boolean tmp7;
_r = tmp4_1;
_g = tmp4_2;
tmp6 = omc_FNode_isRefCref(threadData, _r);
if (1 != tmp6) goto goto_2;
tmp7 = omc_FNode_isRefRefResolved(threadData, _r);
if (1 != tmp7) goto goto_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
_r = tmp4_1;
_g = tmp4_2;
tmp8 = omc_FNode_isRefCref(threadData, _r);
if (1 != tmp8) goto goto_2;
tmpMeta9 = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,17,1) == 0) goto goto_2;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
_cr = tmpMeta10;
_g = omc_FLookup_cr(threadData, _g, _r, _cr, _OMC_LIT10, mmc_mk_none() ,&_rr);
tmpMeta11 = mmc_mk_cons(_rr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta11, _r, _g);
goto tmp3_done;
}
case 2: {
modelica_boolean tmp12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_boolean tmp15;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
_r = tmp4_1;
_g = tmp4_2;
tmp12 = omc_FNode_isRefCref(threadData, _r);
if (1 != tmp12) goto goto_2;
tmpMeta13 = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,17,1) == 0) goto goto_2;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
_cr = tmpMeta14;
tmp15 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_FLookup_cr(threadData, _g, _r, _cr, _OMC_LIT10, mmc_mk_none(), NULL);
tmp15 = 1;
goto goto_16;
goto_16:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp15) {goto goto_2;}
tmpMeta17 = stringAppend(_OMC_LIT14,omc_AbsynUtil_crefString(threadData, _cr));
tmpMeta18 = stringAppend(tmpMeta17,_OMC_LIT12);
tmpMeta19 = stringAppend(tmpMeta18,omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _r)));
tmpMeta20 = stringAppend(tmpMeta19,_OMC_LIT13);
fputs(MMC_STRINGDATA(tmpMeta20),stdout);
tmpMeta21 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta21, _r, _g);
goto tmp3_done;
}
case 3: {
tmpMeta1 = _ig;
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
_og = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_cr(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _ig;
{
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_g = tmp4_1;
tmpMeta1 = omc_FNode_apply1(threadData, _inRef, boxvar_FResolve_cr__one, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_og = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_clsext__one(threadData_t *threadData, modelica_string _name, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inRef;
tmp4_2 = _ig;
{
modelica_metatype _r = NULL;
modelica_metatype _rr = NULL;
modelica_metatype _p = NULL;
modelica_string _id = NULL;
modelica_metatype _g = NULL;
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
modelica_boolean tmp7;
_r = tmp4_1;
_g = tmp4_2;
tmp6 = omc_FNode_isRefClassExtends(threadData, _r);
if (1 != tmp6) goto goto_2;
tmp7 = omc_FNode_isRefRefResolved(threadData, _r);
if (1 != tmp7) goto goto_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
_r = tmp4_1;
_g = tmp4_2;
tmp8 = omc_FNode_isRefClassExtends(threadData, _r);
if (1 != tmp8) goto goto_2;
tmpMeta9 = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,3,5) == 0) goto goto_2;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,2,8) == 0) goto goto_2;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_id = tmpMeta11;
tmpMeta12 = omc_FNode_parents(threadData, omc_FNode_fromRef(threadData, _r));
if (listEmpty(tmpMeta12)) goto goto_2;
tmpMeta13 = MMC_CAR(tmpMeta12);
tmpMeta14 = MMC_CDR(tmpMeta12);
_p = tmpMeta13;
_g = omc_FLookup_ext(threadData, _g, _p, _id, _OMC_LIT0, mmc_mk_none() ,&_rr);
tmpMeta15 = mmc_mk_cons(_rr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta15, _r, _g);
goto tmp3_done;
}
case 2: {
modelica_boolean tmp16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_boolean tmp23;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
_r = tmp4_1;
_g = tmp4_2;
tmp16 = omc_FNode_isRefClassExtends(threadData, _r);
if (1 != tmp16) goto goto_2;
tmpMeta17 = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,3,5) == 0) goto goto_2;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,2,8) == 0) goto goto_2;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
_id = tmpMeta19;
tmpMeta20 = omc_FNode_parents(threadData, omc_FNode_fromRef(threadData, _r));
if (listEmpty(tmpMeta20)) goto goto_2;
tmpMeta21 = MMC_CAR(tmpMeta20);
tmpMeta22 = MMC_CDR(tmpMeta20);
_p = tmpMeta21;
tmp23 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_FLookup_ext(threadData, _g, _p, _id, _OMC_LIT0, mmc_mk_none(), NULL);
tmp23 = 1;
goto goto_24;
goto_24:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp23) {goto goto_2;}
tmpMeta25 = stringAppend(_OMC_LIT15,_id);
tmpMeta26 = stringAppend(tmpMeta25,_OMC_LIT3);
tmpMeta27 = stringAppend(tmpMeta26,omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _r)));
tmpMeta28 = stringAppend(tmpMeta27,_OMC_LIT4);
tmpMeta29 = stringAppend(tmpMeta28,omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _p)));
tmpMeta30 = stringAppend(tmpMeta29,_OMC_LIT5);
fputs(MMC_STRINGDATA(tmpMeta30),stdout);
tmpMeta31 = stringAppend(_OMC_LIT6,stringDelimitList(omc_List_map(threadData, omc_List_map(threadData, omc_FNode_extendsRefs(threadData, _p), boxvar_FNode_fromRef), boxvar_FNode_toPathStr), _OMC_LIT7));
tmpMeta32 = stringAppend(tmpMeta31,_OMC_LIT8);
fputs(MMC_STRINGDATA(tmpMeta32),stdout);
tmpMeta33 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta33, _r, _g);
goto tmp3_done;
}
case 3: {
tmpMeta1 = _ig;
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
_og = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_clsext(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _ig;
{
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_g = tmp4_1;
tmpMeta1 = omc_FNode_apply1(threadData, _inRef, boxvar_FResolve_clsext__one, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_og = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_cc__one(threadData_t *threadData, modelica_string _name, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inRef;
tmp4_2 = _ig;
{
modelica_metatype _r = NULL;
modelica_metatype _rr = NULL;
modelica_metatype _p = NULL;
modelica_metatype _g = NULL;
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
modelica_boolean tmp7;
_r = tmp4_1;
_g = tmp4_2;
tmp6 = omc_FNode_isRefConstrainClass(threadData, _r);
if (1 != tmp6) goto goto_2;
tmp7 = omc_FNode_isRefRefResolved(threadData, _r);
if (1 != tmp7) goto goto_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
_r = tmp4_1;
_g = tmp4_2;
tmp8 = omc_FNode_isRefConstrainClass(threadData, _r);
if (1 != tmp8) goto goto_2;
tmpMeta9 = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,19,1) == 0) goto goto_2;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_p = tmpMeta11;
_g = omc_FLookup_name(threadData, _g, _r, _p, _OMC_LIT10, mmc_mk_none() ,&_rr);
tmpMeta12 = mmc_mk_cons(_rr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta12, _r, _g);
goto tmp3_done;
}
case 2: {
modelica_boolean tmp13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_boolean tmp17;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
_r = tmp4_1;
_g = tmp4_2;
tmp13 = omc_FNode_isRefConstrainClass(threadData, _r);
if (1 != tmp13) goto goto_2;
tmpMeta14 = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,19,1) == 0) goto goto_2;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
_p = tmpMeta16;
tmp17 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_FLookup_name(threadData, _g, _r, _p, _OMC_LIT10, mmc_mk_none(), NULL);
tmp17 = 1;
goto goto_18;
goto_18:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp17) {goto goto_2;}
tmpMeta19 = stringAppend(_OMC_LIT16,omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT17, 1, 0));
tmpMeta20 = stringAppend(tmpMeta19,_OMC_LIT12);
tmpMeta21 = stringAppend(tmpMeta20,omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _r)));
tmpMeta22 = stringAppend(tmpMeta21,_OMC_LIT13);
fputs(MMC_STRINGDATA(tmpMeta22),stdout);
tmpMeta23 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta23, _r, _g);
goto tmp3_done;
}
case 3: {
tmpMeta1 = _ig;
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
_og = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_cc(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _ig;
{
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_g = tmp4_1;
tmpMeta1 = omc_FNode_apply1(threadData, _inRef, boxvar_FResolve_cc__one, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_og = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_ty__one(threadData_t *threadData, modelica_string _name, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inRef;
tmp4_2 = _ig;
{
modelica_metatype _r = NULL;
modelica_metatype _rr = NULL;
modelica_metatype _p = NULL;
modelica_metatype _e = NULL;
modelica_metatype _g = NULL;
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
modelica_boolean tmp7;
_r = tmp4_1;
_g = tmp4_2;
tmp6 = omc_FNode_isRefComponent(threadData, _r);
if (1 != tmp6) goto goto_2;
tmp7 = omc_FNode_isRefRefResolved(threadData, _r);
if (1 != tmp7) goto goto_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
_r = tmp4_1;
_g = tmp4_2;
tmp8 = omc_FNode_isRefComponent(threadData, _r);
if (1 != tmp8) goto goto_2;
tmpMeta9 = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,4,4) == 0) goto goto_2;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
_e = tmpMeta10;
tmpMeta11 = omc_SCodeUtil_getComponentTypeSpec(threadData, _e);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,0,2) == 0) goto goto_2;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
_p = tmpMeta12;
_g = omc_FLookup_name(threadData, _g, _r, _p, _OMC_LIT10, mmc_mk_none() ,&_rr);
tmpMeta13 = mmc_mk_cons(_rr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta13, _r, _g);
goto tmp3_done;
}
case 2: {
modelica_boolean tmp14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_boolean tmp19;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
_r = tmp4_1;
_g = tmp4_2;
tmp14 = omc_FNode_isRefComponent(threadData, _r);
if (1 != tmp14) goto goto_2;
tmpMeta15 = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,4,4) == 0) goto goto_2;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
_e = tmpMeta16;
tmpMeta17 = omc_SCodeUtil_getComponentTypeSpec(threadData, _e);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,0,2) == 0) goto goto_2;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 2));
_p = tmpMeta18;
tmp19 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_FLookup_name(threadData, _g, _r, _p, _OMC_LIT10, mmc_mk_none(), NULL);
tmp19 = 1;
goto goto_20;
goto_20:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp19) {goto goto_2;}
tmpMeta21 = stringAppend(_OMC_LIT18,omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT17, 1, 0));
tmpMeta22 = stringAppend(tmpMeta21,_OMC_LIT12);
tmpMeta23 = stringAppend(tmpMeta22,omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _r)));
tmpMeta24 = stringAppend(tmpMeta23,_OMC_LIT13);
fputs(MMC_STRINGDATA(tmpMeta24),stdout);
tmpMeta25 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta25, _r, _g);
goto tmp3_done;
}
case 3: {
tmpMeta1 = _ig;
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
_og = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_ty(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _ig;
{
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_g = tmp4_1;
tmpMeta1 = omc_FNode_apply1(threadData, _inRef, boxvar_FResolve_ty__one, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_og = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_derived__one(threadData_t *threadData, modelica_string _name, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inRef;
tmp4_2 = _ig;
{
modelica_metatype _r = NULL;
modelica_metatype _rr = NULL;
modelica_metatype _p = NULL;
modelica_metatype _g = NULL;
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
modelica_boolean tmp7;
_r = tmp4_1;
_g = tmp4_2;
tmp6 = omc_FNode_isRefDerived(threadData, _r);
if (1 != tmp6) goto goto_2;
tmp7 = omc_FNode_isRefRefResolved(threadData, _r);
if (1 != tmp7) goto goto_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
_r = tmp4_1;
_g = tmp4_2;
tmp8 = omc_FNode_isRefDerived(threadData, _r);
if (1 != tmp8) goto goto_2;
tmpMeta9 = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,3,5) == 0) goto goto_2;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,2,8) == 0) goto goto_2;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,2,3) == 0) goto goto_2;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,0,2) == 0) goto goto_2;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
_p = tmpMeta13;
_g = omc_FLookup_name(threadData, _g, _r, _p, _OMC_LIT10, mmc_mk_none() ,&_rr);
tmpMeta14 = mmc_mk_cons(_rr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta14, _r, _g);
goto tmp3_done;
}
case 2: {
modelica_boolean tmp15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_boolean tmp21;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
_r = tmp4_1;
_g = tmp4_2;
tmp15 = omc_FNode_isRefDerived(threadData, _r);
if (1 != tmp15) goto goto_2;
tmpMeta16 = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,3,5) == 0) goto goto_2;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,2,8) == 0) goto goto_2;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,2,3) == 0) goto goto_2;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta19,0,2) == 0) goto goto_2;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 2));
_p = tmpMeta20;
tmp21 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_FLookup_name(threadData, _g, _r, _p, _OMC_LIT10, mmc_mk_none(), NULL);
tmp21 = 1;
goto goto_22;
goto_22:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp21) {goto goto_2;}
tmpMeta23 = stringAppend(_OMC_LIT19,omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT17, 1, 0));
tmpMeta24 = stringAppend(tmpMeta23,_OMC_LIT12);
tmpMeta25 = stringAppend(tmpMeta24,omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _r)));
tmpMeta26 = stringAppend(tmpMeta25,_OMC_LIT13);
fputs(MMC_STRINGDATA(tmpMeta26),stdout);
tmpMeta27 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta27, _r, _g);
goto tmp3_done;
}
case 3: {
tmpMeta1 = _ig;
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
_og = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_derived(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _ig;
{
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_g = tmp4_1;
tmpMeta1 = omc_FNode_apply1(threadData, _inRef, boxvar_FResolve_derived__one, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_og = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_ext__one(threadData_t *threadData, modelica_string _name, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inRef;
tmp4_2 = _ig;
{
modelica_metatype _r = NULL;
modelica_metatype _rr = NULL;
modelica_metatype _p = NULL;
modelica_metatype _e = NULL;
modelica_metatype _g = NULL;
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
modelica_boolean tmp7;
modelica_boolean tmp8;
_r = tmp4_1;
_g = tmp4_2;
tmp6 = omc_FNode_isRefExtends(threadData, _r);
if (1 != tmp6) goto goto_2;
tmp7 = omc_FNode_isRefDerived(threadData, _r);
if (0 != tmp7) goto goto_2;
tmp8 = omc_FNode_isRefRefResolved(threadData, _r);
if (1 != tmp8) goto goto_2;
tmpMeta1 = _g;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp9;
modelica_boolean tmp10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
_r = tmp4_1;
_g = tmp4_2;
tmp9 = omc_FNode_isRefExtends(threadData, _r);
if (1 != tmp9) goto goto_2;
tmp10 = omc_FNode_isRefDerived(threadData, _r);
if (0 != tmp10) goto goto_2;
tmpMeta11 = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,5,2) == 0) goto goto_2;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
_e = tmpMeta12;
_p = omc_SCodeUtil_getBaseClassPath(threadData, _e);
omc_SCodeUtil_elementInfo(threadData, _e);
_g = omc_FLookup_name(threadData, _g, _r, _p, _OMC_LIT10, mmc_mk_none() ,&_rr);
tmpMeta13 = mmc_mk_cons(_rr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta13, _r, _g);
goto tmp3_done;
}
case 2: {
modelica_boolean tmp14;
modelica_boolean tmp15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_boolean tmp18;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
_r = tmp4_1;
_g = tmp4_2;
tmp14 = omc_FNode_isRefExtends(threadData, _r);
if (1 != tmp14) goto goto_2;
tmp15 = omc_FNode_isRefDerived(threadData, _r);
if (0 != tmp15) goto goto_2;
tmpMeta16 = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,5,2) == 0) goto goto_2;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
_e = tmpMeta17;
_p = omc_SCodeUtil_getBaseClassPath(threadData, _e);
omc_SCodeUtil_elementInfo(threadData, _e);
tmp18 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_FLookup_name(threadData, _g, _r, _p, _OMC_LIT10, mmc_mk_none(), NULL);
tmp18 = 1;
goto goto_19;
goto_19:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp18) {goto goto_2;}
tmpMeta20 = stringAppend(_OMC_LIT20,omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT17, 1, 0));
tmpMeta21 = stringAppend(tmpMeta20,_OMC_LIT12);
tmpMeta22 = stringAppend(tmpMeta21,omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _r)));
tmpMeta23 = stringAppend(tmpMeta22,_OMC_LIT13);
fputs(MMC_STRINGDATA(tmpMeta23),stdout);
tmpMeta24 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta24, _r, _g);
goto tmp3_done;
}
case 3: {
tmpMeta1 = _ig;
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
_og = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_ext(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _ig;
{
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_g = tmp4_1;
tmpMeta1 = omc_FNode_apply1(threadData, _inRef, boxvar_FResolve_ext__one, _g);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_og = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _og;
}
