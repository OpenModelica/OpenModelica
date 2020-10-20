#ifndef File__H
#define File__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
void omc_File_writeSpace(threadData_t *threadData, modelica_complex _file, modelica_integer _n);
DLLExport
void boxptr_File_writeSpace(threadData_t *threadData, modelica_metatype _file, modelica_metatype _n);
static const MMC_DEFSTRUCTLIT(boxvar_lit_File_writeSpace,2,0) {(void*) boxptr_File_writeSpace,0}};
#define boxvar_File_writeSpace MMC_REFSTRUCTLIT(boxvar_lit_File_writeSpace)
DLLExport
void omc_File_releaseReference(threadData_t *threadData, modelica_complex _file);
DLLExport
void boxptr_File_releaseReference(threadData_t *threadData, modelica_metatype _file);
static const MMC_DEFSTRUCTLIT(boxvar_lit_File_releaseReference,2,0) {(void*) boxptr_File_releaseReference,0}};
#define boxvar_File_releaseReference MMC_REFSTRUCTLIT(boxvar_lit_File_releaseReference)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern void om_file_release_reference(void * (*_file*));
*/
DLLExport
modelica_metatype omc_File_getReference(threadData_t *threadData, modelica_complex _file);
DLLExport
modelica_metatype boxptr_File_getReference(threadData_t *threadData, modelica_metatype _file);
static const MMC_DEFSTRUCTLIT(boxvar_lit_File_getReference,2,0) {(void*) boxptr_File_getReference,0}};
#define boxvar_File_getReference MMC_REFSTRUCTLIT(boxvar_lit_File_getReference)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern modelica_metatype om_file_get_reference(void * (*_file*));
*/
DLLExport
modelica_metatype omc_File_noReference(threadData_t *threadData);
#define boxptr_File_noReference omc_File_noReference
static const MMC_DEFSTRUCTLIT(boxvar_lit_File_noReference,2,0) {(void*) boxptr_File_noReference,0}};
#define boxvar_File_noReference MMC_REFSTRUCTLIT(boxvar_lit_File_noReference)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern modelica_metatype om_file_no_reference();
*/
DLLExport
modelica_string omc_File_getFilename(threadData_t *threadData, modelica_metatype _file);
#define boxptr_File_getFilename omc_File_getFilename
static const MMC_DEFSTRUCTLIT(boxvar_lit_File_getFilename,2,0) {(void*) boxptr_File_getFilename,0}};
#define boxvar_File_getFilename MMC_REFSTRUCTLIT(boxvar_lit_File_getFilename)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern const char* om_file_get_filename(modelica_metatype (*_file*));
*/
DLLExport
modelica_integer omc_File_tell(threadData_t *threadData, modelica_complex _file);
DLLExport
modelica_metatype boxptr_File_tell(threadData_t *threadData, modelica_metatype _file);
static const MMC_DEFSTRUCTLIT(boxvar_lit_File_tell,2,0) {(void*) boxptr_File_tell,0}};
#define boxvar_File_tell MMC_REFSTRUCTLIT(boxvar_lit_File_tell)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern int om_file_tell(void * (*_file*));
*/
DLLExport
modelica_boolean omc_File_seek(threadData_t *threadData, modelica_complex _file, modelica_integer _offset, modelica_integer _whence);
DLLExport
modelica_metatype boxptr_File_seek(threadData_t *threadData, modelica_metatype _file, modelica_metatype _offset, modelica_metatype _whence);
static const MMC_DEFSTRUCTLIT(boxvar_lit_File_seek,2,0) {(void*) boxptr_File_seek,0}};
#define boxvar_File_seek MMC_REFSTRUCTLIT(boxvar_lit_File_seek)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern int om_file_seek(void * (*_file*), int (*_offset*), int (*_whence*));
*/
DLLExport
void omc_File_writeEscape(threadData_t *threadData, modelica_complex _file, modelica_string _data, modelica_integer _escape);
DLLExport
void boxptr_File_writeEscape(threadData_t *threadData, modelica_metatype _file, modelica_metatype _data, modelica_metatype _escape);
static const MMC_DEFSTRUCTLIT(boxvar_lit_File_writeEscape,2,0) {(void*) boxptr_File_writeEscape,0}};
#define boxvar_File_writeEscape MMC_REFSTRUCTLIT(boxvar_lit_File_writeEscape)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern void om_file_write_escape(void * (*_file*), const char* (*_data*), int (*_escape*));
*/
DLLExport
void omc_File_writeReal(threadData_t *threadData, modelica_complex _file, modelica_real _data, modelica_string _format);
DLLExport
void boxptr_File_writeReal(threadData_t *threadData, modelica_metatype _file, modelica_metatype _data, modelica_metatype _format);
static const MMC_DEFSTRUCTLIT(boxvar_lit_File_writeReal,2,0) {(void*) boxptr_File_writeReal,0}};
#define boxvar_File_writeReal MMC_REFSTRUCTLIT(boxvar_lit_File_writeReal)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern void om_file_write_real(void * (*_file*), double (*_data*), const char* (*_format*));
*/
DLLExport
void omc_File_writeInt(threadData_t *threadData, modelica_complex _file, modelica_integer _data, modelica_string _format);
DLLExport
void boxptr_File_writeInt(threadData_t *threadData, modelica_metatype _file, modelica_metatype _data, modelica_metatype _format);
static const MMC_DEFSTRUCTLIT(boxvar_lit_File_writeInt,2,0) {(void*) boxptr_File_writeInt,0}};
#define boxvar_File_writeInt MMC_REFSTRUCTLIT(boxvar_lit_File_writeInt)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern void om_file_write_int(void * (*_file*), int (*_data*), const char* (*_format*));
*/
DLLExport
void omc_File_write(threadData_t *threadData, modelica_complex _file, modelica_string _data);
DLLExport
void boxptr_File_write(threadData_t *threadData, modelica_metatype _file, modelica_metatype _data);
static const MMC_DEFSTRUCTLIT(boxvar_lit_File_write,2,0) {(void*) boxptr_File_write,0}};
#define boxvar_File_write MMC_REFSTRUCTLIT(boxvar_lit_File_write)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern void om_file_write(void * (*_file*), const char* (*_data*));
*/
DLLExport
void omc_File_open(threadData_t *threadData, modelica_complex _file, modelica_string _filename, modelica_integer _mode);
DLLExport
void boxptr_File_open(threadData_t *threadData, modelica_metatype _file, modelica_metatype _filename, modelica_metatype _mode);
static const MMC_DEFSTRUCTLIT(boxvar_lit_File_open,2,0) {(void*) boxptr_File_open,0}};
#define boxvar_File_open MMC_REFSTRUCTLIT(boxvar_lit_File_open)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern void om_file_open(void * (*_file*), const char* (*_filename*), int (*_mode*));
*/
DLLExport
modelica_complex omc_File_File_constructor(threadData_t *threadData, modelica_metatype _fromID);
DLLExport
modelica_metatype boxptr_File_File_constructor(threadData_t *threadData, modelica_metatype _fromID);
static const MMC_DEFSTRUCTLIT(boxvar_lit_File_File_constructor,2,0) {(void*) boxptr_File_File_constructor,0}};
#define boxvar_File_File_constructor MMC_REFSTRUCTLIT(boxvar_lit_File_File_constructor)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern void * om_file_new(modelica_metatype (*_fromID*));
*/
DLLExport
void omc_File_File_destructor(threadData_t *threadData, modelica_complex _file);
DLLExport
void boxptr_File_File_destructor(threadData_t *threadData, modelica_metatype _file);
static const MMC_DEFSTRUCTLIT(boxvar_lit_File_File_destructor,2,0) {(void*) boxptr_File_File_destructor,0}};
#define boxvar_File_File_destructor MMC_REFSTRUCTLIT(boxvar_lit_File_File_destructor)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern void om_file_free(void * (*_file*));
*/
#ifdef __cplusplus
}
#endif
#endif
