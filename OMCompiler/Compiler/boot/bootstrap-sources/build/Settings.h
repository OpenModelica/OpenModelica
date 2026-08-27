#ifndef Settings__H
#define Settings__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
void omc_Settings_setEcho(threadData_t *threadData, modelica_integer _echo);
DLLExport
void boxptr_Settings_setEcho(threadData_t *threadData, modelica_metatype _echo);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Settings_setEcho,2,0) {(void*) boxptr_Settings_setEcho,0}};
#define boxvar_Settings_setEcho MMC_REFSTRUCTLIT(boxvar_lit_Settings_setEcho)
extern void Settings_setEcho(int /*_echo*/);
DLLExport
modelica_integer omc_Settings_getEcho(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Settings_getEcho(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Settings_getEcho,2,0) {(void*) boxptr_Settings_getEcho,0}};
#define boxvar_Settings_getEcho MMC_REFSTRUCTLIT(boxvar_lit_Settings_getEcho)
extern int Settings_getEcho();
DLLExport
modelica_string omc_Settings_getHomeDir(threadData_t *threadData, modelica_boolean _runningTestsuite);
DLLExport
modelica_metatype boxptr_Settings_getHomeDir(threadData_t *threadData, modelica_metatype _runningTestsuite);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Settings_getHomeDir,2,0) {(void*) boxptr_Settings_getHomeDir,0}};
#define boxvar_Settings_getHomeDir MMC_REFSTRUCTLIT(boxvar_lit_Settings_getHomeDir)
extern const char* Settings_getHomeDir(int /*_runningTestsuite*/);
DLLExport
modelica_string omc_Settings_getModelicaPath(threadData_t *threadData, modelica_boolean _runningTestsuite);
DLLExport
modelica_metatype boxptr_Settings_getModelicaPath(threadData_t *threadData, modelica_metatype _runningTestsuite);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Settings_getModelicaPath,2,0) {(void*) boxptr_Settings_getModelicaPath,0}};
#define boxvar_Settings_getModelicaPath MMC_REFSTRUCTLIT(boxvar_lit_Settings_getModelicaPath)
extern const char* Settings_getModelicaPath(int /*_runningTestsuite*/);
DLLExport
void omc_Settings_setModelicaPath(threadData_t *threadData, modelica_string _inString);
#define boxptr_Settings_setModelicaPath omc_Settings_setModelicaPath
static const MMC_DEFSTRUCTLIT(boxvar_lit_Settings_setModelicaPath,2,0) {(void*) boxptr_Settings_setModelicaPath,0}};
#define boxvar_Settings_setModelicaPath MMC_REFSTRUCTLIT(boxvar_lit_Settings_setModelicaPath)
extern void SettingsImpl__setModelicaPath(const char* /*_inString*/);
DLLExport
modelica_string omc_Settings_getInstallationDirectoryPath(threadData_t *threadData);
#define boxptr_Settings_getInstallationDirectoryPath omc_Settings_getInstallationDirectoryPath
static const MMC_DEFSTRUCTLIT(boxvar_lit_Settings_getInstallationDirectoryPath,2,0) {(void*) boxptr_Settings_getInstallationDirectoryPath,0}};
#define boxvar_Settings_getInstallationDirectoryPath MMC_REFSTRUCTLIT(boxvar_lit_Settings_getInstallationDirectoryPath)
extern const char* Settings_getInstallationDirectoryPath();
DLLExport
void omc_Settings_setInstallationDirectoryPath(threadData_t *threadData, modelica_string _inString);
#define boxptr_Settings_setInstallationDirectoryPath omc_Settings_setInstallationDirectoryPath
static const MMC_DEFSTRUCTLIT(boxvar_lit_Settings_setInstallationDirectoryPath,2,0) {(void*) boxptr_Settings_setInstallationDirectoryPath,0}};
#define boxvar_Settings_setInstallationDirectoryPath MMC_REFSTRUCTLIT(boxvar_lit_Settings_setInstallationDirectoryPath)
extern void SettingsImpl__setInstallationDirectoryPath(const char* /*_inString*/);
DLLExport
modelica_string omc_Settings_getTempDirectoryPath(threadData_t *threadData);
#define boxptr_Settings_getTempDirectoryPath omc_Settings_getTempDirectoryPath
static const MMC_DEFSTRUCTLIT(boxvar_lit_Settings_getTempDirectoryPath,2,0) {(void*) boxptr_Settings_getTempDirectoryPath,0}};
#define boxvar_Settings_getTempDirectoryPath MMC_REFSTRUCTLIT(boxvar_lit_Settings_getTempDirectoryPath)
extern const char* Settings_getTempDirectoryPath();
DLLExport
void omc_Settings_setTempDirectoryPath(threadData_t *threadData, modelica_string _inString);
#define boxptr_Settings_setTempDirectoryPath omc_Settings_setTempDirectoryPath
static const MMC_DEFSTRUCTLIT(boxvar_lit_Settings_setTempDirectoryPath,2,0) {(void*) boxptr_Settings_setTempDirectoryPath,0}};
#define boxvar_Settings_setTempDirectoryPath MMC_REFSTRUCTLIT(boxvar_lit_Settings_setTempDirectoryPath)
extern void SettingsImpl__setTempDirectoryPath(const char* /*_inString*/);
DLLExport
modelica_string omc_Settings_getCompileCommand(threadData_t *threadData);
#define boxptr_Settings_getCompileCommand omc_Settings_getCompileCommand
static const MMC_DEFSTRUCTLIT(boxvar_lit_Settings_getCompileCommand,2,0) {(void*) boxptr_Settings_getCompileCommand,0}};
#define boxvar_Settings_getCompileCommand MMC_REFSTRUCTLIT(boxvar_lit_Settings_getCompileCommand)
extern const char* Settings_getCompileCommand();
DLLExport
void omc_Settings_setCompileCommand(threadData_t *threadData, modelica_string _inString);
#define boxptr_Settings_setCompileCommand omc_Settings_setCompileCommand
static const MMC_DEFSTRUCTLIT(boxvar_lit_Settings_setCompileCommand,2,0) {(void*) boxptr_Settings_setCompileCommand,0}};
#define boxvar_Settings_setCompileCommand MMC_REFSTRUCTLIT(boxvar_lit_Settings_setCompileCommand)
extern void SettingsImpl__setCompileCommand(const char* /*_inString*/);
DLLExport
void omc_Settings_setCompilePath(threadData_t *threadData, modelica_string _inString);
#define boxptr_Settings_setCompilePath omc_Settings_setCompilePath
static const MMC_DEFSTRUCTLIT(boxvar_lit_Settings_setCompilePath,2,0) {(void*) boxptr_Settings_setCompilePath,0}};
#define boxvar_Settings_setCompilePath MMC_REFSTRUCTLIT(boxvar_lit_Settings_setCompilePath)
extern void SettingsImpl__setCompilePath(const char* /*_inString*/);
DLLExport
modelica_string omc_Settings_getVersionNr(threadData_t *threadData);
#define boxptr_Settings_getVersionNr omc_Settings_getVersionNr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Settings_getVersionNr,2,0) {(void*) boxptr_Settings_getVersionNr,0}};
#define boxvar_Settings_getVersionNr MMC_REFSTRUCTLIT(boxvar_lit_Settings_getVersionNr)
extern const char* Settings_getVersionNr();
#ifdef __cplusplus
}
#endif
#endif
