#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "FLookup.c"
#endif
#include "omc_simulation_settings.h"
#include "FLookup.h"
#define _OMC_LIT0_data "$ref"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,4,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,4,3) {&FLookup_Options_OPTIONS__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1))}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "missing: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,9,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data " in scope: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,11,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "FLookup.cr failed for: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,23,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data " in: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,5,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,1,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,4,3) {&FLookup_Options_OPTIONS__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT8,4,3) {&FLookup_Options_OPTIONS__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1))}};
#define _OMC_LIT8 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,1,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "FLookup.name failed for: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,25,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "FLookup.search failed for: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,27,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "$for"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,4,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "FLookup.id failed for: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,23,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#include "util/modelica.h"
#include "FLookup_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FLookup_imp__qual(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inRef, modelica_string _inName, modelica_metatype _inImports, modelica_metatype _inOptions, modelica_metatype _inMsg, modelica_metatype *out_outRef);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FLookup_imp__qual,2,0) {(void*) boxptr_FLookup_imp__qual,0}};
#define boxvar_FLookup_imp__qual MMC_REFSTRUCTLIT(boxvar_lit_FLookup_imp__qual)
DLLExport
modelica_metatype omc_FLookup_cr(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inRef, modelica_metatype _inCref, modelica_metatype _inOptions, modelica_metatype _inMsg, modelica_metatype *out_outRef)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _outRef = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inGraph;
tmp4_2 = _inCref;
tmp4_3 = _inMsg;
{
modelica_metatype _r = NULL;
modelica_string _i = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _g = NULL;
modelica_string _s = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_i = tmpMeta6;
_g = tmp4_1;
tmp4 += 4;
tmpMeta[0+0] = omc_FLookup_id(threadData, _g, _inRef, _i, _inOptions, _inMsg, &tmpMeta[0+1]);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_boolean tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_i = tmpMeta7;
_rest = tmpMeta8;
_g = tmp4_1;
_g = omc_FLookup_id(threadData, _g, _inRef, _i, _inOptions, _inMsg ,&_r);
tmp9 = omc_FNode_isRefComponent(threadData, _r);
if (1 != tmp9) goto goto_2;
_r = omc_FNode_child(threadData, _r, _OMC_LIT0);
_r = omc_FNode_target(threadData, omc_FNode_fromRef(threadData, _r));
tmpMeta[0+0] = omc_FLookup_cr(threadData, _g, _r, _rest, _OMC_LIT1, _inMsg, &tmpMeta[0+1]);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_boolean tmp12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_i = tmpMeta10;
_rest = tmpMeta11;
_g = tmp4_1;
_g = omc_FLookup_id(threadData, _g, _inRef, _i, _inOptions, _inMsg ,&_r);
tmp12 = omc_FNode_isRefClass(threadData, _r);
if (1 != tmp12) goto goto_2;
tmpMeta[0+0] = omc_FLookup_cr(threadData, _g, _r, _rest, _OMC_LIT1, _inMsg, &tmpMeta[0+1]);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_boolean tmp15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_i = tmpMeta13;
_rest = tmpMeta14;
_g = tmp4_1;
tmp4 += 1;
_g = omc_FLookup_id(threadData, _g, _inRef, _i, _inOptions, _inMsg ,&_r);
tmp15 = (omc_FNode_isRefClass(threadData, _r) || omc_FNode_isRefComponent(threadData, _r));
if (1 != tmp15) goto goto_2;
tmpMeta16 = stringAppend(_OMC_LIT2,omc_AbsynUtil_crefString(threadData, _rest));
tmpMeta17 = stringAppend(tmpMeta16,_OMC_LIT3);
tmpMeta18 = stringAppend(tmpMeta17,omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _r)));
_s = tmpMeta18;
tmpMeta[0+0] = omc_FGraphBuild_mkAssertNode(threadData, omc_AbsynUtil_crefFirstIdent(threadData, _rest), _s, _r, _g, &tmpMeta[0+1]);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_rest = tmpMeta19;
_g = tmp4_1;
_r = omc_FGraph_top(threadData, _g);
tmpMeta[0+0] = omc_FLookup_cr(threadData, _g, _r, _rest, _inOptions, _inMsg, &tmpMeta[0+1]);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
if (optionNone(tmp4_3)) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 1));
tmpMeta21 = stringAppend(_OMC_LIT4,omc_AbsynUtil_crefString(threadData, _inCref));
tmpMeta22 = stringAppend(tmpMeta21,_OMC_LIT5);
tmpMeta23 = stringAppend(tmpMeta22,omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _inRef)));
tmpMeta24 = stringAppend(tmpMeta23,_OMC_LIT6);
fputs(MMC_STRINGDATA(tmpMeta24),stdout);
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
_outGraph = tmpMeta[0+0];
_outRef = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outRef) { *out_outRef = _outRef; }
return _outGraph;
}
DLLExport
modelica_metatype omc_FLookup_fq(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inName, modelica_metatype _inOptions, modelica_metatype _inMsg, modelica_metatype *out_outRef)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _outRef = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outGraph = omc_FLookup_name(threadData, _inGraph, omc_FGraph_top(threadData, _inGraph), _inName, _inOptions, _inMsg ,&_outRef);
_return: OMC_LABEL_UNUSED
if (out_outRef) { *out_outRef = _outRef; }
return _outGraph;
}
DLLExport
modelica_metatype omc_FLookup_imp__unqual(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inRef, modelica_string _inName, modelica_metatype _inImports, modelica_metatype _inOptions, modelica_metatype _inMsg, modelica_metatype *out_outRef)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _outRef = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inGraph;
tmp4_2 = _inImports;
{
modelica_metatype _path = NULL;
modelica_metatype _rest_imps = NULL;
modelica_metatype _r = NULL;
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
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,2,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_path = tmpMeta8;
_g = tmp4_1;
_g = omc_FLookup_fq(threadData, _g, _path, _inOptions, _inMsg ,&_r);
tmpMeta[0+0] = omc_FLookup_id(threadData, _g, _r, _inName, _OMC_LIT1, _inMsg, &tmpMeta[0+1]);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmp4_2);
tmpMeta10 = MMC_CDR(tmp4_2);
_rest_imps = tmpMeta10;
_g = tmp4_1;
tmpMeta[0+0] = omc_FLookup_imp__unqual(threadData, _g, _inRef, _inName, _rest_imps, _inOptions, _inMsg, &tmpMeta[0+1]);
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
_outGraph = tmpMeta[0+0];
_outRef = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outRef) { *out_outRef = _outRef; }
return _outGraph;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FLookup_imp__qual(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inRef, modelica_string _inName, modelica_metatype _inImports, modelica_metatype _inOptions, modelica_metatype _inMsg, modelica_metatype *out_outRef)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _outRef = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inGraph;
tmp4_2 = _inImports;
{
modelica_string _name = NULL;
modelica_metatype _path = NULL;
modelica_metatype _rest_imps = NULL;
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
modelica_boolean tmp9;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_name = tmpMeta8;
_rest_imps = tmpMeta7;
_g = tmp4_1;
tmp9 = (stringEqual(_inName, _name));
if (0 != tmp9) goto goto_2;
tmpMeta[0+0] = omc_FLookup_imp__qual(threadData, _g, _inRef, _inName, _rest_imps, _inOptions, _inMsg, &tmpMeta[0+1]);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_boolean tmp14;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_2);
tmpMeta11 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,0,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 3));
_name = tmpMeta12;
_path = tmpMeta13;
_g = tmp4_1;
tmp14 = (stringEqual(_inName, _name));
if (1 != tmp14) goto goto_2;
tmpMeta[0+0] = omc_FLookup_fq(threadData, _g, _path, _inOptions, _inMsg, &tmpMeta[0+1]);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_boolean tmp18;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta15 = MMC_CAR(tmp4_2);
tmpMeta16 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,0,2) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
_name = tmpMeta17;
tmp18 = (stringEqual(_inName, _name));
if (1 != tmp18) goto goto_2;
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
_outGraph = tmpMeta[0+0];
_outRef = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outRef) { *out_outRef = _outRef; }
return _outGraph;
}
DLLExport
modelica_metatype omc_FLookup_imp(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inRef, modelica_string _inName, modelica_metatype _inOptions, modelica_metatype _inMsg, modelica_metatype *out_outRef)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _outRef = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
{
modelica_metatype _qi = NULL;
modelica_metatype _uqi = NULL;
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
modelica_boolean tmp6;
_g = tmp4_1;
tmp6 = omc_FNode_hasImports(threadData, omc_FNode_fromRef(threadData, _inRef));
if (1 != tmp6) goto goto_2;
_qi = omc_FNode_imports(threadData, omc_FNode_fromRef(threadData, _inRef), NULL);
tmpMeta[0+0] = omc_FLookup_imp__qual(threadData, _g, _inRef, _inName, _qi, _inOptions, _inMsg, &tmpMeta[0+1]);
goto tmp3_done;
}
case 1: {
modelica_boolean tmp7;
_g = tmp4_1;
tmp7 = omc_FNode_hasImports(threadData, omc_FNode_fromRef(threadData, _inRef));
if (1 != tmp7) goto goto_2;
omc_FNode_imports(threadData, omc_FNode_fromRef(threadData, _inRef) ,&_uqi);
tmpMeta[0+0] = omc_FLookup_imp__unqual(threadData, _g, _inRef, _inName, _uqi, _inOptions, _inMsg, &tmpMeta[0+1]);
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
_outGraph = tmpMeta[0+0];
_outRef = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outRef) { *out_outRef = _outRef; }
return _outGraph;
}
DLLExport
modelica_metatype omc_FLookup_ext(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inRef, modelica_string _inName, modelica_metatype _inOptions, modelica_metatype _inMsg, modelica_metatype *out_outRef)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _outRef = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
{
modelica_metatype _r = NULL;
modelica_metatype _refs = NULL;
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
modelica_boolean tmp6;
_g = tmp4_1;
tmp6 = omc_FNode_isClassExtends(threadData, omc_FNode_fromRef(threadData, _inRef));
if (1 != tmp6) goto goto_2;
_r = omc_FNode_child(threadData, _inRef, _OMC_LIT0);
_r = omc_FNode_target(threadData, omc_FNode_fromRef(threadData, _r));
tmpMeta[0+0] = omc_FLookup_id(threadData, _g, _r, _inName, _OMC_LIT1, _inMsg, &tmpMeta[0+1]);
goto tmp3_done;
}
case 1: {
modelica_boolean tmp7;
_g = tmp4_1;
tmp7 = omc_FNode_isClassExtends(threadData, omc_FNode_fromRef(threadData, _inRef));
if (1 != tmp7) goto goto_2;
_r = omc_FNode_original(threadData, omc_FNode_parents(threadData, omc_FNode_fromRef(threadData, _inRef)));
tmpMeta[0+0] = omc_FLookup_id(threadData, _g, _r, _inName, _OMC_LIT7, _inMsg, &tmpMeta[0+1]);
goto tmp3_done;
}
case 2: {
modelica_boolean tmp8;
_g = tmp4_1;
_refs = omc_FNode_extendsRefs(threadData, _inRef);
tmp8 = listEmpty(_refs);
if (0 != tmp8) goto goto_2;
_refs = omc_List_mapMap(threadData, _refs, boxvar_FNode_fromRef, boxvar_FNode_target);
tmpMeta[0+0] = omc_FLookup_search(threadData, _g, _refs, _inName, _OMC_LIT8, _inMsg, &tmpMeta[0+1]);
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
_outGraph = tmpMeta[0+0];
_outRef = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outRef) { *out_outRef = _outRef; }
return _outGraph;
}
DLLExport
modelica_metatype omc_FLookup_name(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inRef, modelica_metatype _inPath, modelica_metatype _inOptions, modelica_metatype _inMsg, modelica_metatype *out_outRef)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _outRef = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inGraph;
tmp4_2 = _inPath;
tmp4_3 = _inMsg;
{
modelica_metatype _r = NULL;
modelica_string _i = NULL;
modelica_metatype _rest = NULL;
modelica_string _s = NULL;
modelica_metatype _g = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_i = tmpMeta6;
_g = tmp4_1;
tmp4 += 3;
tmpMeta[0+0] = omc_FLookup_id(threadData, _g, _inRef, _i, _inOptions, _inMsg, &tmpMeta[0+1]);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_i = tmpMeta7;
_rest = tmpMeta8;
_g = tmp4_1;
_g = omc_FLookup_id(threadData, _g, _inRef, _i, _inOptions, _inMsg ,&_r);
tmpMeta[0+0] = omc_FLookup_name(threadData, _g, _r, _rest, _inOptions, _inMsg, &tmpMeta[0+1]);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_boolean tmp11;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_i = tmpMeta9;
_rest = tmpMeta10;
_g = tmp4_1;
tmp4 += 1;
_g = omc_FLookup_id(threadData, _g, _inRef, _i, _inOptions, _inMsg ,&_r);
tmp11 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_FLookup_name(threadData, _g, _r, _rest, _inOptions, _inMsg, NULL);
tmp11 = 1;
goto goto_12;
goto_12:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp11) {goto goto_2;}
tmpMeta13 = stringAppend(_OMC_LIT2,omc_AbsynUtil_pathString(threadData, _rest, _OMC_LIT9, 1, 0));
tmpMeta14 = stringAppend(tmpMeta13,_OMC_LIT3);
tmpMeta15 = stringAppend(tmpMeta14,omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _r)));
_s = tmpMeta15;
tmpMeta[0+0] = omc_FGraphBuild_mkAssertNode(threadData, omc_AbsynUtil_pathFirstIdent(threadData, _rest), _s, _r, _g, &tmpMeta[0+1]);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_rest = tmpMeta16;
_g = tmp4_1;
_r = omc_FNode_top(threadData, _inRef);
tmpMeta[0+0] = omc_FLookup_name(threadData, _g, _r, _rest, _inOptions, _inMsg, &tmpMeta[0+1]);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
if (optionNone(tmp4_3)) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 1));
tmpMeta18 = stringAppend(_OMC_LIT10,omc_AbsynUtil_pathString(threadData, _inPath, _OMC_LIT9, 1, 0));
tmpMeta19 = stringAppend(tmpMeta18,_OMC_LIT5);
tmpMeta20 = stringAppend(tmpMeta19,omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _inRef)));
tmpMeta21 = stringAppend(tmpMeta20,_OMC_LIT6);
fputs(MMC_STRINGDATA(tmpMeta21),stdout);
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
if (++tmp4 < 5) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outGraph = tmpMeta[0+0];
_outRef = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outRef) { *out_outRef = _outRef; }
return _outGraph;
}
DLLExport
modelica_metatype omc_FLookup_search(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inRefs, modelica_string _inName, modelica_metatype _inOptions, modelica_metatype _inMsg, modelica_metatype *out_outRef)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _outRef = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inGraph;
tmp4_2 = _inRefs;
tmp4_3 = _inMsg;
{
modelica_metatype _r = NULL;
modelica_metatype _rest = NULL;
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
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
_r = tmpMeta6;
_g = tmp4_1;
tmpMeta[0+0] = omc_FLookup_id(threadData, _g, _r, _inName, _inOptions, _inMsg, &tmpMeta[0+1]);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_2);
tmpMeta9 = MMC_CDR(tmp4_2);
_rest = tmpMeta9;
_g = tmp4_1;
tmpMeta[0+0] = omc_FLookup_search(threadData, _g, _rest, _inName, _inOptions, _inMsg, &tmpMeta[0+1]);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (optionNone(tmp4_3)) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 1));
tmpMeta11 = stringAppend(_OMC_LIT11,_inName);
tmpMeta12 = stringAppend(tmpMeta11,_OMC_LIT5);
tmpMeta13 = stringAppend(tmpMeta12,omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, listHead(_inRefs))));
tmpMeta14 = stringAppend(tmpMeta13,_OMC_LIT6);
fputs(MMC_STRINGDATA(tmpMeta14),stdout);
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
_outGraph = tmpMeta[0+0];
_outRef = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outRef) { *out_outRef = _outRef; }
return _outGraph;
}
DLLExport
modelica_metatype omc_FLookup_id(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inRef, modelica_string _inName, modelica_metatype _inOptions, modelica_metatype _inMsg, modelica_metatype *out_outRef)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _outRef = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inGraph;
tmp4_2 = _inOptions;
tmp4_3 = _inMsg;
{
modelica_metatype _r = NULL;
modelica_metatype _p = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 9; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_g = tmp4_1;
_r = omc_FNode_child(threadData, _inRef, _OMC_LIT12);
_r = omc_FNode_child(threadData, _r, _inName);
tmpMeta[0+0] = _g;
tmpMeta[0+1] = _r;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_boolean tmp8;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmp7 = mmc_unbox_integer(tmpMeta6);
if (0 != tmp7) goto tmp3_end;
_g = tmp4_1;
tmp8 = omc_FNode_isRefImplicitScope(threadData, _inRef);
if (1 != tmp8) goto goto_2;
_p = omc_FNode_parents(threadData, omc_FNode_fromRef(threadData, _inRef));
_r = omc_FNode_original(threadData, _p);
tmpMeta[0+0] = omc_FLookup_id(threadData, _g, _r, _inName, _inOptions, _inMsg, &tmpMeta[0+1]);
goto tmp3_done;
}
case 2: {
modelica_boolean tmp9;
_g = tmp4_1;
tmp9 = omc_FNode_isRefImplicitScope(threadData, _inRef);
if (0 != tmp9) goto goto_2;
_r = omc_FNode_child(threadData, _inRef, _inName);
tmpMeta[0+0] = _g;
tmpMeta[0+1] = _r;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta10;
modelica_integer tmp11;
modelica_boolean tmp12;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp11 = mmc_unbox_integer(tmpMeta10);
if (0 != tmp11) goto tmp3_end;
_g = tmp4_1;
tmp12 = omc_FNode_isRefImplicitScope(threadData, _inRef);
if (0 != tmp12) goto goto_2;
tmpMeta[0+0] = omc_FLookup_imp(threadData, _g, _inRef, _inName, _inOptions, _inMsg, &tmpMeta[0+1]);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta13;
modelica_integer tmp14;
modelica_boolean tmp15;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp14 = mmc_unbox_integer(tmpMeta13);
if (0 != tmp14) goto tmp3_end;
_g = tmp4_1;
tmp15 = omc_FNode_isRefImplicitScope(threadData, _inRef);
if (0 != tmp15) goto goto_2;
tmpMeta[0+0] = omc_FLookup_ext(threadData, _g, _inRef, _inName, _inOptions, _inMsg, &tmpMeta[0+1]);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta16;
modelica_integer tmp17;
modelica_boolean tmp18;
modelica_boolean tmp19;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmp17 = mmc_unbox_integer(tmpMeta16);
if (0 != tmp17) goto tmp3_end;
_g = tmp4_1;
tmp18 = omc_FNode_isRefImplicitScope(threadData, _inRef);
if (0 != tmp18) goto goto_2;
tmp19 = omc_FNode_isEncapsulated(threadData, omc_FNode_fromRef(threadData, _inRef));
if (1 != tmp19) goto goto_2;
_r = omc_FNode_top(threadData, _inRef);
tmpMeta[0+0] = omc_FLookup_id(threadData, _g, _r, _inName, _inOptions, _inMsg, &tmpMeta[0+1]);
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta20;
modelica_integer tmp21;
modelica_boolean tmp22;
modelica_boolean tmp23;
modelica_boolean tmp24;
modelica_metatype tmpMeta25;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmp21 = mmc_unbox_integer(tmpMeta20);
if (0 != tmp21) goto tmp3_end;
_g = tmp4_1;
tmp22 = omc_FNode_isRefImplicitScope(threadData, _inRef);
if (0 != tmp22) goto goto_2;
tmp23 = omc_FNode_isEncapsulated(threadData, omc_FNode_fromRef(threadData, _inRef));
if (0 != tmp23) goto goto_2;
tmp24 = omc_FNode_hasParents(threadData, omc_FNode_fromRef(threadData, _inRef));
if (1 != tmp24) goto goto_2;
_p = omc_FNode_parents(threadData, omc_FNode_fromRef(threadData, _inRef));
_r = omc_FNode_original(threadData, _p);
tmpMeta25 = mmc_mk_cons(_r, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = omc_FLookup_search(threadData, _g, tmpMeta25, _inName, _inOptions, _inMsg, &tmpMeta[0+1]);
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta26;
modelica_integer tmp27;
modelica_boolean tmp28;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmp27 = mmc_unbox_integer(tmpMeta26);
if (0 != tmp27) goto tmp3_end;
tmp28 = omc_FNode_hasParents(threadData, omc_FNode_fromRef(threadData, _inRef));
if (0 != tmp28) goto goto_2;
goto goto_2;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
if (optionNone(tmp4_3)) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 1));
tmpMeta30 = stringAppend(_OMC_LIT13,_inName);
tmpMeta31 = stringAppend(tmpMeta30,_OMC_LIT5);
tmpMeta32 = stringAppend(tmpMeta31,omc_FNode_toPathStr(threadData, omc_FNode_fromRef(threadData, _inRef)));
tmpMeta33 = stringAppend(tmpMeta32,_OMC_LIT6);
fputs(MMC_STRINGDATA(tmpMeta33),stdout);
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
_outGraph = tmpMeta[0+0];
_outRef = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outRef) { *out_outRef = _outRef; }
return _outGraph;
}
