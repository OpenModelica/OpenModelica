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
  import HashSet = NFHashSet;
  import Statement = NFStatement;
  import Type = NFType;

  // Util imports
  import Error;
  import Flags;

protected
  import Algorithm = NFAlgorithm;

public
  record ALGORITHM
    list<Statement> statements;
    list<ComponentRef> inputs;
    list<ComponentRef> outputs;
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

  function getInputsOutputs "This function finds the inputs and outputs of an
    algorithm. Inputs are values that are reffered on the right hand side of any
    statement in the algorithm and an output is a variables belonging to the
    variables that are assigned a value in the algorithm. If a variable is an
    input and an output it will be treated as an output."
    input list<Statement> statements "statements of the algorithm";
    output list<ComponentRef> inputs_lst;
    output list<ComponentRef> outputs_lst;
  protected
    HashSet.HashSet inputs_hs = HashSet.emptyHashSet();
    HashSet.HashSet outputs_hs = HashSet.emptyHashSet();
  algorithm
    try
      (inputs_hs, outputs_hs) := List.fold(statements, function statementInputsOutputs(), (inputs_hs, outputs_hs));
      inputs_lst := BaseHashSet.hashSetList(inputs_hs);
      outputs_lst := BaseHashSet.hashSetList(outputs_hs);
    else
      Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
    end try;
  end getInputsOutputs;

protected
  function statementInputsOutputs "Helper for getInputsOutputs.
    Traverse statements and find inputs and outputs"
    input Statement statement;
    input output tuple<HashSet.HashSet, HashSet.HashSet> hashSets "inputs and outputs";
  algorithm
    hashSets := match statement
      local
        HashSet.HashSet inputs_hs, outputs_hs;
        Expression lhs, rhs;
        list<Expression> elements;
        list<Statement> stmts;
        list<tuple<Expression, list<Statement>>> branches;

      // a := expr;
      case Statement.ASSIGNMENT(lhs = lhs as Expression.CREF(), rhs = rhs)
        algorithm
          (inputs_hs, outputs_hs) := hashSets;
          // TODO extend for array, matrix?
          // TODO has to be scalarized if scalarize
          inputs_hs := Expression.fold(rhs, function expressionInputs(outputs_hs = outputs_hs), inputs_hs);
      then expressionOutput(lhs, (inputs_hs, outputs_hs));

      // (a, b, c, ...) := expr;
      case Statement.ASSIGNMENT(lhs = Expression.TUPLE(elements = elements), rhs = rhs)
        algorithm
          (inputs_hs, outputs_hs) := hashSets;
          // TODO extend for array, matrix?
          inputs_hs := Expression.fold(rhs, function expressionInputs(outputs_hs = outputs_hs), inputs_hs);
          hashSets := (inputs_hs, outputs_hs);
          for exp in elements loop
            hashSets := expressionOutput(exp, hashSets);
          end for;
      then hashSets;

      // ToDo: Statement.ASSIGNMENT(lhs=lhs as Expression.RECORD_ELEMENT())

      case Statement.FOR(body = stmts)
        algorithm
          // add iterator to inputs?
          for stmt in stmts loop
            hashSets := statementInputsOutputs(stmt, hashSets);
          end for;
          // remove iterator from inputs?
      then hashSets;

      case Statement.IF(branches = branches)
        algorithm
          for branch in branches loop
            (_, stmts) := branch;
            // what about using unassigned outputs in condition?
            for stmt in stmts loop
              hashSets := statementInputsOutputs(stmt, hashSets);
            end for;
          end for;
          // TODO input in one branch can't be output in another etc...
      then hashSets;

      case Statement.WHEN(branches = branches)
        algorithm
          for branch in branches loop
            (_, stmts) := branch;
            // what about using unassigned outputs in condition?
            for stmt in stmts loop
              hashSets := statementInputsOutputs(stmt, hashSets);
            end for;
          end for;
          // TODO input in one branch can't be output in another etc...
      then hashSets;

      case Statement.WHILE(body = stmts)
        algorithm
          // what about using unassigned outputs in condition?
          for stmt in stmts loop
            hashSets := statementInputsOutputs(stmt, hashSets);
          end for;
      then hashSets;

      case Statement.ASSERT() then hashSets;
      case Statement.TERMINATE() then hashSets;
      case Statement.NORETCALL() then hashSets;
      case Statement.RETURN() then hashSets;
      case Statement.BREAK() then hashSets;
      case Statement.FAILURE() then hashSets; // does this need to do sth ?

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
    input HashSet.HashSet outputs_hs "outputs from previous statements";
    input output HashSet.HashSet inputs_hs;
  algorithm
    inputs_hs := match exp
      local
        ComponentRef cr;
        Type ty;

      // Skip time
      case Expression.CREF(cref = cr) guard(ComponentRef.isTime(cr)) then inputs_hs;

      // Skip external Objects
      case Expression.CREF(ty = ty) guard(Type.isExternalObject(ty)) then inputs_hs;

      case Expression.CREF(cref = cr)
        algorithm
          // since outputs get stripped, also strip inputs
          cr := ComponentRef.stripSubscriptsExceptModel(cr);
          if not BaseHashSet.has(cr, outputs_hs) then
            inputs_hs := BaseHashSet.add(cr, inputs_hs);
          end if;
      then inputs_hs;

      else inputs_hs;
    end match;
  end expressionInputs;

  function expressionOutput "author: Frenkel TUD 2012-06
    detects outputs by looking at crefs in the lhs of a statement"
    input Expression exp "should be a cref, otherwise fail";
    input output tuple<HashSet.HashSet, HashSet.HashSet> hashSets "inputs and outputs";
  algorithm
    hashSets := match exp
      local
        ComponentRef cr;
        Type ty;
        HashSet.HashSet inputs_hs, outputs_hs;

      // Skip wild
      case Expression.CREF(cref = ComponentRef.WILD()) then hashSets;

      // time is not an output in algorithms
      case Expression.CREF(cref = cr) guard(ComponentRef.isTime(cr))
        algorithm
          Error.addMessage(Error.COMPILER_ERROR, {"Trying to assign to time."});
      then fail();

      // Skip external Objects
      // or error?
      case Expression.CREF(ty = ty) guard(Type.isExternalObject(ty)) then hashSets;

      case Expression.CREF(cref = cr)
        algorithm
          (inputs_hs, outputs_hs) := hashSets;
          /* mahge:
          Modelica spec 3.3 rev 11.1.2
            "If at least one element of an array appears on the left hand side of
             the assignment operator, then the complete array is initialized in
             this algorithm section"
          So we strip the all subs except for model subs and send the whole array to expansion. i.e. we consider the whole array as modified.
          */
          cr := ComponentRef.stripSubscriptsExceptModel(cr);

          /* Modelica spec 3.4 11.1.2
            "A non-discrete variable is initialized with its start value (i.e. the
             value of the start-attribute)."
          phannebohm: This is very weird behavior. TODO change the spec!
          */
          if BaseHashSet.has(cr, inputs_hs) then
            Error.addMessage(Error.COMPILER_WARNING, {"Using output variable in RHS before it is assigned (former occurences will be set to initial value): " + Expression.toString(exp)});
            inputs_hs := BaseHashSet.delete(cr, inputs_hs);
            outputs_hs := BaseHashSet.add(cr, outputs_hs);
          else
            outputs_hs := BaseHashSet.add(cr, outputs_hs);
          end if;
      then (inputs_hs, outputs_hs);

      else
        algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed due to wrong expression type in LHS of algorithm statement: " + Expression.toString(exp)});
      then fail();
    end match;
  end expressionOutput;

  annotation(__OpenModelica_Interface="frontend");
end NFAlgorithm;
