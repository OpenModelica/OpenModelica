#ifndef UnitAbsynBuilder__H
#define UnitAbsynBuilder__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description UnitAbsyn_InstStore_NOSTORE__desc;
DLLExport
modelica_string omc_UnitAbsynBuilder_unit2str(threadData_t *threadData, modelica_metatype _unit);
#define boxptr_UnitAbsynBuilder_unit2str omc_UnitAbsynBuilder_unit2str
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnitAbsynBuilder_unit2str,2,0) {(void*) boxptr_UnitAbsynBuilder_unit2str,0}};
#define boxvar_UnitAbsynBuilder_unit2str MMC_REFSTRUCTLIT(boxvar_lit_UnitAbsynBuilder_unit2str)
DLLExport
modelica_metatype omc_UnitAbsynBuilder_instAddStore(threadData_t *threadData, modelica_metatype _istore, modelica_metatype _itp, modelica_metatype _cr);
#define boxptr_UnitAbsynBuilder_instAddStore omc_UnitAbsynBuilder_instAddStore
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnitAbsynBuilder_instAddStore,2,0) {(void*) boxptr_UnitAbsynBuilder_instAddStore,0}};
#define boxvar_UnitAbsynBuilder_instAddStore MMC_REFSTRUCTLIT(boxvar_lit_UnitAbsynBuilder_instAddStore)
DLLExport
void omc_UnitAbsynBuilder_registerUnitWeights(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _dae);
#define boxptr_UnitAbsynBuilder_registerUnitWeights omc_UnitAbsynBuilder_registerUnitWeights
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnitAbsynBuilder_registerUnitWeights,2,0) {(void*) boxptr_UnitAbsynBuilder_registerUnitWeights,0}};
#define boxvar_UnitAbsynBuilder_registerUnitWeights MMC_REFSTRUCTLIT(boxvar_lit_UnitAbsynBuilder_registerUnitWeights)
DLLExport
modelica_metatype omc_UnitAbsynBuilder_instBuildUnitTerms(threadData_t *threadData, modelica_metatype _env, modelica_metatype _dae, modelica_metatype _compDae, modelica_metatype _store, modelica_metatype *out_terms);
#define boxptr_UnitAbsynBuilder_instBuildUnitTerms omc_UnitAbsynBuilder_instBuildUnitTerms
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnitAbsynBuilder_instBuildUnitTerms,2,0) {(void*) boxptr_UnitAbsynBuilder_instBuildUnitTerms,0}};
#define boxvar_UnitAbsynBuilder_instBuildUnitTerms MMC_REFSTRUCTLIT(boxvar_lit_UnitAbsynBuilder_instBuildUnitTerms)
DLLExport
modelica_metatype omc_UnitAbsynBuilder_emptyInstStore(threadData_t *threadData);
#define boxptr_UnitAbsynBuilder_emptyInstStore omc_UnitAbsynBuilder_emptyInstStore
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnitAbsynBuilder_emptyInstStore,2,0) {(void*) boxptr_UnitAbsynBuilder_emptyInstStore,0}};
#define boxvar_UnitAbsynBuilder_emptyInstStore MMC_REFSTRUCTLIT(boxvar_lit_UnitAbsynBuilder_emptyInstStore)
#ifdef __cplusplus
}
#endif
#endif
