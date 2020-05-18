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

  function getOutputs "This function finds the outputs of an algorithm.
    An input is all values that are reffered on the right hand side of any
    statement in the algorithm and an output is a variables belonging to the
    variables that are assigned a value in the algorithm. If a variable is an
    input and an output it will be treated as an output."
    input Algorithm alg;
    output list<ComponentRef> cref_lst;
  protected
    list<Statement> stmts;
    HashSet.HashSet hashSet = HashSet.emptyHashSet();
  algorithm
    try
      ALGORITHM(statements = stmts) := alg;
      hashSet := List.fold(stmts, function statementOutputs(), hashSet);
      cref_lst := BaseHashSet.hashSetList(hashSet);
    else
      Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
    end try;
  end getOutputs;

protected
  function statementOutputs "Helper relation to getOutputs"
    input Statement statement;
    input output HashSet.HashSet hashSet;
  algorithm
    hashSet := match statement
      local
        Expression lhs;
        list<Expression> elements;
        list<Statement> stmts;
        list<tuple<Expression, list<Statement>>> branches;

      // a := expr;
      case Statement.ASSIGNMENT(lhs = lhs as Expression.CREF())
        algorithm
          // TODO extend for array, matrix?
          // TODO has to be scalarized if scalarize
          hashSet := statementOutputsCrefFinder(lhs, hashSet);
      then hashSet;

      // (a, b, c, ...) := expr;
      case Statement.ASSIGNMENT(lhs=lhs as Expression.TUPLE(elements = elements))
        algorithm
          // TODO extend for array, matrix?
          for exp in elements loop
            hashSet := statementOutputsCrefFinder(exp, hashSet);
          end for;
      then hashSet;

      // ToDo: Statement.ASSIGNMENT(lhs=lhs as Expression.RECORD_ELEMENT())

      case Statement.FOR(body = stmts)
        algorithm
          for stmt in stmts loop
            hashSet := statementOutputs(stmt, hashSet);
          end for;
      then hashSet;

      case Statement.IF(branches = branches)
        algorithm
          for branch in branches loop
            (_, stmts) := branch;
            for stmt in stmts loop
              hashSet := statementOutputs(stmt, hashSet);
            end for;
          end for;
      then hashSet;

      case Statement.WHEN(branches = branches)
        algorithm
          for branch in branches loop
            (_, stmts) := branch;
            for stmt in stmts loop
              hashSet := statementOutputs(stmt, hashSet);
            end for;
          end for;
      then hashSet;

      case Statement.WHILE(body = stmts)
        algorithm
          for stmt in stmts loop
            hashSet := statementOutputs(stmt, hashSet);
          end for;
      then hashSet;

      case Statement.ASSERT() then hashSet;
      case Statement.TERMINATE() then hashSet;
      case Statement.NORETCALL() then hashSet;
      case Statement.RETURN() then hashSet;
      case Statement.BREAK() then hashSet;
      case Statement.FAILURE() then hashSet; // does this need to do sth ?

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
  end statementOutputs;

  function statementOutputsCrefFinder "author: Frenkel TUD 2012-06"
    input Expression exp;
    input output HashSet.HashSet hashSet;
  algorithm
    hashSet := match exp
      local
        ComponentRef cr;
        Type ty;
        DAE.Expand expand;

      // Skip wild
      case Expression.CREF(cref = ComponentRef.WILD()) then hashSet;

      // Skip time
      case Expression.CREF(cref = cr) guard(ComponentRef.isTime(cr)) then hashSet;

      // Skip external Objects
      case Expression.CREF(ty = ty) guard(Type.isExternalObject(ty)) then hashSet;

      case Expression.CREF(cref = cr, ty = ty) guard(Type.isRecord(ty))
        algorithm
          cr := ComponentRef.stripSubscriptsExceptModel(cr);
          hashSet := BaseHashSet.add(cr, hashSet);
      then hashSet;

      // EXPAND
      /* mahge:
        Modelica spec 3.3 rev 11.1.2
        "If at least one element of an array appears on the left hand side of the assignment operator, then the
         complete array is initialized in this algorithm section"
        So we strip the all subs except for model subs and send the whole array to expansion. i.e. we consider the whole array as modified.
      */
      case Expression.CREF(cref=cr)
        algorithm
          cr := ComponentRef.stripSubscriptsExceptModel(cr);
          hashSet := BaseHashSet.add(cr, hashSet);
      then hashSet;

      else
        algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed due to wrong expression type in LHS of algorithm statement: " + Expression.toString(exp)});
      then fail();
    end match;
  end statementOutputsCrefFinder;

  annotation(__OpenModelica_Interface="frontend");
end NFAlgorithm;
