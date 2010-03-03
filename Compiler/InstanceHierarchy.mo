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
protected import RTOpts;

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

end InstanceHierarchy;
