#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "ElementSource.c"
#endif
#include "omc_simulation_settings.h"
#include "ElementSource.h"
#define _OMC_LIT0_data "infoXmlOperations"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,17,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "Enables output of the operations in the _info.xml file when translating models."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,79,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT2,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT1}};
#define _OMC_LIT2 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(94)),_OMC_LIT0,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT2}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "visxml"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,6,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "Outputs a xml-file that contains information for visualization."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,63,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT5}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(123)),_OMC_LIT4,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT6}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT8,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT8 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "Internal error %s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,17,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT10}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT12,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(63)),_OMC_LIT8,_OMC_LIT9,_OMC_LIT11}};
#define _OMC_LIT12 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "ElementSource.getElementSource failed: Element does not have a source"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,69,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT14,2,1) {_OMC_LIT13,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT14 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data "Tried to add the flattened elements to the list of operations, but did not find the SCode equation"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,98,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT16,2,1) {_OMC_LIT15,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT16 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data "time"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,4,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT18,2,4) {&DAE_Type_T__REAL__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT18 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,4,4) {&DAE_ComponentRef_CREF__IDENT__desc,_OMC_LIT17,_OMC_LIT18,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT20,1,3) {&DAE_Prefix_NOPRE__desc,}};
#define _OMC_LIT20 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT20)
#define _OMC_LIT21_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT21,0,_OMC_LIT21_data);
#define _OMC_LIT21 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT21)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT22,1,11) {&DAE_Type_T__UNKNOWN__desc,}};
#define _OMC_LIT22 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT22)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT23,4,4) {&DAE_ComponentRef_CREF__IDENT__desc,_OMC_LIT21,_OMC_LIT22,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT23 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT23)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT24,2,0) {_OMC_LIT23,_OMC_LIT23}};
#define _OMC_LIT24 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT24)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT25,1,4) {&DAE_ComponentPrefix_NOCOMPPRE__desc,}};
#define _OMC_LIT25 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT25)
#include "util/modelica.h"
#include "ElementSource_includes.h"
DLLExport
modelica_metatype omc_ElementSource_addElementSourceInstanceOpt(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _instanceOpt)
{
modelica_metatype _source = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _source;
tmp3_2 = _instanceOpt;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta5;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_source), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[4] = _instanceOpt;
_source = tmpMeta5;
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
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_addElementSourceType(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _classPath)
{
modelica_metatype _source = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!(omc_Flags_isSet(threadData, _OMC_LIT3) || omc_Flags_isSet(threadData, _OMC_LIT7))))
{
goto _return;
}
{
modelica_metatype tmp4_1;
tmp4_1 = _source;
{
modelica_metatype _info = NULL;
modelica_metatype _typeLst = NULL;
modelica_metatype _partOfLst = NULL;
modelica_metatype _instanceOpt = NULL;
modelica_metatype _connectEquationOptLst = NULL;
modelica_metatype _operations = NULL;
modelica_metatype _comment = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_info = tmpMeta6;
_partOfLst = tmpMeta7;
_instanceOpt = tmpMeta8;
_connectEquationOptLst = tmpMeta9;
_typeLst = tmpMeta10;
_operations = tmpMeta11;
_comment = tmpMeta12;
tmpMeta13 = mmc_mk_cons(_classPath, _typeLst);
tmpMeta14 = mmc_mk_box8(3, &DAE_ElementSource_SOURCE__desc, _info, _partOfLst, _instanceOpt, _connectEquationOptLst, tmpMeta13, _operations, _comment);
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
_source = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_addElementSourceConnect(threadData_t *threadData, modelica_metatype _inSource, modelica_metatype _connectEquationOpt)
{
modelica_metatype _outSource = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inSource;
{
modelica_metatype _info = NULL;
modelica_metatype _partOfLst = NULL;
modelica_metatype _instanceOpt = NULL;
modelica_metatype _connectEquationOptLst = NULL;
modelica_metatype _typeLst = NULL;
modelica_metatype _operations = NULL;
modelica_metatype _comment = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_info = tmpMeta6;
_partOfLst = tmpMeta7;
_instanceOpt = tmpMeta8;
_connectEquationOptLst = tmpMeta9;
_typeLst = tmpMeta10;
_operations = tmpMeta11;
_comment = tmpMeta12;
tmpMeta13 = mmc_mk_cons(_connectEquationOpt, _connectEquationOptLst);
tmpMeta14 = mmc_mk_box8(3, &DAE_ElementSource_SOURCE__desc, _info, _partOfLst, _instanceOpt, tmpMeta13, _typeLst, _operations, _comment);
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
_outSource = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outSource;
}
DLLExport
modelica_metatype omc_ElementSource_addElementSourceFileInfo(threadData_t *threadData, modelica_metatype _source, modelica_metatype _fileInfo)
{
modelica_metatype _outSource = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outSource = _source;
tmpMeta1 = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta1), MMC_UNTAGPTR(_outSource), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta1))[2] = _fileInfo;
_outSource = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outSource;
}
DLLExport
modelica_metatype omc_ElementSource_addElementSourcePartOfOpt(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _classPathOpt)
{
modelica_metatype _source = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!(omc_Flags_isSet(threadData, _OMC_LIT3) || omc_Flags_isSet(threadData, _OMC_LIT7))))
{
goto _return;
}
{
modelica_metatype tmp4_1;
tmp4_1 = _classPathOpt;
{
modelica_metatype _classPath = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
tmpMeta1 = _source;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_classPath = tmpMeta6;
tmpMeta7 = mmc_mk_box2(3, &Absyn_Within_WITHIN__desc, _classPath);
tmpMeta1 = omc_ElementSource_addElementSourcePartOf(threadData, _source, tmpMeta7);
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
_source = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_addElementSourcePartOf(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _withinPath)
{
modelica_metatype _source = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!(omc_Flags_isSet(threadData, _OMC_LIT3) || omc_Flags_isSet(threadData, _OMC_LIT7))))
{
goto _return;
}
tmpMeta2 = mmc_mk_cons(_withinPath, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_source), 3))));
tmpMeta1 = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta1), MMC_UNTAGPTR(_source), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta1))[3] = tmpMeta2;
_source = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_getElementSourcePartOfs(threadData_t *threadData, modelica_metatype _source)
{
modelica_metatype _withinLst = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_withinLst = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_source), 3)));
_return: OMC_LABEL_UNUSED
return _withinLst;
}
DLLExport
modelica_metatype omc_ElementSource_getElementSourceConnects(threadData_t *threadData, modelica_metatype _source)
{
modelica_metatype _connectEquationOptLst = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_connectEquationOptLst = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_source), 5)));
_return: OMC_LABEL_UNUSED
return _connectEquationOptLst;
}
DLLExport
modelica_metatype omc_ElementSource_getElementSourceInstances(threadData_t *threadData, modelica_metatype _source)
{
modelica_metatype _instanceOpt = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_instanceOpt = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_source), 4)));
_return: OMC_LABEL_UNUSED
return _instanceOpt;
}
DLLExport
modelica_metatype omc_ElementSource_getElementSourceTypes(threadData_t *threadData, modelica_metatype _source)
{
modelica_metatype _pathLst = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_pathLst = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_source), 6)));
_return: OMC_LABEL_UNUSED
return _pathLst;
}
DLLExport
modelica_metatype omc_ElementSource_getElementSourceFileInfo(threadData_t *threadData, modelica_metatype _source)
{
modelica_metatype _info = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_info = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_source), 2)));
_return: OMC_LABEL_UNUSED
return _info;
}
DLLExport
modelica_metatype omc_ElementSource_getInfo(threadData_t *threadData, modelica_metatype _source)
{
modelica_metatype _info = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_info = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_source), 2)));
_return: OMC_LABEL_UNUSED
return _info;
}
DLLExport
modelica_metatype omc_ElementSource_getStatementSource(threadData_t *threadData, modelica_metatype _stmt)
{
modelica_metatype _source = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _stmt;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 5)));
goto tmp3_done;
}
case 4: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 5)));
goto tmp3_done;
}
case 5: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 5)));
goto tmp3_done;
}
case 6: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 5)));
goto tmp3_done;
}
case 7: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 8)));
goto tmp3_done;
}
case 8: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 9)));
goto tmp3_done;
}
case 9: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 4)));
goto tmp3_done;
}
case 10: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 7)));
goto tmp3_done;
}
case 11: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 5)));
goto tmp3_done;
}
case 12: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 3)));
goto tmp3_done;
}
case 13: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 4)));
goto tmp3_done;
}
case 14: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 3)));
goto tmp3_done;
}
case 15: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 2)));
goto tmp3_done;
}
case 16: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 2)));
goto tmp3_done;
}
case 18: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 4)));
goto tmp3_done;
}
case 19: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 3)));
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
_source = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_getElementSource(threadData_t *threadData, modelica_metatype _element)
{
modelica_metatype _source = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _element;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 11)));
goto tmp3_done;
}
case 4: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4)));
goto tmp3_done;
}
case 5: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4)));
goto tmp3_done;
}
case 6: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4)));
goto tmp3_done;
}
case 7: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4)));
goto tmp3_done;
}
case 8: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 5)));
goto tmp3_done;
}
case 9: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 5)));
goto tmp3_done;
}
case 11: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4)));
goto tmp3_done;
}
case 12: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4)));
goto tmp3_done;
}
case 13: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 5)));
goto tmp3_done;
}
case 15: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 5)));
goto tmp3_done;
}
case 16: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 5)));
goto tmp3_done;
}
case 17: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4)));
goto tmp3_done;
}
case 18: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 3)));
goto tmp3_done;
}
case 19: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 3)));
goto tmp3_done;
}
case 20: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4)));
goto tmp3_done;
}
case 21: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 3)));
goto tmp3_done;
}
case 22: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 5)));
goto tmp3_done;
}
case 23: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 5)));
goto tmp3_done;
}
case 24: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 3)));
goto tmp3_done;
}
case 25: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 3)));
goto tmp3_done;
}
case 26: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4)));
goto tmp3_done;
}
case 27: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 3)));
goto tmp3_done;
}
case 29: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 3)));
goto tmp3_done;
}
case 28: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 3)));
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
omc_Error_addMessage(threadData, _OMC_LIT12, _OMC_LIT14);
goto goto_2;
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
_source = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_getSymbolicTransformations(threadData_t *threadData, modelica_metatype _source)
{
modelica_metatype _ops = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ops = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_source), 7)));
_return: OMC_LABEL_UNUSED
return _ops;
}
DLLExport
modelica_metatype omc_ElementSource_addSymbolicTransformationSolve(threadData_t *threadData, modelica_boolean _add, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _cr, modelica_metatype _exp1, modelica_metatype _exp2, modelica_metatype _exp, modelica_metatype _asserts)
{
modelica_metatype _source = NULL;
modelica_metatype _op = NULL;
modelica_metatype _op1 = NULL;
modelica_metatype _op2 = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!(_add && omc_Flags_isSet(threadData, _OMC_LIT3))))
{
goto _return;
}
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype __omcQ_24tmpVar0;
modelica_integer tmp4;
modelica_metatype _ass_loopVar = 0;
modelica_metatype _ass;
_ass_loopVar = _asserts;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar1;
while(1) {
tmp4 = 1;
if (!listEmpty(_ass_loopVar)) {
_ass = MMC_CAR(_ass_loopVar);
_ass_loopVar = MMC_CDR(_ass_loopVar);
tmp4--;
}
if (tmp4 == 0) {
__omcQ_24tmpVar0 = omc_Algorithm_getAssertCond(threadData, _ass);
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp4 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar1;
}
tmpMeta5 = mmc_mk_box6(9, &DAE_SymbolicOperation_SOLVE__desc, _cr, _exp1, _exp2, _exp, tmpMeta1);
_op1 = tmpMeta5;
tmpMeta6 = mmc_mk_box3(10, &DAE_SymbolicOperation_SOLVED__desc, _cr, _exp2);
_op2 = tmpMeta6;
_op = (omc_Expression_expEqual(threadData, _exp2, _exp)?_op2:_op1);
_source = omc_ElementSource_addSymbolicTransformation(threadData, _source, _op);
_return: OMC_LABEL_UNUSED
return _source;
}
modelica_metatype boxptr_ElementSource_addSymbolicTransformationSolve(threadData_t *threadData, modelica_metatype _add, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _cr, modelica_metatype _exp1, modelica_metatype _exp2, modelica_metatype _exp, modelica_metatype _asserts)
{
modelica_integer tmp1;
modelica_metatype _source = NULL;
tmp1 = mmc_unbox_integer(_add);
_source = omc_ElementSource_addSymbolicTransformationSolve(threadData, tmp1, __omcQ_24in_5Fsource, _cr, _exp1, _exp2, _exp, _asserts);
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_addSymbolicTransformationSimplify(threadData_t *threadData, modelica_boolean _add, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _exp1, modelica_metatype _exp2)
{
modelica_metatype _source = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!omc_Flags_isSet(threadData, _OMC_LIT3)))
{
goto _return;
}
tmpMeta1 = mmc_mk_box3(4, &DAE_SymbolicOperation_SIMPLIFY__desc, _exp1, _exp2);
_source = omc_ElementSource_condAddSymbolicTransformation(threadData, _add, _source, tmpMeta1);
_return: OMC_LABEL_UNUSED
return _source;
}
modelica_metatype boxptr_ElementSource_addSymbolicTransformationSimplify(threadData_t *threadData, modelica_metatype _add, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _exp1, modelica_metatype _exp2)
{
modelica_integer tmp1;
modelica_metatype _source = NULL;
tmp1 = mmc_unbox_integer(_add);
_source = omc_ElementSource_addSymbolicTransformationSimplify(threadData, tmp1, __omcQ_24in_5Fsource, _exp1, _exp2);
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_addSymbolicTransformationSimplifyLst(threadData_t *threadData, modelica_metatype _add, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _explst1, modelica_metatype _explst2)
{
modelica_metatype _source = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!omc_Flags_isSet(threadData, _OMC_LIT3)))
{
goto _return;
}
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _add;
tmp4_2 = _explst1;
tmp4_3 = _explst2;
{
modelica_metatype _brest = NULL;
modelica_metatype _rexplst1 = NULL;
modelica_metatype _rexplst2 = NULL;
modelica_metatype _exp1 = NULL;
modelica_metatype _exp2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta1 = _source;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_integer tmp12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_3);
tmpMeta9 = MMC_CDR(tmp4_3);
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
tmp12 = mmc_unbox_integer(tmpMeta10);
if (1 != tmp12) goto tmp3_end;
_exp1 = tmpMeta6;
_rexplst1 = tmpMeta7;
_exp2 = tmpMeta8;
_rexplst2 = tmpMeta9;
_brest = tmpMeta11;
tmpMeta13 = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _exp1);
tmpMeta14 = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _exp2);
tmpMeta15 = mmc_mk_box3(4, &DAE_SymbolicOperation_SIMPLIFY__desc, tmpMeta13, tmpMeta14);
_source = omc_ElementSource_addSymbolicTransformation(threadData, _source, tmpMeta15);
_add = _brest;
__omcQ_24in_5Fsource = _source;
_explst1 = _rexplst1;
_explst2 = _rexplst2;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_integer tmp22;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmp4_2);
tmpMeta17 = MMC_CDR(tmp4_2);
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta18 = MMC_CAR(tmp4_3);
tmpMeta19 = MMC_CDR(tmp4_3);
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta20 = MMC_CAR(tmp4_1);
tmpMeta21 = MMC_CDR(tmp4_1);
tmp22 = mmc_unbox_integer(tmpMeta20);
if (0 != tmp22) goto tmp3_end;
_rexplst1 = tmpMeta17;
_rexplst2 = tmpMeta19;
_brest = tmpMeta21;
_add = _brest;
__omcQ_24in_5Fsource = _source;
_explst1 = _rexplst1;
_explst2 = _rexplst2;
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
_source = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_addSymbolicTransformationSubstitution(threadData_t *threadData, modelica_boolean _add, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _exp1, modelica_metatype _exp2)
{
modelica_metatype _source = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!omc_Flags_isSet(threadData, _OMC_LIT3)))
{
goto _return;
}
tmpMeta1 = mmc_mk_cons(_exp2, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta2 = mmc_mk_box3(5, &DAE_SymbolicOperation_SUBSTITUTION__desc, tmpMeta1, _exp1);
_source = omc_ElementSource_condAddSymbolicTransformation(threadData, _add, _source, tmpMeta2);
_return: OMC_LABEL_UNUSED
return _source;
}
modelica_metatype boxptr_ElementSource_addSymbolicTransformationSubstitution(threadData_t *threadData, modelica_metatype _add, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _exp1, modelica_metatype _exp2)
{
modelica_integer tmp1;
modelica_metatype _source = NULL;
tmp1 = mmc_unbox_integer(_add);
_source = omc_ElementSource_addSymbolicTransformationSubstitution(threadData, tmp1, __omcQ_24in_5Fsource, _exp1, _exp2);
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_addSymbolicTransformationSubstitutionLst(threadData_t *threadData, modelica_metatype _add, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _explst1, modelica_metatype _explst2)
{
modelica_metatype _source = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!omc_Flags_isSet(threadData, _OMC_LIT3)))
{
goto _return;
}
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _add;
tmp4_2 = _explst1;
tmp4_3 = _explst2;
{
modelica_metatype _brest = NULL;
modelica_metatype _rexplst1 = NULL;
modelica_metatype _rexplst2 = NULL;
modelica_metatype _exp1 = NULL;
modelica_metatype _exp2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta1 = _source;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_integer tmp12;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_3);
tmpMeta9 = MMC_CDR(tmp4_3);
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
tmp12 = mmc_unbox_integer(tmpMeta10);
if (1 != tmp12) goto tmp3_end;
_exp1 = tmpMeta6;
_rexplst1 = tmpMeta7;
_exp2 = tmpMeta8;
_rexplst2 = tmpMeta9;
_brest = tmpMeta11;
_source = omc_ElementSource_addSymbolicTransformationSubstitution(threadData, 1, _source, _exp1, _exp2);
_add = _brest;
__omcQ_24in_5Fsource = _source;
_explst1 = _rexplst1;
_explst2 = _rexplst2;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_integer tmp19;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta13 = MMC_CAR(tmp4_2);
tmpMeta14 = MMC_CDR(tmp4_2);
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta15 = MMC_CAR(tmp4_3);
tmpMeta16 = MMC_CDR(tmp4_3);
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta17 = MMC_CAR(tmp4_1);
tmpMeta18 = MMC_CDR(tmp4_1);
tmp19 = mmc_unbox_integer(tmpMeta17);
if (0 != tmp19) goto tmp3_end;
_rexplst1 = tmpMeta14;
_rexplst2 = tmpMeta16;
_brest = tmpMeta18;
_add = _brest;
__omcQ_24in_5Fsource = _source;
_explst1 = _rexplst1;
_explst2 = _rexplst2;
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
_source = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_addSymbolicTransformationFlattenedEqs(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _elt)
{
modelica_metatype _source = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!omc_Flags_isSet(threadData, _OMC_LIT3)))
{
goto _return;
}
{
modelica_metatype tmp4_1;
tmp4_1 = _source;
{
modelica_metatype _info = NULL;
modelica_metatype _typeLst = NULL;
modelica_metatype _partOfLst = NULL;
modelica_metatype _instanceOpt = NULL;
modelica_metatype _connectEquationOptLst = NULL;
modelica_metatype _operations = NULL;
modelica_metatype _comment = NULL;
modelica_metatype _scode = NULL;
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
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (listEmpty(tmpMeta11)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmpMeta11);
tmpMeta13 = MMC_CDR(tmpMeta11);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,0,2) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 3));
if (!optionNone(tmpMeta15)) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_info = tmpMeta6;
_partOfLst = tmpMeta7;
_instanceOpt = tmpMeta8;
_connectEquationOptLst = tmpMeta9;
_typeLst = tmpMeta10;
_scode = tmpMeta14;
_operations = tmpMeta13;
_comment = tmpMeta16;
tmpMeta18 = mmc_mk_box3(3, &DAE_SymbolicOperation_FLATTEN__desc, _scode, mmc_mk_some(_elt));
tmpMeta17 = mmc_mk_cons(tmpMeta18, _operations);
tmpMeta19 = mmc_mk_box8(3, &DAE_ElementSource_SOURCE__desc, _info, _partOfLst, _instanceOpt, _connectEquationOptLst, _typeLst, tmpMeta17, _comment);
tmpMeta1 = tmpMeta19;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta20;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_info = tmpMeta20;
omc_Error_addSourceMessage(threadData, _OMC_LIT12, _OMC_LIT16, _info);
goto goto_2;
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
_source = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_addSymbolicTransformationDeriveLst(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _explst1, modelica_metatype _explst2)
{
modelica_metatype _source = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!omc_Flags_isSet(threadData, _OMC_LIT3)))
{
goto _return;
}
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _explst1;
tmp4_2 = _explst2;
{
modelica_metatype _op = NULL;
modelica_metatype _rexplst1 = NULL;
modelica_metatype _rexplst2 = NULL;
modelica_metatype _exp1 = NULL;
modelica_metatype _exp2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta1 = _source;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_2);
tmpMeta9 = MMC_CDR(tmp4_2);
_exp1 = tmpMeta6;
_rexplst1 = tmpMeta7;
_exp2 = tmpMeta8;
_rexplst2 = tmpMeta9;
tmpMeta10 = mmc_mk_box4(8, &DAE_SymbolicOperation_OP__DIFFERENTIATE__desc, _OMC_LIT19, _exp1, _exp2);
_op = tmpMeta10;
_source = omc_ElementSource_addSymbolicTransformation(threadData, _source, _op);
__omcQ_24in_5Fsource = _source;
_explst1 = _rexplst1;
_explst2 = _rexplst2;
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
_source = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_condAddSymbolicTransformation(threadData_t *threadData, modelica_boolean _cond, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _op)
{
modelica_metatype _source = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!_cond))
{
goto _return;
}
_source = omc_ElementSource_addSymbolicTransformation(threadData, _source, _op);
_return: OMC_LABEL_UNUSED
return _source;
}
modelica_metatype boxptr_ElementSource_condAddSymbolicTransformation(threadData_t *threadData, modelica_metatype _cond, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _op)
{
modelica_integer tmp1;
modelica_metatype _source = NULL;
tmp1 = mmc_unbox_integer(_cond);
_source = omc_ElementSource_condAddSymbolicTransformation(threadData, tmp1, __omcQ_24in_5Fsource, _op);
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_addSymbolicTransformation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _op)
{
modelica_metatype _source = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!omc_Flags_isSet(threadData, _OMC_LIT3)))
{
goto _return;
}
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _source;
tmp4_2 = _op;
{
modelica_metatype _info = NULL;
modelica_metatype _typeLst = NULL;
modelica_metatype _partOfLst = NULL;
modelica_metatype _instanceOpt = NULL;
modelica_metatype _connectEquationOptLst = NULL;
modelica_metatype _operations = NULL;
modelica_metatype _h1 = NULL;
modelica_metatype _t1 = NULL;
modelica_metatype _t2 = NULL;
modelica_metatype _es1 = NULL;
modelica_metatype _es2 = NULL;
modelica_metatype _es = NULL;
modelica_metatype _comment = NULL;
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
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (listEmpty(tmpMeta13)) goto tmp3_end;
tmpMeta14 = MMC_CAR(tmpMeta13);
tmpMeta15 = MMC_CDR(tmpMeta13);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,2,2) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
if (listEmpty(tmpMeta16)) goto tmp3_end;
tmpMeta17 = MMC_CAR(tmpMeta16);
tmpMeta18 = MMC_CDR(tmpMeta16);
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 3));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_es2 = tmpMeta6;
_t2 = tmpMeta7;
_info = tmpMeta8;
_partOfLst = tmpMeta9;
_instanceOpt = tmpMeta10;
_connectEquationOptLst = tmpMeta11;
_typeLst = tmpMeta12;
_es1 = tmpMeta16;
_h1 = tmpMeta17;
_t1 = tmpMeta19;
_operations = tmpMeta15;
_comment = tmpMeta20;
if (!omc_Expression_expEqual(threadData, _t2, _h1)) goto tmp3_end;
_es = listAppend(_es2, _es1);
tmpMeta22 = mmc_mk_box3(5, &DAE_SymbolicOperation_SUBSTITUTION__desc, _es, _t1);
tmpMeta21 = mmc_mk_cons(tmpMeta22, _operations);
tmpMeta23 = mmc_mk_box8(3, &DAE_ElementSource_SOURCE__desc, _info, _partOfLst, _instanceOpt, _connectEquationOptLst, _typeLst, tmpMeta21, _comment);
tmpMeta1 = tmpMeta23;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_info = tmpMeta24;
_partOfLst = tmpMeta25;
_instanceOpt = tmpMeta26;
_connectEquationOptLst = tmpMeta27;
_typeLst = tmpMeta28;
_operations = tmpMeta29;
_comment = tmpMeta30;
tmpMeta31 = mmc_mk_cons(_op, _operations);
tmpMeta32 = mmc_mk_box8(3, &DAE_ElementSource_SOURCE__desc, _info, _partOfLst, _instanceOpt, _connectEquationOptLst, _typeLst, tmpMeta31, _comment);
tmpMeta1 = tmpMeta32;
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
_source = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_getOptComment(threadData_t *threadData, modelica_metatype _source)
{
modelica_metatype _outComment = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if((!listEmpty((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_source), 8))))))
{
_outComment = mmc_mk_some(omc_List_last(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_source), 8)))));
}
else
{
_outComment = mmc_mk_none();
}
_return: OMC_LABEL_UNUSED
return _outComment;
}
DLLExport
modelica_metatype omc_ElementSource_getComments(threadData_t *threadData, modelica_metatype _source)
{
modelica_metatype _outComments = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _source;
{
modelica_metatype _comment = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_comment = tmpMeta6;
tmpMeta1 = _comment;
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
_outComments = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComments;
}
DLLExport
modelica_metatype omc_ElementSource_addAnnotation(threadData_t *threadData, modelica_metatype _source, modelica_metatype _comment)
{
modelica_metatype _outSource = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _source;
tmp4_2 = _comment;
{
modelica_metatype _info = NULL;
modelica_metatype _typeLst = NULL;
modelica_metatype _partOfLst = NULL;
modelica_metatype _instanceOpt = NULL;
modelica_metatype _connectEquationOptLst = NULL;
modelica_metatype _operations = NULL;
modelica_metatype _commentLst = NULL;
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
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (optionNone(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_info = tmpMeta8;
_partOfLst = tmpMeta9;
_instanceOpt = tmpMeta10;
_connectEquationOptLst = tmpMeta11;
_typeLst = tmpMeta12;
_operations = tmpMeta13;
_commentLst = tmpMeta14;
tmpMeta15 = mmc_mk_cons(_comment, _commentLst);
tmpMeta16 = mmc_mk_box8(3, &DAE_ElementSource_SOURCE__desc, _info, _partOfLst, _instanceOpt, _connectEquationOptLst, _typeLst, _operations, tmpMeta15);
tmpMeta1 = tmpMeta16;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _source;
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
_outSource = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outSource;
}
DLLExport
modelica_metatype omc_ElementSource_addAdditionalComment(threadData_t *threadData, modelica_metatype _source, modelica_string _message)
{
modelica_metatype _outSource = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _source;
{
modelica_metatype _info = NULL;
modelica_metatype _typeLst = NULL;
modelica_metatype _partOfLst = NULL;
modelica_metatype _instanceOpt = NULL;
modelica_metatype _connectEquationOptLst = NULL;
modelica_metatype _operations = NULL;
modelica_metatype _comment = NULL;
modelica_boolean _b;
modelica_metatype _c = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
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
modelica_boolean tmp15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_info = tmpMeta6;
_partOfLst = tmpMeta7;
_instanceOpt = tmpMeta8;
_connectEquationOptLst = tmpMeta9;
_typeLst = tmpMeta10;
_operations = tmpMeta11;
_comment = tmpMeta12;
tmpMeta13 = mmc_mk_box3(3, &SCode_Comment_COMMENT__desc, mmc_mk_none(), mmc_mk_some(_message));
_c = tmpMeta13;
_b = listMember(_c, _comment);
tmp15 = (modelica_boolean)_b;
if(tmp15)
{
tmpMeta16 = _comment;
}
else
{
tmpMeta14 = mmc_mk_cons(_c, _comment);
tmpMeta16 = tmpMeta14;
}
_comment = tmpMeta16;
tmpMeta17 = mmc_mk_box8(3, &DAE_ElementSource_SOURCE__desc, _info, _partOfLst, _instanceOpt, _connectEquationOptLst, _typeLst, _operations, _comment);
tmpMeta1 = tmpMeta17;
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
_outSource = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outSource;
}
DLLExport
modelica_metatype omc_ElementSource_createElementSource(threadData_t *threadData, modelica_metatype _fileInfo, modelica_metatype _partOf, modelica_metatype _prefix, modelica_metatype _connectEquation)
{
modelica_metatype _source = NULL;
modelica_metatype _path = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _partOf;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (!optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_path = tmpMeta7;
tmpMeta9 = mmc_mk_box2(3, &Absyn_Within_WITHIN__desc, _path);
tmpMeta8 = mmc_mk_cons(tmpMeta9, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta8;
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
{
modelica_metatype tmp13_1;
tmp13_1 = _prefix;
{
volatile mmc_switch_type tmp13;
int tmp14;
tmp13 = 0;
for (; tmp13 < 2; tmp13++) {
switch (MMC_SWITCH_CAST(tmp13)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp13_1,0,0) == 0) goto tmp12_end;
tmpMeta10 = _OMC_LIT25;
goto tmp12_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp13_1,1,2) == 0) goto tmp12_end;
tmpMeta10 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefix), 2)));
goto tmp12_done;
}
}
goto tmp12_end;
tmp12_end: ;
}
goto goto_11;
goto_11:;
MMC_THROW_INTERNAL();
goto tmp12_done;
tmp12_done:;
}
}
{
modelica_metatype tmp18_1;
tmp18_1 = _connectEquation;
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
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp18_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,1,3) == 0) goto tmp17_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 2));
if (0 != MMC_STRLEN(tmpMeta21) || strcmp(MMC_STRINGDATA(_OMC_LIT21), MMC_STRINGDATA(tmpMeta21)) != 0) goto tmp17_end;
tmpMeta22 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta15 = tmpMeta22;
goto tmp17_done;
}
case 1: {
modelica_metatype tmpMeta23;
tmpMeta23 = mmc_mk_cons(_connectEquation, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta15 = tmpMeta23;
goto tmp17_done;
}
}
goto tmp17_end;
tmp17_end: ;
}
goto goto_16;
goto_16:;
MMC_THROW_INTERNAL();
goto tmp17_done;
tmp17_done:;
}
}tmpMeta24 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta25 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta26 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta27 = mmc_mk_box8(3, &DAE_ElementSource_SOURCE__desc, _fileInfo, tmpMeta1, tmpMeta10, tmpMeta15, tmpMeta24, tmpMeta25, tmpMeta26);
_source = tmpMeta27;
_return: OMC_LABEL_UNUSED
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_addCommentToSource(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _commentIn)
{
modelica_metatype _source = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _source;
tmp4_2 = _commentIn;
{
modelica_metatype _comment = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
_comment = tmpMeta6;
tmpMeta8 = mmc_mk_cons(_comment, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_source), 8))));
tmpMeta7 = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta7), MMC_UNTAGPTR(_source), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta7))[8] = tmpMeta8;
_source = tmpMeta7;
tmpMeta1 = _source;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _source;
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
_source = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_mergeSources(threadData_t *threadData, modelica_metatype _src1, modelica_metatype _src2)
{
modelica_metatype _mergedSrc = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _src1;
tmp4_2 = _src2;
{
modelica_metatype _info = NULL;
modelica_metatype _partOfLst1 = NULL;
modelica_metatype _partOfLst2 = NULL;
modelica_metatype _p = NULL;
modelica_metatype _instanceOpt1 = NULL;
modelica_metatype _instanceOpt2 = NULL;
modelica_metatype _i = NULL;
modelica_metatype _connectEquationOptLst1 = NULL;
modelica_metatype _connectEquationOptLst2 = NULL;
modelica_metatype _c = NULL;
modelica_metatype _typeLst1 = NULL;
modelica_metatype _typeLst2 = NULL;
modelica_metatype _t = NULL;
modelica_metatype _o = NULL;
modelica_metatype _operations1 = NULL;
modelica_metatype _operations2 = NULL;
modelica_metatype _comment = NULL;
modelica_metatype _comment1 = NULL;
modelica_metatype _comment2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
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
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta24;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 6));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 7));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 8));
_info = tmpMeta6;
_partOfLst1 = tmpMeta7;
_instanceOpt1 = tmpMeta8;
_connectEquationOptLst1 = tmpMeta9;
_typeLst1 = tmpMeta10;
_operations1 = tmpMeta11;
_comment1 = tmpMeta12;
_partOfLst2 = tmpMeta13;
_instanceOpt2 = tmpMeta14;
_connectEquationOptLst2 = tmpMeta15;
_typeLst2 = tmpMeta16;
_operations2 = tmpMeta17;
_comment2 = tmpMeta18;
_p = omc_List_union(threadData, _partOfLst1, _partOfLst2);
{
modelica_metatype tmp22_1;
tmp22_1 = _instanceOpt1;
{
volatile mmc_switch_type tmp22;
int tmp23;
tmp22 = 0;
for (; tmp22 < 2; tmp22++) {
switch (MMC_SWITCH_CAST(tmp22)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp22_1,1,0) == 0) goto tmp21_end;
tmpMeta19 = _instanceOpt2;
goto tmp21_done;
}
case 1: {
tmpMeta19 = _instanceOpt1;
goto tmp21_done;
}
}
goto tmp21_end;
tmp21_end: ;
}
goto goto_20;
goto_20:;
goto goto_2;
goto tmp21_done;
tmp21_done:;
}
}
_i = tmpMeta19;
_c = omc_List_union(threadData, _connectEquationOptLst1, _connectEquationOptLst2);
_t = omc_List_union(threadData, _typeLst1, _typeLst2);
_o = listAppend(_operations1, _operations2);
_comment = omc_List_union(threadData, _comment1, _comment2);
tmpMeta24 = mmc_mk_box8(3, &DAE_ElementSource_SOURCE__desc, _info, _p, _i, _c, _t, _o, _comment);
tmpMeta1 = tmpMeta24;
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
_mergedSrc = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _mergedSrc;
}
