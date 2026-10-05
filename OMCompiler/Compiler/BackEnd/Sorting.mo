/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
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

public
import BackendDAE;

protected
import BackendDump;
import GCExt;
import Matching;

public function Tarjan "author: lochel
  This sorting algorithm only considers equations e that have a matched variable v with e = ass1[v]."
  input BackendDAE.AdjacencyMatrix m;
  input array<Integer> ass1 "eqn := ass1[var]";
  input Integer N = arrayLength(ass1);
  output list<list<Integer>> outComponents = {} "eqn indices";
protected
  Integer index = 0;
  list<Integer> stack = {};

  array<Integer> number, lowlink;
  array<Boolean> onStack;
  Integer eqn;
algorithm
  //BackendDump.dumpAdjacencyMatrix(m);
  //BackendDump.dumpMatchingVars(ass1);

  number := arrayCreate(N, -1);
  lowlink := arrayCreate(N, -1);
  onStack := arrayCreate(N, false);

  for var in 1:arrayLength(ass1) loop
    eqn := ass1[var];
    if eqn > 0 and number[eqn] == -1 then
      (stack, index, outComponents) := StrongConnect(m, ass1, eqn, stack, index, number, lowlink, onStack, outComponents);
    end if;
  end for;
  GCExt.free(number);
  GCExt.free(lowlink);
  GCExt.free(onStack);

  outComponents := listReverse(outComponents);
end Tarjan;

protected function StrongConnect "author: lochel"
  input BackendDAE.AdjacencyMatrix m;
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
  list<tuple<Integer, list<Integer>>> callStack = {} "(eqn, successors left to visit)";
  list<Integer> SCC, successors = {};
  Integer current = eqn, eqn2, parent;
  Boolean entering = true, descended;
algorithm
  while true loop
    if entering then
      entering := false;
      // Set the depth index for current to the smallest unused index
      arrayUpdate(number, current, outIndex);
      arrayUpdate(lowlink, current, outIndex);
      arrayUpdate(onStack, current, true);
      outIndex := outIndex + 1;
      outStack := current::outStack;
      successors := Matching.incomingEquations(current, m, ass1);
    end if;

    // Consider successors of current
    descended := false;
    while not listEmpty(successors) loop
      eqn2::successors := successors;
      if number[eqn2] == -1 then
        // Successor eqn2 has not yet been visited; descend into it
        callStack := (current, successors)::callStack;
        current := eqn2;
        entering := true;
        descended := true;
        break;
      elseif onStack[eqn2] then
        // Successor eqn2 is in the stack and hence in the current SCC
        arrayUpdate(lowlink, current, intMin(lowlink[current], number[eqn2]));
      end if;
    end while;

    if not descended then
      // If current is a root node, pop the stack and generate an SCC
      if lowlink[current] == number[current] then
        eqn2::outStack := outStack;
        arrayUpdate(onStack, eqn2, false);
        SCC := {eqn2};
        while current <> eqn2 loop
          eqn2::outStack := outStack;
          arrayUpdate(onStack, eqn2, false);
          SCC := eqn2::SCC;
        end while;
        outComponents := MetaModelica.Dangerous.listReverseInPlace(SCC)::outComponents;
      end if;

      if listEmpty(callStack) then
        break;
      end if;
      (parent, successors)::callStack := callStack;
      arrayUpdate(lowlink, parent, intMin(lowlink[parent], lowlink[current]));
      current := parent;
    end if;
  end while;
end StrongConnect;

public function TarjanTransposed "author: lochel
  This sorting algorithm only considers equations e with ass2[e] > 0."
  input BackendDAE.AdjacencyMatrixT mT;
  input array<Integer> ass2 "var := ass2[eqn]";
  output list<list<Integer>> outComponents = {} "eqn indices";
protected
  Integer index = 0;
  list<Integer> stack = {};

  array<Integer> number, lowlink;
  array<Boolean> onStack;
  Integer N = arrayLength(ass2);
algorithm
  //BackendDump.dumpAdjacencyMatrixT(mT);
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
  input BackendDAE.AdjacencyMatrixT mT;
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
  list<tuple<Integer, list<Integer>>> callStack = {} "(eqn, successors left to visit)";
  list<Integer> SCC, successors = {};
  Integer current = eqn, var, eqn2, parent;
  Boolean entering = true, descended;
algorithm
  while true loop
    if entering then
      entering := false;
      // Set the depth index for current to the smallest unused index
      arrayUpdate(number, current, outIndex);
      arrayUpdate(lowlink, current, outIndex);
      arrayUpdate(onStack, current, true);
      outIndex := outIndex + 1;
      outStack := current::outStack;

      var := ass2[current] "get the variable that is solved in given equation";
      successors := if var > 0 then list(e for e guard(e > 0 and e <> current) in mT[var]) else {};
    end if;

    // Consider successors of current
    descended := false;
    while not listEmpty(successors) loop
      eqn2::successors := successors;
      if number[eqn2] == -1 then
        // Successor eqn2 has not yet been visited; descend into it
        callStack := (current, successors)::callStack;
        current := eqn2;
        entering := true;
        descended := true;
        break;
      elseif onStack[eqn2] then
        // Successor eqn2 is in the stack and hence in the current SCC
        arrayUpdate(lowlink, current, intMin(lowlink[current], number[eqn2]));
      end if;
    end while;

    if not descended then
      // If current is a root node, pop the stack and generate an SCC
      if lowlink[current] == number[current] then
        eqn2::outStack := outStack;
        arrayUpdate(onStack, eqn2, false);
        SCC := {eqn2};
        while current <> eqn2 loop
          eqn2::outStack := outStack;
          arrayUpdate(onStack, eqn2, false);
          SCC := eqn2::SCC;
        end while;
        outComponents := MetaModelica.Dangerous.listReverseInPlace(SCC)::outComponents;
      end if;

      if listEmpty(callStack) then
        break;
      end if;
      (parent, successors)::callStack := callStack;
      arrayUpdate(lowlink, parent, intMin(lowlink[parent], lowlink[current]));
      current := parent;
    end if;
  end while;
end StrongConnectTransposed;

annotation(__OpenModelica_Interface="backend");
end Sorting;
