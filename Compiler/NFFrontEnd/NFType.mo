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
  import Restriction = NFRestriction;
  import NFClass.Class;

public
  import Dimension = NFDimension;
  import NFInstNode.InstNode;
  import Subscript = NFSubscript;
  import ComplexType = NFComplexType;
  import ConvertDAE = NFConvertDAE;

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

  record ENUMERATION_ANY "enumeration(:)"
  end ENUMERATION_ANY;

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
    ComplexType complexTy;
  end COMPLEX;

  record FUNCTION
    Type resultType;
    DAE.FunctionAttributes attributes;
  end FUNCTION;

  record METABOXED "Used for MetaModelica generic types"
    Type ty;
  end METABOXED;

  record POLYMORPHIC
    String name;
  end POLYMORPHIC;

  record ANY
  end ANY;

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

  function liftArrayRightList
    "Adds array dimensions to a type on the left side, e.g.
       listArrayLeft(Real[2, 3], [4, 5]) => Real[2, 3, 4, 5]."
    input output Type ty;
    input list<Dimension> dims;
  algorithm
    if listEmpty(dims) then
      return;
    end if;

    ty := match ty
      case ARRAY() then ARRAY(ty.elementType, listAppend(ty.dimensions, dims));
      else ARRAY(ty, dims);
    end match;
  end liftArrayRightList;

  function unliftArray
    input output Type ty;
  protected
    Type el_ty;
    list<Dimension> dims;
  algorithm
    ARRAY(el_ty, _ :: dims) := ty;

    if listEmpty(dims) then
      ty := el_ty;
    else
      ty := ARRAY(el_ty, dims);
    end if;
  end unliftArray;

  function unliftArrayN
    input Integer N;
    input output Type ty;
  protected
    Type el_ty;
    list<Dimension> dims;
  algorithm
    ARRAY(el_ty, dims) := ty;

    for i in 1:N loop
      dims := listRest(dims);
    end for;

    if listEmpty(dims) then
      ty := el_ty;
    else
      ty := ARRAY(el_ty, dims);
    end if;
  end unliftArrayN;

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

  function isScalar
    input Type ty;
    output Boolean isScalar;
  algorithm
    isScalar := match ty
      case ARRAY() then false;
      else true;
    end match;
  end isScalar;

  function isArray
    input Type ty;
    output Boolean isArray;
  algorithm
    isArray := match ty
      case ARRAY() then true;
      else false;
    end match;
  end isArray;

  function isVector
    "Return whether the type is a vector type or not, i.e. a 1-dimensional array."
    input Type ty;
    output Boolean isVector;
  algorithm
    isVector := match ty
      case ARRAY(dimensions = {_}) then true;
      else false;
    end match;
  end isVector;

  function isMatrix
    input Type ty;
    output Boolean isMatrix;
  algorithm
    isMatrix := match ty
      case ARRAY(dimensions = {_, _}) then true;
      else false;
    end match;
  end isMatrix;

  function isSquareMatrix
    input Type ty;
    output Boolean isSquareMatrix;
  algorithm
    isSquareMatrix := match ty
      local
        Dimension d1, d2;

      case ARRAY(dimensions = {d1, d2}) then Dimension.isEqualKnown(d1, d2);
      else false;
    end match;
  end isSquareMatrix;

  function isEnumeration
    input Type ty;
    output Boolean isEnum;
  algorithm
    isEnum := match ty
      case ENUMERATION() then true;
      case ENUMERATION_ANY() then true;
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

  function isConnector
    input Type ty;
    output Boolean isConnector;
  algorithm
    isConnector := match ty
      case COMPLEX(complexTy = ComplexType.CONNECTOR()) then true;
      else false;
    end match;
  end isConnector;

  function isRecord
    input Type ty;
    output Boolean isRecord;
  algorithm
    isRecord := match ty
      case COMPLEX() then Restriction.isRecord(Class.restriction(InstNode.getClass(ty.cls)));
      else false;
    end match;
  end isRecord;

  function isScalarArray
    input Type ty;
    output Boolean isScalar;
  algorithm
    isScalar := match ty
      case ARRAY(dimensions = {_}) then true;
      else false;
    end match;
  end isScalarArray;

  function isBasic
    input Type ty;
    output Boolean isNumeric;
  algorithm
    isNumeric := match ty
      case REAL() then true;
      case INTEGER() then true;
      case BOOLEAN() then true;
      case STRING() then true;
      case ENUMERATION() then true;
      case CLOCK() then true;
      case FUNCTION() then isBasic(ty.resultType);
      else false;
    end match;
  end isBasic;

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
      case ENUMERATION_ANY() then true;
      case FUNCTION() then isScalarBuiltin(ty.resultType);
      else false;
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

  function isUnknown
    input Type ty;
    output Boolean isUnknown;
  algorithm
    isUnknown := match ty
      case UNKNOWN() then true;
      else false;
    end match;
  end isUnknown;

  function isPolymorphic
    input Type ty;
    output Boolean isPolymorphic;
  algorithm
    isPolymorphic := match ty
      case POLYMORPHIC() then true;
      else false;
    end match;
  end isPolymorphic;

  function firstTupleType
    input Type ty;
    output Type outTy;
  algorithm
    outTy := match ty
      case TUPLE() then listHead(ty.types);
      else ty;
    end match;
  end firstTupleType;

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
      case METABOXED() then arrayDims(ty.ty);
      else {};
    end match;
  end arrayDims;

  function copyDims
    "Copies array dimensions from one type to another, discarding the existing
     dimensions of the destination type but keeping its element type."
    input Type srcType;
    input Type dstType;
    output Type ty;
  algorithm
    ty := match dstType
      case ARRAY()
        then ARRAY(dstType.elementType, arrayDims(srcType));

      else ARRAY(dstType, arrayDims(srcType));
    end match;
  end copyDims;

  function nthDimension
    input Type ty;
    input Integer index;
    output Dimension dim;
  algorithm
    dim := match ty
      case ARRAY() then listGet(ty.dimensions, index);
      case FUNCTION() then nthDimension(ty.resultType, index);
      case METABOXED() then nthDimension(ty.ty, index);
    end match;
  end nthDimension;

  function dimensionCount
    input Type ty;
    output Integer dimCount;
  algorithm
    dimCount := match ty
      case ARRAY() then listLength(ty.dimensions);
      case FUNCTION() then dimensionCount(ty.resultType);
      case METABOXED() then dimensionCount(ty.ty);
      else 0;
    end match;
  end dimensionCount;

  function nthEnumLiteral
    input Type ty;
    input Integer index;
    output String literal;
  protected
    list<String> literals;
  algorithm
    ENUMERATION(literals = literals) := ty;
    literal := listGet(literals, index);
  end nthEnumLiteral;

  function toString
    input Type ty;
    output String str;
  algorithm
    str := match ty
      case Type.INTEGER() then "Integer";
      case Type.REAL() then "Real";
      case Type.STRING() then "String";
      case Type.BOOLEAN() then "Boolean";
      case Type.CLOCK() then "Clock";
      case Type.ENUMERATION() then "enumeration " + Absyn.pathString(ty.typePath) +
        "(" + stringDelimitList(ty.literals, ", ") + ")";
      case Type.ENUMERATION_ANY() then "enumeration(:)";
      case Type.ARRAY() then toString(ty.elementType) + "[" + stringDelimitList(List.map(ty.dimensions, Dimension.toString), ", ") + "]";
      case Type.TUPLE() then "(" + stringDelimitList(List.map(ty.types, toString), ", ") + ")";
      case Type.NORETCALL() then "()";
      case Type.UNKNOWN() then "unknown()";
      case Type.COMPLEX() then InstNode.name(ty.cls);
      case Type.FUNCTION() then "function( output " + toString(ty.resultType) + " )";
      case Type.METABOXED() then "#" + toString(ty.ty);
      case Type.POLYMORPHIC() then "<" + ty.name + ">";
      case Type.ANY() then "$ANY$";
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown type: " + anyString(ty), sourceInfo());
        then
          fail();
    end match;
  end toString;

  function typenameString
    input Type ty;
    output String str;
  algorithm
    str := match ty
      case Type.ENUMERATION() then Absyn.pathString(ty.typePath);
      else toString(ty);
    end match;
  end typenameString;

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
      case Type.ARRAY()
        then DAE.T_ARRAY(toDAE(ty.elementType),
          list(Dimension.toDAE(d) for d in ty.dimensions));
      case Type.TUPLE()
        then DAE.T_TUPLE(list(toDAE(t) for t in ty.types), ty.names);
      case Type.FUNCTION()
        then DAE.T_FUNCTION({} /*TODO:FIXME*/, toDAE(ty.resultType), ty.attributes, Absyn.IDENT("TODO:FIXME"));
      case Type.NORETCALL() then DAE.T_NORETCALL_DEFAULT;
      case Type.UNKNOWN() then DAE.T_UNKNOWN_DEFAULT;
      case Type.COMPLEX() then InstNode.toDAEType(ty.cls);
      case Type.POLYMORPHIC() then DAE.T_METAPOLYMORPHIC(ty.name);
      case Type.ANY() then DAE.T_ANYTYPE(NONE());
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown type: " + anyString(ty), sourceInfo());
        then
          fail();
    end match;
  end toDAE;

  function subscript
    "Reduces a type's dimensions based on the given list of subscripts."
    input output Type ty;
    input list<Subscript> subs;
  protected
    Dimension dim;
    list<Dimension> dims, subbed_dims = {};
  algorithm
    if listEmpty(subs) then
      return;
    end if;

    dims := arrayDims(ty);

    for sub in subs loop
      dim :: dims := dims;

      subbed_dims := match sub
        case Subscript.INDEX() then subbed_dims;
        case Subscript.SLICE() then Subscript.toDimension(sub) :: subbed_dims;
        case Subscript.WHOLE() then dim :: subbed_dims;
      end match;
    end for;

    ty := arrayElementType(ty);

    if not (listEmpty(subbed_dims) and listEmpty(dims)) then
      ty := ARRAY(ty, listAppend(listReverse(subbed_dims), dims));
    end if;
  end subscript;

  function isEqual
    input Type ty1;
    input Type ty2;
    output Boolean equal;
  algorithm
    if referenceEq(ty1, ty2) then
      equal := true;
      return;
    end if;

    if valueConstructor(ty1) <> valueConstructor(ty2) then
      equal := false;
      return;
    end if;

    equal := match (ty1, ty2)
      local
        list<String> names1, names2;

      case (ENUMERATION(), ENUMERATION())
        then List.isEqualOnTrue(ty1.literals, ty2.literals, stringEq);

      case (ARRAY(), ARRAY())
        then isEqual(ty1.elementType, ty2.elementType) and
             List.isEqualOnTrue(ty1.dimensions, ty2.dimensions, Dimension.isEqualKnown);

      case (TUPLE(names = SOME(names1)), TUPLE(names = SOME(names2)))
        then List.isEqualOnTrue(names1, names2, stringEq) and
             List.isEqualOnTrue(ty1.types, ty2.types, isEqual);

      case (TUPLE(names = NONE()), TUPLE(names = NONE()))
        then List.isEqualOnTrue(ty1.types, ty2.types, isEqual);

      case (TUPLE(), TUPLE()) then false;

      else true;
    end match;
  end isEqual;

  function isDiscrete
    input Type ty;
    output Boolean isDiscrete;
  algorithm
    isDiscrete := match ty
      case INTEGER() then true;
      case STRING() then true;
      case BOOLEAN() then true;
      case ENUMERATION() then true;
      case ARRAY() then isDiscrete(ty.elementType);
      case FUNCTION() then isDiscrete(ty.resultType);
      else false;
    end match;
  end isDiscrete;

  annotation(__OpenModelica_Interface="frontend");
end NFType;
