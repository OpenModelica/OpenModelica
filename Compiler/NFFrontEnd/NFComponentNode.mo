
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

encapsulated package NFComponentNode

import NFComponent.Component;
import NFInstNode.InstNode;
import NFMod.Modifier;
import NFPrefix.Prefix;
import SCode.Element;

uniontype ComponentNode
  record COMPONENT_NODE
    String name;
    Element definition;
    array<Component> component;
    ComponentNode parent;
  end COMPONENT_NODE;

  record EMPTY_NODE end EMPTY_NODE;

  function new
    input String name;
    input Element definition;
    input ComponentNode parent = EMPTY_NODE();
    output ComponentNode node;
  protected
    array<Component> c;
  algorithm
    c := arrayCreate(1, Component.COMPONENT_DEF(definition, Modifier.NOMOD()));
    node := COMPONENT_NODE(name, definition, c, parent);
  end new;

  function newExtends
    input InstNode extendsNode;
    input Element definition;
    output ComponentNode node;
  protected
    array<Component> c;
  algorithm
    c := arrayCreate(1, Component.EXTENDS_NODE(extendsNode));
    node := COMPONENT_NODE("", definition, c, EMPTY_NODE());
  end newExtends;

  function newReference
    input output ComponentNode component;
    input Integer nodeIndex;
    input Integer componentIndex;
  algorithm
    component := replaceComponent(Component.COMPONENT_REF(nodeIndex, componentIndex), component);
  end newReference;

  function name
    input ComponentNode node;
    output String name;
  algorithm
    COMPONENT_NODE(name = name) := node;
  end name;

  function rename
    input output ComponentNode node;
    input String name;
  algorithm
    () := match node
      case COMPONENT_NODE()
        algorithm
          node.name := name;
        then
          ();
    end match;
  end rename;

  function parent
    input ComponentNode node;
    output ComponentNode parentNode;
  algorithm
    COMPONENT_NODE(parent = parentNode) := node;
  end parent;

  function topComponent
    input ComponentNode node;
    output ComponentNode topComponent;
  algorithm
    topComponent := match node
      case COMPONENT_NODE(parent = EMPTY_NODE()) then node;
      case COMPONENT_NODE() then topComponent(node.parent);
    end match;
  end topComponent;

  function setParent
    input ComponentNode parent;
    input output ComponentNode node;
  algorithm
    () := match node
      case COMPONENT_NODE()
        algorithm
          node.parent := parent;
        then
          ();
    end match;
  end setParent;

  function component
    input ComponentNode node;
    output Component component;
  algorithm
    component := match node
      case COMPONENT_NODE() then node.component[1];
    end match;
  end component;

  function updateComponent
    input Component component;
    input output ComponentNode node;
  algorithm
    node := match node
      case COMPONENT_NODE()
        algorithm
          arrayUpdate(node.component, 1, component);
        then
          node;
    end match;
  end updateComponent;

  function replaceComponent
    input Component component;
    input output ComponentNode node;
  algorithm
    _ := match node
      case COMPONENT_NODE()
        algorithm
          node.component := arrayCreate(1, component);
        then
          ();
    end match;
  end replaceComponent;

  function definition
    input ComponentNode node;
    output SCode.Element definition;
  algorithm
    COMPONENT_NODE(definition = definition) := node;
  end definition;

  function setDefinition
    input SCode.Element definition;
    input output ComponentNode node;
  algorithm
    () := match node
      case COMPONENT_NODE()
        algorithm
          node.definition := definition;
        then
          ();
    end match;
  end setDefinition;

  function info
    input ComponentNode node;
    output SourceInfo info;
  algorithm
    info := match node
      case COMPONENT_NODE() then SCode.elementInfo(node.definition);
      else Absyn.dummyInfo;
    end match;
  end info;

  function clone
    input output ComponentNode node;
  algorithm
    () := match node
      case COMPONENT_NODE()
        algorithm
          node.component := arrayCopy(node.component);
        then
          ();

      else ();
    end match;
  end clone;

  function apply<ArgT>
    input output ComponentNode node;
    input FuncType func;
    input ArgT arg;

    partial function FuncType
      input ArgT arg;
      input output Component node;
    end FuncType;
  algorithm
    () := match node
      case COMPONENT_NODE()
        algorithm
          node.component[1] := func(arg, node.component[1]);
        then
          ();
    end match;
  end apply;

  function instPrefix
    input ComponentNode node;
    input output Prefix prefix = Prefix.NO_PREFIX();
  algorithm
    prefix := match node
      case COMPONENT_NODE(parent = EMPTY_NODE()) then prefix;

      case COMPONENT_NODE()
        algorithm
          prefix := Prefix.add(node.name, {}, DAE.T_UNKNOWN_DEFAULT, prefix);
        then
          instPrefix(node.parent, prefix);

      else prefix;
    end match;
  end instPrefix;
end ComponentNode;

annotation(__OpenModelica_Interface="frontend");
end NFComponentNode;
