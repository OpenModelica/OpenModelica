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

encapsulated uniontype NFRangeIterator
protected
  import RangeIterator = NFRangeIterator;
  import Type = NFType;

public
  import Expression = NFExpression;
  import Dimension = NFDimension;

  record INT_RANGE
    Integer current;
    Integer stepsize;
    Integer last;
  end INT_RANGE;

  record REAL_RANGE
    Real start;
    Real stepsize;
    Real stop;
  end REAL_RANGE;

  record ARRAY_RANGE
    list<Expression> values;
  end ARRAY_RANGE;

  function fromExp
    input Expression exp;
    output RangeIterator iterator;
  algorithm
    iterator := match exp
      local
        Integer istart, istep, istop;
        Real rstart, rstep, rstop;
        Type ty;
        list<String> literals;
        Absyn.Path path;
        list<Expression> values;

      case Expression.ARRAY() then ARRAY_RANGE(exp.elements);

      case Expression.RANGE(start = Expression.INTEGER(istart),
                            step = SOME(Expression.INTEGER(istep)),
                            stop = Expression.INTEGER(istop))
        then INT_RANGE(istart, istep, istop);

      case Expression.RANGE(start = Expression.INTEGER(istart),
                            step = NONE(),
                            stop = Expression.INTEGER(istop))
        then INT_RANGE(istart, 1, istop);

      case Expression.RANGE(start = Expression.REAL(rstart),
                            step = SOME(Expression.REAL(rstep)),
                            stop = Expression.REAL(rstop))
        then REAL_RANGE(rstart, rstep, rstop);

      case Expression.RANGE(start = Expression.REAL(rstart),
                            step = NONE(),
                            stop = Expression.REAL(rstop))
        then REAL_RANGE(rstart, 1.0, rstop);

      case Expression.RANGE(start = Expression.ENUM_LITERAL(ty = ty, index = istart),
                            step = NONE(),
                            stop = Expression.ENUM_LITERAL(index = istop))
        algorithm
          Type.ENUMERATION(typePath = _, literals = literals) := ty;
          values := {};

          if istart <= istop then
            for i in 2:istart loop
              literals := listRest(literals);
            end for;

            for i in istart:istop loop
              values := Expression.ENUM_LITERAL(ty, listHead(literals), i) :: values;
              literals := listRest(literals);
            end for;

            values := listReverse(values);
          end if;
        then
          ARRAY_RANGE(values);

      else
        algorithm
          assert(false, getInstanceName() + " got unknown range");
        then
          fail();

    end match;
  end fromExp;

  function fromDim
    input Dimension dim;
    output RangeIterator iterator;
  algorithm
    iterator := match dim
      local
        Type ty;
        list<Expression> expl;

      case Dimension.INTEGER() then INT_RANGE(1, 1, dim.size);

      case Dimension.BOOLEAN()
        then ARRAY_RANGE({Expression.BOOLEAN(false), Expression.BOOLEAN(true)});

      case Dimension.ENUM(enumType = ty as Type.ENUMERATION())
        then ARRAY_RANGE(Expression.makeEnumLiterals(ty));

      case Dimension.EXP() then fromExp(dim.exp);

      else
        algorithm
          assert(false, getInstanceName() + " got unknown dim");
        then
          fail();

    end match;
  end fromDim;

  function next
    input output RangeIterator iterator;
    output Expression nextExp;
  algorithm
    nextExp := match iterator
      case INT_RANGE()
        algorithm
          nextExp := Expression.INTEGER(iterator.current);
          iterator.current := iterator.current + iterator.stepsize;
        then
          nextExp;

      case ARRAY_RANGE()
        algorithm
          nextExp := listHead(iterator.values);
          iterator.values := listRest(iterator.values);
        then
          nextExp;

    end match;
  end next;

  function hasNext
    input RangeIterator iterator;
    output Boolean hasNext;
  algorithm
    hasNext := match iterator
      case INT_RANGE() then iterator.current <= iterator.last;
      case ARRAY_RANGE() then not listEmpty(iterator.values);
    end match;
  end hasNext;

  function toList
    input RangeIterator iterator;
    output list<Expression> expl = listReverse(toListReverse(iterator));
  end toList;

  function toListReverse
    input RangeIterator iterator;
    output list<Expression> expl = {};
  protected
    RangeIterator iter = iterator;
    Expression exp;
  algorithm
    while hasNext(iter) loop
      (iter, exp) := next(iter);
      expl := exp :: expl;
    end while;
  end toListReverse;

  function map<T>
    input RangeIterator iterator;
    input FuncT func;
    output list<T> lst = {};

    partial function FuncT
      input Expression exp;
      output T res;
    end FuncT;
  protected
    RangeIterator iter = iterator;
    Expression exp;
  algorithm
    while hasNext(iter) loop
      (iter, exp) := next(iter);
      lst := func(exp) :: lst;
    end while;

    lst := listReverse(lst);
  end map;

annotation(__OpenModelica_Interface="frontend");
end NFRangeIterator;
