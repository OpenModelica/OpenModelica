#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/GlobalScriptDump.c"
#endif
#include "omc_simulation_settings.h"
#include "GlobalScriptDump.h"
#define _OMC_LIT0_data ": "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,2,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "AST\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,4,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,0,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,1,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "printIstmtStr: unknown"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,22,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "; "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,2,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "printIstmtsStr: unknown"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,23,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#include "util/modelica.h"
#include "GlobalScriptDump_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_string omc_GlobalScriptDump_classString(threadData_t *threadData, modelica_metatype _cl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_GlobalScriptDump_classString,2,0) {(void*) boxptr_GlobalScriptDump_classString,0}};
#define boxvar_GlobalScriptDump_classString MMC_REFSTRUCTLIT(boxvar_lit_GlobalScriptDump_classString)
PROTECTED_FUNCTION_STATIC modelica_string omc_GlobalScriptDump_classString(threadData_t *threadData, modelica_metatype _cl)
{
modelica_string _s = NULL;
modelica_string _id = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _cl;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_id = tmpMeta[1];
tmpMeta[0] = stringAppend(_id,_OMC_LIT0);
tmpMeta[1] = stringAppend(tmpMeta[0],omc_AbsynUtil_classFilename(threadData, _cl));
_s = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _s;
}
DLLExport
void omc_GlobalScriptDump_printGlobalScript(threadData_t *threadData, modelica_metatype _st)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
fputs(MMC_STRINGDATA(_OMC_LIT1),stdout);
omc_GlobalScriptDump_printAST(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_st), 2))));
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_GlobalScriptDump_printAST(threadData_t *threadData, modelica_metatype _pr)
{
modelica_string _s = NULL;
modelica_metatype _class_ = NULL;
modelica_metatype _classes = NULL;
modelica_metatype _within_ = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_s = _OMC_LIT2;
tmpMeta[0] = _pr;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_classes = tmpMeta[1];
_within_ = tmpMeta[2];
{
modelica_metatype _class_;
for (tmpMeta[0] = _classes; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_class_ = MMC_CAR(tmpMeta[0]);
tmpMeta[1] = stringAppend(_s,omc_GlobalScriptDump_classString(threadData, _class_));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT3);
_s = tmpMeta[2];
}
}
fputs(MMC_STRINGDATA(_s),stdout);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_string omc_GlobalScriptDump_printIstmtStr(threadData_t *threadData, modelica_metatype _inStatement)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inStatement;
{
modelica_metatype _alg = NULL;
modelica_metatype _expr = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_alg = tmpMeta[0];
tmp1 = omc_Dump_unparseAlgorithmStr(threadData, _alg);
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_expr = tmpMeta[0];
tmp1 = omc_Dump_printExpStr(threadData, _expr);
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmp1 = _OMC_LIT4;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_GlobalScriptDump_printIstmtsStr(threadData_t *threadData, modelica_metatype _inStatements)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inStatements;
{
modelica_metatype _stmts = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_stmts = tmpMeta[0];
tmp1 = stringDelimitList(omc_List_map(threadData, _stmts, boxvar_GlobalScriptDump_printIstmtStr), _OMC_LIT5);
goto tmp3_done;
}
case 1: {
tmp1 = _OMC_LIT6;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
