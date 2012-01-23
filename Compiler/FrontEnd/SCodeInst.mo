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

encapsulated package SCodeInst
" file:        SCodeInst.mo
  package:     SCodeInst
  description: SCode instantiation

  RCS: $Id$

  Prototype SCode instantiation, enable with +d=scodeInst.
"

public import Absyn;
public import DAE;
public import SCode;
public import SCodeEnv;

protected import Debug;
protected import Dump;
protected import Error;
protected import Expression;
protected import Flags;
protected import List;
protected import SCodeDump;
protected import SCodeLookup;
protected import SCodeFlattenRedeclare;
protected import System;
protected import Types;
protected import Util;

public type Env = SCodeEnv.Env;
protected type Item = SCodeEnv.Item;

protected type Prefix = list<tuple<String, Absyn.ArrayDim>>;

public uniontype FlatProgram
  record FLAT_PROGRAM
    list<SCode.Element> components;
    list<SCode.Equation> equations;
    list<SCode.Equation> initialEquations;
    list<SCode.AlgorithmSection> algorithms;
    list<SCode.AlgorithmSection> initalAlgorithms;
  end FLAT_PROGRAM;
end FlatProgram;

protected constant FlatProgram EMPTY_FLAT_PROGRAM = 
  FLAT_PROGRAM({}, {}, {}, {}, {});


public function instClass
  "Flattens a class."
  input Absyn.Path inClassPath;
  input Env inEnv;
protected
algorithm
  _ := matchcontinue(inClassPath, inEnv)
    local
      Item item;
      Absyn.Path path;
      Env env; 
      String name;
      Integer var_count;
      FlatProgram program;

    case (_, _)
      equation
        System.startTimer();
        name = Absyn.pathLastIdent(inClassPath);
        (item, path, env) = 
          SCodeLookup.lookupClassName(inClassPath, inEnv, Absyn.dummyInfo);
        (program, _) = instClassItem(item, SCode.NOMOD(), env, {});
        System.stopTimer();
        //print("SCodeInst took " +& realString(System.getTimerIntervalTime()) +&
        //  " seconds.\n");
        //printFlatProgram(name, program);
      then
        ();

    else
      equation
        print("SCodeInst.instClass failed\n");
        true = Flags.isSet(Flags.FAILTRACE);
        name = Absyn.pathString(inClassPath);
        Debug.traceln("SCodeInst.instClass failed on " +& name);
      then
        fail();

  end matchcontinue;
end instClass;

protected function mergeFlatProgram
  input FlatProgram inProgram1;
  input FlatProgram inProgram2;
  output FlatProgram outProgram;
algorithm
  outProgram := match(inProgram1, inProgram2)
    local
      list<SCode.Element> el1, el2;
      list<SCode.Equation> eq1, eq2, ie1, ie2;
      list<SCode.AlgorithmSection> al1, al2, ia1, ia2;

    case (FLAT_PROGRAM({}, {}, {}, {}, {}), _) then inProgram2;
    case (_, FLAT_PROGRAM({}, {}, {}, {}, {})) then inProgram1;

    case (FLAT_PROGRAM(el1, eq1, ie1, al1, ia1),
          FLAT_PROGRAM(el2, eq2, ie2, al2, ia2))
      equation
        el1 = listAppend(el1, el2);
        eq1 = listAppend(eq1, eq2);
        ie1 = listAppend(ie1, ie2);
        al1 = listAppend(al1, al2);
        ia1 = listAppend(ia1, ia2);
      then
        FLAT_PROGRAM(el1, eq1, ie1, al1, ia1);

  end match;
end mergeFlatProgram;

protected function instClassItem
  input Item inItem;
  input SCode.Mod inMod;
  input Env inEnv;
  input Prefix inPrefix;
  output FlatProgram outProgram;
  output DAE.Type outType;
protected
  Item item;
algorithm
  item := convertDerivedBasicTypeToShortDef(inItem);
  (outProgram, outType) := instClassItem2(item, inMod, inEnv, inPrefix);
end instClassItem;

protected function instClassItem2
  input Item inItem;
  input SCode.Mod inMod;
  input Env inEnv;
  input Prefix inPrefix;
  output FlatProgram outProgram;
  output DAE.Type outType;
algorithm
  (outProgram, outType) := match(inItem, inMod, inEnv, inPrefix)
    local
      list<SCode.Element> el;
      list<Integer> var_counts;
      Integer var_count;
      Absyn.TypeSpec dty;
      Item item;
      Env env;
      Absyn.Info info;
      SCode.Mod mod;
      SCodeEnv.AvlTree cls_and_vars;
      String name;
      list<SCode.Equation> nel, iel;
      list<SCode.AlgorithmSection> nal, ial;
      list<FlatProgram> progs;
      FlatProgram prog;
      DAE.Type ty;
      Absyn.ArrayDim dims;
      list<DAE.Var> vars;

    case (SCodeEnv.CLASS(cls = SCode.CLASS(name = name), env = env,
        classType = SCodeEnv.BASIC_TYPE()), _, _, _) 
      equation
        vars = instBasicTypeAttributes(inMod, env);
        ty = instBasicType(name, inMod, vars);
      then 
        (EMPTY_FLAT_PROGRAM, ty);

    // A class with parts, instantiate all elements in it.
    case (SCodeEnv.CLASS(cls = SCode.CLASS(name = name, 
          classDef = SCode.PARTS(el, nel, iel, nal, ial, _, _, _)), 
        env = {SCodeEnv.FRAME(clsAndVars = cls_and_vars)}), _, _, _)
      equation
        env = SCodeEnv.mergeItemEnv(inItem, inEnv);
        el = List.map1(el, lookupElement, cls_and_vars);
        el = applyModifications(inMod, el, inPrefix, env);
        prog = FLAT_PROGRAM(el, nel, iel, nal, ial);
        progs = List.map2(el, instElement, env, inPrefix);
        progs = prog :: progs;
        prog = List.fold(progs, mergeFlatProgram, EMPTY_FLAT_PROGRAM);
      then
        (prog, DAE.T_COMPLEX_DEFAULT);

    // A derived class, look up the inherited class and instantiate it.
    case (SCodeEnv.CLASS(cls = SCode.CLASS(classDef =
        SCode.DERIVED(modifications = mod, typeSpec = dty), info = info)), _, _, _)
      equation
        (item, env) = SCodeLookup.lookupTypeSpec(dty, inEnv, info);
        mod = mergeMod(inMod, mod);
        (prog, ty) = instClassItem(item, mod, env, inPrefix);
        dims = Absyn.typeSpecDimensions(dty);
        ty = liftArrayType(dims, ty, inEnv);
      then
        (prog, ty);
        
    else (EMPTY_FLAT_PROGRAM, DAE.T_NONE_DEFAULT);
  end match;
end instClassItem2;

protected function convertDerivedBasicTypeToShortDef
  input Item inItem;
  output Item outItem;
algorithm
  outItem := match(inItem)
    local
      String bc;
      Boolean is_basic;

    case SCodeEnv.CLASS(cls = SCode.CLASS(classDef = SCode.PARTS(
        {SCode.EXTENDS(baseClassPath = Absyn.IDENT(bc))}, {}, {}, {}, {}, NONE(), _, _)))
      equation
        is_basic = isBasicType(bc);
      then 
        convertDerivedBasicTypeToShortDef2(inItem, is_basic, bc);

    else inItem;
  end match;
end convertDerivedBasicTypeToShortDef;

protected function isBasicType
  input String inTypeName;
  output Boolean outIsBasicType;
algorithm
  outIsBasicType := match(inTypeName)
    case "Real" then true;
    case "Integer" then true;
    case "String" then true;
    case "Boolean" then true;
    case "StateSelect" then true;
    else false;
  end match;
end isBasicType;

protected function convertDerivedBasicTypeToShortDef2
  input Item inItem;
  input Boolean inIsBasicType;
  input String inBaseClass;
  output Item outItem;
algorithm
  outItem := match(inItem, inIsBasicType, inBaseClass)
    local
      String name;
      SCode.Prefixes pf;
      SCode.Encapsulated ep;
      SCode.Partial pp;
      SCode.Restriction res;
      Absyn.Info info;
      Env env;
      SCodeEnv.ClassType ty;
      SCode.Visibility vis;
      SCode.Mod mod;
      list<SCode.Annotation> annl;
      Option<SCode.Comment> cmt;

    case (_, false, _) then inItem;

    case (SCodeEnv.CLASS(SCode.CLASS(name, pf, ep, pp, res, 
        SCode.PARTS({SCode.EXTENDS(_, vis, mod, _, _)}, {}, {}, {}, {}, 
          NONE(), annl, cmt), info), env, ty), _, _)
      equation
        cmt = makeClassComment(annl, cmt);
        // TODO: Check restriction
        // TODO: Check visibility
      then
        SCodeEnv.CLASS(SCode.CLASS(name, pf, ep, pp, res,
          SCode.DERIVED(Absyn.TPATH(Absyn.IDENT(inBaseClass), NONE()), mod,
            SCode.defaultVarAttr, cmt), info), env, ty);

  end match;
end convertDerivedBasicTypeToShortDef2;

protected function makeClassComment
  input list<SCode.Annotation> inAnnotations;
  input Option<SCode.Comment> inComment;
  output Option<SCode.Comment> outComment;
algorithm
  outComment := match(inAnnotations, inComment)
    case ({}, NONE()) then NONE();
    else SOME(SCode.CLASS_COMMENT(inAnnotations, inComment));
  end match;
end makeClassComment;

protected function instBasicType
  input SCode.Ident inTypeName;
  input SCode.Mod inMod;
  input list<DAE.Var> inAttributes;
  output DAE.Type outType;
algorithm
  outType := match(inTypeName, inMod, inAttributes)
    case ("Real", _, _) then DAE.T_REAL(inAttributes, DAE.emptyTypeSource);
    case ("Integer", _, _) then DAE.T_INTEGER(inAttributes, DAE.emptyTypeSource);
    case ("String", _, _) then DAE.T_STRING(inAttributes, DAE.emptyTypeSource);
    case ("Boolean", _, _) then DAE.T_BOOL(inAttributes, DAE.emptyTypeSource);
    case ("StateSelect", _, _) then DAE.T_ENUMERATION_DEFAULT;
  end match;
end instBasicType;

protected function applyModifications
  "Applies a class modifier to the class' elements."
  input SCode.Mod inMod;
  input list<SCode.Element> inElements;
  input Prefix inPrefix;
  input Env inEnv;
  output list<SCode.Element> outElements;
protected
  list<tuple<String, SCode.Mod>> mods;
  list<tuple<String, Option<Absyn.Path>, SCode.Mod>> upd_mods;
algorithm
  mods := splitMod(inMod, inPrefix);
  upd_mods := List.map2(mods, updateModElement, inEnv, inPrefix);
  outElements := List.fold(upd_mods, applyModifications2, inElements);
end applyModifications;

protected function updateModElement
  "Given a tuple of an element name and a modifier, checks if the element 
   is in the local scope, or if it comes from an extends clause. If it comes
   from an extends, return a new tuple that also contains the path of the
   extends, otherwise the option will be NONE."
  input tuple<String, SCode.Mod> inMod;
  input Env inEnv;
  input Prefix inPrefix;
  output tuple<String, Option<Absyn.Path>, SCode.Mod> outMod;
protected
algorithm
  outMod := matchcontinue(inMod, inEnv, inPrefix)
    local
      String name, pre_str;
      SCode.Mod mod;
      Absyn.Path path;
      Env env;
      SCodeEnv.AvlTree tree;
      Absyn.Info info;

    // Check if the element can be found in the local scope first.
    case ((name, mod), SCodeEnv.FRAME(clsAndVars = tree) :: _, _)
      equation
        _ = SCodeLookup.lookupInTree(name, tree);
      then
        ((name, NONE(), mod));

    // Check which extends the element comes from.
    // TODO: The element might come from multiple extends!
    case ((name, mod), _, _)
      equation
        (_, _, path, _) = SCodeLookup.lookupInBaseClasses(name, inEnv,
          SCodeLookup.IGNORE_REDECLARES(), {});
      then
        ((name, SOME(path), mod));

    case ((name, mod), _, _)
      equation
        pre_str = printPrefix(inPrefix);
        info = SCode.getModifierInfo(mod);
        Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
          {name, pre_str}, info);
      then
        fail();
        
  end matchcontinue;
end updateModElement;
  
protected function applyModifications2
  "Given a tuple of an element name, and optional path and a modifier, apply
   the modifier to the correct element in the list of elements given."
  input tuple<String, Option<Absyn.Path>, SCode.Mod> inMod;
  input list<SCode.Element> inElements;
  output list<SCode.Element> outElements;
algorithm
  outElements := matchcontinue(inMod, inElements)
    local
      String name, id;
      Absyn.Path path, bc_path;
      SCode.Prefixes pf;
      SCode.Attributes attr;
      Absyn.TypeSpec ty;
      Option<SCode.Comment> cmt;
      Option<Absyn.Exp> cond;
      Absyn.Info info;
      SCode.Mod inner_mod, outer_mod;
      SCode.Element e;
      list<SCode.Element> rest_el;
      SCode.Visibility vis;
      Option<SCode.Annotation> ann;

    // No more elements, this should actually be an error!
    case (_, {}) then {};

    // The optional path is NONE, we are looking for an element.
    case ((id, NONE(), outer_mod), 
        SCode.COMPONENT(name, pf, attr, ty, inner_mod, cmt, cond, info) :: rest_el)
      equation
        true = stringEq(id, name);
        // Element name matches, merge the modifiers.
        inner_mod = mergeMod(outer_mod, inner_mod);
      then
        SCode.COMPONENT(name, pf, attr, ty, inner_mod, cmt, cond, info) :: rest_el;
    
    // The optional path is SOME, we are looking for an extends.
    case ((id, SOME(path), outer_mod),
        SCode.EXTENDS(bc_path, vis, inner_mod, ann, info) :: rest_el)
      equation
        true = Absyn.pathEqual(path, bc_path);
        // Element name matches. Create a new modifier with the given modifier
        // as a named modifier, since the modifier is meant for an element in
        // the extended class, and merge the modifiers.
        outer_mod = SCode.MOD(SCode.NOT_FINAL(), SCode.NOT_EACH(), 
          {SCode.NAMEMOD(id, outer_mod)}, NONE(), Absyn.dummyInfo);
        inner_mod = mergeMod(outer_mod, inner_mod);
      then
        SCode.EXTENDS(bc_path, vis, inner_mod, ann, info) :: rest_el;

    // No match, search the rest of the elements.
    case (_, e :: rest_el)
      equation
        rest_el = applyModifications2(inMod, rest_el);
      then
        e :: rest_el;

  end matchcontinue;
end applyModifications2;

protected function mergeMod
  "Merges two modifiers, where the outer modifier has higher priority than the
   inner one."
  input SCode.Mod inOuterMod;
  input SCode.Mod inInnerMod;
  output SCode.Mod outMod;
algorithm
  outMod := match(inOuterMod, inInnerMod)
    local
      SCode.Final fp1, fp2;
      SCode.Each ep;
      list<SCode.SubMod> submods1, submods2;
      Option<tuple<Absyn.Exp, Boolean>> binding;
      Absyn.Info info;

    // One of the modifiers is NOMOD, return the other.
    case (SCode.NOMOD(), _) then inInnerMod;
    case (_, SCode.NOMOD()) then inOuterMod;

    // Neither of the modifiers have a binding, just merge the submods.
    case (SCode.MOD(subModLst = submods1, binding = NONE(), info = info),
          SCode.MOD(subModLst = submods2, binding = NONE()))
      equation
        submods1 = List.fold(submods1, mergeSubMod, submods2);
      then
        SCode.MOD(SCode.NOT_FINAL(), SCode.NOT_EACH(), submods1, NONE(), info);

    // The outer modifier has a binding which takes priority over the inner
    // modifiers binding.
    case (SCode.MOD(fp1, ep, submods1, binding as SOME(_), info),
        SCode.MOD(finalPrefix = fp2, subModLst = submods2))
      equation
        checkModifierFinalOverride(inOuterMod, inInnerMod);
        submods1 = List.fold(submods1, mergeSubMod, submods2);
      then
        SCode.MOD(fp1, ep, submods1, binding, info);

    // The inner modifier has a binding, but not the outer, so keep it.
    case (SCode.MOD(subModLst = submods1),
          SCode.MOD(fp1, ep, submods2, binding as SOME(_), info))
      equation
        checkModifierFinalOverride(inOuterMod, inInnerMod);
        submods2 = List.fold(submods1, mergeSubMod, submods2);
      then
        SCode.MOD(fp1, ep, submods2, binding, info);

    case (SCode.MOD(subModLst = _), SCode.REDECL(element = _))
      then inOuterMod;

    case (SCode.REDECL(element = _), _) then inInnerMod;

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"SCodeInst.mergeMod failed on unknown mod."});
      then
        fail();
  end match;
end mergeMod;

protected function checkModifierFinalOverride
  input SCode.Mod inOuterMod;
  input SCode.Mod inInnerMod;
algorithm
  _ := match(inOuterMod, inInnerMod)
    case (_, SCode.MOD(finalPrefix = SCode.FINAL()))
      equation
        print("Trying to override final modifier " +& printMod(inInnerMod) +& 
          " with modifier " +& printMod(inOuterMod) +& "\n");
      then
        fail();

    else ();
  end match;
end checkModifierFinalOverride;

protected function mergeSubMod
  "Merges a sub modifier into a list of sub modifiers."
  input SCode.SubMod inSubMod;
  input list<SCode.SubMod> inSubMods;
  output list<SCode.SubMod> outSubMods;
algorithm
  outSubMods := matchcontinue(inSubMod, inSubMods)
    local
      SCode.Ident id1, id2;
      SCode.Mod mod1, mod2;
      SCode.SubMod submod;
      list<SCode.SubMod> rest_mods;

    // No matching sub modifier found, add the given sub modifier as it is.
    case (_, {}) then {inSubMod};

    // Check if the sub modifier matches the first in the list.
    case (SCode.NAMEMOD(id1, mod1), SCode.NAMEMOD(id2, mod2) :: rest_mods)
      equation
        true = stringEq(id1, id2);
        // Match found, merge the sub modifiers.
        mod1 = mergeMod(mod1, mod2);
      then
        SCode.NAMEMOD(id1, mod1) :: rest_mods;

    // No match found, search the rest of the list.
    case (_, submod :: rest_mods)
      equation
        rest_mods = mergeSubMod(inSubMod, rest_mods);
      then 
        submod :: rest_mods;

  end matchcontinue;
end mergeSubMod;

protected function splitMod
  "Splits a modifier that contains sub modifiers info a list of tuples of
   element names with their corresponding modifiers. Ex:
     MOD(x(w = 2), y = 3, x(z = 4) = 5 => 
      {('x', MOD(w = 2, z = 4) = 5), ('y', MOD() = 3)}" 
  input SCode.Mod inMod;
  input Prefix inPrefix;
  output list<tuple<String, SCode.Mod>> outMods;
algorithm
  outMods := match(inMod, inPrefix)
    local
      SCode.Final fp;
      SCode.Each ep;
      list<SCode.SubMod> submods;
      Option<tuple<Absyn.Exp, Boolean>> binding;
      Option<Absyn.Exp> bind_exp;
      list<tuple<String, SCode.Mod>> mods;
      Absyn.Info info;

    // TOOD: print an error if this modifier has a binding?
    case (SCode.MOD(subModLst = submods, binding = binding), _)
      equation
        mods = List.fold1(submods, splitSubMod, inPrefix, {});
      then
        mods;

    else {};

  end match;
end splitMod;

protected function splitSubMod
  "Splits a named sub modifier."
  input SCode.SubMod inSubMod;
  input Prefix inPrefix;
  input list<tuple<String, SCode.Mod>> inMods;
  output list<tuple<String, SCode.Mod>> outMods;
algorithm
  outMods := match(inSubMod, inPrefix, inMods)
    local
      SCode.Ident id;
      SCode.Mod mod;
      list<tuple<String, SCode.Mod>> mods;

    // Filter out redeclarations, they have already been applied.
    case (SCode.NAMEMOD(A = SCode.REDECL(element = _)), _, _)
      then inMods;

    case (SCode.NAMEMOD(ident = id, A = mod), _, _)
      equation
        mods = splitMod2(id, mod, inPrefix, inMods);
      then
        mods;

    case (SCode.IDXMOD(an = _), _, _)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"Subscripted modifiers are not supported."});
      then
        fail();

  end match;
end splitSubMod;

protected function splitMod2
  "Helper function to splitSubMod. Tries to find a modifier for the same element
   as the given modifier, and in that case merges them. Otherwise, add the
   modifier to the given list."
  input String inId;
  input SCode.Mod inMod;
  input Prefix inPrefix;
  input list<tuple<String, SCode.Mod>> inMods;
  output list<tuple<String, SCode.Mod>> outMods;
algorithm
  outMods := matchcontinue(inId, inMod, inPrefix, inMods)
    local
      SCode.Mod mod;
      tuple<String, SCode.Mod> tup_mod;
      list<tuple<String, SCode.Mod>> rest_mods;
      String id;
      SCode.SubMod submod;
      list<SCode.SubMod> submods;

    // No match, add the modifier to the list.
    case (_, _, _, {}) then {(inId, inMod)};

    case (_, _, _, (id, mod) :: rest_mods)
      equation
        true = stringEq(id, inId);
        // Matching element, merge the modifiers.
        mod = mergeModsInSameScope(mod, inMod, id, inPrefix);
      then
        (inId, mod) :: rest_mods;

    case (_, _, _, tup_mod :: rest_mods)
      equation
        rest_mods = splitMod2(inId, inMod, inPrefix, rest_mods);
      then
        tup_mod :: rest_mods;

  end matchcontinue;
end splitMod2;

protected function mergeModsInSameScope
  "Merges two modifier in the same scope, i.e. they have the same priority. It's
   thus an error if the modifiers modify the same element."
  input SCode.Mod inMod1;
  input SCode.Mod inMod2;
  input String inElementName;
  input Prefix inPrefix;
  output SCode.Mod outMod;
algorithm
  outMod := match(inMod1, inMod2, inElementName, inPrefix)
    local
      SCode.Final fp;
      SCode.Each ep;
      list<SCode.SubMod> submods1, submods2;
      Option<tuple<Absyn.Exp, Boolean>> binding;
      String comp_str;
      Absyn.Info info1, info2;

    // The second modifier has no binding, use the binding from the first.
    case (SCode.MOD(fp, ep, submods1, binding, info1), 
          SCode.MOD(subModLst = submods2, binding = NONE()), _, _)
      equation
        submods1 = List.fold2(submods1, mergeSubModInSameScope, inPrefix,
          inElementName, submods2);
      then
        SCode.MOD(fp, ep, submods1, binding, info1);

    // The first modifier has no binding, use the binding from the second.
    case (SCode.MOD(subModLst = submods1, binding = NONE()),
        SCode.MOD(fp, ep, submods2, binding, info2), _, _)
      equation
        submods1 = List.fold2(submods1, mergeSubModInSameScope, inPrefix,
          inElementName, submods2);
      then
        SCode.MOD(fp, ep, submods1, binding, info2);

    // Both modifiers have bindings, show duplicate modification error.
    case (SCode.MOD(binding = SOME(_), info = info1), 
          SCode.MOD(binding = SOME(_), info = info2), _, _)
      equation
        comp_str = printPrefix(inPrefix);
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, info2);
        Error.addSourceMessage(Error.DUPLICATE_MODIFICATIONS, 
          {inElementName, comp_str}, info1);
      then
        fail();

  end match;
end mergeModsInSameScope;

protected function mergeSubModInSameScope
  "Merges two sub modifiers in the same scope."
  input SCode.SubMod inSubMod;
  input Prefix inPrefix;
  input String inElementName;
  input list<SCode.SubMod> inSubMods;
  output list<SCode.SubMod> outSubMods;
algorithm
  outSubMods := match(inSubMod, inPrefix, inElementName, inSubMods)
    local
      SCode.Ident id1, id2;
      SCode.Mod mod1, mod2;
      list<SCode.SubMod> rest_mods;
      SCode.SubMod submod;

    case (_, _, _, {}) then inSubMods;
    case (SCode.NAMEMOD(id1, mod1), _, _, SCode.NAMEMOD(id2, mod2) :: rest_mods)
      equation
        true = stringEq(id1, id2);
        id1 = inElementName +& "." +& id1;
        mod1 = mergeModsInSameScope(mod1, mod2, id1, inPrefix);
      then
        SCode.NAMEMOD(id1, mod1) :: rest_mods;

    case (_, _, _, submod :: rest_mods)
      equation
        rest_mods = mergeSubModInSameScope(inSubMod, inPrefix, inElementName, rest_mods);
      then
        submod :: rest_mods;

  end match;
end mergeSubModInSameScope;

protected function instBasicTypeAttributes
  input SCode.Mod inMod;
  input Env inEnv;
  output list<DAE.Var> outVars;
algorithm
  outVars := match(inMod, inEnv)
    local
      list<SCode.SubMod> submods;
      SCodeEnv.AvlTree attrs;
      list<DAE.Var> vars;
      SCode.Element el;
      Absyn.Info info;

    case (SCode.NOMOD(), _) then {};

    case (SCode.MOD(subModLst = submods), 
        SCodeEnv.FRAME(clsAndVars = attrs) :: _)
      equation
        vars = List.map1(submods, instBasicTypeAttribute, attrs);
      then
        vars;

    case (SCode.REDECL(element = el), _)
      equation
        info = SCode.elementInfo(el);
        Error.addSourceMessage(Error.INVALID_REDECLARE_IN_BASIC_TYPE, {}, info);
      then
        fail();
         
  end match;
end instBasicTypeAttributes;

protected function instBasicTypeAttribute
  input SCode.SubMod inSubMod;
  input SCodeEnv.AvlTree inAttributes;
  output DAE.Var outAttribute;
algorithm
  outAttribute := matchcontinue(inSubMod, inAttributes)
    local
      String ident, tspec;
      DAE.Type ty;
      Absyn.Exp bind_exp;
      DAE.Exp inst_exp;
      DAE.Binding binding;

    case (SCode.NAMEMOD(ident = ident, 
        A = SCode.MOD(subModLst = {}, binding = SOME((bind_exp, _)))), _)
      equation
        SCodeEnv.VAR(var = SCode.COMPONENT(typeSpec = Absyn.TPATH(path =
          Absyn.IDENT(tspec)))) = SCodeLookup.lookupInTree(ident, inAttributes);
        ty = instBasicTypeAttributeType(tspec);
        inst_exp = instExp(bind_exp);
        binding = DAE.EQBOUND(inst_exp, NONE(), DAE.C_UNKNOWN(), 
          DAE.BINDING_FROM_DEFAULT_VALUE());
      then
        DAE.TYPES_VAR(ident, DAE.dummyAttrParam, SCode.PUBLIC(), ty, binding, NONE());

    // TODO: Print error message for invalid attributes.
  end matchcontinue;
end instBasicTypeAttribute;
        
protected function instBasicTypeAttributeType
  input String inTypeName;
  output DAE.Type outType;
algorithm
  outType := match(inTypeName)
    case "$RealType" then DAE.T_REAL_DEFAULT;
    case "$IntegerType" then DAE.T_INTEGER_DEFAULT;
    case "$BooleanType" then DAE.T_BOOL_DEFAULT;
    case "$StringType" then DAE.T_STRING_DEFAULT;
    case "$EnumType" then DAE.T_ENUMERATION_DEFAULT;
    case "StateSelect" then DAE.T_ENUMERATION_DEFAULT;
  end match;
end instBasicTypeAttributeType;

protected function lookupElement
  "This functions might seem a little odd, why look up elements in the
   environment when we already have them? This is because they might have been
   redeclared, and redeclares are only applied to the environment and not the
   SCode itself. So we need to look them up in the environment to make sure we
   have the right elements."
  input SCode.Element inElement;
  input SCodeEnv.AvlTree inEnv;
  output SCode.Element outElement;
algorithm
  outElement := match(inElement, inEnv)
    local
      String name;
      SCode.Element el;

    case (SCode.COMPONENT(name = name), _)
      equation
        SCodeEnv.VAR(var = el) = SCodeEnv.avlTreeGet(inEnv, name);
      then
        el;

    // Only components need to be looked up. Extends are not allowed to be
    // redeclared, while classes are not instantiated by instElement.
    else inElement;
  end match;
end lookupElement;
        
protected function instElement
  input SCode.Element inVar;
  input Env inEnv;
  input Prefix inPrefix;
  output FlatProgram outProgram;
algorithm
  outProgram := match(inVar, inEnv, inPrefix)
    local
      String name,str;
      Absyn.Info info;
      Item item;
      Env env;
      Absyn.Path path;
      Absyn.ArrayDim ad;
      Prefix prefix;
      Integer var_count, dim_count;
      SCode.Mod mod;
      list<SCodeEnv.Redeclaration> redecls;
      SCodeEnv.ExtendsTable exts;
      FlatProgram prog;
      DAE.Dimensions dims;
      DAE.Type ty;

    // A component, look up it's type and instantiate that class.
    case (SCode.COMPONENT(name = name, attributes = SCode.ATTR(arrayDims = ad),
        typeSpec = Absyn.TPATH(path = path), modifications = mod, condition = NONE(), info = info), _, _)
      equation
        // Look up the class of the component.
        (item, path, env) = SCodeLookup.lookupClassName(path, inEnv, info);
        // Apply the redeclarations to the class.
        redecls = SCodeFlattenRedeclare.extractRedeclaresFromModifier(mod);
        (item, env) =
          SCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(redecls, item, env, inEnv);
        // Instantiate the class.
        prefix = (name, ad) :: inPrefix;
        (prog, ty) = instClassItem(item, mod, env, prefix);
        // Add the dimensions of the component to the type.
        ty = liftArrayType(ad, ty, inEnv);


        //print("Type of " +& name +& ": " +& Types.printTypeStr(ty) +& "\n");
      then
        prog;

    // An extends, look up the extended class and instantiate it.
    case (SCode.EXTENDS(baseClassPath = path, modifications = mod, info = info),
        SCodeEnv.FRAME(extendsTable = exts) :: _, _)
      equation
        // Look up the extended class.
        (item, path, env) = SCodeLookup.lookupClassName(path, inEnv, info);
        path = SCodeEnv.mergePathWithEnvPath(path, env);
        // Apply the redeclarations.
        redecls = SCodeFlattenRedeclare.lookupExtendsRedeclaresInTable(path, exts);
        (item, env) =
          SCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(redecls, item, env, inEnv);
        // Instantiate the class.
        (prog, ty) = instClassItem(item, mod, env, inPrefix);
      then
        prog;
        
    else EMPTY_FLAT_PROGRAM;
  end match;
end instElement;

protected function instDimension
  input Absyn.Subscript inSubscript;
  input Env inEnv;
  output DAE.Dimension outDimension;
algorithm
  outDimension := match(inSubscript, inEnv)
    local
      Absyn.Exp aexp;
      DAE.Exp dexp;

    case (Absyn.NOSUB(), _) then DAE.DIM_UNKNOWN();
    case (Absyn.SUBSCRIPT(subscript = aexp), _)
      equation
        //aexp = qualifyExp(aexp, inEnv);
        dexp = instExp(aexp);
      then
        DAE.DIM_EXP(dexp);

  end match;
end instDimension;

protected function qualifyExp
  input Absyn.Exp inExp;
  input Env inEnv;
  output Absyn.Exp outExp;
algorithm
  outExp := match(inExp, inEnv)
    local
      Absyn.ComponentRef cref;

    case (Absyn.CREF(cref), _)
      equation
        cref = SCodeLookup.lookupComponentRef(cref, inEnv, Absyn.dummyInfo);
      then
        Absyn.CREF(cref);

    else inExp;
  end match;
end qualifyExp;

protected function instExp
  input Absyn.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := match(inExp)
    local
      Integer ival;
      Real rval;
      String sval;
      Boolean bval;
      Absyn.ComponentRef acref;
      DAE.ComponentRef dcref;

    case Absyn.REAL(value = rval) then DAE.RCONST(rval);
    case Absyn.INTEGER(value = ival) then DAE.ICONST(ival);
    case Absyn.BOOL(value = bval) then DAE.BCONST(bval);
    case Absyn.STRING(value = sval) then DAE.SCONST(sval);
    case Absyn.CREF(componentRef = acref) 
      equation
        dcref = instCref(acref);
      then
        DAE.CREF(dcref, DAE.T_NONE_DEFAULT);

    else DAE.ICONST(0);
  end match;
end instExp;

protected function instCref
  input Absyn.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inCref)
    local
      String name;
      Absyn.ComponentRef cref;
      DAE.ComponentRef dcref;

    case Absyn.CREF_IDENT(name = name)
      then DAE.CREF_IDENT(name, DAE.T_NONE_DEFAULT, {});

    case Absyn.CREF_QUAL(name = name, componentRef = cref)
      equation
        dcref = instCref(cref);
      then
        DAE.CREF_QUAL(name, DAE.T_NONE_DEFAULT, {}, dcref);

  end match;
end instCref;

protected function printMod
  input SCode.Mod inMod;
  output String outString;
algorithm
  outString := match(inMod)
    local
      SCode.Final fp;
      SCode.Each ep;
      list<SCode.SubMod> submods;
      Option<tuple<Absyn.Exp, Boolean>> binding;
      SCode.Element el;
      String fstr, estr, submod_str, bind_str, el_str;

    case SCode.MOD(fp, ep, submods, binding, _)
      equation
        fstr = SCodeDump.finalStr(fp);
        estr = SCodeDump.eachStr(ep);
        submod_str = stringDelimitList(List.map(submods, printSubMod), ", ");
        bind_str = printBinding(binding);
      then
        "MOD(" +& fstr +& estr +& "{" +& submod_str +& "})" +& bind_str;

    case SCode.REDECL(fp, ep, el)
      equation
        fstr = SCodeDump.finalStr(fp);
        estr = SCodeDump.eachStr(ep);
        el_str = SCodeDump.unparseElementStr(el);
      then
        "REDECL(" +& fstr +& estr +& el_str +& ")";

    case SCode.NOMOD() then "NOMOD()";
  end match;
end printMod;

protected function printSubMod
  input SCode.SubMod inSubMod;
  output String outString;
algorithm
  outString := match(inSubMod)
    local
      SCode.Mod mod;
      list<SCode.Subscript> subs;
      String id, mod_str, subs_str;

    case SCode.NAMEMOD(ident = id, A = mod)
      equation
        mod_str = printMod(mod);
      then
        "NAMEMOD(" +& id +& " = " +& mod_str +& ")";

    case SCode.IDXMOD(subscriptLst = subs, an = mod)
      equation
        subs_str = Dump.printSubscriptsStr(subs);
        mod_str = printMod(mod);
      then
        "IDXMOD(" +& subs_str +& ", " +& mod_str +& ")";

  end match;
end printSubMod;

protected function printBinding
  input Option<tuple<Absyn.Exp, Boolean>> inBinding;
  output String outString;
algorithm
  outString := match(inBinding)
    local
      Absyn.Exp exp;

    case SOME((exp, _)) then " = " +& Dump.printExpStr(exp);
    else "";
  end match;
end printBinding;
        
protected function printFlatProgram
  input SCode.Ident inName;
  input FlatProgram inProgram;
protected
  list<SCode.Element> el;
  list<SCode.Equation> eq, ie;
  list<SCode.AlgorithmSection> al, ia;
algorithm
  FLAT_PROGRAM(el, eq, ie, al, ia) := inProgram;
  print("class " +& inName +& "\n");
  print("Components: " +& intString(listLength(el)) +& "\n");
  print("Equations:  " +& intString(listLength(eq)) +& "\n");
  print("Initial eq: " +& intString(listLength(ie)) +& "\n");
  print("Algorithms: " +& intString(listLength(al)) +& "\n");
  print("Initial al: " +& intString(listLength(ia)) +& "\n");
end printFlatProgram;

protected function printVar
  input Prefix inName;
  input SCode.Element inVar;
  input Absyn.Path inClassPath;
  input Item inClass;
algorithm
  _ := match(inName, inVar, inClassPath, inClass)
    local
      String name, cls;
      SCode.Element var;
      SCode.Prefixes pf;
      SCode.Flow fp;
      SCode.Stream sp;
      SCode.Variability vp;
      Absyn.Direction dp;
      SCode.Mod mod;
      Option<SCode.Comment> cmt;
      Option<Absyn.Exp> cond;
      Absyn.Info info;

    // Only print the variable if it doesn't contain any components, i.e. if
    // it's of basic type. This needs to be better checked, since some models
    // might be empty.
    case (_, SCode.COMPONENT(_, pf, 
          SCode.ATTR(_, fp, sp, vp, dp), _, mod, cmt, cond, info), _,
        SCodeEnv.CLASS(classType = SCodeEnv.BASIC_TYPE()))
      equation
        name = printPrefix(inName);
        var = SCode.COMPONENT(name, pf, SCode.ATTR({}, fp, sp, vp, dp), 
          Absyn.TPATH(inClassPath, NONE()), mod, cmt, cond, info);
        print("  " +& SCodeDump.unparseElementStr(var) +& ";\n");
      then
        ();

    else ();
  end match;
end printVar;

protected function printPrefix
  input Prefix inPrefix;
  output String outString;
algorithm
  outString := match(inPrefix)
    local
      String id;
      Absyn.ArrayDim dims;
      Prefix rest_pre;

    case {} then "";
    case {(id, dims)} then id +& Dump.printArraydimStr(dims);
    case ((id, dims) :: rest_pre)
      then printPrefix(rest_pre) +& "." +& id +& Dump.printArraydimStr(dims);

  end match;
end printPrefix;

protected function liftArrayType
  input Absyn.ArrayDim inDims;
  input DAE.Type inType;
  input Env inEnv;
  output DAE.Type outType;
algorithm
  outType := match(inDims, inType, inEnv)
    local
      DAE.Dimensions dims1, dims2;
      DAE.TypeSource src;
      DAE.Type ty;

    case ({}, _, _) then inType;
    case (_, DAE.T_ARRAY(ty, dims1, src), _)
      equation
        dims2 = List.map1(inDims, instDimension, inEnv);
        dims1 = listAppend(dims2, dims1);
      then
        DAE.T_ARRAY(ty, dims1, src);

    else
      equation
        dims2 = List.map1(inDims, instDimension, inEnv);
      then
        DAE.T_ARRAY(inType, dims2, DAE.emptyTypeSource);
  
  end match;
end liftArrayType;

end SCodeInst;
