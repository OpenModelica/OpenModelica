#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/ZeroMQ.c"
#endif
#include "omc_simulation_settings.h"
#include "ZeroMQ.h"
#include "util/modelica.h"
#include "ZeroMQ_includes.h"
void omc_ZeroMQ_close(threadData_t *threadData, modelica_metatype _zmqSocket)
{
modelica_metatype _zmqSocket_ext;
_zmqSocket_ext = (modelica_metatype)_zmqSocket;
ZeroMQ_close(_zmqSocket_ext);
return;
}
void omc_ZeroMQ_sendReply(threadData_t *threadData, modelica_metatype _zmqSocket, modelica_string _reply)
{
modelica_metatype _zmqSocket_ext;
_zmqSocket_ext = (modelica_metatype)_zmqSocket;
ZeroMQ_sendReply(_zmqSocket_ext, MMC_STRINGDATA(_reply));
return;
}
modelica_string omc_ZeroMQ_handleRequest(threadData_t *threadData, modelica_metatype _zmqSocket)
{
modelica_metatype _zmqSocket_ext;
const char* _request_ext;
modelica_string _request = NULL;
_zmqSocket_ext = (modelica_metatype)_zmqSocket;
_request_ext = ZeroMQ_handleRequest(_zmqSocket_ext);
_request = (modelica_string)mmc_mk_scon(_request_ext);
return _request;
}
modelica_metatype omc_ZeroMQ_initialize(threadData_t *threadData, modelica_string _fileSuffix, modelica_boolean _listenToAll, modelica_integer _port)
{
int _listenToAll_ext;
int _port_ext;
modelica_metatype _zmqSocket_ext;
modelica_metatype _zmqSocket = NULL;
_listenToAll_ext = (int)_listenToAll;
_port_ext = (int)_port;
_zmqSocket_ext = ZeroMQ_initialize(MMC_STRINGDATA(_fileSuffix), _listenToAll_ext, _port_ext);
_zmqSocket = (modelica_metatype)_zmqSocket_ext;
return _zmqSocket;
}
modelica_metatype boxptr_ZeroMQ_initialize(threadData_t *threadData, modelica_metatype _fileSuffix, modelica_metatype _listenToAll, modelica_metatype _port)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _zmqSocket = NULL;
tmp1 = mmc_unbox_integer(_listenToAll);
tmp2 = mmc_unbox_integer(_port);
_zmqSocket = omc_ZeroMQ_initialize(threadData, _fileSuffix, tmp1, tmp2);
return _zmqSocket;
}
