/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköpings, Sweden.
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

package CevalScript
" file:	 CevalScript.mo
  package:      CevalScript
  description: Constant propagation of expressions

  RCS: $Id$

  This module handles scripting.
 
  Input: 
 	Env: Environment with bindings
 	Exp: Expression to evaluate
 	Bool flag determines whether the current instantiation is implicit
 	InteractiveSymbolTable is optional, and used in interactive mode,
 	e.g. from OMShell
 	
  Output:
 	Value: The evaluated value
      InteractiveSymbolTable: Modified symbol table
      Subscript list : Evaluates subscripts and generates constant expressions."

public import Env;
public import Interactive;
public import Values;
public import Absyn;
public import Ceval;

protected import AbsynDep;
protected import Refactor;
protected import ClassLoader;
protected import Parser;
protected import Dump;
protected import ClassInf;
protected import Exp;
protected import Settings;
protected import SCode;
protected import DAE;
protected import Util;
protected import ModUtil;
protected import RTOpts;
protected import Debug;
protected import Lookup;
protected import Inst;
protected import InstanceHierarchy;
protected import Prefix;
protected import Connect;
protected import Print;
protected import System;
protected import Types;
protected import Error;
protected import Static;
protected import ValuesUtil;

public function cevalInteractiveFunctions 
"function cevalInteractiveFunctions
  This function evaluates the functions 
  defined in the interactive environment."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp "expression to evaluate";
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  (outCache,outValue,outInteractiveSymbolTable):=(inCache,Values.STRING("CevalScript is a stub!"),inInteractiveSymbolTable);
end cevalInteractiveFunctions;

protected function setEcho 
  input Boolean echo;
algorithm
  _:=
  matchcontinue (echo)
    local
    case (true)
      equation 
        Settings.setEcho(1);
      then
        ();
    case (false)
      equation 
        Settings.setEcho(0);
      then
        ();
  end matchcontinue; 
end setEcho;

protected function cevalValArray "Help function to cevalInteractiveFunctions. Handles val(var,{timestamps})"
	input Env.Cache cache;
	input Env.Env env;
  input Option<Interactive.InteractiveSymbolTable> st;
	input list<Real> timeStamps;
	input String varName;
	output Env.Cache outCache;
	output Values.Value value;
algorithm
  (outCache,value) := (cache, Values.STRING("CevalScript is a stub!")); 
end cevalValArray;

protected function cevalVal "Help function to cevalInteractiveFunctions. Handles val(var,timestamp)"
	input Env.Cache cache;
	input Env.Env env;
  input Option<Interactive.InteractiveSymbolTable> stopt;
	input Real timeStamp;
	input String varName;
	output Env.Cache outCache;
	output Real value;
algorithm
  (outCache,value) := (cache, 0.0);
end cevalVal;

public function buildModel "function buildModel
 author: x02lucpo
 translates and builds the model by running compiler script on the generated makefile"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output String outString1 "className";
  output String outString2 "method";
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable3;
  output String outString4 "initFileName";
algorithm 
  (outCache,outString1,outString2,outInteractiveSymbolTable3,outString4):=
  (inCache,"","",inInteractiveSymbolTable,"");
end buildModel;

protected function compileModel "function: compileModel
  author: PA, x02lucpo
  Compiles a model given a file-prefix, helper function to buildModel."
  input String inFilePrefix;
  input list<String> inLibsList;
  input String inFileDir;
  input String noClean;
algorithm 
  _:= matchcontinue (inFilePrefix,inLibsList,inFileDir,noClean)
    case (inFilePrefix,inLibsList,inFileDir,noClean) 
      then
        ();
  end matchcontinue;
end compileModel;

protected function winCitation "function: winCitation
  author: PA
  Returns a citation mark if platform is windows, otherwise empty string. 
  Used by simulate to make whitespaces work in filepaths for WIN32"
  output String outString;
algorithm 
  outString:=
  matchcontinue ()
    case ()
      equation 
        "WIN32" = System.platform();
      then
        "\"";
    case () then ""; 
  end matchcontinue;
end winCitation;

public function cevalAstExp 
"function: cevalAstExp
  Part of meta-programming using CODE.
  This function evaluates a piece of Expression AST, replacing Eval(variable)
  with the value of the variable, given that it is of type \"Expression\".
  
  Example: y = Code(1 + x)
           2 + 5  ( x + Eval(y) )  =>   2 + 5  ( x + 1 + x )"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Exp inExp;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Absyn.Exp outExp;
algorithm 
  (outCache,outExp) :=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Absyn.Exp e,e1_1,e2_1,e1,e2,e_1,cond_1,then_1,else_1,cond,then_,else_,exp,e3_1,e3;
      list<Env.Frame> env;
      Absyn.Operator op;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Ceval.Msg msg;
      list<tuple<Absyn.Exp, Absyn.Exp>> nest_1,nest;
      Absyn.ComponentRef cr;
      Absyn.FunctionArgs fa;
      list<Absyn.Exp> expl_1,expl;
      Env.Cache cache;
    case (cache,_,(e as Absyn.INTEGER(value = _)),_,_,_) then (cache,e); 
    case (cache,_,(e as Absyn.REAL(value = _)),_,_,_) then (cache,e); 
    case (cache,_,(e as Absyn.CREF(componentReg = _)),_,_,_) then (cache,e); 
    case (cache,_,(e as Absyn.STRING(value = _)),_,_,_) then (cache,e); 
    case (cache,_,(e as Absyn.BOOL(value = _)),_,_,_) then (cache,e); 
    case (cache,env,Absyn.BINARY(exp1 = e1,op = op,exp2 = e2),impl,st,msg)
      equation 
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg);
      then
        (cache,Absyn.BINARY(e1_1,op,e2_1));
    case (cache,env,Absyn.UNARY(op = op,exp = e),impl,st,msg)
      equation 
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg);
      then
        (cache,Absyn.UNARY(op,e_1));
    case (cache,env,Absyn.LBINARY(exp1 = e1,op = op,exp2 = e2),impl,st,msg)
      equation 
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg);
      then
        (cache,Absyn.LBINARY(e1_1,op,e2_1));
    case (cache,env,Absyn.LUNARY(op = op,exp = e),impl,st,msg)
      equation 
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg);
      then
        (cache,Absyn.LUNARY(op,e_1));
    case (cache,env,Absyn.RELATION(exp1 = e1,op = op,exp2 = e2),impl,st,msg)
      equation 
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg);
      then
        (cache,Absyn.RELATION(e1_1,op,e2_1));
    case (cache,env,Absyn.IFEXP(ifExp = cond,trueBranch = then_,elseBranch = else_,elseIfBranch = nest),impl,st,msg)
      equation 
        (cache,cond_1) = cevalAstExp(cache,env, cond, impl, st, msg);
        (cache,then_1) = cevalAstExp(cache,env, then_, impl, st, msg);
        (cache,else_1) = cevalAstExp(cache,env, else_, impl, st, msg);
        (cache,nest_1) = cevalAstExpexpList(cache,env, nest, impl, st, msg);
      then
        (cache,Absyn.IFEXP(cond_1,then_1,else_1,nest_1));
    case (cache,env,Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "Eval",subscripts = {}),functionArgs = Absyn.FUNCTIONARGS(args = {e},argNames = {})),impl,st,msg)
      local DAE.Exp e_1;
      equation 
        (cache,e_1,_,_) = Static.elabExp(cache,env, e, impl, st,true);
        (cache,Values.CODE(Absyn.C_EXPRESSION(exp)),_) = Ceval.ceval(cache,env, e_1, impl, st, NONE, msg);
      then
        (cache,exp);
    case (cache,env,(e as Absyn.CALL(function_ = cr,functionArgs = fa)),_,_,msg) then (cache,e); 
    case (cache,env,Absyn.ARRAY(arrayExp = expl),impl,st,msg)
      equation 
        (cache,expl_1) = cevalAstExpList(cache,env, expl, impl, st, msg);
      then
        (cache,Absyn.ARRAY(expl_1));
    case (cache,env,Absyn.MATRIX(matrix = expl),impl,st,msg)
      local list<list<Absyn.Exp>> expl_1,expl;
      equation 
        (cache,expl_1) = cevalAstExpListList(cache,env, expl, impl, st, msg);
      then
        (cache,Absyn.MATRIX(expl_1));
    case (cache,env,Absyn.RANGE(start = e1,step = SOME(e2),stop = e3),impl,st,msg)
      equation 
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg);
        (cache,e3_1) = cevalAstExp(cache,env, e3, impl, st, msg);
      then
        (cache,Absyn.RANGE(e1_1,SOME(e2_1),e3_1));
    case (cache,env,Absyn.RANGE(start = e1,step = NONE,stop = e3),impl,st,msg)
      equation 
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg);
        (cache,e3_1) = cevalAstExp(cache,env, e3, impl, st, msg);
      then
        (cache,Absyn.RANGE(e1_1,NONE,e3_1));
    case (cache,env,Absyn.TUPLE(expressions = expl),impl,st,msg)
      equation 
        (cache,expl_1) = cevalAstExpList(cache,env, expl, impl, st, msg);
      then
        (cache,Absyn.TUPLE(expl_1));
    case (cache,env,Absyn.END(),_,_,msg) then (cache,Absyn.END()); 
    case (cache,env,(e as Absyn.CODE(code = _)),_,_,msg) then (cache,e); 
  end matchcontinue;
end cevalAstExp;

public function cevalAstExpList 
"function: cevalAstExpList
  List version of cevalAstExp"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output list<Absyn.Exp> outAbsynExpLst;
algorithm 
  (outCache,outAbsynExpLst) :=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      Ceval.Msg msg;
      Absyn.Exp e_1,e;
      list<Absyn.Exp> res,es;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Env.Cache cache;
    case (cache,env,{},_,_,msg) then (cache,{}); 
    case (cache,env,(e :: es),impl,st,msg)
      equation 
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg);
        (cache,res) = cevalAstExpList(cache,env, es, impl, st, msg);
      then
        (cache,e :: res);
  end matchcontinue;
end cevalAstExpList;

protected function cevalAstExpListList "function: cevalAstExpListList"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<list<Absyn.Exp>> inAbsynExpLstLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output list<list<Absyn.Exp>> outAbsynExpLstLst;
algorithm 
  (outCache,outAbsynExpLstLst) :=
  matchcontinue (inCache,inEnv,inAbsynExpLstLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      Ceval.Msg msg;
      list<Absyn.Exp> e_1,e;
      list<list<Absyn.Exp>> res,es;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Env.Cache cache;
    case (cache,env,{},_,_,msg) then (cache,{}); 
    case (cache,env,(e :: es),impl,st,msg)
      equation 
        (cache,e_1) = cevalAstExpList(cache,env, e, impl, st, msg);
        (cache,res) = cevalAstExpListList(cache,env, es, impl, st, msg);
      then
        (cache,e :: res);
  end matchcontinue;
end cevalAstExpListList;

protected function cevalAstExpexpList 
"function: cevalAstExpexpList
  For IFEXP"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<tuple<Absyn.Exp, Absyn.Exp>> inTplAbsynExpAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output list<tuple<Absyn.Exp, Absyn.Exp>> outTplAbsynExpAbsynExpLst;
algorithm 
  (outCache,outTplAbsynExpAbsynExpLst) :=
  matchcontinue (inCache,inEnv,inTplAbsynExpAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Ceval.Msg msg;
      Absyn.Exp e1_1,e2_1,e1,e2;
      list<tuple<Absyn.Exp, Absyn.Exp>> res,xs;
      list<Env.Frame> env;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Env.Cache cache;
    case (cache,_,{},_,_,msg) then (cache,{}); 
    case (cache,env,((e1,e2) :: xs),impl,st,msg)
      equation 
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg);
        (cache,res) = cevalAstExpexpList(cache,env, xs, impl, st, msg);
      then
        (cache,(e1_1,e2_1) :: res);
  end matchcontinue;
end cevalAstExpexpList;

public function cevalAstElt 
"function: cevalAstElt
  Evaluates an ast constructor for Element nodes, e.g. 
  Code(parameter Real x=1;)"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Element inElement;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Absyn.Element outElement;
algorithm 
  (outCache,outElement) :=
  matchcontinue (inCache,inEnv,inElement,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Absyn.ComponentItem> citems_1,citems;
      list<Env.Frame> env;
      Boolean f,isReadOnly,impl;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter io;
      String id,file;
      Absyn.ElementAttributes attr;
      Absyn.TypeSpec tp;
      Absyn.Info info;
      Integer sline,scolumn,eline,ecolumn;
      Option<Absyn.ConstrainClass> c;
      Option<Interactive.InteractiveSymbolTable> st;
      Ceval.Msg msg;
      Env.Cache cache;
    case (cache,env,Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = io,name = id,specification = Absyn.COMPONENTS(attributes = attr,typeSpec = tp,components = citems),info = (info as Absyn.INFO(fileName = file,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scolumn,lineNumberEnd = eline,columnNumberEnd = ecolumn)),constrainClass = c),impl,st,msg)
      equation 
        (cache,citems_1) = cevalAstCitems(cache,env, citems, impl, st, msg);
      then
        (cache,Absyn.ELEMENT(f,r,io,id,Absyn.COMPONENTS(attr,tp,citems_1),info,c));
  end matchcontinue;
end cevalAstElt;

protected function cevalAstCitems 
"function: cevalAstCitems
  Helper function to cevalAstElt."
 	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output list<Absyn.ComponentItem> outAbsynComponentItemLst;
algorithm 
  (outCache,outAbsynComponentItemLst) :=
  matchcontinue (inCache,inEnv,inAbsynComponentItemLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Ceval.Msg msg;
      list<Absyn.ComponentItem> res,xs;
      Option<Absyn.Modification> modopt_1,modopt;
      list<Absyn.Subscript> ad_1,ad;
      list<Env.Frame> env;
      String id;
      Option<Absyn.Exp> cond;
      Option<Absyn.Comment> cmt;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Absyn.ComponentItem x;
      Env.Cache cache;
    case (cache,_,{},_,_,msg) then (cache,{}); 
    case (cache,env,(Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = ad,modification = modopt),condition = cond,comment = cmt) :: xs),impl,st,msg) /* If one component fails, the rest should still succeed */ 
      equation 
        (cache,res) = cevalAstCitems(cache,env, xs, impl, st, msg);
        (cache,modopt_1) = cevalAstModopt(cache,env, modopt, impl, st, msg);
        (cache,ad_1) = cevalAstArraydim(cache,env, ad, impl, st, msg);
      then
        (cache,Absyn.COMPONENTITEM(Absyn.COMPONENT(id,ad_1,modopt_1),cond,cmt) :: res);
    case (cache,env,(x :: xs),impl,st,msg) /* If one component fails, the rest should still succeed */ 
      equation 
        (cache,res) = cevalAstCitems(cache,env, xs, impl, st, msg);
      then
        (cache,x :: res);
  end matchcontinue;
end cevalAstCitems;

protected function cevalAstModopt 
"function: cevalAstModopt"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Option<Absyn.Modification> inAbsynModificationOption;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Option<Absyn.Modification> outAbsynModificationOption;
algorithm 
  (outCache,outAbsynModificationOption) :=
  matchcontinue (inCache,inEnv,inAbsynModificationOption,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Absyn.Modification res,mod;
      list<Env.Frame> env;
      Boolean st;
      Option<Interactive.InteractiveSymbolTable> impl;
      Ceval.Msg msg;
      Env.Cache cache;
    case (cache,env,SOME(mod),st,impl,msg)
      equation 
        (cache,res) = cevalAstModification(cache,env, mod, st, impl, msg);
      then
        (cache,SOME(res));
    case (cache,env,NONE,_,_,msg) then (cache,NONE); 
  end matchcontinue;
end cevalAstModopt;

protected function cevalAstModification "function: cevalAstModification
  This function evaluates Eval(variable) inside an AST Modification  and replaces 
  the Eval operator with the value of the variable if it has a type \"Expression\""
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Modification inModification;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Absyn.Modification outModification;
algorithm 
  (outCache,outModification) :=
  matchcontinue (inCache,inEnv,inModification,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Absyn.Exp e_1,e;
      list<Absyn.ElementArg> eltargs_1,eltargs;
      list<Env.Frame> env;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Ceval.Msg msg;
      Env.Cache cache;
    case (cache,env,Absyn.CLASSMOD(elementArgLst = eltargs,expOption = SOME(e)),impl,st,msg)
      equation 
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg);
        (cache,eltargs_1) = cevalAstEltargs(cache,env, eltargs, impl, st, msg);
      then
        (cache,Absyn.CLASSMOD(eltargs_1,SOME(e_1)));
    case (cache,env,Absyn.CLASSMOD(elementArgLst = eltargs,expOption = NONE),impl,st,msg)
      equation 
        (cache,eltargs_1) = cevalAstEltargs(cache,env, eltargs, impl, st, msg);
      then
        (cache,Absyn.CLASSMOD(eltargs_1,NONE));
  end matchcontinue;
end cevalAstModification;

protected function cevalAstEltargs "function: cevalAstEltargs
  Helper function to cevalAstModification."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm 
  (outCache,outAbsynElementArgLst):=
  matchcontinue (inCache,inEnv,inAbsynElementArgLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      Ceval.Msg msg;
      Absyn.Modification mod_1,mod;
      list<Absyn.ElementArg> res,args;
      Boolean b,impl;
      Absyn.Each e;
      Absyn.ComponentRef cr;
      Option<String> stropt;
      Option<Interactive.InteractiveSymbolTable> st;
      Absyn.ElementArg m;
      Env.Cache cache;
    case (cache,env,{},_,_,msg) then (cache,{}); 
    /* TODO: look through redeclarations for Eval(var) as well */   
    case (cache,env,(Absyn.MODIFICATION(finalItem = b,each_ = e,componentReg = cr,modification = SOME(mod),comment = stropt) :: args),impl,st,msg) 
      equation 
        (cache,mod_1) = cevalAstModification(cache,env, mod, impl, st, msg);
        (cache,res) = cevalAstEltargs(cache,env, args, impl, st, msg);
      then
        (cache,Absyn.MODIFICATION(b,e,cr,SOME(mod_1),stropt) :: res);
    case (cache,env,(m :: args),impl,st,msg) /* TODO: look through redeclarations for Eval(var) as well */ 
      equation 
        (cache,res) = cevalAstEltargs(cache,env, args, impl, st, msg);
      then
        (cache,m :: res);
  end matchcontinue;
end cevalAstEltargs;

protected function cevalAstArraydim "function: cevalAstArraydim
  Helper function to cevaAstCitems"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ArrayDim inArrayDim;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Absyn.ArrayDim outArrayDim;
algorithm 
  (outCache,outArrayDim) :=
  matchcontinue (inCache,inEnv,inArrayDim,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      Ceval.Msg msg;
      list<Absyn.Subscript> res,xs;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Absyn.Exp e_1,e;
      Env.Cache cache;
    case (cache,env,{},_,_,msg) then (cache,{}); 
    case (cache,env,(Absyn.NOSUB() :: xs),impl,st,msg)
      equation 
        (cache,res) = cevalAstArraydim(cache,env, xs, impl, st, msg);
      then
        (cache,Absyn.NOSUB() :: res);
    case (cache,env,(Absyn.SUBSCRIPT(subScript = e) :: xs),impl,st,msg)
      equation 
        (cache,res) = cevalAstArraydim(cache,env, xs, impl, st, msg);
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg);
      then
        (cache,Absyn.SUBSCRIPT(e) :: res);
  end matchcontinue;
end cevalAstArraydim;

public function checkModel "function: checkModel
 checks a model and returns number of variables and equations"
	input Env.Cache inCache;
	input Env.Env inEnv;
  input Absyn.Path className;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  (outCache,outValue,outInteractiveSymbolTable) := (inCache,Values.STRING("CevalScript is only a stub!"),inInteractiveSymbolTable);  
end checkModel; 

public function getValueString "
Constant evaluates Expression and returns a string representing value. 
"
  input DAE.Exp e1;
  output String ostring;
algorithm ostring := matchcontinue( e1)
  case(e1)
    local Values.Value val;
      String ret;
    equation
      (_,val as Values.STRING(ret),_) = Ceval.ceval(Env.emptyCache,Env.emptyEnv, e1,true,NONE,NONE,Ceval.MSG());
    then
      ret;
  case(e1)
    local Values.Value val;
      String ret;
    equation
      (_,val,_) = Ceval.ceval(Env.emptyCache,Env.emptyEnv, e1,true,NONE,NONE,Ceval.MSG());
      ret = ValuesUtil.printValStr(val);
    then
      ret;
      
end matchcontinue;
end getValueString;

public function generateMakefileHeader
  output String hdr;
algorithm
  hdr := matchcontinue ()
    local
      String omhome,header,ccompiler,cxxcompiler,linker,exeext,dllext,cflags,ldflags;
    case()
      equation
        ccompiler = System.getCCompiler();
        cxxcompiler = System.getCXXCompiler();
        linker = System.getLinker();
        exeext = System.getExeExt();
        dllext = System.getDllExt();
        omhome = Settings.getInstallationDirectoryPath();
        omhome = System.trim(omhome, "\""); //Remove any quotation marks from omhome.
        cflags = System.getCFlags();
        ldflags = System.getLDFlags();
        header = Util.stringAppendList({
          "#Makefile generated by OpenModelica\n\n",
          "CC=",ccompiler,"\n",
          "CXX=",cxxcompiler,"\n",
          "LINK=",linker,"\n",
          "EXEEXT=",exeext,"\n",
          "DLLEXT=",dllext,"\n",
          "CFLAGS= -I\"",omhome,"/include\" ", cflags ,"\n",
          "LDFLAGS= -L\"",omhome,"/lib\" ", ldflags ,"\n"
          });
    then header;
  end matchcontinue;
end generateMakefileHeader;

protected function generateMakefilename "function generateMakefilename"
  input String filenameprefix;
  output String makefilename;
algorithm 
  makefilename := Util.stringAppendList({filenameprefix,".makefile"});
end generateMakefilename;

public function cevalGenerateFunction "function: cevalGenerateFunction
  Generates code for a given function name."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output Env.Cache outCache;
  output String functionName; 
algorithm 
  outCache := inCache;
end cevalGenerateFunction;

public function getFileDir "function: getFileDir
  author: x02lucpo
  returns the dir where class file (.mo) was saved or 
  $OPENMODELICAHOME/work if the file was not saved yet"
  input Absyn.ComponentRef inComponentRef "class";
  input Absyn.Program inProgram;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path p_class;
      Absyn.Class cdef;
      String filename,pd,dir_1,omhome,omhome_1,cit;
      String pd_1;
      list<String> filename_1,dir;
      Absyn.ComponentRef class_;
      Absyn.Program p;
    case (class_,p)
      equation 
        p_class = Absyn.crefToPath(class_) "change to the saved files directory" ;
        cdef = Interactive.getPathedClassInProgram(p_class, p);
        filename = Absyn.classFilename(cdef);
        pd = System.pathDelimiter();
        (pd_1 :: _) = string_list_string_char(pd);
        filename_1 = Util.stringSplitAtChar(filename, pd_1);
        dir = Util.listStripLast(filename_1);
        dir_1 = Util.stringDelimitList(dir, pd);
      then
        dir_1;
    case (class_,p)
      equation 
        omhome = Settings.getInstallationDirectoryPath() "model not yet saved! change to $OPENMODELICAHOME/work" ;
        omhome_1 = System.trim(omhome, "\"");
        pd = System.pathDelimiter();
        cit = winCitation();
        dir_1 = Util.stringAppendList({cit,omhome_1,pd,"work",cit});
      then
        dir_1;
    case (_,_) then "";  /* this function should never fail */ 
  end matchcontinue;
end getFileDir;

end CevalScript;