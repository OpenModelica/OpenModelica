#ifndef ModelicaExternalC__H
#define ModelicaExternalC__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
real_array omc_ModelicaExternalC_ModelicaIO__readRealMatrix(threadData_t *threadData, modelica_string _fileName, modelica_string _matrixName, modelica_integer _nrow, modelica_integer _ncol, modelica_boolean _verboseRead);
DLLExport
modelica_metatype boxptr_ModelicaExternalC_ModelicaIO__readRealMatrix(threadData_t *threadData, modelica_metatype _fileName, modelica_metatype _matrixName, modelica_metatype _nrow, modelica_metatype _ncol, modelica_metatype _verboseRead);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ModelicaExternalC_ModelicaIO__readRealMatrix,2,0) {(void*) boxptr_ModelicaExternalC_ModelicaIO__readRealMatrix,0}};
#define boxvar_ModelicaExternalC_ModelicaIO__readRealMatrix MMC_REFSTRUCTLIT(boxvar_lit_ModelicaExternalC_ModelicaIO__readRealMatrix)
extern void ModelicaIO_readRealMatrix(const char* /*_fileName*/, const char* /*_matrixName*/, double* /*_matrix*/, int /*_nrow*/, int /*_ncol*/, int /*_verboseRead*/);
DLLExport
integer_array omc_ModelicaExternalC_ModelicaIO__readMatrixSizes(threadData_t *threadData, modelica_string _fileName, modelica_string _matrixName);
DLLExport
modelica_metatype boxptr_ModelicaExternalC_ModelicaIO__readMatrixSizes(threadData_t *threadData, modelica_metatype _fileName, modelica_metatype _matrixName);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ModelicaExternalC_ModelicaIO__readMatrixSizes,2,0) {(void*) boxptr_ModelicaExternalC_ModelicaIO__readMatrixSizes,0}};
#define boxvar_ModelicaExternalC_ModelicaIO__readMatrixSizes MMC_REFSTRUCTLIT(boxvar_lit_ModelicaExternalC_ModelicaIO__readMatrixSizes)
extern void ModelicaIO_readMatrixSizes(const char* /*_fileName*/, const char* /*_matrixName*/, int* /*_dim*/);
DLLExport
modelica_integer omc_ModelicaExternalC_Strings__hashString(threadData_t *threadData, modelica_string _string);
DLLExport
modelica_metatype boxptr_ModelicaExternalC_Strings__hashString(threadData_t *threadData, modelica_metatype _string);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ModelicaExternalC_Strings__hashString,2,0) {(void*) boxptr_ModelicaExternalC_Strings__hashString,0}};
#define boxvar_ModelicaExternalC_Strings__hashString MMC_REFSTRUCTLIT(boxvar_lit_ModelicaExternalC_Strings__hashString)
extern int ModelicaStrings_hashString(const char* /*_string*/);
DLLExport
modelica_integer omc_ModelicaExternalC_Strings__skipWhiteSpace(threadData_t *threadData, modelica_string _string, modelica_integer _startIndex);
DLLExport
modelica_metatype boxptr_ModelicaExternalC_Strings__skipWhiteSpace(threadData_t *threadData, modelica_metatype _string, modelica_metatype _startIndex);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ModelicaExternalC_Strings__skipWhiteSpace,2,0) {(void*) boxptr_ModelicaExternalC_Strings__skipWhiteSpace,0}};
#define boxvar_ModelicaExternalC_Strings__skipWhiteSpace MMC_REFSTRUCTLIT(boxvar_lit_ModelicaExternalC_Strings__skipWhiteSpace)
extern int ModelicaStrings_skipWhiteSpace(const char* /*_string*/, int /*_startIndex*/);
DLLExport
modelica_integer omc_ModelicaExternalC_Strings__scanIdentifier(threadData_t *threadData, modelica_string _string, modelica_integer _startIndex, modelica_string *out_identifier);
DLLExport
modelica_metatype boxptr_ModelicaExternalC_Strings__scanIdentifier(threadData_t *threadData, modelica_metatype _string, modelica_metatype _startIndex, modelica_metatype *out_identifier);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ModelicaExternalC_Strings__scanIdentifier,2,0) {(void*) boxptr_ModelicaExternalC_Strings__scanIdentifier,0}};
#define boxvar_ModelicaExternalC_Strings__scanIdentifier MMC_REFSTRUCTLIT(boxvar_lit_ModelicaExternalC_Strings__scanIdentifier)
extern void ModelicaStrings_scanIdentifier(const char* /*_string*/, int /*_startIndex*/, int* /*_nextIndex*/, const char** /*_identifier*/);
DLLExport
modelica_integer omc_ModelicaExternalC_Strings__scanString(threadData_t *threadData, modelica_string _string, modelica_integer _startIndex, modelica_string *out_string2);
DLLExport
modelica_metatype boxptr_ModelicaExternalC_Strings__scanString(threadData_t *threadData, modelica_metatype _string, modelica_metatype _startIndex, modelica_metatype *out_string2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ModelicaExternalC_Strings__scanString,2,0) {(void*) boxptr_ModelicaExternalC_Strings__scanString,0}};
#define boxvar_ModelicaExternalC_Strings__scanString MMC_REFSTRUCTLIT(boxvar_lit_ModelicaExternalC_Strings__scanString)
extern void ModelicaStrings_scanString(const char* /*_string*/, int /*_startIndex*/, int* /*_nextIndex*/, const char** /*_string2*/);
DLLExport
modelica_integer omc_ModelicaExternalC_Strings__scanInteger(threadData_t *threadData, modelica_string _string, modelica_integer _startIndex, modelica_boolean _unsigned, modelica_integer *out_number);
DLLExport
modelica_metatype boxptr_ModelicaExternalC_Strings__scanInteger(threadData_t *threadData, modelica_metatype _string, modelica_metatype _startIndex, modelica_metatype _unsigned, modelica_metatype *out_number);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ModelicaExternalC_Strings__scanInteger,2,0) {(void*) boxptr_ModelicaExternalC_Strings__scanInteger,0}};
#define boxvar_ModelicaExternalC_Strings__scanInteger MMC_REFSTRUCTLIT(boxvar_lit_ModelicaExternalC_Strings__scanInteger)
extern void ModelicaStrings_scanInteger(const char* /*_string*/, int /*_startIndex*/, int /*_unsigned*/, int* /*_nextIndex*/, int* /*_number*/);
DLLExport
modelica_integer omc_ModelicaExternalC_Strings__scanReal(threadData_t *threadData, modelica_string _string, modelica_integer _startIndex, modelica_boolean _unsigned, modelica_real *out_number);
DLLExport
modelica_metatype boxptr_ModelicaExternalC_Strings__scanReal(threadData_t *threadData, modelica_metatype _string, modelica_metatype _startIndex, modelica_metatype _unsigned, modelica_metatype *out_number);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ModelicaExternalC_Strings__scanReal,2,0) {(void*) boxptr_ModelicaExternalC_Strings__scanReal,0}};
#define boxvar_ModelicaExternalC_Strings__scanReal MMC_REFSTRUCTLIT(boxvar_lit_ModelicaExternalC_Strings__scanReal)
extern void ModelicaStrings_scanReal(const char* /*_string*/, int /*_startIndex*/, int /*_unsigned*/, int* /*_nextIndex*/, double* /*_number*/);
DLLExport
modelica_integer omc_ModelicaExternalC_Strings__compare(threadData_t *threadData, modelica_string _string1, modelica_string _string2, modelica_boolean _caseSensitive);
DLLExport
modelica_metatype boxptr_ModelicaExternalC_Strings__compare(threadData_t *threadData, modelica_metatype _string1, modelica_metatype _string2, modelica_metatype _caseSensitive);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ModelicaExternalC_Strings__compare,2,0) {(void*) boxptr_ModelicaExternalC_Strings__compare,0}};
#define boxvar_ModelicaExternalC_Strings__compare MMC_REFSTRUCTLIT(boxvar_lit_ModelicaExternalC_Strings__compare)
extern int ModelicaStrings_compare(const char* /*_string1*/, const char* /*_string2*/, int /*_caseSensitive*/);
DLLExport
void omc_ModelicaExternalC_Streams__close(threadData_t *threadData, modelica_string _fileName);
#define boxptr_ModelicaExternalC_Streams__close omc_ModelicaExternalC_Streams__close
static const MMC_DEFSTRUCTLIT(boxvar_lit_ModelicaExternalC_Streams__close,2,0) {(void*) boxptr_ModelicaExternalC_Streams__close,0}};
#define boxvar_ModelicaExternalC_Streams__close MMC_REFSTRUCTLIT(boxvar_lit_ModelicaExternalC_Streams__close)
extern void ModelicaStreams_closeFile(const char* /*_fileName*/);
DLLExport
modelica_integer omc_ModelicaExternalC_File__stat(threadData_t *threadData, modelica_string _name);
DLLExport
modelica_metatype boxptr_ModelicaExternalC_File__stat(threadData_t *threadData, modelica_metatype _name);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ModelicaExternalC_File__stat,2,0) {(void*) boxptr_ModelicaExternalC_File__stat,0}};
#define boxvar_ModelicaExternalC_File__stat MMC_REFSTRUCTLIT(boxvar_lit_ModelicaExternalC_File__stat)
extern int ModelicaInternal_stat(const char* /*_name*/);
DLLExport
modelica_string omc_ModelicaExternalC_File__fullPathName(threadData_t *threadData, modelica_string _fileName);
#define boxptr_ModelicaExternalC_File__fullPathName omc_ModelicaExternalC_File__fullPathName
static const MMC_DEFSTRUCTLIT(boxvar_lit_ModelicaExternalC_File__fullPathName,2,0) {(void*) boxptr_ModelicaExternalC_File__fullPathName,0}};
#define boxvar_ModelicaExternalC_File__fullPathName MMC_REFSTRUCTLIT(boxvar_lit_ModelicaExternalC_File__fullPathName)
extern const char* ModelicaInternal_fullPathName(const char* /*_fileName*/);
DLLExport
modelica_integer omc_ModelicaExternalC_Streams__countLines(threadData_t *threadData, modelica_string _fileName);
DLLExport
modelica_metatype boxptr_ModelicaExternalC_Streams__countLines(threadData_t *threadData, modelica_metatype _fileName);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ModelicaExternalC_Streams__countLines,2,0) {(void*) boxptr_ModelicaExternalC_Streams__countLines,0}};
#define boxvar_ModelicaExternalC_Streams__countLines MMC_REFSTRUCTLIT(boxvar_lit_ModelicaExternalC_Streams__countLines)
extern int ModelicaInternal_countLines(const char* /*_fileName*/);
DLLExport
modelica_string omc_ModelicaExternalC_Streams__readLine(threadData_t *threadData, modelica_string _fileName, modelica_integer _lineNumber, modelica_boolean *out_endOfFile);
DLLExport
modelica_metatype boxptr_ModelicaExternalC_Streams__readLine(threadData_t *threadData, modelica_metatype _fileName, modelica_metatype _lineNumber, modelica_metatype *out_endOfFile);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ModelicaExternalC_Streams__readLine,2,0) {(void*) boxptr_ModelicaExternalC_Streams__readLine,0}};
#define boxvar_ModelicaExternalC_Streams__readLine MMC_REFSTRUCTLIT(boxvar_lit_ModelicaExternalC_Streams__readLine)
extern const char* ModelicaInternal_readLine(const char* /*_fileName*/, int /*_lineNumber*/, int* /*_endOfFile*/);
DLLExport
void omc_ModelicaExternalC_Streams__print(threadData_t *threadData, modelica_string _string, modelica_string _fileName);
#define boxptr_ModelicaExternalC_Streams__print omc_ModelicaExternalC_Streams__print
static const MMC_DEFSTRUCTLIT(boxvar_lit_ModelicaExternalC_Streams__print,2,0) {(void*) boxptr_ModelicaExternalC_Streams__print,0}};
#define boxvar_ModelicaExternalC_Streams__print MMC_REFSTRUCTLIT(boxvar_lit_ModelicaExternalC_Streams__print)
extern void ModelicaInternal_print(const char* /*_string*/, const char* /*_fileName*/);
#ifdef __cplusplus
}
#endif
#endif
