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

uniontype InstNode
  record INST_NODE
    String name;
    Option<SCode.Element> definition;
    Instance instance;
    Integer index;
    Integer scopeParent;
    InstParent instParent;
  end INST_NODE;

  function new
    input String name;
    input SCode.Element definition;
    input Integer index;
    input Integer scopeParent;
    input InstParent instParent;
    output InstNode node;
  algorithm
    node := INST_NODE(name, SOME(definition), Instance.NOT_INSTANTIATED(), index,
      scopeParent, instParent);
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
    node.name := name;
  end rename;

  function index
    input InstNode node;
    output Integer index;
  algorithm
    INST_NODE(index = index) := node;
  end index;

  function setIndex
    input output InstNode node;
    input Integer index;
  algorithm
    node.index := index;
  end setIndex;

  function scopeParent
    input InstNode node;
    output Integer scopeParent = node.scopeParent;
  end scopeParent;

  function setScopeParent
    input output InstNode node;
    input Integer scopeParent;
  algorithm
    node.scopeParent := scopeParent;
  end setScopeParent;

  function instParent
    input InstNode node;
    output InstParent instParent = node.instParent;
  end instParent;

  function setInstParent
    input output InstNode node;
    input InstParent instParent;
  algorithm
    node.instParent := instParent;
  end setInstParent;

  function instance
    input InstNode node;
    output Instance instance = node.instance;
  end instance;

  function setInstance
    input output InstNode node;
    input Instance instance;
  algorithm
    node.instance := instance;
  end setInstance;
end InstNode;

annotation(__OpenModelica_Interface="frontend");
end NFInstNode;
