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
  import Error;

protected
  import Equation = NFEquation;
  import NFComponent.Component;
  import Util;
  import ElementSource;
  import IOStream;

public
  uniontype Branch
    record BRANCH
      Expression condition;
      Variability conditionVar;
      list<Equation> body;
    end BRANCH;

    record INVALID_BRANCH
      Branch branch;
      list<Error.TotalMessage> errors;
    end INVALID_BRANCH;

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
        then
          if referenceEq(e1, eq.lhs) and referenceEq(e2, eq.rhs)
            then eq else CONNECT(e1, e2, eq.source);

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

  function isConnect
    input Equation eq;
    output Boolean isConnect;
  algorithm
    isConnect := match eq
      case CONNECT() then true;
      else false;
    end match;
  end isConnect;

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

      case CREF_EQUALITY()
        algorithm
          s := IOStream.append(s, ComponentRef.toString(eq.lhs));
          s := IOStream.append(s, " = ");
          s := IOStream.append(s, ComponentRef.toString(eq.rhs));
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
          s := IOStream.append(s, " = ");
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

annotation(__OpenModelica_Interface="frontend");
end NFEquation;
