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

import Component = NFComponent;
import Class = NFClass;
import SCode;
import Absyn;
import AbsynUtil;
import Type = NFType;
import NFFunction.Function;
import Sections = NFSections;
import Pointer;
import Error;
import Prefixes = NFPrefixes;
import Visibility = NFPrefixes.Visibility;
import NFModifier.Modifier;
import SCodeDump;
import DAE;
import Expression = NFExpression;

protected
import List;
import ConvertDAE = NFConvertDAE;
import Restriction = NFRestriction;
import NFClassTree.ClassTree;
import SCodeUtil;
import IOStream;
import UnorderedMap;

public
uniontype InstNodeType
  record NORMAL_CLASS
    "An element with no specific characteristics."
  end NORMAL_CLASS;

  record BASE_CLASS
    "A base class extended by another class."
    InstNode parent;
    SCode.Element definition "The extends clause definition.";
  end BASE_CLASS;

  record DERIVED_CLASS
    "A short class definition."
    InstNodeType ty "The base node type not considering that it's a derived class.";
  end DERIVED_CLASS;

  record BUILTIN_CLASS
    "A builtin element."
  end BUILTIN_CLASS;

  record TOP_SCOPE
    "The unnamed class containing all the top-level classes."
    UnorderedMap<String, InstNode> generatedInners;
  end TOP_SCOPE;

  record ROOT_CLASS
    "The root of the instance tree, i.e. the class that the instantiation starts from."
    InstNode parent "The parent of the class, e.g. when instantiating a function
                     in a component where the component is the parent.";
  end ROOT_CLASS;

  record NORMAL_COMP
  end NORMAL_COMP;

  record REDECLARED_COMP
    InstNode parent "The parent of the replaced component";
  end REDECLARED_COMP;

  record REDECLARED_CLASS
    InstNode parent;
    InstNodeType originalType;
  end REDECLARED_CLASS;

  record GENERATED_INNER
    "A generated inner element due to a missing outer."
  end GENERATED_INNER;
end InstNodeType;

constant Integer NUMBER_OF_CACHES = 2;

uniontype CachedData

  record NO_CACHE end NO_CACHE;

  record PACKAGE
    InstNode instance;
  end PACKAGE;

  record FUNCTION
    list<Function> funcs;
    Boolean typed;
    Boolean specialBuiltin;
  end FUNCTION;

  function empty
    output array<CachedData> cache = arrayCreate(NUMBER_OF_CACHES, NO_CACHE());
  end empty;

  function initFunc
    input array<CachedData> caches;
  protected
    CachedData func_cache;
  algorithm
    func_cache := getFuncCache(caches);
    func_cache := match func_cache
      case NO_CACHE() then FUNCTION({}, false, false);
      case FUNCTION() then func_cache;
    end match;

    setFuncCache(caches, func_cache);
  end initFunc;

  function addFunc
    input Function fn;
    input Boolean specialBuiltin;
    input array<CachedData> caches;
  protected
    CachedData func_cache;
  algorithm
    func_cache := getFuncCache(caches);
    func_cache := match func_cache
      case NO_CACHE() then FUNCTION({fn}, false, specialBuiltin);
      // Append to end so the error messages are ordered properly.
      case FUNCTION() then FUNCTION(listAppend(func_cache.funcs,{fn}), false,
                                    func_cache.specialBuiltin or specialBuiltin);
      else
        algorithm
          Error.assertion(false, getInstanceName() + ": Invalid cache for function", sourceInfo());
        then
          fail();
    end match;

    setFuncCache(caches, func_cache);
  end addFunc;

  function getFuncCache
    input array<CachedData> in_caches;
    output CachedData out_cache = arrayGet(in_caches, 1);
  end getFuncCache;

  function setFuncCache
    input array<CachedData> in_caches;
    input CachedData in_cache;
    algorithm
      arrayUpdate(in_caches, 1, in_cache);
  end setFuncCache;

  function getPackageCache
    input array<CachedData> in_caches;
    output CachedData out_cache = arrayGet(in_caches, 2);
  end getPackageCache;

  function setPackageCache
    input array<CachedData> in_caches;
    input CachedData in_cache;
    output array<CachedData> out_caches = arrayUpdate(in_caches, 2, in_cache);
  end setPackageCache;

  function clearPackageCache
    input array<CachedData> in_caches;
    output array<CachedData> out_caches = arrayUpdate(in_caches, 2, NO_CACHE());
  end clearPackageCache;
end CachedData;

uniontype InstNode
  record CLASS_NODE
    String name;
    SCode.Element definition;
    Visibility visibility;
    Pointer<Class> cls;
    array<CachedData> caches;
    InstNode parentScope;
    InstNodeType nodeType;
  end CLASS_NODE;

  record COMPONENT_NODE
    String name;
    Visibility visibility;
    Pointer<Component> component;
    InstNode parent "The instance that this component is part of.";
    InstNodeType nodeType;
  end COMPONENT_NODE;

  record INNER_OUTER_NODE
    "A node representing an outer element, with a reference to the corresponding inner."
    InstNode innerNode;
    InstNode outerNode;
  end INNER_OUTER_NODE;

  record REF_NODE
    Integer index;
  end REF_NODE;

  record NAME_NODE
    String name;
  end NAME_NODE;

  record IMPLICIT_SCOPE
    InstNode parentScope;
    list<InstNode> locals;
  end IMPLICIT_SCOPE;

  record EXP_NODE
    Expression exp;
  end EXP_NODE;

  record EMPTY_NODE end EMPTY_NODE;

  function new
    input SCode.Element definition;
    input InstNode parent;
    output InstNode node;
  algorithm
    node := match definition
      case SCode.CLASS() then newClass(definition, parent);
      case SCode.COMPONENT() then newComponent(definition, parent);
    end match;
  end new;

  function newClass
    input SCode.Element definition;
    input InstNode parent;
    input InstNodeType nodeType = NORMAL_CLASS();
    output InstNode node;
  protected
    String name;
    SCode.Visibility vis;
  algorithm
    SCode.CLASS(name = name, prefixes = SCode.PREFIXES(visibility = vis)) := definition;
    node := CLASS_NODE(name, definition, Prefixes.visibilityFromSCode(vis),
      Pointer.create(Class.NOT_INSTANTIATED()), CachedData.empty(), parent, nodeType);
  end newClass;

  function newComponent
    input SCode.Element definition;
    input InstNode parent = EMPTY_NODE();
    output InstNode node;
  protected
    String name;
    SCode.Visibility vis;
  algorithm
    SCode.COMPONENT(name = name, prefixes = SCode.PREFIXES(visibility = vis)) := definition;
    node := COMPONENT_NODE(name, Prefixes.visibilityFromSCode(vis),
      Pointer.create(Component.new(definition)), parent, InstNodeType.NORMAL_COMP());
  end newComponent;

  function newExtends
    input SCode.Element definition;
    input InstNode parent;
    output InstNode node;
  protected
    Absyn.Path base_path;
    String name;
    SCode.Visibility vis;
  algorithm
    SCode.Element.EXTENDS(baseClassPath = base_path, visibility = vis) := definition;
    name := AbsynUtil.pathLastIdent(base_path);
    node := CLASS_NODE(name, definition, Prefixes.visibilityFromSCode(vis),
      Pointer.create(Class.NOT_INSTANTIATED()), CachedData.empty(), parent,
      InstNodeType.BASE_CLASS(parent, definition));
  end newExtends;

  function newIterator
    input String name;
    input Type ty;
    input SourceInfo info;
    output InstNode iterator;
  algorithm
    iterator := fromComponent(name, Component.newIterator(ty, info), EMPTY_NODE());
  end newIterator;

  function newIndexedIterator
    input Integer index;
    input Type ty = Type.INTEGER();
    input SourceInfo info = AbsynUtil.dummyInfo;
    output InstNode iterator;
  algorithm
    iterator := newIterator("$i" + String(index), ty, info);
  end newIndexedIterator;

  function fromComponent
    input String name;
    input Component component;
    input InstNode parent;
    output InstNode node;
  algorithm
    node := COMPONENT_NODE(name, Visibility.PUBLIC, Pointer.create(component),
                           parent, InstNodeType.NORMAL_COMP());
  end fromComponent;

  function isClass
    input InstNode node;
    output Boolean isClass;
  algorithm
    isClass := match node
      case CLASS_NODE() then true;
      case INNER_OUTER_NODE() then isClass(node.innerNode);
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

  function isUserdefinedClass
    input InstNode node;
    output Boolean isUserdefined;
  algorithm
    isUserdefined := match node
      case CLASS_NODE()
        then match node.nodeType
          case InstNodeType.NORMAL_CLASS() then true;
          case InstNodeType.BASE_CLASS() then true;
          case InstNodeType.DERIVED_CLASS() then true;
          else false;
        end match;
      else false;
    end match;
  end isUserdefinedClass;

  function isDerivedClass
    input InstNode node;
    output Boolean isDerived;
  algorithm
    isDerived := match node
      case CLASS_NODE(nodeType = InstNodeType.DERIVED_CLASS()) then true;
      else false;
    end match;
  end isDerivedClass;

  function isRootClass
    input InstNode node;
    output Boolean res;
  algorithm
    res := match node
      case CLASS_NODE(nodeType = InstNodeType.ROOT_CLASS()) then true;
      else false;
    end match;
  end isRootClass;

  function isFunction
    input InstNode node;
    output Boolean isFunc;
  algorithm
    isFunc := match node
      case CLASS_NODE() then Class.isFunction(Pointer.access(node.cls));
      else false;
    end match;
  end isFunction;

  function isComponent
    input InstNode node;
    output Boolean isComponent;
  algorithm
    isComponent := match node
      case COMPONENT_NODE() then true;
      case INNER_OUTER_NODE() then isComponent(node.innerNode);
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

  function isName
    input InstNode node;
    output Boolean isName;
  algorithm
    isName := match node
      case NAME_NODE() then true;
      else false;
    end match;
  end isName;

  function isConnector
    input InstNode node;
    output Boolean isConnector;
  algorithm
    isConnector := match node
      case COMPONENT_NODE() then Component.isConnector(component(node));
      case NAME_NODE() then true;
      else false;
    end match;
  end isConnector;

  function isExpandableConnector
    input InstNode node;
    output Boolean isConnector;
  algorithm
    isConnector := match node
      case COMPONENT_NODE() then Component.isExpandableConnector(component(node));
      else false;
    end match;
  end isExpandableConnector;

  function hasParentExpandableConnector
  "@author: adrpo
   returns true if itself or any of the parents are expandable connectors"
    input InstNode node;
    output Boolean b = isExpandableConnector(node);
  protected
    InstNode p;
  algorithm
    p := node;
    while not isEmpty(p) loop
      p := parent(p);
      b := boolOr(b, isExpandableConnector(p));
      if b then
        break;
      end if;
    end while;
  end hasParentExpandableConnector;

  function isOperator
    input InstNode node;
    output Boolean op;
  algorithm
    op := match node
      case CLASS_NODE() then SCodeUtil.isOperator(node.definition);
      case INNER_OUTER_NODE() then isOperator(node.innerNode);
      else false;
    end match;
  end isOperator;

  function name
    input InstNode node;
    output String name;
  algorithm
    name := match node
      case CLASS_NODE() then node.name;
      case COMPONENT_NODE() then node.name;
      case INNER_OUTER_NODE() then name(node.innerNode);
      // For bug catching, these names should never be used.
      case REF_NODE() then "$REF[" + String(node.index) + "]";
      case NAME_NODE() then node.name;
      case IMPLICIT_SCOPE() then "$IMPLICIT";
      case EXP_NODE() then "$EXP(" + Expression.toString(node.exp) + ")";
      case EMPTY_NODE() then "$EMPTY";
    end match;
  end name;

  function className
    input InstNode node;
    output String name;
  algorithm
    CLASS_NODE(name = name) := node;
  end className;

  function scopeName
    "Returns the name of a scope, which in the case of a component is the name
     of the component's type, and for a class simply the name of the class."
    input InstNode node;
    output String outName = name(classScope(explicitScope(node)));
  end scopeName;

  function typeName
    "Returns the type of node the given node is as a string."
    input InstNode node;
    output String name;
  algorithm
    name := match node
      case CLASS_NODE() then "class";
      case COMPONENT_NODE() then "component";
      case INNER_OUTER_NODE() then typeName(node.innerNode);
      case REF_NODE() then "ref node";
      case NAME_NODE() then "name node";
      case IMPLICIT_SCOPE() then "implicit scope";
      case EMPTY_NODE() then "empty node";
    end match;
  end typeName;

  function rename
    input String name;
    input output InstNode node;
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
      else EMPTY_NODE();
    end match;
  end parent;

  function explicitParent
    input InstNode node;
    output InstNode parentNode = explicitScope(parent(node));
  end explicitParent;

  function classParent
    input InstNode node;
    output InstNode parent;
  algorithm
    CLASS_NODE(parentScope = parent) := node;
  end classParent;

  function instanceParent
    "Returns the parent of the node in the instance tree."
    input InstNode node;
    output InstNode parent;
  algorithm
    parent := match node
      case CLASS_NODE() then getDerivedNode(node.parentScope);
      case COMPONENT_NODE(nodeType = InstNodeType.REDECLARED_COMP(parent = parent))
        then getDerivedNode(parent);
      case COMPONENT_NODE() then getDerivedNode(node.parent);
      case IMPLICIT_SCOPE() then getDerivedNode(node.parentScope);
      else EMPTY_NODE();
    end match;
  end instanceParent;

  function rootParent
    input InstNode node;
    output InstNode parent;
  algorithm
    parent := match node
      case CLASS_NODE() then rootTypeParent(node.nodeType, node);
      else parent(node);
    end match;
  end rootParent;

  function rootTypeParent
    input InstNodeType nodeType;
    input InstNode node;
    output InstNode parent;
  algorithm
    parent := match nodeType
      case InstNodeType.ROOT_CLASS() guard not isEmpty(nodeType.parent) then nodeType.parent;
      case InstNodeType.DERIVED_CLASS() then rootTypeParent(nodeType.ty, node);
      else parent(node);
    end match;
  end rootTypeParent;

  function parentScope
    "Returns the parent scope of a node. In the case of a class this is simply
     the enclosing class. In the case of a component it is the enclosing class of
     the component's type."
    input InstNode node;
    output InstNode scope;
  algorithm
    scope := match node
      case CLASS_NODE(nodeType = InstNodeType.DERIVED_CLASS())
        then parentScope(Class.lastBaseClass(node));
      case CLASS_NODE() then node.parentScope;
      case COMPONENT_NODE() then parentScope(Component.classInstance(Pointer.access(node.component)));
      case IMPLICIT_SCOPE() then node.parentScope;
    end match;
  end parentScope;

  function enclosingScopePath
    "Returns the enclosing scopes of a node as a path."
    input InstNode node;
    output Absyn.Path path;
  algorithm
    path := AbsynUtil.stringListPath(
      list(InstNode.name(n) for n in enclosingScopeList(node)));
  end enclosingScopePath;

  function enclosingScopeList
    "Returns the enclosing scopes of a node as a list of nodes."
    input InstNode node;
    output list<InstNode> res = {};
  protected
    InstNode scope = node;
  algorithm
    while not isTopScope(scope) loop
      res := scope :: res;
      scope := classScope(parentScope(scope));
    end while;
  end enclosingScopeList;

  function classScope
    input InstNode node;
    output InstNode scope;
  algorithm
    scope := match node
      case COMPONENT_NODE()
        then Component.classInstance(Pointer.access(node.component));
      else node;
    end match;
  end classScope;

  function libraryScope
    "Returns the top-level class the given node belongs to."
    input InstNode node;
    output InstNode lib;
  algorithm
    lib := match node
      case CLASS_NODE(parentScope = CLASS_NODE(nodeType = InstNodeType.TOP_SCOPE())) then node;
      else libraryScope(parentScope(node));
    end match;
  end libraryScope;

  function topScope
    input InstNode node;
    output InstNode topScope;
  algorithm
    topScope := match node
      case CLASS_NODE(nodeType = InstNodeType.TOP_SCOPE()) then node;
      else topScope(parentScope(node));
    end match;
  end topScope;

  function isTopScope
    input InstNode node;
    output Boolean res;
  algorithm
    res := match node
      case CLASS_NODE(nodeType = InstNodeType.TOP_SCOPE()) then true;
      else false;
    end match;
  end isTopScope;

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
      case CLASS_NODE() then Pointer.access(node.cls);
      case COMPONENT_NODE()
        then getClass(Component.classInstance(Pointer.access(node.component)));
    end match;
  end getClass;

  function getDerivedClass
    input InstNode node;
    output Class cls;
  algorithm
    cls := match node
      case CLASS_NODE() then getClass(getDerivedNode(node));
      case COMPONENT_NODE()
        then getClass(getDerivedNode(Component.classInstance(Pointer.access(node.component))));
    end match;
  end getDerivedClass;

  function getDerivedNode
    input InstNode node;
    output InstNode derived;
  algorithm
    derived := match node
      case CLASS_NODE(nodeType = InstNodeType.BASE_CLASS(parent = derived))
        then getDerivedNode(derived);
      else node;
    end match;
  end getDerivedNode;

  function updateClass
    input Class cls;
    input output InstNode node;
  algorithm
    node := match node
      case CLASS_NODE()
        algorithm
          Pointer.update(node.cls, cls);
        then
          node;
    end match;
  end updateClass;

  function component
    input InstNode node;
    output Component component;
  algorithm
    component := match node
      case COMPONENT_NODE() then Pointer.access(node.component);
    end match;
  end component;

  function updateComponent
    input Component component;
    input output InstNode node;
  algorithm
    node := match node
      case COMPONENT_NODE()
        algorithm
          Pointer.update(node.component, component);
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
          node.component := Pointer.create(component);
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
          node.cls := Pointer.create(cls);
        then
          ();
    end match;
  end replaceClass;

  function nodeType
    input InstNode node;
    output InstNodeType nodeType;
  algorithm
    nodeType := match node
      case CLASS_NODE() then node.nodeType;
      case COMPONENT_NODE() then node.nodeType;
    end match;
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

      case COMPONENT_NODE()
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
    definition := match node
      case CLASS_NODE() then node.definition;
      case COMPONENT_NODE() then Component.definition(Pointer.access(node.component));
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

    end match;
  end setDefinition;

  function info
    input InstNode node;
    output SourceInfo info;
  algorithm
    info := matchcontinue node
      local
        InstNodeType ty;
      case CLASS_NODE(nodeType = ty as InstNodeType.BASE_CLASS())
        then SCodeUtil.elementInfo(ty.definition);
      case CLASS_NODE() then SCodeUtil.elementInfo(node.definition);
      case COMPONENT_NODE() then Component.info(Pointer.access(node.component));
      case COMPONENT_NODE() then info(node.parent);
      else AbsynUtil.dummyInfo;
    end matchcontinue;
  end info;

  function getType
    input InstNode node;
    output Type ty;
  algorithm
    ty := match node
      case CLASS_NODE() then Class.getType(Pointer.access(node.cls), node);
      case COMPONENT_NODE() then Component.getType(Pointer.access(node.component));
    end match;
  end getType;

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
          Pointer.update(node.cls, func(arg, Pointer.access(node.cls)));
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
          Pointer.update(node.component, func(arg, Pointer.access(node.component)));
        then
          ();
    end match;
  end componentApply;

  function scopeList
    input InstNode node;
    input Boolean includeRoot = false "Whether to include the root class name or not.";
    input list<InstNode> accumScopes = {};
    output list<InstNode> scopes;
  algorithm
    scopes := match node
      local
        InstNode parent;

      case CLASS_NODE() then scopeListClass(node, node.nodeType, includeRoot, accumScopes);
      case COMPONENT_NODE(parent = EMPTY_NODE()) then accumScopes;
      case COMPONENT_NODE(nodeType = InstNodeType.REDECLARED_COMP(parent = parent))
        then scopeList(parent, includeRoot, node :: accumScopes);
      case COMPONENT_NODE() then scopeList(node.parent, includeRoot, node :: accumScopes);
      case IMPLICIT_SCOPE() then scopeList(node.parentScope, includeRoot, accumScopes);
      else accumScopes;
    end match;
  end scopeList;

  function scopeListClass
    input InstNode clsNode;
    input InstNodeType ty;
    input Boolean includeRoot;
    input list<InstNode> accumScopes = {};
    output list<InstNode> scopes;
  algorithm
    scopes := match ty
      case InstNodeType.NORMAL_CLASS()
        then scopeList(parent(clsNode), includeRoot, clsNode :: accumScopes);
      case InstNodeType.BASE_CLASS()
        then scopeList(ty.parent, includeRoot, accumScopes);
      case InstNodeType.DERIVED_CLASS()
        then scopeListClass(clsNode, ty.ty, includeRoot, accumScopes);
      case InstNodeType.BUILTIN_CLASS()
        then clsNode :: accumScopes;
      case InstNodeType.TOP_SCOPE()
        then accumScopes;
      case InstNodeType.ROOT_CLASS()
        then if includeRoot then
            scopeList(parent(clsNode), includeRoot, clsNode :: accumScopes)
          else
            accumScopes;
      case InstNodeType.REDECLARED_CLASS()
        then scopeList(ty.parent, includeRoot, getDerivedNode(clsNode) :: accumScopes);
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown node type", sourceInfo());
        then
          fail();
    end match;
  end scopeListClass;

  function scopePath
    input InstNode node;
    input Boolean includeRoot = false "Whether to include the root class name or not.";
    input Boolean ignoreBaseClass = false "Ignore that a class is a base class if true.";
    output Absyn.Path path;
  algorithm
    path := match node
      local
        InstNodeType it;

      case CLASS_NODE(nodeType = it)
        then
          match it
            case InstNodeType.BASE_CLASS() guard not ignoreBaseClass then scopePath(it.parent, includeRoot);
            else scopePath2(node.parentScope, includeRoot, Absyn.IDENT(node.name));
          end match;

      case COMPONENT_NODE() then scopePath2(node.parent, includeRoot, Absyn.IDENT(node.name));
      case IMPLICIT_SCOPE() then scopePath(node.parentScope, includeRoot);

      // For debugging.
      else Absyn.IDENT(name(node));
    end match;
  end scopePath;

  function scopePath2
    input InstNode node;
    input Boolean includeRoot;
    input Absyn.Path accumPath;
    output Absyn.Path path;
  algorithm
    path := match node
      case CLASS_NODE() then scopePathClass(node, node.nodeType, includeRoot, accumPath);
      case COMPONENT_NODE() then scopePath2(node.parent, includeRoot, Absyn.QUALIFIED(node.name, accumPath));
      else accumPath;
    end match;
  end scopePath2;

  function scopePathClass
    input InstNode node;
    input InstNodeType ty;
    input Boolean includeRoot;
    input Absyn.Path accumPath;
    output Absyn.Path path;
  algorithm
    path := match ty
      case InstNodeType.NORMAL_CLASS()
        then scopePath2(classParent(node), includeRoot, Absyn.QUALIFIED(className(node), accumPath));
      case InstNodeType.BASE_CLASS()
        then scopePath2(ty.parent, includeRoot, accumPath);
      case InstNodeType.DERIVED_CLASS()
        then scopePathClass(node, ty.ty, includeRoot, accumPath);
      case InstNodeType.BUILTIN_CLASS()
        then Absyn.QUALIFIED(className(node), accumPath);
      case InstNodeType.TOP_SCOPE()
        then accumPath;
      case InstNodeType.ROOT_CLASS()
        then if includeRoot then
            scopePath2(classParent(node), includeRoot, Absyn.QUALIFIED(className(node), accumPath))
          else
            accumPath;
      case InstNodeType.REDECLARED_CLASS()
        then scopePath2(ty.parent, includeRoot, Absyn.QUALIFIED(className(node), accumPath));
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown node type", sourceInfo());
        then
          fail();
    end match;
  end scopePathClass;

  function isInput
    input InstNode node;
    output Boolean isInput;
  algorithm
    isInput := match node
      case COMPONENT_NODE() then Component.isInput(Pointer.access(node.component));
      else false;
    end match;
  end isInput;

  function isOutput
    input InstNode node;
    output Boolean isOutput;
  algorithm
    isOutput := match node
      case COMPONENT_NODE() then Component.isOutput(Pointer.access(node.component));
      else false;
    end match;
  end isOutput;

  function isInner
    input InstNode node;
    output Boolean isInner;
  algorithm
    isInner := match node
      case COMPONENT_NODE() then Component.isInner(Pointer.access(node.component));
      case CLASS_NODE()
        then AbsynUtil.isInner(SCodeUtil.prefixesInnerOuter(SCodeUtil.elementPrefixes(node.definition)));
      case INNER_OUTER_NODE() then isInner(node.outerNode);
      else false;
    end match;
  end isInner;

  function isOuter
    input InstNode node;
    output Boolean isOuter;
  algorithm
    isOuter := match node
      case COMPONENT_NODE() then Component.isOuter(Pointer.access(node.component));
      case CLASS_NODE()
        then AbsynUtil.isOuter(SCodeUtil.prefixesInnerOuter(SCodeUtil.elementPrefixes(node.definition)));
      case INNER_OUTER_NODE() then isOuter(node.outerNode);
      else false;
    end match;
  end isOuter;

  function isOnlyOuter
    input InstNode node;
    output Boolean isOuter;
  algorithm
    isOuter := match node
      case COMPONENT_NODE() then Component.isOnlyOuter(Pointer.access(node.component));
      case CLASS_NODE()
        then AbsynUtil.isOnlyOuter(SCodeUtil.prefixesInnerOuter(SCodeUtil.elementPrefixes(node.definition)));
      case INNER_OUTER_NODE() then isOnlyOuter(node.outerNode);
      else false;
    end match;
  end isOnlyOuter;

  function isInnerOuterNode
    input InstNode node;
    output Boolean isIO;
  algorithm
    isIO := match node
      case INNER_OUTER_NODE() then true;
      else false;
    end match;
  end isInnerOuterNode;

  function isGeneratedInner
    input InstNode node;
    output Boolean isInner;
  algorithm
    isInner := match node
      case CLASS_NODE(nodeType = InstNodeType.GENERATED_INNER()) then true;
      case COMPONENT_NODE(nodeType = InstNodeType.GENERATED_INNER()) then true;
      else false;
    end match;
  end isGeneratedInner;

  function resolveInner
    input InstNode node;
    output InstNode innerNode;
  algorithm
    innerNode := match node
      case INNER_OUTER_NODE() then node.innerNode;
      else node;
    end match;
  end resolveInner;

  function resolveOuter
    input InstNode node;
    output InstNode outerNode;
  algorithm
    outerNode := match node
      case INNER_OUTER_NODE() then node.outerNode;
      else node;
    end match;
  end resolveOuter;

  function cacheInitFunc
    input output InstNode node;
  algorithm
    () := match node
      case CLASS_NODE() algorithm CachedData.initFunc(node.caches); then ();
      else algorithm Error.assertion(false, getInstanceName() + " got node without cache", sourceInfo()); then fail();
    end match;
  end cacheInitFunc;

  function cacheAddFunc
    input output InstNode node;
    input Function fn;
    input Boolean specialBuiltin;
  algorithm
    () := match node
      case CLASS_NODE() algorithm CachedData.addFunc(fn, specialBuiltin, node.caches); then ();
      else algorithm Error.assertion(false, getInstanceName() + " got node without cache", sourceInfo()); then fail();
    end match;
  end cacheAddFunc;

  function getFuncCache
    input InstNode inNode;
    output CachedData func_cache;
  algorithm
    func_cache := match inNode
      case CLASS_NODE() then CachedData.getFuncCache(inNode.caches);
      else algorithm Error.assertion(false, getInstanceName() + " got node without cache", sourceInfo()); then fail();
    end match;
  end getFuncCache;

  function setFuncCache
    input output InstNode node;
    input CachedData in_func_cache;
  algorithm
    () := match node
      case CLASS_NODE() algorithm CachedData.setFuncCache(node.caches, in_func_cache); then ();
      else algorithm Error.assertion(false, getInstanceName() + " got node without cache", sourceInfo()); then fail();
    end match;
  end setFuncCache;

  function getPackageCache
    input InstNode inNode;
    output CachedData pack_cache;
  algorithm
    pack_cache := match inNode
      case CLASS_NODE() then CachedData.getPackageCache(inNode.caches);
      else algorithm Error.assertion(false, getInstanceName() + " got node without cache", sourceInfo()); then fail();
    end match;
  end getPackageCache;

  function setPackageCache
    input output InstNode node;
    input CachedData in_pack_cache;
  algorithm
    () := match node
      case CLASS_NODE() algorithm CachedData.setPackageCache(node.caches, in_pack_cache); then ();
      else algorithm Error.assertion(false, getInstanceName() + " got node without cache", sourceInfo()); then fail();
    end match;
  end setPackageCache;

  function clearPackageCache
    input output InstNode node;
  algorithm
    () := match node
      case CLASS_NODE() algorithm CachedData.clearPackageCache(node.caches); then ();
      else algorithm Error.assertion(false, getInstanceName() + " got node without cache", sourceInfo()); then fail();
    end match;
  end clearPackageCache;

  function openImplicitScope
    input output InstNode scope;
  algorithm
    scope := match scope
      case IMPLICIT_SCOPE() then scope;
      else IMPLICIT_SCOPE(scope, {});
    end match;
  end openImplicitScope;

  function explicitScope
    "Returns the first parent of the node that's not an implicit scope, or the
     node itself if it's not an implicit scope."
    input InstNode node;
    output InstNode scope;
  algorithm
    scope := match node
      case IMPLICIT_SCOPE() then explicitScope(node.parentScope);
      else node;
    end match;
  end explicitScope;

  function addIterator
    input InstNode iterator;
    input output InstNode scope;
  algorithm
    scope := match scope
      case IMPLICIT_SCOPE() then IMPLICIT_SCOPE(scope, iterator :: scope.locals);
    end match;
  end addIterator;

  function refEqual
    "Returns true if two nodes references the same class or component,
     otherwise false."
    input InstNode node1;
    input InstNode node2;
    output Boolean refEqual;
  algorithm
    refEqual := match (node1, node2)
      case (CLASS_NODE(), CLASS_NODE())
        then referenceEq(Pointer.access(node1.cls), Pointer.access(node2.cls));
      case (COMPONENT_NODE(), COMPONENT_NODE())
        then referenceEq(Pointer.access(node1.component), Pointer.access(node2.component));
      // Other nodes like ref nodes might be equal, but we neither know nor care.
      else false;
    end match;
  end refEqual;

  function refCompare
    input InstNode node1;
    input InstNode node2;
    output Integer res;
  algorithm
    res := match (node1, node2)
      case (CLASS_NODE(), CLASS_NODE())
        then Util.referenceCompare(Pointer.access(node1.cls), Pointer.access(node2.cls));
      case (COMPONENT_NODE(), COMPONENT_NODE())
        then Util.referenceCompare(Pointer.access(node1.component), Pointer.access(node2.component));
      case (CLASS_NODE(), COMPONENT_NODE())
        then Util.referenceCompare(Pointer.access(node1.cls), Pointer.access(node2.component));
      case (COMPONENT_NODE(), CLASS_NODE())
        then Util.referenceCompare(Pointer.access(node1.component), Pointer.access(node2.cls));
    end match;
  end refCompare;

  function nameEqual
    input InstNode node1;
    input InstNode node2;
    output Boolean equal = InstNode.name(node1) == InstNode.name(node2);
  end nameEqual;

  function isSame
    input InstNode node1;
    input InstNode node2;
    output Boolean same = false;
  protected
    InstNode n1 = resolveOuter(node1);
    InstNode n2 = resolveOuter(node2);
  algorithm
    if referenceEq(n1, n2) then
      same := true;
      return;
    // TODO: This is not enough. We need a better way.
    elseif stringEqual(name(n1), name(n2)) then
      same := true;
      return;
    end if;
  end isSame;

  function checkIdentical
    input InstNode node1;
    input InstNode node2;
  protected
    InstNode n1 = resolveOuter(node1);
    InstNode n2 = resolveOuter(node2);
  algorithm
    if referenceEq(n1, n2) then
      return;
    end if;

    () := matchcontinue (n1, n2)
      case (CLASS_NODE(), CLASS_NODE())
        guard Class.isIdentical(getClass(n1), getClass(n2)) then ();
      case (COMPONENT_NODE(), COMPONENT_NODE())
        guard Component.isIdentical(component(n1), component(n2)) then ();
      else
        algorithm
          Error.addMultiSourceMessage(Error.DUPLICATE_ELEMENTS_NOT_IDENTICAL,
            {toString(n1), toString(n2)},
            {InstNode.info(n1), InstNode.info(n2)});
        then
          fail();
    end matchcontinue;
  end checkIdentical;

  function toString
    input InstNode node;
    output String name;
  algorithm
    name := match node
      case COMPONENT_NODE() then Component.toString(node.name, Pointer.access(node.component));
      case CLASS_NODE() then SCodeDump.unparseElementStr(node.definition);
      else name(node);
    end match;
  end toString;

  function toFlatString
    input InstNode node;
    output String name;
  algorithm
    name := match node
      case COMPONENT_NODE() then Component.toFlatString(node.name, Pointer.access(node.component));
      case CLASS_NODE() then Class.toFlatString(Pointer.access(node.cls), node);
      else name(node);
    end match;
  end toFlatString;

  function toFlatStream
    input InstNode node;
    input output IOStream.IOStream s;
  algorithm
    s := match node
      case COMPONENT_NODE() then Component.toFlatStream(node.name, Pointer.access(node.component), s);
      case CLASS_NODE() then Class.toFlatStream(Pointer.access(node.cls), node, s);
      else IOStream.append(s, toFlatString(node));
    end match;
  end toFlatStream;

  function isRedeclare
    input InstNode node;
    output Boolean isRedeclare;
  algorithm
    isRedeclare := match node
      case CLASS_NODE() then SCodeUtil.isElementRedeclare(definition(node));
      case COMPONENT_NODE() then Component.isRedeclare(Pointer.access(node.component));
      else false;
    end match;
  end isRedeclare;

  function isRedeclared
    input InstNode node;
    output Boolean redeclared;
  algorithm
    redeclared := match nodeType(node)
      case InstNodeType.REDECLARED_COMP() then true;
      case InstNodeType.REDECLARED_CLASS() then true;
      else false;
    end match;
  end isRedeclared;

  function isProtectedBaseClass
    input InstNode node;
    output Boolean isProtected;
  algorithm
    isProtected := match node
      local
        SCode.Element def;

      case CLASS_NODE(nodeType = InstNodeType.BASE_CLASS(definition =
          SCode.Element.EXTENDS(visibility = SCode.Visibility.PROTECTED())))
        then true;

      else false;
    end match;
  end isProtectedBaseClass;

  function visibility
    input InstNode node;
    output Visibility vis;
  algorithm
    vis := match node
      case CLASS_NODE() then node.visibility;
      case COMPONENT_NODE() then node.visibility;
      else Visibility.PUBLIC;
    end match;
  end visibility;

  function isProtected
    input InstNode node;
    output Boolean isProtected;
  algorithm
    isProtected := match node
      case CLASS_NODE(visibility = Visibility.PROTECTED) then true;
      case COMPONENT_NODE(visibility = Visibility.PROTECTED) then true;
      else false;
    end match;
  end isProtected;

  function protectClass
    input output InstNode cls;
  algorithm
    () := match cls
      case CLASS_NODE(visibility = Visibility.PUBLIC)
        algorithm
          cls.visibility := Visibility.PROTECTED;
        then
          ();

      else ();
    end match;
  end protectClass;

  function protectComponent
    input output InstNode comp;
  algorithm
    () := match comp
      case COMPONENT_NODE(visibility = Visibility.PUBLIC)
        algorithm
          comp.visibility := Visibility.PROTECTED;
        then
          ();

      else ();
    end match;
  end protectComponent;

  function isEncapsulated
    input InstNode node;
    output Boolean enc;
  algorithm
    enc := match node
      case CLASS_NODE() then Class.isEncapsulated(Pointer.access(node.cls));
      case COMPONENT_NODE() then Class.isEncapsulated(getClass(node));
      else false;
    end match;
  end isEncapsulated;

  function getModifier
    input InstNode node;
    output Modifier mod;
  algorithm
    mod := match node
      case CLASS_NODE() then Class.getModifier(Pointer.access(node.cls));
      case COMPONENT_NODE() then Component.getModifier(Pointer.access(node.component));
      else Modifier.NOMOD();
    end match;
  end getModifier;

  function mergeModifier
    input Modifier mod;
    input output InstNode node;
  algorithm
    () := match node
      case CLASS_NODE()
        algorithm
          Pointer.update(node.cls, Class.mergeModifier(mod, Pointer.access(node.cls)));
        then
          ();

      case COMPONENT_NODE()
        algorithm
          Pointer.update(node.component, Component.mergeModifier(mod, Pointer.access(node.component)));
        then
          ();

      else ();
    end match;
  end mergeModifier;

  function setModifier
    input Modifier mod;
    input output InstNode node;
  algorithm
    () := match node
      case CLASS_NODE()
        algorithm
          Pointer.update(node.cls, Class.setModifier(mod, Pointer.access(node.cls)));
        then
          ();

      case COMPONENT_NODE()
        algorithm
          Pointer.update(node.component, Component.mergeModifier(mod, Pointer.access(node.component)));
        then
          ();

      else ();
    end match;
  end setModifier;

  function toPartialDAEType
    "Returns the DAE type for a class, without the list of variables filled in."
    input InstNode clsNode;
    output DAE.Type outType;
  algorithm
    outType := match clsNode
      local
        Class cls;
        ClassInf.State state;

      case CLASS_NODE()
        algorithm
          cls := Pointer.access(clsNode.cls);
        then
          match cls
            case Class.DAE_TYPE() then stripDAETypeVars(cls.ty);

            else
              algorithm
                state := Restriction.toDAE(Class.restriction(cls),
                                           scopePath(clsNode, includeRoot = true));
              then
                DAE.Type.T_COMPLEX(state, {}, NONE());

          end match;
    end match;
  end toPartialDAEType;

  function stripDAETypeVars
    input output DAE.Type ty;
  algorithm
    () := match ty
      case DAE.Type.T_COMPLEX()
        algorithm
          ty.varLst := {};
        then
          ();

      else ();
    end match;
  end stripDAETypeVars;

  function toFullDAEType
    "Returns the DAE type for a class, with the list of variables filled in."
    input InstNode clsNode;
    output DAE.Type outType;
  algorithm
    outType := match clsNode
      local
        Class cls;
        list<DAE.Var> vars;
        ClassInf.State state;

      case CLASS_NODE()
        algorithm
          cls := Pointer.access(clsNode.cls);
        then
          match cls
            case Class.DAE_TYPE() then cls.ty;

            else
              algorithm
                state := Restriction.toDAE(Class.restriction(cls),
                                           scopePath(clsNode, includeRoot = true));
                vars := ConvertDAE.makeTypeVars(clsNode);
                outType := DAE.Type.T_COMPLEX(state, vars, NONE());
                Pointer.update(clsNode.cls, Class.DAE_TYPE(outType));
              then
                outType;
          end match;
    end match;
  end toFullDAEType;

  function isBuiltin
    input InstNode node;
    output Boolean isBuiltin;
  algorithm
    isBuiltin := match node
      case CLASS_NODE(nodeType = InstNodeType.BUILTIN_CLASS()) then true;
      else false;
    end match;
  end isBuiltin;

  function isPartial
    input InstNode node;
    output Boolean isPartial;
  algorithm
    isPartial := match node
      case CLASS_NODE() then Class.isPartial(Pointer.access(node.cls));
      else false;
    end match;
  end isPartial;

  function clone
    input output InstNode node;
  algorithm
    () := match node
      local
        Class cls;
        Component comp;

      case CLASS_NODE()
        algorithm
          cls := Pointer.access(node.cls);
          cls := Class.classTreeApply(cls, ClassTree.clone);
          node.cls := Pointer.create(cls);
          node.caches := CachedData.empty();
        then
          ();

      case COMPONENT_NODE()
        algorithm
          comp := Pointer.access(node.component);
          comp := Component.setClassInstance(InstNode.clone(Component.classInstance(comp)), comp);
          node.component := Pointer.create(comp);
        then
          ();

      else ();
    end match;
  end clone;

  function getComments
    input InstNode node;
    input list<SCode.Comment> accumCmts = {};
    output list<SCode.Comment> cmts;
  algorithm
    cmts := match node
      local
        SCode.Comment cmt;
        Class cls;

      case CLASS_NODE(definition = SCode.CLASS(cmt = cmt))
        then cmt :: Class.getDerivedComments(Pointer.access(node.cls), accumCmts);

      else accumCmts;
    end match;
  end getComments;

  function copyInstancePtr
    input InstNode srcNode;
    input output InstNode dstNode;
  algorithm
    () := match (srcNode, dstNode)
      case (COMPONENT_NODE(), COMPONENT_NODE())
        algorithm
          dstNode.component := srcNode.component;
        then
          ();

      case (CLASS_NODE(), CLASS_NODE())
        algorithm
          dstNode.cls := srcNode.cls;
        then
          ();

    end match;
  end copyInstancePtr;

  function isRecord
    input InstNode node;
    output Boolean isRec;
  algorithm
    isRec := match node
      case CLASS_NODE() then Restriction.isRecord(Class.restriction(Pointer.access(node.cls)));
      case COMPONENT_NODE() then isRecord(Component.classInstance(Pointer.access(node.component)));
    end match;
  end isRecord;

  function isModel
    input InstNode node;
    output Boolean isModel;
  algorithm
    isModel := match node
      case CLASS_NODE() then Restriction.isModel(Class.restriction(Pointer.access(node.cls)));
      case COMPONENT_NODE() then isModel(Component.classInstance(Pointer.access(node.component)));
      else false;
    end match;
  end isModel;

  function hasBinding
    input InstNode node;
    output Boolean hasBinding;
  algorithm
    hasBinding := match node
      case COMPONENT_NODE()
        then Component.hasBinding(Pointer.access(node.component)) or hasBinding(instanceParent(node));
      else false;
    end match;
  end hasBinding;

  function getSections
    input InstNode node;
    output Sections sections;
  protected
    Class cls = InstNode.getClass(node);
  algorithm
    sections := match cls
      case Class.INSTANCED_CLASS() then cls.sections;
      case Class.TYPED_DERIVED() then getSections(cls.baseClass);

      else
        algorithm
          Error.assertion(false, getInstanceName() + " did not get an instanced class", sourceInfo());
        then fail();
    end match;
  end getSections;

  function hash
    "Returns the hash of an InstNode's name."
    input InstNode node;
    input Integer mod;
    output Integer hash = stringHashDjb2Mod(name(node), mod);
  end hash;

  function dimensionCount
    input InstNode node;
    output Integer count;
  algorithm
    count := match node
      case COMPONENT_NODE() then Component.dimensionCount(Pointer.access(node.component));
      case CLASS_NODE() then Class.dimensionCount(Pointer.access(node.cls));
      else 0;
    end match;
  end dimensionCount;

  function isClockType
    input InstNode node;
    output Boolean clock;
  algorithm
    clock := match node
      case CLASS_NODE(name = "Clock", nodeType = InstNodeType.BUILTIN_CLASS()) then true;
      else false;
    end match;
  end isClockType;

  function restriction
    input InstNode node;
    output Restriction res;
  algorithm
    res := match node
      case CLASS_NODE() then Class.restriction(Pointer.access(node.cls));
      case COMPONENT_NODE() then restriction(Component.classInstance(Pointer.access(node.component)));
      case INNER_OUTER_NODE() then restriction(node.innerNode);
      else Restriction.UNKNOWN();
    end match;
  end restriction;
end InstNode;

annotation(__OpenModelica_Interface="frontend");
end NFInstNode;
