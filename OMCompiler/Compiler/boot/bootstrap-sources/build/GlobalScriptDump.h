#ifndef GlobalScriptDump__H
#define GlobalScriptDump__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
#define boxptr_GlobalScriptDump_classString omc_GlobalScriptDump_classString
DLLExport
void omc_GlobalScriptDump_printGlobalScript(threadData_t *threadData, modelica_metatype _st);
#define boxptr_GlobalScriptDump_printGlobalScript omc_GlobalScriptDump_printGlobalScript
static const MMC_DEFSTRUCTLIT(boxvar_lit_GlobalScriptDump_printGlobalScript,2,0) {(void*) boxptr_GlobalScriptDump_printGlobalScript,0}};
#define boxvar_GlobalScriptDump_printGlobalScript MMC_REFSTRUCTLIT(boxvar_lit_GlobalScriptDump_printGlobalScript)
DLLExport
void omc_GlobalScriptDump_printAST(threadData_t *threadData, modelica_metatype _pr);
#define boxptr_GlobalScriptDump_printAST omc_GlobalScriptDump_printAST
static const MMC_DEFSTRUCTLIT(boxvar_lit_GlobalScriptDump_printAST,2,0) {(void*) boxptr_GlobalScriptDump_printAST,0}};
#define boxvar_GlobalScriptDump_printAST MMC_REFSTRUCTLIT(boxvar_lit_GlobalScriptDump_printAST)
DLLExport
modelica_string omc_GlobalScriptDump_printIstmtStr(threadData_t *threadData, modelica_metatype _inStatement);
#define boxptr_GlobalScriptDump_printIstmtStr omc_GlobalScriptDump_printIstmtStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_GlobalScriptDump_printIstmtStr,2,0) {(void*) boxptr_GlobalScriptDump_printIstmtStr,0}};
#define boxvar_GlobalScriptDump_printIstmtStr MMC_REFSTRUCTLIT(boxvar_lit_GlobalScriptDump_printIstmtStr)
DLLExport
modelica_string omc_GlobalScriptDump_printIstmtsStr(threadData_t *threadData, modelica_metatype _inStatements);
#define boxptr_GlobalScriptDump_printIstmtsStr omc_GlobalScriptDump_printIstmtsStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_GlobalScriptDump_printIstmtsStr,2,0) {(void*) boxptr_GlobalScriptDump_printIstmtsStr,0}};
#define boxvar_GlobalScriptDump_printIstmtsStr MMC_REFSTRUCTLIT(boxvar_lit_GlobalScriptDump_printIstmtsStr)
#ifdef __cplusplus
}
#endif
#endif
