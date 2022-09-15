#ifndef GCExt__H
#define GCExt__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description GCExt_ProfStats_PROFSTATS__desc;
#define boxptr_GCExt_getProfStats_GC__get__prof__stats__modelica omc_GCExt_getProfStats_GC__get__prof__stats__modelica
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern modelica_metatype GC_get_prof_stats_modelica();
*/
DLLExport
modelica_metatype omc_GCExt_getProfStats(threadData_t *threadData);
#define boxptr_GCExt_getProfStats omc_GCExt_getProfStats
static const MMC_DEFSTRUCTLIT(boxvar_lit_GCExt_getProfStats,2,0) {(void*) boxptr_GCExt_getProfStats,0}};
#define boxvar_GCExt_getProfStats MMC_REFSTRUCTLIT(boxvar_lit_GCExt_getProfStats)
DLLExport
modelica_string omc_GCExt_profStatsStr(threadData_t *threadData, modelica_metatype _stats, modelica_string _head, modelica_string _delimiter);
#define boxptr_GCExt_profStatsStr omc_GCExt_profStatsStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_GCExt_profStatsStr,2,0) {(void*) boxptr_GCExt_profStatsStr,0}};
#define boxvar_GCExt_profStatsStr MMC_REFSTRUCTLIT(boxvar_lit_GCExt_profStatsStr)
DLLExport
void omc_GCExt_setMaxHeapSize(threadData_t *threadData, modelica_real _sz);
DLLExport
void boxptr_GCExt_setMaxHeapSize(threadData_t *threadData, modelica_metatype _sz);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GCExt_setMaxHeapSize,2,0) {(void*) boxptr_GCExt_setMaxHeapSize,0}};
#define boxvar_GCExt_setMaxHeapSize MMC_REFSTRUCTLIT(boxvar_lit_GCExt_setMaxHeapSize)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern void GC_set_max_heap_size_dbl(double (*_sz*));
*/
DLLExport
void omc_GCExt_setForceUnmapOnGcollect(threadData_t *threadData, modelica_boolean _forceUnmap);
DLLExport
void boxptr_GCExt_setForceUnmapOnGcollect(threadData_t *threadData, modelica_metatype _forceUnmap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GCExt_setForceUnmapOnGcollect,2,0) {(void*) boxptr_GCExt_setForceUnmapOnGcollect,0}};
#define boxvar_GCExt_setForceUnmapOnGcollect MMC_REFSTRUCTLIT(boxvar_lit_GCExt_setForceUnmapOnGcollect)
extern void GC_set_force_unmap_on_gcollect(int /*_forceUnmap*/);
DLLExport
modelica_boolean omc_GCExt_getForceUnmapOnGcollect(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_GCExt_getForceUnmapOnGcollect(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GCExt_getForceUnmapOnGcollect,2,0) {(void*) boxptr_GCExt_getForceUnmapOnGcollect,0}};
#define boxvar_GCExt_getForceUnmapOnGcollect MMC_REFSTRUCTLIT(boxvar_lit_GCExt_getForceUnmapOnGcollect)
extern int GC_get_force_unmap_on_gcollect();
DLLExport
void omc_GCExt_setFreeSpaceDivisor(threadData_t *threadData, modelica_integer _divisor);
DLLExport
void boxptr_GCExt_setFreeSpaceDivisor(threadData_t *threadData, modelica_metatype _divisor);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GCExt_setFreeSpaceDivisor,2,0) {(void*) boxptr_GCExt_setFreeSpaceDivisor,0}};
#define boxvar_GCExt_setFreeSpaceDivisor MMC_REFSTRUCTLIT(boxvar_lit_GCExt_setFreeSpaceDivisor)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern void GC_set_free_space_divisor(int (*_divisor*));
*/
DLLExport
modelica_boolean omc_GCExt_expandHeap(threadData_t *threadData, modelica_real _sz);
DLLExport
modelica_metatype boxptr_GCExt_expandHeap(threadData_t *threadData, modelica_metatype _sz);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GCExt_expandHeap,2,0) {(void*) boxptr_GCExt_expandHeap,0}};
#define boxvar_GCExt_expandHeap MMC_REFSTRUCTLIT(boxvar_lit_GCExt_expandHeap)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern int GC_expand_hp_dbl(double (*_sz*));
*/
DLLExport
void omc_GCExt_free(threadData_t *threadData, modelica_metatype _data);
#define boxptr_GCExt_free omc_GCExt_free
static const MMC_DEFSTRUCTLIT(boxvar_lit_GCExt_free,2,0) {(void*) boxptr_GCExt_free,0}};
#define boxvar_GCExt_free MMC_REFSTRUCTLIT(boxvar_lit_GCExt_free)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern void omc_GC_free_ext(modelica_metatype (*_data*));
*/
DLLExport
void omc_GCExt_disable(threadData_t *threadData);
#define boxptr_GCExt_disable omc_GCExt_disable
static const MMC_DEFSTRUCTLIT(boxvar_lit_GCExt_disable,2,0) {(void*) boxptr_GCExt_disable,0}};
#define boxvar_GCExt_disable MMC_REFSTRUCTLIT(boxvar_lit_GCExt_disable)
extern void GC_disable();
DLLExport
void omc_GCExt_enable(threadData_t *threadData);
#define boxptr_GCExt_enable omc_GCExt_enable
static const MMC_DEFSTRUCTLIT(boxvar_lit_GCExt_enable,2,0) {(void*) boxptr_GCExt_enable,0}};
#define boxvar_GCExt_enable MMC_REFSTRUCTLIT(boxvar_lit_GCExt_enable)
extern void GC_enable();
DLLExport
void omc_GCExt_gcollectAndUnmap(threadData_t *threadData);
#define boxptr_GCExt_gcollectAndUnmap omc_GCExt_gcollectAndUnmap
static const MMC_DEFSTRUCTLIT(boxvar_lit_GCExt_gcollectAndUnmap,2,0) {(void*) boxptr_GCExt_gcollectAndUnmap,0}};
#define boxvar_GCExt_gcollectAndUnmap MMC_REFSTRUCTLIT(boxvar_lit_GCExt_gcollectAndUnmap)
extern void GC_gcollect_and_unmap();
DLLExport
void omc_GCExt_gcollect(threadData_t *threadData);
#define boxptr_GCExt_gcollect omc_GCExt_gcollect
static const MMC_DEFSTRUCTLIT(boxvar_lit_GCExt_gcollect,2,0) {(void*) boxptr_GCExt_gcollect,0}};
#define boxvar_GCExt_gcollect MMC_REFSTRUCTLIT(boxvar_lit_GCExt_gcollect)
extern void GC_gcollect();
#ifdef __cplusplus
}
#endif
#endif
