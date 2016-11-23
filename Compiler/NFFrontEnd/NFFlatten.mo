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


  New instantiation, enable with +d=newInst.
"

import Inst = NFInst;
import NFBinding.Binding;
import NFComponent.Component;
import NFComponentNode.ComponentNode;
import NFEquation.Equation;
import NFInstance.Instance;
import NFInstanceTree.InstanceTree;
import NFInstNode.InstNode;
import NFPrefix.Prefix;
import NFStatement.Statement;

import DAE;
import Error;
import Expression;
import ExpressionDump;
import SCode;
import System;
import Util;

partial function ExpandScalarFunc<ElementT>
  input ElementT element;
  input Prefix prefix;
  input output list<DAE.Element> elements;
end ExpandScalarFunc;

function flattenClass
  input InstNode classInst;
  output DAE.DAElist dae;
protected
  list<DAE.Element> elems;
  DAE.Element class_elem;
algorithm
  elems := flattenNode(classInst);
  elems := listReverse(elems);
  class_elem := DAE.COMP(InstNode.name(classInst), elems, DAE.emptyElementSource, NONE());
  dae := DAE.DAE({class_elem});
end flattenClass;

function flattenNode
  input InstNode node;
  input Prefix prefix = Prefix.NO_PREFIX();
  input list<DAE.Element> inElements = {};
  output list<DAE.Element> elements;
algorithm
  elements := flattenInstance(InstNode.instance(node), prefix, inElements);
end flattenNode;

function flattenInstance
  input Instance instance;
  input Prefix prefix;
  input output list<DAE.Element> elements;
algorithm
  _ := match instance
    case Instance.INSTANCED_CLASS()
      algorithm
        for c in instance.components loop
          elements := flattenComponent(c, prefix, elements);
        end for;

        elements := flattenEquations(instance.equations, elements);
        elements := flattenInitialEquations(instance.initialEquations, elements);
        elements := flattenAlgorithms(instance.algorithms, elements);
        elements := flattenInitialAlgorithms(instance.initialAlgorithms, elements);
      then
        ();

    else
      algorithm
        print("Got non-instantiated component " + Prefix.toString(prefix) + "\n");
      then
        ();

  end match;
end flattenInstance;

function flattenComponent
  input ComponentNode component;
  input Prefix prefix;
  input output list<DAE.Element> elements;
protected
  Component c = ComponentNode.component(component);
  Prefix new_pre;
  DAE.Type ty;
algorithm
  _ := match c
    case Component.TYPED_COMPONENT()
      algorithm
        ty := Component.getType(c);
        new_pre := Prefix.add(ComponentNode.name(component), {}, ty, prefix);

        elements := match ty
          case DAE.T_ARRAY()
            then flattenArray(Component.unliftType(c), ty.dims, new_pre, flattenScalar, elements);
          else flattenScalar(c, new_pre, elements);
        end match;
      then
        ();

    case Component.EXTENDS_NODE()
      algorithm
        elements := flattenInstance(InstNode.instance(c.node), prefix, elements);
      then
        ();

    else
      algorithm
        assert(true, "flattenComponent got unknown component");
      then
        fail();

  end match;
end flattenComponent;

function flattenArray<ElementT>
  input ElementT element;
  input list<DAE.Dimension> dimensions;
  input Prefix prefix;
  input ExpandScalarFunc scalarFunc;
  input output list<DAE.Element> elements;
  input list<DAE.Subscript> subscripts = {};
protected
  DAE.Dimension dim;
  list<DAE.Dimension> rest_dims;
  Prefix sub_pre;
algorithm
  if listEmpty(dimensions) then
    sub_pre := Prefix.setSubscripts(listReverse(subscripts), prefix);
    elements := scalarFunc(element, sub_pre, elements);
  else
    dim :: rest_dims := dimensions;
    elements := match dim
      case DAE.DIM_INTEGER()
        then flattenArrayIntDim(element, dim.integer, rest_dims, prefix,
            subscripts, scalarFunc, elements);
      case DAE.DIM_ENUM()
        then flattenArrayEnumDim(element, dim.enumTypeName, dim.literals,
            rest_dims, prefix, subscripts, scalarFunc, elements);
      else
        algorithm
          print("Unknown dimension " + ExpressionDump.dimensionString(dim) +
            " in NFFlatten.flattenArray\n");
        then
          fail();
    end match;
  end if;
end flattenArray;

function flattenArrayIntDim<ElementT>
  input ElementT element;
  input Integer dimSize;
  input list<DAE.Dimension> restDims;
  input Prefix prefix;
  input list<DAE.Subscript> subscripts;
  input ExpandScalarFunc scalarFunc;
  input output list<DAE.Element> elements;
protected
  list<DAE.Subscript> subs;
algorithm
  for i in 1:dimSize loop
    subs := DAE.INDEX(DAE.ICONST(i)) :: subscripts;
    elements := flattenArray(element, restDims, prefix, scalarFunc, elements, subs);
  end for;
end flattenArrayIntDim;

function flattenArrayEnumDim<ElementT>
  input ElementT element;
  input Absyn.Path typeName;
  input list<String> literals;
  input list<DAE.Dimension> restDims;
  input Prefix prefix;
  input list<DAE.Subscript> subscripts;
  input ExpandScalarFunc scalarFunc;
  input output list<DAE.Element> elements;
protected
  Integer i = 1;
  DAE.Exp enum_exp;
  list<DAE.Subscript> subs;
algorithm
  for l in literals loop
    enum_exp := DAE.ENUM_LITERAL(Absyn.suffixPath(typeName, l), i);
    i := i + 1;

    subs := DAE.INDEX(enum_exp) :: subscripts;
    elements := flattenArray(element, restDims, prefix, scalarFunc, elements, subs);
  end for;
end flattenArrayEnumDim;

function flattenScalar
  input Component component;
  input Prefix prefix;
  input output list<DAE.Element> elements;
algorithm
  _ := match component
    local
      Instance i;
      DAE.Element var;
      DAE.ComponentRef cref;
      Component.Attributes attr;
      list<DAE.Dimension> dims;
      Option<DAE.Exp> binding_exp;

    case Component.TYPED_COMPONENT()
      algorithm
        i := InstNode.instance(component.classInst);

        elements := match i
          case Instance.INSTANCED_BUILTIN()
            algorithm
              cref := Prefix.toCref(prefix);
              binding_exp := flattenBinding(component.binding, prefix);
              attr := component.attributes;

              var := DAE.VAR(
                cref,
                attr.variability,
                attr.direction,
                DAE.NON_PARALLEL(),
                attr.visibility,
                component.ty,
                binding_exp,
                {},
                attr.connectorType,
                DAE.emptyElementSource,
                NONE(),
                NONE(),
                Absyn.NOT_INNER_OUTER());
            then
              var :: elements;

          else flattenInstance(i, prefix, elements);
        end match;
      then
        ();

    else
      algorithm
        Error.addInternalError("NFFlatten.flattenScalar got untyped component.", Absyn.dummyInfo);
      then
        fail();

  end match;
end flattenScalar;

function flattenBinding
  input Binding binding;
  input Prefix prefix;
  output Option<DAE.Exp> bindingExp;
algorithm
  bindingExp := match binding
    local
      list<DAE.Subscript> subs;

    case Binding.UNBOUND() then NONE();

    case Binding.TYPED_BINDING(propagatedDims = -1)
      then SOME(binding.bindingExp);

    case Binding.TYPED_BINDING()
      algorithm
        // TODO: Implement this in a saner way.
        subs := List.lastN(List.flatten(Prefix.allSubscripts(prefix)),
          binding.propagatedDims);
      then
        SOME(Expression.subscriptExp(binding.bindingExp, subs));

    else
      algorithm
        Error.addInternalError("Flatten.flattenBinding got untyped binding.",
          Absyn.dummyInfo);
      then
        fail();

  end match;
end flattenBinding;

function flattenEquation
  input Equation eq;
  input output list<DAE.Element> elements = {};
algorithm
  elements := match eq
    local
      DAE.Exp lhs, rhs;

    case Equation.EQUALITY()
      then DAE.EQUATION(eq.lhs, eq.rhs, DAE.emptyElementSource) :: elements;

    case Equation.IF()
      then flattenIfEquation(eq.branches, false) :: elements;

    else elements;
  end match;
end flattenEquation;

function flattenEquations
  input list<Equation> equations;
  input output list<DAE.Element> elements = {};
algorithm
  elements := List.fold(equations, flattenEquation, elements);
end flattenEquations;

function flattenInitialEquation
  input Equation eq;
  input output list<DAE.Element> elements;
algorithm
  elements := match eq
    local
      DAE.Exp lhs, rhs;

    case Equation.EQUALITY()
      then DAE.INITIALEQUATION(eq.lhs, eq.rhs, DAE.emptyElementSource) :: elements;

    case Equation.IF()
      then flattenIfEquation(eq.branches, true) :: elements;

    else elements;
  end match;
end flattenInitialEquation;

function flattenInitialEquations
  input list<Equation> equations;
  input output list<DAE.Element> elements = {};
algorithm
  elements := List.fold(equations, flattenInitialEquation, elements);
end flattenInitialEquations;

function flattenIfEquation
  input list<tuple<DAE.Exp, list<Equation>>> ifBranches;
  input Boolean isInitial;
  output DAE.Element ifEquation;
protected
  list<DAE.Exp> conditions = {};
  list<DAE.Element> branch, else_branch;
  list<list<DAE.Element>> branches = {};
algorithm
  for b in ifBranches loop
    conditions := Util.tuple21(b) :: conditions;
    branches := flattenEquations(Util.tuple22(b)) :: branches;
  end for;

  // Transform the last branch to an else-branch if its condition is true.
  if Expression.isConstTrue(listHead(conditions)) then
    conditions := listRest(conditions);
    else_branch := listHead(branches);
    branches := listRest(branches);
  else
    else_branch := {};
  end if;

  conditions := listReverse(conditions);
  branches := listReverse(branches);

  if isInitial then
    ifEquation := DAE.INITIAL_IF_EQUATION(conditions, branches, else_branch,
      DAE.emptyElementSource);
  else
    ifEquation := DAE.IF_EQUATION(conditions, branches, else_branch,
      DAE.emptyElementSource);
  end if;
end flattenIfEquation;

function flattenAlgorithm
  input list<Statement> algSection;
  input output list<DAE.Element> elements;
algorithm

end flattenAlgorithm;

function flattenAlgorithms
  input list<list<Statement>> algorithms;
  input output list<DAE.Element> elements = {};
algorithm
  elements := List.fold(algorithms, flattenAlgorithm, elements);
end flattenAlgorithms;

function flattenInitialAlgorithm
  input list<Statement> algSection;
  input output list<DAE.Element> elements;
algorithm

end flattenInitialAlgorithm;

function flattenInitialAlgorithms
  input list<list<Statement>> algorithms;
  input output list<DAE.Element> elements = {};
algorithm
  elements := List.fold(algorithms, flattenInitialAlgorithm, elements);
end flattenInitialAlgorithms;

annotation(__OpenModelica_Interface="frontend");
end NFFlatten;
