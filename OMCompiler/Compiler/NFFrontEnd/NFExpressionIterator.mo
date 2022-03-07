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

encapsulated uniontype NFExpressionIterator
protected
  import ExpressionIterator = NFExpressionIterator;
  import ComponentRef = NFComponentRef;
  import NFInstNode.InstNode;
  import ExpandExp = NFExpandExp;
  import SimplifyExp = NFSimplifyExp;
  import MetaModelica.Dangerous.listReverseInPlace;

public
  import Expression = NFExpression;
  import Binding = NFBinding;

  record ARRAY_ITERATOR
    array<Expression> arr;
    Integer index;
    list<array<Expression>> arrays;
  end ARRAY_ITERATOR;

  record SCALAR_ITERATOR
    Expression exp;
  end SCALAR_ITERATOR;

  record EACH_ITERATOR
    Expression exp;
  end EACH_ITERATOR;

  record NONE_ITERATOR
  end NONE_ITERATOR;

  record REPEAT_ITERATOR
    list<Expression> current;
    list<Expression> all;
  end REPEAT_ITERATOR;

  function fromExp
    input Expression exp;
    output ExpressionIterator iterator;
  algorithm
    iterator := match exp
      local
        list<Expression> arr, slice;
        Expression e;
        Boolean expanded;

      case Expression.ARRAY()
        algorithm
          (e, expanded) := ExpandExp.expand(exp);

          if not expanded then
            Error.assertion(false, getInstanceName() + " got unexpandable expression `" +
              Expression.toString(exp) + "`", sourceInfo());
          end if;
        then
          makeArrayIterator(e);

      case Expression.CREF()
        algorithm
          e := ExpandExp.expandCref(exp);

          iterator := match e
            case Expression.ARRAY() then fromExp(e);
            else SCALAR_ITERATOR(e);
          end match;
        then
          iterator;

      else
        algorithm
          e := ExpandExp.expand(exp);
        then
          if referenceEq(e, exp) then SCALAR_ITERATOR(exp) else fromExp(e);

    end match;
  end fromExp;

  function fromExpOpt
    input Option<Expression> optExp;
    output ExpressionIterator iterator;
  algorithm
    iterator := match optExp
      local
        Expression exp;

      case SOME(exp) then fromExp(exp);
      else NONE_ITERATOR();
    end match;
  end fromExpOpt;

  function fromBinding
    input Binding binding;
    output ExpressionIterator iterator;
  algorithm
    iterator := match binding
      local
        list<Expression> expl;

      case Binding.TYPED_BINDING(eachType = NFBinding.EachType.EACH)
        then EACH_ITERATOR(binding.bindingExp);

      case Binding.TYPED_BINDING()
        then fromExp(binding.bindingExp);

      case Binding.FLAT_BINDING()
        then EACH_ITERATOR(binding.bindingExp);
    end match;
  end fromBinding;

  function hasNext
    input ExpressionIterator iterator;
    output Boolean hasNext;
  algorithm
    hasNext := match iterator
      case ARRAY_ITERATOR() then iterator.index <= arrayLength(iterator.arr);
      case SCALAR_ITERATOR() then true;
      case EACH_ITERATOR() then true;
      case NONE_ITERATOR() then false;
      case REPEAT_ITERATOR() then true;
    end match;
  end hasNext;

  function next
    input output ExpressionIterator iterator;
    output Expression nextExp;
  algorithm
    (iterator, nextExp) := match iterator
      local
        list<Expression> rest, arr;
        Expression next;
        list<array<Expression>> arrs;

      case ARRAY_ITERATOR()
        algorithm
          next := arrayGet(iterator.arr, iterator.index);

          if iterator.index >= arrayLength(iterator.arr) then
            arrs := iterator.arrays;
            while not listEmpty(arrs) and arrayEmpty(listHead(arrs)) loop
              arrs := listRest(arrs);
            end while;

            if listEmpty(arrs) then
              iterator := ARRAY_ITERATOR(listArray({}), 1, {});
            else
              iterator := ARRAY_ITERATOR(listHead(arrs), 1, listRest(arrs));
            end if;
          else
            iterator.index := iterator.index + 1;
          end if;
        then
          (iterator, next);

      case SCALAR_ITERATOR()
        then (NONE_ITERATOR(), iterator.exp);

      case EACH_ITERATOR() then (iterator, iterator.exp);

      case REPEAT_ITERATOR(rest, arr)
        algorithm
          if not listEmpty(rest) then
            next :: rest := rest;
          else
            next :: rest := arr;
          end if;
        then
          (REPEAT_ITERATOR(rest, arr), next);

    end match;
  end next;

  function nextOpt
    input output ExpressionIterator iterator;
          output Option<Expression> nextExp;
  protected
    Expression exp;
  algorithm
    if hasNext(iterator) then
      (iterator, exp) := next(iterator);
      nextExp := SOME(exp);
    else
      nextExp := NONE();
    end if;
  end nextOpt;

  function toList
    // TODO: Implement this function more efficiently, using the internal
    //       structure of the iterators instead of hasNext and next.
    input ExpressionIterator iterator;
    output list<Expression> expl = {};
  protected
    ExpressionIterator iter;
    Expression exp;
  algorithm
    iter := iterator;

    while hasNext(iter) loop
      (iter, exp) := next(iter);
      expl := exp :: expl;
    end while;

    expl := listReverse(expl);
  end toList;

  function isSubscriptedArrayCall
    "only checks first slice for a subscripted call and assumes it holds for all of them"
    input ExpressionIterator iterator;
    input Boolean trySimplify = true;
    output Boolean b;
  protected
    function is_sub_call
      input Expression exp;
      input Boolean trySimplify;
      output Boolean res;
    protected
      Expression call;
    algorithm
      res := match exp
        case Expression.SUBSCRIPTED_EXP(exp = Expression.CALL())
          then not trySimplify or Expression.isCall(SimplifyExp.simplify(exp.exp));
        else false;
      end match;
    end is_sub_call;
  algorithm
    b := match iterator
      case ARRAY_ITERATOR() then is_sub_call(arrayGet(iterator.arr, 1), trySimplify);
      else false;
    end match;
  end isSubscriptedArrayCall;

protected
  function makeArrayIterator
    input Expression exp;
    output ExpressionIterator iterator;
  protected
    array<Expression> arr;
    list<array<Expression>> arrays;
  algorithm
    arrays := flattenArray(exp, {});

    if listEmpty(arrays) then
      iterator := ARRAY_ITERATOR(listArray({}), 1, arrays);
    else
      iterator := ARRAY_ITERATOR(listHead(arrays), 1, listRest(arrays));
    end if;
  end makeArrayIterator;

  function flattenArray
    input Expression exp;
    input output list<array<Expression>> arrays;
  algorithm
    arrays := flattenArray_impl(exp, {});
    arrays := listReverseInPlace(arrays);

    while not listEmpty(arrays) and arrayEmpty(listHead(arrays)) loop
      arrays := listRest(arrays);
    end while;
  end flattenArray;

  function flattenArray_impl
    input Expression exp;
    input output list<array<Expression>> arrays;
  algorithm
    if Expression.isVector(exp) then
      arrays := Expression.arrayElements(exp) :: arrays;
    else
      for e in Expression.arrayElements(exp) loop
        arrays := flattenArray_impl(e, arrays);
      end for;
    end if;
  end flattenArray_impl;

annotation(__OpenModelica_Interface = "frontend");
end NFExpressionIterator;
