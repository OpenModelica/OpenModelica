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
public import InstTypes;
public import SCode;
public import SCodeEnv;

protected import ComponentReference;
protected import Debug;
protected import Dump;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import InstSymbolTable;
protected import InstUtil;
protected import List;
protected import SCodeCheck;
protected import SCodeExpand;
protected import SCodeFlattenRedeclare;
protected import SCodeLookup;
protected import SCodeMod;
protected import System;
protected import Types;
protected import Typing;

public type Binding = InstTypes.Binding;
public type Class = InstTypes.Class;
public type Component = InstTypes.Component;
public type Dimension = InstTypes.Dimension;
public type Element = InstTypes.Element;
public type Env = SCodeEnv.Env;
public type Equation = InstTypes.Equation;
public type Modifier = InstTypes.Modifier;
public type Prefixes = InstTypes.Prefixes;
public type Prefix = InstTypes.Prefix;

protected type Item = SCodeEnv.Item;
protected type SymbolTable = InstSymbolTable.SymbolTable;

public function instClass
  "Flattens a class."
  input Absyn.Path inClassPath;
  input Env inEnv;
  input list<Absyn.Path> inGlobalConstants;
algorithm
  _ := matchcontinue(inClassPath, inEnv, inGlobalConstants)
    local
      Item item;
      Absyn.Path path;
      Env env; 
      String name;
      Class cls;
      SymbolTable symtab;
      list<Absyn.Path> consts;
      list<Element> const_el;

    case (_, _, _)
      equation
        false = Flags.isSet(Flags.SCODE_INST);
      then
        ();

    case (_, _, _)
      equation
        System.startTimer();
        name = Absyn.pathLastIdent(inClassPath);
        (item, path, env) = 
          SCodeLookup.lookupClassName(inClassPath, inEnv, Absyn.dummyInfo);
        (cls, _) = instClassItem(item, InstTypes.NOMOD(), 
          InstTypes.NO_PREFIXES(), env, InstTypes.emptyPrefix);
        const_el = instGlobalConstants(inGlobalConstants, inClassPath, inEnv);
        cls = InstUtil.addElementsToClass(const_el, cls);

        //print(InstUtil.printClass(cls));
        (cls, symtab) = InstSymbolTable.build(cls);
        //print("SymbolTable:\n");
        //InstSymbolTable.dumpSymbolTableKeys(symtab);

        (cls, symtab) = Typing.typeClass(cls, symtab);
        // Type normal equations and algorithm here.
        (cls, symtab) = instConditionalComponents(cls, symtab);
        (cls, symtab) = Typing.typeClass(cls, symtab);
        // Type connects here.
        System.stopTimer();
        //print("\nclass " +& name +& "\n");
        //print(InstUtil.printClass(cls));
        //print("\nend " +& name +& "\n");

        _ = SCodeExpand.expand(name, cls);
        //print("SCodeInst took " +& realString(System.getTimerIntervalTime()) +& " seconds.\n");
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

protected function instClassItem
  input Item inItem;
  input Modifier inMod;
  input Prefixes inPrefixes;
  input Env inEnv;
  input Prefix inPrefix;
  output Class outClass;
  output DAE.Type outType;
algorithm
  (outClass, outType) := match(inItem, inMod, inPrefixes, inEnv, inPrefix)
    local
      list<SCode.Element> el;
      list<tuple<SCode.Element, Modifier>> mel;
      Absyn.TypeSpec dty;
      Item item;
      Env env;
      Absyn.Info info;
      SCode.Mod smod;
      Modifier mod;
      SCodeEnv.AvlTree cls_and_vars;
      String name, err_msg;
      list<SCode.Equation> snel, siel;
      list<Equation> inel, iiel;
      list<SCode.AlgorithmSection> nal, ial;
      DAE.Type ty;
      Absyn.ArrayDim dims;
      list<DAE.Var> vars;
      list<SCode.Enum> enums;
      Absyn.Path path;
      Class cls;
      list<Element> elems;
      SCode.Element sel;
      Boolean cse;
      SCode.Element scls;
      SCode.ClassDef cdef;
      SCodeEnv.Frame frame;
      Integer dim_count;
      list<SCodeEnv.Extends> exts;

    case (SCodeEnv.CLASS(cls = SCode.CLASS(name = name), env = env,
        classType = SCodeEnv.BASIC_TYPE()), _, _, _, _) 
      equation
        vars = instBasicTypeAttributes(inMod, env);
        ty = instBasicType(name, inMod, vars);
      then 
        (InstTypes.BASIC_TYPE(), ty);

    // A class with parts, instantiate all elements in it.
    case (SCodeEnv.CLASS(cls = SCode.CLASS(name = name,
          classDef = SCode.PARTS(el, snel, siel, nal, ial, _, _, _), info = info),
        env = {SCodeEnv.FRAME(clsAndVars = cls_and_vars)}), _, _, _, _)
      equation
        env = SCodeEnv.mergeItemEnv(inItem, inEnv);
        el = List.map1(el, lookupElement, cls_and_vars);
        mel = SCodeMod.applyModifications(inMod, el, inPrefix, env);
        exts = SCodeEnv.getEnvExtendsFromTable(env);
        (elems, cse) = instElementList(mel, inPrefixes, exts, env, inPrefix);
        inel = instEquations(snel, inEnv, inPrefix);
        iiel = instEquations(siel, inEnv, inPrefix);
        (cls, ty) = InstUtil.makeClass(elems, inel, iiel, nal, ial, cse);
      then
        (cls, ty);

    // A derived class, look up the inherited class and instantiate it.
    case (SCodeEnv.CLASS(cls = SCode.CLASS(classDef =
        SCode.DERIVED(modifications = smod, typeSpec = dty), info = info)), _, _, _, _)
      equation
        (item, env) = SCodeLookup.lookupTypeSpec(dty, inEnv, info);
        dims = Absyn.typeSpecDimensions(dty);
        dim_count = listLength(dims);
        mod = SCodeMod.translateMod(smod, "", dim_count, inPrefix, inEnv);
        mod = SCodeMod.mergeMod(inMod, mod);
        (cls, ty) = instClassItem(item, mod, inPrefixes, env, inPrefix);
        ty = liftArrayType(dims, ty, inEnv, inPrefix);
      then
        (cls, ty);
        
    case (SCodeEnv.CLASS(cls = scls, classType = SCodeEnv.CLASS_EXTENDS(), env = env), _, _, _, _)
      equation
        (cls, ty) = instClassExtends(scls, inMod, inPrefixes, env, inEnv, inPrefix);
      then
        (cls, ty);

    case (SCodeEnv.CLASS(cls = SCode.CLASS(classDef =
        SCode.ENUMERATION(enumLst = enums), info = info)), _, _, _, _)
      equation
        path = InstUtil.prefixToPath(inPrefix);
        ty = InstUtil.makeEnumType(enums, path);
      then
        (InstTypes.BASIC_TYPE(), ty);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("SCodeInst.instClassItem failed on unknown class.\n");
      then
        fail();

  end match;
end instClassItem;
  
protected function instClassExtends
  input SCode.Element inClassExtends;
  input Modifier inMod;
  input Prefixes inPrefixes;
  input Env inClassEnv;
  input Env inEnv;
  input Prefix inPrefix;
  output Class outClass;
  output DAE.Type outType;
algorithm
  (outClass, outType) := 
  matchcontinue(inClassExtends, inMod, inPrefixes, inClassEnv, inEnv, inPrefix)
    local
      SCode.ClassDef cdef;
      Absyn.Path bc_path;
      SCode.Element ext;
      SCode.Mod mod;
      SCode.Element scls;
      Class cls;
      DAE.Type ty;
      Item item;
      String name;
      Absyn.Info info;

    case (SCode.CLASS(classDef = SCode.CLASS_EXTENDS(modifications = mod, 
        composition = cdef)), _, _, _, _, _)
      equation
        (bc_path, info) = getClassExtendsBaseClass(inClassEnv);
        ext = SCode.EXTENDS(bc_path, SCode.PUBLIC(), mod, NONE(), info);
        cdef = SCode.addElementToCompositeClassDef(ext, cdef);
        scls = SCode.setElementClassDefinition(cdef, inClassExtends);
        item = SCodeEnv.CLASS(scls, inClassEnv, SCodeEnv.USERDEFINED());
        (cls, ty) = instClassItem(item, inMod, inPrefixes, inEnv, inPrefix);
      then
        (cls, ty);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        name = SCode.elementName(inClassExtends);
        Debug.traceln("SCodeInst.instClassExtends failed on " +& name);
      then
        fail();

  end matchcontinue;
end instClassExtends;

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
        Debug.traceln("SCodeInst.getClassExtendsBaseClass failed on " +& name);
      then
        fail();

  end matchcontinue;
end getClassExtendsBaseClass;

protected function instBasicType
  input SCode.Ident inTypeName;
  input Modifier inMod;
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

protected function instBasicTypeAttributes
  input Modifier inMod;
  input Env inEnv;
  output list<DAE.Var> outVars;
algorithm
  outVars := match(inMod, inEnv)
    local
      list<Modifier> submods;
      SCodeEnv.AvlTree attrs;
      list<DAE.Var> vars;
      SCode.Element el;
      Absyn.Info info;

    case (InstTypes.NOMOD(), _) then {};

    case (InstTypes.MODIFIER(subModifiers = submods), 
        SCodeEnv.FRAME(clsAndVars = attrs) :: _)
      equation
        vars = List.map1(submods, instBasicTypeAttribute, attrs);
      then
        vars;

    case (InstTypes.REDECLARE(element = el), _)
      equation
        info = SCode.elementInfo(el);
        Error.addSourceMessage(Error.INVALID_REDECLARE_IN_BASIC_TYPE, {}, info);
      then
        fail();
         
  end match;
end instBasicTypeAttributes;

protected function instBasicTypeAttribute
  input Modifier inMod;
  input SCodeEnv.AvlTree inAttributes;
  output DAE.Var outAttribute;
algorithm
  outAttribute := matchcontinue(inMod, inAttributes)
    local
      String ident, tspec;
      DAE.Type ty;
      Absyn.Exp bind_exp;
      DAE.Exp inst_exp;
      DAE.Binding binding;
      Env env;
      Prefix prefix;

    case (InstTypes.MODIFIER(name = ident, subModifiers = {}, 
        binding = InstTypes.RAW_BINDING(bind_exp, env, prefix, _, _)), _)
      equation
        SCodeEnv.VAR(var = SCode.COMPONENT(typeSpec = Absyn.TPATH(path =
          Absyn.IDENT(tspec)))) = SCodeLookup.lookupInTree(ident, inAttributes);
        ty = instBasicTypeAttributeType(tspec);
        inst_exp = instExp(bind_exp, env, prefix);
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
        
protected function instElementList
  input list<tuple<SCode.Element, Modifier>> inElements;
  input Prefixes inPrefixes;
  input list<SCodeEnv.Extends> inExtends;
  input Env inEnv;
  input Prefix inPrefix;
  output list<Element> outElements;
  output Boolean outContainsSpecialExtends;
algorithm
  (outElements, outContainsSpecialExtends) :=
    instElementList2(inElements, inPrefixes, inExtends, inEnv, inPrefix, {}, false);
end instElementList;

protected function instElementList2
  input list<tuple<SCode.Element, Modifier>> inElements;
  input Prefixes inPrefixes;
  input list<SCodeEnv.Extends> inExtends;
  input Env inEnv;
  input Prefix inPrefix;
  input list<Element> inAccumEl;
  input Boolean inContainsSpecialExtends;
  output list<Element> outElements;
  output Boolean outContainsSpecialExtends;
algorithm
  (outElements, outContainsSpecialExtends) :=
  match(inElements, inPrefixes, inExtends, inEnv, inPrefix, inAccumEl, inContainsSpecialExtends)
    local
      SCode.Element elem;
      Modifier mod;
      list<tuple<SCode.Element, Modifier>> rest_el;
      Element res;
      Option<Element> ores;
      Boolean cse;
      list<Element> accum_el;
      list<SCodeEnv.Redeclaration> redecls;
      list<SCodeEnv.Extends> rest_exts;
      String name;

    case ({}, _, {}, _, _, _, cse) then (inAccumEl, cse);

    case ((elem as SCode.COMPONENT(name = _), mod) :: rest_el, _, _, _, _, _, cse)
      equation
        res = instElement(elem, mod, inPrefixes, inEnv, inPrefix);
        (accum_el, cse) = instElementList2(rest_el, inPrefixes, inExtends,
          inEnv, inPrefix, res :: inAccumEl, cse);
      then
        (accum_el, cse);

    case ((elem as SCode.EXTENDS(baseClassPath = _), mod) :: rest_el, _,
        SCodeEnv.EXTENDS(redeclareModifiers = redecls) :: rest_exts, _, _, _, _)
      equation
        (res, cse) = instExtends(elem, mod, inPrefixes, redecls, inEnv, inPrefix);
        cse = inContainsSpecialExtends or cse;
        (accum_el, cse) = instElementList2(rest_el, inPrefixes, rest_exts,
          inEnv, inPrefix, res :: inAccumEl, cse);
      then
        (accum_el, cse);

    case ((SCode.EXTENDS(baseClassPath = _), _) :: _, _, {}, _, _, _, _)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"SCodeInst.instElementList2 ran out of extends!."});
      then
        fail();

    case ((elem as SCode.CLASS(name = name, restriction = SCode.R_PACKAGE()), mod)
        :: rest_el, _, _, _, _, accum_el, cse)
      equation
        ores = instPackageConstants(elem, mod, inEnv, inPrefix);
        accum_el = List.consOption(ores, accum_el);
        (accum_el, cse) = instElementList2(rest_el, inPrefixes, inExtends,
          inEnv, inPrefix, accum_el, cse);
      then
        (accum_el, cse);
        
    case (_ :: rest_el, _, _, _, _, _, cse)
      equation
        (accum_el, cse) = instElementList2(rest_el, inPrefixes, inExtends,
          inEnv, inPrefix, inAccumEl, cse);
      then
        (accum_el, cse);

    case ({}, _, _ :: _, _, _, _, _)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"SCodeInst.instElementList2 has extends left!."});
      then
        fail();

  end match;
end instElementList2;

protected function instElement
  input SCode.Element inElement;
  input Modifier inClassMod;
  input Prefixes inPrefixes;
  input Env inEnv;
  input Prefix inPrefix;
  output Element outElement;
algorithm
  outElement := match(inElement, inClassMod, inPrefixes, inEnv, inPrefix)
    local
      Absyn.ArrayDim ad;
      Absyn.Info info;
      Absyn.Path path, inner_comp;
      Component comp;
      DAE.Type ty;
      Env env;
      Item item;
      list<SCodeEnv.Redeclaration> redecls;
      Binding binding;
      Prefix prefix;
      SCode.Mod smod;
      Modifier mod, cmod;
      String name;
      SCode.Variability var;
      list<DAE.Dimension> dims;
      array<Dimension> dim_arr;
      Class cls;
      Element el;
      SCode.Prefixes pf;
      SCode.Attributes attr;
      Prefixes prefs;
      Integer dim_count;

    case (SCode.COMPONENT(name = name, 
        prefixes = SCode.PREFIXES(innerOuter = Absyn.OUTER())), _, _, _, _)
      equation
        prefix = InstUtil.addPrefix(name, {}, inPrefix);
        path = InstUtil.prefixToPath(prefix);
        comp = InstTypes.OUTER_COMPONENT(path, NONE());
      then
        InstTypes.ELEMENT(comp, InstTypes.BASIC_TYPE());

    // A component, look up it's type and instantiate that class.
    case (SCode.COMPONENT(name = name, prefixes = pf, 
        attributes = attr as SCode.ATTR(arrayDims = ad),
        typeSpec = Absyn.TPATH(path = path), modifications = smod,
        condition = NONE(), info = info), _, _, _, _)
      equation
        // Look up the class of the component.
        (item, _, env) = SCodeLookup.lookupClassName(path, inEnv, info);

        // Instantiate array dimensions and add them to the prefix.
        dims = instDimensions(ad, inEnv, inPrefix);
        prefix = InstUtil.addPrefix(name, dims, inPrefix);

        // Check that it's legal to instantiate the class.
        SCodeCheck.checkInstanceRestriction(item, prefix, info);

        // Merge the class modifications with this elements' modifications.
        dim_count = listLength(ad);
        mod = SCodeMod.translateMod(smod, name, dim_count, inPrefix, inEnv);
        cmod = SCodeMod.propagateMod(inClassMod, dim_count);
        mod = SCodeMod.mergeMod(cmod, mod);

        // Merge prefixes from the instance hierarchy.
        path = InstUtil.prefixPath(Absyn.IDENT(name), inPrefix);
        prefs = InstUtil.mergePrefixes(path, pf, attr, inPrefixes, info);

        // Apply redeclarations to the class definition and instantiate it.
        redecls = SCodeFlattenRedeclare.extractRedeclaresFromModifier(smod);
        (item, env) = SCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(
          redecls, item, env, inEnv, inPrefix);
        (cls, ty) = instClassItem(item, mod, prefs, env, prefix);

        // Add dimensions from the class type.
        (dims, dim_count) = addDimensionsFromType(dims, ty);
        ty = Types.arrayElementType(ty);
        dim_arr = InstUtil.makeDimensionArray(dims);

        // Instantiate the binding.
        mod = SCodeMod.propagateMod(mod, dim_count);
        binding = SCodeMod.getModifierBinding(mod);
        binding = instBinding(binding, dim_count);

        // Create the component and add it to the program.
        comp = InstTypes.UNTYPED_COMPONENT(path, ty, dim_arr, prefs, binding, info);
      then
        InstTypes.ELEMENT(comp, cls);

    // A conditional component, save it for later.
    case (SCode.COMPONENT(name = name, condition = SOME(_)), _, _, _, _)
      equation
        path = InstUtil.prefixPath(Absyn.IDENT(name), inPrefix);
        comp = InstTypes.CONDITIONAL_COMPONENT(path, inElement, inClassMod, inPrefixes, inEnv, inPrefix);
      then
        InstTypes.CONDITIONAL_ELEMENT(comp);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("SCodeInst.instElement failed on unknown element.\n");
      then
        fail();

  end match;
end instElement;

protected function instExtends
  input SCode.Element inExtends;
  input Modifier inClassMod;
  input Prefixes inPrefixes;
  input list<SCodeEnv.Redeclaration> inRedeclares;
  input Env inEnv;
  input Prefix inPrefix;
  output Element outElement;
  output Boolean outContainsSpecialExtends;
algorithm
  (outElement, outContainsSpecialExtends) :=
  match(inExtends, inClassMod, inPrefixes, inRedeclares, inEnv, inPrefix)
    local
      Absyn.Path path, path2;
      SCode.Mod smod;
      Absyn.Info info;
      SCodeEnv.ExtendsTable exts;
      Item item;
      Env env;
      list<SCodeEnv.Redeclaration> redecls;
      Modifier mod;
      Class cls;
      DAE.Type ty;
      Boolean cse;

    case (SCode.EXTENDS(baseClassPath = path, modifications = smod, info = info),
        _, _, _, _, _)
      equation
        // Look up the extended class.
        (item, path, env) = SCodeLookup.lookupClassName(path, inEnv, info);
        path = SCodeEnv.mergePathWithEnvPath(path, env);

        // Apply the redeclarations.
        (item, env) = SCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(
          inRedeclares, item, env, inEnv, inPrefix);

        // Instantiate the class.
        mod = SCodeMod.translateMod(smod, "", 0, inPrefix, inEnv);
        mod = SCodeMod.mergeMod(inClassMod, mod);
        (cls, ty) = instClassItem(item, mod, inPrefixes, env, inPrefix);
        cse = InstUtil.isSpecialExtends(ty);
      then
        (InstTypes.EXTENDED_ELEMENTS(path, cls, ty), cse);
        
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("SCodeInst.instExtends failed on unknown element.\n");
      then
        fail();

  end match;
end instExtends;

protected function instPackageConstants
  input SCode.Element inPackage;
  input Modifier inMod;
  input Env inEnv;
  input Prefix inPrefix;
  output Option<Element> outElement;
algorithm
  outElement := match(inPackage, inMod, inEnv, inPrefix)
    local
      String name;
      list<SCode.Element> el;
      list<tuple<SCode.Element, Modifier>> mel;
      list<Element> iel;
      Option<Element> oel;
      Prefix prefix;
      Env env;
      SCodeEnv.Frame class_env;
      
    case (SCode.CLASS(partialPrefix = SCode.PARTIAL()), _, _, _)
      then NONE();

    case (SCode.CLASS(name = name), _, _, _)
      equation
        SCodeEnv.CLASS(cls = SCode.CLASS(classDef = SCode.PARTS(elementLst = el)),
          env = {class_env}) = SCodeLookup.lookupInClass(name, inEnv);
        env = class_env :: inEnv;
        prefix = InstUtil.addPrefix(name, {}, inPrefix);
        mel = SCodeMod.applyModifications(inMod, el, prefix, env);
        iel = instPackageConstants2(mel, env, prefix, {});
        oel = makeConstantsPackage(prefix, iel);
      then
        oel;

    else NONE();

  end match;
end instPackageConstants;

protected function instPackageConstants2
  input list<tuple<SCode.Element, Modifier>> inElements;
  input Env inEnv;
  input Prefix inPrefix;
  input list<Element> inAccumEl;
  output list<Element> outAccumEl;
algorithm
  outAccumEl := match(inElements, inEnv, inPrefix, inAccumEl)
    local
      SCode.Element sel;
      Modifier mod;
      list<tuple<SCode.Element, Modifier>> rest_el;
      Element el;

    case ({}, _, _, _) then inAccumEl;

    case ((sel as SCode.COMPONENT(attributes = SCode.ATTR(variability =
        SCode.CONST())), mod) :: rest_el, _, _, _)
      equation
        el = instElement(sel, mod, InstTypes.NO_PREFIXES(), inEnv, inPrefix);
      then
        instPackageConstants2(rest_el, inEnv, inPrefix, el :: inAccumEl);

    case (_ :: rest_el, _, _, _)
      then instPackageConstants2(rest_el, inEnv, inPrefix, inAccumEl);

  end match;
end instPackageConstants2;

protected function makeConstantsPackage
  input Prefix inPrefix;
  input list<Element> inElements;
  output Option<Element> outElement;
algorithm
  outElement := match(inPrefix, inElements)
    local
      Absyn.Path name;
      Element el;

    case (_, {}) then NONE();

    else
      equation
        name = InstUtil.prefixToPath(inPrefix);
        el = InstTypes.ELEMENT(InstTypes.PACKAGE(name),
          InstTypes.COMPLEX_CLASS(inElements, {}, {}, {}, {}));
      then
        SOME(el);

  end match;
end makeConstantsPackage;

protected function instEnumLiterals
  input list<SCode.Enum> inEnumLiterals;
  input Absyn.Path inEnumPath;
  input DAE.Type inType;
  input Integer inIndex;
  input list<Element> inAccumEl;
  output list<Element> outElements;
algorithm
  outElements := 
  match(inEnumLiterals, inEnumPath, inType, inIndex, inAccumEl)
    local
      SCode.Enum enum_lit;
      list<SCode.Enum> rest_lits;
      Element el;

    case ({}, _, _, _, _) then inAccumEl;

    case (enum_lit :: rest_lits, _, _, _, _)
      equation
        el = instEnumLiteral(enum_lit, inEnumPath, inType, inIndex);
      then
        instEnumLiterals(rest_lits, inEnumPath, inType, inIndex + 1, 
          el :: inAccumEl);

  end match;
end instEnumLiterals;

protected function instEnumLiteral
  input SCode.Enum inEnumLiteral;
  input Absyn.Path inEnumPath;
  input DAE.Type inType;
  input Integer inIndex;
  output Element outElement;
algorithm
  outElement := match(inEnumLiteral, inEnumPath, inType, inIndex)
    local
      String name;
      Absyn.Path path;
      Component comp;

    case (SCode.ENUM(literal = name), _, _, _)
      equation
        path = Absyn.suffixPath(inEnumPath, name);
        comp = InstUtil.makeEnumLiteralComp(path, inType, inIndex);
      then
        InstTypes.ELEMENT(comp, InstTypes.BASIC_TYPE());

  end match;
end instEnumLiteral;

protected function instBinding
  input Binding inBinding;
  input Integer inCompDimensions;
  output Binding outBinding;
algorithm
  outBinding := match(inBinding, inCompDimensions)
    local
      Absyn.Exp aexp;
      DAE.Exp dexp;
      Env env;
      Prefix prefix;
      Integer pl, cd;
      Absyn.Info info;

    case (InstTypes.RAW_BINDING(aexp, env, prefix, pl, info), cd)
      equation
        dexp = instExp(aexp, env, prefix);
      then
        InstTypes.UNTYPED_BINDING(dexp, false, pl, info);

    else inBinding;

  end match;
end instBinding;

protected function instDimensions
  input list<Absyn.Subscript> inSubscript;
  input Env inEnv;
  input Prefix inPrefix;
  output list<DAE.Dimension> outDimensions;
algorithm
  outDimensions := List.map2(inSubscript, instDimension, inEnv, inPrefix);
end instDimensions;

protected function instDimension
  input Absyn.Subscript inSubscript;
  input Env inEnv;
  input Prefix inPrefix;
  output DAE.Dimension outDimension;
algorithm
  outDimension := match(inSubscript, inEnv, inPrefix)
    local
      Absyn.Exp aexp;
      DAE.Exp dexp;

    case (Absyn.NOSUB(), _, _) then DAE.DIM_UNKNOWN();

    case (Absyn.SUBSCRIPT(subscript = aexp), _, _)
      equation
        dexp = instExp(aexp, inEnv, inPrefix);
      then
        InstUtil.makeDimension(dexp);

  end match;
end instDimension;

protected function instSubscripts
  input list<Absyn.Subscript> inSubscripts;
  input Env inEnv;
  input Prefix inPrefix;
  output list<DAE.Subscript> outSubscripts;
algorithm
  outSubscripts := List.map2(inSubscripts, instSubscript, inEnv, inPrefix);
end instSubscripts;

protected function instSubscript
  input Absyn.Subscript inSubscript;
  input Env inEnv;
  input Prefix inPrefix;
  output DAE.Subscript outSubscript;
algorithm
  outSubscript := match(inSubscript, inEnv, inPrefix)
    local
      Absyn.Exp aexp;
      DAE.Exp dexp;

    case (Absyn.NOSUB(), _, _) then DAE.WHOLEDIM();

    case (Absyn.SUBSCRIPT(subscript = aexp), _, _)
      equation
        dexp = instExp(aexp, inEnv, inPrefix);
      then
        makeSubscript(dexp);

  end match;
end instSubscript;

protected function makeSubscript
  input DAE.Exp inExp;
  output DAE.Subscript outSubscript;
algorithm
  outSubscript := match(inExp)
    case DAE.RANGE(ty = _)
      then DAE.SLICE(inExp);

    else DAE.INDEX(inExp);

  end match;
end makeSubscript;

protected function liftArrayType
  input Absyn.ArrayDim inDims;
  input DAE.Type inType;
  input Env inEnv;
  input Prefix inPrefix;
  output DAE.Type outType;
algorithm
  outType := match(inDims, inType, inEnv, inPrefix)
    local
      DAE.Dimensions dims1, dims2;
      DAE.TypeSource src;
      DAE.Type ty;

    case ({}, _, _, _) then inType;
    case (_, DAE.T_ARRAY(ty, dims1, src), _, _)
      equation
        dims2 = List.map2(inDims, instDimension, inEnv, inPrefix);
        dims1 = listAppend(dims2, dims1);
      then
        DAE.T_ARRAY(ty, dims1, src);

    else
      equation
        dims2 = List.map2(inDims, instDimension, inEnv, inPrefix);
      then
        DAE.T_ARRAY(inType, dims2, DAE.emptyTypeSource);
  
  end match;
end liftArrayType;

protected function addDimensionsFromType
  input list<DAE.Dimension> inDimensions;
  input DAE.Type inType;
  output list<DAE.Dimension> outDimensions;
  output Integer outAddedDims;
algorithm
  (outDimensions, outAddedDims) := match(inDimensions, inType)
    local
      list<DAE.Dimension> dims;
      Integer added_dims;

    case (_, DAE.T_ARRAY(dims = dims))
      equation
        added_dims = listLength(dims);
        dims = listAppend(dims, inDimensions);
      then
        (dims, added_dims);

    else (inDimensions, 0);

  end match;
end addDimensionsFromType;

protected function instExpList
  input list<Absyn.Exp> inExp;
  input Env inEnv;
  input Prefix inPrefix;
  output list<DAE.Exp> outExp;
algorithm
  outExp := List.map2(inExp, instExp, inEnv, inPrefix);
end instExpList;

protected function instExpOpt
  input Option<Absyn.Exp> inExp;
  input Env inEnv;
  input Prefix inPrefix;
  output Option<DAE.Exp> outExp;
algorithm
  outExp := match(inExp, inEnv, inPrefix)
    local
      Absyn.Exp aexp;
      DAE.Exp dexp;

    case (SOME(aexp), _, _)
      equation
        dexp = instExp(aexp, inEnv, inPrefix);
      then
        SOME(dexp);

    else NONE();

  end match;
end instExpOpt;

protected function instExp
  input Absyn.Exp inExp;
  input Env inEnv;
  input Prefix inPrefix;
  output DAE.Exp outExp;
algorithm
  outExp := match(inExp, inEnv, inPrefix)
    local
      Integer ival;
      Real rval;
      String sval;
      Boolean bval;
      Absyn.ComponentRef acref;
      DAE.ComponentRef dcref;
      Absyn.Exp aexp1, aexp2;
      DAE.Exp dexp1, dexp2;
      Absyn.Operator aop;
      DAE.Operator dop;
      list<Absyn.Exp> aexpl, afargs;
      list<DAE.Exp> dexpl, dfargs;
      list<list<Absyn.Exp>> mat_expl;
      list<Absyn.NamedArg> named_args;
      Absyn.Path path;
      Option<Absyn.Exp> oaexp;
      Option<DAE.Exp> odexp;

    case (Absyn.REAL(value = rval), _, _) then DAE.RCONST(rval);
    case (Absyn.INTEGER(value = ival), _, _) then DAE.ICONST(ival);
    case (Absyn.BOOL(value = bval), _, _) then DAE.BCONST(bval);
    case (Absyn.STRING(value = sval), _, _) then DAE.SCONST(sval);
    case (Absyn.CREF(componentRef = acref), _, _) 
      equation
        dcref = instCref(acref, inEnv, inPrefix);
      then
        DAE.CREF(dcref, DAE.T_UNKNOWN_DEFAULT);

    case (Absyn.BINARY(exp1 = aexp1, op = aop, exp2 = aexp2), _, _)
      equation
        dexp1 = instExp(aexp1, inEnv, inPrefix);
        dexp2 = instExp(aexp2, inEnv, inPrefix);
        dop = instOperator(aop);
      then
        DAE.BINARY(dexp1, dop, dexp2);

    case (Absyn.UNARY(op = aop, exp = aexp1), _, _)
      equation
        dexp1 = instExp(aexp1, inEnv, inPrefix);
        dop = instOperator(aop);
      then
        DAE.UNARY(dop, dexp1);

    case (Absyn.LBINARY(exp1 = aexp1, op = aop, exp2 = aexp2), _, _)
      equation
        dexp1 = instExp(aexp1, inEnv, inPrefix);
        dexp2 = instExp(aexp2, inEnv, inPrefix);
        dop = instOperator(aop);
      then
        DAE.LBINARY(dexp1, dop, dexp2);

    case (Absyn.LUNARY(op = aop, exp = aexp1), _, _)
      equation
        dexp1 = instExp(aexp1, inEnv, inPrefix);
        //dop = instOperator(aop);
        dop = DAE.NOT(DAE.T_BOOL_DEFAULT);
      then
        DAE.LUNARY(dop, dexp1);

    case (Absyn.RELATION(exp1 = aexp1, op = aop, exp2 = aexp2), _, _)
      equation
        dexp1 = instExp(aexp1, inEnv, inPrefix);
        dexp2 = instExp(aexp2, inEnv, inPrefix);
        dop = instOperator(aop);
      then
        DAE.RELATION(dexp1, dop, dexp2, -1, NONE());

    case (Absyn.ARRAY(arrayExp = aexpl), _, _)
      equation
        dexp1 = instArray(aexpl, inEnv, inPrefix);
      then
        dexp1;

    case (Absyn.MATRIX(matrix = mat_expl), _, _)
      equation
        dexpl = List.map2(mat_expl, instArray, inEnv, inPrefix);
      then
        DAE.ARRAY(DAE.T_UNKNOWN_DEFAULT, false, dexpl);

    case (Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "size"),
        functionArgs = Absyn.FUNCTIONARGS(args = {aexp1, aexp2})), _, _)
      equation
        dexp1 = instExp(aexp1, inEnv, inPrefix);
        dexp2 = instExp(aexp2, inEnv, inPrefix);
      then
        DAE.SIZE(dexp1, SOME(dexp2));

    case (Absyn.CALL(function_ = acref, 
        functionArgs = Absyn.FUNCTIONARGS(afargs, named_args)), _, _)
      equation
        dexp1 = instFunctionCall(acref, afargs, named_args, inEnv, inPrefix);
      then
        dexp1;

    case (Absyn.RANGE(start = aexp1, step = oaexp, stop = aexp2), _, _)
      equation
        dexp1 = instExp(aexp1, inEnv, inPrefix);
        odexp = instExpOpt(oaexp, inEnv, inPrefix);
        dexp2 = instExp(aexp2, inEnv, inPrefix);
      then
        DAE.RANGE(DAE.T_UNKNOWN_DEFAULT, dexp1, odexp, dexp2);

    case (Absyn.TUPLE(expressions = aexpl), _, _)
      equation
        dexpl = instExpList(aexpl, inEnv, inPrefix);
      then
        DAE.TUPLE(dexpl);

    case (Absyn.LIST(exps = aexpl), _, _)
      equation
        dexpl = instExpList(aexpl, inEnv, inPrefix);
      then
        DAE.LIST(dexpl);

    case (Absyn.CONS(head = aexp1, rest = aexp2), _, _)
      equation
        dexp1 = instExp(aexp1, inEnv, inPrefix);
        dexp2 = instExp(aexp2, inEnv, inPrefix);
      then
        DAE.CONS(dexp1, dexp2);

    //Absyn.PARTEVALFUNCTION
    //Absyn.END
    //Absyn.CODE
    //Absyn.AS
    //Absyn.MATCHEXP

    else DAE.SCONST("fixme");
  end match;
end instExp;

protected function instArray
  input list<Absyn.Exp> inExpl;
  input Env inEnv;
  input Prefix inPrefix;
  output DAE.Exp outArray;
protected
  list<DAE.Exp> expl;
algorithm
  expl := List.map2(inExpl, instExp, inEnv, inPrefix);
  outArray := DAE.ARRAY(DAE.T_UNKNOWN_DEFAULT, false, expl);
end instArray;

protected function instOperator
  input Absyn.Operator inOperator;
  output DAE.Operator outOperator;
algorithm
  outOperator := match(inOperator)
    case Absyn.ADD() then DAE.ADD(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.SUB() then DAE.SUB(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.MUL() then DAE.MUL(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.DIV() then DAE.DIV(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.POW() then DAE.POW(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.UPLUS() then DAE.ADD(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.UMINUS() then DAE.UMINUS(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.ADD_EW() then DAE.ADD_ARR(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.SUB_EW() then DAE.SUB_ARR(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.MUL_EW() then DAE.MUL_ARR(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.DIV_EW() then DAE.DIV_ARR(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.POW_EW() then DAE.POW_ARR2(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.UPLUS_EW() then DAE.ADD(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.UMINUS_EW() then DAE.UMINUS(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.AND() then DAE.AND(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.OR() then DAE.OR(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.NOT() then DAE.NOT(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.LESS() then DAE.LESS(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.LESSEQ() then DAE.LESSEQ(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.GREATER() then DAE.GREATER(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.GREATEREQ() then DAE.GREATEREQ(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.EQUAL() then DAE.EQUAL(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.NEQUAL() then DAE.NEQUAL(DAE.T_UNKNOWN_DEFAULT);
  end match;
end instOperator;

protected function instCref
  "This function instantiates a cref, which means translating if from Absyn to
   DAE representation and prefixing it with the correct prefix so that it can
   be uniquely identified in the symbol table."
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  input Prefix inPrefix;
  output DAE.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref, inEnv, inPrefix)
    local
      Absyn.ComponentRef acref;
      DAE.ComponentRef cref;
      SCode.Variability var;
      SCodeLookup.Origin origin;
      Absyn.Path path;
      Item item;
      Env env;

    case (Absyn.WILD(), _, _) then DAE.WILD();
    case (Absyn.ALLWILD(), _, _) then DAE.WILD();
    case (Absyn.CREF_FULLYQUALIFIED(acref), _, _)
      equation
        cref = instCref2(acref, inEnv, inPrefix);
      then
        cref;

    case (_, _, _)
      equation
        cref = instCref2(inCref, inEnv, inPrefix);
        path = Absyn.crefToPathIgnoreSubs(inCref);
        cref = prefixCref(cref, path, inPrefix, inEnv);
      then
        cref;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- SCodeInst.instCref failed on " +& Dump.printComponentRefStr(inCref));
      then
        fail();
      
  end matchcontinue;
end instCref;
        
protected function instCref2
  "Helper function to instCref, converts an Absyn.ComponentRef to a
   DAE.ComponentRef. This is done by instantiating the cref's subscripts, and
   constructing a DAE.ComponentRef with unknown type (which is filled in during
   typing later on)."
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  input Prefix inPrefix;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inCref, inEnv, inPrefix)
    local
      String name;
      Absyn.ComponentRef cref;
      DAE.ComponentRef dcref;
      list<Absyn.Subscript> asubs;
      list<DAE.Subscript> dsubs;

    case (Absyn.CREF_IDENT(name, asubs), _, _)
      equation
        dsubs = instSubscripts(asubs, inEnv, inPrefix);
      then
        DAE.CREF_IDENT(name, DAE.T_UNKNOWN_DEFAULT, dsubs);

    case (Absyn.CREF_QUAL(name, asubs, cref), _, _)
      equation
        dsubs = instSubscripts(asubs, inEnv, inPrefix);
        dcref = instCref2(cref, inEnv, inPrefix);
      then
        DAE.CREF_QUAL(name, DAE.T_UNKNOWN_DEFAULT, dsubs, dcref);

    case (Absyn.CREF_FULLYQUALIFIED(cref), _, _)
      then instCref2(cref, inEnv, inPrefix);

  end match;
end instCref2;

protected function prefixCref
  "Prefixes a cref so that it can be uniquely identified in the symbol table."
  input DAE.ComponentRef inCref;
  input Absyn.Path inCrefPath;
  input Prefix inPrefix;
  input Env inEnv;
  output DAE.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref, inCrefPath, inPrefix, inEnv)
    local
      Env env;
      DAE.ComponentRef cref;
      SCodeLookup.Origin origin;
      Boolean is_global;

    // If the name can be found in the local scope, call instLocalCref.
    case (_, _, _, _)
      equation
        (_, _, env, origin) = SCodeLookup.lookupNameInPackage(inCrefPath, inEnv);
        is_global = SCodeLookup.originIsGlobal(origin);
        cref = prefixLocalCref(inCref, inPrefix, inEnv, env, is_global);
      then
        cref;

    // Otherwise, look it up in the scopes above, and call instGlobalCref.
    case (_, _, _, _ :: env)
      equation
        (_, _, env, _) = SCodeLookup.lookupName(inCrefPath, env, Absyn.dummyInfo, NONE());
        cref = prefixGlobalCref(inCref, inPrefix, inEnv, env);
      then
        cref;

  end matchcontinue;
end prefixCref;

protected function prefixLocalCref
  "Prefixes a local cref, i.e. a cref that was found in the local scope."
  input DAE.ComponentRef inCref;
  input Prefix inPrefix;
  input Env inOriginEnv "The environment where we looked for the cref.";
  input Env inFoundEnv "The environment where we found the cref.";
  input Boolean inOriginGlobal;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inCref, inPrefix, inOriginEnv, inFoundEnv, inOriginGlobal)
    local
      String id;
      Absyn.Path path;
      Env prefix_env;

    // This case is for a non-global local cref, i.e. the first identifier in the
    // cref is pointing at a local instance and not a local class. In this case
    // we just prefix the cref with the given prefix.
    case (_, _, _, _, false)
      then InstUtil.prefixCref(inCref, inPrefix);

    // Otherwise it's a global local cref, i.e. the first identifier in the cref
    // is pointing at a local class and not a local instance. In this case we
    // prefix the cref with the environment where it was found.
    else prefixCrefWithEnv(inCref, inFoundEnv);

  end match;
end prefixLocalCref;

protected function prefixGlobalCref
  "Prefixes a global cref, i.e. a cref that was found outside the local scope."
  input DAE.ComponentRef inCref;
  input Prefix inPrefix;
  input Env inOriginEnv "The environment where we looked for the cref.";
  input Env inFoundEnv "The environment where we found the cref.";
  output DAE.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref, inPrefix, inOriginEnv, inFoundEnv)
    local
      list<String> oenv, fenv;
      Prefix prefix;
      DAE.ComponentRef cref;
      String id;
      Absyn.Path path;
      Env prefix_env;

    // This case is for a global cref that was found in one of the scopes above
    // where it was used, e.g. it was used in A.B.C but was found in A.B. In
    // this case we remove the equal prefixes, i.e. removing A.B and leaving C.
    // We then apply as much of the given prefix as the number of scopes we have
    // left. So if we have a cref a.b with a prefix c.d and one scope left, we
    // get c.a.b.
    case (_, _, _, _)
      equation
        oenv = SCodeEnv.envScopeNames(inOriginEnv);
        fenv = SCodeEnv.envScopeNames(inFoundEnv);
        prefix = reducePrefix(inPrefix, oenv, fenv);
        cref = InstUtil.prefixCref(inCref, prefix);
      then
        cref;

    // If the previous case failed it means that the cref wasn't found in any of
    // the scopes above where the cref was used, i.e. the instance hierarchy. In
    // this case we prefix the cref with the environment where it was found.
    else prefixCrefWithEnv(inCref, inFoundEnv);
        
  end matchcontinue;
end prefixGlobalCref;

protected function reducePrefix
  "This function reduces a prefix given the environment where we first looked
   for a cref and the environment where it was actually found."
  input Prefix inPrefix;
  input list<String> inOriginEnv;
  input list<String> inFoundEnv;
  output Prefix outPrefix;
algorithm
  outPrefix := match(inPrefix, inOriginEnv, inFoundEnv)
    local
      Prefix rest_prefix;
      list<String> rest_oenv, rest_fenv;
      String oname, fname;

    // This is the second phase, when inFoundEnv is empty, where we remove the
    // first part of the prefix until inOriginEnv is empty.
    case (_ :: rest_prefix, _ :: rest_oenv, {})
      then reducePrefix(rest_prefix, rest_oenv, {});

    // This is the first phase, where we remove the most global scopes of both
    // environments as long as those scopes are equal.
    case (_, oname :: rest_oenv, fname :: rest_fenv)
      equation
        true = stringEq(oname, fname);
      then
        reducePrefix(inPrefix, rest_oenv, rest_fenv);

    // Finally, return the remaining prefix if both environment are empty and
    // the prefix is not empty.
    case (_ :: _, {}, {}) then inPrefix;

  end match;
end reducePrefix;

protected function prefixCrefWithEnv
  "Prefixes a cref with an environment."
  input DAE.ComponentRef inCref;
  input Env inEnv;
  output DAE.ComponentRef outCref;
protected
  String id;
  Env env;
  list<String> env_strl;
algorithm
  outCref := matchcontinue(inCref, inEnv)
    local
      String id;
      Env env;
      list<String> env_strl;
      DAE.ComponentRef cref;

    // This case is when the cref already contains parts of the environment.
    // E.g. the cref A.B.c is found in P.A.B, and result should be P.A.B.c.
    case (_, _)
      equation
        // First we remove the most local scopes until the remaining most local
        // scope has the same name as the first identifier of the cref.
        id = ComponentReference.crefFirstIdent(inCref);
        env = removeNeqEnvTail(id, inEnv);
        // Then we remove the most global scopes until the remaining environment
        // is a prefix of the cref.
        env_strl = removeEnvCrefPrefix(inCref, env);
        // Finally we prefix the cref with the remaining environment.
        cref = ComponentReference.crefPrefixStringList(env_strl, inCref);
      then
        cref;

    // If the previous case failed, i.e. if no scope in the environment has the
    // same name as the first identifier of the cref, then we prefix the cref
    // with the whole environment.
    else
      equation
        env_strl = SCodeEnv.envScopeNames(inEnv);
        cref = ComponentReference.crefPrefixStringList(env_strl, inCref);
      then
        cref;
  
  end matchcontinue;
        
end prefixCrefWithEnv;

protected function removeNeqEnvTail
  "This function removes the most local scopes from the environment until the
   remaining most local scope has the same name as the given identifier. E.g.
   for an environment A.B.C.D and a given identifier B we remove D and C, which
   gives the result A.B"
  input String inId;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inId, inEnv)
    local
      String name;
      Env rest_env;

    // Check if the frame name matches the given identifier. Return the
    // remaining environment in that case.
    case (_, SCodeEnv.FRAME(name = SOME(name)) :: _)
      equation
        true = stringEq(name, inId);
      then
        inEnv;

    // Otherwise, discard the most local scope and try again.
    case (_, _ :: rest_env) then removeNeqEnvTail(inId, rest_env);

  end matchcontinue;
end removeNeqEnvTail;

protected function removeEnvCrefPrefix
  "This function removes the most global scopes of the environment until the
   remaining environment is a prefix of the cref, and returns a list of the
   remaining environment's scope names."
  input DAE.ComponentRef inCref;
  input Env inEnv;
  output list<String> outScopeNames;
protected
  list<String> env_strl, cref_strl;
algorithm
  env_strl := SCodeEnv.envScopeNames(inEnv);
  cref_strl := ComponentReference.toStringList(inCref);
  outScopeNames := removeEnvCrefPrefix2(cref_strl, env_strl, {});
end removeEnvCrefPrefix;

protected function removeEnvCrefPrefix2
  "Helper function to removeEnvCrefPrefix, does the real work."
  input list<String> inCref;
  input list<String> inEnv;
  input list<String> inAccumPrefix;
  output list<String> outPrefix;
algorithm
  outPrefix := matchcontinue(inCref, inEnv, inAccumPrefix)
    local
      String env_head;
      list<String> rest_env;

    // If the environment is a prefix of the cref, return the accumulated
    // prefix.
    case (_, _, _)
      equation
        true = List.isPrefixOnTrue(inEnv, inCref, stringEq);
      then
        listReverse(inAccumPrefix);

    // Otherwise, remove the most global scope, add it to the accumulated prefix
    // and try again. 
    case (_, env_head :: rest_env, _)
      then removeEnvCrefPrefix2(inCref, rest_env, env_head :: inAccumPrefix);

  end matchcontinue;
end removeEnvCrefPrefix2;

protected function instFunctionCall
  input Absyn.ComponentRef inName;
  input list<Absyn.Exp> inPositionalArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Env inEnv;
  input Prefix inPrefix;
  output DAE.Exp outCallExp;
algorithm
  outCallExp := match(inName, inPositionalArgs, inNamedArgs, inEnv, inPrefix)
    local
      Absyn.Path call_path;
      DAE.ComponentRef cref;
      list<DAE.Exp> pos_args;

    case (_, _, _, _, _)
      equation
        call_path = instFunctionName(inName, inEnv, inPrefix);
        pos_args = instExpList(inPositionalArgs, inEnv, inPrefix);
      then
        DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther);

  end match;
end instFunctionCall;

protected function instFunctionName
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  input Prefix inPrefix;
  output Absyn.Path outName;
algorithm
  outName := matchcontinue(inCref, inEnv, inPrefix)
    local
      Absyn.Path path;
      Item item;
      SCodeLookup.Origin origin;
      Env env;

    case (_, _, _)
      equation
        path = Absyn.crefToPath(inCref);
        (item, _, env, origin) =
          SCodeLookup.lookupFunctionName(path, inEnv, Absyn.dummyInfo);
        path = instFunctionName2(item, path, origin, env, inPrefix);
      then
        path;

  end matchcontinue;
end instFunctionName;

protected function instFunctionName2
  input Item inItem;
  input Absyn.Path inPath;
  input SCodeLookup.Origin inOrigin;
  input Env inEnv;
  input Prefix inPrefix;
  output Absyn.Path outPath;
algorithm
  outPath := match(inItem, inPath, inOrigin, inEnv, inPrefix)
    local
      String name;
      Absyn.Path path;

    // The name of a builtin function should not be prefixed.
    case (_, _, SCodeLookup.BUILTIN_ORIGIN(), _, _)
      then inPath;

    // A qualified name with class origin should be prefixed with the package
    // name.
    case (_, Absyn.QUALIFIED(name = _), SCodeLookup.CLASS_ORIGIN(), _, _)
      equation
        name = SCodeEnv.getItemName(inItem);
        path = SCodeEnv.mergePathWithEnvPath(Absyn.IDENT(name), inEnv);
      then
        path;

    // A name with instance origin or a non-qualified name with class origin
    // (i.e. a local name), should be prefixed with the instance prefix.
    else
      equation
        path = InstUtil.prefixPath(inPath, inPrefix);
      then
        path;

  end match;
end instFunctionName2;

protected function instEquations
  input list<SCode.Equation> inEquations;
  input Env inEnv;
  input Prefix inPrefix;
  output list<Equation> outEquations;
algorithm
  //outEquations := List.map2(inEquations, instEquation, inEnv, inPrefix);
  outEquations := {};
end instEquations;

protected function instEquation
  input SCode.Equation inEquation;
  input Env inEnv;
  input Prefix inPrefix;
  output Equation outEquation;
protected
  SCode.EEquation eq; 
algorithm
  SCode.EQUATION(eEquation = eq) := inEquation;
  outEquation := instEEquation(eq, inEnv, inPrefix);
end instEquation;

protected function instEEquation
  input SCode.EEquation inEquation;
  input Env inEnv;
  input Prefix inPrefix;
  output Equation outEquation;
algorithm
  outEquation := match(inEquation, inEnv, inPrefix)
    local
      Absyn.Exp exp1, exp2;
      DAE.Exp dexp1, dexp2;

    case (SCode.EQ_EQUALS(exp1, exp2, _, _), _, _)
      equation
        dexp1 = instExp(exp1, inEnv, inPrefix);
        dexp2 = instExp(exp2, inEnv, inPrefix);
      then
        InstTypes.EQUALITY_EQUATION(dexp1, dexp2);

    else
      equation
        print("Unknown equation in SCodeInst.instEEquation.\n");
      then
        fail();

  end match;
end instEEquation;

protected function instGlobalConstants
  input list<Absyn.Path> inGlobalConstants;
  input Absyn.Path inClassPath;
  input Env inEnv;
  output list<Element> outElements;
algorithm
  outElements := matchcontinue(inGlobalConstants, inClassPath, inEnv)
    local
      list<Element> el;
      Element ss;

    case (_, _, _)
      equation
        el = List.map2(inGlobalConstants, instGlobalConstant, inClassPath, inEnv);
        ss = instGlobalConstant2(SCodeLookup.BUILTIN_STATESELECT,
          Absyn.IDENT("StateSelect"), false, {});
      then
        ss :: el;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("SCodeInst.instGlobalConstants failed\n");
      then
        fail();

  end matchcontinue;
end instGlobalConstants;

protected function instGlobalConstant
  input Absyn.Path inPath;
  input Absyn.Path inClassPath;
  input Env inEnv;
  output Element outElement;
algorithm
  outElement := matchcontinue(inPath, inClassPath, inEnv)
    local
      Item item;
      Env env;
      Boolean loc;
      
    case (_, _, _)
      equation
        (item, _, env) = SCodeLookup.lookupFullyQualified(inPath, inEnv);
        loc = Absyn.pathPrefixOf(inClassPath, inPath);
      then
        instGlobalConstant2(item, inPath, loc, env);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("SCodeInst.instGlobalConstant failed on " +&
          Absyn.pathString(inPath) +& "\n");
      then
        fail();

  end matchcontinue;
end instGlobalConstant;

protected function instGlobalConstant2
  input Item inItem;
  input Absyn.Path inPath;
  input Boolean inLocal;
  input Env inEnv;
  output Element outElement;
algorithm
  outElement := matchcontinue(inItem, inPath, inLocal, inEnv)
    local
      Absyn.Path path, pre_path;
      Prefix prefix;
      SCode.Element el;
      list<SCode.Enum> enuml;
      DAE.Type ty, arr_ty;
      list<Element> enum_el;
      list<DAE.Exp> enum_exps;
      Integer enum_count;
      DAE.Exp bind_exp;
      Binding binding;
      Absyn.Info info;
      Element iel;

    case (SCodeEnv.VAR(var = el), _, true, _)
      equation
        iel = instElement(el, InstTypes.NOMOD(), InstTypes.NO_PREFIXES(), inEnv,
          InstTypes.emptyPrefix);
        pre_path = Absyn.pathPrefix(inPath);
        prefix = InstUtil.pathPrefix(pre_path);
        iel = InstUtil.prefixElement(iel, prefix);
      then  
        iel;
        
    case (SCodeEnv.VAR(var = el), _, false, _)
      equation
        pre_path = Absyn.pathPrefix(inPath);
        prefix = InstUtil.pathPrefix(pre_path);
      then
        instElement(el, InstTypes.NOMOD(), InstTypes.NO_PREFIXES(), inEnv,
          prefix);

    case (SCodeEnv.CLASS(cls = SCode.CLASS(classDef = 
        SCode.ENUMERATION(enumLst = enuml), info = info)), _, _, _)
      equation
        // Instantiate the literals.
        ty = InstUtil.makeEnumType(enuml, inPath);
        enum_el = instEnumLiterals(enuml, inPath, ty, 1, {});
        // Create a binding for the enumeration type, i.e. an array of all
        // literals.
        enum_exps = List.map(enum_el, makeEnumExpFromElement);
        enum_count = listLength(enum_exps);
        arr_ty = DAE.T_ARRAY(ty, {DAE.DIM_INTEGER(enum_count)}, DAE.emptyTypeSource);
        bind_exp = DAE.ARRAY(arr_ty, true, enum_exps);
        // TODO: Check this, should it really be 1?
        binding = InstTypes.TYPED_BINDING(bind_exp, arr_ty, 1, info);
      then
        InstTypes.ELEMENT(InstTypes.TYPED_COMPONENT(inPath, ty, InstTypes.DEFAULT_CONST_PREFIXES, InstTypes.UNBOUND(), info),
          InstTypes.COMPLEX_CLASS(enum_el, {}, {}, {}, {}));

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("SCodeInst.instGlobalConstant failed on " +&
          Absyn.pathString(inPath) +& "\n");
      then
        fail();

  end matchcontinue;
end instGlobalConstant2;

protected function makeEnumExpFromElement
  input Element inElement;
  output DAE.Exp outExp;
algorithm
  InstTypes.ELEMENT(component = InstTypes.TYPED_COMPONENT(binding = 
    InstTypes.TYPED_BINDING(bindingExp = outExp))) := inElement;
end makeEnumExpFromElement;

protected function instConditionalComponents
  input Class inClass;
  input SymbolTable inSymbolTable;
  output Class outClass;
  output SymbolTable outSymbolTable;
algorithm
  (outClass, outSymbolTable) := match(inClass, inSymbolTable)
    local
      SymbolTable st;
      list<Element> comps;
      list<Equation> eq, ieq;
      list<SCode.AlgorithmSection> al, ial;

    case (InstTypes.COMPLEX_CLASS(comps, eq, ieq, al, ial), st)
      equation
        (comps, st) = instConditionalElements(comps, st, {});
      then
        (InstTypes.COMPLEX_CLASS(comps, eq, ieq, al, ial), st);

    else (inClass, inSymbolTable);

  end match;
end instConditionalComponents;

protected function instConditionalElements
  input list<Element> inElements;
  input SymbolTable inSymbolTable;
  input list<Element> inAccumEl;
  output list<Element> outElements;
  output SymbolTable outSymbolTable;
algorithm
  (outElements, outSymbolTable) := match(inElements, inSymbolTable, inAccumEl)
    local
      Element el;
      list<Element> rest_el, accum_el;
      SymbolTable st;
      Option<Element> oel;
      Component comp;
      Absyn.Path bc;
      Class cls;
      DAE.Type ty;

    case ({}, st, accum_el) then (listReverse(accum_el), st);

    case (el :: rest_el, st, accum_el)
      equation
        (oel, st) = instConditionalElement(el, st);
        accum_el = List.consOption(oel, accum_el);
        (accum_el, st) = instConditionalElements(rest_el, st, accum_el);
      then
        (accum_el, st);

  end match;
end instConditionalElements;
        
protected function instConditionalElementOnTrue
  input Boolean inCondition;
  input Element inElement;
  input SymbolTable inSymbolTable;
  output Option<Element> outElement;
  output SymbolTable outSymbolTable;
algorithm
  (outElement, outSymbolTable) := match(inCondition, inElement, inSymbolTable)
    local
      Option<Element> oel;
      SymbolTable st;

    case (true, _, st)
      equation
        (oel, st) = instConditionalElement(inElement, st);
      then
        (oel, st);

    else (NONE(), inSymbolTable);

  end match;
end instConditionalElementOnTrue;

protected function instConditionalElement
  input Element inElement;
  input SymbolTable inSymbolTable;
  output Option<Element> outElement;
  output SymbolTable outSymbolTable;
algorithm
  (outElement, outSymbolTable) := match(inElement, inSymbolTable)
    local
      Component comp;
      Class cls;
      SymbolTable st;
      Element el;
      Option<Element> oel;
      Absyn.Path bc;
      DAE.Type ty;

    case (InstTypes.ELEMENT(comp, cls), st)
      equation
        (cls, st) = instConditionalComponents(cls, st);
        el = InstTypes.ELEMENT(comp, cls);
      then
        (SOME(el), st);

    case (InstTypes.CONDITIONAL_ELEMENT(comp), st)
      equation
        (oel, st) = instConditionalComponent(comp, st);
      then
        (oel, st);

    case (InstTypes.EXTENDED_ELEMENTS(bc, cls, ty), st)
      equation
        (cls, st) = instConditionalComponents(cls, st);
        el = InstTypes.EXTENDED_ELEMENTS(bc, cls, ty);
      then
        (SOME(el), st);

    else (SOME(inElement), inSymbolTable);

  end match;
end instConditionalElement;

protected function instConditionalComponent
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output Option<Element> outElement;
  output SymbolTable outSymbolTable;
algorithm
  (outElement, outSymbolTable) := matchcontinue(inComponent, inSymbolTable)
    local
      SCode.Element sel;
      Absyn.Exp cond_exp;
      Env env;
      Prefix prefix;
      SymbolTable st;
      DAE.Exp inst_exp;
      DAE.Type ty;
      Boolean cond;
      Absyn.Info info;
      Absyn.Path name;
      Modifier mod;
      Option<Element> el;
      Prefixes prefs;

    case (InstTypes.CONDITIONAL_COMPONENT(name, sel as SCode.COMPONENT(condition = 
      SOME(cond_exp), info = info), mod, prefs, env, prefix), st)
      equation
        inst_exp = instExp(cond_exp, env, prefix);
        (inst_exp, ty, st) = Typing.typeExp(inst_exp, st);
        (inst_exp, _) = ExpressionSimplify.simplify(inst_exp);
        cond = evaluateConditionalExp(inst_exp, ty, name, info);
        (el, st) = instConditionalComponent2(cond, sel, mod, prefs, env, prefix, st);
      then
        (el, st);
         
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("SCodeInst.instConditionalComponent failed on " +&
          InstUtil.printComponent(inComponent) +& "\n");
      then
        fail();

  end matchcontinue;
end instConditionalComponent;

protected function instConditionalComponent2
  input Boolean inCondition;
  input SCode.Element inElement;
  input Modifier inMod;
  input Prefixes inPrefixes;
  input Env inEnv;
  input Prefix inPrefix;
  input SymbolTable inSymbolTable;
  output Option<Element> outElement;
  output SymbolTable outSymbolTable;
algorithm
  (outElement, outSymbolTable) := 
  match(inCondition, inElement, inMod, inPrefixes, inEnv, inPrefix, inSymbolTable)
    local
      SCode.Element sel;
      Element el;
      SymbolTable st;
      Boolean added;
      Option<Element> oel;

    case (true, _, _, _, _, _, st)
      equation
        // We need to remove the condition from the element, otherwise
        // instElement will just add it as a conditional component again.
        sel = SCode.removeComponentCondition(inElement);
        // Instantiate the element and update the symbol table.
        el = instElement(sel, inMod, inPrefixes, inEnv, inPrefix);
        (el, st, added) = InstSymbolTable.addInstCondElement(el, st);
        // Recursively instantiate any conditional components in this element.
        (oel, st) = instConditionalElementOnTrue(added, el, st);
      then
        (oel, st);

    else (NONE(), inSymbolTable);
  end match;
end instConditionalComponent2;

protected function evaluateConditionalExp
  input DAE.Exp inExp;
  input DAE.Type inType;
  input Absyn.Path inName;
  input Absyn.Info inInfo;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inExp, inType, inName, inInfo)
    local
      Boolean cond;
      String exp_str, name_str, ty_str;

    case (DAE.BCONST(bool = cond), DAE.T_BOOL(varLst = _), _, _) then cond;

    // TODO: remove this case once typing is fixed!
    case (DAE.BCONST(bool = cond), _, _, _) then cond;

    case (_, DAE.T_BOOL(varLst = _), _, _)
      equation
        // TODO: Return the variability of an expression from instExp, so that
        // we can see whether we got a variable expression here (which is an
        // error), or if we simply failed to evaluate it (which is a fault in
        // the compiler).
        exp_str = ExpressionDump.printExpStr(inExp);
        Error.addSourceMessage(Error.COMPONENT_CONDITION_VARIABILITY,
          {exp_str}, inInfo);
      then
        fail();

    case (_, _, _, _)
      equation
        exp_str = ExpressionDump.printExpStr(inExp);
        name_str = Absyn.pathString(inName);
        ty_str = Types.printTypeStr(inType);
        Error.addSourceMessage(Error.CONDITION_TYPE_ERROR,
          {exp_str, name_str, ty_str}, inInfo);
      then
        fail();

  end match;
end evaluateConditionalExp;
  
end SCodeInst;
