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

encapsulated package NFCheckModel
  import FlatModel = NFFlatModel;
  import Variable = NFVariable;
  import Equation = NFEquation;
  import Algorithm = NFAlgorithm;
  import Statement = NFStatement;

protected
  import Type = NFType;
  import Binding = NFBinding;
  import NFPrefixes.{Direction, Variability};
  import ComponentRef = NFComponentRef;
  import UnorderedSet;
  import Expression = NFExpression;
  import Util;
  import ExpandExp = NFExpandExp;
  import Attributes = NFAttributes;
  import Operator = NFOperator;
  import NFInstNode.InstNode;
  import Component = NFComponent;
  import SimplifyExp = NFSimplifyExp;
  import MetaModelica.Dangerous.listReverseInPlace;

public
function checkModel
  input FlatModel flatModel;
  output Expression variables;
  output Expression equations;
  output Integer simpleEquations = 0;
protected
  Integer vars = 0, eqs = 0;
  list<Expression> var_exps = {}, eq_exps = {};
algorithm
  for v in flatModel.variables loop
    (vars, var_exps, eqs, eq_exps, simpleEquations) :=
      countVariableSize(v, vars, var_exps, eqs, eq_exps, simpleEquations);
  end for;

  (eqs, eq_exps) := Equation.sizeOfListSymbolic(flatModel.equations, eqs, eq_exps);
  simpleEquations := simpleEquations + countSimpleEquations(flatModel.equations);

  for a in flatModel.algorithms loop
    eqs := eqs + countAlgorithmSize(a);
  end for;

  variables := makeSum(vars, var_exps);
  equations := makeSum(eqs, eq_exps);
end checkModel;

function countVariableSize
  input Variable var;
  input output Integer variables;
  input output list<Expression> variablesExps;
  input output Integer equations;
  input output list<Expression> equationsExps;
  input output Integer simpleEquations;
protected
  Type ty;
  Binding binding;
  Attributes attr;
  Integer var_size, binding_size;
  list<Expression> var_exps, binding_exps;
algorithm
  Variable.VARIABLE(ty = ty, binding = binding, attributes = attr) := var;

  if attr.variability < Variability.DISCRETE then
    return;
  end if;

  if Type.isExternalObject(ty) then
    return;
  end if;

  (var_size, var_exps) := Type.sizeOfSymbolic(ty, 0, {}, SOME(var.name));
  variables := variables + var_size;
  variablesExps := listAppend(var_exps, variablesExps);

  if Variable.isInput(var) and Variable.isPublic(var) then
    equations := equations + var_size;
  else
    (binding_size, binding_exps) := Type.sizeOfSymbolic(Binding.getType(binding));
    equations := equations + binding_size;
    equationsExps := listAppend(binding_exps, equationsExps);

    // Check if var = binding counts as a simple equation.
    if Binding.hasExp(binding) and
       isSimpleEquation(Expression.CREF(ty, var.name), Binding.getExp(binding), ty) then
      simpleEquations := simpleEquations + binding_size;
    end if;
  end if;
end countVariableSize;

function countAlgorithmSize
  input Algorithm alg;
  output Integer equations = 0;
protected
  UnorderedSet<ComponentRef> crefs;
algorithm
  crefs := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
  crefs := List.fold(alg.statements, statementOutputs, crefs);
  equations := equations + UnorderedSet.size(crefs);
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
        // Assigning to an array element counts as initializing the whole array, except for arrays
        // of models where each model instance is considered to have their own variables.
        cref := ComponentRef.stripSubscriptsExceptModel(exp.cref);
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

function countSimpleEquations
  input list<Equation> eqs;
  output Integer simpleEquations = 0;
algorithm
  for eq in eqs loop
    simpleEquations := simpleEquations + countSimpleEquation(eq);
  end for;
end countSimpleEquations;

function countSimpleEquation
  input Equation eq;
  output Integer simpleEquations;
algorithm
  simpleEquations := match eq
    case Equation.EQUALITY() guard isSimpleEquation(eq.lhs, eq.rhs, eq.ty) then Type.sizeOf(eq.ty);
    else 0;
  end match;
end countSimpleEquation;

function isSimpleEquation
  input Expression lhs;
  input Expression rhs;
  input Type ty;
  output Boolean isSimple;
algorithm
  if Expression.isLiteral(lhs) then
    // Flip literal = x to x = literal to reduce the number of cases.
    isSimple := isSimpleEquation2(rhs, lhs, ty);
  else
    isSimple := isSimpleEquation2(lhs, rhs, ty);
  end if;
end isSimpleEquation;

function isSimpleEquation2
  input Expression lhs;
  input Expression rhs;
  input Type ty;
  output Boolean isSimple;
protected
  Boolean lhs_is_cref, rhs_is_cref;
  Expression e1, e2;
  Integer u;
  UnorderedSet<ComponentRef> crefs;
algorithm
  isSimple := match (lhs, rhs)
    // ±a = ±b
    // ±a = literal
    case (_, _)
      guard isCrefOrNegatedCref(lhs) and (isCrefOrNegatedCref(rhs) or Expression.isLiteral(rhs))
      then true;

    // ±a ± ±b = 0
    case (Expression.BINARY(), _)
      guard isAddOrSub(lhs.operator) and isCrefOrNegatedCref(lhs.exp1) and
            isCrefOrNegatedCref(lhs.exp2) and Expression.isZero(rhs)
      then true;

    case (Expression.MULTARY(), _)
      guard isAddOrSub(lhs.operator) and Expression.isZero(rhs) and
            listLength(lhs.arguments) + listLength(lhs.inv_arguments) == 2 and
            List.all(lhs.arguments, isCrefOrNegatedCref) and List.all(lhs.inv_arguments, isCrefOrNegatedCref)
      then true;

    // ±a = ±der(b) or ±der(a) = ±b
    case (_, _)
      guard isCrefOrNegatedCref(lhs) and isDerOrNegatedDer(rhs) or
            isCrefOrNegatedCref(rhs) and isDerOrNegatedDer(lhs)
      then true;

    // Any equation involving only one unknown.
    case (_, _)
      guard Type.isReal(ty) or Type.isInteger(ty) or Type.isEnumeration(ty)
      algorithm
        crefs := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
        crefs := Expression.fold(lhs, countUnknowns_traverser, crefs);

        if UnorderedSet.size(crefs) <= 1 then
          crefs := Expression.fold(rhs, countUnknowns_traverser, crefs);
        end if;
      then
        UnorderedSet.size(crefs) == 1;

    else false;
  end match;
end isSimpleEquation2;

function isCrefOrNegatedCref
  input Expression exp;
  output Boolean cref;
algorithm
  cref := match exp
    case Expression.CREF() then true;
    case Expression.UNARY(exp = Expression.CREF()) then true;
    else false;
  end match;
end isCrefOrNegatedCref;

function isDerOrNegatedDer
  input Expression exp;
  output Boolean cref;
algorithm
  cref := match exp
    case Expression.UNARY() then Expression.isCallNamed(exp.exp, "der");
    else Expression.isCallNamed(exp, "der");
  end match;
end isDerOrNegatedDer;

function isAddOrSub
  input Operator op;
  output Boolean res;
algorithm
  res := match op.op
    case NFOperator.Op.ADD then true;
    case NFOperator.Op.SUB then true;
    else false;
  end match;
end isAddOrSub;

function countUnknowns_traverser
  input Expression exp;
  input output UnorderedSet<ComponentRef> crefs;
protected
  InstNode node;
  Component comp;
algorithm
  // This is only used to check if an equation contains exactly one unknown,
  // so return early if we've already found more than that.
  if UnorderedSet.size(crefs) > 1 then
    return;
  end if;

  () := match exp
    case Expression.CREF()
      guard ComponentRef.isCref(exp.cref) and not Type.isExternalObject(exp.ty)
      algorithm
        node := ComponentRef.node(exp.cref);

        if InstNode.isComponent(node) then
          comp := InstNode.component(node);

          if Component.variability(comp) >= Variability.DISCRETE and
             not (Component.isInput(comp) and ComponentRef.isTopLevel(exp.cref)) then
            UnorderedSet.add(exp.cref, crefs);
          end if;
        end if;
      then
        ();

    else ();
  end match;
end countUnknowns_traverser;

function makeSum
  "Constructs n + sum(exps)."
  input Integer n;
  input list<Expression> exps;
  output Expression sumExp;
protected
  list<Expression> expl = {};
  UnorderedMap<Expression, Integer> terms;
  Expression exp;
  Integer factor;
algorithm
  if listEmpty(exps) then
    sumExp := Expression.INTEGER(n);
  else
    terms := UnorderedMap.new<Integer>(Expression.hash, Expression.isEqual);

    for e in exps loop
      addTerm(e, terms);
    end for;

    for term in UnorderedMap.toList(terms) loop
      (exp, factor) := term;

      if factor > 1 then
        exp := Expression.BINARY(Expression.INTEGER(factor), Operator.makeMul(Type.INTEGER()), exp);
      end if;

      expl := exp :: expl;
    end for;

    expl := listReverseInPlace(expl);

    if n <> 0 then
      expl := Expression.INTEGER(n) :: expl;
    end if;

    sumExp := Expression.MULTARY(expl, {}, Operator.makeAdd(Type.INTEGER()));
    sumExp := SimplifyExp.simplify(sumExp);
  end if;
end makeSum;

function addTerm
  input Expression exp;
  input UnorderedMap<Expression, Integer> terms;
protected
  Integer factor;
algorithm
  () := match exp
    // n * exp
    case Expression.BINARY(exp1 = Expression.INTEGER(factor),
                           operator = Operator.OPERATOR(op = NFOperator.Op.MUL))
      algorithm
        mergeTerm(exp.exp2, factor, terms);
      then
        ();

    // exp * n
    case Expression.BINARY(exp2 = Expression.INTEGER(factor),
                           operator = Operator.OPERATOR(op = NFOperator.Op.MUL))
      algorithm
        mergeTerm(exp.exp1, factor, terms);
      then
        ();

    else
      algorithm
        mergeTerm(exp, 1, terms);
      then
        ();
  end match;
end addTerm;

function mergeTerm
  input Expression exp;
  input Integer factor;
  input UnorderedMap<Expression, Integer> terms;
algorithm
  UnorderedMap.addMerge(exp, factor, intAdd, terms);
end mergeTerm;

annotation(__OpenModelica_Interface="nf_frontend");
end NFCheckModel;
