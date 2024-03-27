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
  import BackendExtension = NFBackendExtension;
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
  import Statement = NFStatement;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;

  // Old Backend imports
  import OldBackendDAE = BackendDAE;

  // New Backend imports
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

  type EquationPointer = Pointer<Equation> "mainly used for mapping purposes";

  // used to process different outcomes of slicing from Util/Slice.mo
  // have to be defined here and not in Util/Slice.mo because it is a uniontype and not a package
  type Frame                = tuple<ComponentRef, Expression>                       "iterator-like tuple for array handling";
  type FrameLocation        = tuple<array<Integer>, Frame>                          "sliced frame at specific sub locations";
  type SlicingStatus        = enumeration(UNCHANGED, TRIVIAL, NONTRIVIAL, FAILURE)  "final result of slicing";
  type RecollectStatus      = enumeration(SUCCESS, FAILURE)                         "result of sub-routine recollect";
  type FrameOrderingStatus  = enumeration(UNCHANGED, CHANGED, FAILURE)              "result of sub-routine frame ordering";

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

  uniontype Iterator
    record SINGLE
      ComponentRef name           "the name of the iterator";
      Expression range            "range as <start, step, stop>";
    end SINGLE;

    record NESTED
      array<ComponentRef> names   "sorted iterator names";
      array<Expression> ranges    "sorted ranges as <start, step, stop>";
    end NESTED;

    record EMPTY
    end EMPTY;

    function fromFrames
      input list<Frame> frames;
      output Iterator iter;
    protected
      list<ComponentRef> names;
      list<Expression> ranges;
      ComponentRef name;
      Expression range;
    algorithm
      if listEmpty(frames) then
        iter := EMPTY();
      else
        (names, ranges) := List.unzip(frames);
        iter := match (names, ranges)
          case ({name}, {range})  then SINGLE(name, range);
                                  else NESTED(listArray(names), listArray(ranges));
        end match;
      end if;
    end fromFrames;

    function getFrames
      input Iterator iter;
      output list<ComponentRef> names;
      output list<Expression> ranges;
    algorithm
      (names, ranges) := match iter
        case SINGLE() then ({iter.name}, {iter.range});
        case NESTED() then (arrayList(iter.names), arrayList(iter.ranges));
        case EMPTY()  then ({}, {});
      end match;
    end getFrames;

    function merge
      "merges multiple iterators to one NESTED() iterator"
      input list<Iterator> iterators;
      output Iterator result;
    protected
      list<ComponentRef> tmp_names, names = {};
      list<Expression> tmp_ranges, ranges = {};
    algorithm
      if listLength(iterators) == 1 then
        result := List.first(iterators);
      else
        for iter in listReverse(iterators) loop
          (tmp_names, tmp_ranges) := getFrames(iter);
          names := listAppend(tmp_names, names);
          ranges := listAppend(tmp_ranges, ranges);
        end for;
        result := NESTED(listArray(names), listArray(ranges));
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
    algorithm
      (names, ranges) := getFrames(iterator);
      for tpl in List.zip(names, ranges) loop
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
        case (SINGLE(), SINGLE()) then Expression.isEqual(iter1.range, iter2.range);
        case (NESTED(), NESTED()) algorithm
          if arrayLength(iter1.ranges) == arrayLength(iter2.ranges) then
            for i in 1:arrayLength(iter1.ranges) loop
              b := Expression.isEqual(iter1.ranges[i], iter2.ranges[i]);
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
                  stop  = Expression.INTEGER(stop_min)
                )
              );
            end if;

            // create rest
            rest1 := intersectRest(iter1.name, start1, step1, stop1, start_max-step1, stop_min+step1);
            rest2 := intersectRest(iter2.name, start2, step2, stop2, start_max-step2, stop_min+step2);
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
            stop  = Expression.INTEGER(start_max)
          )
        );
      end if;

      if stop_min > stop  then
        rest_right := EMPTY();
      else
        rest_right := Iterator.SINGLE(
          name  = name,
          range = Expression.makeRange(
            start = Expression.INTEGER(stop_min),
            step  = SOME(Expression.INTEGER(step)),
            stop  = Expression.INTEGER(stop)
          )
        );
      end if;
      rest := (rest_left, rest_right);
    end intersectRest;

    function sizes
      input Iterator iter;
      output list<Integer> sizes "outermost first!";
    algorithm
      sizes := match iter
        case SINGLE() then {Expression.rangeSize(iter.range)};
        case NESTED() then list(Expression.rangeSize(iter.ranges[i]) for i in 1:arrayLength(iter.ranges));
        case EMPTY()  then {};
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " could not get sizes for: " + toString(iter) + "\n"});
        then fail();
      end match;
    end sizes;

    function size
      input Iterator iter;
      output Integer size = product(i for i in 1 :: sizes(iter));
    end size;

    function dimensions
      input Iterator iter;
      output list<Dimension> dims = list(Dimension.fromInteger(s) for s in sizes(iter));
    end dimensions;

    function createLocationReplacements
      "adds replacements rules for a single frame location"
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
        then ();

        case NESTED() guard(arrayLength(location) == arrayLength(iter.ranges)) algorithm
          for i in 1:arrayLength(location) loop
            (start, step, _) := Expression.getIntegerRange(iter.ranges[i]);
            UnorderedMap.add(iter.names[i], Expression.INTEGER(start + location[i]*step), replacements);
          end for;
        then ();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " could not create replacements for location: "
            + List.toString(arrayList(location), intString) + " and iterator: " + toString(iter) + "\n"});
        then fail();
      end match;
    end createLocationReplacements;

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

    function extract
      "takes an expression and maps it to find all occuring iterators.
      returns an iterator if all iterators are equal, fails otherwise.
      also replaces all array constructors with indexed expressions."
      output Iterator iter;
      input output Expression exp;
    protected
      UnorderedMap<ComponentRef, Expression> replacements = UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
    algorithm
      (exp, iter) := Expression.mapFold(exp, function extractFromCall(replacements = replacements), EMPTY());
      exp := Expression.map(exp, function Replacements.applySimpleExp(replacements = replacements));
    end extract;

    function extractFromCall
      "helper function for extract()"
      input output Expression exp;
      input output Iterator iter;
      input UnorderedMap<ComponentRef, Expression> replacements   "replacement rules";
    algorithm
      (exp, iter) := match exp
        local
          Call call;
          list<Frame> frames = {};
          InstNode node;
          Expression range;
          Iterator tmp;

        case Expression.CALL(call = call as Call.TYPED_ARRAY_CONSTRUCTOR()) algorithm
          for tpl in listReverse(call.iters) loop
            (node, range) := tpl;
            frames := (ComponentRef.fromNode(node, Type.INTEGER(), {}, NFComponentRef.Origin.ITERATOR), range) :: frames;
          end for;
          tmp := fromFrames(frames);
          if not isEmpty(iter) then
            createReplacement(iter, tmp, replacements);
          else
            iter := tmp;
          end if;
        then (call.exp, iter);

        else (exp, iter);
      end match;
    end extractFromCall;

    function normalizedSubscripts
      "creates a normalized subscript list such that the traversed iterators result in
      consecutive indices starting at 1."
      input Iterator iter;
      output list<Subscript> subs;
    protected
      list<ComponentRef> names;
      list<Expression> ranges;
    algorithm
      (names, ranges) := getFrames(iter);
      subs := list(normalizedSubscript(frame) for frame in List.zip(names, ranges));
    end normalizedSubscripts;

    function normalizedSubscript
      "returns subscripts such that traversing the range results in consecutive subscript values 1,2,3....
      e.g: i in 10:-2:1 -> x[(i-10)/(-2) + 1] which results in 1,2,3... for i=10,8,6..."
      input tuple<ComponentRef, Expression> frame;
      output Subscript sub;
    protected
      ComponentRef iter_name;
      Expression range, step, sub_exp;
      Type ty = Type.REAL();
    algorithm
      (iter_name, range) := frame;
      sub := match range

        // (iterator-start)/step + 1
        case Expression.RANGE() algorithm
          step := Util.getOptionOrDefault(range.step, Expression.INTEGER(1));
          sub_exp := Expression.fromCref(iter_name);
          // if start and step are equal to 1, make simple expression (simplify is not strong enough yet)
          if not (Expression.isOne(range.start) and Expression.isOne(step)) then
            sub_exp := Expression.MULTARY(
              arguments = {Expression.MULTARY(
                arguments = {Expression.MULTARY(
                  arguments = {sub_exp},
                  inv_arguments = {range.start},
                  operator = Operator.makeAdd(ty))},
                inv_arguments = {step},
                operator = Operator.makeMul(ty)),
              Expression.INTEGER(1)},
            inv_arguments = {},
            operator = Operator.makeAdd(ty));
            sub_exp := SimplifyExp.simplifyDump(sub_exp, true, getInstanceName());
            sub_exp := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.INTEGER_REAL, {sub_exp}, Variability.DISCRETE, Purity.PURE));
          end if;
        then Subscript.INDEX(sub_exp);

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
            + " failed because range is no range: " + Expression.toString(range)});
        then fail();
      end match;
    end normalizedSubscript;

    function toString
      input Iterator iter;
      output String str = "";
    protected
      function singleStr
        input ComponentRef name;
        input Expression range;
        output String str = ComponentRef.toString(name) + " in " + Expression.toString(range);
      end singleStr;
    algorithm
      str := match iter
        case SINGLE() then singleStr(iter.name, iter.range);
        case NESTED() then "{" + stringDelimitList(list(singleStr(iter.names[i], iter.ranges[i]) for i in 1:arrayLength(iter.names)), ", ") + "}";
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
      String s = "(" + intString(Equation.size(Pointer.create(eq))) + ")";
      String tupl_recd_str;
    algorithm
      str := match eq
        case SCALAR_EQUATION() then str + "[SCAL] " + s + " " + Expression.toString(eq.lhs) + " = " + Expression.toString(eq.rhs) + EquationAttributes.toString(eq.attr, " ");
        case ARRAY_EQUATION()  then str + "[ARRY] " + s + " " + Expression.toString(eq.lhs) + " = " + Expression.toString(eq.rhs) + EquationAttributes.toString(eq.attr, " ");
        case RECORD_EQUATION() algorithm
          tupl_recd_str := if Type.isTuple(eq.ty) then "[TUPL] " else "[RECD] ";
        then str + tupl_recd_str + s + " " + Expression.toString(eq.lhs) + " = " + Expression.toString(eq.rhs) + EquationAttributes.toString(eq.attr, " ");
        case ALGORITHM()       then str + "[ALGO] " + s + EquationAttributes.toString(eq.attr, " ") + "\n" + Algorithm.toString(eq.alg, str + "[----] ");
        case IF_EQUATION()     then str + IfEquationBody.toString(eq.body, str + "[----] ", "[-IF-] " + s);
        case FOR_EQUATION()    then str + forEquationToString(eq.iter, eq.body, "", str + "[----] ", "[FOR-] " + s + EquationAttributes.toString(eq.attr, " "));
        case WHEN_EQUATION()   then str + WhenEquationBody.toString(eq.body, str + "[----] ", "[WHEN] " + s);
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
      output Integer s;
    protected
      Equation eqn;
    algorithm
      eqn := Pointer.access(eqn_ptr);
      s := match eqn
        local
          Equation body;
        case SCALAR_EQUATION()            then 1;
        case ARRAY_EQUATION()             then Type.sizeOf(eqn.ty);
        case RECORD_EQUATION()            then Type.sizeOf(eqn.ty);
        case ALGORITHM()                  then eqn.size;
        case IF_EQUATION()                then eqn.size;
        case FOR_EQUATION(body = {body})  then eqn.size;
        case WHEN_EQUATION()              then eqn.size;
        case AUX_EQUATION()               then Variable.size(Pointer.access(eqn.auxiliary));
        case DUMMY_EQUATION()             then 0;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for:\n" + toString(eqn)});
        then fail();
      end match;
    end size;

    function sizes
      input Pointer<Equation> eqn_ptr;
      output list<Integer> size_lst;
    protected
      Equation eqn;
    algorithm
      eqn := Pointer.access(eqn_ptr);
      size_lst := match eqn
        case SCALAR_EQUATION() then {1};
        case ARRAY_EQUATION()  then {Type.sizeOf(eqn.ty)}; //needs to be updated to represent the dimensions
        case RECORD_EQUATION() then {Type.sizeOf(eqn.ty)};
        case ALGORITHM()       then {eqn.size};
        case IF_EQUATION()     then {eqn.size};
        case FOR_EQUATION()    then listReverse(Iterator.sizes(eqn.iter)); // does only consider frames and not conditions
        case WHEN_EQUATION()   then {eqn.size};
        case AUX_EQUATION()    then {Variable.size(Pointer.access(eqn.auxiliary))};
        case DUMMY_EQUATION()  then {};
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for:\n" + toString(eqn)});
        then fail();
      end match;
    end sizes;

    function hash
      "only hashes the name"
      input Pointer<Equation> eqn;
      output Integer i = Variable.hash(Pointer.access(getResidualVar(eqn)));
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
        // ToDo: This is wrong! implement the Algorithm.isEqual!
        // case (ALGORITHM(), ALGORITHM()) then Algorithm.isEqual(eqn1.alg, eqn2.alg);
        case (ALGORITHM(), ALGORITHM())            then equalName(Pointer.create(eqn1), Pointer.create(eqn2));
        case (IF_EQUATION(), IF_EQUATION())        then IfEquationBody.isEqual(eqn1.body, eqn2.body);
        case (FOR_EQUATION(), FOR_EQUATION())      then Iterator.isEqual(eqn1.iter, eqn2.iter) and List.all(List.zip(eqn1.body, eqn2.body), isEqualTpl);
        case (WHEN_EQUATION(), WHEN_EQUATION())    then WhenEquationBody.isEqual(eqn1.body, eqn2.body);
        case (AUX_EQUATION(), AUX_EQUATION())      then BVariable.equalName(eqn1.auxiliary, eqn2.auxiliary) and Util.optionEqual(eqn1.body, eqn2.body, isEqual);
        case (DUMMY_EQUATION(), DUMMY_EQUATION())  then true;
        else false;
      end match;
    end isEqual;

    function getEqnName
      input Pointer<Equation> eqn;
      output ComponentRef name;
    protected
      Pointer<Variable> residualVar;
    algorithm
      residualVar := getResidualVar(eqn);
      name := BVariable.getVarName(residualVar);
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
        case SCALAR_EQUATION(lhs = Expression.CREF(cref = cref))  then BVariable.getVar(cref);
        case ARRAY_EQUATION(lhs = Expression.CREF(cref = cref))   then BVariable.getVar(cref);
        case RECORD_EQUATION(lhs = Expression.CREF(cref = cref))  then BVariable.getVar(cref);
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
      Type ty = Expression.typeOf(lhs);
    algorithm
      // match type and create equation accordingly
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
      eq := Pointer.create(e);
      Equation.createName(eq, idx, str);
    end makeAssignment;

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
          eq.body := list(map(body_eqn, funcExp, funcCrefOpt) for body_eqn in eq.body);
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
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because there was no suitable case for: " + Equation.toString(eq)});
        then fail();

      end match;
    end map;

    function collectCrefs
      "filters all crefs of an equation and adds them
      to a list of crefs. needs cref filter function."
      input Equation eq;
      input Slice.filterCref filter;
      output list<ComponentRef> cref_lst;
    protected
      UnorderedSet<ComponentRef> acc = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    algorithm
      // map with the expression and cref filter functions
      _ := map(eq, function Slice.filterExp(filter = filter, acc = acc),
              SOME(function filter(acc = acc)));
      cref_lst := UnorderedSet.toList(acc);
    end collectCrefs;

    function getLHS
      "gets the left hand side expression of an equation."
      input Equation eq;
      output Expression lhs;
    algorithm
      lhs := match(eq)
        case SCALAR_EQUATION()                              then eq.lhs;
        case ARRAY_EQUATION()                               then eq.lhs;
        case RECORD_EQUATION()                              then eq.lhs;
        case FOR_EQUATION() guard(listLength(eq.body) == 1) then getLHS(List.first(eq.body));
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because LHS was ambiguous for: " + Equation.toString(eq)});
        then fail();
      end match;
    end getLHS;

    function getRHS
      "gets the right hand side expression of an equation."
      input Equation eq;
      output Expression rhs;
    algorithm
      rhs := match(eq)
        case SCALAR_EQUATION()                              then eq.rhs;
        case ARRAY_EQUATION()                               then eq.rhs;
        case RECORD_EQUATION()                              then eq.rhs;
        case FOR_EQUATION() guard(listLength(eq.body) == 1) then getRHS(List.first(eq.body));
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because RHS was ambiguous for: " + Equation.toString(eq)});
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
        case FOR_EQUATION() guard(listLength(eq.body) == 1) algorithm
          eq.body := {setLHS(List.first(eq.body), lhs)};
        then eq;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because LHS could not be set for: " + Equation.toString(eq)});
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
        case FOR_EQUATION() guard(listLength(eq.body) == 1) algorithm
          eq.body := {setRHS(List.first(eq.body), rhs)};
        then eq;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because RHS could not be set for: " + Equation.toString(eq)});
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

        case Equation.SCALAR_EQUATION() algorithm
          tmpExp := eqn.rhs;
          eqn.rhs := eqn.lhs;
          eqn.lhs := tmpExp;
        then eqn;

        case Equation.ARRAY_EQUATION() algorithm
          tmpExp := eqn.rhs;
          eqn.rhs := eqn.lhs;
          eqn.lhs := tmpExp;
        then eqn;

        case Equation.RECORD_EQUATION() algorithm
          tmpExp := eqn.rhs;
          eqn.rhs := eqn.lhs;
          eqn.lhs := tmpExp;
        then eqn;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Equation.toString(eqn)});
        then fail();
      end match;
    end swapLHSandRHS;

    function simplify
      input output Equation eq;
      input String name = "";
      input String indent = "";
    algorithm
      if Flags.isSet(Flags.DUMP_SIMPLIFY) and not stringEqual(indent, "") then
        print("\n");
      end if;
      eq := match eq
        case SCALAR_EQUATION() algorithm
          eq.lhs := SimplifyExp.simplifyDump(eq.lhs, true, name, indent);
          eq.rhs := SimplifyExp.simplifyDump(eq.rhs, true, name, indent);
        then eq;
        case ARRAY_EQUATION() algorithm
          eq.lhs := SimplifyExp.simplifyDump(eq.lhs, true, name, indent);
          eq.rhs := SimplifyExp.simplifyDump(eq.rhs, true, name, indent);
        then eq;
        case RECORD_EQUATION() algorithm
          eq.lhs := SimplifyExp.simplifyDump(eq.lhs, true, name, indent);
          eq.rhs := SimplifyExp.simplifyDump(eq.rhs, true, name, indent);
        then eq;
        // ToDo: implement the following correctly:
        case ALGORITHM()       then eq;
        case IF_EQUATION()     then eq;
        case FOR_EQUATION()    then eq;
        case WHEN_EQUATION() algorithm
          eq.body := WhenEquationBody.simplify(eq.body, name, indent);
        then eq;
        case AUX_EQUATION()    then eq;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Equation.toString(eq)});
        then fail();
      end match;
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
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for \n" + toString(eqn)});
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
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for \n" + toString(eqn)});
        then fail();

      end match;
      Pointer.update(idx, Pointer.access(idx) + 1);
      Pointer.update(eqn_ptr, eqn);
    end subIdxName;

    function createResidual
      "Creates a residual equation from a regular equation.
      Expample (for DAEMode): $RES_DAE_idx := rhs."
      input output Pointer<Equation> eqn_ptr;
      input Boolean new = false               "set to true if the resulting pointer should be a new one";
    protected
      Equation eqn = Pointer.access(eqn_ptr);
      ComponentRef residualCref;
      Expression lhs, rhs;
    algorithm
      // get name cref which is the residual
      residualCref:= match eqn
        local
          list<Subscript> subs;
        case FOR_EQUATION() algorithm
          residualCref := Equation.getEqnName(eqn_ptr);
          subs := Iterator.normalizedSubscripts(eqn.iter);
          residualCref := ComponentRef.setSubscripts(subs, residualCref);
        then residualCref;
        else Equation.getEqnName(eqn_ptr);
      end match;

      // update RHS and LHS
      lhs := Expression.fromCref(residualCref);
      rhs := Equation.getResidualExp(eqn);
      eqn := Equation.setLHS(eqn, lhs);
      eqn := Equation.setRHS(eqn, rhs);

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

        case Equation.SCALAR_EQUATION() algorithm
          operator := Operator.OPERATOR(Expression.typeOf(eqn.lhs), NFOperator.Op.ADD);
        then Expression.MULTARY({eqn.rhs}, {eqn.lhs}, operator);

        case Equation.ARRAY_EQUATION()  algorithm
          operator := Operator.OPERATOR(Expression.typeOf(eqn.lhs), NFOperator.Op.ADD);
        then Expression.MULTARY({eqn.rhs}, {eqn.lhs}, operator);

        case Equation.RECORD_EQUATION(ty = Type.COMPLEX(cls = cls_node)) algorithm
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

        case Equation.IF_EQUATION() then IfEquationBody.getResidualExp(eqn.body);

        // returns innermost residual!
        // Ambiguous for entwined for loops!
        case Equation.FOR_EQUATION() guard(listLength(eqn.body) == 1) then getResidualExp(List.first(eqn.body));

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
          ty := getType(List.first(eq.body));
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

        case FOR_EQUATION() algorithm
          (names, ranges) := Iterator.getFrames(eqn.iter);
        then List.zip(names, ranges);

        else {};
      end match;
    end getForFrames;

    function isDummy
      input Equation eqn;
      output Boolean b;
    algorithm
      b := match eqn case DUMMY_EQUATION() then true; else false; end match;
    end isDummy;

    function isDiscrete
      input Pointer<Equation> eqn;
      output Boolean b;
    protected
      EquationAttributes attr;
    algorithm
      attr := getAttributes(Pointer.access(eqn));
      b := attr.kind == EquationKind.DISCRETE;
    end isDiscrete;

    function isContinuous
      input Pointer<Equation> eqn;
      output Boolean b;
    protected
      EquationAttributes attr;
    algorithm
      attr := getAttributes(Pointer.access(eqn));
      b := attr.kind == EquationKind.CONTINUOUS;
    end isContinuous;

    function isInitial
      input Pointer<Equation> eqn;
      output Boolean b;
    protected
      EquationAttributes attr;
    algorithm
      attr := getAttributes(Pointer.access(eqn));
      b := attr.exclusively_initial;
    end isInitial;

    function isWhenEquation
      input Pointer<Equation> eqn_ptr;
      output Boolean b;
    protected
      Equation eqn = Pointer.access(eqn_ptr);
    algorithm
      b := match eqn
        case Equation.WHEN_EQUATION() then true;
        case Equation.FOR_EQUATION() then List.any(list(Pointer.create(e) for e in eqn.body), isWhenEquation);
        else false;
      end match;
    end isWhenEquation;

    function isIfEquation
      input Pointer<Equation> eqn;
      output Boolean b;
    algorithm
      b := match Pointer.access(eqn)
        case Equation.IF_EQUATION() then true;
        else false;
      end match;
    end isIfEquation;

    function isForEquation
      input Pointer<Equation> eqn;
      output Boolean b;
    algorithm
      b := match Pointer.access(eqn)
        case Equation.FOR_EQUATION() then true;
        else false;
      end match;
    end isForEquation;

    function isArrayEquation
      input Pointer<Equation> eqn;
      output Boolean b;
    algorithm
      b := match Pointer.access(eqn)
        case Equation.ARRAY_EQUATION() then true;
        else false;
      end match;
    end isArrayEquation;

    function isRecordEquation
      input Pointer<Equation> eqn;
      output Boolean b;
    algorithm
      b := match Pointer.access(eqn)
        case Equation.RECORD_EQUATION() then true;
        case Equation.ARRAY_EQUATION(recordSize = SOME(_)) then true;
        else false;
      end match;
    end isRecordEquation;

    function isAlgorithm
      input Pointer<Equation> eqn;
      output Boolean b;
    algorithm
      b := match Pointer.access(eqn)
        case Equation.ALGORITHM() then true;
        else false;
      end match;
    end isAlgorithm;

    function isParameterEquation
      input Equation eqn;
      output Boolean b = true;
    protected
      Pointer<Boolean> b_ptr = Pointer.create(b);
    algorithm
      Equation.map(eqn, function expIsParamOrConst(b_ptr = b_ptr), SOME(function crefIsParamOrConst(b_ptr = b_ptr)));
      b := Pointer.access(b_ptr);
    end isParameterEquation;

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
        Pointer.update(b_ptr, BVariable.isParamOrConst(BVariable.getVarPointer(cref)));
      end if;
    end crefIsParamOrConst;

    function generateBindingEquation
      input Pointer<Variable> var_ptr;
      input Pointer<Integer> idx;
      input Boolean initial_;
      output Pointer<Equation> eqn;
    protected
      String context = "BND";
      Variable var;
      Expression lhs, rhs;
      EquationAttributes eqnAttr;
      Iterator iter;
      list<ComponentRef> sub_crefs;
      list<Subscript> subs;
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
          start := BackendExtension.VariableAttributes.getStartAttribute(var.backendinfo.attributes);
        then Util.getOptionOrDefault(start, Expression.makeZero(ComponentRef.getSubscriptedType(var.name, true)));
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of wrong binding type: " + Binding.toDebugString(var.binding) + " for variable " + Variable.toString(Pointer.access(var_ptr))});
        then fail();
      end match;

      if BVariable.isContinuous(var_ptr) then
        eqnAttr := EquationAttributes.default(EquationKind.CONTINUOUS, initial_);
      else
        eqnAttr := EquationAttributes.default(EquationKind.DISCRETE, initial_);
      end if;

      // simplify rhs and get potential iterators
      (iter, rhs) := Iterator.extract(rhs);
      rhs := SimplifyExp.simplifyDump(rhs, true, getInstanceName());

      if Iterator.isEmpty(iter) then
        lhs := Expression.fromCref(var.name);
        eqn := Equation.makeAssignment(lhs, rhs, idx, context, Iterator.EMPTY(), eqnAttr);
      else
        rhs := Expression.map(rhs, Expression.repairOperator);
        (sub_crefs, _) := Iterator.getFrames(iter);
        subs := list(Subscript.fromTypedExp(Expression.fromCref(cref)) for cref in sub_crefs);
        lhs := Expression.fromCref(ComponentRef.mergeSubscripts(subs, var.name, true, true));
        eqn := Equation.makeAssignment(lhs, rhs, idx, context, iter, eqnAttr);
        // this could lead to non existing variables, should not be a problem though
        Equation.renameIterators(eqn, "$i");
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
          (body, acc) := mergeIterators(List.first(eq.body), false);
          acc := eq.iter :: acc;
        then (if top_level then Equation.FOR_EQUATION(eq.size, Iterator.merge(acc), {body}, eq.source, eq.attr) else body, acc);
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
          body := List.first(eqn.body);
          for iter in iterators loop
            body := Equation.FOR_EQUATION(eqn.size, iter, {body}, eqn.source, eqn.attr);
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
          + List.toString(eqn_lst, function Equation.toString(str = shift + "  "), "", "", "\n", "\n\n"));
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
          + List.toString(entwined, function Equation.toString(str = shift  + "  "), "", "", "\n", "\n\n"));
      end if;
    end entwine;

    function slice
      "performs a single slice based on the given indices and the cref to solve for
      does not work for entwined for loops!"
      input output Pointer<Equation> eqn_ptr  "equation to slice";
      input list<Integer> indices             "zero based indices of the eqn";
      input Option<ComponentRef> cref_opt     "optional cref to solve for, if none is given, the body stays as it is";
      output SlicingStatus slicing_status     "unchanged, trivial (only rearranged) or nontrivial";
      output Solve.Status solve_status        "unprocessed, explicit, implicit, unsolvable";
      input output FunctionTree funcTree      "function tree for solving";
    protected
      Equation eqn;
      list<Frame> frames;
      list<Dimension> dims;
      list<Integer> sizes;
      list<Integer> first_location, last_location, frame_comp;
      list<list<Integer>> locations;
      list<array<Integer>> locations_T;
      list<FrameLocation> frame_locations;
      list<tuple<Integer, Integer, Integer>> ranges;
      FrameOrderingStatus frame_status;
    algorithm
      eqn := Pointer.access(eqn_ptr);
      (eqn_ptr, slicing_status, solve_status) := match eqn
        local
          list<Equation> body_lst;
          Equation body, sliced;
          Option<UnorderedMap<ComponentRef, Expression>> removed_diagonals_opt;
          UnorderedMap<ComponentRef, Expression> replacements, removed_diagonals;
          list<tuple<ComponentRef, Expression>> removed_diagonals_linear_maps;
          Expression condition;
          Integer size;
          Iterator iter;

        // empty index list indicates no slicing and no rearranging
        case _ guard(listEmpty(indices)) then (Pointer.create(eqn), SlicingStatus.UNCHANGED, NBSolve.Status.EXPLICIT);

        case RECORD_EQUATION() algorithm
          slicing_status := if Equation.size(eqn_ptr) == listLength(indices) then SlicingStatus.TRIVIAL else SlicingStatus.NONTRIVIAL;
          if Util.isSome(cref_opt) then
            (eqn, funcTree, solve_status, _) := Solve.solveBody(Pointer.access(eqn_ptr), Util.getOption(cref_opt), funcTree);
          else
            solve_status := NBSolve.Status.EXPLICIT;
          end if;
        then (Pointer.create(eqn), slicing_status, solve_status);

        case ARRAY_EQUATION() algorithm
          slicing_status := if Equation.size(eqn_ptr) == listLength(indices) then SlicingStatus.TRIVIAL else SlicingStatus.NONTRIVIAL;
          if Util.isSome(cref_opt) then
            (eqn, funcTree, solve_status, _) := Solve.solveBody(Pointer.access(eqn_ptr), Util.getOption(cref_opt), funcTree);
          else
            solve_status := NBSolve.Status.EXPLICIT;
          end if;
        then (Pointer.create(eqn), slicing_status, solve_status);

        case FOR_EQUATION() algorithm
          // get the sizes of the 'return value' of the equation
          dims      := Type.arrayDims(Equation.getType(eqn));
          sizes     := list(Dimension.size(dim) for dim in dims);

          // trivial slices replace the original equation entirely
          slicing_status := if Equation.size(eqn_ptr) == listLength(indices) then SlicingStatus.TRIVIAL else SlicingStatus.NONTRIVIAL;

          // kabdelhak: ToDo: check ordering of locations and sizes
          locations                                       := list(Slice.indexToLocation(idx, sizes) for idx in indices);
          locations_T                                     := Slice.transposeLocations(locations, listLength(sizes));
          frames                                          := listReverse(getForFrames(eqn));
          frame_locations                                 := List.zip(locations_T, frames);
          (frame_locations, replacements, frame_status)   := Slice.orderTransposedFrameLocations(frame_locations);
          if frame_status == FrameOrderingStatus.FAILURE then
            slicing_status  := SlicingStatus.FAILURE;
            solve_status    := NBSolve.Status.UNPROCESSED;
            return;
          end if;
          (frames, removed_diagonals_opt)                 := Slice.recollectRangesHeuristic(frame_locations);

          // solve the body equation for the cref if needed
          // ToDo: act on solving status not equal to EXPLICIT ?
          body_lst := match cref_opt
            local
              ComponentRef cref;
            case SOME(cref) algorithm
              // first solve then replace iterators
              (body, funcTree, solve_status, _) := Solve.solveBody(List.first(eqn.body), cref, funcTree);
              body := map(body, function Replacements.applySimpleExp(replacements = replacements));

              // if there is a diagonal to remove, get the necessary linear maps
              if Util.isSome(removed_diagonals_opt) then
                removed_diagonals := Util.getOption(removed_diagonals_opt);
                removed_diagonals_linear_maps := UnorderedMap.toList(removed_diagonals);
                condition := Expression.MULTARY(
                  arguments     = list(makeInequality(tpl) for tpl in removed_diagonals_linear_maps),
                  inv_arguments = {},
                  operator      = Operator.OPERATOR(Type.BOOLEAN(), NFOperator.Op.AND)
                );
                // removed diagonal is represented with IF_EQUATION
                body := IF_EQUATION(
                  size    = Equation.size(Pointer.create(body)),
                  body    = IF_EQUATION_BODY(
                    condition = condition,
                    then_eqns = {Pointer.create(body)},
                    else_if   = NONE() ),
                  source  = eqn.source,
                  attr    = eqn.attr
                );
              end if;
            then {body};

            else eqn.body;
          end match;

          iter := Iterator.fromFrames(frames);
          size := Iterator.size(iter) * sum(Equation.size(Pointer.create(eq)) for eq in body_lst);
          sliced := FOR_EQUATION(
            size    = size,
            iter    = iter,
            body    = body_lst,
            source  = eqn.source,
            attr    = eqn.attr
          );
          // create a new pointer and do not overwrite the old one!
        then (Pointer.create(sliced), slicing_status, solve_status);

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because slicing is not yet supported for: \n" + toString(eqn)});
        then fail();
      end match;
    end slice;

    function singleSlice
      input Pointer<Equation> eqn_ptr                             "equation to slice";
      input Integer scal_idx                                      "zero based scalar index";
      input list<Integer> sizes                                   "frame sizes (innermost first)";
      input ComponentRef cref_to_solve                            "the cref to solve the body for (EMPTY() for already solved)";
      input UnorderedMap<ComponentRef, Expression> replacements   "prepared replacement map";
      output Equation sliced_eqn                                  "scalar sliced equation";
      input output FunctionTree funcTree                          "func tree for solving";
    protected
      Equation eqn;
      list<Integer> location;
    algorithm
      eqn := Pointer.access(eqn_ptr);
      sliced_eqn := match eqn

        // slice the equation
        case FOR_EQUATION() algorithm
          // solve the body if necessary
          if not ComponentRef.isEmpty(cref_to_solve) then
            (sliced_eqn, funcTree, _, _) := Solve.solveBody(List.first(eqn.body), cref_to_solve, funcTree);
          end if;
          // get the frame location indices from single index
          location := Slice.indexToLocation(scal_idx, sizes);
          // create the replacement rules for this location
          Iterator.createLocationReplacements(eqn.iter, listArray(location), replacements);
          // replace iterators
          sliced_eqn := map(sliced_eqn, function Replacements.applySimpleExp(replacements = replacements));
        then sliced_eqn;

        // ToDo: arrays 'n stuff

        // equation that does not need to be sliced
        else eqn;
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
        exp2      = SimplifyExp.simplifyDump(exp, true, getInstanceName())
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
        then {Statement.ASSIGNMENT(eqn.lhs, eqn.rhs, Type.arrayElementType(eqn.ty), eqn.source)};

        case ARRAY_EQUATION()
        then {Statement.ASSIGNMENT(eqn.lhs, eqn.rhs, Type.arrayElementType(eqn.ty), eqn.source)};

        case RECORD_EQUATION(lhs = Expression.CREF(cref = lhs_rec), rhs = Expression.CREF(cref = rhs_rec)) algorithm
          lhs_lst := BVariable.getRecordChildren(BVariable.getVarPointer(lhs_rec));
          rhs_lst := BVariable.getRecordChildren(BVariable.getVarPointer(rhs_rec));
          if listLength(lhs_lst) == listLength(rhs_lst) then
            for tpl in List.zip(lhs_lst, rhs_lst) loop
              (lhs, rhs) := tpl;
               stmts := Statement.ASSIGNMENT(Expression.fromCref(BVariable.getVarName(lhs)), Expression.fromCref(BVariable.getVarName(rhs)), Variable.typeOf(Pointer.access(lhs)), eqn.source) :: stmts;
            end for;
          else
            stmts := {Statement.ASSIGNMENT(eqn.lhs, eqn.rhs, Type.arrayElementType(eqn.ty), eqn.source)};
          end if;
        then stmts;

        case RECORD_EQUATION()
        then {Statement.ASSIGNMENT(eqn.lhs, eqn.rhs, Type.arrayElementType(eqn.ty), eqn.source)};

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
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed it is not yet supported for: \n" + toString(eqn)});
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

    function toString
      input IfEquationBody body;
      input String indent = "";
      input String elseStr = "";
      input Boolean selfCall = false;
      output String str;
    protected
      IfEquationBody elseIf;
    algorithm
      if not Expression.isEnd(body.condition) then
        str := elseStr + "if " + Expression.toString(body.condition) + " then\n";
      else
        str := elseStr + "\n";
      end if;
      for eqn in body.then_eqns loop
        str := str + Equation.toString(Pointer.access(eqn), indent + "  ") + "\n";
      end for;
      if isSome(body.else_if) then
        SOME(elseIf) := body.else_if;
        str := str + toString(elseIf, indent, indent + "else", true);
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
      output Integer size = sum(Equation.size(eqn) for eqn in body.then_eqns);
    end size;

    function isEqual
      input IfEquationBody body1;
      input IfEquationBody body2;
      output Boolean b;
    algorithm
      b := List.all(List.zip(body1.then_eqns, body2.then_eqns), Equation.isEqualPtrTpl) and Util.optionEqual(body1.else_if, body2.else_if, isEqual);
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

    function getResidualExp
      input IfEquationBody body;
      output Expression exp;
    algorithm
      if listLength(body.then_eqns) == 1 then
        exp := Equation.getResidualExp(Pointer.access(List.first(body.then_eqns)));
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for:\n" + toString(body)});
        fail();
      end if;
    end getResidualExp;

    function toStatement
      "converts an if equation body to an algorithmic statement"
      input IfEquationBody body;
      output list<tuple<Expression, list<Statement>>> stmts;
    protected
      tuple<Expression, list<Statement>> stmt;
    algorithm
      stmt := (body.condition, List.flatten(list(Equation.toStatement(Pointer.access(eqn)) for eqn in body.then_eqns)));
      if Util.isSome(body.else_if) then
        stmts := stmt :: toStatement(Util.getOption(body.else_if));
      else
        stmts := {stmt};
      end if;
    end toStatement;

    function split
      "splits an if equation body with multiple equations into multiple bodies of each one equation
      NOTE: does not care for branch matching, it combines first equation of each branch to one
      new body and does the same for second, third, etc."
      input IfEquationBody body;
      output list<IfEquationBody> bodies = {};
    protected
      list<Expression> conditions = {};
      array<list<Pointer<Equation>>> then_eqns = arrayCreate(listLength(body.then_eqns), {});
      Expression condition;
      Pointer<Equation> eqn;
      Option<IfEquationBody> tmp;
    algorithm
      (conditions, then_eqns) := splitCollect(body, conditions, then_eqns);
      for i in 1:arrayLength(then_eqns) loop
        tmp := NONE();
        for tpl in List.zip(conditions, then_eqns[i]) loop
          (condition, eqn) := tpl;
          tmp := SOME(IF_EQUATION_BODY(condition, {eqn}, tmp));
        end for;
        bodies := Util.getOption(tmp) :: bodies;
      end for;
    end split;

    protected function splitCollect
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
      Expression condition                  "the when-condition (Expression.END for no condition)";
      list<WhenStatement> when_stmts        "body statements";
      Option<WhenEquationBody> else_when    "optional elsewhen body";
    end WHEN_EQUATION_BODY;

    function fromFlatList
      input list<tuple<Expression, list<WhenStatement>>> flat_list;
      output Option<WhenEquationBody> body;
    algorithm
      body := match flat_list
        local
          Expression condition;
          list<WhenStatement> stmts;
          list<tuple<Expression, list<WhenStatement>>> tail;
          Option<WhenEquationBody> else_when;
        case (condition, stmts) :: tail algorithm
          else_when := fromFlatList(tail);
        then SOME(WHEN_EQUATION_BODY(condition, stmts, else_when));
        else NONE();
      end match;
    end fromFlatList;

    function toString
      input WhenEquationBody body;
      input String indent = "";
      input String elseStr = "";
      input Boolean selfCall = false;
      output String str;
    protected
      WhenEquationBody elseWhen;
    algorithm
      str := elseStr + "when " + Expression.toString(body.condition) + " then \n";
      for stmt in body.when_stmts loop
        str := str + WhenStatement.toString(stmt, indent + "  ") + "\n";
      end for;
      if isSome(body.else_when) then
        SOME(elseWhen) := body.else_when;
        str := str + toString(elseWhen, indent, indent +"else ", true);
      end if;
      if not selfCall then
        str := str + indent + "end when;";
      end if;
    end toString;

    function size
      "returns the size only considering first when branch."
      input WhenEquationBody body;
      output Integer s = sum(WhenStatement.size(stmt) for stmt in body.when_stmts);
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
      b := List.all(List.zip(body1.when_stmts, body2.when_stmts), WhenStatement.isEqualTpl) and Util.optionEqual(body1.else_when, body2.else_when, isEqual);
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
      UnorderedSet<ComponentRef> discr_map = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
      UnorderedSet<ComponentRef> state_map = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
      list<tuple<Expression, list<WhenStatement>>> flat_when;
      list<tuple<Expression, list<WhenStatement>>> flat_new;
      list<ComponentRef> discretes, states;
      Expression condition, acc_condition = Expression.EMPTY(Type.INTEGER());
      list<WhenStatement> stmts;
      Option<WhenStatement> stmt;
      Option<WhenEquationBody> new_body;
    algorithm
      // collect all discretes and states contained in the when equation body
      // and also flatten the when equation to a list
      flat_when := collectForSplit(SOME(body), discr_map, state_map);
      discretes := UnorderedSet.toList(discr_map);
      states    := UnorderedSet.toList(state_map);

      // create a when equation for each discrete state
      for disc in discretes loop
        flat_new := {};
        for tpl in flat_when loop
          (condition, stmts) := tpl;
          // get first assignment - each branch should only have one
          // assignment per discrete state
          stmt := getFirstAssignment(disc, stmts);
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
            + " failed because when partition for: " + ComponentRef.toString(disc)
            + " could not be recovered."});
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
      input output WhenEquationBody body;
      input String name = "";
      input String indent = "";
    algorithm
      // simplify condition if it is an array with surplus false conditions
      body.condition := match body.condition
        local
          Expression condition;
          list<Expression> conditions;
        case condition as Expression.ARRAY() algorithm
          conditions := list(elem for elem guard(not Expression.isFalse(elem)) in arrayList(condition.elements));
          body.condition := Expression.makeArrayCheckLiteral(Type.ARRAY(Type.BOOLEAN(), {Dimension.fromInteger(listLength(conditions))}), listArray(conditions));
        then body.condition;
        else body.condition;
      end match;

      // ToDo: add simplification of body! (WhenStatements)

      body.condition := SimplifyExp.simplifyDump(body.condition, true, name, indent);
      body.else_when := Util.applyOption(body.else_when, function simplify(name = name, indent = indent));
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

  protected
    function collectForSplit
      "collects all discrete states and regular states for splitting up
      of a when equation. also flattens it to a list"
      input Option<WhenEquationBody> body_opt;
      input UnorderedSet<ComponentRef> discr_map;
      input UnorderedSet<ComponentRef> state_map;
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
            case WhenStatement.ASSIGN(lhs = Expression.CREF(cref = cref)) algorithm
              UnorderedSet.add(cref, discr_map);
            then ();
            case WhenStatement.REINIT(stateVar = cref) algorithm
              UnorderedSet.add(cref, state_map);
            then ();
            case WhenStatement.ASSIGN() algorithm
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
                + " failed because lhs of statement is not a cref: " + WhenStatement.toString(stmt)});
            then fail();
            else ();
          end match;
        end for;
        flat_when := (body.condition, body.when_stmts) :: collectForSplit(body.else_when, discr_map, state_map);
      else
        flat_when := {};
      end if;
    end collectForSplit;

    function getFirstAssignment
      "returns the first assignment in the list that is solved for cref"
      input ComponentRef cref;
      input list<WhenStatement> stmts;
      output Option<WhenStatement> assign = NONE();
    algorithm
      for stmt in stmts loop
        () := match stmt
          local
            ComponentRef lhs;
          case WhenStatement.ASSIGN(lhs = Expression.CREF(cref = lhs))
          guard(ComponentRef.isEqual(cref, lhs)) algorithm
            assign := SOME(stmt); break;
          then ();
          else ();
        end match;
      end for;
    end getFirstAssignment;

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

    function size
      input WhenStatement stmt;
      output Integer s;
    algorithm
      s := match stmt
        case ASSIGN() then Type.sizeOf(Expression.typeOf(stmt.lhs));
                      else 0;
      end match;
    end size;

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
          Expression lhs, rhs, value, condition;
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
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " for unknown reason."});
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
    protected
      Integer luI = lastUsedIndex(equations);
      Integer length, scal_start, current_index = 1;
      String index;
      Boolean useMapping = Util.isSome(mapping_opt);
      array<tuple<Integer,Integer>> mapping;
    algorithm
      if useMapping then
        length := 15;
        mapping := Util.getOption(mapping_opt);
      else
        length := 10;
      end if;
      if printEmpty or luI > 0 then
        str := StringUtil.headline_4(str + " Equations (" + intString(EquationPointers.size(equations)) + "/" + intString(scalarSize(equations)) + ")");
        for i in 1:luI loop
          if ExpandableArray.occupied(i, equations.eqArr) then
            if useMapping then
              (scal_start, _) := mapping[current_index];
              index := "(" + intString(current_index) + "|" + intString(scal_start) + ")";
            else
              index := "(" + intString(current_index) + ")";
            end if;
            index := index + StringUtil.repeat(" ", length - stringLength(index));
            str := str + Equation.toString(Pointer.access(ExpandableArray.get(i, equations.eqArr)), index) + "\n";
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
      output Integer sz = 0;
    algorithm
      for eqn_ptr in toList(equations) loop
        sz := sz + Equation.size(eqn_ptr);
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
    algorithm
      for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          eq_ptr := ExpandableArray.get(i, equations.eqArr);
          eq := Pointer.access(eq_ptr);
          new_eq := func(eq);
          if not referenceEq(eq, new_eq) then
            // Do not update the expandable array entry, but the pointer itself
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
      input MapFunc func;
      partial function MapFunc
        input Pointer<Equation> e;
        output Boolean delete;
      end MapFunc;
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
      output Integer index;
    algorithm
      index := match UnorderedMap.get(name, equations.map)
        case SOME(index) then index;
        case NONE() then -1;
      end match;
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
            case Equation.DUMMY_EQUATION() then ();
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
      output Integer s;
    algorithm
      s := match eqData
        case EQ_DATA_SIM() then EquationPointers.scalarSize(eqData.simulation);
        case EQ_DATA_JAC() then EquationPointers.scalarSize(eqData.equations);
        case EQ_DATA_HES() then EquationPointers.scalarSize(eqData.equations);
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
          eqData.discretes    := EquationPointers.mapExp(eqData.discretes, func);
          eqData.initials     := EquationPointers.mapExp(eqData.initials, func);
          eqData.auxiliaries  := EquationPointers.mapExp(eqData.auxiliaries, func);
        then eqData;

        case EqData.EQ_DATA_JAC() algorithm
          eqData.results      := EquationPointers.mapExp(eqData.results, func);
          eqData.temporary    := EquationPointers.mapExp(eqData.temporary, func);
          eqData.auxiliaries  := EquationPointers.mapExp(eqData.auxiliaries, func);
        then eqData;

        case EqData.EQ_DATA_HES() algorithm
          Pointer.update(eqData.result, Equation.map(Pointer.access(eqData.result), func));
          eqData.temporary    := EquationPointers.mapExp(eqData.temporary, func);
          eqData.auxiliaries  := EquationPointers.mapExp(eqData.auxiliaries, func);
        then eqData;
      end match;
    end mapExp;

    function toString
      input EqData eqData;
      input Integer level = 0;
      output String str;
    algorithm
      str := match eqData
        local
          String tmp;

        case EQ_DATA_SIM()
          algorithm
            tmp := "Equation Data Simulation (scalar simulation equations: " + intString(EquationPointers.scalarSize(eqData.simulation)) + ")";
            tmp := StringUtil.headline_2(tmp) + "\n";
            if level == 0 then
              tmp :=  tmp + EquationPointers.toString(eqData.equations, "Simulation", NONE(), false);
            else

              tmp :=  tmp + EquationPointers.toString(eqData.continuous, "Continuous", NONE(), false) +
                      EquationPointers.toString(eqData.discretes, "Discrete", NONE(), false) +
                      EquationPointers.toString(eqData.initials, "(Exclusively) Initial", NONE(), false) +
                      EquationPointers.toString(eqData.auxiliaries, "Auxiliary", NONE(), false) +
                      EquationPointers.toString(eqData.removed, "Removed", NONE(), false);
            end if;
        then tmp;

        case EQ_DATA_JAC()
          algorithm
            if level == 0 then
              tmp :=  EquationPointers.toString(eqData.equations, "Jacobian", NONE(), false);
            else
              tmp :=  EquationPointers.toString(eqData.results, "Residual", NONE(), false) +
                      EquationPointers.toString(eqData.temporary, "Inner", NONE(), false) +
                      EquationPointers.toString(eqData.auxiliaries, "Auxiliary", NONE(), false);
            end if;
        then tmp;

        case EQ_DATA_HES()
          algorithm
            if level == 0 then
              tmp :=  EquationPointers.toString(eqData.equations, "Hessian", NONE(), false);
            else
              tmp :=  StringUtil.headline_4("Result Equation") + "\n" +
                      Equation.toString(Pointer.access(eqData.result)) + "\n" +
                      EquationPointers.toString(eqData.temporary, "Temporary Inner", NONE(), false) +
                      EquationPointers.toString(eqData.auxiliaries, "Auxiliary", NONE(), false);
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
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
        then fail();
      end match;
    end getUniqueIndex;

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

    type EqType = enumeration(CONTINUOUS, DISCRETE, INITIAL);

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
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
        then fail();
      end match;
    end addTypedList;

    function addUntypedList
      input output EqData eqData;
      input list<Pointer<Equation>> eq_lst;
      input Boolean newName = true;
    protected
      list<Pointer<Equation>> equation_lst, continuous_lst, discretes_lst, initials_lst, auxiliaries_lst, simulation_lst, removed_lst;
    algorithm

      eqData := match eqData
        case EQ_DATA_SIM() algorithm
          if newName then
            for eqn_ptr in eq_lst loop
              Equation.createName(eqn_ptr, eqData.uniqueIndex, SIMULATION_STR);
            end for;
          end if;
          (simulation_lst, continuous_lst, discretes_lst, initials_lst, auxiliaries_lst, removed_lst) := typeList(eq_lst);
          eqData.equations    := EquationPointers.addList(eq_lst, eqData.equations);
          eqData.simulation   := EquationPointers.addList(simulation_lst, eqData.simulation);
          eqData.continuous   := EquationPointers.addList(continuous_lst, eqData.continuous);
          eqData.discretes    := EquationPointers.addList(discretes_lst, eqData.discretes);
          eqData.initials     := EquationPointers.addList(initials_lst, eqData.initials);
          eqData.auxiliaries  := EquationPointers.addList(auxiliaries_lst, eqData.auxiliaries);
          eqData.removed      := EquationPointers.addList(removed_lst, eqData.removed);
        then eqData;

        // ToDo: other cases

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
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
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
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
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
        then fail();
      end match;
    end compress;
  end EqData;

  function typeList
    input list<Pointer<Equation>> equations;
    output list<Pointer<Equation>> simulation_lst = {};
    output list<Pointer<Equation>> continuous_lst = {};
    output list<Pointer<Equation>> discretes_lst = {};
    output list<Pointer<Equation>> initials_lst = {};
    output list<Pointer<Equation>> auxiliaries_lst = {};
    output list<Pointer<Equation>> removed_lst = {};
  algorithm
    for eq in equations loop
    _:= match Equation.getAttributes(Pointer.access(eq))
        case EQUATION_ATTRIBUTES(exclusively_initial = true)
          algorithm
            initials_lst := eq :: initials_lst;
        then ();

        case EQUATION_ATTRIBUTES(kind = EquationKind.CONTINUOUS)
          algorithm
            continuous_lst := eq :: continuous_lst;
            simulation_lst := eq :: simulation_lst;
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
