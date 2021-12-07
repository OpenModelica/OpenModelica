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
encapsulated package NBCausalize
"file:        NBCausalize.mo
 package:     NBCausalize
 description: This file contains the functions which perform the causalization process;
"

public
  import Module = NBModule;

protected
  // NF imports
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import NFFlatten.{FunctionTree, FunctionTreeImpl};
  import InstNode = NFInstNode.InstNode;
  import SBGraphUtil = NFSBGraphUtil;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;
  import NFArrayConnections.NameVertexTable;

  // Backend imports
  import Adjacency = NBAdjacency;
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import Differentiate = NBDifferentiate;
  import NBEquation.EqData;
  import NBEquation.Equation;
  import NBEquation.EquationAttributes;
  import NBEquation.EquationPointers;
  import Matching = NBMatching;
  import Sorting = NBSorting;
  import StrongComponent = NBStrongComponent;
  import System = NBSystem;
  import BVariable = NBVariable;
  import NBVariable.VarData;
  import NBVariable.VariablePointers;

  // util imports
  import BackendUtil = NBBackendUtil;
  import Error;
  import List;
  import StringUtil;
  import UnorderedSet;

  // SetBased Graph imports
  import SBGraph.BipartiteIncidenceList;
  import SBGraph.VertexDescriptor;
  import SBGraph.SetType;
  import NBAdjacency.BipartiteGraph;
  import SBInterval;
  import SBMultiInterval;
  import SBPWLinearMap;
  import SBSet;
  import NBGraphUtil.{SetVertex, SetEdge};

  // ############################################################
  //                      Main Functions
  // ############################################################

public
  function main extends Module.wrapper;
    input System.SystemType systemType;
  protected
    Module.causalizeInterface func = getModule();
  algorithm
    bdae := match (systemType, bdae)
      local
        System.System new_system;
        list<System.System> systems, new_systems = {};
        VarData varData;
        EqData eqData;
        FunctionTree funcTree;

      case (System.SystemType.ODE, BackendDAE.MAIN(ode = systems, varData = varData, eqData = eqData, funcTree = funcTree))
        algorithm
          for system in systems loop
            (new_system, varData, eqData, funcTree) := func(system, varData, eqData, funcTree, NBAdjacency.MatrixStrictness.FULL);
            new_systems := new_system :: new_systems;
          end for;
          bdae.ode := listReverse(new_systems);
          bdae.varData := varData;
          bdae.eqData := eqData;
      then bdae;

      case (System.SystemType.INI, BackendDAE.MAIN(init = systems, varData = varData, eqData = eqData, funcTree = funcTree))
        algorithm
          if Flags.isSet(Flags.INITIALIZATION) then
            print(StringUtil.headline_1("Balance Initialization") + "\n");
          end if;
          for system in systems loop
            (new_system, varData, eqData, funcTree) := func(system, varData, eqData, funcTree, NBAdjacency.MatrixStrictness.INIT);
            new_systems := new_system :: new_systems;
          end for;
          bdae.init := listReverse(new_systems);
          bdae.varData := varData;
          bdae.eqData := eqData;
      then bdae;

      case (System.SystemType.DAE, BackendDAE.MAIN(dae = SOME(systems), varData = varData, eqData = eqData, funcTree = funcTree))
        algorithm
          for system in systems loop
            (new_system, varData, eqData, funcTree) := causalizeDAEMode(system, varData, eqData, funcTree, NBAdjacency.MatrixStrictness.FULL);
            new_systems := new_system :: new_systems;
          end for;
          bdae.dae := SOME(listReverse(new_systems));
          bdae.varData := varData;
          bdae.eqData := eqData;
      then bdae;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed with system type " + System.System.systemTypeString(systemType) + "!"});
      then fail();
    end match;
  end main;

  function simple
    input VariablePointers vars;
    input BEquation.EquationPointers eqs;
    input Adjacency.MatrixType matrixType = NBAdjacency.MatrixType.PSEUDO;
    output list<StrongComponent> comps;
  protected
    Adjacency.Matrix adj;
    Matching matching;
  algorithm
     // create scalar adjacency matrix for now
    adj := Adjacency.Matrix.create(vars, eqs, matrixType);
    matching := Matching.regular(Matching.EMPTY_MATCHING(), adj);
    comps := Sorting.tarjan(adj, matching, vars, eqs);
  end simple;

  function getModule
    "Returns the module function that was chosen by the user."
    output Module.causalizeInterface func;
  protected
    String flag = Flags.getConfigString(Flags.MATCHING_ALGORITHM);
  algorithm
    (func) := match flag
      case "PFPlusExt"  then causalizePseudoArray;
      case "SBGraph"    then causalizeArray;
      case "linear"     then causalizeScalar;
      case "pseudo"     then causalizePseudoArray;
      /* ... New causalize modules have to be added here */
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for unknown option: " + flag});
      then fail();
    end match;
  end getModule;

  // ############################################################
  //                Protected Functions and Types
  // ############################################################

protected
  function causalizeScalar extends Module.causalizeInterface;
  protected
    VariablePointers variables;
    EquationPointers equations;
    Adjacency.Matrix adj;
    Matching matching;
    list<StrongComponent> comps;
  algorithm
    // compress the arrays to remove gaps
    variables := VariablePointers.compress(system.unknowns);
    equations := EquationPointers.compress(system.equations);

    adj := Adjacency.Matrix.create(variables, equations, NBAdjacency.MatrixType.SCALAR, matrixStrictness);
    (matching, adj, variables, equations, funcTree, varData, eqData) := Matching.singular(Matching.EMPTY_MATCHING(), adj, variables, equations, funcTree, varData, eqData, false, true);
    comps := Sorting.tarjan(adj, matching, variables, equations);

    system.unknowns := variables;
    system.equations := equations;
    system.adjacencyMatrix := SOME(adj);
    system.matching := SOME(matching);
    system.strongComponents := SOME(listArray(comps));
  end causalizeScalar;

  function causalizePseudoArray extends Module.causalizeInterface;
  protected
    VariablePointers variables;
    EquationPointers equations;
    Adjacency.Matrix adj;
    Matching matching;
    list<StrongComponent> comps;
  algorithm
    (variables, equations, adj, matching, comps) := match matrixStrictness
      local
        list<Pointer<Variable>> fixable, unfixable;
        list<Pointer<Equation>> initials, simulation;

      case NBAdjacency.MatrixStrictness.INIT algorithm
        (fixable, unfixable)    := List.splitOnTrue(VariablePointers.toList(system.unknowns), BVariable.isFixable);
        (initials, simulation)  := List.splitOnTrue(EquationPointers.toList(system.equations), Equation.isInitial);

        // #################################################
        // Phase I: match sim equations <-> unfixable vars
        // #################################################
        variables := VariablePointers.fromList(unfixable);
        equations := EquationPointers.fromList(simulation);
        adj := Adjacency.Matrix.create(variables, equations, NBAdjacency.MatrixType.PSEUDO, matrixStrictness);
        // do not resolve potential singular systems in Phase I! -> regular matching
        matching := Matching.regular(Matching.EMPTY_MATCHING(), adj, true, true);

        // #################################################
        // Phase II: match all equations <-> all vars
        // #################################################
        (adj, variables, equations) := Adjacency.Matrix.expand(adj, variables, equations, fixable, initials);
        (matching, adj, variables, equations, funcTree, varData, eqData) := Matching.singular(matching, adj, variables, equations, funcTree, varData, eqData, false, true, false);

        comps := Sorting.tarjan(adj, matching, variables, equations);
      then (variables, equations, adj, matching, comps);

      else algorithm
        // compress the arrays to remove gaps
        variables := VariablePointers.compress(system.unknowns);
        equations := EquationPointers.compress(system.equations);

        // create scalar adjacency matrix for now
        adj := Adjacency.Matrix.create(variables, equations, NBAdjacency.MatrixType.PSEUDO, matrixStrictness);
        (matching, adj, variables, equations, funcTree, varData, eqData) := Matching.singular(Matching.EMPTY_MATCHING(), adj, variables, equations, funcTree, varData, eqData, false, true);
        comps := Sorting.tarjan(adj, matching, variables, equations);
      then (variables, equations, adj, matching, comps);
    end match;

    system.unknowns := variables;
    system.equations := equations;
    system.adjacencyMatrix := SOME(adj);
    system.matching := SOME(matching);
    system.strongComponents := SOME(listArray(comps));
  end causalizePseudoArray;

  function causalizeArray extends Module.causalizeInterface;
  protected
    VariablePointers variables;
    EquationPointers equations;
    Adjacency.Matrix adj;
    Matching matching;
    list<StrongComponent> comps;
  algorithm
    // compress the arrays to remove gaps
    variables := VariablePointers.compress(system.unknowns);
    equations := EquationPointers.compress(system.equations);

    // create scalar adjacency matrix for now
    adj := Adjacency.Matrix.create(variables, equations, NBAdjacency.MatrixType.ARRAY, matrixStrictness);
    matching := Matching.regular(Matching.EMPTY_MATCHING(), adj);
  end causalizeArray;

  function causalizeLinear extends Module.causalizeInterface;
  protected
    VariablePointers variables;
    EquationPointers equations;
    Adjacency.Matrix adj;
    Matching matching;
    list<StrongComponent> comps;
  algorithm
    // compress the arrays to remove gaps
    variables := VariablePointers.compress(system.unknowns);
    equations := EquationPointers.compress(system.equations);

    // create scalar adjacency matrix for now
    adj := Adjacency.Matrix.create(variables, equations, NBAdjacency.MatrixType.SCALAR, matrixStrictness);
    matching := Matching.linear(adj);
  end causalizeLinear;

  function causalizeDAEMode extends Module.causalizeInterface;
  protected
    Pointer<list<StrongComponent>> acc = Pointer.create({});
  algorithm
    // create all components as residuals for now
    // ToDo: use tearing to get inner/tmp equations
    EquationPointers.mapPtr(system.equations, function StrongComponent.makeDAEModeResidualTraverse(acc = acc));
    system.strongComponents := SOME(List.listArrayReverse(Pointer.access(acc)));
  end causalizeDAEMode;

  annotation(__OpenModelica_Interface="backend");
end NBCausalize;
