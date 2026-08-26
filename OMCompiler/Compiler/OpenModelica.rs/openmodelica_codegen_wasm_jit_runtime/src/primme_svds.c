/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

/* The PRIMME half of `simulation/solver/jacobian_analysis.c`'s sparse SVD
 * analysis, kept in C so `primme_svds_params` is never described twice.
 *
 * `omc_primme_svds` is `svd_sparse_main` without the printing: it builds the same
 * context, allocates the same two handles, and computes the largest triplet and
 * the `svd_count` smallest ones with the same method, tolerance and Jacobi
 * preconditioner. The caller formats the result.
 *
 * Compiled into the wasm PRIMME archive (see rust_omc.cmake's rust_primme_wasm),
 * so the runtime calls it like any other archive entry point. */

#include <primme.h>
#include <stdlib.h>
#include <string.h>

/* C's `primme_callback_ctx_t`, minus what only the printing needs. */
typedef struct {
   int n;
   const int *colptr;
   const int *rowidx;
   const double *vals;
   double *inv_diag_AtA;
   double *inv_diag_AAt;
} omc_ctx;

static void matrix_vector(const omc_ctx *c, const double *x, double *y)
{
   memset(y, 0, c->n * sizeof(double));
   for (int col = 0; col < c->n; col++)
      for (int nz = c->colptr[col]; nz < c->colptr[col + 1]; nz++)
         y[c->rowidx[nz]] += c->vals[nz] * x[col];
}

static void matrix_vector_transpose(const omc_ctx *c, const double *x, double *y)
{
   memset(y, 0, c->n * sizeof(double));
   for (int col = 0; col < c->n; col++)
      for (int nz = c->colptr[col]; nz < c->colptr[col + 1]; nz++)
         y[col] += c->vals[nz] * x[c->rowidx[nz]];
}

static void LinearOperator(void *x, PRIMME_INT *ldx, void *y, PRIMME_INT *ldy,
                           int *blockSize, int *transpose,
                           primme_svds_params *primme_svds, int *err)
{
   omc_ctx *c = (omc_ctx *)primme_svds->matrix;
   for (int i = 0; i < *blockSize; i++) {
      double *xvec = (double *)x + (*ldx) * i;
      double *yvec = (double *)y + (*ldy) * i;
      if (*transpose == 0)
         matrix_vector(c, xvec, yvec);
      else
         matrix_vector_transpose(c, xvec, yvec);
   }
   *err = 0;
}

static void GenericJacobiPreconditioner(void *x, PRIMME_INT *ldx, void *y, PRIMME_INT *ldy,
                                        int *blockSize, int *mode,
                                        primme_svds_params *primme_svds, int *ierr)
{
   omc_ctx *c = (omc_ctx *)primme_svds->matrix;
   int size = c->n;
   int modeAtA = primme_svds_op_AtA, modeAAt = primme_svds_op_AAt;
   int modeAug = primme_svds_op_augmented;
   PRIMME_INT ldaux = 2 * size;
   int notrans = 0, trans = 1;

   if (*mode == modeAtA || *mode == modeAAt) {
      const double *d = (*mode == modeAtA) ? c->inv_diag_AtA : c->inv_diag_AAt;
      for (int i = 0; i < *blockSize; i++) {
         double *xvec = (double *)x + (*ldx) * i;
         double *yvec = (double *)y + (*ldy) * i;
         for (int j = 0; j < size; j++) yvec[j] = xvec[j] * d[j];
      }
      *ierr = 0;
   } else if (*mode == modeAug) {
      double *aux = (double *)malloc((*blockSize) * ldaux * sizeof(double));
      primme_svds->matrixMatvec(x, ldx, &aux[size], &ldaux, blockSize, &notrans, primme_svds, ierr);
      primme_svds->matrixMatvec((double *)x + size, ldx, aux, &ldaux, blockSize, &trans, primme_svds, ierr);
      GenericJacobiPreconditioner(aux, &ldaux, y, ldy, blockSize, &modeAtA, primme_svds, ierr);
      GenericJacobiPreconditioner(&aux[size], &ldaux, (double *)y + size, ldy, blockSize, &modeAAt,
                                  primme_svds, ierr);
      free(aux);
   }
}

static void compute_jacobi_diags(omc_ctx *c, double sigma)
{
   const double reg = sigma * sigma;
   for (int j = 0; j < c->n; j++) { c->inv_diag_AtA[j] = 0.0; c->inv_diag_AAt[j] = 0.0; }
   for (int j = 0; j < c->n; j++) {
      for (int nz = c->colptr[j]; nz < c->colptr[j + 1]; nz++) {
         double v = c->vals[nz];
         c->inv_diag_AtA[j] += v * v;
         c->inv_diag_AAt[c->rowidx[nz]] += v * v;
      }
   }
   for (int j = 0; j < c->n; j++) {
      c->inv_diag_AtA[j] = 1.0 / (c->inv_diag_AtA[j] + reg);
      c->inv_diag_AAt[j] = 1.0 / (c->inv_diag_AAt[j] + reg);
   }
}

static int run(omc_ctx *c, int numSvals, primme_svds_target target, int print_level,
               double *svals, double *svecs, double *rnorms)
{
   primme_svds_params p;
   primme_svds_initialize(&p);
   p.m = c->n;
   p.n = c->n;
   p.numSvals = numSvals < c->n ? numSvals : c->n;
   p.matrixMatvec = LinearOperator;
   p.matrix = c;
   p.applyPreconditioner = GenericJacobiPreconditioner;
   p.preconditioner = c;
   p.eps = 1e-8;
   p.target = target;
   if (target == primme_svds_largest) p.numSvals = 1;
   primme_svds_set_method(primme_svds_normalequations, PRIMME_DEFAULT_MIN_TIME,
                          PRIMME_DEFAULT_MIN_MATVECS, &p);
   p.printLevel = print_level;
   if (print_level >= 2) primme_svds_display_params(p);
   p.precondition = (target == primme_svds_smallest) ? 1 : 0;
   int ret = dprimme_svds(svals, svecs, rnorms, &p);
   int found = (int)p.numSvals;
   primme_svds_free(&p);
   return ret != 0 ? -1 : found;
}

/* Returns the number of smallest triplets computed, or -1. `svecs_least` holds
 * PRIMME's layout: the left vectors first, then the right ones. */
int omc_primme_svds(int n, const int *colptr, const int *rowidx, const double *vals,
                    int svd_count, double sigma, int print_level,
                    double *sval_top, double *rnorm_top,
                    double *svals_least, double *rnorms_least, double *svecs_least)
{
   omc_ctx c;
   c.n = n;
   c.colptr = colptr;
   c.rowidx = rowidx;
   c.vals = vals;
   c.inv_diag_AtA = (double *)malloc(n * sizeof(double));
   c.inv_diag_AAt = (double *)malloc(n * sizeof(double));
   compute_jacobi_diags(&c, sigma);

   double *svecs_top = (double *)malloc(2 * n * sizeof(double));
   int rc = run(&c, svd_count, primme_svds_largest, print_level, sval_top, svecs_top, rnorm_top);
   free(svecs_top);
   if (rc >= 0)
      rc = run(&c, svd_count, primme_svds_smallest, print_level, svals_least, svecs_least,
               rnorms_least);

   free(c.inv_diag_AtA);
   free(c.inv_diag_AAt);
   return rc;
}
