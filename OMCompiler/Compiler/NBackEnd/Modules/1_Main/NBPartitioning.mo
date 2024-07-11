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
  import ClockKind = NFClockKind;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import NFFunction.Function;
  import Type = NFType;
  import Variable = NFVariable;

  // Backend
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import NBEquation.{Equation, EquationPointer, EquationPointers, EqData, EquationKind, WhenEquationBody, WhenStatement};
  import StrongComponent = NBStrongComponent;
  import Partition = NBPartition;
  import BVariable = NBVariable;
  import NBVariable.VariablePointers;

  // Util
  import MetaModelica.Dangerous;
  import DoubleEnded;
  import NBBackendUtil.Rational;
  import UnorderedMap;
  import UnorderedSet;

  // Old imports
  import OldDAE = DAE;
  import OldBackendDAE = BackendDAE;

public
  uniontype BClock
    record BASE_CLOCK
      ClockKind clock;
    end BASE_CLOCK;

    record SUB_CLOCK
      Rational factor;
      Rational shift;
      Option<String> solver;
    end SUB_CLOCK;

    function toString
      input BClock clock;
      output String str;
    algorithm
    str := match clock
      case BASE_CLOCK() then ClockKind.toDebugString(clock.clock);
      case SUB_CLOCK()  then "SUB_CLOCK(" + Rational.toString(clock.factor) + ", " + Rational.toString(clock.shift) + ")";
                        else "UNKNOWN_CLOCK()";
      end match;
    end toString;

    function hash
      input BClock clock;
      output Integer i = stringHashDjb2(toString(clock));
    end hash;

    function isEqual
      input BClock clock1;
      input BClock clock2;
      output Boolean b;
    algorithm
      b := match (clock1, clock2)
        case (BASE_CLOCK(), BASE_CLOCK()) then ClockKind.compare(clock1.clock, clock2.clock) == 0;
        case (SUB_CLOCK(), SUB_CLOCK()) then Rational.isEqual(clock1.factor, clock2.factor) and Rational.isEqual(clock1.shift, clock2.shift) and Util.optionEqual(clock1.solver, clock2.solver, stringEq);
        else false;
      end match;
    end isEqual;

    function add
      input Equation eqn;
      input ClockedInfo info;
    algorithm
      _ := match (Equation.getLHS(eqn), Equation.getRHS(eqn))
        local
          ComponentRef clock_name;
          Expression exp;

        case (Expression.CREF(cref = clock_name), exp) algorithm
          create(clock_name, exp, info);
        then ();

        case (exp, Expression.CREF(cref = clock_name)) algorithm
          create(clock_name, exp, info);
        then ();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for:\n" + Equation.toString(eqn)});
          fail();
        then fail();
      end match;
    end add;

    function isBaseClock
      input BClock clock;
      output Boolean b;
    algorithm
      b := match clock case BASE_CLOCK() then true; else false; end match;
    end isBaseClock;

    function convertBase
      input BClock clock;
      output OldDAE.ClockKind oldClock;
    algorithm
      oldClock := match clock
        case BASE_CLOCK() then ClockKind.toDAE(clock.clock);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for non-base clock: " + toString(clock)});
        then fail();
      end match;
    end convertBase;

    function convertSub
      input BClock clock;
      output OldBackendDAE.SubClock oldClock;
    algorithm
      oldClock := match clock
        case SUB_CLOCK() then OldBackendDAE.SUBCLOCK(
          factor  = Rational.convert(clock.factor),
          shift   = Rational.convert(clock.shift),
          solver  = clock.solver);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for non-sub clock: " + toString(clock)});
        then fail();
      end match;
    end convertSub;

  protected
    function create
      input ComponentRef clock_name;
      input Expression exp;
      input ClockedInfo info;
    protected
      BClock clock;
      Option<ComponentRef> baseClock;
    algorithm
      try
        // parse the clock and see if it depends on another clock
        (clock, baseClock) := fromExp(exp);
        if Util.isSome(baseClock) then
          // sub clock
          UnorderedMap.add(clock_name, clock, info.subClocks);
          UnorderedMap.add(clock_name, Util.getOption(baseClock), info.subToBase);
        else
          // base clock
          UnorderedMap.add(clock_name, clock, info.baseClocks);
        end if;
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(clock_name) + "."});
        fail();
      end try;
    end create;

    function fromExp
      input Expression exp;
      output BClock subClock;
      output Option<ComponentRef> baseClock;
    algorithm
      (subClock, baseClock) := match exp
        local
          ComponentRef cref;
          Call call;

        case Expression.CLKCONST() algorithm
        then (BASE_CLOCK(exp.clk), NONE());

        case Expression.CREF(cref = cref)
        then (DEFAULT_SUB_CLOCK, SOME(cref));

        case Expression.CALL(call = call as Call.TYPED_CALL()) algorithm
          (baseClock, subClock) := match (AbsynUtil.pathString(Function.nameConsiderBuiltin(call.fn)), Call.arguments(call))
            local
              Expression e;
              Integer i1, i2;

            // subclock: subset sampling
            case ("subSample", {e, Expression.INTEGER(i1)}) algorithm
              (subClock, baseClock) := fromExp(e);
              subClock := updateSubClock(subClock, SUB_CLOCK(Rational.RATIONAL(i1, 1), Rational.RATIONAL(0, 1), NONE()));
            then (baseClock, subClock);

            // subclock: super sampling
            case ("superSample", {e, Expression.INTEGER(i1)}) algorithm
              (subClock, baseClock) := fromExp(e);
              subClock := updateSubClock(subClock, SUB_CLOCK(Rational.RATIONAL(1, i1), Rational.RATIONAL(0, 1), NONE()));
            then (baseClock, subClock);

            // subclock: shift sampling (default 3rd argument = 1)
            case ("shiftSample", {e, Expression.INTEGER(i1)}) algorithm
              (subClock, baseClock) := fromExp(e);
              subClock := updateSubClock(subClock, SUB_CLOCK(Rational.RATIONAL(1, 1), Rational.RATIONAL(i1, 1), NONE()));
            then (baseClock, subClock);

            // subclock: shift sampling
            case ("shiftSample", {e, Expression.INTEGER(i1), Expression.INTEGER(i2)}) algorithm
              (subClock, baseClock) := fromExp(e);
              subClock := updateSubClock(subClock, SUB_CLOCK(Rational.RATIONAL(1, 1), Rational.RATIONAL(i1, i2), NONE()));
            then (baseClock, subClock);

            // subclock: back sampling (default 3rd argument = 1)
            case ("backSample", {e, Expression.INTEGER(i1)}) algorithm
              (subClock, baseClock) := fromExp(e);
              subClock := updateSubClock(subClock, SUB_CLOCK(Rational.RATIONAL(1, 1), Rational.RATIONAL(-i1, 1), NONE()));
            then (baseClock, subClock);

            // subclock: back sampling
            case ("backSample", {e, Expression.INTEGER(i1), Expression.INTEGER(i2)}) algorithm
              (subClock, baseClock) := fromExp(e);
              subClock := updateSubClock(subClock, SUB_CLOCK(Rational.RATIONAL(1, 1), Rational.RATIONAL(-i1, i2), NONE()));
            then (baseClock, subClock);

            else algorithm
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for exp with unhandled call: " + Expression.toString(exp) + "."});
            then fail();
          end match;
        then (subClock, baseClock);

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for exp with unhandled expression kind: " + Expression.toString(exp) + "."});
        then fail();
      end match;
    end fromExp;

    function updateSubClock
      "adding the sub clock src to the sub clock dest. not symmetrical/commutative"
      input output BClock dest;
      input BClock src;
    algorithm
      dest := match (dest, src)
        case (SUB_CLOCK(), SUB_CLOCK()) algorithm
          dest.shift  := Rational.add(dest.shift, Rational.multiply(src.shift, dest.factor));
          dest.factor := Rational.multiply(dest.factor, src.factor);
        then dest;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + toString(dest) + " and " + toString(src) + " because of incorrect clock types."});
        then fail();
      end match;
    end updateSubClock;
  end BClock;

  constant BClock DEFAULT_SUB_CLOCK = SUB_CLOCK(Rational.RATIONAL(1, 1), Rational.RATIONAL(0, 1), NONE());
  type CrefLst = list<ComponentRef>;

  uniontype ClockedInfo
    record CLOCKED_INFO
      UnorderedMap<ComponentRef, BClock> baseClocks;
      UnorderedMap<ComponentRef, BClock> subClocks;
      UnorderedMap<ComponentRef, ComponentRef> subToBase;
      UnorderedMap<ComponentRef, CrefLst> baseToSub;
    end CLOCKED_INFO;

    function new
      output ClockedInfo info = CLOCKED_INFO(
        baseClocks  = UnorderedMap.new<BClock>(ComponentRef.hash, ComponentRef.isEqual),
        subClocks   = UnorderedMap.new<BClock>(ComponentRef.hash, ComponentRef.isEqual),
        subToBase   = UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual),
        baseToSub   = UnorderedMap.new<CrefLst>(ComponentRef.hash, ComponentRef.isEqual));
    end new;

    function toString
      input ClockedInfo info;
      output String str = "";
    algorithm
      if not isEmpty(info) then
        str := StringUtil.headline_2("Clocked Info") + "\n";
        str := str + StringUtil.headline_3("Base Clocks") + UnorderedMap.toString(info.baseClocks, ComponentRef.toString, BClock.toString) + "\n\n";
        str := str + StringUtil.headline_3("Sub Clocks") + UnorderedMap.toString(info.subClocks, ComponentRef.toString, BClock.toString) + "\n\n";
        str := str + StringUtil.headline_3("Sub to Base Clocks") + UnorderedMap.toString(info.subToBase, ComponentRef.toString, ComponentRef.toString) + "\n\n";
        str := str + StringUtil.headline_3("Base to Sub Clocks") + UnorderedMap.toString(info.baseToSub, ComponentRef.toString, ComponentRef.listToString) + "\n";
      end if;
    end toString;

    function isEmpty
      input ClockedInfo info;
      output Boolean b = UnorderedMap.isEmpty(info.baseClocks);
    end isEmpty;

    function resolveSubClocks
      input ClockedInfo info;
    algorithm
      // update sub to base clock
      for sub_clock in UnorderedMap.keyList(info.subClocks) loop
        resolveSubClock(sub_clock, info);
      end for;
      // update base to sub clocks
      for sub_clock in UnorderedMap.keyList(info.subClocks) loop
        addSubClock(sub_clock, info);
      end for;
    end resolveSubClocks;

  protected
    function resolveSubClock
      input ComponentRef clock_name;
      input ClockedInfo info;
      output ComponentRef base_clock;
    protected
      ComponentRef parent_clock = UnorderedMap.getSafe(clock_name, info.subToBase, sourceInfo());
      BClock dest, src;
    algorithm
      if not UnorderedMap.contains(parent_clock, info.baseClocks) then
        // not a base, update necessary
        base_clock := resolveSubClock(parent_clock, info);
        // update the sub clock and add the new base clock
        dest  := UnorderedMap.getSafe(parent_clock, info.subClocks, sourceInfo());
        src   := UnorderedMap.getSafe(clock_name, info.subClocks, sourceInfo());
        UnorderedMap.add(clock_name, BClock.updateSubClock(dest, src), info.subClocks);
        UnorderedMap.add(clock_name, base_clock, info.subToBase);
      else
        base_clock := parent_clock;
      end if;
    end resolveSubClock;

    function addSubClock
      input ComponentRef clock_name;
      input ClockedInfo info;
    protected
      ComponentRef base_clock = UnorderedMap.getSafe(clock_name, info.subToBase, sourceInfo());
      List<ComponentRef> current_clocks;
    algorithm
      current_clocks := UnorderedMap.getOrDefault(base_clock, info.baseToSub, {});
      UnorderedMap.add(base_clock, clock_name :: current_clocks, info.baseToSub);
    end addSubClock;
  end ClockedInfo;

// =========================================================================
//                      MAIN ROUTINE, PLEASE DO NOT CHANGE
// =========================================================================
  function main
    "Wrapper function for any partitioning function. This will be
     called during simulation and gets the corresponding subfunction from
     Config."
    extends Module.wrapper;
    input Partition.Kind kind;
  protected
    Module.partitioningInterface func;
  algorithm
    func := getModule();

    bdae := match (kind, bdae)
      local
        VariablePointers variables, clocks;
        EquationPointers equations, clocked;

      case (NBPartition.Kind.ODE, BackendDAE.MAIN(
        varData = BVariable.VAR_DATA_SIM(unknowns = variables, clocks = clocks),
        eqData = BEquation.EQ_DATA_SIM(simulation = equations, clocked = clocked)))
      algorithm
        bdae.ode := func(kind, variables, equations, clocks, clocked, bdae.clockedInfo);
        bdae.ode := list(sys for sys guard(not Partition.Partition.isEmpty(sys)) in bdae.ode);
      then bdae;

      case (NBPartition.Kind.INI, BackendDAE.MAIN(
        varData = BVariable.VAR_DATA_SIM(initials = variables, clocks = clocks),
        eqData = BEquation.EQ_DATA_SIM(initials = equations, clocked = clocked)))
      algorithm
        bdae.init := partitioningNone(kind, variables, equations, clocks, clocked, bdae.clockedInfo);
        bdae.init := list(sys for sys guard(not Partition.Partition.isEmpty(sys)) in bdae.init);
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
    "creates ODE, ALG, ODE_EVT, ALG_EVT partitions from ODE by checking
    if it contains discrete equations or state equations.
    Should be evoked just before jacobian at the very end."
    extends Module.wrapper;
  algorithm
    bdae := match bdae
      local
        DoubleEnded.MutableList<Partition.Partition> ode = DoubleEnded.MutableList.fromList({});
        DoubleEnded.MutableList<Partition.Partition> alg = DoubleEnded.MutableList.fromList({});
        DoubleEnded.MutableList<Partition.Partition> ode_evt = DoubleEnded.MutableList.fromList({});
        DoubleEnded.MutableList<Partition.Partition> alg_evt = DoubleEnded.MutableList.fromList({});
        DoubleEnded.MutableList<Partition.Partition> clocked = DoubleEnded.MutableList.fromList({});

      case BackendDAE.MAIN() algorithm
        for syst in bdae.ode loop
          Partition.Partition.categorize(syst, ode, alg, ode_evt, alg_evt, clocked);
        end for;
        bdae.ode := DoubleEnded.MutableList.toListAndClear(ode);
        bdae.algebraic := DoubleEnded.MutableList.toListAndClear(alg);
        bdae.ode_event := DoubleEnded.MutableList.toListAndClear(ode_evt);
        bdae.alg_event := DoubleEnded.MutableList.toListAndClear(alg_evt);
        bdae.clocked := DoubleEnded.MutableList.toListAndClear(clocked);
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

    function toPartition
      input Cluster cluster;
      input VariablePointers variables;
      input EquationPointers equations;
      input Partition.Kind kind;
      input ClockedInfo info;
      input Pointer<Integer> index;
      output Partition.Partition partition;
    protected
      list<ComponentRef> cvars = UnorderedSet.toList(cluster.variables);
      list<ComponentRef> cidnt = UnorderedSet.toList(cluster.eqn_idnts);
      Boolean isInit = kind == NBPartition.Kind.INI;
      Partition.Association association;
      list<Pointer<Variable>> var_lst, filtered_vars;
      list<Pointer<Equation>> eqn_lst;
      VariablePointers partVariables;
      EquationPointers partEquations;
      Integer var_idx, clock_idx = Pointer.access(index);
    algorithm
      // find all variables and equations
      var_lst := list(BVariable.getVarPointer(cref) for cref in cvars);
      filtered_vars := list(var for var guard(VariablePointers.contains(var, variables)) in var_lst);
      eqn_lst := list(EquationPointers.getEqnByName(equations, name) for name in cidnt);

      // create variable and equation arrays
      partVariables := VariablePointers.fromList(filtered_vars);
      partEquations := EquationPointers.fromList(eqn_lst);

      // create the association (clocked/continuous)
      association := Partition.Association.create(partEquations, kind, info);

      // replace the clocked functions, inline clocked when equations and set equations to clocked
      if Partition.Association.isClocked(association) then
        partEquations := EquationPointers.mapExp(partEquations, replaceClockedFunctions);
        partEquations := EquationPointers.map(partEquations, replaceClockedWhen);
        partEquations := EquationPointers.map(partEquations, function Equation.setKind(kind = EquationKind.CLOCKED, clock_idx = SOME(clock_idx)));
        partVariables := VariablePointers.mapPtr(partVariables, function BVariable.setVarKind(varKind = VariableKind.CLOCKED()));
      end if;

      partition := Partition.PARTITION(
        index             = clock_idx,
        association       = association,
        unknowns          = partVariables,
        daeUnknowns       = NONE(),
        equations         = partEquations,
        adjacencyMatrix   = NONE(),
        matching          = NONE(),
        strongComponents  = NONE()
      );
      Pointer.update(index, Pointer.access(index) + 1);
    end toPartition;
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
    Boolean isInit = kind == NBPartition.Kind.INI;
    VariablePointers clone_vars;
    EquationPointers clone_eqns;
  algorithm
    clone_vars := VariablePointers.clone(variables);
    clone_eqns := EquationPointers.clone(equations);
    partitions := {Partition.PARTITION(
      index             = 1,
      association       = Partition.Association.CONTINUOUS(kind, NONE()),
      unknowns          = clone_vars,
      daeUnknowns       = NONE(),
      equations         = clone_eqns,
      adjacencyMatrix   = NONE(),
      matching          = NONE(),
      strongComponents  = NONE()
    )};
  end partitioningNone;

  function partitioningClocked
    "partitions all individual partitions and collects the clocked partitions and clocks/subclocks"
    extends Module.partitioningInterface;
  protected
    DisjointSetForest eqn_dsf = DisjointSetForest.new(equations.eqArr.lastUsedIndex[1]);
    array<Integer> var_map = arrayCreate(variables.varArr.lastUsedIndex[1], -1);
    Pointer<Equation> eqn;
    Pointer<Variable> var;
    UnorderedSet<ComponentRef> var_crefs;
    list<Integer> var_indices;
    Integer part_idx;
    UnorderedMap<Integer, Cluster> cluster_map = UnorderedMap.new<Cluster>(Util.id, intEq);
    ComponentRef name_cref;
    Pointer<Integer> index = Pointer.create(1);
    array<Boolean> marked_vars;
    list<Pointer<Variable>> single_vars;
    list<Pointer<Equation>> clocked_eqns = {};
  algorithm
    // parse clock assignments
    for eq_idx in UnorderedMap.valueList(clocked.map) loop
      if eq_idx > 0 then
        eqn := EquationPointers.getEqnAt(clocked, eq_idx);
        BClock.add(Pointer.access(eqn), info);
        clocked_eqns := eqn :: clocked_eqns;
      end if;
    end for;

    // resolve inner sub clock dependencies
    ClockedInfo.resolveSubClocks(info);

    // non clock assignment equations - collect all variables
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

    // find and report variables that could not be assigned to a partition (exclude clocks)
    marked_vars := listArray(list(var_map[var_idx] < 0 for var_idx in UnorderedMap.valueList(variables.map)));
    single_vars := list(var_ptr for var_ptr in VariablePointers.getMarkedVars(variables, marked_vars));

    if not listEmpty(single_vars) then
      Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " (" + Partition.Partition.kindToString(kind)
        + ") failed because the following variables could not be assigned to a partition:\n  {"
        + stringDelimitList(list(BVariable.toString(Pointer.access(var_ptr)) for var_ptr in single_vars), "\n") + "}"});
      fail();
    end if;

    // collect clusters excluding clocked stuff (not considered unknowns)
    for eq_idx in UnorderedMap.valueList(equations.map) loop
      if eq_idx > 0 then
        eqn := EquationPointers.getEqnAt(equations, eq_idx);
        name_cref := Equation.getEqnName(eqn);
        UnorderedMap.addUpdate(DisjointSetForest.find(eqn_dsf, eq_idx), function Cluster.addElement(cref = name_cref, ty = ClusterElementType.EQUATION), cluster_map);
      end if;
    end for;

    for var_idx in UnorderedMap.valueList(variables.map) loop
      if var_idx > 0 then
        var := VariablePointers.getVarAt(variables, var_idx);
        name_cref := BVariable.getVarName(var);
        UnorderedMap.addUpdate(DisjointSetForest.find(eqn_dsf, var_map[var_idx]), function Cluster.addElement(cref = name_cref, ty = ClusterElementType.VARIABLE), cluster_map);
      end if;
    end for;

    partitions := list(Cluster.toPartition(cl, variables, equations, kind, info, index) for cl in UnorderedMap.valueList(cluster_map));

    if Flags.isSet(Flags.DUMP_SYNCHRONOUS) then
      print(StringUtil.headline_1("[dumpSynchronous] Partitioning result:") + "\n" + List.toString(partitions, function Partition.Partition.toString(level = 0), "", "", "\n", "\n"));
      print(ClockedInfo.toString(info));
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
            arg := match Call.arguments(exp.call)
              // not collected samples have 2 arguments
              case {_, arg} then arg;
              // collected samples have 3 arguments
              case {_, _, arg} then arg;
              else algorithm
                Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp) + "."});
              then fail();
            end match;
            _ := collectPartitioningCrefs(arg, var_crefs);
          then Expression.EMPTY(Type.INTEGER());
          else exp;
        end match;
      then newExp;

      // get all variable crefs for this cref and add to set
      case Expression.CREF() guard(not BVariable.isClock(BVariable.getVarPointer(exp.cref))) algorithm
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

  function replaceClockedFunctions
    "replaces sample() calls using clocks as condition with the $getPart function"
    input output Expression exp;
  algorithm
    exp := match exp
      local
        Expression newExp, arg;
        Function func;
        Call call;

      case Expression.CALL(call = call as Call.TYPED_CALL()) algorithm
        newExp := match AbsynUtil.pathString(Function.nameConsiderBuiltin(call.fn))
          case "sample" algorithm
            arg := match Call.arguments(exp.call)
              // not collected samples have 2 arguments
              case {arg, _} then arg;
              // collected samples have 3 arguments
              case {_, arg, _} then arg;
              else algorithm
                Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp) + "."});
              then fail();
            end match;
            func := match Expression.typeOf(arg)
              case Type.REAL()    then NFBuiltinFuncs.GET_PART_REAL;
              case Type.INTEGER() then NFBuiltinFuncs.GET_PART_INT;
              case Type.BOOLEAN() then NFBuiltinFuncs.GET_PART_BOOL;
              else algorithm
                Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. " + Expression.toString(arg) + " is not of correct type."});
              then fail();
            end match;
            newExp := Expression.CALL(Call.makeTypedCall(
              fn          = func,
              args        = {arg},
              variability = Expression.variability(arg),
              purity      = NFPrefixes.Purity.PURE
            ));
          then newExp;
          else exp;
        end match;
      then newExp;
      else exp;
    end match;
  end replaceClockedFunctions;

  function replaceClockedWhen
    "replace clocked when equations in clocked partitions with their body statement.
    only works for split up when equations with a single statement and no else when."
    input output Equation eqn;
  algorithm
    eqn := match eqn
      local
        Expression cond;
        WhenStatement stmt;

      case Equation.WHEN_EQUATION(body = WhenEquationBody.WHEN_EQUATION_BODY(condition = cond, when_stmts = {stmt}, else_when = NONE()))
        guard(Type.isClock(Expression.typeOf(cond)))
      then WhenStatement.toEquation(stmt, eqn.attr, false);

      else eqn;
    end match;
  end replaceClockedWhen;

annotation(__OpenModelica_Interface="backend");
end NBPartitioning;
