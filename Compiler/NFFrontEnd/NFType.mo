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

encapsulated uniontype NFType
protected
  import Type = NFType;
  import List;

public
  import Dimension = NFDimension;
  import NFInstNode.InstNode;

  record INTEGER
  end INTEGER;

  record REAL
  end REAL;

  record STRING
  end STRING;

  record BOOLEAN
  end BOOLEAN;

  record CLOCK
  end CLOCK;

  record ENUMERATION
    Absyn.Path typePath;
    list<String> literals;
  end ENUMERATION;

  record ARRAY
    Type elementType;
    list<Dimension> dimensions;
  end ARRAY;

  record TUPLE
    list<Type> types;
    Option<list<String>> names;
  end TUPLE;

  record NORETCALL
  end NORETCALL;

  record UNKNOWN
  end UNKNOWN;

  record COMPLEX
    InstNode cls;
  end COMPLEX;

  record FUNCTION
    Type resultType;
    DAE.FunctionAttributes attributes;
  end FUNCTION;

  // TODO: Fix constants in uniontypes and use these wherever applicable to
  // speed up comparisons using referenceEq.
  //constant Type INTEGER_DEFAULT = NFType.INTEGER();
  //constant Type REAL_DEFAULT = NFType.REAL();
  //constant Type STRING_DEFAULT = NFType.STRING();
  //constant Type BOOLEAN_DEFAULT = NFType.BOOLEAN();

  function liftArrayLeft
    "Adds an array dimension to a type on the left side, e.g.
       listArrayLeft(Real[2, 3], [4]) => Real[4, 2, 3]."
    input output Type ty;
    input Dimension dim;
  algorithm
    ty := match ty
      case ARRAY() then ARRAY(ty.elementType, dim :: ty.dimensions);
      else ARRAY(ty, {dim});
    end match;
  end liftArrayLeft;

  function liftArrayLeftList
    "Adds array dimensions to a type on the left side, e.g.
       listArrayLeft(Real[2, 3], [4, 5]) => Real[4, 5, 2, 3]."
    input output Type ty;
    input list<Dimension> dims;
  algorithm
    if listEmpty(dims) then
      return;
    end if;

    ty := match ty
      case ARRAY() then ARRAY(ty.elementType, listAppend(dims, ty.dimensions));
      else ARRAY(ty, dims);
    end match;
  end liftArrayLeftList;

  function isInteger
    input Type ty;
    output Boolean isInteger;
  algorithm
    isInteger := match ty
      case INTEGER() then true;
      else false;
    end match;
  end isInteger;

  function isReal
    input Type ty;
    output Boolean isReal;
  algorithm
    isReal := match ty
      case REAL() then true;
      else false;
    end match;
  end isReal;

  function isBoolean
    input Type ty;
    output Boolean isBool;
  algorithm
    isBool := match ty
      case BOOLEAN() then true;
      else false;
    end match;
  end isBoolean;

  function isString
    input Type ty;
    output Boolean isString;
  algorithm
    isString := match ty
      case STRING() then true;
      else false;
    end match;
  end isString;

  function isArray
    input Type ty;
    output Boolean isArray;
  algorithm
    isArray := match ty
      case ARRAY() then true;
      else false;
    end match;
  end isArray;

  function isEnumeration
    input Type ty;
    output Boolean isEnum;
  algorithm
    isEnum := match ty
      case ENUMERATION() then true;
      else false;
    end match;
  end isEnumeration;

  function isComplex
    input Type ty;
    output Boolean isComplex;
  algorithm
    isComplex := match ty
      case COMPLEX() then true;
      else false;
    end match;
  end isComplex;

  function isScalarArray
    input Type ty;
    output Boolean isScalar;
  algorithm
    isScalar := match ty
      case ARRAY(dimensions = {_}) then true;
      else false;
    end match;
  end isScalarArray;

  function isBasicNumeric
    input Type ty;
    output Boolean isNumeric;
  algorithm
    isNumeric := match ty
      case REAL() then true;
      case INTEGER() then true;
      case FUNCTION() then isBasicNumeric(ty.resultType);
      else false;
    end match;
  end isBasicNumeric;

  function isNumeric
    input Type ty;
    output Boolean isNumeric;
  algorithm
    isNumeric := match ty
      case ARRAY() then isBasicNumeric(ty.elementType);
      else isBasicNumeric(ty);
    end match;
  end isNumeric;

  function isScalarBuiltin
    "Returns true for all the builtin scalar types such as Integer, Real, etc."
    input Type ty;
    output Boolean isScalarBuiltin;
  algorithm
    isScalarBuiltin := match ty
      case INTEGER() then true;
      case REAL() then true;
      case STRING() then true;
      case BOOLEAN() then true;
      case CLOCK() then true;
      case ENUMERATION() then true;
      case FUNCTION() then isScalarBuiltin(ty.resultType);
    end match;
  end isScalarBuiltin;

  function isTuple
    input Type ty;
    output Boolean isTuple;
  algorithm
    isTuple := match ty
      case TUPLE() then true;
      else false;
    end match;
  end isTuple;

  function arrayElementType
    "Returns the common type of the elements in an array, or just the type
     itself if it's not an array type."
    input Type ty;
    output Type elementTy;
  algorithm
    elementTy := match ty
      case ARRAY() then ty.elementType;
      else ty;
    end match;
  end arrayElementType;

  function setArrayElementType
    "Sets the common type of the elements in an array, if the type is an array
     type. Otherwise it just returns the given element type."
    input Type arrayTy;
    input Type elementTy;
    output Type ty;
  algorithm
    ty := match arrayTy
      case ARRAY() then ARRAY(elementTy, arrayTy.dimensions);
      else elementTy;
    end match;
  end setArrayElementType;

  function elementType
    input Type ty;
    output Type elementTy;
  algorithm
    elementTy := match ty
      case ARRAY() then ty.elementType;
      case FUNCTION() then ty.resultType;
      else ty;
    end match;
  end elementType;

  function arrayDims
    input Type ty;
    output list<Dimension> dims;
  algorithm
    dims := match ty
      case ARRAY() then ty.dimensions;
      case FUNCTION() then arrayDims(ty.resultType);
    end match;
  end arrayDims;

  function getTypeDims
    input Type ty;
    output list<Dimension> dims;
  algorithm
    try
      dims := arrayDims(ty);
    else
      dims := {};
    end try;
  end getTypeDims;

  function dimensionCount
    input Type ty;
    output Integer dimCount;
  algorithm
    dimCount := match ty
      case ARRAY() then listLength(ty.dimensions);
      case FUNCTION() then dimensionCount(ty.resultType);
      else 0;
    end match;
  end dimensionCount;

  function scalarSuperType
    "Checks that the given types are scalar and that one is a subtype of the other."
    input Type ty1;
    input Type ty2;
    output Type ty;
  algorithm
    ty := match (ty1, ty2)
      case (INTEGER(), INTEGER()) then INTEGER();
      case (REAL(), REAL()) then REAL();
      case (INTEGER(), REAL()) then REAL();
      case (REAL(), INTEGER()) then REAL();
      case (BOOLEAN(), BOOLEAN()) then BOOLEAN();
    end match;
  end scalarSuperType;

  function toString
    input Type ty;
    output String str;
  algorithm
    str := match ty
      case Type.INTEGER() then "Integer";
      case Type.REAL() then "Real";
      case Type.STRING() then "String";
      case Type.BOOLEAN() then "Boolean";
      case Type.ENUMERATION() then "enumeration()";
      case Type.CLOCK() then "Clock";
      case Type.ARRAY() then toString(ty.elementType) + "[" + stringDelimitList(List.map(ty.dimensions, Dimension.toString), ", ") + "]";
      case Type.TUPLE() then "tuple(" + stringDelimitList(List.map(ty.types, toString), ", ") + ")";
      case Type.FUNCTION() then "function( output " + toString(ty.resultType) + " )";
      case Type.NORETCALL() then "noretcall()";
      case Type.UNKNOWN() then "unknown()";
      case Type.COMPLEX() then "complex()";
      else
        algorithm
          assert(false, getInstanceName() + " got unknown type: " + anyString(ty));
        then
          fail();
    end match;
  end toString;

  function toDAE
    input Type ty;
    output DAE.Type daeTy;
  algorithm
    daeTy := match ty
      case Type.INTEGER() then DAE.T_INTEGER_DEFAULT;
      case Type.REAL() then DAE.T_REAL_DEFAULT;
      case Type.STRING() then DAE.T_STRING_DEFAULT;
      case Type.BOOLEAN() then DAE.T_BOOL_DEFAULT;
      case Type.ENUMERATION() then DAE.T_ENUMERATION(NONE(), ty.typePath, ty.literals, {}, {});
      case Type.CLOCK() then DAE.T_CLOCK_DEFAULT;
      case Type.ENUMERATION() then DAE.T_ENUMERATION_DEFAULT;
      case Type.ARRAY()
        then DAE.T_ARRAY(toDAE(ty.elementType),
          list(Dimension.toDAE(d) for d in ty.dimensions));
      case Type.TUPLE()
        then DAE.T_TUPLE(list(toDAE(t) for t in ty.types), ty.names);
      case Type.FUNCTION()
        then DAE.T_FUNCTION({} /*TODO:FIXME*/, toDAE(ty.resultType), ty.attributes, Absyn.IDENT("TODO:FIXME"));
      case Type.NORETCALL() then DAE.T_NORETCALL_DEFAULT;
      case Type.UNKNOWN() then DAE.T_UNKNOWN_DEFAULT;
      case Type.COMPLEX() then DAE.T_COMPLEX_DEFAULT;
      else
        algorithm
          assert(false, getInstanceName() + " got unknown type: " + anyString(ty));
        then
          fail();
    end match;
  end toDAE;

  annotation(__OpenModelica_Interface="frontend");
end NFType;
