#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/NFInstUtil.c"
#endif
#include "omc_simulation_settings.h"
#include "NFInstUtil.h"
#define _OMC_LIT0_data "constant"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,8,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "parameter"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,9,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "discrete"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,8,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "continuous"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,10,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,1,3) {&DAE_Const_C__CONST__desc,}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,1,4) {&DAE_Const_C__PARAM__desc,}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,1,5) {&DAE_Const_C__VAR__desc,}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,1,3) {&DAE_VarVisibility_PUBLIC__desc,}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT8,1,4) {&DAE_VarVisibility_PROTECTED__desc,}};
#define _OMC_LIT8 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,1,3) {&DAE_VarInnerOuter_INNER__desc,}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,1,5) {&DAE_VarInnerOuter_INNER__OUTER__desc,}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,1,4) {&DAE_VarInnerOuter_OUTER__desc,}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT12,1,6) {&DAE_VarInnerOuter_NOT__INNER__OUTER__desc,}};
#define _OMC_LIT12 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT12)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT13,1,5) {&DAE_VarDirection_BIDIR__desc,}};
#define _OMC_LIT13 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT13)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT14,1,4) {&DAE_VarDirection_OUTPUT__desc,}};
#define _OMC_LIT14 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,1,3) {&DAE_VarDirection_INPUT__desc,}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT16,1,3) {&DAE_VarKind_VARIABLE__desc,}};
#define _OMC_LIT16 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT16)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT17,1,5) {&DAE_VarKind_PARAM__desc,}};
#define _OMC_LIT17 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT18,1,6) {&DAE_VarKind_CONST__desc,}};
#define _OMC_LIT18 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,1,4) {&DAE_VarKind_DISCRETE__desc,}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT20,1,3) {&DAE_VarParallelism_PARGLOBAL__desc,}};
#define _OMC_LIT20 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT20)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT21,1,4) {&DAE_VarParallelism_PARLOCAL__desc,}};
#define _OMC_LIT21 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT21)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT22,1,5) {&DAE_VarParallelism_NON__PARALLEL__desc,}};
#define _OMC_LIT22 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT22)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT23,1,4) {&DAE_ConnectorType_FLOW__desc,}};
#define _OMC_LIT23 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT23)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT24,2,5) {&DAE_ConnectorType_STREAM__desc,MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT24 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT24)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT25,1,6) {&DAE_ConnectorType_NON__CONNECTOR__desc,}};
#define _OMC_LIT25 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT25)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT26,1,3) {&SCode_Visibility_PUBLIC__desc,}};
#define _OMC_LIT26 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT26)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT27,1,4) {&SCode_Visibility_PROTECTED__desc,}};
#define _OMC_LIT27 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT27)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT28,1,3) {&Absyn_InnerOuter_INNER__desc,}};
#define _OMC_LIT28 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT28)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT29,1,5) {&Absyn_InnerOuter_INNER__OUTER__desc,}};
#define _OMC_LIT29 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT29)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT30,1,4) {&Absyn_InnerOuter_OUTER__desc,}};
#define _OMC_LIT30 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT30)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT31,1,6) {&Absyn_InnerOuter_NOT__INNER__OUTER__desc,}};
#define _OMC_LIT31 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT31)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT32,1,5) {&Absyn_Direction_BIDIR__desc,}};
#define _OMC_LIT32 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT32)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT33,1,3) {&Absyn_Direction_INPUT__desc,}};
#define _OMC_LIT33 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT33)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT34,1,4) {&Absyn_Direction_OUTPUT__desc,}};
#define _OMC_LIT34 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT34)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT35,1,3) {&SCode_Variability_VAR__desc,}};
#define _OMC_LIT35 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT35)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT36,1,4) {&SCode_Variability_DISCRETE__desc,}};
#define _OMC_LIT36 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT36)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT37,1,5) {&SCode_Variability_PARAM__desc,}};
#define _OMC_LIT37 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT37)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT38,1,6) {&SCode_Variability_CONST__desc,}};
#define _OMC_LIT38 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT38)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT39,1,3) {&SCode_Parallelism_PARGLOBAL__desc,}};
#define _OMC_LIT39 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT39)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT40,1,4) {&SCode_Parallelism_PARLOCAL__desc,}};
#define _OMC_LIT40 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT40)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT41,1,5) {&SCode_Parallelism_NON__PARALLEL__desc,}};
#define _OMC_LIT41 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT41)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT42,1,3) {&SCode_ConnectorType_POTENTIAL__desc,}};
#define _OMC_LIT42 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT42)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT43,1,4) {&SCode_ConnectorType_FLOW__desc,}};
#define _OMC_LIT43 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT43)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT44,1,5) {&SCode_ConnectorType_STREAM__desc,}};
#define _OMC_LIT44 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT44)
#include "util/modelica.h"
#include "NFInstUtil_includes.h"
DLLExport
modelica_string omc_NFInstUtil_variabilityString(threadData_t *threadData, modelica_metatype _var)
{
modelica_string _string = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _var;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 6: {
tmp1 = _OMC_LIT0;
goto tmp3_done;
}
case 5: {
tmp1 = _OMC_LIT1;
goto tmp3_done;
}
case 4: {
tmp1 = _OMC_LIT2;
goto tmp3_done;
}
case 3: {
tmp1 = _OMC_LIT3;
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
_string = tmp1;
_return: OMC_LABEL_UNUSED
return _string;
}
DLLExport
modelica_metatype omc_NFInstUtil_variabilityOr(threadData_t *threadData, modelica_metatype _var1, modelica_metatype _var2)
{
modelica_metatype _var = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _var1;
tmp3_2 = _var2;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 7; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,0) == 0) goto tmp2_end;
tmpMeta[0] = _var1;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,3,0) == 0) goto tmp2_end;
tmpMeta[0] = _var2;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,0) == 0) goto tmp2_end;
tmpMeta[0] = _var1;
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,0) == 0) goto tmp2_end;
tmpMeta[0] = _var2;
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,0) == 0) goto tmp2_end;
tmpMeta[0] = _var1;
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,0) == 0) goto tmp2_end;
tmpMeta[0] = _var2;
goto tmp2_done;
}
case 6: {
tmpMeta[0] = _var1;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_var = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _var;
}
DLLExport
modelica_metatype omc_NFInstUtil_variabilityAnd(threadData_t *threadData, modelica_metatype _var1, modelica_metatype _var2)
{
modelica_metatype _var = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _var1;
tmp3_2 = _var2;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 7; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,0) == 0) goto tmp2_end;
tmpMeta[0] = _var1;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,0) == 0) goto tmp2_end;
tmpMeta[0] = _var2;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,0) == 0) goto tmp2_end;
tmpMeta[0] = _var1;
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,0) == 0) goto tmp2_end;
tmpMeta[0] = _var2;
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,0) == 0) goto tmp2_end;
tmpMeta[0] = _var1;
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,0) == 0) goto tmp2_end;
tmpMeta[0] = _var2;
goto tmp2_done;
}
case 6: {
tmpMeta[0] = _var1;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_var = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _var;
}
DLLExport
modelica_metatype omc_NFInstUtil_toConst(threadData_t *threadData, modelica_metatype _inVar)
{
modelica_metatype _outConst = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inVar;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 6: {
tmpMeta[0] = _OMC_LIT4;
goto tmp2_done;
}
case 5: {
tmpMeta[0] = _OMC_LIT5;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
tmpMeta[0] = _OMC_LIT6;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outConst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outConst;
}
DLLExport
modelica_metatype omc_NFInstUtil_translateVisibility(threadData_t *threadData, modelica_metatype _inVisibility)
{
modelica_metatype _outVisibility = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inVisibility;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT7;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _OMC_LIT8;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outVisibility = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outVisibility;
}
DLLExport
modelica_metatype omc_NFInstUtil_translateInnerOuter(threadData_t *threadData, modelica_metatype _inInnerOuter)
{
modelica_metatype _outInnerOuter = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inInnerOuter;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
tmpMeta[0] = _OMC_LIT9;
goto tmp2_done;
}
case 5: {
tmpMeta[0] = _OMC_LIT10;
goto tmp2_done;
}
case 4: {
tmpMeta[0] = _OMC_LIT11;
goto tmp2_done;
}
case 6: {
tmpMeta[0] = _OMC_LIT12;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outInnerOuter = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outInnerOuter;
}
DLLExport
modelica_metatype omc_NFInstUtil_translateDirection(threadData_t *threadData, modelica_metatype _inDirection)
{
modelica_metatype _outDirection = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inDirection;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 5: {
tmpMeta[0] = _OMC_LIT13;
goto tmp2_done;
}
case 4: {
tmpMeta[0] = _OMC_LIT14;
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _OMC_LIT15;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outDirection = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outDirection;
}
DLLExport
modelica_metatype omc_NFInstUtil_translateVariability(threadData_t *threadData, modelica_metatype _inVariability)
{
modelica_metatype _outVariability = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inVariability;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
tmpMeta[0] = _OMC_LIT16;
goto tmp2_done;
}
case 5: {
tmpMeta[0] = _OMC_LIT17;
goto tmp2_done;
}
case 6: {
tmpMeta[0] = _OMC_LIT18;
goto tmp2_done;
}
case 4: {
tmpMeta[0] = _OMC_LIT19;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outVariability = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outVariability;
}
DLLExport
modelica_metatype omc_NFInstUtil_translateParallelism(threadData_t *threadData, modelica_metatype _inParallelism)
{
modelica_metatype _outParallelism = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inParallelism;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
tmpMeta[0] = _OMC_LIT20;
goto tmp2_done;
}
case 4: {
tmpMeta[0] = _OMC_LIT21;
goto tmp2_done;
}
case 5: {
tmpMeta[0] = _OMC_LIT22;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outParallelism = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outParallelism;
}
DLLExport
modelica_metatype omc_NFInstUtil_translateConnectorType(threadData_t *threadData, modelica_metatype _inConnectorType)
{
modelica_metatype _outConnectorType = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inConnectorType;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 4: {
tmpMeta[0] = _OMC_LIT23;
goto tmp2_done;
}
case 5: {
tmpMeta[0] = _OMC_LIT24;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
tmpMeta[0] = _OMC_LIT25;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outConnectorType = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outConnectorType;
}
DLLExport
modelica_metatype omc_NFInstUtil_daeToSCodeVisibility(threadData_t *threadData, modelica_metatype _inVisibility)
{
modelica_metatype _outVisibility = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inVisibility;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT26;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT27;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outVisibility = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outVisibility;
}
DLLExport
modelica_metatype omc_NFInstUtil_daeToAbsynInnerOuter(threadData_t *threadData, modelica_metatype _inInnerOuter)
{
modelica_metatype _outInnerOuter = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inInnerOuter;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
tmpMeta[0] = _OMC_LIT28;
goto tmp2_done;
}
case 5: {
tmpMeta[0] = _OMC_LIT29;
goto tmp2_done;
}
case 4: {
tmpMeta[0] = _OMC_LIT30;
goto tmp2_done;
}
case 6: {
tmpMeta[0] = _OMC_LIT31;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outInnerOuter = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outInnerOuter;
}
DLLExport
modelica_metatype omc_NFInstUtil_daeToAbsynDirection(threadData_t *threadData, modelica_metatype _inDirection)
{
modelica_metatype _outDirection = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inDirection;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 5: {
tmpMeta[0] = _OMC_LIT32;
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _OMC_LIT33;
goto tmp2_done;
}
case 4: {
tmpMeta[0] = _OMC_LIT34;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outDirection = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outDirection;
}
DLLExport
modelica_metatype omc_NFInstUtil_daeToSCodeVariability(threadData_t *threadData, modelica_metatype _inVariability)
{
modelica_metatype _outVariability = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inVariability;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
tmpMeta[0] = _OMC_LIT35;
goto tmp2_done;
}
case 4: {
tmpMeta[0] = _OMC_LIT36;
goto tmp2_done;
}
case 5: {
tmpMeta[0] = _OMC_LIT37;
goto tmp2_done;
}
case 6: {
tmpMeta[0] = _OMC_LIT38;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outVariability = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outVariability;
}
DLLExport
modelica_metatype omc_NFInstUtil_daeToSCodeParallelism(threadData_t *threadData, modelica_metatype _inParallelism)
{
modelica_metatype _outParallelism = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inParallelism;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
tmpMeta[0] = _OMC_LIT39;
goto tmp2_done;
}
case 4: {
tmpMeta[0] = _OMC_LIT40;
goto tmp2_done;
}
case 5: {
tmpMeta[0] = _OMC_LIT41;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outParallelism = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outParallelism;
}
DLLExport
modelica_metatype omc_NFInstUtil_daeToSCodeConnectorType(threadData_t *threadData, modelica_metatype _inConnectorType)
{
modelica_metatype _outConnectorType = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inConnectorType;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 6: {
tmpMeta[0] = _OMC_LIT42;
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _OMC_LIT42;
goto tmp2_done;
}
case 4: {
tmpMeta[0] = _OMC_LIT43;
goto tmp2_done;
}
case 5: {
tmpMeta[0] = _OMC_LIT44;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outConnectorType = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outConnectorType;
}
