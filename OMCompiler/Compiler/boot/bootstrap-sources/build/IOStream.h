#ifndef IOStream__H
#define IOStream__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description IOStream_IOStream_IOSTREAM__desc;
extern struct record_description IOStream_IOStreamData_BUFFER__DATA__desc;
extern struct record_description IOStream_IOStreamData_FILE__DATA__desc;
extern struct record_description IOStream_IOStreamData_LIST__DATA__desc;
extern struct record_description IOStream_IOStreamType_LIST__desc;
DLLDirection
void omc_IOStream_print(threadData_t *threadData, modelica_metatype _inStream, modelica_integer _whereToPrint);
DLLDirection
void boxptr_IOStream_print(threadData_t *threadData, modelica_metatype _inStream, modelica_metatype _whereToPrint);
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStream_print,2,0) {(void*) boxptr_IOStream_print,0}};
#define boxvar_IOStream_print MMC_REFSTRUCTLIT(boxvar_lit_IOStream_print)
DLLDirection
modelica_string omc_IOStream_string(threadData_t *threadData, modelica_metatype _inStream);
#define boxptr_IOStream_string omc_IOStream_string
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStream_string,2,0) {(void*) boxptr_IOStream_string,0}};
#define boxvar_IOStream_string MMC_REFSTRUCTLIT(boxvar_lit_IOStream_string)
DLLDirection
modelica_boolean omc_IOStream_empty(threadData_t *threadData, modelica_metatype _inStream);
DLLDirection
modelica_metatype boxptr_IOStream_empty(threadData_t *threadData, modelica_metatype _inStream);
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStream_empty,2,0) {(void*) boxptr_IOStream_empty,0}};
#define boxvar_IOStream_empty MMC_REFSTRUCTLIT(boxvar_lit_IOStream_empty)
DLLDirection
modelica_metatype omc_IOStream_clear(threadData_t *threadData, modelica_metatype _inStream);
#define boxptr_IOStream_clear omc_IOStream_clear
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStream_clear,2,0) {(void*) boxptr_IOStream_clear,0}};
#define boxvar_IOStream_clear MMC_REFSTRUCTLIT(boxvar_lit_IOStream_clear)
DLLDirection
void omc_IOStream_delete(threadData_t *threadData, modelica_metatype _inStream);
#define boxptr_IOStream_delete omc_IOStream_delete
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStream_delete,2,0) {(void*) boxptr_IOStream_delete,0}};
#define boxvar_IOStream_delete MMC_REFSTRUCTLIT(boxvar_lit_IOStream_delete)
DLLDirection
modelica_metatype omc_IOStream_close(threadData_t *threadData, modelica_metatype _inStream);
#define boxptr_IOStream_close omc_IOStream_close
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStream_close,2,0) {(void*) boxptr_IOStream_close,0}};
#define boxvar_IOStream_close MMC_REFSTRUCTLIT(boxvar_lit_IOStream_close)
DLLDirection
modelica_metatype omc_IOStream_appendListStream(threadData_t *threadData, modelica_metatype _srcStream, modelica_metatype __omcQ_24in_5FdstStream);
#define boxptr_IOStream_appendListStream omc_IOStream_appendListStream
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStream_appendListStream,2,0) {(void*) boxptr_IOStream_appendListStream,0}};
#define boxvar_IOStream_appendListStream MMC_REFSTRUCTLIT(boxvar_lit_IOStream_appendListStream)
DLLDirection
modelica_metatype omc_IOStream_appendListReverse(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fs, modelica_metatype _data);
#define boxptr_IOStream_appendListReverse omc_IOStream_appendListReverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStream_appendListReverse,2,0) {(void*) boxptr_IOStream_appendListReverse,0}};
#define boxvar_IOStream_appendListReverse MMC_REFSTRUCTLIT(boxvar_lit_IOStream_appendListReverse)
DLLDirection
modelica_metatype omc_IOStream_appendList(threadData_t *threadData, modelica_metatype _inStream, modelica_metatype _inStringList);
#define boxptr_IOStream_appendList omc_IOStream_appendList
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStream_appendList,2,0) {(void*) boxptr_IOStream_appendList,0}};
#define boxvar_IOStream_appendList MMC_REFSTRUCTLIT(boxvar_lit_IOStream_appendList)
DLLDirection
modelica_metatype omc_IOStream_append(threadData_t *threadData, modelica_metatype _inStream, modelica_string _inString);
#define boxptr_IOStream_append omc_IOStream_append
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStream_append,2,0) {(void*) boxptr_IOStream_append,0}};
#define boxvar_IOStream_append MMC_REFSTRUCTLIT(boxvar_lit_IOStream_append)
DLLDirection
modelica_metatype omc_IOStream_create(threadData_t *threadData, modelica_string _streamName, modelica_metatype _streamType);
#define boxptr_IOStream_create omc_IOStream_create
static const MMC_DEFSTRUCTLIT(boxvar_lit_IOStream_create,2,0) {(void*) boxptr_IOStream_create,0}};
#define boxvar_IOStream_create MMC_REFSTRUCTLIT(boxvar_lit_IOStream_create)
#ifdef __cplusplus
}
#endif
#endif
