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
import NFInstNode.InstParent;
import NFInstance.Instance;
import NFComponent.Component;
import NFPrefix.Prefix;

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
    InstNode currentScope;
    InstVector.Vector instances;
    list<Component> hierarchy;
  end INST_TREE;

  function new
    output InstanceTree tree;
  protected
    InstNode top;
    InstVector.Vector instances;
  algorithm
    top := InstNode.INST_NODE("<top>", NONE(), Instance.emptyInstancedClass(),
      TOP_SCOPE, NO_SCOPE, InstParent.NO_PARENT());
    instances := InstVector.new();
    instances := InstVector.add(instances, top);
    tree := INST_TREE(top, instances, {});
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
  protected
    Integer idx = InstNode.index(node);
  algorithm
    tree.instances := InstVector.set(tree.instances, idx, node);

    if idx == InstNode.index(tree.currentScope) then
      tree.currentScope := node;
    end if;
  end updateNode;

  function setCurrentScopeIndex
    input output InstanceTree tree;
    input Integer scope;
  algorithm
    tree.currentScope := InstVector.get(tree.instances, scope);
  end setCurrentScopeIndex;

  function currentScopeIndex
    input InstanceTree tree;
    output Integer index = InstNode.index(tree.currentScope);
  end currentScopeIndex;

  function setCurrentScope
    input output InstanceTree tree;
    input InstNode scope;
  algorithm
    tree.currentScope := scope;
  end setCurrentScope;

  function currentScope
    input InstanceTree tree;
    output InstNode scope;
  algorithm
    scope := tree.currentScope;
  end currentScope;

  function enterParentScope
    input output InstanceTree tree;
  algorithm
    tree.currentScope :=
      InstVector.get(tree.instances, InstNode.scopeParent(tree.currentScope));
  end enterParentScope;

  function pushHierarchy
    input Component instance;
    input output InstanceTree tree;
  algorithm
    tree.hierarchy := instance :: tree.hierarchy;
  end pushHierarchy;

  function popHierarchy
    input output InstanceTree tree;
  algorithm
    tree.hierarchy := listRest(tree.hierarchy);
  end popHierarchy;

  function hierarchy
    input InstanceTree tree;
    output list<Component> nodes = tree.hierarchy;
  end hierarchy;

  function currentInstance
    input InstanceTree tree;
    output Component instance = listHead(tree.hierarchy);
  end currentInstance;

  function enterHierarchy
    input Integer scopeIndex;
    input output InstanceTree tree;
  protected
    list<Component> nodes = tree.hierarchy;
    InstNode node;
  algorithm
    //if InstNode.index(currentInstance(tree)) <> scopeIndex then
    //  while true loop
    //    node := listHead(nodes);
    //    if InstNode.index(node) == scopeIndex then
    //      tree.hierarchy := nodes;
    //      break;
    //    end if;
    //    nodes := listRest(nodes);
    //  end while;
    //end if;
  end enterHierarchy;

  function hierarchyPrefix
    input InstanceTree tree;
    output Prefix prefix = Prefix.NO_PREFIX();
  protected
    list<Component> hierarchy = tree.hierarchy;
    Component c;
  algorithm
    // Make a prefix out of all but the last (anonymous) instances in the hierarchy.
    while listLength(hierarchy) > 1 loop
      c :: hierarchy := hierarchy;
      prefix := Prefix.add(Component.name(c), {}, DAE.T_UNKNOWN_DEFAULT, prefix);
    end while;
  end hierarchyPrefix;

  function scopePrefix
    input InstanceTree tree;
    output Prefix prefix = Prefix.NO_PREFIX();
  protected
    InstNode node = currentScope(tree);
    Integer parent = NO_SCOPE;
    list<InstNode> nodes = {};
  algorithm
    while parent <> TOP_SCOPE loop
      nodes := node :: nodes;
      parent := InstNode.scopeParent(node);
      node := InstVector.get(tree.instances, parent);
    end while;

    for n in nodes loop
      prefix := Prefix.add(InstNode.name(n), {}, DAE.T_UNKNOWN_DEFAULT, prefix);
    end for;
  end scopePrefix;

  function prefix
    input InstNode node;
    output Prefix prefix;
  protected
    InstParent ip;
  algorithm
    ip := InstNode.instParent(node);

    prefix := match ip
      case InstParent.CLASS()
        then prefix2(node);
      //case InstParent.COMPONENT() then hierarchyPrefix(node);
      case InstParent.NO_PARENT() then Prefix.NO_PREFIX();
      else Prefix.NO_PREFIX();
    end match;
  end prefix;

  function prefix2
    input InstNode node;
    output Prefix prefix;
  protected
    InstParent ip = InstNode.instParent(node);
    InstNode n;
    list<InstNode> nodes = {};
  algorithm
    while not InstParent.isEmpty(ip) loop
      ip := match ip
        case InstParent.CLASS()
          algorithm
            nodes := ip.node :: nodes;
          then
            InstNode.instParent(ip.node);

        else InstParent.NO_PARENT();
      end match;
    end while;

    prefix := Prefix.addClass(InstNode.name(node), Prefix.NO_PREFIX());

    while listLength(nodes) > 1 loop
      n :: nodes := nodes;
      prefix := Prefix.addClass(InstNode.name(n), prefix);
    end while;
  end prefix2;
end InstanceTree;

annotation(__OpenModelica_Interface="frontend");
end NFInstanceTree;
