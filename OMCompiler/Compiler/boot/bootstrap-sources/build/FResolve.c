#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/FResolve.c"
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
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inRef;
tmp3_2 = _ig;
{
modelica_metatype _r = NULL;
modelica_metatype _rr = NULL;
modelica_metatype _p = NULL;
modelica_string _id = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
modelica_boolean tmp6;
modelica_boolean tmp7;
_r = tmp3_1;
_g = tmp3_2;
tmp5 = omc_FNode_isRefRedeclare(threadData, _r);
if (1 != tmp5) goto goto_1;
tmp6 = ((omc_FNode_isRefClass(threadData, _r) && (!omc_FNode_isRefClassExtends(threadData, _r))) || omc_FNode_isRefComponent(threadData, _r));
if (1 != tmp6) goto goto_1;
tmp7 = omc_FNode_isRefRefResolved(threadData, _r);
if (1 != tmp7) goto goto_1;
tmpMeta[0] = _g;
goto tmp2_done;
}
case 1: {
modelica_boolean tmp8;
modelica_boolean tmp9;
_r = tmp3_1;
_g = tmp3_2;
tmp8 = omc_FNode_isRefRedeclare(threadData, _r);
if (1 != tmp8) goto goto_1;
tmp9 = ((omc_FNode_isRefClass(threadData, _r) && (!omc_FNode_isRefClassExtends(threadData, _r))) || omc_FNode_isRefComponent(threadData, _r));
if (1 != tmp9) goto goto_1;
_id = omc_SCodeUtil_elementName(threadData, omc_FNode_getElement(threadData, omc_FNode_fromRef(threadData, _r)));
tmpMeta[1] = omc_FNode_parents(threadData, omc_FNode_fromRef(threadData, _r));
if (listEmpty(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
_p = tmpMeta[2];
_g = omc_FLookup_ext(threadData, _g, _p, _id, _OMC_LIT0, mmc_mk_none() ,&_rr);
tmpMeta[1] = mmc_mk_cons(_rr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta[1], _r, _g);
goto tmp2_done;
}
case 2: {
modelica_boolean tmp10;
modelica_boolean tmp11;
modelica_boolean tmp12;
_r = tmp3_1;
_g = tmp3_2;
tmp10 = omc_FNode_isRefRedeclare(threadData, _r);
if (1 != tmp10) goto goto_1;
tmp11 = ((omc_FNode_isRefClass(threadData, _r) && (!omc_FNode_isRefClassExtends(threadData, _r))) || omc_FNode_isRefComponent(threadData, _r));
if (1 != tmp11) goto goto_1;
_id = omc_SCodeUtil_elementName(threadData, omc_FNode_getElement(threadData, omc_FNode_fromRef(threadData, _r)));
tmpMeta[1] = omc_FNode_parents(threadData, omc_FNode_fromRef(threadData, _r));
if (listEmpty(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
_p = tmpMeta[2];
tmp12 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_FLookup_ext(threadData, _g, _p, _id, _OMC_LIT0, mmc_mk_none(), NULL);
tmp12 = 1;
goto goto_13;
goto_13:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp12) {goto goto_1;}
tmpMeta[1] = stringAppend(_OMC_LIT2,_id);
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT3);
tmpMeta[3] = stringAppend(tmpMeta[2],omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _r)));
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT4);
tmpMeta[5] = stringAppend(tmpMeta[4],omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _p)));
tmpMeta[6] = stringAppend(tmpMeta[5],_OMC_LIT5);
fputs(MMC_STRINGDATA(tmpMeta[6]),stdout);
tmpMeta[1] = stringAppend(_OMC_LIT6,stringDelimitList(omc_List_map(threadData, omc_List_map(threadData, omc_FNode_extendsRefs(threadData, _p), boxvar_FNode_fromRef), boxvar_FNode_toPathStr), _OMC_LIT7));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT8);
fputs(MMC_STRINGDATA(tmpMeta[2]),stdout);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta[1], _r, _g);
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _ig;
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
if (++tmp3 < 4) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_og = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_elred(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _ig;
{
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_g = tmp3_1;
tmpMeta[0] = omc_FNode_apply1(threadData, _inRef, boxvar_FResolve_elred__one, _g);
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
_og = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_mod__one(threadData_t *threadData, modelica_string _name, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inRef;
tmp3_2 = _ig;
{
modelica_metatype _r = NULL;
modelica_metatype _rr = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
modelica_boolean tmp6;
_r = tmp3_1;
_g = tmp3_2;
tmp5 = ((omc_FNode_isRefMod(threadData, _r) && (!omc_FNode_isRefModHolder(threadData, _r))) && (!omc_ClassInf_isBasicTypeComponentName(threadData, omc_FNode_refName(threadData, _r))));
if (1 != tmp5) goto goto_1;
tmp6 = omc_FNode_isRefRefResolved(threadData, _r);
if (1 != tmp6) goto goto_1;
tmpMeta[0] = _g;
goto tmp2_done;
}
case 1: {
modelica_boolean tmp7;
_r = tmp3_1;
_g = tmp3_2;
tmp7 = ((omc_FNode_isRefMod(threadData, _r) && (!omc_FNode_isRefModHolder(threadData, _r))) && (!omc_ClassInf_isBasicTypeComponentName(threadData, omc_FNode_refName(threadData, _r))));
if (1 != tmp7) goto goto_1;
_cr = omc_AbsynUtil_pathToCref(threadData, omc_AbsynUtil_stringListPath(threadData, omc_FNode_namesUpToParentName(threadData, _r, _OMC_LIT9)));
_g = omc_FLookup_cr(threadData, _g, omc_FNode_getModifierTarget(threadData, _r), _cr, _OMC_LIT10, mmc_mk_none() ,&_rr);
tmpMeta[1] = mmc_mk_cons(_rr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta[1], _r, _g);
goto tmp2_done;
}
case 2: {
modelica_boolean tmp8;
modelica_boolean tmp9;
_r = tmp3_1;
_g = tmp3_2;
tmp8 = ((omc_FNode_isRefMod(threadData, _r) && (!omc_FNode_isRefModHolder(threadData, _r))) && (!omc_ClassInf_isBasicTypeComponentName(threadData, omc_FNode_refName(threadData, _r))));
if (1 != tmp8) goto goto_1;
_cr = omc_AbsynUtil_pathToCref(threadData, omc_AbsynUtil_stringListPath(threadData, omc_FNode_namesUpToParentName(threadData, _r, _OMC_LIT9)));
tmp9 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_FLookup_cr(threadData, _g, omc_FNode_getModifierTarget(threadData, _r), _cr, _OMC_LIT10, mmc_mk_none(), NULL);
tmp9 = 1;
goto goto_10;
goto_10:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp9) {goto goto_1;}
tmpMeta[1] = stringAppend(_OMC_LIT11,omc_AbsynUtil_crefString(threadData, _cr));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT12);
tmpMeta[3] = stringAppend(tmpMeta[2],omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _r)));
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT13);
fputs(MMC_STRINGDATA(tmpMeta[4]),stdout);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta[1], _r, _g);
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _ig;
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
if (++tmp3 < 4) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_og = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_mod(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _ig;
{
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_g = tmp3_1;
tmpMeta[0] = omc_FNode_apply1(threadData, _inRef, boxvar_FResolve_mod__one, _g);
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
_og = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_cr__one(threadData_t *threadData, modelica_string _name, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inRef;
tmp3_2 = _ig;
{
modelica_metatype _r = NULL;
modelica_metatype _rr = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
modelica_boolean tmp6;
_r = tmp3_1;
_g = tmp3_2;
tmp5 = omc_FNode_isRefCref(threadData, _r);
if (1 != tmp5) goto goto_1;
tmp6 = omc_FNode_isRefRefResolved(threadData, _r);
if (1 != tmp6) goto goto_1;
tmpMeta[0] = _g;
goto tmp2_done;
}
case 1: {
modelica_boolean tmp7;
_r = tmp3_1;
_g = tmp3_2;
tmp7 = omc_FNode_isRefCref(threadData, _r);
if (1 != tmp7) goto goto_1;
tmpMeta[1] = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],17,1) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_cr = tmpMeta[2];
_g = omc_FLookup_cr(threadData, _g, _r, _cr, _OMC_LIT10, mmc_mk_none() ,&_rr);
tmpMeta[1] = mmc_mk_cons(_rr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta[1], _r, _g);
goto tmp2_done;
}
case 2: {
modelica_boolean tmp8;
modelica_boolean tmp9;
_r = tmp3_1;
_g = tmp3_2;
tmp8 = omc_FNode_isRefCref(threadData, _r);
if (1 != tmp8) goto goto_1;
tmpMeta[1] = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],17,1) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_cr = tmpMeta[2];
tmp9 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_FLookup_cr(threadData, _g, _r, _cr, _OMC_LIT10, mmc_mk_none(), NULL);
tmp9 = 1;
goto goto_10;
goto_10:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp9) {goto goto_1;}
tmpMeta[1] = stringAppend(_OMC_LIT14,omc_AbsynUtil_crefString(threadData, _cr));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT12);
tmpMeta[3] = stringAppend(tmpMeta[2],omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _r)));
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT13);
fputs(MMC_STRINGDATA(tmpMeta[4]),stdout);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta[1], _r, _g);
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _ig;
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
if (++tmp3 < 4) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_og = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_cr(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _ig;
{
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_g = tmp3_1;
tmpMeta[0] = omc_FNode_apply1(threadData, _inRef, boxvar_FResolve_cr__one, _g);
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
_og = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_clsext__one(threadData_t *threadData, modelica_string _name, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inRef;
tmp3_2 = _ig;
{
modelica_metatype _r = NULL;
modelica_metatype _rr = NULL;
modelica_metatype _p = NULL;
modelica_string _id = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
modelica_boolean tmp6;
_r = tmp3_1;
_g = tmp3_2;
tmp5 = omc_FNode_isRefClassExtends(threadData, _r);
if (1 != tmp5) goto goto_1;
tmp6 = omc_FNode_isRefRefResolved(threadData, _r);
if (1 != tmp6) goto goto_1;
tmpMeta[0] = _g;
goto tmp2_done;
}
case 1: {
modelica_boolean tmp7;
_r = tmp3_1;
_g = tmp3_2;
tmp7 = omc_FNode_isRefClassExtends(threadData, _r);
if (1 != tmp7) goto goto_1;
tmpMeta[1] = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,5) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,8) == 0) goto goto_1;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_id = tmpMeta[3];
tmpMeta[1] = omc_FNode_parents(threadData, omc_FNode_fromRef(threadData, _r));
if (listEmpty(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
_p = tmpMeta[2];
_g = omc_FLookup_ext(threadData, _g, _p, _id, _OMC_LIT0, mmc_mk_none() ,&_rr);
tmpMeta[1] = mmc_mk_cons(_rr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta[1], _r, _g);
goto tmp2_done;
}
case 2: {
modelica_boolean tmp8;
modelica_boolean tmp9;
_r = tmp3_1;
_g = tmp3_2;
tmp8 = omc_FNode_isRefClassExtends(threadData, _r);
if (1 != tmp8) goto goto_1;
tmpMeta[1] = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,5) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,8) == 0) goto goto_1;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_id = tmpMeta[3];
tmpMeta[1] = omc_FNode_parents(threadData, omc_FNode_fromRef(threadData, _r));
if (listEmpty(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
_p = tmpMeta[2];
tmp9 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_FLookup_ext(threadData, _g, _p, _id, _OMC_LIT0, mmc_mk_none(), NULL);
tmp9 = 1;
goto goto_10;
goto_10:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp9) {goto goto_1;}
tmpMeta[1] = stringAppend(_OMC_LIT15,_id);
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT3);
tmpMeta[3] = stringAppend(tmpMeta[2],omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _r)));
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT4);
tmpMeta[5] = stringAppend(tmpMeta[4],omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _p)));
tmpMeta[6] = stringAppend(tmpMeta[5],_OMC_LIT5);
fputs(MMC_STRINGDATA(tmpMeta[6]),stdout);
tmpMeta[1] = stringAppend(_OMC_LIT6,stringDelimitList(omc_List_map(threadData, omc_List_map(threadData, omc_FNode_extendsRefs(threadData, _p), boxvar_FNode_fromRef), boxvar_FNode_toPathStr), _OMC_LIT7));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT8);
fputs(MMC_STRINGDATA(tmpMeta[2]),stdout);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta[1], _r, _g);
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _ig;
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
if (++tmp3 < 4) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_og = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_clsext(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _ig;
{
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_g = tmp3_1;
tmpMeta[0] = omc_FNode_apply1(threadData, _inRef, boxvar_FResolve_clsext__one, _g);
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
_og = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_cc__one(threadData_t *threadData, modelica_string _name, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inRef;
tmp3_2 = _ig;
{
modelica_metatype _r = NULL;
modelica_metatype _rr = NULL;
modelica_metatype _p = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
modelica_boolean tmp6;
_r = tmp3_1;
_g = tmp3_2;
tmp5 = omc_FNode_isRefConstrainClass(threadData, _r);
if (1 != tmp5) goto goto_1;
tmp6 = omc_FNode_isRefRefResolved(threadData, _r);
if (1 != tmp6) goto goto_1;
tmpMeta[0] = _g;
goto tmp2_done;
}
case 1: {
modelica_boolean tmp7;
_r = tmp3_1;
_g = tmp3_2;
tmp7 = omc_FNode_isRefConstrainClass(threadData, _r);
if (1 != tmp7) goto goto_1;
tmpMeta[1] = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],19,1) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_p = tmpMeta[3];
_g = omc_FLookup_name(threadData, _g, _r, _p, _OMC_LIT10, mmc_mk_none() ,&_rr);
tmpMeta[1] = mmc_mk_cons(_rr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta[1], _r, _g);
goto tmp2_done;
}
case 2: {
modelica_boolean tmp8;
modelica_boolean tmp9;
_r = tmp3_1;
_g = tmp3_2;
tmp8 = omc_FNode_isRefConstrainClass(threadData, _r);
if (1 != tmp8) goto goto_1;
tmpMeta[1] = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],19,1) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_p = tmpMeta[3];
tmp9 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_FLookup_name(threadData, _g, _r, _p, _OMC_LIT10, mmc_mk_none(), NULL);
tmp9 = 1;
goto goto_10;
goto_10:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp9) {goto goto_1;}
tmpMeta[1] = stringAppend(_OMC_LIT16,omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT17, 1, 0));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT12);
tmpMeta[3] = stringAppend(tmpMeta[2],omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _r)));
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT13);
fputs(MMC_STRINGDATA(tmpMeta[4]),stdout);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta[1], _r, _g);
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _ig;
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
if (++tmp3 < 4) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_og = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_cc(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _ig;
{
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_g = tmp3_1;
tmpMeta[0] = omc_FNode_apply1(threadData, _inRef, boxvar_FResolve_cc__one, _g);
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
_og = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_ty__one(threadData_t *threadData, modelica_string _name, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inRef;
tmp3_2 = _ig;
{
modelica_metatype _r = NULL;
modelica_metatype _rr = NULL;
modelica_metatype _p = NULL;
modelica_metatype _e = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
modelica_boolean tmp6;
_r = tmp3_1;
_g = tmp3_2;
tmp5 = omc_FNode_isRefComponent(threadData, _r);
if (1 != tmp5) goto goto_1;
tmp6 = omc_FNode_isRefRefResolved(threadData, _r);
if (1 != tmp6) goto goto_1;
tmpMeta[0] = _g;
goto tmp2_done;
}
case 1: {
modelica_boolean tmp7;
_r = tmp3_1;
_g = tmp3_2;
tmp7 = omc_FNode_isRefComponent(threadData, _r);
if (1 != tmp7) goto goto_1;
tmpMeta[1] = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],4,4) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_e = tmpMeta[2];
tmpMeta[1] = omc_SCodeUtil_getComponentTypeSpec(threadData, _e);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,2) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_p = tmpMeta[2];
_g = omc_FLookup_name(threadData, _g, _r, _p, _OMC_LIT10, mmc_mk_none() ,&_rr);
tmpMeta[1] = mmc_mk_cons(_rr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta[1], _r, _g);
goto tmp2_done;
}
case 2: {
modelica_boolean tmp8;
modelica_boolean tmp9;
_r = tmp3_1;
_g = tmp3_2;
tmp8 = omc_FNode_isRefComponent(threadData, _r);
if (1 != tmp8) goto goto_1;
tmpMeta[1] = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],4,4) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_e = tmpMeta[2];
tmpMeta[1] = omc_SCodeUtil_getComponentTypeSpec(threadData, _e);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,2) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_p = tmpMeta[2];
tmp9 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_FLookup_name(threadData, _g, _r, _p, _OMC_LIT10, mmc_mk_none(), NULL);
tmp9 = 1;
goto goto_10;
goto_10:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp9) {goto goto_1;}
tmpMeta[1] = stringAppend(_OMC_LIT18,omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT17, 1, 0));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT12);
tmpMeta[3] = stringAppend(tmpMeta[2],omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _r)));
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT13);
fputs(MMC_STRINGDATA(tmpMeta[4]),stdout);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta[1], _r, _g);
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _ig;
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
if (++tmp3 < 4) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_og = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_ty(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _ig;
{
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_g = tmp3_1;
tmpMeta[0] = omc_FNode_apply1(threadData, _inRef, boxvar_FResolve_ty__one, _g);
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
_og = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_derived__one(threadData_t *threadData, modelica_string _name, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inRef;
tmp3_2 = _ig;
{
modelica_metatype _r = NULL;
modelica_metatype _rr = NULL;
modelica_metatype _p = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
modelica_boolean tmp6;
_r = tmp3_1;
_g = tmp3_2;
tmp5 = omc_FNode_isRefDerived(threadData, _r);
if (1 != tmp5) goto goto_1;
tmp6 = omc_FNode_isRefRefResolved(threadData, _r);
if (1 != tmp6) goto goto_1;
tmpMeta[0] = _g;
goto tmp2_done;
}
case 1: {
modelica_boolean tmp7;
_r = tmp3_1;
_g = tmp3_2;
tmp7 = omc_FNode_isRefDerived(threadData, _r);
if (1 != tmp7) goto goto_1;
tmpMeta[1] = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,5) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,8) == 0) goto goto_1;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],2,3) == 0) goto goto_1;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,2) == 0) goto goto_1;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
_p = tmpMeta[5];
_g = omc_FLookup_name(threadData, _g, _r, _p, _OMC_LIT10, mmc_mk_none() ,&_rr);
tmpMeta[1] = mmc_mk_cons(_rr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta[1], _r, _g);
goto tmp2_done;
}
case 2: {
modelica_boolean tmp8;
modelica_boolean tmp9;
_r = tmp3_1;
_g = tmp3_2;
tmp8 = omc_FNode_isRefDerived(threadData, _r);
if (1 != tmp8) goto goto_1;
tmpMeta[1] = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,5) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,8) == 0) goto goto_1;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],2,3) == 0) goto goto_1;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,2) == 0) goto goto_1;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
_p = tmpMeta[5];
tmp9 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_FLookup_name(threadData, _g, _r, _p, _OMC_LIT10, mmc_mk_none(), NULL);
tmp9 = 1;
goto goto_10;
goto_10:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp9) {goto goto_1;}
tmpMeta[1] = stringAppend(_OMC_LIT19,omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT17, 1, 0));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT12);
tmpMeta[3] = stringAppend(tmpMeta[2],omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _r)));
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT13);
fputs(MMC_STRINGDATA(tmpMeta[4]),stdout);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta[1], _r, _g);
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _ig;
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
if (++tmp3 < 4) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_og = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_derived(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _ig;
{
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_g = tmp3_1;
tmpMeta[0] = omc_FNode_apply1(threadData, _inRef, boxvar_FResolve_derived__one, _g);
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
_og = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_ext__one(threadData_t *threadData, modelica_string _name, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inRef;
tmp3_2 = _ig;
{
modelica_metatype _r = NULL;
modelica_metatype _rr = NULL;
modelica_metatype _p = NULL;
modelica_metatype _e = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
modelica_boolean tmp6;
modelica_boolean tmp7;
_r = tmp3_1;
_g = tmp3_2;
tmp5 = omc_FNode_isRefExtends(threadData, _r);
if (1 != tmp5) goto goto_1;
tmp6 = omc_FNode_isRefDerived(threadData, _r);
if (0 != tmp6) goto goto_1;
tmp7 = omc_FNode_isRefRefResolved(threadData, _r);
if (1 != tmp7) goto goto_1;
tmpMeta[0] = _g;
goto tmp2_done;
}
case 1: {
modelica_boolean tmp8;
modelica_boolean tmp9;
_r = tmp3_1;
_g = tmp3_2;
tmp8 = omc_FNode_isRefExtends(threadData, _r);
if (1 != tmp8) goto goto_1;
tmp9 = omc_FNode_isRefDerived(threadData, _r);
if (0 != tmp9) goto goto_1;
tmpMeta[1] = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],5,2) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_e = tmpMeta[2];
_p = omc_SCodeUtil_getBaseClassPath(threadData, _e);
omc_SCodeUtil_elementInfo(threadData, _e);
_g = omc_FLookup_name(threadData, _g, _r, _p, _OMC_LIT10, mmc_mk_none() ,&_rr);
tmpMeta[1] = mmc_mk_cons(_rr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta[1], _r, _g);
goto tmp2_done;
}
case 2: {
modelica_boolean tmp10;
modelica_boolean tmp11;
modelica_boolean tmp12;
_r = tmp3_1;
_g = tmp3_2;
tmp10 = omc_FNode_isRefExtends(threadData, _r);
if (1 != tmp10) goto goto_1;
tmp11 = omc_FNode_isRefDerived(threadData, _r);
if (0 != tmp11) goto goto_1;
tmpMeta[1] = omc_FNode_refData(threadData, _r);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],5,2) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_e = tmpMeta[2];
_p = omc_SCodeUtil_getBaseClassPath(threadData, _e);
omc_SCodeUtil_elementInfo(threadData, _e);
tmp12 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_FLookup_name(threadData, _g, _r, _p, _OMC_LIT10, mmc_mk_none(), NULL);
tmp12 = 1;
goto goto_13;
goto_13:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp12) {goto goto_1;}
tmpMeta[1] = stringAppend(_OMC_LIT20,omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT17, 1, 0));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT12);
tmpMeta[3] = stringAppend(tmpMeta[2],omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _r)));
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT13);
fputs(MMC_STRINGDATA(tmpMeta[4]),stdout);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = omc_FGraphBuild_mkRefNode(threadData, _OMC_LIT1, tmpMeta[1], _r, _g);
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _ig;
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
if (++tmp3 < 4) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_og = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _og;
}
DLLExport
modelica_metatype omc_FResolve_ext(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _ig)
{
modelica_metatype _og = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _ig;
{
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_g = tmp3_1;
tmpMeta[0] = omc_FNode_apply1(threadData, _inRef, boxvar_FResolve_ext__one, _g);
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
_og = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _og;
}
