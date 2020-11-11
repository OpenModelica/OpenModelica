#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/Corba.c"
#endif
#include "omc_simulation_settings.h"
#include "Corba.h"
#include "util/modelica.h"
#include "Corba_includes.h"
void omc_Corba_close(threadData_t *threadData)
{
Corba_close();
return;
}
void omc_Corba_sendreply(threadData_t *threadData, modelica_string _inString)
{
Corba_sendreply(MMC_STRINGDATA(_inString));
return;
}
modelica_string omc_Corba_waitForCommand(threadData_t *threadData)
{
const char* _outString_ext;
modelica_string _outString = NULL;
_outString_ext = Corba_waitForCommand();
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
void omc_Corba_initialize(threadData_t *threadData)
{
Corba_initialize();
return;
}
void omc_Corba_setSessionName(threadData_t *threadData, modelica_string _inSessionName)
{
Corba_setSessionName(MMC_STRINGDATA(_inSessionName));
return;
}
void omc_Corba_setObjectReferenceFilePath(threadData_t *threadData, modelica_string _inObjectReferenceFilePath)
{
Corba_setObjectReferenceFilePath(MMC_STRINGDATA(_inObjectReferenceFilePath));
return;
}
modelica_boolean omc_Corba_haveCorba(threadData_t *threadData)
{
int _b_ext;
modelica_boolean _b;
_b_ext = Corba_haveCorba();
_b = (modelica_boolean)_b_ext;
return _b;
}
modelica_metatype boxptr_Corba_haveCorba(threadData_t *threadData)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_Corba_haveCorba(threadData);
out_b = mmc_mk_icon(_b);
return out_b;
}
