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

/*
 * adrpo 2007-05-09
 * UNCOMMENT THIS ONLY IF YOU COMPILE OMC IN DEBUG MODE!!!!!
 * #define RML_DEBUG
 */

#include "rml.h"
#include "lapackimpl.c"

void Lapack_5finit(void)
{
}

RML_BEGIN_LABEL(Lapack__dgeev)
{
  void *A, *WR, *WI, *VL, *VR, *WORK, *INFO;
  LapackImpl__dgeev(rmlA0, rmlA1, rmlA2, rmlA3, rmlA4, rmlA5, rmlA6, rmlA7, rmlA8, &A, &WR, &WI, &VL, &VR, &WORK, &INFO);
  rmlA0 = A;
  rmlA1 = WR;
  rmlA2 = WI;
  rmlA3 = VL;
  rmlA4 = VR;
  rmlA5 = WORK;
  rmlA6 = INFO;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgegv)
{
  void *ALPHAR, *ALPHAI, *BETA, *VL, *VR, *WORK, *INFO;
  LapackImpl__dgegv(rmlA0, rmlA1, rmlA2, rmlA3, rmlA4, rmlA5, rmlA6, rmlA7, rmlA8, rmlA9, rmlA10, &ALPHAR, &ALPHAI, &BETA, &VL, &VR, &WORK, &INFO);
  rmlA0 = ALPHAR;
  rmlA1 = ALPHAI;
  rmlA2 = BETA;
  rmlA3 = VL;
  rmlA4 = VR;
  rmlA5 = WORK;
  rmlA6 = INFO;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgels)
{
  void *A, *B, *WORK, *INFO;
  LapackImpl__dgels(rmlA0, rmlA1, rmlA2, rmlA3, rmlA4, rmlA5, rmlA6, rmlA7, rmlA8, rmlA9, &A, &B, &WORK, &INFO);
  rmlA0 = A;
  rmlA1 = B;
  rmlA2 = WORK;
  rmlA3 = INFO;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgelsx)
{
  void *A, *B, *JPVT, *RANK, *INFO;
  LapackImpl__dgelsx(rmlA0, rmlA1, rmlA2, rmlA3, rmlA4, rmlA5, rmlA6, rmlA7, rmlA8, rmlA9, rmlA10, &A, &B, &JPVT, &RANK, &INFO);
  rmlA0 = A;
  rmlA1 = B;
  rmlA2 = JPVT;
  rmlA3 = RANK;
  rmlA4 = INFO;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgesv)
{
  void *A, *IPIV, *B, *INFO;
  LapackImpl__dgesv(rmlA0, rmlA1, rmlA2, rmlA3, rmlA4, rmlA5, &A, &IPIV, &B, &INFO);
  rmlA0 = A;
  rmlA1 = IPIV;
  rmlA2 = B;
  rmlA3 = INFO;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgglse)
{
  void *A, *B, *C, *D, *X, *WORK, *INFO;
  LapackImpl__dgglse(rmlA0, rmlA1, rmlA2, rmlA3, rmlA4, rmlA5, rmlA6, rmlA7, rmlA8, rmlA9, rmlA10, &A, &B, &C, &D, &X, &WORK, &INFO);
  rmlA0 = A;
  rmlA1 = B;
  rmlA2 = C;
  rmlA3 = D;
  rmlA4 = X;
  rmlA5 = WORK;
  rmlA6 = INFO;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgtsv)
{
  void *DL, *D, *DU, *B, *INFO;
  LapackImpl__dgtsv(rmlA0, rmlA1, rmlA2, rmlA3, rmlA4, rmlA5, rmlA6, &DL, &D, &DU, &B, &INFO);
  rmlA0 = DL;
  rmlA1 = D;
  rmlA2 = DU;
  rmlA3 = B;
  rmlA4 = INFO;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgbsv)
{
  void *AB, *IPIV, *B, *INFO;
  LapackImpl__dgbsv(rmlA0, rmlA1, rmlA2, rmlA3, rmlA4, rmlA5, rmlA6, rmlA7, &AB, &IPIV, &B, &INFO);
  rmlA0 = AB;
  rmlA1 = IPIV;
  rmlA2 = B;
  rmlA3 = INFO;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgesvd)
{
  void *A, *S, *U, *VT, *WORK, *INFO;
  LapackImpl__dgesvd(rmlA0, rmlA1, rmlA2, rmlA3, rmlA4, rmlA5, rmlA6, rmlA7, rmlA8, rmlA9, &A, &S, &U, &VT, &WORK, &INFO);
  rmlA0 = A;
  rmlA1 = S;
  rmlA2 = U;
  rmlA3 = VT;
  rmlA4 = WORK;
  rmlA5 = INFO;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgetrf)
{
  void *A, *IPIV, *INFO;
  LapackImpl__dgetrf(rmlA0, rmlA1, rmlA2, rmlA3, &A, &IPIV, &INFO);
  rmlA0 = A;
  rmlA1 = IPIV;
  rmlA2 = INFO;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgetrs)
{
  void *B, *INFO;
  LapackImpl__dgetrs(rmlA0, rmlA1, rmlA2, rmlA3, rmlA4, rmlA5, rmlA6, rmlA7, &B, &INFO);
  rmlA0 = B;
  rmlA1 = INFO;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgetri)
{
  void *A, *WORK, *INFO;
  LapackImpl__dgetri(rmlA0, rmlA1, rmlA2, rmlA3, rmlA4, rmlA5, &A, &WORK, &INFO);
  rmlA0 = A;
  rmlA1 = WORK;
  rmlA2 = INFO;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgeqpf)
{
  void *A, *JPVT, *TAU, *INFO;
  LapackImpl__dgeqpf(rmlA0, rmlA1, rmlA2, rmlA3, rmlA4, rmlA5, &A, &JPVT, &TAU, &INFO);
  rmlA0 = A;
  rmlA1 = JPVT;
  rmlA2 = TAU;
  rmlA3 = INFO;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dorgqr)
{
  void *A, *WORK, *INFO;
  LapackImpl__dorgqr(rmlA0, rmlA1, rmlA2, rmlA3, rmlA4, rmlA5, rmlA6, rmlA7, &A, &WORK, &INFO);
  rmlA0 = A;
  rmlA1 = WORK;
  rmlA2 = INFO;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

