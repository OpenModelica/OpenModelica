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
  import Class = NFClass;
  import IOStream;
  import Util;
  import NFClassTree.ClassTree;

public
  import Dimension = NFDimension;
  import NFInstNode.InstNode;
  import Subscript = NFSubscript;
  import ComplexType = NFComplexType;
  import NFFunction.Function;
  import Record = NFRecord;

  type FunctionType = enumeration(
    FUNCTIONAL_PARAMETER "Function parameter of function type.",
    FUNCTION_REFERENCE   "Function name used to reference a function.",
    FUNCTIONAL_VARIABLE  "A variable that contains a function reference."
  );

  type Branch = enumeration(
    NONE,
    TRUE,
    FALSE
  );

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
    Function fn;
    FunctionType fnType;
  end FUNCTION;

  record METABOXED "Used for MetaModelica generic types"
    Type ty;
  end METABOXED;

  record POLYMORPHIC
    String name;
  end POLYMORPHIC;

  record ANY
  end ANY;

  record SUBSCRIPTED
    String name;
    Type ty;
    list<Type> subs;
    Type subscriptedTy;
  end SUBSCRIPTED;

  record CONDITIONAL_ARRAY
    "A type that might be one of two types depending on a condition.
     The two types are assumed to be array types with equal number of dimensions."
    Type trueType;
    Type falseType;
    Branch matchedBranch;
  end CONDITIONAL_ARRAY;

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
      case CONDITIONAL_ARRAY() then CONDITIONAL_ARRAY(liftArrayLeft(ty.trueType, dim),
                                                      liftArrayLeft(ty.falseType, dim),
                                                      ty.matchedBranch);
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
      case CONDITIONAL_ARRAY() then CONDITIONAL_ARRAY(liftArrayLeftList(ty.trueType, dims),
                                                      liftArrayLeftList(ty.falseType, dims),
                                                      ty.matchedBranch);
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
      case CONDITIONAL_ARRAY() then CONDITIONAL_ARRAY(liftArrayRightList(ty.trueType, dims),
                                                      liftArrayRightList(ty.falseType, dims),
                                                      ty.matchedBranch);
      else ARRAY(ty, dims);
    end match;
  end liftArrayRightList;

  function unliftArray
    input output Type ty;
  algorithm
    ty := match ty
      local
        list<Dimension> dims;
        Type tty, fty;

      case ARRAY(dimensions = _ :: dims)
        then if listEmpty(dims) then ty.elementType else ARRAY(ty.elementType, dims);

      case CONDITIONAL_ARRAY()
        algorithm
          tty := unliftArray(ty.trueType);
          fty := unliftArray(ty.falseType);
        then
          if isEqual(tty, fty) then tty else CONDITIONAL_ARRAY(tty, fty, ty.matchedBranch);

    end match;
  end unliftArray;

  function unliftArrayN
    input Integer N;
    input output Type ty;
  algorithm
    if N == 0 then
      return;
    end if;

    ty := match ty
      local
        list<Dimension> dims;
        Type tty, fty;

      case ARRAY(dimensions = dims)
        algorithm
          for i in 1:N loop
            dims := listRest(dims);
          end for;
        then
          if listEmpty(dims) then ty.elementType else ARRAY(ty.elementType, dims);

      case CONDITIONAL_ARRAY()
        algorithm
          tty := unliftArrayN(N, ty.trueType);
          fty := unliftArrayN(N, ty.falseType);
        then
          if isEqual(tty, fty) then tty else CONDITIONAL_ARRAY(tty, fty, ty.matchedBranch);

    end match;
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

  function isRealRecursive
    input Type ty;
    output Boolean isReal;
  algorithm
    isReal := match ty
      case REAL()   then true;
      case ARRAY()  then isRealRecursive(ty.elementType);
      else false;
    end match;
  end isRealRecursive;

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

  function isClock
    input Type ty;
    output Boolean isClock;
  algorithm
    isClock := match ty
      case CLOCK() then true;
      else false;
    end match;
  end isClock;

  function isScalar
    input Type ty;
    output Boolean isScalar;
  algorithm
    isScalar := match ty
      case ARRAY() then false;
      case CONDITIONAL_ARRAY() then false;
      else true;
    end match;
  end isScalar;

  function isArray
    input Type ty;
    output Boolean isArray;
  algorithm
    isArray := match ty
      case ARRAY() then true;
      case CONDITIONAL_ARRAY() then true;
      else false;
    end match;
  end isArray;

  function isConditionalArray
    input Type ty;
    output Boolean isConditionalArray;
  algorithm
    isConditionalArray := match ty
      case CONDITIONAL_ARRAY() then true;
      else false;
    end match;
  end isConditionalArray;

  function setConditionalArrayTypes
    input Type condType;
    input Type trueType;
    input Type falseType;
    output Type outType;
  protected
    Branch matched_branch;
  algorithm
    CONDITIONAL_ARRAY(matchedBranch = matched_branch) := condType;
    outType := CONDITIONAL_ARRAY(trueType, falseType, matched_branch);
  end setConditionalArrayTypes;

  function isMatchedBranch
    input Boolean condition;
    input Type condType;
    output Boolean isMatched = true;
  protected
    Branch matched_branch;
  algorithm
    CONDITIONAL_ARRAY(matchedBranch = matched_branch) := condType;

    if condition and matched_branch == Branch.FALSE or
       not condition and matched_branch == Branch.TRUE then
      isMatched := false;
    end if;
  end isMatchedBranch;

  function simplifyConditionalArray
    input Type ty;
    output Type outType;
  algorithm
    outType := match ty
      case CONDITIONAL_ARRAY()
        then match ty.matchedBranch
            case Branch.TRUE then ty.trueType;
            case Branch.FALSE then ty.falseType;
            else ty;
          end match;

      else ty;
    end match;
  end simplifyConditionalArray;

  function isVector
    "Return whether the type is a vector type or not, i.e. a 1-dimensional array."
    input Type ty;
    output Boolean isVector;
  algorithm
    isVector := match ty
      case ARRAY(dimensions = {_}) then true;
      case CONDITIONAL_ARRAY() then isVector(ty.trueType);
      else false;
    end match;
  end isVector;

  function isMatrix
    input Type ty;
    output Boolean isMatrix;
  algorithm
    isMatrix := match ty
      case ARRAY(dimensions = {_, _}) then true;
      case CONDITIONAL_ARRAY() then isMatrix(ty.trueType);
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
      case CONDITIONAL_ARRAY() then isSquareMatrix(ty.trueType);
      else false;
    end match;
  end isSquareMatrix;

  function isEmptyArray
    input Type ty;
    output Boolean isEmpty;
  algorithm
    isEmpty := match ty
      case ARRAY() then List.exist(ty.dimensions, Dimension.isZero);
      case CONDITIONAL_ARRAY() then isEmptyArray(ty.trueType);
      else false;
    end match;
  end isEmptyArray;

  function isSingleElementArray
    input Type ty;
    output Boolean isSingleElement;
  algorithm
    isSingleElement := match ty
      local
        Dimension d;

      case ARRAY(dimensions = {d})
        then Dimension.isKnown(d) and Dimension.size(d) == 1;

      else false;
    end match;
  end isSingleElementArray;

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

  function isExpandableConnector
    input Type ty;
    output Boolean isExpandable;
  algorithm
    isExpandable := match ty
      case COMPLEX(complexTy = ComplexType.EXPANDABLE_CONNECTOR()) then true;
      else false;
    end match;
  end isExpandableConnector;

  function isExternalObject
    input Type ty;
    output Boolean isEO;
  algorithm
    isEO := match ty
      case COMPLEX(complexTy = ComplexType.EXTERNAL_OBJECT()) then true;
      else false;
    end match;
  end isExternalObject;

  function isRecord
    input Type ty;
    output Boolean isRecord;
  algorithm
    isRecord := match ty
      case COMPLEX(complexTy = ComplexType.RECORD()) then true;
      else false;
    end match;
  end isRecord;

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
      case FUNCTION() then isBasic(Function.returnType(ty.fn));
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
      else false;
    end match;
  end isBasicNumeric;

  function isNumeric
    input Type ty;
    output Boolean isNumeric;
  algorithm
    isNumeric := match ty
      case ARRAY() then isBasicNumeric(ty.elementType);
      case CONDITIONAL_ARRAY() then isNumeric(ty.trueType);
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
      case FUNCTION() then isScalarBuiltin(Function.returnType(ty.fn));
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

  function isKnown
    input Type ty;
    output Boolean isKnown;
  algorithm
    isKnown := match ty
      case UNKNOWN() then false;
      else true;
    end match;
  end isKnown;

  function isPolymorphic
    input Type ty;
    output Boolean isPolymorphic;
  algorithm
    isPolymorphic := match ty
      case POLYMORPHIC() then true;
      else false;
    end match;
  end isPolymorphic;

  function isPolymorphicNamed
    input Type ty;
    input String name;
    output Boolean res;
  algorithm
    res := match ty
      case POLYMORPHIC() then name == ty.name;
      else false;
    end match;
  end isPolymorphicNamed;

  function firstTupleType
    input Type ty;
    output Type outTy;
  algorithm
    outTy := match ty
      case TUPLE() then listHead(ty.types);
      case ARRAY() then Type.ARRAY(firstTupleType(ty.elementType), ty.dimensions);
      else ty;
    end match;
  end firstTupleType;

  function nthTupleType
    input Type ty;
    input Integer n;
    output Type outTy;
  algorithm
    outTy := match ty
      case TUPLE() then listGet(ty.types, n);
      case ARRAY() then Type.ARRAY(nthTupleType(ty.elementType, n), ty.dimensions);
      else ty;
    end match;
  end nthTupleType;

  function arrayElementType
    "Returns the common type of the elements in an array, or just the type
     itself if it's not an array type."
    input Type ty;
    output Type elementTy;
  algorithm
    elementTy := match ty
      case ARRAY() then ty.elementType;
      case CONDITIONAL_ARRAY() then arrayElementType(ty.trueType);
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
      case ARRAY() then liftArrayLeftList(elementTy, arrayTy.dimensions);
      case CONDITIONAL_ARRAY()
        then CONDITIONAL_ARRAY(setArrayElementType(arrayTy.trueType, elementTy),
                               setArrayElementType(arrayTy.falseType, elementTy),
                               arrayTy.matchedBranch);
      else elementTy;
    end match;
  end setArrayElementType;

  function elementType
    input Type ty;
    output Type elementTy;
  algorithm
    elementTy := match ty
      case ARRAY() then ty.elementType;
      case CONDITIONAL_ARRAY() then elementType(ty.trueType);
      case FUNCTION() then elementType(Function.returnType(ty.fn));
      else ty;
    end match;
  end elementType;

  function copyElementType
    "Sets the element type of the destination type to the element type of the
     source type."
    input Type dstType;
    input Type srcType;
    output Type ty;
  algorithm
    ty := setArrayElementType(dstType, arrayElementType(srcType));
  end copyElementType;

  function arrayDims
    input Type ty;
    output list<Dimension> dims;
  algorithm
    dims := match ty
      case ARRAY() then ty.dimensions;
      case FUNCTION() then arrayDims(Function.returnType(ty.fn));
      case METABOXED() then arrayDims(ty.ty);
      case CONDITIONAL_ARRAY() then List.fill(Dimension.UNKNOWN(), dimensionCount(ty.trueType));
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
    if listEmpty(arrayDims(srcType)) then
      ty := arrayElementType(dstType);
    else
      ty := match dstType
        case ARRAY()
          then ARRAY(dstType.elementType, arrayDims(srcType));

        else ARRAY(dstType, arrayDims(srcType));
      end match;
    end if;
  end copyDims;

  function nthDimension
    input Type ty;
    input Integer index;
    output Dimension dim;
  algorithm
    dim := match ty
      case ARRAY() then listGet(ty.dimensions, index);
      case FUNCTION() then nthDimension(Function.returnType(ty.fn), index);
      case METABOXED() then nthDimension(ty.ty, index);
    end match;
  end nthDimension;

  function dimensionCount
    input Type ty;
    output Integer dimCount;
  algorithm
    dimCount := match ty
      case ARRAY() then listLength(ty.dimensions);
      case CONDITIONAL_ARRAY() then dimensionCount(ty.trueType);
      case FUNCTION() then dimensionCount(Function.returnType(ty.fn));
      case METABOXED() then dimensionCount(ty.ty);
      else 0;
    end match;
  end dimensionCount;

  function dimensionDiff
    input Type ty1;
    input Type ty2;
    output Integer diff = dimensionCount(ty1) - dimensionCount(ty2);
  end dimensionDiff;

  function hasKnownSize
    input Type ty;
    output Boolean isKnown;
  algorithm
    isKnown := match ty
      case ARRAY() then List.all(ty.dimensions, function Dimension.isKnown(allowExp = false));
      case CONDITIONAL_ARRAY() then false;
      case FUNCTION() then hasKnownSize(Function.returnType(ty.fn));
      else true;
    end match;
  end hasKnownSize;

  function hasZeroDimension
    input Type ty;
    output Boolean hasZero;
  algorithm
    hasZero := match ty
      case ARRAY() then List.exist(ty.dimensions, Dimension.isZero);
      case CONDITIONAL_ARRAY() then hasZeroDimension(ty.trueType) and hasZeroDimension(ty.falseType);
      else false;
    end match;
  end hasZeroDimension;

  function mapDims
    input output Type ty;
    input FuncT func;

    partial function FuncT
      input output Dimension dim;
    end FuncT;
  algorithm
    () := match ty
      local
        Function fn;

      case ARRAY()
        algorithm
          ty.dimensions := list(func(d) for d in ty.dimensions);
        then
          ();

      case TUPLE()
        algorithm
          ty.types := list(mapDims(t, func) for t in ty.types);
        then
          ();

      case FUNCTION(fn = fn)
        algorithm
          ty.fn := Function.setReturnType(mapDims(Function.returnType(fn), func), fn);
        then
          ();

      case METABOXED()
        algorithm
          ty.ty := mapDims(ty.ty, func);
        then
          ();

      case CONDITIONAL_ARRAY()
        algorithm
          ty.trueType := mapDims(ty.trueType, func);
          ty.falseType := mapDims(ty.falseType, func);
        then
          ();

      else ();
    end match;
  end mapDims;

  function foldDims<ArgT>
    input Type ty;
    input FuncT func;
    input output ArgT arg;

    partial function FuncT
      input Dimension dim;
      input output ArgT arg;
    end FuncT;
  algorithm
    arg := match ty
      case ARRAY() then List.fold(ty.dimensions, func, arg);
      case TUPLE() then List.fold(ty.types, function foldDims(func = func), arg);
      case FUNCTION() then foldDims(Function.returnType(ty.fn), func, arg);
      case METABOXED() then foldDims(ty.ty, func, arg);
      else arg;
    end match;
  end foldDims;

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
      case Type.ENUMERATION() then "enumeration " + AbsynUtil.pathString(ty.typePath) +
        "(" + stringDelimitList(ty.literals, ", ") + ")";
      case Type.ENUMERATION_ANY() then "enumeration(:)";
      case Type.ARRAY() then toString(ty.elementType) + "[" + stringDelimitList(List.map(ty.dimensions, Dimension.toString), ", ") + "]";
      case Type.TUPLE() then "(" + stringDelimitList(List.map(ty.types, toString), ", ") + ")";
      case Type.NORETCALL() then "()";
      case Type.UNKNOWN() then "unknown()";
      case Type.COMPLEX() then AbsynUtil.pathString(InstNode.scopePath(ty.cls));
      case Type.FUNCTION() then Function.typeString(ty.fn);
      case Type.METABOXED() then "#" + toString(ty.ty);
      case Type.POLYMORPHIC()
        then if Util.stringStartsWith("__", ty.name) then
          substring(ty.name, 3, stringLength(ty.name)) else "<" + ty.name + ">";

      case Type.ANY() then "$ANY$";
      case Type.CONDITIONAL_ARRAY() then toString(ty.trueType) + "|" + toString(ty.falseType);
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown type: " + anyString(ty), sourceInfo());
        then
          fail();
    end match;
  end toString;

  function toFlatString
    input Type ty;
    output String str;
  algorithm
    str := match ty
      case Type.INTEGER() then "Integer";
      case Type.REAL() then "Real";
      case Type.STRING() then "String";
      case Type.BOOLEAN() then "Boolean";
      case Type.CLOCK() then "Clock";
      case Type.ENUMERATION() then Util.makeQuotedIdentifier(AbsynUtil.pathString(ty.typePath));
      case Type.ENUMERATION_ANY() then "enumeration(:)";
      case Type.ARRAY() then toFlatString(ty.elementType) + "[" + stringDelimitList(List.map(ty.dimensions, Dimension.toFlatString), ", ") + "]";
      case Type.TUPLE() then "(" + stringDelimitList(List.map(ty.types, toFlatString), ", ") + ")";
      case Type.NORETCALL() then "()";
      case Type.UNKNOWN() then "unknown()";
      case Type.COMPLEX() then Util.makeQuotedIdentifier(AbsynUtil.pathString(InstNode.scopePath(ty.cls)));
      case Type.FUNCTION() then Function.typeString(ty.fn);
      case Type.METABOXED() then "#" + toFlatString(ty.ty);
      case Type.POLYMORPHIC() then "<" + ty.name + ">";
      case Type.ANY() then "$ANY$";
      case Type.CONDITIONAL_ARRAY() then toFlatString(ty.trueType) + "|" + toFlatString(ty.falseType);
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown type: " + anyString(ty), sourceInfo());
        then
          fail();
    end match;
  end toFlatString;

  function dimensionsToFlatString
    input Type ty;
    output String str;
  algorithm
    str := match ty
      case Type.ARRAY() then stringDelimitList(List.map(ty.dimensions, Dimension.toFlatString), ", ");
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown or not array type: " + anyString(ty), sourceInfo());
        then
          fail();
    end match;
  end dimensionsToFlatString;

  function toFlatDeclarationStream
    input Type ty;
    input output IOStream.IOStream s;
  algorithm
    s := match ty
      local
        Integer index;
        String name;
        ComplexType complexTy;
        Absyn.Path path;
        InstNode constructor, destructor;
        Function f;

      case ENUMERATION()
        algorithm
          s := IOStream.append(s, "type ");
          s := IOStream.append(s, Util.makeQuotedIdentifier(AbsynUtil.pathString(ty.typePath)));
          s := IOStream.append(s, " = enumeration(");

          if not listEmpty(ty.literals) then
            s := IOStream.append(s, listHead(ty.literals));

            for l in listRest(ty.literals) loop
              s := IOStream.append(s, ", ");
              s := IOStream.append(s, l);
            end for;
          end if;

          s := IOStream.append(s, ")");
        then
          s;

      case COMPLEX(complexTy = ComplexType.RECORD())
        then InstNode.toFlatStream(ty.cls, s);

      case COMPLEX(complexTy = complexTy as ComplexType.EXTERNAL_OBJECT())
        algorithm
          path := InstNode.scopePath(ty.cls);
          name := Util.makeQuotedIdentifier(AbsynUtil.pathString(path));
          s := IOStream.append(s, "class ");
          s := IOStream.append(s, name);
          s := IOStream.append(s, "\n  extends ExternalObject;\n\n");
          {f} := Function.typeNodeCache(complexTy.constructor);
          s := Function.toFlatStream(f, s, overrideName="constructor");
          s := IOStream.append(s, ";\n\n");
          {f} := Function.typeNodeCache(complexTy.destructor);
          s := Function.toFlatStream(f, s, overrideName="destructor");
          s := IOStream.append(s, ";\n\nend ");
          s := IOStream.append(s, name);
        then s;

      case SUBSCRIPTED()
        algorithm
          s := IOStream.append(s, "function ");
          s := IOStream.append(s, Util.makeQuotedIdentifier(ty.name));
          s := IOStream.append(s, "\n");

          s := IOStream.append(s, "  input ");
          s := IOStream.append(s, toString(ty.ty));
          s := IOStream.append(s, " exp;\n");

          index := 1;
          for sub in ty.subs loop
            s := IOStream.append(s, "  input ");
            s := IOStream.append(s, toString(sub));
            s := IOStream.append(s, " s");
            s := IOStream.append(s, String(index));
            s := IOStream.append(s, ";\n");
            index := index + 1;
          end for;

          s := IOStream.append(s, "  output ");
          s := IOStream.append(s, toString(ty.subscriptedTy));
          s := IOStream.append(s, " result = exp[");
          s := IOStream.append(s,
            stringDelimitList(list("s" + String(i) for i in 1:listLength(ty.subs)), ","));
          s := IOStream.append(s, "];\n");

          s := IOStream.append(s, "end ");
          s := IOStream.append(s, Util.makeQuotedIdentifier(ty.name));
        then
          s;

      else s;
    end match;
  end toFlatDeclarationStream;

  function typenameString
    input Type ty;
    output String str;
  algorithm
    str := match ty
      case Type.ENUMERATION() then AbsynUtil.pathString(ty.typePath);
      else toString(ty);
    end match;
  end typenameString;

  function toDAE
    input Type ty;
    input Boolean makeTypeVars = true;
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
        then DAE.T_ARRAY(toDAE(ty.elementType, makeTypeVars),
          list(Dimension.toDAE(d) for d in ty.dimensions));
      case Type.TUPLE()
        then DAE.T_TUPLE(list(toDAE(t) for t in ty.types), ty.names);
      case Type.FUNCTION()
        then match ty.fnType
          case FunctionType.FUNCTIONAL_PARAMETER
            then Function.makeDAEType(ty.fn);
          case FunctionType.FUNCTION_REFERENCE
            then DAE.T_FUNCTION_REFERENCE_FUNC(Function.isBuiltin(ty.fn), Function.makeDAEType(ty.fn));
          case FunctionType.FUNCTIONAL_VARIABLE
            then DAE.T_FUNCTION_REFERENCE_VAR(Function.makeDAEType(ty.fn, true));
        end match;
      case Type.NORETCALL() then DAE.T_NORETCALL_DEFAULT;
      case Type.UNKNOWN() then DAE.T_UNKNOWN_DEFAULT;
      case Type.COMPLEX()
        then if makeTypeVars then InstNode.toFullDAEType(ty.cls) else InstNode.toPartialDAEType(ty.cls);
      case Type.METABOXED() then DAE.T_METABOXED(toDAE(ty.ty));
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
    input Boolean failOnError = true;
  protected
    Dimension dim;
    list<Dimension> dims, subbed_dims = {};
    Type el_ty;
  algorithm
    if listEmpty(subs) then
      return;
    end if;

    ty := match ty
      case ARRAY(dimensions = dims)
        algorithm
          for sub in subs loop
            dim :: dims := dims;

            subbed_dims := match sub
              case Subscript.INDEX() then subbed_dims;
              case Subscript.SLICE() then Subscript.toDimension(sub) :: subbed_dims;
              case Subscript.WHOLE() then dim :: subbed_dims;
              case Subscript.SPLIT_INDEX() then subbed_dims;
            end match;
          end for;

          el_ty := arrayElementType(ty);
        then
          if not (listEmpty(subbed_dims) and listEmpty(dims)) then
            ARRAY(el_ty, listAppend(listReverse(subbed_dims), dims))
          else
            el_ty;

      case CONDITIONAL_ARRAY()
        then CONDITIONAL_ARRAY(subscript(ty.trueType, subs),
                               subscript(ty.falseType, subs),
                               ty.matchedBranch);

      case METABOXED() then METABOXED(subscript(ty.ty, subs));
      case UNKNOWN() then ty;

      else
        algorithm
          if failOnError then
            Error.assertion(false, getInstanceName() +
              " got unsubscriptable type " + toString(ty) + "\n", sourceInfo());
            fail();
          end if;
        then
          Type.UNKNOWN();

    end match;
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

      case (CONDITIONAL_ARRAY(), CONDITIONAL_ARRAY())
        then isEqual(ty1.trueType, ty2.trueType) and isEqual(ty1.falseType, ty2.falseType);

      case (TUPLE(names = SOME(names1)), TUPLE(names = SOME(names2)))
        then List.isEqualOnTrue(names1, names2, stringEq) and
             List.isEqualOnTrue(ty1.types, ty2.types, isEqual);

      case (TUPLE(names = NONE()), TUPLE(names = NONE()))
        then List.isEqualOnTrue(ty1.types, ty2.types, isEqual);

      case (TUPLE(), TUPLE()) then false;
      case (COMPLEX(), COMPLEX()) then InstNode.isSame(ty1.cls, ty2.cls);
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
      case CONDITIONAL_ARRAY() then isDiscrete(ty.trueType);
      case FUNCTION() then isDiscrete(Function.returnType(ty.fn));
      else false;
    end match;
  end isDiscrete;

  function lookupRecordFieldType
    input String name;
    input Type recordType;
    output Type fieldType;
  algorithm
    fieldType := match recordType
      case COMPLEX()
        then InstNode.getType(Class.lookupElement(name, InstNode.getClass(recordType.cls)));
      case ARRAY()
        then liftArrayLeftList(lookupRecordFieldType(name, recordType.elementType), recordType.dimensions);
      case CONDITIONAL_ARRAY()
        then CONDITIONAL_ARRAY(lookupRecordFieldType(name, recordType.trueType),
                               lookupRecordFieldType(name, recordType.falseType),
                               recordType.matchedBranch);
    end match;
  end lookupRecordFieldType;

  function recordFields
    input Type recordType;
    output list<Record.Field> fields;
  algorithm
    fields := match recordType
      case COMPLEX(complexTy = ComplexType.RECORD(fields = fields)) then fields;
      else {};
    end match;
  end recordFields;

  function setRecordFields
    input list<Record.Field> fields;
    input output Type recordType;
  algorithm
    recordType := match recordType
      local
        InstNode rec_node;

      case COMPLEX(complexTy = ComplexType.RECORD(constructor = rec_node))
        then COMPLEX(recordType.cls, ComplexType.RECORD(rec_node, fields));

      else recordType;
    end match;
  end setRecordFields;

  function enumName
    input Type ty;
    output Absyn.Path name;
  algorithm
    ENUMERATION(typePath = name) := ty;
  end enumName;

  function enumSize
    input Type ty;
    output Integer size;
  protected
    list<String> literals;
  algorithm
    ENUMERATION(literals = literals) := ty;
    size := listLength(literals);
  end enumSize;

  function box
    input Type ty;
    output Type boxedType;
  algorithm
    boxedType := match ty
      case STRING() then ty;
      case TUPLE() then TUPLE(list(box(t) for t in ty.types), ty.names);
      case FUNCTION() then ty;
      case METABOXED() then ty;
      case POLYMORPHIC() then ty;
      case ANY() then ty;
      case CONDITIONAL_ARRAY()
        then CONDITIONAL_ARRAY(box(ty.trueType), box(ty.falseType), ty.matchedBranch);
      else METABOXED(ty);
    end match;
  end box;

  function unbox
    input Type ty;
    output Type unboxedType;
  algorithm
    unboxedType := match ty
      case METABOXED() then ty.ty;
      else ty;
    end match;
  end unbox;

  function isBoxed
    input Type ty;
    output Boolean isBoxed;
  algorithm
    isBoxed := match ty
      case METABOXED() then true;
      else false;
    end match;
  end isBoxed;

  function sizeType
    input Type arrayTy;
    output Type sizeTy;
  algorithm
    if Type.isUnknown(arrayTy) then
      // Return unknown type if the type is unknown, to avoid returning Array[0]
      // for untyped expressions.
      sizeTy := Type.UNKNOWN();
    else
      sizeTy := Type.ARRAY(Type.INTEGER(), {Dimension.fromInteger(dimensionCount(arrayTy))});
    end if;
  end sizeType;

  function subscriptedTypeName
    input Type expType;
    input list<Type> subscriptTypes;
    output String str;
  protected
    list<String> strl;
  algorithm
    strl := list(toString(t) for t in subscriptTypes);
    strl := "_" :: strl;
    strl := toString(expType) :: strl;
    strl := "subscript" :: strl;
    str := stringAppendList(strl);
  end subscriptedTypeName;

  function simplify
    input output Type ty;
  algorithm
    () := match ty
      case ARRAY()
        algorithm
          ty.dimensions := list(Dimension.simplify(d) for d in ty.dimensions);
        then
          ();

      else ();
    end match;
  end simplify;

  function sizeOf
    input Type ty;
    output Integer sz;

    function fold_comp_size
      input InstNode comp;
      input Integer sz;
      output Integer outSize = sz + sizeOf(InstNode.getType(comp));
    end fold_comp_size;
  algorithm
    sz := match ty
      case INTEGER() then 1;
      case REAL() then 1;
      case STRING() then 1;
      case BOOLEAN() then 1;
      case CLOCK() then 1;
      case ENUMERATION() then 1;
      case ARRAY() then sizeOf(ty.elementType) * product(Dimension.size(d) for d in ty.dimensions);
      case TUPLE() then List.fold(list(sizeOf(t) for t in ty.types), intAdd, 0);
      case COMPLEX()
        then ClassTree.foldComponents(Class.classTree(InstNode.getClass(ty.cls)), fold_comp_size, 0);
      else 0;
    end match;
  end sizeOf;

  annotation(__OpenModelica_Interface="frontend");
end NFType;
