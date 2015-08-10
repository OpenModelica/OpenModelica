#pragma once
/** @addtogroup solverKinsol
 *
 *  @{
 */

int KINLapackCompletePivoting(void *kinmem, int N);
static int KINLapackCompletePivotingInit(KINMem kin_mem);
static int KINLapackCompletePivotingSetup(KINMem kin_mem);
static int KINLapackCompletePivotingSolve(KINMem kin_mem, N_Vector x, N_Vector b,realtype *res_norm/*used in new sundials: realtype *sJpnorm, realtype *sFdotJp*/);
static void KINLapackCompletePivotingFree(KINMem kin_mem);
static int calcJacobian(KINMem kin_mem);

struct linSysData
{
  double* jac;
  double* scale;
  long int* ihelpArray;
  long int* jhelpArray;
  long int n;
};


