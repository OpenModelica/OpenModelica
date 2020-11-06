#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/IOStream.c"
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
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
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
modelica_integer tmp5;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
_fileID = tmp5;
omc_IOStreamExt_printFile(threadData, _fileID, _whereToPrint);
goto tmp2_done;
}
case 1: {
modelica_integer tmp6;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp6 = mmc_unbox_integer(tmpMeta[1]);
_bufferID = tmp6;
omc_IOStreamExt_printBuffer(threadData, _bufferID, _whereToPrint);
goto tmp2_done;
}
case 2: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_listData = tmpMeta[1];
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
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
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
modelica_integer tmp6;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp6 = mmc_unbox_integer(tmpMeta[1]);
_fileID = tmp6;
tmp1 = omc_IOStreamExt_readFile(threadData, _fileID);
goto tmp3_done;
}
case 1: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_listData = tmpMeta[1];
tmp1 = omc_IOStreamExt_appendReversedList(threadData, _listData);
goto tmp3_done;
}
case 2: {
modelica_integer tmp7;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp7 = mmc_unbox_integer(tmpMeta[1]);
_bufferID = tmp7;
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inStream;
{
modelica_integer _fileID;
modelica_integer _bufferID;
modelica_metatype _fStream = NULL;
modelica_metatype _bStream = NULL;
modelica_string _name = NULL;
modelica_metatype _ty = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp5 = mmc_unbox_integer(tmpMeta[2]);
_fStream = tmp3_1;
_fileID = tmp5;
omc_IOStreamExt_clearFile(threadData, _fileID);
tmpMeta[0] = _fStream;
goto tmp2_done;
}
case 1: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_name = tmpMeta[1];
_ty = tmpMeta[2];
tmpMeta[1] = mmc_mk_box4(3, &IOStream_IOStream_IOSTREAM__desc, _name, _ty, _OMC_LIT0);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
modelica_integer tmp6;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
_bStream = tmp3_1;
_bufferID = tmp6;
omc_IOStreamExt_clearBuffer(threadData, _bufferID);
tmpMeta[0] = _bStream;
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
if (++tmp3 < 3) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outStream = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outStream;
}
DLLExport
void omc_IOStream_delete(threadData_t *threadData, modelica_metatype _inStream)
{
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
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
modelica_integer tmp5;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
_fileID = tmp5;
omc_IOStreamExt_deleteFile(threadData, _fileID);
goto tmp2_done;
}
case 1: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,1) == 0) goto tmp2_end;
goto tmp2_done;
}
case 2: {
modelica_integer tmp6;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp6 = mmc_unbox_integer(tmpMeta[1]);
_bufferID = tmp6;
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inStream;
{
modelica_integer _fileID;
modelica_metatype _fStream = NULL;
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
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp5 = mmc_unbox_integer(tmpMeta[2]);
_fStream = tmp3_1;
_fileID = tmp5;
omc_IOStreamExt_closeFile(threadData, _fileID);
tmpMeta[0] = _fStream;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _inStream;
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
_outStream = tmpMeta[0];
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
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inStream;
{
modelica_metatype _listData = NULL;
modelica_integer _fileID;
modelica_integer _bufferID;
modelica_metatype _fStream = NULL;
modelica_metatype _bStream = NULL;
modelica_string _streamName = NULL;
modelica_metatype _streamType = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp5 = mmc_unbox_integer(tmpMeta[2]);
_fStream = tmp3_1;
_fileID = tmp5;
omc_IOStreamExt_appendFile(threadData, _fileID, _inString);
tmpMeta[0] = _fStream;
goto tmp2_done;
}
case 1: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],1,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
_streamName = tmpMeta[1];
_streamType = tmpMeta[2];
_listData = tmpMeta[4];
tmpMeta[1] = mmc_mk_cons(_inString, _listData);
tmpMeta[2] = mmc_mk_box2(4, &IOStream_IOStreamData_LIST__DATA__desc, tmpMeta[1]);
tmpMeta[3] = mmc_mk_box4(3, &IOStream_IOStream_IOSTREAM__desc, _streamName, _streamType, tmpMeta[2]);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 2: {
modelica_integer tmp6;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
_bStream = tmp3_1;
_bufferID = tmp6;
omc_IOStreamExt_appendBuffer(threadData, _bufferID, _inString);
tmpMeta[0] = _bStream;
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
_outStream = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outStream;
}
DLLExport
modelica_metatype omc_IOStream_create(threadData_t *threadData, modelica_string _streamName, modelica_metatype _streamType)
{
modelica_metatype _outStream = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _streamType;
{
modelica_string _fileName = NULL;
modelica_integer _fileID;
modelica_integer _bufferID;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_fileName = tmpMeta[1];
_fileID = omc_IOStreamExt_createFile(threadData, _fileName);
tmpMeta[1] = mmc_mk_box2(3, &IOStream_IOStreamData_FILE__DATA__desc, mmc_mk_integer(_fileID));
tmpMeta[2] = mmc_mk_box4(3, &IOStream_IOStream_IOSTREAM__desc, _streamName, _streamType, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 4: {
tmpMeta[1] = mmc_mk_box4(3, &IOStream_IOStream_IOSTREAM__desc, _streamName, _streamType, _OMC_LIT0);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 5: {
_bufferID = omc_IOStreamExt_createBuffer(threadData);
tmpMeta[1] = mmc_mk_box2(5, &IOStream_IOStreamData_BUFFER__DATA__desc, mmc_mk_integer(_bufferID));
tmpMeta[2] = mmc_mk_box4(3, &IOStream_IOStream_IOSTREAM__desc, _streamName, _streamType, tmpMeta[1]);
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
_outStream = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outStream;
}
