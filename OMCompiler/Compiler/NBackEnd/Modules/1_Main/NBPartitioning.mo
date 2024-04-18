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
encapsulated package NBPartitioning
"file:        NBPartitioning.mo
 package:     NBPartitioning
 description: This file contains the functions for the partitioning module.
"

public
  import Module = NBModule;

protected
  // NF
  import NFBackendExtension.{BackendInfo, VariableKind};
  import Call = NFCall;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import NFFunction.Function;
  import Type = NFType;
  import Variable = NFVariable;

  // Backend
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import NBEquation.{Equation, EquationPointer, EquationPointers};
  import StrongComponent = NBStrongComponent;
  import System = NBSystem;
  import BVariable = NBVariable;
  import NBVariable.VariablePointers;

  // Util
  import MetaModelica.Dangerous;
  import DoubleEnded;
  import UnorderedMap;
  import UnorderedSet;

// =========================================================================
//                      MAIN ROUTINE, PLEASE DO NOT CHANGE
// =========================================================================
public
  function main
    "Wrapper function for any partitioning function. This will be
     called during simulation and gets the corresponding subfunction from
     Config."
    extends Module.wrapper;
    input System.SystemType systemType;
  protected
    Module.partitioningInterface func;
  algorithm
    func := getModule();

    bdae := match (systemType, bdae)
      local
        VariablePointers variables;
        EquationPointers equations;

      case (System.SystemType.ODE, BackendDAE.MAIN(varData = BVariable.VAR_DATA_SIM(unknowns = variables), eqData = BEquation.EQ_DATA_SIM(simulation = equations)))
        algorithm
          bdae.ode := list(sys for sys guard(not System.System.isEmpty(sys)) in func(systemType, variables, equations));
        then bdae;

      case (System.SystemType.INI, BackendDAE.MAIN(varData = BVariable.VAR_DATA_SIM(initials = variables), eqData = BEquation.EQ_DATA_SIM(initials = equations)))
        algorithm
          bdae.init := list(sys for sys guard(not System.System.isEmpty(sys)) in partitioningNone(systemType, variables, equations));
        then bdae;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
      then fail();
    end match;
  end main;

  function getModule
    "Returns the module function that was chosen by the user."
    output Module.partitioningInterface func;
  protected
    String flag = "clocked"; //Flags.getConfigString(Flags.PARTITIONING)
  algorithm
    (func) := match flag
      case "default"  then (partitioningClocked);
      case "clocked"  then (partitioningClocked);
      case "none"     then (partitioningNone);
      /* ... New detect states modules have to be added here */
      else fail();
    end match;
  end getModule;

  function categorize
    "creates ODE, ALG, ODE_EVT, ALG_EVT systems from ODE by checking
    if it contains discrete equations or state equations.
    Should be evoked just before jacobian at the very end."
    extends Module.wrapper;
  algorithm
    bdae := match bdae
      local
        DoubleEnded.MutableList<System.System> ode = DoubleEnded.MutableList.fromList({});
        DoubleEnded.MutableList<System.System> alg = DoubleEnded.MutableList.fromList({});
        DoubleEnded.MutableList<System.System> ode_evt = DoubleEnded.MutableList.fromList({});
        DoubleEnded.MutableList<System.System> alg_evt = DoubleEnded.MutableList.fromList({});

      case BackendDAE.MAIN() algorithm
        for syst in bdae.ode loop
          System.System.categorize(syst, ode, alg, ode_evt, alg_evt);
        end for;
        bdae.ode := DoubleEnded.MutableList.toListAndClear(ode);
        bdae.algebraic := DoubleEnded.MutableList.toListAndClear(alg);
        bdae.ode_event := DoubleEnded.MutableList.toListAndClear(ode_evt);
        bdae.alg_event := DoubleEnded.MutableList.toListAndClear(alg_evt);
      then bdae;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
      then fail();
    end match;
  end categorize;

protected
  type ClusterElementType = enumeration(EQUATION, VARIABLE);

  uniontype Cluster
    record CLUSTER
      UnorderedSet<ComponentRef> variables    "list of all variables in this set";
      UnorderedSet<ComponentRef> eqn_idnts    "list of all equations in this set";
    end CLUSTER;

    function toString
      input Cluster cluster;
      output String str;
    algorithm
      str := "### Cluster Variables:\n" + UnorderedSet.toString(cluster.variables, ComponentRef.toString)
        + "### Cluster Equation Identifiers:\n" + UnorderedSet.toString(cluster.eqn_idnts, ComponentRef.toString);
    end toString;

    function addElement
      input Option<Cluster> cluster_opt;
      input ComponentRef cref;
      input ClusterElementType ty;
      output Cluster cluster;
    algorithm
      cluster := match cluster_opt
        case SOME(cluster)  then cluster;
        else CLUSTER(
          variables = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual),
          eqn_idnts = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual));
      end match;

      cluster := match ty
        case ClusterElementType.VARIABLE algorithm
          UnorderedSet.add(cref, cluster.variables);
        then cluster;
        case ClusterElementType.EQUATION algorithm
          UnorderedSet.add(cref, cluster.eqn_idnts);
        then cluster;
      end match;
    end addElement;

    function toSystem
      input Cluster cluster;
      input VariablePointers variables;
      input EquationPointers equations;
      input System.SystemType systemType;
      input Pointer<Integer> index;
      output System.System system;
    protected
      list<ComponentRef> cvars = UnorderedSet.toList(cluster.variables);
      list<ComponentRef> cidnt = UnorderedSet.toList(cluster.eqn_idnts);
      Boolean isInit = systemType == System.SystemType.INI;
      list<Pointer<Variable>> var_lst, filtered_vars;
      list<Pointer<Equation>> eqn_lst;
      VariablePointers systVariables;
      EquationPointers systEquations;
      Integer var_idx;
    algorithm
      var_lst := list(BVariable.getVarPointer(cref) for cref in cvars);
      filtered_vars := list(var for var guard(VariablePointers.contains(var, variables)) in var_lst);
      eqn_lst := list(EquationPointers.getEqnByName(equations, name) for name in cidnt);

      systVariables := VariablePointers.fromList(filtered_vars);
      systEquations := EquationPointers.fromList(eqn_lst);

      system := System.SYSTEM(
        systemType        = systemType,
        unknowns          = systVariables,
        daeUnknowns       = NONE(),
        equations         = systEquations,
        adjacencyMatrix   = NONE(),
        matching          = NONE(),
        strongComponents  = NONE(),
        partitionKind     = System.PartitionKind.CONTINUOUS,
        partitionIndex    = Pointer.access(index),
        jacobian          = NONE()
      );
      Pointer.update(index, Pointer.access(index) + 1);
    end toSystem;
  end Cluster;

  // Perhaps this deserves its own place in Util/*.mo
  uniontype DisjointSetForest
    "Custom implementation of disjoint-set data structure with constant number of elements."
    record FOREST
      Pointer<array<Integer>> parent;
      Pointer<array<Integer>> rank;
    end FOREST;

    function new
      "Creates n disjoit subsets of size 1."
      input Integer n;
      output DisjointSetForest dsf;
    algorithm
      dsf := FOREST(
        parent = Pointer.create(listArray(list(i for i in 1:n))),
        rank   = Pointer.create(arrayCreate(n, 0))
      );
    end new;

    function find
      input DisjointSetForest dsf;
      input output Integer index;
    protected
      array<Integer> parent = Pointer.access(dsf.parent);
    algorithm
      while index <> parent[index] loop
        parent[index] := parent[parent[index]] "path halving";
        index := parent[index];
      end while;
      Pointer.update(dsf.parent, parent);
    end find;

    function unite
      input DisjointSetForest dsf;
      input list<Integer> indices;
      output Integer root;
    protected
      list<Integer> roots = list(find(dsf, i) for i in indices);
      array<Integer> parent = Pointer.access(dsf.parent);
      array<Integer> rank = Pointer.access(dsf.rank);
      Integer maxRank;
      Boolean tied = false;
    algorithm
      // find root with highest rank
      root := listHead(roots);
      maxRank := rank[root];
      for r in listRest(roots) loop
        if r <> root then
          if rank[r] > maxRank then
            root := r;
            maxRank := rank[root];
            tied := false;
          elseif rank[r] == maxRank then
            tied := true;
          end if;
        end if;
      end for;

      // update parents
      for r in roots loop
        parent[find(dsf, r)] := root;
      end for;

      // if necessary increment rank
      if tied then
        rank[root] := rank[root] + 1;
      end if;

      Pointer.update(dsf.parent, parent);
      Pointer.update(dsf.rank, rank);
    end unite;
  end DisjointSetForest;

  function partitioningNone extends Module.partitioningInterface;
  protected
    Boolean isInit = systemType == System.SystemType.INI;
    VariablePointers clone_vars;
    EquationPointers clone_eqns;
  algorithm
    clone_vars := VariablePointers.clone(variables);
    clone_eqns := EquationPointers.clone(equations);
    systems := {System.SYSTEM(
      systemType        = systemType,
      unknowns          = clone_vars,
      daeUnknowns       = NONE(),
      equations         = clone_eqns,
      adjacencyMatrix   = NONE(),
      matching          = NONE(),
      strongComponents  = NONE(),
      partitionKind     = System.PartitionKind.CONTINUOUS,
      partitionIndex    = 1,
      jacobian          = NONE()
    )};
  end partitioningNone;

  function partitioningClocked extends Module.partitioningInterface;
  protected
    DisjointSetForest eqn_dsf = DisjointSetForest.new(equations.eqArr.lastUsedIndex[1]);
    array<Integer> var_map = arrayCreate(variables.varArr.lastUsedIndex[1], -1);
    Pointer<Equation> eqn;
    UnorderedSet<ComponentRef> var_crefs;
    list<Integer> var_indices;
    Integer part_idx;
    UnorderedMap<Integer, Cluster> cluster_map = UnorderedMap.new<Cluster>(Util.id, intEq);
    ComponentRef name_cref;
    Pointer<Integer> index = Pointer.create(1);
    array<Boolean> marked_vars;
    list<Pointer<Variable>> single_vars;
  algorithm
    for eq_idx in UnorderedMap.valueList(equations.map) loop
      if eq_idx > 0 then
        eqn := EquationPointers.getEqnAt(equations, eq_idx);
        var_crefs := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);

        // collect all crefs in equation
        _ := Equation.map(Pointer.access(eqn), function collectPartitioningCrefs(var_crefs = var_crefs), NONE(), Expression.mapReverse);

        // find all indices of connected variables
        var_indices := list(VariablePointers.getVarIndex(variables, cref) for cref in UnorderedSet.toList(var_crefs));
        // filter indices of non existant variables (e.g. time)
        var_indices := list(i for i guard(i > 0) in var_indices);

        // unite current equation and all variables that already belong to a partition
        part_idx := DisjointSetForest.unite(eqn_dsf, eq_idx :: list(var_map[j] for j guard(var_map[j] > 0) in var_indices));

        // update connected variable partition indices
        for i in var_indices loop
          var_map[i] := part_idx;
        end for;
      end if;
    end for;

    // find and report variables that could not be assigned to a partition
    marked_vars := listArray(list(var_map[var_idx] < 0 for var_idx in UnorderedMap.valueList(variables.map)));
    single_vars := VariablePointers.getMarkedVars(variables, marked_vars);

    if not listEmpty(single_vars) then
      Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " (" + System.System.systemTypeString(systemType)
        + ") failed because the following variables could not be assigned to a partition:\n  {"
        + stringDelimitList(list(BVariable.toString(Pointer.access(var)) for var in single_vars), "\n") + "}"});
      fail();
    end if;

    // collect clusters
    for eq_idx in UnorderedMap.valueList(equations.map) loop
      if eq_idx > 0 then
        name_cref := Equation.getEqnName(EquationPointers.getEqnAt(equations, eq_idx));
        UnorderedMap.addUpdate(DisjointSetForest.find(eqn_dsf, eq_idx), function Cluster.addElement(cref = name_cref, ty = ClusterElementType.EQUATION), cluster_map);
      end if;
    end for;

    for var_idx in UnorderedMap.valueList(variables.map) loop
      if var_idx > 0 then
        name_cref := BVariable.getVarName(VariablePointers.getVarAt(variables, var_idx));
        UnorderedMap.addUpdate(DisjointSetForest.find(eqn_dsf, var_map[var_idx]), function Cluster.addElement(cref = name_cref, ty = ClusterElementType.VARIABLE), cluster_map);
      end if;
    end for;

    systems := list(Cluster.toSystem(cl, variables, equations, systemType, index) for cl in UnorderedMap.valueList(cluster_map));
    if Flags.isSet(Flags.DUMP_SYNCHRONOUS) then
      print(StringUtil.headline_1("[dumpSynchronous] Partitioning result:") + "\n" + List.toString(systems, function System.System.toString(level = 0), "", "", "\n", "\n"));
    end if;
  end partitioningClocked;

  function collectPartitioningCrefs
    input output Expression exp;
    input UnorderedSet<ComponentRef> var_crefs;
  algorithm
    exp := match exp
      local
        Expression newExp;
        Call call;
        Expression arg;
        list<ComponentRef> children;
        ComponentRef stripped;

      // clocked partitioning special rules
      case Expression.CALL(call = call as Call.TYPED_CALL()) algorithm
        newExp := match AbsynUtil.pathString(Function.nameConsiderBuiltin(call.fn))
          case "previous" then Expression.EMPTY(Type.INTEGER());
          case "hold"     then Expression.EMPTY(Type.INTEGER());
          case "sample" algorithm
            {_, _, arg} := Call.arguments(exp.call);
            _ := collectPartitioningCrefs(arg, var_crefs);
          then Expression.EMPTY(Type.INTEGER());
          else exp;
        end match;
      then newExp;

      // get all variable crefs for this cref and add to set
      case Expression.CREF() algorithm
        // extract potential record children
        children := match BVariable.getVar(exp.cref)
          local
            list<Pointer<Variable>> children_vars;
          case Variable.VARIABLE(backendinfo = BackendInfo.BACKEND_INFO(varKind = VariableKind.RECORD(children = children_vars)))
          then list(BVariable.getVarName(var) for var in children_vars);
          else {exp.cref};
        end match;

        for child in children loop
          // check if cref has to be considered as a dependency
          stripped := ComponentRef.stripSubscriptsAll(child);
          if not BVariable.checkCref(stripped, BVariable.isParamOrConst) then
            addCrefToSet(stripped, var_crefs);
          end if;
        end for;
      then exp;

      else exp;
    end match;
  end collectPartitioningCrefs;

  function addCrefToSet
    input ComponentRef cref;
    input UnorderedSet<ComponentRef> set;
  protected
    Pointer<Variable> var_ptr = BVariable.getVarPointer(cref);
  algorithm
    // states and there derivatives belong to one partition
    // discrete states and there pre value also
    // todo: difference between pre and previous for clocked
    if BVariable.isState(var_ptr) then
      UnorderedSet.add(BVariable.getDerCref(cref), set);
    elseif BVariable.isPrevious(var_ptr) then
      UnorderedSet.add(BVariable.getPrePostCref(cref), set);
    else
      UnorderedSet.add(cref, set);
    end if;
  end addCrefToSet;

annotation(__OpenModelica_Interface="backend");
end NBPartitioning;
