/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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
encapsulated uniontype NSimPartition
"file:        NSimPartition.mo
 package:     NSimPartition
 description: This file contains the data types and functions for clocked partitions
              in simulation code phase.
"
public
  // self import
  import SimPartition = NSimPartition;

  // simcode imports
  import NSimStrongComponent.Block;
  import NSimCode.SimCodeIndices;
  import NSimVar.SimVar;

  // frontend import
  import BuiltinFuncs = NFBuiltinFuncs;
  import Call = NFCall;
  import ClockKind = NFClockKind;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import Prefixes = NFPrefixes;

  // backend imports
  import NBPartitioning.BClock;
  import NBEquation.{EquationKind, EquationAttributes, WhenStatement};
  import Matching = NBMatching;
  import Sorting = NBSorting;

  // import old simcode and frontend
  import DAE;
  import OldSimCode = SimCode;

  record BASE_PARTITION
    BClock baseClock;
    list<SimPartition> subPartitions;
  end BASE_PARTITION;

  record SUB_PARTITION
    list<tuple<SimVar, Boolean /*previous*/>> variables;
    list<Block> equations;
    list<Block> removedEquations;
    BClock subClock;
    UnorderedSet<BClock> clock_dependencies;
    Boolean holdEvents;
  end SUB_PARTITION;

  function createSubPartition
    input BClock subClock;
    input list<Block> equations;
    input list<SimVar> variables;
    input UnorderedSet<BClock> clock_dependencies;
    input Boolean holdEvents;
    output SimPartition part;
  algorithm
    // for now assume all variables need pre()
    part := SUB_PARTITION(list((v, true) for v in variables), equations, {}, subClock, clock_dependencies, holdEvents);
  end createSubPartition;

  function merge
    input SimPartition part1;
    input output SimPartition part2;
  algorithm
    part2 := match (part1, part2)
      case (SUB_PARTITION(), SUB_PARTITION()) guard(BClock.isEqual(part1.subClock, part2.subClock)) algorithm
        part2.variables           := listAppend(part1.variables, part2.variables);
        part2.equations           := listAppend(part1.equations, part2.equations);
        part2.removedEquations    := listAppend(part1.removedEquations, part2.removedEquations);
        part2.clock_dependencies  := UnorderedSet.union(part1.clock_dependencies, part2.clock_dependencies);
        part2.holdEvents          := part1.holdEvents or part2.holdEvents;
      then part2;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for non-combinable partitions:\n"
          + toString(part1) + "\n\n" + toString(part2)});
      then fail();
    end match;
  end merge;

  function createBasePartitions
    input UnorderedMap<BClock, UnorderedMap<BClock, SimPartition>> clock_collector;
    output list<SimPartition> baseParts = {};
    output list<Block> eventClocks = {};
    input output SimCodeIndices simCodeIndices;
  protected
    BClock baseClock;
    UnorderedMap<BClock, SimPartition> subClocks;
    Integer clock_idx = 1;
  algorithm
    // create all base partitions, sort the sub partitions according to their clock dependencies
    for tpl in UnorderedMap.toList(clock_collector) loop
      (baseClock, subClocks) := tpl;
      baseParts := BASE_PARTITION(baseClock, sortSubPartitions(UnorderedMap.valueList(subClocks))) :: baseParts;
    end for;

    // collect all event clocks
    for base in baseParts loop
      _ := match base
        local
          ComponentRef cond;
          DAE.ElementSource source;
          Expression fire;
          WhenStatement stmt;
          EquationAttributes attr;
          Block blck;

        case BASE_PARTITION(baseClock = BClock.BASE_CLOCK(
          clock = ClockKind.EVENT_CLOCK(condition = Expression.CREF(cref = cond))))
        algorithm
          // create a no-return when equation that triggers clock fire
          // when (condition) then $_clkfire(i)
          source  := DAE.emptyElementSource;
          fire    := Expression.CALL(Call.makeTypedCall(
            fn          = NFBuiltinFuncs.CLOCK_FIRE,
            args        = {Expression.INTEGER(clock_idx)},
            variability = NFPrefixes.Variability.CONSTANT,
            purity      = NFPrefixes.Purity.PURE));
          stmt    := WhenStatement.NORETCALL(fire, source);
          attr    := EquationAttributes.default(EquationKind.EMPTY, false);
          blck    := Block.WHEN(simCodeIndices.equationIndex, false, {cond}, {stmt}, NONE(), source, attr);

          eventClocks := blck :: eventClocks;
          simCodeIndices.equationIndex := simCodeIndices.equationIndex + 1;
        then ();
        else ();
      end match;
      clock_idx := clock_idx + 1;
    end for;
  end createBasePartitions;

  function sortSubPartitions
    "use tarjan to sort sub partitions that rely on order"
    input list<SimPartition> unsorted;
    output list<SimPartition> sorted = {};
  protected
    Integer n = listLength(unsorted);
    array<SimPartition> partitions = listArray(listReverse(unsorted));
    array<list<Integer>> m = arrayCreate(n, {});
    // create a trivial matching for an artificially matched bipartite graph (tarjan implementation needs it)
    Matching matching = Matching.trivial(n);
    UnorderedMap<BClock, Integer> index_map = UnorderedMap.new<Integer>(BClock.hash, BClock.isEqual);
    Integer j;
    list<list<Integer>> partition_order;
  algorithm
    // prepare the clock to partition index map
    for i in 1:n loop
      UnorderedMap.add(getClock(partitions[i]), i, index_map);
    end for;

    // fill the adjacency matrix
    for i in 1:n loop
      for clock in UnorderedSet.toList(getClockDependencies(partitions[i])) loop
        j := UnorderedMap.getSafe(clock, index_map, sourceInfo());
        m[i] := j :: m[i];
      end for;
    end for;

    // use tarjan to sort the artificial bipartite graph
    partition_order := Sorting.tarjanScalar(m, matching);

    // use the strong components to sort partitions. no algebraic loops allowed
    for comp in listReverse(partition_order) loop
      sorted := match comp
        case {j} then partitions[j] :: sorted;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for sub-partitions with cyclic dependency:\n"
           + List.toString(list(partitions[i] for i in comp), function toString(str = ""))});
        then fail();
      end match;
    end for;
  end sortSubPartitions;

  function getClockDependencies
    input SimPartition part;
    output UnorderedSet<BClock> clock_dependencies;
  algorithm
    clock_dependencies := match part
      case SUB_PARTITION() then part.clock_dependencies;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for non-sub partition:\n" + toString(part)});
      then fail();
    end match;
  end getClockDependencies;

  function getClock
    input SimPartition part;
    output BClock clock;
  algorithm
    clock := match part
      case BASE_PARTITION() then part.baseClock;
      case SUB_PARTITION()  then part.subClock;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for unknown partition:\n" + toString(part)});
      then fail();
    end match;
  end getClock;

  function listToString
    input list<SimPartition> parts;
    input output String str = "";
    input String header = "";
  protected
    String indent = str;
  algorithm
    str := if header <> "" then StringUtil.headline_3(header) else "";
    for part in parts loop
      str := str + toString(part, indent);
    end for;
  end listToString;

  function toString
    input SimPartition part;
    input output String str = "";
  algorithm
    str := match part
      case BASE_PARTITION() then "[BASE] Partition " + BClock.toString(part.baseClock) + List.toString(part.subPartitions, function toString(str = str), "", "\n", "", "\n");
      case SUB_PARTITION()  then str + "[SUB-] Partition " + BClock.toString(part.subClock) + List.toString(part.equations, function Block.toString(str = str), "", "\n", "", "");
      else "[ERR-]";
    end match;
  end toString;

  function toStringShort
    input SimPartition part;
    output String str;
  algorithm
    str := match part
      case BASE_PARTITION() then "[BASE] Partition " + BClock.toString(part.baseClock);
      case SUB_PARTITION()  then "[SUB-] Partition " + BClock.toString(part.subClock);
      else "[ERR-]";
    end match;
  end toStringShort;

  function convertBase
    input SimPartition part;
    output OldSimCode.ClockedPartition oldPart;
  algorithm
    oldPart := match part
      case BASE_PARTITION() then OldSimCode.CLOCKED_PARTITION(
        baseClock     = BClock.convertBase(part.baseClock),
        subPartitions = list(convertSub(sub) for sub in part.subPartitions));
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for non-base partition:\n" + toString(part)});
      then fail();
    end match;
  end convertBase;

  function convertSub
    input SimPartition part;
    output OldSimCode.SubPartition oldPart;
  algorithm
    oldPart := match part
      case SUB_PARTITION() then OldSimCode.SUBPARTITION(
        vars                = list(SimVar.convertTpl(tpl) for tpl in part.variables),
        equations           = list(Block.convert(blck) for blck in part.equations),
        removedEquations    = list(Block.convert(blck) for blck in part.removedEquations),
        subClock            = BClock.convertSub(part.subClock),
        holdEvents          = part.holdEvents);
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for non-base partition:\n" + toString(part)});
      then fail();
    end match;
  end convertSub;

  annotation(__OpenModelica_Interface="backend");
end NSimPartition;