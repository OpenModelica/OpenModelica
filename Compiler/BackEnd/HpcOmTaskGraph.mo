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

protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import GraphML;
protected import List;


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
    list<Integer> equations;
    list<Integer> dependencySCCs;
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

algorithm
  //Iterate over each system
  (_,_) := BackendDAEUtil.mapEqSystemAndFold(inDAE, createTaskGraph0, false);
end createTaskGraph;

//TODO: Get rid of the boolean parameter
protected function createTaskGraph0 "function createTaskGraph0
  author: marcusw,waurich
  Creates a task graph out of the given system and stores it as a graphml-file."
  input BackendDAE.EqSystem isyst; //The input system which should be analysed
  input tuple<BackendDAE.Shared,Boolean> ishared; //second argument of tuple is an extra argument
  output BackendDAE.EqSystem osyst; //no change here -> this is always isyst
  output tuple<BackendDAE.Shared,Boolean> oshared; //no change here -> this is always ishared
  
algorithm
  (osyst,oshared) := match(isyst,ishared)
    local
      BackendDAE.StrongComponents comps;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      Graph graph;
      BackendDAE.IncidenceMatrix incidenceMatrix;
      DAE.FunctionTree sharedFuncs;
      Integer numberOfVars;
      array<Integer> varSccMapping; //Map each variable to the scc which solves her
      list<String> eqDescs; 
      array<list<Integer>> adjLst;
      list<Integer> roots;
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps), orderedVars=BackendDAE.VARIABLES(numberOfVars=numberOfVars)),(shared as BackendDAE.SHARED(functionTree=sharedFuncs),_))
      equation
        varSccMapping = createVarSccMapping(comps, numberOfVars); 
        //BackendDump.dumpEqSystem(isyst, "TaskGraph Input");
        //Create a new task graph
        graph = GRAPH("TaskGraph",{},{});
        //(_,incidenceMatrix,_,_,_) = BackendDAEUtil.getIncidenceMatrixScalar(isyst, BackendDAE.NORMAL(), SOME(sharedFuncs)); //normale incidenzmatrix reicht
        (_,incidenceMatrix,_) = BackendDAEUtil.getIncidenceMatrix(isyst, BackendDAE.NORMAL(), SOME(sharedFuncs));
        BackendDump.dumpIncidenceMatrix(incidenceMatrix);
        eqDescs = getEquationStrings(comps,isyst);
        //((graph,_)) = List.fold3(comps,createTaskGraph1,incidenceMatrix,varSccMapping,comps,(graph,1));
        ((graph,_)) = List.fold3(comps,createTaskGraph1,(incidenceMatrix,isyst,shared),varSccMapping,eqDescs,(graph,1));      //swapped comps a an extra argument with eqDescs, comps not used in createTeaskgraph1
        //GraphML.dumpGraph(graph, "taskgraph.graphml");
        (adjLst,roots) = getAdjacencyListFromGraph(graph);
        
        print("TASKGRAPH represented as an adjacencyList\n");
        BackendDump.dumpIncidenceMatrix(adjLst);
        print("and the roots: "+&stringDelimitList(List.map(roots,intString),",")+&"\n");
        
        dumpAsGraphML_SccLevel(graph, "taskgraph.graphml");
      then
        (isyst,ishared);
    else
      then fail();
  end match;
end createTaskGraph0;

protected function createTaskGraph1 "function createTaskGraph1
  author: marcusw,waurich
  Appends the task-graph informations for the given StrongComponent to the given graph."
  input BackendDAE.StrongComponent component;
  input tuple<BackendDAE.IncidenceMatrix,BackendDAE.EqSystem,BackendDAE.Shared> isystInfo; //<incidenceMatrix,isyst,ishared> in very compact form
  input array<Integer> varSccMapping;
  input List<String> eqDescs;
  input tuple<Graph,Integer> igraph;
  output tuple<Graph,Integer> ograph;
protected
  Graph tmpGraph;
  StrongConnectedComponent graphComponent;
  Integer componentIndex, calculationTime;
  List<tuple<Integer,Integer>> unsolvedVars;
  BackendDAE.IncidenceMatrix incidenceMatrix;
  BackendDAE.EqSystem isyst;
  BackendDAE.Shared ishared;
  List<Integer> requiredSccs;
  String nodeDesc;
  String eqDesc;
algorithm
  (incidenceMatrix,isyst,ishared) := isystInfo;
  (tmpGraph,componentIndex) := igraph;
  nodeDesc := BackendDump.strongComponentString(component);
  //calculationTime := HpcOmBenchmark.timeForCalculation(component, isyst, ishared);
  eqDesc := listGet(eqDescs,componentIndex);
  unsolvedVars := getUnsolvedVarsBySCC(component,incidenceMatrix);
  requiredSccs := List.fold1(unsolvedVars,fillSccList,varSccMapping,{});
  graphComponent := STRONGCONNECTEDCOMPONENT(nodeDesc, componentIndex, {}, requiredSccs,eqDesc);
  tmpGraph := addSccToGraph(graphComponent, tmpGraph); //array der angibt ob scc schon in liste ist
  ograph := (tmpGraph,componentIndex+1);
end createTaskGraph1;
  

protected function getAdjacencyListFromGraph" computes an adjacency list from a directed Graph
author:Waurich TUD 2013-06"
  input Graph graph;
  output array<list<Integer>> adjacencyLst;
  output list<Integer> roots;
algorithm
  (adjacencyLst,roots) := matchcontinue(graph)
    local
      list<StrongConnectedComponent> comps;
      list<Variable> vars;
      String name;
      Integer size;
      list<Integer> roots;
    case(GRAPH(name=name,components=comps,variables=vars))
      equation
        size = listLength(comps);
        print(intString(size)+&" comps all in all\n");
        adjacencyLst = arrayCreate(size,{});
        ((adjacencyLst,roots)) = List.fold(comps,AdjacencyListFill,(adjacencyLst,{}));
      then
        (adjacencyLst,roots);
    case(GRAPH(name=name,components=comps,variables=vars))
      equation
        true = List.isEmpty(comps);
        print(name+&" is an empty graph\n");
        adjacencyLst = arrayCreate(0,{});
      then 
        (adjacencyLst,{});
  end matchcontinue;
end getAdjacencyListFromGraph;  


protected function AdjacencyListFill "fills the adjacencylist.
author:Waurich TUD 2013-06"
  input StrongConnectedComponent comp; 
  input tuple<array<list<Integer>>,list<Integer>> inValue;
  output tuple<array<list<Integer>>,list<Integer>> outValue;
algorithm
  outValue := matchcontinue(comp,inValue)
    local
      Integer Id;
      list<Integer> depSCCs;      
      list<Integer> row;
      list<Integer> rootsIn;
      list<Integer> rootsOut;
      array<list<Integer>> adjacencyLstIn;
      array<list<Integer>> adjacencyLstOut;
    case(STRONGCONNECTEDCOMPONENT(compIdx=Id, dependencySCCs=depSCCs),((adjacencyLstIn,rootsIn)))  
      equation
        false = intEq(listLength(depSCCs),0);
        //print("compIndex "+&intString(Id)+&"is dependent of "+&stringDelimitList(List.map(depSCCs,intString),",")+&"\n");
        adjacencyLstOut = List.fold1(depSCCs,AdjacencyListEntry,Id,adjacencyLstIn);
      then
        ((adjacencyLstOut,rootsIn));
    case(STRONGCONNECTEDCOMPONENT(compIdx=Id, dependencySCCs=depSCCs),((adjacencyLstIn,rootsIn)))  
      equation
        true = intEq(listLength(depSCCs),0);
        rootsOut = Id::rootsIn;
      then
        ((adjacencyLstIn,rootsOut));
  end matchcontinue;
end AdjacencyListFill;
    
    
protected function AdjacencyListEntry "helper function for AdjacencyListFill
author:Waurich TUD 2013-06"
  input Integer parent;
  input Integer child;
  input array<list<Integer>> adjacencyLstIn;
  output array<list<Integer>> adjacencyLstOut;
protected
  list<Integer> row;
algorithm
      //print("put the childnode "+& intString(child)+&"in the parent node "+&intString(parent)+&"\n");
      row := arrayGet(adjacencyLstIn,parent);
      row := child::row;
      //print("to get the row"+&stringDelimitList(List.map(row,intString),",")+&"\n");
      adjacencyLstOut := arrayUpdate(adjacencyLstIn,parent,row);      
end AdjacencyListEntry;
    

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
      desc = (eqString +& " FOR " +& varString);
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
      desc = (eqString +& " FOR " +& varString);
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


protected function fillSccList "function fillSccList
  author: marcusw
  This function appends the scc, which solves the given variable, to the requiredsccs-list."
  input tuple<Integer,Integer> variable;
  input array<Integer> varSccMapping;
  input List<Integer> iRequiredSccs;
  output List<Integer> oRequiredSccs;

algorithm
  oRequiredSccs := matchcontinue(variable,varSccMapping,iRequiredSccs)
    local
      Integer varIdx,varState, sccIdx;
      List<Integer> tmpRequiredSccs;
    case ((varIdx,varState),_,_)
      equation
        true = intEq(varState,1);
        sccIdx = varSccMapping[varIdx];
        //print("index der var "+&intString(varIdx)+&"mapped to the component "+&intString(sccIdx)+&"\n");
      then sccIdx::iRequiredSccs;
   else then iRequiredSccs;
  end matchcontinue;
end fillSccList;

//TODO: Remove prints if not required
protected function getUnsolvedVarsBySCC "function getUnsolvedVarsBySCC
  author: marcusw,waurich
  Returns all required variables which are not solved inside the given component."
  input BackendDAE.StrongComponent component;
  input BackendDAE.IncidenceMatrix incidenceMatrix;
  output List<tuple<Integer,Integer>> unsolvedVars;
  
algorithm
  unsolvedVars := matchcontinue(component, incidenceMatrix)
    local
      Integer varIdx;
      List<Integer> varIdc;
      List<tuple<Integer,Integer>> tmpVars;
    case(BackendDAE.SINGLEEQUATION(var=varIdx),_)
      equation
        tmpVars = getVarsBySCC(component, incidenceMatrix);
        //print(List.toString(tmpVars, tupleToString, "Component " +& BackendDump.strongComponentString(component) +& " unsolved vars_pre", "{", ";", "}", true) +& "\n");
        tmpVars = List.removeOnTrue(varIdx, compareTupleByVarIdx, tmpVars);
        //print(List.toString(tmpVars, tupleToString, "Component " +& BackendDump.strongComponentString(component) +& " unsolved vars_post", "{", ";", "}", true) +& "\n");
      then 
        tmpVars;
    case(BackendDAE.EQUATIONSYSTEM(vars=varIdc),_)
      equation
        tmpVars = getVarsBySCC(component, incidenceMatrix);
        //print(List.toString(tmpVars, tupleToString, "Component " +& BackendDump.strongComponentString(component) +& " unsolved vars_pre", "{", ";", "}", true) +& "\n");
        tmpVars = List.filter1OnTrue(tmpVars, isTupleMember, varIdc);
        //print(List.toString(tmpVars, tupleToString, "Component " +& BackendDump.strongComponentString(component) +& " unsolved vars_post", "{", ";", "}", true) +& "\n");
      then 
        tmpVars;
    case(BackendDAE.SINGLEWHENEQUATION(vars=varIdc),_)
      equation
        tmpVars = getVarsBySCC(component, incidenceMatrix);
        //print(List.toString(tmpVars, tupleToString, "Component " +& BackendDump.strongComponentString(component) +& " unsolved vars_pre", "{", ";", "}", true) +& "\n");
        tmpVars = List.filter1OnTrue(tmpVars, isTupleMember, varIdc);
        //print(List.toString(tmpVars, tupleToString, "Component " +& BackendDump.strongComponentString(component) +& " unsolved vars_post", "{", ";", "}", true) +& "\n");
      then tmpVars;
    case(BackendDAE.SINGLEALGORITHM(vars=varIdc),_)
      equation 
        tmpVars = getVarsBySCC(component,incidenceMatrix);
        //print(List.toString(tmpVars, tupleToString, "Component " +& BackendDump.strongComponentString(component) +& " unsolved vars_pre", "{", ";", "}", true) +& "\n");
        tmpVars = List.filter1OnTrue(tmpVars, isTupleMember, varIdc);
        //print(List.toString(tmpVars, tupleToString, "Component " +& BackendDump.strongComponentString(component) +& " unsolved vars_post", "{", ";", "}", true) +& "\n");
      then 
        tmpVars;
    case(BackendDAE.SINGLEARRAY(vars=varIdc),_)
      equation
        tmpVars = getVarsBySCC(component, incidenceMatrix);
        //print(List.toString(tmpVars, tupleToString, "Component " +& BackendDump.strongComponentString(component) +& " unsolved vars_pre", "{", ";", "}", true) +& "\n");
        tmpVars = List.filter1OnTrue(tmpVars, isTupleMember, varIdc);
        //print(List.toString(tmpVars, tupleToString, "Component " +& BackendDump.strongComponentString(component) +& " unsolved vars_post", "{", ";", "}", true) +& "\n");
      then 
        tmpVars;
    case(BackendDAE.TORNSYSTEM(tearingvars=varIdc),_)
      equation
        tmpVars = getVarsBySCC(component, incidenceMatrix);
        //print(List.toString(tmpVars, tupleToString, "Component " +& BackendDump.strongComponentString(component) +& " unsolved vars_pre", "{", ";", "}", true) +& "\n");
        tmpVars = List.filter1OnTrue(tmpVars, isTupleMember, varIdc);
        //print(List.toString(tmpVars, tupleToString, "Component " +& BackendDump.strongComponentString(component) +& " unsolved vars_post", "{", ";", "}", true) +& "\n");
      then 
        tmpVars;    
    else
      equation
        print("getUnsolvedVarsBySCC failed\n");
        then fail();
   end matchcontinue;
end getUnsolvedVarsBySCC;


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
      List<tuple<Integer,Integer>> eqnVars;
      String dumpStr;
    case (BackendDAE.SINGLEEQUATION(eqn=eqnIdx),_)
      equation
        eqnVars = getVarsByEqn(eqnIdx,incidenceMatrix);
        dumpStr = List.toString(eqnVars, tupleToString, "", "{", ";", "}", true);
        print("Eqn " +& intString(eqnIdx) +& " vars: " +& dumpStr +& "\n");
      then 
        eqnVars;
    case (BackendDAE.EQUATIONSYSTEM(eqns=eqns),_)
      equation
        eqnVars = List.flatten(List.map1(eqns, getVarsByEqn, incidenceMatrix));
        //print("Error in createTaskGraph1! Unsupported component-type Equationsystem with jacType varying.\n");
      then 
        eqnVars;
    case (BackendDAE.SINGLEWHENEQUATION(eqn=eqnIdx),_)
      equation
        eqnVars = getVarsByEqn(eqnIdx,incidenceMatrix);
        dumpStr = List.toString(eqnVars, tupleToString, "", "{", ";", "}", true);
        print("Eqn " +& intString(eqnIdx) +& " vars: " +& dumpStr +& "\n");
      then 
        eqnVars;
    case (BackendDAE.SINGLEARRAY(eqn=eqnIdx),_)
      equation
        eqnVars = getVarsByEqn(eqnIdx,incidenceMatrix);
        dumpStr = List.toString(eqnVars, tupleToString, "", "{", ";", "}", true);
        print("Eqn " +& intString(eqnIdx) +& " vars: " +& dumpStr +& "\n");
      then 
        eqnVars;
    case (BackendDAE.SINGLEALGORITHM(eqn=eqnIdx),_)
      equation
        eqnVars = getVarsByEqn(eqnIdx,incidenceMatrix);
        dumpStr = List.toString(eqnVars, tupleToString, "", "{", ";", "}", true);
        print("Eqn " +& intString(eqnIdx) +& " vars: " +& dumpStr +& "\n");
      then 
        eqnVars;
    case (BackendDAE.TORNSYSTEM(residualequations=eqns),_)
      equation
        eqnVars = List.flatten(List.map1(eqns, getVarsByEqn, incidenceMatrix));
        //print("Error in createTaskGraph1! Unsupported component-type Equationsystem with jacType varying.\n");
      then 
        eqnVars;
    else
      equation
        print("Error in createTaskGraph1! Unsupported component-type \n");
      then fail();
  end match;  
end getVarsBySCC;

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
    case(BackendDAE.SINGLEEQUATION(var = compVarIdx),_,_)
      equation
        //print("Var " +& intString(compVarIdx) +& " solved in scc " +& BackendDump.strongComponentString(component) +& "\n");
        tmpVarSccMapping = arrayUpdate(varSccMapping,compVarIdx,iSccIdx);
      then iSccIdx+1;
    case(BackendDAE.EQUATIONSYSTEM(vars = compVarIdc),_,_)
      equation
        tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
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
    case(BackendDAE.TORNSYSTEM(tearingvars = compVarIdc,residualequations = residuals, otherEqnVarTpl = tearEqVarTpl),_,_)
      equation
      print("Tearingvars in Tornsystem "+& stringDelimitList(List.map(compVarIdc,intString),",")+&"\n"+&"residualEquations "+&stringDelimitList(List.map(residuals,intString),",")+&"\n"); 
      ((othereqs,othervars)) = List.fold(tearEqVarTpl,othersInTearComp,(({},{})));
      print("other vars in Tornsystem "+& stringDelimitList(List.map(othervars,intString),",")+&"\n"+&"other eqs in Tornsystem "+& stringDelimitList(List.map(othereqs,intString),",")+&"\n");
      compVarIdc = listAppend(othervars,compVarIdc);
      tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
      then 
        iSccIdx+1;    
    case(BackendDAE.MIXEDEQUATIONSYSTEM(disc_vars = compVarIdc),_,_)
      equation
        print("MIXEDEQUATIONSYSTEMS is not supported yet\n");
        //tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
      then fail();
        case(BackendDAE.SINGLECOMPLEXEQUATION(vars = compVarIdc),_,_)
      equation
        print("SINGLECOMPLEXEQUATION is not supported yet\n");
        //tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
      then fail();
    case(BackendDAE.SINGLEIFEQUATION(vars = compVarIdc),_,_)
      equation
        print("SINGLEIFEQUATION is not supported yet\n");
        //tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
      then fail();
    else
      equation
        print("createVarSccMapping0 - Unsupported component-type.");
      then fail();
  end matchcontinue;
end createVarSccMapping0;

//protected function tearingVarsInComp " gets the remaining algebraic vars that are solved in the torn block.
//author:Waurich TUD 2013-06"
//  input tuple<Integer,list<Integer>> otherEqnVarTpl;
//  input list<Integer> compVarIdcIn;
//  output list<Integer> compVarIdcOut;
//algorithm
//  compVarIdc := matchcontinue(otherEqnVarTpl,compVarIdcIn)
//  local
//    Integer eq;
//    list<Integer> varLst;
//    case(((eq,varLst)),_)
//     equation
//      print("the Vars in othereqnvartpl "+&stringDelimitList(List.map(varLst,intString)",")+&"\n");
//      compVarIdcOut = List.fold(varLst,cons,compVarIdcIn);
//      then
//        compVarIdcOut;
//    else
//      then
 //       compVarIdIn;
//  end matchcontinue;
//end tearingVarsInComp;  


protected function othersInTearComp " gets the remaining algebraic vars and equations from the torn block.
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

algorithm
  _ := match(iGraph, fileName)
    case(GRAPH(components = components), _)
      equation 
        graph = GraphML.getGraph("TaskGraph", true);
        graph = List.fold(components, addSccToGraphML, graph);
        GraphML.dumpGraph(graph, fileName);
      then ();
  end match;
end dumpAsGraphML_SccLevel;


protected function addSccToGraphML "function addSccToGraphML
  author: marcusw
  Adds the given component to the given graph as a new node."
  input StrongConnectedComponent component;
  input GraphML.Graph iGraph;
  output GraphML.Graph oGraph;

protected
  String compText;
  Integer compIdx;
  String nodeDesc;
  List<Integer> dependencySCCs;
  String description;
algorithm
  oGraph := match(component,iGraph)
    local
      GraphML.Graph tmpGraph;
    case(STRONGCONNECTEDCOMPONENT(text=compText,compIdx=compIdx, dependencySCCs=dependencySCCs, description=nodeDesc),_)
      equation
        tmpGraph = GraphML.addNode("Component" +& intString(compIdx), compText, GraphML.COLOR_GREEN, GraphML.RECTANGLE(), SOME(nodeDesc), iGraph);
        tmpGraph = List.fold1(dependencySCCs, addSccDepToGraph, compIdx, tmpGraph);
      then tmpGraph;
   end match;
end addSccToGraphML;


protected function addSccDepToGraph "function addSccDepToGraph
  author: marcusw
  Adds a new edge between the component-nodes with index comp1Idx and comp2Idx to the graph."
  input Integer comp1Idx;
  input Integer comp2Idx;
  input GraphML.Graph iGraph;
  output GraphML.Graph oGraph;
 
algorithm
  oGraph := GraphML.addEgde("Edge" +& intString(comp2Idx) +& intString(comp1Idx), "Component" +& intString(comp1Idx), "Component" +& intString(comp2Idx), GraphML.COLOR_GREEN, GraphML.LINE(), NONE(), (SOME(GraphML.ARROWSTANDART()),NONE()), iGraph);
 
end addSccDepToGraph;

end HpcOmTaskGraph;
