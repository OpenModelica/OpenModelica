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

public import Absyn;
public import NFConnect2;
public import DAE;
public import HashTablePathToFunction;
public import NFInstSymbolTable;
public import NFInstTypes;
public import NFTyping;
public import DAEDump;
public import Util;

public type Binding = NFInstTypes.Binding;
public type Class = NFInstTypes.Class;
public type Component = NFInstTypes.Component;
public type Connections = NFConnect2.Connections;
public type Connector = NFConnect2.Connector;
public type ConnectorType = NFConnect2.ConnectorType;
public type DaePrefixes = NFInstTypes.DaePrefixes;
public type Dimension = NFInstTypes.Dimension;
public type Element = NFInstTypes.Element;
public type Equation = NFInstTypes.Equation;
public type Face = NFConnect2.Face;
public type Function = NFInstTypes.Function;
public type FunctionTable = HashTablePathToFunction.HashTable;
public type Modifier = NFInstTypes.Modifier;
public type ParamType = NFInstTypes.ParamType;
public type Prefixes = NFInstTypes.Prefixes;
public type Statement = NFInstTypes.Statement;
public type SymbolTable = NFInstSymbolTable.SymbolTable;
public type Context = NFTyping.Context;
public type EvalPolicy = NFTyping.EvalPolicy;

protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import NFInstUtil;
protected import List;
protected import Types;


public function checkClassComponents
  input Class inClass;
  input Context inContext;
  input SymbolTable inSymbolTable;
  output Class outClass;
  output SymbolTable outSymbolTable;
algorithm
  (outClass, outSymbolTable) :=
    checkClass(inClass, NONE(), inContext, inSymbolTable);
end checkClassComponents;

public function checkClass
  input Class inClass;
  input Option<Component> inParent;
  input Context inContext;
  input SymbolTable inSymbolTable;
  output Class outClass;
  output SymbolTable outSymbolTable;
algorithm
  (outClass, outSymbolTable) := match(inClass, inParent, inContext, inSymbolTable)
    local
      list<Element> comps;
      list<Equation> eq, ieq;
      list<list<Statement>> al, ial;
      SymbolTable st;
      Absyn.Path name;

    case (NFInstTypes.BASIC_TYPE(_), _, _, st) then (inClass, st);

    case (NFInstTypes.COMPLEX_CLASS(name, comps, eq, ieq, al, ial), _, _, st)
      equation
        (comps, st) = List.map2Fold(comps, checkElement, inParent, inContext, st);
      then
        (NFInstTypes.COMPLEX_CLASS(name, comps, eq, ieq, al, ial), st);

  end match;
end checkClass;

protected function checkElement
  input Element inElement;
  input Option<Component> inParent;
  input Context inContext;
  input SymbolTable inSymbolTable;
  output Element outElement;
  output SymbolTable outSymbolTable;
algorithm
  (outElement, outSymbolTable) :=
  match(inElement, inParent, inContext, inSymbolTable)
    local
      Component comp;
      Class cls;
      Absyn.Path name;
      SymbolTable st;
      SourceInfo info;
      String str;

    case (NFInstTypes.ELEMENT(NFInstTypes.UNTYPED_COMPONENT(name = name, info = info), _),
        _, _, _)
      equation
        str = "Found untyped component: " + Absyn.pathString(name);
        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, info);
      then
        fail();

    case (NFInstTypes.ELEMENT(comp, cls), _, _, st)
      equation
        (comp, st)= checkComponent(comp, inParent, inContext, st);
        (cls, st) = checkClass(cls, SOME(comp), inContext, st);
      then
        (NFInstTypes.ELEMENT(comp, cls), st);

    case (NFInstTypes.CONDITIONAL_ELEMENT(_), _, _, _)
      then (inElement, inSymbolTable);

  end match;
end checkElement;

protected function checkComponent
  input Component inComponent;
  input Option<Component> inParent;
  input Context inContext;
  input SymbolTable inSymbolTable;
  output Component outComponent;
  output SymbolTable outSymbolTable;
algorithm
  (outComponent, outSymbolTable) :=
  match(inComponent, inParent, inContext, inSymbolTable)
    local
      Absyn.Path name;
      DAE.Type ty;
      Binding binding;
      SymbolTable st;
      Component comp, inner_comp;
      Context c;
      String str;
      SourceInfo info;

    case (NFInstTypes.UNTYPED_COMPONENT(name = name,  info = info),
        _, _, _)
      equation
        str = "Found untyped component: " + Absyn.pathString(name);
        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, info);
      then
        fail();

    // check and convert if needed the type of
    // the binding vs the type of the component
    case (NFInstTypes.TYPED_COMPONENT(), _, _, st)
      equation
        comp = NFInstUtil.setComponentParent(inComponent, inParent);
        comp = checkComponentBindingType(comp);
      then
        (comp, st);

    case (NFInstTypes.OUTER_COMPONENT(innerName = SOME(name)), _, _, st)
      equation
        comp = NFInstSymbolTable.lookupName(name, st);
        (comp, st) = checkComponent(comp, inParent, inContext, st);
      then
        (comp, st);

    case (NFInstTypes.OUTER_COMPONENT( innerName = NONE()), _, _, st)
      equation
        (_, SOME(inner_comp), st) = NFInstSymbolTable.updateInnerReference(inComponent, st);
        (inner_comp, st) = checkComponent(inner_comp, inParent, inContext, st);
      then
        (inner_comp, st);

    case (NFInstTypes.CONDITIONAL_COMPONENT(name = name), _, _, _)
      equation
        print("Trying to type conditional component " + Absyn.pathString(name) + "\n");
      then
        fail();

    case (NFInstTypes.DELETED_COMPONENT(), _, _, st)
      then (inComponent, st);

  end match;
end checkComponent;

protected function checkComponentBindingType
  input Component inC;
  output Component outC;
algorithm
  outC := matchcontinue (inC)
    local
      DAE.Type ty, propagatedTy, convertedTy;
      Absyn.Path name, eName;
      Option<Component> parent;
      DaePrefixes prefixes;
      Binding binding;
      SourceInfo info;
      DAE.Exp bindingExp;
      DAE.Type bindingType;
      Integer propagatedDims "See NFSCodeMod.propagateMod.";
      SourceInfo binfo;
      String nStr, eStr, etStr, btStr;
      DAE.Dimensions parentDimensions;

    // nothing to check
    case (NFInstTypes.TYPED_COMPONENT(binding = NFInstTypes.UNBOUND()))
      then
        inC;

    // when the component name is equal to the component type we have a constant enumeration!
    // StateSelect = {StateSelect.always, StateSelect.prefer, StateSelect.default, StateSelect.avoid, StateSelect.never}
    case (NFInstTypes.TYPED_COMPONENT(name = name, ty = DAE.T_ENUMERATION(path = eName)))
      equation
        true = Absyn.pathEqual(name, eName);
      then
        inC;

    case (NFInstTypes.TYPED_COMPONENT(name, ty, parent, prefixes, binding, info))
      equation
        NFInstTypes.TYPED_BINDING(bindingExp, bindingType, propagatedDims, binfo) = binding;
        parentDimensions = getParentDimensions(parent, {});
        propagatedTy = liftArray(ty, parentDimensions, propagatedDims);
        (bindingExp, convertedTy) = Types.matchType(bindingExp, bindingType, propagatedTy, true);
        binding = NFInstTypes.TYPED_BINDING(bindingExp, convertedTy, propagatedDims, binfo);
      then
        NFInstTypes.TYPED_COMPONENT(name, ty, parent, prefixes, binding, info);

    case (NFInstTypes.TYPED_COMPONENT(name, ty, parent, _, binding, info))
      equation
        NFInstTypes.TYPED_BINDING(bindingExp, bindingType, propagatedDims, _) = binding;
        parentDimensions = getParentDimensions(parent, {});
        propagatedTy = liftArray(ty, parentDimensions, propagatedDims);
        failure((_, _) = Types.matchType(bindingExp, bindingType, propagatedTy, true));
        nStr = Absyn.pathString(name);
        eStr = ExpressionDump.printExpStr(bindingExp);
        etStr = Types.unparseTypeNoAttr(propagatedTy);
        etStr = etStr + " propDim: " + intString(propagatedDims);
        btStr = Types.unparseTypeNoAttr(bindingType);
        Error.addSourceMessage(Error.VARIABLE_BINDING_TYPE_MISMATCH,
        {nStr, eStr, etStr, btStr}, info);
      then
        fail();

    else
      equation
        //name = NFInstUtil.getComponentName(inC);
        //nStr = "Found untyped component: " + Absyn.pathString(name);
        //Error.addMessage(Error.INTERNAL_ERROR, {nStr});
      then
        fail();

  end matchcontinue;
end checkComponentBindingType;

protected function getParentDimensions
"get the dimensions from the parents of the component up to the root"
  input Option<Component> inParentOpt;
  input DAE.Dimensions inDimensionsAcc;
  output DAE.Dimensions outDimensions;
algorithm
  outDimensions := matchcontinue(inParentOpt, inDimensionsAcc)
    local
      Component c;
      DAE.Dimensions dims;

    case (NONE(), _) then inDimensionsAcc;

    case (SOME(c), _)
      equation
        dims = NFInstUtil.getComponentTypeDimensions(c);
        dims = listAppend(dims, inDimensionsAcc);
        dims = getParentDimensions(NFInstUtil.getComponentParent(c), dims);
      then
        dims;
    // for other...
    case (SOME(_), _) then inDimensionsAcc;
  end matchcontinue;
end getParentDimensions;

protected function liftArray
 input DAE.Type inTy;
 input DAE.Dimensions inParentDimensions;
 input Integer inPropagatedDims;
 output DAE.Type outTy;
algorithm
 outTy := matchcontinue(inTy, inParentDimensions, inPropagatedDims)
   local
     Integer pdims;
     DAE.Type ty;
     DAE.Dimensions dims;
     DAE.TypeSource ts;

   case (_, _, -1) then inTy;
   // TODO! FIXME! check if we can actually have propagated dims of 0
   case (_, {}, 0) then inTy;
   // we have some parent dims
   case (_, _::_, 0)
     equation
       ts = Types.getTypeSource(inTy);
       ty = DAE.T_ARRAY(inTy, inParentDimensions, ts);
     then ty;
   // we can take the lastN from the propagated dims!
   case (_, _, pdims)
     equation
       false = Types.isArray(inTy);
       ts = Types.getTypeSource(inTy);
       dims = List.lastN(inParentDimensions, pdims);
       ty = DAE.T_ARRAY(inTy, dims, ts);
     then
       ty;
   // we can take the lastN from the propagated dims!
   case (_, _, pdims)
     equation
       true = Types.isArray(inTy);
       ty = Types.unliftArray(inTy);
       ts = Types.getTypeSource(inTy);
       dims = listAppend(inParentDimensions, Types.getDimensions(inTy));
       dims = List.lastN(dims, pdims);
       ty = DAE.T_ARRAY(ty, dims, ts);
     then
       ty;
    case (_, {}, _) then inTy;
    else DAE.T_ARRAY(inTy, inParentDimensions, DAE.emptyTypeSource);
  end matchcontinue;
end liftArray;

public function checkExpEquality
  input DAE.Exp inExp1;
  input DAE.Type inTy1;
  input DAE.Exp inExp2;
  input DAE.Type inTy2;
  input String inMessage;
  input SourceInfo inInfo;
  output DAE.Exp outExp1;
  output DAE.Type outTy1;
  output DAE.Exp outExp2;
  output DAE.Type outTy2;
algorithm
  (outExp1, outTy1, outExp2, outTy2) := matchcontinue(inExp1, inTy1, inExp2, inTy2, inMessage, inInfo)
    local
      DAE.Exp e;
      DAE.Type t;
      String e1Str, t1Str, e2Str, t2Str, s1, s2;

    // Check if the Rhs matchs/can be converted to match the Lhs
    case (_, _, _, _, _, _)
      equation
        (e, t) = Types.matchType(inExp2, inTy2, inTy1, true);
      then
        (inExp1, inTy1, e, t);

    // the other way arround just for equations!
    case (_, _, _, _, "equ", _)
      equation
        (e, t) = Types.matchType(inExp1, inTy1, inTy2, true);
      then
        (e, t, inExp2, inTy2);

    // not really fine!
    case (_, _, _, _, "equ", _)
      equation
        e1Str = ExpressionDump.printExpStr(inExp1);
        t1Str = Types.unparseTypeNoAttr(inTy1);
        e2Str = ExpressionDump.printExpStr(inExp2);
        t2Str = Types.unparseTypeNoAttr(inTy2);
        s1 = stringAppendList({e1Str,"=",e2Str});
        s2 = stringAppendList({t1Str,"=",t2Str});
        Error.addSourceMessage(Error.EQUATION_TYPE_MISMATCH_ERROR, {s1,s2}, inInfo);
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFTypeCheck.checkExpEquality failed with type mismatch: " + s1 + " tys: " + s2);
      then
        fail();

    case (_, _, _, _, "alg", _)
      equation
        e1Str = ExpressionDump.printExpStr(inExp1);
        t1Str = Types.unparseTypeNoAttr(inTy1);
        e2Str = ExpressionDump.printExpStr(inExp2);
        t2Str = Types.unparseTypeNoAttr(inTy2);
        s1 = stringAppendList({e1Str,":=",e2Str});
        s2 = stringAppendList({t1Str,":=",t2Str});
        Error.addSourceMessage(Error.ASSIGN_TYPE_MISMATCH_ERROR, {e1Str,e2Str,t1Str,t2Str}, inInfo);
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFTypeCheck.checkExpEquality failed with type mismatch: " + s1 + " tys: " + s2);
      then
        fail();
  end matchcontinue;
end checkExpEquality;




// ************************************************************** //
//   BEGIN: Operator typing helper functions
// ************************************************************** //


public function checkLogicalBinaryOperation
  "mahge:
  Type checks logical binary operations. operations on scalars are handled
  simply by using Types.matchType().
  Operations involving Complex types are handled differently."
  input DAE.Exp inExp1;
  input DAE.Type inType1;
  input DAE.Operator inOp;
  input DAE.Exp inExp2;
  input DAE.Type inType2;
  output DAE.Exp outExp;
  output DAE.Type outType;
algorithm
  (outExp,outType) := matchcontinue(inExp1,inType1,inOp,inExp2,inType2)
    local
      DAE.Exp exp1,exp2,exp;
      DAE.Type ty;
      String e1Str, t1Str, e2Str, t2Str, s1, s2, sugg;
      Boolean isarr1,isarr2;
      DAE.Operator newop;


    // Logical binary operations here are allowed only on Booleans.
    // The Modelica Specification 3.2 doesn't say anything if they should be allowed or not on scalars of type Integers/Reals.
    // It says no for arrays of Integer/Real type.
    case(_,_,_,_,_)
      equation
        true = Types.isBoolean(inType1);
        true = Types.isBoolean(inType2);

        // If they are arrays we need this to match dims.
        (exp1,exp2,ty) = matchTypeBothWays(inExp1,inType1,inExp2,inType2);

        newop = Expression.setOpType(inOp, ty);

        exp = DAE.RELATION(exp1, newop, exp2, -1, NONE());
      then
        (exp,ty);


    // Check if we have relational logical operations involving non-boolean types.
    // Just for proper error messages.
    case(_,_,_,_,_)
      equation
        isarr1 = Types.isBoolean(inType1);
        isarr2 = Types.isBoolean(inType2);

        // If one of them is not boolean.
        false = isarr1 and isarr2;

        e1Str = ExpressionDump.printExpStr(inExp1);
        t1Str = Types.unparseType(inType1);
        e2Str = ExpressionDump.printExpStr(inExp2);
        t2Str = Types.unparseType(inType2);
        sugg = "\n: Logical operations involving non-boolean types are not valid in Modelica.";
        s1 = "' " + e1Str + DAEDump.dumpOperatorSymbol(inOp) + e2Str + " '";
        s2 = "' " + t1Str + DAEDump.dumpOperatorString(inOp) + t2Str + " '";
        Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1,s2,sugg}, Absyn.dummyInfo);
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFTypeCheck.ccheckLogicalBinaryOperation failed with type mismatch: " + t1Str + " tys: " + t2Str);
      then
        fail();


    else
      equation
        e1Str = ExpressionDump.printExpStr(inExp1);
        t1Str = Types.unparseType(inType1);
        e2Str = ExpressionDump.printExpStr(inExp2);
        t2Str = Types.unparseType(inType2);
        s1 = "' " + e1Str + DAEDump.dumpOperatorSymbol(inOp) + e2Str + " '";
        s2 = "' " + t1Str + DAEDump.dumpOperatorString(inOp) + t2Str + " '";
        Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1,s2,t1Str}, Absyn.dummyInfo);
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFTypeCheck.ccheckLogicalBinaryOperation failed with type mismatch: " + t1Str + " tys: " + t2Str);
      then
        fail();

  end matchcontinue;
end checkLogicalBinaryOperation;

public function checkRelationOperation
  "mahge:
  Type checks relational operations. Relations on scalars are handled
  simply by using Types.matchType(). This way conversions from Integer to real
  are handled internaly."
  input DAE.Exp inExp1;
  input DAE.Type inType1;
  input DAE.Operator inOp;
  input DAE.Exp inExp2;
  input DAE.Type inType2;
  output DAE.Exp outExp;
  output DAE.Type outType;
algorithm
  (outExp,outType) := matchcontinue(inExp1,inType1,inOp,inExp2,inType2)
    local
      DAE.Exp exp1,exp2,exp;
      DAE.Type ty,ty1;
      String e1Str, t1Str, e2Str, t2Str, s1, s2, sugg;
      Boolean isarr1,isarr2;
      DAE.Operator newop;
      DAE.TypeSource typsrc;


    // Check types match/can be converted to match.
    case(_,_,_,_,_)
      equation
        true = Types.isSimpleType(inType1);
        true = Types.isSimpleType(inType2);

        (exp1,exp2,ty1) = matchTypeBothWays(inExp1,inType1,inExp2,inType2);

        typsrc = Types.getTypeSource(ty1);
        ty = DAE.T_BOOL({},typsrc);
        newop = Expression.setOpType(inOp, ty);

        exp = DAE.RELATION(exp1, newop, exp2, -1, NONE());
      then
        (exp,ty);


    // Check if we have relational operations involving array types.
    // Just for proper error messages.
    case(_,_,_,_,_)
      equation
        isarr1 = Types.arrayType(inType1);
        isarr2 = Types.arrayType(inType2);

        // If one of them is an array.
        true = isarr1 or isarr2;

        e1Str = ExpressionDump.printExpStr(inExp1);
        t1Str = Types.unparseType(inType1);
        e2Str = ExpressionDump.printExpStr(inExp2);
        t2Str = Types.unparseType(inType2);
        sugg = "\n: Relational operations involving array types are not valid in Modelica.";
        s1 = "' " + e1Str + DAEDump.dumpOperatorSymbol(inOp) + e2Str + " '";
        s2 = "' " + t1Str + DAEDump.dumpOperatorString(inOp) + t2Str + " '";
        Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1,s2,sugg}, Absyn.dummyInfo);
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFTypeCheck.checkRelationOperation failed with type mismatch: " + t1Str + " tys: " + t2Str);
      then
        fail();


    else
      equation
        e1Str = ExpressionDump.printExpStr(inExp1);
        t1Str = Types.unparseType(inType1);
        e2Str = ExpressionDump.printExpStr(inExp2);
        t2Str = Types.unparseType(inType2);
        s1 = "' " + e1Str + DAEDump.dumpOperatorSymbol(inOp) + e2Str + " '";
        s2 = "' " + t1Str + DAEDump.dumpOperatorString(inOp) + t2Str + " '";
        Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1,s2,t1Str}, Absyn.dummyInfo);
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFTypeCheck.checkRelationOperation failed with type mismatch: " + t1Str + " tys: " + t2Str);
      then
        fail();

  end matchcontinue;
end checkRelationOperation;

public function checkBinaryOperation
  "mahge:
  Type checks binary operations. operations on scalars are handled
  simply by using Types.matchType(). This way conversions from Integer to real
  are handled internaly.
  Operations involving arrays and Complex types are handled differently."
  input DAE.Exp inExp1;
  input DAE.Type inType1;
  input DAE.Operator inOp;
  input DAE.Exp inExp2;
  input DAE.Type inType2;
  output DAE.Exp outExp;
  output DAE.Type outType;
algorithm
  (outExp,outType) := matchcontinue(inExp1,inType1,inOp,inExp2,inType2)
    local
      DAE.Exp exp1,exp2,exp;
      DAE.Type ty,ty1,ty2;
      String e1Str, t1Str, e2Str, t2Str, s1, s2;
      Boolean isarr1,isarr2;
      DAE.Operator newop;
      DAE.TypeSource typsrc;


    // All operators expect Numeric types except Addition.
    case(_,_,_,_,_)
      equation
        false = checkValidNumericTypesForOp(inType1,inType1,inOp,true);
      then
        fail();

    // Check division operations.
    // They reslut in T_REAL regardless of the operand types.
    case(_,_,DAE.DIV(_),_,_)
      equation
        true = Types.isSimpleType(inType1);
        true = Types.isSimpleType(inType2);

        (exp1,exp2,ty1) = matchTypeBothWays(inExp1,inType1,inExp2,inType2);

        typsrc = Types.getTypeSource(ty1);
        ty = DAE.T_REAL({},typsrc);
        newop = Expression.setOpType(inOp, ty);

        exp = DAE.BINARY(exp1, newop, exp2);
      then
        (exp,ty);

    // Check exponentiations.
    // They reslut in T_REAL regardless of the operand types.
    // According to spec operands should be promoted to real before expon.
    // to fit with ANSI C ???.
    case(_,_,DAE.POW(_),_,_)
      equation
        true = Types.isSimpleType(inType1);
        true = Types.isSimpleType(inType2);

        // Try converting both to REAL type.
        (exp1,ty1) = Types.matchType(inExp1,inType1,DAE.T_REAL_DEFAULT,true);
        (exp2,_) = Types.matchType(inExp2,inType2,DAE.T_REAL_DEFAULT,true);

        // (exp1,exp2,ty1) = matchTypeBothWays(inExp1,inType1,inExp2,inType2);

        typsrc = Types.getTypeSource(ty1);
        ty = DAE.T_REAL({},typsrc);
        newop = Expression.setOpType(inOp, ty);

        exp = DAE.BINARY(exp1, newop, exp2);
      then
        (exp,ty);

    // Addition operations on Scalars.
    // Check if the operands (match/can be converted to match) the other.
    case(_,_,DAE.ADD(_),_,_)
      equation
        true = Types.isSimpleType(inType1);
        true = Types.isSimpleType(inType2);

        (exp1,exp2,ty) = matchTypeBothWays(inExp1,inType1,inExp2,inType2);
        newop = Expression.setOpType(inOp, ty);

        exp = DAE.BINARY(exp1, newop, exp2);
      then
        (exp,ty);

    // Subtraction operations on Scalars.
    // Check if the operands (match/can be converted to match) the other.
    case(_,_,DAE.SUB(_),_,_)
      equation
        true = Types.isSimpleType(inType1);
        true = Types.isSimpleType(inType2);

        (exp1,exp2,ty) = matchTypeBothWays(inExp1,inType1,inExp2,inType2);
        newop = Expression.setOpType(inOp, ty);

        exp = DAE.BINARY(exp1, newop, exp2);
      then
        (exp,ty);

    // Multiplication operations on Scalars.
    // Check if the operands (match/can be converted to match) the other.
    // Requires Numeric Operands.
    case(_,_,DAE.MUL(_),_,_)
      equation
        true = Types.isSimpleType(inType1);
        true = Types.isSimpleType(inType2);

        (exp1,exp2,ty) = matchTypeBothWays(inExp1,inType1,inExp2,inType2);
        newop = Expression.setOpType(inOp, ty);

        exp = DAE.BINARY(exp1, newop, exp2);
      then
        (exp,ty);


    // Check if we have operations involving array types.
    case(_,_,_,_,_)
      equation
        isarr1 = Types.arrayType(inType1);
        isarr2 = Types.arrayType(inType2);

        // If one of them is an array.
        true = isarr1 or isarr2;

        (exp,ty) = checkBinaryOperationArrays(inExp1,inType1,inOp,inExp2,inType2);
      then
        (exp,ty);


    else
      equation
        e1Str = ExpressionDump.printExpStr(inExp1);
        t1Str = Types.unparseType(inType1);
        e2Str = ExpressionDump.printExpStr(inExp2);
        t2Str = Types.unparseType(inType2);
        s1 = "' " + e1Str + DAEDump.dumpOperatorSymbol(inOp) + e2Str + " '";
        s2 = "' " + t1Str + DAEDump.dumpOperatorString(inOp) + t2Str + " '";
        Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1,s2,t1Str}, Absyn.dummyInfo);
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFTypeCheck.checkBinaryOperation failed with type mismatch: " + t1Str + " tys: " + t2Str);
      then
        fail();

  end matchcontinue;
end checkBinaryOperation;


public function checkBinaryOperationArrays
  "mahge:
  Type checks binary operations involving arrays. This involves more checks than
  scalar types. All normal operations as well as element wise operations involving
  arrays are handled here."
  input DAE.Exp inExp1;
  input DAE.Type inType1;
  input DAE.Operator inOp;
  input DAE.Exp inExp2;
  input DAE.Type inType2;
  output DAE.Exp outExp;
  output DAE.Type outType;
algorithm
  (outExp,outType) := matchcontinue(inExp1,inType1,inOp,inExp2,inType2)
    local
      DAE.Exp exp1,exp2,exp;
      DAE.Type ty1,ty2, arrtp, ty;
      String e1Str, t1Str, e2Str, t2Str, s1, s2, sugg;
      Boolean isarr1,isarr2;
      DAE.Dimensions dims;
      DAE.Dimension M,N1,N2,K;
      DAE.Operator newop;
      DAE.TypeSource typsrc;


    // Adding Subtracting a scalar/array by array/scalar is not allowed.
    // N.B. Allowed only if elemwise operation
    case(_,_,DAE.ADD(_) ,_,_)
      equation
        isarr1 = Types.arrayType(inType1);
        isarr2 = Types.arrayType(inType2);

        // If one of them is a Scalar.
        false = isarr1 and isarr2;

        e1Str = ExpressionDump.printExpStr(inExp1);
        t1Str = Types.unparseType(inType1);
        e2Str = ExpressionDump.printExpStr(inExp2);
        t2Str = Types.unparseType(inType2);
        sugg = "\n: Addition operations involving an array and a scalar are not valid in Modelica. Try using elementwise operator '.+'";
        s1 = "' " + e1Str + DAEDump.dumpOperatorSymbol(inOp) + e2Str + " '";
        s2 = "' " + t1Str + DAEDump.dumpOperatorString(inOp) + t2Str + " '";
        Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1,s2,sugg}, Absyn.dummyInfo);
      then
        fail();

    // Adding Subtracting a scalar/array by array/scalar is not allowed.
    // N.B. Allowed only if elemwise operation
    case(_,_,DAE.SUB(_) ,_,_)
      equation
        isarr1 = Types.arrayType(inType1);
        isarr2 = Types.arrayType(inType2);

        // If one of them is a Scalar.
        false = isarr1 and isarr2;

        e1Str = ExpressionDump.printExpStr(inExp1);
        t1Str = Types.unparseType(inType1);
        e2Str = ExpressionDump.printExpStr(inExp2);
        t2Str = Types.unparseType(inType2);
        sugg = "\n: Subtraction operations involving an array and a scalar are not valid in Modelica. Try using elementwise operator '.-'";
        s1 = "' " + e1Str + DAEDump.dumpOperatorSymbol(inOp) + e2Str + " '";
        s2 = "' " + t1Str + DAEDump.dumpOperatorString(inOp) + t2Str + " '";
        Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1,s2,sugg}, Absyn.dummyInfo);
      then
        fail();

    // Dividing array by scalar. {a,b,c} / s is OK
    // But the operation should be changed to elemwise. DAE.DIV -> DIV_ARRAY_SCALAR
    // And the return type and operator types are always REAL type.
    case(_,_,DAE.DIV(_),_,_)
      equation
        true = Types.arrayType(inType1);
        false = Types.arrayType(inType2);

        DAE.T_ARRAY(_,dims,_) = inType1;
        arrtp = Types.liftArrayListDims(inType2,dims);

        (exp1,exp2,ty1) = matchTypeBothWays(inExp1,inType1,inExp2,arrtp);

        // Create a scalar Real Type and lift it to array.
        // Necessary because even if both operands are of Integer type the result
        // should be Real type with dimensions of the input array operand.
        typsrc = Types.getTypeSource(ty1);
        ty = DAE.T_REAL({},typsrc);
        arrtp = Types.liftArrayListDims(ty,dims);

        newop = Expression.setOpType(inOp, arrtp);

        newop = DAE.DIV_ARRAY_SCALAR(arrtp);
        exp = DAE.BINARY(exp1, newop, exp2);

      then
        (exp,arrtp);

    // Dividing scalar or array by array. s / {a,b,c} or {a,b,c} / {a,b,c} is not allowed.
    // i.e. if the case above failed nothing else is allowed for DAE.DIV()
    case(_,_,DAE.DIV(_) ,_,_)
      equation
        e1Str = ExpressionDump.printExpStr(inExp1);
        t1Str = Types.unparseType(inType1);
        e2Str = ExpressionDump.printExpStr(inExp2);
        t2Str = Types.unparseType(inType2);
        sugg = "\n: Dividing a sclar by array or array by array is not a valid operation in Modelica. Try using elementwise operator './'";
        s1 = "' " + e1Str + DAEDump.dumpOperatorSymbol(inOp) + e2Str + " '";
        s2 = "' " + t1Str + DAEDump.dumpOperatorString(inOp) + t2Str + " '";
        Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1,s2,sugg}, Absyn.dummyInfo);
      then
        fail();

    // Exponentiation of array by scalar. A[:,:]^s is OK only if A is a square matrix and s is an integer type.
    // The operation should be changed to POW_ARRAY_SCALAR.
    case(_,_,DAE.POW(_),_,_)
      equation

        DAE.T_INTEGER(_,_) = inType2;

        2 = getArrayNumberOfDimensions(inType1);
        M = Types.getDimensionNth(inType1, 1);
        K = Types.getDimensionNth(inType1, 2);
        // Check if dims are equal. i.e Square Matrix
        true = isValidMatrixMultiplyDims(M, K);

        newop = Expression.setOpType(inOp, inType1);

        newop = DAE.POW_ARRAY_SCALAR(inType1);
        exp = DAE.BINARY(inExp1, newop, inExp2);

      then
        (exp,inType1);

    // Exponentiation involving and array is invlaid.
    // s ^ {a,b,c}, {a,b,c} ^ s, {a,b,c} ^ {a,b,c} are all invalid.
    // N.B. Allowed only if elemwise operation
    case(_,_,DAE.POW(_) ,_,_)
      equation
        e1Str = ExpressionDump.printExpStr(inExp1);
        t1Str = Types.unparseType(inType1);
        e2Str = ExpressionDump.printExpStr(inExp2);
        t2Str = Types.unparseType(inType2);
        sugg = "\n: Exponentiation involving arrays is only valid for square matrices with integer exponents. Try using elementwise operator '.^'";
        s1 = "' " + e1Str + DAEDump.dumpOperatorSymbol(inOp) + e2Str + " '";
        s2 = "' " + t1Str + DAEDump.dumpOperatorString(inOp) + t2Str + " '";
        Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1,s2,sugg}, Absyn.dummyInfo);
      then
        fail();


    // Multiplication involving an array and scalar is fine.
    case(_,_,DAE.MUL(_),_,_)
      equation
        isarr1 = Types.arrayType(inType1);
        isarr2 = Types.arrayType(inType2);

        // If one of them is a Scalar.
        false = isarr1 and isarr2;

        // Get the dims from the array operand
        arrtp = if isarr1 then inType1 else inType2;
        DAE.T_ARRAY(_,dims,_) = arrtp;

        //match their scalar types
        ty1 = Types.arrayElementType(inType1);
        ty2 = Types.arrayElementType(inType2);
        (exp1,exp2,ty1) = matchTypeBothWays(inExp1,ty1,inExp2,ty2);

        // Create the resulting array and exptype
        ty = Types.liftArrayListDims(ty1,dims);
        newop = DAE.MUL_ARRAY_SCALAR(ty);
        exp = DAE.BINARY(exp1, newop, exp2);

      then
        (exp,ty);


    /********************************************************************/
    // Handling of Matrix/Vector operations.
    /********************************************************************/

    // Multiplication of two vectors. Vector[n]*Vector[n] = Scalar
    // Resolves to Scalar product. DAE.MUL_SCALAR_PRODUCT
    case(_,_,DAE.MUL(_),_,_)
      equation

        1 = getArrayNumberOfDimensions(inType1);
        1 = getArrayNumberOfDimensions(inType1);

        (exp1,exp2,ty1) = matchTypeBothWays(inExp1,inType1,inExp2,inType2);

        ty = Types.arrayElementType(ty1);

        newop = DAE.MUL_SCALAR_PRODUCT(ty);
        exp = DAE.BINARY(exp1, newop, exp2);

      then
        (exp,ty);

    // Multiplication of Matrix by vector. Matrix[M,N1] * Vector[N2] = Vector[M]
    // Resolves to Matrix multiplication. DAE.MUL_MATRIX_PRODUCT
    case(_,_,DAE.MUL(_),_,_)
      equation

        2 = getArrayNumberOfDimensions(inType1);
        1 = getArrayNumberOfDimensions(inType2);

        // Check if dimensions are valid
        M = Types.getDimensionNth(inType1, 1);
        N1 = Types.getDimensionNth(inType1, 2);
        N2 = Types.getDimensionNth(inType2, 1);
        true = isValidMatrixMultiplyDims(N1, N2);

        ty1 = Types.arrayElementType(inType1);
        ty2 = Types.arrayElementType(inType2);

        // Is this OK? using the original exps with the element types of the arrays?
        (exp1,exp2,ty) = matchTypeBothWays(inExp1,ty1,inExp2,ty2);

        // Perpare the resulting Vector,. Vector[M]
        ty = Types.liftArray(ty, M);

        newop = DAE.MUL_MATRIX_PRODUCT(ty);
        exp = DAE.BINARY(exp1, newop, exp2);

      then
        (exp,ty);

    // Multiplication of Vector by Matrix.  Vector[N1] * Matrix[N2,M] = Vector[M]
    // Resolves to Matrix multiplication.
    case(_,_,DAE.MUL(_),_,_)
      equation

        1 = getArrayNumberOfDimensions(inType1);
        2 = getArrayNumberOfDimensions(inType2);

        // Check if dimensions are valid
        N1 = Types.getDimensionNth(inType1, 1);
        N2 = Types.getDimensionNth(inType2, 1);
        M = Types.getDimensionNth(inType2, 2);
        true = isValidMatrixMultiplyDims(N1, N2);

        ty1 = Types.arrayElementType(inType1);
        ty2 = Types.arrayElementType(inType2);

        // Is this OK? using the original exps with the element types of the arrays?
        (exp1,exp2,ty) = matchTypeBothWays(inExp1,ty1,inExp2,ty2);

        // Perpare the resulting Vector,. Vector[M]
        ty = Types.liftArray(ty, M);

        newop = DAE.MUL_MATRIX_PRODUCT(ty);
        exp = DAE.BINARY(exp1, newop, exp2);

      then
        (exp,ty);


    // Multiplication of two Matrices. Matrix[M,N1] * Matrix[N2,K] = Matrix[M, K]
    // Resolves to Matrix multiplication.
    case(_,_,DAE.MUL(_),_,_)
      equation

        2 = getArrayNumberOfDimensions(inType1);
        2 = getArrayNumberOfDimensions(inType2);

        // Check if dimensions are valid
        M = Types.getDimensionNth(inType1, 1);
        N1 = Types.getDimensionNth(inType1, 2);
        N2 = Types.getDimensionNth(inType2, 1);
        K = Types.getDimensionNth(inType2, 2);
        true = isValidMatrixMultiplyDims(N1, N2);

        // We can't use this here because the dimensions do not exactly match.
        // do it manually here.
        // (exp1,exp2,ty1) = matchTypeBothWays(inExp1,inType1,inExp2,inType2);

        ty1 = Types.arrayElementType(inType1);
        ty2 = Types.arrayElementType(inType2);

        // Is this OK? using the original exps with the element types of the arrays?
        (exp1,exp2,ty) = matchTypeBothWays(inExp1,ty1,inExp2,ty2);

        // Perpare the resulting Matrix type,. Matrix[M, K]
        ty = Types.liftArrayListDims(ty, {M, K});

        newop = DAE.MUL_MATRIX_PRODUCT(ty);
        exp = DAE.BINARY(exp1, newop, exp2);

      then
        (exp,ty);

    // Handling of Matrix/Vector operations ends here.
    /********************************************************************/



    // Multiplying array by array. a[2,2,...] * b[2,2,...] is not allowed.
    // i.e. if the cases above failed, which means it is not a Vector/Matrix operation.
    // nothing else is allowed for DAE.MUL().
    // N.B. Allowed only if elementwise oepration
    case(_,_,DAE.MUL(_) ,_,_)
      equation
        e1Str = ExpressionDump.printExpStr(inExp1);
        t1Str = Types.unparseType(inType1);
        e2Str = ExpressionDump.printExpStr(inExp2);
        t2Str = Types.unparseType(inType2);
        s1 = "' " + e1Str + DAEDump.dumpOperatorSymbol(inOp) + e2Str + " '";
        s2 = "' " + t1Str + DAEDump.dumpOperatorString(inOp) + t2Str + " '";
        Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1,s2,t1Str}, Absyn.dummyInfo);
      then
        fail();


    /********************************************************************/
    // Everything else is fine as long as the types of the operands match.
    // This include all Element wise binary oeprations!!!
    /********************************************************************/

    // Operations involving an array and a scalar
    // If there is no specific handling for them
    // (i.e. not handled by cases above.) we can assume
    // that they return a value with same dims as the array operand.
    case(_,_,_,_,_)
      equation

        isarr1 = Types.arrayType(inType1);
        isarr2 = Types.arrayType(inType2);

        // If one of them is a Scalar.
        false = isarr1 and isarr2;

        // Get the dims from the array operand
        arrtp = if isarr1 then inType1 else inType2;
        DAE.T_ARRAY(_,dims,_) = arrtp;

        //match their scalar types
        ty1 = Types.arrayElementType(inType1);
        ty2 = Types.arrayElementType(inType2);
        (exp1,exp2,ty1) = matchTypeBothWays(inExp1,ty1,inExp2,ty2);

        // Create the resulting array and exptype
        ty = Types.liftArrayListDims(ty1,dims);
        newop = Expression.setOpType(inOp, ty);
        exp = DAE.BINARY(exp1, newop, exp2);
      then
        (exp,ty);

    // Both operands are arrays
    case(_,_,_,_,_)
      equation

        // true = Types.arrayType(inType1);
        // true = Types.arrayType(inType2);

        (exp1,exp2,ty1) = matchTypeBothWays(inExp1,inType1,inExp2,inType2);
        newop = Expression.setOpType(inOp, ty1);
        exp = DAE.BINARY(exp1, newop, exp2);
      then
        (exp,ty1);

    // Failure
    else
      equation
        e1Str = ExpressionDump.printExpStr(inExp1);
        t1Str = Types.unparseType(inType1);
        e2Str = ExpressionDump.printExpStr(inExp2);
        t2Str = Types.unparseType(inType2);
        s1 = "' " + e1Str + DAEDump.dumpOperatorSymbol(inOp) + e2Str + " '";
        s2 = "' " + t1Str + DAEDump.dumpOperatorString(inOp) + t2Str + " '";
        Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1,s2,t1Str}, Absyn.dummyInfo);
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFTypeCheck.checkBinaryOperationArrays failed with type mismatch: " + t1Str + " tys: " + t2Str);
      then
        fail();

  end matchcontinue;
end checkBinaryOperationArrays;


protected function matchTypeBothWays
  "mahge:
  Tries to match to types. First by converting the 2nd one to the 1st.
  if not possible then tries to convert the 1st to the 2nd."
  input DAE.Exp inExp1;
  input DAE.Type inType1;
  input DAE.Exp inExp2;
  input DAE.Type inType2;
  output DAE.Exp outExp1;
  output DAE.Exp outExp2;
  output DAE.Type outType;
algorithm
  (outExp1,outExp2,outType) := matchcontinue(inExp1,inType1,inExp2,inType2)
    local
      DAE.Exp exp;
      DAE.Type ty;

  case(_,_,_,_)
      equation
        (exp,ty) = Types.matchType(inExp2,inType2,inType1,true);
      then
        (inExp1,exp,ty);
  case(_,_,_,_)
      equation
        (exp,ty) = Types.matchType(inExp1,inType1,inType2,true);
      then
        (exp,inExp2,ty);
  end matchcontinue;

end matchTypeBothWays;

protected function checkValidNumericTypesForOp
"@mahge:
  Helper function for Check*Operator functions.
  Checks if both operands are Numeric types for all operators except Addition.
  Which cn also work on Strings and maybe Bools??.
  Written separatly because it needs to print an error."
  input DAE.Type inType1;
  input DAE.Type inType2;
  input DAE.Operator inOp;
  input Boolean printError;
  output Boolean isValid;
algorithm
  isValid := matchcontinue(inType1,inType2,inOp,printError)
    local
      String t1Str,t2Str,s2;

    case(_,_,DAE.ADD(_),_) then true;

    case(_,_,_,_)
      equation
        true = Types.isNumericType(inType1);
        true = Types.isNumericType(inType2);
      then true;

    // If printing error messages. print and fail.
    case(_,_,_,true)
      equation
        t1Str = Types.unparseType(inType1);
        t2Str = Types.unparseType(inType2);
        s2 = DAEDump.dumpOperatorString(inOp);
        Error.addSourceMessage(Error.FOUND_NON_NUMERIC_TYPES, {s2,t1Str,t2Str}, Absyn.dummyInfo);
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFTypeCheck.bothTypesSimpleNumeric failed with type mismatch: " + t1Str + " tys: " + t2Str);
      then
        false;

    // If no error messages wanted just return false.
    case(_,_,_,false) then false;

  end matchcontinue;

end checkValidNumericTypesForOp;


public function getArrayNumberOfDimensions
  input DAE.Type inType;
  output Integer outDim;
algorithm
  outDim := match (inType)
    local
      Integer ns;
      DAE.Type t;
      DAE.Dimensions dims;
    case (DAE.T_ARRAY(ty = t, dims = dims))
      equation
        ns = getArrayNumberOfDimensions(t) + listLength(dims);
      then
        ns;
    else 0;
  end match;
end getArrayNumberOfDimensions;


protected function isValidMatrixMultiplyDims
"@mahge:
  Checks if two dimensions are equal, which is a prerequisite for Matrix/Vector
  multiplication."
  input DAE.Dimension dim1;
  input DAE.Dimension dim2;
  output Boolean res;
algorithm
  res := matchcontinue(dim1, dim2)
    local
      String msg;
    // The dimensions are both known and equal.
    case (_, _)
      equation
        true = Expression.dimensionsKnownAndEqual(dim1, dim2);
      then
        true;
    // If checkModel is used we might get unknown dimensions. So use
    // dimensionsEqual instead, which matches anything against DIM_UNKNOWN.
    case (_, _)
      equation
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
        true = Expression.dimensionsEqual(dim1, dim2);
      then
        true;
    case (_, _)
      equation
        msg = "Dimension mismatch in Vector/Matrix multiplication operation: " +
              ExpressionDump.dimensionString(dim1) + "x" + ExpressionDump.dimensionString(dim2);
        Error.addSourceMessage(Error.COMPILER_ERROR, {msg}, Absyn.dummyInfo);
      then false;
  end matchcontinue;
end isValidMatrixMultiplyDims;

// ************************************************************** //
//   END: Operator typing helper functions
// ************************************************************** //





// ************************************************************** //
//   BEGIN: TypeCall helper functions
// ************************************************************** //


public function matchCallArgs
"@mahge:
  matches given call args with the expected or formal arguments for a function.
  if vectorization dimension (inVectDims) is given (is not empty) then the function
  works with vectorization mode.
  otherwise no vectorization will be done.

  However if matching fails in no vect. mode due to dim mismatch then
  a vect dim will be returned from  NFTypeCheck.matchCallArgs and this
  function will start all over again with the new vect dimension."

  input list<DAE.Exp> inArgs;
  input list<DAE.Type> inArgTypes;
  input list<DAE.Type> inExpectedTypes;
  input DAE.Dimensions inVectDims;
  output list<DAE.Exp> outFixedArgs;
  output DAE.Dimensions outVectDims;
algorithm
  (outFixedArgs, outVectDims):=
  matchcontinue (inArgs,inArgTypes,inExpectedTypes, inVectDims)
    local
      DAE.Exp e,e_1;
      list<DAE.Exp> restargs, fixedArgs;
      DAE.Type t1,t2;
      list<DAE.Type> restinty,restexpcty;
      DAE.Dimensions dims1, dims2;
      String e1Str, t1Str, t2Str, s1;

    case ({},{},{},_) then ({}, inVectDims);

    // No vectorization mode.
    // If things continue to match with no vect.
    // Then all is good.
    case (e::restargs, (t1 :: restinty), (t2 :: restexpcty), {})
      equation
        (e_1, {}) = matchCallArg(e,t1,t2,{});

        (fixedArgs, {}) = matchCallArgs(restargs, restinty, restexpcty, {});
      then
        (e_1::fixedArgs, {});

    // No vectorization mode.
    // If argument failed to match not because of dim mismatch
    // but due to actuall type mismatch then it is an invalid call and we fail here.
    case (e::_, (t1 :: _), (t2 :: _), {})
      equation
        failure((_,_) = matchCallArg(e,t1,t2,{}));

        e1Str = ExpressionDump.printExpStr(e);
        t1Str = Types.unparseType(t1);
        t2Str = Types.unparseType(t2);
        s1 = "Failed to match or convert '" + e1Str + "' of type '" + t1Str +
             "' to type '" + t2Str + "'";
        Error.addSourceMessage(Error.INTERNAL_ERROR, {s1}, Absyn.dummyInfo);
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFTypeCheck.matchCallArgs failed with type mismatch: " + t1Str + " tys: " + t2Str);
      then
        fail();

    // No -> Yes vectorization mode.
    // If argument fails to match due to dim mistmatch. then we
    // have our vect. dim and we start from the begining.
    case (e::_, (t1 :: _), (t2 :: _), {})
      equation
        (_, dims1) = matchCallArg(e,t1,t2,{});

        // This is just to be realllly sure. The cases above actually make sure of it.
        false = Expression.dimsEqual(dims1, {});

        // Start from the first arg. This time with Vectorization.
        (fixedArgs, dims2) = matchCallArgs(inArgs,inArgTypes,inExpectedTypes, dims1);
      then
        (fixedArgs, dims2);

    // Vectorization mode.
    case (e::restargs, (t1 :: restinty), (t2 :: restexpcty), dims1)
      equation
        false = Expression.dimsEqual(dims1, {});
        (e_1, dims1) = matchCallArg(e,t1,t2,dims1);
        (fixedArgs, dims1) = matchCallArgs(restargs, restinty, restexpcty, dims1);
      then
        (e_1::fixedArgs, dims1);



    case (_::_,(_ :: _),(_ :: _), _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- NFTypeCheck.matchCallArgs failed\n");
      then
        fail();
  end matchcontinue;
end matchCallArgs;


public function matchCallArg
"@mahge:
  matches a given call arg with the expected or formal argument for a function.
  if vectorization dimension (inVectDims) is given (is not empty) then the function
  works with vectorization mode.
  otherwise no vectorization will be done.

  However if matching fails in no vect. mode due to dim mismatch then
  it will try to see if vectoriztion is possible. If so the vectorization dim is
  returned to NFTypeCheck.matchCallArg so that it can start matching from the begining
  with the new vect dim."

  input DAE.Exp inArg;
  input DAE.Type inArgType;
  input DAE.Type inExpectedType;
  input DAE.Dimensions inVectDims;
  output DAE.Exp outArg;
  output DAE.Dimensions outVectDims;
algorithm
  (outArg, outVectDims) := matchcontinue (inArg,inArgType,inExpectedType,inVectDims)
    local
      DAE.Exp e,e_1;
      DAE.Type e_type,expected_type;
      String e1Str, t1Str, t2Str, s1;
      DAE.Dimensions dims1, dims2, foreachdim;


    // No vectorization mode.
    // Types match (i.e. dims match exactly). Then all is good
    case (e,e_type,expected_type, {})
      equation
        // Of course matchtype will make sure of this
        // but this is faster.
        dims1 = Types.getDimensions(e_type);
        dims2 = Types.getDimensions(expected_type);
        true = Expression.dimsEqual(dims1, dims2);

        (e_1,_) = Types.matchType(e, e_type, expected_type, true);
      then
        (e_1, {});


    // No vectorization mode.
    // If it failed NOT because of dim mismatch but because
    // of actuall type mismatch then fail here.
    case (_,e_type,expected_type, {})
      equation
        dims1 = Types.getDimensions(e_type);
        dims2 = Types.getDimensions(expected_type);
        true = Expression.dimsEqual(dims1, dims2);
      then
        fail();

    // No Vect. -> Vectorization mode.
    // We found a dim mistmatch. Try vectorizing. If vectorizing
    // matches, then this is our vectoriztion dimension.
    // N.B. We still have to start matching again from the first arg
    // with the new vectorization dimension.
    case (e,e_type,expected_type, {})
      equation
        dims1 = Types.getDimensions(e_type);
        dims2 = Types.getDimensions(expected_type);

        false = Expression.dimsEqual(dims1, dims2);

        foreachdim = findVectorizationDim(dims1,dims2);

      then
        (e, foreachdim);


    // IN Vectorization mode!!!.
    case (e,e_type,expected_type, foreachdim)
      equation
        e_1 = checkVectorization(e,e_type,expected_type,foreachdim);
      then
        (e_1, foreachdim);


    case (e,e_type,expected_type, _)
      equation
        e1Str = ExpressionDump.printExpStr(e);
        t1Str = Types.unparseType(e_type);
        t2Str = Types.unparseType(expected_type);
        s1 = "Failed to match or convert '" + e1Str + "' of type '" + t1Str +
             "' to type '" + t2Str + "'";
        Error.addSourceMessage(Error.INTERNAL_ERROR, {s1}, Absyn.dummyInfo);
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFTypeCheck.matchCallArg failed with type mismatch: " + t1Str + " tys: " + t2Str);
      then
        fail();
  end matchcontinue;
end matchCallArg;


protected function checkVectorization
"@mahge:
  checks if it is possible to vectorize a given argument to the
  expected or formal argument with the given vectorization dim.
  e.g. inForeachDim=[3,2]
       function F(input Integer[2]);

       Integer a[2,3,2], b[2,2,2],s;

       a is vectorizable with [3,2] => a[1]), a[2]
       b is not vectorizable with [3,2]
       s is vectorizable with [3,2] => {{s,s},{s,s},{s,s}}

  N.B. The vectoriztion dim came from the first arg mismatch in
  NFTypeCheck.matchCallArg and all susequent args shoudl be vectorizable
  with that dim. This function checks that.
  "
  input DAE.Exp inArg;
  input DAE.Type inArgType;
  input DAE.Type inExpectedType;
  input DAE.Dimensions inForeachDim;
  output DAE.Exp outArg;
algorithm
  outArg := matchcontinue (inArg,inArgType,inExpectedType,inForeachDim)
    local
      DAE.Exp outExp;
      DAE.Dimensions expectedDims, argDims;
      String e1Str, t1Str, t2Str, s1;
      DAE.Type expcType;

    // if types match (which also means dims match exactly).
    // Then we have to change the given argument to an array of
    // the vect. dim to have a 'foreach' argument
    case(_,_,_,_)
      equation
        // Of course matchtype will make sure of this
        // but this is faster.
        argDims = Types.getDimensions(inArgType);
        expectedDims = Types.getDimensions(inExpectedType);
        true = Expression.dimsEqual(argDims, expectedDims);

        (outExp,_) = Types.matchType(inArg, inArgType, inExpectedType, false);

        // create the array from the given arg to match the vectorization
        outExp = Expression.arrayFill(inForeachDim,outExp);
      then
        outExp;

    // if dims don't match exactly. Then the given argument
    // must have the same dimension as our vecorization or 'foreach' dimension.
    // And the expected type will be lifeted to the 'foreach' dim and then
    // matched with the given argument
    case(_,_,_,_)
      equation

        argDims = Types.getDimensions(inArgType);

        // lift the expected type by 'foreach' dims
        expcType = Types.liftArrayListDims(inExpectedType,inForeachDim);

        // Now the given type and the expected type must have the
        // same dimesions. Otherwise vectorization is not possible.
        expectedDims = Types.getDimensions(expcType);
        true = Expression.dimsEqual(argDims, expectedDims);

        (outExp,_) = Types.matchType(inArg, inArgType, expcType, false);
      then
        outExp;

    else
      equation
        argDims = Types.getDimensions(inArgType);
        expectedDims = Types.getDimensions(inExpectedType);

        expectedDims = listAppend(inForeachDim,expectedDims);

        e1Str = ExpressionDump.printExpStr(inArg);
        t1Str = Types.unparseType(inArgType);
        t2Str = Types.unparseType(inExpectedType);
        s1 = "Vectorization can not continue matching '" + e1Str + "' of type '" + t1Str +
             "' to type '" + t2Str + "'. Expected dimensions [" +
             ExpressionDump.printListStr(expectedDims,ExpressionDump.dimensionString,",") + "], found [" +
             ExpressionDump.printListStr(argDims,ExpressionDump.dimensionString,",") + "]";

        Error.addSourceMessage(Error.INTERNAL_ERROR, {s1}, Absyn.dummyInfo);
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFTypeCheck.checkVectorization failed ");
      then
        fail();

   end matchcontinue;

end checkVectorization;


public function findVectorizationDim
"@mahge:
 This function basically finds the diff between two dims. The resulting dimension
 is used for vectorizing calls.

 e.g. dim1=[2,3,4,2]  dim2=[4,2], findVectorizationDim(dim1,dim2) => [2,3]
      dim1=[2,3,4,2]  dim2=[3,4,2], findVectorizationDim(dim1,dim2) => [2]
      dim1=[2,3,4,2]  dim2=[4,3], fail
 "
  input DAE.Dimensions inGivenDims;
  input DAE.Dimensions inExpectedDims;
  output DAE.Dimensions outVectDims;
algorithm
  outVectDims := matchcontinue(inGivenDims, inExpectedDims)
    local
      DAE.Dimensions dims1;
      DAE.Dimension dim1;

    case(_, {}) then inGivenDims;

    case(_, _)
      equation
        true = Expression.dimsEqual(inGivenDims, inExpectedDims);
      then
        {};

    case(dim1::dims1, _)
      equation
        true = listLength(inGivenDims) > listLength(inExpectedDims);
        dims1 = findVectorizationDim(dims1,inExpectedDims);
      then
        dim1::dims1;

    case(_::_, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFTypeCheck.findVectorizationDim failed with dimensions: [" +
         ExpressionDump.printListStr(inGivenDims,ExpressionDump.dimensionString,",") + "] vs [" +
         ExpressionDump.printListStr(inExpectedDims,ExpressionDump.dimensionString,",") + "].");
      then
        fail();

  end matchcontinue;

end findVectorizationDim;


public function makeCallReturnType
"@mahge:
   makes the return type for function.
   i.e if a list of types is given then it is a tuple ret function.
 "
  input list<DAE.Type> inTypeLst;
  output DAE.Type outType;
  output Boolean outBoolean;
algorithm
  (outType,outBoolean) := match (inTypeLst)
    local
      DAE.Type ty;

    case {} then (DAE.T_NORETCALL(DAE.emptyTypeSource), false);

    case {ty} then (ty, false);

    else  (DAE.T_TUPLE(inTypeLst,NONE(),DAE.emptyTypeSource), true);

  end match;
end makeCallReturnType;



public function vectorizeCall
"@mahge:
   Vectorizes calls. Most of the work is done
   vectorizeCall2.
   This function get a list of functions with each arg
   subscripted from vectorizeCall2. e.g. {F(a[1,1]),F(a[1,2]),F(a[2,1]),F(a[2,2])}
   The it converts the list to an array of 'inForEachdim' dims using
   Expression.listToArray. i.e.
   {F(a[1,1]),F(a[1,2]),F(a[2,1]),F(a[2,2])} with vec. dim [2,2] will be
   {{F(a[1,1]),F(a[1,2])}, {F(a[2,1])F(a[2,2])}}

 "
  input Absyn.Path inFnName;
  input list<DAE.Exp> inArgs;
  input DAE.CallAttributes inAttrs;
  input DAE.Type inRetType;
  input DAE.Dimensions inForEachdim;
  output DAE.Exp outExp;
  output DAE.Type outType;
algorithm
  (outExp,outType) := matchcontinue (inFnName,inArgs,inAttrs,inRetType,inForEachdim)
    local
      list<DAE.Exp> callLst;
      DAE.Exp callArr;
      DAE.Type outtype;


    // If no 'forEachdim' then no vectorization
    case(_, _, _, _, {}) then (DAE.CALL(inFnName, inArgs, inAttrs), inRetType);


    case(_, _::_, _, _, _)
      equation
        // Get the call list with args subscripted for each value in 'foreaach' dim.
        callLst = vectorizeCall2(inFnName, inArgs, inAttrs, inForEachdim, {});

        // Create the array of calls from the list
        callArr = Expression.listToArray(callLst,inForEachdim);

        // lift the retType to 'forEachDim' dims
        outtype = Types.liftArrayListDims(inRetType, inForEachdim);
      then
        (callArr, outtype);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"NFTypeCheck.vectorizeCall failed."});
      then
        fail();

  end matchcontinue;
end vectorizeCall;


public function vectorizeCall2
"@mahge:
   Vectorizes calls. This function takes a list of args for a function
   and a vectorization dim. then it subscripts the args for each idex
   of the vec. dim and creates a function call for each subscripted
   arg list. Then retuns the list of functions.
   e.g.
   for argLst ( a, {{b,b,b},{c,c,c}} ) and functionname F with vect. dim of [2,3]
   this function creates the list

   {F(a[1,1],b), F(a[1,2],b), F(a[1,3],b), F(a[2,1],c), F(a[2,2],c), F(a[2,3],c)}
 "
  input Absyn.Path inFnName;
  input list<DAE.Exp> inArgs;
  input DAE.CallAttributes inAttrs;
  input DAE.Dimensions inDims;
  input list<DAE.Exp> inAccumCalls;
  output list<DAE.Exp> outAccumCalls;
algorithm
  outAccumCalls := matchcontinue(inFnName, inArgs, inAttrs, inDims, inAccumCalls)
    local
      DAE.Dimension dim;
      DAE.Dimensions dims;
      DAE.Exp idx;
      list<DAE.Exp> calls, subedargs;

    case (_, _, _, {}, _) then DAE.CALL(inFnName, inArgs, inAttrs) :: inAccumCalls;

    case (_, _, _, dim :: dims, _)
      equation
        (idx, dim) = getNextIndex(dim);

        subedargs = List.map1(inArgs, Expression.subscriptExp, {DAE.INDEX(idx)});

        calls = vectorizeCall2(inFnName, subedargs, inAttrs, dims, inAccumCalls);
        calls = vectorizeCall2(inFnName, inArgs, inAttrs, dim :: dims, calls);
      then
        calls;

    else inAccumCalls;

  end matchcontinue;
end vectorizeCall2;

protected function getNextIndex
  "Returns the next index given a dimension, and updates the dimension. Fails
  when there are no indices left."
  input DAE.Dimension inDim;
  output DAE.Exp outNextIndex;
  output DAE.Dimension outDim;
algorithm
  (outNextIndex, outDim) := match(inDim)
    local
      Integer new_idx, dim_size;
      Absyn.Path p, ep;
      String l;
      list<String> l_rest;

    case DAE.DIM_INTEGER(integer = 0) then fail();
    case DAE.DIM_ENUM(size = 0) then fail();

    case DAE.DIM_INTEGER(integer = new_idx)
      equation
        dim_size = new_idx - 1;
      then
        (DAE.ICONST(new_idx), DAE.DIM_INTEGER(dim_size));

    // Assumes that the enum has been reversed with reverseEnumType.
    case DAE.DIM_ENUM(p, l :: l_rest, new_idx)
      equation
        ep = Absyn.joinPaths(p, Absyn.IDENT(l));
        dim_size = new_idx - 1;
      then
        (DAE.ENUM_LITERAL(ep, new_idx), DAE.DIM_ENUM(p, l_rest, dim_size));
  end match;
end getNextIndex;


// ************************************************************** //
//   END: TypeCall helper functions
// ************************************************************** //


annotation(__OpenModelica_Interface="frontend");
end NFTypeCheck;
