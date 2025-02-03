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
  import BPartition = NBPartition;
  import NBPartition.Partition;
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
    input BPartition.Kind kind;
  protected
    Module.causalizeInterface func = getModule();
  algorithm
    bdae := match (kind, bdae)
      local
        list<Partition> partitions, clocked;
        VarData varData;
        EqData eqData;
        FunctionTree funcTree;

      case (NBPartition.Kind.ODE, BackendDAE.MAIN(ode = partitions, clocked = clocked, varData = varData, eqData = eqData, funcTree = funcTree))
        algorithm
          (partitions, varData, eqData, funcTree) := applyModule(partitions, kind, varData, eqData, funcTree, func);
          (clocked, varData, eqData, funcTree) := applyModule(clocked, kind, varData, eqData, funcTree, func);
          bdae.ode := partitions;
          bdae.clocked := clocked;
          bdae.varData := varData;
          bdae.eqData := eqData;
          bdae.funcTree := funcTree;
      then bdae;

      case (NBPartition.Kind.INI, BackendDAE.MAIN(init = partitions, varData = varData, eqData = eqData, funcTree = funcTree))
        algorithm
          if Flags.isSet(Flags.INITIALIZATION) then
            print(StringUtil.headline_1("Balance Initialization") + "\n");
          end if;
          (partitions, varData, eqData, funcTree) := applyModule(partitions, kind, varData, eqData, funcTree, func);
          bdae.init := partitions;
          if Util.isSome(bdae.init_0) then
            (partitions, varData, eqData, funcTree) := applyModule(Util.getOption(bdae.init_0), kind, varData, eqData, funcTree, func);
            bdae.init_0 := SOME(partitions);
          end if;
          bdae.varData := varData;
          bdae.eqData := eqData;
          bdae.funcTree := funcTree;
      then bdae;

      case (NBPartition.Kind.DAE, BackendDAE.MAIN(dae = SOME(partitions), varData = varData, eqData = eqData, funcTree = funcTree))
        algorithm
          (partitions, varData, eqData, funcTree) := applyModule(partitions, kind, varData, eqData, funcTree, causalizeDAEMode);
          bdae.dae := SOME(partitions);
          bdae.varData := varData;
          bdae.eqData := eqData;
          bdae.funcTree := funcTree;
      then bdae;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed with partition type " + Partition.Partition.kindToString(kind) + "!"});
      then fail();
    end match;
  end main;

  function applyModule
    input list<Partition> partitions;
    input BPartition.Kind kind;
    output list<Partition> new_partitions = {};
    input output VarData varData;
    input output EqData eqData;
    input output FunctionTree funcTree;
    input Module.causalizeInterface func;
  protected
    Partition new_partition;
    Boolean violated = false "true if any partition violated variability consistency";
  algorithm
    for partition in partitions loop
      (new_partition, varData, eqData, funcTree) := func(partition, varData, eqData, funcTree);
      new_partitions := new_partition :: new_partitions;
    end for;
    new_partitions := listReverse(new_partitions);

    if kind <> NBPartition.Kind.INI then
      for partition in new_partitions loop
        violated := checkSystemVariabilities(partition) or violated;
      end for;
      if violated then fail(); end if;
    end if;
  end applyModule;

  function checkSystemVariabilities
    "checks whether variability is valid. Prevents things like `Integer i = time;`"
    input Partition partition;
    output Boolean violated = false;
  protected
    String err;
  algorithm
    if isSome(partition.strongComponents) then
      for scc in Util.getOption(partition.strongComponents) loop
        () := match scc
          local
            Type ty1, ty2;
          case StrongComponent.SINGLE_COMPONENT() algorithm
            ty1 := Type.removeSizeOneArraysAndRecords(Variable.typeOf(Pointer.access(scc.var)));
            ty2 := Type.removeSizeOneArraysAndRecords(Equation.getType(Pointer.access(scc.eqn)));
            if not Type.isEqual(ty1, ty2) then
              // The variability of the equation must be greater or equal to that of the variable it solves.
              // See MLS section 3.8 Variability of Expressions
              err := getInstanceName() + " failed. The following strong component has conflicting types: "
                + Type.toString(ty1) + " != " + Type.toString(ty2) + "\n" + StrongComponent.toString(scc);
              if Flags.isSet(Flags.BLT_DUMP) then
                err := err + "\n" + Partition.toString(partition);
              end if;
              Error.addMessage(Error.COMPILER_ERROR, {err});
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
    input EquationPointers eqns;
    input Adjacency.MatrixStrictness st = NBAdjacency.MatrixStrictness.MATCHING;
    output Matching matching;
    output list<StrongComponent> comps;
  protected
    Adjacency.Matrix full, adj;
  algorithm
    // create full matrix
    full := Adjacency.Matrix.createFull(vars, eqns);

    // create solvable adjacency matrix for matching
    adj := Adjacency.Matrix.fromFull(full, vars.map, eqns.map, eqns, st);
    matching := Matching.regular(NBMatching.EMPTY_MATCHING, adj);

    // create all occurence adjacency matrix for sorting, upgrading the matching matrix
    adj := Adjacency.Matrix.upgrade(adj, full, vars.map, eqns.map, eqns, NBAdjacency.MatrixStrictness.SORTING);
    comps := Sorting.tarjan(adj, matching, vars, eqns);
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
    BPartition.Kind kind = Partition.getKind(partition);
    VariablePointers variables;
    EquationPointers equations;
    Adjacency.Matrix full, adj_matching, adj_sorting;
    Matching matching;
    list<StrongComponent> comps;
  algorithm
    (variables, equations, full, matching, comps) := match kind
      local
        list<Pointer<Variable>> fixable, unfixable;
        list<Pointer<Equation>> initials, simulation;
        UnorderedMap<ComponentRef, Integer> vo, vn, eo, en;

      case kind as NBPartition.Kind.INI algorithm
        // compress the arrays to remove gaps
        partition.unknowns   := VariablePointers.compress(partition.unknowns);
        partition.equations  := EquationPointers.compress(partition.equations);

        // split the variables and equations
        (fixable, unfixable)    := List.splitOnTrue(VariablePointers.toList(partition.unknowns), BVariable.isFixable);
        (initials, simulation)  := List.splitOnTrue(EquationPointers.toList(partition.equations), Equation.isInitial);

        // create full matrix
        full := Adjacency.Matrix.createFull(partition.unknowns, partition.equations);

        // do not resolve potential singular partitions in Phase I or II! -> regular matching
        // #################################################
        // Phase I: match initial equations <-> unfixable vars
        // #################################################
        vn := UnorderedMap.subMap(partition.unknowns.map, list(BVariable.getVarName(var) for var in unfixable));
        en := UnorderedMap.subMap(partition.equations.map, list(Equation.getEqnName(eqn) for eqn in initials));
        adj_matching := Adjacency.Matrix.fromFull(full, vn, en, partition.equations, NBAdjacency.MatrixStrictness.MATCHING);
        matching := Matching.regular(NBMatching.EMPTY_MATCHING, adj_matching, true, true);

        // #################################################
        // Phase II: match all equations <-> unfixables
        // #################################################
        vo := vn;
        eo := en;
        vn := UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual);
        en := UnorderedMap.subMap(partition.equations.map, list(Equation.getEqnName(eqn) for eqn in simulation));
        (adj_matching, full) := Adjacency.Matrix.expand(adj_matching, full, vo, vn, eo, en, partition.unknowns, partition.equations);
        matching := Matching.regular(matching, adj_matching, true, true);

        // #################################################
        // Phase III: match all equations <-> all vars
        // #################################################
        vo := UnorderedMap.merge(vo, vn, sourceInfo());
        eo := UnorderedMap.merge(eo, en, sourceInfo());
        vn := UnorderedMap.subMap(partition.unknowns.map, list(BVariable.getVarName(var) for var in fixable));
        en := UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual);
        (adj_matching, full) := Adjacency.Matrix.expand(adj_matching, full, vo, vn, eo, en, partition.unknowns, partition.equations);
        (matching, adj_matching, full, variables, equations, funcTree, varData, eqData) := Matching.singular(matching, adj_matching, full, partition.unknowns, partition.equations, funcTree, varData, eqData, kind, false, false);

        // create all occurence adjacency matrix for sorting, upgrading the matching matrix
        adj_sorting := Adjacency.Matrix.upgrade(adj_matching, full, variables.map, equations.map, equations, NBAdjacency.MatrixStrictness.SORTING);
        comps := Sorting.tarjan(adj_sorting, matching, variables, equations);
      then (variables, equations, full, matching, comps);

      else algorithm
        // compress the arrays to remove gaps
        variables := VariablePointers.compress(partition.unknowns);
        equations := EquationPointers.compress(partition.equations);

        // create full matrix
        full := Adjacency.Matrix.createFull(variables, equations);

        // create solvable adjacency matrix for matching
        adj_matching := Adjacency.Matrix.fromFull(full, variables.map, equations.map, equations, NBAdjacency.MatrixStrictness.MATCHING);
        (matching, adj_matching, full, variables, equations, funcTree, varData, eqData) := Matching.singular(NBMatching.EMPTY_MATCHING, adj_matching, full, variables, equations, funcTree, varData, eqData, kind, false);

        // create all occurence adjacency matrix for sorting, upgrading the matching matrix
        adj_sorting := Adjacency.Matrix.upgrade(adj_matching, full, variables.map, equations.map, equations, NBAdjacency.MatrixStrictness.SORTING);
        comps := Sorting.tarjan(adj_sorting, matching, variables, equations);
      then (variables, equations, full, matching, comps);
    end match;

    partition.unknowns := variables;
    partition.equations := equations;
    partition.adjacencyMatrix := SOME(full);
    partition.matching := SOME(matching);
    partition.strongComponents := SOME(listArray(comps));
  end causalizePseudoArray;

  function causalizeDAEMode extends Module.causalizeInterface;
  protected
    Pointer<list<StrongComponent>> acc = Pointer.create({});
  algorithm
    // create all components as residuals for now
    // ToDo: use tearing to get inner/tmp equations
    EquationPointers.mapPtr(partition.equations, function StrongComponent.makeDAEModeResidualTraverse(acc = acc));
    partition.strongComponents := SOME(List.listArrayReverse(Pointer.access(acc)));
  end causalizeDAEMode;

  annotation(__OpenModelica_Interface="backend");
end NBCausalize;
