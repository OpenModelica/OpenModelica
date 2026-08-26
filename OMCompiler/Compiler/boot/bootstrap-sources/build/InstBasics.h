#ifndef InstBasics__H
#define InstBasics__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description DAE_InlineType_AFTER__INDEX__RED__INLINE__desc;
extern struct record_description DAE_InlineType_DEFAULT__INLINE__desc;
extern struct record_description DAE_InlineType_EARLY__INLINE__desc;
extern struct record_description DAE_InlineType_NORM__INLINE__desc;
extern struct record_description DAE_InlineType_NO__INLINE__desc;
DLLDirection
modelica_integer omc_InstBasics_getFunctionRestrictionPurity(threadData_t *threadData, modelica_metatype _purity, modelica_metatype _cmt, modelica_boolean _newFrontend);
DLLDirection
modelica_metatype boxptr_InstBasics_getFunctionRestrictionPurity(threadData_t *threadData, modelica_metatype _purity, modelica_metatype _cmt, modelica_metatype _newFrontend);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstBasics_getFunctionRestrictionPurity,2,0) {(void*) boxptr_InstBasics_getFunctionRestrictionPurity,0}};
#define boxvar_InstBasics_getFunctionRestrictionPurity MMC_REFSTRUCTLIT(boxvar_lit_InstBasics_getFunctionRestrictionPurity)
DLLDirection
modelica_boolean omc_InstBasics_commentGenerateEvents(threadData_t *threadData, modelica_metatype _cmt);
DLLDirection
modelica_metatype boxptr_InstBasics_commentGenerateEvents(threadData_t *threadData, modelica_metatype _cmt);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstBasics_commentGenerateEvents,2,0) {(void*) boxptr_InstBasics_commentGenerateEvents,0}};
#define boxvar_InstBasics_commentGenerateEvents MMC_REFSTRUCTLIT(boxvar_lit_InstBasics_commentGenerateEvents)
#define boxptr_InstBasics_isInlineFunc2 omc_InstBasics_isInlineFunc2
DLLDirection
modelica_metatype omc_InstBasics_commentIsInlineFunc(threadData_t *threadData, modelica_metatype _cmt);
#define boxptr_InstBasics_commentIsInlineFunc omc_InstBasics_commentIsInlineFunc
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstBasics_commentIsInlineFunc,2,0) {(void*) boxptr_InstBasics_commentIsInlineFunc,0}};
#define boxvar_InstBasics_commentIsInlineFunc MMC_REFSTRUCTLIT(boxvar_lit_InstBasics_commentIsInlineFunc)
#ifdef __cplusplus
}
#endif
#endif
