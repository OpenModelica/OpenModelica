#ifndef ExecStat__H
#define ExecStat__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description ErrorTypes_Message_MESSAGE__desc;
extern struct record_description ErrorTypes_MessageType_TRANSLATION__desc;
extern struct record_description ErrorTypes_Severity_NOTIFICATION__desc;
extern struct record_description Flags_DebugFlag_DEBUG__FLAG__desc;
extern struct record_description Gettext_TranslatableContent_gettext__desc;
DLLExport
void omc_ExecStat_execStat(threadData_t *threadData, modelica_string _name);
#define boxptr_ExecStat_execStat omc_ExecStat_execStat
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExecStat_execStat,2,0) {(void*) boxptr_ExecStat_execStat,0}};
#define boxvar_ExecStat_execStat MMC_REFSTRUCTLIT(boxvar_lit_ExecStat_execStat)
DLLExport
void omc_ExecStat_execStatReset(threadData_t *threadData);
#define boxptr_ExecStat_execStatReset omc_ExecStat_execStatReset
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExecStat_execStatReset,2,0) {(void*) boxptr_ExecStat_execStatReset,0}};
#define boxvar_ExecStat_execStatReset MMC_REFSTRUCTLIT(boxvar_lit_ExecStat_execStatReset)
#ifdef __cplusplus
}
#endif
#endif
