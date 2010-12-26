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

package SCodeFlatten
" file:        SCodeFlatten.mo
  package:     SCodeFlatten
  description: SCode flattening

  RCS: $Id$

  This module flattens the SCode representation by removing all extends, imports
  and redeclares, and fully qualifying class names.
    
  TODO: 
    * Split SCode.traverseEEquationExps in the same way as traverseStatements
      and traverseStatementExps so that for-loops in equation can be handled.

    * Handle builtin types and functions.
    
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

protected uniontype ExtendsTable
  record EXTENDS_TABLE
    list<Absyn.Path> baseClasses;
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
end Item;

protected type Env = list<Frame>;
protected constant Env emptyEnv = {};

public function flatten
  input SCode.Program inProgram;
  output SCode.Program outProgram;
protected
  Env env;
algorithm
  env := newEnvironment(NONE());
  env := buildInitialEnv();
  env := extendEnvWithClasses(inProgram, env);
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
        (ex, cl, im, co, ud) = sortElements(el);
        // Lookup component types, modifications and conditions.
        co = Util.listMap1(co, lookupComponent, env);
        // Lookup base class and modifications in extends clauses.
        ex = Util.listMap1(ex, lookupExtends, env);
        // Lookup class definitions.
        cl = Util.listMap1(cl, lookupClassDefElementNames, env);
        // Lookup equations and algorithm names.
        neql = Util.listMap1(neql, lookupEquation, env);
        ieql = Util.listMap1(ieql, lookupEquation, env);
        nal = Util.listMap1(nal, lookupAlgorithm, env);
        ial = Util.listMap1(ial, lookupAlgorithm, env);
        el = Util.listFlatten({im, ex, cl, co, ud});
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

protected function sortElements
  input list<SCode.Element> inElements;
  output list<SCode.Element> outExtends;
  output list<SCode.Element> outClassdefs;
  output list<SCode.Element> outImports;
  output list<SCode.Element> outComponents;
  output list<SCode.Element> outUnitDefinitions;
algorithm
  (outExtends, outClassdefs, outImports, outComponents, outUnitDefinitions) :=
  match(inElements)
    local
      SCode.Element e;
      list<SCode.Element> rest_el, ex, cl, im, co, ud;

    case ({}) then ({}, {}, {}, {}, {});

    case ((e as SCode.EXTENDS(baseClassPath = _)) :: rest_el)
      equation
        (ex, cl, im, co, ud) = sortElements(rest_el);
      then
        (e :: ex, cl, im, co, ud);

    case ((e as SCode.CLASSDEF(name = _)) :: rest_el)
      equation
        (ex, cl, im, co, ud) = sortElements(rest_el);
      then
        (ex, e :: cl, im, co, ud);

    case ((e as SCode.IMPORT(imp = _)) :: rest_el)
      equation
        (ex, cl, im, co, ud) = sortElements(rest_el);
      then
        (ex, cl, e :: im, co, ud);

    case ((e as SCode.COMPONENT(component = _)) :: rest_el)
      equation
        (ex, cl, im, co, ud) = sortElements(rest_el);
      then
        (ex, cl, im, e :: co, ud);

    case ((e as SCode.DEFINEUNIT(name = _)) :: rest_el)
      equation
        (ex, cl, im, co, ud) = sortElements(rest_el);
      then
        (ex, cl, im, co, e :: ud);
  end match;
end sortElements;
    
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
  (_, type_spec) := lookupTypeSpec(type_spec, inEnv);
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
algorithm
  (outItem, outTypeSpec) := matchcontinue(inTypeSpec, inEnv)
    local
      Absyn.Path path;
      Option<Absyn.ArrayDim> array_dim;
      Item item;

    case (Absyn.TPATH(path, array_dim), _)
      equation
        (item, path, _) = lookupName(path, inEnv);
      then
        (item, Absyn.TPATH(path, array_dim));

    //else then (inTypeSpec;
  end matchcontinue;
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
algorithm
  SCode.EXTENDS(path, mod, ann, info) := inExtends;
  (_, path, _) := lookupName(path, inEnv);
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
  (equ, _) := SCode.traverseEEquationExps(equ, (traverseExp, inEnv));
  outEquation := SCode.EQUATION(equ);
end lookupEquation;

protected function traverseExp
  input tuple<Absyn.Exp, Env> inTuple;
  output tuple<Absyn.Exp, Env> outTuple;
protected
  Absyn.Exp exp;
  Env env;
algorithm
  (exp, env) := inTuple;
  outTuple := Absyn.traverseExp(exp, lookupExpTraverser, env);
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
  ((outExp, _)) := Absyn.traverseExp(inExp, lookupExpTraverser, inEnv);
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

protected function lookupExpTraverser
  input tuple<Absyn.Exp, Env> inTuple;
  output tuple<Absyn.Exp, Env> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      Env env;
      Absyn.ComponentRef cref;
      Absyn.FunctionArgs args;
      Absyn.Exp exp;

    case ((Absyn.CREF(componentRef = cref), env))
      equation
        cref = lookupComponentRef(cref, env);
      then
        ((Absyn.CREF(cref), env));

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
end lookupExpTraverser;

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

    // Simple name.
    case (Absyn.IDENT(name = id), _)
      equation
        (item, new_path) = lookupSimpleName(id, inEnv);
        item_env = getItemEnv(item);
      then
        (item, new_path, item_env);

    // Qualified name.
    case (Absyn.QUALIFIED(name = id, path = path), _)
      equation
        // Look up the first identifier.
        (item, new_path) = lookupSimpleName(id, inEnv);
        item_env = getItemEnv(item);
        // Look up the rest of the name in the environment of the first
        // identifier. The top scope is needed if we have to look up through
        // imports.
        env = getEnvTopScope(inEnv);
        (item, path) = lookupNameInItem(path, item, env);
        path = Absyn.joinPaths(new_path, path);
        item_env = mergeItemEnv(item, item_env);
      then
        (item, path, item_env);

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

    case (_, _)
      equation
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
        (_, path) = lookupSimpleName(name, inEnv);
        cref = Absyn.pathToCrefWithSubs(path, subs);
      then
        cref;

    case (Absyn.CREF_QUAL(name, subs, rest_cref), inEnv)
      equation
        // Lookup the first identifier.
        (item, new_path) = lookupSimpleName(name, inEnv);
        cref = Absyn.pathToCrefWithSubs(new_path, subs);

        // Lookup the rest of the cref in the enclosing scope of the first
        // identifier (also pass along the top scope, in case we need to look up
        // through imports).
        env = getEnvTopScope(inEnv);
        (item, rest_cref) = lookupCrefInItem(rest_cref, item, env);
        cref = Absyn.joinCrefs(cref, rest_cref); 
      then
        cref;

    case (Absyn.CREF_FULLYQUALIFIED(componentRef = cref), inEnv)
      equation
        cref = lookupComponentRef2(cref, inEnv);
      then
        Absyn.CREF_FULLYQUALIFIED(cref);

  end match;
end lookupComponentRef2;

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
algorithm
  (SOME(outItem), SOME(outPath)) := lookupSimpleName2(inName, inEnv);
end lookupSimpleName;

protected function lookupSimpleName2
  input Absyn.Ident inName;
  input Env inEnv;
  output Option<Item> outItem;
  output Option<Absyn.Path> outPath;
algorithm
  (outItem, outPath) := matchcontinue(inName, inEnv)
    local
      FrameType frame_type;
      Env rest_env;
      Option<Item> opt_item;
      Option<Absyn.Path> opt_path;

    case (_, _)
      equation
        (opt_item, opt_path) = lookupInLocalScope(inName, inEnv);
      then
        (opt_item, opt_path);

    case (_, FRAME(frameType = frame_type) :: rest_env)
      equation
        frameNotEncapsulated(frame_type);
        (opt_item, opt_path) = lookupSimpleName2(inName, rest_env);
      then
        (opt_item, opt_path);

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
algorithm
  (outItem, outPath) := matchcontinue(inName, inEnv)
    local
      AvlTree cls_and_vars;
      Env rest_env;
      Item item;
      Option<Item> opt_item;
      Option<Absyn.Path> opt_path;
      list<Import> imps;
      FrameType frame_type;
      list<Absyn.Path> exts;
      Absyn.Path path;

    // Look among the locally declared components.
    case (_, FRAME(clsAndVars = cls_and_vars) :: _)
      equation
        item = avlTreeGet(cls_and_vars, inName);
      then
        (SOME(item), SOME(Absyn.IDENT(inName)));

    // Look among the inherited components.
    case (_, FRAME(extendsTable = EXTENDS_TABLE(baseClasses = exts)) :: _)
      equation
        (item, path) = lookupInBaseClasses(inName, exts, inEnv);
      then
        (SOME(item), SOME(path));

    // Look among the qualified imports.
    case (_, FRAME(importTable = IMPORT_TABLE(qualifiedImports = imps)) :: _)
      equation
        (opt_item, opt_path) = lookupInQualifiedImports(inName, imps, inEnv);
      then
        (opt_item, opt_path);

    // Look among the unqualified imports.
    case (_, FRAME(importTable = IMPORT_TABLE(unqualifiedImports = imps)) :: _)
      equation
        (opt_item, opt_path) = lookupInUnqualifiedImports(inName, imps, inEnv);
      then
        (opt_item, opt_path);

    // Look in the next scope only if the current scope is an implicit scope
    // created by a for loop.
    case (_, FRAME(frameType = IMPLICIT_SCOPE()) :: rest_env)
      equation
        (opt_item, opt_path) = lookupInLocalScope(inName, rest_env);
      then
        (opt_item, opt_path);

  end matchcontinue;
end lookupInLocalScope;

protected function lookupInBaseClasses
  "Looks up an identifier by following the extends clauses in a scope."
  input Absyn.Ident inName;
  input list<Absyn.Path> inBaseClasses;
  input Env inEnv;
  output Item outItem;
  output Absyn.Path outPath;

  Env env;
algorithm
  // We need to remove the extends from the current scope, because the names of
  // extended classes should not be found by lookup through the extends-clauses
  // (Modelica Specification 3.2, section 5.6.1.).
  env := removeExtendsFromLocalScope(inEnv);
  (outItem, outPath) := lookupInBaseClasses2(inName, inBaseClasses, env);
end lookupInBaseClasses;

protected function lookupInBaseClasses2
  input Absyn.Ident inName;
  input list<Absyn.Path> inBaseClasses;
  input Env inEnv;
  output Item outItem;
  output Absyn.Path outPath;
algorithm
  (outItem, outPath) := matchcontinue(inName, inBaseClasses, inEnv)
    local
      Absyn.Path bc, path;
      list<Absyn.Path> rest_bc;
      Item item;
      Env env;

    // Look in the first base class.
    case (_, bc :: _, inEnv)
      equation
        (item, _, SOME(env)) = lookupName(bc, inEnv);
        (item, path) = lookupNameInItem(Absyn.IDENT(inName), item, env);
      then
        (item, path);

    // No match, check the rest of the base classes.
    case (_, _ :: rest_bc, _)
      equation
        (item, path) = lookupInBaseClasses2(inName, rest_bc, inEnv);
      then
        (item, path);

  end matchcontinue;
end lookupInBaseClasses2;

protected function lookupInQualifiedImports
  input Absyn.Ident inName;
  input list<Import> inImports;
  input Env inEnv;
  output Option<Item> outItem;
  output Option<Absyn.Path> outPath;
algorithm
  (outItem, outPath) := matchcontinue(inName, inImports, inEnv)
    local
      Absyn.Ident name;
      Absyn.Path path;
      Item item;
      list<Import> rest_imps;
      Import imp;
      Option<Item> opt_item;
      Option<Absyn.Path> opt_path;

    // No match, search the rest of the list of imports.
    case (_, Absyn.NAMED_IMPORT(name = name) :: rest_imps, _)
      equation
        false = stringEqual(inName, name);
        (opt_item, opt_path) = lookupInQualifiedImports(inName, rest_imps, inEnv);
      then
        (opt_item, opt_path);

    // Match, look up the fully qualified import path.
    case (_, Absyn.NAMED_IMPORT(name = name, path = path) :: _, _)
      equation
        true = stringEqual(inName, name);
        (item, path) = lookupFullyQualified(path, inEnv);  
      then
        (SOME(item), SOME(path));

    // Partial match, return NONE(). This is when only part of the import path
    // can be found, in which case we should stop looking further.
    case (_, Absyn.NAMED_IMPORT(name = name, path = path) :: _, _)
      equation
        true = stringEqual(inName, name);
      then
        (NONE(), NONE());

  end matchcontinue;
end lookupInQualifiedImports;

protected function lookupInUnqualifiedImports
  input Absyn.Ident inName;
  input list<Import> inImports;
  input Env inEnv;
  output Option<Item> outItem;
  output Option<Absyn.Path> outPath;
algorithm
  (outItem, outPath) := matchcontinue(inName, inImports, inEnv)
    local
      Item item;
      Absyn.Path path, path2;
      Option<Item> opt_item;
      Option<Absyn.Path> opt_path;
      list<Import> rest_imps;

    // For each unqualified import we have to look up the package the import
    // points to, and then look among the public member of the package for the
    // name we are looking for.
    case (_, Absyn.UNQUAL_IMPORT(path = path) :: _, _)
      equation
        // Look up the import path.
        (item, path) = lookupFullyQualified(path, inEnv);
        // Look up the name among the public member of the found package.
        (item, path2) = lookupNameInItem(Absyn.IDENT(inName), item, emptyEnv);
        // Combine the paths for the name and the package it was found in.
        path = Absyn.joinPaths(path, path2);
      then
        (SOME(item), SOME(path));

    // No match, continue with the rest of the imports.
    case (_, _ :: rest_imps, _)
      equation
        (opt_item, opt_path) = 
          lookupInUnqualifiedImports(inName, rest_imps, inEnv);
      then
        (opt_item, opt_path);
  end matchcontinue;
end lookupInUnqualifiedImports;

protected function lookupFullyQualified
  input Absyn.Path inName;
  input Env inEnv;
  output Item outItem;
  output Absyn.Path outPath;
protected
  Env env;
  Frame top_scope;
  Absyn.Path path, path2;
  Option<Absyn.Path> opt_path;
algorithm
  env := listReverse(inEnv);
  (opt_path, path, top_scope :: _) := descendEnv(inName, env);
  (outItem, outPath) := lookupNameInPackage(path, {top_scope});
end lookupFullyQualified;

protected function descendEnv
  input Absyn.Path inName;
  input Env inEnv;
  output Option<Absyn.Path> outDescendedPath;
  output Absyn.Path outRemainingPath;
  output Env outEnv;
algorithm
  (outDescendedPath, outRemainingPath, outEnv) := matchcontinue(inName, inEnv)
    local
      Absyn.Ident name1, name2;
      Option<Absyn.Path> desc_path;
      Absyn.Path rem_path;
      Env rest_env;

    case (Absyn.QUALIFIED(name = name1, path = rem_path), 
        _ :: (rest_env as (FRAME(name = SOME(name2)) :: _)))
      equation
        true = stringEqual(name1, name2);
        (desc_path, rem_path, rest_env) = descendEnv(rem_path, rest_env);
        desc_path = Absyn.prefixOptPath(name1, desc_path);
      then
        (desc_path, rem_path, rest_env);

    else then (NONE(), inName, inEnv);
  end matchcontinue;
end descendEnv;

protected function lookupNameInPackage
  input Absyn.Path inName;
  input Env inEnv;
  output Item outItem;
  output Absyn.Path outPath;
algorithm
  (outItem, outPath) := match(inName, inEnv)
    local
      Absyn.Ident name;
      Absyn.Path path, new_path;
      AvlTree cls_and_vars;
      Frame top_scope;
      Env rest_env;
      Item item;

    case (Absyn.IDENT(name = name), _)
      equation
        (SOME(item), SOME(path)) = lookupInLocalScope(name, inEnv);
      then
        (item, path);

    case (Absyn.QUALIFIED(name = name, path = path), top_scope :: _)
      equation
        (SOME(item), SOME(new_path)) = lookupInLocalScope(name, inEnv); 
        (item, path) = lookupNameInItem(path, item, {top_scope});
        path = Absyn.joinPaths(new_path, path);
      then
        (item, path);

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
     
    case (Absyn.CREF_IDENT(name = name, subscripts = subs), _)
      equation
        (SOME(item), SOME(new_path)) = lookupInLocalScope(name, inEnv);
        cref = Absyn.pathToCrefWithSubs(new_path, subs);
      then
        (item, cref);

    case (Absyn.CREF_QUAL(name = name, subScripts = subs, 
        componentRef = cref_rest), top_scope :: _)
      equation
        (SOME(item), SOME(new_path)) = lookupInLocalScope(name, inEnv);
        (item, cref_rest) = lookupCrefInItem(cref_rest, item, {top_scope});
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
algorithm
  (outItem, outPath) := match(inName, inItem, inEnv)
    local
      SCode.Element var;
      Item item;
      Absyn.Path path;
      Frame class_env;
      Env env;
      Absyn.TypeSpec type_spec;

    case (_, VAR(var = SCode.COMPONENT(typeSpec = type_spec)), _) 
      equation
        (item, _) = lookupTypeSpec(type_spec, inEnv);
        (item, path) = lookupNameInItem(inName, item, inEnv);
      then
        (item, path);

    case (_, CLASS(env = {class_env}), _) 
      equation
        env = class_env :: inEnv;
        (item, path) = lookupNameInPackage(inName, env);
      then
        (item, path);

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
      Env env;
      Absyn.TypeSpec type_spec;

    case (_, VAR(var = SCode.COMPONENT(typeSpec = type_spec)), _)
      equation
        (item, _) = lookupTypeSpec(type_spec, inEnv);
        (item, cref) = lookupCrefInItem(inCref, item, inEnv);
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

protected function getItemEnv
  input Item inItem;
  output Option<Env> outEnv;
algorithm
  outEnv := match(inItem)
    local Env env;

    case VAR(var = _) then NONE();
    case CLASS(env = env) then SOME(env);
  end match;
end getItemEnv;

protected function mergeItemEnv
  input Item inItem;
  input Option<Env> inEnv;
  output Option<Env> outEnv;
algorithm
  outEnv := match(inItem, inEnv)
    local 
      Frame cls_frame;
      Env env;
    case (CLASS(env = {cls_frame}), SOME(env)) then SOME(cls_frame :: env);
    else then NONE();
  end match;
end mergeItemEnv;

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
  outExtends := EXTENDS_TABLE({});
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
protected
  String cls_name;
  Env class_env;
  SCode.ClassDef cdef;
  Absyn.Path cls_path;
algorithm
  SCode.CLASS(name = cls_name, classDef = cdef) := inClass;
  class_env := newEnvironment(SOME(cls_name));
  class_env := extendEnvWithClassComponents(cls_name, cdef, class_env);
  outEnv := extendEnvWithItem(CLASS(inClass, class_env), inEnv, cls_name);
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
  Option<String> name;
  FrameType ty;
  AvlTree tree;
  ImportTable imps;
  list<Absyn.Path> exts;
  Env rest;
  Absyn.Path bc;
algorithm
  SCode.EXTENDS(baseClassPath = bc) := inExtends;
  FRAME(name, ty, tree, EXTENDS_TABLE(exts), imps) :: rest := inEnv;
  outEnv := FRAME(name, ty, tree, EXTENDS_TABLE(bc :: exts), imps) :: rest;
end extendEnvWithExtends;

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

    case (_, SCode.PARTS(elementLst = el), _)
      equation
        env = Util.listFold(el, extendEnvWithElement, inEnv);
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
        env = extendEnvWithVar(inElement, inEnv);
      then
        env;

    case (SCode.CLASSDEF(classDef = _), _)
      equation
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

protected function getEnvPath
  input Env inEnv;
  output Absyn.Path outPath;
algorithm
  outPath := match(inEnv)
    local
      String name;
      Absyn.Path path;
      Env rest;
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
  "This might not be needed! It might be a better idea to handle builtin types
  in a special way so we don't need to search through the whole environment to
  find them. According to Modelica 3.2 section 4.8: 
    Redeclaration of any of these types is an error, and the names are reserved
    such that it is illegal to declare an element with these names.
  "

  output Env outInitialEnv;
protected
  AvlTree tree;
  ExtendsTable exts;
  ImportTable imps;
algorithm
  tree := avlTreeNew();
  exts := newExtendsTable();
  imps := newImportTable();

  tree := avlTreeAdd(tree, "Real", CLASS(
    SCode.CLASS("Real", false, false, SCode.R_CLASS(), 
    SCode.PARTS({}, {}, {}, {}, {}, NONE(), {}, NONE()),
    Absyn.dummyInfo), emptyEnv));
  tree := avlTreeAdd(tree, "Integer", CLASS(
    SCode.CLASS("Integer", false, false, SCode.R_CLASS(), 
    SCode.PARTS({}, {}, {}, {}, {}, NONE(), {}, NONE()),
    Absyn.dummyInfo), emptyEnv));
  tree := avlTreeAdd(tree, "Boolean", CLASS(
    SCode.CLASS("Boolean", false, false, SCode.R_CLASS(),
    SCode.PARTS({}, {}, {}, {}, {}, NONE(), {}, NONE()),
    Absyn.dummyInfo), emptyEnv));
  tree := avlTreeAdd(tree, "String", CLASS(
    SCode.CLASS("String", false, false, SCode.R_CLASS(), 
    SCode.PARTS({}, {}, {}, {}, {}, NONE(), {}, NONE()),
    Absyn.dummyInfo), emptyEnv));

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

protected function avlTreeAdd 
  "Help function to avlTreeAdd."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := matchcontinue (inAvlTree, inKey, inValue)
    local
      AvlKey key, rkey;
      AvlValue value, rval;
      Option<AvlTree> left, right;
      Integer h;
      AvlTree t, bt;
  
    // empty tree
    case (AVLTREENODE(value = NONE(), height = h, left = NONE(), right = NONE()),
        key,value)
      then AVLTREENODE(SOME(AVLTREEVALUE(key, value)), 1, NONE(), NONE());
      
    // insert to right
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey, rval)), 
        height = h, left = left, right = right), key, value)
      equation
        1 = stringCompare(key, rkey); // bigger
        t = createEmptyAvlIfNone(right);
        t = avlTreeAdd(t, key, value);
        bt = balance(AVLTREENODE(SOME(AVLTREEVALUE(rkey, rval)), h, left, SOME(t)));
      then
        bt;
      
    // insert to left subtree
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey, rval)),
          height = h,left = left, right = right), key, value)
      equation
        -1 = stringCompare(key, rkey); // smaller
        t = createEmptyAvlIfNone(left);
        t = avlTreeAdd(t, key, value);
        bt = balance(AVLTREENODE(SOME(AVLTREEVALUE(rkey, rval)), h, SOME(t), right));
      then
        bt;

    case (AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey))), key, _)
      equation
        true = stringEqual(key, rkey);
        print("Identifier " +& key +& " already exists in this scope\n");
      then
        fail();
    
    else
      equation
        print("avlTreeAdd failed\n");
      then
        fail();
  end matchcontinue;
end avlTreeAdd;

protected function avlTreeGet 
  "Get a value from the binary tree given a key."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  output AvlValue outValue;
algorithm
  outValue := matchcontinue (inAvlTree,inKey)
    local
        AvlKey rkey,key;
      AvlValue rval,res;
      AvlTree left,right;
    
    // Found node.
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey, rval))), key)
      equation
        0 = stringCompare(rkey, key);
      then
        rval;
    
    // search to the right
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey, rval)), 
        right = SOME(right)), key)
      equation
        1 = stringCompare(key,rkey);
        res = avlTreeGet(right, key);
      then
        res;

    // search to the left
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey, rval)),
        left = SOME(left)), key)
      equation
        -1 = stringCompare(key,rkey);
        res = avlTreeGet(left, key);
      then
        res;
  end matchcontinue;
end avlTreeGet;

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
