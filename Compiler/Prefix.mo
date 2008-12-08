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
public import Exp;
public import Env;
public import Lookup;

public
uniontype Prefix 
  "A Prefix has a name an a list of constant valued subscripts."
  record NOPRE end NOPRE;

  record PRE
    String prefix "prefix name" ;
    list<Integer> subscripts "subscripts" ;
    Prefix next "next prefix" ;
  end PRE;

end Prefix;

protected import Util;
protected import Print;
protected import Debug;

public function printPrefixStr 
"function: printPrefixStr
  Prints a Prefix to a string."
  input Prefix inPrefix;
  output String outString;
algorithm
  outString := matchcontinue (inPrefix)
    local
      String str,s,rest_1,s_1,s_2;
      Prefix rest;
    case NOPRE() then "<NOPRE>";
    case PRE(prefix = str,subscripts = {},next = NOPRE()) then str;
    case PRE(prefix = str,next = NOPRE())
      equation
        s = stringAppend(str, "[]");
      then
        s;
    case PRE(prefix = str,subscripts = {},next = rest)
      equation
        rest_1 = printPrefixStr(rest);
        s = stringAppend(rest_1, ".");
        s_1 = stringAppend(s, str);
      then
        s_1;
    case PRE(prefix = str,next = rest)
      equation
        rest_1 = printPrefixStr(rest);
        s = stringAppend(rest_1, ".");
        s_1 = stringAppend(s, str);
        s_2 = stringAppend(s_1, "[]");
      then
        s_2;
  end matchcontinue;
end printPrefixStr;

public function printPrefix 
"function: printPrefix
  Prints a prefix to the Print buffer."
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
  input Exp.Ident inIdent;
  input list<Integer> inIntegerLst;
  input Prefix inPrefix;
  output Prefix outPrefix;
algorithm
  outPrefix:=
  matchcontinue (inIdent,inIntegerLst,inPrefix)
    local
      String i;
      list<Integer> s;
      Prefix p;
    case (i,s,p) then PRE(i,s,p);
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
      Prefix c;
    case (PRE(prefix = a,subscripts = b,next = c)) then PRE(a,b,NOPRE());
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
    local Prefix p,res;
    case ((p as PRE(next = NOPRE()))) then p;
    case (PRE(next = p))
      equation
        res = prefixLast(p);
      then
        res;
  end matchcontinue;
end prefixLast;

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
      Prefix ss;
    case (p,NOPRE()) then p;
    case (p,PRE(prefix = s,next = ss))
      equation
        p_1 = prefixPath(Absyn.QUALIFIED(s,p), ss);
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
      Prefix ss;
    case NOPRE()
      equation
        Print.printBuf("#-- Error: Cannot convert empty prefix to a path\n");
      then
        fail();
    case PRE(prefix = s,next = NOPRE()) then Absyn.IDENT(s);
    case PRE(prefix = s,next = ss)
      equation
        p = prefixToPath(ss);
      then
        Absyn.QUALIFIED(s,p);
  end matchcontinue;
end prefixToPath;

public function prefixCref "function: prefixCref

  Prefix a `ComponentRef\' variable by adding the supplied prefix to
  it and returning a new `ComponentRef\'.

  LS: Changed to call prefix_to_cref which is more general now
"
  input Prefix pre;
  input Exp.ComponentRef cref;
  output Exp.ComponentRef cref_1;
  Exp.ComponentRef cref_1;
algorithm
  cref_1 := prefixToCref2(pre, SOME(cref));
end prefixCref;

public function prefixToCref 
"function: prefixToCref
  Convert a prefix to a component reference."
  input Prefix pre;
  output Exp.ComponentRef cref_1;
  Exp.ComponentRef cref_1;
algorithm
  cref_1 := prefixToCref2(pre, NONE);
end prefixToCref;

protected function prefixToCref2 
"function: prefixToCref2
  Convert a prefix to a component reference. Converting NOPRE with no
  component reference is an error because a component reference cannot 
  be empty"
  input Prefix inPrefix;
  input Option<Exp.ComponentRef> inExpComponentRefOption;
  output Exp.ComponentRef outComponentRef;
algorithm
  outComponentRef := matchcontinue (inPrefix,inExpComponentRefOption)
    local
      Exp.ComponentRef cref,cref_1;
      list<Exp.Subscript> s_1;
      String i;
      list<Integer> s;
      Prefix xs;
    case (NOPRE(),NONE)
      equation
        Print.printBuf("#-- Cannot convert empty prefix to component reference\n");
      then
        fail();
    case (NOPRE(),SOME(cref)) then cref;
    case (PRE(prefix = i,subscripts = s,next = xs),NONE)
      equation
        s_1 = Exp.intSubscripts(s);
        cref_1 = prefixToCref2(xs, SOME(Exp.CREF_IDENT(i,s_1)));
      then
        cref_1;
    case (PRE(prefix = i,subscripts = s,next = xs),SOME(cref))
      equation
        s_1 = Exp.intSubscripts(s);
        cref_1 = prefixToCref2(xs, SOME(Exp.CREF_QUAL(i,s_1,cref)));
      then
        cref_1;
  end matchcontinue;
end prefixToCref2;

public function prefixExp 
"function: prefixExp
  Add the supplied prefix to all component references in an expression."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.Exp inExp;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output Exp.Exp outExp;
algorithm
  (outCache,outExp) := matchcontinue (inCache,inEnv,inExp,inPrefix)
    local
      Exp.Exp e,e1_1,e2_1,e1,e2,e3_1,e3,cref_1,dim_1,cref,dim,start_1,stop_1,start,stop,step_1,step,e_1,exp_1,iterexp_1,exp,iterexp;
      Exp.ComponentRef p_1,p;
      list<Env.Frame> env;
      Exp.Type t;
      Prefix pre;
      Exp.Operator o;
      list<Exp.Exp> es_1,es,el,el_1;
      Absyn.Path f,fcn;
      Boolean b,bi,a;
      list<Boolean> bl;
      list<tuple<Exp.Exp, Boolean>> x_1,x;
      list<list<tuple<Exp.Exp, Boolean>>> xs_1,xs;
      String id,s;
      Env.Cache cache;
    case (cache,_,(e as Exp.ICONST(integer = _)),_) then (cache,e);
    case (cache,_,(e as Exp.RCONST(real = _)),_) then (cache,e);
    case (cache,_,(e as Exp.SCONST(string = _)),_) then (cache,e);
    case (cache,_,(e as Exp.BCONST(bool = _)),_) then (cache,e);
    case (cache,env,Exp.CREF(componentRef = p,ty = t),pre)
      equation
        (cache,_,_,_) = Lookup.lookupVarLocal(cache,env, p);
        p_1 = prefixCref(pre, p);
      then
        (cache,Exp.CREF(p_1,t));
    case (cache,env,(e as Exp.CREF(componentRef = p)),pre)
      equation
        failure((_,_,_,_) = Lookup.lookupVarLocal(cache,env, p));
      then
        (cache,e);
    case (cache,env,Exp.BINARY(exp1 = e1,operator = o,exp2 = e2),p)
      local Prefix p;
      equation
        (cache,e1_1) = prefixExp(cache,env, e1, p);
        (cache,e2_1) = prefixExp(cache,env, e2, p);
      then
        (cache,Exp.BINARY(e1_1,o,e2_1));
    case (cache,env,Exp.UNARY(operator = o,exp = e1),p)
      local Prefix p;
      equation
        (cache,e1_1) = prefixExp(cache,env, e1, p);
      then
        (cache,Exp.UNARY(o,e1_1));
    case (cache,env,Exp.LBINARY(exp1 = e1,operator = o,exp2 = e2),p)
      local Prefix p;
      equation
        (cache,e1_1) = prefixExp(cache,env, e1, p);
        (cache,e2_1) = prefixExp(cache,env, e2, p);
      then
        (cache,Exp.LBINARY(e1_1,o,e2_1));
    case (cache,env,Exp.LUNARY(operator = o,exp = e1),p)
      local Prefix p;
      equation
        (cache,e1_1) = prefixExp(cache,env, e1, p);
      then
        (cache,Exp.LUNARY(o,e1_1));
    case (cache,env,Exp.RELATION(exp1 = e1,operator = o,exp2 = e2),p)
      local Prefix p;
      equation
        (cache,e1_1) = prefixExp(cache,env, e1, p);
        (cache,e2_1) = prefixExp(cache,env, e2, p);
      then
        (cache,Exp.RELATION(e1_1,o,e2_1));
    case (cache,env,Exp.IFEXP(expCond = e1,expThen = e2,expElse = e3),p)
      local Prefix p;
      equation
        (cache,e1_1) = prefixExp(cache,env, e1, p);
        (cache,e2_1) = prefixExp(cache,env, e2, p);
        (cache,e3_1) = prefixExp(cache,env, e3, p);
      then
        (cache,Exp.IFEXP(e1_1,e2_1,e3_1));
    case (cache,env,Exp.SIZE(exp = cref,sz = SOME(dim)),p)
      local Prefix p;
      equation
        (cache,cref_1) = prefixExp(cache,env, cref, p);
        (cache,dim_1) = prefixExp(cache,env, dim, p);
      then
        (cache,Exp.SIZE(cref_1,SOME(dim_1)));
    case (cache,env,Exp.SIZE(exp = cref,sz = NONE),p)
      local Prefix p;
      equation
        (cache,cref_1) = prefixExp(cache,env, cref, p);
      then
        (cache,Exp.SIZE(cref_1,NONE));
    case (cache,env,Exp.CALL(path = f,expLst = es,tuple_ = b,builtin = bi,ty = tp),p)
      local Prefix p; Exp.Type tp;
      equation
        (cache,es_1) = prefixExpList(cache,env, es, p);
      then
        (cache,Exp.CALL(f,es_1,b,bi,tp));
    case (cache,env,Exp.ARRAY(ty = t,scalar = a,array = {}),p)
      local Prefix p;
      then
        (cache,Exp.ARRAY(t,a,{}));
    case (cache,env,Exp.ARRAY(ty = t,scalar = a,array = es),p)
      local Prefix p;
      equation
        (cache,es_1) = prefixExpList(cache,env, es, p);
      then
        (cache,Exp.ARRAY(t,a,es_1));
    case (cache,env,Exp.TUPLE(PR = es),p)
      local Prefix p;
      equation
        (cache,es_1) = prefixExpList(cache,env, es, p);
      then
        (cache,Exp.TUPLE(es_1));
    case (cache,env,Exp.MATRIX(ty = t,integer = a,scalar = {}),p)
      local
        Integer a;
        Prefix p;
      then
        (cache,Exp.MATRIX(t,a,{}));
    case (cache,env,Exp.MATRIX(ty = t,integer = a,scalar = (x :: xs)),p)
      local
        Integer b,a;
        Prefix p;
      equation
        el = Util.listMap(x, Util.tuple21);
        bl = Util.listMap(x, Util.tuple22);
        (cache,el_1) = prefixExpList(cache,env, el, p);
        x_1 = Util.listThreadTuple(el_1, bl);
        (cache,Exp.MATRIX(t,b,xs_1)) = prefixExp(cache,env, Exp.MATRIX(t,a,xs), p);
      then
        (cache,Exp.MATRIX(t,a,(x_1 :: xs_1)));
    case (cache,env,Exp.RANGE(ty = t,exp = start,expOption = NONE,range = stop),p)
      local Prefix p;
      equation
        (cache,start_1) = prefixExp(cache,env, start, p);
        (cache,stop_1) = prefixExp(cache,env, stop, p);
      then
        (cache,Exp.RANGE(t,start_1,NONE,stop_1));
    case (cache,env,Exp.RANGE(ty = t,exp = start,expOption = SOME(step),range = stop),p)
      local Prefix p;
      equation
        (cache,start_1) = prefixExp(cache,env, start, p);
        (cache,step_1) = prefixExp(cache,env, step, p);
        (cache,stop_1) = prefixExp(cache,env, stop, p);
      then
        (cache,Exp.RANGE(t,start_1,SOME(step_1),stop_1));
    case (cache,env,Exp.CAST(ty = tp,exp = e),p)
      local Prefix p; Exp.Type tp;
      equation
        (cache,e_1) = prefixExp(cache,env, e, p);
      then
        (cache,Exp.CAST(tp,e_1));
    case (cache,env,Exp.REDUCTION(path = fcn,expr = exp,ident = id,range = iterexp),p)
      local Prefix p;
      equation
        (cache,exp_1) = prefixExp(cache,env, exp, p);
        (cache,iterexp_1) = prefixExp(cache,env, iterexp, p);
      then
        (cache,Exp.REDUCTION(fcn,exp_1,id,iterexp_1));
    case (cache,env,Exp.VALUEBLOCK(t,localDecls = lDecls,body = b,result = res),p)
      local
        Prefix p;
    		list<Exp.DAEElement> lDecls,lDecls2;
        Exp.DAEElement b,b2;
        Exp.Exp res,res2;
        Exp.Type t;
      equation
        (cache,lDecls2) = prefixDecls(cache,env,lDecls,{},p);
        (cache,b2) = prefixAlgorithm(cache,env,b,p);
        (cache,res2) = prefixExp(cache,env,res,p);
      then
        (cache,Exp.VALUEBLOCK(t,lDecls2,b2,res2));

    // MetaModelica extension. KS
    case (cache,env,Exp.LIST(t,es),p)
      local Prefix p;
        Exp.Type t;
      equation
        (cache,es_1) = prefixExpList(cache,env, es, p);
      then (cache,Exp.LIST(t,es_1));

    case (cache,env,Exp.CONS(t,e1,e2),p)
      local Prefix p;
        Exp.Type t;
      equation
        (cache,e1) = prefixExp(cache,env, e1, p);
        (cache,e2) = prefixExp(cache,env, e2, p);
      then (cache,Exp.CONS(t,e1,e2));

    case (cache,env,Exp.META_TUPLE(es),p)
      local Prefix p;
      equation
        (cache,es_1) = prefixExpList(cache,env, es, p);
      then (cache,Exp.META_TUPLE(es_1));

    case (cache,env,Exp.META_OPTION(SOME(e1)),p)
      local Prefix p;
      equation
        (cache,e1) = prefixExp(cache,env,e1, p);
      then (cache,Exp.META_OPTION(SOME(e1)));

    case (cache,env,Exp.META_OPTION(NONE()),p)
      local Prefix p;
      equation
      then (cache,Exp.META_OPTION(NONE()));
        // ------------------------

    case (_,_,e,_)
      equation
        Debug.fprint("failtrace", "-prefix_exp failed on exp:");
        s = Exp.printExpStr(e);
        Debug.fprint("failtrace", s);
        Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end prefixExp;


//--------------------------------------------
//   PART OF THE WORKAROUND FOR VALUEBLOCKS. KS
public function prefixDecls 
"function: prefixDecls
  Add the supplied prefix to the DAE elements located in Exp.mo.
  PART OF THE WORKAROUND FOR VALUEBLOCKS"
  input Env.Cache cache;
  input Env.Env env;
	input list<Exp.DAEElement> lDecls;
	input list<Exp.DAEElement> accList;
  input Prefix p;
  output Env.Cache outCache;
	output list<Exp.DAEElement> outDecls;
algorithm
  (outCache,outDecls) := matchcontinue (cache,env,lDecls,accList,p)
    local
      list<Exp.DAEElement> localAccList;
      Prefix pre;
      Env.Cache localCache;
      Env.Env localEnv;
    case (localCache,_,{},localAccList,_) then (localCache,localAccList);
    case (localCache,localEnv,Exp.VAR(cRef,kind,direction,prot,ty,binding,dims,flow_,stream_,pathLst,vAttr,com,inOut,fType):: rest,localAccList,pre)
      local
        Exp.ComponentRef cRef;
        Exp.VarKind kind "varible kind: variable, constant, parameter, etc." ;
        Exp.VarDirection direction "input, output or bidir" ;
        Exp.VarProtection prot "if protected or public";
        Exp.TypeExp ty "one of the builtin types" ;
        Option<Exp.Exp> binding "Binding expression e.g. for parameters, value of start attribute" ;
        Exp.InstDims dims "dimension of original component" ;
        Exp.Flow flow_ "Flow of connector variable. Needed for unconnected flow variables" ;
        Exp.Stream stream_ "Stream connector variables. " ;
        list<Absyn.Path> pathLst "class name" ;
        Option<Exp.VariableAttributes> vAttr;
        Option<Absyn.Comment> com;
        Absyn.InnerOuter inOut "inner/outer required to 'change' outer references";
        Exp.TypeTypes fType "Full type information required to analyze inner/outer elements";
        list<Exp.DAEElement> rest,temp;
        Exp.DAEElement elem;
      equation
        cRef = prefixCref(pre,cRef);
        elem = Exp.VAR(cRef,kind,direction,prot,ty,binding,dims,flow_,stream_,pathLst,vAttr,com,inOut,fType);
        localAccList = listAppend(localAccList,Util.listCreate(elem));
        (localCache,temp) = prefixDecls(localCache,localEnv,rest,localAccList,pre);
      then (localCache,temp);
    case (localCache,localEnv,Exp.EQUATION(e1,e2) :: rest,localAccList,pre)
      local
        Exp.Exp e1,e2;
        list<Exp.DAEElement> rest,temp;
        Exp.DAEElement elem;
      equation
        (localCache,e1) = prefixExp(localCache,localEnv,e1,pre);
        (localCache,e2) = prefixExp(localCache,localEnv,e2,pre);
        elem = Exp.EQUATION(e1,e2);
        localAccList = listAppend(localAccList,Util.listCreate(elem));
        (localCache,temp) = prefixDecls(localCache,localEnv,rest,localAccList,pre);
      then (localCache,temp);
  end matchcontinue;
end prefixDecls;

public function prefixAlgorithm 
"function: prefixAlgorithm
  Prefix algorithm.
  PART OF THE WORKAROUND FOR VALUEBLOCKS"
	input Env.Cache cache;
	input Env.Env env;
	input Exp.DAEElement b;
	input Prefix p;
	output Env.Cache outCache;
	output Exp.DAEElement outBody;
algorithm
	(outCache,outBody) := matchcontinue (cache,env,b,p)
	  case (localCache,localEnv,Exp.ALGORITHM(Exp.ALGORITHM2(stmts)),localPrefix)
	  local
	  	Env.Cache localCache;
	  	Env.Env localEnv;
	  	Prefix localPrefix;
	  	list<Exp.Statement> stmts;
	  	Exp.DAEElement elem;
	  equation
	  	(localCache,stmts) = prefixStatements(localCache,localEnv,stmts,{},localPrefix);
	    elem = Exp.ALGORITHM(Exp.ALGORITHM2(stmts));
	  then (localCache,elem);
	end matchcontinue;
end prefixAlgorithm;


public function prefixStatements 
"function: prefixStatements
  Prefix statements.
  PART OF THE WORKAROUND FOR VALUEBLOCKS"
	input Env.Cache cache;
	input Env.Env env;
	input list<Exp.Statement> stmts;
	input list<Exp.Statement> accList;
	input Prefix p;
	output Env.Cache outCache;
	output list<Exp.Statement> outStmts;
algorithm
  (outCache,outStmts) := matchcontinue (cache,env,stmts,accList,p)
    local
      Env.Cache localCache;
      Env.Env localEnv;
      list<Exp.Statement> localAccList,rest;
      Prefix pre;
    case (localCache,_,{},localAccList,_) then (localCache,localAccList);
    case (localCache,localEnv,Exp.ASSIGN(t,cRef,e) :: rest,localAccList,pre)
      local
        Exp.Type t;
        Exp.ComponentRef cRef;
        Exp.Exp e;
        Exp.Statement elem;
        list<Exp.Statement> elems;
      equation
        cRef = prefixCref(pre,cRef);
        (localCache,e) = prefixExp(localCache,localEnv,e,pre);
        elem = Exp.ASSIGN(t,cRef,e);
        localAccList = listAppend(localAccList,Util.listCreate(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
      then (localCache,elems);
    case (localCache,localEnv,Exp.TUPLE_ASSIGN(t,eLst,e) :: rest,localAccList,pre)
      local
        Exp.Type t;
        Exp.Exp e;
        list<Exp.Exp> eLst;
        Exp.Statement elem;
        list<Exp.Statement> elems;
      equation
        (localCache,e) = prefixExp(localCache,localEnv,e,pre);
        (localCache,eLst) = prefixExpList(localCache,localEnv,eLst,pre);
        elem = Exp.TUPLE_ASSIGN(t,eLst,e);
        localAccList = listAppend(localAccList,Util.listCreate(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
      then (localCache,elems);
        
    case (localCache,localEnv,Exp.ASSIGN_ARR(t,cRef,e) :: rest,localAccList,pre)
      local
        Exp.Type t;
        Exp.ComponentRef cRef;
        Exp.Exp e;
        Exp.Statement elem;
        list<Exp.Statement> elems;
      equation
        cRef = prefixCref(pre,cRef);
        (localCache,e) = prefixExp(localCache,localEnv,e,pre);
        elem = Exp.ASSIGN_ARR(t,cRef,e);
        localAccList = listAppend(localAccList,Util.listCreate(elem));
    	  (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
      then (localCache,elems);
        
    case (localCache,localEnv,Exp.FOR(t,bool,id,e,sList) :: rest,localAccList,pre)
      local
        Exp.Type t;
        Boolean bool;
        Exp.Ident id;
        Exp.Exp e;
        Exp.Statement elem;
        list<Exp.Statement> elems,sList;
      equation
        (localCache,e) = prefixExp(localCache,localEnv,e,pre);
        (localCache,sList) = prefixStatements(localCache,localEnv,sList,{},pre);
        elem = Exp.FOR(t,bool,id,e,sList);
        localAccList = listAppend(localAccList,Util.listCreate(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);        
      then (localCache,elems);

    case (localCache,localEnv,Exp.IF(e1,sList,elseBranch) :: rest,localAccList,pre)
      local
        Exp.Exp e1;
        list<Exp.Statement> sList,elems;
        Exp.Else elseBranch;
        Exp.Statement elem;
      equation
        (localCache,e1) = prefixExp(localCache,localEnv,e1,pre);
        (localCache,sList) = prefixStatements(localCache,localEnv,sList,{},pre);
        (localCache,elseBranch) = prefixElse(localCache,localEnv,elseBranch,pre);
        elem = Exp.IF(e1,sList,elseBranch);
        localAccList = listAppend(localAccList,Util.listCreate(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
      then (localCache,elems);

    case (localCache,localEnv,Exp.WHILE(e1,sList) :: rest,localAccList,pre)
      local
        Exp.Exp e1;
        list<Exp.Statement> sList,elems;
        Exp.Statement elem;
      equation
        (localCache,e1) = prefixExp(localCache,localEnv,e1,pre);
        (localCache,sList) = prefixStatements(localCache,localEnv,sList,{},pre);
        elem = Exp.WHILE(e1,sList);
        localAccList = listAppend(localAccList,Util.listCreate(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
      then (localCache,elems);
        
    case (localCache,localEnv,Exp.ASSERTSTMT(e1,e2) :: rest,localAccList,pre)
      local
        Exp.Exp e1,e2;
        list<Exp.Statement> elems;
        Exp.Statement elem;
      equation
        (localCache,e1) = prefixExp(localCache,localEnv,e1,pre);
        (localCache,e2) = prefixExp(localCache,localEnv,e2,pre);
        elem = Exp.ASSERTSTMT(e1,e2);
        localAccList = listAppend(localAccList,Util.listCreate(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
      then (localCache,elems);
    case (localCache,localEnv,Exp.TRY(b) :: rest,localAccList,pre)
      local
        list<Exp.Statement> b;
        Exp.Statement elem;
        list<Exp.Statement> elems;
      equation
        (localCache,b) = prefixStatements(localCache,localEnv,b,{},pre);
        elem = Exp.TRY(b);
        localAccList = listAppend(localAccList,Util.listCreate(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
      then (localCache,elems);
    case (localCache,localEnv,Exp.CATCH(b) :: rest,localAccList,pre)
      local
  	    list<Exp.Statement> b;
        Exp.Statement elem;
        list<Exp.Statement> elems;
      equation
        (localCache,b) = prefixStatements(localCache,localEnv,b,{},pre);
        elem = Exp.CATCH(b);
        localAccList = listAppend(localAccList,Util.listCreate(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
      then (localCache,elems);
    case (localCache,localEnv,Exp.THROW() :: rest,localAccList,pre)
      local
        Exp.Statement elem;
    			list<Exp.Statement> elems;
      equation
        elem = Exp.THROW();
        localAccList = listAppend(localAccList,Util.listCreate(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
      then (localCache,elems);
    case (localCache,localEnv,Exp.RETURN() :: rest,localAccList,pre)
      local
        Exp.Statement elem;
        list<Exp.Statement> elems;
      equation
        elem = Exp.RETURN();
        localAccList = listAppend(localAccList,Util.listCreate(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
      then (localCache,elems);
    case (localCache,localEnv,Exp.BREAK() :: rest,localAccList,pre)
      local
        Exp.Statement elem;
        list<Exp.Statement> elems;
      equation
        elem = Exp.BREAK();
        localAccList = listAppend(localAccList,Util.listCreate(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
      then (localCache,elems);
    case (localCache,localEnv,Exp.GOTO(s) :: rest,localAccList,pre)
      local
        Exp.Statement elem;
        list<Exp.Statement> elems;
        String s;
      equation
        elem = Exp.GOTO(s);
        localAccList = listAppend(localAccList,Util.listCreate(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
      then (localCache,elems);
    case (localCache,localEnv,Exp.LABEL(s) :: rest,localAccList,pre)
      local
        Exp.Statement elem;
        list<Exp.Statement> elems;
        String s;
      equation
        elem = Exp.LABEL(s);
        localAccList = listAppend(localAccList,Util.listCreate(elem));
        (localCache,elems) = prefixStatements(localCache,localEnv,rest,localAccList,pre);
      then (localCache,elems);
  end matchcontinue;
end prefixStatements;

public function prefixElse 
"function: prefixElse
  Prefix else statements.
  PART OF THE WORKAROUND FOR VALUEBLOCKS"
  input Env.Cache cache;
  input Env.Env env;
  input Exp.Else elseBranch;
  input Prefix p;
  output Env.Cache outCache;
  output Exp.Else outElse;
algorithm
  (outCache,outElse) := matchcontinue (cache,env,elseBranch,p)
    local
      Env.Cache localCache;
      Env.Env localEnv;
      Prefix pre;
    case (localCache,localEnv,Exp.NOELSE(),pre) then (localCache,Exp.NOELSE());
    case (localCache,localEnv,Exp.ELSEIF(e,lStmt,el),pre)
      local
        Exp.Exp e;
        list<Exp.Statement> lStmt;
        Exp.Else el;
        Exp.Else stmt;
      equation
        (localCache,e) = prefixExp(localCache,localEnv,e,pre);
        (localCache,el) = prefixElse(localCache,localEnv,el,pre);
        (localCache,lStmt) = prefixStatements(localCache,localEnv,lStmt,{},pre);
        stmt = Exp.ELSEIF(e,lStmt,el);
      then (localCache,stmt);
    case (localCache,localEnv,Exp.ELSE(lStmt),pre)
      local
        list<Exp.Statement> lStmt;
        Exp.Else stmt;
      equation
        (localCache,lStmt) = prefixStatements(localCache,localEnv,lStmt,{},pre);
        stmt = Exp.ELSE(lStmt);
      then (localCache,stmt);
  end matchcontinue;
end prefixElse;
//------------------------------------------------------

public function prefixExpList 
"function: prefixExpList
  This function prefixes a list of expressions using the prefixExp function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output list<Exp.Exp> outExpExpLst;
algorithm
  (outCache,outExpExpLst) := matchcontinue (inCache,inEnv,inExpExpLst,inPrefix)
    local
      Exp.Exp e_1,e;
      list<Exp.Exp> es_1,es;
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

public function prefixCrefList 
"function: prefixCrefList
  This function prefixes a list of component references using the prefixCref function."
  input Prefix inPrefix;
  input list<Exp.ComponentRef> inExpComponentRefLst;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst := matchcontinue (inPrefix,inExpComponentRefLst)
    local
      Exp.ComponentRef cr_1,cr;
      list<Exp.ComponentRef> crlist_1,crlist;
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

end Prefix;

