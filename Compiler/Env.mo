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

package Env
"
  file:	       Env.mo
  package:     Env
  description: Environmane management
 
  RCS: $Id$
 
  An environment is a stack of frames, where each frame contains a
  number of class and variable bindings.
  Each frame consist of:
  - a frame name (corresponding to the class partially instantiated in that frame)
  - a binary tree containing a list of classes
  - a binary tree containing a list of functions (functions are overloaded so serveral
						     function names can exist)
  - a list of unnamed items consisting of import statements
 
  As an example lets consider the following Modelica code:
  package A
    package B
     import Modelica.SIunits.;
     constant Voltage V=3.3;
     function foo
     end foo;
     model M1
       Real x,y;  
     end M1;
     model M2
     end M2;
   end B;
  end A;
  
  When instantiating M1 we will first create the environment for its surrounding scope
  by a recursive instantiation on A.B giving the environment:
   { 
   FRAME(\"A\", {Class:B},{},{},false) ,  
   FRAME(\"B\", {Class:M1, Class:M2, Variable:V}, {Type:foo},
	   {import Modelica.SIunits.},false)
   }
 
  Then, the class M1 is instantiated in a new scope/Frame giving the environment:
   { 
   FRAME(\"A\", {Class:B},{},{},false) ,  
   FRAME(\"B\", {Class:M1, Class:M2, Variable:V}, {Type:foo}, 
	   {Import Modelica.SIunits.},false),
   FRAME(\"M1, {Variable:x, Variable:y},{},{},false)
   }

  NOTE: The instance hierachy (components and variables) and the class hierachy 
  (packages and classes) are combined into the same data structure, enabling a 
  uniform lookup mechanism "

public import Absyn;
public import SCode;
public import Types;
public import ClassInf;
public import Exp;

public 
type Ident = String " An identifier is just a string " ;

public uniontype Cache
  record CACHE 
    Option<EnvCache> envCache "The cache consists of environments from which classes can be found";
    Option<Env> initialEnv "and the initial environment";
  end CACHE;
end Cache;

public uniontype EnvCache 
 record ENVCACHE
   "Cache for environments. The cache consists of a tree
    of environments from which lookupcan be performed."
   		CacheTree envTree;
  end ENVCACHE;
end EnvCache;

public uniontype CacheTree
  record CACHETREE
		Ident	name;
		Env env;
		list<CacheTree> children;
  end CACHETREE;
end CacheTree;

type CSetsType = tuple<list<Exp.ComponentRef>,Exp.ComponentRef>;
public 
uniontype Frame
  record FRAME 
    Option<Ident> optName        "Optional class name" ;
    AvlTree       clsAndVars     "List of uniquely named classes and variables" ;
    AvlTree       types          "List of types, which DOES NOT be uniquely named, eg. size have several types" ;
    list<Item>    imports        "list of unnamed items (imports)" ;
    list<Frame>   inherited      "list of frames for inherited elements" ;
    CSetsType     connectionSet  "current connection set crefs" ;
    Boolean       isEncapsulated "encapsulated bool=true means that FRAME is created due to encapsulated class" ;
  end FRAME;

end Frame;

public uniontype InstStatus
"Used to distinguish between different phases of the instantiation of a component
A component is first added to environment untyped. It can thereafter be instantiated to get its type 
and finally instantiated to produce the DAE. These three states are indicated by this datatype."

  record VAR_UNTYPED "Untyped variables, initially added to env"
  end VAR_UNTYPED;
  
  record VAR_TYPED "Typed variables, when instantiation to get type has been performed"
  end VAR_TYPED;
  
  record VAR_DAE "Typed variables that also have been instantiated to generate dae. Required to distinguish
                  between typed variables without DAE to know when to skip multiply declared dae elements"
  end VAR_DAE;                  
end InstStatus;

public 
uniontype Item
  record VAR
    Types.Var instantiated "instantiated component" ;
    Option<tuple<SCode.Element, Types.Mod>> declaration "declaration if not fully instantiated." ;
    InstStatus instStatus "if it untyped, typed or fully instantiated (dae)" ;
    Env env "The environment of the instantiated component
			       Contains e.g. all sub components 
			" ;
  end VAR;

  record CLASS
    SCode.Class class_;
    Env env;
  end CLASS;

  record TYPE
    list<Types.Type> list_ "list since several types with the same name can exist in the same scope (overloading)" ;
  end TYPE;

  record IMPORT
    Absyn.Import import_;
  end IMPORT;

end Item;

public 
type Env = list<Frame>;

protected import Dump;

protected import Print;
protected import Util;
protected import System;
protected import Inst;

public constant Env emptyEnv={} "- Values" ;

public constant Cache emptyCache = CACHE(NONE,NONE);

public function newFrame "- Relations
  function: newFrame
 
  This function creates a new frame, which includes setting up the 
  hashtable for the frame.
"
  input Boolean enc;
  output Frame outFrame;
  AvlTree httypes;
  AvlTree ht;
algorithm 
  ht := avlTreeNew();
  httypes := avlTreeNew();
  outFrame := FRAME(NONE,ht,httypes,{},{},({},Exp.CREF_IDENT("",Exp.OTHER(),{})),enc);
end newFrame;

public function isTyped "
Author BZ 2008-06
This function checks wheter an InstStatus is typed or not. 
Currently used by Inst->update_components_in_env. 
"
input InstStatus is;
output Boolean b;
algorithm b := matchcontinue(is)
  case(VAR_UNTYPED()) then false;
  case(_) then true;
  end matchcontinue; 
end isTyped;

public function openScope "function: openScope
 
  Opening a new scope in the environment means adding a new frame on
  top of the stack of frames. If the scope is not the top scope a classname
  of the scope should be provided such that a name for the scope can be
  derived, see name_scope."
  input Env inEnv;
  input Boolean inBoolean;
  input Option<Ident> inIdentOption;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv,inBoolean,inIdentOption)
    local
      Frame frame;
      Env env_1,env;
      Boolean encflag;
      Ident id;
    case (env,encflag,SOME(id)) /* encapsulated classname */ 
      equation 
        frame = newFrame(encflag);
        env_1 = nameScope((frame :: env), id);
      then
        env_1;
    case (env,encflag,NONE)
      equation 
        frame = newFrame(encflag);
      then
        (frame :: env);
  end matchcontinue;
end openScope;

protected function nameScope
"function: nameScope
  This function names the current scope, giving it an identifier.
  Scopes needs to be named for several reasons. First, it is needed for
  debugging purposes, since it is easier to follow the environment if we 
  know what the current class being instantiated is.
  
  Secondly, it is needed when expanding type names in the context of 
  flattening of the inheritance hiergearchy. The reason for this is that types
  of inherited components needs to be expanded such that the types can be 
  looked up from the environment of the base class.
  See also openScope, getScopeName."
  input Env inEnv;
  input Ident inIdent;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv,inIdent)
    local
      AvlTree httypes;
      AvlTree ht;
      list<AvlValue> imps;
      Env bcframes,res;
      tuple<list<Exp.ComponentRef>,Exp.ComponentRef> crs;
      Boolean encflag;
      Ident id;
    case ((FRAME(clsAndVars = ht,types = httypes,imports = imps,inherited = bcframes,connectionSet = crs,isEncapsulated = encflag) :: res),id) 
    then (FRAME(SOME(id),ht,httypes,imps,bcframes,crs,encflag) :: res); 
  end matchcontinue;
end nameScope;

public function stripForLoopScope "strips for loop scopes"
  input Env env;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(env)
  local String name;
    case(FRAME(optName = SOME(name))::env) equation
      equality(name=Inst.forScopeName);
      env = stripForLoopScope(env);
    then env; 
    case(env) then env; 
  end matchcontinue;
end stripForLoopScope;

public function getScopeName "function: getScopeName
 Returns the name of a scope, if no name exist, the function fails.
"
  input Env inEnv;
  output Ident name;
algorithm 
  name:=
  matchcontinue (inEnv)
    case ((FRAME(optName = SOME(name))::_)) then (name); 
  end matchcontinue;
end getScopeName;

public function getScopeNames "function: getScopeName
 Returns the name of a scope, if no name exist, the function fails.
"
  input Env inEnv;
  output list<Ident> names;
algorithm names := matchcontinue (inEnv)
  local String name;
  case ({}) then {};
  case ((FRAME(optName = SOME(name))::inEnv)) 
    equation
      names = getScopeNames(inEnv);
    then 
      name::names; 
  case ((FRAME(optName = NONE)::inEnv)) 
    equation
      names = getScopeNames(inEnv);
    then 
      "-NONAME-"::names; 
end matchcontinue;
end getScopeNames;

public function updateEnvClasses "Updates the classes of the top frame on the env passed as argument to the environment 
passed as second argument"
input Env env;
input Env classEnv;
output Env outEnv;
algorithm
  outEnv := matchcontinue(env,classEnv)
  local   Option<Ident> optName;
    AvlTree clsAndVars, types ;   
    list<Item> imports;
    list<Frame> inherited,fs;
    tuple<list<Exp.ComponentRef>,Exp.ComponentRef> crefs;
    Boolean enc; 
    
    case(FRAME(optName,clsAndVars,types,imports,inherited,crefs,enc)::fs,classEnv) equation
      clsAndVars = updateEnvClassesInTree(clsAndVars,classEnv);
    then FRAME(optName,clsAndVars,types,imports,inherited,crefs,enc)::fs;
  end matchcontinue;
end updateEnvClasses;

protected function updateEnvClassesInTree "Help function to updateEnvClasses"
  input AvlTree tree;
  input Env classEnv;
  output AvlTree outTree;
algorithm
  outTree := matchcontinue(tree,classEnv)  
  local SCode.Class cl;
    Option<AvlTree> l,r;
    AvlKey k;
    Env env;
    Item item;
    Integer h;
    /* Classes */  
   case(AVLTREENODE(SOME(AVLTREEVALUE(k,CLASS(cl,env))),h,l,r),classEnv) equation
      l = updateEnvClassesInTreeOpt(l,classEnv);
      r = updateEnvClassesInTreeOpt(r,classEnv);     
   then AVLTREENODE(SOME(AVLTREEVALUE(k,CLASS(cl,classEnv))),h,l,r);

     /* Other items */
   case(AVLTREENODE(SOME(AVLTREEVALUE(k,item)),h,l,r),classEnv) equation
      l = updateEnvClassesInTreeOpt(l,classEnv);
      r = updateEnvClassesInTreeOpt(r,classEnv);     
   then AVLTREENODE(SOME(AVLTREEVALUE(k,item)),h,l,r);
     
   case(AVLTREENODE(NONE,h,l,r),classEnv) equation
      l = updateEnvClassesInTreeOpt(l,classEnv);
      r = updateEnvClassesInTreeOpt(r,classEnv);     
   then AVLTREENODE(NONE,h,l,r);     
  end matchcontinue;
end updateEnvClassesInTree;

protected function updateEnvClassesInTreeOpt "Help function to updateEnvClassesInTree"
  input Option<AvlTree> tree;
  input Env classEnv;
  output Option<AvlTree> outTree;
algorithm
  outTree := matchcontinue(tree,classEnv)
  local AvlTree t;
    case(NONE,classEnv) then NONE;
    case(SOME(t),classEnv) equation
      t = updateEnvClassesInTree(t,classEnv); 
    then SOME(t);
  end matchcontinue;
end updateEnvClassesInTreeOpt;  

public function extendFrameC "function: extendFrameC
 
  This function adds a class definition to the environment.
"
  input Env inEnv;
  input SCode.Class inClass;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv,inClass)
    local
      AvlTree httypes;
      AvlTree ht,ht_1;
      Env env,bcframes,fs;
      Option<Ident> id;
      list<AvlValue> imps;
      tuple<list<Exp.ComponentRef>,Exp.ComponentRef> crs;
      Boolean encflag;
      SCode.Class c;
      Ident n;
    case ((env as (FRAME(optName = id,clsAndVars = ht,types = httypes,imports = imps,inherited = bcframes,connectionSet = crs,isEncapsulated = encflag) :: fs)),(c as SCode.CLASS(name = n)))
      equation 
        (ht_1) = avlTreeAdd(ht, n, CLASS(c,env));
      then
        (FRAME(id,ht_1,httypes,imps,bcframes,crs,encflag) :: fs);
    case (_,_)
      equation 
        print("extend_frame_c FAILED\n");
      then
        fail();
  end matchcontinue;
end extendFrameC;

public function extendFrameClasses "function: extendFrameClasses
 
  Adds all clases in a Program to the environment.
"
  input Env inEnv;
  input SCode.Program inProgram;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv,inProgram)
    local
      Env env,env_1,env_2;
      SCode.Class c;
      list<SCode.Class> cs;
    case (env,{}) then env; 
    case (env,(c :: cs))
      equation 
        env_1 = extendFrameC(env, c);
        env_2 = extendFrameClasses(env_1, cs);
      then
        env_2;
  end matchcontinue;
end extendFrameClasses;

public function extendFrameV "function: extendFrameV
 
  This function adds a component to the environment.
"
  input Env inEnv1;
  input Types.Var inVar2;
  input Option<tuple<SCode.Element, Types.Mod>> inTplSCodeElementTypesModOption3;
  input InstStatus instStatus;
  input Env inEnv5;
  output Env outEnv;

algorithm 
  outEnv:=
  matchcontinue (inEnv1,inVar2,inTplSCodeElementTypesModOption3,instStatus,inEnv5)
    local
      AvlTree httypes;
      AvlTree ht,ht_1;
      Option<Ident> id;
      list<AvlValue> imps;
      Env bcframes,fs,env,remember;
      tuple<list<Exp.ComponentRef>,Exp.ComponentRef> crs;
      Boolean encflag;
      InstStatus i;
      Types.Var v;
      Ident n;
      Option<tuple<SCode.Element, Types.Mod>> c;
    case ((FRAME(optName = id,clsAndVars = ht,types = httypes,imports = imps,inherited = bcframes,connectionSet = crs,isEncapsulated = encflag) :: fs),(v as Types.VAR(name = n)),c,i,env) /* environment of component */ 
      equation 
        //failure((_)= avlTreeGet(ht, n)); 
        (ht_1) = avlTreeAdd(ht, n, VAR(v,c,i,env));
      then
        (FRAME(id,ht_1,httypes,imps,bcframes,crs,encflag) :: fs);

        // Variable already added, perhaps from baseclass
    case (remember as (FRAME(optName = id,clsAndVars = ht,types = httypes,imports = imps,inherited = bcframes,connectionSet = crs,isEncapsulated = encflag) :: fs),
          (v as Types.VAR(name = n)),c,i,env) /* environment of component */ 
      equation 
        (_)= avlTreeGet(ht, n); 
      then
        (remember);
  end matchcontinue;
end extendFrameV;

public function updateFrameV "function: updateFrameV
 
  This function updates a component already added to the environment, but 
  that prior to the update did not have any binding. I.e this function is
  called in the second stage of instantiation with declare before use.
"
  input Env inEnv1;
  input Types.Var inVar2;
  input InstStatus instStatus;
  input Env inEnv4;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv1,inVar2,instStatus,inEnv4)
    local
      Boolean encflag;
      InstStatus i;
      Option<tuple<SCode.Element, Types.Mod>> c;
      AvlTree httypes;
      AvlTree ht,ht_1;
      Option<Ident> sid;
      list<AvlValue> imps;
      Env bcframes,fs,env,frames;
      tuple<list<Exp.ComponentRef>,Exp.ComponentRef> crs;
      Types.Var v;
      Ident n,id;
    case ({},_,i,_) then {};  /* fully instantiated env of component */ 
    case ((FRAME(optName = sid,clsAndVars = ht,types = httypes,imports = imps,inherited = bcframes,connectionSet = crs,isEncapsulated = encflag) :: fs),(v as Types.VAR(name = n)),i,env)
      equation 
        VAR(_,c,_,_) = avlTreeGet(ht, n);
        (ht_1) = avlTreeAdd(ht, n, VAR(v,c,i,env));
      then
        (FRAME(sid,ht_1,httypes,imps,bcframes,crs,encflag) :: fs);
    case ((FRAME(optName = sid,clsAndVars = ht,types = httypes,imports = imps,inherited = bcframes,connectionSet = crs,isEncapsulated = encflag) :: fs),(v as Types.VAR(name = n)),i,env) /* Also check frames above, e.g. when variable is in base class */ 
      equation 
        frames = updateFrameV(fs, v, i, env);
      then
        (FRAME(sid,ht,httypes,imps,bcframes,crs,encflag) :: frames);
    case ((FRAME(optName = sid,clsAndVars = ht,types = httypes,imports = imps,inherited = bcframes,connectionSet = crs,isEncapsulated = encflag) :: fs),Types.VAR(name = n),_,_)
      equation 
        /*Print.printBuf("- update_frame_v, variable ");
        Print.printBuf(n);
        Print.printBuf(" not found\n rest of env:");
        printEnv(fs);
        Print.printBuf("\n");*/
      then
        (FRAME(sid,ht,httypes,imps,bcframes,crs,encflag) :: fs);
    case (_,(v as Types.VAR(name = id)),_,_)
      equation 
        print("- update_frame_v failed\n");
        print("  - variable: ");
        print(Types.printVarStr(v));
        print("\n");
      then
        fail();
  end matchcontinue;
end updateFrameV;

public function extendFrameT "function: extendFrameT
 
  This function adds a type to the environment.  Types in the
  environment are used for looking up constants etc. inside class
  definitions, such as packages.  For each type in the environment,
  there is a class definition with the same name in the
  environment.
"
  input Env inEnv;
  input Ident inIdent;
  input Types.Type inType;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv,inIdent,inType)
    local
      list<tuple<Types.TType, Option<Absyn.Path>>> tps;
      AvlTree httypes_1,httypes;
      AvlTree ht;
      Option<Ident> sid;
      list<AvlValue> imps;
      Env bcframes,fs;
      tuple<list<Exp.ComponentRef>,Exp.ComponentRef> crs;
      Boolean encflag;
      Ident n;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case ((FRAME(optName = sid,clsAndVars = ht,types = httypes,imports = imps,inherited = bcframes,connectionSet = crs,isEncapsulated = encflag) :: fs),n,t)
      equation 
        TYPE(tps) = avlTreeGet(httypes, n) "Other types with that name allready exist, add this type as well" ;
        (httypes_1) = avlTreeAdd(httypes, n, TYPE((t :: tps)));
      then
        (FRAME(sid,ht,httypes_1,imps,bcframes,crs,encflag) :: fs);
    case ((FRAME(optName = sid,clsAndVars = ht,types = httypes,imports = imps,inherited = bcframes,connectionSet = crs,isEncapsulated = encflag) :: fs),n,t)
      equation 
        failure(TYPE(_) = avlTreeGet(httypes, n)) "No other types exists" ;
        (httypes_1) = avlTreeAdd(httypes, n, TYPE({t}));
      then
        (FRAME(sid,ht,httypes_1,imps,bcframes,crs,encflag) :: fs);
  end matchcontinue;
end extendFrameT;

public function extendFrameI "function: extends_frame_i
 
  Adds an import statement to the environment.
"
  input Env inEnv;
  input Absyn.Import inImport;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv,inImport)
    local
      Option<Ident> sid;
      AvlTree httypes;
      AvlTree ht;
      list<AvlValue> imps;
      Env bcframes,fs;
      tuple<list<Exp.ComponentRef>,Exp.ComponentRef> crs;
      Boolean encflag;
      Absyn.Import imp;
      Env env;
    case ((FRAME(optName = sid,clsAndVars = ht,types = httypes,imports = imps,inherited = bcframes,connectionSet = crs,isEncapsulated = encflag) :: fs),imp) 
      equation
        false = memberImportList(imps,imp);
    then (FRAME(sid,ht,httypes,(IMPORT(imp) :: imps),bcframes,crs,encflag) :: fs);
      case (env,imp) then env;
  end matchcontinue;
end extendFrameI;

protected function memberImportList "Returns true if import exist in imps"
	input list<Item> imps;
	input Absyn.Import imp;
  output Boolean res "true if import exist in imps, false otherwise";	
algorithm
  res := matchcontinue (imps,imp) 
  	local 
  	  list<Item> ims;
  		Absyn.Import imp2;
  		Boolean res;
    case (IMPORT(imp2)::ims,imp) 
      equation
     		equality(imp2 = imp); 
    then true;
   
    case (_::ims,imp) equation 
       res=memberImportList(ims,imp);
    then res;
    case (_,_) then false;
   end matchcontinue;
end memberImportList;

public function addBcFrame "function: addBcFrame
  author: PA
 
  Adds a baseclass frame to the environment from the baseclass environment
  to the list of base classes of the top frame of the passed environment.
"
  input Env inEnv1;
  input Env inEnv2;
  output Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inEnv1,inEnv2)
    local
      Option<Ident> sid;
      AvlTree tps;
      AvlTree cls;
      list<AvlValue> imps;
      Env bc,fs;
      tuple<list<Exp.ComponentRef>,Exp.ComponentRef> crefs;
      Boolean enc;
      Frame f;
    case ((FRAME(optName = sid,clsAndVars = cls,types = tps,imports = imps,inherited = bc,connectionSet = crefs,isEncapsulated = enc) :: fs),(f :: _)) 
      then (FRAME(sid,cls,tps,imps,(f :: bc),crefs,enc) :: fs);  /* env bc env */ 
  end matchcontinue;
end addBcFrame;

public function topFrame "function: topFrame
 
  Returns the top frame.
"
  input Env inEnv;
  output Frame outFrame;
algorithm 
  outFrame:=
  matchcontinue (inEnv)
    local
      Frame fr,elt;
      Env lst;
    case ({fr}) then fr; 
    case ((elt :: (lst as (_ :: _))))
      equation 
        fr = topFrame(lst);
      then
        fr;
  end matchcontinue;
end topFrame;

public function getClassName
  input Env inEnv;
  output Ident name;
algorithm
   name := matchcontinue (inEnv) 
   	local Ident n;
   	case FRAME(optName = SOME(n))::_ then n;
  end matchcontinue;
end getClassName;    	

public function getEnvPath "function: getEnvPath
 
  This function returns all partially instantiated parents as an Absyn.Path 
  option I.e. it collects all identifiers of each frame until it reaches 
  the topmost unnamed frame. If the environment is only the topmost frame, 
  NONE is returned.
"
  input Env inEnv;
  output Option<Absyn.Path> outAbsynPathOption;
algorithm 
  outAbsynPathOption:=
  matchcontinue (inEnv)
    local
      Ident id;
      Absyn.Path path,path_1;
      Env rest;
    case ({FRAME(optName = SOME(id)),FRAME(optName = NONE)}) then SOME(Absyn.IDENT(id)); 
    case ((FRAME(optName = SOME(id)) :: rest))
      equation 
        SOME(path) = getEnvPath(rest);
        path_1 = Absyn.joinPaths(path, Absyn.IDENT(id));
      then
        SOME(path_1);
    case (_) then NONE; 
  end matchcontinue;
end getEnvPath;

public function printEnvPathStr "function: printEnvPathStr
 
  Retrive the environment path as a string, see get_env_path.
"
  input Env inEnv;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inEnv)
    local
      Absyn.Path path;
      Ident pathstr;
      Env env;
    case (env)
      equation 
        SOME(path) = getEnvPath(env);
        pathstr = Absyn.pathString(path);
      then
        pathstr;
    case (env) then "<global scope>"; 
  end matchcontinue;
end printEnvPathStr;

public function printEnvPath "function: printEnvPath
 
  Print the environment path to the Print buffer. 
  See also get_env_path
"
  input Env inEnv;
algorithm 
  _:=
  matchcontinue (inEnv)
    local
      Absyn.Path path;
      Ident pathstr;
      Env env;
    case (env)
      equation 
        SOME(path) = getEnvPath(env);
        pathstr = Absyn.pathString(path);
        Print.printBuf(pathstr);
      then
        ();
    case (env)
      equation 
        Print.printBuf("TOPENV");
      then
        ();
  end matchcontinue;
end printEnvPath;

public function printEnvStr "function: printEnvStr
 
  Print the environment as a string.
"
  input Env inEnv;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inEnv)
    local
      Ident s1,s2,res;
      Frame fr;
      Env frs;
    case {} then "Empty env\n"; 
    case (fr :: frs)
      equation 
        s1 = printFrameStr(fr);
        s2 = printEnvStr(frs);
        res = stringAppend(s1, s2);
      then
        res;
  end matchcontinue;
end printEnvStr;

public function printEnv "function: printEnv
 
  Print the environment to the Print buffer.
"
  input Env e;
  Ident s;
algorithm 
  s := printEnvStr(e);
  Print.printBuf(s);
end printEnv;

public function printEnvConnectionCrefs "prints the connection crefs of the top frame"
input Env env;
algorithm
  _ := matchcontinue(env ) 
  local list<Exp.ComponentRef> crs;
   Env env;
    case(env as (FRAME(connectionSet = (crs,_))::_)) equation
      print(printEnvPathStr(env));print(" :   ");
      print(Util.stringDelimitList(Util.listMap(crs,Exp.printComponentRefStr),", "));
      print("\n");            
    then ();
  end matchcontinue;
end printEnvConnectionCrefs;

protected function printFrameStr "function: printFrameStr
 
  Print a Frame to a string.
"
  input Frame inFrame;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inFrame)
    local
      Ident s1,s2,s3,encflag_str,s4,res,sid;
      AvlTree httypes;
      AvlTree ht;
      list<AvlValue> imps;
      Env bcframes;
      tuple<list<Exp.ComponentRef>,Exp.ComponentRef> crs;
      Boolean encflag;
    case FRAME(optName = SOME(sid),clsAndVars = ht,types = httypes,imports = imps,inherited = bcframes,connectionSet = crs,isEncapsulated = encflag)
      equation 
        s1 = printAvlTreeStr(ht);
        s2 = printAvlTreeStr(httypes);
        s3 = printImportsStr(imps);
        encflag_str = Util.boolString(encflag);
        s4 = printEnvStr(bcframes);
        res = Util.stringAppendList(
          {"FRAME: ",sid," (enc=",encflag_str,
          ") \nclasses and vars:\n=============\n",s1,"   Types:\n======\n",s2,"   Imports:\n=======\n",s3,"baseclass:\n======\n",s4,"end baseclass\n"});
      then
        res;
    case FRAME(optName = NONE,clsAndVars = ht,types = httypes,imports = imps,inherited = bcframes,connectionSet = crs,isEncapsulated = encflag)
      equation 
        s1 = printAvlTreeStr(ht);
        s2 = printAvlTreeStr(httypes);
        s3 = printImportsStr(imps);
        s4 = printEnvStr(bcframes);
        encflag_str = Util.boolString(encflag);
        res = Util.stringAppendList(
          {"FRAME: unnamed (enc=",encflag_str,
          ") \nclasses and vars:\n=============\n",s1,"   Types:\n======\n",s2,"   Imports:\n=======\n",s3,"baseclass:\n======\n",s4,"end baseclass\n"});
      then
        res;
  end matchcontinue;
end printFrameStr;

protected function printFrameVarsStr "function: printFrameVarsStr
 
  Print only the variables in a Frame to a string.
"
  input Frame inFrame;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inFrame)
    local
      Ident s1,encflag_str,res,sid;
      AvlTree httypes;
      AvlTree ht;
      list<AvlValue> imps;
      Env bcframes;
      tuple<list<Exp.ComponentRef>,Exp.ComponentRef> crs;
      Boolean encflag;
    case FRAME(optName = SOME(sid),clsAndVars = ht,types = httypes,imports = imps,inherited = bcframes,connectionSet = crs,isEncapsulated = encflag)
      equation 
        s1 = printAvlTreeStr(ht);
        encflag_str = Util.boolString(encflag);
        res = Util.stringAppendList(
          {"FRAME: ",sid," (enc=",encflag_str,
          ") \nclasses and vars:\n=============\n",s1,"\n\n\n"});
      then
        res;
    case FRAME(optName = NONE,clsAndVars = ht,types = httypes,imports = imps,inherited = bcframes,connectionSet = crs,isEncapsulated = encflag)
      equation 
        s1 = printAvlTreeStr(ht);
        encflag_str = Util.boolString(encflag);
        res = Util.stringAppendList(
          {"FRAME: unnamed (enc=",encflag_str,
          ") \nclasses and vars:\n=============\n",s1,"\n\n\n"});
      then
        res;
    case _ then ""; 
  end matchcontinue;
end printFrameVarsStr;

protected function printImportsStr "function: printImportsStr
 
  Print import statements to a string.
"
  input list<Item> inItemLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inItemLst)
    local
      Ident s1,s2,res;
      AvlValue e;
      list<AvlValue> rst;
    case {} then ""; 
    case {e}
      equation 
        s1 = printFrameElementStr(("",e));
      then
        s1;
    case ((e :: rst))
      equation 
        s1 = printFrameElementStr(("",e));
        s2 = printImportsStr(rst);
        res = Util.stringAppendList({s1,", ",s2});
      then
        res;
  end matchcontinue;
end printImportsStr;

protected function printFrameElementStr "function: printFrameElementStr
 
  Print frame element to a string
"
  input tuple<Ident, Item> inTplIdentItem;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inTplIdentItem)
    local
      Ident s,elt_str,tp_str,var_str,frame_str,bind_str,res,n,lenstr;
      Types.Var tv;
      SCode.Variability var;
      tuple<Types.TType, Option<Absyn.Path>> tp;
      Types.Binding bind,bnd;
      SCode.Element elt;
      InstStatus i;
      Frame compframe;
      Env env;
      Integer len;
      list<tuple<Types.TType, Option<Absyn.Path>>> lst;
      Absyn.Import imp;
    case ((n,VAR(instantiated = (tv as Types.VAR(attributes = Types.ATTR(parameter_ = var),type_ = tp,binding = bind)),declaration = SOME((elt,_)),instStatus = i,env = (compframe :: _))))
      equation 
        s = SCode.variabilityString(var);
        elt_str = SCode.printElementStr(elt);
        tp_str = Types.unparseType(tp);
        var_str = Types.unparseVar(tv);
        frame_str = printFrameVarsStr(compframe);
        bind_str = Types.printBindingStr(bind);
        res = Util.stringAppendList(
          {"v:",n," ",s,"(",elt_str,") [",tp_str,"] {",var_str,
          "}, binding:",bind_str});
      then
        res;
    case ((n,VAR(instantiated = (tv as Types.VAR(attributes = Types.ATTR(parameter_ = var),type_ = tp)),declaration = SOME((elt,_)),instStatus = i,env = {})))
      equation 
        s = SCode.variabilityString(var);
        elt_str = SCode.printElementStr(elt);
        tp_str = Types.unparseType(tp);
        var_str = Types.unparseVar(tv);
        res = Util.stringAppendList(
          {"v:",n," ",s,"(",elt_str,") [",tp_str,"] {",var_str,
          "}, compframe: []"});
      then
        res;
    case ((n,VAR(instantiated = Types.VAR(binding = bnd),declaration = NONE,instStatus = i,env = env)))
      equation 
        res = Util.stringAppendList({"v:",n,"\n"});
      then
        res;
    case ((n,CLASS(class_ = _)))
      equation 
        res = Util.stringAppendList({"c:",n,"\n"});
      then
        res;
    case ((n,TYPE(list_ = lst)))
      equation 
        len = listLength(lst);
        lenstr = intString(len);
        res = Util.stringAppendList({"t:",n," (",lenstr,")\n"});
      then
        res;
    case ((n,IMPORT(import_ = imp)))
      equation 
        s = Dump.unparseImportStr(imp);
        res = Util.stringAppendList({"imp:",s,"\n"});
      then
        res;
  end matchcontinue;
end printFrameElementStr;

protected function isVarItem "function: isVarItem
 
  Succeeds if item is a VAR.
"
  input tuple<Type_a, Item> inTplTypeAItem;
  replaceable type Type_a subtypeof Any;
algorithm 
  _:=
  matchcontinue (inTplTypeAItem)
    case ((_,VAR(instantiated = _))) then (); 
  end matchcontinue;
end isVarItem;

protected function isClassItem "function: isClassItem
 
  Succeeds if item is a CLASS.
"
  input tuple<Type_a, Item> inTplTypeAItem;
  replaceable type Type_a subtypeof Any;
algorithm 
  _:=
  matchcontinue (inTplTypeAItem)
    case ((_,CLASS(class_ = _))) then (); 
  end matchcontinue;
end isClassItem;

protected function isTypeItem "function: isTypeItem
 
  Succeds if item is a TYPE.
"
  input tuple<Type_a, Item> inTplTypeAItem;
  replaceable type Type_a subtypeof Any;
algorithm 
  _:=
  matchcontinue (inTplTypeAItem)
    case ((_,TYPE(list_ = _))) then (); 
  end matchcontinue;
end isTypeItem;

public function getCachedInitialEnv "get the initial environment from the cache"
  input Cache cache;
  output Env env;
algorithm	
  env := matchcontinue(cache) 
    //case (_) then fail();
    case (CACHE(_,SOME(env))) equation
    //	print("getCachedInitialEnv\n");
      then env;
  end matchcontinue;
end getCachedInitialEnv;  

public function setCachedInitialEnv "set the initial environment in the cache"
  input Cache inCache;
  input Env env;
  output Cache outCache;
algorithm	
  outCache := matchcontinue(inCache,env) 
  local
    	Option<EnvCache> envCache;

    case (CACHE(envCache,_),env) equation 
 //    	print("setCachedInitialEnv\n");
      then CACHE(envCache,SOME(env));
  end matchcontinue;
end setCachedInitialEnv;  
    
public function cacheGet "Get an environment from the cache."
  input Absyn.Path scope;
  input Absyn.Path path;
  input Cache cache;
  output Env env;
algorithm
  env:= matchcontinue(scope,path,cache)
  local CacheTree tree;
   case (scope,path,CACHE(SOME(ENVCACHE(tree)),_))
      equation
        env = cacheGetEnv(scope,path,tree);
        //print("got cached env for ");print(Absyn.pathString(path)); print("\n");
      then env;          
    case (_,_,_) then fail();
  end matchcontinue;
end cacheGet;

public function cacheAdd "Add an environment to the cache."
  input Absyn.Path fullpath "Fully qualified path to the environment";
  input Cache inCache ;
  input Env env "environment";
  output Cache outCache;
algorithm
  outCache := matchcontinue(fullpath,inCache,env)
  local CacheTree tree;
    Option<Env> ie;
      
    case (fullpath,CACHE(NONE,ie),env) 
      equation
        tree = cacheAddEnv(fullpath,CACHETREE("$global",emptyEnv,{}),env);
        //print("Adding ");print(Absyn.pathString(fullpath));print(" to empty cache\n");
      then CACHE(SOME(ENVCACHE(tree)),ie);
    case (fullpath,CACHE(SOME(ENVCACHE(tree)),ie),env) 
      equation
       // print(" about to Adding ");print(Absyn.pathString(fullpath));print(" to cache:\n");
      tree = cacheAddEnv(fullpath,tree,env);
      
       //print("Adding ");print(Absyn.pathString(fullpath));print(" to cache\n");
        //print(printCacheStr(CACHE(SOME(ENVCACHE(tree)),ie)));
      then CACHE(SOME(ENVCACHE(tree)),ie);
    case (_,_,_) equation print("cacheAdd failed\n"); then fail();
  end matchcontinue;
end cacheAdd;

protected function cacheGetEnv "get an environment from the tree cache."
	input Absyn.Path scope;
	input Absyn.Path path;
	input CacheTree tree;
	output Env env;
algorithm
  env := matchcontinue(scope,path,tree)
  local
    	Absyn.Path path2;
    	Ident id;
    	list<CacheTree> children;
    	
			// Search only current scope. Since scopes higher up might not be cached, we cannot search upwards.
    case (path2,path,tree)
      equation
        env = cacheGetEnv2(path2,path,tree);
        //print("found ");print(Absyn.pathString(path));print(" in cache at scope");
				//print(Absyn.pathString(path2));print("\n");
      then env;
  end matchcontinue;
end cacheGetEnv;
 
protected function cacheGetEnv2 "Help function to cacheGetEnv. Searches in one scope by 
  first looking up the scope and then search from there."
  input Absyn.Path scope;
  input Absyn.Path path;
  input CacheTree tree;
  output Env env;
  
algorithm
   env := matchcontinue(scope,path,tree)
	local 	
	  	Env env2;
	  	Ident id,id2;
	  	list<CacheTree> children,children2;
	  	Absyn.Path path2;

	  //	Simple name found in children, search for model from this scope.
     case (Absyn.IDENT(id),path,CACHETREE(_,_,CACHETREE(id2,env2,children2)::_))
       equation 
         equality(id = id2);
         //print("found (1) ");print(id); print("\n");
         env=cacheGetEnv3(path,children2); 
       then env;
         
         //	Simple name. try next.
     case (Absyn.IDENT(id),path,CACHETREE(id2,env2,_::children))
       equation 
         //print("try next ");print(id);print("\n");
         env=cacheGetEnv2(Absyn.IDENT(id),path,CACHETREE(id2,env2,children));
       then env;
         
    // for qualified name, found first matching identifier in child
     case (Absyn.QUALIFIED(id,path2),path,CACHETREE(_,_,CACHETREE(id2,env2,children2)::_))
       equation
         equality(id=id2);
         //print("found qualified (1) ");print(id);print("\n");
         env = cacheGetEnv2(path2,path,CACHETREE(id2,env2,children2));
       then env;
           
    // for qualified name, try next
     case (Absyn.QUALIFIED(id,path2),path,CACHETREE(id2,env2,_::children2))
       equation
         //print("try next qualified ");print(id);print("\n");
         env = cacheGetEnv2(path2,path,CACHETREE(id2,env2,children2));
       then env;
   end matchcontinue;  
end cacheGetEnv2;

protected function cacheGetEnv3 "Help function to cacheGetEnv2, searches down in tree for env."
  input Absyn.Path path;
  input list<CacheTree> children;
  output Env env;
algorithm
  env := matchcontinue(path,children)

    local
      Ident id,id2;

		//found matching simple name
    case (Absyn.IDENT(id),CACHETREE(id2,env,_)::_)
      equation
        equality(id =id2); then env;
     
     // found matching qualified name
    case (Absyn.QUALIFIED(id,path),CACHETREE(id2,_,children)::_) 
      equation        
        equality(id =id2);
        	env = cacheGetEnv3(path,children);
         then env;

     // try next      
    case (path,_::children) 
      equation
        	env = cacheGetEnv3(path,children);
         then env;
  end matchcontinue;
end cacheGetEnv3;

public function cacheAddEnv "Add an environment to the cache"
  input Absyn.Path fullpath "Fully qualified path to the environment";
  input CacheTree tree ;
  input Env env "environment";
  output CacheTree outTree;
algorithm
  outTree := matchcontinue(path,tree,env)
    local 
      Ident id,globalID,id2;
      Absyn.Path path;
      Env globalEnv,oldEnv;
      list<CacheTree> children,children2;
      CacheTree child;
      // simple names already added
      case (Absyn.IDENT(id),(tree as CACHETREE(globalID,globalEnv,CACHETREE(id2,oldEnv,children)::children2)),env) 
        equation
          //print(id);print(" already added\n");
          equality(id=id2);
          then tree;
            
       // simple names try next
      case (Absyn.IDENT(id),tree as CACHETREE(globalID,globalEnv,child::children),env) 
        equation
          CACHETREE(globalID,globalEnv,children) = cacheAddEnv(Absyn.IDENT(id),CACHETREE(globalID,globalEnv,children),env);
          then CACHETREE(globalID,globalEnv,child::children);
                        
      // Simple names, not found
    case (Absyn.IDENT(id),CACHETREE(globalID,globalEnv,{}),env) 
    then CACHETREE(globalID,globalEnv,{CACHETREE(id,env,{})});
      
      // Qualified names.
    case (path as Absyn.QUALIFIED(_,_),CACHETREE(globalID,globalEnv,children),env)
      equation
        children=cacheAddEnv2(path,children,env);
      then CACHETREE(globalID,globalEnv,children);
    case (path,_,_) equation print("cacheAddEnv path=");print(Absyn.pathString(path));print(" failed\n");
      then fail();
  end matchcontinue;
end cacheAddEnv;

protected function cacheAddEnv2
  input Absyn.Path path;
  input list<CacheTree> inChildren;
  input Env env;
  output list<CacheTree> outChildren;
algorithm
  outChildren := matchcontinue(path,inChildren,env)
    local 
      Ident id,id2;
      Absyn.Path path;
      list<CacheTree> children,children2;
      CacheTree child;
      Env env2;
      
      // qualified name, found matching    
    case(Absyn.QUALIFIED(id,path),CACHETREE(id2,env2,children2)::children,env)
      equation
        equality(id=id2);
        children2 = cacheAddEnv2(path,children2,env);
      then	CACHETREE(id2,env2,children2)::children;

		// simple name, found matching
    case (Absyn.IDENT(id),CACHETREE(id2,env2,children2)::children,env) 
      equation
        equality(id=id2);
        //print("single name, found matching\n");
      then CACHETREE(id2,env2,children2)::children;
        
        // try next
    case(path,child::children,env)
      equation
        //print("try next\n");
        children = cacheAddEnv2(path,children,env);
      then	child::children;
        
    // qualified name no child found, create one.
    case (Absyn.QUALIFIED(id,path),{},env) 
      equation        
        children = cacheAddEnv2(path,{},env);
        //print("qualified name no child found, create one.\n");
      then {CACHETREE(id,emptyEnv,children)};   

    // simple name no child found, create one.
    case (Absyn.IDENT(id),{},env) 
      equation
        //print("simple name no child found, create one.\n");
      then {CACHETREE(id,env,{})};
        
    case (_,_,_) equation print("cacheAddEnv2 failed\n"); then fail();
  end matchcontinue;
end cacheAddEnv2;  

public function printCacheStr
  input Cache cache;
  output String str;
algorithm
  str := matchcontinue(cache)
  local CacheTree tree;
    case CACHE(SOME(ENVCACHE(tree)),_) 
      local String s;
      equation
      s = printCacheTreeStr(tree,1); 
      str = Util.stringAppendList({"Cache:\n",s,"\n"});
      then str;
    case CACHE(NONE,_) then "EMPTY CACHE\n";
  end matchcontinue;
end printCacheStr;

protected function printCacheTreeStr
	input CacheTree tree;
	input Integer indent;
  output String str;
algorithm
	str:= matchcontinue(tree,indent)
	local Ident id;
	  list<CacheTree> children;
	  case (CACHETREE(id,_,children),indent) 
	    local
	      String s,s1;
	    equation
	      s = Util.stringDelimitList(Util.listMap1(children,printCacheTreeStr,indent+1),"\n");
	    	s1 = Util.stringAppendList(Util.listFill(" ",indent));
	    	str = Util.stringAppendList({s1,id,"\n",s});
	    then str;
	end matchcontinue;
end printCacheTreeStr;

public function localOutsideConnectorFlowvars "function: localOutsideConnectorFlowvars
 
  Return the outside connector variables that are flow in the local scope.
"
  input Env inEnv;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inEnv)
    local
      list<Exp.ComponentRef> res;
      Option<Ident> sid;
      AvlTree ht;
    case ((FRAME(optName = sid,clsAndVars = ht) :: _))
      equation 
        res = localOutsideConnectorFlowvars2(SOME(ht));
      then
        res;
  end matchcontinue;
end localOutsideConnectorFlowvars;

protected function localOutsideConnectorFlowvars2 "function: localOutsideConnectorFlowvars2
 
  Helper function to local_outside_connector_flowvars
"
  input Option<AvlTree> inBinTreeOption;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inBinTreeOption)
    local
      list<Exp.ComponentRef> lst1,lst2,lst3,res;
      Ident id;
      list<Types.Var> vars;
      Option<AvlTree> l,r;
      Absyn.InnerOuter io;
    case (NONE) then {}; 
    case (SOME(AVLTREENODE(SOME(AVLTREEVALUE(_,VAR(Types.VAR(id,Types.ATTR(innerOuter=io),_,(Types.T_COMPLEX(ClassInf.CONNECTOR(_),vars,_,_),_),_),_,_,_))),_,l,r)))
      equation 
        lst1 = localOutsideConnectorFlowvars2(l);
        lst2 = localOutsideConnectorFlowvars2(r);
        (_,false) = Inst.innerOuterBooleans(io);       
        lst3 = Types.flowVariables(vars, Exp.CREF_IDENT(id,Exp.OTHER(),{}));
        res = Util.listFlatten({lst1,lst2,lst3});
      then
        res;
    case (SOME(AVLTREENODE(SOME(_),_,l,r)))
      equation 
        lst1 = localOutsideConnectorFlowvars2(l);
        lst2 = localOutsideConnectorFlowvars2(r);
        res = listAppend(lst1, lst2);
      then
        res;
    case(_) then {};
  end matchcontinue;
end localOutsideConnectorFlowvars2;

public function localInsideConnectorFlowvars "function: localInsideConnectorFlowvars
 
  Returns the inside connector variables that are flow from the local scope.
"
  input Env inEnv;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inEnv)
    local
      list<Exp.ComponentRef> res;
      Option<Ident> sid;
      AvlTree ht;
    case ((FRAME(optName = sid,clsAndVars = ht) :: _))
      equation 
        res = localInsideConnectorFlowvars2(SOME(ht));
      then
        res;
  end matchcontinue;
end localInsideConnectorFlowvars;

protected function localInsideConnectorFlowvars2 "function: localInsideConnectorFlowvars2
  
  Helper function to local_inside_connector_flowvars
"
  input Option<AvlTree> inBinTreeOption;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inBinTreeOption)
    local
      list<Exp.ComponentRef> lst1,lst2,res,lst3;
      Ident id;
      Option<AvlTree> l,r;
      list<Types.Var> vars;
      tuple<Types.TType, Option<Absyn.Path>> t;
      Absyn.InnerOuter io;
    case (NONE) then {}; 
    
    
         /* Case where we have an array, assumed indexed which contains complex types. */
    case (SOME(AVLTREENODE(SOME(AVLTREEVALUE(_,VAR(Types.VAR(id,(tatr as Types.ATTR(innerOuter=io)),b3,(tmpty as (Types.T_ARRAY(ad,at),_)),bind),_,_,_))),_,l,r)))
      local
        Types.ArrayDim ad;
        Types.Type at,tmpty,flatArrayType;
        Types.Attributes tatr;
        Boolean b3;
        Types.Binding bind;
        list<Integer> adims;
        list<Types.Var> tvars;
        list<list<Integer>> indexIntegerLists;
        list<list<Exp.Subscript>> indexSubscriptLists;
        //list<Exp.ComponentRef> arrayComplex;
      equation 
        (_,false) = Inst.innerOuterBooleans(io); 
        ((flatArrayType as (Types.T_COMPLEX(_,tvars,_,_),_)),adims) = Types.flattenArrayType(tmpty);
        false = Types.isComplexConnector(flatArrayType);
        
        indexSubscriptLists = createSubs(adims);
        
        lst1 = localInsideConnectorFlowvars3_2(tvars, id, indexSubscriptLists);
        lst2 = localInsideConnectorFlowvars2(l);
        lst3 = localInsideConnectorFlowvars2(r);
        res = Util.listFlatten({lst1,lst2,lst3});
        //print(" returning: " +& Util.stringDelimitList(Util.listMap(res,Exp.printComponentRefStr), ", ") +& "\n");
      then
        res;   
        
    /* If CONNECTOR then  outside and not inside, skip.. */
    case (SOME(AVLTREENODE(SOME(AVLTREEVALUE(_,VAR(Types.VAR(id,_,_,(Types.T_COMPLEX(ClassInf.CONNECTOR(_),_,_,_),_),_),_,_,_))),_,l,r)))  
      equation 
        lst1 = localInsideConnectorFlowvars2(l);
        lst2 = localInsideConnectorFlowvars2(r);
        res = listAppend(lst1, lst2);
      then
        res;
        
     /* If OUTER, skip.. */
    case (SOME(AVLTREENODE(SOME(AVLTREEVALUE(_,VAR(Types.VAR(id,Types.ATTR(innerOuter=io),_,(Types.T_COMPLEX(_,vars,_,_),_),_),_,_,_))),_,l,r)))  
      equation
        (_,true) = Inst.innerOuterBooleans(io); 
        lst1 = localInsideConnectorFlowvars2(l);
        lst2 = localInsideConnectorFlowvars2(r);
        res = listAppend(lst1, lst2);
      then
        res;   
    /* ... else retrieve connectors as subcomponents */
    case (SOME(AVLTREENODE(SOME(AVLTREEVALUE(_,VAR(Types.VAR(id,_,_,(Types.T_COMPLEX(_,vars,_,_),_),_),_,_,_))),_,l,r)))  
      equation 
        lst1 = localInsideConnectorFlowvars3(vars, id);
        lst2 = localInsideConnectorFlowvars2(l);
        lst3 = localInsideConnectorFlowvars2(r);
        res = Util.listFlatten({lst1,lst2,lst3});
      then
        res;
    case (SOME(AVLTREENODE(_,_,l,r))) 
      equation 
        lst1 = localInsideConnectorFlowvars2(l);
        lst2 = localInsideConnectorFlowvars2(r);
        res = listAppend(lst1, lst2);
      then
        res;
  end matchcontinue;
end localInsideConnectorFlowvars2;

protected function localInsideConnectorFlowvars3 "function: localInsideConnectorFlowvars3
 
  Helper function to local_inside_connector_flowvars2
"
  input list<Types.Var> inTypesVarLst;
  input Ident inIdent;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inTypesVarLst,inIdent)
    local
      list<Exp.ComponentRef> lst1,lst2,res;
      Ident id,oid,name;
      list<Types.Var> vars,xs;
      Absyn.InnerOuter io;
    case ({},_) then {}; 
    case ((Types.VAR(name = id,attributes=Types.ATTR(innerOuter=io),type_ = (Types.T_COMPLEX(complexClassType = ClassInf.CONNECTOR(string = name),complexVarLst = vars),_)) :: xs),oid)
      equation 
        lst1 = localInsideConnectorFlowvars3(xs, oid);
        (_,false) = Inst.innerOuterBooleans(io);
        //lst2 = Types.flowVariables(vars, Exp.CREF_QUAL(oid,Exp.OTHER(),{},Exp.CREF_IDENT(id,Exp.OTHER(),{})));
        lst2 = Types.flowVariables(vars, Exp.CREF_QUAL(oid,Exp.COMPLEX(name,{},ClassInf.CONNECTOR(name)),{},Exp.CREF_IDENT(id,Exp.COMPLEX(name,{},ClassInf.CONNECTOR(name)),{})));
        res = listAppend(lst1, lst2);
      then
        res;
    case ((_ :: xs),oid)
      equation 
        res = localInsideConnectorFlowvars3(xs, oid);
      then
        res;
  end matchcontinue;
end localInsideConnectorFlowvars3;

protected function localInsideConnectorFlowvars3_2 "
Author: BZ, 2009-05
Extract vars from complex types. 
Helper function for array complex vars. 
"
  input list<Types.Var> inTypesVarLst;
  input Ident inIdent;
  input list<list<Exp.Subscript>> ssubs;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inTypesVarLst,inIdent,ssubs)
    local
      list<Exp.ComponentRef> lst1,lst2,lst3,res;
      Ident id,oid,name;
      list<Types.Var> vars,xs;
      Absyn.InnerOuter io;
      list<Exp.Subscript> s;
      Types.Var tv;
    case ({},_,_) then {}; 
    case (_,_,{}) then {};
    case (((tv as Types.VAR(name = id,attributes=Types.ATTR(innerOuter=io),type_ = (Types.T_COMPLEX(complexClassType = ClassInf.CONNECTOR(string = name),complexVarLst = vars),_))) :: xs),oid,s::ssubs)
      equation 
        lst3 = localInsideConnectorFlowvars3_2({tv},oid,ssubs);
        lst1 = localInsideConnectorFlowvars3_2(xs, oid,s::ssubs);
        (_,false) = Inst.innerOuterBooleans(io);
        //lst2 = Types.flowVariables(vars, Exp.CREF_QUAL(oid,Exp.OTHER(),{},Exp.CREF_IDENT(id,Exp.OTHER(),{})));
        lst2 = Types.flowVariables(vars, Exp.CREF_QUAL(oid,Exp.COMPLEX(name,{},ClassInf.CONNECTOR(name)),s,Exp.CREF_IDENT(id,Exp.COMPLEX(name,{},ClassInf.CONNECTOR(name)),{})));
        res = Util.listFlatten({lst1, lst2,lst3});
      then
        res;
    case ((_ :: xs),oid,ssubs)
      equation 
        //print(" **** FAILURE localInsideConnectorFlowvars3\n **** "); 
        res = localInsideConnectorFlowvars3_2(xs, oid,ssubs);
      then
        res;
  end matchcontinue;
end localInsideConnectorFlowvars3_2;

protected function createSubs "
Author: BZ, 2009-05
Create subscripts from given integerlist of dimensions, ex
{2,3} => {1,1},{1,2},{1,3},{2,1},{2,2},{2,3}.
"
  input list<Integer> inInts;
  output list<list<Exp.Subscript>> osubs;
algorithm osubs := matchcontinue(inInts)
  local
    list<Integer> ints;
    Integer i;
    list<Exp.Subscript> localSubs;
  case({}) then {};
  case(i::inInts)
    equation
      osubs = createSubs(inInts);
      ints = Util.listIntRange(i);
      localSubs = Util.listMap(ints,integer2Subscript);
      osubs = createSubs2(localSubs,osubs);
       //_ = Util.listMap(osubs,dummyDump);
    then 
      osubs;
end matchcontinue;
end createSubs;

protected function dummyDump "
Author: BZ, 2009-05
Debug function, print subscripts. 
"
input list<Exp.Subscript> subs;
output String str; 
algorithm str := matchcontinue(subs)
  local
      Exp.Subscript s;
  case(subs)
    equation
      str = " subs: " +& Util.stringDelimitList(Util.listMap(subs,Exp.printSubscriptStr),", ") +& "\n";
      print(str);
      then
        str;
  end matchcontinue;
end dummyDump; 

protected function createSubs2
input list<Exp.Subscript> s;
input list<list<Exp.Subscript>> subs;
output list<list<Exp.Subscript>> osubs;
algorithm osubs := matchcontinue(s,subs)
  local
    list<Exp.Subscript> lsubs;
    list<list<Exp.Subscript>> lssubs;
    Exp.Subscript sub;
    case({},_) then {};
    case(sub::s,{}) // base case
    equation
      osubs = createSubs2(s,{});
      then
        {sub}::osubs;
  case(sub::s,subs)
    equation
      lssubs = createSubs3(sub,subs);
      osubs = createSubs2(s,subs);
      osubs = listAppend(lssubs,osubs);
      then
         osubs;
  end matchcontinue;
end createSubs2;

protected function createSubs3
input Exp.Subscript s;
input list<list<Exp.Subscript>> subs;
output list<list<Exp.Subscript>> osubs;
algorithm osubs := matchcontinue(s,subs)
  local
    list<Exp.Subscript> lsubs;
    case(_,{}) then {};
  case(s,lsubs::subs)
    equation
      osubs = createSubs3(s,subs);
      lsubs = listAppend({s},lsubs);
      then
         lsubs::osubs;
  end matchcontinue;
end createSubs3;

protected function integer2Subscript "
@author adrpo
 given an integer transform it into an Exp.Subscript"
  input  Integer       index;
  output Exp.Subscript subscript;
algorithm
 subscript := Exp.INDEX(Exp.ICONST(index));
end integer2Subscript;

/* AVL impementation */

public 
type AvlKey = String ;
public 
type AvlValue = Item;

public function keyStr "prints a key to a string"
input AvlKey k;
output String str;
algorithm
  str := k;
end keyStr;

public function valueStr "prints a Value to a string"
input AvlValue v;
output String str;
algorithm
  str := matchcontinue(v)
  local String name; Types.Type tp; Absyn.Import imp;
    case(VAR(instantiated=Types.VAR(name=name,type_=tp))) equation
      str = "v: " +& name +& " " +& Types.unparseType(tp);
    then str;
    case(CLASS(class_=SCode.CLASS(name=name))) equation
      str = "c: " +& name;
    then str;
    case(TYPE(tp::_)) equation
      str = "t: " +& Types.unparseType(tp);
    then str;
    case(IMPORT(imp)) equation
      str = "imp: " +& Dump.unparseImportStr(imp);
    then str;        
  end matchcontinue;
end valueStr;


/* Generic Code below */
public 
uniontype AvlTree "The binary tree data structure
 "
  record AVLTREENODE
    Option<AvlTreeValue> value "Value" ;
    Integer height "heigth of tree, used for balancing";
    Option<AvlTree> left "left subtree" ;
    Option<AvlTree> right "right subtree" ;
  end AVLTREENODE;

end AvlTree;

public 
uniontype AvlTreeValue "Each node in the binary tree can have a value associated with it."
  record AVLTREEVALUE
    AvlKey key "Key" ;
    AvlValue value "Value" ;
  end AVLTREEVALUE;

end AvlTreeValue;
  
public function avlTreeNew "Return an empty tree"
  output AvlTree tree;
algorithm
  tree := AVLTREENODE(NONE,0,NONE,NONE);
end avlTreeNew;
 
public function avlTreeAdd "
 Help function to avlTreeAdd.
 "
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
  partial function FuncTypeKeyToInteger
    input AvlKey inKey;
    output Integer outInteger;
  end FuncTypeKeyToInteger;
algorithm 
  outAvlTree:=
  matchcontinue (inAvlTree,inKey,inValue)
    local
      partial function FuncTypeStringToInteger
        input AvlKey inString;
        output Integer outInteger;
      end FuncTypeStringToInteger;
      AvlKey key,rkey;
      AvlValue value,rval;
      Option<AvlTree> left,right;
      FuncTypeStringToInteger hashfunc;
      Integer rhval,h;
      AvlTree t_1,t,right_1,left_1,bt;
      
      /* empty tree*/
    case (AVLTREENODE(value = NONE,height=h,left = NONE,right = NONE),key,value) 
    	then AVLTREENODE(SOME(AVLTREEVALUE(key,value)),1,NONE,NONE);  
		
		/* Replace this node */     	  
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey,rval)),height=h,left = left,right = right),key,value) 
      equation 
        equality(rkey = key);
        bt = balance(AVLTREENODE(SOME(AVLTREEVALUE(rkey,value)),h,left,right));
      then
        bt;

        /* Insert to right  */         
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey,rval)),height=h,left = left,right = (right)),key,value) 
      equation 
        true = System.strcmp(key,rkey) > 0;  
        t = createEmptyAvlIfNone(right);
        t_1 = avlTreeAdd(t, key, value);
        bt = balance(AVLTREENODE(SOME(AVLTREEVALUE(rkey,rval)),h,left,SOME(t_1)));       
      then
        bt;
        
        /* Insert to left subtree */ 
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey,rval)),height=h,left = left ,right = right),key,value) 
      equation 
        /*true = System.strcmp(key,rkey) < 0;*/
         t = createEmptyAvlIfNone(left);
        t_1 = avlTreeAdd(t, key, value);
        bt = balance(AVLTREENODE(SOME(AVLTREEVALUE(rkey,rval)),h,SOME(t_1),right));
      then
        bt;               
    case (_,_,_)
      equation 
        print("avlTreeAdd failed\n");
      then
        fail();
  end matchcontinue;
end avlTreeAdd;

protected function createEmptyAvlIfNone "Help function to AvlTreeAdd2"
input Option<AvlTree> t;
output AvlTree outT;
algorithm
  outT := matchcontinue(t)
    case(NONE) then AVLTREENODE(NONE,0,NONE,NONE);
    case(SOME(outT)) then outT;   
  end matchcontinue;
end createEmptyAvlIfNone;

protected function nodeValue "return the node value"
input AvlTree bt;
output AvlValue v;
algorithm
  v := matchcontinue(bt)
    case(AVLTREENODE(value=SOME(AVLTREEVALUE(_,v)))) then v;
  end matchcontinue;
end nodeValue;

protected function balance "Balances a AvlTree"
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(bt)
  local Integer d;
    case(bt) equation
      d = differenceInHeight(bt);
      bt = doBalance(d,bt);
    then bt;
    case(_) equation
      print("balance failed\n");
    then fail();
  end matchcontinue;
end balance;

protected function doBalance "perform balance if difference is > 1 or < -1"
input Integer difference;
input AvlTree bt;
output AvlTree outBt;
algorithm
  outBt := matchcontinue(difference,bt)
    case(-1,bt) then computeHeight(bt);
    case(0,bt) then computeHeight(bt);
    case(1,bt) then computeHeight(bt);
      /* d < -1 or d > 1 */
    case(difference,bt) equation
      bt = doBalance2(difference,bt);
    then bt;
    case(difference,bt) then bt;      
  end  matchcontinue;
end doBalance;

protected function doBalance2 "help function to doBalance"
  input Integer difference;
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(difference,bt)
    case(difference,bt) equation
      true = difference < 0; 
      bt = doBalance3(bt);
      bt = rotateLeft(bt);     
     then bt;
    case(difference,bt) equation
      true = difference > 0;
      bt = doBalance4(bt);
      bt = rotateRight(bt);
     then bt;       
  end matchcontinue;
end doBalance2;

protected function doBalance3 "help function to doBalance2"
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(bt)
  local AvlTree rr;
    case(bt) equation
      true = differenceInHeight(getOption(rightNode(bt))) > 0;
      rr = rotateRight(getOption(rightNode(bt)));
      bt = setRight(bt,SOME(rr)); 
    then bt;
    case(bt) then bt;
  end matchcontinue;
end doBalance3;

protected function doBalance4 "help function to doBalance2"
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(bt)
  local AvlTree rl;
 case(bt) equation
      true = differenceInHeight(getOption(leftNode(bt))) < 0;
      rl = rotateLeft(getOption(leftNode(bt)));
      bt = setLeft(bt,SOME(rl)); 
    then bt;
  end matchcontinue;
end doBalance4;
      
protected function setRight "set right treenode"
  input AvlTree node;
  input Option<AvlTree> right;
  output AvlTree outNode;
algorithm
  outNode := matchcontinue(node,right)
   local Option<AvlTreeValue> value;
    Option<AvlTree> l,r;
    Integer height;
    case(AVLTREENODE(value,height,l,r),right) then AVLTREENODE(value,height,l,right);
  end matchcontinue;
end setRight;

protected function setLeft "set left treenode"
  input AvlTree node;
  input Option<AvlTree> left;
  output AvlTree outNode;
algorithm
  outNode := matchcontinue(node,left)
  local Option<AvlTreeValue> value;
    Option<AvlTree> l,r;
    Integer height;
    case(AVLTREENODE(value,height,l,r),left) then AVLTREENODE(value,height,left,r);
  end matchcontinue;
end setLeft;


protected function leftNode "Retrieve the left subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  subNode := matchcontinue(node)
    case(AVLTREENODE(left = subNode)) then subNode;
  end matchcontinue;
end leftNode;

protected function rightNode "Retrieve the right subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  subNode := matchcontinue(node)
    case(AVLTREENODE(right = subNode)) then subNode;
  end matchcontinue;
end rightNode;

protected function exchangeLeft "help function to balance"
input AvlTree node;
input AvlTree parent;
output AvlTree outParent "updated parent";
algorithm
  outParent := matchcontinue(node,parent)
    local Option<AvlTreeValue> value;
      Integer height ;
      AvlTree left,right,bt,leftNode,rightNode;
      
    case(node,parent) equation      
      parent = setRight(parent,leftNode(node));
      parent = balance(parent);
      node = setLeft(node,SOME(parent));
      bt = balance(node);
    then bt;         
  end matchcontinue;
end exchangeLeft;

protected function exchangeRight "help function to balance"
input AvlTree node;
input AvlTree parent;
output AvlTree outParent "updated parent";
algorithm
  outParent := matchcontinue(node,parent)
  local AvlTree bt;
    case(node,parent) equation
      parent = setLeft(parent,rightNode(node));
      parent = balance(parent);
      node = setRight(node,SOME(parent));
      bt = balance(node);
    then bt;
  end matchcontinue;
end exchangeRight;

protected function rotateLeft "help function to balance"
input AvlTree node;
output AvlTree outNode "updated node";
algorithm
  outNode := exchangeLeft(getOption(rightNode(node)),node);
end rotateLeft;

protected function getOption "Retrieve the value of an option"
  replaceable type T subtypeof Any;
  input Option<T> opt;
  output T val;
algorithm
  val := matchcontinue(opt)
    case(SOME(val)) then val;
  end matchcontinue;
end getOption;

protected function rotateRight "help function to balance"
input AvlTree node;
output AvlTree outNode "updated node";
algorithm
  outNode := exchangeRight(getOption(leftNode(node)),node);
end rotateRight;

protected function differenceInHeight "help function to balance, calculates the difference in height
between left and right child"
input AvlTree node;
output Integer diff;
algorithm 
  diff := matchcontinue(node)
  local Integer lh,rh;
    Option<AvlTree> l,r;
    case(AVLTREENODE(left=l,right=r)) equation
      lh = getHeight(l);
      rh = getHeight(r);
    then lh - rh;
  end matchcontinue;
end differenceInHeight;

public function avlTreeGet "  Get a value from the binary tree given a key.
"
  input AvlTree inAvlTree;
  input AvlKey inKey;
  output AvlValue outValue;
  partial function FuncTypeKeyToInteger
    input AvlKey inKey;
    output Integer outInteger;
  end FuncTypeKeyToInteger;
algorithm 
  outValue:=
  matchcontinue (inAvlTree,inKey)
    local
      partial function FuncTypeStringToInteger
        input AvlKey inString;
        output Integer outInteger;
      end FuncTypeStringToInteger;
      AvlKey rkey,key;
      AvlValue rval,res;
      Option<AvlTree> left,right;
      FuncTypeStringToInteger hashfunc;
      Integer rhval;
      /* hash func Search to the right */ 
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey,rval)),left = left,right = right),key) 
      equation 
        equality(rkey = key);
      then
        rval;
        
        /* Search to the right */ 
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey,rval)),left = left,right = SOME(right)),key) 
      local AvlTree right;
      equation
        true = System.strcmp(key,rkey) > 0;
        res = avlTreeGet(right, key);
      then
        res;

        /* Search to the left */         
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey,rval)),left = SOME(left),right = right),key) 
      local AvlTree left;
      equation 
        /*true = System.strcmp(key,rkey) < 0;*/
        res = avlTreeGet(left, key);
      then
        res;
  end matchcontinue;
end avlTreeGet;

protected function getOptionStr "function getOptionStr
 
  Retrieve the string from a string option.
  If NONE return empty string.
"
  input Option<Type_a> inTypeAOption;
  input FuncTypeType_aToString inFuncTypeTypeAToString;
  output String outString;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToString
    input Type_a inTypeA;
    output String outString;
  end FuncTypeType_aToString;
algorithm 
  outString:=
  matchcontinue (inTypeAOption,inFuncTypeTypeAToString)
    local
      String str;
      Type_a a;
      FuncTypeType_aToString r;
    case (SOME(a),r)
      equation 
        str = r(a);
      then
        str;
    case (NONE,_) then ""; 
  end matchcontinue;
end getOptionStr;

protected function printAvlTreeStr " 
  Prints the avl tree to a string
"
  input AvlTree inAvlTree;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAvlTree)
    local
      AvlKey rkey;
      String s1,s2,s3,res;
      AvlValue rval;
      Option<AvlTree> l,r;
      Integer h;
      
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey,rval)),height = h,left = l,right = r))
      equation 
        s2 = getOptionStr(l, printAvlTreeStr);
        s3 = getOptionStr(r, printAvlTreeStr);
        res = valueStr(rval) +& ",  " +& s2 +&",  " +& s3;
      then
        res;
    case (AVLTREENODE(value = NONE,left = l,right = r))
      equation 
        s2 = getOptionStr(l, printAvlTreeStr);
        s3 = getOptionStr(r, printAvlTreeStr);
        res = s2 +& ", "+& s3;
      then
        res;
  end matchcontinue;
end printAvlTreeStr;

protected function computeHeight "compute the heigth of the AvlTree and store in the node info"
  input AvlTree bt;
  output AvlTree outBt;
algorithm
 outBt := matchcontinue(bt)
 local Option<AvlTree> l,r;
   Option<AvlTreeValue> v;
   AvlValue val;
   Integer hl,hr,height;
 case(AVLTREENODE(value=v as SOME(AVLTREEVALUE(_,val)),left=l,right=r)) equation
    hl = getHeight(l);
    hr = getHeight(r);
    height = intMax(hl,hr) + 1; 
 then AVLTREENODE(v,height,l,r);    
 end matchcontinue;
end computeHeight;

protected function getHeight "Retrieve the height of a node"
  input Option<AvlTree> bt;
  output Integer height;
algorithm
  height := matchcontinue(bt)
    case(NONE) then 0;
    case(SOME(AVLTREENODE(height = height))) then height;
  end matchcontinue;
end getHeight;




end Env;

