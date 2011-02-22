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

encapsulated package SCodeDependency
" file:        SCodeDependency.mo
  package:     SCodeDependency
  description: SCode dependency analysis.

  RCS: $Id$

  Dependency analysis for SCode.
"

public import Absyn;
public import SCode;
public import SCodeEnv;

public type Env = SCodeEnv.Env;

protected import Error;
protected import SCodeLookup;
protected import SCodeUtil;
protected import Util;

protected type Item = SCodeEnv.Item;
protected type Extends = SCodeEnv.Extends;
protected type FrameType = SCodeEnv.FrameType;
protected type Import = Absyn.Import;

public function analyse
  "This is the entry point of the dependency analysis. The dependency analysis
  is done in three steps: first it analyses the program and marks each element in
  the program that's used. The it goes through the used classes and checks if
  they contain any class extends, and if so it checks of those class extends are
  used or not. Finally it collects the used elements and builds a new program
  and environment that only contains those elements."
  input Absyn.Path inClassName;
  input Env inEnv;
  input SCode.Program inProgram;
  output SCode.Program outProgram;
  output Env outEnv;
algorithm
  analyseClass(inClassName, inEnv, Absyn.dummyInfo);
  analyseClassExtends(inEnv);
  (outEnv, outProgram) := collectUsedProgram(inEnv, inProgram);
end analyse;

protected function analyseClass
  "Analyses a class by looking up the class, marking it as used and recursively
  analysing it's contents."
  input Absyn.Path inClassName;
  input Env inEnv;
  input Absyn.Info inInfo;
protected
  Item item;
  Option<Env> env;
algorithm
  (item, env) := lookupClass(inClassName, inEnv, inInfo);
  checkItemIsClass(item);
  analyseItem(item, env);
end analyseClass;

protected function lookupClass
  "Lookup a class in the environment. The reason why SCodeLookup is not used
  directly is because we need to look up each part of the class path and mark
  them as used."
  input Absyn.Path inPath;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Item outItem;
  output Option<Env> outEnv;
algorithm
  (outItem, outEnv) := matchcontinue(inPath, inEnv, inInfo)
    local
      Item item;
      Option<Env> opt_env;
      String name_str, env_str;

    case (_, _, _)
      equation
        (item, opt_env) = lookupClass2(inPath, inEnv, inInfo);
      then
        (item, opt_env);

    else
      equation
        name_str = Absyn.pathString(inPath);
        env_str = SCodeEnv.getEnvName(inEnv);
        Error.addSourceMessage(Error.LOOKUP_ERROR, {name_str, env_str}, inInfo);
      then
        fail();
  end matchcontinue;
end lookupClass;

protected function lookupClass2
  "Help function to lookupClass, does the actual look up."
  input Absyn.Path inPath;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Item outItem;
  output Option<Env> outEnv;
algorithm
  (outItem, outEnv) := match(inPath, inEnv, inInfo)
    local
      Item item;
      Env env;
      Option<Env> opt_env;
      String id;
      Absyn.Path rest_path;

    case (Absyn.IDENT(name = _), _, _)
      equation
        (item, _, opt_env) = 
          SCodeLookup.lookupName(inPath, inEnv, inInfo, NONE());
      then
        (item, opt_env);

    case (Absyn.QUALIFIED(name = id, path = rest_path), _, _)
      equation
        (item, _, SOME(env)) = 
          SCodeLookup.lookupName(Absyn.IDENT(id), inEnv, inInfo, NONE());
        analyseItem(item, SOME(env));
        env = SCodeEnv.mergeItemEnv(item, env);
        (item, opt_env) = lookupClass2(rest_path, env, inInfo);
      then  
        (item, opt_env);
  end match;
end lookupClass2;

protected function checkItemIsClass
  "Checks that the found item really is a class, otherwise prints an error
  message."
  input Item inItem;
algorithm
  _ := match(inItem)
    local
      String name;
      Absyn.Info info;

    case SCodeEnv.CLASS(cls = _) then ();

    // We found a component instead, which might happen if the user tries to use
    // a variable name as a type.
    case SCodeEnv.VAR(var = SCode.COMPONENT(component = name, info = info))
      equation
        Error.addSourceMessage(Error.LOOKUP_TYPE_FOUND_COMP, {name}, info);
      then
        fail();
  end match;
end checkItemIsClass;

protected function analyseItem
  "Analyzes an item."
  input Item inItem;
  input Option<Env> inEnv;
algorithm
  _ := matchcontinue(inItem, inEnv)
    local
      SCode.ClassDef cdef;
      SCodeEnv.Frame cls_env;
      Env env;
      Absyn.Info info;
      SCode.Ident name;
      SCode.Restriction res;

    // Check if the item is already marked as used, then we can stop here.
    case (_, _)
      equation
        true = SCodeEnv.isItemUsed(inItem);
      then
        ();

    // A component, mark it and it's environment as used.
    case (SCodeEnv.VAR(var = _), SOME(env))
      equation
        markItemAsUsed(inItem, env);
      then
        ();

    // A class without an environment is one of the builtin types (Real, etc.),
    // so we don't need to do anything here.
    case (SCodeEnv.CLASS(env = {}), _) then ();

    // A normal class, mark it and it's environment as used, and recursively
    // analyse it's contents.
    case (SCodeEnv.CLASS(cls = SCode.CLASS(classDef = cdef, restriction = res,
        info = info), env = {cls_env}), SOME(env))
      equation
        markItemAsUsed(inItem, env);
        env = cls_env :: env;
        analyseClassDef(cdef, env, info);
        analyseMetaType(res, env, info);
      then
        ();

  end matchcontinue;
end analyseItem;

protected function markItemAsUsed
  "Marks an item and it's environment as used."
  input Item inItem;
  input Env inEnv;
algorithm
  _ := match(inItem, inEnv)
    local
      SCodeEnv.Frame cls_env;
      Util.StatefulBoolean is_used;
      
    case (SCodeEnv.VAR(isUsed = is_used), _)
      equation
        Util.setStatefulBoolean(is_used, true);
        markEnvAsUsed(inEnv);
      then
        ();

    case (SCodeEnv.CLASS(env = {cls_env}), _)
      equation
        markFrameAsUsed(cls_env);
        markEnvAsUsed(inEnv);
      then
        ();
  end match;
end markItemAsUsed;

protected function markFrameAsUsed
  "Marks a single frame as used."
  input SCodeEnv.Frame inFrame;
protected
  Util.StatefulBoolean is_used;
algorithm
  SCodeEnv.FRAME(isUsed = is_used) := inFrame;
  Util.setStatefulBoolean(is_used, true);
end markFrameAsUsed;
        
protected function markEnvAsUsed
  "Marks an environment as used. This is done by marking each frame as used, and
  for each frame we also analyse the class it represents to make sure we don't
  miss anything in the enclosing scopes of an item."
  input Env inEnv;
algorithm
  _ := matchcontinue(inEnv)
    local
      Util.StatefulBoolean is_used;
      Env rest_env;
      SCodeEnv.Frame f;

    case ((f as SCodeEnv.FRAME(isUsed = is_used)) :: rest_env)
      equation
        false = Util.getStatefulBoolean(is_used);
        markEnvAsUsed2(f, rest_env);
        Util.setStatefulBoolean(is_used, true);
        markEnvAsUsed(rest_env);
      then
        ();

    else then ();
  end matchcontinue;
end markEnvAsUsed;

protected function markEnvAsUsed2
  "Helper function to markEnvAsUsed. Checks if the given frame belongs to a
  class, and if that's the case calls analyseClass on that class."
  input SCodeEnv.Frame inFrame;
  input SCodeEnv.Env inEnv;
algorithm
  _ := match(inFrame, inEnv)
    local
      String name;

    case (SCodeEnv.FRAME(frameType = SCodeEnv.IMPLICIT_SCOPE()), _) then ();

    case (SCodeEnv.FRAME(name = SOME(name)), _)
      equation
        analyseClass(Absyn.IDENT(name), inEnv, Absyn.dummyInfo);
      then
        ();
  end match;
end markEnvAsUsed2;

protected function analyseClassDef
  "Analyzes the contents of a class definition."
  input SCode.ClassDef inClassDef;
  input Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inClassDef, inEnv, inInfo)
    local
      list<SCode.Element> el;
      SCode.Element e1, e2;
      Absyn.Ident bc;
      SCode.Mod mods;
      Absyn.TypeSpec ty;
      list<SCode.Equation> nel, iel;
      list<SCode.AlgorithmSection> nal, ial;
      Option<SCode.Comment> cmt;
      list<SCode.Annotation> annl;
      Option<Absyn.ExternalDecl> ext_decl;
      Boolean is_ext_obj;

    // A class made of parts, analyse elements, equation, algorithms, etc.
    case (SCode.PARTS(elementLst = el, normalEquationLst = nel, 
        initialEquationLst = iel, normalAlgorithmLst = nal, 
        initialAlgorithmLst = ial, externalDecl = ext_decl,
        annotationLst = annl, comment = cmt), _, _)
      equation
        Util.listMap01(el, inEnv, analyseElement);
        Util.listMap01(nel, inEnv, analyseEquation);
        Util.listMap01(iel, inEnv, analyseEquation);
        Util.listMap01(nal, inEnv, analyseAlgorithm);
        Util.listMap01(ial, inEnv, analyseAlgorithm);
        analyseExternalDecl(ext_decl, inEnv, inInfo);
        Util.listMap02(annl, analyseAnnotation, inEnv, inInfo);
        analyseComment(cmt, inEnv, inInfo);
      then
        ();

    // The previous case failed, which might happen for an external object.
    // Check if the class definition is an external object and analyse it if
    // that's the case.
    case (SCode.PARTS(elementLst = el), _, _)
      equation
        isExternalObject(el, inEnv, inInfo);
        analyseClass(Absyn.IDENT("constructor"), inEnv, inInfo);
        analyseClass(Absyn.IDENT("destructor"), inEnv, inInfo);
      then
        ();

    // A class extends.
    case (SCode.CLASS_EXTENDS(baseClassName = bc, modifications = mods,
        elementLst = el, normalEquationLst = nel, initialEquationLst = iel,
        normalAlgorithmLst = nal, initialAlgorithmLst = ial, 
        annotationLst = annl, comment = cmt), _, _)
      equation
        analyseClass(Absyn.IDENT(bc), inEnv, inInfo);
        analyseModifier(mods, inEnv, inInfo);
        Util.listMap01(el, inEnv, analyseElement);
        Util.listMap01(nel, inEnv, analyseEquation);
        Util.listMap01(iel, inEnv, analyseEquation);
        Util.listMap01(nal, inEnv, analyseAlgorithm);
        Util.listMap01(ial, inEnv, analyseAlgorithm);
        Util.listMap02(annl, analyseAnnotation, inEnv, inInfo);
        analyseComment(cmt, inEnv, inInfo);
      then
        ();

    // A derived class definition.
    case (SCode.DERIVED(typeSpec = ty, modifications = mods, comment = cmt),
        _, _)
      equation
        checkRecursiveShortDefinition(ty, inEnv, inInfo);
        analyseTypeSpec(ty, inEnv, inInfo);
        analyseModifier(mods, inEnv, inInfo);
        analyseComment(cmt, inEnv, inInfo);
      then
        ();  

    // Other cases which doesn't need to be analysed.
    case (SCode.ENUMERATION(enumLst = _), _, _) then ();
    case (SCode.OVERLOAD(pathLst = _), _, _) then ();
    case (SCode.PDER(functionPath = _), _, _) then ();
  end matchcontinue;
end analyseClassDef;

protected function isExternalObject
  "Checks if a class definition is an external object."
  input list<SCode.Element> inElements;
  input Env inEnv;
  input Absyn.Info inInfo;
protected
  list<SCode.Element> el;
  list<String> el_names;
algorithm
  // Remove all 'extends ExternalObject'.
  el := Util.listFilter(inElements, isNotExternalObject);
  // Check if length of the new list is different to the old, i.e. if we
  // actually found an removed any 'extends ExternalObject'.
  false := (listLength(el) == listLength(inElements));
  // Ok, we have an external object, check that it's valid.
  el_names := Util.listMap(el, SCode.elementName);
  checkExternalObject(el_names, inEnv, inInfo);
end isExternalObject;

protected function isNotExternalObject
  "Fails on 'extends ExternalObject', otherwise succeeds."
  input SCode.Element inElement;
algorithm
  _ := match(inElement)
    case SCode.EXTENDS(baseClassPath = Absyn.IDENT("ExternalObject")) then fail();
    else then ();
  end match;
end isNotExternalObject;

protected function checkExternalObject
  "Checks that an external object is valid, i.e. has exactly one constructor and
  one destructor."
  input list<String> inElements;
  input Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := match(inElements, inEnv, inInfo)
    local
      String env_str;
      Boolean has_con, has_des;

    // Ok, we have both a constructor and a destructor.
    case ({"constructor", "destructor"}, _, _) then ();
    case ({"destructor", "constructor"}, _, _) then ();

    // Otherwise it's not valid, so print an error message.
    else
      equation
        has_con = Util.listContainsWithCompareFunc(
          "constructor", inElements, stringEqual);
        has_des = Util.listContainsWithCompareFunc(
          "destructor", inElements, stringEqual);
        env_str = SCodeEnv.getEnvName(inEnv);
        checkExternalObject2(inElements, has_con, has_des, env_str, inInfo);
      then 
        fail();

  end match;
end checkExternalObject;

protected function checkExternalObject2
  "Helper function to checkExternalObject. Prints an error message depending on
  what the external object contained."
  input list<String> inElements;
  input Boolean inHasConstructor;
  input Boolean inHasDestructor;
  input String inObjectName;
  input Absyn.Info inInfo;
algorithm
  _ := match(inElements, inHasConstructor, inHasDestructor, inObjectName, inInfo)
    local
      list<String> el;
      String el_str;

    // The external object contains both a constructor and a destructor, so it
    // has to also contain some invalid elements.
    case (el, true, true, _, _)
      equation
        // Remove the constructor and destructor from the list of elements.
        el = Util.listRemoveFirstOnTrue("constructor", stringEqual, el);
        el = Util.listRemoveFirstOnTrue("destructor", stringEqual, el);
        // Print an error message with the rest of the elements.
        el_str = Util.stringDelimitList(el, ", ");
        el_str = "contains invalid elements: " +& el_str;
        Error.addSourceMessage(Error.INVALID_EXTERNAL_OBJECT,
          {inObjectName, el_str}, inInfo);
      then
        ();

    // The external object is missing a constructor.
    case (_, false, true, _, _)
      equation
        Error.addSourceMessage(Error.INVALID_EXTERNAL_OBJECT,
          {inObjectName, "missing constructor"}, inInfo);
      then
        ();

    // The external object is missing a destructor.
    case (_, true, false, _, _)
      equation
        Error.addSourceMessage(Error.INVALID_EXTERNAL_OBJECT,
          {inObjectName, "missing destructor"}, inInfo);
      then
        ();

    // The external object is missing both a constructor and a destructor.
    case (_, false, false, _, _)
      equation
        Error.addSourceMessage(Error.INVALID_EXTERNAL_OBJECT,
          {inObjectName, "missing both constructor and destructor"}, inInfo);
      then
        ();
  end match;
end checkExternalObject2;

protected function checkRecursiveShortDefinition
  "Checks for recursive short definitions, i.e. class C = C."
  input Absyn.TypeSpec inTypeSpec;
  input Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inTypeSpec, inEnv, inInfo)
    local
      Absyn.Path path;
      String type_name, env_name;
      
    // The type does not have the same name as it's environment, probably ok.
    case (Absyn.TPATH(path = path), 
          SCodeEnv.FRAME(name = SOME(env_name)) :: _, _)
      equation
        type_name = Absyn.pathFirstIdent(path);
        false = stringEqual(type_name, env_name);
      then
        ();

    // The type has the same name as it's environment => recursive definition.
    case (Absyn.TPATH(path = path), 
          SCodeEnv.FRAME(name = SOME(env_name)) :: _, _)
      equation
        type_name = Absyn.pathString(path);
        Error.addSourceMessage(Error.RECURSIVE_SHORT_CLASS_DEFINITION, 
          {env_name, type_name}, inInfo);
      then
        fail();

    case (Absyn.TCOMPLEX(path = _), _, _) then ();
  end matchcontinue;
end checkRecursiveShortDefinition;

protected function analyseMetaType
  "If a metarecord is analysed we need to also analyse it's parent uniontype."
  input SCode.Restriction inRestriction;
  input Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := match(inRestriction, inEnv, inInfo)
    local
      Absyn.Path union_name;

    case (SCode.R_METARECORD(name = union_name), _, _)
      equation
        analyseClass(union_name, inEnv, inInfo);
      then
        ();

    else then ();
  end match;
end analyseMetaType;

protected function analyseElement
  "Analyzes an element."
  input SCode.Element inElement;
  input Env inEnv;
algorithm
  _ := match(inElement, inEnv)
    local
      Absyn.Path bc;
      SCode.Mod mods;
      Absyn.TypeSpec ty;
      Absyn.Info info;
      SCode.Attributes attr;
      Option<Absyn.Exp> cond_exp;
      Option<Absyn.ConstrainClass> cc;
      SCode.Class cls;

    // Fail on 'extends ExternalObject' so we can handle it as a special case in
    // analyseClassDef.
    case (SCode.EXTENDS(baseClassPath = Absyn.IDENT("ExternalObject")), _)
      then fail();

    // An extends-clause.
    case (SCode.EXTENDS(baseClassPath = bc, modifications = mods, info = info), _)
      equation
        true = checkNotExtendsDependent(bc, inEnv, info);
        analyseExtends(bc, inEnv, info);
        analyseModifier(mods, inEnv, info);
      then
        ();
        
    // A component.
    case (SCode.COMPONENT(attributes = attr, typeSpec = ty, modifications = mods, 
        condition = cond_exp, cc = cc, info = info), _)
      equation
        analyseAttributes(attr, inEnv, info);
        analyseTypeSpec(ty, inEnv, info);
        analyseModifier(mods, inEnv, info);
        analyseOptExp(cond_exp, inEnv, info);
        analyseConstrainClass(cc, inEnv, info);
      then
        ();

    // equalityConstraints may not be explicitly used but might be needed anyway
    // (if the record is used in a connect for example), so always mark it as used.
    case (SCode.CLASSDEF(name = "equalityConstraint", 
       classDef = cls as SCode.CLASS(info = info)), _)
      equation
        analyseClass(Absyn.IDENT("equalityConstraint"), inEnv, info);
      then
        ();

    else then ();
  end match;
end analyseElement;

protected function checkNotExtendsDependent
  "The Modelica specification 3.2 says (section 5.6.1): 'The lookup of the names
  of extended classes should give the same result before and after flattening
  the extends. One should not find any element used during this flattening by
  lookup through the extends-clauses.' This means that it's not allowed to have
  a name in an extends-clause that's inherited from another extends-clause. This
  function checks this, and returns true if an extends doesn't depend on an
  extend in the local scope."
  input Absyn.Path inBaseClass;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Boolean outResult;
algorithm
  outResult := matchcontinue(inBaseClass, inEnv, inInfo)
    local
      Absyn.Path bc;
      Absyn.Ident id;
      String bc_name;

    case (_, _, _)
      equation
        id = Absyn.pathFirstIdent(inBaseClass);
        bc = SCodeLookup.lookupBaseClass(id, inEnv, inInfo);
        bc_name = Absyn.pathString(bc);
        Error.addSourceMessage(Error.EXTENDS_INHERITED_FROM_LOCAL_EXTENDS,
          {bc_name, id}, inInfo);
      then
        false;

    else then true;
  end matchcontinue;
end checkNotExtendsDependent;

protected function analyseExtends
  "Analyzes an extends-clause."
  input Absyn.Path inClassName;
  input Env inEnv;
  input Absyn.Info inInfo;
protected
  Item item;
  Option<Env> env;
algorithm
  (item, _, env) := SCodeLookup.lookupBaseClassName(inClassName, inEnv, inInfo);
  analyseItem(item, env);
end analyseExtends;

protected function analyseAttributes
  "Analyzes a components attributes (actually only the array dimensions)."
  input SCode.Attributes inAttributes;
  input Env inEnv;
  input Absyn.Info inInfo;
protected
  Absyn.ArrayDim ad;
algorithm
  SCode.ATTR(arrayDims = ad) := inAttributes;
  Util.listMap02(ad, analyseSubscript, inEnv, inInfo);
end analyseAttributes;

protected function analyseModifier
  "Analyzes a modifier."
  input SCode.Mod inModifier;
  input Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := match(inModifier, inEnv, inInfo)
    local
      list<SCode.Element> el;
      list<SCode.SubMod> sub_mods;
      Option<tuple<Absyn.Exp, Boolean>> bind_exp;

    // No modifier.
    case (SCode.NOMOD(), _, _) then ();

    // A normal modifier, analyse it's submodifiers and optional binding.
    case (SCode.MOD(subModLst = sub_mods, binding = bind_exp), _, _)
      equation
        Util.listMap02(sub_mods, analyseSubMod, inEnv, inInfo);
        analyseModBinding(bind_exp, inEnv, inInfo);
      then
        ();

    // A redeclaration modifier, analyse the redeclarations.
    case (SCode.REDECL(elementLst = el), _, _)
      equation
        Util.listMap01(el, inEnv, analyseRedeclare);
      then
        ();
  end match;
end analyseModifier;

protected function analyseRedeclare
  "Analyzes a redeclaration element."
  input SCode.Element inElement;
  input Env inEnv;
algorithm
  _ := match(inElement, inEnv)
    local
      SCode.ClassDef cdef;
      Option<Absyn.ConstrainClass> cc;
      Absyn.Info info;

    // Class definitions are not analysed in analyseElement but are needed here
    // in case a class is redeclared.
    case (SCode.CLASSDEF(classDef = SCode.CLASS(classDef = cdef, info = info),
        cc = cc), _)
      equation
        analyseClassDef(cdef, inEnv, info);
        analyseConstrainClass(cc, inEnv, info);
      then
        ();

    // Otherwise we can just use analyseElements.
    else
      equation
        analyseElement(inElement, inEnv);
      then
        ();
  end match;
end analyseRedeclare;

protected function analyseConstrainClass
  "Analyzes a constrain class, i.e. given by constrainedby."
  input Option<Absyn.ConstrainClass> inCC;
  input Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := match(inCC, inEnv, inInfo)
    // TODO Add code here.
    case (_, _, _) then ();
  end match;
end analyseConstrainClass;

protected function analyseSubMod
  "Analyzes a submodifier."
  input SCode.SubMod inSubMod;
  input Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := match(inSubMod, inEnv, inInfo)
    local
      SCode.Mod m;
      list<SCode.Subscript> subs;

    case (SCode.NAMEMOD(A = m), _, _)
      equation
        analyseModifier(m, inEnv, inInfo);
      then
        ();

    case (SCode.IDXMOD(subscriptLst = subs, an = m), _, _)
      equation
        analyseModifier(m, inEnv, inInfo);
      then
        ();
  end match;
end analyseSubMod;

protected function analyseSubscript
  "Analyzes a subscript."
  input SCode.Subscript inSubscript;
  input Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := match(inSubscript, inEnv, inInfo)
    local
      Absyn.Exp sub_exp;

    case (Absyn.NOSUB(), _, _) then ();

    case (Absyn.SUBSCRIPT(sub_exp), _, _)
      equation
        analyseExp(sub_exp, inEnv, inInfo);
      then
        ();
  end match;
end analyseSubscript;

protected function analyseModBinding
  "Analyzes an optional modifier binding."
  input Option<tuple<Absyn.Exp, Boolean>> inBinding;
  input Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := match(inBinding, inEnv, inInfo)
    local
      Absyn.Exp bind_exp;

    case (NONE(), _, _) then ();

    case (SOME((bind_exp, _)), _, _)
      equation
        analyseExp(bind_exp, inEnv, inInfo);
      then
        ();
  end match;
end analyseModBinding;

protected function analyseTypeSpec
  "Analyzes a type specificer."
  input Absyn.TypeSpec inTypeSpec;
  input Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := match(inTypeSpec, inEnv, inInfo)
    local
      Absyn.Path type_path;
      list<Absyn.TypeSpec> tys;

    // A normal type.
    case (Absyn.TPATH(path = type_path), _, _)
      equation
        analyseClass(type_path, inEnv, inInfo);
      then
        ();

    // A polymorphic type, i.e. replaceable type Type subtypeof Any.
    case (Absyn.TCOMPLEX(path = Absyn.IDENT("polymorphic")), _, _)
      then ();

    // A MetaModelica type such as list or tuple.
    case (Absyn.TCOMPLEX(typeSpecs = tys), _, _)
      equation
        Util.listMap02(tys, analyseTypeSpec, inEnv, inInfo);
      then
        ();

  end match;
end analyseTypeSpec;

protected function analyseExternalDecl
  "Analyzes an external declaration."
  input Option<Absyn.ExternalDecl> inExtDecl;
  input Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := match(inExtDecl, inEnv, inInfo)
    local
      Absyn.Annotation ann;
      SCode.Annotation sann;

    // An external declaration might have an annotation that we need to analyse.
    case (SOME(Absyn.EXTERNALDECL(annotation_ = SOME(ann))), _, _)
      equation
        sann = SCodeUtil.translateAnnotation(ann);
        analyseAnnotation(sann, inEnv, inInfo);
      then
        ();

    else then ();
  end match;
end analyseExternalDecl;

protected function analyseComment
  "Analyzes an optional comment."
  input Option<SCode.Comment> inComment;
  input Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := match(inComment, inEnv, inInfo)
    local
      SCode.Annotation ann;

    // A comment might have an annotation that we need to analyse.
    case (SOME(SCode.COMMENT(annotation_ = SOME(ann))), _, _)
      equation
        analyseAnnotation(ann, inEnv, inInfo);
      then
        ();

    else then ();
  end match;
end analyseComment;

protected function analyseAnnotation
  "Analyzes an annotation."
  input SCode.Annotation inAnnotation;
  input Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := match(inAnnotation, inEnv, inInfo)
    local
      SCode.Mod mods;
      list<SCode.SubMod> sub_mods;

    case (SCode.ANNOTATION(modification = mods as SCode.MOD(subModLst = sub_mods)),
        _, _)
      equation
        Util.listMap02(sub_mods, analyseAnnotationMod, inEnv, inInfo);
      then
        ();

  end match;
end analyseAnnotation;

protected function analyseAnnotationMod
  "Analyzes an annotation modifier."
  input SCode.SubMod inMod;
  input Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inMod, inEnv, inInfo)
    local
      SCode.Mod mods;
      String id;

    // derivative is a bit special since it's not a builtin function, so just
    // analyse it's modifier to make sure that we get the derivation function.
    case (SCode.NAMEMOD(ident = "derivative", A = mods), _, _)
      equation
        analyseModifier(mods, inEnv, inInfo);
      then
        ();

    // Otherwise, try to analyse the modifier name, and if that succeeds also
    // try and analyse the rest of the modification. This is needed for example
    // for the graphical annotations such as Icon.
    case (SCode.NAMEMOD(ident = id, A = mods), _, _) 
      equation
        analyseAnnotationName(id, inEnv, inInfo);
        analyseModifier(mods, inEnv, inInfo);
      then
        ();

    else then ();
  end matchcontinue;
end analyseAnnotationMod;

protected function analyseAnnotationName
  "Analyzes an annotation name, such as Icon or Line."
  input SCode.Ident inName;
  input Env inEnv;
  input Absyn.Info inInfo;
protected
  Item item;
  Option<Env> opt_env;
algorithm
  (item, _, opt_env) := 
    SCodeLookup.lookupName(Absyn.IDENT(inName), inEnv, inInfo, NONE());
  analyseItem(item, opt_env);
end analyseAnnotationName;

protected function analyseExp
  "Recursively analyses an expression."
  input Absyn.Exp inExp;
  input Env inEnv;
  input Absyn.Info inInfo;
algorithm
  (_, _) := Absyn.traverseExpBidir(inExp, (analyseExpTraverserEnter,
    analyseExpTraverserExit, (inEnv, inInfo)));
end analyseExp;

protected function analyseOptExp
  "Recursively analyses an optional expression."
  input Option<Absyn.Exp> inExp;
  input Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := match(inExp, inEnv, inInfo)
    local
      Absyn.Exp exp;

    case (SOME(exp), _, _)
      equation
        analyseExp(exp, inEnv, inInfo);
      then
        ();

    else then ();
  end match;
end analyseOptExp;

protected function analyseExpTraverserEnter
  "Traversal enter function for use in analyseExp."
  input tuple<Absyn.Exp, tuple<Env, Absyn.Info>> inTuple;
  output tuple<Absyn.Exp, tuple<Env, Absyn.Info>> outTuple;
protected
  Absyn.Exp exp;
  Env env;
  Absyn.Info info;
algorithm
  (exp, (env, info)) := inTuple;
  env := analyseExp2(exp, env, info);
  outTuple := (exp, (env, info));
end analyseExpTraverserEnter;

protected function analyseExp2
  "Helper function to analyseExp, does the actual work."
  input Absyn.Exp inExp;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Env outEnv;
algorithm
  outEnv := match(inExp, inEnv, inInfo)
    local
      Absyn.ComponentRef cref;
      Absyn.FunctionArgs args;
      Absyn.ForIterators iters;
      Env env;

    case (Absyn.CREF(componentRef = cref), _, _)
      equation
        analyseCref(cref, inEnv, inInfo);
      then
        inEnv;
        
    case (Absyn.CALL(functionArgs = Absyn.FOR_ITER_FARG(iterators = iters)), _, _)
      equation
        env = SCodeEnv.extendEnvWithIterators(iters, inEnv);
      then
        env;

    case (Absyn.CALL(function_ = cref, functionArgs = args), _, _)
      equation
        analyseCref(cref, inEnv, inInfo);
      then
        inEnv;

    case (Absyn.PARTEVALFUNCTION(function_ = cref, functionArgs = args), _, _)
      equation
        analyseCref(cref, inEnv, inInfo);
      then
        inEnv;

    case (Absyn.MATCHEXP(matchTy = _), _, _)
      equation
        env = SCodeEnv.extendEnvWithMatch(inExp, inEnv);
      then
        env;

    else then inEnv;
  end match;
end analyseExp2;

protected function analyseCref
  "Analyzes a component reference."
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inCref, inEnv, inInfo)
    local
      Absyn.Path path;
      Item item;
      Option<Env> opt_env;

    case (Absyn.WILD(), _, _) then ();
      
    case (_, _, _)
      equation
        // We want to use lookupName since we need the item and environment, and
        // we don't care about any subscripts, so convert the cref to a path.
        path = Absyn.crefToPathIgnoreSubs(inCref);
        (item, _, opt_env) = SCodeLookup.lookupName(path, inEnv, inInfo, NONE());
        analyseItem(item, opt_env);
      then
        ();

    else then ();

  end matchcontinue;
end analyseCref;

protected function analyseExpTraverserExit
  "Traversal exit function for use in analyseExp."
  input tuple<Absyn.Exp, tuple<Env, Absyn.Info>> inTuple;
  output tuple<Absyn.Exp, tuple<Env, Absyn.Info>> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      Absyn.Exp e;
      Env env;
      Absyn.Info info;

    // Remove any scopes added by the enter function.

    case ((e as Absyn.CALL(functionArgs = Absyn.FOR_ITER_FARG(iterators = _)),
        (SCodeEnv.FRAME(frameType = SCodeEnv.IMPLICIT_SCOPE()) :: env, info)))
      then
        ((e, (env, info)));

    case ((e as Absyn.MATCHEXP(matchTy = _), 
        (SCodeEnv.FRAME(frameType = SCodeEnv.IMPLICIT_SCOPE()) :: env, info)))
      then
        ((e, (env, info)));

    else then inTuple;
  end match;
end analyseExpTraverserExit;

protected function analyseEquation
  "Analyzes an equation."
  input SCode.Equation inEquation;
  input Env inEnv;
protected
  SCode.EEquation equ;
algorithm
  SCode.EQUATION(equ) := inEquation;
  (_, _) := SCode.traverseEEquations(equ, (analyseEEquationTraverser, inEnv));
end analyseEquation;

protected function analyseEEquationTraverser
  "Traversal function for use in analyseEquation."
  input tuple<SCode.EEquation, Env> inTuple;
  output tuple<SCode.EEquation, Env> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      SCode.EEquation equ;
      SCode.Ident iter_name;
      Env env;
      Absyn.Info info;
      Absyn.ComponentRef cref1, cref2;

    case ((equ as SCode.EQ_FOR(index = iter_name, info = info), env))
      equation
        env = SCodeEnv.extendEnvWithIterators({(iter_name, NONE())}, env);
        (equ, _) = SCode.traverseEEquationExps(equ, (traverseExp, (env, info)));
      then
        ((equ, env));

    case ((equ as SCode.EQ_REINIT(cref = cref1, info = info), env))
      equation
        analyseCref(cref1, env, info);
        (equ, _) = SCode.traverseEEquationExps(equ, (traverseExp, (env, info)));
      then
        ((equ, env));

    case ((equ as SCode.EQ_NORETCALL(functionName = cref1, info = info), env))
      equation
        analyseCref(cref1, env, info);
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
end analyseEEquationTraverser;

protected function traverseExp
  "Traversal function used by analyseEEquationTraverser and
  analyseStatementTraverser."
  input tuple<Absyn.Exp, tuple<Env, Absyn.Info>> inTuple;
  output tuple<Absyn.Exp, tuple<Env, Absyn.Info>> outTuple;
protected
  Absyn.Exp exp;
  Env env;
  Absyn.Info info;
algorithm
  (exp, (env, info)) := inTuple;
  (exp, (_, _, (env, info))) := Absyn.traverseExpBidir(exp,
    (analyseExpTraverserEnter, analyseExpTraverserExit, (env, info)));
  outTuple := (exp, (env, info));
end traverseExp;

protected function analyseAlgorithm
  "Analyzes an algorithm."
  input SCode.AlgorithmSection inAlgorithm;
  input Env inEnv;
protected
  list<SCode.Statement> stmts;
algorithm
  SCode.ALGORITHM(stmts) := inAlgorithm;
  Util.listMap01(stmts, inEnv, analyseStatement);
end analyseAlgorithm;

protected function analyseStatement
  "Analyzes a statement in an algorithm."
  input SCode.Statement inStatement;
  input Env inEnv;
algorithm
  (_, _) := SCode.traverseStatements(inStatement, 
    (analyseStatementTraverser, inEnv));
end analyseStatement;

protected function analyseStatementTraverser
  "Traversal function used by analyseStatement."
  input tuple<SCode.Statement, Env> inTuple;
  output tuple<SCode.Statement, Env> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      Absyn.ForIterators iters;
      Env env;
      SCode.Statement stmt;
      Absyn.Info info;
      Absyn.ComponentRef cref;

    case ((stmt as SCode.ALG_FOR(iterators = iters, info = info), env))
      equation
        env = SCodeEnv.extendEnvWithIterators(iters, env);
        (_, _) = SCode.traverseStatementExps(stmt, (traverseExp, (env, info)));
      then
        ((stmt, env));

    case ((stmt as SCode.ALG_NORETCALL(functionCall = cref, info = info), env))
      equation
        analyseCref(cref, env, info);
        (_, _) = SCode.traverseStatementExps(stmt, (traverseExp, (env, info)));
      then
        ((stmt, env));

    case ((stmt, env)) 
      equation
        info = SCode.getStatementInfo(stmt);
        (_, _) = SCode.traverseStatementExps(stmt, (traverseExp, (env, info)));
      then
        ((stmt, env));

  end match;
end analyseStatementTraverser;

protected function analyseClassExtends
  "Goes through the environment and checks if class extends are used or not.
  This is done since class extends are sometimes implicitly used (see for
  example the test case mofiles/ClassExtends3.mo), so only going through the
  first phase of the dependency analysis is not enough to find all class extends
  that are used. Adding all class extends would also be problematic, since we
  would have to make sure that any class extend and it's dependencies are marked
  as used.
  
  This phase goes through all used classes, and if it finds a class extends in
  one of them it sets the use flag to the same as the base class. This is not a
  perfect solution since it means that all class extends that extend a certain
  base class will be marked as used, even if only one of them actually use the
  base class. So we might get some extra dependencies that are actually not
  used, but it's still better then marking all class extends in the program as
  used."
  input Env inEnv;
protected
  SCodeEnv.AvlTree tree;
algorithm
  SCodeEnv.FRAME(clsAndVars = tree) :: _ := inEnv;
  analyseAvlTree(SOME(tree), inEnv);
end analyseClassExtends;

protected function analyseAvlTree
  "Helper function to analyzeClassExtends. Goes through the nodes in an
  AvlTree."
  input Option<SCodeEnv.AvlTree> inTree;
  input Env inEnv;
algorithm
  _ := match(inTree, inEnv)
    local
      Option<SCodeEnv.AvlTree> left, right;
      SCodeEnv.AvlTreeValue value;

    case (NONE(), _) then ();
    case (SOME(SCodeEnv.AVLTREENODE(value = NONE())), _) then ();
    case (SOME(SCodeEnv.AVLTREENODE(value = SOME(value), left = left, right = right)), _)
      equation
        analyseAvlTree(left, inEnv);
        analyseAvlTree(right, inEnv);
        analyseAvlValue(value, inEnv);
      then
        ();

  end match;  
end analyseAvlTree;

protected function analyseAvlValue
  "Helper function to analyzeClassExtends. Analyses a value in the AvlTree."
  input SCodeEnv.AvlTreeValue inValue;
  input Env inEnv;
algorithm
  _ := matchcontinue(inValue, inEnv)
    local
      String key_str;
      SCodeEnv.Frame cls_env;
      Env env;
      SCode.Class cls;
      SCodeEnv.ClassType cls_ty;
      Util.StatefulBoolean is_used;
      String cls_name;

    // Check if the current environment is not used, we can quit here if that's
    // the case.
    case (_, SCodeEnv.FRAME(name = SOME(_), isUsed = is_used) :: _)
      equation
        false = Util.getStatefulBoolean(is_used);
      then
        ();

    case (SCodeEnv.AVLTREEVALUE(key = key_str, value = SCodeEnv.CLASS(cls = cls, 
        env = {cls_env}, classType = cls_ty)), _)
      equation
        env = cls_env :: inEnv;
        analyseClassExtendsDef(cls, cls_ty, env);
        // Check all classes inside of this class too.
        analyseClassExtends(env);
      then
        ();

    else then ();
  end matchcontinue;
end analyseAvlValue;

protected function analyseClassExtendsDef
  "Analyses a class extends definition."
  input SCode.Class inClass;
  input SCodeEnv.ClassType inClassType;
  input Env inEnv;
algorithm
  _ := matchcontinue(inClass, inClassType, inEnv)
    local
      Item item;
      Absyn.Info info;
      Absyn.Path bc;
      String cls_name;
      Env env;

    case (SCode.CLASS(name = cls_name, classDef = SCode.PARTS(elementLst = 
          SCode.EXTENDS(baseClassPath = bc) :: _), info = info), 
        SCodeEnv.CLASS_EXTENDS(), _)
      equation
        // Look up the base class of the class extends, and check if it's used.
        (item, _, _) = SCodeLookup.lookupClassName(bc, inEnv, info);
        true = SCodeEnv.isItemUsed(item);
        // Ok, the base is used, analyse the class extends to mark it and it's
        // dependencies as used.
        _ :: env = inEnv;
        analyseClass(Absyn.IDENT(cls_name), env, info);   
      then
        ();

    else then ();

  end matchcontinue;
end analyseClassExtendsDef;

protected function collectUsedProgram
  "Entry point for the second phase in the dependency analysis. Goes through the
  environment and collects the used elements in a new program and environment."
  input Env inEnv;
  input SCode.Program inProgram;
  output Env outEnv;
  output SCode.Program outProgram;
protected
  Env env;
  SCodeEnv.AvlTree cls_and_vars;
algorithm
  env := SCodeEnv.buildInitialEnv();
  SCodeEnv.FRAME(clsAndVars = cls_and_vars) :: _ := inEnv;
  (outProgram, outEnv) := collectUsedProgram2(cls_and_vars, inProgram, env);
end collectUsedProgram;

protected function collectUsedProgram2
  "Helper function to collectUsedProgram2. Goes through each top-level class in
  the program and collects them if they are used. This is to preserve the order
  of the classes in the new program. Another alternative would have been to just
  traverse the environment and collect the used classes, which would have been a
  bit faster but would not have preserved the order of the program."
  input SCodeEnv.AvlTree clsAndVars;
  input SCode.Program inProgram;
  input Env inAccumEnv;
  output SCode.Program outProgram;
  output Env outAccumEnv;
algorithm
  (outProgram, outAccumEnv) := matchcontinue(clsAndVars, inProgram, inAccumEnv)
    local
      SCode.Class cls;
      SCode.Program rest_prog;
      String name;
      Item item;
      Env env;

    // We're done!
    case (_, {}, _) then (inProgram, inAccumEnv);

    // Try to collect the first class in the list.
    case (_, (cls as SCode.CLASS(name = name)) :: rest_prog, env)
      equation
        (cls, env) = collectUsedClass(cls, clsAndVars, env);
        (rest_prog, env) = collectUsedProgram2(clsAndVars, rest_prog, env); 
      then
        (cls :: rest_prog, env);

    // Could not collect the class (i.e. it's not used), continue with the rest.
    case (_, _ :: rest_prog, env)
      equation
        (rest_prog, env) = collectUsedProgram2(clsAndVars, rest_prog, env);
      then
        (rest_prog, env);

  end matchcontinue;
end collectUsedProgram2;
   
protected function collectUsedClass
  "Checks if the given class is used in the program, and is that's the case it
  adds the class to the accumulated environment. Otherwise it just fails."
  input SCode.Class inClass;
  input SCodeEnv.AvlTree inClsAndVars;
  input Env inAccumEnv;
  output SCode.Class outClass;
  output Env outAccumEnv;
protected
  SCode.Ident name;
  Boolean pp, ep;
  SCode.Restriction res;
  SCode.ClassDef cdef;
  Absyn.Info info;
  Item item;
  SCodeEnv.Frame class_frame;
  Env class_env;
algorithm
  SCode.CLASS(name, pp, ep, res, cdef, info) := inClass;
  // Check if the class is used.
  item := SCodeEnv.avlTreeGet(inClsAndVars, name);
  true := checkClassUsed(item, cdef);
  // The class is used, recursively collect it's contents.
  {class_frame} := SCodeEnv.getItemEnv(item);
  (cdef, class_env) := collectUsedClassDef(name, cdef, class_frame);
  // Add the class to the new environment.
  outClass := SCode.CLASS(name, pp, ep, res, cdef, info);
  item := updateItemEnv(item, outClass, class_env);
  outAccumEnv := SCodeEnv.extendEnvWithItem(item, inAccumEnv, name);
end collectUsedClass;
     
protected function checkClassUsed
  "Given the environment item and definition for a class, returns whether the
  class is used or not."
  input Item inItem;
  input SCode.ClassDef inClassDef;
  output Boolean isUsed;
algorithm
  isUsed := match(inItem, inClassDef)
    // GraphicalAnnotationsProgram____ is a special case, since it's not used by
    // anything, but needed during instantiation.
    case (SCodeEnv.CLASS(cls = 
        SCode.CLASS(name = "GraphicalAnnotationsProgram____")), _) 
      then true;
    // Otherwise, use the environment item to determine if the class is used or
    // not.
    else SCodeEnv.isItemUsed(inItem);
  end match;
end checkClassUsed;

protected function updateItemEnv
  "Replaces the class and environment in an environment item, preserving the
  item's type."
  input Item inItem;
  input SCode.Class inClass;
  input Env inEnv;
  output Item outItem;
algorithm
  outItem := match(inItem, inClass, inEnv)
    local
      SCodeEnv.ClassType cls_ty;

    case (SCodeEnv.CLASS(classType = cls_ty), _, _)
      then SCodeEnv.CLASS(inClass, inEnv, cls_ty);

  end match;
end updateItemEnv;

protected function collectUsedClassDef
  "Collects the contents of a class definition."
  input SCode.Ident inClassName;
  input SCode.ClassDef inClassDef;
  input SCodeEnv.Frame inClassEnv;
  output SCode.ClassDef outClass;
  output Env outEnv;
algorithm
  (outClass, outEnv) := match(inClassName, inClassDef, inClassEnv)
    local
      list<SCode.Element> el;
      list<SCode.Equation> neq, ieq;
      list<SCode.AlgorithmSection> nal, ial;
      Option<Absyn.ExternalDecl> ext_decl;
      list<SCode.Annotation> annl;
      Option<SCode.Comment> cmt;
      SCode.Ident bc;
      SCode.Mod mods;
      Env env;

    case (_, SCode.PARTS(el, neq, ieq, nal, ial, ext_decl, annl, cmt), _)
      equation
        (el, env) = collectUsedElements(inClassName, el, inClassEnv);
      then
        (SCode.PARTS(el, neq, ieq, nal, ial, ext_decl, annl, cmt), env);

    case (_, SCode.CLASS_EXTENDS(bc, mods, el, neq, ieq, nal, ial, annl, cmt), _)
      equation
        (el, env) = collectUsedElements(inClassName, el, inClassEnv);
      then
        (SCode.CLASS_EXTENDS(bc, mods, el, neq, ieq, nal, ial, annl, cmt), env);

    else then (inClassDef, {inClassEnv});
  end match;
end collectUsedClassDef;
         
protected function collectUsedElements
  "Collects a class definition's elements."
  input SCode.Ident inClassName;
  input list<SCode.Element> inElements;
  input SCodeEnv.Frame inClassEnv;
  output list<SCode.Element> outUsedElements;
  output Env outNewEnv;
protected
  SCodeEnv.Frame empty_class_env;
  SCodeEnv.AvlTree cls_and_vars;
algorithm
  // Create a new class environment that preserves the imports and extends.
  (empty_class_env, cls_and_vars) :=
    SCodeEnv.removeClsAndVarsFromFrame(inClassEnv);
  (outUsedElements, outNewEnv) := 
    collectUsedElements2(inElements, cls_and_vars, {}, {empty_class_env});
end collectUsedElements;

protected function collectUsedElements2
  "Helper function to collectUsedElements2. Goes through the given list of
  elements and tries to collect them."
  input list<SCode.Element> inElements;
  input SCodeEnv.AvlTree inClsAndVars;
  input list<SCode.Element> inAccumElements;
  input Env inAccumEnv;
  output list<SCode.Element> outAccumElements;
  output Env outAccumEnv;
algorithm
  (outAccumElements, outAccumEnv) := 
  matchcontinue(inElements, inClsAndVars, inAccumElements, inAccumEnv)
    local
      SCode.Element el;
      list<SCode.Element> rest_el, accum_el;
      Env accum_env;

    // Tail recursive function, reverse the result list.
    case ({}, _, _, _) then (listReverse(inAccumElements), inAccumEnv);

    case (el :: rest_el, _, accum_el, accum_env)
      equation
        (el, accum_env) = collectUsedElement(el, inClsAndVars, accum_env);
        accum_el = el :: accum_el;
        (accum_el, accum_env) = 
          collectUsedElements2(rest_el, inClsAndVars, accum_el, accum_env);
      then
        (accum_el, accum_env);

    case (_ :: rest_el, _, accum_el, accum_env)
      equation
        (accum_el, accum_env) =
          collectUsedElements2(rest_el, inClsAndVars, accum_el, accum_env);
      then
        (accum_el, accum_env);

  end matchcontinue;  
end collectUsedElements2;

protected function collectUsedElement
  "Collects a class element."
  input SCode.Element inElement;
  input SCodeEnv.AvlTree inClsAndVars;
  input Env inAccumEnv;
  output SCode.Element outElement;
  output Env outAccumEnv;
algorithm
  (outElement, outAccumEnv) := match(inElement, inClsAndVars, inAccumEnv)
    local
      SCode.Ident name;
      Boolean fp, rp;
      SCode.Class cls;
      Option<Absyn.ConstrainClass> cc;
      Env env;
      Item item;

    // A class definition, just use collectUsedClass.
    case (SCode.CLASSDEF(name, fp, rp, cls, cc), _, env)
      equation
        (cls, env) = collectUsedClass(cls, inClsAndVars, env);
      then
        (SCode.CLASSDEF(name, fp, rp, cls, cc), env);
  
    // A constant.
    //case (SCode.COMPONENT(component = name, 
    //    attributes = SCode.ATTR(variability = SCode.CONST())), _, _)
    //  equation
    //    item = SCodeEnv.avlTreeGet(inClsAndVars, name);
    //    true = SCodeEnv.isItemUsed(item);
    //    env = SCodeEnv.extendEnvWithItem(item, inAccumEnv, name);
    //  then
    //    (inElement, env);
        
    // Class components are always collected, regardless of whether they are
    // used or not.
    case (SCode.COMPONENT(component = name), _, _)
      equation
        item = SCodeEnv.newVarItem(inElement, true);
        env = SCodeEnv.extendEnvWithItem(item, inAccumEnv, name);
      then
        (inElement, env);

    else then (inElement, inAccumEnv);

  end match;
end collectUsedElement;
    
end SCodeDependency;
