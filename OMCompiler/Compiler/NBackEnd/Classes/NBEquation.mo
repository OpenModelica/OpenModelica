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
encapsulated package NBEquation
" file:         NBEquation.mo
  package:      NBEquation
  description:  This file contains all functions and structures regarding
                backend equations.
"

public
  // Old Frontend imports
  import DAE;
  import ElementSource;

  // New Frontend imports
  import Algorithm = NFAlgorithm;
  import BackendDAE = NBackendDAE;
  import NFBackendExtension.VariableAttributes;
  import Binding = NFBinding;
  import Call = NFCall;
  import Class = NFClass;
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import NFFlatten.FunctionTree;
  import InstNode = NFInstNode.InstNode;
  import Operator = NFOperator;
  import NFPrefixes.{Variability, Purity};
  import SimplifyExp = NFSimplifyExp;
  import SimplifyModel = NFSimplifyModel;
  import Statement = NFStatement;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Typing = NFTyping;
  import Variable = NFVariable;

  // Old Backend imports
  import OldBackendDAE = BackendDAE;

  // New Backend imports
  import DetectStates = NBDetectStates;
  import NBResizable.EvalOrder;
  import Evaluation = NBEvaluation;
  import Inline = NBInline;
  import Replacements = NBReplacements;
  import StrongComponent = NBStrongComponent;
  import Solve = NBSolve;
  import BVariable = NBVariable;
  import NBVariable.{VariablePointer, VariablePointers};

  // Util imports
  import BackendUtil = NBBackendUtil;
  import BaseHashTable;
  import ExpandableArray;
  import Slice = NBSlice;
  import StringUtil;
  import UnorderedMap;
  import Util;

  constant String SIMULATION_STR  = "SIM";
  constant String START_STR       = "SRT";
  constant String PRE_STR         = "PRE";
  constant String TMP_STR         = "TMP";

  type EquationPointer = Pointer<Equation> "mainly used for mapping purposes";

  // used to process different outcomes of slicing from Util/Slice.mo
  // have to be defined here and not in Util/Slice.mo because it is a uniontype and not a package
  type Frame                = tuple<ComponentRef, Expression, Option<Iterator>>     "iterator-like tuple for array handling";
  type FrameLocation        = tuple<array<Integer>, Frame>                          "sliced frame at specific sub locations";
  type SlicingStatus        = enumeration(UNCHANGED, TRIVIAL, NONTRIVIAL, FAILURE)  "final result of slicing";
  type RecollectStatus      = enumeration(SUCCESS, FAILURE)                         "result of sub-routine recollect";
  type FrameOrderingStatus  = enumeration(UNCHANGED, CHANGED, FAILURE)              "result of sub-routine frame ordering";

  type CrefLst              = list<ComponentRef>                                    "type for collecting data in hash maps";

  partial function MapFuncEqn
    input output Equation e;
  end MapFuncEqn;

  partial function MapFuncEqnPtr
    input output Pointer<Equation> e;
  end MapFuncEqnPtr;

  partial function MapFuncExp
    input output Expression e;
  end MapFuncExp;

  partial function MapFuncExpWrapper
    input output Expression e;
    input MapFuncExp func;
  end MapFuncExpWrapper;

  partial function MapFuncCref
    input output ComponentRef c;
  end MapFuncCref;

  partial function checkEqn
    input Pointer<Equation> eqn_ptr;
    output Boolean b;
  end checkEqn;

  uniontype Iterator
    record SINGLE
      ComponentRef name           "the name of the iterator";
      Expression range            "range as <start, step, stop>";
      Option<Iterator> map        "maps to a second iterator if derived from a for-expression";
    end SINGLE;

    record NESTED
      array<ComponentRef> names   "sorted iterator names";
      array<Expression> ranges    "sorted ranges as <start, step, stop>";
      array<Option<Iterator>> maps"maps to a second iterator if derived from a for-expression";
    end NESTED;

    record EMPTY
    end EMPTY;

    function fromFrames
      input list<Frame> frames;
      output Iterator iter;
    protected
      list<ComponentRef> names;
      list<Expression> ranges;
      list<Option<Iterator>> maps;
      ComponentRef name;
      Expression range;
      Option<Iterator> map;
    algorithm
      if listEmpty(frames) then
        iter := EMPTY();
      else
        (names, ranges, maps) := List.unzip3(frames);
        iter := match (names, ranges, maps)
          case ({name}, {range}, {map})  then SINGLE(name, range, map);
                                  else NESTED(listArray(names), listArray(ranges), listArray(maps));
        end match;
      end if;
    end fromFrames;

    function addFrames
      input output Iterator iter;
      input list<Frame> frames;
    protected
      list<ComponentRef> names1, names2;
      list<Expression> ranges1, ranges2;
      list<Option<Iterator>> maps1, maps2;
    algorithm
      if not listEmpty(frames) then
        (names1, ranges1, maps1) := getFrames(iter);
        (names2, ranges2, maps2) := List.unzip3(frames);
        iter := fromFrames(List.zip3(listAppend(names1, names2), listAppend(ranges1, ranges2), listAppend(maps1, maps2)));
      end if;
    end addFrames;

    function getFrames
      input Iterator iter;
      output list<ComponentRef> names;
      output list<Expression> ranges;
      output list<Option<Iterator>> maps;
    algorithm
      (names, ranges, maps) := match iter
        case SINGLE() then ({iter.name}, {iter.range}, {iter.map});
        case NESTED() then (arrayList(iter.names), arrayList(iter.ranges), arrayList(iter.maps));
        case EMPTY()  then ({}, {}, {});
      end match;
    end getFrames;

    function merge
      "merges multiple iterators to one NESTED() iterator"
      input list<Iterator> iterators;
      output Iterator result;
    protected
      list<ComponentRef> tmp_names, names = {};
      list<Expression> tmp_ranges, ranges = {};
      list<Option<Iterator>> tmp_maps, maps = {};
    algorithm
      if List.hasOneElement(iterators) then
        result := listHead(iterators);
      else
        for iter in listReverse(iterators) loop
          (tmp_names, tmp_ranges, tmp_maps) := getFrames(iter);
          names   := listAppend(tmp_names, names);
          ranges  := listAppend(tmp_ranges, ranges);
          maps    := listAppend(tmp_maps, maps);
        end for;
        result := NESTED(listArray(names), listArray(ranges), listArray(maps));
      end if;
    end merge;

    function split
      "splits an operator in its SINGLE() subparts. used for converting to old structure and writing code
      NOTE: returns iterators in reverse order!"
      input Iterator iterator;
      output list<Iterator> result = {};
    protected
      list<ComponentRef> names;
      list<Expression> ranges;
      list<Option<Iterator>> maps;
    algorithm
      (names, ranges, maps) := getFrames(iterator);
      for tpl in List.zip3(names, ranges, maps) loop
        result := Iterator.fromFrames({tpl}) :: result;
      end for;
    end split;

    function rename
      input output Iterator iter;
      input String newBaseName;
      input UnorderedMap<ComponentRef, Expression> replacements;
    algorithm
      iter := match iter
        local
          ComponentRef replacor;

        case SINGLE() algorithm
          replacor := ComponentRef.rename(newBaseName + intString(1), iter.name);
          UnorderedMap.add(iter.name, Expression.fromCref(replacor), replacements);
          iter.name := replacor;
        then iter;

        case NESTED() algorithm
          for i in 1:arrayLength(iter.names) loop
            replacor := ComponentRef.rename(newBaseName + intString(i), iter.names[i]);
            UnorderedMap.add(iter.names[i], Expression.fromCref(replacor), replacements);
            iter.names[i] := replacor;
          end for;
        then iter;
      end match;
    end rename;

    function isEqual
      "compares two iterators not considering their name!"
      input Iterator iter1;
      input Iterator iter2;
      output Boolean b = true;
    algorithm
      b := match (iter1, iter2)
        case (EMPTY(), EMPTY()) then true;
        case (SINGLE(), SINGLE()) then Expression.isEqual(iter1.range, iter2.range) and Util.optionEqual(iter1.map, iter2.map, isEqual);
        case (NESTED(), NESTED()) algorithm
          if arrayLength(iter1.ranges) == arrayLength(iter2.ranges) and arrayLength(iter1.maps) == arrayLength(iter2.maps) then
            for i in 1:arrayLength(iter1.ranges) loop
              b := Expression.isEqual(iter1.ranges[i], iter2.ranges[i]);
              if not b then break; end if;
            end for;
            for i in 1:arrayLength(iter1.maps) loop
              b := Util.optionEqual(iter1.maps[i], iter2.maps[i], isEqual);
              if not b then break; end if;
            end for;
          else
            b := false;
          end if;
        then b;
        else false;
      end match;
    end isEqual;

    function isEmpty
      input Iterator iter;
      output Boolean b;
    algorithm
      b := match iter case EMPTY() then true; else false; end match;
    end isEmpty;

    function intersect
      input Iterator iter1;
      input Iterator iter2;
      output Iterator intersection;
      output tuple<Iterator, Iterator> rest1;
      output tuple<Iterator, Iterator> rest2;
    algorithm
      (intersection, rest1, rest2) := match (iter1, iter2)
        local
          Integer start1, step1, stop1, start2, step2, stop2;
          Integer start_min, start_max, stop_min, stop_max;

        // ToDo: index shift if mod start1 != start2
        case (SINGLE(range = Expression.RANGE(start=Expression.INTEGER(start1), step=SOME(Expression.INTEGER(step1)), stop=Expression.INTEGER(stop1))),
              SINGLE(range = Expression.RANGE(start=Expression.INTEGER(start2), step=SOME(Expression.INTEGER(step2)), stop=Expression.INTEGER(stop2))))
              guard(step1 == step2 and intMod(start1, step1) == intMod(start2, step2))
          algorithm
            start_min := intMin(start1, start2);
            start_max := intMax(start1, start2);
            stop_min := intMin(stop1, stop2);
            stop_max := intMax(stop1, stop2);

            // create intersection
            if start_max >= stop_min then
              intersection := EMPTY();
            else
              intersection := SINGLE(
                name  = iter1.name,
                range = Expression.RANGE(
                  ty    = Expression.typeOf(iter1.range),
                  start = Expression.INTEGER(start_max),
                  step  = SOME(Expression.INTEGER(step1)),
                  stop  = Expression.INTEGER(stop_min)),
                map  = iter1.map);
            end if;

            // create rest
            rest1 := intersectRest(iter1.name, start1, step1, stop1, start_max-step1, stop_min+step1, iter1.map);
            rest2 := intersectRest(iter2.name, start2, step2, stop2, start_max-step2, stop_min+step2, iter2.map);
        then (intersection, rest1, rest2);

        // cannot intersect
        else (EMPTY(), (iter1, EMPTY()), (EMPTY(), iter2));
      end match;
    end intersect;

    function intersectRest
      input ComponentRef name;
      input Integer start;
      input Integer step;
      input Integer stop;
      input Integer start_max;
      input Integer stop_min;
      input Option<Iterator> map;
      output tuple<Iterator, Iterator> rest;
    protected
      Iterator rest_left, rest_right;
    algorithm
      if start > start_max  then
        rest_left := EMPTY();
      else
        rest_left := Iterator.SINGLE(
          name  = name,
          range = Expression.makeRange(
            start = Expression.INTEGER(start),
            step  = SOME(Expression.INTEGER(step)),
            stop  = Expression.INTEGER(start_max)),
          map   = map);
      end if;

      if stop_min > stop  then
        rest_right := EMPTY();
      else
        rest_right := Iterator.SINGLE(
          name  = name,
          range = Expression.makeRange(
            start = Expression.INTEGER(stop_min),
            step  = SOME(Expression.INTEGER(step)),
            stop  = Expression.INTEGER(stop)),
          map   = map);
      end if;
      rest := (rest_left, rest_right);
    end intersectRest;

    function types
      input Iterator iter;
      output list<Type> t "outermost first!";
    algorithm
      t := match iter
        case SINGLE() then {Expression.typeOf(iter.range)};
        case NESTED() then list(Expression.typeOf(iter.ranges[i]) for i in 1:arrayLength(iter.ranges));
        case EMPTY()  then {};
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " could not get types for: " + toString(iter) + "\n"});
        then fail();
      end match;
    end types;

    function sizes
      input Iterator iter;
      input Boolean resize = false;
      output list<Integer> sizes "outermost first!";
    algorithm
      sizes := match iter
        case SINGLE() then {Expression.rangeSize(iter.range, resize)};
        case NESTED() then list(Expression.rangeSize(iter.ranges[i], resize) for i in 1:arrayLength(iter.ranges));
        case EMPTY()  then {};
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " could not get sizes for: " + toString(iter) + "\n"});
        then fail();
      end match;
    end sizes;

    function size
      input Iterator iter;
      input Boolean resize = false;
      output Integer size = product(i for i in 1 :: sizes(iter, resize));
    end size;

    function dimensions
      input Iterator iter;
      output list<Dimension> dims = List.flatten(list(Type.arrayDims(t) for t in types(iter)));
    end dimensions;

    function numDimensions
      input Iterator iter;
      output Integer num;
    algorithm
      num := match iter
        case SINGLE() then 1;
        case NESTED() then arrayLength(iter.names);
        else 0;
      end match;
    end numDimensions;

    function dummy
      "creates a dummy iterator as a replacement for the actual correct one
      Used for solving the body to only evaluate a single frame location instead of all."
      input output Iterator iter;
    protected
      list<ComponentRef> names;
      list<Expression> ranges;
      list<Option<Iterator>> maps;
      function dummyRange
        "artificially set the range to only its first element"
        input output Expression exp;
      algorithm
        exp := match exp
          case Expression.RANGE() then Expression.makeRange(exp.start, NONE(), exp.start);
          case Expression.ARRAY() algorithm
          then if arrayLength(exp.elements) > 0 then Expression.makeArray(
              ty      = Type.ARRAY(Type.INTEGER(), {Dimension.fromInteger(1)}),
              expl    = arrayCreate(1, exp.elements[1]),
              literal = Expression.isLiteral(exp.elements[1]))
            else exp;
          else exp;
        end match;
      end dummyRange;
    algorithm
      (names, ranges, maps) := getFrames(iter);
      ranges := list(dummyRange(e) for e in ranges);
      iter := fromFrames(List.zip3(names, ranges, maps));
    end dummy;

    function createLocationReplacements
      "adds replacements rules for a single frame location
      Note: does not take body sizes > 1 into account"
      input Iterator iter                                         "iterator to replace";
      input array<Integer> location                               "zero based location";
      input UnorderedMap<ComponentRef, Expression> replacements   "replacement rules";
    algorithm
      () := match iter
        local
          Integer start, step;

        case SINGLE() guard(arrayLength(location) == 1) algorithm
          (start, step, _) := Expression.getIntegerRange(iter.range);
          UnorderedMap.add(iter.name, Expression.INTEGER(start + location[1]*step), replacements);
          createMappedLocationReplacement(iter.map, location[1], replacements);
        then ();

        case NESTED() guard(arrayLength(location) == arrayLength(iter.ranges)) algorithm
          for i in 1:arrayLength(location) loop
            (start, step, _) := Expression.getIntegerRange(iter.ranges[i]);
            UnorderedMap.add(iter.names[i], Expression.INTEGER(start + location[i]*step), replacements);
            createMappedLocationReplacement(iter.maps[i], location[i], replacements);
          end for;
        then ();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " could not create replacements for location: "
            + Array.toString(location, intString) + " and iterator: " + toString(iter) + "\n"});
        then fail();
      end match;
    end createLocationReplacements;

    function createMappedLocationReplacement
      input Option<Iterator> map;
      input Integer location;
      input UnorderedMap<ComponentRef, Expression> replacements   "replacement rules";
    algorithm
      _ := match map
        local
          ComponentRef name;
          Expression arr;

        // only does something if the option is filled with an array
        // fail if there is something else?
        case SOME(SINGLE(name = name, range = arr as Expression.ARRAY())) algorithm
          UnorderedMap.add(name, arr.elements[location], replacements);
        then ();
        else ();
      end match;
    end createMappedLocationReplacement;

    function createReplacement
      "adds a replacement rule for one iterator to another.
      fails if they do not have the same depth or range size."
      input Iterator replacor "replaces";
      input Iterator replacee "gets replaced";
      input UnorderedMap<ComponentRef, Expression> replacements   "replacement rules";
    protected
      Boolean failed = false;
    algorithm
      failed := match (replacor, replacee)
        case (SINGLE(), SINGLE()) algorithm
          failed := createSingleReplacement(replacor.name, replacor.range, replacee.name, replacee.range, replacements);
        then failed;

        case (NESTED(), NESTED()) algorithm
          if arrayLength(replacor.names) == arrayLength(replacee.names) then
            for i in 1:arrayLength(replacor.names) loop
              failed := createSingleReplacement(replacor.names[i], replacor.ranges[i], replacee.names[i], replacee.ranges[i], replacements);
              if failed then break; end if;
            end for;
          else
            failed := true;
          end if;
        then failed;

        else true;
      end match;

      if failed then
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " could not create replacements for replacor: "
          + toString(replacor) + " and replacee: " + toString(replacee) + "\n"});
        fail();
      end if;
    end createReplacement;

    function createSingleReplacement
      "helper function for createReplacement()"
      input ComponentRef replacor_cref;
      input Expression replacor_range;
      input ComponentRef replacee_cref;
      input Expression replacee_range;
      input UnorderedMap<ComponentRef, Expression> replacements   "replacement rules";
      output Boolean failed = false;
    protected
      Integer or_start, or_step, or_stop, ee_start, ee_step, ee_stop;
      Expression exp;
    algorithm
      (or_start, or_step, or_stop) := Expression.getIntegerRange(replacor_range);
      (ee_start, ee_step, ee_stop) := Expression.getIntegerRange(replacee_range);
      // check if same size
      if (or_stop-or_start+1)/or_step == (ee_stop-ee_start+1)/ee_step then
        // replacee = ee_start + (ee_step/or_step) * (replacor-or_start)
        exp := Expression.MULTARY(
          arguments     = {Expression.REAL(intReal(ee_start)),
            Expression.MULTARY(
              arguments     = {Expression.REAL(intReal(ee_step)/intReal(or_step)),
                Expression.MULTARY(
                arguments     = {Expression.fromCref(replacor_cref)},
                inv_arguments = {Expression.REAL(intReal(or_start))},
                operator      = Operator.makeAdd(Type.REAL()))},
              inv_arguments = {},
              operator      = Operator.makeMul(Type.REAL()))},
          inv_arguments = {},
          operator      = Operator.makeAdd(Type.REAL()));
        UnorderedMap.add(replacee_cref, exp, replacements);
      else
        failed := true;
      end if;
    end createSingleReplacement;

    function expand
      "takes an iterator and expands it with the iterators of an array
      constructor or a reduction."
      input output Iterator iter;
      input Call call;
    protected
      // dummy set for new variables. ToDo: save them to global variables
      UnorderedSet<VariablePointer> new_iters = UnorderedSet.new(BVariable.hash, BVariable.equalName);
    algorithm
      iter := match call
        local
          list<ComponentRef> names;
          list<Expression> ranges;
          list<Option<Iterator>> maps;

        case Call.TYPED_ARRAY_CONSTRUCTOR() algorithm
          (names, ranges, maps) := getFrames(iter);
        then fromFrames(listAppend(list(Inline.inlineArrayIterator(tpl, new_iters) for tpl in call.iters), List.zip3(names, ranges, maps)));

        case Call.TYPED_REDUCTION() algorithm
          (names, ranges, maps) := getFrames(iter);
        then fromFrames(listAppend(list(Inline.inlineArrayIterator(tpl, new_iters) for tpl in call.iters), List.zip3(names, ranges, maps)));

        else iter;
      end match;
    end expand;

    function extract
      "takes an expression and maps it to find all occuring iterators.
      returns an iterator if all iterators are equal, fails otherwise.
      also replaces all array constructors with indexed expressions."
      output Iterator iter;
      input output Expression exp;
      input UnorderedSet<VariablePointer> new_iters = UnorderedSet.new(BVariable.hash, BVariable.equalName) "store new iterators";
      input UnorderedMap<list<Dimension>, CrefLst> dims_map = UnorderedMap.new<CrefLst>(Dimension.hashList, function List.isEqualOnTrue(inCompFunc = Dimension.isEqual));
    protected
      UnorderedMap<ComponentRef, Expression> replacements = UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
    algorithm
      (exp, iter) := extractFromCall(exp, EMPTY(), replacements, new_iters, dims_map);
      exp := Expression.map(exp, function Replacements.applySimpleExp(replacements = replacements));
      exp := Typing.typeExp(exp, NFInstContext.RHS, sourceInfo(), true);
    end extract;

    function extractFromCall
      "helper function for extract()"
      input output Expression exp;
      input output Iterator iter;
      input UnorderedMap<ComponentRef, Expression> replacements   "replacement rules";
      input UnorderedSet<VariablePointer> new_iters;
      input UnorderedMap<list<Dimension>, list<ComponentRef>> dims_map;
    algorithm
      (exp, iter) := match exp
        local
          Call call;
          list<Frame> frames = {};
          InstNode node;
          Expression range;
          Iterator tmp;
          list<Dimension> full_dims, elem_dims;

        case Expression.CALL(call = call as Call.TYPED_ARRAY_CONSTRUCTOR()) algorithm
          // inline the frontend iterator to get frames for backend iterator
          for tpl in listReverse(call.iters) loop
            frames := Inline.inlineArrayIterator(tpl, new_iters) :: frames;
          end for;
          tmp := fromFrames(frames);

          // create replacement rules if neccessary
          if not isEmpty(iter) then
            createReplacement(iter, tmp, replacements);
          else
            iter := tmp;
          end if;

          // add the dimension -> iterator names to the dims map to apply the iterators correctly to the lhs
          full_dims := Type.arrayDims(Expression.typeOf(exp));
          // remove the dimensions of the type we iterate over to avoid applyings subscripts there
          full_dims := List.firstN(full_dims, listLength(full_dims) - Type.dimensionCount(Expression.typeOf(call.exp)));
          // only add if it's a new dimension configuration, first iterator replaces others
          UnorderedMap.tryAdd(full_dims, list(Util.tuple31(f) for f in frames), dims_map);
        then (call.exp, iter);

        // do not iterate call arguments
        case Expression.CALL() then (exp, iter);

        else algorithm
          (exp, iter) := Expression.mapFoldShallow(exp, function extractFromCall(replacements = replacements, new_iters = new_iters, dims_map = dims_map), iter);
        then (exp, iter);
      end match;
    end extractFromCall;

    function normalizedSubscripts
      "creates a normalized subscript list such that the traversed iterators result in
      consecutive indices starting at 1."
      input Iterator iter;
      input UnorderedMap<ComponentRef, Subscript> iter_map = UnorderedMap.new<Subscript>(ComponentRef.hash, ComponentRef.isEqual);
      output list<Subscript> subs;
    protected
      list<ComponentRef> names;
      list<Expression> ranges;
    algorithm
      (names, ranges) := getFrames(iter);
      subs := list(normalizedSubscript(name, range, iter_map) threaded for name in names, range in ranges);
    end normalizedSubscripts;

    function normalizedSubscript
      "returns subscripts such that traversing the range results in consecutive subscript values 1,2,3....
      e.g: i in 10:-2:1 -> x[(i-10)/(-2) + 1] which results in 1,2,3... for i=10,8,6..."
      input ComponentRef iter_name;
      input Expression range;
      input UnorderedMap<ComponentRef, Subscript> iter_map;
      output Subscript sub;
    protected
      Expression step, sub_exp;
    algorithm
      sub := match range

        // (iterator-start)/step + 1
        case Expression.RANGE() algorithm
          step := Util.getOptionOrDefault(range.step, Expression.INTEGER(1));
          sub_exp := Expression.fromCref(iter_name);
          // i - start
          if not Expression.isOne(range.start) then
            sub_exp := Expression.MULTARY(
              arguments = {sub_exp},
              inv_arguments = {range.start},
              operator = Operator.makeAdd(Type.INTEGER()));
          end if;

          // (...)/step
          if not Expression.isOne(step) then
            sub_exp := Expression.MULTARY(
              arguments = {sub_exp},
              inv_arguments = {step},
              operator = Operator.makeMul(Type.REAL()));
          end if;

          // (...) + 1
          if not Expression.isOne(range.start) then
            sub_exp := Expression.MULTARY(
              arguments = {sub_exp, Expression.INTEGER(1)},
              inv_arguments = {},
              operator = Operator.makeAdd(Expression.typeOf(sub_exp)));
          end if;

          sub_exp := SimplifyExp.simplifyDump(sub_exp, true, getInstanceName());
          if not Type.isInteger(Expression.typeOf(sub_exp)) then
            sub_exp := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.INTEGER_REAL, {sub_exp}, Variability.DISCRETE, Purity.PURE));
          end if;
        then Subscript.INDEX(sub_exp);

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
            + " failed because range is no range: " + Expression.toString(range)});
        then fail();
      end match;

      // add the pair to the map
      UnorderedMap.add(iter_name, sub, iter_map);
    end normalizedSubscript;

    function simplifyRangeCondition
      "used for nested for/if equation. e.g:
      for i in 1:10 loop
        if i <> 6 then // (no else case)
          [...]
      has to be simplified to
      for i in {1,2,3,4,5,7,8,9,10} loop
        [...]"
      input output Iterator iter;
      input Expression condition;
      output Solve.Status status;
    protected
      type IterOpt = Option<Iterator>; // needed for the map
      list<ComponentRef> names;
      list<Expression> ranges;
      list<Option<Iterator>> maps;
      UnorderedMap<ComponentRef, Expression> iter_map = UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
      UnorderedMap<ComponentRef, IterOpt> opt_map = UnorderedMap.new<IterOpt>(ComponentRef.hash, ComponentRef.isEqual);
    algorithm
      (iter, status) := match condition
        local
          Equation tmpEqn;
          list<ComponentRef> occs;
          ComponentRef cref;
          Solve.RelationInversion invert;
          Expression range;
          Operator operator;

        case Expression.RELATION() algorithm
          // prepare the mappings
          (names, ranges, maps) := getFrames(iter);
          for frame in List.zip3(names, ranges, maps) loop
            UnorderedMap.add(Util.tuple31(frame), Util.tuple32(frame), iter_map);
            UnorderedMap.add(Util.tuple31(frame), Util.tuple33(frame), opt_map);
          end for;

          // create temp equation and collect all occuring iterator crefs
          tmpEqn  := Pointer.access(Equation.makeAssignment(condition.exp1, condition.exp2, Pointer.create(0), NBVariable.TEMPORARY_STR, Iterator.EMPTY(), EquationAttributes.default(EquationKind.UNKNOWN, false)));
          occs    := Equation.collectCrefs(tmpEqn, function Equation.collectFromMap(check_map = iter_map));


          if listLength(occs) == 1 then
            // get the only occuring iterator cref and solve the body for it
            cref := listHead(occs);
            (tmpEqn, _, status, invert) := Solve.solveBody(tmpEqn, cref, FunctionTree.EMPTY());
            operator := if invert == NBSolve.RelationInversion.TRUE then Operator.invert(condition.operator) else condition.operator;

            // if its solvable, get the corresponding iterator range and adapt it with the information of the if-condition
            if status == NBSolve.Status.EXPLICIT and invert <> NBSolve.RelationInversion.UNKNOWN then
              range := UnorderedMap.getSafe(cref, iter_map, sourceInfo());
              try
                (range, status) := match range
                  case Expression.RANGE() then (adaptRange(UnorderedMap.getSafe(cref, iter_map, sourceInfo()), Equation.getRHS(tmpEqn), operator), status);

                  // ToDo: intercepting this
                  case Expression.ARRAY() then (adaptArray(UnorderedMap.getSafe(cref, iter_map, sourceInfo()), Equation.getRHS(tmpEqn), operator), status);

                  // can't do anything here
                  else (range, NBSolve.Status.UNSOLVABLE);
                end match;
              else
                Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to combine iterator: " + toString(iter) + " with condition " + Expression.toString(condition) + "."});
                fail();
              end try;

              UnorderedMap.add(cref, range, iter_map);
            else
              status := NBSolve.Status.UNSOLVABLE;
            end if;
          end if;

          // if something changed, create a new iterator
          if status == NBSolve.Status.EXPLICIT then
            iter := Iterator.fromFrames(list((name, UnorderedMap.getSafe(name, iter_map, sourceInfo()), UnorderedMap.getSafe(name, opt_map, sourceInfo())) for name in names));
          end if;
        then (iter, status);

        else (iter, NBSolve.Status.UNSOLVABLE);
      end match;
    end simplifyRangeCondition;

    function adaptRange
      input output Expression range;
      input Expression rhs;
      input Operator operator;
    protected
      Integer thresh, start, step, stop;
      Boolean within_range;
    algorithm
      // extract the primitive type representation
      (thresh, start, step, stop) := match (rhs, range)
        case (Expression.INTEGER(thresh), range as Expression.RANGE(start = Expression.INTEGER(start), step = SOME(Expression.INTEGER(step)), stop = Expression.INTEGER(stop))) then (thresh, start, step, stop);
        case (Expression.INTEGER(thresh), range as Expression.RANGE(start = Expression.INTEGER(start), stop = Expression.INTEGER(stop))) then (thresh, start, 1, stop);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because range could not be evaluated: " + Expression.toString(range)});
        then fail();
      end match;

      within_range := thresh * sign(step) > start * sign(step) and thresh * sign(step) < stop * sign(step);

      range := match operator.op
        // i == VAL as a condition
        case NFOperator.Op.EQUAL then
          // remove all but this element from the range
          if within_range then Expression.makeRange(Expression.INTEGER(thresh), NONE(), Expression.INTEGER(thresh))
          // this element is not in the range >>> no valid element
          else Expression.makeRange(Expression.INTEGER(0), SOME(Expression.INTEGER(0)), Expression.INTEGER(0));

        // i <> VAL as a condition
        case NFOperator.Op.NEQUAL then
          // remove only this element from the range
          if within_range then Expression.makeExpArray(listArray(list(Expression.INTEGER(i) for i guard(i <> thresh) in List.intRange3(start, step, stop))), Type.INTEGER(), true)
          // this element is not in the range >>> original range not changed
          else range;

        // i <, <=, >, >=  VAL as a condition
        case NFOperator.Op.LESS       then interceptRange(thresh - 1, start, step, stop, within_range, sign(step) > 0, range, intLe);
        case NFOperator.Op.LESSEQ     then interceptRange(thresh, start, step, stop, within_range, sign(step) > 0, range, intLt);
        case NFOperator.Op.GREATER    then interceptRange(thresh + 1, start, step, stop, within_range, sign(step) < 0, range, intGe);
        case NFOperator.Op.GREATEREQ  then interceptRange(thresh, start, step, stop, within_range, sign(step) < 0, range, intGt);

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for operator: " + Operator.toDebugString(operator)});
        then fail();
      end match;
    end adaptRange;

    function interceptRange
      input Integer thresh, start, step, stop;
      input Boolean within_range, at_end;
      input output Expression range;
      input intComp func;
    protected
      partial function intComp
        input Integer i1, i2;
        output Boolean b;
      end intComp;

      function lowerBoundary
        input Integer thresh, start, step;
        output Integer boundary = thresh + mod(start - thresh, step);
      end lowerBoundary;
    algorithm
      if within_range then
        // the threshold is within the range, intercept it
        if at_end then
          // interception at the end does not have to be truncated to the fitting part
          range := Expression.makeRange(Expression.INTEGER(start), SOME(Expression.INTEGER(step)), Expression.INTEGER(thresh));
        else
          // interception at the start has to compute the correct lower boundary
          range := Expression.makeRange(Expression.INTEGER(lowerBoundary(thresh, start, step)), SOME(Expression.INTEGER(step)), Expression.INTEGER(stop));
        end if;
      elseif func(if at_end then stop else start, thresh) then
        // the threshold leads to an empty range, otherwise leave it as it was
        range := Expression.makeRange(Expression.INTEGER(0), SOME(Expression.INTEGER(0)), Expression.INTEGER(0));
      end if;
    end interceptRange;

    function adaptArray
      input output Expression array;
      input Expression rhs;
      input Operator operator;
    protected
      Integer thresh;
      list<Integer> elems;
    algorithm
      // extract the primitive type representation
      (thresh, elems) := match (rhs, array)
        case (Expression.INTEGER(thresh), Expression.ARRAY(literal = true)) then (thresh, list(Expression.integerValue(e) for e in array.elements));
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because array range is non literal: " + Expression.toString(array)});
        then fail();
      end match;

      array := match operator.op
        // i == VAL as a condition
        case NFOperator.Op.EQUAL then
          // remove all but this element from the array
          if List.contains(elems, thresh, intEq) then Expression.makeRange(Expression.INTEGER(thresh), NONE(), Expression.INTEGER(thresh))
          // this element is not in the range >>> no valid element
          else Expression.makeRange(Expression.INTEGER(0), SOME(Expression.INTEGER(0)), Expression.INTEGER(0));

        // i <>, <, <=, >, >=  VAL as a condition
        case NFOperator.Op.NEQUAL     then Expression.makeExpArray(listArray(list(Expression.INTEGER(i) for i guard(i <> thresh) in elems)), Type.INTEGER(), true);
        case NFOperator.Op.LESS       then Expression.makeExpArray(listArray(list(Expression.INTEGER(i) for i guard(i < thresh) in elems)), Type.INTEGER(), true);
        case NFOperator.Op.LESSEQ     then Expression.makeExpArray(listArray(list(Expression.INTEGER(i) for i guard(i <= thresh) in elems)), Type.INTEGER(), true);
        case NFOperator.Op.GREATER    then Expression.makeExpArray(listArray(list(Expression.INTEGER(i) for i guard(i > thresh) in elems)), Type.INTEGER(), true);
        case NFOperator.Op.GREATEREQ  then Expression.makeExpArray(listArray(list(Expression.INTEGER(i) for i guard(i >= thresh) in elems)), Type.INTEGER(), true);

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for operator: " + Operator.toDebugString(operator)});
        then fail();
      end match;
    end adaptArray;

    function applyOrder
      input output Iterator iter;
      input UnorderedMap<ComponentRef, EvalOrder> order;
      function applySingleOrder
        input ComponentRef name;
        input output Expression range;
        input UnorderedMap<ComponentRef, EvalOrder> order;
      protected
        EvalOrder eo = UnorderedMap.getOrDefault(name, order, NBResizable.EvalOrder.INDEPENDENT);
        Expression step, res;
        list<Integer> elements;
      algorithm
        range := match range

            // revert a range if needed
            case Expression.RANGE() algorithm
              step := Util.getOptionOrDefault(range.step, Expression.INTEGER(1));
              if (Expression.isNegative(step) and eo == NBResizable.EvalOrder.FORWARD) or (Expression.isPositive(step) and eo == NBResizable.EvalOrder.BACKWARD) then
                res := Expression.revertRange(range);
              else
                res := range;
              end if;
            then res;

            // revert an array/list if needed
            case Expression.ARRAY(literal = true) algorithm
              if eo == NBResizable.EvalOrder.FORWARD then
                elements := list(Expression.getInteger(e) for e in range.elements);
                range.elements := listArray(list(Expression.INTEGER(e) for e in List.sort(elements, intGt)));
              elseif eo == NBResizable.EvalOrder.BACKWARD then
                elements := list(Expression.getInteger(e) for e in range.elements);
                range.elements := listArray(list(Expression.INTEGER(e) for e in List.sort(elements, intLt)));
              end if;
            then range;

            // no other allowed
            else algorithm
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for unhandled range expression: " + Expression.toString(range)});
            then fail();
          end match;
      end applySingleOrder;
    algorithm
      iter := match iter
        case SINGLE() algorithm
          iter.range := applySingleOrder(iter.name, iter.range, order);
        then iter;
        case NESTED() algorithm
          for i in 1:arrayLength(iter.names) loop
            iter.ranges[i] := applySingleOrder(iter.names[i], iter.ranges[i], order);
          end for;
        then iter;
        else iter;
      end match;
    end applyOrder;

    function toString
      input Iterator iter;
      output String str = "";
    protected
      function singleStr
        input ComponentRef name;
        input Expression range;
        input Option<Iterator> map;
        output String str = ComponentRef.toString(name) + " in " + Expression.toString(range);
      protected
        list<ComponentRef> names;
      algorithm
        if Util.isSome(map) then
          (names, _) := getFrames(Util.getOption(map));
          str := str + " (" + ComponentRef.toString(listHead(names)) + ")";
        end if;
      end singleStr;
    algorithm
      str := match iter
        case SINGLE() then singleStr(iter.name, iter.range, iter.map);
        case NESTED() then "{" + stringDelimitList(list(singleStr(iter.names[i], iter.ranges[i], iter.maps[i]) for i in 1:arrayLength(iter.names)), ", ") + "}";
        case EMPTY()  then "<EMPTY ITERATOR>";
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for an unknown reason."});
        then fail();
      end match;
    end toString;

    function map
      "Traverses all expressions of the iterator range and applies a function to it."
      input output Iterator iter;
      input MapFuncExp funcExp;
      input Option<MapFuncCref> funcCrefOpt = NONE();
      input MapFuncExpWrapper mapFunc;
    protected
      MapFuncCref funcCref;
    algorithm
      iter := match iter
        case SINGLE() algorithm
          if Util.isSome(funcCrefOpt) then
            funcCref := Util.getOption(funcCrefOpt);
            iter.name := funcCref(iter.name);
          end if;
          iter.range := mapFunc(iter.range, funcExp);
        then iter;

        case NESTED() algorithm
          if Util.isSome(funcCrefOpt) then
            funcCref := Util.getOption(funcCrefOpt);
            for i in 1:arrayLength(iter.names) loop
              iter.names[i] := funcCref(iter.names[i]);
            end for;
          end if;
          for i in 1:arrayLength(iter.ranges) loop
            iter.ranges[i] := mapFunc(iter.ranges[i], funcExp);
          end for;
        then iter;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for an unknown reason."});
        then fail();
      end match;
    end map;
  end Iterator;

  uniontype Equation
    record SCALAR_EQUATION
      Type ty                         "equality type";
      Expression lhs                  "left hand side expression";
      Expression rhs                  "right hand side expression";
      DAE.ElementSource source        "origin of equation";
      EquationAttributes attr         "Additional Attributes";
    end SCALAR_EQUATION;

    record ARRAY_EQUATION
      Type ty                         "equality type containing dimensions";
      Expression lhs                  "left hand side expression";
      Expression rhs                  "right hand side expression";
      DAE.ElementSource source        "origin of equation";
      EquationAttributes attr         "Additional Attributes";
      Option<Integer> recordSize      "NONE() if not a record";
    end ARRAY_EQUATION;

    record RECORD_EQUATION
      Type ty                         "equality type";
      Expression lhs                  "left hand side expression";
      Expression rhs                  "right hand side expression";
      DAE.ElementSource source        "origin of equation";
      EquationAttributes attr         "Additional Attributes";
      Integer recordSize              "size of the record";
    end RECORD_EQUATION;

    record ALGORITHM
      Integer size                    "output size";
      Algorithm alg                   "Algorithm statements";
      DAE.ElementSource source        "origin of algorithm";
      DAE.Expand expand               "this algorithm was translated from an equation. we should not expand array crefs!";
      EquationAttributes attr         "Additional Attributes";
    end ALGORITHM;

    record IF_EQUATION
      Integer size                    "size of equation";
      IfEquationBody body             "Actual equation body";
      DAE.ElementSource source        "origin of equation";
      EquationAttributes attr         "Additional Attributes";
    end IF_EQUATION;

    record FOR_EQUATION
      Integer size                    "size of equation";
      Iterator iter                   "list of all: <iterator, range>";
      list<Equation> body             "iterated equations (only multiples if entwined)";
      DAE.ElementSource source        "origin of equation";
      EquationAttributes attr         "Additional Attributes";
    end FOR_EQUATION;

    record WHEN_EQUATION
      Integer size                    "size of equation";
      WhenEquationBody body           "Actual equation body";
      DAE.ElementSource source        "origin of equation";
      EquationAttributes attr         "Additional Attributes";
    end WHEN_EQUATION;

    record AUX_EQUATION
      "Auxiliary equations are generated when auxiliary variables are generated
      that are known to always be solved in this specific equation. E.G. $CSE
      The variable binding contains the equation, but this equation is also
      allowed to have a body for special cases."
      Pointer<Variable> auxiliary     "Corresponding auxiliary variable";
      Option<Equation> body           "Optional body equation"; // -> Expression
    end AUX_EQUATION;

    record DUMMY_EQUATION
    end DUMMY_EQUATION;

    function toString
      input Equation eq;
      input output String str = "";
    protected
      String s = "(" + intString(Equation.size(Pointer.create(eq), true)) + ")";
      String tupl_recd_str;
    algorithm
      str := match eq
        case SCALAR_EQUATION() then str + "[SCAL] " + s + " " + Expression.toString(eq.lhs) + " = " + Expression.toString(eq.rhs) + EquationAttributes.toString(eq.attr, " ");
        case ARRAY_EQUATION()  then str + "[ARRY] " + s + " " + Expression.toString(eq.lhs) + " = " + Expression.toString(eq.rhs) + EquationAttributes.toString(eq.attr, " ");
        case RECORD_EQUATION() algorithm
          tupl_recd_str := if Type.isTuple(eq.ty) then "[TUPL] " else "[RECD] ";
        then str + tupl_recd_str + s + " " + Expression.toString(eq.lhs) + " = " + Expression.toString(eq.rhs) + EquationAttributes.toString(eq.attr, " ");
        case ALGORITHM()       then str + "[ALGO] " + s + EquationAttributes.toString(eq.attr, " ") + "\n" + Algorithm.toString(eq.alg, str + "[----] ");
        case IF_EQUATION()     then str + IfEquationBody.toString(eq.body, str + "[----] ", "[-IF-] " + s + EquationAttributes.toString(eq.attr, " ") + "\n");
        case FOR_EQUATION()    then str + forEquationToString(eq.iter, eq.body, "", str + "[----] ", "[FOR-] " + s + EquationAttributes.toString(eq.attr, " "));
        case WHEN_EQUATION()   then str + WhenEquationBody.toString(eq.body, str + "[----] ", "[WHEN] " + s + EquationAttributes.toString(eq.attr, " ") + "\n");
        case AUX_EQUATION()    then str + "[AUX-] " + s + "Auxiliary equation for " + Variable.toString(Pointer.access(eq.auxiliary));
        case DUMMY_EQUATION()  then str + "[DUMY] (0) Dummy equation.";
        else                        str + "[FAIL] (0) " + getInstanceName() + " failed!";
      end match;
    end toString;

    function pointerToString
      input Pointer<Equation> eqn_ptr;
      input output String str = "";
    algorithm
      str := toString(Pointer.access(eqn_ptr), str);
    end pointerToString;

    function source
      input Equation eq;
      output DAE.ElementSource src;
    algorithm
      src := match eq
        case SCALAR_EQUATION() then eq.source;
        case ARRAY_EQUATION()  then eq.source;
        case RECORD_EQUATION() then eq.source;
        case ALGORITHM()       then eq.source;
        case IF_EQUATION()     then eq.source;
        case FOR_EQUATION()    then eq.source;
        case WHEN_EQUATION()   then eq.source;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for:\n" + toString(eq)});
        then fail();
      end match;
    end source;

    function info
      input Equation eq;
      output SourceInfo info = ElementSource.getInfo(source(eq));
    end info;

    function size
      input Pointer<Equation> eqn_ptr;
      input Boolean resize = false;
      output Integer s;
    protected
      Equation eqn;
    algorithm
      eqn := Pointer.access(eqn_ptr);
      s := match eqn
        local
          Equation body;
        case SCALAR_EQUATION()            then 1;
        case ARRAY_EQUATION()             then Type.sizeOf(eqn.ty, resize);
        case RECORD_EQUATION()            then Type.sizeOf(eqn.ty, resize);
        case ALGORITHM()                  then eqn.size;
        case IF_EQUATION()                then if resize then IfEquationBody.size(eqn.body, resize) else eqn.size;
        case FOR_EQUATION(body = {body})  then if resize then Iterator.size(eqn.iter, resize) * Equation.size(Pointer.create(body), resize) else eqn.size;
        case WHEN_EQUATION()              then if resize then WhenEquationBody.size(eqn.body, resize) else eqn.size;
        case AUX_EQUATION()               then Variable.size(Pointer.access(eqn.auxiliary), resize);
        case DUMMY_EQUATION()             then 0;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for:\n" + toString(eqn)});
        then fail();
      end match;
    end size;

    function sizes
      input Pointer<Equation> eqn_ptr;
      input Boolean resize = false;
      output list<Integer> size_lst;
    protected
      Equation eqn;
    algorithm
      eqn := Pointer.access(eqn_ptr);
      size_lst := match eqn
        case SCALAR_EQUATION() then {1};
        case ARRAY_EQUATION()  then {Type.sizeOf(eqn.ty, resize)}; //needs to be updated to represent the dimensions
        case RECORD_EQUATION() then {Type.sizeOf(eqn.ty, resize)};
        case ALGORITHM()       then {eqn.size};
        case IF_EQUATION()     then {eqn.size};
        case FOR_EQUATION()    then listReverse(Iterator.sizes(eqn.iter, resize)); // does only consider frames and not conditions
        case WHEN_EQUATION()   then {eqn.size};
        case AUX_EQUATION()    then {Variable.size(Pointer.access(eqn.auxiliary), resize)};
        case DUMMY_EQUATION()  then {};
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for:\n" + toString(eqn)});
        then fail();
      end match;
    end sizes;

    function applyToType
      input output Pointer<Equation> eqn_ptr;
      input typeFunc func;
      partial function typeFunc
        input output Type ty;
      end typeFunc;
    protected
      Equation new, eqn = Pointer.access(eqn_ptr);
    algorithm
      new := match eqn
        case new as ARRAY_EQUATION()  algorithm new.ty := func(new.ty); then new;
        case new as RECORD_EQUATION() algorithm new.ty := func(new.ty); then new;
        else eqn;
      end match;
      if not referenceEq(eqn, new) then
        Pointer.update(eqn_ptr, new);
      end if;
    end applyToType;

    function hash
      "only hashes the name"
      input Pointer<Equation> eqn;
      output Integer i = if isDummy(Pointer.access(eqn)) then 0 else ComponentRef.hash(getEqnName(eqn));
    end hash;

    function equalName
      input Pointer<Equation> eqn1;
      input Pointer<Equation> eqn2;
      output Boolean b = ComponentRef.isEqual(getEqnName(eqn1), getEqnName(eqn2));
    end equalName;

    function isEqualPtrTpl
      input tuple<EquationPointer, EquationPointer> tpl;
      output Boolean b;
    protected
      EquationPointer eqn1, eqn2;
    algorithm
      (eqn1, eqn2) := tpl;
      b := isEqualPtr(eqn1, eqn2);
    end isEqualPtrTpl;

    function isEqualPtr
      input Pointer<Equation> eqn1;
      input Pointer<Equation> eqn2;
      output Boolean b = isEqual(Pointer.access(eqn1), Pointer.access(eqn2));
    end isEqualPtr;

    function isEqualTpl
      input tuple<Equation, Equation> tpl;
      output Boolean b;
    protected
      Equation eqn1, eqn2;
    algorithm
      (eqn1, eqn2) := tpl;
      b := isEqual(eqn1, eqn2);
    end isEqualTpl;

    function isEqual
      input Equation eqn1;
      input Equation eqn2;
      output Boolean b;
    algorithm
      b := match (eqn1, eqn2)
        case (SCALAR_EQUATION(), SCALAR_EQUATION()) then Expression.isEqual(eqn1.lhs, eqn2.lhs) and Expression.isEqual(eqn1.rhs, eqn2.rhs);
        case (ARRAY_EQUATION(), ARRAY_EQUATION())   then Expression.isEqual(eqn1.lhs, eqn2.lhs) and Expression.isEqual(eqn1.rhs, eqn2.rhs);
        case (RECORD_EQUATION(), RECORD_EQUATION()) then Expression.isEqual(eqn1.lhs, eqn2.lhs) and Expression.isEqual(eqn1.rhs, eqn2.rhs);
        case (ALGORITHM(), ALGORITHM())             then Algorithm.isEqual(eqn1.alg, eqn2.alg);
        case (IF_EQUATION(), IF_EQUATION())         then IfEquationBody.isEqual(eqn1.body, eqn2.body);
        case (FOR_EQUATION(), FOR_EQUATION())       then Iterator.isEqual(eqn1.iter, eqn2.iter) and List.all(list(isEqual(b1, b2) threaded for b1 in eqn1.body, b2 in eqn2.body), Util.id);
        case (WHEN_EQUATION(), WHEN_EQUATION())     then WhenEquationBody.isEqual(eqn1.body, eqn2.body);
        case (AUX_EQUATION(), AUX_EQUATION())       then BVariable.equalName(eqn1.auxiliary, eqn2.auxiliary) and Util.optionEqual(eqn1.body, eqn2.body, isEqual);
        case (DUMMY_EQUATION(), DUMMY_EQUATION())   then true;
        else false;
      end match;
    end isEqual;

    function getEqnName
      input Pointer<Equation> eqn;
      output ComponentRef name;
    protected
      Pointer<Variable> residualVar;
    algorithm
      if isDummy(Pointer.access(eqn)) then
        name := ComponentRef.EMPTY();
      else
        residualVar := getResidualVar(eqn);
        name := BVariable.getVarName(residualVar);
      end if;
    end getEqnName;

    function getResidualVar
      input Pointer<Equation> eqn;
      output Pointer<Variable> residualVar;
    algorithm
      try
        residualVar := EquationAttributes.getResidualVar(getAttributes(Pointer.access(eqn)));
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of missing residual variable."});
        fail();
      end try;
    end getResidualVar;

    function getSolvedVar
      input Equation eqn;
      output Variable var;
    algorithm
      var := match eqn
        local
          ComponentRef cref;
        case SCALAR_EQUATION(lhs = Expression.CREF(cref = cref))  then BVariable.getVar(cref, sourceInfo());
        case ARRAY_EQUATION(lhs = Expression.CREF(cref = cref))   then BVariable.getVar(cref, sourceInfo());
        case RECORD_EQUATION(lhs = Expression.CREF(cref = cref))  then BVariable.getVar(cref, sourceInfo());
        else NBVariable.DUMMY_VARIABLE;
      end match;
    end getSolvedVar;

    function makeAssignment
      input Expression lhs;
      input Expression rhs;
      input Pointer<Integer> idx;
      input String str;
      input Iterator iter;
      input EquationAttributes attr;
      output Pointer<Equation> eq;
    protected
      Equation e;
    algorithm
      e := makeAssignmentEqn(lhs, rhs, iter, attr);
      eq := Pointer.create(e);
      createName(eq, idx, str);
    end makeAssignment;

    function makeAssignmentUpdate
      input output Equation eq;
      input Expression lhs;
      input Expression rhs;
      input Iterator iter;
      input EquationAttributes attr;
    protected
      Pointer<Variable> res_var = Equation.getResidualVar(Pointer.create(eq));
    algorithm
      eq := makeAssignmentEqn(lhs, rhs, iter, attr);
      eq := Equation.setResidualVar(eq, res_var);
    end makeAssignmentUpdate;

    function makeAssignmentEqn
      input Expression lhs;
      input Expression rhs;
      input Iterator iter;
      input EquationAttributes attr;
      output Equation e;
    protected
      Type ty = Expression.typeOf(lhs);
    algorithm
      e := match ty
        case Type.ARRAY() then ARRAY_EQUATION(
            ty          = ty,
            lhs         = lhs,
            rhs         = rhs,
            source      = DAE.emptyElementSource,
            attr        = attr,
            recordSize  = NONE()
          );
        case Type.TUPLE() then RECORD_EQUATION(
            ty          = ty,
            lhs         = lhs,
            rhs         = rhs,
            source      = DAE.emptyElementSource,
            attr        = attr,
            recordSize  = Type.sizeOf(ty)
          );
        case Type.COMPLEX() then RECORD_EQUATION(
            ty          = ty,
            lhs         = lhs,
            rhs         = rhs,
            source      = DAE.emptyElementSource,
            attr        = attr,
            recordSize  = Type.sizeOf(ty)
          );
        else SCALAR_EQUATION(
            ty      = ty,
            lhs     = lhs,
            rhs     = rhs,
            source  = DAE.emptyElementSource,
            attr    = attr
          );
      end match;
      // create for-loop around it if there is an iterator
      if not Iterator.isEmpty(iter) then
        e := FOR_EQUATION(
          size    = Type.sizeOf(ty) * Iterator.size(iter),
          iter    = iter,
          body    = {e},
          source  = DAE.emptyElementSource,
          attr    = attr
        );
        // inline if it has size 1
        e := Inline.inlineForEquation(e);
      end if;
    end makeAssignmentEqn;

    function makeAlgorithm
      input list<Statement> stmts;
      input Boolean init;
      output Pointer<Equation> eqn;
    protected
      Algorithm alg;
    algorithm
      alg := Algorithm.ALGORITHM(stmts, {}, {}, InstNode.EMPTY_NODE(), DAE.emptyElementSource);
      alg := Algorithm.setInputsOutputs(alg);
      eqn := BackendDAE.lowerAlgorithm(alg, init);
    end makeAlgorithm;

    function forEquationToString
      input Iterator iter             "the iterator variable(s)";
      input list<Equation> body       "iterated equations";
      input output String str = "";
      input String indent = "";
      input String indicator = "";
    protected
      String iterators;
    algorithm
      str := str + indicator + "\n";
      str := str + indent + "for " + Iterator.toString(iter) + " loop\n";
      for eqn in body loop
        str := str + toString(eqn, indent + "  ") + "\n";
      end for;
      str := str + indent + "end for;";
    end forEquationToString;

    function getAttributes
      input Equation eq;
      output EquationAttributes attr;
    algorithm
      attr := match eq
        local
          Equation body;
        case SCALAR_EQUATION()                then eq.attr;
        case ARRAY_EQUATION()                 then eq.attr;
        case RECORD_EQUATION()                then eq.attr;
        case ALGORITHM()                      then eq.attr;
        case IF_EQUATION()                    then eq.attr;
        case FOR_EQUATION()                   then eq.attr;
        case WHEN_EQUATION()                  then eq.attr;
        case AUX_EQUATION(body = SOME(body))  then getAttributes(body);
                                              else EquationAttributes.default(EquationKind.UNKNOWN, false);
      end match;
    end getAttributes;

    function setAttributes
      input output Equation eq;
      input EquationAttributes attr;
    algorithm
      eq := match eq
        local
          EquationAttributes tmp;
          Equation body;
        case SCALAR_EQUATION()  algorithm eq.attr := attr; then eq;
        case ARRAY_EQUATION()   algorithm eq.attr := attr; then eq;
        case RECORD_EQUATION()  algorithm eq.attr := attr; then eq;
        case ALGORITHM()        algorithm eq.attr := attr; then eq;
        case IF_EQUATION()      algorithm eq.attr := attr; then eq;
        case FOR_EQUATION()     algorithm eq.attr := attr; then eq;
        case WHEN_EQUATION()    algorithm eq.attr := attr; then eq;
        case AUX_EQUATION(body = SOME(body)) algorithm eq.body := SOME(setAttributes(body, attr)); then eq;
      end match;
    end setAttributes;

    function setKind
      input output Equation eq;
      input EquationKind kind;
      input Option<Integer> clock_idx = NONE();
    algorithm
      eq := match eq
        local
          EquationAttributes tmp;
          Equation body;
        case SCALAR_EQUATION()  algorithm eq.attr := EquationAttributes.setKind(eq.attr, kind, clock_idx); then eq;
        case ARRAY_EQUATION()   algorithm eq.attr := EquationAttributes.setKind(eq.attr, kind, clock_idx); then eq;
        case RECORD_EQUATION()  algorithm eq.attr := EquationAttributes.setKind(eq.attr, kind, clock_idx); then eq;
        case ALGORITHM()        algorithm eq.attr := EquationAttributes.setKind(eq.attr, kind, clock_idx); then eq;
        case IF_EQUATION()      algorithm eq.attr := EquationAttributes.setKind(eq.attr, kind, clock_idx); then eq;
        case FOR_EQUATION()     algorithm eq.attr := EquationAttributes.setKind(eq.attr, kind, clock_idx); then eq;
        case WHEN_EQUATION()    algorithm eq.attr := EquationAttributes.setKind(eq.attr, kind, clock_idx); then eq;
        case AUX_EQUATION(body = SOME(body)) algorithm eq.body := SOME(setKind(body, kind, clock_idx)); then eq;
      end match;
    end setKind;

    function getSource
      input Equation eq;
      output DAE.ElementSource source;
    algorithm
      source := match eq
        local
          Equation body;
        case SCALAR_EQUATION()                then eq.source;
        case ARRAY_EQUATION()                 then eq.source;
        case RECORD_EQUATION()                then eq.source;
        case ALGORITHM()                      then eq.source;
        case IF_EQUATION()                    then eq.source;
        case FOR_EQUATION()                   then eq.source;
        case WHEN_EQUATION()                  then eq.source;
        case AUX_EQUATION(body = SOME(body))  then getSource(body);
                                              else DAE.emptyElementSource;
      end match;
    end getSource;

    function setDerivative
      input output Equation eq;
      input Pointer<Equation> derivative;
    protected
      EquationAttributes attr;
    algorithm
      attr := getAttributes(eq);
      attr.derivative := SOME(derivative);
      eq := setAttributes(eq, attr);
    end setDerivative;

    function map
      "Traverses all expressions of the equations and applies a function to it.
      Optional second input to also traverse crefs, only needed for simple
      eqns, when eqns and algorithms."
      input output Equation eq;
      input MapFuncExp funcExp;
      input Option<MapFuncCref> funcCrefOpt = NONE();
      input MapFuncExpWrapper mapFunc = Expression.map;
    algorithm
      eq := match eq
        local
          Equation body;
          MapFuncCref funcCref;
          Expression lhs, rhs;
          Iterator iter;
          ComponentRef lhs_cref, rhs_cref;
          Algorithm alg;
          IfEquationBody ifEqBody;
          WhenEquationBody whenEqBody;
          Equation body, new_body;

        case SCALAR_EQUATION() algorithm
          lhs := mapFunc(eq.lhs, funcExp);
          rhs := mapFunc(eq.rhs, funcExp);
          if not referenceEq(lhs, eq.lhs) then
            eq.lhs := lhs;
          end if;
          if not referenceEq(rhs, eq.rhs) then
            eq.rhs := rhs;
          end if;
        then eq;

        case ARRAY_EQUATION() algorithm
          lhs := mapFunc(eq.lhs, funcExp);
          rhs := mapFunc(eq.rhs, funcExp);
          if not referenceEq(lhs, eq.lhs) then
            eq.lhs := lhs;
          end if;
          if not referenceEq(rhs, eq.rhs) then
            eq.rhs := rhs;
          end if;
        then eq;

        case RECORD_EQUATION() algorithm
          lhs := mapFunc(eq.lhs, funcExp);
          rhs := mapFunc(eq.rhs, funcExp);
          if not referenceEq(lhs, eq.lhs) then
            eq.lhs := lhs;
          end if;
          if not referenceEq(rhs, eq.rhs) then
            eq.rhs := rhs;
          end if;
        then eq;

        case ALGORITHM() algorithm
          // pass mapFunc because the function itself does not map
          alg := Algorithm.mapExp(eq.alg, function mapFunc(func = funcExp));
          if not referenceEq(alg, eq.alg) then
            eq.alg := Algorithm.setInputsOutputs(alg);
          end if;
        then eq;

        case IF_EQUATION() algorithm
          ifEqBody := IfEquationBody.map(eq.body, funcExp, funcCrefOpt, mapFunc);
          if not referenceEq(ifEqBody, eq.body) then
            eq.body := ifEqBody;
          end if;
        then eq;

        case FOR_EQUATION() algorithm
          iter := Iterator.map(eq.iter, funcExp, funcCrefOpt, mapFunc);
          if not referenceEq(iter, eq.iter) then
            eq.iter := iter;
          end if;
          eq.body := list(map(body_eqn, funcExp, funcCrefOpt, mapFunc) for body_eqn in eq.body);
        then eq;

        case WHEN_EQUATION() algorithm
          whenEqBody := WhenEquationBody.map(eq.body, funcExp, funcCrefOpt, mapFunc);
          if not referenceEq(whenEqBody, eq.body) then
            eq.body := whenEqBody;
          end if;
        then eq;

        case AUX_EQUATION(body = SOME(body)) algorithm
          new_body := map(body, funcExp, funcCrefOpt, mapFunc);
          if not referenceEq(new_body, body) then
            eq.body := SOME(new_body);
          end if;
        then eq;

        case DUMMY_EQUATION() then eq;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because there was no suitable case for: " + toString(eq)});
        then fail();

      end match;
    end map;

    function collectCrefs
      "filters all crefs of an equation and adds them
      to a list of crefs. needs cref filter function."
      input Equation eq;
      input Slice.filterCref filter;
      input MapFuncExpWrapper mapFunc = Expression.map;
      output list<ComponentRef> cref_lst;
    protected
      UnorderedSet<ComponentRef> acc = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    algorithm
      // map with the expression and cref filter functions
      _ := map(eq, function Slice.filterExp(filter = filter, acc = acc),
              SOME(function filter(acc = acc)),
              mapFunc = mapFunc);
      cref_lst := UnorderedSet.toList(acc);
    end collectCrefs;

    function collectFromSet extends Slice.filterCref;
      input UnorderedSet<ComponentRef> check_set;
    algorithm
      if UnorderedSet.contains(cref, check_set) then
        UnorderedSet.add(cref, acc);
      end if;
    end collectFromSet;

    function collectFromMap<T> extends Slice.filterCref;
      input UnorderedMap<ComponentRef, T> check_map;
    algorithm
      if UnorderedMap.contains(cref, check_map) then
        UnorderedSet.add(cref, acc);
      end if;
    end collectFromMap;

    function getLHS
      "gets the left hand side expression of an equation."
      input Equation eq;
      output Expression lhs;
    protected
      Boolean success;
    algorithm
      lhs := match(eq)
        case SCALAR_EQUATION()        then eq.lhs;
        case ARRAY_EQUATION()         then eq.lhs;
        case RECORD_EQUATION()        then eq.lhs;
        case FOR_EQUATION(body = {_}) then getLHS(listHead(eq.body));
        case IF_EQUATION()            algorithm
          (lhs, success) := IfEquationBody.getLHS(eq.body);
          if not success then
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because LHS was ambiguous for: " + toString(eq)});
            fail();
          end if;
        then lhs;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because LHS was ambiguous for: " + toString(eq)});
        then fail();
      end match;
    end getLHS;

    function getRHS
      "gets the right hand side expression of an equation."
      input Equation eq;
      output Expression rhs;
    algorithm
      rhs := match(eq)
        case SCALAR_EQUATION()        then eq.rhs;
        case ARRAY_EQUATION()         then eq.rhs;
        case RECORD_EQUATION()        then eq.rhs;
        case FOR_EQUATION(body = {_}) then getRHS(listHead(eq.body));
        case IF_EQUATION()            then IfEquationBody.getRHS(eq.body);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because RHS was ambiguous for: " + toString(eq)});
        then fail();
      end match;
    end getRHS;

    function setLHS
      "sets the left hand side expression of an equation."
      input output Equation eq;
      input Expression lhs;
    algorithm
      eq := match(eq)
        case SCALAR_EQUATION()  algorithm eq.lhs := lhs; then eq;
        case ARRAY_EQUATION()   algorithm eq.lhs := lhs; then eq;
        case RECORD_EQUATION()  algorithm eq.lhs := lhs; then eq;
        case FOR_EQUATION(body = {_}) algorithm
          eq.body := {setLHS(listHead(eq.body), lhs)};
        then eq;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because LHS " + Expression.toString(lhs) + " could not be set for:\n " + toString(eq)});
        then fail();
      end match;
    end setLHS;

    function setRHS
      "sets the right hand side expression of an equation."
      input output Equation eq;
      input Expression rhs;
    algorithm
      eq := match(eq)
        case SCALAR_EQUATION()  algorithm eq.rhs := rhs; then eq;
        case ARRAY_EQUATION()   algorithm eq.rhs := rhs; then eq;
        case RECORD_EQUATION()  algorithm eq.rhs := rhs; then eq;
        case FOR_EQUATION(body = {_}) algorithm
          eq.body := {setRHS(listHead(eq.body), rhs)};
        then eq;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because RHS could not be set for: " + toString(eq)});
        then fail();
      end match;
    end setRHS;

    function updateLHSandRHS
      input output Equation eqn;
      input Expression lhs;
      input Expression rhs;
    protected
      Type ty;
      EquationAttributes attr = getAttributes(eqn);
      DAE.ElementSource src = source(eqn);
      Option<Integer> opt_rec_size;
      Integer rec_size;
    algorithm
      ty := Expression.typeOf(lhs);
      opt_rec_size := Type.complexSize(ty);
      eqn := match (ty, opt_rec_size)
        case (Type.ARRAY(), _)                then ARRAY_EQUATION(ty, lhs, rhs, src, attr, opt_rec_size);
        case (Type.COMPLEX(), SOME(rec_size)) then RECORD_EQUATION(ty, lhs, rhs, src, attr, rec_size);
                                              else SCALAR_EQUATION(ty, lhs, rhs, src, attr);
      end match;
    end updateLHSandRHS;

    function swapLHSandRHS
      input output Equation eqn;
    algorithm
      eqn := match eqn
        local
          Expression tmpExp;
          ComponentRef tmpCref;

        case SCALAR_EQUATION() algorithm
          tmpExp := eqn.rhs;
          eqn.rhs := eqn.lhs;
          eqn.lhs := tmpExp;
        then eqn;

        case ARRAY_EQUATION() algorithm
          tmpExp := eqn.rhs;
          eqn.rhs := eqn.lhs;
          eqn.lhs := tmpExp;
        then eqn;

        case RECORD_EQUATION() algorithm
          tmpExp := eqn.rhs;
          eqn.rhs := eqn.lhs;
          eqn.lhs := tmpExp;
        then eqn;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + toString(eqn)});
        then fail();
      end match;
    end swapLHSandRHS;

    function simplify
      input output Equation eq;
      input String name = "";
      input String indent = "";
      input Pointer<list<Pointer<Variable>>> acc_discrete_states = Pointer.create({});
      input Pointer<list<Pointer<Variable>>> acc_previous = Pointer.create({});
      input SimplifyFunc simplifyExp = function SimplifyExp.simplifyDump(includeScope = true, name = name, indent = indent);

      partial function SimplifyFunc
        input output Expression exp;
      end SimplifyFunc;
    protected
      // FIXME a polymorphic `apply<TI, TO>` does not work for some reason
      function apply extends MapFuncExpWrapper;
      algorithm
        e := func(e);
      end apply;
      Equation old_eq;
    algorithm
      if Flags.isSet(Flags.DUMP_SIMPLIFY) and not stringEqual(indent, "") then
        print("\n");
      end if;

      // simplify all expressions in the equation
      eq := map(eq, simplifyExp, mapFunc = apply);

      // simplify equation structure
      old_eq := eq;
      eq := match eq
        local
          Equation new_eq;
          WhenEquationBody when_body;
          IfEquationBody if_body;
          Iterator iter;
          Solve.Status status;

        case SCALAR_EQUATION() algorithm
          if Expression.isEqual(eq.lhs, eq.rhs) then
            eq.lhs := Expression.makeZero(eq.ty);
            eq.rhs := Expression.makeZero(eq.ty);
          end if;
        then eq;

        case ARRAY_EQUATION() algorithm
          if Expression.isEqual(eq.lhs, eq.rhs) then
            eq.lhs := Expression.makeZero(eq.ty);
            eq.rhs := Expression.makeZero(eq.ty);
          end if;
        then eq;

        case RECORD_EQUATION() algorithm
          if Expression.isEqual(eq.lhs, eq.rhs) then
            eq.lhs := Expression.makeZero(eq.ty);
            eq.rhs := Expression.makeZero(eq.ty);
          end if;
        then eq;

        case ALGORITHM() algorithm
          eq.alg := SimplifyModel.simplifyAlgorithm(eq.alg);
        then if Algorithm.isEmpty(eq.alg) then Equation.DUMMY_EQUATION() else eq;

        case WHEN_EQUATION() algorithm
          new_eq := match WhenEquationBody.simplify(SOME(eq.body))
            case SOME(when_body) algorithm
              eq.body := when_body;
            then eq;
            else algorithm
              DetectStates.findDiscreteStatesFromWhenBody(eq.body, acc_discrete_states, acc_previous);
            then Equation.DUMMY_EQUATION();
          end match;
        then new_eq;

        case IF_EQUATION() algorithm
          new_eq := match IfEquationBody.simplify(SOME(eq.body))
            case SOME(if_body) algorithm
              if isNone(if_body.else_if) and not List.hasSeveralElements(if_body.then_eqns) then
                // first if-branch is true and has only one equation
                // just replace if-equation with body
                new_eq := Pointer.access(listHead(if_body.then_eqns));
              else
                eq.body := if_body;
                try
                  new_eq := IfEquationBody.inline(if_body, eq);
                else
                  new_eq := eq;
                end try;
              end if;
            then new_eq;
            else Equation.DUMMY_EQUATION();
          end match;
        then new_eq;

        // for equation with a single if-body without else-if.
        // structurally ambiguous of size, the if-condition and the for-loop have to be combined
        case FOR_EQUATION(body = {IF_EQUATION(body = if_body as IfEquationBody.IF_EQUATION_BODY(else_if = NONE()))}) algorithm
          (iter, status) := Iterator.simplifyRangeCondition(eq.iter, if_body.condition);
          if status == NBSolve.Status.EXPLICIT then
            eq.iter := iter;
            eq.body := list(Pointer.access(be) for be in if_body.then_eqns);
            eq.size := Equation.size(Pointer.create(eq), true);
          end if;
        then Inline.inlineForEquation(eq);

        case FOR_EQUATION() then Inline.inlineForEquation(eq);
        case AUX_EQUATION() then eq;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed for: " + toString(eq)});
        then fail();
      end match;

      if Flags.isSet(Flags.DUMP_SIMPLIFY) and not isEqual(old_eq, eq) then
        print(indent + "### dumpSimplify | " + name + " ###\n");
        print(indent + "[BEFORE]\n" + toString(old_eq, indent + "  ") + "\n");
        print(indent + "[AFTER ]\n" + toString(eq, indent + "  ") + "\n\n");
      end if;
    end simplify;

    function createName
      input Pointer<Equation> eqn_ptr;
      input Pointer<Integer> idx;
      input String context;
    protected
      Equation eqn = Pointer.access(eqn_ptr);
      Pointer<Variable> residualVar;
      list<Pointer<Equation>> dummy_eqns;
    algorithm
      // create residual var as name
      (residualVar, _) := BVariable.makeResidualVar(context, Pointer.access(idx), getType(eqn));
      Pointer.update(idx, Pointer.access(idx) + 1);
      eqn := setResidualVar(eqn, residualVar);
      eqn := match eqn
        case IF_EQUATION() algorithm
          IfEquationBody.createNames(eqn.body, idx, context);
        then eqn;
        case FOR_EQUATION() algorithm
          // ToDo: multiple body equations require sub indexing - should not happen!
          dummy_eqns := list(Pointer.create(body_eqn) for body_eqn in eqn.body);
          for body_eqn in dummy_eqns loop createName(body_eqn, idx, context); end for;
          eqn.body := list(Pointer.access(body_eqn) for body_eqn in dummy_eqns);
        then eqn;
        else eqn;
      end match;
      Pointer.update(eqn_ptr, eqn);
    end createName;

    function setResidualVar
      input output Equation eqn;
      input Pointer<Variable> residualVar;
    algorithm
       // update equation attributes
      eqn := match eqn
        case SCALAR_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case ARRAY_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case RECORD_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case ALGORITHM() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case IF_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case FOR_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case WHEN_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for\n" + toString(eqn)});
        then fail();
      end match;
    end setResidualVar;

    function subIdxName
      input Pointer<Equation> eqn_ptr;
      input Pointer<Integer> idx;
    protected
      Equation eqn = Pointer.access(eqn_ptr);
      Pointer<Variable> residualVar;
    algorithm
      // update equation attributes
      eqn := match eqn
        case SCALAR_EQUATION() algorithm
          residualVar := EquationAttributes.getResidualVar(eqn.attr);
          residualVar := BVariable.subIdxName(residualVar, idx);
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case ARRAY_EQUATION() algorithm
          residualVar := EquationAttributes.getResidualVar(eqn.attr);
          residualVar := BVariable.subIdxName(residualVar, idx);
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case RECORD_EQUATION() algorithm
          residualVar := EquationAttributes.getResidualVar(eqn.attr);
          residualVar := BVariable.subIdxName(residualVar, idx);
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case ALGORITHM() algorithm
          residualVar := EquationAttributes.getResidualVar(eqn.attr);
          residualVar := BVariable.subIdxName(residualVar, idx);
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case IF_EQUATION() algorithm
          residualVar := EquationAttributes.getResidualVar(eqn.attr);
          residualVar := BVariable.subIdxName(residualVar, idx);
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case FOR_EQUATION() algorithm
          residualVar := EquationAttributes.getResidualVar(eqn.attr);
          residualVar := BVariable.subIdxName(residualVar, idx);
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case WHEN_EQUATION() algorithm
          residualVar := EquationAttributes.getResidualVar(eqn.attr);
          residualVar := BVariable.subIdxName(residualVar, idx);
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for\n" + toString(eqn)});
        then fail();

      end match;
      Pointer.update(idx, Pointer.access(idx) + 1);
      Pointer.update(eqn_ptr, eqn);
    end subIdxName;

    function createResidual
      "Creates a residual equation from a regular equation.
      Example (for DAEMode): $RES_DAE_idx := rhs."
      input output Pointer<Equation> eqn_ptr;
      input Boolean new = false               "set to true if the resulting pointer should be a new one";
    protected
      Equation eqn = Pointer.access(eqn_ptr);
      EquationAttributes attr;
      ComponentRef residualCref;
      Expression lhs, rhs;
    algorithm
      // leave immediately if its already in residual form
      if isResidual(eqn_ptr) then
        return;
      else
        attr := getAttributes(eqn);
        attr.residual := true;
        eqn := setAttributes(eqn, attr);
      end if;

      // TODO: future improvement - save the residual in [INI] -> re-use for [ODE] tearing
      // get name cref which is the residual
      residualCref := match eqn
        local
          list<Subscript> subs;
        case FOR_EQUATION() algorithm
          residualCref := getEqnName(eqn_ptr);
          subs := Iterator.normalizedSubscripts(eqn.iter);
          subs := listAppend(List.fill(Subscript.WHOLE(), Type.dimensionCount(Equation.getType(listHead(eqn.body)))), subs);
          residualCref := ComponentRef.setSubscripts(subs, residualCref);
        then residualCref;
        else getEqnName(eqn_ptr);
      end match;

      eqn := match eqn
        case IF_EQUATION() algorithm
          eqn.body := IfEquationBody.createResidual(eqn.body, residualCref);
        then IfEquationBody.inline(eqn.body, eqn);
        else algorithm
          // update RHS and LHS
          lhs := Expression.fromCref(residualCref);
          rhs := getResidualExp(eqn);
          eqn := setLHS(eqn, lhs);
          eqn := setRHS(eqn, rhs);
        then eqn;
      end match;

      // update pointer or create new
      if new then eqn_ptr := Pointer.create(eqn); else Pointer.update(eqn_ptr, eqn); end if;
    end createResidual;

    function getResidualExp
      input Equation eqn;
      output Expression exp;
    algorithm
      exp := match eqn
        local
          Operator operator;
          InstNode cls_node;
          Class cls;

        case SCALAR_EQUATION() algorithm
          operator := Operator.OPERATOR(Expression.typeOf(eqn.lhs), NFOperator.Op.ADD);
        then Expression.MULTARY({eqn.rhs}, {eqn.lhs}, operator);

        case ARRAY_EQUATION()  algorithm
          operator := Operator.OPERATOR(Expression.typeOf(eqn.lhs), NFOperator.Op.ADD_EW);
        then Expression.MULTARY({eqn.rhs}, {eqn.lhs}, operator);

        case RECORD_EQUATION(ty = Type.COMPLEX(cls = cls_node)) algorithm
          // check if additive inverses exist
          cls := InstNode.getClass(cls_node);
          for op in {"'+'", "'0'", "'-'"} loop
            if not Class.hasOperator(op, cls) then
              Error.addMessage(Error.INTERNAL_ERROR,
                {"Trying to construct residual expression of type " + Type.toString(eqn.ty)
                 + " for equation " + toString(eqn) + " but operator " + op + " is not defined."});
              fail();
            end if;
          end for;
          operator := Operator.OPERATOR(Expression.typeOf(eqn.lhs), NFOperator.Op.ADD);
        then Expression.MULTARY({eqn.rhs}, {eqn.lhs}, operator);

        // returns innermost residual!
        // Ambiguous for entwined for loops!
        case FOR_EQUATION(body = {_}) then getResidualExp(listHead(eqn.body));

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for:\n" + toString(eqn)});
        then fail();
      end match;
      exp := SimplifyExp.simplifyDump(exp, true, getInstanceName());
    end getResidualExp;

    function getType
      input Equation eq;
      input Boolean skipIterator = false;
      output Type ty;
    algorithm
      ty := match eq
        case SCALAR_EQUATION()  then eq.ty;
        case ARRAY_EQUATION()   then eq.ty;
        case RECORD_EQUATION()  then eq.ty;
        case FOR_EQUATION()     algorithm
          ty := getType(listHead(eq.body));
          if not skipIterator then
            ty := Type.liftArrayRightList(ty, Iterator.dimensions(eq.iter));
          end if;
        then ty;
        case WHEN_EQUATION()    then WhenEquationBody.getType(eq.body);
                                else Type.REAL(); // TODO: WRONG there should not be an else case
      end match;
    end getType;

    function getForIterator
      "does not work for algorithms"
      input Equation eqn;
      output Iterator iterator;
    algorithm
      iterator := match eqn
        case FOR_EQUATION() then eqn.iter;
        else Iterator.EMPTY();
      end match;
    end getForIterator;

    function getForFrames
      input Equation eqn;
      output list<Frame> frames;
    algorithm
      frames := match eqn
        local
          list<ComponentRef> names;
          list<Expression> ranges;
          list<Option<Iterator>> maps;

        case FOR_EQUATION() algorithm
          (names, ranges, maps) := Iterator.getFrames(eqn.iter);
        then List.zip3(names, ranges, maps);

        else {};
      end match;
    end getForFrames;

    function applyForOrder
      input output Equation eqn;
      input UnorderedMap<ComponentRef, EvalOrder> order;
    algorithm
      eqn := match eqn
        case FOR_EQUATION() algorithm
          eqn.iter := Iterator.applyOrder(eqn.iter, order);
        then eqn;
        else eqn;
      end match;
    end applyForOrder;

    function isDummy
      input Equation eqn;
      output Boolean b;
    algorithm
      b := match eqn case DUMMY_EQUATION() then true; else false; end match;
    end isDummy;

    function isResidual extends checkEqn;
    protected
      EquationAttributes attr;
    algorithm
      attr := getAttributes(Pointer.access(eqn_ptr));
      b := attr.residual;
    end isResidual;

    function isDiscrete extends checkEqn;
    protected
      EquationAttributes attr;
    algorithm
      attr := getAttributes(Pointer.access(eqn_ptr));
      b := attr.kind == EquationKind.DISCRETE;
    end isDiscrete;

    function isContinuous extends checkEqn;
    protected
      EquationAttributes attr;
    algorithm
      attr := getAttributes(Pointer.access(eqn_ptr));
      b := attr.kind == EquationKind.CONTINUOUS;
    end isContinuous;

    function isInitial extends checkEqn;
    protected
      EquationAttributes attr;
    algorithm
      attr := getAttributes(Pointer.access(eqn_ptr));
      b := attr.exclusively_initial;
    end isInitial;

    function isWhenEquation extends checkEqn;
    protected
      Equation eqn = Pointer.access(eqn_ptr);
    algorithm
      b := match eqn
        case WHEN_EQUATION() then true;
        case FOR_EQUATION() then List.any(list(Pointer.create(e) for e in eqn.body), isWhenEquation);
        else false;
      end match;
    end isWhenEquation;

    function isIfEquation extends checkEqn;
    algorithm
      b := match Pointer.access(eqn_ptr)
        case IF_EQUATION() then true;
        else false;
      end match;
    end isIfEquation;

    function isForEquation extends checkEqn;
    algorithm
      b := match Pointer.access(eqn_ptr)
        case FOR_EQUATION() then true;
        else false;
      end match;
    end isForEquation;

    function isArrayEquation extends checkEqn;
    algorithm
      b := match Pointer.access(eqn_ptr)
        case ARRAY_EQUATION() then true;
        else false;
      end match;
    end isArrayEquation;

    function isRecordOrTupleEquation extends checkEqn;
    algorithm
      b := match Pointer.access(eqn_ptr)
        local
          WhenEquationBody when_body;
          IfEquationBody if_body;

        case RECORD_EQUATION() then true;
        case ARRAY_EQUATION(recordSize = SOME(_)) then true;
        case WHEN_EQUATION(body = when_body)
          then WhenEquationBody.isRecordOrTupleEquation(when_body);
        case IF_EQUATION(body = if_body)
          then IfEquationBody.isRecordOrTupleEquation(if_body);
        else false;
      end match;
    end isRecordOrTupleEquation;

    function isRecordEquation extends checkEqn;
    algorithm
      b := match Pointer.access(eqn_ptr)
        local
          Equation e;
        case e as RECORD_EQUATION() then not Type.isTuple(e.ty);
        case ARRAY_EQUATION(recordSize = SOME(_)) then true;
        else false;
      end match;
    end isRecordEquation;

    function isTupleEquation extends checkEqn;
    algorithm
      b := match Pointer.access(eqn_ptr)
        local
          Equation e;
        case e as RECORD_EQUATION() then Type.isTuple(e.ty);
        else false;
      end match;
    end isTupleEquation;

    function isAlgorithm extends checkEqn;
    algorithm
      b := match Pointer.access(eqn_ptr)
        case ALGORITHM() then true;
        else false;
      end match;
    end isAlgorithm;

    function isParameterEquation
      input Equation eqn;
      output Boolean b = true;
    protected
      Pointer<Boolean> b_ptr = Pointer.create(b);
    algorithm
      map(eqn, function expIsParamOrConst(b_ptr = b_ptr), SOME(function crefIsParamOrConst(b_ptr = b_ptr)));
      b := Pointer.access(b_ptr);
    end isParameterEquation;

    function isClocked extends checkEqn;
    algorithm
      b := match getAttributes(Pointer.access(eqn_ptr))
        case EQUATION_ATTRIBUTES(kind = EquationKind.CLOCKED) then true;
        else false;
      end match;
    end isClocked;

    function expIsParamOrConst
      input output Expression exp;
      input Pointer<Boolean> b_ptr;
    algorithm
      if Pointer.access(b_ptr) then
        () := match exp
          // set b_ptr to false on impure functions
          case Expression.CREF() algorithm
            crefIsParamOrConst(exp.cref, b_ptr);
          then ();
          case Expression.CALL() algorithm
            Pointer.update(b_ptr, Call.isImpure(exp.call));
          then ();
          else ();
        end match;
      end if;
    end expIsParamOrConst;

    function crefIsParamOrConst
      input output ComponentRef cref;
      input Pointer<Boolean> b_ptr;
    algorithm
      if Pointer.access(b_ptr) then
        Pointer.update(b_ptr, BVariable.isParamOrConst(BVariable.getVarPointer(cref, sourceInfo())));
      end if;
    end crefIsParamOrConst;

    function generateBindingEquation
      input Pointer<Variable> var_ptr;
      input Pointer<Integer> idx;
      input Boolean initial_;
      input UnorderedSet<VariablePointer> new_iters;
      output Pointer<Equation> eqn;
    protected
      String context = "BND";
      Variable var;
      Expression lhs, rhs;
      EquationAttributes eqnAttr;
      Iterator iter;
      list<Subscript> subs;
      // maps used to correctly apply subscripts
      UnorderedMap<list<Dimension>, CrefLst> dims_map = UnorderedMap.new<CrefLst>(Dimension.hashList, function List.isEqualOnTrue(inCompFunc = Dimension.isEqual));
      UnorderedMap<ComponentRef, Subscript> iter_map = UnorderedMap.new<Subscript>(ComponentRef.hash, ComponentRef.isEqual);
    algorithm
      var := Pointer.access(var_ptr);
      rhs := match var.binding
        local
          Binding qual;
          Option<Expression> start;
        case qual as Binding.TYPED_BINDING()    then qual.bindingExp;
        case qual as Binding.UNTYPED_BINDING()  then qual.bindingExp;
        case qual as Binding.FLAT_BINDING()     then qual.bindingExp;
        case qual as Binding.UNBOUND() algorithm
          start := VariableAttributes.getStartAttribute(var.backendinfo.attributes);
        then Util.getOptionOrDefault(start, Expression.makeZero(ComponentRef.getSubscriptedType(var.name, true)));
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of wrong binding type: " + Binding.toDebugString(var.binding) + " for variable " + Variable.toString(Pointer.access(var_ptr))});
        then fail();
      end match;

      if BVariable.isClock(var_ptr) then
        eqnAttr := EquationAttributes.default(EquationKind.CLOCKED, initial_, SOME(-1));
      elseif BVariable.isContinuous(var_ptr, initial_) then
        eqnAttr := EquationAttributes.default(EquationKind.CONTINUOUS, initial_);
      else
        eqnAttr := EquationAttributes.default(EquationKind.DISCRETE, initial_);
      end if;

      // simplify rhs and get potential iterators
      (iter, rhs) := Iterator.extract(rhs, new_iters, dims_map);
      rhs := SimplifyExp.simplifyDump(rhs, true, getInstanceName());

      if Iterator.isEmpty(iter) then
        // no iterator -> no for-loop
        lhs := Expression.fromCref(var.name);
        eqn := makeAssignment(lhs, rhs, idx, context, Iterator.EMPTY(), eqnAttr);
      else
        // iterator -> create for loop and add subscripts to lhs
        rhs   := Expression.map(rhs, Expression.repairOperator);
        subs  := Iterator.normalizedSubscripts(iter, iter_map);

        lhs := Expression.fromCref(ComponentRef.mergeSubscriptsMapped(var.name, dims_map, iter_map));
        eqn := makeAssignment(lhs, rhs, idx, context, iter, eqnAttr);
        // this could lead to non existing variables, should not be a problem though
        renameIterators(eqn, "$i");
      end if;
    end generateBindingEquation;

    function mergeIterators
      "do not use on entwined for loops!"
      input output Equation eq;
      input Boolean top_level = true;
      output list<Iterator> acc;
    algorithm
      (eq, acc) := match eq
        local
          Equation body;
        case FOR_EQUATION() algorithm
          (body, acc) := mergeIterators(listHead(eq.body), false);
          acc := eq.iter :: acc;
        then (if top_level then FOR_EQUATION(eq.size, Iterator.merge(acc), {body}, eq.source, eq.attr) else body, acc);
        else (eq, {});
      end match;
    end mergeIterators;

    function splitIterators
      "do not use on entwined for-loops!"
      input output Equation eqn;
    algorithm
      eqn := match eqn
        local
          list<Iterator> iterators;
          Equation body;
        case FOR_EQUATION() algorithm
          // split returns innermost first
          iterators := Iterator.split(eqn.iter);
          body := listHead(eqn.body);
          for iter in iterators loop
            body := FOR_EQUATION(eqn.size, iter, {body}, eqn.source, eqn.attr);
          end for;
        then body;
        else eqn;
      end match;
    end splitIterators;

    function renameIterators
      input Pointer<Equation> eqn_ptr;
      input String newBaseName;
    protected
      Equation eqn = Pointer.access(eqn_ptr);
    algorithm
      _ := match eqn
        local
          UnorderedMap<ComponentRef, Expression> replacements;

        case FOR_EQUATION() algorithm
          replacements := UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
          eqn.iter := Iterator.rename(eqn.iter, newBaseName, replacements);
          eqn.body := list(map(body_eqn, function Replacements.applySimpleExp(replacements = replacements)) for body_eqn in eqn.body);
          Pointer.update(eqn_ptr, eqn);
        then ();

        else ();
      end match;
    end renameIterators;

    function entwine
      input list<Equation> eqn_lst        "has to be for-loops with combinable ranges";
      input Integer nesting_level = 0;
      output list<Equation> entwined = {} "returns a single for-loop on top level if it is possible";
    protected
      Equation eqn1, eqn2, next;
      list<Equation> rest, tmp;
      Iterator intersection, rest1_left, rest1_right, rest2_left, rest2_right;
      String shift = StringUtil.repeat("  ", nesting_level);
    algorithm
      if Flags.isSet(Flags.DUMP_SLICE) then
        print(shift + "[" + intString(nesting_level) + "] ### Entwining following equations:\n"
          + List.toString(eqn_lst, function toString(str = shift + "  "), "", "", "\n", "\n\n"));
      end if;
      eqn1 :: rest := eqn_lst;
      while not listEmpty(rest) loop
        eqn2 :: rest := rest;
        eqn1 := match (eqn1, eqn2)

          // entwine body if possible - equal iterator -> no intersecting
          case (FOR_EQUATION(), FOR_EQUATION()) guard(Iterator.isEqual(eqn1.iter, eqn2.iter)) algorithm
            eqn1.body := entwine(listAppend(eqn1.body, eqn2.body), nesting_level + 1);
          then eqn1;

          // if the iterators are not equal, they have to be intersected and the respective rests have to be handled
          case (FOR_EQUATION(), FOR_EQUATION()) algorithm
            (intersection, (rest1_left, rest1_right), (rest2_left, rest2_right)) := Iterator.intersect(eqn1.iter, eqn2.iter);
            tmp := {};
            if not Iterator.isEmpty(rest1_left) then
              tmp := FOR_EQUATION(eqn1.size, rest1_left, eqn1.body, eqn1.source, eqn1.attr) :: tmp;
            end if;
            if not Iterator.isEmpty(rest2_left) then
              tmp := FOR_EQUATION(eqn2.size, rest2_left, eqn2.body, eqn2.source, eqn2.attr) :: tmp;
            end if;
            if not Iterator.isEmpty(intersection) then
              tmp := FOR_EQUATION(
                size    = eqn1.size,
                iter    = intersection,
                body    = entwine(listAppend(eqn1.body, eqn2.body), nesting_level + 1),
                source  = eqn1.source,
                attr    = eqn1.attr
              ) :: tmp;
            end if;
            if not Iterator.isEmpty(rest1_right) then
              tmp := FOR_EQUATION(eqn1.size, rest1_right, eqn1.body, eqn1.source, eqn1.attr) :: tmp;
            end if;
            if not Iterator.isEmpty(rest2_right) then
              tmp := FOR_EQUATION(eqn2.size, rest2_right, eqn2.body, eqn2.source, eqn2.attr) :: tmp;
            end if;
            // there has to be at least one equation
            next :: tmp := tmp;
            entwined := listAppend(tmp, entwined);
          then next;

          // no entwining -> just add the equation
          else algorithm
            entwined := eqn1 :: entwined;
          then eqn2;
        end match;
      end while;
      entwined := listReverse(eqn1 :: entwined);
      if Flags.isSet(Flags.DUMP_SLICE) then
        print(shift + "[" + intString(nesting_level) + "] +++ Result of entwining:\n"
          + List.toString(entwined, function toString(str = shift  + "  "), "", "", "\n", "\n\n"));
      end if;
    end entwine;

    function slice
      "performs a single slice based on the given indices and the cref to solve for
      does not work for entwined for loops!"
      input Pointer<Equation> eqn_ptr         "equation to slice";
      input list<Integer> indices             "zero based indices of the eqn";
      output list<Pointer<Equation>> sliced_eqn;
      output SlicingStatus slicing_status     "unchanged, trivial (only rearranged) or nontrivial";
    protected
      Equation eqn;
      list<Dimension> dims;
      list<Integer> sizes;
    algorithm
      eqn := Pointer.access(eqn_ptr);
      (sliced_eqn, slicing_status) := match eqn
        local

        // empty index list indicates no slicing and no rearranging
        case _ guard(listEmpty(indices)) then ({Pointer.create(eqn)}, SlicingStatus.UNCHANGED);

        case RECORD_EQUATION() algorithm
          slicing_status := if Equation.size(eqn_ptr) == listLength(indices) then SlicingStatus.TRIVIAL else SlicingStatus.NONTRIVIAL;
        then ({Pointer.create(eqn)}, slicing_status);

        case ARRAY_EQUATION() algorithm
          slicing_status := if Equation.size(eqn_ptr) == listLength(indices) then SlicingStatus.TRIVIAL else SlicingStatus.NONTRIVIAL;
        then ({Pointer.create(eqn)}, slicing_status);

        case FOR_EQUATION() algorithm
          // trivial slices replace the original equation entirely
          dims            := Type.arrayDims(getType(eqn));
          sizes           := list(Dimension.size(dim) for dim in dims);
          slicing_status  := if Equation.size(eqn_ptr) == listLength(indices) then SlicingStatus.TRIVIAL else SlicingStatus.NONTRIVIAL;
          if slicing_status == SlicingStatus.NONTRIVIAL then
            sliced_eqn := sliceFor(listHead(eqn.body), getForIterator(eqn), sizes, listReverse(getForFrames(eqn)), indices);
          end if;
        then (sliced_eqn, slicing_status);

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because slicing is not yet supported for:\n" + toString(eqn)});
        then fail();
      end match;
    end slice;

    function sliceFor
      input Equation body;
      input Iterator iter;
      input list<Integer> sizes;
      input list<Frame> frames;
      input list<Integer> indices;
      input Boolean naive = false;
      output list<Pointer<Equation>> result;
    protected
      list<Integer> location;
      list<Frame> new_frames;
      list<list<Integer>> locations;
      list<array<Integer>> locations_T;
      list<FrameLocation> frame_locations;
      UnorderedMap<ComponentRef, Expression> replacements;
      FrameOrderingStatus frame_status;
      RecollectStatus recollect_status;
      Equation tmp;
      Option<UnorderedMap<ComponentRef, Expression>> removed_diagonals_opt;
      Integer size;
      Iterator new_iter;
    algorithm
      // get the sizes of the 'return value' of the equation
      if listLength(indices) == 1 then
        // perform a single replacement for the one index
        location      := Slice.indexToLocation(listHead(indices), sizes);
        replacements  := UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
        Iterator.createLocationReplacements(iter, listArray(location), replacements);
        tmp           := map(body, function Replacements.applySimpleExp(replacements = replacements));
        result        := {Pointer.create(tmp)};
      else
        // create the frame locations
        locations                                       := list(Slice.indexToLocation(idx, sizes) for idx in indices);
        locations_T                                     := Slice.transposeLocations(locations, listLength(sizes));
        frame_locations                                 := List.zip(locations_T, frames);
        (frame_locations, replacements, frame_status)   := Slice.orderTransposedFrameLocations(frame_locations);
        if frame_status == FrameOrderingStatus.FAILURE then
          if naive then
            // already tried naive, need to fully scalarize
            result := List.flatten(list(sliceFor(body, iter, sizes, frames, {i}, true) for i in indices));
          else
            // try naive separation
            result := List.flatten(list(sliceFor(body, iter, sizes, frames, subset, true) for subset in Slice.naiveSeparation(indices)));
          end if;
        else
          (new_frames, removed_diagonals_opt, recollect_status) := Slice.recollectRangesHeuristic(frame_locations);
          if recollect_status == RecollectStatus.FAILURE or isSome(removed_diagonals_opt) then
            if naive then
              // already tried naive, need to fully scalarize
              result := List.flatten(list(sliceFor(body, iter, sizes, frames, {i}, true) for i in indices));
            else
              // try naive separation
              result := List.flatten(list(sliceFor(body, iter, sizes, frames, subset, true) for subset in Slice.naiveSeparation(indices)));
            end if;
          else
            // replace iterators
            tmp := map(body, function Replacements.applySimpleExp(replacements = replacements));

            new_iter  := Iterator.fromFrames(new_frames);
            size      := Iterator.size(new_iter) * Equation.size(Pointer.create(tmp));
            tmp       := FOR_EQUATION(
              size    = size,
              iter    = new_iter,
              body    = {tmp},
              source  = getSource(body),
              attr    = getAttributes(body));
            result    := {Pointer.create(tmp)};
          end if;
        end if;
      end if;
    end sliceFor;

    function singleSlice
      input Pointer<Equation> eqn_ptr                             "equation to slice";
      input Integer scal_idx                                      "zero based scalar index";
      input list<Integer> sizes                                   "frame sizes (innermost first)";
      input ComponentRef cref_to_solve                            "the cref to solve the body for (EMPTY() for already solved)";
      input UnorderedMap<ComponentRef, Expression> replacements   "prepared replacement map";
      output Equation sliced_eqn                                  "scalar sliced equation";
      input output FunctionTree funcTree                          "func tree for solving";
      output Solve.Status solve_status                            "solve success status";
    protected
      Equation eqn;
      list<Integer> location;
    algorithm
      eqn := Pointer.access(eqn_ptr);
      (sliced_eqn, solve_status) := match eqn

        // slice the equation
        case FOR_EQUATION() algorithm
          // get the frame location indices from single index
          location := Slice.indexToLocation(scal_idx, sizes);
          // create the replacement rules for this location
          Iterator.createLocationReplacements(eqn.iter, listArray(location), replacements);
          // replace iterators
          sliced_eqn := map(listHead(eqn.body), function Replacements.applySimpleExp(replacements = replacements));
          // solve the body if necessary
          if not ComponentRef.isEmpty(cref_to_solve) then
            (sliced_eqn, funcTree, solve_status, _) := Solve.solveBody(sliced_eqn, cref_to_solve, funcTree);
          end if;
        then (sliced_eqn, solve_status);

        // ToDo: arrays 'n stuff

        // equation that does not need to be sliced
        else (eqn, NBSolve.Status.UNPROCESSED);
      end match;
    end singleSlice;

    protected function makeInequality
      input tuple<ComponentRef, Expression> tpl;
      output Expression equality_exp;
    protected
      ComponentRef cref;
      Expression exp;
    algorithm
      (cref, exp)   := tpl;
      equality_exp  := Expression.RELATION(
        exp1      = Expression.fromCref(cref),
        operator  = Operator.OPERATOR(ComponentRef.nodeType(cref), NFOperator.Op.NEQUAL),
        exp2      = SimplifyExp.simplifyDump(exp, true, getInstanceName()),
        index     = -1
      );
    end makeInequality;

    public function toStatement
      "expects for loops to be split with splitIterators(eqn)"
      input Equation eqn;
      output list<Statement> stmts = {};
    algorithm
      stmts := match eqn
        local
          list<ComponentRef> iter_lst;
          list<Expression> range_lst;
          ComponentRef iter, lhs_rec, rhs_rec;
          Expression range;
          list<Statement> body;
          Pointer<Variable> lhs, rhs;
          list<Pointer<Variable>> lhs_lst, rhs_lst;

        case SCALAR_EQUATION()
        then {Statement.ASSIGNMENT(eqn.lhs, eqn.rhs, eqn.ty, eqn.source)};

        case ARRAY_EQUATION()
        then {Statement.ASSIGNMENT(eqn.lhs, eqn.rhs, eqn.ty, eqn.source)};

        case RECORD_EQUATION(lhs = Expression.CREF(cref = lhs_rec), rhs = Expression.CREF(cref = rhs_rec)) algorithm
          lhs_lst := BVariable.getRecordChildren(BVariable.getVarPointer(lhs_rec, sourceInfo()));
          rhs_lst := BVariable.getRecordChildren(BVariable.getVarPointer(rhs_rec, sourceInfo()));
          if List.compareLength(lhs_lst, rhs_lst) == 0 and not Type.isExternalObject(Type.arrayElementType(Expression.typeOf(eqn.lhs))) then
            for tpl in List.zip(lhs_lst, rhs_lst) loop
              (lhs, rhs) := tpl;
              stmts := Statement.ASSIGNMENT(Expression.fromCref(BVariable.getVarName(lhs)), Expression.fromCref(BVariable.getVarName(rhs)), Variable.typeOf(Pointer.access(lhs)), eqn.source) :: stmts;
            end for;
          else
            stmts := {Statement.ASSIGNMENT(eqn.lhs, eqn.rhs, eqn.ty, eqn.source)};
          end if;
        then stmts;

        case RECORD_EQUATION()
        then {Statement.ASSIGNMENT(eqn.lhs, eqn.rhs, eqn.ty, eqn.source)};

        case FOR_EQUATION() algorithm
          (iter_lst, range_lst) := Equation.Iterator.getFrames(eqn.iter);
          body := List.flatten(list(toStatement(body_eqn) for body_eqn in eqn.body));
          for tpl in listReverse(List.zip(iter_lst, range_lst)) loop
            (iter, range) := tpl;
            body := {Statement.FOR(
              iterator  = ComponentRef.node(iter),
              range     = SOME(range),
              body      = body,
              forType   = Statement.ForType.NORMAL(),
              source    = eqn.source)};
          end for;
        then body;

        case IF_EQUATION() then {Statement.IF(IfEquationBody.toStatement(eqn.body), eqn.source)};

        case WHEN_EQUATION() then {Statement.WHEN(WhenEquationBody.toStatement(eqn.body), eqn.source)};

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed it is not yet supported for:\n" + toString(eqn)});
        then fail();
      end match;
    end toStatement;

  end Equation;

  uniontype IfEquationBody
    record IF_EQUATION_BODY
      Expression condition                  "the if-condition";
      list<Pointer<Equation>> then_eqns     "body equations";
      Option<IfEquationBody> else_if        "optional elseif equation";
    end IF_EQUATION_BODY;

    function toEquation
      "does not name the equation"
      input IfEquationBody body;
      input DAE.ElementSource source;
      input Boolean init;
      output Pointer<Equation> eqn;
    protected
      EquationAttributes attr;
    algorithm
      attr := match body.then_eqns
        local
          Pointer<Equation> then_eqn;
        case {then_eqn} then if Equation.isDiscrete(then_eqn)
          then EquationAttributes.default(EquationKind.DISCRETE, init)
          else EquationAttributes.default(EquationKind.CONTINUOUS, init);
        else algorithm
          if(Flags.isSet(Flags.FAILTRACE)) then
            Error.addMessage(Error.COMPILER_WARNING,{getInstanceName()
              + ": Creating if-equation with multiple body equations. Unsure of type:\n" + IfEquationBody.toString(body)});
          end if;
        then EquationAttributes.default(EquationKind.CONTINUOUS, init);
      end match;
      eqn := Pointer.create(Equation.IF_EQUATION(IfEquationBody.size(body), body, source, attr));
    end toEquation;

    function makeIfEquation
      "similar to makeAssignment but for if-equations"
      input IfEquationBody body;
      input Pointer<Integer> idx;
      input String str;
      input Iterator iter;
      input DAE.ElementSource source;
      input EquationAttributes attr;
      output Pointer<Equation> eq;
    protected
      Equation e;
    algorithm
      e := makeIfEquationEqn(body, iter, source, attr);
      eq := Pointer.create(e);
      Equation.createName(eq, idx, str);
    end makeIfEquation;

    protected function makeIfEquationEqn
      "similar to makeAssignmentEqn but for if-equations"
      input IfEquationBody body;
      input Iterator iter;
      input DAE.ElementSource source;
      input EquationAttributes attr;
      output Equation e;
    algorithm
      e := Equation.IF_EQUATION(
        size    = IfEquationBody.size(body),
        body    = body,
        source  = source,
        attr    = attr
      );
      // create for-loop around it if there is an iterator
      if not Iterator.isEmpty(iter) then
        e := FOR_EQUATION(
          size    = IfEquationBody.size(body) * Iterator.size(iter),
          iter    = iter,
          body    = {e},
          source  = source,
          attr    = attr
        );
        // inline if it has size 1
        e := Inline.inlineForEquation(e);
      end if;
    end makeIfEquationEqn;

  public
    function toString
      input IfEquationBody body;
      input String indent = "";
      input String elseStr = "";
      input Boolean selfCall = false;
      output String str;
    algorithm
      str := elseStr;
      if not selfCall then
        str := str + indent;
      end if;
      if not Expression.isEnd(body.condition) then
        str := str + "if " + Expression.toString(body.condition) + " then\n";
      else
        str := str + "\n";
      end if;
      for eqn in body.then_eqns loop
        str := str + Equation.toString(Pointer.access(eqn), indent + "  ") + "\n";
      end for;
      if isSome(body.else_if) then
        str := str + toString(Util.getOption(body.else_if), indent, indent + "else", true);
      end if;
      if not selfCall then
        str := str + indent + "end if;";
      end if;
    end toString;

    function map
      input output IfEquationBody ifBody;
      input MapFuncExp funcExp;
      input Option<MapFuncCref> funcCrefOpt;
      input MapFuncExpWrapper mapFunc;
    algorithm
      ifBody := mapEqnExpCref(
        ifBody      = ifBody,
        func        = function Pointer.apply(func = function Equation.map(funcExp = funcExp, funcCrefOpt = funcCrefOpt, mapFunc = mapFunc)),
        funcExp     = funcExp,
        funcCrefOpt = funcCrefOpt,
        mapFunc     = mapFunc);
    end map;

    function mapEqnExpCref
      input output IfEquationBody ifBody;
      input MapFuncEqnPtr func;
      input MapFuncExp funcExp;
      input Option<MapFuncCref> funcCrefOpt;
      input MapFuncExpWrapper mapFunc;
    protected
      Expression condition;
      IfEquationBody else_if, old_else_if;
    algorithm
      condition := mapFunc(ifBody.condition, funcExp);
      if not referenceEq(condition, ifBody.condition) then
        ifBody.condition := condition;
      end if;

      // referenceEq for lists?
      ifBody.then_eqns := List.map(ifBody.then_eqns, func);

      if Util.isSome(ifBody.else_if) then
        old_else_if := Util.getOption(ifBody.else_if);
        else_if := mapEqnExpCref(old_else_if, func, funcExp, funcCrefOpt, mapFunc);
        if not referenceEq(else_if, old_else_if) then
          ifBody.else_if := SOME(else_if);
        end if;
      end if;
    end mapEqnExpCref;

    function size
      "only considers first branch"
      input IfEquationBody body;
      input Boolean resize = false;
      output Integer size = sum(Equation.size(eqn, resize) for eqn in body.then_eqns);
    end size;

    function isEqual
      input IfEquationBody body1;
      input IfEquationBody body2;
      output Boolean b;
    algorithm
      b := List.all(list(Equation.isEqualPtr(b1, b2) threaded for b1 in body1.then_eqns, b2 in body2.then_eqns), Util.id) and Util.optionEqual(body1.else_if, body2.else_if, isEqual);
    end isEqual;

    function createNames
      input IfEquationBody body;
      input Pointer<Integer> idx;
      input String context;
    algorithm
      for eqn in body.then_eqns loop
        Equation.createName(eqn, idx, context);
      end for;
      if Util.isSome(body.else_if) then
        createNames(Util.getOption(body.else_if), idx, context);
      end if;
    end createNames;

    function toStatement
      "converts an if equation body to an algorithmic statement"
      input IfEquationBody body;
      output list<tuple<Expression, list<Statement>>> stmts;
    protected
      tuple<Expression, list<Statement>> stmt;
      Expression condition = if Expression.isEnd(body.condition) then Expression.BOOLEAN(true) else body.condition;
    algorithm
      stmt := (condition, List.flatten(list(Equation.toStatement(Pointer.access(eqn)) for eqn in body.then_eqns)));
      if Util.isSome(body.else_if) then
        stmts := stmt :: toStatement(Util.getOption(body.else_if));
      else
        stmts := {stmt};
      end if;
    end toStatement;

    function createResidual
      "needs the if equation to be split"
      input IfEquationBody body;
      input ComponentRef res;
      output IfEquationBody body_res;
    protected
      Pointer<Equation> eqn_ptr;
      Equation eqn;
      Expression exp;
    algorithm
      body_res := IF_EQUATION_BODY(body.condition, {}, Util.applyOption(body.else_if, function createResidual(res = res)));
      body_res := match body.then_eqns
        case {eqn_ptr} algorithm
          eqn := Pointer.access(eqn_ptr);
          exp := Equation.getResidualExp(eqn);
          eqn := Equation.setLHS(eqn, Expression.fromCref(res));
          eqn := Equation.setRHS(eqn, exp);
          body_res.then_eqns := Pointer.create(eqn) :: body_res.then_eqns;
        then body_res;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for:\n" + toString(body)});
        then fail();
      end match;
    end createResidual;

    function inline
      "only works if the LHS of each branch are equal, so if it was solved and only has a single equation each branch"
      input IfEquationBody body;
      input output Equation eqn;
    protected
      Expression lhs, rhs;
      Boolean success;
    algorithm
      (lhs, success) := getLHS(body);
      if success then
        rhs := SimplifyExp.simplify(getRHS(body));
        eqn := Equation.makeAssignmentUpdate(eqn, lhs, rhs, Equation.getForIterator(eqn), Equation.getAttributes(eqn));
      end if;
    end inline;

    function getLHS
      "needs the if equation to be split and equal lhs"
      input IfEquationBody body;
      input output Expression exp = Expression.END();
      output Boolean success = true;
    protected
      Pointer<Equation> eqn_ptr;
      Expression new_exp;
    algorithm
      exp := match body.then_eqns
        case {eqn_ptr} algorithm
          new_exp := Equation.getLHS(Pointer.access(eqn_ptr));
          if Expression.isEnd(exp) or Expression.isEqual(exp, new_exp) then
            if Util.isSome(body.else_if) then
              (new_exp, success) := getLHS(Util.getOption(body.else_if), new_exp);
            end if;
          else
            if Flags.isSet(Flags.FAILTRACE) then
              Error.addCompilerWarning(getInstanceName() + " failed because of ambiguous LHS for:\n" + toString(body));
            end if;
            success := false;
          end if;
        then new_exp;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of un-split if-equation:\n" + toString(body)});
        then fail();
      end match;
    end getLHS;

    function getRHS
      "needs the if equation to be split"
      input IfEquationBody body;
      output Expression exp;
    protected
      Pointer<Equation> eqn_ptr;
      Expression new_exp;
    algorithm
      exp := match body.then_eqns
        case {eqn_ptr} algorithm
          new_exp := Equation.getRHS(Pointer.access(eqn_ptr));
          if Util.isSome(body.else_if) then
            new_exp := Expression.IF(Expression.typeOf(new_exp), body.condition, new_exp, getRHS(Util.getOption(body.else_if)));
          end if;
        then new_exp;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of un-split if-equation:\n" + toString(body)});
        then fail();
      end match;
    end getRHS;

    function split
      "splits an if equation body with multiple equations into multiple bodies of each one equation."
      input IfEquationBody body;
      output list<IfEquationBody> bodies = {};
    protected
      list<Expression> conditions = {};
      array<list<Pointer<Equation>>> then_eqns = arrayCreate(listLength(body.then_eqns), {});
      Expression condition;
      Pointer<Equation> eqn;
      Option<IfEquationBody> tmp;
    algorithm
      (conditions, then_eqns) := splitCollect(sortForSplit(body), conditions, then_eqns);
      for i in 1:arrayLength(then_eqns) loop
        tmp := NONE();
        for tpl in List.zip(conditions, then_eqns[i]) loop
          (condition, eqn) := tpl;
          tmp := SOME(IF_EQUATION_BODY(condition, {eqn}, tmp));
        end for;
        bodies := Util.getOption(tmp) :: bodies;
      end for;
    end split;

    function simplify
      "removes unreachable branches by looking at literal conditions"
      input output Option<IfEquationBody> body;
    algorithm
      body := match body
        local
          IfEquationBody b;

        case SOME(b) algorithm
          // if the condition is True -> cut later unreachable branches
          if Expression.isTrue(b.condition) then
            b.condition := Expression.END();
            b.else_if := NONE();
          else
            b.else_if := simplify(b.else_if);
          end if;
          // if the condition is False -> skip this unreachable branch
          if Expression.isFalse(b.condition) then
            body := b.else_if;
          else
            body := SOME(b);
          end if;
        then body;

        // NONE() stays NONE()
        else body;
      end match;
    end simplify;

    function isRecordOrTupleEquation
      "only checks first layer body if it returns multiple variables"
      input IfEquationBody body;
      output Boolean b;
    algorithm
      b := match body.then_eqns
        local
          Pointer<Equation> eqn_ptr;
         // just a tuple itself
        case {eqn_ptr} then Equation.isRecordOrTupleEquation(eqn_ptr);
        // at least 2 body equations -> tuple return
        case _ :: _ :: _ then true;
        else false;
      end match;
    end isRecordOrTupleEquation;

  protected
    function sortForSplit
      "sorts the body equations by discrete and continuous to correctly split them
      ToDo: make it full type safe sorting"
      input output IfEquationBody body;
    protected
      list<Pointer<Equation>> discretes, continuous;

      function compareLHS
        "Heuristic: often the lhs is a cref. If all branches are solved for the lhs,
         sorting them in the same way makes the split nice without algebraic loops."
        input Pointer<Equation> eqn1;
        input Pointer<Equation> eqn2;
        output Boolean b = Expression.compare(Equation.getLHS(Pointer.access(eqn1)), Equation.getLHS(Pointer.access(eqn2))) > 0;
      end compareLHS;
    algorithm
      (discretes, continuous) := List.splitOnTrue(body.then_eqns, Equation.isDiscrete);
      discretes               := List.sort(discretes, compareLHS);
      continuous              := List.sort(continuous, compareLHS);
      body.then_eqns          := listAppend(discretes, continuous);
      body.else_if            := Util.applyOption(body.else_if, sortForSplit);
    end sortForSplit;

    function splitCollect
      "collects the equations of each branch to create single branch equation bodies afterwards."
      input IfEquationBody body;
      input output list<Expression> conditions;
      input output array<list<Pointer<Equation>>> then_eqns;
    protected
      Integer i = 1;
    algorithm
      conditions := body.condition :: conditions;
      for eqn in body.then_eqns loop
        then_eqns[i] := eqn :: then_eqns[i];
        i := i + 1;
      end for;
      if Util.isSome(body.else_if) then
        (conditions, then_eqns) := splitCollect(Util.getOption(body.else_if), conditions, then_eqns);
      end if;
    end splitCollect;
  end IfEquationBody;

  uniontype WhenEquationBody
    record WHEN_EQUATION_BODY "equation when condition then cr = exp, reinit(...), terminate(...) or assert(...)"
      Expression condition                  "the when-condition";
      list<WhenStatement> when_stmts        "body statements";
      Option<WhenEquationBody> else_when    "optional elsewhen body";
    end WHEN_EQUATION_BODY;

    function fromFlatList
      input list<tuple<Expression, list<WhenStatement>>> flat_list "given in reverse order";
      input output Option<WhenEquationBody> body = NONE();
    algorithm
      body := match flat_list
        local
          Expression condition;
          list<WhenStatement> stmts;
          list<tuple<Expression, list<WhenStatement>>> tail;
        case (condition, stmts) :: tail then fromFlatList(tail, SOME(WHEN_EQUATION_BODY(condition, stmts, body)));
        else body;
      end match;
    end fromFlatList;

    function toString
      input WhenEquationBody body;
      input String indent = "";
      input String elseStr = "";
      input Boolean selfCall = false;
      output String str;
    algorithm
      str := elseStr;
      if not selfCall then
        str := str + indent;
      end if;
      str := str + "when " + Expression.toString(body.condition) + " then\n";
      for stmt in body.when_stmts loop
        str := str + WhenStatement.toString(stmt, indent + "  ") + "\n";
      end for;
      if isSome(body.else_when) then
        str := str + toString(Util.getOption(body.else_when), indent, indent + "else", true);
      end if;
      if not selfCall then
        str := str + indent + "end when;";
      end if;
    end toString;

    function size
      "returns the size only considering first when branch."
      input WhenEquationBody body;
      input Boolean resize = false;
      output Integer s = sum(WhenStatement.size(stmt, resize) for stmt in body.when_stmts);
    end size;

    function getType
      "only works if properly split up"
      input WhenEquationBody body;
      output Type ty;
    algorithm
      ty := match body.when_stmts
        local
          WhenStatement stmt;
        case {stmt} then WhenStatement.getType(stmt);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of not properly split up when equation body: " + toString(body)});
        then fail();
      end match;
    end getType;

    function isEqual
      input WhenEquationBody body1;
      input WhenEquationBody body2;
      output Boolean b;
    algorithm
      b := Expression.isEqual(body1.condition, body2.condition) and List.all(list(WhenStatement.isEqual(b1, b2) threaded for b1 in body1.when_stmts, b2 in body2.when_stmts), Util.id) and Util.optionEqual(body1.else_when, body2.else_when, isEqual);
    end isEqual;

    function getBodyAttributes
      "gets all conditions crefs as a list (has to be applied AFTER Event module)"
      input WhenEquationBody body;
      output list<ComponentRef> conditions;
      output list<WhenStatement> when_stmts = body.when_stmts;
      output Option<WhenEquationBody> else_when = body.else_when;
    protected
      function getConditions
        input Expression cond;
        output list<ComponentRef> conditions;
      algorithm
        conditions := match cond
          local
            ComponentRef cref;
          case Expression.CREF(cref = cref) then {cref};
          case Expression.ARRAY() then List.flatten(list(getConditions(elem) for elem in cond.elements));
          case Expression.CALL() guard(Call.isNamed(cond.call, "initial")) then {};
          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for condition: " + Expression.toString(cond)});
          then fail();
        end match;
      end getConditions;
    algorithm
      conditions := getConditions(body.condition);
    end getBodyAttributes;

    function toStatement
      input WhenEquationBody body;
      output list<tuple<Expression, list<Statement>>> stmts;
    protected
      tuple<Expression, list<Statement>> stmt;
    algorithm
      stmt := (body.condition, list(WhenStatement.toStatement(st) for st in body.when_stmts));
      if Util.isSome(body.else_when) then
        stmts := stmt :: toStatement(Util.getOption(body.else_when));
      else
        stmts := {stmt};
      end if;
    end toStatement;

    function map
      input output WhenEquationBody whenBody;
      input MapFuncExp funcExp;
      input Option<MapFuncCref> funcCrefOpt;
      input MapFuncExpWrapper mapFunc;
    protected
      Expression condition;
    algorithm
      condition := mapFunc(whenBody.condition, funcExp);
      if not referenceEq(condition, whenBody.condition) then
        whenBody.condition := condition;
      end if;

      // ToDo reference eq for lists?
      whenBody.when_stmts := List.map(whenBody.when_stmts, function WhenStatement.map(funcExp = funcExp, funcCrefOpt = funcCrefOpt, mapFunc = mapFunc));

      // map else when
      whenBody.else_when := Util.applyOption(whenBody.else_when, function map(funcExp = funcExp, funcCrefOpt = funcCrefOpt, mapFunc = mapFunc));
    end map;

    function mapCondition
      "only maps the conditions and not the body"
      input output WhenEquationBody whenBody;
      input MapFuncExp funcExp;
      input Option<MapFuncCref> funcCrefOpt;
      input MapFuncExpWrapper mapFunc;
    protected
      Expression condition;
    algorithm
      condition := mapFunc(whenBody.condition, funcExp);
      if not referenceEq(condition, whenBody.condition) then
        whenBody.condition := condition;
      end if;

      // map else when
      whenBody.else_when := Util.applyOption(whenBody.else_when, function mapCondition(funcExp = funcExp, funcCrefOpt = funcCrefOpt, mapFunc = mapFunc));
    end mapCondition;

    function split
      "this function splits up when equations while respecting to keep
      correct branches for assigned discrete states and reinitialized states.
      it also keeps all no return branches as one."
      input WhenEquationBody body;
      output list<WhenEquationBody> bodies = {};
    protected
      UnorderedMap<ComponentRef, CrefSet> discr_map = UnorderedMap.new<CrefSet>(ComponentRef.hash, ComponentRef.isEqual);
      UnorderedSet<ComponentRef> state_set = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
      UnorderedSet<ComponentRef> discr_marks = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
      list<tuple<Expression, list<WhenStatement>>> flat_when;
      list<tuple<Expression, list<WhenStatement>>> flat_new;
      list<ComponentRef> discretes, states;
      CrefSet set;
      Expression condition, acc_condition = Expression.EMPTY(Type.INTEGER());
      list<WhenStatement> stmts, assigns;
      Option<WhenStatement> stmt;
      Option<WhenEquationBody> new_body;
    algorithm
      // collect all discretes and states contained in the when equation body
      // and also flatten the when equation to a list
      flat_when := collectForSplit(SOME(body), discr_map, state_set);
      discretes := UnorderedMap.keyList(discr_map);
      states    := UnorderedSet.toList(state_set);

      // create a when equation for each discrete state
      for disc in discretes loop
        if not UnorderedSet.contains(disc, discr_marks) then
          set := UnorderedMap.getSafe(disc, discr_map, sourceInfo());
          for marked in UnorderedSet.toList(set) loop
            UnorderedSet.add(marked, discr_marks);
          end for;
          flat_new := {};
          for tpl in flat_when loop
            (condition, stmts) := tpl;
            assigns := getAssignments(set, stmts);
            // if there is a statement: create the when body and combine with previous
            // conditions. if there is no statement in this branch, save the condition
            // negated for the next branch
            if not listEmpty(assigns) then
              condition := combineConditions(acc_condition, condition, false);
              acc_condition := Expression.EMPTY(Type.INTEGER());
              flat_new := (condition, assigns) :: flat_new;
            else
              acc_condition := combineConditions(acc_condition, condition, true);
            end if;
          end for;
          // create body from flat list and add to new bodies
          new_body := fromFlatList(flat_new);
          if Util.isSome(new_body) then
            bodies := Util.getOption(new_body) :: bodies;
          else
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
              + " failed because when partition for: " + ComponentRef.toString(disc)
              + " could not be recovered."});
          end if;
        end if;
      end for;

      // create a when equation for each state
      for state in states loop
        flat_new := {};
        for tpl in flat_when loop
          (condition, stmts) := tpl;
          // get first reinit - each branch should only have one
          // reinit per state
          stmt := getFirstReinit(state, stmts);
          // if there is a statement: create the when body and combine with previous
          // conditions. if there is no statement in this branch, save the condition
          // negated for the next branch
          if Util.isSome(stmt) then
            condition := combineConditions(acc_condition, condition, false);
            acc_condition := Expression.EMPTY(Type.INTEGER());
            flat_new := (condition, {Util.getOption(stmt)}) :: flat_new;
          else
            acc_condition := combineConditions(acc_condition, condition, true);
          end if;
        end for;
        // create body from flat list and add to new bodies
        new_body := fromFlatList(flat_new);
        if Util.isSome(new_body) then
          bodies := Util.getOption(new_body) :: bodies;
        else
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
            + " failed because when partition for: " + ComponentRef.toString(state)
            + " could not be recovered."});
        end if;
      end for;

      // collect all statements that are not assign or reinit and combine them
      for tpl in flat_when loop
        (condition, stmts) := tpl;
        stmts := list(stmt for stmt guard(not WhenStatement.isAssignOrReinit(stmt)) in stmts);
        // if there is a statement: create the when body and combine with previous
        // conditions. if there is no statement in this branch, save the condition
        // negated for the next branch
        if not listEmpty(stmts) then
          condition := combineConditions(acc_condition, condition, false);
          acc_condition := Expression.EMPTY(Type.INTEGER());
          flat_new := (condition, stmts) :: flat_new;
        else
          acc_condition := combineConditions(acc_condition, condition, true);
        end if;
      end for;

      bodies := listReverse(bodies);
    end split;

    function simplify
      input output Option<WhenEquationBody> body;
    algorithm
      body := match body
        local
          WhenEquationBody b;
          Expression condition;
          list<Expression> conditions;

        // if the condition is an array, skip surplus of literal elements
        case SOME(b as WHEN_EQUATION_BODY(condition = condition as Expression.ARRAY())) algorithm
          b.else_when := simplify(b.else_when);
          conditions := list(elem for elem guard(not Expression.isBoolean(elem)) in condition.elements);
          if listEmpty(conditions) then
            body := b.else_when;
          elseif List.hasOneElement(conditions) then
            b.condition := listHead(conditions);
            body := SOME(b);
          else
            b.condition := Expression.makeArrayCheckLiteral(Type.ARRAY(Type.BOOLEAN(), {Dimension.fromInteger(listLength(conditions))}), listArray(conditions));
            body := SOME(b);
          end if;
        then body;

        // simplify condition
        case SOME(b) algorithm
          b.else_when := simplify(b.else_when);
          // if the condition is a literal boolean -> skip this unreachable branch
          if Expression.isBoolean(b.condition) then
            body := b.else_when;
          else
            body := SOME(b);
          end if;
        then body;

        // NONE() stays NONE()
        else body;
      end match;
    end simplify;

    function getAllAssigned
      "returns all assigned discrete variables as expressions.
      Note: only needs to iterate first body because all need to have the same
      variables assigned. ModelicaSpecification 3.6, Section 8.6"
      input WhenEquationBody body;
      output list<ComponentRef> assigned = {};
    algorithm
      for stmt in body.when_stmts loop
        assigned := match stmt
          local
            ComponentRef lhs;
          case WhenStatement.ASSIGN(lhs = Expression.CREF(cref = lhs)) then lhs :: assigned;
          else assigned;
        end match;
      end for;
    end getAllAssigned;

    function isRecordOrTupleEquation
      "only checks first layer body if it returns multiple variables"
      input WhenEquationBody body;
      output Boolean b;
    algorithm
      b := match body.when_stmts
        local
          ComponentRef cref;
         // just a record or tuple itself
        case {WhenStatement.ASSIGN(lhs = Expression.TUPLE())} then true;
        case {WhenStatement.ASSIGN(lhs = Expression.RECORD())} then true;
        case {WhenStatement.ASSIGN(lhs = Expression.CREF(cref = cref))}
          then BVariable.checkCref(cref, BVariable.isRecord, sourceInfo());
        // multiple body equations -> tuple return
        case _ guard(List.count(body.when_stmts, WhenStatement.isAssign) > 1) then true;
        else false;
      end match;
    end isRecordOrTupleEquation;

  protected
    type CrefSet = UnorderedSet<ComponentRef>;
    function collectForSplit
      "collects all discrete states and regular states for splitting up
      of a when equation. also flattens it to a list"
      input Option<WhenEquationBody> body_opt;
      input UnorderedMap<ComponentRef, CrefSet> discr_map;
      input UnorderedSet<ComponentRef> state_set;
      output list<tuple<Expression, list<WhenStatement>>> flat_when;
    protected
      WhenEquationBody body;
    algorithm
      if Util.isSome(body_opt) then
        body := Util.getOption(body_opt);
        for stmt in body.when_stmts loop
          () := match stmt
            local
              ComponentRef cref;
              Expression tpl;

            case WhenStatement.ASSIGN(lhs = Expression.CREF(cref = cref)) algorithm
              addCrefsMap(discr_map, {cref});
            then ();
            case WhenStatement.ASSIGN(lhs = tpl as Expression.TUPLE()) algorithm
              addCrefsMap(discr_map, UnorderedSet.toList(Expression.extractCrefs(tpl)));
            then ();
            case WhenStatement.REINIT(stateVar = cref) algorithm
              UnorderedSet.add(cref, state_set);
            then ();
            case WhenStatement.ASSIGN() algorithm
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
                + " failed because lhs of statement is not a cref: " + WhenStatement.toString(stmt)});
            then fail();
            else ();
          end match;
        end for;
        flat_when := (body.condition, body.when_stmts) :: collectForSplit(body.else_when, discr_map, state_set);
      else
        flat_when := {};
      end if;
    end collectForSplit;

    function addCrefsMap
      input UnorderedMap<ComponentRef, CrefSet> discr_map;
      input list<ComponentRef> crefs;
    protected
      CrefSet set_new, set = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    algorithm
      for c in crefs loop
        if UnorderedMap.contains(c, discr_map) then
          set_new := UnorderedMap.getSafe(c, discr_map, sourceInfo());
          if not referenceEq(set, set_new) then
            set := UnorderedSet.union(set, set_new);
          end if;
        else
          UnorderedSet.add(c, set);
        end if;
      end for;

      for c in crefs loop
        UnorderedMap.add(c, set, discr_map);
      end for;
    end addCrefsMap;

    function getAssignments
      "returns all assignments for the crefs in crefSet and merges if necessary"
      input UnorderedSet<ComponentRef> crefSet;
      input list<WhenStatement> stmts;
      output list<WhenStatement> assigns = {};
    algorithm
      for stmt in stmts loop
        () := match stmt
          local
            ComponentRef cref;
            Expression tpl;

          case WhenStatement.ASSIGN(lhs = Expression.CREF(cref = cref))
          guard(UnorderedSet.contains(cref, crefSet)) algorithm
            assigns := stmt :: assigns;
          then ();

          case WhenStatement.ASSIGN(lhs = tpl as Expression.TUPLE())
          guard(List.any(list(UnorderedSet.contains(c, crefSet) for c in UnorderedSet.toList(Expression.extractCrefs(tpl))), Util.id)) algorithm
            assigns := stmt :: assigns;
          then ();

          else ();
        end match;
      end for;
    end getAssignments;

    function getFirstReinit
      "returns the first reinit in the list that reinitializes cref"
      input ComponentRef cref;
      input list<WhenStatement> stmts;
      output Option<WhenStatement> assign = NONE();
    algorithm
      for stmt in stmts loop
        () := match stmt
          case WhenStatement.REINIT()
          guard(ComponentRef.isEqual(cref, stmt.stateVar)) algorithm
            assign := SOME(stmt); break;
          then ();
          else ();
        end match;
      end for;
    end getFirstReinit;

    function combineConditions
      "combines to conditions with an AND. Ignores first condition if EMPTY.
      May invert second condition."
      input Expression acc_condition;
      input output Expression condition;
      input Boolean invert;
    algorithm
      if invert then
        condition := Expression.logicNegate(condition);
      end if;
      if not Expression.isEmpty(acc_condition) then
        condition := Expression.LBINARY(acc_condition, Operator.makeAnd(Type.BOOLEAN()), condition);
      end if;
    end combineConditions;
  end WhenEquationBody;

  uniontype WhenStatement
    record ASSIGN " left_cr = right_exp"
      Expression lhs            "left hand side of assignment";
      Expression rhs            "right hand side of assignment";
      DAE.ElementSource source  "origin of assignment";
    end ASSIGN;

    record REINIT "Reinit Statement"
      ComponentRef stateVar     "State variable to reinit";
      Expression value          "Value after reinit";
      DAE.ElementSource source  "origin of statement";
    end REINIT;

    record ASSERT
      Expression condition;
      Expression message;
      Expression level;
      DAE.ElementSource source "origin of statement";
    end ASSERT;

    record TERMINATE
      "The Modelica built-in terminate(msg)"
      Expression message;
      DAE.ElementSource source "the origin of the component/equation/algorithm";
    end TERMINATE;

    record NORETCALL
      "call with no return value, i.e. no equation.
      Typically side effect call of external function but also
      Connections.* i.e. Connections.root(...) functions."
      Expression exp;
      DAE.ElementSource source "the origin of the component/equation/algorithm";
    end NORETCALL;

    function toString
      input WhenStatement stmt;
      input output String str = "";
    algorithm
      str := match stmt
        local
          Expression lhs, rhs, value, condition, message, level;
          ComponentRef stateVar;
        case ASSIGN(lhs = lhs, rhs = rhs)                                     then str + Expression.toString(lhs) + " := " + Expression.toString(rhs);
        case REINIT(stateVar = stateVar, value = value)                       then str + "reinit(" + ComponentRef.toString(stateVar) + ", " + Expression.toString(value) + ")";
        case ASSERT(condition = condition, message = message, level = level)  then str + "assert(" + Expression.toString(condition) + ", " + Expression.toString(message) + ", " + Expression.toString(level) + ")";
        case TERMINATE(message = message)                                     then str + "terminate(" + Expression.toString(message) + ")";
        case NORETCALL(exp = value)                                           then str + Expression.toString(value);
                                                                              else str + getInstanceName() + " failed.";
      end match;
    end toString;

    function isEqualTpl
      input tuple<WhenStatement, WhenStatement> tpl;
      output Boolean b;
    protected
      WhenStatement stmt1;
      WhenStatement stmt2;
    algorithm
      (stmt1, stmt2) := tpl;
      b := isEqual(stmt1, stmt2);
    end isEqualTpl;

    function isEqual
      input WhenStatement stmt1;
      input WhenStatement stmt2;
      output Boolean b;
    algorithm
      b := match (stmt1, stmt2)
        case (ASSIGN(), ASSIGN()) then Expression.isEqual(stmt1.lhs, stmt2.lhs) and Expression.isEqual(stmt1.rhs, stmt2.rhs);
        case (REINIT(), REINIT()) then ComponentRef.isEqual(stmt1.stateVar, stmt2.stateVar) and Expression.isEqual(stmt1.value, stmt2.value);
        case (ASSERT(), ASSERT()) then Expression.isEqual(stmt1.condition, stmt2.condition) and Expression.isEqual(stmt1.message, stmt2.message) and Expression.isEqual(stmt1.level, stmt2.level);
        case (TERMINATE(), TERMINATE()) then Expression.isEqual(stmt1.message, stmt2.message);
        case (NORETCALL(), NORETCALL()) then Expression.isEqual(stmt1.exp, stmt2.exp);
        else false;
      end match;
    end isEqual;

    function toStatement
      input WhenStatement wstmt;
      output Statement stmt;
    algorithm
      stmt := match wstmt
        case ASSIGN()     then Statement.ASSIGNMENT(wstmt.lhs, wstmt.rhs, Expression.typeOf(wstmt.lhs), wstmt.source);
        case REINIT()     then Statement.REINIT(Expression.fromCref(wstmt.stateVar), wstmt.value, wstmt.source);
        case ASSERT()     then Statement.ASSERT(wstmt.condition, wstmt.message, wstmt.level, wstmt.source);
        case TERMINATE()  then Statement.TERMINATE(wstmt.message, wstmt.source);
        case NORETCALL()  then Statement.NORETCALL(wstmt.exp, wstmt.source);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unrecognized statement: " + toString(wstmt)});
        then fail();
      end match;
    end toStatement;

    function toEquation
      "make assignments for assignment statements and an algorithm otherwise"
      input WhenStatement stmt;
      input EquationAttributes attr;
      input Boolean init;
      output Equation eqn;
    algorithm
      eqn := match stmt
        case ASSIGN() then Equation.makeAssignmentEqn(stmt.lhs, stmt.rhs, Iterator.EMPTY(), attr);
                      else Equation.setAttributes(Pointer.access(Equation.makeAlgorithm({toStatement(stmt)}, init)), attr);
      end match;
    end toEquation;

    function size
      input WhenStatement stmt;
      input Boolean resize = false;
      output Integer s;
    algorithm
      s := match stmt
        case ASSIGN() then Type.sizeOf(Expression.typeOf(stmt.lhs), resize);
                      else 0;
      end match;
    end size;

    function isAssign
      input WhenStatement stmt;
      output Boolean b;
    algorithm
      b := match stmt
        case ASSIGN() then true;
        else false;
      end match;
    end isAssign;

    function isAssignOrReinit
      input WhenStatement stmt;
      output Boolean b;
    algorithm
      b := match stmt
        case ASSIGN() then true;
        case REINIT() then true;
        else false;
      end match;
    end isAssignOrReinit;

    function getType
      input WhenStatement stmt;
      output Type ty;
    algorithm
      ty := match stmt
        case ASSIGN() then Expression.typeOf(stmt.lhs);
        else Type.ANY();
      end match;
    end getType;

    function map
      input output WhenStatement stmt;
      input MapFuncExp funcExp;
      input Option<MapFuncCref> funcCrefOpt;
      input MapFuncExpWrapper mapFunc;
    algorithm
      stmt := match stmt
        local
          MapFuncCref funcCref;
          Expression lhs, rhs, value, condition, message;
          ComponentRef stateVar;

        case ASSIGN()
          algorithm
            lhs := mapFunc(stmt.lhs, funcExp);
            rhs := mapFunc(stmt.rhs, funcExp);
            if not referenceEq(lhs, stmt.lhs) then
              stmt.lhs := lhs;
            end if;
            if not referenceEq(rhs, stmt.rhs) then
              stmt.rhs := rhs;
            end if;
        then stmt;

        case REINIT()
          algorithm
            if isSome(funcCrefOpt) then
              SOME(funcCref) := funcCrefOpt;
              stateVar := funcCref(stmt.stateVar);
              if not referenceEq(stateVar, stmt.stateVar) then
                stmt.stateVar := stateVar;
              end if;
            end if;
            value := mapFunc(stmt.value, funcExp);
            if not referenceEq(value, stmt.value) then
              stmt.value := value;
            end if;
        then stmt;

        case ASSERT()
          algorithm
            condition := mapFunc(stmt.condition, funcExp);
            if not referenceEq(condition, stmt.condition) then
              stmt.condition := condition;
            end if;
            message := mapFunc(stmt.message, funcExp);
            if not referenceEq(message, stmt.message) then
              stmt.message := message;
            end if;
        then stmt;

        case TERMINATE() then stmt;

        case NORETCALL()
          algorithm
            value := mapFunc(stmt.exp, funcExp);
            if not referenceEq(value, stmt.exp) then
              stmt.exp := value;
            end if;
        then stmt;

        else stmt;
      end match;
    end map;

    function convert
      input WhenStatement stmt;
      output OldBackendDAE.WhenOperator oldStmt;
    algorithm
      oldStmt := match stmt
        case ASSIGN() then OldBackendDAE.ASSIGN(
          left    = Expression.toDAE(stmt.lhs),
          right   = Expression.toDAE(stmt.rhs),
          source  = stmt.source
        );

        case REINIT() then OldBackendDAE.REINIT(
          stateVar  = ComponentRef.toDAE(stmt.stateVar),
          value     = Expression.toDAE(stmt.value),
          source    = stmt.source
        );

        case ASSERT() then OldBackendDAE.ASSERT(
          condition = Expression.toDAE(stmt.condition),
          message   = Expression.toDAE(stmt.message),
          level     = Expression.toDAE(stmt.level),
          source    = stmt.source
        );

        case TERMINATE() then OldBackendDAE.TERMINATE(
          message   = Expression.toDAE(stmt.message),
          source    = stmt.source
        );

        case NORETCALL() then OldBackendDAE.NORETCALL(
          exp       = Expression.toDAE(stmt.exp),
          source    = stmt.source
        );

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unrecognized statement: " + toString(stmt)});
        then fail();
      end match;
    end convert;
  end WhenStatement;

  uniontype EquationAttributes
    record EQUATION_ATTRIBUTES
      Option<Pointer<Equation>> derivative  "if the equation has been differentiated w.r.t time already";
      Option<Pointer<Variable>> residualVar "also used to represent the equation itself";
      Option<Integer> clock_idx             "only set if clocked eq";
      Boolean residual                      "true if in residual form";
      Boolean exclusively_initial           "true if in initial equation block";
      Evaluation.Stages evalStages          "evaluation stages (prior used for DAE mode, still necessary?)";
      EquationKind kind                     "continuous, clocked, discrete, empty";
    end EQUATION_ATTRIBUTES;

    function toString
      input EquationAttributes attr;
      input String indent = "";
      output String str;
    algorithm
      str := match attr
        local
          Pointer<Variable> residualVar;
        case EQUATION_ATTRIBUTES(residualVar = SOME(residualVar))
        then indent + "(" + ComponentRef.toString(BVariable.getVarName(residualVar)) + ")";
        else "";
      end match;
    end toString;

    function setKind
      input output EquationAttributes attr;
      input EquationKind kind;
      input Option<Integer> clock_idx = NONE();
    algorithm
      attr.kind := kind;
      attr.clock_idx := clock_idx;
    end setKind;

    function setResidualVar
      input output EquationAttributes attr;
      input Pointer<Variable> residualVar;
    algorithm
      attr.residualVar := SOME(residualVar);
    end setResidualVar;

    function getResidualVar
      input EquationAttributes attr;
      output Pointer<Variable> residualVar;
    algorithm
      try
        SOME(residualVar) := attr.residualVar;
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of missing residualVar!"});
      end try;
    end getResidualVar;

    function convert
      input EquationAttributes attributes;
      output OldBackendDAE.EquationAttributes oldAttributes;
    algorithm
      oldAttributes := OldBackendDAE.EQUATION_ATTRIBUTES(
        differentiated  = Util.isSome(attributes.derivative),
        kind            = convertEquationKind(attributes.kind, attributes.clock_idx, attributes.exclusively_initial),
        evalStages      = Evaluation.Stages.convert(attributes.evalStages));
    end convert;
  end EquationAttributes;

  function default
    input EquationKind kind;
    input Boolean exclusively_initial;
    input Option<Integer> clock_idx = NONE();
    output EquationAttributes attr;
  algorithm
    attr := EQUATION_ATTRIBUTES(
      derivative          = NONE(),
      residualVar         = NONE(),
      clock_idx           = clock_idx,
      residual            = false,
      exclusively_initial = exclusively_initial,
      evalStages          = NBEvaluation.DEFAULT_STAGES,
      kind                = kind);
  end default;

  type EquationKind = enumeration(CONTINUOUS, DISCRETE, CLOCKED, EMPTY, UNKNOWN);

  function convertEquationKind
    input EquationKind eqKind;
    input Option<Integer> clock_idx;
    input Boolean exclusively_initial;
    output OldBackendDAE.EquationKind oldEqKind;
  algorithm
    oldEqKind := match (eqKind, clock_idx)
      local
        Integer clk;
      case (_, _) guard(exclusively_initial)  then OldBackendDAE.INITIAL_EQUATION();
      case (EquationKind.CONTINUOUS, NONE())  then OldBackendDAE.DYNAMIC_EQUATION();
      case (EquationKind.CLOCKED, SOME(clk))  then OldBackendDAE.CLOCKED_EQUATION(clk);
      case (EquationKind.DISCRETE, NONE())    then OldBackendDAE.DISCRETE_EQUATION();
      case (EquationKind.EMPTY, NONE())       then OldBackendDAE.AUX_EQUATION();
      case (EquationKind.UNKNOWN, NONE())     then OldBackendDAE.UNKNOWN_EQUATION_KIND();
      case (_, SOME(clk)) algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because the non-clock equation kind "
          + equationKindString(eqKind, clock_idx, exclusively_initial) + " has a clock index."});
      then fail();
      case (EquationKind.CLOCKED, NONE()) algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because no clock index was provided for clocked equation."});
      then fail();
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " for an unknown reason."});
      then fail();
    end match;
  end convertEquationKind;

  function equationKindString
    input EquationKind eqKind;
    input Option<Integer> clock_idx;
    input Boolean exclusively_initial;
    output String str;
  algorithm
    str := match eqKind
      case EquationKind.CONTINUOUS  then "[CONT";
      case EquationKind.CLOCKED     then "[CLCK";
      case EquationKind.DISCRETE    then "[DISC";
      case EquationKind.EMPTY       then "[EMTY";
                                    else "[UKWN";
    end match;
    str := if exclusively_initial then "[INI]" + str else "[DAE]" + str;
    if Util.isSome(clock_idx) then
      str := str + "(" + intString(Util.getOption(clock_idx)) + ")]";
    else
      str := str + "]";
    end if;
  end equationKindString;

  uniontype EquationPointers
    record EQUATION_POINTERS
      UnorderedMap<ComponentRef, Integer> map   "Map for cref->index";
      ExpandableArray<Pointer<Equation>> eqArr;
    end EQUATION_POINTERS;

    function toString
      input EquationPointers equations;
      input output String str = "";
      input Option<array<tuple<Integer,Integer>>> mapping_opt = NONE();
      input Boolean printEmpty = true;
      input Option<UnorderedSet<String>> filter_opt = NONE();
    protected
      Integer luI = lastUsedIndex(equations);
      Integer length, scal_start, current_index = 1;
      String index;
      Boolean useMapping = Util.isSome(mapping_opt);
      Boolean filterEqs = Util.isSome(filter_opt);
      array<tuple<Integer,Integer>> mapping;
      UnorderedSet<String> filter;
      Pointer<Equation> eqn;
    algorithm
      // check if mapping is used
      if useMapping then
        length := 15;
        mapping := Util.getOption(mapping_opt);
      else
        length := 10;
      end if;

      // check if filter is used
      if filterEqs then
        filter := Util.getOption(filter_opt);
        str := "Filtered " + str;
      end if;

      if printEmpty or luI > 0 then
        str := StringUtil.headline_4(str + " Equations (" + intString(EquationPointers.size(equations)) + "/" + intString(scalarSize(equations, true)) + ")");
        for i in 1:luI loop
          if ExpandableArray.occupied(i, equations.eqArr) then
            eqn := ExpandableArray.get(i, equations.eqArr);
            if not filterEqs or UnorderedSet.contains(ComponentRef.toString(Equation.getEqnName(eqn)), filter) then
              if useMapping then
                (scal_start, _) := mapping[current_index];
                index := "(" + intString(current_index) + "|" + intString(scal_start) + ")";
              else
                index := "(" + intString(current_index) + ")";
              end if;
              index := index + StringUtil.repeat(" ", length - stringLength(index));
              str := str + Equation.toString(Pointer.access(eqn), index) + "\n";
            end if;
            current_index := current_index + 1;
          end if;
        end for;
        str := str + "\n";
      else
        str := "";
      end if;
    end toString;

    function empty
      "Creates an empty EquationPointers using given size."
      input Integer size = BaseHashTable.bigBucketSize;
      output EquationPointers equationPointers;
    protected
      Integer arr_size, bucketSize;
    algorithm
      arr_size := max(size, BaseHashTable.lowBucketSize);
      bucketSize := Util.nextPrime(arr_size);
      equationPointers := EQUATION_POINTERS(UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual, bucketSize), ExpandableArray.new(arr_size, Pointer.create(DUMMY_EQUATION())));
    end empty;

    function clone
      input EquationPointers equations;
      input Boolean shallow = true;
      output EquationPointers new;
    algorithm
      if shallow then
        new := fromList(toList(equations));
      else
        new := fromList(list(Pointer.create(Pointer.access(eqn)) for eqn in toList(equations)));
      end if;
    end clone;

    function size
      "returns the number of elements, not the actual scalarized number of equations!"
      input EquationPointers equations;
      output Integer sz = ExpandableArray.getNumberOfElements(equations.eqArr);
    end size;

    function scalarSize
      "returns the scalar size."
      input EquationPointers equations;
      input Boolean resize = false;
      output Integer sz = 0;
    algorithm
      for eqn_ptr in toList(equations) loop
        sz := sz + Equation.size(eqn_ptr, resize);
      end for;
    end scalarSize;

    function lastUsedIndex
      "returns the last used index != size!"
      input EquationPointers equations;
      output Integer sz = ExpandableArray.getLastUsedIndex(equations.eqArr);
    end lastUsedIndex;

    function toList
      "Creates a EquationPointer list from EquationPointers."
      input EquationPointers equations;
      output list<Pointer<Equation>> eqn_lst;
    algorithm
      eqn_lst := ExpandableArray.toList(equations.eqArr);
    end toList;

    function fromList
      input list<Pointer<Equation>> eq_lst;
      output EquationPointers equations;
    algorithm
      equations := empty(listLength(eq_lst));
      equations := addList(eq_lst, equations);
    end fromList;

    function addList
      input list<Pointer<Equation>> eq_lst;
      input output EquationPointers equations;
    algorithm
      equations := List.fold(eq_lst, function add(), equations);
    end addList;

    function removeList
      "Removes a list of equations from the EquationPointers structure."
      input list<Pointer<Equation>> eq_lst;
      input output EquationPointers equations;
    algorithm
      equations := List.fold(eq_lst, function remove(), equations);
      equations := compress(equations);
    end removeList;

    function add
      input Pointer<Equation> eqn;
      input output EquationPointers equations;
    protected
      ComponentRef name;
      Integer index;
    algorithm
      name := Equation.getEqnName(eqn);
      () := match UnorderedMap.get(name, equations.map)
        case SOME(index) guard(index > 0) algorithm
          ExpandableArray.update(index, eqn, equations.eqArr);
        then ();
        else algorithm
          (_, index) := ExpandableArray.add(eqn, equations.eqArr);
          UnorderedMap.add(name, index, equations.map);
        then ();
      end match;
    end add;

    function remove
      "Removes an equation pointer identified by its (residual var) name from the set."
      input Pointer<Equation> eqn;
      input output EquationPointers equations "only an output for mapping";
    protected
      ComponentRef name;
      Integer index;
    algorithm
      name := Equation.getEqnName(eqn);
      () := match UnorderedMap.get(name, equations.map)
        case SOME(index) guard(index > 0) algorithm
          ExpandableArray.delete(index, equations.eqArr);
          // set the index to -1 to avoid removing entries
          UnorderedMap.add(name, -1, equations.map);
        then ();
        else ();
      end match;
    end remove;

    function map
      "Traverses all equations and applies a function to them."
      input output EquationPointers equations;
      input MapFuncEqn func;
    protected
      Pointer<Equation> eq_ptr;
      Equation eq, new_eq;
      list<String> followEquations = Flags.getConfigStringList(Flags.DEBUG_FOLLOW_EQUATIONS);
      Boolean debug = not listEmpty(followEquations);
      UnorderedSet<String> debug_eqns;
    algorithm
      if debug then
        debug_eqns := UnorderedSet.fromList(followEquations, stringHashDjb2, stringEq);
      end if;

      for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          eq_ptr := ExpandableArray.get(i, equations.eqArr);
          eq := Pointer.access(eq_ptr);
          new_eq := func(eq);
          if not referenceEq(eq, new_eq) then
            // Do not update the expandable array entry, but the pointer itself
            if debug and (UnorderedSet.contains(ComponentRef.toString(Equation.getEqnName(eq_ptr)), debug_eqns)
              or UnorderedSet.contains(ComponentRef.toString(Equation.getEqnName(Pointer.create(new_eq))), debug_eqns))
              and not Equation.equalName(Pointer.create(eq), Pointer.create(new_eq)) then
              print("[debugFollowEquations] The equation:\n" + Equation.toString(eq) + "\nGets replaced by:\n"  + Equation.toString(new_eq) + "\n");
            end if;
            Pointer.update(eq_ptr, new_eq);
          end if;
        end if;
      end for;
    end map;

    function mapPtr
      "Traverses all equations wrapped in pointers and applies a function to them.
      Note: the equation can only be updated if the function itself updates it!"
      input EquationPointers equations;
      input MapFuncEqnPtr func;
    algorithm
      for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          func(ExpandableArray.get(i, equations.eqArr));
        end if;
      end for;
    end mapPtr;

    function mapExp
      "Traverses all expressions of all equations and applies a function to it.
      Optional second input to also traverse crefs, only needed for simple
      eqns, when eqns and algorithms."
      input output EquationPointers equations;
      input MapFuncExp funcExp;
      input Option<MapFuncCref> funcCrefOpt = NONE();
    protected
      Pointer<Equation> eq_ptr;
      Equation eq, new_eq;
    algorithm
      for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          eq_ptr := ExpandableArray.get(i, equations.eqArr);
          eq := Pointer.access(eq_ptr);
          new_eq := Equation.map(eq, funcExp, funcCrefOpt);
          if not referenceEq(eq, new_eq) then
            // Do not update the expandable array entry, but the pointer itself
            Pointer.update(eq_ptr, new_eq);
          end if;
        end if;
      end for;
    end mapExp;

    function mapRemovePtr
      "Traverses all equation pointers and may invoke to remove the equation pointer
      (does not affect other instances of the equation)"
      input output EquationPointers equations;
      input checkEqn func;
    protected
      Pointer<Equation> eq_ptr;
    algorithm
      for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          eq_ptr := ExpandableArray.get(i, equations.eqArr);
          if func(eq_ptr) then
            equations := remove(eq_ptr, equations);
          end if;
        end if;
      end for;
      equations := compress(equations);
    end mapRemovePtr;

    function mapRes
      "maps the residual variable"
      input EquationPointers equations;
      input mapFunc func;
      partial function mapFunc
        input Pointer<Variable> var;
      end mapFunc;
    algorithm
      for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          func(Equation.getResidualVar(ExpandableArray.get(i, equations.eqArr)));
        end if;
      end for;
    end mapRes;

    function fold<T>
      "Traverses all equations and applies a function to them to accumulate data.
      Cannot change equations."
      input EquationPointers equations;
      input MapFunc func;
      input output T extArg;
      partial function MapFunc
        input Equation e;
        input output T extArg;
      end MapFunc;
    algorithm
      for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          extArg := func(Pointer.access(ExpandableArray.get(i, equations.eqArr)), extArg);
        end if;
      end for;
    end fold;

    function foldPtr<T>
      "Traverses all equations and applies a function to them to accumulate data.
      Can change the equation pointer."
      input EquationPointers equations;
      input MapFunc func;
      input output T extArg;
      partial function MapFunc
        input Pointer<Equation> e;
        input output T extArg;
      end MapFunc;
    algorithm
      for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          extArg := func(ExpandableArray.get(i, equations.eqArr), extArg);
        end if;
      end for;
    end foldPtr;

    function foldRemovePtr<T>
      "Traverses all equation pointers and applies a function to them to accumulate data.
      Can invoke to delete the equation pointer. (also deletes other instances of the equation.
      Take care to keep a copy if you want to add it back later)"
      input output EquationPointers equations;
      input MapFunc func;
      input output T extArg;
      partial function MapFunc
        input Pointer<Equation> e;
        input output T extArg;
        output Boolean delete;
      end MapFunc;
    protected
      Pointer<Equation> eq_ptr;
      Boolean delete;
    algorithm
      for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          eq_ptr := ExpandableArray.get(i, equations.eqArr);
          (extArg, delete) := func(eq_ptr, extArg);
          if delete then
            // change the pointer to point to an empty equation
            Pointer.update(eq_ptr, DUMMY_EQUATION());
            // delete this pointer instance
            equations.eqArr := ExpandableArray.delete(i, equations.eqArr);
          end if;
        end if;
      end for;
    end foldRemovePtr;

    function getEqnAt "O(1)
      Returns the equation pointer at given index. If there is none it fails."
      input EquationPointers equations;
      input Integer index;
      output Pointer<Equation> eqn;
    algorithm
      eqn := ExpandableArray.get(index, equations.eqArr);
    end getEqnAt;

    function getEqnByName "O(1)
      Returns the equation with specified name, fails if it does not exist."
      input EquationPointers equations;
      input ComponentRef name;
      output Pointer<Equation> eqn;
    algorithm
      eqn := match UnorderedMap.get(name, equations.map)
        local
          Integer index;
        case SOME(index) guard(index > 0)
        then getEqnAt(equations, index);

        case SOME(index) algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because the equation with the name " + ComponentRef.toString(name) + " has already been deleted."});
        then fail();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because there is no equation with the name " + ComponentRef.toString(name) + "."});
        then fail();
      end match;
    end getEqnByName;

    function getEqnIndex
      "Returns -1 if cref was deleted or cannot be found."
      input EquationPointers equations;
      input ComponentRef name;
      output Integer index = UnorderedMap.getOrDefault(name, equations.map, -1);
    end getEqnIndex;

    function compress "O(n)
      Recollects the elements in order to remove all the gaps.
      Be careful: This changes the indices of the elements."
      input output EquationPointers equations;
    protected
      Pointer<Equation> eqn;
      list<Pointer<Equation>> eqns = {};
    algorithm
      // collect non-empty equations
      for i in ExpandableArray.getLastUsedIndex(equations.eqArr):-1:1 loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          eqn := ExpandableArray.get(i, equations.eqArr);
          () := match Pointer.access(eqn)
            local
              list<Equation> body;
            // todo: add for IF and WHEN
            case Equation.DUMMY_EQUATION() then ();
            case Equation.FOR_EQUATION(body = body) guard(List.all(body, Equation.isDummy)) then ();
            else algorithm
              eqns := eqn :: eqns;
            then ();
          end match;
        end if;
      end for;
      equations := fromList(eqns);
    end compress;

    function sort
      "author: kabdelhak
      Sorts the equations solely by cref and operator attributes and type hash.
      Does not use the name! Used for reproduceable heuristic behavior independent of names."
      input output EquationPointers equations;
    protected
      Integer size;
      list<tuple<Integer, Pointer<Equation>>> hash_lst;
      Pointer<list<tuple<Integer, Pointer<Equation>>>> hash_lst_ptr = Pointer.create({});
      Pointer<Equation> eqn_ptr;
    algorithm
      // use number of elements
      size := ExpandableArray.getNumberOfElements(equations.eqArr);
      // hash all equations and create hash - equation tpl list
      mapPtr(equations, function createSortHashTpl(mod = realInt(size * log(size)), hash_lst_ptr = hash_lst_ptr));
      hash_lst := List.sort(Pointer.access(hash_lst_ptr), BackendUtil.indexTplGt);
      // add the equations one by one in sorted order
      equations := empty(size);
      for tpl in hash_lst loop
        (_, eqn_ptr) := tpl;
        equations.eqArr := ExpandableArray.add(eqn_ptr, equations.eqArr);
      end for;
    end sort;

    function getResiduals
      input EquationPointers equations;
      output VariablePointers residuals;
    algorithm
      residuals := VariablePointers.fromList(list(Equation.getResidualVar(eqn) for eqn in EquationPointers.toList(equations)));
    end getResiduals;

  protected
    function createSortHashTpl
      "Helper function for sort(). Creates the hash value without considering the names and
      adds it as a tuple to the list in pointer."
      input output Pointer<Equation> eqn_ptr;
      input Integer mod;
      input Pointer<list<tuple<Integer, Pointer<Equation>>>> hash_lst_ptr;
    protected
      Equation eqn;
      Integer hash;
    algorithm
      eqn := Pointer.access(eqn_ptr);
      // create hash only from attributes
      hash := BackendUtil.noNameHashEq(eqn, mod);
      Pointer.update(hash_lst_ptr, (hash, eqn_ptr) :: Pointer.access(hash_lst_ptr));
    end createSortHashTpl;
  end EquationPointers;

  uniontype EqData
    record EQ_DATA_SIM
      Pointer<Integer> uniqueIndex  "current index to be used for new identifier";
      EquationPointers equations    "All equations";
      EquationPointers simulation   "All equations for simulation (without initial)";
      EquationPointers continuous   "Continuous equations";
      EquationPointers clocked      "Clocked equations";
      EquationPointers discretes    "Discrete equations";
      EquationPointers initials     "(Exclusively) Initial equations";
      EquationPointers auxiliaries  "Auxiliary equations";
      EquationPointers removed      "Removed equations (alias and no return value)";
    end EQ_DATA_SIM;

    record EQ_DATA_JAC
      Pointer<Integer> uniqueIndex  "current index to be used for new identifier";
      EquationPointers equations    "All equations";
      EquationPointers results      "Result equations";
      EquationPointers temporary    "Temporary inner equations";
      EquationPointers auxiliaries  "Auxiliary equations";
      EquationPointers removed      "Removed equations (alias and no return value)";
    end EQ_DATA_JAC;

    record EQ_DATA_HES
      Pointer<Integer> uniqueIndex  "current index to be used for new identifier";
      EquationPointers equations    "All equations";
      Pointer<Equation> result      "Result equation";
      EquationPointers temporary    "Temporary inner equations";
      EquationPointers auxiliaries  "Auxiliary equations";
      EquationPointers removed      "Removed equations (alias and no return value)";
    end EQ_DATA_HES;

    record EQ_DATA_EMPTY end EQ_DATA_EMPTY;

    function size
      input EqData eqData;
      output Integer s;
    algorithm
      s := match eqData
        case EQ_DATA_SIM() then EquationPointers.size(eqData.simulation);
        case EQ_DATA_JAC() then EquationPointers.size(eqData.equations);
        case EQ_DATA_HES() then EquationPointers.size(eqData.equations);
      end match;
    end size;

    function scalarSize
      input EqData eqData;
      input Boolean resize = false;
      output Integer s;
    algorithm
      s := match eqData
        case EQ_DATA_SIM() then EquationPointers.scalarSize(eqData.simulation, resize);
        case EQ_DATA_JAC() then EquationPointers.scalarSize(eqData.equations, resize);
        case EQ_DATA_HES() then EquationPointers.scalarSize(eqData.equations, resize);
      end match;
    end scalarSize;

    function map
      input output EqData eqData;
      input MapFuncEqn func;
    algorithm
      eqData := match eqData
        case EqData.EQ_DATA_SIM() algorithm
          // we do not want to traverse removed equations, otherwise we could break them
          eqData.simulation   := EquationPointers.map(eqData.simulation, func);
          eqData.continuous   := EquationPointers.map(eqData.continuous, func);
          eqData.clocked      := EquationPointers.map(eqData.clocked, func);
          eqData.discretes    := EquationPointers.map(eqData.discretes, func);
          eqData.initials     := EquationPointers.map(eqData.initials, func);
          eqData.auxiliaries  := EquationPointers.map(eqData.auxiliaries, func);
        then eqData;

        case EqData.EQ_DATA_JAC() algorithm
          eqData.results      := EquationPointers.map(eqData.results, func);
          eqData.temporary    := EquationPointers.map(eqData.temporary, func);
          eqData.auxiliaries  := EquationPointers.map(eqData.auxiliaries, func);
        then eqData;

        case EqData.EQ_DATA_HES() algorithm
          Pointer.update(eqData.result, func(Pointer.access(eqData.result)));
          eqData.temporary    := EquationPointers.map(eqData.temporary, func);
          eqData.auxiliaries  := EquationPointers.map(eqData.auxiliaries, func);
        then eqData;
      end match;
    end map;

    function mapExp
      input output EqData eqData;
      input MapFuncExp func;
    algorithm
      eqData := match eqData
        case EqData.EQ_DATA_SIM() algorithm
          // we do not want to traverse removed equations, otherwise we could break them
          eqData.simulation   := EquationPointers.mapExp(eqData.simulation, func);
          eqData.continuous   := EquationPointers.mapExp(eqData.continuous, func);
          eqData.clocked      := EquationPointers.mapExp(eqData.clocked, func);
          eqData.discretes    := EquationPointers.mapExp(eqData.discretes, func);
          eqData.initials     := EquationPointers.mapExp(eqData.initials, func);
          eqData.auxiliaries  := EquationPointers.mapExp(eqData.auxiliaries, func);
          eqData.removed      := EquationPointers.mapExp(eqData.removed, func);
        then eqData;

        case EqData.EQ_DATA_JAC() algorithm
          eqData.results      := EquationPointers.mapExp(eqData.results, func);
          eqData.temporary    := EquationPointers.mapExp(eqData.temporary, func);
          eqData.auxiliaries  := EquationPointers.mapExp(eqData.auxiliaries, func);
          eqData.removed      := EquationPointers.mapExp(eqData.removed, func);
        then eqData;

        case EqData.EQ_DATA_HES() algorithm
          Pointer.update(eqData.result, Equation.map(Pointer.access(eqData.result), func));
          eqData.temporary    := EquationPointers.mapExp(eqData.temporary, func);
          eqData.auxiliaries  := EquationPointers.mapExp(eqData.auxiliaries, func);
          eqData.removed      := EquationPointers.mapExp(eqData.removed, func);
        then eqData;
      end match;
    end mapExp;

    function toString
      input EqData eqData;
      input Integer level = 0;
      input Option<UnorderedSet<String>> filter_opt = NONE();
      output String str;
    algorithm
      str := match eqData
        local
          String tmp;

        case EQ_DATA_SIM()
          algorithm
            tmp := "Equation Data Simulation (scalar simulation equations: " + intString(EquationPointers.scalarSize(eqData.simulation, true)) + ")";
            tmp := StringUtil.headline_2(tmp) + "\n";
            if level == 0 then
              tmp :=  tmp + EquationPointers.toString(eqData.equations, "Simulation", NONE(), false, filter_opt);
            else
              tmp :=  tmp + EquationPointers.toString(eqData.continuous, "Continuous", NONE(), false, filter_opt) +
                      EquationPointers.toString(eqData.clocked, "Clocked", NONE(), false, filter_opt) +
                      EquationPointers.toString(eqData.discretes, "Discrete", NONE(), false, filter_opt) +
                      EquationPointers.toString(eqData.initials, "(Exclusively) Initial", NONE(), false, filter_opt) +
                      EquationPointers.toString(eqData.auxiliaries, "Auxiliary", NONE(), false, filter_opt) +
                      EquationPointers.toString(eqData.removed, "Removed", NONE(), false, filter_opt);
            end if;
        then tmp;

        case EQ_DATA_JAC()
          algorithm
            if level == 0 then
              tmp :=  EquationPointers.toString(eqData.equations, "Jacobian", NONE(), false, filter_opt);
            else
              tmp :=  EquationPointers.toString(eqData.results, "Residual", NONE(), false, filter_opt) +
                      EquationPointers.toString(eqData.temporary, "Inner", NONE(), false, filter_opt) +
                      EquationPointers.toString(eqData.auxiliaries, "Auxiliary", NONE(), false, filter_opt);
            end if;
        then tmp;

        case EQ_DATA_HES()
          algorithm
            if level == 0 then
              tmp :=  EquationPointers.toString(eqData.equations, "Hessian", NONE(), false, filter_opt);
            else
              tmp :=  StringUtil.headline_4("Result Equation") + "\n" +
                      Equation.toString(Pointer.access(eqData.result)) + "\n" +
                      EquationPointers.toString(eqData.temporary, "Temporary Inner", NONE(), false, filter_opt) +
                      EquationPointers.toString(eqData.auxiliaries, "Auxiliary", NONE(), false, filter_opt);
            end if;
        then tmp;

        case EQ_DATA_EMPTY() then "Empty equation Data!\n";

        else getInstanceName() + " failed!\n";
      end match;
    end toString;

    function getUniqueIndex
      input EqData eqData;
      output Pointer<Integer> uniqueIndex;
    algorithm
      uniqueIndex := match eqData
        case EqData.EQ_DATA_SIM() then eqData.uniqueIndex;
        case EqData.EQ_DATA_JAC() then eqData.uniqueIndex;
        case EqData.EQ_DATA_HES() then eqData.uniqueIndex;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end getUniqueIndex;

    function getEquations
      input EqData eqData;
      output EquationPointers equations;
    algorithm
      equations := match eqData
        case EqData.EQ_DATA_SIM() then eqData.equations;
        case EqData.EQ_DATA_JAC() then eqData.equations;
        case EqData.EQ_DATA_HES() then eqData.equations;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end getEquations;

    function setEquations
      input output EqData eqData;
      input EquationPointers equations;
    algorithm
      eqData := match eqData
        case EQ_DATA_SIM() algorithm eqData.equations := equations; then eqData;
        case EQ_DATA_JAC() algorithm eqData.equations := equations; then eqData;
        case EQ_DATA_HES() algorithm eqData.equations := equations; then eqData;
      end match;
    end setEquations;

    type EqType = enumeration(CONTINUOUS, DISCRETE, CLOCKED, INITIAL);

    function addTypedList
      input output EqData eqData;
      input list<Pointer<Equation>> eq_lst;
      input EqType eqType;
      input Boolean newName = true;
    algorithm
      eqData := match (eqData, eqType)

        case (EQ_DATA_SIM(), EqType.CONTINUOUS) algorithm
          if newName then
            for eqn_ptr in eq_lst loop
              Equation.createName(eqn_ptr, eqData.uniqueIndex, SIMULATION_STR);
            end for;
          end if;
          eqData.equations := EquationPointers.addList(eq_lst, eqData.equations);
          eqData.simulation := EquationPointers.addList(eq_lst, eqData.simulation);
          eqData.continuous := EquationPointers.addList(eq_lst, eqData.continuous);
        then eqData;

        case (EQ_DATA_SIM(), EqType.DISCRETE) algorithm
          if newName then
            for eqn_ptr in eq_lst loop
              Equation.createName(eqn_ptr, eqData.uniqueIndex, SIMULATION_STR);
            end for;
          end if;
          eqData.equations := EquationPointers.addList(eq_lst, eqData.equations);
          eqData.simulation := EquationPointers.addList(eq_lst, eqData.simulation);
          eqData.discretes := EquationPointers.addList(eq_lst, eqData.discretes);
        then eqData;

        case (EQ_DATA_SIM(), EqType.CLOCKED) algorithm
          if newName then
            for eqn_ptr in eq_lst loop
              Equation.createName(eqn_ptr, eqData.uniqueIndex, SIMULATION_STR);
            end for;
          end if;
          eqData.clocked := EquationPointers.addList(eq_lst, eqData.clocked);
        then eqData;

        case (EQ_DATA_SIM(), EqType.INITIAL) algorithm
          if newName then
            for eqn_ptr in eq_lst loop
              Equation.createName(eqn_ptr, eqData.uniqueIndex, SIMULATION_STR);
            end for;
          end if;
          eqData.equations := EquationPointers.addList(eq_lst, eqData.equations);
          eqData.initials := EquationPointers.addList(eq_lst, eqData.initials);
        then eqData;

        // ToDo: other cases

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end addTypedList;

    function addUntypedList
      input output EqData eqData;
      input list<Pointer<Equation>> eq_lst;
      input Boolean newName = true;
    protected
      list<Pointer<Equation>> equation_lst, continuous_lst, clocked_lst, discretes_lst, initials_lst, auxiliaries_lst, simulation_lst, removed_lst;
    algorithm

      eqData := match eqData
        case EQ_DATA_SIM() algorithm
          if newName then
            for eqn_ptr in eq_lst loop
              Equation.createName(eqn_ptr, eqData.uniqueIndex, SIMULATION_STR);
            end for;
          end if;
          (simulation_lst, continuous_lst, clocked_lst, discretes_lst, initials_lst, auxiliaries_lst, removed_lst) := typeList(eq_lst);
          eqData.equations    := EquationPointers.addList(eq_lst, eqData.equations);
          eqData.simulation   := EquationPointers.addList(simulation_lst, eqData.simulation);
          eqData.continuous   := EquationPointers.addList(continuous_lst, eqData.continuous);
          eqData.clocked      := EquationPointers.addList(clocked_lst, eqData.clocked);
          eqData.discretes    := EquationPointers.addList(discretes_lst, eqData.discretes);
          eqData.initials     := EquationPointers.addList(initials_lst, eqData.initials);
          eqData.auxiliaries  := EquationPointers.addList(auxiliaries_lst, eqData.auxiliaries);
          eqData.removed      := EquationPointers.addList(removed_lst, eqData.removed);
        then eqData;

        // ToDo: other cases

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end addUntypedList;

    function removeList
      input list<Pointer<Equation>> eq_lst;
      input output EqData eqData;
    algorithm
      eqData := match eqData
        case EQ_DATA_SIM() algorithm
          eqData.equations    := EquationPointers.removeList(eq_lst, eqData.equations);
          eqData.simulation   := EquationPointers.removeList(eq_lst, eqData.simulation);
          eqData.continuous   := EquationPointers.removeList(eq_lst, eqData.continuous);
          eqData.discretes    := EquationPointers.removeList(eq_lst, eqData.discretes);
          eqData.initials     := EquationPointers.removeList(eq_lst, eqData.initials);
          eqData.auxiliaries  := EquationPointers.removeList(eq_lst, eqData.auxiliaries);
          eqData.removed      := EquationPointers.removeList(eq_lst, eqData.removed);
        then eqData;

        case EQ_DATA_JAC() algorithm
          eqData.equations    := EquationPointers.removeList(eq_lst, eqData.equations);
          eqData.results      := EquationPointers.removeList(eq_lst, eqData.results);
          eqData.temporary    := EquationPointers.removeList(eq_lst, eqData.temporary);
          eqData.auxiliaries  := EquationPointers.removeList(eq_lst, eqData.auxiliaries);
          eqData.removed      := EquationPointers.removeList(eq_lst, eqData.removed);
        then eqData;

        case EQ_DATA_HES() algorithm
          eqData.equations    := EquationPointers.removeList(eq_lst, eqData.equations);
          eqData.temporary    := EquationPointers.removeList(eq_lst, eqData.temporary);
          eqData.auxiliaries  := EquationPointers.removeList(eq_lst, eqData.auxiliaries);
          eqData.removed      := EquationPointers.removeList(eq_lst, eqData.removed);
        then eqData;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end removeList;

    function compress
      input output EqData eqData;
    algorithm
      eqData := match eqData
        case EQ_DATA_SIM() algorithm
          eqData.equations    := EquationPointers.compress(eqData.equations);
          eqData.simulation   := EquationPointers.compress(eqData.simulation);
          eqData.continuous   := EquationPointers.compress(eqData.continuous);
          eqData.discretes    := EquationPointers.compress(eqData.discretes);
          eqData.initials     := EquationPointers.compress(eqData.initials);
          eqData.auxiliaries  := EquationPointers.compress(eqData.auxiliaries);
          eqData.removed      := EquationPointers.compress(eqData.removed);
        then eqData;

        case EQ_DATA_JAC() algorithm
          eqData.equations    := EquationPointers.compress(eqData.equations);
          eqData.results      := EquationPointers.compress(eqData.results);
          eqData.temporary    := EquationPointers.compress(eqData.temporary);
          eqData.auxiliaries  := EquationPointers.compress(eqData.auxiliaries);
          eqData.removed      := EquationPointers.compress(eqData.removed);
        then eqData;

        case EQ_DATA_HES() algorithm
          eqData.equations    := EquationPointers.compress(eqData.equations);
          eqData.temporary    := EquationPointers.compress(eqData.temporary);
          eqData.auxiliaries  := EquationPointers.compress(eqData.auxiliaries);
          eqData.removed      := EquationPointers.compress(eqData.removed);
        then eqData;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end compress;
  end EqData;

  function typeList
    input list<Pointer<Equation>> equations;
    output list<Pointer<Equation>> simulation_lst = {};
    output list<Pointer<Equation>> continuous_lst = {};
    output list<Pointer<Equation>> clocked_lst = {};
    output list<Pointer<Equation>> discretes_lst = {};
    output list<Pointer<Equation>> initials_lst = {};
    output list<Pointer<Equation>> auxiliaries_lst = {};
    output list<Pointer<Equation>> removed_lst = {};
  algorithm
    for eq in equations loop
      () := match Equation.getAttributes(Pointer.access(eq))
        case EQUATION_ATTRIBUTES(exclusively_initial = true)
          algorithm
            initials_lst := eq :: initials_lst;
        then ();

        case EQUATION_ATTRIBUTES(kind = EquationKind.CONTINUOUS)
          algorithm
            continuous_lst := eq :: continuous_lst;
            simulation_lst := eq :: simulation_lst;
        then ();

        case EQUATION_ATTRIBUTES(kind = EquationKind.CLOCKED)
          algorithm
            clocked_lst := eq :: clocked_lst;
        then ();

        case EQUATION_ATTRIBUTES(kind = EquationKind.DISCRETE)
          algorithm
            discretes_lst := eq :: discretes_lst;
            simulation_lst := eq :: simulation_lst;
        then ();

        case EQUATION_ATTRIBUTES(kind = EquationKind.EMPTY)
          algorithm
            removed_lst := eq :: removed_lst;
        then ();

        else
          algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for\n" + Equation.toString(Pointer.access(eq))});
        then fail();
      end match;
    end for;
  end typeList;

  annotation(__OpenModelica_Interface="backend");
end NBEquation;
