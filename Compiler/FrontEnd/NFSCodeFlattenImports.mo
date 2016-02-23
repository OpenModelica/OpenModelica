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

encapsulated package NFSCodeFlattenImports
" file:        NFSCodeFlattenImports.mo
  package:     NFSCodeFlattenImports
  description: SCode flattening


  This module flattens the SCode representation by removing all extends, imports
  and redeclares, and fully qualifying class names.
"

public import Absyn;
public import SCode;
public import NFSCodeEnv;

public type Env = NFSCodeEnv.Env;

protected import Debug;
protected import Error;
protected import Flags;
protected import List;
protected import NFSCodeLookup;
protected import System;

protected type Item = NFSCodeEnv.Item;
protected type Extends = NFSCodeEnv.Extends;
protected type FrameType = NFSCodeEnv.FrameType;
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
      SourceInfo info;
      Item item;
      Env env;
      NFSCodeEnv.Frame cls_env;
      SCode.Element cls;
      NFSCodeEnv.ClassType cls_ty;

    case (SCode.CLASS(name = name, classDef = cdef, info = info), _)
      equation
        (NFSCodeEnv.CLASS(env = {cls_env}, classType = cls_ty), _) =
          NFSCodeLookup.lookupInClass(name, inEnv);
        env = NFSCodeEnv.enterFrame(cls_env, inEnv);

        (cdef, cls_env :: env) = flattenClassDef(cdef, env, info);
        cls = SCode.setElementClassDefinition(cdef, inClass);
        item = NFSCodeEnv.newClassItem(cls, {cls_env}, cls_ty);
        env = NFSCodeEnv.updateItemInEnv(item, env, name);
      then
        (cls, env);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFSCodeFlattenImports.flattenClass failed on " +
          SCode.elementName(inClass) + " in " + NFSCodeEnv.getEnvName(inEnv));
      then
        fail();
  end matchcontinue;
end flattenClass;

protected function flattenClassDef
  input SCode.ClassDef inClassDef;
  input Env inEnv;
  input SourceInfo inInfo;
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

    case (SCode.PARTS(el, neql, ieql, nal, ial, nco, clats, extdecl), _, _)
      equation
        // Lookup elements.
        el = List.filterOnTrue(el, isNotImport);
        (el, env) = List.mapFold(el, flattenElement, inEnv);

        // Lookup equations and algorithm names.
        neql = List.map1(neql, flattenEquation, env);
        ieql = List.map1(ieql, flattenEquation, env);
        nal = List.map1(nal, flattenAlgorithm, env);
        ial = List.map1(ial, flattenAlgorithm, env);
        nco = List.map2(nco, flattenConstraints, env, inInfo);
      then
        (SCode.PARTS(el, neql, ieql, nal, ial, nco, clats, extdecl), env);

    case (SCode.CLASS_EXTENDS(bc, mods, cdef), _, _)
      equation
        (cdef, env) = flattenClassDef(cdef, inEnv, inInfo);
        mods = flattenModifier(mods, env, inInfo);
      then
        (SCode.CLASS_EXTENDS(bc, mods, cdef), env);

    case (SCode.DERIVED(ty, mods, attr), env, _)
      equation
        mods = flattenModifier(mods, env, inInfo);
        // Remove the extends from the local scope before flattening the derived
        // type, because the type should not be looked up via itself.
        env = NFSCodeEnv.removeExtendsFromLocalScope(env);
        ty = flattenTypeSpec(ty, env, inInfo);
      then
        (SCode.DERIVED(ty, mods, attr), inEnv);

    else (inClassDef, inEnv);
  end match;
end flattenClassDef;

protected function flattenDerivedClassDef
  input SCode.ClassDef inClassDef;
  input Env inEnv;
  input SourceInfo inInfo;
  output SCode.ClassDef outClassDef;
protected
  Absyn.TypeSpec ty;
  SCode.Mod mods;
  SCode.Attributes attr;
algorithm
  SCode.DERIVED(ty, mods, attr) := inClassDef;
  ty := flattenTypeSpec(ty, inEnv, inInfo);
  mods := flattenModifier(mods, inEnv, inInfo);
  outClassDef := SCode.DERIVED(ty, mods, attr);
end flattenDerivedClassDef;

protected function isNotImport
  input SCode.Element inElement;
  output Boolean outB;
algorithm
  outB := match(inElement)
    case SCode.IMPORT() then false;
    else true;
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
        item = NFSCodeEnv.newVarItem(elem, true);
        env = NFSCodeEnv.updateItemInEnv(item, inEnv, name);
      then
        (elem, env);

    // Lookup class definitions.
    case (SCode.CLASS(), _)
      equation
        (elem, env) = flattenClass(inElement, inEnv);
      then
        (elem, env);

    // Lookup base class and modifications in extends clauses.
    case (SCode.EXTENDS(), _)
      then (flattenExtends(inElement, inEnv), inEnv);

    else (inElement, inEnv);
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
  SCode.Comment cmt;
  Option<Absyn.Exp> cond;
  Option<Absyn.ConstrainClass> cc;
  SourceInfo info;
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
  input SourceInfo inInfo;
  output SCode.Attributes outAttributes;
protected
  Absyn.ArrayDim ad;
  SCode.ConnectorType ct;
  SCode.Parallelism prl;
  SCode.Variability var;
  Absyn.Direction dir;
  Absyn.IsField isf;
algorithm
  SCode.ATTR(ad, ct, prl, var, dir, isf) := inAttributes;
  ad := List.map2(ad, flattenSubscript, inEnv, inInfo);
  outAttributes := SCode.ATTR(ad, ct, prl, var, dir, isf);
end flattenAttributes;

protected function flattenTypeSpec
  input Absyn.TypeSpec inTypeSpec;
  input Env inEnv;
  input SourceInfo inInfo;
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
        (_, path, _) = NFSCodeLookup.lookupClassName(path, inEnv, inInfo);
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
  SourceInfo info;
  Env env;
  SCode.Visibility vis;
algorithm
  SCode.EXTENDS(path, vis, mod, ann, info) := inExtends;
  env := NFSCodeEnv.removeExtendsFromLocalScope(inEnv);
  (_, path, _) := NFSCodeLookup.lookupBaseClassName(path, env, info);
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
      SourceInfo info;
      Absyn.ComponentRef cref;
      SCode.Comment cmt;
      Absyn.Exp exp;

    case ((equ as SCode.EQ_FOR(index = iter_name, info = info), env))
      equation
        env = NFSCodeEnv.extendEnvWithIterators({Absyn.ITERATOR(iter_name, NONE(), NONE())}, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), env);
        (equ, _) = SCode.traverseEEquationExps(equ, traverseExp, (env, info));
      then
        ((equ, env));

    case ((SCode.EQ_REINIT(cref = cref, expReinit = exp, comment = cmt,
        info = info), env))
      equation
        cref = NFSCodeLookup.lookupComponentRef(cref, env, info);
        equ = SCode.EQ_REINIT(cref, exp, cmt, info);
        (equ, _) = SCode.traverseEEquationExps(equ, traverseExp, (env, info));
      then
        ((equ, env));

    case ((equ, env))
      equation
        info = SCode.getEEquationInfo(equ);
        (equ, _) = SCode.traverseEEquationExps(equ, traverseExp, (env, info));
      then
        ((equ, env));

  end match;
end flattenEEquationTraverser;

protected function traverseExp
  input Absyn.Exp inExp;
  input tuple<Env, SourceInfo> inTuple;
  output Absyn.Exp outExp;
  output tuple<Env, SourceInfo> outTuple;
algorithm
  (outExp, outTuple) := Absyn.traverseExpBidir(inExp, flattenExpTraverserEnter, flattenExpTraverserExit, inTuple);
end traverseExp;

protected function flattenConstraints
  input SCode.ConstraintSection inConstraints;
  input Env inEnv;
  input SourceInfo inInfo;
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
      SourceInfo info;

    case ((stmt as SCode.ALG_FOR(index = iter_name, info = info), env))
      equation
        env = NFSCodeEnv.extendEnvWithIterators({Absyn.ITERATOR(iter_name, NONE(), NONE())}, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), env);
        (stmt, _) = SCode.traverseStatementExps(stmt, traverseExp, (env, info));
      then
        ((stmt, env));

    case ((stmt as SCode.ALG_PARFOR(index = iter_name, info = info), env))
      equation
        env = NFSCodeEnv.extendEnvWithIterators({Absyn.ITERATOR(iter_name, NONE(), NONE())}, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), env);
        (stmt, _) = SCode.traverseStatementExps(stmt, traverseExp, (env, info));
      then
        ((stmt, env));

    case ((stmt, env))
      equation
        info = SCode.getStatementInfo(stmt);
        (stmt, _) = SCode.traverseStatementExps(stmt, traverseExp, (env, info));
      then
        ((stmt, env));

  end match;
end flattenStatementTraverser;

protected function flattenModifier
  input SCode.Mod inMod;
  input Env inEnv;
  input SourceInfo inInfo;
  output SCode.Mod outMod;
algorithm
  outMod := match(inMod, inEnv, inInfo)
    local
      SCode.Final fp;
      SCode.Each ep;
      list<SCode.SubMod> sub_mods;
      Option<Absyn.Exp> opt_exp;
      SCode.Element el;
      SourceInfo info;

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
  input Option<Absyn.Exp> inOptExp;
  input Env inEnv;
  input SourceInfo inInfo;
  output Option<Absyn.Exp> outOptExp;
algorithm
  outOptExp := match inOptExp
    local
      Absyn.Exp exp;

    case SOME(exp)
      equation
        exp = flattenExp(exp, inEnv, inInfo);
      then
        SOME(exp);

    else inOptExp;
  end match;
end flattenModOptExp;

protected function flattenSubMod
  input SCode.SubMod inSubMod;
  input Env inEnv;
  input SourceInfo inInfo;
  output SCode.SubMod outSubMod;
algorithm
  outSubMod := match(inSubMod, inEnv, inInfo)
    local
      SCode.Ident ident;
      list<SCode.Subscript> subs;
      SCode.Mod mod;

    case (SCode.NAMEMOD(ident = ident, mod = mod), _, _)
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
      SourceInfo info;
      SCode.Element element;
      SCode.ClassDef cdef,cdef2;
      SCode.Comment cmt;

    case (SCode.CLASS(name, prefixes, ep, pp, res,
          cdef as SCode.DERIVED(), cmt, info), _)
      equation
        cdef2 = flattenDerivedClassDef(cdef, inEnv, info);
      then
        SCode.CLASS(name, prefixes, ep, pp, res, cdef2, cmt, info);

    case (SCode.CLASS(classDef = SCode.ENUMERATION()), _)
      then
        inElement;

    case (SCode.COMPONENT(), _)
      equation
        element = flattenComponent(inElement, inEnv);
      then
        element;

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"Unknown redeclare in NFSCodeFlattenImports.flattenRedeclare"});
      then
        fail();

  end match;
end flattenRedeclare;

protected function flattenSubscript
  input SCode.Subscript inSub;
  input Env inEnv;
  input SourceInfo inInfo;
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
  input SourceInfo inInfo;
  output Absyn.Exp outExp;
algorithm
  (outExp, _) := Absyn.traverseExpBidir(inExp, flattenExpTraverserEnter, flattenExpTraverserExit, (inEnv, inInfo));
end flattenExp;

protected function flattenOptExp
  input Option<Absyn.Exp> inExp;
  input Env inEnv;
  input SourceInfo inInfo;
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

    else inExp;
  end match;
end flattenOptExp;

protected function flattenExpTraverserEnter
  input Absyn.Exp inExp;
  input tuple<Env, SourceInfo> inTuple;
  output Absyn.Exp outExp;
  output tuple<Env, SourceInfo> outTuple;
algorithm
  (outExp,outTuple) := match(inExp,inTuple)
    local
      Env env;
      Absyn.ComponentRef cref;
      Absyn.FunctionArgs args;
      Absyn.Exp exp;
      Absyn.ForIterators iters;
      SourceInfo info;
      tuple<Env, SourceInfo> tup;

    case (Absyn.CREF(componentRef = cref), tup as (env, info))
      equation
        cref = NFSCodeLookup.lookupComponentRef(cref, env, info);
      then
        (Absyn.CREF(cref), tup);

    case (Absyn.CALL(functionArgs = Absyn.FOR_ITER_FARG(iterators = iters)), (env, info))
      equation
        env = NFSCodeEnv.extendEnvWithIterators(iters, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), env);
      then
        (inExp, (env, info));

    case (Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "SOME")), _)
      then (inExp,inTuple);

    case (Absyn.CALL(function_ = cref, functionArgs = args), tup as (env, info))
      equation
        cref = NFSCodeLookup.lookupComponentRef(cref, env, info);
        // TODO: handle function arguments
      then
        (Absyn.CALL(cref, args), tup);

    case (Absyn.PARTEVALFUNCTION(function_ = cref, functionArgs = args), tup as (env, info))
      equation
        cref = NFSCodeLookup.lookupComponentRef(cref, env, info);
        // TODO: handle function arguments
      then
        (Absyn.PARTEVALFUNCTION(cref, args), tup);

    case (exp as Absyn.MATCHEXP(), (env, info))
      equation
        env = NFSCodeEnv.extendEnvWithMatch(exp, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), env);
      then
        (exp, (env, info));
    else (inExp,inTuple);
  end match;
end flattenExpTraverserEnter;

protected function flattenExpTraverserExit
  input Absyn.Exp inExp;
  input tuple<Env, SourceInfo> inTuple;
  output Absyn.Exp outExp;
  output tuple<Env, SourceInfo> outTuple;
algorithm
  (outExp,outTuple) := match(inExp,inTuple)
    local
      Absyn.Exp e;
      Env env;
      SourceInfo info;

    case (Absyn.CALL(functionArgs = Absyn.FOR_ITER_FARG()),
        (NFSCodeEnv.FRAME(frameType = NFSCodeEnv.IMPLICIT_SCOPE()) :: env, info))
      then
        (inExp, (env, info));

    case (Absyn.MATCHEXP(),
        (NFSCodeEnv.FRAME(frameType = NFSCodeEnv.IMPLICIT_SCOPE()) :: env, info))
      then
        (inExp, (env, info));

    else (inExp,inTuple);
  end match;
end flattenExpTraverserExit;

public function flattenComponentRefSubs
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  input SourceInfo inInfo;
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
        Absyn.crefMakeFullyQualified(cref);

  end match;
end flattenComponentRefSubs;

annotation(__OpenModelica_Interface="frontend");
end NFSCodeFlattenImports;
