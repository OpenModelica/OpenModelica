/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2017, Open Source Modelica Consortium (OSMC),
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

encapsulated package AdjacencyMatrix

import BackendDAE;

protected
import Array;
import Debug;
import Flags;
import List;
import MetaModelica.Dangerous;

public function copyAdjacencyMatrix
  input Option<BackendDAE.AdjacencyMatrix> inAdjacencyMatrix;
  output Option<BackendDAE.AdjacencyMatrix> outAdjacencyMatrix;
algorithm
  outAdjacencyMatrix := match inAdjacencyMatrix
    local
      BackendDAE.AdjacencyMatrix m;

    case SOME(m) algorithm
      m := arrayCopy(m);
    then SOME(m);

    else NONE();
  end match;
end copyAdjacencyMatrix;

public function copyAdjacencyMatrixT = copyAdjacencyMatrix;

public function traverseAdjacencyMatrix<T>
  input BackendDAE.AdjacencyMatrix inM;
  input FuncType func;
  input T inTypeA;
  output BackendDAE.AdjacencyMatrix outM;
  output T outTypeA;
  partial function FuncType
    input BackendDAE.AdjacencyMatrixElement elem;
    input Integer pos;
    input T inTpl;
    output list<Integer> outList;
    output T outTpl;
  end FuncType;
algorithm
  (outM, outTypeA) := traverseAdjacencyMatrix1(inM, func, 1, arrayLength(inM), inTypeA);
end traverseAdjacencyMatrix;

protected function traverseAdjacencyMatrix1<T>
  input BackendDAE.AdjacencyMatrix inM;
  input FuncType func;
  input Integer pos "iterated 1..len";
  input Integer len "length of array";
  input T inTypeA;
  output BackendDAE.AdjacencyMatrix outM;
  output T outTypeA;
  partial function FuncType
    input BackendDAE.AdjacencyMatrixElement elem;
    input Integer pos;
    input T inTpl;
    output list<Integer> outList;
    output T outTpl;
  end FuncType;
algorithm
  (outM, outTypeA) := traverseAdjacencyMatrix2(inM, func, pos, len, intGt(pos, len), inTypeA);
  annotation(__OpenModelica_EarlyInline = true);
end traverseAdjacencyMatrix1;

protected function traverseAdjacencyMatrix2<T>
  input BackendDAE.AdjacencyMatrix inM;
  input FuncType func;
  input Integer pos "iterated 1..len";
  input Integer len "length of array";
  input Boolean stop;
  input T inTypeA;
  output BackendDAE.AdjacencyMatrix outM;
  output T outTypeA;
  partial function FuncType
    input BackendDAE.AdjacencyMatrixElement elem;
    input Integer pos;
    input T inTpl;
    output list<Integer> outList;
    output T outTpl;
  end FuncType;
algorithm
  (outM, outTypeA) := match (stop)
    local
      BackendDAE.AdjacencyMatrix m1, m2;
      T extArg, extArg1, extArg2;
      list<Integer> eqns, eqns1;

    case true
    then (inM, inTypeA);

    case false equation
      (eqns, extArg) = func(inM[pos], pos, inTypeA);
      eqns1 = List.removeOnTrue(pos, intLt, eqns);
      (m1, extArg1) = traverseAdjacencyMatrixList(eqns1, inM, func, arrayLength(inM), pos, extArg);
      (m2, extArg2) = traverseAdjacencyMatrix2(m1, func, pos+1, len, intGt(pos+1, len), extArg1);
    then (m2, extArg2);
  end match;
end traverseAdjacencyMatrix2;

protected function traverseAdjacencyMatrixList<T>
  input list<Integer> inLst "elements to traverse";
  input BackendDAE.AdjacencyMatrix inM;
  input FuncType func;
  input Integer len "length of array";
  input Integer maxpos "do not go further than this position";
  input T inTypeA;
  output BackendDAE.AdjacencyMatrix outM;
  output T outTypeA;
  partial function FuncType
    input BackendDAE.AdjacencyMatrixElement elem;
    input Integer pos;
    input T inTpl;
    output list<Integer> outList;
    output T outTpl;
  end FuncType;
algorithm
  (outM, outTypeA) := matchcontinue (inLst)
    local
      BackendDAE.AdjacencyMatrix m;
      T extArg, extArg1;
      list<Integer> rest, eqns, eqns1, alleqns;
      Integer pos;

    case ({})
    then (inM, inTypeA);

    case (pos::rest) equation
      // do not leave the list
      true = intLt(pos, len+1);
      // do not more than necesary
      true = intLt(pos, maxpos);
      (eqns, extArg) = func(inM[pos], pos, inTypeA);
      eqns1 = List.removeOnTrue(maxpos, intLt, eqns);
      alleqns = List.unionOnTrueList({rest, eqns1}, intEq);
      (m, extArg1) = traverseAdjacencyMatrixList(alleqns, inM, func, len, maxpos, extArg);
    then (m, extArg1);

    case (pos::rest) equation
      // do not leave the list
      true = intLt(pos, len+1);
      (m, extArg) = traverseAdjacencyMatrixList(rest, inM, func, len, maxpos, inTypeA);
    then (m, extArg);

    else equation
      true = Flags.isSet(Flags.FAILTRACE);
      Debug.trace("- BackendDAEOptimize.traverseAdjacencyMatrixList failed\n");
    then fail();
  end matchcontinue;
end traverseAdjacencyMatrixList;

public function getOtherEqSysAdjacencyMatrix
  "This function removes tvar and res from adjacency matrix."
  input BackendDAE.AdjacencyMatrix m;
  input Integer size;
  input Integer index;
  input array<Integer> skip;
  input array<Integer> rowskip;
  input BackendDAE.AdjacencyMatrix mnew;
  output BackendDAE.AdjacencyMatrix outMNew;
algorithm
  outMNew := match (m)
    local
      list<Integer> row;

    case (_) guard intGt(index, size)
    then mnew;

    case (_) guard intGt(skip[index], 0)
      equation
      row = list(r for r guard intGt(r,0) and intGt(rowskip[r], 0) in m[index]);
      arrayUpdate(mnew, index, row);
    then getOtherEqSysAdjacencyMatrix(m, size, index+1, skip, rowskip, mnew);

    case (_) equation
      arrayUpdate(mnew,index,{});
    then getOtherEqSysAdjacencyMatrix(m, size, index+1, skip, rowskip, mnew);
  end match;
end getOtherEqSysAdjacencyMatrix;

protected function isAssigned
  input array<Integer> ass;
  input Integer i;
  output Boolean b;
algorithm
  b := intGt(ass[i], 0);
end isAssigned;

public function transposeAdjacencyMatrix
  "Calculates the transpose of the adjacency matrix,
  i.e. which equations each variable is present in."
  input BackendDAE.AdjacencyMatrix m;
  input Integer nRowsMt;
  output BackendDAE.AdjacencyMatrixT mt;
protected
  Integer i = 1;
algorithm
  mt := arrayCreate(nRowsMt, {});
  for e in m loop
    (mt, i) := transposeRow(e, mt, i);
  end for;
end transposeAdjacencyMatrix;

protected function transposeRow "author: PA
  Helper function to transposeMatrix2.
  Input: BackendDAE.AdjacencyMatrix (eqn => var)
  Input: row number (variable)
  Input: iterator (start with one)
  inputs:  (int list list, int /* row */,int /* iter */)
  outputs:  int list"
  input list<Integer> row;
  input output BackendDAE.AdjacencyMatrixT mt;
  input output Integer indx;
algorithm
  (mt, indx) := match (row)
    local
      Integer i, indx1, iabs;
      list<Integer> res, col;

    case {}
    then (mt, indx+1);

    case i::res equation
      iabs = intAbs(i);
      mt = Array.expand(iabs - arrayLength(mt), mt, {});
      col = mt[iabs];
      indx1 = if intLt(i, 0) then -indx else indx;
      arrayUpdate(mt, iabs, indx1::col);
    then transposeRow(res, mt, indx);
  end match;
end transposeRow;

public function absAdjacencyMatrix "author: PA
  Applies absolute value to all entries in the adjacency matrix.
  This can be used when e.g. der(x) and x are considered the same variable."
  input BackendDAE.AdjacencyMatrix m;
  output BackendDAE.AdjacencyMatrix res;
protected
  list<list<Integer>> lst, lst_1;
  Integer i = 1;
  Integer minn;
algorithm
  res := Dangerous.arrayCreateNoInit(arrayLength(m),{});
  for v in m loop
    minn := List.fold(v,intMin,0);
    if minn < 0 then
      Dangerous.arrayUpdateNoBoundsChecking(res, i, List.map(v,intAbs));
    else
      Dangerous.arrayUpdateNoBoundsChecking(res, i, v);
    end if;
    i := i+1;
  end for;
end absAdjacencyMatrix;

public function isEmpty
  input BackendDAE.AdjacencyMatrix m;
  output Boolean b = true;
algorithm
  for element in m loop
    if not listEmpty(element) then
      b := false;
      return;
    end if;
  end for;
end isEmpty;

annotation(__OpenModelica_Interface="backend");
end AdjacencyMatrix;
