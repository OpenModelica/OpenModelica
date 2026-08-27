#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/Settings.c"
#endif
#include "omc_simulation_settings.h"
#include "Settings.h"
#include "util/modelica.h"
#include "Settings_includes.h"
void omc_Settings_setEcho(threadData_t *threadData, modelica_integer _echo)
{
int _echo_ext;
_echo_ext = (int)_echo;
Settings_setEcho(_echo_ext);
return;
}
void boxptr_Settings_setEcho(threadData_t *threadData, modelica_metatype _echo)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_echo);
omc_Settings_setEcho(threadData, tmp1);
return;
}
modelica_integer omc_Settings_getEcho(threadData_t *threadData)
{
int _echo_ext;
modelica_integer _echo;
_echo_ext = Settings_getEcho();
_echo = (modelica_integer)_echo_ext;
return _echo;
}
modelica_metatype boxptr_Settings_getEcho(threadData_t *threadData)
{
modelica_integer _echo;
modelica_metatype out_echo;
_echo = omc_Settings_getEcho(threadData);
out_echo = mmc_mk_icon(_echo);
return out_echo;
}
modelica_string omc_Settings_getHomeDir(threadData_t *threadData, modelica_boolean _runningTestsuite)
{
int _runningTestsuite_ext;
const char* _outString_ext;
modelica_string _outString = NULL;
_runningTestsuite_ext = (int)_runningTestsuite;
_outString_ext = Settings_getHomeDir(_runningTestsuite_ext);
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
modelica_metatype boxptr_Settings_getHomeDir(threadData_t *threadData, modelica_metatype _runningTestsuite)
{
modelica_integer tmp1;
modelica_string _outString = NULL;
tmp1 = mmc_unbox_integer(_runningTestsuite);
_outString = omc_Settings_getHomeDir(threadData, tmp1);
return _outString;
}
modelica_string omc_Settings_getModelicaPath(threadData_t *threadData, modelica_boolean _runningTestsuite)
{
int _runningTestsuite_ext;
const char* _outString_ext;
modelica_string _outString = NULL;
_runningTestsuite_ext = (int)_runningTestsuite;
_outString_ext = Settings_getModelicaPath(_runningTestsuite_ext);
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
modelica_metatype boxptr_Settings_getModelicaPath(threadData_t *threadData, modelica_metatype _runningTestsuite)
{
modelica_integer tmp1;
modelica_string _outString = NULL;
tmp1 = mmc_unbox_integer(_runningTestsuite);
_outString = omc_Settings_getModelicaPath(threadData, tmp1);
return _outString;
}
void omc_Settings_setModelicaPath(threadData_t *threadData, modelica_string _inString)
{
SettingsImpl__setModelicaPath(MMC_STRINGDATA(_inString));
return;
}
modelica_string omc_Settings_getInstallationDirectoryPath(threadData_t *threadData)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = Settings_getInstallationDirectoryPath();
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
void omc_Settings_setInstallationDirectoryPath(threadData_t *threadData, modelica_string _inString)
{
SettingsImpl__setInstallationDirectoryPath(MMC_STRINGDATA(_inString));
return;
}
modelica_string omc_Settings_getTempDirectoryPath(threadData_t *threadData)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = Settings_getTempDirectoryPath();
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
void omc_Settings_setTempDirectoryPath(threadData_t *threadData, modelica_string _inString)
{
SettingsImpl__setTempDirectoryPath(MMC_STRINGDATA(_inString));
return;
}
modelica_string omc_Settings_getCompileCommand(threadData_t *threadData)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = Settings_getCompileCommand();
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
void omc_Settings_setCompileCommand(threadData_t *threadData, modelica_string _inString)
{
SettingsImpl__setCompileCommand(MMC_STRINGDATA(_inString));
return;
}
void omc_Settings_setCompilePath(threadData_t *threadData, modelica_string _inString)
{
SettingsImpl__setCompilePath(MMC_STRINGDATA(_inString));
return;
}
modelica_string omc_Settings_getVersionNr(threadData_t *threadData)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = Settings_getVersionNr();
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
