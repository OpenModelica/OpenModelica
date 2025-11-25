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
encapsulated package NBPartition
"file:        NBPartition.mo
 package:     NBPartition
 description: This file contains the data-types used to process individual
              partitions of equations.
"

public
  import Adjacency = NBAdjacency;
  import Matching = NBMatching;
  import StrongComponent = NBStrongComponent;

protected
  // NF imports
  import Call = NFCall;
  import ClockKind = NFClockKind;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import Type = NFType;
  import Variable = NFVariable;

  // Backend Imports
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import NBEquation.{Equation, EquationKind, WhenEquationBody, WhenStatement};
  import BJacobian = NBJacobian;
  import NBEquation.EquationPointers;
  import NBPartitioning.{BClock, ClockedInfo};
  import Jacobian = NBackendDAE.BackendDAE;
  import BVariable = NBVariable;
  import NBVariable.VariablePointers;

  // Util imports
  import DoubleEnded;
  import StringUtil;

public
  type Kind = enumeration(ODE, ALG, ODE_EVT, ALG_EVT, INI, DAE, JAC, CLK);

  uniontype Association
    record CONTINUOUS
      Kind kind;
      Option<Jacobian> jacobian "Analytic jacobian for the integrator";
    end CONTINUOUS;
    record CLOCKED
      BClock clock;
      Option<BClock> baseClock;
      UnorderedSet<BClock> clock_deps "dependencies of this clocked partition";
      Boolean holdEvents;
    end CLOCKED;

    function toStringShort
      input Association association;
      output String str;
    algorithm
      str := match association
        case CONTINUOUS() then "Continuous " + Partition.kindToString(association.kind);
        case CLOCKED()    then "Clocked";
                          else "Unknown";
      end match;
    end toStringShort;

    function toString
      input Association association;
      output String str;
    algorithm
      str := match association
        case CONTINUOUS() algorithm
          if Util.isSome(association.jacobian) then
            str := BJacobian.toString(Util.getOption(association.jacobian), Partition.kindToString(association.kind));
          else
            str := StringUtil.headline_1("No Jacobian");
          end if;
        then str;
        case CLOCKED() algorithm
          str := BClock.toString(association.clock);
          if Util.isSome(association.baseClock) then
            str := StringUtil.headline_1("Sub clock: " + str + " of base clock " + BClock.toString(Util.getOption(association.baseClock)));
          else
            str := StringUtil.headline_1("Base clock: " + str);
          end if;
        then str;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. Unknown partition association in match."});
        then fail();
      end match;
    end toString;

    function create
      "create an associtation for a partition from the equation array and the clocked info
      holdEvents is updated later for clocked associations"
      input EquationPointers equations;
      input Kind kind;
      input ClockedInfo info;
      output Association association;
    protected
      Pointer<Option<ClockTpl>> clock_ptr = Pointer.create(NONE());
      UnorderedSet<ClockTpl> failed_set = UnorderedSet.new(hashClockTpl, isEqualClockTpl);
      UnorderedSet<BClock> clock_deps = UnorderedSet.new(BClock.hash, BClock.isEqual);
      Option<ClockTpl> clock_tpl;
      ComponentRef name, base_name;
      BClock clock;
      Pointer<Boolean> hasInferredClock = Pointer.create(false);
    algorithm
      // find all clocks
      EquationPointers.map(equations, function replaceClockedWhen(info = info, clock_ptr = clock_ptr, failed_set = failed_set));
      EquationPointers.mapExp(equations, function expClocked(info = info, clock_ptr = clock_ptr, failed_set = failed_set, clock_deps = clock_deps), NONE(), Expression.fakeMap);
      clock_tpl := Pointer.access(clock_ptr);

      if Util.isSome(clock_tpl) then
        SOME((name, clock)) := clock_tpl;

        // throw an error if there are different clocks in this partition
        if not UnorderedSet.isEmpty(failed_set) then
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because there are non-identical clocks in the same partition:\n"
            + "### First clock found:\n" + clockTplString((name, clock)) + "\n### Conflicting clocks:\n" + UnorderedSet.toString(failed_set, clockTplString) + "."});
          fail();
        end if;

        if BClock.isBaseClock(clock) then
          // inferred clock with no clock to follow leads to a default clock
          if BClock.isInferredClock(clock) then
            if UnorderedMap.isEmpty(info.baseClocks) then
              clock := BClock.BASE_CLOCK(ClockKind.RATIONAL_CLOCK(Expression.INTEGER(1), Expression.INTEGER(1)));
            else
              // Todo: WRONG? how do i know which clock to follow here?
              clock := UnorderedMap.getSafe(Vector.get(info.baseClocks.keys, 1), info.baseClocks, sourceInfo());
            end if;
          end if;
          // when equation clocks might introduce entirely new clocks
          if not UnorderedMap.contains(name, info.baseClocks) then
            UnorderedMap.add(name, clock, info.baseClocks);
            UnorderedMap.add(name, {}, info.baseToSub);
          end if;
          association := CLOCKED(clock, NONE(), clock_deps, false);
        else
          base_name := UnorderedMap.getSafe(name, info.subToBase, sourceInfo());
          association := CLOCKED(clock, SOME(UnorderedMap.getSafe(base_name, info.baseClocks, sourceInfo())), clock_deps, false);
        end if;
      else
        association := CONTINUOUS(kind, NONE());
      end if;
    end create;

    function merge
      input output Association ass1;
      input Association ass2;
      input Boolean strict;
    algorithm
      ass1 := match (ass1, ass2)
        local
          BackendDAE jac1, jac2;

        // merging jacobians
        case (CONTINUOUS(jacobian = SOME(jac1 as BackendDAE.JACOBIAN())), CONTINUOUS(jacobian = SOME(jac2))) guard(not strict or ass1.kind == ass2.kind) algorithm
          ass1.jacobian := SOME(BJacobian.combine({jac1, jac2}, jac1.name));
        then ass1;

        // no jacobians to merge
        case (CONTINUOUS(), CONTINUOUS()) guard(not strict or ass1.kind == ass2.kind) then ass1;

        // merging clocked partitions
        case (CLOCKED(), CLOCKED()) guard(not strict or BClock.isMergable((ass1.clock, ass1.baseClock), (ass2.clock, ass2.baseClock))) algorithm
          ass1.clock_deps := UnorderedSet.union(ass1.clock_deps, ass2.clock_deps);
          ass1.holdEvents := ass1.holdEvents or ass2.holdEvents;
        then ass1;

        // unmergable
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. Cannot merge\n" + toString(ass1) + "\n" + toString(ass2) + "."});
        then fail();
      end match;
    end merge;

    function isClocked
      input Association association;
      output Boolean b;
    algorithm
     b := match association case CLOCKED() then true; else false; end match;
    end isClocked;

    // clock tpl for collecting and comparing clocks in a partition
    type ClockTpl = tuple<ComponentRef, BClock>;

    function clockTplString
      input ClockTpl tpl;
      output String str = "(" + ComponentRef.toString(Util.tuple21(tpl)) + " = " + BClock.toString(Util.tuple22(tpl)) + ")";
    end clockTplString;

    function hashClockTpl
      input ClockTpl tpl;
      output Integer hash = 5381;
    algorithm
      hash := stringHashDjb2Continue(ComponentRef.toString(Util.tuple21(tpl)), hash);
      hash := stringHashDjb2Continue(BClock.toString(Util.tuple22(tpl)), hash);
    end hashClockTpl;

    function isEqualClockTpl
      input ClockTpl tpl1;
      input ClockTpl tpl2;
      output Boolean b =  ComponentRef.isEqual(Util.tuple21(tpl1), Util.tuple21(tpl2)) and
                          BClock.isEqual(Util.tuple22(tpl1), Util.tuple22(tpl2));
    end isEqualClockTpl;

  protected
    function replaceClockedWhen
      input output Equation eqn;
      input ClockedInfo info                    "contains all base- and sub-clocks";
      input Pointer<Option<ClockTpl>> clock_ptr "the first found clock";
      input UnorderedSet<ClockTpl> failed_set   "clocks that are not equal to the first found clock";
    algorithm
      eqn := match eqn
        local
          Expression cond;
          WhenStatement stmt;

        case Equation.WHEN_EQUATION(body = WhenEquationBody.WHEN_EQUATION_BODY(condition = cond, when_stmts = {stmt}, else_when = NONE()))
        guard(Type.isClock(Expression.typeOf(cond))) algorithm
          // check if it contains inferred clock -> update potential new clocks
          _ := match cond
            case Expression.CLKCONST() algorithm
              addClock(Equation.getEqnName(Pointer.create(eqn)), SOME(BClock.BASE_CLOCK(cond.clk)), clock_ptr, failed_set);
            then ();
            else ();
          end match;
        then WhenStatement.toEquation(stmt, eqn.attr, false);

        // nothing happens
        else eqn;
      end match;
    end replaceClockedWhen;

    function expClocked
      "checks if an expression is a clock and collects it. Also finds all other clock dependencies"
      input output Expression exp               "the examined expression";
      input ClockedInfo info                    "contains all base- and sub-clocks";
      input Pointer<Option<ClockTpl>> clock_ptr "the first found clock";
      input UnorderedSet<ClockTpl> failed_set   "clocks that are not equal to the first found clock";
      input UnorderedSet<BClock> clock_deps     "clock dependencies found in sub sampling functions";
    algorithm
      exp := match exp
        local
          Option<BClock> clock_opt;
          ComponentRef arg;

        // check if its a variable that defines a clock
        case Expression.CREF() guard(BVariable.isClockOrClocked(BVariable.getVarPointer(exp.cref, sourceInfo()))) algorithm
          // get the clock if it exists
          if UnorderedMap.contains(exp.cref, info.baseClocks) then
            clock_opt := SOME(UnorderedMap.getSafe(exp.cref, info.baseClocks, sourceInfo()));
          elseif UnorderedMap.contains(exp.cref, info.subClocks) then
            clock_opt := SOME(UnorderedMap.getSafe(exp.cref, info.subClocks, sourceInfo()));
          else
            clock_opt := NONE();
          end if;
          // update the partition clock or add to failed
          addClock(exp.cref, clock_opt, clock_ptr, failed_set);
        then exp;

        // only look for clock dependencies on sample functions
        case Expression.CALL(call = Call.TYPED_CALL(arguments = Expression.CREF(cref = arg) :: _)) guard(Expression.isClockOrSampleFunction(exp)) algorithm
          if UnorderedMap.contains(arg, info.subClocks) then
            UnorderedSet.add(UnorderedMap.getSafe(arg, info.subClocks, sourceInfo()), clock_deps);
          end if;
        then exp;

        // go deeper on everything else
        else Expression.mapShallow(exp, function expClocked(info = info, clock_ptr = clock_ptr, failed_set = failed_set, clock_deps = clock_deps));
      end match;
    end expClocked;

    function addClock
      "checks if the clock to be added is consistent with the previously found clocks.
      updates clock_ptr if correct, adds to failed_set if not."
      input ComponentRef cref;
      input Option<BClock> clock_opt;
      input Pointer<Option<ClockTpl>> clock_ptr "the first found clock";
      input UnorderedSet<ClockTpl> failed_set   "clocks that are not equal to the first found clock";
    algorithm
      _ := match (clock_opt, Pointer.access(clock_ptr))
        local
          BClock new, old;

        // old sub clock and new base clock -> no conflict
        case (SOME(new as BClock.BASE_CLOCK()), SOME((_, old as BClock.SUB_CLOCK()))) then ();

        // old base clock getting updated to new sub clock
        case (SOME(new as BClock.SUB_CLOCK()), SOME((_, old as BClock.BASE_CLOCK()))) algorithm
          Pointer.update(clock_ptr, SOME((cref, new)));
        then ();

        // new base clock that is inferred and no old clock --> add it
        case (SOME(new as BClock.BASE_CLOCK(clock = ClockKind.INFERRED_CLOCK())), NONE()) algorithm
          Pointer.update(clock_ptr, SOME((cref, new)));
        then ();

        // new base clock that is inferred with existing old clock --> nothing happens
        case (SOME(new as BClock.BASE_CLOCK(clock = ClockKind.INFERRED_CLOCK())), SOME(_)) then ();

        // old base clock is inferred --> always take new clock
        case (SOME(new), SOME((_, old as BClock.BASE_CLOCK(clock = ClockKind.INFERRED_CLOCK())))) algorithm
          Pointer.update(clock_ptr, SOME((cref, new)));
        then ();

        // clocks -> equal: success / different: fail
        case (SOME(new), SOME((_, old))) algorithm
          if not BClock.isEqual(new, old) then
            UnorderedSet.add((cref, new), failed_set);
          end if;
        then ();

        // new clock
        case (SOME(new), NONE()) algorithm
          Pointer.update(clock_ptr, SOME((cref, new)));
        then ();

        else ();
      end match;
    end addClock;
  end Association;

  uniontype Partition
    record PARTITION
      Integer index                                   "Partition index";
      Association association                         "Clocked/Continuous";
      VariablePointers unknowns                       "Variable array of unknowns, subset of full variable array";
      Option<VariablePointers> daeUnknowns            "Variable array of unknowns in the case of dae mode";
      EquationPointers equations                      "Equations array, subset of the full equation array";
      Option<Adjacency.Matrix> adjacencyMatrix        "Adjacency matrix with all additional information";
      Option<Matching> matching                       "Matching (see 2.5)";
      Option<array<StrongComponent>> strongComponents "Strong Components";
    end PARTITION;

    function toString
      input Partition partition;
      input Integer level = 0;
      output String str;
    algorithm
      str := StringUtil.headline_2("(" + intString(partition.index) + ") " + Association.toStringShort(partition.association) + " Partition") + "\n";
      str := match partition.strongComponents
        local
          array<StrongComponent> comps;

        case SOME(comps) algorithm
          for i in 1:arrayLength(comps) loop
            str := str + StrongComponent.toString(comps[i], i) + "\n";
          end for;
        then str;

        else algorithm
          str := str + VariablePointers.toString(partition.unknowns, "Unknown") + "\n" + EquationPointers.toString(partition.equations, "") + "\n";
        then str;
      end match;

      if level == 1 or level == 3 then
        if isSome(partition.adjacencyMatrix) then
          str := str + Adjacency.Matrix.toString(Util.getOption(partition.adjacencyMatrix)) + "\n";
        end if;

        if isSome(partition.matching) then
          str := str + Matching.toString(Util.getOption(partition.matching)) + "\n";
        end if;
      end if;

      if level == 2 then
        str := str + Association.toString(partition.association) + "\n";
      end if;
    end toString;

    function toStringList
      input list<Partition> partitions;
      input String header = "";
      output String str = "";
    algorithm
      if not listEmpty(partitions) then
        if header <> "" then
          str := StringUtil.headline_1(header) + "\n";
        end if;
        for part in partitions loop
          str := str + toString(part);
        end for;
      end if;
    end toStringList;

    function sort
      input output Partition partition;
    algorithm
      partition.unknowns := VariablePointers.sort(partition.unknowns);
      partition.equations := EquationPointers.sort(partition.equations);
    end sort;

    function isEmpty
      "returns true if the partition is empty.
      maybe check more than only equations?"
      input Partition partition;
      output Boolean b = EquationPointers.size(partition.equations) == 0;
    end isEmpty;

    function isODEorDAE
      input Partition part;
      output Boolean b;
    algorithm
      b := match part.association
        local
          Kind kind;
        case Association.CONTINUOUS(kind = kind) then kind == Kind.ODE or kind == Kind.ODE_EVT or kind == Kind.DAE;
        else false;
      end match;
    end isODEorDAE;

    function isClocked
      input Partition part;
      output Boolean b;
    algorithm
      b := match part.association
        local
          Kind kind;
        case Association.CLOCKED() then true;
        else false;
      end match;
    end isClocked;

    function categorize
      input Partition partition;
      input DoubleEnded.MutableList<Partition> ode;
      input DoubleEnded.MutableList<Partition> alg;
      input DoubleEnded.MutableList<Partition> ode_evt;
      input DoubleEnded.MutableList<Partition> alg_evt;
      input DoubleEnded.MutableList<Partition> clocked;
    protected
      Boolean algebraic, continuous;
      Kind kind;
      Association association;
      function isAlgebraicContinuous
        input Partition part;
        output Boolean alg = true;
        output Boolean con = true;
      algorithm
        for var in VariablePointers.toList(part.unknowns) loop
          alg := if alg then not BVariable.isStateDerivative(var) else false;
          con := if con then not BVariable.isDiscrete(var) else false;
          // stop searching if both
          if not (alg or con) then
            break;
          end if;
        end for;
      end isAlgebraicContinuous;
    algorithm
      (algebraic, continuous) := isAlgebraicContinuous(partition);
      kind  := match (algebraic, continuous)
        case (true, true)   then Kind.ALG;
        case (false, true)  then Kind.ODE;
        case (true, false)  then Kind.ALG_EVT;
        case (false, false) then Kind.ODE_EVT;
                            else fail();
      end match;
      partition.association := match (kind, partition.association)
        case (_, Association.CLOCKED()) algorithm
          DoubleEnded.push_back(clocked, partition);
        then partition.association;
        case (Kind.ALG, association as Association.CONTINUOUS()) algorithm
          association.kind := kind;
          partition.association := association;
          DoubleEnded.push_back(alg, partition);
        then association;
        case (Kind.ODE, association as Association.CONTINUOUS()) algorithm
          association.kind := kind;
          partition.association := association;
          DoubleEnded.push_back(ode, partition);
        then association;
        case (Kind.ALG_EVT, association as Association.CONTINUOUS()) algorithm
          association.kind := kind;
          partition.association := association;
          DoubleEnded.push_back(alg_evt, partition);
        then association;
        case (Kind.ODE_EVT, association as Association.CONTINUOUS()) algorithm
          association.kind := kind;
          partition.association := association;
          DoubleEnded.push_back(ode_evt, partition);
        then association;
        else fail();
      end match;
    end categorize;

    function setIndex
      input output Partition part;
      input Pointer<Integer> index;
    protected
      Integer clock_idx = Pointer.access(index);
    algorithm
      part.index := clock_idx;
      if isClocked(part) then
        part.equations := EquationPointers.map(part.equations, function Equation.setKind(kind = EquationKind.CLOCKED, clock_idx = SOME(clock_idx)));
      end if;
      Pointer.update(index, clock_idx + 1);
    end setIndex;

    function getJacobian
      input Partition part;
      output Option<Jacobian> jac;
    algorithm
      jac := match part.association
        case CONTINUOUS(jacobian = jac) then jac;
        else NONE();
      end match;
    end getJacobian;

    function getKind
      input Partition part;
      output Kind kind;
    algorithm
      kind := match part.association
        case Association.CONTINUOUS(kind = kind) then kind;
        else Kind.CLK;
      end match;
    end getKind;

    function getClocks
      input Partition part;
      output BClock clock;
      output Option<BClock> baseClock;
      output Boolean holdEvents;
    algorithm
      (clock, baseClock, holdEvents) := match part.association
        case Association.CLOCKED(clock = clock, baseClock = baseClock, holdEvents = holdEvents) then (clock, baseClock, holdEvents);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. Cannot get clock for continuous partition:\n" + toString(part)});
        then fail();
      end match;
    end getClocks;

    function getClockDependencies
      input Partition part;
      output UnorderedSet<BClock> clock_deps;
    algorithm
      clock_deps := match part.association
        case Association.CLOCKED(clock_deps = clock_deps) then clock_deps;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. Cannot get clock dependencies for continuous partition:\n" + toString(part)});
        then fail();
      end match;
    end getClockDependencies;

    function getLoopResiduals
      input Partition part;
      output list<Pointer<Variable>> residuals = {};
    algorithm
      if Util.isSome(part.strongComponents) then
        for comp in Util.getOption(part.strongComponents) loop
          residuals := listAppend(StrongComponent.getLoopResiduals(comp), residuals);
        end for;
      end if;
    end getLoopResiduals;

    function mapEqn
      input output Partition partition;
      input MapFunc func;
      partial function MapFunc
        input output BEquation.Equation e;
      end MapFunc;
    algorithm
      partition.equations := EquationPointers.map(partition.equations, func);
    end mapEqn;

    function mapExp
      input output Partition partition;
      input MapFunc func;
      partial function MapFunc
        input output Expression e;
      end MapFunc;
    algorithm
      partition.equations := EquationPointers.mapExp(partition.equations, func);
    end mapExp;

    function mapStrongComponents
      input output Partition partition;
      input MapFunc func;
      partial function MapFunc
        input output StrongComponent comp;
      end MapFunc;
    protected
      array<StrongComponent> comps;
    algorithm
      if Util.isSome(partition.strongComponents) then
        SOME(comps) := partition.strongComponents;
        for i in 1:arrayLength(comps) loop
          comps[i] := func(comps[i]);
        end for;
        partition.strongComponents := SOME(comps);
      end if;
    end mapStrongComponents;

    function kindToString
      input Kind kind;
      output String str = "";
    algorithm
      str := match kind
        case Kind.ODE         then "ODE";
        case Kind.ALG         then "ALG";
        case Kind.ODE_EVT     then "ODE_EVT";
        case Kind.ALG_EVT     then "ALG_EVT";
        case Kind.INI         then "INI";
        case Kind.DAE         then "DAE";
        case Kind.JAC         then "JAC";
        case Kind.CLK         then "CLK";
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. Unknown partition kind in match."});
        then fail();
      end match;
    end kindToString;

    function kindToInteger
      input Kind kind;
      output Integer i;
    algorithm
      i := match kind
        case Kind.ODE         then 0;
        case Kind.ALG         then 1;
        case Kind.ODE_EVT     then 2;
        case Kind.ALG_EVT     then 3;
        case Kind.INI         then 4;
        case Kind.DAE         then 5;
        case Kind.JAC         then 6;
        case Kind.CLK         then 7;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. Unknown partition kind in match."});
        then fail();
      end match;
    end kindToInteger;

    function clone
      "only clones equations."
      input output Partition par;
      input Boolean shallow = true;
    algorithm
      par.equations := EquationPointers.clone(par.equations, shallow);
      // these are partially pointer based and have to be recomputed if not shallow
      if not shallow then
        par.adjacencyMatrix   := NONE();
        par.matching          := NONE();
        par.strongComponents  := NONE();
        par.association := match par.association
          local
            Association association;
          case association as Association.CONTINUOUS() algorithm
            association.jacobian := NONE();
          then association;
          else par.association;
        end match;
      end if;
    end clone;

    function removeAlias
      "removes alias strong components and replaces it with their original strong components.
      used before differentiating for jacobians."
      input output Partition par;
    protected
      array<StrongComponent> comps;
    algorithm
      if Util.isSome(par.strongComponents) then
        // no need to override comps afterwards since arrays are mutable
        comps := Util.getOption(par.strongComponents);
        for i in 1:arrayLength(comps) loop
          comps[i] := StrongComponent.removeAlias(comps[i]);
        end for;
      end if;
    end removeAlias;

    function updateHeldVars
      input output Partition par;
      input UnorderedSet<ComponentRef> held_crefs;
    algorithm
      par.association := match par.association
        local
          Association association;
        case association as Association.CLOCKED() algorithm
          association.holdEvents := not UnorderedSet.isDisjoint(held_crefs, UnorderedMap.keySet(par.unknowns.map));
        then association;
        else par.association;
      end match;
    end updateHeldVars;

    function merge
      input output Partition part1;
      input Partition part2;
      input Boolean strict;
    algorithm
      if Util.isSome(part1.daeUnknowns) or Util.isSome(part2.daeUnknowns) then
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. Cannot merge DAE-Mode partitions."}); fail();
      elseif Util.isSome(part1.strongComponents) or Util.isSome(part2.strongComponents) then
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. Should not merge sorted partitions."}); fail();
      elseif Util.isSome(part1.matching) or Util.isSome(part2.matching) then
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. Should not merge matched partitions."}); fail();
      elseif Util.isSome(part1.adjacencyMatrix) or Util.isSome(part2.adjacencyMatrix) then
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. Should not merge partitions with adjacency matrix."}); fail();
      end if;

      // index irrelevant, should be updated after use
      part1.association := Association.merge(part1.association, part2.association, strict);
      part1.unknowns    := VariablePointers.addList(VariablePointers.toList(part2.unknowns), part1.unknowns);
      part1.equations   := EquationPointers.addList(EquationPointers.toList(part2.equations), part1.equations);
    end merge;
  end Partition;

  annotation(__OpenModelica_Interface="backend");
end NBPartition;
