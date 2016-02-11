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

encapsulated package NFSCodeCheck
" file:        NFSCodeCheck.mo
  package:     NFSCodeCheck
  description: SCode checking


  This module checks the SCode representation for conformance "

public import Absyn;
public import NFInstTypes;
public import SCode;
public import NFSCodeEnv;

protected import Debug;
protected import Dump;
protected import Error;
protected import Flags;
protected import NFInstDump;
protected import SCodeDump;

public function checkRecursiveShortDefinition
  input Absyn.TypeSpec inTypeSpec;
  input String inTypeName;
  input NFSCodeEnv.Env inTypeEnv;
  input SourceInfo inInfo;
algorithm
  _ := matchcontinue(inTypeSpec, inTypeName, inTypeEnv, inInfo)
    local
      Absyn.Path ts_path, ty_path;
      String ty;

    case (_, _, {}, _) then ();

    case (_, _, _ :: _, _)
      equation
        ts_path = Absyn.typeSpecPath(inTypeSpec);
        ty_path = NFSCodeEnv.getEnvPath(inTypeEnv);
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

    case (_, _, p2)
      then stringEqual(Absyn.pathLastIdent(inTypePath), Absyn.pathFirstIdent(p2));

  end match;
end isSelfReference;

public function checkClassExtendsReplaceability
  input NFSCodeEnv.Item inBaseClass;
  input SourceInfo inOriginInfo;
algorithm
  _ := match(inBaseClass, inOriginInfo)
    local
      SourceInfo info;
      String name;

    case (NFSCodeEnv.CLASS(cls = SCode.CLASS(prefixes = SCode.PREFIXES(
        replaceablePrefix = SCode.REPLACEABLE()))), _)
      then ();

    //case (NFSCodeEnv.CLASS(cls = SCode.CLASS(name = name, prefixes = SCode.PREFIXES(
    //    replaceablePrefix = SCode.NOT_REPLACEABLE()), info = info)), _)
    //  equation
    //    Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inOriginInfo);
    //    Error.addSourceMessage(Error.NON_REPLACEABLE_CLASS_EXTENDS,
    //      {name}, info);
    //  then
    //    fail();
  end match;
end checkClassExtendsReplaceability;

public function checkRedeclareModifier
  input NFSCodeEnv.Redeclaration inModifier;
  input Absyn.Path inBaseClass;
  input NFSCodeEnv.Env inEnv;
algorithm
  _ := match(inModifier, inBaseClass, inEnv)
    local
      SCode.Element e;

    case (NFSCodeEnv.RAW_MODIFIER(e as SCode.CLASS(classDef =
        SCode.DERIVED())), _, _)
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
  input NFSCodeEnv.Env inEnv;
algorithm
  _ := matchcontinue(inModifier, inBaseClass, inEnv)
    local
      Absyn.TypeSpec ty;
      SourceInfo info;
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
  input NFSCodeEnv.Item inItem;
  input SCode.Mod inModifier;
  input SourceInfo inInfo;
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
  input NFSCodeEnv.Item inItem;
  input SCode.Element inReplacement;
  input SourceInfo inInfo;
algorithm
  _ := match(inItem, inReplacement, inInfo)
    local
      SCode.Replaceable repl;
      SCode.Final fin;
      SCode.Ident name;
      SourceInfo info;
      SCode.Variability var;
      SCode.Restriction res;
      SCode.Visibility vis1, vis2;
      String ty;
      Integer err_count;
      Absyn.TypeSpec ty1, ty2;

    case (NFSCodeEnv.VAR(var =
        SCode.COMPONENT(name = name, prefixes = SCode.PREFIXES(
            finalPrefix = fin, replaceablePrefix = repl),
          attributes = SCode.ATTR(variability = var), typeSpec = ty1, info = info)),
        SCode.COMPONENT(prefixes = SCode.PREFIXES(), typeSpec = ty2), _)
      equation
        err_count = Error.getNumErrorMessages();
        ty = "component";
        checkCompRedeclarationReplaceable(name, repl, ty1, ty2, inInfo, info);
        checkRedeclarationFinal(name, ty, fin, inInfo, info);
        checkRedeclarationVariability(name, ty, var, inInfo, info);
        //checkRedeclarationVisibility(name, ty, vis1, vis2, inInfo, info);
        true = intEq(err_count, Error.getNumErrorMessages());
      then
        ();

    case (NFSCodeEnv.CLASS(cls =
        SCode.CLASS(name = name, prefixes = SCode.PREFIXES(
          finalPrefix = fin, replaceablePrefix = repl),
          restriction = res, info = info)),
        SCode.CLASS(prefixes = SCode.PREFIXES()), _)
      equation
        err_count = Error.getNumErrorMessages();
        ty = SCodeDump.restrictionStringPP(res);
        checkClassRedeclarationReplaceable(name, ty, repl, inInfo, info);
        checkRedeclarationFinal(name, ty, fin, inInfo, info);
        //checkRedeclarationVisibility(name, ty, vis1, vis2, inInfo, info);
        true = intEq(err_count, Error.getNumErrorMessages());
      then
        ();

    case (NFSCodeEnv.VAR(var = SCode.COMPONENT(name = name, info = info)),
          SCode.CLASS(restriction = res), _)
      equation
        ty = SCodeDump.restrictionStringPP(res);
        ty = "a " + ty;
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inInfo);
        Error.addSourceMessage(Error.INVALID_REDECLARE_AS,
          {"component", name, ty}, info);
      then
        fail();

    case (NFSCodeEnv.CLASS(cls = SCode.CLASS(restriction = res, info = info)),
          SCode.COMPONENT(name = name), _)
      equation
        ty = SCodeDump.restrictionStringPP(res);
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inInfo);
        Error.addSourceMessage(Error.INVALID_REDECLARE_AS,
          {ty, name, "a component"}, info);
      then
        fail();

    else ();
  end match;
end checkRedeclaredElementPrefix;

protected function checkClassRedeclarationReplaceable
  input SCode.Ident inName;
  input String inType;
  input SCode.Replaceable inReplaceable;
  input SourceInfo inOriginInfo;
  input SourceInfo inInfo;
algorithm
  _ := match(inName, inType, inReplaceable, inOriginInfo, inInfo)
    case (_, _, SCode.REPLACEABLE(), _, _) then ();

    case (_, _, SCode.NOT_REPLACEABLE(), _, _)
      equation
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inOriginInfo);
        Error.addSourceMessage(Error.REDECLARE_NON_REPLACEABLE,
          {inType, inName}, inInfo);
      then
        ();
  end match;
end checkClassRedeclarationReplaceable;

protected function checkCompRedeclarationReplaceable
  input SCode.Ident inName;
  input SCode.Replaceable inReplaceable;
  input Absyn.TypeSpec inType1;
  input Absyn.TypeSpec inType2;
  input SourceInfo inOriginInfo;
  input SourceInfo inInfo;
algorithm
  _ := match(inName, inReplaceable, inType1, inType2, inOriginInfo, inInfo)
    local
      SCode.Element var;
      Absyn.TypeSpec ty1, ty2;

    case (_, SCode.REPLACEABLE(), _, _, _, _) then ();

    case (_, SCode.NOT_REPLACEABLE(), _, _, _, _)
      guard Absyn.pathEqual(Absyn.typeSpecPath(inType1),
                            Absyn.typeSpecPath(inType2))
      then
        ();

    case (_, SCode.NOT_REPLACEABLE(), _, _, _, _)
      equation
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inOriginInfo);
        Error.addSourceMessage(Error.REDECLARE_NON_REPLACEABLE,
          {"component", inName}, inInfo);
      then
        ();
  end match;
end checkCompRedeclarationReplaceable;

protected function checkRedeclarationFinal
  input SCode.Ident inName;
  input String inType;
  input SCode.Final inFinal;
  input SourceInfo inOriginInfo;
  input SourceInfo inInfo;
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
  input SourceInfo inOriginInfo;
  input SourceInfo inInfo;
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
  input SourceInfo inOriginInfo;
  input SourceInfo inNewInfo;
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
  input SourceInfo inInfo;
algorithm
  _ := match(inLiteral, inInfo)
    case (_, _) guard not listMember(inLiteral, {"quantity", "min", "max", "start", "fixed"})
      then ();

    else
      equation
        Error.addSourceMessage(Error.INVALID_ENUM_LITERAL, {inLiteral}, inInfo);
      then
        fail();
  end match;
end checkValidEnumLiteral;

public function checkDuplicateRedeclarations
  "Checks if a redeclaration already exists in a list of redeclarations."
  input NFSCodeEnv.Redeclaration inRedeclare;
  input list<NFSCodeEnv.Redeclaration> inRedeclarations;
protected
  SCode.Element el;
  String el_name;
  SourceInfo el_info;
algorithm
  (el_name, el_info) := NFSCodeEnv.getRedeclarationNameInfo(inRedeclare);
  false := checkDuplicateRedeclarations2(el_name, el_info, inRedeclarations);
end checkDuplicateRedeclarations;

protected function checkDuplicateRedeclarations2
  "Helper function to checkDuplicateRedeclarations."
  input String inRedeclareName;
  input SourceInfo inRedeclareInfo;
  input list<NFSCodeEnv.Redeclaration> inRedeclarations;
  output Boolean outIsDuplicate;
algorithm
  outIsDuplicate := matchcontinue(inRedeclareName, inRedeclareInfo,
      inRedeclarations)
    local
      NFSCodeEnv.Redeclaration redecl;
      list<NFSCodeEnv.Redeclaration> rest_redecls;
      String el_name;
      SourceInfo el_info;

    case (_, _, {}) then false;

    case (_, _, redecl :: _)
      equation
        (el_name, el_info) = NFSCodeEnv.getRedeclarationNameInfo(redecl);
        true = stringEqual(inRedeclareName, el_name);
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, el_info);
        Error.addSourceMessage(Error.DUPLICATE_REDECLARATION,
          {inRedeclareName}, inRedeclareInfo);
      then
        true;

    case (_, _, _ :: rest_redecls)
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
  input SourceInfo inComponentInfo;
  input NFSCodeEnv.Env inTypeEnv;
  input NFSCodeEnv.Item inTypeItem;
  input NFSCodeEnv.Env inComponentEnv;
algorithm
  _ := matchcontinue(inComponentName, inComponentInfo, inTypeEnv, inTypeItem,
      inComponentEnv)
    local
      String cls_name, ty_name;
      NFSCodeEnv.AvlTree tree;
      SCode.Element el;

    // No environment means one of the basic types.
    case (_, _, {}, _, _) then ();

    // Check that the environment of the components type is not an enclosing
    // scope of the component itself.
    case (_, _, _, _, _)
      equation
        false = NFSCodeEnv.envPrefixOf(inTypeEnv, inComponentEnv);
      then
        ();

    // Make an exception for components in functions.
    case (_, _, _, _, NFSCodeEnv.FRAME(name = SOME(cls_name)) ::
        NFSCodeEnv.FRAME(clsAndVars = tree) :: _)
      equation
        NFSCodeEnv.CLASS(cls = el) = NFSCodeEnv.avlTreeGet(tree, cls_name);
        true = SCode.isFunction(el);
      then
        ();

    else
      equation
        ty_name = NFSCodeEnv.getItemName(inTypeItem);
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
  input SourceInfo inInfo;
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
  input NFInstTypes.Component inComponent1;
  input NFInstTypes.Component inComponent2;
algorithm
  _ := match(inComponent1, inComponent2)
    case (_, _)
      equation
        print("Found duplicate component\n");
      then
        ();

  end match;
end checkComponentsEqual;

public function checkInstanceRestriction
  input NFSCodeEnv.Item inItem;
  input NFInstTypes.Prefix inPrefix;
  input SourceInfo inInfo;
algorithm
  _ := matchcontinue(inItem, inPrefix, inInfo)
    local
      SCode.Restriction res;
      String pre_str, res_str;

    case (NFSCodeEnv.CLASS(cls = SCode.CLASS(restriction = res)), _, _)
      equation
        true = SCode.isInstantiableClassRestriction(res);
      then
        ();

    case (NFSCodeEnv.CLASS(cls = SCode.CLASS(restriction = res)), _, _)
      equation
        res_str = SCodeDump.restrictionStringPP(res);
        pre_str = NFInstDump.prefixStr(inPrefix);
        Error.addSourceMessage(Error.INVALID_CLASS_RESTRICTION,
          {res_str, pre_str}, inInfo);
      then
        fail();

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFSCodeCheck.checkInstanceRestriction failed on unknown item.");
      then
        fail();

  end matchcontinue;
end checkInstanceRestriction;

public function checkPartialInstance
  "Checks if the given item is partial, and prints out an error message in that
   case."
  input NFSCodeEnv.Item inItem;
  input SourceInfo inInfo;
algorithm
  _ := match(inItem, inInfo)
    local
      String name;

    case (NFSCodeEnv.CLASS(cls = SCode.CLASS(name = name, partialPrefix =
        SCode.PARTIAL())), _)
      equation
        Error.addSourceMessage(Error.INST_PARTIAL_CLASS, {name}, inInfo);
      then
        fail();

    else ();
  end match;
end checkPartialInstance;

annotation(__OpenModelica_Interface="frontend");
end NFSCodeCheck;
