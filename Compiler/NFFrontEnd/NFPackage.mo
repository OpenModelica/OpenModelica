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

encapsulated package NFPackage
  import NFFlatten.Elements;

protected
  import ExecStat.execStat;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import Binding = NFBinding;
  import Equation = NFEquation;
  import Statement = NFStatement;
  import List;
  import NFComponent.Component;
  import NFInstNode.InstNode;
  import Typing = NFTyping;

public
  type Constants = ConstantsSetImpl.Tree;

  encapsulated package ConstantsSetImpl
    import BaseAvlSet;
    import ComponentRef = NFComponentRef;
    extends BaseAvlSet;

    redeclare type Key = ComponentRef;

    redeclare function extends keyStr
    algorithm
      outString := ComponentRef.toString(inKey);
    end keyStr;

    redeclare function extends keyCompare
    algorithm
      outResult := ComponentRef.compare(inKey1, inKey2);
    end keyCompare;
  end ConstantsSetImpl;

public
  function collectConstants
    input output Elements elements;
  protected
    list<tuple<ComponentRef, Binding>> comps = {};
    Binding binding;
    Constants constants;
  algorithm
    constants := Constants.new();
    constants := List.fold(elements.components, collectBindingConstants, constants);
    constants := List.fold(elements.equations, collectEquationConstants, constants);
    constants := List.fold(elements.initialEquations, collectEquationConstants, constants);
    constants := List.fold(elements.algorithms, collectAlgorithmConstants, constants);
    constants := List.fold(elements.initialAlgorithms, collectAlgorithmConstants, constants);

    for c in Constants.listKeys(constants) loop
      binding := Component.getBinding(InstNode.component(ComponentRef.node(c)));
      comps := (c, binding) :: comps;
    end for;

    elements.components := listAppend(comps, elements.components);

    execStat(getInstanceName());
  end collectConstants;

protected
  function collectBindingConstants
    input tuple<ComponentRef, Binding> component;
    input output Constants constants;
  protected
    Binding binding;
  algorithm
    (_, binding) := component;

    if Binding.isBound(binding) then
      constants := collectExpConstants(Binding.getTypedExp(binding), constants);
    end if;
  end collectBindingConstants;

  function collectExpConstants
    input Expression exp;
    input output Constants constants;
  algorithm
    constants := Expression.fold(exp, collectExpConstants_traverser, constants);
  end collectExpConstants;

  function collectExpConstants_traverser
    input Expression exp;
    input output Constants constants;
  protected
    ComponentRef cref;
  algorithm
    () := match exp
      case Expression.CREF(cref = cref as ComponentRef.CREF())
        algorithm
          if ComponentRef.isPackageConstant(cref) then
            Typing.typeComponentBinding(cref.node);
            // Add the constant to the set.
            constants := Constants.add(constants, ComponentRef.stripSubscriptsAll(cref));
            // Collect constants from the constant's binding.
            constants := collectBindingConstants(
              (cref, Component.getBinding(InstNode.component(ComponentRef.node(cref)))),
              constants);
          end if;
        then
          ();

      else ();
    end match;
  end collectExpConstants_traverser;

  function collectEquationConstants
    input Equation eq;
    input output Constants constants;
  algorithm
    () := match eq
      case Equation.EQUALITY()
        algorithm
          constants := collectExpConstants(eq.lhs, constants);
          constants := collectExpConstants(eq.rhs, constants);
        then
          ();

      case Equation.CREF_EQUALITY()
        algorithm
          // TODO: The crefs can have subscripts with constants.
        then
          ();

      case Equation.ARRAY_EQUALITY()
        algorithm
          constants := collectExpConstants(eq.lhs, constants);
          constants := collectExpConstants(eq.rhs, constants);
        then
          ();

      case Equation.CONNECT()
        algorithm
          constants := collectExpConstants(eq.lhs, constants);
          constants := collectExpConstants(eq.rhs, constants);
        then
          ();

      case Equation.FOR()
        algorithm
          constants := List.fold(eq.body, collectEquationConstants, constants);
        then
          ();

      case Equation.IF()
        algorithm
          for b in eq.branches loop
            constants := collectExpConstants(Util.tuple21(b), constants);
            constants := List.fold(Util.tuple22(b), collectEquationConstants, constants);
          end for;
        then
          ();

      case Equation.WHEN()
        algorithm
          for b in eq.branches loop
            constants := collectExpConstants(Util.tuple21(b), constants);
            constants := List.fold(Util.tuple22(b), collectEquationConstants, constants);
          end for;
        then
          ();

      case Equation.ASSERT()
        algorithm
          constants := collectExpConstants(eq.condition, constants);
          constants := collectExpConstants(eq.message, constants);
          constants := collectExpConstants(eq.level, constants);
        then
          ();

      case Equation.TERMINATE()
        algorithm
          constants := collectExpConstants(eq.message, constants);
        then
          ();

      case Equation.REINIT()
        algorithm
          constants := collectExpConstants(eq.cref, constants);
          constants := collectExpConstants(eq.reinitExp, constants);
        then
          ();

      case Equation.NORETCALL()
        algorithm
          constants := collectExpConstants(eq.exp, constants);
        then
          ();

      else
        algorithm
          assert(false, getInstanceName() + " failed on unknown equation");
        then
          ();

    end match;
  end collectEquationConstants;

  function collectAlgorithmConstants
    input list<Statement> alg;
    input output Constants constants;
  algorithm
    constants := List.fold(alg, collectStatementConstants, constants);
  end collectAlgorithmConstants;

  function collectStatementConstants
    input Statement stmt;
    input output Constants constants;
  algorithm
    () := match stmt
      case Statement.ASSIGNMENT()
        algorithm
          constants := collectExpConstants(stmt.lhs, constants);
          constants := collectExpConstants(stmt.rhs, constants);
        then
          ();

      case Statement.FOR()
        algorithm
          constants := collectAlgorithmConstants(stmt.body, constants);
        then
          ();

      case Statement.IF()
        algorithm
          for b in stmt.branches loop
            constants := collectExpConstants(Util.tuple21(b), constants);
            constants := collectAlgorithmConstants(Util.tuple22(b), constants);
          end for;
        then
          ();

      case Statement.WHEN()
        algorithm
          for b in stmt.branches loop
            constants := collectExpConstants(Util.tuple21(b), constants);
            constants := collectAlgorithmConstants(Util.tuple22(b), constants);
          end for;
        then
          ();

      case Statement.ASSERT()
        algorithm
          constants := collectExpConstants(stmt.condition, constants);
          constants := collectExpConstants(stmt.message, constants);
          constants := collectExpConstants(stmt.level, constants);
        then
          ();

      case Statement.TERMINATE()
        algorithm
          constants := collectExpConstants(stmt.message, constants);
        then
          ();

      case Statement.NORETCALL()
        algorithm
          constants := collectExpConstants(stmt.exp, constants);
        then
          ();

      case Statement.WHILE()
        algorithm
          constants := collectExpConstants(stmt.condition, constants);
          constants := collectAlgorithmConstants(stmt.body, constants);
        then
          ();

      else ();
    end match;
  end collectStatementConstants;

annotation(__OpenModelica_Interface="frontend");
end NFPackage;
