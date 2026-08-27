#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/ElementSource.c"
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
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(95)),_OMC_LIT0,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT2}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "visxml"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,6,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "Outputs a xml-file that contains information for visualization."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,63,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT5}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(129)),_OMC_LIT4,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT6}};
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
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
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
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_source), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = _instanceOpt;
_source = tmpMeta[0];
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
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!(omc_Flags_isSet(threadData, _OMC_LIT3) || omc_Flags_isSet(threadData, _OMC_LIT7))))
{
goto _return;
}
{
modelica_metatype tmp3_1;
tmp3_1 = _source;
{
modelica_metatype _info = NULL;
modelica_metatype _typeLst = NULL;
modelica_metatype _partOfLst = NULL;
modelica_metatype _instanceOpt = NULL;
modelica_metatype _connectEquationOptLst = NULL;
modelica_metatype _operations = NULL;
modelica_metatype _comment = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
_info = tmpMeta[1];
_partOfLst = tmpMeta[2];
_instanceOpt = tmpMeta[3];
_connectEquationOptLst = tmpMeta[4];
_typeLst = tmpMeta[5];
_operations = tmpMeta[6];
_comment = tmpMeta[7];
tmpMeta[1] = mmc_mk_cons(_classPath, _typeLst);
tmpMeta[2] = mmc_mk_box8(3, &DAE_ElementSource_SOURCE__desc, _info, _partOfLst, _instanceOpt, _connectEquationOptLst, tmpMeta[1], _operations, _comment);
tmpMeta[0] = tmpMeta[2];
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
_source = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_addElementSourceConnect(threadData_t *threadData, modelica_metatype _inSource, modelica_metatype _connectEquationOpt)
{
modelica_metatype _outSource = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inSource;
{
modelica_metatype _info = NULL;
modelica_metatype _partOfLst = NULL;
modelica_metatype _instanceOpt = NULL;
modelica_metatype _connectEquationOptLst = NULL;
modelica_metatype _typeLst = NULL;
modelica_metatype _operations = NULL;
modelica_metatype _comment = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
_info = tmpMeta[1];
_partOfLst = tmpMeta[2];
_instanceOpt = tmpMeta[3];
_connectEquationOptLst = tmpMeta[4];
_typeLst = tmpMeta[5];
_operations = tmpMeta[6];
_comment = tmpMeta[7];
tmpMeta[1] = mmc_mk_cons(_connectEquationOpt, _connectEquationOptLst);
tmpMeta[2] = mmc_mk_box8(3, &DAE_ElementSource_SOURCE__desc, _info, _partOfLst, _instanceOpt, tmpMeta[1], _typeLst, _operations, _comment);
tmpMeta[0] = tmpMeta[2];
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
_outSource = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outSource;
}
DLLExport
modelica_metatype omc_ElementSource_addElementSourceFileInfo(threadData_t *threadData, modelica_metatype _source, modelica_metatype _fileInfo)
{
modelica_metatype _outSource = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outSource = _source;
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_outSource), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _fileInfo;
_outSource = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outSource;
}
DLLExport
modelica_metatype omc_ElementSource_addElementSourcePartOfOpt(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _classPathOpt)
{
modelica_metatype _source = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!(omc_Flags_isSet(threadData, _OMC_LIT3) || omc_Flags_isSet(threadData, _OMC_LIT7))))
{
goto _return;
}
{
modelica_metatype tmp3_1;
tmp3_1 = _classPathOpt;
{
modelica_metatype _classPath = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[0] = _source;
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
_classPath = tmpMeta[1];
tmpMeta[1] = mmc_mk_box2(3, &Absyn_Within_WITHIN__desc, _classPath);
tmpMeta[0] = omc_ElementSource_addElementSourcePartOf(threadData, _source, tmpMeta[1]);
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
_source = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_addElementSourcePartOf(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _withinPath)
{
modelica_metatype _source = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!(omc_Flags_isSet(threadData, _OMC_LIT3) || omc_Flags_isSet(threadData, _OMC_LIT7))))
{
goto _return;
}
tmpMeta[1] = mmc_mk_cons(_withinPath, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_source), 3))));
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_source), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = tmpMeta[1];
_source = tmpMeta[0];
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
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _stmt;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 5)));
goto tmp2_done;
}
case 4: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 5)));
goto tmp2_done;
}
case 5: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 5)));
goto tmp2_done;
}
case 6: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 5)));
goto tmp2_done;
}
case 7: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 8)));
goto tmp2_done;
}
case 8: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 9)));
goto tmp2_done;
}
case 9: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 4)));
goto tmp2_done;
}
case 10: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 7)));
goto tmp2_done;
}
case 11: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 5)));
goto tmp2_done;
}
case 12: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 3)));
goto tmp2_done;
}
case 13: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 4)));
goto tmp2_done;
}
case 14: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 3)));
goto tmp2_done;
}
case 15: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 2)));
goto tmp2_done;
}
case 16: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 2)));
goto tmp2_done;
}
case 18: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 4)));
goto tmp2_done;
}
case 19: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 3)));
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
_source = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_getElementSource(threadData_t *threadData, modelica_metatype _element)
{
modelica_metatype _source = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _element;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 11)));
goto tmp2_done;
}
case 4: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4)));
goto tmp2_done;
}
case 5: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4)));
goto tmp2_done;
}
case 6: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4)));
goto tmp2_done;
}
case 7: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4)));
goto tmp2_done;
}
case 8: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 5)));
goto tmp2_done;
}
case 9: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 5)));
goto tmp2_done;
}
case 11: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4)));
goto tmp2_done;
}
case 12: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4)));
goto tmp2_done;
}
case 13: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 5)));
goto tmp2_done;
}
case 15: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 5)));
goto tmp2_done;
}
case 16: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 5)));
goto tmp2_done;
}
case 17: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4)));
goto tmp2_done;
}
case 18: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 3)));
goto tmp2_done;
}
case 19: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 3)));
goto tmp2_done;
}
case 20: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4)));
goto tmp2_done;
}
case 21: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 3)));
goto tmp2_done;
}
case 22: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 5)));
goto tmp2_done;
}
case 23: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 5)));
goto tmp2_done;
}
case 24: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 3)));
goto tmp2_done;
}
case 25: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 3)));
goto tmp2_done;
}
case 26: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4)));
goto tmp2_done;
}
case 27: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 3)));
goto tmp2_done;
}
case 29: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 3)));
goto tmp2_done;
}
case 28: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 3)));
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
omc_Error_addMessage(threadData, _OMC_LIT12, _OMC_LIT14);
goto goto_1;
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
_source = tmpMeta[0];
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!(_add && omc_Flags_isSet(threadData, _OMC_LIT3))))
{
goto _return;
}
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp1;
modelica_metatype __omcQ_24tmpVar0;
int tmp2;
modelica_metatype _ass_loopVar = 0;
modelica_metatype _ass;
_ass_loopVar = _asserts;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta[1];
tmp1 = &__omcQ_24tmpVar1;
while(1) {
tmp2 = 1;
if (!listEmpty(_ass_loopVar)) {
_ass = MMC_CAR(_ass_loopVar);
_ass_loopVar = MMC_CDR(_ass_loopVar);
tmp2--;
}
if (tmp2 == 0) {
__omcQ_24tmpVar0 = omc_Algorithm_getAssertCond(threadData, _ass);
*tmp1 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp1 = &MMC_CDR(*tmp1);
} else if (tmp2 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp1 = mmc_mk_nil();
tmpMeta[0] = __omcQ_24tmpVar1;
}
tmpMeta[2] = mmc_mk_box6(9, &DAE_SymbolicOperation_SOLVE__desc, _cr, _exp1, _exp2, _exp, tmpMeta[0]);
_op1 = tmpMeta[2];
tmpMeta[0] = mmc_mk_box3(10, &DAE_SymbolicOperation_SOLVED__desc, _cr, _exp2);
_op2 = tmpMeta[0];
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
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!omc_Flags_isSet(threadData, _OMC_LIT3)))
{
goto _return;
}
tmpMeta[0] = mmc_mk_box3(4, &DAE_SymbolicOperation_SIMPLIFY__desc, _exp1, _exp2);
_source = omc_ElementSource_condAddSymbolicTransformation(threadData, _add, _source, tmpMeta[0]);
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
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!omc_Flags_isSet(threadData, _OMC_LIT3)))
{
goto _return;
}
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;modelica_metatype tmp3_3;
tmp3_1 = _add;
tmp3_2 = _explst1;
tmp3_3 = _explst2;
{
modelica_metatype _brest = NULL;
modelica_metatype _rexplst1 = NULL;
modelica_metatype _rexplst2 = NULL;
modelica_metatype _exp1 = NULL;
modelica_metatype _exp2 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = _source;
goto tmp2_done;
}
case 1: {
modelica_integer tmp5;
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
if (listEmpty(tmp3_3)) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmp3_3);
tmpMeta[4] = MMC_CDR(tmp3_3);
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmp3_1);
tmpMeta[6] = MMC_CDR(tmp3_1);
tmp5 = mmc_unbox_integer(tmpMeta[5]);
if (1 != tmp5) goto tmp2_end;
_exp1 = tmpMeta[1];
_rexplst1 = tmpMeta[2];
_exp2 = tmpMeta[3];
_rexplst2 = tmpMeta[4];
_brest = tmpMeta[6];
tmpMeta[1] = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _exp1);
tmpMeta[2] = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _exp2);
tmpMeta[3] = mmc_mk_box3(4, &DAE_SymbolicOperation_SIMPLIFY__desc, tmpMeta[1], tmpMeta[2]);
_source = omc_ElementSource_addSymbolicTransformation(threadData, _source, tmpMeta[3]);
_add = _brest;
__omcQ_24in_5Fsource = _source;
_explst1 = _rexplst1;
_explst2 = _rexplst2;
goto _tailrecursive;
goto tmp2_done;
}
case 2: {
modelica_integer tmp6;
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
if (listEmpty(tmp3_3)) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmp3_3);
tmpMeta[4] = MMC_CDR(tmp3_3);
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmp3_1);
tmpMeta[6] = MMC_CDR(tmp3_1);
tmp6 = mmc_unbox_integer(tmpMeta[5]);
if (0 != tmp6) goto tmp2_end;
_rexplst1 = tmpMeta[2];
_rexplst2 = tmpMeta[4];
_brest = tmpMeta[6];
_add = _brest;
__omcQ_24in_5Fsource = _source;
_explst1 = _rexplst1;
_explst2 = _rexplst2;
goto _tailrecursive;
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
_source = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_addSymbolicTransformationSubstitution(threadData_t *threadData, modelica_boolean _add, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _exp1, modelica_metatype _exp2)
{
modelica_metatype _source = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!omc_Flags_isSet(threadData, _OMC_LIT3)))
{
goto _return;
}
tmpMeta[0] = mmc_mk_cons(_exp2, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[1] = mmc_mk_box3(5, &DAE_SymbolicOperation_SUBSTITUTION__desc, tmpMeta[0], _exp1);
_source = omc_ElementSource_condAddSymbolicTransformation(threadData, _add, _source, tmpMeta[1]);
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
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!omc_Flags_isSet(threadData, _OMC_LIT3)))
{
goto _return;
}
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;modelica_metatype tmp3_3;
tmp3_1 = _add;
tmp3_2 = _explst1;
tmp3_3 = _explst2;
{
modelica_metatype _brest = NULL;
modelica_metatype _rexplst1 = NULL;
modelica_metatype _rexplst2 = NULL;
modelica_metatype _exp1 = NULL;
modelica_metatype _exp2 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = _source;
goto tmp2_done;
}
case 1: {
modelica_integer tmp5;
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
if (listEmpty(tmp3_3)) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmp3_3);
tmpMeta[4] = MMC_CDR(tmp3_3);
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmp3_1);
tmpMeta[6] = MMC_CDR(tmp3_1);
tmp5 = mmc_unbox_integer(tmpMeta[5]);
if (1 != tmp5) goto tmp2_end;
_exp1 = tmpMeta[1];
_rexplst1 = tmpMeta[2];
_exp2 = tmpMeta[3];
_rexplst2 = tmpMeta[4];
_brest = tmpMeta[6];
_source = omc_ElementSource_addSymbolicTransformationSubstitution(threadData, 1, _source, _exp1, _exp2);
_add = _brest;
__omcQ_24in_5Fsource = _source;
_explst1 = _rexplst1;
_explst2 = _rexplst2;
goto _tailrecursive;
goto tmp2_done;
}
case 2: {
modelica_integer tmp6;
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
if (listEmpty(tmp3_3)) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmp3_3);
tmpMeta[4] = MMC_CDR(tmp3_3);
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmp3_1);
tmpMeta[6] = MMC_CDR(tmp3_1);
tmp6 = mmc_unbox_integer(tmpMeta[5]);
if (0 != tmp6) goto tmp2_end;
_rexplst1 = tmpMeta[2];
_rexplst2 = tmpMeta[4];
_brest = tmpMeta[6];
_add = _brest;
__omcQ_24in_5Fsource = _source;
_explst1 = _rexplst1;
_explst2 = _rexplst2;
goto _tailrecursive;
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
_source = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_addSymbolicTransformationFlattenedEqs(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _elt)
{
modelica_metatype _source = NULL;
modelica_metatype tmpMeta[12] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!omc_Flags_isSet(threadData, _OMC_LIT3)))
{
goto _return;
}
{
modelica_metatype tmp3_1;
tmp3_1 = _source;
{
modelica_metatype _info = NULL;
modelica_metatype _typeLst = NULL;
modelica_metatype _partOfLst = NULL;
modelica_metatype _instanceOpt = NULL;
modelica_metatype _connectEquationOptLst = NULL;
modelica_metatype _operations = NULL;
modelica_metatype _comment = NULL;
modelica_metatype _scode = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],0,2) == 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 3));
if (!optionNone(tmpMeta[10])) goto tmp2_end;
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
_info = tmpMeta[1];
_partOfLst = tmpMeta[2];
_instanceOpt = tmpMeta[3];
_connectEquationOptLst = tmpMeta[4];
_typeLst = tmpMeta[5];
_scode = tmpMeta[9];
_operations = tmpMeta[8];
_comment = tmpMeta[11];
tmpMeta[2] = mmc_mk_box3(3, &DAE_SymbolicOperation_FLATTEN__desc, _scode, mmc_mk_some(_elt));
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _operations);
tmpMeta[3] = mmc_mk_box8(3, &DAE_ElementSource_SOURCE__desc, _info, _partOfLst, _instanceOpt, _connectEquationOptLst, _typeLst, tmpMeta[1], _comment);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 1: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_info = tmpMeta[1];
omc_Error_addSourceMessage(threadData, _OMC_LIT12, _OMC_LIT16, _info);
goto goto_1;
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
_source = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_addSymbolicTransformationDeriveLst(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _explst1, modelica_metatype _explst2)
{
modelica_metatype _source = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!omc_Flags_isSet(threadData, _OMC_LIT3)))
{
goto _return;
}
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _explst1;
tmp3_2 = _explst2;
{
modelica_metatype _op = NULL;
modelica_metatype _rexplst1 = NULL;
modelica_metatype _rexplst2 = NULL;
modelica_metatype _exp1 = NULL;
modelica_metatype _exp2 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = _source;
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmp3_2);
tmpMeta[4] = MMC_CDR(tmp3_2);
_exp1 = tmpMeta[1];
_rexplst1 = tmpMeta[2];
_exp2 = tmpMeta[3];
_rexplst2 = tmpMeta[4];
tmpMeta[1] = mmc_mk_box4(8, &DAE_SymbolicOperation_OP__DIFFERENTIATE__desc, _OMC_LIT19, _exp1, _exp2);
_op = tmpMeta[1];
_source = omc_ElementSource_addSymbolicTransformation(threadData, _source, _op);
__omcQ_24in_5Fsource = _source;
_explst1 = _rexplst1;
_explst2 = _rexplst2;
goto _tailrecursive;
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
_source = tmpMeta[0];
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
modelica_metatype tmpMeta[16] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
if((!omc_Flags_isSet(threadData, _OMC_LIT3)))
{
goto _return;
}
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _source;
tmp3_2 = _op;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_CAR(tmpMeta[8]);
tmpMeta[10] = MMC_CDR(tmpMeta[8]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[9],2,2) == 0) goto tmp2_end;
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[9]), 2));
if (listEmpty(tmpMeta[11])) goto tmp2_end;
tmpMeta[12] = MMC_CAR(tmpMeta[11]);
tmpMeta[13] = MMC_CDR(tmpMeta[11]);
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[9]), 3));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
_es2 = tmpMeta[1];
_t2 = tmpMeta[2];
_info = tmpMeta[3];
_partOfLst = tmpMeta[4];
_instanceOpt = tmpMeta[5];
_connectEquationOptLst = tmpMeta[6];
_typeLst = tmpMeta[7];
_es1 = tmpMeta[11];
_h1 = tmpMeta[12];
_t1 = tmpMeta[14];
_operations = tmpMeta[10];
_comment = tmpMeta[15];
if (!omc_Expression_expEqual(threadData, _t2, _h1)) goto tmp2_end;
_es = listAppend(_es2, _es1);
tmpMeta[2] = mmc_mk_box3(5, &DAE_SymbolicOperation_SUBSTITUTION__desc, _es, _t1);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _operations);
tmpMeta[3] = mmc_mk_box8(3, &DAE_ElementSource_SOURCE__desc, _info, _partOfLst, _instanceOpt, _connectEquationOptLst, _typeLst, tmpMeta[1], _comment);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 1: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
_info = tmpMeta[1];
_partOfLst = tmpMeta[2];
_instanceOpt = tmpMeta[3];
_connectEquationOptLst = tmpMeta[4];
_typeLst = tmpMeta[5];
_operations = tmpMeta[6];
_comment = tmpMeta[7];
tmpMeta[1] = mmc_mk_cons(_op, _operations);
tmpMeta[2] = mmc_mk_box8(3, &DAE_ElementSource_SOURCE__desc, _info, _partOfLst, _instanceOpt, _connectEquationOptLst, _typeLst, tmpMeta[1], _comment);
tmpMeta[0] = tmpMeta[2];
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
_source = tmpMeta[0];
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
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _source;
{
modelica_metatype _comment = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
_comment = tmpMeta[1];
tmpMeta[0] = _comment;
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
_outComments = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outComments;
}
DLLExport
modelica_metatype omc_ElementSource_addAnnotation(threadData_t *threadData, modelica_metatype _source, modelica_metatype _comment)
{
modelica_metatype _outSource = NULL;
modelica_metatype tmpMeta[10] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _source;
tmp3_2 = _comment;
{
modelica_metatype _info = NULL;
modelica_metatype _typeLst = NULL;
modelica_metatype _partOfLst = NULL;
modelica_metatype _instanceOpt = NULL;
modelica_metatype _connectEquationOptLst = NULL;
modelica_metatype _operations = NULL;
modelica_metatype _commentLst = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
_info = tmpMeta[3];
_partOfLst = tmpMeta[4];
_instanceOpt = tmpMeta[5];
_connectEquationOptLst = tmpMeta[6];
_typeLst = tmpMeta[7];
_operations = tmpMeta[8];
_commentLst = tmpMeta[9];
tmpMeta[1] = mmc_mk_cons(_comment, _commentLst);
tmpMeta[2] = mmc_mk_box8(3, &DAE_ElementSource_SOURCE__desc, _info, _partOfLst, _instanceOpt, _connectEquationOptLst, _typeLst, _operations, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _source;
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
_outSource = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outSource;
}
DLLExport
modelica_metatype omc_ElementSource_addAdditionalComment(threadData_t *threadData, modelica_metatype _source, modelica_string _message)
{
modelica_metatype _outSource = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _source;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
_info = tmpMeta[1];
_partOfLst = tmpMeta[2];
_instanceOpt = tmpMeta[3];
_connectEquationOptLst = tmpMeta[4];
_typeLst = tmpMeta[5];
_operations = tmpMeta[6];
_comment = tmpMeta[7];
tmpMeta[1] = mmc_mk_box3(3, &SCode_Comment_COMMENT__desc, mmc_mk_none(), mmc_mk_some(_message));
_c = tmpMeta[1];
_b = listMember(_c, _comment);
tmp5 = (modelica_boolean)_b;
if(tmp5)
{
tmpMeta[2] = _comment;
}
else
{
tmpMeta[1] = mmc_mk_cons(_c, _comment);
tmpMeta[2] = tmpMeta[1];
}
_comment = tmpMeta[2];
tmpMeta[1] = mmc_mk_box8(3, &DAE_ElementSource_SOURCE__desc, _info, _partOfLst, _instanceOpt, _connectEquationOptLst, _typeLst, _operations, _comment);
tmpMeta[0] = tmpMeta[1];
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
_outSource = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outSource;
}
DLLExport
modelica_metatype omc_ElementSource_createElementSource(threadData_t *threadData, modelica_metatype _fileInfo, modelica_metatype _partOf, modelica_metatype _prefix, modelica_metatype _connectEquation)
{
modelica_metatype _source = NULL;
modelica_metatype _path = NULL;
modelica_metatype tmpMeta[10] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _partOf;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
_path = tmpMeta[1];
tmpMeta[2] = mmc_mk_box2(3, &Absyn_Within_WITHIN__desc, _path);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = tmpMeta[1];
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
{
modelica_metatype tmp7_1;
tmp7_1 = _prefix;
{
volatile mmc_switch_type tmp7;
int tmp8;
tmp7 = 0;
for (; tmp7 < 2; tmp7++) {
switch (MMC_SWITCH_CAST(tmp7)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,0,0) == 0) goto tmp6_end;
tmpMeta[3] = _OMC_LIT25;
goto tmp6_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,1,2) == 0) goto tmp6_end;
tmpMeta[3] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefix), 2)));
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
{
modelica_metatype tmp11_1;
tmp11_1 = _connectEquation;
{
volatile mmc_switch_type tmp11;
int tmp12;
tmp11 = 0;
for (; tmp11 < 2; tmp11++) {
switch (MMC_SWITCH_CAST(tmp11)) {
case 0: {
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp11_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],1,3) == 0) goto tmp10_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
if (0 != MMC_STRLEN(tmpMeta[6]) || strcmp(MMC_STRINGDATA(_OMC_LIT21), MMC_STRINGDATA(tmpMeta[6])) != 0) goto tmp10_end;
tmpMeta[5] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[4] = tmpMeta[5];
goto tmp10_done;
}
case 1: {
tmpMeta[5] = mmc_mk_cons(_connectEquation, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[4] = tmpMeta[5];
goto tmp10_done;
}
}
goto tmp10_end;
tmp10_end: ;
}
goto goto_9;
goto_9:;
MMC_THROW_INTERNAL();
goto tmp10_done;
tmp10_done:;
}
}tmpMeta[6] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[7] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[8] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[9] = mmc_mk_box8(3, &DAE_ElementSource_SOURCE__desc, _fileInfo, tmpMeta[0], tmpMeta[3], tmpMeta[4], tmpMeta[6], tmpMeta[7], tmpMeta[8]);
_source = tmpMeta[9];
_return: OMC_LABEL_UNUSED
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_addCommentToSource(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype _commentIn)
{
modelica_metatype _source = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_source = __omcQ_24in_5Fsource;
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _source;
tmp3_2 = _commentIn;
{
modelica_metatype _comment = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 1));
_comment = tmpMeta[1];
tmpMeta[2] = mmc_mk_cons(_comment, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_source), 8))));
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_source), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[8] = tmpMeta[2];
_source = tmpMeta[1];
tmpMeta[0] = _source;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _source;
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
_source = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _source;
}
DLLExport
modelica_metatype omc_ElementSource_mergeSources(threadData_t *threadData, modelica_metatype _src1, modelica_metatype _src2)
{
modelica_metatype _mergedSrc = NULL;
modelica_metatype tmpMeta[14] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _src1;
tmp3_2 = _src2;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 5));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 6));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 7));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 8));
_info = tmpMeta[1];
_partOfLst1 = tmpMeta[2];
_instanceOpt1 = tmpMeta[3];
_connectEquationOptLst1 = tmpMeta[4];
_typeLst1 = tmpMeta[5];
_operations1 = tmpMeta[6];
_comment1 = tmpMeta[7];
_partOfLst2 = tmpMeta[8];
_instanceOpt2 = tmpMeta[9];
_connectEquationOptLst2 = tmpMeta[10];
_typeLst2 = tmpMeta[11];
_operations2 = tmpMeta[12];
_comment2 = tmpMeta[13];
_p = omc_List_union(threadData, _partOfLst1, _partOfLst2);
{
modelica_metatype tmp7_1;
tmp7_1 = _instanceOpt1;
{
volatile mmc_switch_type tmp7;
int tmp8;
tmp7 = 0;
for (; tmp7 < 2; tmp7++) {
switch (MMC_SWITCH_CAST(tmp7)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,1,0) == 0) goto tmp6_end;
tmpMeta[1] = _instanceOpt2;
goto tmp6_done;
}
case 1: {
tmpMeta[1] = _instanceOpt1;
goto tmp6_done;
}
}
goto tmp6_end;
tmp6_end: ;
}
goto goto_5;
goto_5:;
goto goto_1;
goto tmp6_done;
tmp6_done:;
}
}
_i = tmpMeta[1];
_c = omc_List_union(threadData, _connectEquationOptLst1, _connectEquationOptLst2);
_t = omc_List_union(threadData, _typeLst1, _typeLst2);
_o = listAppend(_operations1, _operations2);
_comment = omc_List_union(threadData, _comment1, _comment2);
tmpMeta[1] = mmc_mk_box8(3, &DAE_ElementSource_SOURCE__desc, _info, _p, _i, _c, _t, _o, _comment);
tmpMeta[0] = tmpMeta[1];
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
_mergedSrc = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _mergedSrc;
}
