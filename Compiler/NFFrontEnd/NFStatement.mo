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

encapsulated uniontype NFStatement
  import Absyn;
  import Type = NFType;
  import Expression = NFExpression;
  import NFInstNode.InstNode;
  import DAE;

protected
  import Statement = NFStatement;
  import ElementSource;
  import Util;
  import IOStream;

public
  record ASSIGNMENT
    Expression lhs "The asignee";
    Expression rhs "The expression";
    Type ty;
    DAE.ElementSource source;
  end ASSIGNMENT;

  record FUNCTION_ARRAY_INIT "Used to mark in which order local array variables in functions should be initialized"
    String name;
    Type ty;
    DAE.ElementSource source;
  end FUNCTION_ARRAY_INIT;

  record FOR
    InstNode iterator;
    Option<Expression> range;
    list<Statement> body "The body of the for loop.";
    DAE.ElementSource source;
  end FOR;

  record IF
    list<tuple<Expression, list<Statement>>> branches
      "List of branches, where each branch is a tuple of a condition and a body.";
    DAE.ElementSource source;
  end IF;

  record WHEN
    list<tuple<Expression, list<Statement>>> branches
      "List of branches, where each branch is a tuple of a condition and a body.";
    DAE.ElementSource source;
  end WHEN;

  record ASSERT
    Expression condition "The assert condition.";
    Expression message "The message to display if the assert fails.";
    Expression level;
    DAE.ElementSource source;
  end ASSERT;

  record TERMINATE
    Expression message "The message to display if the terminate triggers.";
    DAE.ElementSource source;
  end TERMINATE;

  record NORETCALL
    Expression exp;
    DAE.ElementSource source;
  end NORETCALL;

  record WHILE
    Expression condition;
    list<Statement> body;
    DAE.ElementSource source;
  end WHILE;

  record RETURN
    DAE.ElementSource source;
  end RETURN;

  record BREAK
    DAE.ElementSource source;
  end BREAK;

  record FAILURE
    list<Statement> body;
    DAE.ElementSource source;
  end FAILURE;

  function makeAssignment
    input Expression lhs;
    input Expression rhs;
    input Type ty;
    input DAE.ElementSource src;
    output Statement stmt;
  algorithm
    stmt := ASSIGNMENT(lhs, rhs, ty, src);
    annotation(__OpenModelica_EarlyInline=true);
  end makeAssignment;

  function makeIf
    input list<tuple<Expression, list<Statement>>> branches;
    input DAE.ElementSource src;
    output Statement stmt;
  algorithm
    stmt := IF(branches, src);
    annotation(__OpenModelica_EarlyInline=true);
  end makeIf;

  function source
    input Statement stmt;
    output DAE.ElementSource source;
  algorithm
    source := match stmt
      case ASSIGNMENT() then stmt.source;
      case FUNCTION_ARRAY_INIT() then stmt.source;
      case FOR() then stmt.source;
      case IF() then stmt.source;
      case WHEN() then stmt.source;
      case ASSERT() then stmt.source;
      case TERMINATE() then stmt.source;
      case NORETCALL() then stmt.source;
      case WHILE() then stmt.source;
      case RETURN() then stmt.source;
      case BREAK() then stmt.source;
      case FAILURE() then stmt.source;
    end match;
  end source;

  function info
    input Statement stmt;
    output SourceInfo info = ElementSource.getInfo(source(stmt));
  end info;

  partial function ApplyFn
    input Statement stmt;
  end ApplyFn;

  function apply
    input Statement stmt;
    input ApplyFn func;
  algorithm
    () := match stmt
      case FOR()
        algorithm
          for e in stmt.body loop
            apply(e, func);
          end for;
        then
          ();

      case IF()
        algorithm
          for b in stmt.branches loop
            for e in Util.tuple22(b) loop
              apply(e, func);
            end for;
          end for;
        then
          ();

      case WHEN()
        algorithm
          for b in stmt.branches loop
            for e in Util.tuple22(b) loop
              apply(e, func);
            end for;
          end for;
        then
          ();

      case WHILE()
        algorithm
          for e in stmt.body loop
            apply(e, func);
          end for;
        then
          ();

      case FAILURE()
        algorithm
          for e in stmt.body loop
            apply(e, func);
          end for;
        then
          ();

      else ();
    end match;

    func(stmt);
  end apply;

  function map
    input output Statement stmt;
    input MapFn func;

    partial function MapFn
      input output Statement stmt;
    end MapFn;
  algorithm
    () := match stmt
      case FOR()
        algorithm
          stmt.body := list(map(s, func) for s in stmt.body);
        then
          ();

      case IF()
        algorithm
          stmt.branches := list(
            (Util.tuple21(b),
             list(map(s, func) for s in Util.tuple22(b))) for b in stmt.branches);
        then
          ();

      case WHEN()
        algorithm
          stmt.branches := list(
            (Util.tuple21(b),
             list(map(s, func) for s in Util.tuple22(b))) for b in stmt.branches);
        then
          ();

      case WHILE()
        algorithm
          stmt.body := list(map(s, func) for s in stmt.body);
        then
          ();

      else ();
    end match;

    stmt := func(stmt);
  end map;

  function mapExpList
    input output list<Statement> stmtl;
    input MapFunc func;

    partial function MapFunc
      input output Expression exp;
    end MapFunc;
  algorithm
    stmtl := list(mapExp(s, func) for s in stmtl);
  end mapExpList;

  function mapExp
    input output Statement stmt;
    input MapFunc func;

    partial function MapFunc
      input output Expression exp;
    end MapFunc;
  algorithm
    stmt := match stmt
      local
        Expression e1, e2, e3;

      case ASSIGNMENT()
        algorithm
          e1 := func(stmt.lhs);
          e2 := func(stmt.rhs);
        then
          if referenceEq(e1, stmt.lhs) and referenceEq(e2, stmt.rhs) then
            stmt else ASSIGNMENT(e1, e2, stmt.ty, stmt.source);

      case FOR()
        algorithm
          stmt.body := mapExpList(stmt.body, func);
          stmt.range := Util.applyOption(stmt.range, func);
        then
          stmt;

      case IF()
        algorithm
          stmt.branches := list(
            (func(Util.tuple21(b)), mapExpList(Util.tuple22(b), func)) for b in stmt.branches);
        then
          stmt;

      case WHEN()
        algorithm
          stmt.branches := list(
            (func(Util.tuple21(b)), mapExpList(Util.tuple22(b), func)) for b in stmt.branches);
        then
          stmt;

      case ASSERT()
        algorithm
          e1 := func(stmt.condition);
          e2 := func(stmt.message);
          e3 := func(stmt.level);
        then
          if referenceEq(e1, stmt.condition) and referenceEq(e2, stmt.message) and
            referenceEq(e3, stmt.level) then stmt else ASSERT(e1, e2, e3, stmt.source);

      case TERMINATE()
        algorithm
          e1 := func(stmt.message);
        then
          if referenceEq(e1, stmt.message) then stmt else TERMINATE(e1, stmt.source);

      case NORETCALL()
        algorithm
          e1 := func(stmt.exp);
        then
          if referenceEq(e1, stmt.exp) then stmt else NORETCALL(e1, stmt.source);

      case WHILE()
        then WHILE(func(stmt.condition), mapExpList(stmt.body, func), stmt.source);

      else stmt;
    end match;
  end mapExp;

  function foldExpList<ArgT>
    input list<Statement> stmt;
    input FoldFunc func;
    input output ArgT arg;

    partial function FoldFunc
      input Expression exp;
      input output ArgT arg;
    end FoldFunc;
  algorithm
    for s in stmt loop
      arg := foldExp(s, func, arg);
    end for;
  end foldExpList;

  function foldExp<ArgT>
    input Statement stmt;
    input FoldFunc func;
    input output ArgT arg;

    partial function FoldFunc
      input Expression exp;
      input output ArgT arg;
    end FoldFunc;
  algorithm
    () := match stmt
      case Statement.ASSIGNMENT()
        algorithm
          arg := func(stmt.lhs, arg);
          arg := func(stmt.rhs, arg);
        then
          ();

      case Statement.FOR()
        algorithm
          arg := foldExpList(stmt.body, func, arg);

          if isSome(stmt.range) then
            arg := func(Util.getOption(stmt.range), arg);
          end if;
        then
          ();

      case Statement.IF()
        algorithm
          for b in stmt.branches loop
            arg := func(Util.tuple21(b), arg);
            arg := foldExpList(Util.tuple22(b), func, arg);
          end for;
        then
          ();

      case Statement.WHEN()
        algorithm
          for b in stmt.branches loop
            arg := func(Util.tuple21(b), arg);
            arg := foldExpList(Util.tuple22(b), func, arg);
          end for;
        then
          ();

      case Statement.ASSERT()
        algorithm
          arg := func(stmt.condition, arg);
          arg := func(stmt.message, arg);
          arg := func(stmt.level, arg);
        then
          ();

      case Statement.TERMINATE()
        algorithm
          arg := func(stmt.message, arg);
        then
          ();

      case Statement.NORETCALL()
        algorithm
          arg := func(stmt.exp, arg);
        then
          ();

      case Statement.WHILE()
        algorithm
          arg := func(stmt.condition, arg);
          arg := foldExpList(stmt.body, func, arg);
        then
          ();

      else ();
    end match;
  end foldExp;

  function toString
    input Statement stmt;
    input String indent = "";
    output String str;
  protected
    IOStream.IOStream s;
  algorithm
    s := IOStream.create(getInstanceName(), IOStream.IOStreamType.LIST());
    s := toStream(stmt, indent, s);
    str := IOStream.string(s);
    IOStream.delete(s);
  end toString;

  function toStringList
    input list<Statement> stmtl;
    input String indent = "";
    output String str;
  protected
    IOStream.IOStream s;
  algorithm
    s := IOStream.create(getInstanceName(), IOStream.IOStreamType.LIST());
    s := toStreamList(stmtl, indent, s);
    str := IOStream.string(s);
    IOStream.delete(s);
  end toStringList;

  function toStream
    input Statement stmt;
    input String indent;
    input output IOStream.IOStream s;
  protected
    String str;
  algorithm
    s := IOStream.append(s, indent);

    s := match stmt
      case ASSIGNMENT()
        algorithm
          s := IOStream.append(s, Expression.toString(stmt.lhs));
          s := IOStream.append(s, " := ");
          s := IOStream.append(s, Expression.toString(stmt.rhs));
        then
          s;

      case FUNCTION_ARRAY_INIT()
        algorithm
          s := IOStream.append(s, "array init");
          s := IOStream.append(s, stmt.name);
        then
          s;

      case FOR()
        algorithm
          s := IOStream.append(s, "for ");
          s := IOStream.append(s, InstNode.name(stmt.iterator));

          if isSome(stmt.range) then
            s := IOStream.append(s, " in ");
            s := IOStream.append(s, Expression.toString(Util.getOption(stmt.range)));
          end if;

          s := IOStream.append(s, " loop\n");
          s := toStreamList(stmt.body, indent + "  ", s);
          s := IOStream.append(s, indent);
          s := IOStream.append(s, "end for");
        then
          s;

      case IF()
        algorithm
          str := "if ";

          for b in stmt.branches loop
            s := IOStream.append(s, str);
            s := IOStream.append(s, Expression.toString(Util.tuple21(b)));
            s := IOStream.append(s, " then\n");
            s := toStreamList(Util.tuple22(b), indent + "  ", s);
            s := IOStream.append(s, indent);
            str := "elseif ";
          end for;

          s := IOStream.append(s, "end if");
        then
          s;

      case WHEN()
        algorithm
          str := "when ";

          for b in stmt.branches loop
            s := IOStream.append(s, str);
            s := IOStream.append(s, Expression.toString(Util.tuple21(b)));
            s := IOStream.append(s, " then\n");
            s := toStreamList(Util.tuple22(b), indent + "  ", s);
            s := IOStream.append(s, indent);
            str := "elsewhen ";
          end for;

          s := IOStream.append(s, "end when");
        then
          s;

      case ASSERT()
        algorithm
          s := IOStream.append(s, "assert(");
          s := IOStream.append(s, Expression.toString(stmt.condition));
          s := IOStream.append(s, ", ");
          s := IOStream.append(s, Expression.toString(stmt.message));
          s := IOStream.append(s, ", ");
          s := IOStream.append(s, Expression.toString(stmt.level));
          s := IOStream.append(s, ")");
        then
          s;

      case TERMINATE()
        algorithm
          s := IOStream.append(s, "terminate(");
          s := IOStream.append(s, Expression.toString(stmt.message));
          s := IOStream.append(s, ")");
        then
          s;

      case NORETCALL()
        then IOStream.append(s, Expression.toString(stmt.exp));

      case WHILE()
        algorithm
          s := IOStream.append(s, "while ");
          s := IOStream.append(s, Expression.toString(stmt.condition));
          s := IOStream.append(s, " then\n");
          s := toStreamList(stmt.body, indent + "  ", s);
          s := IOStream.append(s, indent);
          s := IOStream.append(s, "end while");
        then
          s;

      case RETURN() then IOStream.append(s, "return");
      case RETURN() then IOStream.append(s, "break");
      else IOStream.append(s, "#UNKNOWN STATEMENT#");
    end match;

  end toStream;

  function toStreamList
    input list<Statement> stmtl;
    input String indent;
    input output IOStream.IOStream s;
  protected
    Boolean prev_multi_line = false, multi_line;
    Boolean first = true;
  algorithm
    for stmt in stmtl loop
      multi_line := isMultiLine(stmt);

      // Improve human parsability by separating statements that spans multiple
      // lines (like if-statements) with newlines.
      if first then
        first := false;
      elseif prev_multi_line or multi_line then
        s := IOStream.append(s, "\n");
      end if;

      prev_multi_line := multi_line;

      s := toStream(stmt, indent, s);
      s := IOStream.append(s, ";\n");
    end for;
  end toStreamList;

  function isMultiLine
    input Statement stmt;
    output Boolean multiLine;
  algorithm
    multiLine := match stmt
      case FOR() then true;
      case IF() then true;
      case WHEN() then true;
      case WHILE() then true;
      else false;
    end match;
  end isMultiLine;

annotation(__OpenModelica_Interface="frontend");
end NFStatement;
