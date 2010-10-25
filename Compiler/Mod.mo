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

package Mod
" file:        Mod.mo
  package:     Mod
  description: Modification handling

  RCS: $Id$

  Modifications are simply the same kind of modifications used in
  the Absyn module.

  This type is very similar to SCode.Mod.
  The main difference is that it uses DAE.Exp for the expressions.
  Expressions stored here are prefixed and typechecked.

  The datatype itself is moved to the Types module, in Types.mo, to prevent circular dependencies."


public import Absyn;
public import DAE;
public import Env;
public import Prefix;
public import SCode;
public import RTOpts;
public import InnerOuter;

public 
type Ident = String;
type InstanceHierarchy = InnerOuter.InstHierarchy "an instance hierarchy";

protected import Ceval;
protected import ClassInf;
protected import Dump;
protected import Debug;
protected import Error;
protected import Exp;
protected import Inst;
protected import PrefixUtil;
protected import Print;
protected import Static;
protected import Types;
protected import Util;
protected import Values;
protected import ValuesUtil;
protected import System;

public function elabMod "
  This function elaborates on the expressions in a modification and
  turns them into global expressions.  This is done because the
  expressions in modifications must be elaborated on in the context
  they are provided in, and not the context they are used in."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input SCode.Mod inMod;
  input Boolean inBoolean;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Mod outMod;
algorithm
  (outCache,outMod) := matchcontinue (inCache,inEnv,inIH,inPrefix,inMod,inBoolean,info)
    local
      Boolean impl,finalPrefix;
      list<DAE.SubMod> subs_1;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      SCode.Mod m,mod;
      Absyn.Each each_;
      list<SCode.SubMod> subs;
      DAE.Exp e_1,e_2;
      DAE.Properties prop;
      Option<Values.Value> e_val;
      Absyn.Exp e,e1;
      list<tuple<SCode.Element, DAE.Mod>> elist_1;
      list<SCode.Element> elist;
      Ident str;
      Env.Cache cache;
      DAE.DAElist dae,dae1,dae2;
      InstanceHierarchy ih;

    // no modifications
    case (cache,_,_,_,SCode.NOMOD(),impl,_) then (cache,DAE.NOMOD());

    // no top binding
    case (cache,env,ih,pre,(m as SCode.MOD(finalPrefix = finalPrefix,eachPrefix = each_,subModLst = subs,absynExpOption = NONE())),impl,info)
      equation
        (cache,subs_1) = elabSubmods(cache, env, ih, pre, subs, impl,info);
      then
        (cache,DAE.MOD(finalPrefix,each_,subs_1,NONE()));

    // Only elaborate expressions with non-delayed type checking, see SCode.MOD.
    case (cache,env,ih,pre,(m as SCode.MOD(finalPrefix = finalPrefix,eachPrefix = each_,subModLst = subs,absynExpOption = SOME((e,false)))),impl,info)
      equation
        (cache,subs_1) = elabSubmods(cache, env, ih, pre, subs, impl,info);
        // print("Mod.elabMod: calling elabExp on mod exp: " +& Dump.printExpStr(e) +& " in env: " +& Env.printEnvPathStr(env) +& "\n");
        (cache,e_1,prop,_) = Static.elabExp(cache, env, e, impl,NONE(), true,pre,info);
        (cache, e_1, prop) = Ceval.cevalIfConstant(cache, env, e_1, prop, impl);
        (cache,e_val) = elabModValue(cache, env, e_1, prop);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre)
        "Bug: will cause elaboration of parameters without value to fail,
         But this can be ok, since a modifier is present, giving it a value from outer modifications.." ;
      then
        (cache,DAE.MOD(finalPrefix,each_,subs_1,SOME(DAE.TYPED(e_2,e_val,prop,SOME(e)))));

    // Delayed type checking
    case (cache,env,ih,pre,(m as SCode.MOD(finalPrefix = finalPrefix,eachPrefix = each_,subModLst = subs,absynExpOption = SOME((e,true)))),impl,info)
      equation
        // print("Mod.elabMod: delayed mod : " +& Dump.printExpStr(e) +& " in env: " +& Env.printEnvPathStr(env) +& "\n");
        (cache,subs_1) = elabSubmods(cache, env, ih, pre, subs, impl, info);
      then
        (cache,DAE.MOD(finalPrefix,each_,subs_1,SOME(DAE.UNTYPED(e))));

    // redeclarations
    case (cache,env,ih,pre,(m as SCode.REDECL(finalPrefix = finalPrefix,elementLst = elist)),impl,info)
      equation
        //elist_1 = Inst.addNomod(elist);
        (elist_1) = elabModRedeclareElements(cache,env,ih,pre,finalPrefix,elist,impl,info);
      then
        (cache,DAE.REDECL(finalPrefix,elist_1));

    // failure
    case (cache,env,ih,pre,mod,impl,info)
      equation
        /*Debug.fprint("failtrace", "#-- elab_mod ");
        str = SCode.printModStr(mod);
        Debug.fprint("failtrace", str);
        Debug.fprint("failtrace", " failed\n");
        print("elab mod failed, mod:");print(str);print("\n");
        print("env:");print(Env.printEnvStr(env));print("\n");*/
        /* elab mod can fail? */
      then
        fail();
  end matchcontinue;
end elabMod;

public function elabModForBasicType "
  Same as elabMod, but if a named Mod is not part of a basic type, fail instead."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input SCode.Mod inMod;
  input Boolean inBoolean;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Mod outMod;
algorithm
  (outCache,outMod) := matchcontinue (inCache,inEnv,inIH,inPrefix,inMod,inBoolean,info)
    case (inCache,inEnv,inIH,inPrefix,inMod,inBoolean,info)
      equation
        checkIfModsAreBasicTypeMods(inMod);
        (outCache,outMod) = elabMod(inCache,inEnv,inIH,inPrefix,inMod,inBoolean,info);
      then (outCache,outMod);
  end matchcontinue;
end elabModForBasicType;

protected function checkIfModsAreBasicTypeMods "
  Verifies that a list of submods only have named modifications that could be
  used for basic types."
  input SCode.Mod mod;
algorithm
  _ := matchcontinue mod
    local
      list<SCode.SubMod> subs;
    case SCode.NOMOD() then ();
    case SCode.MOD(subModLst = subs)
      equation
        checkIfSubmodsAreBasicTypeMods(subs);
      then ();
  end matchcontinue;
end checkIfModsAreBasicTypeMods;

protected function checkIfSubmodsAreBasicTypeMods "
  Verifies that a list of submods only have named modifications that could be
  used for basic types."
  input list<SCode.SubMod> subs;
algorithm
  _ := matchcontinue subs
    local
      SCode.Mod mod;
      String ident;
    case {} then ();
    case SCode.NAMEMOD(ident = ident)::subs
      equation
        true = ClassInf.isBasicTypeComponentName(ident);
        checkIfSubmodsAreBasicTypeMods(subs);
      then ();
    case SCode.IDXMOD(an = mod)::subs
      equation
        checkIfModsAreBasicTypeMods(mod);
        checkIfSubmodsAreBasicTypeMods(subs);
      then ();
  end matchcontinue;
end checkIfSubmodsAreBasicTypeMods;

protected function elabModRedeclareElements
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;  
  input Prefix.Prefix inPrefix;
  input Boolean finalPrefix;
  input list<SCode.Element> elts;
  input Boolean impl;
  input Absyn.Info info;
  output list<tuple<SCode.Element, DAE.Mod>> modElts "the elaborated modifiers";
algorithm
  modElts := matchcontinue(inCache,inEnv,inIH,inPrefix,finalPrefix,elts,impl,info)
    local
      Env.Cache cache; Env.Env env; Prefix.Prefix pre; Boolean f,fi,repl,p,enc,prot;
      Absyn.InnerOuter io;
      list<SCode.Element> elts;
      SCode.Ident cn,cn2,compname;
      Option<SCode.Comment> cmt;
      SCode.Restriction restr;
      Absyn.TypeSpec tp,tp1;
      DAE.Mod emod;
      SCode.Attributes attr;
      SCode.Mod mod;
      Option<Absyn.Exp> cond;
      Option<Absyn.Info> oinfo;
      Option<Absyn.ConstrainClass> cc;
      Option<SCode.Comment> cmt;
      Absyn.Info i;
      DAE.DAElist dae,dae1,dae2;
      InstanceHierarchy ih;

      /* the empty case */
      case(cache,env,_,pre,f,{},_,_) then ({});

         // Only derived classdefinitions supported in redeclares for now. TODO: What is allowed according to spec?
      case(cache,env,ih,pre,f,SCode.CLASSDEF(cn,fi,repl,SCode.CLASS(cn2,p,enc,restr,SCode.DERIVED(tp,mod,attr1,cmt),i),cc)::elts,impl,info)
        local
          Absyn.ElementAttributes attr1;
          Option<Absyn.ConstrainClass> cc;
        equation
         (cache,emod) = elabMod(cache,env,ih,pre,mod,impl,info);
         (modElts) = elabModRedeclareElements(cache,env,ih,pre,f,elts,impl,info);
         (cache,tp1) = elabModQualifyTypespec(cache,env,tp);
        then ((SCode.CLASSDEF(cn,fi,repl,SCode.CLASS(cn,p,enc,restr,SCode.DERIVED(tp1,mod,attr1,cmt),i),cc),emod)::modElts);

   // replaceable type E=enumeration(e1,...,en), E=enumeration(:)
      case(cache,env,ih,pre,f,SCode.CLASSDEF(cn,fi,repl,SCode.CLASS(cn2,p,enc,restr,SCode.ENUMERATION(enumLst,comment),i),cc)::elts,impl,info)
        local
          list<SCode.Enum> enumLst;
        Option<SCode.Comment> comment;
          Option<Absyn.ConstrainClass> cc;
        equation
         (modElts) = elabModRedeclareElements(cache,env,ih,pre,f,elts,impl,info);
        then ((SCode.CLASSDEF(cn,fi,repl,SCode.CLASS(cn,p,enc,restr,SCode.ENUMERATION(enumLst,comment),i),cc),DAE.NOMOD())::modElts);

        // redeclare of component declaration
      case(cache,env,ih,pre,f,SCode.COMPONENT(compname,io,fi,repl,prot,attr,tp,mod,cmt,cond,oinfo,cc)::elts,impl,info) equation
        info = Util.getOptionOrDefault(oinfo,info);
        (cache,emod) = elabMod(cache,env,ih,pre,mod,impl,info);
        (modElts) = elabModRedeclareElements(cache,env,ih,pre,f,elts,impl,info);
        (cache,tp1) = elabModQualifyTypespec(cache,env,tp);
      then ((SCode.COMPONENT(compname,io,fi,repl,prot,attr,tp1,mod,cmt,cond,SOME(info),cc),emod)::modElts);
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
  input DAE.Exp inExp;
  input DAE.Properties inProp;
  output Env.Cache outCache;
  output Option<Values.Value> outValuesValueOption;
algorithm
  (outCache,outValuesValueOption) :=
  matchcontinue (inCache,inEnv,inExp,inProp)
    case (_,_,_,_)
      local
        Values.Value v;
        Ceval.Msg msg;
        Env.Cache cache;
        DAE.Const c;
      equation
        c = Types.propAllConst(inProp);
        // Don't ceval variables.
        false = Types.constIsVariable(c);
        // Show error messages from ceval only if the expression is a constant.
        msg = Util.if_(Types.constIsConst(c), Ceval.MSG, Ceval.NO_MSG);
        (cache,v,_) = Ceval.ceval(inCache, inEnv, inExp, false,NONE(), NONE(), msg);
      then
        (cache,SOME(v));
    // Constant evaluation failed, return no value.
    case (_,_,_,_) then (inCache,NONE());
  end matchcontinue;
end elabModValue;

public function unelabMod
"function: unelabMod
  Transforms Mod back to SCode.Mod, loosing type information."
  input DAE.Mod inMod;
  output SCode.Mod outMod;
algorithm
  outMod:=
  matchcontinue (inMod)
    local
      list<SCode.SubMod> subs_1;
      DAE.Mod m,mod;
      Boolean finalPrefix;
      Absyn.Each each_;
      list<DAE.SubMod> subs;
      Absyn.Exp e,e_1,absynExp;
      Ident es,s;
      DAE.Properties p;
      list<SCode.Element> elist_1;
      list<tuple<SCode.Element, DAE.Mod>> elist;
      
    case (DAE.NOMOD()) then SCode.NOMOD();
    case ((m as DAE.MOD(finalPrefix = finalPrefix,each_ = each_,subModLst = subs,eqModOption = NONE())))
      equation
        subs_1 = unelabSubmods(subs);
      then
        SCode.MOD(finalPrefix,each_,subs_1,NONE());
    case ((m as DAE.MOD(finalPrefix = finalPrefix,each_ = each_,subModLst = subs,eqModOption = SOME(DAE.UNTYPED(e)))))
      equation
        subs_1 = unelabSubmods(subs);
      then
        SCode.MOD(finalPrefix,each_,subs_1,SOME((e,false))); // Default type checking non-delayed

    case ((m as DAE.MOD(finalPrefix = finalPrefix,each_ = each_,subModLst = subs,
                        eqModOption = SOME(DAE.TYPED(e,_,p,SOME(absynExp))))))
      local DAE.Exp e;
      equation
        //es = Exp.printExpStr(e);
        subs_1 = unelabSubmods(subs);
        e_1 = absynExp; //Exp.unelabExp(e);
      then
        SCode.MOD(finalPrefix,each_,subs_1,SOME((e_1,false))); // default typechecking non-delayed

    case ((m as DAE.MOD(finalPrefix = finalPrefix,each_ = each_,subModLst = subs,
                        eqModOption = SOME(DAE.TYPED(e,_,p,NONE())))))
      local DAE.Exp e;
      equation
        //es = Exp.printExpStr(e);
        subs_1 = unelabSubmods(subs);
        e_1 = Exp.unelabExp(e);
      then
        SCode.MOD(finalPrefix,each_,subs_1,SOME((e_1,false))); // default typechecking non-delayed

    case ((m as DAE.REDECL(finalPrefix = finalPrefix,tplSCodeElementModLst = elist)))
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
  input list<DAE.SubMod> inTypesSubModLst;
  output list<SCode.SubMod> outSCodeSubModLst;
algorithm
  outSCodeSubModLst:=
  matchcontinue (inTypesSubModLst)
    local
      list<SCode.SubMod> x_1,xs_1,res;
      DAE.SubMod x;
      list<DAE.SubMod> xs;
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
  input DAE.SubMod inSubMod;
  output list<SCode.SubMod> outSCodeSubModLst;
algorithm
  outSCodeSubModLst:=
  matchcontinue (inSubMod)
    local
      SCode.Mod m_1;
      Ident i;
      DAE.Mod m;
      list<Absyn.Subscript> ss_1;
      list<Integer> ss;
    case (DAE.NAMEMOD(ident = i,mod = m))
      equation
        m_1 = unelabMod(m);
      then
        {SCode.NAMEMOD(i,m_1)};
    case (DAE.IDXMOD(integerLst = ss,mod = m))
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
  This function updates an untyped modification to a typed one, by looking
  up the type of the modifier in the environment and update it."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input DAE.Mod inMod;
  input Boolean inBoolean;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Mod outMod;
algorithm
  (outCache,outMod) := matchcontinue (inCache,inEnv,inIH,inPrefix,inMod,inBoolean,info)
    local
      Boolean impl,f;
      DAE.Mod m;
      list<DAE.SubMod> subs_1,subs;
      DAE.Exp e_1,e_2;
      DAE.Properties prop,p;
      Option<Values.Value> e_val;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      Absyn.Each each_;
      Absyn.Exp e;
      Option<Absyn.Exp> eOpt;
      Env.Cache cache;
      DAE.DAElist dae,dae1,dae2;
      InstanceHierarchy ih;

    case (cache,_,_,_,DAE.NOMOD(),impl,info) then (cache,DAE.NOMOD());

    case (cache,_,_,_,(m as DAE.REDECL(finalPrefix = _)),impl,info) then (cache,m);

    case (cache,env,ih,pre,(m as DAE.MOD(finalPrefix = f,each_ = each_,subModLst = subs,eqModOption = SOME(DAE.UNTYPED(e)))),impl,info)
      equation
        (cache,subs_1) = updateSubmods(cache, env, ih, pre, subs, impl, info);
        (cache,e_1,prop,_) = Static.elabExp(cache, env, e, impl,NONE(), true,pre,info);
        (cache, e_1, prop) = Ceval.cevalIfConstant(cache, env, e_1, prop, impl);
        (cache,e_val) = elabModValue(cache,env,e_1,prop);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        Debug.fprint("updmod", "Updated mod: ");
        Debug.fprintln("updmod", Debug.fcallret1("updmod", printModStr, DAE.MOD(f,each_,subs_1,SOME(DAE.TYPED(e_2,NONE(),prop,SOME(e)))),""));
      then
        (cache,DAE.MOD(f,each_,subs_1,SOME(DAE.TYPED(e_2,e_val,prop,SOME(e)))));

    case (cache,env,ih,pre,DAE.MOD(finalPrefix = f,each_ = each_,subModLst = subs,eqModOption = SOME(DAE.TYPED(e_1,e_val,p,eOpt))),impl,info)
      equation
        (cache,subs_1) = updateSubmods(cache, env, ih, pre, subs, impl, info);
      then
        (cache,DAE.MOD(f,each_,subs_1,SOME(DAE.TYPED(e_1,e_val,p,eOpt))));

    case (cache,env,ih,pre,DAE.MOD(finalPrefix = f,each_ = each_,subModLst = subs,eqModOption = NONE()),impl,info)
      equation
        (cache,subs_1) = updateSubmods(cache, env, ih, pre, subs, impl, info);
      then
        (cache,DAE.MOD(f,each_,subs_1,NONE()));

    case (cache,env,ih,pre,m,impl,info)
      local String str;
      equation
                true = RTOpts.debugFlag("failtrace");
        str = printModStr(m);
        Debug.traceln("- Mod.updateMod failed mod: " +& str);
      then
        fail();
  end matchcontinue;
end updateMod;

protected function updateSubmods ""
    input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input list<DAE.SubMod> inTypesSubModLst;
  input Boolean inBoolean;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<DAE.SubMod> outTypesSubModLst;
algorithm
  (outCache,outTypesSubModLst):=
  matchcontinue (inCache,inEnv,inIH,inPrefix,inTypesSubModLst,inBoolean,info)
    local
      Boolean impl;
      list<DAE.SubMod> x_1,xs_1,res,xs;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      DAE.SubMod x;
      Env.Cache cache;
      DAE.DAElist dae,dae1,dae2;
      InstanceHierarchy ih;
      
    case (cache,_,ih,_,{},impl,info) then (cache,{});  /* impl */
    case (cache,env,ih,pre,(x :: xs),impl,info)
      equation
        (cache,x_1) = updateSubmod(cache, env, ih, pre, x, impl, info);
        (cache,xs_1) = updateSubmods(cache, env, ih, pre, xs, impl, info);
        res = insertSubmods(x_1, xs_1, env, pre);
      then
        (cache,res);
  end matchcontinue;
end updateSubmods;

protected function updateSubmod " "
  input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input DAE.SubMod inSubMod;
  input Boolean inBoolean;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<DAE.SubMod> outTypesSubModLst;
algorithm
  (outCache,outTypesSubModLst):=
  matchcontinue (inCache,inEnv,inIH,inPrefix,inSubMod,inBoolean,info)
    local
      DAE.Mod m_1,m;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      Ident i;
      Boolean impl;
      list<DAE.SubMod> smods;
      Env.Cache cache;
      list<Integer> idxmod;
      DAE.DAElist dae;
      InstanceHierarchy ih;
      
    case (cache,env,ih,pre,DAE.NAMEMOD(ident = i,mod = m),impl,info)
      equation
        (cache,m_1) = updateMod(cache, env, ih, pre, m, impl, info);
      then
        (cache,{DAE.NAMEMOD(i,m_1)});

    case (cache,env,ih,pre,DAE.IDXMOD(mod = m,integerLst=idxmod),impl,info)
      equation
        (cache,m_1) = updateMod(cache, env, ih, pre, m, impl, info) "Static.elab_subscripts (env,ss) => (ss\',true) &" ;
      then
        (cache,{DAE.IDXMOD(idxmod,m_1)});
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
  Notice that the correct type information must be updated later on."
  input SCode.Mod inMod;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue (inMod,inEnv,inPrefix)
    local
      list<DAE.SubMod> subs_1;
      SCode.Mod m,mod;
      Boolean finalPrefix;
      Absyn.Each each_;
      list<SCode.SubMod> subs;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      Absyn.Exp e;
      list<tuple<SCode.Element, DAE.Mod>> elist_1;
      list<SCode.Element> elist;
      Ident s;
    case (SCode.NOMOD(),_,_) then DAE.NOMOD();
    case ((m as SCode.MOD(finalPrefix = finalPrefix,eachPrefix = each_,subModLst = subs,absynExpOption = NONE())),env,pre)
      equation
        subs_1 = elabUntypedSubmods(subs, env, pre);
      then
        DAE.MOD(finalPrefix,each_,subs_1,NONE());
    case ((m as SCode.MOD(finalPrefix = finalPrefix,eachPrefix = each_,subModLst = subs,absynExpOption = SOME((e,_)))),env,pre)
      equation
        subs_1 = elabUntypedSubmods(subs, env, pre);
      then
        DAE.MOD(finalPrefix,each_,subs_1,SOME(DAE.UNTYPED(e)));
    case ((m as SCode.REDECL(finalPrefix = finalPrefix,elementLst = elist)),env,pre)
      equation
        elist_1 = Inst.addNomod(elist);
      then
        DAE.REDECL(finalPrefix,elist_1);
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
  input InstanceHierarchy inIH;  
  input Prefix.Prefix inPrefix;
  input list<SCode.SubMod> inSCodeSubModLst;
  input Boolean inBoolean;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<DAE.SubMod> outTypesSubModLst;
algorithm
  (outCache,outTypesSubModLst) :=
  matchcontinue (inCache,inEnv,inIH,inPrefix,inSCodeSubModLst,inBoolean,info)
    local
      Boolean impl;
      list<DAE.SubMod> x_1,xs_1,res;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      SCode.SubMod x;
      list<SCode.SubMod> xs;
      Env.Cache cache;
      DAE.DAElist dae,dae1,dae2;
      InstanceHierarchy ih;

    case (cache,_,_,_,{},impl,info) then (cache,{});  /* impl */
    case (cache,env,ih,pre,(x :: xs),impl,info)
      equation
        (cache,x_1) = elabSubmod(cache, env, ih, pre, x, impl,info);
        (cache,xs_1) = elabSubmods(cache, env, ih, pre, xs, impl,info);
        res = insertSubmods(x_1, xs_1, env, pre);
      then
        (cache,res);
  end matchcontinue;
end elabSubmods;

protected function elabSubmod
"function: elabSubmod
  This function elaborates on a submodification, turning an
  SCode.SubMod into one or more DAE.SubMod."
    input Env.Cache inCache;
  input Env.Env inEnv;
  input InstanceHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input SCode.SubMod inSubMod;
  input Boolean inBoolean;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<DAE.SubMod> outTypesSubModLst;
algorithm
  (outCache,outTypesSubModLst) :=
  matchcontinue (inCache,inEnv,inIH,inPrefix,inSubMod,inBoolean,info)
    local
      DAE.Mod m_1;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      Ident i;
      SCode.Mod m;
      Boolean impl;
      list<DAE.Subscript> ss_1;
      list<DAE.SubMod> smods;
      list<Absyn.Subscript> ss;
      Env.Cache cache;
      DAE.DAElist dae,dae1,dae2;
      InstanceHierarchy ih;
      
    case (cache,env,ih,pre,SCode.NAMEMOD(ident = i,A = m),impl,info)
      equation
        (cache,m_1) = elabMod(cache, env, ih, pre, m, impl, info);
      then
        (cache,{DAE.NAMEMOD(i,m_1)});
    case (cache,env,ih,pre,SCode.IDXMOD(subscriptLst = ss,an = m),impl,info)
      equation
        (cache,ss_1,DAE.C_CONST()) = Static.elabSubscripts(cache,env, ss, impl,pre,info);
        (cache,m_1) = elabMod(cache, env, ih, pre, m, impl, info);
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
  output list<DAE.SubMod> outTypesSubModLst;
algorithm
  outTypesSubModLst:=
  matchcontinue (inSCodeSubModLst,inEnv,inPrefix)
    local
      list<DAE.SubMod> x_1,xs_1,res;
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
  `SCode.SubMod\' into one or more `DAE.SubMod\'s, wihtout type information.
"
  input SCode.SubMod inSubMod;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  output list<DAE.SubMod> outTypesSubModLst;
algorithm
  outTypesSubModLst:=
  matchcontinue (inSubMod,inEnv,inPrefix)
    local
      DAE.Mod m_1;
      Ident i;
      SCode.Mod m;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      list<Absyn.Subscript> subcr;
    case (SCode.NAMEMOD(ident = i,A = m),env,pre)
      equation
        m_1 = elabUntypedMod(m, env, pre);
      then
        {DAE.NAMEMOD(i,m_1)};
    case (SCode.IDXMOD(subscriptLst = subcr,an = m),env,pre)
      equation
        m_1 = elabUntypedMod(m, env, pre);
      then
        {DAE.IDXMOD({-1},m_1)};
  end matchcontinue;
end elabUntypedSubmod;

protected function makeIdxmods "function: makeIdxmods
  From a list of list of integers, this function creates a list of
  sub-modifications of the IDXMOD variety."
  input list<DAE.Subscript> inExpSubscriptLst;
  input DAE.Mod inMod;
  output list<DAE.SubMod> outTypesSubModLst;
algorithm
  outTypesSubModLst := matchcontinue (inExpSubscriptLst,inMod)
    local
      Integer x;
      DAE.Mod m;
      list<DAE.SubMod> mods,mods_1;
      list<DAE.Subscript> xs;
    
    // last mod
    case ({DAE.INDEX(exp = DAE.ICONST(integer = x))},m) then {DAE.IDXMOD({x},m)};
    // some more mods
    case ((DAE.INDEX(exp = DAE.ICONST(integer = x)) :: xs),m)
      equation
        mods = makeIdxmods(xs, m);
        mods_1 = prefixIdxmods(mods, x);
      then
        mods_1;
    case ((DAE.SLICE(exp = DAE.ARRAY(array = slice)) :: xs),m)
      local list<DAE.Exp> slice;
      equation
        mods = expandSlice(slice, xs, 1, m);
      then
        mods;
    case ((DAE.WHOLEDIM() :: xs),m)
      equation
        print("# Sorry, [:] slices are not handled in modifications\n");
      then
        fail();
    case(xs,m) equation
      print("Mod.makeIdxmods failed for mod:");print(printModStr(m));print("\n");
      print("subs =");print(Util.stringDelimitList(Util.listMap(xs,Exp.printSubscriptStr),","));
      print("\n");
    then fail();

  end matchcontinue;
end makeIdxmods;

protected function prefixIdxmods "function: prefixIdxmods
  This function adds a subscript to each DAE.IDXMOD in a list of submodifications."
  input list<DAE.SubMod> inTypesSubModLst;
  input Integer inInteger;
  output list<DAE.SubMod> outTypesSubModLst;
algorithm
  outTypesSubModLst := matchcontinue (inTypesSubModLst,inInteger)
    local
      list<DAE.SubMod> mods_1,mods;
      list<Integer> l;
      DAE.Mod m;
      Integer i;
    case ({},_) then {};
    case ((DAE.IDXMOD(integerLst = l,mod = m) :: mods),i)
      equation
        mods_1 = prefixIdxmods(mods, i);
      then
        (DAE.IDXMOD((i :: l),m) :: mods_1);
  end matchcontinue;
end prefixIdxmods;

protected function expandSlice "function: expandSlice
  This function goes through an array slice modification and creates
  an singly indexed modification for each index in the slice.  For
  example, x[2:3] = y is changed into x[2] = y[1] and
  x[3] = y[2]."
  input list<DAE.Exp> inExpExpLst;
  input list<DAE.Subscript> inExpSubscriptLst;
  input Integer inInteger;
  input DAE.Mod inMod;
  output list<DAE.SubMod> outTypesSubModLst;
algorithm
  outTypesSubModLst := matchcontinue (inExpExpLst,inExpSubscriptLst,inInteger,inMod)
    local
      DAE.Exp e_1,x,e,e_2;
      tuple<DAE.TType, Option<Absyn.Path>> t_1,t;
      list<DAE.SubMod> mods1,mods2,mods;
      Integer n_1,n;
      list<DAE.Exp> xs;
      list<DAE.Subscript> restSubscripts;
      DAE.Mod m,mod,unfoldedMod;
      Boolean finalPrefix;
      Absyn.Each each_;
      Option<Values.Value> e_val;
      DAE.Const const;
      Ident str;
      Values.Value val, indexVal;
      
    case ({},_,_,_) then {};
    case ({},_,_,_) then {};
      
    // try to do value indexing on e_val as SOME(val) first!
    case ((x :: xs),restSubscripts,n,(m as DAE.MOD(finalPrefix = finalPrefix,each_ = each_,subModLst = {},
                                       eqModOption = SOME(DAE.TYPED(e,SOME(val),DAE.PROP(t,const),_)))))
      equation
        e_2 = DAE.ICONST(n);
        //print("FULLValue: " +& ValuesUtil.printValStr(val) +& "\n");        
        // get the indexed value
        indexVal = ValuesUtil.nthArrayelt(val, n);
        // transform to exp
        e_1 = ValuesUtil.valueExp(indexVal);
        t_1 = Types.unliftArray(t);
        unfoldedMod = DAE.MOD(finalPrefix,each_,{},
                              SOME(DAE.TYPED(e_1,SOME(indexVal),DAE.PROP(t_1,const),NONE())));
        //print("IDXValue: " +& ValuesUtil.printValStr(indexVal) +& "\n");
        //print("Idx: " +& Exp.printExpStr(x) +& " mod: " +& printModStr(unfoldedMod) +& "\n");
        mods1 = makeIdxmods(DAE.INDEX(x) :: restSubscripts,unfoldedMod);
        n_1 = n + 1;
        mods2 = expandSlice(xs, restSubscripts, n_1, m);
        mods = listAppend(mods1, mods2);
      then
        mods;
    
    // value indexing didn't work, try to index DAE.EXP
    case ((x :: xs),restSubscripts,n, 
          (m as DAE.MOD(finalPrefix = finalPrefix,each_ = each_,subModLst = {},
                        eqModOption = SOME(DAE.TYPED(e,e_val,DAE.PROP(t,const),_)))))
      equation
        e_2 = DAE.ICONST(n);
        //print("FULLExpression: " +& Exp.printExpStr(e) +& "\n");        
        e_1 = Exp.simplify(DAE.ASUB(e,{e_2}));
        t_1 = Types.unliftArray(t);
        unfoldedMod = DAE.MOD(finalPrefix,each_,{},
                              SOME(DAE.TYPED(e_1,NONE(),DAE.PROP(t_1,const),NONE())));
        //print("IDXExpression: " +& Exp.printExpStr(e_1) +& "\n");
        //print("Idx: " +& Exp.printExpStr(x) +& " mod: " +& printModStr(unfoldedMod) +& "\n");        
        mods1 = makeIdxmods((DAE.INDEX(x) :: restSubscripts),unfoldedMod);
        n_1 = n + 1;
        mods2 = expandSlice(xs, restSubscripts, n_1, m);
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
  input list<DAE.SubMod> inTypesSubModLst1;
  input list<DAE.SubMod> inTypesSubModLst2;
  input Env.Env inEnv3;
  input Prefix.Prefix inPrefix4;
  output list<DAE.SubMod> outTypesSubModLst;
algorithm
  outTypesSubModLst:=
  matchcontinue (inTypesSubModLst1,inTypesSubModLst2,inEnv3,inPrefix4)
    local
      list<DAE.SubMod> x_1,xs_1,l,xs,y;
      DAE.SubMod x;
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
  input DAE.SubMod inSubMod;
  input list<DAE.SubMod> inTypesSubModLst;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  output list<DAE.SubMod> outTypesSubModLst;
algorithm
  outTypesSubModLst:=
  matchcontinue (inSubMod,inTypesSubModLst,inEnv,inPrefix)
    local
      DAE.SubMod sub,sub1;
      DAE.Mod m,m1,m2;
      Ident n1,n2;
      list<DAE.SubMod> tail,sub2;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      list<Integer> i1,i2;
    
    case (sub,{},_,_) then {sub};
    
    case (DAE.NAMEMOD(ident = n1,mod = m1),(DAE.NAMEMOD(ident = n2,mod = m2) :: tail),env,pre)
      equation
        true = stringEqual(n1, n2);
        m = merge(m1, m2, env, pre);
      then
        (DAE.NAMEMOD(n1,m) :: tail);
    
    case (DAE.IDXMOD(integerLst = i1,mod = m1),(DAE.IDXMOD(integerLst = i2,mod = m2) :: tail),env,pre)
      equation
        equality(i1 = i2);
        m = merge(m1, m2, env, pre);
      then
        (DAE.IDXMOD(i1,m) :: tail);
    
    case (sub1,sub2,_,_) then (sub1 :: sub2);
  end matchcontinue;
end insertSubmod;

// - Lookup
public function lookupModificationP "function: lookupModificationP
  This function extracts a modification from inside another
  modification, using a name to look up submodifications."
  input DAE.Mod inMod;
  input Absyn.Path inPath;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue (inMod,inPath)
    local
      DAE.Mod mod,m,mod_1;
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
        Print.printBuf("- Mod.lookupModificationP failed\n");
      then
        fail();
  end matchcontinue;
end lookupModificationP;

public function lookupCompModification "function: lookupCompModification
  This function is used to look up an identifier in a modification."
  input DAE.Mod inMod;
  input Absyn.Ident inIdent;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue (inMod,inIdent)
    local
      DAE.Mod mod,mod1,mod2;
      list<DAE.SubMod> subs;
      Ident n,i;
      Option<DAE.EqMod> eqMod;
      Absyn.Each e;
      Boolean f;
    case (DAE.NOMOD(),_) then DAE.NOMOD();
    case (DAE.REDECL(finalPrefix = _),_) then DAE.NOMOD();
    case (DAE.MOD(finalPrefix=f,each_=e,subModLst = subs,eqModOption=eqMod),n)
      equation
        mod1 = lookupCompModification2(subs, n);
        mod2 = lookupComplexCompModification(eqMod,n,f,e);
        mod = checkDuplicateModifications(mod1,mod2);
      then
        mod;
  end matchcontinue;
end lookupCompModification;

public function lookupCompModification12 "function: lookupCompModification
Author: BZ, 2009-07
Function for looking up modifiers on specific component.
And put it in a DAE.Mod(Types.NAMEDMOD(comp,mod)) format."
  input DAE.Mod inMod;
  input Absyn.Ident inIdent;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue (inMod,inIdent)
    local
      DAE.Mod mod,mod1,mod2,m;
      list<DAE.SubMod> subs;
      Ident n,i;
      Option<DAE.EqMod> eqMod;
      Absyn.Each e;
      Boolean f;
    case(inMod,inIdent)
      equation
        DAE.NOMOD() = lookupCompModification(inMod,inIdent);
      then
        DAE.NOMOD();
    
    case(inMod,inIdent)
      equation
        (m as DAE.MOD(_,_, {}, SOME(_))) = lookupCompModification(inMod,inIdent);
      then
        m;
    
    case(inMod,inIdent)
      equation
        m = lookupCompModification(inMod,inIdent);
      then
        DAE.MOD(false, Absyn.NON_EACH(), {DAE.NAMEMOD(inIdent,m)},NONE());
  end matchcontinue;
end lookupCompModification12;

protected function lookupComplexCompModification "Lookups a component modification from a complex constructor
(e.g. record constructor) by name."
  input option<DAE.EqMod> eqMod;
  input Absyn.Ident n;
  input Boolean finalPrefix;
  input Absyn.Each each_;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue(eqMod,n,finalPrefix,each_)
    local 
      list<Values.Value> values;
      list<String> names;
      list<DAE.Var> varLst;
      DAE.Mod mod;
      DAE.Exp e;
    
    case(NONE(),_,_,_) then DAE.NOMOD();
    
    case(SOME(DAE.TYPED(e,SOME(Values.RECORD(_,values,names,-1)),
                        DAE.PROP((DAE.T_COMPLEX(complexVarLst = varLst),_),_),_)),
         n,finalPrefix,each_) 
      equation
        mod = lookupComplexCompModification2(values,names,varLst,n,finalPrefix,each_);
      then mod;
    
    case(_,_,_,_) then DAE.NOMOD();
  end matchcontinue;
end lookupComplexCompModification;

protected function lookupComplexCompModification2 "Help function to lookupComplexCompModification"
  input list<Values.Value> values;
  input list<Ident> names;
  input list<DAE.Var> vars;
  input String name;
  input Boolean finalPrefix;
  input Absyn.Each each_;
  output DAE.Mod mod;
algorithm
  mod := matchcontinue(values,names,vars,name,finalPrefix,each_)
    local 
      DAE.Type tp;
      Values.Value v; String name1,name2;
      DAE.Exp e;
      
    case(v::_,name1::_,DAE.TYPES_VAR(name=name2,type_=tp)::_,name,finalPrefix,each_) 
      equation
        true = (name1 ==& name2);
        true = (name2 ==& name);
        e = ValuesUtil.valueExp(v);
      then DAE.MOD(finalPrefix,each_,{},SOME(DAE.TYPED(e,SOME(v),DAE.PROP(tp,DAE.C_CONST()),NONE())));

    case(_::values,_::names,_::vars,name,finalPrefix,each_) equation
      mod = lookupComplexCompModification2(values,names,vars,name,finalPrefix,each_);
    then mod;

  end matchcontinue;
end lookupComplexCompModification2;

protected function checkDuplicateModifications "Checks if two modifiers are present, and in that case
print error of duplicate modifications, if not, the one modification having a value is returned"
  input DAE.Mod mod1;
  input DAE.Mod mod2;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue(mod1,mod2)
    local 
      String s1,s2,s;

    case(DAE.NOMOD(),mod2) then mod2;
    case(mod1,DAE.NOMOD()) then mod1;
    case(mod1,mod2) equation
      s1 = printModStr(mod1);
      s2 = printModStr(mod2);
      s = s1 +& " and " +& s2;
      Error.addMessage(Error.DUPLICATE_MODIFICATIONS,{s});
    then fail();
  end matchcontinue;
end checkDuplicateModifications;

protected function lookupNamedModifications 
"@author: adrpo
 returns a list of matching name modifications"
  input list<DAE.SubMod> inSubModLst;
  input Absyn.Ident inIdent;
  output list<DAE.SubMod> outSubModLst;
algorithm
  outSubModLst := matchcontinue (inSubModLst,inIdent)
    local
      Ident id1,id2;
      DAE.SubMod x;
      list<DAE.SubMod> rest, lst;
      String s;
      
    // empty case
    case ({},_) then {};
    
    // found our modification  
    case ((x  as DAE.NAMEMOD(ident = id1)) :: rest,id2)
      equation
        true = stringEqual(id1, id2);
        lst = lookupNamedModifications(rest, id2);
      then
        x :: lst;    
    
    // a named modification that doesn't match, skip it 
    case ((x  as DAE.NAMEMOD(ident = id1)) :: rest,id2)
      equation
        false = stringEqual(id1, id2);
        lst = lookupNamedModifications(rest, id2);
      then
        lst;

    // an index modification, skip it 
    case ((DAE.IDXMOD(integerLst=_) :: rest),id2)
      equation
        lst = lookupNamedModifications(rest, id2);
      then
        lst;
  end matchcontinue;
end lookupNamedModifications;

public function printSubsStr
"@author: adrpo
 Prints sub-mods in a string with format (sub1, sub2, sub3)"
  input list<DAE.SubMod> inSubMods;
  input Boolean addParan;
  output String s;
algorithm
  s := Util.stringDelimitList(Util.listMap(inSubMods, prettyPrintSubmod), ", ");
  s := Util.if_(addParan,"(","") +& s +& Util.if_(addParan,")","");
end printSubsStr;

protected function lookupCompModification2 "function: lookupCompModification2
  This function is just a helper to lookupCompModification"
  input list<DAE.SubMod> inSubModLst;
  input Absyn.Ident inIdent;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue (inSubModLst,inIdent)
    local
      Ident id;
      DAE.Mod mod;
      String s, s1, s2;
      list<DAE.SubMod> duplicates, tail;
      DAE.SubMod head;
      
      
    // empty case, return DAE.NOMOD()
    case ({},_) then DAE.NOMOD();
    
    // found no modifs that match, return DAE.NOMOD();
    case (inSubModLst,id)
      equation
        {} = lookupNamedModifications(inSubModLst, id);
      then
        DAE.NOMOD();
      
    // found our modification and is not duplicate, only one 
    case (inSubModLst,id)
      equation
        {DAE.NAMEMOD(mod=mod)} = lookupNamedModifications(inSubModLst, id); 
      then
        mod;

    // found our modification and there are more duplicates present 
    case (inSubModLst,id)
      equation
        duplicates = lookupNamedModifications(inSubModLst, id);
        s = printSubsStr(duplicates, true);
        (head::tail) = duplicates;
        s1 = prettyPrintSubmod(head);
        s1 = "(" +& s1 +& ")";
        s2 = printSubsStr(tail, true); 
        Error.addMessage(Error.DUPLICATE_MODIFICATIONS_WARNING, {id, s, s1, s2});
        DAE.NAMEMOD(mod=mod) = head;
      then
        mod;

    case (inSubModLst,inIdent)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- Mod.lookupCompModification2 failed while searching for:" +& 
          inIdent +& " inside mofifications: " +&
          printModStr(DAE.MOD(false,Absyn.NON_EACH(),inSubModLst,NONE())));
      then
        fail();
  end matchcontinue;
end lookupCompModification2;

public function lookupIdxModification "function: lookupIdxModification
  This function extracts modifications to an array element, using an
  integer to index the modification."
  input DAE.Mod inMod;
  input Integer inInteger;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue (inMod,inInteger)
    local
      DAE.Mod mod_1,mod_2,mod_3,inmod,mod;
      list<DAE.SubMod> subs_1,subs;
      Option<DAE.EqMod> eq_1,eq;
      Boolean f;
      Absyn.Each each_;
      Integer idx;
      Ident str,s;
    
    case (DAE.NOMOD(),_) then DAE.NOMOD();
    case (DAE.REDECL(finalPrefix = _),_) then DAE.NOMOD();
    case ((inmod as DAE.MOD(finalPrefix = f,each_ = each_,subModLst = subs,eqModOption = eq)),idx)
      equation
        (mod_1,subs_1) = lookupIdxModification2(subs,idx);
        mod_2 = merge(DAE.MOD(f,each_,subs_1,NONE()), mod_1, {}, Prefix.NOPRE());
        eq_1 = indexEqmod(eq, {idx});
        mod_3 = merge(mod_2, DAE.MOD(false,each_,{},eq_1), {}, Prefix.NOPRE());
      then
        mod_3;
    case (mod,idx)
      equation
                true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "- Mod.lookupIdxModification(");
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
  This function does part of the job for lookupIdxModification."
  input list<DAE.SubMod> inTypesSubModLst;
  input Integer inInteger;
  output DAE.Mod outMod;
  output list<DAE.SubMod> outTypesSubModLst;
algorithm
  (outMod,outTypesSubModLst) := matchcontinue (inTypesSubModLst,inInteger)
    local
      list<DAE.SubMod> subs_1,subs,xs_1;
      Integer x,y,idx;
      DAE.Mod mod,mod_1,nmod_1,nmod;
      Option<DAE.EqMod> eq;
      list<Integer> xs;
      Ident name;
    
    case ({},_) then (DAE.NOMOD(),{});
    
    case ((DAE.IDXMOD(integerLst = {x},mod = mod) :: subs),y) /* FIXME: Redeclaration */
      equation
        true = intEq(x, y);
        (DAE.NOMOD(),subs_1) = lookupIdxModification2(subs,y);
      then
        (mod,subs_1);

    case ((DAE.IDXMOD(integerLst = (x :: xs),mod = mod) :: subs),y)
      equation
        true = intEq(x, y);
        (mod_1,subs_1) = lookupIdxModification2(subs,y);
      then
        (mod_1,(DAE.IDXMOD(xs,mod) :: subs_1));
    
    case ((DAE.IDXMOD(integerLst = (x :: xs),mod = mod) :: subs),y)
      equation
        false = intEq(x, y);
        (mod_1,subs_1) = lookupIdxModification2(subs,y);
      then
        (mod_1,subs_1);
    
    case ((DAE.NAMEMOD(ident = name,mod = nmod) :: subs),y)
      equation
        DAE.NOMOD() = lookupIdxModification3(nmod, y);
        (mod_1,subs_1) = lookupIdxModification2(subs,y);
      then
        (mod_1,subs_1);
    
    case ((DAE.NAMEMOD(ident = name,mod = nmod) :: subs),y)
      equation
        nmod_1 = lookupIdxModification3(nmod, y);
        (mod_1,subs_1) = lookupIdxModification2(subs,y);
      then
        (mod_1,(DAE.NAMEMOD(name,nmod_1) :: subs_1));
    
    case ((x :: xs),idx)
      local
        DAE.SubMod x;
        list<DAE.SubMod> xs;
      equation
        (mod,xs_1) = lookupIdxModification2(xs,idx);
      then
        (mod,(x :: xs_1));
    
    case (_,_)
      equation
       Debug.fprint("failtrace", "- Mod.lookupIdxModification2 failed\n");
      then
        fail();
  end matchcontinue;
end lookupIdxModification2;

protected function lookupIdxModification3 "function: lookupIdxModification3
  Helper function to lookup_idx_modification2.
  when looking up index of a named mod, e.g. y={1,2,3}, it should
  subscript the expression {1,2,3} to corresponding index."
  input DAE.Mod inMod;
  input Integer inInteger;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue (inMod,inInteger)
    local
      Option<DAE.EqMod> eq_1,eq;
      Boolean f;
      list<DAE.SubMod> subs,subs_1;
      Integer idx;
    
    case (DAE.NOMOD(),_) then DAE.NOMOD();  /* indx */
    case (DAE.REDECL(finalPrefix = _),_) then DAE.NOMOD();
    case (DAE.MOD(finalPrefix = f,each_ = Absyn.NON_EACH(),subModLst = subs,eqModOption = eq),idx)
      equation
        (_,subs_1) = lookupIdxModification2(subs,idx);
        eq_1 = indexEqmod(eq, {idx});
      then
        DAE.MOD(f,Absyn.NON_EACH(),subs_1,eq_1);
    case (DAE.MOD(finalPrefix = f,each_ = Absyn.EACH(),subModLst = subs,eqModOption = eq),idx) then DAE.MOD(f,Absyn.EACH(),subs,eq);
    case (inMod,idx) equation
            true = RTOpts.debugFlag("failtrace");
      Debug.fprintln("failtrace", "- Mod.lookupIdxModification3 failed for mod: \n" +&
                     printModStr(inMod) +& "\n for index:" +& intString(idx));
    then fail();
  end matchcontinue;
end lookupIdxModification3;

protected function indexEqmod "function: indexEqmod
  If there is an equation modification, this function can subscript
  it using the provided indexing expressions.  This is used when a
  modification equates an array variable with an array expression.
  This expression will be expanded to produce one equation
  expression per array component."
  input Option<DAE.EqMod> inTypesEqModOption;
  input list<Integer> inIntegerLst;
  output Option<DAE.EqMod> outTypesEqModOption;
algorithm
  outTypesEqModOption := matchcontinue (inTypesEqModOption,inIntegerLst)
    local
      Option<DAE.EqMod> e;
      tuple<DAE.TType, Option<Absyn.Path>> t_1,t;
      DAE.Exp exp,exp2;
      Values.Value e_val_1,e_val;
      DAE.Const c;
      Integer x;
      list<Integer> xs;
      DAE.EqMod eq;
      Absyn.Exp absynExp;

    case (NONE(),_) then NONE();
    case (e,{}) then e;

    // Subscripting empty array gives no value. This is needed in e.g. fill(1.0,0,2) 
    case (SOME(DAE.TYPED(_,SOME(Values.ARRAY(valueLst = {})),_,_)),xs) then NONE();

    // For modifiers with value, retrieve nth element
    case (SOME(DAE.TYPED(e,SOME(e_val),DAE.PROP(t,c),_)),(x :: xs))
      equation
        t_1 = Types.unliftArray(t);
        exp2 = DAE.ICONST(x);
        exp = Exp.simplify(DAE.ASUB(e,{exp2}));
        e_val_1 = ValuesUtil.nthArrayelt(e_val, x);
        e = indexEqmod(SOME(DAE.TYPED(exp,SOME(e_val_1),DAE.PROP(t_1,c),NONE())), xs);
      then
        e;

        // For modifiers without value, apply subscript operator
    case (SOME(DAE.TYPED(e,NONE(),DAE.PROP(t,c),_)),(x :: xs))
      equation
        t_1 = Types.unliftArray(t);
        exp2 = DAE.ICONST(x);
        exp = Exp.simplify(DAE.ASUB(e,{exp2}));
        e = indexEqmod(SOME(DAE.TYPED(exp,NONE(),DAE.PROP(t_1,c),NONE())), xs);
      then
        e;

    case (e as SOME(DAE.TYPED(modifierAsExp = exp, properties = DAE.PROP(type_ = t))), _)
      local
        String exp_str;
      equation
                /* Trying to apply a non-array modifier to an array, which isn't
                 * really allowed but working anyway. Some standard Modelica libraries
                 * are missing the 'each' keyword though (i.e. the DoublePendulum
                 * example), and therefore relying on this behaviour, so just print a
                 * warning here. */
        failure(t_1 = Types.unliftArray(t));
        exp_str = Exp.printExpStr(exp);
                Error.addMessage(Error.MODIFIER_NON_ARRAY_TYPE_WARNING, {exp_str});
            then 
              fail();

    case (SOME(eq),inIntegerLst) 
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- Mod.indexEqmod failed for mod:\n " +&
               Types.unparseEqMod(eq) +& "\n indexes:" +&
               Util.stringDelimitList(Util.listMap(inIntegerLst, intString), ", "));
      then fail();
  end matchcontinue;
end indexEqmod;

public function merge "
A mid step for merging two modifiers.
It validates that the merging is allowed(considering final modifier)."
  input DAE.Mod inMod1;
  input DAE.Mod inMod2;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  output DAE.Mod outMod;
algorithm 
  outMod:= matchcontinue (inMod1,inMod2,inEnv,inPrefix)
    local
      DAE.Mod m;
      list<DAE.SubMod> submods;
      String strPrefix, s; 
      Option<Absyn.Path> p;
      
    case (DAE.NOMOD(),DAE.NOMOD(),_,_) then DAE.NOMOD();
    case (DAE.NOMOD(),m,_,_) then m;
    case (m,DAE.NOMOD(),_,_) then m;
      
    case(inMod1,inMod2,inEnv,inPrefix)
      equation
        true = merge2(inMod2);
      then doMerge(inMod1,inMod2,inEnv,inPrefix);

    case(inMod1,inMod2,inEnv,inPrefix)
      equation
        true = modSubsetOrEqualOrNonOverlap(inMod1,inMod2);
      then doMerge(inMod1,inMod2,inEnv,inPrefix);

    case(inMod1,inMod2,inEnv,inPrefix)
      equation
        false = merge2(inMod2);
        false = modSubsetOrEqualOrNonOverlap(inMod1,inMod2);
        p = Env.getEnvPath(inEnv);
        s = Absyn.optPathString(p);
        // put both modifiers in one big modifier
        strPrefix = PrefixUtil.printPrefixStrIgnoreNoPre(inPrefix);
        submods = {DAE.NAMEMOD("", inMod1), DAE.NAMEMOD("", inMod2)}; 
        m = DAE.MOD(false, Absyn.NON_EACH, submods,NONE());
        s = s +& "\n\tby using modifiers: " +&  strPrefix +& printSubsStr(submods, true) +& 
        " that do not agree.";
        
        Error.addMessage(Error.FINAL_OVERRIDE, {s}); // having a string there incase we
        // print(" final override: " +& s +& "\n ");
        // print("trying to override final while merging mod1:\n" +& printModStr(inMod1) +& " with mod2(final):\n" +& printModStr(inMod2) +& "\n");
      then fail();
  end matchcontinue;
end merge;

public function merge2 "
This function validates that the inner modifier is not final.
Helper function for merge"
  input DAE.Mod inMod1;
  output Boolean outMod;
algorithm outMod:= matchcontinue (inMod1)
  local
    DAE.Mod m;
    case (DAE.REDECL(tplSCodeElementModLst = {(SCode.COMPONENT(finalPrefix=true),_)}))
      then false;
    case(DAE.MOD(finalPrefix = true))
      then false;
    case(_) then true;
  end matchcontinue;
end merge2;

// - Merging
// 
// The merge function merges to modifications to one. 
// The first argument is the *outer* modification that 
// should take precedence over the *inner* modifications.

protected function doMerge "function: merge 
  This function merges to modificiations into one.
  The first modifications takes precedence over the second."
  input DAE.Mod inMod1;
  input DAE.Mod inMod2;
  input Env.Env inEnv3;
  input Prefix.Prefix inPrefix4;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue (inMod1,inMod2,inEnv3,inPrefix4)
    local
      DAE.Mod m,m1_1,m2_1,m_2,mod,mods,outer_,inner_,mm1,mm2,mm3;
      Boolean f1,f,r,p,f2,finalPrefix;
      Absyn.InnerOuter io;
      Ident id1,id2;
      SCode.Attributes attr;
      Absyn.TypeSpec tp;
      SCode.Mod m1,m2;
      Option<SCode.Comment> comment,comment2;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      list<tuple<SCode.Element, DAE.Mod>> els;
      list<DAE.SubMod> subs,subs1,subs2;
      Option<DAE.EqMod> ass,ass1,ass2;
      Absyn.Each each_,each2;
      Option<Absyn.Exp> cond;
      Option<Absyn.ConstrainClass> cc;
      Option<Absyn.Info> info;
    
    case (m,DAE.NOMOD(),_,_) then m;
    
    // redeclaring same component
    case (DAE.REDECL(finalPrefix = f1,tplSCodeElementModLst =
    {(SCode.COMPONENT(component = id1,innerOuter=io,finalPrefix = f,replaceablePrefix = r,protectedPrefix = p,
      attributes = attr,typeSpec = tp,modifications = m1,comment=comment,condition=cond,info=info),_)}),
      DAE.REDECL(finalPrefix = f2,tplSCodeElementModLst =
      {(SCode.COMPONENT(component = id2,modifications = m2,comment = comment2,cc=cc),_)}),env,pre)
      equation
        true = stringEqual(id1, id2);
        m1_1 = elabUntypedMod(m2, env, pre);
        m2_1 = elabUntypedMod(m2, env, pre);
        m_2 = merge(m1_1, m2_1, env, pre);
      then
        DAE.REDECL(f1,{(SCode.COMPONENT(id1,io,f,r,p,attr,tp,SCode.NOMOD(),comment,cond,info,cc),m_2)});

    // luc_pop : this shoud return the first mod because it have been merged in merge_subs
    case ((mod as DAE.REDECL(finalPrefix = f1,tplSCodeElementModLst = (els as {(SCode.COMPONENT(component = id1),_)}))),(mods as DAE.MOD(subModLst = subs)),env,pre) then mod;
    
    case ((icm as DAE.MOD(subModLst = subs)),DAE.REDECL(finalPrefix = f1,tplSCodeElementModLst = (els as {( (celm as SCode.COMPONENT(component = id1)),cm)})),env,pre)
      local
        DAE.Mod cm,icm;
        SCode.Element celm;
      equation
        cm = merge(cm,icm,env,pre);
      then
        DAE.REDECL(f1,{(celm,cm)});

    // When modifiers are identical
    case (outer_,inner_,_,_)
      equation                
        // adrpo: TODO! FIXME! why isn't modEqual working here??!! 
        // true = modEqual(outer_, inner_);        
        equality(outer_ = inner_);
      then
        outer_;

    case (DAE.MOD(finalPrefix = finalPrefix,each_ = each_,subModLst = subs1,eqModOption = ass1),DAE.MOD(finalPrefix = _/*false*, see case above.*/,each_ = each2,subModLst = subs2,eqModOption = ass2),env,pre)
      equation
        subs = mergeSubs(subs1, subs2, env, pre);
        ass = mergeEq(ass1, ass2);
      then
        DAE.MOD(finalPrefix,each_,subs,ass);
    
    /* Case when we have a modifier on a redeclared class
     * This is of current date BZ:2008-03-04 not completly working.
     * see testcase mofiles/Modification14.mo
     */
    case (mm1 as DAE.MOD(subModLst = subs), mm2 as DAE.REDECL(finalPrefix = false,tplSCodeElementModLst = (els as {((elementOne as SCode.CLASSDEF(name = id1)),mm3)})),env,pre)
      local SCode.Element elementOne;
      equation
        mm1 = merge(mm1,mm3,env,pre );
      then DAE.REDECL(false,{(elementOne,mm1)});

    case (mm2 as DAE.REDECL(finalPrefix = false,tplSCodeElementModLst = (els as {((elementOne as SCode.CLASSDEF(name = id1)),mm3)})),mm1 as DAE.MOD(subModLst = subs),env,pre)
      local SCode.Element elementOne;
      equation
        mm1 = merge(mm3,mm1,env,pre );
      then DAE.REDECL(false,{(elementOne,mm1)});
  end matchcontinue;
end doMerge;

protected function mergeSubs "function: mergeSubs
  This function merges to list of DAE.SubMods."
  input list<DAE.SubMod> inTypesSubModLst1;
  input list<DAE.SubMod> inTypesSubModLst2;
  input Env.Env inEnv3;
  input Prefix.Prefix inPrefix4;
  output list<DAE.SubMod> outTypesSubModLst;
algorithm
  outTypesSubModLst := matchcontinue (inTypesSubModLst1,inTypesSubModLst2,inEnv3,inPrefix4)
    local
      list<DAE.SubMod> s1,s1_1,ss,s2,s2_new,s_rec;
      DAE.SubMod s_1,s,s_first;
      list<Env.Frame> env;
      Prefix.Prefix pre;
    
    case ({},s1,_,_) then s1;
    case (s1,{},_,_) then s1;
    case((s::s1),s2,env,pre) // outer, inner, env, pre
      equation
        (s_first,s2_new) = mergeSubs2_2(s,s2,env,pre);
        s_rec = mergeSubs(s1,s2_new,env,pre);
      then
        (s_first::s_rec);
  end matchcontinue;
end mergeSubs;

protected function mergeSubs2_2 "
Author: BZ, 2009-07
Helper function for mergeSubs, used to detect failures in Mod.merge"
  input DAE.SubMod inSubMod;
  input list<DAE.SubMod> inTypesSubModLst;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  output DAE.SubMod outSubMod;
  output list<DAE.SubMod> outTypesSubModLst;
algorithm
  (outSubMod,outTypesSubModLst) := matchcontinue (inSubMod,inTypesSubModLst,inEnv,inPrefix)
    local
      DAE.SubMod sm,s,s1,s2;
      DAE.Mod m,m1,m2;
      Ident n1,n2;
      list<DAE.SubMod> ss,ss_1;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      list<Integer> i1,i2;      
    
    // empty list  
    case (sm,{},_,_) then (sm,{});
    
    // named mods, modifications in the list take precedence
    case (DAE.NAMEMOD(ident = n1,mod = m1),(DAE.NAMEMOD(ident = n2,mod = m2) :: ss),env,pre)      
      equation
        true = stringEqual(n1, n2);
        m = merge(m1, m2, env, pre);
      then
        (DAE.NAMEMOD(n1,m),ss);
    
    // indexed mods, modifications in the list take precedence
    case (DAE.IDXMOD(integerLst = i1,mod = m1),(DAE.IDXMOD(integerLst = i2,mod = m2) :: ss),env,pre)      
      equation
        equality(i1 = i2);
        m = merge(m1, m2, env, pre);
      then
        (DAE.IDXMOD(i1,m),ss);
    
    // handle next
    case (s1,(s2::ss),env,pre)
      equation
        true = verifySubMerge(s1,s2);
        (s,ss_1) = mergeSubs2_2(s1, ss, env, pre);
      then
        (s,s2::ss_1);
  end matchcontinue;
end mergeSubs2_2;

protected function mergeSubs2 "function: mergeSubs2
  This function helps in the merging of two lists of DAE.SubMods.  
  It compares one DAE.SubMod against a list of other DAE.SubMods, 
  and if there is one with the same name, it is kept and the one 
  DAE.SubMod given in the second argument is discarded."
  input list<DAE.SubMod> inTypesSubModLst;
  input DAE.SubMod inSubMod;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  output list<DAE.SubMod> outTypesSubModLst;
  output DAE.SubMod outSubMod;
algorithm
  (outTypesSubModLst,outSubMod) := matchcontinue (inTypesSubModLst,inSubMod,inEnv,inPrefix)
    local
      DAE.SubMod sm,s,s1,s2;
      DAE.Mod m,m1,m2;
      Ident n1,n2;
      list<DAE.SubMod> ss,ss_1;
      list<Env.Frame> env;
      Prefix.Prefix pre;
      list<Integer> i1,i2;
      DAE.Mod m;
    
    // empty list
    case ({},sm,_,_) then ({},sm);
    
    // named mods, modifications in the list take precedence
    case ((DAE.NAMEMOD(ident = n1,mod = m1) :: ss),DAE.NAMEMOD(ident = n2,mod = m2),env,pre)
      equation
        true = stringEqual(n1, n2);
        m = merge(m1, m2, env, pre);
      then
        (ss,DAE.NAMEMOD(n1,m));
    
    // indexed mods, modifications in the list take precedence
    case ((DAE.IDXMOD(integerLst = i1,mod = m1) :: ss),DAE.IDXMOD(integerLst = i2,mod = m2),env,pre)
      equation
        equality(i1 = i2);
        m = merge(m1, m2, env, pre);
      then
        (ss,DAE.IDXMOD(i1,m));
    
    // handle rest
    case ((s1 :: ss),s2,env,pre)
      equation
        true = verifySubMerge(s1,s2);
        (ss_1,s) = mergeSubs2(ss, s2, env, pre);
      then
        ((s1 :: ss_1),s);
  end matchcontinue;
end mergeSubs2;

protected function verifySubMerge "
function to verify that we did not fail the cases where 
we should merge subs (helper function for mergeSubs2)"
  input DAE.SubMod sub1;
  input DAE.SubMod sub2;
  output Boolean b;
algorithm 
  b := matchcontinue(sub1,sub2)
    local list<Integer> i1,i2; String n1,n2;
    
    case (DAE.NAMEMOD(ident = n1),DAE.NAMEMOD(ident = n2))
      equation 
        true = stringEqual(n1, n2);
      then false;
    
    case (DAE.IDXMOD(integerLst = i1),DAE.IDXMOD(integerLst = i2))
      equation 
        equality(i1 = i2);
      then false;
    
    case(_,_) then true;
  end matchcontinue;
end verifySubMerge;

protected function mergeEq "function: mergeEq
  The outer modification, given in the first argument, 
  takes precedence over the inner modifications."
  input Option<DAE.EqMod> inTypesEqModOption1;
  input Option<DAE.EqMod> inTypesEqModOption2;
  output Option<DAE.EqMod> outTypesEqModOption;
algorithm
  outTypesEqModOption := matchcontinue (inTypesEqModOption1,inTypesEqModOption2)
    local Option<DAE.EqMod> e;
    // Outer assignments take precedence
    case ((e as SOME(DAE.TYPED(modifierAsExp = _))),_) then e;
    case ((e as SOME(DAE.UNTYPED(_))),_) then e;
    case (NONE(),e) then e;
  end matchcontinue;
end mergeEq;

public function modEquation "function: modEquation
  This function simply extracts the equation part of a modification."
  input DAE.Mod inMod;
  output Option<DAE.EqMod> outTypesEqModOption;
algorithm
  outTypesEqModOption := matchcontinue (inMod)
    local Option<DAE.EqMod> e;
    case DAE.NOMOD() then NONE();
    case DAE.REDECL(finalPrefix = _) then NONE();
    case DAE.MOD(eqModOption = e) then e;
  end matchcontinue;
end modEquation;

protected function modSubsetOrEqualOrNonOverlap "
same as modEqual with the difference that we allow:
 outer(input arg1: mod1) - modifier to be a subset of
 inner(input arg2: mod2) - modifier,
 IF the subset is cotained in mod2 and those subset matches are equal
 or if outer(expr=NONE()) with inner(expr=(SOME))"
  input DAE.Mod mod1;
  input DAE.Mod mod2;
  output Boolean equal;
algorithm
  equal := matchcontinue(mod1,mod2)
    local 
      Boolean b1,b2,b3,b4,f1,f2;
      Absyn.Each each1,each2;
      list<DAE.SubMod> submods1,submods2;
      Option<DAE.EqMod> eqmod1,eqmod2;

    // adrpo: handle non-overlap: final parameter Real eAxis_ia[3](each final unit="1") = {1,2,3};
    //        mod1 = final each unit="1" mod2 = final = {1,2,3}
    //        otherwise we get an error as: Error: Variable eAxis_ia: trying to override final variable ...
    case(DAE.MOD(f1,each1,submods1,NONE()),DAE.MOD(f2,Absyn.NON_EACH(),{},eqmod2 as SOME(_)))
      equation
        b1 = Util.boolEqual(f1,f2);
        equal = b1;
      then equal;

    // handle subset equal
    case(DAE.MOD(f1,each1,submods1,eqmod1),DAE.MOD(f2,each2,submods2,eqmod2))
      equation
        b1 = Util.boolEqual(f1,f2);
        b2 = Absyn.eachEqual(each1,each2);
        b3 = subModsEqual(submods1,submods2);
        b4 = eqModSubsetOrEqual(eqmod1,eqmod2);
        equal = Util.boolAndList({b1,b2,b3,b4});
      then equal;
    case(DAE.REDECL(_,_),DAE.REDECL(_,_)) then false;
    case(DAE.NOMOD(),DAE.NOMOD()) then true;
    case(mod1, mod2) then false;      
    case(mod1, mod2) 
      equation
        //true = RTOpts.debugFlag("failtrace");
        //Debug.traceln("- Mod.modSubsetOrEqualOrNonOverlap failed on: " +& 
        //   " mod1: " +& printModStr(mod1) +& 
        //   " mod2: " +& printModStr(mod2));
      then
        fail();
  end matchcontinue;
end modSubsetOrEqualOrNonOverlap;

protected function eqModSubsetOrEqual "
Returns true if two EqMods are equal or outer(input arg1) is NONE"
  input Option<DAE.EqMod> eqMod1;
  input Option<DAE.EqMod> eqMod2;
  output Boolean equal;
algorithm
  equal := matchcontinue(eqMod1,eqMod2)
    local 
      Absyn.Exp aexp1,aexp2;
      DAE.Exp exp1,exp2; DAE.EqMod teq;
    
    // no mods
    case(NONE(),NONE()) then true;
    
    // none vs. some (subset) mods
    case(NONE(),SOME(teq)) then true;
    
    // typed mods
    case(SOME(DAE.TYPED(modifierAsExp = exp1)),SOME(DAE.TYPED(modifierAsExp = exp2))) 
      equation
        equal = Exp.expEqual(exp1,exp2);
      then equal;
    
    // typed vs. untyped mods
    case(SOME(DAE.TYPED(exp1,_,_,SOME(aexp1))),SOME(DAE.UNTYPED(aexp2))) 
      equation
        //aexp1 = Exp.unelabExp(exp1);
        equal = Absyn.expEqual(aexp1,aexp2);
      then equal;

    case(SOME(DAE.TYPED(exp1,_,_,NONE())),SOME(DAE.UNTYPED(aexp2))) 
      equation
        aexp1 = Exp.unelabExp(exp1);
        equal = Absyn.expEqual(aexp1,aexp2);
      then equal;

    // untyped vs. typed 
    case(SOME(DAE.UNTYPED(aexp1)),SOME(DAE.TYPED(exp2,_,_,SOME(aexp2)))) 
      equation
        //aexp2 = Exp.unelabExp(exp2);
        equal = Absyn.expEqual(aexp1,aexp2);
      then equal;

    case(SOME(DAE.UNTYPED(aexp1)),SOME(DAE.TYPED(exp2,_,_,NONE()))) 
      equation
        aexp2 = Exp.unelabExp(exp2);
        equal = Absyn.expEqual(aexp1,aexp2);
      then equal;

    // untyped mods
    case(SOME(DAE.UNTYPED(aexp1)),SOME(DAE.UNTYPED(aexp2))) 
      equation
        equal = Absyn.expEqual(aexp1,aexp2);
      then equal;

    // anything else gives false
    case(_,_) then false;
  end matchcontinue;
end eqModSubsetOrEqual;

protected function subModsSubsetOrEqual "
Returns true if two submod lists are equal. Or all of the elements in subModLst1 have equalities in subModLst2.
if subModLst2 then contain more elements is not a mather."
  input list<DAE.SubMod> subModLst1;
  input list<DAE.SubMod> subModLst2;
  output Boolean equal;
algorithm
  equal := matchcontinue(subModLst1,subModLst2)
  local    DAE.Ident id1,id2;
    DAE.Mod mod1,mod2;
    Boolean b1,b2,b3;
    list<Integer> indx1,indx2;
    list<Boolean> blst1;
    case ({},{}) then true;
    case (DAE.NAMEMOD(id1,mod1)::subModLst1,DAE.NAMEMOD(id2,mod2)::subModLst2)
      equation
        true = stringEqual(id1,id2);
        b1 = modEqual(mod1,mod2);
        b2 = subModsEqual(subModLst1,subModLst2);
        equal = Util.boolAndList({b1,b2});
      then equal;
    case (DAE.IDXMOD(indx1,mod1)::subModLst1,DAE.IDXMOD(indx2,mod2)::subModLst2)
      equation
        blst1 = Util.listThreadMap(indx1,indx2,intEq);
        b2 = modSubsetOrEqualOrNonOverlap(mod1,mod2);
        b3 = subModsSubsetOrEqual(subModLst1,subModLst2);
        equal = Util.boolAndList(b2::b3::blst1);
      then equal;
    case(subModLst1,DAE.IDXMOD(_,_)::subModLst2)
      equation
        b3 = subModsSubsetOrEqual(subModLst1,subModLst2);
      then b3;
    case(_,_) then false;
  end matchcontinue;
end subModsSubsetOrEqual;

public function modEqual "
Compares two DAE.Mod, returns true if equal"
  input DAE.Mod mod1;
  input DAE.Mod mod2;
  output Boolean equal;
algorithm
  equal := matchcontinue(mod1,mod2)
    local Boolean b1,b2,b3,b4,f1,f2;
      Absyn.Each each1,each2;
      list<DAE.SubMod> submods1,submods2;
      Option<DAE.EqMod> eqmod1,eqmod2;

    case(DAE.MOD(f1,each1,submods1,eqmod1),DAE.MOD(f2,each2,submods2,eqmod2)) equation
      b1 = Util.boolEqual(f1,f2);
      b2 = Absyn.eachEqual(each1,each2);
      b3 = subModsEqual(submods1,submods2);
      b4 = eqModEqual(eqmod1,eqmod2);
      equal = Util.boolAndList({b1,b2,b3,b4});
      then equal;
    case(DAE.REDECL(_,_),DAE.REDECL(_,_)) then false;
    case(DAE.NOMOD(),DAE.NOMOD()) then true;
    // adrpo: do not fail!
    case (_, _) then false;
  end matchcontinue;
end modEqual;

protected function subModsEqual "Returns true if two submod lists are equal."
  input list<DAE.SubMod> subModLst1;
  input list<DAE.SubMod> subModLst2;
  output Boolean equal;
algorithm
  equal := matchcontinue(subModLst1,subModLst2)
    local    DAE.Ident id1,id2;
      DAE.Mod mod1,mod2;
      Boolean b1,b2,b3;
      list<Integer> indx1,indx2;
      list<Boolean> blst1;
    
    case ({},_) then true;
    
    case (DAE.NAMEMOD(id1,mod1)::subModLst1,DAE.NAMEMOD(id2,mod2)::subModLst2)
      equation
        true = stringEqual(id1,id2);
        b1 = modEqual(mod1,mod2);
        b2 = subModsEqual(subModLst1,subModLst2);
        equal = Util.boolAndList({b1,b2});
      then equal;
    
    case (DAE.IDXMOD(indx1,mod1)::subModLst1,DAE.IDXMOD(indx2,mod2)::subModLst2)
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
  input Option<DAE.EqMod> eqMod1;
  input Option<DAE.EqMod> eqMod2;
  output Boolean equal;
algorithm
  equal := matchcontinue(eqMod1,eqMod2)
    local 
      Absyn.Exp aexp1,aexp2;
      DAE.Exp exp1,exp2;

    // no equ mods
    case(NONE(),NONE()) then true;

    // typed equmods
    case(SOME(DAE.TYPED(exp1,_,_,_)),SOME(DAE.TYPED(exp2,_,_,_))) 
      equation
        equal = Exp.expEqual(exp1,exp2);
      then equal;

    // typed vs. untyped equmods
    case(SOME(DAE.TYPED(exp1,_,_,SOME(aexp1))),SOME(DAE.UNTYPED(aexp2))) 
      equation
        //aexp1 = Exp.unelabExp(exp1);
        equal = Absyn.expEqual(aexp1,aexp2);
      then equal;

    case(SOME(DAE.TYPED(exp1,_,_,NONE())),SOME(DAE.UNTYPED(aexp2))) 
      equation
        aexp1 = Exp.unelabExp(exp1);
        equal = Absyn.expEqual(aexp1,aexp2);
      then equal;

    // untyped vs. typed equmods
    case(SOME(DAE.UNTYPED(aexp1)),SOME(DAE.TYPED(exp2,_,_,SOME(aexp2)))) 
      equation
        //aexp2 = Exp.unelabExp(exp2);
        equal = Absyn.expEqual(aexp1,aexp2);
      then equal;

    case(SOME(DAE.UNTYPED(aexp1)),SOME(DAE.TYPED(exp2,_,_,NONE()))) 
      equation
        aexp2 = Exp.unelabExp(exp2);
        equal = Absyn.expEqual(aexp1,aexp2);
      then equal;

    // untyped equmods
    case(SOME(DAE.UNTYPED(aexp1)),SOME(DAE.UNTYPED(aexp2))) 
      equation
        equal = Absyn.expEqual(aexp1,aexp2);
      then equal;

    // anything else will give false
    case(_,_) then false;
  end matchcontinue;
end eqModEqual;

public function printModStr
"This function prints a modification.
 It uses a few other function to do its stuff."
  input DAE.Mod inMod;
  output String outString;
algorithm
  outString:=
  matchcontinue (inMod)
    local
      list<SCode.Element> elist_1;
      Ident finalPrefixstr,str,res,s1_1,s2;
      list<Ident> str_lst,s1;
      Boolean finalPrefix;
      list<tuple<SCode.Element, DAE.Mod>> elist;
      Absyn.Each each_;
      list<DAE.SubMod> subs;
      Option<DAE.EqMod> eq;
    case (DAE.NOMOD()) then "()";
    case DAE.REDECL(finalPrefix = finalPrefix,tplSCodeElementModLst = elist)
      equation
        elist_1 = Util.listMap(elist, Util.tuple21);
        finalPrefixstr = Util.if_(finalPrefix, " final", "");
        str_lst = Util.listMap(elist_1, SCode.printElementStr);
        str = Util.stringDelimitList(str_lst, ", ");
        res = System.stringAppendList({"(redeclare(",finalPrefixstr,str,"))"});
      then
        res;
    case DAE.MOD(finalPrefix = finalPrefix,each_ = each_,subModLst = subs,eqModOption = eq)
      equation
        finalPrefixstr = Util.if_(finalPrefix, " final", "");
        s1 = printSubs1Str(subs);
        s1_1 = Util.stringDelimitList(s1, ",");
        s1_1 = Util.if_(listLength(subs)>=1," {" +& s1_1 +& "} ",s1_1);
        s2 = printEqmodStr(eq);
        str = System.stringAppendList({finalPrefixstr,s1_1,s2});
      then
        str;
    case(_) equation print(" failure in printModStr \n"); then fail();
  end matchcontinue;
end printModStr;

public function printMod "function: printMod
  Print a modifier on the Print buffer."
  input DAE.Mod m;
  Ident str;
algorithm
  str := printModStr(m);
  Print.printBuf(str);
end printMod;

public function prettyPrintMod "
Author BZ, 2009-07
Prints a readable format of a modifier."
  input DAE.Mod m;
  input Integer depth;
  output String str;
algorithm str := matchcontinue(m,depth)
  local
    list<tuple<SCode.Element, DAE.Mod>> tup;
    list<DAE.SubMod> subs;
    String s1,s2;
    Boolean fp;

  case(DAE.MOD(subModLst = subs, eqModOption=NONE()),depth) // 0 since we are only interested in this scopes modifier.
    equation
      str = prettyPrintSubs(subs,depth);
    then str;

  case(DAE.MOD(subModLst = subs, eqModOption=NONE()),depth) then "";

  case(DAE.MOD(finalPrefix = fp, eqModOption=SOME(eq)),depth)
    local
      DAE.EqMod eq;
    equation
      str = Util.if_(fp,"final ","") +& Types.unparseEqMod(eq);
    then
      str;

  case(DAE.REDECL(tplSCodeElementModLst = tup),depth)
    equation
      s1 = Util.stringDelimitList(Util.listMap(Util.listMap(tup,Util.tuple21),SCode.elementName),", ");
      //print(Util.stringDelimitList(Util.listMap(Util.listMap(tup,Util.tuple21),SCode.printElementStr),",") +& "\n");
      //s2 = Util.stringDelimitList(Util.listMap1(Util.listMap(tup,Util.tuple22),prettyPrintMod,0),", ");
      //print(" (depth: " +& intString(depth) +& " (("+&s2+&")))Redeclaration of element(s): " +& s1 +& "\n");
      //print(" ok\n");
    then
      "redeclare...";
  case(DAE.NOMOD(),_) then "";
  case(_,_) equation print(" failed prettyPrintMod\n"); then fail();
end matchcontinue;
end prettyPrintMod;

protected function prettyPrintSubs "
Author BZ
Helper function for prettyPrintMod"
  input list<DAE.SubMod> inSubs;
  input Integer depth;
  output String str;
algorithm str := matchcontinue(inSubs,depth)
  local
    String s1,s2,s3,id;
    DAE.SubMod s;
    DAE.Mod m;
    list<Integer> li;
  case({},_) then "";
  case((s as DAE.NAMEMOD(id,(m as DAE.REDECL(finalPrefix=_))))::inSubs,depth)
    equation
      //s1 = prettyPrintSubs(inSubs);
      //s2  = prettyPrintMod(m,depth+1);
      //s2 = Util.if_(stringLength(s2) == 0, ""," = " +& s2);
      s2 = " redeclare(" +& id +&  "), class or component " +& id;
    then
      s2;
  case((s as DAE.NAMEMOD(id,m))::inSubs,depth)
    equation
      s2  = prettyPrintMod(m,depth+1);
      s2 = Util.if_(stringLength(s2) == 0, ""," = " +& s2);
      s2 = "(" +& id +& s2 +& "), class or component " +& id;
    then
      s2;
  case((s as DAE.IDXMOD(li,m))::inSubs,depth)
    equation
      //s1 = prettyPrintSubs(inSubs);
      s2  = prettyPrintMod(m,depth+1);
      s1 = "["+& Util.stringDelimitList(Util.listMap(li,intString),",")+&"]" +& " = " +& s2;
    then
      s1;
end matchcontinue;
end prettyPrintSubs;

public function prettyPrintSubmod "
Prints a readable format of a sub-modifier, used in error reporting for built-in classes"
  input DAE.SubMod inSub;
  output String str;
algorithm str := matchcontinue(inSub)
  local
    String s1,s2,id,s3;
    DAE.Mod m;
    list<Integer> li;
    Boolean fp;
    list<tuple<SCode.Element, DAE.Mod>> elist;
    
  case(DAE.NAMEMOD(id,(m as DAE.REDECL(fp, elist))))
    equation
      s1 = Util.stringDelimitList(Util.listMap(Util.listMap(elist, Util.tuple21), SCode.printElementStr), ", ");      
      s2 = id +& "(redeclare " +& Util.if_(fp,"final ","") +& s1 +& ")";
    then
      s2;
      
  case(DAE.NAMEMOD(id,m))
    equation
      s2  = prettyPrintMod(m,0);
      s2 = Util.if_(stringLength(s2) == 0, ""," = " +& s2);
      s2 = id +& s2;
    then
      s2;
      
  case(DAE.IDXMOD(li,m))
    equation
      s2  = prettyPrintMod(m,0);
      s1 = "["+& Util.stringDelimitList(Util.listMap(li,intString),",")+&"]" +& " = " +& s2;
    then
      s1;
end matchcontinue;
end prettyPrintSubmod;

public function printSubs1Str "function: printSubs1Str
  Helper function to printModStr"
  input list<DAE.SubMod> inTypesSubModLst;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inTypesSubModLst)
    local
      Ident s1;
      list<Ident> res;
      DAE.SubMod x;
      list<DAE.SubMod> xs;
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
  Helper function to printSubs1Str"
  input DAE.SubMod inSubMod;
  output String outString;
algorithm
  outString := matchcontinue (inSubMod)
    local
      Ident mod_str,res,n,str;
      DAE.Mod mod;
      list<Integer> ss;
    case DAE.NAMEMOD(ident = n,mod = mod)
      equation
        mod_str = printModStr(mod);
        res = stringAppend(n, mod_str);
      then
        res;
    case DAE.IDXMOD(integerLst = ss,mod = mod)
      equation
        str = printSubscriptsStr(ss);
        mod_str = printModStr(mod);
        res = stringAppend(str, mod_str);
      then
        res;
  end matchcontinue;
end printSubStr;

protected function printSubscriptsStr "function: printSubscriptsStr
  Helper function to printSubStr"
  input list<Integer> inIntegerLst;
  output String outString;
algorithm
  outString := matchcontinue (inIntegerLst)
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
        res = System.stringAppendList({"[",s,str,"]"});
      then
        res;
  end matchcontinue;
end printSubscriptsStr;

protected function printSubscripts2Str "function: printSubscripts2Str
  Helper function to printSubscriptsStr"
  input list<Integer> inIntegerLst;
  output String outString;
algorithm
  outString := matchcontinue (inIntegerLst)
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
        res = System.stringAppendList({",",s,str});
      then
        res;
  end matchcontinue;
end printSubscripts2Str;

protected function printEqmodStr
"function: printEqmodStr
  Helper function to printModStr"
  input Option<DAE.EqMod> inTypesEqModOption;
  output String outString;
algorithm
  outString := matchcontinue (inTypesEqModOption)
    local
      Ident str,str2,e_val_str,res;
      DAE.Exp e;
      Values.Value e_val;
      DAE.Properties prop;
    case NONE() then "";
    case SOME(DAE.TYPED(e,SOME(e_val),prop,_))
      equation
        str = Exp.printExpStr(e);
        str2 = Types.printPropStr(prop);
        e_val_str = ValuesUtil.valString(e_val);
        res = System.stringAppendList({" = (typed)",str," ",str2,", E_VALUE: ",e_val_str});
      then
        res;
    case SOME(DAE.TYPED(e,NONE(),prop,_))
      equation
        str = Exp.printExpStr(e);
        str2 = Types.printPropStr(prop);
        res = System.stringAppendList({" = (typed)",str,str2});
      then
        res;
    case SOME(DAE.UNTYPED(e))
      local Absyn.Exp e;
      equation
        str = Dump.printExpStr(e);
        res = stringAppend(" =(untyped) ", str);
      then
        res;
    case(_) equation print(" ---printEqmodStr FAILED--- "); then fail();
  end matchcontinue;
end printEqmodStr;

public function renameTopLevelNamedSubMod
  input DAE.Mod mod;
  input String oldIdent;
  input String newIdent;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue (mod,oldIdent,newIdent)
    local
      Boolean finalPrefix;
      Absyn.Each each_;
      list<DAE.SubMod> subModLst;
      Option<DAE.EqMod> eqModOption;
    case (DAE.MOD(finalPrefix,each_,subModLst,eqModOption),oldIdent,newIdent)
      equation
        subModLst = Util.listMap2(subModLst, renameNamedSubMod, oldIdent, newIdent);
      then DAE.MOD(finalPrefix,each_,subModLst,eqModOption);
    case (mod,_,_) then mod;
  end matchcontinue;
end renameTopLevelNamedSubMod;

public function renameNamedSubMod
  input DAE.SubMod submod;
  input String oldIdent;
  input String newIdent;
  output DAE.SubMod outMod;
algorithm
  outMod := matchcontinue (submod,oldIdent,newIdent)
    local
      DAE.Mod mod;
      String id;
    case (DAE.NAMEMOD(id,mod),oldIdent,newIdent)
      equation
        true = id ==& oldIdent;
      then DAE.NAMEMOD(newIdent,mod);
    case (submod,_,_) then submod;
  end matchcontinue;
end renameNamedSubMod;

public function emptyModOrEquality
  input DAE.Mod mod;
  output Boolean b;
algorithm
  b := matchcontinue mod
    case DAE.NOMOD() then true;
    case DAE.MOD(subModLst={}) then true;
    case _ then false;
  end matchcontinue;
end emptyModOrEquality;

protected function getAllIndexesFromIdxMods
"@author: adrpo
  Go through the entire list of submods and 
  returns a list<tuple<string,mod>> where
  string created from indexes delimited by DOT."
  input list<DAE.SubMod> inSubModLst;
  output list<tuple<String,DAE.SubMod>> indexes;
algorithm
  indexes := matchcontinue(inSubModLst)
    local 
      list<DAE.SubMod> rest;
      list<Integer> il;
      DAE.SubMod submod;
      String str;
      list<tuple<String,DAE.SubMod>> lst;
      
    // empty case
    case({}) then {};
    // index modifs
    case((submod as DAE.IDXMOD(integerLst = il))::rest)
      equation
        lst = getAllIndexesFromIdxMods(rest);
        // from an index list {1, 2} make a string such as 1.2 
        str = System.stringAppendList(Util.listMap(il, intStringDot));
      then
        (str,submod)::lst;
    // ignore named modifs
    case(_::rest)
      equation
        lst = getAllIndexesFromIdxMods(rest);
      then
        lst;
  end matchcontinue;
end getAllIndexesFromIdxMods;

protected function intStringDot
  input Integer i;
  output String str;
algorithm
  str := intString(i) +& ".";
end intStringDot;

protected function isPrefixOf
  input tuple<String, DAE.SubMod> indexSubMod;
  input String idx;
  output Boolean isPrefix;
algorithm
  isPrefix := matchcontinue(indexSubMod, idx)
    local
      String i;
      Integer len1, len2;
      
    case ((i, _), idx)
      equation
        len1 = stringLength(i);
        len2 = stringLength(idx);
        // either one of them is a substring of the other
        true = boolOr(0 == System.strncmp(i, idx, len1), 0 == System.strncmp(idx, i, len2));  
      then true;
    case (_, _) then false;        
  end matchcontinue; 
end isPrefixOf;

protected function getOverlap
  input list<tuple<String, DAE.SubMod>> indexes;
  output list<tuple<String, DAE.SubMod>> overlap;
algorithm
  overlap := matchcontinue(indexes)
    local
      list<tuple<String, DAE.SubMod>> rest, lst, lst1, lst2;
      tuple<String, DAE.SubMod> t;
      String idx;
      DAE.SubMod s;
      
    // empty cases
    case ({}) then {};
    case ((t as (idx, s))::rest)
      equation
        lst1 = Util.listSelect1(rest, idx, isPrefixOf);
        lst1 = Util.if_(listLength(lst1)==0, lst1, t::lst1);
        lst2 = getOverlap(rest);
        lst = listAppend(lst1, lst2);
      then
        lst;
  end matchcontinue; 
end getOverlap;

public function checkIdxModsForNoOverlap
"@author: adrpo
  This function checks if idx modifications do not overlap.
  If they do an error message is printed and this function fails.
  Example:
  class A Real x[2,2]; end A;
  A a(x[2] = {1.0,3.0}, x[2,1] = 2.0);"
  input DAE.Mod inMod;
  input Prefix.Prefix inPrefix;
  input Option<Absyn.Info> infoOpt;
algorithm
  _ := matchcontinue(inMod, inPrefix, infoOpt)
    local
      list<DAE.SubMod> subModLst;
      list<tuple<String, DAE.SubMod>> indexes, overlap;
      Prefix.Prefix pre;
      String str1, str2, str3;
      DAE.EqMod eqMod;
      DAE.Properties props; 
    
    // no modifications
    case(DAE.NOMOD(), _, _) then ();

    // no submodifications
    case(DAE.MOD(subModLst={}), _, _) then ();

    // one submodification with no eqmod cannot generate overlap
    case(DAE.MOD(subModLst={DAE.IDXMOD(mod=_)}, eqModOption=NONE()), _, _) then ();

    // if eqmod is an array and we have indexmods, we have overlap
    case(DAE.MOD(subModLst=subModLst, eqModOption=SOME(eqMod)), pre, infoOpt)
      equation
        // we have properties
        DAE.TYPED(properties = props) = eqMod;
        // they are an array!
        true = Types.isPropArray(props);
        // we have at least 1 index mod 
        (indexes as _::_) = getAllIndexesFromIdxMods(subModLst);
        str3 = PrefixUtil.printPrefixStrIgnoreNoPre(pre);
        // now try to read this very fast ;)        
        str1 = Util.stringDelimitList(
                 Util.listMap1(
                   Util.listMap(
                     Util.listMap(
                       indexes, 
                       Util.tuple22), 
                     prettyPrintSubmod),
                   Util.stringAppendReverse,
                   str3),  
                 ", ");
        str1 = "(" +& str1 +& ")";
        str2 = str3 +& "=" +& Types.unparseEqMod(eqMod);
        // generate a warning
        Error.addMessageOrSourceMessage(Error.MODIFICATION_AND_MODIFICATION_INDEX_OVERLAP, {str1, str2, str3}, infoOpt);
      then ();

    // modifications, no overlap
    case(DAE.MOD(subModLst=subModLst), _, _)
      equation
        // now how the heck are we verifying for overlap?
        // first try: (if you know a better solution, then, BY ANY MEANS, please implement it here) 
        //  from index list generate strings, i.e. 1.2.3., 1.2.4.
        //  if any of the strings is a prefix of another, we have an overlap!
        indexes = getAllIndexesFromIdxMods(subModLst);
        // get the overlap
        {} = getOverlap(indexes);
      then
        ();
    // modifications, overlap, source message
    case(DAE.MOD(subModLst=subModLst), pre, infoOpt)
      equation
        indexes = getAllIndexesFromIdxMods(subModLst);
        // get the overlap
        overlap = getOverlap(indexes);
        str2 = PrefixUtil.printPrefixStrIgnoreNoPre(pre);
        // now try to read this very fast ;)        
        str1 = Util.stringDelimitList(
                 Util.listMap1(
                   Util.listMap(
                     Util.listMap(
                       overlap, 
                       Util.tuple22), 
                     prettyPrintSubmod),
                   Util.stringAppendReverse,
                   str2),  
                 ", ");
        str1 = "(" +& str1 +& ")";
        // generate a warning
        Error.addMessageOrSourceMessage(Error.MODIFICATION_INDEX_OVERLAP, {str1, str2}, infoOpt);
      then
        ();
  end matchcontinue;
end checkIdxModsForNoOverlap;

end Mod;

