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
  import NBEquation.{Equation, Iterator, IfEquationBody, WhenEquationBody, WhenStatement};

  // NF import
  import ComponentRef = NFComponentRef;
  import ConvertDAE = NFConvertDAE;
  import Expression = NFExpression;
  import Statement = NFStatement;

  // old backend import
  import OldSimCode = SimCode;
  import OldBackendDAE = BackendDAE;

public
  record SINGLE_GENERIC_CALL
    Integer index;
    list<SimIterator> iters;
    Expression lhs;
    Expression rhs;
  end SINGLE_GENERIC_CALL;

  record IF_GENERIC_CALL
    Integer index;
    list<SimIterator> iters;
    list<SimBranch> branches;
  end IF_GENERIC_CALL;

  record WHEN_GENERIC_CALL
    Integer index;
    list<SimIterator> iters;
    list<SimBranch> branches;
  end WHEN_GENERIC_CALL;

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
        + List.toString(call.branches, SimBranch.toString, "", "", "\telse", "");
      case WHEN_GENERIC_CALL() then "(" + intString(call.index) + ") [WHEN]: "
        + List.toString(call.iters, SimIterator.toString) + "\n\t"
        + List.toString(call.branches, SimBranch.toString, "", "", "\telse", "");
      else "CALL_NOT_SUPPORTED";
    end match;
  end toString;

  function fromEquation
    input tuple<Pointer<Equation>, Integer> eqn_tpl;
    output SimGenericCall call;
  protected
    Pointer<Equation> eqn_ptr;
    Integer index;
    Equation body, eqn;
  algorithm
    (eqn_ptr, index) := eqn_tpl;
    eqn := Pointer.access(eqn_ptr);
    call := match eqn

      case Equation.FOR_EQUATION(body = {body as Equation.IF_EQUATION()})
      then IF_GENERIC_CALL(
          index = index,
          iters = SimIterator.fromIterator(eqn.iter),
          branches = SimBranch.fromIfBody(body.body));

      case Equation.FOR_EQUATION(body = {body as Equation.WHEN_EQUATION()})
      then WHEN_GENERIC_CALL(
          index = index,
          iters = SimIterator.fromIterator(eqn.iter),
          branches = SimBranch.fromWhenBody(body.body));

      case Equation.FOR_EQUATION(body = {body})
      then SINGLE_GENERIC_CALL(
          index = index,
          iters = SimIterator.fromIterator(eqn.iter),
          lhs   = Equation.getLHS(body),
          rhs   = Equation.getRHS(body));
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for incorrect equation: " + Equation.toString(eqn)});
      then fail();
    end match;
  end fromEquation;

  function convert
    input SimGenericCall call;
    output OldSimCode.SimGenericCall old_call;
  algorithm
    old_call := match call
      case SINGLE_GENERIC_CALL() then OldSimCode.SINGLE_GENERIC_CALL(
        index = call.index,
        iters = list(SimIterator.convert(iter) for iter in call.iters),
        lhs   = Expression.toDAE(call.lhs),
        rhs   = Expression.toDAE(call.rhs));
      case IF_GENERIC_CALL() then OldSimCode.IF_GENERIC_CALL(
        index     = call.index,
        iters     = list(SimIterator.convert(iter) for iter in call.iters),
        branches  = list(SimBranch.convert(branch) for branch in call.branches));
      case WHEN_GENERIC_CALL() then OldSimCode.WHEN_GENERIC_CALL(
        index     = call.index,
        iters     = list(SimIterator.convert(iter) for iter in call.iters),
        branches  = list(SimBranch.convert(branch) for branch in call.branches));
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for incorrect call: " + toString(call)});
      then fail();
     end match;
  end convert;

  uniontype SimIterator
    record SIM_ITERATOR
      ComponentRef name;
      Integer start;
      Integer step;
      Integer size;
    end SIM_ITERATOR;

    function toString
      input SimIterator iter;
      output String str = "{" + ComponentRef.toString(iter.name) + " | start:" + intString(iter.start) + ", step:" + intString(iter.step) + ", size: " + intString(iter.size) + "}";
    end toString;

    function fromIterator
      input Iterator iter;
      output list<SimIterator> sim_iter = {};
    protected
      list<ComponentRef> names;
      list<Expression> ranges;
      ComponentRef name;
      Expression range;
      Integer start, step, stop;
    algorithm
      (names, ranges) := Iterator.getFrames(iter);
      for tpl in listReverse(List.zip(names, ranges)) loop
        (name, range) := tpl;
        (start, step, stop) := match range
          case Expression.RANGE() then (Expression.integerValue(range.start), Expression.integerValue(Util.getOptionOrDefault(range.step, Expression.INTEGER(1))), Expression.integerValue(range.stop));
          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for incorrect range: " + Expression.toString(range)});
          then fail();
        end match;
        sim_iter := SIM_ITERATOR(name, start, step, intDiv(stop-start,step)+1) :: sim_iter;
      end for;
    end fromIterator;

    function convert
      input SimIterator iter;
      output OldBackendDAE.SimIterator old_iter = OldBackendDAE.SIM_ITERATOR(ComponentRef.toDAE(iter.name), iter.start, iter.step, iter.size);
    end convert;
  end SimIterator;

  uniontype SimBranch
    record SIM_BRANCH
      Expression condition;
      list<tuple<Expression, Expression>> body;
    end SIM_BRANCH;

    record SIM_BRANCH_STMT
      Expression condition;
      list<Statement> body;
    end SIM_BRANCH_STMT;

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
          str := str + List.toString(branch.body, function Statement.toString(indent = ""), "\t  ", "\t  ", "\n", "");
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
        body := (Equation.getLHS(Pointer.access(eqn)), Equation.getRHS(Pointer.access(eqn))) :: body;
      end for;
      branch := SIM_BRANCH(if_body.condition, body) ;
      if Util.isSome(if_body.else_if) then
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
      if Util.isSome(when_body.else_when) then
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

  annotation(__OpenModelica_Interface="backend");
end NSimGenericCall;
