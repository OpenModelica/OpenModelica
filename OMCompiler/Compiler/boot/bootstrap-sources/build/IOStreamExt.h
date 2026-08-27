#ifndef IOStreamExt__H
#define IOStreamExt__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
void omc_IOStreamExt_printReversedList(threadData_t *threadData, modelica_metatype _inStringLst, modelica_integer _whereToPrint);
DLLExport
void boxptr_IOStreamExt_printReversedList(threadData_t *threadData, modelica_metatype _inStringLst, modelica_metatype _whereToPrint);
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStreamExt_printReversedList,2,0) {(void*) boxptr_IOStreamExt_printReversedList,0}};
#define boxvar_IOStreamExt_printReversedList MMC_REFSTRUCTLIT(boxvar_lit_IOStreamExt_printReversedList)
extern void IOStreamExt_printReversedList(modelica_metatype /*_inStringLst*/, int /*_whereToPrint*/);
DLLExport
modelica_string omc_IOStreamExt_appendReversedList(threadData_t *threadData, modelica_metatype _inStringLst);
#define boxptr_IOStreamExt_appendReversedList omc_IOStreamExt_appendReversedList
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStreamExt_appendReversedList,2,0) {(void*) boxptr_IOStreamExt_appendReversedList,0}};
#define boxvar_IOStreamExt_appendReversedList MMC_REFSTRUCTLIT(boxvar_lit_IOStreamExt_appendReversedList)
extern const char* IOStreamExt_appendReversedList(modelica_metatype /*_inStringLst*/);
DLLExport
void omc_IOStreamExt_printBuffer(threadData_t *threadData, modelica_integer _bufferID, modelica_integer _whereToPrint);
DLLExport
void boxptr_IOStreamExt_printBuffer(threadData_t *threadData, modelica_metatype _bufferID, modelica_metatype _whereToPrint);
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStreamExt_printBuffer,2,0) {(void*) boxptr_IOStreamExt_printBuffer,0}};
#define boxvar_IOStreamExt_printBuffer MMC_REFSTRUCTLIT(boxvar_lit_IOStreamExt_printBuffer)
extern void IOStreamExt_printBuffer(int /*_bufferID*/, int /*_whereToPrint*/);
DLLExport
modelica_string omc_IOStreamExt_readBuffer(threadData_t *threadData, modelica_integer _bufferID);
DLLExport
modelica_metatype boxptr_IOStreamExt_readBuffer(threadData_t *threadData, modelica_metatype _bufferID);
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStreamExt_readBuffer,2,0) {(void*) boxptr_IOStreamExt_readBuffer,0}};
#define boxvar_IOStreamExt_readBuffer MMC_REFSTRUCTLIT(boxvar_lit_IOStreamExt_readBuffer)
extern const char* IOStreamExt_readBuffer(int /*_bufferID*/);
DLLExport
void omc_IOStreamExt_clearBuffer(threadData_t *threadData, modelica_integer _bufferID);
DLLExport
void boxptr_IOStreamExt_clearBuffer(threadData_t *threadData, modelica_metatype _bufferID);
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStreamExt_clearBuffer,2,0) {(void*) boxptr_IOStreamExt_clearBuffer,0}};
#define boxvar_IOStreamExt_clearBuffer MMC_REFSTRUCTLIT(boxvar_lit_IOStreamExt_clearBuffer)
extern void IOStreamExt_clearBuffer(int /*_bufferID*/);
DLLExport
void omc_IOStreamExt_deleteBuffer(threadData_t *threadData, modelica_integer _bufferID);
DLLExport
void boxptr_IOStreamExt_deleteBuffer(threadData_t *threadData, modelica_metatype _bufferID);
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStreamExt_deleteBuffer,2,0) {(void*) boxptr_IOStreamExt_deleteBuffer,0}};
#define boxvar_IOStreamExt_deleteBuffer MMC_REFSTRUCTLIT(boxvar_lit_IOStreamExt_deleteBuffer)
extern void IOStreamExt_deleteBuffer(int /*_bufferID*/);
DLLExport
void omc_IOStreamExt_appendBuffer(threadData_t *threadData, modelica_integer _bufferID, modelica_string _inString);
DLLExport
void boxptr_IOStreamExt_appendBuffer(threadData_t *threadData, modelica_metatype _bufferID, modelica_metatype _inString);
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStreamExt_appendBuffer,2,0) {(void*) boxptr_IOStreamExt_appendBuffer,0}};
#define boxvar_IOStreamExt_appendBuffer MMC_REFSTRUCTLIT(boxvar_lit_IOStreamExt_appendBuffer)
extern void IOStreamExt_appendBuffer(int /*_bufferID*/, const char* /*_inString*/);
DLLExport
modelica_integer omc_IOStreamExt_createBuffer(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_IOStreamExt_createBuffer(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStreamExt_createBuffer,2,0) {(void*) boxptr_IOStreamExt_createBuffer,0}};
#define boxvar_IOStreamExt_createBuffer MMC_REFSTRUCTLIT(boxvar_lit_IOStreamExt_createBuffer)
extern int IOStreamExt_createBuffer();
DLLExport
void omc_IOStreamExt_printFile(threadData_t *threadData, modelica_integer _fileID, modelica_integer _whereToPrint);
DLLExport
void boxptr_IOStreamExt_printFile(threadData_t *threadData, modelica_metatype _fileID, modelica_metatype _whereToPrint);
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStreamExt_printFile,2,0) {(void*) boxptr_IOStreamExt_printFile,0}};
#define boxvar_IOStreamExt_printFile MMC_REFSTRUCTLIT(boxvar_lit_IOStreamExt_printFile)
extern void IOStreamExt_printFile(int /*_fileID*/, int /*_whereToPrint*/);
DLLExport
modelica_string omc_IOStreamExt_readFile(threadData_t *threadData, modelica_integer _fileID);
DLLExport
modelica_metatype boxptr_IOStreamExt_readFile(threadData_t *threadData, modelica_metatype _fileID);
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStreamExt_readFile,2,0) {(void*) boxptr_IOStreamExt_readFile,0}};
#define boxvar_IOStreamExt_readFile MMC_REFSTRUCTLIT(boxvar_lit_IOStreamExt_readFile)
extern const char* IOStreamExt_readFile(int /*_fileID*/);
DLLExport
void omc_IOStreamExt_appendFile(threadData_t *threadData, modelica_integer _fileID, modelica_string _inString);
DLLExport
void boxptr_IOStreamExt_appendFile(threadData_t *threadData, modelica_metatype _fileID, modelica_metatype _inString);
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStreamExt_appendFile,2,0) {(void*) boxptr_IOStreamExt_appendFile,0}};
#define boxvar_IOStreamExt_appendFile MMC_REFSTRUCTLIT(boxvar_lit_IOStreamExt_appendFile)
extern void IOStreamExt_appendFile(int /*_fileID*/, const char* /*_inString*/);
DLLExport
void omc_IOStreamExt_clearFile(threadData_t *threadData, modelica_integer _fileID);
DLLExport
void boxptr_IOStreamExt_clearFile(threadData_t *threadData, modelica_metatype _fileID);
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStreamExt_clearFile,2,0) {(void*) boxptr_IOStreamExt_clearFile,0}};
#define boxvar_IOStreamExt_clearFile MMC_REFSTRUCTLIT(boxvar_lit_IOStreamExt_clearFile)
extern void IOStreamExt_clearFile(int /*_fileID*/);
DLLExport
void omc_IOStreamExt_deleteFile(threadData_t *threadData, modelica_integer _fileID);
DLLExport
void boxptr_IOStreamExt_deleteFile(threadData_t *threadData, modelica_metatype _fileID);
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStreamExt_deleteFile,2,0) {(void*) boxptr_IOStreamExt_deleteFile,0}};
#define boxvar_IOStreamExt_deleteFile MMC_REFSTRUCTLIT(boxvar_lit_IOStreamExt_deleteFile)
extern void IOStreamExt_deleteFile(int /*_fileID*/);
DLLExport
void omc_IOStreamExt_closeFile(threadData_t *threadData, modelica_integer _fileID);
DLLExport
void boxptr_IOStreamExt_closeFile(threadData_t *threadData, modelica_metatype _fileID);
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStreamExt_closeFile,2,0) {(void*) boxptr_IOStreamExt_closeFile,0}};
#define boxvar_IOStreamExt_closeFile MMC_REFSTRUCTLIT(boxvar_lit_IOStreamExt_closeFile)
extern void IOStreamExt_closeFile(int /*_fileID*/);
DLLExport
modelica_integer omc_IOStreamExt_createFile(threadData_t *threadData, modelica_string _fileName);
DLLExport
modelica_metatype boxptr_IOStreamExt_createFile(threadData_t *threadData, modelica_metatype _fileName);
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStreamExt_createFile,2,0) {(void*) boxptr_IOStreamExt_createFile,0}};
#define boxvar_IOStreamExt_createFile MMC_REFSTRUCTLIT(boxvar_lit_IOStreamExt_createFile)
extern int IOStreamExt_createFile(const char* /*_fileName*/);
#ifdef __cplusplus
}
#endif
#endif
