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

        case (SOME(Expression.CREF(cref = clock_name)), SOME(exp))
        guard(Expression.isClockOrSampleFunction(exp)) algorithm
          create(clock_name, exp, info);
        then ();

        case (SOME(exp), SOME(Expression.CREF(cref = clock_name)))
        guard(Expression.isClockOrSampleFunction(exp)) algorithm
          create(clock_name, exp, info);
        then ();

        else ();
      end match;
    end add;

    function isBaseClock
      input BClock clock;
      output Boolean b;
    algorithm
      b := match clock case BASE_CLOCK() then true; else false; end match;
    end isBaseClock;

    function isEventClock
      input BClock clock;
      output Boolean b;
    algorithm
      b := match clock case BASE_CLOCK(clock = ClockKind.EVENT_CLOCK()) then true; else false; end match;
    end isEventClock;

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

    function toExp
      input BClock clock;
      output Expression exp;
    algorithm
      exp := match clock
        case BASE_CLOCK() then Expression.CLKCONST(clock.clock);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for non-base clock: " + toString(clock)});
        then fail();
      end match;
    end toExp;

  protected
    function create
      input ComponentRef clock_name;
      input Expression exp;
      input ClockedInfo info;
    protected
      BClock clock;
      Option<ComponentRef> baseClock;
      Pointer<Variable> clock_var;
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

        // if this is from the equation block and not from variable binding, the variable needs to updated
        // such that the clock can be found for the partitioning clocked association
        clock_var := BVariable.getVarPointer(clock_name, sourceInfo());
        if not BVariable.isClockOrClocked(clock_var) then
          BVariable.setVarKind(clock_var, VariableKind.CLOCKED());
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
          Call call;

        case Expression.CLKCONST() algorithm
        then (BASE_CLOCK(exp.clk), NONE());

        case Expression.CREF() algorithm
        then (DEFAULT_SUB_CLOCK, SOME(exp.cref));


        case Expression.CALL(call = call as Call.TYPED_CALL()) algorithm
          (baseClock, subClock) := match (AbsynUtil.pathString(Function.nameConsiderBuiltin(call.fn)), Call.arguments(call))
            local
              Expression e;
              Integer i1, i2;

            // sample: default subclock sampling
            case ("sample", {_, e}) algorithm
              (subClock, baseClock) := fromExp(e);
            then (baseClock, subClock);

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
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
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
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
      then fail();
    end match;
  end categorize;

  function extractClocks
    "replace clock constructors in expressions with variables"
    input output Expression exp;
    input UnorderedMap<BClock, ComponentRef> collector;
    input Pointer<list<Pointer<Variable>>> new_clocks;
    input Pointer<Integer> idx;
  algorithm
    exp := match exp
      local
        BClock clock;
        Pointer<Variable> clock_var;
        ComponentRef clock_name;

      case Expression.CLKCONST() guard(not ClockKind.isInferred(exp.clk)) algorithm
        clock := BClock.BASE_CLOCK(exp.clk);
        if UnorderedMap.contains(clock, collector) then
          clock_name := UnorderedMap.getSafe(clock, collector, sourceInfo());
        else
          (clock_var, clock_name) := BVariable.makeClockVar(Pointer.access(idx), Expression.typeOf(exp));
          UnorderedMap.add(clock, clock_name, collector);
          Pointer.update(new_clocks, clock_var :: Pointer.access(new_clocks));
          Pointer.update(idx, Pointer.access(idx) + 1);
        end if;
      then Expression.fromCref(clock_name);

      else exp;
    end match;
  end extractClocks;

protected
  type ClusterElementType = enumeration(EQUATION, VARIABLE);

  uniontype Cluster
    record CLUSTER
      UnorderedSet<ComponentRef> variables  "set of all variables in this cluster";
      UnorderedSet<ComponentRef> eqn_idnts  "set of all equations in this cluster";
    end CLUSTER;

    function toString
      input Cluster cluster;
      output String str;
    algorithm
      str := "### Cluster Variables:\n" + UnorderedSet.toString(cluster.variables, ComponentRef.toString)
        + "\n### Cluster Equation Identifiers:\n" + UnorderedSet.toString(cluster.eqn_idnts, ComponentRef.toString);
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
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed for " + ComponentRef.toString(cref) + " because of unknown cluster element type."});
        then fail();
      end match;
    end addElement;

    function toPartition
      input Cluster cluster;
      input VariablePointers variables;
      input EquationPointers equations;
      input Partition.Kind kind;
      input ClockedInfo info;
      input UnorderedSet<ComponentRef> held_crefs;
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
      var_lst := list(BVariable.getVarPointer(cref, sourceInfo()) for cref in cvars);
      filtered_vars := list(var for var guard(VariablePointers.contains(var, variables)) in var_lst);
      eqn_lst := list(EquationPointers.getEqnByName(equations, name) for name in cidnt);

      // create variable and equation arrays
      partVariables := VariablePointers.fromList(filtered_vars);
      partEquations := EquationPointers.fromList(eqn_lst);

      // create the association (clocked/continuous)
      association := Partition.Association.create(partEquations, kind, info);

      // replace the clocked functions, inline clocked when equations and set equations to clocked
      partEquations := EquationPointers.mapExp(partEquations, function replaceClockedFunctions(held_crefs = held_crefs));
      if Partition.Association.isClocked(association) then
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
    DisjointSetForest eqn_dsf = DisjointSetForest.new(ExpandableArray.getLastUsedIndex(equations.eqArr));
    array<Integer> var_map = arrayCreate(ExpandableArray.getLastUsedIndex(variables.varArr), -1);
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
    UnorderedSet<ComponentRef> held_crefs = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
  algorithm
    // parse clock assignments
    for eq_idx in UnorderedMap.valueList(clocked.map) loop
      if eq_idx > 0 then
        eqn := EquationPointers.getEqnAt(clocked, eq_idx);
        BClock.add(Pointer.access(eqn), info);
      end if;
    end for;

    // other equations - collect all variables and check for clocked signals
    for eq_idx in UnorderedMap.valueList(equations.map) loop
      if eq_idx > 0 then
        eqn := EquationPointers.getEqnAt(equations, eq_idx);
        BClock.add(Pointer.access(eqn), info);

        // collect all crefs in equation
        var_crefs := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
        Equation.map(Pointer.access(eqn), function collectPartitioningCrefs(var_crefs = var_crefs), NONE(), Expression.fakeMap);

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

    // resolve inner sub clock dependencies
    ClockedInfo.resolveSubClocks(info);

    // find and report variables that could not be assigned to a partition (exclude clocks)
    marked_vars := listArray(list(var_map[var_idx] < 0 for var_idx in UnorderedMap.valueList(variables.map)));
    single_vars := list(var_ptr for var_ptr in VariablePointers.getMarkedVars(variables, marked_vars));

    if not listEmpty(single_vars) then
      Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " (" + Partition.Partition.kindToString(kind)
        + ") failed because the following variables could not be assigned to a partition:\n  {"
        + stringDelimitList(list(BVariable.toString(Pointer.access(var_ptr)) for var_ptr in single_vars), "\n") + "}"});
      fail();
    end if;

    // collect cluster equations
    for eq_idx in UnorderedMap.valueList(equations.map) loop
      if eq_idx > 0 then
        // add the equation
        eqn       := EquationPointers.getEqnAt(equations, eq_idx);
        name_cref := Equation.getEqnName(eqn);
        part_idx  := DisjointSetForest.find(eqn_dsf, eq_idx);
        UnorderedMap.addUpdate(part_idx, function Cluster.addElement(cref = name_cref, ty = ClusterElementType.EQUATION), cluster_map);
      end if;
    end for;

    // collect cluster variables
    for var_idx in UnorderedMap.valueList(variables.map) loop
      if var_idx > 0 then
        var       := VariablePointers.getVarAt(variables, var_idx);
        name_cref := BVariable.getVarName(var);
        part_idx  := DisjointSetForest.find(eqn_dsf, var_map[var_idx]);
        UnorderedMap.addUpdate(part_idx, function Cluster.addElement(cref = name_cref, ty = ClusterElementType.VARIABLE), cluster_map);
      end if;
    end for;

    // get the actual partitions from the clusters and split continuous/clocked
    partitions := list(Cluster.toPartition(cl, variables, equations, kind, info, held_crefs, index) for cl in UnorderedMap.valueList(cluster_map));
    // update the partitions if one of their variables is in a hold() function
    partitions := list(Partition.Partition.updateHeldVars(part, held_crefs) for part in partitions);

    if Flags.isSet(Flags.DUMP_SYNCHRONOUS) then
      print(StringUtil.headline_1("[dumpSynchronous] Partitioning result:") + "\n" + List.toString(partitions, function Partition.Partition.toString(level = 2), "", "", "\n", "\n"));
      print(ClockedInfo.toString(info));
    end if;
  end partitioningClocked;

  public function collectPartitioningClockDependencies
    "clock dependencies are only relevant for sub clocks to the same base clock.
    used in sim code after merging equally clocked partitions.
    needs the $getPart replacement beforhand to work properly"
    input output Expression exp;
    input UnorderedMap<ComponentRef, BClock> clock_map  "only for sub clocks";
    input UnorderedSet<BClock> clock_deps               "found dependencies";
  algorithm
    exp := match exp
      local
        Call call;
        ComponentRef arg;

      // collect clocked dependencies from sub sampling
      case Expression.CALL(call = call as Call.TYPED_CALL(arguments = {Expression.CREF(cref = arg)}))
        guard("$getPart"  == AbsynUtil.pathString(Function.nameConsiderBuiltin(call.fn))) algorithm
        // ToDo: maybe need to strip subscripts and all that
        if UnorderedMap.contains(arg, clock_map) then
          UnorderedSet.add(UnorderedMap.getSafe(arg, clock_map, sourceInfo()), clock_deps);
        else
          Expression.mapShallow(exp, function collectPartitioningClockDependencies(clock_map = clock_map, clock_deps = clock_deps));
        end if;
      then exp;

      else Expression.mapShallow(exp, function collectPartitioningClockDependencies(clock_map = clock_map, clock_deps = clock_deps));
    end match;
  end collectPartitioningClockDependencies;

  protected function collectPartitioningCrefs
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
          // skip these as they do not cause dependency
          case "subSample"    then exp;
          case "superSample"  then exp;
          case "shiftSample"  then exp;
          case "backSample"   then exp;
          case "previous"     then exp;
          case "hold"         then exp;
          // sample can have dependencies
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
          then Expression.mapShallow(arg, function collectPartitioningCrefs(var_crefs = var_crefs));
          else Expression.mapShallow(exp, function collectPartitioningCrefs(var_crefs = var_crefs));
        end match;
      then newExp;

      // get all variable crefs for this cref and add to set
      case Expression.CREF() guard(not BVariable.isClock(BVariable.getVarPointer(exp.cref, sourceInfo()))) algorithm
        // extract potential record children
        children := match BVariable.getVar(exp.cref, sourceInfo())
          local
            list<Pointer<Variable>> children_vars;
          case Variable.VARIABLE(backendinfo = BackendInfo.BACKEND_INFO(varKind = VariableKind.RECORD(children = children_vars)))
          then list(BVariable.getVarName(var) for var in children_vars);
          else {exp.cref};
        end match;

        for child in children loop
          // check if cref has to be considered as a dependency
          stripped := ComponentRef.stripSubscriptsAll(child);
          if not BVariable.checkCref(stripped, BVariable.isParamOrConst, sourceInfo()) then
            addCrefToSet(stripped, var_crefs);
          end if;
        end for;
      then exp;

      else Expression.mapShallow(exp, function collectPartitioningCrefs(var_crefs = var_crefs));
    end match;
  end collectPartitioningCrefs;

  function addCrefToSet
    input ComponentRef cref;
    input UnorderedSet<ComponentRef> set;
  protected
    Pointer<Variable> var_ptr = BVariable.getVarPointer(cref, sourceInfo());
  algorithm
    // states and there derivatives belong to one partition
    // discrete states and there pre value also
    if BVariable.isState(var_ptr) then
      UnorderedSet.add(BVariable.getPartnerCref(cref, BVariable.getVarDer), set);
    elseif BVariable.isPrevious(var_ptr) then
      UnorderedSet.add(BVariable.getPartnerCref(cref, BVariable.getVarPre), set);
    else
      UnorderedSet.add(cref, set);
    end if;
  end addCrefToSet;

  function replaceClockedFunctions
    "replaces sample() and hold() calls using clocks as condition with the $getPart function"
    input output Expression exp;
    input UnorderedSet<ComponentRef> held_crefs;
    function replaceSample
      input output Expression exp;
      input Call call;
      input Boolean basic;
    protected
      Expression arg, arg1, arg2;
    algorithm
      {arg1, arg2} := match Call.arguments(call)
        // not collected samples have 2 arguments
        case {arg1, arg2} then {arg1, arg2};
        // collected samples have 3 arguments
        case {_, arg1, arg2} guard(basic) then {arg1, arg2};
        // non basic with 3 arguments only care for the first argument as signal
        case {arg1, arg2, _} then {arg1, arg2};
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp) + "."});
        then fail();
      end match;
      // if it's the basic sample operator, the second argument is supposed to be the clock, otherwise the first
      if basic then
        exp := if Type.isClock(Expression.typeOf(arg2)) then replaceClockedFunctionExp(arg1) else exp;
      else
        exp := replaceClockedFunctionExp(arg1);
      end if;
    end replaceSample;
  algorithm
    exp := match exp
      local
        Expression newExp, arg, arg2;
        Call call;

      case Expression.CALL(call = call as Call.TYPED_CALL()) algorithm
        newExp := match AbsynUtil.pathString(Function.nameConsiderBuiltin(call.fn))
          // sample cases
          case "sample"       then replaceSample(exp, call, true);
          case "subSample"    then replaceSample(exp, call, false);
          case "superSample"  then replaceSample(exp, call, false);
          case "shiftSample"  then replaceSample(exp, call, false);
          case "backSample"   then replaceSample(exp, call, false);

          // hold case
          case "hold" algorithm
            arg := match Call.arguments(exp.call)
              // hold can only have one argument
              case {arg as Expression.CREF()} algorithm
                UnorderedSet.add(arg.cref, held_crefs);
              then arg;
              else algorithm
                Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp) + "."});
              then fail();
            end match;
          then replaceClockedFunctionExp(arg);

          else exp;
        end match;
      then newExp;
      else exp;
    end match;
  end replaceClockedFunctions;

  function replaceClockedFunctionExp
    input output Expression exp;
  protected
    Function func;
  algorithm
    func := match Expression.typeOf(exp)
      case Type.REAL()    then NFBuiltinFuncs.GET_PART_REAL;
      case Type.INTEGER() then NFBuiltinFuncs.GET_PART_INT;
      case Type.BOOLEAN() then NFBuiltinFuncs.GET_PART_BOOL;
      case Type.CLOCK()   then NFBuiltinFuncs.GET_PART_CLOCK;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. " + Expression.toString(exp) + " is of type "
         + Type.toString(Expression.typeOf(exp)) + ", only real, integer, boolean and clock are allowed."});
      then fail();
    end match;
    exp := Expression.CALL(Call.makeTypedCall(
      fn          = func,
      args        = {exp},
      variability = Expression.variability(exp),
      purity      = NFPrefixes.Purity.PURE
    ));
  end replaceClockedFunctionExp;

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
