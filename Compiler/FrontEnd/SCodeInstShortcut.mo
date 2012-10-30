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

encapsulated package SCodeInstShortcut
" file:        SCodeInstShortcut.mo
  package:     SCodeInstShortcut
  description: SCode instantiation

  RCS: $Id: SCodeInstShortcut.mo 13614 2012-10-25 00:03:02Z perost $

  Prototype SCode transformation to SCode without:
  - redeclares 
  - modifiers
  enable with +d=scodeInstShortcut.
"

public import Absyn;
public import DAE;
public import InstTypes;
public import SCode;
public import SCodeEnv;

protected import ClassInf;
protected import Debug;
protected import Error;
protected import Flags;
protected import InstUtil;
protected import List;
protected import SCodeCheck;
protected import SCodeDump;
protected import SCodeFlattenRedeclare;
protected import SCodeLookup;
protected import SCodeMod;
protected import Util;


public type Binding = InstTypes.Binding;
public type Class = SCode.Element;
public type Component = SCode.Element;
public type Dimension = InstTypes.Dimension;
public type Element = SCode.Element;
public type Env = SCodeEnv.Env;
public type Modifier = InstTypes.Modifier;
public type ParamType = InstTypes.ParamType;
public type Prefixes = InstTypes.Prefixes;
public type Prefix = InstTypes.Prefix;

public type InstInfo = list<Absyn.Path>;
public constant InstInfo emptyInstInfo = {};

protected type Item = SCodeEnv.Item;

public function translate
  "Flattens a class."
  input Absyn.Path inClassPath;
  input Env inEnv;
  output SCode.Program outSCode;
algorithm
  outSCode := matchcontinue(inClassPath, inEnv)
    local 
      list<Class> classes;
      String name;
    
    case (_, _)
      equation
        classes = mkClass(inClassPath, inEnv);
        showSCode(classes);
      then
        classes;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        name = Absyn.pathString(inClassPath);
        Debug.traceln("SCodeInstShortcut.translate failed on " +& name);
      then
        fail();

  end matchcontinue;
end translate;

protected function showSCode
  input SCode.Program inProgram;
algorithm
  _ := matchcontinue(inProgram)
    case (_)
      equation
        true = Flags.isSet(Flags.SHOW_SCODE);
        print(SCodeDump.programStr(inProgram));
      then
        ();
    else ();
  end matchcontinue;
end showSCode;

protected function mkClass
  "Flattens a class."
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
        // Look up the class to instantiate in the environment.
        (item, path, env) = SCodeLookup.lookupClassName(inClassPath, inEnv, Absyn.dummyInfo);
        // Instantiate that class.
        (classes, _, _) = 
              mkClassItem(
                item, 
                InstTypes.NOMOD(),
                InstTypes.NO_PREFIXES(), 
                env, 
                InstTypes.EMPTY_PREFIX(SOME(path)), 
                emptyInstInfo);
      then
        classes;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        name = Absyn.pathString(inClassPath);
        Debug.traceln("SCodeInstShortcut.mkClass failed on " +& name);
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
      Env env;
      Absyn.Info info;
      SCode.Mod smod;
      Modifier mod;
      SCodeEnv.AvlTree cls_and_vars;
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
      list<SCodeEnv.Extends> exts;
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
      Option<SCode.Comment> cmt;
      InstInfo ii;
      Boolean isBasic, isChain;

    case (SCodeEnv.CLASS(
            cls = scls as SCode.CLASS(name = name), 
            env = env, 
            classType = SCodeEnv.BASIC_TYPE()), _, _, _, _, _) 
      equation
        // we should apply inMod here!
        // classes = Util.if_(isBasicType(name), {}, {scls});
        classes = {scls};   
      then 
        (classes, InstTypes.NO_PREFIXES(), inInstInfo);

    case (SCodeEnv.CLASS(cls = scls as 
            SCode.CLASS(classDef =
              SCode.ENUMERATION(enumLst = enums), info = info)), _, _, _, _, _)
      equation
        // we should apply inMod here!
      then
        ({scls}, InstTypes.NO_PREFIXES(), inInstInfo);
        
    // A class with parts, instantiate all elements in it.
    case (SCodeEnv.CLASS(
            cls = SCode.CLASS(
                    name, sprefs, ep, pp, res, 
                    SCode.PARTS(el, eq, ieq, alg, ialg, cs, clsattr, ed, al, cmt), info),
        env = {SCodeEnv.FRAME(clsAndVars = cls_and_vars)}), _, _, _, _, _)
      equation
        // Enter the class scope and look up all class elements.
        env = SCodeEnv.mergeItemEnv(inItem, inEnv);
        
        // Apply modifications to the elements and instantiate them.
        mel = SCodeMod.applyModifications(inMod, el, inPrefix, env);
        exts = SCodeEnv.getEnvExtendsFromTable(env);
        (elems, ii) = mkElementList(mel, inPrefixes, exts, env, inPrefix, inInstInfo);

        sprefs = SCode.prefixesSetRedeclare(sprefs, SCode.NOT_REDECLARE());
        sprefs = SCode.prefixesSetReplaceable(sprefs, SCode.NOT_REPLACEABLE());

        elems = appendUnion(elems, elems);
        
        scls = SCode.CLASS(
               name, sprefs, ep, pp, res,
               SCode.PARTS(elems, eq, ieq, alg, ialg, cs, clsattr, ed, al, cmt),
               info);
      then
        ({scls}, InstTypes.NO_PREFIXES(), ii);

    // A derived class from basic type.
    case (SCodeEnv.CLASS(cls = scls as  
            SCode.CLASS(
                    name, sprefs, ep, pp, res,
                    SCode.DERIVED(dty, smod, attr, cmt), info)), 
          _, _, _, _, _)
      equation
        // Look up the inherited class.
        (item as SCodeEnv.CLASS(classType = SCodeEnv.BASIC_TYPE()), env) =
          SCodeLookup.lookupTypeSpec(dty, inEnv, info);
        
        prefs = inPrefixes;
        classes = {scls};
        ii = inInstInfo;
      then
        (classes, prefs, ii);
        
    // A derived class, look up the inherited class and instantiate it.
    case (SCodeEnv.CLASS(cls = scls as  
            SCode.CLASS(
                    name, sprefs, ep, pp, res,
                    SCode.DERIVED(dty as Absyn.TPATH(path, ad), smod, attr, cmt), info)), 
          _, _, _, _, _)
      equation
        // Look up the inherited class.
        (item, env) = SCodeLookup.lookupTypeSpec(dty, inEnv, info);
        path = Absyn.typeSpecPath(dty);

        // Merge the modifiers and instantiate the inherited class.
        dims = Absyn.typeSpecDimensions(dty);
        dim_count = listLength(dims);
        mod = SCodeMod.translateMod(smod, "", dim_count, inPrefix, inEnv);
        mod = SCodeMod.mergeMod(inMod, mod);
        (classes, prefs, ii) = mkClassItem(item, mod, inPrefixes, env, inPrefix, inInstInfo);

        // Merge the attributes of this class with the prefixes of the inherited
        // class.
        prefs = InstUtil.mergePrefixesWithDerivedClass(path, scls, prefs);

        tname = Absyn.pathStringReplaceDot(path, "$");
        
        cls::classes = classes;
        name2 = SCode.elementName(cls);        
        isChain = boolAnd(stringEq(name, tname), stringEq(name, name2));
        tname = Util.if_(isChain, tname +& "_chain", tname);
        
        tname = "'" +& tname +& "_" +& SCodeEnv.getEnvName(inEnv) +& "'";
        
        sprefs = SCode.prefixesSetRedeclare(sprefs, SCode.NOT_REDECLARE());
        sprefs = SCode.prefixesSetReplaceable(sprefs, SCode.NOT_REPLACEABLE());
        
        scls  = SCode.CLASS(
                  name, sprefs, ep, pp, res,
                  SCode.DERIVED(Absyn.TPATH(Absyn.IDENT(tname), ad), smod, attr, cmt), info);        
        
        cls = SCode.setClassName(tname, cls);        
        classes = cls::classes; 
        
        classes = listAppend({scls}, classes);
      then
        (classes, prefs, ii);

    case (SCodeEnv.CLASS(cls = scls, classType = SCodeEnv.CLASS_EXTENDS(), env = env),
          _, _, _, _, _)
      equation
        (classes, ii) = mkClassExtends(scls, inMod, inPrefixes, env, inEnv, inPrefix, inInstInfo);
      then
        (classes, InstTypes.NO_PREFIXES(), ii);

    case (SCodeEnv.REDECLARED_ITEM(item = item, declaredEnv = env), _, _, _, _, _)
      equation
        (classes, prefs, ii) = mkClassItem(item, inMod, inPrefixes, env, inPrefix, inInstInfo);
      then
        (classes, prefs, ii);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("SCodeInstShortcut.instClassItem failed on unknown class.\n");
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
        item = SCodeEnv.CLASS(scls, inClassEnv, SCodeEnv.CLASS_EXTENDS());
        (classes, _, ii) = mkClassItem(item, inMod, inPrefixes, inEnv, inPrefix, inInstInfo);
      then
        (classes, ii);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        name = SCode.elementName(inClassExtends);
        Debug.traceln("SCodeInstShortcut.instClassExtends failed on " +& name);
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

    case (SCodeEnv.FRAME(extendsTable = SCodeEnv.EXTENDS_TABLE(
        baseClasses = SCodeEnv.EXTENDS(baseClass = bc, info = info) :: _)) :: _)
      then (bc, info);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        name = SCodeEnv.getEnvName(inClassEnv);
        Debug.traceln("SCodeInstShortcut.getClassExtendsBaseClass failed on " +& name);
      then
        fail();

  end matchcontinue;
end getClassExtendsBaseClass;
        
protected function mkElementList
  "Instantiates a list of elements."
  input list<tuple<SCode.Element, Modifier>> inElements;
  input Prefixes inPrefixes;
  input list<SCodeEnv.Extends> inExtends;
  input Env inEnv;
  input Prefix inPrefix;
  input InstInfo inInstInfo;
  output list<Element> outElements;
  output InstInfo outInstInfo;
algorithm
  (outElements, outInstInfo) := mkElementList2(inElements, inPrefixes, inExtends, inEnv, inPrefix, {}, inInstInfo);
end mkElementList;

protected function mkElementList2
  "Helper function to instElementList."
  input list<tuple<SCode.Element, Modifier>> inElements;
  input Prefixes inPrefixes;
  input list<SCodeEnv.Extends> inExtends;
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
      list<SCodeEnv.Extends> exts;
      InstInfo ii;
      Env env;

    case (elem :: rest_el, _, exts, _, _, accum_el, _)
      equation
        (elem, env) = resolveRedeclaredElement(elem, inEnv);
        (accum_el, exts, ii) = mkElement_dispatch(elem, inPrefixes, exts, env, inPrefix, accum_el, inInstInfo);
        (accum_el, ii) = mkElementList2(rest_el, inPrefixes, exts, inEnv, inPrefix, accum_el, ii);
      then
        (accum_el, ii);

    case ({}, _, {}, _, _, _, _) then (inAccumEl, inInstInfo);

    // instElementList takes a list of Extends, which contains the extends
    // information from the environment. We should have one Extends element for
    // each extends clause, so if we have any left when we've run out of
    // elements something has gone very wrong.
    case ({}, _, _ :: _, _, _, _, _)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"SCodeInstShortcut.mkElementList2 has extends left!."});
      then
        fail();

  end match;
end mkElementList2;

protected function resolveRedeclaredElement
  "This function makes sure that an element is up-to-date in case it has been
   redeclared. This is achieved by looking the element up in the environment. In
   the case that the element has been redeclared, the environment where it should
   be instantiated is returned, otherwise the old environment."
  input tuple<SCode.Element, Modifier> inElement;
  input Env inEnv;
  output tuple<SCode.Element, Modifier> outElement;
  output Env outEnv;
algorithm
  (outElement, outEnv) := match(inElement, inEnv)
    local
      Modifier mod;
      String name;
      Item item;
      SCode.Element el;
      Env env;
      
    // Only components which are actually replaceable needs to be looked up,
    // since non-replaceable components can't have been replaced.
    case ((SCode.COMPONENT(name = name, prefixes =
        SCode.PREFIXES(replaceablePrefix = SCode.REPLACEABLE(_))), mod), _)
      equation
        (item, _) = SCodeLookup.lookupInClass(name, inEnv);
        (SCodeEnv.VAR(var = el), env) = SCodeEnv.resolveRedeclaredItem(item, inEnv);
      then
        ((el, mod), env);

    // Other elements doesn't need to be looked up. Extends may not be
    // replaceable, and classes are looked up in the environment anyway. The
    // exception is packages with constants, but those are handled in
    // instPackageConstants.
    else (inElement, inEnv);

  end match;
end resolveRedeclaredElement;

protected function resolveRedeclaredComponent
  input Item inItem;
  input Env inEnv;
  output SCode.Element outComponent;
  output Env outEnv;
algorithm
  (outComponent, outEnv) := match(inItem, inEnv)
    local
      SCode.Element comp;
      Env env;

    case (SCodeEnv.VAR(var = comp), _) then (comp, inEnv);

    case (SCodeEnv.REDECLARED_ITEM(item = SCodeEnv.VAR(var = comp),
        declaredEnv = env), _) then (comp, env);

  end match;
end resolveRedeclaredComponent;

protected function mkElement_dispatch
  "Helper function to instElementList2. Dispatches the given element to the
   correct function for instantiation."
  input tuple<SCode.Element, Modifier> inElement;
  input Prefixes inPrefixes;
  input list<SCodeEnv.Extends> inExtends;
  input Env inEnv;
  input Prefix inPrefix;
  input list<Element> inAccumEl;
  input InstInfo inInstInfo;
  output list<Element> outElements;
  output list<SCodeEnv.Extends> outExtends;
  output InstInfo outInstInfo;
algorithm
  (outElements, outExtends, outInstInfo) :=
  matchcontinue(inElement, inPrefixes, inExtends, inEnv, inPrefix, inAccumEl, inInstInfo)
    local
      SCode.Element elem;
      Modifier mod;
      list<Element> res;
      Option<Element> ores;
      Boolean cse;
      list<Element> accum_el;
      list<SCodeEnv.Redeclaration> redecls;
      list<SCodeEnv.Extends> rest_exts;
      String name;
      Prefix prefix;
      Env env;
      Class cls;
      Item item;
      Absyn.Path fullName;
      InstInfo ii;

    // A component when we're in 'instantiate everything'-mode.
    case ((elem as SCode.COMPONENT(name = _), mod), _, _, _, _, _, _)
      equation
        (res, ii) = mkElement(elem, mod, inPrefixes, inEnv, inPrefix, inInstInfo);
        accum_el = listAppend(inAccumEl, res); 
      then
        (accum_el, inExtends, ii);

    // An extends clause. Instantiate it together with the next Extends element
    // from the environment.
    case ((elem as SCode.EXTENDS(baseClassPath = _), mod), _,
        SCodeEnv.EXTENDS(redeclareModifiers = redecls) :: rest_exts, _, _, _, _)
      equation
        (res, ii) = mkExtends(elem, mod, inPrefixes, redecls, inEnv, inPrefix, inInstInfo);
        accum_el = listAppend(inAccumEl, res);
      then
        (accum_el, rest_exts, ii);
    
    // functions, packages, classes
    case ((elem as SCode.CLASS(name = name),mod), _, _, _, _, _, _)
      equation
        prefix = InstUtil.addPrefix(name, {}, inPrefix);
        fullName = SCodeEnv.mergePathWithEnvPath(Absyn.IDENT(name), inEnv);
        false = listMember(fullName, inInstInfo);
        // add it
        ii = fullName::inInstInfo;
        (item, env) = SCodeLookup.lookupInClass(name, inEnv);
        (res, _, ii) = mkClassItem(item, mod, InstTypes.NO_PREFIXES(), env, prefix, ii);
        ii = inInstInfo;
         accum_el = listAppend(inAccumEl, res);
      then
        (accum_el, inExtends, ii);
    
    // We should have one Extends element for each extends clause in the class.
    // If we get an extends clause but don't have any Extends elements left,
    // something has gone very wrong.
    case ((SCode.EXTENDS(baseClassPath = _), _), _, {}, _, _, _, _)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"SCodeInstShortcut.mkElement_dispatch ran out of extends!."});
      then
        fail();

    // Ignore any other kind of elements (class definitions, etc.).
    else (inAccumEl, inExtends, inInstInfo);

  end matchcontinue;
end mkElement_dispatch;

protected function mkElement
  input SCode.Element inElement;
  input Modifier inClassMod;
  input Prefixes inPrefixes;
  input Env inEnv;
  input Prefix inPrefix;
  input InstInfo inInstInfo;
  output list<Element> outElements;
  output InstInfo outInstInfo;
algorithm
  (outElements, outInstInfo) := 
  match(inElement, inClassMod, inPrefixes, inEnv, inPrefix, inInstInfo)
    local
      Absyn.ArrayDim ad;
      Absyn.Info info;
      Absyn.Path path, tpath, newpath;
      Component comp;
      DAE.Type ty;
      Env env;
      Item item;
      list<SCodeEnv.Redeclaration> redecls;
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
      Option<SCode.Comment> cmt;
      Option<Absyn.Exp> condition;
      InstInfo ii;
      Boolean sameEnv, isBasic;

    /*/ an outer component, keep it like it is
    case (SCode.COMPONENT(name = name, 
        typeSpec = Absyn.TPATH(path = tpath),
        prefixes = SCode.PREFIXES(innerOuter = Absyn.OUTER())), _, _, _, _, _)
      equation
        
      then
        ({inElement}, inInstInfo);*/

    // A component, look up it's type and instantiate that class.
    case (SCode.COMPONENT(
            name, 
            sprefixes,
            attributes as SCode.ATTR(arrayDims = ad),
            typeSpec as Absyn.TPATH(path = tpath),
            smod,
            cmt, 
            condition,
            info), _, _, _, _, _)
      equation
        // Look up the class of the component.
        (item, tpath, env) = SCodeLookup.lookupClassName(tpath, inEnv, info);
        (item, env) = SCodeEnv.resolveRedeclaredItem(item, env);
        SCodeCheck.checkPartialInstance(item, info);
        
        // the class is defined in the same env as the component
        sameEnv = stringEq(SCodeEnv.getEnvName(inEnv), SCodeEnv.getEnvName(env));

        // Instantiate array dimensions and add them to the prefix.
        //(dims,functions) = instDimensions(ad, inEnv, inPrefix, info, functions);
        //prefix = InstUtil.addPrefix(name, dims, inPrefix);
        prefix = InstUtil.addPrefix(name, {}, inPrefix);
        
        // Check that it's legal to instantiate the class.
        SCodeCheck.checkInstanceRestriction(item, prefix, info);

        // Merge the class modifications with this element's modifications.
        dim_count = listLength(ad);
        mod = SCodeMod.translateMod(smod, name, dim_count, inPrefix, inEnv);
        cmod = SCodeMod.propagateMod(inClassMod, dim_count);
        mod = SCodeMod.mergeMod(cmod, mod);

        // Merge prefixes from the instance hierarchy.
        //path = InstUtil.prefixPath(Absyn.IDENT(name), inPrefix);
        //prefs = InstUtil.mergePrefixesFromComponent(path, inElement, inPrefixes);
        //pty = InstUtil.paramTypeFromPrefixes(prefs);
        prefs = inPrefixes;

        // Apply redeclarations to the class definition and instantiate it.
        redecls = SCodeFlattenRedeclare.extractRedeclaresFromModifier(smod);
        (item, env) = SCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(
          redecls, item, env, inEnv, inPrefix);
        (classes, cls_prefs, ii) = mkClassItem(item, mod, prefs, env, prefix, inInstInfo);
        //prefs = InstUtil.mergePrefixes(prefs, cls_prefs, path, "variable");

        // Add dimensions from the class type.
        //(dims, dim_count) = addDimensionsFromType(dims, ty);
        //ty = InstUtil.arrayElementType(ty);
        //dim_arr = InstUtil.makeDimensionArray(dims);

        // Instantiate the binding.
        mod = SCodeMod.propagateMod(mod, dim_count);
        //binding = SCodeMod.getModifierBinding(mod);
        //(binding,functions) = instBinding(binding, dim_count, functions);
 
        // Create the component and add it to the program.
        smod = SCodeMod.removeRedeclaresFromMod(smod);
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
        Debug.traceln("SCodeInstShortcut.instElement failed on unknown element.\n");
      then
        fail();

  end match;
end mkElement;

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
  input list<SCodeEnv.Redeclaration> inRedeclares;
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

    case (SCode.EXTENDS(path, visibility, smod, ann, info),
        _, _, _, _, _, _)
      equation
        // Look up the base class in the environment.
        (item, path, env) = SCodeLookup.lookupBaseClassName(path, inEnv, info);
        path = SCodeEnv.mergePathWithEnvPath(path, env);
        checkRecursiveExtends(path, inEnv, info);

        // Apply the redeclarations.
        (item, env) = SCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(
          inRedeclares, item, env, inEnv, inPrefix);

        // Instantiate the class.
        prefs = InstUtil.mergePrefixesFromExtends(inExtends, inPrefixes);
        mod = SCodeMod.translateMod(smod, "", 0, inPrefix, inEnv);
        mod = SCodeMod.mergeMod(inClassMod, mod);
        
        (classes, _, ii) = 
          mkClassItem(item, mod, prefs, env, inPrefix, inInstInfo);
        
        smod = SCodeMod.removeRedeclaresFromMod(smod);
        
        name = Absyn.pathStringReplaceDot(path, "$");
        name = "'" +& name +& "$ext_" +& SCodeEnv.getEnvName(inEnv) +& "'";
        
        cls::classes = classes;
        cls = SCode.setClassName(name, cls);
        classes = cls::classes; 
        
        cls = SCode.EXTENDS(Absyn.IDENT(name), visibility, smod, ann, info);
        classes = listAppend(classes, {cls});
      then
        (classes, ii);
        
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("SCodeInstShortcut.instExtends failed on unknown element.\n");
      then
        fail();

  end match;
end mkExtends;

protected function checkRecursiveExtends
  input Absyn.Path inExtendedClass;
  input Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inExtendedClass, inEnv, inInfo)
    local
      Absyn.Path env_path;
      String env_str, path_str;

    case (_, _, _)
      equation
        env_path = SCodeEnv.getEnvPath(inEnv);
        false = Absyn.pathPrefixOf(inExtendedClass, env_path);
      then
        ();

    else
      equation
        path_str = Absyn.pathString(inExtendedClass);
        Error.addSourceMessage(Error.RECURSIVE_EXTENDS, {path_str}, inInfo);
      then
        fail();

  end matchcontinue;
end checkRecursiveExtends;

end SCodeInstShortcut;
