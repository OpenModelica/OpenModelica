#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/GraphStreamExt.c"
#endif
#include "omc_simulation_settings.h"
#include "GraphStreamExt.h"
#include "util/modelica.h"
#include "GraphStreamExt_includes.h"
void omc_GraphStreamExt_cleanup(threadData_t *threadData)
{
GraphStreamExt_cleanup(threadData);
return;
}
void omc_GraphStreamExt_changeGraphAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew)
{
int _timeId_ext;
modelica_metatype _attributeValueOld_ext;
modelica_metatype _attributeValueNew_ext;
_timeId_ext = (int)_timeId;
_attributeValueOld_ext = (modelica_metatype)_attributeValueOld;
_attributeValueNew_ext = (modelica_metatype)_attributeValueNew;
GraphStreamExt_changeGraphAttribute(threadData, MMC_STRINGDATA(_streamName), MMC_STRINGDATA(_sourceId), _timeId_ext, MMC_STRINGDATA(_attributeName), _attributeValueOld_ext, _attributeValueNew_ext);
return;
}
void boxptr_GraphStreamExt_changeGraphAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_timeId);
omc_GraphStreamExt_changeGraphAttribute(threadData, _streamName, _sourceId, tmp1, _attributeName, _attributeValueOld, _attributeValueNew);
return;
}
void omc_GraphStreamExt_addGraphAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _attributeName, modelica_metatype _attributeValue)
{
int _timeId_ext;
modelica_metatype _attributeValue_ext;
_timeId_ext = (int)_timeId;
_attributeValue_ext = (modelica_metatype)_attributeValue;
GraphStreamExt_addGraphAttribute(threadData, MMC_STRINGDATA(_streamName), MMC_STRINGDATA(_sourceId), _timeId_ext, MMC_STRINGDATA(_attributeName), _attributeValue_ext);
return;
}
void boxptr_GraphStreamExt_addGraphAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _attributeName, modelica_metatype _attributeValue)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_timeId);
omc_GraphStreamExt_addGraphAttribute(threadData, _streamName, _sourceId, tmp1, _attributeName, _attributeValue);
return;
}
void omc_GraphStreamExt_changeEdgeAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeIdSource, modelica_string _nodeIdTarget, modelica_string _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew)
{
int _timeId_ext;
modelica_metatype _attributeValueOld_ext;
modelica_metatype _attributeValueNew_ext;
_timeId_ext = (int)_timeId;
_attributeValueOld_ext = (modelica_metatype)_attributeValueOld;
_attributeValueNew_ext = (modelica_metatype)_attributeValueNew;
GraphStreamExt_changeEdgeAttribute(threadData, MMC_STRINGDATA(_streamName), MMC_STRINGDATA(_sourceId), _timeId_ext, MMC_STRINGDATA(_nodeIdSource), MMC_STRINGDATA(_nodeIdTarget), MMC_STRINGDATA(_attributeName), _attributeValueOld_ext, _attributeValueNew_ext);
return;
}
void boxptr_GraphStreamExt_changeEdgeAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeIdSource, modelica_metatype _nodeIdTarget, modelica_metatype _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_timeId);
omc_GraphStreamExt_changeEdgeAttribute(threadData, _streamName, _sourceId, tmp1, _nodeIdSource, _nodeIdTarget, _attributeName, _attributeValueOld, _attributeValueNew);
return;
}
void omc_GraphStreamExt_addEdgeAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeIdSource, modelica_string _nodeIdTarget, modelica_string _attributeName, modelica_metatype _attributeValue)
{
int _timeId_ext;
modelica_metatype _attributeValue_ext;
_timeId_ext = (int)_timeId;
_attributeValue_ext = (modelica_metatype)_attributeValue;
GraphStreamExt_addEdgeAttribute(threadData, MMC_STRINGDATA(_streamName), MMC_STRINGDATA(_sourceId), _timeId_ext, MMC_STRINGDATA(_nodeIdSource), MMC_STRINGDATA(_nodeIdTarget), MMC_STRINGDATA(_attributeName), _attributeValue_ext);
return;
}
void boxptr_GraphStreamExt_addEdgeAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeIdSource, modelica_metatype _nodeIdTarget, modelica_metatype _attributeName, modelica_metatype _attributeValue)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_timeId);
omc_GraphStreamExt_addEdgeAttribute(threadData, _streamName, _sourceId, tmp1, _nodeIdSource, _nodeIdTarget, _attributeName, _attributeValue);
return;
}
void omc_GraphStreamExt_changeNodeAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeId, modelica_string _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew)
{
int _timeId_ext;
modelica_metatype _attributeValueOld_ext;
modelica_metatype _attributeValueNew_ext;
_timeId_ext = (int)_timeId;
_attributeValueOld_ext = (modelica_metatype)_attributeValueOld;
_attributeValueNew_ext = (modelica_metatype)_attributeValueNew;
GraphStreamExt_changeNodeAttribute(threadData, MMC_STRINGDATA(_streamName), MMC_STRINGDATA(_sourceId), _timeId_ext, MMC_STRINGDATA(_nodeId), MMC_STRINGDATA(_attributeName), _attributeValueOld_ext, _attributeValueNew_ext);
return;
}
void boxptr_GraphStreamExt_changeNodeAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeId, modelica_metatype _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_timeId);
omc_GraphStreamExt_changeNodeAttribute(threadData, _streamName, _sourceId, tmp1, _nodeId, _attributeName, _attributeValueOld, _attributeValueNew);
return;
}
void omc_GraphStreamExt_addNodeAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeId, modelica_string _attributeName, modelica_metatype _attributeValue)
{
int _timeId_ext;
modelica_metatype _attributeValue_ext;
_timeId_ext = (int)_timeId;
_attributeValue_ext = (modelica_metatype)_attributeValue;
GraphStreamExt_addNodeAttribute(threadData, MMC_STRINGDATA(_streamName), MMC_STRINGDATA(_sourceId), _timeId_ext, MMC_STRINGDATA(_nodeId), MMC_STRINGDATA(_attributeName), _attributeValue_ext);
return;
}
void boxptr_GraphStreamExt_addNodeAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeId, modelica_metatype _attributeName, modelica_metatype _attributeValue)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_timeId);
omc_GraphStreamExt_addNodeAttribute(threadData, _streamName, _sourceId, tmp1, _nodeId, _attributeName, _attributeValue);
return;
}
void omc_GraphStreamExt_addEdge(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeIdSource, modelica_string _nodeIdTarget, modelica_boolean _directed)
{
int _timeId_ext;
int _directed_ext;
_timeId_ext = (int)_timeId;
_directed_ext = (int)_directed;
GraphStreamExt_addEdge(threadData, MMC_STRINGDATA(_streamName), MMC_STRINGDATA(_sourceId), _timeId_ext, MMC_STRINGDATA(_nodeIdSource), MMC_STRINGDATA(_nodeIdTarget), _directed_ext);
return;
}
void boxptr_GraphStreamExt_addEdge(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeIdSource, modelica_metatype _nodeIdTarget, modelica_metatype _directed)
{
modelica_integer tmp1;
modelica_integer tmp2;
tmp1 = mmc_unbox_integer(_timeId);
tmp2 = mmc_unbox_integer(_directed);
omc_GraphStreamExt_addEdge(threadData, _streamName, _sourceId, tmp1, _nodeIdSource, _nodeIdTarget, tmp2);
return;
}
void omc_GraphStreamExt_addNode(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeId)
{
int _timeId_ext;
_timeId_ext = (int)_timeId;
GraphStreamExt_addNode(threadData, MMC_STRINGDATA(_streamName), MMC_STRINGDATA(_sourceId), _timeId_ext, MMC_STRINGDATA(_nodeId));
return;
}
void boxptr_GraphStreamExt_addNode(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeId)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_timeId);
omc_GraphStreamExt_addNode(threadData, _streamName, _sourceId, tmp1, _nodeId);
return;
}
void omc_GraphStreamExt_newStream(threadData_t *threadData, modelica_string _streamName, modelica_string _host, modelica_integer _port, modelica_boolean _debug)
{
int _port_ext;
int _debug_ext;
_port_ext = (int)_port;
_debug_ext = (int)_debug;
GraphStreamExt_newStream(threadData, MMC_STRINGDATA(_streamName), MMC_STRINGDATA(_host), _port_ext, _debug_ext);
return;
}
void boxptr_GraphStreamExt_newStream(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _host, modelica_metatype _port, modelica_metatype _debug)
{
modelica_integer tmp1;
modelica_integer tmp2;
tmp1 = mmc_unbox_integer(_port);
tmp2 = mmc_unbox_integer(_debug);
omc_GraphStreamExt_newStream(threadData, _streamName, _host, tmp1, tmp2);
return;
}
