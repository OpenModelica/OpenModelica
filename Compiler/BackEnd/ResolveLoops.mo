/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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
               resolveLoops.

  RCS: $Id$"

public import BackendDAE;
public import DAE;

protected import BackendDAEUtil;
protected import BackendEquation;
protected import BackendVariable;
protected import ComponentReference;
protected import Debug;
protected import Expression;
protected import ExpressionSimplify;
protected import Flags;
protected import HpcOmEqSystems;
protected import List;
protected import Util;

public function resolveLoops "author:Waurich TUD 2013-12
  traverses the equations and finds simple equations(i.e. linear functions 
  withcoefficients of 1 or -1). if these equations form loops, they will be 
  contracted.
  This happens especially in eletrical models. Here, kirchhoffs voltage and 
  current law can be applied."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := matchcontinue(inDAE)
    local
      BackendDAE.EqSystems eqSysts;
      BackendDAE.Shared shared;
      
    case (_) equation
      true = Flags.isSet(Flags.RESOLVE_LOOPS); 
      BackendDAE.DAE(eqs=eqSysts, shared=shared) = inDAE;
      (eqSysts, (shared, _)) = List.mapFold(eqSysts, resolveLoops_main, (shared, 1));
      outDAE = BackendDAE.DAE(eqSysts, shared);
    then outDAE;
      
    else
    then inDAE;   
  end matchcontinue;   
end resolveLoops;

protected function resolveLoops_main "author: Waurich TUD 2014-01
  Collects the linear equations of the whole DAE. bipartite graphs of the
  eqSystem can be output. All variables and equations which do not belong to a
  loop will be removed. the loops will be analysed and resolved"
  input BackendDAE.EqSystem eqSysIn;
  input tuple<BackendDAE.Shared,Integer> sharedTplIn;
  output BackendDAE.EqSystem eqSysOut;
  output tuple<BackendDAE.Shared,Integer> sharedTplOut;
algorithm
  (eqSysOut,sharedTplOut) := matchcontinue(eqSysIn,sharedTplIn)
    local
      Integer numSimpEqs, numVars, numSimpVars, sysIdx;
      list<Integer> eqMapping, varMapping, nonLoopVarIdcs, nonLoopEqIdcs, loopEqIdcs, loopVarIdcs, eqCrossLst, varCrossLst;
      list<list<Integer>> partitions, loops;
      BackendDAE.Variables vars,simpVars;
      BackendDAE.EquationArray eqs,simpEqs;
      BackendDAE.EqSystem eqSys;
      BackendDAE.IncidenceMatrix m,mT,m_cut, mT_cut, m_after, mT_after;
      BackendDAE.Matching matching;
      BackendDAE.Shared shared, sharedIn;
      BackendDAE.StateSets stateSets;
      list<DAE.ComponentRef> crefs;
      list<BackendDAE.Equation> eqLst,simpEqLst,resolvedEqs;
      list<BackendDAE.Var> varLst,simpVarLst;
    case(_,(sharedIn,sysIdx))
      equation
        BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqs,m=_,mT=_,stateSets=stateSets) = eqSysIn;
        eqLst = BackendEquation.equationList(eqs);
        varLst = BackendVariable.varList(vars);
  
        // build the incidence matrix for the whole System
        numSimpEqs = listLength(eqLst);
        numVars = listLength(varLst);
        m = arrayCreate(numSimpEqs, {});
        mT = arrayCreate(numVars, {});
        (m,mT) = BackendDAEUtil.incidenceMatrixDispatch(vars,eqs,{},mT, 0, numSimpEqs, intLt(0, numSimpEqs), BackendDAE.ABSOLUTE(), NONE()); 
        HpcOmEqSystems.dumpEquationSystemGraphML1(vars,eqs,m,"whole System_"+&intString(sysIdx));
          //BackendDump.dumpEquationArray(eqs,"the complete DAE");
           
        // get the linear equations and their vars
        simpEqLst = BackendEquation.traverseBackendDAEEqns(eqs, getSimpleEquations, {});
        eqMapping = List.map1(simpEqLst,List.position,eqLst);//index starts at zero
        eqMapping = List.map1(eqMapping,intAdd,1);
        simpEqs = BackendEquation.listEquation(simpEqLst);
        crefs = BackendEquation.getAllCrefFromEquations(simpEqs);
        (simpVarLst,varMapping) = BackendVariable.getVarLst(crefs,vars,{},{});
        simpVars = BackendVariable.listVar1(simpVarLst);  

        // build the incidence matrix for the linear equations
        numSimpEqs = listLength(simpEqLst);
        numVars = listLength(simpVarLst);
        m = arrayCreate(numSimpEqs, {});
        mT = arrayCreate(numVars, {});
        (m,mT) = BackendDAEUtil.incidenceMatrixDispatch(simpVars,simpEqs,{},mT, 0, numSimpEqs, intLt(0, numSimpEqs), BackendDAE.ABSOLUTE(), NONE()); 
        HpcOmEqSystems.dumpEquationSystemGraphML1(simpVars,simpEqs,m,"rL_simpEqs_"+&intString(sysIdx));
        
        //partition graph
        partitions = arrayList(partitionBipartiteGraph(m,mT));
        partitions = List.filterOnTrue(partitions,List.hasSeveralElements);
          //print("the partitions for system "+&intString(sysIdx)+&" : \n"+&stringDelimitList(List.map(partitions,HpcOmTaskGraph.intLstString),"\n")+&"\n");       
        
        // cut the deadends (vars and eqs outside of the loops)
        m_cut = arrayCopy(m);
        mT_cut = arrayCopy(mT);
        (loopEqIdcs,loopVarIdcs,nonLoopEqIdcs,nonLoopVarIdcs) = resolveLoops_cutNodes(m_cut,mT_cut,eqMapping,varMapping,varLst,eqLst);
        HpcOmEqSystems.dumpEquationSystemGraphML1(simpVars,simpEqs,m_cut,"rL_loops_"+&intString(sysIdx));
           
        // handle the partitions separately, resolve the loops in the partitions, insert the resolved equation
        eqLst = resolveLoops_resolvePartitions(partitions,m_cut,mT_cut,m,mT,eqMapping,varMapping,eqLst,varLst,nonLoopEqIdcs);      
        eqs = BackendEquation.listEquation(eqLst);
          //BackendDump.dumpEquationList(eqLst,"the complete DAE after resolving");  
        
        // get the graphML for the resolved System
        simpEqLst = List.map1(eqMapping,List.getIndexFirst,eqLst);
        simpEqs = BackendEquation.listEquation(simpEqLst);
        numSimpEqs = listLength(simpEqLst);
        numVars = listLength(simpVarLst);
        m_after = arrayCreate(numSimpEqs, {});
        mT_after = arrayCreate(numVars, {});
        (m_after,mT_after) = BackendDAEUtil.incidenceMatrixDispatch(simpVars,simpEqs,{},mT, 0, numSimpEqs, intLt(0, numSimpEqs), BackendDAE.ABSOLUTE(), NONE()); 
        HpcOmEqSystems.dumpEquationSystemGraphML1(simpVars,simpEqs,m_after,"rL_after_"+&intString(sysIdx));
        
        eqSys = BackendDAE.EQSYSTEM(vars,eqs,NONE(),NONE(),BackendDAE.NO_MATCHING(),stateSets);
      then
        (eqSys,(sharedIn,sysIdx+1));
    else
      equation
        (sharedIn,sysIdx) = sharedTplIn;
      then
        (eqSysIn,(sharedIn,sysIdx+1));
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
        true = List.isEmpty(partition);
        eqLst = resolveLoops_resolvePartitions(rest,mIn,mTIn,m_uncut,mT_uncut,eqMapping,varMapping,daeEqs,daeVars,nonLoopEqs);
    then
      eqLst;
    case(partition::rest,_,_,_,_,_,_,_,_,_)
      equation   
        // search the partitions for loops 
        (_,partition,_) = List.intersection1OnTrue(partition,nonLoopEqs,intEq);
        //print("\nanalyse the partition "+&stringDelimitList(List.map(partition,intString),",")+&"\n");
        (loops,eqCrossLst,varCrossLst) = resolveLoops_findLoops({partition},mIn,mTIn,{},{},{});
        loops = List.filterOnTrue(loops,List.isNotEmpty);
        //print("the loops in this partition: \n"+&stringDelimitList(List.map(loops,HpcOmTaskGraph.intLstString),"\n")+&"\n");      
  
        // check if its worth to resolve the loops
        loops = List.filter1OnTrue(loops,evaluateLoop,(m_uncut,mT_uncut,eqCrossLst));
        //print("the loops that will be resolved: \n"+&stringDelimitList(List.map(loops,HpcOmTaskGraph.intLstString),"\n")+&"\n");
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

       loopVarLst = List.map1(loopEqs,Util.arrayGetIndexFirst,mIn);
       loopVars = List.flatten(loopVarLst);
       loopVars = List.unique(loopVars);
       (nonLoopVars,loopVars,_) = List.intersection1OnTrue(loopVars,nonLoopVars,intEq);

       // remove nonLoopNodes from the incidenceMatrix
       List.map2_0(nonLoopVars,Util.arrayUpdateIndexFirst,{},mTIn);
       List.map2_0(nonLoopEqs,Util.arrayUpdateIndexFirst,{},mIn);
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
  input tuple<BackendDAE.Equation,list<BackendDAE.Equation>> tplIn;
  output tuple<BackendDAE.Equation,list<BackendDAE.Equation>> tplOut;
protected
  BackendDAE.Equation eq, eqIn;
  list<BackendDAE.Equation> eqLst;
  Boolean isSimple;
algorithm
  (eqIn,eqLst) := tplIn;
  (eq,isSimple) := BackendEquation.traverseBackendDAEExpsEqn(eqIn,isAddOrSubExp,true);
  eqLst := Util.if_(isSimple,eq::eqLst,eqLst);
  tplOut := (eqIn,eqLst);
end getSimpleEquations;

protected function resolveLoops_findLoops "author:Waurich TUD 2014-02
  gets the crossNodes for the partitions and searches for loops"
  input list<list<Integer>> partitionsIn;
  input BackendDAE.IncidenceMatrix mIn;  // the whole system of simpleEquations
  input BackendDAE.IncidenceMatrixT mTIn;
  input list<list<Integer>> loopsIn;
  input list<Integer> crossEqsIn;
  input list<Integer> crossVarsIn;
  output list<list<Integer>> loopsOut;
  output list<Integer> crossEqsOut;
  output list<Integer> crossVarsOut;
algorithm
  (loopsOut,crossEqsOut,crossVarsOut) := match(partitionsIn,mIn,mTIn,loopsIn,crossEqsIn,crossVarsIn)
    local
      list<Integer> partition, eqCrossLst, varCrossLst, partitionVars;
      list<list<Integer>> loops, rest, eqVars;
    case({},_,_,_,_,_)
      equation
      then
        (loopsIn,crossEqsIn,crossVarsIn);
    case(partition::rest,_,_,_,_,_)
      equation      
       // get the eqCrossNodes and varCrossNodes i.e. nodes with more than 2 edges
       eqVars = List.map1(partition,Util.arrayGetIndexFirst,mIn);
       partitionVars = List.flatten(eqVars);
       partitionVars = List.unique(partitionVars);
       eqCrossLst = List.fold2(partition,gatherCrossNodes,mIn,mTIn,{});
       varCrossLst = List.fold2(partitionVars,gatherCrossNodes,mTIn,mIn,{});
                
       // search the partitions for loops
       loops = resolveLoops_findLoops2(partition,partitionVars,eqCrossLst,varCrossLst,mIn,mTIn);
       loops = listAppend(loops,loopsIn);
       eqCrossLst = listAppend(eqCrossLst,crossEqsIn);
       varCrossLst = listAppend(varCrossLst,crossVarsIn);
       (loops,eqCrossLst,varCrossLst) = resolveLoops_findLoops(rest,mIn,mTIn,loops,eqCrossLst,varCrossLst);
      then
        (loops,eqCrossLst,varCrossLst);
  end match;
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
    case(_,_,eqIdx::eqCrossLst,{},_,_)
      equation 
          //print("partition has only eqCrossNodes\n");
        // get the paths between the crossEqNodes and order them according to their length
        allPaths = getPathTillNextCrossEq(eqCrossLstIn,mIn,mTIn,eqCrossLstIn,{},{});    
        allPaths = List.sort(allPaths,List.listIsLonger);
          //print("all paths: \n"+&stringDelimitList(List.map(allPaths,HpcOmTaskGraph.intLstString)," / ")+&"\n");   
        paths1 = List.fold1(allPaths,getReverseDoubles,allPaths,{});   // all paths with just one direction
        paths0 = List.unique(paths1);  // only the paths between the eqs without concerning the vars in between
        simpleLoops = getDoubles(paths1,{});  // get 2 adjacent equations which form a simple loop i.e. they share 2 variables
        simpleLoops = List.unique(simpleLoops); 
          //print("all simpleLoop-paths: \n"+&stringDelimitList(List.map(simpleLoops,HpcOmTaskGraph.intLstString)," / ")+&"\n");  
        (_,paths,_) = List.intersection1OnTrue(paths1,simpleLoops,intLstIsEqual);
        
        paths0 = List.sort(paths,List.listIsLonger);  // solve the small loops first
        (connectedPaths,loopConnectors) = connect2PathsToLoops(paths0,{},{});
        loopConnectors = List.filter1OnTrue(loopConnectors,connectsLoops,simpleLoops);
        simpleLoops = listAppend(simpleLoops,loopConnectors);
        
        //print("all simpleLoop-paths: \n"+&stringDelimitList(List.map(simpleLoops,HpcOmTaskGraph.intLstString)," / ")+&"\n");  
        subLoop = connectPathsToOneLoop(simpleLoops,{});  // try to build a a closed loop from these paths
        isNoSingleLoop = List.isEmpty(subLoop);
        simpleLoops = Util.if_(isNoSingleLoop,simpleLoops,{subLoop});          
        paths0 = listAppend(simpleLoops,connectedPaths);
        paths0 = sortPathsAsChain(paths0);
        
        //print("all paths to be resolved: \n"+&stringDelimitList(List.map(paths0,HpcOmTaskGraph.intLstString)," / ")+&"\n");
      then
        paths0; 
    case(_,_,{},varIdx::varCrossLst,_,_)
      equation 
          //print("partition has only varCrossNodes\n");   
        // get the paths between the crossVarNodes and order them according to their length
        paths = getPathTillNextCrossEq(varCrossLstIn,mTIn,mIn,varCrossLstIn,{},{});
        paths = List.sort(paths,List.listIsLonger);
        paths = listReverse(paths);
          //print("from all the paths: \n"+&stringDelimitList(List.map(paths,HpcOmTaskGraph.intLstString)," / ")+&"\n");

        (paths0,paths1) =  List.extract1OnTrue(paths,listLengthIs,listLength(List.last(paths)));
          //print("the shortest paths: \n"+&stringDelimitList(List.map(paths0,HpcOmTaskGraph.intLstString)," / ")+&"\n");
        
        paths1 = Util.if_(List.isEmpty(paths1),paths0,paths1);
        closedPaths = List.map1(paths1,closePathDirectly,paths0);
        closedPaths = List.fold1(closedPaths,getReverseDoubles,closedPaths,{});   // all paths with just one direction
        closedPaths = List.map(closedPaths,List.unique);
        closedPaths = List.map1(closedPaths,getEqNodesForVarLoop,mTIn);// get the eqs for these varLoops
          //print("solve the smallest loops: \n"+&stringDelimitList(List.map(closedPaths,HpcOmTaskGraph.intLstString)," / ")+&"\n");
       then
        closedPaths;
    case(_,_,{},{},_,_)
      equation
         // no crossNodes
           //print("no crossNodes\n");
         varEqsLst = List.map1(eqsIn,Util.arrayGetIndexFirst,mIn);
         isNoSingleLoop = List.exist(varEqsLst,List.isEmpty);
         subLoop = Util.if_(isNoSingleLoop,{},eqsIn);
       then
         {subLoop};
    case(_,_,eqIdx::eqCrossLst,varIdx::varCrossLst,_,_)
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
  startNode := List.first(path);
  endNode := List.last(path);
  // the startNode is connected to a loop
  loops1 := List.filter1OnTrue(allLoops,firstInListIsEqual,startNode);
  loops2 := List.filter1OnTrue(allLoops,lastInListIsEqual,startNode);
  b1 := List.isNotEmpty(loops1) or List.isNotEmpty(loops2);
  // the endNode is connected to a loop
  loops1 := List.filter1OnTrue(allLoops,firstInListIsEqual,endNode);
  loops2 := List.filter1OnTrue(allLoops,lastInListIsEqual,endNode);
  b2 := List.isNotEmpty(loops1) or List.isNotEmpty(loops2);
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
    case(_,startNode::restPath)
      equation
        nextPaths1 = List.filter1OnTrue(allPathsIn, firstInListIsEqual, startNode);
        nextPaths2 = List.filter1OnTrue(allPathsIn, lastInListIsEqual, startNode);
        nextPaths1 = listAppend(nextPaths1,nextPaths2);
        nextPath = List.first(nextPaths1);
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
        nextPath = List.first(nextPaths1);
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
  case(loop1::rest,crossEq::crossEqs,{},_,_,_,_,_,_,_)
    equation
      // only eqCrossNodes
      //print("only eqCrossNodes\n");
      loop1 = List.unique(loop1);
      resolvedEq = resolveClosedLoop(loop1,mIn,mTIn,eqMapping,varMapping,eqLstIn,varLstIn);
      
      // get the equation that will be replaced and the rest
      (crossEqs,eqs,_) = List.intersection1OnTrue(loop1,eqCrossLstIn,intEq);  // replace a crossEq in the loop       
      (replEqs,_,_) = List.intersection1OnTrue(replEqsIn,loop1,intEq);  // just consider the already replaced equations in this loop

      // first try to replace a non cross node, otherwise an already replaced eq, or if none of them is available take a crossnode (THIS IS NOT YET CLEAR)
      pos = Debug.bcallret1(List.isNotEmpty(crossEqs),List.first,crossEqs,-1); 
      pos = Debug.bcallret1(List.isNotEmpty(replEqs),List.first,replEqs,pos); 
      pos = Debug.bcallret1(List.isNotEmpty(eqs),List.first,eqs,pos); // CHECK THIS

      eqs = List.deleteMember(loop1,pos);
        //print("contract eqs: "+&stringDelimitList(List.map(eqs,intString),",")+&" to eq "+&intString(pos)+&"\n");
      
      // get the corresponding vars
      eqVars = List.map1(loop1,Util.arrayGetIndexFirst,mIn);
      vars = List.flatten(eqVars);
      loopVars = doubleEntriesInLst(vars,{},{});  // the vars in the loop
      (_,adjVars,_) = List.intersection1OnTrue(vars,loopVars,intEq); // the vars adjacent to the loop

      // update incidenceMatrix
      List.map2_0(loopVars,Util.arrayUpdateIndexFirst,{},mTIn);  //delete the vars in the loop
      List.map2_0(adjVars,arrayGetDeleteInLst,loop1,mTIn);  // remove the loop eqs from the adjacent vars
      List.map2_0(adjVars,arrayGetAppendLst,{pos},mTIn);  // redirect the adjacent vars to the replaced eq
      List.map2_0(loop1,Util.arrayUpdateIndexFirst,{},mIn);  //delete the eqs in the loop
      _ = arrayUpdate(mIn,pos,adjVars);  // redirect the replaced equation to the vars outside of the loops
      
      // update remaining paths
      rest = List.map2(rest,replaceContractedNodes,pos,eqs);
      rest = List.unique(rest);
        //print("the remaining paths: "+&stringDelimitList(List.map(rest,HpcOmTaskGraph.intLstString),"\n")+&"\n\n");
        
      // replace Equation
        //print("replace equation "+&intString(pos)+&"\n");
      replEqs = pos::replEqsIn;
      pos = listGet(eqMapping,pos);
      eqLst = List.replaceAt(resolvedEq,pos-1,eqLstIn);
      
      (eqLst,replEqs) = resolveLoops_resolveAndReplace(rest,eqCrossLstIn,varCrossLstIn,mIn,mTIn,eqMapping,varMapping,eqLst,varLstIn,replEqs);
    then
      (eqLst,replEqs);
  case(loop1::rest,{},crossVar::crossVars,_,_,_,_,_,_,_)
    equation
      // only varCrossNodes
        //print("only varCrossNodes\n");
      loop1 = List.unique(loop1);
      resolvedEq = resolveClosedLoop(loop1,mIn,mTIn,eqMapping,varMapping,eqLstIn,varLstIn);

      // get the equation that will be replaced and the rest
      (replEqs,_,eqs) = List.intersection1OnTrue(replEqsIn,loop1,intEq);  // just consider the already replaced equations in this loop
      
      //priorize the not yet replaced equations
      eqs = priorizeEqsWithVarCrosses(eqs,mIn,varCrossLstIn);      
        //print("priorized eqs: "+&stringDelimitList(List.map(eqs,intString),",")+&"\n");

      // first try to replace a non cross node, otherwise an already replaced eq      
      pos = Debug.bcallret1(List.isNotEmpty(replEqs),List.first,replEqs,-1); 
      pos = Debug.bcallret1(List.isNotEmpty(eqs),List.first,eqs,pos);

      eqs = List.deleteMember(loop1,pos);
        //print("contract eqs: "+&stringDelimitList(List.map(eqs,intString),",")+&" to eq "+&intString(pos)+&"\n");
      
      // get the corresponding vars
      eqVars = List.map1(loop1,Util.arrayGetIndexFirst,mIn);
      vars = List.flatten(eqVars);
      loopVars = doubleEntriesInLst(vars,{},{});  // the vars in the loop
      (crossVars,loopVars,_) = List.intersection1OnTrue(loopVars,varCrossLstIn,intEq);  // some crossVars have to remain
      //print("loopVars: "+&stringDelimitList(List.map(loopVars,intString),",")+&"\n");
      
      (_,adjVars,_) = List.intersection1OnTrue(vars,loopVars,intEq); // the vars adjacent to the loop
      adjVars = listAppend(crossVars,adjVars);
      adjVars = List.unique(adjVars);
      
      // update incidenceMatrix
      List.map2_0(loopVars,Util.arrayUpdateIndexFirst,{},mTIn);  //delete the vars in the loop
      List.map2_0(adjVars,arrayGetDeleteInLst,loop1,mTIn);  // remove the loop eqs from the adjacent vars
      List.map2_0(adjVars,arrayGetAppendLst,{pos},mTIn);  // redirect the adjacent vars to the replaced eq
      List.map2_0(loop1,Util.arrayUpdateIndexFirst,{},mIn);  //delete the eqs in the loop
      _ = arrayUpdate(mIn,pos,adjVars);  // redirect the replaced equation to the vars outside of the loops
      
      // update remaining paths
      rest = List.map2(rest,replaceContractedNodes,pos,eqs);
      rest = List.unique(rest);
        //print("the remaining paths: "+&stringDelimitList(List.map(rest,HpcOmTaskGraph.intLstString),"\n")+&"\n\n");
        
      // replace Equation
        //print("replace equation "+&intString(pos)+&"\n");
      replEqs = pos::replEqsIn;
      pos = listGet(eqMapping,pos);
      eqLst = List.replaceAt(resolvedEq,pos-1,eqLstIn);
      
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
      (pos::removeCrossEqs) = crossEqs;  // the equation that will be replaced = pos
      eqVars = List.map1(loop1,Util.arrayGetIndexFirst,mIn);
      vars = List.flatten(eqVars);     
        //print("delete vars: "+&stringDelimitList(List.map(vars,intString),",")+&" in the eqs: "+&stringDelimitList(List.map(crossEqs,intString),",")+&"\n");
      List.map2_0(loop1,Util.arrayUpdateIndexFirst,{},mIn);  //delete the equations in the loop
      List.map2_0(vars,Util.arrayUpdateIndexFirst,{},mTIn);  //delete the vars from the loop
      
      // replace Equation
        //print("replace equation "+&intString(pos)+&"\n");
      pos = listGet(eqMapping,pos);
      replEqs = pos::replEqsIn;
      eqLst = List.replaceAt(resolvedEq,pos-1,eqLstIn);
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
          adjSecNodesLst = List.map1(adjPrimNodes,Util.arrayGetIndexFirst,mIn);
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
        (elem::elemLst) = elemLstIn;
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
  varEqLst := List.map1(varIdcs,Util.arrayGetIndexFirst,mTIn);  // get the eqNodes from these loops
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
    //print("solve the loop: "+&stringDelimitList(List.map(loop1,intString),",")+&"\n");
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
    case(_,{eqIdx1},_,_,_,_,_,_)
      equation
          //print("finished loop\n");
      then
        eqIn;
    case(_,(eqIdx1::restLoop),_,_,_,_,_,_)
      equation   
        // the equation to add
        eqIdx2 = List.first(restLoop);
        eqDaeIdx2 = listGet(eqMapping,eqIdx2);
        eq2 = listGet(daeEqsIn,eqDaeIdx2);
        
        // get the vars that are shared of the 2 equations
        adjVars1 = arrayGet(m,eqIdx1);
        adjVars2 = arrayGet(m,eqIdx2);
        (adjVars,adjVars1,_) = List.intersection1OnTrue(adjVars1,adjVars2,intEq); 

        // just take  the first
        varIdx = listGet(adjVars,1);
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

protected function sortLoop "author:Waurich TUD 2014-01
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
        varEqs = List.map1(vars,Util.arrayGetIndexFirst,mT);
        eqs = List.flatten(varEqs);
        eqs = List.unique(eqs);
        (eqs,_,_) = List.intersection1OnTrue(eqs,loopIn,intEq);
        next = List.first(eqs);
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
        startNode = List.first(pathIn);
        endNode = List.last(pathIn);
        true = intEq(startNode,endNode);
      then
        pathIn;
    case(_,_)
      equation
        // it is an open path
        startNode::restPath = pathIn;
        endNode = List.last(pathIn);
        path = findPathByEnds(pathLstIn,startNode,endNode);
        closed = List.isNotEmpty(path);
        path = Util.if_(closed,path,{});
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
        startNode = List.first(path);
        b1 = intEq(startNode,endNodeIn);
        endNode = List.last(path);
        b2 = intEq(endNode,startNodeIn);
        path = Debug.bcallret3(not(b1 and b2),findPathByEnds,pathLst,startNodeIn,endNodeIn,path);
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
  get the entries in the list which occure multiple times.
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
        adjEqs = List.map1(adjVars,Util.arrayGetIndexFirst,mTIn);
        adjEqs = List.map1(adjEqs,List.deleteMember,crossEq);// REMARK: this works only if there are no varCrossNodes
        adjEqs = List.filterOnTrue(adjEqs,List.isNotEmpty);
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
        lastEq = List.first(pathStart);
        prevEq = List.second(pathStart);
        adjVars = arrayGet(mIn,lastEq);
        adjEqs = List.map1(adjVars,Util.arrayGetIndexFirst,mTIn);
        adjEqs = List.map1(adjEqs,List.deleteMember,lastEq);// REMARK: this works only if there are no varCrossNodes
        adjEqs = List.filterOnTrue(adjEqs,List.isNotEmpty);
        nextEqs = List.map(adjEqs,List.first);
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
  entryOut := Util.if_(repl,nodeIn,entryIn);
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
  (crossVars,_,_) := List.intersection1OnTrue(eqVars,varCrossLst,intEq);
  numCrossVars := listLength(crossVars);
  b0 := intEq(numCrossVars,0);
  b1 := intEq(numCrossVars,1);
  b2 := intGe(numCrossVars,2);
  Debug.bcall3(b0,arrayGetAppendLst,1,{eq},priorities);
  Debug.bcall3(b1,arrayGetAppendLst,2,{eq},priorities);
  Debug.bcall3(b2,arrayGetAppendLst,3,{eq},priorities);
end priorizeEqsWithVarCrosses2;

protected function evaluateLoop
  input list<Integer> loopIn;
  input tuple<BackendDAE.IncidenceMatrix,BackendDAE.IncidenceMatrixT,list<Integer>> tplIn;
  output Boolean resolve;
protected
  Integer numInLoop,numOutLoop;
  list<Integer> nonLoopEqs,nonLoopVars,loopEqs, loopVars, allVars, eqCrossLst;
  list<list<Integer>> eqVars;
  BackendDAE.IncidenceMatrix m;
  BackendDAE.IncidenceMatrixT mT;
algorithm
  (m,mT,eqCrossLst) := tplIn;
  eqVars := List.map1(loopIn,Util.arrayGetIndexFirst,m);
  allVars := List.flatten(eqVars);
  loopVars := doubleEntriesInLst(allVars,{},{});
  //print("loopVars : "+&stringDelimitList(List.map(loopVars,intString),",")+&"\n");
  
  // check if its worth to resolve the loop. Therefore compare the amount of vars in and outside the loop
  (_,nonLoopVars,_) := List.intersection1OnTrue(allVars,loopVars,intEq);
  //print("nonLoopVars : "+&stringDelimitList(List.map(nonLoopVars,intString),",")+&"\n");
  (eqCrossLst,_,_) := List.intersection1OnTrue(loopVars,eqCrossLst,intEq); 
  numInLoop := listLength(loopVars);
  numOutLoop := listLength(nonLoopVars);
  resolve := intGe(numInLoop,numOutLoop-1);
end evaluateLoop;

protected function sumUp2Equations "author:Waurich TUD 2013-12
  sums up or subtracts 2 equations, depending on the boolean (true=+, false =-)"
  input Boolean sumUp;
  input BackendDAE.Equation eq1;
  input BackendDAE.Equation eq2;
  output BackendDAE.Equation eqOut;
protected
  DAE.Exp exp1,exp2,exp3,exp4;
algorithm
  BackendDAE.EQUATION(exp=exp1,scalar=exp2) := eq1;
  BackendDAE.EQUATION(exp=exp3,scalar=exp4) := eq2;
  exp1 := sumUp2Expressions(sumUp,exp1,exp3);
  exp2 := sumUp2Expressions(sumUp,exp2,exp4);
  exp2 := sumUp2Expressions(false,exp2,exp1);
  (exp2,_) := ExpressionSimplify.simplify(exp2);
  exp1 := DAE.RCONST(0.0);
  eqOut := BackendDAE.EQUATION(exp1,exp2,DAE.emptyElementSource,false);
end sumUp2Equations;

protected function CRefIsPosOnRHS "author:Waurich TUD 2013-12
  checks if the given cref occurs with a positiv algebraic sign on the right 
  hand side of the equation. if its on the left hand side the algebraic sign 
  has to be negated."
  input DAE.ComponentRef crefIn;
  input BackendDAE.Equation eqIn;
  output Boolean isPos;
algorithm
  isPos := matchcontinue(crefIn,eqIn)
    local
      Boolean exists1, exists2 ,sign1, sign2;
      DAE.Exp e1,e2;
    case(_,BackendDAE.EQUATION(exp = e1,scalar = e2,source=_,differentiated=_))
      equation
        (exists1,sign1) = expIsCref(e1,crefIn);
        (exists2,sign2) = expIsCref(e2,crefIn);
        sign1 = Util.if_(exists1,not sign1,sign2);
     then
       sign1;
    else
      equation
        print("add a case to CRefIsPosOnRHS\n");
      then
        fail();
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
  case(DAE.BINARY(exp1=exp1, operator = DAE.SUB(ty=_), exp2=exp2),_)
    equation
      //exp1-exp2
      (exists1,sign1) = expIsCref(exp1,crefIn); 
      (exists2,sign2) = expIsCref(exp2,crefIn);
      sign2 = boolNot(sign2);
      exists = boolOr(exists1,exists2);
      sign = Util.if_(exists1,sign1,false);
      sign = Util.if_(exists2,sign2,sign);
    then
      (exists,sign);
  case(DAE.BINARY(exp1=exp1, operator = DAE.ADD(ty=_), exp2=exp2),_)
    equation
      //exp1+exp2
      (exists1,sign1) = expIsCref(exp1,crefIn); 
      (exists2,sign2) = expIsCref(exp2,crefIn);
      exists = boolOr(exists1,exists2);
      sign = Util.if_(exists1,sign1,false);
      sign = Util.if_(exists2,sign2,sign);
    then
      (exists,sign);
  case(DAE.UNARY(operator=DAE.UMINUS(ty=_),exp=exp1),_)
    equation
      // -(exp)
      (exists,sign) = expIsCref(exp1,crefIn);
      sign = boolNot(sign);
    then
      (exists,sign);
  case(DAE.RCONST(real=_),_)
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

protected function partitionBipartiteGraph "author: Waurich TUD 2013-12
  checks if there are independent subgraphs in the BIPARTITE graph. the given 
  indeces refer to the equation indeces (rows in the incidenceMatrix)
  The varCrossNodes will divide/cut the partitions."
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  output array<list<Integer>> partitionsOut;
protected
  Integer numParts, numRows, startNode;
  array<Integer> markNodes;
  array<list<Integer>> partitions;
  list<Integer> emptyRows, range, fullRows;
algorithm
  numRows := arrayLength(m);
  range := List.intRange(numRows);
  emptyRows := List.fold1(range, arrayGetIsEmptyLst, m, {});
  (_,fullRows,_) := List.intersection1OnTrue(range,emptyRows,intEq);
  startNode := List.first(fullRows);
  // mark the nodes
  markNodes := arrayCreate(arrayLength(m),0);
  List.map2_0(emptyRows,Util.arrayUpdateIndexFirst,-1,markNodes);
  (markNodes,numParts) := colorNodePartitions(m,mT,{startNode},emptyRows,markNodes,1);
  partitions := arrayCreate(numParts,{});
  partitionsOut := List.fold1(fullRows,getPartitions,markNodes,partitions);
end partitionBipartiteGraph;

protected function getPartitions "author:Waurich TUD 2013-12
  goes through the markedArray and writes the index to the corresponding (the 
  entry in the marked array) partition section."
  input Integer idx;
  input array<Integer> markedArray;
  input array<list<Integer>> partitionArrayIn;
  output array<list<Integer>> partitionArrayOut;
protected
  Boolean b;
  Integer entry;
  list<Integer> partition;
algorithm
  entry := arrayGet(markedArray,idx);
  partition := arrayGet(partitionArrayIn,entry);
  partition := idx::partition;
  partitionArrayOut := arrayUpdate(partitionArrayIn,entry,partition); 
end getPartitions;

protected function colorNodePartitions "author:Waurich TUD 2013-12
  helper for partitionsGraph1."
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input list<Integer> checkNextIn;
  input list<Integer> alreadyChecked;
  input array<Integer> markNodesIn;
  input Integer currNumberIn;
  output array<Integer> markNodesOut;
  output Integer currNumberOut;
protected
  Boolean hasChanged;
  Integer node, currNumber;
  array<Integer> markNodes;
  list<Integer> rest, vars, nextEqs, eqs, checked;
algorithm
 (markNodesOut,currNumberOut) := matchcontinue(m,mT,checkNextIn,alreadyChecked,markNodesIn,currNumberIn)
    local
    case(_,_,{0},_,_,_)
      equation
        currNumber = currNumberIn-1;
        then
          (markNodesIn,currNumber);
    case(_,_,node::rest,_,_,_)
      equation
        // get adjacent equation nodes
        checked = node::alreadyChecked;
        vars = arrayGet(m,node);
        true = List.isNotEmpty(vars);
        eqs = List.fold1(vars,getArrayEntryAndAppend,mT,{});
        (_,eqs,_) = List.intersection1OnTrue(eqs,checked,intEq);  

        //write the eq as marked in the array and check if this is a new equation
        (markNodes,hasChanged) = arrayUpdateAndCheckChange(node,currNumberIn,markNodesIn);
        // get the next nodes
        nextEqs = listAppend(eqs,rest);
        nextEqs = List.unique(nextEqs);
        (markNodes,currNumber) = colorNodePartitions(m,mT,nextEqs,checked,markNodes,currNumberIn);
      then
        (markNodes,currNumber);     
    
    case(_,_,{},_,_,_)
      equation
        node = Util.arrayMemberNoOpt(markNodesIn,arrayLength(markNodesIn)+1,0);
        (markNodes,currNumber) = colorNodePartitions(m,mT,{node},alreadyChecked,markNodesIn,currNumberIn+1);
        then
          (markNodes,currNumber);
  end matchcontinue;
end colorNodePartitions;  

protected function arrayUpdateAndCheckChange
  input Integer eq;
  input Integer currNumber;
  input array<Integer> markNodesIn;
  output array<Integer> markNodesOut;
  output Boolean changedOut;
algorithm
  (markNodesOut,changedOut) := match(eq,currNumber,markNodesIn)
    local
      Boolean hasChanged, isAnotherPartition;
      Integer entry;
      array<Integer> markNodes;
    case(_,_,_)
      equation
        entry = arrayGet(markNodesIn,eq);
        hasChanged = intEq(entry,0);
        isAnotherPartition = intNe(entry,currNumber);
        isAnotherPartition = boolAnd(boolNot(hasChanged),isAnotherPartition);
        Debug.bcall(isAnotherPartition,print,"in arrayUpdateAndGetNextEqs: "+&intString(eq)+&" cannot be assigned to a partition.check this"+&"\n");
        markNodes = arrayUpdate(markNodesIn,eq,currNumber);
      then
        (markNodes,hasChanged);
  end match;      
end arrayUpdateAndCheckChange;

protected function arrayGetIsEmptyLst
  input Integer idx;
  input array<list<Integer>> arrayIn;
  input list<Integer> lstIn;
  output list<Integer> lstOut;
protected
  list<Integer> row;
algorithm
  row := arrayGet(arrayIn,idx);
  row := Util.if_(List.isEmpty(row),{idx},{});
  lstOut := listAppend(lstIn,row);
end arrayGetIsEmptyLst;

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
  lstOut := Util.if_(isCross,idx::lstIn,lstIn);
end gatherCrossNodes;

protected function isAddOrSubExp
  input tuple<DAE.Exp, Boolean> inTpl;
  output tuple<DAE.Exp, Boolean> outTpl;
algorithm
  outTpl := match(inTpl)
    local
      Boolean b;
      DAE.Exp exp,exp1,exp2,exp11,exp12;
      DAE.Operator op;
      DAE.ComponentRef cref;
      DAE.Type ty;
    case((DAE.CREF(componentRef=cref, ty = ty),true))
      equation
        //x
        (exp,b) = inTpl;
      then
        ((exp,b));
    case((DAE.UNARY(operator=_,exp=exp1),true))
      equation
        // (-x)
        (exp,b) = inTpl;
        ((_,b)) = isAddOrSubExp((exp1,b));
      then
        ((exp,b));
    case((DAE.RCONST(real=_),true))  // maybe we have to remove this, because this is just for kirchhoffs current law
      equation
        //const.
        (exp,b) = inTpl;
      then
        ((exp,b));
    case((DAE.BINARY(exp1 = exp1,operator = DAE.ADD(ty=_),exp2 = exp2),true))
      equation
        //x + y
        (exp,b) = inTpl;
        ((_,b)) = isAddOrSubExp((exp1,b));
        ((_,b)) = isAddOrSubExp((exp2,b));
      then
        ((exp,b));
    case((DAE.BINARY(exp1=exp1,operator = DAE.SUB(ty=_),exp2=exp2),true))
      equation
        //x - y
        (exp,b) = inTpl;
        ((_,b)) = isAddOrSubExp((exp1,b));
        ((_,b)) = isAddOrSubExp((exp2,b));
      then
        ((exp,b));
    else
      equation
        (exp,b) = inTpl;
      then
        ((exp,false));
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
  op := Util.if_(sumUp,DAE.ADD(ty),DAE.SUB(ty));
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
        startNode = List.first(path);
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
        true = List.isNotEmpty(paths1);
        path = List.first(paths1);
        endNode = Debug.bcallret1(List.isNotEmpty(paths1),List.last,path,-1);
        endNode = Debug.bcallret1(List.isNotEmpty(paths2),List.first,path,-1);
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
        true = List.isNotEmpty(paths1);
        path = List.first(paths1);
        startNode = Debug.bcallret1(List.isNotEmpty(paths1),List.last,path,-1);
        startNode = Debug.bcallret1(List.isNotEmpty(paths2),List.first,path,-1);
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
        startNode = List.first(path);
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
  first := List.first(lstIn);
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
        startNode = List.first(path);
        endNode = List.last(path);    
        closedALoop = intEq(startNode,endNode);
        loops = Util.if_(closedALoop,path::loopsIn,loopsIn);   
        restPaths = Util.if_(closedALoop,restPathsIn,path::restPathsIn);
      then
        (loops,restPaths);
    case(path::rest,_,_)
      equation
        // the loop closes itself
        startNode = List.first(path);
        endNode = List.last(path);     
        true = intEq(startNode,endNode);
        loops = path::loopsIn;
        (loops,restPaths) = connect2PathsToLoops(rest,loops,restPathsIn);
      then
        (loops,restPaths);    
    case(path::rest,_,_)
      equation
        // check if there is another path that closes the Loop. if not: put the path to the restPaths
        startNode = List.first(path);
        endNode = List.last(path);
        startPaths = List.filter1OnTrue(rest,firstInListIsEqual,startNode);
        startPaths = List.filter1OnTrue(startPaths,lastInListIsEqual,endNode);
        endPaths = List.filter1OnTrue(rest,firstInListIsEqual,endNode);
        endPaths = List.filter1OnTrue(endPaths,lastInListIsEqual,startNode);    
        endPaths = listAppend(startPaths,endPaths);
        closedALoop = intGe(listLength(endPaths),1);
        loops = Debug.bcallret2(closedALoop,connectPaths,path,endPaths,{});
        restPaths = Util.if_(closedALoop,restPathsIn,path::restPathsIn);
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
  Integer last;
algorithm
  path := listDelete(pathIn,0);
  last := intSub(listLength(path),1);
  path := listDelete(path,last);
  loopsOut := List.map1(closingPaths,listAppend,path);
end connectPaths;

end ResolveLoops;
