#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/GraphStream.c"
#endif
#include "omc_simulation_settings.h"
#include "GraphStream.h"
#define _OMC_LIT0_data "java -jar "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,10,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "/share/omc/java/org.omc.graphstream.jar &"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,41,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,0,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "GraphStream: failed to start the external viewer!\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,50,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#include "util/modelica.h"
#include "GraphStream_includes.h"
DLLExport
void omc_GraphStream_cleanup(threadData_t *threadData)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_GraphStreamExt_cleanup(threadData);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_GraphStream_changeGraphAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_GraphStreamExt_changeGraphAttribute(threadData, _streamName, _sourceId, _timeId, _attributeName, _attributeValueOld, _attributeValueNew);
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_GraphStream_changeGraphAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_timeId);
omc_GraphStream_changeGraphAttribute(threadData, _streamName, _sourceId, tmp1, _attributeName, _attributeValueOld, _attributeValueNew);
return;
}
DLLExport
void omc_GraphStream_addGraphAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _attributeName, modelica_metatype _attributeValue)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_GraphStreamExt_addGraphAttribute(threadData, _streamName, _sourceId, _timeId, _attributeName, _attributeValue);
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_GraphStream_addGraphAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _attributeName, modelica_metatype _attributeValue)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_timeId);
omc_GraphStream_addGraphAttribute(threadData, _streamName, _sourceId, tmp1, _attributeName, _attributeValue);
return;
}
DLLExport
void omc_GraphStream_changeEdgeAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeIdSource, modelica_string _nodeIdTarget, modelica_string _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_GraphStreamExt_changeEdgeAttribute(threadData, _streamName, _sourceId, _timeId, _nodeIdSource, _nodeIdTarget, _attributeName, _attributeValueOld, _attributeValueNew);
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_GraphStream_changeEdgeAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeIdSource, modelica_metatype _nodeIdTarget, modelica_metatype _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_timeId);
omc_GraphStream_changeEdgeAttribute(threadData, _streamName, _sourceId, tmp1, _nodeIdSource, _nodeIdTarget, _attributeName, _attributeValueOld, _attributeValueNew);
return;
}
DLLExport
void omc_GraphStream_addEdgeAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeIdSource, modelica_string _nodeIdTarget, modelica_string _attributeName, modelica_metatype _attributeValue)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_GraphStreamExt_addEdgeAttribute(threadData, _streamName, _sourceId, _timeId, _nodeIdSource, _nodeIdTarget, _attributeName, _attributeValue);
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_GraphStream_addEdgeAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeIdSource, modelica_metatype _nodeIdTarget, modelica_metatype _attributeName, modelica_metatype _attributeValue)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_timeId);
omc_GraphStream_addEdgeAttribute(threadData, _streamName, _sourceId, tmp1, _nodeIdSource, _nodeIdTarget, _attributeName, _attributeValue);
return;
}
DLLExport
void omc_GraphStream_changeNodeAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeId, modelica_string _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_GraphStreamExt_changeNodeAttribute(threadData, _streamName, _sourceId, _timeId, _nodeId, _attributeName, _attributeValueOld, _attributeValueNew);
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_GraphStream_changeNodeAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeId, modelica_metatype _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_timeId);
omc_GraphStream_changeNodeAttribute(threadData, _streamName, _sourceId, tmp1, _nodeId, _attributeName, _attributeValueOld, _attributeValueNew);
return;
}
DLLExport
void omc_GraphStream_addNodeAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeId, modelica_string _attributeName, modelica_metatype _attributeValue)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_GraphStreamExt_addNodeAttribute(threadData, _streamName, _sourceId, _timeId, _nodeId, _attributeName, _attributeValue);
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_GraphStream_addNodeAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeId, modelica_metatype _attributeName, modelica_metatype _attributeValue)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_timeId);
omc_GraphStream_addNodeAttribute(threadData, _streamName, _sourceId, tmp1, _nodeId, _attributeName, _attributeValue);
return;
}
DLLExport
void omc_GraphStream_addEdge(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeIdSource, modelica_string _nodeIdTarget, modelica_boolean _directed)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_GraphStreamExt_addEdge(threadData, _streamName, _sourceId, _timeId, _nodeIdSource, _nodeIdTarget, _directed);
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_GraphStream_addEdge(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeIdSource, modelica_metatype _nodeIdTarget, modelica_metatype _directed)
{
modelica_integer tmp1;
modelica_integer tmp2;
tmp1 = mmc_unbox_integer(_timeId);
tmp2 = mmc_unbox_integer(_directed);
omc_GraphStream_addEdge(threadData, _streamName, _sourceId, tmp1, _nodeIdSource, _nodeIdTarget, tmp2);
return;
}
DLLExport
void omc_GraphStream_addNode(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeId)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_GraphStreamExt_addNode(threadData, _streamName, _sourceId, _timeId, _nodeId);
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_GraphStream_addNode(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeId)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_timeId);
omc_GraphStream_addNode(threadData, _streamName, _sourceId, tmp1, _nodeId);
return;
}
DLLExport
void omc_GraphStream_newStream(threadData_t *threadData, modelica_string _streamName, modelica_string _host, modelica_integer _port, modelica_boolean _debug)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_GraphStreamExt_newStream(threadData, _streamName, _host, _port, _debug);
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_GraphStream_newStream(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _host, modelica_metatype _port, modelica_metatype _debug)
{
modelica_integer tmp1;
modelica_integer tmp2;
tmp1 = mmc_unbox_integer(_port);
tmp2 = mmc_unbox_integer(_debug);
omc_GraphStream_newStream(threadData, _streamName, _host, tmp1, tmp2);
return;
}
DLLExport
modelica_integer omc_GraphStream_startExternalViewer(threadData_t *threadData, modelica_string _host, modelica_integer _port)
{
modelica_integer _status;
modelica_integer tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_string _omhome = NULL;
modelica_string _command = NULL;
modelica_string _commandLinux = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
_omhome = omc_Settings_getInstallationDirectoryPath(threadData);
tmpMeta[0] = stringAppend(_OMC_LIT0,_omhome);
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT1);
_commandLinux = tmpMeta[1];
_command = _commandLinux;
_status = omc_System_systemCall(threadData, _command, _OMC_LIT2);
tmp6 = (_status == ((modelica_integer) 0));
if (1 != tmp6) goto goto_2;
tmp1 = _status;
goto tmp3_done;
}
case 1: {
fputs(MMC_STRINGDATA(_OMC_LIT3),stdout);
goto goto_2;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
tmp3_done:
(void)tmp4;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp3_done2;
goto_2:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp4 < 2) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_status = tmp1;
_return: OMC_LABEL_UNUSED
return _status;
}
modelica_metatype boxptr_GraphStream_startExternalViewer(threadData_t *threadData, modelica_metatype _host, modelica_metatype _port)
{
modelica_integer tmp1;
modelica_integer _status;
modelica_metatype out_status;
tmp1 = mmc_unbox_integer(_port);
_status = omc_GraphStream_startExternalViewer(threadData, _host, tmp1);
out_status = mmc_mk_icon(_status);
return out_status;
}
