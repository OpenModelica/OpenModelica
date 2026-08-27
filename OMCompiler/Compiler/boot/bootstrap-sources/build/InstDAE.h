#ifndef InstDAE__H
#define InstDAE__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description DAE_AvlTreePathFunction_Tree_EMPTY__desc;
extern struct record_description DAE_ComponentPrefix_NOCOMPPRE__desc;
extern struct record_description DAE_DAElist_DAE__desc;
extern struct record_description DAE_Element_COMP__desc;
extern struct record_description DAE_Element_VAR__desc;
extern struct record_description DAE_ElementSource_SOURCE__desc;
extern struct record_description DAE_Mod_NOMOD__desc;
extern struct record_description DAE_Type_T__BOOL__desc;
extern struct record_description DAE_Type_T__CLOCK__desc;
extern struct record_description DAE_Type_T__INTEGER__desc;
extern struct record_description DAE_Type_T__REAL__desc;
extern struct record_description DAE_Type_T__STRING__desc;
extern struct record_description ErrorTypes_Message_MESSAGE__desc;
extern struct record_description ErrorTypes_MessageType_TRANSLATION__desc;
extern struct record_description ErrorTypes_Severity_ERROR__desc;
extern struct record_description Flags_DebugFlag_DEBUG__FLAG__desc;
extern struct record_description Gettext_TranslatableContent_gettext__desc;
extern struct record_description SourceInfo_SOURCEINFO__desc;
#define boxptr_InstDAE_showDAE omc_InstDAE_showDAE
DLLExport
modelica_metatype omc_InstDAE_daeDeclare(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inParentEnv, modelica_metatype _inClassEnv, modelica_metatype _inComponentRef, modelica_metatype _inState, modelica_metatype _inType, modelica_metatype _inAttributes, modelica_metatype _visibility, modelica_metatype _inBinding, modelica_metatype _inInstDims, modelica_metatype _inStartValue, modelica_metatype _inVarAttr, modelica_metatype _inComment, modelica_metatype _io, modelica_metatype _finalPrefix, modelica_metatype _source, modelica_boolean _declareComplexVars);
DLLExport
modelica_metatype boxptr_InstDAE_daeDeclare(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inParentEnv, modelica_metatype _inClassEnv, modelica_metatype _inComponentRef, modelica_metatype _inState, modelica_metatype _inType, modelica_metatype _inAttributes, modelica_metatype _visibility, modelica_metatype _inBinding, modelica_metatype _inInstDims, modelica_metatype _inStartValue, modelica_metatype _inVarAttr, modelica_metatype _inComment, modelica_metatype _io, modelica_metatype _finalPrefix, modelica_metatype _source, modelica_metatype _declareComplexVars);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstDAE_daeDeclare,2,0) {(void*) boxptr_InstDAE_daeDeclare,0}};
#define boxvar_InstDAE_daeDeclare MMC_REFSTRUCTLIT(boxvar_lit_InstDAE_daeDeclare)
#ifdef __cplusplus
}
#endif
#endif
