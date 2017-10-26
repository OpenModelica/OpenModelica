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

encapsulated package NFFlatten
" file:        NFFlatten.mo
  package:     NFFlatten
  description: Flattening


  New instantiation, enable with -d=newInst.
"

import Binding = NFBinding;
import Equation = NFEquation;
import NFFunction.Function;
import NFInstNode.InstNode;
import Statement = NFStatement;

protected
import ComponentRef = NFComponentRef;
import Dimension = NFDimension;
import ExecStat.execStat;
import ExpressionIterator = NFExpressionIterator;
import Expression = NFExpression;
import Inst = NFInst;
import List;
import NFCall.Call;
import NFClass.Class;
import NFClassTree.ClassTree;
import NFComponent.Component;
import NFMod.Modifier;
import Sections = NFSections;
import Prefixes = NFPrefixes;
import RangeIterator = NFRangeIterator;
import Subscript = NFSubscript;
import Type = NFType;
import Util;
import MetaModelica.Dangerous.listReverseInPlace;

public
type FunctionTree = FunctionTreeImpl.Tree;

encapsulated package FunctionTreeImpl
  import Absyn.Path;
  import NFFunction.Function;
  import BaseAvlTree;

  extends BaseAvlTree;
  redeclare type Key = Absyn.Path;
  redeclare type Value = Function;

  redeclare function extends keyStr
  algorithm
    outString := Absyn.pathString(inKey);
  end keyStr;

  redeclare function extends valueStr
  algorithm
    outString := "";
  end valueStr;

  redeclare function extends keyCompare
  algorithm
    outResult := Absyn.pathCompareNoQual(inKey1, inKey2);
  end keyCompare;

  redeclare function addConflictDefault = addConflictKeep;
end FunctionTreeImpl;

uniontype Elements
  record ELEMENTS
    list<tuple<ComponentRef, Binding>> components;
    list<Equation> equations;
    list<Equation> initialEquations;
    list<list<Statement>> algorithms;
    list<list<Statement>> initialAlgorithms;
  end ELEMENTS;
end Elements;

function flatten
  input InstNode classInst;
  input String name;
  output Elements elems;
  output FunctionTree funcs;
protected
  list<tuple<ComponentRef, Binding>> comps;
  Sections sections;
  list<Equation> eql, ieql;
  list<list<Statement>> alg, ialg;
algorithm
  sections := Sections.EMPTY();

  (comps, sections) :=
    flattenClass(InstNode.getClass(classInst), ComponentRef.EMPTY(), {}, sections);
  comps := listReverseInPlace(comps);

  elems := match sections
    case Sections.SECTIONS()
      algorithm
        eql := listReverseInPlace(sections.equations);
        ieql := listReverseInPlace(sections.initialEquations);
        alg := listReverseInPlace(sections.algorithms);
        ialg := listReverseInPlace(sections.initialAlgorithms);
      then
        ELEMENTS(comps, eql, ieql, alg, ialg);

    else ELEMENTS(comps, {}, {}, {}, {});
  end match;

  funcs := flattenFunctions(elems);

  execStat(getInstanceName() + "(" + name + ")");
end flatten;

protected
function flattenClass
  input Class cls;
  input ComponentRef prefix;
  input output list<tuple<ComponentRef, Binding>> comps;
  input output Sections sections;
protected
  ClassTree cls_tree;
algorithm
  () := match cls
    case Class.INSTANCED_CLASS(elements = cls_tree as ClassTree.FLAT_TREE())
      algorithm
        for c in cls_tree.components loop
          (comps, sections) := flattenComponent(c, prefix, comps, sections);
        end for;

        sections := flattenSections(cls.sections, prefix, sections);
      then
        ();

    else
      algorithm
        print("Got non-instantiated component " + ComponentRef.toString(prefix) + "\n");
      then
        ();

  end match;
end flattenClass;

function flattenComponent
  input InstNode component;
  input ComponentRef prefix;
  input output list<tuple<ComponentRef, Binding>> comps;
  input output Sections sections;
protected
  InstNode comp_node;
  Component c;
  Type ty;
  ComponentRef new_pre;
  Binding binding;
  list<Dimension> dims;
  Class cls;
algorithm
  // Remove components that are only outer.
  if InstNode.isOnlyOuter(component) then
    return;
  end if;

  comp_node := InstNode.resolveOuter(component);
  c := InstNode.component(comp_node);

  () := match c
    case Component.TYPED_COMPONENT(ty = ty)
      algorithm
        new_pre := ComponentRef.prefixCref(comp_node, ty, {}, prefix);
        cls := InstNode.getClass(c.classInst);

        () := match cls
          // If the component is of a builtin type, add it to the component list
          // along with its binding.
          case Class.INSTANCED_BUILTIN()
            algorithm
              binding := flattenBinding(c.binding, prefix);

              if Type.isArray(ty) and Binding.isBound(binding) and Component.isVar(c) then
                comps := (new_pre, Binding.UNBOUND()) :: comps;
                sections := Sections.prependEquation(
                  Equation.ARRAY_EQUALITY(Expression.CREF(ty, new_pre), Binding.getTypedExp(binding), ty, c.info),
                  sections);
              else
                comps := (new_pre, binding) :: comps;
              end if;
            then
              ();

          // If the component is of a complex type, either flatten its class
          // directly if it's a scalar or vectorize it if it's an array.
          else
            algorithm
              dims := Type.arrayDims(ty);

              if listEmpty(dims) then
                (comps, sections) := flattenClass(cls, new_pre, comps, sections);
              else
                (comps, sections) := flattenArray(cls, dims, new_pre, comps, sections);
              end if;
            then
              ();
        end match;
      then
        ();

    else
      algorithm
        assert(false, getInstanceName() + " got unknown component");
      then
        fail();

  end match;
end flattenComponent;

function flattenArray
  input Class cls;
  input list<Dimension> dimensions;
  input ComponentRef prefix;
  input output list<tuple<ComponentRef, Binding>> comps;
  input output Sections sections;
  input list<Subscript> subscripts = {};
protected
  Dimension dim;
  list<Dimension> rest_dims;
  ComponentRef sub_pre;
  RangeIterator range_iter;
  Expression sub_exp;
algorithm
  if listEmpty(dimensions) then
    sub_pre := ComponentRef.setSubscripts(listReverse(subscripts), prefix);
    (comps, sections) := flattenClass(cls, sub_pre, comps, sections);
  else
    dim :: rest_dims := dimensions;
    range_iter := RangeIterator.fromDim(dim);

    while RangeIterator.hasNext(range_iter) loop
      (range_iter, sub_exp) := RangeIterator.next(range_iter);
      (comps, sections) := flattenArray(cls, rest_dims, prefix, comps, sections,
        Subscript.INDEX(sub_exp) :: subscripts);
    end while;
  end if;
end flattenArray;

function flattenBinding
  input output Binding binding;
  input ComponentRef prefix;
algorithm
  () := match binding
    local
      list<Subscript> subs;

    case Binding.UNBOUND() then ();

    case Binding.TYPED_BINDING()
      algorithm
        if binding.propagatedLevels > 0 then
          subs := List.flatten(ComponentRef.subscriptsN(prefix, binding.propagatedLevels));
          binding.bindingExp := Expression.subscript(binding.bindingExp, subs);
        end if;
      then
        ();

    else
      algorithm
        assert(false, getInstanceName() + " got untyped binding.");
      then
        fail();

  end match;
end flattenBinding;

function flattenExp
  input output Expression exp;
  input ComponentRef prefix;
algorithm
  exp := Expression.map(exp, function flattenExp_traverse(prefix = prefix));
end flattenExp;

function flattenExp_traverse
  input output Expression exp;
  input ComponentRef prefix;
algorithm
  exp := match exp
    case Expression.CREF()
      algorithm
        exp.cref := ComponentRef.transferSubscripts(prefix, exp.cref);
      then
        exp;

    else exp;
  end match;
end flattenExp_traverse;

function flattenSections
  input Sections sections;
  input ComponentRef prefix;
  input output Sections accumSections;
algorithm
  () := match sections
    local
      list<Equation> eq, ieq;
      list<list<Statement>> alg, ialg;

    case Sections.SECTIONS()
      algorithm
        eq := flattenEquations(sections.equations, prefix);
        ieq := flattenEquations(sections.initialEquations, prefix);
        alg := flattenAlgorithms(sections.algorithms, prefix);
        ialg := flattenAlgorithms(sections.initialAlgorithms, prefix);
        accumSections := Sections.prepend(eq, ieq, alg, ialg, accumSections);
      then
        ();

    else ();
  end match;
end flattenSections;

function flattenEquations
  input output list<Equation> equations;
  input ComponentRef prefix;
algorithm
  equations := listReverse(flattenEquation(eq, prefix) for eq in equations);
end flattenEquations;

function flattenEquation
  input output Equation eq;
  input ComponentRef prefix;
algorithm
  eq := match eq
    local
      Expression e1, e2, e3;

    case Equation.EQUALITY()
      algorithm
        e1 := flattenExp(eq.lhs, prefix);
        e2 := flattenExp(eq.rhs, prefix);
      then
        Equation.EQUALITY(e1, e2, eq.ty, eq.info);

    case Equation.FOR()
      algorithm
        eq.body := flattenEquations(eq.body, prefix);
      then
        eq;

    case Equation.IF()
      algorithm
        eq.branches := list(flattenEqBranch(b, prefix) for b in eq.branches);
      then
        eq;

    case Equation.WHEN()
      algorithm
        eq.branches := list(flattenEqBranch(b, prefix) for b in eq.branches);
      then
        eq;

    case Equation.ASSERT()
      algorithm
        e1 := flattenExp(eq.condition, prefix);
        e2 := flattenExp(eq.message, prefix);
        e3 := flattenExp(eq.level, prefix);
      then
        Equation.ASSERT(e1, e2, e3, eq.info);

    case Equation.TERMINATE()
      algorithm
        e1 := flattenExp(eq.message, prefix);
      then
        Equation.TERMINATE(e1, eq.info);

    case Equation.REINIT()
      algorithm
        e1 := flattenExp(eq.cref, prefix);
        e2 := flattenExp(eq.reinitExp, prefix);
      then
        Equation.REINIT(e1, e2, eq.info);

    case Equation.NORETCALL()
      algorithm
        e1 := flattenExp(eq.exp, prefix);
      then
        Equation.NORETCALL(e1, eq.info);

    else eq;
  end match;
end flattenEquation;

function flattenEqBranch
  input output tuple<Expression, list<Equation>> branch;
  input ComponentRef prefix;
protected
  Expression exp;
  list<Equation> eql;
algorithm
  (exp, eql) := branch;
  exp := flattenExp(exp, prefix);
  eql := flattenEquations(eql, prefix);
  branch := (exp, eql);
end flattenEqBranch;

function flattenAlgorithms
  input output list<list<Statement>> algorithms;
  input ComponentRef prefix;
algorithm
  algorithms := listReverse(flattenStatements(alg, prefix) for alg in algorithms);
end flattenAlgorithms;

function flattenStatements
  input output list<Statement> statements;
  input ComponentRef prefix;
algorithm
  statements := list(flattenStatement(s, prefix) for s in statements);
end flattenStatements;

function flattenStatement
  input output Statement stmt;
  input ComponentRef prefix;
algorithm
  stmt := match stmt
    local
      Expression e1, e2, e3;

    case Statement.ASSIGNMENT()
      algorithm
        e1 := flattenExp(stmt.lhs, prefix);
        e2 := flattenExp(stmt.rhs, prefix);
      then
        Statement.ASSIGNMENT(e1, e2, stmt.info);

    case Statement.FOR()
      algorithm
        stmt.body := flattenStatements(stmt.body, prefix);
      then
        stmt;

    case Statement.IF()
      algorithm
        stmt.branches := list(flattenStmtBranch(b, prefix) for b in stmt.branches);
      then
        stmt;

    case Statement.WHEN()
      algorithm
        stmt.branches := list(flattenStmtBranch(b, prefix) for b in stmt.branches);
      then
        stmt;

    case Statement.ASSERT()
      algorithm
        e1 := flattenExp(stmt.condition, prefix);
        e2 := flattenExp(stmt.message, prefix);
        e3 := flattenExp(stmt.level, prefix);
      then
        Statement.ASSERT(e1, e2, e3, stmt.info);

    case Statement.TERMINATE()
      algorithm
        e1 := flattenExp(stmt.message, prefix);
      then
        Statement.TERMINATE(e1, stmt.info);

    case Statement.NORETCALL()
      algorithm
        e1 := flattenExp(stmt.exp, prefix);
      then
        Statement.NORETCALL(e1, stmt.info);

    case Statement.WHILE()
      algorithm
        stmt.condition := flattenExp(stmt.condition, prefix);
        stmt.body := flattenStatements(stmt.body, prefix);
      then
        stmt;

    case Statement.FAILURE()
      algorithm
        stmt.body := flattenStatements(stmt.body, prefix);
      then
        stmt;

    else stmt;
  end match;
end flattenStatement;

function flattenStmtBranch
  input output tuple<Expression, list<Statement>> branch;
  input ComponentRef prefix;
protected
  Expression exp;
  list<Statement> stmtl;
algorithm
  (exp, stmtl) := branch;
  exp := flattenExp(exp, prefix);
  stmtl := flattenStatements(stmtl, prefix);
  branch := (exp, stmtl);
end flattenStmtBranch;

function flattenFunctions
  input Elements elems;
  output FunctionTree funcs;
algorithm
  funcs := FunctionTree.new();
  funcs := List.fold(elems.components, collectComponentFuncs, funcs);
  funcs := List.fold(elems.equations, collectEquationFuncs, funcs);
  funcs := List.fold(elems.initialEquations, collectEquationFuncs, funcs);
  funcs := List.fold(elems.algorithms, collectAlgorithmFuncs, funcs);
  funcs := List.fold(elems.initialAlgorithms, collectAlgorithmFuncs, funcs);
end flattenFunctions;

function collectComponentFuncs
  input tuple<ComponentRef, Binding> component;
  input output FunctionTree funcs;
protected
  Binding binding;
algorithm
  (_, binding) := component;

  if Binding.isBound(binding) then
    funcs := collectExpFuncs(Binding.getTypedExp(binding), funcs);
  end if;
end collectComponentFuncs;

function collectEquationFuncs
  input Equation eq;
  input output FunctionTree funcs;
algorithm
  () := match eq
    case Equation.EQUALITY()
      algorithm
        funcs := collectExpFuncs(eq.lhs, funcs);
        funcs := collectExpFuncs(eq.rhs, funcs);
      then
        ();

    case Equation.ARRAY_EQUALITY()
      algorithm
        // Lhs is always a cref, no need to check it.
        funcs := collectExpFuncs(eq.rhs, funcs);
      then
        ();

    case Equation.FOR()
      algorithm
        funcs := List.fold(eq.body, collectEquationFuncs, funcs);
      then
        ();

    case Equation.IF()
      algorithm
        funcs := List.fold(eq.branches, collectEqBranchFuncs, funcs);
      then
        ();

    case Equation.WHEN()
      algorithm
        funcs := List.fold(eq.branches, collectEqBranchFuncs, funcs);
      then
        ();

    case Equation.ASSERT()
      algorithm
        funcs := collectExpFuncs(eq.condition, funcs);
        funcs := collectExpFuncs(eq.message, funcs);
        funcs := collectExpFuncs(eq.level, funcs);
      then
        ();

    case Equation.TERMINATE()
      algorithm
        funcs := collectExpFuncs(eq.message, funcs);
      then
        ();

    case Equation.REINIT()
      algorithm
        funcs := collectExpFuncs(eq.reinitExp, funcs);
      then
        ();

    case Equation.NORETCALL()
      algorithm
        funcs := collectExpFuncs(eq.exp, funcs);
      then
        ();

    else ();
  end match;
end collectEquationFuncs;

function collectEqBranchFuncs
  input tuple<Expression, list<Equation>> branch;
  input output FunctionTree funcs;
algorithm
  funcs := collectExpFuncs(Util.tuple21(branch), funcs);
  funcs := List.fold(Util.tuple22(branch), collectEquationFuncs, funcs);
end collectEqBranchFuncs;

function collectAlgorithmFuncs
  input list<Statement> alg;
  input output FunctionTree funcs;
algorithm
  funcs := List.fold(alg, collectStatementFuncs, funcs);
end collectAlgorithmFuncs;

function collectStatementFuncs
  input Statement stmt;
  input output FunctionTree funcs;
algorithm
  () := match stmt
    case Statement.ASSIGNMENT()
      algorithm
        funcs := collectExpFuncs(stmt.lhs, funcs);
        funcs := collectExpFuncs(stmt.rhs, funcs);
      then
        ();

    case Statement.FOR()
      algorithm
        funcs := List.fold(stmt.body, collectStatementFuncs, funcs);
      then
        ();

    case Statement.IF()
      algorithm
        funcs := List.fold(stmt.branches, collectStmtBranchFuncs, funcs);
      then
        ();

    case Statement.WHEN()
      algorithm
        funcs := List.fold(stmt.branches, collectStmtBranchFuncs, funcs);
      then
        ();

    case Statement.ASSERT()
      algorithm
        funcs := collectExpFuncs(stmt.condition, funcs);
        funcs := collectExpFuncs(stmt.message, funcs);
        funcs := collectExpFuncs(stmt.level, funcs);
      then
        ();

    case Statement.TERMINATE()
      algorithm
        funcs := collectExpFuncs(stmt.message, funcs);
      then
        ();

    case Statement.NORETCALL()
      algorithm
        funcs := collectExpFuncs(stmt.exp, funcs);
      then
        ();

    case Statement.WHILE()
      algorithm
        funcs := collectExpFuncs(stmt.condition, funcs);
        funcs := List.fold(stmt.body, collectStatementFuncs, funcs);
      then
        ();

    else ();
  end match;
end collectStatementFuncs;

function collectStmtBranchFuncs
  input tuple<Expression, list<Statement>> branch;
  input output FunctionTree funcs;
algorithm
  funcs := collectExpFuncs(Util.tuple21(branch), funcs);
  funcs := List.fold(Util.tuple22(branch), collectStatementFuncs, funcs);
end collectStmtBranchFuncs;

function collectExpFuncs
  input Expression exp;
  input output FunctionTree funcs;
algorithm
  funcs := Expression.fold(exp, collectExpFuncs_traverse, funcs);
end collectExpFuncs;

function collectExpFuncs_traverse
  input Expression exp;
  input output FunctionTree funcs;
algorithm
  () := match exp
    case Expression.CALL()
      algorithm
        funcs := flattenFunction(Call.typedFunction(exp.call), funcs);
      then
        ();

    else ();
  end match;
end collectExpFuncs_traverse;

function flattenFunction
  input Function fn;
  input output FunctionTree funcs;
algorithm
  if not Function.isCollected(fn) then
    Function.collect(fn);
    funcs := FunctionTree.add(funcs, Function.name(fn), fn);
  end if;
end flattenFunction;

annotation(__OpenModelica_Interface="frontend");
end NFFlatten;
