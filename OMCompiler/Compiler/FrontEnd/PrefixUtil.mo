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

encapsulated package PrefixUtil
" file:         PrefixUtil.mo
  package:     PrefixUtil
  description: PrefixUtil management


  When instantiating an expression, there is a prefix that
  has to be added to each variable name to be able to use it in the
  flattened equation set.

  A prefix for a variable x could be for example a.b.c so that the
  fully qualified name is a.b.c.x."


public import Absyn;
public import AbsynUtil;
public import DAE;
public import FCore;
public import FGraph;
public import Lookup;
public import SCode;
public import InnerOuter;
public import ClassInf;

protected

type InstanceHierarchy = InnerOuter.InstHierarchy "an instance hierarchy";

import ComponentReference;
import Config;
import Error;
import Expression;
import ExpressionDump;
import Flags;
import List;
import Print;
//import Util;
import System;
import Types;
import MetaModelica.Dangerous;

public function printComponentPrefixStr "Prints a Prefix to a string. Rather slow..."
  input DAE.ComponentPrefix pre;
  output String outString;
algorithm
  outString :=  match pre
    local
      String str,s,rest_1,s_1,s_2;
      DAE.ComponentPrefix rest;
      DAE.ClassPrefix cp;
      list<DAE.Subscript> ss;

    case DAE.NOCOMPPRE() then "<Prefix.NOCOMPPRE()>";
    case DAE.PRE(next=DAE.NOCOMPPRE(), subscripts={}) then pre.prefix;
    case DAE.PRE(next=DAE.NOCOMPPRE()) then pre.prefix + "[" + ExpressionDump.printSubscriptLstStr(pre.subscripts) + "]";
    case DAE.PRE(subscripts={}) then printComponentPrefixStr(pre.next)+"."+pre.prefix;
    case DAE.PRE() then printComponentPrefixStr(pre.next)+"."+pre.prefix + "[" + ExpressionDump.printSubscriptLstStr(pre.subscripts) + "]";
  end match;
end printComponentPrefixStr;

public function printPrefixStr "Prints a Prefix to a string."
  input DAE.Prefix inPrefix;
  output String outString;
algorithm
  outString :=  matchcontinue (inPrefix)
    local
      String str,s,rest_1,s_1,s_2;
      DAE.ComponentPrefix rest;
      DAE.ClassPrefix cp;
      list<DAE.Subscript> ss;

    case DAE.NOPRE() then "<Prefix.NOPRE()>";
    case DAE.PREFIX(DAE.NOCOMPPRE(),_) then "<Prefix.PREFIX(DAE.NOCOMPPRE())>";
    case DAE.PREFIX(DAE.PRE(str,_,{},DAE.NOCOMPPRE(),_,_),_) then str;
    case DAE.PREFIX(DAE.PRE(str,_,ss,DAE.NOCOMPPRE(),_,_),_)
      equation
        s = stringAppend(str, "[" + stringDelimitList(
          List.map(ss, ExpressionDump.subscriptString), ", ") + "]");
      then
        s;
    case DAE.PREFIX(DAE.PRE(str,_,{},rest,_,_),cp)
      equation
        rest_1 = printPrefixStr(DAE.PREFIX(rest,cp));
        s = stringAppend(rest_1, ".");
        s_1 = stringAppend(s, str);
      then
        s_1;
    case DAE.PREFIX(DAE.PRE(str,_,ss,rest,_,_),cp)
      equation
        rest_1 = printPrefixStr(DAE.PREFIX(rest,cp));
        s = stringAppend(rest_1, ".");
        s_1 = stringAppend(s, str);
        s_2 = stringAppend(s_1, "[" + stringDelimitList(
          List.map(ss, ExpressionDump.subscriptString), ", ") + "]");
      then
        s_2;
  end matchcontinue;
end printPrefixStr;

public function printPrefixStr2 "Prints a Prefix to a string. Designed to be used in Error messages to produce qualified component names"
  input DAE.Prefix inPrefix;
  output String outString;
algorithm
  outString :=  match (inPrefix)
  local
    DAE.Prefix p;
  case DAE.NOPRE() then "";
  case DAE.PREFIX(DAE.NOCOMPPRE(),_) then "";
  case p then printPrefixStr(p)+".";
  end match;
end printPrefixStr2;

public function printPrefixStr3 "Prints a Prefix to a string as a component name. Designed to be used in Error messages"
  input DAE.Prefix inPrefix;
  output String outString;
algorithm
  outString :=  match (inPrefix)
  local
    DAE.Prefix p;
  case DAE.NOPRE() then "<NO COMPONENT>";
  case DAE.PREFIX(DAE.NOCOMPPRE(),_) then "<NO COMPONENT>";
  case p then printPrefixStr(p);
  end match;
end printPrefixStr3;

public function printPrefixStrIgnoreNoPre "Prints a Prefix to a string as a component name. Designed to be used in Error messages"
  input DAE.Prefix inPrefix;
  output String outString;
algorithm
  outString :=  match (inPrefix)
  local
    DAE.Prefix p;
  case DAE.NOPRE() then "";
  case DAE.PREFIX(DAE.NOCOMPPRE(),_) then "";
  case p then printPrefixStr(p);
  end match;
end printPrefixStrIgnoreNoPre;

public function printPrefix "Prints a prefix to the Print buffer."
  input DAE.Prefix p;
protected
  String s;
algorithm
  s := printPrefixStr(p);
  Print.printBuf(s);
end printPrefix;

public function prefixAdd "This function is used to extend a prefix with another level.  If
  the prefix `a.b{10}.c\' is extended with `d\' and an empty subscript
  list, the resulting prefix is `a.b{10}.c.d\'.  Remember that
  prefixes components are stored in the opposite order from the
  normal order used when displaying them."
  input String inIdent;
  input list<DAE.Dimension> inType;
  input list<DAE.Subscript> inIntegerLst;
  input DAE.Prefix inPrefix;
  input SCode.Variability vt;
  input ClassInf.State ci_state;
  input SourceInfo inInfo;
  output DAE.Prefix outPrefix;
algorithm
  outPrefix := match (inIdent,inType,inIntegerLst,inPrefix,vt,ci_state)
    local
      String i;
      list<DAE.Subscript> s;
      DAE.ComponentPrefix p;

    case (i,_,s,DAE.PREFIX(p,_),_,_)
      then DAE.PREFIX(DAE.PRE(i,inType,s,p,ci_state,inInfo),DAE.CLASSPRE(vt));

    case(i,_,s,DAE.NOPRE(),_,_)
      then DAE.PREFIX(DAE.PRE(i,inType,s,DAE.NOCOMPPRE(),ci_state,inInfo),DAE.CLASSPRE(vt));
  end match;
end prefixAdd;

public function prefixFirst
  input DAE.Prefix inPrefix;
  output DAE.Prefix outPrefix;
algorithm
  outPrefix := match (inPrefix)
    local
      String a;
      list<DAE.Subscript> b;
      DAE.ClassPrefix cp;
      DAE.ComponentPrefix c;
      ClassInf.State ci_state;
      list<DAE.Dimension> pdims;
      SourceInfo info;

    case (DAE.PREFIX(DAE.PRE(prefix = a, dimensions = pdims, subscripts = b,ci_state=ci_state, info = info),cp))
      then DAE.PREFIX(DAE.PRE(a,pdims,b,DAE.NOCOMPPRE(),ci_state,info),cp);
  end match;
end prefixFirst;

public function prefixFirstCref
  "Returns the first cref in the prefix."
  input DAE.Prefix inPrefix;
  output DAE.ComponentRef outCref;
protected
  String name;
  list<DAE.Subscript> subs;
algorithm
  DAE.PREFIX(compPre = DAE.PRE(prefix = name, subscripts = subs)) := inPrefix;
  outCref := DAE.CREF_IDENT(name, DAE.T_UNKNOWN_DEFAULT, subs);
end prefixFirstCref;

public function prefixLast "Returns the last NONPRE Prefix of a prefix"
  input DAE.Prefix inPrefix;
  output DAE.Prefix outPrefix;
algorithm
  outPrefix := matchcontinue (inPrefix)
    local
      DAE.ComponentPrefix p;
      DAE.Prefix res;
      DAE.ClassPrefix cp;

    case ((res as DAE.PREFIX(DAE.PRE(next = DAE.NOCOMPPRE()),_))) then res;

    case (DAE.PREFIX(DAE.PRE(next = p),cp))
      equation
        res = prefixLast(DAE.PREFIX(p,cp));
      then
        res;
  end matchcontinue;
end prefixLast;

public function prefixStripLast
"@author: adrpo
 remove the last prefix from the component prefix"
  input DAE.Prefix inPrefix;
  output DAE.Prefix outPrefix;
algorithm
  outPrefix := match (inPrefix)
    local
      DAE.ClassPrefix cp;
      DAE.ComponentPrefix compPre;
    // we can't remove what it isn't there!
    case (DAE.NOPRE()) then DAE.NOPRE();
    // if there isn't any next prefix, return DAE.NOPRE!
    case (DAE.PREFIX(compPre,cp))
      equation
         compPre = compPreStripLast(compPre);
      then DAE.PREFIX(compPre,cp);
  end match;
end prefixStripLast;

protected function compPreStripLast
"@author: adrpo
 remove the last prefix from the component prefix"
  input DAE.ComponentPrefix inCompPrefix;
  output DAE.ComponentPrefix outCompPrefix;
algorithm
  outCompPrefix := match(inCompPrefix)
    local
      DAE.ComponentPrefix next;

    // nothing to remove!
    case DAE.NOCOMPPRE() then DAE.NOCOMPPRE();
    // we have something
    case DAE.PRE(next = next) then next;
   end match;
end compPreStripLast;

public function prefixPath "Prefix a Path variable by adding the supplied
  prefix to it and returning a new Path."
  input Absyn.Path inPath;
  input DAE.Prefix inPrefix;
  output Absyn.Path outPath;
algorithm
  outPath := match (inPath,inPrefix)
    local
      Absyn.Path p,p_1;
      String s;
      DAE.ComponentPrefix ss;
      DAE.ClassPrefix cp;

    case (p,DAE.NOPRE()) then p;
    case (p,DAE.PREFIX(DAE.PRE(prefix = s,next = DAE.NOCOMPPRE()),_))
      equation
        p_1 = Absyn.QUALIFIED(s,p);
      then p_1;
    case (p,DAE.PREFIX(DAE.PRE(prefix = s,next = ss),cp))
      equation
        p_1 = prefixPath(Absyn.QUALIFIED(s,p), DAE.PREFIX(ss,cp));
      then p_1;
  end match;
end prefixPath;

public function prefixToPath "Convert a Prefix to a Path"
  input DAE.Prefix inPrefix;
  output Absyn.Path outPath;
algorithm
  outPath := match inPrefix
    local
      DAE.ComponentPrefix ss;
    case DAE.PREFIX(ss,_) then componentPrefixToPath(ss);
  end match;
end prefixToPath;

public function identAndPrefixToPath "Convert a Ident/Prefix to a String"
  input String ident;
  input DAE.Prefix inPrefix;
  output String str;
algorithm
  str := AbsynUtil.pathString(PrefixUtil.prefixPath(Absyn.IDENT(ident),inPrefix));
end identAndPrefixToPath;

public function componentPrefixToPath "Convert a Prefix to a Path"
  input DAE.ComponentPrefix pre;
  output Absyn.Path path;
algorithm
  path := match pre
    local
      String s;
      DAE.ComponentPrefix ss;
    case DAE.PRE(prefix = s,next = DAE.NOCOMPPRE())
      then Absyn.IDENT(s);
    case DAE.PRE(prefix = s,next = ss)
      then Absyn.QUALIFIED(s,componentPrefixToPath(ss));
  end match;
end componentPrefixToPath;

public function prefixCref "Prefix a ComponentRef variable by adding the supplied prefix to
  it and returning a new ComponentRef.
  LS: Changed to call prefixToCref which is more general now"
  input FCore.Cache cache;
  input FCore.Graph env;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Prefix pre;
  input DAE.ComponentRef cref;
  output FCore.Cache outCache;
  output DAE.ComponentRef cref_1;
algorithm
  (outCache,cref_1) := prefixToCref2(cache,env,inIH,pre, SOME(cref));
end prefixCref;

public function prefixCrefNoContext "Prefix a ComponentRef variable by adding the supplied prefix to
  it and returning a new ComponentRef.
  LS: Changed to call prefixToCref which is more general now"
  input DAE.Prefix inPre;
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  (_, outCref) := prefixToCref2(FCore.noCache(), FGraph.empty(), InnerOuter.emptyInstHierarchy, inPre, SOME(inCref));
end prefixCrefNoContext;

public function prefixToCref "Convert a prefix to a component reference."
  input DAE.Prefix pre;
  output DAE.ComponentRef cref_1;
algorithm
  (_,cref_1) := prefixToCref2(FCore.noCache(), FGraph.empty(), InnerOuter.emptyInstHierarchy, pre, NONE());
end prefixToCref;

protected function prefixToCref2 "Convert a prefix to a component reference. Converting DAE.NOPRE with no
  component reference is an error because a component reference cannot be
  empty"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InstanceHierarchy inIH;
  input DAE.Prefix inPrefix;
  input Option<DAE.ComponentRef> inExpComponentRefOption;
  output FCore.Cache outCache;
  output DAE.ComponentRef outComponentRef;
algorithm
  (outCache,outComponentRef) := match (inCache,inEnv,inIH,inPrefix,inExpComponentRefOption)
    local
      DAE.ComponentRef cref,cref_1,cref_2,cref_;
      String i;
      list<DAE.Subscript> s;
      list<DAE.Dimension> ds;
      DAE.Type ident_ty;
      DAE.ComponentPrefix xs;
      DAE.ClassPrefix cp;
      ClassInf.State ci_state;
      FCore.Cache cache;
      FCore.Graph env;

    case (_,_,_,DAE.NOPRE(),NONE()) then fail();
    case (_,_,_,DAE.PREFIX(DAE.NOCOMPPRE(),_),NONE()) then fail();

    case (cache,_,_,DAE.NOPRE(),SOME(cref)) then (cache,cref);
    case (cache,_,_,DAE.PREFIX(DAE.NOCOMPPRE(),_),SOME(cref)) then (cache,cref);
    case (cache,env,_,DAE.PREFIX(DAE.PRE(prefix = i,dimensions=ds,subscripts = s,next = xs,ci_state=ci_state),cp),NONE())
      equation
        ident_ty = Expression.liftArrayLeftList(DAE.T_COMPLEX(ci_state, {}, NONE()), ds);
        cref_ = ComponentReference.makeCrefIdent(i,ident_ty,s);
        (cache,cref_1) = prefixToCref2(cache,env,inIH,DAE.PREFIX(xs,cp), SOME(cref_));
      then
        (cache,cref_1);
    case (cache,env,_,DAE.PREFIX(DAE.PRE(prefix = i,dimensions=ds,subscripts = s,next = xs,ci_state=ci_state),cp),SOME(cref))
      equation
        (cache,cref) = prefixSubscriptsInCref(cache,env,inIH,inPrefix,cref);
        ident_ty = Expression.liftArrayLeftList(DAE.T_COMPLEX(ci_state, {}, NONE()), ds);
        cref_2 = ComponentReference.makeCrefQual(i,ident_ty,s,cref);
        (cache,cref_1) = prefixToCref2(cache,env,inIH,DAE.PREFIX(xs,cp), SOME(cref_2));
      then
        (cache,cref_1);
  end match;
end prefixToCref2;

public function prefixToCrefOpt "Convert a prefix to an optional component reference."
  input DAE.Prefix pre;
  output Option<DAE.ComponentRef> cref_1;
algorithm
  cref_1 := prefixToCrefOpt2(pre, NONE());
end prefixToCrefOpt;

public function prefixToCrefOpt2 "Convert a prefix to a component reference. Converting DAE.NOPRE with no
  component reference gives a NONE"
  input DAE.Prefix inPrefix;
  input Option<DAE.ComponentRef> inExpComponentRefOption;
  output Option<DAE.ComponentRef> outComponentRefOpt;
algorithm
  outComponentRefOpt := match (inPrefix,inExpComponentRefOption)
    local
      Option<DAE.ComponentRef> cref_1;
      DAE.ComponentRef cref,cref_;
      String i;
      list<DAE.Subscript> s;
      DAE.ComponentPrefix xs;
      DAE.ClassPrefix cp;

    case (DAE.NOPRE(),NONE()) then NONE();
    case (DAE.NOPRE(),SOME(cref)) then SOME(cref);
    case (DAE.PREFIX(DAE.NOCOMPPRE(),_),SOME(cref)) then SOME(cref);
    case (DAE.PREFIX(DAE.PRE(prefix = i,subscripts = s,next = xs),cp),NONE())
      equation
        cref_ = ComponentReference.makeCrefIdent(i,DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("")), {}, NONE()),s);
        cref_1 = prefixToCrefOpt2(DAE.PREFIX(xs,cp), SOME(cref_));
      then
        cref_1;
    case (DAE.PREFIX(DAE.PRE(prefix = i,subscripts = s,next = xs),cp),SOME(cref))
      equation
        cref_ = ComponentReference.makeCrefQual(i,DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("")), {}, NONE()),s,cref);
        cref_1 = prefixToCrefOpt2(DAE.PREFIX(xs,cp), SOME(cref_));
      then
        cref_1;
  end match;
end prefixToCrefOpt2;

public function makeCrefFromPrefixNoFail
"@author:adrpo
   Similar to prefixToCref but it doesn't fail for NOPRE or NOCOMPPRE,
   it will just create an empty cref in these cases"
  input DAE.Prefix pre;
  output DAE.ComponentRef cref;
algorithm
  cref := matchcontinue(pre)
    local
      DAE.ComponentRef c;

    case(DAE.NOPRE())
      equation
        c = ComponentReference.makeCrefIdent("", DAE.T_UNKNOWN_DEFAULT, {});
      then
        c;

    case(DAE.PREFIX(DAE.NOCOMPPRE(), _))
      equation
        c = ComponentReference.makeCrefIdent("", DAE.T_UNKNOWN_DEFAULT, {});
      then
        c;

    case _
      equation
        c = prefixToCref(pre);
      then
        c;
  end matchcontinue;
end makeCrefFromPrefixNoFail;

protected function prefixSubscriptsInCref "help function to prefixToCrefOpt2, deals with prefixing expressions in subscripts"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InstanceHierarchy inIH;
  input DAE.Prefix pre;
  input DAE.ComponentRef inCr;
  output FCore.Cache outCache;
  output DAE.ComponentRef outCr;
algorithm
  (outCache,outCr) := prefixSubscriptsInCrefWork(inCache,inEnv,inIH,pre,inCr,{});
end prefixSubscriptsInCref;

protected function prefixSubscriptsInCrefWork "help function to prefixToCrefOpt2, deals with prefixing expressions in subscripts"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InstanceHierarchy inIH;
  input DAE.Prefix pre;
  input DAE.ComponentRef inCr;
  input list<DAE.ComponentRef> acc;
  output FCore.Cache outCache;
  output DAE.ComponentRef outCr;
algorithm
  (outCache,outCr) := match (inCache,inEnv,inIH,pre,inCr,acc)
    local
      DAE.Ident id;
      DAE.Type tp;
      list<DAE.Subscript> subs;
      FCore.Cache cache;
      FCore.Graph env;
      DAE.ComponentRef cr,crid;
    case(cache,env,_,_,DAE.CREF_IDENT(id,tp,subs),_)
      equation
        (cache,subs) = prefixSubscripts(cache,env,inIH,pre,subs);
        cr = ComponentReference.makeCrefIdent(id,tp,subs);
      then (cache,ComponentReference.implode_reverse(cr::acc));
    case(cache,env,_,_,DAE.CREF_QUAL(id,tp,subs,cr),_)
      equation
        (cache,subs) = prefixSubscripts(cache,env,inIH,pre,subs);
        crid = ComponentReference.makeCrefIdent(id,tp,subs);
        (cache,cr) = prefixSubscriptsInCrefWork(cache,env,inIH,pre,cr,crid::acc);
      then (cache,cr);
    case(cache,_,_,_,DAE.WILD(),_) then (cache,DAE.WILD());
  end match;
end prefixSubscriptsInCrefWork;

protected function prefixSubscripts "help function to prefixSubscriptsInCref, adds prefix to subscripts"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InstanceHierarchy inIH;
  input DAE.Prefix pre;
  input list<DAE.Subscript> inSubs;
  output FCore.Cache outCache;
  output list<DAE.Subscript> outSubs;
algorithm
  (outCache,outSubs) := match(inCache,inEnv,inIH,pre,inSubs)
    local
      DAE.Subscript sub;
      FCore.Cache cache;
      FCore.Graph env;
      list<DAE.Subscript> subs;

    case (cache,_,_,_,{}) then (cache,{});

    case (cache,env,_,_,sub::subs)
      equation
        (cache,sub) = prefixSubscript(cache,env,inIH,pre,sub);
        (cache,subs) = prefixSubscripts(cache,env,inIH,pre,subs);
      then (cache,sub::subs);
  end match;
end prefixSubscripts;

protected function prefixSubscript "help function to prefixSubscripts, adds prefix to one subscript, if it is an expression"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InstanceHierarchy inIH;
  input DAE.Prefix pre;
  input DAE.Subscript sub;
  output FCore.Cache outCache;
  output DAE.Subscript outSub;
algorithm
  (outCache,outSub) := match(inCache,inEnv,inIH,pre,sub)
    local
      DAE.Exp exp;
      FCore.Cache cache;
      FCore.Graph env;

    case(cache,_,_,_,DAE.WHOLEDIM()) then (cache,DAE.WHOLEDIM());

    case(cache,env,_,_,DAE.SLICE(exp)) equation
      (cache,exp) = prefixExpWork(cache,env,inIH,exp,pre);
    then (cache,DAE.SLICE(exp));

    case(cache,env,_,_,DAE.WHOLE_NONEXP(exp)) equation
      (cache,exp) = prefixExpWork(cache,env,inIH,exp,pre);
    then (cache,DAE.WHOLE_NONEXP(exp));

    case(cache,env,_,_,DAE.INDEX(exp)) equation
      (cache,exp) = prefixExpWork(cache,env,inIH,exp,pre);
    then (cache,DAE.INDEX(exp));

  end match;
end prefixSubscript;

public function prefixCrefInnerOuter "Search for the prefix of the inner when the cref is
  an outer and add that instead of the given prefix!
  If the cref is an inner, prefix it normally."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.ComponentRef inCref;
  input DAE.Prefix inPrefix;
  output FCore.Cache outCache;
  output DAE.ComponentRef outCref;
algorithm
  (outCache,outCref) := match (inCache,inEnv,inIH,inCref,inPrefix)
    local
      FCore.Cache cache;
      FCore.Graph env;
      Absyn.InnerOuter io;
      InstanceHierarchy ih;
      DAE.Prefix innerPrefix, pre;
      DAE.ComponentRef lastCref, cref, newCref;
      String n;


    case (cache,_,ih,cref,pre)
      equation
        newCref = InnerOuter.prefixOuterCrefWithTheInnerPrefix(ih, cref, pre);
      then
        (cache,newCref);

    /*
    // adrpo: prefix normally if we have an inner outer variable!
    case (cache,env,ih,cref,pre)
      equation
        (cache,DAE.ATTR(innerOuter = io),_,_,_,_) = Lookup.lookupVarLocal(cache, env, cref);
        // fprintln(Flags.INNER_OUTER, printPrefixStr(inPrefix) + "/" + ComponentReference.printComponentRefStr(cref) +
        //   if_(AbsynUtil.isOuter(io), " [outer] ", " ") +
        //   if_(AbsynUtil.isInner(io), " [inner] ", " "));
        true = AbsynUtil.isInner(io);
        false = AbsynUtil.isOuter(io);
        // prefix normally
        newCref = prefixCref(pre, cref);
        // fprintln(Flags.INNER_OUTER, "INNER normally prefixed: " + ComponentReference.printComponentRefStr(newCref));
      then
        (cache,newCref);

    // adrpo: prefix with *CORRECT* prefix from inner if we have an outer variable!
    case (cache,env,ih,cref as DAE.CREF_IDENT(ident=_),pre)
      equation
        (cache,DAE.ATTR(innerOuter = io),_,_,_,_) = Lookup.lookupVarLocal(cache, env, cref);
        // fprintln(Flags.INNER_OUTER, printPrefixStr(inPrefix) + "/" + ComponentReference.printComponentRefStr(cref) +
        //   if_(AbsynUtil.isOuter(io), " [outer] ", " ") +
        //   if_(AbsynUtil.isInner(io), " [inner] ", " "));
        true = AbsynUtil.isOuter(io);
        n = ComponentReference.crefLastIdent(cref);
        lastCref = Expression.crefIdent(cref);
        // search in the instance hierarchy for the *CORRECT* prefix for this outer variable!
        InnerOuter.INST_INNER(innerPrefix=innerPrefix, instResult=SOME(_)) =
           InnerOuter.lookupInnerVar(cache, env, ih, pre, n, io);
        // prefix the cref with the prefix of the INNER!

        newCref = prefixCref(innerPrefix, lastCref);

        // fprintln(Flags.INNER_OUTER, "OUTER IDENT prefixed INNER : " + ComponentReference.printComponentRefStr(newCref));
      then
        (cache,newCref);

    // adrpo: we have a qualified cref, search for the prefix!
    // bar2/world.someCrap
    case (cache,env,ih,cref as DAE.CREF_QUAL(ident=_),pre)
      equation
        (cache,DAE.ATTR(innerOuter = io),_,_,_,_) = Lookup.lookupVarLocal(cache, env, cref);
        true = AbsynUtil.isOuter(io);
        (cache,innerPrefix) = searchForInnerPrefix(cache,env,ih,cref,pre,io);
        newCref = prefixCref(innerPrefix, cref);
        // fprintln(Flags.INNER_OUTER, "OUTER QUAL prefixed INNER: " + ComponentReference.printComponentRefStr(newCref));
      then
        (cache,newCref);
    */
  end match;
end prefixCrefInnerOuter;

public function prefixExp "Add the supplied prefix to all component references in an expression."
  input output FCore.Cache cache;
  input FCore.Graph env;
  input InnerOuter.InstHierarchy ih;
  input output DAE.Exp exp;
  input DAE.Prefix pre;
algorithm
  try
    (cache, exp) := prefixExpWork(cache, env, ih, exp, pre);
  else
    Error.addInternalError(getInstanceName() + " failed on exp: " + ExpressionDump.printExpStr(exp) + " " + makePrefixString(pre), sourceInfo());
    fail();
  end try;
end prefixExp;

protected function prefixExpWork "Add the supplied prefix to all component references in an expression."
  input output FCore.Cache cache;
  input FCore.Graph env;
  input InnerOuter.InstHierarchy ih;
  input DAE.Exp inExp;
  input DAE.Prefix pre;
  output DAE.Exp outExp;
algorithm
  (cache,outExp) := match (inExp,pre)
    local
      DAE.Exp e,e1_1,e2_1,e1,e2,e3_1,e3,cref_1,dim_1,cref,dim,start_1,stop_1,start,stop,step_1,step,e_1,exp_1,exp,crefExp;
      DAE.ComponentRef cr,cr_1;
      DAE.Operator o;
      list<DAE.Exp> es_1,es;
      Absyn.Path f;
      Boolean sc;
      list<DAE.Exp> x_1,x;
      list<list<DAE.Exp>> xs_1,xs;
      String s;
      list<DAE.Exp> expl;
      DAE.Prefix p;
      Integer b,a;
      DAE.Type t,tp;
      Integer index_;
      Option<tuple<DAE.Exp,Integer,Integer>> isExpisASUB;
      DAE.ReductionInfo reductionInfo;
      DAE.ReductionIterators riters;
      DAE.CallAttributes attr;
      list<String> fieldNames;
      DAE.ClockKind clk;

    // no prefix, return the input expression
    case (e,DAE.NOPRE())
      guard not System.getHasInnerOuterDefinitions()
      then (cache,e);

    // handle literal constants
    case ((e as DAE.ICONST()),_) then (cache,e);
    case ((e as DAE.RCONST()),_) then (cache,e);
    case ((e as DAE.SCONST()),_) then (cache,e);
    case ((e as DAE.BCONST()),_) then (cache,e);
    case ((e as DAE.ENUM_LITERAL()), _) then (cache, e);

    // adrpo: handle prefixing of inner/outer variables
    case (DAE.CREF(componentRef = cr,ty = t),_)
      algorithm
        if System.getHasInnerOuterDefinitions() and not listEmpty(ih) then
          try
            cr_1 := InnerOuter.prefixOuterCrefWithTheInnerPrefix(ih, cr, pre);
            (cache, t) := prefixExpressionsInType(cache, env, ih, pre, t);
            outExp := Expression.makeCrefExp(cr_1, t);
            return;
          else
          end try;
        end if;
        if valueEq(DAE.NOPRE(), pre) then
          crefExp := inExp;
        else
          (cache, crefExp) := prefixExpCref(cache, env, ih, inExp, pre);
        end if;
      then (cache,crefExp);

    // clocks
    case (DAE.CLKCONST(clk), _)
      equation
        (cache, clk) = prefixClockKind(cache, env, ih, clk, pre);
      then
        (cache, DAE.CLKCONST(clk));

    case ((DAE.ASUB(exp = e1, sub = expl)),_)
      equation
        (cache, es_1) = prefixExpList(cache, env, ih, expl, pre);
        (cache, e1) = prefixExpWork(cache, env, ih, e1, pre);
        e2 = Expression.makeASUB(e1,es_1);
      then
        (cache, e2);

    case ((DAE.TSUB(e1, index_, t)),_)
      equation
        (cache,e1) = prefixExpWork(cache, env, ih, e1, pre);
        e2 = DAE.TSUB(e1, index_, t);
      then
        (cache,e2);

    case (DAE.BINARY(exp1 = e1,operator = o,exp2 = e2),_)
      equation
        (cache,e1_1) = prefixExpWork(cache, env, ih, e1, pre);
        (cache,e2_1) = prefixExpWork(cache, env, ih, e2, pre);
      then
        (cache,DAE.BINARY(e1_1,o,e2_1));

    case (DAE.UNARY(operator = o,exp = e1),_)
      equation
        (cache,e1_1) = prefixExpWork(cache, env, ih, e1, pre);
      then
        (cache,DAE.UNARY(o,e1_1));

    case (DAE.LBINARY(exp1 = e1,operator = o,exp2 = e2),_)
      equation
        (cache,e1_1) = prefixExpWork(cache, env, ih, e1, pre);
        (cache,e2_1) = prefixExpWork(cache, env, ih, e2, pre);
      then
        (cache,DAE.LBINARY(e1_1,o,e2_1));

    case (DAE.LUNARY(operator = o,exp = e1),_)
      equation
        (cache,e1_1) = prefixExpWork(cache, env, ih, e1, pre);
      then
        (cache,DAE.LUNARY(o,e1_1));

    case (DAE.RELATION(exp1 = e1,operator = o,exp2 = e2, index=index_, optionExpisASUB= isExpisASUB),_)
      equation
        (cache,e1_1) = prefixExpWork(cache, env, ih, e1, pre);
        (cache,e2_1) = prefixExpWork(cache, env, ih, e2, pre);
      then
        (cache,DAE.RELATION(e1_1,o,e2_1,index_,isExpisASUB));

    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),_)
      equation
        (cache,e1_1) = prefixExpWork(cache, env, ih, e1, pre);
        (cache,e2_1) = prefixExpWork(cache, env, ih, e2, pre);
        (cache,e3_1) = prefixExpWork(cache, env, ih, e3, pre);
      then
        (cache,DAE.IFEXP(e1_1,e2_1,e3_1));

    case (DAE.SIZE(exp = cref,sz = SOME(dim)),_)
      equation
        (cache,cref_1) = prefixExpWork(cache, env, ih, cref, pre);
        (cache,dim_1) = prefixExpWork(cache, env, ih, dim, pre);
      then
        (cache,DAE.SIZE(cref_1,SOME(dim_1)));

    case (DAE.SIZE(exp = cref,sz = NONE()),_)
      equation
        (cache,cref_1) = prefixExpWork(cache, env, ih, cref, pre);
      then
        (cache,DAE.SIZE(cref_1,NONE()));

    case (DAE.CALL(f,es,attr),_)
      equation
        (cache,es_1) = prefixExpList(cache, env, ih, es, pre);
      then
        (cache,DAE.CALL(f,es_1,attr));

    case (e as DAE.PARTEVALFUNCTION(),_)
      algorithm
        (cache,es_1) := prefixExpList(cache, env, ih, e.expList, pre);
        e.expList := es_1;
      then (cache,e);

    case (DAE.RECORD(f,es,fieldNames,t),_)
      equation
        (cache,_) = prefixExpList(cache, env, ih, es, pre);
      then
        (cache,DAE.RECORD(f,es,fieldNames,t));

    case (DAE.ARRAY(ty = t,scalar = sc,array = {}),_)
      then (cache, inExp);

    case (DAE.ARRAY(ty = t,scalar = sc,array = es),_)
      equation
        (cache,es_1) = prefixExpList(cache, env, ih, es, pre);
      then
        (cache,DAE.ARRAY(t,sc,es_1));

    case (DAE.TUPLE(PR = es),_)
      equation
        (cache,es_1) = prefixExpList(cache, env, ih, es, pre);
      then
        (cache,DAE.TUPLE(es_1));

    case (DAE.MATRIX(ty = t,integer = a,matrix = {}),_)
      then (cache,inExp);

    case (DAE.MATRIX(ty = t,integer = a,matrix = (x :: xs)),_)
      equation
        (cache,x_1) = prefixExpList(cache, env, ih, x, pre);
        (cache,DAE.MATRIX(t,_,xs_1)) = prefixExpWork(cache, env, ih, DAE.MATRIX(t,a,xs), pre);
      then
        (cache,DAE.MATRIX(t,a,(x_1 :: xs_1)));

    case (DAE.RANGE(ty = t,start = start,step = NONE(),stop = stop),_)
      equation
        (cache,start_1) = prefixExpWork(cache, env, ih, start, pre);
        (cache,stop_1) = prefixExpWork(cache, env, ih, stop, pre);
      then
        (cache,DAE.RANGE(t,start_1,NONE(),stop_1));

    case (DAE.RANGE(ty = t,start = start,step = SOME(step),stop = stop),_)
      equation
        (cache,start_1) = prefixExpWork(cache, env, ih, start, pre);
        (cache,step_1) = prefixExpWork(cache, env, ih, step, pre);
        (cache,stop_1) = prefixExpWork(cache, env, ih, stop, pre);
      then
        (cache,DAE.RANGE(t,start_1,SOME(step_1),stop_1));

    case (DAE.CAST(ty = tp,exp = e),_)
      equation
        (cache,e_1) = prefixExpWork(cache, env, ih, e, pre);
      then
        (cache,DAE.CAST(tp,e_1));

    case (DAE.REDUCTION(reductionInfo = reductionInfo,expr = exp,iterators = riters),_)
      equation
        (cache,exp_1) = prefixExpWork(cache, env, ih, exp, pre);
        (cache,riters) = prefixIterators(cache, env, ih, riters, pre);
      then
        (cache,DAE.REDUCTION(reductionInfo,exp_1,riters));

    // MetaModelica extension. KS
    case (DAE.LIST(es),_)
      equation
        (cache,es_1) = prefixExpList(cache, env, ih, es, pre);
      then (cache,DAE.LIST(es_1));

    case (DAE.CONS(e1,e2),_)
      equation
        (cache,e1) = prefixExpWork(cache, env, ih, e1, pre);
        (cache,e2) = prefixExpWork(cache, env, ih, e2, pre);
      then (cache,DAE.CONS(e1,e2));

    case (DAE.META_TUPLE(es),_)
      equation
        (cache,es_1) = prefixExpList(cache, env, ih, es, pre);
      then (cache,DAE.META_TUPLE(es_1));

    case (DAE.META_OPTION(SOME(e1)),_)
      equation
        (cache,e1) = prefixExpWork(cache, env, ih, e1, pre);
      then (cache,DAE.META_OPTION(SOME(e1)));

    case (DAE.META_OPTION(NONE()),_)
      equation
      then (cache,DAE.META_OPTION(NONE()));

    case (DAE.METARECORDCALL(), _)
      algorithm
        (cache, expl) := prefixExpList(cache, env, ih, inExp.args, pre);
      then
        (cache, DAE.METARECORDCALL(inExp.path, expl, inExp.fieldNames, inExp.index, inExp.typeVars));

    case (e as DAE.UNBOX(e1),_)
      equation
        (cache,e1) = prefixExpWork(cache, env, ih, e1, pre);
        e.exp = e1;
      then (cache,e);

    case (e as DAE.BOX(e1),_)
      equation
        (cache,e1) = prefixExpWork(cache, env, ih, e1, pre);
        e.exp = e1;
      then (cache,e);
        // ------------------------

    // no prefix, return the input expression
    case (e,DAE.NOPRE()) then (cache,e);

    case (e as DAE.EMPTY(),_) then (cache,e);

    else
      algorithm
        Error.addInternalError(getInstanceName() + " failed on exp: " + ExpressionDump.printExpStr(inExp) + " " + makePrefixString(pre), sourceInfo());
      then fail();
  end match;
end prefixExpWork;

protected function prefixExpCref
  "Helper function to prefixExp for prefixing a cref expression."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InstanceHierarchy inIH;
  input DAE.Exp inCref;
  input DAE.Prefix inPrefix;
  output FCore.Cache outCache;
  output DAE.Exp outCref;
protected
  Option<Boolean> is_iter;
  FCore.Cache cache;
  DAE.ComponentRef cr;
algorithm
  DAE.CREF(componentRef = cr) := inCref;
  (is_iter, cache) := Lookup.isIterator(inCache, inEnv, cr);
  (outCache, outCref) := prefixExpCref2(cache, inEnv, inIH, is_iter, inCref, inPrefix);
end prefixExpCref;

protected function prefixExpCref2
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InstanceHierarchy inIH;
  input Option<Boolean> inIsIter;
  input DAE.Exp inCref;
  input DAE.Prefix inPrefix;
  output FCore.Cache outCache;
  output DAE.Exp outCref;
algorithm
  (outCache, outCref) := match(inCache, inEnv, inIH, inIsIter, inCref, inPrefix)
    local
      FCore.Cache cache;
      DAE.ComponentRef cr;
      DAE.Type ty;
      DAE.Exp exp;

    // A cref found in the current scope that's not an iterator.
    case (cache, _, _, SOME(false), DAE.CREF(componentRef = cr, ty = ty), _)
      equation
        (cache, cr) = prefixCref(cache, inEnv, inIH, inPrefix, cr);
        (cache, ty) = prefixExpressionsInType(cache, inEnv, inIH, inPrefix, ty);
        exp = Expression.makeCrefExp(cr, ty);
      then
        (cache, exp);

    // An iterator, shouldn't be prefixed.
    case (_, _, _, SOME(true), _, _)
      then (inCache, inCref);

    // A cref not found in the current scope.
    case (cache, _, _, NONE(), DAE.CREF(componentRef = cr, ty = ty), _)
      equation
        (cache, cr) = prefixSubscriptsInCref(cache, inEnv, inIH, inPrefix, cr);
        (cache, ty) = prefixExpressionsInType(cache, inEnv, inIH, inPrefix, ty);
        exp = Expression.makeCrefExp(cr, ty);
      then
        (cache, exp);

  end match;
end prefixExpCref2;

protected function prefixIterators
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InstanceHierarchy ih;
  input DAE.ReductionIterators inIters;
  input DAE.Prefix pre;
  output FCore.Cache outCache;
  output DAE.ReductionIterators outIters;
algorithm
  (outCache,outIters) := match (inCache,inEnv,ih,inIters,pre)
    local
      String id;
      DAE.Exp exp,gexp;
      DAE.Type ty;
      DAE.ReductionIterator iter;
      FCore.Cache cache;
      FCore.Graph env;
      DAE.ReductionIterators iters;

    case (cache,_,_,{},_) then (cache,{});
    case (cache,env,_,DAE.REDUCTIONITER(id,exp,SOME(gexp),ty)::iters,_)
      equation
        (cache,exp) = prefixExpWork(cache,env,ih,exp,pre);
        (cache,gexp) = prefixExpWork(cache,env,ih,gexp,pre);
        iter = DAE.REDUCTIONITER(id,exp,SOME(gexp),ty);
        (cache,iters) = prefixIterators(cache,env,ih,iters,pre);
      then (cache,iter::iters);
    case (cache,env,_,DAE.REDUCTIONITER(id,exp,NONE(),ty)::iters,_)
      equation
        (cache,exp) = prefixExpWork(cache,env,ih,exp,pre);
        iter = DAE.REDUCTIONITER(id,exp,NONE(),ty);
        (cache,iters) = prefixIterators(cache,env,ih,iters,pre);
      then (cache,iter::iters);
  end match;
end prefixIterators;

public function prefixExpList "This function prefixes a list of expressions using the prefixExp function."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input list<DAE.Exp> inExpExpLst;
  input DAE.Prefix inPrefix;
  output FCore.Cache outCache = inCache;
  output list<DAE.Exp> outExpExpLst = {};
protected
  DAE.Exp e_1;
algorithm
  for e in inExpExpLst loop
    (outCache,e_1) := prefixExpWork(outCache, inEnv, inIH, e, inPrefix);
    outExpExpLst := e_1::outExpExpLst;
  end for;
  outExpExpLst := Dangerous.listReverseInPlace(outExpExpLst);
end prefixExpList;

//--------------------------------------------
//   PART OF THE WORKAROUND FOR VALUEBLOCKS. KS
protected function prefixStatements "Prefix statements.
  PART OF THE WORKAROUND FOR VALUEBLOCKS"
  input FCore.Cache cache;
  input FCore.Graph env;
  input InstanceHierarchy inIH;
  input list<DAE.Statement> stmts;
  input DAE.Prefix p;
  output FCore.Cache outCache = cache;
  output list<DAE.Statement> outStmts = {};
protected
algorithm
  for st in stmts loop
    _ := match st
      local
        DAE.Type t;
        DAE.Exp e,e1,e2,e3;
        DAE.ElementSource source;
        DAE.Statement elem;

      list<DAE.Statement> localAccList,rest;
      DAE.Prefix pre;
      InstanceHierarchy ih;
      list<DAE.Statement> elems,sList,b;
      String s,id;
      list<DAE.Exp> eLst;
      DAE.ComponentRef cRef;
      Boolean bool;
      DAE.Else elseBranch;
      Integer ix;
      case DAE.STMT_ASSIGN(t,e1,e,source)
        equation
          (outCache,e1) = prefixExpWork(outCache,env,inIH,e1,p);
          (outCache,e) = prefixExpWork(outCache,env,inIH,e,p);
          elem = DAE.STMT_ASSIGN(t,e1,e,source);
          outStmts = elem::outStmts;
        then ();

      case DAE.STMT_TUPLE_ASSIGN(t,eLst,e,source)
        equation
          (outCache,e) = prefixExpWork(outCache,env,inIH,e,p);
          (outCache,eLst) = prefixExpList(outCache,env,inIH,eLst,p);
          elem = DAE.STMT_TUPLE_ASSIGN(t,eLst,e,source);
          outStmts = elem::outStmts;
        then ();

      case DAE.STMT_ASSIGN_ARR(t,e1,e,source)
        equation
          (outCache,e1) = prefixExpWork(outCache,env,inIH,e1,p);
          (outCache,e) = prefixExpWork(outCache,env,inIH,e,p);
          elem = DAE.STMT_ASSIGN_ARR(t,e1,e,source);
          outStmts = elem::outStmts;
        then ();

      case DAE.STMT_FOR(t,bool,id,ix,e,sList,source)
        equation
          (outCache,e) = prefixExpWork(outCache,env,inIH,e,p);
          (outCache,sList) = prefixStatements(outCache,env,inIH,sList,p);
          elem = DAE.STMT_FOR(t,bool,id,ix,e,sList,source);
          outStmts = elem::outStmts;
        then ();

      case DAE.STMT_IF(e1,sList,elseBranch,source)
        equation
          (outCache,e1) = prefixExpWork(outCache,env,inIH,e1,p);
          (outCache,sList) = prefixStatements(outCache,env,inIH,sList,p);
          (outCache,elseBranch) = prefixElse(outCache,env,inIH,elseBranch,p);
          elem = DAE.STMT_IF(e1,sList,elseBranch,source);
          outStmts = elem::outStmts;
        then ();

      case DAE.STMT_WHILE(e1,sList,source)
        equation
          (outCache,e1) = prefixExpWork(outCache,env,inIH,e1,p);
          (outCache,sList) = prefixStatements(outCache,env,inIH,sList,p);
          elem = DAE.STMT_WHILE(e1,sList,source);
          outStmts = elem::outStmts;
        then ();

      case DAE.STMT_ASSERT(e1,e2,e3,source)
        equation
          (outCache,e1) = prefixExpWork(outCache,env,inIH,e1,p);
          (outCache,e2) = prefixExpWork(outCache,env,inIH,e2,p);
          (outCache,e3) = prefixExpWork(outCache,env,inIH,e3,p);
          elem = DAE.STMT_ASSERT(e1,e2,e3,source);
          outStmts = elem::outStmts;
        then ();

      case DAE.STMT_FAILURE(b,source)
        equation
          (outCache,b) = prefixStatements(outCache,env,inIH,b,p);
          elem = DAE.STMT_FAILURE(b,source);
          outStmts = elem::outStmts;
        then ();

      case DAE.STMT_RETURN(source)
        equation
          elem = DAE.STMT_RETURN(source);
          outStmts = elem::outStmts;
        then ();

      case DAE.STMT_BREAK(source)
        equation
          elem = DAE.STMT_BREAK(source);
          outStmts = elem::outStmts;
        then ();
    end match;
  end for;
  outStmts := Dangerous.listReverseInPlace(outStmts);
end prefixStatements;

protected function prefixElse "Prefix else statements.
  PART OF THE WORKAROUND FOR VALUEBLOCKS"
  input FCore.Cache cache;
  input FCore.Graph env;
  input InstanceHierarchy inIH;
  input DAE.Else elseBranch;
  input DAE.Prefix p;
  output FCore.Cache outCache;
  output DAE.Else outElse;
algorithm
  (outCache,outElse) := match (cache,env,inIH,elseBranch,p)
    local
      FCore.Cache localCache;
      FCore.Graph localEnv;
      DAE.Prefix pre;
      InstanceHierarchy ih;
      DAE.Exp e;
      list<DAE.Statement> lStmt;
      DAE.Else el,stmt;

    case (localCache,_,_,DAE.NOELSE(),_)
      then (localCache,DAE.NOELSE());

    case (localCache,localEnv,ih,DAE.ELSEIF(e,lStmt,el),pre)
      equation
        (localCache,e) = prefixExpWork(localCache,localEnv,ih,e,pre);
        (localCache,el) = prefixElse(localCache,localEnv,ih,el,pre);
        (localCache,lStmt) = prefixStatements(localCache,localEnv,ih,lStmt,pre);
        stmt = DAE.ELSEIF(e,lStmt,el);
      then (localCache,stmt);

    case (localCache,localEnv,ih,DAE.ELSE(lStmt),pre)
      equation
       (localCache,lStmt) = prefixStatements(localCache,localEnv,ih,lStmt,pre);
        stmt = DAE.ELSE(lStmt);
      then (localCache,stmt);
  end match;
end prefixElse;

public function makePrefixString "helper function for Mod.verifySingleMod, pretty output"
  input DAE.Prefix pre;
  output String str;
algorithm
  str := matchcontinue(pre)
    case(DAE.NOPRE()) then "from top scope";
    case _
      equation
        str = "from calling scope: " + printPrefixStr(pre);
      then str;
  end matchcontinue;
end makePrefixString;

public function prefixExpressionsInType
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Prefix inPre;
  input DAE.Type inTy;
  output FCore.Cache outCache;
  output DAE.Type outTy;
algorithm
  (outCache, outTy) := matchcontinue(inCache, inEnv, inIH, inPre, inTy)
    // don't do this for MetaModelica!
    case (_, _, _, _, _)
      equation
        true = Config.acceptMetaModelicaGrammar();
      then
       (inCache, inTy);

    else
      equation
        (outTy, (outCache, _, _, _)) = Types.traverseType(inTy, (inCache, inEnv, inIH, inPre), prefixArrayDimensions);
      then
        (outCache, outTy);
  end matchcontinue;
end prefixExpressionsInType;

protected function prefixArrayDimensions
"@author: adrpo
 this function prefixes all the expressions in types to be found by the back-end or code generation!"
  input DAE.Type ty;
  input tuple<FCore.Cache,FCore.Graph,InnerOuter.InstHierarchy,DAE.Prefix> tpl;
  output DAE.Type oty = ty;
  output tuple<FCore.Cache,FCore.Graph,InnerOuter.InstHierarchy,DAE.Prefix> otpl;
algorithm
  (oty,otpl) := match (oty,tpl)
    local
      FCore.Cache cache;
      FCore.Graph env;
      InnerOuter.InstHierarchy ih;
      DAE.Prefix pre;
      DAE.Dimensions dims;

    case (DAE.T_ARRAY(),(cache, env, ih, pre))
      equation
        (cache, dims) = prefixDimensions(cache, env, ih, pre, oty.dims);
        oty.dims = dims;
      then
        (oty,(cache, env, ih, pre));

    else (oty,tpl);

  end match;
end prefixArrayDimensions;

public function prefixDimensions
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.Prefix inPre;
  input DAE.Dimensions inDims;
  output FCore.Cache outCache;
  output DAE.Dimensions outDims;
algorithm
  (outCache,outDims) := matchcontinue(inCache, inEnv, inIH, inPre, inDims)
    local
      DAE.Exp e;
      DAE.Dimensions rest, new;
      DAE.Dimension d;
      FCore.Cache cache;

    case (_, _, _, _, {}) then (inCache, {});

    case (_, _, _, _, DAE.DIM_EXP(exp=e)::rest)
      equation
        (cache, e) = prefixExpWork(inCache, inEnv, inIH, e, inPre);
        (cache, new) = prefixDimensions(cache, inEnv, inIH, inPre, rest);
      then
        (cache, DAE.DIM_EXP(e)::new);

    case (_, _, _, _, d::rest)
      equation
        (cache, new) = prefixDimensions(inCache, inEnv, inIH, inPre, rest);
      then
        (cache, d::new);
  end matchcontinue;
end prefixDimensions;

public function isPrefix
  input DAE.Prefix prefix;
  output Boolean isPrefix;
algorithm
  isPrefix := match prefix
    case DAE.PREFIX() then true;
    else false;
  end match;
end isPrefix;

public function isNoPrefix
  input DAE.Prefix inPrefix;
  output Boolean outIsEmpty;
algorithm
  outIsEmpty := match(inPrefix)
    case DAE.NOPRE() then true;
    else false;
  end match;
end isNoPrefix;

public function prefixClockKind "Add the supplied prefix to the clock kind"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InnerOuter.InstHierarchy inIH;
  input DAE.ClockKind inClkKind;
  input DAE.Prefix inPrefix;
  output FCore.Cache outCache;
  output DAE.ClockKind outClkKind;
algorithm
  (outCache, outClkKind) := match (inCache, inEnv, inIH, inClkKind, inPrefix)
    local
      DAE.Exp e,resolution,interval,method;
      DAE.ClockKind clkKind;
      FCore.Cache cache;
      FCore.Graph env;
      InstanceHierarchy ih;
      DAE.Prefix p;

    // clock kinds
    case (cache, _, _, DAE.INFERRED_CLOCK(), _)
      then (cache, inClkKind);

    case (cache, env, ih, DAE.INTEGER_CLOCK(e, resolution), p)
      equation
        (cache, e) = prefixExpWork(cache, env, ih, e, p);
        (cache, resolution) = prefixExpWork(cache, env, ih, resolution, p);
        clkKind = DAE.INTEGER_CLOCK(e, resolution);
      then
        (cache, clkKind);

    case (cache, env, ih, DAE.REAL_CLOCK(e), p)
      equation
        (cache, e) = prefixExpWork(cache, env, ih, e, p);
        clkKind = DAE.REAL_CLOCK(e);
      then
        (cache, clkKind);

    case (cache, env, ih, DAE.BOOLEAN_CLOCK(e, interval), p)
      equation
        (cache, e) = prefixExpWork(cache, env, ih, e, p);
        (cache, interval) = prefixExpWork(cache, env, ih, interval, p);
        clkKind = DAE.BOOLEAN_CLOCK(e, interval);
      then
        (cache, clkKind);

    case (cache, env, ih, DAE.SOLVER_CLOCK(e, method), p)
      equation
        (cache, e) = prefixExpWork(cache, env, ih, e, p);
        (cache, method) = prefixExpWork(cache, env, ih, method, p);
        clkKind = DAE.SOLVER_CLOCK(e, method);
      then
        (cache, clkKind);

  end match;
end prefixClockKind;

public function getPrefixInfo
  input DAE.Prefix inPrefix;
  output SourceInfo outInfo;
algorithm
  outInfo := match inPrefix
    case DAE.PREFIX(compPre = DAE.PRE(info = outInfo)) then outInfo;
    else AbsynUtil.dummyInfo;
  end match;
end getPrefixInfo;

public function prefixHashWork
  input DAE.ComponentPrefix inPrefix;
  input output Integer hash;
algorithm
  hash := match inPrefix
    case DAE.PRE() then prefixHashWork(inPrefix.next, 31*hash + stringHashDjb2(inPrefix.prefix));
    else hash;
  end match;
end prefixHashWork;

public function componentPrefixPathEqual
  input DAE.ComponentPrefix pre1,pre2;
  output Boolean eq;
algorithm
  eq := match (pre1,pre2)
    case (DAE.PRE(),DAE.PRE())
      then if pre1.prefix==pre2.prefix then componentPrefixPathEqual(pre1.next, pre2.next) else false;
    case (DAE.NOCOMPPRE(),DAE.NOCOMPPRE()) then true;
    else false;
  end match;
end componentPrefixPathEqual;

public function componentPrefix
  input DAE.Prefix inPrefix;
  output DAE.ComponentPrefix outPrefix;
algorithm
  outPrefix := match inPrefix
    case DAE.PREFIX() then inPrefix.compPre;
    else DAE.NOCOMPPRE();
  end match;
end componentPrefix;

public function writeComponentPrefix
  input File.File file;
  input DAE.ComponentPrefix pre;
  input File.Escape escape=File.Escape.None;
algorithm
  _ := match pre
    case DAE.PRE(next=DAE.NOCOMPPRE())
    algorithm
      File.writeEscape(file, pre.prefix, escape);
      ComponentReference.writeSubscripts(file, pre.subscripts, escape);
    then ();
    case DAE.PRE()
    algorithm
      writeComponentPrefix(file, pre.next); // Stored in reverse order...
      File.writeEscape(file, pre.prefix, escape);
      ComponentReference.writeSubscripts(file, pre.subscripts, escape);
    then ();
    else ();
  end match;
end writeComponentPrefix;

public function hasSubs "Function: crefHaveSubs
  Checks whether Prefix has any subscripts, recursive "
  input DAE.ComponentPrefix pre;
  output Boolean ob;
algorithm
  ob := match pre
    case DAE.PRE(subscripts = {}) then hasSubs(pre.next);
    case DAE.PRE() then true;
    else false;
  end match;
end hasSubs;

function removeCompPrefixFromExps
  input DAE.Exp inExp;
  input DAE.ComponentPrefix inCompPref;
  output DAE.Exp outExp;
algorithm
  outExp := Expression.traverseExpBottomUp(inExp, function removeCompPrefixFromCrefExp(inCompPref = inCompPref), false);
end removeCompPrefixFromExps;

protected function removeCompPrefixFromCrefExp
  input DAE.Exp inExp;
  input Boolean inB;
  input DAE.ComponentPrefix inCompPref;
  output DAE.Exp outExp;
  output Boolean b;
algorithm
  (outExp,b) := match (inExp)
    local
      DAE.Exp exp;
      DAE.ComponentRef cref;

    case (exp as DAE.CREF(DAE.CREF_QUAL()))
      algorithm
        cref := removePrefixFromCref(exp.componentRef, inCompPref);
        exp.componentRef := cref;
      then
        (exp, true);

    else (inExp, inB);
  end match;
end removeCompPrefixFromCrefExp;

protected function removePrefixFromCref
  input DAE.ComponentRef inCref;
  input DAE.ComponentPrefix inCompPref;
  output DAE.ComponentRef outCref;
algorithm
  (outCref) := match (inCref, inCompPref)
    local
      DAE.ComponentRef cref, cref2;
      DAE.ComponentPrefix pref;

    case (_, DAE.NOCOMPPRE()) then inCref;
    case (DAE.CREF_IDENT(), _) then inCref;

    case (cref as DAE.CREF_QUAL(_), pref as DAE.PRE(next=DAE.NOCOMPPRE())) algorithm
      if stringEqual(cref.ident, pref.prefix) then
        cref2 := cref.componentRef;
      else
        cref2 := cref;
      end if;
    then
      cref.componentRef;

    case (DAE.CREF_QUAL(_), pref as DAE.PRE(next=DAE.PRE(_))) algorithm
      cref := removePrefixFromCref(inCref,pref.next);
      pref.next := DAE.NOCOMPPRE();
      cref := removePrefixFromCref(cref,pref);
    then
      cref;

    case (_, DAE.PRE()) algorithm
      Error.addInternalError(getInstanceName() + " :Cref is not qualified but we have prefix to remove: " + ComponentReference.crefStr(inCref), sourceInfo());
    then
      fail();

    else algorithm
      Error.addInternalError(getInstanceName() + " :failed on cref: " + ComponentReference.crefStr(inCref), sourceInfo());
    then
      fail();
  end match;
end removePrefixFromCref;

annotation(__OpenModelica_Interface="frontend");
end PrefixUtil;
