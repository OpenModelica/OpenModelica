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

public function TarjanTransposedPartial "author: lochel"
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass2 "var := ass2[eqn]";
  input array<Boolean> activeSet "only eqn nodes n with activeSet[n] == true are considered";
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
    if number[eqn] == -1 and activeSet[eqn] then
      (S, index, outComponents) := StrongConnectTransposedPartial(mT, ass2, activeSet, eqn, S, index, number, lowlink, onStack, outComponents);
    end if;
  end for;
end TarjanTransposedPartial;

protected function StrongConnectTransposedPartial "author: lochel"
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass2 "var := ass2[eqn]";
  input array<Boolean> activeSet "only eqn nodes n with activeSet[n] == true are considered";
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
    if arrayGet(number, eqn2) == -1 and arrayGet(activeSet, eqn2) then
      // Successor eqn2 has not yet been visited; recurse on it
      (outS, outIndex, outComponents) := StrongConnectTransposedPartial(mT, ass2, activeSet, eqn2, outS, outIndex, number, lowlink, onStack, outComponents);
      arrayUpdate(lowlink, eqn, intMin(lowlink[eqn], arrayGet(lowlink, eqn2)));
    elseif arrayGet(onStack, eqn2) and arrayGet(activeSet, eqn2) then
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
end StrongConnectTransposedPartial;

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

annotation(__OpenModelica_Interface="backend");
end Sorting;
