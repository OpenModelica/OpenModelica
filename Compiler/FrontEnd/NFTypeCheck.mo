/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package NFTypeCheck
" file:        NFTypeCheck.mo
  package:     NFTypeCheck
  description: SCodeInst type checking.

  RCS: $Id: NFTypeCheck.mo 12209 2012-06-26 14:57:43Z sjoelund.se $

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
public type Prefix = NFInstTypes.Prefix;
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
      DAE.Type ty;
      Absyn.Info info;
      String str;

    case (NFInstTypes.ELEMENT(comp as NFInstTypes.UNTYPED_COMPONENT(name = name, info = info), cls),
        _, _, st)
      equation
        str = "Found untyped component: " +& Absyn.pathString(name);
        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, info);
      then
        fail();

    case (NFInstTypes.ELEMENT(comp, cls), _, _, st)
      equation
        (comp, st)= checkComponent(comp, inParent, inContext, st);
        (cls, st) = checkClass(cls, SOME(comp), inContext, st);
      then
        (NFInstTypes.ELEMENT(comp, cls), st);

    case (NFInstTypes.CONDITIONAL_ELEMENT(_), _, _, st)
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
  matchcontinue(inComponent, inParent, inContext, inSymbolTable)
    local
      Absyn.Path name;
      DAE.Type ty, bindingTy;
      Binding binding;
      SymbolTable st;
      Component comp, inner_comp;
      Context c;
      String str;
      Absyn.Info info;

    case (NFInstTypes.UNTYPED_COMPONENT(name = name, baseType = ty, binding = binding, info = info),
        _, c, st)
      equation
        str = "Found untyped component: " +& Absyn.pathString(name);
        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, info);
      then
        fail();

    // check and convert if needed the type of 
    // the binding vs the type of the component
    case (NFInstTypes.TYPED_COMPONENT(name = name), _, _, st)
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

    case (NFInstTypes.OUTER_COMPONENT(name = name, innerName = NONE()), _, _, st)
      equation
        (_, SOME(inner_comp), st) = NFInstSymbolTable.updateInnerReference(inComponent, st);
        (inner_comp, st) = checkComponent(inner_comp, inParent, inContext, st);
      then
        (inner_comp, st);

    case (NFInstTypes.CONDITIONAL_COMPONENT(name = name), _, _, _)
      equation
        print("Trying to type conditional component " +& Absyn.pathString(name) +& "\n");
      then
        fail();

    case (NFInstTypes.DELETED_COMPONENT(name = name), _, _, st)
      then (inComponent, st);

    case (NFInstTypes.PACKAGE(name = name), _, _, st)
      equation
        comp = NFInstUtil.setComponentParent(inComponent, inParent);
      then 
        (comp, st);

  end matchcontinue;
end checkComponent;

protected function checkComponentBindingType
  input Component inC;
  output Component outC;
algorithm
  outC := matchcontinue (inC)
    local
      Component c;
      DAE.Type ty, propagatedTy, convertedTy;
      Absyn.Path name, eName;
      Option<Component> parent;
      DaePrefixes prefixes;
      Binding binding;
      Absyn.Info info;
      DAE.Exp bindingExp;
      DAE.Type bindingType;
      Integer propagatedDims "See NFSCodeMod.propagateMod.";
      Absyn.Info binfo;
      String nStr, eStr, etStr, btStr;
      DAE.Dimensions parentDimensions;
  
    // nothing to check
    case (NFInstTypes.TYPED_COMPONENT(binding = NFInstTypes.UNBOUND()))
      then
        inC;  
  
    // when the component name is equal to the component type we have a constant enumeration!
    // StateSelect = {StateSelect.always, StateSelect.prefer, StateSelect.default, StateSelect.avoid, StateSelect.never} 
    case (NFInstTypes.TYPED_COMPONENT(name = name, ty = DAE.T_ENUMERATION(path = eName), binding = binding))
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
        
    case (NFInstTypes.TYPED_COMPONENT(name, ty, parent, prefixes, binding, info))
      equation
        NFInstTypes.TYPED_BINDING(bindingExp, bindingType, propagatedDims, binfo) = binding;
        parentDimensions = getParentDimensions(parent, {});
        propagatedTy = liftArray(ty, parentDimensions, propagatedDims);
        failure((_, _) = Types.matchType(bindingExp, bindingType, propagatedTy, true));
        nStr = Absyn.pathString(name);
        eStr = ExpressionDump.printExpStr(bindingExp);
        etStr = Types.unparseType(propagatedTy);
        etStr = etStr +& " propDim: " +& intString(propagatedDims);
        btStr = Types.unparseType(bindingType);
        Error.addSourceMessage(Error.VARIABLE_BINDING_TYPE_MISMATCH, 
        {nStr, eStr, etStr, btStr}, info);
      then
        fail();
    
    case (_)
      equation
        //name = NFInstUtil.getComponentName(inC);
        //nStr = "Found untyped component: " +& Absyn.pathString(name);
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
    case (SOME(c as NFInstTypes.PACKAGE(parent = _)), _)
      equation
        dims = getParentDimensions(NFInstUtil.getComponentParent(c), inDimensionsAcc);
      then 
        dims;
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
       false = Types.isArray(inTy, {});
       ts = Types.getTypeSource(inTy);
       dims = List.lastN(inParentDimensions, pdims);
       ty = DAE.T_ARRAY(inTy, dims, ts);
     then
       ty;
   // we can take the lastN from the propagated dims!
   case (_, _, pdims)
     equation
       true = Types.isArray(inTy, {});       
       ty = Types.unliftArray(inTy);
       ts = Types.getTypeSource(inTy);       
       dims = listAppend(inParentDimensions, Types.getDimensions(inTy));
       dims = List.lastN(dims, pdims);
       ty = DAE.T_ARRAY(ty, dims, ts);
     then
       ty;
    case (_, {}, pdims) then inTy;
    case (_,  _, pdims) then DAE.T_ARRAY(inTy, inParentDimensions, DAE.emptyTypeSource);
  end matchcontinue;
end liftArray;

public function checkExpEquality
  input DAE.Exp inExp1;
  input DAE.Type inTy1;
  input DAE.Exp inExp2;
  input DAE.Type inTy2;
  input String inMessage;
  input Absyn.Info inInfo;
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
        (inExp1, t, e, t);
    
    // the other way arround just for equations!
    case (_, _, _, _, "equ", _)
      equation
        (e, t) = Types.matchType(inExp1, inTy1, inTy2, true);
      then
        (e, t, inExp2, t);
    
    // not really fine!
    case (_, _, _, _, "equ", _)
      equation
        e1Str = ExpressionDump.printExpStr(inExp1);
        t1Str = Types.unparseType(inTy1);
        e2Str = ExpressionDump.printExpStr(inExp2);
        t2Str = Types.unparseType(inTy2);
        s1 = stringAppendList({e1Str,"=",e2Str});
        s2 = stringAppendList({t1Str,"=",t2Str});
        Error.addSourceMessage(Error.EQUATION_TYPE_MISMATCH_ERROR, {s1,s2}, inInfo);
        Debug.fprintln(Flags.FAILTRACE, "- NFTypeCheck.checkExpEquality failed with type mismatch: " +& s1 +& " tys: " +& s2);
      then
        fail();
    
    case (_, _, _, _, "alg", _)
      equation
        e1Str = ExpressionDump.printExpStr(inExp1);
        t1Str = Types.unparseType(inTy1);
        e2Str = ExpressionDump.printExpStr(inExp2);
        t2Str = Types.unparseType(inTy2);
        s1 = stringAppendList({e1Str,":=",e2Str});
        s2 = stringAppendList({t1Str,":=",t2Str});
        Error.addSourceMessage(Error.ASSIGN_TYPE_MISMATCH_ERROR, {e1Str,e2Str,t1Str,t2Str}, inInfo);
        Debug.fprintln(Flags.FAILTRACE, "- NFTypeCheck.checkExpEquality failed with type mismatch: " +& s1 +& " tys: " +& s2);
      then
        fail();
  end matchcontinue;
end checkExpEquality;


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
      DAE.Type ty,ty1;
      String e1Str, t1Str, e2Str, t2Str, s1, s2, sugg;
      Boolean isarr1,isarr2;
      DAE.Operator newop;
      DAE.TypeSource typsrc;
      
        
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
        s1 = "' " +& e1Str +& DAEDump.dumpOperatorSymbol(inOp) +& e2Str +& " '";
        s2 = "' " +& t1Str +& DAEDump.dumpOperatorString(inOp) +& t2Str +& " '";
        Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1,s2,sugg}, Absyn.dummyInfo);
        Debug.fprintln(Flags.FAILTRACE, "- NFTypeCheck.ccheckLogicalBinaryOperation failed with type mismatch: " +& t1Str +& " tys: " +& t2Str);
      then 
        fail(); 
        
        
    case(_,_,_,_,_) 
      equation
        e1Str = ExpressionDump.printExpStr(inExp1);
        t1Str = Types.unparseType(inType1);
        e2Str = ExpressionDump.printExpStr(inExp2);
        t2Str = Types.unparseType(inType2);
        s1 = "' " +& e1Str +& DAEDump.dumpOperatorSymbol(inOp) +& e2Str +& " '";
        s2 = "' " +& t1Str +& DAEDump.dumpOperatorString(inOp) +& t2Str +& " '";
        Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1,s2,t1Str}, Absyn.dummyInfo);
        Debug.fprintln(Flags.FAILTRACE, "- NFTypeCheck.ccheckLogicalBinaryOperation failed with type mismatch: " +& t1Str +& " tys: " +& t2Str);
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
        s1 = "' " +& e1Str +& DAEDump.dumpOperatorSymbol(inOp) +& e2Str +& " '";
        s2 = "' " +& t1Str +& DAEDump.dumpOperatorString(inOp) +& t2Str +& " '";
        Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1,s2,sugg}, Absyn.dummyInfo);
        Debug.fprintln(Flags.FAILTRACE, "- NFTypeCheck.checkRelationOperation failed with type mismatch: " +& t1Str +& " tys: " +& t2Str);
      then 
        fail(); 
        
        
    case(_,_,_,_,_) 
      equation
        e1Str = ExpressionDump.printExpStr(inExp1);
        t1Str = Types.unparseType(inType1);
        e2Str = ExpressionDump.printExpStr(inExp2);
        t2Str = Types.unparseType(inType2);
        s1 = "' " +& e1Str +& DAEDump.dumpOperatorSymbol(inOp) +& e2Str +& " '";
        s2 = "' " +& t1Str +& DAEDump.dumpOperatorString(inOp) +& t2Str +& " '";
        Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1,s2,t1Str}, Absyn.dummyInfo);
        Debug.fprintln(Flags.FAILTRACE, "- NFTypeCheck.checkRelationOperation failed with type mismatch: " +& t1Str +& " tys: " +& t2Str);
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
    // to fit with ANSI C ???. Anyways we don't have to worry about that here since the C 
    // compiler will take care of it.
    case(_,_,DAE.POW(_),_,_) 
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
        
    // All other operations on Scalars.   
    // Check if the operands (match/can be converted to match) the other.   
    case(_,_,_,_,_) 
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
        
        
    case(_,_,_,_,_) 
      equation
        e1Str = ExpressionDump.printExpStr(inExp1);
        t1Str = Types.unparseType(inType1);
        e2Str = ExpressionDump.printExpStr(inExp2);
        t2Str = Types.unparseType(inType2);
        s1 = "' " +& e1Str +& DAEDump.dumpOperatorSymbol(inOp) +& e2Str +& " '";
        s2 = "' " +& t1Str +& DAEDump.dumpOperatorString(inOp) +& t2Str +& " '";
        Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1,s2,t1Str}, Absyn.dummyInfo);
        Debug.fprintln(Flags.FAILTRACE, "- NFTypeCheck.checkBinaryOperation failed with type mismatch: " +& t1Str +& " tys: " +& t2Str);
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
      DAE.Dimension dim,M,N1,N2,K;
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
        s1 = "' " +& e1Str +& DAEDump.dumpOperatorSymbol(inOp) +& e2Str +& " '";
        s2 = "' " +& t1Str +& DAEDump.dumpOperatorString(inOp) +& t2Str +& " '";
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
        s1 = "' " +& e1Str +& DAEDump.dumpOperatorSymbol(inOp) +& e2Str +& " '";
        s2 = "' " +& t1Str +& DAEDump.dumpOperatorString(inOp) +& t2Str +& " '";
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
        s1 = "' " +& e1Str +& DAEDump.dumpOperatorSymbol(inOp) +& e2Str +& " '";
        s2 = "' " +& t1Str +& DAEDump.dumpOperatorString(inOp) +& t2Str +& " '";
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
        s1 = "' " +& e1Str +& DAEDump.dumpOperatorSymbol(inOp) +& e2Str +& " '";
        s2 = "' " +& t1Str +& DAEDump.dumpOperatorString(inOp) +& t2Str +& " '";
        Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1,s2,sugg}, Absyn.dummyInfo);
      then 
        fail();
   
    
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
        s1 = "' " +& e1Str +& DAEDump.dumpOperatorSymbol(inOp) +& e2Str +& " '";
        s2 = "' " +& t1Str +& DAEDump.dumpOperatorString(inOp) +& t2Str +& " '";
        Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1,s2,t1Str}, Absyn.dummyInfo);
      then 
        fail();   
        
        
    /********************************************************************/
    // Everything else is fine as long as the types of the operands match.
    // This include all Element wise binary oeprations!!!
    /********************************************************************/
    
    // Lhs array, Rhs Scalar. {a, b, c} op s
    // lift the scalar to array and match the type. 
    // This is neccesary to make sure that Integer->Real conv. are made properly.
    // i.e. with multi dim. casting (Not sure if it is really necessary though)
    case(_,_,_,_,_) 
      equation
        true = Types.arrayType(inType1);
        false = Types.arrayType(inType2);
        
        DAE.T_ARRAY(_,dims,_) = inType1;
        arrtp = Types.liftArrayListDims(inType2,dims);

        (exp1,exp2,ty1) = matchTypeBothWays(inExp1,inType1,inExp2,arrtp);
        newop = Expression.setOpType(inOp, ty1);
        exp = DAE.BINARY(exp1, newop, exp2);
         
      then 
        (exp,ty1); 
        
    // Lhs Scalar, Rhs array. s op {a, b, c} 
    // lift the scalar to array and match the type. 
    // This is neccesary to make sure that Integer->Real conv. are made properly.
    // i.e. with multi dim. casting (Not sure if it is really necessary though)
    case(_,_,_,_,_) 
      equation
        false = Types.arrayType(inType1);
        true = Types.arrayType(inType2);
        
        DAE.T_ARRAY(_,dims,_) = inType2;
        arrtp = Types.liftArrayListDims(inType1,dims);

        (exp1,exp2,ty2) = matchTypeBothWays(inExp1,arrtp,inExp2,inType2);
        newop = Expression.setOpType(inOp, ty2);
        exp = DAE.BINARY(exp1, newop, exp2);
         
      then 
        (exp,ty2);
        
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
    case(_,_,_,_,_) 
      equation
        e1Str = ExpressionDump.printExpStr(inExp1);
        t1Str = Types.unparseType(inType1);
        e2Str = ExpressionDump.printExpStr(inExp2);
        t2Str = Types.unparseType(inType2);
        s1 = "' " +& e1Str +& DAEDump.dumpOperatorSymbol(inOp) +& e2Str +& " '";
        s2 = "' " +& t1Str +& DAEDump.dumpOperatorString(inOp) +& t2Str +& " '";
        Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s1,s2,t1Str}, Absyn.dummyInfo);
        Debug.fprintln(Flags.FAILTRACE, "- NFTypeCheck.checkBinaryOperationArrays failed with type mismatch: " +& t1Str +& " tys: " +& t2Str);
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
    case (_) then 0;
  end match;
end getArrayNumberOfDimensions;


protected function isValidMatrixMultiplyDims
  "Checks if two dimensions are equal, which is a prerequisite for Matrix/Vector
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
        msg = "Dimension mismatch in Vector/Matrix multiplication operation: " +&
              ExpressionDump.dimensionString(dim1) +& "x" +& ExpressionDump.dimensionString(dim2);
        Error.addSourceMessage(Error.COMPILER_ERROR, {msg}, Absyn.dummyInfo);
      then false;
  end matchcontinue;
end isValidMatrixMultiplyDims;

protected function isOpElemWise
  input DAE.Operator inOper;
  output Boolean isElemWise;
algorithm
  isElemWise := match(inOper)
    case (DAE.ADD_ARR(_)) then true;
    case (DAE.SUB_ARR(_)) then true;
    case (DAE.MUL_ARR(_)) then true;
    case (DAE.DIV_ARR(_)) then true;
    case (DAE.POW_ARR(_)) then true;
  else false;
  end match;
end isOpElemWise;

protected function doNothing
  input Integer i;
algorithm
  i := i + 1;
end doNothing;

end NFTypeCheck;
