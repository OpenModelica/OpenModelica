#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/MetaUtil.c"
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
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp1;
modelica_metatype __omcQ_24tmpVar0;
int tmp6;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _inList;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta[1];
tmp1 = &__omcQ_24tmpVar1;
while(1) {
tmp6 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp6--;
}
if (tmp6 == 0) {
{
modelica_metatype tmp4_1;
tmp4_1 = _e;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta[3])) goto tmp3_end;
tmpMeta[2] = _OMC_LIT0;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,1) == 0) goto tmp3_end;
tmpMeta[3] = mmc_mk_box2(25, &Absyn_Exp_LIST__desc, omc_MetaUtil_transformArrayNodesToListNodes(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 2)))));
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
case 2: {
tmpMeta[2] = _e;
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
}__omcQ_24tmpVar0 = tmpMeta[2];
*tmp1 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp1 = &MMC_CDR(*tmp1);
} else if (tmp6 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp1 = mmc_mk_nil();
tmpMeta[0] = __omcQ_24tmpVar1;
}
_outList = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outList;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MetaUtil_fixElementItems(threadData_t *threadData, modelica_metatype _inElementItems, modelica_string _inName, modelica_metatype _typeVars, modelica_metatype *out_outMetaClasses)
{
modelica_metatype _outElementItems = NULL;
modelica_metatype _outMetaClasses = NULL;
modelica_integer _index;
modelica_boolean _singleton;
modelica_integer tmp1;
modelica_metatype _c = NULL;
modelica_metatype _r = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outMetaClasses = tmpMeta[0];
_index = ((modelica_integer) 0);
{
modelica_integer __omcQ_24tmpVar3;
modelica_integer __omcQ_24tmpVar2;
int tmp2;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _inElementItems;
__omcQ_24tmpVar3 = ((modelica_integer) 0);
while(1) {
tmp2 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp2--;
}
if (tmp2 == 0) {
__omcQ_24tmpVar2 = (omc_AbsynUtil_isElementItem(threadData, _e)?((modelica_integer) 1):((modelica_integer) 0));
__omcQ_24tmpVar3 = __omcQ_24tmpVar3 + __omcQ_24tmpVar2;
} else if (tmp2 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
tmp1 = __omcQ_24tmpVar3;
}
_singleton = (tmp1 == ((modelica_integer) 1));
{
modelica_metatype __omcQ_24tmpVar5;
modelica_metatype* tmp3;
modelica_metatype __omcQ_24tmpVar4;
int tmp12;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _inElementItems;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar5 = tmpMeta[2];
tmp3 = &__omcQ_24tmpVar5;
while(1) {
tmp12 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp12--;
}
if (tmp12 == 0) {
{
modelica_metatype tmp6_1;
tmp6_1 = _e;
{
modelica_metatype _body = NULL;
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
for (; tmp6 < 2; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,1) == 0) goto tmp5_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,6) == 0) goto tmp5_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],0,2) == 0) goto tmp5_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],3,0) == 0) goto tmp5_end;
_c = tmpMeta[6];
_body = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_c), 7)));
{
modelica_metatype tmp10_1;
tmp10_1 = _body;
{
volatile mmc_switch_type tmp10;
int tmp11;
tmp10 = 0;
for (; tmp10 < 2; tmp10++) {
switch (MMC_SWITCH_CAST(tmp10)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp10_1,0,5) == 0) goto tmp9_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp10_1), 2));
if (listEmpty(tmpMeta[4])) goto tmp9_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
tmpMeta[4] = mmc_mk_cons(stringDelimitList((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_body), 2))), _OMC_LIT6), MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT5, tmpMeta[4], (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_c), 8))));
goto goto_8;
goto tmp9_done;
}
case 1: {
goto tmp9_done;
}
}
goto tmp9_end;
tmp9_end: ;
}
goto goto_8;
goto_8:;
goto goto_4;
goto tmp9_done;
tmp9_done:;
}
}
;
tmpMeta[4] = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _inName);
tmpMeta[5] = mmc_mk_box6(23, &Absyn_Restriction_R__METARECORD__desc, tmpMeta[4], mmc_mk_integer(_index), mmc_mk_boolean(_singleton), mmc_mk_boolean(1), _typeVars);
_r = tmpMeta[5];
tmpMeta[4] = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta[4]), MMC_UNTAGPTR(_c), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[4]))[6] = _r;
_c = tmpMeta[4];
tmpMeta[4] = mmc_mk_cons(_c, _outMetaClasses);
_outMetaClasses = tmpMeta[4];
tmpMeta[4] = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _inName);
tmpMeta[5] = mmc_mk_box6(23, &Absyn_Restriction_R__METARECORD__desc, tmpMeta[4], mmc_mk_integer(_index), mmc_mk_boolean(_singleton), mmc_mk_boolean(0), _typeVars);
_r = tmpMeta[5];
tmpMeta[4] = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta[4]), MMC_UNTAGPTR(_c), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[4]))[6] = _r;
_c = tmpMeta[4];
_index = ((modelica_integer) 1) + _index;
tmpMeta[3] = omc_MetaUtil_setElementItemClass(threadData, _e, _c);
goto tmp5_done;
}
case 1: {
tmpMeta[3] = _e;
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
}__omcQ_24tmpVar4 = tmpMeta[3];
*tmp3 = mmc_mk_cons(__omcQ_24tmpVar4,0);
tmp3 = &MMC_CDR(*tmp3);
} else if (tmp12 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp3 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar5;
}
_outElementItems = tmpMeta[1];
_return: OMC_LABEL_UNUSED
if (out_outMetaClasses) { *out_outMetaClasses = _outMetaClasses; }
return _outElementItems;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MetaUtil_fixClassParts(threadData_t *threadData, modelica_metatype _inClassParts, modelica_string _inClassName, modelica_metatype _typeVars, modelica_metatype *out_outMetaClasses)
{
modelica_metatype _outClassParts = NULL;
modelica_metatype _outMetaClasses = NULL;
modelica_metatype _meta_classes = NULL;
modelica_metatype _els = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outMetaClasses = tmpMeta[0];
{
modelica_metatype __omcQ_24tmpVar7;
modelica_metatype* tmp1;
modelica_metatype __omcQ_24tmpVar6;
int tmp5;
modelica_metatype _p_loopVar = 0;
modelica_metatype _p;
_p_loopVar = _inClassParts;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar7 = tmpMeta[2];
tmp1 = &__omcQ_24tmpVar7;
while(1) {
tmp5 = 1;
if (!listEmpty(_p_loopVar)) {
_p = MMC_CAR(_p_loopVar);
_p_loopVar = MMC_CDR(_p_loopVar);
tmp5--;
}
if (tmp5 == 0) {
{
modelica_metatype tmp4_1;
tmp4_1 = _p;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
_els = omc_MetaUtil_fixElementItems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2))), _inClassName, _typeVars ,&_meta_classes);
tmpMeta[4] = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta[4]), MMC_UNTAGPTR(_p), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[4]))[2] = _els;
_p = tmpMeta[4];
_outMetaClasses = listAppend(_meta_classes, _outMetaClasses);
tmpMeta[3] = _p;
goto tmp3_done;
}
case 4: {
_els = omc_MetaUtil_fixElementItems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2))), _inClassName, _typeVars ,&_meta_classes);
tmpMeta[4] = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta[4]), MMC_UNTAGPTR(_p), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[4]))[2] = _els;
_p = tmpMeta[4];
_outMetaClasses = listAppend(_meta_classes, _outMetaClasses);
tmpMeta[3] = _p;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmpMeta[3] = _p;
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
}__omcQ_24tmpVar6 = tmpMeta[3];
*tmp1 = mmc_mk_cons(__omcQ_24tmpVar6,0);
tmp1 = &MMC_CDR(*tmp1);
} else if (tmp5 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp1 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar7;
}
_outClassParts = tmpMeta[1];
_return: OMC_LABEL_UNUSED
if (out_outMetaClasses) { *out_outMetaClasses = _outMetaClasses; }
return _outClassParts;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MetaUtil_convertElementToClass(threadData_t *threadData, modelica_metatype _inElementItem)
{
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inElementItem;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,1) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,6) == 0) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,2) == 0) MMC_THROW_INTERNAL();
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
_outClass = tmpMeta[3];
_return: OMC_LABEL_UNUSED
return _outClass;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MetaUtil_setElementItemClass(threadData_t *threadData, modelica_metatype _inElementItem, modelica_metatype _inClass)
{
modelica_metatype _outElementItem = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outElementItem = _inElementItem;
{
modelica_metatype tmp3_1;
tmp3_1 = _outElementItem;
{
modelica_metatype _e = NULL;
modelica_metatype _es = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,6) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,2) == 0) goto tmp2_end;
_e = tmpMeta[1];
_es = tmpMeta[2];
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_es), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[3] = _inClass;
_es = tmpMeta[1];
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_e), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[5] = _es;
_e = tmpMeta[1];
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_outElementItem), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[2] = _e;
_outElementItem = tmpMeta[1];
tmpMeta[0] = _outElementItem;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _outElementItem;
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
_outElementItem = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outElementItem;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MetaUtil_createMetaClassesFromElementItems(threadData_t *threadData, modelica_metatype _inElementItems)
{
modelica_metatype _outElementItems = NULL;
modelica_metatype _cls = NULL;
modelica_metatype _meta_classes = NULL;
modelica_metatype _els = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outElementItems = tmpMeta[0];
{
modelica_metatype _e;
for (tmpMeta[1] = listReverse(_inElementItems); !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_e = MMC_CAR(tmpMeta[1]);
{
modelica_metatype tmp3_1;
tmp3_1 = _e;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,6) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,2) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
_cls = tmpMeta[5];
_cls = omc_MetaUtil_createMetaClasses(threadData, _cls ,&_meta_classes);
{
modelica_metatype __omcQ_24tmpVar9;
modelica_metatype* tmp5;
modelica_metatype __omcQ_24tmpVar8;
int tmp6;
modelica_metatype _c_loopVar = 0;
modelica_metatype _c;
_c_loopVar = _meta_classes;
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar9 = tmpMeta[4];
tmp5 = &__omcQ_24tmpVar9;
while(1) {
tmp6 = 1;
if (!listEmpty(_c_loopVar)) {
_c = MMC_CAR(_c_loopVar);
_c_loopVar = MMC_CDR(_c_loopVar);
tmp6--;
}
if (tmp6 == 0) {
__omcQ_24tmpVar8 = omc_MetaUtil_setElementItemClass(threadData, _e, _c);
*tmp5 = mmc_mk_cons(__omcQ_24tmpVar8,0);
tmp5 = &MMC_CDR(*tmp5);
} else if (tmp6 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp5 = mmc_mk_nil();
tmpMeta[3] = __omcQ_24tmpVar9;
}
_els = tmpMeta[3];
_outElementItems = listAppend(_els, _outElementItems);
tmpMeta[2] = omc_MetaUtil_setElementItemClass(threadData, _e, _cls);
goto tmp2_done;
}
case 1: {
tmpMeta[2] = _e;
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
_e = tmpMeta[2];
tmpMeta[2] = mmc_mk_cons(_e, _outElementItems);
_outElementItems = tmpMeta[2];
}
}
_return: OMC_LABEL_UNUSED
return _outElementItems;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MetaUtil_createMetaClassesFromClassParts(threadData_t *threadData, modelica_metatype _inClassParts)
{
modelica_metatype _outClassParts = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar11;
modelica_metatype* tmp1;
modelica_metatype __omcQ_24tmpVar10;
int tmp5;
modelica_metatype _p_loopVar = 0;
modelica_metatype _p;
_p_loopVar = _inClassParts;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar11 = tmpMeta[1];
tmp1 = &__omcQ_24tmpVar11;
while(1) {
tmp5 = 1;
if (!listEmpty(_p_loopVar)) {
_p = MMC_CAR(_p_loopVar);
_p_loopVar = MMC_CDR(_p_loopVar);
tmp5--;
}
if (tmp5 == 0) {
{
modelica_metatype tmp4_1;
tmp4_1 = _p;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmpMeta[3] = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta[3]), MMC_UNTAGPTR(_p), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[3]))[2] = omc_MetaUtil_createMetaClassesFromElementItems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2))));
_p = tmpMeta[3];
tmpMeta[2] = _p;
goto tmp3_done;
}
case 4: {
tmpMeta[3] = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta[3]), MMC_UNTAGPTR(_p), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[3]))[2] = omc_MetaUtil_createMetaClassesFromElementItems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2))));
_p = tmpMeta[3];
tmpMeta[2] = _p;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmpMeta[2] = _p;
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
}__omcQ_24tmpVar10 = tmpMeta[2];
*tmp1 = mmc_mk_cons(__omcQ_24tmpVar10,0);
tmp1 = &MMC_CDR(*tmp1);
} else if (tmp5 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp1 = mmc_mk_nil();
tmpMeta[0] = __omcQ_24tmpVar11;
}
_outClassParts = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outClassParts;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_MetaUtil_createMetaClasses(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype *out_outMetaClasses)
{
modelica_metatype _outClass = NULL;
modelica_metatype _outMetaClasses = NULL;
modelica_metatype _body = NULL;
modelica_metatype _parts = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outClass = _inClass;
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outMetaClasses = tmpMeta[0];
{
modelica_metatype tmp3_1;
tmp3_1 = _outClass;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],19,0) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,5) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
_body = tmpMeta[2];
_parts = tmpMeta[3];
_parts = omc_MetaUtil_fixClassParts(threadData, _parts, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outClass), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_body), 2))) ,&_outMetaClasses);
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_body), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[4] = _parts;
_body = tmpMeta[1];
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_outClass), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[7] = _body;
_outClass = tmpMeta[1];
goto tmp2_done;
}
case 1: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],19,0) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],4,5) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
_body = tmpMeta[2];
_parts = tmpMeta[3];
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_parts = omc_MetaUtil_fixClassParts(threadData, _parts, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outClass), 2))), tmpMeta[1] ,&_outMetaClasses);
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_body), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[5] = _parts;
_body = tmpMeta[1];
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_outClass), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[7] = _body;
_outClass = tmpMeta[1];
goto tmp2_done;
}
case 2: {
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
;
{
modelica_metatype tmp7_1;
tmp7_1 = _outClass;
{
volatile mmc_switch_type tmp7;
int tmp8;
tmp7 = 0;
for (; tmp7 < 3; tmp7++) {
switch (MMC_SWITCH_CAST(tmp7)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,5) == 0) goto tmp6_end;
_body = tmpMeta[1];
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_body), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[4] = omc_MetaUtil_createMetaClassesFromClassParts(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_body), 4))));
_body = tmpMeta[1];
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_outClass), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[7] = _body;
_outClass = tmpMeta[1];
goto tmp6_done;
}
case 1: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],4,5) == 0) goto tmp6_end;
_body = tmpMeta[1];
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_body), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[5] = omc_MetaUtil_createMetaClassesFromClassParts(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_body), 5))));
_body = tmpMeta[1];
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_outClass), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[7] = _body;
_outClass = tmpMeta[1];
goto tmp6_done;
}
case 2: {
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
modelica_metatype _meta_classes = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outProgram = _inProgram;
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_classes = tmpMeta[0];
if((!omc_Config_acceptMetaModelicaGrammar(threadData)))
{
goto _return;
}
{
modelica_metatype tmp3_1;
tmp3_1 = _outProgram;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
{
modelica_metatype _c;
for (tmpMeta[1] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outProgram), 2))); !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_c = MMC_CAR(tmpMeta[1]);
_c = omc_MetaUtil_createMetaClasses(threadData, _c ,&_meta_classes);
tmpMeta[2] = mmc_mk_cons(_c, listAppend(_meta_classes, _classes));
_classes = tmpMeta[2];
}
}
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_outProgram), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[2] = listReverseInPlace(_classes);
_outProgram = tmpMeta[1];
goto tmp2_done;
}
case 1: {
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
;
_return: OMC_LABEL_UNUSED
return _outProgram;
}
