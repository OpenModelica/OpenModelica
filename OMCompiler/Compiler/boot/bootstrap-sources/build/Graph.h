#ifndef Graph__H
#define Graph__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description ErrorTypes_Message_MESSAGE__desc;
extern struct record_description ErrorTypes_MessageType_TRANSLATION__desc;
extern struct record_description ErrorTypes_Severity_ERROR__desc;
extern struct record_description Gettext_TranslatableContent_gettext__desc;
extern struct record_description SourceInfo_SOURCEINFO__desc;
#define boxptr_Graph_merge2 omc_Graph_merge2
DLLExport
modelica_metatype omc_Graph_merge(threadData_t *threadData, modelica_metatype _graph1, modelica_metatype _graph2, modelica_fnptr _eqFunc, modelica_fnptr _compareFunc);
#define boxptr_Graph_merge omc_Graph_merge
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graph_merge,2,0) {(void*) boxptr_Graph_merge,0}};
#define boxvar_Graph_merge MMC_REFSTRUCTLIT(boxvar_lit_Graph_merge)
#define boxptr_Graph_filterGraph2 omc_Graph_filterGraph2
DLLExport
modelica_metatype omc_Graph_filterGraph(threadData_t *threadData, modelica_metatype _inGraph, modelica_fnptr _inCondFunc);
#define boxptr_Graph_filterGraph omc_Graph_filterGraph
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graph_filterGraph,2,0) {(void*) boxptr_Graph_filterGraph,0}};
#define boxvar_Graph_filterGraph MMC_REFSTRUCTLIT(boxvar_lit_Graph_filterGraph)
DLLExport
void omc_Graph_partialDistance2colorInt(threadData_t *threadData, modelica_metatype _inGraphT, modelica_metatype _inforbiddenColor, modelica_metatype _inColors, modelica_metatype _inGraph, modelica_metatype _inColored);
#define boxptr_Graph_partialDistance2colorInt omc_Graph_partialDistance2colorInt
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graph_partialDistance2colorInt,2,0) {(void*) boxptr_Graph_partialDistance2colorInt,0}};
#define boxvar_Graph_partialDistance2colorInt MMC_REFSTRUCTLIT(boxvar_lit_Graph_partialDistance2colorInt)
DLLExport
modelica_metatype omc_Graph_allReachableNodesInt(threadData_t *threadData, modelica_metatype _intmpstorage, modelica_metatype _inGraph, modelica_integer _inMaxGraphNode, modelica_integer _inMaxNodexIndex);
DLLExport
modelica_metatype boxptr_Graph_allReachableNodesInt(threadData_t *threadData, modelica_metatype _intmpstorage, modelica_metatype _inGraph, modelica_metatype _inMaxGraphNode, modelica_metatype _inMaxNodexIndex);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graph_allReachableNodesInt,2,0) {(void*) boxptr_Graph_allReachableNodesInt,0}};
#define boxvar_Graph_allReachableNodesInt MMC_REFSTRUCTLIT(boxvar_lit_Graph_allReachableNodesInt)
DLLExport
void omc_Graph_printNodesInt(threadData_t *threadData, modelica_metatype _inListNodes, modelica_string _inName);
#define boxptr_Graph_printNodesInt omc_Graph_printNodesInt
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graph_printNodesInt,2,0) {(void*) boxptr_Graph_printNodesInt,0}};
#define boxvar_Graph_printNodesInt MMC_REFSTRUCTLIT(boxvar_lit_Graph_printNodesInt)
DLLExport
void omc_Graph_printGraphInt(threadData_t *threadData, modelica_metatype _inGraph);
#define boxptr_Graph_printGraphInt omc_Graph_printGraphInt
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graph_printGraphInt,2,0) {(void*) boxptr_Graph_printGraphInt,0}};
#define boxvar_Graph_printGraphInt MMC_REFSTRUCTLIT(boxvar_lit_Graph_printGraphInt)
DLLExport
modelica_string omc_Graph_printNode(threadData_t *threadData, modelica_metatype _inNode, modelica_fnptr _inPrintFunc);
#define boxptr_Graph_printNode omc_Graph_printNode
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graph_printNode,2,0) {(void*) boxptr_Graph_printNode,0}};
#define boxvar_Graph_printNode MMC_REFSTRUCTLIT(boxvar_lit_Graph_printNode)
DLLExport
modelica_string omc_Graph_printGraph(threadData_t *threadData, modelica_metatype _inGraph, modelica_fnptr _inPrintFunc);
#define boxptr_Graph_printGraph omc_Graph_printGraph
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graph_printGraph,2,0) {(void*) boxptr_Graph_printGraph,0}};
#define boxvar_Graph_printGraph MMC_REFSTRUCTLIT(boxvar_lit_Graph_printGraph)
#define boxptr_Graph_addForbiddenColors omc_Graph_addForbiddenColors
DLLExport
modelica_metatype omc_Graph_partialDistance2color(threadData_t *threadData, modelica_metatype _toColorNodes, modelica_metatype _inforbiddenColor, modelica_metatype _inColors, modelica_metatype _inGraph, modelica_metatype _inGraphT, modelica_metatype _inColored, modelica_fnptr _inEqualFunc, modelica_fnptr _inPrintFunc);
#define boxptr_Graph_partialDistance2color omc_Graph_partialDistance2color
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graph_partialDistance2color,2,0) {(void*) boxptr_Graph_partialDistance2color,0}};
#define boxvar_Graph_partialDistance2color MMC_REFSTRUCTLIT(boxvar_lit_Graph_partialDistance2color)
#define boxptr_Graph_allReachableNodesWork omc_Graph_allReachableNodesWork
DLLExport
modelica_metatype omc_Graph_allReachableNodes(threadData_t *threadData, modelica_metatype _intmpstorage, modelica_metatype _inGraph, modelica_fnptr _inEqualFunc);
#define boxptr_Graph_allReachableNodes omc_Graph_allReachableNodes
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graph_allReachableNodes,2,0) {(void*) boxptr_Graph_allReachableNodes,0}};
#define boxvar_Graph_allReachableNodes MMC_REFSTRUCTLIT(boxvar_lit_Graph_allReachableNodes)
#define boxptr_Graph_insertNodetoGraph omc_Graph_insertNodetoGraph
DLLExport
modelica_metatype omc_Graph_transposeGraph(threadData_t *threadData, modelica_metatype _intmpGraph, modelica_metatype _inGraph, modelica_fnptr _inEqualFunc);
#define boxptr_Graph_transposeGraph omc_Graph_transposeGraph
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graph_transposeGraph,2,0) {(void*) boxptr_Graph_transposeGraph,0}};
#define boxvar_Graph_transposeGraph MMC_REFSTRUCTLIT(boxvar_lit_Graph_transposeGraph)
#define boxptr_Graph_removeNodesFromGraph omc_Graph_removeNodesFromGraph
#define boxptr_Graph_findNodeInGraph omc_Graph_findNodeInGraph
#define boxptr_Graph_findCycleForNode2 omc_Graph_findCycleForNode2
#define boxptr_Graph_findCycleForNode omc_Graph_findCycleForNode
DLLExport
modelica_metatype omc_Graph_findCycles2(threadData_t *threadData, modelica_metatype _inNodes, modelica_metatype _inGraph, modelica_fnptr _inEqualFunc);
#define boxptr_Graph_findCycles2 omc_Graph_findCycles2
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graph_findCycles2,2,0) {(void*) boxptr_Graph_findCycles2,0}};
#define boxvar_Graph_findCycles2 MMC_REFSTRUCTLIT(boxvar_lit_Graph_findCycles2)
DLLExport
modelica_metatype omc_Graph_findCycles(threadData_t *threadData, modelica_metatype _inGraph, modelica_fnptr _inEqualFunc);
#define boxptr_Graph_findCycles omc_Graph_findCycles
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graph_findCycles,2,0) {(void*) boxptr_Graph_findCycles,0}};
#define boxvar_Graph_findCycles MMC_REFSTRUCTLIT(boxvar_lit_Graph_findCycles)
#define boxptr_Graph_removeEdge omc_Graph_removeEdge
#define boxptr_Graph_topologicalSort2 omc_Graph_topologicalSort2
DLLExport
modelica_metatype omc_Graph_topologicalSort(threadData_t *threadData, modelica_metatype _inGraph, modelica_fnptr _inEqualFunc, modelica_metatype *out_outRemainingGraph);
#define boxptr_Graph_topologicalSort omc_Graph_topologicalSort
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graph_topologicalSort,2,0) {(void*) boxptr_Graph_topologicalSort,0}};
#define boxvar_Graph_topologicalSort MMC_REFSTRUCTLIT(boxvar_lit_Graph_topologicalSort)
#define boxptr_Graph_emptyGraphHelper omc_Graph_emptyGraphHelper
DLLExport
modelica_metatype omc_Graph_emptyGraph(threadData_t *threadData, modelica_metatype _inNodes);
#define boxptr_Graph_emptyGraph omc_Graph_emptyGraph
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graph_emptyGraph,2,0) {(void*) boxptr_Graph_emptyGraph,0}};
#define boxvar_Graph_emptyGraph MMC_REFSTRUCTLIT(boxvar_lit_Graph_emptyGraph)
DLLExport
modelica_metatype omc_Graph_buildGraph(threadData_t *threadData, modelica_metatype _inNodes, modelica_fnptr _inEdgeFunc, modelica_metatype _inEdgeArg);
#define boxptr_Graph_buildGraph omc_Graph_buildGraph
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graph_buildGraph,2,0) {(void*) boxptr_Graph_buildGraph,0}};
#define boxvar_Graph_buildGraph MMC_REFSTRUCTLIT(boxvar_lit_Graph_buildGraph)
#ifdef __cplusplus
}
#endif
#endif
