#ifndef Parser__H
#define Parser__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description Flags_ConfigFlag_CONFIG__FLAG__desc;
extern struct record_description Flags_FlagData_ENUM__FLAG__desc;
extern struct record_description Flags_FlagVisibility_EXTERNAL__desc;
extern struct record_description Flags_ValidOptions_STRING__OPTION__desc;
extern struct record_description Gettext_TranslatableContent_gettext__desc;
extern struct record_description Parser_ParserResult_PARSERRESULT__desc;
#define boxptr_Parser_loadFileThread omc_Parser_loadFileThread
DLLExport
void omc_Parser_stopLibraryVendorExecutable(threadData_t *threadData, modelica_metatype _lveInstance);
#define boxptr_Parser_stopLibraryVendorExecutable omc_Parser_stopLibraryVendorExecutable
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_stopLibraryVendorExecutable,2,0) {(void*) boxptr_Parser_stopLibraryVendorExecutable,0}};
#define boxvar_Parser_stopLibraryVendorExecutable MMC_REFSTRUCTLIT(boxvar_lit_Parser_stopLibraryVendorExecutable)
DLLExport
void omc_Parser_checkLVEToolFeature(threadData_t *threadData, modelica_metatype _lveInstance, modelica_string _feature);
#define boxptr_Parser_checkLVEToolFeature omc_Parser_checkLVEToolFeature
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_checkLVEToolFeature,2,0) {(void*) boxptr_Parser_checkLVEToolFeature,0}};
#define boxvar_Parser_checkLVEToolFeature MMC_REFSTRUCTLIT(boxvar_lit_Parser_checkLVEToolFeature)
DLLExport
modelica_boolean omc_Parser_checkLVEToolLicense(threadData_t *threadData, modelica_metatype _lveInstance, modelica_string _packageName);
DLLExport
modelica_metatype boxptr_Parser_checkLVEToolLicense(threadData_t *threadData, modelica_metatype _lveInstance, modelica_metatype _packageName);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_checkLVEToolLicense,2,0) {(void*) boxptr_Parser_checkLVEToolLicense,0}};
#define boxvar_Parser_checkLVEToolLicense MMC_REFSTRUCTLIT(boxvar_lit_Parser_checkLVEToolLicense)
DLLExport
modelica_boolean omc_Parser_startLibraryVendorExecutable(threadData_t *threadData, modelica_string _lvePath, modelica_metatype *out_lveInstance);
DLLExport
modelica_metatype boxptr_Parser_startLibraryVendorExecutable(threadData_t *threadData, modelica_metatype _lvePath, modelica_metatype *out_lveInstance);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_startLibraryVendorExecutable,2,0) {(void*) boxptr_Parser_startLibraryVendorExecutable,0}};
#define boxvar_Parser_startLibraryVendorExecutable MMC_REFSTRUCTLIT(boxvar_lit_Parser_startLibraryVendorExecutable)
DLLExport
modelica_metatype omc_Parser_parallelParseFilesToProgramList(threadData_t *threadData, modelica_metatype _filenames, modelica_string _encoding, modelica_integer _numThreads);
DLLExport
modelica_metatype boxptr_Parser_parallelParseFilesToProgramList(threadData_t *threadData, modelica_metatype _filenames, modelica_metatype _encoding, modelica_metatype _numThreads);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_parallelParseFilesToProgramList,2,0) {(void*) boxptr_Parser_parallelParseFilesToProgramList,0}};
#define boxvar_Parser_parallelParseFilesToProgramList MMC_REFSTRUCTLIT(boxvar_lit_Parser_parallelParseFilesToProgramList)
DLLExport
modelica_metatype omc_Parser_parallelParseFiles(threadData_t *threadData, modelica_metatype _filenames, modelica_string _encoding, modelica_integer _numThreads, modelica_string _libraryPath, modelica_metatype _lveInstance);
DLLExport
modelica_metatype boxptr_Parser_parallelParseFiles(threadData_t *threadData, modelica_metatype _filenames, modelica_metatype _encoding, modelica_metatype _numThreads, modelica_metatype _libraryPath, modelica_metatype _lveInstance);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_parallelParseFiles,2,0) {(void*) boxptr_Parser_parallelParseFiles,0}};
#define boxvar_Parser_parallelParseFiles MMC_REFSTRUCTLIT(boxvar_lit_Parser_parallelParseFiles)
DLLExport
modelica_metatype omc_Parser_stringCref(threadData_t *threadData, modelica_string _str);
#define boxptr_Parser_stringCref omc_Parser_stringCref
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_stringCref,2,0) {(void*) boxptr_Parser_stringCref,0}};
#define boxvar_Parser_stringCref MMC_REFSTRUCTLIT(boxvar_lit_Parser_stringCref)
DLLExport
modelica_metatype omc_Parser_stringPath(threadData_t *threadData, modelica_string _str);
#define boxptr_Parser_stringPath omc_Parser_stringPath
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_stringPath,2,0) {(void*) boxptr_Parser_stringPath,0}};
#define boxvar_Parser_stringPath MMC_REFSTRUCTLIT(boxvar_lit_Parser_stringPath)
DLLExport
modelica_metatype omc_Parser_parsestringexp(threadData_t *threadData, modelica_string _str, modelica_string _infoFilename);
#define boxptr_Parser_parsestringexp omc_Parser_parsestringexp
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_parsestringexp,2,0) {(void*) boxptr_Parser_parsestringexp,0}};
#define boxvar_Parser_parsestringexp MMC_REFSTRUCTLIT(boxvar_lit_Parser_parsestringexp)
DLLExport
modelica_metatype omc_Parser_parsebuiltin(threadData_t *threadData, modelica_string _filename, modelica_string _encoding, modelica_string _libraryPath, modelica_metatype _lveInstance, modelica_integer _acceptedGram, modelica_integer _languageStandardInt);
DLLExport
modelica_metatype boxptr_Parser_parsebuiltin(threadData_t *threadData, modelica_metatype _filename, modelica_metatype _encoding, modelica_metatype _libraryPath, modelica_metatype _lveInstance, modelica_metatype _acceptedGram, modelica_metatype _languageStandardInt);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_parsebuiltin,2,0) {(void*) boxptr_Parser_parsebuiltin,0}};
#define boxvar_Parser_parsebuiltin MMC_REFSTRUCTLIT(boxvar_lit_Parser_parsebuiltin)
DLLExport
modelica_metatype omc_Parser_parsestring(threadData_t *threadData, modelica_string _str, modelica_string _infoFilename);
#define boxptr_Parser_parsestring omc_Parser_parsestring
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_parsestring,2,0) {(void*) boxptr_Parser_parsestring,0}};
#define boxvar_Parser_parsestring MMC_REFSTRUCTLIT(boxvar_lit_Parser_parsestring)
DLLExport
modelica_metatype omc_Parser_parseexp(threadData_t *threadData, modelica_string _filename);
#define boxptr_Parser_parseexp omc_Parser_parseexp
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_parseexp,2,0) {(void*) boxptr_Parser_parseexp,0}};
#define boxvar_Parser_parseexp MMC_REFSTRUCTLIT(boxvar_lit_Parser_parseexp)
DLLExport
modelica_metatype omc_Parser_parse(threadData_t *threadData, modelica_string _filename, modelica_string _encoding, modelica_string _libraryPath, modelica_metatype _lveInstance);
#define boxptr_Parser_parse omc_Parser_parse
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_parse,2,0) {(void*) boxptr_Parser_parse,0}};
#define boxvar_Parser_parse MMC_REFSTRUCTLIT(boxvar_lit_Parser_parse)
#ifdef __cplusplus
}
#endif
#endif
