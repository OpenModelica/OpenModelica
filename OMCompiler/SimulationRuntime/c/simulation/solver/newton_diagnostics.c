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
 * Carried out on behalf of the Delft University of Technology, autumn 2021
 *
 * @param data          Pointer to all simulation data.
 * @param threadData    Pointer to thread data for error handling mainly.
 */

#include "newton_diagnostics.h"
#include "../simulation_info_json.h"
#include "../../util/jacobian_util.h"

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

void MatMult( unsigned rA, unsigned cArB, unsigned cB, double A[rA][cArB], double B[cArB][cB], double C[rA][cB])
{
   // Matrix multiplication A[rA][cArB] * B[cArB][cB] = C[rA][cB]

   for( unsigned i = 0; i < rA; i++)
   {
      for( unsigned j = 0; j < cB; j++)
      {
         C[i][j] = 0;
         for( unsigned k = 0; k < cArB; k++)
            C[i][j] += A[i][k] * B[k][j];
      }
   }
}

// --------------------------------------------------------------------------------------------------------------------------------

void getJacobian( DATA* data, threadData_t *threadData, unsigned sysNumber, unsigned m, double fx[m][m])
{
   NONLINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo->nonlinearSystemData[sysNumber]);
   ANALYTIC_JACOBIAN* jac = &(data->simulationInfo->analyticJacobians[systemData->jacobianIndex]);

   unsigned i, j;

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
}

// --------------------------------------------------------------------------------------------------------------------------------

void getFirstNewtonStep( unsigned m, double f[m], double fx[m][m], double dx[m])
{
   // Function values iteration 0: vector f(x0)
   // Values Jacobian iteration 0: vector fx(x0)
   // Newton step: dx = -f(x0)/fx(x0)

   // Variables for Lapack routines
   int N = m;                           // number of rows and columns of Jacobian
   int NRHS = 1;                        // number of columns of b, i.e. f(x)
   int LDA = N;
   int LDB = N;
   int ipiv[N];
   int info;

   double a[LDA*N];
   double b[LDB*NRHS];

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
      printf( "The solution could not be computed, as the first Newton step could not be compunted; the info satus is : %d\n", info);
   else
   {
      // Store Newton steps in dx
      for( j = 0; j < m; j++)
         dx[j] = -b[j];
   }
}

// --------------------------------------------------------------------------------------------------------------------------------

double maxNonLinearResiduals( unsigned m, unsigned l, unsigned z_idx[l],
                              double f[m], double fx[m][m], double dx[m])
{
   // Calculate the absolute maximum value of the non-linear residuals r_x0 = f_x0 + fz * (z1 - z0)
   // at iteration point x0, where z1 - z0 = dx and fz = J for the linear values and equations.

   // l = m - p: number of linear dependables or equations
   // z_idx    : index of linear dependable in f, fx, dx

   double r_x0[m], fz_dz;
   double maxRes = 1.e-88;
   unsigned i, j;

   for( i = 0; i < m; i++)
   {
      fz_dz = 0;
      for( j = 1; j < l; j++)  // iteration point x0 ==> j = 1 as r_x(j-1) = f_x(j-1) + fz * (z(j) - z(j-1)) = f_x(j-1) + fz * dz(j-1)
         fz_dz += fx[i][z_idx[j]] * dx[z_idx[j]];

      r_x0[i] = fabs(f[i] + fz_dz);
      if (r_x0[i] > maxRes)
         maxRes = r_x0[i];
   }

   return maxRes;
}

// --------------------------------------------------------------------------------------------------------------------------------

void getHessian( DATA* data, threadData_t *threadData, unsigned sysNumber, unsigned m, double fxx[m][m][m])
{
   NONLINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo->nonlinearSystemData[sysNumber]);
   ANALYTIC_JACOBIAN* jac = &(data->simulationInfo->analyticJacobians[systemData->jacobianIndex]);

   unsigned i, j, k;
   const modelica_real eps = 1.e-6;
   SIMULATION_DATA *sData = data->localData[0];

   double fxPls[m][m];
   double fxMin[m][m];

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
      const modelica_real delta_x = tmp_x * eps;

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
            fxx[i][k][j] = (fxPls[i][j] - fxMin[i][j]) / (2 * delta_x);
   }

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

}

// --------------------------------------------------------------------------------------------------------------------------------

void calcGamma( unsigned m, unsigned p, unsigned q, unsigned n_idx[p], unsigned w_idx[q],
                double dx[m], double fxx[m][m][m], double maxRes, double Gamma_ijk[p][q][q])
{
   // Calculation of curvature factors Gamma_ijk
   // ------------------------------------------
   //
   // m     : total number of equations/independents
   // p     : number of non-linear equations
   // q     : number of non-linear independents
   // n_idx : index of non-linear equation, ie of i in fxx[i][j][k]
   // w_idx : index of non-linear dependent, ie of j in dx[j] and of j and k in fxx[i][j][k]
   // dx    : Newton step first iteration = x1 - x0, and dx[w_idx] = w1 - w0
   // fxx   : Hessian as function of x0

   unsigned i, j, k;

   for( i = 0; i < p; i++)
      for( j = 0; j < q; j++)
         for( k = 0; k < q; k++)
            Gamma_ijk[i][j][k] = fabs(0.5 * fxx[n_idx[i]][w_idx[j]][w_idx[k]] * (dx[w_idx[j]] * dx[w_idx[k]]) / maxRes);
}


// --------------------------------------------------------------------------------------------------------------------------------

void calcAlpha( DATA* data, threadData_t* threadData, unsigned sysNumber, unsigned m, unsigned p,
                unsigned q, unsigned n_idx[p], unsigned w_idx[p], double x[m], double dx[m],
                double f[m], double fxx[m][m][m], double lambda, double maxRes, double alpha[p])
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

   //void *dataAndThreadData[2] = {data, threadData};
   RESIDUAL_USERDATA resUserData = {.data=data, .threadData=threadData, .solverData=NULL};
   NONLINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo->nonlinearSystemData[sysNumber]);

   unsigned i, j, k;

   // Get damped guess x1_star for second iteration step
   double x1_star[m];
   for( j = 0; j < m; j++)
      x1_star[j] = x[j] + lambda * dx[j];

   // Calculate residuals f_x1_star for damped guess x1_star
   double f_x1_star[m];
   (systemData->residualFunc)(&resUserData, x1_star, f_x1_star, (int*)&systemData->size);

   // For each non-linear independent get w1_star - w0
   double w1_star_w0[q];
   for( j = 0; j < q; j++)
      w1_star_w0[j] = lambda * dx[w_idx[j]];

   // Calculate alpha for each non-linear equation i
   for( i = 0; i < p; ++i)
   {
      // Vector w_times_fww_w0 = (w1_star - w0)' * fww_w0  (1 x q * q x q --> 1 x q vector)
      double w_times_fww_w0[q];
      for( j = 0; j < q; j++)
      {
         // For each independent
         w_times_fww_w0[j] = 0;
         for( k = 0; k < q; k++)
            w_times_fww_w0[j] += w1_star_w0[k] * fxx[n_idx[i]][w_idx[k]][w_idx[j]];
      }

      // Scalar w_times_f_times_w = w_times_f_i_ww_w0 * (w1_star - w0) = (w1_star - w0)' * f_i_ww_w0 * (w1_star - w0)
      // (1 x q * q x 1 vector --> scalar)
      double w_times_fww_times_w = 0;
      for( k = 0; k < q; k++)
         w_times_fww_times_w += w_times_fww_w0[k] * w1_star_w0[k];

      // Calculate alpha for the non-linear equations
      alpha[i] = fabs(f_x1_star[n_idx[i]] - (1 - lambda) * f[n_idx[i]] - 0.5 * w_times_fww_times_w) / (pow(lambda,3) * maxRes);
   }
}

// --------------------------------------------------------------------------------------------------------------------------------

void getInvJacobian( unsigned m, double fx[m][m], double inv_fx[m][m])
{
   // Calculates inverse matrix of Jacobian fx as function of x0 (m x m matrix)
   // -------------------------------------------------------------------------
   //
   // m     : total number of equations/independents
   // fx    : Jacobian as function of x0

   unsigned i, j;

   // Intialize inverse fx with fx(w0)
   for( i = 0; i < m; i++)
      for( j = 0; j < m; j++)
         inv_fx[i][j] = fx[i][j];

   // Variables for Lapack routines
   int N = m;
   int LWORK = N;
   int ipiv[N];
   int info;
   double *WORK = (double*) calloc(LWORK, sizeof(double));

   // Call Lapack functions dgetrf and dgetri
   dgetrf_(&N, &N, &inv_fx[0][0], &N, ipiv, &info);
   dgetri_(&N, &inv_fx[0][0], &N, ipiv, WORK, &LWORK, &info);

   // Lapack function dgesv could also do the job
   // int NRHS = N;
   // int LDA  = N;
   // int LDB  = N;
   // dgesv_(&N, &NRHS, &fx[0][0], &LDA, ipiv, &inv_fx[0][0], &LDB, &info);

   if (info > 0)
      printf( "The solution could not be computed, as the inverse Jacobian could not be computed; the info satus is : %d\n", info);
}

// --------------------------------------------------------------------------------------------------------------------------------

void calcSigma( unsigned m, unsigned q, unsigned w_idx[q], double dx[m],
                double fx[m][m], double fxx[m][m][m], double Sigma[q][q])
{
   // Calculation of solution sensitivities Sigma_ij
   // ----------------------------------------------
   //
   // m     : total number of equations/independents
   // q     : number of non-linear variables
   // w_idx : index of non-linear dependent, ie of j in dx[j] and of j and k in fxx[i][j][k]
   // dx    : Newton step first iteration = x1 - x0, and dx[w_idx] = w1 - w0
   // fx    : Jacobian as function of x0
   // fxx   : Hessian as function of x0

   unsigned i, j, k;

   // Calculate inverse Jacobian, ie inverse matrix of fx
   double inv_fx[m][m];
   getInvJacobian( m, fx, inv_fx);

   // Get matrix H[i] = (x1 - x0)' * fxx = dx' * fxx (1 x m * m x m matrix --> m vector)
   double H_i[m][m]; // m functions * m vectors --> m x m matrix
   for( i = 0; i < m; i++)
      for( j = 0; j < m; j++)
      {
         H_i[i][j] = 0;
         for( k = 0; k < m; k++)
            H_i[i][j] += dx[k] * fxx[i][k][j];
      }

   // Calculate tmp1 = -inv_fx * H_i
   // (m x m matrix) *  (m x m matrix) --> m x m matrix
   double tmp1[m][m];
   for( i = 0; i < m; i++)
      for( j = 0; j < m; j++)
         inv_fx[i][j] = -inv_fx[i][j];
   MatMult( m, m, m, inv_fx, H_i, tmp1);

   // Abstract matrix tmp2 from tmp1 for only non-linear (q x q matrix)
   double tmp2[q][q];
   for( i = 0; i < q; i++)
      for( j = 0; j < q; j++)
         tmp2[i][j] = tmp1[w_idx[i]][w_idx[j]];

   // Create a q x q matrix wDiag with w1 - w0 = dx[w_idx] on diagonal
   double wDiag[q][q];
   for( i = 0; i < q; i++)
      for( j = 0; j < q; j++)
         if (i == j)
            wDiag[i][j] = dx[w_idx[i]];
         else
            wDiag[i][j] = 0;

   // Get inverse matrix inv_wDiag of wDiag
   double inv_wDiag[q][q];
   getInvJacobian( q, wDiag, inv_wDiag);

   // Calculate tmp3 = | inv_wDiag | * tmp2
   // (q x q matrix) *  (q x q matrix) --> q x q matrix
   double tmp3[q][q];
   for( i = 0; i < q; i++)
      for( j = 0; j < q; j++)
         inv_wDiag[i][j] = fabs(inv_wDiag[i][j]);
   MatMult( q, q, q, inv_wDiag, tmp2, tmp3);

   // Calculate Sigma = tmp3 * wDiag =  | inv_wDiag | * tmp2 * wDiag = | inv_wDiag | * -inv_fx * H_i * wDiag
   MatMult( q, q, q, tmp3, wDiag, Sigma);
}

// --------------------------------------------------------------------------------------------------------------------------------

void PrintResults( DATA* data, unsigned sysNumber, unsigned m, unsigned p, unsigned q, unsigned n_idx[p], unsigned w_idx[q],
                   double x0[m], double alpha[p], double Gamma_ijk[p][q][q], double Sigma_ij[q][q])
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

   unsigned idx_largest_alpha, idx_largest_Sigma,
            idx_largest_G_i, idx_largest_G_j, idx_largest_G_k,
            alpha_checked[p], Sigma_checked[q], Gamma_checked[p][q][q],
            index_alpha[p * q * q + m], index_Sigma[p * q * q + m],
            index_Gamma_i[p * q * q + m], index_Gamma_j[p * q * q + m], index_Gamma_k[p * q * q + m];

   unsigned l, n_gt_eps = 0;

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
      val_largest_Gamma = Gamma_ijk[0][0][0];
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
      val_largest_Sigma = fabs(Sigma_ij[0][0]);
      idx_largest_Sigma = 0;
      for( i = 1; i < p; i++)
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
         //printf("\n      Sigma_%d_%d    =  %8.3f", w_idx[idx_largest_Sigma]+1, w_idx[idx_largest_Sigma]+1,
         //                                          fabs(Sigma_ij[idx_largest_Sigma][idx_largest_Sigma]));
         // ---------------------------------------- end of Debug -------------------------------------------
      }

      // Increment number of values found
      n_gt_eps++;
   }
   //printf("\n\n");

   // Print variables referenced by Sigma and Gamma values > eps and concerned Sigma or Gamma value
   // ---------------------------------------------------------------------------------------------

   unsigned printedIdx[2*n_gt_eps];
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
      val_largest_Gamma = Gamma_ijk[0][0][0];
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
      val_largest_alpha = alpha[0];
      idx_largest_alpha = 0;
      for( i = 1; i < p; i++)
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

   unsigned printedIdx2[n_gt_eps];
   nPrinted = 0;
   printf("      Equations    max(alpha,Gamma)\n");
   printf("      ---------    ------------------");
   for( l = 0; l < n_gt_eps; l++)
   {
      printedIdx2[nPrinted] = -1;
      if (0 <= index_alpha[l] && index_alpha[l] < p)
      {
         // Check if equation l referenced by alpha has already been printed for Gamma
         unsigned alreadyPrinted = 0;
         for( unsigned nP = 0; nP < nPrinted && !alreadyPrinted; nP++)
            alreadyPrinted = index_alpha[l] == printedIdx2[nP];

         if (!alreadyPrinted)
         {
            // Print equation l referenced by alpha and the value of alpha_i
            printf("\n      eqn_%d     %8.3f", n_idx[index_alpha[l]]+1, alpha[index_alpha[l]]);
            printedIdx2[nPrinted++] = index_alpha[l];
         }
      }
      else if (0 <= index_Gamma_i[l] && index_Gamma_i[l] < p &&
               0 <= index_Gamma_j[l] && index_Gamma_j[l] < q &&
               0 <= index_Gamma_k[l] && index_Gamma_k[l] < q)
      {
         // Check if equation l referenced by Gamma has already been printed for alpha
         unsigned alreadyPrinted = 0;
         for( unsigned nP = 0; nP < nPrinted && !alreadyPrinted; nP++)
            alreadyPrinted = index_Gamma_i[l] == printedIdx2[nP];

         if  (!alreadyPrinted)
         {
            // Print equation l referenced by Gamma and the value of Gamma_ljk
            printf("\n      eqn_%d     %8.3f", n_idx[index_Gamma_i[l]]+1,
                   Gamma_ijk[index_Gamma_i[l]][index_Gamma_j[l]][index_Gamma_k[l]]);
            printedIdx2[nPrinted++] = index_Gamma_i[l];
         }
      }
   }
   printf("\n\n");

   printf("   ========================================================\n\n\n");
}

// --------------------------------------------------------------------------------------------------------------------------------

void newtonDiagnostics(DATA* data, threadData_t *threadData, int sysNumber)
{
   infoStreamPrint(LOG_NLS_NEWTON_DIAG, 0, "Hello newton diagnostics (version Teus 22-12-2022)....");

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
   unsigned i;

   // Obtain vector w0: initial guesses of vars where Jacobian matrix J(w) of f(x) only depends on
   // For the moment all vars are considered to be non-linear, i.e. w = x, therefore w_idx[i] = i;
   unsigned p = m;
   unsigned q = m;
   double w0[q];
   unsigned w_idx[q];
   for( i = 0; i < q; i++)
      w_idx[i] = i;

   // Obtain function values of non-linear functions "n", i.e. residuals as function of w0
   // For the moment all functions are considered to be non-linear, i.e. n = f, therefore n_idx[i] = i;
   double n[p];
   unsigned n_idx[p];
   for( i = 0; i < p; i++)
      n_idx[i] = i;

// --------------------------------------------------------------------------------------------------------------------------------

   // Linear dependables "z": store the remaining ones (those not being in w_idx) in z_idx
   double* z;
   unsigned* z_idx;
   if (m > q)
   {
      z = (double*)malloc(m-q);
      z_idx = (unsigned*)malloc(m-q);
      unsigned j = 0;
      for( i = 0; i < m; i++)
      {
         unsigned i_in_w = 0;
         for( unsigned k = 0; k < q; k++)
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

// --------------------------------------------------------------------------------------------------------------------------------

   double x0[m], f[m];

   // Store all dependents in x0 and function values as function of x0 in f
   for( i = 0; i < m; i++)
   {
      x0[i] = systemData->nlsx[i];
      f[i]  = systemData->resValues[i];
   }

   // Store non-linear dependents in w0
   for( i = 0; i < q; i++)
      w0[i] = x0[w_idx[i]];

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

   // Prints vector w0
   printf("\n   Vector w0: non-linear dependents ....\n");
   for( i = 0; i < q; i++)
      printf("\n               w0[%d] = %14.10f  (%s)", i, w0[i], data->modelData->realVarsData[var_id(w_idx[i], data, systemData)].info.name);
   printf("\n");

   // Prints vector z0
   if (m != q)
   {
      printf("\n   Vector z0: linear dependents ....\n");
      for( i = 0; i < m-q; i++)
         printf("\n               z0[%d] = %14.10f  (%s)", i, x0[z_idx[i]], data->modelData->realVarsData[var_id(z_idx[i], data, systemData)].info.name);
      printf("\n");
   }

   // Prints function values "f", i.e. residuals as function of x0
   printf("\n   Function values of all equations f(x0) ....\n");
   for( i = 0; i < m; i++)
      printf("\n               f^%d = %14.10f", i+1, f[i]);
   printf("\n");

   // Prints function values "n" of non-linear equations, i.e. residuals as function of w0
   printf("\n   Function values of non-linear equations n(w0) ....\n");
   for( i = 0; i < p; i++)
      printf("\n               n^%d = %14.10f", i+1, f[n_idx[i]]);
   printf("\n");

   double lambda = 1.0; // 0.49; //
   printf("\n   Damping factor lambda = %6.3g\n", lambda);

// --------------------------------------------------------------------------------------------------------------------------------

   double fx[m][m];
   getJacobian( data, threadData, sysNumber, m, fx);

   //double dx[m];
   double dx[m];
   getFirstNewtonStep( m, f, fx, dx);

   double maxRes = maxNonLinearResiduals( m, m - p, z_idx, f, fx, dx);

   double fxx[m][m][m];
   getHessian( data, threadData, sysNumber, m, fxx);

// --------------------------------------------------------------------------------------------------------------------------------

   double alpha[p];
   calcAlpha( data, threadData, sysNumber, m, p, q, n_idx, w_idx, x0, dx, f, fxx, lambda, maxRes, alpha);

   double Gamma_ijk[p][q][q];
   calcGamma( m, p, q, n_idx, w_idx, dx, fxx, maxRes, Gamma_ijk);

   double Sigma[q][q];
   calcSigma( m, q, w_idx, dx, fx, fxx, Sigma);

   PrintResults( data, sysNumber, m, p, q, n_idx, w_idx, x0, alpha, Gamma_ijk, Sigma);

   infoStreamPrint(LOG_NLS_NEWTON_DIAG, 0, "Newton diagnostics (version Teus 22-12-2022) finished!!");

   return;
}

