/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated uniontype NSimGenericCall
"file:        NSimGenericCall.mo
 package:     NSimGenericCall
 description: This file contains the data types and functions for generic for loop calls.
"
public
  // self import
  import SimGenericCall = NSimGenericCall;

protected
  // NB import
  import NBEquation.{Equation, EquationPointer, Iterator, IfEquationBody, WhenEquationBody, WhenStatement};

  // NF import
  import ComponentRef = NFComponentRef;
  import ConvertDAE = NFConvertDAE;
  import DAE;
  import DAEUtil;
  import OldExpression = Expression;
  import Expression = NFExpression;
  import Operator = NFOperator;
  import SimplifyExp = NFSimplifyExp;
  import Statement = NFStatement;

  // old backend import
  import OldSimCode = SimCode;
  import OldBackendDAE = BackendDAE;

  import NSimCode.Identifier;

public
  record SINGLE_GENERIC_CALL
    Integer index;
    list<SimIterator> iters;
    Expression lhs;
    Expression rhs;
    Boolean resizable;
  end SINGLE_GENERIC_CALL;

  record IF_GENERIC_CALL
    Integer index;
    list<SimIterator> iters;
    list<SimBranch> branches;
    Boolean resizable;
  end IF_GENERIC_CALL;

  record WHEN_GENERIC_CALL
    Integer index;
    list<SimIterator> iters;
    list<SimBranch> branches;
    Boolean resizable;
  end WHEN_GENERIC_CALL;

  function mapShallow
    input output SimGenericCall call;
    input mapExp func;
    partial function mapExp
      input output Expression exp;
    end mapExp;
  algorithm
    call := match call
      case SINGLE_GENERIC_CALL() algorithm
        call.lhs := func(call.lhs);
        call.rhs := func(call.rhs);
      then call;
      case IF_GENERIC_CALL() algorithm
        call.branches := list(SimBranch.mapShallow(branch, func) for branch in call.branches);
      then call;
      case WHEN_GENERIC_CALL() algorithm
        call.branches := list(SimBranch.mapShallow(branch, func) for branch in call.branches);
      then call;
      else call;
    end match;
  end mapShallow;

  function toString
    input SimGenericCall call;
    output String str;
  algorithm
    str := match call
      case SINGLE_GENERIC_CALL() then "(" + intString(call.index) + ") [SNGL]: "
        + List.toString(call.iters, SimIterator.toString) + "\n\t"
        + Expression.toString(call.lhs) + " = " + Expression.toString(call.rhs);
      case IF_GENERIC_CALL() then "(" + intString(call.index) + ") [-IF-]: "
        + List.toString(call.iters, SimIterator.toString) + "\n\t"
        + List.toStringCustom(call.branches, SimBranch.toString, "", "", "\telse", "");
      case WHEN_GENERIC_CALL() then "(" + intString(call.index) + ") [WHEN]: "
        + List.toString(call.iters, SimIterator.toString) + "\n\t"
        + List.toStringCustom(call.branches, SimBranch.toString, "", "", "\telse", "");
      else "CALL_NOT_SUPPORTED";
    end match;
  end toString;

  function fromIdentifier
    input tuple<Identifier, Integer> ident_tpl;
    output SimGenericCall call;
  protected
    Pointer<Equation> eqn_ptr;
    Integer index;
    Boolean resizable;
    Equation body, eqn;
  algorithm
    (Identifier.IDENTIFIER(eqn = eqn_ptr, resizable = resizable), index) := ident_tpl;
    eqn := Pointer.access(eqn_ptr);
    call := match eqn
      local
        list<SimIterator> iters;

      case Equation.FOR_EQUATION(body = {body as Equation.IF_EQUATION()}) algorithm
        iters := SimIterator.fromIterator(eqn.iter);
      then IF_GENERIC_CALL(
          index     = index,
          iters     = iters,
          branches  = SimBranch.fromIfBody(body.body),
          resizable = resizable);

      case Equation.FOR_EQUATION(body = {body as Equation.WHEN_EQUATION()}) algorithm
        iters := SimIterator.fromIterator(eqn.iter);
      then WHEN_GENERIC_CALL(
          index     = index,
          iters     = iters,
          branches  = SimBranch.fromWhenBody(body.body),
          resizable = resizable);

      case Equation.FOR_EQUATION(body = {body}) algorithm
        iters := SimIterator.fromIterator(eqn.iter);
      then SINGLE_GENERIC_CALL(
          index     = index,
          iters     = iters,
          lhs       = Util.getOption(Equation.getLHS(body)),
          rhs       = Util.getOption(Equation.getRHS(body)),
          resizable = resizable);

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for incorrect equation: " + Equation.toString(eqn)});
      then fail();
    end match;
  end fromIdentifier;

  function convert
    input SimGenericCall call;
    output OldSimCode.SimGenericCall old_call;
  algorithm
    old_call := match call
      case SINGLE_GENERIC_CALL() then OldSimCode.SINGLE_GENERIC_CALL(
        index     = call.index,
        iters     = list(SimIterator.convert(iter) for iter in call.iters),
        lhs       = Expression.toDAE(call.lhs),
        rhs       = setRelationAsub(Expression.toDAE(call.rhs), relationAsub(call.iters)),
        resizable = call.resizable);
      case IF_GENERIC_CALL() then OldSimCode.IF_GENERIC_CALL(
        index     = call.index,
        iters     = list(SimIterator.convert(iter) for iter in call.iters),
        branches  = list(SimBranch.convert(branch) for branch in call.branches),
        resizable = call.resizable);
      case WHEN_GENERIC_CALL() then OldSimCode.WHEN_GENERIC_CALL(
        index     = call.index,
        iters     = list(SimIterator.convert(iter) for iter in call.iters),
        branches  = list(SimBranch.convert(branch) for branch in call.branches),
        resizable = call.resizable);
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for incorrect call: " + toString(call)});
      then fail();
     end match;
  end convert;

  function relationAsub
    "The relations of an event condition in a loop have one storedRelations[] slot per
    iteration. For a single iterator with a literal range the slot of the current iteration
    is index + (iterator - start)/step, see DAE.RELATION.optionExpisASUB."
    input list<SimIterator> iters;
    output Option<tuple<DAE.Exp, Integer, Integer>> asub;
  algorithm
    asub := match iters
      local
        ComponentRef name;
        Integer start, step;
      case {SimIterator.SIM_ITERATOR_RANGE(name = name, start = Expression.INTEGER(start), step = Expression.INTEGER(step))}
        then SOME((DAE.CREF(ComponentRef.toDAE(name), DAE.T_INTEGER_DEFAULT), start, step));
      else NONE();
    end match;
  end relationAsub;

  function setRelationAsub
    "sets the iteration offset of the relations with a storedRelations[] slot"
    input output DAE.Exp exp;
    input Option<tuple<DAE.Exp, Integer, Integer>> asub;
  algorithm
    if isSome(asub) then
      (exp, _) := OldExpression.traverseExpBottomUp(exp, setRelationAsubExp, asub);
    end if;
  end setRelationAsub;

  function setRelationAsubExp
    input output DAE.Exp exp;
    input output Option<tuple<DAE.Exp, Integer, Integer>> asub;
  algorithm
    exp := match exp
      case DAE.RELATION(optionExpisASUB = NONE()) guard(exp.index >= 0)
        then DAE.RELATION(exp.exp1, exp.operator, exp.exp2, exp.index, asub);
      else exp;
    end match;
  end setRelationAsubExp;

  function setRelationAsubStatements
    "sets the iteration offset of the relations in for-statements, see relationAsub"
    input output list<DAE.Statement> stmts;
    input Option<tuple<DAE.Exp, Integer, Integer>> asub = NONE();
  protected
    list<DAE.Statement> acc = {};
    Option<tuple<DAE.Exp, Integer, Integer>> for_asub;
  algorithm
    for stmt in stmts loop
      stmt := match stmt
        local
          DAE.Statement new_stmt;
        case new_stmt as DAE.STMT_FOR() algorithm
          for_asub := match new_stmt.range
            local
              Integer start, step;
            case DAE.RANGE(start = DAE.ICONST(start), step = NONE())
              then SOME((DAE.CREF(DAE.CREF_IDENT(new_stmt.iter, new_stmt.type_, {}), new_stmt.type_), start, 1));
            case DAE.RANGE(start = DAE.ICONST(start), step = SOME(DAE.ICONST(step)))
              then SOME((DAE.CREF(DAE.CREF_IDENT(new_stmt.iter, new_stmt.type_, {}), new_stmt.type_), start, step));
            else NONE();
          end match;
          new_stmt.statementLst := setRelationAsubStatements(new_stmt.statementLst, for_asub);
        then new_stmt;
        else algorithm
          if isSome(asub) then
            ({new_stmt}, _) := DAEUtil.traverseDAEStmts({stmt}, setRelationAsubStmtExp, asub);
          else
            new_stmt := stmt;
          end if;
        then new_stmt;
      end match;
      acc := stmt :: acc;
    end for;
    stmts := listReverse(acc);
  end setRelationAsubStatements;

  function setRelationAsubStmtExp
    input output DAE.Exp exp;
    input DAE.Statement stmt;
    input output Option<tuple<DAE.Exp, Integer, Integer>> asub;
  algorithm
    exp := setRelationAsub(exp, asub);
  end setRelationAsubStmtExp;

  uniontype SimIterator
    record SIM_ITERATOR_RANGE
      ComponentRef name;
      Expression start;
      Expression step;
      Expression stop;
      Expression size;
      list<DependentIterator> sub_iter;
    end SIM_ITERATOR_RANGE;

    record SIM_ITERATOR_LIST
      ComponentRef name;
      list<Integer> lst;
      Integer size;
      list<DependentIterator> sub_iter;
    end SIM_ITERATOR_LIST;

    function toString
      input SimIterator iter;
      output String str;
      function subIterString
        input list<DependentIterator> sub_iter;
        output String str = List.toStringCustom(list(Util.tuple21(tpl) for tpl in sub_iter), ComponentRef.toString, "", "(", ", ", ")", false);
      end subIterString;
    algorithm
      str := match iter
        case SIM_ITERATOR_RANGE() then "{" + ComponentRef.toString(iter.name) + " | start:" + Expression.toString(iter.start) + ", step:" + Expression.toString(iter.step) + ", stop:" + Expression.toString(iter.stop) + ", size: " + Expression.toString(iter.size) + "}" + subIterString(iter.sub_iter);
        case SIM_ITERATOR_LIST()  then "{" + ComponentRef.toString(iter.name) + " | list: " + List.toString(iter.lst, intString, List.Style.FLAT_CURLY_SHORT) + "}" + subIterString(iter.sub_iter);
      end match;
    end toString;

    function fromIterator
      "create sim iterator from backend iterator.
      Note: needs to reverse the order of iterators since it needs to be mapped inner first"
      input Iterator iter;
      output list<SimIterator> sim_iter = {};
    protected
      list<ComponentRef> names;
      list<Expression> ranges;
      list<Option<Iterator>> maps;
      ComponentRef name;
      Operator addOp, mulOp;
      Expression range, step, size;
      Option<Iterator> map;
      list<Integer> lst;
      list<DependentIterator> sub_iter;
    algorithm
      (names, ranges, maps) := Iterator.getFrames(iter);
      for tpl in List.zip3(names, ranges, maps) loop
        (name, range, map) := tpl;
        sim_iter := match range
          case Expression.RANGE() algorithm
            step      := Util.getOptionOrDefault(range.step, Expression.INTEGER(1));
            addOp     := Operator.makeAdd(Expression.typeOf(range.start));
            mulOp     := Operator.makeMul(Expression.typeOf(range.start));
            // build the size expression (stop-start)/step+1
            size      := Expression.MULTARY({range.stop}, {range.start}, addOp);
            size      := Expression.MULTARY({size}, {step}, mulOp);
            size      := Expression.MULTARY({size, Expression.INTEGER(1)}, {}, addOp);
            size      := SimplifyExp.simplify(size);
            sub_iter  := if isSome(map) then subIterators(Util.getOption(map)) else {};
          then SIM_ITERATOR_RANGE(name, range.start, step, range.stop, size, sub_iter) :: sim_iter;

          case Expression.ARRAY() guard(range.literal) algorithm
            lst       := list(Expression.integerValue(e) for e in range.elements);
            sub_iter  := if isSome(map) then subIterators(Util.getOption(map)) else {};
          then SIM_ITERATOR_LIST(name, lst, listLength(lst), sub_iter) :: sim_iter;

          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for incorrect iterator domain: " + Expression.toString(range)});
          then fail();
        end match;
      end for;
    end fromIterator;

    function subIterators
      "creates a list dependent sub iterators. the ranges can only be an array"
      input Iterator iter;
      output list<DependentIterator> sub_iter = {};
    protected
      list<ComponentRef> names;
      list<Expression> ranges;
      ComponentRef name;
      Expression range;
    algorithm
      // sub iterators are not allowed to have sub iterators themselves
      (names, ranges, _) := Iterator.getFrames(iter);
      for tpl in listReverse(List.zip(names, ranges)) loop
        (name, range) := tpl;
        sub_iter := match range
          case Expression.ARRAY() then (name, range.elements) :: sub_iter;
          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for incorrect iterator domain: " + Expression.toString(range)});
          then fail();
        end match;
      end for;
    end subIterators;

    function convert
      input SimIterator iter;
      output OldBackendDAE.SimIterator old_iter;
      function convertSubIterator
        input tuple<ComponentRef, array<Expression>> sub_iter;
        output tuple<DAE.ComponentRef, array<DAE.Exp>> old_sub_iter = (ComponentRef.toDAE(Util.tuple21(sub_iter)), listArray(list(Expression.toDAE(e) for e in Util.tuple22(sub_iter))));
      end convertSubIterator;
    algorithm
      old_iter := match iter
        case SIM_ITERATOR_RANGE() then OldBackendDAE.SIM_ITERATOR_RANGE(ComponentRef.toDAE(iter.name), Expression.toDAE(iter.start), Expression.toDAE(iter.step), Expression.toDAE(iter.stop), Expression.toDAE(iter.size), Expression.getInteger(iter.size, false), list(convertSubIterator(si) for si in iter.sub_iter));
        case SIM_ITERATOR_LIST()  then OldBackendDAE.SIM_ITERATOR_LIST(ComponentRef.toDAE(iter.name), iter.lst, iter.size, list(convertSubIterator(si) for si in iter.sub_iter));
      end match;
    end convert;
  end SimIterator;

  type DependentIterator = tuple<ComponentRef, array<Expression>> "represents a dependent sub iterator";

  uniontype SimBranch
    record SIM_BRANCH
      Expression condition;
      list<tuple<Expression, Expression>> body;
    end SIM_BRANCH;

    record SIM_BRANCH_STMT
      Expression condition;
      list<Statement> body;
    end SIM_BRANCH_STMT;

    function mapShallow
      input output SimBranch branch;
      input mapExp func;
    protected
      partial function mapExp
        input output Expression exp;
      end mapExp;
    algorithm
      branch := match branch
        case SIM_BRANCH() algorithm
          branch.body := list((func(Util.tuple21(tpl)), func(Util.tuple22(tpl))) for tpl in branch.body);
        then branch;
        case SIM_BRANCH_STMT() algorithm
          branch.body := list(Statement.mapExp(stmt, func) for stmt in branch.body);
        then branch;
        else branch;
      end match;
    end mapShallow;

    function toString
      input SimBranch branch;
      output String str;
    protected
      Expression lhs, rhs;
    algorithm
      str := match branch
        case SIM_BRANCH() algorithm
          str := if Expression.isEnd(branch.condition) then "\n" else "if " + Expression.toString(branch.condition) + " then\n";
          for tpl in branch.body loop
            (lhs, rhs) := tpl;
            str := str + "\t  " + Expression.toString(lhs) + " = " + Expression.toString(rhs) + "\n";
          end for;
        then str;
        case SIM_BRANCH_STMT() algorithm
          str := if Expression.isEnd(branch.condition) then "\n" else "when " + Expression.toString(branch.condition) + " then\n";
          str := str + List.toString(branch.body, function Statement.toString(indent = ""), List.Style.NEWLINE_TAB);
        then str;
        else "SIM BRANCH NOT KNOWN";
      end match;
    end toString;

    function fromIfBody
      input IfEquationBody if_body;
      output list<SimBranch> branches;
    protected
      list<tuple<Expression, Expression>> body = {};
      SimBranch branch;
    algorithm
      for eqn in listReverse(if_body.then_eqns) loop
        // ToDo: what if there are more complex things inside?
        body := (Util.getOption(Equation.getLHS(Pointer.access(eqn))), Util.getOption(Equation.getRHS(Pointer.access(eqn)))) :: body;
      end for;
      branch := SIM_BRANCH(if_body.condition, body);
      if isSome(if_body.else_if) then
        branches := branch :: fromIfBody(Util.getOption(if_body.else_if));
      else
        branches := {branch};
      end if;
    end fromIfBody;

    function fromWhenBody
      input WhenEquationBody when_body;
      output list<SimBranch> branches;
    protected
      SimBranch branch;
    algorithm
      branch := SIM_BRANCH_STMT(when_body.condition, list(WhenStatement.toStatement(stmt) for stmt in when_body.when_stmts));
      if isSome(when_body.else_when) then
        branches := branch :: fromWhenBody(Util.getOption(when_body.else_when));
      else
        branches := {branch};
      end if;
    end fromWhenBody;

    function convert
      input SimBranch branch;
      output OldSimCode.SimBranch old_branch;
    protected
      Option<DAE.Exp> old_condition;
      list<tuple<DAE.Exp, DAE.Exp>> old_body = {};
      Expression lhs, rhs;
    algorithm
      old_branch := match branch
        case SIM_BRANCH() algorithm
          old_condition := match branch.condition
            case Expression.END() then NONE();
            else SOME(Expression.toDAE(branch.condition));
          end match;

          for tpl in listReverse(branch.body) loop
            (lhs, rhs)  := tpl;
            old_body    := (Expression.toDAE(lhs), Expression.toDAE(rhs)) :: old_body;
          end for;

        then OldSimCode.SIM_BRANCH(
          condition = old_condition,
          body      = old_body);

        case SIM_BRANCH_STMT() algorithm
          old_condition := match branch.condition
            case Expression.END() then NONE();
            else SOME(Expression.toDAE(branch.condition));
          end match;

        then OldSimCode.SIM_BRANCH_STMT(
          condition = old_condition,
          body      = ConvertDAE.convertStatements(branch.body));

        else fail();
      end match;
    end convert;
  end SimBranch;

  annotation(__OpenModelica_Interface="nbackend");
end NSimGenericCall;
