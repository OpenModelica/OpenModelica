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

encapsulated package FFlattenImports
" file:        FFlattenImports.mo
  package:     FFlattenImports
  description: SCode flattening

  RCS: $Id: FFlattenImports.mo 14085 2012-11-27 12:12:40Z adrpo $

  This module flattens the SCode representation by removing all extends, imports
  and redeclares, and fully qualifying class names.
"

public import Absyn;
public import SCode;
public import Env;

public type Env = Env.Env;

protected import Debug;
protected import Error;
protected import Flags;
protected import List;
protected import FLookup;
protected import System;
protected import FEnv;

protected type Item = Env.Item;
protected type Extends = Env.Extends;
protected type FrameType = Env.FrameType;
protected type Import = Absyn.Import;

public function flattenProgram
  input SCode.Program inProgram;
  input Env inEnv;
  output SCode.Program outProgram;
  output Env outEnv;
algorithm
  (outProgram, outEnv) := List.mapFold(inProgram, flattenClass, inEnv);
end flattenProgram;

public function flattenClass
  input SCode.Element inClass;
  input Env inEnv;
  output SCode.Element outClass;
  output Env outEnv;
algorithm
  (outClass, outEnv) := matchcontinue(inClass, inEnv)
    local
      SCode.Ident name;
      SCode.ClassDef cdef;
      Absyn.Info info;
      Item item;
      Env env;
      FEnv.Frame cls_env;
      SCode.Element cls;
      FEnv.ClassType cls_ty;

    case (SCode.CLASS(name = name, classDef = cdef, info = info), _)
      equation
        (Env.CLASS(env = {cls_env}, classType = cls_ty), _) =
          FLookup.lookupInClass(name, inEnv);
        env = FEnv.enterFrame(cls_env, inEnv);

        (cdef, cls_env :: env) = flattenClassDef(cdef, env, info);
        cls = SCode.setElementClassDefinition(cdef, inClass);
        item = FEnv.newClassItem(cls, {cls_env}, cls_ty);
        env = FEnv.updateItemInEnv(item, env, name);
      then
        (cls, env);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- FFlattenImports.flattenClass failed on " +&
          SCode.elementName(inClass) +& " in " +& FEnv.getEnvName(inEnv));
      then
        fail();
  end matchcontinue;
end flattenClass;

protected function flattenClassDef
  input SCode.ClassDef inClassDef;
  input Env inEnv;
  input Absyn.Info inInfo;
  output SCode.ClassDef outClassDef;
  output Env outEnv;
algorithm
  (outClassDef, outEnv) := match(inClassDef, inEnv, inInfo)
    local
      list<SCode.Element> el;
      list<SCode.Equation> neql, ieql;
      list<SCode.AlgorithmSection> nal, ial;
      list<SCode.ConstraintSection> nco;
      list<Absyn.NamedArg> clats; //class attributes
      Option<SCode.ExternalDecl> extdecl;
      list<SCode.Annotation> annl;
      Option<SCode.Comment> cmt;
      Absyn.TypeSpec ty;
      SCode.Mod mods;
      SCode.Attributes attr;
      Env env;
      SCode.Ident bc;
      SCode.ClassDef cdef;

    case (SCode.PARTS(el, neql, ieql, nal, ial, nco, clats, extdecl, annl, cmt), _, _)
      equation
        // Lookup elements.
        el = List.filter(el, isNotImport);
        (el, env) = List.mapFold(el, flattenElement, inEnv);

        // Lookup equations and algorithm names.
        neql = List.map1(neql, flattenEquation, env);
        ieql = List.map1(ieql, flattenEquation, env);
        nal = List.map1(nal, flattenAlgorithm, env);
        ial = List.map1(ial, flattenAlgorithm, env);
        nco = List.map2(nco, flattenConstraints, env, inInfo);
      then
        (SCode.PARTS(el, neql, ieql, nal, ial, nco, clats, extdecl, annl, cmt), env);

    case (SCode.CLASS_EXTENDS(bc, mods, cdef), _, _)
      equation
        (cdef, env) = flattenClassDef(cdef, inEnv, inInfo);
        mods = flattenModifier(mods, env, inInfo);
      then
        (SCode.CLASS_EXTENDS(bc, mods, cdef), env);

    case (SCode.DERIVED(ty, mods, attr, cmt), env, _)
      equation
        mods = flattenModifier(mods, env, inInfo);
        // Remove the extends from the local scope before flattening the derived
        // type, because the type should not be looked up via itself.
        env = FEnv.removeExtendsFromLocalScope(env);
        ty = flattenTypeSpec(ty, env, inInfo);
      then
        (SCode.DERIVED(ty, mods, attr, cmt), inEnv);

    else then (inClassDef, inEnv);
  end match;
end flattenClassDef;

protected function flattenDerivedClassDef
  input SCode.ClassDef inClassDef;
  input Env inEnv;
  input Absyn.Info inInfo;
  output SCode.ClassDef outClassDef;
protected
  Absyn.TypeSpec ty;
  SCode.Mod mods;
  SCode.Attributes attr;
  Option<SCode.Comment> cmt;
algorithm
  SCode.DERIVED(ty, mods, attr, cmt) := inClassDef;
  ty := flattenTypeSpec(ty, inEnv, inInfo);
  mods := flattenModifier(mods, inEnv, inInfo);
  outClassDef := SCode.DERIVED(ty, mods, attr, cmt);
end flattenDerivedClassDef;

protected function isNotImport
  input SCode.Element inElement;
algorithm
  _ := match(inElement)
    case SCode.IMPORT(imp = _) then fail();
    else then ();
  end match;
end isNotImport;

protected function flattenElement
  input SCode.Element inElement;
  input Env inEnv;
  output SCode.Element outElement;
  output Env outEnv;
algorithm
  (outElement, outEnv) := match(inElement, inEnv)
    local
      Env env;
      SCode.Element elem;
      String name;
      Item item;

    // Lookup component types, modifications and conditions.
    case (SCode.COMPONENT(name = name), _)
      equation
        elem = flattenComponent(inElement, inEnv);
        item = FEnv.newVarItem(elem, true);
        env = FEnv.updateItemInEnv(item, inEnv, name);
      then
        (elem, env);

    // Lookup class definitions.
    case (SCode.CLASS(name = _), _)
      equation
        (elem, env) = flattenClass(inElement, inEnv);
      then
        (elem, env);

    // Lookup base class and modifications in extends clauses.
    case (SCode.EXTENDS(baseClassPath = _), _)
      then (flattenExtends(inElement, inEnv), inEnv);

    else then (inElement, inEnv);
  end match;
end flattenElement;

protected function flattenComponent
  input SCode.Element inComponent;
  input Env inEnv;
  output SCode.Element outComponent;
protected
  SCode.Ident name;
  Absyn.InnerOuter io;
  SCode.Prefixes prefixes;
  SCode.Attributes attr;
  Absyn.TypeSpec type_spec;
  SCode.Mod mod;
  Option<SCode.Comment> cmt;
  Option<Absyn.Exp> cond;
  Option<Absyn.ConstrainClass> cc;
  Absyn.Info info;
algorithm
  SCode.COMPONENT(name, prefixes, attr, type_spec, mod, cmt, cond, info) := inComponent;
  attr := flattenAttributes(attr, inEnv, info);
  type_spec := flattenTypeSpec(type_spec, inEnv, info);
  mod := flattenModifier(mod, inEnv, info);
  cond := flattenOptExp(cond, inEnv, info);
  outComponent := SCode.COMPONENT(name, prefixes, attr, type_spec, mod, cmt, cond, info);
end flattenComponent;

protected function flattenAttributes
  input SCode.Attributes inAttributes;
  input Env inEnv;
  input Absyn.Info inInfo;
  output SCode.Attributes outAttributes;
protected
  Absyn.ArrayDim ad;
  SCode.ConnectorType ct;
  SCode.Parallelism prl;
  SCode.Variability var;
  Absyn.Direction dir;
algorithm
  SCode.ATTR(ad, ct, prl, var, dir) := inAttributes;
  ad := List.map2(ad, flattenSubscript, inEnv, inInfo);
  outAttributes := SCode.ATTR(ad, ct, prl, var, dir);
end flattenAttributes;

protected function flattenTypeSpec
  input Absyn.TypeSpec inTypeSpec;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Absyn.TypeSpec outTypeSpec;
algorithm
  outTypeSpec := match(inTypeSpec, inEnv, inInfo)
    local
      Absyn.Path path;
      Option<Absyn.ArrayDim> ad;
      list<Absyn.TypeSpec> tys;

    // A normal type.
    case (Absyn.TPATH(path = path, arrayDim = ad), _, _)
      equation
        (_, path, _) = FLookup.lookupClassName(path, inEnv, inInfo);
      then
        Absyn.TPATH(path, ad);

    // A polymorphic type, i.e. replaceable type Type subtypeof Any.
    case (Absyn.TCOMPLEX(path = Absyn.IDENT("polymorphic")), _, _)
      then inTypeSpec;

    // A MetaModelica type such as list or tuple.
    case (Absyn.TCOMPLEX(path = path, typeSpecs = tys, arrayDim = ad), _, _)
      equation
        tys = List.map2(tys, flattenTypeSpec, inEnv, inInfo);
      then
        Absyn.TCOMPLEX(path, tys, ad);

  end match;
end flattenTypeSpec;

protected function flattenExtends
  input SCode.Element inExtends;
  input Env inEnv;
  output SCode.Element outExtends;
protected
  Absyn.Path path;
  SCode.Mod mod;
  Option<SCode.Annotation> ann;
  Absyn.Info info;
  Env env;
  SCode.Visibility vis;
algorithm
  SCode.EXTENDS(path, vis, mod, ann, info) := inExtends;
  env := FEnv.removeExtendsFromLocalScope(inEnv);
  (_, path, _) := FLookup.lookupBaseClassName(path, env, info);
  mod := flattenModifier(mod, inEnv, info);
  outExtends := SCode.EXTENDS(path, vis, mod, ann, info);
end flattenExtends;

protected function flattenEquation
  input SCode.Equation inEquation;
  input Env inEnv;
  output SCode.Equation outEquation;
protected
  SCode.EEquation equ;
algorithm
  SCode.EQUATION(equ) := inEquation;
  (equ, _) := SCode.traverseEEquations(equ, (flattenEEquationTraverser, inEnv));
  outEquation := SCode.EQUATION(equ);
end flattenEquation;

protected function flattenEEquationTraverser
  input tuple<SCode.EEquation, Env> inTuple;
  output tuple<SCode.EEquation, Env> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      SCode.EEquation equ;
      SCode.Ident iter_name;
      Env env;
      Absyn.Info info;
      Absyn.ComponentRef cref;
      Option<SCode.Comment> cmt;
      Absyn.Exp exp;

    case ((equ as SCode.EQ_FOR(index = iter_name, info = info), env))
      equation
        env = FEnv.extendEnvWithIterators({Absyn.ITERATOR(iter_name, NONE(), NONE())}, System.tmpTickIndex(Env.tmpTickIndex), env);
        (equ, _) = SCode.traverseEEquationExps(equ, (traverseExp, (env, info)));
      then
        ((equ, env));

    case ((SCode.EQ_REINIT(cref = cref, expReinit = exp, comment = cmt,
        info = info), env))
      equation
        cref = FLookup.lookupComponentRef(cref, env, info);
        equ = SCode.EQ_REINIT(cref, exp, cmt, info);
        (equ, _) = SCode.traverseEEquationExps(equ, (traverseExp, (env, info)));
      then
        ((equ, env));

    case ((equ, env))
      equation
        info = SCode.getEEquationInfo(equ);
        (equ, _) = SCode.traverseEEquationExps(equ, (traverseExp, (env, info)));
      then
        ((equ, env));

  end match;
end flattenEEquationTraverser;

protected function traverseExp
  input tuple<Absyn.Exp, tuple<Env, Absyn.Info>> inTuple;
  output tuple<Absyn.Exp, tuple<Env, Absyn.Info>> outTuple;
protected
  Absyn.Exp exp;
  Env env;
  Absyn.Info info;
algorithm
  (exp, (env, info)) := inTuple;
  (exp, (_, _, (env, info))) := Absyn.traverseExpBidir(exp,
    (flattenExpTraverserEnter, flattenExpTraverserExit, (env, info)));
  outTuple := (exp, (env, info));
end traverseExp;

protected function flattenConstraints
  input SCode.ConstraintSection inConstraints;
  input Env inEnv;
  input Absyn.Info inInfo;
  output SCode.ConstraintSection outConstraints;
protected
  list<Absyn.Exp> exps;
algorithm
  SCode.CONSTRAINTS(exps) := inConstraints;
  exps := List.map2(exps, flattenExp, inEnv, inInfo);
  outConstraints := SCode.CONSTRAINTS(exps);
end flattenConstraints;

protected function flattenAlgorithm
  input SCode.AlgorithmSection inAlgorithm;
  input Env inEnv;
  output SCode.AlgorithmSection outAlgorithm;
protected
  list<SCode.Statement> statements;
algorithm
  SCode.ALGORITHM(statements) := inAlgorithm;
  statements := List.map1(statements, flattenStatement, inEnv);
  outAlgorithm := SCode.ALGORITHM(statements);
end flattenAlgorithm;

protected function flattenStatement
  input SCode.Statement inStatement;
  input Env inEnv;
  output SCode.Statement outStatement;
algorithm
  (outStatement, _) := SCode.traverseStatements(inStatement, (flattenStatementTraverser, inEnv));
end flattenStatement;

protected function flattenStatementTraverser
  input tuple<SCode.Statement, Env> inTuple;
  output tuple<SCode.Statement, Env> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      Env env;
      String iter_name;
      SCode.Statement stmt;
      Absyn.Info info;

    case ((stmt as SCode.ALG_FOR(index = iter_name, info = info), env))
      equation
        env = FEnv.extendEnvWithIterators({Absyn.ITERATOR(iter_name, NONE(), NONE())}, System.tmpTickIndex(Env.tmpTickIndex), env);
        (stmt, _) = SCode.traverseStatementExps(stmt, (traverseExp, (env, info)));
      then
        ((stmt, env));

    case ((stmt as SCode.ALG_PARFOR(index = iter_name, info = info), env))
      equation
        env = FEnv.extendEnvWithIterators({Absyn.ITERATOR(iter_name, NONE(), NONE())}, System.tmpTickIndex(Env.tmpTickIndex), env);
        (stmt, _) = SCode.traverseStatementExps(stmt, (traverseExp, (env, info)));
      then
        ((stmt, env));

    case ((stmt, env))
      equation
        info = SCode.getStatementInfo(stmt);
        (stmt, _) = SCode.traverseStatementExps(stmt, (traverseExp, (env, info)));
      then
        ((stmt, env));

  end match;
end flattenStatementTraverser;

protected function flattenModifier
  input SCode.Mod inMod;
  input Env inEnv;
  input Absyn.Info inInfo;
  output SCode.Mod outMod;
algorithm
  outMod := match(inMod, inEnv, inInfo)
    local
      SCode.Final fp;
      SCode.Each ep;
      list<SCode.SubMod> sub_mods;
      Option<tuple<Absyn.Exp, Boolean>> opt_exp;
      SCode.Element el;
      Absyn.Info info;

    case (SCode.MOD(fp, ep, sub_mods, opt_exp, info), _, _)
      equation
        opt_exp = flattenModOptExp(opt_exp, inEnv, inInfo);
        sub_mods = List.map2(sub_mods, flattenSubMod, inEnv, inInfo);
      then
        SCode.MOD(fp, ep, sub_mods, opt_exp, info);

    case (SCode.REDECL(fp, ep, el), _, _)
      equation
        el = flattenRedeclare(el, inEnv);
      then
        SCode.REDECL(fp, ep, el);

    case (SCode.NOMOD(), _, _) then inMod;
  end match;
end flattenModifier;

protected function flattenModOptExp
  input Option<tuple<Absyn.Exp, Boolean>> inOptExp;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Option<tuple<Absyn.Exp, Boolean>> outOptExp;
algorithm
  outOptExp := match(inOptExp, inEnv, inInfo)
    local
      Absyn.Exp exp;
      Boolean delay_elab;

    case (SOME((exp, delay_elab)), _, _)
      equation
        exp = flattenExp(exp, inEnv, inInfo);
      then
        SOME((exp, delay_elab));

    case (NONE(), _, _) then inOptExp;
  end match;
end flattenModOptExp;

protected function flattenSubMod
  input SCode.SubMod inSubMod;
  input Env inEnv;
  input Absyn.Info inInfo;
  output SCode.SubMod outSubMod;
algorithm
  outSubMod := match(inSubMod, inEnv, inInfo)
    local
      SCode.Ident ident;
      list<SCode.Subscript> subs;
      SCode.Mod mod;

    case (SCode.NAMEMOD(ident = ident, A = mod), _, _)
      equation
        mod = flattenModifier(mod, inEnv, inInfo);
      then
        SCode.NAMEMOD(ident, mod);

  end match;
end flattenSubMod;

protected function flattenRedeclare
  input SCode.Element inElement;
  input Env inEnv;
  output SCode.Element outElement;
algorithm
  outElement := match(inElement, inEnv)
    local
      SCode.Ident name;
      SCode.Prefixes prefixes;
      SCode.Partial pp;
      SCode.Encapsulated ep;
      SCode.Restriction res;
      Absyn.Info info;
      SCode.Element element;
      SCode.ClassDef cdef;

    case (SCode.CLASS(name, prefixes, ep, pp, res,
          cdef as SCode.DERIVED(typeSpec = _), info), _)
      equation
        cdef = flattenDerivedClassDef(cdef, inEnv, info);
      then
        SCode.CLASS(name, prefixes, ep, pp, res, cdef, info);

    case (SCode.CLASS(classDef = SCode.ENUMERATION(enumLst = _)), _)
      then
        inElement;

    case (SCode.COMPONENT(name = _), _)
      equation
        element = flattenComponent(inElement, inEnv);
      then
        element;

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"Unknown redeclare in FFlattenImports.flattenRedeclare"});
      then
        fail();

  end match;
end flattenRedeclare;

protected function flattenSubscript
  input SCode.Subscript inSub;
  input Env inEnv;
  input Absyn.Info inInfo;
  output SCode.Subscript outSub;
algorithm
  outSub := match(inSub, inEnv, inInfo)
    local
      Absyn.Exp exp;

    case (Absyn.SUBSCRIPT(subscript = exp), _, _)
      equation
        exp = flattenExp(exp, inEnv, inInfo);
      then
        Absyn.SUBSCRIPT(exp);

    case (Absyn.NOSUB(), _, _) then inSub;
  end match;
end flattenSubscript;

protected function flattenExp
  input Absyn.Exp inExp;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Absyn.Exp outExp;
algorithm
  (outExp, _) := Absyn.traverseExpBidir(inExp, (flattenExpTraverserEnter, flattenExpTraverserExit, (inEnv, inInfo)));
end flattenExp;

protected function flattenOptExp
  input Option<Absyn.Exp> inExp;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Option<Absyn.Exp> outExp;
algorithm
  outExp := match(inExp, inEnv, inInfo)
    local
      Absyn.Exp exp;

    case (SOME(exp), _, _)
      equation
        exp = flattenExp(exp, inEnv, inInfo);
      then
        SOME(exp);

    case (NONE(), _, _) then inExp;
  end match;
end flattenOptExp;

protected function flattenExpTraverserEnter
  input tuple<Absyn.Exp, tuple<Env, Absyn.Info>> inTuple;
  output tuple<Absyn.Exp, tuple<Env, Absyn.Info>> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      Env env;
      Absyn.ComponentRef cref;
      Absyn.FunctionArgs args;
      Absyn.Exp exp;
      Absyn.ForIterators iters;
      Absyn.Info info;
      tuple<Env, Absyn.Info> tup;

    case ((Absyn.CREF(componentRef = cref), tup as (env, info)))
      equation
        cref = FLookup.lookupComponentRef(cref, env, info);
      then
        ((Absyn.CREF(cref), tup));

    case ((exp as Absyn.CALL(functionArgs =
        Absyn.FOR_ITER_FARG(iterators = iters)), (env, info)))
      equation
        env = FEnv.extendEnvWithIterators(iters, System.tmpTickIndex(Env.tmpTickIndex), env);
      then
        ((exp, (env, info)));

    case ((Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "SOME")), _))
      then inTuple;

    case ((Absyn.CALL(function_ = cref, functionArgs = args),
        tup as (env, info)))
      equation
        cref = FLookup.lookupComponentRef(cref, env, info);
        // TODO: handle function arguments
      then
        ((Absyn.CALL(cref, args), tup));

    case ((Absyn.PARTEVALFUNCTION(function_ = cref, functionArgs = args),
        tup as (env, info)))
      equation
        cref = FLookup.lookupComponentRef(cref, env, info);
        // TODO: handle function arguments
      then
        ((Absyn.PARTEVALFUNCTION(cref, args), tup));

    case ((exp as Absyn.MATCHEXP(matchTy = _), tup as (env, info)))
      equation
        env = FEnv.extendEnvWithMatch(exp, System.tmpTickIndex(Env.tmpTickIndex), env);
      then
        ((exp, (env, info)));
    else then inTuple;
  end match;
end flattenExpTraverserEnter;

protected function flattenExpTraverserExit
  input tuple<Absyn.Exp, tuple<Env, Absyn.Info>> inTuple;
  output tuple<Absyn.Exp, tuple<Env, Absyn.Info>> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      Absyn.Exp e;
      Env env;
      Absyn.Info info;

    case ((e as Absyn.CALL(functionArgs = Absyn.FOR_ITER_FARG(iterators = _)),
        (Env.FRAME(frameType = Env.IMPLICIT_SCOPE(iterIndex=_)) :: env, info)))
      then
        ((e, (env, info)));

    case ((e as Absyn.MATCHEXP(matchTy = _),
        (Env.FRAME(frameType = Env.IMPLICIT_SCOPE(iterIndex=_)) :: env, info)))
      then
        ((e, (env, info)));

    else then inTuple;
  end match;
end flattenExpTraverserExit;

public function flattenComponentRefSubs
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := match(inCref, inEnv, inInfo)
    local
      Absyn.Ident name;
      Absyn.ComponentRef cref;
      list<Absyn.Subscript> subs;

    case (Absyn.CREF_IDENT(name, subs), _, _)
      equation
        subs = List.map2(subs, flattenSubscript, inEnv, inInfo);
      then
        Absyn.CREF_IDENT(name, subs);

    case (Absyn.CREF_QUAL(name, subs, cref), _, _)
      equation
        subs = List.map2(subs, flattenSubscript, inEnv, inInfo);
        cref = flattenComponentRefSubs(cref, inEnv, inInfo);
      then
        Absyn.CREF_QUAL(name, subs, cref);

    case (Absyn.CREF_FULLYQUALIFIED(componentRef = cref), _, _)
      equation
        cref = flattenComponentRefSubs(cref, inEnv, inInfo);
      then
        Absyn.CREF_FULLYQUALIFIED(cref);

  end match;
end flattenComponentRefSubs;

end FFlattenImports;
