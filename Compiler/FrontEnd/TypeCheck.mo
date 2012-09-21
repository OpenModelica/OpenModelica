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

encapsulated package TypeCheck
" file:        TypeCheck.mo
  package:     TypeCheck
  description: SCodeInst type checking.

  RCS: $Id: TypeCheck.mo 12209 2012-06-26 14:57:43Z sjoelund.se $

  Functions used by SCodeInst for type checking and type conversion where needed.
"

public import Absyn;
public import Connect2;
public import DAE;
public import HashTablePathToFunction;
public import InstSymbolTable;
public import InstTypes;
public import Typing;

public type Binding = InstTypes.Binding;
public type Class = InstTypes.Class;
public type Component = InstTypes.Component;
public type Connections = Connect2.Connections;
public type Connector = Connect2.Connector;
public type ConnectorType = Connect2.ConnectorType;
public type DaePrefixes = InstTypes.DaePrefixes;
public type Dimension = InstTypes.Dimension;
public type Element = InstTypes.Element;
public type Equation = InstTypes.Equation;
public type Face = Connect2.Face;
public type Function = InstTypes.Function;
public type FunctionTable = HashTablePathToFunction.HashTable;
public type Modifier = InstTypes.Modifier;
public type ParamType = InstTypes.ParamType;
public type Prefixes = InstTypes.Prefixes;
public type Prefix = InstTypes.Prefix;
public type Statement = InstTypes.Statement;
public type SymbolTable = InstSymbolTable.SymbolTable;
public type Context = Typing.Context;
public type EvalPolicy = Typing.EvalPolicy;

protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import InstUtil;
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

    case (InstTypes.BASIC_TYPE(), _, _, st) then (inClass, st);

    case (InstTypes.COMPLEX_CLASS(comps, eq, ieq, al, ial), _, _, st)
      equation
        (comps, st) = List.map2Fold(comps, checkElement, inParent, inContext, st);
      then
        (InstTypes.COMPLEX_CLASS(comps, eq, ieq, al, ial), st);

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

    case (InstTypes.ELEMENT(comp as InstTypes.UNTYPED_COMPONENT(name = name, info = info), cls),
        _, _, st)
      equation
        str = "Found untyped component: " +& Absyn.pathString(name);
        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, info);
      then
        fail();

    case (InstTypes.ELEMENT(comp, cls), _, _, st)
      equation
        (comp, st)= checkComponent(comp, inParent, inContext, st);
        (cls, st) = checkClass(cls, SOME(comp), inContext, st);
      then
        (InstTypes.ELEMENT(comp, cls), st);

    case (InstTypes.EXTENDED_ELEMENTS(name, cls, ty), _, _, st)
      equation
        (cls, st) = checkClass(cls, inParent, inContext, st);
      then
        (InstTypes.EXTENDED_ELEMENTS(name, cls, ty), st);

    case (InstTypes.CONDITIONAL_ELEMENT(_), _, _, st)
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

    case (InstTypes.UNTYPED_COMPONENT(name = name, baseType = ty, binding = binding, info = info),
        _, c, st)
      equation
        str = "Found untyped component: " +& Absyn.pathString(name);
        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, info);
      then
        fail();

    // check and convert if needed the type of 
    // the binding vs the type of the component
    case (InstTypes.TYPED_COMPONENT(name = name), _, _, st)
      equation
        comp = InstUtil.setComponentParent(inComponent, inParent);
        comp = checkComponentBindingType(comp);
      then
        (comp, st);

    case (InstTypes.OUTER_COMPONENT(innerName = SOME(name)), _, _, st)
      equation
        comp = InstSymbolTable.lookupName(name, st);
        (comp, st) = checkComponent(comp, inParent, inContext, st);
      then
        (comp, st);

    case (InstTypes.OUTER_COMPONENT(name = name, innerName = NONE()), _, _, st)
      equation
        (_, SOME(inner_comp), st) = InstSymbolTable.updateInnerReference(inComponent, st);
        (inner_comp, st) = checkComponent(inner_comp, inParent, inContext, st);
      then
        (inner_comp, st);

    case (InstTypes.CONDITIONAL_COMPONENT(name = name), _, _, _)
      equation
        print("Trying to type conditional component " +& Absyn.pathString(name) +& "\n");
      then
        fail();

    case (InstTypes.DELETED_COMPONENT(name = name), _, _, st)
      then (inComponent, st);

    case (InstTypes.PACKAGE(name = name), _, _, st)
      equation
        comp = InstUtil.setComponentParent(inComponent, inParent);
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
      Integer propagatedDims "See SCodeMod.propagateMod.";
      Absyn.Info binfo;
      String nStr, eStr, etStr, btStr;
      DAE.Dimensions parentDimensions;
  
    // nothing to check
    case (InstTypes.TYPED_COMPONENT(binding = InstTypes.UNBOUND()))
      then
        inC;  
  
    // when the component name is equal to the component type we have a constant enumeration!
    // StateSelect = {StateSelect.always, StateSelect.prefer, StateSelect.default, StateSelect.avoid, StateSelect.never} 
    case (InstTypes.TYPED_COMPONENT(name = name, ty = DAE.T_ENUMERATION(path = eName), binding = binding))
      equation
        true = Absyn.pathEqual(name, eName);
      then
        inC;
  
    case (InstTypes.TYPED_COMPONENT(name, ty, parent, prefixes, binding, info))
      equation
        InstTypes.TYPED_BINDING(bindingExp, bindingType, propagatedDims, binfo) = binding;
        parentDimensions = getParentDimensions(parent, {}); 
        propagatedTy = liftArray(ty, parentDimensions, propagatedDims);
        (bindingExp, convertedTy) = Types.matchType(bindingExp, bindingType, propagatedTy, true);
        binding = InstTypes.TYPED_BINDING(bindingExp, convertedTy, propagatedDims, binfo);
      then
        InstTypes.TYPED_COMPONENT(name, ty, parent, prefixes, binding, info);
        
    case (InstTypes.TYPED_COMPONENT(name, ty, parent, prefixes, binding, info))
      equation
        InstTypes.TYPED_BINDING(bindingExp, bindingType, propagatedDims, binfo) = binding;
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
        //name = InstUtil.getComponentName(inC);
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
    case (SOME(c as InstTypes.PACKAGE(parent = _)), _)
      equation
        dims = getParentDimensions(InstUtil.getComponentParent(c), inDimensionsAcc);
      then 
        dims;
    case (SOME(c), _)
      equation
        dims = InstUtil.getComponentTypeDimensions(c);
        dims = listAppend(dims, inDimensionsAcc);
        dims = getParentDimensions(InstUtil.getComponentParent(c), dims);
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
    
    // all fine
    case (inExp1, inTy1, inExp2, inTy2, _, inInfo)
      equation
        (e, t) = Types.matchType(inExp1, inTy1, inTy2, true);
      then
        (e, t, inExp2, t);
    
    // the other way arround just for equations!
    case (inExp1, inTy1, inExp2, inTy2, _, inInfo)
      equation
        (e, t) = Types.matchType(inExp2, inTy2, inTy1, true);
      then
        (inExp1, t, e, t);
    
    // not really fine!
    case (inExp1, inTy1, inExp2, inTy2, "equ", inInfo)
      equation
        e1Str = ExpressionDump.printExpStr(inExp1);
        t1Str = Types.unparseType(inTy1);
        e2Str = ExpressionDump.printExpStr(inExp2);
        t2Str = Types.unparseType(inTy2);
        s1 = stringAppendList({e1Str,"=",e2Str});
        s2 = stringAppendList({t1Str,"=",t2Str});
        Error.addSourceMessage(Error.EQUATION_TYPE_MISMATCH_ERROR, {s1,s2}, inInfo);
        Debug.fprintln(Flags.FAILTRACE, "- TypeCheck.checkExpEquality failed with type mismatch: " +& s1 +& " tys: " +& s2);
      then
        fail();
    
    case (inExp1, inTy1, inExp2, inTy2, "alg", inInfo)
      equation
        e1Str = ExpressionDump.printExpStr(inExp1);
        t1Str = Types.unparseType(inTy1);
        e2Str = ExpressionDump.printExpStr(inExp2);
        t2Str = Types.unparseType(inTy2);
        s1 = stringAppendList({e1Str,":=",e2Str});
        s2 = stringAppendList({t1Str,":=",t2Str});
        Error.addSourceMessage(Error.ASSIGN_TYPE_MISMATCH_ERROR, {e1Str,e2Str,t1Str,t2Str}, inInfo);
        Debug.fprintln(Flags.FAILTRACE, "- TypeCheck.checkExpEquality failed with type mismatch: " +& s1 +& " tys: " +& s2);
      then
        fail();
  end matchcontinue;
end checkExpEquality;

end TypeCheck;
