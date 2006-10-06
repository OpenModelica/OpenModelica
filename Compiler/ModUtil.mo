package ModUtil "
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linköpings universitet, Department of
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

 Neither the name of Linköpings universitet nor the names of its
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

  
  file:	 ModUtil.rml
  module:      ModUtil
  description: Miscellanous modelica related utilities (The horror, THE HORROR)
 
  RCS: $Id$
  
  This module contains various utilities. For example
  converting a path to a string and comparing two paths.
  It is used pretty much everywhere. The difference between this 
  module and the Util module is that ModUtil contains modelica 
  related utilities. The Util module only contains \"low-level\" 
  rml utilities, for example finding elements in lists.
  
"

public import OpenModelica.Compiler.Absyn;

public import OpenModelica.Compiler.DAE;

public import OpenModelica.Compiler.Exp;

protected import OpenModelica.Compiler.RTOpts;

protected import OpenModelica.Compiler.Util;

protected import OpenModelica.Compiler.Algorithm;

protected import OpenModelica.Compiler.Types;

protected function stringPrefixComponentRefs "adrpo -- not used
with \"Print.rml\"
"
  input String inString;
  input FuncTypeExp_ComponentRefType_bTo inFuncTypeExpComponentRefTypeBTo;
  input Type_b inTypeB;
  input list<Exp.Exp> inExpExpLst;
  output list<Exp.Exp> outExpExpLst;
  partial function FuncTypeExp_ComponentRefType_bTo
    input Exp.ComponentRef inComponentRef;
    input Type_b inTypeB;
    replaceable type Type_b;
  end FuncTypeExp_ComponentRefType_bTo;
  replaceable type Type_b;
algorithm 
  outExpExpLst:=
  matchcontinue (inString,inFuncTypeExpComponentRefTypeBTo,inTypeB,inExpExpLst)
    local
      list<Exp.Exp> res,rest;
      Exp.Exp e_1,e;
      String str;
      FuncTypeExp_ComponentRefType_bTo r;
      Type_b rarg;
    case (_,_,_,{}) then {}; 
    case (str,r,rarg,(e :: rest))
      equation 
        res = stringPrefixComponentRefs(str, r, rarg, rest);
        e_1 = stringPrefixComponentRef(str, r, rarg, e);
      then
        (e_1 :: res);
  end matchcontinue;
end stringPrefixComponentRefs;

protected function stringPrefixComponentRef
  input String inString;
  input FuncTypeExp_ComponentRefType_bTo inFuncTypeExpComponentRefTypeBTo;
  input Type_b inTypeB;
  input Exp.Exp inExp;
  output Exp.Exp outExp;
  partial function FuncTypeExp_ComponentRefType_bTo
    input Exp.ComponentRef inComponentRef;
    input Type_b inTypeB;
    replaceable type Type_b;
  end FuncTypeExp_ComponentRefType_bTo;
  replaceable type Type_b;
algorithm 
  outExp:=
  matchcontinue (inString,inFuncTypeExpComponentRefTypeBTo,inTypeB,inExp)
    local
      Exp.ComponentRef cr_1,cr;
      String str;
      FuncTypeExp_ComponentRefType_bTo r;
      Type_b rarg;
      Exp.Type t,ty;
      Exp.Exp e1_1,e2_1,e1,e2,e3_1,e3,e;
      Exp.Operator op;
      list<Exp.Exp> el_1,el;
      Absyn.Path p;
      Boolean b,bi,a;
      list<list<Boolean>> bl;
      list<list<tuple<Exp.Exp, Boolean>>> ell_1,ell;
      Integer i;
    case (str,r,rarg,Exp.CREF(componentRef = cr,ty = t))
      equation 
        r(cr, rarg);
        cr_1 = stringPrefixCref(str, cr);
      then
        Exp.CREF(cr_1,t);
    case (_,r,rarg,Exp.CREF(componentRef = cr,ty = t))
      equation 
        failure(r(cr, rarg));
      then
        Exp.CREF(cr,t);
    case (str,r,rarg,Exp.BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation 
        e1_1 = stringPrefixComponentRef(str, r, rarg, e1);
        e2_1 = stringPrefixComponentRef(str, r, rarg, e2);
      then
        Exp.BINARY(e1_1,op,e2_1);
    case (str,r,rarg,Exp.UNARY(operator = op,exp = e1))
      equation 
        e1_1 = stringPrefixComponentRef(str, r, rarg, e1);
      then
        Exp.UNARY(op,e1_1);
    case (str,r,rarg,Exp.LBINARY(exp1 = e1,operator = op,exp2 = e2))
      equation 
        e1_1 = stringPrefixComponentRef(str, r, rarg, e1);
        e2_1 = stringPrefixComponentRef(str, r, rarg, e2);
      then
        Exp.LBINARY(e1_1,op,e2_1);
    case (str,r,rarg,Exp.LUNARY(operator = op,exp = e1))
      equation 
        e1_1 = stringPrefixComponentRef(str, r, rarg, e1);
      then
        Exp.LUNARY(op,e1_1);
    case (str,r,rarg,Exp.RELATION(exp1 = e1,operator = op,exp2 = e2))
      equation 
        e1_1 = stringPrefixComponentRef(str, r, rarg, e1);
        e2_1 = stringPrefixComponentRef(str, r, rarg, e2);
      then
        Exp.RELATION(e1_1,op,e2_1);
    case (str,r,rarg,Exp.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation 
        e1_1 = stringPrefixComponentRef(str, r, rarg, e1);
        e2_1 = stringPrefixComponentRef(str, r, rarg, e2);
        e3_1 = stringPrefixComponentRef(str, r, rarg, e3);
      then
        Exp.IFEXP(e1_1,e2_1,e3_1);
    case (str,r,rarg,Exp.CALL(path = p,expLst = el,tuple_ = b,builtin = bi,ty = tp))
      local Exp.Type tp;
      equation 
        el_1 = stringPrefixComponentRefs(str, r, rarg, el);
      then 
        Exp.CALL(p,el_1,b,bi,tp);
    case (str,r,rarg,Exp.ARRAY(ty = t,scalar = a,array = el))
      equation 
        el_1 = stringPrefixComponentRefs(str, r, rarg, el);
      then
        Exp.ARRAY(t,a,el_1);
    case (str,r,rarg,Exp.MATRIX(ty = t,integer = a,scalar = ell))
      local
        list<list<Exp.Exp>> el,el_1;
        Integer a;
      equation 
        el = Util.listListMap(ell, Util.tuple21);
        bl = Util.listListMap(ell, Util.tuple22);
        el_1 = stringPrefixComponentRefsList(str, r, rarg, el);
        ell_1 = Util.listListThreadTuple(el_1, bl);
      then
        Exp.MATRIX(t,a,ell_1);
    case (str,r,rarg,Exp.RANGE(ty = t,exp = e1,expOption = NONE,range = e2))
      equation 
        e1_1 = stringPrefixComponentRef(str, r, rarg, e1);
        e2_1 = stringPrefixComponentRef(str, r, rarg, e2);
      then
        Exp.RANGE(t,e1_1,NONE,e2_1);
    case (str,r,rarg,Exp.RANGE(ty = t,exp = e1,expOption = SOME(e2),range = e3))
      equation 
        e1_1 = stringPrefixComponentRef(str, r, rarg, e1);
        e2_1 = stringPrefixComponentRef(str, r, rarg, e2);
        e3_1 = stringPrefixComponentRef(str, r, rarg, e3);
      then
        Exp.RANGE(t,e1_1,SOME(e2_1),e3_1);
    case (str,r,rarg,Exp.TUPLE(PR = el))
      equation 
        el_1 = stringPrefixComponentRefs(str, r, rarg, el);
      then
        Exp.TUPLE(el_1);
    case (str,r,rarg,Exp.CAST(ty = ty,exp = e1))
      equation 
        e1_1 = stringPrefixComponentRef(str, r, rarg, e1);
      then
        Exp.CAST(ty,e1_1);
    case (str,r,rarg,Exp.ASUB(exp = e1,sub = i))
      equation 
        e1_1 = stringPrefixComponentRef(str, r, rarg, e1);
      then
        Exp.ASUB(e1_1,i);
    case (str,r,rarg,e) then e; 
  end matchcontinue;
end stringPrefixComponentRef;

protected function stringPrefixComponentRefsList
  input String inString;
  input FuncTypeExp_ComponentRefType_bTo inFuncTypeExpComponentRefTypeBTo;
  input Type_b inTypeB;
  input list<list<Exp.Exp>> inExpExpLstLst;
  output list<list<Exp.Exp>> outExpExpLstLst;
  partial function FuncTypeExp_ComponentRefType_bTo
    input Exp.ComponentRef inComponentRef;
    input Type_b inTypeB;
    replaceable type Type_b;
  end FuncTypeExp_ComponentRefType_bTo;
  replaceable type Type_b;
algorithm 
  outExpExpLstLst:=
  matchcontinue (inString,inFuncTypeExpComponentRefTypeBTo,inTypeB,inExpExpLstLst)
    local
      list<Exp.Exp> el_1,el;
      list<list<Exp.Exp>> res,rest;
      String str;
      FuncTypeExp_ComponentRefType_bTo r;
      Type_b rarg;
    case (_,_,_,{}) then {}; 
    case (str,r,rarg,(el :: rest))
      equation 
        el_1 = stringPrefixComponentRefs(str, r, rarg, el);
        res = stringPrefixComponentRefsList(str, r, rarg, rest);
      then
        (el_1 :: res);
  end matchcontinue;
end stringPrefixComponentRefsList;

protected function stringPrefixCref
  input String inString;
  input Exp.ComponentRef inComponentRef;
  output Exp.ComponentRef outComponentRef;
algorithm 
  outComponentRef:=
  matchcontinue (inString,inComponentRef)
    local
      String s_1,str,s;
      list<Exp.Subscript> si;
      Exp.ComponentRef cr;
    case (str,Exp.CREF_IDENT(ident = s,subscriptLst = si))
      equation 
        s_1 = stringAppend(str, s);
      then
        Exp.CREF_IDENT(s_1,si);
    case (str,Exp.CREF_QUAL(ident = s,subscriptLst = si,componentRef = cr))
      equation 
        s_1 = stringAppend(str, s);
      then
        Exp.CREF_QUAL(s_1,si,cr);
  end matchcontinue;
end stringPrefixCref;

protected function stringPrefixElements
  input String inString1;
  input list<DAE.Element> inDAEElementLst2;
  input list<DAE.Element> inDAEElementLst3;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  outDAEElementLst:=
  matchcontinue (inString1,inDAEElementLst2,inDAEElementLst3)
    local
      DAE.Element el_1,el;
      list<DAE.Element> res,dae,rest;
      String str;
    case (_,_,{}) then {}; 
    case (str,dae,(el :: rest))
      equation 
        el_1 = stringPrefixElement(str, dae, el);
        res = stringPrefixElements(str, dae, rest);
      then
        (el_1 :: res);
  end matchcontinue;
end stringPrefixElements;

protected function stringPrefixElement
  input String inString;
  input list<DAE.Element> inDAEElementLst;
  input DAE.Element inElement;
  output DAE.Element outElement;
algorithm 
  outElement:=
  matchcontinue (inString,inDAEElementLst,inElement)
    local
      Exp.Exp exp_1,exp,exp1_1,exp2_1,exp1,exp2;
      String str,n;
      list<DAE.Element> dae,dae_1,dae1;
      Exp.ComponentRef cr;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Type ty;
      list<Exp.Subscript> inst_dims;
      Option<Exp.Exp> start;
      DAE.Flow flow_;
      list<Absyn.Path> cl;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      Algorithm.Algorithm alg;
      DAE.ExternalDecl decl;
      DAE.Element e;
    case (str,dae,DAE.VAR(componentRef = cr,varible = vk,variable = vd,input_ = ty,one = SOME(exp),binding = inst_dims,dimension = start,value = flow_,flow_ = cl,variableAttributesOption = dae_var_attr,absynCommentOption = comment))
      equation 
        exp_1 = stringPrefixComponentRef(str, isParameterDaelist, dae, exp);
      then
        DAE.VAR(cr,vk,vd,ty,SOME(exp_1),inst_dims,start,flow_,cl,
          dae_var_attr,comment);
    case (str,dae,DAE.DEFINE(componentRef = cr,exp = exp))
      equation 
        exp_1 = stringPrefixComponentRef(str, isParameterDaelist, dae, exp);
      then
        DAE.DEFINE(cr,exp_1);
    case (str,dae,DAE.EQUATION(exp = exp1,scalar = exp2))
      equation 
        exp1_1 = stringPrefixComponentRef(str, isParameterDaelist, dae, exp1);
        exp2_1 = stringPrefixComponentRef(str, isParameterDaelist, dae, exp2);
      then
        DAE.EQUATION(exp1_1,exp2_1);
    case (str,dae,DAE.ALGORITHM(algorithm_ = alg)) then DAE.ALGORITHM(alg); 
    case (str,dae1,DAE.COMP(ident = n,dAElist = DAE.DAE(elementLst = dae))) /* What happens if a variable is not found among dae, should we check dae1,
    i.e. where the COMP and FUNCTION was found? */ 
      equation 
        dae_1 = stringPrefixElements(str, dae, dae);
      then
        DAE.COMP(n,DAE.DAE(dae_1));
    case (str,dae1,DAE.FUNCTION(path = n,dAElist = DAE.DAE(elementLst = dae),type_ = ty))
      local
        Absyn.Path n;
        tuple<Types.TType, Option<Absyn.Path>> ty;
      equation 
        dae_1 = stringPrefixElements(str, dae, dae);
      then
        DAE.FUNCTION(n,DAE.DAE(dae_1),ty);
    case (str,dae1,DAE.EXTFUNCTION(path = n,dAElist = DAE.DAE(elementLst = dae),type_ = ty,externalDecl = decl))
      local
        Absyn.Path n;
        tuple<Types.TType, Option<Absyn.Path>> ty;
      equation 
        dae_1 = stringPrefixElements(str, dae, dae);
      then
        DAE.EXTFUNCTION(n,DAE.DAE(dae_1),ty,decl);
    case (str,dae,e) then e; 
  end matchcontinue;
end stringPrefixElement;

protected function isParameterDaelist
  input Exp.ComponentRef inComponentRef;
  input list<DAE.Element> inDAEElementLst;
algorithm 
  _:=
  matchcontinue (inComponentRef,inDAEElementLst)
    local
      Exp.ComponentRef cr,crv;
      DAE.VarDirection vd;
      DAE.Type ty;
      Option<Exp.Exp> e;
      list<DAE.Element> rest;
      DAE.VarKind vk;
    case (cr,(DAE.VAR(componentRef = crv,varible = DAE.PARAM(),variable = vd,input_ = ty,one = e) :: rest))
      equation 
        true = Exp.crefEqual(cr, crv);
      then
        ();
    case (cr,(DAE.VAR(componentRef = crv,varible = vk,variable = vd,input_ = ty,one = e) :: rest))
      equation 
        true = Exp.crefEqual(cr, crv);
      then
        fail();
    case (cr,(e :: rest))
      local DAE.Element e;
      equation 
        isParameterDaelist(cr, rest);
      then
        ();
  end matchcontinue;
end isParameterDaelist;

public function stringPrefixParams
  input DAE.DAElist inDAElist;
  output DAE.DAElist outDAElist;
algorithm 
  outDAElist:=
  matchcontinue (inDAElist)
    local list<DAE.Element> dae_1,dae;
    case DAE.DAE(elementLst = dae)
      equation 
        dae_1 = stringPrefixElements("params->", dae, dae);
      then
        DAE.DAE(dae_1);
  end matchcontinue;
end stringPrefixParams;

public function optPathString "function: optPathString
 
  Prints a Path option to a string.
"
  input Option<Absyn.Path> inAbsynPathOption;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAbsynPathOption)
    local
      String str;
      Absyn.Path p;
    case (NONE) then ""; 
    case (SOME(p))
      equation 
        str = pathString(p);
      then
        str;
  end matchcontinue;
end optPathString;

public function pathString "function: pathString
 
  Prints a Path to a string.
"
  input Absyn.Path inPath;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inPath)
    local
      String s;
      Absyn.Path path;
    case path
      equation 
        true = RTOpts.modelicaOutput();
        s = pathString2(path, "__");
      then
        s;
    case path
      equation 
        false = RTOpts.modelicaOutput();
        s = pathString2(path, ".");
      then
        s;
  end matchcontinue;
end pathString;

public function pathString2 "function: pathString2
 
  Helper function to path_string.
"
  input Absyn.Path inPath;
  input String inString;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inPath,inString)
    local
      String s,ns,s1,ss,str;
      Absyn.Path n;
    case (Absyn.IDENT(name = s),_) then s; 
    case (Absyn.QUALIFIED(name = s,path = n),str)
      equation 
        ns = pathString2(n, str);
        s1 = stringAppend(s, str);
        ss = stringAppend(s1, ns);
      then
        ss;
  end matchcontinue;
end pathString2;

public function pathEqual "function: pathEqual
 
  Returns true if two paths are equal.
"
  input Absyn.Path inPath1;
  input Absyn.Path inPath2;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inPath1,inPath2)
    local
      String id1,id2;
      Boolean res;
      Absyn.Path path1,path2;
    case (Absyn.IDENT(name = id1),Absyn.IDENT(name = id2))
      equation 
        equality(id1 = id2);
      then
        true;
    case (Absyn.IDENT(name = id1),Absyn.IDENT(name = id2))
      equation 
        failure(equality(id1 = id2));
      then
        false;
    case (Absyn.QUALIFIED(name = id1,path = path1),Absyn.QUALIFIED(name = id2,path = path2))
      equation 
        equality(id1 = id2);
        res = pathEqual(path1, path2);
      then
        res;
    case (Absyn.QUALIFIED(name = id1,path = path1),Absyn.QUALIFIED(name = id2,path = path2))
      equation 
        failure(equality(id1 = id2));
      then
        false;
    case (_,_) then false; 
  end matchcontinue;
end pathEqual;

public function typeSpecEqual "function: typeSpecEqual
 
  Returns true if two type specifications are equal.
"
  input Absyn.TypeSpec inTySpec1;
  input Absyn.TypeSpec inTySpec2;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inTySpec1,inTySpec2)
    local
      String id1,id2;
      Boolean res;
      Absyn.TypeSpec tySpec1, tySpec2;
    case (tySpec1, tySpec2)
      equation 
        equality(tySpec1 = tySpec1);
      then
        true;
    case (tySpec1, tySpec2)
      equation 
        failure(equality(tySpec1 = tySpec2));
      then
        false;
    case (_,_) then false; 
  end matchcontinue;
end typeSpecEqual;


end ModUtil;

