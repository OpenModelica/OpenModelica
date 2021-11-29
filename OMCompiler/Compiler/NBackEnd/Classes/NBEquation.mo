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
  import Binding = NFBinding;
  import Call = NFCall;
  import Class = NFClass;
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import NFFlatten.FunctionTree;
  import InstNode = NFInstNode.InstNode;
  import Operator = NFOperator;
  import SimplifyExp = NFSimplifyExp;
  import Statement = NFStatement;
  import Type = NFType;
  import Variable = NFVariable;

  // Old Backend imports
  import OldBackendDAE = BackendDAE;

  // New Backend imports
  import StrongComponent = NBStrongComponent;
  import Solve = NBSolve;
  import BVariable = NBVariable;

  // Util imports
  import BackendUtil = NBBackendUtil;
  import BaseHashTable;
  import ExpandableArray;
  import StringUtil;
  import UnorderedMap;

  type EquationPointer = Pointer<Equation> "mainly used for mapping purposes";
  type SlicingStatus = enumeration(UNCHANGED, TRIVIAL, NONTRIVIAL);

  uniontype Iterator
    record SINGLE
      ComponentRef name           "the name of the iterator";
      Expression range            "range as< start, step, stop>";
    end SINGLE;

    record NESTED
      array<ComponentRef> names   "sorted iterator names";
      array<Expression> ranges    "sorted ranges as <start, step, stop>";
    end NESTED;

    function fromFrames
      input list<tuple<ComponentRef, Expression>> frames;
      output Iterator iter;
    protected
      list<ComponentRef> names;
      list<Expression> ranges;
      ComponentRef name;
      Expression range;
    algorithm
      (names, ranges) := List.unzip(frames);
      iter := match (names, ranges)
        case ({name}, {range})  then SINGLE(name, range);
                                else NESTED(listArray(names), listArray(ranges));
      end match;
    end fromFrames;

    function getFrames
      input Iterator iter;
      output list<ComponentRef> names;
      output list<Expression> ranges;
    algorithm
      (names, ranges) := match iter
        case SINGLE() then ({iter.name}, {iter.range});
        case NESTED() then (arrayList(iter.names), arrayList(iter.ranges));
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
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for an unknown reason."});
        then fail();
      end match;
    end toString;

    function map
      "Traverses all expressions of the iterator range and applies a function to it."
      input output Iterator iter;
      input MapFuncExp funcExp;
    algorithm
      iter := match iter
        case SINGLE() algorithm
          iter.range := Expression.map(iter.range, funcExp);
        then iter;
        case NESTED() algorithm
          for i in 1:arrayLength(iter.ranges) loop
            iter.ranges[i] := Expression.map(iter.ranges[i], funcExp);
          end for;
        then iter;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for an unknown reason."});
        then fail();
      end match;
    end map;
  end Iterator;

  partial function MapFuncExp
    input output Expression e;
  end MapFuncExp;
  partial function MapFuncCref
    input output ComponentRef c;
  end MapFuncCref;

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

    record SIMPLE_EQUATION
      Type ty                         "equality type";
      ComponentRef lhs                "left hand side component reference";
      ComponentRef rhs                "right hand side component reference";
      DAE.ElementSource source        "origin of equation";
      EquationAttributes attr         "Additional Attributes";
    end SIMPLE_EQUATION;

    record RECORD_EQUATION
      Type ty                         "equality type";
      //Integer size                    "size of record";
      Expression lhs                  "left hand side expression";
      Expression rhs                  "right hand side expression";
      DAE.ElementSource source        "origin of equation";
      EquationAttributes attr         "Additional Attributes";
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
      Type ty                         "equality type containing dimensions";
      Iterator iter                   "list of all: <iterator, range>";
      Equation body                   "iterated equation";
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
    algorithm
      str := match eq
        case SCALAR_EQUATION() then str + "[SCAL] " + s + EquationAttributes.toString(eq.attr) + Expression.toString(eq.lhs) + " = " + Expression.toString(eq.rhs);
        case ARRAY_EQUATION()  then str + "[ARRY] " + s + EquationAttributes.toString(eq.attr) + Expression.toString(eq.lhs) + " = " + Expression.toString(eq.rhs);
        case SIMPLE_EQUATION() then str + "[SIMP] " + s + EquationAttributes.toString(eq.attr) + ComponentRef.toString(eq.lhs) + " = " + ComponentRef.toString(eq.rhs);
        case RECORD_EQUATION() then str + "[RECD] " + s + EquationAttributes.toString(eq.attr) + Expression.toString(eq.lhs) + " = " + Expression.toString(eq.rhs);
        case ALGORITHM()       then str + "[ALGO] " + s + EquationAttributes.toString(eq.attr) + "\n" + Algorithm.toString(eq.alg, str + "[----] ");
        case IF_EQUATION()     then str + IfEquationBody.toString(eq.body, str + "[----] ", "[-IF-] " + s);
        case FOR_EQUATION()    then str + forEquationToString(eq.iter, eq.body, "", str + "[----] ", "[FOR-] " + s + EquationAttributes.toString(eq.attr));
        case WHEN_EQUATION()   then str + WhenEquationBody.toString(eq.body, str + "[----] ", "[WHEN] " + s);
        case AUX_EQUATION()    then str + "[AUX-] " + s + "Auxiliary equation for " + Variable.toString(Pointer.access(eq.auxiliary));
        case DUMMY_EQUATION()  then str + "[DUMY] (0) Dummy equation.";
        else                        str + "[FAIL] (0) " + getInstanceName() + " failed!";
      end match;
    end toString;

    function pointerToString
      input Pointer<Equation> eqn_ptr;
      output String str = toString(Pointer.access(eqn_ptr));
    end pointerToString;

    function source
      input Equation eq;
      output DAE.ElementSource src;
    algorithm
      src := match eq
        case SCALAR_EQUATION() then eq.source;
        case ARRAY_EQUATION()  then eq.source;
        case SIMPLE_EQUATION() then eq.source;
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
      output Integer size;
    protected
      Equation eqn;
    algorithm
      eqn := Pointer.access(eqn_ptr);
      size := match eqn
        case SCALAR_EQUATION() then 1;
        case ARRAY_EQUATION()  then Type.sizeOf(eqn.ty);
        case SIMPLE_EQUATION() then Type.sizeOf(eqn.ty);
        case RECORD_EQUATION() then Type.sizeOf(eqn.ty);
        case ALGORITHM()       then eqn.size;
        case IF_EQUATION()     then eqn.size;
        case FOR_EQUATION()    then Type.sizeOf(eqn.ty); //probably wrong
        case WHEN_EQUATION()   then eqn.size;
        case AUX_EQUATION()    then Variable.size(Pointer.access(eqn.auxiliary));
        case DUMMY_EQUATION()  then 0;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for:\n" + toString(eqn)});
        then fail();
      end match;
    end size;

    function hash
      "only hashes the name"
      input Pointer<Equation> eqn;
      input Integer mod;
      output Integer i = Variable.hash(Pointer.access(getResidualVar(eqn)), mod);
    end hash;

    function equalName
      input Pointer<Equation> eqn1;
      input Pointer<Equation> eqn2;
      output Boolean b = ComponentRef.isEqual(getEqnName(eqn1), getEqnName(eqn2));
    end equalName;

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

    function makeStartEq
      " x = $START.x"
      input ComponentRef lhs;
      input ComponentRef rhs;
      input Pointer<Integer> idx;
      input list<tuple<ComponentRef, Expression>> frames = {};
      output Pointer<Equation> eq;
    algorithm
      if listLength(frames) == 0 then
        eq := Pointer.create(SIMPLE_EQUATION(
          ty      = ComponentRef.getSubscriptedType(lhs, true),
          lhs     = lhs,
          rhs     = rhs,
          source  = DAE.emptyElementSource,
          attr    = EQ_ATTR_DEFAULT_INITIAL
        ));
      else
        eq := Pointer.create(FOR_EQUATION(
          ty      = ComponentRef.nodeType(lhs),
          iter    = Iterator.fromFrames(frames),
          body    = SIMPLE_EQUATION(ComponentRef.getSubscriptedType(lhs, true), lhs, rhs, DAE.emptyElementSource, EQ_ATTR_DEFAULT_INITIAL),
          source  = DAE.emptyElementSource,
          attr    = EQ_ATTR_DEFAULT_INITIAL
        ));
      end if;
      Equation.createName(eq, idx, "SRT");
    end makeStartEq;

    function makePreEq
      "$PRE.d = d"
      input ComponentRef lhs;
      input ComponentRef rhs;
      input Pointer<Integer> idx;
      output Pointer<Equation> eq;
    algorithm
      eq := Pointer.create(SIMPLE_EQUATION(ComponentRef.getSubscriptedType(lhs, true), lhs, rhs, DAE.emptyElementSource, EQ_ATTR_DEFAULT_INITIAL));
      Equation.createName(eq, idx, "PRE");
    end makePreEq;

    function forEquationToString
      input Iterator iter             "the iterator variable(s)";
      input Equation body             "iterated equation";
      input output String str = "";
      input String indent = "";
      input String indicator = "";
    protected
      String iterators;
    algorithm
      str := str + indicator + "\n";
      str := str + indent + "for " + Iterator.toString(iter) + " loop\n";
      str := str + toString(body, indent + "  ") + "\n";
      str := str + indent + "end for;";
    end forEquationToString;

    function getAttributes
      input Equation eq;
      output EquationAttributes attr;
    algorithm
      attr := match eq
        local
          EquationAttributes tmp;
          Equation body;
        case SCALAR_EQUATION(attr = tmp)      then tmp;
        case ARRAY_EQUATION(attr = tmp)       then tmp;
        case SIMPLE_EQUATION(attr = tmp)      then tmp;
        case RECORD_EQUATION(attr = tmp)      then tmp;
        case ALGORITHM(attr = tmp)            then tmp;
        case IF_EQUATION(attr = tmp)          then tmp;
        case FOR_EQUATION(attr = tmp)         then tmp;
        case WHEN_EQUATION(attr = tmp)        then tmp;
        case AUX_EQUATION(body = SOME(body))  then getAttributes(body);
                                              else EQ_ATTR_DEFAULT_UNKNOWN;
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
        case SIMPLE_EQUATION()  algorithm eq.attr := attr; then eq;
        case RECORD_EQUATION()  algorithm eq.attr := attr; then eq;
        case ALGORITHM()        algorithm eq.attr := attr; then eq;
        case IF_EQUATION()      algorithm eq.attr := attr; then eq;
        case FOR_EQUATION()     algorithm eq.attr := attr; then eq;
        case WHEN_EQUATION()    algorithm eq.attr := attr; then eq;
        case AUX_EQUATION(body = SOME(body)) algorithm eq.body := SOME(setAttributes(body, attr)); then eq;
        end match;
    end setAttributes;

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

        case SCALAR_EQUATION()
          algorithm
            lhs := Expression.map(eq.lhs, funcExp);
            rhs := Expression.map(eq.rhs, funcExp);
            if not referenceEq(lhs, eq.lhs) then
              eq.lhs := lhs;
            end if;
            if not referenceEq(rhs, eq.rhs) then
              eq.rhs := rhs;
            end if;
        then eq;

        case ARRAY_EQUATION()
          algorithm
            lhs := Expression.map(eq.lhs, funcExp);
            rhs := Expression.map(eq.rhs, funcExp);
            if not referenceEq(lhs, eq.lhs) then
              eq.lhs := lhs;
            end if;
            if not referenceEq(rhs, eq.rhs) then
              eq.rhs := rhs;
            end if;
        then eq;

        case SIMPLE_EQUATION()
          algorithm
            if isSome(funcCrefOpt) then
              SOME(funcCref) := funcCrefOpt;
              lhs_cref := funcCref(eq.lhs);
              rhs_cref := funcCref(eq.rhs);
              if not referenceEq(lhs_cref, eq.lhs) then
                eq.lhs := lhs_cref;
              end if;
              if not referenceEq(rhs_cref, eq.rhs) then
                eq.rhs := rhs_cref;
              end if;
            end if;
        then eq;

        case RECORD_EQUATION()
          algorithm
            lhs := Expression.map(eq.lhs, funcExp);
            rhs := Expression.map(eq.rhs, funcExp);
            if not referenceEq(lhs, eq.lhs) then
              eq.lhs := lhs;
            end if;
            if not referenceEq(rhs, eq.rhs) then
              eq.rhs := rhs;
            end if;
        then eq;

        case ALGORITHM()
          algorithm
            alg := Algorithm.mapExp(eq.alg, funcExp);
            if isSome(funcCrefOpt) then
              SOME(funcCref) := funcCrefOpt;
              // ToDo referenceEq for lists?
              //alg.inputs := List.map(alg.inputs, funcCref);
              alg.outputs := List.map(alg.outputs, funcCref);
            end if;
            eq.alg := alg;
        then eq;

        case IF_EQUATION()
          algorithm
            ifEqBody := IfEquationBody.map(eq.body, funcExp, funcCrefOpt);
            if not referenceEq(ifEqBody, eq.body) then
              eq.body := ifEqBody;
            end if;
        then eq;

        case FOR_EQUATION()
          algorithm
            iter := Iterator.map(eq.iter, funcExp);
            body := map(eq.body, funcExp, funcCrefOpt);
            if not referenceEq(iter, eq.iter) then
              eq.iter := iter;
            end if;
            if not referenceEq(body, eq.body) then
              eq.body := body;
            end if;
        then eq;

        case WHEN_EQUATION()
          algorithm
            whenEqBody := WhenEquationBody.map(eq.body, funcExp, funcCrefOpt);
            if not referenceEq(whenEqBody, eq.body) then
              eq.body := whenEqBody;
            end if;
        then eq;

        case AUX_EQUATION(body = SOME(body))
          algorithm
            new_body := map(body, funcExp, funcCrefOpt);
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
      input filterCref filter;
      output list<ComponentRef> cref_lst;

      partial function filterCref
        "partial function that needs to be provided.
        decides if the the cref is added to the list pointer."
        input output ComponentRef cref;
        input Pointer<list<ComponentRef>> cref_lst_ptr;
      end filterCref;

      function filterExp
        "wrapper function that applies filter cref to
        a cref expression."
        input output Expression exp;
        input filterCref filter;
        input Pointer<list<ComponentRef>> cref_lst_ptr;
      algorithm
        _ := match exp
          local
            ComponentRef cref;
            filterCref func;
          case Expression.CREF(cref = cref) algorithm
            filter(cref, cref_lst_ptr);
          then ();
          else ();
        end match;
      end filterExp;

    protected
      Pointer<list<ComponentRef>> cref_lst_ptr = Pointer.create({});
    algorithm
      // map with the expression and cref filter functions
      _ := map(eq, function filterExp(filter = filter, cref_lst_ptr = cref_lst_ptr),
              SOME(function filter(cref_lst_ptr = cref_lst_ptr)));
      cref_lst := Pointer.access(cref_lst_ptr);
    end collectCrefs;

    function getLHS
      "gets the left hand side expression of an equation."
      input Equation eq;
      output Expression lhs;
    algorithm
      lhs := match(eq)
        local
          ComponentRef cref;
        case SCALAR_EQUATION(lhs = lhs)   then lhs;
        case ARRAY_EQUATION(lhs = lhs)    then lhs;
        case RECORD_EQUATION(lhs = lhs)   then lhs;
        case SIMPLE_EQUATION(lhs = cref)  then Expression.fromCref(cref);
        else fail();
      end match;
    end getLHS;

    function getRHS
      "gets the right hand side expression of an equation."
      input Equation eq;
      output Expression rhs;
    algorithm
      rhs := match(eq)
        local
          ComponentRef cref;
        case SCALAR_EQUATION(rhs = rhs)   then rhs;
        case ARRAY_EQUATION(rhs = rhs)    then rhs;
        case RECORD_EQUATION(rhs = rhs)   then rhs;
        case SIMPLE_EQUATION(rhs = cref)  then Expression.fromCref(cref);
        else fail();
      end match;
    end getRHS;

    function setLHS
      "sets the left hand side expression of an equation."
      input output Equation eq;
      input Expression lhs;
    algorithm
      eq := match(eq)
        local
          ComponentRef cref;
          Equation new_eq;
        case SCALAR_EQUATION()
          algorithm
            eq.lhs := lhs;
        then eq;
        case ARRAY_EQUATION()
          algorithm
            eq.lhs := lhs;
        then eq;
        case RECORD_EQUATION()
          algorithm
            eq.lhs := lhs;
        then eq;
        case SIMPLE_EQUATION()
          algorithm
            new_eq := match lhs
              local ComponentRef cr;
              case Expression.CREF(cref = cr) algorithm
                eq.lhs := cr;
              then eq;
              case _ guard(Type.isScalar(Expression.typeOf(lhs)))
              then SCALAR_EQUATION(Expression.typeOf(lhs), lhs, Expression.fromCref(eq.rhs), eq.source, eq.attr);
              else ARRAY_EQUATION(Expression.typeOf(lhs), lhs, Expression.fromCref(eq.rhs), eq.source, eq.attr, NONE());
            end match;
        then new_eq;
        else fail();
      end match;
    end setLHS;

    function setRHS
      "sets the right hand side expression of an equation."
      input output Equation eq;
      input Expression rhs;
    algorithm
      eq := match(eq)
        local
          ComponentRef cref;
          Equation new_eq;
        case SCALAR_EQUATION()
          algorithm
            eq.rhs := rhs;
        then eq;
        case ARRAY_EQUATION()
          algorithm
            eq.rhs := rhs;
        then eq;
        case RECORD_EQUATION()
          algorithm
            eq.rhs := rhs;
        then eq;
        case SIMPLE_EQUATION()
          algorithm
            new_eq := match rhs
              local ComponentRef cr;
              case Expression.CREF(cref = cr) algorithm
                eq.rhs := cr;
              then eq;
              case _ guard(Type.isScalar(Expression.typeOf(rhs)))
              then SCALAR_EQUATION(eq.ty, Expression.fromCref(eq.lhs), rhs, eq.source, eq.attr);
              else ARRAY_EQUATION(eq.ty, Expression.fromCref(eq.lhs), rhs, eq.source, eq.attr, NONE());
            end match;
        then new_eq;
      end match;
    end setRHS;

    function fromLHSandRHS
      input Expression lhs;
      input Expression rhs;
      input Pointer<Integer> idx;
      input String context;
      input EquationAttributes attr = EQ_ATTR_DEFAULT_UNKNOWN;
      input DAE.ElementSource source = DAE.emptyElementSource;
      output Pointer<Equation> eqn_ptr;
    protected
      Type ty;
      Equation eqn;
    algorithm
      ty := Expression.typeOf(lhs);
      eqn := match ty
        case Type.ARRAY() then ARRAY_EQUATION(ty, lhs, rhs, source, attr, NONE());
                          else SCALAR_EQUATION(ty, lhs, rhs, source, attr);
      end match;
      eqn_ptr := Pointer.create(eqn);
      Equation.createName(eqn_ptr, idx, context);
    end fromLHSandRHS;

    function updateLHSandRHS
      input Pointer<Equation> eqn_ptr;
      input Expression lhs;
      input Expression rhs;
    protected
      Type ty;
      Equation eqn = Pointer.access(eqn_ptr);
      EquationAttributes attr = getAttributes(eqn);
      DAE.ElementSource src = source(eqn);
    algorithm
      ty := Expression.typeOf(lhs);
      eqn := match ty
        case Type.ARRAY() then ARRAY_EQUATION(ty, lhs, rhs, src, attr, NONE());
                          else SCALAR_EQUATION(ty, lhs, rhs, src, attr);
      end match;
      Pointer.update(eqn_ptr, eqn);
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

        case Equation.SIMPLE_EQUATION() algorithm
          tmpCref := eqn.rhs;
          eqn.rhs := eqn.lhs;
          eqn.lhs := tmpCref;
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
          eq.lhs := SimplifyExp.simplifyDump(eq.lhs, name, indent);
          eq.rhs := SimplifyExp.simplifyDump(eq.rhs, name, indent);
        then eq;
        case ARRAY_EQUATION() algorithm
          eq.lhs := SimplifyExp.simplifyDump(eq.lhs, name, indent);
          eq.rhs := SimplifyExp.simplifyDump(eq.rhs, name, indent);
        then eq;
        case SIMPLE_EQUATION() then eq;
        case RECORD_EQUATION() algorithm
          eq.lhs := SimplifyExp.simplifyDump(eq.lhs, name, indent);
          eq.rhs := SimplifyExp.simplifyDump(eq.rhs, name, indent);
        then eq;
        // ToDo: implement the following correctly:
        case ALGORITHM()       then eq;
        case IF_EQUATION()     then eq;
        case FOR_EQUATION()    then eq;
        case WHEN_EQUATION()   then eq;
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
    algorithm
      // create residual var as name
      (residualVar, _) := BVariable.makeResidualVar(context, Pointer.access(idx), getType(eqn));
      Pointer.update(idx, Pointer.access(idx) + 1);

      // update equation attributes
      eqn := match eqn
        case SCALAR_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case ARRAY_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case SIMPLE_EQUATION() algorithm
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
      Pointer.update(eqn_ptr, eqn);
    end createName;

    function createResidual
      "Creates a residual equation from a regular equation.
      Expample (for DAEMode): $RES_DAE_idx := rhs.
      Does not solve the equation, only saves the residual term!"
      input output Equation eqn;
      input String context;
      input Pointer<list<Pointer<Variable>>> residual_vars;
      input Pointer<Integer> idx;
    protected
      Pointer<Variable> residualVar;
    algorithm
      // create residual var and update pointers
      (residualVar, _) := BVariable.makeResidualVar(context, Pointer.access(idx), getType(eqn));
      Pointer.update(residual_vars, residualVar :: Pointer.access(residual_vars));
      Pointer.update(idx, Pointer.access(idx) + 1);

      // update equation attributes
      eqn := match eqn
        case SCALAR_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case ARRAY_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case SIMPLE_EQUATION() algorithm
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

        case Equation.SIMPLE_EQUATION() algorithm
          operator := Operator.OPERATOR(ComponentRef.getComponentType(eqn.lhs), NFOperator.Op.ADD);
        then Expression.MULTARY({Expression.fromCref(eqn.rhs)},{Expression.fromCref(eqn.lhs)}, operator);

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

        // returns innermost residual!
        case Equation.FOR_EQUATION() then getResidualExp(eqn.body);

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
        then fail();
      end match;
      exp := SimplifyExp.simplify(exp);
    end getResidualExp;

    function getType
      input Equation eq;
      output Type ty;
    algorithm
      ty := match eq
        case SCALAR_EQUATION()  then eq.ty;
        case SIMPLE_EQUATION()  then eq.ty;
        case ARRAY_EQUATION()   then eq.ty;
        case RECORD_EQUATION()  then eq.ty;
        case FOR_EQUATION()     then eq.ty;
                                else Type.REAL(); // TODO: WRONG there should not be an else case
      end match;
    end getType;

    function getForIterators
      input Equation eqn;
      output list<ComponentRef> iterators;
    algorithm
      iterators := match eqn

        case FOR_EQUATION() algorithm
          (iterators, _) := Iterator.getFrames(eqn.iter);
        then iterators;

        // ToDo: algorithms!

        else {};
      end match;
    end getForIterators;

    function getForFrames
      input Equation eqn;
      output list<tuple<ComponentRef, Expression>> frames;
    algorithm
      frames := match eqn
        local
          list<ComponentRef> names;
          list<Expression> ranges;

        case FOR_EQUATION() algorithm
          (names, ranges) := Iterator.getFrames(eqn.iter);
        then List.zip(names, ranges);

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because eqation is not a for-equation: \n"
            + Equation.toString(eqn)});
        then fail();
      end match;
    end getForFrames;

    function isDiscrete
      input Pointer<Equation> eqn;
      output Boolean b;
    protected
      EquationAttributes attr;
    algorithm
      attr := getAttributes(Pointer.access(eqn));
      b := EquationKind.isDiscrete(attr.kind);
    end isDiscrete;

    function isInitial
      input Pointer<Equation> eqn;
      output Boolean b;
    protected
      EquationAttributes attr;
    algorithm
      attr := getAttributes(Pointer.access(eqn));
      b := EquationKind.isInitial(attr.kind);
    end isInitial;

    function isWhenEquation
      input Pointer<Equation> eqn;
      output Boolean b;
    algorithm
      b := match Pointer.access(eqn)
        case Equation.WHEN_EQUATION() then true;
        else false;
      end match;
    end isWhenEquation;

    function isForEquation
      input Pointer<Equation> eqn;
      output Boolean b;
    algorithm
      b := match Pointer.access(eqn)
        case Equation.FOR_EQUATION() then true;
        else false;
      end match;
    end isForEquation;

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
        _ := match exp
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
      output Pointer<Equation> eqn;
    protected
      Variable var;
      Expression lhs, rhs;
    algorithm
      var := Pointer.access(var_ptr);
      lhs := Expression.fromCref(var.name);
      rhs := match var.binding
        local
          Binding qual;
        case qual as Binding.TYPED_BINDING()  then qual.bindingExp;
        case qual as Binding.UNBOUND()        then Expression.makeZero(Expression.typeOf(lhs));
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of wrong binding type: " + Binding.toString(var.binding) + " for variable " + Variable.toString(Pointer.access(var_ptr))});
        then fail();
      end match;
      eqn := Equation.fromLHSandRHS(lhs, rhs, idx, "BND", EQ_ATTR_DEFAULT_INITIAL);
    end generateBindingEquation;

    function mergeIterators
      input output Equation eq;
      input Boolean top_level = true;
      output list<Iterator> acc;
    algorithm
      (eq, acc) := match eq
        local
          Equation body;
        case FOR_EQUATION() algorithm
          (body, acc) := mergeIterators(eq.body, false);
          acc := eq.iter :: acc;
        then (if top_level then Equation.FOR_EQUATION(eq.ty, Iterator.merge(acc), body, eq.source, eq.attr) else body, acc);
        else (eq, {});
      end match;
    end mergeIterators;

    function splitIterators
      input output Equation eq;
    algorithm
      eq := match eq
        local
          list<Iterator> iterators;
          Equation body;
        case FOR_EQUATION() algorithm
          // split returns innermost first
          iterators := Iterator.split(eq.iter);
          body := eq.body;
          for iter in iterators loop
            body := Equation.FOR_EQUATION(eq.ty, iter, body, eq.source, eq.attr);
          end for;
        then body;
        else eq;
      end match;
    end splitIterators;

    function slice
      "performs a single slice based on the given indices and the cref to solve for"
      input output Pointer<Equation> eqn_ptr  "equation to slice";
      input list<Integer> indices             "zero based indices of the eqn";
      input Option<ComponentRef> cref_opt     "optional cref to solve for, if none is given, the body stays as it is";
      output SlicingStatus status             "has unchanged, trivial (only rearranged) or nontrivial";
      input output FunctionTree funcTree      "function tree for solving";
    protected
      Equation eqn;
      Integer first_idx                       "first strong component index";
      Integer last_idx                        "last strong component index";
      list<tuple<ComponentRef, Expression>> frames;
      list<Dimension> dims;
      list<Integer> sizes;
      list<Integer> first_frame_location, last_frame_location, frame_comp;
      list<list<Integer>> frame_locations;
      list<array<Integer>> frame_locations_T;
      list<tuple<Integer, Integer, Integer>> ranges;
    algorithm
      eqn := Pointer.access(eqn_ptr);
      (eqn_ptr, status) := match eqn
        local
          Equation body, sliced;

        // empty index list indicates no slicing and no rearraning
        case _ guard(listEmpty(indices)) then (eqn_ptr, SlicingStatus.UNCHANGED);

        case FOR_EQUATION() algorithm
          // get the sizes of the 'return value' if the equation
          dims      := Type.arrayDims(Equation.getType(eqn));
          sizes     := list(Dimension.size(dim) for dim in dims);

          if Equation.size(eqn_ptr) == listLength(indices) then
            // trivial solution! All equations are solved the same way
            // only invert the necessary frames and keep the rest as is
            status                := SlicingStatus.TRIVIAL;

            // map first and last index to frame locations
            first_idx             := List.first(indices);
            last_idx              := List.last(indices);
            first_frame_location  := BackendUtil.indexToFrame(first_idx, sizes);
            last_frame_location   := BackendUtil.indexToFrame(last_idx, sizes);

            // compare the location to see if any range has to be inverted
            frame_comp            := BackendUtil.compareFrames(first_frame_location, last_frame_location);
            frames                := getForFrames(eqn);
            frames                := BackendUtil.applyFrameInversion(frames, frame_comp);
          else
            // nontrivial. try to rebuild the for loop frames and slice the equation
            status                := SlicingStatus.NONTRIVIAL;
            frame_locations       := list(BackendUtil.indexToFrame(idx, sizes) for idx in indices);
            frame_locations_T     := BackendUtil.transposeFrameLocations(frame_locations, listLength(sizes));
            ranges                := BackendUtil.recollectRangesHeuristic(frame_locations_T);
            frames                := getForFrames(eqn);
            frames                := BackendUtil.applyNewFrameRanges(frames, ranges);
          end if;

          // solve the body equation for the cref if needed
          // ToDo: act on solving status not equal to EXPLICIT ?
          body := match cref_opt
            local
              ComponentRef cref;
            case SOME(cref) algorithm
              (body, funcTree, _, _) := Solve.solve(eqn.body, cref, funcTree);
            then body;
            else eqn.body;
          end match;

          sliced := FOR_EQUATION(
            ty      = eqn.ty,
            iter    = Iterator.fromFrames(frames),
            body    = body,
            source  = eqn.source,
            attr    = eqn.attr
          );
          // create a new pointer and do not overwrite the old one!
        then (Pointer.create(sliced), status);

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because slicing is not yet supported for: \n" + toString(eqn)});
        then fail();
      end match;
    end slice;

    function toStatement
      "expects for loops to be split with splitIterators(eqn)"
      input Equation eqn;
      output Statement stmt;
    algorithm
      stmt := match eqn
        local
          ComponentRef iter;
          Expression range;

        case Equation.SCALAR_EQUATION()
        then Statement.ASSIGNMENT(eqn.lhs, eqn.rhs, Type.arrayElementType(eqn.ty), eqn.source);

        case Equation.SIMPLE_EQUATION()
        then Statement.ASSIGNMENT(Expression.fromCref(eqn.lhs), Expression.fromCref(eqn.rhs), Type.arrayElementType(eqn.ty), eqn.source);

        case Equation.FOR_EQUATION() algorithm
          ({iter},{range}) := Equation.Iterator.getFrames(eqn.iter);
        then Statement.FOR(
          iterator  = ComponentRef.node(iter),
          range     = SOME(range),
          body      = {toStatement(eqn.body)},
          source    = eqn.source
        );

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
        str := elseStr + "if " + Expression.toString(body.condition) + " then \n";
      else
        str := elseStr + "\n";
      end if;
      for eqn in body.then_eqns loop
        str := str + Equation.toString(Pointer.access(eqn), indent + "  ") + "\n";
      end for;
      if isSome(body.else_if) then
        SOME(elseIf) := body.else_if;
        str := str + toString(elseIf, indent, indent +"else ", true);
      end if;
      if not selfCall then
        str := str + indent + "end if;\n";
      end if;
    end toString;

    function map
      input output IfEquationBody ifBody;
      input MapFuncExp funcExp;
      input Option<MapFuncCref> funcCrefOpt;
    protected
      Expression condition;
    algorithm
      condition := Expression.map(ifBody.condition, funcExp);
      if not referenceEq(condition, ifBody.condition) then
        ifBody.condition := condition;
      end if;

      // referenceEq for lists?
      ifBody.then_eqns := List.map(ifBody.then_eqns, function Pointer.apply(func = function Equation.map(funcExp = function funcExp(), funcCrefOpt = function funcCrefOpt())));
    end map;
  end IfEquationBody;

  uniontype WhenEquationBody
    record WHEN_EQUATION_BODY "equation when condition then cr = exp, reinit(...), terminate(...) or assert(...)"
      Expression condition                  "the when-condition (Expression.END for no condition)" ;
      list<WhenStatement> when_stmts        "body statements";
      Option<WhenEquationBody> else_when    "optional elsewhen body";
    end WHEN_EQUATION_BODY;

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

    function getBodyAttributes
      "gets all conditions crefs as a list (has to be applied AFTER Event module)"
      input WhenEquationBody body;
      output list<ComponentRef> conditions;
      output list<WhenStatement> when_stmts = body.when_stmts;
      output Option<WhenEquationBody> else_when = body.else_when;
    algorithm
      conditions := match body.condition
        local
          ComponentRef cref;
        case Expression.CREF(cref = cref) then {cref};
        // ToDo: Array/Tuple etc
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
        then fail();
      end match;
    end getBodyAttributes;

    function map
      input output WhenEquationBody whenBody;
      input MapFuncExp funcExp;
      input Option<MapFuncCref> funcCrefOpt;
    protected
      Expression condition;
    algorithm
      condition := Expression.map(whenBody.condition, funcExp);
      if not referenceEq(condition, whenBody.condition) then
        whenBody.condition := condition;
      end if;

      // ToDo reference eq for lists?
      whenBody.when_stmts := List.map(whenBody.when_stmts, function WhenStatement.map(funcExp = funcExp, funcCrefOpt = funcCrefOpt));
    end map;
/*
    function convert
      input WhenEquationBody body;
      output OldBackendDAE.WhenEquation oldBody;
    protected
      DAE.Exp condition;
      list<BackendDAE.WhenOperator> stmts;
      BackendDAE.WhenEquation elseWhen;
    algorithm
      // convert the attributes
      condition := Expression.toDAE(body.condition);
      stmts     := list(WhenStatement.convert(stmt) for stmt in body.when_stmts);
      elseWhen  := if Util.isSome(body.else_when) then convert(Util.getOption(body.else_when)) else NONE();
      // create the when equation body itself
      oldBody   := OldBackendDAE.WHEN_STMTS(
        condition     = condition,
        whenStmtLst   = stmts,
        elsewhenPart  = elseWhen
      );
    end convert;
*/
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

    function map
      input output WhenStatement stmt;
      input MapFunc funcExp;
      input Option<MapFuncCref> funcCrefOpt;
      partial function MapFunc
        input output Expression e;
      end MapFunc;
      partial function MapFuncCref
        input output ComponentRef c;
      end MapFuncCref;
    algorithm
      stmt := match stmt
        local
          MapFuncCref funcCref;
          Expression lhs, rhs, value, condition;
          ComponentRef stateVar;

        case ASSIGN()
          algorithm
            lhs := Expression.map(stmt.lhs, funcExp);
            rhs := Expression.map(stmt.rhs, funcExp);
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
            value := Expression.map(stmt.value, funcExp);
            if not referenceEq(value, stmt.value) then
              stmt.value := value;
            end if;
        then stmt;

        case ASSERT()
          algorithm
            condition := Expression.map(stmt.condition, funcExp);
            if not referenceEq(condition, stmt.condition) then
              stmt.condition := condition;
            end if;
        then stmt;

        case TERMINATE() then stmt;

        case NORETCALL()
          algorithm
            value := Expression.map(stmt.exp, funcExp);
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
      Option<Pointer<Equation>> derivative;
      EquationKind kind;
      EvaluationStages evalStages;
      Option<Pointer<Variable>> residualVar "also used to represent the equation itself";
    end EQUATION_ATTRIBUTES;

    function toString
      input EquationAttributes attr;
      output String str;
    algorithm
      str := match attr
        local
          Pointer<Variable> residualVar;
        case EQUATION_ATTRIBUTES(residualVar = SOME(residualVar))
        then "(" + ComponentRef.toString(BVariable.getVarName(residualVar)) + ") ";
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
        kind            = EquationKind.convert(attributes.kind),
        evalStages      = EvaluationStages.convert(attributes.evalStages));
    end convert;
  end EquationAttributes;

  constant EquationAttributes EQ_ATTR_DEFAULT_DYNAMIC = EQUATION_ATTRIBUTES(NONE(), DYNAMIC_EQUATION(), DEFAULT_EVALUATION_STAGES, NONE());
  constant EquationAttributes EQ_ATTR_DEFAULT_BINDING = EQUATION_ATTRIBUTES(NONE(), BINDING_EQUATION(), DEFAULT_EVALUATION_STAGES, NONE());
  constant EquationAttributes EQ_ATTR_DEFAULT_INITIAL = EQUATION_ATTRIBUTES(NONE(), INITIAL_EQUATION(), DEFAULT_EVALUATION_STAGES, NONE());
  constant EquationAttributes EQ_ATTR_DEFAULT_DISCRETE = EQUATION_ATTRIBUTES(NONE(), DISCRETE_EQUATION(), DEFAULT_EVALUATION_STAGES, NONE());
  constant EquationAttributes EQ_ATTR_DEFAULT_AUX = EQUATION_ATTRIBUTES(NONE(), AUX_EQUATION(), DEFAULT_EVALUATION_STAGES, NONE());
  constant EquationAttributes EQ_ATTR_EMPTY_DISCRETE = EQUATION_ATTRIBUTES(NONE(), EMPTY_EQUATION(), DEFAULT_EVALUATION_STAGES, NONE());
  constant EquationAttributes EQ_ATTR_DEFAULT_UNKNOWN = EQUATION_ATTRIBUTES(NONE(), UNKNOWN_EQUATION_KIND(), DEFAULT_EVALUATION_STAGES, NONE());

  uniontype EquationKind
    record BINDING_EQUATION end BINDING_EQUATION;
    record DYNAMIC_EQUATION end DYNAMIC_EQUATION;
    record INITIAL_EQUATION end INITIAL_EQUATION;
    record CLOCKED_EQUATION Integer clk; end CLOCKED_EQUATION;
    record DISCRETE_EQUATION end DISCRETE_EQUATION;
    record AUX_EQUATION "ToDo! Do we still need this?" end AUX_EQUATION;
    record EMPTY_EQUATION end EMPTY_EQUATION;
    record UNKNOWN_EQUATION_KIND end UNKNOWN_EQUATION_KIND;

    function convert
      input EquationKind eqKind;
      output OldBackendDAE.EquationKind oldEqKind;
    algorithm
      oldEqKind := match eqKind
        local
          Integer clk;
        case BINDING_EQUATION()           then OldBackendDAE.BINDING_EQUATION();
        case DYNAMIC_EQUATION()           then OldBackendDAE.DYNAMIC_EQUATION();
        case INITIAL_EQUATION()           then OldBackendDAE.INITIAL_EQUATION();
        case CLOCKED_EQUATION(clk = clk)  then OldBackendDAE.CLOCKED_EQUATION(clk);
        case DISCRETE_EQUATION()          then OldBackendDAE.DISCRETE_EQUATION();
        case AUX_EQUATION()               then OldBackendDAE.AUX_EQUATION();
        case EMPTY_EQUATION()             then OldBackendDAE.AUX_EQUATION();
        case UNKNOWN_EQUATION_KIND()      then OldBackendDAE.UNKNOWN_EQUATION_KIND();
        else fail();
      end match;
    end convert;

    function isDiscrete
      input EquationKind eqKind;
      output Boolean b;
    algorithm
      b := match eqKind
        case DISCRETE_EQUATION() then true;
        else false;
      end match;
    end isDiscrete;

    function isInitial
      input EquationKind eqKind;
      output Boolean b;
    algorithm
      b := match eqKind
        case INITIAL_EQUATION() then true;
        else false;
      end match;
    end isInitial;
  end EquationKind;

  uniontype EvaluationStages
    record EVALUATION_STAGES
      Boolean dynamicEval;
      Boolean algebraicEval;
      Boolean zerocrossEval;
      Boolean discreteEval;
    end EVALUATION_STAGES;

    function convert
      input EvaluationStages evalStages;
      output OldBackendDAE.EvaluationStages oldEvalStages;
    algorithm
      oldEvalStages := OldBackendDAE.EVALUATION_STAGES(
        dynamicEval   = evalStages.dynamicEval,
        algebraicEval = evalStages.algebraicEval,
        zerocrossEval = evalStages.zerocrossEval,
        discreteEval  = evalStages.discreteEval);
    end convert;
  end EvaluationStages;

  constant EvaluationStages DEFAULT_EVALUATION_STAGES = EVALUATION_STAGES(true,true,false,true);

  uniontype EquationPointers
    record EQUATION_POINTERS
      UnorderedMap<ComponentRef, Integer> map   "Map for cref->index";
      ExpandableArray<Pointer<Equation>> eqArr;
    end EQUATION_POINTERS;

    function toString
      input EquationPointers equations;
      input output String str = "";
      input Boolean printEmpty = true;
    protected
      Integer numberOfElements = EquationPointers.size(equations);
      Integer length = 10;
      String index;
    algorithm
      if printEmpty or numberOfElements > 0 then
        str := StringUtil.headline_4(str + " Equations (" + intString(numberOfElements) + "/" + intString(scalarSize(equations)) + ")");
        for i in 1:numberOfElements loop
          index := "(" + intString(i) + ")";
          index := index + StringUtil.repeat(" ", length - stringLength(index));
          str := str + Equation.toString(Pointer.access(ExpandableArray.get(i, equations.eqArr)), index) + "\n";
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
      output EquationPointers new = fromList(toList(equations));
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
      _ := match UnorderedMap.get(name, equations.map)
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
      _ := match UnorderedMap.get(name, equations.map)
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
      input MapFunc func;
      partial function MapFunc
        input output Equation e;
      end MapFunc;
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
      input MapFunc func;
      partial function MapFunc
        input Pointer<Equation> e;
      end MapFunc;
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
      Reorders the elements in order to remove all the gaps.
      Be careful: This changes the indices of the elements."
      input output EquationPointers equations;
    algorithm
      // delete all empty equations
      for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          _ := match Pointer.access(ExpandableArray.get(i, equations.eqArr))
            case Equation.DUMMY_EQUATION() algorithm
              equations.eqArr := ExpandableArray.delete(i, equations.eqArr);
            then ();
            else ();
          end match;
        end if;
      end for;
      // compress the array
      equations.eqArr := ExpandableArray.compress(equations.eqArr);
      // fix the mapping. ToDo: can this be done more efficiently?
      for i in 1:ExpandableArray.getNumberOfElements(equations.eqArr) loop
        UnorderedMap.add(Equation.getEqnName(ExpandableArray.get(i, equations.eqArr)), i, equations.map);
      end for;
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

  protected
    function createSortHashTpl
      "Helper function for sort(). Creates the hash value without considering the names and
      adds it as a tuple to the list in pointer."
      input Pointer<Equation> eqn_ptr;
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
            if level == 0 then
              tmp :=  EquationPointers.toString(eqData.equations, "Simulation", false);
            else
              tmp :=  EquationPointers.toString(eqData.continuous, "Continuous", false) +
                      EquationPointers.toString(eqData.discretes, "Discrete", false) +
                      EquationPointers.toString(eqData.initials, "(Exclusively) Initial", false) +
                      EquationPointers.toString(eqData.auxiliaries, "Auxiliary", false) +
                      EquationPointers.toString(eqData.removed, "Removed", false);
            end if;
        then tmp;

        case EQ_DATA_JAC()
          algorithm
            if level == 0 then
              tmp :=  EquationPointers.toString(eqData.equations, "Jacobian", false);
            else
              tmp :=  EquationPointers.toString(eqData.results, "Result", false) +
                      EquationPointers.toString(eqData.temporary, "Temporary Inner", false) +
                      EquationPointers.toString(eqData.auxiliaries, "Auxiliary", false);
            end if;
        then tmp;

        case EQ_DATA_HES()
          algorithm
            if level == 0 then
              tmp :=  EquationPointers.toString(eqData.equations, "Hessian", false);
            else
              tmp :=  StringUtil.headline_4("Result Equation") + "\n" +
                      Equation.toString(Pointer.access(eqData.result)) + "\n" +
                      EquationPointers.toString(eqData.temporary, "Temporary Inner", false) +
                      EquationPointers.toString(eqData.auxiliaries, "Auxiliary", false);
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
              Equation.createName(eqn_ptr, eqData.uniqueIndex, "SIM");
            end for;
          end if;
          eqData.equations := EquationPointers.addList(eq_lst, eqData.equations);
          eqData.simulation := EquationPointers.addList(eq_lst, eqData.simulation);
          eqData.continuous := EquationPointers.addList(eq_lst, eqData.continuous);
        then eqData;

        case (EQ_DATA_SIM(), EqType.DISCRETE) algorithm
          if newName then
            for eqn_ptr in eq_lst loop
              Equation.createName(eqn_ptr, eqData.uniqueIndex, "SIM");
            end for;
          end if;
          eqData.equations := EquationPointers.addList(eq_lst, eqData.equations);
          eqData.simulation := EquationPointers.addList(eq_lst, eqData.simulation);
          eqData.discretes := EquationPointers.addList(eq_lst, eqData.discretes);
        then eqData;

        case (EQ_DATA_SIM(), EqType.INITIAL) algorithm
          if newName then
            for eqn_ptr in eq_lst loop
              Equation.createName(eqn_ptr, eqData.uniqueIndex, "SIM");
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

    function removeList
      input list<Pointer<Equation>> eq_lst;
      input output EqData eqData;
    algorithm
      eqData := match eqData
        case EQ_DATA_SIM() algorithm
          eqData.equations := EquationPointers.removeList(eq_lst, eqData.equations);
          eqData.simulation := EquationPointers.removeList(eq_lst, eqData.simulation);
          eqData.continuous := EquationPointers.removeList(eq_lst, eqData.continuous);
          eqData.discretes := EquationPointers.removeList(eq_lst, eqData.discretes);
          eqData.initials := EquationPointers.removeList(eq_lst, eqData.initials);
          eqData.auxiliaries := EquationPointers.removeList(eq_lst, eqData.auxiliaries);
          eqData.removed := EquationPointers.removeList(eq_lst, eqData.removed);
        then eqData;

        case EQ_DATA_JAC() algorithm
          eqData.equations := EquationPointers.removeList(eq_lst, eqData.equations);
          eqData.results := EquationPointers.removeList(eq_lst, eqData.results);
          eqData.temporary := EquationPointers.removeList(eq_lst, eqData.temporary);
          eqData.auxiliaries := EquationPointers.removeList(eq_lst, eqData.auxiliaries);
          eqData.removed := EquationPointers.removeList(eq_lst, eqData.removed);
        then eqData;

        case EQ_DATA_HES() algorithm
          eqData.equations := EquationPointers.removeList(eq_lst, eqData.equations);
          eqData.temporary := EquationPointers.removeList(eq_lst, eqData.temporary);
          eqData.auxiliaries := EquationPointers.removeList(eq_lst, eqData.auxiliaries);
          eqData.removed := EquationPointers.removeList(eq_lst, eqData.removed);
        then eqData;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
        then fail();
      end match;
    end removeList;
  end EqData;

  uniontype InnerEquation
    record INNER_EQUATION
      "Inner equation for torn systems."
      Pointer<Equation> eqn;
      Pointer<Variable> var;
      //Option<Constraints> cons;
    end INNER_EQUATION;

    function toString
      input InnerEquation eqn;
      input output String str;
    algorithm
      str := Equation.toString(Pointer.access(eqn.eqn), str + "(" + BVariable.pointerToString(eqn.var) + ") ");
    end toString;

    function fromStrongComponent
      input StrongComponent comp;
      output InnerEquation eqn;
    algorithm
      // ToDo: add more cases
      eqn := match comp
        case StrongComponent.SINGLE_EQUATION() then INNER_EQUATION(comp.eqn, comp.var);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because strong component cannot be an inner equation: " + StrongComponent.toString(comp)});
        then fail();
      end match;
    end fromStrongComponent;
  end InnerEquation;

  annotation(__OpenModelica_Interface="backend");
end NBEquation;
