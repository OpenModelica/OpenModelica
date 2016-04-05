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

encapsulated package ResolveLoops
" file:        ResolveLoops.mo
  package:     ResolveLoops
  description: This package contains functions for the optimization module
               resolveLoops."


public import BackendDAE;
public import DAE;

protected import Array;
protected import BackendDAEUtil;
protected import BackendEquation;
protected import BackendVariable;
protected import BackendDump;
protected import ComponentReference;
protected import Expression;
protected import ExpressionSimplify;
protected import ExpressionSolve;
protected import ExpressionDump;
protected import Flags;
protected import HpcOmEqSystems;
protected import HpcOmTaskGraph;
protected import List;
protected import Util;
protected import Tearing;

public function resolveLoops "author:Waurich TUD 2013-12
  traverses the equations and finds simple equations(i.e. linear functions
  withcoefficients of 1 or -1). if these equations form loops, they will be
  contracted.
  This happens especially in eletrical models. Here, kirchhoffs voltage and
  current law can be applied."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystems eqSysts;
  BackendDAE.Shared shared;
algorithm
  (eqSysts, shared, _) := List.mapFold2(inDAE.eqs, resolveLoops_main, inDAE.shared, 1);
  outDAE := BackendDAE.DAE(eqSysts, shared);
end resolveLoops;

protected function resolveLoops_main "author: Waurich TUD 2014-01
  Collects the linear equations of the whole DAE. bipartite graphs of the
  eqSystem can be output. All variables and equations which do not belong to a
  loop will be removed. the loops will be analysed and resolved"
  input BackendDAE.EqSystem inEqSys;
  input BackendDAE.Shared inShared "unused, just for dumping graphml";
  input Integer inSysIdx;
  output BackendDAE.EqSystem outEqSys;
  output BackendDAE.Shared outShared = inShared "unused";
  output Integer outSysIdx;
algorithm
  (outEqSys, outSysIdx) := matchcontinue(inEqSys)
    local
      Integer numSimpEqs, numVars, numSimpVars;
      list<Integer> eqMapping, varMapping, nonLoopVarIdcs, nonLoopEqIdcs, loopEqIdcs, loopVarIdcs, eqCrossLst, varCrossLst;
      list<list<Integer>> partitions, loops;
      list<tuple<Boolean,String>> varAtts,eqAtts;
      BackendDAE.Variables vars,simpVars;
      BackendDAE.EquationArray eqs,simpEqs;
      BackendDAE.EqSystem eqSys;
      BackendDAE.IncidenceMatrix m,mT,m_cut, mT_cut, m_after, mT_after;
      BackendDAE.Matching matching;
      BackendDAE.StateSets stateSets;
      list<DAE.ComponentRef> crefs;
      list<BackendDAE.Equation> eqLst,simpEqLst,resolvedEqs;
      list<BackendDAE.Var> varLst,simpVarLst;
      BackendDAE.EqSystem syst;

    case syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqs)
      equation
      eqLst = BackendEquation.equationList(eqs);
      varLst = BackendVariable.varList(vars);

      // build the incidence matrix for the whole System
      //numSimpEqs = listLength(eqLst);
      //numVars = listLength(varLst);
      //(m,mT) = BackendDAEUtil.incidenceMatrixDispatch(vars,eqs, BackendDAE.ABSOLUTE());
      BackendDump.dumpBipartiteGraphEqSystem(syst,inShared, "whole System_"+intString(inSysIdx));
        //BackendDump.dumpEquationArray(eqs,"the complete DAE");

      // get the linear equations and their vars
      simpEqLst = BackendEquation.traverseEquationArray(eqs, getSimpleEquations, {});
      eqMapping = List.map1(simpEqLst,List.position,eqLst);
      simpEqs = BackendEquation.listEquation(simpEqLst);
      crefs = BackendEquation.getAllCrefFromEquations(simpEqs);
      (simpVarLst,varMapping) = BackendVariable.getVarLst(crefs,vars,{},{});
      simpVars = BackendVariable.listVar1(simpVarLst);

      // build the incidence matrix for the linear equations
      numSimpEqs = listLength(simpEqLst);
      numVars = listLength(simpVarLst);
      (m,mT) = BackendDAEUtil.incidenceMatrixDispatch(simpVars,simpEqs, BackendDAE.ABSOLUTE());

      varAtts = List.threadMap(List.fill(false,numVars),List.fill("",numVars),Util.makeTuple);
      eqAtts = List.threadMap(List.fill(false,numSimpEqs),List.fill("",numSimpEqs),Util.makeTuple);
      BackendDump.dumpBipartiteGraphStrongComponent2(simpVars,simpEqs,m,varAtts,eqAtts,"rL_simpEqs_"+intString(inSysIdx));

      //partition graph
      partitions = arrayList(partitionBipartiteGraph(m,mT));
      partitions = List.filterOnTrue(partitions,List.hasSeveralElements);
        //print("the partitions for system "+intString(inSysIdx)+" : \n"+stringDelimitList(List.map(partitions,HpcOmTaskGraph.intLstString),"\n")+"\n");

      // cut the deadends (vars and eqs outside of the loops)
      m_cut = arrayCopy(m);
      mT_cut = arrayCopy(mT);
      (_,_,nonLoopEqIdcs,_) = resolveLoops_cutNodes(m_cut,mT_cut,eqMapping,varMapping,varLst,eqLst);

      varAtts = List.threadMap(List.fill(false,numVars),List.fill("",numVars),Util.makeTuple);
      eqAtts = List.threadMap(List.fill(false,numSimpEqs),List.fill("",numSimpEqs),Util.makeTuple);
      BackendDump.dumpBipartiteGraphStrongComponent2(simpVars,simpEqs,m_cut,varAtts,eqAtts,"rL_loops_"+intString(inSysIdx));

      // handle the partitions separately, resolve the loops in the partitions, insert the resolved equation
      eqLst = resolveLoops_resolvePartitions(partitions,m_cut,mT_cut,m,mT,eqMapping,varMapping,eqLst,varLst,nonLoopEqIdcs);
      syst.orderedEqs = BackendEquation.listEquation(eqLst);
        //BackendDump.dumpEquationList(eqLst,"the complete DAE after resolving");

      // get the graphML for the resolved System
      simpEqLst = List.map1(eqMapping,List.getIndexFirst,eqLst);
      simpEqs = BackendEquation.listEquation(simpEqLst);
      numSimpEqs = listLength(simpEqLst);
      numVars = listLength(simpVarLst);
      m_after = BackendDAEUtil.incidenceMatrixDispatch(simpVars,simpEqs, BackendDAE.ABSOLUTE());

      varAtts = List.threadMap(List.fill(false,numVars),List.fill("",numVars),Util.makeTuple);
      eqAtts = List.threadMap(List.fill(false,numSimpEqs),List.fill("",numSimpEqs),Util.makeTuple);
      BackendDump.dumpBipartiteGraphStrongComponent2(simpVars,simpEqs,m_after,varAtts,eqAtts,"rL_after_"+intString(inSysIdx));

      eqSys = BackendDAEUtil.clearEqSyst(syst);
    then (eqSys, inSysIdx+1);

    else (inEqSys, inSysIdx+1);
  end matchcontinue;
end resolveLoops_main;

protected function resolveLoops_resolvePartitions "author:Waurich TUD 2014-02
  checks every partition for loops and resolves them if its worth to."
  input list<list<Integer>> partitionsIn;
  input BackendDAE.IncidenceMatrix mIn;
  input BackendDAE.IncidenceMatrixT mTIn;
  input BackendDAE.IncidenceMatrix m_uncut;
  input BackendDAE.IncidenceMatrixT mT_uncut;
  input list<Integer> eqMapping;
  input list<Integer> varMapping;
  input list<BackendDAE.Equation> daeEqs;
  input list<BackendDAE.Var> daeVars;
  input list<Integer> nonLoopEqs;
  output list<BackendDAE.Equation> eqLstOut;
algorithm
  eqLstOut := matchcontinue(partitionsIn,mIn,mTIn,m_uncut,mT_uncut,eqMapping,varMapping,daeEqs,daeVars,nonLoopEqs)
    local
      list<Integer> partition, eqCrossLst, varCrossLst;
      list<list<Integer>> rest, loops;
      list<BackendDAE.Equation> eqLst;
    case(partition::rest,_,_,_,_,_,_,_,_,_)
      equation
        (_,partition,_) = List.intersection1OnTrue(partition,nonLoopEqs,intEq);
        true = listEmpty(partition);
        eqLst = resolveLoops_resolvePartitions(rest,mIn,mTIn,m_uncut,mT_uncut,eqMapping,varMapping,daeEqs,daeVars,nonLoopEqs);
    then
      eqLst;
    case(partition::rest,_,_,_,_,_,_,_,_,_)
      equation
        // search the partitions for loops
        (_,partition,_) = List.intersection1OnTrue(partition,nonLoopEqs,intEq);
        //print("\nanalyse the partition "+stringDelimitList(List.map(partition,intString),",")+"\n");
        (loops,eqCrossLst,varCrossLst) = resolveLoops_findLoops({partition},mIn,mTIn);
        loops = List.filterOnFalse(loops,listEmpty);
        //print("the loops in this partition: \n"+stringDelimitList(List.map(loops,HpcOmTaskGraph.intLstString),"\n")+"\n");

        // check if its worth to resolve the loops
        loops = List.filter1OnTrue(loops,evaluateLoop,(m_uncut,mT_uncut,eqCrossLst));
        //print("the loops that will be resolved: \n"+stringDelimitList(List.map(loops,HpcOmTaskGraph.intLstString),"\n")+"\n");
        // resolve the loops
        (eqLst,_) = resolveLoops_resolveAndReplace(loops,eqCrossLst,varCrossLst,mIn,mTIn,eqMapping,varMapping,daeEqs,daeVars,{});
        eqLst = resolveLoops_resolvePartitions(rest,mIn,mTIn,m_uncut,mT_uncut,eqMapping,varMapping,eqLst,daeVars,nonLoopEqs);
      then
        eqLst;
    case({},_,_,_,_,_,_,_,_,_)
      equation
      then
        daeEqs;
  end matchcontinue;
end resolveLoops_resolvePartitions;

protected function resolveLoops_cutNodes "author: Waurich TUD 2014-01
  cut the deadend nodes from the partitions"
  input BackendDAE.IncidenceMatrix mIn;
  input BackendDAE.IncidenceMatrix mTIn;
  input list<Integer> eqMapping;
  input list<Integer> varMapping;
  input list<BackendDAE.Var> daeVarsIn;
  input list<BackendDAE.Equation> daeEqsIn;
  output list<Integer> loopEqsOut;
  output list<Integer> loopVarsOut;
  output list<Integer> nonLoopVarsOut;
  output list<Integer> nonLoopEqsOut;
algorithm
  (loopEqsOut,loopVarsOut,nonLoopVarsOut,nonLoopEqsOut) := matchcontinue(mIn,mTIn,eqMapping,varMapping,daeVarsIn,daeEqsIn)
   local
     Integer numVars, numEqs;
     list<Integer> partition, loopVars, loopEqs, nonLoopVars, nonLoopEqs, eqCrossLst, varCrossLst;
     list<list<Integer>>  restPartitions, loopVarLst;
     list<BackendDAE.Equation> eqLst;
     list<BackendDAE.Var> varLst;
   case(_,_,_,_,_,_)
     equation
       // get the deadEnd equations and variables
       numVars = arrayLength(mTIn);
       nonLoopVars = List.filter2OnTrue(List.intRange(numVars),arrayEntryLengthIs,mTIn,1);
       (nonLoopEqs,nonLoopVars) = getDeadEndsInBipartiteGraph(nonLoopVars,mIn,mTIn,{},nonLoopVars);

       // get the eqs inside and outside the loop
       numEqs = arrayLength(mIn);
       (nonLoopEqs,loopEqs,_) = List.intersection1OnTrue(List.intRange(numEqs),nonLoopEqs,intEq);

       loopVarLst = List.map1(loopEqs,Array.getIndexFirst,mIn);
       loopVars = List.flatten(loopVarLst);
       loopVars = List.unique(loopVars);
       (nonLoopVars,loopVars,_) = List.intersection1OnTrue(loopVars,nonLoopVars,intEq);

       // remove nonLoopNodes from the incidenceMatrix
       List.map2_0(nonLoopVars,Array.updateIndexFirst,{},mTIn);
       List.map2_0(nonLoopEqs,Array.updateIndexFirst,{},mIn);
       List.map2_0(loopVars,arrayGetDeleteInLst,nonLoopEqs,mTIn);
       List.map2_0(loopEqs,arrayGetDeleteInLst,nonLoopVars,mIn);
   then
     (loopEqs,loopVars,nonLoopEqs,nonLoopVars);
    else
      equation
        print("resolveLoops_cutNodes failed\n");
      then
        fail();
  end matchcontinue;
end resolveLoops_cutNodes;

protected function arrayEntryLengthIs "author:Waurich TUD 2014-01
  gets the indexed entry of the array and compares the length with the given value."
  input Integer idx;
  input array<list<Integer>> arr;
  input Integer len;
  output Boolean eqLen;
protected
  list<Integer> entry;
  Integer len1;
algorithm
  entry := arrayGet(arr,idx);
  len1 := listLength(entry);
  eqLen := intEq(len,len1);
end arrayEntryLengthIs;

protected function getSimpleEquations
  input BackendDAE.Equation inEq;
  input list<BackendDAE.Equation> inEqs;
  output BackendDAE.Equation outEq;
  output list<BackendDAE.Equation> eqLst;
protected
  BackendDAE.Equation eq;
  Boolean isSimple;
algorithm
  outEq := inEq;
  eqLst := inEqs;
  (eq,isSimple) := BackendEquation.traverseExpsOfEquation(inEq,isAddOrSubExp,true);
  eqLst := if isSimple then eq::eqLst else eqLst;
end getSimpleEquations;

public function resolveLoops_findLoops "author:Waurich TUD 2014-02
  gets the crossNodes for the partitions and searches for loops"
  input list<list<Integer>> partitionsIn;
  input BackendDAE.IncidenceMatrix mIn;  // the whole system of simpleEquations
  input BackendDAE.IncidenceMatrixT mTIn;
  output list<list<Integer>> loopsOut = {};
  output list<Integer> crossEqsOut = {};
  output list<Integer> crossVarsOut = {};
protected
  list<list<Integer>> loops, eqVars;
  list<Integer> eqCrossLst, varCrossLst, partitionVars;
algorithm
  for partition in partitionsIn loop
    try
      // get the eqCrossNodes and varCrossNodes i.e. nodes with more than 2 edges
      eqVars := List.map1(partition,Array.getIndexFirst,mIn);
      partitionVars := List.flatten(eqVars);
      partitionVars := List.unique(partitionVars);
      eqCrossLst := List.fold2(partition,gatherCrossNodes,mIn,mTIn,{});
      varCrossLst := List.fold2(partitionVars,gatherCrossNodes,mTIn,mIn,{});

      // search the partitions for loops
      loops := resolveLoops_findLoops2(partition,partitionVars,eqCrossLst,varCrossLst,mIn,mTIn);
      loopsOut := listAppend(loops,loopsOut);
      crossEqsOut := listAppend(eqCrossLst,crossEqsOut);
      crossVarsOut := listAppend(varCrossLst,crossVarsOut);
    else
      return;
    end try;
  end for;
end resolveLoops_findLoops;

protected function resolveLoops_findLoops2 "author: Waurich TUD 2014-01
  handles the given partition of eqs and vars depending whether there are only varCrossNodes, only EqCrossNodes, both of them or none of them."
  input list<Integer> eqsIn;
  input list<Integer> varsIn;
  input list<Integer> eqCrossLstIn;
  input list<Integer> varCrossLstIn;
  input BackendDAE.IncidenceMatrix mIn;  // the whole system of simpleEquations
  input BackendDAE.IncidenceMatrixT mTIn;
  output list<list<Integer>> loopsOut;
algorithm
  loopsOut := match(eqsIn,varsIn,eqCrossLstIn,varCrossLstIn,mIn,mTIn)
    local
      Boolean isNoSingleLoop;
      Integer replaceIdx,eqIdx,varIdx,parEqIdx,daeEqIdx;
      list<Integer> varCrossLst, eqCrossLst, crossNodes, restNodes, adjCrossNodes, partition, partition2, replEqs, subLoop;
      list<list<Integer>> paths, allPaths, simpleLoops, varEqsLst, crossEqLst, paths0, paths1, closedPaths, loopConnectors, connectedPaths;
      BackendDAE.Equation resolvedEq, startEq;
      list<BackendDAE.Equation> eqLst;
    case(_,_,_::_,{},_,_)
      equation
          //print("partition has only eqCrossNodes\n");
        // get the paths between the crossEqNodes and order them according to their length
        allPaths = getPathTillNextCrossEq(eqCrossLstIn,mIn,mTIn,eqCrossLstIn,{},{});
        allPaths = List.sort(allPaths,List.listIsLonger);
          //print("all paths: \n"+stringDelimitList(List.map(allPaths,HpcOmTaskGraph.intLstString)," / ")+"\n");
        paths1 = List.fold1(allPaths,getReverseDoubles,allPaths,{});   // all paths with just one direction
        paths0 = List.unique(paths1);  // only the paths between the eqs without concerning the vars in between
        simpleLoops = getDoubles(paths1,{});  // get 2 adjacent equations which form a simple loop i.e. they share 2 variables
        simpleLoops = List.unique(simpleLoops);
          //print("all simpleLoop-paths: \n"+stringDelimitList(List.map(simpleLoops,HpcOmTaskGraph.intLstString)," / ")+"\n");
        (_,paths,_) = List.intersection1OnTrue(paths1,simpleLoops,intLstIsEqual);

        paths0 = List.sort(paths,List.listIsLonger);  // solve the small loops first
        (connectedPaths,loopConnectors) = connect2PathsToLoops(paths0,{},{});
        loopConnectors = List.filter1OnTrue(loopConnectors,connectsLoops,simpleLoops);
        simpleLoops = listAppend(simpleLoops,loopConnectors);

        //print("all simpleLoop-paths: \n"+stringDelimitList(List.map(simpleLoops,HpcOmTaskGraph.intLstString)," / ")+"\n");
        subLoop = connectPathsToOneLoop(simpleLoops,{});  // try to build a a closed loop from these paths
        isNoSingleLoop = listEmpty(subLoop);
        simpleLoops = if isNoSingleLoop then simpleLoops else {subLoop};
        paths0 = listAppend(simpleLoops,connectedPaths);
        paths0 = sortPathsAsChain(paths0);

        //print("all paths to be resolved: \n"+stringDelimitList(List.map(paths0,HpcOmTaskGraph.intLstString)," / ")+"\n");
      then
        paths0;
    case(_,_,{},_::_,_,_)
      equation
          //print("partition has only varCrossNodes\n");
        // get the paths between the crossVarNodes and order them according to their length
        paths = getPathTillNextCrossEq(varCrossLstIn,mTIn,mIn,varCrossLstIn,{},{});
        paths = List.sort(paths,List.listIsLonger);
        paths = listReverse(paths);
          //print("from all the paths: \n"+stringDelimitList(List.map(paths,HpcOmTaskGraph.intLstString)," / ")+"\n");

        (paths0,paths1) =  List.extract1OnTrue(paths,listLengthIs,listLength(List.last(paths)));
          //print("the shortest paths: \n"+stringDelimitList(List.map(paths0,HpcOmTaskGraph.intLstString)," / ")+"\n");

        paths1 = if listEmpty(paths1) then paths0 else paths1;
        closedPaths = List.map1(paths1,closePathDirectly,paths0);
        closedPaths = List.fold1(closedPaths,getReverseDoubles,closedPaths,{});   // all paths with just one direction
        closedPaths = List.map(closedPaths,List.unique);
        closedPaths = List.map1(closedPaths,getEqNodesForVarLoop,mTIn);// get the eqs for these varLoops
          //print("solve the smallest loops: \n"+stringDelimitList(List.map(closedPaths,HpcOmTaskGraph.intLstString)," / ")+"\n");
       then
        closedPaths;
    case(_,_,{},{},_,_)
      equation
         // no crossNodes
           //print("no crossNodes\n");
         varEqsLst = List.map1(eqsIn,Array.getIndexFirst,mIn);
         isNoSingleLoop = List.exist(varEqsLst,listEmpty);
         subLoop = if isNoSingleLoop then {} else eqsIn;
       then
         {subLoop};
    case(_,_,_::_,_::_,_,_)
      equation
        //print("there are both varCrossNodes and eqNodes\n");
      then
        {};
    else
      equation
        print("resolveLoops_findLoops2 failed!\n");
      then
        fail();
  end match;
end resolveLoops_findLoops2;

protected function connectsLoops "author:Waurich TUD 2014-02
  checks if the given path connects 2 closed simple Loops"
  input list<Integer> path;
  input list<list<Integer>> allLoops;
  output Boolean connected;
protected
  Boolean b1, b2;
  Integer startNode, endNode;
  list<list<Integer>> loops1, loops2;
algorithm
  startNode := listHead(path);
  endNode := List.last(path);
  // the startNode is connected to a loop
  loops1 := List.filter1OnTrue(allLoops,firstInListIsEqual,startNode);
  loops2 := List.filter1OnTrue(allLoops,lastInListIsEqual,startNode);
  b1 := (not listEmpty(loops1)) or (not listEmpty(loops2));
  // the endNode is connected to a loop
  loops1 := List.filter1OnTrue(allLoops,firstInListIsEqual,endNode);
  loops2 := List.filter1OnTrue(allLoops,lastInListIsEqual,endNode);
  b2 := (not listEmpty(loops1)) or (not listEmpty(loops2));
  connected := b1 and b2;
end connectsLoops;

protected function connectPathsToOneLoop "author:Waurich TUD 2014-02
  tries to connect various paths to one closed, simple loop"
  input list<list<Integer>> allPathsIn;
  input list<Integer> loopIn;
  output list<Integer> loopOut;
algorithm
  loopOut := matchcontinue(allPathsIn,loopIn)
    local
      Integer startNode, endNode, startNode1, endNode1;
      list<Integer> path, nextPath, restPath;
      list<list<Integer>> rest, nextPaths1, nextPaths2;
    case(_,startNode::path)
      equation
        endNode = List.last(path);
        true = intEq(startNode,endNode);
      then
        path;
    case(_,startNode::_)
      equation
        nextPaths1 = List.filter1OnTrue(allPathsIn, firstInListIsEqual, startNode);
        nextPaths2 = List.filter1OnTrue(allPathsIn, lastInListIsEqual, startNode);
        nextPaths1 = listAppend(nextPaths1,nextPaths2);
        nextPath = listHead(nextPaths1);
        rest = List.deleteMember(allPathsIn,nextPath);
        nextPath = List.deleteMember(nextPath,startNode);
        path = listAppend(nextPath,loopIn);
        path = connectPathsToOneLoop(rest,path);
      then
        path;
    case(path::rest,{})
      equation
        startNode::restPath = path;
        nextPaths1 = List.filter1OnTrue(rest, firstInListIsEqual, startNode);
        nextPaths2 = List.filter1OnTrue(rest, lastInListIsEqual, startNode);
        nextPaths1 = listAppend(nextPaths1,nextPaths2);
        nextPath = listHead(nextPaths1);
        rest = List.deleteMember(rest,nextPath);
        path = listAppend(nextPath,restPath);
        path = connectPathsToOneLoop(rest,path);
      then
        path;
    else
      equation
      then
        {};
  end matchcontinue;
end connectPathsToOneLoop;

protected function resolveLoops_resolveAndReplace "author:Waurich TUD 2014-01
  resolves a singleLoop. depending on whether there are only eqCrossNodes, varCrossNodes, both or none."
  input list<list<Integer>> loopsIn;
  input list<Integer> eqCrossLstIn;
  input list<Integer> varCrossLstIn;
  input BackendDAE.IncidenceMatrix mIn;
  input BackendDAE.IncidenceMatrixT mTIn;
  input list<Integer> eqMapping;
  input list<Integer> varMapping;
  input list<BackendDAE.Equation> eqLstIn;
  input list<BackendDAE.Var> varLstIn;
  input list<Integer> replEqsIn;
  output list<BackendDAE.Equation> eqLstOut;
  output list<Integer> replEqsOut;
algorithm
  (eqLstOut,replEqsOut) := matchcontinue(loopsIn,eqCrossLstIn,varCrossLstIn,mIn,mTIn,eqMapping,varMapping,eqLstIn,varLstIn,replEqsIn)
    local
      Integer pos,crossEq,crossVar;
      list<Integer> loop1, eqs, vars, crossEqs, crossEqs2, removeCrossEqs, crossVars, replEqs, loopVars, adjVars;
      list<list<Integer>> rest, eqVars;
      BackendDAE.Equation resolvedEq;
      list<BackendDAE.Equation> eqLst;
  case({},_,_,_,_,_,_,_,_,_)
    equation
      then
        (eqLstIn,replEqsIn);
  case(loop1::rest,_::crossEqs,{},_,_,_,_,_,_,_)
    equation
      // only eqCrossNodes
      //print("only eqCrossNodes\n");
      loop1 = List.unique(loop1);
      resolvedEq = resolveClosedLoop(loop1,mIn,mTIn,eqMapping,varMapping,eqLstIn,varLstIn);

      // get the equation that will be replaced and the rest
      (crossEqs,eqs,_) = List.intersection1OnTrue(loop1,eqCrossLstIn,intEq);  // replace a crossEq in the loop
      replEqs = List.intersectionOnTrue(replEqsIn,loop1,intEq);  // just consider the already replaced equations in this loop

      // first try to replace a non cross node, otherwise an already replaced eq, or if none of them is available take a crossnode (THIS IS NOT YET CLEAR)
      if not listEmpty(eqs) then
        pos = listHead(eqs);
      elseif not listEmpty(replEqs) then
        pos = listHead(replEqs);
      elseif not listEmpty(crossEqs) then
        pos = listHead(crossEqs);
      else
        pos = -1;
      end if;

      eqs = List.deleteMember(loop1,pos);
        //print("contract eqs: "+stringDelimitList(List.map(eqs,intString),",")+" to eq "+intString(pos)+"\n");

      // get the corresponding vars
      eqVars = List.map1(loop1,Array.getIndexFirst,mIn);
      vars = List.flatten(eqVars);
      loopVars = doubleEntriesInLst(vars,{},{});  // the vars in the loop
      (_,adjVars,_) = List.intersection1OnTrue(vars,loopVars,intEq); // the vars adjacent to the loop

      // update incidenceMatrix
      List.map2_0(loopVars,Array.updateIndexFirst,{},mTIn);  //delete the vars in the loop
      List.map2_0(adjVars,arrayGetDeleteInLst,loop1,mTIn);  // remove the loop eqs from the adjacent vars
      List.map2_0(adjVars,arrayGetAppendLst,{pos},mTIn);  // redirect the adjacent vars to the replaced eq
      List.map2_0(loop1,Array.updateIndexFirst,{},mIn);  //delete the eqs in the loop
      arrayUpdate(mIn,pos,adjVars);  // redirect the replaced equation to the vars outside of the loops

      // update remaining paths
      rest = List.map2(rest,replaceContractedNodes,pos,eqs);
      rest = List.unique(rest);
        //print("the remaining paths: "+stringDelimitList(List.map(rest,HpcOmTaskGraph.intLstString),"\n")+"\n\n");

      // replace Equation
        //print("replace equation "+intString(pos)+"\n");
      replEqs = pos::replEqsIn;
      pos = listGet(eqMapping,pos);
      eqLst = List.replaceAt(resolvedEq,pos,eqLstIn);

      (eqLst,replEqs) = resolveLoops_resolveAndReplace(rest,eqCrossLstIn,varCrossLstIn,mIn,mTIn,eqMapping,varMapping,eqLst,varLstIn,replEqs);
    then
      (eqLst,replEqs);
  case(loop1::rest,{},_::crossVars,_,_,_,_,_,_,_)
    equation
      // only varCrossNodes
        //print("only varCrossNodes\n");
      loop1 = List.unique(loop1);
      resolvedEq = resolveClosedLoop(loop1,mIn,mTIn,eqMapping,varMapping,eqLstIn,varLstIn);

      // get the equation that will be replaced and the rest
      (replEqs,_,eqs) = List.intersection1OnTrue(replEqsIn,loop1,intEq);  // just consider the already replaced equations in this loop

      //priorize the not yet replaced equations
      eqs = priorizeEqsWithVarCrosses(eqs,mIn,varCrossLstIn);
        //print("priorized eqs: "+stringDelimitList(List.map(eqs,intString),",")+"\n");

      // first try to replace a non cross node, otherwise an already replaced eq
      pos = if not listEmpty(replEqs) then listHead(replEqs) else -1;
      pos = if not listEmpty(eqs) then listHead(eqs) else pos;

      eqs = List.deleteMember(loop1,pos);
        //print("contract eqs: "+stringDelimitList(List.map(eqs,intString),",")+" to eq "+intString(pos)+"\n");

      // get the corresponding vars
      eqVars = List.map1(loop1,Array.getIndexFirst,mIn);
      vars = List.flatten(eqVars);
      loopVars = doubleEntriesInLst(vars,{},{});  // the vars in the loop
      (crossVars,loopVars,_) = List.intersection1OnTrue(loopVars,varCrossLstIn,intEq);  // some crossVars have to remain
      //print("loopVars: "+stringDelimitList(List.map(loopVars,intString),",")+"\n");

      (_,adjVars,_) = List.intersection1OnTrue(vars,loopVars,intEq); // the vars adjacent to the loop
      adjVars = listAppend(crossVars,adjVars);
      adjVars = List.unique(adjVars);

      // update incidenceMatrix
      List.map2_0(loopVars,Array.updateIndexFirst,{},mTIn);  //delete the vars in the loop
      List.map2_0(adjVars,arrayGetDeleteInLst,loop1,mTIn);  // remove the loop eqs from the adjacent vars
      List.map2_0(adjVars,arrayGetAppendLst,{pos},mTIn);  // redirect the adjacent vars to the replaced eq
      List.map2_0(loop1,Array.updateIndexFirst,{},mIn);  //delete the eqs in the loop
      arrayUpdate(mIn,pos,adjVars);  // redirect the replaced equation to the vars outside of the loops

      // update remaining paths
      rest = List.map2(rest,replaceContractedNodes,pos,eqs);
      rest = List.unique(rest);
        //print("the remaining paths: "+stringDelimitList(List.map(rest,HpcOmTaskGraph.intLstString),"\n")+"\n\n");

      // replace Equation
        //print("replace equation "+intString(pos)+"\n");
      replEqs = pos::replEqsIn;
      pos = listGet(eqMapping,pos);
      eqLst = List.replaceAt(resolvedEq,pos,eqLstIn);

      (eqLst,replEqs) = resolveLoops_resolveAndReplace(rest,eqCrossLstIn,varCrossLstIn,mIn,mTIn,eqMapping,varMapping,eqLst,varLstIn,replEqs);
    then
      (eqLst,replEqs);
  case(loop1::rest,{},{},_,_,_,_,_,_,_)
    equation
      // single Loop
      loop1 = List.unique(loop1);
        //print("single loop\n");
      resolvedEq = resolveClosedLoop(loop1,mIn,mTIn,eqMapping,varMapping,eqLstIn,varLstIn);

      // update IncidenceMatrix
      (_,crossEqs,_) = List.intersection1OnTrue(loop1,replEqsIn,intEq);  // do not replace an already replaced Eq
      (pos::_) = crossEqs;  // the equation that will be replaced = pos
      eqVars = List.map1(loop1,Array.getIndexFirst,mIn);
      vars = List.flatten(eqVars);
        //print("delete vars: "+stringDelimitList(List.map(vars,intString),",")+" in the eqs: "+stringDelimitList(List.map(crossEqs,intString),",")+"\n");
      List.map2_0(loop1,Array.updateIndexFirst,{},mIn);  //delete the equations in the loop
      List.map2_0(vars,Array.updateIndexFirst,{},mTIn);  //delete the vars from the loop

      // replace Equation
        //print("replace equation "+intString(pos)+"\n");
      pos = listGet(eqMapping,pos);
      replEqs = pos::replEqsIn;
      eqLst = List.replaceAt(resolvedEq,pos,eqLstIn);
      (eqLst,replEqs) = resolveLoops_resolveAndReplace(rest,eqCrossLstIn,varCrossLstIn,mIn,mTIn,eqMapping,varMapping,eqLst,varLstIn,replEqs);
    then
      (eqLst,replEqs);
  else
    equation
      print("resolveLoops_resolveAndReplace failed!\n");
    then
      fail();
  end matchcontinue;
end resolveLoops_resolveAndReplace;

protected function getDeadEndsInBipartiteGraph "author:Waurich TUD 2014-01
  gets the deadEndNodes of a bipartiteGraph. update the incidencematrix"
  input list<Integer> checkSecNodes;  //checks all these secondary nodes (vars)
  input BackendDAE.IncidenceMatrix mIn;  // the rows correspond to the primary nodes
  input BackendDAE.IncidenceMatrixT mTIn;
  input list<Integer> primNodesIn;
  input list<Integer> secNodesIn;
  output list<Integer> primNodesOut;
  output list<Integer> secNodesOut;
algorithm
  (primNodesOut,secNodesOut) := match(checkSecNodes,mIn,mTIn,primNodesIn,secNodesIn)
    local
      Integer secNode;
      list<Integer> restSecNodes, adjPrimNodes, adjSecNodes, nonLoopVars, nonLoopEqs;
      list<list<Integer>> adjSecNodesLst;
      case(secNode::restSecNodes,_,_,_,_)
        equation
          adjPrimNodes = arrayGet(mTIn,secNode);
          (_,adjPrimNodes,_) = List.intersection1OnTrue(adjPrimNodes,primNodesIn,intEq);
          adjPrimNodes = List.filter2OnTrue(adjPrimNodes,isNoCrossNode,mIn,secNodesIn);
          adjSecNodesLst = List.map1(adjPrimNodes,Array.getIndexFirst,mIn);
          adjSecNodes = List.flatten(adjSecNodesLst);
          (_,adjSecNodes,_) = List.intersection1OnTrue(adjSecNodes,secNodesIn,intEq);
          adjSecNodes = List.filter2OnTrue(adjSecNodes,arrayEntryLengthIs,mTIn,2);
          restSecNodes = listAppend(restSecNodes,adjSecNodes);
          adjPrimNodes = listAppend(adjPrimNodes,primNodesIn);
          adjSecNodes = listAppend(adjSecNodes,secNodesIn);
          (adjPrimNodes,adjSecNodes) = getDeadEndsInBipartiteGraph(restSecNodes,mIn,mTIn,adjPrimNodes,adjSecNodes);
        then
          (adjPrimNodes,adjSecNodes);
      case({},_,_,_,_)
        equation
        then
        (primNodesIn,secNodesIn);
  end match;
end getDeadEndsInBipartiteGraph;

protected function isNoCrossNode "author:Waurich TUD 2014-01
  checks if the indexed node leads to only one or less other nodes (except doNotConcern)."
  input Integer idx;
  input array<list<Integer>> arr;
  input list<Integer> doNotConsider;
  output Boolean noCrossNode;
protected
  list<Integer> entry;
algorithm
  entry := arrayGet(arr,idx);
  (_,entry,_) := List.intersection1OnTrue(entry,doNotConsider,intEq);
  noCrossNode := intLe(listLength(entry),1);
end isNoCrossNode;

protected function arrayGetDeleteInLst "deletes all entries given in delEntries from the indexed list<Integer> of the array"
  input Integer idx;
  input list<Integer> delEntries;
  input array<list<Integer>> arrIn;
protected
  list<Integer> entry;
algorithm
  entry := arrayGet(arrIn,idx);
  (_,entry,_) := List.intersection1OnTrue(entry,delEntries,intEq);
  _ := arrayUpdate(arrIn,idx,entry);
end arrayGetDeleteInLst;

protected function arrayGetAppendLst "appends appLst to the indexed list<Integer> of the array"
  input Integer idx;
  input list<Integer> appLst;
  input array<list<Integer>> arrIn;
protected
  list<Integer> entry;
algorithm
  entry := arrayGet(arrIn,idx);
  entry := listAppend(entry,appLst);
  _ := arrayUpdate(arrIn,idx,entry);
end arrayGetAppendLst;

protected function getReverseDoubles "author: Waurich TUD 2014-01
  fold function to get the reversed doubles in a list."
  input list<Integer> elem;
  input list<list<Integer>> elemLst;
  input list<list<Integer>> foldLstIn;
  output list<list<Integer>> foldLstOut;
replaceable type ElementType subtypeof Any;
algorithm
  foldLstOut := matchcontinue(elem,elemLst,foldLstIn)
    local
      list<Integer> elemR;
      list<list<Integer>> foldLst;
    case(_,_,_)
      equation
        elemR = listReverse(elem);
        elemR = List.getMember(elemR,elemLst);
        foldLst = List.deleteMember(foldLstIn,elem);
      then
        elemR::foldLst;
    else
      equation
      then
        foldLstIn;
  end matchcontinue;
end getReverseDoubles;

protected function getDoubles "author: Waurich TUD 2014-01
  function to get the reversed doubles in a list."
  input list<list<Integer>> elemLstIn;
  input list<list<Integer>> lstIn;
  output list<list<Integer>> lstOut;
replaceable type ElementType subtypeof Any;
algorithm
  lstOut := matchcontinue(elemLstIn,lstIn)
    local
      list<Integer> elem;
      list<list<Integer>> lst, elemLst;
    case({},_)
      equation
      then
        lstIn;
    case(elem::elemLst,_)
      equation
        elem = List.getMember(elem,elemLst);
        lst = getDoubles(elemLst,elem::lstIn);
      then
        lst;
    else
      equation
        (_::elemLst) = elemLstIn;
        lst = getDoubles(elemLst,lstIn);
      then
        lst;
  end matchcontinue;
end getDoubles;

protected function getEqNodesForVarLoop "author: Waurich TUD 2013-01
  fold function to get the eqs in a loop that is given by the varNodes."
  input list<Integer> varIdcs;
  input BackendDAE.IncidenceMatrixT mTIn;
  output list<Integer> eqIdcs;
protected
  list<list<Integer>> varEqLst;
  list<Integer> eqLst;
algorithm
  varEqLst := List.map1(varIdcs,Array.getIndexFirst,mTIn);  // get the eqNodes from these loops
  eqLst := List.flatten(varEqLst);
  eqIdcs := doubleEntriesInLst(eqLst,{},{});
end getEqNodesForVarLoop;

protected function resolveClosedLoop "author:Waurich TUD 2014-02
  sums up all equations in a loop so that the variables shared by the equations disappear."
  input list<Integer> loopIn;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input list<Integer> eqMapping;
  input list<Integer> varMapping;
  input list<BackendDAE.Equation> daeEqsIn;
  input list<BackendDAE.Var> daeVarsIn;
  output BackendDAE.Equation eqOut;
protected
  Integer startEqIdx,startEqDaeIdx;
  list<Integer> loop1, restLoop;
  BackendDAE.Equation eq;
algorithm
  startEqIdx::restLoop := loopIn;
  startEqDaeIdx := listGet(eqMapping,startEqIdx);
  loop1 := sortLoop(restLoop,m,mT,{startEqIdx});
    //print("solve the loop: "+stringDelimitList(List.map(loop1,intString),",")+"\n");
  eq := listGet(daeEqsIn,startEqDaeIdx);
  eqOut := resolveClosedLoop2(eq,loop1,m,mT,eqMapping,varMapping,daeEqsIn,daeVarsIn);
    //print("the resolved eq\n");
    //BackendDump.printEquationList({eqOut});
end resolveClosedLoop;

protected function resolveClosedLoop2 "author:Waurich TUD 2013-12"
  input BackendDAE.Equation eqIn;
  input list<Integer> loopIn;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input list<Integer> eqMapping;
  input list<Integer> varMapping;
  input list<BackendDAE.Equation> daeEqsIn;
  input list<BackendDAE.Var> daeVarsIn;
  output BackendDAE.Equation eqOut;
algorithm
  (eqOut) := matchcontinue(eqIn,loopIn,m,mT,eqMapping,varMapping,daeEqsIn,daeVarsIn)
    local
      Boolean isPosOnRhs1, isPosOnRhs2, algSign;
      Integer eqIdx1, eqIdx2, eqDaeIdx2, varIdx, daeVarIdx;
      list<Integer> adjVars, adjVars1 ,adjVars2, eqIdcs,varIdcs,varNodes,restLoop, row;
      list<BackendDAE.Equation> eqs;
      BackendDAE.Equation eq2,resolvedEq;
      BackendDAE.Var var;
      DAE.ComponentRef cref, eqCrefs;
    case(_,{_},_,_,_,_,_,_)
      equation
          //print("finished loop\n");
      then
        eqIn;
    case(_,(eqIdx1::restLoop),_,_,_,_,_,_)
      equation
        // the equation to add
        eqIdx2 = listHead(restLoop);
        eqDaeIdx2 = listGet(eqMapping,eqIdx2);
        eq2 = listGet(daeEqsIn,eqDaeIdx2);

        // get the vars that are shared of the 2 equations
        adjVars1 = arrayGet(m,eqIdx1);
        adjVars2 = arrayGet(m,eqIdx2);
        (adjVars,adjVars1,_) = List.intersection1OnTrue(adjVars1,adjVars2,intEq);

        // just take  the first
        varIdx = listHead(adjVars);
        daeVarIdx = listGet(varMapping,varIdx);
        var = listGet(daeVarsIn,daeVarIdx);
        cref = BackendVariable.varCref(var);

        // check the algebraic signs
        isPosOnRhs1 = CRefIsPosOnRHS(cref,eqIn);
        isPosOnRhs2 = CRefIsPosOnRHS(cref,eq2);
        algSign = boolOr((not isPosOnRhs1) and isPosOnRhs2,(not isPosOnRhs2) and isPosOnRhs1); // XOR
        resolvedEq = sumUp2Equations(algSign,eqIn,eq2);
        resolvedEq = resolveClosedLoop2(resolvedEq,restLoop,m,mT,eqMapping,varMapping,daeEqsIn,daeVarsIn);
      then
        resolvedEq;
  end matchcontinue;
end resolveClosedLoop2;

public function sortLoop "author:Waurich TUD 2014-01
  sorts the equations in a loop so that they are solved in a row."
  input list<Integer> loopIn;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input list<Integer> sortLoopIn;
  output list<Integer> sortLoopOut;
algorithm
  sortLoopOut := matchcontinue(loopIn,m,mT,sortLoopIn)
    local
      Integer start, next;
      list<Integer> rest, vars, eqs;
      list<list<Integer>> varEqs;
    case({},_,_,_)
      equation
      then
        listReverse(sortLoopIn);
    case(_,_,_,start::rest)
      equation
        vars = arrayGet(m,start);
        varEqs = List.map1(vars,Array.getIndexFirst,mT);
        eqs = List.flatten(varEqs);
        eqs = List.unique(eqs);
        eqs = List.intersectionOnTrue(eqs,loopIn,intEq);
        next = listHead(eqs);
        rest = List.deleteMember(loopIn,next);
        rest = sortLoop(rest,m,mT,next::sortLoopIn);
      then
        rest;
  end matchcontinue;
end sortLoop;

protected function closePathDirectly "author:Waurich TUD 2014-01
  tries to close the given path with the one of the paths from the list. It outputs the whole loop"
  input list<Integer> pathIn;
  input list<list<Integer>> pathLstIn;
  output list<Integer> pathOut;
algorithm
  pathOut := matchcontinue(pathIn,pathLstIn)
    local
      Boolean closed;
      Integer startNode,endNode;
      list<Integer> path,restPath;
    case(_,_)
      equation
        // the path is already closed
        startNode = listHead(pathIn);
        endNode = List.last(pathIn);
        true = intEq(startNode,endNode);
      then
        pathIn;
    case(_,_)
      equation
        // it is an open path
        startNode::_ = pathIn;
        endNode = List.last(pathIn);
        path = findPathByEnds(pathLstIn,startNode,endNode);
        closed = not listEmpty(path);
        path = if closed then path else {};
        path = listAppend(pathIn,path);
        path = List.unique(path);
      then
        path;
    else
      equation
        print("closePath failed\n");
      then
        fail();
  end matchcontinue;
end closePathDirectly;

protected function findPathByEnds "author:Waurich TUD 2014-01
  searches the list<list<Integer>> for the first list<Integer> on which the start and end Node fit."
  input list<list<Integer>> pathLstIn;
  input Integer startNodeIn;
  input Integer endNodeIn;
  output list<Integer> pathOut;
algorithm
  pathOut := matchcontinue(pathLstIn,startNodeIn,endNodeIn)
    local
      Boolean b1, b2;
      Integer startNode,endNode;
      list<Integer> path;
      list<list<Integer>> pathLst;
    case(path::pathLst,_,_)
      equation
        startNode = listHead(path);
        b1 = intEq(startNode,endNodeIn);
        endNode = List.last(path);
        b2 = intEq(endNode,startNodeIn);
        path = if not(b1 and b2) then findPathByEnds(pathLst,startNodeIn,endNodeIn) else path;
      then
        path;
    case({},_,_)
      equation
      then
        {};
    else
      equation
        print("findPathByEnds failed!\n");
      then
        fail();
  end matchcontinue;
end findPathByEnds;

protected function doubleEntriesInLst "author:Waurich TUD 2014-01
  get the entries in the list which occur multiple times.
  Is there an entry from lstIn found in checkLst, it will be output as doubled"
  input list<ElementType> lstIn;
  input list<ElementType> checkLst;
  input list<ElementType> doubleLst;
  output list<ElementType> lstOut;
replaceable type ElementType subtypeof Any;
algorithm
  lstOut := matchcontinue(lstIn,checkLst,doubleLst)
    local
      Boolean isDouble;
      ElementType elem;
      list<ElementType> lst;
    case(elem::lst,_,_)
      equation
        true = listMember(elem,checkLst);
        lst = doubleEntriesInLst(lst,checkLst,elem::doubleLst);
      then
        lst;
    case(elem::lst,_,_)
      equation
        false = listMember(elem,checkLst);
        lst = doubleEntriesInLst(lst,elem::checkLst,doubleLst);
      then
        lst;
    case({},_,_)
      equation
      then
        doubleLst;
  end matchcontinue;
end doubleEntriesInLst;

protected function getPathTillNextCrossEq "author:Waurich TUD 2013-12
  collects the paths from the given crossEq to the next."
  input list<Integer> checkEqCrossNodes; //these will be traversed
  input BackendDAE.IncidenceMatrix mIn;
  input BackendDAE.IncidenceMatrixT mTIn;
  input list<Integer> allEqCrossNodes;
  input list<list<Integer>> unfinPathsIn;
  input list<list<Integer>> eqPathsIn;
  output list<list<Integer>> eqPathsOut;
algorithm
  eqPathsOut := matchcontinue(checkEqCrossNodes,mIn,mTIn,allEqCrossNodes,unfinPathsIn,eqPathsIn)
    local
      Integer crossEq, lastEq, prevEq;
      list<Integer> adjVars, nextEqs, endEqs, unfinEqs, restCrossNodes, pathStart;
      list<list<Integer>> paths, adjEqs, unfinPaths, restUnfinPaths;
    case(crossEq::restCrossNodes,_,_,_,{},_)
      equation
        // check the next eqNode of the crossEq whether the paths is finished here or the path goes on to another crossEq
        adjVars = arrayGet(mIn,crossEq);
        adjEqs = List.map1(adjVars,Array.getIndexFirst,mTIn);
        adjEqs = List.map1(adjEqs,List.deleteMember,crossEq);// REMARK: this works only if there are no varCrossNodes
        adjEqs = List.filterOnFalse(adjEqs,listEmpty);
      nextEqs = List.flatten(adjEqs);
        (endEqs,unfinEqs,_) = List.intersection1OnTrue(nextEqs,allEqCrossNodes,intEq);
        paths = List.map1(endEqs,cons1,{crossEq}); //TODO: replace this stupid cons1
        paths = listAppend(paths,eqPathsIn);
        unfinPaths = List.map1(unfinEqs,cons1,{crossEq});
        unfinPaths = listAppend(unfinPaths,unfinPathsIn);
        paths = getPathTillNextCrossEq(restCrossNodes,mIn,mTIn,allEqCrossNodes,unfinPaths,paths);
      then
        paths;
    case(_,_,_,_,pathStart::restUnfinPaths,_)
      equation
        lastEq = listHead(pathStart);
        prevEq = List.second(pathStart);
        adjVars = arrayGet(mIn,lastEq);
        adjEqs = List.map1(adjVars,Array.getIndexFirst,mTIn);
        adjEqs = List.map1(adjEqs,List.deleteMember,lastEq);// REMARK: this works only if there are no varCrossNodes
        adjEqs = List.filterOnFalse(adjEqs,listEmpty);
        nextEqs = List.map(adjEqs,listHead);
        (nextEqs,_) = List.deleteMemberOnTrue(prevEq,nextEqs,intEq); //do not take the path back to the previous node
        (endEqs,unfinEqs,_) = List.intersection1OnTrue(nextEqs,allEqCrossNodes,intEq);
        paths = List.map1(endEqs,cons1,pathStart); //TODO: replace this stupid cons1
        paths = listAppend(paths,eqPathsIn);
        unfinPaths = List.map1(unfinEqs,cons1,pathStart);
        unfinPaths = listAppend(unfinPaths,restUnfinPaths);
        paths = getPathTillNextCrossEq(checkEqCrossNodes,mIn,mTIn,allEqCrossNodes,unfinPaths,paths);
      then
        paths;
    case({},_,_,_,{},_)
      equation
      then
        eqPathsIn;
    else
      equation
        print("getPathTillNextCrossEq failed!\n");
        then
          fail();
  end matchcontinue;
end getPathTillNextCrossEq;

protected function cons1
  input Integer elem;
  input list<Integer> lst;
  output list<Integer> outLst;
algorithm
  outLst := elem::lst;
end cons1;

protected function replaceContractedNodes "replaces the replNodes in the pathIn with the nodeIn"
  input list<Integer> pathIn;
  input Integer nodeIn;
  input list<Integer> replNodes;
  output list<Integer> pathOut;
algorithm
  pathOut := List.map2(pathIn,replaceContractedNodes2,nodeIn,replNodes);
end replaceContractedNodes;

protected function replaceContractedNodes2 "replaces the replNodes in the pathIn with the nodeIn"
  input Integer entryIn;
  input Integer nodeIn;
  input list<Integer> replNodes;
  output Integer entryOut;
protected
  Boolean repl;
algorithm
  repl := List.isMemberOnTrue(entryIn,replNodes,intEq);
  entryOut := if repl then nodeIn else entryIn;
end replaceContractedNodes2;

protected function priorizeEqsWithVarCrosses "author:Waurich TUD 2014-02
  the equations with the least number of varCrossNodes are the best."
  input list<Integer> eqsIn;
  input BackendDAE.IncidenceMatrix mIn;
  input list<Integer> varCrossLst;
  output list<Integer> eqsOut;
protected
  array<list<Integer>> priorities; //[0]eqs with no adjVarCross, [1] eqs with one adjVarCross, [2]rest
  list<list<Integer>> priorityLst;
algorithm
  priorities := arrayCreate(3,{});
  List.map3_0(eqsIn,priorizeEqsWithVarCrosses2,mIn,varCrossLst,priorities);
  priorityLst := arrayList(priorities);
  eqsOut := List.flatten(priorityLst);
end priorizeEqsWithVarCrosses;

protected function priorizeEqsWithVarCrosses2
  input Integer eq;
  input BackendDAE.IncidenceMatrix mIn;
  input list<Integer> varCrossLst;
  input array<list<Integer>> priorities;
protected
  Boolean b0,b1,b2;
  Integer numCrossVars;
  list<Integer> eqVars,crossVars;
algorithm
  eqVars := arrayGet(mIn,eq);
  crossVars := List.intersectionOnTrue(eqVars,varCrossLst,intEq);
  numCrossVars := listLength(crossVars);
  if numCrossVars == 0 then
    arrayGetAppendLst(1,{eq},priorities);
  elseif numCrossVars == 1 then
    arrayGetAppendLst(2,{eq},priorities);
  elseif numCrossVars >= 2 then
    arrayGetAppendLst(3,{eq},priorities);
  end if;
end priorizeEqsWithVarCrosses2;

protected function evaluateLoop
  input list<Integer> loopIn;
  input tuple<BackendDAE.IncidenceMatrix,BackendDAE.IncidenceMatrixT,list<Integer>> tplIn;
  output Boolean resolve;
protected
  Boolean r1,r2;
  Integer numInLoop,numOutLoop;
  list<Integer> nonLoopEqs,nonLoopVars,loopEqs, loopVars, allVars, eqCrossLst;
  list<list<Integer>> eqVars;
  BackendDAE.IncidenceMatrix m;
  BackendDAE.IncidenceMatrixT mT;
algorithm
  (m,mT,eqCrossLst) := tplIn;
  eqVars := List.map1(loopIn,Array.getIndexFirst,m);
  allVars := List.flatten(eqVars);
  loopVars := doubleEntriesInLst(allVars,{},{});
  //print("loopVars : "+stringDelimitList(List.map(loopVars,intString),",")+"\n");

  // check if its worth to resolve the loop. Therefore compare the amount of vars in and outside the loop
  (_,nonLoopVars,_) := List.intersection1OnTrue(allVars,loopVars,intEq);
  //print("nonLoopVars : "+stringDelimitList(List.map(nonLoopVars,intString),",")+"\n");
  eqCrossLst := List.intersectionOnTrue(loopVars,eqCrossLst,intEq);
  numInLoop := listLength(loopVars);
  numOutLoop := listLength(nonLoopVars);
  r1 := intGe(numInLoop,numOutLoop-1) and intLe(numInLoop,6);
  r2 := intGe(numInLoop,numOutLoop-2);
  r1 := if intEq(Flags.getConfigInt(Flags.RESHUFFLE),1) then r1 else false;
  r2 := if intEq(Flags.getConfigInt(Flags.RESHUFFLE),2) then r2 else r1;
  resolve := if intEq(Flags.getConfigInt(Flags.RESHUFFLE),3) then true else r2;
end evaluateLoop;

protected function sumUp2Equations "author:Waurich TUD 2013-12
  sums up or subtracts 2 equations, depending on the boolean (true=+, false =-)"
  input Boolean sumUp;
  input BackendDAE.Equation eq1;
  input BackendDAE.Equation eq2;
  output BackendDAE.Equation eqOut;
protected
  DAE.Exp exp1, exp2, exp3, exp4;
algorithm
  BackendDAE.EQUATION(exp=exp1, scalar=exp2) := eq1;
  BackendDAE.EQUATION(exp=exp3, scalar=exp4) := eq2;
  exp1 := sumUp2Expressions(sumUp, exp1, exp3);
  exp2 := sumUp2Expressions(sumUp, exp2, exp4);
  exp2 := sumUp2Expressions(false, exp2, exp1);
  (exp2, _) := ExpressionSimplify.simplify(exp2);
  exp1 := DAE.RCONST(0.0);
  eqOut := BackendDAE.EQUATION(exp1, exp2, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
end sumUp2Equations;

protected function CRefIsPosOnRHS "author:Waurich TUD 2013-12
  checks if the given cref occurs with a positiv algebraic sign on the right
  hand side of the equation. if its on the left hand side the algebraic sign
  has to be negated."
  input DAE.ComponentRef crefIn;
  input BackendDAE.Equation eqIn;
  output Boolean isPos;
algorithm
  isPos := matchcontinue(crefIn, eqIn)
    local
      Boolean exists1, exists2 , sign1, sign2;
      DAE.Exp e1, e2;

  case(_, BackendDAE.EQUATION(exp=e1, scalar=e2)) equation
    (exists1, sign1) = expIsCref(e1, crefIn);
    (_, sign2) = expIsCref(e2, crefIn);
    sign1 = if exists1 then not sign1 else sign2;
  then sign1;

  else equation
    print("add a case to CRefIsPosOnRHS\n");
    then fail();
  end matchcontinue;
end CRefIsPosOnRHS;

protected function expIsCref "author: Waurich TUD 2013-12
  checks if the cref is in the exp.
  if it occurs with a plus sign then true if its with a minus sign then false."
  input DAE.Exp expIn;
  input DAE.ComponentRef crefIn;
  output Boolean isInExp;
  output Boolean algSign;
algorithm
  (isInExp,algSign) := match(expIn,crefIn)
  local
    Boolean sameCref,sign, sign1, sign2, exists, exists1, exists2, isMinus;
    DAE.ComponentRef cref;
    DAE.Exp exp1, exp2;
    DAE.Operator op;
  case(DAE.CREF(componentRef=cref),_)
    equation
      // just a cref
      sameCref = ComponentReference.crefEqualNoStringCompare(crefIn,cref);
    then
      (sameCref,true);
  case(DAE.BINARY(exp1=exp1, operator = DAE.SUB(), exp2=exp2),_)
    equation
      //exp1-exp2
      (exists1,sign1) = expIsCref(exp1,crefIn);
      (exists2,sign2) = expIsCref(exp2,crefIn);
      sign2 = boolNot(sign2);
      exists = boolOr(exists1,exists2);
      sign = exists1 and sign1;
      sign = if exists2 then sign2 else sign;
    then
      (exists,sign);
  case(DAE.BINARY(exp1=exp1, operator = DAE.ADD(), exp2=exp2),_)
    equation
      //exp1+exp2
      (exists1,sign1) = expIsCref(exp1,crefIn);
      (exists2,sign2) = expIsCref(exp2,crefIn);
      exists = boolOr(exists1,exists2);
      sign = exists1 and sign1;
      sign = if exists2 then sign2 else sign;
    then
      (exists,sign);
  case(DAE.UNARY(operator=DAE.UMINUS(),exp=exp1),_)
    equation
      // -(exp)
      (exists,sign) = expIsCref(exp1,crefIn);
      sign = boolNot(sign);
    then
      (exists,sign);
  case(DAE.RCONST(),_)
    equation
      // constant
    then
      (false,false);
  else
    equation
      print("add a case to expIsCref\n");
    then
      (false,false);
  end match;
end expIsCref;

protected function listLengthIs
  input list<Integer> lst;
  input Integer value;
  output Boolean bOut;
algorithm
  bOut := intEq(listLength(lst),value);
end listLengthIs;

public function partitionBipartiteGraph "author: Waurich TUD 2013-12
  checks if there are independent subgraphs in the BIPARTITE graph. the given
  indeces refer to the equation indeces (rows in the incidenceMatrix)."
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  output array<list<Integer>> partitionsOut;
protected
  Integer numEqs, numVars;
  array<Integer> markEqs, markVars;
  list<list<Integer>> partitions;
algorithm
    numEqs := arrayLength(m);
    numVars := arrayLength(mT);
  if intEq(numEqs,0) or intEq(numVars,0) then
    partitionsOut := arrayCreate(1,{});
  else
    markEqs := arrayCreate(numEqs,-1);
    markVars := arrayCreate(numVars,-1);
    (_,partitions) := colorNodePartitions(m,mT,{1},markEqs,markVars,1,{});
    partitionsOut := listArray(partitions);
  end if;
end partitionBipartiteGraph;

protected function colorNodePartitions "author:Waurich TUD 2013-12
  helper for partitionsGraph1. Traverse the graph in a BFS manner.
  mark all visited nodes, gather partitions, color mark-arrays"
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input list<Integer> checkNextIn;
  input array<Integer> markEqs;
  input array<Integer> markVars;
  input Integer currNumberIn;
  input list<list<Integer>> partitionsIn;
  output Integer currNumberOut;
  output list<list<Integer>> partitionsOut;
protected
  Boolean hasChanged;
  Integer eq, currNumber;
  array<Integer> markNodes;
  list<Integer> rest, vars, addEqs, eqs, part;
  list<list<Integer>> restPart, partitions;
algorithm
  (currNumberOut,partitionsOut) := match (m,mT,checkNextIn,markEqs,markVars,currNumberIn,partitionsIn)
    local
    case(_,_,{0},_,_,_,_)
      equation
        //found no unassigned eqnode
        currNumber = currNumberIn-1;
        then
          (currNumber, partitionsIn);
    case(_,_,eq::rest,_,_,_,partitions)
      equation
        //check unassigned node
        if arrayGetIsNotPositive(eq,markEqs) then
          //mark this eq and add to partition
          arrayUpdate(markEqs, eq, currNumberIn);
          if listEmpty(partitions) then
            partitions = {{eq}};
          else
            part::restPart = partitions;
            part = eq::part;
            partitions = part::restPart;
          end if;

          // get adjacent equation nodes
          vars = arrayGet(m,eq);
          true = not listEmpty(vars);

          //all vars that havent been traversed
          vars = List.filter1OnTrue(vars,arrayGetIsNotPositive,markVars);
          List.map2_0(vars,Array.updateIndexFirst,currNumberIn,markVars);

          //all eqs that havent been traversed
          eqs = List.fold1(vars,getArrayEntryAndAppend,mT,{});
          eqs = List.filter1OnTrue(eqs,arrayGetIsNegative,markEqs); // all new equations which havent been queued
          List.map2_0(eqs,Array.updateIndexFirst,0,markEqs);

          // check them later
          rest = listAppend(rest,eqs);
        else
          //the node has been investigated already
          partitions = partitionsIn;
        end if;
        (currNumber,partitions) = colorNodePartitions(m,mT,rest,markEqs,markVars,currNumberIn,partitions);
      then
        (currNumber,partitions);

    case(_,_,{},_,_,_,_)
      equation
        //nothing left in this partition
        eq = Array.position(markEqs,-1);
        (currNumber,partitions) = colorNodePartitions(m,mT,{eq},markEqs,markVars,currNumberIn+1,{}::partitionsIn);
        then
          (currNumber,partitions);
  end match;
end colorNodePartitions;

protected function arrayGetIsNotPositive" outputs true if the indexed entry is not zero."
  input Integer idx;
  input array<Integer> arrayIn;
  output Boolean isNonZero;
algorithm
  isNonZero := arrayGet(arrayIn,idx) <= 0;
end arrayGetIsNotPositive;

protected function arrayGetIsNegative" outputs true if the indexed entry is negative."
  input Integer idx;
  input array<Integer> arrayIn;
  output Boolean isNonZero;
algorithm
  isNonZero := arrayGet(arrayIn,idx) < 0;
end arrayGetIsNegative;

protected function getArrayEntryAndAppend
  input Integer entry;
  input BackendDAE.IncidenceMatrixT m;
  input list<Integer> lstIn;
  output list<Integer> lstOut;
protected
  list<Integer> lst;
algorithm
  lst := arrayGet(m,entry);
  lstOut := listAppend(lst,lstIn);
end getArrayEntryAndAppend;

protected function gatherCrossNodes "author: Waurich TUD 2014-02
  checks if the indexed node has more than 2 neighbours (its a crossroad)."
  input Integer idx;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrix mT;
  input list<Integer> lstIn;
  output list<Integer> lstOut;
protected
  Boolean isCross, isNoCross;
  Integer num;
  list<Integer> row, nextNodes;
  list<list<Integer>> adjNodes;
algorithm
  // the node has more than 2 edges, it might be a crossnode
  row := arrayGet(m,idx);
  num := listLength(row);
  isCross := intGt(num,2);
  lstOut := if isCross then idx::lstIn else lstIn;
end gatherCrossNodes;

protected function isAddOrSubExp
  input DAE.Exp inExp;
  input Boolean inB;
  output DAE.Exp outExp;
  output Boolean b;
algorithm
  (outExp,b) := match(inExp,inB)
    local
      DAE.Exp exp,exp1,exp2,exp11,exp12;
      DAE.Operator op;
      DAE.ComponentRef cref;
      DAE.Type ty;
    case (DAE.CREF(),true)
      equation
        //x
      then (inExp,inB);
    case (DAE.UNARY(exp=exp1),true)
      equation
        // (-x)
        (_,b) = isAddOrSubExp(exp1,true);
      then (inExp,b);
    case (DAE.RCONST(),true)  // maybe we have to remove this, because this is just for kirchhoffs current law
      equation
        //const.
      then (inExp,true);
    case (DAE.BINARY(exp1 = exp1,operator = DAE.ADD(),exp2 = exp2),true)
      equation
        //x + y
        (_,b) = isAddOrSubExp(exp1,true);
        (_,b) = isAddOrSubExp(exp2,b);
      then (inExp,b);
    case (DAE.BINARY(exp1=exp1,operator = DAE.SUB(),exp2=exp2),true)
      equation
        //x - y
        (_,b) = isAddOrSubExp(exp1,true);
        (_,b) = isAddOrSubExp(exp2,b);
      then (inExp,b);
    else (inExp,false);
  end match;
end isAddOrSubExp;

protected function sumUp2Expressions "author:Waurich TUD 2013-12
  sums up or subtracts 2 expressions, depending on the boolen (true=+, false =-)"
  input Boolean sumUp;
  input DAE.Exp exp1;
  input DAE.Exp exp2;
  output DAE.Exp expOut;
protected
  DAE.Operator op;
  DAE.Type ty;
algorithm
  ty := DAE.T_REAL_DEFAULT;
  op := if sumUp then DAE.ADD(ty) else DAE.SUB(ty);
  expOut := DAE.BINARY(exp1,op,exp2);
  (expOut,_) := ExpressionSimplify.simplify(expOut);
end sumUp2Expressions;

protected function intLstIsEqual
  input list<Integer> lst1;
  input list<Integer> lst2;
  output Boolean bOut;
algorithm
  bOut := List.isEqualOnTrue(lst1,lst2,intEq);
end intLstIsEqual;

protected function sortPathsAsChain "author: Waurich TUD 2014-01
  sorts the paths, so that the endNode of the next Path is an endNode of one of
  all already sorted path.
  the contractedNodes represent the endNodes of the already sorted path"
  input list<list<Integer>> pathsIn;
  output list<list<Integer>> pathsOut;
algorithm
  pathsOut := matchcontinue(pathsIn)
    local
      list<Integer> path;
      list<list<Integer>> pathLst;
    case({})
      then
       {};
    case(_)
      equation
        pathLst = sortPathsAsChain1(pathsIn,0,0,{});
      then
        pathLst;
    else
      equation
      then
        pathsIn;
  end matchcontinue;
end sortPathsAsChain;

protected function sortPathsAsChain1 "author: Waurich TUD 2014-01
  sorts the paths, so that the endNode of the next Path is an endNode of one of
  all already sorted path.
  the contractedNodes represent the endNodes of the already sorted path"
  input list<list<Integer>> pathsIn;
  input Integer firstNode;
  input Integer lastNode;
  input list<list<Integer>> sortedPathsIn;
  output list<list<Integer>> sortedPathsOut;
algorithm
  sortedPathsOut := matchcontinue(pathsIn,firstNode,lastNode,sortedPathsIn)
    local
      Integer startNode,endNode;
      list<Integer> path;
      list<list<Integer>> rest, paths1, paths2, sortedPaths;
    case({},_,_,_)
      equation
      then
        sortedPathsIn;
    case(_,-1,-1,_)
      equation
      then
        sortedPathsIn;
    case(path::rest,_,_,{})
      equation
        // the first node
        startNode = listHead(path);
        endNode = List.last(path);
        sortedPaths = sortPathsAsChain1(rest,startNode,endNode,{path});
      then
        sortedPaths;
    case(_,_,_,_)
      equation
        // check if theres a path that continues the endNode
        paths1 = List.filter1OnTrue(pathsIn, firstInListIsEqual, lastNode);
        paths2 = List.filter1OnTrue(pathsIn, lastInListIsEqual, lastNode);
        paths1 = listAppend(paths1,paths2);
        false = listEmpty(paths1);
        path = listHead(paths1);
        endNode = if not listEmpty(paths1) then List.last(path) else -1;
        endNode = if not listEmpty(paths2) then listHead(path) else -1;
        rest = List.deleteMember(pathsIn,path);
        sortedPaths = listAppend(sortedPathsIn,{path});
        sortedPaths = sortPathsAsChain1(rest,firstNode,endNode,sortedPaths);

      then
        sortedPaths;
    case(_,_,_,_)
      equation
        // check if theres a path that continues the startNode
        paths1 = List.filter1OnTrue(pathsIn, firstInListIsEqual, firstNode);
        paths2 = List.filter1OnTrue(pathsIn, lastInListIsEqual, firstNode);
        paths1 = listAppend(paths1,paths2);
        false = listEmpty(paths1);
        path = listHead(paths1);
        startNode = if not listEmpty(paths1) then List.last(path) else -1;
        startNode = if not listEmpty(paths2) then listHead(path) else -1;
        rest = List.deleteMember(pathsIn,path);
        sortedPaths = path::sortedPathsIn;
        sortedPaths = sortPathsAsChain1(rest,startNode,lastNode,sortedPaths);
      then
        sortedPaths;
    else
      equation// TODO: this case just put another, unconnectable path to the front of the list.
              //this path is currently only appendable through the startNode but it has to be also appendable throught the endNode.
              //this might have no effect because in those partitions is either one long path or none.
        path::rest = pathsIn;
        sortedPaths = path::sortedPathsIn;
        startNode = listHead(path);
        sortedPaths = sortPathsAsChain1(rest,startNode,lastNode,sortedPaths);
        then
          sortedPaths;
  end matchcontinue;
end sortPathsAsChain1;

protected function firstInListIsEqual "author:Waurich TUD 2014-01
  checks if the first element in a list is equal to the given value"
  input list<Integer> lstIn;
  input Integer value;
  output Boolean isEq;
protected
  Integer first;
algorithm
  first := listHead(lstIn);
  isEq := intEq(first,value);
end firstInListIsEqual;

protected function lastInListIsEqual "author:Waurich TUD 2014-01
  checks if the last element in a list is equal to the given value"
  input list<Integer> lstIn;
  input Integer value;
  output Boolean isEq;
protected
  Integer last;
algorithm
  last := List.last(lstIn);
  isEq := intEq(last,value);
end lastInListIsEqual;

protected function connect2PathsToLoops "author:Waurich TUD 2014-01
  connects 2 paths to a closed loop"
  input list<list<Integer>> pathsIn;
  input list<list<Integer>> loopsIn;  //empty input
  input list<list<Integer>> restPathsIn;  // empt input
  output list<list<Integer>> pathsOut;
  output list<list<Integer>> restPathsOut;
algorithm
  (pathsOut,restPathsOut) := matchcontinue(pathsIn,loopsIn,restPathsIn)
    local
      Boolean closedALoop;
      Integer startNode, endNode;
      list<Integer> path;
      list<list<Integer>> rest, endPaths, startPaths, loops, restPaths;
    case({},_,_)
      equation
        then
          ({},{});
    case({path},_,_)
      equation
        // checks if the single path closes itself
        startNode = listHead(path);
        endNode = List.last(path);
        closedALoop = intEq(startNode,endNode);
        loops = if closedALoop then path::loopsIn else loopsIn;
        restPaths = if closedALoop then restPathsIn else (path::restPathsIn);
      then
        (loops,restPaths);
    case(path::rest,_,_)
      equation
        // the loop closes itself
        startNode = listHead(path);
        endNode = List.last(path);
        true = intEq(startNode,endNode);
        loops = path::loopsIn;
        (loops,restPaths) = connect2PathsToLoops(rest,loops,restPathsIn);
      then
        (loops,restPaths);
    case(path::rest,_,_)
      equation
        // check if there is another path that closes the Loop. if not: put the path to the restPaths
        startNode = listHead(path);
        endNode = List.last(path);
        startPaths = List.filter1OnTrue(rest,firstInListIsEqual,startNode);
        startPaths = List.filter1OnTrue(startPaths,lastInListIsEqual,endNode);
        endPaths = List.filter1OnTrue(rest,firstInListIsEqual,endNode);
        endPaths = List.filter1OnTrue(endPaths,lastInListIsEqual,startNode);
        endPaths = listAppend(startPaths,endPaths);
        closedALoop = intGe(listLength(endPaths),1);
        loops = if closedALoop then connectPaths(path,endPaths) else {};
        restPaths = if closedALoop then restPathsIn else (path::restPathsIn);
        loops = listAppend(loops,loopsIn);
        (loops,restPaths) = connect2PathsToLoops(rest,loops,restPaths);
      then
        (loops,restPaths);
    else
      equation
        print("connect2PathsToLoops failed\n");
      then
        fail();
  end matchcontinue;
end connect2PathsToLoops;

protected function connectPaths "author:Waurich TUD 2014-02
  connects a given paths with the closing paths i.e. delete the first and last
  node of the path and append it to the given paths"
  input list<Integer> pathIn;
  input list<list<Integer>> closingPaths;
  output list<list<Integer>> loopsOut;
protected
  list<Integer> path;
algorithm
  _::path := pathIn;
  path := List.stripLast(path);
  loopsOut := List.map1(closingPaths,listAppend,path);
end connectPaths;


//____________________________________________________
//reshuffle systems of equations, not yet finished
//____________________________________________________

public function reshuffling_post
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystems eqSystems;
algorithm
  if Flags.isSet(Flags.RESHUFFLE_POST) then
    //print("RESHUFFLING\n");
    //BackendDump.dumpBackendDAE(inDAE,"INDAE");
    eqSystems := List.map1(inDAE.eqs,reshuffling_post0, inDAE.shared);
    outDAE := BackendDAE.DAE(eqSystems, inDAE.shared);
    //BackendDump.dumpBackendDAE(outDAE,"OUTDAE");
  else
    outDAE := inDAE;
  end if;
end reshuffling_post;

protected function reshuffling_post0 "author: waurich TUD 2014-09"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared shared;
  output BackendDAE.EqSystem osyst;
protected
  BackendDAE.StrongComponents comps;
  BackendDAE.EqSystem syst;
  Boolean b;
algorithm
  BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps)):=isyst;
  osyst := List.fold1(comps,reshuffling_post1,shared,isyst);
end reshuffling_post0;

protected function reshuffling_post1
  input BackendDAE.StrongComponent compIn;
  input BackendDAE.Shared shared;
  input BackendDAE.EqSystem systIn;
  output BackendDAE.EqSystem systOut;
algorithm
  systOut := matchcontinue(compIn,shared,systIn)
    local
      list<Integer> vIdcs,eqIdcs;
      BackendDAE.EqSystem eqSys;
      BackendDAE.JacobianType jacType;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> ojac;
    case ((BackendDAE.EQUATIONSYSTEM(eqns=eqIdcs, vars=vIdcs, jac=BackendDAE.FULL_JACOBIAN(ojac), jacType=jacType)),_,_)
      equation
        equality(jacType = BackendDAE.JAC_LINEAR());
        (eqSys,_) = reshuffling_post2(eqIdcs, vIdcs, systIn, shared,  ojac, jacType);
      then eqSys;
    else
      then systIn;
  end matchcontinue;
end reshuffling_post1;

protected function reshuffling_post2 ""
  input list<Integer> eqIdcs;
  input list<Integer> varIdcs;
  input BackendDAE.EqSystem dae;
  input BackendDAE.Shared shared;
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> ojac;
  input BackendDAE.JacobianType jacType;
  output BackendDAE.EqSystem daeOut;
  output Boolean outRunMatching;
protected
  Integer size;
  list<list<Integer>> resEqs;
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn,ass1, ass2, ass1Sys, ass2Sys;
  list<tuple<Boolean,String>> varAtts,eqAtts;
  BackendDAE.EquationArray eqs,replEqs,daeEqs;
  BackendDAE.Variables vars, daeVars;
  BackendDAE.EqSystem subSys;
  BackendDAE.AdjacencyMatrixEnhanced me, me2, meT;
  BackendDAE.IncidenceMatrix m;
  DAE.FunctionTree funcs;
  list<BackendDAE.Equation> eqLst,eqsInLst;
  list<BackendDAE.Var> varLst;
algorithm
  //prepare everything
  size := listLength(varIdcs);
  BackendDAE.EQSYSTEM(orderedVars=daeVars, orderedEqs=daeEqs, matching=BackendDAE.MATCHING(ass1=ass1Sys,ass2=ass2Sys)) := dae;
  funcs := BackendDAEUtil.getFunctions(shared);
  eqLst := BackendEquation.getEqns(eqIdcs,daeEqs);
  eqs := BackendEquation.listEquation(eqLst);
  varLst := List.map1r(varIdcs, BackendVariable.getVarAt, daeVars);
  vars := BackendVariable.listVar1(varLst);
  subSys := BackendDAEUtil.createEqSystem(vars, eqs);
  (me,meT,_,_) := BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(subSys,shared,false);
  (_,m,_,_,_) := BackendDAEUtil.getIncidenceMatrixScalar(subSys,BackendDAE.SOLVABLE(),SOME(BackendDAEUtil.getFunctions(shared)));
  ass1 := arrayCreate(size,-1);
  ass2 := arrayCreate(size,-1);

  // dump system as graphML
  varAtts := List.threadMap(List.fill(false,listLength(varLst)),List.map(eqIdcs,intString),Util.makeTuple);
  eqAtts := List.threadMap(List.fill(false,listLength(eqLst)),List.map(varIdcs,intString),Util.makeTuple);
  BackendDump.dumpBipartiteGraphStrongComponent2(vars,eqs,m,varAtts,eqAtts,"shuffle_pre");

  //start reshuffling
  resEqs := reshuffling_post3_selectShuffleEqs(me,meT);
  //print("selected equation pairs: "+stringDelimitList(List.map(resEqs,HpcOmTaskGraph.intLstString)," | ")+"\n");

  eqsInLst := reshuffling_post4_resolveAndReplace(resEqs,eqLst,varLst,me,meT);

  // dump system as graphML
  //subSys := BackendDAEUtil.createEqSystem(vars, replEqs);
  //(me2,_,_,_) := BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(subSys,shared,false);
  //BackendDump.dumpBipartiteGraphStrongComponentSolvable(vars,replEqs,me2,varAtts,eqAtts,"shuffle_post");

  // the new eqSystem
  daeEqs := List.threadFold(eqIdcs,eqsInLst,BackendEquation.setAtIndexFirst,daeEqs);
  daeOut := BackendDAEUtil.setEqSystEqs(dae, daeEqs);
  daeOut := BackendDAEUtil.setEqSystMatching(daeOut, BackendDAE.MATCHING(ass1Sys, ass2Sys, {}));

  (daeOut,_,_,_,_) := BackendDAEUtil.getIncidenceMatrixScalar(daeOut, BackendDAE.NORMAL(), SOME(funcs));

  outRunMatching := true;
end reshuffling_post2;

protected function reshuffling_post3_selectShuffleEqs
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input BackendDAE.AdjacencyMatrixEnhanced meT;
  output list<list<Integer>> resolveEqs;
algorithm
  resolveEqs := matchcontinue(me,meT)
    local
      Integer resEq1, resEq2, resVar;
      array<Boolean> bArr;
      list<Integer> suitableEqs;
      list<list<Integer>> eqPairs;
    case(_,_)
      equation
        bArr = Array.map1(me,chooseEquation,meT);
        (_,suitableEqs) = List.filter1OnTrueSync(arrayList(bArr),boolEq,true,List.intRange(arrayLength(me)));
        //print("suitableEqs: \n"+stringDelimitList(List.map(suitableEqs,intString)," / ")+"\n");
        eqPairs = List.map2(suitableEqs,getEqPairs,me,meT);
        eqPairs = List.filterOnTrue(eqPairs,List.hasSeveralElements);
      then eqPairs;
    else
      equation
        print("reshuffling_post3_selectShuffleEqs failed!\n");
     then {};
  end matchcontinue;
end reshuffling_post3_selectShuffleEqs;

protected function reshuffling_post4_resolveAndReplace
  input list<list<Integer>> resolveEqLst;
  input list<BackendDAE.Equation> unassEqsIn;
  input list<BackendDAE.Var> unassVarsIn;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input BackendDAE.AdjacencyMatrixEnhanced meT;
  output list<BackendDAE.Equation> unassEqsOut;
algorithm
  unassEqsOut := matchcontinue(resolveEqLst,unassEqsIn,unassVarsIn,me,meT)
    local
      Integer maxNum, replEqIdx;
      list<Integer> numOfAdjVars, resolveEqs;
      list<list<Integer>> rest;
      list<BackendDAE.Equation> unassEqs;
      BackendDAE.Equation resolvedEq;
    case({},_,_,_,_)
      then unassEqsIn;
    case(resolveEqs::rest,_,_,_,_)
      equation
        resolvedEq = resolveEquations(NONE(),resolveEqs,me,meT,unassEqsIn,unassVarsIn);
            //BackendDump.dumpEquationList({resolvedEq},"resolvedEq");

        //replace a former equation
        numOfAdjVars = List.map(List.map1(resolveEqs,Array.getIndexFirst,me),listLength);
        maxNum = List.fold(numOfAdjVars,intMax,listHead(numOfAdjVars));
        replEqIdx = listGet(resolveEqs,List.position(maxNum,numOfAdjVars));
            //BackendDump.dumpEquationList(unassEqsIn," not updated unassEqs");
        unassEqs = List.replaceAt(resolvedEq,replEqIdx,unassEqsIn);
        //print("replace equation "+intString(replEqIdx)+"\n");
            //BackendDump.dumpEquationList(unassEqs,"updated unassEqs");
      then reshuffling_post4_resolveAndReplace(rest,unassEqs,unassVarsIn,me,meT);
   else
     equation
       print("reshuffling_post4_resolveAndReplace failed!\n");
     then fail();
  end matchcontinue;
end reshuffling_post4_resolveAndReplace;

protected function getEqPairs
  input Integer eq;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input BackendDAE.AdjacencyMatrixEnhanced meT;
  output list<Integer> lstOut;
protected
  list<Integer> vars,eqs;
algorithm
  vars := List.map(arrayGet(me,eq),Util.tuple31);
          //print("vars: \n"+stringDelimitList(List.map(vars,intString)," / ")+"\n");
  eqs := List.map(List.flatten(List.map1(vars,Array.getIndexFirst,meT)),Util.tuple31);
          //print("eqs: \n"+stringDelimitList(List.map(eqs,intString)," / ")+"\n");
  eqs := getDoublicates(eqs);
          //print("eqs: \n"+stringDelimitList(List.map(eqs,intString)," / ")+"\n");
  lstOut := List.unique(eq::eqs);
end getEqPairs;

protected function chooseEquation
  input list<BackendDAE.AdjacencyMatrixElementEnhancedEntry> row;
  input BackendDAE.AdjacencyMatrixEnhanced meT;
  output Boolean chooseThis;
protected
  Boolean b1,b2,b3;
  list<Integer> vars,eqs,numEqs;
  list<list<Integer>> eqLst;
algorithm
  vars := List.map(row,Util.tuple31);
  b1 := intEq(listLength(row),2);  // only two variables
  eqLst := List.mapList((List.map1(vars,Array.getIndexFirst,meT)),Util.tuple31);
  numEqs := List.map(eqLst,listLength);
  b3 := List.applyAndFold1(numEqs,boolOr,intEq,2,false);  // at least one adjacent variable hast only 2 adj equations
  eqs := List.flatten(eqLst);
  b2 := intEq(listLength(eqs),listLength(List.unique(eqs))+2);
  b1 := b1 and b2 and b3;
  chooseThis := b1 and List.applyAndFold(row,boolAnd,isSolvable,true);
end chooseEquation;

protected function getDoublicates
  input list<Integer> lstIn;  // only positive Integer
  output list<Integer> lstOut;
protected
  Integer max;
  array<Integer> arr;
algorithm
  max := List.fold(lstIn,intMax,listHead(lstIn));
  arr := arrayCreate(max,-1);
  List.map1_0(lstIn,getDoublicates2,arr);
  (_,lstOut) := List.filter1OnTrueSync(arrayList(arr),intGe,1,List.intRange(arrayLength(arr)));
end getDoublicates;

protected function getDoublicates2
  input Integer idx;
  input array<Integer> arr;
protected
  Integer entry;
algorithm
  entry := arrayGet(arr,idx);
  _ := arrayUpdate(arr,idx,entry+1);
end getDoublicates2;

protected function isSolvable
  input BackendDAE.AdjacencyMatrixElementEnhancedEntry entry;
  output Boolean solvable;
algorithm
  solvable := not Tearing.unsolvable({entry});
end isSolvable;

public function resolveEquations
  input Option<BackendDAE.Equation> eq;
  input list<Integer> loopIn;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input BackendDAE.AdjacencyMatrixEnhanced meT;
  input list<BackendDAE.Equation> eqsIn;
  input list<BackendDAE.Var> varsIn;
  output BackendDAE.Equation eqOut;
protected
algorithm
  eqOut := matchcontinue(eq,loopIn,me,meT,eqsIn,varsIn)
    local
      Integer startEq,nextEq,sharedVar, min;
      list<Integer> rest,vars1,vars2,numEqs;
      BackendDAE.Equation eq1,eq2;
      BackendDAE.Var var;
      BackendDAE.EquationAttributes attr;
      DAE.Exp lhs1, lhs2, rhs1, rhs2 ,varExp,eqExp;
      DAE.ElementSource source;
    case(SOME(eq1),{},_,_,_,_)
      equation
        // resolved the whole cycle
        then eq1;
    case(NONE(),startEq::rest,_,_,_,_)
      equation
        // start resolving the first 2 equations
        nextEq::rest = rest;
        //BackendDump.dumpIncidenceMatrix(m);
        vars1 = List.map(arrayGet(me,startEq),Util.tuple31);
        vars2 = List.map(arrayGet(me,nextEq),Util.tuple31);
        vars1 = List.intersectionOnTrue(vars1,vars2,intEq);
        numEqs = List.map(List.map1(vars1,Array.getIndexFirst,meT),listLength);
        (_,vars1) = List.filter1OnTrueSync(numEqs,intEq,2,vars1);
        sharedVar = listHead(vars1);
        eq1 = listGet(eqsIn,startEq);
        eq2 = listGet(eqsIn,nextEq);
        var = listGet(varsIn,sharedVar);
        varExp = Expression.crefExp(BackendVariable.varCref(var));
            //BackendDump.dumpEquationList({eq1},"eq1");
            //BackendDump.dumpEquationList({eq2},"eq2");
            //BackendDump.dumpVarList({var},"var");

        BackendDAE.EQUATION(exp=lhs1,scalar=rhs1,source=source,attr=attr) = eq1;
        BackendDAE.EQUATION(exp=lhs2,scalar=rhs2) = eq2;
        (eqExp,_) = ExpressionSolve.solve(lhs1,rhs1,varExp);
          //BackendDump.dumpEquationList({eq1},"solved Eq");

        ((lhs2,_)) = Expression.replaceExp(lhs2,varExp,eqExp);
        ((rhs2,_)) = Expression.replaceExp(rhs2,varExp,eqExp);
        (lhs2,_) = ExpressionSimplify.simplify(lhs2);
        (rhs2,_) = ExpressionSimplify.simplify(rhs2);
          eq2 = BackendDAE.EQUATION(lhs2,rhs2,source,attr);
          //BackendDump.dumpEquationList({eq2},"resolved Eq");
     then resolveEquations(SOME(eq2),rest,me,meT,eqsIn,varsIn);
    else
      equation
      print("resolveEquations failed!\n");
    then fail();
  end matchcontinue;
end resolveEquations;

// =============================================================================
// section for postOptModule >solveLinearSystem<<
//
// solve linear system of equations (A x = b)
// =============================================================================

public function solveLinearSystem
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  Integer maxSize =  Flags.getConfigInt(Flags.MAX_SIZE_FOR_SOLVE_LINIEAR_SYSTEM);
  Boolean b = 1 < maxSize;
algorithm
  if b then
    (outDAE,_) := BackendDAEUtil.mapEqSystemAndFold(inDAE, solveLinearSystem0, (false,1,maxSize));
  else
    outDAE := inDAE;
  end if;
end solveLinearSystem;

protected function solveLinearSystem0
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared inShared;
  input tuple<Boolean,Integer,Integer> inTpl;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared outShared;
  output tuple<Boolean,Integer,Integer> outTpl;
protected
  BackendDAE.StrongComponents comps;
algorithm
  BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps)) := isyst;
  (osyst, outShared, outTpl) := solveLinearSystem1(isyst, inShared, comps, inTpl);
end solveLinearSystem0;

protected function solveLinearSystem1
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StrongComponents inComps;
  input tuple<Boolean,Integer,Integer> inTpl;
  output BackendDAE.EqSystem osyst = isyst;
  output BackendDAE.Shared oshared = ishared;
  output tuple<Boolean,Integer,Integer> outTpl;
protected
  Boolean b;
  Boolean runMatching;
  list<Integer> ii = {};
  Integer offset, maxSize;
algorithm
  (runMatching, offset, maxSize) := inTpl;
  for comp in inComps loop
     (osyst,oshared,b,ii,offset) := solveLinearSystem2(osyst,oshared,comp,ii, offset, maxSize);
     runMatching := runMatching or b;
  end for;
  outTpl := (runMatching, offset,maxSize);

  if runMatching then
  osyst := match osyst
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.EqSystem syst;
    case syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns)
      equation
        // remove empty entries from vars/eqns
        eqns = List.fold(ii,BackendEquation.equationRemove,eqns);
        syst.orderedVars = BackendVariable.listVar1(BackendVariable.varList(vars));
        syst.orderedEqs = BackendEquation.listEquation(BackendEquation.equationList(eqns));
      then
        BackendDAEUtil.clearEqSyst(syst);
    end match;
  end if;
end solveLinearSystem1;

protected function solveLinearSystem2
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StrongComponent comp;
  input list<Integer> ii;
  input Integer offset;
  input Integer maxSize;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output Boolean outRunMatching;
  output list<Integer> oi;
  output Integer offset_;
algorithm
  (osyst,oshared,outRunMatching, oi, offset_):=
  matchcontinue (isyst,ishared,comp)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.StrongComponents comps;
      BackendDAE.StrongComponent comp1;
      list<BackendDAE.Equation> eqn_lst;
      list<BackendDAE.Var> var_lst;
      list<Integer> eindex,vindx;
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      Integer toffset;

    case ( syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), shared,
           (BackendDAE.EQUATIONSYSTEM( eqns=eindex, vars=vindx, jac=BackendDAE.FULL_JACOBIAN(SOME(jac)), jacType=BackendDAE.JAC_LINEAR()))
         )
      equation
        eqn_lst = BackendEquation.getEqns(eindex,eqns);
        var_lst = List.map1r(vindx, BackendVariable.getVarAt, vars);
        true = listLength(var_lst) <= maxSize;
        ({},_) = List.splitOnTrue(var_lst, BackendVariable.isStateVar) "TODO: fix BackendDAEUtil.getEqnSysRhs for x and der(x)";
        (syst,shared, toffset) = solveLinearSystem3(syst,shared,eqn_lst,eindex,var_lst,vindx,jac,offset);
      then (syst,shared,true, List.appendNoCopy(eindex, ii), toffset);
    else (isyst,ishared,false, ii, offset);
  end matchcontinue;
end solveLinearSystem2;

protected function solveLinearSystem3
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.Shared ishared;
  input list<BackendDAE.Equation> eqn_lst;
  input list<Integer> eqn_indxs;
  input list<BackendDAE.Var> var_lst;
  input list<Integer> var_indxs;
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  input Integer offset;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output Integer offset_;
algorithm
  (osyst,oshared, offset_):=
  match (inSyst, ishared)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      list<DAE.Exp> beqs;
      list<DAE.ElementSource> sources;
      Integer linInfo;
      list<DAE.ComponentRef> names;
      BackendDAE.Matching matching;
      DAE.FunctionTree funcs;
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
      Integer n;

    case ( syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns),
           shared as BackendDAE.SHARED(functionTree=funcs) )
      algorithm
        (beqs, _) := BackendDAEUtil.getEqnSysRhs( BackendEquation.listEquation(eqn_lst),
                                                  BackendVariable.listVar1(var_lst), SOME(funcs) );
        beqs := listReverse(beqs);
        n := listLength(beqs);
        names := List.map(var_lst, BackendVariable.varCref);
        (eqns, vars, n, shared) := solveLinearSystem4(beqs, jac, names, var_lst, n, eqns, vars, offset, shared);
        syst.orderedVars := vars; syst.orderedEqs := eqns;
        syst := BackendDAEUtil.setEqSystMatrices(syst);
        //eqns = List.fold(eqn_indxs,BackendEquation.equationRemove,eqns);
      then
        (syst, shared, n);
  end match;
end solveLinearSystem3;

protected function solveLinearSystem4
"
  author: Vitalij Ruge
"
  input list<DAE.Exp> b_lst;
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  input list<DAE.ComponentRef> cr_x;
  input list<BackendDAE.Var> var_lst;
  input Integer n;
  input BackendDAE.EquationArray ieqns;
  input BackendDAE.Variables ivars;
  input Integer offset;
  input BackendDAE.Shared ishared;
  output BackendDAE.EquationArray oeqns = ieqns;
  output BackendDAE.Variables ovars = ivars;
  output Integer offset_ = offset + 1;
  output BackendDAE.Shared oshared = ishared;
protected
  array<DAE.Exp> R;
  array<DAE.Exp> Qb = arrayCreate(n,DAE.RCONST(0.0));
  array<DAE.Exp> b = arrayCreate(n,DAE.RCONST(0.0));
  array<DAE.Exp> A = arrayCreate(n*n,DAE.RCONST(0.0));
  array<DAE.Exp> ax = arrayCreate(n,DAE.RCONST(0.0));
  array<DAE.Exp> scaled_x = arrayCreate(n,DAE.RCONST(0.0));
  array<DAE.Exp> scaleA = arrayCreate(n,DAE.RCONST(0.0));

  DAE.Exp a, x;
  Integer m, ii, jj, mm;
  list<DAE.Exp> x_lst = List.map(cr_x, Expression.crefExp);
  DAE.ComponentRef cr;
  list<DAE.ComponentRef> X = cr_x;
  DAE.Exp detA, detAb;
  BackendDAE.Var tmpvar;
  String name;
  list<BackendDAE.Var> vars = var_lst;
  BackendDAE.Var var;
  BackendDAE.Equation eqn;
  list<tuple<Integer, Integer, BackendDAE.Equation>> jac_ = jac;
algorithm
  mm := listLength(jac);
  //A
  for i in 1:mm loop
    (jj,ii,BackendDAE.RESIDUAL_EQUATION(exp = a)) :: jac_ := jac_; // jac(1) = a11, jac(2)=a12,.., jac(n+1) = an1
    m := ii + (jj-1)*n;
    (a, oeqns, ovars, oshared) := BackendEquation.makeTmpEqnForExp(a, "QR$A$" + intString(m), offset, oeqns, ovars, oshared);
    arrayUpdate(A,m,a);
  end for;

  // calc scale A
  for i in 1:n loop
    m := (i-1)*n;
    a :=  Expression.makeSum1(list(Expression.makeAbs(arrayGet(A, m+j)) for j in 1:n));
    arrayUpdate(scaleA,i,a);
  end for;

  // update A scaling
  for i in 1:n loop
    m := (i-1)*n;
    for j in 1:n loop
      a := arrayGet(A,j+m);
      if not Expression.isZero(a) then
        a := Expression.expDiv(a, arrayGet(scaleA,j));
        (a, oeqns, ovars, oshared) := BackendEquation.makeTmpEqnForExp(a, "QR$sA$" + intString(i + (j-1)*n), offset, oeqns, ovars, oshared);
        arrayUpdate(A, j+m, a);
      end if;
    end for;
  end for;

  // b
  m := 1;
  for b_ in b_lst loop
     (a, oeqns, ovars, oshared) := BackendEquation.makeTmpEqnForExp(b_, "QR$b$" + intString(m), offset, oeqns, ovars, oshared);
     arrayUpdate(b, m, a);
     m := m + 1;
  end for;
  //qrDecomposition3(b, n, false, "b");

  // x
  m := 1;
  for xx in x_lst loop
    var :: vars := vars;
    if BackendVariable.isStateVar(var) then
      arrayUpdate(ax,m,Expression.expDer(xx));
    else
      arrayUpdate(ax,m,xx);
    end if;
    m := m + 1;
  end for;

  //rescale x
  // scale_x = x/factor
  for i in 1:n loop
    a := Expression.expMul(arrayGet(ax,i), arrayGet(scaleA,i));
    (a, oeqns, ovars, oshared) := BackendEquation.makeTmpEqnForExp(a, "QR$sx$" + intString(i), offset, oeqns, ovars, oshared);
    arrayUpdate(scaled_x,i,a);
  end for;

  //qrDecomposition3(ax, n, false, "x");

  // A*x = b -> R*x = Q'b
  //(R, Qb, oeqns, ovars, oshared) := qrDecomposition(A, n, b, oeqns, ovars, offset, oshared);
  (R, Qb, oeqns, ovars, oshared) := qrDecompositionHouseholder(A, n, b, oeqns, ovars, offset, oshared);

  // R*x = Q'*b where x is scaled
  for i in n:-1:1 loop
    m := (i-1)*n;
    a := Expression.makeSum1(list(Expression.expMul(arrayGet(R, m + j), arrayGet(scaled_x, j)) for j in i:n));
    eqn := BackendDAE.EQUATION(a, arrayGet(Qb,i), DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
    eqn := BackendEquation.solveEquation(eqn, arrayGet(scaled_x,i), NONE());
    oeqns := BackendEquation.addEquation(eqn, oeqns);
  end for;

end solveLinearSystem4;

protected function qrDecompositionHouseholder
"
  QR-Decomposition based on Householder
  author: Vitalij Ruge
"
  input array<DAE.Exp> A;
  input Integer n;
  input array<DAE.Exp> ib;
  input BackendDAE.EquationArray ieqns;
  input BackendDAE.Variables ivars;
  input Integer offset;
  input BackendDAE.Shared ishared;
  output array<DAE.Exp> R = A;
  output array<DAE.Exp> b = ib;
  output BackendDAE.EquationArray oeqns = ieqns;
  output BackendDAE.Variables ovars = ivars;
  output BackendDAE.Shared oshared = ishared;

protected
  array<DAE.Exp> cA = arrayCreate(n,DAE.RCONST(0.0)) "column of A";
  array<DAE.Exp> v = arrayCreate(n,DAE.RCONST(0.0)) "vec in dyadic tensor";
  DAE.Exp alpha;
  DAE.Exp y1;
  DAE.Exp h,h2;
  DAE.Exp e1,e2,e;
  Integer m "cuurrent size";
  Integer nn = n-1;
  Integer idxVars = 1 "index for tmp vars";
  Integer shift;
algorithm
  //qrDecomposition3(A,n,true,"A");

  for iter in 1:nn loop
    m := n - iter + 1;

    //first column
    qrGet_cA(A,iter,1,n,v);
    y1 := arrayGet(v,1);

    alpha :=  qrCalc_alpha(v,y1,m);
    (alpha, oeqns, ovars, oshared) := BackendEquation.makeTmpEqnForExp(alpha, "QR$a$" + intString(iter), offset, oeqns, ovars, oshared);

    // calc v
    e := Expression.expAdd(y1,alpha);
    (e, oeqns, ovars, oshared) := BackendEquation.makeTmpEqnForExp(e, "QR$y1$" + intString(iter), offset, oeqns, ovars, oshared);
    arrayUpdate(v,1, e);

    // helper for const factor
    h := Expression.expAdd(y1,alpha);
    h := Expression.expMul(alpha,h);
    h := Expression.negate(h);
    (h, oeqns, ovars, oshared) := BackendEquation.makeTmpEqnForExp(h, "QR$h$" + intString(iter), offset, oeqns, ovars, oshared);

    shift := (iter-1)*n + iter;
    //update R
    arrayUpdate(R, shift, Expression.negate(alpha));
    for j in 2:m loop
      arrayUpdate(R, shift + (j-1)*n, DAE.RCONST(0.0));
    end for;

    for col in 2:m loop
      qrGet_cA(A,iter,col,n,cA);
      h2 := Expression.makeScalarProduct(v, cA);
      h2 := Expression.expDiv(h2,h);
     (h2, oeqns, ovars, oshared) := BackendEquation.makeTmpEqnForExp(h2, "QR$h2$" + intString(idxVars), offset, oeqns, ovars, oshared);
      idxVars := idxVars + 1;
      //vec add
      for j in 1:m loop
         e1 := arrayGet(cA,j);
         e2 := arrayGet(v,j);
         e := Expression.expAdd(e1,Expression.expMul(h2, e2));
         (e, oeqns, ovars, oshared) := BackendEquation.makeTmpEqnForExp(e, "QR$R$" + intString(idxVars), offset, oeqns, ovars, oshared);
         idxVars := idxVars + 1;
         //update A
         arrayUpdate(A, shift + (j-1)*n + col-1, e);
      end for;
    end for;
    //update b
    for j in 1:m loop
      arrayUpdate(cA,j, arrayGet(b,iter-1 + j));
    end for;

    h2 := Expression.makeScalarProduct(v, cA);
    h2 := Expression.expDiv(h2, h);
    (h2, oeqns, ovars, oshared) := BackendEquation.makeTmpEqnForExp(h2, "QR$b_$" + intString(idxVars), offset, oeqns, ovars, oshared);
    idxVars := idxVars + 1;

    //vec add
    for j in 1:m loop
      e1 := arrayGet(cA, j);
      e2 := arrayGet(v,j);
      e := Expression.expAdd(e1,Expression.expMul(h2, e2));
      e := Expression.expand(e);
      e := ExpressionSimplify.simplify2(e);
      (e, oeqns, ovars, oshared) := BackendEquation.makeTmpEqnForExp(e, "QR$b$" + intString(idxVars), offset, oeqns, ovars, oshared);
      idxVars := idxVars + 1;
      //update b
      arrayUpdate(b, iter-1+j, e);
    end for;

  end for;
  //qrDecomposition3(A,n,true,"R");

end qrDecompositionHouseholder;

protected function qrGet_cA
"
  helper for QR-Decomposition based on Householder
  return column j in A for iteration iter
  author: Vitalij Ruge
"
  input array<DAE.Exp> A;
  input Integer iter "iteration";
  input Integer j "column";
  input Integer n "size";
  input array<DAE.Exp> cA "output";
protected
  Integer shift = (iter-1)*n + iter + j - 1;
  Integer m = n-iter+1;
algorithm

  for i in 1:m loop
    arrayUpdate(cA, i, arrayGet(A,shift+(i-1)*n));
  end for;

  for i in m+1:n loop
    arrayUpdate(cA, i, DAE.RCONST(0.0));
  end for;

end qrGet_cA;

protected function qrCalc_alpha
"
  helper for QR-Decomposition based on Householder
  calculate -> min loss of significance
  author: Vitalij Ruge
"
  input array<DAE.Exp> y;
  input DAE.Exp y1;
  input Integer m;
  output DAE.Exp alpha;
protected
  DAE.Exp sgn_y1 = Expression.makeSign(y1);
  DAE.Exp norm_y = Expression.lenVec(y);
algorithm
  norm_y := Expression.makeSum1(list( Expression.expPow(arrayGet(y,j), DAE.RCONST(2.0)) for j in 1:m ));
  norm_y := Expression.makePureBuiltinCall("sqrt",{norm_y},DAE.T_REAL_DEFAULT);
  alpha := Expression.expMul(sgn_y1,norm_y);
end qrCalc_alpha;


protected function qrDecomposition
"
  author: Vitalij Ruge
"
  input array<DAE.Exp> A;
  input Integer n;
  input array<DAE.Exp> ib;
  input BackendDAE.EquationArray ieqns;
  input BackendDAE.Variables ivars;
  input Integer offset;
  input BackendDAE.Shared ishared;
  output array<DAE.Exp> R = arrayCreate(n*n,DAE.RCONST(0.0));
  output array<DAE.Exp> b = arrayCreate(n,DAE.RCONST(0.0));
  output BackendDAE.EquationArray oeqns = ieqns;
  output BackendDAE.Variables ovars = ivars;
  output BackendDAE.Shared oshared;
protected
  array<DAE.Exp> Q = arrayCreate(n*n,DAE.RCONST(0.0));
  array<DAE.Exp> v = arrayCreate(n,DAE.RCONST(0.0));
  array<DAE.Exp> u = arrayCreate(n,DAE.RCONST(0.0));
  array<DAE.Exp> w = arrayCreate(n,DAE.RCONST(0.0));
  array<DAE.Exp> e = arrayCreate(n,DAE.RCONST(0.0));
  array<DAE.Exp> vv = arrayCreate(n,DAE.RCONST(0.0));
  array<DAE.Exp> x,y,p;
  DAE.Exp a, ex;
  BackendDAE.Var tmpvar;
  String name;
  DAE.ComponentRef cr;
  Integer kk = 1;
  Integer m = n-1;
  Integer nn;
algorithm
//Gram–Schmidt process
  v := qrDecomposition1(A,n,kk);
  (u, oeqns, ovars, oshared) := BackendEquation.normalizationVec(v,"QR$NOM$" + intString(kk), offset, oeqns, ovars, ishared);

  for j in 1:n loop
    (a,_) := ExpressionSimplify.simplify(arrayGet(u,j));
    (a, oeqns, ovars,oshared) := BackendEquation.makeTmpEqnForExp(a, "QR$Q$" + intString(kk + (j-1)*n), offset, oeqns, ovars,oshared);
    arrayUpdate(Q, kk + (j-1)*n, a);
  end for;

  for k in 1:m loop
    v := qrDecomposition1(A,n,k+1);
    for j in 1:k loop
      u := qrDecomposition1(Q,n,j);
      (v, oeqns, ovars,oshared) := gramSchmidtProcessHelper(v,u,"QR$W$" + intString(kk) + "$" + intString(kk), offset, oeqns, ovars,oshared);
      kk := kk +1;
    end for;
    (u, oeqns, ovars, oshared) := BackendEquation.normalizationVec(v,"QR$NOM$" + intString(k+1), offset, oeqns, ovars, oshared);
    //qrDecomposition3(u, n, false, "u");
    for j in 1:n loop
      nn := k+1 + (j-1)*n;
      (a,_) := ExpressionSimplify.simplify(arrayGet(u,j));
      (a, oeqns, ovars, oshared) := BackendEquation.makeTmpEqnForExp(a, "QR$Q$" + intString(nn), offset, oeqns, ovars, oshared);
      arrayUpdate(Q, nn, a);
    end for;

  end for;
  //qrDecomposition3(Q, n, true, "Q");


  // R
  for i in 1:n loop
    x := qrDecomposition1(Q,n,i);
    m := (i-1)*n;
    //qrDecomposition3(x, n, false, "x" + intString(i));
    for j in i:n loop
      y := qrDecomposition1(A,n,j);
      a := Expression.makeScalarProduct(x,y);
      (a, oeqns, ovars,oshared) := BackendEquation.makeTmpEqnForExp(a, "QR$R$" + intString(m + j), offset, oeqns, ovars,oshared);
      arrayUpdate(R, m+j, a);
    end for;
  end for;

  //qrDecomposition3(R, n, true, "R");
  //qrDecomposition3(Q, n, true, "Q");
  // Q*b
  for i in 1:n loop
     x := qrDecomposition1(Q,n,i);
     //qrDecomposition3(x, n, false, "x" + intString(i));
     a := Expression.makeScalarProduct(x,ib);
     (a, oeqns, ovars,oshared) := BackendEquation.makeTmpEqnForExp(a, "QR$Qb$" + intString(i), offset, oeqns, ovars, oshared);
     arrayUpdate(b, i, a);
  end for;
  //qrDecomposition3(b, n, false, "Qb");

end qrDecomposition;

protected function qrDecomposition1
"return column of A"
  input array<DAE.Exp> A;
  input Integer sizeA;
  input Integer i;
  output array<DAE.Exp> column = arrayCreate(sizeA,DAE.RCONST(0.0)) "A(:,i)";
algorithm
  for j in 1:sizeA loop
    arrayUpdate(column, j, arrayGet(A,i + (j-1)*sizeA));
  end for;
end qrDecomposition1;

protected function qrDecomposition2
"return row of A"
  input array<DAE.Exp> A;
  input Integer sizeA;
  input Integer i "row";
  output array<DAE.Exp> row = arrayCreate(sizeA,DAE.RCONST(0.0)) "A(:,i)";
protected
  Integer k = i - 1;
algorithm
  for j in 1:sizeA loop
    arrayUpdate(row, j, arrayGet(A,j + k*sizeA));
  end for;
end qrDecomposition2;

protected function qrDecomposition3
"for debuge"
input array<DAE.Exp> A;
input Integer sizeA;
input Boolean isMat;
input String s;
protected
 Integer n = sizeA;
 Integer m = if isMat then sizeA else 1;
algorithm
     print("\n");
  for i in 1:n loop
     print("\n");
     for j in 1:m loop
       print(s + "(" + intString(i) + "," + intString(j) + ") = " + ExpressionDump.printExpStr(arrayGet(A, (i-1)*m + j)) + "\t");
     end for;
  end for;
     print("\n");
end qrDecomposition3;

protected function gramSchmidtProcessHelper
"
  author: Vitalij Ruge
  small step inside gram–schmidt process
"
  input array<DAE.Exp> w;
  input array<DAE.Exp> u;
  input String name "var name";
  input Integer offset;
  input BackendDAE.EquationArray ieqns;
  input BackendDAE.Variables ivars;
  input BackendDAE.Shared ishared;
  output array<DAE.Exp> v;
  output BackendDAE.EquationArray oeqns;
  output BackendDAE.Variables ovars;
  output BackendDAE.Shared oshared;
protected
  DAE.Exp h = Expression.makeScalarProduct(w,u);
  Integer n = arrayLength(w);
algorithm
  (h,oeqns,ovars,oshared) := BackendEquation.makeTmpEqnForExp(h, name + "_h", offset, ieqns, ivars, ishared);
  v := Array.map1(u, Expression.expMul, h);
  v := Expression.subVec(w,v);
  for i in 1:n loop
     (h,oeqns,ovars,oshared) := BackendEquation.makeTmpEqnForExp(arrayGet(v,i), name + "_" + intString(i), offset, oeqns, ovars, oshared);
     arrayUpdate(v,i,h);
  end for;

end gramSchmidtProcessHelper;

annotation(__OpenModelica_Interface="backend");
end ResolveLoops;
