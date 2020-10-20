#ifndef FGraphStream__H
#define FGraphStream__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
void omc_FGraphStream_node(threadData_t *threadData, modelica_metatype _n);
#define boxptr_FGraphStream_node omc_FGraphStream_node
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraphStream_node,2,0) {(void*) boxptr_FGraphStream_node,0}};
#define boxvar_FGraphStream_node MMC_REFSTRUCTLIT(boxvar_lit_FGraphStream_node)
DLLExport
void omc_FGraphStream_edge(threadData_t *threadData, modelica_metatype _name, modelica_metatype _source, modelica_metatype _target);
#define boxptr_FGraphStream_edge omc_FGraphStream_edge
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraphStream_edge,2,0) {(void*) boxptr_FGraphStream_edge,0}};
#define boxvar_FGraphStream_edge MMC_REFSTRUCTLIT(boxvar_lit_FGraphStream_edge)
DLLExport
void omc_FGraphStream_finish(threadData_t *threadData);
#define boxptr_FGraphStream_finish omc_FGraphStream_finish
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraphStream_finish,2,0) {(void*) boxptr_FGraphStream_finish,0}};
#define boxvar_FGraphStream_finish MMC_REFSTRUCTLIT(boxvar_lit_FGraphStream_finish)
DLLExport
void omc_FGraphStream_start(threadData_t *threadData);
#define boxptr_FGraphStream_start omc_FGraphStream_start
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraphStream_start,2,0) {(void*) boxptr_FGraphStream_start,0}};
#define boxvar_FGraphStream_start MMC_REFSTRUCTLIT(boxvar_lit_FGraphStream_start)
#ifdef __cplusplus
}
#endif
#endif
