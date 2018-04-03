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
  import Subscript = NFSubscript;

  import DAE;
  import List;
  import SimplifyExp = NFSimplifyExp;
  import Type = NFType;
  import RangeIterator = NFRangeIterator;
  import Dump;

public
  import Expression = NFExpression;
  import Absyn;
  import Dimension = NFDimension;
  import NFPrefixes.Variability;

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

  record WHOLE end WHOLE;

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

  function isIndex
    input Subscript sub;
    output Boolean isIndex;
  algorithm
    isIndex := match sub
      case INDEX() then true;
      else false;
    end match;
  end isIndex;

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

      else false;
    end match;
  end isScalar;

  function isScalarConst
    input Subscript sub;
    output Boolean isScalarConst;
  algorithm
    isScalarConst := match sub
      case INDEX() then Expression.isScalarConst(sub.index);
      else false;
    end match;
  end isScalarConst;

  function isEqual
    input Subscript subscript1;
    input Subscript subscript2;
    output Boolean isEqual;
  algorithm
    isEqual := match (subscript1, subscript2)
      case (RAW_SUBSCRIPT(), RAW_SUBSCRIPT())
        then Absyn.subscriptEqual(subscript1.subscript, subscript2.subscript);

      case (UNTYPED(), UNTYPED())
        then Expression.isEqual(subscript1.exp, subscript2.exp);

      case (INDEX(), INDEX())
        then Expression.isEqual(subscript1.index, subscript2.index);

      case (SLICE(), SLICE())
        then Expression.isEqual(subscript1.slice, subscript2.slice);

      case (WHOLE(), WHOLE()) then true;
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
          Error.assertion(false, getInstanceName() + " failed on unknown subscript", sourceInfo());
        then
          fail();
    end match;
  end toDAE;

  function toString
    input Subscript subscript;
    output String string;
  algorithm
    string := match subscript
      case RAW_SUBSCRIPT() then Dump.printSubscriptStr(subscript.subscript);
      case UNTYPED() then Expression.toString(subscript.exp);
      case INDEX() then Expression.toString(subscript.index);
      case SLICE() then Expression.toString(subscript.slice);
      case WHOLE() then ":";
    end match;
  end toString;

  function toStringList
    input list<Subscript> subscripts;
    output String string;
  algorithm
    string := List.toString(subscripts, toString, "", "[", ", ", "]", false);
  end toStringList;

  function simplify
    input output Subscript subscript;
  algorithm
    () := match subscript
      case INDEX()
        algorithm
          subscript.index := SimplifyExp.simplifyExp(subscript.index);
        then
          ();

      case SLICE()
        algorithm
          subscript.slice := SimplifyExp.simplifyExp(subscript.slice);
        then
          ();

      else ();
    end match;
  end simplify;

  function toDimension
    "Returns a dimension representing the size of the given subscript."
    input Subscript subscript;
    output Dimension dimension;
  algorithm
    dimension := match subscript
      case INDEX() then Dimension.fromInteger(1);
      case SLICE() then listHead(Type.arrayDims(Expression.typeOf(subscript.slice)));
      case WHOLE() then Dimension.UNKNOWN();
    end match;
  end toDimension;

  function expand
    input Subscript subscript;
    input Dimension dimension;
    output list<Subscript> subscripts;
  algorithm
    subscripts := match subscript
      case INDEX() then {subscript};
      case SLICE()
        then list(INDEX(e) for e in Expression.arrayElements(Expression.expand(subscript.slice)));
      case WHOLE()
        then RangeIterator.map(RangeIterator.fromDim(dimension), makeIndex);
    end match;
  end expand;

  function expandList
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
      subs := expand(s, dim);

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
  end expandList;

  function variability
    input Subscript subscript;
    output Variability var;
  algorithm
    var := match subscript
      case UNTYPED() then Expression.variability(subscript.exp);
      case INDEX() then Expression.variability(subscript.index);
      case SLICE() then Expression.variability(subscript.slice);
      case WHOLE() then Variability.CONSTANT;
    end match;
  end variability;

annotation(__OpenModelica_Interface="frontend");
end NFSubscript;
