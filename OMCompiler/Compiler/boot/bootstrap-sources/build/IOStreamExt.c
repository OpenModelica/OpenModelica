#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/IOStreamExt.c"
#endif
#include "omc_simulation_settings.h"
#include "IOStreamExt.h"
#include "util/modelica.h"
#include "IOStreamExt_includes.h"
void omc_IOStreamExt_printReversedList(threadData_t *threadData, modelica_metatype _inStringLst, modelica_integer _whereToPrint)
{
modelica_metatype _inStringLst_ext;
int _whereToPrint_ext;
_inStringLst_ext = (modelica_metatype)_inStringLst;
_whereToPrint_ext = (int)_whereToPrint;
IOStreamExt_printReversedList(_inStringLst_ext, _whereToPrint_ext);
return;
}
void boxptr_IOStreamExt_printReversedList(threadData_t *threadData, modelica_metatype _inStringLst, modelica_metatype _whereToPrint)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_whereToPrint);
omc_IOStreamExt_printReversedList(threadData, _inStringLst, tmp1);
return;
}
modelica_string omc_IOStreamExt_appendReversedList(threadData_t *threadData, modelica_metatype _inStringLst)
{
modelica_metatype _inStringLst_ext;
const char* _outString_ext;
modelica_string _outString = NULL;
_inStringLst_ext = (modelica_metatype)_inStringLst;
_outString_ext = IOStreamExt_appendReversedList(_inStringLst_ext);
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
void omc_IOStreamExt_printBuffer(threadData_t *threadData, modelica_integer _bufferID, modelica_integer _whereToPrint)
{
int _bufferID_ext;
int _whereToPrint_ext;
_bufferID_ext = (int)_bufferID;
_whereToPrint_ext = (int)_whereToPrint;
IOStreamExt_printBuffer(_bufferID_ext, _whereToPrint_ext);
return;
}
void boxptr_IOStreamExt_printBuffer(threadData_t *threadData, modelica_metatype _bufferID, modelica_metatype _whereToPrint)
{
modelica_integer tmp1;
modelica_integer tmp2;
tmp1 = mmc_unbox_integer(_bufferID);
tmp2 = mmc_unbox_integer(_whereToPrint);
omc_IOStreamExt_printBuffer(threadData, tmp1, tmp2);
return;
}
modelica_string omc_IOStreamExt_readBuffer(threadData_t *threadData, modelica_integer _bufferID)
{
int _bufferID_ext;
const char* _outString_ext;
modelica_string _outString = NULL;
_bufferID_ext = (int)_bufferID;
_outString_ext = IOStreamExt_readBuffer(_bufferID_ext);
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
modelica_metatype boxptr_IOStreamExt_readBuffer(threadData_t *threadData, modelica_metatype _bufferID)
{
modelica_integer tmp1;
modelica_string _outString = NULL;
tmp1 = mmc_unbox_integer(_bufferID);
_outString = omc_IOStreamExt_readBuffer(threadData, tmp1);
return _outString;
}
void omc_IOStreamExt_clearBuffer(threadData_t *threadData, modelica_integer _bufferID)
{
int _bufferID_ext;
_bufferID_ext = (int)_bufferID;
IOStreamExt_clearBuffer(_bufferID_ext);
return;
}
void boxptr_IOStreamExt_clearBuffer(threadData_t *threadData, modelica_metatype _bufferID)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_bufferID);
omc_IOStreamExt_clearBuffer(threadData, tmp1);
return;
}
void omc_IOStreamExt_deleteBuffer(threadData_t *threadData, modelica_integer _bufferID)
{
int _bufferID_ext;
_bufferID_ext = (int)_bufferID;
IOStreamExt_deleteBuffer(_bufferID_ext);
return;
}
void boxptr_IOStreamExt_deleteBuffer(threadData_t *threadData, modelica_metatype _bufferID)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_bufferID);
omc_IOStreamExt_deleteBuffer(threadData, tmp1);
return;
}
void omc_IOStreamExt_appendBuffer(threadData_t *threadData, modelica_integer _bufferID, modelica_string _inString)
{
int _bufferID_ext;
_bufferID_ext = (int)_bufferID;
IOStreamExt_appendBuffer(_bufferID_ext, MMC_STRINGDATA(_inString));
return;
}
void boxptr_IOStreamExt_appendBuffer(threadData_t *threadData, modelica_metatype _bufferID, modelica_metatype _inString)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_bufferID);
omc_IOStreamExt_appendBuffer(threadData, tmp1, _inString);
return;
}
modelica_integer omc_IOStreamExt_createBuffer(threadData_t *threadData)
{
int _bufferID_ext;
modelica_integer _bufferID;
_bufferID_ext = IOStreamExt_createBuffer();
_bufferID = (modelica_integer)_bufferID_ext;
return _bufferID;
}
modelica_metatype boxptr_IOStreamExt_createBuffer(threadData_t *threadData)
{
modelica_integer _bufferID;
modelica_metatype out_bufferID;
_bufferID = omc_IOStreamExt_createBuffer(threadData);
out_bufferID = mmc_mk_icon(_bufferID);
return out_bufferID;
}
void omc_IOStreamExt_printFile(threadData_t *threadData, modelica_integer _fileID, modelica_integer _whereToPrint)
{
int _fileID_ext;
int _whereToPrint_ext;
_fileID_ext = (int)_fileID;
_whereToPrint_ext = (int)_whereToPrint;
IOStreamExt_printFile(_fileID_ext, _whereToPrint_ext);
return;
}
void boxptr_IOStreamExt_printFile(threadData_t *threadData, modelica_metatype _fileID, modelica_metatype _whereToPrint)
{
modelica_integer tmp1;
modelica_integer tmp2;
tmp1 = mmc_unbox_integer(_fileID);
tmp2 = mmc_unbox_integer(_whereToPrint);
omc_IOStreamExt_printFile(threadData, tmp1, tmp2);
return;
}
modelica_string omc_IOStreamExt_readFile(threadData_t *threadData, modelica_integer _fileID)
{
int _fileID_ext;
const char* _outString_ext;
modelica_string _outString = NULL;
_fileID_ext = (int)_fileID;
_outString_ext = IOStreamExt_readFile(_fileID_ext);
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
modelica_metatype boxptr_IOStreamExt_readFile(threadData_t *threadData, modelica_metatype _fileID)
{
modelica_integer tmp1;
modelica_string _outString = NULL;
tmp1 = mmc_unbox_integer(_fileID);
_outString = omc_IOStreamExt_readFile(threadData, tmp1);
return _outString;
}
void omc_IOStreamExt_appendFile(threadData_t *threadData, modelica_integer _fileID, modelica_string _inString)
{
int _fileID_ext;
_fileID_ext = (int)_fileID;
IOStreamExt_appendFile(_fileID_ext, MMC_STRINGDATA(_inString));
return;
}
void boxptr_IOStreamExt_appendFile(threadData_t *threadData, modelica_metatype _fileID, modelica_metatype _inString)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_fileID);
omc_IOStreamExt_appendFile(threadData, tmp1, _inString);
return;
}
void omc_IOStreamExt_clearFile(threadData_t *threadData, modelica_integer _fileID)
{
int _fileID_ext;
_fileID_ext = (int)_fileID;
IOStreamExt_clearFile(_fileID_ext);
return;
}
void boxptr_IOStreamExt_clearFile(threadData_t *threadData, modelica_metatype _fileID)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_fileID);
omc_IOStreamExt_clearFile(threadData, tmp1);
return;
}
void omc_IOStreamExt_deleteFile(threadData_t *threadData, modelica_integer _fileID)
{
int _fileID_ext;
_fileID_ext = (int)_fileID;
IOStreamExt_deleteFile(_fileID_ext);
return;
}
void boxptr_IOStreamExt_deleteFile(threadData_t *threadData, modelica_metatype _fileID)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_fileID);
omc_IOStreamExt_deleteFile(threadData, tmp1);
return;
}
void omc_IOStreamExt_closeFile(threadData_t *threadData, modelica_integer _fileID)
{
int _fileID_ext;
_fileID_ext = (int)_fileID;
IOStreamExt_closeFile(_fileID_ext);
return;
}
void boxptr_IOStreamExt_closeFile(threadData_t *threadData, modelica_metatype _fileID)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_fileID);
omc_IOStreamExt_closeFile(threadData, tmp1);
return;
}
modelica_integer omc_IOStreamExt_createFile(threadData_t *threadData, modelica_string _fileName)
{
int _fileID_ext;
modelica_integer _fileID;
_fileID_ext = IOStreamExt_createFile(MMC_STRINGDATA(_fileName));
_fileID = (modelica_integer)_fileID_ext;
return _fileID;
}
modelica_metatype boxptr_IOStreamExt_createFile(threadData_t *threadData, modelica_metatype _fileName)
{
modelica_integer _fileID;
modelica_metatype out_fileID;
_fileID = omc_IOStreamExt_createFile(threadData, _fileName);
out_fileID = mmc_mk_icon(_fileID);
return out_fileID;
}
