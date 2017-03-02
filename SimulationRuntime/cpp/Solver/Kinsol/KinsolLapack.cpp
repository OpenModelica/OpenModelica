#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
/** @addtogroup solverKinsol
*
*  @{
*/
#include <kinsol/kinsol_direct.h>
#include <sundials/sundials_dense.h>
#include <kinsol/kinsol_impl.h>
#include <kinsol/kinsol_spbcgs.h>
#include <kinsol/kinsol_sptfqmr.h>
//#include <kinsol/kinsol_klu.h>
#include <nvector/nvector_serial.h>
#include <Solver/Kinsol/KinsolLapack.h>



/**
 *  \file KinsolLapack.cpp
 *  \brief Alernative linear solver for Kinsol. The linear solver uses Lapack with complete pivoting for LU factorisation
 */


/**
Forward declarations for used external C functions
*/
extern "C" void dgetc2_(long int *n, double *J, long int *ldj, long int *ipivot, long int *jpivot, long int *idid);
extern "C" void dgesc2_(long int *n, double *J, long int *ldj, double* f, long int *ipivot, long int *jpivot, double *scale);




 /**\brief Function to set linear solver for Kinsol
 *  \param [in] kinmem Parameter_Description
 *  \param [in] N size of system
 *  \return status value
 */
int KINLapackCompletePivoting(void *kinmem, int N)
{
	KINMem kin_mem= (KINMem) kinmem;
	kin_mem->kin_linit  = KINLapackCompletePivotingInit;
	kin_mem->kin_lsetup = KINLapackCompletePivotingSetup;
	kin_mem->kin_lsolve = KINLapackCompletePivotingSolve;
	kin_mem->kin_lfree  = KINLapackCompletePivotingFree;
    kin_mem->kin_setupNonNull = TRUE;
	linSysData* data = new linSysData();
	data->jac              = new double[N*N];
	data->scale			  = new double[N];
	data->ihelpArray       = new long int[N];
	data->jhelpArray =     new long int[N];
	data->n=N;
    memset(data->ihelpArray, 0, N*sizeof(long int));
	memset(data->jhelpArray, 0, N*sizeof(long int));
	memset(data->jac, 0, N*N*sizeof(double));
	kin_mem->kin_lmem = (void*)data;
	return 0;
}
/**\brief  callback function to initialize linear solver for Kinsol
 *  \param [in] kin_mem Parameter_Description
 *  \return Return_Description
 *  \details Details
 */
static int KINLapackCompletePivotingInit(KINMem kin_mem)
{
	int flag = 0;
	return(flag);
}
/**\brief callback function to calcluate jacobian matrix and do lu factorisation
 *  \param [in] kin_mem Parameter_Description
 *  \return Return_Description
 *  \details Details
 */
static int KINLapackCompletePivotingSetup(KINMem kin_mem)
{
	int flag=0;
	linSysData* data = (linSysData*)kin_mem->kin_lmem;
	long int irtrn  = 0;          // Retrun-flag of Fortran code
 	flag =calcJacobian(kin_mem);
	dgetc2_(&data->n, data->jac,&data->n, data->ihelpArray, data->jhelpArray, &irtrn);
    return(flag);
}

/**\brief callback function to free linear solver
 *  \param [in] kin_mem Parameter_Description
 *  \return Return_Description
 *  \details Details
 */




#if(SUNDIALS_MAJOR_VERSION == 2 && SUNDIALS_MINOR_VERSION > 6)
static int KINLapackCompletePivotingFree(KINMem kin_mem)
#else
static void KINLapackCompletePivotingFree(KINMem kin_mem)
#endif
{
	linSysData* data = (linSysData*)kin_mem->kin_lmem;

	delete [] data->jac;
	delete [] data->scale;
	delete [] data->ihelpArray;
	delete [] data->jhelpArray;
	delete data;
	#if (SUNDIALS_MAJOR_VERSION == 2 && SUNDIALS_MINOR_VERSION > 6)
    return 0;
	#endif
}
/**\brief Brief callback function to solve linear system
 *  \param [in] kin_mem Parameter_Description
 *  \param [in] x Parameter_Description
 *  \param [in] b Parameter_Description
 *  \param [in] sJpnorm Parameter_Description
 *  \param [in] sFdotJp Parameter_Description
 *  \return Return_Description
 *  \details Details
 */
#if SUNDIALS_MAJOR_VERSION > 2 || (SUNDIALS_MAJOR_VERSION == 2 && SUNDIALS_MINOR_VERSION > 5)
  static int	 KINLapackCompletePivotingSolve(KINMem kin_mem, N_Vector x, N_Vector b, realtype *sJpnorm, realtype *sFdotJp)
#else
  static int   KINLapackCompletePivotingSolve(KINMem kin_mem, N_Vector x, N_Vector b, realtype *res_norm)
#endif
{
	int flag=0;
	linSysData* data = (linSysData*)kin_mem->kin_lmem;

	dgesc2_(&data->n,data->jac,&data->n, NV_DATA_S(b), data->ihelpArray, data->jhelpArray, data->scale);

	memcpy(NV_DATA_S(x),NV_DATA_S(b),data->n*sizeof(double));
#if SUNDIALS_MAJOR_VERSION > 2 || (SUNDIALS_MAJOR_VERSION == 2 && SUNDIALS_MINOR_VERSION > 5)
	*sFdotJp = N_VDotProd(kin_mem->kin_fval, b);
#else
	N_VProd(b, kin_mem->kin_fscale, b);
#endif

	return(flag);
}
/**\brief function to calcluate jacobian matrix
 *  \param [in] kin_mem Parameter_Description
 *  \return Return_Description
 *  \details Details
 */
static int calcJacobian(KINMem kin_mem)
{
	linSysData* data = (linSysData*)kin_mem->kin_lmem;
	double *u_data, *uscale_data;
	double uscale, uj, ujscale, sign;


	u_data   = N_VGetArrayPointer(kin_mem->kin_uu);
	uscale_data = N_VGetArrayPointer(kin_mem->kin_uscale);

	for(int j=0; j<data->n; ++j)
	{

		uj = NV_Ith_S(kin_mem->kin_uu,j);
		ujscale = 1.0/uscale_data[j];
		sign = (uj >= 0.0) ? 1.0 : -1.0;
		// Reset variables for every column
		memcpy(NV_DATA_S(kin_mem->kin_vtemp2),NV_DATA_S(kin_mem->kin_uu),data->n*sizeof(double));
		double stepsize=1.e-14*max(uj,ujscale)*sign;


		// Finitializee difference
		NV_Ith_S(kin_mem->kin_vtemp2,j) = NV_Ith_S(kin_mem->kin_vtemp2,j) + stepsize;

		int retval = kin_mem->kin_func(kin_mem->kin_vtemp2, kin_mem->kin_vtemp1, kin_mem->kin_user_data);
		if (retval != 0) break;

		// Build Jacobian in Fortran format
		for(int i=0; i<data->n; ++i)
		{
			double val = NV_Ith_S(kin_mem->kin_fval,i);
			double val2 =  NV_Ith_S(kin_mem->kin_vtemp1,i);
			data->jac[i+j*data->n] = (NV_Ith_S(kin_mem->kin_fval,i) - NV_Ith_S(kin_mem->kin_vtemp1,i)) / stepsize;
		}
		NV_Ith_S(kin_mem->kin_vtemp2,j) -=stepsize;
	}
	return 0;
}

