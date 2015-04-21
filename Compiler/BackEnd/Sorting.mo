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

encapsulated package Sorting
" file:        Sorting.mo
  package:     Sorting

  RCS: $Id$
"

public import BackendDAE;

protected import BackendDump;
protected import Debug;
protected import Error;
protected import List;
protected import Util;

public function Tarjan "author: lochel"
  input BackendDAE.IncidenceMatrix m;
  input array<Integer> ass1 "eqn := ass1[var]";
  output list<list<Integer>> outComponents = {} "eqn indices";
protected
  Integer index = 0;
  list<Integer> S = {};

  array<Integer> number, lowlink;
  array<Boolean> onStack;
  Integer N = arrayLength(ass1);
algorithm
  //BackendDump.dumpIncidenceMatrix(m);
  //BackendDump.dumpMatchingVars(ass1);

  number := arrayCreate(N, -1);
  lowlink := arrayCreate(N, -1);
  onStack := arrayCreate(N, false);

  for eqn in 1:N loop
    if number[eqn] == -1 then
      (S, index, outComponents) := StrongConnect(m, ass1, eqn, S, index, number, lowlink, onStack, outComponents);
    end if;
  end for;

  outComponents := listReverse(outComponents);
end Tarjan;

protected function StrongConnect "author: lochel"
  input BackendDAE.IncidenceMatrix m;
  input array<Integer> ass1 "eqn := ass1[var]";
  input Integer eqn;
  input list<Integer> S;
  input Integer index;
  input array<Integer> number;
  input array<Integer> lowlink;
  input array<Boolean> onStack;
  input list<list<Integer>> inComponents;
  output list<Integer> outS = S;
  output Integer outIndex = index;
  output list<list<Integer>> outComponents = inComponents;
protected
  list<Integer> SCC;
  Integer eqn2;
algorithm
  // Set the depth index for eqn to the smallest unused index
  arrayUpdate(number, eqn, outIndex);
  arrayUpdate(lowlink, eqn, outIndex);
  arrayUpdate(onStack, eqn, true);
  outIndex := outIndex + 1;
  outS := eqn::outS;

  // Consider successors of eqn
  for i in m[eqn] loop
    if i > 0 then // just consider positive items
      eqn2 := arrayGet(ass1, i);
      if eqn <> eqn2 then
        if number[eqn2] == -1 then
          // Successor eqn2 has not yet been visited; recurse on it
          (outS, outIndex, outComponents) := StrongConnect(m, ass1, eqn2, outS, outIndex, number, lowlink, onStack, outComponents);
          arrayUpdate(lowlink, eqn, intMin(lowlink[eqn], lowlink[eqn2]));
        elseif onStack[eqn2] then
          // Successor eqn2 is in stack S and hence in the current SCC
          arrayUpdate(lowlink, eqn, intMin(lowlink[eqn], number[eqn2]));
        end if;
      end if;
    end if;
  end for;

  // If eqn is a root node, pop the stack and generate an SCC
  if lowlink[eqn] == number[eqn] then
    eqn2::outS := outS;
    arrayUpdate(onStack, eqn2, false);
    SCC := {eqn2};
    while eqn <> eqn2 loop
      eqn2::outS := outS;
      arrayUpdate(onStack, eqn2, false);
      SCC := eqn2::SCC;
    end while;
    outComponents := SCC::outComponents;
  end if;
end StrongConnect;

public function TarjanTransposed "author: lochel"
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass2 "var := ass2[eqn]";
  output list<list<Integer>> outComponents = {} "eqn indices";
protected
  Integer index = 0;
  list<Integer> S = {};

  array<Integer> number, lowlink;
  array<Boolean> onStack;
  Integer N = arrayLength(ass2);
algorithm
  //BackendDump.dumpIncidenceMatrixT(mT);
  //BackendDump.dumpMatchingEqns(ass2);

  number := arrayCreate(N, -1);
  lowlink := arrayCreate(N, -1);
  onStack := arrayCreate(N, false);

  for eqn in 1:N loop
    if number[eqn] == -1 then
      (S, index, outComponents) := StrongConnectTransposed(mT, ass2, eqn, S, index, number, lowlink, onStack, outComponents);
    end if;
  end for;
end TarjanTransposed;

protected function StrongConnectTransposed "author: lochel"
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass2 "var := ass2[eqn]";
  input Integer eqn;
  input list<Integer> S;
  input Integer index;
  input array<Integer> number;
  input array<Integer> lowlink;
  input array<Boolean> onStack;
  input list<list<Integer>> inComponents;
  output list<Integer> outS = S;
  output Integer outIndex = index;
  output list<list<Integer>> outComponents = inComponents;
protected
  list<Integer> SCC;
  Integer var, eqn2;
algorithm
  // Set the depth index for eqn to the smallest unused index
  arrayUpdate(number, eqn, outIndex);
  arrayUpdate(lowlink, eqn, outIndex);
  arrayUpdate(onStack, eqn, true);
  outIndex := outIndex + 1;
  outS := eqn::outS;

  // Consider successors of eqn
  for eqn2 in reachableEquations(eqn, mT, ass2) loop
    if arrayGet(number, eqn2) == -1 then
      // Successor eqn2 has not yet been visited; recurse on it
      (outS, outIndex, outComponents) := StrongConnectTransposed(mT, ass2, eqn2, outS, outIndex, number, lowlink, onStack, outComponents);
      arrayUpdate(lowlink, eqn, intMin(lowlink[eqn], arrayGet(lowlink, eqn2)));
    elseif arrayGet(onStack, eqn2) then
      // Successor eqn2 is in stack S and hence in the current SCC
      arrayUpdate(lowlink, eqn, intMin(lowlink[eqn], arrayGet(number, eqn2)));
    end if;
  end for;

  // If eqn is a root node, pop the stack and generate an SCC
  if lowlink[eqn] == number[eqn] then
    eqn2::outS := outS;
    arrayUpdate(onStack, eqn2, false);
    SCC := {eqn2};
    while eqn <> eqn2 loop
      eqn2::outS := outS;
      arrayUpdate(onStack, eqn2, false);
      SCC := eqn2::SCC;
    end while;
    outComponents := listReverse(SCC)::outComponents;
  end if;
end StrongConnectTransposed;

public function TarjanOld "author: PA
  This is the second part of the BLT sorting. It takes the variable
  assignments and the incidence matrix as input and identifies strong
  components, i.e. subsystems of equations.

  inputs:  (BackendDAE.IncidenceMatrixT, int vector)
  outputs: (int list list /* list of components */ )"
  input BackendDAE.IncidenceMatrixT mt;
  input array<Integer> ass2 "ass[eqnindx]=varindx";
  output list<list<Integer>> outComps;
protected
  Integer n;
  list<list<Integer>> comps;
  array<Integer> number, lowlink;
  array<Boolean> stackflag;
algorithm
  try
    n := arrayLength(ass2);
    number := arrayCreate(n, 0);
    lowlink := arrayCreate(n, 0);
    stackflag := arrayCreate(n, false);
    (_, outComps) := StrongConnectOld(mt, ass2, number, lowlink, stackflag, n, 1, {}, {});
  else
    Error.addInternalError("TarjanOld failed
The sorting of the equations could not be done. (strongComponents failed)
Use +d=failtrace for more information.", sourceInfo());
    fail();
  end try;
end TarjanOld;

public function StrongConnectOld
  input BackendDAE.IncidenceMatrixT mt;
  input array<Integer> a2;
  input array<Integer> number;
  input array<Integer> lowlink;
  input array<Boolean> stackflag;
  input Integer n;
  input Integer inW;
  input list<Integer> istack;
  input list<list<Integer>> icomps;
  output list<Integer> ostack = istack;
  output list<list<Integer>> ocomps = icomps;
protected
  Integer w = inW;
algorithm
  while w <= n loop
    (ostack, ocomps) := strongConnectMain3(mt, a2, number, lowlink, stackflag, n, w, ostack, ocomps);
    w := w+1;
  end while;
end StrongConnectOld;

protected function strongConnectMain3
  input BackendDAE.IncidenceMatrixT mt;
  input array<Integer> a2;
  input array<Integer> number;
  input array<Integer> lowlink;
  input array<Boolean> stackflag;
  input Integer n;
  input Integer w;
  input list<Integer> istack;
  input list<list<Integer>> icomps;
  output list<Integer> ostack = istack;
  output list<list<Integer>> ocomps = icomps;
algorithm
  if intEq(number[w], 0) then
    (_, ostack, ocomps) := strongConnect(mt, a2, number, lowlink, stackflag, 0, w, ostack, ocomps);
  end if;
end strongConnectMain3;

protected function strongConnect "author: PA
  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int vector, int vector,
              int /* i */, int /* v */, int list /* stack */, int list list /* components */)
  outputs: (int /* i */, int list /* stack */, int list list /* components */ )"
  input BackendDAE.IncidenceMatrixT mt;
  input array<Integer> a2;
  input array<Integer> number;
  input array<Integer> lowlink;
  input array<Boolean> stackflag;
  input Integer i;
  input Integer v;
  input list<Integer> stack;
  input list<list<Integer>> comps;
  output Integer oi;
  output list<Integer> ostack;
  output list<list<Integer>> ocomps;
protected
  list<Integer> eqns;
  list<Integer> stack_2;
  list<list<Integer>> comps_1;
  list<Integer> comp;
algorithm
  try
    arrayUpdate(number, v, i+1);
    arrayUpdate(lowlink, v, i+1);
    arrayUpdate(stackflag, v, true);
    eqns := reachableEquations(v, mt, a2);
    (oi, stack_2, comps_1) := iterateReachableNodes(eqns, mt, a2, number, lowlink, stackflag, i+1, v, v::stack, comps);
    (ostack, comp) := checkRoot(v, stack_2, number, lowlink, stackflag);
    ocomps := consIfNonempty(comp, comps_1);
  else
    Debug.traceln("- BackendDAETransform.strongConnect failed for eqn " + intString(v));
    fail();
  end try;
end strongConnect;

protected function consIfNonempty "author: PA
  Small helper function to avoid empty sublists.
  Consider moving to Util?"
  input list<Integer> inIntegerLst;
  input list<list<Integer>> inIntegerLstLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  outIntegerLstLst := match (inIntegerLst)
    case {}
    then inIntegerLstLst;

    else inIntegerLst::inIntegerLstLst;
  end match;
end consIfNonempty;

public function reachableEquations "author: PA
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
  list<Integer> reachable;
algorithm
  var := ass2[eqn] "get the variable that is solved in given equation";
  reachable := if var > 0 then mT[var] else {} "get the equations that depend on that variable";
  reachable := List.select(reachable, Util.intGreaterZero) "just keep positive integers";
  outEqNodes := List.removeOnTrue(eqn, intEq, reachable);
end reachableEquations;

protected function iterateReachableNodes
  input list<Integer> eqns;
  input BackendDAE.IncidenceMatrixT mt;
  input array<Integer> a2;
  input array<Integer> number;
  input array<Integer> lowlink;
  input array<Boolean> stackflag;
  input Integer i;
  input Integer v;
  input list<Integer> istack;
  input list<list<Integer>> icomps;
  output Integer outI;
  output list<Integer> outStack;
  output list<list<Integer>> outComps;
algorithm
  (outI, outStack, outComps) := match (eqns)
    local
      Integer i1, w;
      list<Integer> stack, ws;
      list<list<Integer>> comps;

    case {}
    then (i, istack, icomps);

    case w::ws equation
      (i1, stack, comps) = iterateReachableNodes2(w, mt, a2, number, lowlink, stackflag, i, v, istack, icomps);
      (i1, stack, comps) = iterateReachableNodes(ws, mt, a2, number, lowlink, stackflag, i1, v, stack, comps);
    then (i1, stack, comps);
  end match;
end iterateReachableNodes;

protected function iterateReachableNodes2
  input Integer eqn;
  input BackendDAE.IncidenceMatrixT mt;
  input array<Integer> a2;
  input array<Integer> number;
  input array<Integer> lowlink;
  input array<Boolean> stackflag;
  input Integer i;
  input Integer v;
  input list<Integer> istack;
  input list<list<Integer>> icomps;
  output Integer outI = i;
  output list<Integer> outStack = istack;
  output list<list<Integer>> outComps = icomps;
protected
  Integer lv, lw, minv, nw, nv;
algorithm
  if intEq(number[eqn], 0) then
    (outI, outStack, outComps) := strongConnect(mt, a2, number, lowlink, stackflag, i, eqn, istack, icomps);
    lv := lowlink[v];
    lw := lowlink[eqn];
    minv := intMin(lv, lw);
    arrayUpdate(lowlink, v, minv);
  else
    nw := number[eqn];
    nv := lowlink[v];
    if nw < nv and stackflag[eqn] then
      arrayUpdate(lowlink, v, nw);
    end if;
  end if;
end iterateReachableNodes2;

protected function checkRoot "author: PA
  inputs:  (int /* v */, int list /* stack */, int vector, int vector)
  outputs: (int list /* stack */, int list /* comps */)"
  input Integer v;
  input list<Integer> istack;
  input array<Integer> number;
  input array<Integer> lowlink;
  input array<Boolean> stackflag;
  output list<Integer> ostack;
  output list<Integer> ocomps;
algorithm
  (ostack, ocomps) := matchcontinue (v)
    local
      Integer lv, nv;
      list<Integer> comps, stack;

    case _ equation
      lv = lowlink[v];
      nv = number[v];
      true = intEq(lv, nv);
      (stack, comps) = checkStack(nv, istack, number, stackflag, {});
    then (stack, comps);

    else (istack, {});
  end matchcontinue;
end checkRoot;

protected function checkStack "author: PA
  inputs:  (int /* vn */, int list /* stack */, int vector, int list /* component list */)
  outputs: (int list /* stack */, int list /* comps */)"
  input Integer vn;
  input list<Integer> istack;
  input array<Integer> number;
  input array<Boolean> stackflag;
  input list<Integer> icomp;
  output list<Integer> ostack;
  output list<Integer> ocomp;
algorithm
  (ostack, ocomp) := matchcontinue (istack)
    local
      Integer top;
      list<Integer> rest, comp, stack;

    case top::rest equation
      true = intGe(number[top], vn);
      arrayUpdate(stackflag, top, false);
      (stack, comp) = checkStack(vn, rest, number, stackflag, top :: icomp);
    then (stack, comp);

    else (istack, listReverse(icomp));
  end matchcontinue;
end checkStack;

annotation(__OpenModelica_Interface="backend");
end Sorting;
