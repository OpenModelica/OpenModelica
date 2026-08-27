#ifndef UnitParserExt__H
#define UnitParserExt__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
void omc_UnitParserExt_commit(threadData_t *threadData);
#define boxptr_UnitParserExt_commit omc_UnitParserExt_commit
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnitParserExt_commit,2,0) {(void*) boxptr_UnitParserExt_commit,0}};
#define boxvar_UnitParserExt_commit MMC_REFSTRUCTLIT(boxvar_lit_UnitParserExt_commit)
extern void UnitParserExtImpl__commit();
DLLExport
void omc_UnitParserExt_clear(threadData_t *threadData);
#define boxptr_UnitParserExt_clear omc_UnitParserExt_clear
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnitParserExt_clear,2,0) {(void*) boxptr_UnitParserExt_clear,0}};
#define boxvar_UnitParserExt_clear MMC_REFSTRUCTLIT(boxvar_lit_UnitParserExt_clear)
extern void UnitParserExtImpl__clear();
DLLExport
void omc_UnitParserExt_rollback(threadData_t *threadData);
#define boxptr_UnitParserExt_rollback omc_UnitParserExt_rollback
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnitParserExt_rollback,2,0) {(void*) boxptr_UnitParserExt_rollback,0}};
#define boxvar_UnitParserExt_rollback MMC_REFSTRUCTLIT(boxvar_lit_UnitParserExt_rollback)
extern void UnitParserExtImpl__rollback();
DLLExport
void omc_UnitParserExt_checkpoint(threadData_t *threadData);
#define boxptr_UnitParserExt_checkpoint omc_UnitParserExt_checkpoint
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnitParserExt_checkpoint,2,0) {(void*) boxptr_UnitParserExt_checkpoint,0}};
#define boxvar_UnitParserExt_checkpoint MMC_REFSTRUCTLIT(boxvar_lit_UnitParserExt_checkpoint)
extern void UnitParserExtImpl__checkpoint();
DLLExport
void omc_UnitParserExt_addDerivedWeight(threadData_t *threadData, modelica_string _name, modelica_string _exp, modelica_real _weight);
DLLExport
void boxptr_UnitParserExt_addDerivedWeight(threadData_t *threadData, modelica_metatype _name, modelica_metatype _exp, modelica_metatype _weight);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnitParserExt_addDerivedWeight,2,0) {(void*) boxptr_UnitParserExt_addDerivedWeight,0}};
#define boxvar_UnitParserExt_addDerivedWeight MMC_REFSTRUCTLIT(boxvar_lit_UnitParserExt_addDerivedWeight)
extern void UnitParserExtImpl__addDerivedWeight(const char* /*_name*/, const char* /*_exp*/, double /*_weight*/);
DLLExport
void omc_UnitParserExt_addDerived(threadData_t *threadData, modelica_string _name, modelica_string _exp);
#define boxptr_UnitParserExt_addDerived omc_UnitParserExt_addDerived
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnitParserExt_addDerived,2,0) {(void*) boxptr_UnitParserExt_addDerived,0}};
#define boxvar_UnitParserExt_addDerived MMC_REFSTRUCTLIT(boxvar_lit_UnitParserExt_addDerived)
extern void UnitParserExtImpl__addDerived(const char* /*_name*/, const char* /*_exp*/);
DLLExport
void omc_UnitParserExt_registerWeight(threadData_t *threadData, modelica_string _name, modelica_real _weight);
DLLExport
void boxptr_UnitParserExt_registerWeight(threadData_t *threadData, modelica_metatype _name, modelica_metatype _weight);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnitParserExt_registerWeight,2,0) {(void*) boxptr_UnitParserExt_registerWeight,0}};
#define boxvar_UnitParserExt_registerWeight MMC_REFSTRUCTLIT(boxvar_lit_UnitParserExt_registerWeight)
extern void UnitParserExtImpl__registerWeight(const char* /*_name*/, double /*_weight*/);
DLLExport
void omc_UnitParserExt_addBase(threadData_t *threadData, modelica_string _name);
#define boxptr_UnitParserExt_addBase omc_UnitParserExt_addBase
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnitParserExt_addBase,2,0) {(void*) boxptr_UnitParserExt_addBase,0}};
#define boxvar_UnitParserExt_addBase MMC_REFSTRUCTLIT(boxvar_lit_UnitParserExt_addBase)
extern void UnitParserExtImpl__addBase(const char* /*_name*/);
DLLExport
modelica_metatype omc_UnitParserExt_allUnitSymbols(threadData_t *threadData);
#define boxptr_UnitParserExt_allUnitSymbols omc_UnitParserExt_allUnitSymbols
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnitParserExt_allUnitSymbols,2,0) {(void*) boxptr_UnitParserExt_allUnitSymbols,0}};
#define boxvar_UnitParserExt_allUnitSymbols MMC_REFSTRUCTLIT(boxvar_lit_UnitParserExt_allUnitSymbols)
extern modelica_metatype UnitParserExtImpl__allUnitSymbols();
DLLExport
modelica_metatype omc_UnitParserExt_str2unit(threadData_t *threadData, modelica_string _res, modelica_metatype *out_denoms, modelica_metatype *out_tpnoms, modelica_metatype *out_tpdenoms, modelica_metatype *out_tpstrs, modelica_real *out_scaleFactor, modelica_real *out_offset);
DLLExport
modelica_metatype boxptr_UnitParserExt_str2unit(threadData_t *threadData, modelica_metatype _res, modelica_metatype *out_denoms, modelica_metatype *out_tpnoms, modelica_metatype *out_tpdenoms, modelica_metatype *out_tpstrs, modelica_metatype *out_scaleFactor, modelica_metatype *out_offset);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnitParserExt_str2unit,2,0) {(void*) boxptr_UnitParserExt_str2unit,0}};
#define boxvar_UnitParserExt_str2unit MMC_REFSTRUCTLIT(boxvar_lit_UnitParserExt_str2unit)
extern void UnitParserExt_str2unit(const char* /*_res*/, modelica_metatype* /*_noms*/, modelica_metatype* /*_denoms*/, modelica_metatype* /*_tpnoms*/, modelica_metatype* /*_tpdenoms*/, modelica_metatype* /*_tpstrs*/, double* /*_scaleFactor*/, double* /*_offset*/);
DLLExport
modelica_string omc_UnitParserExt_unit2str(threadData_t *threadData, modelica_metatype _noms, modelica_metatype _denoms, modelica_metatype _tpnoms, modelica_metatype _tpdenoms, modelica_metatype _tpstrs, modelica_real _scaleFactor, modelica_real _offset);
DLLExport
modelica_metatype boxptr_UnitParserExt_unit2str(threadData_t *threadData, modelica_metatype _noms, modelica_metatype _denoms, modelica_metatype _tpnoms, modelica_metatype _tpdenoms, modelica_metatype _tpstrs, modelica_metatype _scaleFactor, modelica_metatype _offset);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnitParserExt_unit2str,2,0) {(void*) boxptr_UnitParserExt_unit2str,0}};
#define boxvar_UnitParserExt_unit2str MMC_REFSTRUCTLIT(boxvar_lit_UnitParserExt_unit2str)
extern const char* UnitParserExt_unit2str(modelica_metatype /*_noms*/, modelica_metatype /*_denoms*/, modelica_metatype /*_tpnoms*/, modelica_metatype /*_tpdenoms*/, modelica_metatype /*_tpstrs*/, double /*_scaleFactor*/, double /*_offset*/);
DLLExport
void omc_UnitParserExt_initSIUnits(threadData_t *threadData);
#define boxptr_UnitParserExt_initSIUnits omc_UnitParserExt_initSIUnits
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnitParserExt_initSIUnits,2,0) {(void*) boxptr_UnitParserExt_initSIUnits,0}};
#define boxvar_UnitParserExt_initSIUnits MMC_REFSTRUCTLIT(boxvar_lit_UnitParserExt_initSIUnits)
extern void UnitParserExtImpl__initSIUnits();
#ifdef __cplusplus
}
#endif
#endif
