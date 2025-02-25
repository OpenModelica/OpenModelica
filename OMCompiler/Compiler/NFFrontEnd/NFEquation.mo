/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

encapsulated uniontype NFEquation
  import Expression = NFExpression;
  import Type = NFType;
  import NFInstNode.InstNode;
  import DAE;
  import ComponentRef = NFComponentRef;
  import NFPrefixes.Variability;
  import ErrorTypes;

protected
  import ElementSource;
  import Equation = NFEquation;
  import Error;
  import ExpandExp = NFExpandExp;
  import FlatModelicaUtil = NFFlatModelicaUtil;
  import IOStream;
  import Util;
  import Call = NFCall;
  import MetaModelica.Dangerous.listReverseInPlace;

public
  uniontype Branch
    record BRANCH
      Expression condition;
      Variability conditionVar;
      list<Equation> body;
    end BRANCH;

    record INVALID_BRANCH
      Branch branch;
      list<ErrorTypes.TotalMessage> errors;
    end INVALID_BRANCH;

    function mapExp
      input output Branch branch;
      input MapExpFn func;
      input Boolean mapBody = true;
    protected
      Expression cond;
      list<Equation> eql;
    algorithm
      branch := match branch
        case Branch.BRANCH()
          algorithm
            cond := func(branch.condition);

            if mapBody then
              eql := list(Equation.mapExp(e, func) for e in branch.body);
            else
              eql := branch.body;
            end if;
          then
            Branch.BRANCH(cond, branch.conditionVar, eql);

        case Branch.INVALID_BRANCH()
          algorithm
            // The body of an invalid branch might not be safe to traverse, but
            // the condition still needs to be valid and should be traversed.
            branch.branch := mapExp(branch.branch, func, mapBody = false);
          then
            branch;

        else branch;
      end match;
    end mapExp;

    function isEmpty
      input Branch branch;
      output Boolean empty;
    algorithm
      empty := match branch
        case Branch.BRANCH() then listEmpty(branch.body);
        case Branch.INVALID_BRANCH() then isEmpty(branch.branch);
      end match;
    end isEmpty;

    function sizeOf
      input Branch branch;
      output Integer size;
    algorithm
      size := match branch
        case Branch.BRANCH() then Equation.sizeOfList(branch.body);
        else 0;
      end match;
    end sizeOf;

    function toStream
      input Branch branch;
      input String indent;
      input output IOStream.IOStream s;
    algorithm
      s := match branch
        case BRANCH()
          algorithm
            s := IOStream.append(s, Expression.toString(branch.condition));
            s := IOStream.append(s, " then\n");
            s := toStreamList(branch.body, indent + "  ", s);
          then
            s;

        case INVALID_BRANCH()
          then toStream(branch.branch, indent, s);
      end match;
    end toStream;

    function toFlatStream
      input Branch branch;
      input BaseModelica.OutputFormat format;
      input String indent;
      input output IOStream.IOStream s;
    algorithm
      s := match branch
        case BRANCH()
          algorithm
            s := IOStream.append(s, Expression.toFlatString(branch.condition, format));
            s := IOStream.append(s, " then\n");
            s := toFlatStreamList(branch.body, format, indent + "  ", s);
          then
            s;

        case INVALID_BRANCH()
          then toFlatStream(branch.branch, format, indent, s);
      end match;
    end toFlatStream;

    function toString
      input Branch branch;
      input String indent;
      output String str;
    protected
      IOStream.IOStream s;
    algorithm
      s := IOStream.create(getInstanceName(), IOStream.IOStreamType.LIST());
      s := toStream(branch, indent, s);
      str := IOStream.string(s);
      IOStream.delete(s);
    end toString;

    function triggerErrors
      input Branch branch;
    algorithm
      () := match branch
        case INVALID_BRANCH()
          algorithm
            Error.addTotalMessages(branch.errors);
          then
            fail();

        else ();
      end match;
    end triggerErrors;
  end Branch;

  record EQUALITY
    Expression lhs "The left hand side expression.";
    Expression rhs "The right hand side expression.";
    Type ty;
    InstNode scope;
    DAE.ElementSource source;
  end EQUALITY;

  record ARRAY_EQUALITY
    Expression lhs;
    Expression rhs;
    Type ty;
    InstNode scope;
    DAE.ElementSource source;
  end ARRAY_EQUALITY;

  record CONNECT
    Expression lhs;
    Expression rhs;
    InstNode scope;
    DAE.ElementSource source;
  end CONNECT;

  record FOR
    InstNode iterator;
    Option<Expression> range;
    list<Equation> body   "The body of the for loop.";
    InstNode scope;
    DAE.ElementSource source;
  end FOR;

  record IF
    list<Branch> branches;
    InstNode scope;
    DAE.ElementSource source;
  end IF;

  record WHEN
    list<Branch> branches;
    InstNode scope;
    DAE.ElementSource source;
  end WHEN;

  record ASSERT
    Expression condition "The assert condition.";
    Expression message "The message to display if the assert fails.";
    Expression level "Error or warning";
    InstNode scope;
    DAE.ElementSource source;
  end ASSERT;

  record TERMINATE
    Expression message "The message to display if the terminate triggers.";
    InstNode scope;
    DAE.ElementSource source;
  end TERMINATE;

  record REINIT
    Expression cref "The variable to reinitialize.";
    Expression reinitExp "The new value of the variable.";
    InstNode scope;
    DAE.ElementSource source;
  end REINIT;

  record NORETCALL
    Expression exp;
    InstNode scope;
    DAE.ElementSource source;
  end NORETCALL;

  function makeEquality
    input Expression lhs;
    input Expression rhs;
    input Type ty;
    input InstNode scope;
    input DAE.ElementSource src;
    output Equation eq;
  algorithm
    eq := EQUALITY(lhs, rhs, ty, scope, src);
    annotation(__OpenModelica_EarlyInline=true);
  end makeEquality;

  function makeCrefEquality
    input ComponentRef lhsCref;
    input ComponentRef rhsCref;
    input InstNode scope;
    input DAE.ElementSource src;
    output Equation eq;
  protected
    Expression e1, e2;
  algorithm
    e1 := Expression.fromCref(lhsCref);
    e2 := Expression.fromCref(rhsCref);
    eq := makeEquality(e1, e2, Expression.typeOf(e1), scope, src);
  end makeCrefEquality;

  function makeBranch
    input Expression condition;
    input list<Equation> body;
    input Variability condVar = Variability.CONTINUOUS;
    output Branch branch;
  algorithm
    branch := Branch.BRANCH(condition, condVar, body);
    annotation(__OpenModelica_EarlyInline=true);
  end makeBranch;

  function makeIf
    input list<Branch> branches;
    input InstNode scope;
    input DAE.ElementSource src;
    output Equation eq;
  algorithm
    eq := IF(branches, scope, src);
    annotation(__OpenModelica_EarlyInline=true);
  end makeIf;

  function source
    input Equation eq;
    output DAE.ElementSource source;
  algorithm
    source := match eq
      case EQUALITY() then eq.source;
      case ARRAY_EQUALITY() then eq.source;
      case CONNECT() then eq.source;
      case FOR() then eq.source;
      case IF() then eq.source;
      case WHEN() then eq.source;
      case ASSERT() then eq.source;
      case TERMINATE() then eq.source;
      case REINIT() then eq.source;
      case NORETCALL() then eq.source;
    end match;
  end source;

  function setSource
    input DAE.ElementSource source;
    input output Equation eq;
  algorithm
    () := match eq
      case EQUALITY()       algorithm eq.source := source; then ();
      case ARRAY_EQUALITY() algorithm eq.source := source; then ();
      case CONNECT()        algorithm eq.source := source; then ();
      case FOR()            algorithm eq.source := source; then ();
      case IF()             algorithm eq.source := source; then ();
      case WHEN()           algorithm eq.source := source; then ();
      case ASSERT()         algorithm eq.source := source; then ();
      case TERMINATE()      algorithm eq.source := source; then ();
      case REINIT()         algorithm eq.source := source; then ();
      case NORETCALL()      algorithm eq.source := source; then ();
    end match;
  end setSource;

  function scope
    input Equation eq;
    output InstNode scope;
  algorithm
    scope := match eq
      case EQUALITY() then eq.scope;
      case ARRAY_EQUALITY() then eq.scope;
      case CONNECT() then eq.scope;
      case FOR() then eq.scope;
      case IF() then eq.scope;
      case WHEN() then eq.scope;
      case ASSERT() then eq.scope;
      case TERMINATE() then eq.scope;
      case REINIT() then eq.scope;
      case NORETCALL() then eq.scope;
    end match;
  end scope;

  function info
    input Equation eq;
    output SourceInfo info = ElementSource.getInfo(source(eq));
  end info;

  partial function ApplyFn
    input Equation eq;
  end ApplyFn;

  function applyList
    input list<Equation> eql;
    input ApplyFn func;
  algorithm
    for eq in eql loop
      apply(eq, func);
    end for;
  end applyList;

  function apply
    input Equation eq;
    input ApplyFn func;
  algorithm
    () := match eq
      case FOR()
        algorithm
          for e in eq.body loop
            apply(e, func);
          end for;
        then
          ();

      case IF()
        algorithm
          for b in eq.branches loop
            () := match b
              case Branch.BRANCH()
                algorithm
                  for e in b.body loop
                    apply(e, func);
                  end for;
                then
                  ();
              else ();
            end match;
          end for;
        then
          ();

      case WHEN()
        algorithm
          for b in eq.branches loop
            () := match b
              case Branch.BRANCH()
                algorithm
                  for e in b.body loop
                    apply(e, func);
                  end for;
                then
                  ();
              else ();
            end match;
          end for;
        then
          ();

      else ();
    end match;

    func(eq);
  end apply;

  partial function MapFn
    input output Equation eq;
  end MapFn;

  function map
    input output Equation eq;
    input MapFn func;
  algorithm
    () := match eq
      case FOR()
        algorithm
          eq.body := list(map(e, func) for e in eq.body);
        then
          ();

      case IF()
        algorithm
          eq.branches := list(
            match b
              case Branch.BRANCH()
                algorithm
                  b.body := list(map(e, func) for e in b.body);
                then
                  b;
              else b;
            end match
          for b in eq.branches);
        then
          ();

      case WHEN()
        algorithm
          eq.branches := list(
            match b
              case Branch.BRANCH()
                algorithm
                  b.body := list(map(e, func) for e in b.body);
                then
                  b;
              else b;
            end match
          for b in eq.branches);
        then
          ();

      else ();
    end match;

    eq := func(eq);
  end map;

  function applyExpList
    input list<Equation> eq;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    for e in eq loop
      applyExp(e, func);
    end for;
  end applyExpList;

  function applyExp
    input Equation eq;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    () := match eq
      case Equation.EQUALITY()
        algorithm
          func(eq.lhs);
          func(eq.rhs);
        then
          ();

      case Equation.ARRAY_EQUALITY()
        algorithm
          func(eq.lhs);
          func(eq.rhs);
        then
          ();

      case Equation.CONNECT()
        algorithm
          func(eq.lhs);
          func(eq.rhs);
        then
          ();

      case Equation.FOR()
        algorithm
          applyExpList(eq.body, func);

          if isSome(eq.range) then
            func(Util.getOption(eq.range));
          end if;
        then
          ();

      case Equation.IF()
        algorithm
          for b in eq.branches loop
            () := match b
              case Branch.BRANCH()
                algorithm
                  func(b.condition);
                  applyExpList(b.body, func);
                then
                  ();

              else ();
            end match;
          end for;
        then
          ();

      case Equation.WHEN()
        algorithm
          for b in eq.branches loop
            () := match b
              case Branch.BRANCH()
                algorithm
                  func(b.condition);
                  applyExpList(b.body, func);
                then
                  ();

              else ();
            end match;
          end for;
        then
          ();

      case Equation.ASSERT()
        algorithm
          func(eq.condition);
          func(eq.message);
          func(eq.level);
        then
          ();

      case Equation.TERMINATE()
        algorithm
          func(eq.message);
        then
          ();

      case Equation.REINIT()
        algorithm
          func(eq.cref);
          func(eq.reinitExp);
        then
          ();

      case Equation.NORETCALL()
        algorithm
          func(eq.exp);
        then
          ();

      else ();
    end match;
  end applyExp;

  function applyExpShallow
    input Equation eq;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    () := match eq
      case Equation.EQUALITY()
        algorithm
          func(eq.lhs);
          func(eq.rhs);
        then
          ();

      case Equation.ARRAY_EQUALITY()
        algorithm
          func(eq.lhs);
          func(eq.rhs);
        then
          ();

      case Equation.CONNECT()
        algorithm
          func(eq.lhs);
          func(eq.rhs);
        then
          ();

      case Equation.FOR()
        algorithm
          if isSome(eq.range) then
            func(Util.getOption(eq.range));
          end if;
        then
          ();

      case Equation.IF()
        algorithm
          for b in eq.branches loop
            () := match b
              case Branch.BRANCH()
                algorithm
                  func(b.condition);
                then
                  ();

              else ();
            end match;
          end for;
        then
          ();

      case Equation.WHEN()
        algorithm
          for b in eq.branches loop
            () := match b
              case Branch.BRANCH()
                algorithm
                  func(b.condition);
                then
                  ();

              else ();
            end match;
          end for;
        then
          ();

      case Equation.ASSERT()
        algorithm
          func(eq.condition);
          func(eq.message);
          func(eq.level);
        then
          ();

      case Equation.TERMINATE()
        algorithm
          func(eq.message);
        then
          ();

      case Equation.REINIT()
        algorithm
          func(eq.cref);
          func(eq.reinitExp);
        then
          ();

      case Equation.NORETCALL()
        algorithm
          func(eq.exp);
        then
          ();

      else ();
    end match;
  end applyExpShallow;

  partial function MapExpFn
    input output Expression MapExpFn;
  end MapExpFn;

  function mapExpList
    input output list<Equation> eql;
    input MapExpFn func;
  algorithm
    eql := list(mapExp(eq, func) for eq in eql);
  end mapExpList;

  function mapExp
    input output Equation eq;
    input MapExpFn func;
  algorithm
    eq := match eq
      local
        Expression e1, e2, e3;
        ComponentRef cr1, cr2;

      case EQUALITY()
        algorithm
          e1 := func(eq.lhs);
          e2 := func(eq.rhs);
        then
          if referenceEq(e1, eq.lhs) and referenceEq(e2, eq.rhs)
            then eq else EQUALITY(e1, e2, eq.ty, eq.scope, eq.source);

      case ARRAY_EQUALITY()
        algorithm
          e1 := func(eq.lhs);
          e2 := func(eq.rhs);
        then
          if referenceEq(e1, eq.lhs) and referenceEq(e2, eq.rhs)
            then eq else ARRAY_EQUALITY(e1, e2, eq.ty, eq.scope, eq.source);

      //case CREF_EQUALITY()
      //  algorithm
      //    Expression.CREF(cref = cr1) := func(Expression.fromCref(eq.lhs));
      //    Expression.CREF(cref = cr2) := func(Expression.fromCref(eq.rhs));
      //  then
      //    Equation.CREF_EQUALITY(cr1, cr2, eq.source);

      case CONNECT()
        algorithm
          e1 := func(eq.lhs);
          e2 := func(eq.rhs);
        then
          if referenceEq(e1, eq.lhs) and referenceEq(e2, eq.rhs)
            then eq else CONNECT(e1, e2, eq.scope, eq.source);

      case FOR()
        algorithm
          eq.body := list(mapExp(e, func) for e in eq.body);
          eq.range := Util.applyOption(eq.range, func);
        then
          eq;

      case IF()
        algorithm
          eq.branches := list(Branch.mapExp(b, func) for b in eq.branches);
        then
          eq;

      case WHEN()
        algorithm
          eq.branches := list(Branch.mapExp(b, func) for b in eq.branches);
        then
          eq;

      case ASSERT()
        algorithm
          e1 := func(eq.condition);
          e2 := func(eq.message);
          e3 := func(eq.level);
        then
          if referenceEq(e1, eq.condition) and referenceEq(e2, eq.message) and
            referenceEq(e3, eq.level) then eq else ASSERT(e1, e2, e3, eq.scope, eq.source);

      case TERMINATE()
        algorithm
          e1 := func(eq.message);
        then
          if referenceEq(e1, eq.message) then eq else TERMINATE(e1, eq.scope, eq.source);

      case REINIT()
        algorithm
          e1 := func(eq.cref);
          e2 := func(eq.reinitExp);
        then
          if referenceEq(e1, eq.cref) and referenceEq(e2, eq.reinitExp) then
            eq else REINIT(e1, e2, eq.scope, eq.source);

      case NORETCALL()
        algorithm
          e1 := func(eq.exp);
        then
          if referenceEq(e1, eq.exp) then eq else NORETCALL(e1, eq.scope, eq.source);

      else eq;
    end match;
  end mapExp;

  function mapExpShallow
    input output Equation eq;
    input MapExpFn func;
  algorithm
    eq := match eq
      local
        Expression e1, e2, e3;

      case EQUALITY()
        algorithm
          e1 := func(eq.lhs);
          e2 := func(eq.rhs);
        then
          if referenceEq(e1, eq.lhs) and referenceEq(e2, eq.rhs)
            then eq else EQUALITY(e1, e2, eq.ty, eq.scope, eq.source);

      case ARRAY_EQUALITY()
        algorithm
          e1 := func(eq.lhs);
          e2 := func(eq.rhs);
        then
          if referenceEq(e1, eq.lhs) and referenceEq(e2, eq.rhs)
            then eq else ARRAY_EQUALITY(e1, e2, eq.ty, eq.scope, eq.source);

      case CONNECT()
        algorithm
          e1 := func(eq.lhs);
          e2 := func(eq.rhs);
        then
          if referenceEq(e1, eq.lhs) and referenceEq(e2, eq.rhs)
            then eq else CONNECT(e1, e2, eq.scope, eq.source);

      case FOR()
        algorithm
          eq.range := Util.applyOption(eq.range, func);
        then
          eq;

      case IF()
        algorithm
          eq.branches := list(Branch.mapExp(b, func, mapBody = false) for b in eq.branches);
        then
          eq;

      case WHEN()
        algorithm
          eq.branches := list(Branch.mapExp(b, func, mapBody = false) for b in eq.branches);
        then
          eq;

      case ASSERT()
        algorithm
          e1 := func(eq.condition);
          e2 := func(eq.message);
          e3 := func(eq.level);
        then
          if referenceEq(e1, eq.condition) and referenceEq(e2, eq.message) and
            referenceEq(e3, eq.level) then eq else ASSERT(e1, e2, e3, eq.scope, eq.source);

      case TERMINATE()
        algorithm
          e1 := func(eq.message);
        then
          if referenceEq(e1, eq.message) then eq else TERMINATE(e1, eq.scope, eq.source);

      case REINIT()
        algorithm
          e1 := func(eq.cref);
          e2 := func(eq.reinitExp);
        then
          if referenceEq(e1, eq.cref) and referenceEq(e2, eq.reinitExp) then
            eq else REINIT(e1, e2, eq.scope, eq.source);

      case NORETCALL()
        algorithm
          e1 := func(eq.exp);
        then
          if referenceEq(e1, eq.exp) then eq else NORETCALL(e1, eq.scope, eq.source);

      else eq;
    end match;
  end mapExpShallow;

  function foldExpList<ArgT>
    input list<Equation> eq;
    input FoldFunc func;
    input output ArgT arg;

    partial function FoldFunc
      input Expression exp;
      input output ArgT arg;
    end FoldFunc;
  algorithm
    for e in eq loop
      arg := foldExp(e, func, arg);
    end for;
  end foldExpList;

  function foldExp<ArgT>
    input Equation eq;
    input FoldFunc func;
    input output ArgT arg;

    partial function FoldFunc
      input Expression exp;
      input output ArgT arg;
    end FoldFunc;
  algorithm
    () := match eq
      case Equation.EQUALITY()
        algorithm
          arg := func(eq.lhs, arg);
          arg := func(eq.rhs, arg);
        then
          ();

      case Equation.ARRAY_EQUALITY()
        algorithm
          arg := func(eq.lhs, arg);
          arg := func(eq.rhs, arg);
        then
          ();

      case Equation.CONNECT()
        algorithm
          arg := func(eq.lhs, arg);
          arg := func(eq.rhs, arg);
        then
          ();

      case Equation.FOR()
        algorithm
          arg := foldExpList(eq.body, func, arg);

          if isSome(eq.range) then
            arg := func(Util.getOption(eq.range), arg);
          end if;
        then
          ();

      case Equation.IF()
        algorithm
          for b in eq.branches loop
            () := match b
              case Branch.BRANCH()
                algorithm
                  arg := func(b.condition, arg);
                  arg := foldExpList(b.body, func, arg);
                then
                  ();

              else ();
            end match;
          end for;
        then
          ();

      case Equation.WHEN()
        algorithm
          for b in eq.branches loop
            () := match b
              case Branch.BRANCH()
                algorithm
                  arg := func(b.condition, arg);
                  arg := foldExpList(b.body, func, arg);
                then
                  ();

              else ();
            end match;
          end for;
        then
          ();

      case Equation.ASSERT()
        algorithm
          arg := func(eq.condition, arg);
          arg := func(eq.message, arg);
          arg := func(eq.level, arg);
        then
          ();

      case Equation.TERMINATE()
        algorithm
          arg := func(eq.message, arg);
        then
          ();

      case Equation.REINIT()
        algorithm
          arg := func(eq.cref, arg);
          arg := func(eq.reinitExp, arg);
        then
          ();

      case Equation.NORETCALL()
        algorithm
          arg := func(eq.exp, arg);
        then
          ();

      else ();
    end match;
  end foldExp;

  function contains
    input Equation eq;
    input PredFn func;
    output Boolean res;

    partial function PredFn
      input Equation eq;
      output Boolean res;
    end PredFn;
  algorithm
    if func(eq) then
      res := true;
      return;
    end if;

    res := match eq
      case FOR() then containsList(eq.body, func);

      case IF()
        algorithm
          for b in eq.branches loop
            () := match b
              case Branch.BRANCH()
                algorithm
                  if containsList(b.body, func) then
                    res := true;
                    return;
                  end if;
                then
                  ();

              else ();
            end match;
          end for;
        then
          false;

      case WHEN()
        algorithm
          for b in eq.branches loop
            () := match b
              case Branch.BRANCH()
                algorithm
                  if containsList(b.body, func) then
                    res := true;
                    return;
                  end if;
                then
                  ();

              else ();
            end match;
          end for;
        then
          false;

      else false;
    end match;
  end contains;

  function containsList
    input list<Equation> eql;
    input PredFn func;
    output Boolean res;

    partial function PredFn
      input Equation eq;
      output Boolean res;
    end PredFn;
  algorithm
    for eq in eql loop
      if contains(eq, func) then
        res := true;
        return;
      end if;
    end for;

    res := false;
  end containsList;

  function containsExp
    input Equation eq;
    input Predicate fn;
    output Boolean res;

    partial function Predicate
      input Expression exp;
      output Boolean res;
    end Predicate;
  algorithm
    res := match eq
      case Equation.EQUALITY() then fn(eq.lhs) or fn(eq.rhs);
      case Equation.ARRAY_EQUALITY() then fn(eq.lhs) or fn(eq.rhs);
      case Equation.CONNECT() then fn(eq.lhs) or fn(eq.rhs);

      case Equation.FOR()
        algorithm
          res := if isSome(eq.range) then fn(Util.getOption(eq.range)) else false;

          if not res then
            res := containsExpList(eq.body, fn);
          end if;
        then
          res;

      case Equation.IF()
        algorithm
          res := false;
          for b in eq.branches loop
            () := match b
              case Branch.BRANCH()
                algorithm
                  if fn(b.condition) then
                    res := true;
                    return;
                  end if;

                  if containsExpList(b.body, fn) then
                    res := true;
                    return;
                  end if;
                then
                  ();

              else ();
            end match;
          end for;
        then
          res;

      case Equation.WHEN()
        algorithm
          res := false;
          for b in eq.branches loop
            () := match b
              case Branch.BRANCH()
                algorithm
                  if fn(b.condition) then
                    res := true;
                    return;
                  end if;

                  if containsExpList(b.body, fn) then
                    res := true;
                    return;
                  end if;
                then
                  ();

              else ();
            end match;
          end for;
        then
          res;

      case Equation.ASSERT() then fn(eq.condition) or fn(eq.message) or fn(eq.level);
      case Equation.TERMINATE() then fn(eq.message);
      case Equation.REINIT() then fn(eq.cref) or fn(eq.reinitExp);
      case Equation.NORETCALL() then fn(eq.exp);
      else false;
    end match;
  end containsExp;

  function containsExpList
    input list<Equation> eql;
    input Predicate func;
    output Boolean res;

    partial function Predicate
      input Expression eq;
      output Boolean res;
    end Predicate;
  algorithm
    for eq in eql loop
      if containsExp(eq, func) then
        res := true;
        return;
      end if;
    end for;

    res := false;
  end containsExpList;

  function replaceIteratorList
    input output list<Equation> eql;
    input InstNode iterator;
    input Expression value;
  algorithm
    eql := mapExpList(eql,
      function Expression.replaceIterator(iterator = iterator, iteratorValue = value));
  end replaceIteratorList;

  function isConnect
    "Checks if an equation is a connect equation."
    input Equation eq;
    output Boolean isConnect;
  algorithm
    isConnect := match eq
      case CONNECT() then true;
      else false;
    end match;
  end isConnect;

  function isConnection
    "Checks if an equation is a connect equation or a Connections.* call."
    input Equation eq;
    output Boolean res;
  protected
    Call call;
  algorithm
    res := match eq
      case Equation.CONNECT() then true;
      case Equation.NORETCALL(exp = Expression.CALL(call = call))
        then Call.isConnectionsOperator(call);
      else false;
    end match;
  end isConnection;

  function sizeOfList
    input list<Equation> eqs;
    output Integer size = 0;
  algorithm
    for eq in eqs loop
      size := size + sizeOf(eq);
    end for;
  end sizeOfList;

  function sizeOf
    input Equation eq;
    output Integer size;
  algorithm
    size := matchcontinue eq
      case EQUALITY() then Type.sizeOf(eq.ty);
      case ARRAY_EQUALITY() then Type.sizeOf(eq.ty);
      case CONNECT() then Type.sizeOf(Expression.typeOf(eq.lhs));
      case FOR()
        algorithm
          size := Type.sizeOf(Expression.typeOf(Util.getOption(eq.range)));
        then
          size * sizeOfList(eq.body);

      case IF() then Branch.sizeOf(listHead(eq.branches));
      case WHEN() then Branch.sizeOf(listHead(eq.branches));
      else 0;
    end matchcontinue;
  end sizeOf;

  function toString
    input Equation eq;
    input String indent = "";
    output String str;
  protected
    IOStream.IOStream s;
  algorithm
    s := IOStream.create(getInstanceName(), IOStream.IOStreamType.LIST());
    s := toStream(eq, indent, s);
    str := IOStream.string(s);
    IOStream.delete(s);
  end toString;

  function toStringList
    input list<Equation> eql;
    input String indent = "";
    output String str;
  protected
    IOStream.IOStream s;
  algorithm
    s := IOStream.create(getInstanceName(), IOStream.IOStreamType.LIST());
    s := toStreamList(eql, indent, s);
    str := IOStream.string(s);
    IOStream.delete(s);
  end toStringList;

  function toStream
    input Equation eq;
    input String indent;
    input output IOStream.IOStream s;
  algorithm
    s := IOStream.append(s, indent);

    s := match eq
      case EQUALITY()
        algorithm
          s := IOStream.append(s, Expression.toString(eq.lhs));
          s := IOStream.append(s, " = ");
          s := IOStream.append(s, Expression.toString(eq.rhs));
        then
          s;

      case ARRAY_EQUALITY()
        algorithm
          s := IOStream.append(s, Expression.toString(eq.lhs));
          s := IOStream.append(s, " = ");
          s := IOStream.append(s, Expression.toString(eq.rhs));
        then
          s;

      case CONNECT()
        algorithm
          s := IOStream.append(s, "connect(");
          s := IOStream.append(s, Expression.toString(eq.lhs));
          s := IOStream.append(s, ", ");
          s := IOStream.append(s, Expression.toString(eq.rhs));
          s := IOStream.append(s, ")");
        then
          s;

      case FOR()
        algorithm
          s := IOStream.append(s, "for ");
          s := IOStream.append(s, InstNode.name(eq.iterator));

          if isSome(eq.range) then
            s := IOStream.append(s, " in ");
            s := IOStream.append(s, Expression.toString(Util.getOption(eq.range)));
          end if;

          s := IOStream.append(s, " loop\n");
          s := toStreamList(eq.body, indent + "  ", s);
          s := IOStream.append(s, indent);
          s := IOStream.append(s, "end for");
        then
          s;

      case IF()
        algorithm
          s := IOStream.append(s, "if ");
          s := Branch.toStream(listHead(eq.branches), indent, s);

          for b in listRest(eq.branches) loop
            s := IOStream.append(s, indent);
            s := IOStream.append(s, "elseif ");
            s := Branch.toStream(b, indent, s);
          end for;

          s := IOStream.append(s, indent);
          s := IOStream.append(s, "end if");
        then
          s;

      case WHEN()
        algorithm
          s := IOStream.append(s, "when ");
          s := Branch.toStream(listHead(eq.branches), indent, s);

          for b in listRest(eq.branches) loop
            s := IOStream.append(s, indent);
            s := IOStream.append(s, "elsewhen ");
            s := Branch.toStream(b, indent, s);
          end for;

          s := IOStream.append(s, indent);
          s := IOStream.append(s, "end when");
        then
          s;

      case ASSERT()
        algorithm
          s := IOStream.append(s, "assert(");
          s := IOStream.append(s, Expression.toString(eq.condition));
          s := IOStream.append(s, ", ");
          s := IOStream.append(s, Expression.toString(eq.message));
          s := IOStream.append(s, ", ");
          s := IOStream.append(s, Expression.toString(eq.level));
          s := IOStream.append(s, ")");
        then
          s;

      case TERMINATE()
        algorithm
          s := IOStream.append(s, "terminate(");
          s := IOStream.append(s, Expression.toString(eq.message));
          s := IOStream.append(s, ")");
        then
          s;

      case REINIT()
        algorithm
          s := IOStream.append(s, "reinit(");
          s := IOStream.append(s, Expression.toString(eq.cref));
          s := IOStream.append(s, ", ");
          s := IOStream.append(s, Expression.toString(eq.reinitExp));
          s := IOStream.append(s, ")");
        then
          s;

      case NORETCALL()
        then IOStream.append(s, Expression.toString(eq.exp));

      else IOStream.append(s, "#UNKNOWN EQUATION#");
    end match;
  end toStream;

  function toStreamList
    input list<Equation> eql;
    input String indent;
    input output IOStream.IOStream s;
  protected
    Boolean prev_multi_line = false, multi_line;
    Boolean first = true;
  algorithm
    for eq in eql loop
      multi_line := isMultiLine(eq);

      // Improve human parsability by separating statements that spans multiple
      // lines (like if-equations) with newlines.
      if first then
        first := false;
      elseif prev_multi_line or multi_line then
        s := IOStream.append(s, "\n");
      end if;

      prev_multi_line := multi_line;

      s := toStream(eq, indent, s);
      s := IOStream.append(s, ";\n");
    end for;
  end toStreamList;

  function toFlatStream
    input Equation eq;
    input BaseModelica.OutputFormat format;
    input String indent;
    input output IOStream.IOStream s;
  algorithm
    s := IOStream.append(s, indent);

    s := match eq
      case EQUALITY()
        algorithm
          s := IOStream.append(s, Expression.toFlatString(eq.lhs, format));
          s := IOStream.append(s, " = ");
          s := IOStream.append(s, Expression.toFlatString(eq.rhs, format));
        then
          s;

      case ARRAY_EQUALITY()
        algorithm
          s := IOStream.append(s, Expression.toFlatString(eq.lhs, format));
          s := IOStream.append(s, " = ");
          s := IOStream.append(s, Expression.toFlatString(eq.rhs, format));
        then
          s;

      case CONNECT()
        algorithm
          s := IOStream.append(s, "connect(");
          s := IOStream.append(s, Expression.toFlatString(eq.lhs, format));
          s := IOStream.append(s, ", ");
          s := IOStream.append(s, Expression.toFlatString(eq.rhs, format));
          s := IOStream.append(s, ")");
        then
          s;

      case FOR()
        algorithm
          s := IOStream.append(s, "for ");
          s := IOStream.append(s, Util.makeQuotedIdentifier(InstNode.name(eq.iterator)));

          if isSome(eq.range) then
            s := IOStream.append(s, " in ");
            s := IOStream.append(s, Expression.toFlatString(Util.getOption(eq.range), format));
          end if;

          s := IOStream.append(s, " loop\n");
          s := toFlatStreamList(eq.body, format, indent + "  ", s);
          s := IOStream.append(s, indent);
          s := IOStream.append(s, "end for");
        then
          s;

      case IF()
        algorithm
          s := IOStream.append(s, "if ");
          s := Branch.toFlatStream(listHead(eq.branches), format, indent, s);

          for b in listRest(eq.branches) loop
            s := IOStream.append(s, indent);
            s := IOStream.append(s, "elseif ");
            s := Branch.toFlatStream(b, format, indent, s);
          end for;

          s := IOStream.append(s, indent);
          s := IOStream.append(s, "end if");
        then
          s;

      case WHEN()
        algorithm
          s := IOStream.append(s, "when ");
          s := Branch.toFlatStream(listHead(eq.branches), format, indent, s);

          for b in listRest(eq.branches) loop
            s := IOStream.append(s, indent);
            s := IOStream.append(s, "elsewhen ");
            s := Branch.toFlatStream(b, format, indent, s);
          end for;

          s := IOStream.append(s, indent);
          s := IOStream.append(s, "end when");
        then
          s;

      case ASSERT()
        algorithm
          s := IOStream.append(s, "assert(");
          s := IOStream.append(s, Expression.toFlatString(eq.condition, format));
          s := IOStream.append(s, ", ");
          s := IOStream.append(s, Expression.toFlatString(eq.message, format));
          s := IOStream.append(s, ", ");
          s := IOStream.append(s, Expression.toFlatString(eq.level, format));
          s := IOStream.append(s, ")");
        then
          s;

      case TERMINATE()
        algorithm
          s := IOStream.append(s, "terminate(");
          s := IOStream.append(s, Expression.toFlatString(eq.message, format));
          s := IOStream.append(s, ")");
        then
          s;

      case REINIT()
        algorithm
          s := IOStream.append(s, "reinit(");
          s := IOStream.append(s, Expression.toFlatString(eq.cref, format));
          s := IOStream.append(s, ", ");
          s := IOStream.append(s, Expression.toFlatString(eq.reinitExp, format));
          s := IOStream.append(s, ")");
        then
          s;

      case NORETCALL()
        then IOStream.append(s, Expression.toFlatString(eq.exp, format));

      else IOStream.append(s, "#UNKNOWN EQUATION#");
    end match;

    s := FlatModelicaUtil.appendElementSourceComment(source(eq), NFFlatModelicaUtil.ElementType.EQUATION, s);
  end toFlatStream;

  function toFlatStreamList
    input list<Equation> eql;
    input BaseModelica.OutputFormat format;
    input String indent;
    input output IOStream.IOStream s;
  protected
    Boolean prev_multi_line = false, multi_line;
    Boolean first = true;
  algorithm
    for eq in eql loop
      multi_line := isMultiLine(eq);

      // Improve human parsability by separating statements that spans multiple
      // lines (like if-equations) with newlines.
      if first then
        first := false;
      elseif prev_multi_line or multi_line then
        s := IOStream.append(s, "\n");
      end if;

      prev_multi_line := multi_line;

      s := toFlatStream(eq, format, indent, s);
      s := IOStream.append(s, ";\n");
    end for;
  end toFlatStreamList;

  function isMultiLine
    input Equation eq;
    output Boolean singleLine;
  algorithm
    singleLine := match eq
      case FOR() then true;
      case IF() then true;
      case WHEN() then true;
      else false;
    end match;
  end isMultiLine;

  function splitRecordEquations
    input list<Equation> equations;
    output list<Equation> outEquations = {};
  algorithm
    for eq in equations loop
      outEquations := splitRecordEquation(eq, outEquations);
    end for;

    outEquations := listReverseInPlace(outEquations);
  end splitRecordEquations;

  function splitRecordEquation
    "Splits an equation involving record expressions into separate equations for
     each record field."
    input Equation eq;
    input output list<Equation> equations;
  protected
    Expression lhs, rhs;
  algorithm
    equations := match eq
      case EQUALITY()
        guard Type.isRecord(Type.arrayElementType(eq.ty))
        algorithm
          eq.lhs := ExpandExp.expand(eq.lhs);
          eq.rhs := ExpandExp.expand(eq.rhs);

          for i in 1:Type.recordFieldCount(Type.arrayElementType(eq.ty)) loop
            lhs := Expression.nthRecordElement(i, eq.lhs);
            rhs := Expression.nthRecordElement(i, eq.rhs);
            equations := EQUALITY(lhs, rhs, Expression.typeOf(lhs), eq.scope, eq.source) :: equations;
          end for;
        then
          equations;

      case ARRAY_EQUALITY()
        guard Type.isRecord(Type.arrayElementType(eq.ty))
        then splitRecordEquation(EQUALITY(eq.lhs, eq.rhs, eq.ty, eq.scope, eq.source), equations);

      case FOR()
        algorithm
          eq.body := splitRecordEquations(eq.body);
        then
          eq :: equations;

      case IF()
        algorithm
          eq.branches := list(splitRecordEquationBranch(b) for b in eq.branches);
        then
          eq :: equations;

      case WHEN()
        algorithm
          eq.branches := list(splitRecordEquationBranch(b) for b in eq.branches);
        then
          eq :: equations;

      else eq :: equations;
    end match;
  end splitRecordEquation;

  function splitRecordEquationBranch
    input output Branch branch;
  algorithm
    () := match branch
      case BRANCH()
        algorithm
          branch.body := splitRecordEquations(branch.body);
        then
          ();

      else ();
    end match;
  end splitRecordEquationBranch;

annotation(__OpenModelica_Interface="frontend");
end NFEquation;
