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
  import Ceval = NFCeval;

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
    constants := List.fold(elements.components, collectComponentConstants, constants);
    constants := Equation.foldExpList(elements.equations, collectExpConstants, constants);
    constants := Equation.foldExpList(elements.initialEquations, collectExpConstants, constants);

    for alg in elements.algorithms loop
      constants := Statement.foldExpList(alg, collectExpConstants, constants);
    end for;

    for alg in elements.initialAlgorithms loop
      constants := Statement.foldExpList(alg, collectExpConstants, constants);
    end for;

    for c in Constants.listKeys(constants) loop
      binding := Component.getBinding(InstNode.component(ComponentRef.node(c)));
      comps := (c, binding) :: comps;
    end for;

    elements.components := listAppend(comps, elements.components);

    execStat(getInstanceName());
  end collectConstants;

  function replaceConstants
    input output Elements elements;
  algorithm
    elements.components := list(replaceComponentConstants(c) for c in elements.components);
    elements.equations := list(Equation.mapExp(eq, replaceExpConstants) for eq in elements.equations);
    elements.initialEquations := list(Equation.mapExp(eq, replaceExpConstants) for eq in elements.initialEquations);
    elements.algorithms := list(Statement.mapExpList(s, replaceExpConstants) for s in elements.algorithms);
    elements.initialAlgorithms := list(Statement.mapExpList(s, replaceExpConstants) for s in elements.initialAlgorithms);
    execStat(getInstanceName());
  end replaceConstants;

  function collectComponentConstants
    input tuple<ComponentRef, Binding> component;
    input output Constants constants;
  protected
    Binding binding;
  algorithm
    (_, binding) := component;

    if Binding.isBound(binding) then
      constants := collectExpConstants(Binding.getTypedExp(binding), constants);
    end if;

    // TODO: The component's attributes (i.e. start, etc) might also contain
    //       package constants.
  end collectComponentConstants;

  function collectBindingConstants
    input Binding binding;
    input output Constants constants;
  algorithm
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
              Component.getBinding(InstNode.component(ComponentRef.node(cref))),
              constants);
          end if;
        then
          ();

      else ();
    end match;
  end collectExpConstants_traverser;

  function replaceComponentConstants
    input output tuple<ComponentRef, Binding> component;
  protected
    ComponentRef cref;
    Binding binding;
  algorithm
    (cref, binding) := component;
    component := (cref, replaceBindingConstants(binding));
  end replaceComponentConstants;

  function replaceBindingConstants
    input output Binding binding;
  algorithm
    () := match binding
      case Binding.TYPED_BINDING()
        algorithm
          binding.bindingExp := replaceExpConstants(binding.bindingExp);
        then
          ();

      else ();
    end match;
  end replaceBindingConstants;

  function replaceExpConstants
    input output Expression exp;
  algorithm
    exp := Expression.map(exp, replaceExpConstants_traverser);
  end replaceExpConstants;

  function replaceExpConstants_traverser
    input output Expression exp;
  protected
    ComponentRef cref;
  algorithm
    exp := match exp
      case Expression.CREF(cref = cref as ComponentRef.CREF())
        then if ComponentRef.isPackageConstant(cref) then
          Ceval.evalExp(exp, Ceval.EvalTarget.IGNORE_ERRORS()) else exp;

      else exp;
    end match;
  end replaceExpConstants_traverser;

annotation(__OpenModelica_Interface="frontend");
end NFPackage;
