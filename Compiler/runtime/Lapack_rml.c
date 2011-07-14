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
  void *A, *WR, *WI, *VL, *VR, *WORK;
  int INFO;
  LapackImpl__dgeev(RML_STRINGDATA(rmlA0), RML_STRINGDATA(rmlA1), RML_UNTAGFIXNUM(rmlA2), rmlA3, RML_UNTAGFIXNUM(rmlA4), RML_UNTAGFIXNUM(rmlA5), RML_UNTAGFIXNUM(rmlA6), rmlA7, RML_UNTAGFIXNUM(rmlA8), &A, &WR, &WI, &VL, &VR, &WORK, &INFO);
  rmlA0 = A;
  rmlA1 = WR;
  rmlA2 = WI;
  rmlA3 = VL;
  rmlA4 = VR;
  rmlA5 = WORK;
  rmlA6 = (void*)RML_TAGFIXNUM((long)INFO);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgegv)
{
  void *ALPHAR, *ALPHAI, *BETA, *VL, *VR, *WORK;
  int INFO;
  LapackImpl__dgegv(RML_STRINGDATA(rmlA0), RML_STRINGDATA(rmlA1), RML_UNTAGFIXNUM(rmlA2), rmlA3, RML_UNTAGFIXNUM(rmlA4), rmlA5, RML_UNTAGFIXNUM(rmlA6), RML_UNTAGFIXNUM(rmlA7), RML_UNTAGFIXNUM(rmlA8), rmlA9, RML_UNTAGFIXNUM(rmlA10), &ALPHAR, &ALPHAI, &BETA, &VL, &VR, &WORK, &INFO);
  rmlA0 = ALPHAR;
  rmlA1 = ALPHAI;
  rmlA2 = BETA;
  rmlA3 = VL;
  rmlA4 = VR;
  rmlA5 = WORK;
  rmlA6 = (void*)RML_TAGFIXNUM((long)INFO);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgels)
{
  void *A, *B, *WORK;
  int INFO;
  LapackImpl__dgels(RML_STRINGDATA(rmlA0), RML_UNTAGFIXNUM(rmlA1), RML_UNTAGFIXNUM(rmlA2), RML_UNTAGFIXNUM(rmlA3), rmlA4, RML_UNTAGFIXNUM(rmlA5), rmlA6, RML_UNTAGFIXNUM(rmlA7), rmlA8, RML_UNTAGFIXNUM(rmlA9), &A, &B, &WORK, &INFO);
  rmlA0 = A;
  rmlA1 = B;
  rmlA2 = WORK;
  rmlA3 = (void*)RML_TAGFIXNUM((long)INFO);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgelsx)
{
  void *A, *B, *JPVT;
  int RANK,INFO;
  LapackImpl__dgelsx(RML_UNTAGFIXNUM(rmlA0), RML_UNTAGFIXNUM(rmlA1), RML_UNTAGFIXNUM(rmlA2), rmlA3, RML_UNTAGFIXNUM(rmlA4), rmlA5, RML_UNTAGFIXNUM(rmlA6), rmlA7, rml_prim_get_real(rmlA8), rmlA9, RML_UNTAGFIXNUM(rmlA10), &A, &B, &JPVT, &RANK, &INFO);
  rmlA0 = A;
  rmlA1 = B;
  rmlA2 = JPVT;
  rmlA3 = (void*)RML_TAGFIXNUM((long)RANK);
  rmlA4 = (void*)RML_TAGFIXNUM((long)INFO);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgesv)
{
  void *A, *IPIV, *B;
  int INFO;
  LapackImpl__dgesv(RML_UNTAGFIXNUM(rmlA0), RML_UNTAGFIXNUM(rmlA1), rmlA2, RML_UNTAGFIXNUM(rmlA3), rmlA4, RML_UNTAGFIXNUM(rmlA5), &A, &IPIV, &B, &INFO);
  rmlA0 = A;
  rmlA1 = IPIV;
  rmlA2 = B;
  rmlA3 = (void*)RML_TAGFIXNUM((long)INFO);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgglse)
{
  void *A, *B, *C, *D, *X, *WORK;
  int INFO;
  LapackImpl__dgglse(RML_UNTAGFIXNUM(rmlA0), RML_UNTAGFIXNUM(rmlA1), RML_UNTAGFIXNUM(rmlA2), rmlA3, RML_UNTAGFIXNUM(rmlA4), rmlA5, RML_UNTAGFIXNUM(rmlA6), rmlA7, rmlA8, rmlA9, RML_UNTAGFIXNUM(rmlA10), &A, &B, &C, &D, &X, &WORK, &INFO);
  rmlA0 = A;
  rmlA1 = B;
  rmlA2 = C;
  rmlA3 = D;
  rmlA4 = X;
  rmlA5 = WORK;
  rmlA6 = (void*)RML_TAGFIXNUM((long)INFO);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgtsv)
{
  void *DL, *D, *DU, *B;
  int INFO;
  LapackImpl__dgtsv(RML_UNTAGFIXNUM(rmlA0), RML_UNTAGFIXNUM(rmlA1), rmlA2, rmlA3, rmlA4, rmlA5, RML_UNTAGFIXNUM(rmlA6), &DL, &D, &DU, &B, &INFO);
  rmlA0 = DL;
  rmlA1 = D;
  rmlA2 = DU;
  rmlA3 = B;
  rmlA4 = (void*)RML_TAGFIXNUM((long)INFO);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgbsv)
{
  void *AB, *IPIV, *B;
  int INFO;
  LapackImpl__dgbsv(RML_UNTAGFIXNUM(rmlA0), RML_UNTAGFIXNUM(rmlA1), RML_UNTAGFIXNUM(rmlA2), RML_UNTAGFIXNUM(rmlA3), rmlA4, RML_UNTAGFIXNUM(rmlA5), rmlA6, RML_UNTAGFIXNUM(rmlA7), &AB, &IPIV, &B, &INFO);
  rmlA0 = AB;
  rmlA1 = IPIV;
  rmlA2 = B;
  rmlA3 = (void*)RML_TAGFIXNUM((long)INFO);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgesvd)
{
  void *A, *S, *U, *VT, *WORK;
  int INFO;
  LapackImpl__dgesvd(RML_STRINGDATA(rmlA0), RML_STRINGDATA(rmlA1), RML_UNTAGFIXNUM(rmlA2), RML_UNTAGFIXNUM(rmlA3), rmlA4, RML_UNTAGFIXNUM(rmlA5), RML_UNTAGFIXNUM(rmlA6), RML_UNTAGFIXNUM(rmlA7), rmlA8, RML_UNTAGFIXNUM(rmlA9), &A, &S, &U, &VT, &WORK, &INFO);
  rmlA0 = A;
  rmlA1 = S;
  rmlA2 = U;
  rmlA3 = VT;
  rmlA4 = WORK;
  rmlA5 = (void*)RML_TAGFIXNUM((long)INFO);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgetrf)
{
  void *A, *IPIV;
  int INFO;
  LapackImpl__dgetrf(RML_UNTAGFIXNUM(rmlA0), RML_UNTAGFIXNUM(rmlA1), rmlA2, RML_UNTAGFIXNUM(rmlA3), &A, &IPIV, &INFO);
  rmlA0 = A;
  rmlA1 = IPIV;
  rmlA2 = (void*)RML_TAGFIXNUM((long)INFO);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgetrs)
{
  void *B;
  int INFO;
  LapackImpl__dgetrs(RML_STRINGDATA(rmlA0), RML_UNTAGFIXNUM(rmlA1), RML_UNTAGFIXNUM(rmlA2), rmlA3, RML_UNTAGFIXNUM(rmlA4), rmlA5, rmlA6, RML_UNTAGFIXNUM(rmlA7), &B, &INFO);
  rmlA0 = B;
  rmlA1 = (void*)RML_TAGFIXNUM((long)INFO);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgetri)
{
  void *A, *WORK;
  int INFO;
  LapackImpl__dgetri(RML_UNTAGFIXNUM(rmlA0), rmlA1, RML_UNTAGFIXNUM(rmlA2), rmlA3, rmlA4, RML_UNTAGFIXNUM(rmlA5), &A, &WORK, &INFO);
  rmlA0 = A;
  rmlA1 = WORK;
  rmlA2 = (void*)RML_TAGFIXNUM((long)INFO);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dgeqpf)
{
  void *A, *JPVT, *TAU;
  int INFO;
  LapackImpl__dgeqpf(RML_UNTAGFIXNUM(rmlA0), RML_UNTAGFIXNUM(rmlA1), rmlA2, RML_UNTAGFIXNUM(rmlA3), rmlA4, rmlA5, &A, &JPVT, &TAU, &INFO);
  rmlA0 = A;
  rmlA1 = JPVT;
  rmlA2 = TAU;
  rmlA3 = (void*)RML_TAGFIXNUM((long)INFO);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

RML_BEGIN_LABEL(Lapack__dorgqr)
{
  void *A, *WORK;
  int INFO;
  LapackImpl__dorgqr(RML_UNTAGFIXNUM(rmlA0), RML_UNTAGFIXNUM(rmlA1), RML_UNTAGFIXNUM(rmlA2), rmlA3, RML_UNTAGFIXNUM(rmlA4), rmlA5, rmlA6, RML_UNTAGFIXNUM(rmlA7), &A, &WORK, &INFO);
  rmlA0 = A;
  rmlA1 = WORK;
  rmlA2 = (void*)RML_TAGFIXNUM((long)INFO);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL;

