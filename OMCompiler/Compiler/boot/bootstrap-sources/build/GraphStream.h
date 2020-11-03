#ifndef GraphStream__H
#define GraphStream__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
void omc_GraphStream_cleanup(threadData_t *threadData);
#define boxptr_GraphStream_cleanup omc_GraphStream_cleanup
static const MMC_DEFSTRUCTLIT(boxvar_lit_GraphStream_cleanup,2,0) {(void*) boxptr_GraphStream_cleanup,0}};
#define boxvar_GraphStream_cleanup MMC_REFSTRUCTLIT(boxvar_lit_GraphStream_cleanup)
DLLExport
void omc_GraphStream_changeGraphAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew);
DLLExport
void boxptr_GraphStream_changeGraphAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GraphStream_changeGraphAttribute,2,0) {(void*) boxptr_GraphStream_changeGraphAttribute,0}};
#define boxvar_GraphStream_changeGraphAttribute MMC_REFSTRUCTLIT(boxvar_lit_GraphStream_changeGraphAttribute)
DLLExport
void omc_GraphStream_addGraphAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _attributeName, modelica_metatype _attributeValue);
DLLExport
void boxptr_GraphStream_addGraphAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _attributeName, modelica_metatype _attributeValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GraphStream_addGraphAttribute,2,0) {(void*) boxptr_GraphStream_addGraphAttribute,0}};
#define boxvar_GraphStream_addGraphAttribute MMC_REFSTRUCTLIT(boxvar_lit_GraphStream_addGraphAttribute)
DLLExport
void omc_GraphStream_changeEdgeAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeIdSource, modelica_string _nodeIdTarget, modelica_string _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew);
DLLExport
void boxptr_GraphStream_changeEdgeAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeIdSource, modelica_metatype _nodeIdTarget, modelica_metatype _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GraphStream_changeEdgeAttribute,2,0) {(void*) boxptr_GraphStream_changeEdgeAttribute,0}};
#define boxvar_GraphStream_changeEdgeAttribute MMC_REFSTRUCTLIT(boxvar_lit_GraphStream_changeEdgeAttribute)
DLLExport
void omc_GraphStream_addEdgeAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeIdSource, modelica_string _nodeIdTarget, modelica_string _attributeName, modelica_metatype _attributeValue);
DLLExport
void boxptr_GraphStream_addEdgeAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeIdSource, modelica_metatype _nodeIdTarget, modelica_metatype _attributeName, modelica_metatype _attributeValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GraphStream_addEdgeAttribute,2,0) {(void*) boxptr_GraphStream_addEdgeAttribute,0}};
#define boxvar_GraphStream_addEdgeAttribute MMC_REFSTRUCTLIT(boxvar_lit_GraphStream_addEdgeAttribute)
DLLExport
void omc_GraphStream_changeNodeAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeId, modelica_string _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew);
DLLExport
void boxptr_GraphStream_changeNodeAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeId, modelica_metatype _attributeName, modelica_metatype _attributeValueOld, modelica_metatype _attributeValueNew);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GraphStream_changeNodeAttribute,2,0) {(void*) boxptr_GraphStream_changeNodeAttribute,0}};
#define boxvar_GraphStream_changeNodeAttribute MMC_REFSTRUCTLIT(boxvar_lit_GraphStream_changeNodeAttribute)
DLLExport
void omc_GraphStream_addNodeAttribute(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeId, modelica_string _attributeName, modelica_metatype _attributeValue);
DLLExport
void boxptr_GraphStream_addNodeAttribute(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeId, modelica_metatype _attributeName, modelica_metatype _attributeValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GraphStream_addNodeAttribute,2,0) {(void*) boxptr_GraphStream_addNodeAttribute,0}};
#define boxvar_GraphStream_addNodeAttribute MMC_REFSTRUCTLIT(boxvar_lit_GraphStream_addNodeAttribute)
DLLExport
void omc_GraphStream_addEdge(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeIdSource, modelica_string _nodeIdTarget, modelica_boolean _directed);
DLLExport
void boxptr_GraphStream_addEdge(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeIdSource, modelica_metatype _nodeIdTarget, modelica_metatype _directed);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GraphStream_addEdge,2,0) {(void*) boxptr_GraphStream_addEdge,0}};
#define boxvar_GraphStream_addEdge MMC_REFSTRUCTLIT(boxvar_lit_GraphStream_addEdge)
DLLExport
void omc_GraphStream_addNode(threadData_t *threadData, modelica_string _streamName, modelica_string _sourceId, modelica_integer _timeId, modelica_string _nodeId);
DLLExport
void boxptr_GraphStream_addNode(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _sourceId, modelica_metatype _timeId, modelica_metatype _nodeId);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GraphStream_addNode,2,0) {(void*) boxptr_GraphStream_addNode,0}};
#define boxvar_GraphStream_addNode MMC_REFSTRUCTLIT(boxvar_lit_GraphStream_addNode)
DLLExport
void omc_GraphStream_newStream(threadData_t *threadData, modelica_string _streamName, modelica_string _host, modelica_integer _port, modelica_boolean _debug);
DLLExport
void boxptr_GraphStream_newStream(threadData_t *threadData, modelica_metatype _streamName, modelica_metatype _host, modelica_metatype _port, modelica_metatype _debug);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GraphStream_newStream,2,0) {(void*) boxptr_GraphStream_newStream,0}};
#define boxvar_GraphStream_newStream MMC_REFSTRUCTLIT(boxvar_lit_GraphStream_newStream)
DLLExport
modelica_integer omc_GraphStream_startExternalViewer(threadData_t *threadData, modelica_string _host, modelica_integer _port);
DLLExport
modelica_metatype boxptr_GraphStream_startExternalViewer(threadData_t *threadData, modelica_metatype _host, modelica_metatype _port);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GraphStream_startExternalViewer,2,0) {(void*) boxptr_GraphStream_startExternalViewer,0}};
#define boxvar_GraphStream_startExternalViewer MMC_REFSTRUCTLIT(boxvar_lit_GraphStream_startExternalViewer)
#ifdef __cplusplus
}
#endif
#endif
