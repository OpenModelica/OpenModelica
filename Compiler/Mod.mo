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

package Mod
" file:        Mod.mo
  package:     Mod
  description: Modification handling

  RCS: $Id$

  Modifications are simply the same kind of modifications used in
  the Absyn module.

  This type is very similar to SCode.Mod.  
  The main difference is that it uses Exp.Exp for the expressions.  
  Expressions stored here are prefixed and typechecked.

  The datatype itself is moved to the Types module, in Types.mo, to prevent circular dependencies."


public import Absyn;
public import Env;
public import Exp;
public import Prefix;
public import SCode;
public import Types;

public type Ident = String;

protected import Dump;
protected import Debug;
protected import Inst;
protected import Static;
protected import Values;
protected import Util;
protected import Ceval;
protected import Error;
protected import Print;
//protected import Interactive;

public function elabMod
"function: elabMod
  This function elaborates on the expressions in a modification and
  turns them into global expressions.  This is done because the
  expressions in modifications must be elaborated on in the context
  they are provided in, and not the context they are used in."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  input SCode.Mod inMod;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Types.Mod outMod;
algorithm 
  (outCache,outMod) :=
  matchcontinue (inCache,inEnv,inPrefix,inMod,inBoolean)
    local
      Boolean impl,finalPrefix;
      list<Types.SubMod> subs_1;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      SCode.Mod m,mod;
      Absyn.Each each_;
      list<SCode.SubMod> subs;
      Exp.Exp e_1,e_2;
      Types.Properties prop;
      Option<Values.Value> e_val;
      Absyn.Exp e,e1;
      list<tuple<SCode.Element, Types.Mod>> elist_1;
      list<SCode.Element> elist;
      Ident str;
      Env.Cache cache;
    case (cache,_,_,SCode.NOMOD(),impl) then (cache,Types.NOMOD());  /* impl */ 
    case (cache,env,pre,(m as SCode.MOD(finalPrefix = finalPrefix,eachPrefix = each_,subModLst = subs,absynExpOption = NONE)),impl)
      equation 
        (cache,subs_1) = elabSubmods(cache,env, pre, subs, impl);
      then
        (cache,Types.MOD(finalPrefix,each_,subs_1,NONE));
        
        // Only elaborate expressions with non-delayed type checking, see SCode.MOD.
    case (cache,env,pre,(m as SCode.MOD(finalPrefix = finalPrefix,eachPrefix = each_,subModLst = subs,absynExpOption = SOME((e,false)))),impl)
      equation 
        (cache,subs_1) = elabSubmods(cache,env, pre, subs, impl);
        (cache,e_1,prop,_) = Static.elabExp(cache,env, e, impl, NONE,true);
        (cache,e_val) = elabModValue(cache,env, e_1);
        (cache,e_2) = Prefix.prefixExp(cache,env, e_1, pre) 
        "Bug: will cause elaboration of parameters without value to fail, 
         But this can be ok, since a modifier is present, giving it a value from outer modifications.." ;
      then
        (cache,Types.MOD(finalPrefix,each_,subs_1,SOME(Types.TYPED(e_2,e_val,prop))));
     
     // Delayed type checking
     case (cache,env,pre,(m as SCode.MOD(finalPrefix = finalPrefix,eachPrefix = each_,subModLst = subs,absynExpOption = SOME((e,true)))),impl)
      equation 
        (cache,subs_1) = elabSubmods(cache,env, pre, subs, impl);
      then
        (cache,Types.MOD(finalPrefix,each_,subs_1,SOME(Types.UNTYPED(e))));   
        
    case (cache,env,pre,(m as SCode.REDECL(finalPrefix = finalPrefix,elementLst = elist)),impl)
      equation 
        
        //elist_1 = Inst.addNomod(elist);
        elist_1 = elabModRedeclareElements(cache,env,pre,finalPrefix,elist,impl);
      then
        (cache,Types.REDECL(finalPrefix,elist_1));
    case (cache,env,pre,mod,impl)
      equation 
        /*Debug.fprint("failtrace", "#-- elab_mod ");
        str = SCode.printModStr(mod);
        Debug.fprint("failtrace", str);
        Debug.fprint("failtrace", " failed\n");
        print("elab mod failed, mod:");print(str);print("\n");
        print("env:");print(Env.printEnvStr(env));print("\n");*/
        /*elab mod can fail?
        
        */
      then
        fail();
  end matchcontinue;
end elabMod;

protected function elabModRedeclareElements
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
	input Boolean finalPrefix;
	input list<SCode.Element> elts;
	input Boolean impl;
	output list<tuple<SCode.Element, Types.Mod>> modElts "the elaborated modifiers";
algorithm
	(modElts) := matchcontinue(inCache,inEnv,inPrefix,finalPrefix,elts,impl)
	local 
	  Env.Cache cache; Env.Env env; Prefix.Prefix pre; Boolean f,fi,repl,p,enc,prot;
	  Absyn.InnerOuter io;
	  list<SCode.Element> elts;
	  SCode.Ident cn,cn2,compname; 
	  Option<Absyn.Path> bc;
	  Option<Absyn.Comment> cmt;
	  SCode.Restriction restr;
	  Absyn.TypeSpec tp,tp1;
	  Types.Mod emod;
	  SCode.Attributes attr;
	  SCode.Mod mod;
	  Option<Absyn.Exp> cond;
	  Option<Absyn.Info> info;

	  /* the empty case */
	  case(cache,env,pre,f,{},_) then {};
	 
	 	// Only derived classdefinitions supported in redeclares for now. TODO: What is allowed according to spec?
	  case(cache,env,pre,f,SCode.CLASSDEF(cn,fi,repl,SCode.CLASS(cn2,p,enc,restr,SCode.DERIVED(tp,mod,attr1)),bc)::elts,impl)
	    local 
	      Absyn.ElementAttributes attr1; 
	    equation
	     (cache,emod) = elabMod(cache,env,pre,mod,impl); 
	     modElts = elabModRedeclareElements(cache,env,pre,f,elts,impl);
	     (cache,tp1) = elabModQualifyTypespec(cache,env,tp);
	 then (SCode.CLASSDEF(cn,fi,repl,SCode.CLASS(cn,p,enc,restr,SCode.DERIVED(tp1,mod,attr1)),bc),emod)::modElts;

		// redeclare of component declaration		 
	  case(cache,env,pre,f,SCode.COMPONENT(compname,io,fi,repl,prot,attr,tp,mod,bc,cmt,cond,info)::elts,impl) equation
	    (cache,emod) = elabMod(cache,env,pre,mod,impl); 
	    modElts = elabModRedeclareElements(cache,env,pre,f,elts,impl);
	    (cache,tp1) = elabModQualifyTypespec(cache,env,tp);
	  then ((SCode.COMPONENT(compname,io,fi,repl,prot,attr,tp1,mod,bc,cmt,cond,info),emod)::modElts);
	end matchcontinue;  
end elabModRedeclareElements;

protected function elabModQualifyTypespec 
"Help function to elabModRedeclareElements.
 This function makes sure that type specifiers, i.e. class names, in redeclarations are looked up in the correct environment. 
 This is achieved by making them fully qualified."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.TypeSpec tp;
  output Env.Cache outCache;
  output Absyn.TypeSpec outTp;
algorithm
  (outCache,outTp) := matchcontinue(inCache,inEnv,tp)
  	local
  	  Env.Cache cache; Env.Env env;
  	  Option<Absyn.ArrayDim> ad;
  	  Absyn.Path p,p1;
    case (cache, env,Absyn.TPATH(p,ad)) equation
      (cache,p1) = Inst.makeFullyQualified(cache,env,p);
    then (cache,Absyn.TPATH(p1,ad));
    
  end matchcontinue;
end elabModQualifyTypespec;
  
protected function elabModValue 
"function: elabModValue
  author: PA
  Helper function to elabMod. Builds values from modifier expressions if possible.
  Tries to Constant evaluate an expressions an create a Value option for it."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.Exp inExp;
  output Env.Cache outCache;
  output Option<Values.Value> outValuesValueOption;
algorithm 
  (outCache,outValuesValueOption) :=
  matchcontinue (inCache,inEnv,inExp)
    local
      Values.Value v;
      list<Env.Frame> env;
      Exp.Exp e;
      Env.Cache cache;
    case (cache,env,e) /* If ceval fails, it should not print error messages. */ 
      equation 
        (cache,v,_) = Ceval.ceval(cache,env, e, false, NONE, NONE, Ceval.NO_MSG());
      then
        (cache,SOME(v));
    case (cache,_,_) then (cache,NONE);
  end matchcontinue;
end elabModValue;

public function unelabMod 
"function: unelabMod
  Transforms Mod back to SCode.Mod, loosing type information."
  input Types.Mod inMod;
  output SCode.Mod outMod;
algorithm 
  outMod:=
  matchcontinue (inMod)
    local
      list<SCode.SubMod> subs_1;
      Types.Mod m,mod;
      Boolean finalPrefix;
      Absyn.Each each_;
      list<Types.SubMod> subs;
      Absyn.Exp e,e_1;
      Ident es,s;
      Types.Properties p;
      list<SCode.Element> elist_1;
      list<tuple<SCode.Element, Types.Mod>> elist;
    case (Types.NOMOD()) then SCode.NOMOD(); 
    case ((m as Types.MOD(finalPrefix = finalPrefix,each_ = each_,subModLst = subs,eqModOption = NONE)))
      equation 
        subs_1 = unelabSubmods(subs);
      then
        SCode.MOD(finalPrefix,each_,subs_1,NONE);
    case ((m as Types.MOD(finalPrefix = finalPrefix,each_ = each_,subModLst = subs,eqModOption = SOME(Types.UNTYPED(e)))))
      equation 
        subs_1 = unelabSubmods(subs);
      then
        SCode.MOD(finalPrefix,each_,subs_1,SOME((e,false))); // Default type checking non-delayed
    case ((m as Types.MOD(finalPrefix = finalPrefix,each_ = each_,subModLst = subs,eqModOption = SOME(Types.TYPED(e,_,p)))))
      local Exp.Exp e;
      equation 
        es = Exp.printExpStr(e);
        subs_1 = unelabSubmods(subs);
        e_1 = Exp.unelabExp(e);
      then
        SCode.MOD(finalPrefix,each_,subs_1,SOME((e_1,false))); // default typechecking non-delayed
    case ((m as Types.REDECL(finalPrefix = finalPrefix,tplSCodeElementModLst = elist)))
      equation 
        elist_1 = Util.listMap(elist, Util.tuple21);
      then
        SCode.REDECL(finalPrefix,elist_1);
    case (mod)
      equation 
        Print.printBuf("#-- Mod.elabUntypedMod failed: " +& printModStr(mod) +& "\n");
        print("- Mod.elabUntypedMod failed :" +& printModStr(mod) +& "\n");
      then
        fail();
  end matchcontinue;
end unelabMod;

protected function unelabSubmods 
"function: unelabSubmods
  Helper function to unelabMod."
  input list<Types.SubMod> inTypesSubModLst;
  output list<SCode.SubMod> outSCodeSubModLst;
algorithm 
  outSCodeSubModLst:=
  matchcontinue (inTypesSubModLst)
    local
      list<SCode.SubMod> x_1,xs_1,res;
      Types.SubMod x;
      list<Types.SubMod> xs;
    case ({}) then {}; 
    case ((x :: xs))
      equation 
        x_1 = unelabSubmod(x);
        xs_1 = unelabSubmods(xs);
        res = listAppend(x_1, xs_1);
      then
        res;
  end matchcontinue;
end unelabSubmods;

protected function unelabSubmod 
"function: unelabSubmod
  This function unelaborates on a submodification."
  input Types.SubMod inSubMod;
  output list<SCode.SubMod> outSCodeSubModLst;
algorithm 
  outSCodeSubModLst:=
  matchcontinue (inSubMod)
    local
      SCode.Mod m_1;
      Ident i;
      Types.Mod m;
      list<Absyn.Subscript> ss_1;
      list<Integer> ss;
    case (Types.NAMEMOD(ident = i,mod = m))
      equation 
        m_1 = unelabMod(m);
      then
        {SCode.NAMEMOD(i,m_1)};
    case (Types.IDXMOD(integerLst = ss,mod = m))
      equation 
        ss_1 = unelabSubscript(ss);
        m_1 = unelabMod(m);
      then
        {SCode.IDXMOD(ss_1,m_1)};
  end matchcontinue;
end unelabSubmod;

protected function unelabSubscript
  input list<Integer> inIntegerLst;
  output list<SCode.Subscript> outSCodeSubscriptLst;
algorithm 
  outSCodeSubscriptLst:=
  matchcontinue (inIntegerLst)
    local
      list<Absyn.Subscript> xs;
      Integer i;
      list<Integer> is;
    case ({}) then {}; 
    case ((i :: is))
      equation 
        xs = unelabSubscript(is);
      then
        (Absyn.SUBSCRIPT(Absyn.INTEGER(i)) :: xs);
  end matchcontinue;
end unelabSubscript;

public function updateMod 
"function: updateMod
  This function updates and untyped modification to a typed one, by looking
  up the type of the modifier in the environment and update it."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  input Types.Mod inMod;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Types.Mod outMod;
algorithm 
  (outCache,outMod) :=
  matchcontinue (inCache,inEnv,inPrefix,inMod,inBoolean)
    local
      Boolean impl,f;
      Types.Mod m;
      list<Types.SubMod> subs_1,subs;
      Exp.Exp e_1,e_2;
      Types.Properties prop,p;
      Option<Values.Value> e_val;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      Absyn.Each each_;
      Absyn.Exp e;
      Env.Cache cache;
    case (cache,_,_,Types.NOMOD(),impl) then (cache,Types.NOMOD());  /* impl */ 
    case (cache,_,_,(m as Types.REDECL(finalPrefix = _)),impl) then (cache,m); 
    case (cache,env,pre,(m as Types.MOD(finalPrefix = f,each_ = each_,subModLst = subs,eqModOption = SOME(Types.UNTYPED(e)))),impl)
      equation 
        (cache,subs_1) = updateSubmods(cache,env, pre, subs, impl);
        (cache,e_1,prop,_) = Static.elabExp(cache,env, e, impl, NONE,true);
        (cache,e_val) = elabModValue(cache,env, e_1);
        (cache,e_2) = Prefix.prefixExp(cache,env, e_1, pre);
        Debug.fprint("updmod", "Updated mod: ");
        Debug.fcall("updmod", printMod, 
          Types.MOD(f,each_,subs_1,SOME(Types.TYPED(e_2,NONE,prop))));
      then
        (cache,Types.MOD(f,each_,subs_1,SOME(Types.TYPED(e_2,e_val,prop))));
    case (cache,env,pre,Types.MOD(finalPrefix = f,each_ = each_,subModLst = subs,eqModOption = SOME(Types.TYPED(e,e_val,p))),impl)
      local Exp.Exp e;
      equation 
        (cache,subs_1) = updateSubmods(cache,env, pre, subs, impl);
      then
        (cache,Types.MOD(f,each_,subs_1,SOME(Types.TYPED(e,e_val,p))));
    case (cache,env,pre,Types.MOD(finalPrefix = f,each_ = each_,subModLst = subs,eqModOption = NONE),impl)
      equation 
        (cache,subs_1) = updateSubmods(cache,env, pre, subs, impl);
      then
        (cache,Types.MOD(f,each_,subs_1,NONE));
    case (cache,env,pre,m,impl)
      local String str;
      equation 
        str = printModStr(m);
        str = Util.stringDelimitList({ str, "\n"}," ");
        
        Print.printBuf("- update_mod failed\n mod:");
        Print.printBuf(str);
        
        Debug.fprint("failtrace", "- update_mod failed mod:");
        Debug.fprint("failtrace", str);
      then
        fail();
  end matchcontinue;
end updateMod;

protected function updateSubmods ""
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  input list<Types.SubMod> inTypesSubModLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output list<Types.SubMod> outTypesSubModLst;
algorithm 
  (outCache,outTypesSubModLst):=
  matchcontinue (inCache,inEnv,inPrefix,inTypesSubModLst,inBoolean)
    local
      Boolean impl;
      list<Types.SubMod> x_1,xs_1,res,xs;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      Types.SubMod x;
      Env.Cache cache;
    case (cache,_,_,{},impl) then (cache,{});  /* impl */ 
    case (cache,env,pre,(x :: xs),impl)
      equation 
        (cache,x_1) = updateSubmod(cache,env, pre, x, impl);
        (cache,xs_1) = updateSubmods(cache,env, pre, xs, impl);
        res = insertSubmods(x_1, xs_1, env, pre);
      then
        (cache,res);
  end matchcontinue;
end updateSubmods;

protected function updateSubmod " "
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  input Types.SubMod inSubMod;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output list<Types.SubMod> outTypesSubModLst;
algorithm 
  (outCache,outTypesSubModLst):=
  matchcontinue (outCache,inEnv,inPrefix,inSubMod,inBoolean)
    local
      Types.Mod m_1,m;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      Ident i;
      Boolean impl;
      list<Types.SubMod> smods;
      Env.Cache cache;
      list<Integer> idxmod;
    case (cache,env,pre,Types.NAMEMOD(ident = i,mod = m),impl) /* impl */ 
      equation 
        (cache,m_1) = updateMod(cache,env, pre, m, impl);
      then
        (cache,{Types.NAMEMOD(i,m_1)});
    case (cache,env,pre,Types.IDXMOD(mod = m,integerLst=idxmod),impl)
      equation 
        (cache,m_1) = updateMod(cache,env, pre, m, impl) "Static.elab_subscripts (env,ss) => (ss\',true) &" ;
      then
        (cache,{Types.IDXMOD(idxmod,m_1)});
  end matchcontinue;
end updateSubmod;

public function elabUntypedMod "function elabUntypedMod
 
  This function is used to convert SCode.Mod into Mod, without 
  adding correct type information. Instead, a undefined type will be 
  given to the modification. This is used when modifications of e.g. 
  elements in base classes used. For instance,
  model test extends A(x=y); end test; // both x and y are defined in A
  The modifier x=y must be merged with outer modifiers, thus it needs 
  to be converted to Mod.
  Notice that the correct type information must be updated later on.
"
  input SCode.Mod inMod;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  output Types.Mod outMod;
algorithm 
  outMod:=
  matchcontinue (inMod,inEnv,inPrefix)
    local
      list<Types.SubMod> subs_1;
      SCode.Mod m,mod;
      Boolean finalPrefix;
      Absyn.Each each_;
      list<SCode.SubMod> subs;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      Absyn.Exp e;
      list<tuple<SCode.Element, Types.Mod>> elist_1;
      list<SCode.Element> elist;
      Ident s;
    case (SCode.NOMOD(),_,_) then Types.NOMOD(); 
    case ((m as SCode.MOD(finalPrefix = finalPrefix,eachPrefix = each_,subModLst = subs,absynExpOption = NONE)),env,pre)
      equation 
        subs_1 = elabUntypedSubmods(subs, env, pre);
      then
        Types.MOD(finalPrefix,each_,subs_1,NONE);
    case ((m as SCode.MOD(finalPrefix = finalPrefix,eachPrefix = each_,subModLst = subs,absynExpOption = SOME((e,_)))),env,pre)
      equation 
        subs_1 = elabUntypedSubmods(subs, env, pre);
      then
        Types.MOD(finalPrefix,each_,subs_1,SOME(Types.UNTYPED(e)));
    case ((m as SCode.REDECL(finalPrefix = finalPrefix,elementLst = elist)),env,pre)
      equation 
        elist_1 = Inst.addNomod(elist);
      then
        Types.REDECL(finalPrefix,elist_1);
    case (mod,env,pre)
      equation 
        print("- elab_untyped_mod ");
        s = SCode.printModStr(mod);
        print(s);
        print(" failed\n");
      then
        fail();
  end matchcontinue;
end elabUntypedMod;

protected function elabSubmods 
"function: elabSubmods
  This function helps elabMod by recusively elaborating on a list of submodifications."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  input list<SCode.SubMod> inSCodeSubModLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output list<Types.SubMod> outTypesSubModLst;
algorithm 
  (outCache,outTypesSubModLst) :=
  matchcontinue (inCache,inEnv,inPrefix,inSCodeSubModLst,inBoolean)
    local
      Boolean impl;
      list<Types.SubMod> x_1,xs_1,res;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      SCode.SubMod x;
      list<SCode.SubMod> xs;
      Env.Cache cache;
    case (cache,_,_,{},impl) then (cache,{});  /* impl */ 
    case (cache,env,pre,(x :: xs),impl)
      equation 
        (cache,x_1) = elabSubmod(cache,env, pre, x, impl);
        (cache,xs_1) = elabSubmods(cache,env, pre, xs, impl);
        res = insertSubmods(x_1, xs_1, env, pre);
      then
        (cache,res);
  end matchcontinue;
end elabSubmods;

protected function elabSubmod 
"function: elabSubmod
  This function elaborates on a submodification, turning an
  SCode.SubMod into one or more Types.SubMod."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  input SCode.SubMod inSubMod;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output list<Types.SubMod> outTypesSubModLst;
algorithm 
  (outCache,outTypesSubModLst) :=
  matchcontinue (inCache,inEnv,inPrefix,inSubMod,inBoolean)
    local
      Types.Mod m_1;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      Ident i;
      SCode.Mod m;
      Boolean impl;
      list<Exp.Subscript> ss_1;
      list<Types.SubMod> smods;
      list<Absyn.Subscript> ss;
      Env.Cache cache;
    case (cache,env,pre,SCode.NAMEMOD(ident = i,A = m),impl) /* impl */ 
      equation 
        (cache,m_1) = elabMod(cache,env, pre, m, impl);
      then
        (cache,{Types.NAMEMOD(i,m_1)});
    case (cache,env,pre,SCode.IDXMOD(subscriptLst = ss,an = m),impl)
      equation 
        (cache,ss_1,Types.C_CONST()) = Static.elabSubscripts(cache,env, ss, impl);
        (cache,m_1) = elabMod(cache,env, pre, m, impl);
        smods = makeIdxmods(ss_1, m_1);
      then
        (cache,smods);
  end matchcontinue;
end elabSubmod;

protected function elabUntypedSubmods "function: elabUntypedSubmods
 
  This function helps `elab_untyped_mod\' by recusively elaborating on a list
  of submodifications.
"
  input list<SCode.SubMod> inSCodeSubModLst;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  output list<Types.SubMod> outTypesSubModLst;
algorithm 
  outTypesSubModLst:=
  matchcontinue (inSCodeSubModLst,inEnv,inPrefix)
    local
      list<Types.SubMod> x_1,xs_1,res;
      SCode.SubMod x;
      list<SCode.SubMod> xs;
      list<Env.Frame> env;
      Prefix.Prefix pre;
    case ({},_,_) then {}; 
    case ((x :: xs),env,pre)
      equation 
        x_1 = elabUntypedSubmod(x, env, pre);
        xs_1 = elabUntypedSubmods(xs, env, pre);
        res = insertSubmods(x_1, xs_1, env, pre);
      then
        res;
  end matchcontinue;
end elabUntypedSubmods;

protected function elabUntypedSubmod "function: elabUntypedSubmod
 
  This function elaborates on a submodification, turning an
  `SCode.SubMod\' into one or more `Types.SubMod\'s, wihtout type information.
"
  input SCode.SubMod inSubMod;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  output list<Types.SubMod> outTypesSubModLst;
algorithm 
  outTypesSubModLst:=
  matchcontinue (inSubMod,inEnv,inPrefix)
    local
      Types.Mod m_1;
      Ident i;
      SCode.Mod m;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      list<Absyn.Subscript> subcr;
    case (SCode.NAMEMOD(ident = i,A = m),env,pre)
      equation 
        m_1 = elabUntypedMod(m, env, pre);
      then
        {Types.NAMEMOD(i,m_1)};
    case (SCode.IDXMOD(subscriptLst = subcr,an = m),env,pre)
      equation 
        m_1 = elabUntypedMod(m, env, pre);
      then
        {Types.IDXMOD({-1},m_1)};
  end matchcontinue;
end elabUntypedSubmod;

protected function makeIdxmods "function: makeIdxmods
 
  From a list of list of integers, this function creates a list of
  sub-modifications of the `IDXMOD\' variety.
"
  input list<Exp.Subscript> inExpSubscriptLst;
  input Types.Mod inMod;
  output list<Types.SubMod> outTypesSubModLst;
algorithm 
  outTypesSubModLst:=
  matchcontinue (inExpSubscriptLst,inMod)
    local
      Integer x;
      Types.Mod m;
      list<Types.SubMod> mods,mods_1;
      list<Exp.Subscript> xs;
    case ({Exp.INDEX(exp = Exp.ICONST(integer = x))},m) then {Types.IDXMOD({x},m)}; 
    case ((Exp.INDEX(exp = Exp.ICONST(integer = x)) :: xs),m)
      equation 
        mods = makeIdxmods(xs, m);
        mods_1 = prefixIdxmods(mods, x);
      then
        mods_1;
    case ((Exp.SLICE(exp = Exp.ARRAY(array = x)) :: xs),m)
      local list<Exp.Exp> x;
      equation 
        Print.printBuf("= expand_slice\n");
        mods = expandSlice(x, xs, 1, m);
      then
        mods;
    case ((Exp.WHOLEDIM() :: xs),m)
      equation 
        print("# Sorry, [:] slices are not handled in modifications\n");
      then
        fail();
    case(xs,m) equation
      print("maekIdxmods failed for mod:");print(printModStr(m));print("\n");
      print("subs =");print(Util.stringDelimitList(Util.listMap(xs,Exp.printSubscriptStr),","));
      print("\n");
    then fail();
      
  end matchcontinue;
end makeIdxmods;

protected function prefixIdxmods "function: prefixIdxmods
 
  This function adds a subscript to each `Types.IDXMOD\' in a list of
  submodifications.
"
  input list<Types.SubMod> inTypesSubModLst;
  input Integer inInteger;
  output list<Types.SubMod> outTypesSubModLst;
algorithm 
  outTypesSubModLst:=
  matchcontinue (inTypesSubModLst,inInteger)
    local
      list<Types.SubMod> mods_1,mods;
      list<Integer> l;
      Types.Mod m;
      Integer i;
    case ({},_) then {}; 
    case ((Types.IDXMOD(integerLst = l,mod = m) :: mods),i)
      equation 
        mods_1 = prefixIdxmods(mods, i);
      then
        (Types.IDXMOD((i :: l),m) :: mods_1);
  end matchcontinue;
end prefixIdxmods;

protected function expandSlice "function: expandSlice
 
  This function goes through an array slice modification and creates
  an singly indexed modification for each index in the slice.  For
  example, `x{2:3} = y\' is changed into `x{2} = y{1}\' and
  `x{3} = y{2}\'.
"
  input list<Exp.Exp> inExpExpLst;
  input list<Exp.Subscript> inExpSubscriptLst;
  input Integer inInteger;
  input Types.Mod inMod;
  output list<Types.SubMod> outTypesSubModLst;
algorithm 
  outTypesSubModLst:=
  matchcontinue (inExpExpLst,inExpSubscriptLst,inInteger,inMod)
    local
      Exp.Exp e_1,x,e,e_2;
      tuple<Types.TType, Option<Absyn.Path>> t_1,t;
      list<Types.SubMod> mods1,mods2,mods;
      Integer n_1,n;
      list<Exp.Exp> xs;
      list<Exp.Subscript> ss;
      Types.Mod m,mod;
      Boolean finalPrefix;
      Absyn.Each each_;
      Option<Values.Value> e_val;
      Types.Const const;
      Ident str;
    case ({},_,_,_) then {}; 
    case ({},_,_,_) then {}; 
    case ((x :: xs),ss,n,(m as Types.MOD(finalPrefix = finalPrefix,each_ = each_,subModLst = {},eqModOption = SOME(Types.TYPED(e,e_val,Types.PROP(t,const))))))
      equation 
        e_2 = Exp.ICONST(n);
        e_1 = Exp.simplify(Exp.ASUB(e,{e_2}));
        t_1 = Types.unliftArray(t);
        mods1 = makeIdxmods((Exp.INDEX(x) :: ss), 
          Types.MOD(finalPrefix,each_,{},
          SOME(Types.TYPED(e_1,e_val,Types.PROP(t_1,const)))));
        n_1 = n + 1;
        mods2 = expandSlice(xs, ss, n_1, m);
        mods = listAppend(mods1, mods2);
      then
        mods;
    case (_,_,_,mod)
      equation 
        str = printModStr(mod);
        Error.addMessage(Error.ILLEGAL_SLICE_MOD, {str});
      then
        fail();
  end matchcontinue;
end expandSlice;

protected function expandList "function: expandList
 
  This utility function takes a list of integer values and a list of
  list of integers, and for each integer in the first and each list
  in the second list creates a
  list with that integer as head and the second list as tail. All
  resulting lists are collected in a list and returned.
"
  input list<Values.Value> inValuesValueLst;
  input list<list<Integer>> inIntegerLstLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm 
  outIntegerLstLst:=
  matchcontinue (inValuesValueLst,inIntegerLstLst)
    local
      list<list<Integer>> l1,l2,l,yy,ys;
      list<Values.Value> xx,xs;
      Integer x;
      list<Integer> y;
    case ({},_) then {}; 
    case (_,{}) then {}; 
    case ((xx as (Values.INTEGER(integer = x) :: xs)),(yy as (y :: ys)))
      equation 
        l1 = expandList(xx, ys);
        l2 = expandList(xs, yy);
        l = listAppend(l1, l2);
      then
        ((x :: y) :: l);
  end matchcontinue;
end expandList;

protected function insertSubmods "function: insertSubmods
 
  This function repeatedly calls `insert_submod\' to incrementally
  insert several sub-modifications.
"
  input list<Types.SubMod> inTypesSubModLst1;
  input list<Types.SubMod> inTypesSubModLst2;
  input Env.Env inEnv3;
  input Prefix.Prefix inPrefix4;
  output list<Types.SubMod> outTypesSubModLst;
algorithm 
  outTypesSubModLst:=
  matchcontinue (inTypesSubModLst1,inTypesSubModLst2,inEnv3,inPrefix4)
    local
      list<Types.SubMod> x_1,xs_1,l,xs,y;
      Types.SubMod x;
      list<Env.Frame> env;
      Prefix.Prefix pre;
    case ({},_,_,_) then {}; 
    case ((x :: xs),y,env,pre)
      equation 
        x_1 = insertSubmod(x, y, env, pre);
        xs_1 = insertSubmods(xs, y, env, pre);
        l = listAppend(x_1, xs_1);
      then
        l;
  end matchcontinue;
end insertSubmods;

protected function insertSubmod "function: insertSubmod
 
  This function inserts a `SubMod\' into a list of unique `SubMod\'s,
  while keeping the uniqueness, merging the submod if necessary.
"
  input Types.SubMod inSubMod;
  input list<Types.SubMod> inTypesSubModLst;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  output list<Types.SubMod> outTypesSubModLst;
algorithm 
  outTypesSubModLst:=
  matchcontinue (inSubMod,inTypesSubModLst,inEnv,inPrefix)
    local
      Types.SubMod sub,sub1;
      Types.Mod m,m1,m2;
      Ident n1,n2;
      list<Types.SubMod> tail,sub2;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      list<Integer> i1,i2;
    case (sub,{},_,_) then {sub}; 
    case (Types.NAMEMOD(ident = n1,mod = m1),(Types.NAMEMOD(ident = n2,mod = m2) :: tail),env,pre)
      equation 
        equality(n1 = n2);
        m = merge(m1, m2, env, pre);
      then
        (Types.NAMEMOD(n1,m) :: tail);
    case (Types.IDXMOD(integerLst = i1,mod = m1),(Types.IDXMOD(integerLst = i2,mod = m2) :: tail),env,pre)
      equation 
        equality(i1 = i2);
        m = merge(m1, m2, env, pre);
      then
        (Types.IDXMOD(i1,m) :: tail);
    case (sub1,sub2,_,_) then (sub1 :: sub2); 
  end matchcontinue;
end insertSubmod;

public function lookupModificationP "
  - Lookup

  function: lookupModificationP
  
  This function extracts a modification from inside another
  modification, using a name to look up submodifications.
"
  input Types.Mod inMod;
  input Absyn.Path inPath;
  output Types.Mod outMod;
algorithm 
  outMod:=
  matchcontinue (inMod,inPath)
    local
      Types.Mod mod,m,mod_1;
      Ident n;
      Absyn.Path p;
    case (m,Absyn.IDENT(name = n))
      equation 
        mod = lookupCompModification(m, n);
      then
        mod;
    case (m,Absyn.FULLYQUALIFIED(p)) then lookupModificationP(m,p);
    case (m,Absyn.QUALIFIED(name = n,path = p))
      equation 
        mod = lookupCompModification(m, n);
        mod_1 = lookupModificationP(mod, p);
      then
        mod_1;
    case (_,_)
      equation 
        Print.printBuf("- lookup_modification_p failed\n");
      then
        fail();
  end matchcontinue;
end lookupModificationP;

public function lookupCompModification "function: lookupCompModification
 
  This function is used to look up an identifier in a modification.
"
  input Types.Mod inMod;
  input Absyn.Ident inIdent;
  output Types.Mod outMod;
algorithm 
  outMod:=
  matchcontinue (inMod,inIdent)
    local
      Types.Mod mod,mod1,mod2;
      list<Types.SubMod> subs;
      Ident n,i;
      Option<Types.EqMod> eqMod;
      Absyn.Each e;
      Boolean f;
    case (Types.NOMOD(),_) then Types.NOMOD(); 
    case (Types.REDECL(finalPrefix = _),_) then Types.NOMOD(); 
    case (Types.MOD(finalPrefix=f,each_=e,subModLst = subs,eqModOption=eqMod),n)
      equation 
        //print(" looking for mod on: " +& n +& "\n"); 
        mod1 = lookupCompModification2(subs, n);        
        mod2 = lookupComplexCompModification(eqMod,n,f,e);
        //print(" found inside compmod: " +& printModStr(mod1) +& "\n And in complexcomp: " +& printModStr(mod2) +& "\n");
        mod = checkDuplicateModifications(mod1,mod2);
      then
        mod;
  end matchcontinue;
end lookupCompModification;

protected function lookupComplexCompModification "Lookups a component modification from a complex constructor 
(e.g. record constructor) by name."
  input option<Types.EqMod> eqMod;
  input Absyn.Ident n;
  input Boolean finalPrefix;
  input Absyn.Each each_;
  output Types.Mod outMod;
algorithm
  outMod := matchcontinue(eqMod,n,finalPrefix,each_)
  local list<Values.Value> values;
    list<String> names;
    list<Types.Var> varLst;
    Types.Mod mod;
    Exp.Exp e;

    case(NONE,_,_,_) then Types.NOMOD();

    case(SOME(Types.TYPED(e,SOME(Values.RECORD(_,values,names)),Types.PROP((Types.T_COMPLEX(complexVarLst = varLst),_),_))),n,finalPrefix,each_) equation
      mod = lookupComplexCompModification2(values,names,varLst,n,finalPrefix,each_);
    then mod;

    case(_,_,_,_) then Types.NOMOD();
  end matchcontinue;    
end lookupComplexCompModification;

protected function lookupComplexCompModification2 "Help function to lookupComplexCompModification"
  input list<Values.Value> values;
  input list<Ident> names;
  input list<Types.Var> vars;
  input String name;
  input Boolean finalPrefix;
  input Absyn.Each each_;
  output Types.Mod mod;
algorithm
  mod := matchcontinue(values,names,vars,name,finalPrefix,each_)
    local Types.Type tp;
      Values.Value v; String name1,name2;
      Exp.Exp e;
    case(v::_,name1::_,Types.VAR(name=name2,type_=tp)::_,name,finalPrefix,each_) equation
      true = (name1 ==& name2);
      true = (name2 ==& name);
      e = Static.valueExp(v);
    then Types.MOD(finalPrefix,each_,{},SOME(Types.TYPED(e,SOME(v),Types.PROP(tp,Types.C_CONST()))));
    case(_::values,_::names,_::vars,name,finalPrefix,each_) equation
      mod = lookupComplexCompModification2(values,names,vars,name,finalPrefix,each_);
    then mod;
  end matchcontinue;
end lookupComplexCompModification2;

protected function checkDuplicateModifications "Checks if two modifiers are present, and in that case
print error of duplicate modifications, if not, the one modification having a value is returned"
input Types.Mod mod1;
input Types.Mod mod2;
output Types.Mod outMod;
algorithm
  outMod := matchcontinue(mod1,mod2)
  local String s1,s2,s;
    
    case(Types.NOMOD(),mod2) then mod2;
    case(mod1,Types.NOMOD()) then mod1;
    case(mod1,mod2) equation
      s1 = printModStr(mod1);
      s2 = printModStr(mod2);
      s = s1 +& " and " +& s2;
      Error.addMessage(Error.DUPLICATE_MODIFICATIONS,{s});
    then fail();
  end matchcontinue;
end checkDuplicateModifications;


protected function lookupCompModification2 "function: lookupCompModification2
  
  This function is just a helper to `lookup_comp_modification\'.
"
  input list<Types.SubMod> inTypesSubModLst;
  input Absyn.Ident inIdent;
  output Types.Mod outMod;
algorithm 
  outMod:=
  matchcontinue (inTypesSubModLst,inIdent)
    local
      Ident n,m;
      Types.Mod mod;
      Types.SubMod x;
      list<Types.SubMod> xs;
    case ({},_) then Types.NOMOD(); 
    case ((Types.NAMEMOD(ident = n,mod = mod) :: _),m)
      equation 
        equality(n = m);        
      then
        mod;
    case ((x :: xs),n)
      equation 
        mod = lookupCompModification2(xs, n);
      then
        mod;
    case (_,_)
      equation 
        Print.printBuf("- lookup_comp_modification2 failed\n");
      then
        fail();
  end matchcontinue;
end lookupCompModification2;

public function lookupIdxModification "function: lookupIdxModification
 
  This function extracts modifications to an array element, using an
  integer to index the modification.
"
  input Types.Mod inMod;
  input Integer inInteger;
  output Types.Mod outMod;
algorithm 
  outMod:=
  matchcontinue (inMod,inInteger)
    local
      Types.Mod mod_1,mod_2,mod_3,inmod,mod;
      list<Types.SubMod> subs_1,subs;
      Option<Types.EqMod> eq_1,eq;
      Boolean f;
      Absyn.Each each_;
      Integer idx;
      Ident str,s;
    case (Types.NOMOD(),_) then Types.NOMOD(); 
    case (Types.REDECL(finalPrefix = _),_) then Types.NOMOD(); 
    case ((inmod as Types.MOD(finalPrefix = f,each_ = each_,subModLst = subs,eqModOption = eq)),idx)
      equation 
        (mod_1,subs_1) = lookupIdxModification2(subs, NONE, idx);
        mod_2 = merge(Types.MOD(f,each_,subs_1,NONE), mod_1, {}, Prefix.NOPRE());
        eq_1 = indexEqmod(eq, {idx});
        mod_3 = merge(mod_2, Types.MOD(f,each_,{},eq_1), {}, Prefix.NOPRE()) "	& print \"lookup_idx_modificaton input :\" &
	print_mod_str inmod => s & print s & print \"\\n\" 
	& print \"lookup_idx_modificaton returns :\" &
	print_mod_str mod\'\'\' => s & print s & print \"\\n\"" ;
      then
        mod_3;
    case (mod,idx)
      equation 
        Debug.fprint("failtrace", "-lookup_idx_modification(");
        str = printModStr(mod);
        Debug.fprint("failtrace", str);
        Debug.fprint("failtrace", ", ");
        s = intString(idx);
        Debug.fprint("failtrace", s);
        Debug.fprint("failtrace", ") failed\n");
      then
        fail();
  end matchcontinue;
end lookupIdxModification;

protected function lookupIdxModification2 "function: lookupIdxModification2
 
  This function does part of the job for `lookup_idx_modification\'.
"
  input list<Types.SubMod> inTypesSubModLst;
  input Option<Types.EqMod> inTypesEqModOption;
  input Integer inInteger;
  output Types.Mod outMod;
  output list<Types.SubMod> outTypesSubModLst;
algorithm 
  (outMod,outTypesSubModLst):=
  matchcontinue (inTypesSubModLst,inTypesEqModOption,inInteger)
    local
      list<Types.SubMod> subs_1,subs,xs_1;
      Integer x,y,idx;
      Types.Mod mod,mod_1,nmod_1,nmod;
      Option<Types.EqMod> eq;
      list<Integer> xs;
      Ident name;
    case ({},_,_) then (Types.NOMOD(),{}); 
    case ((Types.IDXMOD(integerLst = {x},mod = mod) :: subs),eq,y) /* FIXME: Redeclaration */ 
      equation 
        equality(x = y);
        (Types.NOMOD(),subs_1) = lookupIdxModification2(subs, eq, y);
      then
        (mod,subs_1);
    case ((Types.IDXMOD(integerLst = (x :: xs),mod = mod) :: subs),eq,y)
      equation 
        equality(x = y);
        (mod_1,subs_1) = lookupIdxModification2(subs, eq, y);
      then
        (mod_1,(Types.IDXMOD(xs,mod) :: subs_1));
    case ((Types.IDXMOD(integerLst = (x :: xs),mod = mod) :: subs),eq,y)
      equation 
        failure(equality(x = y));
        (mod_1,subs_1) = lookupIdxModification2(subs, eq, y);
      then
        (mod_1,subs_1);
    case ((Types.NAMEMOD(ident = name,mod = nmod) :: subs),eq,y)
      equation 
        nmod_1 = lookupIdxModification3(nmod, y);
        (mod_1,subs_1) = lookupIdxModification2(subs, eq, y);
      then
        (mod_1,(Types.NAMEMOD(name,nmod_1) :: subs_1));
    case ((x :: xs),eq,idx)
      local
        Types.SubMod x;
        list<Types.SubMod> xs;
      equation 
        (mod,xs_1) = lookupIdxModification2(xs, eq, idx);
      then
        (mod,(x :: xs_1));
    case (_,_,_)
      equation 
       Debug.fprint("failtrace", "-lookupIdxModification2 failed\n");
      then
        fail();
  end matchcontinue;
end lookupIdxModification2;

protected function lookupIdxModification3 "function: lookupIdxModification3
 
  Helper function to lookup_idx_modification2.
  when looking up index of a named mod, e.g. y={1,2,3}, it should
  subscript the expression {1,2,3} to corresponding index.
"
  input Types.Mod inMod;
  input Integer inInteger;
  output Types.Mod outMod;
algorithm 
  outMod:=
  matchcontinue (inMod,inInteger)
    local
      Option<Types.EqMod> eq_1,eq;
      Boolean f;
      list<Types.SubMod> subs;
      Integer idx;
    case (Types.NOMOD(),_) then Types.NOMOD();  /* indx */ 
    case (Types.REDECL(finalPrefix = _),_) then Types.NOMOD(); 
    case (Types.MOD(finalPrefix = f,each_ = Absyn.NON_EACH(),subModLst = subs,eqModOption = eq),idx)
      equation 
        eq_1 = indexEqmod(eq, {idx});
      then
        Types.MOD(f,Absyn.NON_EACH(),subs,eq_1);
    case (Types.MOD(finalPrefix = f,each_ = Absyn.EACH(),subModLst = subs,eqModOption = eq),idx) then Types.MOD(f,Absyn.EACH(),subs,eq); 
    case (_,_) equation
      Debug.fprint("failtrace", "-lookupIdxModification3 failed\n");
    then fail();   
  end matchcontinue;
end lookupIdxModification3;

protected function indexEqmod "function: indexEqmod
 
  If there is an equation modification, this function can subscript
  it using the provided indexing expressions.  This is used when a
  modification equates an array variable with an array expression.
  This expression will be expanded to produce one equation
  expression per array component.
"
  input Option<Types.EqMod> inTypesEqModOption;
  input list<Integer> inIntegerLst;
  output Option<Types.EqMod> outTypesEqModOption;
algorithm 
  outTypesEqModOption:=
  matchcontinue (inTypesEqModOption,inIntegerLst)
    local
      Option<Types.EqMod> e;
      tuple<Types.TType, Option<Absyn.Path>> t_1,t;
      Exp.Exp exp,exp2;
      Values.Value e_val_1,e_val;
      Types.Const c;
      Integer x;
      list<Integer> xs;
    case (NONE,_) then NONE; 
    case (e,{}) then e; 
      /* Subscripting empty array gives no value. This is needed in e.g. fill(1.0,0,2) */
    case (SOME(Types.TYPED(_,SOME(Values.ARRAY({})),_)),xs) then NONE;      
      
      /* For modifiers with value, retrieve nth element*/
    case (SOME(Types.TYPED(e,SOME(e_val),Types.PROP(t,c))),(x :: xs))
      equation 
        t_1 = Types.unliftArray(t);
        exp2 = Exp.ICONST(x);
        exp = Exp.simplify(Exp.ASUB(e,{exp2}));
        e_val_1 = Values.nthArrayelt(e_val, x);
        e = indexEqmod(SOME(Types.TYPED(exp,SOME(e_val_1),Types.PROP(t_1,c))), xs);
      then
        e;
        
			/* For modifiers without value, apply subscript operaor */
    case (SOME(Types.TYPED(e,NONE,Types.PROP(t,c))),(x :: xs))
      equation 
        t_1 = Types.unliftArray(t);
        exp2 = Exp.ICONST(x);
        exp = Exp.simplify(Exp.ASUB(e,{exp2}));
        e = indexEqmod(SOME(Types.TYPED(exp,NONE,Types.PROP(t_1,c))), xs);
      then
        e;        
    case (_,_) equation
      Debug.fprint("failtrace", "-indexEqmod failed\n");
    then fail();
  end matchcontinue;
end indexEqmod;

public function merge "
A mid step for merging two modifiers. 
It validates that the merging is allowed(considering final modifier).
"
  input Types.Mod inMod1;
  input Types.Mod inMod2;
  input Env.Env inEnv3;
  input Prefix.Prefix inPrefix4;
  output Types.Mod outMod;
algorithm outMod:= matchcontinue (inMod1,inMod2,inEnv3,inPrefix4)
  local 
    Types.Mod m;
    case (Types.NOMOD(),Types.NOMOD(),_,_) then Types.NOMOD(); 
    case (Types.NOMOD(),m,_,_) then m; 

    case(inMod1,inMod2,inEnv3,inPrefix4)
      equation
        true = merge2(inMod2);
      then doMerge(inMod1,inMod2,inEnv3,inPrefix4);        
    case(inMod1,inMod2,inEnv3,inPrefix4)
      equation
        true = modSubsetOrEqual(inMod1,inMod2);
      then doMerge(inMod1,inMod2,inEnv3,inPrefix4);
    case(inMod1,inMod2,inEnv3,inPrefix4)
      local String s; Option<Absyn.Path> p;
      equation
        false = merge2(inMod2);
        false = modSubsetOrEqual(inMod1,inMod2);
        p = Env.getEnvPath(inEnv3);
        s = Absyn.optPathString(p);
        Error.addMessage(Error.FINAL_OVERRIDE, {s}); // having a string there incase we 
      then fail();
  end matchcontinue;  
end merge;

public function merge2 "
This function validates that the inner modifier is not final.
Helper function for merge
"
  input Types.Mod inMod1;
  output Boolean outMod;
algorithm outMod:= matchcontinue (inMod1)
  local 
    Types.Mod m;
    case (Types.REDECL(tplSCodeElementModLst = {(SCode.COMPONENT(finalPrefix=true),_)})) 
      then false;      
    case(Types.MOD(finalPrefix = true))
      then false;        
    case(_) then true;
  end matchcontinue;
end merge2;

protected function doMerge "
 
  - Merging
 
  The merge function merges to modifications to one. The first
  argument is the \"outer\" modification that should take precedence over
  the \"inner\" modifications.
 
 
  function: merge
  
  This function merges to modificiations into one.  The first
  modifications takes precedence over the second.
"
  input Types.Mod inMod1;
  input Types.Mod inMod2;
  input Env.Env inEnv3;
  input Prefix.Prefix inPrefix4;
  output Types.Mod outMod;
algorithm 
  outMod:=
  matchcontinue (inMod1,inMod2,inEnv3,inPrefix4)
    local
      Types.Mod m,m1_1,m2_1,m_2,mod,mods,outer_,inner_,mm1,mm2,mm3;
      Boolean f1,f,r,p,f2,finalPrefix;
      Absyn.InnerOuter io;
      Ident id1,id2;
      SCode.Attributes attr;
      Absyn.TypeSpec tp;
      SCode.Mod m1,m2;
      Option<Absyn.Path> bc,bc2;
      Option<Absyn.Comment> comment,comment2;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      list<tuple<SCode.Element, Types.Mod>> els;
      list<Types.SubMod> subs,subs1,subs2;
      Option<Types.EqMod> ass,ass1,ass2;
      Absyn.Each each_,each2;
      Option<Absyn.Exp> cond;
      Option<Absyn.Info> info;
    case (m,Types.NOMOD(),_,_) 
      then m; 
    /* redeclaring same component */
    case (Types.REDECL(finalPrefix = f1,tplSCodeElementModLst = 
          {(SCode.COMPONENT(component = id1,innerOuter=io,finalPrefix = f,replaceablePrefix = r,protectedPrefix = p,
                            attributes = attr,typeSpec = tp,modifications = m1,baseClassPath = bc,comment=comment,condition=cond,info=info),_)}),
          Types.REDECL(finalPrefix = f2,tplSCodeElementModLst = 
          {(SCode.COMPONENT(component = id2,modifications = m2,baseClassPath = bc2,comment = comment2),_)}),env,pre) 
      equation 
        equality(id1 = id2);
        m1_1 = elabUntypedMod(m2, env, pre);
        m2_1 = elabUntypedMod(m2, env, pre);
        m_2 = merge(m1_1, m2_1, env, pre);
      then
        Types.REDECL(f1,
          {
          (
          SCode.COMPONENT(id1,io,f,r,p,attr,tp,SCode.NOMOD(),bc,comment,cond,info),m_2)});
    case ((mod as Types.REDECL(finalPrefix = f1,tplSCodeElementModLst = (els as {(SCode.COMPONENT(component = id1),_)}))),(mods as Types.MOD(subModLst = subs)),env,pre) then mod;  /* luc_pop : this shoud return the first mod because it have been merged in merge_subs */ 

      /* TODO: Investigate what this is really good for (BZ 2008-03-04)*/
    case (Types.MOD(subModLst = subs),Types.REDECL(finalPrefix = f1,tplSCodeElementModLst = (els as {(SCode.COMPONENT(component = id1),_)})),env,pre) 
      then Types.MOD(false,Absyn.NON_EACH(),
          (Types.NAMEMOD(id1,Types.REDECL(f1,els)) :: subs),NONE);  
          /* luc_pop : this shoud return the first mod because it have been merged in merge_subs When modifiers are identical */ 
        
        /* When modifiers are identical */ 
    case (outer_,inner_,_,_) 
      equation 
        equality(outer_ = inner_);
      then
        outer_;
    
        /* Commented this becaus it gave false positives. 
        The problem is that merge is used repeatedly in the instantiation process even though 
        no real outer modfier is present. This causes this check to succeed even if no modifier is applied.
        */
    /*case (m1,(m as Types.MOD(finalPrefix = true)),_,_)
      local Types.Mod m1;
      equation 
				print("trying to modify final element with ");print(printModStr(m1));print("\n");
        Print.printBuf("# trying to modify final element\n"); 
      then
        fail();*/
    case (Types.MOD(finalPrefix = finalPrefix,each_ = each_,subModLst = subs1,eqModOption = ass1),Types.MOD(finalPrefix = _/*false*, see case above.*/,each_ = each2,subModLst = subs2,eqModOption = ass2),env,pre)
      equation 
        subs = mergeSubs(subs1, subs2, env, pre);
        ass = mergeEq(ass1, ass2);
      then
        Types.MOD(finalPrefix,each_,subs,ass);
        
        /* Case when we have a modifier on a redeclared class 
         * This is of current date BZ:2008-03-04 not completly working.
         * see testcase mofiles/Modification14.mo 
         */
    case (mm1 as Types.MOD(subModLst = subs), mm2 as Types.REDECL(finalPrefix = false,tplSCodeElementModLst = (els as {((elementOne as SCode.CLASSDEF(name = id1)),mm3)})),env,pre) 
      local SCode.Element elementOne;
      equation
        mm1 = merge(mm1,mm3,env,pre );
      then Types.REDECL(false,{(elementOne,mm1)});
    case (mm2 as Types.REDECL(finalPrefix = false,tplSCodeElementModLst = (els as {((elementOne as SCode.CLASSDEF(name = id1)),mm3)})),mm1 as Types.MOD(subModLst = subs),env,pre) 
      local SCode.Element elementOne;
      equation
        mm1 = merge(mm3,mm1,env,pre );
      then Types.REDECL(false,{(elementOne,mm1)});
  end matchcontinue;
end doMerge;

protected function mergeSubs "function: mergeSubs
  
  This function merges to list of `Types.SubMod\'s.
"
  input list<Types.SubMod> inTypesSubModLst1;
  input list<Types.SubMod> inTypesSubModLst2;
  input Env.Env inEnv3;
  input Prefix.Prefix inPrefix4;
  output list<Types.SubMod> outTypesSubModLst;
algorithm 
  outTypesSubModLst:=
  matchcontinue (inTypesSubModLst1,inTypesSubModLst2,inEnv3,inPrefix4)
    local
      list<Types.SubMod> s1,s1_1,ss,s2;
      Types.SubMod s_1,s;
      list<Env.Frame> env;
      Prefix.Prefix pre;
    case (s1,{},_,_) then s1; 
    case (s1,(s :: s2),env,pre)
      equation 
        (s1_1,s_1) = mergeSubs2(s1, s, env, pre);
        ss = mergeSubs(s1_1, s2, env, pre);
      then
        (s_1 :: ss);
  end matchcontinue;
end mergeSubs;

protected function mergeSubs2 "function: mergeSubs2
  
  This function helps in the merging of two lists of `Types.SubMod\'s.  It
  compares one `Types.SubMod\' against a list of other `Types.SubMod\'s, and if
  there is one with the same name,  it is kept and the one `Types.SubMod\'
  given in the second argument is discarded.
"
  input list<Types.SubMod> inTypesSubModLst;
  input Types.SubMod inSubMod;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  output list<Types.SubMod> outTypesSubModLst;
  output Types.SubMod outSubMod;
algorithm 
  (outTypesSubModLst,outSubMod):=
  matchcontinue (inTypesSubModLst,inSubMod,inEnv,inPrefix)
    local
      Types.SubMod m,s,s1,s2;
      Types.Mod m1,m2;
      Ident n1,n2;
      list<Types.SubMod> ss,ss_1;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      list<Integer> i1,i2;
    case ({},m,_,_) then ({},m); 
      /* Modifications in the list take precedence */
    case ((Types.NAMEMOD(ident = n1,mod = m1) :: ss),Types.NAMEMOD(ident = n2,mod = m2),env,pre)  
      local Types.Mod m;
      equation 
        equality(n1 = n2);
        m = merge(m1, m2, env, pre);
      then
        (ss,Types.NAMEMOD(n1,m));
    case ((Types.IDXMOD(integerLst = i1,mod = m1) :: ss),Types.IDXMOD(integerLst = i2,mod = m2),env,pre)
      local Types.Mod m;
      equation 
        equality(i1 = i2);
        m = merge(m1, m2, env, pre);
      then
        (ss,Types.IDXMOD(i1,m));
    case ((s1 :: ss),s2,env,pre)
      equation 
        true = verifySubMerge(s1,s2);
        (ss_1,s) = mergeSubs2(ss, s2, env, pre);
      then
        ((s1 :: ss_1),s);
  end matchcontinue;
end mergeSubs2;

protected function verifySubMerge "
Function to verify that we did not fail the cases where we should merge subs
(helper function for mergeSubs2) 
"
  input Types.SubMod sub1;
  input Types.SubMod sub2;
  output Boolean b;
algorithm b := matchcontinue(sub1,sub2)
  local list<Integer> i1,i2; String n1,n2;
  case (Types.NAMEMOD(ident = n1),Types.NAMEMOD(ident = n2))  
    equation equality(n1 = n2);
    then false;
  case (Types.IDXMOD(integerLst = i1),Types.IDXMOD(integerLst = i2))
    equation equality(i1 = i2);
    then false;
  case(_,_) then true;
end matchcontinue;
end verifySubMerge;

protected function mergeEq "function: mergeEq
  
  The outer modification, given in the first argument, takes
  precedence over the inner modifications.
"
  input Option<Types.EqMod> inTypesEqModOption1;
  input Option<Types.EqMod> inTypesEqModOption2;
  output Option<Types.EqMod> outTypesEqModOption;
algorithm 
  outTypesEqModOption:=
  matchcontinue (inTypesEqModOption1,inTypesEqModOption2)
    local Option<Types.EqMod> e;
    case ((e as SOME(Types.TYPED(_,_,_))),_) then e;  /* Outer assignments take precedence */
    case ((e as SOME(Types.UNTYPED(_))),_) then e; 
    case (NONE,e) then e; 
  end matchcontinue;
end mergeEq;

public function modEquation "function: modEquation
  
  This function simply extracts the equation part of a modification.
"
  input Types.Mod inMod;
  output Option<Types.EqMod> outTypesEqModOption;
algorithm
  outTypesEqModOption:=
  matchcontinue (inMod)
    local Option<Types.EqMod> e;
    case Types.NOMOD() then NONE;
    case Types.REDECL(finalPrefix = _) then NONE;
    case Types.MOD(eqModOption = e) then e;
  end matchcontinue;
end modEquation;

protected function modSubsetOrEqual "
same as modEqual with the difference that we allow outer(input arg1: mod1)-modifier to be a subset of 
inner(input arg2: mod2)-modifier, IF the subset is cotained in mod2 and those subset matches are equal.
"
  input Types.Mod mod1;
  input Types.Mod mod2;
  output Boolean equal;
algorithm
  equal := matchcontinue(mod1,mod2)
    local Boolean b1,b2,b3,b4,f1,f2;
      Absyn.Each each1,each2;
      list<Types.SubMod> submods1,submods2;
      Option<Types.EqMod> eqmod1,eqmod2;
      
    case(Types.MOD(f1,each1,submods1,eqmod1),Types.MOD(f2,each2,submods2,eqmod2)) equation
      b1 = Util.boolEqual(f1,f2);
      b2 = Absyn.eachEqual(each1,each2);
      b3 = subModsEqual(submods1,submods2);
      b4 = eqModSubsetOrEqual(eqmod1,eqmod2);
      equal = Util.boolAndList({b1,b2,b3,b4});
      then equal;
    case(Types.REDECL(_,_),Types.REDECL(_,_)) then false;
    case(Types.NOMOD(),Types.NOMOD()) then true;
     
  end matchcontinue;
end modSubsetOrEqual;

protected function eqModSubsetOrEqual "
Returns true if two EqMods are equal or outer(input arg1) is NONE"
  input Option<Types.EqMod> eqMod1;
  input Option<Types.EqMod> eqMod2;
  output Boolean equal;
algorithm
  equal := matchcontinue(eqMod1,eqMod2)
  local Absyn.Exp aexp1,aexp2;
    Exp.Exp exp1,exp2; Types.EqMod teq;
    case(SOME(Types.TYPED(exp1,_,_)),SOME(Types.TYPED(exp2,_,_))) equation
      equal = Exp.expEqual(exp1,exp2);
    then equal;
    case(SOME(Types.TYPED(exp1,_,_)),SOME(Types.UNTYPED(aexp2))) equation
      aexp1 = Exp.unelabExp(exp1);
      equal = Absyn.expEqual(aexp1,aexp2);
    then equal;
    case(SOME(Types.UNTYPED(aexp1)),SOME(Types.TYPED(exp2,_,_))) equation
      aexp2 = Exp.unelabExp(exp2);
      equal = Absyn.expEqual(aexp1,aexp2);
    then equal;
    case(SOME(Types.UNTYPED(aexp1)),SOME(Types.UNTYPED(aexp2))) equation
      equal = Absyn.expEqual(aexp1,aexp2);
    then equal;
    case(NONE,NONE) then true;
    case(NONE,SOME(teq)) then true;
    case(_,_) then false;
  end matchcontinue;
end eqModSubsetOrEqual;

protected function subModsSubsetOrEqual "
Returns true if two submod lists are equal. Or all of the elements in subModLst1 have equalities in subModLst2. 
if subModLst2 then contain more elements is not a mather."
  input list<Types.SubMod> subModLst1;
  input list<Types.SubMod> subModLst2;
  output Boolean equal;
algorithm
  equal := matchcontinue(subModLst1,subModLst2)
  local	Types.Ident id1,id2;
    Types.Mod mod1,mod2;
    Boolean b1,b2,b3;
    list<Integer> indx1,indx2;
    list<Boolean> blst1;
    case ({},{}) then true;
    case (Types.NAMEMOD(id1,mod1)::subModLst1,Types.NAMEMOD(id2,mod2)::subModLst2) 
      equation
        equality(id1=id2);
        b1 = modEqual(mod1,mod2);
        b2 = subModsEqual(subModLst1,subModLst2);
        equal = Util.boolAndList({b1,b2});
      then equal;
    case (Types.IDXMOD(indx1,mod1)::subModLst1,Types.IDXMOD(indx2,mod2)::subModLst2) 
      equation
        blst1 = Util.listThreadMap(indx1,indx2,intEq);
        b2 = modSubsetOrEqual(mod1,mod2);
        b3 = subModsSubsetOrEqual(subModLst1,subModLst2);
        equal = Util.boolAndList(b2::b3::blst1);
      then equal;
    case(subModLst1,Types.IDXMOD(_,_)::subModLst2) 
      equation        
        b3 = subModsSubsetOrEqual(subModLst1,subModLst2);        
      then b3;          
    case(_,_) then false;
  end matchcontinue;
end subModsSubsetOrEqual;

public function modEqual ""
  input Types.Mod mod1;
  input Types.Mod mod2;
  output Boolean equal;
algorithm
  equal := matchcontinue(mod1,mod2)
    local Boolean b1,b2,b3,b4,f1,f2;
      Absyn.Each each1,each2;
      list<Types.SubMod> submods1,submods2;
      Option<Types.EqMod> eqmod1,eqmod2;
      
    case(Types.MOD(f1,each1,submods1,eqmod1),Types.MOD(f2,each2,submods2,eqmod2)) equation
      b1 = Util.boolEqual(f1,f2);
      b2 = Absyn.eachEqual(each1,each2);
      b3 = subModsEqual(submods1,submods2);
      b4 = eqModEqual(eqmod1,eqmod2);
      equal = Util.boolAndList({b1,b2,b3,b4});
      then equal;
    case(Types.REDECL(_,_),Types.REDECL(_,_)) then false;
    case(Types.NOMOD(),Types.NOMOD()) then true;
     
  end matchcontinue;
end modEqual;

protected function subModsEqual "Returns true if two submod lists are equal."
  input list<Types.SubMod> subModLst1;
  input list<Types.SubMod> subModLst2;
  output Boolean equal;
algorithm
  equal := matchcontinue(subModLst1,subModLst2)
  local	Types.Ident id1,id2;
    Types.Mod mod1,mod2;
    Boolean b1,b2,b3;
    list<Integer> indx1,indx2;
    list<Boolean> blst1;
    case ({},_) then true;
    case (Types.NAMEMOD(id1,mod1)::subModLst1,Types.NAMEMOD(id2,mod2)::subModLst2) 
      equation
        equality(id1=id2);
        b1 = modEqual(mod1,mod2);
        b2 = subModsEqual(subModLst1,subModLst2);
        equal = Util.boolAndList({b1,b2});
      then equal;
        case (Types.IDXMOD(indx1,mod1)::subModLst1,Types.IDXMOD(indx2,mod2)::subModLst2) 
      equation
        blst1 = Util.listThreadMap(indx1,indx2,intEq);
        b2 = modEqual(mod1,mod2);
        b3 = subModsEqual(subModLst1,subModLst2);
        equal = Util.boolAndList(b2::b3::blst1);
      then equal;
        case(_,_) then false;
  end matchcontinue;
end subModsEqual;
          
protected function eqModEqual "Returns true if two EqMods are equal"
  input Option<Types.EqMod> eqMod1;
  input Option<Types.EqMod> eqMod2;
  output Boolean equal;
algorithm
  equal := matchcontinue(eqMod1,eqMod2)
  local Absyn.Exp aexp1,aexp2;
    Exp.Exp exp1,exp2;
    case(SOME(Types.TYPED(exp1,_,_)),SOME(Types.TYPED(exp2,_,_))) equation
      equal = Exp.expEqual(exp1,exp2);
    then equal;
    case(SOME(Types.TYPED(exp1,_,_)),SOME(Types.UNTYPED(aexp2))) equation
      aexp1 = Exp.unelabExp(exp1);
      equal = Absyn.expEqual(aexp1,aexp2);
    then equal;
    case(SOME(Types.UNTYPED(aexp1)),SOME(Types.TYPED(exp2,_,_))) equation
      aexp2 = Exp.unelabExp(exp2);
      equal = Absyn.expEqual(aexp1,aexp2);
    then equal;
    case(SOME(Types.UNTYPED(aexp1)),SOME(Types.UNTYPED(aexp2))) equation
      equal = Absyn.expEqual(aexp1,aexp2);
    then equal;
    case(NONE,NONE) then true;
    case(_,_) then false;
  end matchcontinue;
end eqModEqual;

public function printModStr "- Printing
  !ignorecode
  function: print_mod
 
  This function prints a modification. It uses a few other function
  to do its stuff.
 
  The functions are excluded from the report for brevity.
"
  input Types.Mod inMod;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inMod)
    local
      list<SCode.Element> elist_1;
      Ident finalPrefixstr,str,res,s1_1,s2;
      list<Ident> str_lst,s1;
      Boolean finalPrefix;
      list<tuple<SCode.Element, Types.Mod>> elist;
      Absyn.Each each_;
      list<Types.SubMod> subs;
      Option<Types.EqMod> eq;
    case (Types.NOMOD()) then "()"; 
    case Types.REDECL(finalPrefix = finalPrefix,tplSCodeElementModLst = elist)
      equation 
        elist_1 = Util.listMap(elist, Util.tuple21);
        finalPrefixstr = Util.if_(finalPrefix, "final", "");
        str_lst = Util.listMap(elist_1, SCode.printElementStr);
        str = Util.stringDelimitList(str_lst, ", ");
        res = Util.stringAppendList({"(redeclare(",finalPrefixstr,str,"))"});
      then
        res;
    case Types.MOD(finalPrefix = finalPrefix,each_ = each_,subModLst = subs,eqModOption = eq)
      equation 
        finalPrefixstr = Util.if_(finalPrefix, "final", "");
        s1 = printSubs1Str(subs);
        s1_1 = Util.stringDelimitList(s1, ",");
        s1_1 = Util.if_(listLength(subs)>=1," {" +& s1_1 +& "} ",s1_1);
        s2 = printEqmodStr(eq);
        str = Util.stringAppendList({finalPrefixstr,s1_1,s2});
      then
        str;
  end matchcontinue;
end printModStr;

public function printMod "function: printMod
 
  Print a modifier on the Print buffer.
"
  input Types.Mod m;
  Ident str;
algorithm 
  str := printModStr(m);
  Print.printBuf(str);
end printMod;

public function printSubs1Str "function: printSubs1Str
 
  Helper function to print_mod_str
"
  input list<Types.SubMod> inTypesSubModLst;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inTypesSubModLst)
    local
      Ident s1;
      list<Ident> res;
      Types.SubMod x;
      list<Types.SubMod> xs;
    case {} then {}; 
    case (x :: xs)
      equation 
        s1 = printSubStr(x);
        res = printSubs1Str(xs);
      then
        (s1 :: res);
  end matchcontinue;
end printSubs1Str;

protected function printSubStr "function: printSubStr
 
  Helper function to print_subs1_str
"
  input Types.SubMod inSubMod;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inSubMod)
    local
      Ident mod_str,res,n,str;
      Types.Mod mod;
      list<Integer> ss;
    case Types.NAMEMOD(ident = n,mod = mod)
      equation 
        mod_str = printModStr(mod);
        res = stringAppend(n, mod_str);
      then
        res;
    case Types.IDXMOD(integerLst = ss,mod = mod)
      equation 
        str = printSubscriptsStr(ss);
        mod_str = printModStr(mod);
        res = stringAppend(str, mod_str);
      then
        res;
  end matchcontinue;
end printSubStr;

protected function printSubscriptsStr "function: printSubscriptsStr
 
  Helper function to print_sub_str
"
  input list<Integer> inIntegerLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inIntegerLst)
    local
      Ident s,str,res;
      Integer x;
      list<Integer> xs;
    case ({}) then "[]"; 
    case (x :: xs)
      equation 
        Print.printBuf("[");
        s = intString(x);
        str = printSubscripts2Str(xs);
        res = Util.stringAppendList({"[",s,str,"]"});
      then
        res;
  end matchcontinue;
end printSubscriptsStr;

protected function printSubscripts2Str "function: printSubscripts2Str
 
  Helper function to print_subscripts_str
"
  input list<Integer> inIntegerLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inIntegerLst)
    local
      Ident s,str,res;
      Integer x;
      list<Integer> xs;
    case ({}) then ""; 
    case (x :: xs)
      equation 
        Print.printBuf(",");
        s = intString(x);
        str = printSubscripts2Str(xs);
        res = Util.stringAppendList({",",s,str});
      then
        res;
  end matchcontinue;
end printSubscripts2Str;

protected function printEqmodStr "function: printEqmodStr
  
  Helper function to print_mod_str
"
  input Option<Types.EqMod> inTypesEqModOption;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inTypesEqModOption)
    local
      Ident str,str2,e_val_str,res;
      Exp.Exp e;
      Values.Value e_val;
      Types.Properties prop;
    case NONE then ""; 
    case SOME(Types.TYPED(e,SOME(e_val),prop))
      equation 
        str = Exp.printExpStr(e);
        str2 = Types.printPropStr(prop);
        e_val_str = Values.valString(e_val);
        res = Util.stringAppendList({" = (typed)",str,str2,", E_VALUE:",e_val_str});
      then
        res;
    case SOME(Types.TYPED(e,NONE,prop))
      equation 
        str = Exp.printExpStr(e);
        str2 = Types.printPropStr(prop);
        res = Util.stringAppendList({" = (typed)",str,str2});
      then
        res;
    case SOME(Types.UNTYPED(e))
      local Absyn.Exp e;
      equation 
        str = Dump.printExpStr(e);
        res = stringAppend(" =(untyped) ", str);
      then
        res;
  end matchcontinue;
end printEqmodStr;
end Mod;

