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

  RCS: $Id: HpcOmTaskGraph.mo 15486 2013-05-24 11:12:35Z marcusw $
"
public import BackendDAE;
public import DAE;

protected import BackendDAEUtil;
protected import BackendDump;
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



public function createTaskGraph
  input BackendDAE.BackendDAE inDAE;

algorithm
  //Iterate over each system
  (_,_) := BackendDAEUtil.mapEqSystemAndFold(inDAE, createTaskGraph0, false);
end createTaskGraph;

protected function createTaskGraph0
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared,Boolean> ishared; //second argument of tuple is an extra argument
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,Boolean> oshared;
  
algorithm
  (osyst,oshared) := match(isyst,ishared)
    local
      BackendDAE.StrongComponents comps;
      BackendDAE.EqSystem syst;
      Graph graph;
      BackendDAE.IncidenceMatrix incidenceMatrix;
      DAE.FunctionTree sharedFuncs;
      Integer numberOfVars;
      array<Integer> varSccMapping; //Map each variable to the scc which solves her
      
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps), orderedVars=BackendDAE.VARIABLES(numberOfVars=numberOfVars)),(BackendDAE.SHARED(functionTree=sharedFuncs),_))
      equation
        varSccMapping = createVarSccMapping(comps, numberOfVars); 
        BackendDump.dumpEqSystem(isyst, "TaskGraph Input");
        graph = GRAPH("TaskGraph",{},{});
        //(_,incidenceMatrix,_,_,_) = BackendDAEUtil.getIncidenceMatrixScalar(isyst, BackendDAE.NORMAL(), SOME(sharedFuncs)); //normale incidenzmatrix reicht
        (_,incidenceMatrix,_) = BackendDAEUtil.getIncidenceMatrix(isyst, BackendDAE.NORMAL(), SOME(sharedFuncs));
        ((graph,_)) = List.fold3(comps,createTaskGraph1,incidenceMatrix,varSccMapping,comps,(graph,1));
        //GraphML.dumpGraph(graph, "taskgraph.graphml");
        dumpAsGraphML_SccLevel(graph, "taskgraph.graphml");
      then
        (isyst,ishared);
    else
      then fail();
  end match;
end createTaskGraph0;

protected function createTaskGraph1
  input BackendDAE.StrongComponent component;
  input BackendDAE.IncidenceMatrix incidenceMatrix;
  input array<Integer> varSccMapping;
  input BackendDAE.StrongComponents components;
  input tuple<Graph,Integer> igraph;
  output tuple<Graph,Integer> ograph;

protected
  Graph tmpGraph;
  StrongConnectedComponent graphComponent;
  Integer componentIndex;
  List<tuple<Integer,Integer>> unsolvedVars;
  List<Option<Integer>> requiredSccs_option;
  List<Integer> requiredSccs;
  String nodeDesc;

algorithm
  (tmpGraph,componentIndex) := igraph;
  nodeDesc := BackendDump.strongComponentString(component);
  unsolvedVars := getUnsolvedVarsBySCC(component,incidenceMatrix);
  //requiredSccs_option := List.map4(unsolvedVars, getSCCByVar, components, incidenceMatrix, 1, varSccMapping); //mittels List.fold
  //requiredSccs_option := List.removeOnTrue(NONE(), bothOptionsNone, requiredSccs_option); //remove all NONE()-Elements
  requiredSccs := List.fold1(unsolvedVars,fillSccList,varSccMapping,{});
  //requiredSccs := List.map(requiredSccs_option, Util.getOption);
  graphComponent := STRONGCONNECTEDCOMPONENT(nodeDesc, componentIndex, {}, requiredSccs);
  tmpGraph := addSccToGraph(graphComponent, tmpGraph); //array der angibt ob scc schon in liste ist
  
  ograph := (tmpGraph,componentIndex+1);
end createTaskGraph1;

protected function fillSccList
  input tuple<Integer,Integer> variable;
  input array<Integer> varSccMapping;
  input List<Integer> iRequiredSccs;
  output List<Integer> oRequiredSccs;

algorithm
  outBool := matchcontinue(variable,varSccMapping,iRequiredSccs)
    local
      Integer varIdx,varState, sccIdx;
      List<Integer> tmpRequiredSccs;
    case ((varIdx,varState),_,_)
      equation
        true = intEq(varState,1);
        sccIdx = varSccMapping[varIdx];
      then sccIdx::iRequiredSccs;
   else then iRequiredSccs;
  end matchcontinue;
end fillSccList;


protected function getUnsolvedVarsBySCC
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
        print(List.toString(tmpVars, tupleToString, "Component " +& BackendDump.strongComponentString(component) +& " unsolved vars_pre", "{", ";", "}", true) +& "\n");
        tmpVars = List.removeOnTrue(varIdx, compareTupleByVarIdx, tmpVars);
        print(List.toString(tmpVars, tupleToString, "Component " +& BackendDump.strongComponentString(component) +& " unsolved vars_post", "{", ";", "}", true) +& "\n");
      then tmpVars;
    case(BackendDAE.EQUATIONSYSTEM(vars=varIdc),_)
      equation
        tmpVars = getVarsBySCC(component, incidenceMatrix);
        print(List.toString(tmpVars, tupleToString, "Component " +& BackendDump.strongComponentString(component) +& " unsolved vars_pre", "{", ";", "}", true) +& "\n");
        tmpVars = List.filter1OnTrue(tmpVars, isTupleMember, varIdc);
        print(List.toString(tmpVars, tupleToString, "Component " +& BackendDump.strongComponentString(component) +& " unsolved vars_post", "{", ";", "}", true) +& "\n");
      then tmpVars;
   end matchcontinue;
end getUnsolvedVarsBySCC;


protected function isTupleMember
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


protected function compareTupleByVarIdx
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


protected function getVarsBySCC
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
      then eqnVars;
    case (BackendDAE.EQUATIONSYSTEM(eqns=eqns),_)
      equation
        eqnVars = List.flatten(List.map1(eqns, getVarsByEqn, incidenceMatrix));
        //print("Error in createTaskGraph1! Unsupported component-type Equationsystem with jacType varying.\n");
      then eqnVars;
    else
      equation
        print("Error in createTaskGraph1! Unsupported component-type \n");
      then fail();
  end match;  
end getVarsBySCC;

protected function tupleToString
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

protected function checkIfEquationContainsVar
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


protected function getVarsByEqn
  input Integer eqnIdx;
  input BackendDAE.IncidenceMatrix incidenceMatrix;
  output list<tuple<Integer,Integer>> vars_out;

protected
  list<Integer> equationVars;

algorithm
  equationVars := incidenceMatrix[eqnIdx];
  vars_out := List.map(equationVars, getVarTuple);
end getVarsByEqn;


protected function getVarTuple
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

protected function compareVarTuple
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

protected function getSCCByVar
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

protected function createVarSccMapping
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

protected function createVarSccMapping0
  input BackendDAE.StrongComponent component;
  input array<Integer> varSccMapping;
  input Integer iSccIdx;
  output Integer oSccIdx;
  
algorithm
  oSccIdx := matchcontinue(component, varSccMapping, iSccIdx)
    local
      Integer compVarIdx;
      List<Integer> compVarIdc;
      array<Integer> tmpVarSccMapping;
    case(BackendDAE.SINGLEEQUATION(var = compVarIdx),_,_)
      equation
        //print("Var " +& intString(compVarIdx) +& " solved in scc " +& BackendDump.strongComponentString(component) +& "\n");
        tmpVarSccMapping = arrayUpdate(varSccMapping,compVarIdx,iSccIdx);
      then iSccIdx+1;
    case(BackendDAE.EQUATIONSYSTEM(vars = compVarIdc),_,_)
      equation
        tmpVarSccMapping = List.fold1(compVarIdc,updateMapping,iSccIdx,varSccMapping);
      then iSccIdx+1;
    else
      equation
        print("createVarSccMapping0 - Unsupported component-type.");
      then fail();
  end matchcontinue;
end createVarSccMapping0;

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
      then GRAPH(name, component::components, variables);
  end match;
end addSccToGraph;


protected function compScc
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

public function dumpAsGraphML_SccLevel
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


protected function addSccToGraphML
  input StrongConnectedComponent component;
  input GraphML.Graph iGraph;
  output GraphML.Graph oGraph;

protected
  String compText;
  Integer compIdx;
  String nodeDesc;
  List<Integer> dependencySCCs;

algorithm
  oGraph := match(component,iGraph)
    local
      GraphML.Graph tmpGraph;
    case(STRONGCONNECTEDCOMPONENT(text=compText,compIdx=compIdx, dependencySCCs=dependencySCCs),_)
      equation
        nodeDesc = "";
        tmpGraph = GraphML.addNode("Component" +& intString(compIdx), compText, GraphML.COLOR_GREEN, GraphML.RECTANGLE(), SOME(nodeDesc), iGraph);
        tmpGraph = List.fold1(dependencySCCs, addSccDepToGraph, compIdx, tmpGraph);
      then tmpGraph;
   end match;
end addSccToGraphML;


protected function addSccDepToGraph
  input Integer comp1Idx;
  input Integer comp2Idx;
  input GraphML.Graph iGraph;
  output GraphML.Graph oGraph;
 
algorithm
  oGraph := GraphML.addEgde("Edge" +& intString(comp2Idx) +& intString(comp1Idx), "Component" +& intString(comp2Idx), "Component" +& intString(comp1Idx), GraphML.COLOR_GREEN, GraphML.LINE(), NONE(), (SOME(GraphML.ARROWSTANDART()),NONE()), iGraph);
 
end addSccDepToGraph;


//public function dumpAsXML
//  input Graph iGraph;
//  input String fileName;
//end dumpAsXML;
end HpcOmTaskGraph;
