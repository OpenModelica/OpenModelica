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

protected import Debug;
protected import Dump;
protected import Error;
protected import ErrorExt;
protected import System;
protected import Util;

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
  input SCode.Element inClass;
algorithm
  _ := match(inClass)
    local
      String name;
      Absyn.TypeSpec ts;
      Absyn.Info info;

    case SCode.CLASS(name = name, classDef = SCode.DERIVED(typeSpec = ts), 
        info = info)
      equation
        checkRecursiveShortDefinition2(name, ts, info);
      then
        ();

    else ();
  end match;
end checkRecursiveShortDefinition;

public function checkRecursiveShortDefinition2
  input String inName;
  input Absyn.TypeSpec inTypeSpec;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inName, inTypeSpec, inInfo)
    local
      String ty;
      
    case (_ , _, _)
      equation
        false = isSelfReference(inName, inTypeSpec);
      then
        ();

    else
      equation
        ty = Dump.unparseTypeSpec(inTypeSpec);
        Error.addSourceMessage(Error.RECURSIVE_SHORT_CLASS_DEFINITION, 
          {inName, ty}, inInfo);
      then
        fail();
    
  end matchcontinue;
end checkRecursiveShortDefinition2;

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
  input String name;
  input Absyn.TypeSpec ts;
  output Boolean selfRef;
algorithm
  selfRef := matchcontinue(name, ts)
    local
      Absyn.Path p;
    
    // a simple type path  
    case (name, Absyn.TPATH(path = p))
      equation
        true = stringEqual(name, Absyn.pathFirstIdent(p));
      then
        true;
    
    // a complex type path 
    case (name, Absyn.TCOMPLEX(path = p))
      equation
        true = stringEqual(name, Absyn.pathFirstIdent(p));
      then
        true;
    
    // anything else returns false
    case (_, _) then false;
  end matchcontinue;
end isSelfReference;

end SCodeCheck;
