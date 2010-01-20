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

package Prefix
" file:	       Prefix.mo
  package:     Prefix
  description: Prefix management

  RCS: $Id$

  When instantiating an expression, there is a prefix that
  has to be added to each variable name to be able to use it in the
  flattened equation set.

  A prefix for a variable x could be for example a.b.c so that the
  fully qualified name is a.b.c.x."


public import Absyn;
public import DAE;
public import Env;
public import Lookup;
public import SCode;
public import RTOpts;

public 
uniontype Prefix "A Prefix has a component prefix and a class prefix. 
The component prefix consist of a name an a list of constant valued subscripts.
The class prefix contains the variability of the class, i.e unspecified, parameter or constant."

  record NOPRE "No prefix information" end NOPRE ;

  record PREFIX 
       ComponentPrefix compPre;
       ClassPrefix classPre;
  end PREFIX;
end Prefix;

uniontype ComponentPrefix "Prefix for component name, e.g. a.b[2].c" 
  record PRE
    String prefix "prefix name" ;
    list<Integer> subscripts "subscripts" ;
    ComponentPrefix next "next prefix" ;
  end PRE;
  record NOCOMPPRE end NOCOMPPRE;
end ComponentPrefix;

uniontype ClassPrefix "Prefix for classes is its variability"
  record CLASSPRE
    SCode.Variability variability "VAR, DISCRETE, PARAM, or CONST";
  end CLASSPRE;
end ClassPrefix;

protected import ClassInf;
protected import Debug;
protected import Exp;
protected import Print;
protected import Util;

public function printPrefixStr "function: printPrefixStr
  Prints a Prefix to a string."
  input Prefix inPrefix;
  output String outString;
algorithm 
  outString :=  matchcontinue (inPrefix)
    local
      String str,s,rest_1,s_1,s_2;
      ComponentPrefix rest;
      ClassPrefix cp;
    case NOPRE() then "<NOPRE>"; 
    case PREFIX(PRE(str,{},NOCOMPPRE()),_) then str; 
    case PREFIX(PRE(str,_,NOCOMPPRE()),_)
      equation 
        s = stringAppend(str, "[]");
      then
        s;
    case PREFIX(PRE(str,{},rest),cp)
      equation 
        rest_1 = printPrefixStr(PREFIX(rest,cp));
        s = stringAppend(rest_1, ".");
        s_1 = stringAppend(s, str);
      then
        s_1;
    case PREFIX(PRE(str,_,rest),cp)
      equation 
        rest_1 = printPrefixStr(PREFIX(rest,cp));
        s = stringAppend(rest_1, ".");
        s_1 = stringAppend(s, str);
        s_2 = stringAppend(s_1, "[]");
      then
        s_2;
  end matchcontinue;
end printPrefixStr;

public function printPrefix "function: printPrefix
 
  Prints a prefix to the Print buffer.
"
  input Prefix p;
  String s;
algorithm 
  s := printPrefixStr(p);
  Print.printBuf(s);
end printPrefix;

public function prefixAdd "function: prefixAdd
 
  This function is used to extend a prefix with another level.  If
  the prefix `a.b{10}.c\' is extended with `d\' and an empty subscript
  list, the resulting prefix is `a.b{10}.c.d\'.  Remember that
  prefixes components are stored in the opposite order from the
  normal order used when displaying them.
"
  input String inIdent;
  input list<Integer> inIntegerLst;
  input Prefix inPrefix;
  input SCode.Variability vt;
  output Prefix outPrefix;
algorithm 
  outPrefix:=
  matchcontinue (inIdent,inIntegerLst,inPrefix,vt)
    local
      String i;
      list<Integer> s;
      ComponentPrefix p;
    case (i,s,PREFIX(p,_),vt) then PREFIX(PRE(i,s,p),CLASSPRE(vt)); 
    case(i,s,NOPRE(),vt) then PREFIX(PRE(i,s,NOCOMPPRE()),CLASSPRE(vt));
  end matchcontinue;
end prefixAdd;

public function prefixFirst
  input Prefix inPrefix;
  output Prefix outPrefix;
algorithm 
  outPrefix:=
  matchcontinue (inPrefix)
    local
      String a;
      list<Integer> b;
      ClassPrefix cp;
      ComponentPrefix c;
    case (PREFIX(PRE(prefix = a,subscripts = b,next = c),cp)) then PREFIX(PRE(a,b,NOCOMPPRE()),cp); 
  end matchcontinue;
end prefixFirst;

public function prefixLast "function: prefixLast
 
  Returns the last NONPRE Prefix of a prefix
"
  input Prefix inPrefix;
  output Prefix outPrefix;
algorithm 
  outPrefix:=
  matchcontinue (inPrefix)
    local ComponentPrefix p;
      Prefix res;
      ClassPrefix cp;
    case ((res as PREFIX(PRE(next = NOCOMPPRE()),cp))) then res; 
    case (PREFIX(PRE(next = p),cp))
      equation 
        res = prefixLast(PREFIX(p,cp));
      then
        res;
  end matchcontinue;
end prefixLast;

public function prefixStripLast
"@author: adrpo
 remove the last prefix from the component prefix"
  input Prefix inPrefix;
  output Prefix outPrefix;
algorithm 
  outPrefix := matchcontinue (inPrefix)
    local
      ClassPrefix cp;
      ComponentPrefix compPre;
    // we can't remove what it isn't there!
    case (NOPRE()) then NOPRE();
    // if there isn't any next prefix, return NOPRE!
    case (PREFIX(compPre,cp))
      equation
         compPre = compPreStripLast(compPre);
      then PREFIX(compPre,cp);
  end matchcontinue;
end prefixStripLast;

protected function compPreStripLast
"@author: adrpo
 remove the last prefix from the component prefix"
  input ComponentPrefix inCompPrefix;
  output ComponentPrefix outCompPrefix;
algorithm
  outCompPrefix := matchcontinue(inCompPrefix)
    local
      String p;
      list<Integer> subs;
      ComponentPrefix next;
      
    // nothing to remove!
    case NOCOMPPRE() then NOCOMPPRE();
    // the last is already nothing
    case PRE(prefix = p, subscripts = subs, next = NOCOMPPRE())
    then NOCOMPPRE();
    // the last is already nothing
    case PRE(prefix = p, subscripts = subs, next = next)
      equation
        next = compPreStripLast(next);
      then 
        PRE(p, subs, next);      
   end matchcontinue;
end compPreStripLast;

public function prefixPath "function: prefixPath
 
  Prefix a `Path\' variable by adding the supplied prefix to it and
  returning a new `Path\'.
"
  input Absyn.Path inPath;
  input Prefix inPrefix;
  output Absyn.Path outPath;
algorithm 
  outPath:=
  matchcontinue (inPath,inPrefix)
    local
      Absyn.Path p,p_1;
      String s;
      ComponentPrefix ss;
      ClassPrefix cp;
    case (p,NOPRE()) then p; 
    case (p,PREFIX(PRE(prefix = s,next = NOCOMPPRE()),cp))
      equation 
        p_1 = Absyn.QUALIFIED(s,p);
      then
        p_1;
    case (p,PREFIX(PRE(prefix = s,next = ss),cp))
      equation 
        p_1 = prefixPath(Absyn.QUALIFIED(s,p), PREFIX(ss,cp));
      then
        p_1;
  end matchcontinue;
end prefixPath;

public function prefixToPath "function: prefixToPath
 
  Convert a Prefix to a `Path\'
"
  input Prefix inPrefix;
  output Absyn.Path outPath;
algorithm 
  outPath:=
  matchcontinue (inPrefix)
    local
      String s;
      Absyn.Path p;
      ComponentPrefix ss;
      ClassPrefix cp;
    case NOPRE()
      equation 
        /*Print.printBuf("#-- Error: Cannot convert empty prefix to a path\n");*/
      then
        fail();
    case PREFIX(PRE(prefix = s,next = NOCOMPPRE()),_) then Absyn.IDENT(s); 
    case PREFIX(PRE(prefix = s,next = ss),cp)
      equation 
        p = prefixToPath(PREFIX(ss,cp));
      then
        Absyn.QUALIFIED(s,p);
  end matchcontinue;
end prefixToPath;

public function prefixCref "function: prefixCref
  Prefix a ComponentRef variable by adding the supplied prefix to
  it and returning a new ComponentRef.
  LS: Changed to call prefixToCref which is more general now"
  input Prefix pre;
  input DAE.ComponentRef cref;
  output DAE.ComponentRef cref_1;
  DAE.ComponentRef cref_1;
algorithm 
  cref_1 := prefixToCref2(pre, SOME(cref));
end prefixCref;

public function prefixToCref "function: prefixToCref 
  Convert a prefix to a component reference."
  input Prefix pre;
  output DAE.ComponentRef cref_1;
  DAE.ComponentRef cref_1;
algorithm 
  cref_1 := prefixToCref2(pre, NONE());
end prefixToCref;

protected function prefixToCref2 "function: prefixToCref2
  Convert a prefix to a component reference. Converting NOPRE with no
  component reference is an error because a component reference cannot be
  empty"
  input Prefix inPrefix;
  input Option<DAE.ComponentRef> inExpComponentRefOption;
  output DAE.ComponentRef outComponentRef;
algorithm 
  outComponentRef := matchcontinue (inPrefix,inExpComponentRefOption)
    local
      DAE.ComponentRef cref,cref_1;
      list<DAE.Subscript> s_1;
      String i;
      list<Integer> s;
      ComponentPrefix xs;
      ClassPrefix cp;
    case (NOPRE(),NONE)
      equation 
      then
        fail();
    case (NOPRE(),SOME(cref)) then cref; 
    case (PREFIX(NOCOMPPRE(),_),SOME(cref)) then cref;       
    case (PREFIX(PRE(prefix = i,subscripts = s,next = xs),cp),NONE)
      equation 
        s_1 = Exp.intSubscripts(s);
        cref_1 = prefixToCref2(PREFIX(xs,cp), SOME(DAE.CREF_IDENT(i,DAE.ET_COMPLEX("",{},ClassInf.UNKNOWN("")),s_1)));
      then
        cref_1;
    case (PREFIX(PRE(prefix = i,subscripts = s,next = xs),cp),SOME(cref))
      equation 
        s_1 = Exp.intSubscripts(s);
        cref_1 = prefixToCref2(PREFIX(xs,cp), SOME(DAE.CREF_QUAL(i,DAE.ET_COMPLEX("",{},ClassInf.UNKNOWN("")),s_1,cref)));
      then
        cref_1;
  end matchcontinue;
end prefixToCref2;

public function prefixToCrefOpt "function: prefixToCref 
  Convert a prefix to an optional component reference."
  input Prefix pre;
  output Option<DAE.ComponentRef> cref_1;
  Option<DAE.ComponentRef> cref_1;
algorithm 
  cref_1 := prefixToCrefOpt2(pre, NONE());
end prefixToCrefOpt;

public function prefixToCrefOpt2 "function: prefixToCrefOpt2
  Convert a prefix to a component reference. Converting NOPRE with no
  component reference gives a NONE"
  input Prefix inPrefix;
  input Option<DAE.ComponentRef> inExpComponentRefOption;
  output Option<DAE.ComponentRef> outComponentRefOpt;
algorithm 
  outComponentRefOpt := matchcontinue (inPrefix,inExpComponentRefOption)
    local
      Option<DAE.ComponentRef> cref_1;
      DAE.ComponentRef cref;
      list<DAE.Subscript> s_1;
      String i;
      list<Integer> s;
      ComponentPrefix xs;
      ClassPrefix cp;

    case (NOPRE(),NONE()) then NONE();
    case (NOPRE(),SOME(cref)) then SOME(cref); 
    case (PREFIX(NOCOMPPRE(),_),SOME(cref)) then SOME(cref);
    case (PREFIX(PRE(prefix = i,subscripts = s,next = xs),cp),NONE())
      equation 
        s_1 = Exp.intSubscripts(s);
        cref_1 = prefixToCrefOpt2(PREFIX(xs,cp), SOME(DAE.CREF_IDENT(i,DAE.ET_COMPLEX("",{},ClassInf.UNKNOWN("")),s_1)));
      then
        cref_1;
    case (PREFIX(PRE(prefix = i,subscripts = s,next = xs),cp),SOME(cref))
      equation 
        s_1 = Exp.intSubscripts(s);
        cref_1 = prefixToCrefOpt2(PREFIX(xs,cp), SOME(DAE.CREF_QUAL(i,DAE.ET_COMPLEX("",{},ClassInf.UNKNOWN("")),s_1,cref)));
      then
        cref_1;
  end matchcontinue;
end prefixToCrefOpt2;

public function prefixExp "function: prefixExp
  Add the supplied prefix to all component references in an expression."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
algorithm 
  (outCache,outExp) := matchcontinue (inCache,inEnv,inExp,inPrefix)
    local
      DAE.Exp e,e1_1,e2_1,e1,e2,e3_1,e3,cref_1,dim_1,cref,dim,start_1,stop_1,start,stop,step_1,step,e_1,exp_1,iterexp_1,exp,iterexp;
      DAE.ComponentRef p_1,p;
      list<Env.Frame> env;
      DAE.ExpType t;
      Prefix pre;
      DAE.Operator o;
      list<DAE.Exp> es_1,es,el,el_1;
      Absyn.Path f,fcn;
      Boolean b,bi,a;
      DAE.InlineType inl;
      list<Boolean> bl;
      list<tuple<DAE.Exp, Boolean>> x_1,x;
      list<list<tuple<DAE.Exp, Boolean>>> xs_1,xs;
      String id,s;
      Env.Cache cache;
    case (cache,_,e,NOPRE()) then (cache,e);       
    case (cache,_,(e as DAE.ICONST(integer = _)),_) then (cache,e); 
    case (cache,_,(e as DAE.RCONST(real = _)),_) then (cache,e); 
    case (cache,_,(e as DAE.SCONST(string = _)),_) then (cache,e); 
    case (cache,_,(e as DAE.BCONST(bool = _)),_) then (cache,e); 

    case (cache,env,(e as DAE.ASUB(exp = e1 as DAE.CREF(componentRef = p,ty = t), sub = expl)),pre) 
      local list<DAE.Exp> expl;
        equation
          (cache,_,_,_) = Lookup.lookupVarLocal(cache,env, p);
          (cache,es_1) = prefixExpList(cache,env, expl, pre);
           p_1 = prefixCref(pre, p);
          e2 = DAE.ASUB(DAE.CREF(p_1,t),es_1);
    then (cache,e2); 
      
    case (cache,env,(e as DAE.ASUB(exp = e1, sub = expl)),pre) 
      local list<DAE.Exp> expl;
      equation
        (cache,es_1) = prefixExpList(cache,env, expl, pre);
        (cache,e1) = prefixExp(cache,env,e1,pre);
        e2 = DAE.ASUB(e1,es_1);
      then (cache,e2); 
      
      
    case (cache,env,DAE.CREF(componentRef = p,ty = t),pre)
      equation 
        (cache,_,_,_) = Lookup.lookupVarLocal(cache,env, p);
        p_1 = prefixCref(pre, p);
      then
        (cache,DAE.CREF(p_1,t));
    case (cache,env,(e as DAE.CREF(componentRef = p)),pre)
      equation 
        failure((_,_,_,_) = Lookup.lookupVarLocal(cache,env, p));
      then
        (cache,e);
    case (cache,env,DAE.BINARY(exp1 = e1,operator = o,exp2 = e2),p)
      local Prefix p;
      equation 
        (cache,e1_1) = prefixExp(cache,env, e1, p);
        (cache,e2_1) = prefixExp(cache,env, e2, p);
      then
        (cache,DAE.BINARY(e1_1,o,e2_1));
    case (cache,env,DAE.UNARY(operator = o,exp = e1),p)
      local Prefix p;
      equation 
        (cache,e1_1) = prefixExp(cache,env, e1, p);
      then
        (cache,DAE.UNARY(o,e1_1));
    case (cache,env,DAE.LBINARY(exp1 = e1,operator = o,exp2 = e2),p)
      local Prefix p;
      equation 
        (cache,e1_1) = prefixExp(cache,env, e1, p);
        (cache,e2_1) = prefixExp(cache,env, e2, p);
      then
        (cache,DAE.LBINARY(e1_1,o,e2_1));
    case (cache,env,DAE.LUNARY(operator = o,exp = e1),p)
      local Prefix p;
      equation 
        (cache,e1_1) = prefixExp(cache,env, e1, p);
      then
        (cache,DAE.LUNARY(o,e1_1));
    case (cache,env,DAE.RELATION(exp1 = e1,operator = o,exp2 = e2),p)
      local Prefix p;
      equation 
        (cache,e1_1) = prefixExp(cache,env, e1, p);
        (cache,e2_1) = prefixExp(cache,env, e2, p);
      then
        (cache,DAE.RELATION(e1_1,o,e2_1));
    case (cache,env,DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),p)
      local Prefix p;
      equation 
        (cache,e1_1) = prefixExp(cache,env, e1, p);
        (cache,e2_1) = prefixExp(cache,env, e2, p);
        (cache,e3_1) = prefixExp(cache,env, e3, p);
      then
        (cache,DAE.IFEXP(e1_1,e2_1,e3_1));
    case (cache,env,DAE.SIZE(exp = cref,sz = SOME(dim)),p)
      local Prefix p;
      equation 
        (cache,cref_1) = prefixExp(cache,env, cref, p);
        (cache,dim_1) = prefixExp(cache,env, dim, p);
      then
        (cache,DAE.SIZE(cref_1,SOME(dim_1)));
    case (cache,env,DAE.SIZE(exp = cref,sz = NONE),p)
      local Prefix p;
      equation 
        (cache,cref_1) = prefixExp(cache,env, cref, p);
      then
        (cache,DAE.SIZE(cref_1,NONE));
    case (cache,env,DAE.CALL(path = f,expLst = es,tuple_ = b,builtin = bi,ty = tp,inlineType = inl),p)
      local Prefix p; DAE.ExpType tp;
      equation 
        (cache,es_1) = prefixExpList(cache,env, es, p);
      then
        (cache,DAE.CALL(f,es_1,b,bi,tp,inl)); 
    case (cache,env,DAE.ARRAY(ty = t,scalar = a,array = {}),p)
      local Prefix p;
      then
        (cache,DAE.ARRAY(t,a,{}));
    /*case (cache,env,Exp.ARRAY(ty = t,scalar = a,array = es),p as PREFIX(PRE(_,{i},_),_))
      local Prefix p; Integer i; DAE.Exp e;
      equation        
        e = listNth(es, i-1);
        Debug.fprint("prefix", "{v1,v2,v3}[" +& intString(i) +& "] => "  +& Exp.printExp2Str(e) +& "\n");
      then
        (cache,e);    */    
    case (cache,env,DAE.ARRAY(ty = t,scalar = a,array = es),p)
      local Prefix p;
      equation 
        (cache,es_1) = prefixExpList(cache,env, es, p);
      then
        (cache,DAE.ARRAY(t,a,es_1));
    case (cache,env,DAE.TUPLE(PR = es),p)
      local Prefix p;
      equation 
        (cache,es_1) = prefixExpList(cache,env, es, p);
      then
        (cache,DAE.TUPLE(es_1));
    case (cache,env,DAE.MATRIX(ty = t,integer = a,scalar = {}),p)
      local
        Integer a;
        Prefix p;
      then
        (cache,DAE.MATRIX(t,a,{}));
    case (cache,env,DAE.MATRIX(ty = t,integer = a,scalar = (x :: xs)),p)
      local
        Integer b,a;
        Prefix p;
      equation 
        el = Util.listMap(x, Util.tuple21);
        bl = Util.listMap(x, Util.tuple22);
        (cache,el_1) = prefixExpList(cache,env, el, p);
        x_1 = Util.listThreadTuple(el_1, bl);
        (cache,DAE.MATRIX(t,b,xs_1)) = prefixExp(cache,env, DAE.MATRIX(t,a,xs), p);
      then
        (cache,DAE.MATRIX(t,a,(x_1 :: xs_1)));
    case (cache,env,DAE.RANGE(ty = t,exp = start,expOption = NONE,range = stop),p)
      local Prefix p;
      equation 
        (cache,start_1) = prefixExp(cache,env, start, p);
        (cache,stop_1) = prefixExp(cache,env, stop, p);
      then
        (cache,DAE.RANGE(t,start_1,NONE,stop_1));
    case (cache,env,DAE.RANGE(ty = t,exp = start,expOption = SOME(step),range = stop),p)
      local Prefix p;
      equation 
        (cache,start_1) = prefixExp(cache,env, start, p);
        (cache,step_1) = prefixExp(cache,env, step, p);
        (cache,stop_1) = prefixExp(cache,env, stop, p);
      then
        (cache,DAE.RANGE(t,start_1,SOME(step_1),stop_1));
    case (cache,env,DAE.CAST(ty = tp,exp = e),p)
      local Prefix p; DAE.ExpType tp;
      equation 
        (cache,e_1) = prefixExp(cache,env, e, p);
      then
        (cache,DAE.CAST(tp,e_1));
    case (cache,env,DAE.REDUCTION(path = fcn,expr = exp,ident = id,range = iterexp),p)
      local Prefix p;
      equation 
        (cache,exp_1) = prefixExp(cache,env, exp, p);
        (cache,iterexp_1) = prefixExp(cache,env, iterexp, p);
      then
        (cache,DAE.REDUCTION(fcn,exp_1,id,iterexp_1));
        
    case (cache,env,DAE.VALUEBLOCK(t,localDecls = lDecls,body = b,result = exp),p)
      local
        list<DAE.Statement> b;
        list<DAE.Element> lDecls;
        Prefix p;
        DAE.ExpType t;
      equation
        (cache,lDecls) = prefixDecls(cache,env,lDecls,{},p);
        (cache,b) = prefixStatements(cache,env,b,{},p);
        (cache,exp) = prefixExp(cache,env,exp,p);
      then
        (cache,DAE.VALUEBLOCK(t,lDecls,b,exp));

        // MetaModelica extension. KS
    case (cache,env,DAE.LIST(t,es),p)
      local Prefix p;
        DAE.ExpType t;
      equation
        (cache,es_1) = prefixExpList(cache,env, es, p);
      then (cache,DAE.LIST(t,es_1));

    case (cache,env,DAE.CONS(t,e1,e2),p)
      local Prefix p;
        DAE.ExpType t;
      equation
        (cache,e1) = prefixExp(cache,env, e1, p);
        (cache,e2) = prefixExp(cache,env, e2, p);
      then (cache,DAE.CONS(t,e1,e2));

    case (cache,env,DAE.META_TUPLE(es),p)
      local Prefix p;
      equation
        (cache,es_1) = prefixExpList(cache,env, es, p);
      then (cache,DAE.META_TUPLE(es_1));

    case (cache,env,DAE.META_OPTION(SOME(e1)),p)
      local Prefix p;
      equation
        (cache,e1) = prefixExp(cache,env,e1, p);
      then (cache,DAE.META_OPTION(SOME(e1)));

    case (cache,env,DAE.META_OPTION(NONE()),p)
      local Prefix p;
      equation
      then (cache,DAE.META_OPTION(NONE()));
        // ------------------------

    case (_,_,e,_)
      equation 
				true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "-prefix_exp failed on exp:");
        s = Exp.printExpStr(e);
        Debug.fprint("failtrace", s);
        Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end prefixExp;

public function prefixExpList "function: prefixExpList
  
  This function prefixes a list of expressions using the
  `prefix_exp\' function.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output list<DAE.Exp> outExpExpLst;
algorithm 
  (outCache,outExpExpLst) :=
  matchcontinue (inCache,inEnv,inExpExpLst,inPrefix)
    local
      DAE.Exp e_1,e;
      list<DAE.Exp> es_1,es;
      list<Env.Frame> env;
      Prefix p;
      Env.Cache cache;
    case (cache,_,{},_) then (cache,{}); 
    case (cache,env,(e :: es),p)
      equation 
        (cache,e_1) = prefixExp(cache,env, e, p);
        (cache,es_1) = prefixExpList(cache,env, es, p);
      then
        (cache,e_1 :: es_1);
  end matchcontinue;
end prefixExpList;

public function prefixCrefList "function: prefixCrefList
  
  This function prefixes a list of component references using the
  `prefix_cref function.
"
  input Prefix inPrefix;
  input list<DAE.ComponentRef> inExpComponentRefLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inPrefix,inExpComponentRefLst)
    local
      DAE.ComponentRef cr_1,cr;
      list<DAE.ComponentRef> crlist_1,crlist;
      Prefix p;
    case (_,{}) then {}; 
    case (p,(cr :: crlist))
      equation 
        cr_1 = prefixCref(p, cr);
        crlist_1 = prefixCrefList(p, crlist);
      then
        (cr_1 :: crlist_1);
  end matchcontinue;
end prefixCrefList;

//--------------------------------------------
//   PART OF THE WORKAROUND FOR VALUEBLOCKS. KS
protected function prefixDecls "function: prefixDecls
  Add the supplied prefix to the DAE elements located in Exp.mo.
  PART OF THE WORKAROUND FOR VALUEBLOCKS"
  input Env.Cache cache;
  input Env.Env env;
	input list<DAE.Element> lDecls;
	input list<DAE.Element> accList;
  input Prefix p;
  output Env.Cache outCache;
	output list<DAE.Element> outDecls;
algorithm
  (outCache,outDecls) := matchcontinue (cache,env,lDecls,accList,p)
    local
      list<DAE.Element> localAccList;
      Prefix pre;  
      Env.Cache localCache;
      Env.Env localEnv;
      DAE.ElementSource source "the origin of the element";
      
    case (localCache,_,{},localAccList,_) then (localCache,localAccList);
    // variables
    case (localCache,localEnv,DAE.VAR(cRef,v1,v2,prot,ty,binding,dims,
      											flowPrefix,streamPrefix,source,vAttr,com,inOut)
       :: rest,localAccList,pre)
    local
      DAE.ComponentRef cRef;
    	DAE.VarKind v1 "varible kind variable, constant, parameter, etc." ;
    	DAE.VarDirection v2 "input, output or bidir" ;
    	DAE.VarProtection prot "if protected or public";
    	DAE.Type ty "the type" ;
    	Option<DAE.Exp> binding "binding" ;
    	DAE.InstDims dims "Binding expression e.g. for parameters" ;
    	DAE.Flow flowPrefix "Flow of connector variable. Needed for unconnected flow variables" ;
    	DAE.Stream streamPrefix "stream or no strem" ;
    	list<Absyn.Path> f "the list of classes";
    	Option<DAE.VariableAttributes> vAttr;
    	Option<SCode.Comment> com "comment";
    	Absyn.InnerOuter inOut "inner/outer required to 'change' outer references";
    	list<DAE.Element> rest,temp;
    	DAE.Element elem;
    equation
      cRef = prefixCref(pre,cRef);  
      elem = DAE.VAR(cRef,v1,v2,prot,ty,binding,dims,flowPrefix,streamPrefix,source,vAttr,com,inOut);  
      localAccList = listAppend(localAccList,Util.listCreate(elem));
      (localCache,temp) = prefixDecls(localCache,localEnv,rest,localAccList,pre);  
    then (localCache,temp);
    // equations
    case (localCache,localEnv,DAE.EQUATION(e1,e2,source) :: rest,localAccList,pre)
      local
        DAE.Exp e1,e2;
        list<DAE.Element> rest,temp;
        DAE.Element elem;
      equation
        (localCache,e1) = prefixExp(localCache,localEnv,e1,pre);
        (localCache,e2) = prefixExp(localCache,localEnv,e2,pre);
        elem = DAE.EQUATION(e1,e2,source); 
        localAccList = listAppend(localAccList,Util.listCreate(elem));
        (localCache,temp) = prefixDecls(localCache,localEnv,rest,localAccList,pre);	
      then (localCache,temp);
    // failure  
    case (_,_,_,_,_)
      equation
        print("Prefix.prefixDecls failed\n");
      then fail();
 end matchcontinue;
end prefixDecls;

protected function prefixStatements "function: prefixStatements
  
  Prefix statements.
  PART OF THE WORKAROUND FOR VALUEBLOCKS
"
	input Env.Cache cache;
	input Env.Env env;
	input list<DAE.Statement> stmts;
	input list<DAE.Statement> accList;
	input Prefix p;
	output Env.Cache outCache;
	output list<DAE.Statement> outStmts;
algorithm
  (outCache,outStmts) :=
  matchcontinue (cache,env,stmts,accList,p)
    local
      Env.Cache localCache;
      Env.Env localEnv;
      list<DAE.Statement> localAccList,rest;
      Prefix pre;
    case (localCache,_,{},localAccList,_) then (localCache,localAccList);
    case (localCache,localEnv,DAE.STMT_ASSIGN(t,e1,e) :: rest,localAccList,pre)  
      local
      	DAE.ExpType t;
    		DAE.Exp e,e1;
    		DAE.Statement elem;
    		list<DAE.Statement> elems;
    	equation
    	  (localCache,e1) = prefixExp(localCache,localEnv,e1,pre);
    	  (localCache,e) = prefixExp(localCache,localEnv,e,pre);  
    	  elem = DAE.STMT_ASSIGN(t,e1,e);
    	  localAccList = listAppend(localAccList,Util.listCreate(elem));
    	  (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
    	then (localCache,elems);  
  	case (localCache,localEnv,DAE.STMT_TUPLE_ASSIGN(t,eLst,e) :: rest,localAccList,pre) 
			local
      	DAE.ExpType t;
    		DAE.Exp e;
    		list<DAE.Exp> eLst;
    		DAE.Statement elem;
    		list<DAE.Statement> elems;
    	equation
    	  (localCache,e) = prefixExp(localCache,localEnv,e,pre);  
    	  (localCache,eLst) = prefixExpList(localCache,localEnv,eLst,pre);
    	  elem = DAE.STMT_TUPLE_ASSIGN(t,eLst,e);
    	  localAccList = listAppend(localAccList,Util.listCreate(elem));
    	  (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
    	then (localCache,elems);  
    
  	case (localCache,localEnv,DAE.STMT_ASSIGN_ARR(t,cRef,e) :: rest,localAccList,pre) 
      local
      	DAE.ExpType t;
    		DAE.ComponentRef cRef;
    		DAE.Exp e;
    		DAE.Statement elem;
    		list<DAE.Statement> elems;
    	equation
    	  cRef = prefixCref(pre,cRef);
    	  (localCache,e) = prefixExp(localCache,localEnv,e,pre);  
    	  elem = DAE.STMT_ASSIGN_ARR(t,cRef,e);
    	  localAccList = listAppend(localAccList,Util.listCreate(elem));
    	  (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
    	then (localCache,elems);  
   
    case (localCache,localEnv,DAE.STMT_FOR(t,bool,id,e,sList) :: rest,localAccList,pre) 
      local
      	DAE.ExpType t;
        Boolean bool;
        String id;
        DAE.Exp e;
    		DAE.Statement elem;
    		list<DAE.Statement> elems,sList;
    	equation
    	  (localCache,e) = prefixExp(localCache,localEnv,e,pre);  
    	  (localCache,sList) = prefixStatements(localCache,localEnv,sList,{},pre);    	  
    	  elem = DAE.STMT_FOR(t,bool,id,e,sList);  
    	  localAccList = listAppend(localAccList,Util.listCreate(elem));
    	  (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
    	  
    	then (localCache,elems); 	   
    	  
  case (localCache,localEnv,DAE.STMT_IF(e1,sList,elseBranch) :: rest,localAccList,pre)	  
      local
        DAE.Exp e1;
        list<DAE.Statement> sList,elems;
        DAE.Else elseBranch;
        DAE.Statement elem;
      equation
        (localCache,e1) = prefixExp(localCache,localEnv,e1,pre);
        (localCache,sList) = prefixStatements(localCache,localEnv,sList,{},pre);
        (localCache,elseBranch) = prefixElse(localCache,localEnv,elseBranch,pre);
        elem = DAE.STMT_IF(e1,sList,elseBranch);
        localAccList = listAppend(localAccList,Util.listCreate(elem));        
        (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
      then (localCache,elems); 	
    	   
    case (localCache,localEnv,DAE.STMT_WHILE(e1,sList) :: rest,localAccList,pre)	  
      local
        DAE.Exp e1;
        list<DAE.Statement> sList,elems;
        DAE.Statement elem;
      equation
        (localCache,e1) = prefixExp(localCache,localEnv,e1,pre);
        (localCache,sList) = prefixStatements(localCache,localEnv,sList,{},pre);
        elem = DAE.STMT_WHILE(e1,sList);
        localAccList = listAppend(localAccList,Util.listCreate(elem));        
        (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
      then (localCache,elems); 	
        
    case (localCache,localEnv,DAE.STMT_ASSERT(e1,e2) :: rest,localAccList,pre)	  
      local
        DAE.Exp e1,e2;
        list<DAE.Statement> elems;
        DAE.Statement elem;
      equation
        (localCache,e1) = prefixExp(localCache,localEnv,e1,pre);
        (localCache,e2) = prefixExp(localCache,localEnv,e2,pre);
        elem = DAE.STMT_ASSERT(e1,e2);
        localAccList = listAppend(localAccList,Util.listCreate(elem));        
        (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
      then (localCache,elems);  	   
  	case (localCache,localEnv,DAE.STMT_TRY(b) :: rest,localAccList,pre)
  	  local
  	    list<DAE.Statement> b;
  	    DAE.Statement elem;
    		list<DAE.Statement> elems;
  	  equation
  	    (localCache,b) = prefixStatements(localCache,localEnv,b,{},pre);
  	    elem = DAE.STMT_TRY(b);
    	  localAccList = listAppend(localAccList,Util.listCreate(elem));
    	  (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
    	then (localCache,elems);
  	case (localCache,localEnv,DAE.STMT_CATCH(b) :: rest,localAccList,pre)
			local
  	    list<DAE.Statement> b;
  	    DAE.Statement elem;
    		list<DAE.Statement> elems;
  	  equation
  	    (localCache,b) = prefixStatements(localCache,localEnv,b,{},pre);
  	    elem = DAE.STMT_CATCH(b);
    	  localAccList = listAppend(localAccList,Util.listCreate(elem));
    	  (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
    	then (localCache,elems);
  	case (localCache,localEnv,DAE.STMT_THROW() :: rest,localAccList,pre)
  	    local
  	    	DAE.Statement elem;
    			list<DAE.Statement> elems;
    		equation
    			elem = DAE.STMT_THROW();
    	  	localAccList = listAppend(localAccList,Util.listCreate(elem));
    	  	(localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
    		then (localCache,elems);
  	case (localCache,localEnv,DAE.STMT_RETURN() :: rest,localAccList,pre)
  	    local
  	    	DAE.Statement elem;
    			list<DAE.Statement> elems;
    		equation
    			elem = DAE.STMT_RETURN();
    	  	localAccList = listAppend(localAccList,Util.listCreate(elem));
    	  	(localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
    		then (localCache,elems);
  	case (localCache,localEnv,DAE.STMT_BREAK() :: rest,localAccList,pre)
  	    local
  	    	DAE.Statement elem;
    			list<DAE.Statement> elems;
    		equation
    			elem = DAE.STMT_BREAK();
    	  	localAccList = listAppend(localAccList,Util.listCreate(elem));
    	  	(localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
    		then (localCache,elems);
  	case (localCache,localEnv,DAE.STMT_GOTO(s) :: rest,localAccList,pre)
  	  local
  	    DAE.Statement elem;
  	    list<DAE.Statement> elems;
  	    String s;
  	  equation
  	    elem = DAE.STMT_GOTO(s);
  	    localAccList = listAppend(localAccList,Util.listCreate(elem));
  	    (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
  	  then (localCache,elems);
  	case (localCache,localEnv,DAE.STMT_LABEL(s) :: rest,localAccList,pre)
  	  local
  	    DAE.Statement elem;
  	    list<DAE.Statement> elems;
  	    String s;
  	  equation
  	    elem = DAE.STMT_LABEL(s);
  	    localAccList = listAppend(localAccList,Util.listCreate(elem));
  	    (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
  	  then (localCache,elems);
  end matchcontinue;
end prefixStatements;

protected function prefixElse "function: prefixElse

  Prefix else statements.
  PART OF THE WORKAROUND FOR VALUEBLOCKS
"
  input Env.Cache cache;
  input Env.Env env;
  input DAE.Else elseBranch;
  input Prefix p;
  output Env.Cache outCache;
  output DAE.Else outElse;
algorithm
  (outCache,outElse) :=
  matchcontinue (cache,env,elseBranch,p)
    local
      Env.Cache localCache;
      Env.Env localEnv;
      Prefix pre;
    case (localCache,localEnv,DAE.NOELSE(),pre)
      then (localCache,DAE.NOELSE());
    case (localCache,localEnv,DAE.ELSEIF(e,lStmt,el),pre)
      local
        DAE.Exp e;
        list<DAE.Statement> lStmt;
        DAE.Else el;
        DAE.Else stmt;
      equation
        (localCache,e) = prefixExp(localCache,localEnv,e,pre);
        (localCache,el) = prefixElse(localCache,localEnv,el,pre);       
        (localCache,lStmt) = prefixStatements(localCache,localEnv,lStmt,{},pre);
        stmt = DAE.ELSEIF(e,lStmt,el);  
      then (localCache,stmt);  
    case (localCache,localEnv,DAE.ELSE(lStmt),pre)
      local
        list<DAE.Statement> lStmt;
        DAE.Else stmt;
      equation
       (localCache,lStmt) = prefixStatements(localCache,localEnv,lStmt,{},pre);
        stmt = DAE.ELSE(lStmt);
      then (localCache,stmt); 
  end matchcontinue; 
end prefixElse;  

end Prefix;
