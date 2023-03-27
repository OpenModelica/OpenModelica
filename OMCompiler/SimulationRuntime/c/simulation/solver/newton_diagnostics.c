/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2021, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

/*! \file newton_diagnostics.c
 *  Containing all functions to run newton diagnostics on non-linear loops.
 *  Improve start values for non-linear loops.
 */


/**
 * @brief Start point for newton diagnostics.
 *
 * Calculation of:
 * 1) alpha     : alpha coefficients
 * 2) Gamma_ijk : curvature factors
 * 3) sigma_ij  : solution sensitivities
 *
 * According to
 *    F.Casella and B.Bachman
 *    On the choice of initial guesses for the Newton-Raphson algorithm
 *    Applied Mathematics and Computation 398 (2021) 125991
 *
 * By Teus van der Stelt, Asimptote bv, the Netherlands
 * Carried out on behalf of the Delft University of Technology, 2023
 *
 * @param data          Pointer to all simulation data.
 * @param threadData    Pointer to thread data for error handling mainly.
 */

#include "newton_diagnostics.h"
#include "../simulation_info_json.h"
#include "../jacobian_util.h"

#ifndef max
#define max(a,b) ((a)>(b)?(a):(b))
#endif

extern int dgesv_(int *n, int *nrhs, double *a, int *lda,
                  int *ipiv, double *b, int *ldb, int *info);

extern int dgetrf_(int *n, int *nrhs, double *a, int *lda,
                   int *ipiv, int *info);

extern int dgetri_(int *n, double *a, int *lda,
                   int *ipiv, double *work, int *lwork, int *info);

// --------------------------------------------------------------------------------------------------------------------------------

unsigned var_id( unsigned idx, DATA* data, NONLINEAR_SYSTEM_DATA* systemData)
{
   // Returns index of "modelInfoGetEquation(&data->modelData->modelDataXml, systemData->equationIndex).vars[idx])"
   // in "data->modelData->realVarsData[i]"

   unsigned id = -1;
   for( unsigned int i = 0; i < data->modelData->nVariablesReal; ++i)
   {
      if (!strcmp(data->modelData->realVarsData[i].info.name, modelInfoGetEquation(&data->modelData->modelDataXml, systemData->equationIndex).vars[idx]))
      {
         id = i;
         break;
      }
   }
   return id;
}

double** MatMult( unsigned rA, unsigned cArB, unsigned cB, double** A, double** B)
{
   // Matrix multiplication A[rA][cArB] * B[cArB][cB] = C[rA][cB]

   double** C = (double**)malloc(rA * sizeof(double*));
   for( unsigned i = 0; i < rA; i++)
      C[i] = (double*)malloc(cB * sizeof(double));

   for( unsigned i = 0; i < rA; i++)
   {
      for( unsigned j = 0; j < cB; j++)
      {
         C[i][j] = 0;
         for( unsigned k = 0; k < cArB; k++)
            C[i][j] += A[i][k] * B[k][j];
      }
   }

   return C;
}

// --------------------------------------------------------------------------------------------------------------------------------

double** getJacobian( DATA* data, threadData_t *threadData, unsigned sysNumber, unsigned m)
{
   NONLINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo->nonlinearSystemData[sysNumber]);
   ANALYTIC_JACOBIAN* jac = &(data->simulationInfo->analyticJacobians[systemData->jacobianIndex]);

   unsigned i, j;

   // Allocate memory for fx (m * m matrix)
   double** fx = (double**)malloc(m * sizeof(double*));
   for( i = 0; i < m; i++)
      fx[i] = (double*)malloc(m * sizeof(double));

   // Order of Jacobian elements:
   // variable 1:   df_1/dv_1, df_1/dv_2, .... df_1/dv_n
   // variable 2:   df_2/dv_1, df_2/dv_2, .... df_2/dv_n
   // ...
   // ...
   // variable n:   df_n/dv_1, df_2/dv_2, .... df_n/dv_n

   for( j = 0; j < m; j++)
   {
      jac->seedVars[j] = 1.0;

      // Calculate values for one column of the Jacobian, output: df_1/dv_j, df_2/dv_j, .... df_n/dv_j
      ((systemData->analyticalJacobianColumn))(data, threadData, jac, NULL);

      // Store values in column of Jacobian
      for( i = 0; i < m; i++)
         fx[i][j] = jac->resultVars[i];

      jac->seedVars[j] = 0.0;
   }

   return fx;
}

// --------------------------------------------------------------------------------------------------------------------------------

double* getFirstNewtonStep( unsigned m, double* f, double** fx)
{
   // Function values iteration 0: vector f(x0)
   // Values Jacobian iteration 0: vector fx(x0)
   // Newton step: dx = -f(x0)/fx(x0)

   // Allocate memory for Newton steps
   double* dx = (double*)malloc(m * sizeof(double));

   // Variables for Lapack routines
   int N = m;                           // number of rows and columns of Jacobian
   int NRHS = 1;                        // number of columns of b, i.e. f(x)
   int LDA = N;
   int LDB = N;
   int* ipiv = (int*)malloc(N* sizeof(int));
   int info;

   double* a = (double*)malloc( LDA * N * sizeof(double));
   double* b = (double*)malloc( LDB * NRHS * sizeof(double));

   unsigned i, j;

   // Store Jacobian values J(x0) in a
   for( i = 0; i < m; i++)
      for( j = 0; j < m; j++)
         a[m*i+j] = fx[j][i];

   // Store function values f(x0) in b
   for( i = 0; i < m; i++)
      b[i] = f[i];

   // Call Lapack function dgesv; after return, b contains the Newton steps
   dgesv_(&N, &NRHS, a, &LDA, ipiv, b, &LDB, &info);

   if (info > 0)
      printf( "getFirstNewtonStep: the first Newton step could not be computed; the info satus is : %d\n", info);
   else
   {
      // Store Newton steps in dx
      for( j = 0; j < m; j++)
         dx[j] = -b[j];
   }

   free(ipiv);
   free(a);
   free(b);

   return dx;
}

// --------------------------------------------------------------------------------------------------------------------------------

double maxNonLinearResiduals( unsigned m, unsigned l, unsigned* z_idx,
                              double* f, double** fx, double* dx)
{
   // Calculate the absolute maximum value of the non-linear residuals r_x0 = f_x0 + fz * (z1 - z0)
   // at iteration point x0, where z1 - z0 = dx and fz = J for the linear values and equations.

   // l = m - p: number of linear dependables or equations
   // z_idx    : index of linear dependable in f, fx, dx

   double r_x0, fz_dz;
   double maxRes = 1.e-88;
   unsigned i, j;

   for( i = 0; i < m; i++)
   {
      fz_dz = 0;
      for( j = 0; j < l; j++)  // iteration point x0 ==> j = 1 as r_x(j-1) = f_x(j-1) + fz * (z(j) - z(j-1)) = f_x(j-1) + fz * dz(j-1)  ????
         fz_dz += fx[i][z_idx[j]] * dx[z_idx[j]];

      r_x0 = fabs(f[i] + fz_dz);
      if (r_x0 > maxRes)
         maxRes = r_x0;
   }

   return maxRes;
}

// --------------------------------------------------------------------------------------------------------------------------------

double*** getHessian( DATA* data, threadData_t *threadData, unsigned sysNumber, unsigned m)
{
   NONLINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo->nonlinearSystemData[sysNumber]);
   ANALYTIC_JACOBIAN* jac = &(data->simulationInfo->analyticJacobians[systemData->jacobianIndex]);

   unsigned i, j, k;
   const modelica_real eps = 1.e-7;
   const modelica_real nominal_x = 1.e-4;
   SIMULATION_DATA *sData = data->localData[0];

   // Allocate memory for Hessian fxx (m * m * m doubles)
   double*** fxx = (double***)malloc(m * sizeof(double**));
   for( i = 0; i < m; i++)
   {
      fxx[i] = (double**)malloc(m * sizeof(double*));
      for( j = 0; j < m; j++)
         fxx[i][j] = (double*)malloc(m * sizeof(double));
   }

   // Allocate memory for Jacobians
   double** fxPls = (double**)malloc(m * sizeof(double*));
   double** fxMin = (double**)malloc(m * sizeof(double*));
   for( i = 0; i < m; i++)
   {
      fxPls[i] = (double*)malloc(m * sizeof(double));
      fxMin[i] = (double*)malloc(m * sizeof(double));
   }

   // ----------------------------------------------- Debug -------------------------------------------------
   /*printf( "\n");
   for( k = 0; k < m; k++)
   {
      unsigned id = var_id(k, data, systemData);
      printf( "               k = %d: id = %d (%s)\n", k, id, data->modelData->realVarsData[id].info.name);
   }*/
   // -------------------------------------------- end of Debug ---------------------------------------------

   for( k = 0; k < m; k++)
   {
      unsigned id = var_id(k, data, systemData);

      double tmp_x = sData->realVars[id];
      const modelica_real delta_x = eps * max( fabs(tmp_x), nominal_x);

      sData->realVars[id] = tmp_x + delta_x;
      for( j = 0; j < m; j++)
      {
         jac->seedVars[j] = 1.0;
         ((systemData->analyticalJacobianColumn))(data, threadData, jac, NULL);
         for( i = 0; i < m; i++)
            fxPls[i][j] = jac->resultVars[i];
         jac->seedVars[j] = 0.0;
      }

      sData->realVars[id] = tmp_x - delta_x;
      for( j = 0; j < m; j++)
      {
         jac->seedVars[j] = 1.0;
         ((systemData->analyticalJacobianColumn))(data, threadData, jac, NULL);
         for( i = 0; i < m; i++)
            fxMin[i][j] = jac->resultVars[i];
         jac->seedVars[j] = 0.0;
      }

      sData->realVars[id] = tmp_x;

      for( j = 0; j < m; j++)
         for( i = 0; i < m; i++)
         {
            fxx[i][k][j] = (fxPls[i][j] - fxMin[i][j]) / (2 * delta_x);
            if (isnan(fxx[i][k][j]))
            {
               printf("NaN detected: fxx[%d][%d][%d]: fxPls[%d][%d] = %f, fxMin[%d][%d] = %f, delta_x = %f\n",
                                          i,j,k,         i,j,fxPls[i][j],    i,j,fxMin[i][j], delta_x);
               return fxx;
            }
         }
   }

   for( i = 0; i < m; i++)
   {
      free(fxPls[i]);
      free(fxMin[i]);
   }
   free(fxPls);
   free(fxMin);

   // ----------------------------------------------- Debug -------------------------------------------------
   /*printf( "\n");
   for( k = 0; k < m; k++)
   {
      // For each eqn. k print m x m matrix
      for( i = 0; i < m; i++)
      {
         if (i == 0)
            printf( "\n\neqn k = %2d: ", k);
         else
            printf( "\n            ");

         for( j = 0; j < m; j++)
            printf( "%7.2f ", fxx[k][i][j]);
      }
   }
   printf( "\n\n");*/
   // -------------------------------------------- end of Debug ---------------------------------------------

   return fxx;
}

// --------------------------------------------------------------------------------------------------------------------------------

double*** calcGamma( unsigned m, unsigned p, unsigned q, unsigned* n_idx,
                     unsigned* w_idx, double* dx, double*** fxx, double maxRes)
{
   // Calculation of curvature factors Gamma_ijk
   // ------------------------------------------
   //
   // m     : total number of equations/independents
   // p     : number of non-linear equations
   // q     : number of non-linear independents
   // n_idx : index of non-linear equation, i.e. of i in fxx[i][j][k]
   // w_idx : index of non-linear dependent, i.e. of j in dx[j] and of j and k in fxx[i][j][k]
   // dx    : Newton step first iteration = x1 - x0, and dx[w_idx] = w1 - w0
   // fxx   : Hessian as function of x0
   // maxRes: absolute maximum value of the non-linear residuals

   unsigned i, j, k;

   // Allocate memory for Gamma_ijk (p * q * q doubles)
   double*** Gamma_ijk = (double***)malloc(p * sizeof(double**));
   for( i = 0; i < p; i++)
   {
      Gamma_ijk[i] = (double**)malloc(q * sizeof(double*));
      for( j = 0; j < q; j++)
         Gamma_ijk[i][j] = (double*)malloc(q * sizeof(double));
   }

   // Calculate Gamma_ijk
   for( i = 0; i < p; i++)
      for( j = 0; j < q; j++)
         for( k = 0; k < q; k++)
            if (!isnan(fxx[n_idx[i]][w_idx[j]][w_idx[k]]) && fxx[n_idx[i]][w_idx[j]][w_idx[k]] != 0)
               Gamma_ijk[i][j][k] = fabs(0.5 * fxx[n_idx[i]][w_idx[j]][w_idx[k]] * (dx[w_idx[j]] * dx[w_idx[k]]) / maxRes);
            else
               Gamma_ijk[i][j][k] = 0;

   return Gamma_ijk;
}


// --------------------------------------------------------------------------------------------------------------------------------

double* calcAlpha( DATA* data, threadData_t* threadData, unsigned sysNumber, unsigned m, unsigned p,
                   unsigned q, unsigned* n_idx, unsigned* w_idx, double* x, double* dx,
                   double* f, double*** fxx, double lambda, double maxRes)
{
   // Calculation of alpha coefficients for all non-linear equations
   // --------------------------------------------------------------
   //
   // m     : total number of equations/independents
   // p     : number of non-linear equations
   // q     : number of non-linear independents
   // n_idx : index of non-linear equation, ie of i in f[i] and fxx[i][j][k]
   // w_idx : index of non-linear dependent, ie of j in x[j] and dx[j] and of j and k in fxx[i][j][k]
   // x     : all independents (non-linear & linear)
   // dx    : Newton step first iteration = x1 - x0, and dx[w_idx] = w1 - w0
   // f     : Function values (ie residuals) as function of x0
   // fxx   : Hessian as function of x0
   // lambda: damping factor
   // maxRes: absolute maximum value of the non-linear residuals of iteration 0

   RESIDUAL_USERDATA resUserData = {.data=data, .threadData=threadData, .solverData=NULL};
   NONLINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo->nonlinearSystemData[sysNumber]);

   unsigned i, j, k;

   // Allocate memory for alpha (p doubles)
   double* alpha = (double*)malloc(p * sizeof(double));

   // Get damped guess x1_star for second iteration step
   double* x1_star = (double*)malloc(m * sizeof(double));
   for( j = 0; j < m; j++)
      x1_star[j] = x[j] + lambda * dx[j];

   // Calculate residuals f_x1_star for damped guess x1_star
   double* f_x1_star = (double*)malloc(m * sizeof(double));
   (systemData->residualFunc)(&resUserData, x1_star, f_x1_star, (int*)&systemData->size);

   // For each non-linear independent get w1_star - w0
   double* w1_star_w0 = (double*)malloc(q * sizeof(double));
   for( j = 0; j < q; j++)
      w1_star_w0[j] = lambda * dx[w_idx[j]];

   // Calculate alpha for each non-linear equation i
   double* w_times_fww_w0 = (double*)malloc(q * sizeof(double));

   for( i = 0; i < p; i++)
   {
      // Vector w_times_fww_w0 = (w1_star - w0)' * fww_w0  (1 x q * q x q --> 1 x q vector)
      for( j = 0; j < q; j++)
      {
         // For each independent
         w_times_fww_w0[j] = 0;
         for( k = 0; k < q; k++)
         {
            if (!isnan(fxx[n_idx[i]][w_idx[k]][w_idx[j]]) && fabs(fxx[n_idx[i]][w_idx[k]][w_idx[j]]) != 0)
               w_times_fww_w0[j] += w1_star_w0[k] * fxx[n_idx[i]][w_idx[k]][w_idx[j]];
         }
      }

      // Scalar w_times_f_times_w = w_times_f_i_ww_w0 * (w1_star - w0) = (w1_star - w0)' * f_i_ww_w0 * (w1_star - w0)
      // (1 x q * q x 1 vector --> scalar)
      double w_times_fww_times_w = 0;
      for( k = 0; k < q; k++)
         w_times_fww_times_w += w_times_fww_w0[k] * w1_star_w0[k];

      // Calculate alpha for the non-linear equations
      alpha[i] = fabs(f_x1_star[n_idx[i]] - (1 - lambda) * f[n_idx[i]] - 0.5 * w_times_fww_times_w) / (pow(lambda,3) * maxRes);
   }

   free(w_times_fww_w0);
   free(w1_star_w0);
   free(f_x1_star);
   free(x1_star);

   return alpha;
}

// --------------------------------------------------------------------------------------------------------------------------------

double** getInvJacobian( unsigned m, double** fx)
{
   // Calculates inverse matrix of Jacobian fx as function of x0 (m x m matrix)
   // -------------------------------------------------------------------------
   //
   // m     : total number of equations/independents
   // fx    : Jacobian as function of x0

   unsigned i, j;

   // Intialize inverse a with fx
   double* a = (double*)malloc(m * m * sizeof(double));
   for( i = 0; i < m; i++)
      for( j = 0; j < m; j++)
         a[m*i+j] = fx[j][i];

   // Variables for Lapack routines
   int N = m;
   int LWORK = N * N;
   int* ipiv = (int*)malloc(N * sizeof(int));
   int info;
   double* WORK = (double*)malloc(LWORK * sizeof(double));

   // Call Lapack function dgetrf to compute the LU factorization of fx
   dgetrf_(&N, &N, a, &N, ipiv, &info);
   if (info > 0)
      printf( "getInvJacobian: LU factorization could not be computed; the info satus is : %d\n", info);

   // Call Lapack function dgetri to compute the inverse of fx
   dgetri_(&N, a, &N, ipiv, WORK, &LWORK, &info);
   if (info > 0)
      printf( "getInvJacobian: inverse Jacobian could not be computed; the info satus is : %d\n", info);

   // Return two dimensional array
   double** inv_fx = (double**)malloc(m * sizeof(double*));
   for( i = 0; i < m; i++)
      inv_fx[i] = (double*)malloc(m * sizeof(double));
   for( i = 0; i < m; i++)
      for( j = 0; j < m; j++)
         inv_fx[j][i] = a[m*i+j];

   free(ipiv);
   free(WORK);
   free(a);

   return inv_fx;
}

// --------------------------------------------------------------------------------------------------------------------------------

double** calcSigma( unsigned m, unsigned q, unsigned* w_idx,
                    double* dx, double** fx, double*** fxx)
{
   // Calculation of solution sensitivities Sigma_ij
   // ----------------------------------------------
   //
   // m     : total number of equations/independents
   // q     : number of non-linear variables
   // w_idx : index of non-linear dependent, i.e. of j in dx[j] and of j and k in fxx[i][j][k]
   // dx    : Newton step first iteration = x1 - x0, and dx[w_idx] = w1 - w0
   // fx    : Jacobian as function of x0
   // fxx   : Hessian as function of x0

   unsigned i, j, k;

   // Calculate inverse Jacobian, i.e. inverse matrix of fx
   ///printf("Calculate inverse Jac of fx\n");
   double** inv_fx = getInvJacobian( m, fx);

   // Get matrix H[i] = (x1 - x0)' * fxx = dx' * fxx (1 x m * m x m matrix --> m vector)
   double** H_i = (double**)malloc(m * sizeof(double*)); // m functions * m vectors --> m x m matrix
   for( i = 0; i < m; i++)
      H_i[i] = (double*)malloc(m * sizeof(double));
   for( i = 0; i < m; i++)
   {
      for( j = 0; j < m; j++)
      {
         H_i[i][j] = 0;
         for( k = 0; k < m; k++)
            H_i[i][j] += dx[k] * fxx[i][k][j];
      }
   }

   // Calculate tmp1 = -inv_fx * H_i
   // (m x m matrix) * (m x m matrix) --> m x m matrix
   for( i = 0; i < m; i++)
   {
      for( j = 0; j < m; j++)
         inv_fx[i][j] = -inv_fx[i][j];
   }
   double** tmp1 = MatMult( m, m, m, inv_fx, H_i);

   // Extract matrix tmp2 from tmp1 for only non-linears (q x q matrix)
   double** tmp2 = (double**)malloc(q * sizeof(double*));
   for( i = 0; i < q; i++)
      tmp2[i] = (double*)malloc(q * sizeof(double));
   for( i = 0; i < q; i++)
   {
      for( j = 0; j < q; j++)
         tmp2[i][j] = tmp1[w_idx[i]][w_idx[j]];
   }

   // Create a q x q matrix wDiag with w1 - w0 = dx[w_idx] on diagonal
   double** wDiag = (double**)malloc(q * sizeof(double*));
   for( i = 0; i < q; i++)
      wDiag[i] = (double*)malloc(q * sizeof(double));
   for( i = 0; i < q; i++)
   {
      for( j = 0; j < q; j++)
         if (i == j)
            wDiag[i][j] = dx[w_idx[i]];
         else
            wDiag[i][j] = 0;
   }

   // Get inverse matrix inv_wDiag of wDiag
   double** inv_wDiag = getInvJacobian( q, wDiag);

   // Calculate tmp3 = | inv_wDiag | * tmp2
   // (q x q matrix) *  (q x q matrix) --> q x q matrix
   for( i = 0; i < q; i++)
      for( j = 0; j < q; j++)
         inv_wDiag[i][j] = fabs(inv_wDiag[i][j]);

   double** tmp3 = MatMult( q, q, q, inv_wDiag, tmp2);

   // Calculate Sigma = tmp3 * wDiag =  | inv_wDiag | * tmp2 * wDiag = | inv_wDiag | * -inv_fx * H_i * wDiag
   double** Sigma = MatMult( q, q, q, tmp3, wDiag);

   // Free dynamically allocated memory
   for( i = 0; i < m; i++)
   {
      free(inv_fx[i]);
      free(H_i[i]);
      free(tmp1[i]);
   }
   free(inv_fx);
   free(H_i);
   free(tmp1);

   for( i = 0; i < q; i++)
   {
      free(wDiag[i]);
      free(inv_wDiag[i]);
      free(tmp2[i]);
      free(tmp3[i]);
   }
   free(wDiag);
   free(inv_wDiag);
   free(tmp2);
   free(tmp3);

   return Sigma;
}

// --------------------------------------------------------------------------------------------------------------------------------

void PrintResults( DATA* data, unsigned sysNumber, unsigned m, unsigned p, unsigned q, unsigned* n_idx, unsigned* w_idx,
                   double* x0, double* alpha, double*** Gamma_ijk, double** Sigma_ij)
{
   printf("  \n   ========================================================");
   printf("  \n   Final results ");
   printf("  \n   ========================================================\n\n");

   NONLINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo->nonlinearSystemData[sysNumber]);

   unsigned i, j, k;
   double eps = 1e-2;

   // ----------------------------------------------- Debug -------------------------------------------------
   /*printf("      Equations\n");
   for( i = 0; i < p; i++)
      printf("\n      i =%2d: %s", n_idx[i]+1, "???"); //, modelInfoGetFunction(&data->modelData->modelDataXml, i).name);
   printf("\n\n");

   printf("      Variables, initial guesses\n");
   for( j = 0; j < q; j++)
      printf("\n      j =%2d: %8s = %10.8g", w_idx[j]+1, data->modelData->realVarsData[var_id(w_idx[j], data, systemData)].info.name, x0[w_idx[j]]);
   printf("\n\n");*/
   // ------------------------------------------- end of Debug ----------------------------------------------

   // Print alpha, Gamma, and Sigma if value > eps
   // --------------------------------------------

   printf("      alpha_i > %4.0e\n", eps);
   printf("      ------------------------");
   for( i = 0; i < p; ++i)
   {
      if (alpha[i] > eps)
      {
         if (alpha[i] < 1.e5)
            printf("\n      alpha_%d =  %8.3f", n_idx[i]+1, alpha[i]);
         else
            printf("\n      alpha_%d =  %8.2e", n_idx[i]+1, alpha[i]);
      }
   }
   printf("\n\n");

   printf("      Gamma_ijk > %4.0e\n", eps);
   printf("      ------------------------");

   for( i = 0; i < p; i++)
   {
      for( j = 0; j < q; j++)
          for( k = j; k < q; k++)
             if (Gamma_ijk[i][j][k] > eps)
                printf("\n      Gamma_%1d_%1d_%1d =  %8.3f", n_idx[i]+1, w_idx[j]+1, w_idx[k]+1, Gamma_ijk[i][j][k]);
   }
   printf("\n\n");

   printf("      |Sigma_jj| > %4.0e\n", eps);
   printf("      ------------------------");
   for( i = 0; i < q; i++)
   {
      if (fabs(Sigma_ij[i][i]) > eps)
         printf("\n      Sigma_%d_%d =  %8.3f", w_idx[i]+1, w_idx[i]+1, fabs(Sigma_ij[i][i]));
   }
   printf("\n\n");

   // Select values of Gamma and Sigma > eps and store them in descending order
   // -------------------------------------------------------------------------

   double   val_largest_alpha, val_largest_Sigma, val_largest_Gamma;

   unsigned idx_largest_alpha, idx_largest_Sigma, l, n_gt_eps = 0,
            idx_largest_G_i, idx_largest_G_j, idx_largest_G_k;

   unsigned* alpha_checked = (unsigned*)malloc(p * sizeof(unsigned));
   unsigned* Sigma_checked = (unsigned*)malloc(q * sizeof(unsigned));
   unsigned*** Gamma_checked = (unsigned***)malloc(p * sizeof(unsigned**));
   for( i = 0; i < p; i++)
   {
      Gamma_checked[i] = (unsigned**)malloc(q * sizeof(unsigned*));
      for( j = 0; j < q; j++)
         Gamma_checked[i][j] = (unsigned*)malloc(q * sizeof(unsigned));
   }
   unsigned* index_alpha = (unsigned*)malloc((p * q * q + m) * sizeof(unsigned));
   unsigned* index_Sigma = (unsigned*)malloc((p * q * q + m) * sizeof(unsigned));
   unsigned* index_Gamma_i = (unsigned*)malloc((p * q * q + m) * sizeof(unsigned));
   unsigned* index_Gamma_j = (unsigned*)malloc((p * q * q + m) * sizeof(unsigned));
   unsigned* index_Gamma_k = (unsigned*)malloc((p * q * q + m) * sizeof(unsigned));

   // Initialize tmp arrays for sorting
   for( i = 0; i < p; i++)
   {
      for( j = 0; j < q; j++)
         for( k = 0; k < q; k++)
            Gamma_checked[i][j][k] = 0;
   }
   for( j = 0; j < q; j++)
      Sigma_checked[j] = 0;

   for( l = 0; l < p * q * q + m; l++)
   {
      // Select largest Gamma variable and its value
      val_largest_Gamma = -1.e10;
      idx_largest_G_i = 0;
      idx_largest_G_j = 0;
      idx_largest_G_k = 0;
      for( i = 0; i < p; i++)
         for( j = 0; j < q; j++)
            for( k = j; k < q; k++)
               if ( Gamma_ijk[i][j][k] > val_largest_Gamma && !Gamma_checked[i][j][k])
               {
                  val_largest_Gamma = Gamma_ijk[i][j][k];
                  idx_largest_G_i = i;
                  idx_largest_G_j = j;
                  idx_largest_G_k = k;
               }

      // Select largest Sigma variable and its value
      val_largest_Sigma = -1.e10;
      idx_largest_Sigma = 0;
      for( i = 0; i < q; i++)
         if ( fabs(Sigma_ij[i][i]) > val_largest_Sigma && !Sigma_checked[i])
         {
            val_largest_Sigma = fabs(Sigma_ij[i][i]);
            idx_largest_Sigma = i;
         }

      // Values < 0 , i.e. less than eps are not considered
      if (val_largest_Gamma < eps && val_largest_Sigma < eps) break;

      // Checkmark and store indices of largest value
      if (val_largest_Gamma > val_largest_Sigma)
      {
         index_Gamma_i[n_gt_eps] = idx_largest_G_i;
         index_Gamma_j[n_gt_eps] = idx_largest_G_j;
         index_Gamma_k[n_gt_eps] = idx_largest_G_k;
         index_Sigma[n_gt_eps] = -1;
         Gamma_checked[idx_largest_G_i][idx_largest_G_j][idx_largest_G_k] = 1;

         // -------------------------------------------- Debug ----------------------------------------------
         //printf("\n      Gamma_%d_%d_%d =  %8.3f", n_idx[idx_largest_G_i]+1, w_idx[idx_largest_G_j]+1,
         //                                          w_idx[idx_largest_G_k]+1, val_largest_Gamma);
         // ---------------------------------------- end of Debug -------------------------------------------
      }
      else
      {
         index_Sigma[n_gt_eps] = idx_largest_Sigma;
         index_Gamma_i[n_gt_eps] = -1;
         index_Gamma_j[n_gt_eps] = -1;
         index_Gamma_k[n_gt_eps] = -1;
         Sigma_checked[idx_largest_Sigma] = 1;

         // -------------------------------------------- Debug ---------------------------------------------
         //printf("\n      Sigma_%d_%d   =  %8.3f", w_idx[idx_largest_Sigma]+1, w_idx[idx_largest_Sigma]+1,
         //                                         fabs(Sigma_ij[idx_largest_Sigma][idx_largest_Sigma]));
         // ---------------------------------------- end of Debug -------------------------------------------
      }

      // Increment number of values found
      n_gt_eps++;
   }
   //printf("\n\n");

   // Print variables referenced by Sigma and Gamma values > eps and concerned Sigma or Gamma value
   // ---------------------------------------------------------------------------------------------

   unsigned* printedIdx = (unsigned*)malloc(2 * n_gt_eps * sizeof(unsigned));
   unsigned nPrinted = 0;
   printf("      Variables    Initial guess         |max(Gamma,Sigma)|\n");
   printf("      ---------    ------------------    ------------------");
   for( l = 0; l < n_gt_eps; l++)
   {
      printedIdx[nPrinted] = -1;
      if (0 <= index_Sigma[l] && index_Sigma[l] < q)
      {
         // Check if variable l referenced by Sigma has already been printed for Gamma
         unsigned alreadyPrinted = 0;
         for( unsigned nP = 0; nP < nPrinted && !alreadyPrinted; nP++)
            alreadyPrinted = index_Sigma[l] == printedIdx[nP];

         if (!alreadyPrinted)
         {
            // Print variable referenced l by Sigma, its init value and the value of Sigma_ll
            printf("\n      var_%d  %10s = %7.7g     %8.3f",
                   w_idx[index_Sigma[l]]+1,
                   data->modelData->realVarsData[var_id(w_idx[index_Sigma[l]], data, systemData)].info.name,
                   x0[w_idx[index_Sigma[l]]],
                   fabs(Sigma_ij[index_Sigma[l]][index_Sigma[l]]));
            printedIdx[nPrinted++] = index_Sigma[l];
         }
      }
      else if (0 <= index_Gamma_i[l] && index_Gamma_i[l] < p &&
               0 <= index_Gamma_j[l] && index_Gamma_j[l] < q &&
               0 <= index_Gamma_k[l] && index_Gamma_k[l] < q)
      {
         // Check if variable l referenced by Gamma has already been printed for Sigma
         unsigned alreadyPrinted_j = 0;
         unsigned alreadyPrinted_k = 0;
         for( unsigned nP = 0; nP < nPrinted; nP++)
         {
            alreadyPrinted_j = alreadyPrinted_j || index_Gamma_j[l] == printedIdx[nP];
            alreadyPrinted_k = alreadyPrinted_k || index_Gamma_k[l] == printedIdx[nP];
         }

         if  (!alreadyPrinted_j)
         {
            // Print variable referenced l by Gamma, its init value and the value of Gamma_ilk
            printf("\n      var_%d  %10s = %7.7g     %8.3f",
                   w_idx[index_Gamma_j[l]]+1,
                   data->modelData->realVarsData[var_id(w_idx[index_Gamma_j[l]], data, systemData)].info.name,
                   x0[w_idx[index_Gamma_j[l]]],
                   Gamma_ijk[index_Gamma_i[l]][index_Gamma_j[l]][index_Gamma_k[l]]);
            printedIdx[nPrinted++] = index_Gamma_j[l];
         }
         if  (!alreadyPrinted_k)
         {
            // Print variable referenced l by Gamma, its init value and the value of Gamma_ijl
            printf("\n      var_%d  %10s = %7.7g     %8.3f",
                   w_idx[index_Gamma_k[l]]+1,
                   data->modelData->realVarsData[var_id(w_idx[index_Gamma_k[l]], data, systemData)].info.name,
                   x0[w_idx[index_Gamma_k[l]]],
                   Gamma_ijk[index_Gamma_i[l]][index_Gamma_j[l]][index_Gamma_k[l]]);
            printedIdx[nPrinted++] = index_Gamma_k[l];
         }
      }
   }
   printf("\n\n");

   // Select values of alpha and Gamma > eps and store them in descending order
   // -------------------------------------------------------------------------

   n_gt_eps = 0;

   // Initialize tmp arrays for sorting
   for( i = 0; i < p; i++)
   {
      for( j = 0; j < q; j++)
         for( k = 0; k < q; k++)
            Gamma_checked[i][j][k] = 0;
      alpha_checked[i] = 0;
   }

   for( l = 0; l < p * q * q + m; l++)
   {
      // Select largest Gamma variable and its value
      val_largest_Gamma = -1.e10;
      idx_largest_G_i = 0;
      idx_largest_G_j = 0;
      idx_largest_G_k = 0;
      for( i = 0; i < p; i++)
         for( j = 0; j < q; j++)
            for( k = j; k < q; k++)
               if ( Gamma_ijk[i][j][k] > val_largest_Gamma && !Gamma_checked[i][j][k])
               {
                  val_largest_Gamma = Gamma_ijk[i][j][k];
                  idx_largest_G_i = i;
                  idx_largest_G_j = j;
                  idx_largest_G_k = k;
               }

      // Select largest alpha variable and its value
      val_largest_alpha = -1.e10;
      idx_largest_alpha = 0;
      for( i = 0; i < p; i++)
         if ( alpha[i] > val_largest_alpha && !alpha_checked[i])
         {
            val_largest_alpha = alpha[i];
            idx_largest_alpha = i;
         }

      // Values < 0 , i.e. less than eps, are not considered
      if (val_largest_Gamma < eps && val_largest_alpha < eps) break;

      // Checkmark and store indices of largest value
      if (val_largest_Gamma > val_largest_alpha)
      {
         index_Gamma_i[n_gt_eps] = idx_largest_G_i;
         index_Gamma_j[n_gt_eps] = idx_largest_G_j;
         index_Gamma_k[n_gt_eps] = idx_largest_G_k;
         index_alpha[n_gt_eps] = -1;
         Gamma_checked[idx_largest_G_i][idx_largest_G_j][idx_largest_G_k] = 1;

         // -------------------------------------------- Debug ----------------------------------------------
         //printf("\n      Gamma_%d_%d_%d =  %8.3f", n_idx[idx_largest_G_i]+1, w_idx[idx_largest_G_j]+1,
         //                                          w_idx[idx_largest_G_k]+1, val_largest_Gamma);
         // ---------------------------------------- end of Debug -------------------------------------------
      }
      else
      {
         index_alpha[n_gt_eps] = idx_largest_alpha;
         index_Gamma_i[n_gt_eps] = -1;
         index_Gamma_j[n_gt_eps] = -1;
         index_Gamma_k[n_gt_eps] = -1;
         alpha_checked[idx_largest_alpha] = 1;

         // -------------------------------------------- Debug ---------------------------------------------
         //printf("\n      alpha_%d     =  %8.3f", w_idx[idx_largest_alpha]+1, alpha[idx_largest_alpha]);
         // ---------------------------------------- end of Debug -------------------------------------------
      }

      // Increment number of values found
      n_gt_eps++;
   }
   //printf("\n\n");

   // Print equations referenced by alpha and Gamma values > eps and concerned alpha or Gamma value
   // ---------------------------------------------------------------------------------------------

   printedIdx = (unsigned*)realloc(printedIdx, n_gt_eps * sizeof(unsigned));
   nPrinted = 0;
   printf("      Equations    max(alpha,Gamma)\n");
   printf("      ---------    ------------------");
   for( l = 0; l < n_gt_eps; l++)
   {
      printedIdx[nPrinted] = -1;
      if (0 <= index_alpha[l] && index_alpha[l] < p)
      {
         // Check if equation l referenced by alpha has already been printed for Gamma
         unsigned alreadyPrinted = 0;
         for( unsigned nP = 0; nP < nPrinted && !alreadyPrinted; nP++)
            alreadyPrinted = index_alpha[l] == printedIdx[nP];

         if (!alreadyPrinted)
         {
            // Print equation l referenced by alpha and the value of alpha_i
            printf("\n      eqn_%d     %8.3f", n_idx[index_alpha[l]]+1, alpha[index_alpha[l]]);
            printedIdx[nPrinted++] = index_alpha[l];
         }
      }
      else if (0 <= index_Gamma_i[l] && index_Gamma_i[l] < p &&
               0 <= index_Gamma_j[l] && index_Gamma_j[l] < q &&
               0 <= index_Gamma_k[l] && index_Gamma_k[l] < q)
      {
         // Check if equation l referenced by Gamma has already been printed for alpha
         unsigned alreadyPrinted = 0;
         for( unsigned nP = 0; nP < nPrinted && !alreadyPrinted; nP++)
            alreadyPrinted = index_Gamma_i[l] == printedIdx[nP];

         if  (!alreadyPrinted)
         {
            // Print equation l referenced by Gamma and the value of Gamma_ljk
            printf("\n      eqn_%d     %8.3f", n_idx[index_Gamma_i[l]]+1,
                   Gamma_ijk[index_Gamma_i[l]][index_Gamma_j[l]][index_Gamma_k[l]]);
            printedIdx[nPrinted++] = index_Gamma_i[l];
         }
      }
   }
   printf("\n\n");

   printf("   ========================================================\n\n\n");

   free(printedIdx);
   free(alpha_checked);
   free(Sigma_checked);
   for( i = 0; i < p; i++)
   {
      for( j = 0; j < q; j++)
         free(Gamma_checked[i][j]);
      free(Gamma_checked[i]);
   }
   free(Gamma_checked);
   free(index_alpha);
   free(index_Sigma);
   free(index_Gamma_i);
   free(index_Gamma_j);
   free(index_Gamma_k);
}

// --------------------------------------------------------------------------------------------------------------------------------

unsigned* getNonlinearEqns( DATA* data, threadData_t* threadData, unsigned sysNumber,
                            unsigned m, double* x0, double* dx, unsigned* p)
{
   // If |f^i(x1)| > 0, then f^i is a nonlinear function

   RESIDUAL_USERDATA resUserData = {.data=data, .threadData=threadData, .solverData=NULL};
   NONLINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo->nonlinearSystemData[sysNumber]);

   unsigned i;
   double eps = 1.e-9;

   // Calculate x1 from NewtonFirstStep data dx
   double* x1 = (double*)malloc(m * sizeof(double));
   for( i = 0; i < m; ++i)
      x1[i] = x0[i] + dx[i];

   // Calculate residuals f_x1 for x1
   double* f_x1 = (double*)malloc(m * sizeof(double));
   (systemData->residualFunc)(&resUserData, x1, f_x1, (int*)&systemData->size);

   // Count number of nonlinear functions, i.e. all functions satifying: |f(x1)| > eps
   *p = 0;
   for( i = 0; i < m; ++i)
      if ( fabs(f_x1[i]) > eps)
         (*p)++;

   // Get indices of nonlinear functions of f^i
   unsigned* n_idx = NULL;
   if (*p > 0)
   {
      n_idx = (unsigned*)malloc(*p * sizeof(unsigned));
      unsigned n = 0;
      for( i = 0; i < m; ++i)
         if ( fabs(f_x1[i]) > eps)
            n_idx[n++] = i;
   }

   // Free allocated memory
   free(x1);
   free(f_x1);

   return n_idx;
}

unsigned* getNonlinearVars( unsigned m, double*** fxx, unsigned* q)
{
   // If at least one value in the entire column j of f_xx[k][i][j] > eps, then x[j] is a nonlinear variable

   unsigned i, j, k;
   double eps = 1.e-9;

   // Allocate memory for indicator of value of column j != 0
   unsigned* aValueOfColumn_gt_0 = (unsigned*)malloc(m * sizeof(unsigned));

   // Initialize indicator of value of column j != 0
   for( j = 0; j < m; j++)
      aValueOfColumn_gt_0[j] = 0;

   // Retrieve indicator of value of column j != 0
   for( k = 0; k < m; k++)
      for( i = 0; i < m; i++)
         for( j = 0; j < m; j++)
            if ( fabs(fxx[k][i][j]) > eps)
               aValueOfColumn_gt_0[j] = 1;

   // Count number of columns where a value > 0 <==> number of nonlinear variables
   *q = 0;
   for( j = 0; j < m; j++)
      *q += aValueOfColumn_gt_0[j];

   // Get indices of nonlinear variables of x[j]
   unsigned *w_idx = NULL;
   if (*q > 0)
   {
      w_idx = (unsigned*)malloc(*q * sizeof(unsigned));
      unsigned n = 0;
      for( j = 0; j < m; j++)
         if ( aValueOfColumn_gt_0[j] == 1)
            w_idx[n++] = j;
   }

   free(aValueOfColumn_gt_0);

   return w_idx;
}

unsigned* getLinearVars( unsigned m, unsigned q, unsigned *w_idx )
{
   // Linear dependables "z": store the remaining ones (those not being in w_idx) in z_idx

   unsigned i, j, k, i_in_w;
   unsigned* z_idx = NULL;

   if (m > q)
   {
      z_idx = (unsigned*)malloc((m - q) * sizeof(unsigned));
      j = 0;
      for( i = 0; i < m; i++)
      {
         i_in_w = 0;
         for(  k = 0; k < q; k++)
         {
            if (w_idx[k] == i)
            {
               i_in_w = 1;
               break;
            }
         }
         if (!i_in_w)
         {
            z_idx[j] = i;
            j++;
         }
      }
   }
   return z_idx;
}

// --------------------------------------------------------------------------------------------------------------------------------

void newtonDiagnostics(DATA* data, threadData_t *threadData, int sysNumber)
{
   infoStreamPrint(LOG_NLS_NEWTON_DIAG, 0, "Newton diagnostics (version Teus 17-02-2023) starting ....");

   printf("\n   ****** Model name: %s\n", data->modelData->modelName);
   printf("   ****** Initial                         : %d\n" , data->simulationInfo->initial);

   printf("   ****** Number of integer parameters    : %ld\n", data->modelData->nParametersInteger);
   for( unsigned int i = 0; i < data->modelData->nParametersInteger; ++i)
      printf("   ****** %2d: id=%d, name=%10s, value=%10ld\n", i+1, (data->modelData->integerParameterData[i].info.id),
                                                                    (data->modelData->integerParameterData[i].info.name),
                                                                    (data->modelData->integerParameterData[i].attribute.start));

   printf("   ****** Number of discrete real params  : %ld\n", data->modelData->nDiscreteReal);
   printf("   ****** Number of real parameters       : %ld\n", data->modelData->nParametersReal);
   for( unsigned int i = 0; i < data->modelData->nParametersReal; ++i)
      printf("   ****** %2d: id=%d, name=%10s, value=%10f\n", i+1, (data->modelData->realParameterData[i].info.id),
                                                                   (data->modelData->realParameterData[i].info.name),
                                                                   (data->modelData->realParameterData[i].attribute.start));

   printf("   ****** Number of integer variables     : %ld\n", data->modelData->nVariablesInteger);
   for( unsigned int i = 0; i < data->modelData->nVariablesInteger; ++i)
      printf("   ****** %2d: id=%d, name=%10s, value=%10ld\n", i+1, (data->modelData->integerVarsData[i].info.id),
                                                                    (data->modelData->integerVarsData[i].info.name),
                                                                    (data->modelData->integerVarsData[i].attribute.start));

   printf("   ****** Number of real variables        : %ld\n", data->modelData->nVariablesReal);
   for( unsigned int i = 0; i < data->modelData->nVariablesReal; ++i)
      printf("   ****** %2d: id=%d, name=%10s, value=%10f\n", i+1, (data->modelData->realVarsData[i].info.id),
                                                                   (data->modelData->realVarsData[i].info.name),
                                                                   (data->modelData->realVarsData[i].attribute.start));

 // --------------------------------------------------------------------------------------------------------------------------------

   // m: total number of equations f(x)
   // p: number of non-linear equations n(x)
   // q: number of variables on which non-linear equations n(x) just depend

   NONLINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo->nonlinearSystemData[sysNumber]);
   unsigned m = systemData->size;
   unsigned i, j, k, p, q;

   // Store all dependents in "x0" and function values as function of x0 in f
   double* x0 = (double*)malloc(m * sizeof(double));
   double* f  = (double*)malloc(m * sizeof(double));
   for( i = 0; i < m; i++)
   {
      x0[i] = systemData->nlsx[i];
      f[i]  = systemData->resValues[i];
   }

   // Get Jacobian fx from system data
   double** fx = getJacobian( data, threadData, sysNumber, m);

   // Obtain Newton steps dx = -f(x0)/fx(x0)
   double* dx = getFirstNewtonStep( m, f, fx);

   // Get Hessian fxx from numerical differentiation of fx
   double*** fxx = getHessian( data, threadData, sysNumber, m);

   // Obtain function values of non-linear functions "n", i.e. residuals as function of w0
   unsigned* n_idx = getNonlinearEqns(data, threadData, sysNumber, m, x0, dx, &p);

   // Obtain vector "w0": initial guesses of vars where Jacobian matrix J(w) of f(x) only depends on
   unsigned* w_idx = getNonlinearVars( m, fxx, &q);

   // Obtain vector "z": linear dependents
   unsigned* z_idx = getLinearVars( m, q, w_idx);

// --------------------------------------------------------------------------------------------------------------------------------

   printf("\n   Information about equations from non-linear pattern ....\n\n");
   printf("               Total number of equations    = %d\n", systemData->nonlinearPattern->numberOfEqns);
   printf("               Number of independents       = %d\n", systemData->nonlinearPattern->numberOfVars);
   printf("               Number of non-linear entries = %d\n", systemData->nonlinearPattern->numberOfNonlinear);

   // Prints values of vector x0
   printf("\n   Vector x0: all dependents ....\n");
   for( i = 0; i < m; i++)
      printf("\n               x0[%d] = %14.10f  (%s)", i, x0[i], data->modelData->realVarsData[var_id(i, data, systemData)].info.name);
   printf("\n");

   // Prints function values "f", i.e. residuals as function of x0
   printf("\n   Function values of all equations f(x0) ....\n");
   for( i = 0; i < m; i++)
      if (fabs(f[i]) > 1.e-9)
      printf("\n               f^%d = %14.10f", i+1, f[i]);
   printf("\n");

   // Prints vector n
   printf("\n   Function values of non-linear equations n(w0) ....\n");
   for( i = 0; i < p; ++i)
      printf("\n               n^%d = f^%d = %14.10f", i+1, n_idx[i]+1, f[n_idx[i]]);
   printf("\n");

   // Prints vector w0
   printf("\n   Vector w0: non-linear dependents .... \n");
   for( i = 0; i < q; i++)
      printf("\n               w0[%d] = x0[%d] = %14.10f  (%s)", i, w_idx[i], x0[w_idx[i]],
              data->modelData->realVarsData[var_id(w_idx[i], data, systemData)].info.name);
   printf("\n");

   // Prints vector z0
   if (m != q)
   {
      printf("\n   Vector z0: linear dependents .... %d\n", m-q);
      for( i = 0; i < m-q; i++)
         printf("\n               z0[%d] = %14.10f  (%s)", i, x0[z_idx[i]],
                 data->modelData->realVarsData[var_id(z_idx[i], data, systemData)].info.name);
      printf("\n");
   }

   double lambda = 1.0; // 0.49; //
   printf("\n   Damping factor lambda = %6.3g\n", lambda);

   printf("\n\n");

// --------------------------------------------------------------------------------------------------------------------------------

   double maxRes = maxNonLinearResiduals( m, m - p, z_idx, f, fx, dx);

   double* alpha = calcAlpha( data, threadData, sysNumber, m, p, q, n_idx, w_idx, x0, dx, f, fxx, lambda, maxRes);

   double*** Gamma_ijk = calcGamma( m, p, q, n_idx, w_idx, dx, fxx, maxRes);

   double** Sigma = calcSigma( m, q, w_idx, dx, fx, fxx);

   PrintResults( data, sysNumber, m, p, q, n_idx, w_idx, x0, alpha, Gamma_ijk, Sigma);

// --------------------------------------------------------------------------------------------------------------------------------

   // Free dynamically allocated memory
   free(x0);
   free(f);
   free(dx);

   for( i = 0; i < m; i++)
      free(fx[i]);
   free(fx);

   for( i = 0; i < m; i++)
   {
      for( j = 0; j < m; j++)
         free(fxx[i][j]);
      free(fxx[i]);
   }
   free(fxx);

   free(n_idx);
   free(w_idx);
   free(z_idx);

   free(alpha);

   for( i = 0; i < p; i++)
   {
      for( j = 0; j < q; j++)
          free(Gamma_ijk[i][j]);
      free(Gamma_ijk[i]);
   }
   free(Gamma_ijk);

   for( i = 0; i < q; i++)
      free(Sigma[i]);
   free(Sigma);

   infoStreamPrint(LOG_NLS_NEWTON_DIAG, 0, "Newton diagnostics (version Teus 17-02-2023) finished!!");

   return;
}

// --------------------------------------------------------------------------------------------------------------------------------

