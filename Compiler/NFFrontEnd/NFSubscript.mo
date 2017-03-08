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

public
  import Expression = NFExpression;

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
      else UNTYPED(exp);
    end match;
  end fromExp;

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
          assert(false, getInstanceName() + " failed on unknown subscript");
        then
          fail();
    end match;
  end toDAE;

  function toString
    input Subscript subscript;
    output String string;
  algorithm
    string := match subscript
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

annotation(__OpenModelica_Interface="frontend");
end NFSubscript;
