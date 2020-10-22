/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Common includes
 */
#include "meta/meta_modelica.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <math.h>

#include "util/rtclock.h"
#include "omc_config.h"
#include "errorext.h"

/*
 * Platform specific includes and defines
 */
#if defined(__MINGW32__) || defined(_MSC_VER)
/* includes/defines specific for Windows*/
#include <assert.h>
#include <direct.h>
#include <process.h>

#if defined(__MINGW32__) /* include dirent for MINGW */
#include <sys/types.h>
#include <dirent.h>
#endif

#else
/* includes/defines specific for LINUX/OS X */
#include <ctype.h>
#include <dirent.h>
#include <sys/param.h> /* MAXPATHLEN */
#include <sys/unistd.h>
#include <sys/wait.h> /* only available in Linux, not windows */
#include <unistd.h>
#include <dlfcn.h>

#endif

#if defined(_MSC_VER)
#define strncasecmp strnicmp
#endif

#ifdef HAVE_LAPACK_DEPRECATED

extern int dgeqpf_(integer *m, integer *n, doublereal *a, integer *lda,
  integer *jpvt, doublereal *tau, doublereal *work, integer *info);

extern int dgegv_(const char *jobvl, const char *jobvr, integer *n, doublereal *a,
  integer *lda, doublereal *b, integer *ldb, doublereal *alphar,
  doublereal *alphai, doublereal *beta, doublereal *vl, integer *ldvl,
  doublereal *vr, integer *ldvr, doublereal *work, integer *lwork,
  integer *info);

extern int dgelsx_(integer *m, integer *n, integer *nrhs, doublereal *a,
  integer *lda, doublereal *b, integer *ldb, integer *jpvt, doublereal *rcond,
  integer *rank, doublereal *work, integer *info);

#endif

#ifndef NO_LAPACK

extern int dgeev_(const char *jobvl, const char *jobvr, integer *n,
  doublereal *a, integer *lda, doublereal *wr, doublereal *wi, doublereal *vl,
  integer *ldvl, doublereal *vr, integer *ldvr, doublereal *work,
  integer *lwork, integer *info);

extern int dgels_(const char *trans, integer *m, integer *n, integer *nrhs,
  doublereal *a, integer *lda, doublereal *b, integer *ldb, doublereal *work,
  integer *lwork, integer *info);

extern int dgelsy_(integer *m, integer *n, integer *nrhs, doublereal *a,
  integer *lda, doublereal *b, integer *ldb, integer *jpvt, doublereal *rcond,
  integer *rank, doublereal *work, integer *lwork, integer *info);

extern int dgesv_(integer *n, integer *nrhs, doublereal *a, integer *lda,
  integer *ipiv, doublereal *b, integer *ldb, integer *info);

extern int dgglse_(integer *m, integer *n, integer *p, doublereal *a,
  integer *lda, doublereal *b, integer *ldb, doublereal *c, doublereal *d,
  doublereal *x, doublereal *work, integer *lwork, integer *info);

extern int dgtsv_(integer *n, integer *nrhs, doublereal *dl, doublereal *d,
  doublereal *du, doublereal *b, integer *ldb, integer *info);

extern int dgbsv_(integer *n, integer *kl, integer *ku, integer *nrhs,
  doublereal *ab, integer *ldab, integer *ipiv, doublereal *b,
  integer *ldb, integer *info);

extern int dgesvd_(const char *jobu, const char *jobvt, integer *m, integer *n,
  doublereal *a, integer *lda, doublereal *s, doublereal *u, integer *ldu,
  doublereal *vt, integer *ldvt, doublereal *work, integer *lwork, integer *info);

extern int dgetrf_(integer *m, integer *n, doublereal *a, integer *lda,
  integer *ipiv, integer *info);

extern int dgetrs_(const char *trans, integer *n, integer *nrhs, doublereal *a,
  integer *lda, integer *ipiv, doublereal *b, integer *ldb, integer *info);

extern int dgetri_(integer *n, doublereal *a, integer *lda, integer *ipiv,
  doublereal *work, integer *lwork, integer *info);

extern int dorgqr_(integer *m, integer *n, integer *k, doublereal *a,
  integer *lda, doublereal *tau, doublereal *work, integer *lwork, integer *info);

static double* alloc_real_matrix(int N, int M, void *data)
{
  double *matrix;
  void *tmp = data;
  int i, j;

  matrix = (double*)malloc(N * M * sizeof(double));
  assert(matrix != NULL);

  if(data) {
    for(i = 0; i < N; ++i) {
      tmp = MMC_CAR(data);
      for(j = 0; j < M; ++j) {
        matrix[j * N + i] = mmc_prim_get_real(MMC_CAR(tmp));
        tmp = MMC_CDR(tmp);
      }
      data = MMC_CDR(data);
    }
  }

  return matrix;
}

static double* alloc_real_vector(int N, void *data)
{
  double *vector;
  void *tmp = data;
  int i;

  vector = (double*)malloc(N * sizeof(double));
  assert(vector != NULL);

  if(data) {
    for(i = 0; i < N; ++i) {
      vector[i] = mmc_prim_get_real(MMC_CAR(tmp));
      tmp = MMC_CDR(tmp);
    }
  }

  return vector;
}

static integer* alloc_int_vector(int N, void *data)
{
  integer *vector;
  void *tmp = data;
  int i;

  vector = (integer*)malloc(N * sizeof(integer));
  assert(vector != NULL);

  if(data) {
    for(i = 0; i < N; ++i) {
      vector[i] = MMC_UNTAGFIXNUM(MMC_CAR(tmp));
      tmp = MMC_CDR(tmp);
    }
  }

  return vector;
}

static double* alloc_zeroed_real_vector(int N)
{
  return (double*)calloc(N, sizeof(double));
}

static double* alloc_zeroed_real_matrix(int N, int M)
{
  return (double*)calloc(N * M, sizeof(double));
}

static integer* alloc_zeroed_int_vector(int N)
{
  return (integer*)calloc(N, sizeof(integer));
}

static void* mk_rml_real_matrix(int N, int M, double *data)
{
  void *res, *tmp;
  int i, j;

  res = mmc_mk_nil();
  for(i = N - 1; i >= 0; --i) {
    tmp = mmc_mk_nil();
    for(j = M - 1; j >= 0; --j) {
      tmp = mmc_mk_cons(mmc_mk_rcon(data[j * N + i]), tmp);
    }
    res = mmc_mk_cons(tmp, res);
  }

  return res;
}

static void* mk_rml_real_vector(int N, double *data)
{
  void *res;
  int i;

  res = mmc_mk_nil();
  for(i = N - 1; i >= 0; --i) {
    res = mmc_mk_cons(mmc_mk_rcon(data[i]), res);
  }

  return res;
}

static void* mk_rml_int_vector(int N, integer *data)
{
  void *res;
  int i;

  res = mmc_mk_nil();
  for(i = N - 1; i >= 0; --i) {
    res = mmc_mk_cons(mmc_mk_icon(data[i]), res);
  }

  return res;
}

static void debug_real_matrix(const char *name, int N, int M, double *data)
{
  int i, j;
  double d;

  printf("%s:\n[", name);

  for(i = 0; i < N; ++i) {
    for(j = 0; j < M; ++j) {
      d = data[i * M + j];

      if(d < 0) {
        printf("%f", d);
      } else {
        printf(" %f", d);
      }
      if(j != M - 1) printf(", ");
    }
    printf(";\n");
  }
  printf(" ];\n");
}

static void debug_real_array(const char *name, int N, double *data)
{
  int i;

  printf("%s: { ", name);

  for(i = 0; i < N; ++i) {
    printf("%f", data[i]);
    if(i != N - 1) printf(", ");
  }
  printf("}\n");
}

static void debug_int_array(const char *name, int N, int *data)
{
  int i;

  printf("%s: { ", name);

  for(i = 0; i < N; ++i) {
    printf("%d", data[i]);
    if(i != N - 1) printf(", ");
  }
  printf("}\n");
}

#endif

void LapackImpl__dgeev(const char *jobvl, const char *jobvr, int N, void *inA, int LDA,
    int LDVL, int LDVR, void *inWORK, int LWORK, void **outA, void **WR,
    void **WI, void **VL, void **VR, void **outWORK, int *INFO)
{
#ifndef NO_LAPACK
  integer n, lda, ldvl, ldvr, lwork, info = 0;
  double *a, *wr, *wi, *vl, *vr, *work;

  n = N;
  lda = LDA;
  ldvl = LDVL;
  ldvr = LDVR;
  lwork = LWORK;

  a = alloc_real_matrix(lda, n, inA);
  work = alloc_real_vector(lwork, inWORK);
  wr = alloc_zeroed_real_vector(n);
  wi = alloc_zeroed_real_vector(n);
  vl = alloc_zeroed_real_matrix(ldvl, n);
  vr = alloc_zeroed_real_matrix(ldvr, n);

  dgeev_(jobvl, jobvr, &n, a, &lda, wr, wi, vl, &ldvl, vr, &ldvr, work,
    &lwork, &info);

  *outA = mk_rml_real_matrix(lda, n, a);
  *WR = mk_rml_real_vector(n, wr);
  *WI = mk_rml_real_vector(n, wi);
  *VL = mk_rml_real_matrix(ldvl, n, vl);
  *VR = mk_rml_real_matrix(ldvr, n, vr);
  *outWORK = mk_rml_real_vector(lwork, work);
  *INFO = info;

  free(a);
  free(work);
  free(wr);
  free(wi);
  free(vl);
  free(vr);
#else
  MMC_THROW();
#endif
}

void LapackImpl__dgegv(const char *jobvl, const char *jobvr, int N, void *A, int LDA,
    void *B, int LDB, int LDVL, int LDVR, void *inWORK, int LWORK,
    void **ALPHAR, void **ALPHAI, void **BETA, void **VL, void **VR,
    void **outWORK, int *INFO)
{
#ifdef HAVE_LAPACK_DEPRECATED
  integer n, lda, ldb, ldvl, ldvr, lwork, info = 0;
  double *a, *b, *work, *alphar, *alphai, *beta, *vl, *vr;

  n = N;
  lda = LDA;
  ldb = LDB;
  ldvl = LDVL;
  ldvr = LDVR;
  lwork = LWORK;

  a = alloc_real_matrix(lda, n, A);
  b = alloc_real_matrix(ldb, n, B);
  alphar = alloc_zeroed_real_vector(n);
  alphai = alloc_zeroed_real_vector(n);
  beta = alloc_zeroed_real_vector(n);
  vl = alloc_zeroed_real_matrix(ldvl, n);
  vr = alloc_zeroed_real_matrix(ldvl, n);
  work = alloc_real_vector(lwork, inWORK);

  dgegv_(&*jobvl, &*jobvr, &n, a, &lda, b, &ldb, alphar, alphai, beta, vl,
    &ldvl, vr, &ldvr, work, &lwork, &info);

  *ALPHAR = mk_rml_real_vector(n, alphar);
  *ALPHAI = mk_rml_real_vector(n, alphai);
  *BETA = mk_rml_real_vector(n, beta);
  *VL = mk_rml_real_matrix(ldvl, n, vl);
  *VR = mk_rml_real_matrix(ldvl, n, vr);
  *outWORK = mk_rml_real_vector(lwork, work);
  *INFO = info;

  free(a);
  free(b);
  free(alphar);
  free(alphai);
  free(beta);
  free(vl);
  free(vr);
  free(work);
#else
  MMC_THROW();
#endif
}

void LapackImpl__dgels(const char *trans, int M, int N, int NRHS, void *inA,
    int LDA, void *inB, int LDB, void *inWORK, int LWORK, void **outA,
    void **outB, void **outWORK, int *INFO)
{
#ifndef NO_LAPACK
  integer m, n, nrhs, lda, ldb, lwork, info = 0;
  double *a, *b, *work;

  m = M;
  n = N;
  nrhs = NRHS;
  lda = LDA;
  ldb = LDB;
  lwork = LWORK;

  a = alloc_real_matrix(lda, n, inA);
  b = alloc_real_matrix(lda, nrhs, inB);
  work = alloc_real_vector(lwork, inWORK);

  dgels_(&*trans, &m, &n, &nrhs, a, &lda, b, &ldb, work, &lwork, &info);

  *outA = mk_rml_real_matrix(lda, n, a);
  *outB = mk_rml_real_matrix(lda, nrhs, b);
  *outWORK = mk_rml_real_vector(lwork, work);
  *INFO = info;

  free(a);
  free(b);
  free(work);
#else
  MMC_THROW();
#endif
}

void LapackImpl__dgelsx(int M, int N, int NRHS, void *inA, int LDA,
    void *inB, int LDB, void *inJPVT, double rcond, void *WORK,
    void **outA, void **outB, void **outJPVT, int *RANK, int *INFO)
{
#ifdef HAVE_LAPACK_DEPRECATED
  integer m, n, nrhs, lda, ldb, rank = 0, info = 0, lwork;
  double *a, *b, *work;
  integer *jpvt;

  m = M;
  n = N;
  nrhs = NRHS;
  lda = LDA;
  ldb = LDB;
  lwork = (integer)fmax(fmin(M, N) + 3*N, 2*fmin(M, N) + nrhs);

  a = alloc_real_matrix(lda, n, inA);
  b = alloc_real_matrix(ldb, nrhs, inB);
  work = alloc_real_vector(lwork, WORK);
  jpvt = alloc_int_vector(n, inJPVT);

  dgelsx_(&m, &n, &nrhs, a, &lda, b, &ldb, jpvt, &rcond, &rank, work, &info);

  *outA = mk_rml_real_matrix(lda, n, a);
  *outB = mk_rml_real_matrix(lda, nrhs, b);
  *outJPVT = mk_rml_int_vector(n, jpvt);
  *RANK = rank;
  *INFO = info;

  free(a);
  free(b);
  free(work);
  free(jpvt);
#else
  MMC_THROW();
#endif
}

void LapackImpl__dgelsy(int M, int N, int NRHS, void *inA, int LDA,
    void *inB, int LDB, void *inJPVT, double rcond, void *inWORK, int LWORK,
    void **outA, void **outB, void **outJPVT, int *RANK, void **outWORK, int *INFO)
{
#ifndef NO_LAPACK
  integer m, n, nrhs, lda, ldb, rank = 0, info = 0, lwork;
  double *a, *b, *work;
  integer *jpvt;

  m = M;
  n = N;
  nrhs = NRHS;
  lda = LDA;
  ldb = LDB;
  lwork = LWORK;

  a = alloc_real_matrix(lda, n, inA);
  b = alloc_real_matrix(ldb, nrhs, inB);
  work = alloc_real_vector(lwork, inWORK);
  jpvt = alloc_int_vector(n, inJPVT);

  dgelsy_(&m, &n, &nrhs, a, &lda, b, &ldb, jpvt, &rcond, &rank, work, &lwork, &info);

  *outA = mk_rml_real_matrix(lda, n, a);
  *outB = mk_rml_real_matrix(lda, nrhs, b);
  *outJPVT = mk_rml_int_vector(n, jpvt);
  *RANK = rank;
  *outWORK = mk_rml_real_vector(lwork, work);
  *INFO = info;

  free(a);
  free(b);
  free(work);
  free(jpvt);
#else
  MMC_THROW();
#endif
}

void LapackImpl__dgesv(int N, int NRHS, void *inA, int LDA, void *inB,
    int LDB, void **outA, void **IPIV, void **outB, int *INFO)
{
#ifndef NO_LAPACK
  integer n, nrhs, lda, ldb, info = 0;
  integer *ipiv;
  double *a, *b;

  n = N;
  nrhs = NRHS;
  lda = LDA;
  ldb = LDB;

  a = alloc_real_matrix(lda, n, inA);
  b = alloc_real_matrix(ldb, nrhs, inB);
  ipiv = alloc_zeroed_int_vector(n);

  dgesv_(&n, &nrhs, a, &lda, ipiv, b, &ldb, &info);

  *outA = mk_rml_real_matrix(lda, n, a);
  *outB = mk_rml_real_matrix(ldb, nrhs, b);
  *IPIV = mk_rml_int_vector(n, ipiv);
  *INFO = info;

  free(a);
  free(b);
  free(ipiv);
#else
  MMC_THROW();
#endif
}

void LapackImpl__dgglse(int M, int N, int P, void *inA, int LDA,
    void *inB, int LDB, void *inC, void *inD, void *inWORK, int LWORK,
    void **outA, void **outB, void **outC, void **outD, void **outX,
    void **outWORK, int *outINFO)
{
#ifndef NO_LAPACK
  integer m, n, p, lda, ldb, lwork, info = 0;
  double *a, *b, *c, *d, *x, *work;

  m = M;
  n = N;
  p = P;
  lda = LDA;
  ldb = LDB;
  lwork = LWORK;

  a = alloc_real_matrix(lda, n, inA);
  b = alloc_real_matrix(ldb, n, inB);
  c = alloc_real_vector(m, inC);
  d = alloc_real_vector(p, inD);
  x = alloc_zeroed_real_vector(n);
  work = alloc_real_vector(lwork, inWORK);

  dgglse_(&m, &n, &p, a, &lda, b, &ldb, c, d, x, work, &lwork, &info);

  *outA = mk_rml_real_matrix(lda, n, a);
  *outB = mk_rml_real_matrix(ldb, n, b);
  *outC = mk_rml_real_vector(m, c);
  *outD = mk_rml_real_vector(p, d);
  *outX = mk_rml_real_vector(n, x);
  *outWORK = mk_rml_real_vector(lwork, work);
  *outINFO = info;

  free(a);
  free(b);
  free(c);
  free(d);
  free(x);
  free(work);
#else
  MMC_THROW();
#endif
}

void LapackImpl__dgtsv(int N, int NRHS, void *inDL, void *inD, void *inDU,
    void *inB, int LDB, void **outDL, void **outD, void **outDU, void **outB,
    int *INFO)
{
#ifndef NO_LAPACK
  integer n, nrhs, ldb, info = 0;
  double *dl, *d, *du, *b;

  n = N;
  nrhs = NRHS;
  ldb = LDB;

  dl = alloc_real_vector(n - 1, inDL);
  d = alloc_real_vector(n, inD);
  du = alloc_real_vector(n - 1, inDU);
  b = alloc_real_matrix(ldb, nrhs, inB);

  dgtsv_(&n, &nrhs, dl, d, du, b, &ldb, &info);

  *outDL = mk_rml_real_vector(n - 1, dl);
  *outD = mk_rml_real_vector(n, d);
  *outDU = mk_rml_real_vector(n - 1, du);
  *outB = mk_rml_real_matrix(ldb, nrhs, b);
  *INFO = info;

  free(dl);
  free(d);
  free(du);
  free(b);
#else
  MMC_THROW();
#endif
}

void LapackImpl__dgbsv(int N, int KL, int KU, int NRHS, void *inAB,
    int LDAB, void *inB, int LDB, void **outAB, void **IPIV, void **outB,
    int *INFO)
{
#ifndef NO_LAPACK
  integer n, kl, ku, nrhs, ldab, ldb, info = 0;
  double *ab, *b;
  integer *ipiv;

  n = N;
  kl = KL;
  ku = KU;
  nrhs = NRHS;
  ldab = LDAB;
  ldb = LDB;

  ab = alloc_real_matrix(ldab, n, inAB);
  b = alloc_real_matrix(ldb, nrhs, inB);
  ipiv = alloc_zeroed_int_vector(n);

  dgbsv_(&n, &kl, &ku, &nrhs, ab, &ldab, ipiv, b, &ldb, &info);

  *outAB = mk_rml_real_matrix(ldab, n, ab);
  *outB = mk_rml_real_matrix(ldb, nrhs, b);
  *IPIV = mk_rml_int_vector(n, ipiv);
  *INFO = info;

  free(ab);
  free(b);
  free(ipiv);
#else
  MMC_THROW();
#endif
}

void LapackImpl__dgesvd(const char *jobu, const char *jobvt, int M, int N, void *inA,
    int LDA, int LDU, int LDVT, void *inWORK, int LWORK, void **outA,
    void **S, void **U, void **VT, void **outWORK, int *INFO)
{
#ifndef NO_LAPACK
  integer m, n, lda, ldu, ldvt, lwork, lds, ucol = 0, info = 0;
  double *a, *s, *u = NULL, *vt, *work;

  m = M;
  n = N;
  lda = LDA;
  ldu = LDU;
  ldvt = LDVT;
  lwork = LWORK;
  lds = (m < n ? m : n);

  if(*jobu == 'A') ucol = m;
  else if(*jobu == 'S') ucol = lds;

  a = alloc_real_matrix(lda, n, inA);
  s = alloc_zeroed_real_vector(lds);
  if(ucol) u = alloc_zeroed_real_matrix(ldu, ucol);
  vt = alloc_zeroed_real_matrix(ldvt, n);
  work = alloc_real_vector(lwork, inWORK);

  dgesvd_(&*jobu, &*jobvt, &m, &n, a, &lda, s, u, &ldu, vt, &ldvt, work,
    &lwork, &info);

  *outA = mk_rml_real_matrix(lda, n, a);
  *S = mk_rml_real_vector(lds, s);
  if(ucol) *U = mk_rml_real_matrix(ldu, ucol, u);
  *VT = mk_rml_real_matrix(ldvt, n, vt);
  *outWORK = mk_rml_real_vector(lwork, work);
  *INFO = info;

  free(a);
  free(s);
  if(ucol) free(u);
  free(vt);
  free(work);
#else
  MMC_THROW();
#endif
}

void LapackImpl__dgetrf(int M, int N, void *inA, int LDA, void **outA,
    void **IPIV, int *INFO)
{
#ifndef NO_LAPACK
  integer m, n, lda, ldipiv, info = 0;
  double *a;
  integer *ipiv;

  m = M;
  n = N;
  lda = LDA;
  ldipiv = (m < n ? m : n);

  a = alloc_real_matrix(lda, n, inA);
  ipiv = alloc_zeroed_int_vector(ldipiv);

  dgetrf_(&m, &n, a, &lda, ipiv, &info);

  *outA = mk_rml_real_matrix(lda, n, a);
  *IPIV = mk_rml_int_vector(ldipiv, ipiv);
  *INFO = info;

  free(a);
  free(ipiv);
#else
  MMC_THROW();
#endif
}

void LapackImpl__dgetrs(const char *trans, int N, int NRHS, void *inA, int LDA,
    void *IPIV, void *inB, int LDB, void **outB, int *INFO)
{
#ifndef NO_LAPACK
  integer n, nrhs, lda, ldb, info = 0;
  double *a, *b;
  integer *ipiv;

  n = N;
  nrhs = NRHS;
  lda = LDA;
  ldb = LDB;

  a = alloc_real_matrix(lda, n, inA);
  b = alloc_real_matrix(ldb, nrhs, inB);
  ipiv = alloc_int_vector(n, IPIV);

  dgetrs_(&*trans, &n, &nrhs, a, &lda, ipiv, b, &ldb, &info);

  *outB = mk_rml_real_matrix(ldb, nrhs, b);
  *INFO = info;

  free(a);
  free(b);
  free(ipiv);
#else
  MMC_THROW();
#endif
}

void LapackImpl__dgetri(int N, void *inA, int LDA, void *IPIV, void *inWORK,
    int LWORK, void **outA, void **outWORK, int *INFO)
{
#ifndef NO_LAPACK
  integer n, lda, lwork, info = 0;
  double *a, *work;
  integer *ipiv;

  n = N;
  lda = LDA;
  lwork = LWORK;

  a = alloc_real_matrix(lda, n, inA);
  work = alloc_real_vector(lwork, inWORK);
  ipiv = alloc_int_vector(n, IPIV);

  dgetri_(&n, a, &lda, ipiv, work, &lwork, &info);

  *outA = mk_rml_real_matrix(lda, n, a);
  *outWORK = mk_rml_real_vector(lwork, work);
  *INFO = info;

  free(a);
  free(work);
  free(ipiv);
#else
  MMC_THROW();
#endif
}

void LapackImpl__dgeqpf(int M, int N, void *inA, int LDA, void *inJPVT,
    void *WORK, void **outA, void **outJPVT, void **TAU, int *INFO)
{
#ifdef HAVE_LAPACK_DEPRECATED
  integer m, n, lda, lwork, ldtau, info = 0;
  double *a, *tau, *work;
  integer *jpvt;

  m = M;
  n = N;
  lda = LDA;
  lwork = 3 * n;
  ldtau = (m < n ? m : n);

  a = alloc_real_matrix(lda, n, inA);
  jpvt = alloc_int_vector(n, inJPVT);
  tau = alloc_zeroed_real_vector(ldtau);
  work = alloc_real_vector(lwork, WORK);

  dgeqpf_(&m, &n, a, &lda, jpvt, tau, work, &info);

  *outA = mk_rml_real_matrix(lda, n, a);
  *outJPVT = mk_rml_int_vector(n, jpvt);
  *TAU = mk_rml_real_vector(ldtau, tau);
  *INFO = info;

  free(a);
  free(jpvt);
  free(tau);
  free(work);
#else
  MMC_THROW();
#endif
}

void LapackImpl__dorgqr(int M, int N, int K, void *inA, int LDA,
    void *TAU, void *inWORK, int LWORK, void **outA, void **outWORK,
    int *INFO)
{
#ifndef NO_LAPACK
  integer m, n, k, lda, lwork, info = 0;
  double *a, *tau, *work;

  m = M;
  n = N;
  k = K;
  lda = LDA;
  lwork = LWORK;

  a = alloc_real_matrix(lda, n, inA);
  tau = alloc_real_vector(k, TAU);
  work = alloc_real_vector(lwork, inWORK);

  dorgqr_(&m, &n, &k, a, &lda, tau, work, &lwork, &info);

  *outA = mk_rml_real_matrix(lda, n, a);
  *outWORK = mk_rml_real_vector(lwork, work);
  *INFO = info;

  free(a);
  free(tau);
  free(work);
#else
  MMC_THROW();
#endif
}

#ifdef __cplusplus
}
#endif

