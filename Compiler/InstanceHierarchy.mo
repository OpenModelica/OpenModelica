/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2009, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
 
package InstanceHierarchy
"
  file:	       InstanceHierarchy.mo
  package:     InstanceHierarchy
  description: Data structure for representing the instance hierarchy

  RCS: $Id: InstanceHierarchy.mo 3976 2009-03-25 15:12:39Z adrpo $"

public 
import Absyn;
import Types;
import Connect;
import SCode;
import Lookup;
import Env;

protected import Debug;
protected import Dump;

public
type InstanceHierarchy = list<Instance> "an instance hierarchy is a list of instances";
  
constant InstanceHierarchy emptyInstanceHierarchy={} "An empty instance hierarchy" ; 
  
uniontype Instance
  record INSTANCE "representing an instance"
    String name "the instance name";
    Option<Absyn.Path> containedIn "the class that contains this instance";
    Option<Absyn.Path> path "the absyn type of the component";
    SCode.Restriction restriction "the restriction of the component";     
    Option<Types.Type> ty "the instantiated type";
    Option<Connect.Face> attrInsideOutside "whether this is an inside our outside component";
    Option<Absyn.InnerOuter> attrInnerOuter "whether this has inner/outer attribute";
    InstanceHierarchy children "the children of this instance"; 
  end INSTANCE;
end Instance;

function createInstance
"@author adrpo
 create the instance hierarchy for a class"
  input SCode.Class cl;
  input String instanceName;
  input Option<Absyn.Path> containedInOpt;
  input Absyn.Path path;
  input Env.Cache cache;
  input Env.Env env;
  output Instance i;
algorithm
  i := matchcontinue(cl, instanceName, containedInOpt, path, cache, env)
    local       
      SCode.Restriction restriction;
      SCode.ClassDef classDef;
      Absyn.Path containedIn;
      InstanceHierarchy children;
      String name;
      
    case (SCode.CLASS(name, _, _, restriction, classDef),instanceName, containedInOpt, path, cache, env)
      equation
        //path = Absyn.joinPaths(path, Absyn.IDENT(name));
        //Debug.fprintln("instance", "IH: Creating instance: " +& instanceName +& " for class:" +& name);
        children = createInstanceHierarchyFromClassDef(classDef, SOME(path), cache, env);
      then 
        INSTANCE(instanceName, containedInOpt, SOME(path), restriction, NONE(), NONE(), NONE(), children);        
  end matchcontinue;
end createInstance;

function createInstanceHierarchyFromClassDef
"@author adrpo
 create the instance hierarchy for a class"
  input SCode.ClassDef cdef;
  input Option<Absyn.Path> containedIn;
  input Env.Cache cache;
  input Env.Env env;
  output InstanceHierarchy ih;
algorithm
  ih := matchcontinue(cdef, containedIn, cache, env)
    local 
      InstanceHierarchy i;
      SCode.Restriction restriction;
      SCode.ClassDef classDef;
      String name;
      Absyn.Path path;
      Instance i;
      InstanceHierarchy ihrest;
      list<SCode.Element> elements;
      
    case (SCode.PARTS(elementLst = elements),containedIn, cache, env)
      equation 
        ihrest = createInstanceHierarchyFromElements(elements, containedIn, cache, env); 
      then 
        ihrest;
  end matchcontinue;
end createInstanceHierarchyFromClassDef;

function createInstanceHierarchyFromElements
"@author adrpo
 create the instance hierarchy for a class"
  input list<SCode.Element> elements;
  input Option<Absyn.Path> containedIn;
  input Env.Cache cache;
  input Env.Env env;
  output InstanceHierarchy ih;
algorithm
  ih := matchcontinue(elements, containedIn, cache, env)
    local 
      InstanceHierarchy i;
      SCode.Restriction restriction;
      SCode.ClassDef classDef;
      String name;
      Absyn.Path path;
      Instance i;
      InstanceHierarchy ihrest;
      list<SCode.Element> rest;
      SCode.Element el;
      SCode.Class cl;
      
    case (SCode.COMPONENT(component=name, typeSpec=Absyn.TPATH(path,_))::rest,containedIn,cache,env)
      equation
        (cache,cl,env) = Lookup.lookupClass(cache, env, path, true);
        i = createInstance(cl, name, containedIn, path, cache, env); 
        ihrest = createInstanceHierarchyFromElements(rest, containedIn, cache, env); 
      then 
        i::ihrest;
        
    case (SCode.EXTENDS(path, _, _)::rest,containedIn,cache,env)
      equation
        (cache,cl,env) = Lookup.lookupClass(cache, env, path, true);
        i = createInstance(cl, "_EXTENDS_", containedIn, path, cache, env); 
        ihrest = createInstanceHierarchyFromElements(rest, containedIn, cache, env); 
      then 
        i::ihrest;        
        
    case (_::rest,containedIn, cache, env)
      equation 
        ihrest = createInstanceHierarchyFromElements(rest, containedIn, cache, env); 
      then 
        ihrest;

    case ({},containedIn, cache, env) then {};
                
  end matchcontinue;
end createInstanceHierarchyFromElements;

function lookupInstance
  input InstanceHierarchy ih;
  input Option<Absyn.Path> containedIn;
  input Absyn.ComponentRef cref;
  output Option<Instance> i;
algorithm
  i := matchcontinue(ih, containedIn, cref)
    case (ih, containedIn, cref)
      then NONE();
  end matchcontinue;
end lookupInstance;

function dumpInstanceHierarchy
  input InstanceHierarchy ih;
  input Integer level;
algorithm
  _ := matchcontinue(ih, level)
    local 
      Instance i;
      InstanceHierarchy rest;
      Integer l;
      
    case ({}, _) then ();
    case (i::{}, l)
      equation
        dumpInstance(i,l+1);
      then ();            
    case (i::rest, l)
      equation
        dumpInstance(i,l+1); print("\n");
        dumpInstanceHierarchy(rest, l);
      then ();
  end matchcontinue;
end dumpInstanceHierarchy;

function dumpInstance
  input Instance i;
  input Integer level;
algorithm
  _ := matchcontinue(i, level)
    local 
      Integer l;
      String name "the instance name";
      Option<Absyn.Path> containedIn "the class that contains this instance";
      Option<Absyn.Path> path "the absyn type of the component";
      SCode.Restriction restriction "the restriction of the component";     
      Option<Types.Type> ty "the instantiated type";
      Option<Connect.Face> attrInsideOutside "whether this is an inside our outside component";
      Option<Absyn.InnerOuter> attrInnerOuter "whether this has inner/outer attribute";
      InstanceHierarchy children "the children of this instance";
      String indent;      
      
    case (INSTANCE(name, containedIn, path, restriction, ty, attrInsideOutside, attrInnerOuter, {}), l)
      equation
        indent = Dump.indentStr(l) +& "+";
        print(indent +& "INSTANCE(" +& name +& ", in: ");
        printPathOpt(containedIn);
        print(", classPath: ");
        printPathOpt(path); 
        print(", restriction: " +& SCode.restrString(restriction));
        print(", ty: "); printTypeOpt(ty); print(", inside/outside: "); 
        printFaceOpt(attrInsideOutside); print(", inner/outer: ");
        printInnerOuterOpt(attrInnerOuter); print(")");
      then ();      
      
    case (INSTANCE(name, containedIn, path, restriction, ty, attrInsideOutside, attrInnerOuter, children), l)
      equation
        indent = Dump.indentStr(l) +& "+";
        print(indent +& "INSTANCE(" +& name +& ", in: ");
        printPathOpt(containedIn);
        print(", classPath: ");
        printPathOpt(path); 
        print(", restriction: " +& SCode.restrString(restriction));
        print(", ty: "); printTypeOpt(ty); print(", inside/outside: "); 
        printFaceOpt(attrInsideOutside); print(", inner/outer: ");
        printInnerOuterOpt(attrInnerOuter); print(")");
        print("\n");
        dumpInstanceHierarchy(children, l+1);
      then ();
  end matchcontinue;
end dumpInstance;

function printPathOpt
  input Option<Absyn.Path> optPath;
algorithm
  _ := matchcontinue(optPath)
    local
      Absyn.Path p;
    case (SOME(p))
      equation
        print (Absyn.pathString(p));
      then ();
    case (NONE())
      equation
        print ("NONE()");
      then ();
  end matchcontinue;
end printPathOpt;

function printTypeOpt
  input Option<Types.Type> optTy;
algorithm
  _ := matchcontinue(optTy)
    local
      Types.Type ty;
    case (SOME(ty))
      equation
        print (Types.printTypeStr(ty));
      then ();
    case (NONE())
      equation
        print ("NONE()");
      then ();
  end matchcontinue;
end printTypeOpt;

function printFaceOpt
  input Option<Connect.Face> optFace;
algorithm
  _ := matchcontinue(optFace)
    local
      Connect.Face f;
    case (SOME(Connect.INNER()))
      equation
        print ("INNER");
      then ();
    case (SOME(Connect.OUTER()))
      equation
        print ("OUTER");
      then ();        
    case (NONE())
      equation
        print ("NONE()");
      then ();
  end matchcontinue;
end printFaceOpt;

function printInnerOuterOpt
  input Option<Absyn.InnerOuter> optInnerOuter;
algorithm
  _ := matchcontinue(optInnerOuter)
    local
      Absyn.InnerOuter io;
    case (SOME(io))
      equation
        print (Dump.unparseInnerouterStr(io));
      then ();
    case (NONE())
      equation
        print ("NONE()");
      then ();
  end matchcontinue;
end printInnerOuterOpt;

end InstanceHierarchy;
