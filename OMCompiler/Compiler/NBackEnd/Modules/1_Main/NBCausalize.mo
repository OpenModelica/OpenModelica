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
  import Prefixes = NFPrefixes;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;
  import NFArrayConnections.NameVertexTable;

  // Backend imports
  import Adjacency = NBAdjacency;
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import Differentiate = NBDifferentiate;
  import NBEquation.{Equation, EquationPointers, EqData, EquationAttributes};
  import Matching = NBMatching;
  import Sorting = NBSorting;
  import StrongComponent = NBStrongComponent;
  import System = NBSystem;
  import BVariable = NBVariable;
  import NBVariable.{VariablePointers, VarData};

  // util imports
  import BackendUtil = NBBackendUtil;
  import Error;
  import List;
  import StringUtil;
  import UnorderedSet;

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
        list<System.System> systems;
        VarData varData;
        EqData eqData;
        FunctionTree funcTree;

      case (System.SystemType.ODE, BackendDAE.MAIN(ode = systems, varData = varData, eqData = eqData, funcTree = funcTree))
        algorithm
          (systems, varData, eqData, funcTree) := applyModule(systems, systemType, varData, eqData, funcTree, func);
          bdae.ode := systems;
          bdae.varData := varData;
          bdae.eqData := eqData;
          bdae.funcTree := funcTree;
      then bdae;

      case (System.SystemType.INI, BackendDAE.MAIN(init = systems, varData = varData, eqData = eqData, funcTree = funcTree))
        algorithm
          if Flags.isSet(Flags.INITIALIZATION) then
            print(StringUtil.headline_1("Balance Initialization") + "\n");
          end if;
          (systems, varData, eqData, funcTree) := applyModule(systems, systemType, varData, eqData, funcTree, func);
          bdae.init := systems;
          if Util.isSome(bdae.init_0) then
            (systems, varData, eqData, funcTree) := applyModule(Util.getOption(bdae.init_0), systemType, varData, eqData, funcTree, func);
            bdae.init_0 := SOME(systems);
          end if;
          bdae.varData := varData;
          bdae.eqData := eqData;
          bdae.funcTree := funcTree;
      then bdae;

      case (System.SystemType.DAE, BackendDAE.MAIN(dae = SOME(systems), varData = varData, eqData = eqData, funcTree = funcTree))
        algorithm
          (systems, varData, eqData, funcTree) := applyModule(systems, systemType, varData, eqData, funcTree, causalizeDAEMode);
          bdae.dae := SOME(systems);
          bdae.varData := varData;
          bdae.eqData := eqData;
          bdae.funcTree := funcTree;
      then bdae;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed with system type " + System.System.systemTypeString(systemType) + "!"});
      then fail();
    end match;
  end main;

  function applyModule
    input list<System.System> systems;
    input System.SystemType systemType;
    output list<System.System> new_systems = {};
    input output VarData varData;
    input output EqData eqData;
    input output FunctionTree funcTree;
    input Module.causalizeInterface func;
  protected
    System.System new_system;
    Boolean violated = false "true if any system violated variability consistency";
  algorithm
    for system in systems loop
      (new_system, varData, eqData, funcTree) := func(system, varData, eqData, funcTree);
      new_systems := new_system :: new_systems;
    end for;
    new_systems := listReverse(new_systems);

    if systemType <> System.SystemType.INI then
      for system in new_systems loop
        violated := checkSystemVariabilities(system) or violated;
      end for;
      if violated then fail(); end if;
    end if;
  end applyModule;

  function checkSystemVariabilities
    "checks whether variability is valid. Prevents things like `Integer i = time;`"
    input System.System system;
    output Boolean violated = false;
  algorithm
    if isSome(system.strongComponents) then
      for scc in Util.getOption(system.strongComponents) loop
        () := match scc
          local
            Type ty1, ty2;
          case StrongComponent.SINGLE_COMPONENT() algorithm
            ty1 := Type.removeSizeOneArrays(Variable.typeOf(Pointer.access(scc.var)));
            ty2 := Type.removeSizeOneArrays(Equation.getType(Pointer.access(scc.eqn)));
            if not Type.isEqual(ty1, ty2) then
              // The variability of the equation must be greater or equal to that of the variable it solves.
              // See MLS section 3.8 Variability of Expressions
              Error.addMessage(Error.COMPILER_ERROR, {getInstanceName() + " failed. The following strong component has conflicting types: "
                + Type.toString(ty1) + " != " + Type.toString(ty2)
                + "\n" + StrongComponent.toString(scc)});
              violated := true;
            end if;
          then ();
          /* TODO case StrongComponent.MULTI_COMPONENT() */
          else ();
        end match;
      end for;
    end if;
  end checkSystemVariabilities;

  function simple
    input VariablePointers vars;
    input EquationPointers eqs;
    output list<StrongComponent> comps;
  protected
    Adjacency.Matrix adj;
    Matching matching;
  algorithm
    // create scalar adjacency matrix for now
    adj := Adjacency.Matrix.create(vars, eqs);
    matching := Matching.regular(NBMatching.EMPTY_MATCHING, adj);
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
  function causalizePseudoArray extends Module.causalizeInterface;
  protected
    VariablePointers variables;
    EquationPointers equations;
    Adjacency.Matrix adj, adj_matching, adj_sorting;
    Matching matching;
    list<StrongComponent> comps;
  algorithm
    (variables, equations, adj, matching, comps) := match system.systemType
      local
        list<Pointer<Variable>> fixable, unfixable;
        list<Pointer<Equation>> initials, simulation;
        UnorderedMap<ComponentRef, Integer> vo, vn, eo, en;

      case NBSystem.SystemType.INI algorithm
        // compress the arrays to remove gaps
        system.unknowns   := VariablePointers.compress(system.unknowns);
        system.equations  := EquationPointers.compress(system.equations);

        // split the variables and equations
        (fixable, unfixable)    := List.splitOnTrue(VariablePointers.toList(system.unknowns), BVariable.isFixable);
        (initials, simulation)  := List.splitOnTrue(EquationPointers.toList(system.equations), Equation.isInitial);

        // create full matrix
        adj := Adjacency.Matrix.createFull(system.unknowns, system.equations);

        // do not resolve potential singular systems in Phase I or II! -> regular matching
        // #################################################
        // Phase I: match initial equations <-> unfixable vars
        // #################################################
        vn := UnorderedMap.subSet(system.unknowns.map, list(BVariable.getVarName(var) for var in unfixable));
        en := UnorderedMap.subSet(system.equations.map, list(Equation.getEqnName(eqn) for eqn in initials));

        adj_matching := Adjacency.Matrix.fromFull(adj, vn, en, system.equations, NBAdjacency.MatrixStrictness.MATCHING);
        matching := Matching.regular(NBMatching.EMPTY_MATCHING, adj_matching, true, true);

        // #################################################
        // Phase II: match all equations <-> unfixables
        // #################################################
        vo := vn;
        eo := en;
        vn := UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual);
        en := UnorderedMap.subSet(system.equations.map, list(Equation.getEqnName(eqn) for eqn in simulation));

        adj_matching := Adjacency.Matrix.expand2(adj_matching, adj, vo, vn, eo, en, system.unknowns, system.equations);
        matching := Matching.regular(matching, adj_matching, true, true);

        // #################################################
        // Phase III: match all equations <-> all vars
        // #################################################
        vo := vn;
        eo := en;
        vn := UnorderedMap.subSet(system.unknowns.map, list(BVariable.getVarName(var) for var in fixable));
        en := UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual);
        adj_matching := Adjacency.Matrix.expand2(adj_matching, adj, vo, vn, eo, en, system.unknowns, system.equations);
        (matching, adj_matching, variables, equations, funcTree, varData, eqData) := Matching.singular(matching, adj_matching, system.unknowns, system.equations, funcTree, varData, eqData, system.systemType, false, true, false);

        // create all occurence adjacency matrix for sorting, upgrading the matching matrix
        adj_sorting := Adjacency.Matrix.upgrade(adj_matching, adj, variables.map, equations.map, equations, NBAdjacency.MatrixStrictness.SORTING);
        comps := Sorting.tarjan(adj_sorting, matching, variables, equations);
      then (variables, equations, adj, matching, comps);

      else algorithm
        // compress the arrays to remove gaps
        variables := VariablePointers.compress(system.unknowns);
        equations := EquationPointers.compress(system.equations);

        // create full matrix
        adj := Adjacency.Matrix.createFull(variables, equations);

        // create solvable adjacency matrix for matching
        adj_matching := Adjacency.Matrix.fromFull(adj, variables.map, equations.map, equations, NBAdjacency.MatrixStrictness.MATCHING);
        (matching, adj_matching, variables, equations, funcTree, varData, eqData) := Matching.singular(NBMatching.EMPTY_MATCHING, adj_matching, variables, equations, funcTree, varData, eqData, system.systemType, false, true);

        // create all occurence adjacency matrix for sorting, upgrading the matching matrix
        adj_sorting := Adjacency.Matrix.upgrade(adj_matching, adj, variables.map, equations.map, equations, NBAdjacency.MatrixStrictness.SORTING);
        comps := Sorting.tarjan(adj_sorting, matching, variables, equations);
      then (variables, equations, adj, matching, comps);
    end match;

    system.unknowns := variables;
    system.equations := equations;
    system.adjacencyMatrix := SOME(adj);
    system.matching := SOME(matching);
    system.strongComponents := SOME(listArray(comps));
  end causalizePseudoArray;

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
