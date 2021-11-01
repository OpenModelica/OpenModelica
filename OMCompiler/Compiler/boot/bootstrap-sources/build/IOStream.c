#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "IOStream.c"
#endif
#include "omc_simulation_settings.h"
#include "IOStream.h"
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT0,2,4) {&IOStream_IOStreamData_LIST__DATA__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT0 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT0)
#include "util/modelica.h"
#include "IOStream_includes.h"
DLLExport
void omc_IOStream_print(threadData_t *threadData, modelica_metatype _inStream, modelica_integer _whereToPrint)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inStream;
{
modelica_metatype _listData = NULL;
modelica_integer _fileID;
modelica_integer _bufferID;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_integer tmp7;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta5,0,1) == 0) goto tmp2_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
_fileID = tmp7;
omc_IOStreamExt_printFile(threadData, _fileID, _whereToPrint);
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_integer tmp10;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,2,1) == 0) goto tmp2_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmp10 = mmc_unbox_integer(tmpMeta9);
_bufferID = tmp10;
omc_IOStreamExt_printBuffer(threadData, _bufferID, _whereToPrint);
goto tmp2_done;
}
case 2: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,1,1) == 0) goto tmp2_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
_listData = tmpMeta12;
omc_IOStreamExt_printReversedList(threadData, _listData, _whereToPrint);
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
return;
}
void boxptr_IOStream_print(threadData_t *threadData, modelica_metatype _inStream, modelica_metatype _whereToPrint)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_whereToPrint);
omc_IOStream_print(threadData, _inStream, tmp1);
return;
}
DLLExport
modelica_string omc_IOStream_string(threadData_t *threadData, modelica_metatype _inStream)
{
modelica_string _string = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inStream;
{
modelica_metatype _listData = NULL;
modelica_integer _fileID;
modelica_integer _bufferID;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_integer tmp8;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmp8 = mmc_unbox_integer(tmpMeta7);
_fileID = tmp8;
tmp1 = omc_IOStreamExt_readFile(threadData, _fileID);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,1,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
_listData = tmpMeta10;
tmp1 = omc_IOStreamExt_appendReversedList(threadData, _listData);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_integer tmp13;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,2,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
tmp13 = mmc_unbox_integer(tmpMeta12);
_bufferID = tmp13;
tmp1 = omc_IOStreamExt_readBuffer(threadData, _bufferID);
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
_string = tmp1;
_return: OMC_LABEL_UNUSED
return _string;
}
DLLExport
modelica_metatype omc_IOStream_clear(threadData_t *threadData, modelica_metatype _inStream)
{
modelica_metatype _outStream = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inStream;
{
modelica_integer _fileID;
modelica_integer _bufferID;
modelica_metatype _fStream = NULL;
modelica_metatype _bStream = NULL;
modelica_string _name = NULL;
modelica_metatype _ty = NULL;
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
modelica_integer tmp8;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmp8 = mmc_unbox_integer(tmpMeta7);
_fStream = tmp4_1;
_fileID = tmp8;
omc_IOStreamExt_clearFile(threadData, _fileID);
tmpMeta1 = _fStream;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_name = tmpMeta9;
_ty = tmpMeta10;
tmpMeta11 = mmc_mk_box4(3, &IOStream_IOStream_IOSTREAM__desc, _name, _ty, _OMC_LIT0);
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_integer tmp14;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,2,1) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
tmp14 = mmc_unbox_integer(tmpMeta13);
_bStream = tmp4_1;
_bufferID = tmp14;
omc_IOStreamExt_clearBuffer(threadData, _bufferID);
tmpMeta1 = _bStream;
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
_outStream = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStream;
}
DLLExport
void omc_IOStream_delete(threadData_t *threadData, modelica_metatype _inStream)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inStream;
{
modelica_integer _fileID;
modelica_integer _bufferID;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_integer tmp7;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta5,0,1) == 0) goto tmp2_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
_fileID = tmp7;
omc_IOStreamExt_deleteFile(threadData, _fileID);
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta8;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,1) == 0) goto tmp2_end;
goto tmp2_done;
}
case 2: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_integer tmp11;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,2,1) == 0) goto tmp2_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmp11 = mmc_unbox_integer(tmpMeta10);
_bufferID = tmp11;
omc_IOStreamExt_deleteBuffer(threadData, _bufferID);
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
return;
}
DLLExport
modelica_metatype omc_IOStream_close(threadData_t *threadData, modelica_metatype _inStream)
{
modelica_metatype _outStream = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inStream;
{
modelica_integer _fileID;
modelica_metatype _fStream = NULL;
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
modelica_integer tmp8;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmp8 = mmc_unbox_integer(tmpMeta7);
_fStream = tmp4_1;
_fileID = tmp8;
omc_IOStreamExt_closeFile(threadData, _fileID);
tmpMeta1 = _fStream;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _inStream;
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
_outStream = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStream;
}
DLLExport
modelica_metatype omc_IOStream_appendList(threadData_t *threadData, modelica_metatype _inStream, modelica_metatype _inStringList)
{
modelica_metatype _outStream = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outStream = omc_List_foldr(threadData, _inStringList, boxvar_IOStream_append, _inStream);
_return: OMC_LABEL_UNUSED
return _outStream;
}
DLLExport
modelica_metatype omc_IOStream_append(threadData_t *threadData, modelica_metatype _inStream, modelica_string _inString)
{
modelica_metatype _outStream = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inStream;
{
modelica_metatype _listData = NULL;
modelica_integer _fileID;
modelica_integer _bufferID;
modelica_metatype _fStream = NULL;
modelica_metatype _bStream = NULL;
modelica_string _streamName = NULL;
modelica_metatype _streamType = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_integer tmp8;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmp8 = mmc_unbox_integer(tmpMeta7);
_fStream = tmp4_1;
_fileID = tmp8;
omc_IOStreamExt_appendFile(threadData, _fileID, _inString);
tmpMeta1 = _fStream;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,1,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
_streamName = tmpMeta9;
_streamType = tmpMeta10;
_listData = tmpMeta12;
tmpMeta13 = mmc_mk_cons(_inString, _listData);
tmpMeta14 = mmc_mk_box2(4, &IOStream_IOStreamData_LIST__DATA__desc, tmpMeta13);
tmpMeta15 = mmc_mk_box4(3, &IOStream_IOStream_IOSTREAM__desc, _streamName, _streamType, tmpMeta14);
tmpMeta1 = tmpMeta15;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_integer tmp18;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,2,1) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
tmp18 = mmc_unbox_integer(tmpMeta17);
_bStream = tmp4_1;
_bufferID = tmp18;
omc_IOStreamExt_appendBuffer(threadData, _bufferID, _inString);
tmpMeta1 = _bStream;
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
_outStream = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStream;
}
DLLExport
modelica_metatype omc_IOStream_create(threadData_t *threadData, modelica_string _streamName, modelica_metatype _streamType)
{
modelica_metatype _outStream = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _streamType;
{
modelica_string _fileName = NULL;
modelica_integer _fileID;
modelica_integer _bufferID;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_fileName = tmpMeta5;
_fileID = omc_IOStreamExt_createFile(threadData, _fileName);
tmpMeta6 = mmc_mk_box2(3, &IOStream_IOStreamData_FILE__DATA__desc, mmc_mk_integer(_fileID));
tmpMeta7 = mmc_mk_box4(3, &IOStream_IOStream_IOSTREAM__desc, _streamName, _streamType, tmpMeta6);
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta8;
tmpMeta8 = mmc_mk_box4(3, &IOStream_IOStream_IOSTREAM__desc, _streamName, _streamType, _OMC_LIT0);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
_bufferID = omc_IOStreamExt_createBuffer(threadData);
tmpMeta9 = mmc_mk_box2(5, &IOStream_IOStreamData_BUFFER__DATA__desc, mmc_mk_integer(_bufferID));
tmpMeta10 = mmc_mk_box4(3, &IOStream_IOStream_IOSTREAM__desc, _streamName, _streamType, tmpMeta9);
tmpMeta1 = tmpMeta10;
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
_outStream = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStream;
}
