/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
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

  RCS: $Id$"

public 
import Absyn;
import Types;
import SCode;
protected import RTOpts;

// addapted from Connect, not to include it as it has tons of dependencies which we don't need.
public 
uniontype Face  
   "This type indicates whether a connector is an inside or an outside
    connector. Note: this is not the same as inner and outer references. 
    A connector is inside if it connects from the outside into a component
    and it is outside if it connects out from the component. 
    This is important when generating equations for flow variables,
    where outside connectors are multiplied with -1 (since flow is always into a component)."
  record INSIDE "an inside connector" end INSIDE;
  record OUTSIDE "an outside connector" end OUTSIDE;    
end Face;

protected import Debug;
protected import Dump;
protected import Util;
protected import System;
protected import Exp;

public
type InstanceHierarchy = list<Instance> "an instance hierarchy is a list of instances";
  
constant InstanceHierarchy emptyInstanceHierarchy={} "An empty instance hierarchy" ; 

public
uniontype InstanceAttributes "attributes of an instance"
  record ATTRIBUTES "the attributes for an instance"
    SCode.Element element "the actual element, being it a class or a component;
                           for a top class we wrap it into a SCode.CLASSDEF()";    
    Option<Types.Type> ty "the instantiated type";
    Option<Face> attrInsideOutside "whether this is an inside or outside component"; 
  end ATTRIBUTES;
end InstanceAttributes;
  
public 
uniontype InstanceConnects "the relations between an instance and other instances" 
  record CONNECTS
    list<SCode.EEquation> connectEquations  "the connect equations in this instance";
    list<Absyn.ComponentRef> actualConnects "theis instance connects to these instances";
  end CONNECTS;
end InstanceConnects;

public 
constant InstanceConnects emptyConnects = CONNECTS({}, {}) "empty connects";

public
uniontype Instance 
 "An instance can be:
  - a model instance:        Modelica.Electrical.Analog.Basic.Resistor
  - a component instance:    Modelica.Electrical.Analog.Basic.Resistor.R
  - an extends instance:     Modelica.Electrical.Analog.Basic.Resistor.extends.Modelica.Electrical.Analog.Interfaces.OnePort
  - a derived instance:      Modelica.SIunits.Voltage.extends.Modelica.SIunits.ElectricPotential" 
    record INSTANCE
      Absyn.ComponentRef name        "the full name of this instance";
      InstanceAttributes attributes  "the attributes of this instance";
      InstanceHierarchy children     "the childrens of this instance";
      InstanceConnects connects      "full connnection info for this instance:
                                      connects that happen in this instance and 
                                      what instances this instance connects to";
      Option<Absyn.ComponentRef> innerReference "inner reference if existing";
      Option<Absyn.ComponentRef> outerReference "outer reference if existing"; 
    end INSTANCE;  
end Instance;

public function createInstanceHierarchyFromProgram
"@author adrpo
 create the instance hierarchy for a list of classes"
  input InstanceHierarchy inIH;
  input Option<Absyn.Path> inScope;  
  input SCode.Program inProgram;  
  output InstanceHierarchy outIH;
algorithm
  outIH := matchcontinue(inIH, inScope, inProgram)
    local
      InstanceHierarchy ih, restIH;
      SCode.Class c;
      list<SCode.Class> cs;
      String n;
      Instance i;
      SCode.Path path;
      Option<Absyn.Path> scope;
      Absyn.ComponentRef fullCr;
      
    case (ih,scope,{}) then ih;
      
    case (ih,scope,(c as SCode.CLASS(name=n)):: cs)
      equation
        path = makePath(scope, n);
        fullCr = Absyn.pathToCref(path);
        i = createInstanceFromClass(fullCr, ATTRIBUTES(SCode.CLASSDEF("dummy", false, false, c, NONE(), NONE()), NONE(), NONE()));
        ih = createInstanceHierarchyFromProgram(i::ih, scope, cs);
      then
        ih;
        
    case (ih,scope,c::_)
      equation 
				true = RTOpts.debugFlag("instance");
        Debug.fprintln("instance", "InstanceHierarchy.createInstanceFromProgram failed on class:" +& SCode.printClassStr(c));
      then
        fail();
  end matchcontinue;     
end createInstanceHierarchyFromProgram;

function createInstance
"@author adrpo
 create an instance"
  input Absyn.ComponentRef fullCr;
  input InstanceAttributes attributes "the attributes of this instance";
  input InstanceHierarchy children "the childrens of this instance";
  input InstanceConnects connects "full connnection info for this instance";
  input Option<Absyn.ComponentRef> innerReference "inner reference if existing";
  input Option<Absyn.ComponentRef> outerReference "outer reference if existing";
  output Instance i;
algorithm
  i := matchcontinue(fullCr, attributes, children, connects, innerReference, outerReference)
    case (fullCr, attributes, children, connects, innerReference, outerReference)
    then INSTANCE(fullCr, attributes, children, connects, innerReference, outerReference);
  end matchcontinue;
end createInstance;

function getClassDefinition
"fetch a class definition from the instance attributes"
  input InstanceAttributes ia;
  output SCode.ClassDef cd;
algorithm
  cd := matchcontinue(ia)
    case ATTRIBUTES(element=SCode.CLASSDEF(classDef=SCode.CLASS(classDef = cd))) then cd;
    case _
      equation
        Debug.fprintln("instance", "InstanceHierarchy.getClassDefinition failed"); 
      then fail();
  end matchcontinue;
end getClassDefinition;

function createInstanceFromClass
"@author adrpo
 create an instance"
  input Absyn.ComponentRef fullCr;
  input InstanceAttributes attributes "the attributes of this instance";
  output Instance i;
algorithm
  i := matchcontinue(fullCr, attributes)
    local 
      Absyn.Path path;
      SCode.ClassDef classDef;
      InstanceConnects connects;
      InstanceHierarchy children;
                       
    case (fullCr, attributes)
      equation
        path = Absyn.crefToPath(fullCr);
        classDef = getClassDefinition(attributes);
        Debug.fprintln("instance", "IH: Creating instance: " +& Absyn.pathString(path));
        (children, connects) = createInstanceHierarchyFromClassDef(SOME(path), classDef);
      then 
        INSTANCE(fullCr, attributes, children, connects, NONE(), NONE());
  end matchcontinue;
end createInstanceFromClass;

function createInstanceHierarchyFromClassDef
"@author adrpo
 create the instance hierarchy for a class definition"
  input Option<Absyn.Path> scope; 
  input SCode.ClassDef cdef;
  output InstanceHierarchy ih;
  output InstanceConnects ic;
algorithm
  (ih, ic) := matchcontinue(scope, cdef)
    local 
      InstanceHierarchy i;
      SCode.Restriction restriction;
      SCode.ClassDef classDef;
      String name;
      Absyn.Path path, fpath;
      Instance i;
      InstanceHierarchy ihrest;
      list<SCode.Element> elements;
      Absyn.TypeSpec t;
      SCode.Class cl;
      list<SCode.Equation> equations;
      InstanceConnects icrest;
      Absyn.ComponentRef fullCref;
      
    case (scope, SCode.PARTS(elementLst = elements, normalEquationLst = equations))
      equation 
        ihrest = createInstanceHierarchyFromElements(scope, elements);
        icrest = addConnects(scope, equations, emptyConnects);
      then 
        (ihrest, icrest);
        
    case (scope, SCode.CLASS_EXTENDS(elementLst = elements, normalEquationLst = equations))
      equation 
        ihrest = createInstanceHierarchyFromElements(scope, elements);
        icrest = addConnects(scope, equations, emptyConnects);
      then 
        (ihrest, icrest);
                
    // derived is just a more powerful extends!
    // TODO! maybe merge DERIVED and EXTENDS!
    case (scope, SCode.DERIVED(t as Absyn.TPATH(path, _), _, _,_)) 
      equation
        fpath = makePath(scope, "$extends$");
        fpath = Absyn.joinPaths(fpath, path);
        fullCref = Absyn.pathToCref(fpath);
        i = createInstance(fullCref, ATTRIBUTES(SCode.EXTENDS(path, SCode.NOMOD(), NONE()), NONE(), NONE()), {}, emptyConnects, NONE(), NONE());
      then 
        ({i}, emptyConnects);
        
    case (scope, _) // ignore enumerations and pder for now
      equation
      then 
        ({}, emptyConnects);
  end matchcontinue;
end createInstanceHierarchyFromClassDef;

function createInstanceHierarchyFromElements
"@author adrpo
 create the instance hierarchy from elements"
  input Option<Absyn.Path> scope;
  input list<SCode.Element> elements;
  output InstanceHierarchy ih;
algorithm
  ih := matchcontinue(scope, elements)
    local 
      InstanceHierarchy i;
      SCode.Restriction restriction;
      SCode.ClassDef classDef;
      String name;
      Absyn.Path path, fpath;
      Instance i;
      InstanceHierarchy ihrest;
      list<SCode.Element> rest;
      SCode.Element el;
      SCode.Class cl;
      Absyn.TypeSpec t;
      Absyn.ComponentRef fullCref;
      
    case (scope, (el as SCode.COMPONENT(component=name, typeSpec=t as Absyn.TPATH(path,_)))::rest)
      equation        
        fpath = makePath(scope, name);
        fullCref = Absyn.pathToCref(fpath);
        i = createInstance(fullCref, ATTRIBUTES(el, NONE(), NONE()), {}, emptyConnects, NONE(), NONE()); 
        ihrest = createInstanceHierarchyFromElements(scope, rest); 
      then 
        i::ihrest;
        
    case (scope, (el as SCode.EXTENDS(path, _, _))::rest)
      equation
        fpath = makePath(scope, "$extends$");
        fpath = Absyn.joinPaths(fpath, path);
        fullCref = Absyn.pathToCref(fpath);
        i = createInstance(fullCref, ATTRIBUTES(el, NONE(), NONE()), {}, emptyConnects, NONE(), NONE());
        ihrest = createInstanceHierarchyFromElements(scope, rest); 
      then 
        i::ihrest;
        
    case (scope, (el as SCode.CLASSDEF(_, _, _, cl as SCode.CLASS(name = name), _, _))::rest)
      equation
        fpath = makePath(scope, name);
        fullCref = Absyn.pathToCref(fpath);
        i = createInstanceFromClass(fullCref, ATTRIBUTES(el, NONE(), NONE())); 
        ihrest = createInstanceHierarchyFromElements(scope, rest);
      then 
        i::ihrest;        
        
    case (scope, (el as SCode.IMPORT(_))::rest) 
      equation 
        fpath = makePath(scope, "$import$");
        fullCref = Absyn.pathToCref(fpath);
        i = createInstanceFromClass(fullCref, ATTRIBUTES(el, NONE(), NONE()));
        ihrest = createInstanceHierarchyFromElements(scope, rest); 
      then 
        ihrest;

    case (scope, (el as SCode.DEFINEUNIT(name, _, _))::rest)
      equation
        fpath = makePath(scope, name);
        fullCref = Absyn.pathToCref(fpath);
        i = createInstanceFromClass(fullCref, ATTRIBUTES(el, NONE(), NONE())); 
        ihrest = createInstanceHierarchyFromElements(scope, rest);
      then 
        i::ihrest;
        
    case (scope, {}) then {};
      
    case (scope, el::rest) 
      equation 
				true = RTOpts.debugFlag("instance");
        Debug.fprintln("instance", "InstanceHierarchy.createInstanceHierarchyFromElements failed on element: " +& SCode.unparseElementStr(el));
      then 
        fail();
  end matchcontinue;
end createInstanceHierarchyFromElements;

function addScopeToConnects
  input Option<Absyn.Path> scope;
  input SCode.EEquation inEqu;
  output SCode.EEquation outEqu;
algorithm
  outEqu := matchcontinue(scope, inEqu)
  local 
    SCode.EEquation e;
    Absyn.Path p;
    Absyn.ComponentRef cr1, cr2;
    Option<SCode.Comment> cmt;
    
    case (NONE(), e) then e;
      
    case (SOME(p), SCode.EQ_CONNECT(cr1, cr2, cmt))
      equation
        cr1 = Absyn.joinCrefs(Absyn.pathToCref(p), cr1);
        cr2 = Absyn.joinCrefs(Absyn.pathToCref(p), cr2);
      then 
         SCode.EQ_CONNECT(cr1, cr2, cmt);
  end matchcontinue;
end addScopeToConnects;

function addConnects
  input Option<Absyn.Path> scope;  
  input list<SCode.Equation> equations;
  input InstanceConnects inInstanceConnects;
  output InstanceConnects outInstanceConnects;
algorithm
  outInstanceConnects := matchcontinue(scope, equations, inInstanceConnects)
    local
	    list<SCode.EEquation> eqs, eEquationLst;
      SCode.EEquation equ; 
      list<SCode.Equation> rest;
      InstanceConnects result;
      list<Absyn.ComponentRef> act;
      
    case (scope, SCode.EQUATION(equ as SCode.EQ_CONNECT(_, _, _), _)::rest, CONNECTS(eqs,act))
      equation
        equ = addScopeToConnects(scope,equ);
        result = addConnects(scope, rest, CONNECTS(equ::eqs,act));
      then 
        result;
        
    case (scope, SCode.EQUATION(SCode.EQ_FOR(_, _, eEquationLst, _), _)::rest, CONNECTS(eqs,act))
      equation
        eEquationLst = filterConnects(eEquationLst);
        eEquationLst = Util.listMap1r(eEquationLst, addScopeToConnects, scope);
        eqs = listAppend(eqs, eEquationLst);        
        result = addConnects(scope, rest, CONNECTS(eqs,act));
      then 
        result;
                
    case (scope, _::rest, inInstanceConnects)
      equation 
        result = addConnects(scope, rest, inInstanceConnects); 
      then 
        result;

    case (scope, {}, inInstanceConnects) then inInstanceConnects;        
        
  end matchcontinue;
end addConnects;

function filterConnects
  input list<SCode.EEquation> inEEquationLst;
  output list<SCode.EEquation> outEEquationLst;
algorithm
  outEEquationLst := matchcontinue(inEEquationLst)
    local 
      SCode.EEquation equ;
      list<SCode.EEquation> other, rest;
      
    case ({}) then {};
      
    case ((equ as SCode.EQ_CONNECT(_, _, _))::rest)
      equation
        other = filterConnects(rest);
      then 
        equ::other;
  end matchcontinue;  
end filterConnects;

function makePath
  input Option<Absyn.Path> optPath;
  input String name;
  output Absyn.Path path;
algorithm
  path := matchcontinue(optPath, name)
    local 
      Absyn.Path p;
    case (SOME(p), name)
      then Absyn.joinPaths(p, Absyn.IDENT(name));
    case (NONE(), name)
      then Absyn.IDENT(name);
  end matchcontinue;
end makePath;

function lookupInstance
  input InstanceHierarchy ih;
  input Absyn.ComponentRef cref;
  output Option<Instance> i;
algorithm
  i := matchcontinue(ih, cref)
    local
      Instance i;
      Option<Instance> oi;
      InstanceHierarchy ihrest, children;
      Absyn.ComponentRef cr;
      
    case ({}, cref) then NONE();
            
    case ((i as INSTANCE(name=cr))::ihrest, cref)
      equation        
        true = Absyn.crefEqual(cref, cr);
      then SOME(i);
        
    case ((i as INSTANCE(name=cr, children=children))::ihrest, cref)
      equation        
        false = Absyn.crefEqual(cref, cr);
        SOME(i) = lookupInstance(children, cref);
      then SOME(i);

    case ((i as INSTANCE(name=cr, children=children))::ihrest, cref)
      equation        
        false = Absyn.crefEqual(cref, cr);
        NONE() = lookupInstance(children, cref);
        SOME(i) = lookupInstance(ihrest, cref);
      then SOME(i);
        
    case (_, cref)
      equation        
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
      Absyn.ComponentRef name        "the full name of this instance";
      InstanceAttributes attributes  "the attributes of this instance";
      InstanceHierarchy children     "the childrens of this instance";
      InstanceConnects connects      "full connnection info for this instance:
                                      connects that happen in this instance and 
                                      what instances this instance connects to";
      Option<Absyn.ComponentRef> innerReference "inner reference if existing";
      Option<Absyn.ComponentRef> outerReference "outer reference if existing"; 
      String indent;
      Option<Types.Type> ty "the instantiated type";
      Option<Face> attrInsideOutside "whether this is an inside or outside component";
      SCode.Element el;      
      
    case (INSTANCE(name, attributes as ATTRIBUTES(el, ty, attrInsideOutside), {}, connects, innerReference, outerReference), l)
      equation
        indent = Dump.indentStr(l) +& "+";
        print(indent +& "I(" +& Dump.printComponentRefStr(name) +& ", el: " +& printElementStr(el));
        print(", ty: "); printTypeOpt(ty); print(", is/os: ");
        printFaceOpt(attrInsideOutside); print(")");
        printInstanceConnects(connects, l+1);
      then ();      
      
    case (INSTANCE(name, attributes as ATTRIBUTES(el, ty, attrInsideOutside), children, connects, innerReference, outerReference), l)
      equation
        indent = Dump.indentStr(l) +& "+";
        print(indent +& "I(" +& Dump.printComponentRefStr(name) +& ", el: " +& printElementStr(el));
        print(", ty: "); printTypeOpt(ty); print(", is/os: "); 
        printFaceOpt(attrInsideOutside); print(")");
        printInstanceConnects(connects, l+1);
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
  input Option<Face> optFace;
algorithm
  _ := matchcontinue(optFace)
    local      
    case (SOME(INSIDE()))
      equation
        print ("INSIDE");
      then ();
    case (SOME(OUTSIDE()))
      equation
        print ("OUTSIDE");
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

function printInstanceConnects
  input InstanceConnects ic;
  input Integer l;
algorithm
  _ := matchcontinue(ic, l)
    local 
      String indent, str;
      list<SCode.EEquation> connectEquations "the connect equations in this instance" ;
      list<Absyn.ComponentRef> actualConnects "theis instance connects to these instances" ;      
          
    case (CONNECTS({}, {}), l) then ();
    case (CONNECTS(connectEquations, actualConnects), l)      
      equation
        indent = Dump.indentStr(l) +& "+";
        str = Util.stringDelimitList(Util.listMap(connectEquations, SCode.equationStr), "\n" +& indent);
        print("\n" +& indent +& str);
        str = Util.stringDelimitList(Util.listMap(actualConnects, Dump.printComponentRefStr), ", ");
        print(str);        
      then ();
  end matchcontinue;  
end printInstanceConnects;

public function printElementStr 
"function: printElementStr
  print SCode.Element to a string."
  input SCode.Element inElement;
  output String outString;
algorithm 
  outString := matchcontinue (inElement)
    local
      String str,res,n,mod_str,s,vs;
      SCode.OptBaseClass pathOpt;
      Absyn.TypeSpec typath;
      SCode.Mod mod;
      Boolean finalPrefix,repl,prot;
      SCode.Class cl;
      SCode.Variability var;
      Option<SCode.Comment> comment;
      SCode.Attributes attr;
      Absyn.Path path;
      Absyn.Import imp;
      
    case SCode.EXTENDS(baseClassPath = path,modifications = mod)
      equation 
        str = Absyn.pathString(path);
        res = Util.stringAppendList({"extends ",str,";"});
      then
        res;
        
    case SCode.COMPONENT(component = n,finalPrefix = finalPrefix,replaceablePrefix = repl,protectedPrefix = prot,
                   attributes = SCode.ATTR(variability = var),typeSpec = typath,modifications = mod,
                   baseClassPath = pathOpt,comment = comment)
      equation 
        mod_str = SCode.printModStr(mod);
        s = Dump.unparseTypeSpec(typath);
        vs = SCode.unparseVariability(var);
        str = SCode.unparseOptPath(pathOpt);
        res = Util.stringAppendList({vs," ",s," ",n,mod_str,"; baseclass: ",str,";"});
      then
        res;
        
    case SCode.CLASSDEF(name = n,finalPrefix = finalPrefix,replaceablePrefix = repl,classDef = cl,baseClassPath = _)
      equation 
        //str = printClassStr(cl);
        res = Util.stringAppendList({"class ",n," ... end ",n,";"});
      then
        res;
        
    case SCode.IMPORT(imp = imp) 
      equation
         str = "import "+& Absyn.printImportString(imp) +& ";";
      then str; 
        
    case SCode.DEFINEUNIT(n, _, _) 
      equation
         str = "defineunit "+& n +& ";";
      then str; 

  end matchcontinue;
end printElementStr;

///////////////////////////////////////////////////////
///////////////////////////////////////////////////////
public import DAE;

public
type Key = DAE.ComponentRef "the prefix + '.' + the component name";
type Value = tuple<SCode.Element, DAE.Mod> "the inputs of the instantiation function and the results";

uniontype TopInstance "a top instance is an instance of a model thar resides at top level" 
  record TOP_INSTANCE
    Option<Absyn.Path> path "top model path";
    InstHierarchyHashTable ht "hash table with fully qualified components";
  end TOP_INSTANCE;
end TopInstance;

type InstHierarchy = list<TopInstance>;

constant InstHierarchy emptyInstHierarchy = {}
"an empty instance hierarchy";

public function hashFunc 
"author: PA
  Calculates a hash value for DAE.ComponentRef"
  input Key k;
  output Integer res;
algorithm 
  res := System.hash(Exp.crefStr(k));
end hashFunc;

public function keyEqual
  input Key key1;
  input Key key2;
  output Boolean res;
algorithm
     res := stringEqual(Exp.crefStr(key1),Exp.crefStr(key2));
end keyEqual;

public function dumpInstHierarchyHashTable ""
  input InstHierarchyHashTable t;
algorithm
  print("InstHierarchyHashTable:\n");
  print(Util.stringDelimitList(Util.listMap(hashTableList(t),dumpTuple),"\n"));
  print("\n");
end dumpInstHierarchyHashTable;

public function dumpTuple
  input tuple<Key,Value> tpl;
  output String str;
algorithm
  str := matchcontinue(tpl)
    local 
      Key k; Value v; SCode.Element el; DAE.Mod mod;
    case((k,v as (el,mod))) equation
      str = "{" +& Exp.crefStr(k) +& ", " +& SCode.printElementStr(el) +& "}\n";
    then str;
  end matchcontinue;
end dumpTuple;

/* end of InstHierarchyHashTable instance specific code */

/* Generic hashtable code below!! */
public  
uniontype InstHierarchyHashTable
  record HASHTABLE
    list<tuple<Key,Integer>>[:] hashTable " hashtable to translate Key to array indx" ;
    ValueArray valueArr "Array of values" ;
    Integer bucketSize "bucket size" ;
    Integer numberOfEntries "number of entries in hashtable" ;   
  end HASHTABLE;
end InstHierarchyHashTable; 

uniontype ValueArray 
"array of values are expandable, to amortize the 
 cost of adding elements in a more efficient manner"
  record VALUE_ARRAY
    Integer numberOfElements "number of elements in hashtable" ;
    Integer arrSize "size of crefArray" ;
    Option<tuple<Key,Value>>[:] valueArray "array of values";
  end VALUE_ARRAY;
end ValueArray;

public function cloneInstHierarchyHashTable 
"Author BZ 2008-06
 Make a stand-alone-copy of hashtable."
input InstHierarchyHashTable inHash;
output InstHierarchyHashTable outHash;
algorithm outHash := matchcontinue(inHash)
  local 
    list<tuple<Key,Integer>>[:] arg1,arg1_2;
    Integer arg3,arg4,arg3_2,arg4_2,arg21,arg21_2,arg22,arg22_2;
    Option<tuple<Key,Value>>[:] arg23,arg23_2;
  case(HASHTABLE(arg1,VALUE_ARRAY(arg21,arg22,arg23),arg3,arg4))
    equation
      arg1_2 = arrayCopy(arg1);
      arg21_2 = arg21;
      arg22_2 = arg22;
      arg23_2 = arrayCopy(arg23);
      arg3_2 = arg3;
      arg4_2 = arg4;
      then
        HASHTABLE(arg1_2,VALUE_ARRAY(arg21_2,arg22_2,arg23_2),arg3_2,arg4_2);
end matchcontinue;
end cloneInstHierarchyHashTable;

public function emptyInstHierarchyHashTable 
"author: PA
  Returns an empty InstHierarchyHashTable.
  Using the bucketsize 100 and array size 10."
  output InstHierarchyHashTable hashTable;
  list<tuple<Key,Integer>>[:] arr;
  list<Option<tuple<Key,Value>>> lst;
  Option<tuple<Key,Value>>[:] emptyarr;
algorithm 
  arr := fill({}, 1000);
  emptyarr := fill(NONE(), 100);
  hashTable := HASHTABLE(arr,VALUE_ARRAY(0,100,emptyarr),1000,0);
end emptyInstHierarchyHashTable;

public function isEmpty "Returns true if hashtable is empty"
  input InstHierarchyHashTable hashTable;
  output Boolean res;
algorithm
  res := matchcontinue(hashTable)
    case(HASHTABLE(_,_,_,0)) then true;
    case(_) then false;  
  end matchcontinue;
end isEmpty;

public function add 
"author: PA
  Add a Key-Value tuple to hashtable.
  If the Key-Value tuple already exists, the function updates the Value."
  input tuple<Key,Value> entry;
  input InstHierarchyHashTable hashTable;
  output InstHierarchyHashTable outHahsTable;
algorithm 
  outVariables:=
  matchcontinue (entry,hashTable)
    local     
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      ValueArray varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      list<tuple<Key,Integer>>[:] hashvec_1,hashvec;
      String name_str;      
      tuple<Key,Value> v,newv;
      Key key;
      Value value;
      /* Adding when not existing previously */
    case ((v as (key,value)),(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation 
        failure((_) = get(key, hashTable));
        hval = hashFunc(key);
        indx = intMod(hval, bsize);
        newpos = valueArrayLength(varr);
        varr_1 = valueArrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, ((key,newpos) :: indexes));
        n_1 = valueArrayLength(varr_1);        
      then HASHTABLE(hashvec_1,varr_1,bsize,n_1);
      
      /* adding when already present => Updating value */
    case ((newv as (key,value)),(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation 
        (_,indx) = get1(key, hashTable);
        //print("adding when present, indx =" );print(intString(indx));print("\n");
        indx_1 = indx - 1;
        varr_1 = valueArraySetnth(varr, indx, newv);
      then HASHTABLE(hashvec,varr_1,bsize,n);
    case (_,_)
      equation 
        print("-InstHierarchyHashTable.add failed\n");
      then
        fail();
  end matchcontinue;
end add;

public function addNoUpdCheck 
"author: PA
  Add a Key-Value tuple to hashtable.
  If the Key-Value tuple already exists, the function updates the Value."
  input tuple<Key,Value> entry;
  input InstHierarchyHashTable hashTable;
  output InstHierarchyHashTable outHahsTable;
algorithm 
  outVariables := matchcontinue (entry,hashTable)
    local     
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      ValueArray varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      list<tuple<Key,Integer>>[:] hashvec_1,hashvec;
      String name_str;      
      tuple<Key,Value> v,newv;
      Key key;
      Value value;
    // Adding when not existing previously
    case ((v as (key,value)),(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation 
        hval = hashFunc(key);
        indx = intMod(hval, bsize);
        newpos = valueArrayLength(varr);
        varr_1 = valueArrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, ((key,newpos) :: indexes));
        n_1 = valueArrayLength(varr_1);        
      then HASHTABLE(hashvec_1,varr_1,bsize,n_1);
    case (_,_)
      equation 
        print("-InstHierarchyHashTable.addNoUpdCheck failed\n");
      then
        fail();
  end matchcontinue;
end addNoUpdCheck;

public function delete 
"author: PA
  delete the Value associatied with Key from the InstHierarchyHashTable.
  Note: This function does not delete from the index table, only from the ValueArray.
  This means that a lot of deletions will not make the InstHierarchyHashTable more compact, it 
  will still contain a lot of incices information."
  input Key key;
  input InstHierarchyHashTable hashTable;
  output InstHierarchyHashTable outHahsTable;
algorithm 
  outVariables := matchcontinue (key,hashTable)
    local     
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      ValueArray varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      list<tuple<Key,Integer>>[:] hashvec_1,hashvec;
      String name_str;      
      tuple<Key,Value> v,newv;
      Key key;
      Value value;     
    // adding when already present => Updating value
    case (key,(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation 
        (_,indx) = get1(key, hashTable);
        indx_1 = indx - 1;
        varr_1 = valueArrayClearnth(varr, indx);
      then HASHTABLE(hashvec,varr_1,bsize,n);
    case (_,hashTable)
      equation 
        print("-InstHierarchyHashTable.delete failed\n");
        print("content:"); dumpInstHierarchyHashTable(hashTable);
      then
        fail();
  end matchcontinue;
end delete;

public function get 
"author: PA 
  Returns a Value given a Key and a InstHierarchyHashTable."
  input Key key;
  input InstHierarchyHashTable hashTable;
  output Value value;
algorithm 
  (value,_):= get1(key,hashTable);
end get;

public function get1 "help function to get"
  input Key key;
  input InstHierarchyHashTable hashTable;
  output Value value;
  output Integer indx;
algorithm 
  (value,indx):= matchcontinue (key,hashTable)
    local
      Integer hval,hashindx,indx,indx_1,bsize,n;
      list<tuple<Key,Integer>> indexes;
      Value v;      
      list<tuple<Key,Integer>>[:] hashvec;     
      ValueArray varr;
      Key key2;
    case (key,(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation 
        hval = hashFunc(key);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = get2(key, indexes);
        v = valueArrayNth(varr, indx);
      then
        (v,indx);
  end matchcontinue;
end get1;

public function get2 
"author: PA 
  Helper function to get"
  input Key key;
  input list<tuple<Key,Integer>> keyIndices;
  output Integer index;
algorithm 
  index := matchcontinue (key,keyIndices)
    local
      Key key2;
      Value res;
      list<tuple<Key,Integer>> xs;
    case (key,((key2,index) :: _))
      equation 
        true = keyEqual(key, key2);
      then
        index;
    case (key,(_ :: xs))      
      equation 
        index = get2(key, xs);
      then
        index;
  end matchcontinue;
end get2;

public function hashTableValueList "return the Value entries as a list of Values"
  input InstHierarchyHashTable hashTable;
  output list<Value> valLst;
algorithm
   valLst := Util.listMap(hashTableList(hashTable),Util.tuple22);
end hashTableValueList;

public function hashTableKeyList "return the Key entries as a list of Keys"
  input InstHierarchyHashTable hashTable;
  output list<Key> valLst;
algorithm
   valLst := Util.listMap(hashTableList(hashTable),Util.tuple21);
end hashTableKeyList;

public function hashTableList "returns the entries in the hashTable as a list of tuple<Key,Value>"
  input InstHierarchyHashTable hashTable;
  output list<tuple<Key,Value>> tplLst;
algorithm
  tplLst := matchcontinue(hashTable)
  local ValueArray varr;
    case(HASHTABLE(valueArr = varr)) equation
      tplLst = valueArrayList(varr);
    then tplLst; 
  end matchcontinue;
end hashTableList;

public function valueArrayList 
"author: PA
  Transforms a ValueArray to a tuple<Key,Value> list"
  input ValueArray valueArray;
  output list<tuple<Key,Value>> tplLst;
algorithm 
  tplLst := matchcontinue (valueArray)
    local
      Option<tuple<Key,Value>>[:] arr;
      tuple<Key,Value> elt;
      Integer lastpos,n,size;
      list<tuple<Key,Value>> lst;
    case (VALUE_ARRAY(numberOfElements = 0,valueArray = arr)) then {}; 
    case (VALUE_ARRAY(numberOfElements = 1,valueArray = arr))
      equation 
        SOME(elt) = arr[0 + 1];
      then
        {elt};
    case (VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr))
      equation 
        lastpos = n - 1;
        lst = valueArrayList2(arr, 0, lastpos);
      then
        lst;
  end matchcontinue;
end valueArrayList;

public function valueArrayList2 "Helper function to valueArrayList"
  input Option<tuple<Key,Value>>[:] inVarOptionArray1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<tuple<Key,Value>> outVarLst;
algorithm 
  outVarLst := matchcontinue (inVarOptionArray1,inInteger2,inInteger3)
    local
      tuple<Key,Value> v;
      Option<tuple<Key,Value>>[:] arr;
      Integer pos,lastpos,pos_1;
      list<tuple<Key,Value>> res;
    case (arr,pos,lastpos)
      equation 
        (pos == lastpos) = true;
        SOME(v) = arr[pos + 1];
      then
        {v};
    case (arr,pos,lastpos)
      equation 
        pos_1 = pos + 1;
        SOME(v) = arr[pos + 1];
        res = valueArrayList2(arr, pos_1, lastpos);
      then
        (v :: res);
    case (arr,pos,lastpos)
      equation 
        pos_1 = pos + 1;
        NONE = arr[pos + 1];
        res = valueArrayList2(arr, pos_1, lastpos);
      then
        (res);
  end matchcontinue;
end valueArrayList2;

public function valueArrayLength 
"author: PA
  Returns the number of elements in the ValueArray"
  input ValueArray valueArray;
  output Integer size;
algorithm 
  size := matchcontinue (valueArray)
    case (VALUE_ARRAY(numberOfElements = size)) then size; 
  end matchcontinue;
end valueArrayLength;

public function valueArrayAdd 
"function: valueArrayAdd
  author: PA 
  Adds an entry last to the ValueArray, increasing 
  array size if no space left by factor 1.4"
  input ValueArray valueArray;
  input tuple<Key,Value> entry;
  output ValueArray outValueArray;
algorithm 
  outValueArray := matchcontinue (valueArray,entry)
    local
      Integer n_1,n,size,expandsize,expandsize_1,newsize;
      Option<tuple<Key,Value>>[:] arr_1,arr,arr_2;
      Real rsize,rexpandsize;
    case (VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr),entry)
      equation 
        (n < size) = true "Have space to add array elt." ;
        n_1 = n + 1;
        arr_1 = arrayUpdate(arr, n + 1, SOME(entry));
      then
        VALUE_ARRAY(n_1,size,arr_1);
        
    case (VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr),entry)
      equation 
        (n < size) = false "Do NOT have splace to add array elt. Expand with factor 1.4" ;
        rsize = intReal(size);
        rexpandsize = rsize*.0.4;
        expandsize = realInt(rexpandsize);
        expandsize_1 = intMax(expandsize, 1);
        newsize = expandsize_1 + size;
        arr_1 = Util.arrayExpand(expandsize_1, arr, NONE);
        n_1 = n + 1;
        arr_2 = arrayUpdate(arr_1, n + 1, SOME(entry));
      then
        VALUE_ARRAY(n_1,newsize,arr_2);
    case (_,_)
      equation 
        print("-InstHierarchyHashTable.valueArrayAdd failed\n");
      then
        fail();
  end matchcontinue;
end valueArrayAdd;

public function valueArraySetnth 
"function: valueArraySetnth
  author: PA 
  Set the n:th variable in the ValueArray to value."
  input ValueArray valueArray;
  input Integer pos;
  input tuple<Key,Value> entry;
  output ValueArray outValueArray;
algorithm 
  outValueArray := matchcontinue (valueArray,pos,entry)
    local
      Option<tuple<Key,Value>>[:] arr_1,arr;
      Integer n,size,pos;      
    case (VALUE_ARRAY(n,size,arr),pos,entry)
      equation 
        (pos < size) = true;
        arr_1 = arrayUpdate(arr, pos + 1, SOME(entry));
      then
        VALUE_ARRAY(n,size,arr_1);
    case (_,_,_)
      equation 
        print("-InstHierarchyHashTable.valueArraySetnth failed\n");
      then
        fail();
  end matchcontinue;
end valueArraySetnth;

public function valueArrayClearnth 
"author: PA
  Clears the n:th variable in the ValueArray (set to NONE)."
  input ValueArray valueArray;
  input Integer pos;
  output ValueArray outValueArray;
algorithm 
  outValueArray := matchcontinue (valueArray,pos)
    local
      Option<tuple<Key,Value>>[:] arr_1,arr;
      Integer n,size,pos;      
    case (VALUE_ARRAY(n,size,arr),pos)
      equation 
        (pos < size) = true;
        arr_1 = arrayUpdate(arr, pos + 1, NONE);
      then
        VALUE_ARRAY(n,size,arr_1);
    case (_,_)
      equation 
        print("-InstHierarchyHashTable.valueArrayClearnth failed\n");
      then
        fail();
  end matchcontinue;
end valueArrayClearnth;

public function valueArrayNth 
"function: valueArrayNth
  author: PA 
  Retrieve the n:th Vale from ValueArray, index from 0..n-1."
  input ValueArray valueArray;
  input Integer pos;
  output Value value;
algorithm 
  value := matchcontinue (valueArray,pos)
    local
      Value v;
      Integer n,pos,len;
      Option<tuple<Key,Value>>[:] arr;
      String ps,lens,ns;
    case (VALUE_ARRAY(numberOfElements = n,valueArray = arr),pos)
      equation 
        (pos < n) = true;
        SOME((_,v)) = arr[pos + 1];
      then
        v;
    case (VALUE_ARRAY(numberOfElements = n,valueArray = arr),pos)
      equation 
        (pos < n) = true;
        NONE = arr[pos + 1];
      then
        fail();
  end matchcontinue;
end valueArrayNth;

end InstanceHierarchy;
