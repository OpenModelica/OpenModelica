/* Jacobians 7 */
#include "Example_model.h"
#include "Example_12jac.h"
#include "simulation/jacobian_util.h"
#include "util/omc_file.h"
int Example_functionJacA_column(DATA* data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  return 0;
}
int Example_functionJacB_column(DATA* data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  return 0;
}
int Example_functionJacC_column(DATA* data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  return 0;
}
int Example_functionJacD_column(DATA* data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  return 0;
}
int Example_functionJacF_column(DATA* data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  return 0;
}
int Example_functionJacH_column(DATA* data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  return 0;
}
/* constant equations */
/* dynamic equations */

/*
equation index: 34
type: SES_RESIZABLE_ASSIGN call index: 0
*/
void Example_eqFunction_34(DATA *data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  const int baseClockIndex = 0;
  const int subClockIndex = 0;
  const int equationIndexes[2] = {1,34};
    for(modelica_integer _omcQ_24i1=((modelica_integer) 1); in_range_integer(_omcQ_24i1, ((modelica_integer) 1), ((modelica_integer) 3)); _omcQ_24i1+=((modelica_integer) 1)){
    genericCall_jac_0(data, threadData, jacobian, equationIndexes, _omcQ_24i1); /*Example_genericCall*/
    }
  threadData->lastEquationSolved = 34;
}

/*
equation index: 33
type: SIMPLE_ASSIGN
$pDER_ODE_JAC_ADJ.$FUN_1 = $pDER_ODE_JAC_ADJ.$FUN_1
*/
void Example_eqFunction_33(DATA *data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  const int baseClockIndex = 0;
  const int subClockIndex = 1;
  const int equationIndexes[2] = {1,33};
  jacobian->tmpVars[4] /* $pDER_ODE_JAC_ADJ.$FUN_1 JACOBIAN_TMP_VAR */ = jacobian->tmpVars[4] /* $pDER_ODE_JAC_ADJ.$FUN_1 JACOBIAN_TMP_VAR */;
  threadData->lastEquationSolved = 33;
}

/*
equation index: 32
type: SIMPLE_ASSIGN
$pDER_ODE_JAC_ADJ.$FUN_1 = 0.0
*/
void Example_eqFunction_32(DATA *data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  const int baseClockIndex = 0;
  const int subClockIndex = 2;
  const int equationIndexes[2] = {1,32};
  jacobian->tmpVars[4] /* $pDER_ODE_JAC_ADJ.$FUN_1 JACOBIAN_TMP_VAR */ = 0.0;
  threadData->lastEquationSolved = 32;
}

/*
equation index: 31
type: SIMPLE_ASSIGN
$pDER_ODE_JAC_ADJ.a = $pDER_ODE_JAC_ADJ.a + $pDER_ODE_JAC_ADJ.c + $pDER_ODE_JAC_ADJ.b
*/
void Example_eqFunction_31(DATA *data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  const int baseClockIndex = 0;
  const int subClockIndex = 3;
  const int equationIndexes[2] = {1,31};
  jacobian->tmpVars[11] /* $pDER_ODE_JAC_ADJ.a JACOBIAN_TMP_VAR */ = jacobian->tmpVars[11] /* $pDER_ODE_JAC_ADJ.a JACOBIAN_TMP_VAR */ + jacobian->tmpVars[3] /* $pDER_ODE_JAC_ADJ.c JACOBIAN_TMP_VAR */ + jacobian->tmpVars[2] /* $pDER_ODE_JAC_ADJ.b JACOBIAN_TMP_VAR */;
  threadData->lastEquationSolved = 31;
}

/*
equation index: 30
type: SIMPLE_ASSIGN
$pDER_ODE_JAC_ADJ.a = 0.0
*/
void Example_eqFunction_30(DATA *data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  const int baseClockIndex = 0;
  const int subClockIndex = 4;
  const int equationIndexes[2] = {1,30};
  jacobian->tmpVars[11] /* $pDER_ODE_JAC_ADJ.a JACOBIAN_TMP_VAR */ = 0.0;
  threadData->lastEquationSolved = 30;
}

/*
equation index: 29
type: SIMPLE_ASSIGN
$pDER_ODE_JAC_ADJ.c = $pDER_ODE_JAC_ADJ.c
*/
void Example_eqFunction_29(DATA *data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  const int baseClockIndex = 0;
  const int subClockIndex = 5;
  const int equationIndexes[2] = {1,29};
  jacobian->tmpVars[3] /* $pDER_ODE_JAC_ADJ.c JACOBIAN_TMP_VAR */ = jacobian->tmpVars[3] /* $pDER_ODE_JAC_ADJ.c JACOBIAN_TMP_VAR */;
  threadData->lastEquationSolved = 29;
}

/*
equation index: 28
type: SIMPLE_ASSIGN
$pDER_ODE_JAC_ADJ.c = 0.0
*/
void Example_eqFunction_28(DATA *data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  const int baseClockIndex = 0;
  const int subClockIndex = 6;
  const int equationIndexes[2] = {1,28};
  jacobian->tmpVars[3] /* $pDER_ODE_JAC_ADJ.c JACOBIAN_TMP_VAR */ = 0.0;
  threadData->lastEquationSolved = 28;
}

/*
equation index: 27
type: SIMPLE_ASSIGN
$pDER_ODE_JAC_ADJ.b = $pDER_ODE_JAC_ADJ.b
*/
void Example_eqFunction_27(DATA *data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  const int baseClockIndex = 0;
  const int subClockIndex = 7;
  const int equationIndexes[2] = {1,27};
  jacobian->tmpVars[2] /* $pDER_ODE_JAC_ADJ.b JACOBIAN_TMP_VAR */ = jacobian->tmpVars[2] /* $pDER_ODE_JAC_ADJ.b JACOBIAN_TMP_VAR */;
  threadData->lastEquationSolved = 27;
}

/*
equation index: 26
type: SIMPLE_ASSIGN
$pDER_ODE_JAC_ADJ.b = 0.0
*/
void Example_eqFunction_26(DATA *data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  const int baseClockIndex = 0;
  const int subClockIndex = 8;
  const int equationIndexes[2] = {1,26};
  jacobian->tmpVars[2] /* $pDER_ODE_JAC_ADJ.b JACOBIAN_TMP_VAR */ = 0.0;
  threadData->lastEquationSolved = 26;
}

/*
equation index: 25
type: SIMPLE_ASSIGN
$pDER_ODE_JAC_ADJ.y = $pDER_ODE_JAC_ADJ.y + $SEED_ODE_JAC_ADJ.$DER.v + $pDER_ODE_JAC_ADJ.a + $pDER_ODE_JAC_ADJ.c + $pDER_ODE_JAC_ADJ.b
*/
void Example_eqFunction_25(DATA *data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  const int baseClockIndex = 0;
  const int subClockIndex = 9;
  const int equationIndexes[2] = {1,25};
  jacobian->tmpVars[9] /* $pDER_ODE_JAC_ADJ.y JACOBIAN_TMP_VAR */ = jacobian->tmpVars[9] /* $pDER_ODE_JAC_ADJ.y JACOBIAN_TMP_VAR */ + jacobian->seedVars[0] /* $SEED_ODE_JAC_ADJ.der(v) SEED_VAR */ + jacobian->tmpVars[11] /* $pDER_ODE_JAC_ADJ.a JACOBIAN_TMP_VAR */ + jacobian->tmpVars[3] /* $pDER_ODE_JAC_ADJ.c JACOBIAN_TMP_VAR */ + jacobian->tmpVars[2] /* $pDER_ODE_JAC_ADJ.b JACOBIAN_TMP_VAR */;
  threadData->lastEquationSolved = 25;
}

/*
equation index: 24
type: SIMPLE_ASSIGN
$pDER_ODE_JAC_ADJ.y = 0.0
*/
void Example_eqFunction_24(DATA *data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  const int baseClockIndex = 0;
  const int subClockIndex = 10;
  const int equationIndexes[2] = {1,24};
  jacobian->tmpVars[9] /* $pDER_ODE_JAC_ADJ.y JACOBIAN_TMP_VAR */ = 0.0;
  threadData->lastEquationSolved = 24;
}

/*
equation index: 23
type: SIMPLE_ASSIGN
$pDER_ODE_JAC_ADJ.z = $pDER_ODE_JAC_ADJ.z + $pDER_ODE_JAC_ADJ.a + $pDER_ODE_JAC_ADJ.c + $pDER_ODE_JAC_ADJ.b
*/
void Example_eqFunction_23(DATA *data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  const int baseClockIndex = 0;
  const int subClockIndex = 11;
  const int equationIndexes[2] = {1,23};
  jacobian->tmpVars[10] /* $pDER_ODE_JAC_ADJ.z JACOBIAN_TMP_VAR */ = jacobian->tmpVars[10] /* $pDER_ODE_JAC_ADJ.z JACOBIAN_TMP_VAR */ + jacobian->tmpVars[11] /* $pDER_ODE_JAC_ADJ.a JACOBIAN_TMP_VAR */ + jacobian->tmpVars[3] /* $pDER_ODE_JAC_ADJ.c JACOBIAN_TMP_VAR */ + jacobian->tmpVars[2] /* $pDER_ODE_JAC_ADJ.b JACOBIAN_TMP_VAR */;
  threadData->lastEquationSolved = 23;
}

/*
equation index: 22
type: SIMPLE_ASSIGN
$pDER_ODE_JAC_ADJ.z = 0.0
*/
void Example_eqFunction_22(DATA *data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  const int baseClockIndex = 0;
  const int subClockIndex = 12;
  const int equationIndexes[2] = {1,22};
  jacobian->tmpVars[10] /* $pDER_ODE_JAC_ADJ.z JACOBIAN_TMP_VAR */ = 0.0;
  threadData->lastEquationSolved = 22;
}

void Example_eqFunction_19(DATA*, threadData_t*);
void Example_eqFunction_20(DATA*, threadData_t*);
/*
equation index: 21
indexNonlinear: 1
type: NONLINEAR

vars: {$pDER_ODE_JAC_ADJ.$TMP_1, $pDER_ODE_JAC_ADJ.$TMP_2}
eqns: {19, 20}
*/
void Example_eqFunction_21(DATA *data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  const int baseClockIndex = 0;
  const int subClockIndex = 13;
  const int equationIndexes[2] = {1,21};
  int retValue;
  infoStreamPrint(OMC_LOG_DT, 0, "Solving nonlinear system 21 (STRICT TEARING SET if tearing enabled) at time = %18.10e", data->localData[0]->timeValue);
  /* get old value */
  data->simulationInfo->nonlinearSystemData[1].nlsxOld[0] = jacobian->tmpVars[0] /* $pDER_ODE_JAC_ADJ.$TMP_1 JACOBIAN_TMP_VAR */;
  data->simulationInfo->nonlinearSystemData[1].nlsxOld[1] = jacobian->tmpVars[1] /* $pDER_ODE_JAC_ADJ.$TMP_2 JACOBIAN_TMP_VAR */;
  retValue = solve_nonlinear_system(data, threadData, 1);
  /* check if solution process was successful */
  if (retValue > 0){
    const int indexes[2] = {1,21};
    throwStreamPrintWithEquationIndexes(threadData, omc_dummyFileInfo, indexes, "Solving non-linear system 21 failed at time=%.15g.\nFor more information please use -lv LOG_NLS.", data->localData[0]->timeValue);
  }
  /* write solution */
  jacobian->tmpVars[0] /* $pDER_ODE_JAC_ADJ.$TMP_1 JACOBIAN_TMP_VAR */ = data->simulationInfo->nonlinearSystemData[1].nlsx[0];
  jacobian->tmpVars[1] /* $pDER_ODE_JAC_ADJ.$TMP_2 JACOBIAN_TMP_VAR */ = data->simulationInfo->nonlinearSystemData[1].nlsx[1];
  threadData->lastEquationSolved = 21;
}

/*
equation index: 18
type: SIMPLE_ASSIGN
$pDER_ODE_JAC_ADJ.v = $pDER_ODE_JAC_ADJ.v + $pDER_ODE_JAC_ADJ.$TMP_2
*/
void Example_eqFunction_18(DATA *data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  const int baseClockIndex = 0;
  const int subClockIndex = 14;
  const int equationIndexes[2] = {1,18};
  jacobian->resultVars[0] /* $pDER_ODE_JAC_ADJ.v JACOBIAN_VAR */ = jacobian->resultVars[0] /* $pDER_ODE_JAC_ADJ.v JACOBIAN_VAR */ + jacobian->tmpVars[1] /* $pDER_ODE_JAC_ADJ.$TMP_2 JACOBIAN_TMP_VAR */;
  threadData->lastEquationSolved = 18;
}

OMC_DISABLE_OPT
int Example_functionJacADJ_constantEqns(DATA* data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  int index = Example_INDEX_JAC_ADJ;
  
  
  return 0;
}

int Example_functionJacADJ_column(DATA* data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  int index = Example_INDEX_JAC_ADJ;
  
  static void (*const eqFunctions[15])(DATA*, threadData_t*, JACOBIAN*, JACOBIAN*) = {
    Example_eqFunction_34,
    Example_eqFunction_33,
    Example_eqFunction_32,
    Example_eqFunction_31,
    Example_eqFunction_30,
    Example_eqFunction_29,
    Example_eqFunction_28,
    Example_eqFunction_27,
    Example_eqFunction_26,
    Example_eqFunction_25,
    Example_eqFunction_24,
    Example_eqFunction_23,
    Example_eqFunction_22,
    Example_eqFunction_21,
    Example_eqFunction_18
  };
  
  if (jacobian->evalSelection) {
    for (int i = 0; i < jacobian->evalSelection->n; i++) {
      int id = jacobian->evalSelection->idx[i];
      eqFunctions[id](data, threadData, jacobian, parentJacobian);
    }
  } else {
    for (int id = 0; id < 15; id++) {
      eqFunctions[id](data, threadData, jacobian, parentJacobian);
    }
  }
  
  return 0;
}

int Example_initialAnalyticJacobianA(DATA* data, threadData_t *threadData, JACOBIAN *jacobian)
{
  jacobian->availability = JACOBIAN_NOT_AVAILABLE;
  return 1;
}
int Example_initialAnalyticJacobianB(DATA* data, threadData_t *threadData, JACOBIAN *jacobian)
{
  jacobian->availability = JACOBIAN_NOT_AVAILABLE;
  return 1;
}
int Example_initialAnalyticJacobianC(DATA* data, threadData_t *threadData, JACOBIAN *jacobian)
{
  jacobian->availability = JACOBIAN_NOT_AVAILABLE;
  return 1;
}
int Example_initialAnalyticJacobianD(DATA* data, threadData_t *threadData, JACOBIAN *jacobian)
{
  jacobian->availability = JACOBIAN_NOT_AVAILABLE;
  return 1;
}
int Example_initialAnalyticJacobianF(DATA* data, threadData_t *threadData, JACOBIAN *jacobian)
{
  jacobian->availability = JACOBIAN_NOT_AVAILABLE;
  return 1;
}
int Example_initialAnalyticJacobianH(DATA* data, threadData_t *threadData, JACOBIAN *jacobian)
{
  jacobian->availability = JACOBIAN_NOT_AVAILABLE;
  return 1;
}
OMC_DISABLE_OPT
int Example_initialAnalyticJacobianADJ(DATA* data, threadData_t *threadData, JACOBIAN *jacobian)
{
  size_t count;

  FILE* pFile = openSparsePatternFile(data, threadData, "Example_JacADJ.bin");
  
  initJacobian(jacobian, 1, 1, 1, NULL, Example_functionJacADJ_column, NULL, NULL);
  jacobian->sparsePattern = allocSparsePattern(1, 1, 1);
  jacobian->availability = JACOBIAN_AVAILABLE;
  
  /* read lead index of compressed sparse column */
  count = omc_fread(jacobian->sparsePattern->leadindex, sizeof(unsigned int), 1+1, pFile, FALSE);
  if (count != 1+1) {
    throwStreamPrint(threadData, "Error while reading lead index list of sparsity pattern. Expected %d, got %zu", 1+1, count);
  }
  
  /* read sparse index */
  count = omc_fread(jacobian->sparsePattern->index, sizeof(unsigned int), 1, pFile, FALSE);
  if (count != 1) {
    throwStreamPrint(threadData, "Error while reading row index list of sparsity pattern. Expected %d, got %zu", 1, count);
  }
  
  /* write color array */
  /* color 1 with 1 columns */
  readSparsePatternColor(threadData, pFile, jacobian->sparsePattern->colorCols, 1, 1, 1);
  
  omc_fclose(pFile);
  
  return 0;
}

/*
single generic call 0 {$i1 in 1:1:3}
  $pDER_ODE_JAC_ADJ.x[$i1] = 0.0;
*/
void genericCall_jac_0(DATA *data, threadData_t *threadData, JACOBIAN *jacobian, const int equationIndexes[2], modelica_integer _omcQ_24i1)
{
  jacobian->tmpVars[6] /* $pDER_ODE_JAC_ADJ.x[1] JACOBIAN_TMP_VAR */ = 0.0;;
}
