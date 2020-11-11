#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/MMath.c"
#endif
#include "omc_simulation_settings.h"
#include "MMath.h"
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT0,3,3) {&MMath_Rational_RATIONAL__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(2))}};
#define _OMC_LIT0 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,3,3) {&MMath_Rational_RATIONAL__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(2)),MMC_IMMEDIATE(MMC_TAGFIXNUM(3))}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT2,3,3) {&MMath_Rational_RATIONAL__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(3)),MMC_IMMEDIATE(MMC_TAGFIXNUM(2))}};
#define _OMC_LIT2 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,3,3) {&MMath_Rational_RATIONAL__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(6))}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,3,3) {&MMath_Rational_RATIONAL__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(4)),MMC_IMMEDIATE(MMC_TAGFIXNUM(2))}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,3,3) {&MMath_Rational_RATIONAL__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1))}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,3,3) {&MMath_Rational_RATIONAL__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(3))}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "testRational succeeded\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,23,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "testRationals failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,21,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "/"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,1,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,3,3) {&MMath_Rational_RATIONAL__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1))}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
#include "util/modelica.h"
#include "MMath_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MMath_normalizeZero(threadData_t *threadData, modelica_metatype _r);
static const MMC_DEFSTRUCTLIT(boxvar_lit_MMath_normalizeZero,2,0) {(void*) boxptr_MMath_normalizeZero,0}};
#define boxvar_MMath_normalizeZero MMC_REFSTRUCTLIT(boxvar_lit_MMath_normalizeZero)
DLLExport
void omc_MMath_testRational(threadData_t *threadData)
{
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
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
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer tmp7;
modelica_integer tmp8;
modelica_integer tmp9;
modelica_integer tmp10;
modelica_integer tmp11;
modelica_integer tmp12;
modelica_integer tmp13;
modelica_integer tmp14;
modelica_integer tmp15;
modelica_integer tmp16;
modelica_integer tmp17;
modelica_integer tmp18;
tmpMeta[0] = omc_MMath_addRational(threadData, _OMC_LIT0, _OMC_LIT1);
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
if (7 != tmp5) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
if (6 != tmp6) goto goto_1;
tmpMeta[0] = omc_MMath_addRational(threadData, _OMC_LIT0, _OMC_LIT2);
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp7 = mmc_unbox_integer(tmpMeta[1]);
if (2 != tmp7) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmp8 = mmc_unbox_integer(tmpMeta[2]);
if (1 != tmp8) goto goto_1;
tmpMeta[0] = omc_MMath_subRational(threadData, _OMC_LIT2, _OMC_LIT0);
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp9 = mmc_unbox_integer(tmpMeta[1]);
if (1 != tmp9) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmp10 = mmc_unbox_integer(tmpMeta[2]);
if (1 != tmp10) goto goto_1;
tmpMeta[0] = omc_MMath_subRational(threadData, _OMC_LIT0, _OMC_LIT3);
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp11 = mmc_unbox_integer(tmpMeta[1]);
if (1 != tmp11) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmp12 = mmc_unbox_integer(tmpMeta[2]);
if (3 != tmp12) goto goto_1;
tmpMeta[0] = omc_MMath_multRational(threadData, _OMC_LIT1, _OMC_LIT4);
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp13 = mmc_unbox_integer(tmpMeta[1]);
if (4 != tmp13) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmp14 = mmc_unbox_integer(tmpMeta[2]);
if (3 != tmp14) goto goto_1;
tmpMeta[0] = omc_MMath_multRational(threadData, _OMC_LIT5, _OMC_LIT5);
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp15 = mmc_unbox_integer(tmpMeta[1]);
if (1 != tmp15) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmp16 = mmc_unbox_integer(tmpMeta[2]);
if (1 != tmp16) goto goto_1;
tmpMeta[0] = omc_MMath_divRational(threadData, _OMC_LIT6, _OMC_LIT1);
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp17 = mmc_unbox_integer(tmpMeta[1]);
if (1 != tmp17) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmp18 = mmc_unbox_integer(tmpMeta[2]);
if (2 != tmp18) goto goto_1;
fputs(MMC_STRINGDATA(_OMC_LIT7),stdout);
goto tmp2_done;
}
case 1: {
fputs(MMC_STRINGDATA(_OMC_LIT8),stdout);
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
modelica_integer omc_MMath_intGcd(threadData_t *threadData, modelica_integer _i1, modelica_integer _i2)
{
modelica_integer _i;
modelica_integer tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_integer tmp4_1;
tmp4_1 = _i2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (0 != tmp4_1) goto tmp3_end;
tmp1 = _i1;
goto tmp3_done;
}
case 1: {
modelica_integer tmp6;
tmp6 = _i2;
_i2 = modelica_integer_mod(_i1, _i2);
_i1 = tmp6;
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
_i = tmp1;
_return: OMC_LABEL_UNUSED
return _i;
}
modelica_metatype boxptr_MMath_intGcd(threadData_t *threadData, modelica_metatype _i1, modelica_metatype _i2)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer _i;
modelica_metatype out_i;
tmp1 = mmc_unbox_integer(_i1);
tmp2 = mmc_unbox_integer(_i2);
_i = omc_MMath_intGcd(threadData, tmp1, tmp2);
out_i = mmc_mk_icon(_i);
return out_i;
}
DLLExport
modelica_metatype omc_MMath_divRational(threadData_t *threadData, modelica_metatype _r1, modelica_metatype _r2)
{
modelica_metatype _r = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _r1;
tmp3_2 = _r2;
{
modelica_integer _i1;
modelica_integer _i2;
modelica_integer _i3;
modelica_integer _i4;
modelica_integer _ri1;
modelica_integer _ri2;
modelica_integer _d;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer tmp7;
modelica_integer tmp8;
modelica_integer tmp9;
modelica_integer tmp10;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp7 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmp8 = mmc_unbox_integer(tmpMeta[4]);
_i1 = tmp5;
_i2 = tmp6;
_i3 = tmp7;
_i4 = tmp8;
_ri1 = (_i1) * (_i4);
_ri2 = (_i3) * (_i2);
_d = omc_MMath_intGcd(threadData, _ri1, _ri2);
tmp9 = _d;
if (tmp9 == 0) {goto goto_1;}
_ri1 = ldiv(_ri1,tmp9).quot;
tmp10 = _d;
if (tmp10 == 0) {goto goto_1;}
_ri2 = ldiv(_ri2,tmp10).quot;
tmpMeta[1] = mmc_mk_box3(3, &MMath_Rational_RATIONAL__desc, mmc_mk_integer(_ri1), mmc_mk_integer(_ri2));
tmpMeta[0] = omc_MMath_normalizeZero(threadData, tmpMeta[1]);
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
_r = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _r;
}
DLLExport
modelica_metatype omc_MMath_multRational(threadData_t *threadData, modelica_metatype _r1, modelica_metatype _r2)
{
modelica_metatype _r = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _r1;
tmp3_2 = _r2;
{
modelica_integer _i1;
modelica_integer _i2;
modelica_integer _i3;
modelica_integer _i4;
modelica_integer _ri1;
modelica_integer _ri2;
modelica_integer _d;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer tmp7;
modelica_integer tmp8;
modelica_integer tmp9;
modelica_integer tmp10;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp7 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmp8 = mmc_unbox_integer(tmpMeta[4]);
_i1 = tmp5;
_i2 = tmp6;
_i3 = tmp7;
_i4 = tmp8;
_ri1 = (_i1) * (_i3);
_ri2 = (_i2) * (_i4);
_d = omc_MMath_intGcd(threadData, _ri1, _ri2);
tmp9 = _d;
if (tmp9 == 0) {goto goto_1;}
_ri1 = ldiv(_ri1,tmp9).quot;
tmp10 = _d;
if (tmp10 == 0) {goto goto_1;}
_ri2 = ldiv(_ri2,tmp10).quot;
tmpMeta[1] = mmc_mk_box3(3, &MMath_Rational_RATIONAL__desc, mmc_mk_integer(_ri1), mmc_mk_integer(_ri2));
tmpMeta[0] = omc_MMath_normalizeZero(threadData, tmpMeta[1]);
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
_r = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _r;
}
DLLExport
modelica_metatype omc_MMath_subRational(threadData_t *threadData, modelica_metatype _r1, modelica_metatype _r2)
{
modelica_metatype _r = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _r1;
tmp3_2 = _r2;
{
modelica_integer _i1;
modelica_integer _i2;
modelica_integer _i3;
modelica_integer _i4;
modelica_integer _ri1;
modelica_integer _ri2;
modelica_integer _d;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer tmp7;
modelica_integer tmp8;
modelica_integer tmp9;
modelica_integer tmp10;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp7 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmp8 = mmc_unbox_integer(tmpMeta[4]);
_i1 = tmp5;
_i2 = tmp6;
_i3 = tmp7;
_i4 = tmp8;
_ri1 = (_i1) * (_i4) - ((_i3) * (_i2));
_ri2 = (_i2) * (_i4);
_d = omc_MMath_intGcd(threadData, _ri1, _ri2);
tmp9 = _d;
if (tmp9 == 0) {goto goto_1;}
_ri1 = ldiv(_ri1,tmp9).quot;
tmp10 = _d;
if (tmp10 == 0) {goto goto_1;}
_ri2 = ldiv(_ri2,tmp10).quot;
tmpMeta[1] = mmc_mk_box3(3, &MMath_Rational_RATIONAL__desc, mmc_mk_integer(_ri1), mmc_mk_integer(_ri2));
tmpMeta[0] = omc_MMath_normalizeZero(threadData, tmpMeta[1]);
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
_r = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _r;
}
DLLExport
modelica_boolean omc_MMath_equals(threadData_t *threadData, modelica_metatype _r1, modelica_metatype _r2)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _r1;
tmp4_2 = _r2;
{
modelica_integer _i1;
modelica_integer _i2;
modelica_integer _i3;
modelica_integer _i4;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_integer tmp6;
modelica_integer tmp7;
modelica_integer tmp8;
modelica_integer tmp9;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp6 = mmc_unbox_integer(tmpMeta[0]);
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp7 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp8 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp9 = mmc_unbox_integer(tmpMeta[3]);
_i1 = tmp6;
_i2 = tmp7;
_i3 = tmp8;
_i4 = tmp9;
tmp1 = ((_i1) * (_i4) - ((_i3) * (_i2)) == ((modelica_integer) 0));
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_MMath_equals(threadData_t *threadData, modelica_metatype _r1, modelica_metatype _r2)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_MMath_equals(threadData, _r1, _r2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_string omc_MMath_rationalString(threadData_t *threadData, modelica_metatype _r)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _r;
{
modelica_integer _n;
modelica_integer _d;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_integer tmp6;
modelica_integer tmp7;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp6 = mmc_unbox_integer(tmpMeta[0]);
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp7 = mmc_unbox_integer(tmpMeta[1]);
_n = tmp6;
_d = tmp7;
tmpMeta[0] = stringAppend(intString(_n),_OMC_LIT9);
tmpMeta[1] = stringAppend(tmpMeta[0],intString(_d));
tmp1 = tmpMeta[1];
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
_str = tmp1;
_return: OMC_LABEL_UNUSED
return _str;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MMath_normalizeZero(threadData_t *threadData, modelica_metatype _r)
{
modelica_metatype _outR = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _r;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
if (0 != tmp5) goto tmp2_end;
tmpMeta[0] = _OMC_LIT10;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _r;
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
_outR = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outR;
}
DLLExport
modelica_metatype omc_MMath_addRational(threadData_t *threadData, modelica_metatype _r1, modelica_metatype _r2)
{
modelica_metatype _r = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _r1;
tmp3_2 = _r2;
{
modelica_integer _i1;
modelica_integer _i2;
modelica_integer _i3;
modelica_integer _i4;
modelica_integer _ri1;
modelica_integer _ri2;
modelica_integer _d;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer tmp7;
modelica_integer tmp8;
modelica_integer tmp9;
modelica_integer tmp10;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp7 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmp8 = mmc_unbox_integer(tmpMeta[4]);
_i1 = tmp5;
_i2 = tmp6;
_i3 = tmp7;
_i4 = tmp8;
_ri1 = (_i1) * (_i4) + (_i3) * (_i2);
_ri2 = (_i2) * (_i4);
_d = omc_MMath_intGcd(threadData, _ri1, _ri2);
tmp9 = _d;
if (tmp9 == 0) {goto goto_1;}
_ri1 = ldiv(_ri1,tmp9).quot;
tmp10 = _d;
if (tmp10 == 0) {goto goto_1;}
_ri2 = ldiv(_ri2,tmp10).quot;
tmpMeta[1] = mmc_mk_box3(3, &MMath_Rational_RATIONAL__desc, mmc_mk_integer(_ri1), mmc_mk_integer(_ri2));
tmpMeta[0] = omc_MMath_normalizeZero(threadData, tmpMeta[1]);
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
_r = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _r;
}
DLLExport
modelica_boolean omc_MMath_isGreaterThan(threadData_t *threadData, modelica_metatype _r1, modelica_metatype _r2)
{
modelica_boolean _b;
modelica_real tmp1;
modelica_real tmp2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmp1 = ((modelica_real)mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_r1), 3)))));
if (tmp1 == 0) {MMC_THROW_INTERNAL();}
tmp2 = ((modelica_real)mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_r2), 3)))));
if (tmp2 == 0) {MMC_THROW_INTERNAL();}
_b = ((((modelica_real)mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_r1), 2)))))) / tmp1 > (((modelica_real)mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_r2), 2)))))) / tmp2);
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_MMath_isGreaterThan(threadData_t *threadData, modelica_metatype _r1, modelica_metatype _r2)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_MMath_isGreaterThan(threadData, _r1, _r2);
out_b = mmc_mk_icon(_b);
return out_b;
}
