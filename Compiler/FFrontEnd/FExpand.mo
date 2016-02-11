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

encapsulated package FExpand
" file:        FExpand.mo
  package:     FExpand
  description: Expanding parts of the graph


"

// public imports
public
import Absyn;
import FCore;

protected
import System;
import FResolve;
import FGraph;
import List;

public
type Name = FCore.Name;
type Id = FCore.Id;
type Seq = FCore.Seq;
type Next = FCore.Next;
type Node = FCore.Node;
type Data = FCore.Data;
type Kind = FCore.Kind;
type Ref = FCore.Ref;
type Refs = FCore.Refs;
type Children = FCore.Children;
type Parents = FCore.Parents;
type Scope = FCore.Scope;
type ImportTable = FCore.ImportTable;
type Graph = FCore.Graph;
type Extra = FCore.Extra;
type Visited = FCore.Visited;
type Import = FCore.Import;
type Msg = Option<SourceInfo>;

public function path
"@author: adrpo
 expand a path in the graph."
  input Graph inGraph;
  input Absyn.Path inPath;
  output Graph outGraph;
  output Ref outRef;
algorithm
  (outGraph, outRef)  := match(inGraph, inPath)
    local
      Ref r, t;
      Name n;
      Absyn.Path p;
      Graph g;
      Scope s;

    case (g, _)
      equation
        t = FGraph.top(g);
        r = t;
      then
        (g, r);

  end match;
end path;

public function all
"@author: adrpo
 expand all references in the graph."
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph  := match(inGraph)
    local
      list<Real> lst;
      Graph g;

    case g
      equation
        lst = {};

        System.startTimer();
        // resolve extends
        g = FResolve.ext(FGraph.top(g), g);
        System.stopTimer();
        lst = List.consr(lst, System.getTimerIntervalTime());
        print("Extends:        " + realString(listHead(lst)) + "\n");

        System.startTimer();
        // resolve derived
        g = FResolve.derived(FGraph.top(g), g);
        System.stopTimer();
        lst = List.consr(lst, System.getTimerIntervalTime());
        print("Derived:        " + realString(listHead(lst)) + "\n");

        System.startTimer();
        // resolve type paths for constrain classes
        g = FResolve.cc(FGraph.top(g), g);
        System.stopTimer();
        lst = List.consr(lst, System.getTimerIntervalTime());
        print("ConstrainedBy:  " + realString(listHead(lst)) + "\n");

        System.startTimer();
        // resolve class extends nodes
        g = FResolve.clsext(FGraph.top(g), g);
        System.stopTimer();
        lst = List.consr(lst, System.getTimerIntervalTime());
        print("ClassExtends:   " + realString(listHead(lst)) + "\n");

        System.startTimer();
        // resolve type paths
        g = FResolve.ty(FGraph.top(g), g);
        System.stopTimer();
        lst = List.consr(lst, System.getTimerIntervalTime());
        print("ComponentTypes: " + realString(listHead(lst)) + "\n");

        System.startTimer();
        // resolve all component references
        g = FResolve.cr(FGraph.top(g), g);
        System.stopTimer();
        lst = List.consr(lst, System.getTimerIntervalTime());
        print("Comp Refs:      " + realString(listHead(lst)) + "\n");

        System.startTimer();
        // resolve all modifier lhs (thisOne = binding)
        g = FResolve.mod(FGraph.top(g), g);
        System.stopTimer();
        lst = List.consr(lst, System.getTimerIntervalTime());
        print("Modifiers:      " + realString(listHead(lst)) + "\n");

        print("FExpand.all:    " + realString(List.fold(lst, realAdd, 0.0)) + "\n");
      then
        g;

  end match;
end all;

annotation(__OpenModelica_Interface="frontend");
end FExpand;
