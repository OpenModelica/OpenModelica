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

package MetaUtil
" file:	       MetaUtil.mo
  package:     MetaUtil
  description: Different MetaModelica extension functions.

  RCS: $Id$

  "

public import Absyn;
public import ClassInf;
public import DAE;
public import Debug;
public import Env;
public import SCode;
public import SCodeUtil;

protected import Exp;
protected import Lookup;
protected import RTOpts;
protected import Types;
protected import Util;
protected import System;

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

public function simplifyListExp "function: simplifyListExp
Author: KS
Used by Static.elabExp to simplify some cons/list expressions.
"
  input DAE.ExpType t;
  input DAE.Exp e1;
  input DAE.Exp e2;
  output DAE.Exp expOut;
algorithm
  expOut :=
  matchcontinue (t,e1,e2)
    local
      DAE.Exp localE1,localE2;
      DAE.ExpType tLocal;
    case (tLocal,localE1,DAE.LIST(_,expList))
      local
        list<DAE.Exp> expList,expList2;
      equation
        expList2 = listAppend({localE1},expList);
      then DAE.LIST(tLocal,expList2);
    case (tLocal,localE1,localE2) then DAE.CONS(tLocal,localE1,localE2);
  end matchcontinue;
end simplifyListExp;

public function fixListConstructorsInArgs "function: fixListConstructorsInArgs
	Author: KS
	In a function call, an Absyn.ARRAY() will be transformed into an Absyn.LIST()
	if the corresponding argument type is a list
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef funcName;
  input list<Absyn.Exp> inArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output list<Absyn.Exp> outArgs;
  output list<Absyn.NamedArg> outNamedArgs;
algorithm
  (outCache,outEnv,outArgs,outNamedArgs) :=
  matchcontinue (inCache,inEnv,funcName,inArgs,inNamedArgs)
    case (cache,env,fn,args,nargs)
      local
        Env.Cache cache;
        Env.Env env;
        Absyn.ComponentRef fn;
        Absyn.Path fn2;
        list<Absyn.Exp> args;
        list<Absyn.NamedArg> nargs;
        list<SCode.Element> elemList;
        list<DAE.Type> typeList1;
        list<DAE.FuncArg> typeList2;
      equation
        fn2 = Absyn.crefToPath(fn);

        (cache,typeList1) = Lookup.lookupFunctionsInEnv(cache,env, fn2);

        typeList2 = extractFuncTypes(typeList1);
        args = fixListConstructorsInArgs2(typeList2,args,{});
        nargs = fixListConstructorsInArgs3(typeList2,nargs,{});
      then (cache,env,args,nargs);
    case (_,_,_,_,_)
      equation
        print("could not look up class");
        Debug.fprint("failtrace", "- could not lookup class for constant list constructors.");
      then fail();
  end matchcontinue;
end fixListConstructorsInArgs;

public function extractFuncTypes "function: extractNameAndType
	Author: KS
	Extracts the name and type.
"
  input list<DAE.Type> inElem;
  output list<DAE.FuncArg> outList;
algorithm
  outList :=
  matchcontinue(inElem)
    case ({}) then {};
    case ((DAE.T_FUNCTION(typeList,_,_),_) :: {})
      local
        list<DAE.FuncArg> typeList;
      equation
      then typeList;
    case (_) then {}; // If a function has more than one definition we do not
                      // bother. SHOULD BE FIXED
  end matchcontinue;
end extractFuncTypes;

public function fixListConstructorsInArgs2 "function: fixListConstructorsInArgs2
	author: KS
"
  input list<DAE.FuncArg> inTypes;
  input list<Absyn.Exp> inArgs;
  input list<Absyn.Exp> accList;
  output list<Absyn.Exp> outArgs;
algorithm
  outArgs :=
  matchcontinue (inTypes,inArgs,accList)
    case ({},localInArgs,_)
      local
        list<Absyn.Exp> localInArgs;
      equation
      then localInArgs;
    case (localInTypes,localInArgs,localAccList)
      local
        list<DAE.FuncArg> localInTypes;
        list<Absyn.Exp> localInArgs,localAccList;
      equation
        localInArgs = fixListConstructorsInArgs2Helper(localInTypes,localInArgs,localAccList);
      then localInArgs;
  end matchcontinue;
end fixListConstructorsInArgs2;

public function fixListConstructorsInArgs2Helper  "function: fixListConstructorsInArgs2
	Author: KS
	Helper function to fixListConstructorsInArgs
"
  input list<DAE.FuncArg> inTypes;
  input list<Absyn.Exp> inArgs;
  input list<Absyn.Exp> accList;
  output list<Absyn.Exp> outArgs;
algorithm
  outArgs :=
  matchcontinue (inTypes,inArgs,accList)
    local
      list<Absyn.Exp> localAccList;
    case (_,{},localAccList) then localAccList;
    case ({},_,localAccList)
      equation
        Debug.fprint("failtrace", "- wrong number of arguments in function call?.");
      then fail();
    case ((_,(DAE.T_LIST(_),_)) :: restTypes,Absyn.ARRAY(expList) :: restArgs,localAccList)
      local
        list<Absyn.Exp> expList,restArgs;
        list<DAE.FuncArg> restTypes;
      equation
        expList = transformArrayNodesToListNodes(expList,{});
        localAccList = listAppend(localAccList,{Absyn.LIST(expList)});
        localAccList = fixListConstructorsInArgs2Helper(restTypes,restArgs,localAccList);
      then localAccList;
    case (_ :: restTypes,firstArg :: restArgs,localAccList)
      local
        Absyn.Exp firstArg;
        list<Absyn.Exp> restArgs;
        list<DAE.FuncArg> restTypes;
      equation
        localAccList = listAppend(localAccList,{firstArg});
        localAccList = fixListConstructorsInArgs2Helper(restTypes,restArgs,localAccList);
      then localAccList;
  end matchcontinue;
end fixListConstructorsInArgs2Helper;


public function fixListConstructorsInArgs3 "function: fixListConstructorsInArgs2
author: KS
"
  input list<DAE.FuncArg> inTypes;
  input list<Absyn.NamedArg> inNamedArgs;
  input list<Absyn.NamedArg> accList;
  output list<Absyn.NamedArg> outArgs;
algorithm
  outArgs :=
  matchcontinue (inTypes,inNamedArgs,accList)
    case ({},localInArgs,_)
      local
        list<Absyn.NamedArg> localInArgs;
      equation
      then localInArgs;
    case (localInTypes,localInArgs,localAccList)
      local
        list<DAE.FuncArg> localInTypes;
        list<Absyn.NamedArg> localInArgs,localAccList;
      equation
        localInArgs = fixListConstructorsInArgs3Helper(localInTypes,localInArgs,localAccList);
      then localInArgs;
  end matchcontinue;
end fixListConstructorsInArgs3;


public function fixListConstructorsInArgs3Helper "function: fixListConstructorsInArgs3
	Author: KS
	Helper function to fixListConstructorsInArgs
"
  input list<DAE.FuncArg> inTypes;
  input list<Absyn.NamedArg> inNamedArgs;
  input list<Absyn.NamedArg> accList;
  output list<Absyn.NamedArg> outArgs;
algorithm
  outArgs :=
  matchcontinue (inTypes,inNamedArgs,accList)
    local
       list<Absyn.NamedArg> localAccList;
    case (_,{},localAccList) then localAccList;
    case (argTypes,Absyn.NAMEDARG(id,Absyn.ARRAY(expList)) :: restArgs,localAccList)
      local
        list<Absyn.Exp> expList;
        Absyn.Ident id;
        list<DAE.FuncArg> argTypes;
        list<Absyn.NamedArg> restArgs;
      equation
        ((DAE.T_LIST(_),_)) = findArgType(id,argTypes);
        expList = transformArrayNodesToListNodes(expList,{});
        localAccList = listAppend(localAccList,{Absyn.NAMEDARG(id,Absyn.LIST(expList))});
        localAccList = fixListConstructorsInArgs3Helper(argTypes,restArgs,localAccList);
      then localAccList;
    case (argTypes,firstArg :: restArgs,localAccList)
      local
        Absyn.NamedArg firstArg;
        list<DAE.FuncArg> argTypes;
        list<Absyn.NamedArg> restArgs;
      equation
        localAccList = listAppend(localAccList,{firstArg});
        localAccList = fixListConstructorsInArgs3Helper(argTypes,restArgs,localAccList);
      then localAccList;
  end matchcontinue;
end fixListConstructorsInArgs3Helper;


public function findArgType "function: findArgType
	Author: KS
	Helper function to fixListConstructorsInArgs
"
  input Absyn.Ident id;
  input list<DAE.FuncArg> argTypes;
  output DAE.Type outType;
algorithm
  outType :=
  matchcontinue (id,argTypes)
    local
      Absyn.Ident localId;
    case (localId,{}) then DAE.T_INTEGER_DEFAULT; // Return DUMMIE (this case should not happend)
    case (localId,(localId2,t) :: _)
      local
        DAE.Type t;
        Absyn.Ident localId2;
      equation
        true = (localId ==& localId2);
      then t;
    case (localId,_ :: restList)
      local
        list<DAE.FuncArg> restList;
        DAE.Type t;
      equation
        t = findArgType(localId,restList);
      then t;
  end matchcontinue;
end findArgType;

public function transformArrayNodesToListNodes "function: transformArrayNodesToListNodes"
  input list<Absyn.Exp> inList;
  input list<Absyn.Exp> accList;
  output list<Absyn.Exp> outList;
algorithm
  outList :=
  matchcontinue (inList,accList)
    local
      list<Absyn.Exp> localAccList;
    case ({},localAccList) then localAccList;
    case (Absyn.ARRAY({}) :: restList,localAccList)
      local
        list<Absyn.Exp> restList;
      equation
        localAccList = listAppend(localAccList,{Absyn.LIST({})});
        localAccList = transformArrayNodesToListNodes(restList,localAccList);
      then localAccList;
    case (Absyn.ARRAY(es) :: restList,localAccList)
      local
        list<Absyn.Exp> es,restList;
      equation
        es = transformArrayNodesToListNodes(es,{});
        localAccList = listAppend(localAccList,{Absyn.LIST(es)});
        localAccList = transformArrayNodesToListNodes(restList,localAccList);
      then localAccList;
    case (firstExp :: restList,localAccList)
      local
        list<Absyn.Exp> restList;
        Absyn.Exp firstExp;
      equation
        localAccList = listAppend(localAccList,{firstExp});
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
    case (localT,0) then localT;
    case (localT,n)
      local
        Integer n;
        DAE.Type t;
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
    case (DAE.PROP(t,_))
      local DAE.Type t; equation then t;
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
  outStrings := matchcontinue(els)
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
  end matchcontinue;
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
      Absyn.Program p;
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
      list<Absyn.Class> classes, metaClassesFlat;
      list<list<Absyn.Class>> metaClasses;
      String name;
      Boolean     partialPrefix;
      Boolean     finalPrefix;
      Boolean     encapsulatedPrefix;
      Absyn.Restriction restriction;
      Absyn.ClassDef    body;
      Absyn.Info        info;
      list<Absyn.ClassPart> classParts;
      Option<String>  comment;
    
    case (Absyn.CLASS(body=Absyn.PARTS(classParts=classParts,comment=comment),name=name,partialPrefix=partialPrefix,finalPrefix=finalPrefix,encapsulatedPrefix=encapsulatedPrefix,restriction=restriction,info=info))
      equation
        classParts = Util.listMap(classParts,createMetaClassesFromClassParts);
        body = Absyn.PARTS(classParts,comment);
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
      Absyn.ElementSpec specification;
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
  out := matchcontinue (elementItem,class_)
      local
      Boolean finalPrefix;
      Option<Absyn.RedeclareKeywords> redeclareKeywords;
      Absyn.InnerOuter innerOuter;
      String name;
      Absyn.ElementSpec specification;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constrainClass;
      Boolean replaceable_;
      list<Absyn.Class> metaClasses, classes;
      list<Absyn.ElementItem> elementItems;
    case (Absyn.ELEMENTITEM(Absyn.ELEMENT(specification=Absyn.CLASSDEF(replaceable_=replaceable_),finalPrefix=finalPrefix,redeclareKeywords=redeclareKeywords,innerOuter=innerOuter,name=name,info=info,constrainClass=constrainClass)),class_)
      then Absyn.ELEMENTITEM(Absyn.ELEMENT(finalPrefix,redeclareKeywords,innerOuter,name,Absyn.CLASSDEF(replaceable_,class_),info,constrainClass));
  end matchcontinue;
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
      SCode.ClassDef d_1;
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
  outcls := matchcontinue(els)
    local
      list<Absyn.ElementItem> rest;
      Absyn.Class c;      
      list<Absyn.Class> clst;
      String uniontypeName, n;
      Boolean p,f,e;
      Absyn.Restriction r;
      Absyn.ClassDef b;
      String fn;
      Boolean ro;
      Integer index,lns,cns,lne,cne;   
    
    case({}) then {};
    
    case(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = c)))::rest)
      equation
        clst = convertElementsToClasses(rest);
      then 
        c::clst;
  end matchcontinue;
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

public function mmc_mk_box "function: mmc_mk_box
  Chooses mmc_mk_box<n>(ctor, ...) or mmc_mk_box(<n>
  depending on the size of the box. /sjoelund"
  input Integer numBoxes;
  input String val;
  output String out;
  String numStr,tmp1,tmp2,tmp3;
algorithm
  numStr := intString(numBoxes);
  tmp1 := "(" +& numStr +& ",";
  tmp2 := numStr +& "(";
  tmp3 := Util.if_(numBoxes > 9, tmp1, tmp2); // mmc_mk_box<n>( or mmc_mk_box(<n>,
  out := System.stringAppendList({"mmc_mk_box",tmp3,val,")"});
end mmc_mk_box;

//Generates the mk_box<size>(<index>,<data>::<data>)
public function listToBoxes "function: listToBoxes
MetaModelica extension, added by simbj"
  input list<String> varList;
  input list<DAE.ExpType> expList;
  input Integer index;
  input String name;
  output String outString;
algorithm
  outString := matchcontinue (varList,expList,index,name)
    local
      String boxStr,expStr;
      list<String> varList;
      Integer numberOfVariables,index;
      String tmp1,tmp2,tmp3,tmp4,tmp5;
    
    case (varList,expList,index,name)
      equation
        numberOfVariables = listLength(expList)+1;
        expStr = createExpStr(varList,expList);
        tmp1 = intString(numberOfVariables);
        tmp2 = intString(index+3 /* 0 and 1 are reserved by other types. 2 is reserved by regular records */);
        tmp3 = "(" +& tmp1 +& ",";
        tmp4 = tmp1 +& "(";
        tmp5 = Util.if_(numberOfVariables > 9, tmp3, tmp4); // mmc_mk_box<n>( or mmc_mk_box(<n>,
        name = Util.stringReplaceChar(name, ".", "_");
        expStr = System.stringAppendList({tmp2,",&",name,"__desc",expStr});
        expStr = mmc_mk_box(numberOfVariables, expStr);
      then expStr;
    
    case (_,_,_,_)
      equation
        Debug.fprint("failtrace", "- MetaUtil.listToBoxes failed\n");
      then fail();
  end matchcontinue;
end listToBoxes;

public function createExpStr
  input list<String> varList;
  input list<DAE.ExpType> expList;
  output String outString;
algorithm
  outString := matchcontinue(varList,expList)
  local
    list<String> restVar;
    list<DAE.ExpType> restExp;
    String firstVar,restStr;
    DAE.ExpType firstExp;
    case ({},{}) then "";
    case (firstVar::restVar,firstExp::restExp)
      equation
        firstVar = createConstantCExp2(firstExp,firstVar);
        restStr = createExpStr(restVar,restExp);
        firstVar = System.stringAppendList({",",firstVar,restStr});
        then firstVar;
  end matchcontinue;
end createExpStr;

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
      then Absyn.R_UNKNOWN;
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
  elementout := matchcontinue(elementin,name,index)
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
  end matchcontinue;
end fixElement;


function fixElementItem
  input Absyn.ElementItem elementItemin;
  input String name;
  input Integer index;
  output Absyn.ElementItem elementItemout;

algorithm
  elementItemout := matchcontinue(elementItemin,name,index)
    local
      Absyn.Element element;
    case(Absyn.ELEMENTITEM(element),name,index)
      equation
        element = fixElement(element,name,index);
      then Absyn.ELEMENTITEM(element);
  end matchcontinue;
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


function fixClassPart
  input Absyn.ClassPart clpartin;
  input String name;
  input Integer index;
  output Absyn.ClassPart clpartout;
  output list<Absyn.ElementItem> elout;
algorithm
  (clpartout,elout) := matchcontinue(clpartin,name,index)
    local
      list<Absyn.ElementItem> elements;
      list<Absyn.ElementItem> elementsFixed;
      String name;
      Integer index;
    case(Absyn.PUBLIC(contents = elements),name,index)
      equation
        elementsFixed = fixElementItems(elements,name,index);
      then (Absyn.PUBLIC(elements),elementsFixed);
    case(Absyn.PROTECTED(contents = elements),name,index)
      equation
        elementsFixed = fixElementItems(elements,name,index);
      then (Absyn.PROTECTED(elements),elementsFixed);
  end matchcontinue;
end fixClassPart;


function fixClassParts

  input list<Absyn.ClassPart> clin;
  input String name;
  input Integer index;
  output list<Absyn.ClassPart> clout;
  output list<Absyn.ElementItem> elout;
algorithm
  (clout,elout) := matchcontinue(clin,name,index)
    local
      Absyn.ClassPart clpart;
      list<Absyn.ClassPart> rest;
      list<Absyn.ElementItem> els;
      String name;
      Integer index;
    case(clpart::rest,name,index)
      equation
        (clpart,els) = fixClassPart(clpart,name,index);
        (rest,_) = fixClassParts(rest,name,index);
      then ((clpart::rest),els);
    case(clpart::nil,name,index)
      equation
        (clpart,els) = fixClassPart(clpart,name,index);
      then ((clpart::nil),els);
  end matchcontinue;
end fixClassParts;


public function fixAstForUniontype
  input Absyn.Element element;
  input Absyn.Restriction re;
  output Absyn.Element elementout;
  output list<Absyn.ElementItem> elLst;
algorithm
  (elementout,elLst) := matchcontinue(element,re)
    local
      Absyn.ElementSpec spec;
      Absyn.Class cl;
      Absyn.ClassDef b;
      list<Absyn.ClassPart> clp;
      list<Absyn.ElementItem> elmnts;
      Option<String>  comment;

      Boolean replaceable_ "replaceable" ;
      Absyn.Class class_ "class" ;

      Absyn.Ident name;
      Boolean     partial_   "true if partial" ;
      Boolean     final_     "true if final" ;
      Boolean     encapsulated_ "true if encapsulated" ;
      Absyn.Info       info;

      Boolean                   final_2;
      Option<Absyn.RedeclareKeywords> redeclareKeywords "replaceable, redeclare" ;
      Absyn.InnerOuter                innerOuter "inner/outer" ;
      Absyn.Ident                     name2;

      Absyn.Info                      info2  "File name the class is defined in + line no + column no" ;
      Option<Absyn.ConstrainClass> constrainClass "constrainClass ; only valid for classdef and component" ;

    case(Absyn.ELEMENT(final_2,redeclareKeywords,innerOuter,name2,spec as
      Absyn.CLASSDEF(replaceable_,cl as Absyn.CLASS(name,partial_,final_,encapsulated_,Absyn.R_UNIONTYPE,b as Absyn.PARTS(clp,comment),info))
      ,info2,constrainClass),Absyn.R_UNIONTYPE)
      equation
        (clp,elmnts) = fixClassParts(clp,name,0);
      then
        (Absyn.ELEMENT(final_2,redeclareKeywords,innerOuter,name2,
          Absyn.CLASSDEF(replaceable_,
            Absyn.CLASS(name,partial_,final_,encapsulated_,
              Absyn.R_UNIONTYPE,
              Absyn.PARTS(clp,comment),
              info)
          ),
          info2,constrainClass),
          elmnts);
    case(_,_)
    then (element,nil);
  end matchcontinue;
end fixAstForUniontype;

/* ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^END^OF^HELPERFUNCTIONS^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ */

public function fixMetaTuple "If a Values.Value is a META_TUPLE, and the property is PROP_TUPLE,
convert the type to the correct format. Else return the type of a PROP"
  input DAE.Properties prop;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (prop)
    local
      Option<Absyn.Path> path;
      list<DAE.Type> tys;
      DAE.Type ty;
    case DAE.PROP_TUPLE((DAE.T_TUPLE(tys),path),_)
      equation
        ty = (DAE.T_METATUPLE(tys),path);
      then ty;
    case DAE.PROP(ty,_) then ty;
  end matchcontinue;
end fixMetaTuple;

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

public function typeConvert "function: typeConvert"
  input DAE.Type t;
  output Absyn.TypeSpec outType;
algorithm
  outType :=
  matchcontinue (t)
    case ((DAE.T_INTEGER(_),_)) then Absyn.TPATH(Absyn.IDENT("Integer"),NONE());
    case ((DAE.T_BOOL(_),_)) then Absyn.TPATH(Absyn.IDENT("Boolean"),NONE());
    case ((DAE.T_STRING(_),_)) then Absyn.TPATH(Absyn.IDENT("String"),NONE());
    case ((DAE.T_REAL(_),_)) then Absyn.TPATH(Absyn.IDENT("Real"),NONE());
    case ((DAE.T_BOXED(t),_)) then typeConvert(t);
    /*case (DAE.T_COMPLEX(ClassInf.RECORD(s), _, _)) local String s;
      equation
      then Absyn.TPATH(Absyn.IDENT(s),NONE()); */
    case ((DAE.T_LIST(t),_))
      local
        Absyn.TypeSpec tSpec;
        list<Absyn.TypeSpec> tSpecList;
      equation
        tSpec = typeConvert(t);
        tSpecList = {tSpec};
      then Absyn.TCOMPLEX(Absyn.IDENT("list"),tSpecList,NONE());
    case ((DAE.T_METAOPTION(t),_))
      local
        Absyn.TypeSpec tSpec;
        DAE.Type t;
        list<Absyn.TypeSpec> tSpecList;
      equation
        tSpec = typeConvert(t);
        tSpecList = {tSpec};
      then Absyn.TCOMPLEX(Absyn.IDENT("Option"),tSpecList,NONE());
    case ((DAE.T_METATUPLE(tList),_))
      local
        Absyn.TypeSpec tSpec;
        list<DAE.Type> tList;
        list<Absyn.TypeSpec> tSpecList;
      equation
        tSpecList = Util.listMap(tList,typeConvert);
      then Absyn.TCOMPLEX(Absyn.IDENT("tuple"),tSpecList,NONE());

    case ((DAE.T_POLYMORPHIC(id),_))
      local
        String id;
      then Absyn.TPATH(Absyn.IDENT(id),NONE);

    case ((DAE.T_META_ARRAY(t),_))
      local
        Absyn.TypeSpec tSpec;
        DAE.Type t;
        list<Absyn.TypeSpec> tSpecList;
      equation
        tSpec = typeConvert(t);
        tSpecList = {tSpec};
      then Absyn.TCOMPLEX(Absyn.IDENT("array"),tSpecList,NONE());

    case ((_,SOME(p)))
      local
        Absyn.Path p;
      then Absyn.TPATH(p, NONE);
    case t
      local String str;
      equation
        true = RTOpts.debugFlag("matchcase");
        str = Types.unparseType(t);
        Debug.fprintln("matchcase", "- MetaUtil.typeConvert failed: " +& str);
      then fail();
  end matchcontinue;
end typeConvert;

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

public function extractOutputVarsType
  input list<DAE.Type> inList;
  input Integer cnt;
  input list<Absyn.ElementItem> accList1;
  input list<Absyn.Exp> accList2;
  output list<Absyn.ElementItem> outList1;
  output list<Absyn.Exp> outList2;
algorithm
  (outList1,outList2) := matchcontinue (inList,cnt,accList1,accList2)
    local
      list<Absyn.ElementItem> localAccList1;
      list<DAE.Type> rest;
      list<Absyn.Exp> localAccList2;
      Integer localCnt;
      DAE.Type ty;
      Absyn.TypeSpec tSpec;
      Absyn.Ident n1,n2;
      Absyn.ElementItem elem1;
      Absyn.Exp elem2;
    case ({},localCnt,localAccList1,localAccList2)
      then (localAccList1,localAccList2);
    case ({(DAE.T_TUPLE(rest),_)},1,{},{})
      equation
        (localAccList1,localAccList2) = extractOutputVarsType(rest,1,{},{});
      then (localAccList1,localAccList2);
    case (ty :: rest, localCnt,localAccList1,localAccList2)
      equation
        tSpec = typeConvert(ty);
        n1 = "var";
        n2 = stringAppend(n1,intString(localCnt));
        elem1 = Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
            tSpec,{Absyn.COMPONENTITEM(Absyn.COMPONENT(n2,{},NONE()),NONE(),NONE())}),
            Absyn.dummyInfo,NONE()));
        elem2 = Absyn.CREF(Absyn.CREF_IDENT(n2,{}));
        localAccList1 = listAppend(localAccList1,{elem1});
        localAccList2 = listAppend(localAccList2,{elem2});
        (localAccList1,localAccList2) = extractOutputVarsType(rest,localCnt+1,localAccList1,localAccList2);
      then (localAccList1,localAccList2);
    case (ty::_,_,_,_)
      equation
        Debug.fprintln("failtrace", "- MetaUtil.extractOutputVarsType failed: " +& Types.unparseType(ty));
      then fail();
  end matchcontinue;
end extractOutputVarsType;

public function createLhsExp "function: createLhsExp"
  input list<Absyn.Exp> inList;
  output Absyn.Exp outExp;
algorithm
  outExp :=
  matchcontinue (inList)
    case (firstExp :: {}) local Absyn.Exp firstExp; equation then firstExp;
    case (lst) local list<Absyn.Exp> lst; equation then Absyn.TUPLE(lst);
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
"Convert an array, T[:], of a MetaModelica type into list. MetaModelica types
can only be of array<T> type, not T[:].
This is mainly to produce better error messages."
  input DAE.Exp exp;
  input DAE.Type ty;
  output DAE.Exp outExp;
  output DAE.Type outTy;
algorithm
  (outExp,outTy) := matchcontinue (exp,ty)
    local
      DAE.Type flatType;
    case (exp,ty)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (flatType,_) = Types.flattenArrayType(ty);
        true = Types.isBoxedType(flatType) or RTOpts.debugFlag("rml") "debug flag to produce better error messages by converting all arrays into lists; the compiler does not use Modelica-style arrays anyway";
        (exp,ty) = Types.matchType(exp, ty, (DAE.T_LIST(DAE.T_BOXED_DEFAULT),NONE()), false);
      then (exp,ty);
    case (exp,ty)
      equation
        false = Types.isBoxedType(ty);
      then (exp,ty);

    case (exp,ty)
      equation
        Debug.fprintln("failtrace", "- Static.tryToConvertArrayToList failed");
      then fail();
  end matchcontinue;
end tryToConvertArrayToList;

end MetaUtil;
