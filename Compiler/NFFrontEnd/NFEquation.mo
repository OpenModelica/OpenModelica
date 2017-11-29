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
  import DAE.ElementSource;
  import ComponentRef = NFComponentRef;

protected
  import Equation = NFEquation;

public
  record EQUALITY
    Expression lhs "The left hand side expression.";
    Expression rhs "The right hand side expression.";
    Type ty;
    SourceInfo info;
  end EQUALITY;

  record CREF_EQUALITY
    ComponentRef lhs;
    ComponentRef rhs;
    ElementSource source;
  end CREF_EQUALITY;

  record ARRAY_EQUALITY
    Expression lhs;
    Expression rhs;
    Type ty;
    SourceInfo info;
  end ARRAY_EQUALITY;

  record CONNECT
    Expression lhs;
    Expression rhs;
    SourceInfo info;
  end CONNECT;

  record FOR
    InstNode iterator;
    list<Equation> body   "The body of the for loop.";
    SourceInfo info;
  end FOR;

  record IF
    list<tuple<Expression, list<Equation>>> branches
      "List of branches, where each branch is a tuple of a condition and a body.";
    SourceInfo info;
  end IF;

  record WHEN
    list<tuple<Expression, list<Equation>>> branches
      "List of branches, where each branch is a tuple of a condition and a body.";
    SourceInfo info;
  end WHEN;

  record ASSERT
    Expression condition "The assert condition.";
    Expression message "The message to display if the assert fails.";
    Expression level "Error or warning";
    SourceInfo info;
  end ASSERT;

  record TERMINATE
    Expression message "The message to display if the terminate triggers.";
    SourceInfo info;
  end TERMINATE;

  record REINIT
    Expression cref "The variable to reinitialize.";
    Expression reinitExp "The new value of the variable.";
    SourceInfo info;
  end REINIT;

  record NORETCALL
    Expression exp;
    SourceInfo info;
  end NORETCALL;

  function mapExpList
    input output list<Equation> eql;
    input MapFn func;

    partial function MapFn
      input output Expression exp;
    end MapFn;
  algorithm
    eql := list(mapExp(eq, func) for eq in eql);
  end mapExpList;

  function mapExp
    input output Equation eq;
    input MapFn func;

    partial function MapFn
      input output Expression exp;
    end MapFn;
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
            then eq else EQUALITY(e1, e2, eq.ty, eq.info);

      case ARRAY_EQUALITY()
        algorithm
          e1 := func(eq.lhs);
          e2 := func(eq.rhs);
        then
          if referenceEq(e1, eq.lhs) and referenceEq(e2, eq.rhs)
            then eq else ARRAY_EQUALITY(e1, e2, eq.ty, eq.info);

      case CONNECT()
        algorithm
          e1 := func(eq.lhs);
          e2 := func(eq.rhs);
        then
          if referenceEq(e1, eq.lhs) and referenceEq(e2, eq.rhs)
            then eq else CONNECT(e1, e2, eq.info);

      case FOR()
        algorithm
          eq.body := list(mapExp(e, func) for e in eq.body);
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
            referenceEq(e3, eq.level) then eq else ASSERT(e1, e2, e3, eq.info);

      case TERMINATE()
        algorithm
          e1 := func(eq.message);
        then
          if referenceEq(e1, eq.message) then eq else TERMINATE(e1, eq.info);

      case REINIT()
        algorithm
          e1 := func(eq.cref);
          e2 := func(eq.reinitExp);
        then
          if referenceEq(e1, eq.cref) and referenceEq(e2, eq.reinitExp) then
            eq else REINIT(e1, e2, eq.info);

      case NORETCALL()
        algorithm
          e1 := func(eq.exp);
        then
          if referenceEq(e1, eq.exp) then eq else NORETCALL(e1, eq.info);

      else eq;
    end match;
  end mapExp;

  function mapExpBranch
    input output tuple<Expression, list<Equation>> branch;
    input MapFn func;

    partial function MapFn
      input output Expression exp;
    end MapFn;
  protected
    Expression cond;
    list<Equation> eql;
  algorithm
    (cond, eql) := branch;
    cond := func(cond);
    eql := list(mapExp(e, func) for e in eql);
    branch := (cond, eql);
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
        then
          ();

      case Equation.IF()
        algorithm
          for b in eq.branches loop
            arg := func(Util.tuple21(b), arg);
            arg := foldExpList(Util.tuple22(b), func, arg);
          end for;
        then
          ();

      case Equation.WHEN()
        algorithm
          for b in eq.branches loop
            arg := func(Util.tuple21(b), arg);
            arg := foldExpList(Util.tuple22(b), func, arg);
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

annotation(__OpenModelica_Interface="frontend");
end NFEquation;
