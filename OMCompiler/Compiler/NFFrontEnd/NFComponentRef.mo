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

encapsulated uniontype NFComponentRef
  import BaseModelica;

protected
  import Component = NFComponent;
  import Absyn;
  import DAE;
  import Subscript = NFSubscript;
  import Type = NFType;
  import NFInstNode.InstNode;
  import NFInstNode.InstNodeType;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import NFPrefixes.{Variability, Purity, Visibility};
  import Class = NFClass;
  import NFClassTree.ClassTree;
  import List;
  import Prefixes = NFPrefixes;
  import MetaModelica.Dangerous.*;
  import JSON;
  import StringUtil;
  import Variable = NFVariable;
  import Binding = NFBinding;
  import NFBackendExtension.{BackendInfo, Annotations};

  import ComponentRef = NFComponentRef;

public
  type Origin = enumeration(
    CREF "From an Absyn cref.",
    SCOPE "From prefixing the cref with its scope.",
    ITERATOR "From an iterator."
  );

  record CREF
    InstNode node;
    list<Subscript> subscripts;
    Type ty "The type of the node, without taking subscripts into account.";
    Origin origin;
    ComponentRef restCref;
  end CREF;

  record EMPTY end EMPTY;
  record WILD end WILD;

  function fromNode
    input InstNode node;
    input Type ty;
    input list<Subscript> subs = {};
    input Origin origin = Origin.CREF;
    output ComponentRef cref = CREF(node, subs, ty, origin, EMPTY());
  end fromNode;

  function prefixCref
    input InstNode node;
    input Type ty;
    input list<Subscript> subs;
    input ComponentRef restCref;
    output ComponentRef cref = CREF(node, subs, ty, Origin.CREF, restCref);
  end prefixCref;

  function prefixScope
    input InstNode node;
    input Type ty;
    input list<Subscript> subs;
    input ComponentRef restCref;
    output ComponentRef cref = CREF(node, subs, ty, Origin.SCOPE, restCref);
  end prefixScope;

  function fromAbsyn
    input InstNode node;
    input list<Absyn.Subscript> subs;
    input ComponentRef restCref = EMPTY();
    output ComponentRef cref;
  protected
    list<Subscript> sl;
  algorithm
    sl := list(Subscript.RAW_SUBSCRIPT(s) for s in subs);
    cref := CREF(node, sl, Type.UNKNOWN(), Origin.CREF, restCref);
  end fromAbsyn;

  function fromAbsynCref
    input Absyn.ComponentRef acref;
    input ComponentRef restCref = EMPTY();
    output ComponentRef cref;
  algorithm
    cref := match acref
      case Absyn.ComponentRef.CREF_IDENT()
        then fromAbsyn(InstNode.NAME_NODE(acref.name), acref.subscripts, restCref);

      case Absyn.ComponentRef.CREF_QUAL()
        then fromAbsynCref(acref.componentRef,
               fromAbsyn(InstNode.NAME_NODE(acref.name), acref.subscripts, restCref));

      case Absyn.ComponentRef.CREF_FULLYQUALIFIED()
        then fromAbsynCref(acref.componentRef);

      case Absyn.ComponentRef.WILD() then WILD();
      case Absyn.ComponentRef.ALLWILD() then WILD();
    end match;
  end fromAbsynCref;

  function fromBuiltin
    input InstNode node;
    input Type ty;
    output ComponentRef cref = CREF(node, {}, ty, Origin.SCOPE, EMPTY());
  end fromBuiltin;

  function makeIterator
    input InstNode node;
    input Type ty = InstNode.getType(node);
    output ComponentRef cref = CREF(node, {}, ty, Origin.ITERATOR, EMPTY());
  end makeIterator;

  function isWild
    input ComponentRef cref;
    output Boolean isWild;
  algorithm
    isWild := match cref
      case WILD() then true;
      else false;
    end match;
  end isWild;

  function isEmpty
    input ComponentRef cref;
    output Boolean isEmpty;
  algorithm
    isEmpty := match cref
      case EMPTY() then true;
      else false;
    end match;
  end isEmpty;

  function isSimple
    input ComponentRef cref;
    output Boolean isSimple;
  algorithm
    isSimple := match cref
      case CREF(restCref = EMPTY()) then true;
      else false;
    end match;
  end isSimple;

  function isTopLevel
    input ComponentRef cref;
    output Boolean b;
  protected
    function isTopLevelRecord
      input ComponentRef cref;
      output Boolean b;
    algorithm
      b := match cref
        case CREF() then Type.isRecord(cref.ty) and isTopLevelRecord(cref.restCref);
        case EMPTY() then true;
        else false;
      end match;
    end isTopLevelRecord;
  algorithm
    b := match cref
      case CREF(restCref = EMPTY()) then true;
      case CREF() then isTopLevelRecord(cref.restCref);
      else false;
    end match;
  end isTopLevel;

  function isCref
    input ComponentRef cref;
    output Boolean isCref;
  algorithm
    isCref := match cref
      case CREF() then true;
      else false;
    end match;
  end isCref;

  function isIterator
    input ComponentRef cref;
    output Boolean isIterator;
  algorithm
    isIterator := match cref
      case CREF(origin = Origin.ITERATOR) then true;
      else false;
    end match;
  end isIterator;

  function isInput
    input ComponentRef cref;
    output Boolean res;
  algorithm
    res := match cref
      case CREF() then InstNode.isInput(cref.node);
      else false;
    end match;
  end isInput;

  function isOutput
    input ComponentRef cref;
    output Boolean res;
  algorithm
    res := match cref
      case CREF() then InstNode.isOutput(cref.node);
      else false;
    end match;
  end isOutput;

  function isNameNode
    input ComponentRef cref;
    output Boolean res;
  algorithm
    res := match cref
      case CREF(node = InstNode.NAME_NODE()) then true;
      else false;
    end match;
  end isNameNode;

  function isEqualRecordChild
    "R.x and R can be considered equal in certain cases if x is the only attribute of R"
    input ComponentRef child;
    input ComponentRef recd;
    output Boolean b = ComponentRef.size(child, true) == ComponentRef.size(recd, true);
  algorithm
    if b then
      b := isRecordChild(child, recd);
    end if;
  end isEqualRecordChild;

  function isRecordChild
    input ComponentRef child;
    input ComponentRef recd;
    output Boolean b;
  algorithm
    b := match recd
      case CREF() then ComponentRef.isEqual(child, recd) or isRecordChild(child, recd.restCref);
      else false;
    end match;
  end isRecordChild;

  function node
    input ComponentRef cref;
    output InstNode node;
  algorithm
    CREF(node = node) := cref;
  end node;

  function nodes
    input ComponentRef cref;
    input list<InstNode> accum = {};
    output list<InstNode> nodes;
  algorithm
    nodes := match cref
      case CREF() then nodes(cref.restCref, cref.node :: accum);
      else accum;
    end match;
  end nodes;

  function nodesIncludingSplitSubs
    input ComponentRef cref;
    input list<InstNode> accum = {};
    output list<InstNode> nodes = accum;
  protected
    InstNode node;
  algorithm
    nodes := match cref
      case CREF()
        algorithm
          for s in cref.subscripts loop
            if Subscript.isSplitIndex(s) then
              Subscript.SPLIT_INDEX(node = node) := s;
              nodes := node :: nodes;
            end if;
          end for;
        then
          nodesIncludingSplitSubs(cref.restCref, cref.node :: nodes);

      else nodes;
    end match;
  end nodesIncludingSplitSubs;

  function containsNode
    input ComponentRef cref;
    input InstNode node;
    output Boolean res;
  algorithm
    res := match cref
      case CREF()
        then InstNode.refEqual(cref.node, node) or containsNode(cref.restCref, node);
      else false;
    end match;
  end containsNode;

  function nodeType
    input ComponentRef cref;
    output Type ty;
  algorithm
    CREF(ty = ty) := cref;
  end nodeType;

  function setNodeType
    input Type ty;
    input output ComponentRef cref;
  algorithm
    () := match cref
      case CREF()
        algorithm
          cref.ty := ty;
        then
          ();

      else ();
    end match;
  end setNodeType;

  function updateNodeType
    input output ComponentRef cref;
  algorithm
    () := match cref
      case CREF() guard InstNode.isComponent(cref.node)
        algorithm
          cref.ty := InstNode.getType(cref.node);
        then
          ();

      else ();
    end match;
  end updateNodeType;

  function scalarType
    input ComponentRef cref;
    output Type ty;
  algorithm
    CREF(ty = ty) := cref;
    ty := Type.arrayElementType(ty);
  end scalarType;

  function applyToType
    input output ComponentRef cref;
    input typeFunc func;
    partial function typeFunc
      input output Type ty;
    end typeFunc;
  algorithm
    cref := match cref
      case CREF() algorithm
        cref.ty := func(cref.ty);
        cref.restCref := applyToType(cref.restCref, func);
      then cref;
      else cref;
    end match;
  end applyToType;

  function firstName
    input ComponentRef cref;
    input Boolean baseModelica = false;
    output String name;
  algorithm
    name := match cref
      case CREF() then InstNode.name(cref.node);
      case WILD() then if baseModelica then "" else "_";
      else "";
    end match;
  end firstName;

  function first
    input output ComponentRef cref;
  algorithm
    () := match cref
      case CREF()
        algorithm
          cref.restCref := EMPTY();
        then
          ();

      else ();
    end match;
  end first;

  function rest
    input ComponentRef cref;
    output ComponentRef restCref;
  algorithm
    CREF(restCref = restCref) := cref;
  end rest;

  function last
    input ComponentRef cref;
    output ComponentRef lastCref;
  algorithm
    lastCref := match cref
      case CREF(restCref = CREF()) then last(cref.restCref);
      else cref;
    end match;
  end last;

  function firstNonScope
    input ComponentRef cref;
    output ComponentRef first;
  protected
    ComponentRef rest_cr = rest(cref);
  algorithm
    first := match rest_cr
      case CREF(origin = Origin.SCOPE) then cref;
      case EMPTY() then cref;
      else firstNonScope(rest_cr);
    end match;
  end firstNonScope;

  function append
    input output ComponentRef cref;
    input ComponentRef restCref;
  algorithm
    cref := match cref
      case CREF()
        algorithm
          cref.restCref := append(cref.restCref, restCref);
        then
          cref;

      case EMPTY() then restCref;
    end match;
  end append;

  function appendScope
    "Appends the instance scope of the given node to a component reference, as
     defined by InstNode.scopeList."
    input InstNode scope;
    input output ComponentRef cref;
    input Boolean includeRoot = false "Whether to include the root class name or not.";
  protected
    ComponentRef prefix;
  algorithm
    prefix := fromNodeList(InstNode.scopeList(scope, includeRoot));

    if not ComponentRef.isEmpty(prefix) then
      cref := append(cref, prefix);
      cref := removeOuterCrefPrefix(cref);
    end if;
  end appendScope;

  function prepend
    input ComponentRef restCref;
    input output ComponentRef cref;
  algorithm
    cref := match cref
      case CREF()
        algorithm
          cref.restCref := restCref;
        then
          cref;

      case EMPTY() then restCref;
    end match;
  end prepend;

  function getComponentType
    "Returns the type of the component the given cref refers to, without taking
     subscripts into account."
    input ComponentRef cref;
    output Type ty;
  algorithm
    ty := match cref
      case CREF() then cref.ty;
      else Type.UNKNOWN();
    end match;
  end getComponentType;

  function getSubscriptedType
    "Returns the type of a cref, with the subscripts taken into account."
    input ComponentRef cref;
    input Boolean includeScope = false;
    output Type ty;
  algorithm
    ty := match cref
      case CREF()
        then getSubscriptedType2(cref.restCref, Type.subscript(cref.ty, cref.subscripts), includeScope);
      else Type.UNKNOWN();
    end match;
  end getSubscriptedType;

  function getSubscriptedType2
    input ComponentRef restCref;
    input Type accumTy;
    input Boolean includeScope;
    output Type ty;
  algorithm
    ty := match restCref
      case CREF()
        guard restCref.origin == Origin.CREF or includeScope
        algorithm
          ty := Type.liftArrayLeftList(accumTy,
            Type.arrayDims(Type.subscript(restCref.ty, restCref.subscripts)));
        then
          getSubscriptedType2(restCref.restCref, ty, includeScope);

      else accumTy;
    end match;
  end getSubscriptedType2;

  function lookupVarAttr
    input ComponentRef cref;
    input String attr_name;
    output Option<Expression> attrValue;
  algorithm
    attrValue := match cref
      local
        Pointer<Variable> v;
      case CREF(node = InstNode.VAR_NODE(varPointer = v))
        then Binding.typedExp(Variable.lookupTypeAttribute(attr_name, Pointer.access(v)));
      else NONE();
    end match;
  end lookupVarAttr;

  function nodeVariability
    "Returns the variability of the component node the cref refers to."
    input ComponentRef cref;
    output Variability var;
  algorithm
    var := match cref
      local
        Pointer<Variable> v;
      case CREF(node = InstNode.COMPONENT_NODE())
        then Component.variability(InstNode.component(cref.node));
      case CREF(node = InstNode.CLASS_NODE()) then Variability.CONSTANT;
      case CREF(node = InstNode.VAR_NODE(varPointer = v)) then Variable.variability(Pointer.access(v));
      else Variability.CONTINUOUS;
    end match;
  end nodeVariability;

  function isResizable
    "Returns true if the cref refers to a resizable component (frontend) or variable (backend)."
    input ComponentRef cref;
    output Boolean b;
  algorithm
    b := match cref
      local
        Pointer<Variable> v;

      // frontend check
      case CREF(node = InstNode.COMPONENT_NODE())
        then Component.isResizable(InstNode.component(cref.node));

      // backend check
      case CREF(node = InstNode.VAR_NODE(varPointer = v)) then match Pointer.access(v)
          case Variable.VARIABLE(backendinfo = BackendInfo.BACKEND_INFO(annotations = Annotations.ANNOTATIONS(resizable = b))) then b;
          else false;
        end match;

      // default
      else false;
    end match;
  end isResizable;

  function subscriptsVariability
    input ComponentRef cref;
    input output Variability var = Variability.CONSTANT;
  algorithm
    () := match cref
      case CREF(origin = Origin.CREF)
        algorithm
          for sub in cref.subscripts loop
            var := Prefixes.variabilityMax(var, Subscript.variability(sub));
          end for;
        then
          ();

      else ();
    end match;
  end subscriptsVariability;

  function variability
    "Returns the variability of the cref, with the variability of the subscripts
     taken into account."
    input ComponentRef cref;
    output Variability var = Prefixes.variabilityMax(nodeVariability(cref),
                                                     subscriptsVariability(cref));
  end variability;

  function purity
    input ComponentRef cref;
    output Purity pur;
  protected
    function sub_purity
      input Subscript sub;
      input output Purity pur;
    algorithm
      pur := Prefixes.purityMin(pur, Subscript.purity(sub));
    end sub_purity;
  algorithm
    pur := match cref
      case CREF(origin = Origin.ITERATOR) then Purity.IMPURE;
      case CREF() then foldSubscripts(cref, sub_purity, Purity.PURE);
      else Purity.IMPURE;
    end match;
  end purity;

  function visibility
    input ComponentRef cref;
    output Visibility vis;
  algorithm
    vis := match cref
      case CREF() then
        if InstNode.isProtected(cref.node) then
          Visibility.PROTECTED else visibility(cref.restCref);

      else Visibility.PUBLIC;
    end match;
  end visibility;

  function rename
    input String name;
    input output ComponentRef cref;
  algorithm
    cref := match cref
      case CREF()
        algorithm
          cref.node := InstNode.rename(name, cref.node);
        then
          cref;

      else cref;
    end match;
  end rename;

  function addSubscript
    input Subscript subscript;
    input output ComponentRef cref;
  algorithm
    () := match cref
      case CREF()
        algorithm
          cref.subscripts := listAppend(cref.subscripts, {subscript});
        then
          ();
    end match;
  end addSubscript;

  function mergeSubscripts
    "merges subscripts to a cref while respecting the dimension
    sizes of the types and previous subscripts.
    if backend = true it discards one subscript for scalars if
    it is exactly INTEGER(1). (needed for slicing)"
    input list<Subscript> subscripts;
    input output ComponentRef cref;
    input Boolean applyToScope = false;
    input Boolean backend = false;
    input Boolean reverse = false;
  protected
    ComponentRef old_cref = cref;
    list<Subscript> new_subscripts;
  algorithm
    (new_subscripts, cref) := mergeSubscripts2(subscripts, cref, applyToScope, backend, reverse);
    if not listEmpty(new_subscripts) then
      Error.assertion(false, getInstanceName() + " failed because the subscripts "
        + List.toString(subscripts, Subscript.toString) + " could not be fully merged onto "
        + ComponentRef.toString(old_cref) + ".\nResult: " + ComponentRef.toString(cref)
        + " with leftover: " + List.toString(new_subscripts, Subscript.toString) + ".", sourceInfo());
      fail();
    end if;
  end mergeSubscripts;

  function mergeSubscripts2
    input output list<Subscript> subscripts;
    input output ComponentRef cref;
    input Boolean applyToScope;
    input Boolean backend;
    input Boolean reverse;
  algorithm
    (subscripts, cref) := match cref
      local
        ComponentRef rest_cref;
        list<Subscript> cref_subs;

      case CREF(subscripts = cref_subs)
        guard applyToScope or cref.origin == Origin.CREF
        algorithm
          if not reverse then
            (subscripts, rest_cref) := mergeSubscripts2(subscripts, cref.restCref, applyToScope, backend, reverse);
          end if;

          if not listEmpty(subscripts) then
            (cref_subs, subscripts) :=
              Subscript.mergeList(subscripts, cref_subs, Type.dimensionCount(cref.ty), backend);
          end if;

          if reverse then
            (subscripts, rest_cref) := mergeSubscripts2(subscripts, cref.restCref, applyToScope, backend, reverse);
          end if;
        then
          (subscripts, CREF(cref.node, cref_subs, cref.ty, cref.origin, rest_cref));

      else (subscripts, cref);
    end match;
  end mergeSubscripts2;

  function mergeSubscriptsMapped
    "merges subscripts to a cref while respecting a map that defines the type to subscript mapping.
    To be used in the backend when the subscripts have to be added to a very specific dimension space
    Note: due to technical reasons the mapping is done in two steps"
    input output ComponentRef cref;
    input UnorderedMap<list<Dimension>, list<ComponentRef>> dims_map;
    input UnorderedMap<ComponentRef, Subscript> iter_map;
  algorithm
    cref := match cref
      local
        list<Dimension> dims;
        Option<list<ComponentRef>> iter_crefs;
        ComponentRef new_cref;
        list<Subscript> new_subs, rest_subs;
        Type ty = getSubscriptedType(cref);

      // local array type -> try to find the current dimension configuration in the map and add subscripts
      case CREF() guard(Type.isArray(ty)) algorithm
        // get dimensions and check in map
        dims          := Type.arrayDims(ty);
        iter_crefs    := UnorderedMap.get(dims, dims_map);
        if Util.isSome(iter_crefs) then
          // dimension configuration was found, map to subscripts and apply in reverse
          new_subs    := list(UnorderedMap.getSafe(iter_name, iter_map, sourceInfo()) for iter_name in Util.getOption(iter_crefs));
          new_cref    := mergeSubscripts(new_subs, cref, true, true, true);
        else
          // not found, just keep current cref
          new_cref    := cref;
        end if;

        // apply to restCref afterwards such that the outermost dimensions are handled first
        // this is important because the full dimension list is considered when checking in the map
        new_cref := match new_cref
          case CREF() algorithm
            new_cref.restCref := mergeSubscriptsMapped(new_cref.restCref, dims_map, iter_map);
          then new_cref;
          else new_cref;
        end match;
      then new_cref;

      // local scalar type -> only apply to
      case CREF() algorithm
        // apply to restCref
        cref.restCref := mergeSubscriptsMapped(cref.restCref, dims_map, iter_map);
      then cref;

      else cref;
    end match;
  end mergeSubscriptsMapped;

  function hasSubscripts
    input ComponentRef cref;
    output Boolean hasSubscripts;
  algorithm
    hasSubscripts := match cref
      case CREF()
        then not listEmpty(cref.subscripts) or hasSubscripts(cref.restCref);

      else false;
    end match;
  end hasSubscripts;

  function hasNonModelSubscripts
    input ComponentRef cref;
    output Boolean hasSubscripts;
  algorithm
    hasSubscripts := match cref
      case CREF() guard(InstNode.isModel(cref.node))
        then hasNonModelSubscripts(cref.restCref);
      case CREF()
        then not listEmpty(cref.subscripts) or hasNonModelSubscripts(cref.restCref);
      else false;
    end match;
  end hasNonModelSubscripts;

  function hasSplitSubscripts
    input ComponentRef cref;
    output Boolean res;
  algorithm
    res := match cref
      case CREF(origin = Origin.CREF)
        then List.any(cref.subscripts, Subscript.isSplitIndex) or
             hasSplitSubscripts(cref.restCref);

      else false;
    end match;
  end hasSplitSubscripts;

  function expandSplitSubscripts
    input output ComponentRef cref;
  algorithm
    () := match cref
      case CREF(origin = Origin.CREF)
        algorithm
          cref.subscripts := Subscript.expandSplitIndices(cref.subscripts, {});
          cref.restCref := expandSplitSubscripts(cref.restCref);
        then
          ();

      else ();
    end match;
  end expandSplitSubscripts;

  function getSubscripts
    input ComponentRef cref;
    output list<Subscript> subscripts;
  algorithm
    subscripts := match cref
      case CREF() then cref.subscripts;
      else {};
    end match;
  end getSubscripts;

  function setSubscripts
    "Sets the subscripts of the first part of a cref."
    input list<Subscript> subscripts;
    input output ComponentRef cref;
  algorithm
    () := match cref
      case CREF()
        algorithm
          cref.subscripts := subscripts;
        then
          ();
    end match;
  end setSubscripts;

  function setSubscriptsList
    "Sets the subscripts of each part of a cref to the corresponding list of subscripts."
    input list<list<Subscript>> subscripts;
    input output ComponentRef cref;
  algorithm
    cref := match (subscripts, cref)
      local
        list<Subscript> subs;
        list<list<Subscript>> rest_subs;
        ComponentRef rest_cref;

      case (subs :: rest_subs, CREF())
        algorithm
          rest_cref := setSubscriptsList(rest_subs, cref.restCref);
        then
          CREF(cref.node, subs, cref.ty, cref.origin, rest_cref);

      case ({}, _) then cref;
    end match;
  end setSubscriptsList;

  function copySubscripts
    "merges the subscritps of origin to the target.
    Note: does not remove subscripts already on target!"
    input ComponentRef origin;
    input output ComponentRef target;
  protected
    list<Subscript> subs = ComponentRef.subscriptsAllFlat(origin);
  algorithm
    if not listEmpty(subs) then
      target := ComponentRef.mergeSubscripts(subs, target, true, true);
    end if;
  end copySubscripts;

  function subscriptsAllWithWhole
    "Returns all subscripts of a cref in reverse order while not omitting whole dimensions.
     Ex: a[1, 2].b[4].c[6, 3] => {{6,3}, {4}, {1,2}}"
    input ComponentRef cref;
    input list<list<Subscript>> accumSubs = {};
    output list<list<Subscript>> subscripts;
  algorithm
    subscripts := match cref
      local
        list<Integer> sizes_;
        list<Subscript> subs;

      case CREF(subscripts = {}) guard(not backendCref(cref)) algorithm
        sizes_ := sizes_local(cref, false);
        subs := {};
        for size in listReverse(sizes_) loop
          if size <> 1 then
            subs := Subscript.SLICE(Expression.RANGE(Type.INTEGER(), Expression.INTEGER(1), NONE(), Expression.INTEGER(size))) :: subs;
          end if;
        end for;
      then subscriptsAllWithWhole(cref.restCref, subs :: accumSubs);

      case CREF() then subscriptsAllWithWhole(cref.restCref, cref.subscripts :: accumSubs);

      else accumSubs;
    end match;
  end subscriptsAllWithWhole;

  function subscriptsAllWithWholeFlat
    "Returns all subscripts of a cref as a flat list in the correct order while not omitting whole dimensions.
     Ex: a[1, 2].b[4].c[6, 3] => {1, 2, 4, 6, 3}"
    input ComponentRef cref;
    output list<Subscript> subscripts = List.flatten(subscriptsAllWithWhole(cref));
  end subscriptsAllWithWholeFlat;

  function subscriptsAll
    "Returns all subscripts of a cref.
     Ex: a[1, 2].b[4].c[6, 3] => {{1,2}, {4}, {6,3}}"
    input ComponentRef cref;
    output list<list<Subscript>> subscripts = listReverseInPlace(subscriptsAllReverse(cref));
  end subscriptsAll;

  function subscriptsAllReverse
    "Returns all subscripts of a cref in reverse order.
     Ex: a[1, 2].b[4].c[6, 3] => {{6,3}, {4}, {1,2}}"
    input ComponentRef cref;
    input list<list<Subscript>> accumSubs = {};
    output list<list<Subscript>> subscripts;
  algorithm
    subscripts := match cref
      case CREF() then subscriptsAllReverse(cref.restCref, cref.subscripts :: accumSubs);
      else accumSubs;
    end match;
  end subscriptsAllReverse;

  function subscriptsAllFlat
    "Returns all subscripts of a cref as a flat list in the correct order.
     Ex: a[1, 2].b[4].c[6, 3] => {1, 2, 4, 6, 3}"
    input ComponentRef cref;
    output list<Subscript> subscripts = List.flattenReverse(subscriptsAll(cref));
  end subscriptsAllFlat;

  function subscriptsExceptModel
    "Returns all subscripts of a cref leaving out model subs.
     Ex: a[1, 2].b[4].c[6, 3] => {{1,2}, {4}, {6,3}}"
    input ComponentRef cref;
    input list<list<Subscript>> accumSubs = {};
    output list<list<Subscript>> subscripts;
  algorithm
    subscripts := match cref
      case CREF() guard(InstNode.isModel(cref.node))  then subscriptsExceptModel(cref.restCref, {} :: accumSubs);
      case CREF()                                     then subscriptsExceptModel(cref.restCref, cref.subscripts :: accumSubs);
                                                      else accumSubs;
    end match;
  end subscriptsExceptModel;

  function subscriptsN
    "Returns the subscripts of the N first parts of a cref in reverse order."
    input ComponentRef cref;
    input Integer n;
    output list<list<Subscript>> subscripts = {};
  protected
    list<Subscript> subs;
    ComponentRef rest = cref;
  algorithm
    for i in 1:n loop
      if isEmpty(rest) then
        break;
      end if;

      CREF(subscripts = subs, restCref = rest) := rest;
      subscripts := subs :: subscripts;
    end for;
  end subscriptsN;

  function transferSubscripts
    "Copies subscripts from one cref to another, overwriting any subscripts on
     the destination cref."
    input ComponentRef srcCref;
    input ComponentRef dstCref;
    output ComponentRef cref;
  protected
    list<Subscript> subs;
  algorithm
    cref := match (srcCref, dstCref)
      case (EMPTY(), _) then dstCref;
      case (_, EMPTY()) then dstCref;
      case (_, WILD()) then dstCref;
      case (_, CREF(origin = Origin.ITERATOR)) then dstCref;

      case (CREF(), CREF(origin = Origin.CREF))
        algorithm
          dstCref.restCref := transferSubscripts(srcCref, dstCref.restCref);
        then
          dstCref;

      case (CREF(), CREF()) guard InstNode.refEqual(srcCref.node, dstCref.node)
        algorithm
          cref := transferSubscripts(srcCref.restCref, dstCref.restCref);
          // Don't remove subscripts unless there's something to replace them with.
          // This avoids loosing subscripts when flattening an already flattened cref with
          // a prefix without subscripts, which can happen in the non-scalarized path.
          subs := if listEmpty(srcCref.subscripts) then dstCref.subscripts else srcCref.subscripts;
        then
          CREF(dstCref.node, subs, dstCref.ty, dstCref.origin, cref);

      case (CREF(), CREF())
        then transferSubscripts(srcCref.restCref, dstCref);

      else
        algorithm
          Error.assertion(false, getInstanceName() + " failed", sourceInfo());
        then
          fail();
    end match;
  end transferSubscripts;

  function applySubscripts
    input ComponentRef cref;
    input FuncT func;
    input Boolean applyToScope = false;

    partial function FuncT
      input Subscript subscript;
    end FuncT;
  algorithm
    () := match cref
      case CREF() guard applyToScope or cref.origin == Origin.CREF
        algorithm
          for sub in cref.subscripts loop
            func(sub);
          end for;

          applySubscripts(cref.restCref, func, applyToScope);
        then
          ();

      else ();
    end match;
  end applySubscripts;

  function foldSubscripts<ArgT>
    input ComponentRef cref;
    input FuncT func;
    input output ArgT arg;
    input Boolean applyToScope = false;

    partial function FuncT
      input Subscript subscript;
      input output ArgT arg;
    end FuncT;
  algorithm
    arg := match cref
      case CREF() guard applyToScope or cref.origin == Origin.CREF
        algorithm
          for sub in cref.subscripts loop
            arg := func(sub, arg);
          end for;
        then
          foldSubscripts(cref.restCref, func, arg, applyToScope);

      else arg;
    end match;
  end foldSubscripts;

  function mapSubscripts
    input output ComponentRef cref;
    input FuncT func;
    input Boolean applyToScope = false;

    partial function FuncT
      input output Subscript subscript;
    end FuncT;
  algorithm
    cref := match cref
      case CREF() guard applyToScope or cref.origin == Origin.CREF
        algorithm
          if not listEmpty(cref.subscripts) then
            cref.subscripts := list(func(s) for s in cref.subscripts);
          end if;

          cref.restCref := mapSubscripts(cref.restCref, func, applyToScope);
        then
          cref;

      else cref;
    end match;
  end mapSubscripts;

  function fillSubscripts
    "Fills in any unsubscripted dimensions in the cref with : subscripts."
    input output ComponentRef cref;
  algorithm
    () := match cref
      local
        list<Dimension> dims;
        Integer dim_count, sub_count;

      case CREF()
        algorithm
          dims := Type.arrayDims(cref.ty);
          dim_count := listLength(dims);
          sub_count := listLength(cref.subscripts);

          if sub_count < dim_count then
            cref.subscripts := List.consN(dim_count - sub_count, Subscript.WHOLE(), cref.subscripts);
          end if;

          cref.restCref := fillSubscripts(cref.restCref);
        then
          ();

      else ();
    end match;
  end fillSubscripts;

  function replaceWholeSubscripts
    "Replaces any : subscripts with slice subscripts for the corresponding dimension."
    input output ComponentRef cref;
  algorithm
    () := match cref
      local
        list<Dimension> dims;
        list<Subscript> subs;

      case CREF()
        algorithm
          if List.any(cref.subscripts, Subscript.isWhole) then
            dims := Type.arrayDims(cref.ty);
            subs := {};

            for s in cref.subscripts loop
              if Subscript.isWhole(s) then
                s := Subscript.fromDimension(listHead(dims));
              end if;

              subs := s :: subs;
              dims := listRest(dims);
            end for;

            cref.subscripts := listReverseInPlace(subs);
          end if;

          cref.restCref := replaceWholeSubscripts(cref.restCref);
        then
          ();

      else ();
    end match;
  end replaceWholeSubscripts;

  function combineSubscripts
    "Moves all subscripts to the end of the cref.
     Ex: a[1, 2].b[4] => a.b[1, 2, 4]"
    input output ComponentRef cref;
  protected
    list<Subscript> subs;
  algorithm
    // Fill in : subscripts where needed so the cref is fully subscripted.
    cref := fillSubscripts(cref);
    // Fetch all the subscripts.
    subs := List.flatten(subscriptsAllReverse(cref));

    if listEmpty(subs) then
      return;
    end if;

    // Replace the cref's subscripts.
    cref := setSubscripts(subs, stripSubscriptsAll(cref));
  end combineSubscripts;

  function compare
    input ComponentRef cref1;
    input ComponentRef cref2;
    output Integer comp;
  algorithm
    comp := match (cref1, cref2)
      case (CREF(), CREF())
        algorithm
          comp := stringCompare(InstNode.name(cref1.node), InstNode.name(cref2.node));

          if comp <> 0 then
            return;
          end if;

          comp := Subscript.compareList(cref1.subscripts, cref2.subscripts);

          if comp <> 0 then
            return;
          end if;
        then
          compare(cref1.restCref, cref2.restCref);

      case (EMPTY(), EMPTY()) then 0;
      case (WILD(), WILD())   then 0;
      case (_, EMPTY())       then 1;
      case (_, WILD())        then 1;
      case (EMPTY(), _)       then -1;
      case (WILD(), _)        then -1;
      else algorithm
        Error.assertion(false, getInstanceName() + " failed", sourceInfo());
      then fail();
    end match;
  end compare;

  function isEqual
    input ComponentRef cref1;
    input ComponentRef cref2;
    output Boolean b;
  algorithm
    if referenceEq(cref1, cref2) then
      b := true;
      return;
    end if;

    b := match (cref1, cref2)
      case (CREF(), CREF()) algorithm
        then InstNode.name(cref1.node) == InstNode.name(cref2.node) and
          Subscript.isEqualList(cref1.subscripts, cref2.subscripts) and
          isEqual(cref1.restCref, cref2.restCref);
      case (EMPTY(), EMPTY()) then true;
      case (WILD(), WILD()) then true;
      else false;
    end match;
  end isEqual;

  function isEqualStrip
    "strips the subscripts before comparing. Used for non expandend variables"
    input ComponentRef cref1;
    input ComponentRef cref2;
    output Boolean b;
  algorithm
    if referenceEq(cref1, cref2) then
      b := true;
      return;
    end if;

    b := match (cref1, cref2)
      case (CREF(), CREF()) algorithm
        then InstNode.name(cref1.node) == InstNode.name(cref2.node) and
          isEqualStrip(cref1.restCref, cref2.restCref);
      case (EMPTY(), EMPTY()) then true;
      case (WILD(), WILD()) then true;
      else false;
    end match;
  end isEqualStrip;

  function isLess
    input ComponentRef cref1;
    input ComponentRef cref2;
    output Boolean isLess = compare(cref1, cref2) < 0;
  end isLess;

  function isGreater
    input ComponentRef cref1;
    input ComponentRef cref2;
    output Boolean isGreater = compare(cref1, cref2) > 0;
  end isGreater;

  function isPrefix
    input ComponentRef cref1;
    input ComponentRef cref2;
    output Boolean isPrefix;
  algorithm
    if referenceEq(cref1, cref2) then
      isPrefix := true;
      return;
    end if;

    isPrefix := match (cref1, cref2)
      case (CREF(), CREF())
        then
          if InstNode.name(cref1.node) == InstNode.name(cref2.node) then
             isEqual(cref1.restCref, cref2.restCref)
          else isEqual(cref1, cref2.restCref);
      else false;
    end match;
  end isPrefix;

  function backendCref
    "returns true if the cref was generated by the backend (starts with $)"
    input ComponentRef cref;
    output Boolean b = StringUtil.startsWith(firstName(cref), "$");
  end backendCref;

  function toAbsyn
    input ComponentRef cref;
    output Absyn.ComponentRef acref;
  algorithm
    acref := match cref
      case CREF()
        algorithm
          acref := Absyn.ComponentRef.CREF_IDENT(InstNode.name(cref.node),
            list(Subscript.toAbsyn(s) for s in cref.subscripts));
        then
          toAbsyn_impl(cref.restCref, acref);

      case WILD() then Absyn.ComponentRef.WILD();
    end match;
  end toAbsyn;

  function toAbsyn_impl
    input ComponentRef cref;
    input Absyn.ComponentRef accumCref;
    output Absyn.ComponentRef acref;
  algorithm
    acref := match cref
      case EMPTY() then accumCref;

      case CREF()
        algorithm
          acref := Absyn.ComponentRef.CREF_QUAL(InstNode.name(cref.node),
            list(Subscript.toAbsyn(s) for s in cref.subscripts), accumCref);
        then
          toAbsyn_impl(cref.restCref, acref);

    end match;
  end toAbsyn_impl;

  function toDAE
    input ComponentRef cref;
    output DAE.ComponentRef dcref;
  algorithm
    dcref := match cref
      case CREF()
        algorithm
          dcref := DAE.ComponentRef.CREF_IDENT(InstNode.name(cref.node), Type.toDAE(cref.ty),
            list(Subscript.toDAE(s) for s in cref.subscripts));
        then
          toDAE_impl(cref.restCref, dcref);

      case WILD() then DAE.ComponentRef.WILD();
    end match;
  end toDAE;

  function toDAE_impl
    input ComponentRef cref;
    input DAE.ComponentRef accumCref;
    output DAE.ComponentRef dcref;
  algorithm
    dcref := match cref
      local
        Type ty;
        DAE.Type dty;

      case EMPTY() then accumCref;
      case CREF()
        algorithm
          // If the type is unknown here it's likely because the cref part is
          // from a scope prefix, which the typing doesn't bother typing since
          // that introduces cycles in the typing. We could patch the crefs
          // after the typing, but the new frontend doesn't use these types anyway.
          // So instead we just fetch the type of the node if the type is unknown.
          ty := if Type.isUnknown(cref.ty) then InstNode.getType(cref.node) else cref.ty;
          dty := Type.toDAE(ty, makeTypeVars = false);
          dcref := DAE.ComponentRef.CREF_QUAL(InstNode.name(cref.node), dty,
            list(Subscript.toDAE(s) for s in cref.subscripts), accumCref);
        then
          toDAE_impl(cref.restCref, dcref);
    end match;
  end toDAE_impl;

  function toString
    input ComponentRef cref;
    output String str;
  algorithm
    str := stringDelimitList(toString_impl(cref, {}), ".");
  end toString;

  function toString_impl
    input ComponentRef cref;
    input output list<String> strl;
  algorithm
    strl := match cref
      local
        String str;

      case CREF()
        algorithm
          str := InstNode.name(cref.node) + Subscript.toStringList(cref.subscripts);
        then
          toString_impl(cref.restCref, str :: strl);

      case WILD() then "_" :: strl;
      else strl;
    end match;
  end toString_impl;

  function toFlatString
    input ComponentRef cref;
    input BaseModelica.OutputFormat format;
    output String str;
  protected
    list<String> strl;
    list<ComponentRef> crefs;
    list<Subscript> subs;
    ComponentRef cr;
  algorithm
    str := firstName(cref, baseModelica = true);

    if str == "time" or str == "" then
      return;
    end if;

    crefs := toListReverse(cref);
    strl := {"'"};
    subs := {};

    if format.scalarizeMode == BaseModelica.ScalarizeMode.NOT_SCALARIZED then
      while not listEmpty(crefs) loop
        cr :: crefs := crefs;
        strl := Util.escapeQuotes(firstName(cr, baseModelica = true)) :: strl;
        subs := listAppend(getSubscripts(cr), subs);

        if format.recordMode == BaseModelica.RecordMode.WITH_RECORDS and isCref(cr) and
           Type.isRecord(scalarType(cr)) and not listEmpty(crefs) then
          strl := "'" :: strl;

          if not listEmpty(subs) then
            strl := Subscript.toFlatStringList(subs, format) :: strl;
            subs := {};
          end if;

          if not listEmpty(crefs) then
            strl := ".'" :: strl;
          end if;
        elseif not listEmpty(crefs) then
          strl := "." :: strl;
        end if;
      end while;
    else
      while not listEmpty(crefs) loop
        cr :: crefs := crefs;
        strl := Util.escapeQuotes(firstName(cr, baseModelica = true)) :: strl;
        subs := getSubscripts(cr);

        if not listEmpty(subs) and
           not (format.scalarizeMode == BaseModelica.ScalarizeMode.PARTIALLY_SCALARIZED and listEmpty(crefs)) then
          strl := Subscript.toFlatStringList(subs, format) :: strl;
        end if;

        if not listEmpty(crefs) then
          if format.recordMode == BaseModelica.RecordMode.WITH_RECORDS and isCref(cr) and
             Type.isRecord(scalarType(cr)) then
            strl := "'.'" :: strl;
          else
            strl := "." :: strl;
          end if;
        end if;
      end while;

      if format.scalarizeMode == BaseModelica.ScalarizeMode.PARTIALLY_SCALARIZED then
        subs := getSubscripts(cref);
      else
        subs := {};
      end if;
    end if;

    strl := "'" :: strl;

    if not listEmpty(subs) then
      strl := Subscript.toFlatStringList(subs, format) :: strl;
    end if;

    str := stringAppendList(listReverse(strl));
  end toFlatString;

  function listToString
    input list<ComponentRef> crs;
    output String str;
  algorithm
    str := "{" + stringDelimitList(List.map(crs, toString), ",") + "}";
  end listToString;

  function toJSON
    input ComponentRef cref;
    output JSON json;
  algorithm
    json := match cref
      case CREF()
        algorithm
          json := JSON.emptyListObject();
          json := JSON.addPair("$kind", JSON.makeString("cref"), json);
          json := JSON.addPair("parts", JSON.makeArray(toJSON_impl(cref)), json);
        then
          json;

      case EMPTY() then JSON.makeNull();

      case WILD()
        algorithm
          json := JSON.emptyListObject();
          json := JSON.addPair("$kind", JSON.makeString("cref"), json);
          json := JSON.addPair("parts", JSON.makeArray(
            {JSON.fromPair("name", JSON.makeString("_"))}), json);
        then
          json;

      else JSON.makeString(toString(cref));
    end match;
  end toJSON;

  function toJSON_impl
    input ComponentRef cref;
    input list<JSON> accum = {};
    output list<JSON> objs;
  protected
    JSON obj, subs;
  algorithm
    objs := match cref
      case CREF()
        algorithm
          obj := JSON.emptyListObject();
          obj := JSON.addPair("name", JSON.makeString(InstNode.name(cref.node)), obj);

          if not listEmpty(cref.subscripts) then
            obj := JSON.addPair("subscripts", Subscript.toJSONList(cref.subscripts), obj);
          end if;
        then
          toJSON_impl(cref.restCref, obj :: accum);

      else accum;
    end match;
  end toJSON_impl;

  function hash
    input ComponentRef cref;
    output Integer hash;
  protected
    Integer h;

    function hash_rest
      input ComponentRef cref;
      input output Integer hash;
    algorithm
      hash := match cref
        case CREF()
          algorithm
            hash := stringHashDjb2Continue(InstNode.name(cref.node), hash);

            for s in cref.subscripts loop
              hash := stringHashDjb2Continue(Subscript.toString(s), hash);
            end for;
          then
            hash_rest(cref.restCref, hash);

        else hash;
      end match;
    end hash_rest;
  algorithm
    hash := match cref
      case CREF()
        algorithm
          h := stringHashDjb2(InstNode.name(cref.node));

          for s in cref.subscripts loop
            h := stringHashDjb2Continue(Subscript.toString(s), h);
          end for;
        then
          hash_rest(cref.restCref, h);

      case WILD() then stringHashDjb2("_");
      else 0;
    end match;
  end hash;

  function hashStrip
    "hashes the cref without subscripts. used for non expanded variables"
    input ComponentRef cref;
    output Integer hash;
  protected
    function hash_rest
      input ComponentRef cref;
      input output Integer hash;
    algorithm
      hash := match cref
        case CREF() then hash_rest(cref.restCref, stringHashDjb2Continue(InstNode.name(cref.node), hash));
        else hash;
      end match;
    end hash_rest;
  algorithm
    hash := match cref
      case CREF() then hash_rest(cref.restCref, stringHashDjb2(InstNode.name(cref.node)));
      case WILD() then stringHashDjb2("_");
      else 0;
    end match;
  end hashStrip;

  function toPath
    input ComponentRef cref;
    output Absyn.Path path;
  algorithm
    path := match cref
      case CREF()
        then toPath_impl(cref.restCref, Absyn.IDENT(InstNode.name(cref.node)));
    end match;
  end toPath;

  function toPath_impl
    input ComponentRef cref;
    input Absyn.Path accumPath;
    output Absyn.Path path;
  algorithm
    path := match cref
      case CREF()
        then toPath_impl(cref.restCref,
          Absyn.QUALIFIED(InstNode.name(cref.node), accumPath));
      else accumPath;
    end match;
  end toPath_impl;

  function fromNodeList
    input list<InstNode> nodes;
    output ComponentRef cref = ComponentRef.EMPTY();
  algorithm
    for n in nodes loop
      cref := CREF(n, {}, InstNode.getType(n), Origin.SCOPE, cref);
    end for;
  end fromNodeList;

  function scalarize
    input ComponentRef cref;
    input Boolean resize;
    output list<ComponentRef> crefs;
  algorithm
    crefs := match cref
      local
        list<Dimension> dims;
        list<list<Subscript>> subs;

      case CREF(ty = Type.ARRAY())
        algorithm
          dims := Type.arrayDims(cref.ty);
          subs := Subscript.scalarizeList(cref.subscripts, dims, resize);
          subs := List.combination(subs);
        then
          list(setSubscripts(s, cref) for s in subs);

      else {cref};
    end match;
  end scalarize;

  function scalarizeAll
    input ComponentRef cref;
    input Boolean resize;
    output list<ComponentRef> crefs;
  protected
    ComponentRef next = cref;
    list<list<ComponentRef>> nested_crefs = {};
  algorithm
    while not isEmpty(next) loop
      nested_crefs := scalarize(next, resize) :: nested_crefs;
      CREF(restCref = next) := next;
    end while;
    crefs := scalarizeAll_Nesting(nested_crefs);
  end scalarizeAll;

  function scalarizeAll_Nesting
    input list<list<ComponentRef>> nested_crefs;
    input ComponentRef cref = EMPTY();
    input output list<ComponentRef> crefs = {};
  algorithm
    crefs := match nested_crefs
      local
        list<ComponentRef> head;
        list<list<ComponentRef>> tail;
        Boolean empty;

      case head :: tail algorithm
        empty := listEmpty(tail);
        for head_cref in head loop
          crefs := match head_cref
            case CREF() algorithm
              head_cref.restCref := cref;
              if empty then
                crefs := head_cref :: crefs;
              else
                crefs := scalarizeAll_Nesting(tail, head_cref, crefs);
              end if;
            then crefs;
          end match;
        end for;
      then crefs;
    end match;
  end scalarizeAll_Nesting;

  function scalarizeSlice
    input ComponentRef cref;
    input list<Integer> slice = {}  "optional slice, empty list means all";
    input Boolean resize;
    output list<ComponentRef> crefs;
  protected
    ComponentRef next = cref;
    list<list<ComponentRef>> nested_crefs = {};
  algorithm
    while not isEmpty(next) loop
      nested_crefs := scalarize(next, resize) :: nested_crefs;
      CREF(restCref = next) := next;
    end while;
    crefs := scalarizeAll_Nesting(nested_crefs);

    // TODO: Only generate crefs that are needed by slice instead of filtering
    //       them here at the end. Is this even possible for unsorted indices?
    if not listEmpty(slice) then
      crefs := List.getAtIndexLst(crefs, slice, true);
    end if;
  end scalarizeSlice;

  function isPackageConstant
    input ComponentRef cref;
    output Boolean isPkgConst;
  algorithm
    // TODO: This should really be CONSTANT and not PARAMETER, but that breaks
    //       some models since we get some redeclared parameters that look like
    //       package constants due to redeclare issues, and which need to e.g.
    //       be collected by Package.collectConstants.
    isPkgConst := nodeVariability(cref) <= Variability.PARAMETER and isPackageConstant2(cref);
  end isPackageConstant;

  function isPackageConstant2
    input ComponentRef cref;
    output Boolean isPkgConst;
  algorithm
    isPkgConst := match cref
      case CREF(node = InstNode.CLASS_NODE()) then InstNode.isUserdefinedClass(cref.node);
      case CREF(origin = Origin.CREF) then isPackageConstant2(cref.restCref);
      else false;
    end match;
  end isPackageConstant2;

  function stripSubscripts
    "Strips the subscripts from the last name in a cref, e.g. a[2].b[3] => a[2].b"
    input ComponentRef cref;
    output ComponentRef strippedCref;
    output list<Subscript> subs;
  algorithm
    (strippedCref, subs) := match cref
      case CREF()
        then (CREF(cref.node, {}, cref.ty, cref.origin, cref.restCref), cref.subscripts);
      else (cref, {});
    end match;
  end stripSubscripts;

  function stripSubscriptsAll
    "Strips all subscripts from a cref."
    input ComponentRef cref;
    output ComponentRef strippedCref;
  algorithm
    strippedCref := match cref
      case CREF()
        then CREF(cref.node, {}, cref.ty, cref.origin, stripSubscriptsAll(cref.restCref));
      else cref;
    end match;
  end stripSubscriptsAll;

  function stripSubscriptsExceptModel
  "Removes all subscript of a componentref expcept for model subscripts"
    input output ComponentRef cref;
  algorithm
    cref := match cref
      local
        InstNode node;
        ComponentRef restCref;

      case CREF(node = node, restCref = restCref) guard(InstNode.isModel(node))
      then CREF(cref.node, cref.subscripts, cref.ty, cref.origin, stripSubscriptsExceptModel(restCref));

      case CREF(restCref = restCref)
      then CREF(cref.node, {}, cref.ty, cref.origin, stripSubscriptsExceptModel(restCref));

      else cref;
    end match;
  end stripSubscriptsExceptModel;

  function stripIteratorSubscripts
    input output ComponentRef cref;
  protected
    list<Subscript> subs;
  algorithm
    () := match cref
      case CREF()
        algorithm
          if not listEmpty(cref.subscripts) and Subscript.isIterator(List.last(cref.subscripts)) then
            subs := listReverse(cref.subscripts);
            subs := List.trim(subs, Subscript.isIterator);
            cref.subscripts := listReverseInPlace(subs);
          end if;

          cref.restCref := stripIteratorSubscripts(cref.restCref);
        then
          ();

      else ();
    end match;
  end stripIteratorSubscripts;

  function simplifySubscripts
    input output ComponentRef cref;
    input Boolean trim = false;
  algorithm
    cref := match cref
      local
        list<Subscript> subs;

      case CREF(subscripts = {}, origin = Origin.CREF)
        algorithm
          cref.restCref := simplifySubscripts(cref.restCref, trim);
        then
          cref;

      case CREF(origin = Origin.CREF)
        algorithm
          subs := Subscript.simplifyList(cref.subscripts, Type.arrayDims(cref.ty), trim);
        then
          CREF(cref.node, subs, cref.ty, cref.origin, simplifySubscripts(cref.restCref, trim));

      else cref;
    end match;
  end simplifySubscripts;

  function evaluateSubscripts
    input output ComponentRef cref;
  algorithm
    cref := match cref
      local
        list<Subscript> subs;

      case CREF(subscripts = {}, origin = Origin.CREF)
        algorithm
          cref.restCref := evaluateSubscripts(cref.restCref);
        then
          cref;

      case CREF(origin = Origin.CREF)
        algorithm
          subs := list(Subscript.eval(s) for s in cref.subscripts);
        then
          CREF(cref.node, subs, cref.ty, cref.origin, evaluateSubscripts(cref.restCref));

      else cref;
    end match;
  end evaluateSubscripts;

  function isDeleted
    input ComponentRef cref;
    output Boolean isDeleted;
  algorithm
    isDeleted := match cref
      local
        InstNode node;

      case CREF(node = node, origin = Origin.CREF)
        then (InstNode.isComponent(node) and Component.isDeleted(InstNode.component(node))) or
             isDeleted(cref.restCref);

      else false;
    end match;
  end isDeleted;

  function isFromCref
    input ComponentRef cref;
    output Boolean fromCref;
  algorithm
    fromCref := match cref
      case CREF(origin = Origin.CREF) then true;
      case WILD() then true;
      else false;
    end match;
  end isFromCref;

  function toListReverse
    input ComponentRef cref;
    input Boolean includeScope = true;
    input list<ComponentRef> accum = {};
    output list<ComponentRef> crefs;
  algorithm
    crefs := match cref
      case CREF() guard includeScope
        then toListReverse(cref.restCref, includeScope, cref :: accum);
      case CREF(origin = Origin.CREF)
        then toListReverse(cref.restCref, includeScope, cref :: accum);
      else accum;
    end match;
  end toListReverse;

  function depth
    input ComponentRef cref;
    output Integer d = 0;
  algorithm
    d := match cref
      case CREF(restCref = EMPTY())
        then d + 1;

      case CREF()
        algorithm
          d := 1 + depth(cref.restCref);
        then d;

      case WILD() then 0;
      else "EMPTY_CREF" then 0;
    end match;
  end depth;

  function size
    input ComponentRef cref;
    input Boolean withComplex;
    input Boolean resize = false;
    output Integer s = product(i for i in sizes(cref, withComplex, resize));
  end size;

  function sizes
    input ComponentRef cref;
    input Boolean withComplex;
    input Boolean resize = false;
    input output list<Integer> s_lst = {};
  algorithm
    s_lst := match cref
      local
        list<Integer> local_lst = {};
      case EMPTY() then listReverse(s_lst);
      case CREF() algorithm
        local_lst := sizes_local(cref, withComplex, resize);
        s_lst := listAppend(local_lst, s_lst);
      then sizes(cref.restCref, withComplex, resize, s_lst);
      case WILD() then {0};
    end match;
  end sizes;

  function sizes_local
    input ComponentRef cref;
    input Boolean withComplex;
    input Boolean resize = false;
    output list<Integer> s_lst = {};
  protected
    Option<Integer> complex_size;
  algorithm
    s_lst := match cref
      case EMPTY() then {};
      case CREF() algorithm
        complex_size := Type.complexSize(cref.ty);
        s_lst := list(Dimension.size(dim, resize) for dim in Type.arrayDims(cref.ty));
        if withComplex and Util.isSome(complex_size) then
          s_lst := Util.getOption(complex_size) :: s_lst;
        end if;
        s_lst := if listEmpty(s_lst) then {1} else s_lst;
      then s_lst;
    end match;
  end sizes_local;

  function sizeKnown
    input ComponentRef cref;
    output Boolean b;
  algorithm
    b := match cref
      case CREF() then Type.sizeKnown(cref.ty);
      else true; // size of WILD() and EMPTY() is known
    end match;
  end sizeKnown;

  function subscriptsToInteger
    input ComponentRef cref;
    output list<Integer> s_lst = {};
  algorithm
    for subs_tmp in subscriptsAllReverse(cref) loop
      if listEmpty(subs_tmp) then
        s_lst := 1 :: s_lst;
      else
        for sub in subs_tmp loop
          s_lst := Expression.integerValueOrDefault(Subscript.toExp(sub), 1) :: s_lst;
        end for;
      end if;
    end for;
  end subscriptsToInteger;

  function subscriptsToExpression
    input ComponentRef cref;
    input Boolean addScalar;
    output list<Expression> e_lst = {};
  algorithm
    for subs_tmp in subscriptsAllReverse(cref) loop
      if addScalar and listEmpty(subs_tmp) then
        e_lst := Expression.INTEGER(1) :: e_lst;
      else
        for sub in subs_tmp loop
          e_lst := Subscript.toExp(sub) :: e_lst;
        end for;
      end if;
    end for;
  end subscriptsToExpression;

  function isEmptyArray
    "Returns whether any node in the cref has a dimension that's 0."
    input ComponentRef cref;
    output Boolean isEmpty;
  algorithm
    isEmpty := match cref
      case CREF()
        then Type.isEmptyArray(cref.ty) or isEmptyArray(cref.restCref);
      else false;
    end match;
  end isEmptyArray;

  function isComplexArray
    input ComponentRef cref;
    output Boolean complexArray;
  algorithm
    complexArray := match cref
      case CREF() then isComplexArray2(cref.restCref);
      else false;
    end match;
  end isComplexArray;

  function isComplexArray2
    input ComponentRef cref;
    output Boolean complexArray;
  algorithm
    complexArray := match cref
      case CREF(ty = Type.ARRAY())
        guard Type.isArray(Type.subscript(cref.ty, cref.subscripts))
        then true;

      case CREF() then isComplexArray2(cref.restCref);
      else false;
    end match;
  end isComplexArray2;

  function containsExp
    input ComponentRef cref;
    input ContainsPred func;
    output Boolean res;

    partial function ContainsPred
      input Expression exp;
      output Boolean res;
    end ContainsPred;
  algorithm
    res := match cref
      case CREF()
        then Subscript.listContainsExp(cref.subscripts, func) or
             containsExp(cref.restCref, func);

      else false;
    end match;
  end containsExp;

  function containsExpShallow
    input ComponentRef cref;
    input ContainsPred func;
    output Boolean res;

    partial function ContainsPred
      input Expression exp;
      output Boolean res;
    end ContainsPred;
  algorithm
    res := match cref
      case ComponentRef.CREF()
        then Subscript.listContainsExpShallow(cref.subscripts, func) or
             containsExpShallow(cref.restCref, func);

      else false;
    end match;
  end containsExpShallow;

  function applyExp
    input ComponentRef cref;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    () := match cref
      case CREF()
        algorithm
          for s in cref.subscripts loop
            Subscript.applyExp(s, func);
          end for;

          applyExp(cref.restCref, func);
        then
          ();

      else ();
    end match;
  end applyExp;

  function applyExpShallow
    input ComponentRef cref;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    () := match cref
      case CREF()
        algorithm
          for s in cref.subscripts loop
            Subscript.applyExpShallow(s, func);
          end for;

          applyExpShallow(cref.restCref, func);
        then
          ();

      else ();
    end match;
  end applyExpShallow;

  function mapExp
    input ComponentRef cref;
    input MapFunc func;
    output ComponentRef outCref;

    partial function MapFunc
      input output Expression e;
    end MapFunc;
  algorithm
    outCref := match cref
      local
        list<Subscript> subs;
        ComponentRef rest;

      case CREF()
        algorithm
          subs := list(Subscript.mapExp(s, func) for s in cref.subscripts);
          rest := mapExp(cref.restCref, func);
        then
          CREF(cref.node, subs, cref.ty, cref.origin, rest);

      else cref;
    end match;
  end mapExp;

  function mapExpShallow
    input ComponentRef cref;
    input MapFunc func;
    output ComponentRef outCref;

    partial function MapFunc
      input output Expression e;
    end MapFunc;
  algorithm
    outCref := match cref
      local
        list<Subscript> subs;
        ComponentRef rest;

      case CREF()
        algorithm
          subs := list(Subscript.mapShallowExp(s, func) for s in cref.subscripts);
          rest := mapExpShallow(cref.restCref, func);
        then
          CREF(cref.node, subs, cref.ty, cref.origin, rest);

      else cref;
    end match;
  end mapExpShallow;

  function foldExp<ArgT>
    input ComponentRef cref;
    input FoldFunc func;
    input output ArgT arg;

    partial function FoldFunc
      input Expression exp;
      input output ArgT arg;
    end FoldFunc;
  algorithm
    () := match cref
      case CREF()
        algorithm
          arg := List.fold(cref.subscripts, function Subscript.foldExp(func = func), arg);
          arg := foldExp(cref.restCref, func, arg);
        then
          ();

      else ();
    end match;
  end foldExp;

  function mapFoldExp<ArgT>
    input ComponentRef cref;
    input MapFunc func;
          output ComponentRef outCref;
    input output ArgT arg;

    partial function MapFunc
      input output Expression e;
      input output ArgT arg;
    end MapFunc;
  algorithm
    outCref := match cref
      local
        list<Subscript> subs;
        ComponentRef rest;

      case CREF()
        algorithm
          (subs, arg) := List.map1Fold(cref.subscripts, Subscript.mapFoldExp, func, arg);
          (rest, arg) := mapFoldExp(cref.restCref, func, arg);
        then
          CREF(cref.node, subs, cref.ty, cref.origin, rest);

      else cref;
    end match;
  end mapFoldExp;

  function mapFoldExpShallow<ArgT>
    input ComponentRef cref;
    input MapFunc func;
          output ComponentRef outCref;
    input output ArgT arg;

    partial function MapFunc
      input output Expression e;
      input output ArgT arg;
    end MapFunc;
  algorithm
    outCref := match cref
      local
        list<Subscript> subs;
        ComponentRef rest;

      case CREF()
        algorithm
          (subs, arg) := List.map1Fold(cref.subscripts, Subscript.mapFoldExpShallow, func, arg);
          (rest, arg) := mapFoldExpShallow(cref.restCref, func, arg);
        then
          CREF(cref.node, subs, cref.ty, cref.origin, rest);

      else cref;
    end match;
  end mapFoldExpShallow;

  function isTime
    input ComponentRef cref;
    output Boolean b = firstName(cref) == "time";
  end isTime;

  function isSubstitute
    input ComponentRef cref;
    output Boolean b = firstName(cref) == "$SUBST_CREF";
  end isSubstitute;

  /* ========================================
      Backend Extension functions
  ========================================= */

  function listHasDiscrete
    "kabdelhak: Returns true if any component reference in the list has a
    discrete type. Used to analyze algorithm outputs."
    input list<ComponentRef> cref_lst;
    output Boolean result = false;
  algorithm
    for cref in cref_lst loop
      if Type.isDiscrete(nodeType(cref)) then
        result := true;
        return;
      end if;
    end for;
  end listHasDiscrete;

  function removeOuterCrefPrefix
    input output ComponentRef cref;
  algorithm
    () := match cref
      case ComponentRef.CREF()
        algorithm
          if InstNode.isGeneratedInner(cref.node) then
            cref.restCref := EMPTY();
          else
            cref.restCref := removeOuterCrefPrefix(cref.restCref);
          end if;
        then
          ();

      else ();
    end match;
  end removeOuterCrefPrefix;

  function mapTypes
    input ComponentRef cref;
    input MapFunc func;
    output ComponentRef outCref;

    partial function MapFunc
      input output Type e;
    end MapFunc;
  algorithm
    outCref := match cref
      local
        ComponentRef rest;
        Type ty;

      case CREF()
        algorithm
          ty := func(cref.ty);
          rest := mapTypes(cref.restCref, func);
        then
          CREF(cref.node, cref.subscripts, ty, cref.origin, rest);

      else cref;
    end match;
  end mapTypes;

  function mapNodes
    input ComponentRef cref;
    input MapFunc func;
    output ComponentRef outCref;

    partial function MapFunc
      input output InstNode n;
    end MapFunc;
  algorithm
    outCref := match cref
      local
        ComponentRef rest;
        InstNode node;

      case CREF()
        algorithm
          node := func(cref.node);
          rest := mapNodes(cref.restCref, func);
        then
          CREF(node, cref.subscripts, cref.ty, cref.origin, rest);

      else cref;
    end match;
  end mapNodes;

  function getArrayCrefOpt
    input ComponentRef scal;
    output Option<ComponentRef> arr;
  protected
    list<Subscript> subs;
  algorithm
    if Flags.getConfigBool(Flags.SIM_CODE_SCALARIZE) then
      subs := subscriptsAllFlat(scal);
      if listEmpty(subs) then
        // do not do it for scalar variables
        arr := NONE();
      elseif List.all(subs, function Subscript.isEqual(subscript1 = Subscript.INDEX(Expression.INTEGER(1)))) then
        // if it is the first element, save the array var
        arr := SOME(stripSubscriptsAll(scal));
      else
        // not first element
        arr := NONE();
      end if;
    else
      arr := if Type.isArray(getSubscriptedType(scal)) then SOME(scal) else NONE();
    end if;
  end getArrayCrefOpt;

  function isSliced
    input ComponentRef cref;
    output Boolean sliced;
  protected
    function is_sliced_impl
      input ComponentRef cref;
      output Boolean sliced;
    algorithm
      sliced := match cref
        case CREF(origin = Origin.CREF)
          algorithm
            sliced := Type.dimensionCount(cref.ty) > listLength(cref.subscripts) or
                      List.any(cref.subscripts, Subscript.isSliced);
          then
            sliced or is_sliced_impl(cref.restCref);

        else false;
      end match;
    end is_sliced_impl;
  algorithm
    sliced := match cref
      case CREF() then is_sliced_impl(cref.restCref);
      else false;
    end match;
  end isSliced;

  function iterate
    input output ComponentRef cref;
          output list<tuple<InstNode, Expression>> iterators;
  protected
    ComponentRef rest_cref;

    function iterate_impl
      "Replaces any slice subscripts (including implicit :) with an iterator,
       and returns a list of all iterators with the corresponding ranges."
      input output ComponentRef cref;
      input output list<tuple<InstNode, Expression>> iterators = {};
    protected
      ComponentRef rest_cref;
      Dimension dim;
      list<Dimension> dims;
      Integer dim_count, sub_count;
      list<Subscript> subs, isubs;
      Integer dim_index;
      InstNode iterator;
      Expression range;
    algorithm
      () := match cref
        case CREF(origin = Origin.CREF)
          algorithm
            dims := listReverse(Type.arrayDims(cref.ty));
            dim_count := listLength(dims);
            sub_count := listLength(cref.subscripts);
            subs := List.consN(dim_count - sub_count, Subscript.WHOLE(), cref.subscripts);
            isubs := {};
            dim_index := dim_count;

            for s in listReverse(subs) loop
              dim :: dims := dims;

              if not Subscript.isIndex(s) then
                range := match s
                  // Slices like 1:3 are used directly.
                  case Subscript.SLICE() then s.slice;
                  // : are turned into 1:size(x, dim).
                  case Subscript.WHOLE()
                    then Expression.makeRange(Dimension.lowerBoundExp(dim),
                                              NONE(),
                                              Dimension.endExp(dim, Expression.CREF(cref.ty, cref), dim_index));
                end match;

                iterator := InstNode.newUniqueIterator();
                iterators := (iterator, range) :: iterators;
                dim_index := dim_index - 1;

                s := Subscript.INDEX(Expression.fromCref(makeIterator(iterator, Type.INTEGER())));
              end if;

              isubs := s :: isubs;
            end for;

            cref.subscripts := isubs;
            (rest_cref, iterators) := iterate_impl(cref.restCref, iterators);
            cref.restCref := rest_cref;
          then
            ();

        else ();
      end match;
    end iterate_impl;
  algorithm
    iterators := match cref
      case CREF()
        algorithm
          (rest_cref, iterators) := iterate_impl(cref.restCref);

          if not listEmpty(iterators) then
            cref.restCref := rest_cref;
            iterators := listReverseInPlace(iterators);
          end if;
        then
          iterators;

      else {};
    end match;
  end iterate;

  function getRecordChildren
    input ComponentRef cref;
    output list<ComponentRef> children = {};
  protected
    Type ty = Type.arrayElementType(getComponentType(cref));
    array<InstNode> children_nodes = listArray({});
  algorithm
    if Type.isComplex(ty) then
      children_nodes := match cref
        case CREF() then ClassTree.getComponents(Class.classTree(InstNode.getClass(Component.classInstance(InstNode.component(cref.node)))));
        else listArray({});
      end match;
    end if;

    if not arrayEmpty(children_nodes) then
      children := list(prefixCref(node, InstNode.getType(node), {}, cref) for node in children_nodes);
    end if;
  end getRecordChildren;

annotation(__OpenModelica_Interface="frontend");
end NFComponentRef;
