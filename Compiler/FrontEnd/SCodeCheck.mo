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

protected import Dump;
protected import Error;
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
        names = Util.listMap(sp, SCode.className);
        names = Util.sort(names,Util.strcmpBool);
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
        msg = Util.stringDelimitList(duplicateNames, ",");
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
        
public function checkDuplicateElements
  input list<SCode.Element> inElements;
algorithm
  _ := matchcontinue(inElements)
    local
      SCode.Element e;
      list<SCode.Element> rest;
    
    case ({}) then ();
    
    case (e::rest)
      equation
      then
        ();
  end matchcontinue;
end checkDuplicateElements;

public function checkDuplicateEnums
  input list<SCode.Enum> inEnumLst;
algorithm
  _ := matchcontinue(inEnumLst)
    local
      SCode.Enum e;
      list<SCode.Enum> rest;
    
    case ({}) then ();
    
    case (e::rest)
      equation
      then
        ();
  end matchcontinue;
end checkDuplicateEnums;

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
  input SCodeEnv.Item inBaseClass;
  input Absyn.Path inPath;
  input Absyn.Info inOriginInfo;
algorithm
  _ := match(inBaseClass, inPath, inOriginInfo)
    local
      Absyn.Info info;
      String err_str;

    case (SCodeEnv.CLASS(cls = SCode.CLASS(prefixes = SCode.PREFIXES(
        replaceablePrefix = SCode.NOT_REPLACEABLE()))), _, _)
      then ();

    case (SCodeEnv.CLASS(cls = SCode.CLASS(prefixes = SCode.PREFIXES(
        replaceablePrefix = SCode.REPLACEABLE(cc = _)), info = info)), _, _)
      equation
        // Disabled until it's decided whether this is an error or not.
        //err_str = Absyn.pathString(inPath);
        //Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inOriginInfo);
        //Error.addSourceMessage(Error.REPLACEABLE_BASE_CLASS, {err_str}, info);
      then
        ();
  end match;
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
    case (_, SCode.REDECL(elementLst = _), _)
      equation
        checkRedeclaredElementPrefix(inItem, inInfo);
      then
        ();

    else ();
  end match;
end checkModifierIfRedeclare;

public function checkRedeclaredElementPrefix
  "Checks that an element that is being redeclared is declared as replaceable
  and non-final, otherwise an error is printed."
  input SCodeEnv.Item inItem;
  input Absyn.Info inInfo;
algorithm
  _ := match(inItem, inInfo)
    local
      SCode.Replaceable repl;
      SCode.Final fin;
      SCode.Ident name;
      Absyn.Info info;
      SCode.Visibility vis;
      SCode.Variability var;
      SCode.Restriction res;
      String ty;
      Integer err_count;

    case (SCodeEnv.VAR(var = SCode.COMPONENT(
          name = name, 
          prefixes = SCode.PREFIXES(
            finalPrefix = fin, 
            replaceablePrefix = repl,
            visibility = vis), 
          attributes = SCode.ATTR(variability = var), 
          info = info)), _)
      equation
        err_count = Error.getNumErrorMessages();
        ty = "component";
        checkRedeclarationReplaceable(name, ty, repl, inInfo, info);
        checkRedeclarationFinal(name, ty, fin, inInfo, info);
        checkRedeclarationVisibility(name, ty, vis, inInfo, info);
        checkRedeclarationVariability(name, ty, var, inInfo, info);
        true = intEq(err_count, Error.getNumErrorMessages());
      then
        ();

    case (SCodeEnv.CLASS(cls = SCode.CLASS(
          name = name, 
          prefixes = SCode.PREFIXES(
            finalPrefix = fin, 
            replaceablePrefix = repl,
            visibility = vis),
          restriction = res,
          info = info)), _)
      equation
        err_count = Error.getNumErrorMessages();
        ty = SCodeDump.restrictionStringPP(res);
        checkRedeclarationReplaceable(name, ty, repl, inInfo, info);
        checkRedeclarationFinal(name, ty, fin, inInfo, info);
        checkRedeclarationVisibility(name, ty, vis, inInfo, info);
        true = intEq(err_count, Error.getNumErrorMessages());
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

protected function checkRedeclarationVisibility
  input SCode.Ident inName;
  input String inType;
  input SCode.Visibility inVisibility;
  input Absyn.Info inOriginInfo;
  input Absyn.Info inInfo;
algorithm
  _ := match(inName, inType, inVisibility, inOriginInfo, inInfo)
    local
      String err_str;
    
    case (_, _, SCode.PROTECTED(), _, _)
      equation
        err_str = "protected " +& inType +& " " +& inName;
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inOriginInfo);
        Error.addSourceMessage(Error.INVALID_REDECLARE, {err_str}, inInfo);
      then
        ();

    case (_, _, SCode.PUBLIC(), _, _) then ();
  end match;
end checkRedeclarationVisibility;

protected function checkRedeclarationFinal
  input SCode.Ident inName;
  input String inType;
  input SCode.Final inFinal;
  input Absyn.Info inOriginInfo;
  input Absyn.Info inInfo;
algorithm
  _ := match(inName, inType, inFinal, inOriginInfo, inInfo)
    local
      String err_str;

    case (_, _, SCode.NOT_FINAL(), _, _) then ();

    case (_, _, SCode.FINAL(), _, _)
      equation
        err_str = "final " +& inType +& " " +& inName;
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inOriginInfo);
        Error.addSourceMessage(Error.INVALID_REDECLARE, {err_str}, inInfo);
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
    local
      String err_str;

    case (_, _, SCode.CONST(), _, _)
      equation
        err_str = "constant " +& inType +& " " +& inName;
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inOriginInfo);
        Error.addSourceMessage(Error.INVALID_REDECLARE, {err_str}, inInfo);
      then
        ();

    else ();
  end match;
end checkRedeclarationVariability;

public function checkValidEnumLiteral
  input String inLiteral;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inLiteral, inInfo)
    case (_, _)
      equation
        true = Util.listNotContains(inLiteral, 
          {"quantity", "min", "max", "start", "fixed"});
      then
        ();

    else
      equation
        Error.addSourceMessage(Error.INVALID_ENUM_LITERAL, {inLiteral}, inInfo);
      then
        fail();
  end matchcontinue;
end checkValidEnumLiteral;

end SCodeCheck;
