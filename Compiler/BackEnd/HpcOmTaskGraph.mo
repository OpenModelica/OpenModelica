/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package HpcOmTaskGraph
" file:        HpcOmTaskGraph.mo
  package:     HpcOmTaskGraph
  description: HpcOmTaskGraph contains the whole logic to create a TaskGraph on BLT-Level

  RCS: $Id: HpcOmTaskGraph.mo 2013-05-24 11:12:35Z marcusw $
"
public import BackendDAE;
public import DAE;
public import SimCode;

protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import ComponentReference;
protected import Debug;
protected import ExpressionDump;
protected import GraphML;
protected import HpcOmBenchmark;
protected import List;
protected import Util;


public uniontype Equation
  record EQUATION
    String text;
    Integer eqIdx;
  end EQUATION;
end Equation;

public uniontype StrongConnectedComponent
  record STRONGCONNECTEDCOMPONENT
    String text;
    Integer compIdx;
    Integer calcTime;
    list<Integer> equations;
    list<tuple<Integer,Integer>> dependencySCCs; //The tuple holds the following values: <SccIdx,NumberOfDepVars>
    String description;
  end STRONGCONNECTEDCOMPONENT;
end StrongConnectedComponent;

public uniontype Variable
  record VARIABLE
    String text;
    Integer varIdx;
    Integer state;
  end VARIABLE;
end Variable;

public uniontype Graph
  record GRAPH
    String name;
    list<StrongConnectedComponent> components;
    list<Variable> variables;
  end GRAPH;
end Graph;


public function createTaskGraph "function createTaskGraph
  author: marcusw,waurich
  Creates a task graph on blt-level and stores it as a graphml-file."
  input BackendDAE.BackendDAE inDAE;
  input String fileNamePrefix;
protected
  list<BackendDAE.EqSystem> systs;
  BackendDAE.Shared shared;
algorithm
  //Iterate over each system
  BackendDAE.DAE(systs,shared) := inDAE;
  (_) := List.fold2(systs,createTaskGraph0,shared,fileNamePrefix,1);  
  //(_,_) := BackendDAEUtil.mapEqSystemAndFold1(inDAE, createTaskGraph0,fileNamePrefix, false);
end createTaskGraph;


protected function createTaskGraph0 "function createTaskGraph0
  author: marcusw,waurich
  Creates a task graph out of the given system and stores it as a graphml-file."
  input BackendDAE.EqSystem isyst; //The input system which should be analysed
  input BackendDAE.Shared ishared; //second argument of tuple is an extra argument
  input String fileNamePrefix;  //the fileName
  input Integer sysIdxIn; // The index of the equationsystem  
  output Integer sysIdxOut;
  //output BackendDAE.EqSystem osyst; //no change here -> this is always isyst
  //output tuple<BackendDAE.Shared,Boolean> oshared; //no change here -> this is always ishared
algorithm
  sysIdxOut := match(isyst,ishared,fileNamePrefix,sysIdxIn)
    local
      BackendDAE.StrongComponents comps;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      Graph graph;
      Graph graphOde;
      BackendDAE.IncidenceMatrix incidenceMatrix;
      DAE.FunctionTree sharedFuncs;
      array<Integer> varSccMapping; //Map each variable to the scc which solves her
      list<String> eqDescs; 
      list<Integer> condVarLst;
      list<Integer> eventEqLst;
      list<Integer> eventVarLst;
      list<Integer> rootLst;
      list<Integer> rootVars;
      array<list<Integer>> adjLst;
      array<list<Integer>> adjLstOde;
      array<Integer> ass1;
      array<Integer> ass2;
      String fileName;
      String fileNameOde;
      Integer numberOfVars;
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1=ass1, ass2=ass2, comps=comps), orderedVars=BackendDAE.VARIABLES(numberOfVars=numberOfVars)),(shared as BackendDAE.SHARED(functionTree=sharedFuncs)),_,_)
      equation
        varSccMapping = createVarSccMapping(comps, numberOfVars); 
        //BackendDump.dumpEqSystem(isyst, "TaskGraph Input");
        
        //Create a new task graph
        graph = GRAPH("TaskGraph",{},{});
        (_,incidenceMatrix,_) = BackendDAEUtil.getIncidenceMatrix(isyst, BackendDAE.NORMAL(), SOME(sharedFuncs));
        //BackendDump.dumpIncidenceMatrix(incidenceMatrix);
        eqDescs = getEquationStrings(comps,isyst);
        (eventEqLst,eventVarLst) = getEventNodes(comps,ass1);  // WhenEquations should have no successors in the taskGraph.but the conditions to check the zerocrossing functions need to be solved in the ode-system.
        adjLst = arrayCreate(listLength(comps),{});
        //((graph,adjLst,rootLst,_)) = List.fold2(comps,createTaskGraph1,(incidenceMatrix,isyst,shared,listLength(comps)),(varSccMapping,eqDescs,eventVarLst),(graph,adjLst,{},1));   // no connection from When-equations to other Nodes
        ((graph,adjLst,rootLst,_)) = List.fold2(comps,createTaskGraph1,(incidenceMatrix,isyst,shared,listLength(comps)),(varSccMapping,eqDescs,{}),(graph,adjLst,{},1));        // connection between When-equations and other Nodes
                
        // create a task graph only for the ODE-system
        (graphOde,adjLstOde) = getOdeSystem(graph,adjLst,isyst,eventVarLst,varSccMapping);
        
        fileName = ("taskGraph"+&fileNamePrefix+&intString(sysIdxIn)+&".graphml");        
        fileNameOde = ("taskGraphODE"+&fileNamePrefix+&intString(sysIdxIn)+&".graphml");   
        dumpAsGraphML_SccLevel(graph, fileName);
        dumpAsGraphML_SccLevel(graphOde, fileNameOde);
      then
        sysIdxIn+1;
    else
      equation
      print("createTaskGraph failed \n");
      then         
        fail();
  end match;
end createTaskGraph0;


protected function createTaskGraph1 "function createTaskGraph1
  author: marcusw,waurich
  Appends the task-graph information for the given StrongComponent to the given graph."
  input BackendDAE.StrongComponent component;
  input tuple<BackendDAE.IncidenceMatrix,BackendDAE.EqSystem,BackendDAE.Shared,Integer> isystInfo; //<incidenceMatrix,isyst,ishared,numberOfComponents> in very compact form
  input tuple<array<Integer>,list<String>,list<Integer>> graphInfo;
  input tuple<Graph,array<list<Integer>>,list<Integer>,Integer> igraph;
  output tuple<Graph,array<list<Integer>>,list<Integer>,Integer> ograph;
protected
  Graph tmpGraph;
  StrongConnectedComponent graphComponent;
  Integer componentIndex, calculationTime, numberOfComps;
  BackendDAE.IncidenceMatrix incidenceMatrix;
  BackendDAE.EqSystem isyst;
  BackendDAE.Shared ishared;
  list<tuple<Integer,Integer>> unsolvedVars;
  array<list<Integer>> adjLst;
  array<Integer> varSccMapping;
  list<Integer> eventVarLst;
  array<Integer> requiredSccs;
  list<Integer> rootLst;
  list<Integer> rootNodesIn;
  list<String> eqDescs;
  Integer componentIndex, calculationTime;
  array<Integer> requiredSccs;
  list<tuple<Integer,Integer>> requiredSccs_RefCount;
  String nodeDesc;
  String eqDesc;
algorithm
  (incidenceMatrix,isyst,ishared,numberOfComps) := isystInfo;
  (varSccMapping,eqDescs,eventVarLst) := graphInfo;
  (tmpGraph,adjLst,rootNodesIn,componentIndex) := igraph;
  nodeDesc := BackendDump.strongComponentString(component);
  calculationTime := HpcOmBenchmark.timeForCalculation(component, isyst, ishared);
  eqDesc := listGet(eqDescs,componentIndex);
  unsolvedVars := getUnsolvedVarsBySCC(component,incidenceMatrix,eventVarLst);
  requiredSccs := arrayCreate(numberOfComps,0); //create a ref-counter for each component
  requiredSccs := List.fold1(unsolvedVars,fillSccList,varSccMapping,requiredSccs); 
  //print("Required sccs for scc " +& nodeDesc +& " (idx: " +& intString(componentIndex) +& ") \n");
  //printReqScc(1, requiredSccs);
  //print("----------------------------------------\n");
  ((_,requiredSccs_RefCount)) := Util.arrayFold(requiredSccs, convertRefArrayToList, (1,{}));
  (adjLst,rootLst) := fillAdjacencyList(adjLst,rootNodesIn,componentIndex,requiredSccs_RefCount,1);
  adjLst := Util.arrayMap1(adjLst,List.sort,intGt);
  
  graphComponent := STRONGCONNECTEDCOMPONENT(nodeDesc, componentIndex, calculationTime, {}, requiredSccs_RefCount,eqDesc);
  tmpGraph := addSccToGraph(graphComponent, tmpGraph); //array der angibt ob scc schon in liste ist
  ograph := (tmpGraph,adjLst,rootLst,componentIndex+1);
end createTaskGraph1;   


protected function fillAdjacencyList "sets the child index in the rows indexed by the parent list.
author: waurich TUD 2013-06"
  input array<list<Integer>> adjLstIn;
  input list<Integer> rootNodesIn;
  input Integer childNode;
  input list<tuple<Integer,Integer>> parentLst;
  input Integer Idx;
  output array<list<Integer>> adjLstOut;
  output list<Integer> rootNodesOut;
algorithm
  (adjLstOut, rootNodesOut) := matchcontinue(adjLstIn,rootNodesIn,childNode,parentLst,Idx)
    local
      Integer parentNode;
      list<Integer> parentRow;
      list<Integer> rootNodes;
      array<list<Integer>> adjLst;
    case(_,_,_,_,_)
      equation
        true = listLength(parentLst) >= Idx;
        ((parentNode,_)) = listGet(parentLst,Idx);
        parentRow = arrayGet(adjLstIn,parentNode);
        parentRow = childNode::parentRow;
        adjLst = arrayUpdate(adjLstIn,parentNode,parentRow);
        (adjLst,rootNodes) = fillAdjacencyList(adjLst,rootNodesIn,childNode,parentLst,Idx+1);
      then
        (adjLst,rootNodes);
    case(_,_,_,_,_)
      equation
        true = listLength(parentLst) == 0;
        rootNodes = childNode::rootNodesIn;
      then
        (adjLstIn,rootNodes);
    else
      then
        (adjLstIn,rootNodesIn);
  end matchcontinue;
end fillAdjacencyList;       
  

protected function printReqScc
  input Integer refSccIdx;
  input array<Integer> requiredSccs;

protected
  Integer refCount;
  String refIdxStr,refCountStr;
algorithm 
  _ := matchcontinue(refSccIdx,requiredSccs)
    case(_,_)
      equation
        true = intLe(refSccIdx,arrayLength(requiredSccs));
        true = intGt(refSccIdx,-1);
        refCount = requiredSccs[refSccIdx];
        refIdxStr = intString(refSccIdx);
        refCountStr = intString(refCount);
        print(refIdxStr +& ":" +& refCountStr +& " ");
        printReqScc(refSccIdx+1,requiredSccs);
      then ();
    else then ();
  end matchcontinue;
end printReqScc;


//protected function fillCalcTimeArray "function fillCalcTimeArray
//  author: marcusw
//  Fills the calculation-time-array."
//  input Graph igraph;
//  input array<Integer> calcTimes;
//  
//algorithm
//  _ := match(igraph,calcTimes)
//    local
//      list<StrongConnectedComponent> components;
//    case(GRAPH(components=components),_)
//      equation 
//        fillCalcTimeArrayTail(components,calcTimes);
//      then ();
//    else
//      then fail();
//  end match;
//  
//end fillCalcTimeArray;
//
//
//protected function fillCalcTimeArrayTail 
//  input list<StrongConnectedComponent> iComps;
//  input array<Integer> calcTimes; //The calculation time of each component
//  
//algorithm
//  _ := match(iComps,calcTimes)
//    local
//      Integer calcTime, compIdx;
//      list<StrongConnectedComponent> rest;
//      String description;
//    case(STRONGCONNECTEDCOMPONENT(calcTime=calcTime,compIdx=compIdx,description=description)::rest,_)
//      equation
//        //print("fillCalcTimeArrayTail -- Idx:" +& compIdx +& " calcTime:" +& calcTime +& " desc:" +& description +& "\n");
//        _ = arrayUpdate(calcTimes, compIdx, calcTime);
//        fillCalcTimeArrayTail(rest,calcTimes);
//      then ();
//    else
//      then ();
//  end match;  
//end fillCalcTimeArrayTail;


protected function getEquationStrings " gets the equation and the variable its solved for for every StrongComponent
author:Waurich TUD 2013-06"
  input BackendDAE.StrongComponents iComps;
  input BackendDAE.EqSystem iEqSystem;
  output List<String> eqDescs;
algorithm
  eqDescs := List.fold1(iComps,getEquationStrings2,iEqSystem,{});
  eqDescs := listReverse(eqDescs);
end getEquationStrings;   


protected function getEquationStrings2 "implementation for getEquationStrings
author:Waurich TUD 2013-06"
  input BackendDAE.StrongComponent comp;
  input BackendDAE.EqSystem iEqSystem;
  input List<String> iEqDesc;
  output List<String> oEqDesc;
algorithm
  oEqDesc := matchcontinue(comp,iEqSystem,iEqDesc)
    local
      Integer i;
      Integer v;
      List<BackendDAE.Equation> eqnLst;
      List<BackendDAE.Var> varLst;
      array<Integer> ass2;
      List<Integer> es;
      List<Integer> vs;
      List<String> descLst;
      List<String> eqDescLst;
      List<String> varDescLst;
      String eqString;
      String varString;
      String desc;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
      BackendDAE.JacobianType jacT;
      BackendDAE.EquationArray orderedEqs;     
      BackendDAE.Variables orderedVars;
      BackendDAE.Equation eqn;
      BackendDAE.Var var;
    case(BackendDAE.SINGLEEQUATION(eqn = i, var = v), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars),_)
      equation
       //get the equation string
       eqnLst = BackendEquation.equationList(orderedEqs);   
       eqn = listGet(eqnLst,i);
       eqString = BackendDump.equationString(eqn);
       eqDescLst = stringListStringChar(eqString);
       eqDescLst = List.map(eqDescLst,prepareXML);
       eqString =stringCharListString(eqDescLst);
       //get the variable string
       varLst = BackendVariable.varList(orderedVars);   
       var = listGet(varLst,v);
       varString = getVarString(var);
       desc = (eqString +& " FOR " +& varString);
       descLst = desc::iEqDesc;
     then 
       descLst;
  case(BackendDAE.EQUATIONSYSTEM(eqns = es, vars = vs, jac = jac, jacType = jacT), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars),_)
     equation
       eqnLst = BackendEquation.equationList(orderedEqs);
       desc = ("Equation System");
       descLst = desc::iEqDesc;
     then 
       descLst;
  case(BackendDAE.MIXEDEQUATIONSYSTEM(disc_eqns = es, disc_vars = vs), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars),_)
     equation
       eqnLst = BackendEquation.equationList(orderedEqs);
       desc = ("MixedEquation System");
       descLst = desc::iEqDesc;
     then 
       descLst;
   case(BackendDAE.SINGLEARRAY(eqn = i, vars = vs), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars, matching= BackendDAE.MATCHING(ass2 = ass2)),_)
     equation
      //get the equation string
      eqnLst = BackendEquation.equationList(orderedEqs);
      eqn = listGet(eqnLst,i);
      eqString = BackendDump.equationString(eqn);
      eqDescLst = stringListStringChar(eqString);
      eqDescLst = List.map(eqDescLst,prepareXML);
      eqString =stringCharListString(eqDescLst);
      //get the variable string
      varLst = BackendVariable.varList(orderedVars);   
      var = listGet(varLst,arrayGet(ass2,i));
      varString = getVarString(var);
      desc = ("ARRAY:"+&eqString +& " FOR " +& varString);
      descLst = desc::iEqDesc;
    then 
      descLst;
   case(BackendDAE.SINGLEALGORITHM(eqn = i, vars = vs), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars, matching= BackendDAE.MATCHING(ass2 = ass2)),_)
     equation
      //get the equation string
      eqnLst = BackendEquation.equationList(orderedEqs);
      eqn = listGet(eqnLst,i);
      eqString = BackendDump.equationString(eqn);
      eqDescLst = stringListStringChar(eqString);
      eqDescLst = List.map(eqDescLst,prepareXML);
      eqString = stringCharListString(eqDescLst);
      descLst = eqString::iEqDesc;
      //get the variable string
      varLst = BackendVariable.varList(orderedVars);   
      var = listGet(varLst,arrayGet(ass2,i));
      varString = getVarString(var);
      desc = ("ALGO:"+&eqString +& " FOR " +& varString);
      descLst = desc::iEqDesc;
    then 
      descLst;
   case(BackendDAE.SINGLECOMPLEXEQUATION(eqn = i, vars = vs), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars, matching= BackendDAE.MATCHING(ass2 = ass2)),_)
     equation
      //get the equation string
      eqnLst = BackendEquation.equationList(orderedEqs);
      eqn = listGet(eqnLst,i);
      eqString = BackendDump.equationString(eqn);
      eqDescLst = stringListStringChar(eqString);
      eqDescLst = List.map(eqDescLst,prepareXML);
      eqString = stringCharListString(eqDescLst);
      descLst = eqString::iEqDesc;
      //get the variable string
      varLst = BackendVariable.varList(orderedVars);   
      var = listGet(varLst,arrayGet(ass2,i));
      varString = getVarString(var);
      desc = ("COMPLEX:"+&eqString +& " FOR " +& varString);
      descLst = desc::iEqDesc;
    then 
      descLst;
   case(BackendDAE.SINGLEWHENEQUATION(eqn = i, vars = vs), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars, matching= BackendDAE.MATCHING(ass2 = ass2)),_)
     equation
      //get the equation string
      eqnLst = BackendEquation.equationList(orderedEqs);
      eqn = listGet(eqnLst,i);
      eqString = BackendDump.equationString(eqn);
      eqDescLst = stringListStringChar(eqString);
      eqDescLst = List.map(eqDescLst,prepareXML);
      eqString =stringCharListString(eqDescLst);
      //get the variable string
      varLst = BackendVariable.varList(orderedVars);   
      var = listGet(varLst,arrayGet(ass2,i));
      varString = getVarString(var);
      desc = ("WHEN:"+&eqString +& " FOR " +& varString);
      descLst = desc::iEqDesc;
    then 
      descLst;
   case(BackendDAE.SINGLEIFEQUATION(eqn = i, vars = vs), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars, matching= BackendDAE.MATCHING(ass2 = ass2)),_)
     equation
      //get the equation string
      eqnLst = BackendEquation.equationList(orderedEqs);
      eqn = listGet(eqnLst,i);
      eqString = BackendDump.equationString(eqn);
      eqDescLst = stringListStringChar(eqString);
      eqDescLst = List.map(eqDescLst,prepareXML);
      eqString = stringCharListString(eqDescLst);
      descLst = eqString::iEqDesc;
      //get the variable string
      varLst = BackendVariable.varList(orderedVars);   
      var = listGet(varLst,arrayGet(ass2,i));
      varString = getVarString(var);
      desc = ("IFEQ:"+&eqString +& " FOR " +& varString);
      descLst = desc::iEqDesc;
    then 
      descLst;
  case(BackendDAE.TORNSYSTEM(residualequations = es, tearingvars = vs, linear=true), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars, matching= BackendDAE.MATCHING(ass2 = ass2)),_)
     equation
      //get the equation string
       eqnLst = BackendEquation.equationList(orderedEqs);
       desc = ("Torn linear System");
       descLst = desc::iEqDesc;
    then 
      descLst;  
  case(BackendDAE.TORNSYSTEM(residualequations = es, tearingvars = vs, linear=false), BackendDAE.EQSYSTEM(orderedEqs = orderedEqs, orderedVars = orderedVars, matching= BackendDAE.MATCHING(ass2 = ass2)),_)
     equation
      //get the equation string
       eqnLst = BackendEquation.equationList(orderedEqs);
       desc = ("Torn nonlinear System");
       descLst = desc::iEqDesc;
    then 
      descLst; 
  else
    equation
      desc = ("no singleEquation");
      descLst = desc::iEqDesc;
    then 
      descLst;
  end matchcontinue; 
end getEquationStrings2;


protected function getVarString "get the var string for a given variable. shortens the String. if necessary insert der operator 
author:waurich TUD 2013-06"
  input BackendDAE.Var inVar;
  output String varString;
algorithm
  varString := matchcontinue(inVar)
  local
    BackendDAE.VarKind kind;
    list<String> varDescLst;
  case(_)
    equation
    true = BackendVariable.isNonStateVar(inVar);
    varString = BackendDump.varString(inVar);
    varDescLst = stringListStringChar(varString);
    varDescLst = shortenVarString(varDescLst);
    varString = stringCharListString(varDescLst);
  then
    varString;
  case(_)
    equation
    false = BackendVariable.isNonStateVar(inVar);
    varString = BackendDump.varString(inVar);
    varDescLst = stringListStringChar(varString);
    varDescLst = shortenVarString(varDescLst);
    varString = stringCharListString(varDescLst);
    varString = (" der(" +& varString +& ")");
    then
      varString;   
  end matchcontinue;  
end getVarString;
   
//TODO: Replace with CDATA
protected function prepareXML " map-function for deletion of forbidden chars from given string
author:Waurich TUD 2013-06"
  input String iString;
  output String oString;
algorithm
  oString := matchcontinue(iString)
    local
    case(_)
      equation
      true = stringEq(iString, ">");
      then " greater ";
    case(_)
      equation
      true = stringEq(iString, "<");
      then " less ";
    else
    then iString;
  end matchcontinue;
end prepareXML;

protected function shortenVarString " terminates var string at :
author:Waurich TUD 2013-06"
  input List<String> iString;
  output List<String> oString;
protected
  Integer pos;
algorithm
  pos := List.position(":",iString);
  (oString,_) := List.split(iString,pos);
end shortenVarString;


protected function getEventNodes " gets the vars that are solved in the When-nodes. the assignment ass2 would not work if complex equations are part of the dae(one eq solves multiple vars)
author:Waurich TUD 2013-06"
  input BackendDAE.StrongComponents inComps;
  input array<Integer> ass1;
  output list<Integer> eqsOut;
  output list<Integer> varsOut;
protected
  list<Integer> eqLst;
algorithm
  eqLst := getEventNodeEqs(inComps,{});
  eqsOut := eqLst;
  //varsOut := matchWithAssignments(eqLst,ass2); 
  varsOut := List.map1(eqLst,getMatchedVars,ass1);
end getEventNodes;
  
//TODO: remove the matchcontinue if sure that the complex equations make no problems any more or if ass2 is fixed.
protected function getMatchedVars "matches the equation to the solved var by using ass1
author:Waurich TUD 2013-06"
  input Integer eq;
  input array<Integer> ass1;
  output Integer varOut;
algorithm
  varOut := matchcontinue(eq,ass1)
    local
      Integer var;
    case(_,_)
      equation
      true = intEq(listLength(List.select1(arrayList(ass1),intEq,eq)),1);
      var = List.position(eq,arrayList(ass1))+1;
      then
        var;
    else
      equation
      print("getMatchedVars failed because the equation solves multiple vars (probably complex equation)\n");
      then
        fail();
  end matchcontinue;
end getMatchedVars;
  
  
protected function matchWithAssignments " matches entries of list1 with the assigned values of ass to obtain the values 
author:Waurich TUD 2013-06" 
  input list<Integer> list1;
  input array<Integer> assign;
  output list<Integer> list2Out;
algorithm
  list2Out := matchWithAssignments1(list1,assign,{});
  list2Out := listReverse(list2Out);
end matchWithAssignments;

protected function matchWithAssignments1" implementation of matchWithAssigments.
author:Waurich TUD 2013-06"
  input list<Integer> list1;
  input array<Integer> assign;
  input list<Integer> list2In;
  output list<Integer> list2Out;
algorithm
  list2Out := matchcontinue(list1, assign, list2In)
    local
      Integer head;
      Integer entry2;
      list<Integer> rest;
      list<Integer> entries2;
    case(head::rest,_,_)
      equation
        entry2 = arrayGet(assign,head);
        entries2 = matchWithAssignments1(rest,assign,entry2::list2In);
      then
        entries2;
    case({},_,_)
      equation
        then
          list2In;
  end matchcontinue;
end matchWithAssignments1;     


protected function getEventNodeEqs "gets the equation for the When-nodes.
author: Waurich TUD 2013-06"
  input BackendDAE.StrongComponents inComps;
  input list<Integer> eventEqsIn;
  output list<Integer> eventEqsOut;
algorithm
  eventEqsOut := matchcontinue(inComps,eventEqsIn)
    local
      Integer eqn;
      list<Integer> eventEqs;
      list<Integer> condVars;
      BackendDAE.StrongComponents rest;
      BackendDAE.StrongComponent head;
    case((head::rest),_)
      equation
        true = isWhenEquation(head);
        BackendDAE.SINGLEWHENEQUATION(eqn = eqn) = head;
        eventEqs = getEventNodeEqs(rest,eqn::eventEqsIn);
      then
        eventEqs;
    case((head::rest),_)
      equation
        false = isWhenEquation(head);
        eventEqs = getEventNodeEqs(rest,eventEqsIn);
      then
        eventEqs;
    case({},_)
      then
        eventEqsIn;
  end matchcontinue;
end getEventNodeEqs;       


protected function isWhenEquation " checks if the comp is of type SINGLEWHENEQUATION.
author:Waurich TUD 2013-06"
  input BackendDAE.StrongComponent inComp;
  output Boolean isWhenEq;
algorithm
  isWhenEq := matchcontinue(inComp)
  local Integer eqn;
    case(BackendDAE.SINGLEWHENEQUATION(eqn=eqn))
    then
      true;
  else
    then
      false;
  end matchcontinue;
end isWhenEquation;


protected function fillSccList "function fillSccList
  author: marcusw
  This function appends the scc, which solves the given variable, to the requiredsccs-list."
  input tuple<Integer,Integer> variable;
  input array<Integer> varSccMapping;
  input array<Integer> iRequiredSccs;
  output array<Integer> oRequiredSccs;

algorithm
  oRequiredSccs := matchcontinue(variable,varSccMapping,iRequiredSccs)
    local
      Integer varIdx,varState, sccIdx, oldCount;
      array<Integer> tmpRequiredSccs;
    case ((varIdx,varState),_,_)
      equation
        true = intEq(varState,1);
        tmpRequiredSccs = iRequiredSccs;
        sccIdx = varSccMapping[varIdx];
        oldCount = iRequiredSccs[sccIdx];
        tmpRequiredSccs = arrayUpdate(tmpRequiredSccs,sccIdx,oldCount+1);
      then tmpRequiredSccs;
   else then iRequiredSccs;
  end matchcontinue;
end fillSccList;


protected function convertRefArrayToList
  input Integer refCountValue;
  input tuple<Integer,list<tuple<Integer,Integer>>> iList; //the current index and the current ref-list
  output tuple<Integer,list<tuple<Integer,Integer>>> oList;

protected
  Integer curIdx;
  tuple<Integer,Integer> tmpTuple;
  list<tuple<Integer,Integer>> curList;

algorithm
  oList := match(refCountValue,iList)
    case(0,(curIdx,curList)) 
      then ((curIdx+1,curList));
    case(_,(curIdx,curList))
      equation
        tmpTuple = (curIdx,refCountValue);
        curList = tmpTuple::curList;
      then ((curIdx+1,curList));
   end match;
end convertRefArrayToList;

//TODO: Remove prints if not required
protected function getUnsolvedVarsBySCC "function getUnsolvedVarsBySCC
  author: marcusw,waurich
  Returns all required variables which are not solved inside the given component."
  input BackendDAE.StrongComponent component;
  input BackendDAE.IncidenceMatrix incidenceMatrix;
  input list<Integer> eventVarLst;
  output List<tuple<Integer,Integer>> unsolvedVars;
  
algorithm
  unsolvedVars := matchcontinue(component, incidenceMatrix,eventVarLst)
    local
      Integer varIdx;
      List<Integer> varIdc;
      List<tuple<Integer,Integer>> tmpVars;
    case(BackendDAE.SINGLEEQUATION(var=varIdx),_,_)
      equation
        tmpVars = getVarsBySCC(component, incidenceMatrix);
        //print(List.toString(tmpVars, tupleToString, "Component " +& BackendDump.strongComponentString(component) +& " unsolved vars_pre", "{", ";", "}", true) +& "\n");
        tmpVars = List.removeOnTrue(varIdx, compareTupleByVarIdx, tmpVars);
        //print(List.toString(tmpVars, tupleToString, "Component " +& BackendDump.strongComponentString(component) +& " unsolved vars_post", "{", ";", "}", true) +& "\n");
        tmpVars = removeEventVars(eventVarLst,tmpVars,1);
        //print(List.toString(tmpVars, tupleToString, "Component " +& BackendDump.strongComponentString(component) +& " unsolved vars_noEvent", "{", ";", "}", true) +& "\n");
      then 
        tmpVars;
    case(BackendDAE.MIXEDEQUATIONSYSTEM(disc_vars=varIdc),_,_)
      equation
        tmpVars = getVarsBySCC(component, incidenceMatrix);
        tmpVars = List.filter1OnTrue(tmpVars, isTupleMember, varIdc);
        tmpVars = removeEventVars(eventVarLst,tmpVars,1);
      then 
        tmpVars;
    case(BackendDAE.EQUATIONSYSTEM(vars=varIdc),_,_)
      equation
        tmpVars = getVarsBySCC(component, incidenceMatrix);
        tmpVars = List.filter1OnTrue(tmpVars, isTupleMember, varIdc);
        tmpVars = removeEventVars(eventVarLst,tmpVars,1);
      then 
        tmpVars;
    case(BackendDAE.SINGLEARRAY(vars=varIdc),_,_)
      equation
        tmpVars = getVarsBySCC(component, incidenceMatrix);
        tmpVars = List.filter1OnTrue(tmpVars, isTupleMember, varIdc);
        tmpVars = removeEventVars(eventVarLst,tmpVars,1);
      then 
        tmpVars;
    case(BackendDAE.SINGLEALGORITHM(vars=varIdc),_,_)
      equation 
        tmpVars = getVarsBySCC(component,incidenceMatrix);
        tmpVars = List.filter1OnTrue(tmpVars, isTupleMember, varIdc);
        tmpVars = removeEventVars(eventVarLst,tmpVars,1);
      then 
        tmpVars;
    case(BackendDAE.SINGLECOMPLEXEQUATION(vars=varIdc),_,_)
      equation
        tmpVars = getVarsBySCC(component, incidenceMatrix);
        tmpVars = List.filter1OnTrue(tmpVars, isTupleMember, varIdc);
        tmpVars = removeEventVars(eventVarLst,tmpVars,1);
      then tmpVars;
    case(BackendDAE.SINGLEWHENEQUATION(vars=varIdc),_,_)
      equation
        tmpVars = getVarsBySCC(component, incidenceMatrix);
        tmpVars = List.filter1OnTrue(tmpVars, isTupleMember, varIdc);
        tmpVars = removeEventVars(eventVarLst,tmpVars,1);
      then tmpVars;
    case(BackendDAE.SINGLEIFEQUATION(vars=varIdc),_,_)
      equation 
        tmpVars = getVarsBySCC(component,incidenceMatrix);
        tmpVars = List.filter1OnTrue(tmpVars, isTupleMember, varIdc);
        tmpVars = removeEventVars(eventVarLst,tmpVars,1);
      then 
        tmpVars;
    case(BackendDAE.TORNSYSTEM(tearingvars=varIdc),_,_)
      equation
        tmpVars = getVarsBySCC(component, incidenceMatrix);
        tmpVars = List.filter1OnTrue(tmpVars, isTupleMember, varIdc);
        tmpVars = removeEventVars(eventVarLst,tmpVars,1);
      then 
        tmpVars;    
    else
      equation
        print("getUnsolvedVarsBySCC failed\n");
        then fail();
   end matchcontinue;
end getUnsolvedVarsBySCC;


protected function removeEventVars "removes EventVars from the varList.
author:Waurich TUD 2013-06"
  input list<Integer> eventVarLst;
  input list<tuple<Integer,Integer>> varLstIn;
  input Integer varIdx;
  output list<tuple<Integer,Integer>> varLstOut;
algorithm
  varLstOut := matchcontinue(eventVarLst,varLstIn,varIdx)
    local
      tuple<Integer,Integer> varTpl;
      list<tuple<Integer,Integer>> rest;
      list<tuple<Integer,Integer>> varLst;
      Integer var;
    case(_,_,_)
      equation
        true = intLe(varIdx,listLength(varLstIn));
        varTpl = listGet(varLstIn,varIdx);
        (var,_) = varTpl;
        true = List.isMemberOnTrue(var,eventVarLst,intEq);
        varLst = listDelete(varLstIn,varIdx-1);
        varLst = removeEventVars(eventVarLst,varLst,varIdx);
      then
        varLst;
    case(_,_,_)
      equation
        true = intLe(varIdx,listLength(varLstIn));
        varTpl = listGet(varLstIn,varIdx);
        (var,_) = varTpl;
        false = List.isMemberOnTrue(var,eventVarLst,intEq);
        varLst = removeEventVars(eventVarLst,varLstIn,varIdx+1);
      then
        varLst;
    else          
      then
        varLstIn;
  end matchcontinue;
end removeEventVars;


protected function isTupleMember "function isTupleMember
  author: marcusw
  Checks if the given variable (stored as tuple <id,state>) is part of the variable-list. This is only possible if the 
  second tuple-argument is one - this means that the variable is not derived."
  input tuple<Integer,Integer> inTuple;
  input List<Integer> varIdc;
  output Boolean isNotMember;

protected
  Integer varIdx, varState;
  Boolean returnValue;

algorithm
  isNotMember := matchcontinue(inTuple, varIdc)
    case((varIdx,varState), _)
      equation
        true = intGt(varIdx,0);
        true = intEq(varState,1);
        returnValue = List.isMemberOnTrue(varIdx, varIdc, intEq);
      then not returnValue;
    else
      then true;
  end matchcontinue;
end isTupleMember;

//TODO: Maybe we can easily replace the tuple-notation with negativ and positiv integers.
protected function compareTupleByVarIdx "function compareTupleByVarIdx
  author: marcusw
  Checks if the given varIdx is the same as the first tuple-argument." 
  input Integer varIdx;
  input tuple<Integer,Integer> var2Idx;
  output Boolean equal;

algorithm
  equal := match(varIdx,var2Idx)
    local
      Integer int1;
      Boolean result;
    case(_,(int1,_))
    then intEq(int1,varIdx);
  end match;
end compareTupleByVarIdx;


protected function getVarsBySCC "function getVarsBySCC
  author: marcusw,waurich
  Returns all variables of all equations which are part of the component." 
  input BackendDAE.StrongComponent component;
  input BackendDAE.IncidenceMatrix incidenceMatrix;
  output List<tuple<Integer,Integer>> vars;
  
algorithm
  vars := match(component, incidenceMatrix)
    local
      Integer eqnIdx; //For SINGLEEQUATION
      List<Integer> eqns; //For EQUATIONSYSTEM
      List<Integer> resEqns;
      List<tuple<Integer,Integer>> eqnVars;
      List<tuple<Integer,Integer>> eqnVarsCond;
      list<tuple<Integer,list<Integer>>> otherEqVars;
      String dumpStr;
      BackendDAE.StrongComponent condSys;
    case (BackendDAE.SINGLEEQUATION(eqn=eqnIdx),_)
      equation
        eqnVars = getVarsByEqn(eqnIdx,incidenceMatrix);
        dumpStr = List.toString(eqnVars, tupleToString, "", "{", ";", "}", true);
      then 
        eqnVars;
    case (BackendDAE.EQUATIONSYSTEM(eqns=eqns),_)
      equation
        eqnVars = List.flatten(List.map1(eqns, getVarsByEqn, incidenceMatrix));
      then 
        eqnVars;
    case (BackendDAE.MIXEDEQUATIONSYSTEM(disc_eqns=eqns, condSystem = condSys),_)
      equation
        //the when condition is a predecessor of the equation system. the affected equation is in the condSys
        eqnVars = List.flatten(List.map1(eqns, getVarsByEqn, incidenceMatrix));
        eqnVarsCond = getVarsBySCC(condSys,incidenceMatrix);
        eqnVars = listAppend(eqnVars,eqnVarsCond);
        eqnVars = List.unique(eqnVars);
      then 
        eqnVars;
    case (BackendDAE.SINGLEARRAY(eqn=eqnIdx),_)
      equation
        eqnVars = getVarsByEqn(eqnIdx,incidenceMatrix);
        dumpStr = List.toString(eqnVars, tupleToString, "", "{", ";", "}", true);
      then 
        eqnVars;
    case (BackendDAE.SINGLEALGORITHM(eqn=eqnIdx),_)
      equation
        eqnVars = getVarsByEqn(eqnIdx,incidenceMatrix);
        dumpStr = List.toString(eqnVars, tupleToString, "", "{", ";", "}", true);
      then 
        eqnVars;
    case (BackendDAE.SINGLECOMPLEXEQUATION(eqn=eqnIdx),_)
      equation
        eqnVars = getVarsByEqn(eqnIdx,incidenceMatrix);
        dumpStr = List.toString(eqnVars, tupleToString, "", "{", ";", "}", true);
      then 
        eqnVars;
    case (BackendDAE.SINGLEWHENEQUATION(eqn=eqnIdx),_)
      equation
        eqnVars = getVarsByEqn(eqnIdx,incidenceMatrix);
        dumpStr = List.toString(eqnVars, tupleToString, "", "{", ";", "}", true);
      then 
        eqnVars;
    case (BackendDAE.SINGLEIFEQUATION(eqn=eqnIdx),_)
      equation
        eqnVars = getVarsByEqn(eqnIdx,incidenceMatrix);
        dumpStr = List.toString(eqnVars, tupleToString, "", "{", ";", "}", true);
      then 
        eqnVars;
    case (BackendDAE.TORNSYSTEM(residualequations=resEqns,otherEqnVarTpl = otherEqVars),_)
      equation
        eqns = List.map(otherEqVars,getTupleFirst);
        eqnVars = List.flatten(List.map1(listAppend(resEqns,eqns), getVarsByEqn, incidenceMatrix));
      then 
        eqnVars;
    else
      equation
        print("Error in createTaskGraph1! Unsupported component-type \n");
      then fail();
  end match;  
end getVarsBySCC;


protected function getTupleFirst "gets the first entry in tuple.
author: Waurich TUD 2013-06"
  input tuple<Integer,list<Integer>> tupleIn;
  output Integer tupOne;
algorithm
  (tupOne,_) := tupleIn;
end getTupleFirst;
  
  
protected function tupleToString "function tupleToString
  author: marcusw
  Returns the given tuple as string." 
  input tuple<Integer,Integer> inTuple;
  output String result;
  
algorithm
  result := match(inTuple)
    local
      Integer int1,int2;
    case((int1,int2))
    then ("(" +& intString(int1) +& "," +& intString(int2) +& ")");
  end match;
end tupleToString;

protected function checkIfEquationContainsVar "function checkIfEquationContainsVar
  author: marcusw
  Returns true if given variable is part of the given equation." 
  input tuple<Integer,Integer> var;
  input Integer eqnIdx;
  input BackendDAE.IncidenceMatrix incidenceMatrix;
  output Boolean contains;
  
algorithm
  contains := match(var, eqnIdx, incidenceMatrix)
    local
      Integer varIdx,varState;
      List<tuple<Integer,Integer>> eqnVars;
    case((varIdx,varState),_,_)
      equation
        eqnVars = getVarsByEqn(eqnIdx, incidenceMatrix);
      then
        List.isMemberOnTrue(var,eqnVars,compareVarTuple);
  end match;
end checkIfEquationContainsVar;


protected function getVarsByEqn "function getVarsByEqn
  author: marcusw
  Returns all variables of the given equation." 
  input Integer eqnIdx;
  input BackendDAE.IncidenceMatrix incidenceMatrix;
  output list<tuple<Integer,Integer>> vars_out;

protected
  list<Integer> equationVars;

algorithm
  equationVars := incidenceMatrix[eqnIdx];
  vars_out := List.map(equationVars, getVarTuple);
end getVarsByEqn;


protected function getVarTuple "function getVarTuple
  author: marcusw
  Converts the given variable to tuple-notation.
  Example:  varIdx = -4 --> (4,0)
            varIdx = 5  --> (5,1)"
  input Integer varIdx;
  output tuple<Integer,Integer> outIdx; //variable index and variable state
  
algorithm
  outIdx := matchcontinue(varIdx)
    case(_)
      equation
        true = intLe(0,varIdx);
      then ((varIdx, 1));
    else
      then ((-varIdx,0));
   end matchcontinue;
end getVarTuple;

protected function compareVarTuple "function compareVarTuple
  author: marcusw
  Compares the two given tuples. The result is true if the first and second elements are equal."
  input tuple<Integer,Integer> tuple1;
  input tuple<Integer,Integer> tuple2;
  output Boolean equals;
  
algorithm
  equals := matchcontinue(tuple1,tuple2)
    local
      Integer int1,int2,int3,int4;
    case((int1,int2),(int3,int4))
      equation
        equality(int1 = int3);
        equality(int2 = int4);
      then true;
    else then false;
 end matchcontinue;
end compareVarTuple;

protected function getSCCByVar "function getSCCByVar
  author: marcusw
  Gets the scc which solves the given variable."
  input tuple<Integer,Integer> varIdx; //variable index and variable state
  input BackendDAE.StrongComponents components;
  input BackendDAE.IncidenceMatrix incidenceMatrix;
  input Integer sccIdx;
  input array<Integer> varSccMapping;
  output Option<Integer> componentIdx;
  
algorithm
  componentIdx := matchcontinue(varIdx, components, incidenceMatrix, sccIdx, varSccMapping)
    local
      Integer returnIdx, rawVarIdx, rawVarState;
    case((rawVarIdx,rawVarState),_,_,_,_)
      equation
        true = intGt(rawVarIdx,0);
        true = intEq(rawVarState,1);
        true = intGt(varSccMapping[rawVarIdx],0);
        returnIdx = varSccMapping[rawVarIdx];
      then
        SOME(returnIdx);
    else
      then NONE();
  end matchcontinue;
end getSCCByVar;


protected function createVarSccMapping "function createVarSccMapping
  author: marcusw
  Create a mapping between variables and strong-components. The returned array (one element for each variable) contains the 
  scc-index which solves the variable."
  input BackendDAE.StrongComponents components;
  input Integer varCount;
  output array<Integer> oVarSccMapping;
  
protected
  array<Integer> varSccMapping;
  
algorithm
  varSccMapping := arrayCreate(varCount,-1);
  _ := List.fold1(components, createVarSccMapping0, varSccMapping, 1);
  //print("Variables in SCCs " +& stringDelimitList(List.map(arrayList(varSccMapping),intString),"  ;  ")+&"\n");
  oVarSccMapping := varSccMapping;
  
end createVarSccMapping;


protected function createVarSccMapping0 "function createVarSccMapping
  author: marcusw,waurich
  Updates all array elements which are solved in the given component. The array-elements will be set to iSccIdx."
  input BackendDAE.StrongComponent component;
  input array<Integer> varSccMapping;
  input Integer iSccIdx;
  output Integer oSccIdx;
  
algorithm
  oSccIdx := matchcontinue(component, varSccMapping, iSccIdx)
    local
      Integer compVarIdx;
      List<Integer> compVarIdc;
      List<Integer> residuals;
      List<Integer> othereqs;
      List<Integer> othervars;
      array<Integer> tmpVarSccMapping;
      list<tuple<Integer,list<Integer>>> tearEqVarTpl;
      BackendDAE.StrongComponent condSys;
    case(BackendDAE.SINGLEEQUATION(var = compVarIdx),_,_)
      equation
        tmpVarSccMapping = arrayUpdate(varSccMapping,compVarIdx,iSccIdx);
      then iSccIdx+1;
    case(BackendDAE.EQUATIONSYSTEM(vars = compVarIdc),_,_)
      equation
        //print("Var from eqSystem " +& stringDelimitList(List.map(compVarIdc,intString),",") +& " solved in scc " +& BackendDump.strongComponentString(component) +& "\n");
        tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
      then 
        iSccIdx+1;
    case(BackendDAE.MIXEDEQUATIONSYSTEM(condSystem = condSys,disc_vars = compVarIdc),_,_)
      equation
        //print("discrete var from MixedeqSystem " +& stringDelimitList(List.map(compVarIdc,intString),",") +& " solved in scc " +& BackendDump.strongComponentString(component) +& "\n");
        tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
        //gets the whole equationsystem (necessary for the adjacencyList)
        _ = List.fold1({condSys}, createVarSccMapping0, tmpVarSccMapping, iSccIdx);
      then 
        iSccIdx+1;
    case(BackendDAE.SINGLEWHENEQUATION(vars = compVarIdc),_,_)
      equation
        tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
      then 
        iSccIdx+1;
    case(BackendDAE.SINGLEARRAY(vars = compVarIdc),_,_)
      equation
        tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
      then 
        iSccIdx+1;        
    case(BackendDAE.SINGLEALGORITHM(vars = compVarIdc),_,_)
      equation
        tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
        then 
          iSccIdx+1;
    case(BackendDAE.SINGLECOMPLEXEQUATION(vars = compVarIdc),_,_)
      equation
        tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
        //print("complex component "+&intString(iSccIdx)+&"solves the vars "+&stringDelimitList(List.map(compVarIdc,intString),",")+&"\n");
        then 
          iSccIdx+1;
    case(BackendDAE.TORNSYSTEM(tearingvars = compVarIdc,residualequations = residuals, otherEqnVarTpl = tearEqVarTpl),_,_)
      equation
      ((othereqs,othervars)) = List.fold(tearEqVarTpl,othersInTearComp,(({},{})));
      compVarIdc = listAppend(othervars,compVarIdc);
      tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
      then 
        iSccIdx+1;   
    case(BackendDAE.SINGLEIFEQUATION(vars = compVarIdc),_,_)
      equation
        //print("Var from ifEq" +& stringDelimitList(List.map(compVarIdc,intString),",") +& " solved in scc " +& BackendDump.strongComponentString(component) +& "\n");
        tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
        then 
          iSccIdx+1;
    else
      equation
        print("createVarSccMapping0 - Unsupported component-type.");
      then fail();
  end matchcontinue;
end createVarSccMapping0;


protected function othersInTearComp " gets the remaining algebraic vars and equations from the torn block.
this function is just for checking if there exists an equation with more than one var(because i dont know why theres a list of vars)
author:Waurich TUD 2013-06"
  input tuple<Integer,list<Integer>> otherEqnVarTpl;
  input tuple<list<Integer>,list<Integer>> othersIn;
  output tuple<list<Integer>,list<Integer>> othersOut;
algorithm
  othersOut := matchcontinue(otherEqnVarTpl,othersIn)
    local
      Integer eq;
      Integer var;
      list<Integer> eqLst;
      list<Integer> varTplLst;
      list<Integer> varLst;
    case(_,_)
      equation
      (eq,varTplLst)=otherEqnVarTpl;  
      true = intEq(listLength(varTplLst),1);
      var = listGet(varTplLst,1);
      (eqLst,varLst) = othersIn;
      varLst = var::varLst;
      eqLst = eq::eqLst;
      then
        ((eqLst,varLst));
    else
      equation
      print("check number of vars in relation to number of eqs in otherEqnVarTpl int the torn system\n");
      then
        fail();  
  end matchcontinue;   
end othersInTearComp;  
  

protected function updateMapping
  input Integer varIdx;
  input Integer sccIdx;
  input array<Integer> iMapping;
  output array<Integer> oMapping;
algorithm
  oMapping := arrayUpdate(iMapping,varIdx,sccIdx);

end updateMapping;



//functions to get the ODEsystem graph and adjacencyList
//------------------------------------------
//------------------------------------------

protected function getOdeSystem " gets the graph and the adjacencyLst only for the ODEsystem.the der(states) and nodes that evaluate zerocrossings are the only branches of the task graph
author: Waurich TUD 2013-06"
  input Graph graphIn;
  input array<list<Integer>> adjLstIn;
  input BackendDAE.EqSystem systIn;
  input list<Integer> whenVars;
  input array<Integer> varSccMapping;
  output Graph graphOdeOut;
  output array<list<Integer>> adjLstOdeOut;
protected
  list<BackendDAE.Var> varLst;
  list<Integer> finalNodes;
  list<Integer> finalVars;
  list<Integer> statevarindx_lst;
  list<Integer> stateVars;
  list<Integer> stateNodes;
  list<Integer> whenNodes;
  BackendDAE.Variables orderedVars;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=orderedVars) := systIn;
  varLst := BackendVariable.varList(orderedVars);
  stateVars := getStates(varLst,{},1);
  stateNodes := matchWithAssignments(stateVars,varSccMapping);
  whenNodes := matchWithAssignments(whenVars,varSccMapping);
  (adjLstOdeOut,graphOdeOut) := cutTaskGraph(adjLstIn,graphIn,stateNodes,whenNodes,{});
end getOdeSystem;


protected function cutTaskGraph "cuts every branch of the taskgraph that leads not to exceptNode.
author:Waurich TUD 2013-06"
  input array<list<Integer>> adjacencyLstIn;
  input Graph graphIn;
  input list<Integer> stateNodes;
  input list<Integer> whenNodes;
  input list<Integer> deleteNodes;
  output array<list<Integer>> adjacencyLstOde;
  output Graph graphOdeOut;
algorithm
  (adjacencyLstOde,graphOdeOut) := matchcontinue(adjacencyLstIn,graphIn,stateNodes,whenNodes,deleteNodes)
    local
      list<Integer> cutNodes;
      list<Integer> deleteNodesTmp;
      list<Integer> noChildren;
      list<Integer> odeMapping;
      list<Integer> whenChildren;
      array<list<Integer>> adjacencyLst;
      Graph graphTmp;
      list<StrongConnectedComponent> comps;   
    case(_,_,_,_,_)
      equation
        // remove the algebraic branches
        
        noChildren = getBranchEnds(adjacencyLstIn,{},1);
        //print("free branches"+&stringDelimitList(List.map(noChildren,intString),",")+&"\n");
        (_,cutNodes,_) = List.intersection1OnTrue(noChildren,listAppend(stateNodes,deleteNodes),intEq);
        deleteNodesTmp = listAppend(cutNodes,deleteNodes);
        //print("cutNodes "+&stringDelimitList(List.map(cutNodes,intString),",")+&"\n");
        false = List.isEmpty(cutNodes);
        graphTmp = updateGraphOde(graphIn,cutNodes,1);
        GRAPH(components=comps) = graphTmp;
        adjacencyLst = removeEntries(adjacencyLstIn,cutNodes);
        (adjacencyLst,graphTmp) = cutTaskGraph(adjacencyLst,graphTmp,stateNodes,whenNodes,deleteNodesTmp);
         then
           (adjacencyLst,graphTmp);
    case(_,_,_,_,_)
      equation
        //remove the when-nodes
        
        noChildren = getBranchEnds(adjacencyLstIn,{},1);
        (_,cutNodes,_) = List.intersection1OnTrue(noChildren,listAppend(stateNodes,deleteNodes),intEq);
        deleteNodesTmp = listAppend(cutNodes,deleteNodes);
        true = List.isEmpty(cutNodes);
        whenChildren = getChildNodes(adjacencyLstIn,whenNodes,{},1);
        //print("the when nodes"+&stringDelimitList(List.map(whenNodes,intString),",")+&"and their children"+&stringDelimitList(List.map(whenChildren,intString),",")+&"\n");
        graphTmp = deleteDependenciesInGraph(graphIn,whenNodes,whenChildren,1);
        adjacencyLst = removeEntries(adjacencyLstIn,whenNodes);
        graphTmp = updateGraphOde(graphTmp,whenNodes,1);
        (adjacencyLst,odeMapping) = deleteRowInAdjLst(adjacencyLst,List.unique(listAppend(deleteNodes,whenNodes)));
        GRAPH(components=comps) = graphTmp;
        //print("graph with  "+&intString(listLength(comps))+&" components "+&"\n");
        //print("found the ODE graph\n");
         then
           (adjacencyLst,graphTmp);
  end matchcontinue;
end cutTaskGraph;

protected function deleteDependenciesInGraph "deletes dependencies for a all ChildNodes in all given parentNodes.
author:Waurich TUD 2013-06"
  input Graph graphIn;
  input list<Integer> parentLst;
  input list<Integer> childLst;
  input Integer childIdx;
  output Graph graphOut;
algorithm
  graphOut := matchcontinue(graphIn,parentLst,childLst,childIdx)
    local
      Integer child;
      Integer childLstIdx;
      Integer calcTime, compIdx;
      String description, name, text;
      list<Integer> equations;
      list<StrongConnectedComponent> comps;
      list<Variable> variables;
      list<tuple<Integer,Integer>> dependencySCCs;
      Graph graphTmp;
      StrongConnectedComponent comp;
    case(_,_,_,_)
      equation
        true = listLength(childLst) >= childIdx;
        GRAPH(name = name, components = comps, variables = variables) = graphIn;
        child = listGet(childLst,childIdx);
        //print("check if for comp "+& intString(child)+& "exists a dependency to "+&stringDelimitList(List.map(parentLst,intString),",")+&"\n");
        (comp,childLstIdx) = getSccByCompIdx(comps,child,1);
        comps = listDelete(comps,childLstIdx-1);
        STRONGCONNECTEDCOMPONENT(text = text, compIdx = compIdx, calcTime = calcTime, equations = equations, description = description, dependencySCCs = dependencySCCs) = comp;
        dependencySCCs = List.fold1(dependencySCCs, deleteDependency, parentLst, {});
        dependencySCCs = listReverse(dependencySCCs);
        comp = STRONGCONNECTEDCOMPONENT(text,compIdx,calcTime,equations,dependencySCCs,description);
        comps = List.insert(comps,child,comp);
        graphTmp = GRAPH(name,comps,variables);
        graphTmp = deleteDependenciesInGraph(graphTmp,parentLst,childLst,childIdx+1);
      then
        graphTmp;
   else
     equation
     then
       graphIn;
  end matchcontinue;
end deleteDependenciesInGraph;


protected function getSccByCompIdx "gets the SCC and the list index by the component index.
author:Waurich TUD 2013-06"
  input list<StrongConnectedComponent> inComps;
  input Integer Idx;
  input Integer lstIdxIn;
  output StrongConnectedComponent compOut;
  output Integer lstIdxOut;
algorithm
  (compOut,lstIdxOut) := matchcontinue(inComps,Idx,lstIdxIn)
    local
      Integer compIdx;
      Integer lstIdxTmp;
      StrongConnectedComponent compTmp;
      StrongConnectedComponent head;
      list<StrongConnectedComponent> rest;
    case((head::rest),_,_)
      equation
        STRONGCONNECTEDCOMPONENT(compIdx=compIdx) = head;
        false = intEq(compIdx,Idx);
        (compTmp,lstIdxTmp) = getSccByCompIdx(rest,Idx,lstIdxIn+1);
        then
          (compTmp,lstIdxTmp);
    case((head::rest),_,_)
      equation
        STRONGCONNECTEDCOMPONENT(compIdx=compIdx) = head;
        true = intEq(compIdx,Idx);
      then
        (head,lstIdxIn);
  end matchcontinue;
end getSccByCompIdx;      
        

protected function deleteDependency "fold function to build a new dependency list without the dependency to the parent node. 
author:Waurich TUD 2013-06"
  input tuple<Integer,Integer> dependencySCCs;
  input list<Integer> parentNodes;
  input list<tuple<Integer,Integer>> dependencySCCsIn;
  output list<tuple<Integer,Integer>> dependencySCCsOut;
algorithm
  dependencySCCsOut := matchcontinue(dependencySCCs,parentNodes,dependencySCCsIn)
    local
      Integer Node;
    case((Node,_),_,_)
      equation
        false = List.isMemberOnTrue(Node,parentNodes,intEq);
        //print("dependentNodes "+&intString(Node)+&" is not member of the Nodes "+& stringDelimitList(List.map(parentNodes,intString),",")+&"\n");
        then
          dependencySCCs::dependencySCCsIn;
    case((Node,_),_,_)
      equation
        //print("IS MEMBER\n");
        true = List.isMemberOnTrue(Node,parentNodes,intEq);
        then
          dependencySCCsIn;
  end matchcontinue;
end deleteDependency;
  

protected function getChildNodes "gets the successor nodes for a list of parent nodes.
author: waurich TUD 2013-06"
  input array<list<Integer>> adjacencyLstIn;
  input list<Integer> parents;
  input list<Integer> childLstTmp;
  input Integer Idx;
  output list<Integer> childLsts;
algorithm
  childLsts := matchcontinue(adjacencyLstIn,parents,childLstTmp,Idx)
    local
      Integer parent;
      list<Integer> row;
      list<Integer> childLst;
    case(_,_,_,_)
      equation
        true = listLength(parents) >= Idx;
        parent = listGet(parents,Idx);
        row = arrayGet(adjacencyLstIn,parent);
        childLst = listAppend(childLstTmp,row);
        childLst = getChildNodes(adjacencyLstIn,parents,childLst,Idx+1);
      then 
        childLst;
    else
      then
        childLstTmp;
  end matchcontinue;
end getChildNodes;


protected function updateGraphOde "deletes those Sccs that are cutNodes.
author:waurich TUD 2013-06"
  input Graph graphIn;
  input list<Integer> cutNodes;
  input Integer Idx;
  output Graph graphOut;
algorithm
  graphOut := matchcontinue(graphIn,cutNodes,Idx)
    local
      String name;
      Integer compIdx;
      list<Variable> variables;
      list<StrongConnectedComponent> comps;
      Graph graphTmp;
      StrongConnectedComponent comp;
    case(GRAPH(name = name, components = comps, variables = variables),_,_)
      equation
       true = listLength(comps) >= Idx;
       comp = listGet(comps,Idx);
       STRONGCONNECTEDCOMPONENT(compIdx=compIdx) = comp;
       true = List.isMemberOnTrue(compIdx,cutNodes,intEq);
       comps = listDelete(comps,Idx-1);
       graphTmp = GRAPH(name,comps,variables);
       graphTmp = updateGraphOde(graphTmp,cutNodes,Idx);
      then
        graphTmp;
    case(GRAPH(name = name, components = comps, variables = variables),_,_)
      equation
       true = listLength(comps) >= Idx;
       comp = listGet(comps,Idx);
       STRONGCONNECTEDCOMPONENT(compIdx=compIdx) = comp;
       false = List.isMemberOnTrue(compIdx,cutNodes,intEq);
       graphTmp = updateGraphOde(graphIn,cutNodes,Idx+1);
     then
       graphTmp;
   case(GRAPH(name = name, components = comps, variables = variables),_,_)
     equation
       true = listLength(comps) < Idx;
       then
         graphIn;
  end matchcontinue;
end updateGraphOde;       

  
//protected function getConditionVars "gets the vars that are necessary to compute the when-conditions
//author: Waurich TUD 2013-06"
//  input list<Integer> eventEqs;
//  input list<Integer> eventVars;
//  input BackendDAE.IncidenceMatrix mIn;
//  input list<Integer> condVarsIn;
//  input Integer Idx;
//  output list<Integer> condVarsOut;
//algorithm
//  condVarsOut := matchcontinue(eventEqs,eventVars,mIn,condVarsIn,Idx)
//    local
//      Integer var;
//      list<Integer> condVars;
//      list<Integer> row;
//    case(_,_,_,_,_)
//      equation
//        true = listLength(eventEqs) >= Idx;
//        row = arrayGet(mIn,listGet(eventEqs,Idx));
//        row = deleteMembersList(row,eventVars);
//        condVars = listAppend(row,condVarsIn);
//        condVars = getConditionVars(eventEqs,eventVars,mIn,condVars,Idx+1);
//      then
//        condVars;
//    else
//      equation
//        condVars = List.unique(condVarsIn);
//      then
//        condVars;     
//    end matchcontinue;
//end getConditionVars;        

protected function deleteMembersList "deletes all members in list1 given by list2
author:waurich TUD 2013-06"
  input list<Integer> list1In;
  input list<Integer> list2;
  output list<Integer> list1Out;
algorithm
  list1Out := matchcontinue(list1In,list2)
    local
      Integer entry;
      Integer head;
      list<Integer> newLst;
      list<Integer> rest;
    case(_,(head::rest))
      equation
        newLst = List.deleteMember(list1In,head);
        newLst = deleteMembersList(newLst,rest);
      then
        newLst;
    case(_,{})
      then
        list1In;
  end matchcontinue;
end deleteMembersList;     
      

protected function removeEntries "deletes given entries from adjacencyLst.
  author: Waurich TUD 2013-06"
  input array<list<Integer>> inArray;
  input list<Integer> noStates;
  output array<list<Integer>> outArray;
algorithm
  outArray := matchcontinue(inArray,noStates)
  local
    Integer head;
    list<Integer> rest;
    array<list<Integer>> ArrayTmp;
  case(_,{})
    equation
    then 
      inArray;
  case(_,(head::rest))
    equation
      ArrayTmp = removeEntryFromArray(inArray,head,1);
      ArrayTmp = removeEntries(ArrayTmp,rest);
    then
      ArrayTmp;
  end matchcontinue;
end removeEntries;


protected function removeEntryFromArray " removes a singel entry from an array<list<Integer>>. starts with indexed row.
  author: Waurich 2013-06"
  input array<list<Integer>> inArray;
  input Integer entry;
  input Integer indx;
  output array<list<Integer>> outArray;
algorithm
  outArray := matchcontinue(inArray,entry,indx)
  local
    Integer size;
    list<Integer> row;
    array<list<Integer>> ArrayTmp;
  case(_,_,_)
  equation
    size = arrayLength(inArray);
    true = indx>size;
  then inArray;
  case(_,_,_)
    equation
      size = arrayLength(inArray);
      true = indx <= size;
      row = arrayGet(inArray,indx);
      row = List.deleteMember(row,entry);
      ArrayTmp = Util.arrayReplaceAtWithFill(indx,row,row,inArray);
    then removeEntryFromArray(ArrayTmp,entry,indx+1);
  end matchcontinue;
end removeEntryFromArray;



protected function deleteRowInAdjLst "deletes rows indexed by the rowDel from the adjacencyLst.
author:waurich TUD 2013 - 06"
  input array<list<Integer>> adjacencyLstIn;
  input list<Integer> rowsDel;
  output array<list<Integer>> adjacencyLstOut;
  output list<Integer> odeMapping;
protected
  array<list<Integer>> adjLst;
  list<Integer> copiedRows;
  list<Integer> rowsDel1;
  Integer size;
algorithm
  size := arrayLength(adjacencyLstIn)-listLength(rowsDel);
  adjLst := arrayCreate(size,{});
  copiedRows := List.intRange(arrayLength(adjacencyLstIn));
  rowsDel1 := List.map1(rowsDel,intSub,1);
  copiedRows := List.deletePositions(copiedRows,rowsDel1);
  adjacencyLstOut := arrayCopyRows(adjacencyLstIn,adjLst,copiedRows,1);
  odeMapping := copiedRows;
end deleteRowInAdjLst;


protected function arrayCopyRows "copies entries given by copiedRows from inArray to newArray"
  input array<list<Integer>> inArray;
  input array<list<Integer>> newArray;
  input list<Integer> copiedRows;
  input Integer Idx;
  output array<list<Integer>> outArray;
algorithm
  outArray := matchcontinue(inArray,newArray,copiedRows,Idx)
    local
      Integer head;
      Integer copyRow;
      list<Integer> rest;
      list<Integer> row;
      array<list<Integer>> arrayTmp;
    case(_,_,_,_)
      equation
        true = listLength(copiedRows) >= Idx;
        copyRow = listGet(copiedRows,Idx);
        row = arrayGet(inArray,copyRow);
        arrayTmp = Util.arrayReplaceAtWithFill(Idx, row, {111,222}, newArray);
        arrayTmp = arrayCopyRows(inArray,arrayTmp,copiedRows,Idx+1);
      then
        arrayTmp;
    else
      equation
      then
        newArray;
  end matchcontinue;
end arrayCopyRows;


protected function subOne
  input Integer minuend1;
  output Integer diffOut;
algorithm
  diffOut := intSub(minuend1,1);
end subOne;


protected function getBranchEnds "gets the end of the branches i.e. a node with no successors(no entries in the adjacencyList)
author:Waurich TUD 2013-06"
  input array<list<Integer>> adjacencyLstIn;
  input list<Integer> noChildrenIn;
  input Integer rowIdx;
  output list<Integer> noChildrenOut;
algorithm
  noChildrenOut := matchcontinue(adjacencyLstIn,noChildrenIn,rowIdx)
    local
      list<Integer> row;
      list<Integer> noChildren;
    case(_,_,_)
      equation
        true = arrayLength(adjacencyLstIn) >= rowIdx;
        row = arrayGet(adjacencyLstIn,rowIdx);
        true = List.isEmpty(row);
        noChildren = getBranchEnds(adjacencyLstIn,rowIdx::noChildrenIn,rowIdx+1);
        then
          noChildren;
    case(_,_,_)
      equation
        // check for tornsystems (self-loops)
        
        true = arrayLength(adjacencyLstIn) >= rowIdx;
        row = arrayGet(adjacencyLstIn,rowIdx);
        true = listLength(row) == 1;  
        true = listGet(row,1) == rowIdx;
        noChildren = getBranchEnds(adjacencyLstIn,rowIdx::noChildrenIn,rowIdx+1);
        then
          noChildren;    
    case(_,_,_)
      equation
        true = arrayLength(adjacencyLstIn) >= rowIdx;
        row = arrayGet(adjacencyLstIn,rowIdx);
        false = List.isEmpty(row);
        noChildren = getBranchEnds(adjacencyLstIn,noChildrenIn,rowIdx+1);
        then
          noChildren;          
    case(_,_,_)
      equation
        true = arrayLength(adjacencyLstIn) < rowIdx;
      then
        noChildrenIn;
  end matchcontinue;
end getBranchEnds;             
        
        
protected function getStates "gets the stateVars from the list of vars.
author:Waurich TUD 2013-06"
  input list<BackendDAE.Var> inVarLst;
  input list<Integer> stateVarsIn;
  input Integer Idx;
  output list<Integer> stateVarsOut;
algorithm
  stateVarsOut := matchcontinue(inVarLst,stateVarsIn,Idx)
    local
      BackendDAE.Var head;
      list<BackendDAE.Var> rest;
      list<Integer> stateVars;
    case((head::rest),_,_)
      equation
        false = BackendVariable.isStateVar(head);
        stateVars = getStates(rest,stateVarsIn,Idx+1);
      then
        stateVars;
    case((head::rest),_,_)
      equation
        true = BackendVariable.isStateVar(head);
        stateVars = getStates(rest,Idx::stateVarsIn,Idx+1);
      then
        stateVars;
    case({},_,_)
      then
        stateVarsIn;
   end matchcontinue;
 end getStates;       
 
 
              

//protected function getSCCByVar0
//  input tuple<Integer,Integer> varIdx; //variable index and variable state
//  input BackendDAE.StrongComponents components;
//  input BackendDAE.IncidenceMatrix incidenceMatrix;
//  input Integer sccIdx;
//  input array<Integer> varSccMapping;
//  output Option<Integer> componentIdx;
//
//algorithm
//  componentIdx := matchcontinue(varIdx, components, incidenceMatrix, sccIdx, varSccMapping)
//    local
//      BackendDAE.StrongComponent head;
//      BackendDAE.StrongComponents tail;
//      Integer varRawIdx,varRawState;
//      Boolean constTrue, contains;
//      Integer compVarIdx, const1, listLen;
//      list<tuple<Integer, list<Integer>>> tornCompEqns;
//      list<Integer> compVarIdc;
//    case((varRawIdx,varRawState),(head as BackendDAE.SINGLEEQUATION(var = compVarIdx))::tail,_,_,_)
//      equation
//        true = compareVarTuple(varIdx, getVarTuple(compVarIdx));
//        varSccMapping = arrayUpdate(varSccMapping,varRawIdx,sccIdx);
//    then SOME(sccIdx);
//    case(_,(head as BackendDAE.EQUATIONSYSTEM(vars = compVarIdc))::tail,_,_,_)
//      equation
//        print("getSCCByVar - Equationsystem not supported\n");
//        //compVarIdc = List.removeOnTrue(varIdx, intNe, compVarIdc);
//        //const1 = 1;
//        //listLen = listLength(compVarIdc);
//        //equality(const1 = listLen);
//      then getSCCByVar(varIdx,tail,incidenceMatrix,sccIdx+1,varSccMapping);
//    case(_,(head as BackendDAE.MIXEDEQUATIONSYSTEM(disc_vars = compVarIdc))::tail,_,_,_)
//      equation
//        print("getSCCByVar - Mixedequationsystem not supported\n");
//      then getSCCByVar(varIdx,tail,incidenceMatrix,sccIdx+1,varSccMapping);
//    case (_,(head as BackendDAE.SINGLEARRAY(vars=compVarIdc))::tail,_,_,_)
//      equation
//        print("getSCCByVar - SingleArray not supported\n");
//      then getSCCByVar(varIdx,tail,incidenceMatrix,sccIdx+1,varSccMapping); 
//    case (_,(head as BackendDAE.SINGLEALGORITHM(vars=compVarIdc))::tail,_,_,_)
//      equation
//        print("getSCCByVar - SingleAlgorithm not supported\n");
//      then getSCCByVar(varIdx,tail,incidenceMatrix,sccIdx+1,varSccMapping);       
//    case (_,(head as BackendDAE.TORNSYSTEM(tearingvars=compVarIdc, otherEqnVarTpl=tornCompEqns))::tail,_,_,_)
//      equation
//        //constTrue = true;
//        //contains = checkIfTornCompContainsEqn(compVarIdc, tornCompEqns, varIdx);
//        //equality(constTrue = contains);
//        print("getSCCByVar - TornSystem not supported\n");
//      then getSCCByVar(varIdx,tail,incidenceMatrix,sccIdx+1);
//    case(_,_::tail,_,_,_)
//      then getSCCByVar(varIdx,tail,incidenceMatrix,sccIdx+1);
//    else NONE();
//  end matchcontinue;
//end getSCCByVar0;

//protected function checkIfTornCompContainsEqn
//  input list<Integer> tearingEqns;
//  input list<tuple<Integer, list<Integer>>> otherEqnVarTpl;
//  input Integer eqnIdx;
//  output Boolean contains;
//
//algorithm
//  contains := checkIfTornCompContainsEqn1(listLength(List.removeOnTrue(eqnIdx, intNe, tearingEqns)), checkIfTornCompContainsEqn0(otherEqnVarTpl,eqnIdx));
//end checkIfTornCompContainsEqn;
//
//protected function checkIfTornCompContainsEqn0
//  input list<tuple<Integer, list<Integer>>> otherEqnVarTpl;
//  input Integer eqnIdx;
//  output Boolean contains;
//
//protected
//  Integer eqn;
//  list<tuple<Integer, list<Integer>>> tail;
//  
//algorithm
//  contains := matchcontinue(otherEqnVarTpl, eqnIdx)
//    case((eqn,_)::tail,_) 
//      equation
//        equality(eqn = eqnIdx);
//      then true;
//    case(_::tail,_) then checkIfTornCompContainsEqn0(tail,eqnIdx);
//    else then false;
//  end matchcontinue;
//end checkIfTornCompContainsEqn0;
//
//protected function checkIfTornCompContainsEqn1
//  input Integer listLen;
//  input Boolean partOfOtherEqn;
//  output Boolean contains;
//
//algorithm
//  contains := match(listLen, partOfOtherEqn)
//    case(1,_)
//      then true;
//    case(_,_)
//      then partOfOtherEqn;
//  end match;  
//end checkIfTornCompContainsEqn1; 


//Create TaskGraph for the ODE-system only (not used)
//------------------------------------------
//------------------------------------------

public function createTaskGraphODE" creates the task Graph only for the ODE equations.
author: waurich TUD 2013-06"
  input list<list<SimCode.SimEqSystem>> odeEquationsIn;
  input BackendDAE.BackendDAE dlowIn;
  input String fileNamePrefix;
algorithm
  _ := matchcontinue(odeEquationsIn, dlowIn, fileNamePrefix)
    local
      BackendDAE.EqSystems eqSysts;
      BackendDAE.EqSystem eqSys;
      BackendDAE.StrongComponents comps;
      BackendDAE.Shared shared;
      BackendDAE.Variables orderedVars;
      Integer numberOfVars;
      Integer sizeODE;
      array<Integer> varSCCMapping;
      list<DAE.ComponentRef> cRefsODE;
      array<Integer> odeScc;
      list<SimCode.SimEqSystem> odeEqLst;
      list<Integer> odeSCCMapping;
      list<Integer> odeVarMatching;
      list<DAE.ComponentRef> varCRefMapping;
      list<BackendDAE.Var> varLst;      
    case(_,BackendDAE.DAE(eqs=eqSysts, shared=shared),_)
      equation
        //true = intEq(listLength(odeEquationsIn), 1);
        odeEqLst = listGet(odeEquationsIn,1);
        print(intString(listLength(odeEqLst))+&"ODEs\n");
        sizeODE =  listLength(odeEqLst);
        cRefsODE = List.map(odeEqLst,getODEcRef);
        print("all the ODEs "+&stringDelimitList(List.map(cRefsODE,ComponentReference.crefStr),",")+&"\n");
        //eqSys = listGet(eqSysts,1);
        //BackendDAE.EQSYSTEM(matching = BackendDAE.MATCHING(comps=comps),orderedVars=orderedVars) = eqSys;
        //BackendDAE.VARIABLES(numberOfVars=numberOfVars) = orderedVars;
        //// map the SCCs to the vars
        //varSCCMapping = createVarSccMapping(comps, numberOfVars);
        //// map vars to cRefs of vars        
        //varLst = BackendVariable.varList(orderedVars);
        //varCRefMapping = List.map(varLst,BackendVariable.varCref);
        //print("map vars to cRefs of vars "+&stringDelimitList(List.map(varCRefMapping,ComponentReference.crefStr),",")+&"\n");
        //// map SCC to cRefs
        //odeScc = arrayCreate(listLength(cRefsODE),-1);
        //_ = List.fold3(cRefsODE, getSccForCRef, odeScc, varSCCMapping, varCRefMapping, 1);
        ////print("ode-SCC-mapping "+&stringDelimitList(List.map(arrayList(odeScc),intString),",")+&"\n");
      then
        ();
    else
      equation
      print("createTaskGraphODE failed! - check the ODEs \n");  
      then
        ();
  end matchcontinue;
end createTaskGraphODE;


protected function getSccForCRef " mappes the Scc to a componentRef. the array cRefsODE is updated (this occurs during List.fold of arrays)
author:Waurich TUD 2013-06."
  input DAE.ComponentRef cRefIn;
  input array<Integer> odeScc;
  input array<Integer> varSCCMapping;
  input list<DAE.ComponentRef> varCRefMapping;
  input Integer odeIdxIn;
  output Integer odeIdxOut;
protected
  Integer var;
  Integer SCCIdx;
  array<Integer> odeSccTmp;
algorithm
  var := varPosition(cRefIn,varCRefMapping); 
  SCCIdx := arrayGet(varSCCMapping,var);
  //print("for the ODE "+& intString(odeIdxIn)+&"i.e. "+&ComponentReference.crefStr(cRefIn)+&"assign var "+&intString(var)+&" i.e. componenten no. "+& intString(SCCIdx)+&"\n");
  odeSccTmp := arrayUpdate(odeScc,odeIdxIn,SCCIdx);
  odeIdxOut :=odeIdxIn+1;
end getSccForCRef;

protected function varPosition " gets the var in the varcRefMapping.
author:Waurich TUD 2013-06"
  input DAE.ComponentRef inElement;
  input list<DAE.ComponentRef> inList;
  output Integer outPosition;
algorithm
  outPosition := varPosition_impl(inElement, inList, 1);
end varPosition;

protected function varPosition_impl 
"Implementation of varPosition."
  input DAE.ComponentRef inElement;
  input list<DAE.ComponentRef> inList;
  input Integer inPosition;
  output Integer outPosition;
algorithm
  outPosition := matchcontinue(inElement, inList, inPosition)
    local
      DAE.ComponentRef head;
      list<DAE.ComponentRef> rest;
      String Str1;
      String Str2;
    case (_, head :: _, _)
      equation
        Str1 = ComponentReference.crefStr(head);
        Str2 = ComponentReference.crefStr(inElement);
        true = stringEq(Str1,Str2); //!!!!BEACHTE DER(STATES)!!!!
      then
        inPosition;
    case (_, _ :: rest, _)
      then varPosition_impl(inElement, rest, inPosition + 1);
  end matchcontinue;
end varPosition_impl;


protected function getODEcRef "gets the cRef for a SimEqSystem.
  author: Waurich TUD 2013-06"
  input SimCode.SimEqSystem odeEqIn;
  output DAE.ComponentRef cRefOut;
algorithm
  cRefOut := matchcontinue(odeEqIn)
  local
    Integer eqIdx;
    DAE.ComponentRef compRef;
    list<DAE.ComponentRef> conditions;
    DAE.Exp exp;
    list<DAE.Exp> exps;
    DAE.ElementSource source;
    list<DAE.Statement> statements;
    String compRefStr;
  case(SimCode.SES_RESIDUAL(index=eqIdx, exp=exp, source=source))
    equation  
    //print("equation "+&intString(eqIdx)+&"is a Residual"+&"\n");
    then
      fail();
  case(SimCode.SES_SIMPLE_ASSIGN(index=eqIdx, cref=compRef, exp=exp, source=source))
    equation
    compRefStr = ComponentReference.crefStr(compRef);    
    //print("equation "+&intString(eqIdx)+&"is a SimpleAssignment from component"+&compRefStr+&"\n");
    then
      compRef; 
  case(SimCode.SES_ALGORITHM(index=eqIdx, statements=statements))
    equation
    //print("equation "+&intString(eqIdx)+&"is a ALGORITHM from component"+&"\n");
    then
      fail();
  case(SimCode.SES_WHEN(index=eqIdx, left=compRef, right=exp, source=source))
    equation
    //print("equation "+&intString(eqIdx)+&"is a When from component"+&"\n");
    then
      compRef;
  else
    equation
    //print("createTaskGraphODE0 failed! - Unsupported SimEqSystem-type! ");
    then
      fail();    
  end matchcontinue;      
end getODEcRef;


//Methods to write blt-structure as xml-file
//------------------------------------------
//------------------------------------------

public function addSccToGraph
  "function addSccToGraph
  author: marcusw
  Adds the given component as node to the given graph."
  input StrongConnectedComponent component;
  input Graph iGraph;
  output Graph oGraph;

algorithm
  oGraph := match(component, iGraph)
    local
      Integer compIdx;
      List<StrongConnectedComponent> components;
      String name;
      list<Variable> variables;
    case(_, GRAPH(name = name, components = components, variables = variables))
        equation
      then GRAPH(name, component::components, variables);
  end match;
end addSccToGraph;


protected function compScc "function compScc
  author: marcusw
  Compares two StrongConnectedComponent-nodes. They are equal if they have the same index."
  input Integer compIdx;
  input StrongConnectedComponent comp2;
  output Boolean equals;
  
algorithm
  equals := match(compIdx, comp2)
    local
      Integer comp2Idx;
    case(_,STRONGCONNECTEDCOMPONENT(compIdx=comp2Idx))
    then intEq(compIdx,comp2Idx);
    else
    then false;
  end match;
end compScc;

public function dumpAsGraphML_SccLevel "function dumpAsGraphML_SccLevel
  author: marcusw
  Write out the given graph as a graphml file."
  input Graph iGraph;
  input String fileName;

protected
  GraphML.Graph graph;
  List<StrongConnectedComponent> components;
  Integer calcTimeIdx;

algorithm
  _ := match(iGraph, fileName)
    case(GRAPH(components = components),_)
      equation 
        graph = GraphML.getGraph("TaskGraph", true);
        (calcTimeIdx,graph) = GraphML.addAttribute("0", "CalcTime", GraphML.TYPE_INTEGER(), GraphML.TARGET_NODE(), graph);
        graph = List.fold1(components, addSccToGraphML, calcTimeIdx, graph);
        GraphML.dumpGraph(graph, fileName);
      then ();
  end match;
end dumpAsGraphML_SccLevel;


protected function addSccToGraphML "function addSccToGraphML
  author: marcusw
  Adds the given component to the given graph as a new node."
  input StrongConnectedComponent component;
  input Integer calcTimeIdx; //index of the calcTime-attribute
  input GraphML.Graph iGraph;
  output GraphML.Graph oGraph;

protected
  String compText;
  Integer compIdx;
  String nodeDesc;
  List<tuple<Integer,Integer>> dependencySCCs;
  String description;
algorithm
  oGraph := match(component,calcTimeIdx,iGraph)
    local
      GraphML.Graph tmpGraph;
      Integer calcTime;
      String calcTimeString;
    case(STRONGCONNECTEDCOMPONENT(text=compText,compIdx=compIdx, dependencySCCs=dependencySCCs, description=nodeDesc, calcTime=calcTime),_,_)
      equation
//        calcTime = calcTimes[compIdx-1]; //because compIdx starts with 1
        calcTimeString = intString(calcTime);
        tmpGraph = GraphML.addNode("Component" +& intString(compIdx), compText, GraphML.COLOR_BLUE, GraphML.RECTANGLE(), SOME(nodeDesc), {((calcTimeIdx,calcTimeString))}, iGraph);
        tmpGraph = List.fold1(dependencySCCs, addSccDepToGraph, compIdx, tmpGraph);
      then tmpGraph;
   end match;
end addSccToGraphML;


protected function addSccDepToGraph "function addSccDepToGraph
  author: marcusw
  Adds a new edge between the component-nodes with index comp1Idx and comp2Idx to the graph."
  input tuple<Integer,Integer> comp1Idx;
  input Integer comp2Idx;
  input GraphML.Graph iGraph;
  output GraphML.Graph oGraph;

protected
  Integer refSccIdx, refSccCount;
  String refSccCountStr;
algorithm
  (refSccIdx,refSccCount) := comp1Idx;
  refSccCountStr := intString(refSccCount);
  oGraph := GraphML.addEgde("Edge" +& intString(comp2Idx) +& intString(refSccIdx), "Component" +& intString(refSccIdx), "Component" +& intString(comp2Idx), GraphML.COLOR_BLACK, GraphML.LINE(), SOME(GraphML.EDGELABEL(refSccCountStr,GraphML.COLOR_BLACK)), (SOME(GraphML.ARROWSTANDART()),NONE()), iGraph);
end addSccDepToGraph;

end HpcOmTaskGraph;
