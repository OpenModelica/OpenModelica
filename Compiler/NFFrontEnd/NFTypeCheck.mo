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
import BindingOrigin = NFBindingOrigin;
import NFOperator.Op;
import NFTyping.ExpOrigin;
import NFFunction.Function;
import NFFunction.TypedArg;
import NFFunction.FunctionMatchKind;
import NFFunction.MatchedFunction;
import NFCall.Call;
import NFCall.CallAttributes;
import ComponentRef = NFComponentRef;
import ErrorExt;
import NFBuiltin;



public
type MatchKind = enumeration(
  EXACT "Exact match",
  CAST  "Matched by casting, e.g. Integer to real",
  UNKNOWN_EXPECTED "The expected type was unknown",
  UNKNOWN_ACTUAL   "The actual type was unknown",
  GENERIC "Matched with a generic type e.g. function F<T> input T i; end F; F(1)",
  PLUG_COMPATIBLE "Component by component matching, e.g. class A R r; end A; is plug compatible with class B R r; end B;",
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

function isExactMatch
  input MatchKind kind;
  output Boolean isCompatible = kind == MatchKind.EXACT;
end isExactMatch;

function isCastMatch
  input MatchKind kind;
  output Boolean isCast = kind == MatchKind.CAST;
end isCastMatch;

function isGenericMatch
  input MatchKind kind;
  output Boolean isCast = kind == MatchKind.GENERIC;
end isGenericMatch;

function isValidAssignmentMatch
  input MatchKind kind;
  output Boolean v = kind == MatchKind.EXACT
                     or kind == MatchKind.CAST
                     ;
end isValidAssignmentMatch;

function isValidBindingMatch
  input MatchKind kind;
  output Boolean v = isValidAssignmentMatch(kind);
end isValidBindingMatch;

function isValidArgumentMatch
  input MatchKind kind;
  output Boolean v = kind == MatchKind.EXACT
                     or kind == MatchKind.CAST
                     or kind == MatchKind.GENERIC
                     ;
end isValidArgumentMatch;

function isValidPlugCompatibleMatch
  input MatchKind kind;
  output Boolean v = kind == MatchKind.EXACT
                     or kind == MatchKind.PLUG_COMPATIBLE
                     ;
end isValidPlugCompatibleMatch;


function checkBinaryOperation
  input Expression exp1;
  input Type type1;
  input Operator operator;
  input Expression exp2;
  input Type type2;
  input SourceInfo info;
  output Expression binaryExp;
  output Type resultType;
algorithm
  if Type.isComplex(Type.arrayElementType(type1)) or
     Type.isComplex(Type.arrayElementType(type2)) then
    (binaryExp,resultType) := checkBinaryOperationOperatorRecords(exp1, type1, operator, exp2, type2, info);
  else
    (binaryExp, resultType) := match operator.op
      case Op.ADD then checkBinaryOperationAdd(exp1, type1, exp2, type2, info);
      case Op.SUB then checkBinaryOperationSub(exp1, type1, exp2, type2, info);
      case Op.MUL then checkBinaryOperationMul(exp1, type1, exp2, type2, info);
      case Op.DIV then checkBinaryOperationDiv(exp1, type1, exp2, type2, info, isElementWise = false);
      case Op.POW then checkBinaryOperationPow(exp1, type1, exp2, type2, info);
      case Op.ADD_EW then checkBinaryOperationEW(exp1, type1, exp2, type2, Op.ADD, info);
      case Op.SUB_EW then checkBinaryOperationEW(exp1, type1, exp2, type2, Op.SUB, info);
      case Op.MUL_EW then checkBinaryOperationEW(exp1, type1, exp2, type2, Op.MUL, info);
      case Op.DIV_EW then checkBinaryOperationDiv(exp1, type1, exp2, type2, info, isElementWise = true);
      case Op.POW_EW then checkBinaryOperationPowEW(exp1, type1, exp2, type2, info);
    end match;
  end if;
end checkBinaryOperation;

public function checkBinaryOperationOperatorRecords
  input Expression inExp1;
  input Type inType1;
  input Operator inOp;
  input Expression inExp2;
  input Type inType2;
  input SourceInfo info;
  output Expression outExp;
  output Type outType;
protected
  String opstr;
  Function operfn;
  InstNode node1, node2;
  ComponentRef fn_ref;
  list<Function> candidates;
  Boolean matched, oper_defined;
  list<TypedArg> args;
  FunctionMatchKind matchKind;
  MatchedFunction matchedFunc;
  list<MatchedFunction> matchedFunctions = {}, exactMatches;
algorithm

  opstr := Operator.symbol(inOp,"'");

  candidates := {};
  if Type.isComplex(inType1) then
    Type.COMPLEX(cls=node1) := inType1;
    try
      fn_ref := Function.lookupFunctionSimple(opstr, node1);
      oper_defined := true;
    else
      oper_defined := false;
    end try;

    if oper_defined then
      fn_ref := Function.instFuncRef(fn_ref, InstNode.info(node1));
      for fn in Call.typeCachedFunctions(fn_ref) loop
        checkValidOperatorOverload(opstr, fn, node1);
        candidates := fn::candidates;
      end for;
    end if;
  end if;

  if Type.isComplex(inType2) then
    Type.COMPLEX(cls=node2) := inType2;

    // If the other operand is complex, make sure the two are not of the same class before collecting
    // operators from this one.
    if not (Type.isComplex(inType1) and InstNode.isSame(node1, node2)) then
        try
          fn_ref := Function.lookupFunctionSimple(opstr, node2);
          oper_defined := true;
        else
          oper_defined := false;
        end try;

        if oper_defined then
          fn_ref := Function.instFuncRef(fn_ref, InstNode.info(node2));
          for fn in Call.typeCachedFunctions(fn_ref) loop
            checkValidOperatorOverload(opstr, fn, node2);
            candidates := fn::candidates;
          end for;
        end if;
      end if;
  end if;
  candidates := listReverse(candidates);

  args := {(inExp1,inType1,Variability.CONSTANT),(inExp2,inType2,Variability.CONSTANT)};

  matchedFunctions := Function.matchFunctionsSilent(candidates, args, {}, info);
  // We only allow exact matches for operator overlaoding. e.g. no casting or generic matches.
  exactMatches := MatchedFunction.getExactMatches(matchedFunctions);

  if listEmpty(exactMatches) then
    // TODO: new error mentioning overloaded operators.
    if not listEmpty(candidates) then
      ErrorExt.setCheckpoint("NFTypeCheck:implicitConstruction");
      try
        (outExp, outType) := implicitConstructAndMatch(candidates, inExp1, inType1,inExp2, inType2);
        ErrorExt.delCheckpoint("NFTypeCheck:implicitConstruction");
        return;
      else
        ErrorExt.rollBack("NFTypeCheck:implicitConstruction");
        printUnresolvableTypeError(Expression.BINARY(inExp1, inOp, inExp2), {inType1, inType2}, info);
        fail();
      end try;
    else
      printUnresolvableTypeError(Expression.BINARY(inExp1, inOp, inExp2), {inType1, inType2}, info);
      fail();
    end if;
  end if;

  if listLength(exactMatches) == 1 then
    matchedFunc ::_ := exactMatches;
    outType := Function.returnType(matchedFunc.func);
    outExp := Expression.CALL(Call.TYPED_CALL(matchedFunc.func, outType, Variability.CONSTANT, list(Util.tuple31(a) for a in matchedFunc.args)
                                              , CallAttributes.CALL_ATTR(
                                                  outType, false, false, false, false, DAE.NO_INLINE(),DAE.NO_TAIL())
                                              )
                              );
  else
    Error.addSourceMessage(Error.AMBIGUOUS_MATCHING_OPERATOR_FUNCTIONS_NFINST,
          {Expression.toString(Expression.BINARY(inExp1, inOp, inExp2))
            , Call.candidateFuncListString(list(mfn.func for mfn in matchedFunctions))}, info);
    fail();
  end if;

end checkBinaryOperationOperatorRecords;

function implicitConstructAndMatch
  input list<Function> candidates;
  input Expression inExp1;
  input Type inType1;
  input Expression inExp2;
  input Type inType2;
  output Expression outExp;
  output Type outType;
protected
  list<InstNode> inputs;
  InstNode in1, in2, scope;
  MatchKind mk1,mk2;
  ComponentRef fn_ref;
  Function operfn;
  list<tuple<Function, list<Expression>, Variability>> matchedfuncs = {};
  Expression exp1,exp2;
  Type ty;
  Variability var;
algorithm

  exp1 := inExp1; exp2 := inExp2;
  for fn in candidates loop
    {in1,in2} := fn.inputs;
    (_, _, mk1) := matchTypes(InstNode.getType(in1),inType1,inExp1,false);
    (_, _, mk2) := matchTypes(InstNode.getType(in2),inType2,inExp2,false);

    // If the first argument matched the expected one, then we try
    // to construct the second argument to the class of the second input.
    if mk1 == MatchKind.EXACT then
      // We only want overloaded constructors when trying to implicitly construct. Default constructors are not considered.
      scope := InstNode.classScope(in2);
      (fn_ref, _, _) := Function.instFunc(Absyn.CREF_IDENT("'constructor'",{}),scope,InstNode.info(in2));
      exp2 := Expression.CALL(NFCall.UNTYPED_CALL(fn_ref, {inExp2}, {}, scope));
      (exp2, ty, var) := Call.typeCall(exp2, 0, InstNode.info(in1));
      matchedfuncs := (fn,{inExp1,exp2}, var)::matchedfuncs;
    elseif mk2 == MatchKind.EXACT then
      // We only want overloaded constructors when trying to implicitly construct. Default constructors are not considered.
      scope := InstNode.classScope(in1);
      (fn_ref, _, _) := Function.instFunc(Absyn.CREF_IDENT("'constructor'",{}),scope,InstNode.info(in1));
      exp1 := Expression.CALL(NFCall.UNTYPED_CALL(fn_ref, {inExp1}, {}, scope));
      (exp1, ty, var) := Call.typeCall(exp1, 0, InstNode.info(in2));
      matchedfuncs := (fn,{exp1,inExp2},var)::matchedfuncs;
    end if;
  end for;


  if listLength(matchedfuncs) == 1 then
    (operfn, {exp1,exp2}, var)::_ := matchedfuncs;
      outType := Function.returnType(operfn);
      outExp := Expression.CALL(Call.TYPED_CALL(operfn, outType, var, {exp1,exp2}
                                                , CallAttributes.CALL_ATTR(
                                                    outType, false, false, false, false, DAE.NO_INLINE(),DAE.NO_TAIL())
                                                )
                                );
    else
    // TODO: FIX ME: Add proper error message.
    print("Ambiguous operator: " + "\nCandidates:\n  ");
    print(Call.candidateFuncListString(list(Util.tuple31(fn) for fn in matchedfuncs)));
    print("\n");
    fail();
  end if;

end implicitConstructAndMatch;

function checkValidBinaryOperatorOverload
  input String oper_name;
  input Function oper_func;
  input InstNode rec_node;
protected
  SourceInfo info;
algorithm
  info := InstNode.info(oper_func.node);
  checkOneOutput(oper_name, oper_func.outputs, rec_node, info);
  checkOutputType(oper_name, List.first(oper_func.outputs), rec_node, info);
  checkTwoInputs(oper_name, oper_func.inputs, rec_node, info);
end checkValidBinaryOperatorOverload;

function checkValidOperatorOverload
  input String oper_name;
  input Function oper_func;
  input InstNode rec_node;
protected
  Type ty1, ty2;
  InstNode out_class;
algorithm
  () := match oper_name
    case "'constructor'" algorithm
      checkOneOutput(oper_name, oper_func.outputs, rec_node, InstNode.info(oper_func.node));
      checkOutputType(oper_name, List.first(oper_func.outputs), rec_node, InstNode.info(oper_func.node));
    then ();
    case "'0'" algorithm
      checkOneOutput(oper_name, oper_func.outputs, rec_node, InstNode.info(oper_func.node));
      checkOutputType(oper_name, List.first(oper_func.outputs), rec_node, InstNode.info(oper_func.node));
    then ();
    case "'+'" algorithm
      checkOneOutput(oper_name, oper_func.outputs, rec_node, InstNode.info(oper_func.node));
      checkOutputType(oper_name, List.first(oper_func.outputs), rec_node, InstNode.info(oper_func.node));
    then ();
    case "'-'" algorithm
      checkOneOutput(oper_name, oper_func.outputs, rec_node, InstNode.info(oper_func.node));
      checkOutputType(oper_name, List.first(oper_func.outputs), rec_node, InstNode.info(oper_func.node));
    then ();
    case "'*'" algorithm
      checkOneOutput(oper_name, oper_func.outputs, rec_node, InstNode.info(oper_func.node));
      checkOutputType(oper_name, List.first(oper_func.outputs), rec_node, InstNode.info(oper_func.node));
    then ();
    case "'/'" algorithm
      checkOneOutput(oper_name, oper_func.outputs, rec_node, InstNode.info(oper_func.node));
      checkOutputType(oper_name, List.first(oper_func.outputs), rec_node, InstNode.info(oper_func.node));
    then ();
    case "'^'" algorithm
      checkOneOutput(oper_name, oper_func.outputs, rec_node, InstNode.info(oper_func.node));
      checkOutputType(oper_name, List.first(oper_func.outputs), rec_node, InstNode.info(oper_func.node));
    then ();
    case "'and'" algorithm
      checkOneOutput(oper_name, oper_func.outputs, rec_node, InstNode.info(oper_func.node));
      checkOutputType(oper_name, List.first(oper_func.outputs), NFBuiltin.BOOLEAN_NODE, InstNode.info(oper_func.node));
    then ();
    case "'or'" algorithm
      checkOneOutput(oper_name, oper_func.outputs, rec_node, InstNode.info(oper_func.node));
      checkOutputType(oper_name, List.first(oper_func.outputs), NFBuiltin.BOOLEAN_NODE, InstNode.info(oper_func.node));
    then ();
    case "'not'" algorithm
      checkOneOutput(oper_name, oper_func.outputs, rec_node, InstNode.info(oper_func.node));
      checkOutputType(oper_name, List.first(oper_func.outputs), NFBuiltin.BOOLEAN_NODE, InstNode.info(oper_func.node));
    then ();
    case "'String'" algorithm
      checkOneOutput(oper_name, oper_func.outputs, rec_node, InstNode.info(oper_func.node));
      checkOutputType(oper_name, List.first(oper_func.outputs), NFBuiltin.STRING_NODE, InstNode.info(oper_func.node));
    then ();

    else ();

  end match;
end checkValidOperatorOverload;

public
function checkOneOutput
  input String oper_name;
  input list<InstNode> outputs;
  input InstNode rec_node;
  input SourceInfo info;
protected
  InstNode out_class;
algorithm
  if listLength(outputs) <> 1 then
      Error.addSourceMessage(Error.OPERATOR_OVERLOADING_WARNING,
          {"Overloaded " + oper_name + " operator functions are required to have exactly one output. Found "
          + intString(listLength(outputs))}, info);
  end if;
end checkOneOutput;

public
function checkTwoInputs
  input String oper_name;
  input list<InstNode> inputs;
  input InstNode rec_node;
  input SourceInfo info;
protected
  InstNode out_class;
algorithm
  if listLength(inputs) < 2 then
      Error.addSourceMessage(Error.OPERATOR_OVERLOADING_WARNING,
          {"Binary overloaded " + oper_name + " operator functions are required to have at least two inputs. Found "
          + intString(listLength(inputs))}, info);
  end if;
end checkTwoInputs;

function checkOutputType
  input String oper_name;
  input InstNode outc;
  input InstNode expected;
  input SourceInfo info;
protected
  InstNode out_class;
algorithm
  out_class := InstNode.classScope(outc);
  if not InstNode.isSame(out_class, expected) then
    Error.addSourceMessage(Error.OPERATOR_OVERLOADING_WARNING,
      {"Wrong type for output of overloaded operator function '"+ oper_name +
        "'. Expected '" + InstNode.scopeName(expected) + "' Found '" + InstNode.scopeName(outc) + "'"}, info);
  end if;
end checkOutputType;

function checkBinaryOperationAdd
  input Expression exp1;
  input Type type1;
  input Expression exp2;
  input Type type2;
  input SourceInfo info;
  output Expression binaryExp;
  output Type resultType;
protected
  Expression e1, e2;
  MatchKind mk;
  Boolean valid;
algorithm
  (e1, e2, resultType, mk) := matchExpressions(exp1, type1, exp2, type2, true);
  valid := isCompatibleMatch(mk);

  valid := match Type.arrayElementType(resultType)
    case Type.INTEGER() then valid;
    case Type.REAL() then valid;
    case Type.STRING() then valid;
    else false;
  end match;

  binaryExp := Expression.BINARY(e1, Operator.makeAdd(resultType), e2);

  if not valid then
    printUnresolvableTypeError(binaryExp, {type1, type2}, info);
  end if;
end checkBinaryOperationAdd;

function checkBinaryOperationSub
  input Expression exp1;
  input Type type1;
  input Expression exp2;
  input Type type2;
  input SourceInfo info;
  output Expression binaryExp;
  output Type resultType;
protected
  Expression e1, e2;
  MatchKind mk;
  Boolean valid;
algorithm
  (e1, e2, resultType, mk) := matchExpressions(exp1, type1, exp2, type2, true);
  valid := isCompatibleMatch(mk);

  valid := match Type.arrayElementType(resultType)
    case Type.INTEGER() then valid;
    case Type.REAL() then valid;
    else false;
  end match;

  binaryExp := Expression.BINARY(e1, Operator.makeSub(resultType), e2);

  if not valid then
    printUnresolvableTypeError(binaryExp, {type1, type2}, info);
  end if;
end checkBinaryOperationSub;

function checkBinaryOperationMul
  input Expression exp1;
  input Type type1;
  input Expression exp2;
  input Type type2;
  input SourceInfo info;
  output Expression binaryExp;
  output Type resultType;
protected
  Expression e1, e2;
  Type ty1, ty2;
  list<Dimension> dims1, dims2;
  Dimension dim11, dim12, dim21, dim22;
  MatchKind mk;
  Op op;
  Boolean valid;
algorithm
  ty1 := Type.arrayElementType(type1);
  ty2 := Type.arrayElementType(type2);
  (e1, e2, resultType, mk) := matchExpressions(exp1, ty1, exp2, ty2, true);
  valid := isCompatibleMatch(mk);

  valid := match resultType
    case Type.INTEGER() then valid;
    case Type.REAL() then valid;
    else false;
  end match;

  dims1 := Type.arrayDims(type1);
  dims2 := Type.arrayDims(type2);

  (resultType, op) := match (dims1, dims2)
    // scalar * scalar = scalar
    case ({}, {}) then (resultType, Op.MUL);
    // scalar * array = array
    case ({}, _) then (Type.ARRAY(resultType, dims2), Op.MUL_SCALAR_ARRAY);
    // array * scalar = array
    case (_, {}) then (Type.ARRAY(resultType, dims1), Op.MUL_ARRAY_SCALAR);
    // vector[n] * vector[n] = scalar
    case ({dim11}, {dim21})
      algorithm
        valid := Dimension.isEqual(dim11, dim21);
      then
        (resultType, Op.SCALAR_PRODUCT);

    // vector[n] * matrix[n, m] = vector[m]
    case ({dim11}, {dim21, dim22})
      algorithm
        valid := Dimension.isEqual(dim11, dim21);
      then
        (Type.ARRAY(resultType, {dim22}), Op.MUL_VECTOR_MATRIX);

    // matrix[n, m] * vector[m] = vector[n]
    case ({dim11, dim12}, {dim21})
      algorithm
        valid := Dimension.isEqual(dim12, dim21);
      then
        (Type.ARRAY(resultType, {dim11}), Op.MUL_MATRIX_VECTOR);

    // matrix[n, m] * matrix[m, p] = vector[n, p]
    case ({dim11, dim12}, {dim21, dim22})
      algorithm
        valid := Dimension.isEqual(dim12, dim21);
      then
        (Type.ARRAY(resultType, {dim11, dim22}), Op.MATRIX_PRODUCT);

    else
      algorithm
        valid := false;
      then
        (resultType, Op.MUL);
  end match;

  binaryExp := Expression.BINARY(e1, Operator.OPERATOR(resultType, op), e2);

  if not valid then
    printUnresolvableTypeError(binaryExp, {type1, type2}, info);
  end if;
end checkBinaryOperationMul;

function checkBinaryOperationDiv
  input Expression exp1;
  input Type type1;
  input Expression exp2;
  input Type type2;
  input SourceInfo info;
  input Boolean isElementWise;
  output Expression binaryExp;
  output Type resultType;
protected
  Expression e1, e2;
  Type ty1, ty2;
  MatchKind mk;
  Boolean valid;
  Operator op;
algorithm
  // Division always returns a Real value, so instead of checking if the types
  // are compatible with each other we check if each type is compatible with Real.
  (e1, ty1, mk) := matchTypes(type1, Type.setArrayElementType(type1, Type.REAL()), exp1, true);
  valid := isCompatibleMatch(mk);
  (e2, ty2, mk) := matchTypes(type2, Type.setArrayElementType(type2, Type.REAL()), exp2, true);
  valid := valid and isCompatibleMatch(mk);

  // Division is always element-wise, the only difference between / and ./ is
  // which operands they accept.
  (resultType, op) := match (Type.isArray(ty1), Type.isArray(ty2), isElementWise)
    // scalar / scalar or scalar ./ scalar
    case (false, false, _   ) then (ty1, Operator.makeDiv(ty1));
    // array / scalar or array ./ scalar
    case (_    , false, _   ) then (ty1, Operator.OPERATOR(ty1, Op.DIV_ARRAY_SCALAR));
    // scalar ./ array
    case (false, _    , true) then (ty2, Operator.OPERATOR(ty2, Op.DIV_SCALAR_ARRAY));

    // array ./ array
    case (true , _    , true)
      algorithm
        // If both operands are arrays, check that their dimensions are compatible.
        (_, _, mk) := matchArrayTypes(ty1, ty2, e1, true);
        valid := valid and isCompatibleMatch(mk);
      then
        (ty1, Operator.makeDiv(ty1));

    // Anything else is an error.
    else
      algorithm
        valid := false;
      then
        (ty1, Operator.makeDiv(ty1));
  end match;

  binaryExp := Expression.BINARY(e1, op, e2);

  if not valid then
    printUnresolvableTypeError(binaryExp, {type1, type2}, info);
  end if;
end checkBinaryOperationDiv;

function checkBinaryOperationPow
  input Expression exp1;
  input Type type1;
  input Expression exp2;
  input Type type2;
  input SourceInfo info;
  output Expression binaryExp;
  output Type resultType;
protected
  Expression e1, e2;
  MatchKind mk;
  Boolean valid;
  Operator op;
algorithm
  // The first operand of ^ should be Real.
  (e1, resultType, mk) := matchTypes(type1, Type.setArrayElementType(type1, Type.REAL()), exp1, true);
  valid := isCompatibleMatch(mk);

  if Type.isArray(resultType) then
    // Real[n, n] ^ Integer
    valid := valid and Type.isSquareMatrix(resultType);
    valid := valid and Type.isInteger(type2);
    op := Operator.OPERATOR(resultType, Op.POW_MATRIX);
    e2 := exp2;
  else
    // Real ^ Real
    (e2, _, mk) := matchTypes(type2, Type.REAL(), exp2, true);
    valid := valid and isCompatibleMatch(mk);
    op := Operator.OPERATOR(resultType, Op.POW);
  end if;

  binaryExp := Expression.BINARY(e1, op, e2);

  if not valid then
    printUnresolvableTypeError(binaryExp, {type1, type2}, info);
  end if;
end checkBinaryOperationPow;

function checkBinaryOperationPowEW
  input Expression exp1;
  input Type type1;
  input Expression exp2;
  input Type type2;
  input SourceInfo info;
  output Expression binaryExp;
  output Type resultType;
protected
  Expression e1, e2;
  Type ty1, ty2;
  MatchKind mk;
  Boolean valid;
  Operator op;
algorithm
  // Exponentiation always returns a Real value, so instead of checking if the types
  // are compatible with ecah other we check if each type is compatible with Real.
  (e1, ty1, mk) := matchTypes(type1, Type.setArrayElementType(type1, Type.REAL()), exp1, true);
  valid := isCompatibleMatch(mk);
  (e2, ty2, mk) := matchTypes(type2, Type.setArrayElementType(type2, Type.REAL()), exp2, true);
  valid := valid and isCompatibleMatch(mk);

  (resultType, op) := match (Type.isArray(ty1), Type.isArray(ty2))
    // scalar .^ scalar
    case (false, false) then (ty1, Operator.makePow(ty1));
    // array .^ scalar
    case (_    , false) then (ty1, Operator.OPERATOR(ty1, Op.POW_ARRAY_SCALAR));
    // scalar .^ array
    case (false, _    ) then (ty2, Operator.OPERATOR(ty2, Op.POW_SCALAR_ARRAY));
    // array .^ array
    else
      algorithm
        // If both operands are arrays, check that their dimensions are compatible.
        (_, _, mk) := matchArrayTypes(ty1, ty2, e1, true);
        valid := valid and isCompatibleMatch(mk);
      then
        (ty1, Operator.makePow(ty1));
  end match;

  binaryExp := Expression.BINARY(e1, op, e2);

  if not valid then
    printUnresolvableTypeError(binaryExp, {type1, type2}, info);
  end if;
end checkBinaryOperationPowEW;

function checkBinaryOperationEW
  input Expression exp1;
  input Type type1;
  input Expression exp2;
  input Type type2;
  input Op elemOp;
  input SourceInfo info;
  output Expression binaryExp;
  output Type resultType;
protected
  Expression e1, e2;
  Type ty1, ty2;
  MatchKind mk;
  Boolean valid, is_arr1, is_arr2;
  Operator op;
algorithm
  is_arr1 := Type.isArray(type1);
  is_arr2 := Type.isArray(type2);

  if is_arr1 and is_arr2 then
    // The expressions must be type compatible if they are both arrays.
    (e1, e2, resultType, mk) := matchExpressions(exp1, type1, exp2, type2, true);
  else
    // Otherwise it's enough if their element types are compatible.
    ty1 := Type.arrayElementType(type1);
    ty2 := Type.arrayElementType(type2);
    (e1, e2, resultType, mk) := matchExpressions(exp1, ty1, exp2, ty2, true);
  end if;

  valid := isCompatibleMatch(mk);

  // Check that the type is valid for the operation.
  valid := match (Type.arrayElementType(resultType), elemOp)
    case (Type.INTEGER(), _) then valid;
    case (Type.REAL(), _) then valid;
    case (Type.STRING(), Op.ADD) then valid;
    else false;
  end match;

  (resultType, op) := match (is_arr1, is_arr2)
    // array * scalar => Op.{elemOp}_ARRAY_SCALAR.
    case (true, false)
      algorithm
        resultType := Type.copyDims(type1, resultType);
        op := Operator.makeArrayScalar(resultType, elemOp);
      then
        (resultType, op);

    // scalar * array => Op.{elemOp}_SCALAR_ARRAY;
    case (false, true)
      algorithm
        resultType := Type.copyDims(type2, resultType);
        op := Operator.makeScalarArray(resultType, elemOp);
      then
        (resultType, op);

    // scalar * scalar and array * array => elemOp.
    else (resultType, Operator.OPERATOR(resultType, elemOp));
  end match;

  binaryExp := Expression.BINARY(e1, op, e2);

  if not valid then
    printUnresolvableTypeError(binaryExp, {type1, type2}, info);
  end if;
end checkBinaryOperationEW;

public function checkUnaryOperation
  input Expression exp1;
  input Type type1;
  input Operator operator;
  input SourceInfo info;
  output Expression unaryExp;
  output Type unaryType;
protected
  Boolean valid = true;
  Operator op;
algorithm
  if Type.isComplex(Type.arrayElementType(type1)) then
    (unaryExp,unaryType) := checkUnaryOperationOperatorRecords(exp1, type1, operator, info);
    return;
  end if;

  unaryType := type1;
  op := Operator.setType(unaryType, operator);

  unaryExp := match operator.op
    case Op.ADD then exp1; // + is a no-op for arithmetic unary operations.
    else Expression.UNARY(op, exp1);
  end match;

  if not Type.isNumeric(type1) then
    printUnresolvableTypeError(unaryExp, {type1}, info);
  end if;
end checkUnaryOperation;

public function checkUnaryOperationOperatorRecords
  input Expression inExp1;
  input Type inType1;
  input Operator inOp;
  input SourceInfo info;
  output Expression outExp;
  output Type outType;
protected
  String opstr;
  Function operfn;
  InstNode node1, fn_node;
  ComponentRef fn_ref;
  list<Function> candidates;
  Boolean matched;
  list<TypedArg> args;
  FunctionMatchKind matchKind;
  MatchedFunction matchedFunc;
  list<MatchedFunction> matchedFunctions = {}, exactMatches;
algorithm

  opstr := Operator.symbol(inOp,"'");
  Type.COMPLEX(cls=node1) := inType1;

  fn_ref := Function.lookupFunctionSimple(opstr, node1);
  fn_ref := Function.instFuncRef(fn_ref, InstNode.info(node1));
  candidates := Call.typeCachedFunctions(fn_ref);
  for fn in candidates loop
    checkValidOperatorOverload(opstr, fn, node1);
  end for;

  args := {(inExp1,inType1,Variability.CONSTANT)};
  matchedFunctions := Function.matchFunctionsSilent(candidates, args, {}, info);

  // We only allow exact matches for operator overlaoding. e.g. no casting or generic matches.
  exactMatches := MatchedFunction.getExactMatches(matchedFunctions);
  if listEmpty(exactMatches) then
    printUnresolvableTypeError(Expression.UNARY(inOp, inExp1), {inType1}, info);
    fail();
  end if;

  if listLength(exactMatches) == 1 then
    matchedFunc ::_ := exactMatches;
    outType := Function.returnType(matchedFunc.func);
    outExp := Expression.CALL(Call.TYPED_CALL(matchedFunc.func, outType, Variability.CONSTANT, list(Util.tuple31(a) for a in matchedFunc.args)
                                              , CallAttributes.CALL_ATTR(
                                                  outType, false, false, false, false, DAE.NO_INLINE(),DAE.NO_TAIL())
                                              )
                              );
  else
    Error.addSourceMessage(Error.AMBIGUOUS_MATCHING_OPERATOR_FUNCTIONS_NFINST,
          {Expression.toString(Expression.UNARY(inOp, inExp1))
            , Call.candidateFuncListString(list(mfn.func for mfn in matchedFunctions))}, info);
    fail();
  end if;

end checkUnaryOperationOperatorRecords;

function checkLogicalBinaryOperation
  input Expression exp1;
  input Type type1;
  input Operator operator;
  input Expression exp2;
  input Type type2;
  input SourceInfo info;
  output Expression outExp;
  output Type resultType;
protected
  Expression e1, e2;
  MatchKind mk;
algorithm

  if Type.isComplex(Type.arrayElementType(type1)) or
    Type.isComplex(Type.arrayElementType(type2)) then
    (outExp,resultType) := checkBinaryOperationOperatorRecords(exp1, type1, operator, exp2, type2, info);
    return;
  end if;


  (e1, e2, resultType, mk) := matchExpressions(exp1, type1, exp2, type2, true);
  outExp := Expression.LBINARY(e1, Operator.setType(resultType, operator), e2);

  if not isCompatibleMatch(mk) or
     not Type.isBoolean(Type.arrayElementType(resultType)) then
    printUnresolvableTypeError(outExp, {type1, type2}, info);
  end if;
end checkLogicalBinaryOperation;

function checkLogicalUnaryOperation
  input Expression exp1;
  input Type type1;
  input Operator operator;
  input SourceInfo info;
  output Expression outExp;
  output Type resultType = type1;
protected
  Expression e1, e2;
  MatchKind mk;
algorithm

  if Type.isComplex(Type.arrayElementType(type1)) then
    (outExp,resultType) := checkUnaryOperationOperatorRecords(exp1, type1, operator, info);
    return;
  end if;

  outExp := Expression.LUNARY(Operator.setType(type1, operator), exp1);

  if not Type.isBoolean(Type.arrayElementType(type1)) then
    printUnresolvableTypeError(outExp, {type1}, info);
  end if;
end checkLogicalUnaryOperation;

function checkRelationOperation
  input Expression exp1;
  input Type type1;
  input Operator operator;
  input Expression exp2;
  input Type type2;
  input ExpOrigin.Type origin;
  input SourceInfo info;
  output Expression outExp;
  output Type resultType;
protected
  Expression e1, e2;
  Type ty;
  MatchKind mk;
  Boolean valid;
  Op o;
algorithm

  if Type.isComplex(Type.arrayElementType(type1)) or
    Type.isComplex(Type.arrayElementType(type2)) then
    (outExp,resultType) := checkBinaryOperationOperatorRecords(exp1, type1, operator, exp2, type2, info);
    return;
  end if;

  (e1, e2, ty, mk) := matchExpressions(exp1, type1, exp2, type2);
  valid := isCompatibleMatch(mk);

  resultType := Type.BOOLEAN();
  outExp := Expression.RELATION(e1, Operator.setType(ty, operator), e2);

  valid := match ty
    case Type.INTEGER() then valid;
    case Type.REAL()
      algorithm
        // Print a warning for == or <> with Real operands in a model.
        o := operator.op;
        if intBitAnd(origin, ExpOrigin.FUNCTION) == 0 and (o == Op.EQUAL or o == Op.NEQUAL) then
          Error.addSourceMessage(Error.WARNING_RELATION_ON_REAL,
            {"<NO COMPONENT>", Expression.toString(outExp), Operator.symbol(operator)}, info);
        end if;
      then
        valid;
    case Type.STRING() then valid;
    case Type.BOOLEAN() then valid;
    case Type.ENUMERATION() then valid;
    else false;
  end match;

  if not valid then
    printUnresolvableTypeError(outExp, {type1, type2}, info);
  end if;
end checkRelationOperation;

function printUnresolvableTypeError
  input Expression exp;
  input list<Type> types;
  input SourceInfo info;
protected
  String exp_str, ty_str;
algorithm
  exp_str := Expression.toString(exp);
  ty_str := List.toString(types, Type.toString, "", "", ", ", "", false);
  Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {exp_str, ty_str, "<NO_COMPONENT>"}, info);
  fail();
end printUnresolvableTypeError;

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
  input Boolean allowUnknown = false; // TODO: This allowUnknown is currently used for two different things.
                                      // Allowing matches againest unknown types AND also allowing matching
                                      // when dim sizes are unknown. These should be separated.
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
        Error.assertion(false, getInstanceName() + " got unknown type.", sourceInfo());
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
        output MatchKind matchKind = MatchKind.NOT_COMPATIBLE;
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

  // TODO: revise this.
  if InstNode.isSame(anode, enode) then
    matchKind := MatchKind.EXACT;
    return;
  end if;

  cls1 := InstNode.getClass(anode);
  cls2 := InstNode.getClass(enode);

  () := match (cls1, cls2, expression)

    case (Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps1)),
          Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps2)),
          Expression.RECORD(elements = elements))
      algorithm
        matchKind := MatchKind.PLUG_COMPATIBLE;

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
            elseif not isValidPlugCompatibleMatch(mk) then
              matchKind := MatchKind.NOT_COMPATIBLE;
              break;
            end if;
          end for;

          if matchKind == MatchKind.CAST then
            expression.elements := listReverse(matched_elements);
          end if;
        end if;

        if matchKind <> MatchKind.NOT_COMPATIBLE then
          matchKind := MatchKind.PLUG_COMPATIBLE;
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

        if matchKind <> MatchKind.NOT_COMPATIBLE then
          matchKind := MatchKind.PLUG_COMPATIBLE;
        end if;

      then
        ();

    case (Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps1)),
          Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps2)), _)
      algorithm
        matchKind := MatchKind.PLUG_COMPATIBLE;

        if arrayLength(comps1) <> arrayLength(comps2) then
          matchKind := MatchKind.NOT_COMPATIBLE;
        else
          for i in 1:arrayLength(comps1) loop
            (_, _, mk) := matchTypes(InstNode.getType(comps1[i]), InstNode.getType(comps2[i]), expression, allowUnknown);

            if not isValidPlugCompatibleMatch(mk) then
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
      // We lift the array which means we have to iterate in theopposite order
      dims1 := listReverse(dims1);
      dims2 := listReverse(dims2);
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
  output Boolean compatible;
algorithm
  if Dimension.isEqual(dim1, dim2) then
    compatibleDim := dim1;
    compatible := true;
  else
    if not Dimension.isKnown(dim1) then
      compatibleDim := dim2;
      compatible := true;
    elseif not Dimension.isKnown(dim2) then
      compatibleDim := dim1;
      compatible := true;
    else
      compatibleDim := dim1;
      compatible := false;
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

    case (_, Type.POLYMORPHIC())
      algorithm
        expression := Expression.BOX(expression);
        // matchKind := MatchKind.GENERIC(expectedType.b,actualType);
      then
        (Type.METABOXED(actualType), MatchKind.GENERIC);

    case (Type.POLYMORPHIC(), _)
      algorithm
        // expression := Expression.UNBOX(expression, Expression.typeOf(expression));
        // matchKind := MatchKind.GENERIC(expectedType.b,actualType);
      then
        (expectedType, MatchKind.GENERIC);

    // Expected type is any, any actual type matches.
    case (_, Type.ANY()) then (expectedType, MatchKind.EXACT);

    // Anything else is not compatible.
    else (Type.UNKNOWN(), MatchKind.NOT_COMPATIBLE);
  end match;
end matchTypes_cast;

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
      then Dimension.fromInteger(max(stopExp.value - startExp.value + 1, 0));

    case (Expression.INTEGER(), SOME(Expression.INTEGER(value = step)), Expression.INTEGER())
      algorithm
        // Don't allow infinite ranges.
        if step == 0 then
          Error.addSourceMessageAndFail(Error.RANGE_TOO_SMALL_STEP, {String(step)}, info);
        end if;
      then
        Dimension.fromInteger(max(intDiv(stopExp.value - startExp.value, step) + 1, 0));

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
      Real start, step;

    case (Expression.REAL(), NONE(), Expression.REAL())
      then Dimension.fromInteger(Util.realRangeSize(startExp.value, 1.0, stopExp.value));

    case (Expression.REAL(value = start), SOME(Expression.REAL(value = step)), Expression.REAL())
      algorithm
        // Check that adding step to start actually produces a different value,
        // otherwise the step size is too small.
        if start == start + step then
          Error.addSourceMessageAndFail(Error.RANGE_TOO_SMALL_STEP, {String(step)}, info);
        end if;
      then
        Dimension.fromInteger(Util.realRangeSize(startExp.value, step, stopExp.value));

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
        Dimension.fromInteger(sz);

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
      then Dimension.fromInteger(max(stopExp.index - startExp.index + 1, 0));

    else Dimension.UNKNOWN();
  end match;
end getRangeTypeEnum;

function matchBinding
  input output Binding binding;
  input Type componentType;
  input String name;
  input InstNode parent;
algorithm
  () := match binding
    local
      MatchKind ty_match;
      Expression exp;
      Type ty, comp_ty;
      InstNode next_parent;
      list<list<Dimension>> dims;
      Integer binding_level;

    case Binding.TYPED_BINDING()
      algorithm
        comp_ty := componentType;
        binding_level := BindingOrigin.level(binding.origin);

        if not binding.isEach and binding_level > 0 then
          next_parent := parent;
          dims := {};

          for i in 1:binding_level loop
            dims := Type.arrayDims(InstNode.getType(next_parent)) :: dims;
            next_parent := InstNode.derivedParent(next_parent);
          end for;

          comp_ty := Type.liftArrayLeftList(comp_ty, List.flatten(dims));
        end if;

        (exp, ty, ty_match) := matchTypes(binding.bindingType, comp_ty, binding.bindingExp, true);

        if not isValidBindingMatch(ty_match) then
          Error.addSourceMessage(Error.VARIABLE_BINDING_TYPE_MISMATCH,
            {name, Binding.toString(binding), Type.toString(comp_ty),
             Type.toString(binding.bindingType)}, Binding.getInfo(binding));
          fail();
        elseif isCastMatch(ty_match) then
          binding := Binding.TYPED_BINDING(exp, ty, binding.variability, binding.origin, binding.isEach);
        end if;
      then
        ();

    case Binding.UNBOUND() then ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got untyped binding " + Binding.toString(binding), sourceInfo());
      then
        fail();
  end match;
end matchBinding;

function checkDimensionType
  "Checks that an expression used as a dimension has a valid type for a
   dimension, otherwise prints an error and fails."
  input Expression exp;
  input Type ty;
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
end checkDimensionType;

annotation(__OpenModelica_Interface="frontend");
end NFTypeCheck;
