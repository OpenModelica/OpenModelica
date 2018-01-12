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
  import BindingOrigin = NFBindingOrigin;

public
  import Expression = NFExpression;
  import Binding = NFBinding;

  record ARRAY_ITERATOR
    list<Expression> array;
    list<Expression> slice;
  end ARRAY_ITERATOR;

  record SCALAR_ITERATOR
    Expression exp;
  end SCALAR_ITERATOR;

  record EACH_ITERATOR
    Expression exp;
  end EACH_ITERATOR;

  record NONE_ITERATOR
  end NONE_ITERATOR;

  function fromExp
    input Expression exp;
    output ExpressionIterator iterator;
  algorithm
    iterator := match exp
      local
        list<Expression> arr, slice;
        Expression e;

      case Expression.ARRAY()
        algorithm
          (arr, slice) := nextArraySlice(exp.elements);
        then
          ARRAY_ITERATOR(arr, slice);

      case Expression.CREF()
        algorithm
          e := Expression.expandCref(exp);

          iterator := match e
            case Expression.ARRAY() then fromExp(e);
            else SCALAR_ITERATOR(e);
          end match;
        then
          iterator;

      else SCALAR_ITERATOR(exp);
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
      case Binding.TYPED_BINDING()
        then if BindingOrigin.isEach(binding.origin) or BindingOrigin.isFromClass(binding.origin) then
          EACH_ITERATOR(binding.bindingExp) else fromExp(binding.bindingExp);

      case Binding.FLAT_BINDING()
        then SCALAR_ITERATOR(binding.bindingExp);
    end match;
  end fromBinding;

  function hasNext
    input ExpressionIterator iterator;
    output Boolean hasNext;
  algorithm
    hasNext := match iterator
      case ARRAY_ITERATOR() then not listEmpty(iterator.slice);
      case SCALAR_ITERATOR() then true;
      case EACH_ITERATOR() then true;
      case NONE_ITERATOR() then false;
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

      case ARRAY_ITERATOR()
        algorithm
          next :: rest := iterator.slice;

          if listEmpty(rest) then
            (arr, rest) := nextArraySlice(iterator.array);
            iterator := ARRAY_ITERATOR(arr, rest);
          else
            iterator.slice := rest;
          end if;
        then
          (iterator, next);

      case SCALAR_ITERATOR()
        then (NONE_ITERATOR(), iterator.exp);

      case EACH_ITERATOR() then (iterator, iterator.exp);
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

protected
  function nextArraySlice
    input output list<Expression> array;
          output list<Expression> slice;
  protected
    Expression e;
    list<Expression> arr;
  algorithm
    if listEmpty(array) then
      slice := {};
    else
      e := listHead(array);

      (array, slice) := match e
        case Expression.ARRAY()
          algorithm
            (arr, slice) := nextArraySlice(e.elements);

            if listEmpty(arr) then
              array := listRest(array);
            else
              e.elements := arr;
              array := e :: listRest(array);
            end if;
          then
            (array, slice);

        else ({}, array);
      end match;
    end if;
  end nextArraySlice;

annotation(__OpenModelica_Interface = "frontend");
end NFExpressionIterator;
