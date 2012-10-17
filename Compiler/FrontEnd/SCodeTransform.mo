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

encapsulated package SCodeTransform
" file:        SCodeTransform.mo
  package:     SCodeTransform
  description: SCode instantiation

  RCS: $Id: SCodeTransform.mo 13164 2012-10-03 14:35:19Z perost $

  Prototype SCode instantiation, enable with +d=scodeInst.
"

public import Absyn;
public import Connect2;
public import DAE;
public import HashTablePathToFunction;
public import InstSymbolTable;
public import InstTypes;
public import SCode;

protected import BaseHashTable;
protected import ClassInf;
protected import ComponentReference;
protected import ConnectCheck;
protected import ConnectUtil2;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import InstUtil;
protected import List;
protected import Types;
protected import Util;
protected import TypeCheck;

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
public type FunctionHashTable = HashTablePathToFunction.HashTable;
public type Modifier = InstTypes.Modifier;
public type ParamType = InstTypes.ParamType;
public type Prefixes = InstTypes.Prefixes;
public type Prefix = InstTypes.Prefix;
public type Statement = InstTypes.Statement;
public type SymbolTable = InstSymbolTable.SymbolTable;

public function instClassToSCodeElement
  input Class inClass;
  input Absyn.Path inClassName;
  input FunctionHashTable inFunctions;
  output SCode.Element outClass;
algorithm
  (outClass) := mkClass(inClass, NONE(), inClassName, inFunctions);
end instClassToSCodeElement;

public function mkClass
  input Class inClass;
  input Option<Component> inParent;
  input Absyn.Path inClassName;
  input FunctionHashTable inFunctions;
  output SCode.Element outClass;
algorithm
  outClass := match(inClass, inParent, inClassName, inFunctions)
    local
      list<Element> comps;
      list<Equation> eq, ieq;
      list<list<Statement>> al, ial;
      SCode.Element scel;
      String name;
      list<SCode.Element> scels;
      list<SCode.Equation>          sceqs;
      list<SCode.Equation>          scieqs;
      list<SCode.AlgorithmSection>  scalgs;
      list<SCode.AlgorithmSection>  scialgs;
      Absyn.Path cname;      

    case (InstTypes.BASIC_TYPE(cname), _, _, _)
      equation
         name = Absyn.pathLastIdent(cname);
         scel = SCode.CLASS(
                name, 
                SCode.defaultPrefixes, 
                SCode.NOT_ENCAPSULATED(), 
                SCode.NOT_PARTIAL(), 
                SCode.R_TYPE(), 
                SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE(), {}, NONE()), 
                Absyn.dummyInfo);
      then 
        scel;

    case (InstTypes.COMPLEX_CLASS(cname, comps, eq, ieq, al, ial), _, _, _)
      equation
        name = Absyn.pathLastIdent(cname);
        scels   = mkElements(comps, inParent, cname, inFunctions);
        sceqs   = List.map3(eq, mkEquation, inParent, inClassName, inFunctions);
        scieqs  = List.map3(ieq, mkEquation, inParent, inClassName, inFunctions);
        scalgs  = List.map3(al, mkAlgorithm, inParent, inClassName, inFunctions);
        scialgs = List.map3(ial, mkAlgorithm, inParent, inClassName, inFunctions);
        scel = SCode.CLASS(
                name, 
                SCode.defaultPrefixes, 
                SCode.NOT_ENCAPSULATED(), 
                SCode.NOT_PARTIAL(), 
                SCode.R_CLASS(),
                SCode.PARTS(scels, sceqs, scieqs, scalgs, scialgs, {}, {}, NONE(), {}, NONE()), 
                Absyn.dummyInfo);  
      then
        scel;

  end match;
end mkClass;

protected function mkElements
  input list<Element> inElements;
  input Option<Component> inParent;
  input Absyn.Path inClassName;
  input FunctionHashTable inFunctions;
  output list<SCode.Element> outElements;
algorithm
  outElements := match(inElements, inParent, inClassName, inFunctions)
    local
      SCode.Element scel;
      list<SCode.Element> scels, scels1, scels2;
      Element el;
      list<Element> rest;

    case ({}, _, _, _) then {};

    case (el::rest, _, _, _)
      equation
        scels1 = mkElement(el, inParent, inClassName, inFunctions);
        scels2 = mkElements(rest, inParent, inClassName, inFunctions);
        scels = listAppend(scels1, scels2);
      then
        scels;

  end match;
end mkElements;

protected function mkElement
  input Element inElement;
  input Option<Component> inParent;
  input Absyn.Path inClassName;
  input FunctionHashTable inFunctions;
  output list<SCode.Element> outElements;
algorithm
  outElements := match(inElement, inParent, inClassName, inFunctions)
    local
      Component comp;
      Class cls;
      Absyn.Path name, fullName, cname;
      SymbolTable st;
      DAE.Type ty;
      SCode.Element scel, scext;
      list<SCode.Element> scco;
      String strname;

    case (InstTypes.ELEMENT(comp, cls as InstTypes.BASIC_TYPE(name)), _, _, _)
      equation
        scco = mkComponent(comp, inParent, name, inFunctions);
      then
        scco;

    case (InstTypes.ELEMENT(comp, cls as InstTypes.COMPLEX_CLASS(name = name)), _, _, _)
      equation
        cname = InstUtil.getComponentName(comp);
        strname = Absyn.pathLastIdent(cname);
        strname = Absyn.pathLastIdent(name) +& "__" +& strname;
        fullName = Absyn.IDENT(strname);
        scco = mkComponent(comp, inParent, fullName, inFunctions);
        cls = InstUtil.setClassName(cls, fullName);
        scel = mkClass(cls, SOME(comp), fullName, inFunctions);
      then
        scel::scco;

    case (InstTypes.EXTENDED_ELEMENTS(name, cls, ty), _, _, _)
      equation
        scel = mkClass(cls, inParent, name, inFunctions);
        strname = Absyn.pathLastIdent(InstUtil.getClassName(cls));
        scext = SCode.EXTENDS(Absyn.IDENT(strname), SCode.PUBLIC(), SCode.NOMOD(), NONE(), Absyn.dummyInfo);
      then
        {scel, scext};

    case (InstTypes.CONDITIONAL_ELEMENT(comp), _, _, _)
      equation
        scco = mkComponent(comp, inParent, inClassName, inFunctions);
      then
        scco;
  end match;
end mkElement;

protected function mkMod
  input Binding inBinding;
  input Option<Component> inParent;
  input Absyn.Path inClassName;
  input FunctionHashTable inFunctions;
  output SCode.Mod outMod;
algorithm
  outMod := match(inBinding, inParent, inClassName, inFunctions)
    local 
      Absyn.Exp ae;
      DAE.Exp e; 
      SCode.Each se; 
      Integer pd; 
      Absyn.Info info;
      SCode.Mod m;
    
    case (InstTypes.UNBOUND(), _, _, _) then SCode.NOMOD();
    
    case (InstTypes.RAW_BINDING(bindingExp = ae, propagatedDims = pd, info = info), _, _, _)
      equation
        se = Util.if_(pd == -1, SCode.EACH(), SCode.NOT_EACH()); 
        m = SCode.MOD(SCode.NOT_FINAL(), se, {}, SOME((ae, false)), info);
      then 
        m;
        
    case (InstTypes.UNTYPED_BINDING(bindingExp = e, propagatedDims = pd, info = info), _, _, _)
      equation
        se = Util.if_(pd == -1, SCode.EACH(), SCode.NOT_EACH());
        ae = mkExp(e); 
        m = SCode.MOD(SCode.NOT_FINAL(), se, {}, SOME((ae, false)), info);
      then 
        m;
  end match;  
end mkMod;

protected function mkComponent
  input Component inComponent;
  input Option<Component> inParent;
  input Absyn.Path inClassName;
  input FunctionHashTable inFunctions;
  output list<SCode.Element> outElements;
algorithm
  outElements :=
  match(inComponent, inParent, inClassName, inFunctions)
    local
      Absyn.Path name;
      String id;
      DAE.Type ty;
      Binding binding;
      SymbolTable st;
      Component comp, inner_comp;
      SCode.Element scco;
      Absyn.Info info;
      SCode.Mod mod;

    case (InstTypes.UNTYPED_COMPONENT(name = name, baseType = ty, binding = binding, info = info), _, _, _)
      equation
        id = Absyn.pathLastIdent(name);
        mod = mkMod(binding, inParent, inClassName, inFunctions);
        scco = SCode.COMPONENT(
          id, 
          SCode.defaultPrefixes, 
          SCode.defaultConstAttr, 
          Absyn.TPATH(inClassName, NONE()), 
          mod,
          NONE(), 
          NONE(), 
          info);
      then
        {scco};

    // A typed component without a parent has been typed due to a dependency
    // such as a binding, when parent information was not available. Update it
    // now if we have that information.
    case (InstTypes.TYPED_COMPONENT(name = name, info = info), _, _, _)
      equation
        id = Absyn.pathLastIdent(name);
        scco = SCode.COMPONENT(
          id, 
          SCode.defaultPrefixes, 
          SCode.defaultConstAttr, 
          Absyn.TPATH(inClassName, NONE()), 
          SCode.NOMOD(), 
          NONE(), 
          NONE(), 
          info);
      then
        {scco};
            
    case (InstTypes.PACKAGE(name = name), _, _, _)
      equation
        id = Absyn.pathLastIdent(name);
        scco = SCode.COMPONENT(
          id, 
          SCode.defaultPrefixes, 
          SCode.defaultConstAttr, 
          Absyn.TPATH(inClassName, NONE()), 
          SCode.NOMOD(), 
          NONE(), 
          NONE(), 
          Absyn.dummyInfo);
      then
        {scco};

    case (InstTypes.OUTER_COMPONENT(name = name), _, _, _)
      equation
        id = Absyn.pathLastIdent(name);
        scco = SCode.COMPONENT(
          id, 
          SCode.defaultPrefixes, 
          SCode.defaultConstAttr, 
          Absyn.TPATH(inClassName, NONE()), 
          SCode.NOMOD(), 
          NONE(), 
          NONE(), 
          Absyn.dummyInfo);
      then
        {scco};
    
    case (InstTypes.CONDITIONAL_COMPONENT(name = name, info = info, element = scco), _, _, _)
      equation
      then
        {scco};
  end match;
end mkComponent;

public function mkExp
  input DAE.Exp inExp;
  output Absyn.Exp outExp;
algorithm
  outExp :=  Expression.unelabExp(inExp);
end mkExp;

public function mkExpOpt
  input Option<DAE.Exp> inExpOpt;
  output Option<Absyn.Exp> outExpOpt;
algorithm
  outExpOpt := match(inExpOpt)
    local DAE.Exp e; Absyn.Exp ae;
    case (NONE()) then NONE();
    case (SOME(e)) equation ae = mkExp(e); then SOME(ae);
  end match;
end mkExpOpt;

protected function mkCref
  input DAE.ComponentRef inCref;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := ComponentReference.unelabCref(inCref);
end mkCref;

public function mkEEquation
  input Equation inEquation;
  input Option<Component> inParent;
  input Absyn.Path inClassName;
  input FunctionHashTable inFunctions;
  output SCode.EEquation outEquation;
algorithm
  outEquation := matchcontinue(inEquation, inParent, inClassName, inFunctions)
    local
      String name;
      DAE.Exp lhs, rhs, e1, e2, e3, e;
      DAE.ComponentRef cr, cr1, cr2;
      Absyn.Exp al, ar, ae, ae1, ae2, ae3;
      Absyn.ComponentRef acr1, acr2, acr;
      SCode.EEquation eq;
      list<SCode.EEquation> eqs;
      list<Equation> body;
      Absyn.Info info;
      Prefix prefix;
      list<tuple<DAE.Exp, list<Equation>>> branches;
      Option<DAE.Exp> eOpt;
      Option<Absyn.Exp> aeOpt;
      list<Absyn.Exp> conditionLst;
      Absyn.Exp condition;
      list<list<SCode.EEquation>> thenBranch;
      list<SCode.EEquation> elseBranch;
      list<SCode.EEquation> eEquationLst;
      list<tuple<Absyn.Exp, list<SCode.EEquation>>> elseBranches;
      
    case (InstTypes.EQUALITY_EQUATION(lhs, rhs, info), _, _, _)
      equation
        al = mkExp(lhs);
        ar = mkExp(rhs);
        eq = SCode.EQ_EQUALS(al, ar, NONE(), info); 
      then
        eq;

    case (InstTypes.CONNECT_EQUATION(cr1, _, _, cr2, _, _, prefix, info),  _, _, _)
      equation
        acr1 = mkCref(cr1);
        acr2 = mkCref(cr2);
        eq = SCode.EQ_CONNECT(acr1, acr2, NONE(), info);
      then
        eq;

    case (InstTypes.FOR_EQUATION(name, _, _, eOpt, body, info),  _, _, _)
      equation
        aeOpt = mkExpOpt(eOpt); 
        eqs = List.map3(body, mkEEquation, inParent, inClassName, inFunctions);
        eq = SCode.EQ_FOR(name, aeOpt, eqs, NONE(), info);
      then
        eq;

    case (InstTypes.IF_EQUATION(branches, info), _, _, _)
      equation
        (conditionLst, thenBranch, elseBranch) = 
          mkIf(branches, inParent, inClassName, inFunctions);
        eq = SCode.EQ_IF(conditionLst, thenBranch, elseBranch, NONE(), info);
      then
        eq;

    case (InstTypes.WHEN_EQUATION(branches, info), _, _, _)
      equation
        (condition, eEquationLst, elseBranches) = 
          mkWhen(branches, inParent, inClassName, inFunctions);
        eq = SCode.EQ_WHEN(condition, eEquationLst, elseBranches, NONE(), info);
      then
        eq;

    case (InstTypes.ASSERT_EQUATION(e1, e2, e3, info), _, _, _)
      equation
        ae1 = mkExp(e1);
        ae2 = mkExp(e2);
        ae3 = mkExp(e3);
        eq = SCode.EQ_ASSERT(ae1, ae2, ae3, NONE(), info);
      then
        eq;

    case (InstTypes.TERMINATE_EQUATION(e, info), _, _, _)
      equation
        ae = mkExp(e);
        eq = SCode.EQ_TERMINATE(ae, NONE(), info);
      then
        eq;

    case (InstTypes.REINIT_EQUATION(cr, e, info), _, _, _)
      equation
        acr = mkCref(cr);
        ae = mkExp(e);
        eq = SCode.EQ_REINIT(acr, ae, NONE(), info);
      then
        eq;

    case (InstTypes.NORETCALL_EQUATION(e, info), _, _, _)
      equation
        ae = mkExp(e);
        eq = SCode.EQ_NORETCALL(ae, NONE(), info);
      then
        eq;
        
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"SCodeTransform.mkEEquation got an unknown equation type!"});
      then
        fail();

  end matchcontinue;
end mkEEquation;
       
public function mkEquation
  input Equation inEquation;
  input Option<Component> inParent;
  input Absyn.Path inClassName;
  input FunctionHashTable inFunctions;
  output SCode.Equation outEquation;
algorithm
  outEquation := match(inEquation, inParent, inClassName, inFunctions)
    local
      SCode.EEquation eeq;      
    case (_, _, _, _)
      equation
        eeq = mkEEquation(inEquation, inParent, inClassName, inFunctions);
      then 
        SCode.EQUATION(eeq);
  end match;  
end mkEquation;

protected function mkIf
  input list<tuple<DAE.Exp, list<Equation>>> inBranches;
  input Option<Component> inParent;
  input Absyn.Path inClassName;
  input FunctionHashTable inFunctions;
  output list<Absyn.Exp> conditionLst;
  output list<list<SCode.EEquation>> thenBranch;
  output list<SCode.EEquation> elseBranch;
algorithm
  (conditionLst, thenBranch, elseBranch) := match(inBranches, inParent, inClassName, inFunctions)
    local
      DAE.Exp e;
      list<Equation> leq;
      list<tuple<DAE.Exp, list<Equation>>> rest;
      list<Absyn.Exp> c;
      list<list<SCode.EEquation>> tb;
      list<SCode.EEquation> eb;
      
    case ((e, leq)::rest, _, _, _)
      equation
        c  = {};
        tb = {};
        eb = {};
      then
        (c, tb, eb);
  end match; 
end mkIf;

protected function mkWhen
  input list<tuple<DAE.Exp, list<Equation>>> inBranches;
  input Option<Component> inParent;
  input Absyn.Path inClassName;
  input FunctionHashTable inFunctions;
  output Absyn.Exp condition;
  output list<SCode.EEquation> eEquationLst;
  output list<tuple<Absyn.Exp, list<SCode.EEquation>>> elseBranches;
algorithm
  (condition, eEquationLst, elseBranches) := match(inBranches, inParent, inClassName, inFunctions)
    local
      DAE.Exp e;
      list<Equation> leq;
      list<tuple<DAE.Exp, list<Equation>>> rest;
      Absyn.Exp c;
      list<SCode.EEquation> eel;
      list<tuple<Absyn.Exp, list<SCode.EEquation>>> eb;
    
    case ((e, leq)::rest,  _, _, _)
      equation
        c  = mkExp(e);
        eel = {};
        eb = {};
      then
        (c, eel, eb);
  end match; 
end mkWhen;

public function mkAlgorithm
  input list<Statement> inAlgorithm;
  input Option<Component> inParent;
  input Absyn.Path inClassName;
  input FunctionHashTable inFunctions;
  output SCode.AlgorithmSection outAlgorithm;
algorithm
  outAlgorithm := match(inAlgorithm, inParent, inClassName, inFunctions)
    local
      list<SCode.Statement> stmts;
      
    case (_,  _, _, _)
      equation
        stmts = List.map3(inAlgorithm, mkStatement, inParent, inClassName, inFunctions);
      then 
        SCode.ALGORITHM(stmts);
  end match;  
end mkAlgorithm;

protected function mkStatement
  input Statement inStmt;
  input Option<Component> inParent;
  input Absyn.Path inClassName;
  input FunctionHashTable inFunctions;
  output SCode.Statement outStmt;
algorithm
  outStmt := match (inStmt, inParent, inClassName, inFunctions)
    local
      String name;
      DAE.Exp lhs, rhs, e1, e2, e3, e;
      DAE.ComponentRef cr, cr1, cr2;
      Absyn.Exp al, ar, ae, ae1, ae2, ae3;
      Absyn.ComponentRef acr1, acr2, acr;
      Option<Absyn.Exp> aeOpt;
      Option<DAE.Exp> eOpt;
      list<Statement> body;
      Absyn.Info info;
      Prefix prefix;
      SCode.Statement stmt;
      list<SCode.Statement> stmts;
      list<tuple<DAE.Exp, list<Statement>>> branches;
      Absyn.Exp boolExpr;
      list<SCode.Statement> trueBranch;
      list<tuple<Absyn.Exp, list<SCode.Statement>>> elseIfBranch;
      list<SCode.Statement> elseBranch;

    case (InstTypes.ASSIGN_STMT(lhs = lhs, rhs = rhs, info=info), _, _, _)
      equation
        al = mkExp(lhs);
        ar = mkExp(rhs);
        stmt = SCode.ALG_ASSIGN(al, ar, NONE(), info); 
      then
        stmt;
            
    case (InstTypes.FUNCTION_ARRAY_INIT(name = name, info = info), _, _, _)
      equation
        // ??
      then 
        fail();
    
    case (InstTypes.NORETCALL_STMT(exp = e, info = info), _, _, _)
      equation
        ae = mkExp(e);
        stmt = SCode.ALG_NORETCALL(ae, NONE(), info);
      then 
        stmt;
    
    case (InstTypes.IF_STMT(branches = branches, info = info), _, _, _)
      equation
        (boolExpr, trueBranch, elseIfBranch, elseBranch) =
          mkAlgIf(branches,  inParent, inClassName, inFunctions);
        stmt = SCode.ALG_IF(boolExpr, trueBranch, elseIfBranch, elseBranch, NONE(), info);
      then
        stmt;
    
    case (InstTypes.FOR_STMT(name, _, _, eOpt, body, info),  _, _, _)
      equation
        aeOpt = mkExpOpt(eOpt); 
        stmts = List.map3(body, mkStatement, inParent, inClassName, inFunctions);
        stmt = SCode.ALG_FOR(name, aeOpt, stmts, NONE(), info);
      then
        stmt;    
    
    else
      equation
        print("Unknown statement in SCodeTransform.mkStatement\n");
      then fail();
  end match;
end mkStatement;

protected function mkAlgIf
  input list<tuple<DAE.Exp, list<Statement>>> inBranches;
  input Option<Component> inParent;
  input Absyn.Path inClassName;
  input FunctionHashTable inFunctions;
  output Absyn.Exp boolExpr;
  output list<SCode.Statement> trueBranch;
  output list<tuple<Absyn.Exp, list<SCode.Statement>>> elseIfBranch;
  output list<SCode.Statement> elseBranch;
algorithm
  (boolExpr, trueBranch, elseIfBranch, elseBranch) := match(inBranches, inParent, inClassName, inFunctions)
    local
      DAE.Exp e;
      list<Statement> lal;
      list<tuple<DAE.Exp, list<Statement>>> rest;
      Absyn.Exp b;
      list<SCode.Statement> tb;
      list<tuple<Absyn.Exp, list<SCode.Statement>>> eib;
      list<SCode.Statement> eb;
            
    case ((e, lal)::rest,  _, _, _)
      equation
        b  = mkExp(e);
        tb = {};
        eib = {};
        eb = {};
      then
        (b, tb, eib, eb);
  end match; 
end mkAlgIf;

/*
protected function lookupFunction
  input Absyn.Path inPath;
  input HashTablePathToFunction.HashTable inTable;
  output Function outFunction;
algorithm
  outFunction := matchcontinue(inPath, inTable)
    local
      String func_str;

    case (_, _) then BaseHashTable.get(inPath, inTable);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); 
        func_str = Absyn.pathString(inPath);
        Debug.traceln("- Typing.lookupFunction could not find the function " +& func_str);
      then
        fail();

  end matchcontinue;
end lookupFunction;
        
public function typeFunction
  input Absyn.Path inPath;
  input tuple<HashTablePathToFunction.HashTable, SymbolTable> inTpl;
  output tuple<HashTablePathToFunction.HashTable, SymbolTable> outTpl;
protected
  HashTablePathToFunction.HashTable ht;
  SymbolTable st;
  Function func;
algorithm
  (ht, st) := inTpl;
  func := lookupFunction(inPath, ht);
  outTpl := typeFunction2(func, inPath, ht, st);
end typeFunction;
  
public function typeFunction2
  input Function inFunction;
  input Absyn.Path inPath;
  input FunctionTable inFunctionTable;
  input SymbolTable inSymbolTable;
  output tuple<FunctionTable, SymbolTable> outTuple;
algorithm
  outTuple := matchcontinue (inFunction, inPath, inFunctionTable, inSymbolTable)
    local
      list<InstTypes.Element> inputs,outputs,locals;
      list<InstTypes.Statement> al;
      HashTablePathToFunction.HashTable ht;
      SymbolTable st;

    case (InstTypes.FUNCTION(inputs = inputs, outputs = outputs, locals = locals,
        algorithms = al), _, ht, st)
      equation
        st = InstSymbolTable.addFunctionScope(st);
        (_, st) = InstSymbolTable.addElements(inputs, st);
        (_, st) = InstSymbolTable.addElements(outputs, st);
        (_, st) = InstSymbolTable.addElements(locals, st);
        (inputs, st) = List.map2Fold(inputs, mkElement, NONE(), CONTEXT_FUNCTION(), st);
        (outputs, st) = List.map2Fold(outputs, mkElement, NONE(), CONTEXT_FUNCTION(), st);
        (locals, st) = List.map2Fold(locals, mkElement, NONE(), CONTEXT_FUNCTION(), st);
        al = typeStatements(al, CONTEXT_FUNCTION(), st);
        ht = BaseHashTable.add((inPath, InstTypes.FUNCTION(inPath, inputs, outputs, locals, al)), ht);
        _::st = st;
      then
        ((ht, st));

    case (InstTypes.RECORD(path = _), _, ht, st)
      equation
        print("- Typing.typeFunction2: Support for record constructors not yet implemented.\n");
      then
        ((ht, st));

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Typing.typeFunction2 failed on function " +&
          Absyn.pathString(inPath));
      then 
        fail();

  end matchcontinue;
end typeFunction2;
*/

end SCodeTransform;
