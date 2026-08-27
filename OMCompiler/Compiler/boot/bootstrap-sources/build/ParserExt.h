#ifndef ParserExt__H
#define ParserExt__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
void omc_ParserExt_stopLibraryVendorExecutable(threadData_t *threadData, modelica_metatype _lveInstance);
#define boxptr_ParserExt_stopLibraryVendorExecutable omc_ParserExt_stopLibraryVendorExecutable
static const MMC_DEFSTRUCTLIT(boxvar_lit_ParserExt_stopLibraryVendorExecutable,2,0) {(void*) boxptr_ParserExt_stopLibraryVendorExecutable,0}};
#define boxvar_ParserExt_stopLibraryVendorExecutable MMC_REFSTRUCTLIT(boxvar_lit_ParserExt_stopLibraryVendorExecutable)
extern void ParserExt_stopLibraryVendorExecutable(modelica_metatype /*_lveInstance*/);
DLLExport
void omc_ParserExt_checkLVEToolFeature(threadData_t *threadData, modelica_metatype _lveInstance, modelica_string _feature);
#define boxptr_ParserExt_checkLVEToolFeature omc_ParserExt_checkLVEToolFeature
static const MMC_DEFSTRUCTLIT(boxvar_lit_ParserExt_checkLVEToolFeature,2,0) {(void*) boxptr_ParserExt_checkLVEToolFeature,0}};
#define boxvar_ParserExt_checkLVEToolFeature MMC_REFSTRUCTLIT(boxvar_lit_ParserExt_checkLVEToolFeature)
extern void ParserExt_checkLVEToolFeature(modelica_metatype /*_lveInstance*/, const char* /*_feature*/);
DLLExport
modelica_boolean omc_ParserExt_checkLVEToolLicense(threadData_t *threadData, modelica_metatype _lveInstance, modelica_string _packageName);
DLLExport
modelica_metatype boxptr_ParserExt_checkLVEToolLicense(threadData_t *threadData, modelica_metatype _lveInstance, modelica_metatype _packageName);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ParserExt_checkLVEToolLicense,2,0) {(void*) boxptr_ParserExt_checkLVEToolLicense,0}};
#define boxvar_ParserExt_checkLVEToolLicense MMC_REFSTRUCTLIT(boxvar_lit_ParserExt_checkLVEToolLicense)
extern int ParserExt_checkLVEToolLicense(modelica_metatype /*_lveInstance*/, const char* /*_packageName*/);
DLLExport
modelica_boolean omc_ParserExt_startLibraryVendorExecutable(threadData_t *threadData, modelica_string _lvePath, modelica_metatype *out_lveInstance);
DLLExport
modelica_metatype boxptr_ParserExt_startLibraryVendorExecutable(threadData_t *threadData, modelica_metatype _lvePath, modelica_metatype *out_lveInstance);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ParserExt_startLibraryVendorExecutable,2,0) {(void*) boxptr_ParserExt_startLibraryVendorExecutable,0}};
#define boxvar_ParserExt_startLibraryVendorExecutable MMC_REFSTRUCTLIT(boxvar_lit_ParserExt_startLibraryVendorExecutable)
extern int ParserExt_startLibraryVendorExecutable(const char* /*_lvePath*/, modelica_metatype* /*_lveInstance*/);
DLLExport
modelica_metatype omc_ParserExt_stringCref(threadData_t *threadData, modelica_string _str, modelica_string _infoFilename, modelica_integer _acceptedGram, modelica_integer _languageStandardInt, modelica_boolean _runningTestsuite);
DLLExport
modelica_metatype boxptr_ParserExt_stringCref(threadData_t *threadData, modelica_metatype _str, modelica_metatype _infoFilename, modelica_metatype _acceptedGram, modelica_metatype _languageStandardInt, modelica_metatype _runningTestsuite);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ParserExt_stringCref,2,0) {(void*) boxptr_ParserExt_stringCref,0}};
#define boxvar_ParserExt_stringCref MMC_REFSTRUCTLIT(boxvar_lit_ParserExt_stringCref)
extern modelica_metatype ParserExt_stringCref(const char* /*_str*/, const char* /*_infoFilename*/, int /*_acceptedGram*/, int /*_languageStandardInt*/, int /*_runningTestsuite*/);
DLLExport
modelica_metatype omc_ParserExt_stringPath(threadData_t *threadData, modelica_string _str, modelica_string _infoFilename, modelica_integer _acceptedGram, modelica_integer _languageStandardInt, modelica_boolean _runningTestsuite);
DLLExport
modelica_metatype boxptr_ParserExt_stringPath(threadData_t *threadData, modelica_metatype _str, modelica_metatype _infoFilename, modelica_metatype _acceptedGram, modelica_metatype _languageStandardInt, modelica_metatype _runningTestsuite);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ParserExt_stringPath,2,0) {(void*) boxptr_ParserExt_stringPath,0}};
#define boxvar_ParserExt_stringPath MMC_REFSTRUCTLIT(boxvar_lit_ParserExt_stringPath)
extern modelica_metatype ParserExt_stringPath(const char* /*_str*/, const char* /*_infoFilename*/, int /*_acceptedGram*/, int /*_languageStandardInt*/, int /*_runningTestsuite*/);
DLLExport
modelica_metatype omc_ParserExt_parsestringexp(threadData_t *threadData, modelica_string _str, modelica_string _infoFilename, modelica_integer _acceptedGram, modelica_integer _languageStandardInt, modelica_boolean _runningTestsuite);
DLLExport
modelica_metatype boxptr_ParserExt_parsestringexp(threadData_t *threadData, modelica_metatype _str, modelica_metatype _infoFilename, modelica_metatype _acceptedGram, modelica_metatype _languageStandardInt, modelica_metatype _runningTestsuite);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ParserExt_parsestringexp,2,0) {(void*) boxptr_ParserExt_parsestringexp,0}};
#define boxvar_ParserExt_parsestringexp MMC_REFSTRUCTLIT(boxvar_lit_ParserExt_parsestringexp)
extern modelica_metatype ParserExt_parsestringexp(const char* /*_str*/, const char* /*_infoFilename*/, int /*_acceptedGram*/, int /*_languageStandardInt*/, int /*_runningTestsuite*/);
DLLExport
modelica_metatype omc_ParserExt_parsestring(threadData_t *threadData, modelica_string _str, modelica_string _infoFilename, modelica_integer _acceptedGram, modelica_integer _languageStandardInt, modelica_boolean _runningTestsuite);
DLLExport
modelica_metatype boxptr_ParserExt_parsestring(threadData_t *threadData, modelica_metatype _str, modelica_metatype _infoFilename, modelica_metatype _acceptedGram, modelica_metatype _languageStandardInt, modelica_metatype _runningTestsuite);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ParserExt_parsestring,2,0) {(void*) boxptr_ParserExt_parsestring,0}};
#define boxvar_ParserExt_parsestring MMC_REFSTRUCTLIT(boxvar_lit_ParserExt_parsestring)
extern modelica_metatype ParserExt_parsestring(const char* /*_str*/, const char* /*_infoFilename*/, int /*_acceptedGram*/, int /*_languageStandardInt*/, int /*strict*/, int /*_runningTestsuite*/);
DLLExport
modelica_metatype omc_ParserExt_parseexp(threadData_t *threadData, modelica_string _filename, modelica_string _infoFilename, modelica_integer _acceptedGram, modelica_integer _languageStandardInt, modelica_boolean _runningTestsuite);
DLLExport
modelica_metatype boxptr_ParserExt_parseexp(threadData_t *threadData, modelica_metatype _filename, modelica_metatype _infoFilename, modelica_metatype _acceptedGram, modelica_metatype _languageStandardInt, modelica_metatype _runningTestsuite);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ParserExt_parseexp,2,0) {(void*) boxptr_ParserExt_parseexp,0}};
#define boxvar_ParserExt_parseexp MMC_REFSTRUCTLIT(boxvar_lit_ParserExt_parseexp)
extern modelica_metatype ParserExt_parseexp(const char* /*_filename*/, const char* /*_infoFilename*/, int /*_acceptedGram*/, int /*_languageStandardInt*/, int /*_runningTestsuite*/);
DLLExport
modelica_metatype omc_ParserExt_parse(threadData_t *threadData, modelica_string _filename, modelica_string _infoFilename, modelica_integer _acceptedGram, modelica_string _encoding, modelica_integer _languageStandardInt, modelica_boolean _runningTestsuite, modelica_string _libraryPath, modelica_metatype _lveInstance);
DLLExport
modelica_metatype boxptr_ParserExt_parse(threadData_t *threadData, modelica_metatype _filename, modelica_metatype _infoFilename, modelica_metatype _acceptedGram, modelica_metatype _encoding, modelica_metatype _languageStandardInt, modelica_metatype _runningTestsuite, modelica_metatype _libraryPath, modelica_metatype _lveInstance);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ParserExt_parse,2,0) {(void*) boxptr_ParserExt_parse,0}};
#define boxvar_ParserExt_parse MMC_REFSTRUCTLIT(boxvar_lit_ParserExt_parse)
extern modelica_metatype ParserExt_parse(const char* /*_filename*/, const char* /*_infoFilename*/, int /*_acceptedGram*/, int /*_languageStandardInt*/, int /*strict*/, const char* /*_encoding*/, int /*_runningTestsuite*/, const char* /*_libraryPath*/, modelica_metatype /*_lveInstance*/);
#ifdef __cplusplus
}
#endif
#endif
