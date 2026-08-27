#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/Socket.c"
#endif
#include "omc_simulation_settings.h"
#include "Socket.h"
#include "util/modelica.h"
#include "Socket_includes.h"
void omc_Socket_cleanup(threadData_t *threadData)
{
Socket_cleanup();
return;
}
void omc_Socket_close(threadData_t *threadData, modelica_integer _inInteger)
{
int _inInteger_ext;
_inInteger_ext = (int)_inInteger;
Socket_close(_inInteger_ext);
return;
}
void boxptr_Socket_close(threadData_t *threadData, modelica_metatype _inInteger)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_inInteger);
omc_Socket_close(threadData, tmp1);
return;
}
void omc_Socket_sendreply(threadData_t *threadData, modelica_integer _inInteger, modelica_string _inString)
{
int _inInteger_ext;
_inInteger_ext = (int)_inInteger;
Socket_sendreply(_inInteger_ext, MMC_STRINGDATA(_inString));
return;
}
void boxptr_Socket_sendreply(threadData_t *threadData, modelica_metatype _inInteger, modelica_metatype _inString)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_inInteger);
omc_Socket_sendreply(threadData, tmp1, _inString);
return;
}
modelica_string omc_Socket_handlerequest(threadData_t *threadData, modelica_integer _inInteger)
{
int _inInteger_ext;
const char* _outString_ext;
modelica_string _outString = NULL;
_inInteger_ext = (int)_inInteger;
_outString_ext = Socket_handlerequest(_inInteger_ext);
_outString = (modelica_string)mmc_mk_scon(_outString_ext);
return _outString;
}
modelica_metatype boxptr_Socket_handlerequest(threadData_t *threadData, modelica_metatype _inInteger)
{
modelica_integer tmp1;
modelica_string _outString = NULL;
tmp1 = mmc_unbox_integer(_inInteger);
_outString = omc_Socket_handlerequest(threadData, tmp1);
return _outString;
}
modelica_integer omc_Socket_waitforconnect(threadData_t *threadData, modelica_integer _inInteger)
{
int _inInteger_ext;
int _outInteger_ext;
modelica_integer _outInteger;
_inInteger_ext = (int)_inInteger;
_outInteger_ext = Socket_waitforconnect(_inInteger_ext);
_outInteger = (modelica_integer)_outInteger_ext;
return _outInteger;
}
modelica_metatype boxptr_Socket_waitforconnect(threadData_t *threadData, modelica_metatype _inInteger)
{
modelica_integer tmp1;
modelica_integer _outInteger;
modelica_metatype out_outInteger;
tmp1 = mmc_unbox_integer(_inInteger);
_outInteger = omc_Socket_waitforconnect(threadData, tmp1);
out_outInteger = mmc_mk_icon(_outInteger);
return out_outInteger;
}
