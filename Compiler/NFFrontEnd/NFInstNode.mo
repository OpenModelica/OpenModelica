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
import NFClass.Class;
import NFMod.Modifier;
import SCode;
import Absyn;
import Type = NFType;
import NFFunction.Function;

public
uniontype InstNodeType
  record NORMAL_CLASS
    "A normal class."
  end NORMAL_CLASS;

  record BASE_CLASS
    "A base class extended by another class."
    InstNode parent;
  end BASE_CLASS;

  record TOP_SCOPE
    "The unnamed class containing all the top-level classes."
  end TOP_SCOPE;

  record ROOT_CLASS
    "The root of the instance tree, i.e. the class that the instantiation starts from."
  end ROOT_CLASS;
end InstNodeType;

uniontype CachedData
  record NO_CACHE end NO_CACHE;

  record FUNCTION
    list<Function> funcs;
    Boolean typed;
  end FUNCTION;

  function empty
    output array<CachedData> cache = arrayCreate(1, NO_CACHE());
  end empty;

  function addFunc
    input Function fn;
    input output CachedData cache;
  algorithm
    cache := match cache
      case NO_CACHE() then FUNCTION({fn}, false);
      case FUNCTION() then FUNCTION(fn :: cache.funcs, false);
      else
        algorithm
          assert(false, getInstanceName() + ": Invalid cache for function");
        then
          fail();
    end match;
  end addFunc;
end CachedData;

uniontype InstNode
  record CLASS_NODE
    String name;
    SCode.Element definition;
    array<Class> cls;
    array<CachedData> cached;
    InstNode parentScope;
    InstNodeType nodeType;
  end CLASS_NODE;

  record COMPONENT_NODE
    String name;
    SCode.Element definition;
    array<Component> component;
    InstNode parent;
  end COMPONENT_NODE;

  record REF_NODE
    Integer index;
  end REF_NODE;

  record IMPLICIT_SCOPE
    InstNode parentScope;
    list<InstNode> locals;
  end IMPLICIT_SCOPE;

  record EMPTY_NODE end EMPTY_NODE;

  function new
    input SCode.Element definition;
    input InstNode parent;
    output InstNode node;
  algorithm
    node := match definition
      case SCode.CLASS()
        then CLASS_NODE(definition.name, definition, arrayCreate(1, Class.NOT_INSTANTIATED()),
          CachedData.empty(), parent, NORMAL_CLASS());
      case SCode.COMPONENT()
        then COMPONENT_NODE(definition.name, definition,
          arrayCreate(1, Component.COMPONENT_DEF(Modifier.NOMOD())), parent);
    end match;
  end new;

  function newClass
    input SCode.Element definition;
    input InstNode parent;
    input InstNodeType nodeType = NORMAL_CLASS();
    output InstNode node;
  protected
    array<Class> i;
    String name;
  algorithm
    SCode.CLASS(name = name) := definition;
    i := arrayCreate(1, Class.NOT_INSTANTIATED());
    node := CLASS_NODE(name, definition, i, CachedData.empty(), parent, nodeType);
  end newClass;

  function newComponent
    input SCode.Element definition;
    input InstNode parent = EMPTY_NODE();
    output InstNode node;
  protected
    array<Component> c;
    String name;
  algorithm
    SCode.COMPONENT(name = name) := definition;
    c := arrayCreate(1, Component.COMPONENT_DEF(Modifier.NOMOD()));
    node := COMPONENT_NODE(name, definition, c, parent);
  end newComponent;

  function newExtends
    input InstNode node;
    input InstNode scope;
    output InstNode extendsNode;
  algorithm
    extendsNode := match node
      local
        array<Class> cls;

      case CLASS_NODE()
        algorithm
          cls := arrayCreate(1, Class.NOT_INSTANTIATED());
        then
          CLASS_NODE("$extends." + node.name, node.definition, cls,
            node.cached, node.parentScope, InstNodeType.BASE_CLASS(scope));

      else
        algorithm
          assert(false, getInstanceName() + " got non-class");
        then
          fail();
    end match;
  end newExtends;

  function fromComponent
    input String name;
    input Component component;
    input SCode.Element definition;
    input InstNode parent;
    output InstNode node;
  protected
    array<Component> c;
  algorithm
    c := arrayCreate(1, component);
    node := COMPONENT_NODE(name, definition, c, parent);
  end fromComponent;

  function isClass
    input InstNode node;
    output Boolean isClass;
  algorithm
    isClass := match node
      case CLASS_NODE() then true;
      else false;
    end match;
  end isClass;

  function isBaseClass
    input InstNode node;
    output Boolean isBaseClass;
  algorithm
    isBaseClass := match node
      case CLASS_NODE(nodeType = InstNodeType.BASE_CLASS()) then true;
      else false;
    end match;
  end isBaseClass;

  function isComponent
    input InstNode node;
    output Boolean isComponent;
  algorithm
    isComponent := match node
      case COMPONENT_NODE() then true;
      else false;
    end match;
  end isComponent;

  function isRef
    input InstNode node;
    output Boolean isRef;
  algorithm
    isRef := match node
      case REF_NODE() then true;
      else false;
    end match;
  end isRef;

  function isEmpty
    input InstNode node;
    output Boolean isEmpty;
  algorithm
    isEmpty := match node
      case EMPTY_NODE() then true;
      else false;
    end match;
  end isEmpty;

  function isImplicit
    input InstNode node;
    output Boolean isImplicit;
  algorithm
    isImplicit := match node
      case IMPLICIT_SCOPE() then true;
      else false;
    end match;
  end isImplicit;

  function name
    input InstNode node;
    output String name;
  algorithm
    name := match node
      case CLASS_NODE() then node.name;
      case COMPONENT_NODE() then node.name;
      // For bug catching, these names should never be used.
      case REF_NODE() then "$ref" + String(node.index);
      case IMPLICIT_SCOPE() then "$implicit";
      case EMPTY_NODE() then "$empty";
    end match;
  end name;

  function rename
    input output InstNode node;
    input String name;
  algorithm
    () := match node
      case CLASS_NODE()
        algorithm
          node.name := name;
        then
          ();

      case COMPONENT_NODE()
        algorithm
          node.name := name;
        then
          ();
    end match;
  end rename;

  function parent
    input InstNode node;
    output InstNode parent;
  algorithm
    parent := match node
      case CLASS_NODE() then node.parentScope;
      case COMPONENT_NODE() then node.parent;
      case IMPLICIT_SCOPE() then node.parentScope;
    end match;
  end parent;

  function classScope
    input InstNode node;
    output InstNode scope;
  algorithm
    scope := match node
      case CLASS_NODE() then node;
      case COMPONENT_NODE() then Component.classInstance(node.component[1]);
    end match;
  end classScope;

  function topScope
    input InstNode node;
    output InstNode topScope;
  algorithm
    topScope := match node
      case CLASS_NODE(nodeType = InstNodeType.TOP_SCOPE()) then node;
      case CLASS_NODE() then topScope(node.parentScope);
    end match;
  end topScope;

  function topComponent
    input InstNode node;
    output InstNode topComponent;
  algorithm
    topComponent := match node
      case COMPONENT_NODE(parent = EMPTY_NODE()) then node;
      case COMPONENT_NODE() then topComponent(node.parent);
    end match;
  end topComponent;

  function setParent
    input InstNode parent;
    input output InstNode node;
  algorithm
    () := match node
      case CLASS_NODE()
        algorithm
          node.parentScope := parent;
        then
          ();

      case COMPONENT_NODE()
        algorithm
          node.parent := parent;
        then
          ();

      case IMPLICIT_SCOPE()
        algorithm
          node.parentScope := parent;
        then
          ();
    end match;
  end setParent;

  function setOrphanParent
    "Sets the parent of a node if the node lacks a parent, otherwise does nothing."
    input InstNode parent;
    input output InstNode node;
  algorithm
    () := match node
      case CLASS_NODE(parentScope = EMPTY_NODE())
        algorithm
          node.parentScope := parent;
        then
          ();

      case COMPONENT_NODE(parent = EMPTY_NODE())
        algorithm
          node.parent := parent;
        then
          ();

      else ();
    end match;
  end setOrphanParent;

  function getClass
    input InstNode node;
    output Class cls;
  algorithm
    cls := match node
      case CLASS_NODE() then node.cls[1];
      case COMPONENT_NODE()
        then getClass(Component.classInstance(node.component[1]));
    end match;
  end getClass;

  function updateClass
    input Class cls;
    input output InstNode node;
  algorithm
    node := match node
      case CLASS_NODE()
        algorithm
          arrayUpdate(node.cls, 1, cls);
        then
          node;
    end match;
  end updateClass;

  function component
    input InstNode node;
    output Component component;
  algorithm
    component := match node
      case COMPONENT_NODE() then node.component[1];
    end match;
  end component;

  function updateComponent
    input Component component;
    input output InstNode node;
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
    input output InstNode node;
  algorithm
    () := match node
      case COMPONENT_NODE()
        algorithm
          node.component := arrayCreate(1, component);
        then
          ();
    end match;
  end replaceComponent;

  function replaceClass
    input Class cls;
    input output InstNode node;
  algorithm
    () := match node
      case CLASS_NODE()
        algorithm
          node.cls := arrayCreate(1, cls);
        then
          ();
    end match;
  end replaceClass;

  function nodeType
    input InstNode node;
    output InstNodeType nodeType;
  algorithm
    CLASS_NODE(nodeType = nodeType) := node;
  end nodeType;

  function setNodeType
    input InstNodeType nodeType;
    input output InstNode node;
  algorithm
    () := match node
      case CLASS_NODE()
        algorithm
          node.nodeType := nodeType;
        then
          ();
    end match;
  end setNodeType;

  function definition
    input InstNode node;
    output SCode.Element definition;
  algorithm
    definition := match node
      case CLASS_NODE() then node.definition;
      case COMPONENT_NODE() then node.definition;
    end match;
  end definition;

  function setDefinition
    input SCode.Element definition;
    input output InstNode node;
  algorithm
    () := match node
      case CLASS_NODE()
        algorithm
          node.definition := definition;
        then
          ();

      case COMPONENT_NODE()
        algorithm
          node.definition := definition;
        then
          ();
    end match;
  end setDefinition;

  function info
    input InstNode node;
    output SourceInfo info;
  algorithm
    info := match node
      case CLASS_NODE() then SCode.elementInfo(node.definition);
      case COMPONENT_NODE() then SCode.elementInfo(node.definition);
      else Absyn.dummyInfo;
    end match;
  end info;

  function getType
    input InstNode node;
    output Type ty;
  algorithm
    ty := match node
      case CLASS_NODE() then
        if Class.isBuiltin(node.cls[1]) then
          Class.getType(node.cls[1])
        else
          Type.COMPLEX(node);

      case COMPONENT_NODE() then Component.getType(node.component[1]);
    end match;
  end getType;

  function clone
    input output InstNode node;
  algorithm
    () := match node
      case CLASS_NODE()
        algorithm
          node.cls := arrayCreate(1, Class.clone(node.cls[1]));
        then
          ();

      case COMPONENT_NODE()
        algorithm
          node.component := arrayCopy(node.component);
        then
          ();

      else ();
    end match;
  end clone;

  function classApply<ArgT>
    input output InstNode node;
    input FuncType func;
    input ArgT arg;

    partial function FuncType
      input ArgT arg;
      input output Class cls;
    end FuncType;
  algorithm
    () := match node
      case CLASS_NODE()
        algorithm
          node.cls[1] := func(arg, node.cls[1]);
        then
          ();
    end match;
  end classApply;

  function componentApply<ArgT>
    input output InstNode node;
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
  end componentApply;

  function scopeList
    input InstNode node;
    input list<InstNode> accumScopes = {};
    output list<InstNode> scopes;
  algorithm
    scopes := match node
      local
        InstNodeType it;

      case CLASS_NODE()
        algorithm
          it := node.nodeType;
        then
          match it
            case InstNodeType.NORMAL_CLASS()
              then scopeList(node.parentScope, node :: accumScopes);
            case InstNodeType.BASE_CLASS()
              then scopeList(it.parent, accumScopes);
            else accumScopes;
          end match;

      case COMPONENT_NODE(parent = EMPTY_NODE()) then accumScopes;
      case COMPONENT_NODE() then scopeList(node.parent, node :: accumScopes);
      case IMPLICIT_SCOPE() then scopeList(node.parentScope, accumScopes);
    end match;
  end scopeList;

  function path
    input InstNode node;
    output Absyn.Path p;
  protected
    String n;
    InstNode parent;
  algorithm
    n := InstNode.name(node);
    parent := InstNode.parent(node);
    p := Absyn.IDENT(n);
    p := match(InstNode.nodeType(parent))
      case InstNodeType.ROOT_CLASS() then p;
      case InstNodeType.TOP_SCOPE() then p;
      else Absyn.joinPaths(path(parent), p);
    end match;
  end path;

  function isInput
    input InstNode node;
    output Boolean isInput;
  algorithm
    isInput := match node
      case COMPONENT_NODE() then Component.isInput(node.component[1]);
      else false;
    end match;
  end isInput;

  function isOutput
    input InstNode node;
    output Boolean isOutput;
  algorithm
    isOutput := match node
      case COMPONENT_NODE() then Component.isOutput(node.component[1]);
      else false;
    end match;
  end isOutput;

  function cachedData
    input InstNode node;
    output CachedData cached;
  algorithm
    cached := match node
      case CLASS_NODE() then node.cached[1];
      else CachedData.NO_CACHE();
    end match;
  end cachedData;

  function setCachedData
    input CachedData cached;
    input output InstNode node;
  algorithm
    () := match node
      case CLASS_NODE()
        algorithm
          arrayUpdate(node.cached, 1, cached);
        then
          ();
    end match;
  end setCachedData;

  function cacheAddFunc
    input Function fn;
    input output InstNode node;
  algorithm
    () := match node
      case CLASS_NODE()
        algorithm
          arrayUpdate(node.cached, 1, CachedData.addFunc(fn, node.cached[1]));
        then
          ();

      else
        algorithm
          assert(false, getInstanceName() + " got node without cache");
        then
          fail();
    end match;
  end cacheAddFunc;

  function openImplicitScope
    input output InstNode scope;
  algorithm
    scope := match scope
      case IMPLICIT_SCOPE() then scope;
      else IMPLICIT_SCOPE(scope, {});
    end match;
  end openImplicitScope;

  function addIterator
    input InstNode iterator;
    input output InstNode scope;
  algorithm
    scope := match scope
      case IMPLICIT_SCOPE() then IMPLICIT_SCOPE(scope, iterator :: scope.locals);
    end match;
  end addIterator;
end InstNode;

annotation(__OpenModelica_Interface="frontend");
end NFInstNode;
