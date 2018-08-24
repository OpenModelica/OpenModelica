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
  import Absyn;
  import Expression = NFExpression;
  import Type = NFType;
  import NFInstNode.InstNode;
  import DAE;
  import ComponentRef = NFComponentRef;
  import NFPrefixes.Variability;

protected
  import Equation = NFEquation;
  import NFComponent.Component;
  import Util;
  import ElementSource;

public
  uniontype Branch
    record BRANCH
      Expression condition;
      Variability conditionVar;
      list<Equation> body;
    end BRANCH;

    function toString
      input Branch branch;
      output String str;
    algorithm
      str := Expression.toString(branch.condition) + " then\n" + toStringList(branch.body);
    end toString;
  end Branch;

  record EQUALITY
    Expression lhs "The left hand side expression.";
    Expression rhs "The right hand side expression.";
    Type ty;
    DAE.ElementSource source;
  end EQUALITY;

  record CREF_EQUALITY
    ComponentRef lhs;
    ComponentRef rhs;
    DAE.ElementSource source;
  end CREF_EQUALITY;

  record ARRAY_EQUALITY
    Expression lhs;
    Expression rhs;
    Type ty;
    DAE.ElementSource source;
  end ARRAY_EQUALITY;

  record CONNECT
    Expression lhs;
    Expression rhs;
    list<Equation> broken "equations which would replace a broken connect in the overconstrained connection graph";
    DAE.ElementSource source;
  end CONNECT;

  record FOR
    InstNode iterator;
    Option<Expression> range;
    list<Equation> body   "The body of the for loop.";
    DAE.ElementSource source;
  end FOR;

  record IF
    list<Branch> branches;
    DAE.ElementSource source;
  end IF;

  record WHEN
    list<Branch> branches;
    DAE.ElementSource source;
  end WHEN;

  record ASSERT
    Expression condition "The assert condition.";
    Expression message "The message to display if the assert fails.";
    Expression level "Error or warning";
    DAE.ElementSource source;
  end ASSERT;

  record TERMINATE
    Expression message "The message to display if the terminate triggers.";
    DAE.ElementSource source;
  end TERMINATE;

  record REINIT
    Expression cref "The variable to reinitialize.";
    Expression reinitExp "The new value of the variable.";
    DAE.ElementSource source;
  end REINIT;

  record NORETCALL
    Expression exp;
    DAE.ElementSource source;
  end NORETCALL;

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
    input DAE.ElementSource src;
    output Equation eq;
  algorithm
    eq := IF(branches, src);
    annotation(__OpenModelica_EarlyInline=true);
  end makeIf;

  function source
    input Equation eq;
    output DAE.ElementSource source;
  algorithm
    source := match eq
      case EQUALITY() then eq.source;
      case CREF_EQUALITY() then eq.source;
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
        list<Equation> eql;

      case EQUALITY()
        algorithm
          e1 := func(eq.lhs);
          e2 := func(eq.rhs);
        then
          if referenceEq(e1, eq.lhs) and referenceEq(e2, eq.rhs)
            then eq else EQUALITY(e1, e2, eq.ty, eq.source);

      case ARRAY_EQUALITY()
        algorithm
          e1 := func(eq.lhs);
          e2 := func(eq.rhs);
        then
          if referenceEq(e1, eq.lhs) and referenceEq(e2, eq.rhs)
            then eq else ARRAY_EQUALITY(e1, e2, eq.ty, eq.source);

      case CONNECT()
        algorithm
          e1 := func(eq.lhs);
          e2 := func(eq.rhs);
          eql := mapExpList(eq.broken, func);
        then
          if referenceEq(e1, eq.lhs) and referenceEq(e2, eq.rhs)
            then eq else CONNECT(e1, e2, eql, eq.source);

      case FOR()
        algorithm
          eq.body := list(mapExp(e, func) for e in eq.body);
          eq.range := Util.applyOption(eq.range, func);
        then
          eq;

      case IF()
        algorithm
          eq.branches := list(mapExpBranch(b, func) for b in eq.branches);
        then
          eq;

      case WHEN()
        algorithm
          eq.branches := list(mapExpBranch(b, func) for b in eq.branches);
        then
          eq;

      case ASSERT()
        algorithm
          e1 := func(eq.condition);
          e2 := func(eq.message);
          e3 := func(eq.level);
        then
          if referenceEq(e1, eq.condition) and referenceEq(e2, eq.message) and
            referenceEq(e3, eq.level) then eq else ASSERT(e1, e2, e3, eq.source);

      case TERMINATE()
        algorithm
          e1 := func(eq.message);
        then
          if referenceEq(e1, eq.message) then eq else TERMINATE(e1, eq.source);

      case REINIT()
        algorithm
          e1 := func(eq.cref);
          e2 := func(eq.reinitExp);
        then
          if referenceEq(e1, eq.cref) and referenceEq(e2, eq.reinitExp) then
            eq else REINIT(e1, e2, eq.source);

      case NORETCALL()
        algorithm
          e1 := func(eq.exp);
        then
          if referenceEq(e1, eq.exp) then eq else NORETCALL(e1, eq.source);

      else eq;
    end match;
  end mapExp;

  function mapExpBranch
    input output Branch branch;
    input MapExpFn func;
  protected
    Expression cond;
    list<Equation> eql;
  algorithm
    branch := match branch
      case Branch.BRANCH()
        algorithm
          cond := func(branch.condition);
          eql := list(mapExp(e, func) for e in branch.body);
        then
          Branch.BRANCH(cond, branch.conditionVar, eql);

      else branch;
    end match;
  end mapExpBranch;

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

  function toString
    input Equation eq;
    output String str;
  algorithm
    str := match eq
      local
        String s1, s2;

      case EQUALITY()
        then Expression.toString(eq.lhs) + " = " + Expression.toString(eq.rhs);

      case CREF_EQUALITY()
        then ComponentRef.toString(eq.lhs) + " = " + ComponentRef.toString(eq.rhs);

      case ARRAY_EQUALITY()
        then Expression.toString(eq.lhs) + " = " + Expression.toString(eq.rhs);

      case CONNECT()
        then "connect(" + Expression.toString(eq.lhs) + ", " + Expression.toString(eq.rhs) + ")";

      case FOR()
        algorithm
          s1 := if isSome(eq.range) then " in " + Expression.toString(Util.getOption(eq.range)) else "";
          s2 := toStringList(eq.body);
        then
          "for " + InstNode.name(eq.iterator) + s1 + " loop\n" + s2 + "end for";

      case IF()
        then "if " + Branch.toString(listHead(eq.branches)) +
             List.toString(listRest(eq.branches), Branch.toString, "", "elseif ", "\nelseif ", "", false) +
             "\nend if";

      case WHEN()
        then "when " + Branch.toString(listHead(eq.branches)) +
             List.toString(listRest(eq.branches), Branch.toString, "", "elsewhen ", "\nelsewhen ", "", false) +
             "\nend when";

      case ASSERT()
        then "assert(" + Expression.toString(eq.condition) + ", " +
             Expression.toString(eq.message) + ", " + Expression.toString(eq.level) + ")";

      case TERMINATE()
        then "terminate( " + Expression.toString(eq.message) + ")";

      case REINIT()
        then "reinit(" + Expression.toString(eq.cref) + ", " + Expression.toString(eq.reinitExp) + ")";

      case NORETCALL()
        then Expression.toString(eq.exp);

      else "#UNKNOWN EQUATION#";
    end match;
  end toString;

  function toStringList
    input list<Equation> eql;
    output String str;
  algorithm
    str := List.toString(eql, toString, "", "  ", "\n  ", "", false) + "\n";
  end toStringList;

annotation(__OpenModelica_Interface="frontend");
end NFEquation;
