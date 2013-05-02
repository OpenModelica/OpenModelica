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

encapsulated package NFSCodeInstShortcut
" file:  NFSCodeInstShortcut.mo
  package:     NFSCodeInstShortcut
  description: SCode instantiation

  RCS: $Id: NFSCodeInstShortcut.mo 13614 2012-10-25 00:03:02Z perost $

  Prototype SCode transformation to SCode without:
  - redeclares
  - modifiers
  enable with +d=scodeInstShortcut.
"

public import Absyn;
public import DAE;
public import NFInstTypes;
public import NFInstTypesOld;
public import SCode;
public import NFSCodeEnv;

protected import ClassInf;
protected import Debug;
protected import Error;
protected import Flags;
protected import NFInstUtil;
protected import List;
protected import NFSCodeCheck;
protected import SCodeDump;
protected import NFSCodeFlattenRedeclare;
protected import NFSCodeLookup;
protected import NFSCodeMod;
protected import Util;
protected import NFSCodeApplyRedeclare;
protected import NFSCodeAnalyseRedeclare;

public type Binding = NFInstTypesOld.Binding;
public type Class = SCode.Element;
public type Component = SCode.Element;
public type Dimension = NFInstTypes.Dimension;
public type Element = SCode.Element;
public type Env = NFSCodeEnv.Env;
public type Modifier = NFInstTypesOld.Modifier;
public type ParamType = NFInstTypes.ParamType;
public type Prefixes = NFInstTypes.Prefixes;
public type Prefix = NFInstTypes.Prefix;

public type InstInfo = list<Absyn.Path>;
public constant InstInfo emptyInstInfo = {};

protected type Item = NFSCodeEnv.Item;

public function translate
"translates a class to a class without redeclarations"
  input Absyn.Path inClassPath;
  input Env inEnv;
  input SCode.Program inProgram;
  output SCode.Program outSCode;
algorithm
  outSCode := matchcontinue(inClassPath, inEnv, inProgram)
    local
      list<Class> classes;
      String name;

    case (_, _, _)
      equation
  classes = NFSCodeApplyRedeclare.translate(inClassPath, inEnv, inProgram);
  showSCode(classes);
  // print("Done with NFSCodeInstShortcut ...\n");
      then
  classes;

    /*
    case (_, _, _)
      equation
  classes = mkClass(inClassPath, inEnv);
  showSCode(classes);
      then
  classes;*/

    else
      equation
  true = Flags.isSet(Flags.FAILTRACE);
  name = Absyn.pathString(inClassPath);
  Debug.traceln("NFSCodeInstShortcut.translate failed on " +& name);
      then
  fail();

  end matchcontinue;
end translate;

protected function showSCode
  input SCode.Program inProgram;
algorithm
  _ := matchcontinue(inProgram)
    local
      SCode.Program rest;
      SCode.Element e;

    case ({}) then ();

    case (e::rest)
      equation
  true = Flags.isSet(Flags.SHOW_SCODE);
  print("// " +& SCode.getElementName(e) +& "\n");
  print(SCodeDump.unparseElementStr(e));
  print(";\n\n");
  showSCode(rest);
      then
  ();

    else ();
  end matchcontinue;
end showSCode;

protected function mkClass
"translates a class to a class without redeclarations"
  input Absyn.Path inClassPath;
  input Env inEnv;
  output SCode.Program outSCode;
algorithm
  outSCode := matchcontinue(inClassPath, inEnv)
    local
      Item item;
      Absyn.Path path;
      Env env;
      String name;
      list<Class> classes;
      list<Element> const_el;

    case (_, _)
      equation
  name = Absyn.pathLastIdent(inClassPath);

  // ---------------- Instantiation ---------------
  // Look up the class to translate it in the environment.
  (item, path, env) = NFSCodeLookup.lookupClassName(inClassPath, inEnv, Absyn.dummyInfo);
  // Instantiate that class.
  (classes, _, _) =
        mkClassItem(
          item,
          NFInstTypesOld.NOMOD(),
          NFInstTypes.NO_PREFIXES(),
          env,
          NFInstTypes.EMPTY_PREFIX(SOME(path)),
          emptyInstInfo);
      then
  classes;

    else
      equation
  true = Flags.isSet(Flags.FAILTRACE);
  name = Absyn.pathString(inClassPath);
  Debug.traceln("NFSCodeInstShortcut.mkClass failed on " +& name);
      then
  fail();

  end matchcontinue;
end mkClass;

protected function isBasicType
  input String name;
  output Boolean isBasic;
algorithm
  isBasic := listMember(name, {"Real", "String", "Integer", "Boolean"});
end isBasicType;

protected function mkClassItem
  input Item inItem;
  input Modifier inMod;
  input Prefixes inPrefixes;
  input Env inEnv;
  input Prefix inPrefix;
  input InstInfo inInstInfo;
  output list<Class> outClasses;
  output Prefixes outPrefixes;
  output InstInfo outInstInfo;
algorithm
  (outClasses, outPrefixes, outInstInfo) :=
  matchcontinue(inItem, inMod, inPrefixes, inEnv, inPrefix, inInstInfo)
    local
      list<SCode.Element> el, classes;
      list<tuple<SCode.Element, Modifier>> mel;
      Absyn.TypeSpec dty;
      Option<Absyn.ArrayDim> ad;
      Item item;
      Env env, envDerived;
      Absyn.Info info;
      SCode.Mod smod;
      Modifier mod;
      NFSCodeEnv.AvlTree cls_and_vars;
      String name, tname, name1, name2;
      list<SCode.Equation> eq, ieq;
      list<SCode.AlgorithmSection> alg, ialg;
      DAE.Type ty;
      Absyn.ArrayDim dims;
      list<DAE.Var> vars;
      list<SCode.Enum> enums;
      Absyn.Path path;
      list<Element> elems;
      Boolean cse, ice;
      SCode.Element scls, scls2, cls;
      SCode.ClassDef cdef;
      Integer dim_count;
      list<NFSCodeEnv.Extends> exts;
      SCode.Restriction res;
      ClassInf.State state;
      SCode.Attributes attr;
      Prefixes prefs;
      Prefix prefix;
      SCode.Prefixes sprefs;
      SCode.Encapsulated ep;
      SCode.Partial pp;
      list<SCode.ConstraintSection> cs;
      list<Absyn.NamedArg> clsattr;
      Option<SCode.ExternalDecl> ed;
      list<SCode.Annotation> al;
      InstInfo ii;
      Boolean isBasic, isChain;
      list<NFSCodeEnv.Redeclaration> redeclares;
      SCode.Comment cmt;


    case (NFSCodeEnv.CLASS(
      cls = scls as SCode.CLASS(name = name),
      env = env,
      classType = NFSCodeEnv.BASIC_TYPE()), _, _, _, _, _)
      equation
  // we should apply inMod here!
  // classes = Util.if_(isBasicType(name), {}, {scls});
  classes = {scls};
      then
  (classes, NFInstTypes.NO_PREFIXES(), inInstInfo);

    case (NFSCodeEnv.CLASS(cls = scls as
      SCode.CLASS(classDef =
        SCode.ENUMERATION(enumLst = enums), info = info)), _, _, _, _, _)
      equation
  // we should apply inMod here!
      then
  ({scls}, NFInstTypes.NO_PREFIXES(), inInstInfo);

    // A class with parts, instantiate all elements in it.
    case (NFSCodeEnv.CLASS(
      cls = SCode.CLASS(
              name, sprefs, ep, pp, res,
              SCode.PARTS(el, eq, ieq, alg, ialg, cs, clsattr, ed), cmt, info),
  env = {NFSCodeEnv.FRAME(clsAndVars = cls_and_vars)}), _, _, _, _, _)
      equation
  // Enter the class scope and look up all class elements.
  env = NFSCodeEnv.mergeItemEnv(inItem, inEnv);

  // Apply modifications to the elements and instantiate them.
  mel = NFSCodeMod.applyModifications(inMod, el, inPrefix, env);
  exts = NFSCodeEnv.getEnvExtendsFromTable(env);
  (elems, ii) = mkElementList(mel, inPrefixes, exts, env, inPrefix, {}, inInstInfo);

  sprefs = SCode.prefixesSetRedeclare(sprefs, SCode.NOT_REDECLARE());
  sprefs = SCode.prefixesSetReplaceable(sprefs, SCode.NOT_REPLACEABLE());

  elems = appendUnion(elems, elems);

  scls = SCode.CLASS(
         name, sprefs, ep, pp, res,
         SCode.PARTS(elems, eq, ieq, alg, ialg, cs, clsattr, ed),
         cmt, info);
      then
  ({scls}, NFInstTypes.NO_PREFIXES(), ii);

    // A derived class from basic type.
    case (NFSCodeEnv.CLASS(cls = scls as
      SCode.CLASS(
              name, sprefs, ep, pp, res,
              SCode.DERIVED(dty, smod, attr), _, info)),
    _, _, _, _, _)
      equation
  // Look up the inherited class.
  (item as NFSCodeEnv.CLASS(classType = NFSCodeEnv.BASIC_TYPE()), _, env) =
    NFSCodeLookup.lookupTypeSpec(dty, inEnv, info);

  prefs = inPrefixes;
  classes = {scls};
  ii = inInstInfo;
      then
  (classes, prefs, ii);

    // A derived class, look up the inherited class and instantiate it.
    case (NFSCodeEnv.CLASS(cls = scls as
      SCode.CLASS(
              name, sprefs, ep, pp, res,
              SCode.DERIVED(dty as Absyn.TPATH(path, ad), smod, attr), cmt, info),
              env = envDerived),
    _, _, _, _, _)
      equation
  // Look up the inherited class.
  (item, _, env) = NFSCodeLookup.lookupTypeSpec(dty, inEnv, info);
  path = Absyn.typeSpecPath(dty);

  (item, env, _) = NFSCodeEnv.resolveRedeclaredItem(item, env);

  // Merge the modifiers and instantiate the inherited class.
  dims = Absyn.typeSpecDimensions(dty);
  dim_count = listLength(dims);
  mod = NFSCodeMod.translateMod(smod, "", dim_count, inPrefix, inEnv);
  mod = NFSCodeMod.mergeMod(inMod, mod);

  // Apply the redeclarations from the derived environment!!!!
  redeclares = listAppend(
    NFSCodeEnv.getDerivedClassRedeclares(name, dty, envDerived),
    NFSCodeFlattenRedeclare.extractRedeclaresFromModifier(smod));
  (item, env, _) = NFSCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(redeclares, item, env, inEnv, inPrefix);

  (classes, prefs, ii) = mkClassItem(item, mod, inPrefixes, env, inPrefix, inInstInfo);

  // Merge the attributes of this class with the prefixes of the inherited
  // class.
  prefs = NFInstUtil.mergePrefixesWithDerivedClass(path, scls, prefs);

  tname = Absyn.pathStringReplaceDot(path, "$");

  cls::classes = classes;
  name2 = SCode.elementName(cls);
  isChain = boolAnd(stringEq(name, tname), stringEq(name, name2));
  tname = Util.if_(isChain, tname +& "_chain", tname);

  tname = "'" +& tname +& "_" +& NFSCodeEnv.getEnvName(inEnv) +& "'";

  sprefs = SCode.prefixesSetRedeclare(sprefs, SCode.NOT_REDECLARE());
  sprefs = SCode.prefixesSetReplaceable(sprefs, SCode.NOT_REPLACEABLE());

  scls  = SCode.CLASS(
            name, sprefs, ep, pp, res,
            SCode.DERIVED(Absyn.TPATH(Absyn.IDENT(tname), ad), smod, attr), cmt, info);

  cls = SCode.setClassName(tname, cls);
  classes = cls::classes;

  classes = listAppend({scls}, classes);
      then
  (classes, prefs, ii);

    case (NFSCodeEnv.CLASS(cls = scls, classType = NFSCodeEnv.CLASS_EXTENDS(), env = env),
    _, _, _, _, _)
      equation
  (classes, ii) = mkClassExtends(scls, inMod, inPrefixes, env, inEnv, inPrefix, inInstInfo);
      then
  (classes, NFInstTypes.NO_PREFIXES(), ii);

    case (NFSCodeEnv.REDECLARED_ITEM(item = item, declaredEnv = env), _, _, _, _, _)
      equation
  (classes, prefs, ii) = mkClassItem(item, inMod, inPrefixes, env, inPrefix, inInstInfo);
      then
  (classes, prefs, ii);

    else
      equation
  true = Flags.isSet(Flags.FAILTRACE);
  Debug.traceln("NFSCodeInstShortcut.instClassItem failed on unknown class.\n");
      then
  fail();

  end matchcontinue;
end mkClassItem;

protected function mkClassExtends
  input SCode.Element inClassExtends;
  input Modifier inMod;
  input Prefixes inPrefixes;
  input Env inClassEnv;
  input Env inEnv;
  input Prefix inPrefix;
  input InstInfo inInstInfo;
  output list<Class> outClasses;
  output InstInfo outInstInfo;
algorithm
  (outClasses, outInstInfo) :=
  matchcontinue(inClassExtends, inMod, inPrefixes, inClassEnv, inEnv, inPrefix, inInstInfo)
    local
      SCode.ClassDef cdef;
      SCode.Mod mod;
      SCode.Element scls, ext;
      Absyn.Path bc_path;
      Absyn.Info info;
      String name;
      Item item;
      Env base_env, ext_env;
      Class base_cls, ext_cls, comp_cls;
      list<Class> classes;
      DAE.Type base_ty, ext_ty, comp_ty;
      InstInfo ii;

    case (SCode.CLASS(classDef = SCode.CLASS_EXTENDS(modifications = mod,
      composition = cdef)), _, _, _, _, _, _)
      equation
  (bc_path, info) = getClassExtendsBaseClass(inClassEnv);
  ext = SCode.EXTENDS(bc_path, SCode.PUBLIC(), mod, NONE(), info);
  cdef = SCode.addElementToCompositeClassDef(ext, cdef);
  scls = SCode.setElementClassDefinition(cdef, inClassExtends);
  item = NFSCodeEnv.CLASS(scls, inClassEnv, NFSCodeEnv.CLASS_EXTENDS());
  (classes, _, ii) = mkClassItem(item, inMod, inPrefixes, inEnv, inPrefix, inInstInfo);
      then
  (classes, ii);

    else
      equation
  true = Flags.isSet(Flags.FAILTRACE);
  name = SCode.elementName(inClassExtends);
  Debug.traceln("NFSCodeInstShortcut.instClassExtends failed on " +& name);
      then
  fail();

  end matchcontinue;
end mkClassExtends;

protected function getClassExtendsBaseClass
  input Env inClassEnv;
  output Absyn.Path outPath;
  output Absyn.Info outInfo;
algorithm
  (outPath, outInfo) := matchcontinue(inClassEnv)
    local
      Absyn.Path bc;
      Absyn.Info info;
      String name;

    case (NFSCodeEnv.FRAME(extendsTable = NFSCodeEnv.EXTENDS_TABLE(
      baseClasses = NFSCodeEnv.EXTENDS(baseClass = bc, info = info) :: _)) :: _)
      then (bc, info);

    else
      equation
  true = Flags.isSet(Flags.FAILTRACE);
  name = NFSCodeEnv.getEnvName(inClassEnv);
  Debug.traceln("NFSCodeInstShortcut.getClassExtendsBaseClass failed on " +& name);
      then
  fail();

  end matchcontinue;
end getClassExtendsBaseClass;

protected function mkElementList
"Helper function to mkClassItem."
  input list<tuple<SCode.Element, Modifier>> inElements;
  input Prefixes inPrefixes;
  input list<NFSCodeEnv.Extends> inExtends;
  input Env inEnv;
  input Prefix inPrefix;
  input list<Element> inAccumEl;
  input InstInfo inInstInfo;
  output list<Element> outElements;
  output InstInfo outInstInfo;
algorithm
  (outElements, outInstInfo) :=
  match(inElements, inPrefixes, inExtends, inEnv, inPrefix, inAccumEl, inInstInfo)
    local
      tuple<SCode.Element, Modifier> elem;
      list<tuple<SCode.Element, Modifier>> rest_el;
      Boolean cse;
      list<Element> accum_el;
      list<NFSCodeEnv.Extends> exts;
      InstInfo ii;
      Env env;
      Modifier orig_mod;

    case (elem :: rest_el, _, exts, _, _, accum_el, _)
      equation
  (elem, orig_mod, env, _) = NFSCodeAnalyseRedeclare.resolveRedeclaredElement(elem, inEnv, inPrefix);
  (accum_el, exts, ii) = mkElement_dispatch(elem, orig_mod, inPrefixes, exts, env, inPrefix, accum_el, inInstInfo);
  (accum_el, ii) = mkElementList(rest_el, inPrefixes, exts, inEnv, inPrefix, accum_el, ii);
      then
  (accum_el, ii);

    case ({}, _, {}, _, _, _, _) then (inAccumEl, inInstInfo);

    // mkElementList takes a list of Extends, which contains the extends
    // information from the environment. We should have one Extends element for
    // each extends clause, so if we have any left when we've run out of
    // elements something has gone very wrong.
    case ({}, _, _ :: _, _, _, _, _)
      equation
  Error.addMessage(Error.INTERNAL_ERROR, {"NFSCodeInstShortcut.mkElementList has extends left!."});
      then
  fail();

  end match;
end mkElementList;

protected function mkElement_dispatch
"Helper function to mkElementList.
 Dispatches the given element to the correct function for transformation."
  input tuple<SCode.Element, Modifier> inElement;
  input Modifier inOriginalMod;
  input Prefixes inPrefixes;
  input list<NFSCodeEnv.Extends> inExtends;
  input Env inEnv;
  input Prefix inPrefix;
  input list<Element> inAccumEl;
  input InstInfo inInstInfo;
  output list<Element> outElements;
  output list<NFSCodeEnv.Extends> outExtends;
  output InstInfo outInstInfo;
algorithm
  (outElements, outExtends, outInstInfo) :=
  matchcontinue(inElement, inOriginalMod, inPrefixes, inExtends, inEnv, inPrefix, inAccumEl, inInstInfo)
    local
      SCode.Element elem;
      Modifier mod;
      list<Element> res;
      Option<Element> ores;
      Boolean cse;
      list<Element> accum_el;
      list<NFSCodeEnv.Redeclaration> redecls;
      list<NFSCodeEnv.Extends> rest_exts;
      String name;
      Prefix prefix;
      Env env;
      Class cls;
      Item item;
      Absyn.Path fullName;
      InstInfo ii;

    // A component
    case ((elem as SCode.COMPONENT(name = _), mod), _, _, _, _, _, _, _)
      equation
  (res, ii) = mkElement(elem, mod, inOriginalMod, inPrefixes, inEnv, inPrefix, inInstInfo);
  accum_el = listAppend(inAccumEl, res);
      then
  (accum_el, inExtends, ii);

    // An extends clause. Transform it it together with the next Extends element from the environment.
    case ((elem as SCode.EXTENDS(baseClassPath = _), mod), _, _,
  NFSCodeEnv.EXTENDS(redeclareModifiers = redecls) :: rest_exts, _, _, _, _)
      equation
  (res, ii) = mkExtends(elem, mod, inPrefixes, redecls, inEnv, inPrefix, inInstInfo);
  accum_el = listAppend(inAccumEl, res);
      then
  (accum_el, rest_exts, ii);

    // functions, packages, classes
    case ((elem as SCode.CLASS(name = name),mod), _, _, _, _, _, _, _)
      equation
  prefix = NFInstUtil.addPrefix(name, {}, inPrefix);
  fullName = NFSCodeEnv.mergePathWithEnvPath(Absyn.IDENT(name), inEnv);
  false = listMember(fullName, inInstInfo);
  // add it
  ii = fullName::inInstInfo;
  (item, env) = NFSCodeLookup.lookupInClass(name, inEnv);
  (res, _, ii) = mkClassItem(item, mod, NFInstTypes.NO_PREFIXES(), env, prefix, ii);
  ii = inInstInfo;
  accum_el = listAppend(inAccumEl, res);
      then
  (accum_el, inExtends, ii);

    // We should have one Extends element for each extends clause in the class.
    // If we get an extends clause but don't have any Extends elements left,
    // something has gone very wrong.
    case ((SCode.EXTENDS(baseClassPath = _), _), _, _, {}, _, _, _, _)
      equation
  Error.addMessage(Error.INTERNAL_ERROR, {"NFSCodeInstShortcut.mkElement_dispatch ran out of extends!."});
      then
  fail();

    /*/ debugging case
    case (_, _, _, _, _, _, _, _)
      equation
  true = Flags.isSet(Flags.FAILTRACE);
  (elem, _) = inElement;
  print("Ignoring: " +& SCodeDump.unparseElementStr(elem) +& "\n");
  (accum_el, rest_exts, ii) = mkElement_dispatch(inElement, inPrefixes, inExtends, inEnv, inPrefix, inAccumEl, inInstInfo);
      then
  (accum_el, rest_exts, ii); //(inAccumEl, inExtends, inInstInfo);*/

    // Ignore any other kind of elements (class definitions, etc.).
    else
      equation
  (elem, _) = inElement;
  // print("Ignoring: " +& SCodeDump.unparseElementStr(elem) +& "\n");
      then
  (inAccumEl, inExtends, inInstInfo);
  end matchcontinue;
end mkElement_dispatch;

protected function mkElement
  input SCode.Element inElement;
  input Modifier inClassMod;
  input Modifier inOriginalMod;
  input Prefixes inPrefixes;
  input Env inEnv;
  input Prefix inPrefix;
  input InstInfo inInstInfo;
  output list<Element> outElements;
  output InstInfo outInstInfo;
algorithm
  (outElements, outInstInfo) :=
  match(inElement, inClassMod, inOriginalMod, inPrefixes, inEnv, inPrefix, inInstInfo)
    local
      Absyn.ArrayDim ad;
      Absyn.Info info;
      Absyn.Path path, tpath, newpath;
      Component comp;
      DAE.Type ty;
      Env env;
      Item item;
      list<NFSCodeEnv.Redeclaration> redecls;
      Binding binding;
      Prefix prefix;
      SCode.Mod smod;
      Modifier mod, cmod;
      String name, tname, newname;
      list<DAE.Dimension> dims;
      array<Dimension> dim_arr;
      Class cls;
      list<Class> classes;
      Prefixes prefs, cls_prefs;
      Integer dim_count;
      Absyn.Exp cond_exp;
      DAE.Exp inst_exp;
      ParamType pty;
      SCode.Prefixes sprefixes;
      SCode.Attributes attributes;
      Absyn.TypeSpec typeSpec;
      SCode.Comment cmt;
      Option<Absyn.Exp> condition;
      InstInfo ii;
      Boolean sameEnv, isBasic, isCompInsideType;
      Option<Absyn.ArrayDim> arrayDimOpt;

    // A component, look up it's type and instantiate that class.
    case (SCode.COMPONENT(
      name,
      sprefixes,
      attributes as SCode.ATTR(arrayDims = ad),
      typeSpec as Absyn.TPATH(tpath, arrayDimOpt),
      smod,
      cmt,
      condition,
      info), _, _, _, _, _, _)
      equation
  // Look up the class of the component.
  (item, tpath, env) = NFSCodeLookup.lookupClassName(tpath, inEnv, info);
  (item, env, _) = NFSCodeEnv.resolveRedeclaredItem(item, env);
  // NFSCodeCheck.checkPartialInstance(item, info);

  // the class is defined in the same env as the component
  sameEnv = stringEq(NFSCodeEnv.getEnvName(inEnv), NFSCodeEnv.getEnvName(env));

  // Instantiate array dimensions and add them to the prefix.
  //(dims,functions) = instDimensions(ad, inEnv, inPrefix, info, functions);
  //prefix = NFInstUtil.addPrefix(name, dims, inPrefix);
  prefix = NFInstUtil.addPrefix(name, {}, inPrefix);

  // Check that it's legal to instantiate the class.
  NFSCodeCheck.checkInstanceRestriction(item, prefix, info);

  // Merge the class modifications with this element's modifications.
  dim_count = listLength(ad);
  mod = NFSCodeMod.translateMod(smod, name, dim_count, inPrefix, inEnv);
  mod = NFSCodeMod.mergeMod(inOriginalMod, mod);
  cmod = NFSCodeMod.propagateMod(inClassMod, dim_count);
  mod = NFSCodeMod.mergeMod(cmod, mod);

  // Merge prefixes from the instance hierarchy.
  //path = NFInstUtil.prefixPath(Absyn.IDENT(name), inPrefix);
  //prefs = NFInstUtil.mergePrefixesFromComponent(path, inElement, inPrefixes);
  //pty = NFInstUtil.paramTypeFromPrefixes(prefs);
  prefs = inPrefixes;

  // Apply redeclarations to the class definition and instantiate it.
  redecls = NFSCodeFlattenRedeclare.extractRedeclaresFromModifier(smod);
  (item, env, _) = NFSCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(
    redecls, item, env, inEnv, inPrefix);
  (classes, cls_prefs, ii) = mkClassItem(item, mod, prefs, env, prefix, inInstInfo);
  //prefs = NFInstUtil.mergePrefixes(prefs, cls_prefs, path, "variable");

  // Add dimensions from the class type.
  //(dims, dim_count) = addDimensionsFromType(dims, ty);
  //ty = NFInstUtil.arrayElementType(ty);
  //dim_arr = NFInstUtil.makeDimensionArray(dims);

  // Instantiate the binding.
  mod = NFSCodeMod.propagateMod(mod, dim_count);
  //binding = NFSCodeMod.getModifierBinding(mod);
  //(binding,functions) = instBinding(binding, dim_count, functions);

  // Create the component and add it to the program.
  smod = NFSCodeMod.removeRedeclaresFromMod(smod);
  // set as no redeclare
  sprefixes = SCode.prefixesSetRedeclare(sprefixes, SCode.NOT_REDECLARE());

  tname = Absyn.pathStringReplaceDot(tpath, "$");
  isBasic = isBasicType(tname);
  tname = Util.if_(isBasic, tname, "'" +& tname +& "$" +& name +& "'");
  typeSpec = Absyn.TPATH(Absyn.IDENT(tname), NONE());

  cls::classes = classes;
  cls = SCode.setClassName(tname, cls);
  classes = Util.if_(isBasic, classes, cls::classes);

  comp = SCode.COMPONENT(
      name,
      sprefixes,
      attributes,
      typeSpec,
      smod,
      cmt,
      condition,
      info);

  classes = listAppend(classes, {comp});
      then
  (classes, ii);

    else
      equation
  true = Flags.isSet(Flags.FAILTRACE);
  Debug.traceln("NFSCodeInstShortcut.instElement failed on unknown element.\n");
      then
  fail();

  end match;
end mkElement;


protected function isInsideType
"detects things like the types in equalityConstraint function
 i.e. recursive types."
  input Env inCompEnv;
  input Absyn.Path inTypePath;
  input Env inTypeEnv;
  input Absyn.Info inInfo;
  output Boolean componentIsInsideType;
algorithm
  componentIsInsideType := matchcontinue(inCompEnv, inTypePath, inTypeEnv, inInfo)
    local
      Absyn.Path tpath;
    case (_, _, _, _)
      equation
  tpath = NFSCodeLookup.qualifyPath(inTypePath, inTypeEnv, inInfo, NONE());
      then
  Absyn.pathPrefixOf(tpath, NFSCodeEnv.getEnvPath(inCompEnv));
    case (_, _, _, _)
      then
  Absyn.pathPrefixOf(inTypePath, NFSCodeEnv.getEnvPath(inCompEnv));
    else false;
  end matchcontinue;
end  isInsideType;

protected function appendUnion
  input SCode.Program inProg1;
  input SCode.Program inProg2;
  output SCode.Program outProg;
algorithm
  outProg := List.unionOnTrue(inProg1, inProg2, SCode.elementEqual);
end appendUnion;

protected function mkExtends
  input SCode.Element inExtends;
  input Modifier inClassMod;
  input Prefixes inPrefixes;
  input list<NFSCodeEnv.Redeclaration> inRedeclares;
  input Env inEnv;
  input Prefix inPrefix;
  input InstInfo inInstInfo;
  output list<Element> outElements;
  output InstInfo outInstInfo;
algorithm
  (outElements, outInstInfo) :=
  match(inExtends, inClassMod, inPrefixes, inRedeclares, inEnv, inPrefix, inInstInfo)
    local
      Absyn.Path path;
      SCode.Mod smod;
      Absyn.Info info;
      Item item;
      Env env;
      Modifier mod;
      Class cls;
      list<Class> classes;
      DAE.Type ty;
      Boolean cse;
      Prefixes prefs;
      String name, tname;
      SCode.Visibility visibility;
      Option<SCode.Annotation> ann;
      InstInfo ii;
      Boolean isBasic;

    case (SCode.EXTENDS(path, visibility, smod, ann, info),
  _, _, _, _, _, _)
      equation
  // Look up the base class in the environment.
  (item, path, env) = NFSCodeLookup.lookupBaseClassName(path, inEnv, info);
  path = NFSCodeEnv.mergePathWithEnvPath(path, env);
  NFSCodeAnalyseRedeclare.checkRecursiveExtends(path, inEnv, info);

  // Apply the redeclarations.
  (item, env, _) = NFSCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(
    inRedeclares, item, env, inEnv, inPrefix);

  // Instantiate the class.
  prefs = NFInstUtil.mergePrefixesFromExtends(inExtends, inPrefixes);
  mod = NFSCodeMod.translateMod(smod, "", 0, inPrefix, inEnv);
  mod = NFSCodeMod.mergeMod(inClassMod, mod);

  (classes, _, ii) =
    mkClassItem(item, mod, prefs, env, inPrefix, inInstInfo);

  smod = NFSCodeMod.removeRedeclaresFromMod(smod);

  name = Absyn.pathStringReplaceDot(path, "$");
  isBasic = isBasicType(name);
  name = Util.if_(
          isBasic,
          name,
          "'" +& name +& "$ext_" +& NFSCodeEnv.getEnvName(inEnv) +& "'");

  cls::classes = classes;
  cls = SCode.setClassName(name, cls);
  classes = cls::classes;

  cls = SCode.EXTENDS(Absyn.IDENT(name), visibility, smod, ann, info);
  classes = Util.if_(isBasic, {cls}, listAppend(classes, {cls}));
      then
  (classes, ii);

    else
      equation
  true = Flags.isSet(Flags.FAILTRACE);
  Debug.traceln("NFSCodeInstShortcut.instExtends failed on unknown element.\n");
      then
  fail();

  end match;
end mkExtends;

end NFSCodeInstShortcut;
