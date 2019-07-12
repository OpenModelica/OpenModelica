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

encapsulated package Matching "
  This package provides functions to compute perfect and martial matchings.
  It also provides some useful auxiliary functions."

import BackendDAE;
import BackendDAEFunc;
import DAE;

protected
import BackendDAEUtil;
import BackendVariable;
import Error;
import List;
import MetaModelica.Dangerous;

// =============================================================================
// just a matching algorithm
// - PerfectMatching
// - RegularMatching
// =============================================================================

public function PerfectMatching "
  This function fails if there is no perfect matching for the given system."
  input BackendDAE.IncidenceMatrix m;
  output array<Integer> ass1 "eqn := ass1[var]";
  output array<Integer> ass2 "var := ass2[eqn]";
protected
  Boolean perfectMatching;
  Integer N = arrayLength(m);
algorithm
  (ass1, ass2, true) := RegularMatching(m, N, N);
end PerfectMatching;

public function RegularMatching "
  function returns at least a partial matching, starting from scratch.
  Unmatched nodes are represented by -1."
  input BackendDAE.IncidenceMatrix m;
  input Integer nVars;
  input Integer nEqns;
  output array<Integer> ass1 "eqn := ass1[var]";
  output array<Integer> ass2 "var := ass2[eqn]";
  output Boolean outPerfectMatching;
algorithm
  ass1 := arrayCreate(nVars, -1);
  ass2 := arrayCreate(nEqns, -1);

  (ass1, ass2, outPerfectMatching) := ContinueMatching(m, nVars, nEqns, ass1, ass2);
end RegularMatching;

public function ContinueMatching "
  This function returns at least a partial matching, starting from a given
  partial matching. Unmatched nodes are represented by -1."
  input BackendDAE.IncidenceMatrix m;
  input Integer nVars;
  input Integer nEqns;
  input output array<Integer> ass1 "eqn := ass1[var]";
  input output array<Integer> ass2 "var := ass2[eqn]";
  output Boolean outPerfectMatching=true;
protected
  Integer i, j;
  array<Boolean> eMark, vMark;
  array<Integer> eMarkIx, vMarkIx;
  Integer eMarkN=0, vMarkN=0;
algorithm
  vMark := arrayCreate(nVars, false);
  eMark := arrayCreate(nEqns, false);
  vMarkIx := arrayCreate(nVars, 0);
  eMarkIx := arrayCreate(nEqns, 0);

  i := 1;
  while i<=nEqns and outPerfectMatching loop
    j := ass2[i];
    if (j>0 and ass1[j] == i) then
      outPerfectMatching :=true;
    else
      clearArrayWithKnownSetIndexes(eMark, eMarkIx, eMarkN);
      clearArrayWithKnownSetIndexes(vMark, vMarkIx, vMarkN);
      (outPerfectMatching,eMarkN,vMarkN) := PathFound(i, m, eMark, vMark, ass1, ass2, eMarkIx, vMarkIx, 0, 0);
    end if;
    i := i+1;
  end while;
end ContinueMatching;

public function Matching
  input BackendDAE.EqSystem inSys;
  input BackendDAE.Shared inShared;
  input Boolean clearMatching;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem outSys = inSys;
  output BackendDAE.Shared outShared = inShared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg = inArg;
protected
  Integer i;
  Boolean success = true;
  BackendDAE.IncidenceMatrix m;
  Integer nVars, nEqns, j;
  array<Integer> ass1, ass2;
  array<Boolean> eMark, vMark;
  array<Integer> eMarkIx, vMarkIx;
  Integer eMarkN=0, vMarkN=0;
  BackendDAE.EquationArray eqns;
  BackendDAE.Variables vars;
  list<Integer> mEqns;
algorithm
  //BackendDAE.EQSYSTEM(m=SOME(m), matching=BackendDAE.MATCHING(ass1=ass1, ass2=ass2)) := outSys;
  SOME(m) := outSys.m;
  nEqns := BackendDAEUtil.systemSize(outSys);
  nVars := BackendVariable.daenumVariables(outSys);
  // Be carefull, since matching may have been generated with not distinguishing between
  // state and their derivative, which leads to wrong traversing of bibartite graph!!!!
  //(ass1, ass2) := getAssignment(clearMatching, nVars, nEqns, inSys);
  //if clearMatching then
  ass2 := arrayCreate(nEqns, -1);
  ass1 := arrayCreate(nVars, -1);
  //CheapMatching(nEqns, m, ass1, ass2);
  //end if;
  vMark := arrayCreate(nVars, false);
  eMark := arrayCreate(nEqns, false);
  vMarkIx := arrayCreate(nVars, 0);
  eMarkIx := arrayCreate(nEqns, 0);
  i := 1;
  while i<=nEqns and success loop
    j := ass2[i];
    if ((j>0) and ass1[j] == i) then
      success :=true;
    else
      clearArrayWithKnownSetIndexes(eMark, eMarkIx, eMarkN);
      clearArrayWithKnownSetIndexes(vMark, vMarkIx, vMarkN);
      (success,eMarkN,vMarkN) := PathFound(i, m, eMark, vMark, ass1, ass2, eMarkIx, vMarkIx, 0, 0);
      if not success then
        mEqns := {};
        for j in 1:nEqns loop
          if eMark[j] then
            mEqns:=j::mEqns;
          end if;
        end for;
        (_, i, outSys, outShared, ass1, ass2, outArg) := sssHandler({mEqns}, i, outSys, outShared, ass1, ass2, outArg);
        SOME(m) := outSys.m;
        //nEqns := BackendDAEUtil.systemSize(outSys);
        //nVars := BackendVariable.daenumVariables(outSys);
        //ass1 := assignmentsArrayExpand(ass1, nVars, arrayLength(ass1), -1);
        //ass2 := assignmentsArrayExpand(ass2, nEqns, arrayLength(ass2), -1);
        //vMark := assignmentsArrayBooleanExpand(vMark, nVars, arrayLength(vMark), false);
        //eMark := assignmentsArrayBooleanExpand(eMark, nEqns, arrayLength(eMark), false);
        success := true;
        i := i-1;
      end if;
    end if;
    i := i+1;
  end while;
  if success then
    outSys := BackendDAEUtil.setEqSystMatching(outSys, BackendDAE.MATCHING(ass1, ass2, {}));
  else
    print("\nSingular System!!!\n");
  end if;
end Matching;

protected function PathFound
  input Integer i;
  input BackendDAE.IncidenceMatrix m;
  input array<Boolean> eMark;
  input array<Boolean> vMark;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input array<Integer> eMarkIx;
  input array<Integer> vMarkIx;
  output Boolean success=false;
  input output Integer eMarkN, vMarkN;
algorithm
  if arrayGet(eMark, i) then
    return;
  end if;
  arrayUpdate(eMark, i, true);
  eMarkN := eMarkN+1;
  arrayUpdate(eMarkIx, eMarkN, i);

  for j in m[i] loop
    // negative entries in adjacence matrix belong to states!!!
    if (j>0 and ass1[j] <= 0) then
      success := true;
      arrayUpdate(ass1, j, i);
      arrayUpdate(ass2, i, j);
      return;
    end if;
  end for;

  for j in m[i] loop
    // negative entries in adjacence matrix belong to states!!!
    if (j>0 and not vMark[j]) then
      arrayUpdate(vMark, j, true);
      vMarkN := vMarkN+1;
      arrayUpdate(vMarkIx, vMarkN, j);
      (success, eMarkN, vMarkN) := PathFound(ass1[j], m, eMark, vMark, ass1, ass2, eMarkIx, vMarkIx, eMarkN, vMarkN);
      if success then
        arrayUpdate(ass1, j, i);
        arrayUpdate(ass2, i, j);
        return;
      end if;
    end if;
  end for;
end PathFound;

protected function CheapMatching
  input Integer nEqns;
  input BackendDAE.IncidenceMatrix m;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
protected
  Integer i, j;
  Boolean success=false;
  list<Integer> vars;
algorithm
  for i in 1:nEqns loop
    vars := m[i];
    while not success and not listEmpty(vars) loop
      j::vars := vars;
      // negative entries in adjacence matrix belong to states!!!
      if (j>0 and ass1[j] <= 0) then
        success := true;
        arrayUpdate(ass1, j, i);
        arrayUpdate(ass2, i, j);
      end if;
    end while;
  end for;
end CheapMatching;

public function invertMatching "author: lochel
  ass1 <-> ass2"
  input array<Integer> inAss;
  output array<Integer> outAss;
protected
  Integer N = arrayLength(inAss);
  Integer j;
algorithm
  outAss := arrayCreate(N, -1);
  for i in 1:N loop
    j := inAss[i];
    if j > 0 then
      outAss[inAss[i]] := i;
    end if;
  end for;
end invertMatching;

public function reachableEquations "author: lochel
  Returns a list of reachable nodes (equations), corresponding
  to those equations that uses the solved variable of this equation.
  The edges of the graph that identifies strong components/blocks are
  dependencies between blocks. A directed edge e = (n1, n2) means
  that n1 solves for a variable (e.g. \'a\') that is used in the equation
  of n2, i.e. the equation of n1 must be solved before the equation of n2."
  input Integer eqn;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass2 "var := ass2[eqn]";
  output list<Integer> outEqNodes;
protected
  Integer var;
algorithm
  var := ass2[eqn] "get the variable that is solved in given equation";
  outEqNodes := if var > 0 then list(e for e guard(e > 0 and e <> eqn) in mT[var]) else {} "get the equations that depend on that variable";
end reachableEquations;

public function incomingEquations "author: lochel
  Returns a list of incoming nodes (equations), corresponding
  to those variables that occur in this equation."
  input Integer eqn;
  input BackendDAE.IncidenceMatrix m;
  input array<Integer> ass1 "eqn := ass1[var]";
  output list<Integer> outEqNodes;
algorithm
  outEqNodes := list(ass1[var] for var guard(var > 0 and ass1[var] <> eqn and ass1[var] > 0) in m[eqn]);
end incomingEquations;

public function isAssigned
"author: Frenkel TUD 2012-05"
  input array<Integer> ass;
  input Integer i;
  output Boolean b;
algorithm
  b := intGt(ass[intAbs(i)],0);
end isAssigned;

public function isUnAssigned
"author: Frenkel TUD 2012-05"
  input array<Integer> ass;
  input Integer i;
  output Boolean b;
algorithm
  b := intLt(ass[intAbs(i)],1);
end isUnAssigned;

public function getUnassigned "author: Frenkel TUD 2012-05
  return all Indices with ass[indx]<1, traverses the
  array from the ne element to the first."
  input Integer ne;
  input array<Integer> ass;
  input list<Integer> inUnassigned;
  output list<Integer> outUnassigned;
algorithm
  outUnassigned := match(ne,ass,inUnassigned)
    local
      list<Integer> unassigned;
    case (0,_,_)
      then
        inUnassigned;
    case (_,_,_)
      equation
        unassigned = List.consOnTrue(intLt(ass[ne],1), ne, inUnassigned);
      then
        getUnassigned(ne-1,ass,unassigned);
  end match;
end getUnassigned;

public function getAssigned
"author: Frenkel TUD 2012-05
  return all Indixes with ass[indx]>0, traverses the
  array from the ne element to the first."
  input Integer ne;
  input array<Integer> ass;
  input list<Integer> inAssigned;
  output list<Integer> outAssigned;
algorithm
  outAssigned := match(ne,ass,inAssigned)
    local
      list<Integer> assigned;
    case (0,_,_)
      then
        inAssigned;
    case (_,_,_)
      equation
        assigned = List.consOnTrue(intGt(ass[ne],0), ne, inAssigned);
      then
        getAssigned(ne-1,ass,assigned);
  end match;
end getAssigned;

protected function clearArrayWithKnownSetIndexes "Sets elements of arr in arrIx[1:n] to false; if n>0.3*size(arr), clear all of them"
  input array<Boolean> arr;
  input array<Integer> arrIx;
  input Integer n;
protected
  constant Boolean debug = false;
algorithm
  if n>0.3*arrayLength(arr) then
    for i in 1:arrayLength(arr) loop
      Dangerous.arrayUpdateNoBoundsChecking(arr, i, false);
    end for;
  else
    true := n <= arrayLength(arrIx);
    for i in 1:n loop
      Dangerous.arrayUpdate(arr, Dangerous.arrayGetNoBoundsChecking(arrIx, i), false);
    end for;
  end if;
  if debug then
    for e in 1:arrayLength(arr) loop
      Error.assertion(not arrayGet(arr,e), "clearArrayWithKnownSetIndexes failed: " + String(e) + " n=" + String(n)+" ixs="+stringDelimitList(list(String(arrayGet(arrIx,i)) for i in 1:n),","), sourceInfo());
    end for;
  end if;
end clearArrayWithKnownSetIndexes;

annotation(__OpenModelica_Interface="backend");
end Matching;
