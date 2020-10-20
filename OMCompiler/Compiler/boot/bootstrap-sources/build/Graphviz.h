#ifndef Graphviz__H
#define Graphviz__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description Graphviz_Attribute_ATTR__desc;
#define boxptr_Graphviz_makeAttrReq omc_Graphviz_makeAttrReq
#define boxptr_Graphviz_makeAttr omc_Graphviz_makeAttr
#define boxptr_Graphviz_makeNode omc_Graphviz_makeNode
#define boxptr_Graphviz_makeEdge omc_Graphviz_makeEdge
#define boxptr_Graphviz_printEdge omc_Graphviz_printEdge
#define boxptr_Graphviz_nodename omc_Graphviz_nodename
#define boxptr_Graphviz_dumpChildren omc_Graphviz_dumpChildren
#define boxptr_Graphviz_makeLabelReq omc_Graphviz_makeLabelReq
#define boxptr_Graphviz_makeLabel omc_Graphviz_makeLabel
#define boxptr_Graphviz_dumpNode omc_Graphviz_dumpNode
DLLExport
void omc_Graphviz_dump(threadData_t *threadData, modelica_metatype _node);
#define boxptr_Graphviz_dump omc_Graphviz_dump
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graphviz_dump,2,0) {(void*) boxptr_Graphviz_dump,0}};
#define boxvar_Graphviz_dump MMC_REFSTRUCTLIT(boxvar_lit_Graphviz_dump)
#ifdef __cplusplus
}
#endif
#endif
