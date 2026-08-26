#include "omc_simulation_settings.h"
#include "ComponentReferenceBasics.h"
#define _OMC_LIT0_data "{"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,1,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data ","
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,1,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "}"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,1,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "_L"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,2,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "_R"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,2,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,2,0) {_OMC_LIT3,_OMC_LIT4}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "["
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,1,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "]"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,1,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT8,2,0) {_OMC_LIT6,_OMC_LIT7}};
#define _OMC_LIT8 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "__"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,2,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,1,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "_"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,1,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#include "util/modelica.h"
#include "ComponentReferenceBasics_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_integer omc_ComponentReferenceBasics_hashSubscript(threadData_t *threadData, modelica_metatype _sub);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReferenceBasics_hashSubscript(threadData_t *threadData, modelica_metatype _sub);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReferenceBasics_hashSubscript,2,0) {(void*) boxptr_ComponentReferenceBasics_hashSubscript,0}};
#define boxvar_ComponentReferenceBasics_hashSubscript MMC_REFSTRUCTLIT(boxvar_lit_ComponentReferenceBasics_hashSubscript)
PROTECTED_FUNCTION_STATIC modelica_integer omc_ComponentReferenceBasics_hashSubscripts2(threadData_t *threadData, modelica_metatype _dims, modelica_metatype _subs, modelica_integer _factor);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReferenceBasics_hashSubscripts2(threadData_t *threadData, modelica_metatype _dims, modelica_metatype _subs, modelica_metatype _factor);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReferenceBasics_hashSubscripts2,2,0) {(void*) boxptr_ComponentReferenceBasics_hashSubscripts2,0}};
#define boxvar_ComponentReferenceBasics_hashSubscripts2 MMC_REFSTRUCTLIT(boxvar_lit_ComponentReferenceBasics_hashSubscripts2)
PROTECTED_FUNCTION_STATIC modelica_integer omc_ComponentReferenceBasics_hashSubscripts(threadData_t *threadData, modelica_metatype _tp, modelica_metatype _subs);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReferenceBasics_hashSubscripts(threadData_t *threadData, modelica_metatype _tp, modelica_metatype _subs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReferenceBasics_hashSubscripts,2,0) {(void*) boxptr_ComponentReferenceBasics_hashSubscripts,0}};
#define boxvar_ComponentReferenceBasics_hashSubscripts MMC_REFSTRUCTLIT(boxvar_lit_ComponentReferenceBasics_hashSubscripts)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ComponentReferenceBasics_crefEqualWithoutSubs2(threadData_t *threadData, modelica_boolean _refEq, modelica_metatype _icr1, modelica_metatype _icr2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReferenceBasics_crefEqualWithoutSubs2(threadData_t *threadData, modelica_metatype _refEq, modelica_metatype _icr1, modelica_metatype _icr2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReferenceBasics_crefEqualWithoutSubs2,2,0) {(void*) boxptr_ComponentReferenceBasics_crefEqualWithoutSubs2,0}};
#define boxvar_ComponentReferenceBasics_crefEqualWithoutSubs2 MMC_REFSTRUCTLIT(boxvar_lit_ComponentReferenceBasics_crefEqualWithoutSubs2)
PROTECTED_FUNCTION_STATIC modelica_integer omc_ComponentReferenceBasics_crefLexicalCompareSubsAtEnd2(threadData_t *threadData, modelica_metatype _inSubs1, modelica_metatype _inSubs2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReferenceBasics_crefLexicalCompareSubsAtEnd2(threadData_t *threadData, modelica_metatype _inSubs1, modelica_metatype _inSubs2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReferenceBasics_crefLexicalCompareSubsAtEnd2,2,0) {(void*) boxptr_ComponentReferenceBasics_crefLexicalCompareSubsAtEnd2,0}};
#define boxvar_ComponentReferenceBasics_crefLexicalCompareSubsAtEnd2 MMC_REFSTRUCTLIT(boxvar_lit_ComponentReferenceBasics_crefLexicalCompareSubsAtEnd2)
PROTECTED_FUNCTION_STATIC modelica_integer omc_ComponentReferenceBasics_hashSubscript(threadData_t *threadData, modelica_metatype _sub)
{
modelica_integer _hash;
modelica_integer tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _sub;
{
modelica_metatype _exp = NULL;
modelica_integer _i;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 0);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_integer tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmp8 = mmc_unbox_integer(tmpMeta7);
_i = tmp8;
tmp1 = _i;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_exp = tmpMeta9;
tmp1 = omc_ExpressionBasics_hashExp(threadData, _exp);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_exp = tmpMeta10;
tmp1 = omc_ExpressionBasics_hashExp(threadData, _exp);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_exp = tmpMeta11;
tmp1 = omc_ExpressionBasics_hashExp(threadData, _exp);
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
_hash = tmp1;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _hash;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReferenceBasics_hashSubscript(threadData_t *threadData, modelica_metatype _sub)
{
modelica_integer _hash;
modelica_metatype out_hash;
_hash = omc_ComponentReferenceBasics_hashSubscript(threadData, _sub);
out_hash = mmc_mk_icon(_hash);
return out_hash;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_ComponentReferenceBasics_hashSubscripts2(threadData_t *threadData, modelica_metatype _dims, modelica_metatype _subs, modelica_integer _factor)
{
modelica_integer _hash;
modelica_integer tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _dims;
tmp4_2 = _subs;
{
modelica_metatype _s = NULL;
modelica_metatype _rest_dims = NULL;
modelica_metatype _rest_subs = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmp1 = ((modelica_integer) 0);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_2);
tmpMeta9 = MMC_CDR(tmp4_2);
_rest_dims = tmpMeta7;
_s = tmpMeta8;
_rest_subs = tmpMeta9;
tmp1 = (omc_ComponentReferenceBasics_hashSubscript(threadData, _s)) * (_factor) + omc_ComponentReferenceBasics_hashSubscripts2(threadData, _rest_dims, _rest_subs, (((modelica_integer) 1000)) * (_factor));
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
_hash = tmp1;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _hash;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReferenceBasics_hashSubscripts2(threadData_t *threadData, modelica_metatype _dims, modelica_metatype _subs, modelica_metatype _factor)
{
modelica_integer tmp1;
modelica_integer _hash;
modelica_metatype out_hash;
tmp1 = mmc_unbox_integer(_factor);
_hash = omc_ComponentReferenceBasics_hashSubscripts2(threadData, _dims, _subs, tmp1);
out_hash = mmc_mk_icon(_hash);
return out_hash;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_ComponentReferenceBasics_hashSubscripts(threadData_t *threadData, modelica_metatype _tp, modelica_metatype _subs)
{
modelica_integer _hash;
modelica_integer tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _subs;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp1 = ((modelica_integer) 0);
goto tmp3_done;
}
case 1: {
tmp1 = omc_ComponentReferenceBasics_hashSubscripts2(threadData, omc_List_fill(threadData, mmc_mk_integer(((modelica_integer) 1)), listLength(_subs)), _subs, ((modelica_integer) 1));
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
_hash = tmp1;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _hash;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReferenceBasics_hashSubscripts(threadData_t *threadData, modelica_metatype _tp, modelica_metatype _subs)
{
modelica_integer _hash;
modelica_metatype out_hash;
_hash = omc_ComponentReferenceBasics_hashSubscripts(threadData, _tp, _subs);
out_hash = mmc_mk_icon(_hash);
return out_hash;
}
DLLDirection
modelica_integer omc_ComponentReferenceBasics_hashComponentRef(threadData_t *threadData, modelica_metatype _cr)
{
modelica_integer _hash;
modelica_integer tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cr;
{
modelica_string _id = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _cr1 = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id = tmpMeta5;
_tp = tmpMeta6;
_subs = tmpMeta7;
tmp1 = stringHashDjb2(_id) + omc_ComponentReferenceBasics_hashSubscripts(threadData, _tp, _subs);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta8;
_tp = tmpMeta9;
_subs = tmpMeta10;
_cr1 = tmpMeta11;
tmp1 = stringHashDjb2(_id) + (omc_ComponentReferenceBasics_hashSubscripts(threadData, _tp, _subs) + omc_ComponentReferenceBasics_hashComponentRef(threadData, _cr1));
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmp1 = ((modelica_integer) 0);
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
_hash = tmp1;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _hash;
}
modelica_metatype boxptr_ComponentReferenceBasics_hashComponentRef(threadData_t *threadData, modelica_metatype _cr)
{
modelica_integer _hash;
modelica_metatype out_hash;
_hash = omc_ComponentReferenceBasics_hashComponentRef(threadData, _cr);
out_hash = mmc_mk_icon(_hash);
return out_hash;
}
DLLDirection
modelica_string omc_ComponentReferenceBasics_printComponentRefListStr(threadData_t *threadData, modelica_metatype _crs)
{
modelica_string _res = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = stringAppend(_OMC_LIT0,stringDelimitList(omc_List_map(threadData, _crs, boxvar_ComponentReferenceBasics_printComponentRefStr), _OMC_LIT1));
tmpMeta2 = stringAppend(tmpMeta1,_OMC_LIT2);
_res = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _res;
}
DLLDirection
modelica_string omc_ComponentReferenceBasics_printComponentRef2Str(threadData_t *threadData, modelica_string _inIdent, modelica_metatype _inSubscriptLst)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_string tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inIdent;
tmp4_2 = _inSubscriptLst;
{
modelica_string _s = NULL;
modelica_string _str = NULL;
modelica_string _strseba = NULL;
modelica_string _strsebb = NULL;
modelica_metatype _l = NULL;
modelica_boolean _b;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
_s = tmp4_1;
tmp1 = _s;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
_s = tmp4_1;
_l = tmp4_2;
_b = omc_Config_modelicaOutput(threadData);
_str = omc_ExpressionBasics_printListStr(threadData, _l, boxvar_ExpressionBasics_printSubscriptStr, _OMC_LIT1);
tmpMeta6 = (_b?_OMC_LIT5:_OMC_LIT8);
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_strseba = tmpMeta7;
_strsebb = tmpMeta8;
tmpMeta9 = mmc_mk_cons(_s, mmc_mk_cons(_strseba, mmc_mk_cons(_str, mmc_mk_cons(_strsebb, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp1 = stringAppendList(tmpMeta9);
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLDirection
modelica_string omc_ComponentReferenceBasics_printComponentRefStr(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_string _s = NULL;
modelica_string _str = NULL;
modelica_string _strrest = NULL;
modelica_string _strseb = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _cr = NULL;
modelica_boolean _b;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta7)) goto tmp3_end;
_s = tmpMeta6;
tmp1 = _s;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_s = tmpMeta8;
_subs = tmpMeta9;
tmp1 = omc_ComponentReferenceBasics_printComponentRef2Str(threadData, _s, _subs);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_s = tmpMeta10;
_subs = tmpMeta11;
_cr = tmpMeta12;
_b = omc_Config_modelicaOutput(threadData);
_str = omc_ComponentReferenceBasics_printComponentRef2Str(threadData, _s, _subs);
_strrest = omc_ComponentReferenceBasics_printComponentRefStr(threadData, _cr);
_strseb = (_b?_OMC_LIT9:_OMC_LIT10);
tmpMeta13 = mmc_mk_cons(_str, mmc_mk_cons(_strseb, mmc_mk_cons(_strrest, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta13);
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT11;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLDirection
modelica_metatype omc_ComponentReferenceBasics_makeCrefQual(threadData_t *threadData, modelica_string _ident, modelica_metatype _identType, modelica_metatype _subscriptLst, modelica_metatype _componentRef)
{
modelica_metatype _outCrefQual = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box5(3, &DAE_ComponentRef_CREF__QUAL__desc, _ident, _identType, _subscriptLst, _componentRef);
_outCrefQual = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCrefQual;
}
DLLDirection
modelica_metatype omc_ComponentReferenceBasics_makeCrefIdent(threadData_t *threadData, modelica_string _ident, modelica_metatype _identType, modelica_metatype _subscriptLst)
{
modelica_metatype _outCrefIdent = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _ident, _identType, _subscriptLst);
_outCrefIdent = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCrefIdent;
}
DLLDirection
modelica_metatype omc_ComponentReferenceBasics_crefStripLastSubs(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_string _id = NULL;
modelica_metatype _s = NULL;
modelica_metatype _cr_1 = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _t2 = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_id = tmpMeta6;
_t2 = tmpMeta7;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta9 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _id, _t2, tmpMeta8);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta10;
_t2 = tmpMeta11;
_s = tmpMeta12;
_cr = tmpMeta13;
_cr_1 = omc_ComponentReferenceBasics_crefStripLastSubs(threadData, _cr);
tmpMeta14 = mmc_mk_box5(3, &DAE_ComponentRef_CREF__QUAL__desc, _id, _t2, _s, _cr_1);
tmpMeta1 = tmpMeta14;
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
_outComponentRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRef;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ComponentReferenceBasics_crefEqualWithoutSubs2(threadData_t *threadData, modelica_boolean _refEq, modelica_metatype _icr1, modelica_metatype _icr2)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _refEq;
tmp4_2 = _icr1;
tmp4_3 = _icr2;
{
modelica_string _n1 = NULL;
modelica_string _n2 = NULL;
modelica_boolean _r;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (1 /* true */ != tmp4_1) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
_n1 = tmpMeta6;
_n2 = tmpMeta7;
tmp1 = (stringEqual(_n1, _n2));
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_boolean tmp12;
modelica_boolean tmp13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,4) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 5));
_n1 = tmpMeta8;
_cr1 = tmpMeta9;
_n2 = tmpMeta10;
_cr2 = tmpMeta11;
_r = (stringEqual(_n1, _n2));
tmp12 = (modelica_boolean)_r;
if(tmp12)
{
_refEq = referenceEq(_cr1, _cr2);
_icr1 = _cr1;
_icr2 = _cr2;
goto _tailrecursive;
}
else
{
tmp13 = 0;
}
tmp1 = tmp13;
goto tmp3_done;
}
case 3: {
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReferenceBasics_crefEqualWithoutSubs2(threadData_t *threadData, modelica_metatype _refEq, modelica_metatype _icr1, modelica_metatype _icr2)
{
modelica_integer tmp1;
modelica_boolean _res;
modelica_metatype out_res;
tmp1 = mmc_unbox_integer(_refEq);
_res = omc_ComponentReferenceBasics_crefEqualWithoutSubs2(threadData, tmp1, _icr1, _icr2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_boolean omc_ComponentReferenceBasics_crefEqualWithoutSubs(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _res;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = omc_ComponentReferenceBasics_crefEqualWithoutSubs2(threadData, referenceEq(_cr1, _cr2), _cr1, _cr2);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
modelica_metatype boxptr_ComponentReferenceBasics_crefEqualWithoutSubs(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_ComponentReferenceBasics_crefEqualWithoutSubs(threadData, _cr1, _cr2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_boolean omc_ComponentReferenceBasics_crefEqualWithoutLastSubs(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _res;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = omc_ComponentReferenceBasics_crefEqualNoStringCompare(threadData, omc_ComponentReferenceBasics_crefStripLastSubs(threadData, _cr1), omc_ComponentReferenceBasics_crefStripLastSubs(threadData, _cr2));
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
modelica_metatype boxptr_ComponentReferenceBasics_crefEqualWithoutLastSubs(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_ComponentReferenceBasics_crefEqualWithoutLastSubs(threadData, _cr1, _cr2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_metatype omc_ComponentReferenceBasics_crefEqualReturn(threadData_t *threadData, modelica_metatype _cr, modelica_metatype _cr2)
{
modelica_metatype _ocr = NULL;
modelica_boolean tmp1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmp1 = omc_ComponentReferenceBasics_crefEqualNoStringCompare(threadData, _cr, _cr2);
if (1 /* true */ != tmp1) MMC_THROW_INTERNAL();
_ocr = _cr;
_return: OMC_LABEL_UNUSED
return _ocr;
}
DLLDirection
modelica_boolean omc_ComponentReferenceBasics_crefEqualNoStringCompare(threadData_t *threadData, modelica_metatype _inCref1, modelica_metatype _inCref2)
{
modelica_boolean _outEqual;
modelica_boolean tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(referenceEq(_inCref1, _inCref2))
{
_outEqual = 1;
goto _return;
}
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inCref1;
tmp4_2 = _inCref2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmp1 = ((stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref2), 2))))) && omc_ExpressionBasics_subscriptEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref2), 4)))));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmp1 = (((stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref2), 2))))) && omc_ComponentReferenceBasics_crefEqualNoStringCompare(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref1), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref2), 5))))) && omc_ExpressionBasics_subscriptEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref2), 4)))));
goto tmp3_done;
}
case 2: {
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
_outEqual = tmp1;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _outEqual;
}
modelica_metatype boxptr_ComponentReferenceBasics_crefEqualNoStringCompare(threadData_t *threadData, modelica_metatype _inCref1, modelica_metatype _inCref2)
{
modelica_boolean _outEqual;
modelica_metatype out_outEqual;
_outEqual = omc_ComponentReferenceBasics_crefEqualNoStringCompare(threadData, _inCref1, _inCref2);
out_outEqual = mmc_mk_icon(_outEqual);
return out_outEqual;
}
DLLDirection
modelica_boolean omc_ComponentReferenceBasics_crefEqualVerySlowStringCompareDoNotUse(threadData_t *threadData, modelica_metatype _inComponentRef1, modelica_metatype _inComponentRef2)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inComponentRef1;
tmp4_2 = _inComponentRef2;
{
modelica_string _n1 = NULL;
modelica_string _n2 = NULL;
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
modelica_metatype _idx1 = NULL;
modelica_metatype _idx2 = NULL;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 9; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
tmp6 = referenceEq(_inComponentRef1, _inComponentRef2);
if (1 /* true */ != tmp6) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_boolean tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta8)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (!listEmpty(tmpMeta10)) goto tmp3_end;
_n1 = tmpMeta7;
_n2 = tmpMeta9;
tmp4 += 6;
tmp11 = (stringEqual(_n1, _n2));
if (1 /* true */ != tmp11) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_boolean tmp20;
modelica_boolean tmp21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta13)) goto tmp3_end;
tmpMeta14 = MMC_CAR(tmpMeta13);
tmpMeta15 = MMC_CDR(tmpMeta13);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (listEmpty(tmpMeta17)) goto tmp3_end;
tmpMeta18 = MMC_CAR(tmpMeta17);
tmpMeta19 = MMC_CDR(tmpMeta17);
_n1 = tmpMeta12;
_idx1 = tmpMeta13;
_n2 = tmpMeta16;
_idx2 = tmpMeta17;
tmp4 += 5;
tmp20 = (stringEqual(_n1, _n2));
if (1 /* true */ != tmp20) goto goto_2;
tmp21 = omc_ExpressionBasics_subscriptEqual(threadData, _idx1, _idx2);
if (1 /* true */ != tmp21) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_integer tmp28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_boolean tmp32;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta23)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (listEmpty(tmpMeta25)) goto tmp3_end;
tmpMeta26 = MMC_CAR(tmpMeta25);
tmpMeta27 = MMC_CDR(tmpMeta25);
_n1 = tmpMeta22;
_n2 = tmpMeta24;
_idx2 = tmpMeta25;
tmp4 += 4;
tmp28 = omc_System_stringFind(threadData, _n1, _n2);
if (0 != tmp28) goto goto_2;
tmpMeta29 = stringAppend(_n2,_OMC_LIT6);
tmpMeta30 = stringAppend(tmpMeta29,omc_ExpressionBasics_printListStr(threadData, _idx2, boxvar_ExpressionBasics_printSubscriptStr, _OMC_LIT1));
tmpMeta31 = stringAppend(tmpMeta30,_OMC_LIT7);
_s1 = tmpMeta31;
tmp32 = (stringEqual(_s1, _n1));
if (1 /* true */ != tmp32) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_integer tmp39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
modelica_boolean tmp43;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta34)) goto tmp3_end;
tmpMeta35 = MMC_CAR(tmpMeta34);
tmpMeta36 = MMC_CDR(tmpMeta34);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (!listEmpty(tmpMeta38)) goto tmp3_end;
_n1 = tmpMeta33;
_idx2 = tmpMeta34;
_n2 = tmpMeta37;
tmp4 += 3;
tmp39 = omc_System_stringFind(threadData, _n2, _n1);
if (0 != tmp39) goto goto_2;
tmpMeta40 = stringAppend(_n1,_OMC_LIT6);
tmpMeta41 = stringAppend(tmpMeta40,omc_ExpressionBasics_printListStr(threadData, _idx2, boxvar_ExpressionBasics_printSubscriptStr, _OMC_LIT1));
tmpMeta42 = stringAppend(tmpMeta41,_OMC_LIT7);
_s1 = tmpMeta42;
tmp43 = (stringEqual(_s1, _n2));
if (1 /* true */ != tmp43) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_boolean tmp50;
modelica_boolean tmp51;
modelica_boolean tmp52;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
_n1 = tmpMeta44;
_idx1 = tmpMeta45;
_cr1 = tmpMeta46;
_n2 = tmpMeta47;
_idx2 = tmpMeta48;
_cr2 = tmpMeta49;
tmp4 += 2;
tmp50 = (stringEqual(_n1, _n2));
if (1 /* true */ != tmp50) goto goto_2;
tmp51 = omc_ComponentReferenceBasics_crefEqualVerySlowStringCompareDoNotUse(threadData, _cr1, _cr2);
if (1 /* true */ != tmp51) goto goto_2;
tmp52 = omc_ExpressionBasics_subscriptEqual(threadData, _idx1, _idx2);
if (1 /* true */ != tmp52) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_integer tmp55;
modelica_boolean tmp56;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_cr1 = tmp4_1;
_n1 = tmpMeta53;
_cr2 = tmp4_2;
_n2 = tmpMeta54;
tmp4 += 1;
tmp55 = omc_System_stringFind(threadData, _n2, _n1);
if (0 != tmp55) goto goto_2;
_s1 = omc_ComponentReferenceBasics_printComponentRefStr(threadData, _cr1);
_s2 = omc_ComponentReferenceBasics_printComponentRefStr(threadData, _cr2);
tmp56 = (stringEqual(_s1, _s2));
if (1 /* true */ != tmp56) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta57;
modelica_metatype tmpMeta58;
modelica_integer tmp59;
modelica_boolean tmp60;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmpMeta58 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_cr1 = tmp4_1;
_n1 = tmpMeta57;
_cr2 = tmp4_2;
_n2 = tmpMeta58;
tmp59 = omc_System_stringFind(threadData, _n1, _n2);
if (0 != tmp59) goto goto_2;
_s1 = omc_ComponentReferenceBasics_printComponentRefStr(threadData, _cr1);
_s2 = omc_ComponentReferenceBasics_printComponentRefStr(threadData, _cr2);
tmp60 = (stringEqual(_s1, _s2));
if (1 /* true */ != tmp60) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 8: {
tmp1 = 0;
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
_outBoolean = tmp1;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _outBoolean;
}
modelica_metatype boxptr_ComponentReferenceBasics_crefEqualVerySlowStringCompareDoNotUse(threadData_t *threadData, modelica_metatype _inComponentRef1, modelica_metatype _inComponentRef2)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_ComponentReferenceBasics_crefEqualVerySlowStringCompareDoNotUse(threadData, _inComponentRef1, _inComponentRef2);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLDirection
modelica_boolean omc_ComponentReferenceBasics_crefNotInLst(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _lst)
{
modelica_boolean _b;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = (!omc_List_isMemberOnTrue(threadData, _cref, _lst, boxvar_ComponentReferenceBasics_crefEqual));
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _b;
}
modelica_metatype boxptr_ComponentReferenceBasics_crefNotInLst(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _lst)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_ComponentReferenceBasics_crefNotInLst(threadData, _cref, _lst);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLDirection
modelica_boolean omc_ComponentReferenceBasics_crefInLst(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _lst)
{
modelica_boolean _b;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_List_isMemberOnTrue(threadData, _cref, _lst, boxvar_ComponentReferenceBasics_crefEqual);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _b;
}
modelica_metatype boxptr_ComponentReferenceBasics_crefInLst(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _lst)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_ComponentReferenceBasics_crefInLst(threadData, _cref, _lst);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLDirection
modelica_boolean omc_ComponentReferenceBasics_crefEqual(threadData_t *threadData, modelica_metatype _inComponentRef1, modelica_metatype _inComponentRef2)
{
modelica_boolean _outBoolean;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outBoolean = omc_ComponentReferenceBasics_crefEqualNoStringCompare(threadData, _inComponentRef1, _inComponentRef2);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _outBoolean;
}
modelica_metatype boxptr_ComponentReferenceBasics_crefEqual(threadData_t *threadData, modelica_metatype _inComponentRef1, modelica_metatype _inComponentRef2)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_ComponentReferenceBasics_crefEqual(threadData, _inComponentRef1, _inComponentRef2);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLDirection
modelica_boolean omc_ComponentReferenceBasics_crefNotPrefixOf(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _cr1;
tmp4_2 = _cr2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
tmp1 = (!omc_ComponentReferenceBasics_crefPrefixOf(threadData, _cr1, _cr2));
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
_outBoolean = tmp1;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _outBoolean;
}
modelica_metatype boxptr_ComponentReferenceBasics_crefNotPrefixOf(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_ComponentReferenceBasics_crefNotPrefixOf(threadData, _cr1, _cr2);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLDirection
modelica_boolean omc_ComponentReferenceBasics_crefPrefixOfIgnoreSubscripts(threadData_t *threadData, modelica_metatype _prefixCref, modelica_metatype _fullCref)
{
modelica_boolean _outPrefixOf;
modelica_boolean tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _prefixCref;
tmp4_2 = _fullCref;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmp1 = ((stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 2))))) && omc_ComponentReferenceBasics_crefPrefixOfIgnoreSubscripts(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 5)))));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmp1 = (stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 2)))));
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmp1 = (stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 2)))));
goto tmp3_done;
}
case 3: {
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
_outPrefixOf = tmp1;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _outPrefixOf;
}
modelica_metatype boxptr_ComponentReferenceBasics_crefPrefixOfIgnoreSubscripts(threadData_t *threadData, modelica_metatype _prefixCref, modelica_metatype _fullCref)
{
modelica_boolean _outPrefixOf;
modelica_metatype out_outPrefixOf;
_outPrefixOf = omc_ComponentReferenceBasics_crefPrefixOfIgnoreSubscripts(threadData, _prefixCref, _fullCref);
out_outPrefixOf = mmc_mk_icon(_outPrefixOf);
return out_outPrefixOf;
}
DLLDirection
modelica_boolean omc_ComponentReferenceBasics_crefPrefixOf(threadData_t *threadData, modelica_metatype _prefixCref, modelica_metatype _fullCref)
{
modelica_boolean _outPrefixOf;
modelica_boolean tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _prefixCref;
tmp4_2 = _fullCref;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmp1 = (((stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 2))))) && omc_ExpressionBasics_subscriptEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 4))))) && omc_ComponentReferenceBasics_crefPrefixOf(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 5)))));
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
tmp1 = (stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 2)))));
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmp1 = ((stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 2))))) && omc_ExpressionBasics_subscriptEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 4)))));
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta7)) goto tmp3_end;
tmp1 = (stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 2)))));
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmp1 = ((stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 2))))) && omc_ExpressionBasics_subscriptEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 4)))));
goto tmp3_done;
}
case 5: {
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
_outPrefixOf = tmp1;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _outPrefixOf;
}
modelica_metatype boxptr_ComponentReferenceBasics_crefPrefixOf(threadData_t *threadData, modelica_metatype _prefixCref, modelica_metatype _fullCref)
{
modelica_boolean _outPrefixOf;
modelica_metatype out_outPrefixOf;
_outPrefixOf = omc_ComponentReferenceBasics_crefPrefixOf(threadData, _prefixCref, _fullCref);
out_outPrefixOf = mmc_mk_icon(_outPrefixOf);
return out_outPrefixOf;
}
DLLDirection
modelica_boolean omc_ComponentReferenceBasics_crefContainedIn(threadData_t *threadData, modelica_metatype _containerCref, modelica_metatype _containedCref)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _containerCref;
tmp4_2 = _containedCref;
{
modelica_metatype _full = NULL;
modelica_metatype _partOf = NULL;
modelica_metatype _cr2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
_full = tmp4_1;
_partOf = tmp4_2;
tmp6 = omc_ComponentReferenceBasics_crefEqualNoStringCompare(threadData, _full, _partOf);
if (1 /* true */ != tmp6) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta7;
modelica_boolean tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_full = tmp4_1;
_cr2 = tmpMeta7;
_partOf = tmp4_2;
tmp8 = omc_ComponentReferenceBasics_crefEqualNoStringCompare(threadData, _full, _partOf);
if (0 /* false */ != tmp8) goto goto_2;
tmp1 = omc_ComponentReferenceBasics_crefContainedIn(threadData, _cr2, _partOf);
goto tmp3_done;
}
case 3: {
tmp1 = 0;
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
_outBoolean = tmp1;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _outBoolean;
}
modelica_metatype boxptr_ComponentReferenceBasics_crefContainedIn(threadData_t *threadData, modelica_metatype _containerCref, modelica_metatype _containedCref)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_ComponentReferenceBasics_crefContainedIn(threadData, _containerCref, _containedCref);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_ComponentReferenceBasics_crefLexicalCompareSubsAtEnd2(threadData_t *threadData, modelica_metatype _inSubs1, modelica_metatype _inSubs2)
{
modelica_integer _res;
modelica_metatype _rest = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_metatype tmpMeta6;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = ((modelica_integer) 0);
_rest = _inSubs2;
{
modelica_metatype _i;
for (tmpMeta1 = _inSubs1; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_i = MMC_CAR(tmpMeta1);
tmpMeta2 = _rest;
if (listEmpty(tmpMeta2)) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_CAR(tmpMeta2);
tmpMeta4 = MMC_CDR(tmpMeta2);
tmp5 = mmc_unbox_integer(tmpMeta3);
_res = tmp5;
_rest = tmpMeta4;
_res = ((mmc_unbox_integer(_i) > _res)?((modelica_integer) 1):((mmc_unbox_integer(_i) < _res)?((modelica_integer) -1):((modelica_integer) 0)));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
}
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReferenceBasics_crefLexicalCompareSubsAtEnd2(threadData_t *threadData, modelica_metatype _inSubs1, modelica_metatype _inSubs2)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_ComponentReferenceBasics_crefLexicalCompareSubsAtEnd2(threadData, _inSubs1, _inSubs2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_integer omc_ComponentReferenceBasics_crefLexicalCompareSubsAtEnd(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _res;
modelica_metatype _subs1 = NULL;
modelica_metatype _subs2 = NULL;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = omc_ComponentReferenceBasics_CompareWithoutSubscripts_compare(threadData, _cr1, _cr2);
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_subs1 = omc_ExpressionBasics_subscriptsInt(threadData, omc_ComponentReferenceBasics_crefSubs(threadData, _cr1));
_subs2 = omc_ExpressionBasics_subscriptsInt(threadData, omc_ComponentReferenceBasics_crefSubs(threadData, _cr2));
_res = omc_ComponentReferenceBasics_crefLexicalCompareSubsAtEnd2(threadData, _subs1, _subs2);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
modelica_metatype boxptr_ComponentReferenceBasics_crefLexicalCompareSubsAtEnd(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_ComponentReferenceBasics_crefLexicalCompareSubsAtEnd(threadData, _cr1, _cr2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_boolean omc_ComponentReferenceBasics_crefLexicalGreaterSubsAtEnd(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _isGreater;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_isGreater = (omc_ComponentReferenceBasics_crefLexicalCompareSubsAtEnd(threadData, _cr1, _cr2) > ((modelica_integer) 0));
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _isGreater;
}
modelica_metatype boxptr_ComponentReferenceBasics_crefLexicalGreaterSubsAtEnd(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _isGreater;
modelica_metatype out_isGreater;
_isGreater = omc_ComponentReferenceBasics_crefLexicalGreaterSubsAtEnd(threadData, _cr1, _cr2);
out_isGreater = mmc_mk_icon(_isGreater);
return out_isGreater;
}
DLLDirection
modelica_integer omc_ComponentReferenceBasics_crefCompareGenericNotAlphabetic(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _comp;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_comp = omc_ComponentReferenceBasics_CompareWithGenericSubscriptNotAlphabetic_compare(threadData, _cr1, _cr2);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _comp;
}
modelica_metatype boxptr_ComponentReferenceBasics_crefCompareGenericNotAlphabetic(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _comp;
modelica_metatype out_comp;
_comp = omc_ComponentReferenceBasics_crefCompareGenericNotAlphabetic(threadData, _cr1, _cr2);
out_comp = mmc_mk_icon(_comp);
return out_comp;
}
DLLDirection
modelica_integer omc_ComponentReferenceBasics_crefCompareIntSubscript(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _comp;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_comp = omc_ComponentReferenceBasics_CompareWithIntSubscript_compare(threadData, _cr1, _cr2);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _comp;
}
modelica_metatype boxptr_ComponentReferenceBasics_crefCompareIntSubscript(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _comp;
modelica_metatype out_comp;
_comp = omc_ComponentReferenceBasics_crefCompareIntSubscript(threadData, _cr1, _cr2);
out_comp = mmc_mk_icon(_comp);
return out_comp;
}
DLLDirection
modelica_integer omc_ComponentReferenceBasics_crefCompareGeneric(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _comp;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_comp = omc_ComponentReferenceBasics_CompareWithGenericSubscript_compare(threadData, _cr1, _cr2);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _comp;
}
modelica_metatype boxptr_ComponentReferenceBasics_crefCompareGeneric(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _comp;
modelica_metatype out_comp;
_comp = omc_ComponentReferenceBasics_crefCompareGeneric(threadData, _cr1, _cr2);
out_comp = mmc_mk_icon(_comp);
return out_comp;
}
DLLDirection
modelica_boolean omc_ComponentReferenceBasics_crefSortFunc(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _greaterThan;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_greaterThan = (omc_ComponentReferenceBasics_CompareWithGenericSubscript_compare(threadData, _cr1, _cr2) > ((modelica_integer) 0));
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _greaterThan;
}
modelica_metatype boxptr_ComponentReferenceBasics_crefSortFunc(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _greaterThan;
modelica_metatype out_greaterThan;
_greaterThan = omc_ComponentReferenceBasics_crefSortFunc(threadData, _cr1, _cr2);
out_greaterThan = mmc_mk_icon(_greaterThan);
return out_greaterThan;
}
DLLDirection
modelica_integer omc_ComponentReferenceBasics_CompareWithIntSubscript_compare(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _res;
modelica_integer tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _cr1;
tmp4_2 = _cr2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = omc_ComponentReferenceBasics_CompareWithIntSubscript_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_res = omc_ComponentReferenceBasics_CompareWithIntSubscript_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_cr1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 5)));
_cr2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 5)));
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_res = omc_ComponentReferenceBasics_CompareWithIntSubscript_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = ((modelica_integer) 1);
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_res = omc_ComponentReferenceBasics_CompareWithIntSubscript_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = ((modelica_integer) -1);
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
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
modelica_metatype boxptr_ComponentReferenceBasics_CompareWithIntSubscript_compare(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_ComponentReferenceBasics_CompareWithIntSubscript_compare(threadData, _cr1, _cr2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_integer omc_ComponentReferenceBasics_CompareWithIntSubscript_compareSubs(threadData_t *threadData, modelica_metatype _ss1, modelica_metatype _ss2)
{
modelica_integer _res;
modelica_metatype _ss = NULL;
modelica_metatype _s2 = NULL;
modelica_integer _i1;
modelica_integer _i2;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = ((modelica_integer) 0);
_ss = _ss2;
{
modelica_metatype _s1;
for (tmpMeta1 = _ss1; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_s1 = MMC_CAR(tmpMeta1);
if(listEmpty(_ss))
{
_res = ((modelica_integer) -1);
goto _return;
}
tmpMeta2 = _ss;
if (listEmpty(tmpMeta2)) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_CAR(tmpMeta2);
tmpMeta4 = MMC_CDR(tmpMeta2);
_s2 = tmpMeta3;
_ss = tmpMeta4;
_i1 = omc_ExpressionBasics_subscriptInt(threadData, _s1);
_i2 = omc_ExpressionBasics_subscriptInt(threadData, _s2);
_res = ((_i1 < _i2)?((modelica_integer) -1):((_i1 > _i2)?((modelica_integer) 1):((modelica_integer) 0)));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
}
}
if((!listEmpty(_ss)))
{
_res = ((modelica_integer) 1);
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
modelica_metatype boxptr_ComponentReferenceBasics_CompareWithIntSubscript_compareSubs(threadData_t *threadData, modelica_metatype _ss1, modelica_metatype _ss2)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_ComponentReferenceBasics_CompareWithIntSubscript_compareSubs(threadData, _ss1, _ss2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_integer omc_ComponentReferenceBasics_CompareWithoutSubscripts_compare(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _res;
modelica_integer tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _cr1;
tmp4_2 = _cr2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
goto _return;
tmp1 = omc_ComponentReferenceBasics_CompareWithoutSubscripts_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_cr1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 5)));
_cr2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 5)));
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = ((modelica_integer) 1);
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = ((modelica_integer) -1);
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
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
modelica_metatype boxptr_ComponentReferenceBasics_CompareWithoutSubscripts_compare(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_ComponentReferenceBasics_CompareWithoutSubscripts_compare(threadData, _cr1, _cr2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_integer omc_ComponentReferenceBasics_CompareWithoutSubscripts_compareSubs(threadData_t *threadData, modelica_metatype _ss1, modelica_metatype _ss2)
{
modelica_integer _res;
modelica_metatype _ss = NULL;
modelica_metatype _s2 = NULL;
modelica_integer _i1;
modelica_integer _i2;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = ((modelica_integer) 0);
_ss = _ss2;
{
modelica_metatype _s1;
for (tmpMeta1 = _ss1; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_s1 = MMC_CAR(tmpMeta1);
if(listEmpty(_ss))
{
_res = ((modelica_integer) -1);
goto _return;
}
tmpMeta2 = _ss;
if (listEmpty(tmpMeta2)) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_CAR(tmpMeta2);
tmpMeta4 = MMC_CDR(tmpMeta2);
_s2 = tmpMeta3;
_ss = tmpMeta4;
_i1 = omc_ExpressionBasics_subscriptInt(threadData, _s1);
_i2 = omc_ExpressionBasics_subscriptInt(threadData, _s2);
_res = ((_i1 < _i2)?((modelica_integer) -1):((_i1 > _i2)?((modelica_integer) 1):((modelica_integer) 0)));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
}
}
if((!listEmpty(_ss)))
{
_res = ((modelica_integer) 1);
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
modelica_metatype boxptr_ComponentReferenceBasics_CompareWithoutSubscripts_compareSubs(threadData_t *threadData, modelica_metatype _ss1, modelica_metatype _ss2)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_ComponentReferenceBasics_CompareWithoutSubscripts_compareSubs(threadData, _ss1, _ss2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_integer omc_ComponentReferenceBasics_CompareWithGenericSubscriptNotAlphabetic_compare(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _res;
modelica_integer tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _cr1;
tmp4_2 = _cr2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = omc_ComponentReferenceBasics_CompareWithGenericSubscriptNotAlphabetic_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_res = omc_ComponentReferenceBasics_CompareWithGenericSubscriptNotAlphabetic_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_cr1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 5)));
_cr2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 5)));
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_res = omc_ComponentReferenceBasics_CompareWithGenericSubscriptNotAlphabetic_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = ((modelica_integer) 1);
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_res = omc_ComponentReferenceBasics_CompareWithGenericSubscriptNotAlphabetic_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = ((modelica_integer) -1);
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
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
modelica_metatype boxptr_ComponentReferenceBasics_CompareWithGenericSubscriptNotAlphabetic_compare(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_ComponentReferenceBasics_CompareWithGenericSubscriptNotAlphabetic_compare(threadData, _cr1, _cr2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_integer omc_ComponentReferenceBasics_CompareWithGenericSubscriptNotAlphabetic_compareSubs(threadData_t *threadData, modelica_metatype _ss1, modelica_metatype _ss2)
{
modelica_integer _res;
modelica_metatype _ss = NULL;
modelica_metatype _s2 = NULL;
modelica_integer _i1;
modelica_integer _i2;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = ((modelica_integer) 0);
_ss = _ss2;
{
modelica_metatype _s1;
for (tmpMeta1 = _ss1; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_s1 = MMC_CAR(tmpMeta1);
if(listEmpty(_ss))
{
_res = ((modelica_integer) -1);
goto _return;
}
tmpMeta2 = _ss;
if (listEmpty(tmpMeta2)) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_CAR(tmpMeta2);
tmpMeta4 = MMC_CDR(tmpMeta2);
_s2 = tmpMeta3;
_ss = tmpMeta4;
_res = omc_ExpressionBasics_compareSubscripts(threadData, _s1, _s2);
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
}
}
if((!listEmpty(_ss)))
{
_res = ((modelica_integer) 1);
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
modelica_metatype boxptr_ComponentReferenceBasics_CompareWithGenericSubscriptNotAlphabetic_compareSubs(threadData_t *threadData, modelica_metatype _ss1, modelica_metatype _ss2)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_ComponentReferenceBasics_CompareWithGenericSubscriptNotAlphabetic_compareSubs(threadData, _ss1, _ss2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_integer omc_ComponentReferenceBasics_CompareWithGenericSubscript_compareSubs(threadData_t *threadData, modelica_metatype _ss1, modelica_metatype _ss2)
{
modelica_integer _res;
modelica_metatype _ss = NULL;
modelica_metatype _s2 = NULL;
modelica_integer _i1;
modelica_integer _i2;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = ((modelica_integer) 0);
_ss = _ss2;
{
modelica_metatype _s1;
for (tmpMeta1 = _ss1; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_s1 = MMC_CAR(tmpMeta1);
if(listEmpty(_ss))
{
_res = ((modelica_integer) -1);
goto _return;
}
tmpMeta2 = _ss;
if (listEmpty(tmpMeta2)) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_CAR(tmpMeta2);
tmpMeta4 = MMC_CDR(tmpMeta2);
_s2 = tmpMeta3;
_ss = tmpMeta4;
_res = stringCompare(omc_ExpressionBasics_printSubscriptStr(threadData, _s1), omc_ExpressionBasics_printSubscriptStr(threadData, _s2));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
}
}
if((!listEmpty(_ss)))
{
_res = ((modelica_integer) 1);
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
modelica_metatype boxptr_ComponentReferenceBasics_CompareWithGenericSubscript_compareSubs(threadData_t *threadData, modelica_metatype _ss1, modelica_metatype _ss2)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_ComponentReferenceBasics_CompareWithGenericSubscript_compareSubs(threadData, _ss1, _ss2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_integer omc_ComponentReferenceBasics_CompareWithGenericSubscript_compare(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _res;
modelica_integer tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _cr1;
tmp4_2 = _cr2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = omc_ComponentReferenceBasics_CompareWithGenericSubscript_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_res = omc_ComponentReferenceBasics_CompareWithGenericSubscript_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_cr1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 5)));
_cr2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 5)));
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_res = omc_ComponentReferenceBasics_CompareWithGenericSubscript_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = ((modelica_integer) 1);
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_res = omc_ComponentReferenceBasics_CompareWithGenericSubscript_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = ((modelica_integer) -1);
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
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
modelica_metatype boxptr_ComponentReferenceBasics_CompareWithGenericSubscript_compare(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_ComponentReferenceBasics_CompareWithGenericSubscript_compare(threadData, _cr1, _cr2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_string omc_ComponentReferenceBasics_crefFirstIdent(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_string _outIdent = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_string _id = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_id = tmpMeta6;
tmp1 = _id;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_id = tmpMeta7;
tmp1 = _id;
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
_outIdent = tmp1;
_return: OMC_LABEL_UNUSED
return _outIdent;
}
DLLDirection
modelica_boolean omc_ComponentReferenceBasics_crefFirstIdentEqual(threadData_t *threadData, modelica_metatype _inCref1, modelica_metatype _inCref2)
{
modelica_boolean _outEqual;
modelica_string _id1 = NULL;
modelica_string _id2 = NULL;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_id1 = omc_ComponentReferenceBasics_crefFirstIdent(threadData, _inCref1);
_id2 = omc_ComponentReferenceBasics_crefFirstIdent(threadData, _inCref2);
_outEqual = (stringEqual(_id1, _id2));
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _outEqual;
}
modelica_metatype boxptr_ComponentReferenceBasics_crefFirstIdentEqual(threadData_t *threadData, modelica_metatype _inCref1, modelica_metatype _inCref2)
{
modelica_boolean _outEqual;
modelica_metatype out_outEqual;
_outEqual = omc_ComponentReferenceBasics_crefFirstIdentEqual(threadData, _inCref1, _inCref2);
out_outEqual = mmc_mk_icon(_outEqual);
return out_outEqual;
}
DLLDirection
modelica_metatype omc_ComponentReferenceBasics_crefLastCref(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta1 = _inComponentRef;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_cr = tmpMeta6;
_inComponentRef = _cr;
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
_outComponentRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRef;
}
DLLDirection
modelica_string omc_ComponentReferenceBasics_crefLastIdent(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_string _outIdent = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_string _id = NULL;
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_id = tmpMeta6;
tmp1 = _id;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_cr = tmpMeta7;
_inComponentRef = _cr;
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
_outIdent = tmp1;
_return: OMC_LABEL_UNUSED
return _outIdent;
}
DLLDirection
modelica_metatype omc_ComponentReferenceBasics_crefFirstCref(threadData_t *threadData, modelica_metatype _inCr)
{
modelica_metatype _outCr = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCr;
{
modelica_string _id = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _t2 = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id = tmpMeta6;
_t2 = tmpMeta7;
_subs = tmpMeta8;
tmpMeta9 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _id, _t2, _subs);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta1 = _inCr;
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
_outCr = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCr;
}
DLLDirection
modelica_boolean omc_ComponentReferenceBasics_crefFirstCrefLastCrefEqual(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _equal;
modelica_metatype _pcr1 = NULL;
modelica_metatype _pcr2 = NULL;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_pcr1 = omc_ComponentReferenceBasics_crefFirstCref(threadData, _cr1);
_pcr2 = omc_ComponentReferenceBasics_crefLastCref(threadData, _cr2);
_equal = omc_ComponentReferenceBasics_crefEqual(threadData, _pcr1, _pcr2);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _equal;
}
modelica_metatype boxptr_ComponentReferenceBasics_crefFirstCrefLastCrefEqual(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_ComponentReferenceBasics_crefFirstCrefLastCrefEqual(threadData, _cr1, _cr2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLDirection
modelica_boolean omc_ComponentReferenceBasics_crefFirstCrefEqual(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _equal;
modelica_metatype _pcr1 = NULL;
modelica_metatype _pcr2 = NULL;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_pcr1 = omc_ComponentReferenceBasics_crefFirstCref(threadData, _cr1);
_pcr2 = omc_ComponentReferenceBasics_crefFirstCref(threadData, _cr2);
_equal = omc_ComponentReferenceBasics_crefEqual(threadData, _pcr1, _pcr2);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _equal;
}
modelica_metatype boxptr_ComponentReferenceBasics_crefFirstCrefEqual(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_ComponentReferenceBasics_crefFirstCrefEqual(threadData, _cr1, _cr2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLDirection
modelica_boolean omc_ComponentReferenceBasics_crefLastIdentEqual(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _equal;
modelica_string _id1 = NULL;
modelica_string _id2 = NULL;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_id1 = omc_ComponentReferenceBasics_crefLastIdent(threadData, _cr1);
_id2 = omc_ComponentReferenceBasics_crefLastIdent(threadData, _cr2);
_equal = (stringEqual(_id1, _id2));
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _equal;
}
modelica_metatype boxptr_ComponentReferenceBasics_crefLastIdentEqual(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_ComponentReferenceBasics_crefLastIdentEqual(threadData, _cr1, _cr2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLDirection
modelica_metatype omc_ComponentReferenceBasics_crefSubs(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_metatype _outSubscriptLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_metatype _subs = NULL;
modelica_metatype _res = NULL;
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_subs = tmpMeta6;
tmpMeta1 = _subs;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_subs = tmpMeta7;
_cr = tmpMeta8;
_res = omc_ComponentReferenceBasics_crefSubs(threadData, _cr);
tmpMeta1 = listAppend(_subs, _res);
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
_outSubscriptLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outSubscriptLst;
}
DLLDirection
modelica_metatype omc_ComponentReferenceBasics_crefDims(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_metatype _outDimensionLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_metatype _dims = NULL;
modelica_metatype _res = NULL;
modelica_metatype _idType = NULL;
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_idType = tmpMeta6;
tmpMeta1 = omc_TypesDump_getDimensions(threadData, _idType);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_idType = tmpMeta7;
_cr = tmpMeta8;
_dims = omc_TypesDump_getDimensions(threadData, _idType);
_res = omc_ComponentReferenceBasics_crefDims(threadData, _cr);
tmpMeta1 = listAppend(_dims, _res);
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
_outDimensionLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outDimensionLst;
}
