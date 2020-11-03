#ifndef Config__H
#define Config__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description ErrorTypes_Message_MESSAGE__desc;
extern struct record_description ErrorTypes_MessageType_SCRIPTING__desc;
extern struct record_description ErrorTypes_Severity_NOTIFICATION__desc;
extern struct record_description ErrorTypes_Severity_WARNING__desc;
extern struct record_description Flags_ConfigFlag_CONFIG__FLAG__desc;
extern struct record_description Flags_DebugFlag_DEBUG__FLAG__desc;
extern struct record_description Flags_FlagData_BOOL__FLAG__desc;
extern struct record_description Flags_FlagData_ENUM__FLAG__desc;
extern struct record_description Flags_FlagData_INT__FLAG__desc;
extern struct record_description Flags_FlagData_STRING__FLAG__desc;
extern struct record_description Flags_FlagData_STRING__LIST__FLAG__desc;
extern struct record_description Flags_FlagVisibility_EXTERNAL__desc;
extern struct record_description Flags_FlagVisibility_INTERNAL__desc;
extern struct record_description Flags_ValidOptions_STRING__DESC__OPTION__desc;
extern struct record_description Flags_ValidOptions_STRING__OPTION__desc;
extern struct record_description Gettext_TranslatableContent_gettext__desc;
extern struct record_description Gettext_TranslatableContent_notrans__desc;
DLLExport
modelica_boolean omc_Config_flatModelica(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_flatModelica(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_flatModelica,2,0) {(void*) boxptr_Config_flatModelica,0}};
#define boxvar_Config_flatModelica MMC_REFSTRUCTLIT(boxvar_lit_Config_flatModelica)
DLLExport
modelica_boolean omc_Config_synchronousFeaturesAllowed(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_synchronousFeaturesAllowed(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_synchronousFeaturesAllowed,2,0) {(void*) boxptr_Config_synchronousFeaturesAllowed,0}};
#define boxvar_Config_synchronousFeaturesAllowed MMC_REFSTRUCTLIT(boxvar_lit_Config_synchronousFeaturesAllowed)
DLLExport
modelica_boolean omc_Config_adaptiveHomotopy(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_adaptiveHomotopy(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_adaptiveHomotopy,2,0) {(void*) boxptr_Config_adaptiveHomotopy,0}};
#define boxvar_Config_adaptiveHomotopy MMC_REFSTRUCTLIT(boxvar_lit_Config_adaptiveHomotopy)
DLLExport
modelica_boolean omc_Config_globalHomotopy(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_globalHomotopy(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_globalHomotopy,2,0) {(void*) boxptr_Config_globalHomotopy,0}};
#define boxvar_Config_globalHomotopy MMC_REFSTRUCTLIT(boxvar_lit_Config_globalHomotopy)
DLLExport
modelica_boolean omc_Config_ignoreCommandLineOptionsAnnotation(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_ignoreCommandLineOptionsAnnotation(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_ignoreCommandLineOptionsAnnotation,2,0) {(void*) boxptr_Config_ignoreCommandLineOptionsAnnotation,0}};
#define boxvar_Config_ignoreCommandLineOptionsAnnotation MMC_REFSTRUCTLIT(boxvar_lit_Config_ignoreCommandLineOptionsAnnotation)
DLLExport
modelica_string omc_Config_dynamicTearing(threadData_t *threadData);
#define boxptr_Config_dynamicTearing omc_Config_dynamicTearing
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_dynamicTearing,2,0) {(void*) boxptr_Config_dynamicTearing,0}};
#define boxvar_Config_dynamicTearing MMC_REFSTRUCTLIT(boxvar_lit_Config_dynamicTearing)
DLLExport
modelica_boolean omc_Config_profileFunctions(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_profileFunctions(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_profileFunctions,2,0) {(void*) boxptr_Config_profileFunctions,0}};
#define boxvar_Config_profileFunctions MMC_REFSTRUCTLIT(boxvar_lit_Config_profileFunctions)
DLLExport
modelica_boolean omc_Config_profileHtml(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_profileHtml(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_profileHtml,2,0) {(void*) boxptr_Config_profileHtml,0}};
#define boxvar_Config_profileHtml MMC_REFSTRUCTLIT(boxvar_lit_Config_profileHtml)
DLLExport
modelica_boolean omc_Config_profileAll(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_profileAll(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_profileAll,2,0) {(void*) boxptr_Config_profileAll,0}};
#define boxvar_Config_profileAll MMC_REFSTRUCTLIT(boxvar_lit_Config_profileAll)
DLLExport
modelica_boolean omc_Config_profileSome(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_profileSome(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_profileSome,2,0) {(void*) boxptr_Config_profileSome,0}};
#define boxvar_Config_profileSome MMC_REFSTRUCTLIT(boxvar_lit_Config_profileSome)
DLLExport
modelica_boolean omc_Config_intEnumConversion(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_intEnumConversion(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_intEnumConversion,2,0) {(void*) boxptr_Config_intEnumConversion,0}};
#define boxvar_Config_intEnumConversion MMC_REFSTRUCTLIT(boxvar_lit_Config_intEnumConversion)
DLLExport
modelica_boolean omc_Config_scalarizeBindings(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_scalarizeBindings(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_scalarizeBindings,2,0) {(void*) boxptr_Config_scalarizeBindings,0}};
#define boxvar_Config_scalarizeBindings MMC_REFSTRUCTLIT(boxvar_lit_Config_scalarizeBindings)
DLLExport
modelica_boolean omc_Config_scalarizeMinMax(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_scalarizeMinMax(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_scalarizeMinMax,2,0) {(void*) boxptr_Config_scalarizeMinMax,0}};
#define boxvar_Config_scalarizeMinMax MMC_REFSTRUCTLIT(boxvar_lit_Config_scalarizeMinMax)
DLLExport
modelica_boolean omc_Config_showErrorMessages(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_showErrorMessages(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_showErrorMessages,2,0) {(void*) boxptr_Config_showErrorMessages,0}};
#define boxvar_Config_showErrorMessages MMC_REFSTRUCTLIT(boxvar_lit_Config_showErrorMessages)
DLLExport
modelica_integer omc_Config_versionStringToStd(threadData_t *threadData, modelica_string _inVersion);
DLLExport
modelica_metatype boxptr_Config_versionStringToStd(threadData_t *threadData, modelica_metatype _inVersion);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_versionStringToStd,2,0) {(void*) boxptr_Config_versionStringToStd,0}};
#define boxvar_Config_versionStringToStd MMC_REFSTRUCTLIT(boxvar_lit_Config_versionStringToStd)
DLLExport
void omc_Config_setLanguageStandardFromMSL(threadData_t *threadData, modelica_string _inLibraryName);
#define boxptr_Config_setLanguageStandardFromMSL omc_Config_setLanguageStandardFromMSL
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_setLanguageStandardFromMSL,2,0) {(void*) boxptr_Config_setLanguageStandardFromMSL,0}};
#define boxvar_Config_setLanguageStandardFromMSL MMC_REFSTRUCTLIT(boxvar_lit_Config_setLanguageStandardFromMSL)
DLLExport
modelica_string omc_Config_languageStandardString(threadData_t *threadData, modelica_integer _inStandard);
DLLExport
modelica_metatype boxptr_Config_languageStandardString(threadData_t *threadData, modelica_metatype _inStandard);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_languageStandardString,2,0) {(void*) boxptr_Config_languageStandardString,0}};
#define boxvar_Config_languageStandardString MMC_REFSTRUCTLIT(boxvar_lit_Config_languageStandardString)
DLLExport
modelica_boolean omc_Config_languageStandardAtMost(threadData_t *threadData, modelica_integer _inStandard);
DLLExport
modelica_metatype boxptr_Config_languageStandardAtMost(threadData_t *threadData, modelica_metatype _inStandard);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_languageStandardAtMost,2,0) {(void*) boxptr_Config_languageStandardAtMost,0}};
#define boxvar_Config_languageStandardAtMost MMC_REFSTRUCTLIT(boxvar_lit_Config_languageStandardAtMost)
DLLExport
modelica_boolean omc_Config_languageStandardAtLeast(threadData_t *threadData, modelica_integer _inStandard);
DLLExport
modelica_metatype boxptr_Config_languageStandardAtLeast(threadData_t *threadData, modelica_metatype _inStandard);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_languageStandardAtLeast,2,0) {(void*) boxptr_Config_languageStandardAtLeast,0}};
#define boxvar_Config_languageStandardAtLeast MMC_REFSTRUCTLIT(boxvar_lit_Config_languageStandardAtLeast)
DLLExport
void omc_Config_setLanguageStandard(threadData_t *threadData, modelica_integer _inStandard);
DLLExport
void boxptr_Config_setLanguageStandard(threadData_t *threadData, modelica_metatype _inStandard);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_setLanguageStandard,2,0) {(void*) boxptr_Config_setLanguageStandard,0}};
#define boxvar_Config_setLanguageStandard MMC_REFSTRUCTLIT(boxvar_lit_Config_setLanguageStandard)
DLLExport
modelica_integer omc_Config_getLanguageStandard(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_getLanguageStandard(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_getLanguageStandard,2,0) {(void*) boxptr_Config_getLanguageStandard,0}};
#define boxvar_Config_getLanguageStandard MMC_REFSTRUCTLIT(boxvar_lit_Config_getLanguageStandard)
DLLExport
void omc_Config_setsimCodeTarget(threadData_t *threadData, modelica_string _inString);
#define boxptr_Config_setsimCodeTarget omc_Config_setsimCodeTarget
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_setsimCodeTarget,2,0) {(void*) boxptr_Config_setsimCodeTarget,0}};
#define boxvar_Config_setsimCodeTarget MMC_REFSTRUCTLIT(boxvar_lit_Config_setsimCodeTarget)
DLLExport
modelica_string omc_Config_simCodeTarget(threadData_t *threadData);
#define boxptr_Config_simCodeTarget omc_Config_simCodeTarget
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_simCodeTarget,2,0) {(void*) boxptr_Config_simCodeTarget,0}};
#define boxvar_Config_simCodeTarget MMC_REFSTRUCTLIT(boxvar_lit_Config_simCodeTarget)
DLLExport
void omc_Config_setTearingHeuristic(threadData_t *threadData, modelica_string _inString);
#define boxptr_Config_setTearingHeuristic omc_Config_setTearingHeuristic
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_setTearingHeuristic,2,0) {(void*) boxptr_Config_setTearingHeuristic,0}};
#define boxvar_Config_setTearingHeuristic MMC_REFSTRUCTLIT(boxvar_lit_Config_setTearingHeuristic)
DLLExport
modelica_string omc_Config_getTearingHeuristic(threadData_t *threadData);
#define boxptr_Config_getTearingHeuristic omc_Config_getTearingHeuristic
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_getTearingHeuristic,2,0) {(void*) boxptr_Config_getTearingHeuristic,0}};
#define boxvar_Config_getTearingHeuristic MMC_REFSTRUCTLIT(boxvar_lit_Config_getTearingHeuristic)
DLLExport
void omc_Config_setTearingMethod(threadData_t *threadData, modelica_string _inString);
#define boxptr_Config_setTearingMethod omc_Config_setTearingMethod
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_setTearingMethod,2,0) {(void*) boxptr_Config_setTearingMethod,0}};
#define boxvar_Config_setTearingMethod MMC_REFSTRUCTLIT(boxvar_lit_Config_setTearingMethod)
DLLExport
modelica_string omc_Config_getTearingMethod(threadData_t *threadData);
#define boxptr_Config_getTearingMethod omc_Config_getTearingMethod
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_getTearingMethod,2,0) {(void*) boxptr_Config_getTearingMethod,0}};
#define boxvar_Config_getTearingMethod MMC_REFSTRUCTLIT(boxvar_lit_Config_getTearingMethod)
DLLExport
void omc_Config_setMatchingAlgorithm(threadData_t *threadData, modelica_string _inString);
#define boxptr_Config_setMatchingAlgorithm omc_Config_setMatchingAlgorithm
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_setMatchingAlgorithm,2,0) {(void*) boxptr_Config_setMatchingAlgorithm,0}};
#define boxvar_Config_setMatchingAlgorithm MMC_REFSTRUCTLIT(boxvar_lit_Config_setMatchingAlgorithm)
DLLExport
modelica_string omc_Config_getMatchingAlgorithm(threadData_t *threadData);
#define boxptr_Config_getMatchingAlgorithm omc_Config_getMatchingAlgorithm
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_getMatchingAlgorithm,2,0) {(void*) boxptr_Config_getMatchingAlgorithm,0}};
#define boxvar_Config_getMatchingAlgorithm MMC_REFSTRUCTLIT(boxvar_lit_Config_getMatchingAlgorithm)
DLLExport
void omc_Config_setCheapMatchingAlgorithm(threadData_t *threadData, modelica_integer _inInteger);
DLLExport
void boxptr_Config_setCheapMatchingAlgorithm(threadData_t *threadData, modelica_metatype _inInteger);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_setCheapMatchingAlgorithm,2,0) {(void*) boxptr_Config_setCheapMatchingAlgorithm,0}};
#define boxvar_Config_setCheapMatchingAlgorithm MMC_REFSTRUCTLIT(boxvar_lit_Config_setCheapMatchingAlgorithm)
DLLExport
modelica_integer omc_Config_getCheapMatchingAlgorithm(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_getCheapMatchingAlgorithm(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_getCheapMatchingAlgorithm,2,0) {(void*) boxptr_Config_getCheapMatchingAlgorithm,0}};
#define boxvar_Config_getCheapMatchingAlgorithm MMC_REFSTRUCTLIT(boxvar_lit_Config_getCheapMatchingAlgorithm)
DLLExport
void omc_Config_setIndexReductionMethod(threadData_t *threadData, modelica_string _inString);
#define boxptr_Config_setIndexReductionMethod omc_Config_setIndexReductionMethod
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_setIndexReductionMethod,2,0) {(void*) boxptr_Config_setIndexReductionMethod,0}};
#define boxvar_Config_setIndexReductionMethod MMC_REFSTRUCTLIT(boxvar_lit_Config_setIndexReductionMethod)
DLLExport
modelica_string omc_Config_getIndexReductionMethod(threadData_t *threadData);
#define boxptr_Config_getIndexReductionMethod omc_Config_getIndexReductionMethod
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_getIndexReductionMethod,2,0) {(void*) boxptr_Config_getIndexReductionMethod,0}};
#define boxvar_Config_getIndexReductionMethod MMC_REFSTRUCTLIT(boxvar_lit_Config_getIndexReductionMethod)
DLLExport
void omc_Config_setPostOptModules(threadData_t *threadData, modelica_metatype _inStringLst);
#define boxptr_Config_setPostOptModules omc_Config_setPostOptModules
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_setPostOptModules,2,0) {(void*) boxptr_Config_setPostOptModules,0}};
#define boxvar_Config_setPostOptModules MMC_REFSTRUCTLIT(boxvar_lit_Config_setPostOptModules)
DLLExport
void omc_Config_setPreOptModules(threadData_t *threadData, modelica_metatype _inStringLst);
#define boxptr_Config_setPreOptModules omc_Config_setPreOptModules
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_setPreOptModules,2,0) {(void*) boxptr_Config_setPreOptModules,0}};
#define boxvar_Config_setPreOptModules MMC_REFSTRUCTLIT(boxvar_lit_Config_setPreOptModules)
DLLExport
modelica_metatype omc_Config_getInitOptModules(threadData_t *threadData);
#define boxptr_Config_getInitOptModules omc_Config_getInitOptModules
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_getInitOptModules,2,0) {(void*) boxptr_Config_getInitOptModules,0}};
#define boxvar_Config_getInitOptModules MMC_REFSTRUCTLIT(boxvar_lit_Config_getInitOptModules)
DLLExport
modelica_metatype omc_Config_getPostOptModulesDAE(threadData_t *threadData);
#define boxptr_Config_getPostOptModulesDAE omc_Config_getPostOptModulesDAE
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_getPostOptModulesDAE,2,0) {(void*) boxptr_Config_getPostOptModulesDAE,0}};
#define boxvar_Config_getPostOptModulesDAE MMC_REFSTRUCTLIT(boxvar_lit_Config_getPostOptModulesDAE)
DLLExport
modelica_metatype omc_Config_getPostOptModules(threadData_t *threadData);
#define boxptr_Config_getPostOptModules omc_Config_getPostOptModules
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_getPostOptModules,2,0) {(void*) boxptr_Config_getPostOptModules,0}};
#define boxvar_Config_getPostOptModules MMC_REFSTRUCTLIT(boxvar_lit_Config_getPostOptModules)
DLLExport
modelica_metatype omc_Config_getPreOptModules(threadData_t *threadData);
#define boxptr_Config_getPreOptModules omc_Config_getPreOptModules
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_getPreOptModules,2,0) {(void*) boxptr_Config_getPreOptModules,0}};
#define boxvar_Config_getPreOptModules MMC_REFSTRUCTLIT(boxvar_lit_Config_getPreOptModules)
DLLExport
void omc_Config_setOrderConnections(threadData_t *threadData, modelica_boolean _show);
DLLExport
void boxptr_Config_setOrderConnections(threadData_t *threadData, modelica_metatype _show);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_setOrderConnections,2,0) {(void*) boxptr_Config_setOrderConnections,0}};
#define boxvar_Config_setOrderConnections MMC_REFSTRUCTLIT(boxvar_lit_Config_setOrderConnections)
DLLExport
modelica_boolean omc_Config_orderConnections(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_orderConnections(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_orderConnections,2,0) {(void*) boxptr_Config_orderConnections,0}};
#define boxvar_Config_orderConnections MMC_REFSTRUCTLIT(boxvar_lit_Config_orderConnections)
DLLExport
void omc_Config_setGraphicsExpMode(threadData_t *threadData, modelica_boolean _graphicsExpMode);
DLLExport
void boxptr_Config_setGraphicsExpMode(threadData_t *threadData, modelica_metatype _graphicsExpMode);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_setGraphicsExpMode,2,0) {(void*) boxptr_Config_setGraphicsExpMode,0}};
#define boxvar_Config_setGraphicsExpMode MMC_REFSTRUCTLIT(boxvar_lit_Config_setGraphicsExpMode)
DLLExport
modelica_boolean omc_Config_getGraphicsExpMode(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_getGraphicsExpMode(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_getGraphicsExpMode,2,0) {(void*) boxptr_Config_getGraphicsExpMode,0}};
#define boxvar_Config_getGraphicsExpMode MMC_REFSTRUCTLIT(boxvar_lit_Config_getGraphicsExpMode)
DLLExport
void omc_Config_setEvaluateParametersInAnnotations(threadData_t *threadData, modelica_boolean _shouldEvaluate);
DLLExport
void boxptr_Config_setEvaluateParametersInAnnotations(threadData_t *threadData, modelica_metatype _shouldEvaluate);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_setEvaluateParametersInAnnotations,2,0) {(void*) boxptr_Config_setEvaluateParametersInAnnotations,0}};
#define boxvar_Config_setEvaluateParametersInAnnotations MMC_REFSTRUCTLIT(boxvar_lit_Config_setEvaluateParametersInAnnotations)
DLLExport
modelica_boolean omc_Config_getEvaluateParametersInAnnotations(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_getEvaluateParametersInAnnotations(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_getEvaluateParametersInAnnotations,2,0) {(void*) boxptr_Config_getEvaluateParametersInAnnotations,0}};
#define boxvar_Config_getEvaluateParametersInAnnotations MMC_REFSTRUCTLIT(boxvar_lit_Config_getEvaluateParametersInAnnotations)
DLLExport
modelica_boolean omc_Config_showStartOrigin(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_showStartOrigin(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_showStartOrigin,2,0) {(void*) boxptr_Config_showStartOrigin,0}};
#define boxvar_Config_showStartOrigin MMC_REFSTRUCTLIT(boxvar_lit_Config_showStartOrigin)
DLLExport
modelica_boolean omc_Config_showStructuralAnnotations(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_showStructuralAnnotations(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_showStructuralAnnotations,2,0) {(void*) boxptr_Config_showStructuralAnnotations,0}};
#define boxvar_Config_showStructuralAnnotations MMC_REFSTRUCTLIT(boxvar_lit_Config_showStructuralAnnotations)
DLLExport
void omc_Config_setShowAnnotations(threadData_t *threadData, modelica_boolean _show);
DLLExport
void boxptr_Config_setShowAnnotations(threadData_t *threadData, modelica_metatype _show);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_setShowAnnotations,2,0) {(void*) boxptr_Config_setShowAnnotations,0}};
#define boxvar_Config_setShowAnnotations MMC_REFSTRUCTLIT(boxvar_lit_Config_setShowAnnotations)
DLLExport
modelica_boolean omc_Config_showAnnotations(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_showAnnotations(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_showAnnotations,2,0) {(void*) boxptr_Config_showAnnotations,0}};
#define boxvar_Config_showAnnotations MMC_REFSTRUCTLIT(boxvar_lit_Config_showAnnotations)
DLLExport
void omc_Config_setDefaultOpenCLDevice(threadData_t *threadData, modelica_integer _defdevid);
DLLExport
void boxptr_Config_setDefaultOpenCLDevice(threadData_t *threadData, modelica_metatype _defdevid);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_setDefaultOpenCLDevice,2,0) {(void*) boxptr_Config_setDefaultOpenCLDevice,0}};
#define boxvar_Config_setDefaultOpenCLDevice MMC_REFSTRUCTLIT(boxvar_lit_Config_setDefaultOpenCLDevice)
DLLExport
modelica_integer omc_Config_getDefaultOpenCLDevice(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_getDefaultOpenCLDevice(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_getDefaultOpenCLDevice,2,0) {(void*) boxptr_Config_getDefaultOpenCLDevice,0}};
#define boxvar_Config_getDefaultOpenCLDevice MMC_REFSTRUCTLIT(boxvar_lit_Config_getDefaultOpenCLDevice)
DLLExport
void omc_Config_setVectorizationLimit(threadData_t *threadData, modelica_integer _limit);
DLLExport
void boxptr_Config_setVectorizationLimit(threadData_t *threadData, modelica_metatype _limit);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_setVectorizationLimit,2,0) {(void*) boxptr_Config_setVectorizationLimit,0}};
#define boxvar_Config_setVectorizationLimit MMC_REFSTRUCTLIT(boxvar_lit_Config_setVectorizationLimit)
DLLExport
modelica_integer omc_Config_vectorizationLimit(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_vectorizationLimit(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_vectorizationLimit,2,0) {(void*) boxptr_Config_vectorizationLimit,0}};
#define boxvar_Config_vectorizationLimit MMC_REFSTRUCTLIT(boxvar_lit_Config_vectorizationLimit)
DLLExport
void omc_Config_setNoSimplify(threadData_t *threadData, modelica_boolean _noSimplify);
DLLExport
void boxptr_Config_setNoSimplify(threadData_t *threadData, modelica_metatype _noSimplify);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_setNoSimplify,2,0) {(void*) boxptr_Config_setNoSimplify,0}};
#define boxvar_Config_setNoSimplify MMC_REFSTRUCTLIT(boxvar_lit_Config_setNoSimplify)
DLLExport
modelica_boolean omc_Config_getNoSimplify(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_getNoSimplify(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_getNoSimplify,2,0) {(void*) boxptr_Config_getNoSimplify,0}};
#define boxvar_Config_getNoSimplify MMC_REFSTRUCTLIT(boxvar_lit_Config_getNoSimplify)
DLLExport
void omc_Config_setAnnotationVersion(threadData_t *threadData, modelica_string _annotationVersion);
#define boxptr_Config_setAnnotationVersion omc_Config_setAnnotationVersion
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_setAnnotationVersion,2,0) {(void*) boxptr_Config_setAnnotationVersion,0}};
#define boxvar_Config_setAnnotationVersion MMC_REFSTRUCTLIT(boxvar_lit_Config_setAnnotationVersion)
DLLExport
modelica_string omc_Config_getAnnotationVersion(threadData_t *threadData);
#define boxptr_Config_getAnnotationVersion omc_Config_getAnnotationVersion
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_getAnnotationVersion,2,0) {(void*) boxptr_Config_getAnnotationVersion,0}};
#define boxvar_Config_getAnnotationVersion MMC_REFSTRUCTLIT(boxvar_lit_Config_getAnnotationVersion)
DLLExport
modelica_boolean omc_Config_acceptPDEModelicaGrammar(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_acceptPDEModelicaGrammar(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_acceptPDEModelicaGrammar,2,0) {(void*) boxptr_Config_acceptPDEModelicaGrammar,0}};
#define boxvar_Config_acceptPDEModelicaGrammar MMC_REFSTRUCTLIT(boxvar_lit_Config_acceptPDEModelicaGrammar)
DLLExport
modelica_boolean omc_Config_acceptOptimicaGrammar(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_acceptOptimicaGrammar(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_acceptOptimicaGrammar,2,0) {(void*) boxptr_Config_acceptOptimicaGrammar,0}};
#define boxvar_Config_acceptOptimicaGrammar MMC_REFSTRUCTLIT(boxvar_lit_Config_acceptOptimicaGrammar)
DLLExport
modelica_boolean omc_Config_acceptParModelicaGrammar(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_acceptParModelicaGrammar(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_acceptParModelicaGrammar,2,0) {(void*) boxptr_Config_acceptParModelicaGrammar,0}};
#define boxvar_Config_acceptParModelicaGrammar MMC_REFSTRUCTLIT(boxvar_lit_Config_acceptParModelicaGrammar)
DLLExport
modelica_boolean omc_Config_acceptMetaModelicaGrammar(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_acceptMetaModelicaGrammar(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_acceptMetaModelicaGrammar,2,0) {(void*) boxptr_Config_acceptMetaModelicaGrammar,0}};
#define boxvar_Config_acceptMetaModelicaGrammar MMC_REFSTRUCTLIT(boxvar_lit_Config_acceptMetaModelicaGrammar)
DLLExport
modelica_integer omc_Config_acceptedGrammar(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_acceptedGrammar(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_acceptedGrammar,2,0) {(void*) boxptr_Config_acceptedGrammar,0}};
#define boxvar_Config_acceptedGrammar MMC_REFSTRUCTLIT(boxvar_lit_Config_acceptedGrammar)
DLLExport
modelica_boolean omc_Config_helpRequest(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_helpRequest(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_helpRequest,2,0) {(void*) boxptr_Config_helpRequest,0}};
#define boxvar_Config_helpRequest MMC_REFSTRUCTLIT(boxvar_lit_Config_helpRequest)
DLLExport
modelica_boolean omc_Config_versionRequest(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_versionRequest(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_versionRequest,2,0) {(void*) boxptr_Config_versionRequest,0}};
#define boxvar_Config_versionRequest MMC_REFSTRUCTLIT(boxvar_lit_Config_versionRequest)
DLLExport
modelica_boolean omc_Config_silent(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_silent(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_silent,2,0) {(void*) boxptr_Config_silent,0}};
#define boxvar_Config_silent MMC_REFSTRUCTLIT(boxvar_lit_Config_silent)
DLLExport
modelica_string omc_Config_classToInstantiate(threadData_t *threadData);
#define boxptr_Config_classToInstantiate omc_Config_classToInstantiate
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_classToInstantiate,2,0) {(void*) boxptr_Config_classToInstantiate,0}};
#define boxvar_Config_classToInstantiate MMC_REFSTRUCTLIT(boxvar_lit_Config_classToInstantiate)
DLLExport
modelica_string omc_Config_simulationCodeTarget(threadData_t *threadData);
#define boxptr_Config_simulationCodeTarget omc_Config_simulationCodeTarget
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_simulationCodeTarget,2,0) {(void*) boxptr_Config_simulationCodeTarget,0}};
#define boxvar_Config_simulationCodeTarget MMC_REFSTRUCTLIT(boxvar_lit_Config_simulationCodeTarget)
DLLExport
modelica_boolean omc_Config_simulationCg(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_simulationCg(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_simulationCg,2,0) {(void*) boxptr_Config_simulationCg,0}};
#define boxvar_Config_simulationCg MMC_REFSTRUCTLIT(boxvar_lit_Config_simulationCg)
DLLExport
modelica_real omc_Config_bandwidth(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_bandwidth(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_bandwidth,2,0) {(void*) boxptr_Config_bandwidth,0}};
#define boxvar_Config_bandwidth MMC_REFSTRUCTLIT(boxvar_lit_Config_bandwidth)
DLLExport
modelica_real omc_Config_latency(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_latency(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_latency,2,0) {(void*) boxptr_Config_latency,0}};
#define boxvar_Config_latency MMC_REFSTRUCTLIT(boxvar_lit_Config_latency)
DLLExport
modelica_integer omc_Config_noProc(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_noProc(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_noProc,2,0) {(void*) boxptr_Config_noProc,0}};
#define boxvar_Config_noProc MMC_REFSTRUCTLIT(boxvar_lit_Config_noProc)
DLLExport
modelica_boolean omc_Config_modelicaOutput(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_modelicaOutput(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_modelicaOutput,2,0) {(void*) boxptr_Config_modelicaOutput,0}};
#define boxvar_Config_modelicaOutput MMC_REFSTRUCTLIT(boxvar_lit_Config_modelicaOutput)
DLLExport
modelica_boolean omc_Config_splitArrays(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_splitArrays(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_splitArrays,2,0) {(void*) boxptr_Config_splitArrays,0}};
#define boxvar_Config_splitArrays MMC_REFSTRUCTLIT(boxvar_lit_Config_splitArrays)
DLLExport
modelica_boolean omc_Config_typeinfo(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Config_typeinfo(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Config_typeinfo,2,0) {(void*) boxptr_Config_typeinfo,0}};
#define boxvar_Config_typeinfo MMC_REFSTRUCTLIT(boxvar_lit_Config_typeinfo)
#ifdef __cplusplus
}
#endif
#endif
