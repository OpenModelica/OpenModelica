#include "omc_simulation_settings.h"
#include "DAEDumpTypes.h"
#define _OMC_LIT0_data "Evaluate"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,8,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "Inline"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,6,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "LateInline"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,10,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "derivative"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,10,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "inverse"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,7,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "smoothOrder"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,11,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "InlineAfterIndexReduction"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,25,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "GenerateEvents"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,14,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,0,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "annotation"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,10,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,10,3) {&SCodeDump_SCodeDumpOptions_OPTIONS__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0 /* false */)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0 /* false */)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0 /* false */)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0 /* false */)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1 /* true */)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1 /* true */)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0 /* false */)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0 /* false */)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0 /* false */))}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data " "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,1,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "  "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,2,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data ";\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,2,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data " \""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,2,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data "\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,1,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
#include "util/modelica.h"
#include "DAEDumpTypes_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_boolean omc_DAEDumpTypes_filterStructuralMod(threadData_t *threadData, modelica_metatype _mod);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEDumpTypes_filterStructuralMod(threadData_t *threadData, modelica_metatype _mod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEDumpTypes_filterStructuralMod,2,0) {(void*) boxptr_DAEDumpTypes_filterStructuralMod,0}};
#define boxvar_DAEDumpTypes_filterStructuralMod MMC_REFSTRUCTLIT(boxvar_lit_DAEDumpTypes_filterStructuralMod)
PROTECTED_FUNCTION_STATIC modelica_string omc_DAEDumpTypes_dumpAnnotationStr(threadData_t *threadData, modelica_metatype _inComment, modelica_string _inPrefix, modelica_string _inSuffix);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEDumpTypes_dumpAnnotationStr,2,0) {(void*) boxptr_DAEDumpTypes_dumpAnnotationStr,0}};
#define boxvar_DAEDumpTypes_dumpAnnotationStr MMC_REFSTRUCTLIT(boxvar_lit_DAEDumpTypes_dumpAnnotationStr)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_DAEDumpTypes_filterStructuralMod(threadData_t *threadData, modelica_metatype _mod)
{
modelica_boolean _keep;
modelica_boolean tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_mod), 2)));
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 9; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (8 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT0), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (6 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT1), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
if (10 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT2), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
if (10 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT3), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 4: {
if (7 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT4), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 5: {
if (11 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT5), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 6: {
if (25 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT6), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 7: {
if (14 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
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
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_keep = tmp1;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _keep;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEDumpTypes_filterStructuralMod(threadData_t *threadData, modelica_metatype _mod)
{
modelica_boolean _keep;
modelica_metatype out_keep;
_keep = omc_DAEDumpTypes_filterStructuralMod(threadData, _mod);
out_keep = mmc_mk_icon(_keep);
return out_keep;
}
DLLDirection
modelica_metatype omc_DAEDumpTypes_filterStructuralMods(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fmod)
{
modelica_metatype _mod = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_mod = __omcQ_24in_5Fmod;
_mod = omc_SCodeUtil_filterSubMods(threadData, _mod, boxvar_DAEDumpTypes_filterStructuralMod);
_return: OMC_LABEL_UNUSED
return _mod;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_DAEDumpTypes_dumpAnnotationStr(threadData_t *threadData, modelica_metatype _inComment, modelica_string _inPrefix, modelica_string _inSuffix)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inComment;
{
modelica_string _ann = NULL;
modelica_metatype _ann_mod = NULL;
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
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (optionNone(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
_ann_mod = tmpMeta9;
if(omc_Config_showAnnotations(threadData))
{
tmpMeta10 = stringAppend(_inPrefix,_OMC_LIT9);
tmpMeta11 = stringAppend(tmpMeta10,omc_SCodeDump_printModStr(threadData, _ann_mod, _OMC_LIT10));
tmpMeta12 = stringAppend(tmpMeta11,_inSuffix);
_ann = tmpMeta12;
}
else
{
if(omc_Config_showStructuralAnnotations(threadData))
{
_ann_mod = omc_DAEDumpTypes_filterStructuralMods(threadData, _ann_mod);
if((!omc_SCodeUtil_isEmptyMod(threadData, _ann_mod)))
{
tmpMeta13 = stringAppend(_inPrefix,_OMC_LIT9);
tmpMeta14 = stringAppend(tmpMeta13,omc_SCodeDump_printModStr(threadData, _ann_mod, _OMC_LIT10));
tmpMeta15 = stringAppend(tmpMeta14,_inSuffix);
_ann = tmpMeta15;
}
else
{
_ann = _OMC_LIT8;
}
}
else
{
_ann = _OMC_LIT8;
}
}
tmp1 = _ann;
goto tmp3_done;
}
case 1: {
tmp1 = _OMC_LIT8;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLDirection
modelica_string omc_DAEDumpTypes_dumpCompAnnotationStr(threadData_t *threadData, modelica_metatype _inComment)
{
modelica_string _outString = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outString = omc_DAEDumpTypes_dumpAnnotationStr(threadData, _inComment, _OMC_LIT11, _OMC_LIT8);
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLDirection
modelica_string omc_DAEDumpTypes_dumpCommentAnnotationStr(threadData_t *threadData, modelica_metatype _inComment)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComment;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
tmp1 = _OMC_LIT8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
tmpMeta6 = stringAppend(omc_DAEDumpTypes_dumpCommentStr(threadData, _inComment),omc_DAEDumpTypes_dumpCompAnnotationStr(threadData, _inComment));
tmp1 = tmpMeta6;
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
modelica_string omc_DAEDumpTypes_dumpClassAnnotationStr(threadData_t *threadData, modelica_metatype _inComment)
{
modelica_string _outString = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outString = omc_DAEDumpTypes_dumpAnnotationStr(threadData, _inComment, _OMC_LIT12, _OMC_LIT13);
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLDirection
modelica_string omc_DAEDumpTypes_dumpCommentStr(threadData_t *threadData, modelica_metatype _inComment)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComment;
{
modelica_string _cmt = NULL;
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
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
if (optionNone(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
_cmt = tmpMeta8;
_cmt = omc_System_escapedString(threadData, _cmt, 0 /* false */);
tmpMeta9 = mmc_mk_cons(_OMC_LIT14, mmc_mk_cons(_cmt, mmc_mk_cons(_OMC_LIT15, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta9);
goto tmp3_done;
}
case 1: {
tmp1 = _OMC_LIT8;
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
