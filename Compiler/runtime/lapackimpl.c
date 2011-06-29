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
#include "meta_modelica.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <math.h>

#include "rtclock.h"
#include "config.h"
#include "rtopts.h"
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

/* MacOS malloc.h is in sys */
#ifndef __APPLE_CC__
#include <malloc.h>
#else
#include <sys/malloc.h>
#endif

#endif

#if defined(_MSC_VER)
#define strncasecmp strnicmp
#endif

double* alloc_real_matrix(int N, int M, void *data)
{
  double *matrix;
  void *tmp = data;
  int i, j; 
  
  matrix = (double*)malloc(N * M * sizeof(double));
  assert(matrix != NULL);

  if(data) {
    for(i = 0; i < N; ++i) {
      tmp = RML_CAR(data);
      for(j = 0; j < M; ++j) {
        matrix[j * N + i] = rml_prim_get_real(RML_CAR(tmp));
        tmp = RML_CDR(tmp);
      }
      data = RML_CDR(data);
    }
  }

  return matrix;
}

double* alloc_real_vector(int N, void *data)
{
  double *vector;
  void *tmp = data;
  int i;

  vector = (double*)malloc(N * sizeof(double));
  assert(vector != NULL);

  if(data) {
    for(i = 0; i < N; ++i) {
      vector[i] = rml_prim_get_real(RML_CAR(tmp));
      tmp = RML_CDR(tmp);
    }
  } 

  return vector;
}

integer* alloc_int_vector(int N, void *data)
{
  integer *vector;
  void *tmp = data;
  int i;

  vector = (integer*)malloc(N * sizeof(integer));
  assert(vector != NULL);

  if(data) {
    for(i = 0; i < N; ++i) {
      vector[i] = RML_UNTAGFIXNUM(RML_CAR(tmp));
      tmp = RML_CDR(tmp);
    }
  }

  return vector;
}

double* alloc_zeroed_real_vector(int N)
{
  return (double*)calloc(N, sizeof(double));
}

double* alloc_zeroed_real_matrix(int N, int M)
{
  return (double*)calloc(N * M, sizeof(double));
}

integer* alloc_zeroed_int_vector(int N)
{
  return (integer*)calloc(N, sizeof(integer));
}

void* mk_rml_real_matrix(int N, int M, double *data)
{
  void *res, *tmp;
  int i, j;

  res = mk_nil();
  for(i = N - 1; i >= 0; --i) {
    tmp = mk_nil();
    for(j = M - 1; j >= 0; --j) {
      tmp = mk_cons(mk_rcon(data[j * N + i]), tmp);
    }
    res = mk_cons(tmp, res);
  }

  return res;
}

void* mk_rml_real_vector(int N, double *data)
{
  void *res;
  int i;

  res = mk_nil();
  for(i = N - 1; i >= 0; --i) {
    res = mk_cons(mk_rcon(data[i]), res);
  }

  return res;
}

void* mk_rml_int_vector(int N, integer *data)
{
  void *res;
  int i;

  res = mk_nil();
  for(i = N - 1; i >= 0; --i) {
    res = mk_cons(mk_icon(data[i]), res);
  }

  return res;
}

void debug_real_matrix(const char *name, int N, int M, double *data)
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

void debug_real_array(const char *name, int N, double *data)
{
  int i;

  printf("%s: { ", name);

  for(i = 0; i < N; ++i) {
    printf("%f", data[i]);
    if(i != N - 1) printf(", ");
  }
  printf("}\n");
}

void debug_int_array(const char *name, int N, int *data)
{
  int i;

  printf("%s: { ", name);

  for(i = 0; i < N; ++i) {
    printf("%d", data[i]);
    if(i != N - 1) printf(", ");
  }
  printf("}\n");
}

void LapackImpl__dgeev(void *JOBVL, void *JOBVR, void *N, void *inA, void *LDA, 
    void *LDVL, void *LDVR, void *inWORK, void *LWORK, void **outA, void **WR,
    void **WI, void **VL, void **VR, void **outWORK, void **INFO)
{
  integer n, lda, ldvl, ldvr, lwork, info = 0;
  double *a, *wr, *wi, *vl, *vr, *work;
  const char *jobvl = RML_STRINGDATA(JOBVL);
  const char *jobvr = RML_STRINGDATA(JOBVR);

  n = RML_UNTAGFIXNUM(N);
  lda = RML_UNTAGFIXNUM(LDA);
  ldvl = RML_UNTAGFIXNUM(LDVL);
  ldvr = RML_UNTAGFIXNUM(LDVR);
  lwork = RML_UNTAGFIXNUM(LWORK);

  a = alloc_real_matrix(lda, n, inA);
  work = alloc_real_vector(lwork, inWORK);
  wr = alloc_zeroed_real_vector(n);
  wi = alloc_zeroed_real_vector(n);
  vl = alloc_zeroed_real_matrix(ldvl, n);
  vr = alloc_zeroed_real_matrix(ldvr, n);

  dgeev_(&*jobvl, &*jobvr, &n, a, &lda, wr, wi, vl, &ldvl, vr, &ldvr, work,
    &lwork, &info);

  *outA = mk_rml_real_matrix(lda, n, a);
  *WR = mk_rml_real_vector(n, wr);
  *WI = mk_rml_real_vector(n, wi);
  *VL = mk_rml_real_matrix(ldvl, n, vl);
  *VR = mk_rml_real_matrix(ldvr, n, vr);
  *outWORK = mk_rml_real_vector(lwork, work);
  *INFO = mk_icon(info);

  free(a);
  free(work);
  free(wr);
  free(wi);
  free(vl);
  free(vr);
}

void LapackImpl__dgegv(void *JOBVL, void *JOBVR, void *N, void *A, void *LDA,
    void *B, void *LDB, void *LDVL, void *LDVR, void *inWORK, void *LWORK, 
    void **ALPHAR, void **ALPHAI, void **BETA, void **VL, void **VR, 
    void **outWORK, void **INFO)
{
  integer n, lda, ldb, ldvl, ldvr, lwork, info = 0;
  double *a, *b, *work, *alphar, *alphai, *beta, *vl, *vr;
  const char *jobvl = RML_STRINGDATA(JOBVL);
  const char *jobvr = RML_STRINGDATA(JOBVR);

  n = RML_UNTAGFIXNUM(N);
  lda = RML_UNTAGFIXNUM(LDA);
  ldb = RML_UNTAGFIXNUM(LDB);
  ldvl = RML_UNTAGFIXNUM(LDVL);
  ldvr = RML_UNTAGFIXNUM(LDVR);
  lwork = RML_UNTAGFIXNUM(LWORK);

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
  *INFO = mk_icon(info);

  free(a);
  free(b);
  free(alphar);
  free(alphai);
  free(beta);
  free(vl);
  free(vr);
  free(work);
}

void LapackImpl__dgels(void *TRANS, void *M, void *N, void *NRHS, void *inA,
    void *LDA, void *inB, void *LDB, void *inWORK, void *LWORK, void **outA,
    void **outB, void **outWORK, void **INFO)
{
  integer m, n, nrhs, lda, ldb, lwork, info = 0;
  double *a, *b, *work;
  const char *trans = RML_STRINGDATA(TRANS);

  m = RML_UNTAGFIXNUM(M);
  n = RML_UNTAGFIXNUM(N);
  nrhs = RML_UNTAGFIXNUM(NRHS);
  lda = RML_UNTAGFIXNUM(LDA);
  ldb = RML_UNTAGFIXNUM(LDB);
  lwork = RML_UNTAGFIXNUM(LWORK);

  a = alloc_real_matrix(lda, n, inA);
  b = alloc_real_matrix(lda, nrhs, inB);
  work = alloc_real_vector(lwork, inWORK);

  dgels_(&*trans, &m, &n, &nrhs, a, &lda, b, &ldb, work, &lwork, &info);

  *outA = mk_rml_real_matrix(lda, n, a);
  *outB = mk_rml_real_matrix(lda, nrhs, b);
  *outWORK = mk_rml_real_vector(lwork, work);
  *INFO = mk_icon(info);

  free(a);
  free(b);
  free(work);
}

void LapackImpl__dgelsx(void *M, void *N, void *NRHS, void *inA, void *LDA, 
    void *inB, void *LDB, void *inJPVT, void *RCOND, void *WORK, void *LWORK,
    void **outA, void **outB, void **outJPVT, void **RANK, void **INFO) 
{
  integer m, n, nrhs, lda, ldb, rank = 0, info = 0, lwork;
  double rcond;
  double *a, *b, *work;
  integer *jpvt;

  m = RML_UNTAGFIXNUM(M);
  n = RML_UNTAGFIXNUM(N);
  nrhs = RML_UNTAGFIXNUM(NRHS);
  lda = RML_UNTAGFIXNUM(LDA);
  ldb = RML_UNTAGFIXNUM(LDB);
  rcond = rml_prim_get_real(RCOND);
  lwork = RML_UNTAGFIXNUM(LWORK);

  a = alloc_real_matrix(lda, n, inA);
  b = alloc_real_matrix(ldb, nrhs, inB);
  work = alloc_real_vector(lwork, WORK);
  jpvt = alloc_int_vector(n, inJPVT);

  dgelsx_(&m, &n, &nrhs, a, &lda, b, &ldb, jpvt, &rcond, &rank, work, &info);

  *outA = mk_rml_real_matrix(lda, n, a);
  *outB = mk_rml_real_matrix(lda, nrhs, b);
  *outJPVT = mk_rml_int_vector(n, jpvt);
  *RANK = mk_icon(rank);
  *INFO = mk_icon(info);

  free(a);
  free(b);
  free(work);
  free(jpvt);
}

void LapackImpl__dgesv(void *N, void *NRHS, void *inA, void *LDA, void *inB,
    void *LDB, void **outA, void **IPIV, void **outB, void **INFO)
{
  integer n, nrhs, lda, ldb, info = 0;
  integer *ipiv;
  double *a, *b;

  n = RML_UNTAGFIXNUM(N);
  nrhs = RML_UNTAGFIXNUM(NRHS);
  lda = RML_UNTAGFIXNUM(LDA);
  ldb = RML_UNTAGFIXNUM(LDB);

  a = alloc_real_matrix(lda, n, inA);
  b = alloc_real_matrix(ldb, nrhs, inB);
  ipiv = alloc_zeroed_int_vector(n);

  dgesv_(&n, &nrhs, a, &lda, ipiv, b, &ldb, &info);

  *outA = mk_rml_real_matrix(lda, n, a);
  *outB = mk_rml_real_matrix(ldb, nrhs, b);
  *IPIV = mk_rml_int_vector(n, ipiv);
  *INFO = mk_icon(info);

  free(a);
  free(b);
  free(ipiv);
}

void LapackImpl__dgglse(void *M, void *N, void *P, void *inA, void *LDA, 
    void *inB, void *LDB, void *inC, void *inD, void *inWORK, void *LWORK, 
    void **outA, void **outB, void **outC, void **outD, void **outX, 
    void **outWORK, void **outINFO)
{
  integer m, n, p, lda, ldb, lwork, info = 0;
  double *a, *b, *c, *d, *x, *work;

  m = RML_UNTAGFIXNUM(M);
  n = RML_UNTAGFIXNUM(N);
  p = RML_UNTAGFIXNUM(P);
  lda = RML_UNTAGFIXNUM(LDA);
  ldb = RML_UNTAGFIXNUM(LDB);
  lwork = RML_UNTAGFIXNUM(LWORK);

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
  *outINFO = mk_icon(info);

  free(a);
  free(b);
  free(c);
  free(d);
  free(x);
  free(work);
}

void LapackImpl__dgtsv(void *N, void *NRHS, void *inDL, void *inD, void *inDU,
    void *inB, void *LDB, void **outDL, void **outD, void **outDU, void **outB,
    void **INFO)
{
  integer n, nrhs, ldb, info = 0;
  double *dl, *d, *du, *b;

  n = RML_UNTAGFIXNUM(N);
  nrhs = RML_UNTAGFIXNUM(NRHS);
  ldb = RML_UNTAGFIXNUM(LDB);

  dl = alloc_real_vector(n - 1, inDL);
  d = alloc_real_vector(n, inD);
  du = alloc_real_vector(n - 1, inDU);
  b = alloc_real_matrix(ldb, nrhs, inB);

  dgtsv_(&n, &nrhs, dl, d, du, b, &ldb, &info);

  *outDL = mk_rml_real_vector(n - 1, dl);
  *outD = mk_rml_real_vector(n, d);
  *outDU = mk_rml_real_vector(n - 1, du);
  *outB = mk_rml_real_matrix(ldb, nrhs, b);
  *INFO = mk_icon(info);

  free(dl);
  free(d);
  free(du);
  free(b);
}

void LapackImpl__dgbsv(void *N, void *KL, void *KU, void *NRHS, void *inAB, 
    void *LDAB, void *inB, void *LDB, void **outAB, void **IPIV, void **outB,
    void **INFO)
{
  integer n, kl, ku, nrhs, ldab, ldb, info = 0;
  double *ab, *b;
  integer *ipiv;

  n = RML_UNTAGFIXNUM(N);
  kl = RML_UNTAGFIXNUM(KL);
  ku = RML_UNTAGFIXNUM(KU);
  nrhs = RML_UNTAGFIXNUM(NRHS);
  ldab = RML_UNTAGFIXNUM(LDAB);
  ldb = RML_UNTAGFIXNUM(LDB);

  ab = alloc_real_matrix(ldab, n, inAB);
  b = alloc_real_matrix(ldb, nrhs, inB);
  ipiv = alloc_zeroed_int_vector(n);

  dgbsv_(&n, &kl, &ku, &nrhs, ab, &ldab, ipiv, b, &ldb, &info);

  *outAB = mk_rml_real_matrix(ldab, n, ab);
  *outB = mk_rml_real_matrix(ldb, nrhs, b);
  *IPIV = mk_rml_int_vector(n, ipiv);
  *INFO = mk_icon(info);

  free(ab);
  free(b);
  free(ipiv);
}

void LapackImpl__dgesvd(void *JOBU, void *JOBVT, void *M, void *N, void *inA,
    void *LDA, void *LDU, void *LDVT, void *inWORK, void *LWORK, void **outA,
    void **S, void **U, void **VT, void **outWORK, void **INFO)
{
  integer m, n, lda, ldu, ldvt, lwork, lds, ucol = 0, info = 0;
  double *a, *s, *u = NULL, *vt, *work;
  const char *jobu = RML_STRINGDATA(JOBU);
  const char *jobvt = RML_STRINGDATA(JOBVT);

  m = RML_UNTAGFIXNUM(M);
  n = RML_UNTAGFIXNUM(N);
  lda = RML_UNTAGFIXNUM(LDA);
  ldu = RML_UNTAGFIXNUM(LDU);
  ldvt = RML_UNTAGFIXNUM(LDVT);
  lwork = RML_UNTAGFIXNUM(LWORK);
  lds = min(m, n);
 
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
  *INFO = mk_icon(info);

  free(a);
  free(s);
  if(ucol) free(u);
  free(vt);
  free(work);
}

void LapackImpl__dgetrf(void *M, void *N, void *inA, void *LDA, void **outA,
    void **IPIV, void **INFO)
{
  integer m, n, lda, ldipiv, info = 0;
  double *a;
  integer *ipiv;

  m = RML_UNTAGFIXNUM(M);
  n = RML_UNTAGFIXNUM(N);
  lda = RML_UNTAGFIXNUM(LDA);
  ldipiv = min(m, n);

  a = alloc_real_matrix(lda, n, inA);
  ipiv = alloc_zeroed_int_vector(ldipiv);

  dgetrf_(&m, &n, a, &lda, ipiv, &info);

  *outA = mk_rml_real_matrix(lda, n, a);
  *IPIV = mk_rml_int_vector(ldipiv, ipiv);
  *INFO = mk_icon(info);

  free(a);
  free(ipiv);
}

void LapackImpl__dgetrs(void *TRANS, void *N, void *NRHS, void *inA, void *LDA,
    void *IPIV, void *inB, void *LDB, void **outB, void **INFO)
{
  integer n, nrhs, lda, ldb, info = 0;
  double *a, *b;
  integer *ipiv;
  const char *trans = RML_STRINGDATA(TRANS);

  n = RML_UNTAGFIXNUM(N);
  nrhs = RML_UNTAGFIXNUM(NRHS);
  lda = RML_UNTAGFIXNUM(LDA);
  ldb = RML_UNTAGFIXNUM(LDB);

  a = alloc_real_matrix(lda, n, inA);
  b = alloc_real_matrix(ldb, nrhs, inB);
  ipiv = alloc_int_vector(n, IPIV);

  dgetrs_(&*trans, &n, &nrhs, a, &lda, ipiv, b, &ldb, &info);

  *outB = mk_rml_real_matrix(ldb, nrhs, b);
  *INFO = mk_icon(info);

  free(a);
  free(b);
  free(ipiv);
}

void LapackImpl__dgetri(void *N, void *inA, void *LDA, void *IPIV, void *inWORK,
    void *LWORK, void **outA, void **outWORK, void **INFO)
{
  integer n, lda, lwork, info = 0;
  double *a, *work;
  integer *ipiv;

  n = RML_UNTAGFIXNUM(N);
  lda = RML_UNTAGFIXNUM(LDA);
  lwork = RML_UNTAGFIXNUM(LWORK);

  a = alloc_real_matrix(lda, n, inA);
  work = alloc_real_vector(lwork, inWORK);
  ipiv = alloc_int_vector(n, IPIV);

  dgetri_(&n, a, &lda, ipiv, work, &lwork, &info);

  *outA = mk_rml_real_matrix(lda, n, a);
  *outWORK = mk_rml_real_vector(lwork, work);
  *INFO = mk_icon(info);

  free(a);
  free(work);
}

void LapackImpl__dgeqpf(void *M, void *N, void *inA, void *LDA, void *inJPVT, 
    void *WORK, void **outA, void **outJPVT, void **TAU, void **INFO)
{
  integer m, n, lda, lwork, ldtau, info = 0;
  double *a, *tau, *work;
  integer *jpvt;

  m = RML_UNTAGFIXNUM(M);
  n = RML_UNTAGFIXNUM(N);
  lda = RML_UNTAGFIXNUM(LDA);
  lwork = 3 * n;
  ldtau = min(m, n);

  a = alloc_real_matrix(lda, n, inA);
  jpvt = alloc_int_vector(n, inJPVT);
  tau = alloc_zeroed_real_vector(ldtau);
  work = alloc_real_vector(lwork, WORK);

  dgeqpf_(&m, &n, a, &lda, jpvt, tau, work, &info);

  *outA = mk_rml_real_matrix(lda, n, a);
  *outJPVT = mk_rml_int_vector(n, jpvt);
  *TAU = mk_rml_real_vector(ldtau, tau);
  *INFO = mk_icon(info);
}

void LapackImpl__dorgqr(void *M, void *N, void *K, void *inA, void *LDA, 
    void *TAU, void *inWORK, void *LWORK, void **outA, void **outWORK, 
    void **INFO)
{
  integer m, n, k, lda, lwork, info = 0;
  double *a, *tau, *work;

  m = RML_UNTAGFIXNUM(M);
  n = RML_UNTAGFIXNUM(N);
  k = RML_UNTAGFIXNUM(K);
  lda = RML_UNTAGFIXNUM(LDA);
  lwork = RML_UNTAGFIXNUM(LWORK);

  a = alloc_real_matrix(lda, n, inA);
  tau = alloc_real_vector(k, TAU);
  work = alloc_real_vector(lwork, inWORK);

  dorgqr_(&m, &n, &k, a, &lda, tau, work, &lwork, &info);

  *outA = mk_rml_real_matrix(lda, n, a);
  *outWORK = mk_rml_real_vector(lwork, work);
  *INFO = mk_icon(info);

  free(a);
  free(tau);
  free(work);
}

#ifdef __cplusplus
}
#endif

