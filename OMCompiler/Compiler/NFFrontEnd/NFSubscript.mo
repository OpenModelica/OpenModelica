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

encapsulated uniontype NFSubscript
protected
  import DAE;
  import List;
  import SimplifyExp = NFSimplifyExp;
  import Type = NFType;
  import RangeIterator = NFRangeIterator;
  import Dump;
  import ExpandExp = NFExpandExp;
  import Prefixes = NFPrefixes;
  import Ceval = NFCeval;
  import MetaModelica.Dangerous.listReverseInPlace;
  import Util;

public
  import Expression = NFExpression;
  import Absyn;
  import AbsynUtil;
  import Dimension = NFDimension;
  import NFPrefixes.{Variability, Purity};
  import NFCeval.EvalTarget;
  import NFInstNode.InstNode;
  import ComponentRef = NFComponentRef;

  import Subscript = NFSubscript;

  record RAW_SUBSCRIPT
    Absyn.Subscript subscript;
  end RAW_SUBSCRIPT;

  record UNTYPED
    Expression exp;
  end UNTYPED;

  record INDEX
    Expression index;
  end INDEX;

  record SLICE
    Expression slice;
  end SLICE;

  record EXPANDED_SLICE
    list<Subscript> indices;
  end EXPANDED_SLICE;

  record WHOLE end WHOLE;

  // Split proxy and index subscripts are added to modifier array expressions to
  // indicate where they are split when propagating them down to the array
  // elements. Proxies are added during the instantiation and then replaced with
  // split indices during typing once the number of dimensions on elements are known.
  record SPLIT_PROXY
    InstNode origin;
    InstNode parent;
  end SPLIT_PROXY;

  record SPLIT_INDEX
    InstNode node;
    Integer dimIndex;
  end SPLIT_INDEX;

  function fromExp
    input Expression exp;
    output Subscript subscript;
  algorithm
    subscript := match exp
      case Expression.INTEGER() then INDEX(exp);
      case Expression.BOOLEAN() then INDEX(exp);
      case Expression.ENUM_LITERAL() then INDEX(exp);
      else UNTYPED(exp);
    end match;
  end fromExp;

  function fromTypedExp
    input Expression exp;
    output Subscript subscript;
  algorithm
    subscript := if Type.isArray(Expression.typeOf(exp)) then SLICE(exp) else INDEX(exp);
  end fromTypedExp;

  function toExp
    input Subscript subscript;
    output Expression exp;
  algorithm
    exp := match subscript
      case UNTYPED() then subscript.exp;
      case INDEX() then subscript.index;
      case SLICE() then subscript.slice;
    end match;
  end toExp;

  function toInteger
    input Subscript subscript;
    output Integer int;
  algorithm
    int := match subscript
      case INDEX() then Expression.toInteger(subscript.index);
    end match;
  end toInteger;

  protected function isValidIndexType
    input Type ty;
    output Boolean b = Type.isInteger(ty) or Type.isBoolean(ty) or Type.isEnumeration(ty);
  end isValidIndexType;

  public
  function makeIndex
    input Expression exp;
    output Subscript subscript;
  protected
    Type ty;
  algorithm
    ty := Expression.typeOf(exp);
    if isValidIndexType(ty) then
      subscript := INDEX(exp);
    else
      Error.assertion(false, getInstanceName() + " got a non integer type exp to make an index sub", sourceInfo());
      fail();
    end if;
  end makeIndex;

  function makeSplitIndex
    input InstNode node;
    input Integer dimIndex;
    output Subscript subscript = SPLIT_INDEX(node, dimIndex);
  algorithm
    if dimIndex < 1 then
      Error.assertion(false, getInstanceName() + " got invalid index " + String(dimIndex), sourceInfo());
    end if;
  end makeSplitIndex;

  function isIndex
    input Subscript sub;
    output Boolean isIndex;
  algorithm
    isIndex := match sub
      case INDEX() then true;
      else false;
    end match;
  end isIndex;

  function isWhole
    input Subscript sub;
    output Boolean isWhole;
  algorithm
    isWhole := match sub
      case WHOLE() then true;
      else false;
    end match;
  end isWhole;

  function isSliced
    input Subscript sub;
    output Boolean sliced;
  algorithm
    sliced := match sub
      case SLICE() then true;
      case WHOLE() then true;
      else false;
    end match;
  end isSliced;

  function isScalar
    input Subscript sub;
    output Boolean isScalar;
  algorithm
    isScalar := match sub
      local
        Type ty;

      case INDEX() algorithm
        ty := Expression.typeOf(sub.index);
        then
          isValidIndexType(ty);

      case SPLIT_INDEX() then true;

      else false;
    end match;
  end isScalar;

  function isScalarLiteral
    input Subscript sub;
    output Boolean isScalarLiteral;
  algorithm
    isScalarLiteral := match sub
      case INDEX() then Expression.isScalarLiteral(sub.index);
      else false;
    end match;
  end isScalarLiteral;

  function isIterator
    input Subscript sub;
    input InstNode iterator;
    output Boolean res;
  protected
    ComponentRef cref;
  algorithm
    res := match sub
      case UNTYPED(exp = Expression.CREF(cref = cref))
        then InstNode.refEqual(iterator, ComponentRef.node(cref));

      case INDEX(index = Expression.CREF(cref = cref))
        then InstNode.refEqual(iterator, ComponentRef.node(cref));

      else false;
    end match;
  end isIterator;

  function isEqual
    input Subscript subscript1;
    input Subscript subscript2;
    output Boolean isEqual;
  algorithm
    isEqual := match (subscript1, subscript2)
      case (RAW_SUBSCRIPT(), RAW_SUBSCRIPT())
        then AbsynUtil.subscriptEqual(subscript1.subscript, subscript2.subscript);

      case (UNTYPED(), UNTYPED())
        then Expression.isEqual(subscript1.exp, subscript2.exp);

      case (INDEX(), INDEX())
        then Expression.isEqual(subscript1.index, subscript2.index);

      case (SLICE(), SLICE())
        then Expression.isEqual(subscript1.slice, subscript2.slice);

      case (WHOLE(), WHOLE()) then true;

      case (SPLIT_INDEX(), SPLIT_INDEX())
        then subscript1.dimIndex == subscript2.dimIndex and
             InstNode.refEqual(subscript1.node, subscript2.node);

      else false;
    end match;
  end isEqual;

  function isEqualList
    input list<Subscript> subscripts1;
    input list<Subscript> subscripts2;
    output Boolean isEqual;
  protected
    Subscript s2;
    list<Subscript> rest = subscripts2;
  algorithm
    for s1 in subscripts1 loop
      if listEmpty(rest) then
        isEqual := false;
        return;
      end if;

      s2 :: rest := rest;

      if not isEqual(s1, s2) then
        isEqual := false;
        return;
      end if;
    end for;

    isEqual := listEmpty(rest);
  end isEqualList;

  function compare
    input Subscript subscript1;
    input Subscript subscript2;
    output Integer comp;
  algorithm
    if referenceEq(subscript1, subscript2) then
      comp := 0;
      return;
    end if;

    comp := Util.intCompare(valueConstructor(subscript1), valueConstructor(subscript2));
    if comp <> 0 then
      return;
    end if;

    comp := match subscript1
      local
        Expression e;
        InstNode node;
        Integer index;

      case UNTYPED()
        algorithm
          UNTYPED(exp = e) := subscript2;
        then
          Expression.compare(subscript1.exp, e);

      case INDEX()
        algorithm
          INDEX(index = e) := subscript2;
        then
          Expression.compare(subscript1.index, e);

      case SLICE()
        algorithm
          SLICE(slice = e) := subscript2;
        then
          Expression.compare(subscript1.slice, e);

      case WHOLE() then 0;

      case SPLIT_INDEX()
        algorithm
          SPLIT_INDEX(node = node, dimIndex = index) := subscript2;
          comp := InstNode.refCompare(subscript1.node, node);
        then
          if comp == 0 then Util.intCompare(subscript1.dimIndex, index) else comp;

    end match;
  end compare;

  function compareList
    input list<Subscript> subscripts1;
    input list<Subscript> subscripts2;
    output Integer comp;
  protected
    Subscript s2;
    list<Subscript> rest_s2 = subscripts2;
  algorithm
    comp := Util.intCompare(listLength(subscripts1), listLength(subscripts2));

    if comp <> 0 then
      return;
    end if;

    for s1 in subscripts1 loop
      s2 :: rest_s2 := rest_s2;
      comp := compare(s1, s2);

      if comp <> 0 then
        return;
      end if;
    end for;

    comp := 0;
  end compareList;

  function containsExp
    input Subscript subscript;
    input ContainsPred func;
    output Boolean res;

    partial function ContainsPred
      input Expression exp;
      output Boolean res;
    end ContainsPred;
  algorithm
    res := match subscript
      case UNTYPED() then Expression.contains(subscript.exp, func);
      case INDEX() then Expression.contains(subscript.index, func);
      case SLICE() then Expression.contains(subscript.slice, func);
      else false;
    end match;
  end containsExp;

  function listContainsExp
    input list<Subscript> subscripts;
    input ContainsPred func;
    output Boolean res;

    partial function ContainsPred
      input Expression exp;
      output Boolean res;
    end ContainsPred;
  algorithm
    for s in subscripts loop
      if containsExp(s, func) then
        res := true;
        return;
      end if;
    end for;

    res := false;
  end listContainsExp;

  function containsExpShallow
    input Subscript subscript;
    input ContainsPred func;
    output Boolean res;

    partial function ContainsPred
      input Expression exp;
      output Boolean res;
    end ContainsPred;
  algorithm
    res := match subscript
      case UNTYPED() then func(subscript.exp);
      case INDEX() then func(subscript.index);
      case SLICE() then func(subscript.slice);
      else false;
    end match;
  end containsExpShallow;

  function listContainsExpShallow
    input list<Subscript> subscripts;
    input ContainsPred func;
    output Boolean res;

    partial function ContainsPred
      input Expression exp;
      output Boolean res;
    end ContainsPred;
  algorithm
    for s in subscripts loop
      if containsExpShallow(s, func) then
        res := true;
        return;
      end if;
    end for;

    res := false;
  end listContainsExpShallow;

  function applyExp
    input Subscript subscript;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    () := match subscript
      case UNTYPED() algorithm Expression.apply(subscript.exp, func); then ();
      case INDEX() algorithm Expression.apply(subscript.index, func); then ();
      case SLICE() algorithm Expression.apply(subscript.slice, func); then ();
      else ();
    end match;
  end applyExp;

  function applyExpShallow
    input Subscript subscript;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    () := match subscript
      case UNTYPED() algorithm func(subscript.exp); then ();
      case INDEX() algorithm func(subscript.index); then ();
      case SLICE() algorithm func(subscript.slice); then ();
      else ();
    end match;
  end applyExpShallow;

  function mapExp
    input Subscript subscript;
    input MapFunc func;
    output Subscript outSubscript;

    partial function MapFunc
      input output Expression e;
    end MapFunc;
  algorithm
    outSubscript := match subscript
      local
        Expression e1, e2;

      case UNTYPED(exp = e1)
        algorithm
          e2 := Expression.map(e1, func);
        then
          if referenceEq(e1, e2) then subscript else UNTYPED(e2);

      case INDEX(index = e1)
        algorithm
          e2 := Expression.map(e1, func);
        then
          if referenceEq(e1, e2) then subscript else fromTypedExp(e2);

      case SLICE(slice = e1)
        algorithm
          e2 := Expression.map(e1, func);
        then
          if referenceEq(e1, e2) then subscript else fromTypedExp(e2);

      else subscript;
    end match;
  end mapExp;

  function mapShallowExp
    input Subscript subscript;
    input MapFunc func;
    output Subscript outSubscript;

    partial function MapFunc
      input output Expression e;
    end MapFunc;
  algorithm
    outSubscript := match subscript
      local
        Expression e1, e2;

      case UNTYPED(exp = e1)
        algorithm
          e2 := func(e1);
        then
          if referenceEq(e1, e2) then subscript else UNTYPED(e2);

      case INDEX(index = e1)
        algorithm
          e2 := func(e1);
        then
          if referenceEq(e1, e2) then subscript else fromTypedExp(e2);

      case SLICE(slice = e1)
        algorithm
          e2 := func(e1);
        then
          if referenceEq(e1, e2) then subscript else fromTypedExp(e2);

      else subscript;
    end match;
  end mapShallowExp;

  function foldExp<ArgT>
    input Subscript subscript;
    input FoldFunc func;
    input ArgT arg;
    output ArgT result;

    partial function FoldFunc
      input Expression exp;
      input output ArgT arg;
    end FoldFunc;
  algorithm
    result := match subscript
      case UNTYPED() then Expression.fold(subscript.exp, func, arg);
      case INDEX() then Expression.fold(subscript.index, func, arg);
      case SLICE() then Expression.fold(subscript.slice, func, arg);
      else arg;
    end match;
  end foldExp;

  function mapFoldExp<ArgT>
    input Subscript subscript;
    input MapFunc func;
          output Subscript outSubscript;
    input output ArgT arg;

    partial function MapFunc
      input output Expression e;
      input output ArgT arg;
    end MapFunc;
  algorithm
    outSubscript := match subscript
      local
        Expression exp;

      case UNTYPED()
        algorithm
          (exp, arg) := Expression.mapFold(subscript.exp, func, arg);
        then
          if referenceEq(subscript.exp, exp) then subscript else UNTYPED(exp);

      case INDEX()
        algorithm
          (exp, arg) := Expression.mapFold(subscript.index, func, arg);
        then
          if referenceEq(subscript.index, exp) then subscript else fromTypedExp(exp);

      case SLICE()
        algorithm
          (exp, arg) := Expression.mapFold(subscript.slice, func, arg);
        then
          if referenceEq(subscript.slice, exp) then subscript else fromTypedExp(exp);

      else subscript;
    end match;
  end mapFoldExp;

  function mapFoldExpShallow<ArgT>
    input Subscript subscript;
    input MapFunc func;
          output Subscript outSubscript;
    input output ArgT arg;

    partial function MapFunc
      input output Expression e;
      input output ArgT arg;
    end MapFunc;
  algorithm
    outSubscript := match subscript
      local
        Expression exp;

      case UNTYPED()
        algorithm
          (exp, arg) := func(subscript.exp, arg);
        then
          if referenceEq(subscript.exp, exp) then subscript else UNTYPED(exp);

      case INDEX()
        algorithm
          (exp, arg) := func(subscript.index, arg);
        then
          if referenceEq(subscript.index, exp) then subscript else fromTypedExp(exp);

      case SLICE()
        algorithm
          (exp, arg) := func(subscript.slice, arg);
        then
          if referenceEq(subscript.slice, exp) then subscript else fromTypedExp(exp);

      else subscript;
    end match;
  end mapFoldExpShallow;

  function toAbsyn
    input Subscript subscript;
    output Absyn.Subscript asubscript;
  algorithm
    asubscript := match subscript
      case RAW_SUBSCRIPT() then subscript.subscript;
      case UNTYPED() then Absyn.Subscript.SUBSCRIPT(Expression.toAbsyn(subscript.exp));
      case INDEX() then Absyn.Subscript.SUBSCRIPT(Expression.toAbsyn(subscript.index));
      case SLICE() then Absyn.Subscript.SUBSCRIPT(Expression.toAbsyn(subscript.slice));
      case WHOLE() then Absyn.Subscript.NOSUB();
      else
        algorithm
          Error.assertion(false, getInstanceName() + " failed on unknown subscript", sourceInfo());
        then
          fail();
    end match;
  end toAbsyn;

  function toDAE
    input Subscript subscript;
    output DAE.Subscript daeSubscript;
  algorithm
    daeSubscript := match subscript
      case INDEX() then DAE.INDEX(Expression.toDAE(subscript.index));
      case SLICE() then DAE.SLICE(Expression.toDAE(subscript.slice));
      case WHOLE() then DAE.WHOLEDIM();
      else
        algorithm
          Error.assertion(false, getInstanceName() + " failed on unknown subscript " + toString(subscript), sourceInfo());
        then
          fail();
    end match;
  end toDAE;

  function toDAEExp
    input Subscript subscript;
    output DAE.Exp daeExp;
  algorithm
    daeExp := match subscript
      case INDEX() then Expression.toDAE(subscript.index);
      case SLICE() then Expression.toDAE(subscript.slice);
      else
        algorithm
          Error.assertion(false, getInstanceName() + " failed on unknown subscript '" +
            toString(subscript) + "'", sourceInfo());
        then
          fail();
    end match;
  end toDAEExp;

  function toString
    input Subscript subscript;
    output String string;
  algorithm
    string := match subscript
      case RAW_SUBSCRIPT() then Dump.printSubscriptStr(subscript.subscript);
      case UNTYPED() then Expression.toString(subscript.exp);
      case INDEX() then Expression.toString(subscript.index);
      case SLICE() then Expression.toString(subscript.slice);
      case EXPANDED_SLICE()
        then List.toString(subscript.indices, toString, "", "{", ", ", "}", false);
      case WHOLE() then ":";
      case SPLIT_PROXY()
        then "<" + InstNode.name(subscript.origin) + ", " + InstNode.name(subscript.parent) + ">";
      case SPLIT_INDEX()
        then "<" + InstNode.name(subscript.node) + ", " + String(subscript.dimIndex) + ">";
    end match;
  end toString;

  function toStringList
    input list<Subscript> subscripts;
    output String string;
  algorithm
    string := List.toString(subscripts, toString, "", "[", ", ", "]", false);
  end toStringList;

  function toFlatString
    input Subscript subscript;
    output String string;
  algorithm
    string := match subscript
      case RAW_SUBSCRIPT() then Dump.printSubscriptStr(subscript.subscript);
      case UNTYPED() then Expression.toFlatString(subscript.exp);
      case INDEX() then Expression.toFlatString(subscript.index);
      case SLICE() then Expression.toFlatString(subscript.slice);
      case EXPANDED_SLICE()
        then List.toString(subscript.indices, toString, "", "{", ", ", "}", false);
      case WHOLE() then ":";
      case SPLIT_INDEX()
        then "<" + InstNode.name(subscript.node) + ", " + String(subscript.dimIndex) + ">";
    end match;
  end toFlatString;

  function toFlatStringList
    input list<Subscript> subscripts;
    output String string;
  algorithm
    string := List.toString(subscripts, toFlatString, "", "[", ",", "]", false);
  end toFlatStringList;

  function eval
    input Subscript subscript;
    input EvalTarget target = EvalTarget.IGNORE_ERRORS();
    output Subscript outSubscript;
  algorithm
    outSubscript := match subscript
      case INDEX() then INDEX(Ceval.evalExp(subscript.index, target));
      case SLICE() then SLICE(Ceval.evalExp(subscript.slice, target));
      else subscript;
    end match;
  end eval;

  function simplify
    input Subscript subscript;
    input Dimension dimension;
    output Subscript outSubscript;
  algorithm
    outSubscript := match subscript
      case INDEX() then INDEX(SimplifyExp.simplify(subscript.index));
      case SLICE() then simplifySlice(subscript.slice, dimension);
      else subscript;
    end match;
  end simplify;

  function simplifySlice
    input Expression slice;
    input Dimension dimension;
    output Subscript outSubscript;
  protected
    Expression exp;
  algorithm
    exp := SimplifyExp.simplify(slice);

    outSubscript := match exp
      // If the slice is equivalent to 1:size(dim), replace it with :
      case Expression.RANGE()
        guard (isNone(exp.step) or Expression.isOne(Util.getOption(exp.step))) and
              Dimension.expIsLowerBound(exp.start) and
              Dimension.expIsUpperBound(exp.stop, dimension)
        then WHOLE();

      // Otherwise return a new slice with the simplified expression.
      else SLICE(exp);
    end match;
  end simplifySlice;

  function simplifyList
    input list<Subscript> subscripts;
    input list<Dimension> dimensions;
    input Boolean trim = false;
    output list<Subscript> outSubscripts = {};
  protected
    Dimension d;
    list<Dimension> rest_d = dimensions;
  algorithm
    if listEmpty(dimensions) then
      // If the type of the subscript owner isn't known, for example when dealing
      // with expandable connector elements, treat the dimensions as unknown.
      outSubscripts := list(simplify(s, Dimension.UNKNOWN()) for s in subscripts);
    else
      rest_d := List.lastN(dimensions, listLength(subscripts));

      for s in subscripts loop
        d :: rest_d := rest_d;
        outSubscripts := simplify(s, d) :: outSubscripts;
      end for;

      if trim then
        outSubscripts := listReverseInPlace(List.trim(outSubscripts, isWhole));
      else
        outSubscripts := listReverseInPlace(outSubscripts);
      end if;
    end if;
  end simplifyList;

  function toDimension
    "Returns a dimension representing the size of the given subscript."
    input Subscript subscript;
    output Dimension dimension;
  algorithm
    dimension := match subscript
      case INDEX() then Dimension.fromInteger(1);
      case SLICE() then listHead(Type.arrayDims(Expression.typeOf(subscript.slice)));
      case WHOLE() then Dimension.UNKNOWN();
      case SPLIT_INDEX() then Dimension.fromInteger(1);
    end match;
  end toDimension;

  function fromDimension
    "Returns a slice subscripts that covers the given dimension.
     Will fail for untyped or unknown dimensions."
    input Dimension dimension;
    output Subscript subscript;
  algorithm
    subscript := match dimension
      case Dimension.INTEGER()
        then Subscript.SLICE(Expression.makeIntegerRange(1, 1, dimension.size));
      case Dimension.BOOLEAN()
        then Subscript.SLICE(Expression.makeRange(Expression.BOOLEAN(false), NONE(), Expression.BOOLEAN(true)));
      case Dimension.ENUM()
        then Subscript.SLICE(Expression.makeRange(
          Expression.makeEnumLiteral(dimension.enumType, 1),
          NONE(),
          Expression.makeEnumLiteral(dimension.enumType, Type.enumSize(dimension.enumType))));
      case Dimension.EXP()
        then Subscript.SLICE(Expression.makeRange(Expression.INTEGER(1), NONE(), dimension.exp));
    end match;
  end fromDimension;

  function scalarize
    input Subscript subscript;
    input Dimension dimension;
    output list<Subscript> subscripts;
  algorithm
    subscripts := match subscript
      case INDEX() then {subscript};
      case SLICE()
        then list(INDEX(e) for e in Expression.arrayElements(ExpandExp.expand(subscript.slice)));
      case WHOLE()
        then RangeIterator.map(RangeIterator.fromDim(dimension), makeIndex);
    end match;
  end scalarize;

  function scalarizeList
    input list<Subscript> subscripts;
    input list<Dimension> dimensions;
    output list<list<Subscript>> outSubscripts = {};
  protected
    Dimension dim;
    list<Dimension> rest_dims = dimensions;
    list<Subscript> subs;
  algorithm
    for s in subscripts loop
      dim :: rest_dims := rest_dims;
      subs := scalarize(s, dim);

      if listEmpty(subs) then
        outSubscripts := {};
        return;
      else
        outSubscripts := subs :: outSubscripts;
      end if;
    end for;

    for d in rest_dims loop
      subs := RangeIterator.map(RangeIterator.fromDim(d), makeIndex);

      if listEmpty(subs) then
        outSubscripts := {};
        return;
      else
        outSubscripts := subs :: outSubscripts;
      end if;
    end for;

    outSubscripts := listReverse(outSubscripts);
  end scalarizeList;

  function expand
    input Subscript subscript;
    input Dimension dimension;
    output Subscript outSubscript;
    output Boolean expanded;
  algorithm
    (outSubscript, expanded) := match subscript
      local
        Expression exp;
        RangeIterator iter;

      case SLICE() then expandSlice(subscript);

      case WHOLE()
        algorithm
          iter := RangeIterator.fromDim(dimension);

          if RangeIterator.isValid(iter) then
            outSubscript := EXPANDED_SLICE(RangeIterator.map(iter, makeIndex));
            expanded := true;
          else
            outSubscript := subscript;
            expanded := false;
          end if;
        then
          (outSubscript, expanded);

      else (subscript, true);
    end match;
  end expand;

  function expandSlice
    input Subscript subscript;
    output Subscript outSubscript;
    output Boolean expanded;
  algorithm
    (outSubscript, expanded) := match subscript
      local
        Expression exp;

      case SLICE()
        algorithm
          exp := ExpandExp.expand(subscript.slice);

          if Expression.isArray(exp) then
            outSubscript := EXPANDED_SLICE(list(INDEX(e) for e in Expression.arrayElements(exp)));
            expanded := true;
          else
            outSubscript := subscript;
            expanded := false;
          end if;
        then
          (outSubscript, expanded);

      else (subscript, false);
    end match;
  end expandSlice;

  function expandList
    input list<Subscript> subscripts;
    input list<Dimension> dimensions;
    output list<Subscript> outSubscripts = {};
  protected
    Dimension dim;
    list<Dimension> rest_dims = dimensions;
    Subscript sub;
  algorithm
    for s in subscripts loop
      dim :: rest_dims := rest_dims;
      sub := expand(s, dim);
      outSubscripts := sub :: outSubscripts;
    end for;

    for d in rest_dims loop
      sub := EXPANDED_SLICE(RangeIterator.map(RangeIterator.fromDim(d), makeIndex));
      outSubscripts := sub :: outSubscripts;
    end for;

    outSubscripts := listReverse(outSubscripts);
  end expandList;

  function variability
    input Subscript subscript;
    output Variability var;
  algorithm
    var := match subscript
      case UNTYPED() then Expression.variability(subscript.exp);
      case INDEX() then Expression.variability(subscript.index);
      case SLICE() then Expression.variability(subscript.slice);
      else Variability.CONSTANT;
    end match;
  end variability;

  function variabilityList
    input list<Subscript> subscripts;
    output Variability var = Variability.CONSTANT;
  algorithm
    for s in subscripts loop
      var := Prefixes.variabilityMax(var, variability(s));
    end for;
  end variabilityList;

  function purity
    input Subscript subscript;
    output Purity purity;
  algorithm
    purity := match subscript
      case UNTYPED() then Expression.purity(subscript.exp);
      case INDEX() then Expression.purity(subscript.index);
      case SLICE() then Expression.purity(subscript.slice);
      else Purity.IMPURE;
    end match;
  end purity;

  function purityList
    input list<Subscript> subscripts;
    output Purity pur = Purity.PURE;
  algorithm
    for s in subscripts loop
      pur := Prefixes.purityMin(pur, purity(s));
    end for;
  end purityList;

  function mergeList
    "Merges a list of subscripts with a list of 'existing' subscripts.
     This is done by e.g. subscripting existing slice and : subscripts,
     such that e.g. mergeList({1, :}, {3:5, 1:3, 4}) => {3, 1:3, 4}.
     The function will ensure that the output list contains at most as
     many subscripts as the given number of dimensions, and also returns
     the list of remaining subscripts that couldn't be added."
    input list<Subscript> newSubs "Subscripts to add";
    input list<Subscript> oldSubs "Existing subscripts";
    input Integer dimensions "The number of dimensions to subscript";
    output list<Subscript> outSubs "The merged subscripts, at most 'dimensions' many";
    output list<Subscript> remainingSubs "The subscripts that didn't fit";
  protected
    Integer subs_count;
    Subscript new_sub, old_sub;
    list<Subscript> rest_old_subs;
    Boolean merged = true;
  algorithm
    // If there aren't any existing subscripts we just add as many subscripts
    // from the list of new subscripts as possible.
    if listEmpty(oldSubs) then
      if listLength(newSubs) <= dimensions then
        outSubs := newSubs;
        remainingSubs := {};
      else
        (outSubs, remainingSubs) := List.split(newSubs, dimensions);
      end if;

      return;
    end if;

    subs_count := listLength(oldSubs);
    remainingSubs := newSubs;
    rest_old_subs := oldSubs;
    outSubs := {};

    // Loop over the remaining subscripts as long as they can be merged.
    while merged and not listEmpty(remainingSubs) loop
      new_sub :: remainingSubs := remainingSubs;
      merged := false;

      // Loop over the old subscripts while this new subscript hasn't been
      // merged and there's still old subscript left.
      while not merged loop
        if listEmpty(rest_old_subs) then
          remainingSubs := new_sub :: remainingSubs;
          break;
        else
          old_sub :: rest_old_subs := rest_old_subs;

          // Try to replace the old subscript with the new.
          (merged, outSubs) := match old_sub
            // If the old subscript is a slice, subscript it with the new subscript.
            case SLICE()
              algorithm
                // The old subscript only changes if the new is an index or slice, not :.
                if not isWhole(new_sub) then
                  outSubs := Subscript.INDEX(Expression.applySubscript(new_sub, old_sub.slice)) :: outSubs;
                else
                  outSubs := old_sub :: outSubs;
                end if;
              then
                (true, outSubs);

            // If the old subscript is :, replace it with the new subscript.
            case WHOLE() then (true, new_sub :: outSubs);
            // If the old subscript is a scalar index it can't be replaced.
            else (false, old_sub :: outSubs);
          end match;
        end if;
      end while;
    end while;

    // Append any remaining old subscripts.
    for s in rest_old_subs loop
      outSubs := s :: outSubs;
    end for;

    // Append any remaining new subscripts to the end of the list as long as
    // there are dimensions left to fill.
    while not listEmpty(remainingSubs) and subs_count < dimensions loop
      new_sub :: remainingSubs := remainingSubs;
      outSubs := new_sub :: outSubs;
      subs_count := subs_count + 1;
    end while;

    outSubs := listReverseInPlace(outSubs);
  end mergeList;

  function first
    input Dimension dim;
    output Subscript sub;
  algorithm
    sub := match dim
      case Dimension.INTEGER() then INDEX(Expression.INTEGER(1));
      case Dimension.BOOLEAN() then INDEX(Expression.BOOLEAN(false));
      case Dimension.ENUM()    then INDEX(Expression.nthEnumLiteral(dim.enumType, 1));
    end match;
  end first;

  function isSplitIndex
    input Subscript sub;
    output Boolean res;
  algorithm
    res := match sub
      case SPLIT_INDEX() then true;
      else false;
    end match;
  end isSplitIndex;

  function expandSplitIndices
    input list<Subscript> subs;
    input list<InstNode> indicesToKeep = {};
    output list<Subscript> outSubs = {};
  protected
    Boolean changed = false;
  algorithm
    for s in subs loop
      () := match s
        case SPLIT_INDEX()
          algorithm
            if List.isMemberOnTrue(s.node, indicesToKeep, InstNode.refEqual) then
              outSubs := s :: outSubs;
            else
              outSubs := WHOLE() :: outSubs;
              changed := true;
            end if;
          then
            ();

        else
          algorithm
            outSubs := s :: outSubs;
          then
            ();
      end match;
    end for;

    if changed then
      outSubs := List.trim(outSubs, isWhole);
      outSubs := listReverseInPlace(outSubs);
    else
      outSubs := subs;
    end if;
  end expandSplitIndices;

  function hash
    input Subscript sub;
    input Integer mod;
    output Integer hash;
  algorithm
    hash := match sub
      case SPLIT_PROXY() then intMod(InstNode.hash(sub.origin, 1) + InstNode.hash(sub.parent, 1), mod);
      case SPLIT_INDEX() then intMod(InstNode.hash(sub.node, 1) + sub.dimIndex, mod);
      else stringHashDjb2Mod(toString(sub), mod);
    end match;
  end hash;

  function splitIndexDimExp
    input Subscript sub;
    output Expression exp;
  protected
    InstNode node;
    Integer index;
  algorithm
    SPLIT_INDEX(node = node, dimIndex = index) := sub;
    exp := Dimension.sizeExp(Type.nthDimension(InstNode.getType(node), index));
  end splitIndexDimExp;

annotation(__OpenModelica_Interface="frontend");
end NFSubscript;
