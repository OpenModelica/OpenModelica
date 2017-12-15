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
  import NFComponent.Component;
  import Absyn;
  import DAE;
  import Subscript = NFSubscript;
  import Type = NFType;
  import NFInstNode.InstNode;
  import NFInstNode.InstNodeType;
  import RangeIterator = NFRangeIterator;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import NFPrefixes.Variability;
  import System;
  import NFClass.Class;

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
    Type ty;
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
    output ComponentRef cref;
  algorithm
    cref := match acref
      case Absyn.ComponentRef.CREF_IDENT()
        then CREF(InstNode.NAME_NODE(acref.name),
          list(Subscript.RAW_SUBSCRIPT(s) for s in acref.subscripts),
          Type.UNKNOWN(), Origin.CREF, EMPTY());

      case Absyn.ComponentRef.CREF_QUAL()
        then CREF(InstNode.NAME_NODE(acref.name),
          list(Subscript.RAW_SUBSCRIPT(s) for s in acref.subscripts),
          Type.UNKNOWN(), Origin.CREF, fromAbsynCref(acref.componentRef));

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

  function node
    input ComponentRef cref;
    output InstNode node;
  algorithm
    CREF(node = node) := cref;
  end node;

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

  function getType
    input ComponentRef cref;
    output Type ty;
  algorithm
    ty := match cref
      case CREF() then cref.ty;
      else Type.UNKNOWN();
    end match;
  end getType;

  function setType
    input Type ty;
    input output ComponentRef cref;
  algorithm
    () := match cref
      case CREF()
        algorithm
          cref.ty := ty;
        then
          ();
    end match;
  end setType;

  function getVariability
    input ComponentRef cref;
    output Variability var;
  algorithm
    var := match cref
      case CREF() then Component.variability(InstNode.component(cref.node));
      else Variability.CONTINUOUS;
    end match;
  end getVariability;

  function addSubscript
    input Subscript subscript;
    input output ComponentRef cref;
  algorithm
    cref := match cref
      case CREF()
        then CREF(cref.node, listAppend(cref.subscripts, {subscript}),
            Type.unliftArray(cref.ty), cref.origin, cref.restCref);
    end match;
  end addSubscript;

  function fillSubscripts
    "This function takes a list of subscript lists and a cref, and adds the
     first subscript list to the first part of the cref, the second list to the
     second part, and so on. This function is meant to be used to fill in all
     subscripts in a cref such that it becomes a scalar, so the type of each
     cref part is set to the array element type for that part."
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
          rest_cref := fillSubscripts(rest_subs, cref.restCref);
        then
          CREF(cref.node, listAppend(cref.subscripts, subs),
            Type.arrayElementType(cref.ty), cref.origin, rest_cref);

      case ({}, _) then cref;
    end match;
  end fillSubscripts;

  function setSubscripts
    input list<Subscript> subscripts;
    input output ComponentRef cref;
  algorithm
    cref := match cref
      case CREF()
        then CREF(cref.node, subscripts, Type.arrayElementType(cref.ty), cref.origin, cref.restCref);
    end match;
  end setSubscripts;

  function replaceSubscripts
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
  end replaceSubscripts;

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

  function subscriptsN
    "Returns the subscripts of the N first parts of a cref in reverse order.
     Fails if the cref is fewer than N parts."
    input ComponentRef cref;
    input Integer n;
    output list<list<Subscript>> subscripts = {};
  protected
    list<Subscript> subs;
    ComponentRef rest = cref;
  algorithm
    for i in 1:n loop
      CREF(subscripts = subs, restCref = rest) := rest;
      subscripts := subs :: subscripts;
    end for;
  end subscriptsN;

  function transferSubscripts
    input ComponentRef srcCref;
    input ComponentRef dstCref;
    output ComponentRef cref;
  algorithm
    cref := match (srcCref, dstCref)
      case (EMPTY(), _) then dstCref;
      case (_, EMPTY()) then dstCref;
      case (_, CREF(origin = Origin.ITERATOR)) then dstCref;

      case (CREF(), CREF(origin = Origin.CREF))
        algorithm
          dstCref.restCref := transferSubscripts(srcCref, dstCref.restCref);
        then
          dstCref;

      case (CREF(), CREF())
        algorithm
          cref := transferSubscripts(srcCref.restCref, dstCref.restCref);
        then
          CREF(dstCref.node, srcCref.subscripts, srcCref.ty, dstCref.origin, cref);

      else
        algorithm
          Error.assertion(false, getInstanceName() + " failed", sourceInfo());
        then
          fail();
    end match;
  end transferSubscripts;

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
      case EMPTY() then accumCref;
      case CREF()
        algorithm
          dcref := DAE.ComponentRef.CREF_QUAL(InstNode.name(cref.node), Type.toDAE(cref.ty),
            list(Subscript.toDAE(s) for s in cref.subscripts), accumCref);
        then
          toDAE_impl(cref.restCref, dcref);
    end match;
  end toDAE_impl;

  function toString
    input ComponentRef cref;
    output String str;
  algorithm
    str := match cref
      case CREF(restCref = EMPTY())
        then InstNode.name(cref.node) + Subscript.toStringList(cref.subscripts);

      case CREF()
        algorithm
          str := toString(cref.restCref);
        then
          str + "." + InstNode.name(cref.node) + Subscript.toStringList(cref.subscripts);

      case WILD() then "_";
      else "EMPTY_CREF";
    end match;
  end toString;

  function hash
    input ComponentRef cref;
    input Integer mod;
    output Integer hash = System.stringHashDjb2Mod(toString(cref), mod);
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
        RangeIterator iter;
        Expression exp;
        list<list<Subscript>> subs;
        list<list<Subscript>> new_subs;
        Subscript sub;
        ComponentRef scalar_cref;

      case CREF()
        algorithm
          dims := Type.arrayDims(cref.ty);
          subs := {cref.subscripts};

          for dim in listReverse(dims) loop
            iter := RangeIterator.fromDim(dim);
            new_subs := {};

            while RangeIterator.hasNext(iter) loop
              (iter, exp) := RangeIterator.next(iter);
              sub := Subscript.INDEX(exp);
              new_subs := listAppend(list(sub :: s for s in subs), new_subs);
            end while;

            subs := new_subs;
          end for;

          scalar_cref := setType(Type.arrayElementType(cref.ty), cref);
        then
          listReverse(replaceSubscripts(s, scalar_cref) for s in subs);

      else {cref};
    end match;
  end scalarize;

  function isPackageConstant
    input ComponentRef cref;
    output Boolean isPkgConst;
  algorithm
    isPkgConst := match cref
      case CREF(node = InstNode.CLASS_NODE(nodeType = InstNodeType.NORMAL_CLASS())) then true;
      case CREF(origin = Origin.CREF) then isPackageConstant(cref.restCref);
      else false;
    end match;
  end isPackageConstant;

  function stripSubscripts
    "Strips the subscripts from the last name in a cref, e.g. a[2].b[3] => a[2].b"
    input ComponentRef cref;
    output ComponentRef strippedCref;
  algorithm
    strippedCref := match cref
      case CREF()
        then CREF(cref.node, {}, cref.ty, cref.origin, cref.restCref);
      else cref;
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
  algorithm
    cref := match cref
      local
        list<Subscript> subs;

      case CREF(subscripts = {})
        algorithm
          cref.restCref := simplifySubscripts(cref.restCref);
        then
          cref;

      case CREF()
        algorithm
          subs := list(Subscript.simplify(s) for s in cref.subscripts);
        then
          CREF(cref.node, subs, cref.ty, cref.origin, simplifySubscripts(cref.restCref));

      else cref;
    end match;
  end simplifySubscripts;

annotation(__OpenModelica_Interface="frontend");
end NFComponentRef;
