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

encapsulated package SCodeFlatten
" file:        SCodeFlatten.mo
  package:     SCodeFlatten
  description: SCode flattening

  RCS: $Id$

  This module flattens the SCode representation by removing all extends, imports
  and redeclares, and fully qualifying class names.
"

public import Absyn;
public import SCode;

protected import Debug;
protected import Error;
protected import Util;
protected import Dump;

protected type Import = Absyn.Import;

protected uniontype ImportTable
  record IMPORT_TABLE
    list<Import> qualifiedImports;
    list<Import> unqualifiedImports;
  end IMPORT_TABLE;
end ImportTable;

protected uniontype Extends
  record EXTENDS
    Absyn.Path baseClass;
    list<SCode.Element> redeclareModifiers;
  end EXTENDS;
end Extends;

protected uniontype ExtendsTable
  record EXTENDS_TABLE
    list<Extends> baseClasses;
    list<SCode.Class> classExtends;
  end EXTENDS_TABLE;
end ExtendsTable;

protected uniontype FrameType
  record NORMAL_SCOPE end NORMAL_SCOPE;
  record ENCAPSULATED_SCOPE end ENCAPSULATED_SCOPE;
  record IMPLICIT_SCOPE end IMPLICIT_SCOPE;
end FrameType;

protected uniontype Frame
  record FRAME
    Option<String> name;
    FrameType frameType;
    AvlTree clsAndVars;
    ExtendsTable extendsTable;
    ImportTable importTable;
  end FRAME;
end Frame;

protected uniontype Item
  record VAR
    SCode.Element var;
  end VAR;

  record CLASS
    SCode.Class cls;
    Env env;
  end CLASS;

  record BUILTIN
    String name;
  end BUILTIN;
end Item;

protected type Env = list<Frame>;
protected constant Env emptyEnv = {};

protected constant Item BUILTIN_REAL = BUILTIN("Real");
protected constant Item BUILTIN_INTEGER = BUILTIN("Integer");
protected constant Item BUILTIN_BOOLEAN = BUILTIN("Boolean");
protected constant Item BUILTIN_STRING = BUILTIN("String");
protected constant Item BUILTIN_STATESELECT = BUILTIN("StateSelect");
protected constant Item BUILTIN_EXTERNALOBJECT = BUILTIN("ExternalObject");

public function flatten
  input SCode.Program inProgram;
  output SCode.Program outProgram;
protected
  Env env;
algorithm
  env := newEnvironment(NONE());
  env := buildInitialEnv();
  env := extendEnvWithClasses(inProgram, env);
  env := insertClassExtendsIntoEnv(env);
  outProgram := flattenProgram(inProgram, env);
end flatten;

protected function flattenProgram
  input SCode.Program inProgram;
  input Env inEnv;
  output SCode.Program outProgram;
algorithm
  outProgram := Util.listMap1(inProgram, lookupClassNames, inEnv);
end flattenProgram;

protected function lookupClassNames
  input SCode.Class inClass;
  input Env inEnv;
  output SCode.Class outClass;
protected
  SCode.Ident name;
  Boolean part_pre, encap_pre;
  SCode.Restriction restriction;
  SCode.ClassDef cdef;
  Absyn.Info info;
  Env env;
algorithm
  SCode.CLASS(name, part_pre, encap_pre, restriction, cdef, info) := inClass;
  env := enterScope(inEnv, name);
  cdef := lookupClassDefNames(cdef, env);
  outClass := SCode.CLASS(name, part_pre, encap_pre, restriction, cdef, info);
end lookupClassNames;

protected function lookupClassDefNames
  input SCode.ClassDef inClassDef;
  input Env inEnv;
  output SCode.ClassDef outClassDef;
algorithm
  outClassDef := match(inClassDef, inEnv)
    local
      list<SCode.Element> el, ex, cl, im, co, ud;
      list<SCode.Equation> neql, ieql;
      list<SCode.AlgorithmSection> nal, ial;
      Option<Absyn.ExternalDecl> extdecl;
      list<SCode.Annotation> annl;
      Option<SCode.Comment> cmt;
      SCode.ClassDef cdef;
      Env env;

    case (SCode.PARTS(el, neql, ieql, nal, ial, extdecl, annl, cmt), env)
      equation
        // Lookup elements.
        el = Util.listMap1(el, lookupElement, env);

        // Lookup equations and algorithm names.
        neql = Util.listMap1(neql, lookupEquation, env);
        ieql = Util.listMap1(ieql, lookupEquation, env);
        nal = Util.listMap1(nal, lookupAlgorithm, env);
        ial = Util.listMap1(ial, lookupAlgorithm, env);
        cdef = SCode.PARTS(el, neql, ieql, nal, ial, extdecl, annl, cmt);
      then
        cdef;

    //case (SCode.CLASS_EXTENDS
    //case (SCode.DERIVED

    case (SCode.ENUMERATION(enumLst = _), _) then inClassDef;

    //case (SCode.OVERLOAD
    //case (SCode.PDER
    else then inClassDef;
  end match;
end lookupClassDefNames;

protected function lookupElement
  input SCode.Element inElement;
  input Env inEnv;
  output SCode.Element outElement;
algorithm
  outElement := match(inElement, inEnv)
    // Lookup component types, modifications and conditions.
    case (SCode.COMPONENT(component = _), _)
      then lookupComponent(inElement, inEnv);

    // Lookup class definitions.
    case (SCode.CLASSDEF(name = _), _)
      then lookupClassDefElementNames(inElement, inEnv);

    // Lookup base class and modifications in extends clauses.
    case (SCode.EXTENDS(baseClassPath = _), _)
      then lookupExtends(inElement, inEnv);

    else then inElement;
  end match;
end lookupElement;
    
protected function lookupClassDefElementNames
  input SCode.Element inClassDefElement;
  input Env inEnv;
  output SCode.Element outClassDefElement;
protected
  SCode.Ident name;
  Boolean fp, rp;
  SCode.Class cls;
  Option<Absyn.ConstrainClass> cc;
algorithm
  SCode.CLASSDEF(name, fp, rp, cls, cc) := inClassDefElement;
  cls := lookupClassNames(cls, inEnv);
  outClassDefElement := SCode.CLASSDEF(name, fp, rp, cls, cc);
end lookupClassDefElementNames;

protected function lookupComponent
  input SCode.Element inComponent;
  input Env inEnv;
  output SCode.Element outComponent;
protected
  SCode.Ident name;
  Absyn.InnerOuter io;
  Boolean fp, rp, pp;
  SCode.Attributes attr;
  Absyn.TypeSpec type_spec;
  SCode.Mod mod;
  Option<SCode.Comment> cmt;
  Option<Absyn.Exp> cond;
  Option<Absyn.Info> info;
  Option<Absyn.ConstrainClass> cc;
algorithm
  SCode.COMPONENT(name, io, fp, rp, pp, attr, type_spec, mod, cmt, cond, 
    info, cc) := inComponent;
  (_, type_spec, _) := lookupTypeSpec(type_spec, inEnv);
  mod := lookupModifier(mod, inEnv);
  cond := lookupOptExp(cond, inEnv);
  outComponent := SCode.COMPONENT(name, io, fp, rp, pp, attr, type_spec, mod,
    cmt, cond, info, cc);
end lookupComponent;

protected function lookupTypeSpec
  input Absyn.TypeSpec inTypeSpec;
  input Env inEnv;
  output Item outItem;
  output Absyn.TypeSpec outTypeSpec;
  output Env outTypeEnv;
algorithm
  (outItem, outTypeSpec, outTypeEnv) := match(inTypeSpec, inEnv)
    local
      Absyn.Path path;
      Absyn.Ident name;
      Option<Absyn.ArrayDim> array_dim;
      Item item;
      Env env;

    case (Absyn.TPATH(path, array_dim), _)
      equation
        (item, path, SOME(env)) = lookupName(path, inEnv);
      then
        (item, Absyn.TPATH(path, array_dim), env);

  end match;
end lookupTypeSpec;

protected function lookupExtends
  input SCode.Element inExtends;
  input Env inEnv;
  output SCode.Element outExtends;
protected
  Absyn.Path path;
  SCode.Mod mod;
  Option<SCode.Annotation> ann;
  Absyn.Info info;
  Env env;
algorithm
  SCode.EXTENDS(path, mod, ann, info) := inExtends;
  env := removeExtendsFromLocalScope(inEnv);
  (_, path, _) := lookupName(path, env);
  mod := lookupModifier(mod, inEnv);
  outExtends := SCode.EXTENDS(path, mod, ann, info);
end lookupExtends;

protected function lookupEquation
  input SCode.Equation inEquation;
  input Env inEnv;
  output SCode.Equation outEquation;
protected
  SCode.EEquation equ;
algorithm
  SCode.EQUATION(equ) := inEquation;
  (equ, _) := SCode.traverseEEquations(equ, (lookupEEquationTraverser, inEnv));
  outEquation := SCode.EQUATION(equ);
end lookupEquation;

protected function lookupEEquationTraverser
  input tuple<SCode.EEquation, Env> inTuple;
  output tuple<SCode.EEquation, Env> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      SCode.EEquation equ;
      SCode.Ident iter_name;
      Env env;

    case ((equ as SCode.EQ_FOR(index = iter_name), env))
      equation
        env = extendEnvWithIterators({(iter_name, NONE())}, env);
        (equ, _) = SCode.traverseEEquationExps(equ, (traverseExp, env));
      then
        ((equ, env));

    case ((equ, env))
      equation
        (equ, _) = SCode.traverseEEquationExps(equ, (traverseExp, env));
      then
        ((equ, env));

  end match;
end lookupEEquationTraverser;

protected function traverseExp
  input tuple<Absyn.Exp, Env> inTuple;
  output tuple<Absyn.Exp, Env> outTuple;
protected
  Absyn.Exp exp;
  Env env;
algorithm
  (exp, env) := inTuple;
  (exp, (_, _, env)) := Absyn.traverseExpBidir(exp,
    (lookupExpTraverserEnter, lookupExpTraverserExit, env));
  outTuple := (exp, env);
end traverseExp;

protected function lookupAlgorithm
  input SCode.AlgorithmSection inAlgorithm;
  input Env inEnv;
  output SCode.AlgorithmSection outAlgorithm;
protected
  list<SCode.Statement> statements;
algorithm
  SCode.ALGORITHM(statements) := inAlgorithm;
  statements := Util.listMap1(statements, lookupStatement, inEnv);
  outAlgorithm := SCode.ALGORITHM(statements);
end lookupAlgorithm;

protected function lookupStatement
  input SCode.Statement inStatement;
  input Env inEnv;
  output SCode.Statement outStatement;
protected
  Env env;
algorithm
  (outStatement, _) := SCode.traverseStatements(inStatement,
    (lookupStatementTraverser, inEnv));
end lookupStatement;

protected function lookupStatementTraverser
  input tuple<SCode.Statement, Env> inTuple;
  output tuple<SCode.Statement, Env> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      Absyn.ForIterators iters;
      Env env;
      SCode.Statement stmt;

    case ((stmt as SCode.ALG_FOR(iterators = iters), env))
      equation
        env = extendEnvWithIterators(iters, env);
        (stmt, _) = SCode.traverseStatementExps(stmt, (traverseExp, env));
      then
        ((stmt, env));

    case ((stmt, env)) 
      equation
        (stmt, _) = SCode.traverseStatementExps(stmt, (traverseExp, env));
      then
        ((stmt, env));

  end match;
end lookupStatementTraverser;

protected function lookupModifier
  input SCode.Mod inMod;
  input Env inEnv;
  output SCode.Mod outMod;
algorithm
  outMod := match(inMod, inEnv)
    local
      Boolean fp;
      Absyn.Each ep;
      list<SCode.SubMod> sub_mods;
      Option<tuple<Absyn.Exp, Boolean>> opt_exp;
      list<SCode.Element> el;

    case (SCode.MOD(fp, ep, sub_mods, opt_exp), _)
      equation
        opt_exp = lookupModOptExp(opt_exp, inEnv);
        sub_mods = Util.listMap1(sub_mods, lookupSubMod, inEnv);
      then
        SCode.MOD(fp, ep, sub_mods, opt_exp);

    case (SCode.REDECL(fp, el), _)
      equation
        //print("SCodeFlatten.lookupModifier: REDECL\n");
      then
        //fail();
        inMod;

    case (SCode.NOMOD(), _) then inMod;
  end match;
end lookupModifier;

protected function lookupModOptExp
  input Option<tuple<Absyn.Exp, Boolean>> inOptExp;
  input Env inEnv;
  output Option<tuple<Absyn.Exp, Boolean>> outOptExp;
algorithm
  outOptExp := match(inOptExp, inEnv)
    local
      Absyn.Exp exp;
      Boolean delay_elab;

    case (SOME((exp, delay_elab)), _)
      equation
        exp = lookupExp(exp, inEnv);
      then
        SOME((exp, delay_elab));

    case (NONE(), _) then inOptExp;
  end match;
end lookupModOptExp;

protected function lookupSubMod
  input SCode.SubMod inSubMod;
  input Env inEnv;
  output SCode.SubMod outSubMod;
algorithm
  outSubMod := match(inSubMod, inEnv)
    local
      SCode.Ident ident;
      list<SCode.Subscript> subs;
      SCode.Mod mod;

    case (SCode.NAMEMOD(ident = ident, A = mod), _)
      equation
        mod = lookupModifier(mod, inEnv);
      then
        SCode.NAMEMOD(ident, mod);

    case (SCode.IDXMOD(subscriptLst = subs, an = mod), _)
      equation
        subs = Util.listMap1(subs, lookupSubscript, inEnv);
        mod = lookupModifier(mod, inEnv);
      then
        SCode.IDXMOD(subs, mod);
  end match;
end lookupSubMod;

protected function lookupSubscript
  input SCode.Subscript inSub;
  input Env inEnv;
  output SCode.Subscript outSub;
algorithm
  outSub := match(inSub, inEnv)
    local
      Absyn.Exp exp;

    case (Absyn.SUBSCRIPT(subScript = exp), _)
      equation
        exp = lookupExp(exp, inEnv);
      then
        Absyn.SUBSCRIPT(exp);

    case (Absyn.NOSUB(), _) then inSub;
  end match;
end lookupSubscript;

protected function lookupExp
  input Absyn.Exp inExp;
  input Env inEnv;
  output Absyn.Exp outExp;
algorithm
  (outExp, _) := Absyn.traverseExpBidir(inExp, 
    (lookupExpTraverserEnter, lookupExpTraverserExit, inEnv));
end lookupExp;

protected function lookupOptExp
  input Option<Absyn.Exp> inExp;
  input Env inEnv;
  output Option<Absyn.Exp> outExp;
algorithm
  outExp := match(inExp, inEnv)
    local
      Absyn.Exp exp;

    case (SOME(exp), _)
      equation
        exp = lookupExp(exp, inEnv);
      then
        SOME(exp);

    case (NONE(), _) then NONE();
  end match;
end lookupOptExp;

protected function lookupExpTraverserEnter
  input tuple<Absyn.Exp, Env> inTuple;
  output tuple<Absyn.Exp, Env> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      Env env;
      Absyn.ComponentRef cref;
      Absyn.FunctionArgs args;
      Absyn.Exp exp;
      Absyn.ForIterators iters;

    case ((Absyn.CREF(componentRef = cref), env))
      equation
        cref = lookupComponentRef(cref, env);
      then
        ((Absyn.CREF(cref), env));

    case ((exp as Absyn.CALL(functionArgs = 
        Absyn.FOR_ITER_FARG(iterators = iters)), env))
      equation
        env = extendEnvWithIterators(iters, env);
      then
        ((exp, env));

    case ((Absyn.CALL(function_ = cref, functionArgs = args), env))
      equation
        cref = lookupComponentRef(cref, env);
        // TODO: handle function arguments
      then
        ((Absyn.CALL(cref, args), env));

    case ((Absyn.PARTEVALFUNCTION(function_ = cref, functionArgs = args), env))
      equation
        cref = lookupComponentRef(cref, env);
        // TODO: handle function arguments
      then
        ((Absyn.PARTEVALFUNCTION(cref, args), env));
    
    else then inTuple;
  end matchcontinue;
end lookupExpTraverserEnter;

protected function lookupExpTraverserExit
  input tuple<Absyn.Exp, Env> inTuple;
  output tuple<Absyn.Exp, Env> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      Absyn.Exp e;
      Env env;

    case ((e as Absyn.CALL(functionArgs = Absyn.FOR_ITER_FARG(iterators = _)),
        FRAME(frameType = IMPLICIT_SCOPE()) :: env))
      then
        ((e, env));

    else then inTuple;
  end match;
end lookupExpTraverserExit;


protected function lookupBuiltinType
  input Absyn.Ident inName;
  output Item outItem;
algorithm
  outItem := match(inName)
    case "Real" then BUILTIN_REAL;
    case "Integer" then BUILTIN_INTEGER;
    case "Boolean" then BUILTIN_BOOLEAN;
    case "String" then BUILTIN_STRING;
    case "StateSelect" then BUILTIN_STATESELECT;
    case "ExternalObject" then BUILTIN_EXTERNALOBJECT;
  end match;
end lookupBuiltinType;

protected function lookupName
  "Looks up a simple or qualified name in the environment and returns the
  environment item corresponding to the name, the fully qualified path for the
  name and optionally the enclosing scope of the name if the name references a
  class."
  input Absyn.Path inName;
  input Env inEnv;
  output Item outItem;
  output Absyn.Path outName;
  output Option<Env> outEnv;
algorithm
  (outItem, outName, outEnv) := matchcontinue(inName, inEnv)
    local
      Absyn.Ident id;
      Item item;
      Absyn.Path path, new_path;
      Env env;
      Option<Env> item_env;

    case (Absyn.IDENT(name = id), _)
      equation
        item = lookupBuiltinType(id);
      then
        (item, inName, SOME(emptyEnv));

    // Simple name.
    case (Absyn.IDENT(name = id), _)
      equation
        (item, new_path, env) = lookupSimpleName(id, inEnv);
      then
        (item, new_path, SOME(env));

    // Qualified name.
    case (Absyn.QUALIFIED(name = id, path = path), _)
      equation
        // Look up the first identifier.
        (item, new_path, env) = lookupSimpleName(id, inEnv);
        // Look up the rest of the name in the environment of the first
        // identifier.
        (item, path, env) = lookupNameInItem(path, item, env);
        path = Absyn.joinPaths(new_path, path);
      then
        (item, path, SOME(env));
      
    // Qualified name.
    case (Absyn.QUALIFIED(name = id, path = path), _)
      equation
        print("Failed!\n");
        // Look up the first identifier.
        (item, new_path, env) = lookupSimpleName(id, inEnv);
        // Look up the rest of the name in the environment of the first
        // identifier.
        (item, path, env) = lookupNameInItem(path, item, env);
        path = Absyn.joinPaths(new_path, path);
      then
        (item, path, SOME(env));
          
    else
      equation
        print("- SCodeFlatten.lookupName failed for " +&
          Absyn.pathString(inName) +& " in " +&
          Absyn.pathString(getEnvPath(inEnv)) +& "\n");
      then
        fail();
        
  end matchcontinue;
end lookupName;

protected function lookupComponentRef
  "Look up a component reference in the environment and returns it fully
  qualified."
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  output Absyn.ComponentRef outCref;

algorithm
  outCref := matchcontinue(inCref, inEnv)
    local
      Absyn.ComponentRef cref;

    case (Absyn.CREF_QUAL(name = "StateSelect", subScripts = {}, 
        componentRef = Absyn.CREF_IDENT(name = _)), _)
      then inCref;

    case (_, _)
      equation
        // First look up all subscripts, because all subscripts should be found
        // in the enclosing scope of the component reference.
        cref = lookupComponentRefSubs(inCref, inEnv);
        // Then look up the component reference itself.
        cref = lookupComponentRef2(cref, inEnv);
      then
        cref;

    case (_, _)
      equation
        print("lookupComponentRef failed for " +&
        Absyn.printComponentRefStr(inCref) +& " in " +& getEnvName(inEnv) +& "\n");
        // First look up all subscripts, because all subscripts should be found
        // in the enclosing scope of the component reference.
        cref = lookupComponentRefSubs(inCref, inEnv);
        // Then look up the component reference itself.
        cref = lookupComponentRef2(cref, inEnv);
      then
        cref;

    else
      equation
        print("- SCodeFlatten.lookupComponentRef failed for " +&
          Absyn.printComponentRefStr(inCref) +& " in " +&
          Absyn.pathString(getEnvPath(inEnv)) +& "\n");
      then
        fail();

  end matchcontinue;
end lookupComponentRef;

protected function lookupComponentRef2
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := match(inCref, inEnv)
    local
      Absyn.ComponentRef cref, rest_cref;
      Absyn.Ident name;
      list<Absyn.Subscript> subs;
      Absyn.Path path, new_path;
      Env env;
      Item item;

    case (Absyn.CREF_IDENT(name, subs), inEnv)
      equation
        (_, path, _) = lookupSimpleName(name, inEnv);
        cref = Absyn.pathToCrefWithSubs(path, subs);
      then
        cref;

    case (Absyn.CREF_QUAL(name, subs, rest_cref), inEnv)
      equation
        // Lookup the first identifier.
        (item, new_path, env) = lookupSimpleName(name, inEnv);
        cref = Absyn.pathToCrefWithSubs(new_path, subs);

        // Lookup the rest of the cref in the enclosing scope of the first
        // identifier.
        (item, rest_cref) = lookupCrefInItem(rest_cref, item, env);
        cref = joinCrefs(cref, rest_cref); 
      then
        cref;

    case (Absyn.CREF_FULLYQUALIFIED(componentRef = cref), inEnv)
      equation
        cref = lookupComponentRef2(cref, inEnv);
      then
        Absyn.CREF_FULLYQUALIFIED(cref);

  end match;
end lookupComponentRef2;

protected function joinCrefs
  input Absyn.ComponentRef inCref1;
  input Absyn.ComponentRef inCref2;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := match(inCref1, inCref2)
    case (_, Absyn.CREF_FULLYQUALIFIED(componentRef = _)) then inCref2;
    else then Absyn.joinCrefs(inCref1, inCref2);
  end match;
end joinCrefs;
    
protected function lookupComponentRefSubs
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := match(inCref, inEnv)
    local
      Absyn.Ident name;
      Absyn.ComponentRef cref;
      list<Absyn.Subscript> subs;

    case (Absyn.CREF_IDENT(name, subs), _)
      equation
        subs = Util.listMap1(subs, lookupSubscript, inEnv);
      then
        Absyn.CREF_IDENT(name, subs);

    case (Absyn.CREF_QUAL(name, subs, cref), _)
      equation
        subs = Util.listMap1(subs, lookupSubscript, inEnv);
        cref = lookupComponentRefSubs(cref, inEnv);
      then
        Absyn.CREF_QUAL(name, subs, cref);

    case (Absyn.CREF_FULLYQUALIFIED(componentRef = cref), _)
      equation
        cref = lookupComponentRefSubs(cref, inEnv);
      then
        Absyn.CREF_FULLYQUALIFIED(cref);

  end match;
end lookupComponentRefSubs;

protected function lookupSimpleName
  input Absyn.Ident inName;
  input Env inEnv;
  output Item outItem;
  output Absyn.Path outPath;
  output Env outEnv;
algorithm
  (SOME(outItem), SOME(outPath), SOME(outEnv)) := 
    lookupSimpleName2(inName, inEnv);
end lookupSimpleName;

protected function lookupSimpleName2
  input Absyn.Ident inName;
  input Env inEnv;
  output Option<Item> outItem;
  output Option<Absyn.Path> outPath;
  output Option<Env> outEnv;
algorithm
  (outItem, outPath, outEnv) := matchcontinue(inName, inEnv)
    local
      FrameType frame_type;
      Env rest_env;
      Option<Item> opt_item;
      Option<Absyn.Path> opt_path;
      Option<Env> opt_env;

    case (_, _)
      equation
        (opt_item, opt_path, opt_env) = lookupInLocalScope(inName, inEnv);
      then
        (opt_item, opt_path, opt_env);

    case (_, FRAME(frameType = frame_type) :: rest_env)
      equation
        frameNotEncapsulated(frame_type);
        (opt_item, opt_path, opt_env) = lookupSimpleName2(inName, rest_env);
      then
        (opt_item, opt_path, opt_env);

  end matchcontinue;
end lookupSimpleName2;

protected function frameNotEncapsulated
  input FrameType frameType;
algorithm
  _ := match(frameType)
    case ENCAPSULATED_SCOPE() then fail();
    else then ();
  end match;
end frameNotEncapsulated;

protected function lookupInLocalScope
  "Looks up a simple identifier in the environment. Returns SOME(item) if an
  item is found, NONE() if a partial match was found (for example when the name
  matches the import name of an import, but the imported class couldn't be
  found), or fails if no match is found."
  input Absyn.Ident inName;
  input Env inEnv;
  output Option<Item> outItem;
  output Option<Absyn.Path> outPath;
  output Option<Env> outEnv;
algorithm
  (outItem, outPath, outEnv) := matchcontinue(inName, inEnv)
    local
      AvlTree cls_and_vars;
      Env rest_env, env;
      Item item;
      Option<Item> opt_item;
      Option<Absyn.Path> opt_path;
      list<Import> imps;
      FrameType frame_type;
      Absyn.Path path;
      Option<Env> opt_env;

    // Look among the locally declared components.
    case (_, FRAME(clsAndVars = cls_and_vars) :: _)
      equation
        item = avlTreeGet(cls_and_vars, inName);
      then
        (SOME(item), SOME(Absyn.IDENT(inName)), SOME(inEnv));

    // Look among the inherited components.
    case (_, _)
      equation
        (item, path, _, env) = lookupInBaseClasses(inName, inEnv);
      then
        (SOME(item), SOME(path), SOME(env));

    // Look among the qualified imports.
    case (_, FRAME(importTable = IMPORT_TABLE(qualifiedImports = imps)) :: _)
      equation
        (opt_item, opt_path, opt_env) = 
          lookupInQualifiedImports(inName, imps, inEnv);
      then
        (opt_item, opt_path, opt_env);

    // Look among the unqualified imports.
    case (_, FRAME(importTable = IMPORT_TABLE(unqualifiedImports = imps)) :: _)
      equation
        (opt_item, opt_path, opt_env) = 
          lookupInUnqualifiedImports(inName, imps, inEnv);
      then
        (opt_item, opt_path, opt_env);

    // Look in the next scope only if the current scope is an implicit scope
    // created by a for loop.
    case (_, FRAME(frameType = IMPLICIT_SCOPE()) :: rest_env)
      equation
        (opt_item, opt_path, opt_env) = lookupInLocalScope(inName, rest_env);
      then
        (opt_item, opt_path, opt_env);

  end matchcontinue;
end lookupInLocalScope;

protected function lookupInBaseClasses
  "Looks up an identifier by following the extends clauses in a scope."
  input Absyn.Ident inName;
  input Env inEnv;
  output Item outItem;
  output Absyn.Path outPath;
  output Absyn.Path outBaseClass;
  output Env outEnv;

  Env env;
  list<Extends> bcl;
algorithm
  FRAME(extendsTable = EXTENDS_TABLE(baseClasses = bcl as _ :: _)) :: _ := inEnv;
  // We need to remove the extends from the current scope, because the names of
  // extended classes should not be found by lookup through the extends-clauses
  // (Modelica Specification 3.2, section 5.6.1.).
  env := removeExtendsFromLocalScope(inEnv);
  (outItem, outPath, outBaseClass, outEnv) := 
    lookupInBaseClasses2(inName, bcl, env);
end lookupInBaseClasses;

protected function lookupInBaseClasses2
  input Absyn.Ident inName;
  input list<Extends> inBaseClasses;
  input Env inEnv;
  output Item outItem;
  output Absyn.Path outPath;
  output Absyn.Path outBaseClass;
  output Env outEnv;
algorithm
  (outItem, outPath, outBaseClass, outEnv) := 
  matchcontinue(inName, inBaseClasses, inEnv)
    local
      Absyn.Path bc, path;
      list<Extends> rest_bc;
      Item item;
      Env env;
      list<SCode.Element> redecls;

    // Look in the first base class.
    case (_, EXTENDS(baseClass = bc, redeclareModifiers = redecls) :: _, inEnv)
      equation
        (item, _, SOME(env)) = lookupName(bc, inEnv);
        (item, env) = replaceRedeclaredClassesInEnv(redecls, item, env, inEnv);
        (item, path, env) = lookupNameInItem(Absyn.IDENT(inName), item, env);
      then
        (item, path, bc, env);

    // No match, check the rest of the base classes.
    case (_, _ :: rest_bc, _)
      equation
        (item, path, bc, env) = lookupInBaseClasses2(inName, rest_bc, inEnv);
      then
        (item, path, bc, env);

  end matchcontinue;
end lookupInBaseClasses2;

protected function lookupInQualifiedImports
  input Absyn.Ident inName;
  input list<Import> inImports;
  input Env inEnv;
  output Option<Item> outItem;
  output Option<Absyn.Path> outPath;
  output Option<Env> outEnv;
algorithm
  (outItem, outPath, outEnv) := matchcontinue(inName, inImports, inEnv)
    local
      Absyn.Ident name;
      Absyn.Path path;
      Item item;
      list<Import> rest_imps;
      Import imp;
      Option<Item> opt_item;
      Option<Absyn.Path> opt_path;
      Option<Env> opt_env;
      Env env;

    // No match, search the rest of the list of imports.
    case (_, Absyn.NAMED_IMPORT(name = name) :: rest_imps, _)
      equation
        false = stringEqual(inName, name);
        (opt_item, opt_path, opt_env) = 
          lookupInQualifiedImports(inName, rest_imps, inEnv);
      then
        (opt_item, opt_path, opt_env);

    // Match, look up the fully qualified import path.
    case (_, Absyn.NAMED_IMPORT(name = name, path = path) :: _, _)
      equation
        true = stringEqual(inName, name);
        (item, path, env) = lookupFullyQualified(path, inEnv);  
      then
        (SOME(item), SOME(path), SOME(env));

    // Partial match, return NONE(). This is when only part of the import path
    // can be found, in which case we should stop looking further.
    case (_, Absyn.NAMED_IMPORT(name = name, path = path) :: _, _)
      equation
        true = stringEqual(inName, name);
      then
        (NONE(), NONE(), NONE());

  end matchcontinue;
end lookupInQualifiedImports;

protected function lookupInUnqualifiedImports
  input Absyn.Ident inName;
  input list<Import> inImports;
  input Env inEnv;
  output Option<Item> outItem;
  output Option<Absyn.Path> outPath;
  output Option<Env> outEnv;
algorithm
  (outItem, outPath, outEnv) := matchcontinue(inName, inImports, inEnv)
    local
      Item item;
      Absyn.Path path, path2;
      Option<Item> opt_item;
      Option<Absyn.Path> opt_path;
      list<Import> rest_imps;
      Env env;
      Option<Env> opt_env;

    // For each unqualified import we have to look up the package the import
    // points to, and then look among the public member of the package for the
    // name we are looking for.
    case (_, Absyn.UNQUAL_IMPORT(path = path) :: _, _)
      equation
        // Look up the import path.
        (item, path, env) = lookupFullyQualified(path, inEnv);
        // Look up the name among the public member of the found package.
        (item, path2, env) = lookupNameInItem(Absyn.IDENT(inName), item, env);
        // Combine the paths for the name and the package it was found in.
        path = Absyn.joinPaths(path, path2);
      then
        (SOME(item), SOME(path), SOME(env));

    // No match, continue with the rest of the imports.
    case (_, _ :: rest_imps, _)
      equation
        (opt_item, opt_path, opt_env) = 
          lookupInUnqualifiedImports(inName, rest_imps, inEnv);
      then
        (opt_item, opt_path, opt_env);
  end matchcontinue;
end lookupInUnqualifiedImports;

protected function lookupFullyQualified
  input Absyn.Path inName;
  input Env inEnv;
  output Item outItem;
  output Absyn.Path outPath;
  output Env outEnv;
protected
  Env env;
  Frame top_scope;
  Absyn.Path path, path2;
  Option<Absyn.Path> opt_path;
algorithm
  env := getEnvTopScope(inEnv);
  (outItem, outPath, outEnv) := lookupNameInPackage(inName, env);
  outPath := Absyn.FULLYQUALIFIED(outPath);
end lookupFullyQualified;

protected function lookupNameInPackage
  input Absyn.Path inName;
  input Env inEnv;
  output Item outItem;
  output Absyn.Path outPath;
  output Env outEnv;
algorithm
  (outItem, outPath, outEnv) := match(inName, inEnv)
    local
      Absyn.Ident name;
      Absyn.Path path, new_path;
      AvlTree cls_and_vars;
      Frame top_scope;
      Env rest_env, env;
      Item item;

    case (Absyn.IDENT(name = name), _)
      equation
        (SOME(item), SOME(path), SOME(env)) = lookupInLocalScope(name, inEnv);
      then
        (item, path, env);

    case (Absyn.QUALIFIED(name = name, path = path), top_scope :: _)
      equation
        (SOME(item), SOME(new_path), SOME(env)) = lookupInLocalScope(name, inEnv); 
        (item, path, env) = lookupNameInItem(path, item, env);
        path = Absyn.joinPaths(new_path, path);
      then
        (item, path, env);

  end match;
end lookupNameInPackage;

protected function lookupCrefInPackage
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  output Item outItem;
  output Absyn.ComponentRef outCref;
algorithm
  (outItem, outCref) := match(inCref, inEnv)
    local
      Absyn.Ident name;
      Absyn.Path new_path;
      list<Absyn.Subscript> subs;
      Absyn.ComponentRef cref, cref_rest;
      Item item;
      Frame top_scope;
      Env env;
     
    case (Absyn.CREF_IDENT(name = name, subscripts = subs), _)
      equation
        (SOME(item), SOME(new_path), _) = lookupInLocalScope(name, inEnv);
        cref = Absyn.pathToCrefWithSubs(new_path, subs);
      then
        (item, cref);

    case (Absyn.CREF_QUAL(name = name, subScripts = subs, 
        componentRef = cref_rest), _)
      equation
        (SOME(item), SOME(new_path), SOME(env)) = 
          lookupInLocalScope(name, inEnv);
        (item, cref_rest) = lookupCrefInItem(cref_rest, item, env);
        cref = Absyn.pathToCrefWithSubs(new_path, subs);
        cref = Absyn.joinCrefs(cref, cref_rest);
      then
        (item, cref);

  end match;
end lookupCrefInPackage;

protected function lookupNameInItem
  input Absyn.Path inName;
  input Item inItem;
  input Env inEnv;
  output Item outItem;
  output Absyn.Path outPath;
  output Env outEnv;
algorithm
  (outItem, outPath, outEnv) := match(inName, inItem, inEnv)
    local
      SCode.Element var;
      Item item;
      Absyn.Path path;
      Frame class_env;
      Env env, type_env;
      Absyn.TypeSpec type_spec;
      SCode.Mod mods;
      list<SCode.Element> redeclares;

    case (_, VAR(var = SCode.COMPONENT(typeSpec = type_spec, 
        modifications = mods)), _)
      equation
        (item, _, type_env) = lookupTypeSpec(type_spec, inEnv);
        redeclares = extractRedeclaresFromModifier(mods);
        (item, type_env) = 
          replaceRedeclaredClassesInEnv(redeclares, item, type_env, inEnv);
        (item, path, env) = lookupNameInItem(inName, item, type_env);
      then
        (item, path, env);

    case (_, CLASS(env = {class_env}), _) 
      equation
        env = class_env :: inEnv;
        (item, path, env) = lookupNameInPackage(inName, env);
      then
        (item, path, env);

  end match;
end lookupNameInItem;

protected function lookupCrefInItem
  input Absyn.ComponentRef inCref;
  input Item inItem;
  input Env inEnv;
  output Item outItem;
  output Absyn.ComponentRef outCref;
algorithm
  (outItem, outCref) := match(inCref, inItem, inEnv)
    local
      Item item;
      Absyn.ComponentRef cref;
      Frame class_env;
      Env env, type_env;
      Absyn.TypeSpec type_spec;
      SCode.Mod mods;
      list<SCode.Element> redeclares;

    case (_, VAR(var = SCode.COMPONENT(typeSpec = type_spec, 
        modifications = mods)), _)
      equation
        (item, _, type_env) = lookupTypeSpec(type_spec, inEnv);
        redeclares = extractRedeclaresFromModifier(mods);
        (item, type_env) = 
          replaceRedeclaredClassesInEnv(redeclares, item, type_env, inEnv);
        (item, cref) = lookupCrefInItem(inCref, item, type_env);
      then
        (item, cref);

    case (_, CLASS(env = {class_env}), _)
      equation
        env = class_env :: inEnv;
        (item, cref) = lookupCrefInPackage(inCref, env);
      then
        (item, cref);

  end match;
end lookupCrefInItem;

protected function replaceRedeclaredClassesInEnv
  "If a variable has modifications that redeclare classes in it's instance we
  need to replace those classes in the environment so that the lookup finds the
  right classes. This function takes a list of redeclares from a variables
  modifications and applies them to the environment of the variables type."
  input list<SCode.Element> inRedeclares "The redeclares from the modifications.";
  input Item inItem "The type of the variable.";
  input Env inTypeEnv "The enclosing scopes of the type.";
  input Env inVarEnv "The environment in which the variable was declared.";
  output Item outItem;
  output Env outEnv;
algorithm
  (outItem, outEnv) := matchcontinue(inRedeclares, inItem, inTypeEnv, inVarEnv)
    local
      list<SCode.Element> redeclares;
      SCode.Class cls;
      Env env;
      Frame item_env;

    case (_, VAR(var = _), _, _) then (inItem, inTypeEnv);
    case (_, BUILTIN(name = _), _, _) then (inItem, inTypeEnv);

    case (_, CLASS(cls = cls, env = {item_env}), _, _)
      equation
        redeclares = Util.listMap1(inRedeclares, qualifyRedeclare, inVarEnv);
        // Merge the types environment with it's enclosing scopes to get the
        // enclosing scopes of the classes we need to replace.
        env = item_env :: inTypeEnv;
        env = Util.listFold(redeclares, replaceRedeclaredClassInEnv, env);
        item_env :: env = env;
      then
        (CLASS(cls, {item_env}), env);

    else
      equation
        print("- SCodeFlatten.replaceRedeclaredClassesInEnv failed!\n");
      then
        fail();
  end matchcontinue;
end replaceRedeclaredClassesInEnv;

protected function extractRedeclaresFromModifier
  input SCode.Mod inMod;
  output list<SCode.Element> outRedeclares;
algorithm
  outRedeclares := match(inMod)
    local
      list<SCode.SubMod> sub_mods;
      list<SCode.Element> redeclares;
    
    case (SCode.MOD(subModLst = sub_mods))
      equation
        redeclares = Util.listFold(sub_mods, extractRedeclareFromSubMod, {});
      then
        redeclares;

    else then {};
  end match;
end extractRedeclaresFromModifier;

protected function extractRedeclareFromSubMod
  input SCode.SubMod inMod;
  input list<SCode.Element> inRedeclares;
  output list<SCode.Element> outRedeclares;
algorithm
  outRedeclares := match(inMod, inRedeclares)
    local
      SCode.Element redecl;

    case (SCode.NAMEMOD(A = SCode.REDECL(elementLst = 
        {redecl as SCode.CLASSDEF(name = _)})), _)
      then redecl :: inRedeclares;

    else then inRedeclares;
  end match;
end extractRedeclareFromSubMod;

protected function qualifyRedeclare
  "Since a modifier might redeclare a class in a type with a class that is not
  reachable from the type we need to fully qualify the class. Ex:
    A a(redeclare package P = P1)
  where P1 is not reachable from A."
  input SCode.Element inElement;
  input Env inEnv;
  output SCode.Element outElement;
algorithm
  outElement := matchcontinue(inElement, inEnv)
    local
      SCode.Ident name, name2;
      Absyn.Ident id;
      Boolean fp, rp, pp, ep;
      Option<Absyn.ConstrainClass> cc;
      Option<Absyn.ArrayDim> ad;
      Absyn.Path path;
      SCode.Mod mods;
      Absyn.ElementAttributes attr;
      Option<SCode.Comment> cmt;
      Env env;
      SCode.Restriction res;
      Absyn.Info info;

    case (SCode.CLASSDEF(
          name = name, 
          finalPrefix = fp, 
          replaceablePrefix = rp,
          classDef = SCode.CLASS(
            name = name2,
            partialPrefix = pp,
            encapsulatedPrefix = ep,
            restriction = res,
            classDef = SCode.DERIVED(
              typeSpec = Absyn.TPATH(path, ad),
              modifications = mods, 
              attributes = attr, 
              comment = cmt),
            info = info),
          cc = cc), _)
      equation
        (_, path, SOME(env)) = lookupName(path, inEnv);
        path = mergePathWithEnvPath(path, env);
      then
        SCode.CLASSDEF(name, fp, rp, 
          SCode.CLASS(name2, pp, ep, res,
            SCode.DERIVED(Absyn.TPATH(path, ad), mods, attr, cmt),
            info), cc);

    else
      equation
        print("- SCodeFlatten.qualifyRedeclare failed on " +&
          SCode.printElementStr(inElement) +& " in " +&
          Absyn.pathString(getEnvPath(inEnv)) +& "\n");
      then
        fail();
  end matchcontinue;
end qualifyRedeclare;

protected function mergePathWithEnvPath
  input Absyn.Path inPath;
  input Env inEnv;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue(inPath, inEnv)
    local
      Absyn.Path path;
      Absyn.Ident id;

    case (_, _)
      equation
        id = Absyn.pathLastIdent(inPath);
        path = Absyn.joinPaths(getEnvPath(inEnv), Absyn.IDENT(id));
      then
        path;

    else then inPath;
  end matchcontinue;
end mergePathWithEnvPath;

protected function replaceRedeclaredClassInEnv
  input SCode.Element inRedeclare;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inRedeclare, inEnv)
    local
      SCode.Ident name;
      SCode.Class cls;
      Env env;
      Item item;
      Absyn.Path path;
      Option<Env> opt_env;

    case (SCode.CLASSDEF(name = name, classDef = cls), _)
      equation
        (item, path, SOME(env)) = lookupName(Absyn.IDENT(name), inEnv);
        path = Absyn.joinPaths(getEnvPath(env), path);
        env = replaceClassInEnv(path, cls, inEnv);
      then
        env;

    case (_, _)
      equation
        print("Not a class def: " +& SCode.printElementStr(inRedeclare) +&
            "\n");
      then
        inEnv;

    else then inEnv;
  end match;
end replaceRedeclaredClassInEnv;
        
protected function replaceClassInEnv
  "Replaces a class in the environment with another class, which is needed for
  redeclare. There are two cases here: either the class we want to replace is in
  the current path or it's somewhere else in the environment. If it's in the
  current path we can just go through the frames until we find the right frame
  to replace the class in. If it's not we need to look up the correct class in
  the environment and continue into the class's environment."
  input Absyn.Path inPath;
  input SCode.Class inClass;
  input Env inEnv;
  output Env outEnv;
protected
  Env env;
  Boolean next_scope_available;
  Frame f;
algorithm
  // Reverse the frame order so that the frames are in the same order as the path.
  env := listReverse(inEnv);
  // Make the redeclare in both the current environment and the global.
  // TODO: do this in a better way.
  f :: env := replaceClassInEnv2(inPath, inClass, env);
  {f} := replaceClassInEnv2(inPath, inClass, {f});
  outEnv := listReverse(f :: env);
end replaceClassInEnv;

protected function checkNextScopeAvailability
  "Checks if the next scope in the environment is the scope we are looking for
  next. If the first identifier in the path has the same name as the next scope
  it returns true, otherwise false."
  input Absyn.Path inPath;
  input Env inEnv;
  output Boolean isAvailable;
algorithm
  isAvailable := match(inPath, inEnv)
    local
      String name, scope_name;

    case (Absyn.QUALIFIED(name = name), _ :: FRAME(name = SOME(scope_name)) :: _)
      then stringEqual(name, scope_name);

    else then false;
  end match;
end checkNextScopeAvailability;

protected function replaceClassInEnv2
  "Helper function to replaceClassInEnv."
  input Absyn.Path inPath;
  input SCode.Class inClass;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := replaceClassInEnv3(inPath, inClass, inEnv,
    checkNextScopeAvailability(inPath, inEnv));
end replaceClassInEnv2;

protected function replaceClassInEnv3
  "Helper function to replaceClassInEnv."
  input Absyn.Path inPath;
  input SCode.Class inClass;
  input Env inEnv;
  input Boolean inNextScopeAvailable;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inPath, inClass, inEnv, inNextScopeAvailable)
    local
      String name, scope_name;
      Absyn.Path path;
      Env env, rest_env;
      Frame f;

    // A simple identifier means that the class should be replaced in the
    // current scope.
    case (Absyn.IDENT(name = name), _, _, _)
      equation
        env = replaceClassInScope(name, inClass, inEnv);
      then
        env;

    // If the next frame is the next scope we want to reach we can just continue
    // into it.
    case (Absyn.QUALIFIED(path = path), _, f :: rest_env, true)
      equation
        rest_env = replaceClassInEnv2(path, inClass, rest_env);
        env = f :: rest_env;
      then
        env;

    // If there are no more scopes available in the environment we need to start
    // going into classes in the environment instead.
    case (Absyn.QUALIFIED(name = name, path = path), _, _, false)
      equation
        env = replaceClassInClassEnv(inPath, inClass, inEnv);
      then
        env;

    else
      equation
        print("- SCodeFlatten.replaceClassInEnv3 failed.\n");
      then
        fail();

  end matchcontinue;
end replaceClassInEnv3;

protected function replaceClassInScope
  "Replaces a class in the current scope."
  input SCode.Ident inClassName;
  input SCode.Class inClass;
  input Env inEnv;
  output Env outEnv;
protected
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  ExtendsTable exts;
  ImportTable imps;
  Env env, class_env;
  SCode.ClassDef cdef;
algorithm
  FRAME(name, ty, tree, exts, imps) :: env := inEnv;
  class_env := newEnvironment(SOME(inClassName));
  SCode.CLASS(classDef = cdef) := inClass;
  class_env := extendEnvWithClassComponents(inClassName, cdef, class_env);
  tree := avlTreeReplace(tree, inClassName, CLASS(inClass, class_env));
  outEnv := FRAME(name, ty, tree, exts, imps) :: env;
end replaceClassInScope;

protected function replaceClassInClassEnv
  "Replaces a class in the environment of another class."
  input Absyn.Path inClassPath;
  input SCode.Class inClass;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inClassPath, inClass, inEnv)
    local
      Option<String> frame_name;
      FrameType ty;
      AvlTree tree;
      ExtendsTable exts;
      ImportTable imps;
      Env rest_env, class_env, env;
      Item item;
      String name;
      Absyn.Path path;
      SCode.Class cls;

    // A simple identifier means that we have reached the environment in which
    // the class should be replaced.
    case (Absyn.IDENT(name = name), _, _)
      equation
        env = replaceClassInScope(name, inClass, inEnv);
      then
        env;

    // A qualified path means that we should look up the first identifier and
    // continue into the found class's environment.
    case (Absyn.QUALIFIED(name = name, path = path), _,
        FRAME(frame_name, ty, tree, exts, imps) :: rest_env)
      equation
        CLASS(cls = cls, env = class_env) = avlTreeGet(tree, name);
        class_env = replaceClassInClassEnv(path, inClass, class_env);
        tree = avlTreeReplace(tree, name, CLASS(cls, class_env)); 
      then
        FRAME(frame_name, ty, tree, exts, imps) :: rest_env;

  end match;
end replaceClassInClassEnv;
        
//protected function expandExtend
//  input SCode.Element inElement;
//  input Env inEnv;
//  input SCode.ClassDef inClassDef;
//  output SCode.ClassDef outClassDef;
//algorithm
//  outClassDef := matchcontinue(inElement, inEnv, inClassDef)
//    local
//      Absyn.Path path;
//      SCode.Mod mods;
//      SCode.ClassDef base_cdef, merged_cdef;
//
//    case (SCode.EXTENDS(baseClassPath = path, modifications = mods), _, _)
//      equation
//        SCode.CLASS(classDef = base_cdef) = lookupClass(path, inEnv);
//        merged_cdef = mergeClassDefs(base_cdef, inClassDef);
//      then
//        merged_cdef;
//
//  end matchcontinue;
//end expandExtend;
//
//protected function mergeClassDefs
//  input SCode.ClassDef inClassDef1;
//  input SCode.ClassDef inClassDef2;
//  output SCode.ClassDef outClassDef;
//algorithm
//  outClassDef := matchcontinue(inClassDef1, inClassDef2)
//    local
//      list<SCode.Element> el1, el2;
//      list<SCode.Equation> neql1, neql2, ieql1, ieql2;
//      list<SCode.AlgorithmSection> nal1, nal2, ial1, ial2;
//      list<SCode.Annotation> annl;
//      Option<SCode.Comment> cmt;
//
//    case (SCode.PARTS(el1, neql1, ieql1, nal1, ial1, NONE(), _, _),
//          SCode.PARTS(el2, neql2, ieql2, nal2, ial2, NONE(), annl, cmt))
//      equation
//        // TODO: Handle duplicate elements!
//        el1 = listAppend(el1, el2);
//        neql1 = listAppend(neql1, neql2);
//        ieql1 = listAppend(ieql1, ieql2);
//        nal1 = listAppend(nal1, nal2);
//        ial1 = listAppend(ial1, ial2);
//      then
//        SCode.PARTS(el1, neql1, ieql1, nal1, ial2, NONE(), annl, cmt);
//
//    else
//      equation
//        Debug.fprintln("failtrace", "- SCodeFlatten.mergeClassDefs failed.");
//      then
//        fail();
//  end matchcontinue;
//end mergeClassDefs;
//   

protected function newEnvironment
  input Option<SCode.Ident> inName;
  output Env outEnv;
protected
  Frame new_frame;
algorithm
  new_frame := newFrame(inName, NORMAL_SCOPE());
  outEnv := {new_frame};
end newEnvironment;

protected function openScope
  input Env inEnv;
  input SCode.Class inClass;
  output Env outEnv;
protected
  String name;
  Boolean encapsulated_prefix;
  Frame new_frame;
algorithm
  SCode.CLASS(name = name, encapsulatedPrefix = encapsulated_prefix) := inClass;
  new_frame := newFrame(SOME(name), getFrameType(encapsulated_prefix));
  outEnv := new_frame :: inEnv;
end openScope;

protected function enterScope
  input Env inEnv;
  input SCode.Ident inName;
  output Env outEnv;
protected
  Frame cls_env;
  AvlTree cls_and_vars;
algorithm
  FRAME(clsAndVars = cls_and_vars) :: _ := inEnv;
  CLASS(env = {cls_env}) := avlTreeGet(cls_and_vars, inName);
  outEnv := cls_env :: inEnv;
end enterScope;

protected function getEnvTopScope
  input Env inEnv;
  output Env outEnv;
protected
  Frame top_scope;
  Env env;
algorithm
  env := listReverse(inEnv);
  top_scope :: _ := env;
  outEnv := {top_scope};
end getEnvTopScope;

protected function getFrameType
  input Boolean isEncapsulated;
  output FrameType outType;
algorithm
  outType := match(isEncapsulated)
    case true then ENCAPSULATED_SCOPE();
    else then NORMAL_SCOPE();
  end match;
end getFrameType;

protected function newFrame
  input Option<String> inName;
  input FrameType inType;
  output Frame outFrame;
protected
  AvlTree tree;
  ExtendsTable exts;
  ImportTable imps;
algorithm
  tree := avlTreeNew();
  exts := newExtendsTable();
  imps := newImportTable();
  outFrame := FRAME(inName, inType, tree, exts, imps);
end newFrame;

protected function newImportTable
  output ImportTable outImports;
algorithm
  outImports := IMPORT_TABLE({}, {});
end newImportTable;

protected function newExtendsTable
  output ExtendsTable outExtends;
algorithm
  outExtends := EXTENDS_TABLE({}, {});
end newExtendsTable;

protected function extendEnvWithClasses
  input list<SCode.Class> inClasses;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := Util.listFold(inClasses, extendEnvWithClass, inEnv);
end extendEnvWithClasses;

protected function extendEnvWithClass
  input SCode.Class inClass;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inClass, inEnv)
    local
      String cls_name;
      Env class_env, env;
      SCode.ClassDef cdef;
      Absyn.Path cls_path;

    case (SCode.CLASS(classDef = SCode.CLASS_EXTENDS(baseClassName = _)), _)
      then addClassExtendsToEnvExtendsTable(inClass, inEnv);

    case (SCode.CLASS(name = cls_name, classDef = cdef), _)
      equation
        class_env = newEnvironment(SOME(cls_name));
        class_env = extendEnvWithClassComponents(cls_name, cdef, class_env);
        env = extendEnvWithItem(CLASS(inClass, class_env), inEnv, cls_name);
      then
        env;
  end match;
end extendEnvWithClass;

protected function removeExtendsFromLocalScope
  input Env inEnv;
  output Env outEnv;
protected
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  ImportTable imps;
  ExtendsTable exts;
  Env rest;
algorithm
  FRAME(name = name, frameType = ty, clsAndVars = tree, importTable = imps) 
    :: rest := inEnv;
  exts := newExtendsTable();
  outEnv := FRAME(name, ty, tree, exts, imps) :: rest;
end removeExtendsFromLocalScope;
  
protected function extendEnvWithClassDef
  input SCode.Element inClassDefElement;
  input Env inEnv;
  output Env outEnv;
protected
  SCode.Class cls;
algorithm
  SCode.CLASSDEF(classDef = cls) := inClassDefElement;
  outEnv := extendEnvWithClass(cls, inEnv);
end extendEnvWithClassDef;

protected function extendEnvWithVar
  input SCode.Element inVar;
  input Env inEnv;
  output Env outEnv;
protected
  String var_name;
algorithm
  SCode.COMPONENT(component = var_name) := inVar; 
  outEnv := extendEnvWithItem(VAR(inVar), inEnv, var_name);
end extendEnvWithVar;

protected function extendEnvWithItem
  input Item inItem;
  input Env inEnv;
  input String inItemName;
  output Env outEnv;
protected
  Option<String> name;
  AvlTree tree;
  ExtendsTable exts;
  ImportTable imps;
  FrameType ty;
  Env rest;
algorithm
  FRAME(name, ty, tree, exts, imps) :: rest := inEnv;
  tree := avlTreeAdd(tree, inItemName, inItem);
  outEnv := FRAME(name, ty, tree, exts, imps) :: rest;
end extendEnvWithItem;

protected function extendEnvWithImport
  input SCode.Element inImport;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inImport, inEnv)
    local
      Import imp;
      Option<String> name;
      AvlTree tree;
      ExtendsTable exts;
      list<Import> qual_imps, unqual_imps;
      FrameType ty;
      Env rest;

    // Unqualified imports
    case (SCode.IMPORT(imp = imp as Absyn.UNQUAL_IMPORT(path = _)), 
        FRAME(name, ty, tree, exts, IMPORT_TABLE(qual_imps, unqual_imps)) :: rest)
      equation
        unqual_imps = imp :: unqual_imps;
      then
        FRAME(name, ty, tree, exts, IMPORT_TABLE(qual_imps, unqual_imps)) :: rest;

    // Qualified imports
    case (SCode.IMPORT(imp = imp), 
        FRAME(name, ty, tree, exts, IMPORT_TABLE(qual_imps, unqual_imps)) :: rest)
      equation
        imp = translateQualifiedImportToNamed(imp);
        checkUniqueQualifiedImport(imp, qual_imps);
        qual_imps = imp :: qual_imps;
      then
        FRAME(name, ty, tree, exts, IMPORT_TABLE(qual_imps, unqual_imps)) :: rest;
  end match;
end extendEnvWithImport;

protected function extendEnvWithExtends
  input SCode.Element inExtends;
  input Env inEnv;
  output Env outEnv;
protected
  Absyn.Path bc;
  SCode.Mod mods;
  list<SCode.Element> redecls;
algorithm
  SCode.EXTENDS(baseClassPath = bc, modifications = mods) := inExtends;
  redecls := extractRedeclaresFromModifier(mods);
  outEnv := addExtendsToEnvExtendsTable(EXTENDS(bc, redecls), inEnv);
end extendEnvWithExtends;

protected function addExtendsToEnvExtendsTable
  input Extends inExtends;
  input Env inEnv;
  output Env outEnv;
protected
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  ImportTable imps;
  list<Extends> exts;
  list<SCode.Class> ce;
  Env rest_env;
algorithm
  FRAME(name, ty, tree, EXTENDS_TABLE(exts, ce), imps) :: rest_env := inEnv;
  exts := inExtends :: exts;
  outEnv := FRAME(name, ty, tree, EXTENDS_TABLE(exts, ce), imps) :: rest_env;
end addExtendsToEnvExtendsTable;

protected function addClassExtendsToEnvExtendsTable
  input SCode.Class inClassExtends;
  input Env inEnv;
  output Env outEnv;
protected
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  ImportTable imps;
  list<Extends> exts;
  list<SCode.Class> ce;
  Env rest_env;
algorithm
  FRAME(name, ty, tree, EXTENDS_TABLE(exts, ce), imps) :: rest_env := inEnv;
  ce := inClassExtends :: ce;
  outEnv := FRAME(name, ty, tree, EXTENDS_TABLE(exts, ce), imps) :: rest_env;
end addClassExtendsToEnvExtendsTable;

protected function extendEnvWithClassComponents
  input String inClassName;
  input SCode.ClassDef inClassDef;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inClassName, inClassDef, inEnv)
    local
      list<SCode.Element> el;
      list<SCode.Enum> enums;
      Absyn.TypeSpec enum_type;
      Env env;
      Absyn.Path path;

    case (_, SCode.PARTS(elementLst = el), _)
      equation
        env = Util.listFold(el, extendEnvWithElement, inEnv);
      then
        env;

    case (_, SCode.DERIVED(typeSpec = Absyn.TPATH(path = path)), _)
      equation
        env = extendEnvWithExtends(SCode.EXTENDS(path, SCode.NOMOD(), NONE(),
          Absyn.dummyInfo), inEnv);
      then
        env;

    case (_, SCode.ENUMERATION(enumLst = enums), _)
      equation
        enum_type = Absyn.TPATH(Absyn.IDENT(inClassName), NONE());
        env = Util.listFold1(enums, extendEnvWithEnum, enum_type, inEnv);
      then
        env;

    else then inEnv;
  end match;
end extendEnvWithClassComponents;

protected function extendEnvWithElement
  input SCode.Element inElement;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inElement, inEnv)
    local
      Env env;

    case (SCode.COMPONENT(component = _), _)
      equation
        //print("Extending environment with component " +&
        //    getEnvName(inEnv) +& "." +&
        //    SCode.elementName(inElement) +& "\n");
        env = extendEnvWithVar(inElement, inEnv);
      then
        env;

    case (SCode.CLASSDEF(classDef = _), _)
      equation
        //print("Extending environment with class def " +&
        //    getEnvName(inEnv) +& "." +&
        //    SCode.elementName(inElement) +& "\n");
        env = extendEnvWithClassDef(inElement, inEnv);
      then
        env;

    case (SCode.EXTENDS(baseClassPath = _), _)
      equation
        env = extendEnvWithExtends(inElement, inEnv);
      then
        env;

    case (SCode.IMPORT(imp = _), _)
      equation
        env = extendEnvWithImport(inElement, inEnv);
      then
        env;

    case (SCode.DEFINEUNIT(name = _), _)
      then inEnv;

  end match;
end extendEnvWithElement;

protected function translateQualifiedImportToNamed
  input Import inImport;
  output Import outImport;
algorithm
  outImport := match(inImport)
    local
      Absyn.Ident name;
      Absyn.Path path;

    case Absyn.NAMED_IMPORT(name = _) then inImport;

    case Absyn.QUAL_IMPORT(path = path)
      equation
        name = Absyn.pathLastIdent(path);
      then
        Absyn.NAMED_IMPORT(name, path);
  end match;
end translateQualifiedImportToNamed;

protected function checkUniqueQualifiedImport
  input Import inImport;
  input list<Import> inImports;
protected
  Absyn.Ident name;
algorithm
  false := Util.listContainsWithCompareFunc(inImport, inImports,
    compareQualifiedImportNames);
end checkUniqueQualifiedImport;

protected function compareQualifiedImportNames
  input Import inImport1;
  input Import inImport2;
  output Boolean outEqual;
protected
  Absyn.Ident name1, name2;
algorithm
  outEqual := matchcontinue(inImport1, inImport2)
    local
      Absyn.Ident name1, name2;
    
    case (Absyn.NAMED_IMPORT(name = name1), Absyn.NAMED_IMPORT(name = name2))
      equation
        true = stringEqual(name1, name2);
        print("Error: qualified import with same names: " +& name1 +& "!\n");
      then
        true;

    else then false;
  end matchcontinue;
end compareQualifiedImportNames;

protected function checkUniqueQualifiedImport2
  input Absyn.Ident inName;
  input list<Import> inImports;
algorithm
  _ := matchcontinue(inName, inImports)
    local
      Absyn.Ident name;
      Import imp;
      list<Import> rest_imps;

    case (_, {}) then ();

    case (_, Absyn.NAMED_IMPORT(name = name) :: _)
      equation
        true = stringEqual(name, inName);
        print("Error: qualified import with same names: " +& name +& "!\n");
      then
        fail();

    case (_, _ :: rest_imps)
      equation
        checkUniqueQualifiedImport2(inName, rest_imps);
      then
        ();

  end matchcontinue;
end checkUniqueQualifiedImport2;

protected function extendEnvWithEnum
  input SCode.Enum inEnum;
  input Absyn.TypeSpec inEnumType;
  input Env inEnv;
  output Env outEnv;
protected
  SCode.Element enum_lit;
  SCode.Ident lit_name;
algorithm
  SCode.ENUM(literal = lit_name) := inEnum;
  enum_lit := SCode.COMPONENT(lit_name, Absyn.UNSPECIFIED(), 
    false, false, false, 
    SCode.ATTR({}, false, false, SCode.RO(), SCode.CONST(), Absyn.BIDIR()),
    inEnumType, SCode.NOMOD(), NONE(), NONE(), NONE(), NONE());
  outEnv := extendEnvWithElement(enum_lit, inEnv);
end extendEnvWithEnum;

protected function extendEnvWithIterators
  input Absyn.ForIterators inIterators;
  input Env inEnv;
  output Env outEnv;
protected
  Frame frame;
algorithm
  frame := newFrame(NONE(), IMPLICIT_SCOPE());
  outEnv := Util.listFold(inIterators, extendEnvWithIterator, frame :: inEnv);
end extendEnvWithIterators;

protected function extendEnvWithIterator
  input tuple<Absyn.Ident, Option<Absyn.Exp>> inIterator;
  input Env inEnv;
  output Env outEnv;
protected
  Absyn.Ident iter_name;
  SCode.Element iter;
algorithm
  (iter_name, _) := inIterator;
  iter := SCode.COMPONENT(iter_name, Absyn.UNSPECIFIED(),
    false, false, false,
    SCode.ATTR({}, false, false, SCode.RO(), SCode.CONST(), Absyn.BIDIR()),
    Absyn.TPATH(Absyn.IDENT(""), NONE()), SCode.NOMOD(),
    NONE(), NONE(), NONE(), NONE());
  outEnv := extendEnvWithElement(iter, inEnv);
end extendEnvWithIterator;

protected function insertClassExtendsIntoEnv
  input Env inEnv;
  output Env outEnv;
protected
  Env env, rest_env;
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  list<Extends> bcl;
  list<SCode.Class> ce;
  ImportTable imps;
algorithm
  FRAME(extendsTable = EXTENDS_TABLE(classExtends = ce)) :: _ := inEnv;
  env := Util.listFold(ce, extendEnvWithClassExtends, inEnv);
  FRAME(name, ty, tree, EXTENDS_TABLE(bcl, _), imps) :: rest_env := env;
  SOME(tree) := insertClassExtendsIntoClassEnv(SOME(tree), inEnv);
  outEnv := FRAME(name, ty, tree, EXTENDS_TABLE(bcl, {}), imps) :: rest_env;
end insertClassExtendsIntoEnv;

protected function insertClassExtendsIntoClassEnv
  input Option<AvlTree> inTree;
  input Env inEnv;
  output Option<AvlTree> outTree;
algorithm
  outEnv := match(inTree, inEnv)
    local
      String name;
      Integer h;
      Option<AvlTree> left, right;
      Env rest_env;
      SCode.Class cls;
      Frame class_frame;
      Option<AvlTreeValue> value;

    case (NONE(), _) then inTree;

    case (SOME(AVLTREENODE(value = SOME(AVLTREEVALUE(
          key = name, value = CLASS(cls = cls, env = {class_frame}))),
        height = h, left = left, right = right)), _)
      equation
        class_frame :: rest_env = insertClassExtendsIntoEnv(class_frame :: inEnv);
        left = insertClassExtendsIntoClassEnv(left, inEnv);
        right = insertClassExtendsIntoClassEnv(right, inEnv);
      then
        SOME(AVLTREENODE(SOME(AVLTREEVALUE(name, CLASS(cls, {class_frame}))), h,
          left, right)); 

    case (SOME(AVLTREENODE(value = value, height = h, 
        left = left, right = right)), _)
      equation
        left = insertClassExtendsIntoClassEnv(left, inEnv);
        right = insertClassExtendsIntoClassEnv(right, inEnv);
      then
        SOME(AVLTREENODE(value, h, left, right));
  end match;
end insertClassExtendsIntoClassEnv;

protected function extendEnvWithClassExtends
  input SCode.Class inClassExtends;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inClassExtends, inEnv)
    local
      SCode.Ident bc;
      list<SCode.Element> el;
      Absyn.Path path;
      Boolean pp, ep;
      SCode.Restriction res;
      Absyn.Info info;
      Env env;
      SCode.Mod mods;

    // When a 'redeclare class extends X' is encountered we insert a 'class X
    // extends BaseClass.X' into the environment, with the same elements as the
    // class extends clause. BaseClass is the class that class X is inherited
    // from. This allows use to look up elements in class extends, because
    // lookup can handle normal extends.
    case (SCode.CLASS(
        partialPrefix = pp,
        encapsulatedPrefix = ep,
        restriction = res,
        classDef = SCode.CLASS_EXTENDS(
          baseClassName = bc, 
          modifications = mods,
          elementLst = el),
        info = info), _)
      equation
        // Look up which extends the base class comes from and add it to the
        // base class name.
        path = lookupBaseClass(bc, inEnv, info);
        path = Absyn.joinPaths(path, Absyn.IDENT(bc));
        // Insert a 'class bc extends path' into the environment.
        el = SCode.EXTENDS(path, mods, NONE(), info) :: el;
        env = extendEnvWithClass(SCode.CLASS(bc, pp, ep, res, 
          SCode.PARTS(el, {}, {}, {}, {}, NONE(), {}, NONE()), info), inEnv);
      then env;

    else then inEnv;
  end match;
end extendEnvWithClassExtends;

protected function lookupBaseClass
  "Looks up from which base class a certain class is inherited from by searching
  the extends in the local scope."
  input SCode.Ident inClass;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Absyn.Path outBaseClass;
algorithm
  outBaseClass := matchcontinue(inClass, inEnv, inInfo)
    local
      Absyn.Path bc;

    case (_, _, _)
      equation
        (_, _, bc, _) = lookupInBaseClasses(inClass, inEnv);
      then
        bc;

    else
      equation
        print("- SCodeFlatten.lookupBaseClass: Could not find "
        +& inClass +& " among the inherited classes.\n");
      then
        fail();
  end matchcontinue;
end lookupBaseClass;

protected function getEnvName
  input Env inEnv;
  output String outString;
algorithm
  outString := matchcontinue(inEnv)
    local
      String str;

    case _
      equation
        str = Absyn.pathString(getEnvPath(inEnv));
      then
        str;

    else then "";
  end matchcontinue;
end getEnvName;

protected function getEnvPath
  input Env inEnv;
  output Absyn.Path outPath;
algorithm
  outPath := match(inEnv)
    local
      String name;
      Absyn.Path path;
      Env rest;

    case ({FRAME(name = SOME(name))})
      then Absyn.IDENT(name);

    case ({FRAME(name = SOME(name)), FRAME(name = NONE())}) 
      then Absyn.IDENT(name);

    case (FRAME(name = SOME(name)) :: rest)
      equation
        path = getEnvPath(rest);
        path = Absyn.joinPaths(path, Absyn.IDENT(name));
      then
        path;
  end match;
end getEnvPath;

protected function buildInitialEnv
  output Env outInitialEnv;
protected
  AvlTree tree;
  ExtendsTable exts;
  ImportTable imps;
algorithm
  tree := avlTreeNew();
  exts := newExtendsTable();
  imps := newImportTable();

  tree := avlTreeAdd(tree, "time", VAR(
    SCode.COMPONENT("time", Absyn.UNSPECIFIED(), false, false, false,
    SCode.ATTR({}, false, false, SCode.RO(), SCode.VAR(), Absyn.INPUT()),
    Absyn.TPATH(Absyn.IDENT("Real"), NONE()), SCode.NOMOD(),
    NONE(), NONE(), NONE(), NONE())));

  tree := avlTreeAdd(tree, "String", CLASS(
    SCode.CLASS("String", false, false, SCode.R_FUNCTION(),
      SCode.PARTS({}, {}, {}, {}, {}, NONE(), {}, NONE()), Absyn.dummyInfo),
    emptyEnv));

  tree := avlTreeAdd(tree, "Integer", CLASS(
    SCode.CLASS("Integer", false, false, SCode.R_FUNCTION(),
      SCode.PARTS({}, {}, {}, {}, {}, NONE(), {}, NONE()), Absyn.dummyInfo),
    emptyEnv));

  outInitialEnv := {FRAME(NONE(), NORMAL_SCOPE(), tree, exts, imps)};
end buildInitialEnv;

// AVL Tree implementation
protected type AvlKey = String;
protected type AvlValue = Item;

protected uniontype AvlTree 
  "The binary tree data structure"
  record AVLTREENODE
    Option<AvlTreeValue> value "Value";
    Integer height "heigth of tree, used for balancing";
    Option<AvlTree> left "left subtree";
    Option<AvlTree> right "right subtree";
  end AVLTREENODE;
end AvlTree;

protected uniontype AvlTreeValue 
  "Each node in the binary tree can have a value associated with it."
  record AVLTREEVALUE
    AvlKey key "Key" ;
    AvlValue value "Value" ;
  end AVLTREEVALUE;
end AvlTreeValue;

protected function avlTreeNew 
  "Return an empty tree"
  output AvlTree tree;
algorithm
  tree := AVLTREENODE(NONE(),0,NONE(),NONE());
end avlTreeNew;

protected function printEnvStr
  input Env inEnv;
  output String outString;
protected
  Frame f;
algorithm
  f :: _ := inEnv;
  outString := printFrameStr(f);
end printEnvStr;

protected function printFrameStr
  input Frame inFrame;
  output String outString;
protected
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  ExtendsTable exts;
  ImportTable imps;
  String name_str, ty_str, tree_str, ext_str, imp_str;
algorithm
  FRAME(name, ty, tree, exts, imps) := inFrame;
  name_str := printFrameNameStr(name);
  ty_str := printFrameTypeStr(ty);
  tree_str := printAvlTreeStr(SOME(tree));
  ext_str := printExtendsTableStr(exts);
  imp_str := printImportTableStr(imps);
  name_str := "<<<" +& ty_str +& " frame " +& name_str +& ">>>\n";
  outString := name_str +& 
    "\tImports:\n" +& imp_str +&
    "\n\tExtends:\n" +& ext_str +&
    "\n\tComponents:\n" +& tree_str +& "\n";
end printFrameStr;

protected function printFrameNameStr
  input Option<String> inFrame;
  output String outString;
algorithm
  outString := match(inFrame)
    local
      String name;

    case NONE() then "global";
    case SOME(name) then name;
  end match;
end printFrameNameStr;

protected function printFrameTypeStr
  input FrameType inFrame;
  output String outString;
algorithm
  outString := match(inFrame)
    case NORMAL_SCOPE then "Normal";
    case ENCAPSULATED_SCOPE then "Encapsulated";
    case IMPLICIT_SCOPE then "Implicit";
  end match;
end printFrameTypeStr;

protected function printAvlTreeStr
  input Option<AvlTree> inTree;
  output String outString;
algorithm
  outString := match(inTree)
    local
      Option<AvlTree> left, right;
      AvlTreeValue value;
      String left_str, right_str, value_str;

    case (NONE()) then "";
    case (SOME(AVLTREENODE(value = SOME(value), left = left, right = right)))
      equation
        left_str = printAvlTreeStr(left);
        right_str = printAvlTreeStr(right);
        value_str = printAvlValueStr(value);
        value_str = value_str +& left_str +& right_str;
      then
        value_str;
  end match;
end printAvlTreeStr;

protected function printAvlValueStr
  input AvlTreeValue inValue;
  output String outString;
algorithm
  outString := match(inValue)
    local
      String key_str, value_str;

    case (AVLTREEVALUE(key = key_str, value = CLASS(cls = _)))
      then "\t\tClass " +& key_str +& "\n";

    case (AVLTREEVALUE(key = key_str, value = VAR(var = _)))
      then "\t\tVar " +& key_str +& "\n";

    case (AVLTREEVALUE(key = key_str, value = BUILTIN(name = _)))
      then "\t\tBuiltin " +& key_str +& "\n";
  end match;
end printAvlValueStr;

protected function printExtendsTableStr
  input ExtendsTable inExtendsTable;
  output String outString;
protected
  list<Extends> bcl;
algorithm
  EXTENDS_TABLE(baseClasses = bcl) := inExtendsTable;
  outString := Util.stringDelimitList(Util.listMap(bcl, printExtendsStr), "\n");
end printExtendsTableStr;

protected function printExtendsStr
  input Extends inExtends;
  output String outString;
protected
  Absyn.Path bc;
  list<SCode.Element> mods;
  String mods_str;
algorithm
  EXTENDS(baseClass = bc, redeclareModifiers = mods) := inExtends;
  mods_str := Util.stringDelimitList(
    Util.listMap(mods, SCode.printElementStr), "\n");
  outString := "\t\t" +& Absyn.pathString(bc) +& "(" +& mods_str +& ")";
end printExtendsStr;

protected function printImportTableStr
  input ImportTable inImports;
  output String outString;
protected
  list<Import> qual_imps, unqual_imps;
  String qual_str, unqual_str;
algorithm
  IMPORT_TABLE(qual_imps, unqual_imps) := inImports;
  qual_str := Util.stringDelimitList(
    Util.listMap(qual_imps, Absyn.printImportString), "\n\t\t");
  unqual_str := Util.stringDelimitList(
    Util.listMap(unqual_imps, Absyn.printImportString), "\n\t\t");
  outString := "\t\t" +& qual_str +& unqual_str;
end printImportTableStr;

protected function avlTreeAdd
  "Inserts a new value into the tree."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match(inAvlTree, inKey, inValue)
    local
      AvlKey key, rkey;
      AvlValue value;

    // empty tree
    case (AVLTREENODE(value = NONE(), left = NONE(), right = NONE()), _, _)
      then AVLTREENODE(SOME(AVLTREEVALUE(inKey, inValue)), 1, NONE(), NONE());

    case (AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey))), key, value)
      then balance(avlTreeAdd2(inAvlTree, stringCompare(key, rkey), key, value));
 
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Env.avlTreeAdd failed"});
      then fail();

  end match;
end avlTreeAdd;

protected function avlTreeAdd2
  "Helper function to avlTreeAdd."
  input AvlTree inAvlTree;
  input Integer inKeyComp;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match(inAvlTree, inKeyComp, inKey, inValue)
    local
      AvlKey key;
      AvlValue value;
      Option<AvlTree> left, right;
      Integer h;
      AvlTree t;
      Option<AvlTreeValue> oval;

    // Don't allow replacing of nodes.
    case (_, 0, key, _)
      equation
        print("Identifier " +& key +& " already exists in this scope!\n");
      then
        fail();

    // Insert into right subtree.
    case (AVLTREENODE(value = oval, height = h, left = left, right = right),
        1, key, value)
      equation
        t = createEmptyAvlIfNone(right);
        t = avlTreeAdd(t, key, value);
      then  
        AVLTREENODE(oval, h, left, SOME(t));

    // Insert into left subtree.
    case (AVLTREENODE(value = oval, height = h, left = left, right = right),
        -1, key, value)
      equation
        t = createEmptyAvlIfNone(left);
        t = avlTreeAdd(t, key, value);
      then
        AVLTREENODE(oval, h, SOME(t), right);
  end match;
end avlTreeAdd2;

protected function avlTreeGet
  "Get a value from the binary tree given a key."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  output AvlValue outValue;
protected
  AvlKey rkey;
algorithm
  AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey))) := inAvlTree;
  outValue := avlTreeGet2(inAvlTree, stringCompare(inKey, rkey), inKey);
end avlTreeGet;

protected function avlTreeGet2
  "Helper function to avlTreeGet."
  input AvlTree inAvlTree;
  input Integer inKeyComp;
  input AvlKey inKey;
  output AvlValue outValue;
algorithm
  outValue := match(inAvlTree, inKeyComp, inKey)
    local
      AvlKey key;
      AvlValue rval;
      AvlTree left, right;

    // Found match.
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(value = rval))), 0, _)
      then rval;

    // Search to the right.
    case (AVLTREENODE(right = SOME(right)), 1, key)
      then avlTreeGet(right, key);

    // Search to the left.
    case (AVLTREENODE(left = SOME(left)), -1, key)
      then avlTreeGet(left, key);
  end match;
end avlTreeGet2;

protected function avlTreeReplace
  "Replaces the value of an already existing node in the tree with a new value."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match(inAvlTree, inKey, inValue)
    local
      AvlKey key, rkey;
      AvlValue value;

    case (AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey))), key, value)
      then avlTreeReplace2(inAvlTree, stringCompare(key, rkey), key, value);
 
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Env.avlTreeAdd failed"});
      then fail();

  end match;
end avlTreeReplace;

protected function avlTreeReplace2
  "Helper function to avlTreeReplace."
  input AvlTree inAvlTree;
  input Integer inKeyComp;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match(inAvlTree, inKeyComp, inKey, inValue)
    local
      AvlKey key, rkey;
      AvlValue value;
      Option<AvlTree> left, right;
      Integer h;
      AvlTree t;
      Option<AvlTreeValue> oval;

    // Replace this node.
    case (AVLTREENODE(value = SOME(_), height = h, left = left, right = right),
        0, key, value)
      then AVLTREENODE(SOME(AVLTREEVALUE(key, value)), h, left, right);

    // Insert into right subtree.
    case (AVLTREENODE(value = oval, height = h, left = left, right = right),
        1, key, value)
      equation
        t = createEmptyAvlIfNone(right);
        t = avlTreeReplace(t, key, value);
      then  
        AVLTREENODE(oval, h, left, SOME(t));

    // Insert into left subtree.
    case (AVLTREENODE(value = oval, height = h, left = left, right = right),
        -1, key, value)
      equation
        t = createEmptyAvlIfNone(left);
        t = avlTreeReplace(t, key, value);
      then
        AVLTREENODE(oval, h, SOME(t), right);
  end match;
end avlTreeReplace2;

protected function createEmptyAvlIfNone 
  "Help function to AvlTreeAdd"
    input Option<AvlTree> t;
    output AvlTree outT;
algorithm
  outT := match(t)
    case (NONE()) then avlTreeNew();
    case (SOME(outT)) then outT;
  end match;
end createEmptyAvlIfNone;

protected function balance 
  "Balances an AvlTree"
  input AvlTree bt;
  output AvlTree outBt;
protected
  Integer d;
algorithm
  d := differenceInHeight(bt);
  outBt := doBalance(d, bt);
end balance;

protected function doBalance 
  "Performs balance if difference is > 1 or < -1"
  input Integer difference;
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := match(difference, bt)
    case(-1, _) then computeHeight(bt);
    case( 0, _) then computeHeight(bt);
    case( 1, _) then computeHeight(bt);
    /* d < -1 or d > 1 */
    else then doBalance2(difference, bt);
  end match;
end doBalance;

protected function doBalance2 
"help function to doBalance"
  input Integer difference;
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(difference,bt)
    case(difference,bt) 
      equation
        true = difference < 0;
        bt = doBalance3(bt);
        bt = rotateLeft(bt);
      then bt;
    case(difference,bt) 
      equation
        true = difference > 0;
        bt = doBalance4(bt);
        bt = rotateRight(bt);
      then bt;
    else then bt;
  end matchcontinue;
end doBalance2;

protected function doBalance3 
  "help function to doBalance2"
  input AvlTree bt;
  output AvlTree outBt;
protected
  AvlTree rr;
algorithm
  true := differenceInHeight(Util.getOption(rightNode(bt))) > 0;
  rr := rotateRight(Util.getOption(rightNode(bt)));
  outBt := setRight(bt,SOME(rr));
end doBalance3;

protected function doBalance4 
  "help function to doBalance2"
  input AvlTree bt;
  output AvlTree outBt;
protected
  AvlTree rl;
algorithm
  true := differenceInHeight(Util.getOption(leftNode(bt))) < 0;
  rl := rotateLeft(Util.getOption(leftNode(bt)));
  outBt := setLeft(bt,SOME(rl));
end doBalance4;

protected function setRight 
  "set right treenode"
  input AvlTree node;
  input Option<AvlTree> right;
  output AvlTree outNode;
protected
  Option<AvlTreeValue> value;
  Option<AvlTree> l;
  Integer height;
algorithm
  AVLTREENODE(value, height, l, _) := node;
  outNode := AVLTREENODE(value, height, l, right);
end setRight;

protected function setLeft 
  "set left treenode"
  input AvlTree node;
  input Option<AvlTree> left;
  output AvlTree outNode;
protected
  Option<AvlTreeValue> value;
  Option<AvlTree> r;
  Integer height;
algorithm
  AVLTREENODE(value, height, _, r) := node;
  outNode := AVLTREENODE(value, height, left, r);
end setLeft;

protected function leftNode 
  "Retrieve the left subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  AVLTREENODE(left = subNode) := node;
end leftNode;

protected function rightNode 
  "Retrieve the right subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  AVLTREENODE(right = subNode) := node;
end rightNode;

protected function exchangeLeft 
  "help function to balance"
  input AvlTree inNode;
  input AvlTree inParent;
  output AvlTree outParent "updated parent";
protected
  AvlTree parent, node;
algorithm
  parent := setRight(inParent, leftNode(inNode));
  parent := balance(parent);
  node := setLeft(inNode, SOME(parent));
  outParent := balance(node);
end exchangeLeft;

protected function exchangeRight 
  "help function to balance"
  input AvlTree inNode;
  input AvlTree inParent;
  output AvlTree outParent "updated parent";
protected
  AvlTree parent, node;
algorithm
  parent := setLeft(inParent, rightNode(inNode));
  parent := balance(parent);
  node := setRight(inNode, SOME(parent));
  outParent := balance(node);
end exchangeRight;

protected function rotateLeft 
  "help function to balance"
  input AvlTree node;
  output AvlTree outNode "updated node";
algorithm
  outNode := exchangeLeft(Util.getOption(rightNode(node)), node);
end rotateLeft;

protected function rotateRight 
  "help function to balance"
  input AvlTree node;
  output AvlTree outNode "updated node";
algorithm
  outNode := exchangeRight(Util.getOption(leftNode(node)), node);
end rotateRight;

protected function differenceInHeight 
  "help function to balance, calculates the difference in height between left
  and right child"
  input AvlTree node;
  output Integer diff;
protected
  Option<AvlTree> l, r;
algorithm
  AVLTREENODE(left = l, right = r) := node;
  diff := getHeight(l) - getHeight(r);
end differenceInHeight;

protected function computeHeight 
  "compute the heigth of the AvlTree and store in the node info"
  input AvlTree bt;
  output AvlTree outBt;
protected
  Option<AvlTree> l,r;
  Option<AvlTreeValue> v;
  AvlValue val;
  Integer hl,hr,height;
algorithm
  AVLTREENODE(value = v as SOME(AVLTREEVALUE(value = val)), 
    left = l, right = r) := bt;
  hl := getHeight(l);
  hr := getHeight(r);
  height := intMax(hl, hr) + 1;
  outBt := AVLTREENODE(v, height, l, r);
end computeHeight;

protected function getHeight 
  "Retrieve the height of a node"
  input Option<AvlTree> bt;
  output Integer height;
algorithm
  height := match(bt)
    case(NONE()) then 0;
    case(SOME(AVLTREENODE(height = height))) then height;
  end match;
end getHeight;

end SCodeFlatten;
