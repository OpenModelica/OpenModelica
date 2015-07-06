/* Automatically generated header for external MetaModelica functions */
#ifdef __cplusplus
extern "C" {
#endif
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef FMI_Info_INFO__desc_added
#define FMI_Info_INFO__desc_added
ADD_METARECORD_DEFINITIONS const char* FMI_Info_INFO__desc__fields[11] = {"fmiVersion","fmiType","fmiModelName","fmiModelIdentifier","fmiGuid","fmiDescription","fmiGenerationTool","fmiGenerationDateAndTime","fmiVariableNamingConvention","fmiNumberOfContinuousStates","fmiNumberOfEventIndicators"};
ADD_METARECORD_DEFINITIONS struct record_description FMI_Info_INFO__desc = {
  "FMI_Info_INFO",
  "FMI.Info.INFO",
  FMI_Info_INFO__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description FMI_Info_INFO__desc;
#endif
#define FMI__INFO_3dBOX11 3
#define FMI__INFO(fmiVersion,fmiType,fmiModelName,fmiModelIdentifier,fmiGuid,fmiDescription,fmiGenerationTool,fmiGenerationDateAndTime,fmiVariableNamingConvention,fmiNumberOfContinuousStates,fmiNumberOfEventIndicators) (mmc_mk_box(12, 3,&FMI_Info_INFO__desc,fmiVersion,fmiType,fmiModelName,fmiModelIdentifier,fmiGuid,fmiDescription,fmiGenerationTool,fmiGenerationDateAndTime,fmiVariableNamingConvention,fmiNumberOfContinuousStates,fmiNumberOfEventIndicators))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef FMI_TypeDefinitions_ENUMERATIONTYPE__desc_added
#define FMI_TypeDefinitions_ENUMERATIONTYPE__desc_added
ADD_METARECORD_DEFINITIONS const char* FMI_TypeDefinitions_ENUMERATIONTYPE__desc__fields[6] = {"name","description","quantity","min","max","items"};
ADD_METARECORD_DEFINITIONS struct record_description FMI_TypeDefinitions_ENUMERATIONTYPE__desc = {
  "FMI_TypeDefinitions_ENUMERATIONTYPE",
  "FMI.TypeDefinitions.ENUMERATIONTYPE",
  FMI_TypeDefinitions_ENUMERATIONTYPE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description FMI_TypeDefinitions_ENUMERATIONTYPE__desc;
#endif
#define FMI__ENUMERATIONTYPE_3dBOX6 3
#define FMI__ENUMERATIONTYPE(name,description,quantity,min,max,items) (mmc_mk_box7(3,&FMI_TypeDefinitions_ENUMERATIONTYPE__desc,name,description,quantity,min,max,items))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef FMI_EnumerationItem_ENUMERATIONITEM__desc_added
#define FMI_EnumerationItem_ENUMERATIONITEM__desc_added
ADD_METARECORD_DEFINITIONS const char* FMI_EnumerationItem_ENUMERATIONITEM__desc__fields[2] = {"name","description"};
ADD_METARECORD_DEFINITIONS struct record_description FMI_EnumerationItem_ENUMERATIONITEM__desc = {
  "FMI_EnumerationItem_ENUMERATIONITEM",
  "FMI.EnumerationItem.ENUMERATIONITEM",
  FMI_EnumerationItem_ENUMERATIONITEM__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description FMI_EnumerationItem_ENUMERATIONITEM__desc;
#endif
#define FMI__ENUMERATIONITEM_3dBOX2 3
#define FMI__ENUMERATIONITEM(name,description) (mmc_mk_box3(3,&FMI_EnumerationItem_ENUMERATIONITEM__desc,name,description))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef FMI_ExperimentAnnotation_EXPERIMENTANNOTATION__desc_added
#define FMI_ExperimentAnnotation_EXPERIMENTANNOTATION__desc_added
ADD_METARECORD_DEFINITIONS const char* FMI_ExperimentAnnotation_EXPERIMENTANNOTATION__desc__fields[3] = {"fmiExperimentStartTime","fmiExperimentStopTime","fmiExperimentTolerance"};
ADD_METARECORD_DEFINITIONS struct record_description FMI_ExperimentAnnotation_EXPERIMENTANNOTATION__desc = {
  "FMI_ExperimentAnnotation_EXPERIMENTANNOTATION",
  "FMI.ExperimentAnnotation.EXPERIMENTANNOTATION",
  FMI_ExperimentAnnotation_EXPERIMENTANNOTATION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description FMI_ExperimentAnnotation_EXPERIMENTANNOTATION__desc;
#endif
#define FMI__EXPERIMENTANNOTATION_3dBOX3 3
#define FMI__EXPERIMENTANNOTATION(fmiExperimentStartTime,fmiExperimentStopTime,fmiExperimentTolerance) (mmc_mk_box4(3,&FMI_ExperimentAnnotation_EXPERIMENTANNOTATION__desc,fmiExperimentStartTime,fmiExperimentStopTime,fmiExperimentTolerance))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef FMI_ModelVariables_ENUMERATIONVARIABLE__desc_added
#define FMI_ModelVariables_ENUMERATIONVARIABLE__desc_added
ADD_METARECORD_DEFINITIONS const char* FMI_ModelVariables_ENUMERATIONVARIABLE__desc__fields[14] = {"instance","name","description","baseType","variability","causality","hasStartValue","startValue","isFixed","valueReference","x1Placement","x2Placement","y1Placement","y2Placement"};
ADD_METARECORD_DEFINITIONS struct record_description FMI_ModelVariables_ENUMERATIONVARIABLE__desc = {
  "FMI_ModelVariables_ENUMERATIONVARIABLE",
  "FMI.ModelVariables.ENUMERATIONVARIABLE",
  FMI_ModelVariables_ENUMERATIONVARIABLE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description FMI_ModelVariables_ENUMERATIONVARIABLE__desc;
#endif
#define FMI__ENUMERATIONVARIABLE_3dBOX14 7
#define FMI__ENUMERATIONVARIABLE(instance,name,description,baseType,variability,causality,hasStartValue,startValue,isFixed,valueReference,x1Placement,x2Placement,y1Placement,y2Placement) (mmc_mk_box(15, 7,&FMI_ModelVariables_ENUMERATIONVARIABLE__desc,instance,name,description,baseType,variability,causality,hasStartValue,startValue,isFixed,valueReference,x1Placement,x2Placement,y1Placement,y2Placement))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef FMI_ModelVariables_STRINGVARIABLE__desc_added
#define FMI_ModelVariables_STRINGVARIABLE__desc_added
ADD_METARECORD_DEFINITIONS const char* FMI_ModelVariables_STRINGVARIABLE__desc__fields[14] = {"instance","name","description","baseType","variability","causality","hasStartValue","startValue","isFixed","valueReference","x1Placement","x2Placement","y1Placement","y2Placement"};
ADD_METARECORD_DEFINITIONS struct record_description FMI_ModelVariables_STRINGVARIABLE__desc = {
  "FMI_ModelVariables_STRINGVARIABLE",
  "FMI.ModelVariables.STRINGVARIABLE",
  FMI_ModelVariables_STRINGVARIABLE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description FMI_ModelVariables_STRINGVARIABLE__desc;
#endif
#define FMI__STRINGVARIABLE_3dBOX14 6
#define FMI__STRINGVARIABLE(instance,name,description,baseType,variability,causality,hasStartValue,startValue,isFixed,valueReference,x1Placement,x2Placement,y1Placement,y2Placement) (mmc_mk_box(15, 6,&FMI_ModelVariables_STRINGVARIABLE__desc,instance,name,description,baseType,variability,causality,hasStartValue,startValue,isFixed,valueReference,x1Placement,x2Placement,y1Placement,y2Placement))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef FMI_ModelVariables_BOOLEANVARIABLE__desc_added
#define FMI_ModelVariables_BOOLEANVARIABLE__desc_added
ADD_METARECORD_DEFINITIONS const char* FMI_ModelVariables_BOOLEANVARIABLE__desc__fields[14] = {"instance","name","description","baseType","variability","causality","hasStartValue","startValue","isFixed","valueReference","x1Placement","x2Placement","y1Placement","y2Placement"};
ADD_METARECORD_DEFINITIONS struct record_description FMI_ModelVariables_BOOLEANVARIABLE__desc = {
  "FMI_ModelVariables_BOOLEANVARIABLE",
  "FMI.ModelVariables.BOOLEANVARIABLE",
  FMI_ModelVariables_BOOLEANVARIABLE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description FMI_ModelVariables_BOOLEANVARIABLE__desc;
#endif
#define FMI__BOOLEANVARIABLE_3dBOX14 5
#define FMI__BOOLEANVARIABLE(instance,name,description,baseType,variability,causality,hasStartValue,startValue,isFixed,valueReference,x1Placement,x2Placement,y1Placement,y2Placement) (mmc_mk_box(15, 5,&FMI_ModelVariables_BOOLEANVARIABLE__desc,instance,name,description,baseType,variability,causality,hasStartValue,startValue,isFixed,valueReference,x1Placement,x2Placement,y1Placement,y2Placement))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef FMI_ModelVariables_INTEGERVARIABLE__desc_added
#define FMI_ModelVariables_INTEGERVARIABLE__desc_added
ADD_METARECORD_DEFINITIONS const char* FMI_ModelVariables_INTEGERVARIABLE__desc__fields[14] = {"instance","name","description","baseType","variability","causality","hasStartValue","startValue","isFixed","valueReference","x1Placement","x2Placement","y1Placement","y2Placement"};
ADD_METARECORD_DEFINITIONS struct record_description FMI_ModelVariables_INTEGERVARIABLE__desc = {
  "FMI_ModelVariables_INTEGERVARIABLE",
  "FMI.ModelVariables.INTEGERVARIABLE",
  FMI_ModelVariables_INTEGERVARIABLE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description FMI_ModelVariables_INTEGERVARIABLE__desc;
#endif
#define FMI__INTEGERVARIABLE_3dBOX14 4
#define FMI__INTEGERVARIABLE(instance,name,description,baseType,variability,causality,hasStartValue,startValue,isFixed,valueReference,x1Placement,x2Placement,y1Placement,y2Placement) (mmc_mk_box(15, 4,&FMI_ModelVariables_INTEGERVARIABLE__desc,instance,name,description,baseType,variability,causality,hasStartValue,startValue,isFixed,valueReference,x1Placement,x2Placement,y1Placement,y2Placement))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef FMI_ModelVariables_REALVARIABLE__desc_added
#define FMI_ModelVariables_REALVARIABLE__desc_added
ADD_METARECORD_DEFINITIONS const char* FMI_ModelVariables_REALVARIABLE__desc__fields[14] = {"instance","name","description","baseType","variability","causality","hasStartValue","startValue","isFixed","valueReference","x1Placement","x2Placement","y1Placement","y2Placement"};
ADD_METARECORD_DEFINITIONS struct record_description FMI_ModelVariables_REALVARIABLE__desc = {
  "FMI_ModelVariables_REALVARIABLE",
  "FMI.ModelVariables.REALVARIABLE",
  FMI_ModelVariables_REALVARIABLE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description FMI_ModelVariables_REALVARIABLE__desc;
#endif
#define FMI__REALVARIABLE_3dBOX14 3
#define FMI__REALVARIABLE(instance,name,description,baseType,variability,causality,hasStartValue,startValue,isFixed,valueReference,x1Placement,x2Placement,y1Placement,y2Placement) (mmc_mk_box(15, 3,&FMI_ModelVariables_REALVARIABLE__desc,instance,name,description,baseType,variability,causality,hasStartValue,startValue,isFixed,valueReference,x1Placement,x2Placement,y1Placement,y2Placement))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef FMI_FmiImport_FMIIMPORT__desc_added
#define FMI_FmiImport_FMIIMPORT__desc_added
ADD_METARECORD_DEFINITIONS const char* FMI_FmiImport_FMIIMPORT__desc__fields[14] = {"platform","fmuFileName","fmuWorkingDirectory","fmiLogLevel","fmiDebugOutput","fmiContext","fmiInstance","fmiInfo","fmiTypeDefinitionsList","fmiExperimentAnnotation","fmiModelVariablesInstance","fmiModelVariablesList","generateInputConnectors","generateOutputConnectors"};
ADD_METARECORD_DEFINITIONS struct record_description FMI_FmiImport_FMIIMPORT__desc = {
  "FMI_FmiImport_FMIIMPORT",
  "FMI.FmiImport.FMIIMPORT",
  FMI_FmiImport_FMIIMPORT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description FMI_FmiImport_FMIIMPORT__desc;
#endif
#define FMI__FMIIMPORT_3dBOX14 3
#define FMI__FMIIMPORT(platform,fmuFileName,fmuWorkingDirectory,fmiLogLevel,fmiDebugOutput,fmiContext,fmiInstance,fmiInfo,fmiTypeDefinitionsList,fmiExperimentAnnotation,fmiModelVariablesInstance,fmiModelVariablesList,generateInputConnectors,generateOutputConnectors) (mmc_mk_box(15, 3,&FMI_FmiImport_FMIIMPORT__desc,platform,fmuFileName,fmuWorkingDirectory,fmiLogLevel,fmiDebugOutput,fmiContext,fmiInstance,fmiInfo,fmiTypeDefinitionsList,fmiExperimentAnnotation,fmiModelVariablesInstance,fmiModelVariablesList,generateInputConnectors,generateOutputConnectors))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Util_ReplacePattern_REPLACEPATTERN__desc_added
#define Util_ReplacePattern_REPLACEPATTERN__desc_added
ADD_METARECORD_DEFINITIONS const char* Util_ReplacePattern_REPLACEPATTERN__desc__fields[2] = {"from","to"};
ADD_METARECORD_DEFINITIONS struct record_description Util_ReplacePattern_REPLACEPATTERN__desc = {
  "Util_ReplacePattern_REPLACEPATTERN",
  "Util.ReplacePattern.REPLACEPATTERN",
  Util_ReplacePattern_REPLACEPATTERN__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Util_ReplacePattern_REPLACEPATTERN__desc;
#endif
#define Util__REPLACEPATTERN_3dBOX2 3
#define Util__REPLACEPATTERN(from,to) (mmc_mk_box3(3,&Util_ReplacePattern_REPLACEPATTERN__desc,from,to))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Util_Status_FAILURE__desc_added
#define Util_Status_FAILURE__desc_added
ADD_METARECORD_DEFINITIONS const char* Util_Status_FAILURE__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Util_Status_FAILURE__desc = {
  "Util_Status_FAILURE",
  "Util.Status.FAILURE",
  Util_Status_FAILURE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Util_Status_FAILURE__desc;
#endif
#define Util__FAILURE_3dBOX0 4
static const MMC_DEFSTRUCTLIT(Util__FAILURE__struct,1,4) {&Util_Status_FAILURE__desc}};
static void *Util__FAILURE = MMC_REFSTRUCTLIT(Util__FAILURE__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Util_Status_SUCCESS__desc_added
#define Util_Status_SUCCESS__desc_added
ADD_METARECORD_DEFINITIONS const char* Util_Status_SUCCESS__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Util_Status_SUCCESS__desc = {
  "Util_Status_SUCCESS",
  "Util.Status.SUCCESS",
  Util_Status_SUCCESS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Util_Status_SUCCESS__desc;
#endif
#define Util__SUCCESS_3dBOX0 3
static const MMC_DEFSTRUCTLIT(Util__SUCCESS__struct,1,3) {&Util_Status_SUCCESS__desc}};
static void *Util__SUCCESS = MMC_REFSTRUCTLIT(Util__SUCCESS__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Util_DateTime_DATETIME__desc_added
#define Util_DateTime_DATETIME__desc_added
ADD_METARECORD_DEFINITIONS const char* Util_DateTime_DATETIME__desc__fields[6] = {"sec","min","hour","mday","mon","year"};
ADD_METARECORD_DEFINITIONS struct record_description Util_DateTime_DATETIME__desc = {
  "Util_DateTime_DATETIME",
  "Util.DateTime.DATETIME",
  Util_DateTime_DATETIME__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Util_DateTime_DATETIME__desc;
#endif
#define Util__DATETIME_3dBOX6 3
#define Util__DATETIME(sec,min,hour,mday,mon,year) (mmc_mk_box7(3,&Util_DateTime_DATETIME__desc,sec,min,hour,mday,mon,year))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Util_TranslatableContent_notrans__desc_added
#define Util_TranslatableContent_notrans__desc_added
ADD_METARECORD_DEFINITIONS const char* Util_TranslatableContent_notrans__desc__fields[1] = {"str"};
ADD_METARECORD_DEFINITIONS struct record_description Util_TranslatableContent_notrans__desc = {
  "Util_TranslatableContent_notrans",
  "Util.TranslatableContent.notrans",
  Util_TranslatableContent_notrans__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Util_TranslatableContent_notrans__desc;
#endif
#define Util__notrans_3dBOX1 4
#define Util__notrans(str) (mmc_mk_box2(4,&Util_TranslatableContent_notrans__desc,str))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Util_TranslatableContent_gettext__desc_added
#define Util_TranslatableContent_gettext__desc_added
ADD_METARECORD_DEFINITIONS const char* Util_TranslatableContent_gettext__desc__fields[1] = {"msgid"};
ADD_METARECORD_DEFINITIONS struct record_description Util_TranslatableContent_gettext__desc = {
  "Util_TranslatableContent_gettext",
  "Util.TranslatableContent.gettext",
  Util_TranslatableContent_gettext__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Util_TranslatableContent_gettext__desc;
#endif
#define Util__gettext_3dBOX1 3
#define Util__gettext(msgid) (mmc_mk_box2(3,&Util_TranslatableContent_gettext__desc,msgid))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Config_LanguageStandard_MODELICA__LATEST__desc_added
#define Config_LanguageStandard_MODELICA__LATEST__desc_added
ADD_METARECORD_DEFINITIONS const char* Config_LanguageStandard_MODELICA__LATEST__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Config_LanguageStandard_MODELICA__LATEST__desc = {
  "Config_LanguageStandard_MODELICA__LATEST",
  "Config.LanguageStandard.MODELICA_LATEST",
  Config_LanguageStandard_MODELICA__LATEST__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Config_LanguageStandard_MODELICA__LATEST__desc;
#endif
#define Config__MODELICA_5fLATEST_3dBOX0 9
static const MMC_DEFSTRUCTLIT(Config__MODELICA_5fLATEST__struct,1,9) {&Config_LanguageStandard_MODELICA__LATEST__desc}};
static void *Config__MODELICA_5fLATEST = MMC_REFSTRUCTLIT(Config__MODELICA_5fLATEST__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Config_LanguageStandard_MODELICA__3__3__desc_added
#define Config_LanguageStandard_MODELICA__3__3__desc_added
ADD_METARECORD_DEFINITIONS const char* Config_LanguageStandard_MODELICA__3__3__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Config_LanguageStandard_MODELICA__3__3__desc = {
  "Config_LanguageStandard_MODELICA__3__3",
  "Config.LanguageStandard.MODELICA_3_3",
  Config_LanguageStandard_MODELICA__3__3__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Config_LanguageStandard_MODELICA__3__3__desc;
#endif
#define Config__MODELICA_5f3_5f3_3dBOX0 8
static const MMC_DEFSTRUCTLIT(Config__MODELICA_5f3_5f3__struct,1,8) {&Config_LanguageStandard_MODELICA__3__3__desc}};
static void *Config__MODELICA_5f3_5f3 = MMC_REFSTRUCTLIT(Config__MODELICA_5f3_5f3__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Config_LanguageStandard_MODELICA__3__2__desc_added
#define Config_LanguageStandard_MODELICA__3__2__desc_added
ADD_METARECORD_DEFINITIONS const char* Config_LanguageStandard_MODELICA__3__2__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Config_LanguageStandard_MODELICA__3__2__desc = {
  "Config_LanguageStandard_MODELICA__3__2",
  "Config.LanguageStandard.MODELICA_3_2",
  Config_LanguageStandard_MODELICA__3__2__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Config_LanguageStandard_MODELICA__3__2__desc;
#endif
#define Config__MODELICA_5f3_5f2_3dBOX0 7
static const MMC_DEFSTRUCTLIT(Config__MODELICA_5f3_5f2__struct,1,7) {&Config_LanguageStandard_MODELICA__3__2__desc}};
static void *Config__MODELICA_5f3_5f2 = MMC_REFSTRUCTLIT(Config__MODELICA_5f3_5f2__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Config_LanguageStandard_MODELICA__3__1__desc_added
#define Config_LanguageStandard_MODELICA__3__1__desc_added
ADD_METARECORD_DEFINITIONS const char* Config_LanguageStandard_MODELICA__3__1__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Config_LanguageStandard_MODELICA__3__1__desc = {
  "Config_LanguageStandard_MODELICA__3__1",
  "Config.LanguageStandard.MODELICA_3_1",
  Config_LanguageStandard_MODELICA__3__1__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Config_LanguageStandard_MODELICA__3__1__desc;
#endif
#define Config__MODELICA_5f3_5f1_3dBOX0 6
static const MMC_DEFSTRUCTLIT(Config__MODELICA_5f3_5f1__struct,1,6) {&Config_LanguageStandard_MODELICA__3__1__desc}};
static void *Config__MODELICA_5f3_5f1 = MMC_REFSTRUCTLIT(Config__MODELICA_5f3_5f1__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Config_LanguageStandard_MODELICA__3__0__desc_added
#define Config_LanguageStandard_MODELICA__3__0__desc_added
ADD_METARECORD_DEFINITIONS const char* Config_LanguageStandard_MODELICA__3__0__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Config_LanguageStandard_MODELICA__3__0__desc = {
  "Config_LanguageStandard_MODELICA__3__0",
  "Config.LanguageStandard.MODELICA_3_0",
  Config_LanguageStandard_MODELICA__3__0__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Config_LanguageStandard_MODELICA__3__0__desc;
#endif
#define Config__MODELICA_5f3_5f0_3dBOX0 5
static const MMC_DEFSTRUCTLIT(Config__MODELICA_5f3_5f0__struct,1,5) {&Config_LanguageStandard_MODELICA__3__0__desc}};
static void *Config__MODELICA_5f3_5f0 = MMC_REFSTRUCTLIT(Config__MODELICA_5f3_5f0__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Config_LanguageStandard_MODELICA__2__X__desc_added
#define Config_LanguageStandard_MODELICA__2__X__desc_added
ADD_METARECORD_DEFINITIONS const char* Config_LanguageStandard_MODELICA__2__X__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Config_LanguageStandard_MODELICA__2__X__desc = {
  "Config_LanguageStandard_MODELICA__2__X",
  "Config.LanguageStandard.MODELICA_2_X",
  Config_LanguageStandard_MODELICA__2__X__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Config_LanguageStandard_MODELICA__2__X__desc;
#endif
#define Config__MODELICA_5f2_5fX_3dBOX0 4
static const MMC_DEFSTRUCTLIT(Config__MODELICA_5f2_5fX__struct,1,4) {&Config_LanguageStandard_MODELICA__2__X__desc}};
static void *Config__MODELICA_5f2_5fX = MMC_REFSTRUCTLIT(Config__MODELICA_5f2_5fX__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Config_LanguageStandard_MODELICA__1__X__desc_added
#define Config_LanguageStandard_MODELICA__1__X__desc_added
ADD_METARECORD_DEFINITIONS const char* Config_LanguageStandard_MODELICA__1__X__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Config_LanguageStandard_MODELICA__1__X__desc = {
  "Config_LanguageStandard_MODELICA__1__X",
  "Config.LanguageStandard.MODELICA_1_X",
  Config_LanguageStandard_MODELICA__1__X__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Config_LanguageStandard_MODELICA__1__X__desc;
#endif
#define Config__MODELICA_5f1_5fX_3dBOX0 3
static const MMC_DEFSTRUCTLIT(Config__MODELICA_5f1_5fX__struct,1,3) {&Config_LanguageStandard_MODELICA__1__X__desc}};
static void *Config__MODELICA_5f1_5fX = MMC_REFSTRUCTLIT(Config__MODELICA_5f1_5fX__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Error_Severity_NOTIFICATION__desc_added
#define Error_Severity_NOTIFICATION__desc_added
ADD_METARECORD_DEFINITIONS const char* Error_Severity_NOTIFICATION__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Error_Severity_NOTIFICATION__desc = {
  "Error_Severity_NOTIFICATION",
  "Error.Severity.NOTIFICATION",
  Error_Severity_NOTIFICATION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Error_Severity_NOTIFICATION__desc;
#endif
#define Error__NOTIFICATION_3dBOX0 6
static const MMC_DEFSTRUCTLIT(Error__NOTIFICATION__struct,1,6) {&Error_Severity_NOTIFICATION__desc}};
static void *Error__NOTIFICATION = MMC_REFSTRUCTLIT(Error__NOTIFICATION__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Error_Severity_WARNING__desc_added
#define Error_Severity_WARNING__desc_added
ADD_METARECORD_DEFINITIONS const char* Error_Severity_WARNING__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Error_Severity_WARNING__desc = {
  "Error_Severity_WARNING",
  "Error.Severity.WARNING",
  Error_Severity_WARNING__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Error_Severity_WARNING__desc;
#endif
#define Error__WARNING_3dBOX0 5
static const MMC_DEFSTRUCTLIT(Error__WARNING__struct,1,5) {&Error_Severity_WARNING__desc}};
static void *Error__WARNING = MMC_REFSTRUCTLIT(Error__WARNING__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Error_Severity_ERROR__desc_added
#define Error_Severity_ERROR__desc_added
ADD_METARECORD_DEFINITIONS const char* Error_Severity_ERROR__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Error_Severity_ERROR__desc = {
  "Error_Severity_ERROR",
  "Error.Severity.ERROR",
  Error_Severity_ERROR__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Error_Severity_ERROR__desc;
#endif
#define Error__ERROR_3dBOX0 4
static const MMC_DEFSTRUCTLIT(Error__ERROR__struct,1,4) {&Error_Severity_ERROR__desc}};
static void *Error__ERROR = MMC_REFSTRUCTLIT(Error__ERROR__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Error_Severity_INTERNAL__desc_added
#define Error_Severity_INTERNAL__desc_added
ADD_METARECORD_DEFINITIONS const char* Error_Severity_INTERNAL__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Error_Severity_INTERNAL__desc = {
  "Error_Severity_INTERNAL",
  "Error.Severity.INTERNAL",
  Error_Severity_INTERNAL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Error_Severity_INTERNAL__desc;
#endif
#define Error__INTERNAL_3dBOX0 3
static const MMC_DEFSTRUCTLIT(Error__INTERNAL__struct,1,3) {&Error_Severity_INTERNAL__desc}};
static void *Error__INTERNAL = MMC_REFSTRUCTLIT(Error__INTERNAL__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Error_MessageType_SCRIPTING__desc_added
#define Error_MessageType_SCRIPTING__desc_added
ADD_METARECORD_DEFINITIONS const char* Error_MessageType_SCRIPTING__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Error_MessageType_SCRIPTING__desc = {
  "Error_MessageType_SCRIPTING",
  "Error.MessageType.SCRIPTING",
  Error_MessageType_SCRIPTING__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Error_MessageType_SCRIPTING__desc;
#endif
#define Error__SCRIPTING_3dBOX0 8
static const MMC_DEFSTRUCTLIT(Error__SCRIPTING__struct,1,8) {&Error_MessageType_SCRIPTING__desc}};
static void *Error__SCRIPTING = MMC_REFSTRUCTLIT(Error__SCRIPTING__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Error_MessageType_SIMULATION__desc_added
#define Error_MessageType_SIMULATION__desc_added
ADD_METARECORD_DEFINITIONS const char* Error_MessageType_SIMULATION__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Error_MessageType_SIMULATION__desc = {
  "Error_MessageType_SIMULATION",
  "Error.MessageType.SIMULATION",
  Error_MessageType_SIMULATION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Error_MessageType_SIMULATION__desc;
#endif
#define Error__SIMULATION_3dBOX0 7
static const MMC_DEFSTRUCTLIT(Error__SIMULATION__struct,1,7) {&Error_MessageType_SIMULATION__desc}};
static void *Error__SIMULATION = MMC_REFSTRUCTLIT(Error__SIMULATION__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Error_MessageType_SYMBOLIC__desc_added
#define Error_MessageType_SYMBOLIC__desc_added
ADD_METARECORD_DEFINITIONS const char* Error_MessageType_SYMBOLIC__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Error_MessageType_SYMBOLIC__desc = {
  "Error_MessageType_SYMBOLIC",
  "Error.MessageType.SYMBOLIC",
  Error_MessageType_SYMBOLIC__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Error_MessageType_SYMBOLIC__desc;
#endif
#define Error__SYMBOLIC_3dBOX0 6
static const MMC_DEFSTRUCTLIT(Error__SYMBOLIC__struct,1,6) {&Error_MessageType_SYMBOLIC__desc}};
static void *Error__SYMBOLIC = MMC_REFSTRUCTLIT(Error__SYMBOLIC__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Error_MessageType_TRANSLATION__desc_added
#define Error_MessageType_TRANSLATION__desc_added
ADD_METARECORD_DEFINITIONS const char* Error_MessageType_TRANSLATION__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Error_MessageType_TRANSLATION__desc = {
  "Error_MessageType_TRANSLATION",
  "Error.MessageType.TRANSLATION",
  Error_MessageType_TRANSLATION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Error_MessageType_TRANSLATION__desc;
#endif
#define Error__TRANSLATION_3dBOX0 5
static const MMC_DEFSTRUCTLIT(Error__TRANSLATION__struct,1,5) {&Error_MessageType_TRANSLATION__desc}};
static void *Error__TRANSLATION = MMC_REFSTRUCTLIT(Error__TRANSLATION__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Error_MessageType_GRAMMAR__desc_added
#define Error_MessageType_GRAMMAR__desc_added
ADD_METARECORD_DEFINITIONS const char* Error_MessageType_GRAMMAR__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Error_MessageType_GRAMMAR__desc = {
  "Error_MessageType_GRAMMAR",
  "Error.MessageType.GRAMMAR",
  Error_MessageType_GRAMMAR__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Error_MessageType_GRAMMAR__desc;
#endif
#define Error__GRAMMAR_3dBOX0 4
static const MMC_DEFSTRUCTLIT(Error__GRAMMAR__struct,1,4) {&Error_MessageType_GRAMMAR__desc}};
static void *Error__GRAMMAR = MMC_REFSTRUCTLIT(Error__GRAMMAR__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Error_MessageType_SYNTAX__desc_added
#define Error_MessageType_SYNTAX__desc_added
ADD_METARECORD_DEFINITIONS const char* Error_MessageType_SYNTAX__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Error_MessageType_SYNTAX__desc = {
  "Error_MessageType_SYNTAX",
  "Error.MessageType.SYNTAX",
  Error_MessageType_SYNTAX__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Error_MessageType_SYNTAX__desc;
#endif
#define Error__SYNTAX_3dBOX0 3
static const MMC_DEFSTRUCTLIT(Error__SYNTAX__struct,1,3) {&Error_MessageType_SYNTAX__desc}};
static void *Error__SYNTAX = MMC_REFSTRUCTLIT(Error__SYNTAX__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Error_Message_MESSAGE__desc_added
#define Error_Message_MESSAGE__desc_added
ADD_METARECORD_DEFINITIONS const char* Error_Message_MESSAGE__desc__fields[4] = {"id","ty","severity","message"};
ADD_METARECORD_DEFINITIONS struct record_description Error_Message_MESSAGE__desc = {
  "Error_Message_MESSAGE",
  "Error.Message.MESSAGE",
  Error_Message_MESSAGE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Error_Message_MESSAGE__desc;
#endif
#define Error__MESSAGE_3dBOX4 3
#define Error__MESSAGE(id,ty,severity,message) (mmc_mk_box5(3,&Error_Message_MESSAGE__desc,id,ty,severity,message))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Error_TotalMessage_TOTALMESSAGE__desc_added
#define Error_TotalMessage_TOTALMESSAGE__desc_added
ADD_METARECORD_DEFINITIONS const char* Error_TotalMessage_TOTALMESSAGE__desc__fields[2] = {"msg","info"};
ADD_METARECORD_DEFINITIONS struct record_description Error_TotalMessage_TOTALMESSAGE__desc = {
  "Error_TotalMessage_TOTALMESSAGE",
  "Error.TotalMessage.TOTALMESSAGE",
  Error_TotalMessage_TOTALMESSAGE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Error_TotalMessage_TOTALMESSAGE__desc;
#endif
#define Error__TOTALMESSAGE_3dBOX2 3
#define Error__TOTALMESSAGE(msg,info) (mmc_mk_box3(3,&Error_TotalMessage_TOTALMESSAGE__desc,msg,info))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_Value_EMPTY__desc_added
#define Values_Value_EMPTY__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_Value_EMPTY__desc__fields[4] = {"scope","name","ty","tyStr"};
ADD_METARECORD_DEFINITIONS struct record_description Values_Value_EMPTY__desc = {
  "Values_Value_EMPTY",
  "Values.Value.EMPTY",
  Values_Value_EMPTY__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_Value_EMPTY__desc;
#endif
#define Values__EMPTY_3dBOX4 19
#define Values__EMPTY(scope,name,ty,tyStr) (mmc_mk_box5(19,&Values_Value_EMPTY__desc,scope,name,ty,tyStr))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_Value_META__FAIL__desc_added
#define Values_Value_META__FAIL__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_Value_META__FAIL__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Values_Value_META__FAIL__desc = {
  "Values_Value_META__FAIL",
  "Values.Value.META_FAIL",
  Values_Value_META__FAIL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_Value_META__FAIL__desc;
#endif
#define Values__META_5fFAIL_3dBOX0 18
static const MMC_DEFSTRUCTLIT(Values__META_5fFAIL__struct,1,18) {&Values_Value_META__FAIL__desc}};
static void *Values__META_5fFAIL = MMC_REFSTRUCTLIT(Values__META_5fFAIL__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_Value_META__BOX__desc_added
#define Values_Value_META__BOX__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_Value_META__BOX__desc__fields[1] = {"value"};
ADD_METARECORD_DEFINITIONS struct record_description Values_Value_META__BOX__desc = {
  "Values_Value_META__BOX",
  "Values.Value.META_BOX",
  Values_Value_META__BOX__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_Value_META__BOX__desc;
#endif
#define Values__META_5fBOX_3dBOX1 17
#define Values__META_5fBOX(value) (mmc_mk_box2(17,&Values_Value_META__BOX__desc,value))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_Value_NORETCALL__desc_added
#define Values_Value_NORETCALL__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_Value_NORETCALL__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Values_Value_NORETCALL__desc = {
  "Values_Value_NORETCALL",
  "Values.Value.NORETCALL",
  Values_Value_NORETCALL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_Value_NORETCALL__desc;
#endif
#define Values__NORETCALL_3dBOX0 16
static const MMC_DEFSTRUCTLIT(Values__NORETCALL__struct,1,16) {&Values_Value_NORETCALL__desc}};
static void *Values__NORETCALL = MMC_REFSTRUCTLIT(Values__NORETCALL__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_Value_CODE__desc_added
#define Values_Value_CODE__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_Value_CODE__desc__fields[1] = {"A"};
ADD_METARECORD_DEFINITIONS struct record_description Values_Value_CODE__desc = {
  "Values_Value_CODE",
  "Values.Value.CODE",
  Values_Value_CODE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_Value_CODE__desc;
#endif
#define Values__CODE_3dBOX1 15
#define Values__CODE(A) (mmc_mk_box2(15,&Values_Value_CODE__desc,A))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_Value_OPTION__desc_added
#define Values_Value_OPTION__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_Value_OPTION__desc__fields[1] = {"some"};
ADD_METARECORD_DEFINITIONS struct record_description Values_Value_OPTION__desc = {
  "Values_Value_OPTION",
  "Values.Value.OPTION",
  Values_Value_OPTION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_Value_OPTION__desc;
#endif
#define Values__OPTION_3dBOX1 14
#define Values__OPTION(some) (mmc_mk_box2(14,&Values_Value_OPTION__desc,some))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_Value_RECORD__desc_added
#define Values_Value_RECORD__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_Value_RECORD__desc__fields[4] = {"record_","orderd","comp","index"};
ADD_METARECORD_DEFINITIONS struct record_description Values_Value_RECORD__desc = {
  "Values_Value_RECORD",
  "Values.Value.RECORD",
  Values_Value_RECORD__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_Value_RECORD__desc;
#endif
#define Values__RECORD_3dBOX4 13
#define Values__RECORD(record_,orderd,comp,index) (mmc_mk_box5(13,&Values_Value_RECORD__desc,record_,orderd,comp,index))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_Value_META__TUPLE__desc_added
#define Values_Value_META__TUPLE__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_Value_META__TUPLE__desc__fields[1] = {"valueLst"};
ADD_METARECORD_DEFINITIONS struct record_description Values_Value_META__TUPLE__desc = {
  "Values_Value_META__TUPLE",
  "Values.Value.META_TUPLE",
  Values_Value_META__TUPLE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_Value_META__TUPLE__desc;
#endif
#define Values__META_5fTUPLE_3dBOX1 12
#define Values__META_5fTUPLE(valueLst) (mmc_mk_box2(12,&Values_Value_META__TUPLE__desc,valueLst))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_Value_TUPLE__desc_added
#define Values_Value_TUPLE__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_Value_TUPLE__desc__fields[1] = {"valueLst"};
ADD_METARECORD_DEFINITIONS struct record_description Values_Value_TUPLE__desc = {
  "Values_Value_TUPLE",
  "Values.Value.TUPLE",
  Values_Value_TUPLE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_Value_TUPLE__desc;
#endif
#define Values__TUPLE_3dBOX1 11
#define Values__TUPLE(valueLst) (mmc_mk_box2(11,&Values_Value_TUPLE__desc,valueLst))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_Value_META__ARRAY__desc_added
#define Values_Value_META__ARRAY__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_Value_META__ARRAY__desc__fields[1] = {"valueLst"};
ADD_METARECORD_DEFINITIONS struct record_description Values_Value_META__ARRAY__desc = {
  "Values_Value_META__ARRAY",
  "Values.Value.META_ARRAY",
  Values_Value_META__ARRAY__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_Value_META__ARRAY__desc;
#endif
#define Values__META_5fARRAY_3dBOX1 10
#define Values__META_5fARRAY(valueLst) (mmc_mk_box2(10,&Values_Value_META__ARRAY__desc,valueLst))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_Value_LIST__desc_added
#define Values_Value_LIST__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_Value_LIST__desc__fields[1] = {"valueLst"};
ADD_METARECORD_DEFINITIONS struct record_description Values_Value_LIST__desc = {
  "Values_Value_LIST",
  "Values.Value.LIST",
  Values_Value_LIST__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_Value_LIST__desc;
#endif
#define Values__LIST_3dBOX1 9
#define Values__LIST(valueLst) (mmc_mk_box2(9,&Values_Value_LIST__desc,valueLst))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_Value_ARRAY__desc_added
#define Values_Value_ARRAY__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_Value_ARRAY__desc__fields[2] = {"valueLst","dimLst"};
ADD_METARECORD_DEFINITIONS struct record_description Values_Value_ARRAY__desc = {
  "Values_Value_ARRAY",
  "Values.Value.ARRAY",
  Values_Value_ARRAY__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_Value_ARRAY__desc;
#endif
#define Values__ARRAY_3dBOX2 8
#define Values__ARRAY(valueLst,dimLst) (mmc_mk_box3(8,&Values_Value_ARRAY__desc,valueLst,dimLst))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_Value_ENUM__LITERAL__desc_added
#define Values_Value_ENUM__LITERAL__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_Value_ENUM__LITERAL__desc__fields[2] = {"name","index"};
ADD_METARECORD_DEFINITIONS struct record_description Values_Value_ENUM__LITERAL__desc = {
  "Values_Value_ENUM__LITERAL",
  "Values.Value.ENUM_LITERAL",
  Values_Value_ENUM__LITERAL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_Value_ENUM__LITERAL__desc;
#endif
#define Values__ENUM_5fLITERAL_3dBOX2 7
#define Values__ENUM_5fLITERAL(name,index) (mmc_mk_box3(7,&Values_Value_ENUM__LITERAL__desc,name,index))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_Value_BOOL__desc_added
#define Values_Value_BOOL__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_Value_BOOL__desc__fields[1] = {"boolean"};
ADD_METARECORD_DEFINITIONS struct record_description Values_Value_BOOL__desc = {
  "Values_Value_BOOL",
  "Values.Value.BOOL",
  Values_Value_BOOL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_Value_BOOL__desc;
#endif
#define Values__BOOL_3dBOX1 6
#define Values__BOOL(boolean) (mmc_mk_box2(6,&Values_Value_BOOL__desc,boolean))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_Value_STRING__desc_added
#define Values_Value_STRING__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_Value_STRING__desc__fields[1] = {"string"};
ADD_METARECORD_DEFINITIONS struct record_description Values_Value_STRING__desc = {
  "Values_Value_STRING",
  "Values.Value.STRING",
  Values_Value_STRING__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_Value_STRING__desc;
#endif
#define Values__STRING_3dBOX1 5
#define Values__STRING(string) (mmc_mk_box2(5,&Values_Value_STRING__desc,string))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_Value_REAL__desc_added
#define Values_Value_REAL__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_Value_REAL__desc__fields[1] = {"real"};
ADD_METARECORD_DEFINITIONS struct record_description Values_Value_REAL__desc = {
  "Values_Value_REAL",
  "Values.Value.REAL",
  Values_Value_REAL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_Value_REAL__desc;
#endif
#define Values__REAL_3dBOX1 4
#define Values__REAL(real) (mmc_mk_box2(4,&Values_Value_REAL__desc,real))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_Value_INTEGER__desc_added
#define Values_Value_INTEGER__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_Value_INTEGER__desc__fields[1] = {"integer"};
ADD_METARECORD_DEFINITIONS struct record_description Values_Value_INTEGER__desc = {
  "Values_Value_INTEGER",
  "Values.Value.INTEGER",
  Values_Value_INTEGER__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_Value_INTEGER__desc;
#endif
#define Values__INTEGER_3dBOX1 3
#define Values__INTEGER(integer) (mmc_mk_box2(3,&Values_Value_INTEGER__desc,integer))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_IntRealOp_LESSEQOP__desc_added
#define Values_IntRealOp_LESSEQOP__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_IntRealOp_LESSEQOP__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Values_IntRealOp_LESSEQOP__desc = {
  "Values_IntRealOp_LESSEQOP",
  "Values.IntRealOp.LESSEQOP",
  Values_IntRealOp_LESSEQOP__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_IntRealOp_LESSEQOP__desc;
#endif
#define Values__LESSEQOP_3dBOX0 8
static const MMC_DEFSTRUCTLIT(Values__LESSEQOP__struct,1,8) {&Values_IntRealOp_LESSEQOP__desc}};
static void *Values__LESSEQOP = MMC_REFSTRUCTLIT(Values__LESSEQOP__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_IntRealOp_POWOP__desc_added
#define Values_IntRealOp_POWOP__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_IntRealOp_POWOP__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Values_IntRealOp_POWOP__desc = {
  "Values_IntRealOp_POWOP",
  "Values.IntRealOp.POWOP",
  Values_IntRealOp_POWOP__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_IntRealOp_POWOP__desc;
#endif
#define Values__POWOP_3dBOX0 7
static const MMC_DEFSTRUCTLIT(Values__POWOP__struct,1,7) {&Values_IntRealOp_POWOP__desc}};
static void *Values__POWOP = MMC_REFSTRUCTLIT(Values__POWOP__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_IntRealOp_SUBOP__desc_added
#define Values_IntRealOp_SUBOP__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_IntRealOp_SUBOP__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Values_IntRealOp_SUBOP__desc = {
  "Values_IntRealOp_SUBOP",
  "Values.IntRealOp.SUBOP",
  Values_IntRealOp_SUBOP__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_IntRealOp_SUBOP__desc;
#endif
#define Values__SUBOP_3dBOX0 6
static const MMC_DEFSTRUCTLIT(Values__SUBOP__struct,1,6) {&Values_IntRealOp_SUBOP__desc}};
static void *Values__SUBOP = MMC_REFSTRUCTLIT(Values__SUBOP__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_IntRealOp_ADDOP__desc_added
#define Values_IntRealOp_ADDOP__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_IntRealOp_ADDOP__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Values_IntRealOp_ADDOP__desc = {
  "Values_IntRealOp_ADDOP",
  "Values.IntRealOp.ADDOP",
  Values_IntRealOp_ADDOP__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_IntRealOp_ADDOP__desc;
#endif
#define Values__ADDOP_3dBOX0 5
static const MMC_DEFSTRUCTLIT(Values__ADDOP__struct,1,5) {&Values_IntRealOp_ADDOP__desc}};
static void *Values__ADDOP = MMC_REFSTRUCTLIT(Values__ADDOP__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_IntRealOp_DIVOP__desc_added
#define Values_IntRealOp_DIVOP__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_IntRealOp_DIVOP__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Values_IntRealOp_DIVOP__desc = {
  "Values_IntRealOp_DIVOP",
  "Values.IntRealOp.DIVOP",
  Values_IntRealOp_DIVOP__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_IntRealOp_DIVOP__desc;
#endif
#define Values__DIVOP_3dBOX0 4
static const MMC_DEFSTRUCTLIT(Values__DIVOP__struct,1,4) {&Values_IntRealOp_DIVOP__desc}};
static void *Values__DIVOP = MMC_REFSTRUCTLIT(Values__DIVOP__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Values_IntRealOp_MULOP__desc_added
#define Values_IntRealOp_MULOP__desc_added
ADD_METARECORD_DEFINITIONS const char* Values_IntRealOp_MULOP__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Values_IntRealOp_MULOP__desc = {
  "Values_IntRealOp_MULOP",
  "Values.IntRealOp.MULOP",
  Values_IntRealOp_MULOP__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Values_IntRealOp_MULOP__desc;
#endif
#define Values__MULOP_3dBOX0 3
static const MMC_DEFSTRUCTLIT(Values__MULOP__struct,1,3) {&Values_IntRealOp_MULOP__desc}};
static void *Values__MULOP = MMC_REFSTRUCTLIT(Values__MULOP__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef GlobalScript_SimulationOptions_SIMULATION__OPTIONS__desc_added
#define GlobalScript_SimulationOptions_SIMULATION__OPTIONS__desc_added
ADD_METARECORD_DEFINITIONS const char* GlobalScript_SimulationOptions_SIMULATION__OPTIONS__desc__fields[12] = {"startTime","stopTime","numberOfIntervals","stepSize","tolerance","method","fileNamePrefix","options","outputFormat","variableFilter","cflags","simflags"};
ADD_METARECORD_DEFINITIONS struct record_description GlobalScript_SimulationOptions_SIMULATION__OPTIONS__desc = {
  "GlobalScript_SimulationOptions_SIMULATION__OPTIONS",
  "GlobalScript.SimulationOptions.SIMULATION_OPTIONS",
  GlobalScript_SimulationOptions_SIMULATION__OPTIONS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description GlobalScript_SimulationOptions_SIMULATION__OPTIONS__desc;
#endif
#define GlobalScript__SIMULATION_5fOPTIONS_3dBOX12 3
#define GlobalScript__SIMULATION_5fOPTIONS(startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,fileNamePrefix,options,outputFormat,variableFilter,cflags,simflags) (mmc_mk_box(13, 3,&GlobalScript_SimulationOptions_SIMULATION__OPTIONS__desc,startTime,stopTime,numberOfIntervals,stepSize,tolerance,method,fileNamePrefix,options,outputFormat,variableFilter,cflags,simflags))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef GlobalScript_CompiledCFunction_CFunction__desc_added
#define GlobalScript_CompiledCFunction_CFunction__desc_added
ADD_METARECORD_DEFINITIONS const char* GlobalScript_CompiledCFunction_CFunction__desc__fields[5] = {"path","retType","funcHandle","buildTime","loadedFromFile"};
ADD_METARECORD_DEFINITIONS struct record_description GlobalScript_CompiledCFunction_CFunction__desc = {
  "GlobalScript_CompiledCFunction_CFunction",
  "GlobalScript.CompiledCFunction.CFunction",
  GlobalScript_CompiledCFunction_CFunction__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description GlobalScript_CompiledCFunction_CFunction__desc;
#endif
#define GlobalScript__CFunction_3dBOX5 3
#define GlobalScript__CFunction(path,retType,funcHandle,buildTime,loadedFromFile) (mmc_mk_box6(3,&GlobalScript_CompiledCFunction_CFunction__desc,path,retType,funcHandle,buildTime,loadedFromFile))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef GlobalScript_Statement_IEXP__desc_added
#define GlobalScript_Statement_IEXP__desc_added
ADD_METARECORD_DEFINITIONS const char* GlobalScript_Statement_IEXP__desc__fields[2] = {"exp","info"};
ADD_METARECORD_DEFINITIONS struct record_description GlobalScript_Statement_IEXP__desc = {
  "GlobalScript_Statement_IEXP",
  "GlobalScript.Statement.IEXP",
  GlobalScript_Statement_IEXP__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description GlobalScript_Statement_IEXP__desc;
#endif
#define GlobalScript__IEXP_3dBOX2 4
#define GlobalScript__IEXP(exp,info) (mmc_mk_box3(4,&GlobalScript_Statement_IEXP__desc,exp,info))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef GlobalScript_Statement_IALG__desc_added
#define GlobalScript_Statement_IALG__desc_added
ADD_METARECORD_DEFINITIONS const char* GlobalScript_Statement_IALG__desc__fields[1] = {"algItem"};
ADD_METARECORD_DEFINITIONS struct record_description GlobalScript_Statement_IALG__desc = {
  "GlobalScript_Statement_IALG",
  "GlobalScript.Statement.IALG",
  GlobalScript_Statement_IALG__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description GlobalScript_Statement_IALG__desc;
#endif
#define GlobalScript__IALG_3dBOX1 3
#define GlobalScript__IALG(algItem) (mmc_mk_box2(3,&GlobalScript_Statement_IALG__desc,algItem))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef GlobalScript_Statements_ISTMTS__desc_added
#define GlobalScript_Statements_ISTMTS__desc_added
ADD_METARECORD_DEFINITIONS const char* GlobalScript_Statements_ISTMTS__desc__fields[2] = {"interactiveStmtLst","semicolon"};
ADD_METARECORD_DEFINITIONS struct record_description GlobalScript_Statements_ISTMTS__desc = {
  "GlobalScript_Statements_ISTMTS",
  "GlobalScript.Statements.ISTMTS",
  GlobalScript_Statements_ISTMTS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description GlobalScript_Statements_ISTMTS__desc;
#endif
#define GlobalScript__ISTMTS_3dBOX2 3
#define GlobalScript__ISTMTS(interactiveStmtLst,semicolon) (mmc_mk_box3(3,&GlobalScript_Statements_ISTMTS__desc,interactiveStmtLst,semicolon))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef GlobalScript_InstantiatedClass_INSTCLASS__desc_added
#define GlobalScript_InstantiatedClass_INSTCLASS__desc_added
ADD_METARECORD_DEFINITIONS const char* GlobalScript_InstantiatedClass_INSTCLASS__desc__fields[3] = {"qualName","daeElementLst","env"};
ADD_METARECORD_DEFINITIONS struct record_description GlobalScript_InstantiatedClass_INSTCLASS__desc = {
  "GlobalScript_InstantiatedClass_INSTCLASS",
  "GlobalScript.InstantiatedClass.INSTCLASS",
  GlobalScript_InstantiatedClass_INSTCLASS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description GlobalScript_InstantiatedClass_INSTCLASS__desc;
#endif
#define GlobalScript__INSTCLASS_3dBOX3 3
#define GlobalScript__INSTCLASS(qualName,daeElementLst,env) (mmc_mk_box4(3,&GlobalScript_InstantiatedClass_INSTCLASS__desc,qualName,daeElementLst,env))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef GlobalScript_Variable_IVAR__desc_added
#define GlobalScript_Variable_IVAR__desc_added
ADD_METARECORD_DEFINITIONS const char* GlobalScript_Variable_IVAR__desc__fields[3] = {"varIdent","value","type_"};
ADD_METARECORD_DEFINITIONS struct record_description GlobalScript_Variable_IVAR__desc = {
  "GlobalScript_Variable_IVAR",
  "GlobalScript.Variable.IVAR",
  GlobalScript_Variable_IVAR__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description GlobalScript_Variable_IVAR__desc;
#endif
#define GlobalScript__IVAR_3dBOX3 3
#define GlobalScript__IVAR(varIdent,value,type_) (mmc_mk_box4(3,&GlobalScript_Variable_IVAR__desc,varIdent,value,type_))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef GlobalScript_LoadedFile_FILE__desc_added
#define GlobalScript_LoadedFile_FILE__desc_added
ADD_METARECORD_DEFINITIONS const char* GlobalScript_LoadedFile_FILE__desc__fields[3] = {"fileName","loadTime","classNamesQualified"};
ADD_METARECORD_DEFINITIONS struct record_description GlobalScript_LoadedFile_FILE__desc = {
  "GlobalScript_LoadedFile_FILE",
  "GlobalScript.LoadedFile.FILE",
  GlobalScript_LoadedFile_FILE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description GlobalScript_LoadedFile_FILE__desc;
#endif
#define GlobalScript__FILE_3dBOX3 3
#define GlobalScript__FILE(fileName,loadTime,classNamesQualified) (mmc_mk_box4(3,&GlobalScript_LoadedFile_FILE__desc,fileName,loadTime,classNamesQualified))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef GlobalScript_SymbolTable_SYMBOLTABLE__desc_added
#define GlobalScript_SymbolTable_SYMBOLTABLE__desc_added
ADD_METARECORD_DEFINITIONS const char* GlobalScript_SymbolTable_SYMBOLTABLE__desc__fields[6] = {"ast","explodedAst","instClsLst","lstVarVal","compiledFunctions","loadedFiles"};
ADD_METARECORD_DEFINITIONS struct record_description GlobalScript_SymbolTable_SYMBOLTABLE__desc = {
  "GlobalScript_SymbolTable_SYMBOLTABLE",
  "GlobalScript.SymbolTable.SYMBOLTABLE",
  GlobalScript_SymbolTable_SYMBOLTABLE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description GlobalScript_SymbolTable_SYMBOLTABLE__desc;
#endif
#define GlobalScript__SYMBOLTABLE_3dBOX6 3
#define GlobalScript__SYMBOLTABLE(ast,explodedAst,instClsLst,lstVarVal,compiledFunctions,loadedFiles) (mmc_mk_box7(3,&GlobalScript_SymbolTable_SYMBOLTABLE__desc,ast,explodedAst,instClsLst,lstVarVal,compiledFunctions,loadedFiles))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef GlobalScript_Component_EXTENDSITEM__desc_added
#define GlobalScript_Component_EXTENDSITEM__desc_added
ADD_METARECORD_DEFINITIONS const char* GlobalScript_Component_EXTENDSITEM__desc__fields[2] = {"the1","the2"};
ADD_METARECORD_DEFINITIONS struct record_description GlobalScript_Component_EXTENDSITEM__desc = {
  "GlobalScript_Component_EXTENDSITEM",
  "GlobalScript.Component.EXTENDSITEM",
  GlobalScript_Component_EXTENDSITEM__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description GlobalScript_Component_EXTENDSITEM__desc;
#endif
#define GlobalScript__EXTENDSITEM_3dBOX2 4
#define GlobalScript__EXTENDSITEM(the1,the2) (mmc_mk_box3(4,&GlobalScript_Component_EXTENDSITEM__desc,the1,the2))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef GlobalScript_Component_COMPONENTITEM__desc_added
#define GlobalScript_Component_COMPONENTITEM__desc_added
ADD_METARECORD_DEFINITIONS const char* GlobalScript_Component_COMPONENTITEM__desc__fields[3] = {"the1","the2","the3"};
ADD_METARECORD_DEFINITIONS struct record_description GlobalScript_Component_COMPONENTITEM__desc = {
  "GlobalScript_Component_COMPONENTITEM",
  "GlobalScript.Component.COMPONENTITEM",
  GlobalScript_Component_COMPONENTITEM__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description GlobalScript_Component_COMPONENTITEM__desc;
#endif
#define GlobalScript__COMPONENTITEM_3dBOX3 3
#define GlobalScript__COMPONENTITEM(the1,the2,the3) (mmc_mk_box4(3,&GlobalScript_Component_COMPONENTITEM__desc,the1,the2,the3))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef GlobalScript_Components_COMPONENTS__desc_added
#define GlobalScript_Components_COMPONENTS__desc_added
ADD_METARECORD_DEFINITIONS const char* GlobalScript_Components_COMPONENTS__desc__fields[2] = {"componentLst","the"};
ADD_METARECORD_DEFINITIONS struct record_description GlobalScript_Components_COMPONENTS__desc = {
  "GlobalScript_Components_COMPONENTS",
  "GlobalScript.Components.COMPONENTS",
  GlobalScript_Components_COMPONENTS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description GlobalScript_Components_COMPONENTS__desc;
#endif
#define GlobalScript__COMPONENTS_3dBOX2 3
#define GlobalScript__COMPONENTS(componentLst,the) (mmc_mk_box3(3,&GlobalScript_Components_COMPONENTS__desc,componentLst,the))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef GlobalScript_ComponentReplacement_COMPONENTREPLACEMENT__desc_added
#define GlobalScript_ComponentReplacement_COMPONENTREPLACEMENT__desc_added
ADD_METARECORD_DEFINITIONS const char* GlobalScript_ComponentReplacement_COMPONENTREPLACEMENT__desc__fields[3] = {"which1","the2","the3"};
ADD_METARECORD_DEFINITIONS struct record_description GlobalScript_ComponentReplacement_COMPONENTREPLACEMENT__desc = {
  "GlobalScript_ComponentReplacement_COMPONENTREPLACEMENT",
  "GlobalScript.ComponentReplacement.COMPONENTREPLACEMENT",
  GlobalScript_ComponentReplacement_COMPONENTREPLACEMENT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description GlobalScript_ComponentReplacement_COMPONENTREPLACEMENT__desc;
#endif
#define GlobalScript__COMPONENTREPLACEMENT_3dBOX3 3
#define GlobalScript__COMPONENTREPLACEMENT(which1,the2,the3) (mmc_mk_box4(3,&GlobalScript_ComponentReplacement_COMPONENTREPLACEMENT__desc,which1,the2,the3))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef GlobalScript_ComponentReplacementRules_COMPONENTREPLACEMENTRULES__desc_added
#define GlobalScript_ComponentReplacementRules_COMPONENTREPLACEMENTRULES__desc_added
ADD_METARECORD_DEFINITIONS const char* GlobalScript_ComponentReplacementRules_COMPONENTREPLACEMENTRULES__desc__fields[2] = {"componentReplacementLst","the"};
ADD_METARECORD_DEFINITIONS struct record_description GlobalScript_ComponentReplacementRules_COMPONENTREPLACEMENTRULES__desc = {
  "GlobalScript_ComponentReplacementRules_COMPONENTREPLACEMENTRULES",
  "GlobalScript.ComponentReplacementRules.COMPONENTREPLACEMENTRULES",
  GlobalScript_ComponentReplacementRules_COMPONENTREPLACEMENTRULES__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description GlobalScript_ComponentReplacementRules_COMPONENTREPLACEMENTRULES__desc;
#endif
#define GlobalScript__COMPONENTREPLACEMENTRULES_3dBOX2 3
#define GlobalScript__COMPONENTREPLACEMENTRULES(componentReplacementLst,the) (mmc_mk_box3(3,&GlobalScript_ComponentReplacementRules_COMPONENTREPLACEMENTRULES__desc,componentReplacementLst,the))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ForIterator_ITERATOR__desc_added
#define Absyn_ForIterator_ITERATOR__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ForIterator_ITERATOR__desc__fields[3] = {"name","guardExp","range"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ForIterator_ITERATOR__desc = {
  "Absyn_ForIterator_ITERATOR",
  "Absyn.ForIterator.ITERATOR",
  Absyn_ForIterator_ITERATOR__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ForIterator_ITERATOR__desc;
#endif
#define Absyn__ITERATOR_3dBOX3 3
#define Absyn__ITERATOR(name,guardExp,range) (mmc_mk_box4(3,&Absyn_ForIterator_ITERATOR__desc,name,guardExp,range))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Program_PROGRAM__desc_added
#define Absyn_Program_PROGRAM__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Program_PROGRAM__desc__fields[2] = {"classes","within_"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Program_PROGRAM__desc = {
  "Absyn_Program_PROGRAM",
  "Absyn.Program.PROGRAM",
  Absyn_Program_PROGRAM__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Program_PROGRAM__desc;
#endif
#define Absyn__PROGRAM_3dBOX2 3
#define Absyn__PROGRAM(classes,within_) (mmc_mk_box3(3,&Absyn_Program_PROGRAM__desc,classes,within_))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Within_TOP__desc_added
#define Absyn_Within_TOP__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Within_TOP__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Within_TOP__desc = {
  "Absyn_Within_TOP",
  "Absyn.Within.TOP",
  Absyn_Within_TOP__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Within_TOP__desc;
#endif
#define Absyn__TOP_3dBOX0 4
static const MMC_DEFSTRUCTLIT(Absyn__TOP__struct,1,4) {&Absyn_Within_TOP__desc}};
static void *Absyn__TOP = MMC_REFSTRUCTLIT(Absyn__TOP__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Within_WITHIN__desc_added
#define Absyn_Within_WITHIN__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Within_WITHIN__desc__fields[1] = {"path"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Within_WITHIN__desc = {
  "Absyn_Within_WITHIN",
  "Absyn.Within.WITHIN",
  Absyn_Within_WITHIN__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Within_WITHIN__desc;
#endif
#define Absyn__WITHIN_3dBOX1 3
#define Absyn__WITHIN(path) (mmc_mk_box2(3,&Absyn_Within_WITHIN__desc,path))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Class_CLASS__desc_added
#define Absyn_Class_CLASS__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Class_CLASS__desc__fields[7] = {"name","partialPrefix","finalPrefix","encapsulatedPrefix","restriction","body","info"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Class_CLASS__desc = {
  "Absyn_Class_CLASS",
  "Absyn.Class.CLASS",
  Absyn_Class_CLASS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Class_CLASS__desc;
#endif
#define Absyn__CLASS_3dBOX7 3
#define Absyn__CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restriction,body,info) (mmc_mk_box8(3,&Absyn_Class_CLASS__desc,name,partialPrefix,finalPrefix,encapsulatedPrefix,restriction,body,info))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ClassDef_PDER__desc_added
#define Absyn_ClassDef_PDER__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ClassDef_PDER__desc__fields[3] = {"functionName","vars","comment"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ClassDef_PDER__desc = {
  "Absyn_ClassDef_PDER",
  "Absyn.ClassDef.PDER",
  Absyn_ClassDef_PDER__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ClassDef_PDER__desc;
#endif
#define Absyn__PDER_3dBOX3 8
#define Absyn__PDER(functionName,vars,comment) (mmc_mk_box4(8,&Absyn_ClassDef_PDER__desc,functionName,vars,comment))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ClassDef_CLASS__EXTENDS__desc_added
#define Absyn_ClassDef_CLASS__EXTENDS__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ClassDef_CLASS__EXTENDS__desc__fields[5] = {"baseClassName","modifications","comment","parts","ann"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ClassDef_CLASS__EXTENDS__desc = {
  "Absyn_ClassDef_CLASS__EXTENDS",
  "Absyn.ClassDef.CLASS_EXTENDS",
  Absyn_ClassDef_CLASS__EXTENDS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ClassDef_CLASS__EXTENDS__desc;
#endif
#define Absyn__CLASS_5fEXTENDS_3dBOX5 7
#define Absyn__CLASS_5fEXTENDS(baseClassName,modifications,comment,parts,ann) (mmc_mk_box6(7,&Absyn_ClassDef_CLASS__EXTENDS__desc,baseClassName,modifications,comment,parts,ann))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ClassDef_OVERLOAD__desc_added
#define Absyn_ClassDef_OVERLOAD__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ClassDef_OVERLOAD__desc__fields[2] = {"functionNames","comment"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ClassDef_OVERLOAD__desc = {
  "Absyn_ClassDef_OVERLOAD",
  "Absyn.ClassDef.OVERLOAD",
  Absyn_ClassDef_OVERLOAD__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ClassDef_OVERLOAD__desc;
#endif
#define Absyn__OVERLOAD_3dBOX2 6
#define Absyn__OVERLOAD(functionNames,comment) (mmc_mk_box3(6,&Absyn_ClassDef_OVERLOAD__desc,functionNames,comment))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ClassDef_ENUMERATION__desc_added
#define Absyn_ClassDef_ENUMERATION__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ClassDef_ENUMERATION__desc__fields[2] = {"enumLiterals","comment"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ClassDef_ENUMERATION__desc = {
  "Absyn_ClassDef_ENUMERATION",
  "Absyn.ClassDef.ENUMERATION",
  Absyn_ClassDef_ENUMERATION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ClassDef_ENUMERATION__desc;
#endif
#define Absyn__ENUMERATION_3dBOX2 5
#define Absyn__ENUMERATION(enumLiterals,comment) (mmc_mk_box3(5,&Absyn_ClassDef_ENUMERATION__desc,enumLiterals,comment))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ClassDef_DERIVED__desc_added
#define Absyn_ClassDef_DERIVED__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ClassDef_DERIVED__desc__fields[4] = {"typeSpec","attributes","arguments","comment"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ClassDef_DERIVED__desc = {
  "Absyn_ClassDef_DERIVED",
  "Absyn.ClassDef.DERIVED",
  Absyn_ClassDef_DERIVED__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ClassDef_DERIVED__desc;
#endif
#define Absyn__DERIVED_3dBOX4 4
#define Absyn__DERIVED(typeSpec,attributes,arguments,comment) (mmc_mk_box5(4,&Absyn_ClassDef_DERIVED__desc,typeSpec,attributes,arguments,comment))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ClassDef_PARTS__desc_added
#define Absyn_ClassDef_PARTS__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ClassDef_PARTS__desc__fields[5] = {"typeVars","classAttrs","classParts","ann","comment"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ClassDef_PARTS__desc = {
  "Absyn_ClassDef_PARTS",
  "Absyn.ClassDef.PARTS",
  Absyn_ClassDef_PARTS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ClassDef_PARTS__desc;
#endif
#define Absyn__PARTS_3dBOX5 3
#define Absyn__PARTS(typeVars,classAttrs,classParts,ann,comment) (mmc_mk_box6(3,&Absyn_ClassDef_PARTS__desc,typeVars,classAttrs,classParts,ann,comment))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_TypeSpec_TCOMPLEX__desc_added
#define Absyn_TypeSpec_TCOMPLEX__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_TypeSpec_TCOMPLEX__desc__fields[3] = {"path","typeSpecs","arrayDim"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_TypeSpec_TCOMPLEX__desc = {
  "Absyn_TypeSpec_TCOMPLEX",
  "Absyn.TypeSpec.TCOMPLEX",
  Absyn_TypeSpec_TCOMPLEX__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_TypeSpec_TCOMPLEX__desc;
#endif
#define Absyn__TCOMPLEX_3dBOX3 4
#define Absyn__TCOMPLEX(path,typeSpecs,arrayDim) (mmc_mk_box4(4,&Absyn_TypeSpec_TCOMPLEX__desc,path,typeSpecs,arrayDim))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_TypeSpec_TPATH__desc_added
#define Absyn_TypeSpec_TPATH__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_TypeSpec_TPATH__desc__fields[2] = {"path","arrayDim"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_TypeSpec_TPATH__desc = {
  "Absyn_TypeSpec_TPATH",
  "Absyn.TypeSpec.TPATH",
  Absyn_TypeSpec_TPATH__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_TypeSpec_TPATH__desc;
#endif
#define Absyn__TPATH_3dBOX2 3
#define Absyn__TPATH(path,arrayDim) (mmc_mk_box3(3,&Absyn_TypeSpec_TPATH__desc,path,arrayDim))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_EnumDef_ENUM__COLON__desc_added
#define Absyn_EnumDef_ENUM__COLON__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_EnumDef_ENUM__COLON__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_EnumDef_ENUM__COLON__desc = {
  "Absyn_EnumDef_ENUM__COLON",
  "Absyn.EnumDef.ENUM_COLON",
  Absyn_EnumDef_ENUM__COLON__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_EnumDef_ENUM__COLON__desc;
#endif
#define Absyn__ENUM_5fCOLON_3dBOX0 4
static const MMC_DEFSTRUCTLIT(Absyn__ENUM_5fCOLON__struct,1,4) {&Absyn_EnumDef_ENUM__COLON__desc}};
static void *Absyn__ENUM_5fCOLON = MMC_REFSTRUCTLIT(Absyn__ENUM_5fCOLON__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_EnumDef_ENUMLITERALS__desc_added
#define Absyn_EnumDef_ENUMLITERALS__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_EnumDef_ENUMLITERALS__desc__fields[1] = {"enumLiterals"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_EnumDef_ENUMLITERALS__desc = {
  "Absyn_EnumDef_ENUMLITERALS",
  "Absyn.EnumDef.ENUMLITERALS",
  Absyn_EnumDef_ENUMLITERALS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_EnumDef_ENUMLITERALS__desc;
#endif
#define Absyn__ENUMLITERALS_3dBOX1 3
#define Absyn__ENUMLITERALS(enumLiterals) (mmc_mk_box2(3,&Absyn_EnumDef_ENUMLITERALS__desc,enumLiterals))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_EnumLiteral_ENUMLITERAL__desc_added
#define Absyn_EnumLiteral_ENUMLITERAL__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_EnumLiteral_ENUMLITERAL__desc__fields[2] = {"literal","comment"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_EnumLiteral_ENUMLITERAL__desc = {
  "Absyn_EnumLiteral_ENUMLITERAL",
  "Absyn.EnumLiteral.ENUMLITERAL",
  Absyn_EnumLiteral_ENUMLITERAL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_EnumLiteral_ENUMLITERAL__desc;
#endif
#define Absyn__ENUMLITERAL_3dBOX2 3
#define Absyn__ENUMLITERAL(literal,comment) (mmc_mk_box3(3,&Absyn_EnumLiteral_ENUMLITERAL__desc,literal,comment))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ClassPart_EXTERNAL__desc_added
#define Absyn_ClassPart_EXTERNAL__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ClassPart_EXTERNAL__desc__fields[2] = {"externalDecl","annotation_"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ClassPart_EXTERNAL__desc = {
  "Absyn_ClassPart_EXTERNAL",
  "Absyn.ClassPart.EXTERNAL",
  Absyn_ClassPart_EXTERNAL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ClassPart_EXTERNAL__desc;
#endif
#define Absyn__EXTERNAL_3dBOX2 10
#define Absyn__EXTERNAL(externalDecl,annotation_) (mmc_mk_box3(10,&Absyn_ClassPart_EXTERNAL__desc,externalDecl,annotation_))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ClassPart_INITIALALGORITHMS__desc_added
#define Absyn_ClassPart_INITIALALGORITHMS__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ClassPart_INITIALALGORITHMS__desc__fields[1] = {"contents"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ClassPart_INITIALALGORITHMS__desc = {
  "Absyn_ClassPart_INITIALALGORITHMS",
  "Absyn.ClassPart.INITIALALGORITHMS",
  Absyn_ClassPart_INITIALALGORITHMS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ClassPart_INITIALALGORITHMS__desc;
#endif
#define Absyn__INITIALALGORITHMS_3dBOX1 9
#define Absyn__INITIALALGORITHMS(contents) (mmc_mk_box2(9,&Absyn_ClassPart_INITIALALGORITHMS__desc,contents))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ClassPart_ALGORITHMS__desc_added
#define Absyn_ClassPart_ALGORITHMS__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ClassPart_ALGORITHMS__desc__fields[1] = {"contents"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ClassPart_ALGORITHMS__desc = {
  "Absyn_ClassPart_ALGORITHMS",
  "Absyn.ClassPart.ALGORITHMS",
  Absyn_ClassPart_ALGORITHMS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ClassPart_ALGORITHMS__desc;
#endif
#define Absyn__ALGORITHMS_3dBOX1 8
#define Absyn__ALGORITHMS(contents) (mmc_mk_box2(8,&Absyn_ClassPart_ALGORITHMS__desc,contents))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ClassPart_INITIALEQUATIONS__desc_added
#define Absyn_ClassPart_INITIALEQUATIONS__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ClassPart_INITIALEQUATIONS__desc__fields[1] = {"contents"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ClassPart_INITIALEQUATIONS__desc = {
  "Absyn_ClassPart_INITIALEQUATIONS",
  "Absyn.ClassPart.INITIALEQUATIONS",
  Absyn_ClassPart_INITIALEQUATIONS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ClassPart_INITIALEQUATIONS__desc;
#endif
#define Absyn__INITIALEQUATIONS_3dBOX1 7
#define Absyn__INITIALEQUATIONS(contents) (mmc_mk_box2(7,&Absyn_ClassPart_INITIALEQUATIONS__desc,contents))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ClassPart_EQUATIONS__desc_added
#define Absyn_ClassPart_EQUATIONS__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ClassPart_EQUATIONS__desc__fields[1] = {"contents"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ClassPart_EQUATIONS__desc = {
  "Absyn_ClassPart_EQUATIONS",
  "Absyn.ClassPart.EQUATIONS",
  Absyn_ClassPart_EQUATIONS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ClassPart_EQUATIONS__desc;
#endif
#define Absyn__EQUATIONS_3dBOX1 6
#define Absyn__EQUATIONS(contents) (mmc_mk_box2(6,&Absyn_ClassPart_EQUATIONS__desc,contents))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ClassPart_CONSTRAINTS__desc_added
#define Absyn_ClassPart_CONSTRAINTS__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ClassPart_CONSTRAINTS__desc__fields[1] = {"contents"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ClassPart_CONSTRAINTS__desc = {
  "Absyn_ClassPart_CONSTRAINTS",
  "Absyn.ClassPart.CONSTRAINTS",
  Absyn_ClassPart_CONSTRAINTS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ClassPart_CONSTRAINTS__desc;
#endif
#define Absyn__CONSTRAINTS_3dBOX1 5
#define Absyn__CONSTRAINTS(contents) (mmc_mk_box2(5,&Absyn_ClassPart_CONSTRAINTS__desc,contents))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ClassPart_PROTECTED__desc_added
#define Absyn_ClassPart_PROTECTED__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ClassPart_PROTECTED__desc__fields[1] = {"contents"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ClassPart_PROTECTED__desc = {
  "Absyn_ClassPart_PROTECTED",
  "Absyn.ClassPart.PROTECTED",
  Absyn_ClassPart_PROTECTED__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ClassPart_PROTECTED__desc;
#endif
#define Absyn__PROTECTED_3dBOX1 4
#define Absyn__PROTECTED(contents) (mmc_mk_box2(4,&Absyn_ClassPart_PROTECTED__desc,contents))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ClassPart_PUBLIC__desc_added
#define Absyn_ClassPart_PUBLIC__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ClassPart_PUBLIC__desc__fields[1] = {"contents"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ClassPart_PUBLIC__desc = {
  "Absyn_ClassPart_PUBLIC",
  "Absyn.ClassPart.PUBLIC",
  Absyn_ClassPart_PUBLIC__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ClassPart_PUBLIC__desc;
#endif
#define Absyn__PUBLIC_3dBOX1 3
#define Absyn__PUBLIC(contents) (mmc_mk_box2(3,&Absyn_ClassPart_PUBLIC__desc,contents))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ElementItem_LEXER__COMMENT__desc_added
#define Absyn_ElementItem_LEXER__COMMENT__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ElementItem_LEXER__COMMENT__desc__fields[1] = {"comment"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ElementItem_LEXER__COMMENT__desc = {
  "Absyn_ElementItem_LEXER__COMMENT",
  "Absyn.ElementItem.LEXER_COMMENT",
  Absyn_ElementItem_LEXER__COMMENT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ElementItem_LEXER__COMMENT__desc;
#endif
#define Absyn__LEXER_5fCOMMENT_3dBOX1 4
#define Absyn__LEXER_5fCOMMENT(comment) (mmc_mk_box2(4,&Absyn_ElementItem_LEXER__COMMENT__desc,comment))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ElementItem_ELEMENTITEM__desc_added
#define Absyn_ElementItem_ELEMENTITEM__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ElementItem_ELEMENTITEM__desc__fields[1] = {"element"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ElementItem_ELEMENTITEM__desc = {
  "Absyn_ElementItem_ELEMENTITEM",
  "Absyn.ElementItem.ELEMENTITEM",
  Absyn_ElementItem_ELEMENTITEM__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ElementItem_ELEMENTITEM__desc;
#endif
#define Absyn__ELEMENTITEM_3dBOX1 3
#define Absyn__ELEMENTITEM(element) (mmc_mk_box2(3,&Absyn_ElementItem_ELEMENTITEM__desc,element))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Element_TEXT__desc_added
#define Absyn_Element_TEXT__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Element_TEXT__desc__fields[3] = {"optName","string","info"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Element_TEXT__desc = {
  "Absyn_Element_TEXT",
  "Absyn.Element.TEXT",
  Absyn_Element_TEXT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Element_TEXT__desc;
#endif
#define Absyn__TEXT_3dBOX3 5
#define Absyn__TEXT(optName,string,info) (mmc_mk_box4(5,&Absyn_Element_TEXT__desc,optName,string,info))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Element_DEFINEUNIT__desc_added
#define Absyn_Element_DEFINEUNIT__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Element_DEFINEUNIT__desc__fields[2] = {"name","args"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Element_DEFINEUNIT__desc = {
  "Absyn_Element_DEFINEUNIT",
  "Absyn.Element.DEFINEUNIT",
  Absyn_Element_DEFINEUNIT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Element_DEFINEUNIT__desc;
#endif
#define Absyn__DEFINEUNIT_3dBOX2 4
#define Absyn__DEFINEUNIT(name,args) (mmc_mk_box3(4,&Absyn_Element_DEFINEUNIT__desc,name,args))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Element_ELEMENT__desc_added
#define Absyn_Element_ELEMENT__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Element_ELEMENT__desc__fields[6] = {"finalPrefix","redeclareKeywords","innerOuter","specification","info","constrainClass"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Element_ELEMENT__desc = {
  "Absyn_Element_ELEMENT",
  "Absyn.Element.ELEMENT",
  Absyn_Element_ELEMENT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Element_ELEMENT__desc;
#endif
#define Absyn__ELEMENT_3dBOX6 3
#define Absyn__ELEMENT(finalPrefix,redeclareKeywords,innerOuter,specification,info,constrainClass) (mmc_mk_box7(3,&Absyn_Element_ELEMENT__desc,finalPrefix,redeclareKeywords,innerOuter,specification,info,constrainClass))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ConstrainClass_CONSTRAINCLASS__desc_added
#define Absyn_ConstrainClass_CONSTRAINCLASS__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ConstrainClass_CONSTRAINCLASS__desc__fields[2] = {"elementSpec","comment"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ConstrainClass_CONSTRAINCLASS__desc = {
  "Absyn_ConstrainClass_CONSTRAINCLASS",
  "Absyn.ConstrainClass.CONSTRAINCLASS",
  Absyn_ConstrainClass_CONSTRAINCLASS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ConstrainClass_CONSTRAINCLASS__desc;
#endif
#define Absyn__CONSTRAINCLASS_3dBOX2 3
#define Absyn__CONSTRAINCLASS(elementSpec,comment) (mmc_mk_box3(3,&Absyn_ConstrainClass_CONSTRAINCLASS__desc,elementSpec,comment))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ElementSpec_COMPONENTS__desc_added
#define Absyn_ElementSpec_COMPONENTS__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ElementSpec_COMPONENTS__desc__fields[3] = {"attributes","typeSpec","components"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ElementSpec_COMPONENTS__desc = {
  "Absyn_ElementSpec_COMPONENTS",
  "Absyn.ElementSpec.COMPONENTS",
  Absyn_ElementSpec_COMPONENTS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ElementSpec_COMPONENTS__desc;
#endif
#define Absyn__COMPONENTS_3dBOX3 6
#define Absyn__COMPONENTS(attributes,typeSpec,components) (mmc_mk_box4(6,&Absyn_ElementSpec_COMPONENTS__desc,attributes,typeSpec,components))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ElementSpec_IMPORT__desc_added
#define Absyn_ElementSpec_IMPORT__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ElementSpec_IMPORT__desc__fields[3] = {"import_","comment","info"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ElementSpec_IMPORT__desc = {
  "Absyn_ElementSpec_IMPORT",
  "Absyn.ElementSpec.IMPORT",
  Absyn_ElementSpec_IMPORT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ElementSpec_IMPORT__desc;
#endif
#define Absyn__IMPORT_3dBOX3 5
#define Absyn__IMPORT(import_,comment,info) (mmc_mk_box4(5,&Absyn_ElementSpec_IMPORT__desc,import_,comment,info))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ElementSpec_EXTENDS__desc_added
#define Absyn_ElementSpec_EXTENDS__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ElementSpec_EXTENDS__desc__fields[3] = {"path","elementArg","annotationOpt"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ElementSpec_EXTENDS__desc = {
  "Absyn_ElementSpec_EXTENDS",
  "Absyn.ElementSpec.EXTENDS",
  Absyn_ElementSpec_EXTENDS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ElementSpec_EXTENDS__desc;
#endif
#define Absyn__EXTENDS_3dBOX3 4
#define Absyn__EXTENDS(path,elementArg,annotationOpt) (mmc_mk_box4(4,&Absyn_ElementSpec_EXTENDS__desc,path,elementArg,annotationOpt))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ElementSpec_CLASSDEF__desc_added
#define Absyn_ElementSpec_CLASSDEF__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ElementSpec_CLASSDEF__desc__fields[2] = {"replaceable_","class_"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ElementSpec_CLASSDEF__desc = {
  "Absyn_ElementSpec_CLASSDEF",
  "Absyn.ElementSpec.CLASSDEF",
  Absyn_ElementSpec_CLASSDEF__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ElementSpec_CLASSDEF__desc;
#endif
#define Absyn__CLASSDEF_3dBOX2 3
#define Absyn__CLASSDEF(replaceable_,class_) (mmc_mk_box3(3,&Absyn_ElementSpec_CLASSDEF__desc,replaceable_,class_))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_InnerOuter_NOT__INNER__OUTER__desc_added
#define Absyn_InnerOuter_NOT__INNER__OUTER__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_InnerOuter_NOT__INNER__OUTER__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_InnerOuter_NOT__INNER__OUTER__desc = {
  "Absyn_InnerOuter_NOT__INNER__OUTER",
  "Absyn.InnerOuter.NOT_INNER_OUTER",
  Absyn_InnerOuter_NOT__INNER__OUTER__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_InnerOuter_NOT__INNER__OUTER__desc;
#endif
#define Absyn__NOT_5fINNER_5fOUTER_3dBOX0 6
static const MMC_DEFSTRUCTLIT(Absyn__NOT_5fINNER_5fOUTER__struct,1,6) {&Absyn_InnerOuter_NOT__INNER__OUTER__desc}};
static void *Absyn__NOT_5fINNER_5fOUTER = MMC_REFSTRUCTLIT(Absyn__NOT_5fINNER_5fOUTER__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_InnerOuter_INNER__OUTER__desc_added
#define Absyn_InnerOuter_INNER__OUTER__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_InnerOuter_INNER__OUTER__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_InnerOuter_INNER__OUTER__desc = {
  "Absyn_InnerOuter_INNER__OUTER",
  "Absyn.InnerOuter.INNER_OUTER",
  Absyn_InnerOuter_INNER__OUTER__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_InnerOuter_INNER__OUTER__desc;
#endif
#define Absyn__INNER_5fOUTER_3dBOX0 5
static const MMC_DEFSTRUCTLIT(Absyn__INNER_5fOUTER__struct,1,5) {&Absyn_InnerOuter_INNER__OUTER__desc}};
static void *Absyn__INNER_5fOUTER = MMC_REFSTRUCTLIT(Absyn__INNER_5fOUTER__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_InnerOuter_OUTER__desc_added
#define Absyn_InnerOuter_OUTER__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_InnerOuter_OUTER__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_InnerOuter_OUTER__desc = {
  "Absyn_InnerOuter_OUTER",
  "Absyn.InnerOuter.OUTER",
  Absyn_InnerOuter_OUTER__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_InnerOuter_OUTER__desc;
#endif
#define Absyn__OUTER_3dBOX0 4
static const MMC_DEFSTRUCTLIT(Absyn__OUTER__struct,1,4) {&Absyn_InnerOuter_OUTER__desc}};
static void *Absyn__OUTER = MMC_REFSTRUCTLIT(Absyn__OUTER__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_InnerOuter_INNER__desc_added
#define Absyn_InnerOuter_INNER__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_InnerOuter_INNER__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_InnerOuter_INNER__desc = {
  "Absyn_InnerOuter_INNER",
  "Absyn.InnerOuter.INNER",
  Absyn_InnerOuter_INNER__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_InnerOuter_INNER__desc;
#endif
#define Absyn__INNER_3dBOX0 3
static const MMC_DEFSTRUCTLIT(Absyn__INNER__struct,1,3) {&Absyn_InnerOuter_INNER__desc}};
static void *Absyn__INNER = MMC_REFSTRUCTLIT(Absyn__INNER__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Import_GROUP__IMPORT__desc_added
#define Absyn_Import_GROUP__IMPORT__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Import_GROUP__IMPORT__desc__fields[2] = {"prefix","groups"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Import_GROUP__IMPORT__desc = {
  "Absyn_Import_GROUP__IMPORT",
  "Absyn.Import.GROUP_IMPORT",
  Absyn_Import_GROUP__IMPORT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Import_GROUP__IMPORT__desc;
#endif
#define Absyn__GROUP_5fIMPORT_3dBOX2 6
#define Absyn__GROUP_5fIMPORT(prefix,groups) (mmc_mk_box3(6,&Absyn_Import_GROUP__IMPORT__desc,prefix,groups))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Import_UNQUAL__IMPORT__desc_added
#define Absyn_Import_UNQUAL__IMPORT__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Import_UNQUAL__IMPORT__desc__fields[1] = {"path"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Import_UNQUAL__IMPORT__desc = {
  "Absyn_Import_UNQUAL__IMPORT",
  "Absyn.Import.UNQUAL_IMPORT",
  Absyn_Import_UNQUAL__IMPORT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Import_UNQUAL__IMPORT__desc;
#endif
#define Absyn__UNQUAL_5fIMPORT_3dBOX1 5
#define Absyn__UNQUAL_5fIMPORT(path) (mmc_mk_box2(5,&Absyn_Import_UNQUAL__IMPORT__desc,path))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Import_QUAL__IMPORT__desc_added
#define Absyn_Import_QUAL__IMPORT__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Import_QUAL__IMPORT__desc__fields[1] = {"path"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Import_QUAL__IMPORT__desc = {
  "Absyn_Import_QUAL__IMPORT",
  "Absyn.Import.QUAL_IMPORT",
  Absyn_Import_QUAL__IMPORT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Import_QUAL__IMPORT__desc;
#endif
#define Absyn__QUAL_5fIMPORT_3dBOX1 4
#define Absyn__QUAL_5fIMPORT(path) (mmc_mk_box2(4,&Absyn_Import_QUAL__IMPORT__desc,path))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Import_NAMED__IMPORT__desc_added
#define Absyn_Import_NAMED__IMPORT__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Import_NAMED__IMPORT__desc__fields[2] = {"name","path"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Import_NAMED__IMPORT__desc = {
  "Absyn_Import_NAMED__IMPORT",
  "Absyn.Import.NAMED_IMPORT",
  Absyn_Import_NAMED__IMPORT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Import_NAMED__IMPORT__desc;
#endif
#define Absyn__NAMED_5fIMPORT_3dBOX2 3
#define Absyn__NAMED_5fIMPORT(name,path) (mmc_mk_box3(3,&Absyn_Import_NAMED__IMPORT__desc,name,path))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_GroupImport_GROUP__IMPORT__RENAME__desc_added
#define Absyn_GroupImport_GROUP__IMPORT__RENAME__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_GroupImport_GROUP__IMPORT__RENAME__desc__fields[2] = {"rename","name"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_GroupImport_GROUP__IMPORT__RENAME__desc = {
  "Absyn_GroupImport_GROUP__IMPORT__RENAME",
  "Absyn.GroupImport.GROUP_IMPORT_RENAME",
  Absyn_GroupImport_GROUP__IMPORT__RENAME__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_GroupImport_GROUP__IMPORT__RENAME__desc;
#endif
#define Absyn__GROUP_5fIMPORT_5fRENAME_3dBOX2 4
#define Absyn__GROUP_5fIMPORT_5fRENAME(rename,name) (mmc_mk_box3(4,&Absyn_GroupImport_GROUP__IMPORT__RENAME__desc,rename,name))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_GroupImport_GROUP__IMPORT__NAME__desc_added
#define Absyn_GroupImport_GROUP__IMPORT__NAME__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_GroupImport_GROUP__IMPORT__NAME__desc__fields[1] = {"name"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_GroupImport_GROUP__IMPORT__NAME__desc = {
  "Absyn_GroupImport_GROUP__IMPORT__NAME",
  "Absyn.GroupImport.GROUP_IMPORT_NAME",
  Absyn_GroupImport_GROUP__IMPORT__NAME__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_GroupImport_GROUP__IMPORT__NAME__desc;
#endif
#define Absyn__GROUP_5fIMPORT_5fNAME_3dBOX1 3
#define Absyn__GROUP_5fIMPORT_5fNAME(name) (mmc_mk_box2(3,&Absyn_GroupImport_GROUP__IMPORT__NAME__desc,name))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ComponentItem_COMPONENTITEM__desc_added
#define Absyn_ComponentItem_COMPONENTITEM__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ComponentItem_COMPONENTITEM__desc__fields[3] = {"component","condition","comment"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ComponentItem_COMPONENTITEM__desc = {
  "Absyn_ComponentItem_COMPONENTITEM",
  "Absyn.ComponentItem.COMPONENTITEM",
  Absyn_ComponentItem_COMPONENTITEM__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ComponentItem_COMPONENTITEM__desc;
#endif
#define Absyn__COMPONENTITEM_3dBOX3 3
#define Absyn__COMPONENTITEM(component,condition,comment) (mmc_mk_box4(3,&Absyn_ComponentItem_COMPONENTITEM__desc,component,condition,comment))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Component_COMPONENT__desc_added
#define Absyn_Component_COMPONENT__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Component_COMPONENT__desc__fields[3] = {"name","arrayDim","modification"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Component_COMPONENT__desc = {
  "Absyn_Component_COMPONENT",
  "Absyn.Component.COMPONENT",
  Absyn_Component_COMPONENT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Component_COMPONENT__desc;
#endif
#define Absyn__COMPONENT_3dBOX3 3
#define Absyn__COMPONENT(name,arrayDim,modification) (mmc_mk_box4(3,&Absyn_Component_COMPONENT__desc,name,arrayDim,modification))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_EquationItem_EQUATIONITEMCOMMENT__desc_added
#define Absyn_EquationItem_EQUATIONITEMCOMMENT__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_EquationItem_EQUATIONITEMCOMMENT__desc__fields[1] = {"comment"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_EquationItem_EQUATIONITEMCOMMENT__desc = {
  "Absyn_EquationItem_EQUATIONITEMCOMMENT",
  "Absyn.EquationItem.EQUATIONITEMCOMMENT",
  Absyn_EquationItem_EQUATIONITEMCOMMENT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_EquationItem_EQUATIONITEMCOMMENT__desc;
#endif
#define Absyn__EQUATIONITEMCOMMENT_3dBOX1 4
#define Absyn__EQUATIONITEMCOMMENT(comment) (mmc_mk_box2(4,&Absyn_EquationItem_EQUATIONITEMCOMMENT__desc,comment))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_EquationItem_EQUATIONITEM__desc_added
#define Absyn_EquationItem_EQUATIONITEM__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_EquationItem_EQUATIONITEM__desc__fields[3] = {"equation_","comment","info"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_EquationItem_EQUATIONITEM__desc = {
  "Absyn_EquationItem_EQUATIONITEM",
  "Absyn.EquationItem.EQUATIONITEM",
  Absyn_EquationItem_EQUATIONITEM__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_EquationItem_EQUATIONITEM__desc;
#endif
#define Absyn__EQUATIONITEM_3dBOX3 3
#define Absyn__EQUATIONITEM(equation_,comment,info) (mmc_mk_box4(3,&Absyn_EquationItem_EQUATIONITEM__desc,equation_,comment,info))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_AlgorithmItem_ALGORITHMITEMCOMMENT__desc_added
#define Absyn_AlgorithmItem_ALGORITHMITEMCOMMENT__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_AlgorithmItem_ALGORITHMITEMCOMMENT__desc__fields[1] = {"comment"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_AlgorithmItem_ALGORITHMITEMCOMMENT__desc = {
  "Absyn_AlgorithmItem_ALGORITHMITEMCOMMENT",
  "Absyn.AlgorithmItem.ALGORITHMITEMCOMMENT",
  Absyn_AlgorithmItem_ALGORITHMITEMCOMMENT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_AlgorithmItem_ALGORITHMITEMCOMMENT__desc;
#endif
#define Absyn__ALGORITHMITEMCOMMENT_3dBOX1 4
#define Absyn__ALGORITHMITEMCOMMENT(comment) (mmc_mk_box2(4,&Absyn_AlgorithmItem_ALGORITHMITEMCOMMENT__desc,comment))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_AlgorithmItem_ALGORITHMITEM__desc_added
#define Absyn_AlgorithmItem_ALGORITHMITEM__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_AlgorithmItem_ALGORITHMITEM__desc__fields[3] = {"algorithm_","comment","info"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_AlgorithmItem_ALGORITHMITEM__desc = {
  "Absyn_AlgorithmItem_ALGORITHMITEM",
  "Absyn.AlgorithmItem.ALGORITHMITEM",
  Absyn_AlgorithmItem_ALGORITHMITEM__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_AlgorithmItem_ALGORITHMITEM__desc;
#endif
#define Absyn__ALGORITHMITEM_3dBOX3 3
#define Absyn__ALGORITHMITEM(algorithm_,comment,info) (mmc_mk_box4(3,&Absyn_AlgorithmItem_ALGORITHMITEM__desc,algorithm_,comment,info))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Equation_EQ__FAILURE__desc_added
#define Absyn_Equation_EQ__FAILURE__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Equation_EQ__FAILURE__desc__fields[1] = {"equ"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Equation_EQ__FAILURE__desc = {
  "Absyn_Equation_EQ__FAILURE",
  "Absyn.Equation.EQ_FAILURE",
  Absyn_Equation_EQ__FAILURE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Equation_EQ__FAILURE__desc;
#endif
#define Absyn__EQ_5fFAILURE_3dBOX1 9
#define Absyn__EQ_5fFAILURE(equ) (mmc_mk_box2(9,&Absyn_Equation_EQ__FAILURE__desc,equ))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Equation_EQ__NORETCALL__desc_added
#define Absyn_Equation_EQ__NORETCALL__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Equation_EQ__NORETCALL__desc__fields[2] = {"functionName","functionArgs"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Equation_EQ__NORETCALL__desc = {
  "Absyn_Equation_EQ__NORETCALL",
  "Absyn.Equation.EQ_NORETCALL",
  Absyn_Equation_EQ__NORETCALL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Equation_EQ__NORETCALL__desc;
#endif
#define Absyn__EQ_5fNORETCALL_3dBOX2 8
#define Absyn__EQ_5fNORETCALL(functionName,functionArgs) (mmc_mk_box3(8,&Absyn_Equation_EQ__NORETCALL__desc,functionName,functionArgs))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Equation_EQ__WHEN__E__desc_added
#define Absyn_Equation_EQ__WHEN__E__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Equation_EQ__WHEN__E__desc__fields[3] = {"whenExp","whenEquations","elseWhenEquations"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Equation_EQ__WHEN__E__desc = {
  "Absyn_Equation_EQ__WHEN__E",
  "Absyn.Equation.EQ_WHEN_E",
  Absyn_Equation_EQ__WHEN__E__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Equation_EQ__WHEN__E__desc;
#endif
#define Absyn__EQ_5fWHEN_5fE_3dBOX3 7
#define Absyn__EQ_5fWHEN_5fE(whenExp,whenEquations,elseWhenEquations) (mmc_mk_box4(7,&Absyn_Equation_EQ__WHEN__E__desc,whenExp,whenEquations,elseWhenEquations))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Equation_EQ__FOR__desc_added
#define Absyn_Equation_EQ__FOR__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Equation_EQ__FOR__desc__fields[2] = {"iterators","forEquations"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Equation_EQ__FOR__desc = {
  "Absyn_Equation_EQ__FOR",
  "Absyn.Equation.EQ_FOR",
  Absyn_Equation_EQ__FOR__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Equation_EQ__FOR__desc;
#endif
#define Absyn__EQ_5fFOR_3dBOX2 6
#define Absyn__EQ_5fFOR(iterators,forEquations) (mmc_mk_box3(6,&Absyn_Equation_EQ__FOR__desc,iterators,forEquations))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Equation_EQ__CONNECT__desc_added
#define Absyn_Equation_EQ__CONNECT__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Equation_EQ__CONNECT__desc__fields[2] = {"connector1","connector2"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Equation_EQ__CONNECT__desc = {
  "Absyn_Equation_EQ__CONNECT",
  "Absyn.Equation.EQ_CONNECT",
  Absyn_Equation_EQ__CONNECT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Equation_EQ__CONNECT__desc;
#endif
#define Absyn__EQ_5fCONNECT_3dBOX2 5
#define Absyn__EQ_5fCONNECT(connector1,connector2) (mmc_mk_box3(5,&Absyn_Equation_EQ__CONNECT__desc,connector1,connector2))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Equation_EQ__EQUALS__desc_added
#define Absyn_Equation_EQ__EQUALS__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Equation_EQ__EQUALS__desc__fields[2] = {"leftSide","rightSide"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Equation_EQ__EQUALS__desc = {
  "Absyn_Equation_EQ__EQUALS",
  "Absyn.Equation.EQ_EQUALS",
  Absyn_Equation_EQ__EQUALS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Equation_EQ__EQUALS__desc;
#endif
#define Absyn__EQ_5fEQUALS_3dBOX2 4
#define Absyn__EQ_5fEQUALS(leftSide,rightSide) (mmc_mk_box3(4,&Absyn_Equation_EQ__EQUALS__desc,leftSide,rightSide))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Equation_EQ__IF__desc_added
#define Absyn_Equation_EQ__IF__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Equation_EQ__IF__desc__fields[4] = {"ifExp","equationTrueItems","elseIfBranches","equationElseItems"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Equation_EQ__IF__desc = {
  "Absyn_Equation_EQ__IF",
  "Absyn.Equation.EQ_IF",
  Absyn_Equation_EQ__IF__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Equation_EQ__IF__desc;
#endif
#define Absyn__EQ_5fIF_3dBOX4 3
#define Absyn__EQ_5fIF(ifExp,equationTrueItems,elseIfBranches,equationElseItems) (mmc_mk_box5(3,&Absyn_Equation_EQ__IF__desc,ifExp,equationTrueItems,elseIfBranches,equationElseItems))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Algorithm_ALG__CONTINUE__desc_added
#define Absyn_Algorithm_ALG__CONTINUE__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Algorithm_ALG__CONTINUE__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Algorithm_ALG__CONTINUE__desc = {
  "Absyn_Algorithm_ALG__CONTINUE",
  "Absyn.Algorithm.ALG_CONTINUE",
  Absyn_Algorithm_ALG__CONTINUE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Algorithm_ALG__CONTINUE__desc;
#endif
#define Absyn__ALG_5fCONTINUE_3dBOX0 14
static const MMC_DEFSTRUCTLIT(Absyn__ALG_5fCONTINUE__struct,1,14) {&Absyn_Algorithm_ALG__CONTINUE__desc}};
static void *Absyn__ALG_5fCONTINUE = MMC_REFSTRUCTLIT(Absyn__ALG_5fCONTINUE__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Algorithm_ALG__TRY__desc_added
#define Absyn_Algorithm_ALG__TRY__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Algorithm_ALG__TRY__desc__fields[2] = {"body","elseBody"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Algorithm_ALG__TRY__desc = {
  "Absyn_Algorithm_ALG__TRY",
  "Absyn.Algorithm.ALG_TRY",
  Absyn_Algorithm_ALG__TRY__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Algorithm_ALG__TRY__desc;
#endif
#define Absyn__ALG_5fTRY_3dBOX2 13
#define Absyn__ALG_5fTRY(body,elseBody) (mmc_mk_box3(13,&Absyn_Algorithm_ALG__TRY__desc,body,elseBody))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Algorithm_ALG__FAILURE__desc_added
#define Absyn_Algorithm_ALG__FAILURE__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Algorithm_ALG__FAILURE__desc__fields[1] = {"equ"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Algorithm_ALG__FAILURE__desc = {
  "Absyn_Algorithm_ALG__FAILURE",
  "Absyn.Algorithm.ALG_FAILURE",
  Absyn_Algorithm_ALG__FAILURE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Algorithm_ALG__FAILURE__desc;
#endif
#define Absyn__ALG_5fFAILURE_3dBOX1 12
#define Absyn__ALG_5fFAILURE(equ) (mmc_mk_box2(12,&Absyn_Algorithm_ALG__FAILURE__desc,equ))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Algorithm_ALG__BREAK__desc_added
#define Absyn_Algorithm_ALG__BREAK__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Algorithm_ALG__BREAK__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Algorithm_ALG__BREAK__desc = {
  "Absyn_Algorithm_ALG__BREAK",
  "Absyn.Algorithm.ALG_BREAK",
  Absyn_Algorithm_ALG__BREAK__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Algorithm_ALG__BREAK__desc;
#endif
#define Absyn__ALG_5fBREAK_3dBOX0 11
static const MMC_DEFSTRUCTLIT(Absyn__ALG_5fBREAK__struct,1,11) {&Absyn_Algorithm_ALG__BREAK__desc}};
static void *Absyn__ALG_5fBREAK = MMC_REFSTRUCTLIT(Absyn__ALG_5fBREAK__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Algorithm_ALG__RETURN__desc_added
#define Absyn_Algorithm_ALG__RETURN__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Algorithm_ALG__RETURN__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Algorithm_ALG__RETURN__desc = {
  "Absyn_Algorithm_ALG__RETURN",
  "Absyn.Algorithm.ALG_RETURN",
  Absyn_Algorithm_ALG__RETURN__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Algorithm_ALG__RETURN__desc;
#endif
#define Absyn__ALG_5fRETURN_3dBOX0 10
static const MMC_DEFSTRUCTLIT(Absyn__ALG_5fRETURN__struct,1,10) {&Absyn_Algorithm_ALG__RETURN__desc}};
static void *Absyn__ALG_5fRETURN = MMC_REFSTRUCTLIT(Absyn__ALG_5fRETURN__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Algorithm_ALG__NORETCALL__desc_added
#define Absyn_Algorithm_ALG__NORETCALL__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Algorithm_ALG__NORETCALL__desc__fields[2] = {"functionCall","functionArgs"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Algorithm_ALG__NORETCALL__desc = {
  "Absyn_Algorithm_ALG__NORETCALL",
  "Absyn.Algorithm.ALG_NORETCALL",
  Absyn_Algorithm_ALG__NORETCALL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Algorithm_ALG__NORETCALL__desc;
#endif
#define Absyn__ALG_5fNORETCALL_3dBOX2 9
#define Absyn__ALG_5fNORETCALL(functionCall,functionArgs) (mmc_mk_box3(9,&Absyn_Algorithm_ALG__NORETCALL__desc,functionCall,functionArgs))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Algorithm_ALG__WHEN__A__desc_added
#define Absyn_Algorithm_ALG__WHEN__A__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Algorithm_ALG__WHEN__A__desc__fields[3] = {"boolExpr","whenBody","elseWhenAlgorithmBranch"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Algorithm_ALG__WHEN__A__desc = {
  "Absyn_Algorithm_ALG__WHEN__A",
  "Absyn.Algorithm.ALG_WHEN_A",
  Absyn_Algorithm_ALG__WHEN__A__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Algorithm_ALG__WHEN__A__desc;
#endif
#define Absyn__ALG_5fWHEN_5fA_3dBOX3 8
#define Absyn__ALG_5fWHEN_5fA(boolExpr,whenBody,elseWhenAlgorithmBranch) (mmc_mk_box4(8,&Absyn_Algorithm_ALG__WHEN__A__desc,boolExpr,whenBody,elseWhenAlgorithmBranch))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Algorithm_ALG__WHILE__desc_added
#define Absyn_Algorithm_ALG__WHILE__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Algorithm_ALG__WHILE__desc__fields[2] = {"boolExpr","whileBody"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Algorithm_ALG__WHILE__desc = {
  "Absyn_Algorithm_ALG__WHILE",
  "Absyn.Algorithm.ALG_WHILE",
  Absyn_Algorithm_ALG__WHILE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Algorithm_ALG__WHILE__desc;
#endif
#define Absyn__ALG_5fWHILE_3dBOX2 7
#define Absyn__ALG_5fWHILE(boolExpr,whileBody) (mmc_mk_box3(7,&Absyn_Algorithm_ALG__WHILE__desc,boolExpr,whileBody))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Algorithm_ALG__PARFOR__desc_added
#define Absyn_Algorithm_ALG__PARFOR__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Algorithm_ALG__PARFOR__desc__fields[2] = {"iterators","parforBody"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Algorithm_ALG__PARFOR__desc = {
  "Absyn_Algorithm_ALG__PARFOR",
  "Absyn.Algorithm.ALG_PARFOR",
  Absyn_Algorithm_ALG__PARFOR__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Algorithm_ALG__PARFOR__desc;
#endif
#define Absyn__ALG_5fPARFOR_3dBOX2 6
#define Absyn__ALG_5fPARFOR(iterators,parforBody) (mmc_mk_box3(6,&Absyn_Algorithm_ALG__PARFOR__desc,iterators,parforBody))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Algorithm_ALG__FOR__desc_added
#define Absyn_Algorithm_ALG__FOR__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Algorithm_ALG__FOR__desc__fields[2] = {"iterators","forBody"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Algorithm_ALG__FOR__desc = {
  "Absyn_Algorithm_ALG__FOR",
  "Absyn.Algorithm.ALG_FOR",
  Absyn_Algorithm_ALG__FOR__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Algorithm_ALG__FOR__desc;
#endif
#define Absyn__ALG_5fFOR_3dBOX2 5
#define Absyn__ALG_5fFOR(iterators,forBody) (mmc_mk_box3(5,&Absyn_Algorithm_ALG__FOR__desc,iterators,forBody))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Algorithm_ALG__IF__desc_added
#define Absyn_Algorithm_ALG__IF__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Algorithm_ALG__IF__desc__fields[4] = {"ifExp","trueBranch","elseIfAlgorithmBranch","elseBranch"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Algorithm_ALG__IF__desc = {
  "Absyn_Algorithm_ALG__IF",
  "Absyn.Algorithm.ALG_IF",
  Absyn_Algorithm_ALG__IF__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Algorithm_ALG__IF__desc;
#endif
#define Absyn__ALG_5fIF_3dBOX4 4
#define Absyn__ALG_5fIF(ifExp,trueBranch,elseIfAlgorithmBranch,elseBranch) (mmc_mk_box5(4,&Absyn_Algorithm_ALG__IF__desc,ifExp,trueBranch,elseIfAlgorithmBranch,elseBranch))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Algorithm_ALG__ASSIGN__desc_added
#define Absyn_Algorithm_ALG__ASSIGN__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Algorithm_ALG__ASSIGN__desc__fields[2] = {"assignComponent","value"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Algorithm_ALG__ASSIGN__desc = {
  "Absyn_Algorithm_ALG__ASSIGN",
  "Absyn.Algorithm.ALG_ASSIGN",
  Absyn_Algorithm_ALG__ASSIGN__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Algorithm_ALG__ASSIGN__desc;
#endif
#define Absyn__ALG_5fASSIGN_3dBOX2 3
#define Absyn__ALG_5fASSIGN(assignComponent,value) (mmc_mk_box3(3,&Absyn_Algorithm_ALG__ASSIGN__desc,assignComponent,value))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Modification_CLASSMOD__desc_added
#define Absyn_Modification_CLASSMOD__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Modification_CLASSMOD__desc__fields[2] = {"elementArgLst","eqMod"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Modification_CLASSMOD__desc = {
  "Absyn_Modification_CLASSMOD",
  "Absyn.Modification.CLASSMOD",
  Absyn_Modification_CLASSMOD__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Modification_CLASSMOD__desc;
#endif
#define Absyn__CLASSMOD_3dBOX2 3
#define Absyn__CLASSMOD(elementArgLst,eqMod) (mmc_mk_box3(3,&Absyn_Modification_CLASSMOD__desc,elementArgLst,eqMod))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_EqMod_EQMOD__desc_added
#define Absyn_EqMod_EQMOD__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_EqMod_EQMOD__desc__fields[2] = {"exp","info"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_EqMod_EQMOD__desc = {
  "Absyn_EqMod_EQMOD",
  "Absyn.EqMod.EQMOD",
  Absyn_EqMod_EQMOD__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_EqMod_EQMOD__desc;
#endif
#define Absyn__EQMOD_3dBOX2 4
#define Absyn__EQMOD(exp,info) (mmc_mk_box3(4,&Absyn_EqMod_EQMOD__desc,exp,info))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_EqMod_NOMOD__desc_added
#define Absyn_EqMod_NOMOD__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_EqMod_NOMOD__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_EqMod_NOMOD__desc = {
  "Absyn_EqMod_NOMOD",
  "Absyn.EqMod.NOMOD",
  Absyn_EqMod_NOMOD__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_EqMod_NOMOD__desc;
#endif
#define Absyn__NOMOD_3dBOX0 3
static const MMC_DEFSTRUCTLIT(Absyn__NOMOD__struct,1,3) {&Absyn_EqMod_NOMOD__desc}};
static void *Absyn__NOMOD = MMC_REFSTRUCTLIT(Absyn__NOMOD__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ElementArg_REDECLARATION__desc_added
#define Absyn_ElementArg_REDECLARATION__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ElementArg_REDECLARATION__desc__fields[6] = {"finalPrefix","redeclareKeywords","eachPrefix","elementSpec","constrainClass","info"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ElementArg_REDECLARATION__desc = {
  "Absyn_ElementArg_REDECLARATION",
  "Absyn.ElementArg.REDECLARATION",
  Absyn_ElementArg_REDECLARATION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ElementArg_REDECLARATION__desc;
#endif
#define Absyn__REDECLARATION_3dBOX6 4
#define Absyn__REDECLARATION(finalPrefix,redeclareKeywords,eachPrefix,elementSpec,constrainClass,info) (mmc_mk_box7(4,&Absyn_ElementArg_REDECLARATION__desc,finalPrefix,redeclareKeywords,eachPrefix,elementSpec,constrainClass,info))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ElementArg_MODIFICATION__desc_added
#define Absyn_ElementArg_MODIFICATION__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ElementArg_MODIFICATION__desc__fields[6] = {"finalPrefix","eachPrefix","path","modification","comment","info"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ElementArg_MODIFICATION__desc = {
  "Absyn_ElementArg_MODIFICATION",
  "Absyn.ElementArg.MODIFICATION",
  Absyn_ElementArg_MODIFICATION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ElementArg_MODIFICATION__desc;
#endif
#define Absyn__MODIFICATION_3dBOX6 3
#define Absyn__MODIFICATION(finalPrefix,eachPrefix,path,modification,comment,info) (mmc_mk_box7(3,&Absyn_ElementArg_MODIFICATION__desc,finalPrefix,eachPrefix,path,modification,comment,info))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_RedeclareKeywords_REDECLARE__REPLACEABLE__desc_added
#define Absyn_RedeclareKeywords_REDECLARE__REPLACEABLE__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_RedeclareKeywords_REDECLARE__REPLACEABLE__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_RedeclareKeywords_REDECLARE__REPLACEABLE__desc = {
  "Absyn_RedeclareKeywords_REDECLARE__REPLACEABLE",
  "Absyn.RedeclareKeywords.REDECLARE_REPLACEABLE",
  Absyn_RedeclareKeywords_REDECLARE__REPLACEABLE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_RedeclareKeywords_REDECLARE__REPLACEABLE__desc;
#endif
#define Absyn__REDECLARE_5fREPLACEABLE_3dBOX0 5
static const MMC_DEFSTRUCTLIT(Absyn__REDECLARE_5fREPLACEABLE__struct,1,5) {&Absyn_RedeclareKeywords_REDECLARE__REPLACEABLE__desc}};
static void *Absyn__REDECLARE_5fREPLACEABLE = MMC_REFSTRUCTLIT(Absyn__REDECLARE_5fREPLACEABLE__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_RedeclareKeywords_REPLACEABLE__desc_added
#define Absyn_RedeclareKeywords_REPLACEABLE__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_RedeclareKeywords_REPLACEABLE__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_RedeclareKeywords_REPLACEABLE__desc = {
  "Absyn_RedeclareKeywords_REPLACEABLE",
  "Absyn.RedeclareKeywords.REPLACEABLE",
  Absyn_RedeclareKeywords_REPLACEABLE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_RedeclareKeywords_REPLACEABLE__desc;
#endif
#define Absyn__REPLACEABLE_3dBOX0 4
static const MMC_DEFSTRUCTLIT(Absyn__REPLACEABLE__struct,1,4) {&Absyn_RedeclareKeywords_REPLACEABLE__desc}};
static void *Absyn__REPLACEABLE = MMC_REFSTRUCTLIT(Absyn__REPLACEABLE__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_RedeclareKeywords_REDECLARE__desc_added
#define Absyn_RedeclareKeywords_REDECLARE__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_RedeclareKeywords_REDECLARE__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_RedeclareKeywords_REDECLARE__desc = {
  "Absyn_RedeclareKeywords_REDECLARE",
  "Absyn.RedeclareKeywords.REDECLARE",
  Absyn_RedeclareKeywords_REDECLARE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_RedeclareKeywords_REDECLARE__desc;
#endif
#define Absyn__REDECLARE_3dBOX0 3
static const MMC_DEFSTRUCTLIT(Absyn__REDECLARE__struct,1,3) {&Absyn_RedeclareKeywords_REDECLARE__desc}};
static void *Absyn__REDECLARE = MMC_REFSTRUCTLIT(Absyn__REDECLARE__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Each_NON__EACH__desc_added
#define Absyn_Each_NON__EACH__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Each_NON__EACH__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Each_NON__EACH__desc = {
  "Absyn_Each_NON__EACH",
  "Absyn.Each.NON_EACH",
  Absyn_Each_NON__EACH__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Each_NON__EACH__desc;
#endif
#define Absyn__NON_5fEACH_3dBOX0 4
static const MMC_DEFSTRUCTLIT(Absyn__NON_5fEACH__struct,1,4) {&Absyn_Each_NON__EACH__desc}};
static void *Absyn__NON_5fEACH = MMC_REFSTRUCTLIT(Absyn__NON_5fEACH__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Each_EACH__desc_added
#define Absyn_Each_EACH__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Each_EACH__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Each_EACH__desc = {
  "Absyn_Each_EACH",
  "Absyn.Each.EACH",
  Absyn_Each_EACH__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Each_EACH__desc;
#endif
#define Absyn__EACH_3dBOX0 3
static const MMC_DEFSTRUCTLIT(Absyn__EACH__struct,1,3) {&Absyn_Each_EACH__desc}};
static void *Absyn__EACH = MMC_REFSTRUCTLIT(Absyn__EACH__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ElementAttributes_ATTR__desc_added
#define Absyn_ElementAttributes_ATTR__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ElementAttributes_ATTR__desc__fields[6] = {"flowPrefix","streamPrefix","parallelism","variability","direction","arrayDim"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ElementAttributes_ATTR__desc = {
  "Absyn_ElementAttributes_ATTR",
  "Absyn.ElementAttributes.ATTR",
  Absyn_ElementAttributes_ATTR__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ElementAttributes_ATTR__desc;
#endif
#define Absyn__ATTR_3dBOX6 3
#define Absyn__ATTR(flowPrefix,streamPrefix,parallelism,variability,direction,arrayDim) (mmc_mk_box7(3,&Absyn_ElementAttributes_ATTR__desc,flowPrefix,streamPrefix,parallelism,variability,direction,arrayDim))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Parallelism_NON__PARALLEL__desc_added
#define Absyn_Parallelism_NON__PARALLEL__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Parallelism_NON__PARALLEL__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Parallelism_NON__PARALLEL__desc = {
  "Absyn_Parallelism_NON__PARALLEL",
  "Absyn.Parallelism.NON_PARALLEL",
  Absyn_Parallelism_NON__PARALLEL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Parallelism_NON__PARALLEL__desc;
#endif
#define Absyn__NON_5fPARALLEL_3dBOX0 5
static const MMC_DEFSTRUCTLIT(Absyn__NON_5fPARALLEL__struct,1,5) {&Absyn_Parallelism_NON__PARALLEL__desc}};
static void *Absyn__NON_5fPARALLEL = MMC_REFSTRUCTLIT(Absyn__NON_5fPARALLEL__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Parallelism_PARLOCAL__desc_added
#define Absyn_Parallelism_PARLOCAL__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Parallelism_PARLOCAL__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Parallelism_PARLOCAL__desc = {
  "Absyn_Parallelism_PARLOCAL",
  "Absyn.Parallelism.PARLOCAL",
  Absyn_Parallelism_PARLOCAL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Parallelism_PARLOCAL__desc;
#endif
#define Absyn__PARLOCAL_3dBOX0 4
static const MMC_DEFSTRUCTLIT(Absyn__PARLOCAL__struct,1,4) {&Absyn_Parallelism_PARLOCAL__desc}};
static void *Absyn__PARLOCAL = MMC_REFSTRUCTLIT(Absyn__PARLOCAL__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Parallelism_PARGLOBAL__desc_added
#define Absyn_Parallelism_PARGLOBAL__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Parallelism_PARGLOBAL__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Parallelism_PARGLOBAL__desc = {
  "Absyn_Parallelism_PARGLOBAL",
  "Absyn.Parallelism.PARGLOBAL",
  Absyn_Parallelism_PARGLOBAL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Parallelism_PARGLOBAL__desc;
#endif
#define Absyn__PARGLOBAL_3dBOX0 3
static const MMC_DEFSTRUCTLIT(Absyn__PARGLOBAL__struct,1,3) {&Absyn_Parallelism_PARGLOBAL__desc}};
static void *Absyn__PARGLOBAL = MMC_REFSTRUCTLIT(Absyn__PARGLOBAL__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_FlowStream_NOT__FLOW__STREAM__desc_added
#define Absyn_FlowStream_NOT__FLOW__STREAM__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_FlowStream_NOT__FLOW__STREAM__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_FlowStream_NOT__FLOW__STREAM__desc = {
  "Absyn_FlowStream_NOT__FLOW__STREAM",
  "Absyn.FlowStream.NOT_FLOW_STREAM",
  Absyn_FlowStream_NOT__FLOW__STREAM__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_FlowStream_NOT__FLOW__STREAM__desc;
#endif
#define Absyn__NOT_5fFLOW_5fSTREAM_3dBOX0 5
static const MMC_DEFSTRUCTLIT(Absyn__NOT_5fFLOW_5fSTREAM__struct,1,5) {&Absyn_FlowStream_NOT__FLOW__STREAM__desc}};
static void *Absyn__NOT_5fFLOW_5fSTREAM = MMC_REFSTRUCTLIT(Absyn__NOT_5fFLOW_5fSTREAM__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_FlowStream_STREAM__desc_added
#define Absyn_FlowStream_STREAM__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_FlowStream_STREAM__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_FlowStream_STREAM__desc = {
  "Absyn_FlowStream_STREAM",
  "Absyn.FlowStream.STREAM",
  Absyn_FlowStream_STREAM__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_FlowStream_STREAM__desc;
#endif
#define Absyn__STREAM_3dBOX0 4
static const MMC_DEFSTRUCTLIT(Absyn__STREAM__struct,1,4) {&Absyn_FlowStream_STREAM__desc}};
static void *Absyn__STREAM = MMC_REFSTRUCTLIT(Absyn__STREAM__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_FlowStream_FLOW__desc_added
#define Absyn_FlowStream_FLOW__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_FlowStream_FLOW__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_FlowStream_FLOW__desc = {
  "Absyn_FlowStream_FLOW",
  "Absyn.FlowStream.FLOW",
  Absyn_FlowStream_FLOW__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_FlowStream_FLOW__desc;
#endif
#define Absyn__FLOW_3dBOX0 3
static const MMC_DEFSTRUCTLIT(Absyn__FLOW__struct,1,3) {&Absyn_FlowStream_FLOW__desc}};
static void *Absyn__FLOW = MMC_REFSTRUCTLIT(Absyn__FLOW__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Variability_CONST__desc_added
#define Absyn_Variability_CONST__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Variability_CONST__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Variability_CONST__desc = {
  "Absyn_Variability_CONST",
  "Absyn.Variability.CONST",
  Absyn_Variability_CONST__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Variability_CONST__desc;
#endif
#define Absyn__CONST_3dBOX0 6
static const MMC_DEFSTRUCTLIT(Absyn__CONST__struct,1,6) {&Absyn_Variability_CONST__desc}};
static void *Absyn__CONST = MMC_REFSTRUCTLIT(Absyn__CONST__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Variability_PARAM__desc_added
#define Absyn_Variability_PARAM__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Variability_PARAM__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Variability_PARAM__desc = {
  "Absyn_Variability_PARAM",
  "Absyn.Variability.PARAM",
  Absyn_Variability_PARAM__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Variability_PARAM__desc;
#endif
#define Absyn__PARAM_3dBOX0 5
static const MMC_DEFSTRUCTLIT(Absyn__PARAM__struct,1,5) {&Absyn_Variability_PARAM__desc}};
static void *Absyn__PARAM = MMC_REFSTRUCTLIT(Absyn__PARAM__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Variability_DISCRETE__desc_added
#define Absyn_Variability_DISCRETE__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Variability_DISCRETE__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Variability_DISCRETE__desc = {
  "Absyn_Variability_DISCRETE",
  "Absyn.Variability.DISCRETE",
  Absyn_Variability_DISCRETE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Variability_DISCRETE__desc;
#endif
#define Absyn__DISCRETE_3dBOX0 4
static const MMC_DEFSTRUCTLIT(Absyn__DISCRETE__struct,1,4) {&Absyn_Variability_DISCRETE__desc}};
static void *Absyn__DISCRETE = MMC_REFSTRUCTLIT(Absyn__DISCRETE__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Variability_VAR__desc_added
#define Absyn_Variability_VAR__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Variability_VAR__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Variability_VAR__desc = {
  "Absyn_Variability_VAR",
  "Absyn.Variability.VAR",
  Absyn_Variability_VAR__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Variability_VAR__desc;
#endif
#define Absyn__VAR_3dBOX0 3
static const MMC_DEFSTRUCTLIT(Absyn__VAR__struct,1,3) {&Absyn_Variability_VAR__desc}};
static void *Absyn__VAR = MMC_REFSTRUCTLIT(Absyn__VAR__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Direction_BIDIR__desc_added
#define Absyn_Direction_BIDIR__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Direction_BIDIR__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Direction_BIDIR__desc = {
  "Absyn_Direction_BIDIR",
  "Absyn.Direction.BIDIR",
  Absyn_Direction_BIDIR__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Direction_BIDIR__desc;
#endif
#define Absyn__BIDIR_3dBOX0 5
static const MMC_DEFSTRUCTLIT(Absyn__BIDIR__struct,1,5) {&Absyn_Direction_BIDIR__desc}};
static void *Absyn__BIDIR = MMC_REFSTRUCTLIT(Absyn__BIDIR__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Direction_OUTPUT__desc_added
#define Absyn_Direction_OUTPUT__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Direction_OUTPUT__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Direction_OUTPUT__desc = {
  "Absyn_Direction_OUTPUT",
  "Absyn.Direction.OUTPUT",
  Absyn_Direction_OUTPUT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Direction_OUTPUT__desc;
#endif
#define Absyn__OUTPUT_3dBOX0 4
static const MMC_DEFSTRUCTLIT(Absyn__OUTPUT__struct,1,4) {&Absyn_Direction_OUTPUT__desc}};
static void *Absyn__OUTPUT = MMC_REFSTRUCTLIT(Absyn__OUTPUT__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Direction_INPUT__desc_added
#define Absyn_Direction_INPUT__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Direction_INPUT__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Direction_INPUT__desc = {
  "Absyn_Direction_INPUT",
  "Absyn.Direction.INPUT",
  Absyn_Direction_INPUT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Direction_INPUT__desc;
#endif
#define Absyn__INPUT_3dBOX0 3
static const MMC_DEFSTRUCTLIT(Absyn__INPUT__struct,1,3) {&Absyn_Direction_INPUT__desc}};
static void *Absyn__INPUT = MMC_REFSTRUCTLIT(Absyn__INPUT__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_DOT__desc_added
#define Absyn_Exp_DOT__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_DOT__desc__fields[2] = {"exp","index"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_DOT__desc = {
  "Absyn_Exp_DOT",
  "Absyn.Exp.DOT",
  Absyn_Exp_DOT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_DOT__desc;
#endif
#define Absyn__DOT_3dBOX2 26
#define Absyn__DOT(exp,index) (mmc_mk_box3(26,&Absyn_Exp_DOT__desc,exp,index))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_LIST__desc_added
#define Absyn_Exp_LIST__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_LIST__desc__fields[1] = {"exps"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_LIST__desc = {
  "Absyn_Exp_LIST",
  "Absyn.Exp.LIST",
  Absyn_Exp_LIST__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_LIST__desc;
#endif
#define Absyn__LIST_3dBOX1 25
#define Absyn__LIST(exps) (mmc_mk_box2(25,&Absyn_Exp_LIST__desc,exps))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_MATCHEXP__desc_added
#define Absyn_Exp_MATCHEXP__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_MATCHEXP__desc__fields[5] = {"matchTy","inputExp","localDecls","cases","comment"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_MATCHEXP__desc = {
  "Absyn_Exp_MATCHEXP",
  "Absyn.Exp.MATCHEXP",
  Absyn_Exp_MATCHEXP__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_MATCHEXP__desc;
#endif
#define Absyn__MATCHEXP_3dBOX5 24
#define Absyn__MATCHEXP(matchTy,inputExp,localDecls,cases,comment) (mmc_mk_box6(24,&Absyn_Exp_MATCHEXP__desc,matchTy,inputExp,localDecls,cases,comment))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_CONS__desc_added
#define Absyn_Exp_CONS__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_CONS__desc__fields[2] = {"head","rest"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_CONS__desc = {
  "Absyn_Exp_CONS",
  "Absyn.Exp.CONS",
  Absyn_Exp_CONS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_CONS__desc;
#endif
#define Absyn__CONS_3dBOX2 23
#define Absyn__CONS(head,rest) (mmc_mk_box3(23,&Absyn_Exp_CONS__desc,head,rest))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_AS__desc_added
#define Absyn_Exp_AS__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_AS__desc__fields[2] = {"id","exp"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_AS__desc = {
  "Absyn_Exp_AS",
  "Absyn.Exp.AS",
  Absyn_Exp_AS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_AS__desc;
#endif
#define Absyn__AS_3dBOX2 22
#define Absyn__AS(id,exp) (mmc_mk_box3(22,&Absyn_Exp_AS__desc,id,exp))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_CODE__desc_added
#define Absyn_Exp_CODE__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_CODE__desc__fields[1] = {"code"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_CODE__desc = {
  "Absyn_Exp_CODE",
  "Absyn.Exp.CODE",
  Absyn_Exp_CODE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_CODE__desc;
#endif
#define Absyn__CODE_3dBOX1 21
#define Absyn__CODE(code) (mmc_mk_box2(21,&Absyn_Exp_CODE__desc,code))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_END__desc_added
#define Absyn_Exp_END__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_END__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_END__desc = {
  "Absyn_Exp_END",
  "Absyn.Exp.END",
  Absyn_Exp_END__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_END__desc;
#endif
#define Absyn__END_3dBOX0 20
static const MMC_DEFSTRUCTLIT(Absyn__END__struct,1,20) {&Absyn_Exp_END__desc}};
static void *Absyn__END = MMC_REFSTRUCTLIT(Absyn__END__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_TUPLE__desc_added
#define Absyn_Exp_TUPLE__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_TUPLE__desc__fields[1] = {"expressions"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_TUPLE__desc = {
  "Absyn_Exp_TUPLE",
  "Absyn.Exp.TUPLE",
  Absyn_Exp_TUPLE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_TUPLE__desc;
#endif
#define Absyn__TUPLE_3dBOX1 19
#define Absyn__TUPLE(expressions) (mmc_mk_box2(19,&Absyn_Exp_TUPLE__desc,expressions))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_RANGE__desc_added
#define Absyn_Exp_RANGE__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_RANGE__desc__fields[3] = {"start","step","stop"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_RANGE__desc = {
  "Absyn_Exp_RANGE",
  "Absyn.Exp.RANGE",
  Absyn_Exp_RANGE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_RANGE__desc;
#endif
#define Absyn__RANGE_3dBOX3 18
#define Absyn__RANGE(start,step,stop) (mmc_mk_box4(18,&Absyn_Exp_RANGE__desc,start,step,stop))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_MATRIX__desc_added
#define Absyn_Exp_MATRIX__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_MATRIX__desc__fields[1] = {"matrix"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_MATRIX__desc = {
  "Absyn_Exp_MATRIX",
  "Absyn.Exp.MATRIX",
  Absyn_Exp_MATRIX__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_MATRIX__desc;
#endif
#define Absyn__MATRIX_3dBOX1 17
#define Absyn__MATRIX(matrix) (mmc_mk_box2(17,&Absyn_Exp_MATRIX__desc,matrix))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_ARRAY__desc_added
#define Absyn_Exp_ARRAY__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_ARRAY__desc__fields[1] = {"arrayExp"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_ARRAY__desc = {
  "Absyn_Exp_ARRAY",
  "Absyn.Exp.ARRAY",
  Absyn_Exp_ARRAY__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_ARRAY__desc;
#endif
#define Absyn__ARRAY_3dBOX1 16
#define Absyn__ARRAY(arrayExp) (mmc_mk_box2(16,&Absyn_Exp_ARRAY__desc,arrayExp))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_PARTEVALFUNCTION__desc_added
#define Absyn_Exp_PARTEVALFUNCTION__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_PARTEVALFUNCTION__desc__fields[2] = {"function_","functionArgs"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_PARTEVALFUNCTION__desc = {
  "Absyn_Exp_PARTEVALFUNCTION",
  "Absyn.Exp.PARTEVALFUNCTION",
  Absyn_Exp_PARTEVALFUNCTION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_PARTEVALFUNCTION__desc;
#endif
#define Absyn__PARTEVALFUNCTION_3dBOX2 15
#define Absyn__PARTEVALFUNCTION(function_,functionArgs) (mmc_mk_box3(15,&Absyn_Exp_PARTEVALFUNCTION__desc,function_,functionArgs))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_CALL__desc_added
#define Absyn_Exp_CALL__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_CALL__desc__fields[2] = {"function_","functionArgs"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_CALL__desc = {
  "Absyn_Exp_CALL",
  "Absyn.Exp.CALL",
  Absyn_Exp_CALL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_CALL__desc;
#endif
#define Absyn__CALL_3dBOX2 14
#define Absyn__CALL(function_,functionArgs) (mmc_mk_box3(14,&Absyn_Exp_CALL__desc,function_,functionArgs))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_IFEXP__desc_added
#define Absyn_Exp_IFEXP__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_IFEXP__desc__fields[4] = {"ifExp","trueBranch","elseBranch","elseIfBranch"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_IFEXP__desc = {
  "Absyn_Exp_IFEXP",
  "Absyn.Exp.IFEXP",
  Absyn_Exp_IFEXP__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_IFEXP__desc;
#endif
#define Absyn__IFEXP_3dBOX4 13
#define Absyn__IFEXP(ifExp,trueBranch,elseBranch,elseIfBranch) (mmc_mk_box5(13,&Absyn_Exp_IFEXP__desc,ifExp,trueBranch,elseBranch,elseIfBranch))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_RELATION__desc_added
#define Absyn_Exp_RELATION__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_RELATION__desc__fields[3] = {"exp1","op","exp2"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_RELATION__desc = {
  "Absyn_Exp_RELATION",
  "Absyn.Exp.RELATION",
  Absyn_Exp_RELATION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_RELATION__desc;
#endif
#define Absyn__RELATION_3dBOX3 12
#define Absyn__RELATION(exp1,op,exp2) (mmc_mk_box4(12,&Absyn_Exp_RELATION__desc,exp1,op,exp2))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_LUNARY__desc_added
#define Absyn_Exp_LUNARY__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_LUNARY__desc__fields[2] = {"op","exp"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_LUNARY__desc = {
  "Absyn_Exp_LUNARY",
  "Absyn.Exp.LUNARY",
  Absyn_Exp_LUNARY__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_LUNARY__desc;
#endif
#define Absyn__LUNARY_3dBOX2 11
#define Absyn__LUNARY(op,exp) (mmc_mk_box3(11,&Absyn_Exp_LUNARY__desc,op,exp))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_LBINARY__desc_added
#define Absyn_Exp_LBINARY__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_LBINARY__desc__fields[3] = {"exp1","op","exp2"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_LBINARY__desc = {
  "Absyn_Exp_LBINARY",
  "Absyn.Exp.LBINARY",
  Absyn_Exp_LBINARY__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_LBINARY__desc;
#endif
#define Absyn__LBINARY_3dBOX3 10
#define Absyn__LBINARY(exp1,op,exp2) (mmc_mk_box4(10,&Absyn_Exp_LBINARY__desc,exp1,op,exp2))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_UNARY__desc_added
#define Absyn_Exp_UNARY__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_UNARY__desc__fields[2] = {"op","exp"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_UNARY__desc = {
  "Absyn_Exp_UNARY",
  "Absyn.Exp.UNARY",
  Absyn_Exp_UNARY__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_UNARY__desc;
#endif
#define Absyn__UNARY_3dBOX2 9
#define Absyn__UNARY(op,exp) (mmc_mk_box3(9,&Absyn_Exp_UNARY__desc,op,exp))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_BINARY__desc_added
#define Absyn_Exp_BINARY__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_BINARY__desc__fields[3] = {"exp1","op","exp2"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_BINARY__desc = {
  "Absyn_Exp_BINARY",
  "Absyn.Exp.BINARY",
  Absyn_Exp_BINARY__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_BINARY__desc;
#endif
#define Absyn__BINARY_3dBOX3 8
#define Absyn__BINARY(exp1,op,exp2) (mmc_mk_box4(8,&Absyn_Exp_BINARY__desc,exp1,op,exp2))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_BOOL__desc_added
#define Absyn_Exp_BOOL__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_BOOL__desc__fields[1] = {"value"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_BOOL__desc = {
  "Absyn_Exp_BOOL",
  "Absyn.Exp.BOOL",
  Absyn_Exp_BOOL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_BOOL__desc;
#endif
#define Absyn__BOOL_3dBOX1 7
#define Absyn__BOOL(value) (mmc_mk_box2(7,&Absyn_Exp_BOOL__desc,value))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_STRING__desc_added
#define Absyn_Exp_STRING__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_STRING__desc__fields[1] = {"value"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_STRING__desc = {
  "Absyn_Exp_STRING",
  "Absyn.Exp.STRING",
  Absyn_Exp_STRING__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_STRING__desc;
#endif
#define Absyn__STRING_3dBOX1 6
#define Absyn__STRING(value) (mmc_mk_box2(6,&Absyn_Exp_STRING__desc,value))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_CREF__desc_added
#define Absyn_Exp_CREF__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_CREF__desc__fields[1] = {"componentRef"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_CREF__desc = {
  "Absyn_Exp_CREF",
  "Absyn.Exp.CREF",
  Absyn_Exp_CREF__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_CREF__desc;
#endif
#define Absyn__CREF_3dBOX1 5
#define Absyn__CREF(componentRef) (mmc_mk_box2(5,&Absyn_Exp_CREF__desc,componentRef))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_REAL__desc_added
#define Absyn_Exp_REAL__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_REAL__desc__fields[1] = {"value"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_REAL__desc = {
  "Absyn_Exp_REAL",
  "Absyn.Exp.REAL",
  Absyn_Exp_REAL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_REAL__desc;
#endif
#define Absyn__REAL_3dBOX1 4
#define Absyn__REAL(value) (mmc_mk_box2(4,&Absyn_Exp_REAL__desc,value))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Exp_INTEGER__desc_added
#define Absyn_Exp_INTEGER__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Exp_INTEGER__desc__fields[1] = {"value"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Exp_INTEGER__desc = {
  "Absyn_Exp_INTEGER",
  "Absyn.Exp.INTEGER",
  Absyn_Exp_INTEGER__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Exp_INTEGER__desc;
#endif
#define Absyn__INTEGER_3dBOX1 3
#define Absyn__INTEGER(value) (mmc_mk_box2(3,&Absyn_Exp_INTEGER__desc,value))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Case_ELSE__desc_added
#define Absyn_Case_ELSE__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Case_ELSE__desc__fields[6] = {"localDecls","classPart","result","resultInfo","comment","info"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Case_ELSE__desc = {
  "Absyn_Case_ELSE",
  "Absyn.Case.ELSE",
  Absyn_Case_ELSE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Case_ELSE__desc;
#endif
#define Absyn__ELSE_3dBOX6 4
#define Absyn__ELSE(localDecls,classPart,result,resultInfo,comment,info) (mmc_mk_box7(4,&Absyn_Case_ELSE__desc,localDecls,classPart,result,resultInfo,comment,info))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Case_CASE__desc_added
#define Absyn_Case_CASE__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Case_CASE__desc__fields[9] = {"pattern","patternGuard","patternInfo","localDecls","classPart","result","resultInfo","comment","info"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Case_CASE__desc = {
  "Absyn_Case_CASE",
  "Absyn.Case.CASE",
  Absyn_Case_CASE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Case_CASE__desc;
#endif
#define Absyn__CASE_3dBOX9 3
#define Absyn__CASE(pattern,patternGuard,patternInfo,localDecls,classPart,result,resultInfo,comment,info) (mmc_mk_box(10, 3,&Absyn_Case_CASE__desc,pattern,patternGuard,patternInfo,localDecls,classPart,result,resultInfo,comment,info))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_MatchType_MATCHCONTINUE__desc_added
#define Absyn_MatchType_MATCHCONTINUE__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_MatchType_MATCHCONTINUE__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_MatchType_MATCHCONTINUE__desc = {
  "Absyn_MatchType_MATCHCONTINUE",
  "Absyn.MatchType.MATCHCONTINUE",
  Absyn_MatchType_MATCHCONTINUE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_MatchType_MATCHCONTINUE__desc;
#endif
#define Absyn__MATCHCONTINUE_3dBOX0 4
static const MMC_DEFSTRUCTLIT(Absyn__MATCHCONTINUE__struct,1,4) {&Absyn_MatchType_MATCHCONTINUE__desc}};
static void *Absyn__MATCHCONTINUE = MMC_REFSTRUCTLIT(Absyn__MATCHCONTINUE__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_MatchType_MATCH__desc_added
#define Absyn_MatchType_MATCH__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_MatchType_MATCH__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_MatchType_MATCH__desc = {
  "Absyn_MatchType_MATCH",
  "Absyn.MatchType.MATCH",
  Absyn_MatchType_MATCH__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_MatchType_MATCH__desc;
#endif
#define Absyn__MATCH_3dBOX0 3
static const MMC_DEFSTRUCTLIT(Absyn__MATCH__struct,1,3) {&Absyn_MatchType_MATCH__desc}};
static void *Absyn__MATCH = MMC_REFSTRUCTLIT(Absyn__MATCH__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_CodeNode_C__MODIFICATION__desc_added
#define Absyn_CodeNode_C__MODIFICATION__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_CodeNode_C__MODIFICATION__desc__fields[1] = {"modification"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_CodeNode_C__MODIFICATION__desc = {
  "Absyn_CodeNode_C__MODIFICATION",
  "Absyn.CodeNode.C_MODIFICATION",
  Absyn_CodeNode_C__MODIFICATION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_CodeNode_C__MODIFICATION__desc;
#endif
#define Absyn__C_5fMODIFICATION_3dBOX1 10
#define Absyn__C_5fMODIFICATION(modification) (mmc_mk_box2(10,&Absyn_CodeNode_C__MODIFICATION__desc,modification))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_CodeNode_C__EXPRESSION__desc_added
#define Absyn_CodeNode_C__EXPRESSION__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_CodeNode_C__EXPRESSION__desc__fields[1] = {"exp"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_CodeNode_C__EXPRESSION__desc = {
  "Absyn_CodeNode_C__EXPRESSION",
  "Absyn.CodeNode.C_EXPRESSION",
  Absyn_CodeNode_C__EXPRESSION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_CodeNode_C__EXPRESSION__desc;
#endif
#define Absyn__C_5fEXPRESSION_3dBOX1 9
#define Absyn__C_5fEXPRESSION(exp) (mmc_mk_box2(9,&Absyn_CodeNode_C__EXPRESSION__desc,exp))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_CodeNode_C__ELEMENT__desc_added
#define Absyn_CodeNode_C__ELEMENT__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_CodeNode_C__ELEMENT__desc__fields[1] = {"element"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_CodeNode_C__ELEMENT__desc = {
  "Absyn_CodeNode_C__ELEMENT",
  "Absyn.CodeNode.C_ELEMENT",
  Absyn_CodeNode_C__ELEMENT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_CodeNode_C__ELEMENT__desc;
#endif
#define Absyn__C_5fELEMENT_3dBOX1 8
#define Absyn__C_5fELEMENT(element) (mmc_mk_box2(8,&Absyn_CodeNode_C__ELEMENT__desc,element))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_CodeNode_C__ALGORITHMSECTION__desc_added
#define Absyn_CodeNode_C__ALGORITHMSECTION__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_CodeNode_C__ALGORITHMSECTION__desc__fields[2] = {"boolean","algorithmItemLst"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_CodeNode_C__ALGORITHMSECTION__desc = {
  "Absyn_CodeNode_C__ALGORITHMSECTION",
  "Absyn.CodeNode.C_ALGORITHMSECTION",
  Absyn_CodeNode_C__ALGORITHMSECTION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_CodeNode_C__ALGORITHMSECTION__desc;
#endif
#define Absyn__C_5fALGORITHMSECTION_3dBOX2 7
#define Absyn__C_5fALGORITHMSECTION(boolean,algorithmItemLst) (mmc_mk_box3(7,&Absyn_CodeNode_C__ALGORITHMSECTION__desc,boolean,algorithmItemLst))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_CodeNode_C__EQUATIONSECTION__desc_added
#define Absyn_CodeNode_C__EQUATIONSECTION__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_CodeNode_C__EQUATIONSECTION__desc__fields[2] = {"boolean","equationItemLst"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_CodeNode_C__EQUATIONSECTION__desc = {
  "Absyn_CodeNode_C__EQUATIONSECTION",
  "Absyn.CodeNode.C_EQUATIONSECTION",
  Absyn_CodeNode_C__EQUATIONSECTION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_CodeNode_C__EQUATIONSECTION__desc;
#endif
#define Absyn__C_5fEQUATIONSECTION_3dBOX2 6
#define Absyn__C_5fEQUATIONSECTION(boolean,equationItemLst) (mmc_mk_box3(6,&Absyn_CodeNode_C__EQUATIONSECTION__desc,boolean,equationItemLst))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_CodeNode_C__CONSTRAINTSECTION__desc_added
#define Absyn_CodeNode_C__CONSTRAINTSECTION__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_CodeNode_C__CONSTRAINTSECTION__desc__fields[2] = {"boolean","equationItemLst"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_CodeNode_C__CONSTRAINTSECTION__desc = {
  "Absyn_CodeNode_C__CONSTRAINTSECTION",
  "Absyn.CodeNode.C_CONSTRAINTSECTION",
  Absyn_CodeNode_C__CONSTRAINTSECTION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_CodeNode_C__CONSTRAINTSECTION__desc;
#endif
#define Absyn__C_5fCONSTRAINTSECTION_3dBOX2 5
#define Absyn__C_5fCONSTRAINTSECTION(boolean,equationItemLst) (mmc_mk_box3(5,&Absyn_CodeNode_C__CONSTRAINTSECTION__desc,boolean,equationItemLst))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_CodeNode_C__VARIABLENAME__desc_added
#define Absyn_CodeNode_C__VARIABLENAME__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_CodeNode_C__VARIABLENAME__desc__fields[1] = {"componentRef"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_CodeNode_C__VARIABLENAME__desc = {
  "Absyn_CodeNode_C__VARIABLENAME",
  "Absyn.CodeNode.C_VARIABLENAME",
  Absyn_CodeNode_C__VARIABLENAME__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_CodeNode_C__VARIABLENAME__desc;
#endif
#define Absyn__C_5fVARIABLENAME_3dBOX1 4
#define Absyn__C_5fVARIABLENAME(componentRef) (mmc_mk_box2(4,&Absyn_CodeNode_C__VARIABLENAME__desc,componentRef))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_CodeNode_C__TYPENAME__desc_added
#define Absyn_CodeNode_C__TYPENAME__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_CodeNode_C__TYPENAME__desc__fields[1] = {"path"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_CodeNode_C__TYPENAME__desc = {
  "Absyn_CodeNode_C__TYPENAME",
  "Absyn.CodeNode.C_TYPENAME",
  Absyn_CodeNode_C__TYPENAME__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_CodeNode_C__TYPENAME__desc;
#endif
#define Absyn__C_5fTYPENAME_3dBOX1 3
#define Absyn__C_5fTYPENAME(path) (mmc_mk_box2(3,&Absyn_CodeNode_C__TYPENAME__desc,path))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_FunctionArgs_FOR__ITER__FARG__desc_added
#define Absyn_FunctionArgs_FOR__ITER__FARG__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_FunctionArgs_FOR__ITER__FARG__desc__fields[3] = {"exp","iterType","iterators"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_FunctionArgs_FOR__ITER__FARG__desc = {
  "Absyn_FunctionArgs_FOR__ITER__FARG",
  "Absyn.FunctionArgs.FOR_ITER_FARG",
  Absyn_FunctionArgs_FOR__ITER__FARG__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_FunctionArgs_FOR__ITER__FARG__desc;
#endif
#define Absyn__FOR_5fITER_5fFARG_3dBOX3 4
#define Absyn__FOR_5fITER_5fFARG(exp,iterType,iterators) (mmc_mk_box4(4,&Absyn_FunctionArgs_FOR__ITER__FARG__desc,exp,iterType,iterators))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_FunctionArgs_FUNCTIONARGS__desc_added
#define Absyn_FunctionArgs_FUNCTIONARGS__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_FunctionArgs_FUNCTIONARGS__desc__fields[2] = {"args","argNames"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_FunctionArgs_FUNCTIONARGS__desc = {
  "Absyn_FunctionArgs_FUNCTIONARGS",
  "Absyn.FunctionArgs.FUNCTIONARGS",
  Absyn_FunctionArgs_FUNCTIONARGS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_FunctionArgs_FUNCTIONARGS__desc;
#endif
#define Absyn__FUNCTIONARGS_3dBOX2 3
#define Absyn__FUNCTIONARGS(args,argNames) (mmc_mk_box3(3,&Absyn_FunctionArgs_FUNCTIONARGS__desc,args,argNames))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ReductionIterType_THREAD__desc_added
#define Absyn_ReductionIterType_THREAD__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ReductionIterType_THREAD__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ReductionIterType_THREAD__desc = {
  "Absyn_ReductionIterType_THREAD",
  "Absyn.ReductionIterType.THREAD",
  Absyn_ReductionIterType_THREAD__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ReductionIterType_THREAD__desc;
#endif
#define Absyn__THREAD_3dBOX0 4
static const MMC_DEFSTRUCTLIT(Absyn__THREAD__struct,1,4) {&Absyn_ReductionIterType_THREAD__desc}};
static void *Absyn__THREAD = MMC_REFSTRUCTLIT(Absyn__THREAD__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ReductionIterType_COMBINE__desc_added
#define Absyn_ReductionIterType_COMBINE__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ReductionIterType_COMBINE__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ReductionIterType_COMBINE__desc = {
  "Absyn_ReductionIterType_COMBINE",
  "Absyn.ReductionIterType.COMBINE",
  Absyn_ReductionIterType_COMBINE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ReductionIterType_COMBINE__desc;
#endif
#define Absyn__COMBINE_3dBOX0 3
static const MMC_DEFSTRUCTLIT(Absyn__COMBINE__struct,1,3) {&Absyn_ReductionIterType_COMBINE__desc}};
static void *Absyn__COMBINE = MMC_REFSTRUCTLIT(Absyn__COMBINE__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_NamedArg_NAMEDARG__desc_added
#define Absyn_NamedArg_NAMEDARG__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_NamedArg_NAMEDARG__desc__fields[2] = {"argName","argValue"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_NamedArg_NAMEDARG__desc = {
  "Absyn_NamedArg_NAMEDARG",
  "Absyn.NamedArg.NAMEDARG",
  Absyn_NamedArg_NAMEDARG__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_NamedArg_NAMEDARG__desc;
#endif
#define Absyn__NAMEDARG_3dBOX2 3
#define Absyn__NAMEDARG(argName,argValue) (mmc_mk_box3(3,&Absyn_NamedArg_NAMEDARG__desc,argName,argValue))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_NEQUAL__desc_added
#define Absyn_Operator_NEQUAL__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_NEQUAL__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_NEQUAL__desc = {
  "Absyn_Operator_NEQUAL",
  "Absyn.Operator.NEQUAL",
  Absyn_Operator_NEQUAL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_NEQUAL__desc;
#endif
#define Absyn__NEQUAL_3dBOX0 25
static const MMC_DEFSTRUCTLIT(Absyn__NEQUAL__struct,1,25) {&Absyn_Operator_NEQUAL__desc}};
static void *Absyn__NEQUAL = MMC_REFSTRUCTLIT(Absyn__NEQUAL__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_EQUAL__desc_added
#define Absyn_Operator_EQUAL__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_EQUAL__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_EQUAL__desc = {
  "Absyn_Operator_EQUAL",
  "Absyn.Operator.EQUAL",
  Absyn_Operator_EQUAL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_EQUAL__desc;
#endif
#define Absyn__EQUAL_3dBOX0 24
static const MMC_DEFSTRUCTLIT(Absyn__EQUAL__struct,1,24) {&Absyn_Operator_EQUAL__desc}};
static void *Absyn__EQUAL = MMC_REFSTRUCTLIT(Absyn__EQUAL__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_GREATEREQ__desc_added
#define Absyn_Operator_GREATEREQ__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_GREATEREQ__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_GREATEREQ__desc = {
  "Absyn_Operator_GREATEREQ",
  "Absyn.Operator.GREATEREQ",
  Absyn_Operator_GREATEREQ__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_GREATEREQ__desc;
#endif
#define Absyn__GREATEREQ_3dBOX0 23
static const MMC_DEFSTRUCTLIT(Absyn__GREATEREQ__struct,1,23) {&Absyn_Operator_GREATEREQ__desc}};
static void *Absyn__GREATEREQ = MMC_REFSTRUCTLIT(Absyn__GREATEREQ__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_GREATER__desc_added
#define Absyn_Operator_GREATER__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_GREATER__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_GREATER__desc = {
  "Absyn_Operator_GREATER",
  "Absyn.Operator.GREATER",
  Absyn_Operator_GREATER__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_GREATER__desc;
#endif
#define Absyn__GREATER_3dBOX0 22
static const MMC_DEFSTRUCTLIT(Absyn__GREATER__struct,1,22) {&Absyn_Operator_GREATER__desc}};
static void *Absyn__GREATER = MMC_REFSTRUCTLIT(Absyn__GREATER__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_LESSEQ__desc_added
#define Absyn_Operator_LESSEQ__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_LESSEQ__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_LESSEQ__desc = {
  "Absyn_Operator_LESSEQ",
  "Absyn.Operator.LESSEQ",
  Absyn_Operator_LESSEQ__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_LESSEQ__desc;
#endif
#define Absyn__LESSEQ_3dBOX0 21
static const MMC_DEFSTRUCTLIT(Absyn__LESSEQ__struct,1,21) {&Absyn_Operator_LESSEQ__desc}};
static void *Absyn__LESSEQ = MMC_REFSTRUCTLIT(Absyn__LESSEQ__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_LESS__desc_added
#define Absyn_Operator_LESS__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_LESS__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_LESS__desc = {
  "Absyn_Operator_LESS",
  "Absyn.Operator.LESS",
  Absyn_Operator_LESS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_LESS__desc;
#endif
#define Absyn__LESS_3dBOX0 20
static const MMC_DEFSTRUCTLIT(Absyn__LESS__struct,1,20) {&Absyn_Operator_LESS__desc}};
static void *Absyn__LESS = MMC_REFSTRUCTLIT(Absyn__LESS__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_NOT__desc_added
#define Absyn_Operator_NOT__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_NOT__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_NOT__desc = {
  "Absyn_Operator_NOT",
  "Absyn.Operator.NOT",
  Absyn_Operator_NOT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_NOT__desc;
#endif
#define Absyn__NOT_3dBOX0 19
static const MMC_DEFSTRUCTLIT(Absyn__NOT__struct,1,19) {&Absyn_Operator_NOT__desc}};
static void *Absyn__NOT = MMC_REFSTRUCTLIT(Absyn__NOT__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_OR__desc_added
#define Absyn_Operator_OR__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_OR__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_OR__desc = {
  "Absyn_Operator_OR",
  "Absyn.Operator.OR",
  Absyn_Operator_OR__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_OR__desc;
#endif
#define Absyn__OR_3dBOX0 18
static const MMC_DEFSTRUCTLIT(Absyn__OR__struct,1,18) {&Absyn_Operator_OR__desc}};
static void *Absyn__OR = MMC_REFSTRUCTLIT(Absyn__OR__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_AND__desc_added
#define Absyn_Operator_AND__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_AND__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_AND__desc = {
  "Absyn_Operator_AND",
  "Absyn.Operator.AND",
  Absyn_Operator_AND__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_AND__desc;
#endif
#define Absyn__AND_3dBOX0 17
static const MMC_DEFSTRUCTLIT(Absyn__AND__struct,1,17) {&Absyn_Operator_AND__desc}};
static void *Absyn__AND = MMC_REFSTRUCTLIT(Absyn__AND__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_UMINUS__EW__desc_added
#define Absyn_Operator_UMINUS__EW__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_UMINUS__EW__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_UMINUS__EW__desc = {
  "Absyn_Operator_UMINUS__EW",
  "Absyn.Operator.UMINUS_EW",
  Absyn_Operator_UMINUS__EW__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_UMINUS__EW__desc;
#endif
#define Absyn__UMINUS_5fEW_3dBOX0 16
static const MMC_DEFSTRUCTLIT(Absyn__UMINUS_5fEW__struct,1,16) {&Absyn_Operator_UMINUS__EW__desc}};
static void *Absyn__UMINUS_5fEW = MMC_REFSTRUCTLIT(Absyn__UMINUS_5fEW__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_UPLUS__EW__desc_added
#define Absyn_Operator_UPLUS__EW__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_UPLUS__EW__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_UPLUS__EW__desc = {
  "Absyn_Operator_UPLUS__EW",
  "Absyn.Operator.UPLUS_EW",
  Absyn_Operator_UPLUS__EW__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_UPLUS__EW__desc;
#endif
#define Absyn__UPLUS_5fEW_3dBOX0 15
static const MMC_DEFSTRUCTLIT(Absyn__UPLUS_5fEW__struct,1,15) {&Absyn_Operator_UPLUS__EW__desc}};
static void *Absyn__UPLUS_5fEW = MMC_REFSTRUCTLIT(Absyn__UPLUS_5fEW__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_POW__EW__desc_added
#define Absyn_Operator_POW__EW__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_POW__EW__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_POW__EW__desc = {
  "Absyn_Operator_POW__EW",
  "Absyn.Operator.POW_EW",
  Absyn_Operator_POW__EW__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_POW__EW__desc;
#endif
#define Absyn__POW_5fEW_3dBOX0 14
static const MMC_DEFSTRUCTLIT(Absyn__POW_5fEW__struct,1,14) {&Absyn_Operator_POW__EW__desc}};
static void *Absyn__POW_5fEW = MMC_REFSTRUCTLIT(Absyn__POW_5fEW__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_DIV__EW__desc_added
#define Absyn_Operator_DIV__EW__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_DIV__EW__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_DIV__EW__desc = {
  "Absyn_Operator_DIV__EW",
  "Absyn.Operator.DIV_EW",
  Absyn_Operator_DIV__EW__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_DIV__EW__desc;
#endif
#define Absyn__DIV_5fEW_3dBOX0 13
static const MMC_DEFSTRUCTLIT(Absyn__DIV_5fEW__struct,1,13) {&Absyn_Operator_DIV__EW__desc}};
static void *Absyn__DIV_5fEW = MMC_REFSTRUCTLIT(Absyn__DIV_5fEW__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_MUL__EW__desc_added
#define Absyn_Operator_MUL__EW__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_MUL__EW__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_MUL__EW__desc = {
  "Absyn_Operator_MUL__EW",
  "Absyn.Operator.MUL_EW",
  Absyn_Operator_MUL__EW__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_MUL__EW__desc;
#endif
#define Absyn__MUL_5fEW_3dBOX0 12
static const MMC_DEFSTRUCTLIT(Absyn__MUL_5fEW__struct,1,12) {&Absyn_Operator_MUL__EW__desc}};
static void *Absyn__MUL_5fEW = MMC_REFSTRUCTLIT(Absyn__MUL_5fEW__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_SUB__EW__desc_added
#define Absyn_Operator_SUB__EW__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_SUB__EW__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_SUB__EW__desc = {
  "Absyn_Operator_SUB__EW",
  "Absyn.Operator.SUB_EW",
  Absyn_Operator_SUB__EW__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_SUB__EW__desc;
#endif
#define Absyn__SUB_5fEW_3dBOX0 11
static const MMC_DEFSTRUCTLIT(Absyn__SUB_5fEW__struct,1,11) {&Absyn_Operator_SUB__EW__desc}};
static void *Absyn__SUB_5fEW = MMC_REFSTRUCTLIT(Absyn__SUB_5fEW__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_ADD__EW__desc_added
#define Absyn_Operator_ADD__EW__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_ADD__EW__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_ADD__EW__desc = {
  "Absyn_Operator_ADD__EW",
  "Absyn.Operator.ADD_EW",
  Absyn_Operator_ADD__EW__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_ADD__EW__desc;
#endif
#define Absyn__ADD_5fEW_3dBOX0 10
static const MMC_DEFSTRUCTLIT(Absyn__ADD_5fEW__struct,1,10) {&Absyn_Operator_ADD__EW__desc}};
static void *Absyn__ADD_5fEW = MMC_REFSTRUCTLIT(Absyn__ADD_5fEW__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_UMINUS__desc_added
#define Absyn_Operator_UMINUS__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_UMINUS__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_UMINUS__desc = {
  "Absyn_Operator_UMINUS",
  "Absyn.Operator.UMINUS",
  Absyn_Operator_UMINUS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_UMINUS__desc;
#endif
#define Absyn__UMINUS_3dBOX0 9
static const MMC_DEFSTRUCTLIT(Absyn__UMINUS__struct,1,9) {&Absyn_Operator_UMINUS__desc}};
static void *Absyn__UMINUS = MMC_REFSTRUCTLIT(Absyn__UMINUS__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_UPLUS__desc_added
#define Absyn_Operator_UPLUS__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_UPLUS__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_UPLUS__desc = {
  "Absyn_Operator_UPLUS",
  "Absyn.Operator.UPLUS",
  Absyn_Operator_UPLUS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_UPLUS__desc;
#endif
#define Absyn__UPLUS_3dBOX0 8
static const MMC_DEFSTRUCTLIT(Absyn__UPLUS__struct,1,8) {&Absyn_Operator_UPLUS__desc}};
static void *Absyn__UPLUS = MMC_REFSTRUCTLIT(Absyn__UPLUS__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_POW__desc_added
#define Absyn_Operator_POW__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_POW__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_POW__desc = {
  "Absyn_Operator_POW",
  "Absyn.Operator.POW",
  Absyn_Operator_POW__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_POW__desc;
#endif
#define Absyn__POW_3dBOX0 7
static const MMC_DEFSTRUCTLIT(Absyn__POW__struct,1,7) {&Absyn_Operator_POW__desc}};
static void *Absyn__POW = MMC_REFSTRUCTLIT(Absyn__POW__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_DIV__desc_added
#define Absyn_Operator_DIV__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_DIV__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_DIV__desc = {
  "Absyn_Operator_DIV",
  "Absyn.Operator.DIV",
  Absyn_Operator_DIV__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_DIV__desc;
#endif
#define Absyn__DIV_3dBOX0 6
static const MMC_DEFSTRUCTLIT(Absyn__DIV__struct,1,6) {&Absyn_Operator_DIV__desc}};
static void *Absyn__DIV = MMC_REFSTRUCTLIT(Absyn__DIV__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_MUL__desc_added
#define Absyn_Operator_MUL__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_MUL__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_MUL__desc = {
  "Absyn_Operator_MUL",
  "Absyn.Operator.MUL",
  Absyn_Operator_MUL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_MUL__desc;
#endif
#define Absyn__MUL_3dBOX0 5
static const MMC_DEFSTRUCTLIT(Absyn__MUL__struct,1,5) {&Absyn_Operator_MUL__desc}};
static void *Absyn__MUL = MMC_REFSTRUCTLIT(Absyn__MUL__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_SUB__desc_added
#define Absyn_Operator_SUB__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_SUB__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_SUB__desc = {
  "Absyn_Operator_SUB",
  "Absyn.Operator.SUB",
  Absyn_Operator_SUB__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_SUB__desc;
#endif
#define Absyn__SUB_3dBOX0 4
static const MMC_DEFSTRUCTLIT(Absyn__SUB__struct,1,4) {&Absyn_Operator_SUB__desc}};
static void *Absyn__SUB = MMC_REFSTRUCTLIT(Absyn__SUB__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Operator_ADD__desc_added
#define Absyn_Operator_ADD__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Operator_ADD__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Operator_ADD__desc = {
  "Absyn_Operator_ADD",
  "Absyn.Operator.ADD",
  Absyn_Operator_ADD__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Operator_ADD__desc;
#endif
#define Absyn__ADD_3dBOX0 3
static const MMC_DEFSTRUCTLIT(Absyn__ADD__struct,1,3) {&Absyn_Operator_ADD__desc}};
static void *Absyn__ADD = MMC_REFSTRUCTLIT(Absyn__ADD__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Subscript_SUBSCRIPT__desc_added
#define Absyn_Subscript_SUBSCRIPT__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Subscript_SUBSCRIPT__desc__fields[1] = {"subscript"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Subscript_SUBSCRIPT__desc = {
  "Absyn_Subscript_SUBSCRIPT",
  "Absyn.Subscript.SUBSCRIPT",
  Absyn_Subscript_SUBSCRIPT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Subscript_SUBSCRIPT__desc;
#endif
#define Absyn__SUBSCRIPT_3dBOX1 4
#define Absyn__SUBSCRIPT(subscript) (mmc_mk_box2(4,&Absyn_Subscript_SUBSCRIPT__desc,subscript))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Subscript_NOSUB__desc_added
#define Absyn_Subscript_NOSUB__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Subscript_NOSUB__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Subscript_NOSUB__desc = {
  "Absyn_Subscript_NOSUB",
  "Absyn.Subscript.NOSUB",
  Absyn_Subscript_NOSUB__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Subscript_NOSUB__desc;
#endif
#define Absyn__NOSUB_3dBOX0 3
static const MMC_DEFSTRUCTLIT(Absyn__NOSUB__struct,1,3) {&Absyn_Subscript_NOSUB__desc}};
static void *Absyn__NOSUB = MMC_REFSTRUCTLIT(Absyn__NOSUB__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ComponentRef_ALLWILD__desc_added
#define Absyn_ComponentRef_ALLWILD__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ComponentRef_ALLWILD__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ComponentRef_ALLWILD__desc = {
  "Absyn_ComponentRef_ALLWILD",
  "Absyn.ComponentRef.ALLWILD",
  Absyn_ComponentRef_ALLWILD__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ComponentRef_ALLWILD__desc;
#endif
#define Absyn__ALLWILD_3dBOX0 7
static const MMC_DEFSTRUCTLIT(Absyn__ALLWILD__struct,1,7) {&Absyn_ComponentRef_ALLWILD__desc}};
static void *Absyn__ALLWILD = MMC_REFSTRUCTLIT(Absyn__ALLWILD__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ComponentRef_WILD__desc_added
#define Absyn_ComponentRef_WILD__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ComponentRef_WILD__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ComponentRef_WILD__desc = {
  "Absyn_ComponentRef_WILD",
  "Absyn.ComponentRef.WILD",
  Absyn_ComponentRef_WILD__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ComponentRef_WILD__desc;
#endif
#define Absyn__WILD_3dBOX0 6
static const MMC_DEFSTRUCTLIT(Absyn__WILD__struct,1,6) {&Absyn_ComponentRef_WILD__desc}};
static void *Absyn__WILD = MMC_REFSTRUCTLIT(Absyn__WILD__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ComponentRef_CREF__IDENT__desc_added
#define Absyn_ComponentRef_CREF__IDENT__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ComponentRef_CREF__IDENT__desc__fields[2] = {"name","subscripts"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ComponentRef_CREF__IDENT__desc = {
  "Absyn_ComponentRef_CREF__IDENT",
  "Absyn.ComponentRef.CREF_IDENT",
  Absyn_ComponentRef_CREF__IDENT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ComponentRef_CREF__IDENT__desc;
#endif
#define Absyn__CREF_5fIDENT_3dBOX2 5
#define Absyn__CREF_5fIDENT(name,subscripts) (mmc_mk_box3(5,&Absyn_ComponentRef_CREF__IDENT__desc,name,subscripts))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ComponentRef_CREF__QUAL__desc_added
#define Absyn_ComponentRef_CREF__QUAL__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ComponentRef_CREF__QUAL__desc__fields[3] = {"name","subscripts","componentRef"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ComponentRef_CREF__QUAL__desc = {
  "Absyn_ComponentRef_CREF__QUAL",
  "Absyn.ComponentRef.CREF_QUAL",
  Absyn_ComponentRef_CREF__QUAL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ComponentRef_CREF__QUAL__desc;
#endif
#define Absyn__CREF_5fQUAL_3dBOX3 4
#define Absyn__CREF_5fQUAL(name,subscripts,componentRef) (mmc_mk_box4(4,&Absyn_ComponentRef_CREF__QUAL__desc,name,subscripts,componentRef))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ComponentRef_CREF__FULLYQUALIFIED__desc_added
#define Absyn_ComponentRef_CREF__FULLYQUALIFIED__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ComponentRef_CREF__FULLYQUALIFIED__desc__fields[1] = {"componentRef"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ComponentRef_CREF__FULLYQUALIFIED__desc = {
  "Absyn_ComponentRef_CREF__FULLYQUALIFIED",
  "Absyn.ComponentRef.CREF_FULLYQUALIFIED",
  Absyn_ComponentRef_CREF__FULLYQUALIFIED__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ComponentRef_CREF__FULLYQUALIFIED__desc;
#endif
#define Absyn__CREF_5fFULLYQUALIFIED_3dBOX1 3
#define Absyn__CREF_5fFULLYQUALIFIED(componentRef) (mmc_mk_box2(3,&Absyn_ComponentRef_CREF__FULLYQUALIFIED__desc,componentRef))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Path_FULLYQUALIFIED__desc_added
#define Absyn_Path_FULLYQUALIFIED__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Path_FULLYQUALIFIED__desc__fields[1] = {"path"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Path_FULLYQUALIFIED__desc = {
  "Absyn_Path_FULLYQUALIFIED",
  "Absyn.Path.FULLYQUALIFIED",
  Absyn_Path_FULLYQUALIFIED__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Path_FULLYQUALIFIED__desc;
#endif
#define Absyn__FULLYQUALIFIED_3dBOX1 5
#define Absyn__FULLYQUALIFIED(path) (mmc_mk_box2(5,&Absyn_Path_FULLYQUALIFIED__desc,path))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Path_IDENT__desc_added
#define Absyn_Path_IDENT__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Path_IDENT__desc__fields[1] = {"name"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Path_IDENT__desc = {
  "Absyn_Path_IDENT",
  "Absyn.Path.IDENT",
  Absyn_Path_IDENT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Path_IDENT__desc;
#endif
#define Absyn__IDENT_3dBOX1 4
#define Absyn__IDENT(name) (mmc_mk_box2(4,&Absyn_Path_IDENT__desc,name))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Path_QUALIFIED__desc_added
#define Absyn_Path_QUALIFIED__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Path_QUALIFIED__desc__fields[2] = {"name","path"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Path_QUALIFIED__desc = {
  "Absyn_Path_QUALIFIED",
  "Absyn.Path.QUALIFIED",
  Absyn_Path_QUALIFIED__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Path_QUALIFIED__desc;
#endif
#define Absyn__QUALIFIED_3dBOX2 3
#define Absyn__QUALIFIED(name,path) (mmc_mk_box3(3,&Absyn_Path_QUALIFIED__desc,name,path))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Restriction_R__UNKNOWN__desc_added
#define Absyn_Restriction_R__UNKNOWN__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Restriction_R__UNKNOWN__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Restriction_R__UNKNOWN__desc = {
  "Absyn_Restriction_R__UNKNOWN",
  "Absyn.Restriction.R_UNKNOWN",
  Absyn_Restriction_R__UNKNOWN__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Restriction_R__UNKNOWN__desc;
#endif
#define Absyn__R_5fUNKNOWN_3dBOX0 24
static const MMC_DEFSTRUCTLIT(Absyn__R_5fUNKNOWN__struct,1,24) {&Absyn_Restriction_R__UNKNOWN__desc}};
static void *Absyn__R_5fUNKNOWN = MMC_REFSTRUCTLIT(Absyn__R_5fUNKNOWN__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Restriction_R__METARECORD__desc_added
#define Absyn_Restriction_R__METARECORD__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Restriction_R__METARECORD__desc__fields[4] = {"name","index","singleton","moved"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Restriction_R__METARECORD__desc = {
  "Absyn_Restriction_R__METARECORD",
  "Absyn.Restriction.R_METARECORD",
  Absyn_Restriction_R__METARECORD__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Restriction_R__METARECORD__desc;
#endif
#define Absyn__R_5fMETARECORD_3dBOX4 23
#define Absyn__R_5fMETARECORD(name,index,singleton,moved) (mmc_mk_box5(23,&Absyn_Restriction_R__METARECORD__desc,name,index,singleton,moved))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Restriction_R__UNIONTYPE__desc_added
#define Absyn_Restriction_R__UNIONTYPE__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Restriction_R__UNIONTYPE__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Restriction_R__UNIONTYPE__desc = {
  "Absyn_Restriction_R__UNIONTYPE",
  "Absyn.Restriction.R_UNIONTYPE",
  Absyn_Restriction_R__UNIONTYPE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Restriction_R__UNIONTYPE__desc;
#endif
#define Absyn__R_5fUNIONTYPE_3dBOX0 22
static const MMC_DEFSTRUCTLIT(Absyn__R_5fUNIONTYPE__struct,1,22) {&Absyn_Restriction_R__UNIONTYPE__desc}};
static void *Absyn__R_5fUNIONTYPE = MMC_REFSTRUCTLIT(Absyn__R_5fUNIONTYPE__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Restriction_R__PREDEFINED__CLOCK__desc_added
#define Absyn_Restriction_R__PREDEFINED__CLOCK__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Restriction_R__PREDEFINED__CLOCK__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Restriction_R__PREDEFINED__CLOCK__desc = {
  "Absyn_Restriction_R__PREDEFINED__CLOCK",
  "Absyn.Restriction.R_PREDEFINED_CLOCK",
  Absyn_Restriction_R__PREDEFINED__CLOCK__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Restriction_R__PREDEFINED__CLOCK__desc;
#endif
#define Absyn__R_5fPREDEFINED_5fCLOCK_3dBOX0 21
static const MMC_DEFSTRUCTLIT(Absyn__R_5fPREDEFINED_5fCLOCK__struct,1,21) {&Absyn_Restriction_R__PREDEFINED__CLOCK__desc}};
static void *Absyn__R_5fPREDEFINED_5fCLOCK = MMC_REFSTRUCTLIT(Absyn__R_5fPREDEFINED_5fCLOCK__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Restriction_R__PREDEFINED__ENUMERATION__desc_added
#define Absyn_Restriction_R__PREDEFINED__ENUMERATION__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Restriction_R__PREDEFINED__ENUMERATION__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Restriction_R__PREDEFINED__ENUMERATION__desc = {
  "Absyn_Restriction_R__PREDEFINED__ENUMERATION",
  "Absyn.Restriction.R_PREDEFINED_ENUMERATION",
  Absyn_Restriction_R__PREDEFINED__ENUMERATION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Restriction_R__PREDEFINED__ENUMERATION__desc;
#endif
#define Absyn__R_5fPREDEFINED_5fENUMERATION_3dBOX0 20
static const MMC_DEFSTRUCTLIT(Absyn__R_5fPREDEFINED_5fENUMERATION__struct,1,20) {&Absyn_Restriction_R__PREDEFINED__ENUMERATION__desc}};
static void *Absyn__R_5fPREDEFINED_5fENUMERATION = MMC_REFSTRUCTLIT(Absyn__R_5fPREDEFINED_5fENUMERATION__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Restriction_R__PREDEFINED__BOOLEAN__desc_added
#define Absyn_Restriction_R__PREDEFINED__BOOLEAN__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Restriction_R__PREDEFINED__BOOLEAN__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Restriction_R__PREDEFINED__BOOLEAN__desc = {
  "Absyn_Restriction_R__PREDEFINED__BOOLEAN",
  "Absyn.Restriction.R_PREDEFINED_BOOLEAN",
  Absyn_Restriction_R__PREDEFINED__BOOLEAN__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Restriction_R__PREDEFINED__BOOLEAN__desc;
#endif
#define Absyn__R_5fPREDEFINED_5fBOOLEAN_3dBOX0 19
static const MMC_DEFSTRUCTLIT(Absyn__R_5fPREDEFINED_5fBOOLEAN__struct,1,19) {&Absyn_Restriction_R__PREDEFINED__BOOLEAN__desc}};
static void *Absyn__R_5fPREDEFINED_5fBOOLEAN = MMC_REFSTRUCTLIT(Absyn__R_5fPREDEFINED_5fBOOLEAN__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Restriction_R__PREDEFINED__STRING__desc_added
#define Absyn_Restriction_R__PREDEFINED__STRING__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Restriction_R__PREDEFINED__STRING__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Restriction_R__PREDEFINED__STRING__desc = {
  "Absyn_Restriction_R__PREDEFINED__STRING",
  "Absyn.Restriction.R_PREDEFINED_STRING",
  Absyn_Restriction_R__PREDEFINED__STRING__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Restriction_R__PREDEFINED__STRING__desc;
#endif
#define Absyn__R_5fPREDEFINED_5fSTRING_3dBOX0 18
static const MMC_DEFSTRUCTLIT(Absyn__R_5fPREDEFINED_5fSTRING__struct,1,18) {&Absyn_Restriction_R__PREDEFINED__STRING__desc}};
static void *Absyn__R_5fPREDEFINED_5fSTRING = MMC_REFSTRUCTLIT(Absyn__R_5fPREDEFINED_5fSTRING__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Restriction_R__PREDEFINED__REAL__desc_added
#define Absyn_Restriction_R__PREDEFINED__REAL__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Restriction_R__PREDEFINED__REAL__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Restriction_R__PREDEFINED__REAL__desc = {
  "Absyn_Restriction_R__PREDEFINED__REAL",
  "Absyn.Restriction.R_PREDEFINED_REAL",
  Absyn_Restriction_R__PREDEFINED__REAL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Restriction_R__PREDEFINED__REAL__desc;
#endif
#define Absyn__R_5fPREDEFINED_5fREAL_3dBOX0 17
static const MMC_DEFSTRUCTLIT(Absyn__R_5fPREDEFINED_5fREAL__struct,1,17) {&Absyn_Restriction_R__PREDEFINED__REAL__desc}};
static void *Absyn__R_5fPREDEFINED_5fREAL = MMC_REFSTRUCTLIT(Absyn__R_5fPREDEFINED_5fREAL__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Restriction_R__PREDEFINED__INTEGER__desc_added
#define Absyn_Restriction_R__PREDEFINED__INTEGER__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Restriction_R__PREDEFINED__INTEGER__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Restriction_R__PREDEFINED__INTEGER__desc = {
  "Absyn_Restriction_R__PREDEFINED__INTEGER",
  "Absyn.Restriction.R_PREDEFINED_INTEGER",
  Absyn_Restriction_R__PREDEFINED__INTEGER__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Restriction_R__PREDEFINED__INTEGER__desc;
#endif
#define Absyn__R_5fPREDEFINED_5fINTEGER_3dBOX0 16
static const MMC_DEFSTRUCTLIT(Absyn__R_5fPREDEFINED_5fINTEGER__struct,1,16) {&Absyn_Restriction_R__PREDEFINED__INTEGER__desc}};
static void *Absyn__R_5fPREDEFINED_5fINTEGER = MMC_REFSTRUCTLIT(Absyn__R_5fPREDEFINED_5fINTEGER__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Restriction_R__ENUMERATION__desc_added
#define Absyn_Restriction_R__ENUMERATION__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Restriction_R__ENUMERATION__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Restriction_R__ENUMERATION__desc = {
  "Absyn_Restriction_R__ENUMERATION",
  "Absyn.Restriction.R_ENUMERATION",
  Absyn_Restriction_R__ENUMERATION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Restriction_R__ENUMERATION__desc;
#endif
#define Absyn__R_5fENUMERATION_3dBOX0 15
static const MMC_DEFSTRUCTLIT(Absyn__R_5fENUMERATION__struct,1,15) {&Absyn_Restriction_R__ENUMERATION__desc}};
static void *Absyn__R_5fENUMERATION = MMC_REFSTRUCTLIT(Absyn__R_5fENUMERATION__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Restriction_R__OPERATOR__RECORD__desc_added
#define Absyn_Restriction_R__OPERATOR__RECORD__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Restriction_R__OPERATOR__RECORD__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Restriction_R__OPERATOR__RECORD__desc = {
  "Absyn_Restriction_R__OPERATOR__RECORD",
  "Absyn.Restriction.R_OPERATOR_RECORD",
  Absyn_Restriction_R__OPERATOR__RECORD__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Restriction_R__OPERATOR__RECORD__desc;
#endif
#define Absyn__R_5fOPERATOR_5fRECORD_3dBOX0 14
static const MMC_DEFSTRUCTLIT(Absyn__R_5fOPERATOR_5fRECORD__struct,1,14) {&Absyn_Restriction_R__OPERATOR__RECORD__desc}};
static void *Absyn__R_5fOPERATOR_5fRECORD = MMC_REFSTRUCTLIT(Absyn__R_5fOPERATOR_5fRECORD__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Restriction_R__OPERATOR__desc_added
#define Absyn_Restriction_R__OPERATOR__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Restriction_R__OPERATOR__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Restriction_R__OPERATOR__desc = {
  "Absyn_Restriction_R__OPERATOR",
  "Absyn.Restriction.R_OPERATOR",
  Absyn_Restriction_R__OPERATOR__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Restriction_R__OPERATOR__desc;
#endif
#define Absyn__R_5fOPERATOR_3dBOX0 13
static const MMC_DEFSTRUCTLIT(Absyn__R_5fOPERATOR__struct,1,13) {&Absyn_Restriction_R__OPERATOR__desc}};
static void *Absyn__R_5fOPERATOR = MMC_REFSTRUCTLIT(Absyn__R_5fOPERATOR__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Restriction_R__FUNCTION__desc_added
#define Absyn_Restriction_R__FUNCTION__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Restriction_R__FUNCTION__desc__fields[1] = {"functionRestriction"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Restriction_R__FUNCTION__desc = {
  "Absyn_Restriction_R__FUNCTION",
  "Absyn.Restriction.R_FUNCTION",
  Absyn_Restriction_R__FUNCTION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Restriction_R__FUNCTION__desc;
#endif
#define Absyn__R_5fFUNCTION_3dBOX1 12
#define Absyn__R_5fFUNCTION(functionRestriction) (mmc_mk_box2(12,&Absyn_Restriction_R__FUNCTION__desc,functionRestriction))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Restriction_R__PACKAGE__desc_added
#define Absyn_Restriction_R__PACKAGE__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Restriction_R__PACKAGE__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Restriction_R__PACKAGE__desc = {
  "Absyn_Restriction_R__PACKAGE",
  "Absyn.Restriction.R_PACKAGE",
  Absyn_Restriction_R__PACKAGE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Restriction_R__PACKAGE__desc;
#endif
#define Absyn__R_5fPACKAGE_3dBOX0 11
static const MMC_DEFSTRUCTLIT(Absyn__R_5fPACKAGE__struct,1,11) {&Absyn_Restriction_R__PACKAGE__desc}};
static void *Absyn__R_5fPACKAGE = MMC_REFSTRUCTLIT(Absyn__R_5fPACKAGE__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Restriction_R__TYPE__desc_added
#define Absyn_Restriction_R__TYPE__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Restriction_R__TYPE__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Restriction_R__TYPE__desc = {
  "Absyn_Restriction_R__TYPE",
  "Absyn.Restriction.R_TYPE",
  Absyn_Restriction_R__TYPE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Restriction_R__TYPE__desc;
#endif
#define Absyn__R_5fTYPE_3dBOX0 10
static const MMC_DEFSTRUCTLIT(Absyn__R_5fTYPE__struct,1,10) {&Absyn_Restriction_R__TYPE__desc}};
static void *Absyn__R_5fTYPE = MMC_REFSTRUCTLIT(Absyn__R_5fTYPE__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Restriction_R__EXP__CONNECTOR__desc_added
#define Absyn_Restriction_R__EXP__CONNECTOR__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Restriction_R__EXP__CONNECTOR__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Restriction_R__EXP__CONNECTOR__desc = {
  "Absyn_Restriction_R__EXP__CONNECTOR",
  "Absyn.Restriction.R_EXP_CONNECTOR",
  Absyn_Restriction_R__EXP__CONNECTOR__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Restriction_R__EXP__CONNECTOR__desc;
#endif
#define Absyn__R_5fEXP_5fCONNECTOR_3dBOX0 9
static const MMC_DEFSTRUCTLIT(Absyn__R_5fEXP_5fCONNECTOR__struct,1,9) {&Absyn_Restriction_R__EXP__CONNECTOR__desc}};
static void *Absyn__R_5fEXP_5fCONNECTOR = MMC_REFSTRUCTLIT(Absyn__R_5fEXP_5fCONNECTOR__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Restriction_R__CONNECTOR__desc_added
#define Absyn_Restriction_R__CONNECTOR__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Restriction_R__CONNECTOR__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Restriction_R__CONNECTOR__desc = {
  "Absyn_Restriction_R__CONNECTOR",
  "Absyn.Restriction.R_CONNECTOR",
  Absyn_Restriction_R__CONNECTOR__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Restriction_R__CONNECTOR__desc;
#endif
#define Absyn__R_5fCONNECTOR_3dBOX0 8
static const MMC_DEFSTRUCTLIT(Absyn__R_5fCONNECTOR__struct,1,8) {&Absyn_Restriction_R__CONNECTOR__desc}};
static void *Absyn__R_5fCONNECTOR = MMC_REFSTRUCTLIT(Absyn__R_5fCONNECTOR__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Restriction_R__BLOCK__desc_added
#define Absyn_Restriction_R__BLOCK__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Restriction_R__BLOCK__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Restriction_R__BLOCK__desc = {
  "Absyn_Restriction_R__BLOCK",
  "Absyn.Restriction.R_BLOCK",
  Absyn_Restriction_R__BLOCK__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Restriction_R__BLOCK__desc;
#endif
#define Absyn__R_5fBLOCK_3dBOX0 7
static const MMC_DEFSTRUCTLIT(Absyn__R_5fBLOCK__struct,1,7) {&Absyn_Restriction_R__BLOCK__desc}};
static void *Absyn__R_5fBLOCK = MMC_REFSTRUCTLIT(Absyn__R_5fBLOCK__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Restriction_R__RECORD__desc_added
#define Absyn_Restriction_R__RECORD__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Restriction_R__RECORD__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Restriction_R__RECORD__desc = {
  "Absyn_Restriction_R__RECORD",
  "Absyn.Restriction.R_RECORD",
  Absyn_Restriction_R__RECORD__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Restriction_R__RECORD__desc;
#endif
#define Absyn__R_5fRECORD_3dBOX0 6
static const MMC_DEFSTRUCTLIT(Absyn__R_5fRECORD__struct,1,6) {&Absyn_Restriction_R__RECORD__desc}};
static void *Absyn__R_5fRECORD = MMC_REFSTRUCTLIT(Absyn__R_5fRECORD__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Restriction_R__MODEL__desc_added
#define Absyn_Restriction_R__MODEL__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Restriction_R__MODEL__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Restriction_R__MODEL__desc = {
  "Absyn_Restriction_R__MODEL",
  "Absyn.Restriction.R_MODEL",
  Absyn_Restriction_R__MODEL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Restriction_R__MODEL__desc;
#endif
#define Absyn__R_5fMODEL_3dBOX0 5
static const MMC_DEFSTRUCTLIT(Absyn__R_5fMODEL__struct,1,5) {&Absyn_Restriction_R__MODEL__desc}};
static void *Absyn__R_5fMODEL = MMC_REFSTRUCTLIT(Absyn__R_5fMODEL__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Restriction_R__OPTIMIZATION__desc_added
#define Absyn_Restriction_R__OPTIMIZATION__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Restriction_R__OPTIMIZATION__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Restriction_R__OPTIMIZATION__desc = {
  "Absyn_Restriction_R__OPTIMIZATION",
  "Absyn.Restriction.R_OPTIMIZATION",
  Absyn_Restriction_R__OPTIMIZATION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Restriction_R__OPTIMIZATION__desc;
#endif
#define Absyn__R_5fOPTIMIZATION_3dBOX0 4
static const MMC_DEFSTRUCTLIT(Absyn__R_5fOPTIMIZATION__struct,1,4) {&Absyn_Restriction_R__OPTIMIZATION__desc}};
static void *Absyn__R_5fOPTIMIZATION = MMC_REFSTRUCTLIT(Absyn__R_5fOPTIMIZATION__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Restriction_R__CLASS__desc_added
#define Absyn_Restriction_R__CLASS__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Restriction_R__CLASS__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Restriction_R__CLASS__desc = {
  "Absyn_Restriction_R__CLASS",
  "Absyn.Restriction.R_CLASS",
  Absyn_Restriction_R__CLASS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Restriction_R__CLASS__desc;
#endif
#define Absyn__R_5fCLASS_3dBOX0 3
static const MMC_DEFSTRUCTLIT(Absyn__R_5fCLASS__struct,1,3) {&Absyn_Restriction_R__CLASS__desc}};
static void *Absyn__R_5fCLASS = MMC_REFSTRUCTLIT(Absyn__R_5fCLASS__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_FunctionPurity_NO__PURITY__desc_added
#define Absyn_FunctionPurity_NO__PURITY__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_FunctionPurity_NO__PURITY__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_FunctionPurity_NO__PURITY__desc = {
  "Absyn_FunctionPurity_NO__PURITY",
  "Absyn.FunctionPurity.NO_PURITY",
  Absyn_FunctionPurity_NO__PURITY__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_FunctionPurity_NO__PURITY__desc;
#endif
#define Absyn__NO_5fPURITY_3dBOX0 5
static const MMC_DEFSTRUCTLIT(Absyn__NO_5fPURITY__struct,1,5) {&Absyn_FunctionPurity_NO__PURITY__desc}};
static void *Absyn__NO_5fPURITY = MMC_REFSTRUCTLIT(Absyn__NO_5fPURITY__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_FunctionPurity_IMPURE__desc_added
#define Absyn_FunctionPurity_IMPURE__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_FunctionPurity_IMPURE__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_FunctionPurity_IMPURE__desc = {
  "Absyn_FunctionPurity_IMPURE",
  "Absyn.FunctionPurity.IMPURE",
  Absyn_FunctionPurity_IMPURE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_FunctionPurity_IMPURE__desc;
#endif
#define Absyn__IMPURE_3dBOX0 4
static const MMC_DEFSTRUCTLIT(Absyn__IMPURE__struct,1,4) {&Absyn_FunctionPurity_IMPURE__desc}};
static void *Absyn__IMPURE = MMC_REFSTRUCTLIT(Absyn__IMPURE__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_FunctionPurity_PURE__desc_added
#define Absyn_FunctionPurity_PURE__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_FunctionPurity_PURE__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_FunctionPurity_PURE__desc = {
  "Absyn_FunctionPurity_PURE",
  "Absyn.FunctionPurity.PURE",
  Absyn_FunctionPurity_PURE__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_FunctionPurity_PURE__desc;
#endif
#define Absyn__PURE_3dBOX0 3
static const MMC_DEFSTRUCTLIT(Absyn__PURE__struct,1,3) {&Absyn_FunctionPurity_PURE__desc}};
static void *Absyn__PURE = MMC_REFSTRUCTLIT(Absyn__PURE__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_FunctionRestriction_FR__KERNEL__FUNCTION__desc_added
#define Absyn_FunctionRestriction_FR__KERNEL__FUNCTION__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_FunctionRestriction_FR__KERNEL__FUNCTION__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_FunctionRestriction_FR__KERNEL__FUNCTION__desc = {
  "Absyn_FunctionRestriction_FR__KERNEL__FUNCTION",
  "Absyn.FunctionRestriction.FR_KERNEL_FUNCTION",
  Absyn_FunctionRestriction_FR__KERNEL__FUNCTION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_FunctionRestriction_FR__KERNEL__FUNCTION__desc;
#endif
#define Absyn__FR_5fKERNEL_5fFUNCTION_3dBOX0 6
static const MMC_DEFSTRUCTLIT(Absyn__FR_5fKERNEL_5fFUNCTION__struct,1,6) {&Absyn_FunctionRestriction_FR__KERNEL__FUNCTION__desc}};
static void *Absyn__FR_5fKERNEL_5fFUNCTION = MMC_REFSTRUCTLIT(Absyn__FR_5fKERNEL_5fFUNCTION__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_FunctionRestriction_FR__PARALLEL__FUNCTION__desc_added
#define Absyn_FunctionRestriction_FR__PARALLEL__FUNCTION__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_FunctionRestriction_FR__PARALLEL__FUNCTION__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_FunctionRestriction_FR__PARALLEL__FUNCTION__desc = {
  "Absyn_FunctionRestriction_FR__PARALLEL__FUNCTION",
  "Absyn.FunctionRestriction.FR_PARALLEL_FUNCTION",
  Absyn_FunctionRestriction_FR__PARALLEL__FUNCTION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_FunctionRestriction_FR__PARALLEL__FUNCTION__desc;
#endif
#define Absyn__FR_5fPARALLEL_5fFUNCTION_3dBOX0 5
static const MMC_DEFSTRUCTLIT(Absyn__FR_5fPARALLEL_5fFUNCTION__struct,1,5) {&Absyn_FunctionRestriction_FR__PARALLEL__FUNCTION__desc}};
static void *Absyn__FR_5fPARALLEL_5fFUNCTION = MMC_REFSTRUCTLIT(Absyn__FR_5fPARALLEL_5fFUNCTION__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_FunctionRestriction_FR__OPERATOR__FUNCTION__desc_added
#define Absyn_FunctionRestriction_FR__OPERATOR__FUNCTION__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_FunctionRestriction_FR__OPERATOR__FUNCTION__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_FunctionRestriction_FR__OPERATOR__FUNCTION__desc = {
  "Absyn_FunctionRestriction_FR__OPERATOR__FUNCTION",
  "Absyn.FunctionRestriction.FR_OPERATOR_FUNCTION",
  Absyn_FunctionRestriction_FR__OPERATOR__FUNCTION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_FunctionRestriction_FR__OPERATOR__FUNCTION__desc;
#endif
#define Absyn__FR_5fOPERATOR_5fFUNCTION_3dBOX0 4
static const MMC_DEFSTRUCTLIT(Absyn__FR_5fOPERATOR_5fFUNCTION__struct,1,4) {&Absyn_FunctionRestriction_FR__OPERATOR__FUNCTION__desc}};
static void *Absyn__FR_5fOPERATOR_5fFUNCTION = MMC_REFSTRUCTLIT(Absyn__FR_5fOPERATOR_5fFUNCTION__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_FunctionRestriction_FR__NORMAL__FUNCTION__desc_added
#define Absyn_FunctionRestriction_FR__NORMAL__FUNCTION__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_FunctionRestriction_FR__NORMAL__FUNCTION__desc__fields[1] = {"purity"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_FunctionRestriction_FR__NORMAL__FUNCTION__desc = {
  "Absyn_FunctionRestriction_FR__NORMAL__FUNCTION",
  "Absyn.FunctionRestriction.FR_NORMAL_FUNCTION",
  Absyn_FunctionRestriction_FR__NORMAL__FUNCTION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_FunctionRestriction_FR__NORMAL__FUNCTION__desc;
#endif
#define Absyn__FR_5fNORMAL_5fFUNCTION_3dBOX1 3
#define Absyn__FR_5fNORMAL_5fFUNCTION(purity) (mmc_mk_box2(3,&Absyn_FunctionRestriction_FR__NORMAL__FUNCTION__desc,purity))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Annotation_ANNOTATION__desc_added
#define Absyn_Annotation_ANNOTATION__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Annotation_ANNOTATION__desc__fields[1] = {"elementArgs"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Annotation_ANNOTATION__desc = {
  "Absyn_Annotation_ANNOTATION",
  "Absyn.Annotation.ANNOTATION",
  Absyn_Annotation_ANNOTATION__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Annotation_ANNOTATION__desc;
#endif
#define Absyn__ANNOTATION_3dBOX1 3
#define Absyn__ANNOTATION(elementArgs) (mmc_mk_box2(3,&Absyn_Annotation_ANNOTATION__desc,elementArgs))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Comment_COMMENT__desc_added
#define Absyn_Comment_COMMENT__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Comment_COMMENT__desc__fields[2] = {"annotation_","comment"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Comment_COMMENT__desc = {
  "Absyn_Comment_COMMENT",
  "Absyn.Comment.COMMENT",
  Absyn_Comment_COMMENT__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Comment_COMMENT__desc;
#endif
#define Absyn__COMMENT_3dBOX2 3
#define Absyn__COMMENT(annotation_,comment) (mmc_mk_box3(3,&Absyn_Comment_COMMENT__desc,annotation_,comment))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_ExternalDecl_EXTERNALDECL__desc_added
#define Absyn_ExternalDecl_EXTERNALDECL__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_ExternalDecl_EXTERNALDECL__desc__fields[5] = {"funcName","lang","output_","args","annotation_"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_ExternalDecl_EXTERNALDECL__desc = {
  "Absyn_ExternalDecl_EXTERNALDECL",
  "Absyn.ExternalDecl.EXTERNALDECL",
  Absyn_ExternalDecl_EXTERNALDECL__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_ExternalDecl_EXTERNALDECL__desc;
#endif
#define Absyn__EXTERNALDECL_3dBOX5 3
#define Absyn__EXTERNALDECL(funcName,lang,output_,args,annotation_) (mmc_mk_box6(3,&Absyn_ExternalDecl_EXTERNALDECL__desc,funcName,lang,output_,args,annotation_))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Ref_RIM__desc_added
#define Absyn_Ref_RIM__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Ref_RIM__desc__fields[1] = {"im"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Ref_RIM__desc = {
  "Absyn_Ref_RIM",
  "Absyn.Ref.RIM",
  Absyn_Ref_RIM__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Ref_RIM__desc;
#endif
#define Absyn__RIM_3dBOX1 5
#define Absyn__RIM(im) (mmc_mk_box2(5,&Absyn_Ref_RIM__desc,im))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Ref_RTS__desc_added
#define Absyn_Ref_RTS__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Ref_RTS__desc__fields[1] = {"ts"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Ref_RTS__desc = {
  "Absyn_Ref_RTS",
  "Absyn.Ref.RTS",
  Absyn_Ref_RTS__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Ref_RTS__desc;
#endif
#define Absyn__RTS_3dBOX1 4
#define Absyn__RTS(ts) (mmc_mk_box2(4,&Absyn_Ref_RTS__desc,ts))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Ref_RCR__desc_added
#define Absyn_Ref_RCR__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Ref_RCR__desc__fields[1] = {"cr"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Ref_RCR__desc = {
  "Absyn_Ref_RCR",
  "Absyn.Ref.RCR",
  Absyn_Ref_RCR__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Ref_RCR__desc;
#endif
#define Absyn__RCR_3dBOX1 3
#define Absyn__RCR(cr) (mmc_mk_box2(3,&Absyn_Ref_RCR__desc,cr))
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Msg_NO__MSG__desc_added
#define Absyn_Msg_NO__MSG__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Msg_NO__MSG__desc__fields[1] = {"no fields"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Msg_NO__MSG__desc = {
  "Absyn_Msg_NO__MSG",
  "Absyn.Msg.NO_MSG",
  Absyn_Msg_NO__MSG__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Msg_NO__MSG__desc;
#endif
#define Absyn__NO_5fMSG_3dBOX0 4
static const MMC_DEFSTRUCTLIT(Absyn__NO_5fMSG__struct,1,4) {&Absyn_Msg_NO__MSG__desc}};
static void *Absyn__NO_5fMSG = MMC_REFSTRUCTLIT(Absyn__NO_5fMSG__struct);
#ifdef ADD_METARECORD_DEFINITIONS
#ifndef Absyn_Msg_MSG__desc_added
#define Absyn_Msg_MSG__desc_added
ADD_METARECORD_DEFINITIONS const char* Absyn_Msg_MSG__desc__fields[1] = {"info"};
ADD_METARECORD_DEFINITIONS struct record_description Absyn_Msg_MSG__desc = {
  "Absyn_Msg_MSG",
  "Absyn.Msg.MSG",
  Absyn_Msg_MSG__desc__fields
};
#endif
#else /* Only use the file as a header */
extern struct record_description Absyn_Msg_MSG__desc;
#endif
#define Absyn__MSG_3dBOX1 3
#define Absyn__MSG(info) (mmc_mk_box2(3,&Absyn_Msg_MSG__desc,info))
#ifdef __cplusplus
}
#endif

