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
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import Variable = NFVariable;

  // Backend
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import NBEquation.{Equation, EquationPointers};
  import Initialization = NBInitialization;
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
          // remove the when equations for initial systems
          equations := EquationPointers.mapRemovePtr(equations, Equation.isWhenEquation);
          bdae.init := list(sys for sys guard(not System.System.isEmpty(sys)) in func(systemType, variables, equations));
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
    String flag = "default"; //Flags.getConfigString(Flags.PARTITIONING)
  algorithm
    (func) := match flag
      case "default"  then (partitioningDefault);
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
  uniontype Cluster
    record CLUSTER
      list<ComponentRef> variables    "list of all variables in this set";
      list<ComponentRef> eqn_idnts    "list of all equations in this set";
    end CLUSTER;

    function toString
      input Cluster cluster;
      output String str;
    algorithm
      str := "### Cluster Variables:\n";
      for cref in cluster.variables loop
        str := str + "  " + ComponentRef.toString(cref) + "\n";
      end for;
      str := str + "### Cluster Equation Identifiers:\n";
      for cref in cluster.eqn_idnts loop
        str := str + "  " + ComponentRef.toString(cref) + "\n";
      end for;
    end toString;

    function merge
      input ClusterPointer cluster1;
      input ClusterPointer cluster2;
      input UnorderedMap<ComponentRef, ClusterPointer> map;
    protected
      Cluster c1 = Pointer.access(cluster1);
      Cluster c2 = Pointer.access(cluster2);
      Integer c1v = listLength(c1.variables);
      Integer c1e = listLength(c1.eqn_idnts);
      Integer c2v = listLength(c2.variables);
      Integer c2e = listLength(c2.eqn_idnts);
      list<ComponentRef> variables    "list of all variables in this set";
      list<ComponentRef> eqn_idnts    "list of all equations in this set";
    algorithm
      // do magic here, wait for adrian to provide dangerous list merging

      // find the smaller list to append
      if c1v > c2v then
        variables := Dangerous.listAppendDestroy(c2.variables, c1.variables);
      else
        variables := Dangerous.listAppendDestroy(c1.variables, c2.variables);
      end if;

      // find the smaller list to append
      if c1e > c2e then
        eqn_idnts := Dangerous.listAppendDestroy(c2.eqn_idnts, c1.eqn_idnts);
      else
        eqn_idnts := Dangerous.listAppendDestroy(c1.eqn_idnts, c2.eqn_idnts);
      end if;

      // find the lowest number of pointers needed to be changed
      if (c1v + c1e) > (c2v + c2e) then
        c1.variables := variables;
        c1.eqn_idnts := eqn_idnts;
        Pointer.update(cluster1, c1);
        for var in c2.variables loop
          UnorderedMap.add(var, cluster1, map);
        end for;
        for var in c2.eqn_idnts loop
          UnorderedMap.add(var, cluster1, map);
        end for;
      else
        c2.variables := variables;
        c2.eqn_idnts := eqn_idnts;
        Pointer.update(cluster2, c2);
        for var in c1.variables loop
          UnorderedMap.add(var, cluster2, map);
        end for;
        for var in c1.eqn_idnts loop
          UnorderedMap.add(var, cluster2, map);
        end for;
      end if;
    end merge;

    function getClusters
      "extracts all clusters from the unordered map and avoids duplicates by marking variables"
      input UnorderedMap<ComponentRef, ClusterPointer> map;
      input Integer size;
      output list<Cluster> clusters = {};
    protected
      UnorderedSet<ComponentRef> cref_marks = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual, size);
      list<tuple<ComponentRef, ClusterPointer>> entry_lst;
      ComponentRef cref;
      ClusterPointer cluster_ptr;
      Cluster cluster;
      Option<Pointer<Cluster>> err_cluster;
      String errStr;
    algorithm
      entry_lst := UnorderedMap.toList(map);
      for entry in entry_lst loop
        (cref, cluster_ptr) := entry;
        if not UnorderedSet.contains(cref, cref_marks) then
          cluster := Pointer.access(cluster_ptr);
          clusters := cluster :: clusters;
          for var in cluster.variables loop
            try
              UnorderedSet.addUnique(var, cref_marks);
            else
              errStr := getInstanceName()
                + " failed while trying to add the cluster for " + ComponentRef.toString(cref)
                + ", because the cluster for variable " + ComponentRef.toString(var) + " was already added.\n"
                + StringUtil.headline_4("Conflicting cluster 1 (" + ComponentRef.toString(cref) + ")")
                + Cluster.toString(cluster) + "\n"
                + StringUtil.headline_4("Conflicting cluster 2 (" + ComponentRef.toString(var) + ")");
              err_cluster := UnorderedMap.get(var, map);
              if Util.isSome(err_cluster) then
                errStr := errStr + Cluster.toString(Pointer.access(Util.getOption(err_cluster))) + "\n";
              else
                errStr := errStr + "<CLUSTER NOT FOUND>\n";
              end if;
              Error.addMessage(Error.INTERNAL_ERROR,{errStr});
              fail();
            end try;
          end for;
          for var in cluster.eqn_idnts loop
            try
              UnorderedSet.addUnique(var, cref_marks);
            else
              errStr := getInstanceName()
                + " failed while trying to add the cluster for " + ComponentRef.toString(cref)
                + ", because the cluster for variable " + ComponentRef.toString(var) + " was already added.\n"
                + StringUtil.headline_4("Conflicting cluster 1 (" + ComponentRef.toString(cref) + ")")
                + Cluster.toString(cluster) + "\n"
                + StringUtil.headline_4("Conflicting cluster 2 (" + ComponentRef.toString(var) + ")");
              err_cluster := UnorderedMap.get(var, map);
              if Util.isSome(err_cluster) then
                errStr := errStr + Cluster.toString(Pointer.access(Util.getOption(err_cluster))) + "\n";
              else
                errStr := errStr + "<CLUSTER NOT FOUND>\n";
              end if;
              Error.addMessage(Error.INTERNAL_ERROR,{errStr});
              fail();
            end try;
          end for;
        end if;
      end for;
    end getClusters;

    function toSystem
      input Cluster cluster;
      input VariablePointers variables;
      input EquationPointers equations;
      input System.SystemType systemType;
      input Pointer<array<Boolean>> marked_vars_ptr;
      input Pointer<Integer> index;
      output System.System system;
    protected
      array<Boolean> marked_vars = Pointer.access(marked_vars_ptr);
      Boolean isInit = systemType == System.SystemType.INI;
      list<Pointer<Variable>> var_lst, filtered_vars;
      list<Pointer<Equation>> eqn_lst;
      VariablePointers systVariables;
      EquationPointers systEquations;
      Integer var_idx;
    algorithm
      for cref in cluster.variables loop
        var_idx := VariablePointers.getVarIndex(variables, cref);
        if var_idx > 0 then
          marked_vars[var_idx] := false;
        end if;
      end for;
      var_lst := list(BVariable.getVarPointer(cref) for cref in cluster.variables);
      filtered_vars := list(var for var guard(VariablePointers.contains(var, variables)) in var_lst);
      eqn_lst := list(EquationPointers.getEqnByName(equations, name) for name in cluster.eqn_idnts);

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
      Pointer.update(marked_vars_ptr, marked_vars);
      Pointer.update(index, Pointer.access(index) + 1);
    end toSystem;
  end Cluster;

  // needed for unordered map
  type ClusterPointer = Pointer<Cluster>;

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
      unknowns          = if isInit then Initialization.sortInitVars(clone_vars) else clone_vars,
      daeUnknowns       = NONE(),
      equations         = if isInit then Initialization.sortInitEqns(clone_eqns) else clone_eqns,
      adjacencyMatrix   = NONE(),
      matching          = NONE(),
      strongComponents  = NONE(),
      partitionKind     = System.PartitionKind.CONTINUOUS,
      partitionIndex    = 1,
      jacobian          = NONE()
    )};
  end partitioningNone;

  function partitioningDefault extends Module.partitioningInterface;
  protected
    UnorderedMap<ComponentRef, ClusterPointer> map;
    Integer size = VariablePointers.size(variables) + EquationPointers.size(equations);
    list<Cluster> clusters;
    Pointer<array<Boolean>> marked_vars_ptr = Pointer.create(arrayCreate(VariablePointers.size(variables), true));
    list<Pointer<Variable>> single_vars, non_state_single_vars;
    Pointer<Integer> index = Pointer.create(1);
  algorithm
    // collect partitions in clusters
    map := UnorderedMap.new<ClusterPointer>(ComponentRef.hash, ComponentRef.isEqual);
    collectPartitions(equations, systemType, map);
    // extract unique clusters from the unordered map
    clusters := Cluster.getClusters(map, size);
    // create systems from clusters by filtering the variables for relevant ones
    systems := list(Cluster.toSystem(cluster, variables, equations, systemType, marked_vars_ptr, index) for cluster in clusters);

    single_vars := VariablePointers.getMarkedVars(variables, Pointer.access(marked_vars_ptr));
    if systemType <> System.SystemType.INI then
      if not listEmpty(single_vars) then
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " (" + System.System.systemTypeString(systemType)
          + ") failed because the following variables could not be assigned to a partition:\n  {"
          + stringDelimitList(list(BVariable.toString(Pointer.access(var)) for var in single_vars), ", ") + "}"});
        fail();
      end if;
    else
      (single_vars, non_state_single_vars) := List.extractOnTrue(single_vars, BVariable.isState);
      if not listEmpty(non_state_single_vars) then
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " (" + System.System.systemTypeString(systemType)
          + ") failed because the following non state variables could not be assigned to a partition:\n  {"
          + stringDelimitList(list(BVariable.toString(Pointer.access(var)) for var in non_state_single_vars), ", ") + "}"});
        fail();
      end if;
      systems := System.SYSTEM(
        systemType        = systemType,
        unknowns          = VariablePointers.fromList(single_vars),
        daeUnknowns       = NONE(),
        equations         = EquationPointers.empty(),
        adjacencyMatrix   = NONE(),
        matching          = NONE(),
        strongComponents  = NONE(),
        partitionKind     = System.PartitionKind.CONTINUOUS,
        partitionIndex    = Pointer.access(index),
        jacobian          = NONE()
      ) :: systems;
    end if;
  end partitioningDefault;

  function collectPartitions
    input EquationPointers equations;
    input System.SystemType systemType;
    input UnorderedMap<ComponentRef, ClusterPointer> map;
  algorithm
    EquationPointers.mapPtr(equations, function collectPartitionsEquation(systemType=systemType,map=map));
  end collectPartitions;

  function collectPartitionsEquation
    input Pointer<Equation> eqn;
    input System.SystemType systemType;
    input UnorderedMap<ComponentRef, ClusterPointer> map;
  protected
    ComponentRef eqCref = BVariable.getVarName(Equation.getResidualVar(eqn));
  algorithm
    _ := Equation.map(
      eq          = Pointer.access(eqn),
      funcExp     = function collectPartitionsExpression(eqCref=eqCref,systemType=systemType,map=map),
      funcCrefOpt = SOME(function collectPartitionsCref(eqCref=eqCref,systemType=systemType,map=map))
    );
  end collectPartitionsEquation;

  function collectPartitionsExpression
    input output Expression exp;
    input ComponentRef eqCref;
    input System.SystemType systemType;
    input UnorderedMap<ComponentRef, ClusterPointer> map;
  algorithm
    _ := match exp
      case Expression.CREF() guard(not ComponentRef.isTime(exp.cref)) algorithm
        _ := collectPartitionsCref(exp.cref, eqCref, systemType, map);
      then ();
      else ();
    end match;
  end collectPartitionsExpression;

  function collectPartitionsCref
    input output ComponentRef varCref;
    input ComponentRef eqCref;
    input System.SystemType systemType;
    input UnorderedMap<ComponentRef, ClusterPointer> map;
  protected
    ComponentRef stripped;
    Boolean b;
  algorithm
    stripped := ComponentRef.stripSubscriptsAll(varCref);

    b := match systemType
      case System.SystemType.ODE then BVariable.checkCref(stripped, BVariable.isParamOrConst);
      case System.SystemType.INI then BVariable.checkCref(stripped, BVariable.isConst);
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because the SystemType " + System.System.systemTypeString(systemType) + " is not yet supported."});
      then fail();
    end match;
    if not b then
      _ := match (UnorderedMap.get(eqCref, map), UnorderedMap.get(stripped, map))
        local
          ClusterPointer cluster1, cluster2;
          Cluster c;

        // neither equation nor variable already have a cluster
        case (NONE(), NONE()) algorithm
          cluster1 := Pointer.create(CLUSTER({}, {}));
          addCrefToMap(stripped, cluster1, map);
          addCrefToMap(eqCref, cluster1, map);
        then ();

        // equation does not have a cluster, but variable has one
        case (NONE(), SOME(cluster2)) algorithm
          addCrefToMap(eqCref, cluster2, map);
        then ();

        // variable does not have a cluster, but equation has one
        case (SOME(cluster1), NONE()) algorithm
          addCrefToMap(stripped, cluster1, map);
        then ();

        // both already have a different cluster
        case (SOME(cluster1), SOME(cluster2))
        guard(not referenceEq(cluster1, cluster2)) algorithm
          Cluster.merge(cluster1, cluster2, map);
        then ();

        // both already have the same cluster
        else ();
      end match;
    end if;
  end collectPartitionsCref;

  function addCrefToMap
    input ComponentRef cref;
    input ClusterPointer clusterPointer;
    input UnorderedMap<ComponentRef, ClusterPointer> map;
  protected
    Cluster cluster = Pointer.access(clusterPointer);
    Pointer<Variable> var_ptr = BVariable.getVarPointer(cref);
    ComponentRef cref2;
    Boolean addSecond = false;
  algorithm
    if BVariable.isDAEResidual(var_ptr) then
      cluster.eqn_idnts := cref :: cluster.eqn_idnts;
    elseif BVariable.isState(var_ptr) then
      cluster.variables := cref :: cluster.variables;
      cref2 := BVariable.getDerCref(cref);
      cluster.variables := cref2 :: cluster.variables;
      addSecond := true;
    elseif BVariable.isStateDerivative(var_ptr) then
      cluster.variables := cref :: cluster.variables;
      cref2 := BVariable.getStateCref(cref);
      cluster.variables := cref2 :: cluster.variables;
      addSecond := true;
    else
      cluster.variables := cref :: cluster.variables;
    end if;
    Pointer.update(clusterPointer, cluster);
    UnorderedMap.add(cref, clusterPointer, map);
    if addSecond then
      UnorderedMap.add(cref2, clusterPointer, map);
    end if;
  end addCrefToMap;

annotation(__OpenModelica_Interface="backend");
end NBPartitioning;
