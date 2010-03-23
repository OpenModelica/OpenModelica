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
public import DAE;
public import SCode;
public import HashTable5;

public type Ident = String " An identifier is just a string " ;
public type BCEnv = list<Env> "The environment of inherited classes";
public type Env = list<Frame> "an environment is a list of frames";

public uniontype Cache
  record CACHE
    Option<EnvCache>[:] envCache "The cache contains of environments from which classes can be found";
    Option<Env> initialEnv "and the initial environment";
    HashTable5.HashTable instantiatedFuncs "and a hashtable to indicated already instantiated functions (to break inst. of recursive function calls)";
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

type CSetsType = tuple<list<DAE.ComponentRef>,DAE.ComponentRef>;

public
uniontype Frame
  record FRAME
    Option<Ident>       optName           "Optional class name";
    AvlTree             clsAndVars        "List of uniquely named classes and variables";
    AvlTree             types             "List of types, which DOES NOT need to be uniquely named, eg. size may have several types";
    list<Item>          imports           "list of unnamed items (imports)";
    BCEnv               inherited         "list of environments for inherited elements";
    CSetsType           connectionSet     "current connection set crefs";
    Boolean             isEncapsulated    "encapsulated bool=true means that FRAME is created due to encapsulated class";
    list<SCode.Element> defineUnits "list of units defined in the frame";
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
    DAE.Var instantiated "instantiated component" ;
    Option<tuple<SCode.Element, DAE.Mod>> declaration "declaration if not fully instantiated.";
    InstStatus instStatus "if it untyped, typed or fully instantiated (dae)";
    Env env "The environment of the instantiated component. Contains e.g. all sub components";    
  end VAR;

  record CLASS
    SCode.Class class_;
    Env env;
  end CLASS;

  record TYPE
    list<DAE.Type> list_ "list since several types with the same name can exist in the same scope (overloading)" ;
  end TYPE;

  record IMPORT
    Absyn.Import import_;
  end IMPORT;

end Item;

protected import Dump;
protected import Exp;
protected import Print;
protected import Util;
protected import System;
protected import Types;
protected import Debug;
protected import OptManager;
protected import RTOpts;

public constant Env emptyEnv={} "- Values" ;

public function emptyCache
"returns an empty cache"
  output Cache cache;
 protected
  Option<EnvCache>[:] arr; HashTable5.HashTable instFuncs;
algorithm
  //print("EMPTYCACHE\n");
  arr := listArray({NONE});
  instFuncs := HashTable5.emptyHashTable();
  cache := CACHE(arr,NONE,instFuncs);
end emptyCache;

public constant String forScopeName="$for loop scope$" "a unique scope used in for equations";
public constant String forIterScopeName="$foriter loop scope$" "a unique scope used in for iterators";
public constant String valueBlockScopeName="$valueblock scope$" "a unique scope used by valueblocks";

// functions for dealing with the environment

public function newFrame "function: newFrame
  This function creates a new frame, which includes setting up the
  hashtable for the frame."
  input Boolean enc;
  output Frame outFrame;
  AvlTree httypes;
  AvlTree ht;
algorithm
  ht := avlTreeNew();
  httypes := avlTreeNew();
  outFrame := FRAME(NONE,ht,httypes,{},{},({},DAE.CREF_IDENT("",DAE.ET_OTHER(),{})),enc,{});
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
  derived, see nameScope."
  input Env inEnv;
  input Boolean inBoolean;
  input Option<Ident> inIdentOption;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv,inBoolean,inIdentOption)
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
        frame :: env;
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
  outEnv := matchcontinue (inEnv,inIdent)
    local
      AvlTree httypes;
      AvlTree ht;
      list<AvlValue> imps;
      BCEnv bcframes;
      Env res;
      tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crs;
      Boolean encflag;
      Ident id;
      list<SCode.Element> defineUnits;

    case ((FRAME(_,ht,httypes,imps,bcframes,crs,encflag,defineUnits) :: res),id)
    then (FRAME(SOME(id),ht,httypes,imps,bcframes,crs,encflag,defineUnits) :: res);
  end matchcontinue;
end nameScope;

public function inForLoopScope "returns true if environment has a frame that is a for loop"
  input Env env;
  output Boolean res;
algorithm
  res := matchcontinue(env)
  local String name;
    case(FRAME(optName = SOME(name))::_) equation
      equality(name=forScopeName);
    then true;
    case(_) then false;
  end matchcontinue;
end inForLoopScope;

public function inForIterLoopScope "returns true if environment has a frame that is a for iterator 'loop'"
  input Env env;
  output Boolean res;
algorithm
  res := matchcontinue(env)
  local String name;
    case(FRAME(optName = SOME(name))::_) equation
      equality(name=forIterScopeName);
    then true;
    case(_) then false;
  end matchcontinue;
end inForIterLoopScope;


public function stripForLoopScope "strips for loop scopes"
  input Env env;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(env)
  local String name;
    case(FRAME(optName = SOME(name))::env) equation
      equality(name=forScopeName);
      env = stripForLoopScope(env);
    then env;
    case(env) then env;
  end matchcontinue;
end stripForLoopScope;

public function getScopeName "function: getScopeName
 Returns the name of a scope, if no name exist, the function fails."
  input Env inEnv;
  output Ident name;
algorithm
  name:= matchcontinue (inEnv)
    case ((FRAME(optName = SOME(name))::_)) then (name);
  end matchcontinue;
end getScopeName;

public function getScopeNames "function: getScopeName
 Returns the name of a scope, if no name exist, the function fails."
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
    BCEnv inherited;
    list<Frame> fs;
    tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crefs;
    Boolean enc;
    list<SCode.Element> defineUnits;

    case(FRAME(optName,clsAndVars,types,imports,inherited,crefs,enc,defineUnits)::fs,classEnv)
      equation
        clsAndVars = updateEnvClassesInTree(clsAndVars,classEnv);
      then FRAME(optName,clsAndVars,types,imports,inherited,crefs,enc,defineUnits)::fs;
  end matchcontinue;
end updateEnvClasses;

protected function updateEnvClassesInTree "Help function to updateEnvClasses"
  input AvlTree tree;
  input Env classEnv;
  output AvlTree outTree;
algorithm
  outTree := matchcontinue(tree,classEnv)
    local
      SCode.Class cl;
      Option<AvlTree> l,r;
      AvlKey k;
      Env env;
      Item item;
      Integer h;
   // Classes
   case(AVLTREENODE(SOME(AVLTREEVALUE(k,CLASS(cl,env))),h,l,r),classEnv) equation
      l = updateEnvClassesInTreeOpt(l,classEnv);
      r = updateEnvClassesInTreeOpt(r,classEnv);
   then AVLTREENODE(SOME(AVLTREEVALUE(k,CLASS(cl,classEnv))),h,l,r);

   // Other items
   case(AVLTREENODE(SOME(AVLTREEVALUE(k,item)),h,l,r),classEnv) equation
      l = updateEnvClassesInTreeOpt(l,classEnv);
      r = updateEnvClassesInTreeOpt(r,classEnv);
   then AVLTREENODE(SOME(AVLTREEVALUE(k,item)),h,l,r);

   // nothing
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
  This function adds a class definition to the environment."
  input Env inEnv;
  input SCode.Class inClass;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv,inClass)
    local
      AvlTree httypes;
      AvlTree ht,ht_1;
      Env env,fs;
      BCEnv bcframes;
      Option<Ident> id;
      list<AvlValue> imps;
      tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crs;
      Boolean encflag;
      SCode.Class c;
      Ident n;
      list<SCode.Element> defineUnits;

    case ((env as (FRAME(id,ht,httypes,imps,bcframes,crs,encflag,defineUnits) :: fs)),(c as SCode.CLASS(name = n)))
      equation
        (ht_1) = avlTreeAdd(ht, n, CLASS(c,env));
      then
        (FRAME(id,ht_1,httypes,imps,bcframes,crs,encflag,defineUnits) :: fs);

    case (_,_)
      equation
        print("extend_frame_c FAILED\n");
      then
        fail();
  end matchcontinue;
end extendFrameC;

public function extendFrameClasses "function: extendFrameClasses
  Adds all clases in a Program to the environment."
  input Env inEnv;
  input SCode.Program inProgram;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv,inProgram)
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
  This function adds a component to the environment."
  input Env inEnv1;
  input DAE.Var inVar2;
  input Option<tuple<SCode.Element, DAE.Mod>> inTplSCodeElementTypesModOption3;
  input InstStatus instStatus;
  input Env inEnv5;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv1,inVar2,inTplSCodeElementTypesModOption3,instStatus,inEnv5)
    local
      AvlTree httypes;
      AvlTree ht,ht_1;
      Option<Ident> id;
      list<AvlValue> imps;
      Env fs,env,remember;
      BCEnv bcframes;
      tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crs;
      Boolean encflag;
      InstStatus i;
      DAE.Var v;
      Ident n;
      Option<tuple<SCode.Element, DAE.Mod>> c;
      list<SCode.Element> defineUnits;

    case ((FRAME(id,ht,httypes,imps,bcframes,crs,encflag,defineUnits) :: fs),(v as DAE.TYPES_VAR(name = n)),c,i,env) /* environment of component */
      equation
        //failure((_)= avlTreeGet(ht, n));
        (ht_1) = avlTreeAdd(ht, n, VAR(v,c,i,env));
      then
        (FRAME(id,ht_1,httypes,imps,bcframes,crs,encflag,defineUnits) :: fs);

    // Variable already added, perhaps from baseclass
    case (remember as (FRAME(id,ht,httypes,imps,bcframes,crs,encflag,defineUnits) :: fs),
          (v as DAE.TYPES_VAR(name = n)),c,i,env) /* environment of component */
      equation
        (_)= avlTreeGet(ht, n);
      then
        (remember);
  end matchcontinue;
end extendFrameV;

public function updateFrameV "function: updateFrameV
  This function updates a component already added to the environment, but
  that prior to the update did not have any binding. I.e this function is
  called in the second stage of instantiation with declare before use."
  input Env inEnv1;
  input DAE.Var inVar2;
  input InstStatus instStatus;
  input Env inEnv4;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv1,inVar2,instStatus,inEnv4)
    local
      Boolean encflag;
      InstStatus i;
      Option<tuple<SCode.Element, DAE.Mod>> c;
      AvlTree httypes;
      AvlTree ht,ht_1;
      Option<Ident> sid;
      list<AvlValue> imps;
      BCEnv bcframes;
      Env fs,env,frames;
      tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crs;
      DAE.Var v;
      Ident n,id;
      list<SCode.Element> defineUnits;

    case ({},_,i,_) then {};  /* fully instantiated env of component */
    case ((FRAME(sid,ht,httypes,imps,bcframes,crs,encflag,defineUnits) :: fs),(v as DAE.TYPES_VAR(name = n)),i,env)
      equation
        VAR(_,c,_,_) = avlTreeGet(ht, n);
        (ht_1) = avlTreeAdd(ht, n, VAR(v,c,i,env));
      then
        (FRAME(sid,ht_1,httypes,imps,bcframes,crs,encflag,defineUnits) :: fs);
    case ((FRAME(sid,ht,httypes,imps,bcframes,crs,encflag,defineUnits) :: fs),(v as DAE.TYPES_VAR(name = n)),i,env) /* Also check frames above, e.g. when variable is in base class */
      equation
        frames = updateFrameV(fs, v, i, env);
      then
        (FRAME(sid,ht,httypes,imps,bcframes,crs,encflag,defineUnits) :: frames);
    case ((FRAME(sid,ht, httypes,imps,bcframes,crs,encflag,defineUnits) :: fs),DAE.TYPES_VAR(name = n),_,_)
      equation
        /*Print.printBuf("- update_frame_v, variable ");
        Print.printBuf(n);
        Print.printBuf(" not found\n rest of env:");
        printEnv(fs);
        Print.printBuf("\n");*/
      then
        (FRAME(sid,ht,httypes,imps,bcframes,crs,encflag,defineUnits) :: fs);
    case (_,(v as DAE.TYPES_VAR(name = id)),_,_)
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
  environment."
  input Env inEnv;
  input Ident inIdent;
  input DAE.Type inType;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv,inIdent,inType)
    local
      list<tuple<DAE.TType, Option<Absyn.Path>>> tps;
      AvlTree httypes_1,httypes;
      AvlTree ht;
      Option<Ident> sid;
      list<AvlValue> imps;
      BCEnv bcframes;
      Env fs;
      tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crs;
      Boolean encflag;
      Ident n;
      tuple<DAE.TType, Option<Absyn.Path>> t;
      list<SCode.Element> defineUnits;

    case ((FRAME(sid,ht,httypes,imps,bcframes,crs,encflag,defineUnits) :: fs),n,t)
      equation
        TYPE(tps) = avlTreeGet(httypes, n) "Other types with that name allready exist, add this type as well" ;
        (httypes_1) = avlTreeAdd(httypes, n, TYPE((t :: tps)));
      then
        (FRAME(sid,ht,httypes_1,imps,bcframes,crs,encflag,defineUnits) :: fs);
    case ((FRAME(sid,ht,httypes,imps,bcframes,crs,encflag,defineUnits) :: fs),n,t)
      equation
        failure(TYPE(_) = avlTreeGet(httypes, n)) "No other types exists" ;
        (httypes_1) = avlTreeAdd(httypes, n, TYPE({t}));
      then
        (FRAME(sid,ht,httypes_1,imps,bcframes,crs,encflag,defineUnits) :: fs);
  end matchcontinue;
end extendFrameT;

public function extendFrameI "function: extendsFrameI
  Adds an import statement to the environment."
  input Env inEnv;
  input Absyn.Import inImport;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv,inImport)
    local
      Option<Ident> sid;
      AvlTree httypes;
      AvlTree ht;
      list<AvlValue> imps;
      BCEnv bcframes;
      tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crs;
      Boolean encflag;
      Absyn.Import imp;
      Env fs,env;
      list<SCode.Element> defineUnits;

    case ((FRAME(sid,ht,httypes,imps,bcframes,crs,encflag,defineUnits) :: fs),imp)
      equation
        false = memberImportList(imps,imp);
    then (FRAME(sid,ht,httypes,(IMPORT(imp) :: imps),bcframes,crs,encflag,defineUnits) :: fs);

    case (env,imp) then env;
  end matchcontinue;
end extendFrameI;

public function extendFrameDefunit "
  Adds a defineunit to the environment."
  input Env inEnv;
  input SCode.Element defunit;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv,defunit)
    local
      Option<Ident> sid;
      AvlTree httypes;
      AvlTree ht;
      list<AvlValue> imps;
      BCEnv bcframes;
      tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crs;
      Boolean encflag;
      Env fs;
      list<SCode.Element> defineUnits;

    case ((FRAME(sid,ht,httypes,imps,bcframes,crs,encflag,defineUnits) :: fs),defunit)
    then (FRAME(sid,ht,httypes,imps,bcframes,crs,encflag,defunit::defineUnits) :: fs);
  end matchcontinue;
end extendFrameDefunit;

public function extendFrameForIterator
	"Adds a for loop iterator to the environment."
	input Env env;
	input String name;
	input DAE.Type type_;
	input DAE.Binding binding;
	input SCode.Variability variability;
	input Option<DAE.Const> constOfForIteratorRange;
	output Env new_env;
algorithm
	new_env := matchcontinue(env, name, type_, binding, variability, constOfForIteratorRange)
		local
			Env new_env_1;
		case (_, _, _, _,variability,constOfForIteratorRange)
			equation
				new_env_1 = extendFrameV(env,
					DAE.TYPES_VAR(
						name,
						DAE.ATTR(false, false, SCode.RW(), variability, Absyn.BIDIR(), Absyn.UNSPECIFIED()),
						false,
						type_,
						binding,
						constOfForIteratorRange),
					NONE, VAR_UNTYPED(), {});
			then new_env_1;
	end matchcontinue;
end extendFrameForIterator;

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

/*
public function addBcFrame "function: addBcFrame
  author: PA
  Adds a baseclass frame to the environment from the baseclass environment
  to the list of base classes of the top frame of the passed environment."
  input Env inEnv1;
  input Env inEnv2;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv1,inEnv2)
    local
      Option<Ident> sid;
      AvlTree tps;
      AvlTree cls;
      list<AvlValue> imps;
      Env bc,fs;
      tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crefs;
      Boolean enc;
      Frame f;
      list<SCode.Element> defineUnits;

    case ((FRAME(sid,cls,tps,imps,bc,crefs,enc,defineUnits) :: fs),(f :: _))
      then (FRAME(sid,cls,tps,imps,(f :: bc),crefs,enc,defineUnits) :: fs);
  end matchcontinue;
end addBcFrame;
*/

public function topFrame "function: topFrame
  Returns the top frame."
  input Env inEnv;
  output Frame outFrame;
algorithm
  outFrame := matchcontinue (inEnv)
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

/*
public function enclosingScopeEnv "function: enclosingScopeEnv
@author: adrpo
 Returns the environment with the current scope frame removed."
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv)
    local
      Env rest;
    case ({}) then {};
    case (_ :: rest)
      then
        rest;
  end matchcontinue;
end enclosingScopeEnv;
*/

public function getClassName
  input Env inEnv;
  output Ident name;
algorithm
   name := matchcontinue (inEnv)
   	local Ident n;
   	case FRAME(optName = SOME(n))::_ then n;
  end matchcontinue;
end getClassName;

public function getEnvName "returns the FQ name of the environment, see also getEnvPath"
input Env env;
output Absyn.Path path;
algorithm
  path := matchcontinue(env)
    case(env) equation
      SOME(path) = getEnvPath(env);
    then path;
    case _
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- Env.getEnvName failed");
        _ = getEnvPath(env);
      then fail();
  end matchcontinue;
end getEnvName;

public function getEnvPath "function: getEnvPath
  This function returns all partially instantiated parents as an Absyn.Path
  option I.e. it collects all identifiers of each frame until it reaches
  the topmost unnamed frame. If the environment is only the topmost frame,
  NONE is returned."
  input Env inEnv;
  output Option<Absyn.Path> outAbsynPathOption;
algorithm
  outAbsynPathOption := matchcontinue (inEnv)
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

public function joinEnvPath "function: joinEnvPath
  Used to join an Env with an Absyn.Path (probably an IDENT)"
  input Env inEnv;
  input Absyn.Path inPath;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue(inEnv,inPath)
    local
      Absyn.Path envPath;
    case (inEnv,inPath)
      equation
        SOME(envPath) = getEnvPath(inEnv);
        envPath = Absyn.joinPaths(envPath,inPath);
      then envPath;
    case (inEnv,inPath)
      equation
        NONE() = getEnvPath(inEnv);
      then inPath;
  end matchcontinue;
end joinEnvPath;

public function printEnvPathStr "function: printEnvPathStr
 Retrive the environment path as a string, see getEnvPath."
  input Env inEnv;
  output String outString;
algorithm
  outString := matchcontinue (inEnv)
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
  See also getEnvPath"
  input Env inEnv;
algorithm
  _ := matchcontinue (inEnv)
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
  Print the environment as a string."
  input Env inEnv;
  output String outString;
algorithm
  outString := matchcontinue (inEnv)
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
  Print the environment to the Print buffer."
  input Env e;
  Ident s;
algorithm
  s := printEnvStr(e);
  Print.printBuf(s);
end printEnv;

public function printEnvConnectionCrefs "prints the connection crefs of the top frame"
  input Env env;
algorithm
  _ := matchcontinue(env)
    local
      list<DAE.ComponentRef> crs;
      Env env;
    case(env as (FRAME(connectionSet = (crs,_))::_)) equation
      print(printEnvPathStr(env));print(" :   ");
      print(Util.stringDelimitList(Util.listMap(crs,Exp.printComponentRefStr),", "));
      print("\n");
    then ();
  end matchcontinue;
end printEnvConnectionCrefs;

protected function printFrameStr "function: printFrameStr
  Print a Frame to a string."
  input Frame inFrame;
  output String outString;
algorithm
  outString := matchcontinue (inFrame)
    local
      Ident s1,s2,s3,encflag_str,s4,res,sid;
      Option<Ident> optName;
      list<Ident> bcstrings;
      AvlTree httypes;
      AvlTree ht;
      list<AvlValue> imps;
      BCEnv bcframes;
      tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crs;
      Boolean encflag;
    case FRAME(optName = optName,clsAndVars = ht,types = httypes,imports = imps,inherited = bcframes,connectionSet = crs,isEncapsulated = encflag)
      equation
        sid = Util.getOptionOrDefault(optName, "unnamed");
        s1 = printAvlTreeStr(ht);
        s2 = printAvlTreeStr(httypes);
        s3 = printImportsStr(imps);
        s4 = Util.stringAppendList(Util.listMap(bcframes,printEnvStr));
        encflag_str = Util.boolString(encflag);
        res = Util.stringAppendList(
          "FRAME: " :: sid :: " (enc=" :: encflag_str ::
          ") \nclasses and vars:\n=============\n" :: s1 :: "   Types:\n======\n" :: s2 :: "   Imports:\n=======\n" :: s3 ::
          "baseclass:\n======\n" :: s4 :: "end baseclass\n" :: {});
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
      tuple<list<DAE.ComponentRef>,DAE.ComponentRef> crs;
      Boolean encflag;
    case FRAME(optName = SOME(sid),clsAndVars = ht,types = httypes,imports = imps,connectionSet = crs,isEncapsulated = encflag)
      equation
        s1 = printAvlTreeStr(ht);
        encflag_str = Util.boolString(encflag);
        res = Util.stringAppendList(
          {"FRAME: ",sid," (enc=",encflag_str,
          ") \nclasses and vars:\n=============\n",s1,"\n\n\n"});
      then
        res;
    case FRAME(optName = NONE,clsAndVars = ht,types = httypes,imports = imps,connectionSet = crs,isEncapsulated = encflag)
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
      DAE.Var tv;
      SCode.Variability var;
      tuple<DAE.TType, Option<Absyn.Path>> tp;
      DAE.Binding bind,bnd;
      SCode.Element elt;
      InstStatus i;
      Frame compframe;
      Env env;
      Integer len;
      list<tuple<DAE.TType, Option<Absyn.Path>>> lst;
      Absyn.Import imp;
    case ((n,VAR(instantiated = (tv as DAE.TYPES_VAR(attributes = DAE.ATTR(parameter_ = var),type_ = tp,binding = bind)),declaration = SOME((elt,_)),instStatus = i,env = (compframe :: _))))
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
    case ((n,VAR(instantiated = (tv as DAE.TYPES_VAR(attributes = DAE.ATTR(parameter_ = var),type_ = tp)),declaration = SOME((elt,_)),instStatus = i,env = {})))
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
    case ((n,VAR(instantiated = DAE.TYPES_VAR(binding = bnd),declaration = NONE,instStatus = i,env = env)))
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
    case (CACHE(_,SOME(env),_)) equation
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
    	Option<EnvCache>[:] envCache;
    	HashTable5.HashTable ef;

    case (CACHE(envCache,_,ef),env) equation
 //    	print("setCachedInitialEnv\n");
      then CACHE(envCache,SOME(env),ef);
  end matchcontinue;
end setCachedInitialEnv;

public function addCachedInstFunc "adds the FQ path to the set of instantiated functions"
  input Cache inCache;
  input Absyn.Path func "fully qualified function name";
  output Cache outCache;
algorithm
  outCache := matchcontinue(inCache,func)
  local
    	Option<EnvCache>[:] envCache;
    	HashTable5.HashTable ef;
    	Absyn.ComponentRef cr;
    	Option<Env> ienv;

    case (CACHE(envCache,ienv,ef),func) equation
      cr = Absyn.pathToCref(func);
      ef = HashTable5.add((cr,0),ef);
      then CACHE(envCache,ienv,ef);
  end matchcontinue;
end addCachedInstFunc;

function getCachedInstFunc "returns the integer value 0 if the FQ function is in the set of already instantiated functions. If not, this function fails"
  input Cache inCache;
  input Absyn.Path path;
  output Integer res;
algorithm
  res := matchcontinue(inCache,path)
  local HashTable5.HashTable ef; Absyn.ComponentRef cr;
    Integer v;
    case(CACHE(instantiatedFuncs=ef),path) equation
      cr = Absyn.pathToCref(path);
      v = HashTable5.get(cr,ef);
    then v;
  end matchcontinue;
end getCachedInstFunc;

public function cacheGet "Get an environment from the cache."
  input Absyn.Path scope;
  input Absyn.Path path;
  input Cache cache;
  output Env env;
algorithm
  env:= matchcontinue(scope,path,cache)
  local CacheTree tree;  Option<EnvCache>[:] arr;
    HashTable5.HashTable ef;
   case (scope,path,CACHE(arr ,_,ef))
      equation
        true = OptManager.getOption("envCache");
        SOME(ENVCACHE(tree)) = arr[1];
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
    Option<EnvCache>[:] arr;
    HashTable5.HashTable ef;
    case(_,inCache,env) equation
      false = OptManager.getOption("envCache");
    then inCache;

    case (fullpath,CACHE(arr,ie,ef),env)
      equation
        NONE = arr[1];
        tree = cacheAddEnv(fullpath,CACHETREE("$global",emptyEnv,{}),env);
        //print("Adding ");print(Absyn.pathString(fullpath));print(" to empty cache\n");
        arr = arrayUpdate(arr,1,SOME(ENVCACHE(tree)));
      then CACHE(arr,ie,ef);
    case (fullpath,CACHE(arr,ie,ef),env)
      equation
        SOME(ENVCACHE(tree))=arr[1];
       // print(" about to Adding ");print(Absyn.pathString(fullpath));print(" to cache:\n");
      tree = cacheAddEnv(fullpath,tree,env);

       //print("Adding ");print(Absyn.pathString(fullpath));print(" to cache\n");
        //print(printCacheStr(CACHE(SOME(ENVCACHE(tree)),ie)));
        arr = arrayUpdate(arr,1,SOME(ENVCACHE(tree)));
      then CACHE(arr,ie,ef);
    case (_,_,_) equation
      true = OptManager.getOption("envCache");
      print("cacheAdd failed\n");
    then fail();
  end matchcontinue;
end cacheAdd;

// moved from Inst as is more natural to be here!
public function addCachedEnv
"function: addCachedEnv
  add a new environment in the cache obtaining a new cache"
  input Cache inCache;
  input String id;
  input Env env;
  output Cache outCache;
algorithm
  outCache := matchcontinue(inCache,id,env)
    local
      Absyn.Path path,newPath;
      case(inCache,id,env) equation
        false = OptManager.getOption("envCache");
      then inCache;

    case(inCache,id,env)
      equation

        SOME(path) = getEnvPath(env);
        outCache = cacheAdd(path,inCache,env);
      then outCache;

    case(inCache,id,env)
      equation
        // this should be placed in the global environment
        // how do we do that??
        Debug.fprintln("env", "<<<< Env.addCachedEnv - failed to add env to cache for: " +&
            printEnvPathStr(env) +& " [" +& id +& "]");
      then inCache;

  end matchcontinue;
end addCachedEnv;

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
        true = OptManager.getOption("envCache");
        env = cacheGetEnv2(path2,path,tree);
        //print("found ");print(Absyn.pathString(path));print(" in cache at scope");
				//print(Absyn.pathString(path2));print("  pathEnv:"+&printEnvPathStr(env)+&"\n");
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
     
     // for qualified name, try next.
   /*  case (Absyn.QUALIFIED(id, path2), path, CACHETREE(id2, env2, _ :: children))
       equation
         env = cacheGetEnv2(Absyn.QUALIFIED(id, path2), path, CACHETREE(id2, env2, children));
       then env;*/
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
        // shouldn't we replace it?
        // Debug.fprintln("env", ">>>> Env.cacheAdd - already in cache: " +& printEnvPathStr(env));
      then tree;

    // simple names try next
    case (Absyn.IDENT(id),tree as CACHETREE(globalID,globalEnv,child::children),env)
      equation
        CACHETREE(globalID,globalEnv,children) = cacheAddEnv(Absyn.IDENT(id),CACHETREE(globalID,globalEnv,children),env);
      then CACHETREE(globalID,globalEnv,child::children);

    // Simple names, not found
    case (Absyn.IDENT(id),CACHETREE(globalID,globalEnv,{}),env)
      equation
        // Debug.fprintln("env", ">>>> Env.cacheAdd - add to cache: " +& printEnvPathStr(env));
      then CACHETREE(globalID,globalEnv,{CACHETREE(id,env,{})});

    // Qualified names.
    case (path as Absyn.QUALIFIED(_,_),CACHETREE(globalID,globalEnv,children),env)
      equation
        children=cacheAddEnv2(path,children,env);
      then CACHETREE(globalID,globalEnv,children);

    // failure
    case (path,_,_)
      equation
        print("cacheAddEnv path=");print(Absyn.pathString(path));print(" failed\n");
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
        // Debug.fprintln("env", ">>>> Env.cacheAdd - already in cache: " +& printEnvPathStr(env));
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
        // Debug.fprintln("env", ">>>> Env.cacheAdd - add to cache: " +& printEnvPathStr(env));
        //print("qualified name no child found, create one.\n");
      then {CACHETREE(id,emptyEnv,children)};

    // simple name no child found, create one.
    case (Absyn.IDENT(id),{},env)
      equation
        // print("simple name no child found, create one.\n");
        // Debug.fprintln("env", ">>>> Env.cacheAdd - add to cache: " +& printEnvPathStr(env));
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
    Option<EnvCache>[:] arr;
    HashTable5.HashTable ef;
    case CACHE(arr,_,ef)
      local String s,s2;
      equation
        SOME(ENVCACHE(tree)) = arr[1];
      s = printCacheTreeStr(tree,1);
      str = Util.stringAppendList({"Cache:\n",s,"\n"});
      s2 = HashTable5.dumpHashTableStr(ef);
      str = str +& "\nInstantiated funcs: " +& s2 +&"\n";
      then str;
    case CACHE(_,_,_) then "EMPTY CACHE\n";
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

protected function dummyDump "
Author: BZ, 2009-05
Debug function, print subscripts.
"
input list<DAE.Subscript> subs;
output String str;
algorithm str := matchcontinue(subs)
  local
      DAE.Subscript s;
  case(subs)
    equation
      str = " subs: " +& Util.stringDelimitList(Util.listMap(subs,Exp.printSubscriptStr),", ") +& "\n";
      print(str);
      then
        str;
  end matchcontinue;
end dummyDump;

protected function integer2Subscript "
@author adrpo
 given an integer transform it into an DAE.Subscript"
  input  Integer       index;
  output DAE.Subscript subscript;
algorithm
 subscript := DAE.INDEX(DAE.ICONST(index));
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
  local String name; DAE.Type tp; Absyn.Import imp;
    case(VAR(instantiated=DAE.TYPES_VAR(name=name,type_=tp))) equation
      str = "v: " +& name +& " " +& Types.unparseType(tp) +& "("
      +& Types.printTypeStr(tp) +& ")";
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

   
    case (AVLTREENODE(value = NONE,height=h,left = NONE,right = NONE),key as "lskf",value)
    	then AVLTREENODE(SOME(AVLTREEVALUE(key,value)),1,NONE,NONE);

		/* Replace this node */
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey,rval)),height=h,left = left,right = right),key as "lskf",value)
      equation
        equality(rkey = key);
        bt = balance(AVLTREENODE(SOME(AVLTREEVALUE(rkey,value)),h,left,right));
      then
        bt;
        
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

public function isTopScope "Returns true if we are in the top-most scope"
  input Env env;
  output Boolean isTop;
algorithm
  isTop := matchcontinue env
    case {FRAME(optName = NONE())} then true;
    case _ then false;
  end matchcontinue;
end isTopScope;

end Env;

