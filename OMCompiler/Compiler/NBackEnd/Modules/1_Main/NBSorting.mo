/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2020, Open Source Modelica Consortium (OSMC),
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
encapsulated package NBSorting
"file:        NBSorting.mo
 package:     NBSorting
 description: This file contains the functions which perform the sorting process;
"

public
  import StrongComponent = NBStrongComponent;

protected
  import BEquation = NBEquation;
  import NBEquation.EquationPointers;
  import BVariable = NBVariable;
  import NBVariable.VariablePointers;
  import Adjacency = NBAdjacency;
  import Matching = NBMatching;

public
  function tarjan
    "author: kabdelhak
    Sorting algorithm for directed graphs by Robert E. Tarjan.
    First published in doi:10.1137/0201010"
    input Adjacency.Matrix adj;
    input Matching matching;
    input VariablePointers vars;
    input EquationPointers eqns;
    output list<StrongComponent> comps;
  algorithm
    comps := match (adj, matching)
      local
        list<list<Integer>> comps_indices;

      case (Adjacency.Matrix.SCALAR_ADJACENCY_MATRIX(), Matching.SCALAR_MATCHING()) algorithm
        comps_indices := tarjanScalar(adj.m, matching.var_to_eqn, matching.eqn_to_var);
        comps := list(StrongComponent.create(idx_lst, matching, vars, eqns) for idx_lst in comps_indices);
      then comps;

      case (Adjacency.Matrix.ARRAY_ADJACENCY_MATRIX(), Matching.ARRAY_MATCHING()) algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because array sorting is not yet supported."});
      then fail();

      case (Adjacency.Matrix.EMPTY_ADJACENCY_MATRIX(), Matching.EMPTY_MATCHING()) algorithm
      then {};

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because adjacency matrix and matching have different types."});
      then fail();
    end match;
  end tarjan;

  function tarjanScalar
    "author: lochel, kabdelhak
    This sorting algorithm only considers equations e that have a matched variable v with e = var_to_eqn[v]."
    input array<list<Integer>> m          "normal adjacency matrix";
    input array<Integer> var_to_eqn       "eqn := var_to_eqn[var]";
    input array<Integer> eqn_to_var       "var := eqn_to_var[eqn]";
    output list<list<Integer>> comps = {} "eqn indices";
  protected
    Integer index = 0;
    list<Integer> stack = {};
    array<Integer> number, lowlink;
    array<Boolean> onStack;
    Integer N = arrayLength(var_to_eqn);
    Integer M = arrayLength(eqn_to_var);
    Integer eqn;
  algorithm
    number := arrayCreate(M, -1);
    lowlink := arrayCreate(M, -1);
    onStack := arrayCreate(M, false);

    // loop over all variables and find their component
    for var in 1:N loop
      eqn := var_to_eqn[var];
      if eqn > 0 and number[eqn] == -1 then
        (stack, index, comps) := strongConnect(m, var_to_eqn, eqn, stack, index, number, lowlink, onStack, comps);
      end if;
    end for;

    // free auxiliary arrays
    GC.free(number);
    GC.free(lowlink);
    GC.free(onStack);

    // reverse for correct ordering
    comps := listReverse(comps);
  end tarjanScalar;

  protected function strongConnect
    "author: lochel, kabdelhak"
    input array<list<Integer>> m            "normal adjacency matrix";
    input array<Integer> var_to_eqn         "eqn := var_to_eqn[var]";
    input Integer eqn                       "current equation index";
    input output list<Integer> stack        "equation stack";
    input output Integer index              "component index";
    input array<Integer> number             "auxiliary array";
    input array<Integer> lowlink            "represents the component groups";
    input array<Boolean> onStack            "true if eqn index is on the stack";
    input output list<list<Integer>> comps  "accumulator for components";
  protected
    list<Integer> SCC;
    Integer eqn2;
  algorithm
    // Set the depth index for eqn to the smallest unused index
    arrayUpdate(number, eqn, index);
    arrayUpdate(lowlink, eqn, index);
    arrayUpdate(onStack, eqn, true);
    index := index + 1;
    stack := eqn::stack;

    // Consider successors of eqn
    for eqn2 in predecessors(eqn, m, var_to_eqn) loop
      if number[eqn2] == -1 then
        // Successor eqn2 has not yet been visited; recurse on it
        (stack, index, comps) := strongConnect(m, var_to_eqn, eqn2, stack, index, number, lowlink, onStack, comps);
        arrayUpdate(lowlink, eqn, intMin(lowlink[eqn], lowlink[eqn2]));
      elseif onStack[eqn2] then
        // Successor eqn2 is in the stack and hence in the current SCC
        arrayUpdate(lowlink, eqn, intMin(lowlink[eqn], number[eqn2]));
      end if;
    end for;

    // If eqn is a root node, pop the stack and generate an SCC
    if lowlink[eqn] == number[eqn] then
      eqn2::stack := stack;
      arrayUpdate(onStack, eqn2, false);
      SCC := {eqn2};
      while eqn <> eqn2 loop
        eqn2::stack := stack;
        arrayUpdate(onStack, eqn2, false);
        SCC := eqn2::SCC;
      end while;
      comps := MetaModelica.Dangerous.listReverseInPlace(SCC)::comps;
    end if;
  end strongConnect;

  function predecessors "author: lochel, kabdelhak
    Returns a list of incoming nodes, corresponding
    to the adjacency matrix"
    input Integer idx             "node index to get all predecessors for";
    input array<list<Integer>> m  "normal adjacency matrix";
    input array<Integer> mapping  "maps either var to eqn or eqn to var (matching)";
    output list<Integer> pre_lst  "all predecessors";
  algorithm
    pre_lst := list(mapping[cand] for cand guard(cand > 0 and mapping[cand] <> idx and mapping[cand] > 0) in m[idx]);
  end predecessors;

  annotation(__OpenModelica_Interface="backend");
end NBSorting;

