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

encapsulated package NFInstanceTree

import BasePVector;
import NFInstNode.InstNode;
import NFInstance.Instance;

encapsulated package InstVector
  import BasePVector;
  import NFInst.InstNode;
  extends BasePVector(redeclare type T = InstNode);
  annotation(__OpenModelica_Interface="util");
end InstVector;

constant Integer NO_SCOPE = 0;
constant Integer TOP_SCOPE = 1;

uniontype InstanceTree
  record INST_TREE
    Integer currentScope;
    InstVector.Vector instances;
    list<InstNode> hierarchy;
  end INST_TREE;

  function new
    output InstanceTree tree;
  protected
    InstNode top;
    InstVector.Vector instances;
  algorithm
    top := InstNode.INST_NODE("<top>", NONE(), Instance.emptyInstancedClass(), TOP_SCOPE, NO_SCOPE);
    instances := InstVector.new();
    instances := InstVector.add(instances, top);
    tree := INST_TREE(TOP_SCOPE, instances, {});
  end new;

  function instanceCount
    input InstanceTree tree;
    output Integer count;
  protected
    InstVector.Vector instances;
  algorithm
    INST_TREE(instances = instances) := tree;
    count := InstVector.size(instances);
  end instanceCount;

  function addInstances
    input list<InstNode> instances;
    input output InstanceTree tree;
  algorithm
    tree.instances := InstVector.addList(tree.instances, instances);
  end addInstances;

  function lookupNode
    input Integer index;
    input InstanceTree tree;
    output InstNode node;
  algorithm
    node := InstVector.get(tree.instances, index);
  end lookupNode;

  function updateNode
    input InstNode node;
    input output InstanceTree tree;
  algorithm
    tree.instances := InstVector.set(tree.instances, InstNode.index(node), node);
  end updateNode;

  function setCurrentScope
    input output InstanceTree tree;
    input Integer scope;
  algorithm
    tree.currentScope := scope;
  end setCurrentScope;

  function currentScopeIndex
    input InstanceTree tree;
    output Integer index = tree.currentScope;
  end currentScopeIndex;

  function currentScope
    input InstanceTree tree;
    output InstNode scope;
  algorithm
    scope := InstVector.get(tree.instances, tree.currentScope);
  end currentScope;
end InstanceTree;

annotation(__OpenModelica_Interface="frontend");
end NFInstanceTree;
