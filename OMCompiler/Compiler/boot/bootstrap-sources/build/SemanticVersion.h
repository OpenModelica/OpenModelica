#ifndef SemanticVersion__H
#define SemanticVersion__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description SemanticVersion_Version_NONSEMVER__desc;
extern struct record_description SemanticVersion_Version_SEMVER__desc;
DLLExport
modelica_boolean omc_SemanticVersion_isSemVer(threadData_t *threadData, modelica_metatype _v);
DLLExport
modelica_metatype boxptr_SemanticVersion_isSemVer(threadData_t *threadData, modelica_metatype _v);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SemanticVersion_isSemVer,2,0) {(void*) boxptr_SemanticVersion_isSemVer,0}};
#define boxvar_SemanticVersion_isSemVer MMC_REFSTRUCTLIT(boxvar_lit_SemanticVersion_isSemVer)
DLLExport
modelica_boolean omc_SemanticVersion_hasMetaInformation(threadData_t *threadData, modelica_metatype _v);
DLLExport
modelica_metatype boxptr_SemanticVersion_hasMetaInformation(threadData_t *threadData, modelica_metatype _v);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SemanticVersion_hasMetaInformation,2,0) {(void*) boxptr_SemanticVersion_hasMetaInformation,0}};
#define boxvar_SemanticVersion_hasMetaInformation MMC_REFSTRUCTLIT(boxvar_lit_SemanticVersion_hasMetaInformation)
DLLExport
modelica_boolean omc_SemanticVersion_isPrerelease(threadData_t *threadData, modelica_metatype _v);
DLLExport
modelica_metatype boxptr_SemanticVersion_isPrerelease(threadData_t *threadData, modelica_metatype _v);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SemanticVersion_isPrerelease,2,0) {(void*) boxptr_SemanticVersion_isPrerelease,0}};
#define boxvar_SemanticVersion_isPrerelease MMC_REFSTRUCTLIT(boxvar_lit_SemanticVersion_isPrerelease)
DLLExport
modelica_string omc_SemanticVersion_toString(threadData_t *threadData, modelica_metatype _v);
#define boxptr_SemanticVersion_toString omc_SemanticVersion_toString
static const MMC_DEFSTRUCTLIT(boxvar_lit_SemanticVersion_toString,2,0) {(void*) boxptr_SemanticVersion_toString,0}};
#define boxvar_SemanticVersion_toString MMC_REFSTRUCTLIT(boxvar_lit_SemanticVersion_toString)
DLLExport
modelica_integer omc_SemanticVersion_compare(threadData_t *threadData, modelica_metatype _v1, modelica_metatype _v2, modelica_boolean _comparePrerelease, modelica_boolean _compareBuildInformation);
DLLExport
modelica_metatype boxptr_SemanticVersion_compare(threadData_t *threadData, modelica_metatype _v1, modelica_metatype _v2, modelica_metatype _comparePrerelease, modelica_metatype _compareBuildInformation);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SemanticVersion_compare,2,0) {(void*) boxptr_SemanticVersion_compare,0}};
#define boxvar_SemanticVersion_compare MMC_REFSTRUCTLIT(boxvar_lit_SemanticVersion_compare)
DLLExport
modelica_metatype omc_SemanticVersion_parse(threadData_t *threadData, modelica_string _s);
#define boxptr_SemanticVersion_parse omc_SemanticVersion_parse
static const MMC_DEFSTRUCTLIT(boxvar_lit_SemanticVersion_parse,2,0) {(void*) boxptr_SemanticVersion_parse,0}};
#define boxvar_SemanticVersion_parse MMC_REFSTRUCTLIT(boxvar_lit_SemanticVersion_parse)
#ifdef __cplusplus
}
#endif
#endif
