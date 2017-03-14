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

public
  import Expression = NFExpression;

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

  record ENUM_RANGE

  end ENUM_RANGE;

  record ARRAY
    list<Expression> values;
  end ARRAY;

  function new
    input Expression exp;
    output RangeIterator iterator;
  algorithm
    iterator := match exp
      local
        Integer istart, istep, istop;
        Real rstart, rstep, rstop;

      case Expression.ARRAY() then ARRAY(exp.elements);

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

      else
        algorithm
          assert(false, getInstanceName() + " got unknown range");
        then
          fail();

    end match;
  end new;

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

      case ARRAY()
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
      case ARRAY({}) then false;
      case ARRAY() then true;
    end match;
  end hasNext;

annotation(__OpenModelica_Interface="frontend");
end NFRangeIterator;
