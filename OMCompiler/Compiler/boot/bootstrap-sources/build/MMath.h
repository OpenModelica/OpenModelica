#ifndef MMath__H
#define MMath__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description MMath_Rational_RATIONAL__desc;
DLLDirection
void omc_MMath_testRational(threadData_t *threadData);
#define boxptr_MMath_testRational omc_MMath_testRational
static const MMC_DEFSTRUCTLIT(boxvar_lit_MMath_testRational,2,0) {(void*) boxptr_MMath_testRational,0}};
#define boxvar_MMath_testRational MMC_REFSTRUCTLIT(boxvar_lit_MMath_testRational)
DLLDirection
modelica_integer omc_MMath_intGcd(threadData_t *threadData, modelica_integer _i1, modelica_integer _i2);
DLLDirection
modelica_metatype boxptr_MMath_intGcd(threadData_t *threadData, modelica_metatype _i1, modelica_metatype _i2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_MMath_intGcd,2,0) {(void*) boxptr_MMath_intGcd,0}};
#define boxvar_MMath_intGcd MMC_REFSTRUCTLIT(boxvar_lit_MMath_intGcd)
DLLDirection
modelica_metatype omc_MMath_divRational(threadData_t *threadData, modelica_metatype _r1, modelica_metatype _r2);
#define boxptr_MMath_divRational omc_MMath_divRational
static const MMC_DEFSTRUCTLIT(boxvar_lit_MMath_divRational,2,0) {(void*) boxptr_MMath_divRational,0}};
#define boxvar_MMath_divRational MMC_REFSTRUCTLIT(boxvar_lit_MMath_divRational)
DLLDirection
modelica_metatype omc_MMath_multRational(threadData_t *threadData, modelica_metatype _r1, modelica_metatype _r2);
#define boxptr_MMath_multRational omc_MMath_multRational
static const MMC_DEFSTRUCTLIT(boxvar_lit_MMath_multRational,2,0) {(void*) boxptr_MMath_multRational,0}};
#define boxvar_MMath_multRational MMC_REFSTRUCTLIT(boxvar_lit_MMath_multRational)
DLLDirection
modelica_metatype omc_MMath_subRational(threadData_t *threadData, modelica_metatype _r1, modelica_metatype _r2);
#define boxptr_MMath_subRational omc_MMath_subRational
static const MMC_DEFSTRUCTLIT(boxvar_lit_MMath_subRational,2,0) {(void*) boxptr_MMath_subRational,0}};
#define boxvar_MMath_subRational MMC_REFSTRUCTLIT(boxvar_lit_MMath_subRational)
DLLDirection
modelica_boolean omc_MMath_equals(threadData_t *threadData, modelica_metatype _r1, modelica_metatype _r2);
DLLDirection
modelica_metatype boxptr_MMath_equals(threadData_t *threadData, modelica_metatype _r1, modelica_metatype _r2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_MMath_equals,2,0) {(void*) boxptr_MMath_equals,0}};
#define boxvar_MMath_equals MMC_REFSTRUCTLIT(boxvar_lit_MMath_equals)
DLLDirection
modelica_string omc_MMath_rationalString(threadData_t *threadData, modelica_metatype _r);
#define boxptr_MMath_rationalString omc_MMath_rationalString
static const MMC_DEFSTRUCTLIT(boxvar_lit_MMath_rationalString,2,0) {(void*) boxptr_MMath_rationalString,0}};
#define boxvar_MMath_rationalString MMC_REFSTRUCTLIT(boxvar_lit_MMath_rationalString)
#define boxptr_MMath_normalizeZero omc_MMath_normalizeZero
DLLDirection
modelica_metatype omc_MMath_addRational(threadData_t *threadData, modelica_metatype _r1, modelica_metatype _r2);
#define boxptr_MMath_addRational omc_MMath_addRational
static const MMC_DEFSTRUCTLIT(boxvar_lit_MMath_addRational,2,0) {(void*) boxptr_MMath_addRational,0}};
#define boxvar_MMath_addRational MMC_REFSTRUCTLIT(boxvar_lit_MMath_addRational)
DLLDirection
modelica_boolean omc_MMath_isGreaterThan(threadData_t *threadData, modelica_metatype _r1, modelica_metatype _r2);
DLLDirection
modelica_metatype boxptr_MMath_isGreaterThan(threadData_t *threadData, modelica_metatype _r1, modelica_metatype _r2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_MMath_isGreaterThan,2,0) {(void*) boxptr_MMath_isGreaterThan,0}};
#define boxvar_MMath_isGreaterThan MMC_REFSTRUCTLIT(boxvar_lit_MMath_isGreaterThan)
#ifdef __cplusplus
}
#endif
#endif
