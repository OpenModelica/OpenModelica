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

encapsulated package NFSimplifyModel

import FlatModel = NFFlatModel;
import Equation = NFEquation;
import Statement = NFStatement;
import Expression = NFExpression;
import Type = NFType;
import ComponentRef = NFComponentRef;
import NFFlatten.FunctionTree;
import NFClass.Class;
import NFInstNode.InstNode;
import NFFunction.Function;
import Sections = NFSections;

protected
import MetaModelica.Dangerous.*;
import ExecStat.execStat;

public
function simplify
  input output FlatModel flatModel;
  input output FunctionTree functions;
algorithm
  flatModel.equations := simplifyEquations(flatModel.equations);
  flatModel.initialEquations := simplifyEquations(flatModel.initialEquations);

  //functions := FunctionTree.map(functions, simplifyFunction);

  execStat(getInstanceName());
end simplify;

function simplifyEquations
  input list<Equation> eql;
  output list<Equation> outEql = {};
algorithm
  for eq in eql loop
    outEql := simplifyEquation(eq, outEql);
  end for;

  outEql := listReverseInPlace(outEql);
end simplifyEquations;

function simplifyEquation
  input Equation eq;
  input output list<Equation> equations;
algorithm
  equations := match eq
    case Equation.EQUALITY()
      algorithm
        eq.lhs := removeEmptyTupleElements(eq.lhs);
        eq.rhs := removeEmptyFunctionArguments(eq.rhs);
      then
        eq :: equations;

    case Equation.ARRAY_EQUALITY()
      algorithm
        eq.rhs := removeEmptyFunctionArguments(eq.rhs);
      then
        eq :: equations;

    case Equation.NORETCALL()
      algorithm
        eq.exp := removeEmptyFunctionArguments(eq.exp);
      then
        eq :: equations;

    else eq :: equations;
  end match;
end simplifyEquation;

function simplifyStatements
  input list<Statement> stmts;
  output list<Statement> outStmts = {};
algorithm
  for s in stmts loop
    outStmts := simplifyStatement(s, outStmts);
  end for;

  outStmts := listReverseInPlace(outStmts);
end simplifyStatements;

function simplifyStatement
  input Statement stmt;
  input output list<Statement> statements;
algorithm
  statements := match stmt
    case Statement.ASSIGNMENT()
      algorithm
        stmt.lhs := removeEmptyTupleElements(stmt.lhs);
        stmt.rhs := removeEmptyFunctionArguments(stmt.rhs);
      then
        stmt :: statements;

    case Statement.NORETCALL()
      algorithm
        stmt.exp := removeEmptyFunctionArguments(stmt.exp);
      then
        stmt :: statements;

    else stmt :: statements;
  end match;
end simplifyStatement;

function removeEmptyTupleElements
  "Replaces tuple elements that has one or more zero dimension with _."
  input output Expression exp;
algorithm
  () := match exp
    local
      list<Type> tyl;

    case Expression.TUPLE(ty = Type.TUPLE(types = tyl))
      algorithm
        exp.elements := list(
          if Type.isEmptyArray(t) then Expression.CREF(t, ComponentRef.WILD()) else e
          threaded for e in exp.elements, t in tyl);
      then
        ();

    else ();
  end match;
end removeEmptyTupleElements;

function removeEmptyFunctionArguments
  input Expression exp;
  input Boolean isArg = false;
  output Expression outExp;
protected
  Boolean is_arg;
algorithm
  if isArg then
    () := match exp
      case Expression.CREF() guard Type.isEmptyArray(exp.ty)
        algorithm
          //outExp := Expression.ARRAY(exp.ty, {});
          outExp := Expression.fillType(exp.ty, Expression.INTEGER(0));
          return;
        then
          ();

      else ();
    end match;
  end if;

  is_arg := isArg or Expression.isCall(exp);
  outExp := Expression.mapShallow(exp, function removeEmptyFunctionArguments(isArg = is_arg));
end removeEmptyFunctionArguments;

function simplifyFunction
  input Absyn.Path name;
  input output Function func;
protected
  Class cls;
  list<Statement> fn_body;
  Sections sections;
algorithm
  cls := InstNode.getClass(func.node);

  () := match cls
    case Class.INSTANCED_CLASS(sections = sections)
      algorithm
        () := match sections
          case Sections.SECTIONS(algorithms = {fn_body})
            algorithm
              fn_body := simplifyStatements(fn_body);
              sections.algorithms := {fn_body};
              cls.sections := sections;
              InstNode.updateClass(cls, func.node);
            then
              ();

          else ();
        end match;
      then
        ();

    else ();
  end match;
end simplifyFunction;

annotation(__OpenModelica_Interface="frontend");
end NFSimplifyModel;
