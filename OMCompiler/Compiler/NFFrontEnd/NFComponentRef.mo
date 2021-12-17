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
  import NFPrefixes.{Variability, Purity};
  import Class = NFClass;
  import List;
  import Prefixes = NFPrefixes;
  import MetaModelica.Dangerous.*;

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

  record STRING
    String name;
    ComponentRef restCref;
  end STRING;

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
    input Type ty;
    output ComponentRef cref = CREF(node, {}, ty, Origin.ITERATOR, EMPTY());
  end makeIterator;

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

  function firstName
    input ComponentRef cref;
    output String name;
  algorithm
    name := match cref
      case CREF() then InstNode.name(cref.node);
      else "";
    end match;
  end firstName;

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

  function nodeVariability
    "Returns the variability of the component node the cref refers to."
    input ComponentRef cref;
    output Variability var;
  algorithm
    var := match cref
      case CREF(node = InstNode.COMPONENT_NODE())
        then Component.variability(InstNode.component(cref.node));
      case CREF(node = InstNode.CLASS_NODE()) then Variability.CONSTANT;
      else Variability.CONTINUOUS;
    end match;
  end nodeVariability;

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
    input list<Subscript> subscripts;
    input output ComponentRef cref;
    input Boolean applyToScope = false;
  algorithm
    ({}, cref) := mergeSubscripts2(subscripts, cref, applyToScope);
  end mergeSubscripts;

  function mergeSubscripts2
    input output list<Subscript> subscripts;
    input output ComponentRef cref;
    input Boolean applyToScope;
  algorithm
    (subscripts, cref) := match cref
      local
        ComponentRef rest_cref;
        list<Subscript> cref_subs;

      case CREF(subscripts = cref_subs)
        guard applyToScope or cref.origin == Origin.CREF
        algorithm
          (subscripts, rest_cref) := mergeSubscripts2(subscripts, cref.restCref, applyToScope);

          if not listEmpty(subscripts) then
            (cref_subs, subscripts) :=
              Subscript.mergeList(subscripts, cref_subs, Type.dimensionCount(cref.ty));
          end if;
        then
          (subscripts, CREF(cref.node, cref_subs, cref.ty, cref.origin, rest_cref));

      else (subscripts, cref);
    end match;
  end mergeSubscripts2;

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

  function hasSplitSubscripts
    input ComponentRef cref;
    output Boolean res;
  algorithm
    res := match cref
      case CREF(origin = Origin.CREF)
        then List.exist(cref.subscripts, Subscript.isSplitIndex) or
             hasSplitSubscripts(cref.restCref);

      else false;
    end match;
  end hasSplitSubscripts;

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

  function subscriptsAll
    "Returns all subscripts of a cref in reverse order.
     Ex: a[1, 2].b[4].c[6, 3] => {{6,3}, {4}, {1,2}}"
    input ComponentRef cref;
    input list<list<Subscript>> accumSubs = {};
    output list<list<Subscript>> subscripts;
  algorithm
    subscripts := match cref
      case CREF() then subscriptsAll(cref.restCref, cref.subscripts :: accumSubs);
      else accumSubs;
    end match;
  end subscriptsAll;

  function subscriptsAllFlat
    "Returns all subscripts of a cref as a flat list in the correct order.
     Ex: a[1, 2].b[4].c[6, 3] => {1, 2, 4, 6, 3}"
    input ComponentRef cref;
    output list<Subscript> subscripts = List.flattenReverse(subscriptsAll(cref));
  end subscriptsAllFlat;

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
        then
          CREF(dstCref.node, srcCref.subscripts, dstCref.ty, dstCref.origin, cref);

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

    partial function FuncT
      input Subscript subscript;
    end FuncT;
  algorithm
    () := match cref
      case CREF(origin = Origin.CREF)
        algorithm
          for sub in cref.subscripts loop
            func(sub);
          end for;

          applySubscripts(cref.restCref, func);
        then
          ();

      else ();
    end match;
  end applySubscripts;

  function foldSubscripts<ArgT>
    input ComponentRef cref;
    input FuncT func;
    input output ArgT arg;

    partial function FuncT
      input Subscript subscript;
      input output ArgT arg;
    end FuncT;
  algorithm
    arg := match cref
      case CREF(origin = Origin.CREF)
        algorithm
          for sub in cref.subscripts loop
            arg := func(sub, arg);
          end for;
        then
          foldSubscripts(cref.restCref, func, arg);

      else arg;
    end match;
  end foldSubscripts;

  function mapSubscripts
    input output ComponentRef cref;
    input FuncT func;

    partial function FuncT
      input output Subscript subscript;
    end FuncT;
  algorithm
    cref := match cref
      case CREF(origin = Origin.CREF)
        algorithm
          if not listEmpty(cref.subscripts) then
            cref.subscripts := list(func(s) for s in cref.subscripts);
          end if;

          cref.restCref := mapSubscripts(cref.restCref, func);
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
          if List.exist(cref.subscripts, Subscript.isWhole) then
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
    subs := List.flatten(subscriptsAll(cref));

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
      case (_, EMPTY()) then 1;
      case (EMPTY(), _) then -1;
    end match;
  end compare;

  function isEqual
    input ComponentRef cref1;
    input ComponentRef cref2;
    output Boolean isEqual;
  algorithm
    if referenceEq(cref1, cref2) then
      isEqual := true;
      return;
    end if;

    isEqual := match (cref1, cref2)
      case (CREF(), CREF())
        then InstNode.name(cref1.node) == InstNode.name(cref2.node) and
             Subscript.isEqualList(cref1.subscripts, cref2.subscripts) and
             isEqual(cref1.restCref, cref2.restCref);

      case (EMPTY(), EMPTY()) then true;
      case (WILD(), WILD()) then true;
      else false;
    end match;
  end isEqual;

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

      case STRING()
        algorithm
          acref := Absyn.ComponentRef.CREF_IDENT(cref.name, {});
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

      case STRING()
        algorithm
          acref := Absyn.ComponentRef.CREF_QUAL(cref.name, {}, accumCref);
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
      case STRING() then toString_impl(cref.restCref, cref.name :: strl);
      else strl;
    end match;
  end toString_impl;

  function toFlatString
    input ComponentRef cref;
    output String str;
  protected
    ComponentRef cr;
    list<Subscript> subs;
    list<String> strl = {};
  algorithm
    (cr, subs) := stripSubscripts(cref);
    strl := toFlatString_impl(cr, strl);

    str := match listHead(strl)
      case "time" then "time";
      case "_" then "_";
      else stringAppendList({"'", stringDelimitList(strl, "."), "'", Subscript.toFlatStringList(subs)});
    end match;
  end toFlatString;

  function toFlatString_impl
    input ComponentRef cref;
    input output list<String> strl;
  algorithm
    strl := match cref
      local
        String str;

      case CREF()
        algorithm
          str := Util.escapeQuotes(InstNode.name(cref.node)) + Subscript.toFlatStringList(cref.subscripts);

          if Type.isRecord(cref.ty) and not listEmpty(strl) then
            strl := ("'" + listHead(strl)) :: listRest(strl);
            str := str + "'";
          end if;
        then
          toFlatString_impl(cref.restCref, str :: strl);

      case WILD() then "_" :: strl;
      case STRING() then toFlatString_impl(cref.restCref, cref.name :: strl);
      else strl;
    end match;
  end toFlatString_impl;

  function listToString
    input list<ComponentRef> crs;
    output String str;
  algorithm
    str := "{" + stringDelimitList(List.map(crs, toString), ",") + "}";
  end listToString;

  function hash
    input ComponentRef cref;
    input Integer mod;
    output Integer hash = stringHashDjb2Mod(toString(cref), mod);
  end hash;

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
    output list<ComponentRef> crefs;
  algorithm
    crefs := match cref
      local
        list<Dimension> dims;
        list<list<Subscript>> subs;

      case CREF(ty = Type.ARRAY())
        algorithm
          dims := Type.arrayDims(cref.ty);
          subs := Subscript.scalarizeList(cref.subscripts, dims);
          subs := List.combination(subs);
        then
          list(setSubscripts(s, cref) for s in subs);

      else {cref};
    end match;
  end scalarize;

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
        then
          d;

      case WILD() then 0;
      else "EMPTY_CREF" then 0;
    end match;
  end depth;

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
      case CREF(origin = Origin.CREF)
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
      case CREF(origin = Origin.CREF)
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

      case CREF(origin = Origin.CREF)
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

      case CREF(origin = Origin.CREF)
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
      case CREF(origin = Origin.CREF)
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

      case CREF(origin = Origin.CREF)
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

      case CREF(origin = Origin.CREF)
        algorithm
          (subs, arg) := List.map1Fold(cref.subscripts, Subscript.mapFoldExpShallow, func, arg);
          (rest, arg) := mapFoldExpShallow(cref.restCref, func, arg);
        then
          CREF(cref.node, subs, cref.ty, cref.origin, rest);

      else cref;
    end match;
  end mapFoldExpShallow;

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
      input Integer index = 1;
    protected
      ComponentRef rest_cref;
      Dimension dim;
      list<Dimension> dims;
      Integer dim_count, sub_count;
      list<Subscript> subs, isubs;
      Integer dim_index, iter_index;
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
            iter_index := index;
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
                                              Dimension.endExp(dim, cref, dim_index));
                end match;

                iterator := InstNode.newIndexedIterator(iter_index);
                iterators := (iterator, range) :: iterators;
                dim_index := dim_index - 1;
                iter_index := iter_index + 1;

                s := Subscript.INDEX(Expression.fromCref(makeIterator(iterator, Type.INTEGER())));
              end if;

              isubs := s :: isubs;
            end for;

            cref.subscripts := isubs;
            (rest_cref, iterators) := iterate_impl(cref.restCref, iterators, iter_index);
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

annotation(__OpenModelica_Interface="frontend");
end NFComponentRef;
