#include "omc_simulation_settings.h"
#include "InstBasics.h"
#define _OMC_LIT0_data "__OpenModelica_Impure"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,21,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "__ModelicaAssociation_Impure"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,28,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "GenerateEvents"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,14,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,1,6) {&DAE_InlineType_DEFAULT__INLINE__desc,}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,1,3) {&DAE_InlineType_NORM__INLINE__desc,}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,1,7) {&DAE_InlineType_NO__INLINE__desc,}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,1,8) {&DAE_InlineType_AFTER__INDEX__RED__INLINE__desc,}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,1,5) {&DAE_InlineType_EARLY__INLINE__desc,}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "Inline"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,6,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "LateInline"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,10,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "__MathCore_InlineAfterIndexReduction"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,36,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "__Dymola_InlineAfterIndexReduction"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,34,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "InlineAfterIndexReduction"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,25,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "__OpenModelica_EarlyInline"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,26,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#include "util/modelica.h"
#include "InstBasics_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_boolean omc_InstBasics_commentGenerateEvents_commentGenerateEvents2(threadData_t *threadData, modelica_metatype _inSubModList);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstBasics_commentGenerateEvents_commentGenerateEvents2(threadData_t *threadData, modelica_metatype _inSubModList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstBasics_commentGenerateEvents_commentGenerateEvents2,2,0) {(void*) boxptr_InstBasics_commentGenerateEvents_commentGenerateEvents2,0}};
#define boxvar_InstBasics_commentGenerateEvents_commentGenerateEvents2 MMC_REFSTRUCTLIT(boxvar_lit_InstBasics_commentGenerateEvents_commentGenerateEvents2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstBasics_isInlineFunc2(threadData_t *threadData, modelica_metatype _inSubModList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstBasics_isInlineFunc2,2,0) {(void*) boxptr_InstBasics_isInlineFunc2,0}};
#define boxvar_InstBasics_isInlineFunc2 MMC_REFSTRUCTLIT(boxvar_lit_InstBasics_isInlineFunc2)
DLLDirection
modelica_integer omc_InstBasics_getFunctionRestrictionPurity(threadData_t *threadData, modelica_metatype _purity, modelica_metatype _cmt, modelica_boolean _newFrontend)
{
modelica_integer _outPurity;
modelica_integer tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _purity;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = 1;
goto tmp3_done;
}
case 4: {
tmp1 = 2;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmp1 = 3;
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
_outPurity = tmp1;
if(((modelica_integer)_outPurity == 3))
{
if(omc_SCodeUtil_commentHasBooleanNamedAnnotation(threadData, _cmt, _OMC_LIT1))
{
_outPurity = 2;
}
else
{
if(((!_newFrontend) && omc_SCodeUtil_commentHasBooleanNamedAnnotation(threadData, _cmt, _OMC_LIT0)))
{
_outPurity = 4;
}
}
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _outPurity;
}
modelica_metatype boxptr_InstBasics_getFunctionRestrictionPurity(threadData_t *threadData, modelica_metatype _purity, modelica_metatype _cmt, modelica_metatype _newFrontend)
{
modelica_integer tmp1;
modelica_integer _outPurity;
modelica_metatype out_outPurity;
tmp1 = mmc_unbox_integer(_newFrontend);
_outPurity = omc_InstBasics_getFunctionRestrictionPurity(threadData, _purity, _cmt, tmp1);
out_outPurity = mmc_mk_icon(_outPurity);
return out_outPurity;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_InstBasics_commentGenerateEvents_commentGenerateEvents2(threadData_t *threadData, modelica_metatype _inSubModList)
{
modelica_boolean _res;
modelica_boolean _stop;
modelica_metatype tmpMeta1;
modelica_boolean tmp2 = 0;
modelica_metatype tmpMeta13;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = 0;
{
modelica_metatype _tp;
for (tmpMeta1 = _inSubModList; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_tp = MMC_CAR(tmpMeta1);
{
modelica_metatype tmp5_1;
tmp5_1 = _tp;
{
volatile mmc_switch_type tmp5;
int tmp6;
tmp5 = 0;
for (; tmp5 < 2; tmp5++) {
switch (MMC_SWITCH_CAST(tmp5)) {
case 0: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_integer tmp12;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
if (14 != MMC_STRLEN(tmpMeta7) || strcmp(MMC_STRINGDATA(_OMC_LIT2), MMC_STRINGDATA(tmpMeta7)) != 0) goto tmp4_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,6) == 0) goto tmp4_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 5));
if (optionNone(tmpMeta9)) goto tmp4_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,4,1) == 0) goto tmp4_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
tmp12 = mmc_unbox_integer(tmpMeta11);
_res = tmp12;
tmp2 = 0;
goto tmp4_done;
}
case 1: {
tmp2 = 1;
goto tmp4_done;
}
}
goto tmp4_end;
tmp4_end: ;
}
goto goto_3;
goto_3:;
MMC_THROW_INTERNAL();
goto tmp4_done;
tmp4_done:;
}
}
_stop = tmp2;
if(_stop)
{
break;
}
}
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstBasics_commentGenerateEvents_commentGenerateEvents2(threadData_t *threadData, modelica_metatype _inSubModList)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_InstBasics_commentGenerateEvents_commentGenerateEvents2(threadData, _inSubModList);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_boolean omc_InstBasics_commentGenerateEvents(threadData_t *threadData, modelica_metatype _cmt)
{
modelica_boolean _generateEvents;
modelica_boolean tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cmt;
{
modelica_metatype _smlst = NULL;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (optionNone(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,6) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 4));
_smlst = tmpMeta9;
tmp1 = omc_InstBasics_commentGenerateEvents_commentGenerateEvents2(threadData, _smlst);
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
_generateEvents = tmp1;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _generateEvents;
}
modelica_metatype boxptr_InstBasics_commentGenerateEvents(threadData_t *threadData, modelica_metatype _cmt)
{
modelica_boolean _generateEvents;
modelica_metatype out_generateEvents;
_generateEvents = omc_InstBasics_commentGenerateEvents(threadData, _cmt);
out_generateEvents = mmc_mk_icon(_generateEvents);
return out_generateEvents;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstBasics_isInlineFunc2(threadData_t *threadData, modelica_metatype _inSubModList)
{
modelica_metatype _res = NULL;
modelica_boolean _stop;
modelica_metatype tmpMeta1;
modelica_boolean tmp2 = 0;
modelica_metatype tmpMeta49;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_stop = 0;
_res = _OMC_LIT3;
{
modelica_metatype _tp;
for (tmpMeta1 = _inSubModList; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_tp = MMC_CAR(tmpMeta1);
{
modelica_metatype tmp5_1;
tmp5_1 = _tp;
{
volatile mmc_switch_type tmp5;
int tmp6;
tmp5 = 0;
for (; tmp5 < 8; tmp5++) {
switch (MMC_SWITCH_CAST(tmp5)) {
case 0: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_integer tmp12;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
if (6 != MMC_STRLEN(tmpMeta7) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmpMeta7)) != 0) goto tmp4_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,6) == 0) goto tmp4_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 5));
if (optionNone(tmpMeta9)) goto tmp4_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,4,1) == 0) goto tmp4_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
tmp12 = mmc_unbox_integer(tmpMeta11);
if (1 /* true */ != tmp12) goto tmp4_end;
_res = _OMC_LIT4;
tmp2 = 0;
goto tmp4_done;
}
case 1: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_integer tmp18;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
if (6 != MMC_STRLEN(tmpMeta13) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmpMeta13)) != 0) goto tmp4_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,0,6) == 0) goto tmp4_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 5));
if (optionNone(tmpMeta15)) goto tmp4_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,4,1) == 0) goto tmp4_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
tmp18 = mmc_unbox_integer(tmpMeta17);
if (0 /* false */ != tmp18) goto tmp4_end;
_res = _OMC_LIT5;
tmp2 = 0;
goto tmp4_done;
}
case 2: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_integer tmp24;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
if (10 != MMC_STRLEN(tmpMeta19) || strcmp(MMC_STRINGDATA(_OMC_LIT9), MMC_STRINGDATA(tmpMeta19)) != 0) goto tmp4_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,0,6) == 0) goto tmp4_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 5));
if (optionNone(tmpMeta21)) goto tmp4_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta22,4,1) == 0) goto tmp4_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 2));
tmp24 = mmc_unbox_integer(tmpMeta23);
if (1 /* true */ != tmp24) goto tmp4_end;
_res = _OMC_LIT6;
tmp2 = 1;
goto tmp4_done;
}
case 3: {
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_integer tmp30;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
if (36 != MMC_STRLEN(tmpMeta25) || strcmp(MMC_STRINGDATA(_OMC_LIT10), MMC_STRINGDATA(tmpMeta25)) != 0) goto tmp4_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,0,6) == 0) goto tmp4_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 5));
if (optionNone(tmpMeta27)) goto tmp4_end;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta28,4,1) == 0) goto tmp4_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta28), 2));
tmp30 = mmc_unbox_integer(tmpMeta29);
if (1 /* true */ != tmp30) goto tmp4_end;
_res = _OMC_LIT6;
tmp2 = 1;
goto tmp4_done;
}
case 4: {
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_integer tmp36;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
if (34 != MMC_STRLEN(tmpMeta31) || strcmp(MMC_STRINGDATA(_OMC_LIT11), MMC_STRINGDATA(tmpMeta31)) != 0) goto tmp4_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta32,0,6) == 0) goto tmp4_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 5));
if (optionNone(tmpMeta33)) goto tmp4_end;
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta33), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta34,4,1) == 0) goto tmp4_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 2));
tmp36 = mmc_unbox_integer(tmpMeta35);
if (1 /* true */ != tmp36) goto tmp4_end;
_res = _OMC_LIT6;
tmp2 = 1;
goto tmp4_done;
}
case 5: {
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_integer tmp42;
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
if (25 != MMC_STRLEN(tmpMeta37) || strcmp(MMC_STRINGDATA(_OMC_LIT12), MMC_STRINGDATA(tmpMeta37)) != 0) goto tmp4_end;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta38,0,6) == 0) goto tmp4_end;
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta38), 5));
if (optionNone(tmpMeta39)) goto tmp4_end;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta40,4,1) == 0) goto tmp4_end;
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta40), 2));
tmp42 = mmc_unbox_integer(tmpMeta41);
if (1 /* true */ != tmp42) goto tmp4_end;
_res = _OMC_LIT6;
tmp2 = 1;
goto tmp4_done;
}
case 6: {
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_integer tmp48;
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
if (26 != MMC_STRLEN(tmpMeta43) || strcmp(MMC_STRINGDATA(_OMC_LIT13), MMC_STRINGDATA(tmpMeta43)) != 0) goto tmp4_end;
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta44,0,6) == 0) goto tmp4_end;
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 5));
if (optionNone(tmpMeta45)) goto tmp4_end;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta46,4,1) == 0) goto tmp4_end;
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta46), 2));
tmp48 = mmc_unbox_integer(tmpMeta47);
if (1 /* true */ != tmp48) goto tmp4_end;
_res = _OMC_LIT7;
tmp2 = 1;
goto tmp4_done;
}
case 7: {
tmp2 = 0;
goto tmp4_done;
}
}
goto tmp4_end;
tmp4_end: ;
}
goto goto_3;
goto_3:;
MMC_THROW_INTERNAL();
goto tmp4_done;
tmp4_done:;
}
}
_stop = tmp2;
if(_stop)
{
break;
}
}
}
_return: OMC_LABEL_UNUSED
return _res;
}
DLLDirection
modelica_metatype omc_InstBasics_commentIsInlineFunc(threadData_t *threadData, modelica_metatype _cmt)
{
modelica_metatype _outInlineType = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cmt;
{
modelica_metatype _smlst = NULL;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (optionNone(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,6) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 4));
_smlst = tmpMeta9;
tmpMeta1 = omc_InstBasics_isInlineFunc2(threadData, _smlst);
goto tmp3_done;
}
case 1: {
tmpMeta1 = _OMC_LIT3;
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
_outInlineType = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outInlineType;
}
