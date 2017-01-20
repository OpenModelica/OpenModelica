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

encapsulated uniontype NFDimension
protected
  import Dimension = NFDimension;

public
  import Absyn.Exp;
  import Absyn.Path;
  import Dump;
  import NFExpression.Expression;

  record UNTYPED
    Absyn.Exp dimension;
    Boolean isProcessing;
  end UNTYPED;

  record INTEGER
    Integer size;
  end INTEGER;

  record BOOLEAN
  end BOOLEAN;

  record ENUM
    Absyn.Path enumTypeName;
    list<String> literals;
  end ENUM;

  record EXP
    Expression exp;
  end EXP;

  record UNKNOWN
  end UNKNOWN;

  function toDAE
    input Dimension dim;
    output DAE.Dimension daeDim;
  algorithm
    daeDim := match dim
      case INTEGER() then DAE.DIM_INTEGER(dim.size);
      case BOOLEAN() then DAE.DIM_BOOLEAN();
      case ENUM()
        then DAE.DIM_ENUM(dim.enumTypeName, dim.literals, listLength(dim.literals));
      case EXP() then DAE.DIM_EXP(Expression.toDAE(dim.exp));
      case UNKNOWN() then DAE.DIM_UNKNOWN();
    end match;
  end toDAE;

  function size
    input Dimension dim;
    output Integer size;
  algorithm
    size := match dim
      case INTEGER() then dim.size;
      case BOOLEAN() then 2;
      case ENUM() then listLength(dim.literals);
    end match;
  end size;

  function isEqual
    input Dimension dim1;
    input Dimension dim2;
    output Boolean isEqual;
  algorithm
    isEqual := match (dim1, dim2)
      case (UNKNOWN(), _) then true;
      case (_, UNKNOWN()) then true;
      case (EXP(), _) then true;
      case (_, EXP()) then true;
      else Dimension.size(dim1) == Dimension.size(dim2);
    end match;
  end isEqual;

  function isEqualKnown
    input Dimension dim1;
    input Dimension dim2;
    output Boolean isEqual;
  algorithm
    isEqual := match (dim1, dim2)
      case (UNKNOWN(), _) then false;
      case (_, UNKNOWN()) then false;
      case (EXP(), EXP()) then Expression.isEqual(dim1.exp, dim2.exp);
      else Dimension.size(dim1) == Dimension.size(dim2);
    end match;
  end isEqualKnown;

  function toString
    input Dimension dim;
    output String str;
  algorithm
    str := match dim
      case INTEGER() then String(dim.size);
      case BOOLEAN() then "Boolean";
      case ENUM() then Absyn.pathString(dim.enumTypeName);
      case EXP() then Expression.toString(dim.exp);
      case UNKNOWN() then ":";
      case UNTYPED() then Dump.printExpStr(dim.dimension);
    end match;
  end toString;

annotation(__OpenModelica_Interface="frontend");
end NFDimension;
