#ifndef System__H
#define System__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_real omc_System_getSizeOfData(threadData_t *threadData, modelica_metatype _data, modelica_real *out_raw_sz, modelica_real *out_nonSharedStringSize);
DLLExport
modelica_metatype boxptr_System_getSizeOfData(threadData_t *threadData, modelica_metatype _data, modelica_metatype *out_raw_sz, modelica_metatype *out_nonSharedStringSize);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getSizeOfData,2,0) {(void*) boxptr_System_getSizeOfData,0}};
#define boxvar_System_getSizeOfData MMC_REFSTRUCTLIT(boxvar_lit_System_getSizeOfData)
extern double SystemImpl__getSizeOfData(modelica_metatype /*_data*/, double* /*_raw_sz*/, double* /*_nonSharedStringSize*/);
DLLExport
void omc_System_updateUriMapping(threadData_t *threadData, modelica_metatype _namesAndDirs);
#define boxptr_System_updateUriMapping omc_System_updateUriMapping
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_updateUriMapping,2,0) {(void*) boxptr_System_updateUriMapping,0}};
#define boxvar_System_updateUriMapping MMC_REFSTRUCTLIT(boxvar_lit_System_updateUriMapping)
extern void OpenModelica_updateUriMapping(OpenModelica_threadData_ThreadData*, modelica_metatype /*_namesAndDirs*/);
DLLExport
void omc_System_fflush(threadData_t *threadData);
#define boxptr_System_fflush omc_System_fflush
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_fflush,2,0) {(void*) boxptr_System_fflush,0}};
#define boxvar_System_fflush MMC_REFSTRUCTLIT(boxvar_lit_System_fflush)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern void SystemImpl__fflush();
*/
DLLExport
modelica_boolean omc_System_relocateFunctions(threadData_t *threadData, modelica_string _fileName, modelica_metatype _names);
DLLExport
modelica_metatype boxptr_System_relocateFunctions(threadData_t *threadData, modelica_metatype _fileName, modelica_metatype _names);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_relocateFunctions,2,0) {(void*) boxptr_System_relocateFunctions,0}};
#define boxvar_System_relocateFunctions MMC_REFSTRUCTLIT(boxvar_lit_System_relocateFunctions)
extern int SystemImpl__relocateFunctions(const char* /*_fileName*/, modelica_metatype /*_names*/);
DLLExport
modelica_metatype omc_System_stringAllocatorResult(threadData_t *threadData, modelica_complex _sa, modelica_metatype _dummy);
DLLExport
modelica_metatype boxptr_System_stringAllocatorResult(threadData_t *threadData, modelica_metatype _sa, modelica_metatype _dummy);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_stringAllocatorResult,2,0) {(void*) boxptr_System_stringAllocatorResult,0}};
#define boxvar_System_stringAllocatorResult MMC_REFSTRUCTLIT(boxvar_lit_System_stringAllocatorResult)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern modelica_metatype om_stringAllocatorResult(void * (*_sa*));
*/
DLLExport
void omc_System_stringAllocatorStringCopy(threadData_t *threadData, modelica_complex _dest, modelica_string _source, modelica_integer _destOffset);
DLLExport
void boxptr_System_stringAllocatorStringCopy(threadData_t *threadData, modelica_metatype _dest, modelica_metatype _source, modelica_metatype _destOffset);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_stringAllocatorStringCopy,2,0) {(void*) boxptr_System_stringAllocatorStringCopy,0}};
#define boxvar_System_stringAllocatorStringCopy MMC_REFSTRUCTLIT(boxvar_lit_System_stringAllocatorStringCopy)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern void om_stringAllocatorStringCopy(void * (*_dest*), const char* (*_source*), int (*_destOffset*));
*/
DLLExport
modelica_complex omc_System_StringAllocator_constructor(threadData_t *threadData, modelica_integer _sz);
DLLExport
modelica_metatype boxptr_System_StringAllocator_constructor(threadData_t *threadData, modelica_metatype _sz);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_StringAllocator_constructor,2,0) {(void*) boxptr_System_StringAllocator_constructor,0}};
#define boxvar_System_StringAllocator_constructor MMC_REFSTRUCTLIT(boxvar_lit_System_StringAllocator_constructor)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern void * StringAllocator_constructor(int (*_sz*));
*/
DLLExport
void omc_System_StringAllocator_destructor(threadData_t *threadData, modelica_complex _str);
DLLExport
void boxptr_System_StringAllocator_destructor(threadData_t *threadData, modelica_metatype _str);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_StringAllocator_destructor,2,0) {(void*) boxptr_System_StringAllocator_destructor,0}};
#define boxvar_System_StringAllocator_destructor MMC_REFSTRUCTLIT(boxvar_lit_System_StringAllocator_destructor)
#define boxptr_System_dladdr___dladdr omc_System_dladdr___dladdr
extern void SystemImpl__dladdr(modelica_metatype /*_symbol*/, const char** /*_file*/, const char** /*_name*/);
DLLExport
modelica_string omc_System_dladdr(threadData_t *threadData, modelica_metatype _symbol, modelica_string *out_file, modelica_string *out_name);
#define boxptr_System_dladdr omc_System_dladdr
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_dladdr,2,0) {(void*) boxptr_System_dladdr,0}};
#define boxvar_System_dladdr MMC_REFSTRUCTLIT(boxvar_lit_System_dladdr)
DLLExport
modelica_boolean omc_System_covertTextFileToCLiteral(threadData_t *threadData, modelica_string _textFile, modelica_string _outFile, modelica_string _target);
DLLExport
modelica_metatype boxptr_System_covertTextFileToCLiteral(threadData_t *threadData, modelica_metatype _textFile, modelica_metatype _outFile, modelica_metatype _target);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_covertTextFileToCLiteral,2,0) {(void*) boxptr_System_covertTextFileToCLiteral,0}};
#define boxvar_System_covertTextFileToCLiteral MMC_REFSTRUCTLIT(boxvar_lit_System_covertTextFileToCLiteral)
extern int SystemImpl__covertTextFileToCLiteral(const char* /*_textFile*/, const char* /*_outFile*/, const char* /*_target*/);
DLLExport
modelica_integer omc_System_alarm(threadData_t *threadData, modelica_integer _seconds);
DLLExport
modelica_metatype boxptr_System_alarm(threadData_t *threadData, modelica_metatype _seconds);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_alarm,2,0) {(void*) boxptr_System_alarm,0}};
#define boxvar_System_alarm MMC_REFSTRUCTLIT(boxvar_lit_System_alarm)
extern int SystemImpl__alarm(int /*_seconds*/);
DLLExport
modelica_boolean omc_System_stat(threadData_t *threadData, modelica_string _filename, modelica_real *out_st_size, modelica_real *out_st_mtime);
DLLExport
modelica_metatype boxptr_System_stat(threadData_t *threadData, modelica_metatype _filename, modelica_metatype *out_st_size, modelica_metatype *out_st_mtime);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_stat,2,0) {(void*) boxptr_System_stat,0}};
#define boxvar_System_stat MMC_REFSTRUCTLIT(boxvar_lit_System_stat)
extern int SystemImpl__stat(const char* /*_filename*/, double* /*_st_size*/, double* /*_st_mtime*/);
DLLExport
modelica_string omc_System_ctime(threadData_t *threadData, modelica_real _t);
DLLExport
modelica_metatype boxptr_System_ctime(threadData_t *threadData, modelica_metatype _t);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_ctime,2,0) {(void*) boxptr_System_ctime,0}};
#define boxvar_System_ctime MMC_REFSTRUCTLIT(boxvar_lit_System_ctime)
extern const char* SystemImpl__ctime(double /*_t*/);
DLLExport
void omc_System_initGarbageCollector(threadData_t *threadData);
#define boxptr_System_initGarbageCollector omc_System_initGarbageCollector
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_initGarbageCollector,2,0) {(void*) boxptr_System_initGarbageCollector,0}};
#define boxvar_System_initGarbageCollector MMC_REFSTRUCTLIT(boxvar_lit_System_initGarbageCollector)
extern void System_initGarbageCollector();
DLLExport
modelica_real omc_System_getMemorySize(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_getMemorySize(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getMemorySize,2,0) {(void*) boxptr_System_getMemorySize,0}};
#define boxvar_System_getMemorySize MMC_REFSTRUCTLIT(boxvar_lit_System_getMemorySize)
extern double System_getMemorySize();
DLLExport
void omc_System_threadWorkFailed(threadData_t *threadData);
#define boxptr_System_threadWorkFailed omc_System_threadWorkFailed
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_threadWorkFailed,2,0) {(void*) boxptr_System_threadWorkFailed,0}};
#define boxvar_System_threadWorkFailed MMC_REFSTRUCTLIT(boxvar_lit_System_threadWorkFailed)
extern void System_threadFail(OpenModelica_threadData_ThreadData*);
DLLExport
void omc_System_exit(threadData_t *threadData, modelica_integer _status);
DLLExport
void boxptr_System_exit(threadData_t *threadData, modelica_metatype _status);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_exit,2,0) {(void*) boxptr_System_exit,0}};
#define boxvar_System_exit MMC_REFSTRUCTLIT(boxvar_lit_System_exit)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern void exit(int (*_status*));
*/
DLLExport
modelica_metatype omc_System_launchParallelTasks(threadData_t *threadData, modelica_integer _numThreads, modelica_metatype _inData, modelica_fnptr _func);
DLLExport
modelica_metatype boxptr_System_launchParallelTasks(threadData_t *threadData, modelica_metatype _numThreads, modelica_metatype _inData, modelica_fnptr _func);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_launchParallelTasks,2,0) {(void*) boxptr_System_launchParallelTasks,0}};
#define boxvar_System_launchParallelTasks MMC_REFSTRUCTLIT(boxvar_lit_System_launchParallelTasks)
extern modelica_metatype System_launchParallelTasks(OpenModelica_threadData_ThreadData*, int /*_numThreads*/, modelica_metatype /*_inData*/, modelica_fnptr /*_func*/);
DLLExport
modelica_integer omc_System_numProcessors(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_numProcessors(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_numProcessors,2,0) {(void*) boxptr_System_numProcessors,0}};
#define boxvar_System_numProcessors MMC_REFSTRUCTLIT(boxvar_lit_System_numProcessors)
extern int System_numProcessors();
DLLExport
modelica_boolean omc_System_rename(threadData_t *threadData, modelica_string _source, modelica_string _dest);
DLLExport
modelica_metatype boxptr_System_rename(threadData_t *threadData, modelica_metatype _source, modelica_metatype _dest);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_rename,2,0) {(void*) boxptr_System_rename,0}};
#define boxvar_System_rename MMC_REFSTRUCTLIT(boxvar_lit_System_rename)
extern int SystemImpl__rename(const char* /*_source*/, const char* /*_dest*/);
DLLExport
modelica_boolean omc_System_fileContentsEqual(threadData_t *threadData, modelica_string _file1, modelica_string _file2);
DLLExport
modelica_metatype boxptr_System_fileContentsEqual(threadData_t *threadData, modelica_metatype _file1, modelica_metatype _file2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_fileContentsEqual,2,0) {(void*) boxptr_System_fileContentsEqual,0}};
#define boxvar_System_fileContentsEqual MMC_REFSTRUCTLIT(boxvar_lit_System_fileContentsEqual)
extern int SystemImpl__fileContentsEqual(const char* /*_file1*/, const char* /*_file2*/);
DLLExport
modelica_boolean omc_System_fileIsNewerThan(threadData_t *threadData, modelica_string _file1, modelica_string _file2);
DLLExport
modelica_metatype boxptr_System_fileIsNewerThan(threadData_t *threadData, modelica_metatype _file1, modelica_metatype _file2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_fileIsNewerThan,2,0) {(void*) boxptr_System_fileIsNewerThan,0}};
#define boxvar_System_fileIsNewerThan MMC_REFSTRUCTLIT(boxvar_lit_System_fileIsNewerThan)
extern int System_fileIsNewerThan(const char* /*_file1*/, const char* /*_file2*/);
DLLExport
modelica_integer omc_System_getTerminalWidth(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_getTerminalWidth(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getTerminalWidth,2,0) {(void*) boxptr_System_getTerminalWidth,0}};
#define boxvar_System_getTerminalWidth MMC_REFSTRUCTLIT(boxvar_lit_System_getTerminalWidth)
extern int System_getTerminalWidth();
DLLExport
modelica_string omc_System_getSimulationHelpText(threadData_t *threadData, modelica_boolean _detailed, modelica_boolean _sphinx);
DLLExport
modelica_metatype boxptr_System_getSimulationHelpText(threadData_t *threadData, modelica_metatype _detailed, modelica_metatype _sphinx);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getSimulationHelpText,2,0) {(void*) boxptr_System_getSimulationHelpText,0}};
#define boxvar_System_getSimulationHelpText MMC_REFSTRUCTLIT(boxvar_lit_System_getSimulationHelpText)
extern const char* System_getSimulationHelpTextSphinx(int /*_detailed*/, int /*_sphinx*/);
DLLExport
modelica_string omc_System_realpath(threadData_t *threadData, modelica_string _path);
#define boxptr_System_realpath omc_System_realpath
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_realpath,2,0) {(void*) boxptr_System_realpath,0}};
#define boxvar_System_realpath MMC_REFSTRUCTLIT(boxvar_lit_System_realpath)
extern const char* System_realpath(const char* /*_path*/);
DLLExport
modelica_integer omc_System_numBits(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_numBits(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_numBits,2,0) {(void*) boxptr_System_numBits,0}};
#define boxvar_System_numBits MMC_REFSTRUCTLIT(boxvar_lit_System_numBits)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern int architecture_numbits();
*/
DLLExport
modelica_string omc_System_anyStringCode(threadData_t *threadData, modelica_metatype _any);
#define boxptr_System_anyStringCode omc_System_anyStringCode
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_anyStringCode,2,0) {(void*) boxptr_System_anyStringCode,0}};
#define boxvar_System_anyStringCode MMC_REFSTRUCTLIT(boxvar_lit_System_anyStringCode)
extern const char* anyStringCode(modelica_metatype /*_any*/);
DLLExport
modelica_string omc_System_gettext(threadData_t *threadData, modelica_string _msgid);
#define boxptr_System_gettext omc_System_gettext
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_gettext,2,0) {(void*) boxptr_System_gettext,0}};
#define boxvar_System_gettext MMC_REFSTRUCTLIT(boxvar_lit_System_gettext)
extern const char* SystemImpl__gettext(const char* /*_msgid*/);
DLLExport
void omc_System_gettextInit(threadData_t *threadData, modelica_string _locale);
#define boxptr_System_gettextInit omc_System_gettextInit
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_gettextInit,2,0) {(void*) boxptr_System_gettextInit,0}};
#define boxvar_System_gettextInit MMC_REFSTRUCTLIT(boxvar_lit_System_gettextInit)
extern void SystemImpl__gettextInit(const char* /*_locale*/);
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern int rand();
*/
DLLExport
modelica_integer omc_System_intRandom(threadData_t *threadData, modelica_integer _n);
DLLExport
modelica_metatype boxptr_System_intRandom(threadData_t *threadData, modelica_metatype _n);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_intRandom,2,0) {(void*) boxptr_System_intRandom,0}};
#define boxvar_System_intRandom MMC_REFSTRUCTLIT(boxvar_lit_System_intRandom)
DLLExport
modelica_integer omc_System_intRand(threadData_t *threadData, modelica_integer _n);
DLLExport
modelica_metatype boxptr_System_intRand(threadData_t *threadData, modelica_metatype _n);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_intRand,2,0) {(void*) boxptr_System_intRand,0}};
#define boxvar_System_intRand MMC_REFSTRUCTLIT(boxvar_lit_System_intRand)
DLLExport
modelica_real omc_System_realRand(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_realRand(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_realRand,2,0) {(void*) boxptr_System_realRand,0}};
#define boxvar_System_realRand MMC_REFSTRUCTLIT(boxvar_lit_System_realRand)
extern double SystemImpl__realRand();
DLLExport
modelica_string omc_System_sprintff(threadData_t *threadData, modelica_string _format, modelica_real _val);
DLLExport
modelica_metatype boxptr_System_sprintff(threadData_t *threadData, modelica_metatype _format, modelica_metatype _val);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_sprintff,2,0) {(void*) boxptr_System_sprintff,0}};
#define boxvar_System_sprintff MMC_REFSTRUCTLIT(boxvar_lit_System_sprintff)
extern const char* System_sprintff(const char* /*_format*/, double /*_val*/);
DLLExport
modelica_string omc_System_snprintff(threadData_t *threadData, modelica_string _format, modelica_integer _maxlen, modelica_real _val);
DLLExport
modelica_metatype boxptr_System_snprintff(threadData_t *threadData, modelica_metatype _format, modelica_metatype _maxlen, modelica_metatype _val);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_snprintff,2,0) {(void*) boxptr_System_snprintff,0}};
#define boxvar_System_snprintff MMC_REFSTRUCTLIT(boxvar_lit_System_snprintff)
extern const char* System_snprintff(const char* /*_format*/, int /*_maxlen*/, double /*_val*/);
DLLExport
modelica_string omc_System_iconv(threadData_t *threadData, modelica_string _string, modelica_string _from, modelica_string _to);
#define boxptr_System_iconv omc_System_iconv
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_iconv,2,0) {(void*) boxptr_System_iconv,0}};
#define boxvar_System_iconv MMC_REFSTRUCTLIT(boxvar_lit_System_iconv)
extern const char* SystemImpl__iconv(const char* /*_string*/, const char* /*_from*/, const char* /*_to*/, int);
DLLExport
modelica_boolean omc_System_reopenStandardStream(threadData_t *threadData, modelica_integer __stream, modelica_string _filename);
DLLExport
modelica_metatype boxptr_System_reopenStandardStream(threadData_t *threadData, modelica_metatype __stream, modelica_metatype _filename);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_reopenStandardStream,2,0) {(void*) boxptr_System_reopenStandardStream,0}};
#define boxvar_System_reopenStandardStream MMC_REFSTRUCTLIT(boxvar_lit_System_reopenStandardStream)
extern int SystemImpl__reopenStandardStream(int /*__stream*/, const char* /*_filename*/);
DLLExport
modelica_metatype omc_System_dgesv(threadData_t *threadData, modelica_metatype _A, modelica_metatype _B, modelica_integer *out_info);
DLLExport
modelica_metatype boxptr_System_dgesv(threadData_t *threadData, modelica_metatype _A, modelica_metatype _B, modelica_metatype *out_info);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_dgesv,2,0) {(void*) boxptr_System_dgesv,0}};
#define boxvar_System_dgesv MMC_REFSTRUCTLIT(boxvar_lit_System_dgesv)
extern int SystemImpl__dgesv(modelica_metatype /*_A*/, modelica_metatype /*_B*/, modelica_metatype* /*_X*/);
DLLExport
modelica_string omc_System_gccVersion(threadData_t *threadData);
#define boxptr_System_gccVersion omc_System_gccVersion
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_gccVersion,2,0) {(void*) boxptr_System_gccVersion,0}};
#define boxvar_System_gccVersion MMC_REFSTRUCTLIT(boxvar_lit_System_gccVersion)
extern const char* System_gccVersion();
DLLExport
modelica_string omc_System_gccDumpMachine(threadData_t *threadData);
#define boxptr_System_gccDumpMachine omc_System_gccDumpMachine
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_gccDumpMachine,2,0) {(void*) boxptr_System_gccDumpMachine,0}};
#define boxvar_System_gccDumpMachine MMC_REFSTRUCTLIT(boxvar_lit_System_gccDumpMachine)
extern const char* System_gccDumpMachine();
DLLExport
modelica_string omc_System_openModelicaPlatform(threadData_t *threadData);
#define boxptr_System_openModelicaPlatform omc_System_openModelicaPlatform
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_openModelicaPlatform,2,0) {(void*) boxptr_System_openModelicaPlatform,0}};
#define boxvar_System_openModelicaPlatform MMC_REFSTRUCTLIT(boxvar_lit_System_openModelicaPlatform)
extern const char* System_openModelicaPlatform();
DLLExport
modelica_string omc_System_modelicaPlatform(threadData_t *threadData);
#define boxptr_System_modelicaPlatform omc_System_modelicaPlatform
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_modelicaPlatform,2,0) {(void*) boxptr_System_modelicaPlatform,0}};
#define boxvar_System_modelicaPlatform MMC_REFSTRUCTLIT(boxvar_lit_System_modelicaPlatform)
extern const char* System_modelicaPlatform();
DLLExport
modelica_string omc_System_uriToClassAndPath(threadData_t *threadData, modelica_string _uri, modelica_string *out_classname, modelica_string *out_pathname);
#define boxptr_System_uriToClassAndPath omc_System_uriToClassAndPath
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_uriToClassAndPath,2,0) {(void*) boxptr_System_uriToClassAndPath,0}};
#define boxvar_System_uriToClassAndPath MMC_REFSTRUCTLIT(boxvar_lit_System_uriToClassAndPath)
extern void System_uriToClassAndPath(const char* /*_uri*/, const char** /*_scheme*/, const char** /*_classname*/, const char** /*_pathname*/);
DLLExport
modelica_real omc_System_realMaxLit(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_realMaxLit(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_realMaxLit,2,0) {(void*) boxptr_System_realMaxLit,0}};
#define boxvar_System_realMaxLit MMC_REFSTRUCTLIT(boxvar_lit_System_realMaxLit)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern double realMaxLit();
*/
DLLExport
modelica_integer omc_System_intMaxLit(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_intMaxLit(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_intMaxLit,2,0) {(void*) boxptr_System_intMaxLit,0}};
#define boxvar_System_intMaxLit MMC_REFSTRUCTLIT(boxvar_lit_System_intMaxLit)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern int intMaxLit();
*/
DLLExport
modelica_string omc_System_unquoteIdentifier(threadData_t *threadData, modelica_string _str);
#define boxptr_System_unquoteIdentifier omc_System_unquoteIdentifier
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_unquoteIdentifier,2,0) {(void*) boxptr_System_unquoteIdentifier,0}};
#define boxvar_System_unquoteIdentifier MMC_REFSTRUCTLIT(boxvar_lit_System_unquoteIdentifier)
extern const char* System_unquoteIdentifier(const char* /*_str*/);
DLLExport
modelica_integer omc_System_unescapedStringLength(threadData_t *threadData, modelica_string _unescapedString);
DLLExport
modelica_metatype boxptr_System_unescapedStringLength(threadData_t *threadData, modelica_metatype _unescapedString);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_unescapedStringLength,2,0) {(void*) boxptr_System_unescapedStringLength,0}};
#define boxvar_System_unescapedStringLength MMC_REFSTRUCTLIT(boxvar_lit_System_unescapedStringLength)
extern int SystemImpl__unescapedStringLength(const char* /*_unescapedString*/);
DLLExport
modelica_string omc_System_unescapedString(threadData_t *threadData, modelica_string _escapedString);
#define boxptr_System_unescapedString omc_System_unescapedString
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_unescapedString,2,0) {(void*) boxptr_System_unescapedString,0}};
#define boxvar_System_unescapedString MMC_REFSTRUCTLIT(boxvar_lit_System_unescapedString)
extern const char* System_unescapedString(const char* /*_escapedString*/);
DLLExport
modelica_string omc_System_escapedString(threadData_t *threadData, modelica_string _unescapedString, modelica_boolean _unescapeNewline);
DLLExport
modelica_metatype boxptr_System_escapedString(threadData_t *threadData, modelica_metatype _unescapedString, modelica_metatype _unescapeNewline);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_escapedString,2,0) {(void*) boxptr_System_escapedString,0}};
#define boxvar_System_escapedString MMC_REFSTRUCTLIT(boxvar_lit_System_escapedString)
extern const char* System_escapedString(const char* /*_unescapedString*/, int /*_unescapeNewline*/);
DLLExport
modelica_string omc_System_dirname(threadData_t *threadData, modelica_string _filename);
#define boxptr_System_dirname omc_System_dirname
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_dirname,2,0) {(void*) boxptr_System_dirname,0}};
#define boxvar_System_dirname MMC_REFSTRUCTLIT(boxvar_lit_System_dirname)
extern const char* System_dirname(const char* /*_filename*/);
DLLExport
modelica_string omc_System_basename(threadData_t *threadData, modelica_string _filename);
#define boxptr_System_basename omc_System_basename
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_basename,2,0) {(void*) boxptr_System_basename,0}};
#define boxvar_System_basename MMC_REFSTRUCTLIT(boxvar_lit_System_basename)
extern const char* System_basename(const char* /*_filename*/);
DLLExport
modelica_string omc_System_getUUIDStr(threadData_t *threadData);
#define boxptr_System_getUUIDStr omc_System_getUUIDStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getUUIDStr,2,0) {(void*) boxptr_System_getUUIDStr,0}};
#define boxvar_System_getUUIDStr MMC_REFSTRUCTLIT(boxvar_lit_System_getUUIDStr)
extern const char* System_getUUIDStr();
DLLExport
modelica_integer omc_System_getTimerStackIndex(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_getTimerStackIndex(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getTimerStackIndex,2,0) {(void*) boxptr_System_getTimerStackIndex,0}};
#define boxvar_System_getTimerStackIndex MMC_REFSTRUCTLIT(boxvar_lit_System_getTimerStackIndex)
extern int System_getTimerStackIndex();
DLLExport
modelica_real omc_System_getTimerElapsedTime(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_getTimerElapsedTime(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getTimerElapsedTime,2,0) {(void*) boxptr_System_getTimerElapsedTime,0}};
#define boxvar_System_getTimerElapsedTime MMC_REFSTRUCTLIT(boxvar_lit_System_getTimerElapsedTime)
extern double System_getTimerElapsedTime();
DLLExport
modelica_real omc_System_getTimerCummulatedTime(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_getTimerCummulatedTime(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getTimerCummulatedTime,2,0) {(void*) boxptr_System_getTimerCummulatedTime,0}};
#define boxvar_System_getTimerCummulatedTime MMC_REFSTRUCTLIT(boxvar_lit_System_getTimerCummulatedTime)
extern double System_getTimerCummulatedTime();
DLLExport
modelica_real omc_System_getTimerIntervalTime(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_getTimerIntervalTime(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getTimerIntervalTime,2,0) {(void*) boxptr_System_getTimerIntervalTime,0}};
#define boxvar_System_getTimerIntervalTime MMC_REFSTRUCTLIT(boxvar_lit_System_getTimerIntervalTime)
extern double System_getTimerIntervalTime();
DLLExport
void omc_System_stopTimer(threadData_t *threadData);
#define boxptr_System_stopTimer omc_System_stopTimer
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_stopTimer,2,0) {(void*) boxptr_System_stopTimer,0}};
#define boxvar_System_stopTimer MMC_REFSTRUCTLIT(boxvar_lit_System_stopTimer)
extern void System_stopTimer();
DLLExport
void omc_System_startTimer(threadData_t *threadData);
#define boxptr_System_startTimer omc_System_startTimer
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_startTimer,2,0) {(void*) boxptr_System_startTimer,0}};
#define boxvar_System_startTimer MMC_REFSTRUCTLIT(boxvar_lit_System_startTimer)
extern void System_startTimer();
DLLExport
void omc_System_resetTimer(threadData_t *threadData);
#define boxptr_System_resetTimer omc_System_resetTimer
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_resetTimer,2,0) {(void*) boxptr_System_resetTimer,0}};
#define boxvar_System_resetTimer MMC_REFSTRUCTLIT(boxvar_lit_System_resetTimer)
extern void System_resetTimer();
DLLExport
modelica_integer omc_System_realtimeNtick(threadData_t *threadData, modelica_integer _clockIndex);
DLLExport
modelica_metatype boxptr_System_realtimeNtick(threadData_t *threadData, modelica_metatype _clockIndex);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_realtimeNtick,2,0) {(void*) boxptr_System_realtimeNtick,0}};
#define boxvar_System_realtimeNtick MMC_REFSTRUCTLIT(boxvar_lit_System_realtimeNtick)
extern int System_realtimeNtick(int /*_clockIndex*/);
DLLExport
void omc_System_realtimeClear(threadData_t *threadData, modelica_integer _clockIndex);
DLLExport
void boxptr_System_realtimeClear(threadData_t *threadData, modelica_metatype _clockIndex);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_realtimeClear,2,0) {(void*) boxptr_System_realtimeClear,0}};
#define boxvar_System_realtimeClear MMC_REFSTRUCTLIT(boxvar_lit_System_realtimeClear)
extern void System_realtimeClear(int /*_clockIndex*/);
DLLExport
modelica_real omc_System_realtimeTock(threadData_t *threadData, modelica_integer _clockIndex);
DLLExport
modelica_metatype boxptr_System_realtimeTock(threadData_t *threadData, modelica_metatype _clockIndex);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_realtimeTock,2,0) {(void*) boxptr_System_realtimeTock,0}};
#define boxvar_System_realtimeTock MMC_REFSTRUCTLIT(boxvar_lit_System_realtimeTock)
extern double System_realtimeTock(int /*_clockIndex*/);
DLLExport
void omc_System_realtimeTick(threadData_t *threadData, modelica_integer _clockIndex);
DLLExport
void boxptr_System_realtimeTick(threadData_t *threadData, modelica_metatype _clockIndex);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_realtimeTick,2,0) {(void*) boxptr_System_realtimeTick,0}};
#define boxvar_System_realtimeTick MMC_REFSTRUCTLIT(boxvar_lit_System_realtimeTick)
extern void System_realtimeTick(int /*_clockIndex*/);
DLLExport
modelica_integer omc_System_getuid(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_getuid(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getuid,2,0) {(void*) boxptr_System_getuid,0}};
#define boxvar_System_getuid MMC_REFSTRUCTLIT(boxvar_lit_System_getuid)
extern int System_getuid();
DLLExport
modelica_boolean omc_System_userIsRoot(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_userIsRoot(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_userIsRoot,2,0) {(void*) boxptr_System_userIsRoot,0}};
#define boxvar_System_userIsRoot MMC_REFSTRUCTLIT(boxvar_lit_System_userIsRoot)
extern int System_userIsRoot();
DLLExport
modelica_integer omc_System_tmpTickMaximum(threadData_t *threadData, modelica_integer _index);
DLLExport
modelica_metatype boxptr_System_tmpTickMaximum(threadData_t *threadData, modelica_metatype _index);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_tmpTickMaximum,2,0) {(void*) boxptr_System_tmpTickMaximum,0}};
#define boxvar_System_tmpTickMaximum MMC_REFSTRUCTLIT(boxvar_lit_System_tmpTickMaximum)
extern int SystemImpl_tmpTickMaximum(OpenModelica_threadData_ThreadData*, int /*_index*/);
DLLExport
void omc_System_tmpTickSetIndex(threadData_t *threadData, modelica_integer _start, modelica_integer _index);
DLLExport
void boxptr_System_tmpTickSetIndex(threadData_t *threadData, modelica_metatype _start, modelica_metatype _index);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_tmpTickSetIndex,2,0) {(void*) boxptr_System_tmpTickSetIndex,0}};
#define boxvar_System_tmpTickSetIndex MMC_REFSTRUCTLIT(boxvar_lit_System_tmpTickSetIndex)
extern void SystemImpl_tmpTickSetIndex(OpenModelica_threadData_ThreadData*, int /*_start*/, int /*_index*/);
DLLExport
void omc_System_tmpTickResetIndex(threadData_t *threadData, modelica_integer _start, modelica_integer _index);
DLLExport
void boxptr_System_tmpTickResetIndex(threadData_t *threadData, modelica_metatype _start, modelica_metatype _index);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_tmpTickResetIndex,2,0) {(void*) boxptr_System_tmpTickResetIndex,0}};
#define boxvar_System_tmpTickResetIndex MMC_REFSTRUCTLIT(boxvar_lit_System_tmpTickResetIndex)
extern void SystemImpl_tmpTickResetIndex(OpenModelica_threadData_ThreadData*, int /*_start*/, int /*_index*/);
DLLExport
modelica_integer omc_System_tmpTickIndexReserve(threadData_t *threadData, modelica_integer _index, modelica_integer _reserve);
DLLExport
modelica_metatype boxptr_System_tmpTickIndexReserve(threadData_t *threadData, modelica_metatype _index, modelica_metatype _reserve);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_tmpTickIndexReserve,2,0) {(void*) boxptr_System_tmpTickIndexReserve,0}};
#define boxvar_System_tmpTickIndexReserve MMC_REFSTRUCTLIT(boxvar_lit_System_tmpTickIndexReserve)
extern int SystemImpl_tmpTickIndexReserve(OpenModelica_threadData_ThreadData*, int /*_index*/, int /*_reserve*/);
DLLExport
modelica_integer omc_System_tmpTickIndex(threadData_t *threadData, modelica_integer _index);
DLLExport
modelica_metatype boxptr_System_tmpTickIndex(threadData_t *threadData, modelica_metatype _index);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_tmpTickIndex,2,0) {(void*) boxptr_System_tmpTickIndex,0}};
#define boxvar_System_tmpTickIndex MMC_REFSTRUCTLIT(boxvar_lit_System_tmpTickIndex)
extern int SystemImpl_tmpTickIndex(OpenModelica_threadData_ThreadData*, int /*_index*/);
DLLExport
void omc_System_tmpTickReset(threadData_t *threadData, modelica_integer _start);
DLLExport
void boxptr_System_tmpTickReset(threadData_t *threadData, modelica_metatype _start);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_tmpTickReset,2,0) {(void*) boxptr_System_tmpTickReset,0}};
#define boxvar_System_tmpTickReset MMC_REFSTRUCTLIT(boxvar_lit_System_tmpTickReset)
extern void SystemImpl_tmpTickReset(OpenModelica_threadData_ThreadData*, int /*_start*/);
DLLExport
modelica_integer omc_System_tmpTick(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_tmpTick(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_tmpTick,2,0) {(void*) boxptr_System_tmpTick,0}};
#define boxvar_System_tmpTick MMC_REFSTRUCTLIT(boxvar_lit_System_tmpTick)
DLLExport
modelica_boolean omc_System_getHasInnerOuterDefinitions(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_getHasInnerOuterDefinitions(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getHasInnerOuterDefinitions,2,0) {(void*) boxptr_System_getHasInnerOuterDefinitions,0}};
#define boxvar_System_getHasInnerOuterDefinitions MMC_REFSTRUCTLIT(boxvar_lit_System_getHasInnerOuterDefinitions)
extern int System_getHasInnerOuterDefinitions();
DLLExport
void omc_System_setHasInnerOuterDefinitions(threadData_t *threadData, modelica_boolean _hasInnerOuterDefinitions);
DLLExport
void boxptr_System_setHasInnerOuterDefinitions(threadData_t *threadData, modelica_metatype _hasInnerOuterDefinitions);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_setHasInnerOuterDefinitions,2,0) {(void*) boxptr_System_setHasInnerOuterDefinitions,0}};
#define boxvar_System_setHasInnerOuterDefinitions MMC_REFSTRUCTLIT(boxvar_lit_System_setHasInnerOuterDefinitions)
extern void System_setHasInnerOuterDefinitions(int /*_hasInnerOuterDefinitions*/);
DLLExport
modelica_boolean omc_System_getUsesCardinality(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_getUsesCardinality(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getUsesCardinality,2,0) {(void*) boxptr_System_getUsesCardinality,0}};
#define boxvar_System_getUsesCardinality MMC_REFSTRUCTLIT(boxvar_lit_System_getUsesCardinality)
extern int System_getUsesCardinality();
DLLExport
void omc_System_setUsesCardinality(threadData_t *threadData, modelica_boolean _inUses);
DLLExport
void boxptr_System_setUsesCardinality(threadData_t *threadData, modelica_metatype _inUses);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_setUsesCardinality,2,0) {(void*) boxptr_System_setUsesCardinality,0}};
#define boxvar_System_setUsesCardinality MMC_REFSTRUCTLIT(boxvar_lit_System_setUsesCardinality)
extern void System_setUsesCardinality(int /*_inUses*/);
DLLExport
modelica_boolean omc_System_getHasStreamConnectors(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_getHasStreamConnectors(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getHasStreamConnectors,2,0) {(void*) boxptr_System_getHasStreamConnectors,0}};
#define boxvar_System_getHasStreamConnectors MMC_REFSTRUCTLIT(boxvar_lit_System_getHasStreamConnectors)
extern int System_getHasStreamConnectors();
DLLExport
void omc_System_setHasStreamConnectors(threadData_t *threadData, modelica_boolean _hasStream);
DLLExport
void boxptr_System_setHasStreamConnectors(threadData_t *threadData, modelica_metatype _hasStream);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_setHasStreamConnectors,2,0) {(void*) boxptr_System_setHasStreamConnectors,0}};
#define boxvar_System_setHasStreamConnectors MMC_REFSTRUCTLIT(boxvar_lit_System_setHasStreamConnectors)
extern void System_setHasStreamConnectors(int /*_hasStream*/);
DLLExport
modelica_boolean omc_System_getPartialInstantiation(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_getPartialInstantiation(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getPartialInstantiation,2,0) {(void*) boxptr_System_getPartialInstantiation,0}};
#define boxvar_System_getPartialInstantiation MMC_REFSTRUCTLIT(boxvar_lit_System_getPartialInstantiation)
extern int System_getPartialInstantiation();
DLLExport
void omc_System_setPartialInstantiation(threadData_t *threadData, modelica_boolean _isPartialInstantiation);
DLLExport
void boxptr_System_setPartialInstantiation(threadData_t *threadData, modelica_metatype _isPartialInstantiation);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_setPartialInstantiation,2,0) {(void*) boxptr_System_setPartialInstantiation,0}};
#define boxvar_System_setPartialInstantiation MMC_REFSTRUCTLIT(boxvar_lit_System_setPartialInstantiation)
extern void System_setPartialInstantiation(int /*_isPartialInstantiation*/);
DLLExport
modelica_boolean omc_System_getHasOverconstrainedConnectors(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_getHasOverconstrainedConnectors(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getHasOverconstrainedConnectors,2,0) {(void*) boxptr_System_getHasOverconstrainedConnectors,0}};
#define boxvar_System_getHasOverconstrainedConnectors MMC_REFSTRUCTLIT(boxvar_lit_System_getHasOverconstrainedConnectors)
extern int System_getHasOverconstrainedConnectors();
DLLExport
void omc_System_setHasOverconstrainedConnectors(threadData_t *threadData, modelica_boolean _hasOverconstrained);
DLLExport
void boxptr_System_setHasOverconstrainedConnectors(threadData_t *threadData, modelica_metatype _hasOverconstrained);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_setHasOverconstrainedConnectors,2,0) {(void*) boxptr_System_setHasOverconstrainedConnectors,0}};
#define boxvar_System_setHasOverconstrainedConnectors MMC_REFSTRUCTLIT(boxvar_lit_System_setHasOverconstrainedConnectors)
extern void System_setHasOverconstrainedConnectors(int /*_hasOverconstrained*/);
DLLExport
modelica_boolean omc_System_getHasExpandableConnectors(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_getHasExpandableConnectors(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getHasExpandableConnectors,2,0) {(void*) boxptr_System_getHasExpandableConnectors,0}};
#define boxvar_System_getHasExpandableConnectors MMC_REFSTRUCTLIT(boxvar_lit_System_getHasExpandableConnectors)
extern int System_getHasExpandableConnectors();
DLLExport
void omc_System_setHasExpandableConnectors(threadData_t *threadData, modelica_boolean _hasExpandable);
DLLExport
void boxptr_System_setHasExpandableConnectors(threadData_t *threadData, modelica_metatype _hasExpandable);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_setHasExpandableConnectors,2,0) {(void*) boxptr_System_setHasExpandableConnectors,0}};
#define boxvar_System_setHasExpandableConnectors MMC_REFSTRUCTLIT(boxvar_lit_System_setHasExpandableConnectors)
extern void System_setHasExpandableConnectors(int /*_hasExpandable*/);
DLLExport
modelica_string omc_System_readFileNoNumeric(threadData_t *threadData, modelica_string _inString);
#define boxptr_System_readFileNoNumeric omc_System_readFileNoNumeric
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_readFileNoNumeric,2,0) {(void*) boxptr_System_readFileNoNumeric,0}};
#define boxvar_System_readFileNoNumeric MMC_REFSTRUCTLIT(boxvar_lit_System_readFileNoNumeric)
extern const char* SystemImpl__readFileNoNumeric(const char* /*_inString*/);
DLLExport
modelica_string omc_System_getCurrentTimeStr(threadData_t *threadData);
#define boxptr_System_getCurrentTimeStr omc_System_getCurrentTimeStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getCurrentTimeStr,2,0) {(void*) boxptr_System_getCurrentTimeStr,0}};
#define boxvar_System_getCurrentTimeStr MMC_REFSTRUCTLIT(boxvar_lit_System_getCurrentTimeStr)
extern const char* System_getCurrentTimeStr();
DLLExport
modelica_integer omc_System_getCurrentDateTime(threadData_t *threadData, modelica_integer *out_min, modelica_integer *out_hour, modelica_integer *out_mday, modelica_integer *out_mon, modelica_integer *out_year);
DLLExport
modelica_metatype boxptr_System_getCurrentDateTime(threadData_t *threadData, modelica_metatype *out_min, modelica_metatype *out_hour, modelica_metatype *out_mday, modelica_metatype *out_mon, modelica_metatype *out_year);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getCurrentDateTime,2,0) {(void*) boxptr_System_getCurrentDateTime,0}};
#define boxvar_System_getCurrentDateTime MMC_REFSTRUCTLIT(boxvar_lit_System_getCurrentDateTime)
extern void System_getCurrentDateTime(int* /*_sec*/, int* /*_min*/, int* /*_hour*/, int* /*_mday*/, int* /*_mon*/, int* /*_year*/);
DLLExport
modelica_real omc_System_getCurrentTime(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_getCurrentTime(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getCurrentTime,2,0) {(void*) boxptr_System_getCurrentTime,0}};
#define boxvar_System_getCurrentTime MMC_REFSTRUCTLIT(boxvar_lit_System_getCurrentTime)
extern double SystemImpl__getCurrentTime();
DLLExport
modelica_metatype omc_System_getFileModificationTime(threadData_t *threadData, modelica_string _fileName);
#define boxptr_System_getFileModificationTime omc_System_getFileModificationTime
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getFileModificationTime,2,0) {(void*) boxptr_System_getFileModificationTime,0}};
#define boxvar_System_getFileModificationTime MMC_REFSTRUCTLIT(boxvar_lit_System_getFileModificationTime)
extern modelica_metatype System_getFileModificationTime(const char* /*_fileName*/);
DLLExport
modelica_real omc_System_getVariableValue(threadData_t *threadData, modelica_real _timeStamp, modelica_metatype _timeValues, modelica_metatype _varValues);
DLLExport
modelica_metatype boxptr_System_getVariableValue(threadData_t *threadData, modelica_metatype _timeStamp, modelica_metatype _timeValues, modelica_metatype _varValues);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getVariableValue,2,0) {(void*) boxptr_System_getVariableValue,0}};
#define boxvar_System_getVariableValue MMC_REFSTRUCTLIT(boxvar_lit_System_getVariableValue)
extern double System_getVariableValue(double /*_timeStamp*/, modelica_metatype /*_timeValues*/, modelica_metatype /*_varValues*/);
DLLExport
void omc_System_setClassnamesForSimulation(threadData_t *threadData, modelica_string _inString);
#define boxptr_System_setClassnamesForSimulation omc_System_setClassnamesForSimulation
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_setClassnamesForSimulation,2,0) {(void*) boxptr_System_setClassnamesForSimulation,0}};
#define boxvar_System_setClassnamesForSimulation MMC_REFSTRUCTLIT(boxvar_lit_System_setClassnamesForSimulation)
extern void System_setClassnamesForSimulation(const char* /*_inString*/);
DLLExport
modelica_string omc_System_getClassnamesForSimulation(threadData_t *threadData);
#define boxptr_System_getClassnamesForSimulation omc_System_getClassnamesForSimulation
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getClassnamesForSimulation,2,0) {(void*) boxptr_System_getClassnamesForSimulation,0}};
#define boxvar_System_getClassnamesForSimulation MMC_REFSTRUCTLIT(boxvar_lit_System_getClassnamesForSimulation)
extern const char* System_getClassnamesForSimulation();
extern int SystemImpl__removeDirectory(const char* /*_inString*/);
DLLExport
modelica_boolean omc_System_removeDirectory(threadData_t *threadData, modelica_string _inString);
DLLExport
modelica_metatype boxptr_System_removeDirectory(threadData_t *threadData, modelica_metatype _inString);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_removeDirectory,2,0) {(void*) boxptr_System_removeDirectory,0}};
#define boxvar_System_removeDirectory MMC_REFSTRUCTLIT(boxvar_lit_System_removeDirectory)
DLLExport
modelica_boolean omc_System_copyFile(threadData_t *threadData, modelica_string _source, modelica_string _destination);
DLLExport
modelica_metatype boxptr_System_copyFile(threadData_t *threadData, modelica_metatype _source, modelica_metatype _destination);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_copyFile,2,0) {(void*) boxptr_System_copyFile,0}};
#define boxvar_System_copyFile MMC_REFSTRUCTLIT(boxvar_lit_System_copyFile)
extern int SystemImpl__copyFile(const char* /*_source*/, const char* /*_destination*/);
DLLExport
modelica_boolean omc_System_directoryExists(threadData_t *threadData, modelica_string _inString);
DLLExport
modelica_metatype boxptr_System_directoryExists(threadData_t *threadData, modelica_metatype _inString);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_directoryExists,2,0) {(void*) boxptr_System_directoryExists,0}};
#define boxvar_System_directoryExists MMC_REFSTRUCTLIT(boxvar_lit_System_directoryExists)
extern int SystemImpl__directoryExists(const char* /*_inString*/);
DLLExport
modelica_integer omc_System_removeFile(threadData_t *threadData, modelica_string _fileName);
DLLExport
modelica_metatype boxptr_System_removeFile(threadData_t *threadData, modelica_metatype _fileName);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_removeFile,2,0) {(void*) boxptr_System_removeFile,0}};
#define boxvar_System_removeFile MMC_REFSTRUCTLIT(boxvar_lit_System_removeFile)
extern int SystemImpl__removeFile(const char* /*_fileName*/);
DLLExport
modelica_boolean omc_System_regularFileExists(threadData_t *threadData, modelica_string _inString);
DLLExport
modelica_metatype boxptr_System_regularFileExists(threadData_t *threadData, modelica_metatype _inString);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_regularFileExists,2,0) {(void*) boxptr_System_regularFileExists,0}};
#define boxvar_System_regularFileExists MMC_REFSTRUCTLIT(boxvar_lit_System_regularFileExists)
extern int SystemImpl__regularFileExists(const char* /*_inString*/);
DLLExport
modelica_real omc_System_time(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_time(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_time,2,0) {(void*) boxptr_System_time,0}};
#define boxvar_System_time MMC_REFSTRUCTLIT(boxvar_lit_System_time)
extern double SystemImpl__time();
DLLExport
modelica_string omc_System_getLoadModelPath(threadData_t *threadData, modelica_string _className, modelica_metatype _prios, modelica_metatype _mps, modelica_boolean _requireExactVersion, modelica_string *out_name, modelica_boolean *out_isDir);
DLLExport
modelica_metatype boxptr_System_getLoadModelPath(threadData_t *threadData, modelica_metatype _className, modelica_metatype _prios, modelica_metatype _mps, modelica_metatype _requireExactVersion, modelica_metatype *out_name, modelica_metatype *out_isDir);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getLoadModelPath,2,0) {(void*) boxptr_System_getLoadModelPath,0}};
#define boxvar_System_getLoadModelPath MMC_REFSTRUCTLIT(boxvar_lit_System_getLoadModelPath)
extern void System_getLoadModelPath(const char* /*_className*/, modelica_metatype /*_prios*/, modelica_metatype /*_mps*/, int /*_requireExactVersion*/, const char** /*_dir*/, const char** /*_name*/, int* /*_isDir*/);
DLLExport
modelica_metatype omc_System_mocFiles(threadData_t *threadData, modelica_string _inString);
#define boxptr_System_mocFiles omc_System_mocFiles
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_mocFiles,2,0) {(void*) boxptr_System_mocFiles,0}};
#define boxvar_System_mocFiles MMC_REFSTRUCTLIT(boxvar_lit_System_mocFiles)
extern modelica_metatype System_mocFiles(const char* /*_inString*/);
DLLExport
modelica_metatype omc_System_moFiles(threadData_t *threadData, modelica_string _inString);
#define boxptr_System_moFiles omc_System_moFiles
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_moFiles,2,0) {(void*) boxptr_System_moFiles,0}};
#define boxvar_System_moFiles MMC_REFSTRUCTLIT(boxvar_lit_System_moFiles)
extern modelica_metatype System_moFiles(const char* /*_inString*/);
DLLExport
modelica_metatype omc_System_subDirectories(threadData_t *threadData, modelica_string _inString);
#define boxptr_System_subDirectories omc_System_subDirectories
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_subDirectories,2,0) {(void*) boxptr_System_subDirectories,0}};
#define boxvar_System_subDirectories MMC_REFSTRUCTLIT(boxvar_lit_System_subDirectories)
extern modelica_metatype System_subDirectories(const char* /*_inString*/);
DLLExport
modelica_integer omc_System_setEnv(threadData_t *threadData, modelica_string _varName, modelica_string _value, modelica_boolean _overwrite);
DLLExport
modelica_metatype boxptr_System_setEnv(threadData_t *threadData, modelica_metatype _varName, modelica_metatype _value, modelica_metatype _overwrite);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_setEnv,2,0) {(void*) boxptr_System_setEnv,0}};
#define boxvar_System_setEnv MMC_REFSTRUCTLIT(boxvar_lit_System_setEnv)
extern int setenv(const char* /*_varName*/, const char* /*_value*/, int /*_overwrite*/);
DLLExport
modelica_string omc_System_readEnv(threadData_t *threadData, modelica_string _inString);
#define boxptr_System_readEnv omc_System_readEnv
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_readEnv,2,0) {(void*) boxptr_System_readEnv,0}};
#define boxvar_System_readEnv MMC_REFSTRUCTLIT(boxvar_lit_System_readEnv)
extern const char* System_readEnv(const char* /*_inString*/);
DLLExport
modelica_string omc_System_pwd(threadData_t *threadData);
#define boxptr_System_pwd omc_System_pwd
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_pwd,2,0) {(void*) boxptr_System_pwd,0}};
#define boxvar_System_pwd MMC_REFSTRUCTLIT(boxvar_lit_System_pwd)
extern const char* SystemImpl__pwd();
DLLExport
modelica_string omc_System_createTemporaryDirectory(threadData_t *threadData, modelica_string _inPrefix);
#define boxptr_System_createTemporaryDirectory omc_System_createTemporaryDirectory
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_createTemporaryDirectory,2,0) {(void*) boxptr_System_createTemporaryDirectory,0}};
#define boxvar_System_createTemporaryDirectory MMC_REFSTRUCTLIT(boxvar_lit_System_createTemporaryDirectory)
extern const char* SystemImpl__createTemporaryDirectory(const char* /*_inPrefix*/);
DLLExport
modelica_boolean omc_System_createDirectory(threadData_t *threadData, modelica_string _inString);
DLLExport
modelica_metatype boxptr_System_createDirectory(threadData_t *threadData, modelica_metatype _inString);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_createDirectory,2,0) {(void*) boxptr_System_createDirectory,0}};
#define boxvar_System_createDirectory MMC_REFSTRUCTLIT(boxvar_lit_System_createDirectory)
extern int SystemImpl__createDirectory(const char* /*_inString*/);
DLLExport
modelica_integer omc_System_cd(threadData_t *threadData, modelica_string _inString);
DLLExport
modelica_metatype boxptr_System_cd(threadData_t *threadData, modelica_metatype _inString);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_cd,2,0) {(void*) boxptr_System_cd,0}};
#define boxvar_System_cd MMC_REFSTRUCTLIT(boxvar_lit_System_cd)
extern int SystemImpl__chdir(const char* /*_inString*/);
DLLExport
void omc_System_plotCallBack(threadData_t *threadData, modelica_boolean _externalWindow, modelica_string _filename, modelica_string _title, modelica_string _grid, modelica_string _plotType, modelica_string _logX, modelica_string _logY, modelica_string _xLabel, modelica_string _yLabel, modelica_string _x1, modelica_string _x2, modelica_string _y1, modelica_string _y2, modelica_string _curveWidth, modelica_string _curveStyle, modelica_string _legendPosition, modelica_string _footer, modelica_string _autoScale, modelica_string _variables);
DLLExport
void boxptr_System_plotCallBack(threadData_t *threadData, modelica_metatype _externalWindow, modelica_metatype _filename, modelica_metatype _title, modelica_metatype _grid, modelica_metatype _plotType, modelica_metatype _logX, modelica_metatype _logY, modelica_metatype _xLabel, modelica_metatype _yLabel, modelica_metatype _x1, modelica_metatype _x2, modelica_metatype _y1, modelica_metatype _y2, modelica_metatype _curveWidth, modelica_metatype _curveStyle, modelica_metatype _legendPosition, modelica_metatype _footer, modelica_metatype _autoScale, modelica_metatype _variables);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_plotCallBack,2,0) {(void*) boxptr_System_plotCallBack,0}};
#define boxvar_System_plotCallBack MMC_REFSTRUCTLIT(boxvar_lit_System_plotCallBack)
extern void SystemImpl__plotCallBack(OpenModelica_threadData_ThreadData*, int /*_externalWindow*/, const char* /*_filename*/, const char* /*_title*/, const char* /*_grid*/, const char* /*_plotType*/, const char* /*_logX*/, const char* /*_logY*/, const char* /*_xLabel*/, const char* /*_yLabel*/, const char* /*_x1*/, const char* /*_x2*/, const char* /*_y1*/, const char* /*_y2*/, const char* /*_curveWidth*/, const char* /*_curveStyle*/, const char* /*_legendPosition*/, const char* /*_footer*/, const char* /*_autoScale*/, const char* /*_variables*/);
DLLExport
modelica_boolean omc_System_plotCallBackDefined(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_System_plotCallBackDefined(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_plotCallBackDefined,2,0) {(void*) boxptr_System_plotCallBackDefined,0}};
#define boxvar_System_plotCallBackDefined MMC_REFSTRUCTLIT(boxvar_lit_System_plotCallBackDefined)
extern int SystemImpl__plotCallBackDefined(OpenModelica_threadData_ThreadData*);
DLLExport
modelica_integer omc_System_spawnCall(threadData_t *threadData, modelica_string _path, modelica_string _str);
DLLExport
modelica_metatype boxptr_System_spawnCall(threadData_t *threadData, modelica_metatype _path, modelica_metatype _str);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_spawnCall,2,0) {(void*) boxptr_System_spawnCall,0}};
#define boxvar_System_spawnCall MMC_REFSTRUCTLIT(boxvar_lit_System_spawnCall)
extern int SystemImpl__spawnCall(const char* /*_path*/, const char* /*_str*/);
DLLExport
modelica_metatype omc_System_systemCallParallel(threadData_t *threadData, modelica_metatype _inStrings, modelica_integer _numThreads);
DLLExport
modelica_metatype boxptr_System_systemCallParallel(threadData_t *threadData, modelica_metatype _inStrings, modelica_metatype _numThreads);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_systemCallParallel,2,0) {(void*) boxptr_System_systemCallParallel,0}};
#define boxvar_System_systemCallParallel MMC_REFSTRUCTLIT(boxvar_lit_System_systemCallParallel)
extern modelica_metatype SystemImpl__systemCallParallel(modelica_metatype /*_inStrings*/, int /*_numThreads*/);
DLLExport
modelica_string omc_System_popen(threadData_t *threadData, modelica_string _command, modelica_integer *out_status);
DLLExport
modelica_metatype boxptr_System_popen(threadData_t *threadData, modelica_metatype _command, modelica_metatype *out_status);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_popen,2,0) {(void*) boxptr_System_popen,0}};
#define boxvar_System_popen MMC_REFSTRUCTLIT(boxvar_lit_System_popen)
extern const char* System_popen(OpenModelica_threadData_ThreadData*, const char* /*_command*/, int* /*_status*/);
DLLExport
modelica_integer omc_System_systemCall(threadData_t *threadData, modelica_string _command, modelica_string _outFile);
DLLExport
modelica_metatype boxptr_System_systemCall(threadData_t *threadData, modelica_metatype _command, modelica_metatype _outFile);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_systemCall,2,0) {(void*) boxptr_System_systemCall,0}};
#define boxvar_System_systemCall MMC_REFSTRUCTLIT(boxvar_lit_System_systemCall)
extern int SystemImpl__systemCall(const char* /*_command*/, const char* /*_outFile*/);
DLLExport
modelica_string omc_System_readFile(threadData_t *threadData, modelica_string _inString);
#define boxptr_System_readFile omc_System_readFile
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_readFile,2,0) {(void*) boxptr_System_readFile,0}};
#define boxvar_System_readFile MMC_REFSTRUCTLIT(boxvar_lit_System_readFile)
extern const char* System_readFile(const char* /*_inString*/);
DLLExport
void omc_System_appendFile(threadData_t *threadData, modelica_string _file, modelica_string _data);
#define boxptr_System_appendFile omc_System_appendFile
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_appendFile,2,0) {(void*) boxptr_System_appendFile,0}};
#define boxvar_System_appendFile MMC_REFSTRUCTLIT(boxvar_lit_System_appendFile)
extern void System_appendFile(const char* /*_file*/, const char* /*_data*/);
DLLExport
void omc_System_writeFile(threadData_t *threadData, modelica_string _fileNameToWrite, modelica_string _stringToBeWritten);
#define boxptr_System_writeFile omc_System_writeFile
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_writeFile,2,0) {(void*) boxptr_System_writeFile,0}};
#define boxvar_System_writeFile MMC_REFSTRUCTLIT(boxvar_lit_System_writeFile)
extern void System_writeFile(const char* /*_fileNameToWrite*/, const char* /*_stringToBeWritten*/);
DLLExport
void omc_System_freeLibrary(threadData_t *threadData, modelica_integer _inLibHandle, modelica_boolean _inPrintDebug);
DLLExport
void boxptr_System_freeLibrary(threadData_t *threadData, modelica_metatype _inLibHandle, modelica_metatype _inPrintDebug);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_freeLibrary,2,0) {(void*) boxptr_System_freeLibrary,0}};
#define boxvar_System_freeLibrary MMC_REFSTRUCTLIT(boxvar_lit_System_freeLibrary)
extern void System_freeLibrary(int /*_inLibHandle*/, int /*_inPrintDebug*/);
DLLExport
void omc_System_freeFunction(threadData_t *threadData, modelica_integer _inFuncHandle, modelica_boolean _inPrintDebug);
DLLExport
void boxptr_System_freeFunction(threadData_t *threadData, modelica_metatype _inFuncHandle, modelica_metatype _inPrintDebug);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_freeFunction,2,0) {(void*) boxptr_System_freeFunction,0}};
#define boxvar_System_freeFunction MMC_REFSTRUCTLIT(boxvar_lit_System_freeFunction)
extern void System_freeFunction(int /*_inFuncHandle*/, int /*_inPrintDebug*/);
DLLExport
modelica_integer omc_System_lookupFunction(threadData_t *threadData, modelica_integer _inLibHandle, modelica_string _inFunc);
DLLExport
modelica_metatype boxptr_System_lookupFunction(threadData_t *threadData, modelica_metatype _inLibHandle, modelica_metatype _inFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_lookupFunction,2,0) {(void*) boxptr_System_lookupFunction,0}};
#define boxvar_System_lookupFunction MMC_REFSTRUCTLIT(boxvar_lit_System_lookupFunction)
extern int System_lookupFunction(int /*_inLibHandle*/, const char* /*_inFunc*/);
DLLExport
modelica_integer omc_System_loadLibrary(threadData_t *threadData, modelica_string _inLib, modelica_boolean _inPrintDebug);
DLLExport
modelica_metatype boxptr_System_loadLibrary(threadData_t *threadData, modelica_metatype _inLib, modelica_metatype _inPrintDebug);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_loadLibrary,2,0) {(void*) boxptr_System_loadLibrary,0}};
#define boxvar_System_loadLibrary MMC_REFSTRUCTLIT(boxvar_lit_System_loadLibrary)
extern int System_loadLibrary(const char* /*_inLib*/, int /*_inPrintDebug*/);
DLLExport
modelica_string omc_System_getLDFlags(threadData_t *threadData);
#define boxptr_System_getLDFlags omc_System_getLDFlags
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getLDFlags,2,0) {(void*) boxptr_System_getLDFlags,0}};
#define boxvar_System_getLDFlags MMC_REFSTRUCTLIT(boxvar_lit_System_getLDFlags)
extern const char* System_getLDFlags();
DLLExport
void omc_System_setLDFlags(threadData_t *threadData, modelica_string _inString);
#define boxptr_System_setLDFlags omc_System_setLDFlags
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_setLDFlags,2,0) {(void*) boxptr_System_setLDFlags,0}};
#define boxvar_System_setLDFlags MMC_REFSTRUCTLIT(boxvar_lit_System_setLDFlags)
extern void SystemImpl__setLDFlags(const char* /*_inString*/);
DLLExport
modelica_string omc_System_getLinker(threadData_t *threadData);
#define boxptr_System_getLinker omc_System_getLinker
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getLinker,2,0) {(void*) boxptr_System_getLinker,0}};
#define boxvar_System_getLinker MMC_REFSTRUCTLIT(boxvar_lit_System_getLinker)
extern const char* System_getLinker();
DLLExport
void omc_System_setLinker(threadData_t *threadData, modelica_string _inString);
#define boxptr_System_setLinker omc_System_setLinker
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_setLinker,2,0) {(void*) boxptr_System_setLinker,0}};
#define boxvar_System_setLinker MMC_REFSTRUCTLIT(boxvar_lit_System_setLinker)
extern void SystemImpl__setLinker(const char* /*_inString*/);
DLLExport
modelica_string omc_System_getOMPCCompiler(threadData_t *threadData);
#define boxptr_System_getOMPCCompiler omc_System_getOMPCCompiler
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getOMPCCompiler,2,0) {(void*) boxptr_System_getOMPCCompiler,0}};
#define boxvar_System_getOMPCCompiler MMC_REFSTRUCTLIT(boxvar_lit_System_getOMPCCompiler)
extern const char* System_getOMPCCompiler();
DLLExport
modelica_string omc_System_getCXXCompiler(threadData_t *threadData);
#define boxptr_System_getCXXCompiler omc_System_getCXXCompiler
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getCXXCompiler,2,0) {(void*) boxptr_System_getCXXCompiler,0}};
#define boxvar_System_getCXXCompiler MMC_REFSTRUCTLIT(boxvar_lit_System_getCXXCompiler)
extern const char* System_getCXXCompiler();
DLLExport
void omc_System_setCXXCompiler(threadData_t *threadData, modelica_string _inString);
#define boxptr_System_setCXXCompiler omc_System_setCXXCompiler
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_setCXXCompiler,2,0) {(void*) boxptr_System_setCXXCompiler,0}};
#define boxvar_System_setCXXCompiler MMC_REFSTRUCTLIT(boxvar_lit_System_setCXXCompiler)
extern void SystemImpl__setCXXCompiler(const char* /*_inString*/);
DLLExport
modelica_string omc_System_getCFlags(threadData_t *threadData);
#define boxptr_System_getCFlags omc_System_getCFlags
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getCFlags,2,0) {(void*) boxptr_System_getCFlags,0}};
#define boxvar_System_getCFlags MMC_REFSTRUCTLIT(boxvar_lit_System_getCFlags)
extern const char* System_getCFlags();
DLLExport
void omc_System_setCFlags(threadData_t *threadData, modelica_string _inString);
#define boxptr_System_setCFlags omc_System_setCFlags
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_setCFlags,2,0) {(void*) boxptr_System_setCFlags,0}};
#define boxvar_System_setCFlags MMC_REFSTRUCTLIT(boxvar_lit_System_setCFlags)
extern void SystemImpl__setCFlags(const char* /*_inString*/);
DLLExport
modelica_string omc_System_getCCompiler(threadData_t *threadData);
#define boxptr_System_getCCompiler omc_System_getCCompiler
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_getCCompiler,2,0) {(void*) boxptr_System_getCCompiler,0}};
#define boxvar_System_getCCompiler MMC_REFSTRUCTLIT(boxvar_lit_System_getCCompiler)
extern const char* System_getCCompiler();
DLLExport
void omc_System_setCCompiler(threadData_t *threadData, modelica_string _inString);
#define boxptr_System_setCCompiler omc_System_setCCompiler
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_setCCompiler,2,0) {(void*) boxptr_System_setCCompiler,0}};
#define boxvar_System_setCCompiler MMC_REFSTRUCTLIT(boxvar_lit_System_setCCompiler)
extern void SystemImpl__setCCompiler(const char* /*_inString*/);
DLLExport
modelica_metatype omc_System_strtokIncludingDelimiters(threadData_t *threadData, modelica_string _string, modelica_string _token);
#define boxptr_System_strtokIncludingDelimiters omc_System_strtokIncludingDelimiters
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_strtokIncludingDelimiters,2,0) {(void*) boxptr_System_strtokIncludingDelimiters,0}};
#define boxvar_System_strtokIncludingDelimiters MMC_REFSTRUCTLIT(boxvar_lit_System_strtokIncludingDelimiters)
extern modelica_metatype System_strtokIncludingDelimiters(const char* /*_string*/, const char* /*_token*/);
DLLExport
modelica_metatype omc_System_strtok(threadData_t *threadData, modelica_string _string, modelica_string _token);
#define boxptr_System_strtok omc_System_strtok
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_strtok,2,0) {(void*) boxptr_System_strtok,0}};
#define boxvar_System_strtok MMC_REFSTRUCTLIT(boxvar_lit_System_strtok)
extern modelica_metatype System_strtok(const char* /*_string*/, const char* /*_token*/);
DLLExport
modelica_string omc_System_tolower(threadData_t *threadData, modelica_string _inString);
#define boxptr_System_tolower omc_System_tolower
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_tolower,2,0) {(void*) boxptr_System_tolower,0}};
#define boxvar_System_tolower MMC_REFSTRUCTLIT(boxvar_lit_System_tolower)
extern const char* System_tolower(const char* /*_inString*/);
DLLExport
modelica_string omc_System_toupper(threadData_t *threadData, modelica_string _inString);
#define boxptr_System_toupper omc_System_toupper
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_toupper,2,0) {(void*) boxptr_System_toupper,0}};
#define boxvar_System_toupper MMC_REFSTRUCTLIT(boxvar_lit_System_toupper)
extern const char* System_toupper(const char* /*_inString*/);
DLLExport
modelica_string omc_System_makeC89Identifier(threadData_t *threadData, modelica_string _str);
#define boxptr_System_makeC89Identifier omc_System_makeC89Identifier
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_makeC89Identifier,2,0) {(void*) boxptr_System_makeC89Identifier,0}};
#define boxvar_System_makeC89Identifier MMC_REFSTRUCTLIT(boxvar_lit_System_makeC89Identifier)
extern const char* System_makeC89Identifier(const char* /*_str*/);
DLLExport
modelica_string omc_System_stringReplace(threadData_t *threadData, modelica_string _str, modelica_string _source, modelica_string _target);
#define boxptr_System_stringReplace omc_System_stringReplace
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_stringReplace,2,0) {(void*) boxptr_System_stringReplace,0}};
#define boxvar_System_stringReplace MMC_REFSTRUCTLIT(boxvar_lit_System_stringReplace)
extern const char* System_stringReplace(const char* /*_str*/, const char* /*_source*/, const char* /*_target*/);
DLLExport
modelica_integer omc_System_strncmp(threadData_t *threadData, modelica_string _inString1, modelica_string _inString2, modelica_integer _len);
DLLExport
modelica_metatype boxptr_System_strncmp(threadData_t *threadData, modelica_metatype _inString1, modelica_metatype _inString2, modelica_metatype _len);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_strncmp,2,0) {(void*) boxptr_System_strncmp,0}};
#define boxvar_System_strncmp MMC_REFSTRUCTLIT(boxvar_lit_System_strncmp)
extern int System_strncmp(const char* /*_inString1*/, const char* /*_inString2*/, int /*_len*/);
DLLExport
modelica_integer omc_System_regex(threadData_t *threadData, modelica_string _str, modelica_string _re, modelica_integer _maxMatches, modelica_boolean _extended, modelica_boolean _ignoreCase, modelica_metatype *out_strs);
DLLExport
modelica_metatype boxptr_System_regex(threadData_t *threadData, modelica_metatype _str, modelica_metatype _re, modelica_metatype _maxMatches, modelica_metatype _extended, modelica_metatype _ignoreCase, modelica_metatype *out_strs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_regex,2,0) {(void*) boxptr_System_regex,0}};
#define boxvar_System_regex MMC_REFSTRUCTLIT(boxvar_lit_System_regex)
extern modelica_metatype System_regex(const char* /*_str*/, const char* /*_re*/, int /*_maxMatches*/, int /*_extended*/, int /*_ignoreCase*/, int* /*_numMatches*/);
DLLExport
modelica_string omc_System_stringFindString(threadData_t *threadData, modelica_string _str, modelica_string _searchStr);
#define boxptr_System_stringFindString omc_System_stringFindString
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_stringFindString,2,0) {(void*) boxptr_System_stringFindString,0}};
#define boxvar_System_stringFindString MMC_REFSTRUCTLIT(boxvar_lit_System_stringFindString)
extern const char* System_stringFindString(const char* /*_str*/, const char* /*_searchStr*/);
DLLExport
modelica_integer omc_System_stringFind(threadData_t *threadData, modelica_string _str, modelica_string _searchStr);
DLLExport
modelica_metatype boxptr_System_stringFind(threadData_t *threadData, modelica_metatype _str, modelica_metatype _searchStr);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_stringFind,2,0) {(void*) boxptr_System_stringFind,0}};
#define boxvar_System_stringFind MMC_REFSTRUCTLIT(boxvar_lit_System_stringFind)
extern int System_stringFind(const char* /*_str*/, const char* /*_searchStr*/);
DLLExport
modelica_integer omc_System_strcmp__offset(threadData_t *threadData, modelica_string _string1, modelica_integer _offset1, modelica_integer _length1, modelica_string _string2, modelica_integer _offset2, modelica_integer _length2);
DLLExport
modelica_metatype boxptr_System_strcmp__offset(threadData_t *threadData, modelica_metatype _string1, modelica_metatype _offset1, modelica_metatype _length1, modelica_metatype _string2, modelica_metatype _offset2, modelica_metatype _length2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_strcmp__offset,2,0) {(void*) boxptr_System_strcmp__offset,0}};
#define boxvar_System_strcmp__offset MMC_REFSTRUCTLIT(boxvar_lit_System_strcmp__offset)
extern int System_strcmp_offset(const char* /*_string1*/, int /*_offset1*/, int /*_length1*/, const char* /*_string2*/, int /*_offset2*/, int /*_length2*/);
DLLExport
modelica_integer omc_System_strcmp(threadData_t *threadData, modelica_string _inString1, modelica_string _inString2);
DLLExport
modelica_metatype boxptr_System_strcmp(threadData_t *threadData, modelica_metatype _inString1, modelica_metatype _inString2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_strcmp,2,0) {(void*) boxptr_System_strcmp,0}};
#define boxvar_System_strcmp MMC_REFSTRUCTLIT(boxvar_lit_System_strcmp)
extern int System_strcmp(const char* /*_inString1*/, const char* /*_inString2*/);
DLLExport
modelica_string omc_System_trimChar(threadData_t *threadData, modelica_string _inString1, modelica_string _inString2);
#define boxptr_System_trimChar omc_System_trimChar
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_trimChar,2,0) {(void*) boxptr_System_trimChar,0}};
#define boxvar_System_trimChar MMC_REFSTRUCTLIT(boxvar_lit_System_trimChar)
extern const char* System_trimChar(const char* /*_inString1*/, const char* /*_inString2*/);
DLLExport
modelica_string omc_System_trimWhitespace(threadData_t *threadData, modelica_string _inString);
#define boxptr_System_trimWhitespace omc_System_trimWhitespace
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_trimWhitespace,2,0) {(void*) boxptr_System_trimWhitespace,0}};
#define boxvar_System_trimWhitespace MMC_REFSTRUCTLIT(boxvar_lit_System_trimWhitespace)
DLLExport
modelica_string omc_System_trim(threadData_t *threadData, modelica_string _inString, modelica_string _charsToRemove);
#define boxptr_System_trim omc_System_trim
static const MMC_DEFSTRUCTLIT(boxvar_lit_System_trim,2,0) {(void*) boxptr_System_trim,0}};
#define boxvar_System_trim MMC_REFSTRUCTLIT(boxvar_lit_System_trim)
extern const char* System_trim(const char* /*_inString*/, const char* /*_charsToRemove*/);
#ifdef __cplusplus
}
#endif
#endif
