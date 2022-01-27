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

encapsulated uniontype NFVerifyModel
  import FlatModel = NFFlatModel;

protected
  import List;
  import Error;
  import ErrorTypes;
  import DAE;
  import ElementSource;
  import ExecStat.execStat;
  import ComponentRef = NFComponentRef;
  import Equation = NFEquation;
  import Expression = NFExpression;
  import ExpandExp = NFExpandExp;
  import NFInstNode.InstNode;
  import Record = NFRecord;
  import Variable = NFVariable;
  import Algorithm = NFAlgorithm;
  import Statement = NFStatement;
  import Binding = NFBinding;
  import Subscript = NFSubscript;
  import Dimension = NFDimension;
  import Util;
  import Type = NFType;
  import NFPrefixes.Variability;
  import NFHashTable.HashTable;
  import BaseHashTable;

public
  function verify
    input FlatModel flatModel;
  algorithm
    for var in flatModel.variables loop
      verifyVariable(var);
    end for;

    for eq in flatModel.equations loop
      verifyEquation(eq);
    end for;

    for ieq in flatModel.initialEquations loop
      verifyEquation(ieq);
    end for;

    for alg in flatModel.algorithms loop
      verifyAlgorithm(alg);
    end for;

    for ialg in flatModel.initialAlgorithms loop
      verifyAlgorithm(ialg);
    end for;

    // check for discrete real variables not assigned in when equations (#5836)
    checkDiscreteReal(flatModel);

    execStat(getInstanceName());
  end verify;

protected
  function verifyVariable
    input Variable var;
  algorithm
    verifyBinding(var.binding);

    for attr in var.typeAttributes loop
      verifyBinding(Util.tuple22(attr));
    end for;

    for v in var.children loop
      verifyVariable(v);
    end for;
  end verifyVariable;

  function verifyBinding
    input Binding binding;
  algorithm
    if Binding.isBound(binding) then
      checkSubscriptBounds(Binding.getTypedExp(binding), Binding.getInfo(binding));
    end if;
  end verifyBinding;

  function verifyEquation
    input Equation eq;
  algorithm
    () := match eq
      case Equation.WHEN()
        algorithm
          verifyWhenEquation(eq.branches, eq.source);
        then
          ();

      else ();
    end match;

    Equation.applyExp(eq, function checkSubscriptBounds(info = Equation.info(eq)));
  end verifyEquation;

  function verifyWhenEquation
    "Checks that each branch in a when-equation has the same set of crefs on the lhs."
    input list<Equation.Branch> branches;
    input DAE.ElementSource source;
  protected
    list<ComponentRef> crefs1, crefs2;
    list<Equation.Branch> rest_branches;
    list<Equation> body;
  algorithm
    // Only when-equation with more than one branch needs to be checked.
    if List.hasOneElement(branches) then
      return;
    end if;

    Equation.Branch.BRANCH(body = body) :: rest_branches := branches;
    crefs1 := whenEquationBranchCrefs(body);

    for branch in rest_branches loop
      Equation.Branch.BRANCH(body = body) := branch;
      crefs2 := whenEquationBranchCrefs(body);

      checkCrefSetEquality(crefs1, crefs2, Error.DIFFERENT_VARIABLES_SOLVED_IN_ELSEWHEN, source);
    end for;
  end verifyWhenEquation;

  function whenEquationBranchCrefs
    "Helper function to verifyWhenEquation, returns the set of crefs that the
     given list of equations contains on the lhs."
    input list<Equation> eql;
    output list<ComponentRef> crefs = {};
  algorithm
    for eq in eql loop
      crefs := match eq
        case Equation.EQUALITY()       then whenEquationEqualityCrefs(eq.lhs, crefs);
        case Equation.CREF_EQUALITY()  then eq.lhs :: crefs;
        case Equation.ARRAY_EQUALITY() then whenEquationEqualityCrefs(eq.lhs, crefs);
        case Equation.REINIT()         then whenEquationEqualityCrefs(eq.cref, crefs);
        case Equation.IF()             then whenEquationIfCrefs(eq.branches, eq.source, crefs);
        else crefs;
      end match;
    end for;

    crefs := List.sort(crefs, ComponentRef.isGreater);
    crefs := List.sortedUnique(crefs, ComponentRef.isEqual);
  end whenEquationBranchCrefs;

  function whenEquationEqualityCrefs
    input Expression lhsExp;
    input output list<ComponentRef> crefs;
  algorithm
    crefs := match lhsExp
      case Expression.CREF() then lhsExp.cref :: crefs;
      case Expression.TUPLE()
        then List.fold(lhsExp.elements, whenEquationEqualityCrefs, crefs);
    end match;
  end whenEquationEqualityCrefs;

  function whenEquationIfCrefs
    "Checks that the left-hand sides of the given if-equation branches consists
     of the same set of crefs, and adds that set to the given set of crefs."
    input list<Equation.Branch> branches;
    input DAE.ElementSource source;
    input output list<ComponentRef> crefs;
  protected
    list<ComponentRef> crefs1, crefs2;
    list<Equation.Branch> rest_branches;
    list<Equation> body;
  algorithm
    Equation.Branch.BRANCH(body = body) :: rest_branches := branches;
    crefs1 := whenEquationBranchCrefs(body);

    for branch in rest_branches loop
      Equation.Branch.BRANCH(body = body) := branch;
      crefs2 := whenEquationBranchCrefs(body);

      // All the branches must have the same set of crefs on the lhs.
      checkCrefSetEquality(crefs1, crefs2, Error.WHEN_IF_VARIABLE_MISMATCH, source);
    end for;

    crefs := listAppend(crefs1, crefs);
  end whenEquationIfCrefs;

  function checkCrefSetEquality
    input list<ComponentRef> crefs1;
    input list<ComponentRef> crefs2;
    input ErrorTypes.Message errMsg;
    input DAE.ElementSource source;
  algorithm
    // Assume the user isn't mixing different ways of subscripting array
    // varibles in the different branches, and just check the sets as is.
    if List.isEqualOnTrue(crefs1, crefs2, ComponentRef.isEqual) then
      return;
    end if;

    // If the sets didn't match, expand arrays into scalars and try again.
    if List.isEqualOnTrue(expandCrefSet(crefs1), expandCrefSet(crefs2), ComponentRef.isEqual) then
      return;
    end if;

    // Couldn't get the sets to match, print an error and fail.
    Error.addSourceMessage(errMsg, {}, ElementSource.getInfo(source));
    fail();
  end checkCrefSetEquality;

  function expandCrefSet
    input list<ComponentRef> crefs;
    output list<ComponentRef> outCrefs = {};
  protected
    Expression exp;
    list<Expression> expl;
  algorithm
    for cref in crefs loop
      exp := Expression.fromCref(cref);
      exp := ExpandExp.expandCref(exp);

      if Expression.isArray(exp) then
        expl := Expression.arrayElements(exp);
        outCrefs := listAppend(list(Expression.toCref(e) for e in expl), outCrefs);
      else
        outCrefs := cref :: outCrefs;
      end if;
    end for;

    outCrefs := List.sort(outCrefs, ComponentRef.isGreater);
    outCrefs := List.sortedUnique(outCrefs, ComponentRef.isEqual);
  end expandCrefSet;

  function verifyAlgorithm
    input Algorithm alg;
  algorithm
    Algorithm.apply(alg, verifyStatement);
  end verifyAlgorithm;

  function verifyStatement
    input Statement stmt;
  algorithm
    Statement.applyExp(stmt, function checkSubscriptBounds(info = Statement.info(stmt)));
  end verifyStatement;

  function checkSubscriptBounds
    input Expression exp;
    input SourceInfo info;
  algorithm
    Expression.apply(exp, function checkSubscriptBounds_traverser(info = info));
  end checkSubscriptBounds;

  function checkSubscriptBounds_traverser
    input Expression exp;
    input SourceInfo info;
  algorithm
    () := match exp
      case Expression.CREF()
        algorithm
          checkSubscriptBoundsCref(exp.cref, info);
        then
          ();

      else ();
    end match;
  end checkSubscriptBounds_traverser;

  function checkSubscriptBoundsCref
    input ComponentRef cref;
    input SourceInfo info;
  algorithm
    () := match cref
      local
        list<Dimension> dims;
        list<Subscript> subs;
        Dimension d;
        Integer int_sub, index;

      case ComponentRef.CREF(subscripts = subs as _ :: _, ty = Type.ARRAY(dimensions = dims))
        algorithm
          index := 1;

          for s in subs loop
            d :: dims := dims;

            if Subscript.isScalarLiteral(s) and Dimension.isKnown(d) then
              int_sub := Subscript.toInteger(s);

              if int_sub < 1 or int_sub > Dimension.size(d) then
                Error.addSourceMessage(Error.ARRAY_INDEX_OUT_OF_BOUNDS,
                  {Subscript.toString(s), String(index),
                   Dimension.toString(d), ComponentRef.firstName(cref)}, info);
                fail();
              end if;
            end if;

            index := index + 1;
          end for;

          checkSubscriptBoundsCref(cref.restCref, info);
        then
          ();

      else ();
    end match;
  end checkSubscriptBoundsCref;

  function checkDiscreteReal
    "author: kabdelhak 2020-06
    Checks if all discrete real variables are defined by a when-statement.
    Linear with respect to the number of equations and variables. It traverses
    each equation and collects all relevant component references and afterwards
    checks if any discrete real variables were not defined by a when-statement.
    Ticket: #5836"
    input FlatModel flatModel;
  protected
    HashTable hashTable = NFHashTable.emptyHashTable();
    list<Variable> illegal_discrete_vars = {};
    String err_str = "";
  algorithm
    // collect all lhs crefs that are discrete and real from equations
    for eqn in flatModel.equations loop
      hashTable := checkDiscreteRealEquation(eqn, hashTable, false);
    end for;

    // collect all lhs crefs that are discrete and real from algorithms
    for alg in flatModel.algorithms loop
      hashTable := match alg
        local
          list<Statement> statements;

        case Algorithm.ALGORITHM(statements = statements)
          algorithm
            for statement in statements loop
              hashTable := checkDiscreteRealStatement(statement, hashTable, false);
            end for;
        then hashTable;

        else hashTable;
      end match;
    end for;

    // check if all discrete real variables are assigned in when bodys
    for variable in flatModel.variables loop
      // check variability and not type for discrete variables
      // remove all subscripts to handle arrays
      variable.name := ComponentRef.stripSubscriptsAll(variable.name);
      if Variable.variability(variable) == Variability.DISCRETE and Type.isRealRecursive(variable.ty) and not BaseHashTable.hasKey(variable.name, hashTable) then
        illegal_discrete_vars := variable :: illegal_discrete_vars;
      end if;
    end for;

    // report error if there are any
    if not listEmpty(illegal_discrete_vars) then
      for var in illegal_discrete_vars loop
        Error.addSourceMessage(Error.DISCRETE_REAL_UNDEFINED, {ComponentRef.toString(var.name)}, var.info);
      end for;
      fail();
    end if;
  end checkDiscreteReal;

protected
  function checkDiscreteRealBranch
    "author: kabdelhak 2020-06
    collects all single discrete real crefs on the LHS of the body eqns of a
    when (or nested if inside when) branch."
    input Equation.Branch branch;
    input output HashTable hashTable;
    input Boolean when_found;
  algorithm
    hashTable := match branch
      local
        list<Equation> body;

      case Equation.BRANCH(body = body) guard(when_found)
        algorithm
          for eqn in body loop
            hashTable := checkDiscreteRealEquation(eqn, hashTable, when_found);
          end for;
      then hashTable;

      else hashTable;
    end match;
  end checkDiscreteRealBranch;

  function checkDiscreteRealEquation
    "author: kabdelhak 2020-06
    collects all single discrete real crefs on the LHS of a branch which is
    part of a when eqn body. Only use to analyze when equation bodys!"
    input Equation body_eqn;
    input output HashTable hashTable;
    input Boolean when_found;
  algorithm
    hashTable := match body_eqn
      local
        Expression lhs;
        Type ty;
        ComponentRef cref;
        InstNode cls;
        list<Equation> body;
        list<Equation.Branch> branches;

      case Equation.EQUALITY(lhs = lhs)       guard(when_found) then checkDiscreteRealExp(lhs, hashTable);
      case Equation.ARRAY_EQUALITY(lhs = lhs) guard(when_found) then checkDiscreteRealExp(lhs, hashTable);

      case Equation.CREF_EQUALITY(lhs = cref as ComponentRef.CREF(ty = ty)) guard(Type.isRealRecursive(ty) and when_found)
        algorithm
          // remove all subscripts to handle arrays
          hashTable := BaseHashTable.add((ComponentRef.stripSubscriptsAll(cref), 0), hashTable);
      then hashTable;

      case Equation.CREF_EQUALITY(lhs = cref as ComponentRef.CREF(ty = ty as Type.COMPLEX(cls = cls))) guard(Type.isRecord(ty) and when_found)
      then checkDiscreteRealRecord(cref, cls, hashTable);

      // traverse nested if equations. It suffices if the variable is defined in ANY branch.
      case Equation.IF(branches = branches)
        algorithm
          for branch in branches loop
            hashTable := checkDiscreteRealBranch(branch, hashTable, when_found);
          end for;
      then hashTable;

      // traverse when body
      case Equation.WHEN(branches = branches)
        algorithm
          for branch in branches loop
            hashTable := checkDiscreteRealBranch(branch, hashTable, true);
          end for;
      then hashTable;

      // what if LHS is indexed? :(
      case Equation.FOR(body = body)
        algorithm
          for eqn in body loop
            hashTable := checkDiscreteRealEquation(eqn, hashTable, when_found);
          end for;
      then hashTable;

      else hashTable;
    end match;
  end checkDiscreteRealEquation;

  function checkDiscreteRealStatement
    "author: kabdelhak 2020-06
    collects all single discrete real crefs on the LHS of a statement which is
    part of a when algorithm body."
    input Statement statement;
    input output HashTable hashTable;
    input Boolean when_found;
  algorithm
    hashTable := match statement
      local
        Expression lhs;
        list<tuple<Expression, list<Statement>>> branches;
        list<Statement> body;

      case Statement.WHEN(branches = branches)
        algorithm
          for branch in branches loop
            (_, body) := branch;
            for statement in body loop
              hashTable := checkDiscreteRealStatement(statement, hashTable, true);
            end for;
          end for;
      then hashTable;

      case Statement.ASSIGNMENT(lhs = lhs) guard(when_found) then checkDiscreteRealExp(lhs, hashTable);

      // traverse nested if Algorithms. It suffices if the variable is defined in ANY branch.
      case Statement.IF(branches = branches)
        algorithm
          for branch in branches loop
            (_, body) := branch;
            for stmt in body loop
              hashTable := checkDiscreteRealStatement(stmt, hashTable, when_found);
            end for;
          end for;
      then hashTable;

      // what if the LHS is indexed? :(
      case Statement.FOR(body = body)
        algorithm
          for statement in body loop
            hashTable := checkDiscreteRealStatement(statement, hashTable, when_found);
          end for;
      then hashTable;

      else hashTable;
    end match;
  end checkDiscreteRealStatement;

  function checkDiscreteRealExp
    "author: kabdelhak 2020-06
    collects all single discrete real crefs of an expression which represents the LHS."
    input Expression exp;
    input output HashTable hashTable;
  algorithm
    hashTable := match exp
      local
         Type ty;
         ComponentRef cref;
         list<Expression> elements;
         InstNode cls;

      // only add if it is a real variable, we cannot check for discrete here
      // since only the variable has variablity information
      // Type.isDiscrete does always return false for REAL
      case Expression.CREF(ty = ty, cref = cref) guard(Type.isRealRecursive(ty))
        algorithm
          // remove all subscripts to handle arrays
          hashTable := BaseHashTable.add((ComponentRef.stripSubscriptsAll(cref), 0), hashTable);
      then hashTable;

      case Expression.CREF(ty = ty as Type.COMPLEX(cls = cls), cref = cref) guard(Type.isRecord(ty))
      then checkDiscreteRealRecord(cref, cls, hashTable);

      case Expression.TUPLE(elements = elements)
        algorithm
          for element in elements loop
            hashTable := checkDiscreteRealExp(element, hashTable);
          end for;
      then hashTable;

      else hashTable;

    end match;
  end checkDiscreteRealExp;

  function checkDiscreteRealRecord
    input ComponentRef cref;
    input InstNode cls;
    input output HashTable hashTable;
  protected
    ComponentRef element;
    list<InstNode> inputs;
  algorithm
    // remove all subscripts to handle arrays
    hashTable := BaseHashTable.add((ComponentRef.stripSubscriptsAll(cref), 0), hashTable);
    // also add all record elements
    (inputs, _, _) := Record.collectRecordParams(cls);
    for node in inputs loop
      element := ComponentRef.prefixCref(node, InstNode.getType(node), {}, cref);
      hashTable := BaseHashTable.add((ComponentRef.stripSubscriptsAll(element), 0), hashTable);
    end for;
  end checkDiscreteRealRecord;

  annotation(__OpenModelica_Interface="frontend");
end NFVerifyModel;
