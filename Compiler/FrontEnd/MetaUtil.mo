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

encapsulated package MetaUtil
" file:        MetaUtil.mo
  package:     MetaUtil
  description: Different MetaModelica extension functions.

  RCS: $Id$

  "

public import Absyn;
public import ClassInf;
public import DAE;
public import SCode;
public import SCodeUtil;

protected import Config;
protected import Dump;
protected import Error;
protected import Flags;
protected import List;
protected import Types;

public function isList "author: KS
  Return true if list
"
  input DAE.Properties prop;
  output Boolean bool;
algorithm
  bool := matchcontinue (prop)
    case (DAE.PROP(DAE.T_METALIST(listType = _),_)) then true;
    else false;
  end matchcontinue;
end isList;

public function transformArrayNodesToListNodes "function: transformArrayNodesToListNodes"
  input list<Absyn.Exp> inList;
  input list<Absyn.Exp> accList;
  output list<Absyn.Exp> outList;
algorithm
  outList := matchcontinue (inList,accList)
    local
      list<Absyn.Exp> localAccList,es,restList;
      Absyn.Exp firstExp;
    case ({},localAccList) then listReverse(localAccList);
    case (Absyn.ARRAY({}) :: restList,localAccList)
      equation
        localAccList = Absyn.LIST({})::localAccList;
        localAccList = transformArrayNodesToListNodes(restList,localAccList);
      then localAccList;
    case (Absyn.ARRAY(es) :: restList,localAccList)
      equation
        es = transformArrayNodesToListNodes(es,{});
        localAccList = Absyn.LIST(es)::localAccList;
        localAccList = transformArrayNodesToListNodes(restList,localAccList);
      then localAccList;
    case (firstExp :: restList,localAccList)
      equation
        localAccList = firstExp::localAccList;
        localAccList = transformArrayNodesToListNodes(restList,localAccList);
      then localAccList;
  end matchcontinue;
end transformArrayNodesToListNodes;

public function createListType "function: createListType"
  input DAE.Type inType;
  input Integer numLists;
  output DAE.Type outType;
algorithm
  outType :=
  matchcontinue (inType,numLists)
    local
      DAE.Type localT;
      Integer n;
      DAE.Type t;
    case (localT,0) then localT;
    case (localT,n)
      equation
        t = DAE.T_METALIST(localT, DAE.emptyTypeSource);
        t = createListType(t,n-1);
      then t;
  end matchcontinue;
end createListType;

public function getTypeFromProp "function: getTypeFromProp"
  input DAE.Properties inProp;
  output DAE.Type outType;
algorithm
  outType :=
  match (inProp)
    local
      DAE.Type t;
    case (DAE.PROP(t,_)) equation then t;
  end match;
end getTypeFromProp;

public function getListOfStrings
  input list<SCode.Element> els;
  output list<String> outStrings;
algorithm
  outStrings := match(els)
    local
      list<SCode.Element> rest;
      list<String> slst;
      String n;

    case({}) then {};

    case(SCode.CLASS(name = n)::rest)
      equation
        slst = getListOfStrings(rest);
      then
        n::slst;

  end match;
end getListOfStrings;

//Check if a class has a certain restriction, added by simbj
public function classHasMetaRestriction
  input SCode.Element cl;
  output Boolean outBoolean;
algorithm
  outBoolean := match(cl)
    case(SCode.CLASS(restriction = SCode.R_METARECORD(index=_))) then true;
    else false;
  end match;
end classHasMetaRestriction;

//Check if a class has a certain restriction, added by simbj
public function classHasRestriction
  input SCode.Element cl;
  input SCode.Restriction re;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue(cl,re)
    local
      SCode.Restriction re1,re2;

    case(SCode.CLASS(restriction = re1),re2)
      equation
        equality(re1 = re2);
      then true;

    else false;
  end matchcontinue;
end classHasRestriction;

public function createMetaClassesInProgram "Adds metarecord classes to the AST. This function handles a whole program,
  including packages."
  input Absyn.Program program;
  output Absyn.Program out;
algorithm
  out :=  match (program)
    local
      list<Absyn.Class> classes, metaClassesFlat;
      list<list<Absyn.Class>> metaClasses;
      Absyn.Program p;

    case p as Absyn.PROGRAM() guard Config.acceptMetaModelicaGrammar()
      equation
        metaClasses = List.map(p.classes, createMetaClasses);
        metaClassesFlat = List.flatten(metaClasses);
        classes = List.map(p.classes, createMetaClassesFromPackage);
        p.classes = listAppend(classes, metaClassesFlat);
      then p;
    else program;
  end match;
end createMetaClassesInProgram;

protected function createMetaClassesFromPackage "Helper function to createMetaClassesInProgram"
  input Absyn.Class cl;
  output Absyn.Class out;
algorithm
  out := matchcontinue(cl)
    local
      String name;
      Boolean     partialPrefix;
      Boolean     finalPrefix;
      Boolean     encapsulatedPrefix;
      Absyn.Restriction restriction;
      Absyn.ClassDef    body;
      SourceInfo        info;
      list<Absyn.ClassPart> classParts;
      Option<String>  comment;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;

    case (Absyn.CLASS(body=Absyn.PARTS(typeVars=typeVars,classAttrs=classAttrs,classParts=classParts,ann=ann,comment=comment),name=name,partialPrefix=partialPrefix,finalPrefix=finalPrefix,encapsulatedPrefix=encapsulatedPrefix,restriction=restriction,info=info))
      equation
        classParts = List.map(classParts,createMetaClassesFromClassParts);
        body = Absyn.PARTS(typeVars,classAttrs,classParts,ann,comment);
      then Absyn.CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restriction,body,info);

    case _ then cl;
  end matchcontinue;
end createMetaClassesFromPackage;

protected function createMetaClassesFromClassParts
  input Absyn.ClassPart classPart;
  output Absyn.ClassPart out;
algorithm
  out := matchcontinue (classPart)
    local
      list<Absyn.ElementItem> els;
      list<list<Absyn.ElementItem>> lels;

    case (Absyn.PUBLIC(els))
      equation
        lels = List.map(els, createMetaClassesFromElementItem);
        els = List.flatten(lels);
      then Absyn.PUBLIC(els);

    case (Absyn.PROTECTED(els))
      equation
        lels = List.map(els, createMetaClassesFromElementItem);
        els = List.flatten(lels);
      then Absyn.PROTECTED(els);

    case _ then classPart;
  end matchcontinue;
end createMetaClassesFromClassParts;

protected function createMetaClassesFromElementItem
  input Absyn.ElementItem elementItem;
  output list<Absyn.ElementItem> out;
algorithm
  out := matchcontinue(elementItem)
    local
      SourceInfo info;
      Boolean replaceable_;
      Absyn.Class class_, cl2;
      list<Absyn.Class> metaClasses, classes;
      list<Absyn.ElementItem> elementItems;
    case (Absyn.ELEMENTITEM(Absyn.ELEMENT(specification=Absyn.CLASSDEF(class_=class_))))
      equation
        metaClasses = createMetaClasses(class_);
        cl2 = createMetaClassesFromPackage(class_);
        classes = cl2 :: metaClasses;
        elementItems = List.map1r(classes,setElementItemClass,elementItem);
      then elementItems;
    case _ then {elementItem};
  end matchcontinue;
end createMetaClassesFromElementItem;

protected function setElementItemClass
  input Absyn.ElementItem elementItem;
  input Absyn.Class class_;
  output Absyn.ElementItem out;
algorithm
  out := match (elementItem,class_)
      local
      Boolean finalPrefix;
      Option<Absyn.RedeclareKeywords> redeclareKeywords;
      Absyn.InnerOuter innerOuter;
      SourceInfo info;
      Option<Absyn.ConstrainClass> constrainClass;
      Boolean replaceable_;
    case (Absyn.ELEMENTITEM(Absyn.ELEMENT(specification=Absyn.CLASSDEF(replaceable_=replaceable_),finalPrefix=finalPrefix,redeclareKeywords=redeclareKeywords,innerOuter=innerOuter,info=info,constrainClass=constrainClass)),_)
      then Absyn.ELEMENTITEM(Absyn.ELEMENT(finalPrefix,redeclareKeywords,innerOuter,Absyn.CLASSDEF(replaceable_,class_),info,constrainClass));
    /* Annotations, comments */
    else elementItem;
  end match;
end setElementItemClass;

//Added by simbj
//Analyze the AST, find union type and extend the AST with metarecords
public function createMetaClasses
input Absyn.Class cl;
output list<Absyn.Class> clstout;
algorithm
  clstout := matchcontinue(cl)
    local
      list<Absyn.ClassPart> cls;
      list<Absyn.ElementItem> els;
      list<Absyn.Class> cllst;
      SCode.Restriction r_1;
      Absyn.Class c;
      String n;
      Boolean p,f,e;
      Absyn.Restriction r;
      Absyn.ClassDef d;
      SourceInfo file_info;

    case(c as Absyn.CLASS(name = n,partialPrefix = _,finalPrefix = _,encapsulatedPrefix = _,restriction = r,
         body = Absyn.PARTS(classParts = {Absyn.PUBLIC(contents = els)},comment = _),info = _))
      equation
        r_1 = SCodeUtil.translateRestriction(c, r); // uniontype will not get elaborated!
        SCode.R_UNIONTYPE() = r_1;
        els = fixElementItems(els,n,0,listLength(els)==1);
        cllst = convertElementsToClasses(els);
      then cllst;
    else {};
  end matchcontinue;
end createMetaClasses;

//Added by simbj
//Helper function
function convertElementsToClasses
  input list<Absyn.ElementItem> els;
  output list<Absyn.Class> outcls;
algorithm
  outcls := match(els)
    local
      list<Absyn.ElementItem> rest;
      Absyn.Class c;
      list<Absyn.Class> clst;

    case({}) then {};

    case(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = c)))::rest)
      equation
        clst = convertElementsToClasses(rest);
      then
        c::clst;

    /* Strip annotation, comment */
    case(_::rest)
      then convertElementsToClasses(rest);
  end match;
end convertElementsToClasses;

//Added by simbj
//Reparses type and returns the real type
//NOTE: This is probably a bad way to do this, should be moved, maybe to the parser?
function reparseType
  input Absyn.Path path;
  output DAE.Type outType;
algorithm
  outType := match(path)
    local
      DAE.Type t;
    case(Absyn.IDENT("Integer")) then DAE.T_INTEGER_DEFAULT;
    case(Absyn.IDENT("Real")) then DAE.T_REAL_DEFAULT;
    case(Absyn.IDENT("String")) then DAE.T_STRING_DEFAULT;
    case(Absyn.IDENT("Boolean")) then DAE.T_BOOL_DEFAULT;
    // BTH
    case(Absyn.IDENT("Clock"))
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then DAE.T_CLOCK_DEFAULT;
  end match;
end reparseType;

/* These functions are helper functions for the Uniontypes, added by simbj */
public function getRestriction
  input Absyn.Element el;
  output Absyn.Restriction res;
algorithm
  res := match(el)
    local
      Absyn.ElementSpec spec;
      Absyn.Class cl;
      Absyn.Restriction r;
    case(Absyn.ELEMENT(specification=Absyn.CLASSDEF(class_=Absyn.CLASS(restriction=r))))
      then r;
    else Absyn.R_UNKNOWN();
  end match;
end getRestriction;

function fixRestriction
  input Absyn.Restriction resin;
  input String name;
  input Integer index;
  input Boolean singleton;
  output Absyn.Restriction resout;
algorithm
  resout := match(resin,name,index,singleton)
    local
      Absyn.Ident ident;
      Absyn.Path path;
    case(Absyn.R_RECORD(),_,_,_)
      equation
        ident = name;
        path = Absyn.IDENT(ident);
      then Absyn.R_METARECORD(path,index,singleton);
    else resin;
  end match;
end fixRestriction;


function fixClass
  input Absyn.Class classin;
  input String name;
  input Integer index;
  input Boolean singleton;
  output Absyn.Class classout;
algorithm
  classout := match(classin,name,index,singleton)
    local
      Absyn.Ident n;
      Boolean p;
      Boolean f;
      Boolean e;
      Absyn.Restriction res;
      Absyn.ClassDef b;
      SourceInfo i;

    case(Absyn.CLASS(n,p,f,e,res,b,i),_,_,_)
      equation
        res = fixRestriction(res,name,index,singleton);
      then Absyn.CLASS(n,p,f,e,res,b,i);
    else classin;
  end match;
end fixClass;


function fixElementSpecification
  input Absyn.ElementSpec specin;
  input String name;
  input Integer index;
  input Boolean singleton;
  output Absyn.ElementSpec specout;
algorithm
  specout := match(specin,name,index,singleton)
    local
      Boolean rep;
      Absyn.Class c;
    case(Absyn.CLASSDEF(rep,c),_,_,_)
      equation
        c = fixClass(c,name,index,singleton);
      then Absyn.CLASSDEF(rep,c);
    else specin;
  end match;
end fixElementSpecification;

function fixElement
  input Absyn.Element elementin;
  input String name;
  input Integer index;
  input Boolean singleton;
  output Absyn.Element elementout;

algorithm
  elementout := match(elementin,name,index,singleton)
    local
      Boolean f;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter i;
      Absyn.ElementSpec spec;
      SourceInfo inf;
      Option<Absyn.ConstrainClass> con;
    case(Absyn.ELEMENT(finalPrefix = f, redeclareKeywords = r, innerOuter=i, specification=spec, info=inf, constrainClass=con),_,_,_)
      equation
        spec = fixElementSpecification(spec,name,index,singleton);
      then Absyn.ELEMENT(f,r,i,spec,inf,con);
  end match;
end fixElement;



function fixElementItems
  input list<Absyn.ElementItem> elementItemsin;
  input String name;
  input Integer index;
  input Boolean singleton;
  output list<Absyn.ElementItem> elementItemsout;
algorithm
  elementItemsout := match (elementItemsin,name,index,singleton)
    local
      Absyn.Element element;
      Absyn.ElementItem elementitem;
      list<Absyn.ElementItem> rest;
    case({},_,_,_) then {};
    case(Absyn.ELEMENTITEM(element)::rest,_,_,_)
      equation
        element = fixElement(element,name,index,singleton);
        rest = fixElementItems(rest,name,index+1,singleton);
      then (Absyn.ELEMENTITEM(element)::rest);
    case (_::rest,_,_,_) then fixElementItems(rest,name,index,singleton);
  end match;
end fixElementItems;

/* ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^END^OF^HELPERFUNCTIONS^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ */

public function constructorCallTypeToNamesAndTypes "Fetches the field names
and types from a record call or metarecord call"
  input DAE.Type inType;
  output list<String> varNames;
  output list<DAE.Type> outTypes;
algorithm
  (varNames,outTypes) := match (inType)
    local
      list<String> names;
      list<DAE.Type> types;
      list<DAE.FuncArg> fargs;
      list<DAE.Var> fields;

    case (DAE.T_METARECORD(fields = fields))
      equation
        names = List.map(fields, Types.getVarName);
        types = List.map(fields, Types.getVarType);
      then (names,types);

    case (DAE.T_FUNCTION(funcArg = fargs,funcResultType = DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_))))
      equation
        names = List.map(fargs, Types.funcArgName);
        types = List.map(fargs, Types.funcArgType);
      then (names,types);
  end match;
end constructorCallTypeToNamesAndTypes;

public function fixUniontype
  input ClassInf.State st;
  input Option<DAE.Type> t;
  input SCode.ClassDef c;
  output Option<DAE.Type> outType;
algorithm
  outType := matchcontinue (st,t,c)
    local
      list<SCode.Element> els;
      list<String> slst;
      list<Absyn.Path> paths;
      Absyn.Path p;
      Boolean b;
      DAE.TypeSource ts;

    case (ClassInf.META_UNIONTYPE(p),_,SCode.PARTS(elementLst = els))
      equation
        p = Absyn.makeFullyQualified(p);
        slst = getListOfStrings(els);
        paths = List.map1r(slst, Absyn.pathReplaceIdent, p);
        b = listLength(paths)==1;
        ts = Types.mkTypeSource(SOME(p));
      then
        SOME(DAE.T_METAUNIONTYPE(paths,b,ts));

    else t;
  end matchcontinue;
end fixUniontype;

public function createLhsExp "function: createLhsExp"
  input list<Absyn.Exp> inList;
  output Absyn.Exp outExp;
algorithm
  outExp := matchcontinue (inList)
    local
      list<Absyn.Exp> lst;
      Absyn.Exp firstExp;
    case (firstExp :: {}) then firstExp;
    case (lst) then Absyn.TUPLE(lst);
  end matchcontinue;
end createLhsExp;

public function onlyCrefExpressions "function: onlyCrefExpressions"
  input list<Absyn.Exp> expList;
  output Boolean boolVal;
algorithm
  boolVal :=
  matchcontinue (expList)
    local
      list<Absyn.Exp> restList;
    case ({}) then true;
    case (Absyn.CREF(_) :: restList) then onlyCrefExpressions(restList);
    else false;
  end matchcontinue;
end onlyCrefExpressions;

public function isTupleExp
  input Absyn.Exp inExp;
  output Boolean b;
algorithm
  b := matchcontinue (inExp)
    case Absyn.TUPLE(_) then true;
    case _ then false;
  end matchcontinue;
end isTupleExp;

public function extractListFromTuple "author: KS
 Given an Absyn.Exp, this function will extract the list of expressions if the
 expression is a tuple, otherwise a list of length one is created"
  input Absyn.Exp inExp;
  input Integer numOfExps;
  output list<Absyn.Exp> outList;
algorithm
  outList :=
  matchcontinue (inExp,numOfExps)
    local
      list<Absyn.Exp> l;
      Absyn.Exp exp;
    case (Absyn.TUPLE(l),1) then {Absyn.TUPLE(l)};
    case (Absyn.TUPLE(l),_) then l;
    case (exp,_) then {exp};
  end matchcontinue;
end extractListFromTuple;

public function tryToConvertArrayToList
"Convert an array, T[:], of a MetaModelica type into list (done by a different function).
MetaModelica types can only be of array<T> type, not T[:].
This is mainly to produce better error messages."
  input DAE.Exp exp;
  input DAE.Type ty;
  output DAE.Exp outExp;
  output DAE.Type outTy;
algorithm
  (outExp,outTy) := match (exp,ty)
    local
      DAE.Type flatType;
    case (_,_)
      equation
        (flatType,_) = Types.flattenArrayType(ty);
        false = (not Types.isString(flatType) and Types.isBoxedType(flatType)) or Flags.isSet(Flags.RML) "debug flag to produce better error messages by converting all arrays into lists; the compiler does not use Modelica-style arrays anyway";
      then (exp,ty);
  end match;
end tryToConvertArrayToList;

annotation(__OpenModelica_Interface="frontend");
end MetaUtil;
