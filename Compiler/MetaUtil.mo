/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
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

package MetaUtil
" file:	       MetaUtil.mo
  package:     MetaUtil
  description: Different MetaModelica extension functions.

  RCS: $Id$

  "
public import Types;
public import Exp;
public import Util;
public import Lookup;
public import Debug;
public import Env;
public import Absyn;
public import SCode;
public import DAE;
public import RTOpts;
public import ClassInf;

public function isList "function: isList
	author: KS
	Return true if list
"
  input Types.Properties prop;
  output Boolean bool;
algorithm
  bool :=
  matchcontinue (prop)
    case (Types.PROP((Types.T_LIST(_),_),_)) then true;
    case (_) then false;
  end matchcontinue;
end isList;

/*
public function typeMatching "function:
	author: KS
	Used by the list constructor. Matching of types.
	The returned value is a type because the type of e.g. list(NONE, SOME(1)) is list<Integer>, not list<NOTYPE>
"
  input Types.Type t;
  input list<Types.Properties> propList;
  output Types.Type out;
algorithm
  out := Util.listReduce();
  matchcontinue (t,propList)
    local
      Types.Type t,t1,t2;
      Types.Properties prop;
      list<Types.Properties> restList;
      String s1,s2;
    case (t,{}) then t;
    case (t1, prop :: restList)
      equation
        t2 = Types.getPropType(prop);
        true = Types.subtype(t2,t1);
        t = typeMatching(t1,restList);
      then t;
    case (t1, prop :: restList)
      equation
        t2 = Types.getPropType(prop);
        true = Types.subtype(t1,t2);
        t = typeMatching(t2,restList);
      then t;
    case (t1, prop :: restList)
      equation
        t2 = Types.getPropType(prop);
        s1 = Types.unparseType(t1);
        s2 = Types.unparseType(t2);
        s1 = Util.stringAppendList({"- MetaUtil.typeMatching: mismatch of types in list constructor:\n  t1=", s1, "\n  t2=", s2});
        Debug.fprintln("failtrace", s1);
      then fail();
  end matchcontinue;
end typeMatching;
*/

public function simplifyListExp "function: simplifyListExp
Author: KS
Used by Static.elabExp to simplify some cons/list expressions.
"
  input Exp.Type t;
  input Exp.Exp e1;
  input Exp.Exp e2;
  output Exp.Exp expOut;
algorithm
  expOut :=
  matchcontinue (t,e1,e2)
    local
      Exp.Exp localE1,localE2;
      Exp.Type tLocal;
    case (tLocal,localE1,Exp.LIST(_,expList))
      local
        list<Exp.Exp> expList,expList2;
      equation
        expList2 = listAppend({localE1},expList);
      then Exp.LIST(tLocal,expList2);
    case (tLocal,localE1,localE2) then Exp.CONS(tLocal,localE1,localE2);
  end matchcontinue;
end simplifyListExp;

public function listToConsCell "function: listToConsCell
Author: KS
In the C-code, a list constructor will consist of
several cons constructor. For instance:
list(1,2,3,4) will be written as
mk_cons(1,mk_cons(2,mk_cons(3,mk_cons(4,mk_nil())))),
(the constants 1,2,3,4 each will be wrapped with a create-constant
function call)
"
  input list<String> varList;
  input list<Exp.Exp> expList;
  output String outString;
algorithm
  outString :=
  matchcontinue (varList,expList)
    case ({},_)
      local
        String s;
      equation
        s = "mmc_mk_nil()";
      then s;
    case (firstVar :: restVar,firstExp :: restExp)
      local
        String firstVar,s,s2;
        list<String> restVar;
        list<Exp.Exp> restExp;
        Exp.Exp firstExp;
      equation
        firstVar = createConstantCExp(firstExp,firstVar);
        s2 = listToConsCell(restVar,restExp);
        s = Util.stringAppendList({"mmc_mk_cons(",firstVar,",",s2,")"});
      then s;
  end matchcontinue;
end listToConsCell;

public function createConstantCExp "function: createConstantCExp2"
  input Exp.Exp exp;
  input String inExp;
  output String s;
  Exp.Type expType;
algorithm
  expType := Exp.typeof(exp);
  s := createConstantCExp2(expType, inExp);
end createConstantCExp;

protected function createConstantCExp2 "function: createConstantCExp2"
  input Exp.Type exp;
  input String inExp;
  output String s;
algorithm
  s :=
  matchcontinue(exp,inExp)
    local
      String localInExp,outStr;
    case (Exp.INT(),localInExp)
      equation
        outStr = Util.stringAppendList({"mmc_mk_icon(",localInExp,")"});
      then outStr;
    case (Exp.REAL(),localInExp)
      equation
        outStr = Util.stringAppendList({"mmc_mk_rcon(",localInExp,")"});
      then outStr;
    case (Exp.BOOL(),localInExp)
      equation
        outStr = Util.stringAppendList({"mmc_mk_icon(",localInExp,")"});
      then outStr;
    case (Exp.STRING(),localInExp)
      equation
        outStr = Util.stringAppendList({"mmc_mk_scon(",localInExp,")"});
      then outStr;
    case (Exp.COMPLEX(name = name, varLst = varLst),localInExp)
      local
        list<Exp.Var> varLst;
        list<String> vars, vars1;
        list<Exp.Type> types;
        String str,name;
      equation
        vars = Util.listMap(varLst, Exp.varName);
        str = stringAppend(localInExp,".");
        vars1 = Util.listMap1r(vars, stringAppend, str);
        types = Util.listMap(varLst, Exp.varType);
        outStr = listToBoxes(vars1,types,-1,name);
      then outStr;
    
    case (_,localInExp) then localInExp;
    
  end matchcontinue;
end createConstantCExp2;

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
        list<Types.Type> typeList1;
        list<Types.FuncArg> typeList2;
      equation
        fn2 = Absyn.crefToPath(fn);

        (cache,typeList1)
        = Lookup.lookupFunctionsInEnv(cache,env, fn2);

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
  input list<Types.Type> inElem;
  output list<Types.FuncArg> outList;
algorithm
  outList :=
  matchcontinue(inElem)
    case ({}) then {};
    case ((Types.T_FUNCTION(typeList,_),_) :: {})
      local
        list<Types.FuncArg> typeList;
      equation
      then typeList;
    case (_) then {}; // If a function has more than one definition we do not
                      // bother. SHOULD BE FIXED
  end matchcontinue;
end extractFuncTypes;

public function fixListConstructorsInArgs2 "function: fixListConstructorsInArgs2
	author: KS
"
  input list<Types.FuncArg> inTypes;
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
        list<Types.FuncArg> localInTypes;
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
  input list<Types.FuncArg> inTypes;
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
    case ((_,(Types.T_LIST(_),_)) :: restTypes,Absyn.ARRAY(expList) :: restArgs,localAccList)
      local
        list<Absyn.Exp> expList,restArgs;
        list<Types.FuncArg> restTypes;
      equation
        expList = transformArrayNodesToListNodes(expList,{});
        localAccList = listAppend(localAccList,{Absyn.LIST(expList)});
        localAccList = fixListConstructorsInArgs2Helper(restTypes,restArgs,localAccList);
      then localAccList;
    case (_ :: restTypes,firstArg :: restArgs,localAccList)
      local
        Absyn.Exp firstArg;
        list<Absyn.Exp> restArgs;
        list<Types.FuncArg> restTypes;
      equation
        localAccList = listAppend(localAccList,{firstArg});
        localAccList = fixListConstructorsInArgs2Helper(restTypes,restArgs,localAccList);
      then localAccList;
  end matchcontinue;
end fixListConstructorsInArgs2Helper;


public function fixListConstructorsInArgs3 "function: fixListConstructorsInArgs2
author: KS
"
  input list<Types.FuncArg> inTypes;
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
        list<Types.FuncArg> localInTypes;
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
  input list<Types.FuncArg> inTypes;
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
        list<Types.FuncArg> argTypes;
        list<Absyn.NamedArg> restArgs;
      equation
        ((Types.T_LIST(_),_)) = findArgType(id,argTypes);
        expList = transformArrayNodesToListNodes(expList,{});
        localAccList = listAppend(localAccList,{Absyn.NAMEDARG(id,Absyn.LIST(expList))});
        localAccList = fixListConstructorsInArgs3Helper(argTypes,restArgs,localAccList);
      then localAccList;
    case (argTypes,firstArg :: restArgs,localAccList)
      local
        Absyn.NamedArg firstArg;
        list<Types.FuncArg> argTypes;
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
  input list<Types.FuncArg> argTypes;
  output Types.Type outType;
algorithm
  outType :=
  matchcontinue (id,argTypes)
    local
      Absyn.Ident localId;
    case (localId,{}) then ((Types.T_INTEGER({}),NONE())); // Return DUMMIE (this case should not happend)
    case (localId,(localId2,t) :: _)
      local
        Types.Type t;
        Absyn.Ident localId2;
      equation
        true = (localId ==& localId2);
      then t;
    case (localId,_ :: restList)
      local
        list<Types.FuncArg> restList;
        Types.Type t;
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
  input Types.Type inType;
  input Integer numLists;
  output Types.Type outType;
algorithm
  outType :=
  matchcontinue (inType,numLists)
    local
      Types.Type localT;
    case (localT,0) then localT;
    case (localT,n)
      local
        Integer n;
        Types.Type t;
      equation
        t = (Types.T_LIST(localT),NONE());
        t = createListType(t,n-1);
      then t;
  end matchcontinue;
end createListType;



public function getTypeFromProp "function: getTypeFromProp"
  input Types.Properties inProp;
  output Types.Type outType;
algorithm
  outType :=
  matchcontinue (inProp)
    case (Types.PROP(t,_))
      local Types.Type t; equation then t;
  end matchcontinue;
end getTypeFromProp;

/*
public function typeMatching
  input Types.Type t;
  input list<Types.Properties> propList;
  output Boolean outBool;
algorithm
  outBool :=
  matchcontinue (t,propList)
    local
      Boolean b;
      Types.Type tLocal;
      list<Types.Properties> restList;
    case (_,{}) then true;
    case (tLocal as (Types.T_INTEGER(_),_),Types.PROP((Types.T_INTEGER(_),_),_) :: restList)
      equation
        b = typeMatching(tLocal,restList);
      then b;
    case (tLocal as (Types.T_REAL(_),_),Types.PROP((Types.T_REAL(_),_),_) :: restList)
      equation
        b = typeMatching(tLocal,restList);
      then b;
    case (tLocal as (Types.T_STRING(_),_),Types.PROP((Types.T_STRING(_),_),_) :: restList)
     equation
        b = typeMatching(tLocal,restList);
      then b;
    case (tLocal as (Types.T_BOOL(_),_),Types.PROP((Types.T_BOOL(_),_),_) :: restList)
     equation
        b = typeMatching(tLocal,restList);
      then b;
    case (tLocal as (Types.T_NOTYPE(),_),Types.PROP((Types.T_NOTYPE(),_),_) :: restList)
     equation
        b = typeMatching(tLocal,restList);
      then b;
    case (tLocal as (Types.T_COMPLEX(ClassInf.RECORD(s1),_,_),_),
      Types.PROP((Types.T_COMPLEX(ClassInf.RECORD(s2),_,_),_),_) :: restList)
      local String s1,s2;
      equation
        true = (s1 ==& s2);
        b = typeMatching(tLocal,restList);
      then b;

    case (tLocal as (Types.T_LIST(t1),_),
      Types.PROP((Types.T_LIST(t2),_),_) :: restList)
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
        Types.TType t;
        Absyn.TypeSpec t2;
      equation
        (localCache,Types.VAR(_,_,_,(t,_),_),_,_) = Lookup.lookupIdent(localCache,localEnv,c);
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

//Added by simbj
//Creates a type for an union type
public function createUnionType "function: createUnionType
  Takes a Class and an original Type as input. If the Class is a uniontype,
  the type is changed to the corresponding T_UNIONTYPE. Else, the original
  in type is used.
"
  input SCode.Class cl;
  input Types.Type inType;
  output Types.Type outType;
algorithm
 outType := matchcontinue(cl,inType)
  local
    list<SCode.Element> els;
    list<String> slst;
    list<Absyn.Path> pathLst;
    Types.Type t;
    Absyn.Path p;
    case (SCode.CLASS(classDef = SCode.PARTS(elementLst = els), restriction = SCode.R_UNIONTYPE),(_,SOME(p)))
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        slst = getListOfStrings(els);
        pathLst = Util.listMap1r(slst, Absyn.pathReplaceIdent, p);
        t = (Types.T_UNIONTYPE(pathLst),SOME(p));
      then t;
    case (_,t) then t;
  end matchcontinue;
end createUnionType;


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

//Added by simbj
//Adds the union type to a DAE
public function addUnionTypeToDAE
  input list<DAE.Element> daeElem;  
  input Types.Type inType;
  output list<DAE.Element> outElem; 
algorithm 
  outElem :=   
  matchcontinue (daeElem,inType)
    case (DAE.VAR(vn,kind,dir,prot,_,e,inst_dims,fl,st,lPath,dae_var_attr,comment,io,_) :: restList,t) 
      local 
        list<DAE.Element> daeE,restList; 
        Exp.ComponentRef vn;
        DAE.VarKind kind;
        DAE.VarDirection dir;
        DAE.VarProtection prot;
        Option<Exp.Exp> e;
        DAE.InstDims inst_dims;
        DAE.Flow fl;
        list<Absyn.Path> lPath;
        Option<DAE.VariableAttributes> dae_var_attr;
        Option<Absyn.Comment> comment;
        Absyn.InnerOuter io;
        Types.Type t;
        DAE.Stream st;
      equation
        daeE = (DAE.VAR(vn,kind,dir,prot,DAE.UNIONTYPE(),e,inst_dims,fl,st,lPath,dae_var_attr,comment,io,t) :: restList);
      then daeE; 
  end matchcontinue;
end addUnionTypeToDAE;


//Added by simbj
//Adds the Metarecord type to a DAE
public function addMetarecordTypeToDAE
  input list<DAE.Element> daeElem;  
  input Types.Type inType;
  output list<DAE.Element> outElem; 
algorithm 
  outElem :=   
  matchcontinue (daeElem,inType)
    case (DAE.VAR(vn,kind,dir,prot,_,e,inst_dims,fl,st,lPath,dae_var_attr,comment,io,_) :: restList,t) 
      local 
        list<DAE.Element> daeE,restList; 
        Exp.ComponentRef vn;
        DAE.VarKind kind;
        DAE.VarDirection dir;
        DAE.VarProtection prot;
        Option<Exp.Exp> e;
        DAE.InstDims inst_dims;
        DAE.Flow fl;
        list<Absyn.Path> lPath;
        Option<DAE.VariableAttributes> dae_var_attr;
        Option<Absyn.Comment> comment;
        Absyn.InnerOuter io;
        Types.Type t;
        DAE.Stream st;
      equation
        daeE = (DAE.VAR(vn,kind,dir,prot,DAE.METARECORD(),e,inst_dims,fl,st,lPath,dae_var_attr,comment,io,t) :: restList);
      then daeE; 
  end matchcontinue;
end addMetarecordTypeToDAE;

public function addListTypeToDAE "function: addListTypeToDAE"
  input list<DAE.Element> daeElem;  
  input Types.Type inType;
  output list<DAE.Element> outElem; 
algorithm 
  outElem :=   
  matchcontinue (daeElem,inType)
    case (DAE.VAR(vn,kind,dir,prot,_,e,inst_dims,fl,st,lPath,dae_var_attr,comment,io,_) :: restList,t) 
      local 
        list<DAE.Element> daeE,restList; 
        Exp.ComponentRef vn;
        DAE.VarKind kind;
        DAE.VarDirection dir;
        DAE.VarProtection prot;
        Option<Exp.Exp> e;
        DAE.InstDims inst_dims;
        DAE.Flow fl;
        list<Absyn.Path> lPath;
        Option<DAE.VariableAttributes> dae_var_attr;
        Option<Absyn.Comment> comment;
        Absyn.InnerOuter io;
        Types.Type t;
        DAE.Stream st;
      equation
        daeE = (DAE.VAR(vn,kind,dir,prot,DAE.LIST(),e,inst_dims,fl,st,lPath,dae_var_attr,comment,io,t) :: restList);
      then daeE; 
  end matchcontinue;
end addListTypeToDAE;

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
  including packages.
"
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
      then Absyn.PROGRAM(classes,w,ts);
  end matchcontinue;
end createMetaClassesInProgram;

protected function createMetaClassesFromPackage "function: createMetaClassesFromPackages
  Helper function to createMetaClassesInProgram
"
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
      Absyn.Class class_;
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
  case(c as Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,body = d as
      Absyn.PARTS(classParts = cls as {Absyn.PUBLIC(contents = els)},comment = _)
      ,info = file_info))
      equation
        r_1 = SCode.elabRestriction(c, r); // uniontype will not get elaborated!
        equality(r_1 = SCode.R_UNIONTYPE);
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
      Integer index;
      String uniontypeName;
      case({}) then {};
      case(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = c)))::rest)
        local list<Absyn.Class> clst;
          String n;
          Boolean p,f,e;
          Absyn.Restriction r;
          Absyn.ClassDef b;
          String fn;
          Boolean ro;
          Integer lns,cns,lne,cne;
        equation
          clst = convertElementsToClasses(rest);
        then c::clst;
    end matchcontinue;
end convertElementsToClasses;

/* Removed 2009-08-19. The args are now generated like any Modelica components.
 * This means we don't have to write cases for every single datatype. /sjoelund
function createFunctionArgsList //helper function for uniontypes
  input SCode.Class c;
  input Env.Cache inCache;
  input Env.Env inEnv;
  output list<tuple<SCode.Ident, tuple<Types.TType, Option<Absyn.Path>>>> fargs;
algorithm
fargs := matchcontinue(c,inCache,inEnv)
  local
    list<SCode.Element> els;
    Env.Cache cache;
    Env.Env env;
  case(SCode.CLASS(restriction =  SCode.R_METARECORD(_,_),classDef = SCode.PARTS(elementLst = els)),cache,env)
    then createFunctionArgsList2(els,cache,env);
  end matchcontinue;
end createFunctionArgsList;

function createFunctionArgsList2
  input list<SCode.Element> els;
  input Env.Cache inCache;
  input Env.Env inEnv;
  output list<tuple<SCode.Ident, tuple<Types.TType, Option<Absyn.Path>>>> fargs;
algorithm
   fargs := matchcontinue(els,inCache,inEnv)
   local
     SCode.Element e;
     list<SCode.Element> rest;
     SCode.Ident name,typeName;
     Types.Type t;
     Env.Cache cache;
     Env.Env env,env_1;
     Absyn.Path path;
     list<tuple<SCode.Ident, tuple<Types.TType, Option<Absyn.Path>>>> fargs;
     SCode.Class cl;
   case({},cache,env)
     then {};
       // Special case for recursive uniontypes. sjoelund 2009-05-13
   case(SCode.COMPONENT(component = name,typeSpec = Absyn.TPATH(path = path))::rest,cache,env)
     equation
       (cache,cl,env_1) = Lookup.lookupClass(cache,env,path,true);
       SCode.CLASS(restriction = SCode.R_UNIONTYPE()) = cl;
       t = createUnionType(cl,NONE);
       fargs = createFunctionArgsList2(rest,cache,env);
     then (name,t)::fargs;
       // Special case for (non-uniontype) records
   case(SCode.COMPONENT(component = name,typeSpec = Absyn.TPATH(path = path))::rest,cache,env)
     equation
       (cache,cl as SCode.CLASS(restriction = SCode.R_RECORD()),_) = Lookup.lookupClass(cache,env,path,true);
       (cache,(Types.T_FUNCTION(_,t),_),env_1) = Lookup.lookupType(cache, env, path, false);
       fargs = createFunctionArgsList2(rest,cache,env);
     then (name,t)::fargs;
   case(SCode.COMPONENT(component = name,typeSpec = Absyn.TPATH(path = path))::rest,cache,env)
     equation
       (cache,t,env_1) = Lookup.lookupType(cache, env, path, false);
       fargs = createFunctionArgsList2(rest,cache,env);
     then (name,t)::fargs;
   case(SCode.COMPONENT(component = name,typeSpec = Absyn.TPATH(path = path))::rest,cache,env)
     equation
       //failure(Lookup.lookupType(cache, env, path, false));
       t = reparseType(path);
       fargs = createFunctionArgsList2(rest,cache,env);
     then (name,t)::fargs;
   case (SCode.COMPONENT(component = name)::_,_,_)
     equation
       Debug.fprint("failtrace", "MetaUtil.createFunctionArgsList2 failed: ");
       Debug.fprint("failtrace", name);
       Debug.fprint("failtrace", "\n");
     then fail();
   end matchcontinue;
end createFunctionArgsList2;
*/

//Added by simbj
//Reparses type and returns the real type
//NOTE: This is probably a bad way to do this, should be moved, maybe to the parser?
function reparseType
  input Absyn.Path path;
  output Types.Type outType;
algorithm
  outType := matchcontinue(path)
    local
      Types.Type t;
    case(Absyn.IDENT("Integer")) 
      equation
        t = (Types.T_INTEGER({}),NONE());
    then t;
    case(Absyn.IDENT("Real"))
      equation
        t = (Types.T_REAL({}),NONE());
        then t;
    case(Absyn.IDENT("String"))
      equation
        t = (Types.T_STRING({}),NONE());
        then t;
    case(Absyn.IDENT("Boolean"))
      equation
        t = (Types.T_BOOL({}),NONE());
        then t;
  end matchcontinue;
end reparseType;

public function mmc_mk_box "function: mmc_mk_box
  Chooses mmc_mk_box<n>(ctor, ...) or mmc_mk_box(<n>
  depending on the size of the box. /sjoelund
"
  input Integer numBoxes;
  input String val;
  output String out;
  String numStr,tmp1,tmp2,tmp3;
algorithm
  numStr := intString(numBoxes);
  tmp1 := "(" +& numStr +& ",";
  tmp2 := numStr +& "(";
  tmp3 := Util.if_(numBoxes > 9, tmp1, tmp2); // mmc_mk_box<n>( or mmc_mk_box(<n>,
  out := Util.stringAppendList({"mmc_mk_box",tmp3,val,")"});
end mmc_mk_box;

//Generates the mk_box<size>(<index>,<data>::<data>)
public function listToBoxes "function: listToBoxes 
MetaModelica extension, added by simbj
"
  input list<String> varList; 
  input list<Exp.Type> expList;  
  input Integer index;
  input String name;
  output String outString;
algorithm  
  outString := 
  matchcontinue (varList,expList,index,name) 
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
        expStr = Util.stringAppendList({tmp2,",&",name,"__desc",expStr});
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
  input list<Exp.Type> expList;
  output String outString;
algorithm
  outString := matchcontinue(varList,expList)
  local
    list<String> restVar;
    list<Exp.Type> restExp;
    String firstVar,restStr;
    Exp.Type firstExp;
    case ({},{}) then "";
    case (firstVar::restVar,firstExp::restExp)
      equation
        firstVar = createConstantCExp2(firstExp,firstVar);
        restStr = createExpStr(restVar,restExp);
        firstVar = Util.stringAppendList({",",firstVar,restStr});
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
      String name;
      Integer index;
      Absyn.Ident ident;
      Absyn.Path path;
      case(Absyn.R_RECORD(),name,index)
        equation
          ident = name;
          path = Absyn.IDENT(ident);
      then Absyn.R_METARECORD(path,index);
      case(_,_,_)
      then resin;
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
        String name;
        Integer index;
        
      case(Absyn.CLASS(n,p,f,e,res,b,i),name,index)
        equation
          res = fixRestriction(res,name,index);
      then Absyn.CLASS(n,p,f,e,res,b,i);
      case(_,_,_)
      then classin;
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
      String name;
      Integer index;
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
      String name;
      Integer index;
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
      String name;
      Integer index;
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
      String name;
      Integer index;
    case(element::rest,name,index)
      equation
        element = fixElementItem(element,name,index);
        rest = fixElementItems(rest,name,index+1);   
      then (element::rest);
    case(element::nil,name,index)
      equation
        element = fixElementItem(element,name,index);
      then (element::nil);
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
  input Types.Properties prop;
  output Types.Type outType;
algorithm
  outType := matchcontinue (prop)
    local
      Option<Absyn.Path> path;
      list<Types.Type> tys;
      Types.Type ty;
    case Types.PROP_TUPLE((Types.T_TUPLE(tys),path),_)
      equation
        ty = (Types.T_METATUPLE(tys),path);
      then ty;
    case Types.PROP(ty,_) then ty;
  end matchcontinue;
end fixMetaTuple;

public function constructorCallTypeToNamesAndTypes "Fetches the field names
and types from a record call or metarecord call"
  input Types.Type inType;
  output list<String> varNames;
  output list<Types.Type> outTypes;
algorithm
  (varNames,outTypes) := matchcontinue (inType)
    local
      list<String> names;
      list<Types.Type> types;
      list<Types.FuncArg> fargs;
      list<Types.Var> fields;
    case ((Types.T_METARECORD(fields = fields),_))
      equation
        names = Util.listMap(fields, Types.getVarName);
        types = Util.listMap(fields, Types.getVarType);
      then (names,types);
    case ((Types.T_FUNCTION(fargs, (Types.T_COMPLEX(complexClassType = ClassInf.RECORD(_)),_)),_))
      equation
        names = Util.listMap(fargs, Util.tuple21);
        types = Util.listMap(fargs, Util.tuple22);
      then (names,types);
  end matchcontinue;
end constructorCallTypeToNamesAndTypes;

public function typeConvert "function: typeConvert"
  input Types.Type t;
  output Absyn.TypeSpec outType;
algorithm
  outType :=
  matchcontinue (t)
    case ((Types.T_INTEGER(_),_)) then Absyn.TPATH(Absyn.IDENT("Integer"),NONE());
    case ((Types.T_BOOL(_),_)) then Absyn.TPATH(Absyn.IDENT("Boolean"),NONE());
    case ((Types.T_STRING(_),_)) then Absyn.TPATH(Absyn.IDENT("String"),NONE());
    case ((Types.T_REAL(_),_)) then Absyn.TPATH(Absyn.IDENT("Real"),NONE());
    /*case (Types.T_COMPLEX(ClassInf.RECORD(s), _, _)) local String s;
      equation
      then Absyn.TPATH(Absyn.IDENT(s),NONE()); */
    case ((Types.T_LIST(t),_))
      local
        Absyn.TypeSpec tSpec;
        list<Absyn.TypeSpec> tSpecList;
      equation
        tSpec = typeConvert(t);
        tSpecList = {tSpec};
      then Absyn.TCOMPLEX(Absyn.IDENT("list"),tSpecList,NONE());
    case ((Types.T_METAOPTION(t),_))
      local
        Absyn.TypeSpec tSpec;
        Types.Type t;
        list<Absyn.TypeSpec> tSpecList;
      equation
        tSpec = typeConvert(t);
        tSpecList = {tSpec};
      then Absyn.TCOMPLEX(Absyn.IDENT("Option"),tSpecList,NONE());
    case ((Types.T_METATUPLE(tList),_))
      local
        Absyn.TypeSpec tSpec;
        list<Types.Type> tList;
        list<Absyn.TypeSpec> tSpecList;
      equation
        tSpecList = Util.listMap(tList,typeConvert);
      then Absyn.TCOMPLEX(Absyn.IDENT("tuple"),tSpecList,NONE());
    
    case ((Types.T_POLYMORPHIC(id),_))
      local
        String id;
      then Absyn.TPATH(Absyn.IDENT(id),NONE);
    
    case ((_,SOME(p)))
      local
        Absyn.Path p;
      then Absyn.TPATH(p, NONE);
    case t
      local String str;
      equation
        str = Types.unparseType(t);
        Debug.fprintln("matchcase", "- MetaUtil.typeConvert failed: " +& str);
      then fail();
  end matchcontinue;
end typeConvert;

end MetaUtil;
