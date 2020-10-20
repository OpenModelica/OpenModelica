#ifndef GraphStreamExt__H
#define GraphStreamExt__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
void omc_GraphStreamExt_cleanup(threadData_t *threadData);
#define boxptr_GraphStreamExt_cleanup omc_GraphStreamExt_cleanup
static const MMC_DEFSTRUCTLIT(boxvar_lit_GraphStreamExt_cleanup,2,0) {(void*) boxptr_GraphStreamExt_cleanup,0}};
#define boxvar_GraphStreamExt_cleanup MMC_REFSTRUCTLIT(boxvar_lit_GraphStreamExt_cleanup)
extern void GraphStreamExt_cleanup(OpenModelica_threadData_ThreadData*);
DLLExport
void omc_GraphStreamExt_changeGraphAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew);
DLLExport
void boxptr_GraphStreamExt_changeGraphAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GraphStreamExt_changeGraphAttribute,2,0) {(void*) boxptr_GraphStreamExt_changeGraphAttribute,0}};
#define boxvar_GraphStreamExt_changeGraphAttribute MMC_REFSTRUCTLIT(boxvar_lit_GraphStreamExt_changeGraphAttribute)
extern void GraphStreamExt_changeGraphAttribute(OpenModelica_threadData_ThreadData*, const char* /*_streamName*/, const char* /*_sourceId*/, int /*_timeId*/, const char* /*_attributeName*/, modelica_metatype /*_attributeValueOld*/, modelica_metatype /*_attributeValueNew*/);
DLLExport
void omc_GraphStreamExt_addGraphAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _attributeName, modelica_metatype _attributeValue);
DLLExport
void boxptr_GraphStreamExt_addGraphAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _attributeName, modelica_metatype _attributeValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GraphStreamExt_addGraphAttribute,2,0) {(void*) boxptr_GraphStreamExt_addGraphAttribute,0}};
#define boxvar_GraphStreamExt_addGraphAttribute MMC_REFSTRUCTLIT(boxvar_lit_GraphStreamExt_addGraphAttribute)
extern void GraphStreamExt_addGraphAttribute(OpenModelica_threadData_ThreadData*, const char* /*_streamName*/, const char* /*_sourceId*/, int /*_timeId*/, const char* /*_attributeName*/, modelica_metatype /*_attributeValue*/);
DLLExport
void omc_GraphStreamExt_changeEdgeAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeIdSource, modelica_string _nodeIdTarget, modelica_string _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew);
DLLExport
void boxptr_GraphStreamExt_changeEdgeAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeIdSource, modelica_metatype _nodeIdTarget, modelica_metatype _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GraphStreamExt_changeEdgeAttribute,2,0) {(void*) boxptr_GraphStreamExt_changeEdgeAttribute,0}};
#define boxvar_GraphStreamExt_changeEdgeAttribute MMC_REFSTRUCTLIT(boxvar_lit_GraphStreamExt_changeEdgeAttribute)
extern void GraphStreamExt_changeEdgeAttribute(OpenModelica_threadData_ThreadData*, const char* /*_streamName*/, const char* /*_sourceId*/, int /*_timeId*/, const char* /*_nodeIdSource*/, const char* /*_nodeIdTarget*/, const char* /*_attributeName*/, modelica_metatype /*_attributeValueOld*/, modelica_metatype /*_attributeValueNew*/);
DLLExport
void omc_GraphStreamExt_addEdgeAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeIdSource, modelica_string _nodeIdTarget, modelica_string _attributeName, modelica_metatype _attributeValue);
DLLExport
void boxptr_GraphStreamExt_addEdgeAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeIdSource, modelica_metatype _nodeIdTarget, modelica_metatype _attributeName, modelica_metatype _attributeValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GraphStreamExt_addEdgeAttribute,2,0) {(void*) boxptr_GraphStreamExt_addEdgeAttribute,0}};
#define boxvar_GraphStreamExt_addEdgeAttribute MMC_REFSTRUCTLIT(boxvar_lit_GraphStreamExt_addEdgeAttribute)
extern void GraphStreamExt_addEdgeAttribute(OpenModelica_threadData_ThreadData*, const char* /*_streamName*/, const char* /*_sourceId*/, int /*_timeId*/, const char* /*_nodeIdSource*/, const char* /*_nodeIdTarget*/, const char* /*_attributeName*/, modelica_metatype /*_attributeValue*/);
DLLExport
void omc_GraphStreamExt_changeNodeAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeId, modelica_string _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew);
DLLExport
void boxptr_GraphStreamExt_changeNodeAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeId, modelica_metatype _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GraphStreamExt_changeNodeAttribute,2,0) {(void*) boxptr_GraphStreamExt_changeNodeAttribute,0}};
#define boxvar_GraphStreamExt_changeNodeAttribute MMC_REFSTRUCTLIT(boxvar_lit_GraphStreamExt_changeNodeAttribute)
extern void GraphStreamExt_changeNodeAttribute(OpenModelica_threadData_ThreadData*, const char* /*_streamName*/, const char* /*_sourceId*/, int /*_timeId*/, const char* /*_nodeId*/, const char* /*_attributeName*/, modelica_metatype /*_attributeValueOld*/, modelica_metatype /*_attributeValueNew*/);
DLLExport
void omc_GraphStreamExt_addNodeAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeId, modelica_string _attributeName, modelica_metatype _attributeValue);
DLLExport
void boxptr_GraphStreamExt_addNodeAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeId, modelica_metatype _attributeName, modelica_metatype _attributeValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GraphStreamExt_addNodeAttribute,2,0) {(void*) boxptr_GraphStreamExt_addNodeAttribute,0}};
#define boxvar_GraphStreamExt_addNodeAttribute MMC_REFSTRUCTLIT(boxvar_lit_GraphStreamExt_addNodeAttribute)
extern void GraphStreamExt_addNodeAttribute(OpenModelica_threadData_ThreadData*, const char* /*_streamName*/, const char* /*_sourceId*/, int /*_timeId*/, const char* /*_nodeId*/, const char* /*_attributeName*/, modelica_metatype /*_attributeValue*/);
DLLExport
void omc_GraphStreamExt_addEdge(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeIdSource, modelica_string _nodeIdTarget, modelica_boolean _directed);
DLLExport
void boxptr_GraphStreamExt_addEdge(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeIdSource, modelica_metatype _nodeIdTarget, modelica_metatype _directed);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GraphStreamExt_addEdge,2,0) {(void*) boxptr_GraphStreamExt_addEdge,0}};
#define boxvar_GraphStreamExt_addEdge MMC_REFSTRUCTLIT(boxvar_lit_GraphStreamExt_addEdge)
extern void GraphStreamExt_addEdge(OpenModelica_threadData_ThreadData*, const char* /*_streamName*/, const char* /*_sourceId*/, int /*_timeId*/, const char* /*_nodeIdSource*/, const char* /*_nodeIdTarget*/, int /*_directed*/);
DLLExport
void omc_GraphStreamExt_addNode(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeId);
DLLExport
void boxptr_GraphStreamExt_addNode(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeId);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GraphStreamExt_addNode,2,0) {(void*) boxptr_GraphStreamExt_addNode,0}};
#define boxvar_GraphStreamExt_addNode MMC_REFSTRUCTLIT(boxvar_lit_GraphStreamExt_addNode)
extern void GraphStreamExt_addNode(OpenModelica_threadData_ThreadData*, const char* /*_streamName*/, const char* /*_sourceId*/, int /*_timeId*/, const char* /*_nodeId*/);
DLLExport
void omc_GraphStreamExt_newStream(threadData_t *threadData, modelica_string _streamName, modelica_string _host, modelica_integer _port, modelica_boolean _debug);
DLLExport
void boxptr_GraphStreamExt_newStream(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _host, modelica_metatype _port, modelica_metatype _debug);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GraphStreamExt_newStream,2,0) {(void*) boxptr_GraphStreamExt_newStream,0}};
#define boxvar_GraphStreamExt_newStream MMC_REFSTRUCTLIT(boxvar_lit_GraphStreamExt_newStream)
extern void GraphStreamExt_newStream(OpenModelica_threadData_ThreadData*, const char* /*_streamName*/, const char* /*_host*/, int /*_port*/, int /*_debug*/);
#ifdef __cplusplus
}
#endif
#endif
