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

protected import ClassInf;
protected import ComponentReference;
protected import Connect;
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
protected import Util;

public type Binding = InstTypes.Binding;
public type Class = InstTypes.Class;
public type Component = InstTypes.Component;
public type Condition = InstTypes.Condition;
public type Dimension = InstTypes.Dimension;
public type Element = InstTypes.Element;
public type Env = SCodeEnv.Env;
public type Equation = InstTypes.Equation;
public type Function = InstTypes.Function;
public type Modifier = InstTypes.Modifier;
public type ParamType = InstTypes.ParamType;
public type Prefixes = InstTypes.Prefixes;
public type Prefix = InstTypes.Prefix;
public type Statement = InstTypes.Statement;

protected type FunctionSlot = InstTypes.FunctionSlot;
protected type Item = SCodeEnv.Item;
protected type SymbolTable = InstSymbolTable.SymbolTable;

protected uniontype InstPolicy
  record INST_ALL end INST_ALL;
  record INST_ONLY_CONST end INST_ONLY_CONST;
end InstPolicy;

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
        (cls, _, _) = instClassItem(item, InstTypes.NOMOD(), 
          InstTypes.NO_PREFIXES(), env, InstTypes.emptyPrefix, INST_ALL());
        const_el = instGlobalConstants(inGlobalConstants, inClassPath, inEnv);
        cls = InstUtil.addElementsToClass(const_el, cls);

        //print(InstUtil.printClass(cls));
        (cls, symtab) = InstSymbolTable.build(cls);
        (cls, symtab) = assignParamTypes(cls, symtab);
        (cls, symtab) = Typing.typeClass(cls, symtab);

        (cls, symtab) = instConditionalComponents(cls, symtab);
        (cls, symtab) = Typing.typeClass(cls, symtab);
        cls = Typing.typeSections(cls, symtab);

        System.stopTimer();
        //print("\nclass " +& name +& "\n");
        //print(InstUtil.printClass(cls));
        //print("\nend " +& name +& "\n");

        //print("SCodeInst took " +& realString(System.getTimerIntervalTime()) +& " seconds.\n");

        _ = SCodeExpand.expand(name, cls);
      then
        ();

    else
      equation
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
  input InstPolicy inInstPolicy;
  output Class outClass;
  output DAE.Type outType;
  output Prefixes outPrefixes;
algorithm
  (outClass, outType, outPrefixes) :=
  match(inItem, inMod, inPrefixes, inEnv, inPrefix, inInstPolicy)
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
      list<Equation> eq, ieq;
      list<list<Statement>> alg, ialg;
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
      SCode.Restriction res;
      ClassInf.State state;
      InstPolicy ip;
      SCode.Attributes attr;
      Prefixes prefs;

    case (SCodeEnv.CLASS(cls = SCode.CLASS(name = name), env = env,
        classType = SCodeEnv.BASIC_TYPE()), _, _, _, _, _) 
      equation
        vars = instBasicTypeAttributes(inMod, env);
        ty = instBasicType(name, inMod, vars);
      then 
        (InstTypes.BASIC_TYPE(), ty, InstTypes.NO_PREFIXES());

    // A class with parts, instantiate all elements in it.
    case (SCodeEnv.CLASS(cls = SCode.CLASS(name = name, restriction = res,
        classDef = cdef as SCode.PARTS(elementLst = el), info = info),
        env = {SCodeEnv.FRAME(clsAndVars = cls_and_vars)}), _, _, _, _, ip)
      equation
        // Enter the class scope and look up all class elements.
        env = SCodeEnv.mergeItemEnv(inItem, inEnv);
        el = List.map1(el, lookupElement, cls_and_vars);

        // Apply modifications to the elements and instantiate them.
        mel = SCodeMod.applyModifications(inMod, el, inPrefix, env);
        exts = SCodeEnv.getEnvExtendsFromTable(env);
        (elems, cse) = instElementList(mel, inPrefixes, exts, env, inPrefix, ip);

        // Instantiate all equation and algorithm sections.
        (eq, ieq, alg, ialg) = instSections(cdef, env, inPrefix, ip);

        // Create the class.
        state = ClassInf.start(res, Absyn.IDENT(name));
        (cls, ty) = InstUtil.makeClass(elems, eq, ieq, alg, ialg, state, cse);
      then
        (cls, ty, InstTypes.NO_PREFIXES());

    // A derived class, look up the inherited class and instantiate it.
    case (SCodeEnv.CLASS(cls = scls as SCode.CLASS(name = name, classDef =
        SCode.DERIVED(modifications = smod, typeSpec = dty, attributes = attr),
        restriction = res, info = info)), _, _, _, _, ip)
      equation
        // Look up the inherited class.
        (item, env) = SCodeLookup.lookupTypeSpec(dty, inEnv, info);
        path = Absyn.typeSpecPath(dty);

        // Merge the modifiers and instantiate the inherited class.
        dims = Absyn.typeSpecDimensions(dty);
        dim_count = listLength(dims);
        mod = SCodeMod.translateMod(smod, "", dim_count, inPrefix, inEnv);
        mod = SCodeMod.mergeMod(inMod, mod);
        (cls, ty, prefs) = instClassItem(item, mod, inPrefixes, env, inPrefix, ip);

        // Merge the attributes of this class with the prefixes of the inherited
        // class.
        prefs = InstUtil.mergePrefixesWithDerivedClass(path, scls, prefs);
        // Add any dimensions from this class to the resulting type.
        ty = liftArrayType(dims, ty, inEnv, inPrefix);

        state = ClassInf.start(res, Absyn.IDENT(name));
        ty = InstUtil.makeDerivedClassType(ty, state);
      then
        (cls, ty, prefs);
        
    case (SCodeEnv.CLASS(cls = scls, classType = SCodeEnv.CLASS_EXTENDS(), env = env),
        _, _, _, _, ip)
      equation
        (cls, ty) =
          instClassExtends(scls, inMod, inPrefixes, env, inEnv, inPrefix, ip);
      then
        (cls, ty, InstTypes.NO_PREFIXES());

    case (SCodeEnv.CLASS(cls = SCode.CLASS(classDef =
        SCode.ENUMERATION(enumLst = enums), info = info)), _, _, _, _, _)
      equation
        path = InstUtil.prefixToPath(inPrefix);
        ty = InstUtil.makeEnumType(enums, path);
      then
        (InstTypes.BASIC_TYPE(), ty, InstTypes.NO_PREFIXES());

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
  input InstPolicy inInstPolicy;
  output Class outClass;
  output DAE.Type outType;
algorithm
  (outClass, outType) := 
  matchcontinue(inClassExtends, inMod, inPrefixes, inClassEnv, inEnv, inPrefix,
      inInstPolicy)
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
      InstPolicy ip;

    case (SCode.CLASS(classDef = SCode.CLASS_EXTENDS(modifications = mod, 
        composition = cdef)), _, _, _, _, _, ip)
      equation
        (bc_path, info) = getClassExtendsBaseClass(inClassEnv);
        ext = SCode.EXTENDS(bc_path, SCode.PUBLIC(), mod, NONE(), info);
        cdef = SCode.addElementToCompositeClassDef(ext, cdef);
        scls = SCode.setElementClassDefinition(cdef, inClassExtends);
        item = SCodeEnv.CLASS(scls, inClassEnv, SCodeEnv.USERDEFINED());
        (cls, ty, _) = instClassItem(item, inMod, inPrefixes, inEnv, inPrefix, ip);
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
        DAE.TYPES_VAR(ident, DAE.dummyAttrParam, ty, binding, NONE());

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
  input InstPolicy inInstPolicy;
  output list<Element> outElements;
  output Boolean outContainsSpecialExtends;
algorithm
  (outElements, outContainsSpecialExtends) := instElementList2(inElements, 
    inPrefixes, inExtends, inEnv, inPrefix, inInstPolicy, {}, false);
end instElementList;

protected function instElementList2
  input list<tuple<SCode.Element, Modifier>> inElements;
  input Prefixes inPrefixes;
  input list<SCodeEnv.Extends> inExtends;
  input Env inEnv;
  input Prefix inPrefix;
  input InstPolicy inInstPolicy;
  input list<Element> inAccumEl;
  input Boolean inContainsSpecialExtends;
  output list<Element> outElements;
  output Boolean outContainsSpecialExtends;
algorithm
  (outElements, outContainsSpecialExtends) :=
  match(inElements, inPrefixes, inExtends, inEnv, inPrefix, inInstPolicy,
      inAccumEl, inContainsSpecialExtends)
    local
      tuple<SCode.Element, Modifier> elem;
      list<tuple<SCode.Element, Modifier>> rest_el;
      Boolean cse;
      list<Element> accum_el;
      list<SCodeEnv.Extends> exts;

    case (elem :: rest_el, _, exts, _, _, _, accum_el, cse)
      equation
        (accum_el, exts, cse) = instElementList_dispatch(elem, inPrefixes, exts,
          inEnv, inPrefix, inInstPolicy, accum_el, cse);
        (accum_el, cse) = instElementList2(rest_el, inPrefixes, exts,
          inEnv, inPrefix, inInstPolicy, accum_el, cse);
      then
        (accum_el, cse);

    case ({}, _, {}, _, _, _, _, cse) then (inAccumEl, cse);

    case ({}, _, _ :: _, _, _, _, _, _)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"SCodeInst.instElementList2 has extends left!."});
      then
        fail();

  end match;
end instElementList2;

protected function instElementList_dispatch
  input tuple<SCode.Element, Modifier> inElement;
  input Prefixes inPrefixes;
  input list<SCodeEnv.Extends> inExtends;
  input Env inEnv;
  input Prefix inPrefix;
  input InstPolicy inInstPolicy;
  input list<Element> inAccumEl;
  input Boolean inContainsSpecialExtends;
  output list<Element> outElements;
  output list<SCodeEnv.Extends> outExtends;
  output Boolean outContainsSpecialExtends;
algorithm
  (outElements, outExtends, outContainsSpecialExtends) :=
  match(inElement, inPrefixes, inExtends, inEnv, inPrefix, inInstPolicy,
      inAccumEl, inContainsSpecialExtends)
    local
      SCode.Element elem;
      Modifier mod;
      Element res;
      Option<Element> ores;
      Boolean cse;
      list<Element> accum_el;
      list<SCodeEnv.Redeclaration> redecls;
      list<SCodeEnv.Extends> rest_exts;
      String name;
      InstPolicy ip;

    case ((elem as SCode.COMPONENT(name = _), mod), _, _, _, _, INST_ALL(), _, cse)
      equation
        res = instElement(elem, mod, inPrefixes, inEnv, inPrefix, inInstPolicy);
      then
        (res :: inAccumEl, inExtends, cse);

    case ((elem as SCode.COMPONENT(attributes = SCode.ATTR(variability =
        SCode.CONST())), mod), _, _, _, _, INST_ONLY_CONST(), _, cse)
      equation
        res = instElement(elem, mod, inPrefixes, inEnv, inPrefix, inInstPolicy);
      then
        (res :: inAccumEl, inExtends, cse);

    case ((elem as SCode.EXTENDS(baseClassPath = _), mod), _,
        SCodeEnv.EXTENDS(redeclareModifiers = redecls) :: rest_exts, _, _, ip, _, _)
      equation
        (res, cse) = instExtends(elem, mod, inPrefixes, redecls, inEnv, inPrefix, ip);
        cse = inContainsSpecialExtends or cse;
      then
        (res :: inAccumEl, rest_exts, cse);

    case ((elem as SCode.CLASS(name = name, restriction = SCode.R_PACKAGE()),
        mod), _, _, _, _, ip, _, cse)
      equation
        ores = instPackageConstants(elem, mod, inEnv, inPrefix);
        accum_el = List.consOption(ores, inAccumEl);
      then
        (accum_el, inExtends, cse);

    case ((SCode.EXTENDS(baseClassPath = _), _), _, {}, _, _, _, _, _)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
        {"SCodeInst.instElementList_dispatch ran out of extends!."});
      then
        fail();

    else (inAccumEl, inExtends, inContainsSpecialExtends);

  end match;
end instElementList_dispatch;

protected function instElement
  input SCode.Element inElement;
  input Modifier inClassMod;
  input Prefixes inPrefixes;
  input Env inEnv;
  input Prefix inPrefix;
  input InstPolicy inInstPolicy;
  output Element outElement;
algorithm
  outElement := 
  match(inElement, inClassMod, inPrefixes, inEnv, inPrefix, inInstPolicy)
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
      Prefixes prefs, cls_prefs;
      Integer dim_count;
      InstPolicy ip;
      Absyn.Exp cond_exp;
      DAE.Exp inst_exp;
      ParamType pty;

    case (SCode.COMPONENT(name = name, 
        prefixes = SCode.PREFIXES(innerOuter = Absyn.OUTER())), _, _, _, _, _)
      equation
        prefix = InstUtil.addPrefix(name, {}, inPrefix);
        path = InstUtil.prefixToPath(prefix);
        comp = InstTypes.OUTER_COMPONENT(path, NONE());
      then
        InstTypes.ELEMENT(comp, InstTypes.BASIC_TYPE());

    // A component, look up it's type and instantiate that class.
    case (SCode.COMPONENT(name = name, attributes = SCode.ATTR(arrayDims = ad),
        typeSpec = Absyn.TPATH(path = path), modifications = smod,
        condition = NONE(), info = info), _, _, _, _, ip)
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
        prefs = InstUtil.mergePrefixesFromComponent(path, inElement, inPrefixes);
        pty = InstUtil.paramTypeFromPrefixes(prefs);

        // Apply redeclarations to the class definition and instantiate it.
        redecls = SCodeFlattenRedeclare.extractRedeclaresFromModifier(smod);
        (item, env) = SCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(
          redecls, item, env, inEnv, inPrefix);
        (cls, ty, cls_prefs) = instClassItem(item, mod, prefs, env, prefix, ip);
        prefs = InstUtil.mergePrefixes(prefs, cls_prefs, path, "variable");

        // Add dimensions from the class type.
        (dims, dim_count) = addDimensionsFromType(dims, ty);
        ty = InstUtil.arrayElementType(ty);
        dim_arr = InstUtil.makeDimensionArray(dims);

        // Instantiate the binding.
        mod = SCodeMod.propagateMod(mod, dim_count);
        binding = SCodeMod.getModifierBinding(mod);
        binding = instBinding(binding, dim_count);

        // Create the component and add it to the program.
        comp = InstTypes.UNTYPED_COMPONENT(path, ty, dim_arr, prefs, pty, binding, info);
      then
        InstTypes.ELEMENT(comp, cls);

    // A conditional component, save it for later.
    case (SCode.COMPONENT(name = name, condition = SOME(cond_exp), info = info),
        _, _, _, _, _)
      equation
        path = InstUtil.prefixPath(Absyn.IDENT(name), inPrefix);
        inst_exp = instExp(cond_exp, inEnv, inPrefix);
        comp = InstTypes.CONDITIONAL_COMPONENT(path, inst_exp, inElement,
          inClassMod, inPrefixes, inEnv, inPrefix, info);
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
  input InstPolicy inInstPolicy;
  output Element outElement;
  output Boolean outContainsSpecialExtends;
algorithm
  (outElement, outContainsSpecialExtends) :=
  match(inExtends, inClassMod, inPrefixes, inRedeclares, inEnv, inPrefix, inInstPolicy)
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
      InstPolicy ip;

    case (SCode.EXTENDS(baseClassPath = path, modifications = smod, info = info),
        _, _, _, _, _, ip)
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
        (cls, ty, _) = instClassItem(item, mod, inPrefixes, env, inPrefix, ip);
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
      Item item;
      Class cls;
      
    case (SCode.CLASS(partialPrefix = SCode.PARTIAL()), _, _, _)
      then NONE();

    case (SCode.CLASS(name = name), _, _, _)
      equation
        item = SCodeLookup.lookupInClass(name, inEnv);
        prefix = InstUtil.addPrefix(name, {}, inPrefix);
        (cls, _, _) = instClassItem(item, inMod, InstTypes.NO_PREFIXES(), inEnv,
          prefix, INST_ONLY_CONST());
        oel = makeConstantsPackage(prefix, cls);
      then
        oel;

    else NONE();

  end match;
end instPackageConstants;

protected function makeConstantsPackage
  input Prefix inPrefix;
  input Class inClass;
  output Option<Element> outElement;
algorithm
  outElement := match(inPrefix, inClass)
    local
      Absyn.Path name;
      Element el;

    case (_, InstTypes.COMPLEX_CLASS(_ :: _, {}, {}, {}, {}))
      equation
        name = InstUtil.prefixToPath(inPrefix);
        el = InstTypes.ELEMENT(InstTypes.PACKAGE(name), inClass);
      then
        SOME(el);

    case (_, InstTypes.COMPLEX_CLASS(components = _ :: _))
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"SCodeInst.makeConstantsPackage got complex class with equations or algorithms!"});
      then
        fail();

    else NONE();

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
  (outDimensions, outAddedDims) := matchcontinue(inDimensions, inType)
    local
      list<DAE.Dimension> dims;
      Integer added_dims;

    case (_, _)
      equation
        dims = Types.getDimensions(inType);
        added_dims = listLength(dims);
        dims = listAppend(inDimensions, dims);
      then
        (dims, added_dims);

    else (inDimensions, 0);

  end matchcontinue;
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
        dexp1 = instFunctionCall(acref, afargs, named_args, inEnv, inPrefix, Absyn.dummyInfo);
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
      Absyn.Path path;

    // If the name can be found in the local scope, call instLocalCref.
    case (_, _, _, _)
      equation
        (_, path, env, origin) = SCodeLookup.lookupNameInPackage(inCrefPath, inEnv);
        is_global = SCodeLookup.originIsGlobal(origin);
        cref = prefixLocalCref(inCref, inPrefix, inEnv, env, is_global);
      then
        cref;

    // Otherwise, look it up in the scopes above, and call instGlobalCref.
    case (_, _, _, _ :: env)
      equation
        (_, path, env, _) = SCodeLookup.lookupNameSilent(inCrefPath, env, Absyn.dummyInfo);
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
  input Absyn.Info inInfo;
  output DAE.Exp outCallExp;
algorithm
  outCallExp := match(inName, inPositionalArgs, inNamedArgs, inEnv, inPrefix, inInfo)
    local
      Absyn.Path call_path;
      DAE.ComponentRef cref;
      list<DAE.Exp> pos_args, args;
      list<tuple<String, DAE.Exp>> named_args;
      Class func;
      list<Element> inputs, outputs; 
      
    case (_, _, _, _, _, _)
      equation
        (call_path, InstTypes.FUNCTION(inputs=inputs,outputs=outputs)) = instFunction(inName, inEnv, inPrefix, inInfo);
        pos_args = instExpList(inPositionalArgs, inEnv, inPrefix);
        named_args = List.map2(inNamedArgs, instNamedArg, inEnv, inPrefix);
        args = fillFunctionSlots(pos_args, named_args, inputs, call_path, inInfo);
      then
        DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther);

  end match;
end instFunctionCall;

protected function instFunction
  input Absyn.ComponentRef inName;
  input Env inEnv;
  input Prefix inPrefix;
  input Absyn.Info inInfo;
  output Absyn.Path outName;
  output Function outFunction;
algorithm
  (outName, outFunction) := match(inName, inEnv, inPrefix, inInfo)
    local
      Absyn.Path path;
      Item item;
      SCodeLookup.Origin origin;
      Env env;
      Class cls;
      Function func;
      list<Element> inputs, outputs, locals;
      list<list<Statement>> algorithms;
      list<Statement> stmts;

    case (_, _, _, _)
      equation
        path = Absyn.crefToPath(inName);
        (item, _, env, origin) = SCodeLookup.lookupFunctionName(path, inEnv, inInfo);
        path = instFunctionName(item, path, origin, env, inPrefix);
        (cls as InstTypes.COMPLEX_CLASS(algorithms=algorithms), _, _) = instClassItem(item, InstTypes.NOMOD(),
          InstTypes.NO_PREFIXES(), inEnv, inPrefix, INST_ALL());
        (inputs,outputs,locals) = getFunctionParameters(cls);
        stmts = List.flatten(algorithms);
      then
        (path, InstTypes.FUNCTION(inputs,outputs,locals,stmts));

  end match;
end instFunction;

protected function instFunctionName
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
end instFunctionName;

protected function instNamedArg
  input Absyn.NamedArg inNamedArg;
  input Env inEnv;
  input Prefix inPrefix;
  output tuple<String, DAE.Exp> outNamedArg;
protected
  String name;
  Absyn.Exp aexp;
  DAE.Exp dexp;
algorithm
  Absyn.NAMEDARG(argName = name, argValue = aexp) := inNamedArg;
  dexp := instExp(aexp, inEnv, inPrefix);
  outNamedArg := (name, dexp);
end instNamedArg;

protected function getFunctionParameters
  input Class inClass;
  output list<Element> outInputs;
  output list<Element> outOutputs;
  output list<Element> outLocals;
algorithm
  (outInputs, outOutputs, outLocals) := matchcontinue(inClass)
    local
      list<Element> comps, inputs, outputs, locals;

    case InstTypes.COMPLEX_CLASS(components = comps)
      equation
        (inputs, outputs, locals) = getFunctionParameters2(comps, {}, {}, {});
      then
        (inputs, outputs, locals);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- SCodeInst.getFunctionParameters failed.\n");
      then
        fail();

  end matchcontinue;
end getFunctionParameters;
  
protected function getFunctionParameters2
  input list<Element> inElements;
  input list<Element> inAccumInputs;
  input list<Element> inAccumOutputs;
  input list<Element> inAccumLocals;
  output list<Element> outInputs;
  output list<Element> outOutputs;
  output list<Element> outLocals;
algorithm
  (outInputs, outOutputs, outLocals) := match(inElements, inAccumInputs, inAccumOutputs, inAccumLocals)
    local
      Prefixes prefs;
      Absyn.Path name;
      DAE.Type ty;
      Absyn.Info info;
      Element el;
      list<Element> rest_el;
      list<Element> inputs, outputs, locals;

    case ((el as InstTypes.ELEMENT(component = InstTypes.UNTYPED_COMPONENT(
        name = name, baseType = ty, prefixes = prefs, info = info))) :: rest_el,
        inputs, outputs, locals)
      equation
        validateFunctionVariable(name, ty, prefs, info);
        (inputs, outputs, locals) = 
          getFunctionParameters3(name, prefs, info, el, inputs, outputs, locals);
        (inputs, outputs, locals) = getFunctionParameters2(rest_el, inputs, outputs, locals);
      then
        (inputs, outputs, locals);

    case ({}, _, _, _) then (inAccumInputs, inAccumOutputs, inAccumLocals);

  end match;
end getFunctionParameters2;

protected function getFunctionParameters3
  input Absyn.Path inName;
  input Prefixes inPrefixes;
  input Absyn.Info inInfo;
  input Element inElement;
  input list<Element> inAccumInputs;
  input list<Element> inAccumOutputs;
  input list<Element> inAccumLocals;
  output list<Element> outInputs;
  output list<Element> outOutputs;
  output list<Element> outLocals;
algorithm
  (outInputs, outOutputs, outLocals) := match(inName, inPrefixes, inInfo, inElement,
      inAccumInputs, inAccumOutputs, inAccumLocals)

    case (_, InstTypes.PREFIXES(direction = (Absyn.INPUT(), _)), _, _, _, _, _)
      equation
        validateFormalParameter(inName, inPrefixes, inInfo);
      then
        (inElement :: inAccumInputs, inAccumOutputs, inAccumLocals);

    case (_, InstTypes.PREFIXES(direction = (Absyn.OUTPUT(), _)), _, _, _, _, _)
      equation
        validateFormalParameter(inName, inPrefixes, inInfo);
      then
        (inAccumInputs, inElement :: inAccumOutputs, inAccumLocals);

    else
      equation
        validateLocalFunctionVariable(inName, inPrefixes, inInfo);
      then
        (inAccumInputs, inAccumOutputs, inElement :: inAccumLocals);

  end match;
end getFunctionParameters3;

protected function validateFunctionVariable
  input Absyn.Path inName;
  input DAE.Type inType;
  input Prefixes inPrefixes;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inName, inType, inPrefixes, inInfo)
    local
      String name, ty_str, io_str;
      Absyn.InnerOuter io;

    case (_, _, InstTypes.PREFIXES(innerOuter = Absyn.NOT_INNER_OUTER()), _) 
      equation
        true = Types.isValidFunctionVarType(inType); 
      then ();

    case (_, _, _, _)
      equation
        false = Types.isValidFunctionVarType(inType);
        name = Absyn.pathString(inName);
        ty_str = Types.getTypeName(inType);
        Error.addSourceMessage(Error.INVALID_FUNCTION_VAR_TYPE,
          {ty_str, name}, inInfo);
      then
        fail();

    // A formal parameter may not have an inner/outer prefix.
    case (_, _, InstTypes.PREFIXES(innerOuter = io), _)
      equation
        false = Absyn.isNotInnerOuter(io);
        name = Absyn.pathString(inName);
        io_str = Dump.unparseInnerouterStr(io);
        Error.addSourceMessage(Error.INNER_OUTER_FORMAL_PARAMETER,
          {io_str, name}, inInfo);
      then
        fail();

  end matchcontinue;
end validateFunctionVariable;

protected function validateFormalParameter
  input Absyn.Path inName;
  input Prefixes inPrefixes;
  input Absyn.Info inInfo;
algorithm
  _ := match(inName, inPrefixes, inInfo)
    local
      String name;

    // A formal parameter must be public.
    case (_, InstTypes.PREFIXES(visibility = SCode.PROTECTED()), _)
      equation
        name = Absyn.pathString(inName);
        Error.addSourceMessage(Error.PROTECTED_FORMAL_FUNCTION_VAR,
          {name}, inInfo);
      then
        fail();

    else ();
         
  end match;
end validateFormalParameter;

protected function validateLocalFunctionVariable
  input Absyn.Path inName;
  input Prefixes inPrefixes;
  input Absyn.Info inInfo;
algorithm
  _ := match(inName, inPrefixes, inInfo)
    local
      String name;

    // A local function variable must be protected.
    case (_, InstTypes.PREFIXES(visibility = SCode.PUBLIC()), _)
      equation
        name = Absyn.pathString(inName);
        Error.addSourceMessage(Error.NON_FORMAL_PUBLIC_FUNCTION_VAR, {name}, inInfo);
      then
        fail();

    else ();

  end match;
end validateLocalFunctionVariable;

protected function fillFunctionSlots
  input list<DAE.Exp> inPositionalArgs;
  input list<tuple<String, DAE.Exp>> inNamedArgs;
  input list<Element> inInputs;
  input Absyn.Path inFuncName;
  input Absyn.Info inInfo;
  output list<DAE.Exp> outArgs;
protected
  list<FunctionSlot> slots;
algorithm
  slots := makeFunctionSlots(inInputs, inPositionalArgs, {}, inFuncName, inInfo);
  slots := List.fold(inNamedArgs, fillFunctionSlot, slots);
  outArgs := List.map(slots, extractFunctionSlotExp);
end fillFunctionSlots;

protected function makeFunctionSlots
  input list<Element> inInputs;
  input list<DAE.Exp> inPositionalArgs;
  input list<FunctionSlot> inAccumSlots;
  input Absyn.Path inFuncName;
  input Absyn.Info inInfo;
  output list<FunctionSlot> outSlots;
algorithm
  outSlots := match(inInputs, inPositionalArgs, inAccumSlots, inFuncName, inInfo)
    local
      String param_name, name;
      Binding binding;
      list<Element> rest_inputs;
      Option<DAE.Exp> arg, default_value;
      list<DAE.Exp> rest_args;
      list<FunctionSlot> slots;

    // Last vararg input and no positional arguments means we're done.
    case ({InstTypes.ELEMENT(component = InstTypes.UNTYPED_COMPONENT(prefixes =
        InstTypes.PREFIXES(varArgs = InstTypes.IS_VARARG())))}, {}, _, _, _)
      then listReverse(inAccumSlots);

    // If the last input of the function is a vararg, handle it first
    case (rest_inputs as (InstTypes.ELEMENT(component = InstTypes.UNTYPED_COMPONENT(name =
        Absyn.IDENT(param_name), binding = binding, prefixes = InstTypes.PREFIXES(varArgs = InstTypes.IS_VARARG()))) :: {}),  _::_, slots, _, _)
      equation
        (arg, rest_args) = List.splitFirstOption(inPositionalArgs);
        default_value = InstUtil.getBindingExpOpt(binding);
        slots = InstTypes.SLOT(param_name, arg, default_value) :: slots;
      then
        makeFunctionSlots(rest_inputs, rest_args, slots, inFuncName, inInfo);  

    case (InstTypes.ELEMENT(component = InstTypes.UNTYPED_COMPONENT(name =
        Absyn.IDENT(param_name), binding = binding)) :: rest_inputs, _, slots, _, _)
      equation
        (arg, rest_args) = List.splitFirstOption(inPositionalArgs);
        default_value = InstUtil.getBindingExpOpt(binding);
        slots = InstTypes.SLOT(param_name, arg, default_value) :: slots;
      then
        makeFunctionSlots(rest_inputs, rest_args, slots, inFuncName, inInfo);  
        
    // No more inputs and positional arguments means we're done.
    case ({}, {}, _, _, _) then listReverse(inAccumSlots);

    // No more inputs but positional arguments left is an error.
    case ({}, _ :: _, _, _, _)
      equation
        // TODO: Make this a proper error message.
        print(Error.infoStr(inInfo) +& ": ");
        name = Absyn.pathString(inFuncName);
        print("SCodeInst.makeFunctionSlots: Too many arguments to function " +&
          name +& "\n");
      then
        fail();

  end match;
end makeFunctionSlots;
  
protected function fillFunctionSlot
  input tuple<String, DAE.Exp> inNamedArg;
  input list<FunctionSlot> inSlots;
  output list<FunctionSlot> outSlots;
algorithm
  outSlots := match(inNamedArg, inSlots)
    local
      String arg_name, slot_name;
      DAE.Exp arg;
      FunctionSlot slot;
      list<FunctionSlot> rest_slots;
      Boolean eq;

      case ((arg_name, _), (slot as InstTypes.SLOT(name = slot_name)) :: rest_slots)
        equation
          eq = stringEq(arg_name, slot_name);
        then
          fillFunctionSlot2(eq, inNamedArg, slot, rest_slots);

      case ((arg_name, _), {})
        equation
          print("No matching slot " +& arg_name +& "\n");
        then
          fail();

  end match;
end fillFunctionSlot;

protected function fillFunctionSlot2
  input Boolean inMatching;
  input tuple<String, DAE.Exp> inNamedArg;
  input FunctionSlot inSlot;
  input list<FunctionSlot> inRestSlots;
  output list<FunctionSlot> outSlots;
algorithm
  outSlots := match(inMatching, inNamedArg, inSlot, inRestSlots)
    local
      String name;
      DAE.Exp arg;
      FunctionSlot slot;
      list<FunctionSlot> slots;

    // Found a matching empty slot, fill it.
    case (true, (_, arg), InstTypes.SLOT(name = name, arg = NONE()), _)
      equation
        slot = InstTypes.SLOT(name, SOME(arg), NONE());
      then
        slot :: inRestSlots;
      
    // Slot not matching, search through the rest of the slots.
    case (false, _, _, _)
      equation
        slots = fillFunctionSlot(inNamedArg, inRestSlots);
      then
        inSlot :: slots;

    // Found a matching slot that is already filled, show error.
    case (true, _, InstTypes.SLOT(name = name, arg = SOME(_)), _)
      equation
        print("Slot " +& name +& " is already filled!\n");
      then
        fail();

  end match;
end fillFunctionSlot2;
        
protected function extractFunctionSlotExp
  input FunctionSlot inSlot;
  output DAE.Exp outExp;
algorithm
  outExp := match(inSlot)
    local
      DAE.Exp exp;
      String name;

    case InstTypes.SLOT(arg = SOME(exp)) then exp;
    case InstTypes.SLOT(defaultValue = SOME(exp)) then exp;
    case InstTypes.SLOT(name = name)
      equation
        print("Slot " +& name +& " has no value.\n");
      then
        fail();

  end match;
end extractFunctionSlotExp;

protected function assignParamTypes
  input Class inClass;
  input SymbolTable inSymbolTable;
  output Class outClass;
  output SymbolTable outSymbolTable;
algorithm
  (outClass, outSymbolTable) :=
    InstUtil.traverseClassComponents(inClass, inSymbolTable, assignParamTypesToComp);
end assignParamTypes;

protected function assignParamTypesToComp
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output Component outComponent;
  output SymbolTable outSymbolTable;
algorithm
  (outComponent, outSymbolTable) := match(inComponent, inSymbolTable)
    local
      array<Dimension> dims;
      DAE.Exp cond;
      SymbolTable st;

    case (InstTypes.UNTYPED_COMPONENT(dimensions = dims), st)
      equation
        st = Util.arrayFold(dims, assignParamTypesToDim, st);
      then
        (inComponent, st);

    case (InstTypes.CONDITIONAL_COMPONENT(condition = cond), st)
      equation
        st = markExpAsStructural(cond, st);
      then
        (inComponent, st);

    else (inComponent, inSymbolTable);

  end match;
end assignParamTypesToComp;

protected function assignParamTypesToDim
  input Dimension inDimension;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := match(inDimension, inSymbolTable)
    local
      DAE.Exp dim_exp;
      SymbolTable st;

    case (InstTypes.UNTYPED_DIMENSION(dimension = DAE.DIM_EXP(exp = dim_exp)), st)
      equation
        ((_, st)) = Expression.traverseExpTopDown(dim_exp,
          markDimExpAsStructuralTraverser, st);
      then
        st;

    else inSymbolTable;

  end match;
end assignParamTypesToDim;

protected function markDimExpAsStructuralTraverser
  input tuple<DAE.Exp, SymbolTable> inTuple;
  output tuple<DAE.Exp, Boolean, SymbolTable> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      DAE.Exp exp, index_exp;
      SymbolTable st;
      DAE.ComponentRef cref;

    case (((exp as DAE.CREF(componentRef = cref)), st))
      equation
        st = markParamAsStructural(cref, st);
        // TODO: Mark cref subscripts too.
      then
        ((exp, true, st));

    case (((exp as DAE.SIZE(sz = SOME(index_exp))), st))
      equation
        st = markExpAsStructural(index_exp, st);
      then
        ((exp, false, st));

    case ((exp, st)) then ((exp, true, st));

  end match;
end markDimExpAsStructuralTraverser;

protected function markExpAsStructural
  input DAE.Exp inExp;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  ((_, outSymbolTable)) := Expression.traverseExp(inExp,
    markExpAsStructuralTraverser, inSymbolTable);
end markExpAsStructural;

protected function markExpAsStructuralTraverser
  input tuple<DAE.Exp, SymbolTable> inTuple;
  output tuple<DAE.Exp, SymbolTable> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      DAE.ComponentRef cref;
      DAE.Exp exp;
      SymbolTable st;

    case (((exp as DAE.CREF(componentRef = cref)), st))
      equation
        st = markParamAsStructural(cref, st);
      then
        ((exp, st));

    else inTuple;

  end match;
end markExpAsStructuralTraverser;

protected function markParamAsStructural
  input DAE.ComponentRef inCref;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := matchcontinue(inCref, inSymbolTable)
    local
      SymbolTable st;
      Component comp;
      DAE.ComponentRef cref;

    case (_, st)
      equation
        (comp, st) = InstSymbolTable.lookupCrefResolveOuter(inCref, st);
        st = markComponentAsStructural(comp, st);
      then
        st;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- SCodeInst.markParamAsStructural failed on " +&
          ComponentReference.printComponentRefStr(inCref) +& "\n");
      then
        fail();

  end matchcontinue;
end markParamAsStructural;
        
protected function markComponentAsStructural
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := match(inComponent, inSymbolTable)
    local
      Absyn.Path name;
      DAE.Type ty;
      array<Dimension> dims;
      Prefixes prefs;
      Binding binding;
      Absyn.Info info;
      SymbolTable st;
      Component comp;

    // Already marked as structural.
    case (InstTypes.UNTYPED_COMPONENT(paramType = InstTypes.STRUCT_PARAM()), _)
      then inSymbolTable;

    case (InstTypes.UNTYPED_COMPONENT(name, ty, dims, prefs, _, binding, info), st)
      equation
        st = markBindingAsStructural(binding, st);
        comp = InstTypes.UNTYPED_COMPONENT(name, ty, dims, prefs,
          InstTypes.STRUCT_PARAM(), binding, info);
        st = InstSymbolTable.updateComponent(comp, st);
      then
        st;
        
    case (InstTypes.OUTER_COMPONENT(name = _), _)
      equation
        print("SCodeInst.markComponentAsStructural: IMPLEMENT ME!\n");
      then
        fail();

    case (InstTypes.CONDITIONAL_COMPONENT(name = _), _)
      equation
        print("SCodeInst.markComponentAsStructural: conditional component used as structural parameter!\n");
      then
        fail();

    else inSymbolTable;
  end match;
end markComponentAsStructural;

protected function markBindingAsStructural
  input Binding inBinding;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := match(inBinding, inSymbolTable)
    local
      DAE.Exp bind_exp;

    case (InstTypes.UNTYPED_BINDING(bindingExp = bind_exp), _)
      then markExpAsStructural(bind_exp, inSymbolTable);

    else inSymbolTable;

  end match;
end markBindingAsStructural;

protected function instSections
  input SCode.ClassDef inClassDef;
  input Env inEnv;
  input Prefix inPrefix;
  input InstPolicy inInstPolicy;
  output list<Equation> outEquations;
  output list<Equation> outInitialEquations;
  output list<list<Statement>> outStatements;
  output list<list<Statement>> outInitialStatements;
algorithm
  (outEquations, outInitialEquations, outStatements, outInitialStatements) :=
  match(inClassDef, inEnv, inPrefix, inInstPolicy)
    local
      list<SCode.Equation> snel, siel;
      list<SCode.AlgorithmSection> snal, sial;
      list<Equation> inel, iiel;
      list<list<Statement>> inal, iial;

    case (SCode.PARTS(normalEquationLst = snel, initialEquationLst = siel, normalAlgorithmLst = snal, initialAlgorithmLst = sial), _,
        _, INST_ALL())
      equation
        inel = instEquations(snel, inEnv, inPrefix);
        iiel = instEquations(siel, inEnv, inPrefix);
        inal = instAlgorithmSections(snal, inEnv, inPrefix);
        iial = instAlgorithmSections(sial, inEnv, inPrefix);
      then
        (inel, iiel, inal, iial);

    case (_, _, _, INST_ONLY_CONST()) then ({}, {}, {}, {});

  end match;
end instSections;

protected function instEquations
  input list<SCode.Equation> inEquations;
  input Env inEnv;
  input Prefix inPrefix;
  output list<Equation> outEquations;
algorithm
  outEquations := List.map2(inEquations, instEquation, inEnv, inPrefix);
  //outEquations := {};
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

protected function instEEquations
  input list<SCode.EEquation> inEquations;
  input Env inEnv;
  input Prefix inPrefix;
  output list<Equation> outEquations;
algorithm
  outEquations := List.map2(inEquations, instEEquation, inEnv, inPrefix);
end instEEquations;

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
      Absyn.ComponentRef cref1, cref2;
      DAE.ComponentRef dcref1, dcref2;
      Absyn.Info info;
      String for_index;
      list<SCode.EEquation> eql;
      list<Equation> ieql;
      list<Absyn.Exp> if_condition, expl, args;
      list<list<SCode.EEquation>> if_branches;
      list<tuple<DAE.Exp, list<Equation>>> inst_branches;
      list<tuple<Absyn.Exp, list<SCode.EEquation>>> when_branches;
      list<DAE.Exp> iexpl, iargs;
      list<Absyn.NamedArg> nargs;
      Env env;
      Absyn.Path func_path;
      Item item;
      Class cls;

    case (SCode.EQ_EQUALS(exp1, exp2, _, info), _, _)
      equation
        dexp1 = instExp(exp1, inEnv, inPrefix);
        dexp2 = instExp(exp2, inEnv, inPrefix);
      then
        InstTypes.EQUALITY_EQUATION(dexp1, dexp2, info);

    // To determine whether a connected component is inside or outside we need
    // to know the type of the first identifier in the cref. Since it's illegal
    // to connect to global constants we can just save the prefix until we do
    // the typing, which means that we can then determine this with a hashtable
    // lookup.
    case (SCode.EQ_CONNECT(crefLeft = cref1, crefRight = cref2, info = info), _, _)
      equation
        dcref1 = instCref2(cref1, inEnv, inPrefix);
        dcref2 = instCref2(cref2, inEnv, inPrefix);
      then
        InstTypes.CONNECT_EQUATION(dcref1, Connect.NO_FACE(), DAE.T_UNKNOWN_DEFAULT,
          dcref2, Connect.NO_FACE(), DAE.T_UNKNOWN_DEFAULT, inPrefix, info);

    case (SCode.EQ_FOR(index = for_index, range = SOME(exp1), eEquationLst = eql,
        info = info), _, _)
      equation
        env = SCodeEnv.extendEnvWithIterators(
          {Absyn.ITERATOR(for_index, NONE(), NONE())}, inEnv);
        dexp1 = instExp(exp1, env, inPrefix);
        ieql = instEEquations(eql, env, inPrefix);
      then
        InstTypes.FOR_EQUATION(for_index, DAE.T_UNKNOWN_DEFAULT, SOME(dexp1), ieql, info);

    case (SCode.EQ_FOR(index = for_index, range = NONE(), eEquationLst = eql,
        info = info), _, _)
      equation
        env = SCodeEnv.extendEnvWithIterators({Absyn.ITERATOR(for_index, NONE(), NONE())}, inEnv);
        ieql = instEEquations(eql, env, inPrefix);
      then
        InstTypes.FOR_EQUATION(for_index, DAE.T_UNKNOWN_DEFAULT, NONE(), ieql, info);

    case (SCode.EQ_IF(condition = if_condition, thenBranch = if_branches,
        elseBranch = eql, info = info), _, _)
      equation
        inst_branches = List.threadMap2Reverse(if_condition, if_branches,
          instIfBranch, inEnv, inPrefix);
        ieql = instEEquations(eql, inEnv, inPrefix);
        // Add else branch as a branch with condition true last in the list.
        inst_branches = listReverse((DAE.BCONST(true), ieql) :: inst_branches);
      then
        InstTypes.IF_EQUATION(inst_branches, info);
         
    case (SCode.EQ_WHEN(condition = exp1, eEquationLst = eql,
        elseBranches = when_branches, info = info), _, _)
      equation
        dexp1 = instExp(exp1, inEnv, inPrefix);
        ieql = instEEquations(eql, inEnv, inPrefix);
        inst_branches = List.map2(when_branches, instWhenBranch, inEnv, inPrefix); 
      then
        InstTypes.WHEN_EQUATION(inst_branches, info);

    case (SCode.EQ_ASSERT(condition = exp1, message = exp2, info = info), _, _)
      equation
        dexp1 = instExp(exp1, inEnv, inPrefix);
        dexp2 = instExp(exp2, inEnv, inPrefix);
      then
        InstTypes.ASSERT_EQUATION(dexp1, dexp2, info);

    case (SCode.EQ_TERMINATE(message = exp1, info = info), _, _)
      equation
        dexp1 = instExp(exp1, inEnv, inPrefix);
      then
        InstTypes.TERMINATE_EQUATION(dexp1, info);

    case (SCode.EQ_REINIT(cref = cref1, expReinit = exp1, info = info), _, _)
      equation
        dcref1 = instCref(cref1, inEnv, inPrefix);
        dexp1 = instExp(exp1, inEnv, inPrefix);
      then
        InstTypes.REINIT_EQUATION(dcref1, dexp1, info);
        
    case (SCode.EQ_NORETCALL(exp = exp1, info = info), _, _)
      equation
        dexp1 = instExp(exp1, inEnv, inPrefix);
      then
        InstTypes.NORETCALL_EQUATION(dexp1, info);

    else
      equation
        print("Unknown equation in SCodeInst.instEEquation.\n");
      then
        fail();

  end match;
end instEEquation;

protected function instAlgorithmSections
  input list<SCode.AlgorithmSection> inSections;
  input Env inEnv;
  input Prefix inPrefix;
  output list<list<Statement>> outStatements;
algorithm
  outStatements := List.map2(inSections, instAlgorithmSection, inEnv, inPrefix);
end instAlgorithmSections;

protected function instAlgorithmSection
  input SCode.AlgorithmSection inSection;
  input Env inEnv;
  input Prefix inPrefix;
  output list<Statement> outStatements;
protected
  list<SCode.Statement> sstatements;
algorithm
  SCode.ALGORITHM(statements=sstatements) := inSection;
  outStatements := List.map2(sstatements, instStatement, inEnv, inPrefix);
end instAlgorithmSection;

protected function instStatements
  input list<SCode.Statement> sstatements;
  input Env inEnv;
  input Prefix inPrefix;
  output list<Statement> outStatements;
algorithm
  outStatements := List.map2(sstatements, instStatement, inEnv, inPrefix);
end instStatements;

protected function instStatement
  input SCode.Statement statement;
  input Env inEnv;
  input Prefix inPrefix;
  output Statement outStatement;
algorithm
  outStatement := match (statement,inEnv,inPrefix)
    local
      Absyn.Exp exp1, exp2, if_condition;
      Absyn.Info info;
      DAE.Exp dexp1, dexp2;
      Env env;
      list<SCode.Statement> if_branch,else_branch,body;
      list<tuple<Absyn.Exp,list<SCode.Statement>>> elseif_branches,branches;
      list<tuple<DAE.Exp,list<Statement>>> inst_branches;
      list<Statement> ibody;
      String for_index;
    case (SCode.ALG_ASSIGN(exp1, exp2, _, info), _, _)
      equation
        dexp1 = instExp(exp1, inEnv, inPrefix);
        dexp2 = instExp(exp2, inEnv, inPrefix);
      then InstTypes.ASSIGN_STMT(dexp1, dexp2, info);

    case (SCode.ALG_FOR(index = for_index, range = SOME(exp1), forBody = body, info = info), _, _)
      equation
        env = SCodeEnv.extendEnvWithIterators({Absyn.ITERATOR(for_index, NONE(), NONE())}, inEnv);
        dexp1 = instExp(exp1, env, inPrefix);
        ibody = instStatements(body, env, inPrefix);
      then
        InstTypes.FOR_STMT(for_index, DAE.T_UNKNOWN_DEFAULT, SOME(dexp1), ibody, info);

    case (SCode.ALG_FOR(index = for_index, range = NONE(), forBody = body, info = info), _, _)
      equation
        env = SCodeEnv.extendEnvWithIterators({Absyn.ITERATOR(for_index, NONE(), NONE())}, inEnv);
        ibody = instStatements(body, env, inPrefix);
      then
        InstTypes.FOR_STMT(for_index, DAE.T_UNKNOWN_DEFAULT, NONE(), ibody, info);

    case (SCode.ALG_WHILE(boolExpr = exp1, whileBody = body, info = info), _, _)
      equation
        dexp1 = instExp(exp1, inEnv, inPrefix);
        ibody = instStatements(body, inEnv, inPrefix);
      then
        InstTypes.WHILE_STMT(dexp1, ibody, info);

    case (SCode.ALG_IF(boolExpr = if_condition, trueBranch = if_branch,
        elseIfBranch = elseif_branches,
        elseBranch = else_branch, info = info), _, _)
      equation
        elseif_branches = (if_condition,if_branch)::elseif_branches;
        /* Save some memory by making this more complicated than it is */
        inst_branches = List.map2_tail(elseif_branches,instStatementBranch,inEnv,inPrefix,{});
        inst_branches = List.map2_tail({(Absyn.BOOL(true),else_branch)},instStatementBranch,inEnv,inPrefix,inst_branches);
        inst_branches = listReverse(inst_branches);
      then
        InstTypes.IF_STMT(inst_branches, info);

    case (SCode.ALG_WHEN_A(branches = branches, info = info), _, _)
      equation
        inst_branches = List.map2(branches,instStatementBranch,inEnv,inPrefix);
      then
        InstTypes.WHEN_STMT(inst_branches, info);

      /*
    case (SCode.ALG_ASSIGN(exp1, exp2, _, info), _, _)
      equation
        dexp1 = instExp(exp1, inEnv, inPrefix);
        dexp2 = instExp(exp2, inEnv, inPrefix);
      then InstTypes.ASSIGN_STMT(dexp1, dexp2, info);
      */

  end match;
end instStatement;

protected function instIfBranch
  input Absyn.Exp inCondition;
  input list<SCode.EEquation> inBody;
  input Env inEnv;
  input Prefix inPrefix;
  output tuple<DAE.Exp, list<Equation>> outIfBranch;
protected
  DAE.Exp cond_exp;
  list<Equation> eql;
algorithm
  cond_exp := instExp(inCondition, inEnv, inPrefix);
  eql := instEEquations(inBody, inEnv, inPrefix);
  outIfBranch := (cond_exp, eql);
end instIfBranch;

protected function instStatementBranch
  input tuple<Absyn.Exp,list<SCode.Statement>> tpl;
  input Env inEnv;
  input Prefix inPrefix;
  output tuple<DAE.Exp, list<Statement>> outIfBranch;
protected
  Absyn.Exp cond;
  DAE.Exp icond;
  list<SCode.Statement> stmts;
  list<Statement> istmts;
algorithm
  (cond,stmts) := tpl;
  icond := instExp(cond, inEnv, inPrefix);
  istmts := instStatements(stmts, inEnv, inPrefix);
  outIfBranch := (icond, istmts);
end instStatementBranch;

protected function instWhenBranch
  input tuple<Absyn.Exp, list<SCode.EEquation>> inBranch;
  input Env inEnv;
  input Prefix inPrefix;
  output tuple<DAE.Exp, list<Equation>> outBranch;
protected
  Absyn.Exp aexp;
  list<SCode.EEquation> eql;
  DAE.Exp dexp;
  list<Equation> ieql;
algorithm
  (aexp, eql) := inBranch;
  dexp := instExp(aexp, inEnv, inPrefix);
  ieql := instEEquations(eql, inEnv, inPrefix);
  outBranch := (dexp, ieql);
end instWhenBranch;

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
          InstTypes.emptyPrefix, INST_ALL());
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
          prefix, INST_ALL());

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
        InstTypes.ELEMENT(InstTypes.TYPED_COMPONENT(inPath, ty,
            InstTypes.DEFAULT_CONST_DAE_PREFIXES, binding, info),
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
      list<list<Statement>> al, ial;

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
      Env env;
      Prefix prefix;
      SymbolTable st;
      DAE.Exp cond_exp;
      DAE.Type ty;
      Condition cond;
      Absyn.Info info;
      Absyn.Path name;
      Modifier mod;
      Option<Element> el;
      Prefixes prefs;

    case (InstTypes.CONDITIONAL_COMPONENT(name, cond_exp, sel, mod, prefs, env,
        prefix, info), st)
      equation
        (cond_exp, ty, st) = Typing.typeExp(cond_exp, Typing.EVAL_CONST_PARAM(), st);
        (cond_exp, _) = ExpressionSimplify.simplify(cond_exp);
        cond = evaluateConditionalExp(cond_exp, ty, name, info);
        (el, st) = instConditionalComponent2(cond, name, sel, mod, prefs, env, prefix, st);
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
  input Condition inCondition;
  input Absyn.Path inName;
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
  match(inCondition, inName, inElement, inMod, inPrefixes, inEnv, inPrefix, inSymbolTable)
    local
      SCode.Element sel;
      Element el;
      SymbolTable st;
      Boolean added;
      Option<Element> oel;
      Component comp;

    case (InstTypes.SINGLE_CONDITION(true), _, _, _, _, _, _, st)
      equation
        // We need to remove the condition from the element, otherwise
        // instElement will just add it as a conditional component again.
        sel = SCode.removeComponentCondition(inElement);
        // Instantiate the element and update the symbol table.
        el = instElement(sel, inMod, inPrefixes, inEnv, inPrefix, INST_ALL());
        (el, st, added) = InstSymbolTable.addInstCondElement(el, st);
        // Recursively instantiate any conditional components in this element.
        (oel, st) = instConditionalElementOnTrue(added, el, st);
      then
        (oel, st);

    case (InstTypes.SINGLE_CONDITION(false), _, _, _, _, _, _, st)
      equation
        comp = InstTypes.DELETED_COMPONENT(inName);
        st = InstSymbolTable.updateComponent(comp, inSymbolTable);
      then
        (NONE(), st);

    case (InstTypes.ARRAY_CONDITION(conditions = _), _, _, _, _, _, _, st)
      equation
        print("Sorry, complex arrays with conditional components are not yet supported.\n");
      then
        fail();

  end match;
end instConditionalComponent2;

protected function evaluateConditionalExp
  input DAE.Exp inExp;
  input DAE.Type inType;
  input Absyn.Path inName;
  input Absyn.Info inInfo;
  output Condition outCondition;
algorithm
  outCondition := match(inExp, inType, inName, inInfo)
    local
      Boolean cond;
      String exp_str, name_str, ty_str;
      DAE.Type ty;
      list<DAE.Exp> expl;
      list<Condition> condl;

    case (DAE.BCONST(bool = cond), DAE.T_BOOL(varLst = _), _, _)
      then InstTypes.SINGLE_CONDITION(cond);

    case (DAE.ARRAY(ty = ty, array = expl), DAE.T_BOOL(varLst = _), _, _)
      equation
        condl = List.map3(expl, evaluateConditionalExp, ty, inName, inInfo);
      then
        InstTypes.ARRAY_CONDITION(condl);

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
