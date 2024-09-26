/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated uniontype NFAlgorithm
  // OF imports
  import DAE;

  // NF imports
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import NFInstNode.InstNode;
  import Statement = NFStatement;
  import Type = NFType;

  // Util imports
  import Error;
  import Flags;
  import UnorderedSet;

protected
  import Algorithm = NFAlgorithm;

public
  record ALGORITHM
    list<Statement> statements;
    list<ComponentRef> inputs;
    list<ComponentRef> outputs;
    InstNode scope;
    DAE.ElementSource source;
  end ALGORITHM;

  partial function ApplyFn
    input Statement alg;
  end ApplyFn;

  function applyList
    input list<Algorithm> algs;
    input ApplyFn func;
  algorithm
    for alg in algs loop
      for s in alg.statements loop
        Statement.apply(s, func);
      end for;
    end for;
  end applyList;

  function apply
    input Algorithm alg;
    input ApplyFn func;
  algorithm
    for s in alg.statements loop
      Statement.apply(s, func);
    end for;
  end apply;

  function applyExp
    input Algorithm alg;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    for s in alg.statements loop
      Statement.applyExp(s, func);
    end for;
  end applyExp;

  function applyExpList
    input list<Algorithm> algs;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    for alg in algs loop
      applyExp(alg, func);
    end for;
  end applyExpList;

  function mapExp
    input output Algorithm alg;
    input MapFunc func;

    partial function MapFunc
      input output Expression exp;
    end MapFunc;
  algorithm
    alg.statements := Statement.mapExpList(alg.statements, func);
  end mapExp;

  function mapExpList
    input output list<Algorithm> algs;
    input MapFunc func;

    partial function MapFunc
      input output Expression exp;
    end MapFunc;
  algorithm
    algs := list(mapExp(alg, func) for alg in algs);
  end mapExpList;

  function foldExp<ArgT>
    input Algorithm alg;
    input FoldFunc func;
    input output ArgT arg;

    partial function FoldFunc
      input Expression exp;
      input output ArgT arg;
    end FoldFunc;
  algorithm
    for s in alg.statements loop
      arg := Statement.foldExp(s, func, arg);
    end for;
  end foldExp;

  function foldExpList<ArgT>
    input list<Algorithm> algs;
    input FoldFunc func;
    input output ArgT arg;

    partial function FoldFunc
      input Expression exp;
      input output ArgT arg;
    end FoldFunc;
  algorithm
    for alg in algs loop
      arg := foldExp(alg, func, arg);
    end for;
  end foldExpList;

  function toString
    input Algorithm alg;
    input String indent = "";
    output String str;
  algorithm
    str := Statement.toStringList(alg.statements, indent);
  end toString;

  function setInputsOutputs
    input output Algorithm alg;
  protected
    list<ComponentRef> inputs, outputs;
  algorithm
    (inputs, outputs) := getInputsOutputs(alg.statements);
    alg.inputs := inputs;
    alg.outputs := outputs;
  end setInputsOutputs;

  function getInputsOutputs "This function finds the inputs and outputs of an
    algorithm. Inputs are values that are reffered on the right hand side of any
    statement in the algorithm and an output is a variables belonging to the
    variables that are assigned a value in the algorithm. If a variable is an
    input and an output it will be treated as an output."
    input list<Statement> statements;
    output list<ComponentRef> inputs_lst;
    output list<ComponentRef> outputs_lst;
  protected
    UnorderedSet<ComponentRef> inputs_set  = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    UnorderedSet<ComponentRef> outputs_set = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
  algorithm
    try
      for statement in statements loop
        statementInputsOutputs(statement, inputs_set, outputs_set);
      end for;
      inputs_lst  := UnorderedSet.toList(inputs_set);
      outputs_lst := UnorderedSet.toList(outputs_set);
    else
      Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
    end try;
  end getInputsOutputs;

  function isEqual
    input Algorithm alg1;
    input Algorithm alg2;
    output Boolean b;
  algorithm
    b := List.isEqualOnTrue(alg1.inputs, alg2.inputs, ComponentRef.isEqual)
      and List.isEqualOnTrue(alg1.outputs, alg2.outputs, ComponentRef.isEqual)
      and List.isEqualOnTrue(alg1.statements, alg2.statements, Statement.isEqual);
  end isEqual;

protected
  function statementInputsOutputs "Helper for getInputsOutputs.
    Traverse statements and find inputs and outputs"
    input Statement statement;
    input UnorderedSet<ComponentRef> inputs_set;
    input UnorderedSet<ComponentRef> outputs_set;
  algorithm
    () := match statement
      local
        Expression lhs, rhs;
        list<Expression> elements;
        list<Statement> stmts;
        list<tuple<Expression, list<Statement>>> branches;

      // a := expr;
      case Statement.ASSIGNMENT(lhs = lhs as Expression.CREF(), rhs = rhs) algorithm
        // TODO extend for array, matrix?
        // TODO has to be scalarized if scalarize
        Expression.apply(rhs, function expressionInputs(inputs_set = inputs_set, outputs_set = outputs_set));
        expressionOutput(lhs, inputs_set, outputs_set);
      then ();

      // (a, b, c, ...) := expr;
      case Statement.ASSIGNMENT(lhs = Expression.TUPLE(elements = elements), rhs = rhs) algorithm
        // TODO extend for array, matrix?
        Expression.apply(rhs, function expressionInputs(inputs_set = inputs_set, outputs_set = outputs_set));
        for exp in elements loop
          expressionOutput(exp, inputs_set, outputs_set);
        end for;
      then ();

      // ToDo: Statement.ASSIGNMENT(lhs=lhs as Expression.RECORD_ELEMENT())

      case Statement.FOR(body = stmts) algorithm
        for stmt in stmts loop
          statementInputsOutputs(stmt, inputs_set, outputs_set);
        end for;
      then ();

      case Statement.IF(branches = branches) algorithm
        for branch in branches loop
          (_, stmts) := branch;
          // TODO warn about using unassigned outputs in condition -> const eval?
          for stmt in stmts loop
            statementInputsOutputs(stmt, inputs_set, outputs_set);
          end for;
        end for;
        // TODO input in one branch can't be output in another etc...
      then ();

      case Statement.WHEN(branches = branches) algorithm
        for branch in branches loop
          (_, stmts) := branch;
          // what about using unassigned outputs in condition?
          for stmt in stmts loop
            statementInputsOutputs(stmt, inputs_set, outputs_set);
          end for;
        end for;
        // TODO input in one branch can't be output in another etc...
      then ();

      case Statement.WHILE(body = stmts) algorithm
        // TODO warn about using unassigned outputs in condition -> const eval?
        for stmt in stmts loop
          statementInputsOutputs(stmt, inputs_set, outputs_set);
        end for;
      then ();

      case Statement.ASSERT() then ();
      case Statement.TERMINATE() then ();
      case Statement.REINIT() then ();
      case Statement.NORETCALL() then ();
      case Statement.RETURN() then ();
      case Statement.BREAK() then ();
      case Statement.FAILURE() then ();

      case Statement.FUNCTION_ARRAY_INIT()
        algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed due to wrong Statement Type: FUNCTION_ARRAY_INIT."});
      then fail();

      else
        algorithm
          if Flags.isSet(Flags.FAILTRACE) then
            Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed for " + Statement.toString(statement)});
          end if;
      then fail();

    end match;
  end statementInputsOutputs;

  function expressionInputs
    "finds all inputs on the rhs of a statement"
    input Expression exp;
    input UnorderedSet<ComponentRef> inputs_set;
    input UnorderedSet<ComponentRef> outputs_set "outputs from previous statements";
  algorithm
    () := match exp
      local
        ComponentRef cr;
        Type ty;

      // Skip time
      case Expression.CREF(cref = cr) guard(ComponentRef.isTime(cr)) then ();

      // Skip iterators
      case Expression.CREF(cref = cr) guard ComponentRef.isIterator(cr) then ();

      // Skip external Objects
      case Expression.CREF(ty = ty) guard(Type.isExternalObject(ty)) then ();

      case Expression.CREF(cref = cr) algorithm
        // since outputs get stripped, also strip inputs
        // otherwise uninitialized output detection doesn't work properly
        cr := ComponentRef.stripSubscriptsAll(cr);
        if not UnorderedSet.contains(cr, outputs_set) then
          UnorderedSet.add(cr, inputs_set);
        end if;
      then ();

      else ();
    end match;
  end expressionInputs;

  function expressionOutput "author: Frenkel TUD 2012-06
    detects outputs by looking at crefs in the lhs of a statement"
    input Expression exp "should be a cref, otherwise fail";
    input UnorderedSet<ComponentRef> inputs_set;
    input UnorderedSet<ComponentRef> outputs_set;
  algorithm
    () := match exp
      local
        ComponentRef cr;
        Type ty;

      // Skip wild
      case Expression.CREF(cref = ComponentRef.WILD()) then ();

      // time is not an output in algorithms
      case Expression.CREF(cref = cr) guard(ComponentRef.isTime(cr)) algorithm
        Error.addMessage(Error.COMPILER_ERROR, {"Trying to assign to time."});
      then fail();

      // Iterators are not outputs in algorithms
      case Expression.CREF(cref = cr) guard ComponentRef.isIterator(cr) algorithm
        Error.addMessage(Error.COMPILER_ERROR, {"Trying to assign to iterator " + ComponentRef.toString(cr) + "."});
      then fail();

      // Skip external Objects
      // or error?
      case Expression.CREF(ty = ty) guard(Type.isExternalObject(ty)) then ();

      case Expression.CREF(cref = cr) algorithm
        /* mahge:
        Modelica spec 3.3 rev 11.1.2
          "If at least one element of an array appears on the left hand side of
           the assignment operator, then the complete array is initialized in
           this algorithm section"
        So we strip the all subs except for model subs and send the whole array to expansion. i.e. we consider the whole array as modified.
        */
        cr := ComponentRef.stripSubscriptsAll(cr);
        if UnorderedSet.remove(cr, inputs_set) then
          if Flags.isSet(Flags.FAILTRACE) then
            Error.addMessage(Error.COMPILER_WARNING, {"Using output variable in RHS before it is assigned (former occurences will be set to initial value): " + Expression.toString(exp)});
          end if;
          // TODO add to outputs that need to be initialized / partially replaced by initial value?
        end if;
        UnorderedSet.add(cr, outputs_set);
      then ();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed due to wrong expression type in LHS of algorithm statement: " + Expression.toString(exp)});
      then fail();
    end match;
  end expressionOutput;

  annotation(__OpenModelica_Interface="frontend");
end NFAlgorithm;
