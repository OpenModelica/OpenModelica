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

"

public import BackendDAE;

protected import BackendDump;
protected import Matching;

public function Tarjan "author: lochel
  This sorting algorithm only considers equations e that have a matched variable v with e = ass1[v]."
  input BackendDAE.IncidenceMatrix m;
  input array<Integer> ass1 "eqn := ass1[var]";
  output list<list<Integer>> outComponents = {} "eqn indices";
protected
  Integer index = 0;
  list<Integer> stack = {};

  array<Integer> number, lowlink;
  array<Boolean> onStack;
  Integer N = arrayLength(ass1);
  Integer eqn;
algorithm
  //BackendDump.dumpIncidenceMatrix(m);
  //BackendDump.dumpMatchingVars(ass1);

  number := arrayCreate(N, -1);
  lowlink := arrayCreate(N, -1);
  onStack := arrayCreate(N, false);

  for var in 1:N loop
    eqn := ass1[var];
    if eqn > 0 and number[eqn] == -1 then
      (stack, index, outComponents) := StrongConnect(m, ass1, eqn, stack, index, number, lowlink, onStack, outComponents);
    end if;
  end for;

  outComponents := listReverse(outComponents);
end Tarjan;

protected function StrongConnect "author: lochel"
  input BackendDAE.IncidenceMatrix m;
  input array<Integer> ass1 "eqn := ass1[var]";
  input Integer eqn;
  input list<Integer> stack;
  input Integer index;
  input array<Integer> number;
  input array<Integer> lowlink;
  input array<Boolean> onStack;
  input list<list<Integer>> inComponents;
  output list<Integer> outStack = stack;
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
  outStack := eqn::outStack;

  // Consider successors of eqn
  for eqn2 in Matching.incomingEquations(eqn, m, ass1) loop
    if number[eqn2] == -1 then
      // Successor eqn2 has not yet been visited; recurse on it
      (outStack, outIndex, outComponents) := StrongConnect(m, ass1, eqn2, outStack, outIndex, number, lowlink, onStack, outComponents);
      arrayUpdate(lowlink, eqn, intMin(lowlink[eqn], lowlink[eqn2]));
    elseif onStack[eqn2] then
      // Successor eqn2 is in the stack and hence in the current SCC
      arrayUpdate(lowlink, eqn, intMin(lowlink[eqn], number[eqn2]));
    end if;
  end for;

  // If eqn is a root node, pop the stack and generate an SCC
  if lowlink[eqn] == number[eqn] then
    eqn2::outStack := outStack;
    arrayUpdate(onStack, eqn2, false);
    SCC := {eqn2};
    while eqn <> eqn2 loop
      eqn2::outStack := outStack;
      arrayUpdate(onStack, eqn2, false);
      SCC := eqn2::SCC;
    end while;
    outComponents := listReverse(SCC)::outComponents;
  end if;
end StrongConnect;

public function TarjanTransposed "author: lochel
  This sorting algorithm only considers equations e with ass2[e] > 0."
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass2 "var := ass2[eqn]";
  output list<list<Integer>> outComponents = {} "eqn indices";
protected
  Integer index = 0;
  list<Integer> stack = {};

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
    if number[eqn] == -1 and ass2[eqn] > 0 then
      (stack, index, outComponents) := StrongConnectTransposed(mT, ass2, eqn, stack, index, number, lowlink, onStack, outComponents);
    end if;
  end for;
end TarjanTransposed;

protected function StrongConnectTransposed "author: lochel"
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass2 "var := ass2[eqn]";
  input Integer eqn;
  input list<Integer> stack;
  input Integer index;
  input array<Integer> number;
  input array<Integer> lowlink;
  input array<Boolean> onStack;
  input list<list<Integer>> inComponents;
  output list<Integer> outStack = stack;
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
  outStack := eqn::outStack;

  // Consider successors of eqn
  for eqn2 in Matching.reachableEquations(eqn, mT, ass2) loop
    if number[eqn2] == -1 then
      // Successor eqn2 has not yet been visited; recurse on it
      (outStack, outIndex, outComponents) := StrongConnectTransposed(mT, ass2, eqn2, outStack, outIndex, number, lowlink, onStack, outComponents);
      arrayUpdate(lowlink, eqn, intMin(lowlink[eqn], lowlink[eqn2]));
    elseif onStack[eqn2] then
      // Successor eqn2 is in the stack and hence in the current SCC
      arrayUpdate(lowlink, eqn, intMin(lowlink[eqn], number[eqn2]));
    end if;
  end for;

  // If eqn is a root node, pop the stack and generate an SCC
  if lowlink[eqn] == number[eqn] then
    eqn2::outStack := outStack;
    arrayUpdate(onStack, eqn2, false);
    SCC := {eqn2};
    while eqn <> eqn2 loop
      eqn2::outStack := outStack;
      arrayUpdate(onStack, eqn2, false);
      SCC := eqn2::SCC;
    end while;
    outComponents := listReverse(SCC)::outComponents;
  end if;
end StrongConnectTransposed;

annotation(__OpenModelica_Interface="backend");
end Sorting;
