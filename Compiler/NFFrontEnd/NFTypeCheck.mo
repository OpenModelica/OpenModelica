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

encapsulated package NFTypeCheck
" file:        NFTypeCheck.mo
  package:     NFTypeCheck
  description: SCodeInst type checking.


  Functions used by SCodeInst for type checking and type conversion where needed.
"

import DAE;
import Dimension = NFDimension;
import Expression = NFExpression;
import NFInstNode.InstNode;
import NFBinding.Binding;
import NFPrefixes.Variability;

protected
import Debug;
import DAEExpression = Expression;
import Error;
import ExpressionDump;
import List;
import Types;
import Operator = NFOperator;
import Type = NFType;
import Class = NFClass.Class;
import ClassTree = NFClassTree;
import InstUtil = NFInstUtil;
import DAEUtil;
import Prefixes = NFPrefixes;
import Restriction = NFRestriction;
import ComplexType = NFComplexType;

public
type MatchKind = enumeration(
  EXACT "Exact match",
  CAST  "Matched by casting, e.g. Integer to real",
  UNKNOWN_EXPECTED "The expected type was unknown",
  UNKNOWN_ACTUAL   "The actual type was unknown",
  GENERIC "Matched with a generic type e.g. function F<T> input T i; end F; F(1)",
  NOT_COMPATIBLE
);

function isCompatibleMatch
  input MatchKind kind;
  output Boolean isCompatible = kind <> MatchKind.NOT_COMPATIBLE;
end isCompatibleMatch;

function isIncompatibleMatch
  input MatchKind kind;
  output Boolean isIncompatible = kind == MatchKind.NOT_COMPATIBLE;
end isIncompatibleMatch;

function isCastMatch
  input MatchKind kind;
  output Boolean isCast = kind == MatchKind.CAST;
end isCastMatch;

//
//
//public function checkClassComponents
//  input Class inClass;
//  input Context inContext;
//  input SymbolTable inSymbolTable;
//  output Class outClass;
//  output SymbolTable outSymbolTable;
//algorithm
//  (outClass, outSymbolTable) :=
//    checkClass(inClass, NONE(), inContext, inSymbolTable);
//end checkClassComponents;
//
//public function checkClass
//  input Class inClass;
//  input Option<Component> inParent;
//  input Context inContext;
//  input SymbolTable inSymbolTable;
//  output Class outClass;
//  output SymbolTable outSymbolTable;
//algorithm
//  (outClass, outSymbolTable) := match(inClass, inParent, inContext, inSymbolTable)
//    local
//      list<Element> comps;
//      list<Equation> eq, ieq;
//      list<list<Statement>> al, ial;
//      SymbolTable st;
//      Absyn.Path name;
//
//    case (NFInstTypes.BASIC_TYPE(_), _, _, st) then (inClass, st);
//
//    case (NFInstTypes.COMPLEX_CLASS(name, comps, eq, ieq, al, ial), _, _, st)
//      equation
//        (comps, st) = List.map2Fold(comps, checkElement, inParent, inContext, st);
//      then
//        (NFInstTypes.COMPLEX_CLASS(name, comps, eq, ieq, al, ial), st);
//
//  end match;
//end checkClass;
//
//protected function checkElement
//  input Element inElement;
//  input Option<Component> inParent;
//  input Context inContext;
//  input SymbolTable inSymbolTable;
//  output Element outElement;
//  output SymbolTable outSymbolTable;
//algorithm
//  (outElement, outSymbolTable) :=
//  match(inElement, inParent, inContext, inSymbolTable)
//    local
//      Component comp;
//      Class cls;
//      Absyn.Path name;
//      SymbolTable st;
//      SourceInfo info;
//      String str;
//
//    case (NFInstTypes.ELEMENT(NFInstTypes.UNTYPED_COMPONENT(name = name, info = info), _),
//        _, _, _)
//      equation
//        str = "Found untyped component: " + Absyn.pathString(name);
//        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, info);
//      then
//        fail();
//
//    case (NFInstTypes.ELEMENT(comp, cls), _, _, st)
//      equation
//        (comp, st)= checkComponent(comp, inParent, inContext, st);
//        (cls, st) = checkClass(cls, SOME(comp), inContext, st);
//      then
//        (NFInstTypes.ELEMENT(comp, cls), st);
//
//    case (NFInstTypes.CONDITIONAL_ELEMENT(_), _, _, _)
//      then (inElement, inSymbolTable);
//
//  end match;
//end checkElement;
//
//protected function checkComponent
//  input Component inComponent;
//  input Option<Component> inParent;
//  input Context inContext;
//  input SymbolTable inSymbolTable;
//  output Component outComponent;
//  output SymbolTable outSymbolTable;
//algorithm
//  (outComponent, outSymbolTable) :=
//  match(inComponent, inParent, inContext, inSymbolTable)
//    local
//      Absyn.Path name;
//      Type ty;
//      Binding binding;
//      SymbolTable st;
//      Component comp, inner_comp;
//      Context c;
//      String str;
//      SourceInfo info;
//
//    case (NFInstTypes.UNTYPED_COMPONENT(name = name,  info = info),
//        _, _, _)
//      equation
//        str = "Found untyped component: " + Absyn.pathString(name);
//        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, info);
//      then
//        fail();
//
//    // check and convert if needed the type of
//    // the binding vs the type of the component
//    case (NFInstTypes.TYPED_COMPONENT(), _, _, st)
//      equation
//        comp = NFInstUtil.setComponentParent(inComponent, inParent);
//        comp = checkComponentBindingType(comp);
//      then
//        (comp, st);
//
//    case (NFInstTypes.OUTER_COMPONENT(innerName = SOME(name)), _, _, st)
//      equation
//        comp = NFInstSymbolTable.lookupName(name, st);
//        (comp, st) = checkComponent(comp, inParent, inContext, st);
//      then
//        (comp, st);
//
//    case (NFInstTypes.OUTER_COMPONENT( innerName = NONE()), _, _, st)
//      equation
//        (_, SOME(inner_comp), st) = NFInstSymbolTable.updateInnerReference(inComponent, st);
//        (inner_comp, st) = checkComponent(inner_comp, inParent, inContext, st);
//      then
//        (inner_comp, st);
//
//    case (NFInstTypes.CONDITIONAL_COMPONENT(name = name), _, _, _)
//      equation
//        print("Trying to type conditional component " + Absyn.pathString(name) + "\n");
//      then
//        fail();
//
//    case (NFInstTypes.DELETED_COMPONENT(), _, _, st)
//      then (inComponent, st);
//
//  end match;
//end checkComponent;
//
//protected function checkComponentBindingType
//  input Component inC;
//  output Component outC;
//algorithm
//  outC := matchcontinue (inC)
//    local
//      Type ty, propagatedTy, convertedTy;
//      Absyn.Path name, eName;
//      Option<Component> parent;
//      DaePrefixes prefixes;
//      Binding binding;
//      SourceInfo info;
//      Expression bindingExp;
//      Type bindingType;
//      Integer propagatedDims "See NFSCodeMod.propagateMod.";
//      SourceInfo binfo;
//      String nStr, eStr, etStr, btStr;
//      DAE.Dimensions parentDimensions;
//
//    // nothing to check
//    case (NFInstTypes.TYPED_COMPONENT(binding = NFInstTypes.UNBOUND()))
//      then
//        inC;
//
//    // when the component name is equal to the component type we have a constant enumeration!
//    // StateSelect = {StateSelect.always, StateSelect.prefer, StateSelect.default, StateSelect.avoid, StateSelect.never}
//    case (NFInstTypes.TYPED_COMPONENT(name = name, ty = DAE.T_ENUMERATION(path = eName)))
//      equation
//        true = Absyn.pathEqual(name, eName);
//      then
//        inC;
//
//    case (NFInstTypes.TYPED_COMPONENT(name, ty, parent, prefixes, binding, info))
//      equation
//        NFInstTypes.TYPED_BINDING(bindingExp, bindingType, propagatedDims, binfo) = binding;
//        parentDimensions = getParentDimensions(parent, {});
//        propagatedTy = liftArray(ty, parentDimensions, propagatedDims);
//        (bindingExp, convertedTy) = Types.matchType(bindingExp, bindingType, propagatedTy, true);
//        binding = NFInstTypes.TYPED_BINDING(bindingExp, convertedTy, propagatedDims, binfo);
//      then
//        NFInstTypes.TYPED_COMPONENT(name, ty, parent, prefixes, binding, info);
//
//    case (NFInstTypes.TYPED_COMPONENT(name, ty, parent, _, binding, info))
//      equation
//        NFInstTypes.TYPED_BINDING(bindingExp, bindingType, propagatedDims, _) = binding;
//        parentDimensions = getParentDimensions(parent, {});
//        propagatedTy = liftArray(ty, parentDimensions, propagatedDims);
//        failure((_, _) = Types.matchType(bindingExp, bindingType, propagatedTy, true));
//        nStr = Absyn.pathString(name);
//        eStr = ExpressionDump.printExpStr(bindingExp);
//        etStr = Types.unparseTypeNoAttr(propagatedTy);
//        etStr = etStr + " propDim: " + intString(propagatedDims);
//        btStr = Types.unparseTypeNoAttr(bindingType);
//        Error.addSourceMessage(Error.VARIABLE_BINDING_TYPE_MISMATCH,
//        {nStr, eStr, etStr, btStr}, info);
//      then
//        fail();
//
//    else
//      equation
//        //name = NFInstUtil.getComponentName(inC);
//        //nStr = "Found untyped component: " + Absyn.pathString(name);
//        //Error.addMessage(Error.INTERNAL_ERROR, {nStr});
//      then
//        fail();
//
//  end matchcontinue;
//end checkComponentBindingType;
//
//protected function getParentDimensions
//"get the dimensions from the parents of the component up to the root"
//  input Option<Component> inParentOpt;
//  input DAE.Dimensions inDimensionsAcc;
//  output DAE.Dimensions outDimensions;
//algorithm
//  outDimensions := matchcontinue(inParentOpt, inDimensionsAcc)
//    local
//      Component c;
//      DAE.Dimensions dims;
//
//    case (NONE(), _) then inDimensionsAcc;
//
//    case (SOME(c), _)
//      equation
//        dims = NFInstUtil.getComponentTypeDimensions(c);
//        dims = listAppend(dims, inDimensionsAcc);
//        dims = getParentDimensions(NFInstUtil.getComponentParent(c), dims);
//      then
//        dims;
//    // for other...
//    case (SOME(_), _) then inDimensionsAcc;
//  end matchcontinue;
//end getParentDimensions;
//
// ************************************************************** //
//   BEGIN: Operator typing helper functions
// ************************************************************** //


function checkLogicalBinaryOperation
  "mahge:
  Type checks logical binary operations. operations on scalars are handled
  simply by using Types.matchType().
  Operations involving Complex types are handled differently."
  input Expression exp1;
  input Type type1;
  input Operator operator;
  input Expression exp2;
  input Type type2;
  output Expression exp;
  output Type ty;
protected
  Expression e1, e2;
  Operator op;
  //TypeSource ty_src;
  String e1_str, e2_str, ty1_str, ty2_str, msg_str, op_str, s1, s2;
  MatchKind ty_match;
algorithm
  try
    true := Type.isBoolean(type1) and Type.isBoolean(type2);

    // Logical binary operations here are allowed only on Booleans.
    // The Modelica Specification 3.2 doesn't say anything if they should be
    // allowed or not on scalars of type Integers/Reals.
    // It says no for arrays of Integer/Real type.
    (e1, e2, ty, ty_match) := matchExpressions(exp1, type1, exp2, type2);
    true := isCompatibleMatch(ty_match);
    op := Operator.setType(ty, operator);

    exp := Expression.LBINARY(e1, op, e2);
  else
    e1_str := Expression.toString(exp1);
    e2_str := Expression.toString(exp2);
    ty1_str := Type.toString(type1);
    ty2_str := Type.toString(type2);
    op_str := Operator.symbol(operator);

    // Check if we have relational operations involving array types.
    // Just for proper error messages.
    msg_str := if not (Type.isBoolean(type1) or Type.isBoolean(type2)) then
      "\n: Logical operations involving non-Boolean types are not valid in Modelica." else ty1_str;

    s1 := "' " + e1_str + op_str + e2_str + " '";
    s2 := "' " + ty1_str + op_str + ty2_str + " '";

    Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1, s2, msg_str}, Absyn.dummyInfo);
    fail();
  end try;
end checkLogicalBinaryOperation;

public function checkLogicalUnaryOperation
  "petfr:
  Typechecks logical unary operations, i.e. the not operator"
  input Expression exp1;
  input Type type1;
  input Operator operator;
  output Expression exp;
  output Type ty;
protected
  Expression e1;
  Operator op;
  //TypeSource ty_src;
  String e1_str, ty1_str, msg_str, op_str, s1;
algorithm
  try
    true := Type.isBoolean(type1);
    // Logical unary operations here are allowed only on Booleans.
    ty := type1;
    op := Operator.setType(ty, operator);
    exp := Expression.LUNARY(op, exp1);

  else
    e1_str := Expression.toString(exp1);
    ty1_str := Type.toString(type1);
    op_str := Operator.symbol(operator);

    // Just for proper error messages.
    msg_str := if not (Type.isBoolean(type1)) then
      "\n: Logical operations involving non-Boolean types are not valid in Modelica." else ty1_str;

    s1 := "' " + e1_str + op_str  + " '";

    Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1, msg_str}, Absyn.dummyInfo);
    fail();
  end try;
end checkLogicalUnaryOperation;

public function checkRelationOperation
  "mahge:
  Type checks relational operations. Relations on scalars are handled
  simply by using Types.matchType(). This way conversions from Integer to real
  are handled internaly."
  input Expression exp1;
  input Type type1;
  input Operator operator;
  input Expression exp2;
  input Type type2;
  output Expression exp;
  output Type ty;
protected
  Expression e1, e2;
  Operator op;
  //TypeSource ty_src;
  String e1_str, e2_str, ty1_str, ty2_str, msg_str, op_str, s1, s2;
  MatchKind ty_match;
algorithm
  try
    true := Type.isScalarBuiltin(type1) and Type.isScalarBuiltin(type2);

    // Check types match/can be converted to match.
    (e1, e2, ty, ty_match) := matchExpressions(exp1, type1, exp2, type2);
    true := isCompatibleMatch(ty_match);
    //ty_src := Types.getTypeSource(ty);
    //ty := DAE.T_BOOL({}, ty_src);
    ty := Type.BOOLEAN();
    op := Operator.setType(ty, operator);

    exp := Expression.RELATION(e1, op, e2);
  else
    e1_str := Expression.toString(exp1);
    e2_str := Expression.toString(exp2);
    ty1_str := Type.toString(type1);
    ty2_str := Type.toString(type2);
    op_str := Operator.symbol(operator);

    // Check if we have relational operations involving array types.
    // Just for proper error messages.
    msg_str := if Type.isArray(type1) or Type.isArray(type2) then
      "\n: Relational operations involving array types are not valid in Modelica." else ty1_str;

    s1 := "' " + e1_str + op_str + e2_str + " '";
    s2 := "' " + ty1_str + op_str + ty2_str + " '";

    Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1, s2, msg_str}, Absyn.dummyInfo);
    fail();
  end try;
end checkRelationOperation;

public function checkBinaryOperation
  "mahge:
  Type checks binary operations. operations on scalars are handled
  simply by using Types.matchType(). This way conversions from Integer to Real
  are handled internally.
  Operations involving arrays and Complex types are handled differently."
  input Expression exp1;
  input Type type1;
  input Operator operator;
  input Expression exp2;
  input Type type2;
  output Expression binaryExp;
  output Type binaryType;
protected
  Expression e1, e2;
  Operator op;
  //TypeSource ty_src;
  String e1_str, e2_str, ty1_str, ty2_str, s1, s2;
  MatchKind ty_match;
algorithm
  // All operators expect Numeric types except Addition.
  true := checkValidNumericTypesForOp(type1, type2, operator, true);

  try
    if Type.isScalarBuiltin(type1) and Type.isScalarBuiltin(type2) then
      // Binary expression with expression of simple type.

      (e1, e2, binaryType) := match operator
        // Addition operations on Scalars.
        // Check if the operands (match/can be converted to match) the other.
        case Operator.ADD()
          algorithm
            (e1, e2, binaryType, ty_match) := matchExpressions(exp1, type1, exp2, type2);
            true := isCompatibleMatch(ty_match);
          then
            (e1, e2, binaryType);

        case Operator.SUB()
          algorithm
            (e1, e2, binaryType, ty_match) := matchExpressions(exp1, type1, exp2, type2);
            true := isCompatibleMatch(ty_match);
          then
            (e1, e2, binaryType);

        case Operator.MUL()
          algorithm
            (e1, e2, binaryType, ty_match) := matchExpressions(exp1, type1, exp2, type2);
            true := isCompatibleMatch(ty_match);
          then
            (e1, e2, binaryType);

        // Check division operations.
        // They result in T_REAL regardless of the operand types.
        case Operator.DIV()
          algorithm
            (e1, e2, binaryType, ty_match) := matchExpressions(exp1, type1, exp2, type2);
            true := isCompatibleMatch(ty_match);

            //ty_src := Types.getTypeSource(type1);
          then
            (e1, e2, Type.REAL());

        // Check exponentiations.
        // They result in T_REAL regardless of the operand types.
        // According to spec operands should be promoted to real before expon.
        // to fit with ANSI C ???.
        case Operator.POW()
          algorithm
            // Try converting both to Real type.
            (e1, _, ty_match) := matchTypes(type1, Type.REAL(), exp1);
            true := isCompatibleMatch(ty_match);
            (e2, _, ty_match) := matchTypes(type2, Type.REAL(), exp2);
            true := isCompatibleMatch(ty_match);
            //ty_src := Types.getTypeSource(type1);
          then
            (e1, e2, Type.REAL());

      end match;

      op := Operator.setType(binaryType, operator);
      binaryExp := Expression.BINARY(e1, op, e2);
    else
      // Binary expression with expressions of array type.
      (binaryExp, binaryType) := checkBinaryOperationArrays(exp1, type1, operator, exp2, type2);
    end if;
  else
    e1_str := Expression.toString(exp1);
    e2_str := Expression.toString(exp2);
    ty1_str := Type.toString(type1);
    ty2_str := Type.toString(type2);
    s1 := "' " + e1_str + Operator.symbol(operator) + e2_str + " '";
    s2 := "' " + ty1_str + Operator.symbol(operator) + ty2_str + " '";
    Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1, s2, ty1_str}, Absyn.dummyInfo);
    fail();
  end try;
end checkBinaryOperation;

public function checkUnaryOperation
  "petfr:
  Type checks arithmetic unary operations. Both for simple scalar types and
  operations involving array types. Builds DAE unary node."
  input Expression exp1;
  input Type type1;
  input Operator operator;
  output Expression unaryExp;
  output Type unaryType;
protected
  Operator op;
  //TypeSource ty_src;
  String e1_str, ty1_str, s1;
algorithm
  try
    // Arithmetic type expected for Unary operators, i.e., UMINUS, UMINUS_ARR;  UPLUS removed
    true := Type.isNumeric(type1);

    unaryType := type1;
    op := Operator.setType(unaryType, operator);
    unaryExp := match op
              case Operator.ADD() then exp1; // If UNARY +, +exp1, remove it since no unary Operator.ADD
              else Expression.UNARY(op, exp1);
            end match;
  else
    e1_str := Expression.toString(exp1);
    ty1_str := Type.toString(type1);
    s1 := "' " + e1_str + Operator.symbol(operator) + " '" +
       " Arithmetic type expected for this unary operator ";
    Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1, ty1_str}, Absyn.dummyInfo);
    fail();
  end try;
end checkUnaryOperation;

public function checkBinaryOperationArrays
  "mahge:
  Type checks binary operations involving arrays. This involves more checks than
  scalar types. All normal operations as well as element wise operations involving
  arrays are handled here."
  input Expression inExp1;
  input Type inType1;
  input Operator inOp;
  input Expression inExp2;
  input Type inType2;
  output Expression outExp;
  output Type outType;
protected
  Boolean isArray1,isArray2, bothArrays;
  Integer nrDims1, nrDims2;
  MatchKind ty_match;
algorithm

  nrDims1 := Type.dimensionCount(inType1);
  nrDims2 := Type.dimensionCount(inType2);
  isArray1 := nrDims1 > 0;
  isArray2 := nrDims2 > 0;
  bothArrays := isArray1 and isArray2;

  (outExp, outType) := match inOp
    local
      Expression exp1,exp2;
      Type ty1,ty2, arrtp, ty;
      list<Dimension> dims;
      Dimension M,N1,N2,K;
      Operator newop;
      //TypeSource typsrc;

    case Operator.ADD()
      algorithm
        if (bothArrays) then
          (exp1,exp2,outType, ty_match) := matchExpressions(inExp1,inType1,inExp2,inType2);
          true := isCompatibleMatch(ty_match);
          outExp := Expression.BINARY(exp1, Operator.ADD(outType), exp2);
        else
          binaryArrayOpError(inExp1,inType1,inExp2,inType2,inOp,
            "\n: Addition operations involving an array and a scalar are " +
            "not valid in Modelica. Try using elementwise operator '.+'");
          fail();
        end if;
      then
        (outExp, outType);

    case Operator.SUB()
      algorithm
        if (bothArrays) then
          (exp1,exp2,outType, ty_match) := matchExpressions(inExp1,inType1,inExp2,inType2);
          true := isCompatibleMatch(ty_match);
          outExp := Expression.BINARY(exp1, Operator.SUB(outType), exp2);
        else
          binaryArrayOpError(inExp1,inType1,inExp2,inType2,inOp,
            "\n: Subtraction operations involving an array and a scalar are " +
            "not valid in Modelica. Try using elementwise operator '.+'");
          fail();
        end if;
      then
        (outExp, outType);

    case Operator.DIV()
      algorithm
        if (isArray1 and not isArray2) then
          dims := Type.arrayDims(inType1);
          arrtp := Type.liftArrayLeftList(inType2,dims);

          (exp1,exp2,_, ty_match) := matchExpressions(inExp1,inType1,inExp2,arrtp);
          true := isCompatibleMatch(ty_match);

          // Create a scalar Real Type and lift it to array.
          // Necessary because even if both operands are of Integer type the result
          // should be Real type with dimensions of the input array operand.
          //typsrc := Types.getTypeSource(ty1);
          ty := Type.REAL();

          outType := Type.liftArrayLeftList(ty,dims);
          outExp := Expression.BINARY(exp1, Operator.DIV_ARRAY_SCALAR(outType), exp2);
        else
          binaryArrayOpError(inExp1,inType1,inExp2,inType2,inOp,
            "\n: Dividing a sclar by array or array by array is not a valid " +
            "operation in Modelica. Try using elementwise operator './'");
          fail();
        end if;
      then
        (outExp, outType);

    case Operator.POW()
      algorithm
        if (nrDims1 == 2 and not isArray2) then
          {M, K} := Type.arrayDims(inType1);

          // Check if dims are equal. i.e Square Matrix
          if not(isValidMatrixMultiplyDims(M, K)) then
            binaryArrayOpError(inExp1,inType1,inExp2,inType2,inOp,
              "\n: Exponentiation involving arrays is only valid for square " +
              "matrices with integer exponents. Try using elementwise operator '.^'");
            fail();
          end if;

          if not Type.isInteger(inType2) then
            binaryArrayOpError(inExp1,inType1,inExp2,inType2,inOp,
              "\n: Exponentiation involving arrays is only valid for square " +
              "matrices with integer exponents. Try using elementwise operator '.^'");
            fail();
          end if;

          outType := inType1;
          outExp := Expression.BINARY(inExp1, Operator.POW_ARRAY_SCALAR(inType1), inExp2);
        else
          binaryArrayOpError(inExp1,inType1,inExp2,inType2,inOp,
            "\n: Exponentiation involving arrays is only valid for square " +
            "matrices with integer exponents. Try using elementwise operator '.^'");
          fail();
        end if;
      then
        (outExp, outType);


    case Operator.MUL()
      algorithm
        if (not isArray1 or not isArray2) then

          arrtp := if isArray1 then inType1 else inType2;
          dims := Type.arrayDims(arrtp);
          //match their scalar types. For now.
          ty1 := Type.elementType(inType1);
          ty2 := Type.elementType(inType2);
          // TODO: one of the exps is array but its type is now simple.
          (exp1,exp2,ty, ty_match) := matchExpressions(inExp1,ty1,inExp2,ty2);
          true := isCompatibleMatch(ty_match);

          outType := Type.liftArrayLeftList(ty,dims);
          outExp := Expression.BINARY(exp1, Operator.MUL_ARRAY_SCALAR(outType), exp2);

        elseif (nrDims1 == 1 and nrDims2 == 1) then
          {N1} := Type.arrayDims(inType1);
          {N2} := Type.arrayDims(inType2);
          if (not isValidMatrixMultiplyDims(N1,N2)) then
            binaryArrayOpError(inExp1,inType1,inExp2,inType2,inOp,
            "\n: Dimensions not equal for scalar product.");
            fail();
          else
            (exp1,exp2,ty, ty_match) := matchExpressions(inExp1,inType1,inExp2,inType2);
            true := isCompatibleMatch(ty_match);
            outType := Type.elementType(ty);
            outExp := Expression.BINARY(exp1, Operator.MUL_SCALAR_PRODUCT(outType), exp2);
          end if;

        elseif (nrDims1 == 2 and nrDims2 == 1) then
          {M,N1} := Type.arrayDims(inType1);
          {N2} := Type.arrayDims(inType2);
          if (not isValidMatrixMultiplyDims(N1,N2)) then
            binaryArrayOpError(inExp1,inType1,inExp2,inType2,inOp,
            "\n: Dimensions error in Matrix Vector multiplication.");
            fail();
          else
            ty1 := Type.elementType(inType1);
            ty2 := Type.elementType(inType2);
            // TODO: the exps are arrays but the types are now simple.
            (exp1,exp2,ty, ty_match) := matchExpressions(inExp1,ty1,inExp2,ty2);
            true := isCompatibleMatch(ty_match);
            outType := Type.liftArrayLeftList(ty, {M});
            outExp := Expression.BINARY(exp1, Operator.MUL_MATRIX_PRODUCT(outType), exp2);
          end if;

        elseif (nrDims1 == 1 and nrDims2 == 2) then

          {N1} := Type.arrayDims(inType1);
          {N2,M} := Type.arrayDims(inType2);
          if (not isValidMatrixMultiplyDims(N1,N2)) then
            binaryArrayOpError(inExp1,inType1,inExp2,inType2,inOp,
            "\n: Dimensions error in Vector Matrix multiplication.");
            fail();
          else
            ty1 := Type.elementType(inType1);
            ty2 := Type.elementType(inType2);
            // TODO: the exps are arrays but the types are now simple.
            (exp1,exp2,ty, ty_match) := matchExpressions(inExp1,ty1,inExp2,ty2);
            true := isCompatibleMatch(ty_match);
            outType := Type.liftArrayLeftList(ty, {M});
            outExp := Expression.BINARY(exp1, Operator.MUL_MATRIX_PRODUCT(outType), exp2);
          end if;

        elseif (nrDims1 == 2 and nrDims2 == 2) then

          {M,N1} := Type.arrayDims(inType1);
          {N2,K} := Type.arrayDims(inType2);
          if (not isValidMatrixMultiplyDims(N1,N2)) then
            binaryArrayOpError(inExp1,inType1,inExp2,inType2,inOp,
            "\n: Dimensions error in Matrix Matrix multiplication.");
            fail();
          else
            ty1 := Type.elementType(inType1);
            ty2 := Type.elementType(inType2);
            // TODO: the exps are arrays but the types are now simple.
            (exp1,exp2,ty, ty_match) := matchExpressions(inExp1,ty1,inExp2,ty2);
            true := isCompatibleMatch(ty_match);
            outType := Type.liftArrayLeftList(ty, {M,K});
            outExp := Expression.BINARY(exp1, Operator.MUL_MATRIX_PRODUCT(outType), exp2);
          end if;

        else
          binaryArrayOpError(inExp1,inType1,inExp2,inType2,inOp,"");
          fail();
        end if;

      then
        (outExp, outType);

    case _ guard Operator.isBinaryElementWise(inOp)
      algorithm
        (exp1,exp2,outType, ty_match) := matchExpressions(inExp1,inType1,inExp2,inType2);
        true := isCompatibleMatch(ty_match);
        newop := Operator.setType(outType, inOp);
        outExp := Expression.BINARY(exp1, newop, exp2);
      then
        (outExp, outType);

    else
      algorithm
        assert(false, getInstanceName() + ": got a binary operation that is not
            handled yet");
      then
        fail();
  end match;

end checkBinaryOperationArrays;


// ************************************************************** //
//   END: Operator typing helper functions
// ************************************************************** //





//// ************************************************************** //
////   BEGIN: TypeCall helper functions
//// ************************************************************** //
//
//
//public function matchCallArgs
//"@mahge:
//  matches given call args with the expected or formal arguments for a function.
//  if vectorization dimension (inVectDims) is given (is not empty) then the function
//  works with vectorization mode.
//  otherwise no vectorization will be done.
//
//  However if matching fails in no vect. mode due to dim mismatch then
//  a vect dim will be returned from  NFTypeCheck.matchCallArgs and this
//  function will start all over again with the new vect dimension."
//
//  input list<Expression> inArgs;
//  input list<Type> inArgTypes;
//  input list<Type> inExpectedTypes;
//  input DAE.Dimensions inVectDims;
//  output list<Expression> outFixedArgs;
//  output DAE.Dimensions outVectDims;
//algorithm
//  (outFixedArgs, outVectDims):=
//  matchcontinue (inArgs,inArgTypes,inExpectedTypes, inVectDims)
//    local
//      Expression e,e_1;
//      list<Expression> restargs, fixedArgs;
//      Type t1,t2;
//      list<Type> restinty,restexpcty;
//      DAE.Dimensions dims1, dims2;
//      String e1Str, t1Str, t2Str, s1;
//
//    case ({},{},{},_) then ({}, inVectDims);
//
//    // No vectorization mode.
//    // If things continue to match with no vect.
//    // Then all is good.
//    case (e::restargs, (t1 :: restinty), (t2 :: restexpcty), {})
//      equation
//        (e_1, {}) = matchCallArg(e,t1,t2,{});
//
//        (fixedArgs, {}) = matchCallArgs(restargs, restinty, restexpcty, {});
//      then
//        (e_1::fixedArgs, {});
//
//    // No vectorization mode.
//    // If argument failed to match not because of dim mismatch
//    // but due to actuall type mismatch then it is an invalid call and we fail here.
//    case (e::_, (t1 :: _), (t2 :: _), {})
//      equation
//        failure((_,_) = matchCallArg(e,t1,t2,{}));
//
//        e1Str = ExpressionDump.printExpStr(e);
//        t1Str = Types.unparseType(t1);
//        t2Str = Types.unparseType(t2);
//        s1 = "Failed to match or convert '" + e1Str + "' of type '" + t1Str +
//             "' to type '" + t2Str + "'";
//        Error.addSourceMessage(Error.INTERNAL_ERROR, {s1}, Absyn.dummyInfo);
//        true = Flags.isSet(Flags.FAILTRACE);
//        Debug.traceln("- NFTypeCheck.matchCallArgs failed with type mismatch: " + t1Str + " tys: " + t2Str);
//      then
//        fail();
//
//    // No -> Yes vectorization mode.
//    // If argument fails to match due to dim mistmatch. then we
//    // have our vect. dim and we start from the begining.
//    case (e::_, (t1 :: _), (t2 :: _), {})
//      equation
//        (_, dims1) = matchCallArg(e,t1,t2,{});
//
//        // This is just to be realllly sure. The cases above actually make sure of it.
//        false = Expression.dimsEqual(dims1, {});
//
//        // Start from the first arg. This time with Vectorization.
//        (fixedArgs, dims2) = matchCallArgs(inArgs,inArgTypes,inExpectedTypes, dims1);
//      then
//        (fixedArgs, dims2);
//
//    // Vectorization mode.
//    case (e::restargs, (t1 :: restinty), (t2 :: restexpcty), dims1)
//      equation
//        false = Expression.dimsEqual(dims1, {});
//        (e_1, dims1) = matchCallArg(e,t1,t2,dims1);
//        (fixedArgs, dims1) = matchCallArgs(restargs, restinty, restexpcty, dims1);
//      then
//        (e_1::fixedArgs, dims1);
//
//
//
//    case (_::_,(_ :: _),(_ :: _), _)
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        Debug.trace("- NFTypeCheck.matchCallArgs failed\n");
//      then
//        fail();
//  end matchcontinue;
//end matchCallArgs;
//
//
//public function matchCallArg
//"@mahge:
//  matches a given call arg with the expected or formal argument for a function.
//  if vectorization dimension (inVectDims) is given (is not empty) then the function
//  works with vectorization mode.
//  otherwise no vectorization will be done.
//
//  However if matching fails in no vect. mode due to dim mismatch then
//  it will try to see if vectoriztion is possible. If so the vectorization dim is
//  returned to NFTypeCheck.matchCallArg so that it can start matching from the begining
//  with the new vect dim."
//
//  input Expression inArg;
//  input Type inArgType;
//  input Type inExpectedType;
//  input DAE.Dimensions inVectDims;
//  output Expression outArg;
//  output DAE.Dimensions outVectDims;
//algorithm
//  (outArg, outVectDims) := matchcontinue (inArg,inArgType,inExpectedType,inVectDims)
//    local
//      Expression e,e_1;
//      Type e_type,expected_type;
//      String e1Str, t1Str, t2Str, s1;
//      DAE.Dimensions dims1, dims2, foreachdim;
//
//
//    // No vectorization mode.
//    // Types match (i.e. dims match exactly). Then all is good
//    case (e,e_type,expected_type, {})
//      equation
//        // Of course matchtype will make sure of this
//        // but this is faster.
//        dims1 = Types.getDimensions(e_type);
//        dims2 = Types.getDimensions(expected_type);
//        true = Expression.dimsEqual(dims1, dims2);
//
//        (e_1,_) = Types.matchType(e, e_type, expected_type, true);
//      then
//        (e_1, {});
//
//
//    // No vectorization mode.
//    // If it failed NOT because of dim mismatch but because
//    // of actuall type mismatch then fail here.
//    case (_,e_type,expected_type, {})
//      equation
//        dims1 = Types.getDimensions(e_type);
//        dims2 = Types.getDimensions(expected_type);
//        true = Expression.dimsEqual(dims1, dims2);
//      then
//        fail();
//
//    // No Vect. -> Vectorization mode.
//    // We found a dim mistmatch. Try vectorizing. If vectorizing
//    // matches, then this is our vectoriztion dimension.
//    // N.B. We still have to start matching again from the first arg
//    // with the new vectorization dimension.
//    case (e,e_type,expected_type, {})
//      equation
//        dims1 = Types.getDimensions(e_type);
//        dims2 = Types.getDimensions(expected_type);
//
//        false = Expression.dimsEqual(dims1, dims2);
//
//        foreachdim = findVectorizationDim(dims1,dims2);
//
//      then
//        (e, foreachdim);
//
//
//    // IN Vectorization mode!!!.
//    case (e,e_type,expected_type, foreachdim)
//      equation
//        e_1 = checkVectorization(e,e_type,expected_type,foreachdim);
//      then
//        (e_1, foreachdim);
//
//
//    case (e,e_type,expected_type, _)
//      equation
//        e1Str = ExpressionDump.printExpStr(e);
//        t1Str = Types.unparseType(e_type);
//        t2Str = Types.unparseType(expected_type);
//        s1 = "Failed to match or convert '" + e1Str + "' of type '" + t1Str +
//             "' to type '" + t2Str + "'";
//        Error.addSourceMessage(Error.INTERNAL_ERROR, {s1}, Absyn.dummyInfo);
//        true = Flags.isSet(Flags.FAILTRACE);
//        Debug.traceln("- NFTypeCheck.matchCallArg failed with type mismatch: " + t1Str + " tys: " + t2Str);
//      then
//        fail();
//  end matchcontinue;
//end matchCallArg;
//
//
//protected function checkVectorization
//"@mahge:
//  checks if it is possible to vectorize a given argument to the
//  expected or formal argument with the given vectorization dim.
//  e.g. inForeachDim=[3,2]
//       function F(input Integer[2]);
//
//       Integer a[2,3,2], b[2,2,2],s;
//
//       a is vectorizable with [3,2] => a[1]), a[2]
//       b is not vectorizable with [3,2]
//       s is vectorizable with [3,2] => {{s,s},{s,s},{s,s}}
//
//  N.B. The vectoriztion dim came from the first arg mismatch in
//  NFTypeCheck.matchCallArg and all susequent args shoudl be vectorizable
//  with that dim. This function checks that.
//  "
//  input Expression inArg;
//  input Type inArgType;
//  input Type inExpectedType;
//  input DAE.Dimensions inForeachDim;
//  output Expression outArg;
//algorithm
//  outArg := matchcontinue (inArg,inArgType,inExpectedType,inForeachDim)
//    local
//      Expression outExp;
//      DAE.Dimensions expectedDims, argDims;
//      String e1Str, t1Str, t2Str, s1;
//      Type expcType;
//
//    // if types match (which also means dims match exactly).
//    // Then we have to change the given argument to an array of
//    // the vect. dim to have a 'foreach' argument
//    case(_,_,_,_)
//      equation
//        // Of course matchtype will make sure of this
//        // but this is faster.
//        argDims = Types.getDimensions(inArgType);
//        expectedDims = Types.getDimensions(inExpectedType);
//        true = Expression.dimsEqual(argDims, expectedDims);
//
//        (outExp,_) = Types.matchType(inArg, inArgType, inExpectedType, false);
//
//        // create the array from the given arg to match the vectorization
//        outExp = Expression.arrayFill(inForeachDim,outExp);
//      then
//        outExp;
//
//    // if dims don't match exactly. Then the given argument
//    // must have the same dimension as our vecorization or 'foreach' dimension.
//    // And the expected type will be lifeted to the 'foreach' dim and then
//    // matched with the given argument
//    case(_,_,_,_)
//      equation
//
//        argDims = Types.getDimensions(inArgType);
//
//        // lift the expected type by 'foreach' dims
//        expcType = Types.liftArrayListDims(inExpectedType,inForeachDim);
//
//        // Now the given type and the expected type must have the
//        // same dimesions. Otherwise vectorization is not possible.
//        expectedDims = Types.getDimensions(expcType);
//        true = Expression.dimsEqual(argDims, expectedDims);
//
//        (outExp,_) = Types.matchType(inArg, inArgType, expcType, false);
//      then
//        outExp;
//
//    else
//      equation
//        argDims = Types.getDimensions(inArgType);
//        expectedDims = Types.getDimensions(inExpectedType);
//
//        expectedDims = listAppend(inForeachDim,expectedDims);
//
//        e1Str = ExpressionDump.printExpStr(inArg);
//        t1Str = Types.unparseType(inArgType);
//        t2Str = Types.unparseType(inExpectedType);
//        s1 = "Vectorization can not continue matching '" + e1Str + "' of type '" + t1Str +
//             "' to type '" + t2Str + "'. Expected dimensions [" +
//             ExpressionDump.printListStr(expectedDims,ExpressionDump.dimensionString,",") + "], found [" +
//             ExpressionDump.printListStr(argDims,ExpressionDump.dimensionString,",") + "]";
//
//        Error.addSourceMessage(Error.INTERNAL_ERROR, {s1}, Absyn.dummyInfo);
//        true = Flags.isSet(Flags.FAILTRACE);
//        Debug.traceln("- NFTypeCheck.checkVectorization failed ");
//      then
//        fail();
//
//   end matchcontinue;
//
//end checkVectorization;
//
//
//public function findVectorizationDim
//"@mahge:
// This function basically finds the diff between two dims. The resulting dimension
// is used for vectorizing calls.
//
// e.g. dim1=[2,3,4,2]  dim2=[4,2], findVectorizationDim(dim1,dim2) => [2,3]
//      dim1=[2,3,4,2]  dim2=[3,4,2], findVectorizationDim(dim1,dim2) => [2]
//      dim1=[2,3,4,2]  dim2=[4,3], fail
// "
//  input DAE.Dimensions inGivenDims;
//  input DAE.Dimensions inExpectedDims;
//  output DAE.Dimensions outVectDims;
//algorithm
//  outVectDims := matchcontinue(inGivenDims, inExpectedDims)
//    local
//      DAE.Dimensions dims1;
//      DAE.Dimension dim1;
//
//    case(_, {}) then inGivenDims;
//
//    case(_, _)
//      equation
//        true = Expression.dimsEqual(inGivenDims, inExpectedDims);
//      then
//        {};
//
//    case(dim1::dims1, _)
//      equation
//        true = listLength(inGivenDims) > listLength(inExpectedDims);
//        dims1 = findVectorizationDim(dims1,inExpectedDims);
//      then
//        dim1::dims1;
//
//    case(_::_, _)
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        Debug.traceln("- NFTypeCheck.findVectorizationDim failed with dimensions: [" +
//         ExpressionDump.printListStr(inGivenDims,ExpressionDump.dimensionString,",") + "] vs [" +
//         ExpressionDump.printListStr(inExpectedDims,ExpressionDump.dimensionString,",") + "].");
//      then
//        fail();
//
//  end matchcontinue;
//
//end findVectorizationDim;
//
//
//public function makeCallReturnType
//"@mahge:
//   makes the return type for function.
//   i.e if a list of types is given then it is a tuple ret function.
// "
//  input list<Type> inTypeLst;
//  output Type outType;
//  output Boolean outBoolean;
//algorithm
//  (outType,outBoolean) := match (inTypeLst)
//    local
//      Type ty;
//
//    case {} then (DAE.T_NORETCALL(DAE.emptyTypeSource), false);
//
//    case {ty} then (ty, false);
//
//    else  (DAE.T_TUPLE(inTypeLst,NONE(),DAE.emptyTypeSource), true);
//
//  end match;
//end makeCallReturnType;
//
//
//
//public function vectorizeCall
//"@mahge:
//   Vectorizes calls. Most of the work is done
//   vectorizeCall2.
//   This function get a list of functions with each arg
//   subscripted from vectorizeCall2. e.g. {F(a[1,1]),F(a[1,2]),F(a[2,1]),F(a[2,2])}
//   The it converts the list to an array of 'inForEachdim' dims using
//   Expression.listToArray. i.e.
//   {F(a[1,1]),F(a[1,2]),F(a[2,1]),F(a[2,2])} with vec. dim [2,2] will be
//   {{F(a[1,1]),F(a[1,2])}, {F(a[2,1])F(a[2,2])}}
//
// "
//  input Absyn.Path inFnName;
//  input list<Expression> inArgs;
//  input DAE.CallAttributes inAttrs;
//  input Type inRetType;
//  input DAE.Dimensions inForEachdim;
//  output Expression outExp;
//  output Type outType;
//algorithm
//  (outExp,outType) := matchcontinue (inFnName,inArgs,inAttrs,inRetType,inForEachdim)
//    local
//      list<Expression> callLst;
//      Expression callArr;
//      Type outtype;
//
//
//    // If no 'forEachdim' then no vectorization
//    case(_, _, _, _, {}) then (DAE.CALL(inFnName, inArgs, inAttrs), inRetType);
//
//
//    case(_, _::_, _, _, _)
//      equation
//        // Get the call list with args subscripted for each value in 'foreaach' dim.
//        callLst = vectorizeCall2(inFnName, inArgs, inAttrs, inForEachdim, {});
//
//        // Create the array of calls from the list
//        callArr = Expression.listToArray(callLst,inForEachdim);
//
//        // lift the retType to 'forEachDim' dims
//        outtype = Types.liftArrayListDims(inRetType, inForEachdim);
//      then
//        (callArr, outtype);
//
//    else
//      equation
//        Error.addMessage(Error.INTERNAL_ERROR, {"NFTypeCheck.vectorizeCall failed."});
//      then
//        fail();
//
//  end matchcontinue;
//end vectorizeCall;
//
//
//public function vectorizeCall2
//"@mahge:
//   Vectorizes calls. This function takes a list of args for a function
//   and a vectorization dim. then it subscripts the args for each idex
//   of the vec. dim and creates a function call for each subscripted
//   arg list. Then retuns the list of functions.
//   e.g.
//   for argLst ( a, {{b,b,b},{c,c,c}} ) and functionname F with vect. dim of [2,3]
//   this function creates the list
//
//   {F(a[1,1],b), F(a[1,2],b), F(a[1,3],b), F(a[2,1],c), F(a[2,2],c), F(a[2,3],c)}
// "
//  input Absyn.Path inFnName;
//  input list<Expression> inArgs;
//  input DAE.CallAttributes inAttrs;
//  input DAE.Dimensions inDims;
//  input list<Expression> inAccumCalls;
//  output list<Expression> outAccumCalls;
//algorithm
//  outAccumCalls := matchcontinue(inFnName, inArgs, inAttrs, inDims, inAccumCalls)
//    local
//      DAE.Dimension dim;
//      DAE.Dimensions dims;
//      Expression idx;
//      list<Expression> calls, subedargs;
//
//    case (_, _, _, {}, _) then DAE.CALL(inFnName, inArgs, inAttrs) :: inAccumCalls;
//
//    case (_, _, _, dim :: dims, _)
//      equation
//        (idx, dim) = getNextIndex(dim);
//
//        subedargs = List.map1(inArgs, Expression.subscriptExp, {DAE.INDEX(idx)});
//
//        calls = vectorizeCall2(inFnName, subedargs, inAttrs, dims, inAccumCalls);
//        calls = vectorizeCall2(inFnName, inArgs, inAttrs, dim :: dims, calls);
//      then
//        calls;
//
//    else inAccumCalls;
//
//  end matchcontinue;
//end vectorizeCall2;
//
//protected function getNextIndex
//  "Returns the next index given a dimension, and updates the dimension. Fails
//  when there are no indices left."
//  input DAE.Dimension inDim;
//  output Expression outNextIndex;
//  output DAE.Dimension outDim;
//algorithm
//  (outNextIndex, outDim) := match(inDim)
//    local
//      Integer new_idx, dim_size;
//      Absyn.Path p, ep;
//      String l;
//      list<String> l_rest;
//
//    case DAE.DIM_INTEGER(integer = 0) then fail();
//    case DAE.DIM_ENUM(size = 0) then fail();
//
//    case DAE.DIM_INTEGER(integer = new_idx)
//      equation
//        dim_size = new_idx - 1;
//      then
//        (DAE.ICONST(new_idx), DAE.DIM_INTEGER(dim_size));
//
//    // Assumes that the enum has been reversed with reverseEnumType.
//    case DAE.DIM_ENUM(p, l :: l_rest, new_idx)
//      equation
//        ep = Absyn.joinPaths(p, Absyn.IDENT(l));
//        dim_size = new_idx - 1;
//      then
//        (DAE.ENUM_LITERAL(ep, new_idx), DAE.DIM_ENUM(p, l_rest, dim_size));
//  end match;
//end getNextIndex;


// ************************************************************** //
//   END: TypeCall helper functions
// ************************************************************** //

function matchExpressions
  input output Expression exp1;
  input Type type1;
  input output Expression exp2;
  input Type type2;
  input Boolean allowUnknown = false;
        output Type compatibleType;
        output MatchKind matchKind;
algorithm
  (exp1, compatibleType, matchKind) :=
    matchTypes(type1, type2, exp1, allowUnknown);

  if isIncompatibleMatch(matchKind) then
    (exp2, compatibleType, matchKind) :=
      matchTypes(type2, type1, exp2, allowUnknown);
  end if;
end matchExpressions;

public
function matchTypes
  input Type actualType;
  input Type expectedType;
  input output Expression expression;
  input Boolean allowUnknown = false;
        output Type compatibleType;
        output MatchKind matchKind;
algorithm
  // Return true if the references are the same.
  if referenceEq(actualType, expectedType) then
    compatibleType := actualType;
    matchKind := MatchKind.EXACT;
    return;
  end if;

  // Check if the types are different kinds of types.
  if valueConstructor(actualType) <> valueConstructor(expectedType) then
    // If the types are not of the same kind we might need to type cast the
    // expression to make it compatible.
    (expression, compatibleType, matchKind) :=
      matchTypes_cast(actualType, expectedType, expression, allowUnknown);
    return;
  end if;

  // The types are of the same kind, so we only need to match on one of them.
  matchKind := MatchKind.EXACT;
  compatibleType := match (actualType)
    local
      list<Dimension> dims1, dims2;
      Dimension dim1, dim2;
      Type ety1, ety2;
      Boolean compat;
      InstNode cls;

    case Type.INTEGER() then actualType;
    case Type.REAL() then actualType;
    case Type.STRING() then actualType;
    case Type.BOOLEAN() then actualType;
    case Type.CLOCK() then actualType;

    case Type.ENUMERATION()
      algorithm
      then
        actualType;

    case Type.ENUMERATION_ANY() then actualType;

    case Type.ARRAY()
      algorithm
        (expression, compatibleType, matchKind) :=
          matchArrayTypes(actualType, expectedType, expression, allowUnknown);
      then
        compatibleType;

    case Type.TUPLE()
      algorithm
        (expression, compatibleType, matchKind) :=
          matchTupleTypes(actualType, expectedType, expression, allowUnknown);
      then
        compatibleType;

    case Type.COMPLEX()
      algorithm
        (expression, compatibleType, matchKind) :=
          matchComplexTypes(actualType, expectedType, expression, allowUnknown);
      then
        compatibleType;

    else
      algorithm
        assert(false, getInstanceName() + " got unknown type.");
      then
        fail();

  end match;
end matchTypes;

function matchComplexTypes
  input Type actualType;
  input Type expectedType;
  input output Expression expression;
  input Boolean allowUnknown;
        output Type compatibleType = actualType;
        output MatchKind matchKind = MatchKind.EXACT;
protected
  Class cls1, cls2;
  InstNode anode, enode;
  array<InstNode> comps1, comps2;
  Absyn.Path path;
  Type ty;
  ComplexType cty1, cty2;
  Expression e;
  list<Expression> elements, matched_elements = {};
  MatchKind mk;
algorithm
  Type.COMPLEX(cls = anode) := actualType;
  Type.COMPLEX(cls = enode) := expectedType;
  cls1 := InstNode.getClass(anode);
  cls2 := InstNode.getClass(enode);

  () := match (cls1, cls2, expression)
    case (Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps1)),
          Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps2)),
          Expression.RECORD(elements = elements))
      algorithm
        if arrayLength(comps1) <> arrayLength(comps2) or
           arrayLength(comps1) <> listLength(elements) then
          matchKind := MatchKind.NOT_COMPATIBLE;
        else
          for i in 1:arrayLength(comps1) loop
            e :: elements := elements;
            (e, _, mk) := matchTypes(InstNode.getType(comps1[i]), InstNode.getType(comps2[i]), e, allowUnknown);
            matched_elements := e :: matched_elements;

            if mk == MatchKind.CAST then
              matchKind := mk;
            elseif mk <> MatchKind.EXACT then
              matchKind := MatchKind.NOT_COMPATIBLE;
              break;
            end if;
          end for;

          if matchKind == MatchKind.CAST then
            expression.elements := listReverse(matched_elements);
          end if;
        end if;
      then
        ();

    case (Class.INSTANCED_CLASS(ty = Type.COMPLEX(complexTy = cty1 as ComplexType.CONNECTOR())),
          Class.INSTANCED_CLASS(ty = Type.COMPLEX(complexTy = cty2 as ComplexType.CONNECTOR())), _)
      algorithm
        matchKind := matchComponentList(cty1.potentials, cty2.potentials, allowUnknown);
        if matchKind <> MatchKind.NOT_COMPATIBLE then
          matchKind := matchComponentList(cty1.flows, cty2.flows, allowUnknown);
          if matchKind <> MatchKind.NOT_COMPATIBLE then
            matchKind := matchComponentList(cty1.streams, cty2.streams, allowUnknown);
          end if;
        end if;
      then
        ();

    case (Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps1)),
          Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps2)), _)
      algorithm
        if arrayLength(comps1) <> arrayLength(comps2) then
          matchKind := MatchKind.NOT_COMPATIBLE;
        else
          for i in 1:arrayLength(comps1) loop
            (_, _, mk) := matchTypes(InstNode.getType(comps1[i]), InstNode.getType(comps2[i]), expression, allowUnknown);

            if mk <> MatchKind.EXACT then
              matchKind := MatchKind.NOT_COMPATIBLE;
              break;
            end if;
          end for;
        end if;
      then
        ();

    else
      algorithm
        matchKind := MatchKind.NOT_COMPATIBLE;
      then
        ();

  end match;
end matchComplexTypes;

function matchComponentList
  input list<InstNode> comps1;
  input list<InstNode> comps2;
  input Boolean allowUnknown;
  output MatchKind matchKind;
protected
  InstNode c2;
  list<InstNode> rest_c2 = comps2;
  Expression dummy = Expression.INTEGER(0);
algorithm
  if listLength(comps1) <> listLength(comps2) then
    matchKind := MatchKind.NOT_COMPATIBLE;
  else
    for c1 in comps1 loop
      c2 :: rest_c2 := comps2;
      (_, _, matchKind) := matchTypes(InstNode.getType(c1), InstNode.getType(c2), dummy, allowUnknown);

      if matchKind <> MatchKind.EXACT then
        matchKind := MatchKind.NOT_COMPATIBLE;
        return;
      end if;
    end for;
  end if;
end matchComponentList;

function matchArrayTypes
  input Type arrayType1;
  input Type arrayType2;
  input output Expression expression;
  input Boolean allowUnknown;
        output Type compatibleType;
        output MatchKind matchKind;
protected
  Type ety1, ety2;
  list<Dimension> dims1, dims2;
  Dimension dim1, dim2;
  Boolean compat;
algorithm
  Type.ARRAY(elementType = ety1, dimensions = dims1) := arrayType1;
  Type.ARRAY(elementType = ety2, dimensions = dims2) := arrayType2;

  // Check that the element types are compatible.
  (expression, compatibleType, matchKind) :=
    matchTypes(ety1, ety2, expression, allowUnknown);

  // If the element types are compatible, check the dimensions too.
  if isCompatibleMatch(matchKind) then
    // The arrays must have the same number of dimensions.
    if listLength(dims1) == listLength(dims2) then
      while not listEmpty(dims1) loop
        dim1 :: dims1 := dims1;
        dim2 :: dims2 := dims2;

        // And the dimensions must be equal.
        (dim1, compat) := matchDimensions(dim1, dim2, allowUnknown);

        if not compat then
          matchKind := MatchKind.NOT_COMPATIBLE;
          break;
        end if;

        compatibleType := Type.liftArrayLeft(compatibleType, dim1);
      end while;
    else
      matchKind := MatchKind.NOT_COMPATIBLE;
    end if;
  end if;
end matchArrayTypes;

function matchTupleTypes
  input Type tupleType1;
  input Type tupleType2;
  input output Expression expression;
  input Boolean allowUnknown;
        output Type compatibleType = tupleType1;
        output MatchKind matchKind = MatchKind.EXACT;
protected
  list<Type> tyl1, tyl2;
  Type ty1;
algorithm
  Type.TUPLE(types = tyl1) := tupleType1;
  Type.TUPLE(types = tyl2) := tupleType2;

  if listLength(tyl1) < listLength(tyl2) then
    matchKind := MatchKind.NOT_COMPATIBLE;
    return;
  end if;

  for ty2 in tyl2 loop
    ty1 :: tyl1 := tyl1;
    (_, _, matchKind) := matchTypes(ty1, ty2, expression, allowUnknown);

    if matchKind <> MatchKind.EXACT then
      break;
    end if;
  end for;
end matchTupleTypes;

function matchDimensions
  input Dimension dim1;
  input Dimension dim2;
  input Boolean allowUnknown;
  output Dimension compatibleDim;
  output Boolean compatible = true;
algorithm
  if Dimension.isEqualKnown(dim1, dim2) then
    compatibleDim := dim1;
  elseif allowUnknown then
    if Dimension.isKnown(dim1) then
      compatibleDim := dim1;
    else
      compatibleDim := dim2;
    end if;
  end if;
end matchDimensions;

function matchTypes_cast
  input Type actualType;
  input Type expectedType;
  input output Expression expression;
  input Boolean allowUnknown = false;
        output Type compatibleType;
        output MatchKind matchKind;
algorithm
  (compatibleType, matchKind) := match(actualType, expectedType)
    // Integer can be cast to Real.
    case (Type.INTEGER(), Type.REAL())
      algorithm
        expression := Expression.typeCastElements(expression, expectedType);
      then
        (expectedType, MatchKind.CAST);

    // Any enumeration is compatible with enumeration(:).
    case (Type.ENUMERATION(), Type.ENUMERATION_ANY())
      algorithm
        // TODO: FIXME: Maybe this should be generic match
      then
        (actualType, MatchKind.CAST);

    // If the actual type is a tuple but the expected type isn't,
    // try to use the first type in the tuple.
    case (Type.TUPLE(types = _ :: _), _)
      algorithm
        (expression, compatibleType, matchKind) :=
          matchTypes(listHead(actualType.types), expectedType, expression, allowUnknown);

        if isCompatibleMatch(matchKind) then
          expression := match expression
            case Expression.TUPLE() then listHead(expression.elements);
            else Expression.TUPLE_ELEMENT(expression, 1, compatibleType);
          end match;

          matchKind := MatchKind.CAST;
        end if;
      then
        (compatibleType, matchKind);

    // Allow unknown types in some cases, e.g. () has type METALIST(UNKNOWN)
    case (Type.UNKNOWN(), _)
      then (expectedType,
        if allowUnknown then MatchKind.UNKNOWN_ACTUAL else MatchKind.NOT_COMPATIBLE);

    case (_, Type.UNKNOWN())
      then (actualType,
        if allowUnknown then MatchKind.UNKNOWN_EXPECTED else MatchKind.NOT_COMPATIBLE);

    case (_, Type.ANY_TYPE())
      algorithm
        expression := Expression.BOX(expression);
        // matchKind := MatchKind.GENERIC(expectedType.b,actualType);
      then
        (Type.METABOXED(actualType), MatchKind.GENERIC);

    case (Type.ANY_TYPE(), _)
      algorithm
        // expression := Expression.UNBOX(expression, Expression.typeOf(expression));
        // matchKind := MatchKind.GENERIC(expectedType.b,actualType);
      then
        (expectedType, MatchKind.GENERIC);

    // Anything else is not compatible.
    else (Type.UNKNOWN(), MatchKind.NOT_COMPATIBLE);
  end match;
end matchTypes_cast;


//function checkTypeCompat
//  "This function checks that two types are compatible, as per the definition of
//   type compatible expressions in the specification. If needed it also does type
//   casting to make the expressions compatible. If the types are compatible it
//   returns the compatible type, otherwise the type returned is undefined."
//  input output Expression exp1;
//  input Type type1;
//  input output Expression exp2;
//  input Type type2;
//  input Boolean allowUnknown = false;
//        output Type compatType;
//        output Boolean compatible = true;
//protected
//  Type ty1, ty2;
//algorithm
//  // Return true if the references are the same.
//  if referenceEq(type1, type2) then
//    compatType := type1;
//    return;
//  end if;
//
//  // Check if the types are different kinds of types.
//  if valueConstructor(type1) <> valueConstructor(type2) then
//    if Types.extendsBasicType(type1) or Types.extendsBasicType(type2) then
//      // If either type extends a basic type, check the basic type instead.
//      ty1 := Types.derivedBasicType(type1);
//      ty2 := Types.derivedBasicType(type2);
//      (exp1, exp2, compatType, compatible) :=
//        checkTypeCompat(exp1, ty1, exp2, ty2);
//    else
//      // If the types are not of the same kind they might need to be type cast
//      // to become compatible.
//      (exp1, exp2, compatType, compatible) :=
//        checkTypeCompat_cast(exp1, type1, exp2, type2, allowUnknown);
//    end if;
//
//    // Regardless of the chosen branch above, we are done here.
//    return;
//  end if;
//
//  // The types are of the same kind, so we only need to match on one of them
//  // (which is a lot more efficient than matching both).
//  compatType := match(type1)
//    local
//      list<DAE.Dimension> dims1, dims2;
//      Type ety1, ety2, ty;
//      list<String> names;
//      list<DAE.Var> vars;
//      list<DAE.FuncArg> args;
//      list<Type> tys, tys2;
//      String name;
//      Absyn.Path p1, p2;
//
//    // Basic types, must be the same.
//    case DAE.T_INTEGER() then DAE.T_INTEGER_DEFAULT;
//    case DAE.T_REAL() then DAE.T_REAL_DEFAULT;
//    case DAE.T_STRING() then DAE.T_STRING_DEFAULT;
//    case DAE.T_BOOL() then DAE.T_BOOL_DEFAULT;
//    case DAE.T_CLOCK() then DAE.T_CLOCK_DEFAULT;
//
//    case DAE.T_SUBTYPE_BASIC()
//      algorithm
//        DAE.T_SUBTYPE_BASIC(complexType = ty) := type2;
//        (exp1, exp2, compatType, compatible) :=
//          checkTypeCompat(exp1, type1.complexType, exp2, ty);
//      then
//        compatType;
//
//    // Enumerations, check that they have same literals.
//    case DAE.T_ENUMERATION()
//      algorithm
//        DAE.T_ENUMERATION(names = names) := type2;
//        compatible := List.isEqualOnTrue(type1.names, names, stringEq);
//      then
//        type1;
//
//    // Arrays, must have compatible element types and dimensions.
//    case DAE.T_ARRAY()
//      algorithm
//        // Check that the element types are compatible.
//        ety1 := Types.arrayElementType(type1);
//        ety2 := Types.arrayElementType(type2);
//        (exp1, exp2, compatType, compatible) :=
//          checkTypeCompat(exp1, ety1, exp2, ety2);
//
//        // If the element types are compatible, check the dimensions too.
//        if compatible then
//          dims1 := Types.getDimensions(type1);
//          dims2 := Types.getDimensions(type2);
//
//          // The arrays must have the same number of dimensions.
//          if listLength(dims1) == listLength(dims2) then
//            dims1 := list(if DAEExpression.dimensionsKnownAndEqual(dim1, dim2) then
//              dim1 else DAE.DIM_UNKNOWN() threaded for dim1 in dims1, dim2 in dims2);
//            compatType := Types.liftArrayListDims(compatType, dims1);
//          else
//            compatible := false;
//          end if;
//        end if;
//      then
//        compatType;
//
//    // Records, must have the same components.
//    case DAE.T_COMPLEX(complexClassType = ClassInf.RECORD())
//      algorithm
//        DAE.T_COMPLEX(varLst = vars) := type2;
//        // TODO: Implement type casting for records with the same components but
//        // in different order.
//        compatible := List.isEqualOnTrue(type1.varLst, vars, Types.varEqualName);
//      then
//        type1;
//
//    case DAE.T_FUNCTION()
//      algorithm
//        DAE.T_FUNCTION(funcResultType = ty, funcArg = args) := type2;
//        (exp1, exp2, compatType, compatible) :=
//          checkTypeCompat(exp1, type1.funcResultType, exp2, ty);
//
//        if compatible then
//          tys := list(Types.funcArgType(arg) for arg in type1.funcArg);
//          tys2 := list(Types.funcArgType(arg) for arg in args);
//          (_, compatible) := checkTypeCompatList(exp1, tys, exp2, tys2);
//        end if;
//      then
//        type1;
//
//    case DAE.T_TUPLE()
//      algorithm
//        DAE.T_TUPLE(types = tys) := type2;
//        (tys, compatible) :=
//          checkTypeCompatList(exp1, type1.types, exp2, tys);
//      then
//        DAE.T_TUPLE(tys, type1.names, type1.source);
//
//    // MetaModelica types.
//    case DAE.T_METALIST()
//      algorithm
//        DAE.T_METALIST(ty = ty) := type2;
//        (exp1, exp2, compatType, compatible) :=
//          checkTypeCompat(exp1, type1.ty, exp2, ty, true);
//      then
//        DAE.T_METALIST(compatType, type1.source);
//
//    case DAE.T_METAARRAY()
//      algorithm
//        DAE.T_METAARRAY(ty = ty) := type2;
//        (exp1, exp2, compatType, compatible) :=
//          checkTypeCompat(exp1, type1.ty, exp2, ty, true);
//      then
//        DAE.T_METAARRAY(compatType, type1.source);
//
//    case DAE.T_METAOPTION()
//      algorithm
//        DAE.T_METAOPTION(ty = ty) := type2;
//        (exp1, exp2, compatType, compatible) :=
//          checkTypeCompat(exp1, type1.ty, exp2, ty, true);
//      then
//        DAE.T_METAOPTION(compatType, type1.source);
//
//    case DAE.T_METATUPLE()
//      algorithm
//        DAE.T_METATUPLE(types = tys) := type2;
//        (tys, compatible) :=
//          checkTypeCompatList(exp1, type1.types, exp2, tys);
//      then
//        DAE.T_METATUPLE(tys, type1.source);
//
//    case DAE.T_METABOXED()
//      algorithm
//        DAE.T_METABOXED(ty = ty) := type2;
//        (exp1, exp2, compatType, compatible) :=
//          checkTypeCompat(exp1, type1.ty, exp2, ty);
//      then
//        DAE.T_METABOXED(compatType, type1.source);
//
//    case DAE.T_METAPOLYMORPHIC()
//      algorithm
//        DAE.T_METAPOLYMORPHIC(name = name) := type2;
//        compatible := type1.name == name;
//      then
//        type1;
//
//    case DAE.T_METAUNIONTYPE(source = {p1})
//      algorithm
//        DAE.T_METAUNIONTYPE(source = {p2}) := type2;
//        compatible := Absyn.pathEqual(p1, p2);
//      then
//        type1;
//
//    case DAE.T_METARECORD(utPath = p1)
//      algorithm
//        DAE.T_METARECORD(utPath = p2) := type2;
//        compatible := Absyn.pathEqual(p1, p2);
//      then
//        type1;
//
//    case DAE.T_FUNCTION_REFERENCE_VAR()
//      algorithm
//        DAE.T_FUNCTION_REFERENCE_VAR(functionType = ty) := type2;
//        (exp1, exp2, compatType, compatible) :=
//          checkTypeCompat(exp1, type1.functionType, exp2, ty);
//      then
//        DAE.T_FUNCTION_REFERENCE_VAR(compatType, type1.source);
//
//    else
//      algorithm
//        compatible := false;
//      then
//        DAE.T_UNKNOWN_DEFAULT;
//
//  end match;
//end checkTypeCompat;
//
//function checkTypeCompatList
//  "Checks that two lists of types are compatible using checkTypeCompat."
//  input Expression exp1;
//  input list<Type> types1;
//  input Expression exp2;
//  input list<Type> types2;
//  output list<Type> compatibleTypes = {};
//  output Boolean compatible = true;
//protected
//  Type ty2;
//  list<Type> rest_ty2 = types2;
//  Boolean compat;
//algorithm
//  if listLength(types1) <> listLength(types2) then
//    compatible := false;
//    return;
//  end if;
//
//  for ty1 in types1 loop
//    ty2 :: rest_ty2 := rest_ty2;
//    // Ignore the returned expressions. This function is used for tuples, and
//    // it's not clear how tuples should be type converted. So we only check that
//    // the types are compatible and hope for the best.
//    (_, _, ty2, compat) := checkTypeCompat(exp1, ty1, exp2, ty2);
//
//    if not compat then
//      compatible := false;
//      return;
//    end if;
//
//    compatibleTypes := ty2 :: compatibleTypes;
//  end for;
//
//  compatibleTypes := listReverse(compatibleTypes);
//end checkTypeCompatList;

//function checkTypeCompat_cast
//  "Helper function to checkTypeCompat. Tries to type cast one of the given
//   expressions so that they become type compatible."
//  input output Expression exp1;
//  input Type type1;
//  input output Expression exp2;
//  input Type type2;
//  input Boolean allowUnknown;
//  output Type compatType;
//  output Boolean compatible = true;
//protected
//  Type ty1, ty2;
//  Absyn.Path path;
//algorithm
//  ty1 := Types.derivedBasicType(type1);
//  ty2 := Types.derivedBasicType(type2);
//
//  compatType := match(ty1, ty2)
//    // Real <-> Integer
//    case (DAE.T_REAL(), DAE.T_INTEGER())
//      algorithm
//        exp2 := Expression.typeCastElements(exp2, DAE.T_REAL_DEFAULT);
//      then
//        DAE.T_REAL_DEFAULT;
//
//    case (DAE.T_INTEGER(), DAE.T_REAL())
//      algorithm
//        exp1 := Expression.typeCastElements(exp1, DAE.T_REAL_DEFAULT);
//      then
//        DAE.T_REAL_DEFAULT;
//
//    // If one of the expressions is boxed, unbox it.
//    case (DAE.T_METABOXED(), _)
//      algorithm
//        (exp1, exp2, compatType, compatible) :=
//          checkTypeCompat(exp1, ty1.ty, exp2, ty2, allowUnknown);
//        exp1 := if Types.isBoxedType(ty2) then exp1 else Expression.UNBOX(exp1, compatType);
//      then
//        ty2;
//
//    case (_, DAE.T_METABOXED())
//      algorithm
//        (exp1, exp2, compatType, compatible) :=
//          checkTypeCompat(exp1, ty1, exp2, ty2.ty, allowUnknown);
//        exp2 := if Types.isBoxedType(ty1) then exp2 else Expression.UNBOX(exp2, compatType);
//      then
//        ty1;
//
//    // Expressions such as Absyn.IDENT gets the type T_METARECORD(Absyn.Path.IDENT)
//    // instead of UNIONTYPE(Absyn.Path), but e.g. a function returning an
//    // Absyn.PATH has the type UNIONTYPE(Absyn.PATH). So we'll just pretend that
//    // metarecords actually have uniontype type.
//    case (DAE.T_METARECORD(), DAE.T_METAUNIONTYPE(source = {path}))
//      algorithm
//        compatible := Absyn.pathEqual(ty1.utPath, path);
//      then
//        ty2;
//
//    case (DAE.T_METAUNIONTYPE(source = {path}), DAE.T_METARECORD())
//      algorithm
//        compatible := Absyn.pathEqual(path, ty2.utPath);
//      then
//        ty1;
//
//    // Allow unknown types in some cases, e.g. () has type T_METALIST(T_UNKNOWN)
//    case (DAE.T_UNKNOWN(), _)
//      algorithm
//        compatible := allowUnknown;
//      then
//        ty2;
//
//    case (_, DAE.T_UNKNOWN())
//      algorithm
//        compatible := allowUnknown;
//      then
//        ty1;
//
//    // Anything else is not compatible.
//    else
//      algorithm
//        compatible := false;
//      then
//        DAE.T_UNKNOWN_DEFAULT;
//
//  end match;
//end checkTypeCompat_cast;

//public function getTypeDims
//"This will NOT fail if type is not array type."
//  input Type inType;
//  output DAE.Dimensions outDims;
//algorithm
//  outDims := match (inType)
//    case DAE.T_ARRAY() then inType.dims;
//    case DAE.T_FUNCTION() then getTypeDims(inType.funcResultType);
//    else {};
//  end match;
//end getTypeDims;

//function applySubsToDims
//  input list<DAE.Dimension> inDims;
//  input list<DAE.Subscript> inSubs;
//  output list<DAE.Dimension> outDims = {};
//protected
//  DAE.Dimension dim;
//  list<DAE.Dimension> dims1, dims2, slicedims;
//  Type baseTy, ixty;
//algorithm
//  dims1 := inDims;
//  dims2 := {};
//
//  for sub in inSubs loop
//    _ := match sub
//      case DAE.INDEX()
//        algorithm
//          ixty := Expression.typeof(sub.exp);
//          slicedims := getTypeDims(ixty);
//          if listLength(slicedims) > 0 then
//            assert(listLength(slicedims) == 1,
//              getInstanceName() + " failed. Got a slice with more than one dim?");
//            _::dims1 := dims1;
//            {dim} := slicedims;
//            outDims := dim::outDims;
//          end if;
//        then
//          ();
//
//      case DAE.WHOLEDIM()
//        algorithm
//          dim::dims1 := dims1;
//          outDims := dim::outDims;
//        then
//          ();
//    end match;
//  end for;
//end applySubsToDims;

function checkValidNumericTypesForOp
"  TODO: update me.
  @mahge:
  Helper function for Check*Operator functions.
  Checks if both operands are Numeric types for all operators except Addition.
  Which can also work on Strings and maybe Booleans??.
  Written separatly because it needs to print an error."
  input Type type1;
  input Type type2;
  input Operator operator;
  input Boolean printError;
  output Boolean isValid;
algorithm
  isValid := match operator
    local
      String ty1_str, ty2_str, op_str;

    case Operator.ADD() then true;

    case _ guard Type.isNumeric(type1) and Type.isNumeric(type2) then true;

    else
      algorithm
        if printError then
          ty1_str := Type.toString(type1);
          ty2_str := Type.toString(type2);
          op_str := Operator.symbol(operator);
          Error.addSourceMessage(Error.FOUND_NON_NUMERIC_TYPES,
            {op_str, ty1_str, ty2_str}, Absyn.dummyInfo);
        end if;
      then
        false;
  end match;
end checkValidNumericTypesForOp;

function isValidMatrixMultiplyDims
" TODO: update me.
  @mahge:
  Checks if two dimensions are equal, which is a prerequisite for Matrix/Vector
  multiplication."
  input Dimension dim1;
  input Dimension dim2;
  output Boolean res;
protected
  String msg;
algorithm
  if Dimension.isEqualKnown(dim1, dim2) then
    // The dimensions are both known and equal.
    res := true;
  elseif Flags.getConfigBool(Flags.CHECK_MODEL) and Dimension.isEqual(dim1, dim2) then
    // If checkModel is used we might get unknown dimensions. So use
    // isEqual instead, which matches anything against Dimension.UNKNOWN.
    res := true;
  else
    msg := "Dimension mismatch in Vector/Matrix multiplication operation: " +
      Dimension.toString(dim1) + "x" + Dimension.toString(dim2);
    Error.addSourceMessage(Error.COMPILER_ERROR, {msg}, Absyn.dummyInfo);
    res := false;
  end if;
end isValidMatrixMultiplyDims;

function binaryArrayOpError
  input Expression inExp1;
  input Type inType1;
  input Expression inExp2;
  input Type inType2;
  input Operator inOp;
  input String suggestion;
protected
  String e1Str, t1Str, e2Str, t2Str, s1, s2, sugg;
algorithm
  e1Str := Expression.toString(inExp1);
  t1Str := Type.toString(inType1);
  e2Str := Expression.toString(inExp2);
  t2Str := Type.toString(inType2);
  s1 := "' " + e1Str + Operator.symbol(inOp) + e2Str + " '";
  s2 := "' " + t1Str + Operator.symbol(inOp) + t2Str + " '";
  Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1,s2,suggestion}, Absyn.dummyInfo);
  fail();
end binaryArrayOpError;

//public function getCrefType
//  input DAE.ComponentRef inCref;
//  output Type outType;
//protected
//  Type baseTy;
//  list<DAE.Dimension> dims, accdims;
//algorithm
//  (accdims,baseTy) := getCrefType2(inCref);
//  if listLength(accdims) > 0 then
//    outType := DAE.T_ARRAY(baseTy, accdims, DAE.emptyTypeSource);
//  else
//    outType := baseTy;
//  end if;
//end getCrefType;
//
//function getCrefType2
//  input DAE.ComponentRef inCref;
//  input output list<DAE.Dimension> accDims = {};
//  output Type baseType;
//protected
//  list<DAE.Dimension> dims;
//algorithm
//  _ := match inCref
//
//    case DAE.CREF_IDENT()
//      algorithm
//        baseType := Type.elementType(inCref.identType);
//        dims := getTypeDims(inCref.identType);
//        dims := applySubsToDims(dims, inCref.subscriptLst);
//        accDims := dims;
//      then ();
//
//    case DAE.CREF_QUAL()
//      algorithm
//        (accDims,baseType) := getCrefType2(inCref.componentRef);
//        dims := getTypeDims(inCref.identType);
//        dims := applySubsToDims(dims, inCref.subscriptLst);
//        accDims := listAppend(dims, accDims);
//      then ();
//
//    else
//      fail();
//  end match;
//end getCrefType2;

function getRangeType
  input Expression startExp;
  input Option<Expression> stepExp;
  input Expression stopExp;
  input Type rangeElemType;
  input SourceInfo info;
  output Type rangeType;
protected
  Expression step_exp;
  Dimension dim;
algorithm
  if isSome(stepExp) then
    SOME(step_exp) := stepExp;

    dim := match rangeElemType
      case Type.INTEGER() then getRangeTypeInt(startExp, stepExp, stopExp, info);
      case Type.REAL() then getRangeTypeReal(startExp, stepExp, stopExp, info);
      else // Only Integer and Real ranges may have a step size.
        algorithm
          if Type.isBoolean(rangeElemType) or Type.isEnumeration(rangeElemType) then
            // If the range is Boolean or enumeration, tell the user that the
            // step size is not allowed to be specified.
            Error.addSourceMessage(Error.RANGE_INVALID_STEP,
              {Type.toString(rangeElemType)}, info);
          else
            // Other types are not allowed regardless of step size or not.
            Error.addSourceMessage(Error.RANGE_INVALID_TYPE,
              {Type.toString(rangeElemType)}, info);
          end if;
        then
          fail();
    end match;
  else
    dim := match rangeElemType
      case Type.INTEGER() then getRangeTypeInt(startExp, stepExp, stopExp, info);
      case Type.REAL() then getRangeTypeReal(startExp, stepExp, stopExp, info);
      case Type.BOOLEAN() then getRangeTypeBool(startExp, stopExp);
      case Type.ENUMERATION() then getRangeTypeEnum(startExp, stopExp);
      else
        algorithm
          Error.addSourceMessage(Error.RANGE_INVALID_TYPE,
            {Type.toString(rangeElemType)}, info);
        then
          fail();
    end match;
  end if;

  rangeType := Type.ARRAY(rangeElemType, {dim});
end getRangeType;

function getRangeTypeInt
  input Expression startExp;
  input Option<Expression> stepExp;
  input Expression stopExp;
  input SourceInfo info;
  output Dimension dim;
algorithm
  dim := match (startExp, stepExp, stopExp)
    local
      Integer step;

    case (Expression.INTEGER(), NONE(), Expression.INTEGER())
      then Dimension.INTEGER(max(stopExp.value - startExp.value + 1, 0));

    case (Expression.INTEGER(), SOME(Expression.INTEGER(value = step)), Expression.INTEGER())
      algorithm
        // Don't allow infinite ranges.
        if step == 0 then
          Error.addSourceMessageAndFail(Error.RANGE_ZERO_STEP, {}, info);
        end if;
      then
        Dimension.INTEGER(max(intDiv(stopExp.value - startExp.value, step) + 1, 0));

    else Dimension.UNKNOWN();
  end match;
end getRangeTypeInt;

function getRangeTypeReal
  input Expression startExp;
  input Option<Expression> stepExp;
  input Expression stopExp;
  input SourceInfo info;
  output Dimension dim;
algorithm
  dim := match (startExp, stepExp, stopExp)
    local
      Real step;

    case (Expression.REAL(), NONE(), Expression.REAL())
      then Dimension.INTEGER(Util.realRangeSize(startExp.value, 1.0, stopExp.value));

    case (Expression.REAL(), SOME(Expression.REAL(value = step)), Expression.REAL())
      algorithm
        // The old inst checked that step > 1e-14, but that's actually ok if
        // start and stop are also small. We could maybe check that the range
        // doesn't become too large, but then we'd have to define 'too large'.
        if step == 0.0 then
          Error.addSourceMessageAndFail(Error.RANGE_ZERO_STEP, {}, info);
        end if;
      then
        Dimension.INTEGER(Util.realRangeSize(startExp.value, step, stopExp.value));

    else Dimension.UNKNOWN();
  end match;
end getRangeTypeReal;

function getRangeTypeBool
  input Expression startExp;
  input Expression stopExp;
  output Dimension dim;
algorithm
  dim := match (startExp, stopExp)
    local
      Integer sz;

    case (Expression.BOOLEAN(), Expression.BOOLEAN())
      algorithm
        sz := if startExp.value == startExp.value then 1
              elseif startExp.value < startExp.value then 2
              else 0;
      then
        Dimension.INTEGER(sz);

    else Dimension.UNKNOWN();
  end match;
end getRangeTypeBool;

function getRangeTypeEnum
  input Expression startExp;
  input Expression stopExp;
  output Dimension dim;
algorithm
  dim := match (startExp, stopExp)
    case (Expression.ENUM_LITERAL(), Expression.ENUM_LITERAL())
      then Dimension.INTEGER(max(stopExp.index - startExp.index + 1, 0));

    else Dimension.UNKNOWN();
  end match;
end getRangeTypeEnum;

function checkIfExpression
  input Expression condExp;
  input Type condType;
  input Variability condVar;
  input Expression thenExp;
  input Type thenType;
  input Variability thenVar;
  input Expression elseExp;
  input Type elseType;
  input Variability elseVar;
  input SourceInfo info;
  output Expression outExp;
  output Type outType;
  output Variability outVar;
protected
   Expression ec, e1, e2;
   String s1, s2, s3, s4;
   MatchKind ty_match;
algorithm
  (ec, _, ty_match) := matchTypes(condType, Type.BOOLEAN(), condExp);

  // The condition must be a boolean.
  if isIncompatibleMatch(ty_match) then
    s1 := Expression.toString(condExp);
    s2 := Type.toString(condType);
    Error.addSourceMessageAndFail(Error.IF_CONDITION_TYPE_ERROR, {s1, s2}, info);
  end if;

  (e1, e2, outType, ty_match) :=
    matchExpressions(thenExp, thenType, elseExp, elseType);

  // The types of the branches must be compatible.
  if isIncompatibleMatch(ty_match) then
    s1 := Expression.toString(thenExp);
    s2 := Expression.toString(elseExp);
    s3 := Type.toString(thenType);
    s4 := Type.toString(elseType);
    Error.addSourceMessageAndFail(Error.TYPE_MISMATCH_IF_EXP,
      {"", s1, s3, s2, s4}, info);
  end if;

  outExp := Expression.IF(ec, e1, e2);
  outType := thenType;
  outVar := Prefixes.variabilityMax(thenVar, elseVar);
end checkIfExpression;

function matchBinding
  input output Binding binding;
  input Type componentType;
  input String name;
  input InstNode component;
algorithm
  () := match binding
    local
      MatchKind ty_match;
      Expression exp;
      Type ty, comp_ty;
      InstNode parent;
      list<Dimension> dims;

    case Binding.TYPED_BINDING()
      algorithm
        comp_ty := componentType;

        if binding.originLevel >= 0 then
          parent := component;

          for i in 1:InstNode.level(component) - binding.originLevel loop
            parent := InstNode.parent(component);
            dims := Type.arrayDims(InstNode.getType(parent));
            comp_ty := Type.liftArrayLeftList(comp_ty, dims);
          end for;
        end if;

        (exp, ty, ty_match) := matchTypes(binding.bindingType, comp_ty, binding.bindingExp);

        if not isCompatibleMatch(ty_match) then
          Error.addSourceMessage(Error.VARIABLE_BINDING_TYPE_MISMATCH,
            {name, Binding.toString(binding), Type.toString(comp_ty),
             Type.toString(binding.bindingType)}, binding.info);
          fail();
        elseif isCastMatch(ty_match) then
          binding := Binding.TYPED_BINDING(exp, ty, binding.variability, binding.originLevel, binding.info);
        end if;
      then
        ();

    case Binding.UNBOUND() then ();

    else
      algorithm
        assert(false, getInstanceName() + " got untyped binding " + Binding.toString(binding));
      then
        fail();
  end match;
end matchBinding;

function checkDimension
  "Checks that an expression used as a dimension is a parameter expression and
   has a valid type for a dimension, otherwise prints an error and fails."
  input Expression exp;
  input Type ty;
  input Variability var;
  input SourceInfo info;
algorithm
  if not Type.isInteger(ty) then
    () := match exp
      case Expression.TYPENAME(ty = Type.ARRAY(elementType = Type.BOOLEAN())) then ();
      case Expression.TYPENAME(ty = Type.ARRAY(elementType = Type.ENUMERATION())) then ();
      else
        algorithm
          Error.addSourceMessage(Error.INVALID_DIMENSION_TYPE,
            {Expression.toString(exp), Type.toString(ty)}, info);
        then
          fail();
    end match;
  end if;

  if var > Variability.PARAMETER then
    Error.addSourceMessage(Error.DIMENSION_NOT_KNOWN,
      {Expression.toString(exp)}, info);
    fail();
  end if;
end checkDimension;

annotation(__OpenModelica_Interface="frontend");
end NFTypeCheck;
