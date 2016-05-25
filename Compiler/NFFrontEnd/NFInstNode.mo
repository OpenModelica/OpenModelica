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

import NFInst.Instance;
import SCode;

uniontype InstNode
  record INST_NODE
    String name;
    Option<SCode.Element> definition;
    Instance instance;
    Integer index;
    Integer parent;
  end INST_NODE;

  function new
    input String name;
    input SCode.Element definition;
    input Integer index;
    input Integer parent;
    output InstNode node;
  algorithm
    node := INST_NODE(name, SOME(definition), Instance.NOT_INSTANTIATED(), index, parent);
  end new;

  function name
    input InstNode node;
    output String name;
  algorithm
    INST_NODE(name = name) := node;
  end name;

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

  function parent
    input InstNode node;
    output Integer parent = node.parent;
  end parent;

  function setParent
    input output InstNode node;
    input Integer parent;
  algorithm
    node.parent := parent;
  end setParent;

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
