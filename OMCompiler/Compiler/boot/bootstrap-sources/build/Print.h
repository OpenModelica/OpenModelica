#ifndef Print__H
#define Print__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_boolean omc_Print_hasBufNewLineAtEnd(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Print_hasBufNewLineAtEnd(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Print_hasBufNewLineAtEnd,2,0) {(void*) boxptr_Print_hasBufNewLineAtEnd,0}};
#define boxvar_Print_hasBufNewLineAtEnd MMC_REFSTRUCTLIT(boxvar_lit_Print_hasBufNewLineAtEnd)
extern int Print_hasBufNewLineAtEnd(OpenModelica_threadData_ThreadData*);
DLLExport
void omc_Print_printBufNewLine(threadData_t *threadData);
#define boxptr_Print_printBufNewLine omc_Print_printBufNewLine
static const MMC_DEFSTRUCTLIT(boxvar_lit_Print_printBufNewLine,2,0) {(void*) boxptr_Print_printBufNewLine,0}};
#define boxvar_Print_printBufNewLine MMC_REFSTRUCTLIT(boxvar_lit_Print_printBufNewLine)
extern void Print_printBufNewLine(OpenModelica_threadData_ThreadData*);
DLLExport
void omc_Print_printBufSpace(threadData_t *threadData, modelica_integer _inNumOfSpaces);
DLLExport
void boxptr_Print_printBufSpace(threadData_t *threadData, modelica_metatype _inNumOfSpaces);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Print_printBufSpace,2,0) {(void*) boxptr_Print_printBufSpace,0}};
#define boxvar_Print_printBufSpace MMC_REFSTRUCTLIT(boxvar_lit_Print_printBufSpace)
extern void Print_printBufSpace(OpenModelica_threadData_ThreadData*, int /*_inNumOfSpaces*/);
DLLExport
modelica_integer omc_Print_getBufLength(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Print_getBufLength(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Print_getBufLength,2,0) {(void*) boxptr_Print_getBufLength,0}};
#define boxvar_Print_getBufLength MMC_REFSTRUCTLIT(boxvar_lit_Print_getBufLength)
extern int Print_getBufLength(OpenModelica_threadData_ThreadData*);
DLLExport
void omc_Print_writeBufConvertLines(threadData_t *threadData, modelica_string _filename);
#define boxptr_Print_writeBufConvertLines omc_Print_writeBufConvertLines
static const MMC_DEFSTRUCTLIT(boxvar_lit_Print_writeBufConvertLines,2,0) {(void*) boxptr_Print_writeBufConvertLines,0}};
#define boxvar_Print_writeBufConvertLines MMC_REFSTRUCTLIT(boxvar_lit_Print_writeBufConvertLines)
extern void Print_writeBufConvertLines(OpenModelica_threadData_ThreadData*, const char* /*_filename*/);
DLLExport
void omc_Print_writeBuf(threadData_t *threadData, modelica_string _filename);
#define boxptr_Print_writeBuf omc_Print_writeBuf
static const MMC_DEFSTRUCTLIT(boxvar_lit_Print_writeBuf,2,0) {(void*) boxptr_Print_writeBuf,0}};
#define boxvar_Print_writeBuf MMC_REFSTRUCTLIT(boxvar_lit_Print_writeBuf)
extern void Print_writeBuf(OpenModelica_threadData_ThreadData*, const char* /*_filename*/);
DLLExport
modelica_string omc_Print_getString(threadData_t *threadData);
#define boxptr_Print_getString omc_Print_getString
static const MMC_DEFSTRUCTLIT(boxvar_lit_Print_getString,2,0) {(void*) boxptr_Print_getString,0}};
#define boxvar_Print_getString MMC_REFSTRUCTLIT(boxvar_lit_Print_getString)
extern const char* Print_getString(OpenModelica_threadData_ThreadData*);
DLLExport
void omc_Print_clearBuf(threadData_t *threadData);
#define boxptr_Print_clearBuf omc_Print_clearBuf
static const MMC_DEFSTRUCTLIT(boxvar_lit_Print_clearBuf,2,0) {(void*) boxptr_Print_clearBuf,0}};
#define boxvar_Print_clearBuf MMC_REFSTRUCTLIT(boxvar_lit_Print_clearBuf)
extern void Print_clearBuf(OpenModelica_threadData_ThreadData*);
DLLExport
void omc_Print_printBuf(threadData_t *threadData, modelica_string _inString);
#define boxptr_Print_printBuf omc_Print_printBuf
static const MMC_DEFSTRUCTLIT(boxvar_lit_Print_printBuf,2,0) {(void*) boxptr_Print_printBuf,0}};
#define boxvar_Print_printBuf MMC_REFSTRUCTLIT(boxvar_lit_Print_printBuf)
extern void Print_printBuf(OpenModelica_threadData_ThreadData*, const char* /*_inString*/);
DLLExport
modelica_string omc_Print_getErrorString(threadData_t *threadData);
#define boxptr_Print_getErrorString omc_Print_getErrorString
static const MMC_DEFSTRUCTLIT(boxvar_lit_Print_getErrorString,2,0) {(void*) boxptr_Print_getErrorString,0}};
#define boxvar_Print_getErrorString MMC_REFSTRUCTLIT(boxvar_lit_Print_getErrorString)
extern const char* Print_getErrorString(OpenModelica_threadData_ThreadData*);
DLLExport
void omc_Print_clearErrorBuf(threadData_t *threadData);
#define boxptr_Print_clearErrorBuf omc_Print_clearErrorBuf
static const MMC_DEFSTRUCTLIT(boxvar_lit_Print_clearErrorBuf,2,0) {(void*) boxptr_Print_clearErrorBuf,0}};
#define boxvar_Print_clearErrorBuf MMC_REFSTRUCTLIT(boxvar_lit_Print_clearErrorBuf)
extern void Print_clearErrorBuf(OpenModelica_threadData_ThreadData*);
DLLExport
void omc_Print_printErrorBuf(threadData_t *threadData, modelica_string _inString);
#define boxptr_Print_printErrorBuf omc_Print_printErrorBuf
static const MMC_DEFSTRUCTLIT(boxvar_lit_Print_printErrorBuf,2,0) {(void*) boxptr_Print_printErrorBuf,0}};
#define boxvar_Print_printErrorBuf MMC_REFSTRUCTLIT(boxvar_lit_Print_printErrorBuf)
extern void Print_printErrorBuf(OpenModelica_threadData_ThreadData*, const char* /*_inString*/);
DLLExport
void omc_Print_restoreBuf(threadData_t *threadData, modelica_integer _handle);
DLLExport
void boxptr_Print_restoreBuf(threadData_t *threadData, modelica_metatype _handle);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Print_restoreBuf,2,0) {(void*) boxptr_Print_restoreBuf,0}};
#define boxvar_Print_restoreBuf MMC_REFSTRUCTLIT(boxvar_lit_Print_restoreBuf)
extern void Print_restoreBuf(OpenModelica_threadData_ThreadData*, int /*_handle*/);
DLLExport
modelica_integer omc_Print_saveAndClearBuf(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Print_saveAndClearBuf(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Print_saveAndClearBuf,2,0) {(void*) boxptr_Print_saveAndClearBuf,0}};
#define boxvar_Print_saveAndClearBuf MMC_REFSTRUCTLIT(boxvar_lit_Print_saveAndClearBuf)
extern int Print_saveAndClearBuf(OpenModelica_threadData_ThreadData*);
#ifdef __cplusplus
}
#endif
#endif
