#ifndef Gettext__H
#define Gettext__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_string omc_Gettext_translateContent(threadData_t *threadData, modelica_metatype _msg);
#define boxptr_Gettext_translateContent omc_Gettext_translateContent
static const MMC_DEFSTRUCTLIT(boxvar_lit_Gettext_translateContent,2,0) {(void*) boxptr_Gettext_translateContent,0}};
#define boxvar_Gettext_translateContent MMC_REFSTRUCTLIT(boxvar_lit_Gettext_translateContent)
#ifdef __cplusplus
}
#endif
#endif
