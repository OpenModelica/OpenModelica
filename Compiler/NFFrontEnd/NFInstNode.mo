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

encapsulated package NFInstNode

import NFComponent.Component;
import NFInst.Instance;
import SCode;

uniontype InstParent
  record CLASS
    InstNode node;
  end CLASS;

  record COMPONENT
    Component component;
  end COMPONENT;

  record NO_PARENT end NO_PARENT;

  function isEmpty
    input InstParent parent;
    output Boolean empty;
  algorithm
    empty := match parent
      case NO_PARENT() then true;
      else false;
    end match;
  end isEmpty;
end InstParent;

uniontype InstNodeType
  record NORMAL_CLASS end NORMAL_CLASS;

  record EXTENDS
    InstNode parent;
  end EXTENDS;

  record TOP_SCOPE end TOP_SCOPE;
end InstNodeType;

uniontype InstNode
  record INST_NODE
    String name;
    SCode.Element definition;
    array<Instance> instance;
    InstNode parentScope;
    InstNodeType nodeType;
  end INST_NODE;

  record EMPTY_NODE end EMPTY_NODE;

  function new
    input String name;
    input SCode.Element definition;
    input InstNode parent;
    input InstNodeType nodeType = NORMAL_CLASS();
    output InstNode node;
  protected
    array<Instance> i;
  algorithm
    i := arrayCreate(1, Instance.NOT_INSTANTIATED());
    node := INST_NODE(name, definition, i, parent, nodeType);
  end new;

  function name
    input InstNode node;
    output String name;
  algorithm
    INST_NODE(name = name) := node;
  end name;

  function rename
    input output InstNode node;
    input String name;
  algorithm
    _ := match node
      case INST_NODE()
        algorithm
          node.name := name;
        then
          ();
    end match;
  end rename;

  function parentScope
    input InstNode node;
    output InstNode parentScope;
  algorithm
    INST_NODE(parentScope = parentScope) := node;
  end parentScope;

  function topScope
    input InstNode node;
    output InstNode topScope;
  algorithm
    topScope := match node
      case INST_NODE(nodeType = InstNodeType.TOP_SCOPE()) then node;
      else parentScope(node);
    end match;
  end topScope;

  function setParentScope
    input InstNode parentScope;
    input output InstNode node;
  algorithm
    _ := match node
      case INST_NODE()
        algorithm
          node.parentScope := parentScope;
        then
          ();
    end match;
  end setParentScope;

  function instance
    input InstNode node;
    output Instance instance;
  algorithm
    instance := match node
      case INST_NODE() then node.instance[1];
    end match;
  end instance;

  function setInstance
    input Instance instance;
    input output InstNode node;
  algorithm
    node := match node
      case INST_NODE()
        algorithm
          arrayUpdate(node.instance, 1, instance);
        then
          node;
    end match;
  end setInstance;

  function nodeType
    input InstNode node;
    output InstNodeType nodeType;
  algorithm
    nodeType := match node
      case INST_NODE() then node.nodeType;
      else NORMAL_CLASS();
    end match;
  end nodeType;

  function setNodeType
    input InstNodeType nodeType;
    input output InstNode node;
  algorithm
    () := match node
      case INST_NODE()
        algorithm
          node.nodeType := nodeType;
        then
          ();

      else ();
    end match;
  end setNodeType;

  function definition
    input InstNode node;
    output SCode.Element definition;
  algorithm
    INST_NODE(definition = definition) := node;
  end definition;

  function setDefinition
    input SCode.Element definition;
    input output InstNode node;
  algorithm
    _ := match node
      case INST_NODE()
        algorithm
          node.definition := definition;
        then
          ();
    end match;
  end setDefinition;

  function clone
    input InstNode node;
    output InstNode clone;
  algorithm
    clone := match node
      case INST_NODE()
        then INST_NODE(node.name, node.definition, arrayCopy(node.instance),
          node.parentScope, node.nodeType);
      else node;
    end match;
  end clone;
end InstNode;

annotation(__OpenModelica_Interface="frontend");
end NFInstNode;
