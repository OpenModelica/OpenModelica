/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package NFEvalFunctionExt

import Expression = NFExpression;

protected
import EvalFunction = NFEvalFunction;
import NFEvalFunction.assignVariable;
import Ceval = NFCeval;
import Type = NFType;
import Lapack;

public

function Lapack_dgeev
  input list<Expression> args;
protected
  Expression jobvl, jobvr, n, a, lda, ldvl, ldvr, work, lwork, wr, wi, vl, vr, info;
  Integer INFO, LDA, LDVL, LDVR, LWORK, N;
  String JOBVL, JOBVR;
  list<list<Real>> A, VL, VR;
  list<Real> WORK, WR, WI;
algorithm
  {jobvl, jobvr, n, a, lda, wr, wi, vl, ldvl, vr, ldvr, work, lwork, info} := args;

  JOBVL := evaluateExtStringArg(jobvl);
  JOBVR := evaluateExtStringArg(jobvr);
  N := evaluateExtIntArg(n);
  A := evaluateExtRealMatrixArg(a);
  LDA := evaluateExtIntArg(lda);
  LDVL := evaluateExtIntArg(ldvl);
  LDVR := evaluateExtIntArg(ldvr);
  WORK := evaluateExtRealArrayArg(work);
  LWORK := evaluateExtIntArg(lwork);

  (A, WR, WI, VL, VR, WORK, INFO) :=
    Lapack.dgeev(JOBVL, JOBVR, N, A, LDA, LDVL, LDVR, WORK, LWORK);

  assignVariableExt(a, Expression.makeRealMatrix(A));
  assignVariable(wr, Expression.makeRealArray(WR));
  assignVariable(wi, Expression.makeRealArray(WI));
  assignVariableExt(vl, Expression.makeRealMatrix(VL));
  assignVariableExt(vr, Expression.makeRealMatrix(VR));
  assignVariable(work, Expression.makeRealArray(WORK));
  assignVariable(info, Expression.makeInteger(INFO));
end Lapack_dgeev;

function Lapack_dgegv
  input list<Expression> args;
protected
  Expression jobvl, jobvr, n, a, lda, b, ldb, alphar, alphai;
  Expression beta, vl, ldvl, vr, ldvr, work, lwork, info;
  String JOBVL, JOBVR;
  Integer N, LDA, LDB, LDVL, LDVR, LWORK, INFO;
  list<list<Real>> A, B, VL, VR;
  list<Real> WORK, ALPHAR, ALPHAI, BETA;
algorithm
  {jobvl, jobvr, n, a, lda, b, ldb, alphar, alphai,
   beta, vl, ldvl, vr, ldvr, work, lwork, info} := args;

  JOBVL := evaluateExtStringArg(jobvl);
  JOBVR := evaluateExtStringArg(jobvr);
  N := evaluateExtIntArg(n);
  A := evaluateExtRealMatrixArg(a);
  LDA := evaluateExtIntArg(lda);
  B := evaluateExtRealMatrixArg(b);
  LDB := evaluateExtIntArg(ldb);
  LDVL := evaluateExtIntArg(ldvl);
  LDVR := evaluateExtIntArg(ldvr);
  WORK := evaluateExtRealArrayArg(work);
  LWORK := evaluateExtIntArg(lwork);

  (ALPHAR, ALPHAI, BETA, VL, VR, WORK, INFO) :=
    Lapack.dgegv(JOBVL, JOBVR, N, A, LDA, B, LDB, LDVL, LDVR, WORK, LWORK);

  assignVariable(alphar, Expression.makeRealArray(ALPHAR));
  assignVariable(alphai, Expression.makeRealArray(ALPHAI));
  assignVariable(beta, Expression.makeRealArray(BETA));
  assignVariableExt(vl, Expression.makeRealMatrix(VL));
  assignVariableExt(vr, Expression.makeRealMatrix(VR));
  assignVariable(work, Expression.makeRealArray(WORK));
  assignVariable(info, Expression.makeInteger(INFO));
end Lapack_dgegv;

function Lapack_dgels
  input list<Expression> args;
protected
  Expression trans, m, n, nrhs, a, lda, b, ldb, work, lwork, info;
  String TRANS;
  Integer M, N, NRHS, LDA, LDB, LWORK, INFO;
  list<list<Real>> A, B;
  list<Real> WORK;
algorithm
  {trans, m, n, nrhs, a, lda, b, ldb, work, lwork, info} := args;

  TRANS := evaluateExtStringArg(trans);
  M := evaluateExtIntArg(m);
  N := evaluateExtIntArg(n);
  NRHS := evaluateExtIntArg(nrhs);
  A := evaluateExtRealMatrixArg(a);
  LDA := evaluateExtIntArg(lda);
  B := evaluateExtRealMatrixArg(b);
  LDB := evaluateExtIntArg(ldb);
  WORK := evaluateExtRealArrayArg(work);
  LWORK := evaluateExtIntArg(lwork);

  (A, B, WORK, INFO) :=
    Lapack.dgels(TRANS, M, N, NRHS, A, LDA, B, LDB, WORK, LWORK);

  assignVariableExt(a, Expression.makeRealMatrix(A));
  assignVariableExt(b, Expression.makeRealMatrix(B));
  assignVariable(work, Expression.makeRealArray(WORK));
  assignVariable(info, Expression.makeInteger(INFO));
end Lapack_dgels;

function Lapack_dgelsx
  input list<Expression> args;
protected
  Expression m, n, nrhs, a, lda, b, ldb, jpvt, rcond, rank, work, info;
  Integer M, N, NRHS, LDA, LDB, RANK, INFO;
  list<list<Real>> A, B;
  list<Integer> JPVT;
  Real RCOND;
  list<Real> WORK;
algorithm
  if listLength(args) == 12 then
    {m, n, nrhs, a, lda, b, ldb, jpvt, rcond, rank, work, info} := args;
  else
    // Some older versions of the MSL calls dgelsx with an extra lwork argument.
    {m, n, nrhs, a, lda, b, ldb, jpvt, rcond, rank, work, _, info} := args;
  end if;

  M := evaluateExtIntArg(m);
  N := evaluateExtIntArg(n);
  NRHS := evaluateExtIntArg(nrhs);
  A := evaluateExtRealMatrixArg(a);
  LDA := evaluateExtIntArg(lda);
  B := evaluateExtRealMatrixArg(b);
  LDB := evaluateExtIntArg(ldb);
  JPVT := evaluateExtIntArrayArg(jpvt);
  RCOND := evaluateExtRealArg(rcond);
  WORK := evaluateExtRealArrayArg(work);

  (A, B, JPVT, RANK, INFO) :=
    Lapack.dgelsx(M, N, NRHS, A, LDA, B, LDB, JPVT, RCOND, WORK);

  assignVariableExt(a, Expression.makeRealMatrix(A));
  assignVariableExt(b, Expression.makeRealMatrix(B));
  assignVariable(jpvt, Expression.makeIntegerArray(JPVT));
  assignVariable(rank, Expression.makeInteger(RANK));
  assignVariable(info, Expression.makeInteger(INFO));
end Lapack_dgelsx;

function Lapack_dgelsy
  input list<Expression> args;
protected
  Expression m, n, nrhs, a, lda, b, ldb, jpvt, rcond, rank, work, lwork, info;
  Integer M, N, NRHS, LDA, LDB, RANK, LWORK, INFO;
  list<list<Real>> A, B;
  list<Integer> JPVT;
  Real RCOND;
  list<Real> WORK;
algorithm
  {m, n, nrhs, a, lda, b, ldb, jpvt, rcond, rank, work, lwork, info} := args;

  M := evaluateExtIntArg(m);
  N := evaluateExtIntArg(n);
  NRHS := evaluateExtIntArg(nrhs);
  A := evaluateExtRealMatrixArg(a);
  LDA := evaluateExtIntArg(lda);
  B := evaluateExtRealMatrixArg(b);
  LDB := evaluateExtIntArg(ldb);
  JPVT := evaluateExtIntArrayArg(jpvt);
  RCOND := evaluateExtRealArg(rcond);
  WORK := evaluateExtRealArrayArg(work);
  LWORK := evaluateExtIntArg(lwork);

  (A, B, JPVT, RANK, WORK, INFO) :=
    Lapack.dgelsy(M, N, NRHS, A, LDA, B, LDB, JPVT, RCOND, WORK, LWORK);

  assignVariableExt(a, Expression.makeRealMatrix(A));
  assignVariableExt(b, Expression.makeRealMatrix(B));
  assignVariable(jpvt, Expression.makeIntegerArray(JPVT));
  assignVariable(rank, Expression.makeInteger(RANK));
  assignVariable(work, Expression.makeRealArray(WORK));
  assignVariable(info, Expression.makeInteger(INFO));
end Lapack_dgelsy;

function Lapack_dgesv
  input list<Expression> args;
protected
  Expression n, nrhs, a, lda, ipiv, b, ldb, info;
  Integer N, NRHS, LDA, LDB, INFO;
  list<list<Real>> A, B;
  list<Integer> IPIV;
algorithm
  {n, nrhs, a, lda, ipiv, b, ldb, info} := args;

  N := evaluateExtIntArg(n);
  NRHS := evaluateExtIntArg(nrhs);
  A := evaluateExtRealMatrixArg(a);
  LDA := evaluateExtIntArg(lda);
  B := evaluateExtRealMatrixArg(b);
  LDB := evaluateExtIntArg(ldb);

  (A, IPIV, B, INFO) :=
    Lapack.dgesv(N, NRHS, A, LDA, B, LDB);

  assignVariableExt(a, Expression.makeRealMatrix(A));
  assignVariable(ipiv, Expression.makeIntegerArray(IPIV));
  assignVariableExt(b, Expression.makeRealMatrix(B));
  assignVariable(info, Expression.makeInteger(INFO));
end Lapack_dgesv;

function Lapack_dgglse
  input list<Expression> args;
protected
  Expression m, n, p, a, lda, b, ldb, c, d, x, work, lwork, info;
  Integer M, N, P, LDA, LDB, LWORK, INFO;
  list<list<Real>> A, B;
  list<Real> C, D, WORK, X;
algorithm
  {m, n, p, a, lda, b, ldb, c, d, x, work, lwork, info} := args;

  M := evaluateExtIntArg(m);
  N := evaluateExtIntArg(n);
  P := evaluateExtIntArg(p);
  A := evaluateExtRealMatrixArg(a);
  LDA := evaluateExtIntArg(lda);
  B := evaluateExtRealMatrixArg(b);
  LDB := evaluateExtIntArg(ldb);
  C := evaluateExtRealArrayArg(c);
  D := evaluateExtRealArrayArg(d);
  WORK := evaluateExtRealArrayArg(work);
  LWORK := evaluateExtIntArg(lwork);

  (A, B, C, D, X, WORK, INFO) :=
    Lapack.dgglse(M, N, P, A, LDA, B, LDB, C, D, WORK, LWORK);

  assignVariableExt(a, Expression.makeRealMatrix(A));
  assignVariableExt(b, Expression.makeRealMatrix(B));
  assignVariable(c, Expression.makeRealArray(C));
  assignVariable(d, Expression.makeRealArray(D));
  assignVariable(x, Expression.makeRealArray(X));
  assignVariable(work, Expression.makeRealArray(WORK));
  assignVariable(info, Expression.makeInteger(INFO));
end Lapack_dgglse;

function Lapack_dgtsv
  input list<Expression> args;
protected
  Expression n, nrhs, dl, d, du, b, ldb, info;
  Integer N, NRHS, LDB, INFO;
  list<Real> DL, D, DU;
  list<list<Real>> B;
algorithm
  {n, nrhs, dl, d, du, b, ldb, info} := args;

  N := evaluateExtIntArg(n);
  NRHS := evaluateExtIntArg(nrhs);
  DL := evaluateExtRealArrayArg(dl);
  D := evaluateExtRealArrayArg(d);
  DU := evaluateExtRealArrayArg(du);
  B := evaluateExtRealMatrixArg(b);
  LDB := evaluateExtIntArg(ldb);

  (DL, D, DU, B, INFO) :=
    Lapack.dgtsv(N, NRHS, DL, D, DU, B, LDB);

  assignVariable(dl, Expression.makeRealArray(DL));
  assignVariable(d, Expression.makeRealArray(D));
  assignVariable(du, Expression.makeRealArray(DU));
  assignVariableExt(b, Expression.makeRealMatrix(B));
  assignVariable(info, Expression.makeInteger(INFO));
end Lapack_dgtsv;

function Lapack_dgbsv
  input list<Expression> args;
protected
  Expression n, kl, ku, nrhs, ab, ldab, ipiv, b, ldb, info;
  Integer N, KL, KU, NRHS, LDAB, LDB, INFO;
  list<list<Real>> AB, B;
  list<Integer> IPIV;
algorithm
  {n, kl, ku, nrhs, ab, ldab, ipiv, b, ldb, info} := args;

  N := evaluateExtIntArg(n);
  KL := evaluateExtIntArg(kl);
  KU := evaluateExtIntArg(ku);
  NRHS := evaluateExtIntArg(nrhs);
  AB := evaluateExtRealMatrixArg(ab);
  LDAB := evaluateExtIntArg(ldab);
  B := evaluateExtRealMatrixArg(b);
  LDB := evaluateExtIntArg(ldb);

  (AB, IPIV, B, INFO) :=
    Lapack.dgbsv(N, KL, KU, NRHS, AB, LDAB, B, LDB);

  assignVariableExt(ab, Expression.makeRealMatrix(AB));
  assignVariable(ipiv, Expression.makeIntegerArray(IPIV));
  assignVariableExt(b, Expression.makeRealMatrix(B));
  assignVariable(info, Expression.makeInteger(INFO));
end Lapack_dgbsv;

function Lapack_dgesvd
  input list<Expression> args;
protected
  Expression jobu, jobvt, m, n, a, lda, s, u, ldu, vt, ldvt, work, lwork, info;
  String JOBU, JOBVT;
  Integer M, N, LDA, LDU, LDVT, LWORK, INFO;
  list<list<Real>> A, U, VT;
  list<Real> S, WORK;
algorithm
  {jobu, jobvt, m, n, a, lda, s, u, ldu, vt, ldvt, work, lwork, info} := args;

  JOBU := evaluateExtStringArg(jobu);
  JOBVT := evaluateExtStringArg(jobvt);
  M := evaluateExtIntArg(m);
  N := evaluateExtIntArg(n);
  A := evaluateExtRealMatrixArg(a);
  LDA := evaluateExtIntArg(lda);
  LDU := evaluateExtIntArg(ldu);
  LDVT := evaluateExtIntArg(ldvt);
  WORK := evaluateExtRealArrayArg(work);
  LWORK := evaluateExtIntArg(lwork);

  (A, S, U, VT, WORK, INFO) :=
    Lapack.dgesvd(JOBU, JOBVT, M, N, A, LDA, LDU, LDVT, WORK, LWORK);

  assignVariableExt(a, Expression.makeRealMatrix(A));
  assignVariable(s, Expression.makeRealArray(S));
  assignVariableExt(u, Expression.makeRealMatrix(U));
  assignVariableExt(vt, Expression.makeRealMatrix(VT));
  assignVariable(work, Expression.makeRealArray(WORK));
  assignVariable(info, Expression.makeInteger(INFO));
end Lapack_dgesvd;

function Lapack_dgetrf
  input list<Expression> args;
protected
  Expression m, n, a, lda, ipiv, info;
  Integer M, N, LDA, INFO;
  list<list<Real>> A;
  list<Integer> IPIV;
algorithm
  {m, n, a, lda, ipiv, info} := args;

  M := evaluateExtIntArg(m);
  N := evaluateExtIntArg(n);
  A := evaluateExtRealMatrixArg(a);
  LDA := evaluateExtIntArg(lda);

  (A, IPIV, INFO) :=
    Lapack.dgetrf(M, N, A, LDA);

  assignVariableExt(a, Expression.makeRealMatrix(A));
  assignVariable(ipiv, Expression.makeIntegerArray(IPIV));
  assignVariable(info, Expression.makeInteger(INFO));
end Lapack_dgetrf;

function Lapack_dgetrs
  input list<Expression> args;
protected
  Expression trans, n, nrhs, a, lda, ipiv, b, ldb, info;
  String TRANS;
  Integer N, NRHS, LDA, LDB, INFO;
  list<list<Real>> A, B;
  list<Integer> IPIV;
algorithm
  {trans, n, nrhs, a, lda, ipiv, b, ldb, info} := args;

  TRANS := evaluateExtStringArg(trans);
  N := evaluateExtIntArg(n);
  NRHS := evaluateExtIntArg(nrhs);
  A := evaluateExtRealMatrixArg(a);
  LDA := evaluateExtIntArg(lda);
  IPIV := evaluateExtIntArrayArg(ipiv);
  B := evaluateExtRealMatrixArg(b);
  LDB := evaluateExtIntArg(ldb);

  (B, INFO) :=
    Lapack.dgetrs(TRANS, N, NRHS, A, LDA, IPIV, B, LDB);

  assignVariableExt(b, Expression.makeRealMatrix(B));
  assignVariable(info, Expression.makeInteger(INFO));
end Lapack_dgetrs;

function Lapack_dgetri
  input list<Expression> args;
protected
  Expression n, a, lda, ipiv, work, lwork, info;
  Integer N, LDA, LWORK, INFO;
  list<list<Real>> A;
  list<Integer> IPIV;
  list<Real> WORK;
algorithm
  {n, a, lda, ipiv, work, lwork, info} := args;

  N := evaluateExtIntArg(n);
  A := evaluateExtRealMatrixArg(a);
  LDA := evaluateExtIntArg(lda);
  IPIV := evaluateExtIntArrayArg(ipiv);
  WORK := evaluateExtRealArrayArg(work);
  LWORK := evaluateExtIntArg(lwork);

  (A, WORK, INFO) :=
    Lapack.dgetri(N, A, LDA, IPIV, WORK, LWORK);

  assignVariableExt(a, Expression.makeRealMatrix(A));
  assignVariable(work, Expression.makeRealArray(WORK));
  assignVariable(info, Expression.makeInteger(INFO));
end Lapack_dgetri;

function Lapack_dgeqpf
  input list<Expression> args;
protected
  Expression m, n, a, lda, jpvt, tau, work, info;
  Integer M, N, LDA, INFO;
  list<list<Real>> A;
  list<Integer> JPVT;
  list<Real> WORK, TAU;
algorithm
  {m, n, a, lda, jpvt, tau, work, info} := args;

  M := evaluateExtIntArg(m);
  N := evaluateExtIntArg(n);
  A := evaluateExtRealMatrixArg(a);
  LDA := evaluateExtIntArg(lda);
  JPVT := evaluateExtIntArrayArg(jpvt);
  WORK := evaluateExtRealArrayArg(work);

  (A, JPVT, TAU, INFO) :=
    Lapack.dgeqpf(M, N, A, LDA, JPVT, WORK);

  assignVariableExt(a, Expression.makeRealMatrix(A));
  assignVariable(jpvt, Expression.makeIntegerArray(JPVT));
  assignVariable(tau, Expression.makeRealArray(TAU));
  assignVariable(info, Expression.makeInteger(INFO));
end Lapack_dgeqpf;

function Lapack_dorgqr
  input list<Expression> args;
protected
  Expression m, n, k, a, lda, tau, work, lwork, info;
  Integer M, N, K, LDA, LWORK, INFO;
  list<list<Real>> A;
  list<Real> TAU, WORK;
algorithm
  {m, n, k, a, lda, tau, work, lwork, info} := args;

  M := evaluateExtIntArg(m);
  N := evaluateExtIntArg(n);
  K := evaluateExtIntArg(k);
  A := evaluateExtRealMatrixArg(a);
  LDA := evaluateExtIntArg(lda);
  TAU := evaluateExtRealArrayArg(tau);
  WORK := evaluateExtRealArrayArg(work);
  LWORK := evaluateExtIntArg(lwork);

  (A, WORK, INFO) :=
    Lapack.dorgqr(M, N, K, A, LDA, TAU, WORK, LWORK);

  assignVariableExt(a, Expression.makeRealMatrix(A));
  assignVariable(work, Expression.makeRealArray(WORK));
  assignVariable(info, Expression.makeInteger(INFO));
end Lapack_dorgqr;

protected
function evaluateExtIntArg
  input Expression arg;
  output Integer value = getExtIntValue(Ceval.evalExp(arg));
end evaluateExtIntArg;

function getExtIntValue
  input Expression exp;
  output Integer value;
algorithm
  value := match exp
    case Expression.INTEGER() then exp.value;
    case Expression.EMPTY() then 0;
  end match;
end getExtIntValue;

function evaluateExtRealArg
  input Expression arg;
  output Real value = getExtRealValue(Ceval.evalExp(arg));
end evaluateExtRealArg;

function getExtRealValue
  input Expression exp;
  output Real value;
algorithm
  value := match exp
    case Expression.REAL() then exp.value;
    case Expression.EMPTY() then 0.0;
  end match;
end getExtRealValue;

function evaluateExtStringArg
  input Expression arg;
  output String value = getExtStringValue(Ceval.evalExp(arg));
end evaluateExtStringArg;

function getExtStringValue
  input Expression exp;
  output String value;
algorithm
  value := match exp
    case Expression.STRING() then exp.value;
    case Expression.EMPTY() then "";
  end match;
end getExtStringValue;

function evaluateExtIntArrayArg
  input Expression arg;
  output list<Integer> value;
protected
  list<Expression> expl;
algorithm
  expl := Expression.arrayElementList(Ceval.evalExp(arg));
  value := list(getExtIntValue(e) for e in expl);
end evaluateExtIntArrayArg;

function evaluateExtRealArrayArg
  input Expression arg;
  output list<Real> value;
protected
  list<Expression> expl;
algorithm
  expl := Expression.arrayElementList(Ceval.evalExp(arg));
  value := list(getExtRealValue(e) for e in expl);
end evaluateExtRealArrayArg;

function evaluateExtRealMatrixArg
  input Expression arg;
  output list<list<Real>> value;
protected
  array<Expression> expl;
  Type ty;
algorithm
  Expression.ARRAY(ty = ty, elements = expl) := Ceval.evalExp(arg);

  // Some external functions don't make a difference between vectors and
  // matrices, so if the argument is a vector we convert it into a matrix.
  value := match Type.dimensionCount(ty)
    case 1
      then list({getExtRealValue(e)} for e in expl);
    case 2
      then list(list(getExtRealValue(e) for e in Expression.arrayElements(row))
                for row in expl);
  end match;
end evaluateExtRealMatrixArg;

function assignVariableExt
  "Some external functions doesn't differentiate between vector and matrices, so
   we might get back a Nx1 matrix when expecting a vector. In that case it needs
   to be converted back into a vector before assigning the variable. Otherwise
   this function just calls assignVariable, so it's only needed for matrix
   arguments."
  input Expression variable;
  input Expression value;
protected
  Expression exp;
algorithm
  exp := match (Expression.typeOf(variable), value)
    // Vector variable, matrix value => convert value to vector.
    case (Type.ARRAY(dimensions = {_}),
          Expression.ARRAY(ty = Type.ARRAY(dimensions = {_, _})))
      then Expression.makeArray(Type.unliftArray(value.ty),
                                listArray(list(Expression.arrayScalarElement(e) for e in value.elements)),
                                literal = true);

    else value;
  end match;

  assignVariable(variable, exp);
end assignVariableExt;

annotation(__OpenModelica_Interface="frontend");
end NFEvalFunctionExt;

