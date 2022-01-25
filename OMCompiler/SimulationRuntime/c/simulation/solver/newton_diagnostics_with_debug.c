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

extern int dgesv_(int *n, int *nrhs, double *a, int *lda,
                  int *ipiv, double *b, int *ldb, int *info);

extern int dgetrf_(int *n, int *nrhs, double *a, int *lda,
                   int *ipiv, int *info);

extern int dgetri_(int *n, double *a, int *lda,
                   int *ipiv, double *work, int *lwork, int *info);

/*unsigned var_id( idx)
{
   // DC circuit case

   //  1: id=1000, name=     $cse2, value=1301631377994.751953
   //  2: id=1001, name=         i, value=  0.900000
   //  3: id=1002, name=         v, value=  9.630000
   //  4: id=1003, name=     v_[1], value=  0.900000
   //  5: id=1004, name=     v_[2], value=  0.900000
   //  6: id=1005, name=     v_[3], value=  0.900000
   //  7: id=1006, name=     v_[4], value=  0.900000
   //  8: id=1007, name=     v_[5], value=  0.900000
   //  9: id=1008, name=     v_[6], value=  0.900000
   // 10: id=1009, name=     v_[7], value=  0.900000
   // 11: id=1010, name=     v_[8], value=  0.900000
   // 12: id=1011, name=     v_[9], value=  0.900000
   // 13: id=1012, name=    v_[10], value=  0.900000
   // 14: id=1013, name=       v_d, value=  0.630000

   // 0 1 2 3 4 5 6 7 8 9 10 11 12 13
   // 0 4 2 1 5 6 7 8 9 10 11 12 3 13

   unsigned id;
   if (idx == 0)
      id = 3;
   else if (idx == 1)
      id = 4;
   else if (idx == 2)
      id = 1;
   else if (idx == 3)
      id = 13;
   else if (idx == 4)
      id = 2;
   else
      id = idx;
   return id;
}*/

unsigned var_id( idx)
{
   // Thermo-hydraulic case

   // idx = 0 --> id = 2: gamma
   // idx = 1 --> id = 0:   T_o
   // idx = 2 --> id = 1:     f
   // idx = 3 --> id = 4:   p_i
   // idx = 4 --> id = 5:   p_o
   // idx = 5 --> id = 3:   k_v

   unsigned id;
   if (idx == 0)
      id = 2;
   else if (idx == 1)
      id = 0;
   else if (idx == 2)
      id = 1;
   else if (idx == 3)
      id = 4;
   else if (idx == 4)
      id = 5;
   else if (idx == 5)
      id = 3;
   return id;
}

// --------------------------------------------------------------------------------------------------------------------------------

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

void getFirstNewtonStep( unsigned m, double f[m], double fx[m][m], double dx[m], int info)
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

   double a[N][N];
   double b[NRHS][N];

   unsigned i, j;

   // Store Jacobian values J(x0) in a
   for( i = 0; i < m; i++)
      for( j = 0; j < m; j++)
         a[i][j] = fx[j][i];

   // Store function values f(x0) in b
   for( i = 0; i < m; i++)
      b[0][i] = f[i];

   // Call Lapack function dgesv; after return b contains the Newton steps
   dgesv_(&N, &NRHS, &a[0][0], &LDA, ipiv, &b[0][0], &LDB, &info);

   if (info > 0)
      printf( "The solution could not be computed, as the first Newton step could not be compunted; the info satus is : %d\n", info);
   else
   {
      // Store Newton steps in dx
      for( j = 0; j < m; j++)
         dx[j] = -b[0][j];
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
      for( j = 0; j < l; j++)
         fz_dz += fx[i][z_idx[j]] * dx[z_idx[j]];

      r_x0[i] = fabs(f[i] + fz_dz);
      if (r_x0[i] > maxRes)
         maxRes = r_x0[i];
   }

   // Prints values of vector r_x0
   /*printf("\n   Vector r_x0 ....\n");
   for( i = 0; i < m; i++)
      printf("\n               r_x0[%d] = %14.10f", i+1, r_x0[i]);
   printf("\n\n");*/

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

   for( k = 0; k < m; k++)
   {
      unsigned id = var_id(k);

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
}

// --------------------------------------------------------------------------------------------------------------------------------

void calcGamma( unsigned m, unsigned p, unsigned w_idx[p], unsigned n_idx[p], double dx[m],
                double fxx[m][m][m], double maxRes, double Gamma_ijk[p][p][p])
{
   // Calculation of curvature factors Gamma_ijk
   // ------------------------------------------
   //
   // m     : total number of equations/independents
   // p     : number of non-linear equations/independents
   // w_idx : index of non-linear dependent, ie of j in dx[j] and of j and k in fxx[i][j][k]
   // n_idx : index of non-linear equation, ie of i in fxx[i][j][k]
   // dx    : Newton step first iteration = x1 - x0, and dx[w_idx] = w1 - w0
   // fxx   : Hessian as function of x0

   unsigned i, j, k;

   for( i = 0; i < p; i++)
      for( j = 0; j < p; j++)
         for( k = 0; k < p; k++)
            Gamma_ijk[i][j][k] = fabs(0.5 * fxx[n_idx[i]][w_idx[j]][w_idx[k]] * (dx[w_idx[j]] * dx[w_idx[k]]) / maxRes);
}


// --------------------------------------------------------------------------------------------------------------------------------

void calcAlpha( DATA* data, threadData_t* threadData, unsigned sysNumber, unsigned m, unsigned p,
                unsigned w_idx[p], unsigned n_idx[p], double x[m], double dx[m], double f[m],
                double fxx[m][m][m], double lambda, double maxRes, double alpha[p])
{
   // Calculation of alpha coefficients for all non-linear equations
   // --------------------------------------------------------------
   //
   // m     : total number of equations/independents
   // p     : number of non-linear equations/independents
   // w_idx : index of non-linear dependent, ie of j in x[j] and dx[j] and of j and k in fxx[i][j][k]
   // n_idx : index of non-linear equation, ie of i in f[i] and fxx[i][j][k]
   // x     : all independents (non-linear & linear)
   // dx    : Newton step first iteration = x1 - x0, and dx[w_idx] = w1 - w0
   // f     : Function values (ie residuals) as function of x0
   // fxx   : Hessian as function of x0
   // lambda: damping factor
   // maxRes: absolute maximum value of the non-linear residuals of iteration 0

   void *dataAndThreadData[2] = {data, threadData};
   NONLINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo->nonlinearSystemData[sysNumber]);

   unsigned i, j, k;

   // Get damped guess x1_star for second iteration step
   double x1_star[m];
   for( j = 0; j < m; j++)
      x1_star[j] = x[j] + lambda * dx[j];

   // Calculate residuals f_x1_star for damped guess x1_star
   double f_x1_star[m];
   (systemData->residualFunc)(dataAndThreadData, x1_star, f_x1_star, (int*)&systemData->size);

   // For each non-linear independent get w1_star - w0
   double w1_star_w0[p];
   for( j = 0; j < p; j++)
      w1_star_w0[j] = lambda * dx[w_idx[j]];

   // Calculate alpha for each non-linear equation i
   for( i = 0; i < p; ++i)
   {
      // Vector w_times_fww_w0 = (w1_star - w0)' * fww_w0  (1 x p * p x p --> 1 x p vector)
      double w_times_fww_w0[p];
      for( j = 0; j < p; j++)
      {
         // For each independent
         w_times_fww_w0[j] = 0;
         for( k = 0; k < p; k++)
            w_times_fww_w0[j] += w1_star_w0[k] * fxx[n_idx[i]][w_idx[k]][w_idx[j]];
      }

      // Scalar w_times_f_times_w = w_times_f_i_ww_w0 * (w1_star - w0) = (w1_star - w0)' * f_i_ww_w0 * (w1_star - w0)
      // (1 x p * p x 1 vector --> scalar)
      double w_times_fww_times_w = 0;
      for( k = 0; k < p; k++)
         w_times_fww_times_w += w_times_fww_w0[k] * w1_star_w0[k];

      // Calculate alpha for the non-linear equations
      alpha[i] = fabs(f_x1_star[n_idx[i]] - (1 - lambda) * f[n_idx[i]] - 0.5 * w_times_fww_times_w) / (pow(lambda,3) * maxRes);
   }
}

// --------------------------------------------------------------------------------------------------------------------------------

void getInvJacobian( unsigned m, double fx[m][m], double inv_fx[m][m])
{
   // Calculates inverse matrix of Jacobian fx as function of w0 (p x p matrix)
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

void calcSigma( unsigned m, unsigned p, unsigned w_idx[p], unsigned n_idx[p],
                double dx[m], double fx[m][m], double fxx[m][m][m], double Sigma[p][p])
{
   // Calculation of solution sensitivities Sigma_ij
   // ----------------------------------------------
   //
   // m     : total number of equations/independents
   // p     : number of non-linear equations/independents
   // w_idx : index of non-linear dependent, ie of j in dx[j] and of j and k in fxx[i][j][k]
   // n_idx : index of non-linear equation, ie of i in fx[i][j] and fxx[i][j][k]
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

   // Abstract matrix tmp2 from tmp1 for only non-linear (p x p matrix)
   double tmp2[p][p];
   for( i = 0; i < p; i++)
      for( j = 0; j < p; j++)
         tmp2[i][j] = tmp1[w_idx[i]][w_idx[j]];

   // Create a p x p matrix wDiag with w1 - w0 = dx[w_idx] on diagonal
   double wDiag[p][p];
   for( i = 0; i < p; i++)
      for( j = 0; j < p; j++)
         if (i == j)
            wDiag[i][j] = dx[w_idx[i]];
         else
            wDiag[i][j] = 0;

   // Get inverse matrix inv_wDiag of wDiag
   double inv_wDiag[p][p];
   getInvJacobian( p, wDiag, inv_wDiag);

   // Calculate tmp3 = | inv_wDiag | * tmp2
   // (p x p matrix) *  (p x p matrix) --> p x p matrix
   double tmp3[p][p];
   for( i = 0; i < p; i++)
      for( j = 0; j < p; j++)
         inv_wDiag[i][j] = fabs(inv_wDiag[i][j]);
   MatMult( p, p, p, inv_wDiag, tmp2, tmp3);

   // Calculate Sigma = tmp3 * wDiag =  | inv_wDiag | * tmp2 * wDiag = | inv_wDiag | * -inv_fx * H_i * wDiag
   MatMult( p, p, p, tmp3, wDiag, Sigma);
}

// --------------------------------------------------------------------------------------------------------------------------------

void PrintResults( DATA* data, unsigned p, unsigned w_idx[p], unsigned n_idx[p], double x0[p],
                   double lambda, double alpha[p], double Gamma_ijk[p][p][p], double Sigma_ij[p][p])
{
   unsigned i, j, k;

   printf("\n\n   ===============");
   printf("  \n    Final results ");
   printf("  \n   ===============\n\n");

   for( i = 0; i < p; i++)
      printf("      eq_%d : \n", n_idx[i]+1); //, data->modelData->realVarsData[var_id(w_idx[j])].info.name);
   printf("\n");

   for( j = 0; j < p; j++)
      printf("      var_%d: %8s = %7.3f\n", w_idx[j]+1, data->modelData->realVarsData[var_id(w_idx[j])].info.name, x0[w_idx[j]]);
   printf("\n");

   printf("      lambda    = %8.3f\n\n", lambda);

   for( i = 0; i < p; ++i)
   {
      if (alpha[i] > 1.e-6)
      {
         if (alpha[i] < 1.e5)
            printf("      alpha_%d   = %8.3f\n", n_idx[i]+1, alpha[i]);
         else
            printf("      alpha_%d   = %8.2e\n", n_idx[i]+1, alpha[i]);
      }
   }
   printf("\n");

   for( i = 0; i < p; i++)
   {
      for( j = 0; j < p; j++)
          for( k = 0; k <= j; k++)
             if (Gamma_ijk[i][j][k] > 1.e-6)
                printf("      Gamma_%d%d%d = %8.3f\n", n_idx[i]+1, w_idx[j]+1, w_idx[k]+1, Gamma_ijk[i][j][k]);
   }
   printf("\n");

   printf("      Sigma_ij\n           ");
   for( j = 0; j < p; j++)
      printf("      j=%2d", w_idx[j]+1);
   for( i = 0; i < p; i++)
   {
      printf("\n      i=%2d ", w_idx[i]+1);
      for( j = 0; j < p; j++)
         printf("%10.3f", Sigma_ij[i][j]);
   }
   printf("\n\n\n");
}

// --------------------------------------------------------------------------------------------------------------------------------

void newtonDiagnostics(DATA* data, threadData_t *threadData, int sysNumber)
{
  infoStreamPrint(LOG_NLS_NEWTON_DIAG, 0, "Hello newton diagnostics (version Teus)....");

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

  printf("   ****** Number of equations             : %ld\n", data->modelData->modelDataXml.nEquations);
  printf("   ****** Number of functions             : %ld\n", data->modelData->modelDataXml.nFunctions);
  printf("   ****** Number of relations             : %ld\n", data->modelData->nRelations);
  printf("   ****** Number of Jacobians             : %ld\n", data->modelData->nJacobians);
  printf("   ****** Number of sensitivity params    : %ld\n", data->modelData->nSensitivityVars);
  printf("   ****** Number of input variables       : %ld\n", data->modelData->nInputVars);
  printf("   ****** Number of output variables      : %ld\n", data->modelData->nOutputVars);
  printf("   ****** Number of linear systems        : %ld\n", data->modelData->nLinearSystems);
  printf("   ****** Number of nonlinear systems     : %ld\n", data->modelData->nNonLinearSystems);
  printf("   ****** Current index linear equation   : %d\n", data->simulationInfo->currentLinearSystemIndex);
  printf("   ****** Current index nonlinear equation: %d\n", data->simulationInfo->currentNonlinearSystemIndex);

  NONLINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo->nonlinearSystemData[sysNumber]);
  printf("   Nonlinear equation: %d\n", sysNumber);
  printf("   equationIndex     : %ld\n", systemData->equationIndex);
  printf("   size              : %ld\n", systemData->size);


  // --------------------------------------------------------------------------------------------------------------------------------

  // m total number of equations f(x)
  // p number of non-linear equations n(x)

  unsigned m = systemData->size;

  unsigned i;      // Function counter
  unsigned j, k;   // Variable counters

  double x0[m], f[m];

  // --------------------------------------------------------------------------------------------------------------------------------
  //  Thermo hydraulic case
  // --------------------------------------------------------------------------------------------------------------------------------

  // Obtain vector w0: initial guesses of vars where Jacobian matrix J(w) of f(x) only depends on
  unsigned p = m;
  double w0[p];
  unsigned w_idx[p];
  w_idx[0] = 0;
  w_idx[1] = 1;
  w_idx[2] = 2;
  w_idx[3] = 3;
  w_idx[4] = 4;
  w_idx[5] = 5;

  // Obtain function values of non-linear functions "n", i.e. residuals as function of w0
  double n[p];
  unsigned n_idx[p];
  n_idx[0] = 0;
  n_idx[1] = 1;
  n_idx[2] = 2;
  n_idx[3] = 3;
  n_idx[4] = 4;
  n_idx[5] = 5;

  // Linear dependables "z":
  double z[1];
  unsigned z_idx[1];

  // Linear equations "l":
  double l[1];
  unsigned l_idx[1];


  // --------------------------------------------------------------------------------------------------------------------------------
  //  DC circuit case
  // --------------------------------------------------------------------------------------------------------------------------------
  /*
  // Obtain vector w0: initial guesses of vars where Jacobian matrix J(w) of f(x) only depends on
  unsigned p = 3;
  double w0[q];
  unsigned w_idx[q];
  w_idx[0] = 2;  // var^3
  w_idx[1] = 3;  // var^4
  w_idx[2] = 4;  // var^5

  // Obtain function values of non-linear functions "n", i.e. residuals as function of w0
  double n[p];
  unsigned n_idx[p];
  n_idx[0] = 1;  // f^2
  n_idx[1] = 3;  // f^4
  n_idx[2] = 4;  // f^5

  // Linear dependables "z":
  double z[m-p];
  unsigned z_idx[m-p];
  z_idx[0]  =  0;
  z_idx[1]  =  1;
  z_idx[2]  =  5;
  z_idx[3]  =  6;
  z_idx[4]  =  7;
  z_idx[5]  =  8;
  z_idx[6]  =  9;
  z_idx[7]  = 10;
  z_idx[8]  = 11;
  z_idx[9]  = 12;

  // Linear equations "l":
  double l[m-p];
  unsigned l_idx[m-p];
  l_idx[0]  =  0;
  l_idx[1]  =  2;
  l_idx[2]  =  5;
  l_idx[3]  =  6;
  l_idx[4]  =  7;
  l_idx[5]  =  8;
  l_idx[6]  =  9;
  l_idx[7]  = 10;
  l_idx[8]  = 11;
  l_idx[9]  = 12;
*/
  // --------------------------------------------------------------------------------------------------------------------------------

  // Store all dependents in x0
  for( j = 0; j < m; j++)
     x0[j] = systemData->nlsx[j];

  // Store all function values f as function of x0
  for( i = 0; i < m; i++)
     f[i] = systemData->resValues[i];

  // Store non-linear dependents in w0
  for( j = 0; j < p; j++)
     w0[j] = x0[w_idx[j]];

  // Store function values of non-linear equations n
  for( i = 0; i < p; i++)
     n[i] = f[n_idx[i]];

  // Store linear variables z0
  for( j = 0; j < m - p; j++)
     z[j] = x0[z_idx[j]];

  // Store function values of linear equations l
  for( i = 0; i < m - p; i++)
     l[i] = f[l_idx[i]];

  // --------------------------------------------------------------------------------------------------------------------------------

   // Prints values of vector x0
  printf("\n   Vector x0 ....\n");
  for( j = 0; j < m; ++j)
     printf("\n               x0[%d] = %14.10f  (%s)", j+1, x0[j], data->modelData->realVarsData[var_id(j)].info.name);

  //SIMULATION_DATA *sData2 = data->localData[0];
  //unsigned nRealVar = data->modelData->nVariablesReal;
  //printf("\n\n   Vector x0 .... sData->realVars[j]\n");
  //for( j = 1; j < nRealVar; ++j)
  //   printf("\n               x0[%d] = %14.10f  (%s)", j, sData2->realVars[j], data->modelData->realVarsData[j].info.name);

  // Prints function values "f", i.e. residuals as function of x0
  printf("\n\n   Function values of all equations f(x0) ....\n");
  for( i = 0; i < m; ++i)
     printf("\n               f^%d = %14.10f", i+1, f[i]);

  // Prints values of vector w0
  printf("\n\n   Vector w0 .... \n");
  for( j = 0; j < p; j++)
     printf("\n               w0[%d] = %14.10f  (%s)", w_idx[j]+1, w0[j], data->modelData->realVarsData[var_id(w_idx[j])].info.name);

  // Prints function values of non-linear functions "n", i.e. residuals as function of w0
  printf("\n\n   Function values non-linear functions n(w0) ....\n");
  for( i = 0; i < p; i++)
     printf("\n               n^%d = %14.10f", n_idx[i]+1, n[i]);

  // Prints function values all linear functions "l", i.e. residuals as function of z0
  if (m - p > 0) printf("\n\n   Function values of linear functions l(z0) ....\n");
  for( i = 0; i < m - p; ++i)
     printf("\n               l^%d = %14.10f", l_idx[i]+1, l[i]);

   // --------------------------------------------------------------------------------------------------------------------------------
   //                                             Calculate Jacobian fx as function of x0
   // --------------------------------------------------------------------------------------------------------------------------------

   double fx[m][m];
   getJacobian( data, threadData, sysNumber, m, fx);

   // Prints values of Jacobian: each row i contains function f^i and each column variabele j
   printf("\n\n   Jacobian (per equation i).... J(x0)\n\n                   ");

   for( j = 0; j < m; j++)
      printf("     j=%2d", j+1);

   printf("\n                   ");
   for( j = 0; j < m; j++)
      printf("%9s", data->modelData->realVarsData[var_id(j)].info.name);

   for( i = 0; i < m; i++)
   {
      printf("\n               f^%2d", i+1);
      for( j = 0; j < m; j++)
         printf(" %8.6g", fx[i][j]);
   }
   printf("\n");

   if (p < m)
   {
      printf("\n   Jacobian (per non-linear equation i).... J(w0)\n\n                   ");

      for( j = 0; j < p; j++)
         printf("     j=%2d", w_idx[j]+1);

      printf("\n                   ");
      for( j = 0; j < p; j++)
         printf("%9s", data->modelData->realVarsData[var_id(w_idx[j])].info.name);

      for( i = 0; i < p; i++)
      {
         printf("\n               f^%2d", n_idx[i]+1);
         for( j = 0; j < p; j++)
            printf(" %8.6g", fx[n_idx[i]][w_idx[j]]);
      }
      printf("\n");
   }

   // --------------------------------------------------------------------------------------------------------------------------------
   //                                               Calculate first new Newton step delta
   // --------------------------------------------------------------------------------------------------------------------------------

   double dx[m];
   int info;
   getFirstNewtonStep( m, f, fx, dx, info);

   if (info > 0)
   {
      // Prints values of vector x1
      printf("\n   Newton steps for x....\n");
      for( j = 0; j < m; ++j)
         printf("\n               step[%d] = %14.10f", j+1, dx[j]);
      printf("\n");

      // Prints values of vector x1
      printf("\n   Vector x1 ....\n");
      for( j = 0; j < m; ++j)
         printf("\n               x1[%d] = %14.10f", j+1, x0[j] + dx[j]);
      printf("\n\n");
   }

   // Calculate non-linear residuals r_x0 = f_x0 + fz * (z1 - z0) at iteration point x0, where z1 - z0 = dx and fz = J.
   double max_res = maxNonLinearResiduals( m, m - p, z_idx, f, fx, dx);

   // --------------------------------------------------------------------------------------------------------------------------------
   //                                 Calculate fxx values with finite differences from Jacobian
   // --------------------------------------------------------------------------------------------------------------------------------

   double fxx[m][m][m];
   getHessian( data, threadData, sysNumber, m, fxx);

   // Prints values of Hessian per equation
   printf("\n   Hessian (per equation i).... H(x0)\n\n                   ");
   for( j = 0; j < m; j++)
      printf("     j=%2d", j+1);

   printf("\n                   ");
   for( j = 0; j < m; j++)
      printf("%9s", data->modelData->realVarsData[var_id(j)].info.name);

   for( i = 0; i < m; i++)
   {
      printf("\n\n      i = %2d   ", i+1);
      for( k = 0; k < m; k++)
      {
         if (k == 0)
            printf(               "k = %2d", k+1);
         else
            printf("               k = %2d", k+1);

         for( j = 0; j < m; j++)
            printf(" %8.6g", fxx[i][k][j]);
         printf("\n");
      }
   }
   printf("\n\n");

   // Prints values of Hessian per non-linear equation
   if (p < m)
   {
      printf("\n   Hessian (per non-linear equation i).... H(w0)\n\n                   ");
      for( j = 0; j < p; j++)
         printf("     j=%2d", w_idx[j]+1);

      printf("\n                   ");
      for( j = 0; j < p; j++)
         printf("%9s", data->modelData->realVarsData[var_id(w_idx[j])].info.name);

      for( i = 0; i < p; i++)
      {
         printf("\n\n      i = %2d   ", n_idx[i]+1);
         for( k = 0; k < p; k++)
         {
            if (k == 0)
               printf(               "k = %2d", w_idx[k]+1);
            else
               printf("               k = %2d", w_idx[k]+1);

            for( j = 0; j < p; j++)
               printf(" %8.6g", fxx[n_idx[i]][w_idx[k]][w_idx[j]]);
            printf("\n");
         }
      }
      printf("\n\n");
   }

   // --------------------------------------------------------------------------------------------------------------------------------
   //                                                   Calculate alpha coefficients
   // --------------------------------------------------------------------------------------------------------------------------------

   printf("\n   Calculating alpha coefficients....\n\n");

   double lambda = 0.49;

   printf("      max residual = %f\n\n", max_res);
   printf("      lambda  = %6.3f\n\n", lambda);

   double alpha[p];
   calcAlpha( data, threadData, sysNumber, m, p, w_idx, n_idx, x0, dx, f, fxx, lambda, max_res, alpha);

   for( i = 0; i < p; ++i)
   {
     if (alpha[i] < 1.e5)
        printf("      alpha_%d = %7.4f\n", n_idx[i]+1, alpha[i]);
     else
        printf("      alpha_%d = %7.4e\n", n_idx[i]+1, alpha[i]);
   }

   printf("\n   Calculating alpha coefficients finished!!\n\n");

   // --------------------------------------------------------------------------------------------------------------------------------
   //                                                  Calculate curvature factors
   // --------------------------------------------------------------------------------------------------------------------------------

   printf("\n   Calculating curvature factors Gamma_ijk....\n\n");

   double Gamma_ijk[p][p][p];
   calcGamma( m, p, w_idx, n_idx, dx, fxx, max_res, Gamma_ijk);

   for( i = 0; i < p; i++)
   {
      printf("               ");
      for( k = 0; k < p; k++)
         printf("          k=%2d", w_idx[k]+1);

      printf("\n              ");
      for( k = 0; k < p; ++k)
         printf("%14s", data->modelData->realVarsData[var_id(w_idx[k])].info.name);

      printf("\n     i = %2d ", n_idx[i]+1);
      for( j = 0; j < p; j++)
      {
         printf("j = %2d:   ", w_idx[j]+1);
         for( k = 0; k < p; k++)
         {
            if (Gamma_ijk[i][j][k] > 1.e-6)
               printf(" %10.8f   ", Gamma_ijk[i][j][k]);
            else
               printf("     0        ");
         }
         printf("\n            ");
      }
      printf("\n");
   }

   printf("   Calculating curvature factors finished!!\n\n");

   // --------------------------------------------------------------------------------------------------------------------------------
   //                                                 Calculate solution sensitivities
   // --------------------------------------------------------------------------------------------------------------------------------

   printf("\n   Calculating solution sensitivities....\n");

   double Sigma[p][p];
   calcSigma( m, p, w_idx, n_idx, dx, fx, fxx, Sigma);

   for( i = 0; i < p; ++i)
   {
      printf("\n      i = %2d ", i+1);
      for( j = 0; j < p; ++j)
         printf("%10.4f", Sigma[i][j]);
   }

   printf("\n\n   Calculating solution sensitivities finished!!\n");

   // --------------------------------------------------------------------------------------------------------------------------------

   PrintResults( data, p, w_idx, n_idx, x0, lambda, alpha, Gamma_ijk, Sigma);

   infoStreamPrint(LOG_NLS_NEWTON_DIAG, 0, "Newton diagnostics (version Teus) finished!!");
   return;
}

