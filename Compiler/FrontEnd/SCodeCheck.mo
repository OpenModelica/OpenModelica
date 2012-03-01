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

encapsulated package SCodeCheck
" file:        SCodeCheck.mo
  package:     SCodeCheck
  description: SCode checking

  RCS: $Id$

  This module checks the SCode representation for conformance "

public import Absyn;
public import SCode;
public import SCodeEnv;
public import SCodeInst;

protected import Config;
protected import Dump;
protected import Error;
protected import List;
protected import Util;
protected import SCodeDump;

public function checkDuplicateClasses
  input SCode.Program inProgram;
algorithm
  _ := matchcontinue(inProgram)
    local
      SCode.Element c;
      SCode.Program sp;
      list<String> names;
      
    case (sp)
      equation
        names = List.map(sp, SCode.className);
        names = List.sort(names,Util.strcmpBool);
        (_,names) = Util.splitUniqueOnBool(names,stringEqual);
        checkForDuplicateClassesInTopScope(names);
      then
        ();
  end matchcontinue;
end checkDuplicateClasses;

protected function checkForDuplicateClassesInTopScope
"Verifies that the input is empty; else an error message is printed"
  input list<String> duplicateNames;
algorithm
  _ := match duplicateNames
    local
      String msg;
    case {} then ();
    else
      equation
        msg = stringDelimitList(duplicateNames, ",");
        Error.addMessage(Error.DUPLICATE_CLASSES_TOP_LEVEL,{msg});
      then fail();
  end match;
end checkForDuplicateClassesInTopScope;

public function checkRecursiveShortDefinition
  input Absyn.TypeSpec inTypeSpec;
  input String inTypeName;
  input SCodeEnv.Env inTypeEnv;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inTypeSpec, inTypeName, inTypeEnv, inInfo)
    local
      Absyn.Path ts_path, ty_path;
      String ty, id;

    case (_, _, {}, _) then ();

    case (_, _, _ :: _, _)
      equation
        ts_path = Absyn.typeSpecPath(inTypeSpec); 
        ty_path = SCodeEnv.getEnvPath(inTypeEnv);
        false = isSelfReference(inTypeName, ty_path, ts_path);
      then
        ();

    else
      equation
        ty = Dump.unparseTypeSpec(inTypeSpec);
        Error.addSourceMessage(Error.RECURSIVE_SHORT_CLASS_DEFINITION,
          {inTypeName, ty}, inInfo);
      then
        fail();

  end matchcontinue;
end checkRecursiveShortDefinition;
        
protected function isSelfReference
  input String inTypeName;
  input Absyn.Path inTypePath;
  input Absyn.Path inReferencedName;
  output Boolean selfRef;
algorithm
  selfRef := match(inTypeName, inTypePath, inReferencedName)
    local
      Absyn.Path p1, p2;
    
    case (_, p1, Absyn.FULLYQUALIFIED(p2))
      then Absyn.pathEqual(Absyn.joinPaths(p1, Absyn.IDENT(inTypeName)), p2);

    case (_, p1, p2)
      then stringEqual(Absyn.pathLastIdent(inTypePath), Absyn.pathFirstIdent(p2));

  end match;
end isSelfReference;

public function checkExtendsReplaceability
  "Checks that a base class in an extends clause is not replaceable. If it is,
   this function will print an error and fail, except for some special cases."
  input SCodeEnv.Item inBaseClass;
  input Absyn.Path inPath;
  input SCodeEnv.Env inEnv;
  input Absyn.Info inOriginInfo;
algorithm
  _ := matchcontinue(inBaseClass, inPath, inEnv, inOriginInfo)
    local
      Absyn.Info info;
      String err_str;
      SCode.ClassDef cdef;

    // The base class is not replaceable, ok.
    case (SCodeEnv.CLASS(cls = SCode.CLASS(prefixes = SCode.PREFIXES(
        replaceablePrefix = SCode.NOT_REPLACEABLE()))), _, _, _)
      then ();

    // If the parent class contains no elements it might be a short class
    // definition, which is allowed to have a replaceable base class.
    case (_, _, SCodeEnv.FRAME(clsAndVars = SCodeEnv.AVLTREENODE(value = NONE(),
        left = NONE(), right = NONE())) :: _, _)
      then ();

    // If we're using Modelica 2.x or earlier we don't care, since replaceable
    // baseclasses weren't explicitly forbidden in older versions.
    case (_, _, _, _)
      equation
        true = Config.languageStandardAtMost(Config.MODELICA_2_X());
      then
        ();

    // A replaceable baseclass will produce an error.
    case (SCodeEnv.CLASS(cls = SCode.CLASS(prefixes = SCode.PREFIXES(
        replaceablePrefix = SCode.REPLACEABLE(cc = _)), 
        classDef = cdef, info = info)), _, _, _)
      equation
        err_str = Absyn.pathString(inPath);
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inOriginInfo);
        Error.addSourceMessage(Error.REPLACEABLE_BASE_CLASS, {err_str}, info);
      then
        fail();
  end matchcontinue;
end checkExtendsReplaceability;

public function checkClassExtendsReplaceability
  input SCodeEnv.Item inBaseClass;
  input Absyn.Info inOriginInfo;
algorithm
  _ := match(inBaseClass, inOriginInfo)
    local
      Absyn.Info info;
      String name;

    case (SCodeEnv.CLASS(cls = SCode.CLASS(prefixes = SCode.PREFIXES(
        replaceablePrefix = SCode.REPLACEABLE(cc = _)))), _)
      then ();

    case (SCodeEnv.CLASS(cls = SCode.CLASS(name = name, prefixes = SCode.PREFIXES(
        replaceablePrefix = SCode.NOT_REPLACEABLE()), info = info)), _)
      equation
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inOriginInfo);
        Error.addSourceMessage(Error.NON_REPLACEABLE_CLASS_EXTENDS,
          {name}, info);
      then
        fail();
  end match;
end checkClassExtendsReplaceability;

public function checkRedeclareModifier
  input SCodeEnv.Redeclaration inModifier;
  input Absyn.Path inBaseClass;
  input SCodeEnv.Env inEnv;
algorithm
  _ := match(inModifier, inBaseClass, inEnv)
    local
      SCode.Element e;

    case (SCodeEnv.RAW_MODIFIER(e as SCode.CLASS(classDef = 
        SCode.DERIVED(typeSpec = _))), _, _)
      equation
        checkRedeclareModifier2(e, inBaseClass, inEnv);
      then
        ();

    else ();
  end match;
end checkRedeclareModifier;

public function checkRedeclareModifier2
  input SCode.Element inModifier;
  input Absyn.Path inBaseClass;
  input SCodeEnv.Env inEnv;
algorithm
  _ := matchcontinue(inModifier, inBaseClass, inEnv)
    local
      Absyn.TypeSpec ty;
      Absyn.Info info;
      String name, ty_str;
      Absyn.Path ty_path;

    case (SCode.CLASS(name = name, 
        classDef = SCode.DERIVED(typeSpec = ty)), _, _)
      equation
        ty_path = Absyn.typeSpecPath(ty);
        false = isSelfReference(name, inBaseClass, ty_path);
      then
        ();

    case (SCode.CLASS(name = name, 
        classDef = SCode.DERIVED(typeSpec = ty), info = info), _, _)
      equation
        ty_str = Dump.unparseTypeSpec(ty);
        Error.addSourceMessage(Error.RECURSIVE_SHORT_CLASS_DEFINITION,
          {name, ty_str}, info);
      then
        fail();
        
  end matchcontinue;
end checkRedeclareModifier2;
        
public function checkModifierIfRedeclare
  input SCodeEnv.Item inItem;
  input SCode.Mod inModifier;
  input Absyn.Info inInfo;
algorithm
  _ := match(inItem, inModifier, inInfo)
    local
      SCode.Element el;

    case (_, SCode.REDECL(element = el), _)
      equation
        checkRedeclaredElementPrefix(inItem, el, inInfo);
      then
        ();

    else ();
  end match;
end checkModifierIfRedeclare;

public function checkRedeclaredElementPrefix
  "Checks that an element that is being redeclared is declared as replaceable
  and non-final, otherwise an error is printed."
  input SCodeEnv.Item inItem;
  input SCode.Element inReplacement;
  input Absyn.Info inInfo;
algorithm
  _ := match(inItem, inReplacement, inInfo)
    local
      SCode.Replaceable repl;
      SCode.Final fin;
      SCode.Ident name;
      Absyn.Info info;
      SCode.Variability var;
      SCode.Restriction res;
      SCode.Visibility vis1, vis2;
      String ty;
      Integer err_count;

    case (SCodeEnv.VAR(var = 
        SCode.COMPONENT(name = name, prefixes = SCode.PREFIXES(
            visibility = vis1, finalPrefix = fin, replaceablePrefix = repl), 
          attributes = SCode.ATTR(variability = var), info = info)), 
        SCode.COMPONENT(prefixes = SCode.PREFIXES(visibility = vis2)), _)
      equation
        err_count = Error.getNumErrorMessages();
        ty = "component";
        checkRedeclarationReplaceable(name, ty, repl, inInfo, info);
        checkRedeclarationFinal(name, ty, fin, inInfo, info);
        checkRedeclarationVariability(name, ty, var, inInfo, info);
        //checkRedeclarationVisibility(name, ty, vis1, vis2, inInfo, info);
        true = intEq(err_count, Error.getNumErrorMessages());
      then
        ();

    case (SCodeEnv.CLASS(cls = 
        SCode.CLASS(name = name, prefixes = SCode.PREFIXES(
          visibility = vis1, finalPrefix = fin, replaceablePrefix = repl), 
          restriction = res, info = info)),
        SCode.CLASS(prefixes = SCode.PREFIXES(visibility = vis2)), _)
      equation
        err_count = Error.getNumErrorMessages();
        ty = SCodeDump.restrictionStringPP(res);
        checkRedeclarationReplaceable(name, ty, repl, inInfo, info);
        checkRedeclarationFinal(name, ty, fin, inInfo, info);
        //checkRedeclarationVisibility(name, ty, vis1, vis2, inInfo, info);
        true = intEq(err_count, Error.getNumErrorMessages());
      then
        ();

    case (SCodeEnv.VAR(var = SCode.COMPONENT(name = name, info = info)),
          SCode.CLASS(restriction = res), _)
      equation
        ty = SCodeDump.restrictionStringPP(res);
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inInfo);
        Error.addSourceMessage(Error.INVALID_REDECLARE_AS,
          {ty, name, "a component"}, info);
      then
        ();

    case (SCodeEnv.CLASS(cls = SCode.CLASS(restriction = res, info = info)),
          SCode.COMPONENT(name = name), _)
      equation
        ty = SCodeDump.restrictionStringPP(res);
        ty = "a " +& ty;
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inInfo);
        Error.addSourceMessage(Error.INVALID_REDECLARE_AS,
          {"component", name, ty}, info);
      then
        ();

    else ();
  end match;
end checkRedeclaredElementPrefix;

protected function checkRedeclarationReplaceable
  input SCode.Ident inName;
  input String inType;
  input SCode.Replaceable inReplaceable;
  input Absyn.Info inOriginInfo;
  input Absyn.Info inInfo;
algorithm
  _ := match(inName, inType, inReplaceable, inOriginInfo, inInfo)

    case (_, _, SCode.REPLACEABLE(cc = _), _, _) then ();

    case (_, _, SCode.NOT_REPLACEABLE(), _, _)
      equation
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inOriginInfo);
        Error.addSourceMessage(Error.REDECLARE_NON_REPLACEABLE,
          {inType, inName}, inInfo);
      then
        ();
  end match;
end checkRedeclarationReplaceable;

protected function checkRedeclarationFinal
  input SCode.Ident inName;
  input String inType;
  input SCode.Final inFinal;
  input Absyn.Info inOriginInfo;
  input Absyn.Info inInfo;
algorithm
  _ := match(inName, inType, inFinal, inOriginInfo, inInfo)
    case (_, _, SCode.NOT_FINAL(), _, _) then ();

    case (_, _, SCode.FINAL(), _, _)
      equation
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inOriginInfo);
        Error.addSourceMessage(Error.INVALID_REDECLARE, 
          {"final", inType, inName}, inInfo);
      then
        ();
  end match;
end checkRedeclarationFinal;

protected function checkRedeclarationVariability
  input SCode.Ident inName;
  input String inType;
  input SCode.Variability inVariability;
  input Absyn.Info inOriginInfo;
  input Absyn.Info inInfo;
algorithm
  _ := match(inName, inType, inVariability, inOriginInfo, inInfo)
    case (_, _, SCode.CONST(), _, _)
      equation
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inOriginInfo);
        Error.addSourceMessage(Error.INVALID_REDECLARE, 
          {"constant", inType, inName}, inInfo);
      then
        ();

    else ();
  end match;
end checkRedeclarationVariability;

protected function checkRedeclarationVisibility
  input SCode.Ident inName;
  input String inType;
  input SCode.Visibility inOriginalVisibility;
  input SCode.Visibility inNewVisibility;
  input Absyn.Info inOriginInfo;
  input Absyn.Info inNewInfo;
algorithm
  _ := match(inName, inType, inOriginalVisibility, inNewVisibility,
      inOriginInfo, inNewInfo)
    case (_, _, SCode.PUBLIC(), SCode.PROTECTED(), _, _)
      equation
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inNewInfo);
        Error.addSourceMessage(Error.INVALID_REDECLARE_AS,
          {"public element", inName, "protected"}, inOriginInfo);
      then
        fail();

    case (_, _, SCode.PROTECTED(), SCode.PUBLIC(), _, _)
      equation
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inNewInfo);
        Error.addSourceMessage(Error.INVALID_REDECLARE_AS,
          {"protected element", inName, "public"}, inOriginInfo);
      then
        fail();

    else ();
  end match;
end checkRedeclarationVisibility;

public function checkValidEnumLiteral
  input String inLiteral;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inLiteral, inInfo)
    case (_, _)
      equation
        false = listMember(inLiteral, {"quantity", "min", "max", "start", "fixed"});
      then ();

    else
      equation
        Error.addSourceMessage(Error.INVALID_ENUM_LITERAL, {inLiteral}, inInfo);
      then
        fail();
  end matchcontinue;
end checkValidEnumLiteral;

public function checkDuplicateRedeclarations
  "Checks if a redeclaration already exists in a list of redeclarations."
  input SCodeEnv.Redeclaration inRedeclare;
  input list<SCodeEnv.Redeclaration> inRedeclarations;
protected
  SCode.Element el;
  String el_name;
  Absyn.Info el_info;
algorithm
  el := SCodeEnv.getRedeclarationElement(inRedeclare);
  el_name := SCode.elementName(el);
  el_info := SCode.elementInfo(el);
  false := checkDuplicateRedeclarations2(el_name, el_info, inRedeclarations);
end checkDuplicateRedeclarations;

protected function checkDuplicateRedeclarations2
  "Helper function to checkDuplicateRedeclarations."
  input String inRedeclareName;
  input Absyn.Info inRedeclareInfo;
  input list<SCodeEnv.Redeclaration> inRedeclarations;
  output Boolean outIsDuplicate;
algorithm
  outIsDuplicate := matchcontinue(inRedeclareName, inRedeclareInfo,
      inRedeclarations)
    local
      SCodeEnv.Redeclaration redecl;
      list<SCodeEnv.Redeclaration> rest_redecls;
      SCode.Element el;
      String el_name;
      Absyn.Info el_info;

    case (_, _, {}) then false;

    case (_, _, redecl :: rest_redecls)
      equation
        el = SCodeEnv.getRedeclarationElement(redecl);
        el_name = SCode.elementName(el);
        true = stringEqual(inRedeclareName, el_name);
        el_info = SCode.elementInfo(el);
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, el_info);
        Error.addSourceMessage(Error.DUPLICATE_REDECLARATION,
          {inRedeclareName}, inRedeclareInfo);
      then
        true;

    case (_, _, redecl :: rest_redecls)
      then checkDuplicateRedeclarations2(inRedeclareName, 
        inRedeclareInfo, rest_redecls);
        
  end matchcontinue;
end checkDuplicateRedeclarations2;
        
public function checkRecursiveComponentDeclaration
  "Checks if a component is declared with a type that is one of the enclosing
   classes, e.g:
     class A
       class B
         A a;
       end B;
     end A;
  "
  input String inComponentName;
  input Absyn.Info inComponentInfo;
  input SCodeEnv.Env inTypeEnv;
  input SCodeEnv.Item inTypeItem;
  input SCodeEnv.Env inComponentEnv;
algorithm
  _ := matchcontinue(inComponentName, inComponentInfo, inTypeEnv, inTypeItem,
      inComponentEnv)
    local
      String cls_name, ty_name;
      SCodeEnv.AvlTree tree;
      SCodeEnv.Item item;
      SCode.Element el;
    
    // No environment means one of the basic types.
    case (_, _, {}, _, _) then ();

    // Check that the environment of the components type is not an enclosing
    // scope of the component itself.
    case (_, _, _, _, _)
      equation
        false = SCodeEnv.envPrefixOf(inTypeEnv, inComponentEnv);
      then
        ();

    // Make an exception for components in functions.
    case (_, _, _, _, SCodeEnv.FRAME(name = SOME(cls_name)) ::
        SCodeEnv.FRAME(clsAndVars = tree) :: _)
      equation
        SCodeEnv.CLASS(cls = el) = SCodeEnv.avlTreeGet(tree, cls_name);
        true = SCode.isFunction(el);
      then
        ();
        
    else
      equation
        ty_name = SCodeEnv.getItemName(inTypeItem);
        Error.addSourceMessage(Error.RECURSIVE_DEFINITION,
          {inComponentName, ty_name}, inComponentInfo);
      then
        fail();

  end matchcontinue;
end checkRecursiveComponentDeclaration;

public function checkIdentNotEqTypeName
  "Checks that a simple identifier is not the same as a type name."
  input String inIdent;
  input Absyn.TypeSpec inTypeName;
  input Absyn.Info inInfo;
  output Boolean outIsNotEq;
algorithm
  outIsNotEq := matchcontinue(inIdent, inTypeName, inInfo)
    local
      String id, ty;

    case (id, Absyn.TPATH(path = Absyn.IDENT(ty)), _)
      equation
        true = stringEq(id, ty);
        Error.addSourceMessage(Error.LOOKUP_TYPE_FOUND_COMP, {id}, inInfo);
      then
        false;

    else true;
  end matchcontinue;
end checkIdentNotEqTypeName;

public function checkComponentsEqual
  input SCodeInst.Component inComponent1;
  input SCodeInst.Component inComponent2;
algorithm
  _ := match(inComponent1, inComponent2)
    case (_, _)
      equation
        print("Found duplicate component\n");
      then
        ();

  end match;
end checkComponentsEqual;

end SCodeCheck;
