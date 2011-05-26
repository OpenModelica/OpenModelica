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

encapsulated package SCodeFlattenExtends
" file:        SCodeFlattenExtends.mo
  package:     SCodeFlattenExtends
  description: Flattening of extends (and class extends) clauses by copying all components 
               from base classes in the current class, fully qualifying all paths and 
               applying the outer modifications.

  RCS: $Id$

  This module is responsible for flattening of extends (and class extends) 
  clauses by copying all components from base classes in the current class, 
  fully qualifying all paths and applying the outer modifications."

// public imports
public import Absyn;
public import SCode;
public import SCodeEnv;
public import SCodeHashTable;

protected import BaseHashTable;
protected import Debug;
protected import Dump;
protected import RTOpts;
protected import SCodeLookup;
protected import SCodeDump;
protected import SCodeFlat;
protected import SCodeFlatDump;

public function flattenProgram
  "Flattens the last class in a program."
  input Absyn.Path inClassName;
  input SCodeEnv.Env inEnv;
  input SCode.Program inProgram;
  output SCode.Program outProgram;
algorithm
  outProgram := matchcontinue(inClassName, inEnv, inProgram)
    local
      SCodeFlat.FlatProgram flatProgram;

    case (_, _, _)
      equation
        false = RTOpts.debugFlag("scodeFlatten");
      then
        inProgram;

    else
      equation
        (flatProgram, _) = SCodeFlat.flattenProgram(inProgram, SCodeFlat.EXTRA(inEnv, {}, {}, {}, {}, Absyn.dummyInfo));
        SCodeFlatDump.outputFlatProgram(flatProgram);
      then
        inProgram;

  end matchcontinue;
end flattenProgram;

protected function flattenClass
  "simplifies a class."
  input SCode.Element inClass;
  input SCodeEnv.Env inEnv;
  output SCode.Element outClass;
algorithm
  outClass := matchcontinue(inClass, inEnv)
    local
      SCodeEnv.Env env;
      SCode.Element cl, newCls;
      SCode.Element element;
      SCode.Ident className;
      Absyn.ComponentRef fullCref;
      SCode.ClassDef cDef;
      Absyn.Info info;
      SCode.Ident n;
      SCode.Prefixes pref;
      SCode.Encapsulated ep;
      SCode.Partial pp;
      SCode.Restriction restr;
      
    case (cl as SCode.CLASS(n, pref, ep, pp, restr, cDef, info), env)
      equation
        print("Flattening: " +& SCodeDump.printElementStr(cl) +& "\n");
        className = SCode.className(cl);        
        element = cl;
        env = SCodeEnv.enterScope(env, className);
        cDef = flattenClassDef(cDef, env, info);        
      then 
        SCode.CLASS(n, pref, ep, pp, restr, cDef, info);
  end matchcontinue; 
end flattenClass;

protected function flattenClassDef
  "Flattens a classdef."  
  input SCode.ClassDef inClassDef;
  input SCodeEnv.Env inEnv;
  input Absyn.Info inInfo;
  output SCode.ClassDef outClassDef;
algorithm
  outClassDef := matchcontinue(inClassDef, inEnv, inInfo)
    local
      SCodeEnv.Env env;
      SCode.Element cl, newCls, parentElement;
      SCodeEnv.ClassType cls_ty;
      SCode.Program rest;
      SCode.Element el;
      SCode.Ident className, baseClassName, name;
      Absyn.ComponentRef fullCref;
      Absyn.Path path;
      SCodeEnv.ClassType classType;
      list<SCode.Element> els, modifiers;
      list<SCode.Equation> ne "the list of equations";
      list<SCode.Equation> ie "the list of initial equations";
      list<SCode.AlgorithmSection> na "the list of algorithms";
      list<SCode.AlgorithmSection> ia "the list of initial algorithms";
      Option<SCode.ExternalDecl> ed "used by external functions";
      list<SCode.Annotation> al "the list of annotations found in between class elements, equations and algorithms";
      Option<SCode.Comment> c "the class comment";
      SCode.ClassDef cDef;
      Option<SCode.Element> baseClassOpt;
      Absyn.Info info;
      SCode.Mod mod;
      SCode.Attributes attr;
      Option<SCode.Comment> cmt;
    
    // handle parts
    case (SCode.PARTS(els, ne, ie, na, ia, ed, al, c), env, info)
      equation
        els = flattenElements(els, env, inInfo);
      then 
        SCode.PARTS(els, ne, ie, na, ia, ed, al, c);
    
    // handle class extends
    case (SCode.CLASS_EXTENDS(baseClassName, mod, cDef), env, info)
      equation
        cDef = flattenClassDef(cDef, env, info);
      then 
        cDef;
    
    // handle derived!
    case (SCode.DERIVED(Absyn.TPATH(path, _), mod, attr, cmt), env, info)
      equation        
        // Remove the extends from the local scope before flattening the derived
        // type, because the type should not be looked up via itself.
        env = SCodeEnv.removeExtendsFromLocalScope(env);
        
        (SCodeEnv.CLASS(cls = el as SCode.CLASS(classDef = cDef, info = info), classType = cls_ty), path, env) = 
          SCodeLookup.lookupBaseClassName(path, env, info);

        print("Flattening derived: " +& SCodeDump.printElementStr(el) +& "\n");
        
        // entering the base class
        env = SCodeEnv.enterScope(env, Absyn.pathLastIdent(path));
        
        cDef = flattenClassDef(cDef, env, info);
      then 
        cDef;
    
    // handle enumeration
    case (SCode.ENUMERATION(enumLst = _), env, info)
      then 
        inClassDef;
    
    // handle overload
    case (SCode.OVERLOAD(pathLst = _), env, info)
      then 
        inClassDef;
    
    // handle pder
    case (SCode.PDER(functionPath = _), env, info)
      then 
        inClassDef;
  end matchcontinue; 
end flattenClassDef;

protected function flattenElements
  "flatten elements"
  input list<SCode.Element> inElements;
  input SCodeEnv.Env inEnv;
  input Absyn.Info inInfo;
  output list<SCode.Element> outElements;  
algorithm
  outElements := matchcontinue(inElements, inEnv, inInfo)
    local
      SCodeEnv.Env env;
      SCode.Element el;
      list<SCode.Element> rest, lst1, lst2, lst;
      Absyn.Info info;
      Absyn.ComponentRef fullCref;
    
    // handle classes without elements!  
    case ({}, env, info) then {};
    
    // handle rest
    case (el::rest, env, info)
      equation
        print("Flattening element: " +& SCodeDump.printElementStr(el) +& "\n");
        lst1 = flattenElement(el, env, info);
        lst2 = flattenElements(rest, env, info);
        lst = listAppend(lst1, lst2);
      then 
        lst;
  end matchcontinue; 
end flattenElements;

protected function flattenElement
  "flatten an element"  
  input SCode.Element inElement;
  input SCodeEnv.Env inEnv;
  input Absyn.Info inInfo;
  output list<SCode.Element> outElements;  
algorithm
  outElements := matchcontinue(inElement, inEnv, inInfo)
    local
      SCodeEnv.Env env;
      SCodeEnv.ClassType cls_ty;      
      Absyn.ComponentRef fullCref;
      SCode.Ident name;
      Absyn.Path path;
      SCode.Element el, cl, parentElement;
      Absyn.Import imp;
      Absyn.Info info;
      SCodeEnv.Item item;
      SCode.Visibility vis;
      SCode.ClassDef cDef;
      Option<SCode.Annotation> ann;
      SCode.Mod mod;
    
    // handle extends
    case (el as SCode.EXTENDS(path, vis, mod, ann, info), env, _)
      equation
        // Remove the extends from the local scope before flattening the extends
        // type, because the type should not be looked up via itself.
        env = SCodeEnv.removeExtendsFromLocalScope(env);
        
        (SCodeEnv.CLASS(cls = cl as SCode.CLASS(classDef = cDef, info = info), classType = cls_ty), path, env) = 
          SCodeLookup.lookupBaseClassName(path, env, info);
        
        print("Flattening extends: " +& SCodeDump.printElementStr(cl) +& "\n");
        
        // entering the base class
        env = SCodeEnv.enterScope(env, Absyn.pathLastIdent(path));

        cDef = flattenClassDef(cDef,env,info);
      then 
        {el};

    // handle classdef
    case (el as SCode.CLASS(name = name, classDef = cDef, info = info), env, _)
      equation
        env = SCodeEnv.enterScope(env, name);

        cDef = flattenClassDef(cDef, env, info);
      then 
        {el};
    
    // handle import, WE SHOULD NOT HAVE ANY!
    case (el as SCode.IMPORT(imp = imp), env, info)
      equation
        print("Import found! We should not have any!");
      then 
        {el};

    // handle basic type component
    case (el as SCode.COMPONENT(name = name, typeSpec = Absyn.TPATH(path = path)), env, info)
      equation
        (SCodeEnv.CLASS(cls = cl as SCode.CLASS(classDef = cDef, info = info), classType = SCodeEnv.BUILTIN()), path, env) = 
          SCodeLookup.lookupClassName(path, env, info);
      then 
        {el};

    // handle user defined component
    case (el as SCode.COMPONENT(name = name, typeSpec = Absyn.TPATH(path = path)), env, info)
      equation
        (SCodeEnv.CLASS(cls = cl as SCode.CLASS(classDef = cDef, info = info), classType = cls_ty), path, env) = 
          SCodeLookup.lookupClassName(path, env, info);
        cl = flattenClass(cl, env);
      then 
        {el};
    
    // handle defineunit
    case (el as SCode.DEFINEUNIT(name = name), env, info)
      equation
      then 
        {el};
        
     case (el, env, info)
       equation
         print("- SCodeFlattenExtends.flattenElement failed on element: " +& SCodeDump.shortElementStr(el) +& "\n");
       then
         fail();
  end matchcontinue; 
end flattenElement;

end SCodeFlattenExtends;
