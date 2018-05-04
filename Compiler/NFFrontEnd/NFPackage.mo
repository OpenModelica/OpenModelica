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
  import FlatModel = NFFlatModel;
  import NFFlatten.FunctionTree;

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
  import NFFunction.Function;
  import NFClass.Class;
  import Sections = NFSections;
  import ClassTree = NFClassTree;
  import NFTyping.ExpOrigin;
  import Variable = NFVariable;

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
    input output FlatModel flatModel;
    input FunctionTree functions;
  protected
    list<Variable> vars = {};
    Binding binding;
    Constants constants;
  algorithm
    constants := Constants.new();
    constants := List.fold(flatModel.variables, collectVariableConstants, constants);
    constants := Equation.foldExpList(flatModel.equations, collectExpConstants, constants);
    constants := Equation.foldExpList(flatModel.initialEquations, collectExpConstants, constants);
    constants := Statement.foldExpListList(flatModel.algorithms, collectExpConstants, constants);
    constants := Statement.foldExpListList(flatModel.initialAlgorithms, collectExpConstants, constants);
    constants := FunctionTree.fold(functions, collectFuncConstants, constants);

    vars := listReverse(Variable.fromCref(c) for c in Constants.listKeys(constants));
    flatModel.variables := listAppend(vars, flatModel.variables);

    execStat(getInstanceName());
  end collectConstants;

  function replaceConstants
    input output FlatModel flatModel;
    input output FunctionTree functions;
  algorithm
    flatModel.variables := list(replaceVariableConstants(c) for c in flatModel.variables);
    flatModel.equations := Equation.mapExpList(flatModel.equations, replaceExpConstants);
    flatModel.initialEquations := Equation.mapExpList(flatModel.initialEquations, replaceExpConstants);
    flatModel.algorithms := Statement.mapExpListList(flatModel.algorithms, replaceExpConstants);
    flatModel.initialAlgorithms := Statement.mapExpListList(flatModel.initialAlgorithms, replaceExpConstants);
    functions := FunctionTree.map(functions, replaceFuncConstants);
    execStat(getInstanceName());
  end replaceConstants;

  function collectVariableConstants
    input Variable var;
    input output Constants constants;
  algorithm
    if Binding.isBound(var.binding) then
      constants := collectExpConstants(Binding.getTypedExp(var.binding), constants);
    end if;

    // TODO: The component's attributes (i.e. start, etc) might also contain
    //       package constants.
  end collectVariableConstants;

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
            Typing.typeComponentBinding(cref.node, ExpOrigin.CLASS);
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

  function collectFuncConstants
    input Absyn.Path name;
    input Function func;
    input output Constants constants;
  protected
    Class cls;
    array<InstNode> comps;
    Sections sections;
  algorithm
    cls := InstNode.getClass(func.node);

    () := match cls
      case Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps),
                                 sections = sections)
        algorithm
          for c in comps loop
            if not InstNode.isEmpty(c) then
              constants := collectBindingConstants(
                Component.getBinding(InstNode.component(c)), constants);
            end if;
          end for;

          () := match sections
            case Sections.SECTIONS()
              algorithm
                constants := Statement.foldExpListList(sections.algorithms, collectExpConstants, constants);
              then
                ();

            case Sections.EXTERNAL()
              algorithm
                for arg in sections.args loop
                  constants := collectExpConstants(arg, constants);
                end for;
              then
                ();

            else ();
          end match;
        then
          ();

      else ();
    end match;
  end collectFuncConstants;

  function replaceVariableConstants
    input output Variable var;
  protected
    ComponentRef cref;
    Binding binding;
  algorithm
    binding := replaceBindingConstants(var.binding);

    if not referenceEq(binding, var.binding) then
      var.binding := binding;
    end if;
  end replaceVariableConstants;

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

  function replaceFuncConstants
    input Absyn.Path name;
    input output Function func;
  protected
    Class cls;
    array<InstNode> comps;
    Sections sections;
    Component comp;
    Binding binding, eval_binding;
  algorithm
    cls := InstNode.getClass(func.node);

    () := match cls
      case Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps),
                                 sections = sections)
        algorithm
          for c in comps loop
            comp := InstNode.component(c);
            binding := Component.getBinding(comp);
            eval_binding := replaceBindingConstants(binding);

            if not referenceEq(binding, eval_binding) then
              comp := Component.setBinding(eval_binding, comp);
              InstNode.updateComponent(comp, c);
            end if;
          end for;

          () := match sections
            case Sections.SECTIONS()
              algorithm
                sections.algorithms := Statement.mapExpListList(sections.algorithms, replaceExpConstants);
                cls.sections := sections;
                InstNode.updateClass(cls, func.node);
              then
                ();

            else ();
          end match;
        then
          ();

    end match;
  end replaceFuncConstants;

annotation(__OpenModelica_Interface="frontend");
end NFPackage;
