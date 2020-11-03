#ifndef GC__H
#define GC__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description GC_ProfStats_PROFSTATS__desc;
#define boxptr_GC_getProfStats_GC__get__prof__stats__modelica omc_GC_getProfStats_GC__get__prof__stats__modelica
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern modelica_metatype GC_get_prof_stats_modelica();
*/
DLLExport
modelica_metatype omc_GC_getProfStats(threadData_t *threadData);
#define boxptr_GC_getProfStats omc_GC_getProfStats
static const MMC_DEFSTRUCTLIT(boxvar_lit_GC_getProfStats,2,0) {(void*) boxptr_GC_getProfStats,0}};
#define boxvar_GC_getProfStats MMC_REFSTRUCTLIT(boxvar_lit_GC_getProfStats)
DLLExport
modelica_string omc_GC_profStatsStr(threadData_t *threadData, modelica_metatype _stats, modelica_string _head, modelica_string _delimiter);
#define boxptr_GC_profStatsStr omc_GC_profStatsStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_GC_profStatsStr,2,0) {(void*) boxptr_GC_profStatsStr,0}};
#define boxvar_GC_profStatsStr MMC_REFSTRUCTLIT(boxvar_lit_GC_profStatsStr)
DLLExport
void omc_GC_setMaxHeapSize(threadData_t *threadData, modelica_real _sz);
DLLExport
void boxptr_GC_setMaxHeapSize(threadData_t *threadData, modelica_metatype _sz);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GC_setMaxHeapSize,2,0) {(void*) boxptr_GC_setMaxHeapSize,0}};
#define boxvar_GC_setMaxHeapSize MMC_REFSTRUCTLIT(boxvar_lit_GC_setMaxHeapSize)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern void GC_set_max_heap_size_dbl(double (*_sz*));
*/
DLLExport
void omc_GC_setForceUnmapOnGcollect(threadData_t *threadData, modelica_boolean _forceUnmap);
DLLExport
void boxptr_GC_setForceUnmapOnGcollect(threadData_t *threadData, modelica_metatype _forceUnmap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GC_setForceUnmapOnGcollect,2,0) {(void*) boxptr_GC_setForceUnmapOnGcollect,0}};
#define boxvar_GC_setForceUnmapOnGcollect MMC_REFSTRUCTLIT(boxvar_lit_GC_setForceUnmapOnGcollect)
extern void GC_set_force_unmap_on_gcollect(int /*_forceUnmap*/);
DLLExport
modelica_boolean omc_GC_getForceUnmapOnGcollect(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_GC_getForceUnmapOnGcollect(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GC_getForceUnmapOnGcollect,2,0) {(void*) boxptr_GC_getForceUnmapOnGcollect,0}};
#define boxvar_GC_getForceUnmapOnGcollect MMC_REFSTRUCTLIT(boxvar_lit_GC_getForceUnmapOnGcollect)
extern int GC_get_force_unmap_on_gcollect();
DLLExport
void omc_GC_setFreeSpaceDivisor(threadData_t *threadData, modelica_integer _divisor);
DLLExport
void boxptr_GC_setFreeSpaceDivisor(threadData_t *threadData, modelica_metatype _divisor);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GC_setFreeSpaceDivisor,2,0) {(void*) boxptr_GC_setFreeSpaceDivisor,0}};
#define boxvar_GC_setFreeSpaceDivisor MMC_REFSTRUCTLIT(boxvar_lit_GC_setFreeSpaceDivisor)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern void GC_set_free_space_divisor(int (*_divisor*));
*/
DLLExport
modelica_boolean omc_GC_expandHeap(threadData_t *threadData, modelica_real _sz);
DLLExport
modelica_metatype boxptr_GC_expandHeap(threadData_t *threadData, modelica_metatype _sz);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GC_expandHeap,2,0) {(void*) boxptr_GC_expandHeap,0}};
#define boxvar_GC_expandHeap MMC_REFSTRUCTLIT(boxvar_lit_GC_expandHeap)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern int GC_expand_hp_dbl(double (*_sz*));
*/
DLLExport
void omc_GC_free(threadData_t *threadData, modelica_metatype _data);
#define boxptr_GC_free omc_GC_free
static const MMC_DEFSTRUCTLIT(boxvar_lit_GC_free,2,0) {(void*) boxptr_GC_free,0}};
#define boxvar_GC_free MMC_REFSTRUCTLIT(boxvar_lit_GC_free)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern void omc_GC_free_ext(modelica_metatype (*_data*));
*/
DLLExport
void omc_GC_disable(threadData_t *threadData);
#define boxptr_GC_disable omc_GC_disable
static const MMC_DEFSTRUCTLIT(boxvar_lit_GC_disable,2,0) {(void*) boxptr_GC_disable,0}};
#define boxvar_GC_disable MMC_REFSTRUCTLIT(boxvar_lit_GC_disable)
extern void GC_disable();
DLLExport
void omc_GC_enable(threadData_t *threadData);
#define boxptr_GC_enable omc_GC_enable
static const MMC_DEFSTRUCTLIT(boxvar_lit_GC_enable,2,0) {(void*) boxptr_GC_enable,0}};
#define boxvar_GC_enable MMC_REFSTRUCTLIT(boxvar_lit_GC_enable)
extern void GC_enable();
DLLExport
void omc_GC_gcollectAndUnmap(threadData_t *threadData);
#define boxptr_GC_gcollectAndUnmap omc_GC_gcollectAndUnmap
static const MMC_DEFSTRUCTLIT(boxvar_lit_GC_gcollectAndUnmap,2,0) {(void*) boxptr_GC_gcollectAndUnmap,0}};
#define boxvar_GC_gcollectAndUnmap MMC_REFSTRUCTLIT(boxvar_lit_GC_gcollectAndUnmap)
extern void GC_gcollect_and_unmap();
DLLExport
void omc_GC_gcollect(threadData_t *threadData);
#define boxptr_GC_gcollect omc_GC_gcollect
static const MMC_DEFSTRUCTLIT(boxvar_lit_GC_gcollect,2,0) {(void*) boxptr_GC_gcollect,0}};
#define boxvar_GC_gcollect MMC_REFSTRUCTLIT(boxvar_lit_GC_gcollect)
extern void GC_gcollect();
#ifdef __cplusplus
}
#endif
#endif
