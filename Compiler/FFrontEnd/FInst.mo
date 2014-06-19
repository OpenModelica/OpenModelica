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

encapsulated package FInst
" file:        FInst.mo
  package:     FInst
  description: Graph based instantiation

  RCS: $Id: FInst 18987 2014-02-05 16:24:53Z adrpo $

"

// public imports
public
import Absyn;
import SCode;
import DAE;
import FCore;

protected
import Builtin;
import Env;
import FGraph;
import FExpand;
import FGraphBuild;
import FGraphDump;
import FGraphStream;
import System;
import InstUtil;
import Flags;
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
type ImportTable = FCore.ImportTable;
type Graph = FCore.Graph;
type Extra = FCore.Extra;
type Visited = FCore.Visited;
type Import = FCore.Import;

type Msg = Option<Absyn.Info>;


public function inst
"@author: adrpo
 instantiate path in program"
  input Absyn.Path inPath;
  input SCode.Program inProgram;
  output DAE.DAElist dae;
algorithm
  dae := matchcontinue(inPath, inProgram)
    local
      Graph g;
      SCode.Program p;
      list<Real> lst;

    case (_, _)
      equation
        p = doSCodeDep(inProgram, inPath);

        FGraphStream.start();

        lst = {};

        // enableTrace();
        System.startTimer();
        (_, g) = Builtin.initialFGraph(Env.emptyCache());
        g = FGraphBuild.mkProgramGraph(
                 p,
                 FCore.USERDEFINED(),
                 g);
        System.stopTimer();
        lst = List.consr(lst, System.getTimerIntervalTime());
        print("SCode->FGraph:  " +& realString(List.first(lst)) +& "\n");

        System.startTimer();
        // resolve all
        g = FExpand.all(g);
        System.stopTimer();
        lst = List.consr(lst, System.getTimerIntervalTime());

        print("FGraph nodes:   " +& intString(FGraph.lastId(g)) +& "\n");
        print("Total time:     " +& realString(List.fold(lst, realAdd, 0.0)) +& "\n");

        FGraphDump.dumpGraph(g, "F:\\dev\\" +& Absyn.pathString(inPath) +& ".graph.graphml");

        FGraphStream.finish();
      then
        DAE.emptyDae;

    case (_, _)
      equation
        print("FInst.inst failed!\n");
      then
        DAE.emptyDae;

  end matchcontinue;
end inst;

protected function doSCodeDep
"do or not do scode dependency based on a flag"
  input SCode.Program inProgram;
  input Absyn.Path inPath;
  output SCode.Program outProgram;
algorithm
  outProgram := matchcontinue(inProgram, inPath)
    case (_, _)
      equation
        true = Flags.isSet(Flags.GRAPH_INST_RUN_DEP);
        outProgram = InstUtil.scodeFlatten(inProgram, inPath);
      then
        outProgram;
    else inProgram;
  end matchcontinue;
end doSCodeDep;

end FInst;
