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

encapsulated package Coloring
" file:        Coloring.mo
  package:     Coloring
  description: Distance-2 graph coloring of sparsity patterns, used to compress
               the columns of analytic Jacobians. Operates purely on integer
               adjacency structures (no backend datatypes), so it is shared by
               both the old backend (SymbolicJacobian) and the new backend
               (NBJacobian) without either depending on the other.
"

protected
import Array;
import ExecStat.execStat;
import Error;
import Flags;
import GCExt;
import Graph;
import List;

public function createColoring
  input array<list<Integer>> sparseArray;
  input array<list<Integer>> sparseArrayT;
  input Integer sizeVars;
  input Integer sizeVarswithDep;
  output array<list<Integer>> coloredArray;
protected
  constant Boolean debug = false;
  list<Integer> nodesList;
  array<Integer> colored;
  array<Integer> forbiddenColor;
  list<tuple<Integer, list<Integer>>> sparseGraph, sparseGraphT;
  array<tuple<Integer, list<Integer>>> arraysparseGraph;
  Integer maxColor;
algorithm
  try
    // build up a bi-partied graph of pattern
    if Flags.isSet(Flags.DUMP_SPARSE_VERBOSE) then
      print("analytical Jacobians[SPARSE] -> build sparse graph.\n");
    end if;
    nodesList := List.intRange2(1,sizeVarswithDep);
    sparseGraph := Graph.buildGraph(nodesList,createBipartiteGraph,sparseArray);
    sparseGraphT := Graph.buildGraph(List.intRange2(1,sizeVars),createBipartiteGraph,sparseArrayT);

    // debug dump
    if Flags.isSet(Flags.DUMP_SPARSE_VERBOSE) then
      print("sparse graph: \n");
      Graph.printGraphInt(sparseGraph);
      print("transposed sparse graph: \n");
      Graph.printGraphInt(sparseGraphT);
      print("analytical Jacobians[SPARSE] -> builded graph for coloring.\n");
    end if;

    // color sparse bipartite graph
    forbiddenColor := arrayCreate(sizeVars,0);
    colored := arrayCreate(sizeVars,0);
    arraysparseGraph := listArray(sparseGraph);
    if debug then execStat("generateSparsePattern -> coloring start "); end if;
    if (sizeVars>0) then
      Graph.partialDistance2colorInt(sparseGraphT, forbiddenColor, nodesList, arraysparseGraph, colored);
    end if;
    if debug then execStat("generateSparsePattern -> coloring end "); end if;
    GCExt.free(forbiddenColor);
    GCExt.free(arraysparseGraph);
    // get max color used
    maxColor := Array.fold(colored, intMax, 0);

    // map index of that array into colors
    coloredArray := arrayCreate(maxColor, {});
    mapIndexColors(colored, sizeVars, coloredArray);
    GCExt.free(colored);

    if Flags.isSet(Flags.DUMP_SPARSE_VERBOSE) then
      print("Print Coloring Cols: \n");
      dumpColoring(arrayList(coloredArray));
    end if;
  else
    Error.addInternalError("function createColoring failed", sourceInfo());
    fail();
  end try;
end createColoring;

protected function createBipartiteGraph
  input Integer inNode;
  input array<list<Integer>> inSparsePattern;
  output list<Integer> outEdges = {};
algorithm
  if inNode >= 1 and inNode <= arrayLength(inSparsePattern)  then
    outEdges := arrayGet(inSparsePattern,inNode);
  else
    outEdges := {};
  end if;
end createBipartiteGraph;

protected function mapIndexColors
  input array<Integer> inColors;
  input Integer inMaxIndex;
  input array<list<Integer>> inArray;
protected
  Integer index;
algorithm
  try
    for i in 1:inMaxIndex loop
      index := arrayGet(inColors, i);
      arrayUpdate(inArray, index, i::arrayGet(inArray, index));
    end for;
  else
    Error.addInternalError("function mapIndexColors failed", sourceInfo());
    fail();
  end try;
end mapIndexColors;

protected function dumpColoring
  "Local equivalent of BackendDump.dumpSparsePattern for the verbose coloring
   dump. Kept here so this shared package does not depend on the old backend's
   BackendDump."
  input list<list<Integer>> pattern;
algorithm
  print("Print sparse pattern: " + intString(listLength(pattern)) + "\n");
  for row in pattern loop
    print("{" + stringDelimitList(List.map(row, intString), ", ") + "}\n");
  end for;
  print("\n");
end dumpColoring;

annotation(__OpenModelica_Interface="backend_util");
end Coloring;
