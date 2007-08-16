package MetaUtil "
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linkopings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

 Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

 Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

 Neither the name of Linkopings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  
  file:	 MetaUtil.mo
  module:      MetaUtil
  description: MetaUtil 
  Different MetaModelica extension functions.
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


public function typeMatching "function:   
	author: KS
	Used by the list constructor. Matching of types.
"
  input Types.Type t;
  input list<Types.Properties> propList; 
  output Boolean outBool; 
algorithm
  outBool := 
  matchcontinue (t,propList)
    local 
      Boolean b;
      Types.Type t1,t2; 
      list<Types.Properties> restList;
    case (_,{}) then true; 
    case (t1,Types.PROP(t2,_) :: restList) 
      equation
        true = Types.subtype(t2,t1); 
        b = typeMatching(t1,restList);  
      then b;
    case (_,_) 
      equation 
        Debug.fprint("failtrace", "-mismatch of types in list constructor\n");
      then fail();
  end matchcontinue;
end typeMatching;

public function consMatch "function: consMatch
Author: KS  
Used by the cons constructor
"
  input Types.Properties firstArg;
  input Types.Properties secondArg;
  output Boolean b;
algorithm 
  b :=
  matchcontinue (firstArg,secondArg)
    local
      Types.Type tLocal,t; 
      Boolean b2;
    case (Types.PROP(tLocal,_),Types.PROP((Types.T_LIST((Types.T_NOTYPE(),_)),_),_)) then true;  
    case (Types.PROP(tLocal,_),Types.PROP((Types.T_LIST(t),_),_)) 
      equation
        b2 = Types.subtype(tLocal,t);
      then b2;
    case (_,_) then false;
  end matchcontinue;  
end consMatch;  

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

public function createConstantCExp "function: createConstantCExp"
  input Exp.Exp exp; 
  input String inExp;
  output String s; 
algorithm
  s := 
  matchcontinue(exp,inExp)  
    local 
      String localInExp,outStr;
    case (Exp.ICONST(_),localInExp) 
      local equation 
        outStr = Util.stringAppendList({"mmc_mk_icon(",localInExp,")"});
      then outStr; 
    case (Exp.RCONST(_),localInExp) 
      local equation 
        outStr = Util.stringAppendList({"mmc_mk_rcon(",localInExp,")"});
      then outStr; 
    case (Exp.BCONST(_),localInExp)   
      local equation 
        outStr = Util.stringAppendList({"mmc_mk_icon(",localInExp,")"});
      then outStr; 
    case (_,localInExp) then localInExp;      
  end matchcontinue;
end createConstantCExp;
  
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


public function evalTypeSpec "function: evalTypeSpec"
  input Absyn.TypeSpec typeSpec; 
  input Integer numLists;
  output Absyn.Path outPath; 
  output Integer outNumLists;
algorithm 
  (outPath,outNumLists) := 
  matchcontinue (typeSpec,numLists) 
    local 
      Absyn.Path tpath; 
      Integer n;
    case (Absyn.TPATH(tpath, _),n) then (tpath,n); 
    case (Absyn.TCOMPLEX(Absyn.IDENT("list"),tSpec :: _,_),n) 
      local  
        Absyn.TypeSpec tSpec;  
      equation   
        (tpath,n) = evalTypeSpec(tSpec,n+1);    
      then (tpath,n);  
  end matchcontinue;
end evalTypeSpec;   

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


public function addListTypeToDAE "function: addListTypeToDAE"
  input list<DAE.Element> daeElem;  
  input Types.Type inType;
  output list<DAE.Element> outElem; 
algorithm 
  outElem :=   
  matchcontinue (daeElem,inType)
    case (DAE.VAR(vn,kind,dir,prot,_,e,inst_dims,fl,lPath,dae_var_attr,comment,io,_) :: restList,t) 
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
      equation
        daeE = (DAE.VAR(vn,kind,dir,prot,DAE.LIST(),e,inst_dims,fl,lPath,dae_var_attr,comment,io,t) :: restList);
      then daeE; 
  end matchcontinue;
end addListTypeToDAE;


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
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
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


public function typeConvert "function: typeConvert"
  input Types.TType t;
  output Absyn.TypeSpec outType;
algorithm
  outType := 
  matchcontinue (t)
    case (Types.T_INTEGER(_)) then Absyn.TPATH(Absyn.IDENT("Integer"),NONE());
    case (Types.T_BOOL(_)) then Absyn.TPATH(Absyn.IDENT("Boolean"),NONE());
    case (Types.T_STRING(_)) then Absyn.TPATH(Absyn.IDENT("String"),NONE());
    case (Types.T_REAL(_)) then Absyn.TPATH(Absyn.IDENT("Real"),NONE()); 
    case (Types.T_COMPLEX(ClassInf.RECORD(s), _, _)) local String s; 
      equation
      then Absyn.TPATH(Absyn.IDENT(s),NONE()); 
    case (Types.T_LIST((t,_)))  
      local 
        Absyn.TypeSpec tSpec; 
        Types.TType t;  
        list<Absyn.TypeSpec> tSpecList; 
      equation
        tSpec = typeConvert(t);
        tSpecList = {tSpec};
      then Absyn.TCOMPLEX(Absyn.IDENT("list"),tSpecList,NONE());      
    // ...
  end matchcontinue;  
end typeConvert; */

end MetaUtil;