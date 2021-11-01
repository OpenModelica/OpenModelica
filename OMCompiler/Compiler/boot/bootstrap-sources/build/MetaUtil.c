#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "MetaUtil.c"
#endif
#include "omc_simulation_settings.h"
#include "MetaUtil.h"
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT0,2,25) {&Absyn_Exp_LIST__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT0 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT2,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT2 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "Records inside uniontypes must not contain type variables (got: %s). Put them on the uniontype instead."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,103,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT3}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(5043)),_OMC_LIT1,_OMC_LIT2,_OMC_LIT4}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data ","
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,1,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#include "util/modelica.h"
#include "MetaUtil_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MetaUtil_fixElementItems(threadData_t *threadData, modelica_metatype _inElementItems, modelica_string _inName, modelica_metatype _typeVars, modelica_metatype *out_outMetaClasses);
static const MMC_DEFSTRUCTLIT(boxvar_lit_MetaUtil_fixElementItems,2,0) {(void*) boxptr_MetaUtil_fixElementItems,0}};
#define boxvar_MetaUtil_fixElementItems MMC_REFSTRUCTLIT(boxvar_lit_MetaUtil_fixElementItems)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MetaUtil_fixClassParts(threadData_t *threadData, modelica_metatype _inClassParts, modelica_string _inClassName, modelica_metatype _typeVars, modelica_metatype *out_outMetaClasses);
static const MMC_DEFSTRUCTLIT(boxvar_lit_MetaUtil_fixClassParts,2,0) {(void*) boxptr_MetaUtil_fixClassParts,0}};
#define boxvar_MetaUtil_fixClassParts MMC_REFSTRUCTLIT(boxvar_lit_MetaUtil_fixClassParts)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MetaUtil_convertElementToClass(threadData_t *threadData, modelica_metatype _inElementItem);
static const MMC_DEFSTRUCTLIT(boxvar_lit_MetaUtil_convertElementToClass,2,0) {(void*) boxptr_MetaUtil_convertElementToClass,0}};
#define boxvar_MetaUtil_convertElementToClass MMC_REFSTRUCTLIT(boxvar_lit_MetaUtil_convertElementToClass)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MetaUtil_setElementItemClass(threadData_t *threadData, modelica_metatype _inElementItem, modelica_metatype _inClass);
static const MMC_DEFSTRUCTLIT(boxvar_lit_MetaUtil_setElementItemClass,2,0) {(void*) boxptr_MetaUtil_setElementItemClass,0}};
#define boxvar_MetaUtil_setElementItemClass MMC_REFSTRUCTLIT(boxvar_lit_MetaUtil_setElementItemClass)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MetaUtil_createMetaClassesFromElementItems(threadData_t *threadData, modelica_metatype _inElementItems);
static const MMC_DEFSTRUCTLIT(boxvar_lit_MetaUtil_createMetaClassesFromElementItems,2,0) {(void*) boxptr_MetaUtil_createMetaClassesFromElementItems,0}};
#define boxvar_MetaUtil_createMetaClassesFromElementItems MMC_REFSTRUCTLIT(boxvar_lit_MetaUtil_createMetaClassesFromElementItems)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MetaUtil_createMetaClassesFromClassParts(threadData_t *threadData, modelica_metatype _inClassParts);
static const MMC_DEFSTRUCTLIT(boxvar_lit_MetaUtil_createMetaClassesFromClassParts,2,0) {(void*) boxptr_MetaUtil_createMetaClassesFromClassParts,0}};
#define boxvar_MetaUtil_createMetaClassesFromClassParts MMC_REFSTRUCTLIT(boxvar_lit_MetaUtil_createMetaClassesFromClassParts)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MetaUtil_createMetaClasses(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype *out_outMetaClasses);
static const MMC_DEFSTRUCTLIT(boxvar_lit_MetaUtil_createMetaClasses,2,0) {(void*) boxptr_MetaUtil_createMetaClasses,0}};
#define boxvar_MetaUtil_createMetaClasses MMC_REFSTRUCTLIT(boxvar_lit_MetaUtil_createMetaClasses)
DLLExport
modelica_metatype omc_MetaUtil_transformArrayNodesToListNodes(threadData_t *threadData, modelica_metatype _inList)
{
modelica_metatype _outList = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype __omcQ_24tmpVar0;
modelica_integer tmp11;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _inList;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar1;
while(1) {
tmp11 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp11--;
}
if (tmp11 == 0) {
{
modelica_metatype tmp7_1;
tmp7_1 = _e;
{
volatile mmc_switch_type tmp7;
int tmp8;
tmp7 = 0;
for (; tmp7 < 3; tmp7++) {
switch (MMC_SWITCH_CAST(tmp7)) {
case 0: {
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,13,1) == 0) goto tmp6_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
if (!listEmpty(tmpMeta9)) goto tmp6_end;
tmpMeta4 = _OMC_LIT0;
goto tmp6_done;
}
case 1: {
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,13,1) == 0) goto tmp6_end;
tmpMeta10 = mmc_mk_box2(25, &Absyn_Exp_LIST__desc, omc_MetaUtil_transformArrayNodesToListNodes(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 2)))));
tmpMeta4 = tmpMeta10;
goto tmp6_done;
}
case 2: {
tmpMeta4 = _e;
goto tmp6_done;
}
}
goto tmp6_end;
tmp6_end: ;
}
goto goto_5;
goto_5:;
MMC_THROW_INTERNAL();
goto tmp6_done;
tmp6_done:;
}
}__omcQ_24tmpVar0 = tmpMeta4;
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp11 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar1;
}
_outList = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outList;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MetaUtil_fixElementItems(threadData_t *threadData, modelica_metatype _inElementItems, modelica_string _inName, modelica_metatype _typeVars, modelica_metatype *out_outMetaClasses)
{
modelica_metatype _outElementItems = NULL;
modelica_metatype _outMetaClasses = NULL;
modelica_metatype tmpMeta1;
modelica_integer _index;
modelica_boolean _singleton;
modelica_integer tmp2;
modelica_metatype _c = NULL;
modelica_metatype _r = NULL;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outMetaClasses = tmpMeta1;
_index = ((modelica_integer) 0);
{
modelica_integer __omcQ_24tmpVar3;
modelica_integer __omcQ_24tmpVar2;
modelica_integer tmp3;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _inElementItems;
__omcQ_24tmpVar3 = ((modelica_integer) 0);
while(1) {
tmp3 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp3--;
}
if (tmp3 == 0) {
__omcQ_24tmpVar2 = (omc_AbsynUtil_isElementItem(threadData, _e)?((modelica_integer) 1):((modelica_integer) 0));
__omcQ_24tmpVar3 = __omcQ_24tmpVar3 + __omcQ_24tmpVar2;
} else if (tmp3 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
tmp2 = __omcQ_24tmpVar3;
}
_singleton = (tmp2 == ((modelica_integer) 1));
{
modelica_metatype __omcQ_24tmpVar5;
modelica_metatype* tmp5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype __omcQ_24tmpVar4;
modelica_integer tmp31;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _inElementItems;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar5 = tmpMeta6;
tmp5 = &__omcQ_24tmpVar5;
while(1) {
tmp31 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp31--;
}
if (tmp31 == 0) {
{
modelica_metatype tmp10_1;
tmp10_1 = _e;
{
modelica_metatype _body = NULL;
volatile mmc_switch_type tmp10;
int tmp11;
tmp10 = 0;
for (; tmp10 < 2; tmp10++) {
switch (MMC_SWITCH_CAST(tmp10)) {
case 0: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
if (mmc__uniontype__metarecord__typedef__equal(tmp10_1,0,1) == 0) goto tmp9_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp10_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,0,6) == 0) goto tmp9_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,0,2) == 0) goto tmp9_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 3));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,3,0) == 0) goto tmp9_end;
_c = tmpMeta14;
_body = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_c), 7)));
{
modelica_metatype tmp18_1;
tmp18_1 = _body;
{
volatile mmc_switch_type tmp18;
int tmp19;
tmp18 = 0;
for (; tmp18 < 2; tmp18++) {
switch (MMC_SWITCH_CAST(tmp18)) {
case 0: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp18_1,0,5) == 0) goto tmp17_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp18_1), 2));
if (listEmpty(tmpMeta20)) goto tmp17_end;
tmpMeta21 = MMC_CAR(tmpMeta20);
tmpMeta22 = MMC_CDR(tmpMeta20);
tmpMeta23 = mmc_mk_cons(stringDelimitList((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_body), 2))), _OMC_LIT6), MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT5, tmpMeta23, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_c), 8))));
goto goto_16;
goto tmp17_done;
}
case 1: {
goto tmp17_done;
}
}
goto tmp17_end;
tmp17_end: ;
}
goto goto_16;
goto_16:;
goto goto_8;
goto tmp17_done;
tmp17_done:;
}
}
;
tmpMeta24 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _inName);
tmpMeta25 = mmc_mk_box6(23, &Absyn_Restriction_R__METARECORD__desc, tmpMeta24, mmc_mk_integer(_index), mmc_mk_boolean(_singleton), mmc_mk_boolean(1), _typeVars);
_r = tmpMeta25;
tmpMeta26 = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta26), MMC_UNTAGPTR(_c), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta26))[6] = _r;
_c = tmpMeta26;
tmpMeta27 = mmc_mk_cons(_c, _outMetaClasses);
_outMetaClasses = tmpMeta27;
tmpMeta28 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _inName);
tmpMeta29 = mmc_mk_box6(23, &Absyn_Restriction_R__METARECORD__desc, tmpMeta28, mmc_mk_integer(_index), mmc_mk_boolean(_singleton), mmc_mk_boolean(0), _typeVars);
_r = tmpMeta29;
tmpMeta30 = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta30), MMC_UNTAGPTR(_c), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta30))[6] = _r;
_c = tmpMeta30;
_index = ((modelica_integer) 1) + _index;
tmpMeta7 = omc_MetaUtil_setElementItemClass(threadData, _e, _c);
goto tmp9_done;
}
case 1: {
tmpMeta7 = _e;
goto tmp9_done;
}
}
goto tmp9_end;
tmp9_end: ;
}
goto goto_8;
goto_8:;
MMC_THROW_INTERNAL();
goto tmp9_done;
tmp9_done:;
}
}__omcQ_24tmpVar4 = tmpMeta7;
*tmp5 = mmc_mk_cons(__omcQ_24tmpVar4,0);
tmp5 = &MMC_CDR(*tmp5);
} else if (tmp31 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp5 = mmc_mk_nil();
tmpMeta4 = __omcQ_24tmpVar5;
}
_outElementItems = tmpMeta4;
_return: OMC_LABEL_UNUSED
if (out_outMetaClasses) { *out_outMetaClasses = _outMetaClasses; }
return _outElementItems;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MetaUtil_fixClassParts(threadData_t *threadData, modelica_metatype _inClassParts, modelica_string _inClassName, modelica_metatype _typeVars, modelica_metatype *out_outMetaClasses)
{
modelica_metatype _outClassParts = NULL;
modelica_metatype _outMetaClasses = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _meta_classes = NULL;
modelica_metatype _els = NULL;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outMetaClasses = tmpMeta1;
{
modelica_metatype __omcQ_24tmpVar7;
modelica_metatype* tmp3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype __omcQ_24tmpVar6;
modelica_integer tmp11;
modelica_metatype _p_loopVar = 0;
modelica_metatype _p;
_p_loopVar = _inClassParts;
tmpMeta4 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar7 = tmpMeta4;
tmp3 = &__omcQ_24tmpVar7;
while(1) {
tmp11 = 1;
if (!listEmpty(_p_loopVar)) {
_p = MMC_CAR(_p_loopVar);
_p_loopVar = MMC_CDR(_p_loopVar);
tmp11--;
}
if (tmp11 == 0) {
{
modelica_metatype tmp8_1;
tmp8_1 = _p;
{
int tmp8;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp8_1))) {
case 3: {
modelica_metatype tmpMeta9;
_els = omc_MetaUtil_fixElementItems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2))), _inClassName, _typeVars ,&_meta_classes);
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_p), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[2] = _els;
_p = tmpMeta9;
_outMetaClasses = listAppend(_meta_classes, _outMetaClasses);
tmpMeta5 = _p;
goto tmp7_done;
}
case 4: {
modelica_metatype tmpMeta10;
_els = omc_MetaUtil_fixElementItems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2))), _inClassName, _typeVars ,&_meta_classes);
tmpMeta10 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta10), MMC_UNTAGPTR(_p), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta10))[2] = _els;
_p = tmpMeta10;
_outMetaClasses = listAppend(_meta_classes, _outMetaClasses);
tmpMeta5 = _p;
goto tmp7_done;
}
default:
tmp7_default: OMC_LABEL_UNUSED; {
tmpMeta5 = _p;
goto tmp7_done;
}
}
goto tmp7_end;
tmp7_end: ;
}
goto goto_6;
goto_6:;
MMC_THROW_INTERNAL();
goto tmp7_done;
tmp7_done:;
}
}__omcQ_24tmpVar6 = tmpMeta5;
*tmp3 = mmc_mk_cons(__omcQ_24tmpVar6,0);
tmp3 = &MMC_CDR(*tmp3);
} else if (tmp11 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp3 = mmc_mk_nil();
tmpMeta2 = __omcQ_24tmpVar7;
}
_outClassParts = tmpMeta2;
_return: OMC_LABEL_UNUSED
if (out_outMetaClasses) { *out_outMetaClasses = _outMetaClasses; }
return _outClassParts;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MetaUtil_convertElementToClass(threadData_t *threadData, modelica_metatype _inElementItem)
{
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inElementItem;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,0,1) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta2,0,6) == 0) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta3,0,2) == 0) MMC_THROW_INTERNAL();
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 3));
_outClass = tmpMeta4;
_return: OMC_LABEL_UNUSED
return _outClass;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MetaUtil_setElementItemClass(threadData_t *threadData, modelica_metatype _inElementItem, modelica_metatype _inClass)
{
modelica_metatype _outElementItem = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outElementItem = _inElementItem;
{
modelica_metatype tmp4_1;
tmp4_1 = _outElementItem;
{
modelica_metatype _e = NULL;
modelica_metatype _es = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,6) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,2) == 0) goto tmp3_end;
_e = tmpMeta6;
_es = tmpMeta7;
tmpMeta8 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta8), MMC_UNTAGPTR(_es), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta8))[3] = _inClass;
_es = tmpMeta8;
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_e), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[5] = _es;
_e = tmpMeta9;
tmpMeta10 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta10), MMC_UNTAGPTR(_outElementItem), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta10))[2] = _e;
_outElementItem = tmpMeta10;
tmpMeta1 = _outElementItem;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _outElementItem;
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
_outElementItem = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outElementItem;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MetaUtil_createMetaClassesFromElementItems(threadData_t *threadData, modelica_metatype _inElementItems)
{
modelica_metatype _outElementItems = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _cls = NULL;
modelica_metatype _meta_classes = NULL;
modelica_metatype _els = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outElementItems = tmpMeta1;
{
modelica_metatype _e;
for (tmpMeta2 = listReverse(_inElementItems); !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_e = MMC_CAR(tmpMeta2);
{
modelica_metatype tmp6_1;
tmp6_1 = _e;
{
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
for (; tmp6 < 2; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,1) == 0) goto tmp5_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,6) == 0) goto tmp5_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,0,2) == 0) goto tmp5_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 3));
_cls = tmpMeta10;
_cls = omc_MetaUtil_createMetaClasses(threadData, _cls ,&_meta_classes);
{
modelica_metatype __omcQ_24tmpVar9;
modelica_metatype* tmp12;
modelica_metatype tmpMeta13;
modelica_metatype __omcQ_24tmpVar8;
modelica_integer tmp14;
modelica_metatype _c_loopVar = 0;
modelica_metatype _c;
_c_loopVar = _meta_classes;
tmpMeta13 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar9 = tmpMeta13;
tmp12 = &__omcQ_24tmpVar9;
while(1) {
tmp14 = 1;
if (!listEmpty(_c_loopVar)) {
_c = MMC_CAR(_c_loopVar);
_c_loopVar = MMC_CDR(_c_loopVar);
tmp14--;
}
if (tmp14 == 0) {
__omcQ_24tmpVar8 = omc_MetaUtil_setElementItemClass(threadData, _e, _c);
*tmp12 = mmc_mk_cons(__omcQ_24tmpVar8,0);
tmp12 = &MMC_CDR(*tmp12);
} else if (tmp14 == 1) {
break;
} else {
goto goto_4;
}
}
*tmp12 = mmc_mk_nil();
tmpMeta11 = __omcQ_24tmpVar9;
}
_els = tmpMeta11;
_outElementItems = listAppend(_els, _outElementItems);
tmpMeta3 = omc_MetaUtil_setElementItemClass(threadData, _e, _cls);
goto tmp5_done;
}
case 1: {
tmpMeta3 = _e;
goto tmp5_done;
}
}
goto tmp5_end;
tmp5_end: ;
}
goto goto_4;
goto_4:;
MMC_THROW_INTERNAL();
goto tmp5_done;
tmp5_done:;
}
}
_e = tmpMeta3;
tmpMeta15 = mmc_mk_cons(_e, _outElementItems);
_outElementItems = tmpMeta15;
}
}
_return: OMC_LABEL_UNUSED
return _outElementItems;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MetaUtil_createMetaClassesFromClassParts(threadData_t *threadData, modelica_metatype _inClassParts)
{
modelica_metatype _outClassParts = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar11;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype __omcQ_24tmpVar10;
modelica_integer tmp10;
modelica_metatype _p_loopVar = 0;
modelica_metatype _p;
_p_loopVar = _inClassParts;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar11 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar11;
while(1) {
tmp10 = 1;
if (!listEmpty(_p_loopVar)) {
_p = MMC_CAR(_p_loopVar);
_p_loopVar = MMC_CDR(_p_loopVar);
tmp10--;
}
if (tmp10 == 0) {
{
modelica_metatype tmp7_1;
tmp7_1 = _p;
{
int tmp7;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp7_1))) {
case 3: {
modelica_metatype tmpMeta8;
tmpMeta8 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta8), MMC_UNTAGPTR(_p), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta8))[2] = omc_MetaUtil_createMetaClassesFromElementItems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2))));
_p = tmpMeta8;
tmpMeta4 = _p;
goto tmp6_done;
}
case 4: {
modelica_metatype tmpMeta9;
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_p), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[2] = omc_MetaUtil_createMetaClassesFromElementItems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2))));
_p = tmpMeta9;
tmpMeta4 = _p;
goto tmp6_done;
}
default:
tmp6_default: OMC_LABEL_UNUSED; {
tmpMeta4 = _p;
goto tmp6_done;
}
}
goto tmp6_end;
tmp6_end: ;
}
goto goto_5;
goto_5:;
MMC_THROW_INTERNAL();
goto tmp6_done;
tmp6_done:;
}
}__omcQ_24tmpVar10 = tmpMeta4;
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar10,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp10 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar11;
}
_outClassParts = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outClassParts;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MetaUtil_createMetaClasses(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype *out_outMetaClasses)
{
modelica_metatype _outClass = NULL;
modelica_metatype _outMetaClasses = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _body = NULL;
modelica_metatype _parts = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outClass = _inClass;
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outMetaClasses = tmpMeta1;
{
modelica_metatype tmp4_1;
tmp4_1 = _outClass;
{
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,19,0) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,5) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
_body = tmpMeta7;
_parts = tmpMeta8;
_parts = omc_MetaUtil_fixClassParts(threadData, _parts, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outClass), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_body), 2))) ,&_outMetaClasses);
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_body), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[4] = _parts;
_body = tmpMeta9;
tmpMeta10 = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta10), MMC_UNTAGPTR(_outClass), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta10))[7] = _body;
_outClass = tmpMeta10;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,19,0) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,4,5) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 5));
_body = tmpMeta12;
_parts = tmpMeta13;
tmpMeta14 = MMC_REFSTRUCTLIT(mmc_nil);
_parts = omc_MetaUtil_fixClassParts(threadData, _parts, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outClass), 2))), tmpMeta14 ,&_outMetaClasses);
tmpMeta15 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta15), MMC_UNTAGPTR(_body), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta15))[5] = _parts;
_body = tmpMeta15;
tmpMeta16 = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta16), MMC_UNTAGPTR(_outClass), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta16))[7] = _body;
_outClass = tmpMeta16;
goto tmp3_done;
}
case 2: {
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
;
{
modelica_metatype tmp19_1;
tmp19_1 = _outClass;
{
volatile mmc_switch_type tmp19;
int tmp20;
tmp19 = 0;
for (; tmp19 < 3; tmp19++) {
switch (MMC_SWITCH_CAST(tmp19)) {
case 0: {
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp19_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta21,0,5) == 0) goto tmp18_end;
_body = tmpMeta21;
tmpMeta22 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta22), MMC_UNTAGPTR(_body), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta22))[4] = omc_MetaUtil_createMetaClassesFromClassParts(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_body), 4))));
_body = tmpMeta22;
tmpMeta23 = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta23), MMC_UNTAGPTR(_outClass), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta23))[7] = _body;
_outClass = tmpMeta23;
goto tmp18_done;
}
case 1: {
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp19_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta24,4,5) == 0) goto tmp18_end;
_body = tmpMeta24;
tmpMeta25 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta25), MMC_UNTAGPTR(_body), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta25))[5] = omc_MetaUtil_createMetaClassesFromClassParts(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_body), 5))));
_body = tmpMeta25;
tmpMeta26 = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta26), MMC_UNTAGPTR(_outClass), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta26))[7] = _body;
_outClass = tmpMeta26;
goto tmp18_done;
}
case 2: {
goto tmp18_done;
}
}
goto tmp18_end;
tmp18_end: ;
}
goto goto_17;
goto_17:;
MMC_THROW_INTERNAL();
goto tmp18_done;
tmp18_done:;
}
}
;
_return: OMC_LABEL_UNUSED
if (out_outMetaClasses) { *out_outMetaClasses = _outMetaClasses; }
return _outClass;
}
DLLExport
modelica_metatype omc_MetaUtil_createMetaClassesInProgram(threadData_t *threadData, modelica_metatype _inProgram)
{
modelica_metatype _outProgram = NULL;
modelica_metatype _classes = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _meta_classes = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outProgram = _inProgram;
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_classes = tmpMeta1;
if((!omc_Config_acceptMetaModelicaGrammar(threadData)))
{
goto _return;
}
{
modelica_metatype tmp4_1;
tmp4_1 = _outProgram;
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
modelica_metatype tmpMeta9;
{
modelica_metatype _c;
for (tmpMeta6 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outProgram), 2))); !listEmpty(tmpMeta6); tmpMeta6=MMC_CDR(tmpMeta6))
{
_c = MMC_CAR(tmpMeta6);
_c = omc_MetaUtil_createMetaClasses(threadData, _c ,&_meta_classes);
tmpMeta7 = mmc_mk_cons(_c, listAppend(_meta_classes, _classes));
_classes = tmpMeta7;
}
}
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_outProgram), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[2] = listReverseInPlace(_classes);
_outProgram = tmpMeta9;
goto tmp3_done;
}
case 1: {
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
;
_return: OMC_LABEL_UNUSED
return _outProgram;
}
