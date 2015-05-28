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

encapsulated package Mod
" file:        Mod.mo
  package:     Mod
  description: Modification handling

  RCS: $Id$

  Modifications are simply the same kind of modifications used in the Absyn module.

  This module contains functions for handling DAE.Mod, which is very similar to
  SCode.Mod. The main difference is that it uses DAE.Exp for the expressions.
  Expressions stored here are prefixed and typechecked.
"


public import Absyn;
public import DAE;
public import FCore;
public import FGraph;
public import Prefix;
public import SCode;
public import InnerOuter;
public import ComponentReference;

protected type InstanceHierarchy = InnerOuter.InstHierarchy "an instance hierarchy";

protected import Ceval;
protected import ClassInf;
protected import Config;
protected import Dump;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import Inst;
protected import InstUtil;
protected import List;
protected import PrefixUtil;
protected import Print;
protected import Static;
protected import Types;
protected import Util;
protected import Values;
protected import ValuesUtil;
protected import System;
protected import SCodeDump;
protected import Lookup;
protected import SCodeUtil;

public uniontype ModScope
  "Used to know where a modifier came from, for error reporting."
  record COMPONENT
    String name;
  end COMPONENT;

  record EXTENDS
    Absyn.Path path;
  end EXTENDS;

  record DERIVED
    Absyn.Path path;
  end DERIVED;
end ModScope;

protected
uniontype FullMod "used for error reporting"
  record MOD "the fully qualified cref and the mod, only used for redeclare"
    DAE.ComponentRef cref;
    DAE.Mod mod;
  end MOD;

  record SUB_MOD "the fully qualified cref and the sub mod for all other mods"
    DAE.ComponentRef cref;
    DAE.SubMod subMod;
  end SUB_MOD;
end FullMod;

protected type SubMod = DAE.SubMod;
protected type EqMod = DAE.EqMod;

public function elabMod "
  This function elaborates on the expressions in a modification and
  turns them into global expressions.  This is done because the
  expressions in modifications must be elaborated on in the context
  they are provided in, and not the context they are used in."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input SCode.Mod inMod;
  input Boolean inBoolean;
  input ModScope inModScope;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Mod outMod;
algorithm
  (outCache,outMod) := match(inCache,inEnv,inIH,inPrefix,inMod,inBoolean,inModScope,inInfo)
    local
      Boolean impl;
      SCode.Final finalPrefix;
      list<DAE.SubMod> subs_1;
      FCore.Graph env;
      Prefix.Prefix pre;
      SCode.Mod m;
      SCode.Each each_;
      list<SCode.SubMod> subs;
      DAE.Exp e_1,e_2;
      DAE.Properties prop;
      Option<Values.Value> e_val;
      Absyn.Exp e;
      tuple<SCode.Element, DAE.Mod> el_mod;
      SCode.Element elem;
      FCore.Cache cache;
      InstanceHierarchy ih;
      SourceInfo info;
      String str;

    // no modifications
    case (cache,_,_,_,SCode.NOMOD(),_,_,_) then (cache,DAE.NOMOD());

    // no top binding
    case (cache,env,ih,pre,(SCode.MOD(finalPrefix = finalPrefix,eachPrefix = each_,subModLst = subs,binding = NONE())),impl,_,info)
      equation
        (cache,subs_1) = elabSubmods(cache, env, ih, pre, subs, impl, inModScope, info);
      then
        (cache,DAE.MOD(finalPrefix,each_,subs_1,NONE()));

    // Only elaborate expressions with non-delayed type checking, see SCode.MOD.
    case (cache,env,ih,pre,(SCode.MOD(finalPrefix = finalPrefix,eachPrefix = each_,subModLst = subs,binding = SOME(e), info=info)),impl,_,_)
      equation
        (cache,subs_1) = elabSubmods(cache, env, ih, pre, subs, impl, inModScope, info);
        // print("Mod.elabMod: calling elabExp on mod exp: " + Dump.printExpStr(e) + " in env: " + FGraph.printGraphPathStr(env) + "\n");
        (cache,e_1,prop,_) = Static.elabExp(cache, env, e, impl, NONE(), Config.splitArrays(), pre, info); // Vectorize only if arrays are expanded
        (cache, e_1, prop) = Ceval.cevalIfConstant(cache, env, e_1, prop, impl, info);
        (e_val, cache) = elabModValue(cache, env, e_1, prop, impl, info);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre)
        "Bug: will cause elaboration of parameters without value to fail,
         But this can be ok, since a modifier is present, giving it a value from outer modifications.." ;
      then
        (cache,DAE.MOD(finalPrefix,each_,subs_1,SOME(DAE.TYPED(e_2,e_val,prop,e,info))));

    // Delayed type checking
    case (cache,env,ih,pre,(SCode.MOD(finalPrefix = finalPrefix,eachPrefix = each_,subModLst = subs,binding = SOME(e), info = info)),impl,_,_)
      equation
        // print("Mod.elabMod: delayed mod : " + Dump.printExpStr(e) + " in env: " + FGraph.printGraphPathStr(env) + "\n");
        (cache,subs_1) = elabSubmods(cache, env, ih, pre, subs, impl, inModScope, info);
      then
        (cache,DAE.MOD(finalPrefix,each_,subs_1,SOME(DAE.UNTYPED(e,info))));

    // redeclarations
    case (cache,env,ih,pre,(SCode.REDECL(finalPrefix = finalPrefix, eachPrefix = each_, element = elem)),impl,_,info)
      equation
        //elist_1 = Inst.addNomod(elist);
        (el_mod) = elabModRedeclareElement(cache,env,ih,pre,finalPrefix,elem,impl,inModScope,info);
      then
        (cache,DAE.REDECL(finalPrefix,each_,{el_mod}));

    /*/ failure
    case (cache,env,ih,pre,m,impl,info)
      equation
        str = "- Mod.elabMod  failed: " +
              SCodeDump.printModStr(m) +
              " in env: " +
              FGraph.printGraphStr(env);
        fprintln(Flags.FAILTRACE, str);
      then
        fail();*/
  end match;
end elabMod;

public function elabModForBasicType "
  Same as elabMod, but if a named Mod is not part of a basic type, fail instead."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input SCode.Mod inMod;
  input Boolean inBoolean;
  input ModScope inModScope;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Mod outMod;
algorithm
  checkIfModsAreBasicTypeMods(inMod);
  (outCache,outMod) := elabMod(inCache,inEnv,inIH,inPrefix,inMod,inBoolean,inModScope,info);
end elabModForBasicType;

protected function checkIfModsAreBasicTypeMods "
  Verifies that a list of submods only have named modifications that could be
  used for basic types."
  input SCode.Mod mod;
algorithm
  _ := match mod
    local
      list<SCode.SubMod> subs;
    case SCode.NOMOD() then ();
    case SCode.MOD(subModLst = subs)
      equation
        checkIfSubmodsAreBasicTypeMods(subs);
      then ();
  end match;
end checkIfModsAreBasicTypeMods;

protected function checkIfSubmodsAreBasicTypeMods "
  Verifies that a list of submods only have named modifications that could be
  used for basic types."
  input list<SCode.SubMod> inSubs;
algorithm
  _ := match inSubs
    local
      SCode.Mod mod;
      String ident;
      list<SCode.SubMod> subs;

    case {} then ();
    case SCode.NAMEMOD(ident = ident)::subs
      equation
        true = ClassInf.isBasicTypeComponentName(ident);
        checkIfSubmodsAreBasicTypeMods(subs);
      then ();
  end match;
end checkIfSubmodsAreBasicTypeMods;

protected function elabModRedeclareElement
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input SCode.Final finalPrefix;
  input SCode.Element inElt;
  input Boolean impl;
  input ModScope inModScope;
  input SourceInfo info;
  output tuple<SCode.Element, DAE.Mod> modElts "the elaborated modifiers";
algorithm
  modElts := matchcontinue(inCache,inEnv,inIH,inPrefix,finalPrefix,inElt,impl,inModScope,info)
    local
      FCore.Cache cache; FCore.Graph env; Prefix.Prefix pre;
      SCode.Final f,fi;
      SCode.Replaceable repl;
      SCode.Partial p;
      SCode.Encapsulated enc;
      SCode.Visibility vis;
      SCode.Redeclare redecl;
      Absyn.InnerOuter io;
      SCode.Ident cn,compname,bcn;
      SCode.Restriction restr;
      Absyn.TypeSpec tp,tp1;
      DAE.Mod emod;
      SCode.Attributes attr;
      SCode.Mod mod, modOriginal;
      Option<Absyn.Exp> cond;
      SourceInfo i;
      InstanceHierarchy ih;
      SCode.Attributes attr1;
      list<SCode.Enum> enumLst;
      SCode.Comment cmt,comment;
      SCode.Element element, c;
      SCode.Prefixes prefixes;

    /*/ search for target class locally and if it is a derived with no modifications, use it
    // replaceable package Medium = Modelica.Media.Air.MoistAir constrainedby Modelica.Media.Interfaces.PartialMedium;
    // modifier: redeclare Medium = Medium
    case(cache,env,ih,pre,_,
      SCode.CLASS(cn,
        prefixes as SCode.PREFIXES(vis,redecl,fi,io,repl),enc,p,restr,SCode.DERIVED(Absyn.TPATH(Absyn.IDENT(bcn), NONE()),mod,attr1),cmt,i),_,_,_)
      equation
        true = stringEq(cn, bcn);
        (c, _) = Lookup.lookupClassLocal(env, bcn);
        tp = SCode.getDerivedTypeSpec(c);
        c = SCode.mergeWithOriginal(SCode.CLASS(cn,SCode.PREFIXES(vis,redecl,fi,io,repl),enc,p,restr,SCode.DERIVED(tp,mod,attr1),cmt,i), c);
        SCode.CLASS(cn,SCode.PREFIXES(vis,redecl,fi,io,repl),enc,p,restr,SCode.DERIVED(tp,mod,attr1),cmt,i) = c;
        (cache,emod) = elabMod(cache,env,ih,pre,mod,impl,inModScope,info);
        (cache,tp1) = elabModQualifyTypespec(cache,env,ih,pre,impl,info,cn,tp);
        // unelab mod so we get constant evaluation of parameters
        mod = unelabMod(emod);
      then
        ((SCode.CLASS(cn,SCode.PREFIXES(vis,redecl,fi,io,repl),enc,p,restr,SCode.DERIVED(tp1,mod,attr1),cmt,i),emod));*/

    // Only derived classdefinitions supported in redeclares for now.
    // TODO: What is allowed according to spec? adrpo: 2011-06-28: is not decided yet,
    //       but i think only derived even if in the Modelica.Media we have redeclare-as-element
    //       replacing entire functions with PARTS and everything, so i added the case below
    case(cache,env,ih,pre,_,
      SCode.CLASS(cn,
        prefixes as SCode.PREFIXES(vis,redecl,fi,io,repl),enc,p,restr,SCode.DERIVED(tp,mod,attr1),cmt,i),_,_,_)
      equation
        // merge modifers from the component to the modifers from the constrained by
        mod = SCode.mergeModifiers(mod, SCodeUtil.getConstrainedByModifiers(prefixes));
        (cache,emod) = elabMod(cache,env,ih,pre,mod,impl,inModScope,info);
        (_,tp1) = elabModQualifyTypespec(cache,env,ih,pre,impl,info,cn,tp);
        // unelab mod so we get constant evaluation of parameters
        mod = unelabMod(emod);
      then
        ((SCode.CLASS(cn,SCode.PREFIXES(vis,redecl,fi,io,repl),enc,p,restr,SCode.DERIVED(tp1,mod,attr1),cmt,i),emod));

    // replaceable type E=enumeration(e1,...,en), E=enumeration(:)
    case(_,_,_,_,_,
      SCode.CLASS(cn,
        SCode.PREFIXES(vis,redecl,fi,io,repl),enc,p,restr,SCode.ENUMERATION(enumLst),cmt,i),_,_,_)
      then
        ((SCode.CLASS(cn,SCode.PREFIXES(vis,redecl,fi,io,repl),enc,p,restr,SCode.ENUMERATION(enumLst),cmt,i),DAE.NOMOD()));

    // redeclare of component declaration
    case(cache,env,ih,pre,_,SCode.COMPONENT(compname,prefixes as SCode.PREFIXES(vis,redecl,fi,io,repl),attr,tp,mod,cmt,cond,i),_,_,_)
      equation
        // merge modifers from the component to the modifers from the constrained by
        mod = SCode.mergeModifiers(mod, SCodeUtil.getConstrainedByModifiers(prefixes));
        (cache,emod) = elabMod(cache,env,ih,pre,mod,impl,inModScope,info);
        (_,tp1) = elabModQualifyTypespec(cache,env,ih,pre,impl,info,compname,tp);
        // unelab mod so we get constant evaluation of parameters
        mod = unelabMod(emod);
      then
        ((SCode.COMPONENT(compname,SCode.PREFIXES(vis,redecl,fi,io,repl),attr,tp1,mod,cmt,cond,i),emod));

    // redeclare failure?
    case(_,_,_,_,_,element,_,_,_)
      equation
        print("Unhandled element redeclare (we keep it as it is!): " + SCodeDump.unparseElementStr(element,SCodeDump.defaultOptions) + "\n");
      then
        ((element,DAE.NOMOD()));

  end matchcontinue;
end elabModRedeclareElement;

protected function elabModQualifyTypespec
"Help function to elabModRedeclareElements.
 This function makes sure that type specifiers, i.e. class names, in redeclarations are looked up in the correct environment.
 This is achieved by making them fully qualified."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input Boolean impl;
  input SourceInfo info;
  input Absyn.Ident name;
  input Absyn.TypeSpec tp;
  output FCore.Cache outCache;
  output Absyn.TypeSpec outTp;
algorithm
  (outCache,outTp) := match(inCache,inEnv,inIH,inPrefix,impl,info,name,tp)
      local
        FCore.Cache cache; FCore.Graph env;
        Absyn.ArrayDim dims;
        Absyn.Path p,p1;
        Absyn.ComponentRef cref;
        DAE.Dimensions edims;
        InnerOuter.InstHierarchy ih;
        Prefix.Prefix pre;

    // no array dimensions
    case (cache, env, _, _, _, _, _, Absyn.TPATH(p,NONE()))
      equation
        (cache,p1) = Inst.makeFullyQualified(cache,env,p);
    then
      (cache,Absyn.TPATH(p1,NONE()));

    // some array dimensions, elaborate them!
    case (cache, env, ih, pre, _, _, _, Absyn.TPATH(p,SOME(dims)))
      equation
        cref = Absyn.CREF_IDENT(name,{});
        (cache,edims) = InstUtil.elabArraydim(cache, env, cref, p, dims, NONE(), impl, NONE(), true, false, pre, info, {});
        (cache,edims) = PrefixUtil.prefixDimensions(cache, env, ih, pre, edims);
        dims = List.map(edims, Expression.unelabDimension);
        (cache,p1) = Inst.makeFullyQualified(cache,env,p);
    then
      (cache,Absyn.TPATH(p1,SOME(dims)));

  end match;
end elabModQualifyTypespec;

protected function elabModValue
  "Helper function to elabMod. Tries to constant evaluate a modifier expression."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp inExp;
  input DAE.Properties inProp;
  input Boolean inImpl;
  input SourceInfo inInfo;
  output Option<Values.Value> outValue = NONE();
  output FCore.Cache outCache = inCache;
protected
  Integer err_count;
  Absyn.Msg msg;
  DAE.Const c;
  Values.Value v;
algorithm
  c := Types.propAllConst(inProp);

  // If the expression is a parameter or constant expression:
  if not Types.constIsVariable(c) then
    // Show error messages from ceval only if the expression is constant.
    msg := Absyn.optMsg(Types.constIsConst(c) and not inImpl, inInfo);
    err_count := Error.getNumErrorMessages();

    try
      (_, v) := Ceval.ceval(inCache, inEnv, inExp, false, NONE(), msg, 0);
      outValue := SOME(v);
    else
      // Fail if ceval gave an error. Except if the expression contains a
      // function call, because we don't handle function parameter modifiers
      // correctly which causes issues with CevalFunction.
      if err_count <> Error.getNumErrorMessages() and not
          Expression.containsAnyCall(inExp) then
        fail();
      end if;
    end try;
  end if;
end elabModValue;

public function unelabMod
"Transforms Mod back to SCode.Mod, loosing type information."
  input DAE.Mod inMod;
  output SCode.Mod outMod;
algorithm
  outMod:=
  matchcontinue (inMod)
    local
      list<SCode.SubMod> subs_1;
      DAE.Mod m,mod;
      SCode.Final finalPrefix;
      SCode.Each each_;
      list<DAE.SubMod> subs;
      Absyn.Exp e,e_1,absynExp;
      DAE.Properties p;
      SCode.Element elem;
      DAE.Exp dexp;
      String str;
      SourceInfo info;
      Values.Value v;

    case (DAE.NOMOD()) then SCode.NOMOD();
    case ((DAE.MOD(finalPrefix = finalPrefix,eachPrefix = each_,subModLst = subs,eqModOption = NONE())))
      equation
        subs_1 = unelabSubmods(subs);
      then
        SCode.MOD(finalPrefix,each_,subs_1,NONE(),Absyn.dummyInfo);

    case ((DAE.MOD(finalPrefix = finalPrefix,eachPrefix = each_,subModLst = subs,eqModOption = SOME(DAE.UNTYPED(e,info)))))
      equation
        subs_1 = unelabSubmods(subs);
      then
        SCode.MOD(finalPrefix,each_,subs_1,SOME(e),info);

    // use the constant first!
    case ((DAE.MOD(finalPrefix = finalPrefix,eachPrefix = each_,subModLst = subs,
                        eqModOption = SOME(DAE.TYPED(modifierAsValue = SOME(v), info = info)))))
      equation
        //es = ExpressionDump.printExpStr(e);
        subs_1 = unelabSubmods(subs);
        e_1 = Expression.unelabExp(ValuesUtil.valueExp(v));
      then
        SCode.MOD(finalPrefix,each_,subs_1,SOME(e_1),info); // default typechecking non-delayed

    /* / use the expression second
    case ((DAE.MOD(finalPrefix = finalPrefix,eachPrefix = each_,subModLst = subs,
                        eqModOption = SOME(DAE.TYPED(modifierAsExp = dexp, info = info)))))
      equation
        //es = ExpressionDump.printExpStr(e);
        subs_1 = unelabSubmods(subs);
        e_1 = Expression.unelabExp(dexp);
      then
        SCode.MOD(finalPrefix,each_,subs_1,SOME((e_1,false)),info); // default typechecking non-delayed */

    case ((DAE.MOD(finalPrefix = finalPrefix,eachPrefix = each_,subModLst = subs,
                        eqModOption = SOME(DAE.TYPED(_,_,_,absynExp,info)))))
      equation
        //es = ExpressionDump.printExpStr(e);
        subs_1 = unelabSubmods(subs);
        e_1 = absynExp; //Expression.unelabExp(e);
      then
        SCode.MOD(finalPrefix,each_,subs_1,SOME(e_1),info);

    case ((DAE.REDECL(finalPrefix = finalPrefix,eachPrefix = each_,tplSCodeElementModLst = {(elem, _)})))
      then
        SCode.REDECL(finalPrefix,each_,elem);

    case (mod)
      equation
        str = "Mod.elabUntypedMod failed: " + printModStr(mod) + "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();
  end matchcontinue;
end unelabMod;

protected function unelabSubmods
"Helper function to unelabMod."
  input list<DAE.SubMod> inTypesSubModLst;
  output list<SCode.SubMod> outSCodeSubModLst;
algorithm
  outSCodeSubModLst:=
  match (inTypesSubModLst)
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
  end match;
end unelabSubmods;

protected function unelabSubmod
"This function unelaborates on a submodification."
  input DAE.SubMod inSubMod;
  output list<SCode.SubMod> outSCodeSubModLst;
algorithm
  outSCodeSubModLst:=
  match (inSubMod)
    local
      SCode.Mod m_1;
      String i;
      DAE.Mod m;
      list<Absyn.Subscript> ss_1;
      list<Integer> ss;
    case (DAE.NAMEMOD(ident = i,mod = m))
      equation
        m_1 = unelabMod(m);
      then
        {SCode.NAMEMOD(i,m_1)};
  end match;
end unelabSubmod;

protected function unelabSubscript
  input list<Integer> inIntegerLst;
  output list<SCode.Subscript> outSCodeSubscriptLst;
algorithm
  outSCodeSubscriptLst:=
  match (inIntegerLst)
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
  end match;
end unelabSubscript;

public function updateMod
"This function updates an untyped modification to a typed one, by looking
  up the type of the modifier in the environment and update it."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input DAE.Mod inMod;
  input Boolean inBoolean;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Mod outMod;
algorithm
  (outCache,outMod) := matchcontinue (inCache,inEnv,inIH,inPrefix,inMod,inBoolean,inInfo)
    local
      Boolean impl;
      SCode.Final f;
      DAE.Mod m;
      list<DAE.SubMod> subs_1,subs;
      DAE.Exp e_1,e_2;
      DAE.Properties prop,p;
      Option<Values.Value> e_val;
      FCore.Graph env;
      Prefix.Prefix pre;
      SCode.Each each_;
      Absyn.Exp e;
      Option<Absyn.Exp> eOpt;
      FCore.Cache cache;
      InstanceHierarchy ih;
      String str;
      SourceInfo info;

    case (cache,_,_,_,DAE.NOMOD(),_,_) then (cache,DAE.NOMOD());

    case (cache,_,_,_,(m as DAE.REDECL()),_,_) then (cache,m);

    case (cache,env,ih,pre,(DAE.MOD(finalPrefix = f,eachPrefix = each_,subModLst = subs,eqModOption = SOME(DAE.UNTYPED(e,info)))),impl,_)
      equation
        (cache,subs_1) = updateSubmods(cache, env, ih, pre, subs, impl, info);
        (cache,e_1,prop,_) = Static.elabExp(cache, env, e, impl,NONE(), true, pre, info);
        (cache, e_1, prop) = Ceval.cevalIfConstant(cache, env, e_1, prop, impl, info);
        (e_val, cache) = elabModValue(cache,env,e_1,prop,impl,info);
        (cache,e_2) = PrefixUtil.prefixExp(cache, env, ih, e_1, pre);
        if Flags.isSet(Flags.UPDMOD) then
          Debug.trace("Updated mod: ");
          Debug.traceln(printModStr(DAE.MOD(f,each_,subs_1,SOME(DAE.TYPED(e_2,NONE(),prop,e,info)))));
        end if;
      then
        (cache,DAE.MOD(f,each_,subs_1,SOME(DAE.TYPED(e_2,e_val,prop,e,info))));

    case (cache,env,ih,pre,DAE.MOD(finalPrefix = f,eachPrefix = each_,subModLst = subs,eqModOption = SOME(DAE.TYPED(e_1,e_val,p,e,info))),impl,_)
      equation
        (cache,subs_1) = updateSubmods(cache, env, ih, pre, subs, impl, info);
      then
        (cache,DAE.MOD(f,each_,subs_1,SOME(DAE.TYPED(e_1,e_val,p,e,info))));

    case (cache,env,ih,pre,DAE.MOD(finalPrefix = f,eachPrefix = each_,subModLst = subs,eqModOption = NONE()),impl,info)
      equation
        (cache,subs_1) = updateSubmods(cache, env, ih, pre, subs, impl, info);
      then
        (cache,DAE.MOD(f,each_,subs_1,NONE()));

    case (_,_,_,_,m,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        str = printModStr(m);
        Debug.traceln("- Mod.updateMod failed mod: " + str);
      then fail();
  end matchcontinue;
end updateMod;

protected function updateSubmods ""
    input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input list<DAE.SubMod> inTypesSubModLst;
  input Boolean inBoolean;
  input SourceInfo info;
  output FCore.Cache outCache;
  output list<DAE.SubMod> outTypesSubModLst;
algorithm
  (outCache,outTypesSubModLst):=
  match (inCache,inEnv,inIH,inPrefix,inTypesSubModLst,inBoolean,info)
    local
      Boolean impl;
      list<DAE.SubMod> x_1,xs_1,res,xs;
      FCore.Graph env;
      Prefix.Prefix pre;
      DAE.SubMod x;
      FCore.Cache cache;
      InstanceHierarchy ih;

    case (cache,_,_,_,{},_,_) then (cache,{});  /* impl */
    case (cache,env,ih,pre,(x :: xs),impl,_)
      equation
        (cache,x_1) = updateSubmod(cache, env, ih, pre, x, impl, info);
        (cache,xs_1) = updateSubmods(cache, env, ih, pre, xs, impl, info);
        res = listAppend(x_1, xs_1);
      then
        (cache,res);
  end match;
end updateSubmods;

protected function updateSubmod " "
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input DAE.SubMod inSubMod;
  input Boolean inBoolean;
  input SourceInfo info;
  output FCore.Cache outCache;
  output list<DAE.SubMod> outTypesSubModLst;
algorithm
  (outCache,outTypesSubModLst):=
  match (inCache,inEnv,inIH,inPrefix,inSubMod,inBoolean,info)
    local
      DAE.Mod m_1,m;
      FCore.Graph env;
      Prefix.Prefix pre;
      String i;
      Boolean impl;
      FCore.Cache cache;
      list<Integer> idxmod;
      InstanceHierarchy ih;

    case (cache,env,ih,pre,DAE.NAMEMOD(ident = i,mod = m),impl,_)
      equation
        (cache,m_1) = updateMod(cache, env, ih, pre, m, impl, info);
      then
        (cache,{DAE.NAMEMOD(i,m_1)});

  end match;
end updateSubmod;

public function elabUntypedMod "This function is used to convert SCode.Mod into Mod, without
  adding correct type information. Instead, a undefined type will be
  given to the modification. This is used when modifications of e.g.
  elements in base classes used. For instance,
  model test extends A(x=y); end test; // both x and y are defined in A
  The modifier x=y must be merged with outer modifiers, thus it needs
  to be converted to Mod.
  Notice that the correct type information must be updated later on."
  input SCode.Mod inMod;
  input FCore.Graph inEnv;
  input Prefix.Prefix inPrefix;
  input ModScope inModScope;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue (inMod,inEnv,inPrefix,inModScope)
    local
      list<DAE.SubMod> subs_1;
      SCode.Mod m,mod;
      SCode.Final finalPrefix;
      SCode.Each each_;
      list<SCode.SubMod> subs;
      FCore.Graph env;
      Prefix.Prefix pre;
      Absyn.Exp e;
      SCode.Element elem;
      String s;
      SourceInfo info;
    case (SCode.NOMOD(),_,_,_) then DAE.NOMOD();
    case ((SCode.MOD(finalPrefix = finalPrefix,eachPrefix = each_,subModLst = subs,binding = NONE())),env,pre,_)
      equation
        subs_1 = elabUntypedSubmods(subs, env, pre, inModScope);
      then
        DAE.MOD(finalPrefix,each_,subs_1,NONE());
    case ((SCode.MOD(finalPrefix = finalPrefix,eachPrefix = each_,subModLst = subs,binding = SOME(e),info = info)),env,pre,_)
      equation
        subs_1 = elabUntypedSubmods(subs, env, pre, inModScope);
      then
        DAE.MOD(finalPrefix,each_,subs_1,SOME(DAE.UNTYPED(e,info)));
    case ((SCode.REDECL(finalPrefix = finalPrefix,eachPrefix = each_, element = elem)),_,_,_)
      then
        DAE.REDECL(finalPrefix,each_,{(elem, DAE.NOMOD())});
    else
      equation
        print("- elab_untyped_mod ");
        s = SCodeDump.printModStr(inMod,SCodeDump.defaultOptions);
        print(s);
        print(" failed\n");
      then
        fail();
  end matchcontinue;
end elabUntypedMod;

protected function elabSubmods
  "This function helps elabMod by recursively elaborating on a list of submodifications."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input list<SCode.SubMod> inSCodeSubModLst;
  input Boolean inBoolean;
  input ModScope inModScope;
  input SourceInfo info;
  output FCore.Cache outCache;
  output list<DAE.SubMod> outTypesSubModLst;
protected
  list<SCode.SubMod> submods;
algorithm
  submods := compactSubMods(inSCodeSubModLst, inModScope);
  (outCache, outTypesSubModLst) := elabSubmods2(inCache, inEnv, inIH, inPrefix,
    submods, inBoolean, info, {});
end elabSubmods;

protected function elabSubmods2
  "This function elaborates a list of submodifications."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input list<SCode.SubMod> inSubMods;
  input Boolean inImpl;
  input SourceInfo inInfo;
  input list<DAE.SubMod> inAccumMods;
  output FCore.Cache outCache;
  output list<DAE.SubMod> outSubMods;
algorithm
  (outCache, outSubMods) :=
  match(inCache, inEnv, inIH, inPrefix, inSubMods, inImpl, inInfo, inAccumMods)
    local
      FCore.Cache cache;
      SCode.SubMod smod;
      list<SCode.SubMod> rest_smods;
      DAE.SubMod dmod;
      list<DAE.SubMod> accum_mods;

    case (cache, _, _, _, smod :: rest_smods, _, _, _)
      equation
        (cache, dmod) = elabSubmod(cache, inEnv, inIH, inPrefix, smod, inImpl, inInfo);
        (cache, accum_mods) = elabSubmods2(cache, inEnv, inIH, inPrefix,
          rest_smods, inImpl, inInfo, dmod :: inAccumMods);
      then
        (cache, accum_mods);

    else (inCache, listReverse(inAccumMods));

  end match;
end elabSubmods2;

protected function compactSubMods
  "This function merges the submodifiers in a modifier so that each submodifier
    only occurs once. Ex:

    compactMod({x.start = 2.0, y = 4.0, x(min = 1.0, max = 3.0)}) =>
      {x(start = 2.0, min = 1.0, max = 3.0), y = 4.0}

  "
  input list<SCode.SubMod> inSubMods;
  input ModScope inModScope;
  output list<SCode.SubMod> outSubMods;
protected
  list<SCode.SubMod> submods;
algorithm
  submods := List.fold2(inSubMods, compactSubMod, inModScope, {}, {});
  outSubMods := listReverse(submods);
end compactSubMods;

protected function compactSubMod
  "Helper function to compactSubMods. Tries to merge the given modifier with an
   existing modifier in the accumulation list. If a matching modifier is not
   found in the list it's added instead."
  input SCode.SubMod inSubMod;
  input ModScope inModScope;
  input list<String> inName;
  input list<SCode.SubMod> inAccumMods;
  output list<SCode.SubMod> outSubMods;
protected
  list<SCode.SubMod> submods;
  Boolean found;
algorithm
  (submods, found) := List.findMap3(inAccumMods, compactSubMod2, inSubMod, inModScope, inName);
  outSubMods := List.consOnTrue(not found, inSubMod, submods);
end compactSubMod;

protected function compactSubMod2
  "Helper function to compactSubMod. Merges the given modifier with the existing
    modifier if they have the same name, otherwise does nothing."
  input SCode.SubMod inExistingMod;
  input SCode.SubMod inNewMod;
  input ModScope inModScope;
  input list<String> inName;
  output SCode.SubMod outMod;
  output Boolean outFound;
algorithm
  (outMod, outFound) := matchcontinue(inExistingMod, inNewMod, inModScope, inName)
    local
      String name1, name2;
      SCode.SubMod submod;

    case (SCode.NAMEMOD(ident = name1), SCode.NAMEMOD(ident = name2), _, _)
      equation
        false = stringEqual(name1, name2);
      then
        (inExistingMod, false);

    case (SCode.NAMEMOD(ident = name1), _, _, _)
      equation
        submod = mergeSubModsInSameScope(inExistingMod, inNewMod, name1 :: inName, inModScope);
      then
        (submod, true);

  end matchcontinue;
end compactSubMod2;

protected function mergeSubModsInSameScope
  "Merges two submodifiers in the same scope, i.e. they have the same priority.
   It's thus an error if the modifiers modify the same element."
  input SCode.SubMod inMod1;
  input SCode.SubMod inMod2;
  input list<String> inElementName;
  input ModScope inModScope;
  output SCode.SubMod outMod;
algorithm
  outMod := match(inMod1, inMod2, inElementName, inModScope)
    local
      String id, scope, name;
      SCode.Final fp;
      SCode.Each ep;
      list<SCode.SubMod> submods1, submods2;
      Option<Absyn.Exp> binding;
      SourceInfo info1, info2;
      SCode.Mod mod1, mod2;

    // The second modifier has no binding, use the binding from the first.
    case (SCode.NAMEMOD(id, SCode.MOD(fp, ep, submods1, binding, info1)),
          SCode.NAMEMOD(mod = SCode.MOD(subModLst = submods2, binding = NONE())), _, _)
      equation
        submods1 = List.fold2(submods1, compactSubMod, inModScope,
          inElementName, submods2);
      then
        SCode.NAMEMOD(id, SCode.MOD(fp, ep, submods1, binding, info1));

    // The first modifier has no binding, use the binding from the second.
    case (SCode.NAMEMOD(mod = SCode.MOD(subModLst = submods1, binding = NONE())),
          SCode.NAMEMOD(id, SCode.MOD(fp, ep, submods2, binding, info2)), _, _)
      equation
        submods1 = List.fold2(submods1, compactSubMod, inModScope,
          inElementName, submods2);
      then
        SCode.NAMEMOD(id, SCode.MOD(fp, ep, submods1, binding, info2));

    // The first modifier has no binding, use the binding from the second.
    case (SCode.NAMEMOD(mod = mod1), SCode.NAMEMOD(mod = mod2), _, _)
      equation
        info1 = SCode.getModifierInfo(mod1);
        info2 = SCode.getModifierInfo(mod2);
        scope = printModScope(inModScope);
        name = stringDelimitList(listReverse(inElementName), ".");
        Error.addMultiSourceMessage(Error.DUPLICATE_MODIFICATIONS,
          {name, scope}, {info2, info1});
      then
        fail();

  end match;
end mergeSubModsInSameScope;

protected function printModScope
  input ModScope inModScope;
  output String outString;
algorithm
  outString := match(inModScope)
    local
      String name;
      Absyn.Path path;

    case COMPONENT(name = name) then System.gettext("component ") + name;
    case EXTENDS(path = path) then System.gettext("extends ") + Absyn.pathString(path);
    case DERIVED(path = path) then System.gettext("inherited class ") + Absyn.pathString(path);

  end match;
end printModScope;

protected function elabSubmod
  "This function elaborates on a submodification, turning an
   SCode.SubMod into a DAE.SubMod."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input SCode.SubMod inSubMod;
  input Boolean inBoolean;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.SubMod outSubMod;
protected
  SCode.Mod smod;
  DAE.Mod dmod;
  String i;
algorithm
  SCode.NAMEMOD(ident = i, mod = smod) := inSubMod;
  (outCache, dmod) := elabMod(inCache, inEnv, inIH, inPrefix, smod, inBoolean, COMPONENT(i), info);
  outSubMod := DAE.NAMEMOD(i, dmod);
end elabSubmod;

protected function elabUntypedSubmods
  input list<SCode.SubMod> inSubMods;
  input FCore.Graph inEnv;
  input Prefix.Prefix inPrefix;
  input ModScope inModScope;
  output list<DAE.SubMod> outSubMods;
protected
  list<SCode.SubMod> submods;
algorithm
  submods := compactSubMods(inSubMods, inModScope);
  outSubMods := elabUntypedSubmods2(submods, inEnv, inPrefix, inModScope);
end elabUntypedSubmods;

protected function elabUntypedSubmods2 "
  This function helps `elab_untyped_mod\' by recusively elaborating on a list
  of submodifications.
"
  input list<SCode.SubMod> inSubMods;
  input FCore.Graph inEnv;
  input Prefix.Prefix inPrefix;
  input ModScope inModScope;
  output list<DAE.SubMod> outSubMods;
algorithm
  outSubMods := match (inSubMods, inEnv, inPrefix, inModScope)
    local
      list<DAE.SubMod> x_1,xs_1,res;
      SCode.SubMod x;
      list<SCode.SubMod> xs;
      FCore.Graph env;
      Prefix.Prefix pre;
    case ({},_,_,_) then {};
    case ((x :: xs),env,pre,_)
      equation
        x_1 = elabUntypedSubmod(x, env, pre);
        xs_1 = elabUntypedSubmods2(xs, env, pre, inModScope);
        res = listAppend(x_1, xs_1);
      then
        res;
  end match;
end elabUntypedSubmods2;

protected function elabUntypedSubmod "
  This function elaborates on a submodification, turning an
  `SCode.SubMod\' into one or more `DAE.SubMod\'s, wihtout type information.
"
  input SCode.SubMod inSubMod;
  input FCore.Graph inEnv;
  input Prefix.Prefix inPrefix;
  output list<DAE.SubMod> outTypesSubModLst;
algorithm
  outTypesSubModLst:=
  match (inSubMod,inEnv,inPrefix)
    local
      DAE.Mod m_1;
      String i;
      SCode.Mod m;
      FCore.Graph env;
      Prefix.Prefix pre;
      list<Absyn.Subscript> subcr;
      list<DAE.Subscript> sList;
      list<DAE.SubMod> smods;

    case (SCode.NAMEMOD(ident = i, mod = m),env,pre)
      equation
        m_1 = elabUntypedMod(m, env, pre, COMPONENT(""));
      then
        {DAE.NAMEMOD(i,m_1)};
  end match;
end elabUntypedSubmod;

// - Lookup
public function lookupModificationP "This function extracts a modification from inside another
  modification, using a name to look up submodifications."
  input DAE.Mod inMod;
  input Absyn.Path inPath;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue (inMod,inPath)
    local
      DAE.Mod mod,m,mod_1;
      String n;
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
    else
      equation
        Print.printBuf("- Mod.lookupModificationP failed\n");
      then
        fail();
  end matchcontinue;
end lookupModificationP;

public function lookupCompModification "This function is used to look up an identifier in a modification."
  input DAE.Mod inMod;
  input Absyn.Ident inIdent;
  output DAE.Mod outMod;
algorithm
  outMod := match(inMod,inIdent)
    local
      DAE.Mod mod,mod1,mod2;
      list<DAE.SubMod> subs;
      String n;
      Option<DAE.EqMod> eqMod;
      SCode.Each e;
      SCode.Final f;

    case (DAE.MOD(finalPrefix = f,eachPrefix = e,subModLst = subs,eqModOption = eqMod),n)
      equation
        mod1 = lookupCompModification2(subs, n);
        mod2 = lookupComplexCompModification(eqMod,n,f,e);
        mod = checkDuplicateModifications(mod1,mod2,n);
      then
        mod;

    else DAE.NOMOD();
  end match;
end lookupCompModification;

public function getModifs
"return the modifications from mod
 which is named inName or which
 is named name if name is inside
 inSMod(xxx = name)"
  input DAE.Mod inMods;
  input SCode.Ident inName;
  input SCode.Mod inSMod;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue(inMods, inName, inSMod)
    local
      DAE.Mod m;

    case (_, _, _)
      equation
        m = lookupCompModification(inMods, inName);
        m = mergeModifiers(inMods, m, inSMod);
      then
        m;

    else
      equation
        m = mergeModifiers(inMods, DAE.NOMOD(), inSMod);
      then
        m;
  end matchcontinue;
end getModifs;

protected function mergeModifiers
  input DAE.Mod inMods;
  input DAE.Mod inMod;
  input SCode.Mod inSMod;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue(inMods, inMod, inSMod)
    local
      DAE.Mod m;
      list<SCode.SubMod> sl;
      SCode.Final f;
      SCode.Each e;

    case (_, _, SCode.MOD(f, e, sl, _, _))
      equation
        m = mergeSubMods(inMods, inMod, f, e, sl);
      then
        m;

    else inMod;

  end matchcontinue;
end mergeModifiers;

protected function mergeSubMods
  input DAE.Mod inMods;
  input DAE.Mod inMod;
  input SCode.Final f;
  input SCode.Each e;
  input list<SCode.SubMod> inSMods;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue inSMods
    local
      DAE.Mod m;
      SCode.Ident id, n;
      list<SCode.SubMod> rest;

    case {} then inMod;

    case SCode.NAMEMOD(n, SCode.MOD(binding = SOME(Absyn.CREF(Absyn.CREF_IDENT(id, _)))))::rest
      equation
        m = lookupCompModification(inMods, id);
        m = DAE.MOD(f, e, {DAE.NAMEMOD(n, m)}, NONE());
        m = merge(inMod, m, FGraph.empty(), Prefix.NOPRE());
        m = mergeSubMods(inMods, m, f, e, rest);
      then
        m;

    case _::rest
      equation
        m = mergeSubMods(inMods, inMod, f, e, rest);
      then
        m;

  end matchcontinue;
end mergeSubMods;

public function lookupCompModificationFromEqu "This function is used to look up an identifier in a modification."
  input DAE.Mod inMod;
  input Absyn.Ident inIdent;
  output DAE.Mod outMod;
algorithm
  outMod := match (inMod,inIdent)
    local
      DAE.Mod mod,mod1,mod2;
      list<DAE.SubMod> subs;
      String n;
      Option<DAE.EqMod> eqMod;
      SCode.Each e;
      SCode.Final f;

    case (DAE.NOMOD(),_) then DAE.NOMOD();
    case (DAE.REDECL(),_) then DAE.NOMOD();
    case (DAE.MOD(finalPrefix=f,eachPrefix=e,subModLst = subs,eqModOption=eqMod),n)
      equation
        mod1 = lookupCompModification2(subs, n);
        mod2 = lookupComplexCompModification(eqMod,n,f,e);
        mod = selectEqMod(mod1, mod2, n);
      then
        mod;
  end match;
end lookupCompModificationFromEqu;

protected function selectEqMod
"@adrpo:
  This function selects the eqmod modifier if is not DAE.NOMOD! AND IS TYPED!
  Otherwise check for duplicates"
 input DAE.Mod subMod;
 input DAE.Mod eqMod;
 input String n;
 output DAE.Mod mod;
algorithm
  mod := match (subMod, eqMod, n)
    // eqmod is nomod!
    case (_, DAE.NOMOD(), _) then subMod;
    case (_,DAE.MOD(eqModOption = SOME(DAE.TYPED())), _) then eqMod;
    else
      equation
        mod = checkDuplicateModifications(subMod,eqMod,n);
      then
        mod;
  end match;
end selectEqMod;

protected function lookupComplexCompModification "Lookups a component modification from a complex constructor
(e.g. record constructor) by name."
  input Option<DAE.EqMod> eqMod;
  input Absyn.Ident n;
  input SCode.Final finalPrefix;
  input SCode.Each each_;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue(eqMod,n,finalPrefix,each_)
    local
      list<Values.Value> values;
      list<String> names;
      list<DAE.Var> varLst;
      DAE.Mod mod;
      DAE.Exp e;
      SourceInfo info;

    case(NONE(),_,_,_) then DAE.NOMOD();

    case(SOME(DAE.TYPED(_,SOME(Values.RECORD(_,values,names,-1)),
                        DAE.PROP(DAE.T_COMPLEX(varLst = varLst),_),_,info)),
         _,_,_)
      equation
        mod = lookupComplexCompModification2(values,names,varLst,n,finalPrefix,each_,info);
      then mod;

    else DAE.NOMOD();

  end matchcontinue;
end lookupComplexCompModification;

protected function lookupComplexCompModification2 "Help function to lookupComplexCompModification"
  input list<Values.Value> inValues;
  input list<String> inNames;
  input list<DAE.Var> inVars;
  input String name;
  input SCode.Final finalPrefix;
  input SCode.Each each_;
  input SourceInfo info;
  output DAE.Mod mod;
algorithm
  mod := matchcontinue(inValues,inNames,inVars,name,finalPrefix,each_,info)
    local
      DAE.Type tp;
      Values.Value v;
      String name1,name2;
      DAE.Exp e;
      list<Values.Value> values;
      list<String> names;
      list<DAE.Var> vars;
      Absyn.Exp ae;

    case(v::_,name1::_,DAE.TYPES_VAR(name=name2,ty=tp)::_,_,_,_,_)
      equation
        true = (name1 == name2);
        true = (name2 == name);
        e = ValuesUtil.valueExp(v);
        ae = Expression.unelabExp(e);
      then
        DAE.MOD(finalPrefix,each_,{},SOME(DAE.TYPED(e,SOME(v),DAE.PROP(tp,DAE.C_CONST()),ae,info)));

    case(_::values,_::names,_::vars,_,_,_,_)
      equation
        mod = lookupComplexCompModification2(values,names,vars,name,finalPrefix,each_,info);
      then
        mod;

  end matchcontinue;
end lookupComplexCompModification2;

protected function checkDuplicateModifications "Checks if two modifiers are present, and in that case
print error of duplicate modifications, if not, the one modification having a value is returned"
  input DAE.Mod mod1;
  input DAE.Mod mod2;
  input String n;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue(mod1,mod2,n)
    local
      String s1,s2,s,n2;

    case(DAE.NOMOD(),_,_) then mod2;
    case (_,DAE.NOMOD(),_) then mod1;
    // if they are equal, ignoring prefix, return the second one!
    case(_,_,_)
      equation
        true = modEqual(mod1, mod2);
      then
        mod2;

    // print error message
    else
      equation
        s1 = printModStr(mod1);
        s2 = printModStr(mod2);
        s = s1 + " and " + s2;
        n2 = "component " + n;
        Error.addMessage(Error.DUPLICATE_MODIFICATIONS,{s,n2});
      then
        mod2;

  end matchcontinue;
end checkDuplicateModifications;

protected function modEqualNoPrefix
  input DAE.Mod mod1;
  input DAE.Mod mod2;
  output DAE.Mod outMod;
  output Boolean equal;
algorithm
  (outMod, equal) := matchcontinue(mod1, mod2)
    local
      SCode.Final f1,f2;
      SCode.Each each1,each2;
      list<DAE.SubMod> submods1,submods2;
      Option<DAE.EqMod> eqmod1,eqmod2;
      list<tuple<SCode.Element, DAE.Mod>> elsmods1, elsmods2;
      SCode.Program els1, els2;

    case(DAE.MOD(_,_,submods1,eqmod1),DAE.MOD(f2,each2,submods2,eqmod2))
      equation
        true = subModsEqual(submods1,submods2);
        true = eqModEqual(eqmod1,eqmod2);
      then
        (DAE.MOD(f2,each2,submods2,eqmod2), true);

    // two exactly the same mod, return just one! (used when it is REDECL or a submod is REDECL)
    case(DAE.REDECL(_, _, elsmods1),DAE.REDECL(f2, each2, elsmods2))
      equation
        els1 = List.map(elsmods1, Util.tuple21);
        els2 = List.map(elsmods2, Util.tuple21);
        true = List.fold(List.threadMap(els1, els2, SCode.elementEqual), boolAnd, true);
      then
        (DAE.REDECL(f2, each2, elsmods2), true);

    case(DAE.NOMOD(),DAE.NOMOD()) then (DAE.NOMOD(), true);

    // adrpo: do not fail, return false!
    else (mod2, false);
  end matchcontinue;
end modEqualNoPrefix;

protected function lookupNamedSubMod
  input list<DAE.SubMod> inSubMods;
  input Absyn.Ident inIdent;
  output DAE.SubMod outSubMod;
algorithm
  outSubMod := List.getMemberOnTrue(inIdent, inSubMods, isSubModNamed);
end lookupNamedSubMod;

protected function isSubModNamed
  input Absyn.Ident inIdent;
  input DAE.SubMod inSubMod;
  output Boolean outIsNamed;
protected
  String ident;
algorithm
  DAE.NAMEMOD(ident = ident) := inSubMod;
  outIsNamed := stringEq(inIdent, ident);
end isSubModNamed;

public function printSubsStr
"@author: adrpo
 Prints sub-mods in a string with format (sub1, sub2, sub3)"
  input list<DAE.SubMod> inSubMods;
  input Boolean addParan;
  output String s;
algorithm
  s := stringDelimitList(List.map(inSubMods, prettyPrintSubmod), ", ");
  s := (if addParan then "(" else "") + s + (if addParan then ")" else "");
end printSubsStr;

protected function lookupCompModification2
  input list<DAE.SubMod> inSubModLst;
  input Absyn.Ident inIdent;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue(inSubModLst, inIdent)
    local
      list<DAE.SubMod> mmods;
      DAE.Mod mod;

    case ({}, _) then DAE.NOMOD();

    case (_, _)
      equation
        DAE.NAMEMOD(mod = mod) = lookupNamedSubMod(inSubModLst, inIdent);
      then
        mod;

    else DAE.NOMOD();

  end matchcontinue;
end lookupCompModification2;

public function lookupIdxModification
  "This function extracts modifications to an array element, using a subscript
   expression to index the modification."
  input DAE.Mod inMod;
  input DAE.Exp inIndex;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue inMod
    local
      DAE.Mod mod1, mod2;
      list<DAE.SubMod> subs;
      Option<DAE.EqMod> eq;

    case DAE.NOMOD() then DAE.NOMOD();
    case DAE.REDECL() then DAE.NOMOD();
    case DAE.MOD()
      algorithm
        (mod1, subs) := lookupIdxModification2(inMod.subModLst, inIndex);
        mod2 := DAE.MOD(inMod.finalPrefix, inMod.eachPrefix, subs, NONE());
        mod2 := merge(mod2, mod1, FGraph.empty(), Prefix.NOPRE());

        eq := indexEqmod(inMod.eqModOption, {inIndex});
        mod1 := DAE.MOD(SCode.NOT_FINAL(), inMod.eachPrefix, {}, eq);
        mod2 := merge(mod2, mod1, FGraph.empty(), Prefix.NOPRE());
      then
        mod2;

    else
      algorithm
        true := Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Mod.lookupIdxModification(");
        Debug.trace(printModStr(inMod));
        Debug.traceln(", " + ExpressionDump.printExpStr(inIndex) + ") failed");
      then
        fail();

  end matchcontinue;
end lookupIdxModification;

protected function lookupIdxModification2
  "This function does part of the job for lookupIdxModification."
  input list<DAE.SubMod> inSubMods;
  input DAE.Exp inIndex;
  output DAE.Mod outMod = DAE.NOMOD();
  output list<DAE.SubMod> outSubMods = {};
protected
  DAE.Mod mod;
  String name;
algorithm
  for submod in inSubMods loop
    DAE.NAMEMOD(name, mod) := submod;
    mod := lookupIdxModification3(mod, inIndex);

    // isEmptyMod should be used instead, but the Modification13 test case
    // breaks if empty submods are filtered out...
    if not isNoMod(mod) then
      outSubMods := DAE.NAMEMOD(name, mod) :: outSubMods;
    end if;
  end for;

  outSubMods := listReverse(outSubMods);
end lookupIdxModification2;

protected function lookupIdxModification3
  "Helper function to lookupIdxModification2.
   When lookup up the index of a named mod, e.g. y = {1, 2, 3}, it should
   subscript the expression {1, 2, 3} to the corresponding index."
  input DAE.Mod inMod;
  input DAE.Exp inIndex;
  output DAE.Mod outMod;
algorithm
  outMod := match inMod
    local
      list<DAE.SubMod> subs;
      Option<DAE.EqMod> eq;

    case DAE.NOMOD() then DAE.NOMOD();
    case DAE.REDECL() then inMod;

    case DAE.MOD(eachPrefix = SCode.NOT_EACH())
      algorithm
        (_, subs) := lookupIdxModification2(inMod.subModLst, inIndex);
        eq := indexEqmod(inMod.eqModOption, {inIndex});
      then
        DAE.MOD(inMod.finalPrefix, inMod.eachPrefix, subs, eq);

    case DAE.MOD(eachPrefix = SCode.EACH())
      then inMod;

  end match;
end lookupIdxModification3;

protected function indexEqmod
  "If there is an equation modification, this function can subscript it using
   the provided indexing expressions. This is used when a modification equates
   an array variable with an array expression. This expression will be expanded
   to produce one equation expression per array component."
  input Option<DAE.EqMod> inBinding;
  input list<DAE.Exp> inIndices;
  output Option<DAE.EqMod> outBinding = inBinding;
protected
  DAE.Exp exp;
  Option<Values.Value> oval;
  Values.Value val;
  DAE.Type ty;
  DAE.Const c;
  Absyn.Exp aexp;
  DAE.EqMod eq;
  SourceInfo info;
algorithm
  if isNone(inBinding) or listEmpty(inIndices) then
    return;
  end if;

  SOME(eq) := inBinding;

  outBinding := matchcontinue eq
    // Subscripting empty array gives no value. This is needed in e.g. fill(1.0, 0, 2).
    case DAE.TYPED(modifierAsValue = SOME(Values.ARRAY(valueLst = {}))) then NONE();

    // A normal typed binding.
    case DAE.TYPED(exp, oval, DAE.PROP(ty, c), aexp, info)
      algorithm
        // Subscript the expression with the indices.
        for i in inIndices loop
          if not Types.isArray(ty) then
            // Check that we're not trying to apply a non-array modifier to an
            // array, which isn't really allowed but working anyway. Some
            // standard Modelica libraries are missing the 'each' keyword
            // though (e.g. the DoublePendulum example), and therefore relying
            // on this behaviour, so just print a warning here.
            Error.addSourceMessage(Error.MODIFIER_NON_ARRAY_TYPE_WARNING,
              {ExpressionDump.printExpStr(exp)}, info);
            return;
          end if;

          ty := Types.unliftArray(ty);
          exp := ExpressionSimplify.simplify1(Expression.makeASUB(exp, {i}));
        end for;

        // If the modifier has a value, retrieve the indexed elements.
        if isSome(oval) then
          SOME(val) := oval;

          for i in inIndices loop
            val := ValuesUtil.nthArrayelt(val, Expression.expArrayIndex(i));
          end for;

          oval := SOME(val);
        end if;
      then
        SOME(DAE.TYPED(exp, oval, DAE.PROP(ty, c), aexp, info));

    else
      algorithm
        true := Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Mod.indexEqmod failed for mod:\n " +
          Types.unparseEqMod(eq) + "\n indices: " +
          ExpressionDump.printExpListStr(inIndices));
      then
        fail();

  end matchcontinue;
end indexEqmod;

public function merge "
A mid step for merging two modifiers.
It validates that the merging is allowed(considering final modifier)."
  input DAE.Mod inModOuter "the outer mod which should overwrite the inner mod";
  input DAE.Mod inModInner "the inner mod";
  input FCore.Graph inEnv;
  input Prefix.Prefix inPrefix;
  output DAE.Mod outMod;
algorithm
  outMod:= matchcontinue (inModOuter,inModInner,inEnv,inPrefix)
    local
      DAE.Mod m;
      String  s1, s2, s3, s4;
      Option<Absyn.Path> p;
      list<tuple<SCode.Element, DAE.Mod>> elsmods1, elsmods2;
      SCode.Final fp1, fp2;
      SCode.Each ep1, ep2;
      SCode.Program els1, els2;

    case (DAE.NOMOD(),DAE.NOMOD(),_,_) then DAE.NOMOD();
    case (DAE.NOMOD(),m,_,_) then m;
    case (m,DAE.NOMOD(),_,_) then m;
    // That's a NOMOD() if I ever saw one...
    case (m,DAE.MOD(subModLst={},eqModOption=NONE()),_,_) then m;
    case (DAE.MOD(subModLst={},eqModOption=NONE()),m,_,_) then m;

    case(_,_,_,_)
      equation
        //true = merge2(inModInner);
      then
        doMerge(inModOuter,inModInner,inEnv,inPrefix);

    case(_,_,_,_)
      equation
        true = modSubsetOrEqualOrNonOverlap(inModOuter,inModInner);
        m = doMerge(inModOuter,inModInner,inEnv,inPrefix);
      then
        m;

    // two exactly the same mod, return just one! (used when it is REDECL or a submod is REDECL)
    case(DAE.REDECL(fp1, ep1, elsmods1),DAE.REDECL(fp2, ep2, elsmods2),_,_)
      equation
        true = SCode.eachEqual(ep1, ep2);
        true = SCode.finalEqual(fp1, fp2);
        els1 = List.map(elsmods1, Util.tuple21);
        els2 = List.map(elsmods2, Util.tuple21);
        true = List.fold(List.threadMap(els1, els2, SCode.elementEqual), boolAnd, true);
      then
        inModOuter;

    else
      equation
        false = merge2(inModInner);
        false = modSubsetOrEqualOrNonOverlap(inModOuter,inModInner);
        p = FGraph.getScopePath(inEnv);
        s1 = PrefixUtil.printPrefixStrIgnoreNoPre(inPrefix);
        s2 = Absyn.optPathString(p);
        s3 = printModStr(inModOuter);
        s4 = printModStr(inModInner);
        Error.addMessage(Error.FINAL_OVERRIDE, {s1,s2,s3,s4});
        // keep this for debugging via gdb.
        // _ = merge(inModOuter,inModInner,inEnv,inPrefix);
      then
        fail();

  end matchcontinue;
end merge;

public function merge2 "
This function validates that the inner modifier is not final.
Helper function for merge"
  input DAE.Mod inMod1;
  output Boolean outMod;
algorithm
  outMod:= matchcontinue (inMod1)
    local
      case (DAE.REDECL(tplSCodeElementModLst =
            {(SCode.COMPONENT(prefixes=SCode.PREFIXES(finalPrefix=SCode.FINAL())),_)}))
        then false;
      case(DAE.MOD(finalPrefix = SCode.FINAL()))
        then false;
      else true;
  end matchcontinue;
end merge2;

// - Merging
protected function doMerge "This function merges two modifications into one.
  The first argument is the *outer* modification that
  should take precedence over the *inner* modification."
  input DAE.Mod inModOuter "the outer mod which should overwrite the inner mod";
  input DAE.Mod inModInner "the inner mod";
  input FCore.Graph inEnv3;
  input Prefix.Prefix inPrefix4;
  output DAE.Mod outMod;
algorithm
  outMod := match (inModOuter,inModInner,inEnv3,inPrefix4)
    local
      DAE.Mod m,m1_1,m2_1,m_2,mod,mods,mm1,mm2,mm3,mm4,cm,icm,emod1,emod2,emod;
      SCode.Visibility vis;
      SCode.Final finalPrefix,f,f1,f2;
      SCode.Replaceable r;
      SCode.Redeclare redecl;
      Absyn.InnerOuter io;
      String id1,id2;
      SCode.Attributes attr1, attr2, attr;
      Absyn.TypeSpec tp;
      SCode.Mod m1,m2,sm,cm1,cm2;
      SCode.Comment comment,comment2;
      Option<SCode.Annotation> ann;
      FCore.Graph env;
      Prefix.Prefix pre;
      list<tuple<SCode.Element, DAE.Mod>> els;
      list<DAE.SubMod> subs,subs1,subs2;
      Option<DAE.EqMod> ass,ass1,ass2;
      SCode.Each each1,each2;
      Option<Absyn.Exp> cond;
      SourceInfo info, info1, info2;
      SCode.Element celm,elementOne,el;
      SCode.ClassDef cdef;
      SCode.Encapsulated ep;
      SCode.Partial pp;
      SCode.Restriction res1, res2, res;
      SCode.Prefixes pf1, pf2, pf;

    /*
    case (inModOuter,inModInner,_,_)
      equation
        print("Merging: " + printModStr(inModOuter) + " with " + printModStr(inModInner) + "\n");
      then
        fail();*/

    case (m,DAE.NOMOD(),_,_) then m;

    // redeclaring same component
    case (DAE.REDECL(finalPrefix = f1,eachPrefix = each1, tplSCodeElementModLst =
            {(SCode.COMPONENT(
                name = id1,
                prefixes = pf1,
                attributes = attr1,
                typeSpec = tp,
                modifications = m1,
                comment=comment,
                condition=cond,
                info=info1),
                emod1)}),
          DAE.REDECL(tplSCodeElementModLst =
            {(SCode.COMPONENT(
                name = id2,
                prefixes = pf2,
                attributes = attr2),
                emod2)}),env,pre)
      equation
        true = stringEq(id1, id2);
        m1 = SCode.mergeModifiers(m1, SCodeUtil.getConstrainedByModifiers(pf1));
        m2 = SCode.mergeModifiers(m1, SCodeUtil.getConstrainedByModifiers(pf2));
        m1_1 = elabUntypedMod(m1, env, pre, COMPONENT(id1));
        m2_1 = elabUntypedMod(m2, env, pre, COMPONENT(id2));
        m_2 = merge(m1_1, m2_1, env, pre);
        // if we have a constraint class we don't need the mod
        sm = unelabMod(m_2);
        emod = merge(emod1, emod2, env, pre);
        pf = SCode.propagatePrefixes(pf2, pf1);
        attr = SCode.propagateAttributes(attr2, attr1);
      then
        DAE.REDECL(f1,each1,
          {(SCode.COMPONENT(id1,
              pf,
              attr,
              tp,
              sm,
              comment,cond,info1),emod)});

    // Redeclaring same class.
    case (DAE.REDECL(finalPrefix = f1, eachPrefix = each1, tplSCodeElementModLst =
            {(SCode.CLASS(name = id1,
                prefixes = pf1,
                restriction = res1,
                classDef = cdef,
                cmt = comment,
                info = info1),
                m1_1)}),
          DAE.REDECL(tplSCodeElementModLst =
            {(SCode.CLASS(name = id2,
                prefixes = pf2,
                restriction = res2,
                encapsulatedPrefix = ep,
                partialPrefix = pp,
                info = info2),
                m2_1)}), env, pre)
      equation
        true = stringEq(id1, id2);
        m1_1 = merge(m1_1, elabUntypedMod(SCodeUtil.getConstrainedByModifiers(pf1), env, pre, COMPONENT(id1)), env, pre);
        m2_1 = merge(m2_1, elabUntypedMod(SCodeUtil.getConstrainedByModifiers(pf2), env, pre, COMPONENT(id2)), env, pre);
        m = merge(m1_1, m2_1, env, pre);
        pf = SCode.propagatePrefixes(pf2, pf1);
        (res, info) = SCode.checkSameRestriction(res1, res2, info1, info2);
      then
        DAE.REDECL(f1, each1, {(SCode.CLASS(id1, pf, ep, pp, res, cdef, comment, info), m)});

    // luc_pop : this shoud return the first mod because it have been merged in merge_subs
    case (DAE.REDECL(finalPrefix = f1,eachPrefix = each1,
                       tplSCodeElementModLst = {(celm as SCode.COMPONENT(),cm)}),
          icm as DAE.MOD(),env,pre)
      equation
        cm = merge(cm,icm,env,pre);
      then
        DAE.REDECL(f1,each1,{(celm,cm)});

    case ((icm as DAE.MOD()),
          DAE.REDECL(
            finalPrefix = f1,
            eachPrefix = each1,
            tplSCodeElementModLst = ({( (celm as SCode.COMPONENT()),cm)})),env,pre)
      equation
        cm = merge(icm,cm,env,pre);
      then
        DAE.REDECL(f1,each1,{(celm,cm)});

    case (DAE.MOD(finalPrefix = finalPrefix,eachPrefix = each1,subModLst = subs1,eqModOption = ass1),
          DAE.MOD(subModLst = subs2,eqModOption = ass2),env,pre)
      equation
        subs = mergeSubs(subs1, subs2, env, pre);
        ass = mergeEq(ass1, ass2);
        mm2 = DAE.MOD(finalPrefix,each1,subs,ass);
      then
        mm2;

    // Case when we have a modifier on a redeclared class
    // This is of current date BZ:2008-03-04 not completly working.
    // see testcase mofiles/Modification14.mo
    case (mm1 as DAE.MOD(),
          DAE.REDECL(
                  finalPrefix = finalPrefix,eachPrefix = each1,
                  tplSCodeElementModLst = (                  {((elementOne as SCode.CLASS()),mm3)})),
                  env,pre)
      equation
        mm4 = merge(mm1,mm3,env,pre);
      then
        DAE.REDECL(finalPrefix,each1,{(elementOne,mm4)});

    case (DAE.REDECL(finalPrefix = finalPrefix,eachPrefix = each1, tplSCodeElementModLst = ({((elementOne as SCode.CLASS()),mm3)})),
          mm1 as DAE.MOD(),env,pre)
      equation
        mm4 = merge(mm3,mm1,env,pre);
      then
        DAE.REDECL(finalPrefix,each1,{(elementOne,mm4)});

  end match;
end doMerge;

protected function mergeSubs "This function merges to list of DAE.SubMods."
  input list<DAE.SubMod> inTypesSubModLst1;
  input list<DAE.SubMod> inTypesSubModLst2;
  input FCore.Graph inEnv3;
  input Prefix.Prefix inPrefix4;
  output list<DAE.SubMod> outTypesSubModLst;
algorithm
  outTypesSubModLst := matchcontinue (inTypesSubModLst1,inTypesSubModLst2,inEnv3,inPrefix4)
    local
      list<DAE.SubMod> s1,s2,s2_new,s_rec;
      DAE.SubMod s,s_first;
      FCore.Graph env;
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
  input FCore.Graph inEnv;
  input Prefix.Prefix inPrefix;
  output DAE.SubMod outSubMod;
  output list<DAE.SubMod> outTypesSubModLst;
algorithm
  (outSubMod,outTypesSubModLst) := matchcontinue (inSubMod,inTypesSubModLst,inEnv,inPrefix)
    local
      DAE.SubMod sm,s,s1,s2;
      DAE.Mod m,m1,m2;
      String n1,n2;
      list<DAE.SubMod> ss,ss_1;
      FCore.Graph env;
      Prefix.Prefix pre;
      list<Integer> i1,i2;

    // empty list
    case (sm,{},_,_) then (sm,{});

    // named mods, modifications in the list take precedence
    case (DAE.NAMEMOD(ident = n1,mod = m1),(DAE.NAMEMOD(ident = n2,mod = m2) :: ss),env,pre)
      equation
        true = stringEq(n1, n2);
        m = merge(m1, m2, env, pre);
      then
        (DAE.NAMEMOD(n1,m),ss);

    // handle next
    case (s1,(s2::ss),env,pre)
      equation
        true = verifySubMerge(s1,s2);
        (s,ss_1) = mergeSubs2_2(s1, ss, env, pre);
      then
        (s,s2::ss_1);
  end matchcontinue;
end mergeSubs2_2;

protected function mergeSubs2 "This function helps in the merging of two lists of DAE.SubMods.
  It compares one DAE.SubMod against a list of other DAE.SubMods,
  and if there is one with the same name, it is kept and the one
  DAE.SubMod given in the second argument is discarded."
  input list<DAE.SubMod> inTypesSubModLst;
  input DAE.SubMod inSubMod;
  input FCore.Graph inEnv;
  input Prefix.Prefix inPrefix;
  output list<DAE.SubMod> outTypesSubModLst;
  output DAE.SubMod outSubMod;
algorithm
  (outTypesSubModLst,outSubMod) := matchcontinue (inTypesSubModLst,inSubMod,inEnv,inPrefix)
    local
      DAE.SubMod sm,s,s1,s2;
      DAE.Mod m,m1,m2;
      String n1,n2;
      list<DAE.SubMod> ss,ss_1;
      FCore.Graph env;
      Prefix.Prefix pre;
      list<Integer> i1,i2;

    // empty list
    case ({},sm,_,_) then ({},sm);

    // named mods, modifications in the list take precedence
    case ((DAE.NAMEMOD(ident = n1,mod = m1) :: ss),DAE.NAMEMOD(ident = n2,mod = m2),env,pre)
      equation
        true = stringEq(n1, n2);
        m = merge(m1, m2, env, pre);
      then
        (ss,DAE.NAMEMOD(n1,m));

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
        true = stringEq(n1, n2);
      then false;

    else true;
  end matchcontinue;
end verifySubMerge;

protected function mergeEq "The outer modification, given in the first argument,
  takes precedence over the inner modifications."
  input Option<DAE.EqMod> inTypesEqModOption1;
  input Option<DAE.EqMod> inTypesEqModOption2;
  output Option<DAE.EqMod> outTypesEqModOption;
algorithm
  outTypesEqModOption := match (inTypesEqModOption1,inTypesEqModOption2)
    local Option<DAE.EqMod> e;
    // Outer assignments take precedence
    case ((e as SOME(_)),_) then e;
    case (NONE(),e) then e;
  end match;
end mergeEq;

public function modEquation "This function simply extracts the equation part of a modification."
  input DAE.Mod inMod;
  output Option<DAE.EqMod> outTypesEqModOption;
algorithm
  outTypesEqModOption := match (inMod)
    local Option<DAE.EqMod> e;
    case DAE.NOMOD() then NONE();
    case DAE.REDECL() then NONE();
    case DAE.MOD(eqModOption = e) then e;
  end match;
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
      SCode.Final f1,f2;
      SCode.Each each1,each2;
      list<DAE.SubMod> submods1,submods2;
      Option<DAE.EqMod> eqmod1,eqmod2;
      list<tuple<SCode.Element, DAE.Mod>> elsmods1, elsmods2;
      SCode.Program els1, els2;

    // adrpo: handle non-overlap: final parameter Real eAxis_ia[3](each final unit="1") = {1,2,3};
    //        mod1 = final each unit="1" mod2 = final = {1,2,3}
    //        otherwise we get an error as: Error: Variable eAxis_ia: trying to override final variable ...
    case(DAE.MOD(f1,_,_,NONE()),DAE.MOD(f2,SCode.NOT_EACH(),{},SOME(_)))
      equation
        true = SCode.finalEqual(f1, f2);
      then
        true;

    case(DAE.MOD(_,_,_,eqmod1),DAE.MOD(_,SCode.NOT_EACH(),{},eqmod2))
      equation
        true = eqModSubsetOrEqual(eqmod1,eqmod2);
      then
        true;

    // handle subset equal
    case(DAE.MOD(f1,each1,submods1,eqmod1),DAE.MOD(f2,each2,submods2,eqmod2))
      equation
        true = SCode.finalEqual(f1, f2);
        true = SCode.eachEqual(each1,each2);
        true = subModsEqual(submods1,submods2);
        true = eqModSubsetOrEqual(eqmod1,eqmod2);
      then
        true;

    // two exactly the same mod, return just one! (used when it is REDECL or a submod is REDECL)
    case(DAE.REDECL(f1, each1, elsmods1),DAE.REDECL(f2, each2, elsmods2))
      equation
        true = SCode.finalEqual(f1, f2);
        true = SCode.eachEqual(each1, each2);
        els1 = List.map(elsmods1, Util.tuple21);
        els2 = List.map(elsmods2, Util.tuple21);
        true = List.fold(List.threadMap(els1, els2, SCode.elementEqual), boolAnd, true);
      then
        true;

    case(DAE.NOMOD(),DAE.NOMOD()) then true;

    else false;

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
    case(NONE(),SOME(_)) then true;

    // typed mods
    case(SOME(DAE.TYPED()),SOME(DAE.TYPED()))
      equation
        true = eqModEqual(eqMod1,eqMod2);
      then
        true;

    // typed vs. untyped mods
    case(SOME(DAE.TYPED(modifierAsAbsynExp=aexp1)),SOME(DAE.UNTYPED(exp=aexp2)))
      equation
        true = Absyn.expEqual(aexp1,aexp2);
      then
        true;

    // untyped vs. typed
    case(SOME(DAE.UNTYPED(exp=aexp1)),SOME(DAE.TYPED(modifierAsAbsynExp=aexp2)))
      equation
        true = Absyn.expEqual(aexp1,aexp2);
      then
        true;

    // untyped mods
    case(SOME(DAE.UNTYPED(exp=aexp1)),SOME(DAE.UNTYPED(exp=aexp2)))
      equation
        true = Absyn.expEqual(aexp1,aexp2);
      then
        true;

    // anything else gives false
    else false;
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
    list<DAE.SubMod> rest1,rest2;

    case ({},{}) then true;

    case (DAE.NAMEMOD(id1,mod1)::rest1,DAE.NAMEMOD(id2,mod2)::rest2)
      equation
        true = stringEq(id1,id2);
        true = modEqual(mod1,mod2);
        true = subModsEqual(rest1,rest2);
      then
        true;

    // otherwise false
    else false;
  end matchcontinue;
end subModsSubsetOrEqual;

public function modEqual "
Compares two DAE.Mod, returns true if equal"
  input DAE.Mod mod1;
  input DAE.Mod mod2;
  output Boolean equal;
algorithm
  equal := matchcontinue(mod1,mod2)
    local
      SCode.Final f1,f2;
      SCode.Each each1,each2;
      list<DAE.SubMod> submods1,submods2;
      Option<DAE.EqMod> eqmod1,eqmod2;
      list<tuple<SCode.Element, DAE.Mod>> elsmods1, elsmods2;
      SCode.Program els1, els2;

    case(DAE.MOD(f1,each1,submods1,eqmod1),DAE.MOD(f2,each2,submods2,eqmod2))
      equation
        true = SCode.finalEqual(f1, f2);
        true = SCode.eachEqual(each1,each2);
        true = subModsEqual(submods1,submods2);
        true = eqModEqual(eqmod1,eqmod2);
      then
        true;

    // two exactly the same mod, return just one! (used when it is REDECL or a submod is REDECL)
    case(DAE.REDECL(f1, each1, elsmods1),DAE.REDECL(f2, each2, elsmods2))
      equation
        true = SCode.finalEqual(f1, f2);
        true = SCode.eachEqual(each1, each2);
        els1 = List.map(elsmods1, Util.tuple21);
        els2 = List.map(elsmods2, Util.tuple21);
        true = List.fold(List.threadMap(els1, els2, SCode.elementEqual), boolAnd, true);
      then
        true;

    case(DAE.NOMOD(),DAE.NOMOD()) then true;

    // adrpo: do not fail, return false!
    else false;
  end matchcontinue;
end modEqual;

protected function subModsEqual "Returns true if two submod lists are equal."
  input list<DAE.SubMod> inSubModLst1;
  input list<DAE.SubMod> inSubModLst2;
  output Boolean equal;
algorithm
  equal := matchcontinue(inSubModLst1,inSubModLst2)
    local
      DAE.Ident id1,id2;
      DAE.Mod mod1,mod2;
      list<Integer> indx1,indx2;
      list<DAE.SubMod> subModLst1, subModLst2;


    case ({},{}) then true;

    case (DAE.NAMEMOD(id1,mod1)::subModLst1,DAE.NAMEMOD(id2,mod2)::subModLst2)
      equation
        true = stringEq(id1,id2);
        true = modEqual(mod1,mod2);
        true = subModsEqual(subModLst1,subModLst2);
      then
        true;

    // otherwise false
    else false;

  end matchcontinue;
end subModsEqual;

public function subModEqual "Returns true if two submod are equal."
  input DAE.SubMod subMod1;
  input DAE.SubMod subMod2;
  output Boolean equal;
algorithm
  equal := matchcontinue(subMod1,subMod2)
    local
      DAE.Ident id1,id2;
      DAE.Mod mod1,mod2;
      Boolean b1,b2,b3;
      list<Integer> indx1,indx2;
      list<Boolean> blst1;

    case (DAE.NAMEMOD(id1,mod1),DAE.NAMEMOD(id2,mod2))
      equation
        true = stringEq(id1,id2);
        true = modEqual(mod1,mod2);
      then
        true;

    // otherwise false
    else false;
  end matchcontinue;
end subModEqual;

protected function valEqual
  input Option<Values.Value> inV1;
  input Option<Values.Value> inV2;
  input Boolean equal;
  output Boolean bEq;
algorithm
  bEq := match(inV1, inV2, equal)
    local Values.Value v1, v2;
    case (_, _, true) then true;
    case (NONE(), NONE(), _) then equal;
    case (SOME(v1), SOME(v2), false)
      equation
        bEq = Expression.expEqual(
                  ValuesUtil.valueExp(v1),
                  ValuesUtil.valueExp(v2));
      then
        bEq;
  end match;
end valEqual;

protected function eqModEqual "Returns true if two EqMods are equal"
  input Option<DAE.EqMod> eqMod1;
  input Option<DAE.EqMod> eqMod2;
  output Boolean equal;
algorithm
  equal := matchcontinue(eqMod1,eqMod2)
    local
      Absyn.Exp aexp1,aexp2;
      DAE.Exp exp1,exp2;
      Option<Values.Value> v1, v2;

    // no equ mods
    case(NONE(),NONE()) then true;

    // typed equmods
    case(SOME(DAE.TYPED(modifierAsExp = exp1, modifierAsValue = v1)),
         SOME(DAE.TYPED(modifierAsExp = exp2, modifierAsValue = v2)))
      equation
        equal = Expression.expEqual(exp1,exp2);
        // check the values as crefs might have been replaced!
        true = valEqual(v1, v2, equal);
      then
        true;

    // typed vs. untyped equmods
    case(SOME(DAE.TYPED(modifierAsAbsynExp=aexp1)),SOME(DAE.UNTYPED(exp=aexp2)))
      equation
        true = Absyn.expEqual(aexp1,aexp2);
      then
        true;

    // untyped vs. typed equmods
    case(SOME(DAE.UNTYPED(exp=aexp1)),SOME(DAE.TYPED(modifierAsAbsynExp=aexp2)))
      equation
        true = Absyn.expEqual(aexp1,aexp2);
      then
        true;

    // untyped equmods
    case(SOME(DAE.UNTYPED(exp=aexp1)),SOME(DAE.UNTYPED(exp=aexp2)))
      equation
        true = Absyn.expEqual(aexp1,aexp2);
      then
        true;

    // anything else will give false
    else false;

  end matchcontinue;
end eqModEqual;

public function printModStr
"This function prints a modification.
 It uses a few other function to do its stuff."
  input DAE.Mod inMod;
  output String outString;
algorithm
  outString := matchcontinue (inMod)
    local
      list<SCode.Element> elist_1;
      String prefix,str,res,s1_1,s2;
      list<String> str_lst,s1;
      SCode.Final finalPrefix;
      list<tuple<SCode.Element, DAE.Mod>> elist;
      SCode.Each eachPrefix;
      list<DAE.SubMod> subs;
      Option<DAE.EqMod> eq;

    case (DAE.NOMOD()) then "()";

    case DAE.REDECL(finalPrefix = finalPrefix,eachPrefix = eachPrefix,tplSCodeElementModLst = elist)
      equation
        elist_1 = List.map(elist, Util.tuple21);
        prefix =  SCodeDump.finalStr(finalPrefix) + SCodeDump.eachStr(eachPrefix);
        str_lst = List.map1(elist_1, SCodeDump.unparseElementStr, SCodeDump.defaultOptions);
        str = stringDelimitList(str_lst, ", ");
        res = stringAppendList({"(",prefix,str,")"});
      then
        res;

    case DAE.MOD(finalPrefix = finalPrefix,eachPrefix = eachPrefix,subModLst = subs,eqModOption = eq)
      equation
        prefix =  SCodeDump.finalStr(finalPrefix) + SCodeDump.eachStr(eachPrefix);
        s1 = printSubs1Str(subs);
        s1_1 = stringDelimitList(s1, ", ");
        s1_1 = if not listEmpty(subs) then " {" + s1_1 + "} " else s1_1;
        s2 = printEqmodStr(eq);
        str = stringAppendList({prefix,s1_1,s2});
      then
        str;

    else equation print(" failure in printModStr \n"); then fail();

  end matchcontinue;
end printModStr;

public function printMod "Print a modifier on the Print buffer."
  input DAE.Mod m;
protected
  String str;
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
algorithm
  str := matchcontinue(m,depth)
    local
      list<tuple<SCode.Element, DAE.Mod>> tup;
      list<DAE.SubMod> subs;
      SCode.Final fp;
      DAE.EqMod eq;

    case(DAE.MOD(subModLst = subs, eqModOption=NONE()),_)
      equation
        str = prettyPrintSubs(subs,depth);
      then
        str;

    case(DAE.MOD(finalPrefix = fp, eqModOption=SOME(eq)),_)
      equation
        str = (if SCode.finalBool(fp) then "final " else "") + " = " + Types.unparseEqMod(eq);
      then
        str;

    case(DAE.REDECL(tplSCodeElementModLst = tup),_)
      equation
        str = stringDelimitList(List.map1(List.map(tup,Util.tuple21),SCodeDump.unparseElementStr,SCodeDump.defaultOptions),", ");
      then
        str;

    case(DAE.NOMOD(),_) then "";

    else
      equation
        print(" failed prettyPrintMod\n");
      then
        fail();

  end matchcontinue;
end prettyPrintMod;

protected function prettyPrintSubs "
Author BZ
Helper function for prettyPrintMod"
  input list<DAE.SubMod> inSubs;
  input Integer depth;
  output String str;
algorithm
  str := match(inSubs,depth)
    local
      String s1,s2,id;
      DAE.SubMod s;
      DAE.Mod m;
      list<Integer> li;
      list<DAE.SubMod> subs;

    case({},_) then "";
    case((DAE.NAMEMOD(id,(DAE.REDECL())))::_,_)
      equation
        s2 = " redeclare(" + id +  "), class or component " + id;
      then
        s2;
    case((DAE.NAMEMOD(id,m))::_,_)
      equation
        s2  = prettyPrintMod(m,depth+1);
        s2 = if stringLength(s2) == 0 then "" else s2;
        s2 = "(" + id + s2 + "), class or component " + id;
      then
        s2;
    end match;
end prettyPrintSubs;

public function prettyPrintSubmod "
Prints a readable format of a sub-modifier, used in error reporting for built-in classes"
  input DAE.SubMod inSub;
  output String str;
algorithm
  str := match(inSub)
    local
      String s1,s2,id;
      DAE.Mod m;
      list<Integer> li;
      SCode.Final fp;
      SCode.Each ep;
      list<tuple<SCode.Element, DAE.Mod>> elist;

    case(DAE.NAMEMOD(id,(DAE.REDECL(fp, ep, elist))))
      equation
        s1 = stringDelimitList(List.map1(List.map(elist, Util.tuple21), SCodeDump.unparseElementStr, SCodeDump.defaultOptions), ", ");
        s2 = id + "(redeclare " +
             (if SCode.eachBool(ep) then "each " else "") +
             (if SCode.finalBool(fp) then "final " else "") + s1 + ")";
      then
        s2;

    case(DAE.NAMEMOD(id,m))
      equation
        s2  = prettyPrintMod(m,0);
        s2 = if stringLength(s2) == 0 then "" else s2;
        s2 = id + s2;
      then
        s2;

  end match;
end prettyPrintSubmod;

public function printSubs1Str "Helper function to printModStr"
  input list<DAE.SubMod> inTypesSubModLst;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  match (inTypesSubModLst)
    local
      String s1;
      list<String> res;
      DAE.SubMod x;
      list<DAE.SubMod> xs;
    case {} then {};
    case (x :: xs)
      equation
        s1 = printSubStr(x);
        res = printSubs1Str(xs);
      then
        (s1 :: res);
  end match;
end printSubs1Str;

protected function printSubStr "Helper function to printSubs1Str"
  input DAE.SubMod inSubMod;
  output String outString;
algorithm
  outString := match (inSubMod)
    local
      String mod_str,res,n,str;
      DAE.Mod mod;
      list<Integer> ss;
    case DAE.NAMEMOD(ident = n,mod = mod)
      equation
        mod_str = printModStr(mod);
        res = stringAppend(n + " ", mod_str);
      then
        res;
  end match;
end printSubStr;

protected function printSubscriptsStr "Helper function to printSubStr"
  input list<Integer> inIntegerLst;
  output String outString;
algorithm
  outString := match (inIntegerLst)
    local
      String s,str,res;
      Integer x;
      list<Integer> xs;
    case ({}) then "[]";
    case (x :: xs)
      equation
        Print.printBuf("[");
        s = intString(x);
        str = printSubscripts2Str(xs);
        res = stringAppendList({"[",s,str,"]"});
      then
        res;
  end match;
end printSubscriptsStr;

protected function printSubscripts2Str "Helper function to printSubscriptsStr"
  input list<Integer> inIntegerLst;
  output String outString;
algorithm
  outString := match (inIntegerLst)
    local
      String s,str,res;
      Integer x;
      list<Integer> xs;
    case ({}) then "";
    case (x :: xs)
      equation
        Print.printBuf(",");
        s = intString(x);
        str = printSubscripts2Str(xs);
        res = stringAppendList({",",s,str});
      then
        res;
  end match;
end printSubscripts2Str;

protected function printEqmodStr
"Helper function to printModStr"
  input Option<DAE.EqMod> inTypesEqModOption;
  output String outString;
algorithm
  outString := matchcontinue (inTypesEqModOption)
    local
      String str,str2,e_val_str,res;
      DAE.Exp e;
      Values.Value e_val;
      DAE.Properties prop;
      Absyn.Exp ae;

    case NONE() then "";

    case SOME(DAE.TYPED(e,SOME(e_val),prop,_,_))
      equation
        str = ExpressionDump.printExpStr(e);
        str2 = Types.printPropStr(prop);
        e_val_str = ValuesUtil.valString(e_val);
        res = stringAppendList({" = (typed)",str," ",str2,", value: ",e_val_str});
      then
        res;

    case SOME(DAE.TYPED(e,NONE(),prop,_,_))
      equation
        str = ExpressionDump.printExpStr(e);
        str2 = Types.printPropStr(prop);
        res = stringAppendList({" = (typed)",str, ", type:\n", str2});
      then
        res;

    case SOME(DAE.UNTYPED(exp=ae))
      equation
        str = Dump.printExpStr(ae);
        res = stringAppend(" =(untyped) ", str);
      then
        res;

    else
      equation
        res = "---Mod.printEqmodStr FAILED---";
      then
        res;
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
      SCode.Final finalPrefix;
      SCode.Each each_;
      list<DAE.SubMod> subModLst;
      Option<DAE.EqMod> eqModOption;

    case (DAE.MOD(finalPrefix,each_,subModLst,eqModOption),_,_)
      equation
        subModLst = List.map2(subModLst, renameNamedSubMod, oldIdent, newIdent);
      then
        DAE.MOD(finalPrefix,each_,subModLst,eqModOption);

    else mod;

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
    case (DAE.NAMEMOD(id,mod),_,_)
      equation
        true = stringEq(id,oldIdent);
      then DAE.NAMEMOD(newIdent,mod);
    else submod;
  end matchcontinue;
end renameNamedSubMod;

public function emptyModOrEquality
  input DAE.Mod mod;
  output Boolean b;
algorithm
  b := match mod
    case DAE.NOMOD() then true;
    case DAE.MOD(subModLst={}) then true;
    else false;
  end match;
end emptyModOrEquality;

protected function intStringDot
  input Integer i;
  output String str;
algorithm
  str := intString(i) + ".";
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

    case ((i, _), _)
      equation
        len1 = stringLength(i);
        len2 = stringLength(idx);
        // either one of them is a substring of the other
        true = boolOr(0 == System.strncmp(i, idx, len1), 0 == System.strncmp(idx, i, len2));
      then true;
    else false;
  end matchcontinue;
end isPrefixOf;

protected function getFullModsFromMod
"@author: adrpo
  This function will create fully qualified crefs from
  modifications. See also getFullModsFromSubMods.
  Examples:
  x(start=1, stateSelect=s) => x.start, x.stateSelect
  (x.start=1, x.stateSelect=s) => x.start, x.stateSelect
  x([2] = 1, start = 2) => x[2], x.start"
  input DAE.ComponentRef inTopCref;
  input DAE.Mod inMod;
  output list<FullMod> outFullMods;
algorithm
  outFullMods := match(inTopCref, inMod)
    local
      list<FullMod> fullMods;
      list<DAE.SubMod> subModLst;
      list<tuple<SCode.Element, DAE.Mod>> tplSCodeElementModLst;
      SCode.Final finalPrefix;
      SCode.Each eachPrefix;

    // DAE.NOMOD empty case, no more dive in
    case (_, DAE.NOMOD()) then {};

    // DAE.MOD
    case (_, DAE.MOD(subModLst = subModLst))
      equation
        fullMods = getFullModsFromSubMods(inTopCref, subModLst);
      then
        fullMods;

    // DAE.REDECL
    case (_, DAE.REDECL(finalPrefix = finalPrefix, eachPrefix = eachPrefix, tplSCodeElementModLst = tplSCodeElementModLst))
      equation
        fullMods = getFullModsFromModRedeclare(inTopCref, tplSCodeElementModLst, finalPrefix, eachPrefix);
      then
        fullMods;
  end match;
end getFullModsFromMod;

protected function getFullModsFromModRedeclare
"@author: adrpo
  This function will create fully qualified
  crefs from the redeclaration lists for redeclare mod.
  See also getFullModsFromMod, getFullModsFromSubMod
  Examples:
  x(redeclare package P = P, redeclare class C = C) => x.P, x.C"
  input DAE.ComponentRef inTopCref;
  input list<tuple<SCode.Element, DAE.Mod>> inElements;
  input SCode.Final finalPrefix;
  input SCode.Each eachPrefix;
  output list<FullMod> outFullMods;
algorithm
  outFullMods := matchcontinue(inTopCref, inElements, finalPrefix, eachPrefix)
    local
      list<FullMod> fullMods;
      DAE.Ident id;
      DAE.Mod mod;
      list<tuple<SCode.Element, DAE.Mod>> rest;
      DAE.ComponentRef cref;
      SCode.Element el;
      tuple<SCode.Element, DAE.Mod> x;

    // empty case
    case (_, {}, _, _) then {};

    // SCode.CLASS, TODO! FIXME! what do we do with the mod??
    case (_, (x as (SCode.CLASS(name = id), _))::rest, _, _)
      equation
        cref = ComponentReference.joinCrefs(
                 inTopCref,
                 ComponentReference.makeCrefIdent(
                   id, DAE.T_UNKNOWN_DEFAULT, {}));
        fullMods = getFullModsFromModRedeclare(inTopCref, rest, finalPrefix, eachPrefix);
      then
        MOD(cref, DAE.REDECL(finalPrefix, eachPrefix, {x}))::fullMods;

    // SCode.COMPONENT, TODO! FIXME! what do we do with the mod??
    case (_, (x as (SCode.COMPONENT(name = id), _))::rest, _, _)
      equation
        cref = ComponentReference.joinCrefs(
                 inTopCref,
                 ComponentReference.makeCrefIdent(
                   id, DAE.T_UNKNOWN_DEFAULT, {}));
        fullMods = getFullModsFromModRedeclare(inTopCref, rest, finalPrefix, eachPrefix);
      then
        MOD(cref, DAE.REDECL(finalPrefix, eachPrefix, {x}))::fullMods;

    // anything else, just ignore, TODO! FIXME! maybe report an error??!!
    case (_, (_, _)::rest, _, _)
      equation
        fullMods = getFullModsFromModRedeclare(inTopCref, rest, finalPrefix, eachPrefix);
      then
        fullMods;
  end matchcontinue;
end getFullModsFromModRedeclare;

protected function getFullModsFromSubMods
"@author: adrpo
  This function will create fully qualified crefs from
  sub modifications. See also getFullModsFromMod.
  Examples:
  x(start=1, stateSelect=s) => x.start, x.stateSelect
  (x.start=1, x.stateSelect=s) => x.start, x.stateSelect
  x([2] = 1, start = 2) => x[2], x.start"
  input DAE.ComponentRef inTopCref;
  input list<DAE.SubMod> inSubMods;
  output list<FullMod> outFullMods;
algorithm
  outFullMods := match(inTopCref, inSubMods)
    local
      list<FullMod> fullMods1, fullMods2, fullMods;
      list<DAE.SubMod> rest;
      DAE.SubMod subMod;
      DAE.Ident id;
      DAE.Mod mod;
      list<Integer> indexes;
      DAE.ComponentRef cref;

    // empty case
    case (_, {}) then {};

    // named modifier, only add LEAFS to the list!
    case (_, (subMod as DAE.NAMEMOD(id, mod))::rest)
      equation
        cref = ComponentReference.joinCrefs(
                 inTopCref,
                 ComponentReference.makeCrefIdent(
                   id, DAE.T_UNKNOWN_DEFAULT, {}));
        fullMods1 = getFullModsFromMod(cref, mod);
        fullMods2 = getFullModsFromSubMods(inTopCref, rest);
        fullMods = listAppend(
                     if listEmpty(fullMods1)
                              then SUB_MOD(cref, subMod)::fullMods1 // add if LEAF
                              else fullMods1,
                     fullMods2);
      then
        fullMods;

  end match;
end getFullModsFromSubMods;

protected function fullModCrefsEqual
"@author: adrpo
  This function checks if the crefs of the given full mods are equal"
  input FullMod inFullMod1;
  input FullMod inFullMod2;
  output Boolean isEqual;
algorithm
  isEqual := match(inFullMod1, inFullMod2)
    local DAE.ComponentRef cr1, cr2;
    case (MOD(cr1, _), MOD(cr2, _)) then ComponentReference.crefEqualNoStringCompare(cr1, cr2);
    case (SUB_MOD(cr1, _), SUB_MOD(cr2, _)) then ComponentReference.crefEqualNoStringCompare(cr1, cr2);
    case (MOD(cr1, _), SUB_MOD(cr2, _)) then ComponentReference.crefEqualNoStringCompare(cr1, cr2);
    case (SUB_MOD(cr1, _), MOD(cr2, _)) then ComponentReference.crefEqualNoStringCompare(cr1, cr2);
  end match;
end fullModCrefsEqual;

protected function prettyPrintFullMod
"@author: adrpo
  This function checks if the crefs of the given full mods are equal"
  input FullMod inFullMod;
  input Integer inDepth;
  output String outStr;
algorithm
  outStr := match(inFullMod, inDepth)
    local
      DAE.Mod mod;
      DAE.SubMod subMod;
      DAE.ComponentRef cr;
      String str;

    case (MOD(cr, mod),        _)
      equation
        str = ComponentReference.printComponentRefStr(cr) + ": " + prettyPrintMod(mod, inDepth);
      then
        str;

    case (SUB_MOD(cr, subMod), _)
      equation
        str = ComponentReference.printComponentRefStr(cr) + ": " + prettyPrintSubmod(subMod);
      then
        str;

  end match;
end prettyPrintFullMod;

public function getUnelabedSubMod
  input SCode.Mod inMod;
  input SCode.Ident inIdent;
  output SCode.Mod outSubMod;
protected
  list<SCode.SubMod> submods;
algorithm
  SCode.MOD(subModLst = submods) := inMod;
  outSubMod := getUnelabedSubMod2(submods, inIdent);
end getUnelabedSubMod;

protected function getUnelabedSubMod2
  input list<SCode.SubMod> inSubMods;
  input SCode.Ident inIdent;
  output SCode.Mod outMod;
algorithm
  outMod := matchcontinue(inSubMods, inIdent)
    local
      SCode.Ident id;
      SCode.Mod m;
      list<SCode.SubMod> rest_mods;

    case (SCode.NAMEMOD(ident = id, mod = m) :: _, _)
      equation
        true = stringEqual(id, inIdent);
      then
        m;

    case (_ :: rest_mods, _)
      then getUnelabedSubMod2(rest_mods, inIdent);

  end matchcontinue;
end getUnelabedSubMod2;

public function isUntypedMod
  "Returns true if a modifier contains any untyped parts, otherwise false."
  input DAE.Mod inMod;
  output Boolean outIsUntyped;
algorithm
  outIsUntyped := matchcontinue(inMod)
    local
      list<DAE.SubMod> submods;

    case DAE.MOD(eqModOption = SOME(DAE.UNTYPED())) then true;

    case DAE.MOD(subModLst = submods)
      equation
        _ = List.selectFirst(submods, isUntypedSubMod);
      then
        true;

    else false;
  end matchcontinue;
end isUntypedMod;

protected function isUntypedSubMod
  "Returns true if a submodifier contains any untyped parts, otherwise false."
  input DAE.SubMod inSubMod;
  output Boolean outIsUntyped;
protected
  DAE.Mod mod;
algorithm
  DAE.NAMEMOD(mod = mod) := inSubMod;
  outIsUntyped := isUntypedMod(mod);
end isUntypedSubMod;

public function getUntypedCrefs
  input DAE.Mod inMod;
  output list<Absyn.ComponentRef> outCrefs;
algorithm
  outCrefs := matchcontinue(inMod)
    local
      Absyn.Exp exp;
      list<Absyn.ComponentRef> crefs;
      list<DAE.SubMod> submods;

    case DAE.MOD(eqModOption = SOME(DAE.UNTYPED(exp = exp)))
      equation
        crefs = Absyn.getCrefFromExp(exp, true, true);
      then
        crefs;

    case DAE.MOD(subModLst = submods)
      equation
        crefs = List.fold(submods, getUntypedCrefFromSubMod, {});
      then
        crefs;

    else {};
  end matchcontinue;
end getUntypedCrefs;

protected function getUntypedCrefFromSubMod
  input DAE.SubMod inSubMod;
  input list<Absyn.ComponentRef> inCrefs;
  output list<Absyn.ComponentRef> outCrefs;
algorithm
  outCrefs := match(inSubMod, inCrefs)
    local
      DAE.Mod mod;
      list<Absyn.ComponentRef> crefs;

    case (DAE.NAMEMOD(mod = mod), _)
      equation
        crefs = getUntypedCrefs(mod);
      then
        listAppend(crefs, inCrefs);

  end match;
end getUntypedCrefFromSubMod;

// moved from Types!
public function stripSubmod
"author: PA
  Removes the sub modifiers of a modifier."
  input DAE.Mod inMod;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue (inMod)
    local
      SCode.Final f;
      SCode.Each each_;
      list<SubMod> subs;
      Option<EqMod> eq;
      DAE.Mod m;
    case (DAE.MOD(finalPrefix = f,eachPrefix = each_,eqModOption = eq))
      then DAE.MOD(f,each_,{},eq);
    case (m) then m;
  end matchcontinue;
end stripSubmod;

public function removeFirstSubsRedecl "
Author: BZ, 2009-08
Removed REDECLARE() statements at first level of SubMods"
  input DAE.Mod inMod;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue (inMod)
    local
      SCode.Final f;
      SCode.Each each_;
      list<SubMod> subs;
      Option<EqMod> eq;
      DAE.Mod m;
    case (DAE.MOD(finalPrefix = f,eachPrefix = each_,subModLst = {},eqModOption = eq))
      then DAE.MOD(f,each_,{},eq);
    case (DAE.MOD(subModLst = subs,eqModOption = NONE()))
      equation
         {} = removeRedecl(subs);
      then
        DAE.NOMOD();
    case (DAE.MOD(finalPrefix = f,eachPrefix = each_,subModLst = subs,eqModOption = eq))
      equation
         subs = removeRedecl(subs);
      then
        DAE.MOD(f,each_,subs,eq);
    case (m) then m;
  end matchcontinue;
end removeFirstSubsRedecl;

protected function removeRedecl "
Author BZ
helper function for removeFirstSubsRedecl"
  input list<SubMod> isubs;
  output list<SubMod> osubs;
algorithm
  osubs := matchcontinue(isubs)
    local
      SubMod sm;
      String s;
      list<SubMod> subs;

    case({}) then {};
    case(DAE.NAMEMOD(_,DAE.REDECL(_,_,_))::subs) then removeRedecl(subs);
    case(sm::subs)
      equation
        osubs = removeRedecl(subs);
      then
        sm::osubs;
  end matchcontinue;
end removeRedecl;

public function removeModList "
Author BZ, 2009-07
Delete a list of named modifiers"
  input DAE.Mod inMod;
  input list<String> remStrings;
  output DAE.Mod outMod;
protected
  String s;
algorithm
  outMod := match(inMod,remStrings)
    local
      list<String> rest;
    case(_,{}) then inMod;
    case(_, s::_)
      then removeModList(removeMod(inMod,s),remStrings);
  end match;
end removeModList;

public function removeMod "
Author: BZ, 2009-05
Remove a modifier(/s) on a specified component."
  input DAE.Mod inmod;
  input String componentModified;
  output DAE.Mod outmod;
algorithm
  outmod := match(inmod,componentModified)
    local
      SCode.Final f;
      SCode.Each e;
      list<SubMod> subs;
      Option<EqMod> oem;
      list<tuple<SCode.Element, DAE.Mod>> redecls;

    case(DAE.NOMOD(),_) then DAE.NOMOD();

    case((DAE.REDECL(f,e,redecls)),_)
      equation
        //fprint(Flags.REDECL,"Removing redeclare mods: " + componentModified +" before" + Mod.printModStr(inmod) + "\n");
        redecls = removeRedeclareMods(redecls,componentModified);
        outmod = if not listEmpty(redecls) then DAE.REDECL(f,e,redecls) else DAE.NOMOD();
        //fprint(Flags.REDECL,"Removing redeclare mods: " + componentModified +" after" + Mod.printModStr(outmod) + "\n");
      then
        outmod;

    case(DAE.MOD(f,e,subs,oem),_)
      equation
        //fprint(Flags.REDECL,"Removing redeclare mods: " + componentModified +" before" + Mod.printModStr(inmod) + "\n");
        subs = removeModInSubs(subs,componentModified);
        outmod = DAE.MOD(f,e,subs,oem);
        //fprint(Flags.REDECL,"Removing redeclare mods: " + componentModified +" after" + Mod.printModStr(outmod) + "\n");
      then
        outmod;
  end match;
end removeMod;

protected function removeRedeclareMods ""
  input list<tuple<SCode.Element, DAE.Mod>> inLst;
  input String currComp;
  output list<tuple<SCode.Element, DAE.Mod>> outLst;
algorithm
  outLst := matchcontinue(inLst,currComp)
    local
      SCode.Element comp;
      DAE.Mod mod;
      String s1;
      list<tuple<SCode.Element, DAE.Mod>> lst;

    case({},_) then {};

    case((comp,_)::lst,_)
      equation
        outLst = removeRedeclareMods(lst,currComp);
        s1 = SCode.elementName(comp);
        true = stringEq(s1,currComp);
      then
        outLst;

    case((comp,mod)::lst,_)
      equation
        outLst = removeRedeclareMods(lst,currComp);
      then
        (comp,mod)::outLst;

    else
      equation
        print("removeRedeclareMods failed\n");
      then fail();
  end matchcontinue;
end removeRedeclareMods;

protected function removeModInSubs "
Author BZ, 2009-05
Helper function for removeMod, removes modifiers in submods;
"
  input list<SubMod> inSubs;
  input String componentName;
  output list<SubMod> outsubs;
algorithm
  outsubs := match(inSubs,componentName)
    local
      DAE.Mod m1;
      list<SubMod> subs1,subs2,subs;
      String s1;
      SubMod sub;

    case({},_) then {};
    case((DAE.NAMEMOD(s1,m1))::subs,_)
      equation
        subs1 = if stringEq(s1,componentName) then {} else {DAE.NAMEMOD(s1,m1)};
        subs2 = removeModInSubs(subs,componentName) "check for multiple mod on same comp";
        outsubs = listAppend(subs1,subs2);
      then
        outsubs;
  end match;
end removeModInSubs;

public function addEachIfNeeded
"This function adds each to the mods
 if the dimensions are not empty."
  input DAE.Mod inMod;
  input DAE.Dimensions inDimensions;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue (inMod, inDimensions)
    local
      SCode.Final finalPrefix;
      list<tuple<SCode.Element, DAE.Mod>> elist;
      SCode.Each eachPrefix;
      list<DAE.SubMod> subs;
      Option<DAE.EqMod> eq;

    case (_, {}) then inMod;
    case (DAE.NOMOD(), _) then DAE.NOMOD();

    case (DAE.REDECL(finalPrefix,_,elist), _)
      then
        DAE.REDECL(finalPrefix,SCode.EACH(),elist);

    // do not each the subs of already each'ed mod
    case (DAE.MOD(finalPrefix,SCode.EACH(),subs,eq), _)
      then
        DAE.MOD(finalPrefix,SCode.EACH(),subs,eq);

    case (DAE.MOD(finalPrefix,eachPrefix,subs,eq), _)
      equation
        subs = addEachToSubsIfNeeded(subs, inDimensions);
      then
        DAE.MOD(finalPrefix,eachPrefix,subs,eq);

    else
      equation
        print("Mod.addEachIfNeeded failed on: " + printModStr(inMod) + "\n");
      then
        fail();

  end matchcontinue;
end addEachIfNeeded;

public function addEachOneLevel
"This function adds each to the mods
 if the dimensions are not empty."
  input DAE.Mod inMod;
  output DAE.Mod outMod;
algorithm
  outMod := matchcontinue (inMod)
    local
      SCode.Final finalPrefix;
      list<tuple<SCode.Element, DAE.Mod>> elist;
      SCode.Each eachPrefix;
      list<DAE.SubMod> subs;
      Option<DAE.EqMod> eq;

    case (DAE.NOMOD()) then DAE.NOMOD();

    case (DAE.REDECL(finalPrefix,_,elist))
      then
        DAE.REDECL(finalPrefix,SCode.EACH(),elist);

    case (DAE.MOD(finalPrefix,_,subs,eq))
      then
        DAE.MOD(finalPrefix,SCode.EACH(),subs,eq);

    else
      equation
        print("Mod.addEachOneLevel failed on: " + printModStr(inMod) + "\n");
      then
        fail();

  end matchcontinue;
end addEachOneLevel;

public function addEachToSubsIfNeeded
  input list<DAE.SubMod> inSubMods;
  input DAE.Dimensions inDimensions;
  output list<DAE.SubMod> outSubMods;
algorithm
  outSubMods := match(inSubMods, inDimensions)
    local
      list<DAE.SubMod> rest;
      DAE.Mod m;
      String id;
      list<Integer> idxs;

    case (_, {}) then inSubMods;

    case ({}, _) then {};

    case (DAE.NAMEMOD(id, m)::rest, _)
      equation
        m = addEachOneLevel(m);
        rest = addEachToSubsIfNeeded(rest, inDimensions);
      then
        DAE.NAMEMOD(id, m)::rest;

  end match;
end addEachToSubsIfNeeded;

public function isEmptyMod
"@author: adrpo
 returns true if this is an empty modifier"
  input DAE.Mod inMod;
  output Boolean isEmpty;
algorithm
  isEmpty := match inMod
    case DAE.NOMOD() then true;
    // That's a NOMOD() if I ever saw one...
    case DAE.MOD(subModLst = {}, eqModOption = NONE()) then true;
    else false;
  end match;
end isEmptyMod;

public function isNoMod
  input DAE.Mod inMod;
  output Boolean outIsNoMod;
algorithm
  outIsNoMod := match inMod
    case DAE.NOMOD() then true;
    else false;
  end match;
end isNoMod;

public function getModInfo
  input DAE.Mod inMod;
  output SourceInfo outInfo;
algorithm
  outInfo := match(inMod)
    local
      SourceInfo info;

    case DAE.MOD(eqModOption = SOME(DAE.TYPED(info = info))) then info;
    case DAE.MOD(eqModOption = SOME(DAE.UNTYPED(info = info))) then info;
  end match;
end getModInfo;

public function isRedeclareMod
  input DAE.Mod inMod;
  output Boolean yes;
algorithm
  yes := match(inMod)
    case DAE.REDECL() then true;
    else false;
  end match;
end isRedeclareMod;


public function getClassModifier
"return the modifier present in the environment for this class or DAE.NOMOD if ther is none"
  input FCore.Graph inEnv;
  input FCore.Name inName;
  output DAE.Mod outMod;
protected
  FCore.Node n;
  DAE.Mod mod;
algorithm
   outMod := matchcontinue(inEnv, inName)

     case (_, _)
       equation
         n = FNode.fromRef(FNode.child(FGraph.lastScopeRef(inEnv), inName));
         if (not FNode.isInstance(FNode.fromRef(FGraph.lastScopeRef(inEnv)))) then
           FCore.N(data=FCore.CL(mod = mod)) = n;
           mod = Mod.removeMod(mod, inName);
           /*
           if not isEmptyMod(mod)
           then
             print("Env: " + FGraph.printGraphPathStr(inEnv) + " " + inName + "(" + printModStr(mod) + ")" + "\n");
           end if;
           */
         else
           mod = DAE.NOMOD();
         end if;
       then mod;

     else DAE.NOMOD();

  end matchcontinue;
end getClassModifier;

annotation(__OpenModelica_Interface="frontend");
end Mod;

