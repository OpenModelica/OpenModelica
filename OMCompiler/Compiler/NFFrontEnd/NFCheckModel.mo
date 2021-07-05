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

encapsulated package NFCheckModel
  import FlatModel = NFFlatModel;
  import Variable = NFVariable;
  import Equation = NFEquation;
  import Algorithm = NFAlgorithm;
  import Statement = NFStatement;

protected
  import Type = NFType;
  import Binding = NFBinding;
  import Component = NFComponent;
  import NFPrefixes.{Direction, Variability};
  import ComponentRef = NFComponentRef;
  import UnorderedSet;
  import Expression = NFExpression;
  import Util;
  import ExpandExp = NFExpandExp;

public
function checkModel
  input FlatModel flatModel;
  output Integer variables = 0;
  output Integer equations = 0;
algorithm
  for v in flatModel.variables loop
    (variables, equations) := countVariableSize(v, variables, equations);
  end for;

  equations := equations + countEquationListSize(flatModel.equations);

  for a in flatModel.algorithms loop
    equations := equations + countAlgorithmSize(a);
  end for;
end checkModel;

function countVariableSize
  input Variable var;
  input output Integer variables;
  input output Integer equations;
protected
  Type ty;
  Binding binding;
  Component.Attributes attr;
algorithm
  Variable.VARIABLE(ty = ty, binding = binding, attributes = attr) := var;

  if attr.variability < Variability.DISCRETE then
    return;
  end if;

  if Type.isExternalObject(ty) then
    return;
  end if;

  if not Variable.isTopLevelInput(var) then
    variables := variables + Type.sizeOf(ty);
  end if;

  equations := equations + Type.sizeOf(Binding.getType(binding));
end countVariableSize;

function countEquationListSize
  input list<Equation> eqs;
  output Integer equations = 0;
algorithm
  for e in eqs loop
    equations := equations + countEquationSize(e);
  end for;
end countEquationListSize;

function countEquationSize
  input Equation eq;
  output Integer equations;
algorithm
  equations := match eq
    case Equation.EQUALITY() then Type.sizeOf(eq.ty);
    case Equation.CREF_EQUALITY() then Type.sizeOf(ComponentRef.getSubscriptedType(eq.lhs));
    case Equation.ARRAY_EQUALITY() then Type.sizeOf(eq.ty);
    case Equation.FOR() then countEquationListSize(eq.body);
    case Equation.IF() then countEquationBranchSize(listHead(eq.branches));
    case Equation.WHEN() then countEquationBranchSize(listHead(eq.branches));
    else 0;
  end match;
end countEquationSize;

function countEquationBranchSize
  input Equation.Branch branch;
  output Integer equations;
algorithm
  equations := match branch
    case Equation.Branch.BRANCH() then countEquationListSize(branch.body);

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got invalid branch", sourceInfo());
      then
        fail();
  end match;
end countEquationBranchSize;

function countAlgorithmSize
  input Algorithm alg;
  output Integer equations = 0;
protected
  UnorderedSet<ComponentRef> crefs;
algorithm
  crefs := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
  crefs := List.fold(alg.statements, statementOutputs, crefs);
  equations := equations + UnorderedSet.size(crefs);

  print("Algorithm size: " + String(UnorderedSet.size(crefs)) + "\n");
  for cr in UnorderedSet.toList(crefs) loop
    print(ComponentRef.toString(cr) + "\n");
  end for;
end countAlgorithmSize;

protected
function statementOutputs
  input Statement stmt;
  input output UnorderedSet<ComponentRef> crefs;
algorithm
  crefs := match stmt
    case Statement.ASSIGNMENT()
      then Expression.fold(stmt.lhs, statementOutputCrefFinder, crefs);

    case Statement.FOR()
      then List.fold(stmt.body, statementOutputs, crefs);

    case Statement.IF()
      algorithm
        for b in stmt.branches loop
          crefs := List.fold(Util.tuple22(b), statementOutputs, crefs);
        end for;
      then
        crefs;

    case Statement.WHEN()
      algorithm
        for b in stmt.branches loop
          crefs := List.fold(Util.tuple22(b), statementOutputs, crefs);
        end for;
      then
        crefs;

    case Statement.WHILE()
      then List.fold(stmt.body, statementOutputs, crefs);

    else crefs;
  end match;
end statementOutputs;

function statementOutputCrefFinder
  input Expression exp;
  input output UnorderedSet<ComponentRef> crefs;
protected
  ComponentRef cref;
algorithm
  crefs := match exp
    case Expression.CREF()
      algorithm
        cref := ComponentRef.stripSubscripts(exp.cref);
      then Expression.fold(ExpandExp.expand(Expression.fromCref(cref)), statementOutputCrefFinder2, crefs);

    else crefs;
  end match;
end statementOutputCrefFinder;

function statementOutputCrefFinder2
  input Expression exp;
  input output UnorderedSet<ComponentRef> crefs;
algorithm
  () := match exp
    case Expression.CREF()
      guard ComponentRef.isCref(exp.cref) and not ComponentRef.isIterator(exp.cref)
      algorithm
        UnorderedSet.add(exp.cref, crefs);
      then
        ();

    else ();
  end match;

end statementOutputCrefFinder2;

annotation(__OpenModelica_Interface="frontend");
end NFCheckModel;
