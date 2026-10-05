/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * Shared access to the LAPACK routines omc calls. Include this instead of
 * declaring the routines yourself, and call them through OMC_LAPACK(), so that
 * every caller goes through the same path on Windows.
 */

#ifndef OMC_LAPACK_H
#define OMC_LAPACK_H

#include "omc_config.h"
#include "openmodelica_types.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifdef HAVE_LAPACK

#ifdef HAVE_LAPACK_DEPRECATED
#define OMC_LAPACK_DEPRECATED_FUNCTIONS(X) \
  X(dgeqpf_, int, (integer *m, integer *n, doublereal *a, integer *lda, \
      integer *jpvt, doublereal *tau, doublereal *work, integer *info)) \
  X(dgegv_, int, (const char *jobvl, const char *jobvr, integer *n, doublereal *a, \
      integer *lda, doublereal *b, integer *ldb, doublereal *alphar, \
      doublereal *alphai, doublereal *beta, doublereal *vl, integer *ldvl, \
      doublereal *vr, integer *ldvr, doublereal *work, integer *lwork, \
      integer *info)) \
  X(dgelsx_, int, (integer *m, integer *n, integer *nrhs, doublereal *a, \
      integer *lda, doublereal *b, integer *ldb, integer *jpvt, doublereal *rcond, \
      integer *rank, doublereal *work, integer *info))
#else
#define OMC_LAPACK_DEPRECATED_FUNCTIONS(X)
#endif

#define OMC_LAPACK_FUNCTIONS(X) \
  OMC_LAPACK_DEPRECATED_FUNCTIONS(X) \
  X(dgeev_, int, (const char *jobvl, const char *jobvr, integer *n, \
      doublereal *a, integer *lda, doublereal *wr, doublereal *wi, doublereal *vl, \
      integer *ldvl, doublereal *vr, integer *ldvr, doublereal *work, \
      integer *lwork, integer *info)) \
  X(dgels_, int, (const char *trans, integer *m, integer *n, integer *nrhs, \
      doublereal *a, integer *lda, doublereal *b, integer *ldb, doublereal *work, \
      integer *lwork, integer *info)) \
  X(dgelsy_, int, (integer *m, integer *n, integer *nrhs, doublereal *a, \
      integer *lda, doublereal *b, integer *ldb, integer *jpvt, doublereal *rcond, \
      integer *rank, doublereal *work, integer *lwork, integer *info)) \
  X(dgesv_, int, (integer *n, integer *nrhs, doublereal *a, integer *lda, \
      integer *ipiv, doublereal *b, integer *ldb, integer *info)) \
  X(dgglse_, int, (integer *m, integer *n, integer *p, doublereal *a, \
      integer *lda, doublereal *b, integer *ldb, doublereal *c, doublereal *d, \
      doublereal *x, doublereal *work, integer *lwork, integer *info)) \
  X(dgtsv_, int, (integer *n, integer *nrhs, doublereal *dl, doublereal *d, \
      doublereal *du, doublereal *b, integer *ldb, integer *info)) \
  X(dgbsv_, int, (integer *n, integer *kl, integer *ku, integer *nrhs, \
      doublereal *ab, integer *ldab, integer *ipiv, doublereal *b, \
      integer *ldb, integer *info)) \
  X(dgesvd_, int, (const char *jobu, const char *jobvt, integer *m, integer *n, \
      doublereal *a, integer *lda, doublereal *s, doublereal *u, integer *ldu, \
      doublereal *vt, integer *ldvt, doublereal *work, integer *lwork, integer *info)) \
  X(dgetrf_, int, (integer *m, integer *n, doublereal *a, integer *lda, \
      integer *ipiv, integer *info)) \
  X(dgetrs_, int, (const char *trans, integer *n, integer *nrhs, doublereal *a, \
      integer *lda, integer *ipiv, doublereal *b, integer *ldb, integer *info)) \
  X(dgetri_, int, (integer *n, doublereal *a, integer *lda, integer *ipiv, \
      doublereal *work, integer *lwork, integer *info)) \
  X(dorgqr_, int, (integer *m, integer *n, integer *k, doublereal *a, \
      integer *lda, doublereal *tau, doublereal *work, integer *lwork, integer *info)) \
  X(dhseqr_, int, (const char *job, const char *compz, integer *n, integer *ilo, \
      integer *ihi, doublereal *h, integer *ldh, doublereal *wr, doublereal *wi, \
      doublereal *z, integer *ldz, doublereal *work, integer *lwork, integer *info))

#if defined(_WIN32)

/*
 * On Windows the LAPACK library is loaded on demand rather than imported by
 * the compiler DLL, and it is loaded with OMP_NUM_THREADS pinned to one.
 *
 * OpenBLAS allocates its per-thread buffers in DllMain, sized by the thread
 * count, and Windows charges the whole allocation as committed memory even
 * though the buffers are never written. That is roughly 128 MB per hardware
 * thread on every omc process, several gigabytes on a build agent, while the
 * working set stays a few tens of megabytes. The compiler only ever does
 * small dense solves, so a threaded BLAS buys it nothing.
 *
 * Neither loading late nor asking for fewer threads afterwards helps on its
 * own: DllMain runs either way, and by the time openblas_set_num_threads is
 * reachable the memory is already committed. Only the environment, read once
 * during DllMain, changes the outcome. It is restored right after the load so
 * that compilers and simulations spawned by omc keep full threading.
 */

#define OMC_LAPACK_DECLARE_POINTER(name, ret, params) \
  typedef ret (*omc_lapack_fp_##name) params; \
  extern omc_lapack_fp_##name omc_lapack_ptr_##name;
OMC_LAPACK_FUNCTIONS(OMC_LAPACK_DECLARE_POINTER)

/* Loads the library on first use and hands back the routine, or reports an
   error and throws if it cannot be resolved. */
void* omc_lapack_symbol(void **slot, const char *name);

#define OMC_LAPACK(name) \
  (*(omc_lapack_fp_##name) omc_lapack_symbol((void**)&omc_lapack_ptr_##name, #name))

#else /* not Windows: the library is linked in, call it directly */

#define OMC_LAPACK_DECLARE_EXTERN(name, ret, params) extern ret name params;
OMC_LAPACK_FUNCTIONS(OMC_LAPACK_DECLARE_EXTERN)

#define OMC_LAPACK(name) name

#endif

#endif /* HAVE_LAPACK */

#ifdef __cplusplus
}
#endif

#endif /* OMC_LAPACK_H */
