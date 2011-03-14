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

encapsulated package MetaUtil
" file:         MetaUtil.mo
  package:     MetaUtil
  description: Different MetaModelica extension functions.

  RCS: $Id$

  "

public import Absyn;
public import ClassInf;
public import DAE;
public import Debug;
public import SCode;
public import SCodeUtil;

protected import Error;
protected import RTOpts;
protected import Types;
protected import Util;

public function isList "function: isList
  author: KS
  Return true if list
"
  input DAE.Properties prop;
  output Boolean bool;
algorithm
  bool :=
  matchcontinue (prop)
    case (DAE.PROP((DAE.T_LIST(_),_),_)) then true;
    case (_) then false;
  end matchcontinue;
end isList;

public function transformArrayNodesToListNodes "function: transformArrayNodesToListNodes"
  input list<Absyn.Exp> inList;
  input list<Absyn.Exp> accList;
  output list<Absyn.Exp> outList;
algorithm
  outList :=
  matchcontinue (inList,accList)
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
        t = (DAE.T_LIST(localT),NONE());
        t = createListType(t,n-1);
      then t;
  end matchcontinue;
end createListType;



public function getTypeFromProp "function: getTypeFromProp"
  input DAE.Properties inProp;
  output DAE.Type outType;
algorithm
  outType :=
  matchcontinue (inProp)
    local
      DAE.Type t;
    case (DAE.PROP(t,_)) equation then t;
  end matchcontinue;
end getTypeFromProp;

/*
public function typeMatching
  input DAE.Type t;
  input list<DAE.Properties> propList;
  output Boolean outBool;
algorithm
  outBool :=
  matchcontinue (t,propList)
    local
      Boolean b;
      DAE.Type tLocal;
      list<DAE.Properties> restList;
    case (_,{}) then true;
    case (tLocal as (DAE.T_INTEGER(_),_),DAE.PROP((DAE.T_INTEGER(_),_),_) :: restList)
      equation
        b = typeMatching(tLocal,restList);
      then b;
    case (tLocal as (DAE.T_REAL(_),_),DAE.PROP((DAE.T_REAL(_),_),_) :: restList)
      equation
        b = typeMatching(tLocal,restList);
      then b;
    case (tLocal as (DAE.T_STRING(_),_),DAE.PROP((DAE.T_STRING(_),_),_) :: restList)
     equation
        b = typeMatching(tLocal,restList);
      then b;
    case (tLocal as (DAE.T_BOOL(_),_),DAE.PROP((DAE.T_BOOL(_),_),_) :: restList)
     equation
        b = typeMatching(tLocal,restList);
      then b;
    case (tLocal as (DAE.T_NOTYPE(),_),DAE.PROP((DAE.T_NOTYPE(),_),_) :: restList)
     equation
        b = typeMatching(tLocal,restList);
      then b;
    case (tLocal as (DAE.T_COMPLEX(ClassInf.RECORD(s1),_,_),_),
      DAE.PROP((DAE.T_COMPLEX(ClassInf.RECORD(s2),_,_),_),_) :: restList)
      local String s1,s2;
      equation
        true = (s1 ==& s2);
        b = typeMatching(tLocal,restList);
      then b;

    case (tLocal as (DAE.T_LIST(t1),_),
      DAE.PROP((DAE.T_LIST(t2),_),_) :: restList)
      local String s1,s2;
      equation
        true = (s1 ==& s2);
        b = typeMatching(tLocal,restList);
      then b;

    case (_,_) then false;
  end matchcontinue;
end typeMatching;  */
/*
public function createMatchcontinueResultVars "function: createMatchcontinueResultVars"
  input Env.Cache cache;
  input Env.Env env;
  input list<Absyn.Exp> refList;
  input Integer num;
  input list<Absyn.ElementItem> accDeclList;
  input list<Absyn.Exp> accVarList;
  output Env.Cache outCache;
  output list<Absyn.ElementItem> outDecls;
  output list<Absyn.Exp> outVarList;
algorithm
  (outCache,outDecls,outVarList) :=
  matchcontinue (cache,env,refList,num)
    local
      Env.Cache localCache;
      Env.Env localEnv;
      list<Absyn.ElementItem> localAccDeclList;
      list<Absyn.Exp> localAccVarList;
    case (localCache,_,{},_,localAccDeclList,localAccVarList)
    then (localCache,localAccDeclList,localAccVarList);
    case (localCache,localEnv,Absyn.CREF(Absyn.CREF_IDENT(c,{})) :: restExp,n,localAccDeclList,localAccVarList)
      local
        Absyn.Ident varName,c;
        list<Absyn.ElementItem> varList;
        list<Absyn.Exp> restExp;
        Integer n;
        DAE.TType t;
        Absyn.TypeSpec t2;
      equation
        (localCache,DAE.TYPES_VAR(_,_,_,(t,_),_),_,_) = Lookup.lookupIdent(localCache,localEnv,c);
        t2 = typeConvert(t);
        varName = stringAppend("RES__",intString(n));

        varList = Util.listCreate(Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
            t2,
            {Absyn.COMPONENTITEM(Absyn.COMPONENT(varName,{},NONE()),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0),NONE())));

        localAccVarList = listAppend(localAccVarList,{Absyn.CREF(Absyn.CREF_IDENT(varName,{}))});
        localAccDeclList = listAppend(localAccDeclList,varList);
        (localCache,localAccDeclList,localAccVarList) = createMatchcontinueResultVars(
          localCache,localEnv,restExp,n+1,localAccDeclList,localAccVarList);
      then (localCache,localAccDeclList,localAccVarList);
    case (_,_,_,_,_,_) then fail();
  end matchcontinue;
end createMatchcontinueResultVars;
*/

public function getListOfStrings
input list<SCode.Element> els;
output list<String> outStrings;

algorithm
  outStrings := match(els)
  local
    list<SCode.Element> rest;
    list<String> slst;
    String n;
    case({})
      then {};
    case(SCode.CLASSDEF(name = n)::rest)
      equation
        slst = getListOfStrings(rest);
        then n::slst;
    case(_) then fail();
  end match;
end getListOfStrings;

//Check if a class has a certain restriction, added by simbj
public function classHasMetaRestriction
  input SCode.Class cl;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue(cl)
    local
      SCode.Restriction re1,re2;
    case(SCode.CLASS(restriction = SCode.R_METARECORD(_,_)))
      then true;
    case(_) then false;
  end matchcontinue;
end classHasMetaRestriction;

//Check if a class has a certain restriction, added by simbj
public function classHasRestriction
  input SCode.Class cl;
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
    
    case(_,_) then false;
  end matchcontinue;
end classHasRestriction;

public function createMetaClassesInProgram "function: createMetaClassesInProgram
  Adds metarecord classes to the AST. This function handles a whole program,
  including packages."
  input Absyn.Program program;
  output Absyn.Program out;
algorithm
  out := matchcontinue(program)
    local
      list<Absyn.Class> classes, metaClassesFlat;
      list<list<Absyn.Class>> metaClasses;
      Absyn.Within w;
      Absyn.TimeStamp ts;
    
    case (program)
      equation
        false = RTOpts.acceptMetaModelicaGrammar();
      then program;
    
    case (Absyn.PROGRAM(classes = classes,within_ = w,globalBuildTimes=ts))
      equation
        metaClasses = Util.listMap(classes, createMetaClasses);
        metaClassesFlat = Util.listFlatten(metaClasses);
        classes = Util.listMap(classes, createMetaClassesFromPackage);
        classes = listAppend(classes, metaClassesFlat);
      then 
        Absyn.PROGRAM(classes,w,ts);
  end matchcontinue;
end createMetaClassesInProgram;

protected function createMetaClassesFromPackage "function: createMetaClassesFromPackages
  Helper function to createMetaClassesInProgram"
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
      Absyn.Info        info;
      list<Absyn.ClassPart> classParts;
      Option<String>  comment;
      list<String> typeVars;
    
    case (Absyn.CLASS(body=Absyn.PARTS(typeVars=typeVars,classParts=classParts,comment=comment),name=name,partialPrefix=partialPrefix,finalPrefix=finalPrefix,encapsulatedPrefix=encapsulatedPrefix,restriction=restriction,info=info))
      equation
        classParts = Util.listMap(classParts,createMetaClassesFromClassParts);
        body = Absyn.PARTS(typeVars,classParts,comment);
      then Absyn.CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restriction,body,info);
    
    case (cl) then cl;
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
        lels = Util.listMap(els, createMetaClassesFromElementItem);
        els = Util.listFlatten(lels);
      then Absyn.PUBLIC(els);
    
    case (Absyn.PROTECTED(els))
      equation
        lels = Util.listMap(els, createMetaClassesFromElementItem);
        els = Util.listFlatten(lels);
      then Absyn.PROTECTED(els);
    
    case (classPart) then classPart;
  end matchcontinue;
end createMetaClassesFromClassParts;

protected function createMetaClassesFromElementItem
  input Absyn.ElementItem elementItem;
  output list<Absyn.ElementItem> out;
algorithm
  out := matchcontinue(elementItem)
    local
      Boolean finalPrefix;
      Option<Absyn.RedeclareKeywords> redeclareKeywords;
      Absyn.InnerOuter innerOuter;
      String name;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constrainClass;
      Boolean replaceable_;
      Absyn.Class class_, cl2;
      list<Absyn.Class> metaClasses, classes;
      list<Absyn.ElementItem> elementItems;
    case (Absyn.ELEMENTITEM(Absyn.ELEMENT(specification=Absyn.CLASSDEF(replaceable_=replaceable_,class_=class_),finalPrefix=finalPrefix,redeclareKeywords=redeclareKeywords,innerOuter=innerOuter,name=name,info=info,constrainClass=constrainClass)))
      equation
        metaClasses = createMetaClasses(class_);
        cl2 = createMetaClassesFromPackage(class_);
        classes = cl2 :: metaClasses;
        elementItems = Util.listMap1r(classes,setElementItemClass,elementItem);
      then elementItems;
    case (elementItem) then {elementItem};
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
      String name;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constrainClass;
      Boolean replaceable_;
    case (Absyn.ELEMENTITEM(Absyn.ELEMENT(specification=Absyn.CLASSDEF(replaceable_=replaceable_),finalPrefix=finalPrefix,redeclareKeywords=redeclareKeywords,innerOuter=innerOuter,name=name,info=info,constrainClass=constrainClass)),class_)
      then Absyn.ELEMENTITEM(Absyn.ELEMENT(finalPrefix,redeclareKeywords,innerOuter,name,Absyn.CLASSDEF(replaceable_,class_),info,constrainClass));
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
      Absyn.Info file_info;
    
    case(c as Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
         body = d as Absyn.PARTS(classParts = cls as {Absyn.PUBLIC(contents = els)},comment = _),info = file_info))
      equation
        r_1 = SCodeUtil.translateRestriction(c, r); // uniontype will not get elaborated!
        SCode.R_UNIONTYPE() = r_1;
        els = fixElementItems(els,n,0);
        cllst = convertElementsToClasses(els);
      then cllst;
    case(_) then {};
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
  end match;
end convertElementsToClasses;

//Added by simbj
//Reparses type and returns the real type
//NOTE: This is probably a bad way to do this, should be moved, maybe to the parser?
function reparseType
  input Absyn.Path path;
  output DAE.Type outType;
algorithm
  outType := matchcontinue(path)
    local
      DAE.Type t;
    case(Absyn.IDENT("Integer")) then DAE.T_INTEGER_DEFAULT;
    case(Absyn.IDENT("Real")) then DAE.T_REAL_DEFAULT;
    case(Absyn.IDENT("String")) then DAE.T_STRING_DEFAULT;
    case(Absyn.IDENT("Boolean")) then DAE.T_BOOL_DEFAULT;
  end matchcontinue;
end reparseType;

/* These functions are helper functions for the Uniontypes, added by simbj */
public function getRestriction
  input Absyn.Element el;
  output Absyn.Restriction res;
algorithm
  res := matchcontinue(el)
    local
      Absyn.ElementSpec spec;
      Absyn.Class cl;
      Absyn.Restriction r;
    case(Absyn.ELEMENT(_,_,_,_,spec as Absyn.CLASSDEF(_,cl as Absyn.CLASS(_,_,_,_,r,_,_)),_,_))
      then r;
    case(_)
      then Absyn.R_UNKNOWN();
  end matchcontinue;
end getRestriction;

function fixRestriction
    input Absyn.Restriction resin;
    input String name;
    input Integer index;
    output Absyn.Restriction resout;

algorithm
  resout := matchcontinue(resin,name,index)
    local
      Absyn.Ident ident;
      Absyn.Path path;
    case(Absyn.R_RECORD(),name,index)
      equation
        ident = name;
        path = Absyn.IDENT(ident);
      then Absyn.R_METARECORD(path,index);
    case(_,_,_) then resin;
  end matchcontinue;
end fixRestriction;


function fixClass
  input Absyn.Class classin;
  input String name;
  input Integer index;
  output Absyn.Class classout;
algorithm
  classout := matchcontinue(classin,name,index)
    local
      Absyn.Ident n;
      Boolean p;
      Boolean f;
      Boolean e;
      Absyn.Restriction res;
      Absyn.ClassDef b;
      Absyn.Info i;

    case(Absyn.CLASS(n,p,f,e,res,b,i),name,index)
      equation
        res = fixRestriction(res,name,index);
      then Absyn.CLASS(n,p,f,e,res,b,i);
    case(_,_,_) then classin;
  end matchcontinue;
end fixClass;


function fixElementSpecification
  input Absyn.ElementSpec specin;
  input String name;
  input Integer index;
  output Absyn.ElementSpec specout;
algorithm
  specout := matchcontinue(specin,name,index)
    local
      Boolean rep;
      Absyn.Class c;
    case(Absyn.CLASSDEF(rep,c),name,index)
      equation
        c = fixClass(c,name,index);
      then Absyn.CLASSDEF(rep,c);
    case(_,_,_)
    then specin;
  end matchcontinue;
end fixElementSpecification;

function fixElement
  input Absyn.Element elementin;
  input String name;
  input Integer index;
  output Absyn.Element elementout;

algorithm
  elementout := match(elementin,name,index)
    local
      Boolean f;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter i;
      Absyn.Ident n;
      Absyn.ElementSpec spec;
      Absyn.Info inf;
      Option<Absyn.ConstrainClass> con;
    case(Absyn.ELEMENT(finalPrefix = f, redeclareKeywords = r, innerOuter=i, name=n, specification=spec, info=inf, constrainClass=con),name,index)
      equation
        spec = fixElementSpecification(spec,name,index);
      then Absyn.ELEMENT(f,r,i,n,spec,inf,con);
  end match;
end fixElement;


function fixElementItem
  input Absyn.ElementItem elementItemin;
  input String name;
  input Integer index;
  output Absyn.ElementItem elementItemout;

algorithm
  elementItemout := match(elementItemin,name,index)
    local
      Absyn.Element element;
    case(Absyn.ELEMENTITEM(element),name,index)
      equation
        element = fixElement(element,name,index);
      then Absyn.ELEMENTITEM(element);
  end match;
end fixElementItem;


function fixElementItems
  input list<Absyn.ElementItem> elementItemsin;
  input String name;
  input Integer index;
  output list<Absyn.ElementItem> elementItemsout;
algorithm
  elementItemsout := matchcontinue(elementItemsin,name,index)
    local
      Absyn.ElementItem element;
      list<Absyn.ElementItem> rest;
    case(element::rest,name,index)
      equation
        element = fixElementItem(element,name,index);
        rest = fixElementItems(rest,name,index+1);
      then (element::rest);
    case(element::{},name,index)
      equation
        element = fixElementItem(element,name,index);
      then (element::{});
  end matchcontinue;
end fixElementItems;

/* ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^END^OF^HELPERFUNCTIONS^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ */

public function constructorCallTypeToNamesAndTypes "Fetches the field names
and types from a record call or metarecord call"
  input DAE.Type inType;
  output list<String> varNames;
  output list<DAE.Type> outTypes;
algorithm
  (varNames,outTypes) := matchcontinue (inType)
    local
      list<String> names;
      list<DAE.Type> types;
      list<DAE.FuncArg> fargs;
      list<DAE.Var> fields;
    case ((DAE.T_METARECORD(fields = fields),_))
      equation
        names = Util.listMap(fields, Types.getVarName);
        types = Util.listMap(fields, Types.getVarType);
      then (names,types);
    case ((DAE.T_FUNCTION(fargs,(DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)),_),_),_))
      equation
        names = Util.listMap(fargs, Util.tuple21);
        types = Util.listMap(fargs, Util.tuple22);
      then (names,types);
  end matchcontinue;
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
    case (ClassInf.UNIONTYPE(p),t,SCode.PARTS(elementLst = els))
      equation
        p = Absyn.FULLYQUALIFIED(p);
        slst = getListOfStrings(els);
        paths = Util.listMap1r(slst, Absyn.pathReplaceIdent, p);
      then SOME((DAE.T_UNIONTYPE(paths),SOME(p)));
    case (_,t,_) then t;
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
    case ({}) then false;
    case (Absyn.CREF(Absyn.WILD()) :: _) then false;
    case ({Absyn.CREF(_)}) then true;
    case (Absyn.CREF(_) :: restList) then onlyCrefExpressions(restList);
    case (_) then false;
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

public function extractListFromTuple "function: extractListFromTuple
  author: KS
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
    case (exp,ty)
      equation
        (flatType,_) = Types.flattenArrayType(ty);
        false = (not Types.isString(flatType) and Types.isBoxedType(flatType)) or RTOpts.debugFlag("rml") "debug flag to produce better error messages by converting all arrays into lists; the compiler does not use Modelica-style arrays anyway";
      then (exp,ty);
  end match;
end tryToConvertArrayToList;

public function strictRMLCheck
"If we are checking for strict RML, and function containing a single statement
that is a match expression must be on the form (outputs) := matchcontinue (inputs).
RML does not check this even though it's translated to this internally, so we
must check for it to warn the user."
  input Boolean b;
  input SCode.Class c;
  output Boolean isOK;
algorithm
  isOK := matchcontinue (b,c)
    local
      list<SCode.Element> elts,inelts,outelts;
      list<String> innames,outnames;
      list<Absyn.Exp> outcrefs,increfs;
      Absyn.Exp comp,inputs;
      Absyn.Info info;
    case (false,_) then true;
    case (_,SCode.CLASS(info = info, restriction = SCode.R_FUNCTION(), classDef = SCode.PARTS(elementLst = elts, normalAlgorithmLst = {SCode.ALGORITHM({SCode.ALG_ASSIGN(assignComponent = comp, value = Absyn.MATCHEXP(inputExp = inputs))})})))
      equation
        outcrefs = extractListFromTuple(comp,0);
        increfs = extractListFromTuple(inputs,0);
        inelts = Util.listSelect1(elts, Absyn.INPUT(), SCode.isComponentWithDirection);
        outelts = Util.listSelect1(elts, Absyn.OUTPUT(), SCode.isComponentWithDirection);
        innames = Util.listMap(inelts, SCode.elementName);
        outnames = Util.listMap(outelts, SCode.elementName);
      then strictRMLCheck2(increfs,outcrefs,innames,outnames,info);
    case (_,_) then true;
  end matchcontinue;
end strictRMLCheck;

protected function strictRMLCheck2
"If we are checking for strict RML, and function containing a single statement
that is a match expression must be on the form (outputs) := matchcontinue (inputs).
RML does not check this even though it's translated to this internally, so we
must check for it to warn the user."
  input list<Absyn.Exp> increfs;
  input list<Absyn.Exp> outcrefs;
  input list<String> innames;
  input list<String> outnames;
  input Absyn.Info info;
  output Boolean b;
algorithm
  b := matchcontinue (increfs,outcrefs,innames,outnames,info)
    local
      list<String> names;
    case (increfs,outcrefs,innames,outnames,info)
      equation
        true = (listLength(increfs) <> listLength(innames));
        Error.addSourceMessage(Error.META_STRICT_RML_MATCH_IN_OUT, {"Number of input arguments don't match"}, info);
      then false;
    case (increfs,outcrefs,innames,outnames as _::_,info)
      equation
        true = (listLength(outcrefs) <> listLength(outnames));
        Error.addSourceMessage(Error.META_STRICT_RML_MATCH_IN_OUT, {"Number of output arguments don't match"}, info);
      then false;
    case (increfs,outcrefs,innames,outnames,info)
      equation
        false = (listLength(outnames)+listLength(innames)) == listLength(Util.listUnion(innames,outnames));
        Error.addSourceMessage(Error.META_STRICT_RML_MATCH_IN_OUT, {"An argument in the output has the same name as one in the input"}, info);
      then false;
    case (increfs,outcrefs,innames,outnames,info)
      equation
        failure(_ = Util.listMap(increfs, Absyn.expCref));
        Error.addSourceMessage(Error.META_STRICT_RML_MATCH_IN_OUT, {"Input expression was not a tuple of component references"}, info);
      then false;
    case (increfs,outcrefs,innames,outnames,info)
      equation
        failure(_ = Util.listMap(outcrefs, Absyn.expCref));
        Error.addSourceMessage(Error.META_STRICT_RML_MATCH_IN_OUT, {"Output expression was not a tuple of component references"}, info);
      then false;
    case (increfs,outcrefs,innames,outnames,info)
      equation
        names = Util.listMap(increfs, Absyn.expComponentRefStr);
        failure(equality(names = innames));
        Error.addSourceMessage(Error.META_STRICT_RML_MATCH_IN_OUT, {"The input does not match"}, info);
      then false;
    case (increfs,{Absyn.CREF(Absyn.WILD())},innames,{},info) then true;
    case (increfs,outcrefs,innames,outnames,info)
      equation
        names = Util.listMap(outcrefs, Absyn.expComponentRefStr);
        failure(equality(names = outnames));
        Error.addSourceMessage(Error.META_STRICT_RML_MATCH_IN_OUT, {"The output does not match"}, info);
      then false;
    case (_,_,_,_,_) then true;
  end matchcontinue;
end strictRMLCheck2;

end MetaUtil;
