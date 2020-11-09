#pragma once
/** @addtogroup solverKinsol
 *
 *  @{
 */

#include <kinsol/kinsol.h>
#include <kinsol/kinsol_impl.h>
#include <nvector/nvector_serial.h>
#include <sunlinsol/sunlinsol_dense.h>       /* Default dense linear solver */
/* Will be used with new sundials version */
//#include <sunlinsol/sunlinsol_klu.h>         /* Linear solver KLU */
#include <sunlinsol/sunlinsol_spgmr.h>      /* Scaled, Preconditioned, Generalized Minimum Residual iterative linear solver */
#include <sunlinsol/sunlinsol_spbcgs.h>     /* Scaled, Preconditioned, Bi-Conjugate Gradient, Stabilized iterative linear solver */

int KINLapackCompletePivoting(void* kinmem, int N);
static int KINLapackCompletePivotingInit(KINMem kin_mem);
static int KINLapackCompletePivotingSetup(KINMem kin_mem);
static int KINLapackCompletePivotingSolve(KINMem kin_mem, N_Vector x, N_Vector b, realtype *sJpnorm, realtype *sFdotJp);
static int KINLapackCompletePivotingFree(KINMem kin_mem);

static int calcJacobian(KINMem kin_mem);

struct linSysData
{
    double* jac;
    double* scale;
    long int* ihelpArray;
    long int* jhelpArray;
    long int n;
};
