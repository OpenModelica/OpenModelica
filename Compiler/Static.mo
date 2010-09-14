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

package Static
" file:	       Static.mo
  package:     Static
  description: Static analysis of expressions

  RCS: $Id$

  This module does static analysis on expressions.
  The analyzed expressions are built using the
  constructors in the `Exp\' module from expressions defined in \'Absyn\'.
  Also, a set of properties of the expressions is calculated during analysis.
  Properties of expressions include type information and a boolean indicating if the
  expression is constant or not.
  If the expression is constant, the \'Ceval\' module is used to evaluate the expression
  value. A value of an expression is described using the \'Values\' module.

  The main function in this module is evalExp which takes an Absyn.Exp and transform it
  into an DAE.Exp, while performing type checking and automatic type conversions, etc.
  To determine types of builtin functions and operators, the module also contain an elaboration
  handler for functions and operators. This function is called elabBuiltinHandler.
  NOTE: These functions should only determine the type and properties of the builtin functions and
  operators and not evaluate them. Constant evaluation is performed by the Ceval module.
  The module also contain a function for deoverloading of operators, in the \'deoverload\' function.
  It transforms operators like \'+\' to its specific form, ADD, ADD_ARR, etc.

  Interactive function calls are also given their types by elabExp, which calls
  elabCallInteractive.

  Elaboration for functions involve checking the types of the arguments by filling slots of the
  argument list with first positional and then named arguments to find a matching function. The
  details of this mechanism can be found in the Modelica specification.
  The elaboration also contain function deoverloading which will be added to Modelica in the future."

public import Absyn;
public import ConnectionGraph;
public import Convert;
public import DAE;
public import Env;
public import Interactive;
public import MetaUtil;
public import RTOpts;
public import SCode;
public import SCodeUtil;
public import Values;

public type Ident = String;

public
uniontype Slot
  record SLOT
    DAE.FuncArg an "An argument to a function" ;
    Boolean true_ "True if the slot has been filled, i.e. argument has been given a value" ;
    Option<DAE.Exp> expExpOption;
    list<DAE.Dimension> typesArrayDimLst;
  end SLOT;
end Slot;

protected import Ceval;
protected import ClassInf;
protected import Connect;
protected import Debug;
protected import Dump;
protected import Error;
protected import ErrorExt;
protected import Exp;
protected import Inst;
protected import InnerOuter;
protected import Lookup;
protected import Mod;
protected import ModUtil;
protected import OptManager;
public import Prefix;
protected import Print;
protected import System;
protected import Types;
protected import UnitAbsyn;
protected import Util;
protected import ValuesUtil;
protected import DAEUtil;
protected import PrefixUtil;
protected import CevalScript;
// protected import AbsynDep;

protected constant DAE.Exp defaultOutputFormat = DAE.SCONST("plt");

public type Prefix = Prefix.Prefix "a prefix";

public function elabExpList "Expression elaboration of Absyn.Exp list, i.e. lists of expressions."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output list<DAE.Exp> outExpExpLst;
  output list<DAE.Properties> outTypesPropertiesLst;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExpExpLst,outTypesPropertiesLst,outInteractiveInteractiveSymbolTableOption,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,performVectorization,inPrefix)
    local
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st,st_1,st_2;
      DAE.Exp exp;
      DAE.Properties p;
      list<DAE.Exp> exps;
      list<DAE.Properties> props;
      list<Env.Frame> env;
      Absyn.Exp e;
      list<Absyn.Exp> rest;
      Env.Cache cache;
      Boolean doVect;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;
    case (cache,_,{},impl,st,doVect,_) then (cache,{},{},st,DAEUtil.emptyDae);
    case (cache,env,(e :: rest),impl,st,doVect,pre)
      equation
        (cache,exp,p,st_1,dae1) = elabExp(cache,env, e, impl, st,doVect,pre);
        (cache,exps,props,st_2,dae2) = elabExpList(cache,env, rest, impl, st_1,doVect,pre);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,(exp :: exps),(p :: props),st_2,dae);
  end matchcontinue;
end elabExpList;

public function elabExpListList
"function: elabExpListList
  Expression elaboration of lists of lists of expressions.
  Used in for instance matrices, etc."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<list<Absyn.Exp>> inAbsynExpLstLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output list<list<DAE.Exp>> outExpExpLstLst;
  output list<list<DAE.Properties>> outTypesPropertiesLstLst;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExpExpLstLst,outTypesPropertiesLstLst,outInteractiveInteractiveSymbolTableOption,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLstLst,inBoolean,inInteractiveInteractiveSymbolTableOption,performVectorization,inPrefix)
    local
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st,st_1,st_2;
      list<DAE.Exp> exp;
      list<DAE.Properties> p;
      list<list<DAE.Exp>> exps;
      list<list<DAE.Properties>> props;
      list<Env.Frame> env;
      list<Absyn.Exp> e;
      list<list<Absyn.Exp>> rest;
      Env.Cache cache;
      Boolean doVect;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;

    case (cache,_,{},impl,st,doVect,_) then (cache,{},{},st,DAEUtil.emptyDae);
    case (cache,env,(e :: rest),impl,st,doVect,pre)
      equation
        (cache,exp,p,st_1,dae1) = elabExpList(cache,env, e, impl, st,doVect,pre);
        (cache,exps,props,st_2,dae2) = elabExpListList(cache,env, rest, impl, st_1,doVect,pre);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,(exp :: exps),(p :: props),st_2,dae);
  end matchcontinue;
end elabExpListList;

public function elabExp "
function: elabExp
  Static analysis of expressions means finding out the properties of
  the expression.  These properties are described by the
  `DAE.Properties\' type, and include the type and the variability of the
  expression.  This function performs analysis, and returns an
  `DAE.Exp\' and the properties."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Exp inExp;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
  output DAE.DAElist outDae "contains functions";
algorithm
  (outCache,outExp,outProperties,outInteractiveInteractiveSymbolTableOption,outDae):=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inInteractiveInteractiveSymbolTableOption,performVectorization,inPrefix)
    local
      Integer x,l,nmax;
      DAE.Dimension dim1,dim2;
      Boolean impl,a,havereal;
      Option<Interactive.InteractiveSymbolTable> st,st_1,st_2,st_3;
      Ident id,expstr,envstr;
      DAE.Exp exp,e1_1,e2_1,e1_2,e2_2,exp_1,exp_2,e_1,e_2,e3_1,start_1,stop_1,start_2,stop_2,step_1,step_2,mexp,mexp_1;
      DAE.Properties prop,prop_1,prop1,prop2,prop3;
      list<Env.Frame> env;
      Absyn.ComponentRef cr,fn;
      DAE.Type t1,t2,arrtp,rtype,t,start_t,stop_t,step_t,t_1,t_2,tp;
      DAE.Const c1,c2,c,c_start,c_stop,const,c_step;
      list<tuple<DAE.Operator, list<tuple<DAE.TType, Option<Absyn.Path>>>, tuple<DAE.TType, Option<Absyn.Path>>>> ops;
      DAE.Operator op_1;
      Absyn.Exp e,e1,e2,e,e3,iterexp,start,stop,step;
      Absyn.Operator op;
      list<Absyn.Exp> args,rest,es;
      list<Absyn.NamedArg> nargs;
      list<DAE.Exp> es_1;
      list<DAE.Properties> props;
      list<tuple<DAE.TType, Option<Absyn.Path>>> types,tps_2;
      list<DAE.TupleConst> consts;
      DAE.ExpType rt,at,tp_1;
      list<list<DAE.Properties>> tps;
      list<list<tuple<DAE.TType, Option<Absyn.Path>>>> tps_1;
      Env.Cache cache;
      Boolean doVect;
      Absyn.ForIterators iterators;
      DAE.DAElist dae1,dae2,dae3,dae;
      Prefix pre;

    // The types below should contain the default values of the attributes of the builtin
    // types. But since they are default, we can leave them out for now, unit=\"\" is not 
    // that interesting to find out. 
    case (cache,_,Absyn.INTEGER(value = x),impl,st,doVect,_) 
    then (cache,DAE.ICONST(x),DAE.PROP(DAE.T_INTEGER_DEFAULT,DAE.C_CONST()),st,DAEUtil.emptyDae);  
      
    case (cache,_,Absyn.REAL(value = x),impl,st,doVect,_)
      local Real x;
      then
        (cache,DAE.RCONST(x),DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_CONST()),st,DAEUtil.emptyDae);

    case (cache,_,Absyn.STRING(value = x),impl,st,doVect,_)
      local Ident x;
      then
        (cache,DAE.SCONST(x),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_CONST()),st,DAEUtil.emptyDae);

    case (cache,_,Absyn.BOOL(value = x),impl,st,doVect,_)
      local Boolean x;
      then
        (cache,DAE.BCONST(x),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_CONST()),st,DAEUtil.emptyDae);

    case (cache,_,Absyn.END(),impl,st,doVect,_)
    then (cache,DAE.END(),DAE.PROP(DAE.T_INTEGER_DEFAULT,DAE.C_CONST()),st,DAEUtil.emptyDae);

    case (cache,env,Absyn.CREF(componentRef = cr),impl,st,doVect,pre) // BoschRexroth specifics
      local DAE.Type ty;
      equation
        false = OptManager.getOption("cevalEquation");
        (cache,exp,prop as DAE.PROP(ty,DAE.C_PARAM()),_,dae) = elabCref(cache,env, cr, impl,doVect,pre);
      then
        (cache,exp,DAE.PROP(ty,DAE.C_VAR()),st,dae);

    case (cache,env,Absyn.CREF(componentRef = cr),impl,st,doVect,pre)
      equation
        (cache,exp,prop,_,dae) = elabCref(cache,env, cr, impl,doVect,pre);
      then
        (cache,exp,prop,st,dae);

    case (cache,env,(exp as Absyn.BINARY(exp1 = e1,op = op,exp2 = e2)),impl,st,doVect,pre) /* Binary and unary operations */
      local Absyn.Exp exp;
      equation
        (cache,e1_1,DAE.PROP(t1,c1),st_1,dae1) = elabExp(cache,env, e1, impl, st,doVect,pre);
        (cache,e2_1,DAE.PROP(t2,c2),st_2,dae2) = elabExp(cache,env, e2, impl, st_1,doVect,pre);
        c = Types.constAnd(c1, c2);

        (cache,ops) = operators(cache,op, env, t1, t2);
        (op_1,{e1_2,e2_2},rtype) = deoverload(ops, {(e1_1,t1),(e2_1,t2)}, exp,pre);                
        exp_1 = replaceOperatorWithFcall(DAE.BINARY(e1_2,op_1,e2_2), c);
        exp_1 = Exp.simplify(exp_1);
        prop = DAE.PROP(rtype,c);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,exp_1,prop,st_2,dae);

    case (cache,env,(exp as Absyn.UNARY(op = op,exp = e)),impl,st,doVect,pre)
      local Absyn.Exp exp;
      equation
        (cache,e_1,DAE.PROP(t,c),st_1,dae1) = elabExp(cache,env, e, impl, st,doVect,pre);
        (cache,ops) = operators(cache,op, env, t, (DAE.T_NOTYPE(),NONE));
        (op_1,{e_2},rtype) = deoverload(ops, {(e_1,t)}, exp,pre);
        exp_1 = replaceOperatorWithFcall(DAE.UNARY(op_1,e_2), c);
        exp_1 = Exp.simplify(exp_1);
        prop = DAE.PROP(rtype,c);
      then
        (cache,exp_1,prop,st_1,dae1);
    case (cache,env,(exp as Absyn.LBINARY(exp1 = e1,op = op,exp2 = e2)),impl,st,doVect,pre)
      local Absyn.Exp exp;
      equation
        (cache,e1_1,DAE.PROP(t1,c1),st_1,dae1) = elabExp(cache,env, e1, impl, st,doVect,pre) "Logical binary expressions" ;
        (cache,e2_1,DAE.PROP(t2,c2),st_2,dae2) = elabExp(cache,env, e2, impl, st_1,doVect,pre);
        c = Types.constAnd(c1, c2);
        (cache,ops) = operators(cache,op, env, t1, t2);
        (op_1,{e1_2,e2_2},rtype) = deoverload(ops, {(e1_1,t1),(e2_1,t2)}, exp,pre);
        exp_1 = replaceOperatorWithFcall(DAE.LBINARY(e1_2,op_1,e2_2), c);
        exp_1 = Exp.simplify(exp_1);
        prop = DAE.PROP(rtype,c);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,exp_1,prop,st_2,dae);
    case (cache,env,(exp as Absyn.LUNARY(op = op,exp = e)),impl,st,doVect,pre)
      local Absyn.Exp exp;
      equation
        (cache,e_1,DAE.PROP(t,c),st_1,dae) = elabExp(cache,env, e, impl, st,doVect,pre) "Logical unary expressions" ;
        (cache,ops) = operators(cache,op, env, t, (DAE.T_NOTYPE(),NONE));
        (op_1,{e_2},rtype) = deoverload(ops, {(e_1,t)}, exp,pre);
        exp_1 = replaceOperatorWithFcall(DAE.LUNARY(op_1,e_2), c);
        exp_1 = Exp.simplify(exp_1);
        prop = DAE.PROP(rtype,c);
      then
        (cache,exp_1,prop,st_1,dae);
    case (cache,env,(exp as Absyn.RELATION(exp1 = e1,op = op,exp2 = e2)),impl,st,doVect,pre)
      local Absyn.Exp exp;
      equation
        (cache,e1_1,DAE.PROP(t1,c1),st_1,dae1) = elabExp(cache,env, e1, impl, st,doVect,pre) "Relations, e.g. a < b" ;
        (cache,e2_1,DAE.PROP(t2,c2),st_2,dae2) = elabExp(cache,env, e2, impl, st_1,doVect,pre);
        c = Types.constAnd(c1, c2);
        (cache,ops) = operators(cache,op, env, t1, t2);
        (op_1,{e1_2,e2_2},rtype) = deoverload(ops, {(e1_1,t1),(e2_1,t2)}, exp,pre);
        exp_1 = replaceOperatorWithFcall(DAE.RELATION(e1_2,op_1,e2_2), c);
        exp_1 = Exp.simplify(exp_1);
        prop = DAE.PROP(rtype,c);
        warnUnsafeRelations(c,t1,t2,e1_2,e2_2,op_1,pre);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,exp_1,prop,st_2,dae);
    case (cache,env,e as Absyn.IFEXP(ifExp = _),impl,st,doVect,pre) /* Conditional expressions */
      equation
        Absyn.IFEXP(ifExp = e1,trueBranch = e2,elseBranch = e3) = Absyn.canonIfExp(e);
        (cache,e1_1,prop1,st_1,dae1) = elabExp(cache,env, e1, impl, st,doVect,pre) "if expressions" ;
        (cache,e2_1,prop2,st_2,dae2) = elabExp(cache,env, e2, impl, st_1,doVect,pre);
        (cache,e3_1,prop3,st_3,dae3) = elabExp(cache,env, e3, impl, st_2,doVect,pre);
        (cache,e_1,prop) = elabIfexp(cache,env, e1_1, prop1, e2_1, prop2, e3_1, prop3, impl, st,pre);
        dae = DAEUtil.joinDaeLst({dae1,dae2,dae3});
      then
        (cache,e_1,prop,st_3,dae);

       /*--------------------------------*/
       /* Part of MetaModelica extension. KS */
    case (cache,env,Absyn.CALL(function_ = Absyn.CREF_IDENT("SOME",_),functionArgs = Absyn.FUNCTIONARGS(args = (e1 :: _),argNames = _)),impl,st,doVect,pre)
      local DAE.Exp e;
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (cache,e,prop,st_1,dae) = elabExp(cache,env, e1, impl, st,doVect,pre);
        t = Types.getPropType(prop);
        e = DAE.META_OPTION(SOME(e));
        c = Types.propAllConst(prop);
        prop1 = DAE.PROP((DAE.T_METAOPTION(t),NONE()),c);
      then
        (cache,e,prop1,st,dae);

    case (cache,env,Absyn.CALL(function_ = Absyn.CREF_IDENT("NONE",_),functionArgs = Absyn.FUNCTIONARGS(args = {},argNames = _)),impl,st,doVect,_)
      local DAE.Exp e;
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        e = DAE.META_OPTION(NONE());
        prop1 = DAE.PROP((DAE.T_METAOPTION((DAE.T_NOTYPE(),NONE)),NONE()),DAE.C_CONST());
      then
        (cache,e,prop1,st,DAEUtil.emptyDae);

      /*  case (cache,env,Absyn.CALL(function_ = fn,functionArgs = Absyn.FUNCTIONARGS(args = args,argNames = nargs)),impl,st,doVect)
      local DAE.Exp e;
          equation
            //true = RTOpts.acceptMetaModelicaGrammar();
            (cache,env,args,nargs) = MetaUtil.fixListConstructorsInArgs(cache,env,fn,args,nargs);
            Debug.fprintln("sei", "elab_exp CALL...") "Function calls PA. Only positional arguments are elaborated for now. TODO: Implement elaboration of named arguments." ;
            (cache,e,prop,st_1) = elabCall(cache,env, fn, args, nargs, impl, st);
            c = Types.propAllConst(prop);
            Debug.fprintln("sei", "elab_exp CALL done");
          then
            (cache,e_1,prop_1,st_1);    */
     /*--------------------------------*/

        /* If fail to elaborate e2 or e3 above check if cond is constant and make non-selected branch
         undefined. NOTE: Dirty hack to make MSL CombiTable models work!!! */
    case (cache,env,Absyn.IFEXP(ifExp = e1,trueBranch = e2,elseBranch = e3),impl,st,doVect,pre) /* Conditional expressions */
      local DAE.Exp e; Boolean b;
      equation
        (cache,e1_1,prop1,st_1,dae1) = elabExp(cache,env, e1, impl, st,doVect,pre);
        true = Types.isParameterOrConstant(Types.propAllConst(prop1));
        (cache,Values.BOOL(b),_) = Ceval.ceval(cache, env, e1_1, impl, NONE, NONE, Ceval.NO_MSG());

        (cache,e,prop,st_2,dae2) = elabIfexpBranch(cache,env,b,e1_1,e2,e3, impl, st_1,doVect,pre);
        /* TODO elseif part */
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,e,prop,st_2,dae);
    case (cache,env,Absyn.CALL(function_ = fn,functionArgs = Absyn.FUNCTIONARGS(args = args,argNames = nargs)),impl,st,doVect,pre)
      local DAE.Exp e;
      equation
        Debug.fprintln("sei", "elab_exp CALL...") "Function calls PA. Only positional arguments are elaborated for now. TODO: Implement elaboration of named arguments." ;
        (cache,e,prop,st_1,dae) = elabCall(cache,env, fn, args, nargs, impl, st,pre);
        c = Types.propAllConst(prop);
        e = Exp.simplify(e);
        Debug.fprintln("sei", "elab_exp CALL done");
      then
        (cache,e,prop,st_1,dae);
    // stefan
    /*case (cache,env,e1 as Absyn.PARTEVALFUNCTION(function_ = fn,functionArgs = Absyn.FUNCTIONARGS(args = args,argNames = nargs)),impl,st,doVect)
      local DAE.Exp e;
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (cache,e,prop,st_1) = elabPartEvalFunction(cache,env,e1,st,impl,doVect);
      then
        (cache,e,prop,st_1);*/
    case (cache,env,e1 as Absyn.PARTEVALFUNCTION(function_ = _),impl,st,doVect,pre)
      local DAE.Exp e;
      equation
        (cache,e,prop,st_1,dae) = elabPartEvalFunction(cache,env,e1,st,impl,doVect,pre);
      then
        (cache,e,prop,st_1,dae);
    case (cache,env,Absyn.TUPLE(expressions = e),impl,st,doVect,pre) /* PR. Get the properties for each expression in the tuple.
    Each expression has its own constflag.
    */
      local
        list<DAE.Exp> e_1;
        list<Absyn.Exp> e;
        list<tuple<Absyn.Ident, Absyn.Exp>> iterators;
      equation
        (cache,e_1,props,dae) = elabTuple(cache,env, e, impl,doVect,pre) "Tuple function calls" ;
        (types,consts) = splitProps(props);
      then
        (cache,DAE.TUPLE(e_1),DAE.PROP_TUPLE((DAE.T_TUPLE(types),NONE),DAE.TUPLE_CONST(consts)),st,dae);
    case (cache,env,Absyn.CALL(function_ = fn,functionArgs = Absyn.FOR_ITER_FARG(exp = exp, iterators=iterators)),impl,st,doVect,pre) /* Array-related expressions Elab reduction expressions, including array() constructor */
      local
        DAE.Exp e;
        Absyn.Exp exp;
      equation
        (cache,e,prop,st_1,dae) = elabCallReduction(cache,env, fn, exp, iterators, impl, st,doVect,pre);
        c = Types.propAllConst(prop);
        e = Exp.simplify(e);
      then
        (cache,e,prop,st_1,dae);
    case (cache,env,Absyn.RANGE(start = start,step = NONE,stop = stop),impl,st,doVect,pre)
      equation
        (cache,start_1,DAE.PROP(start_t,c_start),st_1,dae1) = elabExp(cache,env, start, impl, st,doVect,pre) "Range expressions without step value, e.g. 1:5" ;
        (cache,stop_1,DAE.PROP(stop_t,c_stop),st_2,dae2) = elabExp(cache,env, stop, impl, st_1,doVect,pre);
        (start_2,NONE,stop_2,rt) = deoverloadRange((start_1,start_t), NONE, (stop_1,stop_t));
        const = Types.constAnd(c_start, c_stop);
        (cache,t) = elabRangeType(cache,env, start_2, NONE, stop_2, const, rt, impl,pre);
        exp_2 = DAE.RANGE(rt, start_2, NONE, stop_2);
        prop_1 = DAE.PROP(t, const);
        exp_2 = Exp.simplify(exp_2);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,exp_2,prop_1,st_2,dae);

    case (cache,env,Absyn.RANGE(start = start,step = SOME(step),stop = stop),impl,st,doVect,pre)
      equation
        (cache,start_1,DAE.PROP(start_t,c_start),st_1,dae1) = elabExp(cache,env, start, impl, st,doVect,pre) "Range expressions with step value, e.g. 1:0.5:4" ;
        (cache,step_1,DAE.PROP(step_t,c_step),st_2,dae2) = elabExp(cache,env, step, impl, st_1,doVect,pre);
        (cache,stop_1,DAE.PROP(stop_t,c_stop),st_3,dae3) = elabExp(cache,env, stop, impl, st_2,doVect,pre);
        (start_2,SOME(step_2),stop_2,rt) = deoverloadRange((start_1,start_t), SOME((step_1,step_t)), (stop_1,stop_t));
        c1 = Types.constAnd(c_start, c_step);
        const = Types.constAnd(c1, c_stop);
        (cache,t) = elabRangeType(cache,env, start_2, SOME(step_2), stop_2, const, rt, impl,pre);
        exp_2 = DAE.RANGE(rt, start_2, SOME(step_2), stop_2);
        prop_1 = DAE.PROP(t, const);
        exp_2 = Exp.simplify(exp_2);
        dae = DAEUtil.joinDaeLst({dae1,dae2,dae3});
      then
        (cache,exp_2,prop_1,st_3,dae);

     // Part of the MetaModelica extension. This eliminates elab_array failed failtraces when using the empty list. sjoelund
   case (cache,env,Absyn.ARRAY({}),impl,st,doVect,pre)
     local equation
       true = RTOpts.acceptMetaModelicaGrammar();
       (cache,exp,prop,st,dae) = elabExp(cache,env,Absyn.LIST({}),impl,st,doVect,pre);
     then (cache,exp,prop,st,dae);

    case (cache,env,Absyn.ARRAY(arrayExp = es),impl,st,doVect,pre)
      local DAE.Exp arrexp;
      equation
        (cache,es_1,DAE.PROP(t,const),dae) = elabArray(cache,env, es, impl, st,doVect,pre) "array expressions, e.g. {1,2,3}" ;
        l = listLength(es_1);
        arrtp = (DAE.T_ARRAY(DAE.DIM_INTEGER(l),t),NONE);
        at = Types.elabType(arrtp);
        a = Types.isArray(t);
        a = boolNot(a); // scalar = !array
        arrexp =  DAE.ARRAY(at,a,es_1);
        arrexp = tryToConvertArrayToMatrix(arrexp);
      then
        (cache,arrexp,DAE.PROP(arrtp,const),st,dae);

    case (cache,env,Absyn.MATRIX(matrix = es),impl,st,doVect,pre)
      local list<list<Absyn.Exp>> es;
        Integer d1,d2;
      equation
        (cache,_,tps,_,dae1) = elabExpListList(cache,env, es, impl, st,doVect,pre) "matrix expressions, e.g. {1,0;0,1} with elements of simple type." ;
        tps_1 = Util.listListMap(tps, Types.getPropType);
        tps_2 = Util.listFlatten(tps_1);
        nmax = matrixConstrMaxDim(tps_2);
        havereal = Types.containReal(tps_2);
        (cache,mexp,DAE.PROP(t,c),dim1,dim2,dae2)
        = elabMatrixSemi(cache,env, es, impl, st, havereal, nmax,doVect,pre);
        mexp = Util.if_(havereal,DAE.CAST(DAE.ET_ARRAY(DAE.ET_REAL(),{dim1,dim2}),mexp)
          , mexp);
        mexp=Exp.simplify(mexp); // to propagate cast down to scalar elts
        mexp_1 = elabMatrixToMatrixExp(mexp);
        t_1 = Types.unliftArray(t);
        t_2 = Types.unliftArray(t_1) "All elts promoted to matrix, therefore unlifting" ;
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,mexp_1,DAE.PROP((DAE.T_ARRAY(dim1,(DAE.T_ARRAY(dim2,t_2),NONE)),NONE),c),st,dae);
    case (cache,env,Absyn.CODE(code = c),impl,st,doVect,_)
      local Absyn.CodeNode c;
      equation
        tp = elabCodeType(env, c) "Code expressions" ;
        tp_1 = Types.elabType(tp);
      then
        (cache,DAE.CODE(c,tp_1),DAE.PROP(tp,DAE.C_CONST()),st,DAEUtil.emptyDae);

    case (cache,env,Absyn.VALUEBLOCK(ld,body,res),impl,st,doVect,pre)
      local
        Absyn.ValueblockBody body;
        list<Absyn.ElementItem> ld;
        list<SCode.Element> ld2;
        list<tuple<SCode.Element, Inst.Mod>> ld_mod;

        list<Absyn.AlgorithmItem> b,b2;
        list<DAE.Statement> b_alg;
        DAE.DAElist dae1,dae2;
        list<DAE.Element> dae1_2Elts;
        Absyn.Exp res;
        DAE.Exp res2;
        Env.Env env2;

        DAE.Properties prop;
      equation
        // debug_print("elabExp->VALUEBLOCKALGORITHMS", b);
        env2 = Env.openScope(env, false, SOME(Env.valueBlockScopeName));

        // Tranform declarations such as Real x,y; to Real x; Real y;
        ld2 = SCodeUtil.translateEitemlist(ld,false);

        // Filter out the components (just to be sure)
        ld2 = Inst.componentElts(ld2);

        // Transform the element list into a list of element,NOMOD
        ld_mod = Inst.addNomod(ld2);

        (cache,env2,_,_) = Inst.addComponentsToEnv(cache, env2, InnerOuter.emptyInstHierarchy, DAE.NOMOD(), Prefix.NOPRE(),
          Connect.SETS({},{},{},{}), ClassInf.FUNCTION(Absyn.IDENT("dummieFunc")), ld_mod, {}, {}, {}, impl);

        (cache,env2,_,_,dae1,_,_,_,_) =
          Inst.instElementList(cache,env2,InnerOuter.emptyInstHierarchy, UnitAbsyn.noStore,
                               DAE.NOMOD(), Prefix.NOPRE(), Connect.SETS({},{},{},{}),
                               ClassInf.FUNCTION(Absyn.IDENT("dummieFunc")),
                               ld_mod,{},impl,ConnectionGraph.EMPTY);

        (b,cache) = fromValueblockBodyToAlgs(body, cache, env2,pre);
        //----------------------------------------------------------------------
        // The instantiation of the components may have produced some equations
        (b2,DAE.DAE(dae1_2Elts,_)) = Convert.fromDAEEqsToAbsynAlg(dae1);
        b = listAppend(b2,b);
        //----------------------------------------------------------------------
        (cache,b_alg,_) = Inst.instStatements(cache, env2, 
            InnerOuter.emptyInstHierarchy, 
            Prefix.NOPRE(), SCodeUtil.translateClassdefAlgorithmitems(b), DAE.emptyElementSource, SCode.NON_INITIAL(), true, Inst.neverUnroll);
        // debug_print("before -> res",res);
        (cache,res2,prop as DAE.PROP(tp,_),st,dae3) = elabExp(cache,env2,res,impl,st,doVect,pre);
        // debug_print("after -> res",res2);
        tp_1 = Types.elabType(tp);
        // debug_print("end",tp_1);
        // TODO: PA: I do not know which dae:s to collect here. It should collect all dae:s that comes from
        // elaborating expressions (since they can contain function calls and that is what we want to collect)
      then (cache,DAE.VALUEBLOCK(tp_1,dae1_2Elts,b_alg,res2),prop,st,dae3);

       //-------------------------------------
       // Part of the MetaModelica extension. KS
   case (cache,env,Absyn.ARRAY(es),impl,st,doVect,pre)
     local equation
       true = RTOpts.acceptMetaModelicaGrammar();
       (cache,exp,prop,st,dae) = elabExp(cache,env,Absyn.LIST(es),impl,st,doVect,pre);
     then (cache,exp,prop,st,dae);

   case (cache,env,Absyn.CONS(e1,e2),impl,st,doVect,pre)
     local
       Boolean correctTypes;
       DAE.Type t;
     equation
       (e1 :: _) = MetaUtil.transformArrayNodesToListNodes({e1},{});
       (e2 :: _) = MetaUtil.transformArrayNodesToListNodes({e2},{});

       (cache,e1_1,prop1,st_1,dae1) = elabExp(cache,env, e1, impl, st,doVect,pre);
       (cache,e2_1,DAE.PROP((DAE.T_LIST(t2),_),c2),st_1,dae2) = elabExp(cache,env, e2, impl, st,doVect,pre);

       t1 = Types.getPropType(prop1);
       c1 = Types.propAllConst(prop1);
       t = Types.superType(t1,t2);

       (e1_1,_) = Types.matchType(e1_1, t1, t, true);
       (e2_1,_) = Types.matchType(e2_1, t2, t, true);

       // If the second expression is a DAE.LIST, then we can create a DAE.LIST
       // instead of DAE.CONS
       tp_1 = Types.elabType(t);
       exp = MetaUtil.simplifyListExp(tp_1,e1_1,e2_1);

       c = Types.constAnd(c1,c2);
       prop = DAE.PROP((DAE.T_LIST(t),NONE()),c);
       dae = DAEUtil.joinDaes(dae1,dae2);
     then (cache,exp,prop,st,dae);

       // The Absyn.LIST() node is used for list expressions that are
       // transformed from Absyn.ARRAY()
  case (cache,env,Absyn.LIST({}),impl,st,doVect,_)
    local
      list<DAE.Properties> propList;
      Boolean correctTypes;
      DAE.Type t;
    equation
      t = (DAE.T_LIST((DAE.T_NOTYPE,NONE)),NONE);
      prop = DAE.PROP(t,DAE.C_CONST());
    then (cache,DAE.LIST(DAE.ET_LIST(DAE.ET_OTHER()),{}),prop,st,DAEUtil.emptyDae);

  case (cache,env,Absyn.LIST(es),impl,st,doVect,pre)
    local
      list<DAE.Properties> propList;
      list<DAE.Type> typeList;
      list<DAE.Const> constList;
      Boolean correctTypes;
      DAE.Type t;
    equation
      (cache,es_1,propList,st_2,dae) = elabExpList(cache,env, es, impl, st,doVect,pre);
      typeList = Util.listMap(propList, Types.getPropType);
      constList = Types.getConstList(propList);
      c = Util.listReduce(constList, Types.constAnd) "The case empty list is handled above";
      (es_1, t, _) = Types.listMatchSuperType(es_1, typeList, {}, Types.matchTypeRegular, true);
      prop = DAE.PROP((DAE.T_LIST(t),NONE()),c);
      tp_1 = Types.elabType(t);
    then (cache,DAE.LIST(tp_1,es_1),prop,st_2,dae);
       // ----------------------------------

    case (cache,env,e,_,_,_,pre)
      equation
        ///* FAILTRACE REMOVE
        true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "- Static.elabExp failed: ");

        Debug.traceln(Dump.printExpStr(e));
        Debug.traceln("  Scope: " +& Env.printEnvPathStr(env));
        Debug.traceln("  Prefix: " +& PrefixUtil.printPrefixStr(pre));

        //Debug.traceln("\n env : ");
        //Debug.traceln(Env.printEnvStr(env));
        //Debug.traceln("\n----------------------- FINISHED ENV ------------------------\n");
        //*/
      then
        fail();
  end matchcontinue;
end elabExp;


// Part of MetaModelica extension
public function elabListExp "function: elabListExp
Function that elaborates the MetaModelica list type,
for instance list<Integer>.
This is used by Inst.mo when handling a var := {...} statement
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inExpList;
  input DAE.Properties inProp;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outExp,outProperties,outInteractiveInteractiveSymbolTableOption) :=
  matchcontinue (inCache,inEnv,inExpList,inProp,inBoolean,inInteractiveInteractiveSymbolTableOption,performVectorization,inPrefix)
    local
      Env.Cache cache;
      Env.Env env;
      Boolean impl,doVect;
      Option<Interactive.InteractiveSymbolTable> st;
      DAE.Properties prop;
      DAE.Const c;
      Prefix pre;
    case (cache,env,{},prop,_,st,_,_)
      then (cache,DAE.LIST(DAE.ET_OTHER(),{}),prop,st);
    case (cache,env,expList,prop as DAE.PROP((DAE.T_LIST(t),_),c),impl,st,doVect,pre)
      local
        list<Absyn.Exp> expList;
        list<DAE.Exp> expExpList;
        DAE.Type t;
        list<Boolean> boolList;
        list<DAE.Properties> propList;
        list<DAE.Type> typeList;
        DAE.ExpType t2;
      equation
        (cache,expExpList,propList,st,_) = elabExpList(cache,env,expList,impl,st,doVect,pre);
        typeList = Util.listMap(propList, Types.getPropType);
        (expExpList, t, _) = Types.listMatchSuperType(expExpList, typeList, {}, Types.matchTypeRegular, true);
        t2 = Types.elabType(t);
      then
        (cache,DAE.LIST(t2,expExpList),DAE.PROP((DAE.T_LIST(t),NONE),c),st);
    case (_,_,_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "- elabListExp failed, non-matching args in list constructor?");
      then
        fail();
  end matchcontinue;
end elabListExp;
/* ------------------------------- */

public function fromValueblockBodyToAlgs
  input Absyn.ValueblockBody body;
  input Env.Cache cache;
  input Env.Env env;
  input Prefix inPrefix;
  output list<Absyn.AlgorithmItem> outAlgs;
  output Env.Cache outCache;
algorithm
  (outAlgs,cache) := matchcontinue (body,cache,env,inPrefix)
    local
      list<Absyn.AlgorithmItem> algs1,algs2,eqAlgs,algs;
      list<Absyn.EquationItem> eq1;
      Prefix pre;
    case (Absyn.VALUEBLOCKALGORITHMS(algs1),cache,_,_)
      then (algs1,cache);
    case (Absyn.VALUEBLOCKMATCHCASE(algs1,eq1,algs2),cache,env,pre)
      equation
        (cache,eqAlgs) = fromEquationsToAlgAssignments(eq1,{},cache,env,pre);
        algs = listAppend(eqAlgs,algs2);
        algs = listAppend(algs1,algs);
      then (algs,cache);
  end matchcontinue;
end fromValueblockBodyToAlgs;

protected function fromEquationsToAlgAssignments "function: fromEquationsToAlgAssignments
 Converts equations to algorithm assignments.
 Matchcontinue expressions may contain statements that you won't find
 in a normal equation section. For instance:

 case(...)
 local
 equation
 		(var1,_,MYREC(...)) = func(...);
  	fail();
 then 1;
 "
  input list<Absyn.EquationItem> eqsIn;
  input list<Absyn.AlgorithmItem> accList;
  input Env.Cache cache;
  input Env.Env env;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output list<Absyn.AlgorithmItem> algsOut;
algorithm
  (outCache,algOut) :=
  matchcontinue (eqsIn,accList,cache,env,inPrefix)
    local
      list<Absyn.AlgorithmItem> localAccList;
      Env.Cache localCache;
      Env.Env localEnv;
      Prefix pre;
    case ({},localAccList,localCache,localEnv,_) equation then (localCache,localAccList);
    case (Absyn.EQUATIONITEM(equation_ = first, comment = comment, info = info) :: rest,localAccList,localCache,localEnv,pre)
      local
        Option<Absyn.Comment> comment;
        Absyn.Info info;
        Absyn.Equation first;
        list<Absyn.EquationItem> rest;
        list<Absyn.AlgorithmItem> firstAlg,restAlgs;
      equation
        (localCache,firstAlg) = fromEquationToAlgAssignment(first,comment,info,localCache,localEnv,pre);
        localAccList = listAppend(localAccList,firstAlg);
        (localCache,restAlgs) = fromEquationsToAlgAssignments(rest,localAccList,localCache,localEnv,pre);
      then (localCache,restAlgs);
  end matchcontinue;
end fromEquationsToAlgAssignments;

protected function fromEquationToAlgAssignment "function: fromEquationToAlgAssignment"
  input Absyn.Equation eq;
  input Option<Absyn.Comment> comment;
  input Absyn.Info info;
  input Env.Cache cache;
  input Env.Env env;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output list<Absyn.AlgorithmItem> algStatement;
algorithm
  (outCache,algStatement) := matchcontinue (eq,comment,info,cache,env,inPrefix)
    local
      Env.Cache localCache;
      Env.Env localEnv;
      Prefix pre;

    case (Absyn.EQ_EQUALS(Absyn.BOOL(true),right),comment,info,localCache,_,_)
      local
        Absyn.Exp left,right;
        list<Absyn.AlgorithmItem> algItem1,algItem2;
      equation
        /*
        An equation such as ...

        true = exp;

        ... is transformed into ...

        if (exp != true)
        	throw();
        	*/
        algItem1 = {Absyn.ALGORITHMITEM(Absyn.ALG_THROW(),comment,info)};
        algItem2 = {Absyn.ALGORITHMITEM(Absyn.ALG_IF(Absyn.LUNARY(Absyn.NOT(),right),algItem1,{},{}),comment,info)};
      then (localCache,algItem2);

    case (Absyn.EQ_EQUALS(Absyn.BOOL(false),right),comment,info,localCache,_,_)
      local
        Absyn.Exp left,right;
        list<Absyn.AlgorithmItem> algItem1,algItem2;
      equation
        algItem1 = {Absyn.ALGORITHMITEM(Absyn.ALG_THROW(),comment,info)};
        algItem2 = {Absyn.ALGORITHMITEM(Absyn.ALG_IF(right,algItem1,{},{}),comment,info)};
      then (localCache,algItem2);

      // The syntax n>=0 = true; is also used
    case (Absyn.EQ_EQUALS(left,Absyn.BOOL(true)),comment,info,localCache,_,_)
      local
        Absyn.Exp left,right;
        list<Absyn.AlgorithmItem> algItem1,algItem2;
      equation
        failure(Absyn.CREF(_) = left); // If lhs is a CREF, it should be an assignment
        algItem1 = {Absyn.ALGORITHMITEM(Absyn.ALG_THROW(),comment,info)};
        algItem2 = {Absyn.ALGORITHMITEM(Absyn.ALG_IF(Absyn.LUNARY(Absyn.NOT(),left),algItem1,{},{}),comment,info)};
      then (localCache,algItem2);

    case (Absyn.EQ_EQUALS(left,Absyn.BOOL(false)),comment,info,localCache,_,_)
      local
        Absyn.Exp left,right;
        list<Absyn.AlgorithmItem> algItem1,algItem2;
      equation
        failure(Absyn.CREF(_) = left); // If lhs is a CREF, it should be an assignment
        algItem1 = {Absyn.ALGORITHMITEM(Absyn.ALG_THROW(),comment,info)};
        algItem2 = {Absyn.ALGORITHMITEM(Absyn.ALG_IF(left,algItem1,{},{}),comment,info)};
      then (localCache,algItem2);

    case (Absyn.EQ_NORETCALL(Absyn.CREF_IDENT("fail",_),_),comment,info,localCache,_,_)
      local
        list<Absyn.AlgorithmItem> algItem;
      equation
        algItem = {Absyn.ALGORITHMITEM(Absyn.ALG_THROW(),comment,info)};
      then (localCache,algItem);

    case (Absyn.EQ_NORETCALL(cref,fargs),comment,info,localCache,_,_)
      local
        list<Absyn.AlgorithmItem> algItem;
        Absyn.ComponentRef cref;
        Absyn.FunctionArgs fargs;
      equation
        algItem = {Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(cref,fargs),comment,info)};
      then (localCache,algItem);

      /*
      If we have an equation of the form (exp1,exp2,...,expN) = func(...),
      we may have to transform it into a matchcontinue statement,
      since the expressions should be "matched" against the return
      values of the function */
    case (Absyn.EQ_EQUALS(e,rhsExp),comment,info,localCache,localEnv,pre)
      local
        list<Absyn.Exp> expL,varList;
        Absyn.Exp rhsExp,matchExp,e;
        Absyn.ComponentRef cRef;
        Absyn.Path p;
        list<Absyn.AlgorithmItem> algItem,algItem2;
        SCode.Element cl;
        SCode.Class class_;
        list<Absyn.ElementItem> elemList;
        SCode.Class cl1;
        Absyn.Exp lhsExp;
        DAE.Type ty, resType;
        DAE.Properties prop;
        Prefix pre;
      equation
        // If we have a statement such as: ((a,b)) = func(...); this
        // is not the same as (a,b) = func(...);
        expL = extractListFromTuple(e,0);
        false = onlyCrefExpressions(expL);

      /*
      _ :=
      valueblock(
      var1,...,varN;

      (var1,...,varN) := func(...);
      _ :=
      valueblock(


      )

      */
        // Builtin functions like listGet are polymorphic and need to be elaborated if we want
        // to know what types the components should have.
        // We also need to elaborate crefs in order to determine what type it has.
        (localCache, _, prop, _,_) = elabExp(localCache, env, rhsExp, true, NONE, true,pre);
        ty = Util.if_(isTupleExp(rhsExp),MetaUtil.fixMetaTuple(prop),Types.getPropType(prop));
        (elemList,varList) = extractOutputVarsType({ty},1,{},{});

        matchExp =
        Absyn.MATCHEXP(Absyn.MATCHCONTINUE(),Absyn.TUPLE(varList),{},
          Absyn.CASE(e,{},{},Absyn.TUPLE({}),NONE()) :: {},NONE());

        lhsExp = createLhsExp(varList);

        algItem2 = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(lhsExp,rhsExp),comment,info),
          Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.WILD),matchExp),comment,info)};

        algItem = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.WILD),
          Absyn.VALUEBLOCK(elemList,Absyn.VALUEBLOCKALGORITHMS(algItem2),Absyn.BOOL(true))),comment,info)};

      then (localCache,algItem);
      /*---------------------------------------*/

    case (Absyn.EQ_EQUALS(left,right),comment,info,localCache,_,_)
      local
        Absyn.Exp left,right;
        list<Absyn.AlgorithmItem> algItem;
      equation
        algItem = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(left,right),comment,info)};
      then (localCache,algItem);

    case (Absyn.EQ_FAILURE(Absyn.EQUATIONITEM(eq2,comment2,info2)),comment,info,cache,env,pre)
      local
        Absyn.Equation eq2;
        Option<Absyn.Comment> comment2;
        Absyn.Info info2;
        Absyn.AlgorithmItem brk,try,catchBreak,res,throw;
        list<Absyn.AlgorithmItem> algItem;
      equation
        (cache,algItem) = fromEquationToAlgAssignment(eq2,comment2,info2,cache,env,pre);
        try = Absyn.ALGORITHMITEM(Absyn.ALG_TRY(algItem),comment,info);
        brk = Absyn.ALGORITHMITEM(Absyn.ALG_BREAK(),comment,info);
        throw = Absyn.ALGORITHMITEM(Absyn.ALG_THROW(),comment,info);
        catchBreak = Absyn.ALGORITHMITEM(Absyn.ALG_CATCH({brk}),comment,info);
        res = Absyn.ALGORITHMITEM(Absyn.ALG_WHILE(Absyn.BOOL(true), {try,catchBreak,throw}),comment,info);
      then (cache,{res});
    case (_,_,_,_,_,_)
      equation
        Debug.fprintln("failtrace", "- Static.fromEquationToAlgAssignment failed");
      then fail();
  end matchcontinue;
end fromEquationToAlgAssignment;

protected function extractListFromTuple "function: extractListFromTuple
	author: KS
 Given an Absyn.Exp, this function will extract the list of expressions if the
 expression is a tuple, otherwise a list of length one is created"
  input Absyn.Exp inExp;
  input Integer numOfExps;
  output list<Absyn.Exp> outList;
algorithm
  outList :=
  matchcontinue (inExp,numOfExps)
    case(Absyn.TUPLE(l),1)
      local
        list<Absyn.Exp> l;
      equation
      then {Absyn.TUPLE(l)};
    case(Absyn.TUPLE(l),_)
      local
        list<Absyn.Exp> l;
      equation
      then l;
    case(exp,_)
      local
        Absyn.Exp exp;
      equation
      then {exp};
  end matchcontinue;
end extractListFromTuple;

protected function isTupleExp
  input Absyn.Exp inExp;
  output Boolean b;
algorithm
  b := matchcontinue (inExp)
    case Absyn.TUPLE(_) then true;
    case _ then false;
  end matchcontinue;
end isTupleExp;

protected function onlyCrefExpressions "function: onlyCrefExpressions"
  input list<Absyn.Exp> expList;
  output Boolean boolVal;
algorithm
  boolVal :=
  matchcontinue (expList)
    case ({})
      then true;
    case (Absyn.CREF(Absyn.WILD()) :: _) then false;
    case (Absyn.CREF(_) :: restList)
      local
        list<Absyn.Exp> restList;
        Boolean b;
      equation
        b = onlyCrefExpressions(restList);
      then b;
    case (_) then false;
  end matchcontinue;
end onlyCrefExpressions;

protected function createLhsExp "function: createLhsExp"
  input list<Absyn.Exp> inList;
  output Absyn.Exp outExp;
algorithm
  outExp :=
  matchcontinue (inList)
    case (firstExp :: {}) local Absyn.Exp firstExp; equation then firstExp;
    case (lst) local list<Absyn.Exp> lst; equation then Absyn.TUPLE(lst);
  end matchcontinue;
end createLhsExp;

protected function extractOutputVarsType
  input list<DAE.Type> inList;
  input Integer cnt;
  input list<Absyn.ElementItem> accList1;
  input list<Absyn.Exp> accList2;
  output list<Absyn.ElementItem> outList1;
  output list<Absyn.Exp> outList2;
algorithm
  (outList1,outList2) := matchcontinue (inList,cnt,accList1,accList2)
    local
      list<Absyn.ElementItem> localAccList1;
      list<DAE.Type> rest;
      list<Absyn.Exp> localAccList2;
      Integer localCnt;
    case ({},localCnt,localAccList1,localAccList2)
      then (localAccList1,localAccList2);
    case ({(DAE.T_TUPLE(rest),_)},1,{},{})
      equation
        (localAccList1,localAccList2) = extractOutputVarsType(rest,1,{},{});
      then (localAccList1,localAccList2);
    case (ty :: rest, localCnt,localAccList1,localAccList2)
      local
        DAE.Type ty;
        Absyn.TypeSpec tSpec;
        Absyn.Ident n1,n2;
        Absyn.ElementItem elem1;
        Absyn.Exp elem2;
      equation
        tSpec = MetaUtil.typeConvert(ty);
        n1 = "var";
        n2 = stringAppend(n1,intString(localCnt));
        elem1 = Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
            tSpec,{Absyn.COMPONENTITEM(Absyn.COMPONENT(n2,{},NONE()),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0,Absyn.dummyTimeStamp),NONE()));
        elem2 = Absyn.CREF(Absyn.CREF_IDENT(n2,{}));
        localAccList1 = listAppend(localAccList1,{elem1});
        localAccList2 = listAppend(localAccList2,{elem2});
        (localAccList1,localAccList2) = extractOutputVarsType(rest,localCnt+1,localAccList1,localAccList2);
      then (localAccList1,localAccList2);
    case (_,_,_,_)
      equation
        Debug.fprintln("failtrace", "- Patternm.extractOutputVarsType failed");
      then fail();
  end matchcontinue;
end extractOutputVarsType;

protected function elabMatrixGetDimensions "function: elabMatrixGetDimensions

  Helper function to elab_exp (MATRIX). Calculates the dimensions of the
  matrix by investigating the elaborated expression.
"
  input DAE.Exp inExp;
  output Integer outInteger1;
  output Integer outInteger2;
algorithm
  (outInteger1,outInteger2):=
  matchcontinue (inExp)
    local
      Integer dim1,dim2;
      list<DAE.Exp> lst2,lst;
    case (DAE.ARRAY(array = lst))
      equation
        dim1 = listLength(lst);
        (DAE.ARRAY(array = lst2) :: _) = lst;
        dim2 = listLength(lst2);
      then
        (dim1,dim2);
  end matchcontinue;
end elabMatrixGetDimensions;

protected function elabMatrixToMatrixExp "function: elabMatrixToMatrixExp

  Convert an array expression (which is a matrix or higher dim.) to
  a matrix expression (using MATRIX).
"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp)
    local
      list<list<tuple<DAE.Exp, Boolean>>> mexpl;
      Integer dim;
      DAE.ExpType a,elt_ty;
      Boolean at;
      Option<Integer> dim;
      Integer d1;
      list<DAE.Exp> expl;
      DAE.Exp e;
    case (DAE.ARRAY(ty = a,scalar = at,array = expl))
      equation
        mexpl = elabMatrixToMatrixExp2(expl);
        d1 = listLength(mexpl);
      then
        DAE.MATRIX(a,d1,mexpl);
    case (e) then e;  /* if fails, skip conversion, use generic array expression as is. */
  end matchcontinue;
end elabMatrixToMatrixExp;

protected function elabMatrixToMatrixExp2 "function: elabMatrixToMatrixExp2

  Helper function to elab_matrix_to_matrix_exp
"
  input list<DAE.Exp> inExpExpLst;
  output list<list<tuple<DAE.Exp, Boolean>>> outTplExpExpBooleanLstLst;
algorithm
  (outTplExpExpBooleanLstLst):=
  matchcontinue (inExpExpLst)
    local
      list<tuple<DAE.Exp, Boolean>> expl_1;
      list<list<tuple<DAE.Exp, Boolean>>> es_1;
      DAE.ExpType a;
      Boolean at;
      list<DAE.Exp> expl,es;
    case ({}) then {};
    case ((DAE.ARRAY(ty = a,scalar = at,array = expl) :: es))
      equation
        expl_1 = elabMatrixToMatrixExp3(expl);
        es_1 = elabMatrixToMatrixExp2(es);
      then
        expl_1 :: es_1;
  end matchcontinue;
end elabMatrixToMatrixExp2;

protected function elabMatrixToMatrixExp3
  input list<DAE.Exp> inExpExpLst;
  output list<tuple<DAE.Exp, Boolean>> outTplExpExpBooleanLst;
algorithm
  outTplExpExpBooleanLst:=
  matchcontinue (inExpExpLst)
    local
      DAE.ExpType tp;
      Boolean scalar;
      Ident s;
      list<tuple<DAE.Exp, Boolean>> es_1;
      DAE.Exp e;
      list<DAE.Exp> es;
    case ({}) then {};
    case ((e :: es))
      equation
        tp = Exp.typeof(e);
        scalar = Exp.typeBuiltin(tp);
        s = Util.boolString(scalar);
        es_1 = elabMatrixToMatrixExp3(es);
      then
        ((e,scalar) :: es_1);
  end matchcontinue;
end elabMatrixToMatrixExp3;

protected function matrixConstrMaxDim "function: matrixConstrMaxDim

  Helper function to elab_exp (MATRIX).
  Determines the maximum dimension of the array arguments to the matrix
  constructor as.
  max(2, ndims(A), ndims(B), ndims(C),..) for matrix constructor arguments
  A, B, C, ...
"
  input list<DAE.Type> inTypesTypeLst;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inTypesTypeLst)
    local
      Integer tn,tn2,res;
      tuple<DAE.TType, Option<Absyn.Path>> t;
      list<tuple<DAE.TType, Option<Absyn.Path>>> ts;
    case ({}) then 2;
    case ((t :: ts))
      equation
        tn = Types.ndims(t);
        tn2 = matrixConstrMaxDim(ts);
        res = intMax(tn, tn2);
      then
        res;
    case (_)
      equation
        Debug.fprint("failtrace", "-matrix_constr_max_dim failed\n");
      then
        fail();
  end matchcontinue;
end matrixConstrMaxDim;

protected function elabCallReduction
"function: elabCallReduction
  This function elaborates reduction expressions, that look like function
  calls. For example an array constructor."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef reductionFn;
  input Absyn.Exp reductionExp;
  input Absyn.ForIterators reductionIters;
  input Boolean impl;
  input Option<Interactive.InteractiveSymbolTable> inST;
  input Boolean performVectorization;
  input Prefix inPrefix;
	output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<Interactive.InteractiveSymbolTable> outST;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outST,outDae):=
  matchcontinue (inCache,inEnv,reductionFn,reductionExp,reductionIters,impl,
      inST,performVectorization,inPrefix)
    local
      DAE.Exp iterexp_1,exp_1;
      DAE.Type iterty,expty;
      DAE.Const iterconst,expconst,const;
      list<Env.Frame> env_1,env;
      Option<Interactive.InteractiveSymbolTable> st;
      DAE.Properties prop;
      Absyn.Path fn_1;
      Absyn.ComponentRef fn;
      Absyn.Exp exp,iterexp;
      Ident iter;
      Boolean impl,doVect;
      Env.Cache cache;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;
      Absyn.ForIterators iterators;

    case (cache, env, fn as Absyn.CREF_IDENT("array", {}), exp, iterators, 
        impl, st, doVect,pre)
      equation
        (cache, exp_1, prop, st, dae) = 
          elabCallReduction3(cache, env, exp, iterators, impl, st, doVect, pre);
      then
        (cache, exp_1, prop, st, dae);

		// reduction with an empty vector as range expression.
		case (cache, env, Absyn.CREF_IDENT(reduction_op, {}), _, {(_, SOME(iterexp))}, 
        impl, st, doVect,pre)
			local
				String reduction_op;
			equation
				(cache, DAE.MATRIX(DAE.ET_ARRAY(_,_), 0, {}), _, _, dae) = 
          elabExp(cache, env, iterexp, impl, st, doVect,pre);
				exp_1 = reductionDefaultValue(reduction_op);
			then
				(cache, exp_1, DAE.PROP(DAE.T_REAL_DEFAULT, DAE.C_CONST), st, dae);

    // min, max, sum and product - try and expand the reduction,
    case (cache, env, fn, exp, iterators, impl, st, doVect, pre)
      local
        DAE.ExpType ty;
        list<DAE.Exp> expl;
      equation
        (cache, DAE.ARRAY(array = expl), DAE.PROP(expty, const), st, dae) = 
          elabCallReduction3(cache, env, exp, iterators, impl, st, doVect, pre);
        exp_1 = Util.listReduce(expl, chooseReductionFn(fn)); 
        expty = Types.unliftArray(expty);
      then
        (cache, exp_1, DAE.PROP(expty, const), st, dae);
		
    // min, max, sum and product - expansion failed in previous case, generate
    // reduction call.
		case (cache,env,fn,exp,{(iter,SOME(iterexp))},impl,st,doVect,pre)
			equation
        (cache,iterexp_1,DAE.PROP((DAE.T_ARRAY(arrayType = iterty),_),iterconst),_,dae1)
          = elabExp(cache, env, iterexp, impl, st, doVect,pre);
				env_1 = Env.openScope(env, false, SOME(Env.forIterScopeName));
				env_1 = Env.extendFrameForIterator(env_1, iter, iterty, DAE.UNBOUND(), 
          SCode.CONST(), SOME(iterconst));
        (cache,exp_1,DAE.PROP(expty, expconst),st,dae2) = 
          elabExp(cache, env_1, exp, impl, st, doVect,pre);
				const = Types.constAnd(expconst, iterconst);
				prop = DAE.PROP(expty, const);
				fn_1 = Absyn.crefToPath(fn);
			  dae = DAEUtil.joinDaes(dae1,dae2);
			then
        (cache,DAE.REDUCTION(fn_1,exp_1,iter,iterexp_1),prop,st,dae);

		case (cache,env,fn,exp,iterators,impl,st,doVect,pre)
			equation
				Debug.fprint("failtrace", "Static.elabCallReduction - failed!\n");
			then fail();
	end matchcontinue;
end elabCallReduction;

protected function chooseReductionFn
  input Absyn.ComponentRef fn;
  output ReductionFn reductionFn;
  partial function ReductionFn
    input DAE.Exp lhs;
    input DAE.Exp rhs;
    output DAE.Exp result;
  end ReductionFn;
algorithm
  reductionFn := matchcontinue(fn)
    //case Absyn.CREF_IDENT("max", {}) then reductionFnMax;
    //case Absyn.CREF_IDENT("min", {}) then reductionFnMin;
    case Absyn.CREF_IDENT("sum", {}) then reductionFnSum;
    case Absyn.CREF_IDENT("product", {}) then reductionFnProduct;
  end matchcontinue;
end chooseReductionFn;

protected function reductionFnSum
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  output DAE.Exp result;

  DAE.ExpType ty;
algorithm
  ty := Exp.typeof(lhs);
  result := DAE.BINARY(lhs, DAE.ADD(ty), rhs);
end reductionFnSum;

protected function reductionFnProduct
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  output DAE.Exp result;

  DAE.ExpType ty;
algorithm
  ty := Exp.typeof(lhs);
  result := DAE.BINARY(lhs, DAE.MUL(ty), rhs);
end reductionFnProduct;

protected function updateIteratorConst "updates the const of for iterators from VAR to its elaborated constness, currently at most PARAM, since 
cevalIfConstant will mess up things for constant expressions.
TODO: When cevalIfConstant is removed in future this can also be fixed.
"
  input Env.Env env;  
  input list<Ident> iter_names;
  input list<DAE.Const> iter_const;
  output Env.Env outEnv;
algorithm
  outEnv := matchcontinue(env,iter_names,iter_const)
  local Ident name; DAE.Const c;
    DAE.Type ty; DAE.Binding bind;
    Option<DAE.Const> forIterConst;
        
    case(env,{},{}) then env;
    case(env,name::iter_names,c::iter_const) equation
      (_,_,ty,bind,forIterConst,_,_,_,_) = Lookup.lookupVarLocal(Env.emptyCache(),env,DAE.CREF_IDENT(name,DAE.ET_OTHER(),{}));
      env = Env.extendFrameForIterator(env,name,ty,bind,constToVariability(c),forIterConst);
      //print("updating "+&name+&" to const:"+&DAEUtil.constStr(c)+&"\n");
      env = updateIteratorConst(env,iter_names,iter_const);
    then env;
  end matchcontinue;
end updateIteratorConst;

protected function reductionDefaultValue
	input String reductionOp;
	output DAE.Exp defaultValue;
algorithm
	defaultValue := matchcontinue(reductionOp)
		case "min" then DAE.RCONST(1e60);
		case "max" then DAE.RCONST(-1e60);
		case "sum" then DAE.RCONST(0.0);
		case "product" then DAE.RCONST(1.0);
	end matchcontinue;
end reductionDefaultValue;

protected function elabArrayIterators
	"Elaborates array constructors such as 'array(i for i in 1:5)'"
	input Env.Cache cache;
	input Env.Env env;
	input Absyn.ForIterators iterators;
	input Boolean implicitInstantiation;
	input Option<Interactive.InteractiveSymbolTable> st;
	input Boolean performVectorization;
	input Prefix inPrefix;
	output Env.Cache newCache;
	output Env.Env newEnv;
	output list<DAE.Const> consts;
	output list<list<Values.Value>> iteratorValues;
	output list<Ident> iteratorNames;
	output DAE.Type arrayType;
	output DAE.DAElist outDae "contain functions";
algorithm
	(newCache, newEnv, consts, iteratorValues, iteratorNames, arrayDim,outDae) :=
	matchcontinue(cache, env, iterators, implicitInstantiation, st, performVectorization,inPrefix)
		local
			Ident iter_name;
			list<Ident> iter_names;
			DAE.Exp iter_exp;
			Absyn.ForIterators rest_iters;
			Env.Cache new_cache;
			Env.Env new_env;
			list<DAE.Const> iters_const;
			DAE.Const iter_const;
      DAE.Dimension array_dim;
			DAE.Type array_type, iter_type;
			list<Values.Value> iter_values;
			list<list<Values.Value>> iter_values_list;
			DAE.DAElist dae,dae1,dae2;
			SCode.Variability variability;
			Prefix pre;
			
		case (_, _, {}, _, _, _,_)
			equation
				new_env = Env.openScope(env, false, SOME(Env.forIterScopeName));
				// Return the type T_NOTYPE as a placeholder. constructArrayType is
				// later used by cevalCallReduction to replace it with the correct type.
			then (cache, new_env, {}, {}, {}, (DAE.T_NOTYPE(), NONE),DAEUtil.emptyDae);
		case (_, _, (iter_name, SOME(iter_exp)) :: rest_iters, _, _, _,pre)
			equation
				(new_cache, new_env, iters_const, iter_values_list, iter_names, array_type,dae1)
					= elabArrayIterators(cache, env, rest_iters, implicitInstantiation, st, performVectorization,pre);
				// Elaborate the iterator expression to get the iterators type and dimension of the generated array.
				(new_cache, iter_exp, DAE.PROP((DAE.T_ARRAY(arrayDim = array_dim, arrayType = iter_type), _), constFlag = iter_const), _,dae2)
					= elabExp(cache, env, iter_exp, implicitInstantiation, st, performVectorization,pre);
				// Use ceval to get a list of values generated by the iterator expression.
				(new_cache, Values.ARRAY(valueLst = iter_values), _)
					= Ceval.ceval(new_cache, env, iter_exp, implicitInstantiation, NONE, NONE, Ceval.MSG());
				true = Types.isParameterOrConstant(iter_const);
				// Add the iterator to the environment so that the array constructor
				// expression can be elaborated later.
				new_env = Env.extendFrameForIterator(new_env, iter_name, iter_type, DAE.UNBOUND(), SCode.VAR(), SOME(iter_const));
				dae = DAEUtil.joinDaes(dae1,dae2);
			then (new_cache, new_env, iter_const::iters_const, iter_values :: iter_values_list, iter_name :: iter_names, (DAE.T_ARRAY(array_dim, array_type), NONE),dae);
	end matchcontinue;
end elabArrayIterators;

protected function constToVariability "translates an DAE.Const to a SCode.Variability"
  input DAE.Const const;
  output SCode.Variability variability;
algorithm
  variability := matchcontinue(const)
    case(DAE.C_VAR())  then SCode.VAR();
    case(DAE.C_PARAM()) then SCode.PARAM();
    case(DAE.C_CONST()) then SCode.CONST();
  end matchcontinue;
end constToVariability;
  
protected function expandArray
	"Symbolically expands an array with the help of elabCallReduction2."
	input DAE.Exp expr;
	input list<list<Values.Value>> valLists;
	input list<Ident> iteratorNames;
	input Boolean isArray;
	input DAE.ExpType arrayType;
	output DAE.Exp expandedExp;
algorithm
	expandedExp := matchcontinue(expr, valLists, iteratorNames, isArray, arrayType)
		local
			list<Values.Value> values;
			list<list<Values.Value>> rest_values;
			Ident iterator_name;
			list<Ident> rest_iterators;
			list<DAE.Exp> new_expl, expanded_expl;
		case (_, {}, {}, _, _) then expr;
		case (_, values :: rest_values, iterator_name :: rest_iterators, _, _)
			equation
				expanded_expl = elabCallReduction2(expr, values, iterator_name);
				new_expl = Util.listMap4(expanded_expl, expandArray, rest_values, rest_iterators, isArray, arrayType);
			then DAE.ARRAY(arrayType, isArray, new_expl);
		end matchcontinue;
end expandArray;

protected function elabCallReduction2 "help function to elabCallReduction. symbolically expands arrays"
  input DAE.Exp e;
  input list<Values.Value> valLst;
  input Ident id;
  output list<DAE.Exp> expl;
algorithm
	expl := matchcontinue(e, valLst, id)
		local
			Integer i;
			Real r;
			DAE.Exp e1;
			Values.Value v;
    case(e, {}, id) then {};
    case(e, Values.INTEGER(i)::valLst, id)
			equation
				(e1,_) = Exp.replaceExp(e,DAE.CREF(DAE.CREF_IDENT(id,DAE.ET_OTHER(),{}),DAE.ET_OTHER()),DAE.ICONST(i));
				expl = elabCallReduction2(e, valLst, id);
			then e1::expl;
		case(e, Values.REAL(r) :: valLst, id)
			equation
				(e1,_) = Exp.replaceExp(e, DAE.CREF(DAE.CREF_IDENT(id, DAE.ET_OTHER(), {}), DAE.ET_OTHER()), DAE.RCONST(r));
				expl = elabCallReduction2(e, valLst, id);
			then e1 :: expl;
		case(e, (v as Values.ENUM_LITERAL(index = _)) :: valLst, id)
		  equation
		    e1 = ValuesUtil.valueExp(v);
		    (e1,_) = Exp.replaceExp(e,DAE.CREF(DAE.CREF_IDENT(id,DAE.ET_OTHER(),{}),DAE.ET_OTHER()),e1);
		    expl = elabCallReduction2(e, valLst, id);
		  then e1 :: expl; 
  end matchcontinue;
end elabCallReduction2;

protected function elabCallReduction3
  "Helper function to elabCallReduction. Expands reduction calls."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Exp reductionExp;
  input Absyn.ForIterators reductionIters;
  input Boolean impl;
  input Option<Interactive.InteractiveSymbolTable> inST;
  input Boolean doVect;
  input Prefix prefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<Interactive.InteractiveSymbolTable> outST;
  output DAE.DAElist outDae;

  Env.Cache cache;
  Env.Env env;
  DAE.Const iterconst, exp_const, const;
  list<DAE.Const> iterconsts;
  list<list<Values.Value>> vals;
  list<Ident> iter_names;
  DAE.Type array_type, exp_type, ty;
  DAE.ExpType etp;
  DAE.DAElist dae1, dae2;
  DAE.Exp exp;
  Boolean b;
  Option<Interactive.InteractiveSymbolTable> st;
algorithm
  (cache, env, iterconsts, vals, iter_names, array_type, dae1) :=
    elabArrayIterators(inCache, inEnv, reductionIters, impl, inST, doVect, prefix);
  iterconst := Util.listReduce(iterconsts, Types.constAnd);
  env := updateIteratorConst(env, iter_names, iterconsts);
  (cache, exp, DAE.PROP(exp_type, exp_const), st, dae2) :=
    elabExp(cache, env, reductionExp, impl, inST, doVect, prefix);
  b := not Types.isArray(exp_type);
  ty := constructArrayType(array_type, exp_type);
  etp := Types.elabType(ty);
  const := Types.constAnd(exp_const, iterconst);
  outCache := cache;
  outExp := expandArray(exp, vals, iter_names, b, etp);
  outProperties := DAE.PROP(ty, const);
  outST := st;
  outDae := DAEUtil.joinDaes(dae1, dae2);
end elabCallReduction3;

protected function constructArrayType
	"Helper function for elabCallReduction. Combines the type of the expression in
		an array constructor with the type of the generated array by replacing the
		placeholder T_NOTYPE in arrayType with expType. Example:
			r[i] for i in 1:5 =>
				arrayType = type(i in 1:5) = (T_ARRAY(DIM(5), T_NOTYPE), NONE)
				expType = type(r[i]) = (T_REAL, NONE)
			=> resType = (T_ARRAY(DIM(5), (T_REAL, NONE)), NONE)"
	input DAE.Type arrayType;
	input DAE.Type expType;
	output DAE.Type resType;
algorithm
	resType := matchcontinue(arrayType, expType)
		local
			DAE.Type ty;
      DAE.Dimension dim;
			Option<Absyn.Path> path;
		case ((DAE.T_NOTYPE(), _), _) then expType;
		case ((DAE.T_ARRAY(dim, ty), path), _)
			equation
				ty = constructArrayType(ty, expType);
			then
				((DAE.T_ARRAY(dim, ty), path));
	end matchcontinue;
end constructArrayType;

protected function replaceOperatorWithFcall "function: replaceOperatorWithFcall

  Replaces a userdefined operator expression with a corresponding function
  call expression. Other expressions just passes through.
"
  input DAE.Exp inExp;
  input DAE.Const inConst;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp,inConst)
    local
      DAE.Exp e1,e2,e;
      Absyn.Path funcname;
      DAE.Const c;
    case (DAE.BINARY(exp1 = e1,operator = DAE.USERDEFINED(fqName = funcname),exp2 = e2),c) then DAE.CALL(funcname,{e1,e2},false,false,DAE.ET_OTHER(),DAE.NO_INLINE);
    case (DAE.UNARY(operator = DAE.USERDEFINED(fqName = funcname),exp = e1),c) then DAE.CALL(funcname,{e1},false,false,DAE.ET_OTHER(),DAE.NO_INLINE);
    case (DAE.LBINARY(exp1 = e1,operator = DAE.USERDEFINED(fqName = funcname),exp2 = e2),c) then DAE.CALL(funcname,{e1,e2},false,false,DAE.ET_OTHER(),DAE.NO_INLINE);
    case (DAE.LUNARY(operator = DAE.USERDEFINED(fqName = funcname),exp = e1),c) then DAE.CALL(funcname,{e1},false,false,DAE.ET_OTHER(),DAE.NO_INLINE);
    case (DAE.RELATION(exp1 = e1,operator = DAE.USERDEFINED(fqName = funcname),exp2 = e2),c) then DAE.CALL(funcname,{e1,e2},false,false,DAE.ET_OTHER(),DAE.NO_INLINE);
    case (e,_) then e;
  end matchcontinue;
end replaceOperatorWithFcall;

protected function elabCodeType "function: elabCodeType

  This function will construct the correct type for the given Code
  expression. The types are built-in classes of different types. E.g.
  the class TypeName is the type
  of Code expressions corresponding to a type name Code expression.
"
  input Env.Env inEnv;
  input Absyn.CodeNode inCode;
  output DAE.Type outType;
algorithm
  outType:=
  matchcontinue (inEnv,inCode)
    local list<Env.Frame> env;
    case (env,Absyn.C_TYPENAME(path = _)) then ((DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("TypeName")),{},NONE,NONE),NONE));
    case (env,Absyn.C_VARIABLENAME(componentRef = _)) then ((DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("VariableName")),{},NONE,NONE),
          NONE));
    case (env,Absyn.C_EQUATIONSECTION(boolean = _)) then ((
          DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("EquationSection")),{},NONE,NONE),NONE));
    case (env,Absyn.C_ALGORITHMSECTION(boolean = _)) then ((
          DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("AlgorithmSection")),{},NONE,NONE),NONE));
    case (env,Absyn.C_ELEMENT(element = _)) then ((DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("Element")),{},NONE,NONE),NONE));
    case (env,Absyn.C_EXPRESSION(exp = _)) then ((DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("Expression")),{},NONE,NONE),
          NONE));
    case (env,Absyn.C_MODIFICATION(modification = _)) then ((DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("Modification")),{},NONE,NONE),
          NONE));
  end matchcontinue;
end elabCodeType;

public function elabGraphicsExp
"function elabGraphicsExp
  This function is specially designed for elaboration of expressions when
  investigating Modelica 2.0 graphical annotations.
  These have an array of records representing graphical objects. These
  elements can have different types, therefore elab_graphic_exp will allow
  arrays with elements of varying types. "
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Exp inExp;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inPrefix)
    local
      Integer x,l,nmax;
      DAE.Dimension dim1,dim2;
      Boolean impl,a,havereal;
      Ident fnstr;
      DAE.Exp exp,e1_1,e2_1,e1_2,e2_2,e_1,e_2,e3_1,start_1,stop_1,start_2,stop_2,step_1,step_2,mexp,mexp_1;
      DAE.Properties prop,prop1,prop2,prop3;
      list<Env.Frame> env;
      Absyn.ComponentRef cr,fn;
      tuple<DAE.TType, Option<Absyn.Path>> t1,t2,rtype,t,start_t,stop_t,step_t,t_1,t_2;
      DAE.Const c1,c2,c,c_start,c_stop,const,c_step;
      list<tuple<DAE.Operator, list<tuple<DAE.TType, Option<Absyn.Path>>>, tuple<DAE.TType, Option<Absyn.Path>>>> ops;
      DAE.Operator op_1;
      Absyn.Exp e,e1,e2,e,e3,start,stop,step;
      Absyn.Operator op;
      list<Absyn.Exp> args,rest,es;
      list<Absyn.NamedArg> nargs;
      list<DAE.Exp> es_1;
      list<DAE.Properties> props;
      list<tuple<DAE.TType, Option<Absyn.Path>>> types,tps_2;
      list<DAE.TupleConst> consts;
      DAE.ExpType rt,at;
      list<list<DAE.Properties>> tps;
      list<list<tuple<DAE.TType, Option<Absyn.Path>>>> tps_1;
      Env.Cache cache;
      Prefix pre;
    case (cache,_,Absyn.INTEGER(value = x),impl,_) then (cache,DAE.ICONST(x),DAE.PROP(DAE.T_INTEGER_DEFAULT,DAE.C_CONST()));  /* impl */
    case (cache,_,Absyn.REAL(value = x),impl,_)
      local Real x;
      then
        (cache,DAE.RCONST(x),DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_CONST()));
    case (cache,_,Absyn.STRING(value = x),impl,_)
      local Ident x;
      then
        (cache,DAE.SCONST(x),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_CONST()));
    case (cache,_,Absyn.BOOL(value = x),impl,_)
      local Boolean x;
      then
        (cache,DAE.BCONST(x),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_CONST()));
    case (cache,env,Absyn.CREF(componentRef = cr),impl,pre)
      equation
        Debug.fprint("tcvt","before Static.elabCref in elabGraphicsExp\n");
        (cache,exp,prop,_,_) = elabCref(cache,env, cr, impl,true /*perform vectorization*/,pre);
        Debug.fprint("tcvt","after Static.elabCref in elabGraphicsExp\n");
      then
        (cache,exp,prop);
    case (cache,env,(exp as Absyn.BINARY(exp1 = e1,op = op,exp2 = e2)),impl,pre) /* Binary and unary operations */
      local Absyn.Exp exp;
      equation
        (cache,e1_1,DAE.PROP(t1,c1)) = elabGraphicsExp(cache,env, e1, impl,pre);
        (cache,e2_1,DAE.PROP(t2,c2)) = elabGraphicsExp(cache,env, e2, impl,pre);
        c = Types.constAnd(c1, c2);
        (cache,ops) = operators(cache,op, env, t1, t2);
        (op_1,{e1_2,e2_2},rtype) = deoverload(ops, {(e1_1,t1),(e2_1,t2)}, exp,pre);
      then
        (cache,DAE.BINARY(e1_2,op_1,e2_2),DAE.PROP(rtype,c));
    case (cache,env,(exp as Absyn.UNARY(op = op,exp = e)),impl,pre)
      local Absyn.Exp exp;
      equation
        (cache,e_1,DAE.PROP(t,c)) = elabGraphicsExp(cache,env, e, impl,pre);
        (cache,ops) = operators(cache,op, env, t, (DAE.T_NOTYPE(),NONE));
        (op_1,{e_2},rtype) = deoverload(ops, {(e_1,t)}, exp,pre);
      then
        (cache,DAE.UNARY(op_1,e_2),DAE.PROP(rtype,c));
    case (cache,env,(exp as Absyn.LBINARY(exp1 = e1,op = op,exp2 = e2)),impl,pre)
      local Absyn.Exp exp;
      equation
        (cache,e1_1,DAE.PROP(t1,c1)) = elabGraphicsExp(cache,env, e1, impl,pre) "Logical binary expressions" ;
        (cache,e2_1,DAE.PROP(t2,c2)) = elabGraphicsExp(cache,env, e2, impl,pre);
        c = Types.constAnd(c1, c2);
        (cache,ops) = operators(cache,op, env, t1, t2);
        (op_1,{e1_2,e2_2},rtype) = deoverload(ops, {(e1_1,t1),(e2_1,t2)}, exp,pre);
      then
        (cache,DAE.LBINARY(e1_2,op_1,e2_2),DAE.PROP(rtype,c));
    case (cache,env,(exp as Absyn.LUNARY(op = op,exp = e)),impl,pre)
      local Absyn.Exp exp;
      equation
        (cache,e_1,DAE.PROP(t,c)) = elabGraphicsExp(cache,env, e, impl,pre) "Logical unary expressions" ;
        (cache,ops) = operators(cache,op, env, t, (DAE.T_NOTYPE(),NONE));
        (op_1,{e_2},rtype) = deoverload(ops, {(e_1,t)}, exp,pre);
      then
        (cache,DAE.LUNARY(op_1,e_2),DAE.PROP(rtype,c));
    case (cache,env,(exp as Absyn.RELATION(exp1 = e1,op = op,exp2 = e2)),impl,pre)
      local Absyn.Exp exp;
      equation
        (cache,e1_1,DAE.PROP(t1,c1)) = elabGraphicsExp(cache,env, e1, impl,pre) "Relation expressions" ;
        (cache,e2_1,DAE.PROP(t2,c2)) = elabGraphicsExp(cache,env, e2, impl,pre);
        c = Types.constAnd(c1, c2);
        (cache,ops) = operators(cache,op, env, t1, t2);
        (op_1,{e1_2,e2_2},rtype) = deoverload(ops, {(e1_1,t1),(e2_1,t2)}, exp,pre);
      then
        (cache,DAE.RELATION(e1_2,op_1,e2_2),DAE.PROP(rtype,c));
    case (cache,env,e as Absyn.IFEXP(ifExp = _),impl,pre) /* Conditional expressions */
      equation
        Absyn.IFEXP(ifExp = e1,trueBranch = e2,elseBranch = e3) = Absyn.canonIfExp(e);
        (cache,e1_1,prop1) = elabGraphicsExp(cache,env, e1, impl,pre);
        (cache,e2_1,prop2) = elabGraphicsExp(cache,env, e2, impl,pre);
        (cache,e3_1,prop3) = elabGraphicsExp(cache,env, e3, impl,pre);
        (cache,e_1,prop) = elabIfexp(cache,env, e1_1, prop1, e2_1, prop2, e3_1, prop3, impl, NONE,pre);
      then
        (cache,e_1,prop);
    case (cache,env,Absyn.CALL(function_ = fn,functionArgs = Absyn.FUNCTIONARGS(args = args,argNames = nargs)),impl,pre) /* Function calls */
      local DAE.Exp e;
      equation
        fnstr = Dump.printComponentRefStr(fn);
        (cache,e,prop,_,_) = elabCall(cache,env, fn, args, nargs, true, NONE,pre);
      then
        (cache,e,prop);
    case (cache,env,Absyn.TUPLE(expressions = (e as (e1 :: rest))),impl,pre) /* PR. Get the properties for each expression in the tuple.
	 Each expression has its own constflag.
	 !!The output from functions does just have one const flag.
	 Fix this!!
	 */
      local
        list<DAE.Exp> e_1;
        list<Absyn.Exp> e;
      equation
        (cache,e_1,props,_) = elabTuple(cache,env, e, impl,false,pre);
        (types,consts) = splitProps(props);
      then
        (cache,DAE.TUPLE(e_1),DAE.PROP_TUPLE((DAE.T_TUPLE(types),NONE),DAE.TUPLE_CONST(consts)));
    case (cache,env,Absyn.RANGE(start = start,step = NONE,stop = stop),impl,pre) /* Array-related expressions */
      equation
        (cache,start_1,DAE.PROP(start_t,c_start)) = elabGraphicsExp(cache,env, start, impl,pre);
        (cache,stop_1,DAE.PROP(stop_t,c_stop)) = elabGraphicsExp(cache,env, stop, impl,pre);
        (start_2,NONE,stop_2,rt) = deoverloadRange((start_1,start_t), NONE, (stop_1,stop_t));
        const = Types.constAnd(c_start, c_stop);
        (cache,t) = elabRangeType(cache,env, start_2, NONE, stop_2, const, rt, impl,pre);
      then
        (cache,DAE.RANGE(rt,start_1,NONE,stop_1),DAE.PROP(t,const));
    case (cache,env,Absyn.RANGE(start = start,step = SOME(step),stop = stop),impl,pre)
      equation
        (cache,start_1,DAE.PROP(start_t,c_start)) = elabGraphicsExp(cache,env, start, impl,pre) "Debug.fprintln(\"setr\", \"elab_graphics_exp_range2\") &" ;
        (cache,step_1,DAE.PROP(step_t,c_step)) = elabGraphicsExp(cache,env, step, impl,pre);
        (cache,stop_1,DAE.PROP(stop_t,c_stop)) = elabGraphicsExp(cache,env, stop, impl,pre);
        (start_2,SOME(step_2),stop_2,rt) = deoverloadRange((start_1,start_t), SOME((step_1,step_t)), (stop_1,stop_t));
        c1 = Types.constAnd(c_start, c_step);
        const = Types.constAnd(c1, c_stop);
        (cache,t) = elabRangeType(cache,env, start_2, SOME(step_2), stop_2, const, rt, impl,pre);
      then
        (cache,DAE.RANGE(rt,start_2,SOME(step_2),stop_2),DAE.PROP(t,const));
    case (cache,env,Absyn.ARRAY(arrayExp = es),impl,pre)
      equation
        (cache,es_1,DAE.PROP(t,const)) = elabGraphicsArray(cache,env, es, impl,pre);
        l = listLength(es_1);
        at = Types.elabType(t);
        a = Types.isArray(t);
      then
        (cache,DAE.ARRAY(at,a,es_1),DAE.PROP((DAE.T_ARRAY(DAE.DIM_INTEGER(l),t),NONE),const));
    case (cache,env,Absyn.MATRIX(matrix = es),impl,pre)
      local list<list<Absyn.Exp>> es;
      equation
        (cache,_,tps,_,_) = elabExpListList(cache,env, es, impl, NONE,true,pre);
        tps_1 = Util.listListMap(tps, Types.getPropType);
        tps_2 = Util.listFlatten(tps_1);
        nmax = matrixConstrMaxDim(tps_2);
        havereal = Types.containReal(tps_2);
        (cache,mexp,DAE.PROP(t,c),dim1,dim2,_) = elabMatrixSemi(cache,env, es, impl, NONE, havereal, nmax,true,pre);
        at = Types.elabType(t);
        mexp_1 = elabMatrixToMatrixExp(mexp);
        t_1 = Types.unliftArray(t);
        t_2 = Types.unliftArray(t_1);
      then
        (cache,mexp,DAE.PROP((DAE.T_ARRAY(dim1,(DAE.T_ARRAY(dim2,t_2),NONE)),NONE),c));
    case (cache,_,e,impl,pre)
      local Ident es,ps;
      equation
        Print.printErrorBuf("- elab_graphics_exp failed: ");
        ps = PrefixUtil.printPrefixStr2(pre);
        es = Dump.printExpStr(e);
        Print.printErrorBuf(ps+&es);
        Print.printErrorBuf("\n");
      then
        fail();
  end matchcontinue;
end elabGraphicsExp;

protected function deoverloadRange "function: deoverloadRange

  Does deoverloading of range expressions. They can be both Integer ranges
  and Real ranges. This function determines which one to use.
"
  input tuple<DAE.Exp, DAE.Type> inTplExpExpTypesType1;
  input Option<tuple<DAE.Exp, DAE.Type>> inTplExpExpTypesTypeOption2;
  input tuple<DAE.Exp, DAE.Type> inTplExpExpTypesType3;
  output DAE.Exp outExp1;
  output Option<DAE.Exp> outExpExpOption2;
  output DAE.Exp outExp3;
  output DAE.ExpType outType4;
algorithm
  (outExp1,outExpExpOption2,outExp3,outType4):=
  matchcontinue (inTplExpExpTypesType1,inTplExpExpTypesTypeOption2,inTplExpExpTypesType3)
    local
      DAE.Exp e1,e3,e2,e1_1,e3_1,e2_1;
      tuple<DAE.TType, Option<Absyn.Path>> t1,t3,t2;
      DAE.ExpType et;
      list<String> ns,ne;
    case ((e1,(DAE.T_INTEGER(varLstInt = _),_)),NONE,(e3,(DAE.T_INTEGER(varLstInt = _),_))) then (e1,NONE,e3,DAE.ET_INT());
    case ((e1,(DAE.T_INTEGER(varLstInt = _),_)),SOME((e2,(DAE.T_INTEGER(_),_))),(e3,(DAE.T_INTEGER(varLstInt = _),_))) then (e1,SOME(e2),e3,DAE.ET_INT());
    // enumeration has no step value
    case ((e1,t1 as (DAE.T_ENUMERATION(names = ns),_)),NONE,(e3,(DAE.T_ENUMERATION(names = ne),_)))
      equation
        // check if enumtyp start and end are equal
        true = Util.isListEqual(ns,ne,true);
        // convert vars
          et = Types.elabType(t1);
         then (e1,NONE,e3,et);
    case ((e1,t1),NONE,(e3,t3))
      equation
        ({e1_1,e3_1},_) = elabArglist({DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},
          {(e1,t1),(e3,t3)});
      then
        (e1_1,NONE,e3_1,DAE.ET_REAL());
    case ((e1,t1),SOME((e2,t2)),(e3,t3))
      equation
        ({e1_1,e2_1,e3_1},_) = elabArglist(
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT,
          DAE.T_REAL_DEFAULT}, {(e1,t1),(e2,t2),(e3,t3)});
      then
        (e1_1,SOME(e2_1),e3_1,DAE.ET_REAL());
  end matchcontinue;
end deoverloadRange;

protected function elabRangeType "function: elabRangeType

  Helper function to elab_range. Calculates the dimension of the
  range expression.
"
	input Env.Cache inCache;
  input Env.Env inEnv1;
  input DAE.Exp inExp2;
  input Option<DAE.Exp> inExpExpOption3;
  input DAE.Exp inExp4;
  input DAE.Const inConst5;
  input DAE.ExpType inType6;
  input Boolean inBoolean7;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Type outType;
algorithm
  (outCache,outType) :=
  matchcontinue (inCache,inEnv1,inExp2,inExpExpOption3,inExp4,inConst5,inType6,inBoolean7,inPrefix)
    local
      Integer startv,stopv,n,n_1,stepv,n_2,n_3,n_4;
      list<Env.Frame> env;
      DAE.Exp start,stop,step;
      DAE.Const const;
      Boolean impl;
      Ident s1,s2,s3,s4,s5,s6,str,sp;
      Option<Ident> s2opt;
      DAE.ExpType expty;
      Env.Cache cache;
      Prefix pre;
    case (cache,env,start,NONE,stop,const,_,impl,pre) /* impl as false */
      equation
        (cache,Values.INTEGER(startv),_) = Ceval.ceval(cache,env, start, impl, NONE, NONE, Ceval.MSG());
        (cache,Values.INTEGER(stopv),_) = Ceval.ceval(cache,env, stop, impl, NONE, NONE, Ceval.MSG());
        n = stopv - startv;
        n_1 = n + 1;
      then
        (cache,(
          DAE.T_ARRAY(DAE.DIM_INTEGER(n_1),DAE.T_INTEGER_DEFAULT),NONE));
    case (cache,env,start,SOME(step),stop,const,_,impl,_) /* as false */
      equation
        (cache,Values.INTEGER(startv),_) = Ceval.ceval(cache,env, start, impl, NONE, NONE, Ceval.MSG());
        (cache,Values.INTEGER(stepv),_) = Ceval.ceval(cache,env, step, impl, NONE, NONE, Ceval.MSG());
        (cache,Values.INTEGER(stopv),_) = Ceval.ceval(cache,env, stop, impl, NONE, NONE, Ceval.MSG());
        n = stopv - startv;
        n_1 = n/stepv;
        n_2 = n_1 + 1;
      then
        (cache,(
          DAE.T_ARRAY(DAE.DIM_INTEGER(n_2),DAE.T_INTEGER_DEFAULT),NONE));
    /* enumeration has no step value */
    case (cache,env,start,NONE,stop,const,_,impl,_) /* impl as false */
      local list<String> names; Absyn.Path p;
      equation
        (cache,Values.ENUM_LITERAL(name = p, index = startv),_) = Ceval.ceval(cache,env, start, impl, NONE, NONE, Ceval.MSG());
        (cache,Values.ENUM_LITERAL(index = stopv),_) = Ceval.ceval(cache,env, stop, impl, NONE, NONE, Ceval.MSG());
        n = stopv - startv;
        n_1 = n + 1;
        p = Absyn.pathPrefix(p);
      then
        (cache,(
          DAE.T_ARRAY(DAE.DIM_INTEGER(n_1),(DAE.T_ENUMERATION(NONE(),p,{},{}),NONE)),NONE));
    case (cache,env,start,NONE,stop,const,_,impl,_) /* as false */
      local Real startv,stopv,n,n_2;
      equation
        (cache,Values.REAL(startv),_) = Ceval.ceval(cache,env, start, impl, NONE, NONE, Ceval.MSG());
        (cache,Values.REAL(stopv),_) = Ceval.ceval(cache,env, stop, impl, NONE, NONE, Ceval.MSG());
        n = stopv -. startv;
        n_2 = realFloor(n);
        n_3 = realInt(n_2);
        n_1 = n_3 + 1;
      then
        (cache,(
          DAE.T_ARRAY(DAE.DIM_INTEGER(n_1),DAE.T_REAL_DEFAULT),NONE));
    case (cache,env,start,SOME(step),stop,const,_,impl,_) /* as false */
      local Real startv,stepv,stopv,n,n_1,n_3;
      equation
        (cache,Values.REAL(startv),_) = Ceval.ceval(cache,env, start, impl, NONE, NONE, Ceval.MSG());
        (cache,Values.REAL(stepv),_) = Ceval.ceval(cache,env, step, impl, NONE, NONE, Ceval.MSG());
        (cache,Values.REAL(stopv),_) = Ceval.ceval(cache,env, stop, impl, NONE, NONE, Ceval.MSG());
        n = stopv -. startv;
        n_1 = n /. stepv;
        n_3 = realFloor(n_1);
        n_4 = realInt(n_3);
        n_2 = n_4 + 1;
      then
        (cache,(
          DAE.T_ARRAY(DAE.DIM_INTEGER(n_2),DAE.T_REAL_DEFAULT),NONE));

		case (cache,_,_,_,_,const,DAE.ET_INT(),_,_)
  	  then (cache,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_INTEGER_DEFAULT), NONE));

		case (cache,_,_,_,_,const,DAE.ET_REAL(),_,_)
   	 then (cache,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_REAL_DEFAULT),NONE));

    case (cache,env,start,step,stop,const,expty,impl,pre)
      local Option<DAE.Exp> step;
      equation
				true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "- elab_range_type failed: ");
        sp = PrefixUtil.printPrefixStr(pre);
        s1 = Exp.printExpStr(start);
        s2opt = Util.applyOption(step, Exp.printExpStr);
        s2 = Util.flattenOption(s2opt, "none");
        s3 = Exp.printExpStr(stop);
        s4 = Types.unparseConst(const);
        s5 = Util.if_(impl, "impl", "expl");
        s6 = Exp.typeString(expty);
        str = Util.stringAppendList({"(",sp,":",s1,":",s2,":",s3,") ",s4," ",s5," ",s6});
        Debug.fprintln("failtrace", str);
      then
        fail();
  end matchcontinue;
end elabRangeType;

protected function elabTuple "function: elabTuple

  This function does elaboration of tuples, i.e. function calls returning
  several values.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Boolean performVectorization;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output list<DAE.Exp> outExpExpLst;
  output list<DAE.Properties> outTypesPropertiesLst;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExpExpLst,outTypesPropertiesLst,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,performVectorization,inPrefix)
    local
      DAE.Exp e_1;
      DAE.Properties p;
      list<DAE.Exp> exps_1;
      list<DAE.Properties> props;
      list<Env.Frame> env;
      Absyn.Exp e;
      list<Absyn.Exp> exps;
      Boolean impl;
      Env.Cache cache;
      Boolean doVect;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;

    case (cache,env,(e :: exps),impl,doVect,pre)
      equation
        (cache,e_1,p,_,dae1) = elabExp(cache,env, e, impl, NONE,doVect,pre);
        (cache,exps_1,props,dae2) = elabTuple(cache,env, exps, impl,doVect,pre);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,(e_1 :: exps_1),(p :: props),dae);

    case (cache,env,{},impl,doVect,_) then (cache,{},{},DAEUtil.emptyDae);
  end matchcontinue;
end elabTuple;

// stefan
protected function elabPartEvalFunction
"function: elabPartEvalFunction
	turns an Absyn.PARTEVALFUNCTION into an DAE.PARTEVALFUNCTION"
	input Env.Cache inCache;
	input Env.Env inEnv;
	input Absyn.Exp inExp;
	input Option<Interactive.InteractiveSymbolTable> inSymbolTableOption;
	input Boolean inImpl;
	input Boolean inVect;
	input Prefix inPrefix;
	output Env.Cache outCache;
	output DAE.Exp outExp;
	output DAE.Properties outProperties;
	output Option<Interactive.InteractiveSymbolTable> outSymbolTableOption;
	output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outSymbolTableOption,outDae) := matchcontinue(inCache,inEnv,inExp,inSymbolTableOption,inImpl,inVect,inPrefix)
    local
      Env.Cache c;
      Env.Env env;
      Absyn.ComponentRef cref;
      list<Absyn.Exp> posArgs;
      list<Absyn.NamedArg> namedArgs;
      Option<Interactive.InteractiveSymbolTable> st;
      Boolean impl,doVect;
      Absyn.Path p;
      list<DAE.Exp> args;
      DAE.ExpType ty;
      DAE.Properties prop,prop_1;
      DAE.Type tty,tty_1;
      DAE.DAElist dae;
      Prefix pre;
    case(c,env,Absyn.PARTEVALFUNCTION(cref,Absyn.FUNCTIONARGS(posArgs,namedArgs)),st,impl,doVect,pre)
      equation
        p = Absyn.crefToPath(cref);
        (c,DAE.CALL(p,args,_,_,_,_),prop,st,dae) = elabCall(c,env,cref,posArgs,namedArgs,impl,st,pre);
        (c,tty,env) = Lookup.lookupType(c,env,p,true);
        tty_1 = stripExtraArgsFromType(listLength(args),tty);
        tty_1 = Types.makeFunctionPolymorphicReference(tty_1);
        ty = Types.elabType(tty_1);
        prop_1 = Types.setTypeInProps(tty_1,prop);
      then
        (c,DAE.PARTEVALFUNCTION(p,args,ty),prop_1,st,dae);
    case(_,_,_,_,_,_,_)
      equation
        Debug.fprintln("failtrace","Static.elabPartEvalFunction failed");
      then
        fail();
  end matchcontinue;
end elabPartEvalFunction;

protected function stripExtraArgsFromType
"function: stripExtraArgsFromType
	removes the last n arguments from the funcarg list of a function type"
	input Integer inInteger;
	input DAE.Type inType;
	output DAE.Type outType;
algorithm
  outType := matchcontinue(inInteger,inType)
    local
      Integer n;
      DAE.Type resType,tty,tty_1;
      list<DAE.FuncArg> args,args_1;
      Option<Absyn.Path> po;
      DAE.InlineType  isInline;
    case(0,tty) then tty;
    case(n,(DAE.T_FUNCTION(args,resType,isInline),po))
      equation
        args_1 = Util.listRemoveNth(args,listLength(args));
        tty = (DAE.T_FUNCTION(args_1,resType,isInline),po);
        tty_1 = stripExtraArgsFromType(n-1,tty);
      then
        tty_1;
    case(_,_)
      equation
        Debug.fprintln("failtrace","- Static.stripExtraArgsFromType failed");
      then
        fail();
  end matchcontinue;
end stripExtraArgsFromType;

protected function elabArray
"function: elabArray
  This function elaborates on array expressions.

  All types of an array should be equivalent. However, mixed Integer and Real
  elements are allowed in an array and in that case the Integer elements
  are converted to Real elements."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output list<DAE.Exp> outExpExpLst;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExpExpLst,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,performVectorization,inPrefix)
    local
      list<DAE.Exp> expl_1;
      DAE.Properties prop;
      list<Env.Frame> env;
      list<Absyn.Exp> expl;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Env.Cache cache;
      Boolean doVect;
      DAE.Type t; DAE.Const c;
      DAE.DAElist dae;
      Prefix pre;

    case (cache,env,expl,impl,st,doVect,pre) /* impl array contains mixed Integer and Real types */
      equation
        elabArrayHasMixedIntReals(cache,env, expl, impl, st,doVect,pre);
        (cache,expl_1,prop,dae) = elabArrayReal(cache,env, expl, impl, st,doVect,pre);
      then
        (cache,expl_1,prop,dae);
    case (cache,env,expl,impl,st,doVect,pre)
      local Integer dim;
      equation
        (cache,expl_1,prop as DAE.PROP(t,c),dae) = elabArray2(cache,env, expl, impl, st,doVect,pre);
      then
        (cache,expl_1,DAE.PROP(t,c),dae);
  end matchcontinue;
end elabArray;

protected function elabArrayHasMixedIntReals
"function: elabArrayHasMixedIntReals
  Helper function to elab_array, checks if expression list contains both
  Integer and Real types."
	input Env.Cache inCache;
  input Env.Env env;
  input list<Absyn.Exp> expl;
  input Boolean impl;
  input Option<Interactive.InteractiveSymbolTable> st;
  input Boolean performVectorization;
  input Prefix inPrefix;
algorithm
  elabArrayHasInt(inCache,env, expl, impl, st, performVectorization,inPrefix);
  elabArrayHasReal(inCache,env, expl, impl, st, performVectorization,inPrefix);
end elabArrayHasMixedIntReals;

protected function elabArrayHasInt
"function: elabArrayHasInt
  author :PA
  Helper function to elabArray."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  input Prefix inPrefix;
algorithm
  _ := matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,performVectorization,inPrefix)
    local
      DAE.Exp e_1;
      tuple<DAE.TType, Option<Absyn.Path>> tp;
      list<Env.Frame> env;
      Absyn.Exp e;
      list<Absyn.Exp> expl;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Env.Cache cache;
      Boolean doVect;
      Prefix pre;
    case (cache,env,(e :: expl),impl,st,doVect,pre) /* impl */
      equation
        (cache,e_1,DAE.PROP(tp,_),_,_) = elabExp(cache,env, e, impl, st,doVect,pre);
        ((DAE.T_INTEGER(_),_)) = Types.arrayElementType(tp);
      then
        ();
    case (cache,env,(e :: expl),impl,st,doVect,pre)
      equation
        elabArrayHasInt(cache,env, expl, impl, st,doVect,pre);
      then
        ();
  end matchcontinue;
end elabArrayHasInt;

protected function elabArrayHasReal
"function: elabArrayHasReal
  author :PA
  Helper function to elabArray."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  input Prefix inPrefix;
algorithm
  _ := matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,performVectorization,inPrefix)
    local
      DAE.Exp e_1;
      tuple<DAE.TType, Option<Absyn.Path>> tp;
      list<Env.Frame> env;
      Absyn.Exp e;
      list<Absyn.Exp> expl;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Env.Cache cache;
      Boolean doVect;
      Prefix pre;
    case (cache,env,(e :: expl),impl,st,doVect,pre) /* impl */
      equation
        (cache,e_1,DAE.PROP(tp,_),_,_) = elabExp(cache,env, e, impl, st,doVect,pre);
        ((DAE.T_REAL(_),_)) = Types.arrayElementType(tp);
      then
        ();
    case (cache,env,(e :: expl),impl,st,doVect,pre)
      equation
        elabArrayHasReal(cache,env, expl, impl, st,doVect,pre);
      then
        ();
  end matchcontinue;
end elabArrayHasReal;

protected function elabArrayReal
"function: elabArrayReal
  Helper function to elabArray, converts all elements to Real"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output list<DAE.Exp> outExpExpLst;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExpExpLst,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,performVectorization,inPrefix)
    local
      list<DAE.Exp> expl_1,expl_2;
      list<DAE.Properties> props;
      tuple<DAE.TType, Option<Absyn.Path>> real_tp,real_tp_1;
      Ident s;
      DAE.Const const;
      list<tuple<DAE.TType, Option<Absyn.Path>>> types;
      list<Env.Frame> env;
      list<Absyn.Exp> expl;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Env.Cache cache;
      Boolean doVect;
      DAE.DAElist dae;
      Prefix pre;

    case (cache,env,expl,impl,st,doVect,pre) /* impl elaborate each expression, pick first realtype
	    and type_convert all expressions to that type */
      equation
        (cache,expl_1,props,_,dae) = elabExpList(cache,env, expl, impl, st,doVect,pre);
        real_tp = elabArrayFirstPropsReal(props);
        s = Types.unparseType(real_tp);
        const = elabArrayConst(props);
        types = Util.listMap(props, Types.getPropType);
        (expl_2,real_tp_1) = elabArrayReal2(expl_1, types, real_tp,pre);
      then
        (cache,expl_2,DAE.PROP(real_tp_1,const),dae);
    case (cache,env,expl,impl,st,doVect,pre)
      equation
        Debug.fprint("failtrace", "-elab_array_real failed, prefix=");
        Debug.fprint("failtrace", PrefixUtil.printPrefixStr(pre)); 
        Debug.fprint("failtrace", ", expl=");
        Debug.fprint("failtrace", Util.stringDelimitList(Util.listMap(expl,Dump.printExpStr),","));
        Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end elabArrayReal;

protected function elabArrayFirstPropsReal
"function: elabArrayFirstPropsReal
  author: PA
  Pick the first type among the list of
  properties which has elementype Real."
  input list<DAE.Properties> inTypesPropertiesLst;
  output DAE.Type outType;
algorithm
  outType:=
  matchcontinue (inTypesPropertiesLst)
    local
      tuple<DAE.TType, Option<Absyn.Path>> tp;
      list<DAE.Properties> rest;
    case ((DAE.PROP(type_ = tp) :: _))
      equation
        ((DAE.T_REAL(_),_)) = Types.arrayElementType(tp);
      then
        tp;
    case ((_ :: rest))
      equation
        tp = elabArrayFirstPropsReal(rest);
      then
        tp;
  end matchcontinue;
end elabArrayFirstPropsReal;

protected function elabArrayConst
"function: elabArrayConst
  Constructs a const value from a list of properties, using constAnd."
  input list<DAE.Properties> inTypesPropertiesLst;
  output DAE.Const outConst;
algorithm
  outConst:=
  matchcontinue (inTypesPropertiesLst)
    local
      tuple<DAE.TType, Option<Absyn.Path>> tp;
      DAE.Const c,c2,c1;
      list<DAE.Properties> rest;
    case ({DAE.PROP(type_ = tp,constFlag = c)}) then c;
    case ((DAE.PROP(constFlag = c1) :: rest))
      equation
        c2 = elabArrayConst(rest);
        c = Types.constAnd(c2, c1);
      then
        c;
    case (_) equation Debug.fprint("failtrace", "-elabArrayConst failed\n"); then fail();
  end matchcontinue;
end elabArrayConst;

protected function elabArrayReal2
"function: elabArrayReal2
  author: PA
  Applies type_convert to all expressions in a list to the type given
  as argument."
  input list<DAE.Exp> inExpExpLst;
  input list<DAE.Type> inTypesTypeLst;
  input DAE.Type inType;
  input Prefix inPrefix;
  output list<DAE.Exp> outExpExpLst;
  output DAE.Type outType;
algorithm
  (outExpExpLst,outType):=
  matchcontinue (inExpExpLst,inTypesTypeLst,inType,inPrefix)
    local
      tuple<DAE.TType, Option<Absyn.Path>> tp,res_type,t,to_type;
      list<DAE.Exp> res,es;
      DAE.Exp e,e_1;
      list<tuple<DAE.TType, Option<Absyn.Path>>> ts;
      Ident s,s2,s3,sp;
      Prefix pre;
    case ({},{},tp,_) then ({},tp);  /* expl to_type new_expl res_type */
    case ((e :: es),(t :: ts),to_type,pre) /* No need for type conversion. */
      equation
        true = Types.equivtypes(t, to_type);
        (res,res_type) = elabArrayReal2(es, ts, to_type,pre);
      then
        ((e :: res),res_type);
    case ((e :: es),(t :: ts),to_type,pre) /* type conversion */
      equation
        (e_1,res_type) = Types.matchType(e, t, to_type, true);
        (res,_) = elabArrayReal2(es, ts, to_type,pre);
      then
        ((e_1 :: res),res_type);
    case ((e :: es),(t :: ts),to_type,pre)
      equation
        print("elab_array_real2 failed\n");
        s = Exp.printExpStr(e);
        s2 = Types.unparseType(t);
        sp = PrefixUtil.printPrefixStr(pre);
        print("exp = ");
        print(s);
        print("prefix = ");
        print(sp);
        print(" type:");
        print(s2);
        print("\n");
        s3 = Types.unparseType(to_type);
        print(" to type :");
        print(s3);
        print("\n");
      then
        fail();
  end matchcontinue;
end elabArrayReal2;

protected function elabArray2
"function: elabArray2
  Helper function to elabArray, checks that all elements are equivalent."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output list<DAE.Exp> outExpExpLst;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExpExpLst,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,performVectorization,inPrefix)
    local
      DAE.Exp e_1;
      DAE.Properties prop;
      list<Env.Frame> env;
      Absyn.Exp e;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      tuple<DAE.TType, Option<Absyn.Path>> t1,t2;
      DAE.Const c1,c2,c;
      list<DAE.Exp> es_1;
      list<Absyn.Exp> es,expl;
      Ident e_str,str,elt_str,t1_str,t2_str,sp;
      list<Ident> strs;
      Env.Cache cache;
      Boolean doVect;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;

		case (cache, _, {}, _, _, _,_)
			then (cache, {}, DAE.PROP(DAE.T_REAL_DEFAULT, DAE.C_CONST), DAE.DAE({}, DAE.AVLTREENODE(NONE, 0, NONE, NONE)));

    case (cache,env,{e},impl,st,doVect,pre)
      equation
        (cache,e_1,prop,_,dae) = elabExp(cache,env, e, impl, st,doVect,pre);
      then
        (cache,{e_1},prop,dae);

    case (cache,env,(e :: es),impl,st,doVect,pre)
      equation
        (cache,e_1,DAE.PROP(t1,c1),_,dae1) = elabExp(cache,env, e, impl, st,doVect,pre);
        (cache,es_1,DAE.PROP(t2,c2),dae2) = elabArray2(cache,env, es, impl, st,doVect,pre);
        true = Types.equivtypes(t1, t2);
        c = Types.constAnd(c1, c2);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,(e_1 :: es_1),DAE.PROP(t1,c),dae);

    case (cache,env,(e :: es),impl,st,doVect,pre)
      equation
        (cache,e_1,DAE.PROP(t1,c1),_,_) = elabExp(cache,env, e, impl, st,doVect,pre);
        (cache,es_1,DAE.PROP(t2,c2),_) = elabArray2(cache,env, es, impl, st,doVect,pre);
        false = Types.equivtypes(t1, t2);
        sp = PrefixUtil.printPrefixStr3(pre);
        e_str = Dump.printExpStr(e);
        strs = Util.listMap(es, Dump.printExpStr);
        str = Util.stringDelimitList(strs, ",");
        elt_str = Util.stringAppendList({"[",str,"]"});
        t1_str = Types.unparseType(t1);
        t2_str = Types.unparseType(t2);
        Error.addMessage(Error.TYPE_MISMATCH_ARRAY_EXP, {sp,e_str,t1_str,elt_str,t2_str});
      then
        fail();
    case (cache,_,expl,_,_,_,_)
      equation
        // We can't use this failtrace when elaborating lists since they may
        // contain types that are not equivalent. This only happens when
        // using MetaModelica grammar.
        false = RTOpts.acceptMetaModelicaGrammar();
        Debug.fprint("failtrace", "elab_array failed\n");
      then
        fail();
  end matchcontinue;
end elabArray2;

protected function elabGraphicsArray
"function: elabGraphicsArray
  This function elaborates array expressions for graphics elaboration."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output list<DAE.Exp> outExpExpLst;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExpExpLst,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,inPrefix)
    local
      DAE.Exp e_1;
      DAE.Properties prop;
      list<Env.Frame> env;
      Absyn.Exp e;
      Boolean impl;
      tuple<DAE.TType, Option<Absyn.Path>> t1,t2;
      DAE.Const c1,c2,c;
      list<DAE.Exp> es_1;
      list<Absyn.Exp> es;
      Env.Cache cache;
      Prefix pre;
    case (cache,env,{e},impl,pre) /* impl */
      equation
        (cache,e_1,prop) = elabGraphicsExp(cache,env, e, impl,pre);
      then
        (cache,{e_1},prop);
    case (cache,env,(e :: es),impl,pre)
      equation
        (cache,e_1,DAE.PROP(t1,c1)) = elabGraphicsExp(cache,env, e, impl,pre);
        (cache,es_1,DAE.PROP(t2,c2)) = elabGraphicsArray(cache,env, es, impl,pre);
        c = Types.constAnd(c1, c2);
      then
        (cache,(e_1 :: es_1),DAE.PROP(t1,c));
    case (cache,env,{},impl,pre)
      local String envStr, str,preStr;
      equation
        envStr = Env.printEnvPathStr(env);
        preStr = PrefixUtil.printPrefixStr(pre);
        str = "Static.elabGraphicsArray failed on an empty modification with prefix: " +& preStr +& " in scope: " +& envStr;
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();
    case (cache,env,e::_,impl,pre)
      local String envStr, expStr, str,preStr;
      equation 
        envStr = Env.printEnvPathStr(env);
        preStr = PrefixUtil.printPrefixStr(pre);
        expStr = Dump.printExpStr(e);
        str = "Static.elabGraphicsArray failed on expresion: " +& expStr +& " with prefix: " +& preStr +& " in scope: " +& envStr;
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();        
  end matchcontinue;
end elabGraphicsArray;

protected function elabMatrixComma "function elabMatrixComma

  This function is a helper function for elab_matrix_semi.
  It elaborates one matrix row of a matrix.
"
	input Env.Cache inCache;
  input Env.Env inEnv1;
  input list<Absyn.Exp> inAbsynExpLst2;
  input Boolean inBoolean3;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption4;
  input Boolean inBoolean5;
  input Integer inInteger6;
  input Boolean performVectorization;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp1;
  output DAE.Properties outProperties2;
  output DAE.Dimension outInteger3;
  output DAE.Dimension outInteger4;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp1,outProperties2,outInteger3,outInteger4,outDae):=
  matchcontinue (inCache,inEnv1,inAbsynExpLst2,inBoolean3,inInteractiveInteractiveSymbolTableOption4,inBoolean5,inInteger6,performVectorization,inPrefix)
    local
      DAE.Exp el_1,el_2;
      DAE.Properties prop,prop1,prop1_1,prop2,props;
      tuple<DAE.TType, Option<Absyn.Path>> t1,t1_1;
      Integer t1_dim1,nmax_2,nmax,t1_ndims,dim;
      DAE.Dimension t1_dim1_1,t1_dim2_1,dim1,dim2,dim2_1;
      Boolean array,impl,havereal,a,scalar,doVect;
      DAE.ExpType at;
      list<Env.Frame> env;
      Absyn.Exp el;
      Option<Interactive.InteractiveSymbolTable> st;
      list<DAE.Exp> els_1;
      list<Absyn.Exp> els;
      Env.Cache cache;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;
    case (cache,env,{el},impl,st,havereal,nmax,doVect,pre) /* implicit inst. have real nmax dim1 dim2 */
      equation
        (cache,el_1,(prop as DAE.PROP(t1,_)),_,dae) = elabExp(cache,env, el, impl, st,doVect,pre);
        t1_dim1 = Types.ndims(t1);
        nmax_2 = nmax - t1_dim1;
        (el_2,(prop as DAE.PROP(t1_1,_))) = promoteExp(el_1, prop, nmax_2);
        (_,t1_dim1_1 :: (t1_dim2_1 :: _)) = Types.flattenArrayTypeOpt(t1_1);
        array = Types.isArray(Types.unliftArray(Types.unliftArray(t1_1)));
        scalar = boolNot(array);
        at = Types.elabType(t1_1);
        at = Exp.liftArrayLeft(at, DAE.DIM_INTEGER(1));
      then
        (cache,DAE.ARRAY(at,scalar,{el_2}),prop,t1_dim1_1,t1_dim2_1,dae);
    case (cache,env,(el :: els),impl,st,havereal,nmax,doVect,pre)
      equation
        (cache,el_1,(prop1 as DAE.PROP(t1,_)),_,dae1) = elabExp(cache,env, el, impl, st,doVect,pre);
        t1_ndims = Types.ndims(t1);
        nmax_2 = nmax - t1_ndims;
        (el_2,(prop1_1 as DAE.PROP(t1_1,_))) = promoteExp(el_1, prop1, nmax_2);
         (_,t1_dim1_1 :: (t1_dim2_1 :: _)) = Types.flattenArrayTypeOpt(t1_1);
        (cache,el_1 as DAE.ARRAY(at,a,els_1),prop2,dim1,dim2,dae2) = elabMatrixComma(cache,env, els, impl, st, havereal, nmax,doVect,pre);
        dim2_1 = Exp.dimensionsAdd(t1_dim2_1,dim2)"comma between matrices => concatenation along second dimension" ;
        props = Types.matchWithPromote(prop1_1, prop2, havereal);
        el_1 = Exp.arrayAppend(el_2, el_1);
        //dim = listLength((el :: els));
        //at = Exp.liftArrayLeft(at, DAE.DIM_INTEGER(dim));
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache, el_1, props, dim1, dim2_1, dae);
        //(cache,DAE.ARRAY(at,a,(el_2 :: els_1)),props,dim1,dim2_1,dae);
    case (_,_,_,_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "- elabMatrixComma failed\n");
      then
        fail();
  end matchcontinue;
end elabMatrixComma;

protected function elabMatrixCatTwoExp "function: elabMatrixCatTwoExp
  author: PA

  This function takes an array expression of dimension >=3 and
  concatenates each array element along the second dimension.
  For instance
  elab_matrix_cat_two( {{1,2;5,6}, {3,4;7,8}}) => {1,2,3,4;5,6,7,8}
"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp)
    local
      DAE.Exp res;
      list<DAE.Exp> expl;
    case (DAE.ARRAY(array = expl))
      equation
        res = elabMatrixCatTwo(expl);
      then
        res;
    case (_)
      equation
        Debug.fprint("failtrace", "-elab_matrix_cat_one failed\n");
      then
        fail();
  end matchcontinue;
end elabMatrixCatTwoExp;

protected function elabMatrixCatTwo "function: elabMatrixCatTwo
  author: PA

  Concatenates a list of matrix(or higher dim) expressions along
  the second dimension.
"
  input list<DAE.Exp> inExpExpLst;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExpExpLst)
    local
      DAE.Exp e,res,e1,e2;
      list<DAE.Exp> rest,expl;
    case ({e}) then e;
    case ({e1,e2})
      equation
        res = elabMatrixCatTwo2(e1, e2);
      then
        res;
    case ((e1 :: rest))
      equation
        e2 = elabMatrixCatTwo(rest);
        res = elabMatrixCatTwo2(e1, e2);
      then
        res;
    case (expl)
      local DAE.ExpType tp;
      equation
        tp = Exp.typeof(Util.listFirst(expl));
       then DAE.CALL(Absyn.IDENT("cat"),(DAE.ICONST(2) :: expl),false,true,tp,DAE.NO_INLINE);
  end matchcontinue;
end elabMatrixCatTwo;

protected function elabMatrixCatTwo2 "function: elabMatrixCatTwo2

  Helper function to elab_matrix_cat_two
  Concatenates two array expressions that are matrices (or higher dimension)
  along the first dimension (row).
"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp1,inExp2)
    local
      list<DAE.Exp> expl,expl1,expl2;
      DAE.Exp e;
      DAE.ExpType a1,a2, ty;
      Boolean at1,at2;
    case (DAE.ARRAY(ty = a1,scalar = at1,array = expl1),DAE.ARRAY(ty = a2,scalar = at2,array = expl2))
      equation
        e :: expl = elabMatrixCatTwo3(expl1, expl2);
        ty = Exp.typeof(e);
        ty = Exp.liftArrayLeft(ty, DAE.DIM_INTEGER(1));
      then
        DAE.ARRAY(ty,at1,e :: expl);
  end matchcontinue;
end elabMatrixCatTwo2;

protected function elabMatrixCatTwo3 "function: elabMatrixCatTwo3

  Helper function to elab_matrix_cat_two_2
"
  input list<DAE.Exp> inExpExpLst1;
  input list<DAE.Exp> inExpExpLst2;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inExpExpLst1,inExpExpLst2)
    local
      list<DAE.Exp> expl,es_1,expl1,es1,expl2,es2;
      DAE.ExpType a1,a2, ty;
      Boolean at1,at2;
      DAE.Dimension dim1, dim2;
      list<DAE.Dimension> dims1, dims2;
    case ({},{}) then {};
    case ((DAE.ARRAY(ty = a1,scalar = at1,array = expl1) :: es1),
          (DAE.ARRAY(ty = a2,scalar = at2,array = expl2) :: es2))
      equation 
        expl = listAppend(expl1, expl2);
        es_1 = elabMatrixCatTwo3(es1, es2);
        ty = Exp.concatArrayType(a1, a2);
      then
        (DAE.ARRAY(ty,at1,expl) :: es_1);
  end matchcontinue;
end elabMatrixCatTwo3;

protected function elabMatrixCatOne "function: elabMatrixCatOne
  author: PA

  Concatenates a list of matrix(or higher dim) expressions along
  the first dimension.
  i.e. elabMatrixCatOne( { {1,2;3,4}, {5,6;7,8} }) => {1,2;3,4;5,6;7,8}
"
  input list<DAE.Exp> inExpExpLst;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExpExpLst)
    local
      DAE.Exp e;
      DAE.ExpType a;
      Boolean at;
      list<DAE.Exp> expl,expl1,expl2,es;
    case ({(e as DAE.ARRAY(ty = a,scalar = at,array = expl))}) then e;
    case ({DAE.ARRAY(ty = a,scalar = at,array = expl1),DAE.ARRAY(array = expl2)})
      equation
        expl = listAppend(expl1, expl2);
      then
        DAE.ARRAY(a,at,expl);
    case ((DAE.ARRAY(ty = a,scalar = at,array = expl1) :: es))
      equation
        DAE.ARRAY(_,_,expl2) = elabMatrixCatOne(es);
        expl = listAppend(expl1, expl2);
      then
        DAE.ARRAY(a,at,expl);
    case (expl) local
      DAE.ExpType tp;
      equation
        tp = Exp.typeof(Util.listFirst(expl));
        then DAE.CALL(Absyn.IDENT("cat"),(DAE.ICONST(1) :: expl),false,true,tp,DAE.NO_INLINE);
  end matchcontinue;
end elabMatrixCatOne;

protected function promoteExp "function: promoteExp
  author: PA

  Adds onesized array dimensions to an expressions n times to the right
  of array dimensions.
  For instance
  promote_exp( {1,2},1) => {{1},{2}}
  promote_exp( {1,2},2) => { {{1}},{{2}} }
  See also promote_real_array in real_array.c
"
  input DAE.Exp inExp;
  input DAE.Properties inProperties;
  input Integer inInteger;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outExp,outProperties):=
  matchcontinue (inExp,inProperties,inInteger)
    local
      DAE.Exp e,e_1,e_2;
      DAE.Properties prop,prop_1;
      Integer n_1,n;
      DAE.ExpType e_tp,e_tp_1;
      tuple<DAE.TType, Option<Absyn.Path>> tp_1,tp;
      Boolean array;
      DAE.Const c;
    case (e,prop,-1) then (e,prop);  /* n */
    case (e,prop,0) then (e,prop);
    case (e,DAE.PROP(type_ = tp,constFlag = c),n)
      equation
        n_1 = n - 1;
        //e_tp = Types.elabType(tp);
        tp_1 = Types.liftArrayRight(tp, DAE.DIM_INTEGER(1));
        //e_tp_1 = Types.elabType(tp_1);
        //array = Exp.typeBuiltin(e_tp);
        e_1 = promoteExp2(e, (n,tp));
        (e_2,prop_1) = promoteExp(e_1, DAE.PROP(tp_1,c), n_1);
      then
        (e_2,prop_1);
    case(_,_,_) equation
      Debug.fprint("failtrace","-promoteExp failed\n");
      then fail();
  end matchcontinue;
end promoteExp;

protected function promoteExp2
"function: promoteExp2
  Helper function to promoteExp, adds
  dimension to the right of the expression."
  input DAE.Exp inExp;
  input tuple<Integer, DAE.Type> inTplIntegerTypesType;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp,inTplIntegerTypesType)
    local
      Integer n_1,n;
      tuple<DAE.TType, Option<Absyn.Path>> tp_1,tp,tp2;
      list<DAE.Exp> expl_1,expl;
      DAE.ExpType a;
      Boolean at;
      DAE.Exp e;
      Ident es;
    case (DAE.ARRAY(ty = a,scalar = at,array = expl),(n,tp))
      equation
        n_1 = n - 1;
        tp_1 = Types.unliftArray(tp);
        a = Exp.liftArrayLeft(a, DAE.DIM_INTEGER(1));
        expl_1 = Util.listMap1(expl, promoteExp2, (n_1,tp_1));
      then
        DAE.ARRAY(a,at,expl_1);
    case (e,(_,tp)) /* scalars can be promoted from s to {s} */
      local DAE.ExpType at;
      equation
        false = Types.isArray(tp);
        at = Exp.typeof(e);
      then
        DAE.ARRAY(DAE.ET_ARRAY(at,{DAE.DIM_INTEGER(1)}),true,{e});
    case (e,(_,(DAE.T_ARRAY(arrayDim = DAE.DIM_INTEGER(integer = 1),arrayType = tp2),_))) /* arrays of one dimension can be promoted from a to {a} */
      local DAE.ExpType at;
      equation
        at = Exp.typeof(e);
        false = Types.isArray(tp2);
      then
        DAE.ARRAY(DAE.ET_ARRAY(at,{DAE.DIM_INTEGER(1)}),true,{e});
    case (e,(n,tp)) /* fallback, use \"builtin\" operator promote */
      local DAE.ExpType etp,tp1;
      equation
        es = Exp.printExpStr(e);
        etp = Types.elabType(tp);
        tp1 = promoteExpType(etp,n);
      then
        DAE.CALL(Absyn.IDENT("promote"),{e,DAE.ICONST(n)},false,true,tp1,DAE.NO_INLINE);
  end matchcontinue;
end promoteExp2;

function promoteExpType "lifts the type using liftArrayRight n times"
  input DAE.ExpType inType;
  input Integer n;
  output DAE.ExpType outType;
algorithm
  outType :=  matchcontinue(inType,n)

    case(inType,0) then inType;
    case(inType,n)
      local DAE.ExpType tp1,tp2;
      equation
      tp1=Exp.liftArrayRight(inType, DAE.DIM_INTEGER(1));
      tp2 = promoteExpType(tp1,n-1);
    then tp2;
  end matchcontinue;
end promoteExpType;

protected function elabMatrixSemi
"function: elabMatrixSemi
  This function elaborates Matrix expressions, e.g. {1,0;2,1}
  A row is elaborated with elabMatrixComma."
	input Env.Cache inCache;
  input Env.Env inEnv1;
  input list<list<Absyn.Exp>> inAbsynExpLstLst2;
  input Boolean inBoolean3;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption4;
  input Boolean inBoolean5;
  input Integer inInteger6;
  input Boolean performVectorization;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp1;
  output DAE.Properties outProperties2;
  output DAE.Dimension outInteger3;
  output DAE.Dimension outInteger4;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp1,outProperties2,outInteger3,outInteger4,outDae) :=
  matchcontinue (inCache,inEnv1,inAbsynExpLstLst2,inBoolean3,inInteractiveInteractiveSymbolTableOption4,inBoolean5,inInteger6,performVectorization,inPrefix)
    local
      DAE.Exp el_1,el_2,els_1,els_2;
      DAE.Properties props,props1,props2;
      tuple<DAE.TType, Option<Absyn.Path>> t,t1,t2;
      Integer maxn,dim;
      DAE.Dimension dim1,dim2,dim1_1,dim2_1,dim1_2;
      DAE.ExpType at;
      Boolean a,impl,havereal;
      list<Env.Frame> env;
      list<Absyn.Exp> el;
      Option<Interactive.InteractiveSymbolTable> st;
      list<list<Absyn.Exp>> els;
      Ident el_str,t1_str,t2_str,dim1_str,dim2_str,el_str1,pre_str;
      Env.Cache cache;
      Boolean doVect;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;

    case (cache,env,{el},impl,st,havereal,maxn,doVect,pre) /* implicit inst. contain real maxn */
      equation
        (cache,el_1,(props as DAE.PROP(t,_)),dim1,dim2,dae) = elabMatrixComma(cache,env, el, impl, st, havereal, maxn,doVect,pre);
        at = Types.elabType(t);
        a = Types.isPropArray(props);
        el_2 = elabMatrixCatTwoExp(el_1);
      then
        (cache,el_2,props,dim1,dim2,dae);
    case (cache,env,(el :: els),impl,st,havereal,maxn,doVect,pre)
      equation
        dim = listLength((el :: els));
        (cache,el_1,props1,dim1,dim2,dae1) = elabMatrixComma(cache,env, el, impl, st, havereal, maxn,doVect,pre);
        el_2 = elabMatrixCatTwoExp(el_1);
        (cache,els_1,props2,dim1_1,dim2_1,dae2) = elabMatrixSemi(cache,env, els, impl, st, havereal, maxn,doVect,pre);
        els_2 = elabMatrixCatOne({el_2,els_1});
        true = Exp.dimensionsEqual(dim2,dim2_1) "semicoloned values a;b must have same no of columns" ;
        dim1_2 = Exp.dimensionsAdd(dim1, dim1_1) "number of rows added." ;
        (props) = Types.matchWithPromote(props1, props2, havereal);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,els_2,props,dim1_2,dim2,dae);

    case (_,_,_,_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "- Static.elabMatrixSemi failed\n");
      then
        fail();
    case (cache,env,(el :: els),impl,st,havereal,maxn,doVect,pre) /* Error messages */
      equation
        (cache,el_1,DAE.PROP(t1,_),_,_,_) = elabMatrixComma(cache,env, el, impl, st, havereal, maxn,doVect,pre);
        (cache,els_1,DAE.PROP(t2,_),_,_,_) = elabMatrixSemi(cache,env, els, impl, st, havereal, maxn,doVect,pre);
        failure(equality(t1 = t2));
        pre_str = PrefixUtil.printPrefixStr3(inPrefix);
        el_str = Exp.printListStr(el, Dump.printExpStr, ", ");
        t1_str = Types.unparseType(t1);
        t2_str = Types.unparseType(t2);
        Error.addMessage(Error.TYPE_MISMATCH_MATRIX_EXP, {pre_str,el_str,t1_str,t2_str});
      then
        fail();
    case (cache,env,(el :: els),impl,st,havereal,maxn,doVect,pre)
      equation
        (cache,el_1,DAE.PROP(t1,_),dim1,_,_) = elabMatrixComma(cache,env, el, impl, st, havereal, maxn,doVect,pre);
        (cache,els_1,props2,_,dim2,_) = elabMatrixSemi(cache,env, els, impl, st, havereal, maxn,doVect,pre);
        false = Exp.dimensionsEqual(dim1,dim2);
        dim1_str = Exp.dimensionString(dim1);
        dim2_str = Exp.dimensionString(dim2);
        pre_str = PrefixUtil.printPrefixStr3(inPrefix);
        el_str = Exp.printListStr(el, Dump.printExpStr, ", ");
        el_str1 = Util.stringAppendList({"[",el_str,"]"});
        Error.addMessage(Error.MATRIX_EXP_ROW_SIZE, {pre_str,el_str1,dim1_str,dim2_str});
      then
        fail();
  end matchcontinue;
end elabMatrixSemi;

protected function verifyBuiltInHandlerType "
 Author BZ, 2009-02
  This function validates that arguments to function are of a correct type.
  Then call elabCallArgs to vectorize/type-match."
  input Env.Cache cache;
  input Env.Env env;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean impl;
  input extraFunc typeChecker;
  input String fnName;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
  partial function extraFunc
    input DAE.Type inp1;
    output Boolean outp1;
  end extraFunc;
algorithm
  (outCache,outExp,outProperties,outDae) := matchcontinue (cache,env,inAbsynExpLst,impl,typeChecker,fnName,inPrefix)
    local
      DAE.Type ty,ty2;
      Absyn.Exp s1;
      DAE.Exp s1_1;
      DAE.Const c;
      DAE.Properties prop;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;
    
    case (cache,env,{s1},impl,typeChecker,fnName,pre) /* impl */
      equation
        (cache,_,DAE.PROP(ty,c),_,dae1) = elabExp(cache, env, s1, impl, NONE,true,pre);
        // verify type here to see that input arguments are okay.
        ty2 = Types.arrayElementType(ty);
        true = typeChecker(ty2);
        (cache,s1_1,(prop as DAE.PROP(ty,c)),dae2) = elabCallArgs(cache,env, Absyn.IDENT(fnName), {s1}, {}, impl, NONE,pre);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,s1_1,prop,dae);
  end matchcontinue;
end verifyBuiltInHandlerType;

protected function elabBuiltinCardinality
"function: elabBuiltinCardinality
  author: PA
  This function elaborates the cardinality operator."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae) := matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp exp_1;
      DAE.ComponentRef cr_1;
      tuple<DAE.TType, Option<Absyn.Path>> tp1;
      list<Env.Frame> env;
      Absyn.Exp exp;
      Absyn.ComponentRef cr;
      Boolean impl;
      Env.Cache cache;
      DAE.DAElist dae;
      Prefix pre;
    
    case (cache,env,{(exp as Absyn.CREF(componentRef = cr))},_,impl,pre)
      equation
        (cache,(exp_1 as DAE.CREF(cr_1,_)),DAE.PROP(tp1,_),_,dae) = elabExp(cache,env, exp, impl, NONE,true,pre);
      then
        (cache,DAE.CALL(Absyn.IDENT("cardinality"),{exp_1},false,true,DAE.ET_INT(),DAE.NO_INLINE),DAE.PROP(DAE.T_INTEGER_DEFAULT,DAE.C_CONST()),dae);
  end matchcontinue;
end elabBuiltinCardinality;

protected function elabBuiltinSmooth
"This function elaborates the smooth operator.
  smooth(p,expr) - If p>=0 smooth(p, expr) returns expr and states that expr is p times
  continuously differentiable, i.e.: expr is continuous in all real variables appearing in
  the expression and all partial derivatives with respect to all appearing real variables
  exist and are continuous up to order p.
  The only allowed types for expr in smooth are: real expressions, arrays of
  allowed expressions, and records containing only components of allowed
	expressions."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae) := matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp p_1,expr_1,exp;
      DAE.Const c1,c2_1,c,c_1;
      Boolean c2,impl,b1,b2;
      DAE.Type tp,tp1;
      list<Env.Frame> env;
      Absyn.Exp p,expr;
      list<Absyn.Exp> expl;
      Env.Cache cache;
      DAE.ExpType etp;
      String s1,a1,a2,sp;
      Integer pInt;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;

    case (cache,env,{Absyn.INTEGER(pInt),expr},_,impl,pre) // if p is 0 just return the expression!
      equation
        true = pInt == 0;
        (cache,expr_1,DAE.PROP(tp,c),_,dae1) = elabExp(cache,env, expr, impl, NONE, true,pre);
        b1 = Types.isReal(tp);
        b2 = Types.isRecordWithOnlyReals(tp);
        true = Util.boolOrList({b1,b2});
        etp = Types.elabType(tp);
        exp = expr_1;
      then
        (cache,exp,DAE.PROP(tp,c),dae1);

    case (cache,env,{p,expr},_,impl,pre)
      equation
        (cache,p_1,DAE.PROP(tp1,c1),_,dae1) = elabExp(cache,env, p, impl, NONE,true,pre);
        true = Types.isParameterOrConstant(c1);
        true = Types.isInteger(tp1);
        (cache,expr_1,DAE.PROP(tp,c),_,dae2) = elabExp(cache,env, expr, impl, NONE,true,pre);
        b1 = Types.isReal(tp);
        b2 = Types.isRecordWithOnlyReals(tp);
        true = Util.boolOrList({b1,b2});
        etp = Types.elabType(tp);
        exp = DAE.CALL(Absyn.IDENT("smooth"),{p_1,expr_1},false,true,etp,DAE.NO_INLINE);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,exp,DAE.PROP(tp,c),dae);

    case (cache,env,{p,expr},_,impl,pre)
      equation
        (cache,p_1,DAE.PROP(tp1,c1),_,_) = elabExp(cache,env, p, impl, NONE,true,pre)  ;
        false = Types.isParameterOrConstant(c1) and Types.isInteger(tp1);
        a1 = Dump.printExpStr(p);
        a2 = Dump.printExpStr(expr);
        sp = PrefixUtil.printPrefixStr3(pre);
        s1 = "smooth(" +& a1 +& ", " +& a2 +&"), first argument must be a constant or parameter expression of type Integer";
        Error.addMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS,{s1,sp});
      then
        fail();

    case (cache,env,{p,expr},_,impl,pre)
      equation
        (cache,p_1,DAE.PROP(_,c1),_,_) = elabExp(cache,env, p, impl, NONE,true,pre)  ;
        true = Types.isParameterOrConstant(c1);
        (cache,expr_1,DAE.PROP(tp,c),_,_) = elabExp(cache,env, expr, impl, NONE,true,pre);
        b1 = Types.isReal(tp);
        b2 = Types.isRecordWithOnlyReals(tp);
        false = Util.boolOrList({b1,b2});
        a1 = Dump.printExpStr(p);
        a2 = Dump.printExpStr(expr);
        sp = PrefixUtil.printPrefixStr3(pre);
        s1 = "smooth("+&a1+& ", "+&a2 +&"), second argument must be a Real, array of Reals or record only containg Reals";
        Error.addMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS,{s1,sp});
      then
        fail();

    case (cache,env,expl,_,impl,pre) equation
      failure(2 = listLength(expl));
      a1 = Dump.printExpLstStr(expl);
      sp = PrefixUtil.printPrefixStr3(pre);
      s1 = "expected smooth(p,expr), got smooth("+&a1+&")";
      Error.addMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS,{s1,sp});
    then fail();
  end matchcontinue;
end elabBuiltinSmooth;

protected function elabBuiltinSize
"function: elabBuiltinSize
  This function elaborates the size operator.
  Input is the list of arguments to size as Absyn.Exp
  expressions and the environment, Env.Env."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae) := matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp dimp,arraycrefe,exp;
      DAE.Const c1,c2_1,c,c_1;
      DAE.Type arrtp;
      DAE.Properties prop;
      Boolean c2,impl;
      list<Env.Frame> env;
      Absyn.Exp arraycr,dim;
      list<Absyn.Exp> expl;
      Env.Cache cache;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;
      String sp;
      Integer dim_int;
      DAE.ExpType ety;
      list<DAE.Dimension> dims;
      DAE.Dimension d;
        
    // size(A,x) for an array A with known dimensions and constant x. 
    // Returns the size of the x:th dimension.
    case (cache, env, {arraycr, dim}, _, impl, pre) 
      equation
        (cache,dimp,_,_,dae1) = elabExp(cache, env, dim, impl, NONE, true, pre);
        dim_int = Exp.expInt(dimp);
        (cache, arraycrefe, _, _, dae2) = elabExp(cache, env, arraycr, impl, NONE, false, pre);
        ety = Exp.typeof(arraycrefe);
        dims = Exp.arrayTypeDimensions(ety);
        d = listNth(dims, dim_int - 1);
        exp = Exp.dimensionSizeExp(d);
        prop = DAE.PROP(DAE.T_INTEGER_DEFAULT, DAE.C_CONST);
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        (cache, exp, prop, dae); 
            
    // The previous case failed, return a call to the size function instead.
    case (cache,env,{arraycr,dim},_,impl,pre)
      equation
        (cache,dimp,_,_,dae1) = elabExp(cache, env, dim, impl, NONE, true,pre);
        (cache,arraycrefe,_,_,dae2) = elabExp(cache, env, arraycr, impl, NONE, true,pre);
        exp = DAE.SIZE(arraycrefe,SOME(dimp));
        prop = DAE.PROP(DAE.T_INTEGER_DEFAULT, DAE.C_PARAM);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,exp,prop,dae);

    // size(A) for an array A with known dimensions. Returns an array of all dimensions of A.
    case (cache,env,{arraycr},_,impl,pre)
      local list<Exp.Exp> dim_expl;
      equation
        (cache, arraycrefe, _, _, dae1) = elabExp(cache, env, arraycr, impl, NONE, false, pre);
        ety = Exp.typeof(arraycrefe);
        dims = Exp.arrayTypeDimensions(ety);
        dim_expl = Util.listMap(dims, Exp.dimensionSizeExp);
        dim_int = listLength(dim_expl);
        exp = DAE.ARRAY(DAE.ET_ARRAY(DAE.ET_INT, {DAE.DIM_INTEGER(dim_int)}), true, dim_expl);
        prop = DAE.PROP((DAE.T_ARRAY(DAE.DIM_INTEGER(dim_int), DAE.T_INTEGER_DEFAULT), NONE), DAE.C_CONST);
      then
        (cache, exp, prop, dae1);
        
    // The previous case failed, return a call to the size function instead.
    case (cache,env,{arraycr},_,impl,pre)
      local Boolean c;
      equation
        (cache,arraycrefe,DAE.PROP(arrtp,_),_,dae1) = elabExp(cache,env, arraycr, impl, NONE,true,pre);
        c = Types.dimensionsKnown(arrtp);
        c_1 = Types.boolConstSize(c);
        exp = DAE.SIZE(arraycrefe,NONE);
        prop = DAE.PROP((DAE.T_ARRAY(DAE.DIM_NONE, DAE.T_INTEGER_DEFAULT), NONE), c_1);
      then
        (cache,exp,prop,dae1);
        
    // failure!
    case (cache,env,expl,_,impl,pre)
      equation
				true = RTOpts.debugFlag("failtrace");
				sp = PrefixUtil.printPrefixStr3(pre);
        Debug.fprintln("failtrace", "- Static.elabBuiltinSize failed on: " +& Dump.printExpLstStr(expl) +& " in component: " +& sp);
      then
        fail();
  end matchcontinue;
end elabBuiltinSize;

protected function elabBuiltinNDims
"@author Stefan Vorkoetter <svorkoetter@maplesoft.com>
 ndims(A) : Returns the number of dimensions k of array expression A, with k >= 0.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae) := matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp arraycrefe,exp;
      DAE.Const c;
      tuple<DAE.TType, Option<Absyn.Path>> arrtp;
      Boolean c2,impl;
      list<Env.Frame> env;
      Absyn.Exp arraycr;
      Env.Cache cache;
      list<Absyn.Exp> expl;
      Integer nd;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;
      String sp;

    case (cache,env,{arraycr},_,impl,pre)
      equation
        (cache,arraycrefe,DAE.PROP(arrtp,_),_,dae1) = elabExp(cache,env, arraycr, impl, NONE,true,pre) "ndims(A)" ;
        c2 = Types.dimensionsKnown(arrtp);
        c = Types.boolConst(c2);
        nd = Types.ndims(arrtp);
        exp = DAE.ICONST(nd);
      then
        (cache,exp,DAE.PROP(DAE.T_INTEGER_DEFAULT,c),dae1);

    case (cache,env,expl,_,impl,pre)
      equation
				true = RTOpts.debugFlag("failtrace");
				sp = PrefixUtil.printPrefixStr3(pre);
        Debug.fprint("failtrace", "- Static.elabBuiltinNdims failed for: ndims(" +& Dump.printExpLstStr(expl) +& " in component: " +& sp);
      then
        fail();
  end matchcontinue;
end elabBuiltinNDims;

protected function elabBuiltinFill "function: elabBuiltinFill

  This function elaborates the builtin operator fill.
  The input is the arguments to fill as Absyn.Exp expressions and the environment Env.Env
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
	output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp s_1,exp;
      DAE.Properties prop;
      list<DAE.Exp> dims_1;
      list<DAE.Properties> dimprops;
      tuple<DAE.TType, Option<Absyn.Path>> sty;
      list<Values.Value> dimvals;
      list<Env.Frame> env;
      Absyn.Exp s;
      list<Absyn.Exp> dims;
      Boolean impl;
      Ident implstr,expstr,str,sp;
      list<Ident> expstrs;
      Env.Cache cache;
      DAE.Const c1;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;

    case (cache,env,(s :: dims),_,impl,pre) /* impl */
      equation
        (cache,s_1,prop,_,dae1) = elabExp(cache, env, s, impl, NONE,true,pre);
        (cache,dims_1,dimprops,_,dae2) = elabExpList(cache,env, dims, impl, NONE,true,pre);
        sty = Types.getPropType(prop);
        (cache,dimvals) = Ceval.cevalList(cache,env, dims_1, impl, NONE, Ceval.MSG());
        c1 = Types.elabTypePropToConst(prop::dimprops);
        (cache,exp,prop) = elabBuiltinFill2(cache,env, s_1, sty, dimvals,c1,pre);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,exp,prop,dae);
    
		/* If the previous case failed we probably couldn't constant evaluate the
		 * dimensions. Create a function call to fill instead, and let the compiler
		 * sort it out later. */
    case (cache, env, (s :: dims), _, impl,pre)
			local
				DAE.ExpType exp_type;
      equation
        (cache, s_1, prop, _, dae1) = elabExp(cache, env, s, impl, NONE, true,pre);
        (cache, dims_1, dimprops, _, dae2) = elabExpList(cache, env, dims, impl, NONE, true,pre);
        sty = Types.getPropType(prop);
        sty = makeFillArgListType(sty, dimprops);
				exp_type = Types.elabType(sty);
        dae = DAEUtil.joinDaes(dae1, dae2);
        prop = DAE.PROP(sty, DAE.C_VAR());
				exp = DAE.CALL(Absyn.IDENT("fill"), s_1 :: dims_1, false, true, exp_type, DAE.NORM_INLINE);
     then
       (cache, exp, prop, dae);
      
    case (cache,env,dims,_,impl,pre)
      equation
				true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace",
          "- elab_builtin_fill: Couldn't elaborate fill(): ");
        implstr = Util.boolString(impl);
        expstrs = Util.listMap(dims, Dump.printExpStr);
        expstr = Util.stringDelimitList(expstrs, ", ");
				sp = PrefixUtil.printPrefixStr3(pre);
        str = Util.stringAppendList({expstr," impl=",implstr,", in component: ",sp});
        Debug.fprintln("failtrace", str);
      then
        fail();
  end matchcontinue;
end elabBuiltinFill;

public function elabBuiltinFill2
"
  function: elabBuiltinFill2
  Helper function to: elabBuiltinFill
  
  Public since it is used by Exp.simplifyBuiltinCalls.
"
	input Env.Cache inCache;
	input Env.Env inEnv;
  input DAE.Exp inExp;
  input DAE.Type inType;
  input list<Values.Value> inValuesValueLst;
  input DAE.Const constVar;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inExp,inType,inValuesValueLst,constVar,inPrefix)
    local
      list<DAE.Exp> arraylist;
      Ident dimension;
      DAE.ExpType at;
      Boolean a;
      list<Env.Frame> env;
      DAE.Exp s,exp;
      tuple<DAE.TType, Option<Absyn.Path>> sty,ty,sty2;
      Integer v;
      DAE.Const con;
      list<Values.Value> rest;
      Env.Cache cache;
      DAE.Const c1;
      Prefix pre;
      String str;
    case (cache,env,s,sty,{Values.INTEGER(integer = v)},c1,_)
      equation
        arraylist = buildExpList(s, v);
        dimension = intString(v);
        sty2 = (DAE.T_ARRAY(DAE.DIM_INTEGER(v),sty),NONE);
        at = Types.elabType(sty2);
        a = Types.isArray(sty2);
      then
        (cache,DAE.ARRAY(at,a,arraylist),DAE.PROP(sty2,c1));
    case (cache,env,s,sty,(Values.INTEGER(integer = v) :: rest),c1,pre)
      equation
        (cache,exp,DAE.PROP(ty,con)) = elabBuiltinFill2(cache,env, s, sty, rest,c1,pre);
        arraylist = buildExpList(exp, v);
        dimension = intString(v);
        sty2 = (DAE.T_ARRAY(DAE.DIM_INTEGER(v),ty),NONE);
        at = Types.elabType(sty2);
        a = Types.isArray(sty2);
      then
        (cache,DAE.ARRAY(at,a,arraylist),DAE.PROP(sty2,c1));
    case (_,_,_,_,_,_,pre)
      equation
        str = "elab_builtin_fill_2 failed in component" +& PrefixUtil.printPrefixStr3(inPrefix);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();
  end matchcontinue;
end elabBuiltinFill2;

protected function makeFillArgListType
	"Helper function to elabBuiltinFill. Takes the type of the fill expression and
		the properties of the dimensions, and constructs the result type of the fill
		function."
	input DAE.Type fillType;
	input list<DAE.Properties> dimProps;
	output DAE.Type resType;
algorithm
	resProp := matchcontinue(fillType, dimProps)
		local
			DAE.Properties prop;
			list<DAE.Properties> rest_props;
			DAE.Type t, t2;
		case (_, {}) then fillType;
		case (_, prop :: rest_props)
			equation
				t = makeFillArgListType(fillType, rest_props);
				t = (DAE.T_ARRAY(DAE.DIM_NONE, t), NONE);
			then
				t;
	end matchcontinue;
end makeFillArgListType;

protected function elabBuiltinTranspose "function: elabBuiltinTranspose

  This function elaborates the builtin operator transpose
  The input is the arguments to fill as Absyn.Exp expressions and the environment Env.Env
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.ExpType tp;
      Boolean sc,impl;
      list<DAE.Exp> expl,exp_2;
      DAE.Dimension d1,d2;
      tuple<DAE.TType, Option<Absyn.Path>> eltp,newtp;
      Integer dim1,dim2,dimMax;
      DAE.Properties prop;
      DAE.Const c;
      list<Env.Frame> env;
      Absyn.Exp matexp;
      DAE.Exp exp_1,exp;
      Env.Cache cache;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;

    case (cache,env,{matexp},_,impl,pre) /* impl try symbolically transpose the ARRAY expression */
      equation
        (cache,DAE.ARRAY(tp,sc,expl),DAE.PROP((DAE.T_ARRAY(d1,(DAE.T_ARRAY(d2,eltp),_)),_),c),_,dae1)
        	= elabExp(cache,env, matexp, impl, NONE,true,pre);
        dim1 = Exp.dimensionSize(d1);
        exp_2 = elabBuiltinTranspose2(expl, 1, dim1);
        newtp = (DAE.T_ARRAY(d2,(DAE.T_ARRAY(d1,eltp),NONE)),NONE);
        prop = DAE.PROP(newtp,c);
        tp = transposeExpType(tp);
      then
        (cache,DAE.ARRAY(tp,sc,exp_2),prop,dae1);
    case (cache,env,{matexp},_,impl,pre) /* try symbolically transpose the MATRIX expression */
      local
        Integer sc;
        list<list<tuple<DAE.Exp, Boolean>>> expl,exp_2;
      equation
        (cache,DAE.MATRIX(tp,sc,expl),DAE.PROP((DAE.T_ARRAY(d1,(DAE.T_ARRAY(d2,eltp),_)),_),c),_,dae1)
        	= elabExp(cache,env, matexp, impl, NONE,true,pre);
        dim1 = Exp.dimensionSize(d1);
        dim2 = Exp.dimensionSize(d2);
        dimMax = intMax(dim1, dim2);
        exp_2 = elabBuiltinTranspose3(expl, 1, dimMax);
        newtp = (DAE.T_ARRAY(d2,(DAE.T_ARRAY(d1,eltp),NONE)),NONE);
        prop = DAE.PROP(newtp,c);
        tp = transposeExpType(tp);
      then
        (cache,DAE.MATRIX(tp,sc,exp_2),prop,dae1);
    case (cache,env,{matexp},_,impl,pre) /* .. otherwise create transpose call */
      local DAE.ExpType tp;
      equation
        (cache,exp_1,DAE.PROP((DAE.T_ARRAY(d1,(DAE.T_ARRAY(d2,eltp),_)),_),c),_,dae1)
        	= elabExp(cache,env, matexp, impl, NONE,true,pre);
        newtp = (DAE.T_ARRAY(d2,(DAE.T_ARRAY(d1,eltp),NONE)),NONE);
        tp = Types.elabType(newtp);
        exp = DAE.CALL(Absyn.IDENT("transpose"),{exp_1},false,true,tp,DAE.NO_INLINE);
        prop = DAE.PROP(newtp,c);
      then
        (cache,exp,prop,dae1);
  end matchcontinue;
end elabBuiltinTranspose;

protected function transposeExpType
  "Helper function to elabBuiltinTranspose. Transposes an array type, i.e. swaps
  the first two dimensions." 
  input DAE.ExpType inType;
  output DAE.ExpType outType;
algorithm
  outType := matchcontinue(inType)
    case (DAE.ET_ARRAY(ty = ty, arrayDimensions = dim1 :: dim2 :: dim_rest))
      local
        DAE.ExpType ty;
        DAE.Dimension dim1, dim2;
        list<DAE.Dimension> dim_rest;
      then
        DAE.ET_ARRAY(ty, dim2 :: dim1 :: dim_rest);
  end matchcontinue;
end transposeExpType;
   
protected function elabBuiltinTranspose2 "function: elabBuiltinTranspose2
  author: PA

  Helper function to elab_builtin_transpose. Tries to symbolically transpose
  a matrix expression in ARRAY form.
"
  input list<DAE.Exp> inExpExpLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inExpExpLst1,inInteger2,inInteger3)
    local
      DAE.Exp e;
      list<DAE.Exp> es,rest,elst;
      DAE.ExpType tp;
      Integer indx_1,indx,dim1;
    case (elst,indx,dim1)
      equation
        (indx <= dim1) = true;
        indx_1 = indx - 1;
        (e :: es) = Util.listMap1(elst, Exp.nthArrayExp, indx_1);
        tp = Exp.typeof(e);
        indx_1 = indx + 1;
        rest = elabBuiltinTranspose2(elst, indx_1, dim1);
      then
        (DAE.ARRAY(tp,false,(e :: es)) :: rest);
    case (_,_,_) then {};
  end matchcontinue;
end elabBuiltinTranspose2;

protected function elabBuiltinTranspose3 "function: elabBuiltinTranspose3
  author: PA

  Helper function to elab_builtin_transpose. Tries to symbolically transpose
  a MATRIX expression list
"
  input list<list<tuple<DAE.Exp, Boolean>>> inTplExpExpBooleanLstLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<list<tuple<DAE.Exp, Boolean>>> outTplExpExpBooleanLstLst;
algorithm
  outTplExpExpBooleanLstLst:=
  matchcontinue (inTplExpExpBooleanLstLst1,inInteger2,inInteger3)
    local
      Integer lindx,indx_1,indx,dim1;
      tuple<DAE.Exp, Boolean> e;
      list<tuple<DAE.Exp, Boolean>> es;
      DAE.Exp e_1;
      DAE.ExpType tp;
      list<list<tuple<DAE.Exp, Boolean>>> rest,res,elst;
    case (elst,indx,dim1)
      equation
        (indx <= dim1) = true;
        lindx = indx - 1;
        (e :: es) = Util.listMap1(elst, list_nth, lindx);
        e_1 = Util.tuple21(e);
        tp = Exp.typeof(e_1);
        indx_1 = indx + 1;
        rest = elabBuiltinTranspose3(elst, indx_1, dim1);
        res = listAppend({(e :: es)}, rest);
      then
        res;
    case (_,_,_) then {};
  end matchcontinue;
end elabBuiltinTranspose3;

protected function buildExpList "function: buildExpList

  Helper function to e.g. elab_builtin_fill_2. Creates n copies of the same
  expression given as input.
"
  input DAE.Exp inExp;
  input Integer inInteger;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inExp,inInteger)
    local
      DAE.Exp e;
      Integer c_1,c;
      list<DAE.Exp> rest;
    case (e,0) then {};  /* n */
    case (e,1) then {e};
    case (e,c)
      equation
        c_1 = c - 1;
        rest = buildExpList(e, c_1);
      then
        (e :: rest);
  end matchcontinue;
end buildExpList;

protected function elabBuiltinSum "function: elabBuiltinSum

  This function elaborates the builtin operator sum.
  The input is the arguments to fill as Absyn.Exp expressions and the environment Env.Env
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
	output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp exp_1,exp_2;
      DAE.Dimension dim;
      tuple<DAE.TType, Option<Absyn.Path>> tp;
      DAE.Const c;
      list<Env.Frame> env;
      Absyn.Exp arrexp;
      Boolean impl;
      Env.Cache cache;
      DAE.Type ty,ty2;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;

    case (cache,env,{arrexp},_,impl,pre) /* impl */
      local String str_exp,str_pre;
      equation
        (cache,exp_1,DAE.PROP(ty,c),_,dae1) = elabExp(cache,env, arrexp, impl, NONE,true,pre);
        (exp_1,ty2) = Types.matchType(exp_1, ty, DAE.T_INTEGER_DEFAULT, true);
        str_exp = "sum(" +& Dump.printExpStr(arrexp) +& ")";
        str_pre = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.BUILTIN_FUNCTION_SUM_HAS_SCALAR_PARAMETER, {str_exp, str_pre});
      then
         (cache,exp_1,DAE.PROP(DAE.T_INTEGER_DEFAULT,c),dae1);
    case (cache,env,{arrexp},_,impl,pre) /* impl */
      local String str_exp,str_pre;
      equation
        (cache,exp_1,DAE.PROP(ty,c),_,dae1) = elabExp(cache,env, arrexp, impl, NONE,true,pre);
        (exp_1,ty2) = Types.matchType(exp_1, ty, DAE.T_REAL_DEFAULT, true);
        str_exp = "sum(" +& Dump.printExpStr(arrexp) +& ")";
        str_pre = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.BUILTIN_FUNCTION_SUM_HAS_SCALAR_PARAMETER, {str_exp, str_pre});
      then
         (cache,exp_1,DAE.PROP(DAE.T_REAL_DEFAULT,c),dae1);
    case (cache,env,aexps,_,impl,pre)
      local
        DAE.ExpType etp;
        DAE.Type t;
        list<Absyn.Exp> aexps;
      equation
        arrexp = Util.listFirst(aexps);
        (cache,exp_1,DAE.PROP(t,c),_,dae1) = elabExp(cache,env, arrexp, impl, NONE,true,pre);
        (tp,_) = Types.flattenArrayType(t);
        etp = Types.elabType(tp);
        exp_2 = elabBuiltinSum2(DAE.CALL(Absyn.IDENT("sum"),{exp_1},false,true,etp,DAE.NO_INLINE));
      then
        (cache,exp_2,DAE.PROP(tp,c),dae1);
  end matchcontinue;
end elabBuiltinSum;

protected function elabBuiltinSum2 " replaces sum({a1,a2,...an}) with a1+a2+...+an} and
sum([a11,a12,...,a1n;...,am1,am2,..amn]) with a11+a12+...+amn
"
input DAE.Exp inExp;
output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      DAE.ExpType ty;
      Boolean sc;
      list<DAE.Exp> expl;
      DAE.Exp e;
      list<list<tuple<DAE.Exp, Boolean>>> mexpl;
      Integer dim;
    case(DAE.CALL(_,{DAE.ARRAY(ty,sc,expl)},_,_,_,_)) equation
      e = Exp.makeSum(expl);
    then e;
    case(DAE.CALL(_,{DAE.MATRIX(ty,dim,mexpl)},_,_,_,_)) equation
      expl = Util.listMap(Util.listFlatten(mexpl), Util.tuple21);
      e = Exp.makeSum(expl);
    then e;

    case (e) then e;
  end matchcontinue;
end elabBuiltinSum2;

protected function elabBuiltinProduct "function: elabBuiltinProduct

  This function elaborates the builtin operator product.
  The input is the arguments to fill as Absyn.Exp expressions and the environment Env.Env
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
	output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp exp_1,exp_2;
      DAE.Dimension dim;
      tuple<DAE.TType, Option<Absyn.Path>> tp;
      DAE.Const c;
      list<Env.Frame> env;
      Absyn.Exp arrexp;
      Boolean impl;
      DAE.Type ty,ty2;
      Env.Cache cache;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;

    case (cache,env,{arrexp},_,impl,pre)
      local String str_exp,str_pre;
      equation
        (cache,exp_1,DAE.PROP(ty,c),_,dae1) = elabExp(cache,env, arrexp, impl, NONE,true,pre);
        (exp_1,ty2) = Types.matchType(exp_1, ty, DAE.T_INTEGER_DEFAULT, true);
        str_exp = "product(" +& Dump.printExpStr(arrexp) +& ")";
        str_pre = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.BUILTIN_FUNCTION_PRODUCT_HAS_SCALAR_PARAMETER, {str_exp, str_pre});
      then
         (cache,exp_1,DAE.PROP(DAE.T_INTEGER_DEFAULT,c),dae1);
    case (cache,env,{arrexp},_,impl,pre) /* impl */
      local String str_exp,str_pre;
      equation
        (cache,exp_1,DAE.PROP(ty,c),_,dae1) = elabExp(cache,env, arrexp, impl, NONE,true,pre);
        (exp_1,ty2) = Types.matchType(exp_1, ty, DAE.T_REAL_DEFAULT, true);
        str_exp = "product(" +& Dump.printExpStr(arrexp) +& ")";
        str_pre = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.BUILTIN_FUNCTION_PRODUCT_HAS_SCALAR_PARAMETER, {str_exp, str_pre});
      then
         (cache,exp_1,DAE.PROP(DAE.T_REAL_DEFAULT,c),dae1);
    case (cache,env,{arrexp},_,impl,pre) /* impl */
      local DAE.ExpType etp; DAE.Type t;
      equation
        (cache,exp_1,DAE.PROP(t as (DAE.T_ARRAY(dim,tp),_),c),_,dae1) = elabExp(cache,env, arrexp, impl, NONE,true,pre);
        tp = Types.arrayElementType(t);
        etp = Types.elabType(tp);
        exp_2 = elabBuiltinProduct2(DAE.CALL(Absyn.IDENT("product"),{exp_1},false,true,etp,DAE.NO_INLINE));
      then
        (cache,exp_2,DAE.PROP(tp,c),dae1);
  end matchcontinue;
end elabBuiltinProduct;

protected function elabBuiltinProduct2 " replaces product({a1,a2,...an})
with a1*a2*...*an} and
product([a11,a12,...,a1n;...,am1,am2,..amn]) with a11*a12*...*amn
"
input DAE.Exp inExp;
output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      DAE.ExpType ty;
      Boolean sc;
      list<DAE.Exp> expl;
      DAE.Exp e;
      list<list<tuple<DAE.Exp, Boolean>>> mexpl;
      Integer dim;
    case(DAE.CALL(_,{DAE.ARRAY(ty,sc,expl)},_,_,_,_)) equation
      e = Exp.makeProductLst(expl);
    then e;
    case(DAE.CALL(_,{DAE.MATRIX(ty,dim,mexpl)},_,_,_,_)) equation
      expl = Util.listMap(Util.listFlatten(mexpl), Util.tuple21);
      e = Exp.makeProductLst(expl);
    then e;

    case (e) then e;
  end matchcontinue;
end elabBuiltinProduct2;

protected function elabBuiltinPre "function: elabBuiltinPre
  This function elaborates the builtin operator pre.
  Input is the arguments to the pre operator and the environment, Env.Env."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp exp_1,exp_2;
      tuple<DAE.TType, Option<Absyn.Path>> tp;
      DAE.Const c;
      list<Env.Frame> env;
      Absyn.Exp exp;
      DAE.Dimension dim;
      Boolean impl;
      Ident s,el_str,pre_str;
      list<Absyn.Exp> expl;
      Env.Cache cache;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;

    /* an matrix? */
    case (cache,env,{exp},_,impl,pre) /* impl */
      local
        DAE.Type t,t2;
        DAE.ExpType etp,etp_org;
        list<DAE.Exp> expl_1;
        Boolean sc;
      equation
        (cache,exp_1 as DAE.MATRIX(_, _, _),DAE.PROP(t as (DAE.T_ARRAY(dim,tp),_),c),_,dae1) = elabExp(cache, env, exp, impl, NONE, true,pre);

        true = Types.isArray(t);

        t2 = Types.unliftArray(t);
        etp = Types.elabType(t2);

        exp_2 = elabBuiltinPreMatrix(DAE.CALL(Absyn.IDENT("pre"),{exp_1},false,true,etp,DAE.NO_INLINE),t2);
      then
        (cache,exp_2,DAE.PROP(t,c),dae1);

    /* an array? */
    case (cache,env,{exp},_,impl,pre)
      local
        DAE.Type t,t2;
        DAE.ExpType etp,etp_org;
        list<DAE.Exp> expl_1;
        Boolean sc;
      equation
        (cache,exp_1,DAE.PROP(t as (DAE.T_ARRAY(dim,tp),_),c),_,dae1) = elabExp(cache, env, exp, impl, NONE,true,pre);

        true = Types.isArray(t);

        t2 = Types.unliftArray(t);
        etp = Types.elabType(t2);

        (expl_1,sc) = elabBuiltinPre2(DAE.CALL(Absyn.IDENT("pre"),{exp_1},false,true,etp,DAE.NO_INLINE),t2);

        etp_org = Types.elabType(t);
        exp_2 = DAE.ARRAY(etp_org,  sc,  expl_1);
      then
        (cache,exp_2,DAE.PROP(t,c),dae1);

    /* a scalar? */
    case (cache,env,{exp},_,impl,pre) /* impl */
      local DAE.ExpType t; String str;
      equation
        (cache,exp_1,DAE.PROP(tp,c),_,dae1) = elabExp(cache,env, exp, impl, NONE,true,pre);
        (tp,_) = Types.flattenArrayType(tp);
        true = Types.basicType(tp);
        t = Types.elabType(tp);
        exp_2 = DAE.CALL(Absyn.IDENT("pre"),{exp_1},false,true,t,DAE.NO_INLINE);
      then
        (cache,exp_2,DAE.PROP(tp,c),dae1);
    case (cache,env,{exp},_,impl,pre)
      local DAE.Exp exp;
      equation
        (cache,exp,DAE.PROP(tp,c),_,_) = elabExp(cache,env, exp, impl, NONE,true,pre);
        (tp,_) = Types.flattenArrayType(tp);
        false = Types.basicType(tp);
        s = Exp.printExpStr(exp);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.OPERAND_BUILTIN_TYPE, {"pre",pre_str,s});
      then
        fail();
    case (cache,env,expl,_,_,pre)
      equation
        el_str = Exp.printListStr(expl, Dump.printExpStr, ", ");
        pre_str = PrefixUtil.printPrefixStr3(pre);
        s = Util.stringAppendList({"pre(",el_str,")"});
        Error.addMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS, {s,pre_str});
      then
        fail();
  end matchcontinue;
end elabBuiltinPre;

protected function elabBuiltinPre2 "function: elabBuiltinPre
  Help function for elabBuiltinPre, when type is array, send it here.
"
input DAE.Exp inExp;
input DAE.Type t;
output list<DAE.Exp> outExp;
output Boolean sc;
algorithm
  (outExp) := matchcontinue(inExp,t)
    local
      DAE.ExpType ty;
      Boolean sc;
      Integer i;
      list<DAE.Exp> expl,e;
      DAE.Exp exp_1;
      list<list<tuple<DAE.Exp, Boolean>>> matrixExpl, matrixExplPre;
      list<Boolean> boolList;

    case(DAE.CALL(expLst = {DAE.ARRAY(ty,sc,expl)}),t)
      equation
        (e) = makePreLst(expl, t);
      then (e,sc);
    case(DAE.CALL(expLst = {DAE.MATRIX(ty,i,matrixExpl)}),t)
      equation
        matrixExplPre = makePreMatrix(matrixExpl, t);
      then ({DAE.MATRIX(ty,i,matrixExplPre)},false);
    case (exp_1,t)
      equation
      then
        (exp_1 :: {},false);

  end matchcontinue;
end elabBuiltinPre2;

protected function elabBuiltinInStream "function: elabBuiltinInStream
  This function elaborates the builtin operator inStream.
  Input is the arguments to the inStream operator and the environment, Env.Env."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae) := matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp exp_1,exp_2;
      tuple<DAE.TType, Option<Absyn.Path>> tp;
      DAE.Const c;
      list<Env.Frame> env;
      Absyn.Exp exp;
      DAE.Dimension dim;
      Boolean impl;
      Ident s,el_str,pre_str;
      list<Absyn.Exp> expl;
      Env.Cache cache;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;
            
    /* a scalar? */
    case (cache,env,{exp},_,impl,pre) /* impl */
      local DAE.ExpType t; String str;
      equation
        (cache,exp_1,DAE.PROP(tp,c),_,dae1) = elabExp(cache,env, exp, impl, NONE,true,pre);
        (tp,_) = Types.flattenArrayType(tp);
        true = Types.basicType(tp);
        t = Types.elabType(tp);
        exp_2 = DAE.CALL(Absyn.IDENT("inStream"),{exp_1},false,true,t,DAE.NO_INLINE);
      then
        (cache,exp_2,DAE.PROP(tp,c),dae1);
    case (cache,env,{exp},_,impl,pre)
      local DAE.Exp exp;
      equation
        (cache,exp,DAE.PROP(tp,c),_,_) = elabExp(cache,env, exp, impl, NONE,true,pre);
        (tp,_) = Types.flattenArrayType(tp);
        false = Types.basicType(tp);
        s = Exp.printExpStr(exp);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.OPERAND_BUILTIN_TYPE, {"inStream",pre_str,s});
      then
        fail();
    case (cache,env,expl,_,_,pre)
      equation
        el_str = Exp.printListStr(expl, Dump.printExpStr, ", ");
        pre_str = PrefixUtil.printPrefixStr3(pre);
        s = Util.stringAppendList({"inStream(",el_str,")"});
        Error.addMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS, {s,pre_str});
      then
        fail();
  end matchcontinue;
end elabBuiltinInStream;

protected function elabBuiltinActualStream "function: elabBuiltinActualStream
  This function elaborates the builtin operator inStream.
  Input is the arguments to the inStream operator and the environment, Env.Env."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae) := matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp exp_1,exp_2;
      tuple<DAE.TType, Option<Absyn.Path>> tp;
      DAE.Const c;
      list<Env.Frame> env;
      Absyn.Exp exp;
      DAE.Dimension dim;
      Boolean impl;
      Ident s,el_str,pre_str;
      list<Absyn.Exp> expl;
      Env.Cache cache;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;
            
    /* a scalar? */
    case (cache,env,{exp},_,impl,pre) /* impl */
      local DAE.ExpType t; String str;
      equation
        (cache,exp_1,DAE.PROP(tp,c),_,dae1) = elabExp(cache,env, exp, impl, NONE,true,pre);
        (tp,_) = Types.flattenArrayType(tp);
        true = Types.basicType(tp);
        t = Types.elabType(tp);
        exp_2 = DAE.CALL(Absyn.IDENT("actualStream"),{exp_1},false,true,t,DAE.NO_INLINE);
      then
        (cache,exp_2,DAE.PROP(tp,c),dae1);
    case (cache,env,{exp},_,impl,pre)
      local DAE.Exp exp;
      equation
        (cache,exp,DAE.PROP(tp,c),_,_) = elabExp(cache,env, exp, impl, NONE,true,pre);
        (tp,_) = Types.flattenArrayType(tp);
        false = Types.basicType(tp);
        s = Exp.printExpStr(exp);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.OPERAND_BUILTIN_TYPE, {"actualStream",pre_str,s});
      then
        fail();
    case (cache,env,expl,_,_,pre)
      equation
        el_str = Exp.printListStr(expl, Dump.printExpStr, ", ");
        pre_str = PrefixUtil.printPrefixStr3(pre);
        s = Util.stringAppendList({"actualStream(",el_str,")"});
        Error.addMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS, {s,pre_str});
      then
        fail();
  end matchcontinue;
end elabBuiltinActualStream;

protected function elabBuiltinMMCGetField "Fetches fields from a boxed datatype:
Tuple: (a,b,c),2 => b
Option: SOME(x),1 => x
Metarecord: ut,0,\"field\" => ut[0].field - (first record in the record list of the uniontype - the field with the specified name)...
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp s1_1;
      DAE.ExpType tp;
      DAE.Const c;
      list<Env.Frame> env;
      Absyn.Exp s1,s2;
      Boolean impl;
      DAE.Type ty;
      Env.Cache cache;
      DAE.Properties prop;
      DAE.Const c;
      list<DAE.Exp> expList;
      list<DAE.Type> tys;
      Integer i;
      DAE.DAElist dae;
      Prefix pre;
    case (cache,env,{s1,Absyn.INTEGER(i)},{},impl,pre) /* Tuple */
      equation
        (cache,s1_1,DAE.PROP((DAE.T_METATUPLE(tys),_),c),_,dae) = elabExp(cache, env, s1, impl, NONE, true,pre);
        ty = listNth(tys,i-1);
        tp = Types.elabType(ty);
        s1_1 = DAE.CALL(Absyn.IDENT("mmc_get_field"), {s1_1, DAE.ICONST(i)}, false, true, tp,DAE.NO_INLINE);
        ty = Util.if_(Types.isBoxedType(ty), ty, (DAE.T_BOXED(ty),NONE));
      then
        (cache,s1_1,DAE.PROP(ty,c),dae);

    case (cache,env,{s1,Absyn.INTEGER(1)},{},impl,pre) /* Option */
      equation
        (cache,s1_1,DAE.PROP((DAE.T_METAOPTION(ty),_),c),_,dae) = elabExp(cache, env, s1, impl, NONE, true,pre);
        tp = Types.elabType(ty);
        s1_1 = DAE.CALL(Absyn.IDENT("mmc_get_field"), {s1_1, DAE.ICONST(1)}, false, true, tp,DAE.NO_INLINE);
        ty = Util.if_(Types.isBoxedType(ty), ty, (DAE.T_BOXED(ty),NONE));
      then
        (cache,s1_1,DAE.PROP(ty,c),dae);
    case (cache,env,{s1,Absyn.CREF(cref),Absyn.STRING(fieldName)},{},impl,pre) /* Uniontype */
      local
        String fieldName, str, utStr;
        Absyn.Path p, p2;
        list<DAE.Var> fields;
        DAE.Var var;
        Integer fieldNum;
        Absyn.ComponentRef cref;
      equation
        (cache,s1_1,DAE.PROP((DAE.T_UNIONTYPE(_),SOME(p)),c),_,dae) = elabExp(cache, env, s1, impl, NONE, true,pre);
        p2 = Absyn.crefToPath(cref);
        (cache,(DAE.T_METARECORD(fields = fields),_),env) = Lookup.lookupType(cache,env,p2,true);
        (var as DAE.TYPES_VAR(type_ = ty)) = Types.varlistLookup(fields, fieldName);
        fieldNum = Util.listPosition(var, fields)+2;
        tp = Types.elabType(ty);
        s1_1 = DAE.CALL(Absyn.IDENT("mmc_get_field"), {s1_1, DAE.ICONST(fieldNum)}, false, true, tp,DAE.NO_INLINE);
        ty = Util.if_(Types.isBoxedType(ty), ty, (DAE.T_BOXED(ty),NONE));
      then
        (cache,s1_1,DAE.PROP(ty,c),dae);
    case (_,_,_,_,_,_)
      equation
        Debug.fprintln("failtrace", "- elabBuiltinMMCGetField failed");
      then fail();
  end matchcontinue;
end elabBuiltinMMCGetField;

protected function elabBuiltinIfExp "cond,x,y => if cond then x else y"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp s0_1,s1_1,s2_1;
      DAE.ExpType tp;
      DAE.Const c;
      list<Env.Frame> env;
      Absyn.Exp s0,s1,s2;
      Boolean impl;
      DAE.Type ty,t1,t2;
      Env.Cache cache;
      DAE.Properties prop1,prop2;
      DAE.Const c1,c2,c0;
      list<DAE.Exp> expList;
      list<DAE.Type> tys;
      Integer i;
      DAE.DAElist dae,dae1,dae2,dae3;
      Prefix pre;

    case (cache,env,{s0,s1,s2},{},impl,pre)
      equation
        (cache,s0_1,DAE.PROP((DAE.T_BOOL(_),_),c0),_,dae1) = elabExp(cache, env, s0, impl, NONE, true,pre);
        (cache,s1_1,prop1,_,dae2) = elabExp(cache, env, s1, impl, NONE, impl,pre);
        (cache,s2_1,prop2,_,dae3) = elabExp(cache, env, s2, impl, NONE, impl,pre);
        t1 = Types.getPropType(prop1);
        t2 = Types.getPropType(prop2);
        (s1_1,t1) = Types.matchType(s1_1, t1, (DAE.T_BOXED((DAE.T_NOTYPE,NONE)),NONE), true);
        (s2_1,t2) = Types.matchType(s2_1, t2, (DAE.T_BOXED((DAE.T_NOTYPE,NONE)),NONE), true);
        t1 = Types.unboxedType(t1);
        t2 = Types.unboxedType(t2);
        ty = Types.superType(t1, t2);
        tp = Types.elabType(ty);
        ty = if_exp(Types.isBoxedType(ty), ty, (DAE.T_BOXED(ty),NONE));
        c1 = Types.propAllConst(prop1);
        c2 = Types.propAllConst(prop2);
        c = Types.constAnd(c1,c2);
        c = Types.constAnd(c,c0);
        s1_1 = DAE.CALL(Absyn.IDENT("if_exp"), {s0_1,s1_1,s2_1}, false, true, tp,DAE.NO_INLINE);
        dae = DAEUtil.joinDaeLst({dae1,dae2,dae3});
      then
        (cache,s1_1,DAE.PROP(ty,c),dae);
    case (_,_,_,_,_,_)
      equation
        Debug.fprintln("failtrace", "- elabBuiltinIfExp failed");
      then fail();
  end matchcontinue;
end elabBuiltinIfExp;

protected function elabBuiltinMMC_Uniontype_MetaRecord_Typedefs_Equal "mmc_uniontype_metarecord_typedef_equal(x,1,REC1) => bool"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      String s;
      DAE.Exp s1_1;
      DAE.Const c;
      list<Env.Frame> env;
      Absyn.Exp s1;
      Boolean impl;
      DAE.Type ty;
      Env.Cache cache;
      DAE.Const c;
      list<DAE.Exp> expList;
      Integer i,numFields;
      DAE.DAElist dae;
      Prefix pre;

    case (cache,env,{s1,Absyn.INTEGER(i),Absyn.INTEGER(numFields),Absyn.STRING(s)},{},impl,pre)
      equation
        (cache,s1_1,DAE.PROP((DAE.T_UNIONTYPE(_),_),c),_,dae) = elabExp(cache, env, s1, impl, NONE, true,pre);
        expList = {s1_1, DAE.ICONST(i), DAE.ICONST(numFields), DAE.SCONST(s)};
        s1_1 = DAE.CALL(Absyn.IDENT("mmc_uniontype_metarecord_typedef_equal"), expList, false, true, DAE.ET_BOOL,DAE.NO_INLINE);
      then
        (cache,s1_1,DAE.PROP(DAE.T_BOOL_DEFAULT,c),dae);
    case (_,_,_,_,_,_)
      equation
        Debug.fprintln("failtrace", "- elabBuiltinMMC_Uniontype_MetaRecord_Typedefs_Equal failed");
      then fail();
  end matchcontinue;
end elabBuiltinMMC_Uniontype_MetaRecord_Typedefs_Equal;

protected function elabBuiltinClock " => x"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp s1_1, s2_1;
      DAE.ExpType tp;
      DAE.Const c;
      list<Env.Frame> env;
      Absyn.Exp s1,s2,s;
      Boolean impl;
      DAE.Type ty;
      Env.Cache cache;
      DAE.Properties prop;
      DAE.Const c, c1, c2;
      list<DAE.Exp> expList;
      String fnName;
      Prefix pre;
    case (cache,env,{},{},impl,pre)
      equation
        s = Absyn.CALL(Absyn.CREF_IDENT("mmc_clock", {}), Absyn.FUNCTIONARGS({},{}));
        (cache,s1_1,prop,_,_) = elabExp(cache, env, s, impl, NONE, true,pre);
      then
        (cache,s1_1,prop,DAEUtil.emptyDae);

    case (_,_,_,_,_,_)
      equation
        Debug.fprintln("failtrace", "- elabBuiltinClock failed");
      then fail();
  end matchcontinue;
end elabBuiltinClock;

protected function makePreLst
"function: makePreLst
  Takes a list of expressions and makes a list of pre - expressions"
  input list<DAE.Exp> inExpLst;
  input DAE.Type t;
  output list<DAE.Exp> outExp;
algorithm
  (outExp):=
  matchcontinue (inExpLst,t)
      local
        DAE.Exp exp_1;
        list<DAE.Exp> expl_1;

    case((exp_1 :: expl_1),t)
      local
        DAE.Exp exp_2;
        list<DAE.Exp> expl_2;
        DAE.ExpType ttt;
        DAE.Type ttY;
      equation
        ttt = Types.elabType(t);
        exp_2 = DAE.CALL(Absyn.IDENT("pre"),{exp_1},false,true,ttt,DAE.NO_INLINE);
        (expl_2) = makePreLst(expl_1,t);
      then
        ((exp_2 :: expl_2));

      case ({},t)
        equation
      then
        ({});
  end matchcontinue;
end makePreLst;

protected function elabBuiltinPreMatrix
"function: elabBuiltinPreMatrix
 Help function for elabBuiltinPreMatrix, when type is matrix, send it here."
  input DAE.Exp inExp;
  input DAE.Type t;
  output DAE.Exp outExp;
algorithm
  (outExp) := matchcontinue(inExp,t)
    local
      DAE.ExpType ty;
      Boolean sc;
      Integer i;
      list<DAE.Exp> expl,e;
      DAE.Exp exp_1;
      list<list<tuple<DAE.Exp, Boolean>>> matrixExpl, matrixExplPre;
      list<Boolean> boolList;

    case(DAE.CALL(_,{DAE.MATRIX(ty,i,matrixExpl)},_,_,_,_),t)
      equation
        matrixExplPre = makePreMatrix(matrixExpl, t);
      then DAE.MATRIX(ty,i,matrixExplPre);

    case (exp_1,t) then exp_1;
  end matchcontinue;
end elabBuiltinPreMatrix;

protected function makePreMatrix
"function: makePreMatrix
  Takes a list of matrix expressions and makes a list of pre - matrix expressions"
  input list<list<tuple<DAE.Exp, Boolean>>> inMatrixExp;
  input DAE.Type t;
  output list<list<tuple<DAE.Exp, Boolean>>> outMatrixExp;
algorithm
  (outMatrixExp) := matchcontinue (inMatrixExp,t)
    local
      list<list<tuple<DAE.Exp, Boolean>>> lstLstExp, lstLstExpRest;
      list<tuple<DAE.Exp, Boolean>> lstExpBool, lstExpBoolPre;

    case ({},t) then {};
    case(lstExpBool::lstLstExpRest,t)
      equation
        lstExpBoolPre = mkLstPre(lstExpBool, t);
        lstLstExp = makePreMatrix(lstLstExpRest, t);
      then
        lstExpBoolPre ::lstLstExp;
  end matchcontinue;
end makePreMatrix;

function mkLstPre
  input  list<tuple<DAE.Exp, Boolean>> inLst;
  input  DAE.Type t;
  output list<tuple<DAE.Exp, Boolean>> outLst;
algorithm
  outLst := matchcontinue(inLst, t)
    local
      DAE.Exp exp; Boolean b;
      DAE.Exp expPre;
      DAE.ExpType ttt;
      list<tuple<DAE.Exp, Boolean>> rest;
    case ({}, t) then {};
    case ((exp,b)::rest, t)
      equation
        ttt = Types.elabType(t);
        exp = DAE.CALL(Absyn.IDENT("pre"),{exp},false,true,ttt,DAE.NO_INLINE);
        rest = mkLstPre(rest,t);
      then
        (exp, b)::rest;
  end matchcontinue;
end mkLstPre;

protected function elabBuiltinInitial "function: elabBuiltinInitial

  This function elaborates the builtin operator \'initial()\'
  Input is the arguments to the operator, which should be an empty list.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      list<Env.Frame> env;
      Boolean impl;
      Env.Cache cache;
      Prefix pre;
      String sp;
    case (cache,env,{},{},impl,_)
    then (cache,DAE.CALL(Absyn.IDENT("initial"),{},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),DAEUtil.emptyDae);

    case (cache,env,_,_,_,pre)
      equation
        sp = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS,
          {"initial takes no arguments",sp});
      then
        fail();
  end matchcontinue;
end elabBuiltinInitial;

protected function elabBuiltinTerminal "function: elabBuiltinTerminal

  This function elaborates the builtin operator \'terminal()\'
  Input is the arguments to the operator, which should be an empty list.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      list<Env.Frame> env;
      Boolean impl;
      Env.Cache cache;
      Prefix pre;
      String sp;
    case (cache,env,{},{},impl,_)
    then (cache,DAE.CALL(Absyn.IDENT("terminal"),{},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),DAEUtil.emptyDae);

    case (cache,env,_,_,impl,pre)
      equation
        sp = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS,
          {"terminal takes no arguments",sp});
      then
        fail();
  end matchcontinue;
end elabBuiltinTerminal;

protected function elabBuiltinArray "function: elabBuiltinArray

  This function elaborates the builtin operator \'array\'. For instance,
  array(1,4,6) which is the same as {1,4,6}.
  Input is the list of arguments to the operator, as Absyn.Exp list.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      list<DAE.Exp> exp_1,exp_2;
      list<DAE.Properties> typel;
      tuple<DAE.TType, Option<Absyn.Path>> tp,newtp;
      DAE.Const c;
      Integer len;
      DAE.ExpType newtp_1;
      Boolean scalar,impl;
      DAE.Exp exp;
      list<Env.Frame> env;
      list<Absyn.Exp> expl;
      Env.Cache cache;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;

    case (cache,env,expl,_,impl,pre)
      equation
        (cache,exp_1,typel,_,dae1) = elabExpList(cache,env, expl, impl, NONE,true,pre);
        (exp_2,DAE.PROP(tp,c)) = elabBuiltinArray2(exp_1, typel,pre);
        len = listLength(expl);
        newtp = (DAE.T_ARRAY(DAE.DIM_INTEGER(len),tp),NONE);
        newtp_1 = Types.elabType(newtp);
        scalar = Types.isArray(tp);
        exp = DAE.ARRAY(newtp_1,scalar,exp_1);
      then
        (cache,exp,DAE.PROP(newtp,c),dae1);
  end matchcontinue;
end elabBuiltinArray;

protected function elabBuiltinArray2 "function elabBuiltinArray2.

  Helper function to elab_builtin_array.
  Asserts that all types are of same dimensionality and of same
  builtin types.
"
  input list<DAE.Exp> inExpExpLst;
  input list<DAE.Properties> inTypesPropertiesLst;
  input Prefix inPrefix;
  output list<DAE.Exp> outExpExpLst;
  output DAE.Properties outProperties;
algorithm
  (outExpExpLst,outProperties):=
  matchcontinue (inExpExpLst,inTypesPropertiesLst,inPrefix)
    local
      list<DAE.Exp> expl,expl_1;
      list<DAE.Properties> tpl;
      list<tuple<DAE.TType, Option<Absyn.Path>>> tpl_1;
      DAE.Properties tp;
      Prefix pre;
      String sp;
    case (expl,tpl,pre)
      equation
        false = sameDimensions(tpl);
        sp = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.DIFFERENT_DIM_SIZE_IN_ARGUMENTS, {"array",sp});
      then
        fail();
    case (expl,tpl,_)
      equation
        tpl_1 = Util.listMap(tpl, Types.getPropType) "If first elt is Integer but arguments contain Real, convert all to Real" ;
        true = Types.containReal(tpl_1);
        (expl_1,tp) = elabBuiltinArray3(expl, tpl,
          DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_VAR()));
      then
        (expl_1,tp);
    case (expl,(tpl as (tp :: _)),_)
      equation
        (expl_1,tp) = elabBuiltinArray3(expl, tpl, tp);
      then
        (expl_1,tp);
  end matchcontinue;
end elabBuiltinArray2;

protected function elabBuiltinArray3 "function: elab_bultin_array3

  Helper function to elab_builtin_array.
"
  input list<DAE.Exp> inExpExpLst;
  input list<DAE.Properties> inTypesPropertiesLst;
  input DAE.Properties inProperties;
  output list<DAE.Exp> outExpExpLst;
  output DAE.Properties outProperties;
algorithm
  (outExpExpLst,outProperties):=
  matchcontinue (inExpExpLst,inTypesPropertiesLst,inProperties)
    local
      DAE.Properties tp,t1;
      DAE.Exp e1_1,e1;
      list<DAE.Exp> expl_1,expl;
      list<DAE.Properties> tpl;
    case ({},{},tp) then ({},tp);
    case ((e1 :: expl),(t1 :: tpl),tp)
      equation
        (e1_1,_) = Types.matchProp(e1, t1, tp, true);
        (expl_1,_) = elabBuiltinArray3(expl, tpl, tp);
      then
        ((e1_1 :: expl_1),t1);
  end matchcontinue;
end elabBuiltinArray3;

protected function elabBuiltinZeros "function: elabBuiltinZeros

  This function elaborates the builtin operator \'zeros(n)\'.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp e;
      DAE.Properties p;
      list<Env.Frame> env;
      list<Absyn.Exp> args;
      Boolean impl;
      Env.Cache cache;
      DAE.DAElist dae;
      Prefix pre;

    case (cache,env,args,_,impl,pre)
      equation
        (cache,e,p,dae) = elabBuiltinFill(cache,env, (Absyn.INTEGER(0) :: args),{}, impl,pre);
      then
        (cache,e,p,dae);
  end matchcontinue;
end elabBuiltinZeros;

protected function sameDimensions
  "This function returns true if all properties, containing types, have the same
  dimensions, otherwise false."
  input list<DAE.Properties> inProps;
  output Boolean res;

  list<DAE.Type> types;
  list<list<Integer>> dims;
algorithm
  types := Util.listMap(inProps, Types.getPropType);
  dims := Util.listMap(types, Types.getDimensionSizes);
  res := sameDimensions2(dims);
end sameDimensions;

protected function sameDimensionsExceptionDimX
  "This function returns true if all properties, containing types, have the same
  dimensions (except for dimension X), otherwise false."
  input list<DAE.Properties> inProps;
  input Integer dimException;
  output Boolean res;

  list<DAE.Type> types;
  list<list<Integer>> dims;
algorithm
  types := Util.listMap(inProps, Types.getPropType);
  dims := Util.listMap(types, Types.getDimensionSizes);
  dims := Util.listRemoveNth(dims, dimException);
  res := sameDimensions2(dims);
end sameDimensionsExceptionDimX;

protected function sameDimensions2
  input list<list<Integer>> inIntegerLstLst;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inIntegerLstLst)
    local
      list<list<Integer>> l,restelts;
      list<Integer> elts;
      Integer dim1,dim2;
    case (l)
      equation
        {} = Util.listFlatten(l);
      then
        true;
    case (l)
      equation
        elts = Util.listMap(l, Util.listFirst);
        restelts = Util.listMap(l, Util.listRest);
        true = sameDimensions3(elts);
        true = sameDimensions2(restelts);
      then
        true;
    case (_) then false;
  end matchcontinue;
end sameDimensions2;

protected function sameDimensions3
  "Helper function to sameDimensions2. Check that all dimensions in a list are equal."
  input list<Integer> inDims;
  output Boolean outRes;
algorithm
  outRes := matchcontinue (inDims)
    local
      Integer i1,i2;
      Boolean res,res2,res_1;
      list<Integer> rest;
    case ({}) then true;
    case ({_}) then true;
    case ({i1,i2}) then (i1 == i2);
    case ((i1 :: (i2 :: rest)))
      equation
        res = sameDimensions3((i2 :: rest));
        res2 = (i1 == i2);
        res_1 = boolAnd(res, res2);
      then
        res_1;
    case (_) then false;
  end matchcontinue;
end sameDimensions3;

protected function elabBuiltinOnes "function: elabBuiltinOnes

  This function elaborates on the builtin opeator \'ones(n)\'.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp e;
      DAE.Properties p;
      list<Env.Frame> env;
      list<Absyn.Exp> args;
      Boolean impl;
      Env.Cache cache;
      DAE.DAElist dae;
      Prefix pre;
    case (cache,env,args,_,impl,pre)
      equation
        (cache,e,p,dae) = elabBuiltinFill(cache,env, (Absyn.INTEGER(1) :: args), {}, impl,pre);
      then
        (cache,e,p,dae);
  end matchcontinue;
end elabBuiltinOnes;

protected function elabBuiltinMax "function: elabBuiltinMax

   This function elaborates on the builtin operator \'max(v1,v2)\'
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp arrexp_1,s1_1,s2_1;
      tuple<DAE.TType, Option<Absyn.Path>> ty,elt_ty;
      DAE.Const c,c1,c2;
      list<Env.Frame> env;
      Absyn.Exp arrexp,s1,s2;
      Boolean impl;
      Env.Cache cache;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;

    case (cache,env,{arrexp},_,impl,pre) /* max(vector) */
      local DAE.ExpType tp;
      equation
        (cache,arrexp_1,DAE.PROP(ty,c),_,dae1) = elabExp(cache,env, arrexp, impl, NONE,true,pre);
        elt_ty = Types.arrayElementType(ty);
        tp = Types.elabType(ty);
      then
        (cache,DAE.CALL(Absyn.IDENT("max"),{arrexp_1},false,true,tp,DAE.NO_INLINE),DAE.PROP(elt_ty,c),dae1);

        /*max(x,y) where x & y are Real scalars*/
    case (cache,env,{s1,s2},_,impl,pre)
      local DAE.ExpType tp; DAE.Type ty1,ty2;
      equation
        (cache,s1_1,DAE.PROP(ty1,c1),_,dae1) = elabExp(cache,env, s1, impl, NONE,true,pre);
        (cache,s2_1,DAE.PROP(ty2,c2),_,dae2) = elabExp(cache,env, s2, impl, NONE,true,pre);
        true = Types.isRealOrSubTypeReal(ty1) or Types.isRealOrSubTypeReal(ty2);
        (s1_1,ty) = Types.matchType(s1_1,ty1,DAE.T_REAL_DEFAULT,true);
        (s2_1,ty) = Types.matchType(s2_1,ty2,DAE.T_REAL_DEFAULT,true);
        c = Types.constAnd(c1, c2);
        tp = Types.elabType(ty);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,DAE.CALL(Absyn.IDENT("max"),{s1_1,s2_1},false,true,tp,DAE.NO_INLINE),DAE.PROP(ty,c),dae);

        /*max(x,y) where x & y are Integer scalars*/
    case (cache,env,{s1,s2},_,impl,pre)
      local DAE.ExpType tp; DAE.Type ty1,ty2;
      equation
        (cache,s1_1,DAE.PROP(ty1,c1),_,dae1) = elabExp(cache,env, s1, impl, NONE,true,pre);
        (cache,s2_1,DAE.PROP(ty2,c2),_,dae2) = elabExp(cache,env, s2, impl, NONE,true,pre);
        true = Types.isInteger(ty1) and Types.isInteger(ty2);
        c = Types.constAnd(c1, c2);
        tp = Types.elabType(ty1);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,DAE.CALL(Absyn.IDENT("max"),{s1_1,s2_1},false,true,tp,DAE.NO_INLINE),DAE.PROP(ty1,c),dae);
  end matchcontinue;
end elabBuiltinMax;

protected function elabBuiltinMin "function: elabBuiltinMin

  This function elaborates the builtin operator \'min(a,b)\'
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp arrexp_1,s1_1,s2_1;
      tuple<DAE.TType, Option<Absyn.Path>> ty,elt_ty;
      DAE.Const c,c1,c2;
      list<Env.Frame> env;
      Absyn.Exp arrexp,s1,s2;
      Boolean impl;
      Env.Cache cache;
      DAE.ExpType tp;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;
    case (cache,env,{arrexp},_,impl,pre) /* min(vector) */
      equation
        (cache,arrexp_1,DAE.PROP(ty,c),_,dae1) = elabExp(cache,env, arrexp, impl, NONE,true,pre);
        elt_ty = Types.arrayElementType(ty);
        tp = Types.elabType(ty);
      then
        (cache,DAE.CALL(Absyn.IDENT("min"),{arrexp_1},false,true,tp,DAE.NO_INLINE),DAE.PROP(elt_ty,c),dae1);

        /*min(x,y) where x & y are Real scalars*/
    case (cache,env,{s1,s2},_,impl,pre)
      local DAE.ExpType tp; DAE.Type ty1,ty2;
      equation
        (cache,s1_1,DAE.PROP(ty1,c1),_,dae1) = elabExp(cache,env, s1, impl, NONE,true,pre);
        (cache,s2_1,DAE.PROP(ty2,c2),_,dae2) = elabExp(cache,env, s2, impl, NONE,true,pre);
        true = Types.isRealOrSubTypeReal(ty1) or Types.isRealOrSubTypeReal(ty2);
        (s1_1,ty) = Types.matchType(s1_1,ty1,DAE.T_REAL_DEFAULT,true);
        (s2_1,ty) = Types.matchType(s2_1,ty2,DAE.T_REAL_DEFAULT,true);
        c = Types.constAnd(c1, c2);
        tp = Types.elabType(ty);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,DAE.CALL(Absyn.IDENT("min"),{s1_1,s2_1},false,true,tp,DAE.NO_INLINE),DAE.PROP(ty,c),dae);

        /*min(x,y) where x & y are Integer scalars*/
    case (cache,env,{s1,s2},_,impl,pre)
      local DAE.ExpType tp; DAE.Type ty1,ty2;
      equation
        (cache,s1_1,DAE.PROP(ty1,c1),_,dae1) = elabExp(cache,env, s1, impl, NONE,true,pre);
        (cache,s2_1,DAE.PROP(ty2,c2),_,dae2) = elabExp(cache,env, s2, impl, NONE,true,pre);
        true = Types.isInteger(ty1) and Types.isInteger(ty2);
        c = Types.constAnd(c1, c2);
        tp = Types.elabType(ty1);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,DAE.CALL(Absyn.IDENT("min"),{s1_1,s2_1},false,true,tp,DAE.NO_INLINE),DAE.PROP(ty1,c),dae);
  end matchcontinue;
end elabBuiltinMin;

protected function elabBuiltinFloor "function: elabBuiltinFloor

  This function elaborates on the builtin operator floor.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp s1_1;
      DAE.Const c;
      list<Env.Frame> env;
      Absyn.Exp s1;
      Boolean impl;
      DAE.Type ty;
      Env.Cache cache;
      DAE.Properties prop;
      DAE.DAElist dae;
      Prefix pre;

    case (cache,env,{s1},_,impl,pre)
      equation
        (cache,s1_1,prop,dae) = verifyBuiltInHandlerType(cache,env,{s1},impl,Types.isRealOrSubTypeReal,"floor",pre);
      then
        (cache,s1_1,prop,dae);
  end matchcontinue;
end elabBuiltinFloor;

protected function elabBuiltinCeil "function: elabBuiltinCeil

  This function elaborates on the builtin operator ceil.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp s1_1;
      DAE.Const c;
      list<Env.Frame> env;
      Absyn.Exp s1;
      Boolean impl;
      Env.Cache cache;
      DAE.Type ty;
      DAE.Properties prop;
      DAE.DAElist dae;
      Prefix pre;

    case (cache,env,{s1},_,impl,pre) /* impl */
      equation
        (cache,s1_1,prop,dae) = verifyBuiltInHandlerType(cache,env,{s1},impl,Types.isRealOrSubTypeReal,"ceil",pre);
      then
        (cache,s1_1,prop,dae);
  end matchcontinue;
end elabBuiltinCeil;

protected function elabBuiltinAbs "function: elabBuiltinAbs

  This function elaborates on the builtin operator abs
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp s1_1;
      DAE.Const c;
      list<Env.Frame> env;
      Absyn.Exp s1;
      Boolean impl;
      Env.Cache cache;
      list<DAE.Var> tpl;
      DAE.Type ty,ty2,ety;
      DAE.Properties prop;
      DAE.DAElist dae;
      Prefix pre;

    case (cache,env,{s1},_,impl,pre)
      equation
        (cache,s1_1,prop,dae) = verifyBuiltInHandlerType(cache,env,{s1},impl,Types.isRealOrSubTypeReal,"abs",pre);
      then
        (cache,s1_1,prop,dae);
    case (cache,env,{s1},_,impl,pre)
      equation
        (cache,s1_1,prop,dae) = verifyBuiltInHandlerType(cache,env,{s1},impl,Types.isIntegerOrSubTypeInteger,"abs",pre);
      then
        (cache,s1_1,prop,dae);
  end matchcontinue;
end elabBuiltinAbs;

protected function elabBuiltinSqrt "function: elabBuiltinSqrt

  This function elaborates on the builtin operator sqrt.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp s1_1;
      DAE.Const c;
      list<Env.Frame> env;
      Absyn.Exp s1;
      Boolean impl;
      Env.Cache cache;
      list<DAE.Var> tpl;
      DAE.Type ty,ty2;
      DAE.Properties prop;
      DAE.DAElist dae;
      Prefix pre;
    case (cache,env,{s1},_,impl,pre)
      equation
        (cache,s1_1,prop,dae) = verifyBuiltInHandlerType(cache,env,{s1},impl,Types.isRealOrSubTypeReal,"sqrt",pre);
      then
        (cache,s1_1,prop,dae);
    case (cache,env,{s1},_,impl,pre)
      equation
        (cache,s1_1,prop,dae) = verifyBuiltInHandlerType(cache,env,{s1},impl,Types.isIntegerOrSubTypeInteger,"sqrt",pre);
      then
        (cache,s1_1,prop,dae);
  end matchcontinue;
end elabBuiltinSqrt;

protected function elabBuiltinDiv "function: elabBuiltinDiv

  This function elaborates on the builtin operator div.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp s1_1,s2_1;
      DAE.Const c1,c2,c;
      list<Env.Frame> env;
      Absyn.Exp s1,s2;
      Boolean impl;
      Env.Cache cache;
      DAE.Type cty1,cty2;
      DAE.Properties prop;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;
      case (cache,env,{s1,s2},_,impl,pre)
      equation
        // TODO: this is not so nice. s1,s2 are elaborated twice, first in the calls below and then in elabCallArgs.
        (cache,s1_1,DAE.PROP(cty1,c1),_,_) = elabExp(cache,env, s1, impl, NONE,true,pre);
        (cache,s2_1,DAE.PROP(cty2,c2),_,_) = elabExp(cache,env, s2, impl, NONE,true,pre);
        cty1 = Types.arrayElementType(cty1);
        Types.integerOrReal(cty1);
        cty2 = Types.arrayElementType(cty2);
        Types.integerOrReal(cty2);
        (cache,s1_1,prop,dae1) = elabCallArgs(cache,env, Absyn.IDENT("div"), {s1,s2}, {}, impl, NONE,pre);
      then
        (cache,s1_1,prop,dae1);
  end matchcontinue;
end elabBuiltinDiv;

protected function elabBuiltinDelay "
Author BZ
TODO: implement,
fix types, so we can have integer as input
verify that the input is correct.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp s1_1,s2_1,s3_1;
      DAE.Const c1,c2,c3,c;
      DAE.Type expressionType,expressionType2,ty1,ty2,ty3;
      list<Env.Frame> env;
      Absyn.Exp s1,s2,s3;
      Boolean impl;
      Env.Cache cache;
      String errorString,sp;
      DAE.DAElist dae,dae1,dae2,dae3;
       Prefix pre;
    case (cache,env,{s1,s2},_,impl,pre)
      equation
        (cache,s1_1,DAE.PROP(ty1,c1),_,dae1) = elabExp(cache,env, s1, impl, NONE,true,pre);
        (cache,s2_1,DAE.PROP(ty2,c2),_,dae2) = elabExp(cache,env, s2, impl, NONE,true,pre);
        (s1_1,_) = Types.matchType(s1_1,ty1,DAE.T_REAL_DEFAULT,true);
        (s2_1,_) = Types.matchType(s2_1,ty2,DAE.T_REAL_DEFAULT,true);
        true = Types.isParameterOrConstant(c2);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,DAE.CALL(Absyn.IDENT("delay"),{s1_1,s2_1,s2_1},false,true,DAE.ET_REAL(),DAE.NO_INLINE),DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_VAR()),dae);

    // adrpo: allow delay(x, var) to be used but issue a warning. 
    //        used in Modelica.Electrical.Analog.Lines.TLine*
    case (cache,env,{s1,s2},_,impl,pre)
      equation
        (cache,s1_1,DAE.PROP(ty1,c1),_,dae1) = elabExp(cache,env, s1, impl, NONE,true,pre);
        (cache,s2_1,DAE.PROP(ty2,c2),_,dae2) = elabExp(cache,env, s2, impl, NONE,true,pre);
        (s1_1,_) = Types.matchType(s1_1,ty1,DAE.T_REAL_DEFAULT,true);
        (s2_1,_) = Types.matchType(s2_1,ty2,DAE.T_REAL_DEFAULT,true);
        // the value is not a parameter or constant but a variable 
        // that has an equation involving ONLY params/consts. 
        false = Types.isParameterOrConstant(c2);
        sp = PrefixUtil.printPrefixStr3(pre);        
        errorString = "delay(" +& Exp.printExpStr(s1_1) +& ", " +& Exp.printExpStr(s2_1) +& 
           ") where argument #2 has to be parameter or constant expression but is a variable";
        Error.addMessage(Error.WARNING_BUILTIN_DELAY, {sp,errorString});
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,DAE.CALL(Absyn.IDENT("delay"),{s1_1,s2_1,s2_1},false,true,DAE.ET_REAL(),DAE.NO_INLINE),DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_VAR()),dae);

    case (cache,env,{s1,s2,s3},_,impl,pre)
      equation
        (cache,s1_1,DAE.PROP(ty1,c1),_,dae1) = elabExp(cache,env, s1, impl, NONE,true,pre);
        (cache,s2_1,DAE.PROP(ty2,c2),_,dae2) = elabExp(cache,env, s2, impl, NONE,true,pre);
        (cache,s3_1,DAE.PROP(ty3,c3),_,dae3) = elabExp(cache,env, s3, impl, NONE,true,pre);
        (s1_1,_) = Types.matchType(s1_1,ty1,DAE.T_REAL_DEFAULT,true);
        (s2_1,_) = Types.matchType(s2_1,ty2,DAE.T_REAL_DEFAULT,true);
        (s3_1,_) = Types.matchType(s3_1,ty3,DAE.T_REAL_DEFAULT,true);
        true = Types.isParameterOrConstant(c3);
        dae = DAEUtil.joinDaeLst({dae1,dae2,dae3});
      then
        (cache,DAE.CALL(Absyn.IDENT("delay"),{s1_1,s2_1,s3_1},false,true,DAE.ET_REAL(),DAE.NO_INLINE),DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_VAR()),dae);
    
    // adrpo: allow delay(x, var, var) to be used but issue a warning. 
    //        used in Modelica.Electrical.Analog.Lines.TLine*
    case (cache,env,{s1,s2,s3},_,impl,pre)
      equation
        (cache,s1_1,DAE.PROP(ty1,c1),_,dae1) = elabExp(cache,env, s1, impl, NONE,true,pre);
        (cache,s2_1,DAE.PROP(ty2,c2),_,dae2) = elabExp(cache,env, s2, impl, NONE,true,pre);
        (cache,s3_1,DAE.PROP(ty3,c3),_,dae3) = elabExp(cache,env, s3, impl, NONE,true,pre);
        (s1_1,_) = Types.matchType(s1_1,ty1,DAE.T_REAL_DEFAULT,true);
        (s2_1,_) = Types.matchType(s2_1,ty2,DAE.T_REAL_DEFAULT,true);
        (s3_1,_) = Types.matchType(s3_1,ty3,DAE.T_REAL_DEFAULT,true);
        false = Types.isParameterOrConstant(c3);
        sp = PrefixUtil.printPrefixStr3(pre);
        errorString = "delay(" +& Exp.printExpStr(s1_1) +& ", " +& Exp.printExpStr(s2_1) +& 
        ", " +& Exp.printExpStr(s3_1) +& ") where argument #3 has to be parameter or constant expression but is a variable";
        Error.addMessage(Error.WARNING_BUILTIN_DELAY, {sp,errorString});        
        dae = DAEUtil.joinDaeLst({dae1,dae2,dae3});
      then
        (cache,DAE.CALL(Absyn.IDENT("delay"),{s1_1,s2_1,s3_1},false,true,DAE.ET_REAL(),DAE.NO_INLINE),DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_VAR()),dae);
    
    case(_,_,_,_,_,pre)
      equation
        errorString = " use of delay: \n delay(real, real, real as parameter/constant)\n or delay(real, real as parameter/constant).";
        sp = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.WARNING_BUILTIN_DELAY, {sp,errorString});
      then fail();
  end matchcontinue;
end elabBuiltinDelay;

protected function elabBuiltinMod
"function: elabBuiltinMod
  This function elaborates on the builtin operator mod."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp s1_1,s2_1;
      DAE.Const c1,c2,c;
      list<Env.Frame> env;
      Absyn.Exp s1,s2;
      Boolean impl;
      Env.Cache cache;
      DAE.Type cty1,cty2;
      DAE.Properties prop;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;
    case (cache,env,{s1,s2},_,impl,pre)
      equation
        (cache,s1_1,DAE.PROP(cty1,c1),_,_) = elabExp(cache,env, s1, impl, NONE,true,pre);
        (cache,s2_1,DAE.PROP(cty2,c2),_,_) = elabExp(cache,env, s2, impl, NONE,true,pre);
        cty1 = Types.arrayElementType(cty1);
        Types.integerOrReal(cty1);
        cty2 = Types.arrayElementType(cty2);
        Types.integerOrReal(cty2);
        (cache,s1_1,prop,dae) = elabCallArgs(cache,env, Absyn.IDENT("mod"), {s1,s2}, {}, impl, NONE,pre);
      then
        (cache,s1_1,prop,dae);
  end matchcontinue;
end elabBuiltinMod;

protected function elabBuiltinRem "function: elab_builtin_sqrt

  This function elaborates on the builtin operator rem.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp s1_1,s2_1;
      DAE.Const c1,c2,c;
      list<Env.Frame> env;
      Absyn.Exp s1,s2;
      Boolean impl;
      Env.Cache cache;
            DAE.Type cty1,cty2;
      DAE.Properties prop;
      DAE.DAElist dae;
      Prefix pre;

      case (cache,env,{s1,s2},_,impl,pre)
      equation
        (cache,s1_1,DAE.PROP(cty1,c1),_,_) = elabExp(cache,env, s1, impl, NONE,true,pre);
        (cache,s2_1,DAE.PROP(cty2,c2),_,_) = elabExp(cache,env, s2, impl, NONE,true,pre);
        cty1 = Types.arrayElementType(cty1);
        Types.integerOrReal(cty1);
        cty2 = Types.arrayElementType(cty2);
        Types.integerOrReal(cty2);
        (cache,s1_1,prop,dae) = elabCallArgs(cache,env, Absyn.IDENT("rem"), {s1,s2}, {}, impl, NONE,pre);
      then
        (cache,s1_1,prop,dae);
  end matchcontinue;
end elabBuiltinRem;

protected function elabBuiltinInteger
"function: elabBuiltinInteger
  This function elaborates on the builtin operator integer, which extracts
  the Integer value of a Real value."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp s1_1;
      DAE.Const c;
      list<Env.Frame> env;
      Absyn.Exp s1;
      Boolean impl;
      Env.Cache cache;
      DAE.Properties prop;
      DAE.DAElist dae;
      DAE.Type ty;
			String exp_str;
      Prefix pre;
    case (cache,env,{s1},_,impl,pre)
      equation
        (cache,s1_1,prop,dae) =
					verifyBuiltInHandlerType(cache,env,{s1},impl,Types.isIntegerOrRealOrSubTypeOfEither,"integer",pre);
      then
        (cache,s1_1,prop,dae);
  end matchcontinue;
end elabBuiltinInteger;

protected function elabBuiltinIntegerEnum
"function: elabBuiltinIntegerEnum
  This function elaborates on the builtin operator Integer for Enumerations, which extracts
  the Integer value of a Enumeration element."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp s1_1;
      DAE.Const c;
      list<Env.Frame> env;
      Absyn.Exp s1;
      Boolean impl;
      Env.Cache cache;
      DAE.Properties prop;
      DAE.DAElist dae;
      Prefix pre;
    case (cache,env,{s1},_,impl,pre)
      equation
        (cache,s1_1,prop,dae) = verifyBuiltInHandlerType(cache,env,{s1},impl,Types.isEnumeration,"Integer",pre);
      then
        (cache,s1_1,prop,dae);
  end matchcontinue;
end elabBuiltinIntegerEnum;

protected function elabBuiltinDiagonal "function: elabBuiltinDiagonal

  This function elaborates on the builtin operator diagonal, creating a
  matrix with a value of the diagonal. The other elements are zero.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.ExpType tp;
      Boolean impl;
      list<DAE.Exp> expl;
      DAE.Dimension dim;
      Integer dimension;
      tuple<DAE.TType, Option<Absyn.Path>> arrType,ty;
      DAE.Const c;
      DAE.Exp res,s1_1;
      list<Env.Frame> env;
      Absyn.Exp v1,s1;
      Env.Cache cache;
      DAE.DAElist dae;
      Prefix pre;
    case (cache,env,{v1},_,impl,pre)
      equation
        (cache, DAE.ARRAY(ty = tp, array = expl),
         DAE.PROP((DAE.T_ARRAY(arrayDim = dim, arrayType = arrType),NONE),c),
         _,dae) = elabExp(cache,env, v1, impl, NONE,true,pre);
        true = Exp.dimensionKnown(dim);
        ty = (DAE.T_ARRAY(dim,(DAE.T_ARRAY(dim,arrType),NONE)),NONE);
        tp = Types.elabType(ty);
        res = elabBuiltinDiagonal2(expl,tp);
      then
        (cache,res,DAE.PROP(ty,c),dae);

    case (cache,env,{s1},_,impl,pre)
      local
        DAE.ExpType tp;
      equation
        (cache,s1_1,
          DAE.PROP((DAE.T_ARRAY(arrayDim = dim, arrayType = arrType),NONE),c),
         _,dae) = elabExp(cache,env, s1, impl, NONE,true, pre);
        true = Exp.dimensionKnown(dim);
        ty = (DAE.T_ARRAY(dim,(DAE.T_ARRAY(dim,arrType),NONE)),NONE);
        tp = Types.elabType(ty);
      then
        (cache,DAE.CALL(Absyn.IDENT("diagonal"),{s1_1},false,true,tp,DAE.NO_INLINE),DAE.PROP(ty,c),dae);
    case (_,_,_,_,_,_)
      equation
        Debug.fprintln("failtrace", "- Static.elabBuiltinDiagonal: Couldn't elaborate diagonal()");
      then
        fail();
  end matchcontinue;
end elabBuiltinDiagonal;

protected function elabBuiltinDiagonal2 "function: elabBuiltinDiagonal2
  author: PA

  Tries to symbolically simplify diagonal.
  For instance diagonal({a,b}) => {a,0;0,b}
"
  input list<DAE.Exp> expl;
  input Exp.Type inType;
  output DAE.Exp res;
  Integer dim;
algorithm
  dim := listLength(expl);
  res := elabBuiltinDiagonal3(expl, 0, dim, inType);
end elabBuiltinDiagonal2;

protected function elabBuiltinDiagonal3
  input list<DAE.Exp> inExpExpLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  input Exp.Type inType;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExpExpLst1,inInteger2,inInteger3,inType)
    local
      DAE.ExpType tp,ty;
      Boolean sc;
      list<Boolean> scs;
      list<DAE.Exp> expl,expl_1,es;
      list<tuple<DAE.Exp, Boolean>> row;
      DAE.Exp e;
      Integer indx,dim,indx_1,mdim;
      list<list<tuple<DAE.Exp, Boolean>>> rows;
    case ({e},indx,dim,ty)
      equation
        tp = Exp.typeof(e);
        sc = Exp.typeBuiltin(tp);
        scs = Util.listFill(sc, dim);
        expl = Util.listFill(Exp.makeConstZero(tp), dim);
        expl_1 = Util.listReplaceAt(e, indx, expl);
        row = Util.listThreadTuple(expl_1, scs);
      then
        DAE.MATRIX(ty,dim,{row});
    case ((e :: es),indx,dim,ty)
      equation
        indx_1 = indx + 1;
        DAE.MATRIX(tp,mdim,rows) = elabBuiltinDiagonal3(es, indx_1, dim, ty);
        tp = Exp.typeof(e);
        sc = Exp.typeBuiltin(tp);
        scs = Util.listFill(sc, dim);
        expl = Util.listFill(Exp.makeConstZero(tp), dim);
        expl_1 = Util.listReplaceAt(e, indx, expl);
        row = Util.listThreadTuple(expl_1, scs);
      then
        DAE.MATRIX(ty,mdim,(row :: rows));
  end matchcontinue;
end elabBuiltinDiagonal3;

protected function elabBuiltinDifferentiate "function: elabBuiltinDifferentiate

  This function elaborates on the builtin operator differentiate,
  by deriving the Exp
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      list<Absyn.ComponentRef> cref_list1,cref_list2,cref_list;
      Interactive.InteractiveSymbolTable symbol_table;
      list<Env.Frame> gen_env,env;
      DAE.Exp s1_1,s2_1;
      DAE.Properties st;
      Absyn.Exp s1,s2;
      Boolean impl;
      Env.Cache cache;
      Prefix pre;

    case (cache,env,{s1,s2},_,impl,pre)
      equation
        cref_list1 = Absyn.getCrefFromExp(s1,true);
        cref_list2 = Absyn.getCrefFromExp(s2,true);
        cref_list = listAppend(cref_list1, cref_list2);
        symbol_table = absynCrefListToInteractiveVarList(cref_list, Interactive.emptySymboltable,
          DAE.T_REAL_DEFAULT);
        gen_env = Interactive.buildEnvFromSymboltable(symbol_table);
        (cache,s1_1,st,_,_) = elabExp(cache,gen_env, s1, impl, NONE,true,pre);
        (cache,s2_1,st,_,_) = elabExp(cache,gen_env, s2, impl, NONE,true,pre);
      then
        (cache,DAE.CALL(Absyn.IDENT("differentiate"),{s1_1,s2_1},false,true,DAE.ET_REAL(),DAE.NO_INLINE),st,DAEUtil.emptyDae);
    case (_,_,_,_,_,_)
      equation
        print(
          "#-- elab_builtin_differentiate: Couldn't elaborate differentiate()\n");
      then
        fail();
  end matchcontinue;
end elabBuiltinDifferentiate;

protected function elabBuiltinSimplify "function: elabBuiltinSimplify

  This function elaborates the simplify function.
  The call in mosh is: simplify(x+yx-x,\"Real\") if the variable should be
  Real or simplify(x+yx-x,\"Integer\") if the variable should be Integer
  This function is only for testing Exp.simplify
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      list<Absyn.ComponentRef> cref_list;
      Interactive.InteractiveSymbolTable symbol_table;
      list<Env.Frame> gen_env,env;
      DAE.Exp s1_1;
      DAE.Properties st;
      Absyn.Exp s1;
      Boolean impl;
      Env.Cache cache;
      Prefix pre;
    case (cache,env,{s1,Absyn.STRING(value = "Real")},_,impl,pre) /* impl */
      equation
        cref_list = Absyn.getCrefFromExp(s1,true);
        symbol_table = absynCrefListToInteractiveVarList(cref_list, Interactive.emptySymboltable,
          DAE.T_REAL_DEFAULT);
        gen_env = Interactive.buildEnvFromSymboltable(symbol_table);
        (cache,s1_1,st,_,_) = elabExp(cache,gen_env, s1, impl, NONE,true,pre);
      then
        (cache,DAE.CALL(Absyn.IDENT("simplify"),{s1_1},false,true,DAE.ET_REAL(),DAE.NO_INLINE),st,DAEUtil.emptyDae);
    case (cache,env,{s1,Absyn.STRING(value = "Integer")},_,impl,pre)
      equation
        cref_list = Absyn.getCrefFromExp(s1,true);
        symbol_table = absynCrefListToInteractiveVarList(cref_list, Interactive.emptySymboltable,
          DAE.T_INTEGER_DEFAULT);
        gen_env = Interactive.buildEnvFromSymboltable(symbol_table);
        (cache,s1_1,st,_,_) = elabExp(cache,gen_env, s1, impl, NONE,true,pre);
      then
        (cache,DAE.CALL(Absyn.IDENT("simplify"),{s1_1},false,true,DAE.ET_INT(),DAE.NO_INLINE),st,DAEUtil.emptyDae);
    case (_,_,_,_,_,_)
      equation
        print("#-- elab_builtin_simplify: Couldn't elaborate simplify()\n");
      then
        fail();
  end matchcontinue;
end elabBuiltinSimplify;

protected function absynCrefListToInteractiveVarList "function: absynCrefListToInteractiveVarList

  Creates Interactive variables from the list of component references. Each
  variable will get a value that is the AST code for the variable itself.
  This is used when calling differentiate, etc., to be able to evaluate
  a variable and still get the variable name.
"
  input list<Absyn.ComponentRef> inAbsynComponentRefLst;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input DAE.Type inType;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm
  outInteractiveSymbolTable:=
  matchcontinue (inAbsynComponentRefLst,inInteractiveSymbolTable,inType)
    local
      Interactive.InteractiveSymbolTable symbol_table,symbol_table_1,symbol_table_2;
      Absyn.Path path;
      Ident path_str;
      Absyn.ComponentRef cr;
      list<Absyn.ComponentRef> rest;
      tuple<DAE.TType, Option<Absyn.Path>> tp;
    case ({},symbol_table,_) then symbol_table;
    case ((cr :: rest),symbol_table,tp)
      equation
        path = Absyn.crefToPath(cr);
        path_str = Absyn.pathString(path);
        symbol_table_1 = Interactive.addVarToSymboltable(path_str, Values.CODE(Absyn.C_VARIABLENAME(cr)), tp,
          symbol_table);
        symbol_table_2 = absynCrefListToInteractiveVarList(rest, symbol_table_1, tp);
      then
        symbol_table_2;
    case (_,_,_)
      equation
        Debug.fprint("failtrace",
          "-absyn_cref_list_to_interactive_var_list failed\n");
      then
        fail();
  end matchcontinue;
end absynCrefListToInteractiveVarList;

protected function elabBuiltinNoevent "function: elabBuiltinNoevent

  The builtin operator noevent makes sure that events are not generated
  for the expression.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp exp_1;
      DAE.Properties prop;
      list<Env.Frame> env;
      Absyn.Exp exp;
      Boolean impl;
      Env.Cache cache;
      DAE.DAElist dae;
      Prefix pre;
    case (cache,env,{exp},_,impl,pre) /* impl */
      equation
        (cache,exp_1,prop,_,dae) = elabExp(cache,env, exp, impl, NONE,true,pre);
      then
        (cache,DAE.CALL(Absyn.IDENT("noEvent"),{exp_1},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),prop,dae);
  end matchcontinue;
end elabBuiltinNoevent;

protected function elabBuiltinEdge "function: elabBuiltinEdge

  This function handles the built in edge operator. If the operand is
  constant edge is always false.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp exp_1,exp_2;
      list<Env.Frame> env;
      Absyn.Exp exp;
      Boolean impl;
      DAE.Const c;
      Env.Cache cache;
      DAE.DAElist dae;
      Prefix pre;
      String ps;
    case (cache,env,{exp},_,impl,pre) /* Constness: C_VAR */
      equation
        (cache,exp_1,DAE.PROP((DAE.T_BOOL(_),_),DAE.C_VAR()),_,dae) = elabExp(cache, env, exp, impl, NONE,true,pre);
      then
        (cache,DAE.CALL(Absyn.IDENT("edge"),{exp_1},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),dae);

    case (cache,env,{exp},_,impl,pre)
      equation
        (cache,exp_1,DAE.PROP((DAE.T_BOOL(_),_),c),_,dae) = elabExp(cache, env, exp, impl, NONE,true,pre);
        exp_2 = ValuesUtil.valueExp(Values.BOOL(false));
      then
        (cache,exp_2,DAE.PROP(DAE.T_BOOL_DEFAULT,c),dae);
    case (_,env,_,_,_,pre)
      equation
        ps = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS, {"edge",ps});
      then
        fail();
  end matchcontinue;
end elabBuiltinEdge;

protected function elabBuiltinSign "function: elabBuiltinSign

  This function handles the built in sign operator.
  sign(v) is expanded into (if v>0 then 1 else if v < 0 then -1 else 0)
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp exp_1,exp_2;
      list<Env.Frame> env;
      list<Absyn.Exp> expl;
      Absyn.Exp exp;
      Boolean impl;
      DAE.Const c;
      DAE.Type tp1,ty2,ty;
      DAE.ExpType tp_1;
      DAE.Exp zero,one,ret;
      Env.Cache cache;
      DAE.Properties prop;
      DAE.DAElist dae;
      Prefix pre;

    case (cache,env,{exp},_,impl,pre) /* Argument to sign must be an Integer or Real expression */
      equation
        (cache,exp_1,DAE.PROP(tp1,c),_,_) = elabExp(cache,env, exp, impl, NONE,true,pre);
        ty2 = Types.arrayElementType(tp1);
        Types.integerOrReal(ty2);
        (cache,ret,(prop as DAE.PROP(ty,c)),dae) = elabCallArgs(cache,env, Absyn.IDENT("sign"), {exp}, {}, impl, NONE,pre);
      then
        (cache, ret, prop,dae);
  end matchcontinue;
end elabBuiltinSign;

protected function elabBuiltinDer
"function: elabBuiltinDer
  This function handles the built in der operator."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp e,exp_1;
      DAE.Properties prop;
      list<Env.Frame> env;
      Absyn.Exp exp;
      Absyn.ComponentRef cr;
      Boolean impl;
      DAE.Const c;
      list<Ident> lst;
      Ident s,sp;
      list<Absyn.Exp> expl;
      Env.Cache cache;
      DAE.DAElist dae;
      Prefix pre;

    // Replace der of constant Real, Integer or array of Real/Integer by zero(s) 
    case (cache,env,{exp},_,impl,pre)
      local
        DAE.Type ety,ty;
        list<DAE.Dimension> dims;
      equation
        (_,_,DAE.PROP(ety,c),_,_) = elabExp(cache, env, exp, impl, NONE,false,pre);
        failure(equality(c=DAE.C_VAR));
        dims = Types.getRealOrIntegerDimensions(ety);
        (e,ty) = Exp.makeZeroExpression(dims);
      then
        (cache,e,DAE.PROP(ty,DAE.C_CONST),DAE.DAE({}, DAE.AVLTREENODE(NONE, 0, NONE, NONE)));  

      /* use elab_call_args to also try vectorized calls */
    case (cache,env,{exp},_,impl,pre)
      local
        DAE.Type ety,restype,ty;
        list<tuple<DAE.TType, Option<Absyn.Path>>> typelist;
        DAE.Exp ee1;
      equation
        (_,ee1,DAE.PROP(ety,c),_,_) = elabExp(cache, env, exp, impl, NONE,true,pre);
        ety = Types.arrayElementType(ety);
        true = Types.isRealOrSubTypeReal(ety);
        (cache,e,(prop as DAE.PROP(ty,_)),dae) = elabCallArgs(cache,env, Absyn.IDENT("der"), {exp}, {}, impl, NONE,pre);
      then
        (cache,e,prop,dae);

    case (cache,env,{exp},_,impl,pre)
      local
        DAE.Type ety;
        String es3;
      equation
        (_,_,DAE.PROP(ety,_),_,_) = elabExp(cache,env, exp, impl, NONE,false,pre);
        false = Types.isRealOrSubTypeReal(ety);
        s = Dump.printExpStr(exp);
        sp = PrefixUtil.printPrefixStr3(pre);
        es3 = Types.unparseType(ety);
        Error.addMessage(Error.DERIVATIVE_NON_REAL, {s,sp,es3});
      then
        fail();
    case (cache,env,expl,_,_,pre)
      equation
        lst = Util.listMap(expl, Dump.printExpStr);
        s = Util.stringDelimitList(lst, ", ");
        sp = PrefixUtil.printPrefixStr3(pre);
        s = Util.stringAppendList({"der(",s,")"});
        Error.addMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS, {s,sp});
      then fail();
  end matchcontinue;
end elabBuiltinDer;

protected function elabBuiltinSample "function: elabBuiltinSample
  author: PA

  This function handles the built in sample operator.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp start_1,interval_1;
      tuple<DAE.TType, Option<Absyn.Path>> tp1,tp2;
      list<Env.Frame> env;
      Absyn.Exp start,interval;
      Boolean impl;
      Env.Cache cache;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;
      String sp;
    case (cache,env,{start,interval},_,impl,pre) /* impl */
      equation
        (cache,start_1,DAE.PROP(tp1,_),_,dae1) = elabExp(cache,env, start, impl, NONE,true,pre);
        (cache,interval_1,DAE.PROP(tp2,_),_,dae2) = elabExp(cache,env, interval, impl, NONE,true,pre);
        Types.integerOrReal(tp1);
        Types.integerOrReal(tp2);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,DAE.CALL(Absyn.IDENT("sample"),{start_1,interval_1},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),dae);

    case (cache,env,{start,interval},_,impl,pre)
      equation
        (cache,start_1,DAE.PROP(tp1,_),_,_) = elabExp(cache,env, start, impl, NONE,true,pre);
        failure(Types.integerOrReal(tp1));
        sp = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.ARGUMENT_MUST_BE_INTEGER_OR_REAL, {"First","sample", sp});
      then
        fail();
    case (cache,env,{start,interval},_,impl,pre)
      equation
        (cache,start_1,DAE.PROP(tp1,_),_,_) = elabExp(cache,env, interval, impl, NONE,true,pre);
        failure(Types.integerOrReal(tp1));
        sp = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.ARGUMENT_MUST_BE_INTEGER_OR_REAL, {"Second","sample", sp});
      then
        fail();
  end matchcontinue;
end elabBuiltinSample;

protected function elabBuiltinChange "function: elabBuiltinChange
  author: PA

  This function handles the built in change operator.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp exp_1;
      DAE.ComponentRef cr_1;
      DAE.Const c;
      tuple<DAE.TType, Option<Absyn.Path>> tp1;
      list<Env.Frame> env;
      Absyn.Exp exp;
      Absyn.ComponentRef cr;
      Boolean impl;
      Env.Cache cache;
      DAE.DAElist dae;
      Prefix pre;
      String sp;

    case (cache,env,{(exp as Absyn.CREF(componentRef = cr))},_,impl,pre) /* simple type, \'discrete\' variable */
      equation
        (cache,(exp_1 as DAE.CREF(cr_1,_)),DAE.PROP(tp1,_),_,dae) = elabExp(cache,env, exp, impl, NONE,true,pre);
        Types.simpleType(tp1);
        (cache,DAE.ATTR(_,_,_,SCode.DISCRETE(),_,_),_,_,_,_,_,_,_) = Lookup.lookupVar(cache,env, cr_1);
      then
        (cache,DAE.CALL(Absyn.IDENT("change"),{exp_1},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),dae);

    case (cache,env,{(exp as Absyn.CREF(componentRef = cr))},_,impl,pre) /* simple type, boolean or integer => discrete variable */
      equation
        (cache,(exp_1 as DAE.CREF(cr_1,_)),DAE.PROP(tp1,_),_,dae) = elabExp(cache,env, exp, impl, NONE,true,pre);
        Types.simpleType(tp1);
        Types.discreteType(tp1);
      then
        (cache,DAE.CALL(Absyn.IDENT("change"),{exp_1},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),dae);

    case (cache,env,{(exp as Absyn.CREF(componentRef = cr))},_,impl,pre) /* simple type, constant variability */
      equation
        (cache,(exp_1 as DAE.CREF(cr_1,_)),DAE.PROP(tp1,c),_,dae) = elabExp(cache,env, exp, impl, NONE,true,pre);
        true = Types.isParameterOrConstant(c);
        Types.simpleType(tp1);
      then
        (cache,DAE.CALL(Absyn.IDENT("change"),{exp_1},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),dae);

    case (cache,env,{(exp as Absyn.CREF(componentRef = cr))},_,impl,pre)
      equation
        (cache,(exp_1 as DAE.CREF(cr_1,_)),DAE.PROP(tp1,_),_,_) = elabExp(cache,env, exp, impl, NONE,true,pre);
        Types.simpleType(tp1);
        (cache,_,_,_,_,_,_,_,_) = Lookup.lookupVar(cache,env, cr_1);
        sp = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.ARGUMENT_MUST_BE_DISCRETE_VAR, {"First","change",sp});
      then
        fail();
    case (cache,env,{(exp as Absyn.CREF(componentRef = cr))},_,impl,pre)
      equation
        (cache,exp_1,DAE.PROP(tp1,_),_,_) = elabExp(cache,env, exp, impl, NONE,true,pre);
        failure(Types.simpleType(tp1));
        sp = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.TYPE_MUST_BE_SIMPLE, {"operand to change", sp});
      then
        fail();
    case (cache,env,{exp},_,impl,pre)
      equation
        sp = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.ARGUMENT_MUST_BE_VARIABLE, {"First","change", sp});
      then
        fail();
  end matchcontinue;
end elabBuiltinChange;

protected function elabBuiltinCat "function: elabBuiltinCat
  author: PA

  This function handles the built in cat operator.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp exp,dim_exp;
      DAE.Const const1,const2,const;
      Integer dim,num_matrices;
      list<DAE.Exp> matrices_1;
      list<DAE.Properties> props;
      tuple<DAE.TType, Option<Absyn.Path>> result_type,result_type_1;
      list<Env.Frame> env;
      list<Absyn.Exp> matrices;
      Boolean impl;
      DAE.Properties tp;
      list<Ident> lst;
      Ident s,str;
      Env.Cache cache;
      DAE.ExpType etp;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;
      String sp;
    case (cache,env,(dim :: matrices),_,impl,pre) /* impl */
      equation
        (cache,dim_exp,DAE.PROP((DAE.T_INTEGER(_),_),const1),_,dae1) = elabExp(cache,env, dim, impl, NONE,true,pre);
        (cache,Values.INTEGER(dim),_) = Ceval.ceval(cache,env, dim_exp, false, NONE, NONE, Ceval.MSG());
        (cache,matrices_1,props,_,dae2) = elabExpList(cache,env, matrices, impl, NONE,true,pre);
        true = sameDimensionsExceptionDimX(props,dim);
        const2 = elabArrayConst(props);
        const = Types.constAnd(const1, const2);
        num_matrices = listLength(matrices_1);
        (DAE.PROP(type_ = result_type) :: _) = props;
        result_type_1 = elabBuiltinCat2(result_type, dim, num_matrices);
        etp = Types.elabType(result_type_1);
        dae = DAEUtil.joinDaes(dae1,dae2);
        exp = DAE.CALL(Absyn.IDENT("cat"),(dim_exp :: matrices_1),false,true,etp,DAE.NO_INLINE);
      then
        (cache,exp,DAE.PROP(result_type_1,const),dae);
    case (cache,env,(dim :: matrices),_,impl,pre)
      local Absyn.Exp dim;
      equation
        (cache,dim_exp,tp,_,_) = elabExp(cache,env, dim, impl, NONE,true,pre);
        failure(DAE.PROP((DAE.T_INTEGER(_),_),const1) = tp);
        sp = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.ARGUMENT_MUST_BE_INTEGER, {"First","cat",sp});
      then
        fail();
    case (cache,env,(dim :: matrices),_,impl,pre)
      local Absyn.Exp dim;
      equation
        (cache,dim_exp,DAE.PROP((DAE.T_INTEGER(_),_),const1),_,_) = elabExp(cache,env, dim, impl, NONE,true,pre);
        (cache,matrices_1,props,_,_) = elabExpList(cache,env, matrices, impl, NONE,true,pre);
        false = sameDimensions(props);
        lst = Util.listMap((dim :: matrices), Dump.printExpStr);
        s = Util.stringDelimitList(lst, ", ");
        sp = PrefixUtil.printPrefixStr3(pre);
        str = Util.stringAppendList({"cat(",s,")"});
        Error.addMessage(Error.DIFFERENT_DIM_SIZE_IN_ARGUMENTS, {str,sp});
      then
        fail();
  end matchcontinue;
end elabBuiltinCat;

protected function elabBuiltinCat2 "function: elabBuiltinCat2

  Helper function to elab_builtin_cat. Updates the result type given
  the input type, number of matrices given to cat and dimension to concatenate
  along.
"
  input DAE.Type inType1;
  input Integer inInteger2;
  input Integer inInteger3;
  output DAE.Type outType;
algorithm
  outType:=
  matchcontinue (inType1,inInteger2,inInteger3)
    local
      Integer new_d,old_d,n_args,n_1,n;
      tuple<DAE.TType, Option<Absyn.Path>> tp,tp_1;
      Option<Absyn.Path> p;
      DAE.Dimension dim;
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM_INTEGER(integer = old_d),arrayType = tp),p),1,n_args) /* dim num_args */
      equation
        new_d = old_d*n_args;
      then
        ((DAE.T_ARRAY(DAE.DIM_INTEGER(new_d),tp),p));
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM_NONE), _), 1, _)
      equation
        true = OptManager.getOption("checkModel");
      then
        inType1;       
    case ((DAE.T_ARRAY(arrayDim = dim,arrayType = tp),p),n,n_args)
      equation
        n_1 = n - 1;
        tp_1 = elabBuiltinCat2(tp, n_1, n_args);
      then
        ((DAE.T_ARRAY(dim,tp_1),p));
  end matchcontinue;
end elabBuiltinCat2;

protected function elabBuiltinIdentity "function: elabBuiltinIdentity
  author: PA

  This function handles the built in identity operator.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp dim_exp;
      Integer size;
      list<Env.Frame> env;
      Absyn.Exp dim;
      Boolean impl;
      Env.Cache cache;
      DAE.DAElist dae,dae1,dae2;
      DAE.Type ty;
      DAE.ExpType ety;
      Prefix pre;
      DAE.Const c;
      Ceval.Msg msg;

    case (cache,env,{dim},_,impl,pre)
      equation
        (cache,dim_exp,DAE.PROP((DAE.T_INTEGER(_),_),c),_,dae1) = elabExp(cache,env, dim, impl, NONE,true,pre);
        true = Types.isParameterOrConstant(c);
        msg = Util.if_(OptManager.getOption("checkModel"), Ceval.NO_MSG, Ceval.MSG);
        (cache,Values.INTEGER(size),_) = Ceval.ceval(cache,env, dim_exp, false, NONE, NONE, msg);
        ty = (DAE.T_ARRAY(DAE.DIM_INTEGER(size),(DAE.T_ARRAY(DAE.DIM_INTEGER(size),DAE.T_INTEGER_DEFAULT),NONE)),NONE);
        ety = Types.elabType(ty);
      then
        (cache,DAE.CALL(Absyn.IDENT("identity"),{dim_exp},false,true,ety,DAE.NO_INLINE),DAE.PROP(ty,c),dae1);

    case (cache,env,{dim},_,impl,pre)
      equation
        (cache,dim_exp,DAE.PROP((DAE.T_INTEGER(_),_),DAE.C_VAR()),_,dae1) = elabExp(cache,env, dim, impl, NONE,true,pre);
        ty = (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_INTEGER_DEFAULT),NONE)),NONE);
        ety = Types.elabType(ty);
      then
        (cache,DAE.CALL(Absyn.IDENT("identity"),{dim_exp},false,true,ety,DAE.NO_INLINE),DAE.PROP(ty,DAE.C_VAR()),dae1);
        
    case (cache,env,{dim},_,impl,pre)
      equation
        true = OptManager.getOption("checkModel");
        (cache,dim_exp,DAE.PROP(type_ = (DAE.T_INTEGER(_), _)),_,dae1) = elabExp(cache,env,dim,impl,NONE,true,pre);
        ty = (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_INTEGER_DEFAULT),NONE)),NONE);
        ety = Types.elabType(ty);
      then
        (cache,DAE.CALL(Absyn.IDENT("identity"),{dim_exp},false,true,ety,DAE.NO_INLINE),DAE.PROP(ty,DAE.C_VAR),dae1);
        
    case (cache,env,{dim},_,impl,pre)
      equation
        print("-elab_builtin_identity failed\n");
      then
        fail();
  end matchcontinue;
end elabBuiltinIdentity;

protected function elabBuiltinIsRoot
"function: elabBuiltinIsRoot
  This function elaborates on the builtin operator Connections.isRoot."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      list<Env.Frame> env;
      Env.Cache cache;
      Boolean impl;
      Absyn.Exp exp0;
      DAE.Exp exp;
      Prefix pre;
    case (cache,env,{exp0},{},impl,pre) /* impl */
      equation
      (cache, exp, _, _,_) = elabExp(cache, env, exp0, false, NONE, false,pre);
      then
        (cache,
        DAE.CALL(Absyn.QUALIFIED("Connections", Absyn.IDENT("isRoot")), {exp},
             false, true, DAE.ET_BOOL,DAE.NO_INLINE),
        DAE.PROP(DAE.T_BOOL_DEFAULT, DAE.C_VAR));
  end matchcontinue;
end elabBuiltinIsRoot;

protected function elabBuiltinRooted
"author: adrpo
  This function handles the built-in rooted operator. (MultiBody).
  See more here: http://trac.modelica.org/Modelica/ticket/95"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae) := matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      list<Env.Frame> env;
      Env.Cache cache;
      Boolean impl;
      Absyn.Exp exp0;
      DAE.Exp exp;
      DAE.DAElist dae;
      Prefix pre;

    // adrpo: TODO! FIXME!
    //        this operator is not even specified in the specification!
    //        We should implement this as said here:
    //        http://trac.modelica.org/Modelica/ticket/95
    case (cache,env,{exp0},{},impl,pre) /* impl */
      equation
        (cache, exp, _, _,dae) = elabExp(cache, env, exp0, false, NONE, false,pre);
      then
        (cache, DAE.BCONST(true),DAE.PROP(DAE.T_BOOL_DEFAULT, DAE.C_CONST),dae);
  end matchcontinue;
end elabBuiltinRooted;

protected function elabBuiltinScalar "function: elab_builtin_
  author: PA

  This function handles the built in scalar operator.
  For example, scalar({1}) => 1 or scalar({a}) => a
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp e;
      tuple<DAE.TType, Option<Absyn.Path>> tp,scalar_tp,tp_1;
      DAE.Const c;
      list<Env.Frame> env;
      Boolean impl;
      Env.Cache cache;
      DAE.DAElist dae;
      Prefix pre;

    case (cache,env,{e},_,impl,pre) /*  scalar({a}) => a */
      equation
        (cache,DAE.ARRAY(_,_,{e}),DAE.PROP(tp,c),_,dae) = elabExp(cache,env, e, impl, NONE,true,pre);
        scalar_tp = Types.unliftArray(tp);
        Types.simpleType(scalar_tp);
      then
        (cache,e,DAE.PROP(scalar_tp,c),dae);

    case (cache,env,{e},_,impl,pre) /* scalar([a]) => a */
      equation
        (cache,DAE.MATRIX(_,_,{{(e,_)}}),DAE.PROP(tp,c),_,dae) = elabExp(cache,env, e, impl, NONE,true,pre);
        tp_1 = Types.unliftArray(tp);
        scalar_tp = Types.unliftArray(tp_1);
        Types.simpleType(scalar_tp);
      then
        (cache,e,DAE.PROP(scalar_tp,c),dae);
  end matchcontinue;
end elabBuiltinScalar;

protected function elabBuiltinSkew "
  author: PA

  This function handles the built in skew operator.

"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp e1,e2;
      tuple<DAE.TType, Option<Absyn.Path>> tp1,tp2;
      DAE.Const c1,c2,c;
      Boolean scalar1,scalar2;
      list<Env.Frame> env;
      Boolean impl;
      Env.Cache cache;
      Absyn.Exp v1,v2;
      list<DAE.Exp> expl1,expl2;
      list<list<tuple<DAE.Exp,Boolean>>> mexpl;
      DAE.ExpType etp1,etp2,etp,etp3;
      DAE.Type eltTp;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;

			//First, try symbolic simplification
    case (cache,env,{v1},_,impl,pre) equation
      (cache,DAE.ARRAY(etp1,scalar1,expl1),DAE.PROP(tp1,c1),_,dae1) = elabExp(cache,env, v1, impl, NONE,true,pre);
      {3} = Types.getDimensionSizes(tp1);
      mexpl = elabBuiltinSkew2(expl1,scalar1);
      tp1 = Types.liftArray(tp1,DAE.DIM_INTEGER(3));
      etp3 = Types.elabType(tp1);
      then
        (cache,DAE.MATRIX(etp3,3,mexpl),DAE.PROP(tp1,c1),dae1);

		//Fallback, use builtin function skew
    case (cache,env,{v1},_,impl,pre) equation
      (cache,e1,DAE.PROP(tp1,c1),_,dae1) = elabExp(cache,env, v1, impl, NONE,true,pre);
       {3} = Types.getDimensionSizes(tp1);
       etp = Exp.typeof(e1);
       eltTp = Types.arrayElementType(tp1);
       tp1 = Types.liftArray(Types.liftArray(eltTp,DAE.DIM_INTEGER(3)),DAE.DIM_INTEGER(3));
       then (cache,DAE.CALL(Absyn.IDENT("skew"),{e1},false,true,DAE.ET_ARRAY(etp,{DAE.DIM_INTEGER(3),DAE.DIM_INTEGER(3)}),DAE.NO_INLINE),
         		 DAE.PROP(tp1,DAE.C_VAR()),dae1);
  end matchcontinue;
end elabBuiltinSkew;

protected function elabBuiltinSkew2 "help function to elabBuiltinSkew"
	input list<DAE.Exp> v1;
	input  Boolean scalar;
	output list<list<tuple<DAE.Exp,Boolean>>> res;
algorithm
  res := matchcontinue(v1,scalar)
  local DAE.Exp x1,x2,x3,zero,a11,a12,a13,a21,a22,a23,a31,a32,a33;
    Boolean s;

 		// skew(x)
    case({x1,x2,x3},s) equation
        zero = Exp.makeConstZero(Exp.typeof(x1));
        a11 = zero;
        a12 = Exp.negate(x3);
        a13 = x2;
        a21 = x3;
        a22 = zero;
        a23 = Exp.negate(x1);
        a31 = Exp.negate(x2);
        a32 = x1;
        a33 = zero;

    then {{(a11,s),(a12,s),(a13,s)},{(a21,s),(a22,s),(a23,s)},{(a31,s),(a32,s),(a33,s)}};
  end matchcontinue;
end elabBuiltinSkew2;


protected function elabBuiltinCross "
  author: PA

  This function handles the built in cross operator.

"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp e1,e2;
      tuple<DAE.TType, Option<Absyn.Path>> tp1,tp2;
      DAE.Const c1,c2,c;
      Boolean scalar1,scalar2;
      list<Env.Frame> env;
      Boolean impl;
      Env.Cache cache;
      Absyn.Exp v1,v2;
      list<DAE.Exp> expl1,expl2,expl3;
      DAE.ExpType etp1,etp2,etp,etp3;
      DAE.Type eltTp;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;

			//First, try symbolic simplification
    case (cache,env,{v1,v2},_,impl,pre) equation
      (cache,DAE.ARRAY(etp1,scalar1,expl1),DAE.PROP(tp1,c1),_,dae1) = elabExp(cache,env, v1, impl, NONE,true,pre);
      (cache,DAE.ARRAY(etp2,scalar2,expl2),DAE.PROP(tp2,c2),_,dae2) = elabExp(cache,env, v2, impl, NONE,true,pre);
      // adrpo 2009-05-15: cross can fail if given a function with input Real[:]!
      //{3} = Types.getDimensionSizes(tp1);
      //{3} = Types.getDimensionSizes(tp2);
      expl3 = elabBuiltinCross2(expl1,expl2);
      c = Types.constAnd(c1,c2);
      etp3 = Types.elabType(tp1);
      dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,DAE.ARRAY(etp3,scalar1,expl3),DAE.PROP(tp1,c),dae);

		//Fallback, use builtin function cross
    case (cache,env,{v1,v2},_,impl,pre) equation
      (cache,e1,DAE.PROP(tp1,c1),_,dae1) = elabExp(cache,env, v1, impl, NONE,true,pre);
      (cache,e2,DAE.PROP(tp2,c2),_,dae2) = elabExp(cache,env, v2, impl, NONE,true,pre);
      // adrpo 2009-05-15: cross can fail if given a function with input Real[:]!
       //{3} = Types.getDimensionSizes(tp1);
       //{3} = Types.getDimensionSizes(tp2);
       etp = Exp.typeof(e1);
       eltTp = Types.arrayElementType(tp1);
       dae = DAEUtil.joinDaes(dae1,dae2);
       then (cache,DAE.CALL(Absyn.IDENT("cross"),{e1,e2},false,true,etp,DAE.NO_INLINE),
         		 DAE.PROP((DAE.T_ARRAY(DAE.DIM_INTEGER(3),eltTp),NONE),DAE.C_VAR()),dae);
  end matchcontinue;
end elabBuiltinCross;

public function elabBuiltinCross2 "help function to elabBuiltinCross. Public since it used by Exp.simplify1"
	input list<DAE.Exp> v1;
	input list<DAE.Exp> v2;
	output list<DAE.Exp> res;
algorithm
  res := matchcontinue(v1,v2)
  local DAE.Exp x1,x2,x3,y1,y2,y3,p1,p2,r1,r2,r3;

 		// {x[2]*y[3]-x[3]*y[2],x[3]*y[1]-x[1]*y[3],x[1]*y[2]-x[2]*y[1]}
    case({x1,x2,x3},{y1,y2,y3}) equation
    	  r1 = Exp.makeDiff(Exp.makeProductLst({x2,y3}),Exp.makeProductLst({x3,y2}));
    	  r2 = Exp.makeDiff(Exp.makeProductLst({x3,y1}),Exp.makeProductLst({x1,y3}));
    	  r3 = Exp.makeDiff(Exp.makeProductLst({x1,y2}),Exp.makeProductLst({x2,y1}));
    then {r1,r2,r3};
  end matchcontinue;
end elabBuiltinCross2;


protected function elabBuiltinString "
  author: PA

  This function handles the built-in String operator.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp exp;
      tuple<DAE.TType, Option<Absyn.Path>> tp,arr_tp;
      DAE.Const c,const;
      list<DAE.Const> constlist;
      DAE.ExpType tp_1,etp;
      list<Env.Frame> env;
      Absyn.Exp e;
      Boolean impl,scalar;
      list<DAE.Exp> expl,expl_1,args_1;
      list<Integer> dims;
      Env.Cache cache;
      DAE.Properties prop;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      list<Slot> slots,newslots;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;
    case (cache,env,args as e::_,nargs,impl,pre)
      equation
        (cache,exp,DAE.PROP(tp,c),_,dae1) = elabExp(cache,env, e, impl, NONE,true,pre);
				/* Create argument slots for String function */
        slots = {SLOT(("x",tp),false,NONE,{}),
        				 SLOT(("minimumLength",DAE.T_INTEGER_DEFAULT),false,SOME(DAE.ICONST(0)),{}),
        				 SLOT(("leftJustified",DAE.T_BOOL_DEFAULT),false,SOME(DAE.BCONST(true)),{}),
        				 SLOT(("significantDigits",DAE.T_INTEGER_DEFAULT),false,SOME(DAE.ICONST(6)),{})};
        (cache,args_1,newslots,constlist,_,dae2) = elabInputArgs(cache,env, args, nargs, slots, true/*checkTypes*/ ,impl, {}, pre);
        c = Util.listReduce(constlist, Types.constAnd);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
				(cache,
				DAE.CALL(Absyn.IDENT("String"),args_1,false,true,DAE.ET_STRING(),DAE.NO_INLINE),
				DAE.PROP(DAE.T_STRING_DEFAULT,c),dae);
  end matchcontinue;
end elabBuiltinString;

protected function elabBuiltinLinspace "
  author: PA

  This function handles the built-in linspace function.
  e.g. linspace(1,3,3) => {1,2,3}
       linspace(0,1,5) => {0,0.25,0.5,0.75,1.0}
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> expl;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean impl;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,expl,inNamedArg,impl,inPrefix)
      local Absyn.Exp x,y,n;
        DAE.Exp x1,y1,n1,x2,y2; DAE.Type tp1,tp2,tp3,tp11,tp22; DAE.Const c1,c2,c3,c;
        Integer size;
        Env.Cache cache; Env.Env env;
        DAE.DAElist dae,dae1,dae2,dae3;
      Prefix pre;

        /* linspace(x,y,n) where n is constant or parameter */
    case (cache,env,{x,y,n},_,impl,pre) equation
      (cache,x1,DAE.PROP(tp1,c1),_,dae1) = elabExp(cache,env, x, impl, NONE,true,pre);
      (cache,y1,DAE.PROP(tp2,c2),_,dae2) = elabExp(cache,env, y, impl, NONE,true,pre);
      (x2,tp11) = Types.matchType(x1,tp1,DAE.T_REAL_DEFAULT,true);
      (y2,tp22) = Types.matchType(y1,tp2,DAE.T_REAL_DEFAULT,true);
      (cache,n1,DAE.PROP(tp3 as (DAE.T_INTEGER(_),_),c3),_,dae3) = elabExp(cache,env, n, impl, NONE,true,pre);
      true = Types.isParameterOrConstant(c3);
      (cache,Values.INTEGER(size),_) = Ceval.ceval(cache,env, n1, false, NONE, NONE, Ceval.MSG());
      c = Types.constAnd(c1,c2);
      dae = DAEUtil.joinDaeLst({dae1,dae2,dae3});
    then (cache, DAE.CALL(Absyn.IDENT("linspace"),{x2,y2,n1},false,true,DAE.ET_ARRAY(DAE.ET_REAL(),{DAE.DIM_INTEGER(size)}),DAE.NO_INLINE), 
      DAE.PROP((DAE.T_ARRAY(DAE.DIM_INTEGER(size),tp11),NONE),c),dae);

    /* linspace(x,y,n) where n is variable time expression */
    case (cache,env,{x,y,n},_,impl,pre) equation
      (cache,x1,DAE.PROP(tp1,c1),_,dae1) = elabExp(cache,env, x, impl, NONE,true,pre);
      (cache,y1,DAE.PROP(tp2,c2),_,dae2) = elabExp(cache,env, y, impl, NONE,true,pre);
      (x2,tp11) = Types.matchType(x1,tp1,DAE.T_REAL_DEFAULT,true);
      (y2,tp22) = Types.matchType(y1,tp2,DAE.T_REAL_DEFAULT,true);
      (cache,n1,DAE.PROP(tp3 as (DAE.T_INTEGER(_),_),c3),_,dae3) = elabExp(cache,env, n, impl, NONE,true,pre);
      false = Types.isParameterOrConstant(c3);
      c = Types.constAnd(c1,Types.constAnd(c2,c3));
      dae = DAEUtil.joinDaeLst({dae1,dae2,dae3});
    then (cache, DAE.CALL(Absyn.IDENT("linspace"),{x2,y2,n1},false,true,DAE.ET_ARRAY(DAE.ET_REAL(),{DAE.DIM_NONE}),DAE.NO_INLINE),
      DAE.PROP((DAE.T_ARRAY(DAE.DIM_NONE,tp11),NONE),c),dae);
  end matchcontinue;
end elabBuiltinLinspace;

protected function elabBuiltinVector "function: elabBuiltinVector
  author: PA

  This function handles the built in vector operator.
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix)
    local
      DAE.Exp exp;
      DAE.Type tp,arr_tp;
      DAE.Const c;
      DAE.ExpType tp_1,etp;
      list<Env.Frame> env;
      Absyn.Exp e;
      Boolean impl,scalar;
      list<DAE.Exp> expl,expl_1,expl_2;
      list<list<tuple<DAE.Exp, Boolean>>> explm;
      String s,str;
      list<Integer> dims;
      Env.Cache cache;
      DAE.DAElist dae;
      Prefix pre;

    case (cache,env,{e},_,impl,pre) /* vector(scalar) = {scalar} */
      equation
        (cache,exp,DAE.PROP(tp,c),_,dae) = elabExp(cache,env, e, impl, NONE,true,pre);
        Types.simpleType(tp);
        arr_tp = Types.liftArray(tp, DAE.DIM_INTEGER(1));
        tp_1 = Types.elabType(arr_tp);
      then
        (cache,DAE.ARRAY(tp_1,true,{exp}),DAE.PROP(arr_tp,c),dae);

    case (cache,env,{e},_,impl,pre) /* vector(array of scalars) = array of scalars */
      equation
        (cache,DAE.ARRAY(etp,scalar,expl),DAE.PROP(tp,c),_,dae) = elabExp(cache,env, e, impl, NONE,true,pre);
        1 = Types.ndims(tp);
      then
        (cache,DAE.ARRAY(etp,scalar,expl),DAE.PROP(tp,c),dae);

    case (cache,env,{e},_,impl,pre) /* vector of multi dimensional array, at most one dim > 1 */
      local
        DAE.Type tp_1;
        Integer dim;
      equation
        (cache,DAE.ARRAY(_,_,expl),DAE.PROP(tp,c),_,dae) = elabExp(cache,env, e, impl, NONE,true,pre);
        tp_1 = Types.arrayElementType(tp);
        dims = Types.getDimensionSizes(tp);
				checkBuiltinVectorDims(e, env, dims,pre);
				expl_1 = flattenArray(expl);
				dim = listLength(expl_1);
				tp = (DAE.T_ARRAY(DAE.DIM_INTEGER(dim), tp_1), NONE);
        etp = Types.elabType(tp);
      then
        (cache,DAE.ARRAY(etp,true,expl_1),DAE.PROP(tp,c),dae);

      case (cache,env,{e},_,impl,pre) /* vector of multi dimensional matrix, at most one dim > 1 */
      local
        tuple<DAE.TType, Option<Absyn.Path>> tp_1;
        Integer dimtmp;
      equation
        (cache,DAE.MATRIX(_,_,explm),DAE.PROP(tp,c),_,dae) = elabExp(cache,env, e, impl, NONE,true,pre);
        tp_1 = Types.arrayElementType(tp);
        dims = Types.getDimensionSizes(tp);
        expl_2 = Util.listMap(Util.listFlatten(explm),Util.tuple21);
        expl_1 = elabBuiltinVector2(expl_2, dims);
        dimtmp = listLength(expl_1);
        tp_1 = Types.liftArray(tp_1, DAE.DIM_INTEGER(dimtmp));
        etp = Types.elabType(tp_1);
      then
        (cache,DAE.ARRAY(etp,true,expl_1),DAE.PROP(tp_1,c),dae);
  end matchcontinue;
end elabBuiltinVector;

protected function checkBuiltinVectorDims
	input Absyn.Exp expr;
	input Env.Env env;
	input list<Integer> dimensions;
	input Prefix inPrefix;
algorithm
	_ := matchcontinue(expr, env, dimensions,inPrefix)
		local
			Integer dims_larger_than_one;
			Prefix pre;
		case (_, _, _,_)
			equation
				dims_larger_than_one = countDimsLargerThanOne(dimensions);
				(dims_larger_than_one > 1) = false;
			then ();
		case (_, _, _, pre)
			local
				String arg_str, scope_str, dim_str, pre_str;
			equation
				scope_str = Env.printEnvPathStr(env);
				arg_str = "vector(" +& Dump.printExpStr(expr) +& ")";
				dim_str = "[" +& Util.stringDelimitList(Util.listMap(dimensions, intString), ", ") +& "]";
				pre_str = PrefixUtil.printPrefixStr3(pre);
				Error.addMessage(Error.BUILTIN_VECTOR_INVALID_DIMENSIONS, {scope_str, pre_str, dim_str, arg_str});
			then fail();
	end matchcontinue;
end checkBuiltinVectorDims;

protected function countDimsLargerThanOne
	input list<Integer> dimensions;
	output Integer dimsLargerThanOne;
algorithm
	dimsLargerThanOne := matchcontinue(dimensions)
		local
			Integer dim, dims_larger_than_one;
			list<Integer> rest_dims;
		case ({}) then 0;
		case ((dim :: rest_dims))
			equation
				(dim > 1) = true;
				dims_larger_than_one = 1 + countDimsLargerThanOne(rest_dims);
			then
				dims_larger_than_one;
		case ((dim :: rest_dims))
			equation
				dims_larger_than_one = countDimsLargerThanOne(rest_dims);
			then dims_larger_than_one;
	end matchcontinue;
end countDimsLargerThanOne;

protected function flattenArray
	input list<DAE.Exp> arr;
	output list<DAE.Exp> flattenedExpl;
algorithm
	flattenedExpl := matchcontinue(arr)
		local
			DAE.Exp e;
			list<DAE.Exp> expl, expl2, rest_expl;
		case ({}) then {};
		case ((DAE.ARRAY(array = expl) :: rest_expl))
			equation
				expl = flattenArray(expl);
				expl2 = flattenArray(rest_expl);
				expl = listAppend(expl, expl2);
			then expl;
		case ((DAE.MATRIX(scalar = {{(e,_)}}) :: rest_expl))
			equation
				expl = flattenArray(rest_expl);
			then
				(e :: expl);
		case ((e :: expl))
			equation
				expl = flattenArray(expl);
			then
				(e :: expl);
	end matchcontinue;
end flattenArray;

protected function dimensionListMaxOne "function: elabBuiltinVector2

  Helper function to elab_builtin_vector.
"
  input list<Integer> inIntegerLst;
  output Integer dimensions;
algorithm
  outExpExpLst:=
  matchcontinue (inIntegerLst)
    local
      Integer dim;
      list<Integer> dims;
      case ({})
        then
          0;
      case ((dim :: dims))
        equation
          (dim > 1) = true;
          Error.addMessage(Error.ERROR_FLATTENING, {"Vector may only be 1x2 or 2x1 dimensions"});
        then
          10;
      case((dim :: dims))
        local
         Integer x;
        equation
        x = dimensionListMaxOne(dims);
        then
          x;
  end matchcontinue;
end dimensionListMaxOne;

protected function elabBuiltinVector2 "function: elabBuiltinVector2

  Helper function to elabBuiltinVector, for matrix expressions.
"
  input list<DAE.Exp> inExpExpLst;
  input list<Integer> inIntegerLst;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inExpExpLst,inIntegerLst)
    local
      list<DAE.Exp> expl_1,expl;
      Integer dim;
      list<Integer> dims;
      DAE.Exp e;
    case (expl,(dim :: dims))
      equation
        (dim > 1) = true;
        (1 > dimensionListMaxOne(dims)) = true;
	      then
        expl;
    case (expl,(dim :: dims))
      equation
        (1 > dimensionListMaxOne(dims) ) = false;
        expl_1 = elabBuiltinVector2(expl, dims);
      then
        expl_1;
  end matchcontinue;
end elabBuiltinVector2;

public function elabBuiltinHandlerGeneric "function: elabBuiltinHandlerGeneric

  This function dispatches the elaboration of special builtin operators by
  returning the appropriate function, see also elab_builtin_handler.
  These special builtin operators can not be represented in the
  environment since they must be generated on the fly, given a generated
  type.
"
  input Ident inIdent;
  output FuncTypeEnv_EnvAbsyn_ExpLstBooleanToExp_ExpTypes_Properties outFuncTypeEnvEnvAbsynExpLstBooleanToExpExpTypesProperties;
  partial function FuncTypeEnv_EnvAbsyn_ExpLstBooleanToExp_ExpTypes_Properties
	  input Env.Cache inCache;
    input Env.Env inEnv;
    input list<Absyn.Exp> inAbsynExpLst;
    input list<Absyn.NamedArg> inNamedArg;
    input Boolean inBoolean;
    input Prefix.Prefix inPrefix;
    output Env.Cache outCache;
    output DAE.Exp outExp;
    output DAE.Properties outProperties;
    output DAE.DAElist outDae;
  end FuncTypeEnv_EnvAbsyn_ExpLstBooleanToExp_ExpTypes_Properties;
algorithm
  outFuncTypeEnvEnvAbsynExpLstBooleanToExpExpTypesProperties:=
  matchcontinue (inIdent)
    case "cardinality" then elabBuiltinCardinality;
  end matchcontinue;
end elabBuiltinHandlerGeneric;

public function elabBuiltinHandler "function: elabBuiltinHandler

  This function dispatches the elaboration of builtin operators by
  returning the appropriate function. When a new builtin operator is
  added, a new rule has to be added to this function.
"
  input Ident inIdent;
  output FuncTypeEnv_EnvAbsyn_ExpLstBooleanToExp_ExpTypes_Properties outFuncTypeEnvEnvAbsynExpLstBooleanToExpExpTypesProperties;
  partial function FuncTypeEnv_EnvAbsyn_ExpLstBooleanToExp_ExpTypes_Properties
	  input Env.Cache inCache;
    input Env.Env inEnv;
    input list<Absyn.Exp> inAbsynExpLst;
    input list<Absyn.NamedArg> inNamedArg;
    input Boolean inBoolean;
    input Prefix inPrefix;
    output Env.Cache outCache;
    output DAE.Exp outExp;
    output DAE.Properties outProperties;
    output DAE.DAElist outDae;
  end FuncTypeEnv_EnvAbsyn_ExpLstBooleanToExp_ExpTypes_Properties;
algorithm
  outFuncTypeEnvEnvAbsynExpLstBooleanToExpExpTypesProperties:=
  matchcontinue (inIdent)
    case "delay" then elabBuiltinDelay;
    case "smooth" then elabBuiltinSmooth;
    case "size" then elabBuiltinSize;  /* impl */
    case "ndims" then elabBuiltinNDims;
    case "zeros" then elabBuiltinZeros;
    case "ones" then elabBuiltinOnes;
    case "fill" then elabBuiltinFill;
    case "max" then elabBuiltinMax;
    case "min" then elabBuiltinMin;
    case "transpose" then elabBuiltinTranspose;
    case "array" then elabBuiltinArray;
    case "sum" then elabBuiltinSum;
    case "product" then elabBuiltinProduct;
    case "pre" then elabBuiltinPre;
    case "initial" then elabBuiltinInitial;
    case "terminal" then elabBuiltinTerminal;
    case "floor" then elabBuiltinFloor;
    case "ceil" then elabBuiltinCeil;
    case "abs" then elabBuiltinAbs;
    case "sqrt" then elabBuiltinSqrt;
    case "div" then elabBuiltinDiv;
    case "integer" then elabBuiltinInteger;
    case "mod" then elabBuiltinMod;
    case "rem" then elabBuiltinRem;
    case "diagonal" then elabBuiltinDiagonal;
    case "differentiate" then elabBuiltinDifferentiate;
    case "simplify" then elabBuiltinSimplify;
    case "noEvent" then elabBuiltinNoevent;
    case "edge" then elabBuiltinEdge;
    case "sign" then elabBuiltinSign;
    case "der" then elabBuiltinDer;
    case "sample" then elabBuiltinSample;
    case "change" then elabBuiltinChange;
    case "cat" then elabBuiltinCat;
    case "identity" then elabBuiltinIdentity;
    case "vector" then elabBuiltinVector;
    case "scalar" then elabBuiltinScalar;
    case "cross" then elabBuiltinCross;
    case "skew" then elabBuiltinSkew;
    case "String" then elabBuiltinString;
    case "rooted" then elabBuiltinRooted;
    case "linspace" then elabBuiltinLinspace;
    case "Integer" then elabBuiltinIntegerEnum;
    case "inStream" then elabBuiltinInStream;
    case "actualStream" then elabBuiltinActualStream;
      
    case "mmc_get_field" equation true = RTOpts.acceptMetaModelicaGrammar(); then elabBuiltinMMCGetField;
    case "mmc_uniontype_metarecord_typedef_equal" equation true = RTOpts.acceptMetaModelicaGrammar(); then elabBuiltinMMC_Uniontype_MetaRecord_Typedefs_Equal;
    case "if_exp" equation true = RTOpts.acceptMetaModelicaGrammar(); then elabBuiltinIfExp;
    case "clock" equation true = RTOpts.acceptMetaModelicaGrammar(); then elabBuiltinClock;
  end matchcontinue;
end elabBuiltinHandler;

protected function isBuiltinFunc "function: isBuiltinFunc
  Returns true if the function name given as argument
  is a builtin function, which either has a elabBuiltinHandler function
  or can be found in the builtin environment."
	input Env.Cache inCache;
  input Absyn.Path inPath;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output Boolean outBoolean;
algorithm
  (outCache,outBoolean) := matchcontinue (inCache,inPath,inPrefix)
    local
      Ident id;
      Absyn.Path path;
      Env.Cache cache;
      Prefix pre;
    case (cache,Absyn.IDENT(name = id),_)
      equation
        _ = elabBuiltinHandler(id);
      then
        (cache,true);
    case (cache, Absyn.QUALIFIED("Connections", Absyn.IDENT("isRoot")),_)
      then
        (cache,true);
    case (cache,path,pre)
      equation
        (cache,true) = Lookup.isInBuiltinEnv(cache,path);
        checkSemiSupportedFunctions(path,pre);
      then
        (cache,true);
    case (cache,_,_) then (cache,false);
  end matchcontinue;
end isBuiltinFunc;

protected function checkSemiSupportedFunctions "Checks for special functions like arccos, ln, etc
that are not covered by the specification, but is used in many libraries and is available in Dymola"
input Absyn.Path path;
input Prefix inPrefix;
algorithm
  _ := matchcontinue(path,inPrefix)
  local
    Prefix pre;
    String ps;
    case(Absyn.IDENT("arcsin"),pre) equation
      ps = PrefixUtil.printPrefixStr3(pre);
      Error.addMessage(Error.SEMI_SUPPORTED_FUNCTION,{"arcsin",ps});
      then ();
    case(Absyn.IDENT("arccos"),pre) equation
      ps = PrefixUtil.printPrefixStr3(pre);
      Error.addMessage(Error.SEMI_SUPPORTED_FUNCTION,{"arccos",ps});
      then ();
    case(Absyn.IDENT("arctan"),pre) equation
      ps = PrefixUtil.printPrefixStr3(pre);
      Error.addMessage(Error.SEMI_SUPPORTED_FUNCTION,{"arctan",ps});
      then ();
    case(Absyn.IDENT("ln"),pre) equation
      ps = PrefixUtil.printPrefixStr3(pre);
      Error.addMessage(Error.SEMI_SUPPORTED_FUNCTION,{"ln",ps});
      then ();
     case(_,_) then ();
  end matchcontinue;
end checkSemiSupportedFunctions;

protected function elabCallBuiltin "function: elabCallBuiltin

  This function elaborates on builtin operators (such as \"pre\", \"der\" etc.),
  by calling the builtin handler to retrieve the correct function to call.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae):=
  matchcontinue (inCache,inEnv,inComponentRef,inAbsynExpLst,inNamedArgs,inBoolean,inPrefix)
    local
      partial function handlerFunc
      	input Env.Cache inCache;
        input list<Env.Frame> inEnvFrameLst;
        input list<Absyn.Exp> inAbsynExpLst;
        input list<Absyn.NamedArg> inNamedArgs;
        input Boolean inBoolean;
        input Prefix inPrefix;
        output Env.Cache outCache;
        output DAE.Exp outExp;
        output DAE.Properties outProperties;
        output DAE.DAElist outDae;
      end handlerFunc;
      handlerFunc handler;
      DAE.Exp exp;
      DAE.Properties prop;
      list<Env.Frame> env;
      Ident name;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      Boolean impl;
      Env.Cache cache;
      DAE.DAElist dae;
      Prefix pre;

    /* impl for normal builtin operators and functions */
    case (cache,env,Absyn.CREF_IDENT(name = name,subscripts = {}),args,nargs,impl,pre)
      equation
        handler = elabBuiltinHandler(name);
        (cache,exp,prop,dae) = handler(cache,env, args, nargs, impl,pre);
      then
        (cache,exp,prop,dae);
    /* special handling for MultiBody 3.x rooted() operator */
    case (cache,env,Absyn.CREF_IDENT(name = "rooted"),args,nargs,impl,pre)
      equation
        (cache,exp,prop,_) = elabBuiltinRooted(cache,env, args, nargs, impl,pre);
      then
        (cache,exp,prop,DAEUtil.emptyDae);
    /* special handling for Connections.isRoot() operator */
    case (cache,env,Absyn.CREF_QUAL(name = "Connections", componentRef = Absyn.CREF_IDENT(name = "isRoot")),args,nargs,impl,pre)
      equation
        (cache,exp,prop) = elabBuiltinIsRoot(cache,env, args, nargs, impl,pre);
      then
        (cache,exp,prop,DAEUtil.emptyDae);
    /* for generic types, like e.g. cardinality */
    case (cache,env,Absyn.CREF_IDENT(name = name,subscripts = {}),args,nargs,impl,pre)
      equation
        handler = elabBuiltinHandlerGeneric(name);
        (cache,exp,prop,dae) = handler(cache,env, args, nargs, impl,pre);
      then
        (cache,exp,prop,dae);
  end matchcontinue;
end elabCallBuiltin;

protected function elabCall "
function: elabCall
  This function elaborates on a function call.  It converts the name
  to a Absyn.Path, and used the Static.elabCallArgs to do the rest of the
  work."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outInteractiveInteractiveSymbolTableOption,outDae):=
  matchcontinue (inCache,inEnv,inComponentRef,inAbsynExpLst,inAbsynNamedArgLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inPrefix)
    local
      DAE.Exp e;
      DAE.Properties prop;
      Option<Interactive.InteractiveSymbolTable> st,st_1;
      list<Env.Frame> env;
      Absyn.ComponentRef fn;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      Boolean impl;
      Absyn.Path fn_1;
      Ident fnstr,argstr,prestr;
      list<Ident> argstrs;
      Env.Cache cache;
      DAE.DAElist dae;
      Prefix pre;

    case (cache,env,fn,args,nargs,impl,st,pre) /* impl LS: Check if a builtin function call, e.g. size()
	      and calculate if so */
      equation
        (cache,e,prop,st) = elabCallInteractive(cache,env, fn, args, nargs, impl, st,pre) "Elaborate interactive function calls, such as simulate(), plot() etc." ;
      then
        (cache,e,prop,st,DAEUtil.emptyDae);
    case (cache,env,fn,args,nargs,impl,st,pre)
      equation
        (cache,e,prop,dae) = elabCallBuiltin(cache,env, fn, args, nargs, impl,pre) "Built in functions (e.g. \"pre\", \"der\"), have only possitional arguments" ;
      then
        (cache,e,prop,st,dae);

    /* Interactive mode */
    case (cache,env,fn,args,nargs,(impl as true),st,pre)
      equation
        false = hasBuiltInHandler(fn,args,pre);
        Debug.fprintln("sei", "elab_call 3");
        fn_1 = Absyn.crefToPath(fn);
        (cache,e,prop,dae) = elabCallArgs(cache,env, fn_1, args, nargs, impl, st,pre);
        Debug.fprint("sei", "elab_call 3 succeeded: ");
        fnstr = Dump.printComponentRefStr(fn);
        Debug.fprintln("sei", fnstr);
      then
        (cache,e,prop,st,dae);

    /* Non-interactive mode */
    case (cache,env,fn,args,nargs,(impl as false),st,pre)
      equation
        false = hasBuiltInHandler(fn,args,pre);
        Debug.fprint("sei", "elab_call 4: ");
        fnstr = Dump.printComponentRefStr(fn);
        Debug.fprintln("sei", fnstr);
        fn_1 = Absyn.crefToPath(fn);
        (cache,e,prop,dae) = elabCallArgs(cache,env, fn_1, args, nargs, impl, st,pre);
        Debug.fprint("sei", "elab_call 4 succeeded: ");
        Debug.fprintln("sei", fnstr);
      then
        (cache,e,prop,st,dae);
    case (cache,env,fn,args,nargs,impl,st,pre)
      equation
				true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "- Static.elabCall failed\n");
        Debug.fprint("failtrace", " function: ");
        fnstr = Dump.printComponentRefStr(fn);
        Debug.fprint("failtrace", fnstr);
        Debug.fprint("failtrace", "   posargs: ");
        argstrs = Util.listMap(args, Dump.printExpStr);
        argstr = Util.stringDelimitList(argstrs, ", ");
        Debug.fprintln("failtrace", argstr);
        Debug.fprint("failtrace", " prefix: ");
        prestr = PrefixUtil.printPrefixStr(pre);
        Debug.fprint("failtrace", prestr);
      then
        fail();
  end matchcontinue;
end elabCall;

protected function hasBuiltInHandler "
Author: BZ, 2009-02
Determine if a function has a builtin handler or not.
"
input Absyn.ComponentRef fn;
input list<Absyn.Exp> expl;
input Prefix inPrefix;
output Boolean b;
algorithm b := matchcontinue(fn,expl,inPrefix)
case (Absyn.CREF_IDENT(name = name,subscripts = {}),expl,pre)
  local String name,s,ps; list<String> lst;
    Prefix pre;
    equation
      _ = elabBuiltinHandler(name);
      //print(" error, handler found for " +& name +& "\n");
      lst = Util.listMap(expl, Dump.printExpStr);
      s = Util.stringDelimitList(lst, ", ");
      s = Util.stringAppendList({name,"(",s,")'.\n"});
      ps = PrefixUtil.printPrefixStr3(pre);
      Error.addMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS, {s,ps});
      then
        true;
case(_,_,_) then false;
  end matchcontinue;
end hasBuiltInHandler;

protected function elabCallInteractive "function: elabCallInteractive

  This function elaborates the functions defined in the interactive environment.
  Since some of these functions are meta-functions, they can not be described in the type
  system, and is thus given the the type T_NOTYPE
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
 algorithm
  (outCache,outExp,outProperties,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inComponentRef,inAbsynExpLst,inAbsynNamedArgLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inPrefix)
    local
      Absyn.Path path,classname;
      DAE.ComponentRef cr_1,cr2_1;
      list<Env.Frame> env;
      Absyn.ComponentRef cr,cr2;
      Boolean impl;
      Interactive.InteractiveSymbolTable st;
      Ident varid,cname_str,filename,str;
      DAE.Exp filenameprefix,startTime,stopTime,numberOfIntervals,method,options,size_exp,exp_1,bool_exp_1,storeInTemp,noClean,tolerance,outputFormat;
      tuple<DAE.TType, Option<Absyn.Path>> recordtype;
      list<Absyn.NamedArg> args;
      list<DAE.Exp> vars_1;
      DAE.Properties ptop,prop;
      Option<Interactive.InteractiveSymbolTable> st_1;
      Integer size,var_len;
      list<Absyn.Exp> vars;
      Absyn.Exp size_absyn,exp,bool_exp;
      Env.Cache cache;
      Prefix pre;

    case (cache,env,Absyn.CREF_IDENT(name = "typeOf"),{Absyn.CREF(componentRef = Absyn.CREF_IDENT(name = varid,subscripts = {}))},{},impl,SOME(st),_) then (cache,DAE.CALL(Absyn.IDENT("typeOf"),
          {DAE.CODE(Absyn.C_VARIABLENAME(Absyn.CREF_IDENT(varid,{})),DAE.ET_OTHER())},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "clear"),{},{},impl,SOME(st),_) then (cache,DAE.CALL(Absyn.IDENT("clear"),{},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "clearVariables"),{},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("clearVariables"),{},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "list"),{},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("list"),{},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "list"),{Absyn.CREF(componentRef = cr)},{},impl,SOME(st),_)
      local Absyn.Path className;
      equation
				className = Absyn.crefToPath(cr);
      then
        (cache,DAE.CALL(Absyn.IDENT("list"),{DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER())},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

		case (cache,env,Absyn.CREF_IDENT(name = "checkModel"),{Absyn.CREF(componentRef = cr)},{},impl,SOME(st),_)
		  local Absyn.Path className;
		  equation
		  className = Absyn.crefToPath(cr);
		then (cache,DAE.CALL(Absyn.IDENT("checkModel"),
          {DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER())},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

		case (cache,env,Absyn.CREF_IDENT(name = "checkAllModelsRecursive"),{Absyn.CREF(componentRef = cr)},{},impl,SOME(st),_)
		  local Absyn.Path className;
		  equation
		  className = Absyn.crefToPath(cr);
		then (cache,DAE.CALL(Absyn.IDENT("checkAllModelsRecursive"),
          {DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER())},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

		case (cache,env,Absyn.CREF_IDENT(name = "translateGraphics"),{Absyn.CREF(componentRef = cr)},{},impl,SOME(st),_)
		  local Absyn.Path className;
		  equation
		  className = Absyn.crefToPath(cr);
		then (cache,DAE.CALL(Absyn.IDENT("translateGraphics"),
          {DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER())},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "translateModel"),{Absyn.CREF(componentRef = cr)},args,impl,SOME(st),pre)
      local
        Absyn.Path className;
      equation
        className = Absyn.crefToPath(cr);
        cname_str = Absyn.pathString(className);
        (cache,filenameprefix) = getOptionalNamedArg(cache,env, SOME(st), impl, "fileNamePrefix",
          DAE.T_STRING_DEFAULT, args, DAE.SCONST(cname_str),pre);
        recordtype = (
          DAE.T_COMPLEX(ClassInf.RECORD(Absyn.IDENT("SimulationObject")),
          {
          DAE.TYPES_VAR("flatClass",
          DAE.ATTR(false,false,SCode.RO(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE()),
          DAE.TYPES_VAR("exeFile",
          DAE.ATTR(false,false,SCode.RO(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE())},NONE,NONE),NONE);
      then
        (cache,DAE.CALL(Absyn.IDENT("translateModel"),
          {DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER()),filenameprefix},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(recordtype,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "exportDAEtoMatlab"),{Absyn.CREF(componentRef = cr)},args,impl,SOME(st),pre)
      local
        Absyn.Path className;
      equation
        className = Absyn.crefToPath(cr);
        cname_str = Absyn.pathString(className);
        (cache,filenameprefix) = getOptionalNamedArg(cache,env, SOME(st), impl, "fileNamePrefix",
          DAE.T_STRING_DEFAULT, args, DAE.SCONST(cname_str),pre);
        recordtype = (
          DAE.T_COMPLEX(ClassInf.RECORD(Absyn.IDENT("SimulationObject")),
          {
          DAE.TYPES_VAR("flatClass",
          DAE.ATTR(false,false,SCode.RO(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE()),
          DAE.TYPES_VAR("exeFile",
          DAE.ATTR(false,false,SCode.RO(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),false,DAE.T_STRING_DEFAULT,DAE.UNBOUND(),NONE())},NONE,NONE),NONE);
      then
        (cache,DAE.CALL(Absyn.IDENT("exportDAEtoMatlab"),
          {DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER()),filenameprefix},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(recordtype,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "instantiateModel"),{Absyn.CREF(componentRef = cr)},{},impl,SOME(st),pre)
      local Absyn.Path className;
      equation
        className = Absyn.crefToPath(cr);
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl,pre);
      then
        (cache, DAE.CALL(Absyn.IDENT("instantiateModel"),
          {DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER())},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

		/* Special case for Parham Vaseles OpenModelica Interactive, where buildModel
		   takes stepSize instead of startTime, stopTime and numberOfIntervals */
		case (cache,env,Absyn.CREF_IDENT(name = "buildModel"),{Absyn.CREF(componentRef = cr)},args,impl,SOME(st),pre)
			local
				Absyn.Path className;
				DAE.Exp noClean, tolerance, storeInTemp;
				Real stepTime;
				Integer intervals;
			equation
				// An ICONST is used as the default value of stepSize so that this case
				// fails if stepSize isn't given as argument to buildModel.
				(cache, DAE.RCONST(stepTime)) = getOptionalNamedArg(cache, env, SOME(st), impl, "stepSize", DAE.T_REAL_DEFAULT, args, DAE.ICONST(0),pre);
				startTime = DAE.RCONST(0.0);
				stopTime = DAE.RCONST(1.0);
				intervals = realInt(1.0 /. stepTime);
				numberOfIntervals = DAE.ICONST(intervals);
				className = Absyn.crefToPath(cr);
        cname_str = Absyn.pathString(className);
				(cache,tolerance) = getOptionalNamedArg(cache,env, SOME(st), impl, "tolerance", DAE.T_REAL_DEFAULT, args, DAE.RCONST(1e-6),pre);  
        (cache,method) = getOptionalNamedArg(cache,env, SOME(st), impl, "method", DAE.T_STRING_DEFAULT, args, DAE.SCONST("dassl"),pre);
        (cache,options) = getOptionalNamedArg(cache,env, SOME(st), impl, "options", DAE.T_STRING_DEFAULT, args, DAE.SCONST(""),pre);
        (cache,filenameprefix) = getOptionalNamedArg(cache,env, SOME(st), impl, "fileNamePrefix",  DAE.T_STRING_DEFAULT, args, DAE.SCONST(cname_str),pre);
        (cache,storeInTemp) = getOptionalNamedArg(cache,env, SOME(st), impl, "storeInTemp", DAE.T_BOOL_DEFAULT, args, DAE.BCONST(false),pre);  
        (cache,noClean) = getOptionalNamedArg(cache,env, SOME(st), impl, "noClean", DAE.T_BOOL_DEFAULT, args, DAE.BCONST(false),pre);  
        (cache,outputFormat) = getOptionalNamedArg(cache,env, SOME(st), impl, "outputFormat", DAE.T_STRING_DEFAULT, args, defaultOutputFormat,pre);
			then
				(cache, DAE.CALL(Absyn.IDENT("buildModel"),
				{DAE.CODE(Absyn.C_TYPENAME(className), DAE.ET_OTHER()), startTime, stopTime,
				numberOfIntervals,tolerance,method,filenameprefix,storeInTemp,noClean,options,outputFormat},
				false,true,DAE.ET_OTHER(),DAE.NO_INLINE),
				DAE.PROP((DAE.T_ARRAY(DAE.DIM_INTEGER(2),DAE.T_STRING_DEFAULT),NONE),DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "buildModel"),{Absyn.CREF(componentRef = cr)},args,impl,SOME(st),pre)
      local Absyn.Path className; DAE.Exp storeInTemp; DAE.Exp noClean,tolerance;
      equation 
        className = Absyn.crefToPath(cr);
        cname_str = Absyn.pathString(className);
        (cache,startTime) = getOptionalNamedArg(cache,env, SOME(st), impl, "startTime", DAE.T_REAL_DEFAULT, args, DAE.RCONST(0.0),pre);
        (cache,stopTime) = getOptionalNamedArg(cache,env, SOME(st), impl, "stopTime", DAE.T_REAL_DEFAULT, args, DAE.RCONST(1.0),pre);
        (cache,numberOfIntervals) = getOptionalNamedArg(cache,env, SOME(st), impl, "numberOfIntervals", DAE.T_INTEGER_DEFAULT, args, DAE.ICONST(500),pre);
        (cache,tolerance) = getOptionalNamedArg(cache,env, SOME(st), impl, "tolerance", DAE.T_REAL_DEFAULT, args, DAE.RCONST(1e-6),pre);  
        (cache,method) = getOptionalNamedArg(cache,env, SOME(st), impl, "method", DAE.T_STRING_DEFAULT, args, DAE.SCONST("dassl"),pre);
        (cache,options) = getOptionalNamedArg(cache,env, SOME(st), impl, "options", DAE.T_STRING_DEFAULT, args, DAE.SCONST(""),pre);
        (cache,filenameprefix) = getOptionalNamedArg(cache,env, SOME(st), impl, "fileNamePrefix", DAE.T_STRING_DEFAULT, args, DAE.SCONST(cname_str),pre);
        (cache,storeInTemp) = getOptionalNamedArg(cache,env, SOME(st), impl, "storeInTemp", DAE.T_BOOL_DEFAULT, args, DAE.BCONST(false),pre);  
        (cache,noClean) = getOptionalNamedArg(cache,env, SOME(st), impl, "noClean", DAE.T_BOOL_DEFAULT, args, DAE.BCONST(false),pre);  
        (cache,outputFormat) = getOptionalNamedArg(cache,env, SOME(st), impl, "outputFormat", DAE.T_STRING_DEFAULT, args, defaultOutputFormat,pre);
      then
        (cache,DAE.CALL(Absyn.IDENT("buildModel"),
          {DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER()),startTime,stopTime,
          numberOfIntervals,tolerance,method,filenameprefix,storeInTemp,noClean,options,outputFormat},false,true,DAE.ET_OTHER(),DAE.NO_INLINE),DAE.PROP(
          (
          DAE.T_ARRAY(DAE.DIM_INTEGER(2),DAE.T_STRING_DEFAULT),NONE),DAE.C_VAR()),SOME(st));
    case (cache,env,Absyn.CREF_IDENT(name = "buildModelBeast"),{Absyn.CREF(componentRef = cr)},args,impl,SOME(st),pre)
      local Absyn.Path className; DAE.Exp storeInTemp; DAE.Exp noClean,tolerance;
      equation 
        className = Absyn.crefToPath(cr);
        cname_str = Absyn.pathString(className);
        (cache,startTime) = getOptionalNamedArg(cache,env, SOME(st), impl, "startTime", DAE.T_REAL_DEFAULT, args, DAE.RCONST(0.0),pre);
        (cache,stopTime) = getOptionalNamedArg(cache,env, SOME(st), impl, "stopTime", DAE.T_REAL_DEFAULT, args, DAE.RCONST(1.0),pre); 
        (cache,numberOfIntervals) = getOptionalNamedArg(cache,env, SOME(st), impl, "numberOfIntervals", DAE.T_INTEGER_DEFAULT, args, DAE.ICONST(500),pre);
        (cache,tolerance) = getOptionalNamedArg(cache,env, SOME(st), impl, "tolerance", DAE.T_REAL_DEFAULT, args, DAE.RCONST(1e-6),pre); 
        (cache,method) = getOptionalNamedArg(cache,env, SOME(st), impl, "method", DAE.T_STRING_DEFAULT, args, DAE.SCONST("dassl"),pre);
        (cache,options) = getOptionalNamedArg(cache,env, SOME(st), impl, "options", DAE.T_STRING_DEFAULT, args, DAE.SCONST(""),pre); 
        (cache,filenameprefix) = getOptionalNamedArg(cache,env, SOME(st), impl, "fileNamePrefix", DAE.T_STRING_DEFAULT, args, DAE.SCONST(cname_str),pre);
        (cache,storeInTemp) = getOptionalNamedArg(cache,env, SOME(st), impl, "storeInTemp", DAE.T_BOOL_DEFAULT, args, DAE.BCONST(false),pre);  
        (cache,noClean) = getOptionalNamedArg(cache,env, SOME(st), impl, "noClean", DAE.T_BOOL_DEFAULT, args, DAE.BCONST(false),pre);  
        (cache,outputFormat) = getOptionalNamedArg(cache,env, SOME(st), impl, "outputFormat", DAE.T_STRING_DEFAULT, args, defaultOutputFormat,pre);
      then
        (cache,DAE.CALL(Absyn.IDENT("buildModelBeast"),
          {DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER()),startTime,stopTime,
          numberOfIntervals,tolerance, method,filenameprefix,storeInTemp,noClean,options,outputFormat},false,true,DAE.ET_OTHER(),DAE.NO_INLINE),DAE.PROP(
          (DAE.T_ARRAY(DAE.DIM_INTEGER(2),DAE.T_STRING_DEFAULT),NONE),DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "simulate"),{Absyn.CREF(componentRef = cr)},args,impl,SOME(st),pre) /* Fill in rest of defaults here */
      local Absyn.Path className;
      equation
        className = Absyn.crefToPath(cr);
        (cache,cr_1) = elabUntypedCref(cache, env, cr, impl,pre);
        classname = componentRefToPath(cr_1) "this extracts the fileNamePrefix which is used when generating code and init-file" ;
        cname_str = Absyn.pathString(classname);
        (cache,startTime) = getOptionalNamedArg(cache,env, SOME(st), impl, "startTime", DAE.T_REAL_DEFAULT, args, DAE.RCONST(0.0),pre);
        (cache,stopTime) = getOptionalNamedArg(cache,env, SOME(st), impl, "stopTime", DAE.T_REAL_DEFAULT, args, DAE.RCONST(1.0),pre);
        (cache,numberOfIntervals) = getOptionalNamedArg(cache,env, SOME(st), impl, "numberOfIntervals", DAE.T_INTEGER_DEFAULT, args, DAE.ICONST(500),pre);
        (cache,tolerance) = getOptionalNamedArg(cache,env, SOME(st), impl, "tolerance", DAE.T_REAL_DEFAULT, args, DAE.RCONST(1e-6),pre);  
        (cache,method) = getOptionalNamedArg(cache,env, SOME(st), impl, "method", DAE.T_STRING_DEFAULT, args, DAE.SCONST("dassl"),pre);
        (cache,filenameprefix) = getOptionalNamedArg(cache,env, SOME(st), impl, "fileNamePrefix", DAE.T_STRING_DEFAULT, args, DAE.SCONST(cname_str),pre);
        (cache,storeInTemp) = getOptionalNamedArg(cache,env, SOME(st), impl, "storeInTemp", DAE.T_BOOL_DEFAULT, args, DAE.BCONST(false),pre);
        (cache,options) = getOptionalNamedArg(cache,env, SOME(st), impl, "options", DAE.T_STRING_DEFAULT, args, DAE.SCONST(""),pre);
        (cache,noClean) = getOptionalNamedArg(cache,env, SOME(st), impl, "noClean", DAE.T_BOOL_DEFAULT, args, DAE.BCONST(false),pre);
        (cache,outputFormat) = getOptionalNamedArg(cache,env, SOME(st), impl, "outputFormat", DAE.T_STRING_DEFAULT, args, defaultOutputFormat,pre);
        recordtype = CevalScript.getSimulationResultType();
      then
        (cache,DAE.CALL(Absyn.IDENT("simulate"),
          {DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER()),startTime,stopTime,
          numberOfIntervals,tolerance,method,filenameprefix,storeInTemp,noClean,options,outputFormat},false,true,DAE.ET_OTHER(),DAE.NO_INLINE),DAE.PROP(recordtype,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "jacobian"),{Absyn.CREF(componentRef = cr)},args,impl,SOME(st),pre) /* Fill in rest of defaults here */
      equation
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl,pre);
      then
        (cache,DAE.CALL(Absyn.IDENT("jacobian"),{DAE.CREF(cr_1,DAE.ET_OTHER())},false,
          true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "readSimulationResult"),{Absyn.STRING(value = filename),Absyn.ARRAY(arrayExp = vars),size_absyn},args,impl,SOME(st),pre)
      equation
        vars_1 = elabVariablenames(vars);
        (cache,size_exp,ptop,st_1,_) = elabExp(cache,env, size_absyn, false, SOME(st),true,pre);
        (cache,Values.INTEGER(size),_) = Ceval.ceval(cache,env, size_exp, false, st_1, NONE, Ceval.MSG());
        var_len = listLength(vars);
      then
        (cache,DAE.CALL(Absyn.IDENT("readSimulationResult"),
          {DAE.SCONST(filename),DAE.ARRAY(DAE.ET_OTHER(),false,vars_1),
          size_exp},false,true,DAE.ET_ARRAY(DAE.ET_REAL(),{DAE.DIM_INTEGER(var_len),DAE.DIM_INTEGER(size)}),DAE.NO_INLINE),DAE.PROP(
          (DAE.T_ARRAY(DAE.DIM_INTEGER(var_len),
          (DAE.T_ARRAY(DAE.DIM_INTEGER(size),DAE.T_REAL_DEFAULT),NONE)),NONE),DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "readSimulationResultSize"),{Absyn.STRING(value = filename)},args,impl,SOME(st),_) 
      /* elab_variablenames(vars) => vars\' & list_length(vars) => var_len */  
    then (cache, DAE.CALL(Absyn.IDENT("readSimulationResultSize"),
          {DAE.SCONST(filename)},false,true,DAE.ET_OTHER(),DAE.NO_INLINE),DAE.PROP(DAE.T_INTEGER_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "plot2"),{(cr as Absyn.CREF(componentRef = _))},{},impl,SOME(st),_)
      local Absyn.Exp cr;
      equation
        vars_1 = elabVariablenames({cr});
      then
        (cache,DAE.CALL(Absyn.IDENT("plot2"),{DAE.ARRAY(DAE.ET_OTHER(),false,vars_1)},
          false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "plot2"),{Absyn.ARRAY(arrayExp = vars)},{},impl,SOME(st),_)
      equation
        vars_1 = elabVariablenames(vars);
      then
        (cache,DAE.CALL(Absyn.IDENT("plot2"),{DAE.ARRAY(DAE.ET_OTHER(),false,vars_1)},
          false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

//visualize(model)
  case (cache,env,Absyn.CREF_IDENT(name = "visualize"),{Absyn.CREF(componentRef = cr)},args,impl,SOME(st),_) /* Fill in rest of defaults here */
    local Absyn.Path className; DAE.Exp storeInTemp; Absyn.Exp cr2;
      		DAE.Exp interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points;
//      		String vars;
      equation
				className = Absyn.crefToPath(cr);
      then
        (cache,DAE.CALL(Absyn.IDENT("visualize"),{DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER())},
          false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));


//plotAll(model)
  case (cache,env,Absyn.CREF_IDENT(name = "plotAll"),{Absyn.CREF(componentRef = cr)},args,impl,SOME(st),pre) /* Fill in rest of defaults here */
    local Absyn.Path className; DAE.Exp storeInTemp;
      		DAE.Exp interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, xRange, yRange;

      equation
//        vars_1 = elabVariablenames({cr2});
				className = Absyn.crefToPath(cr);
        (cache,interpolation) = getOptionalNamedArg(cache,env, SOME(st), impl, "interpolation", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("linear"),pre);
        (cache,title) = getOptionalNamedArg(cache,env, SOME(st), impl, "title", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("Plot by OpenModelica"),pre);
        (cache,legend) = getOptionalNamedArg(cache,env, SOME(st), impl, "legend", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(true),pre);
        (cache,grid) = getOptionalNamedArg(cache,env, SOME(st), impl, "grid", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(true),pre);
        (cache,logX) = getOptionalNamedArg(cache,env, SOME(st), impl, "logX", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);
        (cache,logY) = getOptionalNamedArg(cache,env, SOME(st), impl, "logY", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);
       (cache,xLabel) = getOptionalNamedArg(cache,env, SOME(st), impl, "xLabel", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("time"),pre);
        (cache,yLabel) = getOptionalNamedArg(cache,env, SOME(st), impl, "yLabel", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST(""),pre);
        (cache,points) = getOptionalNamedArg(cache,env, SOME(st), impl, "points", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);

        (cache,xRange) = getOptionalNamedArg(cache,env, SOME(st), impl, "xRange",  (DAE.T_ARRAY(DAE.DIM_INTEGER(2),DAE.T_REAL_DEFAULT),NONE),
          args, DAE.ARRAY(DAE.ET_REAL(), false, {DAE.RCONST(0.0), DAE.RCONST(0.0)}),pre);// DAE.ARRAY(DAE.ET_REAL(), false, {0, 0}));
        (cache,yRange) = getOptionalNamedArg(cache,env, SOME(st), impl, "yRange",  (DAE.T_ARRAY(DAE.DIM_INTEGER(2),DAE.T_REAL_DEFAULT),NONE),
          args, DAE.ARRAY(DAE.ET_REAL(), false, {DAE.RCONST(0.0), DAE.RCONST(0.0)}),pre);// DAE.ARRAY(DAE.ET_REAL(), false, {0, 0}));


      then
        (cache,DAE.CALL(Absyn.IDENT("plotAll"),{DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER()), interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, xRange, yRange},
          false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

//plotAll()
  case (cache,env,Absyn.CREF_IDENT(name = "plotAll"),{},args,impl,SOME(st),pre) /* Fill in rest of defaults here */
    local Absyn.Path className; DAE.Exp storeInTemp;
      		DAE.Exp interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, xRange, yRange;

      equation
//        vars_1 = elabVariablenames({cr2});
//				className = Absyn.crefToPath(cr);
        (cache,interpolation) = getOptionalNamedArg(cache,env, SOME(st), impl, "interpolation", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("linear"),pre);
        (cache,title) = getOptionalNamedArg(cache,env, SOME(st), impl, "title", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("Plot by OpenModelica"),pre);
        (cache,legend) = getOptionalNamedArg(cache,env, SOME(st), impl, "legend", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(true),pre);
        (cache,grid) = getOptionalNamedArg(cache,env, SOME(st), impl, "grid", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(true),pre);
        (cache,logX) = getOptionalNamedArg(cache,env, SOME(st), impl, "logX", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);
        (cache,logY) = getOptionalNamedArg(cache,env, SOME(st), impl, "logY", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);
       (cache,xLabel) = getOptionalNamedArg(cache,env, SOME(st), impl, "xLabel", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("time"),pre);
        (cache,yLabel) = getOptionalNamedArg(cache,env, SOME(st), impl, "yLabel", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST(""),pre);
        (cache,points) = getOptionalNamedArg(cache,env, SOME(st), impl, "points", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);

        (cache,xRange) = getOptionalNamedArg(cache,env, SOME(st), impl, "xRange",  (DAE.T_ARRAY(DAE.DIM_INTEGER(2),DAE.T_REAL_DEFAULT),NONE),
          args, DAE.ARRAY(DAE.ET_REAL(), false, {DAE.RCONST(0.0), DAE.RCONST(0.0)}),pre);// DAE.ARRAY(DAE.ET_REAL(), false, {0, 0}));
        (cache,yRange) = getOptionalNamedArg(cache,env, SOME(st), impl, "yRange",  (DAE.T_ARRAY(DAE.DIM_INTEGER(2),DAE.T_REAL_DEFAULT),NONE),
          args, DAE.ARRAY(DAE.ET_REAL(), false, {DAE.RCONST(0.0), DAE.RCONST(0.0)}),pre);// DAE.ARRAY(DAE.ET_REAL(), false, {0, 0}));


      then
        (cache,DAE.CALL(Absyn.IDENT("plotAll"),{interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, xRange, yRange},
          false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));


//plot2(model, x)
  case (cache,env,Absyn.CREF_IDENT(name = "plot"),{Absyn.CREF(componentRef = cr), cr2 as Absyn.CREF(componentRef = _)},args,impl,SOME(st),pre) /* Fill in rest of defaults here */
    local Absyn.Path className; DAE.Exp storeInTemp; Absyn.Exp cr2;
      		DAE.Exp interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, xRange, yRange;

      equation
        vars_1 = elabVariablenames({cr2});
				className = Absyn.crefToPath(cr);
        (cache,interpolation) = getOptionalNamedArg(cache,env, SOME(st), impl, "interpolation", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("linear"),pre);
        (cache,title) = getOptionalNamedArg(cache,env, SOME(st), impl, "title", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("Plot by OpenModelica"),pre);
        (cache,legend) = getOptionalNamedArg(cache,env, SOME(st), impl, "legend", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(true),pre);
        (cache,grid) = getOptionalNamedArg(cache,env, SOME(st), impl, "grid", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(true),pre);
        (cache,logX) = getOptionalNamedArg(cache,env, SOME(st), impl, "logX", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);
        (cache,logY) = getOptionalNamedArg(cache,env, SOME(st), impl, "logY", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);
       (cache,xLabel) = getOptionalNamedArg(cache,env, SOME(st), impl, "xLabel", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("time"),pre);
        (cache,yLabel) = getOptionalNamedArg(cache,env, SOME(st), impl, "yLabel", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST(""),pre);
        (cache,points) = getOptionalNamedArg(cache,env, SOME(st), impl, "points", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);

        (cache,xRange) = getOptionalNamedArg(cache,env, SOME(st), impl, "xRange",  (DAE.T_ARRAY(DAE.DIM_INTEGER(2),DAE.T_REAL_DEFAULT),NONE),
          args, DAE.ARRAY(DAE.ET_REAL(), false, {DAE.RCONST(0.0), DAE.RCONST(0.0)}),pre);// DAE.ARRAY(DAE.ET_REAL(), false, {0, 0}));
        (cache,yRange) = getOptionalNamedArg(cache,env, SOME(st), impl, "yRange",  (DAE.T_ARRAY(DAE.DIM_INTEGER(2),DAE.T_REAL_DEFAULT),NONE),
          args, DAE.ARRAY(DAE.ET_REAL(), false, {DAE.RCONST(0.0), DAE.RCONST(0.0)}),pre);// DAE.ARRAY(DAE.ET_REAL(), false, {0, 0}));


      then
        (cache,DAE.CALL(Absyn.IDENT("plot"),{DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER()), DAE.ARRAY(DAE.ET_OTHER(),false,vars_1), interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, xRange, yRange},
          false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

//plot2(model, {x,y})
  case (cache,env,Absyn.CREF_IDENT(name = "plot"),{Absyn.CREF(componentRef = cr), Absyn.ARRAY(arrayExp = vars)},args,impl,SOME(st),pre) /* Fill in rest of defaults here */
    local Absyn.Path className; DAE.Exp storeInTemp; Absyn.Exp cr2;
        DAE.Exp interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, xRange, yRange;

      equation
        vars_1 = elabVariablenames(vars);
				className = Absyn.crefToPath(cr);
        (cache,interpolation) = getOptionalNamedArg(cache,env, SOME(st), impl, "interpolation", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("linear"),pre);


        (cache,title) = getOptionalNamedArg(cache,env, SOME(st), impl, "title", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("Plot by OpenModelica"),pre);
        (cache,legend) = getOptionalNamedArg(cache,env, SOME(st), impl, "legend", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(true),pre);
        (cache,grid) = getOptionalNamedArg(cache,env, SOME(st), impl, "grid", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(true),pre);
        (cache,logX) = getOptionalNamedArg(cache,env, SOME(st), impl, "logX", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);
        (cache,logY) = getOptionalNamedArg(cache,env, SOME(st), impl, "logY", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);
       (cache,xLabel) = getOptionalNamedArg(cache,env, SOME(st), impl, "xLabel", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("time"),pre);
        (cache,yLabel) = getOptionalNamedArg(cache,env, SOME(st), impl, "yLabel", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST(""),pre);
        (cache,points) = getOptionalNamedArg(cache,env, SOME(st), impl, "points", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);

        (cache,xRange) = getOptionalNamedArg(cache,env, SOME(st), impl, "xRange",  (DAE.T_ARRAY(DAE.DIM_INTEGER(2),DAE.T_REAL_DEFAULT),NONE),
          args, DAE.ARRAY(DAE.ET_REAL(), false, {DAE.RCONST(0.0), DAE.RCONST(0.0)}),pre);// DAE.ARRAY(DAE.ET_REAL(), false, {0, 0}));
        (cache,yRange) = getOptionalNamedArg(cache,env, SOME(st), impl, "yRange",  (DAE.T_ARRAY(DAE.DIM_INTEGER(2),DAE.T_REAL_DEFAULT),NONE),
          args, DAE.ARRAY(DAE.ET_REAL(), false, {DAE.RCONST(0.0), DAE.RCONST(0.0)}),pre);// DAE.ARRAY(DAE.ET_REAL(), false, {0, 0}));

      then
        (cache,DAE.CALL(Absyn.IDENT("plot"),{DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER()), DAE.ARRAY(DAE.ET_OTHER(),false,vars_1), interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, xRange, yRange},
          false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));



//plot2(x)
    case (cache,env,Absyn.CREF_IDENT(name = "plot"),{(cr as Absyn.CREF(componentRef = _))},args,impl,SOME(st),pre)
      local Absyn.Exp cr;
        DAE.Exp grid, legend, title, interpolation, logX, logY, xLabel, yLabel, points, xRange, yRange;
      equation
        vars_1 = elabVariablenames({cr});

        (cache,interpolation) = getOptionalNamedArg(cache,env, SOME(st), impl, "interpolation", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("linear"),pre);
        (cache,title) = getOptionalNamedArg(cache,env, SOME(st), impl, "title", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("Plot by OpenModelica"),pre);
        (cache,legend) = getOptionalNamedArg(cache,env, SOME(st), impl, "legend", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(true),pre);
        (cache,grid) = getOptionalNamedArg(cache,env, SOME(st), impl, "grid", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(true),pre);
        (cache,logX) = getOptionalNamedArg(cache,env, SOME(st), impl, "logX", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);
        (cache,logY) = getOptionalNamedArg(cache,env, SOME(st), impl, "logY", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);
       (cache,xLabel) = getOptionalNamedArg(cache,env, SOME(st), impl, "xLabel", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("time"),pre);
        (cache,yLabel) = getOptionalNamedArg(cache,env, SOME(st), impl, "yLabel", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST(""),pre);
        (cache,points) = getOptionalNamedArg(cache,env, SOME(st), impl, "points", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);

        (cache,xRange) = getOptionalNamedArg(cache,env, SOME(st), impl, "xRange",  (DAE.T_ARRAY(DAE.DIM_INTEGER(2),DAE.T_REAL_DEFAULT),NONE),
          args, DAE.ARRAY(DAE.ET_REAL(), false, {DAE.RCONST(0.0), DAE.RCONST(0.0)}),pre);// DAE.ARRAY(DAE.ET_REAL(), false, {0, 0}));
        (cache,yRange) = getOptionalNamedArg(cache,env, SOME(st), impl, "yRange",  (DAE.T_ARRAY(DAE.DIM_INTEGER(2),DAE.T_REAL_DEFAULT),NONE),
          args, DAE.ARRAY(DAE.ET_REAL(), false, {DAE.RCONST(0.0), DAE.RCONST(0.0)}),pre);// DAE.ARRAY(DAE.ET_REAL(), false, {0, 0}));

      then
        (cache,DAE.CALL(Absyn.IDENT("plot"),{DAE.ARRAY(DAE.ET_OTHER(),false,vars_1), interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, xRange, yRange},
          false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

//plot2({x,y})
    case (cache,env,Absyn.CREF_IDENT(name = "plot"),{Absyn.ARRAY(arrayExp = vars)},args,impl,SOME(st),pre)
						local
						  DAE.Exp interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, xRange, yRange;
            equation
        vars_1 = elabVariablenames(vars);
        (cache,interpolation) = getOptionalNamedArg(cache,env, SOME(st), impl, "interpolation", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("linear"),pre);
        (cache,title) = getOptionalNamedArg(cache,env, SOME(st), impl, "title", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("Plot by OpenModelica"),pre);
        (cache,legend) = getOptionalNamedArg(cache,env, SOME(st), impl, "legend", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(true),pre);
        (cache,grid) = getOptionalNamedArg(cache,env, SOME(st), impl, "grid", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(true),pre);
        (cache,logX) = getOptionalNamedArg(cache,env, SOME(st), impl, "logX", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);
        (cache,logY) = getOptionalNamedArg(cache,env, SOME(st), impl, "logY", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);
       (cache,xLabel) = getOptionalNamedArg(cache,env, SOME(st), impl, "xLabel", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("time"),pre);
        (cache,yLabel) = getOptionalNamedArg(cache,env, SOME(st), impl, "yLabel", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST(""),pre);
        (cache,points) = getOptionalNamedArg(cache,env, SOME(st), impl, "points", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);

        (cache,xRange) = getOptionalNamedArg(cache,env, SOME(st), impl, "xRange",  (DAE.T_ARRAY(DAE.DIM_INTEGER(2),DAE.T_REAL_DEFAULT),NONE),
          args, DAE.ARRAY(DAE.ET_REAL(), false, {DAE.RCONST(0.0), DAE.RCONST(0.0)}),pre);// DAE.ARRAY(DAE.ET_REAL(), false, {0, 0}));
        (cache,yRange) = getOptionalNamedArg(cache,env, SOME(st), impl, "yRange",  (DAE.T_ARRAY(DAE.DIM_INTEGER(2),DAE.T_REAL_DEFAULT),NONE),
          args, DAE.ARRAY(DAE.ET_REAL(), false, {DAE.RCONST(0.0), DAE.RCONST(0.0)}),pre);// DAE.ARRAY(DAE.ET_REAL(), false, {0, 0}));


      then
        (cache,DAE.CALL(Absyn.IDENT("plot"),{DAE.ARRAY(DAE.ET_OTHER(),false,vars_1), interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, xRange, yRange},
          false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

   case (cache,env,Absyn.CREF_IDENT(name = "val"),{(cr as Absyn.CREF(componentRef = _)),cd},{},impl,SOME(st),pre)
      local
        Absyn.Exp cr,cd;
        DAE.Exp cd1,cr2;
      equation
        {cr2} = elabVariablenames({cr});
        (cache,cd1,ptop,st_1,_) = elabExp(cache, env, cd, false, SOME(st),true,pre);
        Types.integerOrReal(Types.arrayElementType(Types.getPropType(ptop)));
      then
        (cache,DAE.CALL(Absyn.IDENT("val"),{cr2,cd1},
          false,true,DAE.ET_REAL(),DAE.NO_INLINE),DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "plotParametric2"),vars,{},impl,SOME(st),_) /* PlotParametric is similar to plot but does not allow a single CREF as an
   argument as you are plotting at least one variable as a function of another.
   Thus, plotParametric has to take an array as an argument, or two componentRefs. */
      equation
        vars_1 = elabVariablenames(vars);
      then
        (cache,DAE.CALL(Absyn.IDENT("plotParametric2"),
          vars_1,false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

   case (cache,env,Absyn.CREF_IDENT(name = "plotParametric"),{Absyn.CREF(componentRef = cr), cr2 as Absyn.CREF(componentRef = _), cr3 as Absyn.CREF(componentRef = _)} ,args,impl,SOME(st),pre) /* PlotParametric is similar to plot but does not allow a single CREF as an
   argument as you are plotting at least one variable as a function of another.
   Thus, plotParametric has to take an array as an argument, or two componentRefs. */
   local Absyn.Path className; list<DAE.Exp> vars_3; Absyn.Exp cr2, cr3;
     		 DAE.Exp interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, xRange, yRange;
         list<DAE.Exp> vars_2;
      equation
        vars_1 = elabVariablenames({cr2});
        vars_2 = elabVariablenames({cr3});
				className = Absyn.crefToPath(cr);
        vars_3 = listAppend(vars_1, vars_2);

         (cache,interpolation) = getOptionalNamedArg(cache,env, SOME(st), impl, "interpolation", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("linear"),pre);

        (cache,title) = getOptionalNamedArg(cache,env, SOME(st), impl, "title", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("Plot by OpenModelica"),pre);
        (cache,legend) = getOptionalNamedArg(cache,env, SOME(st), impl, "legend", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(true),pre);
        (cache,grid) = getOptionalNamedArg(cache,env, SOME(st), impl, "grid", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(true),pre);
        (cache,logX) = getOptionalNamedArg(cache,env, SOME(st), impl, "logX", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);
        (cache,logY) = getOptionalNamedArg(cache,env, SOME(st), impl, "logY", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);
       (cache,xLabel) = getOptionalNamedArg(cache,env, SOME(st), impl, "xLabel", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("time"),pre);
        (cache,yLabel) = getOptionalNamedArg(cache,env, SOME(st), impl, "yLabel", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST(""),pre);
        (cache,points) = getOptionalNamedArg(cache,env, SOME(st), impl, "points", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);

        (cache,xRange) = getOptionalNamedArg(cache,env, SOME(st), impl, "xRange",  (DAE.T_ARRAY(DAE.DIM_INTEGER(2),DAE.T_REAL_DEFAULT),NONE),
          args, DAE.ARRAY(DAE.ET_REAL(), false, {DAE.RCONST(0.0), DAE.RCONST(0.0)}),pre);// DAE.ARRAY(DAE.ET_REAL(), false, {0, 0}));
        (cache,yRange) = getOptionalNamedArg(cache,env, SOME(st), impl, "yRange",  (DAE.T_ARRAY(DAE.DIM_INTEGER(2),DAE.T_REAL_DEFAULT),NONE),
          args, DAE.ARRAY(DAE.ET_REAL(), false, {DAE.RCONST(0.0), DAE.RCONST(0.0)}),pre);// DAE.ARRAY(DAE.ET_REAL(), false, {0, 0}));

      then

        (cache,DAE.CALL(Absyn.IDENT("plotParametric"),{DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER()), DAE.ARRAY(DAE.ET_OTHER(),false,vars_3), interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, xRange, yRange}
        ,false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

//plotParametric2(x,y)
   case (cache,env,Absyn.CREF_IDENT(name = "plotParametric"),{cr2 as Absyn.CREF(componentRef = _), cr3 as Absyn.CREF(componentRef = _)} ,args,impl,SOME(st),pre) /* PlotParametric is similar to plot but does not allow a single CREF as an
   argument as you are plotting at least one variable as a function of another.
   Thus, plotParametric has to take an array as an argument, or two componentRefs. */
   local Absyn.Path className; list<DAE.Exp> vars_3; Absyn.Exp cr2, cr3;
     DAE.Exp interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, xRange, yRange;
     list<DAE.Exp> vars_2;
      equation

        vars_1 = elabVariablenames({cr2});
        vars_2 = elabVariablenames({cr3});
        vars_3 = listAppend(vars_1, vars_2);

         (cache,interpolation) = getOptionalNamedArg(cache,env, SOME(st), impl, "interpolation", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("linear"),pre);

         (cache,title) = getOptionalNamedArg(cache,env, SOME(st), impl, "title", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("Plot by OpenModelica"),pre);
        (cache,legend) = getOptionalNamedArg(cache,env, SOME(st), impl, "legend", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(true),pre);
        (cache,grid) = getOptionalNamedArg(cache,env, SOME(st), impl, "grid", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(true),pre);
        (cache,logX) = getOptionalNamedArg(cache,env, SOME(st), impl, "logX", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);
        (cache,logY) = getOptionalNamedArg(cache,env, SOME(st), impl, "logY", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);
       (cache,xLabel) = getOptionalNamedArg(cache,env, SOME(st), impl, "xLabel", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("time"),pre);
        (cache,yLabel) = getOptionalNamedArg(cache,env, SOME(st), impl, "yLabel", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST(""),pre);
        (cache,points) = getOptionalNamedArg(cache,env, SOME(st), impl, "points", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);

        (cache,xRange) = getOptionalNamedArg(cache,env, SOME(st), impl, "xRange",  (DAE.T_ARRAY(DAE.DIM_INTEGER(2),DAE.T_REAL_DEFAULT),NONE),
          args, DAE.ARRAY(DAE.ET_REAL(), false, {DAE.RCONST(0.0), DAE.RCONST(0.0)}),pre);// DAE.ARRAY(DAE.ET_REAL(), false, {0, 0}));
        (cache,yRange) = getOptionalNamedArg(cache,env, SOME(st), impl, "yRange",  (DAE.T_ARRAY(DAE.DIM_INTEGER(2),DAE.T_REAL_DEFAULT),NONE),
          args, DAE.ARRAY(DAE.ET_REAL(), false, {DAE.RCONST(0.0), DAE.RCONST(0.0)}),pre);// DAE.ARRAY(DAE.ET_REAL(), false, {0, 0}));

      then

        (cache,DAE.CALL(Absyn.IDENT("plotParametric"),{DAE.ARRAY(DAE.ET_OTHER(),false,vars_3), interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, xRange, yRange}
        ,false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

	//plotParametric2(x,y)
    case (cache,env,Absyn.CREF_IDENT(name = "plotParametric"),vars,args,impl,SOME(st),pre) /* PlotParametric is similar to plot but does not allow a single CREF as an
   argument as you are plotting at least one variable as a function of another.
   Thus, plotParametric has to take an array as an argument, or two componentRefs. */
			local
			  DAE.Exp interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, xRange, yRange;
      equation

        vars_1 = elabVariablenames(vars);
        (cache,interpolation) = getOptionalNamedArg(cache,env, SOME(st), impl, "interpolation", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("linear"),pre);
        (cache,title) = getOptionalNamedArg(cache,env, SOME(st), impl, "title", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("Plot by OpenModelica"),pre);
        (cache,legend) = getOptionalNamedArg(cache,env, SOME(st), impl, "legend", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(true),pre);
        (cache,grid) = getOptionalNamedArg(cache,env, SOME(st), impl, "grid", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(true),pre);
        (cache,logX) = getOptionalNamedArg(cache,env, SOME(st), impl, "logX", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);
        (cache,logY) = getOptionalNamedArg(cache,env, SOME(st), impl, "logY", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);
       (cache,xLabel) = getOptionalNamedArg(cache,env, SOME(st), impl, "xLabel", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST("time"),pre);
        (cache,yLabel) = getOptionalNamedArg(cache,env, SOME(st), impl, "yLabel", DAE.T_STRING_DEFAULT,
          args, DAE.SCONST(""),pre);
        (cache,points) = getOptionalNamedArg(cache,env, SOME(st), impl, "points", DAE.T_BOOL_DEFAULT,
          args, DAE.BCONST(false),pre);

        (cache,xRange) = getOptionalNamedArg(cache,env, SOME(st), impl, "xRange",  (DAE.T_ARRAY(DAE.DIM_INTEGER(2),DAE.T_REAL_DEFAULT),NONE),
          args, DAE.ARRAY(DAE.ET_REAL(), false, {DAE.RCONST(0.0), DAE.RCONST(0.0)}),pre);// DAE.ARRAY(DAE.ET_REAL(), false, {0, 0}));
        (cache,yRange) = getOptionalNamedArg(cache,env, SOME(st), impl, "yRange",  (DAE.T_ARRAY(DAE.DIM_INTEGER(2),DAE.T_REAL_DEFAULT),NONE),
          args, DAE.ARRAY(DAE.ET_REAL(), false, {DAE.RCONST(0.0), DAE.RCONST(0.0)}),pre);// DAE.ARRAY(DAE.ET_REAL(), false, {0, 0}));

      then
        (cache,DAE.CALL(Absyn.IDENT("plotParametric"),
          vars_1,false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "enableSendData"),{Absyn.BOOL(value = enabled)},{},impl,SOME(st),_)
      local
        Boolean enabled;
       then (cache, DAE.CALL(Absyn.IDENT("enableSendData"),{DAE.BCONST(enabled)},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "setDataPort"),{Absyn.INTEGER(value = port)},{},impl,SOME(st),_)
      local
        Integer port;
       then (cache, DAE.CALL(Absyn.IDENT("setDataPort"),{DAE.ICONST(port)},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "setVariableFilter"),{Absyn.ARRAY(arrayExp = strings)},{},impl,SOME(st),_)
      local
        list<Absyn.Exp> strings;
        equation
          vars_1 = elabVariablenames(strings);
       then (cache, DAE.CALL(Absyn.IDENT("setVariableFilter"),{DAE.ARRAY(DAE.ET_OTHER(), false, vars_1)},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));


    case (cache,env,Absyn.CREF_IDENT(name = "timing"),{exp},{},impl,SOME(st),pre)
      equation
        (cache,exp_1,prop,st_1,_) = elabExp(cache,env, exp, impl, SOME(st),true,pre);
      then
        (cache,DAE.CALL(Absyn.IDENT("timing"),{exp_1},false,true,DAE.ET_REAL(),DAE.NO_INLINE),DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_VAR()),st_1);

    case (cache,env,Absyn.CREF_IDENT(name = "generateCode"),{Absyn.CREF(componentRef = cr)},{},impl,SOME(st),_)
      local Absyn.Path className;
      equation
        className = Absyn.crefToPath(cr);
      then
        (cache,DAE.CALL(Absyn.IDENT("generateCode"),{DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER())},
          false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "setLinker"),{Absyn.STRING(value = str)},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("setLinker"),{DAE.SCONST(str)},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));
    case (cache,env,Absyn.CREF_IDENT(name = "setLinkerFlags"),{Absyn.STRING(value = str)},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("setLinkerFlags"),{DAE.SCONST(str)},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));
    case (cache,env,Absyn.CREF_IDENT(name = "setCompiler"),{Absyn.STRING(value = str)},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("setCompiler"),{DAE.SCONST(str)},false, true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

      case (cache,env,Absyn.CREF_IDENT(name = "verifyCompiler"),{},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("verifyCompiler"),{},false,
          true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "setCompilerPath"),{Absyn.STRING(value = str)},{},impl,SOME(st),_)
      then (cache, DAE.CALL(Absyn.IDENT("setCompilerPath"),{DAE.SCONST(str)},false, true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "setCompileCommand"),{Absyn.STRING(value = str)},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("setCompileCommand"),{DAE.SCONST(str)},false,
          true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "setPlotCommand"),{Absyn.STRING(value = str)},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("setPlotCommand"),{DAE.SCONST(str)},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getSettings"),{},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("getSettings"),{},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "setTempDirectoryPath"),{Absyn.STRING(value = str)},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("setTempDirectoryPath"),{DAE.SCONST(str)},
          false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getTempDirectoryPath"),{},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("getTempDirectoryPath"),
          {},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "setInstallationDirectoryPath"),{Absyn.STRING(value = str)},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("setInstallationDirectoryPath"),
          {DAE.SCONST(str)},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getInstallationDirectoryPath"),{},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("getInstallationDirectoryPath"),
          {},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

		case (cache,env,Absyn.CREF_IDENT(name = "setModelicaPath"),{Absyn.STRING(value = str)},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("setModelicaPath"),
          {DAE.SCONST(str)},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "setCompilerFlags"),{Absyn.STRING(value = str)},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("setCompilerFlags"),{DAE.SCONST(str)},false,
          true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "setDebugFlags"),{Absyn.STRING(value = str)},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("setDebugFlags"),{DAE.SCONST(str)},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "setCommandLineOptions"),{stringArray},{},impl,SOME(st),pre)
      local
        Absyn.Exp stringArray;
        DAE.Exp arr;
      equation
          (_, arr, _, _, _) = elabExp(Env.emptyCache(), {}, stringArray, false, NONE(), true,pre);
       then 
         (cache, DAE.CALL(Absyn.IDENT("setCommandLineOptions"),{arr},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "cd"),{Absyn.STRING(value = str)},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("cd"),{DAE.SCONST(str)},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "cd"),{},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("cd"),{},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getVersion"),{},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("getVersion"),{},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getTempDirectoryPath"),{},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("getTempDirectoryPath"),{},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "system"),{Absyn.STRING(value = str)},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("system"),{DAE.SCONST(str)},false,true,DAE.ET_INT(),DAE.NO_INLINE),DAE.PROP(DAE.T_INTEGER_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "readFile"),{Absyn.STRING(value = str)},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("readFile"),{DAE.SCONST(str)},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "readFileNoNumeric"),{Absyn.STRING(value = str)},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("readFileNoNumeric"),{DAE.SCONST(str)},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "listVariables"),{},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("listVariables"),{},false,true,DAE.ET_OTHER(),DAE.NO_INLINE),DAE.PROP(
          (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_NOTYPE(),NONE)),NONE),DAE.C_VAR()),SOME(st));  /* Returns an array of \"component references\" */

    case (cache,env,Absyn.CREF_IDENT(name = "getErrorString"),{},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("getErrorString"),{},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getMessagesString"),{},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("getMessagesString"),{},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "clearMessages"),{},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("clearMessages"),{},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getMessagesStringInternal"),{},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("getMessagesStringInternal"),{},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "runScript"),{Absyn.STRING(value = str)},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("runScript"),{DAE.SCONST(str)},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "loadModel"),{Absyn.CREF(componentRef = cr)},{},impl,SOME(st),_)
      local Absyn.Path className;
      equation
        className = Absyn.crefToPath(cr);
      then
        (cache,DAE.CALL(Absyn.IDENT("loadModel"),{DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER())},
          false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "deleteFile"),{Absyn.STRING(value = str)},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("deleteFile"),{DAE.SCONST(str)},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "loadFile"),{Absyn.STRING(value = str)},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("loadFile"),{DAE.SCONST(str)},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "saveModel"),{Absyn.STRING(value = str),Absyn.CREF(componentRef = cr)},{},impl,SOME(st),_)
      local Absyn.Path className;
      equation
          className = Absyn.crefToPath(cr);
      then
        (cache,DAE.CALL(Absyn.IDENT("saveModel"),
          {DAE.SCONST(str),DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER())},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "saveTotalModel"),{Absyn.STRING(value = str),Absyn.CREF(componentRef = cr)},{},impl,SOME(st),_)
      local Absyn.Path className;
      equation
          className = Absyn.crefToPath(cr);
      then
        (cache,DAE.CALL(Absyn.IDENT("saveTotalModel"),
          {DAE.SCONST(str),DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER())},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "save"),{Absyn.CREF(componentRef = cr)},{},impl,SOME(st),_)
      local Absyn.Path className;
      equation
        className = Absyn.crefToPath(cr);
      then
        (cache,DAE.CALL(Absyn.IDENT("save"),{DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER())},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "saveAll"),{Absyn.STRING(value = str)},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("saveAll"),{DAE.SCONST(str)},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "help"),{},{},impl,SOME(st),_) then (cache, DAE.CALL(Absyn.IDENT("help"),{},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getUnit"),{Absyn.CREF(componentRef = cr),Absyn.CREF(componentRef = cr2)},{},impl,SOME(st),pre)
      equation
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl,pre);
        (cache,cr2_1) = elabUntypedCref(cache,env, cr2, impl,pre);
      then
        (cache,DAE.CALL(Absyn.IDENT("getUnit"),
          {DAE.CREF(cr_1,DAE.ET_OTHER()),DAE.CREF(cr2_1,DAE.ET_OTHER())},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getQuantity"),{Absyn.CREF(componentRef = cr),Absyn.CREF(componentRef = cr2)},{},impl,SOME(st),pre)
      equation
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl,pre);
        (cache,cr2_1) = elabUntypedCref(cache,env, cr2, impl,pre);
      then
        (cache,DAE.CALL(Absyn.IDENT("getQuantity"),
          {DAE.CREF(cr_1,DAE.ET_OTHER()),DAE.CREF(cr2_1,DAE.ET_OTHER())},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getDisplayUnit"),{Absyn.CREF(componentRef = cr),Absyn.CREF(componentRef = cr2)},{},impl,SOME(st),pre)
      equation
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl,pre);
        (cache,cr2_1) = elabUntypedCref(cache,env, cr2, impl,pre);
      then
        (cache,DAE.CALL(Absyn.IDENT("getDisplayUnit"),
          {DAE.CREF(cr_1,DAE.ET_OTHER()),DAE.CREF(cr2_1,DAE.ET_OTHER())},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getMin"),{Absyn.CREF(componentRef = cr),Absyn.CREF(componentRef = cr2)},{},impl,SOME(st),pre)
      equation
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl,pre);
        (cache,cr2_1) = elabUntypedCref(cache,env, cr2, impl,pre);
      then
        (cache,DAE.CALL(Absyn.IDENT("getMin"),
          {DAE.CREF(cr_1,DAE.ET_OTHER()),DAE.CREF(cr2_1,DAE.ET_OTHER())},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getMax"),{Absyn.CREF(componentRef = cr),Absyn.CREF(componentRef = cr2)},{},impl,SOME(st),pre)
      equation
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl,pre);
        (cache,cr2_1) = elabUntypedCref(cache,env, cr2, impl,pre);
      then
        (cache,DAE.CALL(Absyn.IDENT("getMax"),
          {DAE.CREF(cr_1,DAE.ET_OTHER()),DAE.CREF(cr2_1,DAE.ET_OTHER())},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getStart"),{Absyn.CREF(componentRef = cr),Absyn.CREF(componentRef = cr2)},{},impl,SOME(st),pre)
      equation
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl,pre);
        (cache,cr2_1) = elabUntypedCref(cache,env, cr2, impl,pre);
      then
        (cache,DAE.CALL(Absyn.IDENT("getStart"),
          {DAE.CREF(cr_1,DAE.ET_OTHER()),DAE.CREF(cr2_1,DAE.ET_OTHER())},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getFixed"),{Absyn.CREF(componentRef = cr),Absyn.CREF(componentRef = cr2)},{},impl,SOME(st),pre)
      equation
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl,pre);
        (cache,cr2_1) = elabUntypedCref(cache,env, cr2, impl,pre);
      then
        (cache,DAE.CALL(Absyn.IDENT("getFixed"),
          {DAE.CREF(cr_1,DAE.ET_OTHER()),DAE.CREF(cr2_1,DAE.ET_OTHER())},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getNominal"),{Absyn.CREF(componentRef = cr),Absyn.CREF(componentRef = cr2)},{},impl,SOME(st),pre)
      equation
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl,pre);
        (cache,cr2_1) = elabUntypedCref(cache,env, cr2, impl,pre);
      then
        (cache,DAE.CALL(Absyn.IDENT("getNominal"),
          {DAE.CREF(cr_1,DAE.ET_OTHER()),DAE.CREF(cr2_1,DAE.ET_OTHER())},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getStateSelect"),{Absyn.CREF(componentRef = cr),Absyn.CREF(componentRef = cr2)},{},impl,SOME(st),pre)
      equation
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl,pre);
        (cache,cr2_1) = elabUntypedCref(cache,env, cr2, impl,pre);
      then
        (cache,DAE.CALL(Absyn.IDENT("getStateSelect"),
          {DAE.CREF(cr_1,DAE.ET_OTHER()),DAE.CREF(cr2_1,DAE.ET_OTHER())},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(
          (
          DAE.T_ENUMERATION(NONE(),Absyn.IDENT(""),{"never","avoid","default","prefer","always"},{}),NONE),DAE.C_VAR()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "echo"),{bool_exp},{},impl,SOME(st),pre)
      equation
        (cache,bool_exp_1,prop,st_1,_) = elabExp(cache,env, bool_exp, impl, SOME(st),true,pre);
      then
        (cache,DAE.CALL(Absyn.IDENT("echo"),{bool_exp_1},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_CONST()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "getClassesInModelicaPath"),{},{},impl,SOME(st),_)
      then (cache,DAE.CALL(Absyn.IDENT("getClassesInModelicaPath"),{},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_CONST()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "checkExamplePackages"),{},{},impl,SOME(st),_)
    then (cache,DAE.CALL(Absyn.IDENT("checkExamplePackages"),{},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_CONST()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "checkExamplePackages"),{Absyn.STRING(value = str)},{},impl,SOME(st),_)
    then (cache,DAE.CALL(Absyn.IDENT("checkExamplePackages"),{DAE.SCONST(str)},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_CONST()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "checkExamplePackages"),{Absyn.CREF(componentRef = cr)},{},impl,SOME(st),_)
      local Absyn.Path className;
      equation
        className = Absyn.crefToPath(cr);
      then (cache,DAE.CALL(Absyn.IDENT("checkExamplePackages"),{DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER())},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_CONST()),SOME(st));

    case (cache,env,Absyn.CREF_IDENT(name = "checkExamplePackages"),{Absyn.CREF(componentRef = cr), Absyn.STRING(value = str)},{},impl,SOME(st),_)
      local Absyn.Path className;
      equation
        className = Absyn.crefToPath(cr);
      then (cache,DAE.CALL(Absyn.IDENT("checkExamplePackages"),{DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER()), DAE.SCONST(str)},false,true,DAE.ET_STRING(),DAE.NO_INLINE),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_CONST()),SOME(st));


     case (cache,env,Absyn.CREF_IDENT(name = "dumpXMLDAE"),{Absyn.CREF(componentRef = cr)},args,impl,SOME(st),pre)
      local 
        Absyn.Path className;
        DAE.Exp storeInTemp,translationLevel,addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals;
      equation
        className = Absyn.crefToPath(cr);
        cname_str = Absyn.pathString(className);
        (cache,translationLevel) = getOptionalNamedArg(cache, env, SOME(st), impl, "translationLevel",
                                                      DAE.T_STRING_DEFAULT, args, DAE.SCONST("flat"),pre);
        (cache,addOriginalIncidenceMatrix) = getOptionalNamedArg(cache,env, SOME(st), impl, "addOriginalIncidenceMatrix",
          DAE.T_BOOL_DEFAULT, args, DAE.BCONST(false),pre);
        (cache,addSolvingInfo) = getOptionalNamedArg(cache,env, SOME(st), impl, "addSolvingInfo",
          DAE.T_BOOL_DEFAULT, args, DAE.BCONST(false),pre);
        (cache,addMathMLCode) = getOptionalNamedArg(cache,env, SOME(st), impl, "addMathMLCode",
          DAE.T_BOOL_DEFAULT, args, DAE.BCONST(false),pre);
        (cache,dumpResiduals) = getOptionalNamedArg(cache,env, SOME(st), impl, "dumpResiduals",
          DAE.T_BOOL_DEFAULT, args, DAE.BCONST(false),pre);
        (cache,filenameprefix) = getOptionalNamedArg(cache,env, SOME(st), impl, "fileNamePrefix",
          DAE.T_STRING_DEFAULT, args, DAE.SCONST(cname_str),pre);
        (cache,storeInTemp) = getOptionalNamedArg(cache,env, SOME(st), impl, "storeInTemp",
          DAE.T_BOOL_DEFAULT, args, DAE.BCONST(false),pre);
      then
        (cache,DAE.CALL(Absyn.IDENT("dumpXMLDAE"),
          {DAE.CODE(Absyn.C_TYPENAME(className),DAE.ET_OTHER()),translationLevel,addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals,filenameprefix,storeInTemp},false,true,DAE.ET_OTHER(),DAE.NO_INLINE),DAE.PROP(
          (
          DAE.T_ARRAY(DAE.DIM_INTEGER(2),DAE.T_STRING_DEFAULT),NONE),DAE.C_VAR()),SOME(st));
  end matchcontinue;
end elabCallInteractive;


protected function elabVariablenames "function: elabVariablenames
  This function elaborates variablenames to DAE.Exp. A variablename can
  be used in e.g. plot(model,{v1{3},v2.t}) It should only be used in interactive
  functions that uses variablenames as componentreferences.
"
  input list<Absyn.Exp> inAbsynExpLst;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inAbsynExpLst)
    local
      DAE.ComponentRef cr_1;
      list<DAE.Exp> xs_1;
      Absyn.ComponentRef cr;
      list<Absyn.Exp> xs;
      String str, str2;
    case {} then {};
    case ((Absyn.CREF(componentRef = cr) :: xs))
      equation

        xs_1 = elabVariablenames(xs);
      then
        (DAE.CODE(Absyn.C_VARIABLENAME(cr),DAE.ET_OTHER()) :: xs_1);
/*
    case ((Absyn.CALL(Absyn.CREF_IDENT(name="der"), Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(name = str))}, {})) :: xs))
      equation
        str2 = "der(" +& str +& ")";
        cr = Absyn.CREF_IDENT(str2,{});
        xs_1 = elabVariablenames(xs);
      then
        (DAE.CODE(Absyn.C_VARIABLENAME(cr),DAE.ET_OTHER()) :: xs_1);

    case ((Absyn.STRING(value = str) :: xs))
      equation

        xs_1 = elabVariablenames(xs);
      then
        (DAE.SCONST(str) :: xs_1);
*/
  end matchcontinue;
end elabVariablenames;

protected function getOptionalNamedArg "function: getOptionalNamedArg
   This function is used to \"elaborate\" interactive functions optional parameters,
  e.g. simulate(A.b, startTime=1), startTime is an optional parameter
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean inBoolean;
  input Ident inIdent;
  input DAE.Type inType;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input DAE.Exp inExp;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
algorithm
  (outCache,outExp):=
  matchcontinue (inCache,inEnv,inInteractiveInteractiveSymbolTableOption,inBoolean,inIdent,inType,inAbsynNamedArgLst,inExp,inPrefix)
    local
      DAE.Exp exp,exp_1,exp_2,dexp;
      tuple<DAE.TType, Option<Absyn.Path>> t,tp;
      DAE.Const c1;
      list<Env.Frame> env;
      Option<Interactive.InteractiveSymbolTable> st;
      Boolean impl;
      Ident id,id2;
      list<Absyn.NamedArg> xs;
      Env.Cache cache;
      Prefix pre;
    case (cache,_,_,_,_,_,{},exp,_) then (cache,exp);  /* The expected type */
    case (cache,env,st,impl,id,tp,(Absyn.NAMEDARG(argName = id2,argValue = exp) :: xs),dexp,pre)
      local Absyn.Exp exp;
      equation
        true = stringEqual(id, id2);
        (cache,exp_1,DAE.PROP(t,c1),_,_) = elabExp(cache,env, exp, impl, st,true,pre);
        (exp_2,_) = Types.matchType(exp_1, t, tp, true);
      then
        (cache,exp_2);
    case (cache,env,st,impl,id,tp,(Absyn.NAMEDARG(argName = id2,argValue = exp) :: xs),dexp,pre)
      local Absyn.Exp exp;
      equation
        (cache,exp_1) = getOptionalNamedArg(cache,env, st, impl, id, tp, xs, dexp,pre);
      then
        (cache,exp_1);
  end matchcontinue;
end getOptionalNamedArg;

public function elabUntypedCref "function: elabUntypedCref
  This function elaborates a ComponentRef without adding type information.
   Environment is passed along, such that constant subscripts can be elabed using existing
  functions
"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.ComponentRef outComponentRef;
algorithm
  (outCache,outComponentRef) :=
  matchcontinue (inCache,inEnv,inComponentRef,inBoolean,inPrefix)
    local
      list<DAE.Subscript> subs_1;
      list<Env.Frame> env;
      Ident id;
      list<Absyn.Subscript> subs;
      Boolean impl;
      DAE.ComponentRef cr_1;
      Absyn.ComponentRef cr;
      Env.Cache cache;
      DAE.ExpType ty2;
      Prefix pre;
    case (cache,env,Absyn.CREF_IDENT(name = id,subscripts = subs),impl,pre) /* impl */
      equation
        (cache,subs_1,_,_) = elabSubscripts(cache,env, subs, impl,pre);
      then
        (cache,DAE.CREF_IDENT(id,DAE.ET_OTHER(),subs_1));
    case (cache,env,Absyn.CREF_QUAL(name = id,subScripts = subs,componentRef = cr),impl,pre)
      equation
        (cache,subs_1,_,_) = elabSubscripts(cache,env, subs, impl,pre);
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl,pre);
      then
        (cache,DAE.CREF_QUAL(id,DAE.ET_OTHER(),subs_1,cr_1));
  end matchcontinue;
end elabUntypedCref;

protected function pathToComponentRef "function: pathToComponentRef
  This function tranlates a typename to a variable name.
"
  input Absyn.Path inPath;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inPath)
    local
      Ident id;
      DAE.ComponentRef cref;
      Absyn.Path path;
    case (Absyn.FULLYQUALIFIED(path)) then pathToComponentRef(path);
    case (Absyn.IDENT(name = id)) then DAE.CREF_IDENT(id,DAE.ET_OTHER(),{});
    case (Absyn.QUALIFIED(name = id,path = path))
      equation
        cref = pathToComponentRef(path);
      then
        DAE.CREF_QUAL(id,DAE.ET_COMPLEX(Absyn.IDENT(""),{},ClassInf.UNKNOWN(Absyn.IDENT(""))),{},cref);
  end matchcontinue;
end pathToComponentRef;

public function componentRefToPath "function: componentRefToPath
  This function translates a variable name to a type name.
"
  input DAE.ComponentRef inComponentRef;
  output Absyn.Path outPath;
algorithm
  outPath:=
  matchcontinue (inComponentRef)
    local
      Ident s,id;
      Absyn.Path path;
      DAE.ComponentRef cref;
    case (DAE.CREF_IDENT(ident = s,subscriptLst = {})) then Absyn.IDENT(s);
    case (DAE.CREF_QUAL(ident = id,componentRef = cref))
      equation
        path = componentRefToPath(cref);
      then
        Absyn.QUALIFIED(id,path);
  end matchcontinue;
end componentRefToPath;

public function needToRebuild
  input String newFile;
  input String oldFile;
  input Real   buildTime;
  output Boolean buildNeeded;
algorithm
  buildNeeded := matchcontinue(newFile, oldFile, buildTime)
    local String newf,oldf; Real bt,nfmt;
    case ("","",bt) then true; // rebuild all the time if the function has no file!
    case (newf,oldf,bt)
      equation
        true = stringEqual(newf, oldf); // the files should be the same!
        // the new file nf should have an older modification time than the last build
        SOME(nfmt) = System.getFileModificationTime(newf);
        true = realGt(bt, nfmt); // the file was not modified since last build
      then false;
    case (_,_,_) then true;
  end matchcontinue;
end needToRebuild;

public function isFunctionInCflist
"function: isFunctionInCflist
  This function returns true if a function, named by an Absyn.Path,
  is present in the list of precompiled functions that can be executed
  in the interactive mode. If it returns true, it also returns the
  functionHandle stored in the cflist."
  input list<Interactive.CompiledCFunction> inTplAbsynPathTypesTypeLst;
  input Absyn.Path inPath;
  output Boolean outBoolean;
  output Integer outFuncHandle;
  output Real outBuildTime;
  output String outFileName;
algorithm
  (outBoolean,outFuncHandle,outBuildTime,outFileName) := matchcontinue (inTplAbsynPathTypesTypeLst,inPath)
    local
      Absyn.Path path1,path2;
      DAE.Type ty;
      list<Interactive.CompiledCFunction> rest;
      Boolean res;
      Integer handle;
      Real buildTime;
      String fileName;
    case ({},_) then (false, -1, -1.0, "");
    case ((Interactive.CFunction(path1,ty,handle,buildTime,fileName) :: rest),path2)
      equation
        true = ModUtil.pathEqual(path1, path2);
      then
        (true, handle, buildTime, fileName);
    case ((Interactive.CFunction(path1,ty,_,_,_) :: rest),path2)
      equation
        false = ModUtil.pathEqual(path1, path2);
        (res,handle,buildTime,fileName) = isFunctionInCflist(rest, path2);
      then
        (res,handle,buildTime,fileName);
  end matchcontinue;
end isFunctionInCflist;

/*
public function getComponentsWithUnkownArraySizes
"This function returns true if a class
 has unknown array sizes for a component"
  input SCode.Class cl;
  output list<SCode.Element> compElts;
algorithm
  compElts := matchcontinue (cl)
    local
      list<SCode.Element> rest;
      SCode.Element comp;
    // handle the empty things
    case ({}) then ({},{},{});
    // collect components
    case (( comp as SCode.COMPONENT(component=_) ) :: rest) then comp::splitElts(rest);
    // ignore others
    case (_ :: rest) then splitElts(rest);
  end matchcontinue;
end getComponentsWithUnkownArraySizes;

protected function transformFunctionArgumentsIntoModifications
"@author: adrpo
 This function transforms the arguments
 given to a function into a modification."
  input Env.Cache cache;
  input Env.Env env;
  input Boolean impl;
  input Option<Interactive.InteractiveSymbolTable> inSymTab;
  input SCode.Class inClass;
  input list<Absyn.Exp> inPositionalArguments;
  input list<Absyn.NamedArg> inNamedArguments;
  output Option<Absyn.Modification> absynOptMod;
algorithm
  absynOptMod := matchcontinue (cache, env, impl, inSymTab, inClass, inPositionalArguments, inNamedArguments)
    local
      Option<Absyn.Modification> m;
      list<Absyn.NamedArg> na;

    case (_, _, _, _, _,{},{}) then NONE();
    case (cache,env,impl,inSymTab,_,{},inNamedArguments)
      equation
        m = transformToModification(cache,env,impl,inSymTab,inNamedArguments);
      then m;
    case (cache,env,impl,inSymTab,inClass,inPositionalArguments,inNamedArguments)
      equation
        // TODO! FIXME! transform positional to named!
        //na = listAppend(inNamedArguments, transformPositionalToNamed(inClass, inPositionalArguments);
        m = transformToModification(cache,env,impl,inSymTab,inNamedArguments);
      then m;
  end matchcontinue;
end transformFunctionArgumentsIntoModifications;

protected function transformFunctionArgumentsIntoModifications
"@author: adrpo
 This function transforms the arguments
 given to a function into a modification."
  input Env.Cache cache;
  input Env.Env env;
  input Boolean impl;
  input Option<Interactive.InteractiveSymbolTable> inSymTab;
  input SCode.Class inClass;
  input list<Absyn.Exp> inPositionalArguments;
  input list<Absyn.NamedArg> inNamedArguments;
  output Option<Absyn.Modification> absynOptMod;
algorithm
  absynOptMod := matchcontinue (cache, env, impl, inSymTab, inClass, inPositionalArguments, inNamedArguments)
    local
      Option<Absyn.Modification> m;
    case (_, _, _, _, _,{},{}) then NONE();
    case (cache,env,impl,inSymTab,_,{},inNamedArguments)
      equation
        m = transformToModification(cache,env,impl,inSymTab,inNamedArguments);
      then m;
  end matchcontinue;
end transformFunctionArgumentsIntoModifications;
*/

protected function createDummyFarg
  input String name;
  output DAE.FuncArg farg;
algorithm
  farg := (name, (DAE.T_NOTYPE,NONE()));
end createDummyFarg;

protected function transformModificationsToNamedArguments
  input SCode.Class c;
  input String prefix;
  output list<Absyn.NamedArg> namedArguments;
algorithm
  namedArguments := matchcontinue(c, prefix)
    local
      SCode.Mod mod;
      list<Absyn.NamedArg> nArgs;

    // fech modifications from the class if there are any
    case (SCode.CLASS(classDef = SCode.DERIVED(modifications = mod)), prefix)
      equation
        // transform modifications into function arguments and prefix the UNQUALIFIED component
        // references with the function prefix, here world.
        Debug.fprintln("static", "Found modifications: " +& SCode.printModStr(mod));
        /* modification elaboration doesn't work as World is not a package!
           anyhow we can deal with this in a different way, see below
        // build the prefix
        prefix = Prefix.PREFIX(Prefix.PRE(componentName, {}, Prefix.NOCOMPPRE()),
                               Prefix.CLASSPRE(SCode.VAR()));
        // elaborate the modification
        (cache, daeMod) = Mod.elabMod(cache, classEnv, prefix, mod, impl);
        Debug.fprintln("static", "Elaborated modifications: " +& Mod.printModStr(daeMod));
        */
        nArgs = SCodeUtil.translateSCodeModToNArgs(prefix, mod);
        Debug.fprintln("static", "Translated mods to named arguments: " +&
           Util.stringDelimitList(Util.listMap(nArgs, Dump.printNamedArgStr), ", "));
     then
       nArgs;
   // if there isn't a derived class, return nothing
   case (c, prefix)
     then {};
  end matchcontinue;
end transformModificationsToNamedArguments;

protected function addComponentFunctionsToCurrentEnvironment
"author: adrpo
  This function will copy the SCode.Class N given as input and the
  derived dependency into the current scope with name componentName.N"
 input Env.Cache inCache;
 input Env.Env inEnv;
 input SCode.Class scodeClass;
 input Env.Env inClassEnv;
 input String componentName;
 output Env.Cache outCache;
 output Env.Env outEnv;
algorithm
  (outCache, outEnv) := matchcontinue(inCache, inEnv, scodeClass, inClassEnv, componentName)
    local
      Env.Cache cache;
      Env.Env env, classEnv;
      SCode.Class sc, extendedClass;
      String cn, extendsCn;
      SCode.Ident name "the name of the class" ;
      Boolean partialPrefix "the partial prefix" ;
      Boolean encapsulatedPrefix "the encapsulated prefix" ;
      SCode.Restriction restriction "the restriction of the class" ;
      SCode.ClassDef classDef "the class specification" ;
      Absyn.TypeSpec typeSpec "typeSpec: type specification" ;
      Absyn.Path extendsPath, newExtendsPath;
      SCode.Mod modifications ;
      Absyn.ElementAttributes attributes ;
      Option<SCode.Comment> comment "the translated comment from the Absyn" ;
      Option<Absyn.ArrayDim> arrayDim;           
      Absyn.Info info;

    // handle derived component functions i.e. gravityAcceleration = gravityAccelerationTypes
    case(cache, env, sc as SCode.CLASS(name, partialPrefix, encapsulatedPrefix, restriction, classDef as
         SCode.DERIVED(typeSpec as Absyn.TPATH(extendsPath, arrayDim), modifications, attributes, comment),info),
         classEnv, cn)
      equation
        // System.enableTrace();
        // change the class name from gravityAcceleration to be world.gravityAcceleration
        name = componentName +& "." +& name;
        // remove modifications as they are added via transformModificationsToNamedArguments
        // also change extendsPath to world.gravityAccelerationTypes
        extendsCn = Absyn.pathString(Absyn.QUALIFIED(componentName, extendsPath));
        newExtendsPath = Absyn.IDENT(extendsCn);
        sc = SCode.CLASS(name, partialPrefix, encapsulatedPrefix, restriction,
               SCode.DERIVED(Absyn.TPATH(newExtendsPath, arrayDim), SCode.NOMOD(), attributes, comment),info);
        // add the class function to the environment
        env = Env.extendFrameC(env, sc);
        // lookup the derived class
        (_, extendedClass, _) = Lookup.lookupClass(cache, classEnv, extendsPath, true);
        // construct the extended class gravityAccelerationType
        // with a different name: world.gravityAccelerationType
        SCode.CLASS(name, partialPrefix, encapsulatedPrefix, restriction, classDef, info) = extendedClass;
        // change the class name from gravityAccelerationTypes to be world.gravityAccelerationTypes
        name = componentName +& "." +& name;
        // construct the extended class world.gravityAccelerationType
        sc = SCode.CLASS(name, partialPrefix, encapsulatedPrefix, restriction, classDef, info);
        // add the extended class function to the environment
        env = Env.extendFrameC(env, sc);
      then (cache, env);
    // handle component functions made of parts
    case(cache, env, sc as SCode.CLASS(name, partialPrefix, encapsulatedPrefix, restriction, classDef as _, info),
         classEnv, cn)
      equation
        // System.enableTrace();
        // change the class name from gravityAcceleration to be world.gravityAcceleration
        name = componentName +& "." +& name;
        // remove modifications as they are added via transformModificationsToNamedArguments
        // also change extendsPath to world.gravityAccelerationTypes
        sc = SCode.CLASS(name, partialPrefix, encapsulatedPrefix, restriction, classDef, info);
        // add the class function to the environment
        env = Env.extendFrameC(env, sc);
      then (cache, env);
  end matchcontinue;
end addComponentFunctionsToCurrentEnvironment;

protected function elabCallArgs "
function: elabCallArgs
  Given the name of a function and two lists of expression and
  NamedArg respectively to be used
  as actual arguments in a function call to that function, this
  function finds the function definition and matches the actual
  arguments to the formal parameters."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Prefix inPrefix;
	output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae) :=
  elabCallArgs2(inCache,inEnv,inPath,inAbsynExpLst,inAbsynNamedArgLst,inBoolean,Util.makeStatefulBoolean(false),inInteractiveInteractiveSymbolTableOption,inPrefix);
end elabCallArgs;
      
protected function elabCallArgs2 "
function: elabCallArgs
  Given the name of a function and two lists of expression and
  NamedArg respectively to be used
  as actual arguments in a function call to that function, this
  function finds the function definition and matches the actual
  arguments to the formal parameters."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inBoolean;
  input Util.StatefulBoolean stopElab;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Prefix inPrefix;
	output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outDae) :=
  matchcontinue (inCache,inEnv,inPath,inAbsynExpLst,inAbsynNamedArgLst,inBoolean,stopElab,inInteractiveInteractiveSymbolTableOption,inPrefix)
    local
      DAE.Type t,outtype,restype,functype,tp1;
      list<tuple<Ident, DAE.Type>> fargs;
      list<Env.Frame> env_1,env_2,env;
      list<Slot> slots,newslots,newslots2,slots2;
      list<DAE.Exp> args_1,args_2,args1;
      list<DAE.Const> constlist;
      DAE.Const const;
      DAE.TupleConst tyconst;
      DAE.Properties prop,prop_1;
      SCode.Class cl;
      Absyn.Path fn,fn_1,fqPath;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs, translatedNArgs;
      Boolean impl,tuple_,builtin;
      DAE.InlineType inline;
      Option<Interactive.InteractiveSymbolTable> st;
      list<DAE.Type> typelist,ktypelist,tys;
      list<DAE.Dimension> vect_dims;
      DAE.Exp call_exp;
      list<Ident> t_lst;
      Ident fn_str,types_str,scope,pre_str;
      String s,name,argStr,id;
      Env.Cache cache;
      DAE.ExpType tp;
      SCode.Mod mod;
      DAE.Mod tmod;
      SCode.Class cl;
      Option<Absyn.Modification> absynOptMod;
      ClassInf.State complexClassType;
      DAE.DAElist dae,dae1,dae2,dae3,dae4,outDae;
      Prefix pre;
      SCode.Class c;
      SCode.Restriction re;
      Integer index;
      list<String> fieldNames;
      list<DAE.Var> vars;

    /* Record constructors that might have come from Graphical expressions with unknown array sizes */
    /*
     * adrpo: HACK! HACK! TODO! remove this case if records with unknown sizes can be instantiated
     * this could be also fixed by transforming the function call arguments into modifications and
     * send the modifications as an option in Lookup.lookup* functions!
     */
    case (cache,env,fn,args,nargs,impl,stopElab,st,pre)
      local list<SCode.Element> comps; list<String> names;
      equation
        (cache,cl as SCode.CLASS(restriction = SCode.R_PACKAGE()),_) =
           Lookup.lookupClass(cache, env, Absyn.IDENT("GraphicalAnnotationsProgram____"), false);
        (cache,cl as SCode.CLASS(name = name, restriction = SCode.R_RECORD()),env_1) = Lookup.lookupClass(cache, env, fn, false);
        (cache,cl,env_2) = Lookup.lookupRecordConstructorClass(cache,env_1 /* env */, fn);
        (comps,_::names) = SCode.getClassComponents(cl); // remove the fist one as it is the result!
        /*
        (cache,(t as (DAE.T_FUNCTION(fargs,(outtype as (DAE.T_COMPLEX(complexClassType as ClassInf.RECORD(name),_,_,_),_))),_)),env_1)
        	= Lookup.lookupType(cache, env, fn, true);
        */
        fargs = Util.listMap(names, createDummyFarg);
        slots = makeEmptySlots(fargs);
        (cache,args_1,newslots,constlist,_,_) = elabInputArgs(cache, env, args, nargs, slots, false /*checkTypes*/ ,impl,{},pre);
        const = Util.listFold(constlist, Types.constAnd, DAE.C_CONST());
        (cache,newslots2) = fillDefaultSlots(cache, newslots, cl, env_2, impl,pre);
        args_2 = expListFromSlots(newslots2);
        tp = complexTypeFromSlots(newslots2,ClassInf.UNKNOWN(Absyn.IDENT("")));
        //tyconst = elabConsts(outtype, const);
        //prop = getProperties(outtype, tyconst);
      then
        (cache,DAE.CALL(fn,args_2,false,false,tp,DAE.NO_INLINE),DAE.PROP((DAE.T_NOTYPE(),NONE()),DAE.C_CONST()),DAEUtil.emptyDae);

    // adrpo: deal with function call via an instance: MultiBody world.gravityAcceleration
    case (cache, env, fn, args, nargs, impl, stopElab, st,pre)
      local
        DAE.ExpType tp;
        String str2, stringifiedInstanceFunctionName;
        list<DAE.Type> ltypes;
        list<String> lstr;
        Absyn.Path fnPrefix, componentType, correctFunctionPath, functionClassPath;
        DAE.ComponentRef cr;
        Absyn.InnerOuter innerOuter;
        SCode.Ident componentName, fnIdent;
        Env.Env classEnv;
        SCode.Class scodeClass;
        SCode.Mod mod;
        Prefix.Prefix prefix;
        DAE.Mod daeMod;

      equation
        fnPrefix = Absyn.stripLast(fn); // take the prefix: word
        fnIdent = Absyn.pathLastIdent(fn); // take the suffix: gravityAcceleration
        Absyn.IDENT(componentName) = fnPrefix; // see that is just a name TODO! this might be a path
        (_, _, SOME((SCode.COMPONENT(innerOuter=innerOuter, typeSpec = Absyn.TPATH(componentType, _)),_)), _) =
          Lookup.lookupIdent(cache, env, componentName); // search for the component
        // join the type with the function name: Modelica.Mechanics.MultiBody.World.gravityAcceleration
        functionClassPath = Absyn.joinPaths(componentType, Absyn.IDENT(fnIdent));

        Debug.fprintln("static", "Looking for function: " +& Absyn.pathString(fn));
        // lookup the function using the correct typeOf(world).functionName
        Debug.fprintln("static", "Looking up class: " +& Absyn.pathString(functionClassPath));
        (_, scodeClass, classEnv) = Lookup.lookupClass(cache, env, functionClassPath, true);
        Util.setStatefulBoolean(stopElab,true);
        // see if class scodeClass is derived and then
        // take the applied modifications and transform
        // them into function arguments by prefixing them
        // with the component reference (here world)
        // Example:
        //   The derived function:
        //     function gravityAcceleration = gravityAccelerationTypes(
        //                  gravityType = gravityType,
        //                  g = g * Modelica.Math.Vectors.normalize(n),
        //                  mue = mue);
        //   The actual call (that we are handling here):
        //     g_0 = world.gravityAcceleration(frame_a.r_0 + Frames.resolve1(frame_a.R, r_CM));
        //   Will be rewriten to:
        //     g_0 = world.gravityAcceleration(frame_a.r_0 + Frames.resolve1(frame_a.R, r_CM),
        //                  gravityType = world.gravityType,
        //                  g = world.g*Modelica.Math.Vectors.normalize(world.n, 1E-013),
        //                  mue = world.mue));
        // if the class is derived translate modifications to named arguments
        translatedNArgs = transformModificationsToNamedArguments(scodeClass, componentName);
        (cache, env) = addComponentFunctionsToCurrentEnvironment(cache, env, scodeClass, classEnv, componentName);
        // transform Absyn.QUALIFIED("world", Absyn.IDENT("gravityAcceleration")) to
        // Absyn.IDENT("world.gravityAcceleration").
        stringifiedInstanceFunctionName = Absyn.pathString(fn);
        correctFunctionPath = Absyn.IDENT(stringifiedInstanceFunctionName);
        // use the extra arguments if any
        nargs = listAppend(nargs, translatedNArgs);
        // call the class normally
        (cache,call_exp,prop_1,dae) = elabCallArgs(cache, env, correctFunctionPath, args, nargs, impl, st,pre);
      then
        (cache,call_exp,prop_1,dae);

    /* Record constructors, user defined or implicit */ // try the hard stuff first
    case (cache,env,fn,args,nargs,impl,stopElab,st,pre)
      local
        String lastId;
        list<Env.Frame> recordEnv;
        SCode.Class recordCl;
        Absyn.Path fpath;
      equation
        (cache,(t as (DAE.T_FUNCTION(fargs,(outtype as (DAE.T_COMPLEX(complexClassType as ClassInf.RECORD(path=_),_,_,_),_)),DAE.NO_INLINE),_)),_)
        	= Lookup.lookupType(cache,env, fn, true);
//        print(" inst record: " +& name +& " \n");
        (_,recordCl,recordEnv) = Lookup.lookupClass(cache,env,fn, false);
        true = MetaUtil.classHasRestriction(recordCl, SCode.R_RECORD());
        Util.setStatefulBoolean(stopElab,true);
        lastId = Absyn.pathLastIdent(fn);
        fn = Env.joinEnvPath(recordEnv, Absyn.IDENT(lastId));

        slots = makeEmptySlots(fargs);
        (cache,args_1,newslots,constlist,_,dae1) = elabInputArgs(cache,env, args, nargs, slots, true /*checkTypes*/ ,impl, {},pre);
        //print(" args: " +& Util.stringDelimitList(Util.listMap(args_1,Exp.printExpStr), ", ") +& "\n");
        vect_dims = slotsVectorizable(newslots);
        const = Util.listFold(constlist, Types.constAnd, DAE.C_CONST());
        tyconst = elabConsts(outtype, const);
        prop = getProperties(outtype, tyconst);
        (cache,env_2,cl) = Lookup.buildRecordConstructorClass(cache, recordEnv, recordCl);
        (cache,newslots2) = fillDefaultSlots(cache, newslots, cl, env_2, impl,pre);
        args_2 = expListFromSlots(newslots2);
        tp = complexTypeFromSlots(newslots2,ClassInf.RECORD(fn));
        (call_exp,prop_1) = vectorizeCall(DAE.CALL(fn,args_2,false,false,tp,DAE.NO_INLINE), vect_dims, newslots2, prop);
        //print(" RECORD CONSTRUCT("+&Absyn.pathString(fn)+&")= "+&Exp.printExpStr(call_exp)+&"\n");
       /* Instantiate the function and add to dae function tree*/
        (cache,dae) = instantiateDaeFunction(cache,recordEnv,fn,false/*record constructor never builtin*/,SOME(recordCl),true);
        dae = DAEUtil.joinDaes(dae,dae1);
      then
        (cache,call_exp,prop_1,dae);

    /* ------ */
    case (cache,env,fn,args,nargs,impl,stopElab,st,pre) /* Metamodelica extension, added by simbj */
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        false = Util.getStatefulBoolean(stopElab);
        (cache,t as (DAE.T_METARECORD(index,vars),_),env_1) = Lookup.lookupType(cache, env, fn, false);
        Util.setStatefulBoolean(stopElab,true);
        (cache,c,env_1) = Lookup.lookupClass(cache, env_1, fn, false);
        // (_, _, _, _, (DAE.T_COMPLEX(complexClassType = ClassInf.META_RECORD(_), complexVarLst = vars),_), _, _, _) = Inst.instClass(cache,env_1,DAE.NOMOD(),Prefix.NOPRE(), Connect.emptySet,c,{},false,Inst.INNER_CALL(), ConnectionGraph.EMPTY);
        fieldNames = Util.listMap(vars, Types.getVarName);
        tys = Util.listMap(vars, Types.getVarType);
        fargs = Util.listThreadTuple(fieldNames, tys);
        slots = makeEmptySlots(fargs);
        (cache,args_1,newslots,constlist,_,dae1) = elabInputArgs(cache,env, args, nargs, slots, true /*checkTypes*/ ,impl,{},pre);
        const = Util.listReduce(constlist, Types.constAnd);
        tyconst = elabConsts(t, const);
        prop = getProperties(t, tyconst);
        (cache,newslots2) = fillDefaultSlots(cache,newslots, c, env, impl,pre);
        args_2 = expListFromSlots(newslots2);
        (cache, fqPath) = Inst.makeFullyQualified(cache, env_1, fn);
      then
        (cache,DAE.METARECORDCALL(fqPath,args_2,fieldNames,index),prop,dae1);
        /* ------ */

    case (cache,env,fn,args,nargs,impl,stopElab,st,pre) /* ..Other functions */
      local
        DAE.ExpType tp;
        DAE.Exp callExp;
        String str2,debugPrintString;
        list<DAE.Type> ltypes;
        list<String> lstr;
      equation
        false = Util.getStatefulBoolean(stopElab);
        (cache,typelist as _::_,dae1) = Lookup.lookupFunctionsInEnv(cache, env, fn)
        "PR. A function can have several types. Taking an array with
         different dimensions as parameter for example. Because of this we
         cannot just lookup the function name and trust that it
         returns the correct function. It returns just one
         functiontype of several possibilites. The solution is to send
         in the function type of the user function and check both the
         function name and the function\'s type." ;
        Util.setStatefulBoolean(stopElab,true);
        (cache,args_1,constlist,restype,functype as (DAE.T_FUNCTION(inline = inline),_),vect_dims,slots,dae2) =
          elabTypes(cache, env, args, nargs, typelist, true/* Check types*/, impl,pre)
          "The constness of a function depends on the inputs. If all inputs are constant the call itself is constant." ;
        fn_1 = deoverloadFuncname(fn, functype);
        tuple_ = isTuple(restype);
        (cache,builtin) = isBuiltinFunc(cache,fn_1,pre);
        const = Util.listFold(constlist, Types.constAnd, DAE.C_CONST());
        (cache,const) = determineConstSpecialFunc(cache,env,const,fn);
        tyconst = elabConsts(restype, const);
        prop = getProperties(restype, tyconst);
        tp = Types.elabType(restype);
        (cache,args_2,slots2) = addDefaultArgs(cache,env,args_1,fn,slots,impl,pre);
        callExp = DAE.CALL(fn_1,args_2,tuple_,builtin,tp,inline);

        //debugPrintString = Util.if_(Util.isEqual(DAE.NORM_INLINE,inline)," Inline: " +& Absyn.pathString(fn_1) +& "\n", "");print(debugPrintString);

        (call_exp,prop_1) = vectorizeCall(callExp, vect_dims, slots2, prop);

        /* Instantiate the function and add to dae function tree*/
        (cache,dae3) = instantiateDaeFunction(cache,env,fn,builtin,NONE,true);
        /* Instantiate any implicit record constructors needed and add them to the dae function tree */
        (cache,dae4) = instantiateImplicitRecordConstructors(cache, env, args_1, st);
        //dae4 = DAEUtil.emptyDae;
        dae = DAEUtil.joinDaeLst({dae1,dae2,dae3,dae4});
      then
        (cache,call_exp,prop_1,dae);

    case (cache,env,fn,args,nargs,impl,stopElab,st,pre) /* no matching type found, no candidates. */
      equation
        (cache,{},_) = Lookup.lookupFunctionsInEnv(cache,env, fn);
        fn_str = Absyn.pathString(fn);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        fn_str = fn_str +& " in component " +& pre_str;
        Error.addMessage(Error.NO_MATCHING_FUNCTION_FOUND_NO_CANDIDATE, {fn_str});
      then
        fail();

    case (cache,env,fn,args,nargs,impl,stopElab,st,pre) /* no matching type found, with -one- candidate */
      equation
        (cache,typelist as {tp1},_) = Lookup.lookupFunctionsInEnv(cache, env, fn);
        (cache,args_1,constlist,restype,functype,vect_dims,slots,_) =
          elabTypes(cache, env, args, nargs, typelist, false/* Do not check types*/, impl,pre);
        argStr = Exp.printExpListStr(args_1);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        fn_str = Absyn.pathString(fn) +& "(" +& argStr +& ") of type " +& Types.unparseType(functype);
        types_str = Types.unparseType(tp1) ;
        Error.addMessage(Error.NO_MATCHING_FUNCTION_FOUND, {fn_str,pre_str,types_str});
      then
        fail();

    case (cache,env,fn,args,nargs,impl,stopElab,st,pre) /* no matching type found, with candidates */
      equation
        (cache,typelist as _::_::_,_) = Lookup.lookupFunctionsInEnv(cache,env, fn);

        t_lst = Util.listMap(typelist, Types.unparseType);
        fn_str = Absyn.pathString(fn);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        types_str = Util.stringDelimitList(t_lst, "\n -");
        //fn_str = fn_str +& " in component " +& pre_str;
        Error.addMessage(Error.NO_MATCHING_FUNCTION_FOUND, {fn_str,pre_str,types_str});
      then
        fail();

    /*// lookup failure -> not needed is caught below
    case (cache,env,fn,args,nargs,impl,st)
      equation
        failure((_,_,_) = Lookup.lookupFunctionsInEnv(cache, env, fn));
        fn_str = Absyn.pathString(fn);
        scope = Env.printEnvPathStr(env);
        Error.addMessage(Error.LOOKUP_ERROR, {fn_str,scope});
      then
        fail(); */

    case (cache,env,fn,args,nargs,impl,stopElab,st,pre)
      local
        list<Absyn.Exp> t4;
      equation
        t4 = args;
        failure((_,_,_) = Lookup.lookupType(cache,env, fn, false)) "msg" ;
        scope = Env.printEnvPathStr(env);
        fn_str = Absyn.pathString(fn);
        Error.addMessage(Error.LOOKUP_ERROR, {fn_str,scope}); // No need to add prefix because only depends on scope?
      then
        fail();
    
    case (cache,env,fn,args,nargs,impl,stopElab,st,pre)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- Static.elabCallArgs failed on: " +& Absyn.pathString(fn) +& " in env: " +& Env.printEnvPathStr(env));
      then
        fail();
  end matchcontinue;
end elabCallArgs2;

protected function instantiateDaeFunction "help function to elabCallArgs. Instantiates the function as a dae and adds it to the
functiontree of a newly created dae"
  input Env.Cache inCache;
  input Env.Env env;
  input Absyn.Path name;
  input Boolean builtin "builtin functions create empty dae";
  input option<SCode.Class> clOpt "if not present, looked up by name in environment";
  input Boolean printErrorMsg "if true, prints an error message if the function could not be instantiated";
  output Env.Cache outCache;
  output DAE.DAElist outDae;
algorithm
  (outCache,outDae) := matchcontinue(inCache,env,name,builtin,clOpt,printErrorMsg)
  local Env.Cache cache;
    SCode.Class cl; DAE.DAElist dae;
    String id,id2;
    /* Builtin functions skipped*/
    case(cache,env,name,true,_,_) then (cache,DAEUtil.emptyDae);

    /* External object functions skipped*/
    case(cache,env,name,_,_,_)
      equation
        (_,true) = isExternalObjectFunction(cache,env,name);
      then (cache,DAEUtil.emptyDae);

      /* Recursive calls (by looking at envinronment) skipped */
    case(cache,env,name,false,NONE,_)
      equation
        false = Env.isTopScope(env);
        true = Absyn.pathSuffixOf(name,Env.getEnvName(env));            
      then (cache,DAEUtil.emptyDae);

    /* Recursive calls (by looking in cache) skipped */
    case(cache,env,name,false,_,_)
      equation
        (cache,cl,env) = Lookup.lookupClass(cache,env,name,false);
        (cache,name) = Inst.makeFullyQualified(cache,env,name);
        _ = Env.getCachedInstFunc(cache,name);
      then (cache,DAEUtil.emptyDae);

    /* Class must be looked up*/
    case(cache,env,name,false,NONE,_)
      equation
        (cache,cl,env) = Lookup.lookupClass(cache,env,name,false);
        (cache,name) = Inst.makeFullyQualified(cache,env,name);
        cache = Env.addCachedInstFunc(cache,name);
        (cache,env,_,dae) = Inst.implicitFunctionInstantiation(cache,env,InnerOuter.emptyInstHierarchy,DAE.NOMOD(),Prefix.NOPRE(),Connect.emptySet,cl,{});
        dae = DAEUtil.addDaeFunction(dae);
      then (cache,dae);

    /* class already available*/
    case(cache,env,name,false,SOME(cl),_)
      equation
        (cache,name) = Inst.makeFullyQualified(cache,env,name);
        (cache,env,_,dae) = Inst.implicitFunctionInstantiation(cache,env,InnerOuter.emptyInstHierarchy,DAE.NOMOD(),Prefix.NOPRE(),Connect.emptySet,cl,{});
        dae = DAEUtil.addDaeFunction(dae);
      then (cache,dae);

    /* Call to function reference variable */
    case(cache,env,name,false,NONE,_)
      local
        DAE.ComponentRef cref;
      equation
        cref = pathToComponentRef(name);
        (cache,_,(DAE.T_FUNCTION(funcArg = _),_),_,_,_,env,_,_) = Lookup.lookupVar(cache,env,cref);
        dae = DAEUtil.emptyDae;
      then (cache,dae);

    case(cache,env,name,_,_,true)
      equation
        print("instantiateDaeFunction failed for "+&Absyn.pathString(name)+&" in scope: " +& Env.printEnvPathStr(env) +& "\n");
      then fail();
  end matchcontinue;
end instantiateDaeFunction;

protected function instantiateImplicitRecordConstructors
  "Given a list of arguments to a function, this function checks if any of the
  arguments are component references to a record instance, and instantiates the
  record constructors for those components. These are implicit record
  constructors, because they are not explicitly called, but are needed when code
  is generated for record instances as function input arguments."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> args;
  input Option<Interactive.InteractiveSymbolTable> st;
  output Env.Cache outCache;
  output DAE.DAElist outDae;
algorithm
  (outCache, outDae) := matchcontinue(inCache, inEnv, args, st)
    local
      list<DAE.Exp> rest_args;
      Absyn.Path record_name;
      Env.Cache cache;
      DAE.DAElist dae1, dae2;
    case (_, _, _, SOME(_)) then (inCache, DAEUtil.emptyDae);
    case (_, _, {}, _) then (inCache, DAEUtil.emptyDae);
    case (_, _, DAE.CREF(ty = DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = record_name))) :: rest_args, _)
      equation
        (cache, dae1) = instantiateDaeFunction(inCache, inEnv, record_name, false, NONE, false);
        (cache, dae2) = instantiateImplicitRecordConstructors(cache, inEnv, rest_args, NONE);
        dae1 = DAEUtil.joinDaes(dae1, dae2);
      then (cache, dae1);
    case (_, _, _ :: rest_args, _)
      equation
        (cache, dae1) = instantiateImplicitRecordConstructors(inCache, inEnv, rest_args, NONE);
      then (cache, dae1);
  end matchcontinue;
end instantiateImplicitRecordConstructors;

protected function addDefaultArgs "adds default values (from slots) to argument list of function call.
This is needed because when generating C-code all arguments must be present in the function call.

If in future C++ code is generated instead, this is not required, since C++ allows default values for arguments.
"
  input Env.Cache inCache;
  input Env.Env env;
  input list<DAE.Exp> inArgs;
  input Absyn.Path fn;
  input list<Slot> slots;
  input Boolean impl;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output list<DAE.Exp> outArgs;
  output list<Slot> outSlots;
algorithm
  (outCache,outArgs,outSlots) := matchcontinue(cache,env,inArgs,fn,slots,impl,inPrefix)
    local Env.Cache cache;
      SCode.Class cl;
      Env.Env env_2;
      list<DAE.Exp> args_2;
      list<Slot> slots2;
      Prefix pre;
      // If we find a class
    case(cache,env,inArgs,fn,slots,impl,pre) equation
      // We need the class to fill default slots
      (cache,cl,env_2) = Lookup.lookupClass(cache,env,fn,false);
      (cache,slots2) = fillDefaultSlots(cache,slots, cl, env_2, impl,pre);
      // Update argument list to include default values.
      args_2 = expListFromSlots(slots2);
    then (cache,args_2,slots2);

      // If no class found. builtin, with no defaults. NOTE: if builtin class with defaults exist
      // both its type -and- its class must be added to Builtin.mo
    case(cache,env,inArgs,fn,slots,impl,_)
    then (cache,inArgs,slots);
  end matchcontinue;
end addDefaultArgs;


protected function determineConstSpecialFunc "For the special functions constructor and destructor,
in external object,
the constantness is always variable, even if arguments are constant, because they should be called during
runtime and not during compiletime."
  input Env.Cache inCache;
  input Env.Env env;
  input DAE.Const inConst;
  input Absyn.Path funcName;
  output Env.Cache outCache;
  output DAE.Const outConst;
algorithm
  (outCache,outConst) := matchcontinue(inCache,env,inConst,funcName)
  local Absyn.Path path;
    Env.Cache cache;
    SCode.Class c;
    Env.Env env_1;
    list<SCode.Element> els;
    // External Object found, constructor call is not constant.
    case (cache,env,inConst, path) equation
      (cache,true) = isExternalObjectFunction(cache,env,path);
      then (cache,DAE.C_VAR());
    case (cache,env,inConst,path) then (cache,inConst);
  end matchcontinue;
end determineConstSpecialFunc;

public function isExternalObjectFunction
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.Path path;
  output Env.Cache outCache;
  output Boolean res;
algorithm
  (outCache,res) := matchcontinue(cache,env,path)
    local Env.Cache cache; Env.Env env_1;
      list<SCode.Element> els;
    case (cache,env,path) equation
      (cache,SCode.CLASS(classDef = SCode.PARTS(elementLst = els)),env_1)
        	= Lookup.lookupClass(cache,env, path, false);
      true = Inst.isExternalObject(els);
      then (cache,true);
    case (cache,env,path) equation
      "constructor" = Absyn.pathLastIdent(path); then (cache,true);
    case (cache,env,path) equation
      "destructor" = Absyn.pathLastIdent(path); then (cache,true);
    case (cache,env,path)  then (cache,false);
  end matchcontinue;
end isExternalObjectFunction;

protected function vectorizeCall "function: vectorizeCall
  author: PA

  Takes an expression and a list of array dimensions and the Slot list.
  It will vectorize the expression over the dimension given as array dim
  for the slots which have that dimension.
  For example foo:(Real,Real[:])=> Real
  foo(1:2,{1,2;3,4}) vectorizes with arraydim [2] to 
  {foo(1,{1,2}),foo(2,{3,4})}
"
  input DAE.Exp inExp;
  input list<DAE.Dimension> inTypesArrayDimLst;
  input list<Slot> inSlotLst;
  input DAE.Properties inProperties;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outExp,outProperties) := matchcontinue (inExp,inTypesArrayDimLst,inSlotLst,inProperties)
    local
      DAE.Exp e,vect_exp,vect_exp_1;
      tuple<DAE.TType, Option<Absyn.Path>> e_type,tp,tp_1;
      DAE.Properties prop;
      DAE.ExpType exp_type;
      DAE.Const c;
      Absyn.Path fn;
      list<DAE.Exp> args,expl;
      Boolean tuple_,builtin,scalar;
      DAE.InlineType inl;
      Integer int_dim;
      DAE.Dimension dim;
      list<DAE.Dimension> ad;
      list<Slot> slots;
      DAE.ExpType etp;
    case (e,{},_,prop) then (e,prop);
    
    // If the dimension is not defined we can't vectorize the call. If we are running
    // checkModel this should succeed anyway, since we might be checking a function
    // that takes a vector of unknown size. So pretend that the dimension is 1.
    case (e, (DAE.DIM_NONE :: ad), slots, prop)
      equation
        true = OptManager.getOption("checkModel");
        (vect_exp_1, prop) = vectorizeCall(e, DAE.DIM_INTEGER(1) :: ad, slots, prop);
      then 
        (vect_exp_1, prop);
        
    /* Scalar expression, i.e function call */
    case (e as DAE.CALL(path = fn,expLst = args,tuple_ = tuple_,builtin = builtin,ty = etp,inlineType=inl),(dim :: ad),slots,DAE.PROP(tp,c)) 
      equation 
        int_dim = Exp.dimensionSize(dim);
        exp_type = Types.elabType(Types.liftArray(tp, dim)) "pass type of vectorized result expr";
        vect_exp = vectorizeCallScalar(DAE.CALL(fn,args,tuple_,builtin,etp,inl), exp_type, int_dim, slots);
        tp = Types.liftArray(tp, dim);
        (vect_exp_1,prop) = vectorizeCall(vect_exp, ad, slots, DAE.PROP(tp,c));
      then
        (vect_exp_1,prop);
    
    /* array expression of function calls */
    case (DAE.ARRAY(scalar = scalar,array = expl),(dim :: ad),slots,DAE.PROP(tp,c)) 
      equation
        int_dim = Exp.dimensionSize(dim);
        exp_type = Types.elabType(Types.liftArray(tp, dim));
        vect_exp = vectorizeCallArray(inExp, int_dim, slots);
        tp = Types.liftArrayRight(tp, dim);
        (vect_exp_1,prop) = vectorizeCall(vect_exp, ad, slots, DAE.PROP(tp,c));
      then
        (vect_exp_1,prop);
        
    case (_,_,_,_)
      equation
        Debug.fprintln("failtrace", "- Static.vectorizeCall failed");
      then
        fail();
  end matchcontinue;
end vectorizeCall;

protected function vectorizeCallArray
"function : vectorizeCallArray
  author: PA

  Helper function to vectorize_call, vectoriezes ARRAY expression to
  an array of array expressions."
  input DAE.Exp inExp;
  input Integer inInteger;
  input list<Slot> inSlotLst;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp,inInteger,inSlotLst)
    local
      list<DAE.Exp> arr_expl,expl;
      Boolean scalar_1,scalar;
      DAE.Exp res_exp;
      DAE.ExpType tp,exp_tp;
      Integer cur_dim;
      list<Slot> slots;
    case (DAE.ARRAY(ty = tp,scalar = scalar,array = expl),cur_dim,slots) /* cur_dim */
      equation
        arr_expl = vectorizeCallArray2(expl, tp, cur_dim, slots);
        scalar_1 = Exp.typeBuiltin(tp);
        tp = Exp.liftArrayRight(tp, DAE.DIM_INTEGER(cur_dim));
        res_exp = DAE.ARRAY(tp,scalar_1,arr_expl);
      then
        res_exp;
  end matchcontinue;
end vectorizeCallArray;

protected function vectorizeCallArray2
"function: vectorizeCallArray2
  author: PA
  Helper function to vectorizeCallArray"
  input list<DAE.Exp> inExpExpLst;
  input DAE.ExpType inType;
  input Integer inInteger;
  input list<Slot> inSlotLst;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inExpExpLst,inType,inInteger,inSlotLst)
    local
      DAE.ExpType tp,e_tp;
      Integer cur_dim;
      list<Slot> slots;
      DAE.Exp e_1,e;
      list<DAE.Exp> es_1,es;
    case ({},tp,cur_dim,slots) then {};
    case ((e :: es),e_tp,cur_dim,slots)
      equation
        e_1 = vectorizeCallArray3(e, e_tp, cur_dim, slots);
        es_1 = vectorizeCallArray2(es, e_tp, cur_dim, slots);
      then
        (e_1 :: es_1);
  end matchcontinue;
end vectorizeCallArray2;

protected function vectorizeCallArray3 "function: vectorizeCallArray3
  author: PA

  Helper function to vectorize_call_array_2
"
  input DAE.Exp inExp;
  input DAE.ExpType inType;
  input Integer inInteger;
  input list<Slot> inSlotLst;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp,inType,inInteger,inSlotLst)
    local
      DAE.Exp e_1,e;
      DAE.ExpType e_tp;
      Integer cur_dim;
      list<Slot> slots;
    case ((e as DAE.CALL(path = _)),e_tp,cur_dim,slots) /* cur_dim */
      equation
        e_1 = vectorizeCallScalar(e, e_tp, cur_dim, slots);
      then
        e_1;
    case ((e as DAE.ARRAY(ty = _)),e_tp,cur_dim,slots)
      equation
        e_1 = vectorizeCallArray(e, cur_dim, slots);
      then
        e_1;
  end matchcontinue;
end vectorizeCallArray3;

protected function vectorizeCallScalar
"function: vectorizeCallScalar
  author: PA

  Helper function to vectorizeCall, vectorizes CALL expressions to
  array expressions."
  input DAE.Exp inExp "e.g. abs(v)";
  input DAE.ExpType inType " e.g. Real[3], result of vectorized call";
  input Integer inInteger;
  input list<Slot> inSlotLst;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp,inType,inInteger,inSlotLst)
    local
      list<DAE.Exp> expl,args;
      Boolean scalar,tuple_,builtin;
      DAE.Exp new_exp,callexp;
      Absyn.Path fn;
      DAE.ExpType e_type, arr_type;
      Integer dim;
      list<Slot> slots;
    case ((callexp as DAE.CALL(path = fn,expLst = args,tuple_ = tuple_,builtin = builtin)),e_type,dim,slots) /* cur_dim */
      equation
        expl = vectorizeCallScalar2(args, slots, 1, dim, callexp);
        e_type = Exp.unliftArray(e_type);
        scalar = Exp.typeBuiltin(e_type) " unlift vectorized dimension to find element type";
        arr_type = DAE.ET_ARRAY(e_type, {DAE.DIM_INTEGER(dim)});
        new_exp = DAE.ARRAY(arr_type,scalar,expl);
      then
        new_exp;
    case (_,_,_,_)
      equation
        Debug.fprint("failtrace", "-Static.vectorizeCallScalar failed\n");
      then
        fail();
  end matchcontinue;
end vectorizeCallScalar;

protected function vectorizeCallScalar2
"function: vectorizeCallScalar2
  author: PA

  Iterates through vectorized dimension an creates argument list according
  to vectorized dimension in corresponding slot."
  input list<DAE.Exp> inExpExpLst1;
  input list<Slot> inSlotLst2;
  input Integer inInteger3;
  input Integer inInteger4;
  input DAE.Exp inExp5;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inExpExpLst1,inSlotLst2,inInteger3,inInteger4,inExp5)
    local
      list<DAE.Exp> callargs,res,expl,args;
      Integer cur_dim_1,cur_dim,dim;
      list<Slot> slots;
      Absyn.Path fn;
      Boolean t,b;
      DAE.InlineType inl;
      DAE.ExpType tp;
    case (expl,slots,cur_dim,dim,DAE.CALL(path = fn,expLst = args,tuple_ = t,builtin = b,ty=tp,inlineType=inl)) /* cur_dim - current indx in dim dim - dimension size */
      equation
        (cur_dim <= dim) = true;
        callargs = vectorizeCallScalar3(expl, slots, cur_dim);

        cur_dim_1 = cur_dim + 1;
        res = vectorizeCallScalar2(expl, slots, cur_dim_1, dim, DAE.CALL(fn,args,t,b,tp,inl));
      then
        (DAE.CALL(fn,callargs,t,b,tp,inl) :: res);
    case (_,_,_,_,_) then {};
  end matchcontinue;
end vectorizeCallScalar2;

protected function vectorizeCallScalar3
"function: vectorizeCallScalar3
  author: PA

  Helper function to vectorizeCallScalar2"
  input list<DAE.Exp> inExpExpLst;
  input list<Slot> inSlotLst;
  input Integer inInteger;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inExpExpLst,inSlotLst,inInteger)
    local
      list<DAE.Exp> res,es;
      DAE.Exp e,asub_exp;
      list<Slot> ss;
      Integer dim_indx;
    case ({},{},_) then {};  /* dim_indx */
    case ((e :: es),(SLOT(typesArrayDimLst = {}) :: ss),dim_indx) /* scalar argument */
      equation
        res = vectorizeCallScalar3(es, ss, dim_indx);
      then
        (e :: res);
    case ((e :: es),(SLOT(typesArrayDimLst = (_ :: _)) :: ss),dim_indx) /* foreach argument */
      equation
        res = vectorizeCallScalar3(es, ss, dim_indx);
        asub_exp = DAE.ICONST(dim_indx);
        asub_exp = Exp.simplify(DAE.ASUB(e,{asub_exp}));
      then
        (asub_exp :: res);
  end matchcontinue;
end vectorizeCallScalar3;

protected function deoverloadFuncname
"function: deoverloadFuncname

  This function is used to deoverload function calls. It investigates the
  type of the function to see if it has the optional functionname set. If
  so this is returned. Otherwise return input."
  input Absyn.Path inPath;
  input DAE.Type inType;
  output Absyn.Path outPath;
algorithm
  outPath:=
  matchcontinue (inPath,inType)
    local Absyn.Path fn,fn_1;
    case (fn,(DAE.T_FUNCTION(funcArg = _),SOME(fn_1))) then fn_1;
    case (fn,(_,_)) then fn;
  end matchcontinue;
end deoverloadFuncname;

protected function isTuple
"function: isTuple
  Return true if Type is a Tuple type."
  input DAE.Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inType)
    case ((DAE.T_TUPLE(tupleType = _),_)) then true;
    case ((_,_)) then false;
  end matchcontinue;
end isTuple;

protected function elabTypes "
function: elabTypes
   Elaborate input parameters to a function and
   select matching function type from a list of types."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input list<DAE.Type> inTypesTypeLst;
  input Boolean checkTypes "if True, checks types";
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output list<DAE.Exp> outExpExpLst1;
  output list<DAE.Const> outTypesConstLst2;
  output DAE.Type outType3;
  output DAE.Type outType4;
  output list<DAE.Dimension> outTypesArrayDimLst5;
  output list<Slot> outSlotLst6;
  output DAE.DAElist outDae "contain function";
algorithm
  (outCache,outExpExpLst1,outTypesConstLst2,outType3,outType4,outTypesArrayDimLst5,outSlotLst6,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inAbsynNamedArgLst,inTypesTypeLst,checkTypes,inBoolean,inPrefix)
    local
      list<Slot> slots,newslots;
      list<DAE.Exp> args_1;
      list<DAE.Const> clist;
      list<DAE.Dimension> dims;
      list<Env.Frame> env;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      tuple<DAE.TType, Option<Absyn.Path>> t,restype;
      list<tuple<Ident, tuple<DAE.TType, Option<Absyn.Path>>>> params;
      list<tuple<DAE.TType, Option<Absyn.Path>>> trest;
      Boolean impl;
      DAE.InlineType isInline;
      Env.Cache cache;
      Types.PolymorphicBindings polymorphicBindings;
      Option<Absyn.Path> p;
      DAE.DAElist dae;
      Prefix pre;

    // We found a match.
    case (cache,env,args,nargs,((t as (DAE.T_FUNCTION(funcArg = params,funcResultType = restype, inline = isInline),p)) :: trest),checkTypes,impl,pre)
      equation
        slots = makeEmptySlots(params);
        (cache,args_1,newslots,clist,polymorphicBindings,dae) = elabInputArgs(cache, env, args, nargs, slots, checkTypes, impl, {},pre);
        dims = slotsVectorizable(newslots);
        restype = Types.fixPolymorphicRestype(restype, polymorphicBindings);
        t = (DAE.T_FUNCTION(params,restype,isInline),p);
        t = createActualFunctype(t,newslots,checkTypes) "only created when not checking types for error msg";
      then
        (cache,args_1,clist,restype,t,dims,newslots,dae);

    // We did not found a match, try next function type
    case (cache,env,args,nargs,((DAE.T_FUNCTION(funcArg = params,funcResultType = restype),_) :: trest),checkTypes,impl,pre)
      equation
        (cache,args_1,clist,restype,t,dims,slots,dae) = elabTypes(cache,env, args,nargs,trest, checkTypes,impl,pre);
      then
        (cache,args_1,clist,restype,t,dims,slots,dae);

    // failtrace
    case (cache,env,_,_,_,_,_,_)
      equation
        Debug.fprintln("failtrace", "- Static.elabTypes failed.");
      then
        fail();
  end matchcontinue;
end elabTypes;

protected function createActualFunctype
"Creates the actual function type of a CALL expression, used for error messages.
 This type is only created if checkTypes is false."
  input DAE.Type tp;
  input list<Slot> slots;
  input Boolean checkTypes;
  output DAE.Type outTp;
algorithm
  outTp := matchcontinue(tp,slots,checkTypes)
    local
      Option<Absyn.Path> optPath;
      list<DAE.FuncArg> slotParams,params; DAE.Type restype;
      DAE.InlineType isInline;
    case(tp,_,true) then tp;
      /* When not checking types, create function type by looking at the filled slots */
    case(tp as (DAE.T_FUNCTION(funcArg = params,funcResultType = restype,inline = isInline),optPath),slots,false) equation
      slotParams = funcargLstFromSlots(slots);
    then ((DAE.T_FUNCTION(slotParams,restype,isInline),optPath));
  end matchcontinue;
end createActualFunctype;

protected function slotsVectorizable
"function: slotsVectorizable
  author: PA

  This function checks all vectorized array dimensions in the slots and
  confirms that they all are of same dimension,or no dimension, i.e. not
  vectorized. The uniform vectorized array dimension is returned."
  input list<Slot> inSlotLst;
  output list<DAE.Dimension> outTypesArrayDimLst;
algorithm
  outTypesArrayDimLst:=
  matchcontinue (inSlotLst)
    local
      list<DAE.Dimension> ad;
      list<Slot> rest;
    case ({}) then {};
    case ((SLOT(typesArrayDimLst = (ad as (_ :: _))) :: rest))
      equation
        sameSlotsVectorizable(rest, ad);
      then
        ad;
    case ((SLOT(typesArrayDimLst = {}) :: rest))
      equation
        ad = slotsVectorizable(rest);
      then
        ad;
    case (_)
      equation
        Debug.fprint("failtrace", "-slots_vectorizable failed\n");
      then
        fail();
  end matchcontinue;
end slotsVectorizable;

protected function sameSlotsVectorizable
"function: sameSlotsVectorizable
  author: PA

  This function succeds if all slots in the list either has the array
  dimension as given by the second argument or no array dimension at all.
  The array dimension must match both in dimension size and number of
  dimensions."
  input list<Slot> inSlotLst;
  input list<DAE.Dimension> inTypesArrayDimLst;
algorithm
  _:=
  matchcontinue (inSlotLst,inTypesArrayDimLst)
    local
      list<DAE.Dimension> slot_ad,ad;
      list<Slot> rest;
    case ({},_) then ();
    case ((SLOT(typesArrayDimLst = (slot_ad as (_ :: _))) :: rest),ad) /* arraydim must match */
      equation
        sameArraydimLst(ad, slot_ad);
        sameSlotsVectorizable(rest, ad);
      then
        ();
    case ((SLOT(typesArrayDimLst = {}) :: rest),ad) /* empty arradim matches too */
      equation
        sameSlotsVectorizable(rest, ad);
      then
        ();
  end matchcontinue;
end sameSlotsVectorizable;

protected function sameArraydimLst
"function: sameArraydimLst
  author: PA

  Helper function to sameSlotsVectorizable. "
  input list<DAE.Dimension> inTypesArrayDimLst1;
  input list<DAE.Dimension> inTypesArrayDimLst2;
algorithm
  _:=
  matchcontinue (inTypesArrayDimLst1,inTypesArrayDimLst2)
    local
      Integer i1,i2;
      list<DAE.Dimension> ads1,ads2;
    case ({},{}) then ();
    case ((DAE.DIM_INTEGER(integer = i1) :: ads1),(DAE.DIM_INTEGER(integer = i2) :: ads2))
      equation
        true = intEq(i1, i2);
        sameArraydimLst(ads1, ads2);
      then
        ();
    case (DAE.DIM_NONE :: ads1,DAE.DIM_NONE :: ads2)
      equation
        sameArraydimLst(ads1, ads2);
      then
        ();
  end matchcontinue;
end sameArraydimLst;

protected function getProperties
"function: getProperties
  This function creates a Properties object from a DAE.Type and a
  DAE.TupleConst value."
  input DAE.Type inType;
  input DAE.TupleConst inTupleConst;
  output DAE.Properties outProperties;
algorithm
  outProperties:=
  matchcontinue (inType,inTupleConst)
    local
      tuple<DAE.TType, Option<Absyn.Path>> tt,t,ty;
      DAE.TupleConst const;
      DAE.Const b;
      Ident tystr,conststr;
    case ((tt as (DAE.T_TUPLE(tupleType = _),_)),const) then DAE.PROP_TUPLE(tt,const);  /* At least two elements in the type list, this is a tuple. LS: Tuples are fixed before here */
    case (t,DAE.TUPLE_CONST(tupleConstLst = (DAE.SINGLE_CONST(const = b) :: {}))) then DAE.PROP(t,b);  /* One type, this is a tuple with one element. The resulting properties
    is then identical to that of a single expression. */
    case (t,DAE.TUPLE_CONST(tupleConstLst = (DAE.SINGLE_CONST(const = b) :: {}))) then DAE.PROP(t,b);
    case (t,DAE.SINGLE_CONST(const = b)) then DAE.PROP(t,b);
    case (ty,const)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "- get_properties failed: ");
        tystr = Types.unparseType(ty);
        conststr = Types.unparseTupleconst(const);
        Debug.fprint("failtrace", tystr);
        Debug.fprint("failtrace", ", ");
        Debug.fprintln("failtrace", conststr);
      then
        fail();
  end matchcontinue;
end getProperties;

protected function buildTupleConst
"function: buildTupleConst
  author: LS

  Build a TUPLE_CONST (DAE.TupleConst) for a PROP_TUPLE for a function call
  from a list of bools derived from arguments

  We should check functions actual arguments instead of their formal
  parameters as done below"
  input list<DAE.Const> blist;
  output DAE.TupleConst outTupleConst;
  list<DAE.TupleConst> clist;
algorithm
  clist := buildTupleConstList(blist);
  outTupleConst := DAE.TUPLE_CONST(clist);
end buildTupleConst;

protected function buildTupleConstList
"function: buildTupleConstList
  Helper function to buildTupleConst"
  input list<DAE.Const> inTypesConstLst;
  output list<DAE.TupleConst> outTypesTupleConstLst;
algorithm
  outTypesTupleConstLst:=
  matchcontinue (inTypesConstLst)
    local
      list<DAE.TupleConst> restlist;
      DAE.Const c;
      list<DAE.Const> crest;
    case {} then {};
    case (c :: crest)
      equation
        restlist = buildTupleConstList(crest);
      then
        (DAE.SINGLE_CONST(c) :: restlist);
  end matchcontinue;
end buildTupleConstList;

protected function elabConsts "function: elabConsts
  author: PR

  This just splits the properties list into a type list and a const list.
  LS: Changed to take a Type, which is the functions return type.
  LS: Update: const is derived from the input arguments and sent here.
"
  input DAE.Type inType;
  input DAE.Const inConst;
  output DAE.TupleConst outTupleConst;
algorithm
  outTupleConst:=
  matchcontinue (inType,inConst)
    local
      list<DAE.TupleConst> consts;
      list<tuple<DAE.TType, Option<Absyn.Path>>> tys;
      DAE.Const c;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
    case ((DAE.T_TUPLE(tupleType = tys),_),c)
      equation
        consts = checkConsts(tys, c);
      then
        DAE.TUPLE_CONST(consts);
    case (ty,c) /* LS: If not a tuple then one normal type, T_INTEGER etc, but we make a list of types
     with one element and call the same check_consts, so that we always have DAE.TUPLE_CONST as result
 */
      equation
        consts = checkConsts({ty}, c);
      then
        DAE.TUPLE_CONST(consts);
  end matchcontinue;
end elabConsts;

protected function checkConsts
"function: checkConsts
  LS: Changed to take a Type list, which is the functions return type. Only
   for functions returning a tuple
  LS: Update: const is derived from the input arguments and sent here "
  input list<DAE.Type> inTypesTypeLst;
  input DAE.Const inConst;
  output list<DAE.TupleConst> outTypesTupleConstLst;
algorithm
  outTypesTupleConstLst:=
  matchcontinue (inTypesTypeLst,inConst)
    local
      DAE.TupleConst c;
      list<DAE.TupleConst> rest_1;
      tuple<DAE.TType, Option<Absyn.Path>> a;
      list<tuple<DAE.TType, Option<Absyn.Path>>> rest;
      DAE.Const const;
    case ({},_) then {};
    case ((a :: rest),const)
      equation
        c = checkConst(a, const);
        rest_1 = checkConsts(rest, const);
      then
        (c :: rest_1);
  end matchcontinue;
end checkConsts;

protected function checkConst "function: checkConst
  author: PR
   At the moment this make all outputs non cons.
  All ouputs should be checked in the function body for constness.
  LS: but it says true?
  LS: Adapted to check one type instead of funcarg, since it just checks
  return type
  LS: Update: const is derived from the input arguments and sent here
"
  input DAE.Type inType;
  input DAE.Const inConst;
  output DAE.TupleConst outTupleConst;
algorithm
  outTupleConst:=
  matchcontinue (inType,inConst)
    local DAE.Const c;
    case ((DAE.T_TUPLE(tupleType = _),_),c)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"No suport for tuples built by tuples"});
      then
        fail();
    case ((_,_),c) then DAE.SINGLE_CONST(c);
  end matchcontinue;
end checkConst;

protected function splitProps "function: splitProps

  Splits the properties list into the separated types list and const list.
"
  input list<DAE.Properties> inTypesPropertiesLst;
  output list<DAE.Type> outTypesTypeLst;
  output list<DAE.TupleConst> outTypesTupleConstLst;
algorithm
  (outTypesTypeLst,outTypesTupleConstLst):=
  matchcontinue (inTypesPropertiesLst)
    local
      list<tuple<DAE.TType, Option<Absyn.Path>>> types;
      list<DAE.TupleConst> consts;
      tuple<DAE.TType, Option<Absyn.Path>> t;
      DAE.Const c;
      list<DAE.Properties> props;
      DAE.TupleConst t_c;
    case ((DAE.PROP(type_ = t,constFlag = c) :: props))
      equation
        (types,consts) = splitProps(props) "list_append(ts,t::{}) => t1 & list_append(cs,DAE.SINGLE_CONST(c)::{}) => t2 & " ;
      then
        ((t :: types),(DAE.SINGLE_CONST(c) :: consts));
    case ((DAE.PROP_TUPLE(type_ = t,tupleConst = t_c) :: props))
      equation
        (types,consts) = splitProps(props) "list_append(ts,t::{}) => ts\' & list_append(cs, t_c::{}) => cs\' &
" ;
      then
        ((t :: types),(t_c :: consts));
    case ({}) then ({},{});
  end matchcontinue;
end splitProps;

protected function getTypes
"function: getTypes
  This relatoin returns the types of a DAE.FuncArg list."
  input list<DAE.FuncArg> inTypesFuncArgLst;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  outTypesTypeLst:=
  matchcontinue (inTypesFuncArgLst)
    local
      list<tuple<DAE.TType, Option<Absyn.Path>>> types;
      Ident n;
      tuple<DAE.TType, Option<Absyn.Path>> t;
      list<tuple<Ident, tuple<DAE.TType, Option<Absyn.Path>>>> rest;
    case (((n,t) :: rest))
      equation
        types = getTypes(rest) "print(\"\\nDebug: Got a type for output of function. \") &" ;
      then
        (t :: types);
    case ({}) then {};
  end matchcontinue;
end getTypes;

protected function functionParams
"function: functionParams
  A function definition is just a clas definition where all publi
  components are declared as either inpu or outpu.  This
  function_ find all those components and_ separates them into two
  separate lists.

  LS: This can probably replaced by Types.getInputVars and Types.getOutputVars"
  input list<DAE.Var> inTypesVarLst;
  output list<DAE.FuncArg> outTypesFuncArgLst1;
  output list<DAE.FuncArg> outTypesFuncArgLst2;
algorithm
  (outTypesFuncArgLst1,outTypesFuncArgLst2) := matchcontinue (inTypesVarLst)
    local
      list<tuple<Ident, tuple<DAE.TType, Option<Absyn.Path>>>> in_,out;
      list<DAE.Var> vs;
      Ident n;
      tuple<DAE.TType, Option<Absyn.Path>> t;
      DAE.Var v;

    case {} then ({},{});
    case ((DAE.TYPES_VAR(protected_ = true) :: vs)) /* Ignore protected components */
      equation
        (in_,out) = functionParams(vs);
      then
        (in_,out);
    case ((DAE.TYPES_VAR(name = n,attributes = DAE.ATTR(direction = Absyn.INPUT()),protected_ = false,type_ = t,binding = DAE.UNBOUND()) :: vs))
      equation
        (in_,out) = functionParams(vs);
      then
        (((n,t) :: in_),out);
    case ((DAE.TYPES_VAR(name = n,attributes = DAE.ATTR(direction = Absyn.OUTPUT()),protected_ = false,type_ = t,binding = DAE.UNBOUND()) :: vs))
      equation
        (in_,out) = functionParams(vs);
      then
        (in_,((n,t) :: out));
    case (((v as DAE.TYPES_VAR(name = n,attributes = DAE.ATTR(direction = Absyn.BIDIR()))) :: vs))
      equation
        Error.addMessage(Error.FUNCTION_COMPS_MUST_HAVE_DIRECTION, {n});
      then
        fail();
    case (vs)
      equation
        // enabled only by +d=failtrace
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- Static.functionParams failed on: " +& Util.stringDelimitList(Util.listMap(vs, Types.printVarStr), "; "));
      then
        fail();
  end matchcontinue;
end functionParams;

protected function elabInputArgs
"function_: elabInputArgs
  This function_ elaborates on a number of expressions and_ matches
  them to a number of `DAE.Var\' objects, applying type_ conversions
  on the expressions when necessary to match the type_ of the
  `DAE.Var\'.

  PA: Positional arguments and named arguments are filled in the argument slots as:
 1. Positional arguments fill the first slots according to their position.
 2. Named arguments fill slots with the same name as the named argument.
 3. Unfilled slots are checks so that they have default values, otherwise error."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input list<Slot> inSlotLst;
  input Boolean checkTypes "if true, check types";
  input Boolean inBoolean;
  input Types.PolymorphicBindings polymorphicBindings;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output list<DAE.Exp> outExpExpLst;
  output list<Slot> outSlotLst;
  output list<DAE.Const> outTypesConstLst;
  output Types.PolymorphicBindings outPolymorphicBindings;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExpExpLst,outSlotLst,outTypesConstLst,outPolymorphicBindings,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inAbsynNamedArgLst,inSlotLst,checkTypes,inBoolean,polymorphicBindings,inPrefix)
    local
      list<tuple<Ident, tuple<DAE.TType, Option<Absyn.Path>>>> farg;
      list<Slot> slots_1,newslots,slots;
      list<DAE.Const> clist1,clist2,clist;
      list<DAE.Exp> explst,newexp;
      list<Env.Frame> env;
      list<Absyn.Exp> exp;
      list<Absyn.NamedArg> narg;
      Boolean impl;
      Env.Cache cache;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;

    // impl const Fill slots with positional arguments
    case (cache,env,(exp as (_ :: _)),narg,slots,checkTypes,impl,polymorphicBindings,pre)
      equation
        farg = funcargLstFromSlots(slots);
        (cache,slots_1,clist1,polymorphicBindings,dae1) =
          elabPositionalInputArgs(cache, env, exp, farg, slots, checkTypes, impl, polymorphicBindings,pre);
        (cache,_,newslots,clist2,polymorphicBindings,dae2) =
          elabInputArgs(cache, env, {}, narg, slots_1, checkTypes, impl, polymorphicBindings,pre)
          "recursive call fills named arguments" ;
        clist = listAppend(clist1, clist2);
        explst = expListFromSlots(newslots);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,explst,newslots,clist,polymorphicBindings,dae);

    // Fill slots with named arguments
    case (cache,env,{},narg as _::_,slots,checkTypes,impl,polymorphicBindings,pre)
       local String s;
      equation
        farg = funcargLstFromSlots(slots);
        s = printSlotsStr(slots);
        (cache,newslots,clist,polymorphicBindings,dae1) =
          elabNamedInputArgs(cache, env, narg, farg, slots, checkTypes, impl, polymorphicBindings,pre);
        newexp = expListFromSlots(newslots);
      then
        (cache,newexp,newslots,clist,polymorphicBindings,dae1);

    // Empty function call, e.g foo(), is always constant
    case (cache,env,{},{},slots,checkTypes,impl,polymorphicBindings,_)
      equation
      then (cache,{},slots,{DAE.C_CONST()},polymorphicBindings,DAEUtil.emptyDae);

    // fail trace
    case (_,_,_,_,_,_,_,_,_)
      /* FAILTRACE REMOVE equation Debug.fprint("failtrace","elabInputArgs failed\n"); */ then fail();
  end matchcontinue;
end elabInputArgs;

protected function makeEmptySlots
"function: makeEmptySlots
  Helper function to elabInputArgs.
  Creates the slots to be filled with arguments. Intially they are empty."
  input list<DAE.FuncArg> inTypesFuncArgLst;
  output list<Slot> outSlotLst;
algorithm
  outSlotLst:=
  matchcontinue (inTypesFuncArgLst)
    local
      list<Slot> ss;
      tuple<Ident, tuple<DAE.TType, Option<Absyn.Path>>> fa;
      list<tuple<Ident, tuple<DAE.TType, Option<Absyn.Path>>>> fs;
    case ({}) then {};
    case ((fa :: fs))
      equation
        ss = makeEmptySlots(fs);
      then
        (SLOT(fa,false,NONE,{}) :: ss);
  end matchcontinue;
end makeEmptySlots;

protected function funcargLstFromSlots
"function: funcargLstFromSlots
  Converts slots to Types.Funcarg"
  input list<Slot> inSlotLst;
  output list<DAE.FuncArg> outTypesFuncArgLst;
algorithm
  outTypesFuncArgLst:=
  matchcontinue (inSlotLst)
    local
      list<tuple<Ident, tuple<DAE.TType, Option<Absyn.Path>>>> fs;
      tuple<Ident, tuple<DAE.TType, Option<Absyn.Path>>> fa;
      list<Slot> xs;
    case {} then {};
    case ((SLOT(an = fa) :: xs))
      equation
        fs = funcargLstFromSlots(xs);
      then
        (fa :: fs);
  end matchcontinue;
end funcargLstFromSlots;

protected function complexTypeFromSlots
"Creates an DAE.ET_COMPLEX type from a list of slots.
 Used to create type of record constructors "
  input list<Slot> slots;
  input ClassInf.State complexClassType;
  output DAE.ExpType tp;
algorithm
  tp := matchcontinue(slots,complexClassType)
  local DAE.ExpType etp; DAE.Type tp; String id;
    list<DAE.ExpVar> vLst;
    ClassInf.State ci;
    Absyn.Path path;
    case({},complexClassType) equation
      path = ClassInf.getStateName(complexClassType);
    then DAE.ET_COMPLEX(path,{},complexClassType);
    case(SLOT(an = (id,tp))::slots,complexClassType) equation
      etp = Types.elabType(tp);
      DAE.ET_COMPLEX(path,vLst,ci) = complexTypeFromSlots(slots,complexClassType);
    then DAE.ET_COMPLEX(path,DAE.COMPLEX_VAR(id,etp)::vLst,ci);
  end matchcontinue;
end complexTypeFromSlots;

protected function expListFromSlots
"function expListFromSlots
  Convers slots to expressions "
  input list<Slot> inSlotLst;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inSlotLst)
    local
      list<DAE.Exp> lst;
      DAE.Exp e;
      list<Slot> xs;
    case {} then {};
    case ((SLOT(expExpOption = SOME(e)) :: xs))
      equation
        lst = expListFromSlots(xs);
      then
        (e :: lst);
    case ((SLOT(expExpOption = NONE) :: xs))
      equation
        lst = expListFromSlots(xs);
      then
        lst;
  end matchcontinue;
end expListFromSlots;

protected function fillDefaultSlots
"function: fillDefaultSlots
  This function takes a slot list and a class definition of a function
  and fills  default values into slots which have not been filled."
  input Env.Cache inCache;
  input list<Slot> inSlotLst;
  input SCode.Class inClass;
  input Env.Env inEnv;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output list<Slot> outSlotLst;
algorithm
  (outCache,outSlotLst) :=
  matchcontinue (inCache,inSlotLst,inClass,inEnv,inBoolean,inPrefix)
    local
      list<Slot> res,xs;
      tuple<Ident, tuple<DAE.TType, Option<Absyn.Path>>> fa;
      Option<DAE.Exp> e;
      list<DAE.Dimension> ds;
      SCode.Class class_;
      list<Env.Frame> env;
      Boolean impl;
      Absyn.Exp dexp;
      DAE.Exp exp,exp_1;
      tuple<DAE.TType, Option<Absyn.Path>> t,tp;
      DAE.Const c1;
      Ident id;
      Env.Cache cache;
      Prefix pre;
    case (cache,(SLOT(an = fa,true_ = true,expExpOption = e,typesArrayDimLst = ds) :: xs),class_,env,impl,pre) /* impl */
      equation
        (cache,res) = fillDefaultSlots(cache,xs, class_, env, impl,pre);
      then
        (cache,SLOT(fa,true,e,ds) :: res);
    case (cache,(SLOT(an = (id,tp),true_ = false,expExpOption = e,typesArrayDimLst = ds) :: xs),class_,env,impl,pre)
      equation
        (cache,res) = fillDefaultSlots(cache,xs, class_, env, impl,pre);
        SCode.COMPONENT(modifications = SCode.MOD(_,_,_,SOME((dexp,_)))) = SCode.getElementNamed(id, class_);
        (cache,exp,DAE.PROP(t,c1),_,_) = elabExp(cache,env, dexp, impl, NONE,true,pre);
        (exp_1,_) = Types.matchType(exp,t,tp,true);
      then
        (cache,SLOT((id,tp),true,SOME(exp_1),ds) :: res);
    case (cache,(SLOT(an = (id,tp),true_ = false,expExpOption = e,typesArrayDimLst = ds) :: xs),class_,env,impl,pre)
      equation
        (cache,res) = fillDefaultSlots(cache,xs, class_, env, impl,pre) "Error.add_message(Error.INTERNAL_ERROR,{id})" ;
      then
        (cache,SLOT((id,tp),true,e,ds) :: xs);
    case (cache,{},_,_,_,_) then (cache,{});
  end matchcontinue;
end fillDefaultSlots;

protected function printSlotsStr
"function printSlotsStr
  prints the slots to a string"
  input list<Slot> inSlotLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inSlotLst)
    local
      Ident farg_str,filled,str,s,s1,s2,res;
      list<Ident> str_lst;
      tuple<Ident, tuple<DAE.TType, Option<Absyn.Path>>> farg;
      Option<DAE.Exp> exp;
      list<DAE.Dimension> ds;
      list<Slot> xs;
    case ((SLOT(an = farg,true_ = filled,expExpOption = exp,typesArrayDimLst = ds) :: xs))
      equation
        farg_str = Types.printFargStr(farg);
        filled = Util.if_(filled, "filled", "not filled");
        str = Dump.getOptionStr(exp, Exp.printExpStr);
        str_lst = Util.listMap(ds, Exp.dimensionString);
        s = Util.stringDelimitList(str_lst, ", ");
        s1 = Util.stringAppendList({"SLOT(",farg_str,", ",filled,", ",str,", [",s,"])\n"});
        s2 = printSlotsStr(xs);
        res = stringAppend(s1, s2);
      then
        res;
    case ({}) then "";
  end matchcontinue;
end printSlotsStr;

protected function elabPositionalInputArgs
"function: elabPositionalInputArgs
  This function elaborates the positional input arguments of a function.
  A list of slots is filled from the beginning with types of each
  positional argument."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<DAE.FuncArg> inTypesFuncArgLst;
  input list<Slot> inSlotLst;
  input Boolean checkTypes "if true, check types";
  input Boolean inBoolean;
  input Types.PolymorphicBindings polymorphicBindings;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output list<Slot> outSlotLst;
  output list<DAE.Const> outTypesConstLst;
  output Types.PolymorphicBindings outPolymorphicBindings;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outSlotLst,outTypesConstLst,outPolymorphicBindings,outDae):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inTypesFuncArgLst,inSlotLst,checkTypes,inBoolean,polymorphicBindings,inPrefix)
    local
      list<Slot> slots,slots_1,newslots;
      Boolean impl;
      DAE.Exp e_1,e_2;
      tuple<DAE.TType, Option<Absyn.Path>> t,vt;
      DAE.Const c1;
      list<DAE.Const> clist;
      list<Env.Frame> env;
      Absyn.Exp e;
      list<Absyn.Exp> es;
      tuple<Ident, tuple<DAE.TType, Option<Absyn.Path>>> farg;
      list<tuple<Ident, tuple<DAE.TType, Option<Absyn.Path>>>> vs;
      list<DAE.Dimension> ds;
      Env.Cache cache;
      Ident id;
      DAE.Properties props;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;

    // the empty case
    case (cache, _, {}, _, slots, checkTypes, impl, polymorphicBindings,pre)
      then (cache,slots,{},polymorphicBindings,DAEUtil.emptyDae);

        // exact match
    case (cache, env, (e :: es), ((farg as (_,vt)) :: vs), slots, checkTypes as true, impl, polymorphicBindings,pre)
      equation
        (cache,e_1,props,_,dae1) = elabExp(cache,env, e, impl, NONE, true,pre);
        t = Types.getPropType(props);
        c1 = Types.propAllConst(props);
        (e_2,_,polymorphicBindings) = Types.matchTypePolymorphic(e_1,t,vt,polymorphicBindings,false);
        (cache,slots_1,clist,polymorphicBindings,dae2) =
        elabPositionalInputArgs(cache, env, es, vs, slots, checkTypes, impl, polymorphicBindings,pre);
        newslots = fillSlot(farg, e_2, {}, slots_1,checkTypes,pre) "no vectorized dim" ;
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,newslots,(c1 :: clist),polymorphicBindings,dae);

    // check if vectorized argument
    case (cache, env, (e :: es), ((farg as (_,vt)) :: vs), slots, checkTypes as true, impl, polymorphicBindings,pre)
      equation
        (cache,e_1,props,_,dae1) = elabExp(cache,env, e, impl, NONE,true,pre);
        t = Types.getPropType(props);
        c1 = Types.propAllConst(props);
        (e_2,_,ds,polymorphicBindings) = Types.vectorizableType(e_1, t, vt);
        (cache,slots_1,clist,_,dae2) =
          elabPositionalInputArgs(cache, env, es, vs, slots, checkTypes, impl, polymorphicBindings,pre);
        newslots = fillSlot(farg, e_2, ds, slots_1, checkTypes,pre);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,newslots,(c1 :: clist),polymorphicBindings,dae);

    // not checking types
    case (cache, env, (e :: es), ((farg as (id,vt)) :: vs), slots, checkTypes as false, impl, polymorphicBindings,pre)
      equation
        (cache,e_1,props,_,dae1) = elabExp(cache,env, e, impl, NONE,true,pre);
        t = Types.getPropType(props);
        c1 = Types.propAllConst(props);
        (cache,slots_1,clist,polymorphicBindings,dae2) =
          elabPositionalInputArgs(cache, env, es, vs, slots,checkTypes, impl, polymorphicBindings,pre);
        /* fill slot with actual type for error message*/
        newslots = fillSlot((id,t), e_1, {}, slots_1, checkTypes,pre);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,newslots,(c1 :: clist),polymorphicBindings,dae);

    // check types and display error
    case (cache, env, (e :: es), ((farg as (_,vt)) :: vs), slots, checkTypes as true, impl, polymorphicBindings,pre)
      equation
        /* FAILTRACE REMOVE
        (cache,e_1,DAE.PROP(t,c1),_) = elabExp(cache,env, e, impl, NONE,true);
        failure((e_2,_) = Types.matchType(e_1, t, vt));
        Debug.fprint("failtrace", "elabPositionalInputArgs failed, expected type:");
        Debug.fprint("failtrace", Types.unparseType(vt));
        Debug.fprint("failtrace", " found type");
        Debug.fprint("failtrace", Types.unparseType(t));
        Debug.fprint("failtrace", "\n");
        */
      then
        fail();
    // failtrace
    case (cache, env, es, _, slots, checkTypes, impl, polymorphicBindings,pre)
      equation
        /* FAILTRACE REMOVE
        Debug.fprint("failtrace", "elabPositionalInputArgs failed: expl:");
        Debug.fprint("failtrace", Util.stringDelimitList(Util.listMap(es,Dump.printExpStr),", "));
        Debug.fprint("failtrace", "\n");
        */
      then
        fail();
  end matchcontinue;
end elabPositionalInputArgs;

protected function elabNamedInputArgs
"function elabNamedInputArgs
  This function takes an Env, a NamedArg list, a DAE.FuncArg list and a
  Slot list.
  It builds up a new slot list and a list of elaborated expressions.
  If a slot is filled twice the function fails. If a slot is not filled at
  all and the
  value is not a parameter or a constant the function also fails."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input list<DAE.FuncArg> inTypesFuncArgLst;
  input list<Slot> inSlotLst;
  input Boolean checkTypes "if true, check types";
  input Boolean inBoolean;
  input Types.PolymorphicBindings polymorphicBindings;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output list<Slot> outSlotLst;
  output list<DAE.Const> outTypesConstLst;
  output Types.PolymorphicBindings outPolymorphicBindings;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outSlotLst,outTypesConstLst,outPolymorphicBindings,outDae) :=
  matchcontinue (inCache,inEnv,inAbsynNamedArgLst,inTypesFuncArgLst,inSlotLst,checkTypes,inBoolean,polymorphicBindings,inPrefix)
    local
      DAE.Exp e_1,e_2;
      tuple<DAE.TType, Option<Absyn.Path>> t,vt;
      DAE.Const c1;
      list<Slot> slots_1,newslots,slots;
      list<DAE.Const> clist;
      list<Env.Frame> env;
      Ident id, pre_str;
      Absyn.Exp e;
      list<Absyn.NamedArg> nas,narg;
      list<tuple<Ident, tuple<DAE.TType, Option<Absyn.Path>>>> farg;
      Boolean impl;
      Env.Cache cache;
      list<DAE.Dimension> ds;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;

    // the empty case
    case (cache,_,{},_,slots,checkTypes,impl,polymorphicBindings,_)
      then (cache,slots,{},polymorphicBindings,DAEUtil.emptyDae);

    // check types exact match
    case (cache,env,(Absyn.NAMEDARG(argName = id,argValue = e) :: nas),farg,slots,checkTypes as true,impl,polymorphicBindings,pre)
      equation
        (cache,e_1,DAE.PROP(t,c1),_,dae1) = elabExp(cache, env, e, impl, NONE, true,pre);
        vt = findNamedArgType(id, farg);
        (e_2,_,polymorphicBindings) = Types.matchTypePolymorphic(e_1,t,vt,polymorphicBindings,false);
        slots_1 = fillSlot((id,vt), e_2, {}, slots,checkTypes,pre);
        (cache,newslots,clist,polymorphicBindings,dae2) =
          elabNamedInputArgs(cache, env, nas, farg, slots_1, checkTypes, impl, polymorphicBindings,pre);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,newslots,(c1 :: clist),polymorphicBindings,dae);

    // check types vectorized argument
    case (cache,env,(Absyn.NAMEDARG(argName = id,argValue = e) :: nas),farg,slots,checkTypes as true,impl,polymorphicBindings,pre)
      equation
        (cache,e_1,DAE.PROP(t,c1),_,dae1) = elabExp(cache, env, e, impl, NONE, true,pre);
        vt = findNamedArgType(id, farg);
        (e_2,_,ds,polymorphicBindings) = Types.vectorizableType(e_1, t, vt);
        slots_1 = fillSlot((id,vt), e_2, ds, slots, checkTypes,pre);
        (cache,newslots,clist,polymorphicBindings,dae2) =
          elabNamedInputArgs(cache, env, nas, farg, slots_1, checkTypes, impl, polymorphicBindings,pre);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,newslots,(c1 :: clist),polymorphicBindings,dae);

    // do not check types
    case (cache,env,(Absyn.NAMEDARG(argName = id,argValue = e) :: nas),farg,slots,checkTypes as false,impl,polymorphicBindings,pre)
      equation
        (cache,e_1,DAE.PROP(t,c1),_,dae1) = elabExp(cache,env, e, impl, NONE,true,pre);
        vt = findNamedArgType(id, farg);
        slots_1 = fillSlot((id,vt), e_1, {}, slots,checkTypes,pre);
        (cache,newslots,clist,polymorphicBindings,dae2) =
          elabNamedInputArgs(cache, env, nas, farg, slots_1, checkTypes, impl, polymorphicBindings,pre);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,newslots,(c1 :: clist),polymorphicBindings,dae2);

    // failure
    case (cache,env,narg,farg,_,checkTypes,impl,polymorphicBindings,pre)
      equation
        true = RTOpts.debugFlag("failtrace");
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Debug.fprintln("failtrace", "Static.elabNamedInputArgs failed for first named argument in: (" +&
           Util.stringDelimitList(Util.listMap(narg, Dump.printNamedArgStr), ", ") +& "), in component: " +& pre_str);
      then
        fail();
  end matchcontinue;
end elabNamedInputArgs;

protected function findNamedArgType
"function findNamedArgType
  This function takes an Ident and a FuncArg list, and returns the FuncArg
  which has  that identifier.
  Used for instance when looking up named arguments from the function type."
  input Ident inIdent;
  input list<DAE.FuncArg> inTypesFuncArgLst;
  output DAE.Type outType;
algorithm
  outType:=
  matchcontinue (inIdent,inTypesFuncArgLst)
    local
      Ident id,id2;
      tuple<DAE.TType, Option<Absyn.Path>> farg;
      list<tuple<Ident, tuple<DAE.TType, Option<Absyn.Path>>>> ts;
    case (id,((id2,farg) :: ts))
      equation
        true = stringEqual(id, id2);
      then
        farg;
    case (id,((farg as (id2,_)) :: ts))
      equation
        false = stringEqual(id, id2);
        farg = findNamedArgType(id, ts);
      then
        farg;
  end matchcontinue;
end findNamedArgType;

protected function fillSlot
"function: fillSlot
  This function takses a `FuncArg\' and an DAE.Exp and a Slot list and fills
  the slot holding the FuncArg, by setting the boolean value of the slot
  and setting the expression. The function fails if the slot is allready set."
  input DAE.FuncArg inFuncArg;
  input DAE.Exp inExp;
  input list<DAE.Dimension> inTypesArrayDimLst;
  input list<Slot> inSlotLst;
  input Boolean checkTypes "type checking only if true";
  input Prefix inPrefix;
  output list<Slot> outSlotLst;
algorithm
  outSlotLst := matchcontinue (inFuncArg,inExp,inTypesArrayDimLst,inSlotLst,checkTypes,inPrefix)
    local
      Ident fa1,fa2,fa;
      DAE.Exp exp;
      list<DAE.Dimension> ds;
      tuple<DAE.TType, Option<Absyn.Path>> b;
      list<Slot> xs,newslots;
      tuple<Ident, tuple<DAE.TType, Option<Absyn.Path>>> farg;
      Slot s1;
      Prefix pre;
      String ps;
    
    case ((fa1,_),exp,ds,(SLOT(an = (fa2,b),true_ = false) :: xs),checkTypes as true,pre)
      equation
        true = stringEqual(fa1, fa2);
      then
        (SLOT((fa2,b),true,SOME(exp),ds) :: xs);
    
    // If not checking types, store actual type in slot so error message contains actual type 
    case ((fa1,b),exp,ds,(SLOT(an = (fa2,_),true_ = false) :: xs),checkTypes as false,pre)
      equation
        true = stringEqual(fa1, fa2);
      then
        (SLOT((fa2,b),true,SOME(exp),ds) :: xs);
    
    // fail if slot already filled
    case ((fa1,_),exp,ds,(SLOT(an = (fa2,b),true_ = true) :: xs),checkTypes ,pre)
      equation
        true = stringEqual(fa1, fa2);
        ps = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.FUNCTION_SLOT_ALLREADY_FILLED, {fa2,ps});
      then
        fail();
    
    // no equal, fill slot
    case ((farg as (fa1,_)),exp,ds,((s1 as SLOT(an = (fa2,_))) :: xs),checkTypes,pre)
      equation
        false = stringEqual(fa1, fa2);
        newslots = fillSlot(farg, exp, ds, xs,checkTypes,pre);
      then
        (s1 :: newslots);
    
    // failure
    case ((fa,_),_,_,_,_,pre)
      equation
        ps = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.NO_SUCH_ARGUMENT, {fa,ps});
      then
        fail();
  end matchcontinue;
end fillSlot;

public function elabCref "
function: elabCref
  Elaborate on a component reference.  Check the type of the
  component referred to, and check if the environment contains
  either a constant binding for that variable, or if it contains an
  equation binding with a constant expression."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Boolean inBoolean "implicit instantiation";
  input Boolean performVectorization "true => generates vectorized expressions, {v[1],v[2],...}";
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output SCode.Accessibility outAccessibility;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExp,outProperties,outAccessibility,outDae) :=
  matchcontinue (inCache,inEnv,inComponentRef,inBoolean,performVectorization,inPrefix)
    local
      DAE.ComponentRef c_1;
      DAE.Const const;
      SCode.Accessibility acc,acc_1;
      SCode.Variability variability;
      Option<Absyn.Path> optPath;
      DAE.Type t;
      DAE.TType tt;
      DAE.Binding binding;
      DAE.Exp exp;
      list<Env.Frame> env;
      Absyn.ComponentRef c;
      Boolean impl;
      Ident s,scope;
      Env.Cache cache;
      Boolean doVect,isBuiltinFunc;
      DAE.ExpType et;
      Absyn.InnerOuter io;
      DAE.DAElist dae,dae1,dae2;
      String str,fn_str,scope;
      DAE.Properties props;
      Lookup.SplicedExpData splicedExpData;
      Absyn.Path path,fpath;
      list<DAE.Type> typelist;
      list<String> typelistStr;
      String typeStr;
      DAE.ComponentRef expCref;
      DAE.ExpType expType;
      Option<DAE.Const> forIteratorConstOpt;
      Prefix pre;

    // wildcard
    case (cache,env,c as Absyn.WILD(),impl,doVect,_) /* impl */
      equation
        t = (DAE.T_ANYTYPE(NONE),NONE);
        et = Types.elabType(t);
      then
        (cache,DAE.CREF(DAE.WILD(),et),DAE.PROP(t, DAE.C_VAR()),SCode.WO(),DAEUtil.emptyDae);

    // a normal cref
    case (cache,env,c,impl,doVect,pre) /* impl */
      equation
        (cache,c_1,_,dae) = elabCrefSubs(cache, env, c, Prefix.NOPRE(), impl);
        (cache,DAE.ATTR(_,_,acc,variability,_,io),t,binding,forIteratorConstOpt,splicedExpData,_,_,_) = Lookup.lookupVar(cache, env, c_1);
        (cache,exp,const,acc_1) = elabCref2(cache, env, c_1, acc, variability, forIteratorConstOpt,io, t, binding, doVect,splicedExpData,pre);
        exp = makeASUBArrayAdressing(c,cache,env,impl,exp,splicedExpData,doVect,pre);        
      then
        (cache,exp,DAE.PROP(t,const),acc_1,dae);
        
    // An enumeration type => array of enumeration literals.
    case (cache, env, c, impl, doVect, pre)
      local
        list<String> enum_lit_strs;
        SCode.Class cl;
      equation
        path = Absyn.crefToPath(c);
        (cache, cl as SCode.CLASS(restriction = SCode.R_ENUMERATION), env) = 
          Lookup.lookupClass(cache, env, path, false);
        typeStr = Absyn.pathLastIdent(path);
        path = Env.joinEnvPath(env, Absyn.IDENT(typeStr));
        enum_lit_strs = SCode.componentNames(cl);
        (exp, t) = makeEnumerationArray(path, enum_lit_strs);
      then
        (cache,exp,DAE.PROP(t, DAE.C_CONST),SCode.RO(),DAEUtil.emptyDae);
        
    // MetaModelica Partial Function
    case (cache,env,c,impl,doVect,pre)
      equation
        //true = RTOpts.debugFlag("fnptr") or RTOpts.acceptMetaModelicaGrammar();
        path = Absyn.crefToPath(c);
        (cache,typelist,dae1) = Lookup.lookupFunctionsInEnv(cache,env,path);
        (cache, isBuiltinFunc) = isBuiltinFunc(cache, path,pre);
        {t} = typelist;
        (tt,optPath) = t;
        t = (tt, Util.if_(isBuiltinFunc, SOME(path), optPath)) "builtin functions store NONE there";
        (_,SOME(fpath)) = t;
        t = Types.makeFunctionPolymorphicReference(t);
        c = Absyn.pathToCref(fpath);
        expCref = Exp.toExpCref(c);
        exp = DAE.CREF(expCref,DAE.ET_FUNCTION_REFERENCE_FUNC(isBuiltinFunc));
        // This is not done by lookup - only elabCall. So we should do it here.
        (cache,dae2) = instantiateDaeFunction(cache,env,path,isBuiltinFunc,NONE,true);
        dae = DAEUtil.joinDaeLst({dae1,dae2});
      then
        (cache,exp,DAE.PROP(t,DAE.C_CONST()),SCode.RO(),dae);

    // MetaModelica extension
    case (cache,env,Absyn.CREF_IDENT("NONE",{}),impl,doVect,_)
      local DAE.Exp e;
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        e = DAE.META_OPTION(NONE());
      then
        (cache,e,DAE.PROP((DAE.T_METAOPTION((DAE.T_NOTYPE(),NONE)),NONE()),DAE.C_CONST()),SCode.RO(),DAEUtil.emptyDae);

    case (cache,env,c,impl,doVect,_)
      equation
        //true = RTOpts.debugFlag("fnptr") or RTOpts.acceptMetaModelicaGrammar();
        path = Absyn.crefToPath(c);
        failure((_,_,_) = Lookup.lookupFunctionsInEnv(cache,env,path));
        fn_str = Absyn.pathString(path);
        scope = Env.printEnvPathStr(env);
        Error.addMessage(Error.LOOKUP_ERROR, {fn_str,scope});
      then
        fail();

    case (cache,env,c,impl,doVect,pre)
      equation
        failure((_,_,_,_) = elabCrefSubs(cache,env, c, Prefix.NOPRE(),impl));
        s = Dump.printComponentRefStr(c);
        scope = Env.printEnvPathStr(env);
        Error.addMessage(Error.LOOKUP_VARIABLE_ERROR, {s,scope}); // - no need to add prefix info since problem only depends on the scope?
      then
        fail();

    case (cache,env,c,impl,doVect,pre)
      equation
        // enabled with +d=failtrace
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- Static.elabCref failed: " +&
          Dump.printComponentRefStr(c) +& " in env: " +&
          Env.printEnvPathStr(env));
        // Debug.traceln("ENVIRONMENT:\n" +& Env.printEnvStr(env));
      then
        fail();
  end matchcontinue;
end elabCref;

public function makeEnumerationArray
  "Expands an enumeration type to an array of it's enumeration literals."
  input Absyn.Path enumTypeName;
  input list<String> enumLiterals;
  output DAE.Exp enumArray;
  output DAE.Type enumArrayType;

  list<Absyn.Path> enum_lit_names;
  list<DAE.Exp> enum_lit_expl;
  Integer sz;
  DAE.ExpType ety;
algorithm
  enum_lit_names := Util.listMap(enumLiterals, Absyn.makeIdentPathFromString);
  enum_lit_names := Util.listMap1r(enum_lit_names, Absyn.joinPaths, enumTypeName);
  enum_lit_expl := Util.listMapAndFold(enum_lit_names, makeEnumLiteral, 1);
  sz := listLength(enumLiterals);
  ety := DAE.ET_ARRAY(DAE.ET_ENUMERATION(NONE, enumTypeName, enumLiterals, {}),
    {DAE.DIM_ENUM(enumTypeName, enumLiterals, sz)});
  enumArray := DAE.ARRAY(ety, true, enum_lit_expl);
  enumArrayType := (DAE.T_ENUMERATION(NONE, enumTypeName, enumLiterals, {}), NONE);
  enumArrayType := (DAE.T_ARRAY(DAE.DIM_ENUM(enumTypeName, enumLiterals, sz), 
    enumArrayType), NONE);
end makeEnumerationArray;

protected function makeEnumLiteral
  "Creates a new enumeration literal. For use with listMapAndFold."
  input Absyn.Path name;
  input Integer index;
  output DAE.Exp enumExp;
  output Integer newIndex;
algorithm
  enumExp := DAE.ENUM_LITERAL(name, index);
  newIndex := index + 1;
end makeEnumLiteral;

protected function makeASUBArrayAdressing
"function makeASUBArrayAdressing
  This function remakes CREF subscripts to ASUB's of ASUB's
  a[1,index,y[z]] (CREF_IDENT(a,{1,DAE.INDEX(CREF_IDENT('index',{})),DAE.INDEX(CREF_IDENT('y',{DAE.INDEX(CREF_IDENT('z))})) ))
  to
  ASUB( exp = CREF_IDENT(a,{}),
   sub = {1,CREF_IDENT('index',{}), ASUB( exp = CREF_IDENT('y',{}), sub = {CREF_IDENT('z',{})})})
  will create nestled asubs for subscripts conaining crefs with subs."
  input Absyn.ComponentRef inRef;
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Boolean inBoolean "implicit instantiation";
  input DAE.Exp inExp;
  input Lookup.SplicedExpData splicedExpData;
  input Boolean doVect "if doVect is false, no vectorization and thus no ASUB addressing is performed";
  input Prefix inPrefix;
  output DAE.Exp outExp;
algorithm
  outComponentRef := matchcontinue (inRef,inCache,inEnv,inBoolean,inExp,splicedExpData,doVect,inPrefix)
    local
      DAE.Exp exp1, exp2, aexp1,aexp2;
      Absyn.ComponentRef cref, crefChild;
      list<Absyn.Subscript> assl;
      list<DAE.Subscript> essl;
      String id,id2;
      DAE.ExpType ty,ty2;
      DAE.ComponentRef cr;
      DAE.Const const;
      list<Env.Frame> env;
      Boolean impl;
      Env.Cache cache;
      Types.Type idTp;
      Prefix pre;
    // return inExp if no vectorization is to be done
    case(inRef,cache,env,impl,inExp,splicedExpData,false,_) then inExp;      
    
    case(Absyn.CREF_IDENT(id,assl),cache,env,impl, exp1 as DAE.CREF(DAE.CREF_IDENT(id2,_,essl),ty),Lookup.SPLICEDEXPDATA(SOME(DAE.CREF(cr,_)),idTp),doVect,pre)
      local DAE.Exp tmpExp;
      equation
        (_,_,const as DAE.C_VAR,_) = elabSubscripts(cache,env, assl ,impl,pre);
        exp1 = makeASUBArrayAdressing2(essl,pre);
        ty2 = Exp.crefType(cr);
        exp1 = DAE.ASUB(DAE.CREF(DAE.CREF_IDENT(id2,ty2,{}),ty2),exp1);
      then
        exp1;
    case(Absyn.CREF_IDENT(id,assl),cache,env,impl, exp1 as DAE.CREF(DAE.CREF_IDENT(id2,ty2,essl),ty),_,doVect,pre)
      equation
        (_,_,const as DAE.C_VAR,_) = elabSubscripts(cache,env, assl ,impl,pre);
        exp1 = makeASUBArrayAdressing2( essl,pre);
        exp1 = DAE.ASUB(DAE.CREF(DAE.CREF_IDENT(id2,ty2,{}),ty),exp1);
      then
        exp1;
    case(_,_,_,_, (exp1 as DAE.CREF(DAE.CREF_IDENT(id2,_,essl),ty)),Lookup.SPLICEDEXPDATA(SOME(DAE.CREF(cr,_)),idTp),doVect,_)
      local
        DAE.ExpType tty2;
      equation
        tty2 = Exp.crefType(cr);
        exp1 = DAE.CREF(DAE.CREF_IDENT(id2,tty2,essl),ty);
      then
        exp1;
    // adrpo: return exp1 here instead of exp2
    //        returning exp2 generates x.y[{1,2,3}] for  x.Real[3].y;
    case(_,_,_,_, (exp1 as DAE.CREF(DAE.CREF_QUAL(id2,_,essl,crr2),ty)), Lookup.SPLICEDEXPDATA(SOME(exp2 as DAE.CREF(cr,_)),idTp),doVect,_)
      local
        DAE.ComponentRef crr2;
        DAE.ExpType tty2;
        equation
          //Debug.fprint("failtrace", "-Qualified asubs not yet implemented\n");
      then
        exp1; // adrpo why it was returning here exp2???
    case(_,_,_,_,exp1,_,doVect,_)
      then
        exp1;
  end matchcontinue;
end makeASUBArrayAdressing;

protected function makeASUBArrayAdressing2
"function makeASUBArrayAdressing
  This function is supposed to remake
  CREFS with a variable subscript to a ASUB"
  input list<DAE.Subscript> inSSL;
  input Prefix inPrefix;
  output list<DAE.Exp> outExp;
algorithm
  outComponentRef := matchcontinue (inSSL,inPrefix)
    local
      DAE.Exp exp1,exp2,b1,b2;
      list<DAE.Exp> expl1,expl2;
      DAE.Const c1;
      String id,id2,str,pre_str;
      DAE.Subscript sub;
      DAE.ExpType ety,ety1,ty2;
      list<DAE.Subscript> subs,subs2;
      DAE.Operator op;
      Prefix pre;

    // empty list
    case( {},_ ) then {};
    // an integer index in the list head
    case( (sub as DAE.INDEX(exp = exp1 as DAE.ICONST(_)))::subs,pre )
      equation
        expl1 = makeASUBArrayAdressing2(subs,pre);
      then
        (exp1::expl1);
    // a component reference in the list head
    case( (sub as DAE.INDEX(exp1 as DAE.CREF(DAE.CREF_IDENT(id2,_,{}),ety1)))::subs ,pre )
      equation
        expl1 = makeASUBArrayAdressing2(subs,pre);
      then
        (exp1::expl1);
    // ??!! what's up with this??
    case( (sub as DAE.INDEX(DAE.CREF(DAE.CREF_IDENT(id2,ty2,subs2),ety1)))::subs ,pre)
      equation
        expl1 = makeASUBArrayAdressing2(subs,pre);
        expl2 = makeASUBArrayAdressing2(subs2,pre);
        exp1 = DAE.ASUB(DAE.CREF(DAE.CREF_IDENT(id2,ty2,{}),ety1),expl2);
      then
        (exp1::expl1);
    // an binary expression as index
    case( (sub as DAE.INDEX(DAE.BINARY(b1,op,b2)))::subs ,pre)
      equation
        // TODO! make some check here
        expl2 = makeASUBArrayAdressing2(subs,pre);
        exp1 = DAE.BINARY(b1,op,b2);
      then
        exp1 :: expl2;
    // time to fail
    case( ((sub as DAE.INDEX(exp1)))::subs ,pre)
      equation
        // enabled with +d=failtrace
        true = RTOpts.debugFlag("failtrace");
        str = Exp.printExpStr(exp1);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Debug.traceln("- Static.makeASUBArrayAdressing2 failed for INDEX(" +& str +& ") in component " +& pre_str);
        // adrpo: don't do any further as we anyway fail!
        // expl2 = makeASUBArrayAdressing2(subs);
      then
        fail();
  end matchcontinue;
end makeASUBArrayAdressing2;

/* This function will be usefull when we implement Qualified subs such as:
a.b[1,j] or a[1].b[1,j]. As of now, a[j].b[i] will not be possible since
we can't know where b is located in a. but if a is non_array or a fully
adressed array(without variables), this is doable and this funtion can be used.
protected function allowQualSubscript ""
  input list<DAE.Subscript> subs;
  input DAE.ExpType ty;
  output Boolean bool;
algorithm bool := matchcontinue( subs, ty )
  local
    list<DAE.Subscript> subs;
    list<Option<Integer>> ad;
    list<list<Integer>> ill;
    list<Integer> il;
    Integer x,y;
  case({},ty as DAE.ET_ARRAY(ty=_))
  then false;
  case({},_)
  then true;
  case(subs, ty as DAE.ET_ARRAY(arrayDimensions=ad))
    equation
      x = listLength(subs);
      ill = Util.listMap(ad,Util.genericOption);
      il = Util.listFlatten(ill);
      y = listLength(il);
      true = intEq(x, y );
    then
      true;
  case(_,_) equation print(" not allowed qual_asub\n"); then false;
end matchcontinue;
end allowQualSubscript;
*/

protected function fillCrefSubscripts
"function: fillCrefSubscripts
  This is a helper function to elab_cref2.
  It investigates a DAE.Type in order to fill the subscript lists of a
  component reference. For instance, the name a.b with the type array of
  one dimension will become a.b[:]."
  input DAE.ComponentRef inComponentRef;
  input DAE.Type inType;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := matchcontinue (inComponentRef,inType/*,slicedExp*/)
    local
      DAE.ComponentRef e,cref_1,cref;
      tuple<DAE.TType, Option<Absyn.Path>> t;
      list<DAE.Subscript> subs_1,subs;
      Ident id;
      DAE.ExpType ty2;
    // no subscripts
    case ((e as DAE.CREF_IDENT(subscriptLst = {})),t) then e;
    
    // simple ident with non-empty subscripts
    case ((e as DAE.CREF_IDENT(ident = id, identType = ty2, subscriptLst = subs)),t)
      equation
        subs_1 = fillSubscripts(subs, t);
      then
        DAE.CREF_IDENT(id,ty2,subs_1);
    // qualified ident with non-empty subscrips
    case (e as (DAE.CREF_QUAL(ident = id,subscriptLst = subs,componentRef = cref,identType = ty2 )),t)
      equation
        // TODO!FIXME!
        // DAE.CREF_IDENT(id, ty2, subs) = fillCrefSubscripts(DAE.CREF_IDENT(id, ty2, subs),t);
        cref_1 = fillCrefSubscripts(cref, t);
      then
        DAE.CREF_QUAL(id,ty2,subs,cref_1);
  end matchcontinue;
end fillCrefSubscripts;

protected function fillSubscripts
"function: fillSubscripts
  Helper function to fillCrefSubscripts."
  input list<DAE.Subscript> inExpSubscriptLst;
  input DAE.Type inType;
  output list<DAE.Subscript> outExpSubscriptLst;
algorithm
  outExpSubscriptLst := matchcontinue (inExpSubscriptLst,inType)
    local
      list<DAE.Subscript> subs_1,subs_2,subs;
      tuple<DAE.TType, Option<Absyn.Path>> t;
      DAE.Subscript fs;
    // empty list
    case ({},(DAE.T_ARRAY(arrayType = t),_))
      equation
        subs_1 = fillSubscripts({}, t);
        subs_2 = listAppend({DAE.WHOLEDIM()}, subs_1);
      then
        subs_2;
    // some subscripts present
    case ((fs :: subs),(DAE.T_ARRAY(arrayType = t),_))
      equation
        subs_1 = fillSubscripts(subs, t);
      then
        (fs :: subs_1);
    // not an array type!
    case (subs,_) then subs;
  end matchcontinue;
end fillSubscripts;

protected function elabCref2
"function: elabCref2
  This function check whether the component reference found in
  elabCref has a binding, and if that binding is constant.
  If the binding is a VALBOUND binding, the value is substituted.
  Constant values are e.g.:
    1+5, c1+c2, ps1+ps2, where c1 and c2 are Modelica constants,
                      ps1 and ps2 are structural parameters.

  Non Constant values are e.g.:
    p1+p2, x1x2, where p1,p2 are modelica parameters,
                 x1,x2 modelica variables."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inComponentRef;
  input SCode.Accessibility inAccessibility;
  input SCode.Variability inVariability;
  input Option<DAE.Const> forIteratorConstOpt;
  input Absyn.InnerOuter io;
  input DAE.Type inType;
  input DAE.Binding inBinding;
  input Boolean performVectorization "true => vectorized expressions";
  input Lookup.SplicedExpData splicedExpData;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Const outConst;
  output SCode.Accessibility outAccessibility;
algorithm
  (outCache,outExp,outConst,outAccessibility) :=
  matchcontinue (inCache,inEnv,inComponentRef,inAccessibility,inVariability,forIteratorConstOpt,io,inType,inBinding,performVectorization,splicedExpData,inPrefix)
    local
      DAE.ExpType t_1, expTy;
      DAE.ComponentRef cr,cr_1,cref;
      SCode.Accessibility acc,acc_1;
      tuple<DAE.TType, Option<Absyn.Path>> t,tt,et,tp,idTp;
      DAE.Exp e,e_1,exp,exp1;
      Option<DAE.Exp> sexp;
      Values.Value v;
      list<Env.Frame> env;
      DAE.Const const;
      SCode.Variability variability_1,variability,var;
      DAE.Binding binding_1,bind;
      String s,str,scope,pre_str;
      DAE.Binding binding;
      Env.Cache cache;
      Boolean doVect;
      Lookup.SplicedExpData splicedExpData;     
      DAE.ExpType expIdTy; 
      Prefix pre;

    // If type not yet determined, component must be referencing itself.
    // The constantness is undecidable since binding is not available. return C_VAR
    case (cache,_,cr,acc,_,_,io,(t as (DAE.T_NOTYPE(),_)),_,doVect,_,_)
      equation
        expTy = Types.elabType(t);
      then
        (cache,DAE.CREF(cr,expTy),DAE.C_VAR(),acc);

    // adrpo: report a warning if the binding came from a start value!
    case (cache,env,cr,acc,SCode.PARAM(),forIteratorConstOpt,io,tt,bind as DAE.EQBOUND(source = DAE.BINDING_FROM_START_VALUE()),doVect,splicedExpData,inPrefix)
      equation
        s = Exp.printComponentRefStr(cr);
        pre_str = PrefixUtil.printPrefixStr2(inPrefix);
        s = pre_str +& s;
        str = DAEUtil.printBindingExpStr(inBinding);
        Error.addMessage(Error.UNBOUND_PARAMETER_WITH_START_VALUE_WARNING(), {str, s});
        bind = DAEUtil.setBindingSource(bind, DAE.BINDING_FROM_DEFAULT_VALUE());
        (cache, e_1, const, acc) = elabCref2(cache,env,cr,acc,inVariability,forIteratorConstOpt,io,tt,bind,doVect,splicedExpData,inPrefix);
      then
        (cache,e_1,const,acc);

    // a variable
    case (cache,_,cr,acc,SCode.VAR(),_,io,tt,_,doVect,Lookup.SPLICEDEXPDATA(sexp,idTp),_)
      local DAE.ExpType expIdTy; 
      equation
        expTy = Types.elabType(tt);
        expIdTy = Types.elabType(idTp);
        cr_1 = fillCrefSubscripts(cr, tt);
        e = crefVectorize(doVect, DAE.CREF(cr_1,expTy), tt, sexp,expIdTy,true);
      then
        (cache,e,DAE.C_VAR(),acc);

    // a discrete variable
    case (cache,_,cr,acc,SCode.DISCRETE(),_,io,tt,_,doVect,Lookup.SPLICEDEXPDATA(_,idTp),_)
      equation
        expTy = Types.elabType(tt);
        cr_1 = fillCrefSubscripts(cr, tt);
        expIdTy = Types.elabType(idTp);
        e = crefVectorize(doVect,DAE.CREF(cr_1,expTy), tt, NONE,expIdTy,true);
      then
        (cache,e,DAE.C_VAR(),acc);

    // an enumeration literal -> simplify to a literal expression
    case (cache,env,cr,_,SCode.CONST(),_,_,(DAE.T_ENUMERATION(index = SOME(i), path = p), _),_,_,_,_)
      local
        Integer i;
        Absyn.Path p;
      equation
        p = Absyn.joinPaths(p, Exp.crefLastPath(cr));
      then
        (cache, DAE.ENUM_LITERAL(p, i), DAE.C_CONST(), SCode.RO());
         
    // a constant -> evaluate binding
    case (cache,env,cr,acc,SCode.CONST(),_,io,tt,binding,doVect,_,_)
      equation
        (cache,v) = Ceval.cevalCrefBinding(cache,env,cr,binding,false,Ceval.MSG());
        e = ValuesUtil.valueExp(v);
        et = Types.typeOfValue(v);
        (e_1,_) = Types.matchType(e, et, tt, true);
      then
        (cache,e_1,DAE.C_CONST(),SCode.RO());
    
    // a constant with some for iterator constness -> don't constant evaluate
    case (cache,env,cr,acc,SCode.CONST(),SOME(_),io,tt,_,doVect,_,_)
      equation
        expTy = Types.elabType(tt);
      then
        (cache,DAE.CREF(cr,expTy),DAE.C_CONST(),SCode.RO());

    // evaluate parameters only if "evalparam" is set; TODO! also ceval if annotation Evaluate=true.
    case (cache,env,cr,acc,SCode.PARAM(),_,io,tt,DAE.VALBOUND(valBound = v),doVect,Lookup.SPLICEDEXPDATA(_,idTp),_)
      equation
        true = RTOpts.debugFlag("evalparam");
        expTy = Types.elabType(tt);
        expIdTy = Types.elabType(idTp);
        cr_1 = fillCrefSubscripts(cr, tt);
        e_1 = crefVectorize(doVect,DAE.CREF(cr_1,expTy), tt, NONE,expIdTy,true);
        (cache,v,_) = Ceval.ceval(cache,env,e_1,false,NONE,NONE,Ceval.MSG());
        e = ValuesUtil.valueExp(v);
        et = Types.typeOfValue(v);
        (e_1,_) = Types.matchType(e, et, tt, true);
      then
        (cache,e_1,DAE.C_PARAM(),SCode.RO());

    // a binding equation and evalparam
    case (cache,env,cr,acc,var,_,io,tt,DAE.EQBOUND(exp = exp,constant_ = const),doVect,Lookup.SPLICEDEXPDATA(_,idTp),_) 
      equation 
        true = SCode.isParameterOrConst(var);
        true = RTOpts.debugFlag("evalparam");
        expTy = Types.elabType(tt) "Constants with equal bindings should be constant, i.e. true
                                    but const is passed on, allowing constants to have wrong bindings
                                    This must be caught later on.";
        expIdTy = Types.elabType(idTp);                            
        cr_1 = fillCrefSubscripts(cr, tt);
        e_1 = crefVectorize(doVect,DAE.CREF(cr_1,expTy), tt, NONE,expIdTy,true);
        (cache,v,_) = Ceval.ceval(cache,env,e_1,false,NONE,NONE,Ceval.MSG());
        e = ValuesUtil.valueExp(v);
        et = Types.typeOfValue(v);
        (e_1,_) = Types.matchType(e, et, tt, true);
      then
        (cache,e_1,DAE.C_PARAM(),SCode.RO());

    // vectorization of parameters with valuebound
    case (cache,env,cr,acc,SCode.PARAM(),_,io,tt,DAE.VALBOUND(valBound = v),doVect,Lookup.SPLICEDEXPDATA(_,idTp),_)
      equation
        expTy = Types.elabType(tt);
        expIdTy = Types.elabType(idTp);
        cr_1 = fillCrefSubscripts(cr, tt);
        e_1 = crefVectorize(doVect,DAE.CREF(cr_1,expTy), tt, NONE,expIdTy,true);
      then
        (cache,e_1,DAE.C_PARAM(),acc);

    // a constant with a binding
    case (cache,env,cr,acc,SCode.CONST(),_,io,tt,DAE.EQBOUND(exp = exp,constant_ = const),doVect,Lookup.SPLICEDEXPDATA(_,idTp),_)
      equation 
        expTy = Types.elabType(tt) "Constants with equal bindings should be constant, i.e. true
                                    but const is passed on, allowing constants to have wrong bindings
                                    This must be caught later on." ;
        expIdTy = Types.elabType(idTp);                                    
        cr_1 = fillCrefSubscripts(cr, tt);
        e_1 = crefVectorize(doVect,DAE.CREF(cr_1,expTy), tt, NONE,expIdTy,true);
      then
        (cache,e_1,const,acc);

    // vectorization of parameters with binding equations
    case (cache,env,cr,acc,SCode.PARAM(),_,io,tt,DAE.EQBOUND(exp = exp ,constant_ = const),doVect,Lookup.SPLICEDEXPDATA(sexp,idTp),_)
      equation
        expTy = Types.elabType(tt) "parameters with equal binding becomes C_PARAM" ;
        expIdTy = Types.elabType(idTp);
        cr_1 = fillCrefSubscripts(cr, tt);
        e_1 = crefVectorize(doVect,DAE.CREF(cr_1,expTy), tt,sexp,expIdTy,true);
      then
        (cache,e_1,DAE.C_PARAM(),acc);

    // variables with constant binding
    case (cache,env,cr,acc,_,_,io,tt,DAE.EQBOUND(exp = exp,constant_ = const),doVect,Lookup.SPLICEDEXPDATA(sexp,idTp),_)
      equation
        expTy = Types.elabType(tt) "..the rest should be non constant, even if they have a constant binding." ;
        expIdTy = Types.elabType(idTp);
        cr_1 = fillCrefSubscripts(cr, tt);
        e_1 = crefVectorize(doVect,DAE.CREF(cr_1,expTy), tt, NONE,expIdTy,true);
      then
        (cache,e_1,DAE.C_VAR(),acc);

    // enum constants does not have a value expression
    case (cache,env,cr,acc,_,_,io,(tt as (DAE.T_ENUMERATION(SOME(_),_,_,_),_)),_,doVect,_,_)
      equation
        expTy = Types.elabType(tt);
      then
        (cache,DAE.CREF(cr,expTy),DAE.C_CONST(),acc);

    // if value not constant, but references another parameter, which has a value perform value propagation.
    case (cache,env,cr,acc,variability,forIteratorConstOpt,io,tp,DAE.EQBOUND(exp = DAE.CREF(componentRef = cref,ty = _),constant_ = DAE.C_VAR()),doVect,splicedExpData,pre)
      equation
        (cache,DAE.ATTR(_,_,acc_1,variability_1,_,io),t,binding_1,_,_,_,_,_) = Lookup.lookupVar(cache, env, cref);
        (cache,e,const,acc) = elabCref2(cache, env, cref, acc_1, variability_1,forIteratorConstOpt, io, t, binding_1,doVect,splicedExpData,pre);
      then
        (cache,e,const,acc);

    // report error
    case (cache,_,cr,_,_,_,_,_,DAE.EQBOUND(exp = exp,constant_ = DAE.C_VAR()),doVect,_,pre)
      equation
        s = Exp.printComponentRefStr(cr);
        str = Exp.printExpStr(exp);
        pre_str = PrefixUtil.printPrefixStr2(pre);
        s = pre_str +& s;
        Error.addMessage(Error.CONSTANT_OR_PARAM_WITH_NONCONST_BINDING, {s,str});
      then
        fail();

    // constants without value produce error. (as long as not for iterator)
    case (cache,env,cr,acc,SCode.CONST(),NONE/*not foriter*/,io,tt,DAE.UNBOUND(),doVect,_,pre)
      equation
        s = Exp.printComponentRefStr(cr);
        scope = Env.printEnvPathStr(env);
        pre_str = PrefixUtil.printPrefixStr2(pre);
        s = pre_str +& s;
        Error.addMessage(Error.NO_CONSTANT_BINDING, {s,scope});
        Debug.fprintln("static","- Static.elabCref2 failed on: " +& pre_str +& s +& " with no constant binding in scope: " +& scope);
        expTy = Types.elabType(tt);
        cr_1 = fillCrefSubscripts(cr, tt);
      then
        (cache,DAE.CREF(cr_1,expTy),DAE.C_CONST(),acc);

    // parameters without value but with fixed=false is ok, these are given value during initialization. (as long as not for iterator)
    case (cache,env,cr,acc,SCode.PARAM(),NONE/* not foriter*/,io,tt,DAE.UNBOUND(),doVect,_,_)
      equation
        false = Types.getFixedVarAttribute(tt);
        expTy = Types.elabType(tt);
        cr_1 = fillCrefSubscripts(cr, tt);
      then
        (cache,DAE.CREF(cr_1,expTy),DAE.C_PARAM(),acc);

    // outer parameters without value is ok.
    case (cache,env,cr,acc,SCode.PARAM(),_,io,tt,DAE.UNBOUND(),doVect,_,_)
      equation
        (_,true) = InnerOuter.innerOuterBooleans(io);
        expTy = Types.elabType(tt);
        cr_1 = fillCrefSubscripts(cr, tt);
      then
        (cache,DAE.CREF(cr_1,expTy),DAE.C_PARAM(),acc);

    // parameters without value with fixed=true or no fixed attribute set produce warning (as long as not for iterator)                 
    case (cache,env,cr,acc,SCode.PARAM(),forIteratorConstOpt,io,tt,DAE.UNBOUND(),doVect,Lookup.SPLICEDEXPDATA(sexp,idTp),pre)
      local Boolean genWarning;
      equation
        s = Exp.printComponentRefStr(cr);
        genWarning = not Util.isSome(forIteratorConstOpt);
        pre_str = PrefixUtil.printPrefixStr2(pre);
        // Don't generate warning if variable is for iterator, since it doesn't have a value (it's iterated over separately)
        s = pre_str +& s;
        Debug.bcall2(genWarning,Error.addMessage,Error.UNBOUND_PARAMETER_WARNING,{s});
        expTy = Types.elabType(tt);
        expIdTy = Types.elabType(idTp);
        cr_1 = fillCrefSubscripts(cr, tt);
        e_1 = crefVectorize(doVect,DAE.CREF(cr_1,expTy), tt,NONE,expIdTy,true);
      then
        (cache,e_1,DAE.C_PARAM(),acc);
      
    // failure!
    case (cache,env,cr,acc,var,_,io,tp,bind,doVect,_,pre)
      equation
        true = RTOpts.debugFlag("failtrace");
        pre_str = PrefixUtil.printPrefixStr2(pre);
        Debug.fprint("failtrace", "- Static.elabCref2 failed for: " +& pre_str +& Exp.printComponentRefStr(cr) +& "\n env:" +& Env.printEnvStr(env));
      then
        fail();
  end matchcontinue;
end elabCref2;

public function crefVectorize
"function: crefVectorize
  This function takes a DAE.Exp and a DAE.Type and if the expression
  is a ComponentRef and the type is an array it returns an array of
  component references with subscripts for each index.
  For instance, parameter Real x[3];
  gives cref_vectorize('x', <arraytype>) => '{x[1],x[2],x[3]}
  This is needed since the DAE does not know what the variable 'x' is,
  it only knows the variables 'x[1]', 'x[2]' and 'x[3]'.
  NOTE: Currently only works for one and two dimensions."
  input Boolean performVectorization "if false, return input";
  input DAE.Exp inExp;
  input DAE.Type inType;
  input Option<DAE.Exp> splicedExp;
  input DAE.ExpType crefIdType "the type of the last cref ident, without considering subscripts. picked up from splicedExpData and used for crefs in vectorized exp";
  input Boolean applyLimits "if true, only perform for small sized arrays (dimsize < vectorization limit (default 20))"; 
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (performVectorization,inExp,inType,splicedExp,crefIdType,applyLimits)
    local
      Boolean b1,b2;
      DAE.ExpType exptp;
      DAE.Exp e;
      DAE.ComponentRef cr;
      DAE.Type t;
      DAE.Dimension d1, d2;

    // no vectorization
    case(false, e, _, _,_,_) then e;

    // types extending basictype
    case (_,e,(DAE.T_COMPLEX(_,_,SOME(t),_),_),_,crefIdType,applyLimits)
      equation
        e = crefVectorize(true,e,t,NONE,crefIdType,applyLimits);
      then e;

    // component reference and an array type with dimensions less than vectorization limit
    case (_, _, (DAE.T_ARRAY(arrayDim = d1, arrayType = (DAE.T_ARRAY(arrayDim = d2), _)), _),
        SOME(DAE.CREF(componentRef = cr)), crefIdType, applyLimits)
      equation
        b1 = (Exp.dimensionSize(d1) < RTOpts.vectorizationLimit());
        b2 = (Exp.dimensionSize(d2) < RTOpts.vectorizationLimit());
        true = boolAnd(b1, b2) or not applyLimits;
        e = elabCrefSlice(cr,crefIdType);
        e = tryToConvertArrayToMatrix(e);
      then
        e;

    case (_, _, (DAE.T_ARRAY(arrayDim = d1, arrayType = t), _), 
        SOME(DAE.CREF(componentRef = cr)), crefIdType, applyLimits)
      equation
        false = Types.isArray(t);
        true = (Exp.dimensionSize(d1) < RTOpts.vectorizationLimit()) or not applyLimits;
        e = elabCrefSlice(cr,crefIdType);
      then
        e;

    /* matrix sizes > vectorization limit is not vectorized */
    case (_, DAE.CREF(componentRef = cr, ty = exptp), 
        (DAE.T_ARRAY(arrayDim = d1, arrayType = t as (DAE.T_ARRAY(arrayDim = d2), _)), _),
        _, crefIdType, applyLimits)
      local
        Integer ds, ds2;
      equation 
        ds = Exp.dimensionSize(d1);
        ds2 = Exp.dimensionSize(d2);
        b1 = (ds < RTOpts.vectorizationLimit());
        b2 = (ds2 < RTOpts.vectorizationLimit());
        true = boolAnd(b1, b2) or not applyLimits;
        e = createCrefArray2d(cr, 1, ds, ds2, exptp, t,crefIdType);
      then
        e;
        
    /* vectorsizes > vectorization limit is not vectorized */ 
    case (_,DAE.CREF(componentRef = cr,ty = exptp),
        (DAE.T_ARRAY(arrayDim = d1,arrayType = t),_),_,crefIdType,applyLimits) 
      local
        Integer ds;
      equation 
        false = Types.isArray(t);
        ds = Exp.dimensionSize(d1);
        true = (ds < RTOpts.vectorizationLimit()) or not applyLimits;
        e = createCrefArray(cr, 1, ds, exptp, t,crefIdType);
      then
        e;
    case (_,e,_,_,_,_) then e; 
  end matchcontinue;
end crefVectorize;

protected function tryToConvertArrayToMatrix
"function trytoConvertToMatrix
  A function that tries to convert an Exp to an Matrix,
  if it fails it just returns the input exp."
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      DAE.Exp exp;
    case(exp)
      equation
        exp = elabMatrixToMatrixExp(exp);
      then exp;
    case(exp) then exp;
  end matchcontinue;
end tryToConvertArrayToMatrix;

protected function extractDimensionOfChild
"function extractDimensionOfChild
  A function for extracting the type-dimension of the child to *me* to dimension *my* array-size.
  Also returns wheter the array is a scalar or not."
  input DAE.Exp inExp;
  output list<DAE.Dimension> outExp;
  output Boolean isScalar;
algorithm
  (outExp,isScalar) := matchcontinue(inExp)
    local
      DAE.Exp exp1,exp2;
      list<DAE.Exp> expl1,expl2;
      DAE.ExpType ety,ety2;
      list<DAE.Dimension> tl;
      Integer x;
      Boolean sc;

    case(exp1 as DAE.ARRAY(ty = (ety as DAE.ET_ARRAY(ty=ety2, arrayDimensions=(tl))),scalar=sc,array=expl1))
    then (tl,sc);

    case(exp1 as DAE.ARRAY(ty = _,scalar=_,array=expl1 as ((exp2 as DAE.ARRAY(_,_,_)) :: expl2)))
      equation
        (tl,_) = extractDimensionOfChild(exp2);
        x = listLength(expl1);
      then
        (DAE.DIM_INTEGER(x)::tl, false );

    case(exp1 as DAE.ARRAY(ty = _,scalar=_,array=expl1))
      equation
        x = listLength(expl1);
      then ({DAE.DIM_INTEGER(x)},true);

    case(exp1 as DAE.CREF(_ , _))
    then
      ({},true);
  end matchcontinue;
end extractDimensionOfChild;

protected function elabCrefSlice
"Bjozac, 2007-05-29  Main function from now for vectorizing output.
 the subscriptlist shold cotain eighter \"done slices\" or numbers representing
 dimension entries.
Example:
1) a is a real[2,3] with no subscripts, the input here should be
CREF_IDENT('a',{DAE.SLICE(DAE.ARRAY(_,_,{1,2})), DAE.SLICE(DAE.ARRAY(_,_,{1,2,3}))})>
   ==> {{a[1,1],a[1,2],a[1,3]},{a[2,1],a[2,2],a[2,3]}}
2) a is a real[3,3] with subscripts {1,2},{1,3}, the input should be
CREF_IDENT('a',{DAE.SLICE(DAE.ARRAY(_,_,{DAE.INDEX(1),DAE.INDEX(2)})),
                DAE.SLICE(DAE.ARRAY(_,_,{DAE.INDEX(1),DAE.INDEX(3)}))})
   ==> {{a[1,1],a[1,3]},{a[2,1],a[2,3]}}"
  input DAE.ComponentRef inCref;
  input DAE.ExpType inType;
  output DAE.Exp outCref;
algorithm
  outCref := matchcontinue(inCref, inType)
    local
      list<DAE.Subscript> ssl;
      DAE.ComponentRef cref;
      String id;
      DAE.Exp exp1,child;
      DAE.ExpType ety;

    case( cref as DAE.CREF_IDENT(ident = id,subscriptLst = ssl),ety)
      equation       
        exp1 = flattenSubscript(ssl,id,ety);
      then
        exp1;
    case( cref as DAE.CREF_QUAL(ident = id, subscriptLst = ssl, componentRef = child),ety)
      equation
        child = elabCrefSlice(child,ety);
        exp1 = flattenSubscript(ssl,id,ety);
        exp1 = mergeQualWithRest(exp1,child,ety) ;
      then
        exp1;
  end matchcontinue;
end elabCrefSlice;

protected function mergeQualWithRest
"function mergeQualWithRest
  Incase we have a qual with child references, this function merges them.
  The input should be an array, or just one CREF_QUAL, of arrays...of arrays
  of CREF_QUALS and the same goes for 'rest'. Also the flat type as input."
  input DAE.Exp qual;
  input DAE.Exp rest;
  input DAE.ExpType inType;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(qual,rest,inType)
    local
      DAE.Exp exp1,exp2;
      list<DAE.Exp> expl1, expl2;
      DAE.Subscript ssl;
      String id;
      DAE.ExpType ety;
    // a component reference
    case(exp1 as DAE.CREF(_,_),exp2,_)
      equation
        exp1 = mergeQualWithRest2(exp2,exp1);
      then exp1;
    // an array
    case(exp1 as DAE.ARRAY(_, _, expl1),exp2,ety)
      local
        list<DAE.Dimension> iLst;
        Boolean scalar;
      equation
        expl1 = Util.listMap2(expl1,mergeQualWithRest,exp2,ety);

        exp2 = DAE.ARRAY(DAE.ET_INT(),false,expl1);
        (iLst, scalar) = extractDimensionOfChild(exp2);
        ety = Exp.arrayEltType(ety);
        exp2 = DAE.ARRAY(DAE.ET_ARRAY( ety, iLst), scalar, expl1);
    then exp2;      
  end matchcontinue;
end mergeQualWithRest;

protected function mergeQualWithRest2
"function mergeQualWithRest
  Helper to mergeQualWithRest, handles the case
  when the child-qual is arrays of arrays."
  input DAE.Exp rest;
  input DAE.Exp qual;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(rest,qual)
    local
      DAE.Exp exp1,exp2;
      list<DAE.Exp> expl1, expl2;
      list<DAE.Subscript> ssl;
      DAE.ComponentRef cref;
      String id;
      DAE.ExpType ety,ty2;
    // a component reference
    case(exp1 as DAE.CREF(cref, ety),exp2 as DAE.CREF(DAE.CREF_IDENT(id,ty2, ssl),_))
      equation
        exp1 = DAE.CREF(DAE.CREF_QUAL(id,ty2, ssl,cref),ety);
      then exp1;
    // an array
    case(exp1 as DAE.ARRAY(_, _, expl1), exp2 as DAE.CREF(DAE.CREF_IDENT(id,_, ssl),ety))
      local
        list<DAE.Dimension> iLst;
        Boolean scalar;
      equation
        expl1 = Util.listMap1(expl1,mergeQualWithRest2,exp2);
        exp1 = DAE.ARRAY(DAE.ET_INT(),false,expl1);
        (iLst, scalar) = extractDimensionOfChild(exp1);
        ety = Exp.arrayEltType(ety);
        exp1 = DAE.ARRAY(DAE.ET_ARRAY( ety, iLst), scalar, expl1);
      then exp1;
  end matchcontinue;
end mergeQualWithRest2;

protected function flattenSubscript
"function flattenSubscript
  Intermediate step for flattenSubscript
  to catch subscript free CREF's."
  input list<DAE.Subscript> inSubs;
  input String name;
  input DAE.ExpType inType;
  output DAE.Exp outExp;
algorithm
  outSub := matchcontinue(inSubs,name, inType)
    local
      String id;
      DAE.Subscript sub1;
      list<DAE.Subscript> subs1;
      list<DAE.Exp> expl1,expl2;
      DAE.Exp exp1,exp2;
      DAE.ExpType ety;
      list<DAE.Exp> expl1;
    // empty list
    case({},id,ety)
      equation
        exp1 = DAE.CREF(DAE.CREF_IDENT(id,ety,{}),ety);
      then
        exp1;
    // some subscripts present
    case(subs1,id,ety) // {1,2,3}
      equation
        exp2 = flattenSubscript2(subs1,id,ety);
      then
        exp2;
  end matchcontinue;
end flattenSubscript;

// BZ(2010-01-29): Changed to public to be able to vectorize crefs from other places
public function flattenSubscript2
"function flattenSubscript2
  This function takes the created 'invalid' subscripts
  and the name of the CREF and returning the CREFS
  Example: flattenSubscript2({SLICE({1,2}},SLICE({1}),\"a\",tp) ==> {{a[1,1]},{a[2,1]}}.

  This is done in several function calls, this specific
  function extracts the numbers ( 1,2 and 1 ).
  "
  input list<DAE.Subscript> inSubs;
  input String name;
  input DAE.ExpType inType;
  output DAE.Exp outExp;
algorithm
  outSub := matchcontinue(inSubs,name, inType)
    local
      String id;
      DAE.Subscript sub1;
      list<DAE.Subscript> subs1;
      list<DAE.Exp> expl1,expl2;
      DAE.Exp exp1,exp2,exp3;
      DAE.ExpType ety;
      list<DAE.Exp> expl1;

    // empty subscript
    case({},_,_) then DAE.ARRAY(DAE.ET_OTHER(),false,{});
    
    // first subscript integer, ety
    case( ( (sub1 as DAE.INDEX(exp = exp1 as DAE.ICONST(_))) :: subs1),id,ety)
      equation
        exp2 = flattenSubscript2(subs1,id,ety);
        //print("1. flattened rest into "+&Exp.dumpExpStr(exp2,0)+&"\n");
        exp2 = applySubscript(exp1, exp2 ,id,Exp.unliftArray(ety));
        //print("1. applied this subscript into "+&Exp.dumpExpStr(exp2,0)+&"\n");
      then
        exp2;
    // special case for zero dimension...
    case( ((sub1 as DAE.SLICE( exp2 as DAE.ARRAY(_,_,(expl1 as DAE.ICONST(0)::{})) )):: subs1),id,ety) // {1,2,3}
      local
        list<DAE.Dimension> iLst;
        Boolean scalar;
      equation
        exp2 = flattenSubscript2(subs1,id,ety);
        expl2 = Util.listMap3(expl1,applySubscript,exp2,id,ety);
        exp3 = listNth(expl2,0);
        exp3 = removeDoubleEmptyArrays(exp3);
      then
        exp3;
    // normal case;
    case( ((sub1 as DAE.SLICE( exp2 as DAE.ARRAY(_,_,expl1) )):: subs1),id,ety) // {1,2,3}
      local
        list<DAE.Dimension> iLst;
        Boolean scalar;
      equation
        exp2 = flattenSubscript2(subs1,id,ety);
        expl2 = Util.listMap3(expl1,applySubscript,exp2,id,ety);
        exp3 = DAE.ARRAY(DAE.ET_INT(),false,expl2);
        (iLst, scalar) = extractDimensionOfChild(exp3);
        ety = Exp.arrayEltType(ety);
        exp3 = DAE.ARRAY(DAE.ET_ARRAY( ety, iLst), scalar, expl2);
        exp3 = removeDoubleEmptyArrays(exp3);
      then
        exp3;
  end matchcontinue;
end flattenSubscript2;

protected function removeDoubleEmptyArrays
"function removeDoubleArrays
 A help function, to prevent the {{}} look of empty arrays."
  input DAE.Exp inArr;
  output DAE.Exp  outArr;
algorithm
  outArr := matchcontinue(inArr)
    local
      DAE.Exp exp1,exp2;
      list<DAE.Exp> expl1,expl2,expl3,expl4;
      DAE.ExpType ty1,ty2;
      Boolean sc;
    case(exp1 as DAE.ARRAY(ty = _,scalar=_,array = expl1 as
      ((exp2 as DAE.ARRAY(ty=_,scalar=_,array={}))::{}) ))
      then
        exp2;
    case(exp1 as DAE.ARRAY(ty = ty1,scalar=sc,array = expl1 as
      ((exp2 as DAE.ARRAY(ty=ty2,scalar=_,array=expl2))::expl3) ))
      equation
        expl3 = Util.listMap(expl1,removeDoubleEmptyArrays);
        exp1 = DAE.ARRAY(ty1, sc, (expl3));
      then
        exp1;
    case(exp1) then exp1;
    case(exp1)
      equation
        print("- Static.removeDoubleEmptyArrays failure for: " +& Exp.printExpStr(exp1) +& "\n");
      then
        fail();
  end matchcontinue;
end removeDoubleEmptyArrays;

protected function applySubscript
"function applySubscript
  here we apply the subscripts to the IDENTS of the CREF's.
  Special case for adressing INDEX[0], make an empty array.
  If we have an array of subscript, we call applySubscript2"
  input DAE.Exp inSub "dim n ";
  input DAE.Exp inSubs "dim >n";
  input String name;
  input DAE.ExpType inType;
  output DAE.Exp outExp;
algorithm
  outSub := matchcontinue(inSub, inSubs ,name, inType)
    local
      String id;
      DAE.Exp exp1,exp2;
      list<DAE.Exp> expl1,expl2;
      DAE.ExpType ety,tmpy,crty;
      list<DAE.Dimension> arrDim;

    case(exp2,exp1 as DAE.ARRAY(DAE.ET_ARRAY(ty =_, arrayDimensions = arrDim) ,_,{}),id ,ety)
      equation
        true = Exp.arrayContainZeroDimension(arrDim);
      then exp1;

        /* add dimensions */       
    case(exp1 as DAE.ICONST(integer=0),exp2 as DAE.ARRAY(DAE.ET_ARRAY(ty =_, arrayDimensions = arrDim) ,_,_),id ,ety) 
      equation
        exp1 = DAE.ARRAY(DAE.ET_ARRAY( ety,DAE.DIM_INTEGER(0)::arrDim),true,{});
      then exp1;

    case(exp1 as DAE.ICONST(integer=0),_,_ ,ety)
      equation
        exp1 = DAE.ARRAY(DAE.ET_ARRAY( ety,{DAE.DIM_INTEGER(0)}),true,{});
      then exp1;

    case(exp1,DAE.ARRAY(_,_,{}),id ,ety)
      equation
        true = Exp.isValidSubscript(exp1);
        crty = Exp.unliftArray(ety) "only subscripting one dimension, unlifting once ";
        exp1 = DAE.CREF(DAE.CREF_IDENT(id,ety,{DAE.INDEX(exp1)}),crty);
      then exp1;

    case(exp1, exp2, id ,ety)
      equation
        true = Exp.isValidSubscript(exp1);
        exp1 = applySubscript2(exp1, exp2,ety);
      then exp1;
  end matchcontinue;
end applySubscript;

protected function applySubscript2
"function applySubscript
  Handles multiple subscripts for the expression.
  If it is an array, we listmap applySubscript3"
  input DAE.Exp inSub "The subs to add";
  input DAE.Exp inSubs "The already created subs";
  input DAE.ExpType inType;
  output DAE.Exp outExp;
algorithm
  outSub := matchcontinue(inSub, inSubs, inType )
    local
      String id;
      DAE.Exp exp1,exp2;
      list<DAE.Exp> expl1,expl2;
      list<DAE.Subscript> subs;
      DAE.ExpType ety,ty2,crty;
      list<DAE.Dimension> iLst;
      Boolean scalar;

    case(exp1 as DAE.ICONST(integer=_),exp2 as DAE.CREF(DAE.CREF_IDENT(id,ty2,subs),_ ),ety )
      equation
        crty = Exp.unliftArrayTypeWithSubs(DAE.INDEX(exp1)::subs,ty2);
        exp2 = DAE.CREF(DAE.CREF_IDENT(id,ty2,(DAE.INDEX(exp1)::subs)),crty);
      then exp2;

    case(exp1 as DAE.ICONST(integer=_), exp2 as DAE.ARRAY(_,_,expl1),ety )
      equation
        expl1 = Util.listMap2(expl1,applySubscript3,exp1,ety);
        exp2 = DAE.ARRAY(DAE.ET_INT(),false,expl1);
        (iLst, scalar) = extractDimensionOfChild(exp2);
        ety = Exp.arrayEltType(ety);
        exp2 = DAE.ARRAY(DAE.ET_ARRAY( ety, iLst), scalar, expl1);
      then exp2;
  end matchcontinue;
end applySubscript2;

protected function applySubscript3
"function applySubscript
  Final applySubscript function, here we call ourself
  recursive until we have the CREFS we are looking for."
  input DAE.Exp inSubs "The already created subs";
  input DAE.Exp inSub "The subs to add";
  input DAE.ExpType inType;
  output DAE.Exp outExp;
algorithm
  outSub := matchcontinue(inSubs,inSub, inType )
    local
      String id;
      DAE.Exp exp1,exp2;
      list<DAE.Exp> expl1,expl2;
      list<DAE.Subscript> subs;
      DAE.ExpType ety,ty2,crty;
      list<DAE.Dimension> iLst;
      Boolean scalar;

    case(exp2 as DAE.CREF(DAE.CREF_IDENT(id,ty2,subs),_), exp1 as DAE.ICONST(integer=_),ety )
      equation
        crty = Exp.unliftArrayTypeWithSubs(DAE.INDEX(exp1)::subs,ty2);
        exp2 = DAE.CREF(DAE.CREF_IDENT(id,ty2,(DAE.INDEX(exp1)::subs)),crty);
      then exp2;

    case( exp2 as DAE.ARRAY(_,_,expl1), exp1 as DAE.ICONST(integer=_),ety)
      equation
        expl1 = Util.listMap2(expl1,applySubscript3,exp1,ety);
        exp2 = DAE.ARRAY(DAE.ET_INT(),false,expl1);
        (iLst, scalar) = extractDimensionOfChild(exp2);
        ety = Exp.unliftArray(ety);
        exp2 = DAE.ARRAY(DAE.ET_ARRAY( ety, iLst), scalar, expl1);
      then exp2;
  end matchcontinue;
end applySubscript3;


protected function callVectorize
"function: callVectorize
  author: PA

  Takes an expression that is a function call and an expresion list
  and maps the call to each expression in the list.
  For instance, call_vectorize(DAE.CALL(XX(\"der\",),...),{1,2,3}))
  => {DAE.CALL(XX(\"der\"),{1}), DAE.CALL(XX(\"der\"),{2}),DAE.CALL(XX(\"der\",{3}))}
  NOTE: the vectorized expression is inserted first in the argument list
 of the call, so if extra arguments should be passed these can be given as
 input to the call expression."
  input DAE.Exp inExp;
  input list<DAE.Exp> inExpExpLst;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst := matchcontinue (inExp,inExpExpLst)
    local
      DAE.Exp e,callexp;
      list<DAE.Exp> es_1,args,es;
      Absyn.Path fn;
      Boolean tuple_,builtin;
      DAE.InlineType inl;
      DAE.ExpType tp;
    // empty list
    case (e,{}) then {};
    // vectorize call
    case ((callexp as DAE.CALL(path = fn,expLst = args,tuple_ = tuple_,builtin = builtin,ty=tp,inlineType=inl)),(e :: es))
      equation
        es_1 = callVectorize(callexp, es);
      then
        (DAE.CALL(fn,(e :: args),tuple_,builtin,tp,inl) :: es_1);
    case (_,_)
      equation
        Debug.fprintln("failtrace", "- Static.callVectorize failed");
      then
        fail();
  end matchcontinue;
end callVectorize;

protected function createCrefArray
"function: createCrefArray
  helper function to crefVectorize, creates each individual cref,
  e.g. {x{1},x{2}, ...} from x."
  input DAE.ComponentRef inComponentRef1;
  input Integer inInteger2;
  input Integer inInteger3;
  input DAE.ExpType inType4;
  input DAE.Type inType5;
  input DAE.ExpType crefIdType;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inComponentRef1,inInteger2,inInteger3,inType4,inType5,crefIdType)
    local
      DAE.ComponentRef cr,cr_1;
      Integer indx,ds,indx_1;
      DAE.ExpType et,elt_tp;
      tuple<DAE.TType, Option<Absyn.Path>> t;
      list<DAE.Exp> expl;
      DAE.Exp e_1;
      list<DAE.Subscript> ss;
    // index iterator dimension size
    case (cr,indx,ds,et,t,crefIdType)  
      equation 
        (indx > ds) = true;
      then
        DAE.ARRAY(et,true,{});
    // for crefs with wholedim
    case (cr,indx,ds,et,t,crefIdType)  
      equation 
        indx_1 = indx + 1;
        DAE.ARRAY(_,_,expl) = createCrefArray(cr, indx_1, ds, et, t,crefIdType);
        DAE.WHOLEDIM()::ss = Exp.crefLastSubs(cr);
        cr_1 = Exp.crefStripLastSubs(cr);
        cr_1 = Exp.subscriptCref(cr_1, DAE.INDEX(DAE.ICONST(indx))::ss);
        elt_tp = Exp.unliftArray(et);
        e_1 = crefVectorize(true,DAE.CREF(cr_1,elt_tp), t,NONE,crefIdType,true);
      then
        DAE.ARRAY(et,true,(e_1 :: expl));
    // no subscript
    case (cr,indx,ds,et,t,crefIdType) 
      equation 
        indx_1 = indx + 1;
        {} = Exp.crefLastSubs(cr);
        DAE.ARRAY(_,_,expl) = createCrefArray(cr, indx_1, ds, et, t,crefIdType);
        cr_1 = Exp.subscriptCref(cr, {DAE.INDEX(DAE.ICONST(indx))});
        elt_tp = Exp.unliftArray(et);
        e_1 = crefVectorize(true,DAE.CREF(cr_1,elt_tp), t,NONE,crefIdType,true);
      then
        DAE.ARRAY(et,true,(e_1 :: expl));
    // index
    case (cr,indx,ds,et,t,crefIdType) 
      equation 
        (DAE.INDEX(e_1) :: ss) = Exp.crefLastSubs(cr);
        cr_1 = Exp.crefStripLastSubs(cr);
        cr_1 = Exp.subscriptCref(cr_1,ss);
        DAE.ARRAY(_,_,expl) = createCrefArray(cr_1, indx, ds, et, t,crefIdType);
        expl = Util.listMap1(expl,Exp.prependSubscriptExp,DAE.INDEX(e_1));
      then
        DAE.ARRAY(et,true,expl);
    // failure
    case (cr,indx,ds,et,t,crefIdType)
      equation
        Debug.fprintln("failtrace", "createCrefArray failed on:" +& Exp.printComponentRefStr(cr));
      then
        fail();
  end matchcontinue;
end createCrefArray;

protected function createCrefArray2d
"function: createCrefArray2d
  helper function to cref_vectorize, creates each
  individual cref, e.g. {x{1,1},x{2,1}, ...} from x."
  input DAE.ComponentRef inComponentRef1;
  input Integer inInteger2;
  input Integer inInteger3;
  input Integer inInteger4;
  input DAE.ExpType inType5;
  input DAE.Type inType6;
  input DAE.ExpType crefIdType;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inComponentRef1,inInteger2,inInteger3,inInteger4,inType5,inType6,crefIdType)
    local
      DAE.ComponentRef cr,cr_1;
      Integer indx,ds,ds2,indx_1;
      DAE.ExpType et,tp,elt_tp;
      tuple<DAE.TType, Option<Absyn.Path>> t;
      list<list<tuple<DAE.Exp, Boolean>>> ms;
      Boolean sc;
      list<DAE.Exp> expl;
      list<Boolean> scs;
      list<tuple<DAE.Exp, Boolean>> row;
    // index iterator dimension size 1 dimension size 2
    case (cr,indx,ds,ds2,et,t,crefIdType) 
      equation 
        (indx > ds) = true;
      then
        DAE.MATRIX(et,0,{});
    // increase the index dimension
    case (cr,indx,ds,ds2,et,t,crefIdType)
      equation
        indx_1 = indx + 1;
        DAE.MATRIX(_,_,ms) = createCrefArray2d(cr, indx_1, ds, ds2, et, t,crefIdType);
        cr_1 = Exp.subscriptCref(cr, {DAE.INDEX(DAE.ICONST(indx))});
        elt_tp = Exp.unliftArray(et);
        DAE.ARRAY(tp,sc,expl) = crefVectorize(true,DAE.CREF(cr_1,elt_tp), t,NONE,crefIdType,true);
        scs = Util.listFill(sc, ds2);
        row = Util.listThreadTuple(expl, scs);
      then
        DAE.MATRIX(et,ds,(row :: ms));
    //
    case (cr,indx,ds,ds2,et,t,crefIdType)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- Static.createCrefArray2d failed on: " +& Exp.printComponentRefStr(cr));
      then
        fail();
  end matchcontinue;
end createCrefArray2d;

protected function elabCrefSubs
"function: elabCrefSubs
  This function elaborates on all subscripts in a component reference."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Prefix.Prefix crefPrefix "the accumulated cref, required for lookup";
  input Boolean inBoolean;
  output Env.Cache outCache;
  output DAE.ComponentRef outComponentRef;
  output DAE.Const outConst "The constness of the subscripts. Note: This is not the same as
  the constness of a cref with subscripts! (just becase x[1,2] has a constant subscript list does
  not mean that the variable x[1,2] is constant)";
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outComponentRef,outConst,outDae) := matchcontinue (inCache,inEnv,inComponentRef,crefPrefix,inBoolean)
    local
      tuple<DAE.TType, Option<Absyn.Path>> t;
      list<DAE.Dimension> sl;
      DAE.Const const,const1,const2;
      list<Env.Frame> env;
      Ident id;
      list<Absyn.Subscript> ss;
      Boolean impl;
      DAE.ComponentRef cr;
      DAE.ExpType ty;
      list<DAE.Subscript> ss_1;
      Absyn.ComponentRef subs;
      DAE.ComponentRef esubs;
      Env.Cache cache;
      list<Integer> indexes;
      SCode.Variability vt;
      DAE.DAElist dae,dae1,dae2;

    // Wildcard
    case( cache,env, Absyn.WILD(),_,impl) then (cache,DAE.WILD(),DAE.C_VAR(),DAEUtil.emptyDae);
    // IDENT
    case (cache,env,Absyn.CREF_IDENT(name = id,subscripts = ss),crefPrefix,impl)
      equation
        // Debug.traceln("Try elabSucscriptsDims " +& id);
        (cache,cr) = PrefixUtil.prefixCref(cache,env,InnerOuter.emptyInstHierarchy,crefPrefix,DAE.CREF_IDENT(id,DAE.ET_OTHER(),{}));
        (cache,_,t,_,_,_,_,_,_) = Lookup.lookupVar(cache,env,cr);
        // print("elabCrefSubs type of: " +& id +& " is " +& Types.printTypeStr(t) +& "\n"); 
        // Debug.traceln("    elabSucscriptsDims " +& id +& " got var");
        ty = Types.elabType(t);
        sl = Types.getDimensions(t);
        /*Constant evaluate subscripts on form x[1,p,q] where p,q are constants or parameters*/
        (cache,ss_1,const,dae) = elabSubscriptsDims(cache,env, ss, sl, impl,crefPrefix); 
      then       
        (cache,DAE.CREF_IDENT(id,ty,ss_1),const,dae);
    // QUAL,with no subscripts => looking for var
    case (cache,env,cr as Absyn.CREF_QUAL(name = id,subScripts = {},componentRef = subs),crefPrefix,impl)
      equation
        (cache,cr) = PrefixUtil.prefixCref(cache,env,InnerOuter.emptyInstHierarchy,crefPrefix,DAE.CREF_IDENT(id,DAE.ET_OTHER(),{}));
        //print("env:");print(Env.printEnvStr(env));print("\n");
        (cache,_,t,_,_,_,_,_,_) = Lookup.lookupVar(cache,env,cr);
        ty = Types.elabType(t);
        crefPrefix = PrefixUtil.prefixAdd(id,{},crefPrefix,SCode.VAR(),ClassInf.UNKNOWN(Absyn.IDENT(""))); // variability doesn't matter
        (cache,cr,const,dae) = elabCrefSubs(cache,env, subs,crefPrefix,impl);
      then
        (cache,DAE.CREF_QUAL(id,ty,{},cr),const,dae);
    // QUAL,with no subscripts second case => look for class
    case (cache,env,cr as Absyn.CREF_QUAL(name = id,subScripts = {},componentRef = subs),crefPrefix,impl)
      equation
        crefPrefix = PrefixUtil.prefixAdd(id,{},crefPrefix,SCode.VAR(),ClassInf.UNKNOWN(Absyn.IDENT(""))); // variability doesn't matter
        (cache,cr,const,dae) = elabCrefSubs(cache,env, subs,crefPrefix,impl);
      then
        (cache,DAE.CREF_QUAL(id,DAE.ET_COMPLEX(Absyn.IDENT(""),{},ClassInf.UNKNOWN(Absyn.IDENT(""))),{},cr),const,dae);
    // QUAL,with constant subscripts
    case (cache,env,cr as Absyn.CREF_QUAL(name = id,subScripts = ss as _::_,componentRef = subs),crefPrefix,impl)
      equation
        (cache,cr) = PrefixUtil.prefixCref(cache,env,InnerOuter.emptyInstHierarchy,crefPrefix,DAE.CREF_IDENT(id,DAE.ET_OTHER(),{}));
        (cache,DAE.ATTR(_,_,_,vt,_,_),t,_,_,_,_,_,_) = Lookup.lookupVar(cache,env, cr);
        sl = Types.getDimensions(t);
        ty = Types.elabType(t);
        (cache,ss_1,const1,dae1) = elabSubscriptsDims(cache,env, ss, sl, impl,crefPrefix);
        //indexes = Exp.subscriptsInt(ss_1);
        //crefPrefix = Prefix.prefixAdd(id,indexes,crefPrefix,vt);
        crefPrefix = PrefixUtil.prefixAdd(id, {}, crefPrefix, vt,ClassInf.UNKNOWN(Absyn.IDENT("")));
        (cache,cr,const2,dae2) = elabCrefSubs(cache,env, subs,crefPrefix,impl);
        const = Types.constAnd(const1, const2);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,DAE.CREF_QUAL(id,ty,ss_1,cr),const,dae);

    // failure
    case (cache,env,cr,crefPrefix,impl)
      local Absyn.ComponentRef cr;
      equation 
        // FAILTRACE REMOVE
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- Static.elabCrefSubs failed on: prefix: " +&
        PrefixUtil.printPrefixStr(crefPrefix) +& " cr: " +&
          Dump.printComponentRefStr(cr) +& " env: " +&
          Env.printEnvPathStr(env));
        // System.enableTrace();
      then
        fail();
  end matchcontinue;
end elabCrefSubs;

public function elabSubscripts 
"function: elabSubscripts 
  This function converts a list of Absyn.Subscript to a list of
  DAE.Subscript, and checks if all subscripts are constant.
  HJ: not checking for constant, returning if constant or not"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Subscript> inAbsynSubscriptLst;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output list<DAE.Subscript> outExpSubscriptLst;
  output DAE.Const outConst;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExpSubscriptLst,outConst,outDae) := matchcontinue (inCache,inEnv,inAbsynSubscriptLst,inBoolean,inPrefix)
    local
      DAE.Subscript sub_1;
      DAE.Const const1,const2,const;
      list<DAE.Subscript> subs_1;
      list<Env.Frame> env;
      Absyn.Subscript sub;
      list<Absyn.Subscript> subs;
      Boolean impl;
      Env.Cache cache;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;

    // empty list
    case (cache,_,{},_,_) then (cache,{},DAE.C_CONST(),DAEUtil.emptyDae);
    // elab a subscript then recurse
    case (cache,env,(sub :: subs),impl,pre)
      equation
        (cache,sub_1,const1,dae1) = elabSubscript(cache,env, sub, impl,pre);
        (cache,subs_1,const2,dae2) = elabSubscripts(cache,env, subs, impl,pre);
        const = Types.constAnd(const1, const2);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,(sub_1 :: subs_1),const,dae);
  end matchcontinue;
end elabSubscripts;

protected function elabSubscriptsDims
"function: elabSubscriptsDims
  Helper function to elabSubscripts"
  input Env.Cache cache;
  input Env.Env env;
  input list<Absyn.Subscript> subs;
  input list<DAE.Dimension> dims;
  input Boolean impl;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output list<DAE.Subscript> outSubs;
  output DAE.Const outConst;
  output DAE.DAElist outDae;
algorithm
  (outCache,outSubs,outConst,outDae) := matchcontinue (cache,env,subs,dims,impl,inPrefix)
    local
      String s1,s2,sp;
      DAE.DAElist dae;
      Prefix pre;

    case (cache,env,subs,dims,impl,pre)
      equation
        ErrorExt.setCheckpoint("elabSubscriptsDims");
        (outCache,outSubs,outConst,dae) = elabSubscriptsDims2(cache,env,subs,dims,impl,pre);
        ErrorExt.rollBack("elabSubscriptsDims");
      then (outCache,outSubs,outConst,dae);

    case (cache,env,subs,dims,impl,pre)
      equation
        ErrorExt.rollBack("elabSubscriptsDims");
        s1 = Dump.printSubscriptsStr(subs);
        s2 = Types.printDimensionsStr(dims);
        sp = PrefixUtil.printPrefixStr3(pre);
        //print(" adding error for {{" +& s1 +& "}},,{{" +& s2 +& "}} ");
        Error.addMessage(Error.ILLEGAL_SUBSCRIPT,{s1,s2,sp});
      then fail();
    end matchcontinue;
end elabSubscriptsDims;

protected function elabSubscriptsDims2
"Helper function to elabSubscriptsDims"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Subscript> inAbsynSubscriptLst;
  input list<DAE.Dimension> inIntegerLst;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output list<DAE.Subscript> outExpSubscriptLst;
  output DAE.Const outConst;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outExpSubscriptLst,outConst,outDae) := matchcontinue (inCache,inEnv,inAbsynSubscriptLst,inIntegerLst,inBoolean,inPrefix)
    local
      DAE.Subscript sub_1;
      DAE.Const const1,const2,const;
      list<DAE.Subscript> subs_1,ss;
      list<Env.Frame> env;
      Absyn.Subscript sub;
      list<Absyn.Subscript> subs;
      DAE.Dimension dim;
      Integer int_dim;
      list<DAE.Dimension> restdims,dims;
      Boolean impl;
      Env.Cache cache;
      DAE.DAElist dae,dae1,dae2;
      Prefix pre;

    // empty list
    case (cache,_,{},_,_,_) then (cache,{},DAE.C_CONST(),DAEUtil.emptyDae);

    // if in for iterator loop scope the subscript should never be evaluated to a value 
    //(since the parameter/const value of iterator variables are not available until expansion, which happens later on)
    // Note that for loops are expanded 'on the fly' and should therefore not be treated in this way.
    case (cache,env,(sub :: subs),(dim :: restdims),impl, pre) /* If param, call ceval. */
      equation
        true = Env.inForIterLoopScope(env);
        true = Exp.dimensionKnown(dim);
        (cache,sub_1,const1,dae1) = elabSubscript(cache,env, sub, impl,pre);
        (cache,subs_1,const2,dae2) = elabSubscriptsDims2(cache,env, subs, restdims, impl,pre);
        const = Types.constAnd(const1, const2);        
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,sub_1::subs_1,const,dae);

    // If the subscript contains a param or const then it should be evaluated to the value
    case (cache,env,(sub :: subs),(dim :: restdims),impl, pre) /* If param or const, call ceval. */
      equation
        int_dim = Exp.dimensionSize(dim);
        (cache,sub_1,const1,dae1) = elabSubscript(cache,env, sub, impl, pre);
        (cache,subs_1,const2,dae2) = elabSubscriptsDims2(cache,env, subs, restdims, impl, pre);
        const = Types.constAnd(const1, const2);
        true = Types.isParameterOrConstant(const);
        (cache,sub_1) = Ceval.cevalSubscript(cache,env,sub_1,int_dim,impl,Ceval.MSG());
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,sub_1::subs_1,const,dae);

    // If the previous case failed and we're just checking the model, try again
    // but skip the constant evaluation.
    case (cache,env,(sub :: subs),(dim :: restdims),impl, pre) 
      equation
        true = OptManager.getOption("checkModel");
        true = Exp.dimensionKnown(dim);
        (cache,sub_1,const1,dae1) = elabSubscript(cache,env, sub, impl, pre);
        (cache,subs_1,const2,dae2) = elabSubscriptsDims2(cache,env, subs, restdims, impl, pre);
        const = Types.constAnd(const1, const2);
        true = Types.isParameterOrConstant(const);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,sub_1::subs_1,const,dae);
        
    // if not constant, keep as is.
    case (cache,env,(sub :: subs),(dim :: restdims),impl, pre)
      equation
        true = Exp.dimensionKnown(dim);
        (cache,sub_1,const1,dae1) = elabSubscript(cache,env, sub, impl, pre);
        (cache,subs_1,const2,dae2) = elabSubscriptsDims2(cache,env, subs, restdims, impl, pre);       
        const = Types.constAnd(const1, const2);
        false = Types.isParameterOrConstant(const);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,(sub_1 :: subs_1),const,dae);

    // for unknown dimension, ':', keep as is.
    case (cache,env,(sub :: subs),(DAE.DIM_NONE :: restdims),impl, pre)
      equation
        (cache,sub_1,const1,dae1) = elabSubscript(cache,env, sub, impl,pre);
        (cache,subs_1,const2,dae2) = elabSubscriptsDims2(cache,env, subs, restdims, impl,pre);       
        const = Types.constAnd(const1, const2);
        dae = DAEUtil.joinDaes(dae1,dae2);
      then
        (cache,(sub_1 :: subs_1),const,dae);
  end matchcontinue;
end elabSubscriptsDims2;

protected function elabSubscript "function: elabSubscript

  This function converts an `Absyn.Subscript\' to an
  `DAE.Subscript\'."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Subscript inSubscript;
  input Boolean inBoolean;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Subscript outSubscript;
  output DAE.Const outConst;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache,outSubscript,outConst,outDae):=
  matchcontinue (inCache,inEnv,inSubscript,inBoolean,inPrefix)
    local
      Boolean impl;
      DAE.Exp sub_1;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      DAE.Const const;
      DAE.Subscript sub_2;
      list<Env.Frame> env;
      Absyn.Exp sub;
      Env.Cache cache;
      DAE.DAElist dae;
      DAE.Properties prop;
      Prefix pre;

    // no subscript      
    case (cache,_,Absyn.NOSUB(),impl,_) then (cache,DAE.WHOLEDIM(),DAE.C_CONST(),DAEUtil.emptyDae);

    // some subscript, try to elaborate it
    case (cache,env,Absyn.SUBSCRIPT(subScript = sub),impl,pre)
      equation
        (cache,sub_1,prop as DAE.PROP(ty,const),_,dae) = elabExp(cache,env, sub, impl, NONE,true,pre); 
        (cache, sub_1, prop as DAE.PROP(ty, _)) = Ceval.cevalIfConstant(cache, env, sub_1, prop, impl);
        sub_2 = elabSubscriptType(ty, sub, sub_1,pre);
      then
        (cache,sub_2,const,dae);
    // some subscript, try to elaborate it
    case (cache,env,inSubscript,impl,_)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- Static.elabSubscript failed on " +&
          Dump.printSubscriptStr(inSubscript) +& " in env: " +&
          Env.printEnvPathStr(env));
      then
        fail();
  end matchcontinue;
end elabSubscript;

protected function elabSubscriptType "function: elabSubscriptType

  This function is used to find the correct constructor for
  DAE.Subscript to use for an indexing expression.  If an integer
  is given as index, DAE.INDEX() is used, and if an integer array
  is given, DAE.SLICE() is used."
  input DAE.Type inType1;
  input Absyn.Exp inExp2;
  input DAE.Exp inExp3;
  input Prefix inPrefix;
  output DAE.Subscript outSubscript;
algorithm
  outSubscript := matchcontinue (inType1,inExp2,inExp3,inPrefix)
    local
      DAE.Exp sub;
      Ident e_str,t_str,p_str;
      tuple<DAE.TType, Option<Absyn.Path>> t;
      Absyn.Exp e;
      Prefix pre;

    case ((DAE.T_INTEGER(varLstInt = _),_),_,sub,_) then DAE.INDEX(sub); 
    case ((DAE.T_ENUMERATION(_,_,_,_),_),_,sub,_) then DAE.INDEX(sub);
    case ((DAE.T_ARRAY(arrayType = (DAE.T_INTEGER(varLstInt = _),_)),_),_,sub,_) then DAE.SLICE(sub);
    case (t,e,_,pre)
      equation
        e_str = Dump.printExpStr(e);
        t_str = Types.unparseType(t);
        p_str = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.SUBSCRIPT_NOT_INT_OR_INT_ARRAY, {e_str,t_str,p_str});
      then
        fail();
  end matchcontinue;
end elabSubscriptType;

protected function subscriptCrefType
"function: subscriptCrefType
  If a component of an array type is subscripted, the type of the
  component reference is of lower dimensionality than the
  component.  This function shows the function between the component
  type and the component reference expression type.

  This function might actually not be needed.
"
  input DAE.Exp inExp;
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inExp,inType)
    local
      tuple<DAE.TType, Option<Absyn.Path>> t_1,t;
      DAE.ComponentRef c;
      DAE.Exp e;

    case (DAE.CREF(componentRef = c),t)
      equation
        t_1 = subscriptCrefType2(c, t);
      then
        t_1;

    case (e,t) then t; 
  end matchcontinue;
end subscriptCrefType;

protected function subscriptCrefType2
  input DAE.ComponentRef inComponentRef;
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inComponentRef,inType)
    local
      tuple<DAE.TType, Option<Absyn.Path>> t,t_1;
      list<DAE.Subscript> subs;
      DAE.ComponentRef c;

    case (DAE.CREF_IDENT(subscriptLst = {}),t) then t; 
    case (DAE.CREF_IDENT(subscriptLst = subs),t)
      equation
        t_1 = subscriptType(t, subs);
      then
        t_1;
    case (DAE.CREF_QUAL(componentRef = c),t)
      equation
        t_1 = subscriptCrefType2(c, t);
      then
        t_1;
  end matchcontinue;
end subscriptCrefType2;

protected function subscriptType "function: subscriptType 
  Given an array dimensionality and a list of subscripts, this
  function reduces the dimensionality.
  This does not handle slices or check that subscripts are not out
  of bounds."
  input DAE.Type inType;
  input list<DAE.Subscript> inExpSubscriptLst;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inType,inExpSubscriptLst)
    local
      tuple<DAE.TType, Option<Absyn.Path>> t,t_1;
      list<DAE.Subscript> subs;
      DAE.Dimension dim;
      Option<Absyn.Path> p;

    case (t,{}) then t; 
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM_INTEGER(integer = _),arrayType = t),_),(DAE.INDEX(exp = _) :: subs))
      equation
        t_1 = subscriptType(t, subs);
      then
        t_1;
    case ((DAE.T_ARRAY(arrayDim = dim,arrayType = t),p),(DAE.SLICE(exp = _) :: subs))
      equation
        t_1 = subscriptType(t, subs);
      then
        ((DAE.T_ARRAY(dim,t_1),p));
    case ((DAE.T_ARRAY(arrayDim = dim,arrayType = t),p),(DAE.WHOLEDIM() :: subs))
      equation
        t_1 = subscriptType(t, subs);
      then
        ((DAE.T_ARRAY(dim,t_1),p));
    case (t,_)
      equation
        Print.printBuf("- subscript_type failed (");
        Print.printBuf(Types.printTypeStr(t));
        Print.printBuf(" , [...])\n");
      then
        fail();
  end matchcontinue;
end subscriptType;

protected function elabIfexpBranch "Dirty hack function that only elaborated the selected branch of an if expression if the other branch
can not be elaborated (due to e.g. indexing out of bounds in array, etc.)
The non-selected branch will be replaced by a dummy variable called $undefined such that code generation does not fail later on"
  input Env.Cache cache;
  input Env.Env env;
  input Boolean b "selected branch";
  input DAE.Exp cond;
  input Absyn.Exp tbranch;
  input Absyn.Exp fbranch;
  input Boolean impl;
  input Option<Interactive.InteractiveSymbolTable> st;
  input Boolean doVect;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp exp;
  output DAE.Properties prop;
  output Option<Interactive.InteractiveSymbolTable> outSt;
  output DAE.DAElist outDae "contain functions";
algorithm
  (outCache, exp, prop,outSt,outDae) := matchcontinue(cache,env,b,cond,tbranch,fbranch,impl,st,doVect,inPrefix)
    local 
      DAE.Exp e2; DAE.Properties prop1;
      Option<Interactive.InteractiveSymbolTable> st_1;
      DAE.DAElist dae;
      Prefix pre;

    // Select true-branch
    case(cache,env,true,cond,tbranch,fbranch,impl,st,doVect,pre) equation
      (cache,e2,prop1,st_1,dae) = elabExp(cache,env, tbranch, impl, st,doVect,pre);
    then (cache,DAE.IFEXP(cond,e2,DAE.CREF(DAE.CREF_IDENT("$undefined",DAE.ET_OTHER(),{}),DAE.ET_OTHER())),prop1,st_1,dae);

    // Select false-branch
    case(cache,env,false,cond,tbranch,fbranch,impl,st,doVect,pre) equation
      (cache,e2,prop1,st_1,dae) = elabExp(cache,env, fbranch, impl, st,doVect,pre);
    then (cache,DAE.IFEXP(cond,DAE.CREF(DAE.CREF_IDENT("$undefined",DAE.ET_OTHER(),{}),DAE.ET_OTHER()),e2),prop1,st_1,dae);
  end matchcontinue;
end elabIfexpBranch;

protected function elabIfexp "function: elabIfexp  
  This function elaborates on the parts of an if expression."
  input Env.Cache inCache;
  input Env.Env inEnv1;
  input DAE.Exp inExp2;
  input DAE.Properties inProperties3;
  input DAE.Exp inExp4;
  input DAE.Properties inProperties5;
  input DAE.Exp inExp6;
  input DAE.Properties inProperties7;
  input Boolean inBoolean8;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption9;
  input Prefix inPrefix;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv1,inExp2,inProperties3,inExp4,inProperties5,inExp6,inProperties7,inBoolean8,inInteractiveInteractiveSymbolTableOption9,inPrefix)
    local
      DAE.Const c,c1,c2,c3;
      DAE.Exp exp,e1,e2,e3,e2_1,e3_1;
      list<Env.Frame> env;
      tuple<DAE.TType, Option<Absyn.Path>> t2,t3,t2_1,t3_1,t1;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Ident e_str,t_str,e1_str,t1_str,e2_str,t2_str,pre_str;
      Env.Cache cache;
      Prefix pre;

    case (cache,env,e1,DAE.PROP(type_ = (DAE.T_BOOL(varLstBool = _),_),constFlag = c1),e2,DAE.PROP(type_ = t2,constFlag = c2),e3,DAE.PROP(type_ = t3,constFlag = c3),impl,st,_)
      equation
        true = Types.semiEquivTypes(t2, t3);
        c = constIfexp(e1, c1, c2, c3);
        (cache,exp) = cevalIfexpIfConstant(cache,env, e1, e2, e3, c1, impl, st);
      then
        (cache,exp,DAE.PROP(t2,c));

    case (cache,env,e1,DAE.PROP(type_ = (DAE.T_BOOL(varLstBool = _),_),constFlag = c1),e2,DAE.PROP(type_ = t2,constFlag = c2),e3,DAE.PROP(type_ = t3,constFlag = c3),impl,st,_)
      equation
        (e2_1,t2_1) = Types.matchType(e2, t2, t3, true);
        c = constIfexp(e1, c1, c2, c3) "then-part type converted to match else-part" ;
        (cache,exp) = cevalIfexpIfConstant(cache,env, e1, e2_1, e3, c1, impl, st);
      then
        (cache,exp,DAE.PROP(t2_1,c));

    case (cache,env,e1,DAE.PROP(type_ = (DAE.T_BOOL(varLstBool = _),_),constFlag = c1),e2,DAE.PROP(type_ = t2,constFlag = c2),e3,DAE.PROP(type_ = t3,constFlag = c3),impl,st,_)
      equation
        (e3_1,t3_1) = Types.matchType(e3, t3, t2, true);
        c = constIfexp(e1, c1, c2, c3) "else-part type converted to match then-part" ;
        (cache,exp) = cevalIfexpIfConstant(cache,env, e1, e2, e3_1, c1, impl, st);
      then
        (cache,exp,DAE.PROP(t2,c));

    case (cache,env,e1,DAE.PROP(type_ = t1,constFlag = c1),e2,DAE.PROP(type_ = t2,constFlag = c2),e3,DAE.PROP(type_ = t3,constFlag = c3),impl,st,pre)
      equation
        failure(equality(t1 = DAE.T_BOOL_DEFAULT()));
        e_str = Exp.printExpStr(e1);
        t_str = Types.unparseType(t1);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        t_str = t_str +& " (in component: "+&pre_str+&")";
        Error.addMessage(Error.IF_CONDITION_TYPE_ERROR(), {e_str,t_str});
      then
        fail();

    case (cache,env,e1,DAE.PROP(type_ = (DAE.T_BOOL(varLstBool = _),_),constFlag = c1),e2,DAE.PROP(type_ = t2,constFlag = c2),e3,DAE.PROP(type_ = t3,constFlag = c3),impl,st,pre)
      equation
        false = Types.semiEquivTypes(t2, t3);
        e1_str = Exp.printExpStr(e2);
        t1_str = Types.unparseType(t2);
        e2_str = Exp.printExpStr(e3);
        t2_str = Types.unparseType(t3);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.TYPE_MISMATCH_IF_EXP, {pre_str,e1_str,t1_str,e2_str,t2_str});
      then
        fail();

    case (_,_,_,_,_,_,_,_,_,_,_)
      equation
        Print.printBuf("- Static.elabIfexp failed\n");
      then
        fail();
  end matchcontinue;
end elabIfexp;

protected function cevalIfexpIfConstant "function: cevalIfexpIfConstant
  author: PA
  Constant evaluates the condition of an expression if it is constants and
  elimitates the if expressions by selecting branch."
  input Env.Cache inCache;
  input Env.Env inEnv1;
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;
  input DAE.Exp inExp4;
  input DAE.Const inConst5;
  input Boolean inBoolean6;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption7;
  output Env.Cache outCache;
  output DAE.Exp outExp;
algorithm
  (outCache,outExp) :=
  matchcontinue (inCache,inEnv1,inExp2,inExp3,inExp4,inConst5,inBoolean6,inInteractiveInteractiveSymbolTableOption7)
    local
      list<Env.Frame> env;
      DAE.Exp e1,e2,e3,res;
      Boolean impl,cond;
      Option<Interactive.InteractiveSymbolTable> st;
      Env.Cache cache;
    case (cache,env,e1,e2,e3,DAE.C_VAR(),impl,st) then (cache,DAE.IFEXP(e1,e2,e3));
    case (cache,env,e1,e2,e3,DAE.C_PARAM(),impl,st) then (cache,DAE.IFEXP(e1,e2,e3));
    case (cache,env,e1,e2,e3,DAE.C_CONST(),impl,st)
      equation
        (cache,Values.BOOL(cond),_) = Ceval.ceval(cache,env, e1, impl, st, NONE, Ceval.MSG());
        res = Util.if_(cond, e2, e3);
      then
        (cache,res);
  end matchcontinue;
end cevalIfexpIfConstant;

protected function constIfexp "function: constIfexp
  Tests wether an *if* expression is constant.  This is done by
  first testing if the conditional is constant, and if so evaluating
  it to see which branch should be tested for constant-ness.
  This will miss some occations where the expression actually 
  is constant, as in the expression *if x then 1.0 else 1.0*"
  input DAE.Exp inExp1;
  input DAE.Const inConst2;
  input DAE.Const inConst3;
  input DAE.Const inConst4;
  output DAE.Const outConst;
algorithm
  outConst := matchcontinue (inExp1,inConst2,inConst3,inConst4)
    local DAE.Const const,c1,c2,c3;
    case (_,c1,c2,c3)
      equation
        const = Util.listReduce({c1,c2,c3}, Types.constAnd);
      then
        const;
  end matchcontinue;
end constIfexp;

protected function canonCref2 "function: canonCref2
  This function relates a DAE.ComponentRef to its canonical form,
  which is when all subscripts are evaluated to constant values.  
  If Such an evaluation is not possible, there is no canonical 
  form and this function fails."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inComponentRef;
  input DAE.ComponentRef inPrefixCref;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output DAE.ComponentRef outComponentRef;
algorithm
  (outCache,outComponentRef) :=
  matchcontinue (inCache,inEnv,inComponentRef,inPrefixCref,inBoolean)
    local
      list<DAE.Subscript> ss_1,ss;
      list<Env.Frame> env;
      Ident n;
      Boolean impl;
      Env.Cache cache;
      DAE.ComponentRef prefixCr,cr;
      list<Integer> sl;
      tuple<DAE.TType, Option<Absyn.Path>> t;
      DAE.ExpType ty2;
    case (cache,env,DAE.CREF_IDENT(ident = n,identType = ty2, subscriptLst = ss),prefixCr,impl) /* impl */
      equation
        cr = Exp.joinCrefs(prefixCr,DAE.CREF_IDENT(n,ty2,{}));
        (cache,_,t,_,_,_,_,_,_) = Lookup.lookupVar(cache,env, cr);
        sl = Types.getDimensionSizes(t);
        (cache,ss_1) = Ceval.cevalSubscripts(cache,env, ss, sl, impl, Ceval.MSG());
      then
        (cache,DAE.CREF_IDENT(n,ty2,ss_1));
  end matchcontinue;
end canonCref2;

public function canonCref "function: canonCref
  Transform expression to canonical form
  by constant evaluating all subscripts."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inComponentRef;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output DAE.ComponentRef outComponentRef;
algorithm
  (outCache,outComponentRef) :=
  matchcontinue (inCache,inEnv,inComponentRef,inBoolean)
    local
      tuple<DAE.TType, Option<Absyn.Path>> t;
      list<Integer> sl;
      list<DAE.Subscript> ss_1,ss;
      list<Env.Frame> env, componentEnv;
      Ident n;
      Boolean impl;
      DAE.ComponentRef c_1,c,cr;
      Env.Cache cache;
      DAE.ExpType ty2;

    // handle wild _
    case (cache,env,DAE.WILD,impl)
      equation 
        true = RTOpts.acceptMetaModelicaGrammar();
      then
        (cache,DAE.WILD);

    // an unqualified component reference
    case (cache,env,DAE.CREF_IDENT(ident = n,subscriptLst = ss),impl) /* impl */ 
      equation 
        (cache,_,t,_,_,_,_,_,_) = Lookup.lookupVar(cache, env, DAE.CREF_IDENT(n,DAE.ET_OTHER(),{}));
        sl = Types.getDimensionSizes(t);
        (cache,ss_1) = Ceval.cevalSubscripts(cache, env, ss, sl, impl, Ceval.MSG());
        ty2 = Types.elabType(t);
      then
        (cache,DAE.CREF_IDENT(n,ty2,ss_1));

    // a qualified component reference
    case (cache,env,DAE.CREF_QUAL(ident = n,subscriptLst = ss,componentRef = c),impl)
      equation
        (cache,_,t,_,_,_,_,componentEnv,_) = Lookup.lookupVar(cache, env, DAE.CREF_IDENT(n,DAE.ET_OTHER(),{}));
        ty2 = Types.elabType(t);
        sl = Types.getDimensionSizes(t);
        (cache,ss_1) = Ceval.cevalSubscripts(cache, env, ss, sl, impl, Ceval.MSG());
       //(cache,c_1) = canonCref2(cache, env, c, DAE.CREF_IDENT(n,ty2,ss), impl);
       (cache, c_1) = canonCref(cache, componentEnv, c, impl);
      then
        (cache,DAE.CREF_QUAL(n,ty2, ss_1,c_1));

    // failtrace
    case (cache,env,cr,_)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "- Static.canonCref failed, cr: ");
        Debug.fprint("failtrace", Exp.printComponentRefStr(cr));
        Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end canonCref;

public function eqCref "- Equality functions
  function: eqCref

  This function checks if two component references can be considered
  equal and fails if not.  Two component references are equal if all
  corresponding identifiers are the same, and if the subscripts are
  equal, according to the function `eq_subscripts\'.
"
  input DAE.ComponentRef inComponentRef1;
  input DAE.ComponentRef inComponentRef2;
algorithm
  _:=
  matchcontinue (inComponentRef1,inComponentRef2)
    local
      Ident n1,n2;
      list<DAE.Subscript> s1,s2;
      DAE.ComponentRef c1,c2;
    case (DAE.CREF_IDENT(ident = n1,subscriptLst = s1),DAE.CREF_IDENT(ident = n2,subscriptLst = s2))
      equation
        true = stringEqual(n1, n2);
        eqSubscripts(s1, s2);
      then
        ();
    case (DAE.CREF_QUAL(ident = n1,subscriptLst = s1,componentRef = c1),DAE.CREF_QUAL(ident = n2,subscriptLst = s2,componentRef = c2))
      equation
        true = stringEqual(n1, n2);
        eqSubscripts(s1, s2);
        eqCref(c1, c2);
      then
        ();
  end matchcontinue;
end eqCref;

protected function eqSubscripts "function: eqSubscripts

  Two list of subscripts are equal if they are of equal length and
  all their elements are pairwise equal according to the function
  `eq_subscript\'.
"
  input list<DAE.Subscript> inExpSubscriptLst1;
  input list<DAE.Subscript> inExpSubscriptLst2;
algorithm
  _:=
  matchcontinue (inExpSubscriptLst1,inExpSubscriptLst2)
    local
      DAE.Subscript s1,s2;
      list<DAE.Subscript> ss1,ss2;
    case ({},{}) then ();
    case ((s1 :: ss1),(s2 :: ss2))
      equation
        eqSubscript(s1, s2);
        eqSubscripts(ss1, ss2);
      then
        ();
  end matchcontinue;
end eqSubscripts;

protected function eqSubscript "function: eqSubscript
  This function test whether two subscripts are equal.  
  Two subscripts are equal if they have the same constructor, and 
  if all corresponding expressions are either syntactically equal, 
  or if they have the same constant value."
  input DAE.Subscript inSubscript1;
  input DAE.Subscript inSubscript2;
algorithm
  _ := matchcontinue (inSubscript1,inSubscript2)
    local DAE.Exp s1,s2;
    case (DAE.WHOLEDIM(),DAE.WHOLEDIM()) then ();
    case (DAE.INDEX(exp = s1),DAE.INDEX(exp = s2))
      equation
        true = Exp.expEqual(s1, s2);
      then
        ();
  end matchcontinue;
end eqSubscript;

/*
 * - Argument type casting and operator de-overloading
 *
 *  If a function is called with arguments that don\'t match the
 *  expected parameter types, implicit type conversions are performed
 *  in some cases.  Usually it is an integer argument that is promoted
 *  to a real.
 *
 *  Many operators in Modelica are overloaded, meaning that they can
 *  operate on several different types of arguments.  To describe what
 *  it means to add, say, an integer and a real number, the
 *  expressions have to be de-overloaded, with one operator for each
 *  distinct operation.
 */

protected function elabArglist 
"function: elabArglist
  Given a list of parameter types and an argument list, this
  function tries to match the two, promoting the type of 
  arguments when necessary."
  input list<DAE.Type> inTypesTypeLst;
  input list<tuple<DAE.Exp, DAE.Type>> inTplExpExpTypesTypeLst;
  output list<DAE.Exp> outExpExpLst;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  (outExpExpLst,outTypesTypeLst) := matchcontinue (inTypesTypeLst,inTplExpExpTypesTypeLst)
    local
      DAE.Exp arg_1,arg;
      tuple<DAE.TType, Option<Absyn.Path>> atype_1,pt,atype;
      list<DAE.Exp> args_1;
      list<tuple<DAE.TType, Option<Absyn.Path>>> atypes_1,pts;
      list<tuple<DAE.Exp, tuple<DAE.TType, Option<Absyn.Path>>>> args;
    
    // empty lists
    case ({},{}) then ({},{});
    
    // we have something 
    case ((pt :: pts),((arg,atype) :: args))
      equation
        (arg_1,atype_1) = Types.matchType(arg, atype, pt, false);
        (args_1,atypes_1) = elabArglist(pts, args);
      then
        ((arg_1 :: args_1),(atype_1 :: atypes_1));
  end matchcontinue;
end elabArglist;

public function deoverload "function: deoverload
  Given several lists of parameter types and one argument list, 
  this function tries to find one list of parameter types which 
  is compatible with the argument list. It uses elabArglist to 
  do the matching, which means that automatic type conversions 
  will be made when necessary.  The new argument list, together 
  with a new operator that corresponds to the parameter type list 
  is returned.
  
  The basic principle is that the first operator that matches is chosen.
  
  The third argument to the function is the expression containing
  the operation to be deoverloaded.  It is only used for error
  messages."
  input list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> inTplExpOperatorTypesTypeLstTypesTypeLst;
  input list<tuple<DAE.Exp, DAE.Type>> inTplExpExpTypesTypeLst;
  input Absyn.Exp inExp;
  input Prefix inPrefix;
  output DAE.Operator outOperator;
  output list<DAE.Exp> outExpExpLst;
  output DAE.Type outType;
algorithm
  (outOperator,outExpExpLst,outType) := matchcontinue (inTplExpOperatorTypesTypeLstTypesTypeLst,inTplExpExpTypesTypeLst,inExp,inPrefix)
    local
      list<DAE.Exp> args_1,exps;
      list<tuple<DAE.TType, Option<Absyn.Path>>> types_1,params,tps;
      tuple<DAE.TType, Option<Absyn.Path>> rtype_1,rtype;
      DAE.Operator op;
      list<tuple<DAE.Exp, tuple<DAE.TType, Option<Absyn.Path>>>> args;
      list<tuple<DAE.Operator, list<tuple<DAE.TType, Option<Absyn.Path>>>, tuple<DAE.TType, Option<Absyn.Path>>>> xs;
      Absyn.Exp exp;
      Ident s,estr,tpsstr,pre_str;
      list<Ident> exps_str,tps_str;
      Prefix pre;
      DAE.ExpType ty;

    case (((op,params,rtype) :: _),args,_,pre)
      equation
        //Debug.fprint("dovl", Util.stringDelimitList(Util.listMap(params, Types.printTypeStr),"\n"));
        //Debug.fprint("dovl", "\n===\n");
        (args_1,types_1) = elabArglist(params, args);
        rtype_1 = computeReturnType(op, types_1, rtype,pre);
        ty = Types.elabType(rtype_1);
        op = Exp.setOpType(op, ty);
      then
        (op,args_1,rtype_1);
    
    case ((_ :: xs),args,exp,pre)
      equation
        (op,args_1,rtype) = deoverload(xs, args, exp,pre);
      then
        (op,args_1,rtype);
    
    case ({},args,exp,pre)
      equation
        s = Dump.printExpStr(exp);
        exps = Util.listMap(args, Util.tuple21);
        tps = Util.listMap(args, Util.tuple22);
        exps_str = Util.listMap(exps, Exp.printExpStr);
        estr = Util.stringDelimitList(exps_str, ", ");
        tps_str = Util.listMap(tps, Types.unparseType);
        tpsstr = Util.stringDelimitList(tps_str, ", ");
        pre_str = PrefixUtil.printPrefixStr3(pre);
        s = Util.stringAppendList({s," (expressions :",estr," types: ",tpsstr,")"});
        Error.addMessage(Error.UNRESOLVABLE_TYPE, {s,pre_str});
      then
        fail();
  end matchcontinue;
end deoverload;

protected function computeReturnType "function: computeReturnType
  This function determines the return type of 
  an operator and the types of the operands."
  input DAE.Operator inOperator;
  input list<DAE.Type> inTypesTypeLst;
  input DAE.Type inType;
  input Prefix inPrefix;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inOperator,inTypesTypeLst,inType,inPrefix)
    local
      tuple<DAE.TType, Option<Absyn.Path>> typ1,typ2,rtype,etype,typ;
      Ident t1_str,t2_str,pre_str;
      Integer n1,n2,m,n,m1,m2,p;
      Prefix pre;
    
    case (DAE.ADD_ARR(ty = _),{typ1,typ2},rtype,_)
      equation
        true = Types.subtype(typ1, typ2);
      then
        typ1;
    
    case (DAE.ADD_ARR(ty = _),{typ1,typ2},rtype,_)
      equation
        true = Types.subtype(typ1, typ2);
      then
        typ1;
    
    case (DAE.ADD_ARR(ty = _),{typ1,typ2},_,pre)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        //t2_str = t2_str +& ", in component: " +& pre_str;
        Error.addMessage(Error.INCOMPATIBLE_TYPES(), {"vector addition",pre_str,t1_str,t2_str});
      then
        fail();
    
    case (DAE.SUB_ARR(ty = _),{typ1,typ2},rtype,_)
      equation
        true = Types.subtype(typ1, typ2);
      then
        typ1;
    
    case (DAE.SUB_ARR(ty = _),{typ1,typ2},rtype,_)
      equation
        true = Types.subtype(typ1, typ2);
      then
        typ1;
    
    case (DAE.SUB_ARR(ty = _),{typ1,typ2},_,pre)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        //t2_str = t2_str +& ", in component: " +& pre_str;
        Error.addMessage(Error.INCOMPATIBLE_TYPES(),{"vector subtraction",pre_str,t1_str,t2_str});
      then
        fail();
    
    case (DAE.MUL_ARR(ty = _),{typ1,typ2},rtype,_)
      equation
        true = Types.subtype(typ1, typ2);
      then
        typ1;
    
    case (DAE.MUL_ARR(ty = _),{typ1,typ2},rtype,_)
      equation
        true = Types.subtype(typ1, typ2);
      then
        typ1;
    
    case (DAE.MUL_ARR(ty = _),{typ1,typ2},_,pre)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        //t2_str = t2_str +& ", in component: " +& pre_str;
        Error.addMessage(Error.INCOMPATIBLE_TYPES,{"vector elementwise multiplication",pre_str,t1_str,t2_str});
      then
        fail();
    
    case (DAE.DIV_ARR(ty = _),{typ1,typ2},rtype,_)
      equation
        true = Types.subtype(typ1, typ2);
      then
        typ1;
    
    case (DAE.DIV_ARR(ty = _),{typ1,typ2},rtype,_)
      equation
        true = Types.subtype(typ1, typ2);
      then
        typ1;
    
    case (DAE.DIV_ARR(ty = _),{typ1,typ2},_,pre)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        //t2_str = t2_str +& ", in component: " +& pre_str;
        Error.addMessage(Error.INCOMPATIBLE_TYPES(),{"vector elementwise division",pre_str,t1_str,t2_str});
      then
        fail();
    
    // Matrix[n,m]^i
    case (DAE.POW_ARR(ty = _),{typ1,typ2},_,_)
      equation
        2 = nDims(typ1);
        n = dimSize(typ1, 1);
        m1 = dimSize(typ1, 2);
        true = intEq(n, m1);
      then
        typ1;
    
    case (DAE.POW_ARR2(ty = _),{typ1,typ2},rtype,_)
      equation
        true = Types.subtype(typ1, typ2);
      then
        typ1;
    
    case (DAE.POW_ARR2(ty = _),{typ1,typ2},rtype,_)
      equation
        true = Types.subtype(typ1, typ2);
      then
        typ1;
    
    case (DAE.POW_ARR2(ty = _),{typ1,typ2},_,pre)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        //t2_str = t2_str +& ", in component: " +& pre_str;
        Error.addMessage(Error.INCOMPATIBLE_TYPES, {"elementwise vector^vector",pre_str,t1_str,t2_str});
      then
        fail();
    
    case (DAE.MUL_SCALAR_PRODUCT(ty = _),{typ1,typ2},rtype,_)
      equation
        true = Types.subtype(typ1, typ2);
      then
        rtype;
    
    case (DAE.MUL_SCALAR_PRODUCT(ty = _),{typ1,typ2},rtype,_)
      equation
        true = Types.subtype(typ1, typ2);
      then
        rtype;
    
    case (DAE.MUL_SCALAR_PRODUCT(ty = _),{typ1,typ2},rtype,pre)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        //t2_str = t2_str +& ", in component: " +& pre_str;
        Error.addMessage(Error.INCOMPATIBLE_TYPES, {"scalar product",pre_str,t1_str,t2_str});
      then
        fail();
    
    // Vector[n]*Matrix[n,m]
    case (DAE.MUL_MATRIX_PRODUCT(ty = _),{typ1,typ2},_,_)
      equation
        1 = nDims(typ1);
        2 = nDims(typ2);
        n1 = dimSize(typ1, 1);
        n2 = dimSize(typ2, 1);
        m = dimSize(typ2, 2);
        true = intEq(n1, n2);
        etype = elementType(typ1);
        rtype = (DAE.T_ARRAY(DAE.DIM_INTEGER(m),etype),NONE);
      then
        rtype;
    
    // Matrix[n,m]*Vector[m]
    case (DAE.MUL_MATRIX_PRODUCT(ty = _),{typ1,typ2},_,_)
      equation
        2 = nDims(typ1);
        1 = nDims(typ2);
        n = dimSize(typ1, 1);
        m1 = dimSize(typ1, 2);
        m2 = dimSize(typ2, 1);
        true = intEq(m1, m2);
        etype = elementType(typ2);
        rtype = (DAE.T_ARRAY(DAE.DIM_INTEGER(n),etype),NONE);
      then
        rtype;
    
    case (DAE.MUL_MATRIX_PRODUCT(ty = _),{typ1,typ2},_,_)
      equation
        2 = nDims(typ1);
        2 = nDims(typ2);
        n = dimSize(typ1, 1);
        m1 = dimSize(typ1, 2);
        m2 = dimSize(typ2, 1);
        p = dimSize(typ2, 2);
        true = intEq(m1, m2);
        etype = elementType(typ1);
        rtype = (DAE.T_ARRAY(DAE.DIM_INTEGER(n), (DAE.T_ARRAY(DAE.DIM_INTEGER(p),etype),NONE)),NONE);
      then
        rtype;
    
    case (DAE.MUL_MATRIX_PRODUCT(ty = _),{typ1,typ2},rtype,pre)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        //t2_str = t2_str +& ", in component: " +& pre_str;
        Error.addMessage(Error.INCOMPATIBLE_TYPES(),{"matrix multiplication",pre_str,t1_str,t2_str});
      then
        fail();
    
    case (DAE.MUL_SCALAR_ARRAY(ty = _),{typ1,typ2},rtype,_) then typ2;  /* rtype */

    case (DAE.MUL_ARRAY_SCALAR(ty = _),{typ1,typ2},rtype,_) then typ1;  /* rtype */

    case (DAE.ADD_SCALAR_ARRAY(ty = _),{typ1,typ2},rtype,_) then typ2;  /* rtype */

    case (DAE.ADD_ARRAY_SCALAR(ty = _),{typ1,typ2},rtype,_) then typ1;  /* rtype */

    case (DAE.SUB_SCALAR_ARRAY(ty = _),{typ1,typ2},rtype,_) then typ2;  /* rtype */

    case (DAE.SUB_ARRAY_SCALAR(ty = _),{typ1,typ2},rtype,_) then typ1;  /* rtype */

    case (DAE.DIV_SCALAR_ARRAY(ty = _),{typ1,typ2},rtype,_) then typ2;  /* rtype */

    case (DAE.DIV_ARRAY_SCALAR(ty = _),{typ1,typ2},rtype,_) then typ1;  /* rtype */

    case (DAE.POW_ARRAY_SCALAR(ty = _),{typ1,typ2},rtype,_) then typ1;  /* rtype */

    case (DAE.POW_SCALAR_ARRAY(ty = _),{typ1,typ2},rtype,_) then typ2;  /* rtype */

    case (DAE.ADD(ty = _),_,typ,_) then typ;

    case (DAE.SUB(ty = _),_,typ,_) then typ;

    case (DAE.MUL(ty = _),_,typ,_) then typ;

    case (DAE.DIV(ty = _),_,typ,_) then typ;

    case (DAE.POW(ty = _),_,typ,_) then typ;

    case (DAE.UMINUS(ty = _),_,typ,_) then typ;

    case (DAE.UMINUS_ARR(ty = _),(typ1 :: _),_,_) then typ1;

    case (DAE.UPLUS(ty = _),_,typ,_) then typ;

    case (DAE.UPLUS_ARR(ty = _),(typ1 :: _),_,_) then typ1;

    case (DAE.AND(),_,typ,_) then typ;

    case (DAE.OR(),_,typ,_) then typ;

    case (DAE.NOT(),_,typ,_) then typ;

    case (DAE.LESS(ty = _),_,typ,_) then typ;

    case (DAE.LESSEQ(ty = _),_,typ,_) then typ;

    case (DAE.GREATER(ty = _),_,typ,_) then typ;

    case (DAE.GREATEREQ(ty = _),_,typ,_) then typ;

    case (DAE.EQUAL(ty = _),_,typ,_) then typ;

    case (DAE.NEQUAL(ty = _),_,typ,_) then typ;

    case (DAE.USERDEFINED(fqName = _),_,typ,_) then typ;
  end matchcontinue;
end computeReturnType;

public function nDims "function nDims
  Returns the number of dimensions of a Type."
  input DAE.Type inType;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inType)
    local
      Integer ns;
      tuple<DAE.TType, Option<Absyn.Path>> t;
    case ((DAE.T_INTEGER(varLstInt = _),_)) then 0;
    case ((DAE.T_REAL(varLstReal = _),_)) then 0;
    case ((DAE.T_STRING(varLstString = _),_)) then 0;
    case ((DAE.T_BOOL(varLstBool = _),_)) then 0;
    case ((DAE.T_ARRAY(arrayType = t),_))
      equation
        ns = nDims(t);
      then
        ns + 1;
    case ((DAE.T_COMPLEX(_,_,SOME(t),_),_))
      equation
        ns = nDims(t);
      then ns;
  end matchcontinue;
end nDims;

protected function dimSize "function: dimSize
  Returns the dimension size of the given dimesion."
  input DAE.Type inType;
  input Integer inInteger;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inType,inInteger)
    local
      Integer n,d_1,d;
      tuple<DAE.TType, Option<Absyn.Path>> t;
    case ((DAE.T_ARRAY(arrayDim = DAE.DIM_INTEGER(integer = n)),_),1) then n;  /* n:th dimension size of n:nth dimension */
    case ((DAE.T_ARRAY(arrayType = t),_),d)
      equation
        (d > 1) = true;
        d_1 = d - 1;
        n = dimSize(t, d_1);
      then
        n;
    case ((DAE.T_COMPLEX(_,_,SOME(t),_),_),d)
      equation
       n = dimSize(t, d);
      then
        n;
  end matchcontinue;
end dimSize;

protected function elementType "function: elementType
  Returns the element type of a type, i.e. for arrays, return the 
  element type, and for bulitin scalar types return the type itself."
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inType)
    local tuple<DAE.TType, Option<Absyn.Path>> t,t_1;
    case ((t as (DAE.T_INTEGER(varLstInt = _),_))) then t;
    case ((t as (DAE.T_REAL(varLstReal = _),_))) then t;
    case ((t as (DAE.T_STRING(varLstString = _),_))) then t;
    case ((t as (DAE.T_BOOL(varLstBool = _),_))) then t;
    case ((DAE.T_ARRAY(arrayType = t),_))
      equation
        t_1 = elementType(t);
      then
        t_1;
    case ((DAE.T_COMPLEX(_,_,SOME(t),_),_))
      equation
        t_1 = elementType(t);
      then t_1;
  end matchcontinue;
end elementType;

/* We have these as constants instead of function calls as done previously
 * because it takes a long time to generate these types over and over again.
 * The types are a bit hard to read, but they are simply 1 through 9-dimensional
 * arrays of the basic types. */
protected constant list<DAE.Type> intarrtypes = {
  (DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_INTEGER_DEFAULT),NONE), // 1-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_INTEGER_DEFAULT),NONE)),NONE), // 2-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_INTEGER_DEFAULT),NONE)),NONE)),NONE), // 3-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_INTEGER_DEFAULT),NONE)),NONE)),NONE)),NONE), // 4-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_INTEGER_DEFAULT),NONE)),NONE)),NONE)),NONE)),NONE), // 5-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_INTEGER_DEFAULT),NONE)),NONE)),NONE)),NONE)),NONE)),NONE), // 6-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_INTEGER_DEFAULT),NONE)),NONE)),NONE)),NONE)),NONE)),NONE)),NONE), // 7-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_INTEGER_DEFAULT),NONE)),NONE)),NONE)),NONE)),NONE)),NONE)),NONE)),NONE), // 8-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_INTEGER_DEFAULT),NONE)),NONE)),NONE)),NONE)),NONE)),NONE)),NONE)),NONE)),NONE) // 9-dim
};
protected constant list<DAE.Type> realarrtypes = {
  (DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_REAL_DEFAULT),NONE), // 1-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_REAL_DEFAULT),NONE)),NONE), // 2-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_REAL_DEFAULT),NONE)),NONE)),NONE), // 3-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_REAL_DEFAULT),NONE)),NONE)),NONE)),NONE), // 4-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_REAL_DEFAULT),NONE)),NONE)),NONE)),NONE)),NONE), // 5-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_REAL_DEFAULT),NONE)),NONE)),NONE)),NONE)),NONE)),NONE), // 6-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_REAL_DEFAULT),NONE)),NONE)),NONE)),NONE)),NONE)),NONE)),NONE), // 7-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_REAL_DEFAULT),NONE)),NONE)),NONE)),NONE)),NONE)),NONE)),NONE)),NONE), // 8-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_REAL_DEFAULT),NONE)),NONE)),NONE)),NONE)),NONE)),NONE)),NONE)),NONE)),NONE) // 9-dim
};
protected constant list<DAE.Type> stringarrtypes = {
  (DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_STRING_DEFAULT),NONE), // 1-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_STRING_DEFAULT),NONE)),NONE), // 2-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_STRING_DEFAULT),NONE)),NONE)),NONE), // 3-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_STRING_DEFAULT),NONE)),NONE)),NONE)),NONE), // 4-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_STRING_DEFAULT),NONE)),NONE)),NONE)),NONE)),NONE), // 5-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_STRING_DEFAULT),NONE)),NONE)),NONE)),NONE)),NONE)),NONE), // 6-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_STRING_DEFAULT),NONE)),NONE)),NONE)),NONE)),NONE)),NONE)),NONE), // 7-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_STRING_DEFAULT),NONE)),NONE)),NONE)),NONE)),NONE)),NONE)),NONE)),NONE), // 8-dim
  (DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,(DAE.T_ARRAY(DAE.DIM_NONE,DAE.T_STRING_DEFAULT),NONE)),NONE)),NONE)),NONE)),NONE)),NONE)),NONE)),NONE)),NONE) // 9-dim
};
/* Simply a list of 9 of that basic type; used to match with the array types */
protected constant list<DAE.Type> inttypes = {
  DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT
};
protected constant list<DAE.Type> realtypes = {
  DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT
};
protected constant list<DAE.Type> stringtypes = {
  DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT
};


public function operators "function: operators

  This function relates the operators in the abstract syntax to the
  de-overloaded operators in the SCode. It produces a list of available
  types for a specific operator, that the overload function chooses from.
  Therefore, in order for the builtin type conversion from Integer to
  Real to work, operators that work on both Integers and Reals must
  return the Integer type -before- the Real type in the list.
"
  input Env.Cache inCache;
  input Absyn.Operator inOperator1;
  input Env.Env inEnv2;
  input DAE.Type inType3;
  input DAE.Type inType4;
  output Env.Cache outCache;
  output list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> outTplExpOperatorTypesTypeLstTypesTypeLst;
algorithm
  (outCache,outTplExpOperatorTypesTypeLstTypesTypeLst) :=
  matchcontinue (inCache,inOperator1,inEnv2,inType3,inType4)
    local
      list<tuple<DAE.Operator, list<tuple<DAE.TType, Option<Absyn.Path>>>, tuple<DAE.TType, Option<Absyn.Path>>>> intarrs,realarrs,stringarrs,scalars,userops,arrays,types,scalarprod,matrixprod,intscalararrs,realscalararrs,intarrsscalar,realarrsscalar,realarrscalar,arrscalar,stringscalararrs,stringarrsscalar;
      list<Env.Frame> env;
      tuple<DAE.TType, Option<Absyn.Path>> t1,t2,int_scalar,int_vector,int_matrix,real_scalar,real_vector,real_matrix;
      DAE.Operator int_mul,real_mul,int_mul_sp,real_mul_sp,int_mul_mp,real_mul_mp,real_div,real_pow,int_pow;
      Ident s;
      Absyn.Operator op;
      Env.Cache cache;
      DAE.ExpType defaultExpType;
    case (cache,Absyn.ADD(),env,t1,t2) /* Arithmetical operators */
      equation
        intarrs = operatorReturn(DAE.ADD_ARR(DAE.ET_ARRAY(DAE.ET_INT(), {DAE.DIM_NONE})),
                    intarrtypes, intarrtypes, intarrtypes);
        realarrs = operatorReturn(DAE.ADD_ARR(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
                     realarrtypes, realarrtypes, realarrtypes);
        stringarrs = operatorReturn(DAE.ADD_ARR(DAE.ET_ARRAY(DAE.ET_STRING(), {DAE.DIM_NONE})),
                       stringarrtypes, stringarrtypes, stringarrtypes);
        scalars = {
          (DAE.ADD(DAE.ET_INT()),
          {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_INTEGER_DEFAULT),
          (DAE.ADD(DAE.ET_REAL()),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_REAL_DEFAULT),
          (DAE.ADD(DAE.ET_STRING()),
          {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_STRING_DEFAULT)};
        arrays = Util.listFlatten({intarrs,realarrs,stringarrs});
        types = Util.listFlatten({scalars,arrays});
      then
        (cache,types);
    case (cache,Absyn.ADD_EW(),env,t1,t2) /* Arithmetical operators */
      equation
        intarrs = operatorReturn(DAE.ADD_ARR(DAE.ET_ARRAY(DAE.ET_INT(), {DAE.DIM_NONE})),
                    intarrtypes, intarrtypes, intarrtypes);
        realarrs = operatorReturn(DAE.ADD_ARR(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
                     realarrtypes, realarrtypes, realarrtypes);
        stringarrs = operatorReturn(DAE.ADD_ARR(DAE.ET_ARRAY(DAE.ET_STRING(), {DAE.DIM_NONE})),
                       stringarrtypes, stringarrtypes, stringarrtypes);
        scalars = {
          (DAE.ADD(DAE.ET_INT()),
          {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_INTEGER_DEFAULT),
          (DAE.ADD(DAE.ET_REAL()),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_REAL_DEFAULT),
          (DAE.ADD(DAE.ET_STRING()),
          {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_STRING_DEFAULT)};
        intscalararrs = operatorReturn(DAE.ADD_SCALAR_ARRAY(DAE.ET_ARRAY(DAE.ET_INT(), {DAE.DIM_NONE})),
                          inttypes, intarrtypes, intarrtypes);
        realscalararrs = operatorReturn(DAE.ADD_SCALAR_ARRAY(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
                           realtypes, realarrtypes, realarrtypes);
        intarrsscalar = operatorReturn(DAE.ADD_ARRAY_SCALAR(DAE.ET_ARRAY(DAE.ET_INT(), {DAE.DIM_NONE})),
                          intarrtypes, inttypes, intarrtypes);
        realarrsscalar = operatorReturn(DAE.ADD_ARRAY_SCALAR(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
                           realarrtypes, realtypes, realarrtypes);
        stringscalararrs = operatorReturn(DAE.ADD_SCALAR_ARRAY(DAE.ET_ARRAY(DAE.ET_STRING(), {DAE.DIM_NONE})),
                             stringtypes, stringarrtypes, stringarrtypes);
        stringarrsscalar = operatorReturn(DAE.ADD_ARRAY_SCALAR(DAE.ET_ARRAY(DAE.ET_STRING(), {DAE.DIM_NONE})),
                             stringarrtypes, stringtypes, stringarrtypes);
        types = Util.listFlatten({scalars,intscalararrs,realscalararrs,stringscalararrs,intarrsscalar,
          realarrsscalar,stringarrsscalar,intarrs,realarrs,stringarrs});
      then
        (cache,types);

    case (cache,Absyn.SUB(),env,t1,t2)
      equation
        intarrs = operatorReturn(DAE.SUB_ARR(DAE.ET_ARRAY(DAE.ET_INT(), {DAE.DIM_NONE})),
                    intarrtypes, intarrtypes, intarrtypes);
        realarrs = operatorReturn(DAE.SUB_ARR(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
                     realarrtypes, realarrtypes, realarrtypes);
        scalars = {
          (DAE.SUB(DAE.ET_INT()),
          {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_INTEGER_DEFAULT),
          (DAE.SUB(DAE.ET_REAL()),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_REAL_DEFAULT)};
        types = Util.listFlatten({scalars,intarrs,realarrs});
      then
        (cache,types);
    case (cache,Absyn.SUB_EW(),env,t1,t2) /* Arithmetical operators */
      equation
        intarrs = operatorReturn(DAE.SUB_ARR(DAE.ET_ARRAY(DAE.ET_INT(), {DAE.DIM_NONE})),
                    intarrtypes, intarrtypes, intarrtypes);
        realarrs = operatorReturn(DAE.SUB_ARR(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
                     realarrtypes, realarrtypes, realarrtypes);
        scalars = {
          (DAE.SUB(DAE.ET_INT()),
          {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_INTEGER_DEFAULT),
          (DAE.SUB(DAE.ET_REAL()),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_REAL_DEFAULT)};
        intscalararrs = operatorReturn(DAE.SUB_SCALAR_ARRAY(DAE.ET_ARRAY(DAE.ET_INT(), {DAE.DIM_NONE})),
                          inttypes, intarrtypes, intarrtypes);
        realscalararrs = operatorReturn(DAE.SUB_SCALAR_ARRAY(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
                           realtypes, realarrtypes, realarrtypes);
        intarrsscalar = operatorReturn(DAE.SUB_ARRAY_SCALAR(DAE.ET_ARRAY(DAE.ET_INT(), {DAE.DIM_NONE})),
                          intarrtypes, inttypes, intarrtypes);
        realarrsscalar = operatorReturn(DAE.SUB_ARRAY_SCALAR(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
                           realarrtypes, realtypes, realarrtypes);
        types = Util.listFlatten({scalars,intscalararrs,realscalararrs,intarrsscalar,
          realarrsscalar,intarrs,realarrs});
      then
        (cache,types);

    case (cache,Absyn.MUL(),env,t1,t2)
      equation
        int_mul = DAE.MUL(DAE.ET_INT());
        real_mul = DAE.MUL(DAE.ET_REAL());
        int_mul_sp = DAE.MUL_SCALAR_PRODUCT(DAE.ET_INT());
        real_mul_sp = DAE.MUL_SCALAR_PRODUCT(DAE.ET_REAL());
        int_mul_mp = DAE.MUL_MATRIX_PRODUCT(DAE.ET_INT());
        real_mul_mp = DAE.MUL_MATRIX_PRODUCT(DAE.ET_REAL());
        int_scalar = DAE.T_INTEGER_DEFAULT;
        int_vector = (DAE.T_ARRAY(DAE.DIM_NONE,int_scalar),NONE);
        int_matrix = (DAE.T_ARRAY(DAE.DIM_NONE,int_vector),NONE);
        real_scalar = DAE.T_REAL_DEFAULT;
        real_vector = (DAE.T_ARRAY(DAE.DIM_NONE,real_scalar),NONE);
        real_matrix = (DAE.T_ARRAY(DAE.DIM_NONE,real_vector),NONE);
        scalars = {(int_mul,{int_scalar,int_scalar},int_scalar),
          (real_mul,{real_scalar,real_scalar},real_scalar)};
        scalarprod = {(int_mul_sp,{int_vector,int_vector},int_scalar),
          (real_mul_sp,{real_vector,real_vector},real_scalar)};
        matrixprod = {(int_mul_mp,{int_vector,int_matrix},int_vector),
          (int_mul_mp,{int_matrix,int_vector},int_vector),(int_mul_mp,{int_matrix,int_matrix},int_matrix),
          (real_mul_mp,{real_vector,real_matrix},real_vector),(real_mul_mp,{real_matrix,real_vector},real_vector),
          (real_mul_mp,{real_matrix,real_matrix},real_matrix)};
        intscalararrs = operatorReturn(DAE.MUL_SCALAR_ARRAY(DAE.ET_ARRAY(DAE.ET_INT(), {DAE.DIM_NONE})),
                          inttypes, intarrtypes, intarrtypes);
        realscalararrs = operatorReturn(DAE.MUL_SCALAR_ARRAY(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
                           realtypes, realarrtypes, realarrtypes);
        intarrsscalar = operatorReturn(DAE.MUL_ARRAY_SCALAR(DAE.ET_ARRAY(DAE.ET_INT(), {DAE.DIM_NONE})),
                          intarrtypes, inttypes, intarrtypes);
        realarrsscalar = operatorReturn(DAE.MUL_ARRAY_SCALAR(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
                           realarrtypes, realtypes, realarrtypes);
        types = Util.listFlatten(
          {scalars,intscalararrs,realscalararrs,intarrsscalar,
          realarrsscalar,scalarprod,matrixprod});
      then
        (cache,types);
    case (cache,Absyn.MUL_EW(),env,t1,t2) /* Arithmetical operators */
      equation
        intarrs = operatorReturn(DAE.MUL_ARR(DAE.ET_ARRAY(DAE.ET_INT(), {DAE.DIM_NONE})),
					intarrtypes, intarrtypes, intarrtypes);
        realarrs = operatorReturn(DAE.MUL_ARR(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
					realarrtypes, realarrtypes, realarrtypes);
        scalars = {
          (DAE.MUL(DAE.ET_INT()),
          {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_INTEGER_DEFAULT),
          (DAE.MUL(DAE.ET_REAL()),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_REAL_DEFAULT)};
        intscalararrs = operatorReturn(DAE.MUL_SCALAR_ARRAY(DAE.ET_ARRAY(DAE.ET_INT(), {DAE.DIM_NONE})),
					inttypes, intarrtypes, intarrtypes);
        realscalararrs = operatorReturn(DAE.MUL_SCALAR_ARRAY(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
					realtypes, realarrtypes, realarrtypes);
        intarrsscalar = operatorReturn(DAE.MUL_ARRAY_SCALAR(DAE.ET_ARRAY(DAE.ET_INT(), {DAE.DIM_NONE})),
					intarrtypes, inttypes, intarrtypes);
        realarrsscalar = operatorReturn(DAE.MUL_ARRAY_SCALAR(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
					realarrtypes, realtypes, realarrtypes);
        types = Util.listFlatten({scalars,intscalararrs,realscalararrs,intarrsscalar,
          realarrsscalar,intarrs,realarrs});
      then
        (cache,types);

    case (cache,Absyn.DIV(),env,t1,t2)
      equation
        real_div = DAE.DIV(DAE.ET_REAL());
        real_scalar = DAE.T_REAL_DEFAULT;
        scalars = {(real_div,{real_scalar,real_scalar},real_scalar)};
        realarrscalar = operatorReturn(DAE.DIV_ARRAY_SCALAR(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
					realarrtypes, realtypes, realarrtypes);
        types = Util.listFlatten({scalars,realarrscalar});
      then
        (cache,types);
    case (cache,Absyn.DIV_EW(),env,t1,t2) /* Arithmetical operators */
      equation
        realarrs = operatorReturn(DAE.DIV_ARR(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
					realarrtypes, realarrtypes, realarrtypes);
        scalars = {
          (DAE.DIV(DAE.ET_REAL()),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_REAL_DEFAULT)};
        realscalararrs = operatorReturn(DAE.DIV_SCALAR_ARRAY(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
					realtypes, realarrtypes, realarrtypes);
        realarrsscalar = operatorReturn(DAE.DIV_ARRAY_SCALAR(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
					realarrtypes, realtypes, realarrtypes);
        types = Util.listFlatten({scalars,realscalararrs,
          realarrsscalar,realarrs});
      then
        (cache,types);

    case (cache,Absyn.POW(),env,t1,t2)
      equation
        real_scalar = DAE.T_REAL_DEFAULT "The POW operator. a^b is only defined for integer exponents, i.e. b must
	  be of type Integer" ;
        int_scalar = DAE.T_INTEGER_DEFAULT;
        real_vector = (DAE.T_ARRAY(DAE.DIM_NONE,real_scalar),NONE);
        real_matrix = (DAE.T_ARRAY(DAE.DIM_NONE,real_vector),NONE);
        real_pow = DAE.POW(DAE.ET_REAL());
        int_pow = DAE.POW(DAE.ET_INT());
        scalars = {(int_pow,{int_scalar,int_scalar},int_scalar),
          (real_pow,{real_scalar,real_scalar},real_scalar)};
        arrscalar = {
          (DAE.POW_ARR(DAE.ET_REAL()),{real_matrix,int_scalar},
          real_matrix)};
        types = Util.listFlatten({scalars,arrscalar});
      then
        (cache,types);
    case (cache,Absyn.POW_EW(),env,t1,t2)
      equation
        realarrs = operatorReturn(DAE.POW_ARR2(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
					realarrtypes, realarrtypes, realarrtypes);
        scalars = {
          (DAE.POW(DAE.ET_REAL()),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_REAL_DEFAULT)};
        realscalararrs = operatorReturn(DAE.POW_SCALAR_ARRAY(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
					realtypes, realarrtypes, realarrtypes);
        realarrsscalar = operatorReturn(DAE.POW_ARRAY_SCALAR(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
					realarrtypes, realtypes, realarrtypes);
        types = Util.listFlatten({scalars,realscalararrs,
          realarrsscalar,realarrs});
      then
        (cache,types);

    case (cache,Absyn.UMINUS(),env,t1,t2)
      equation
        scalars = {
          (DAE.UMINUS(DAE.ET_INT()),{DAE.T_INTEGER_DEFAULT},
          DAE.T_INTEGER_DEFAULT),
          (DAE.UMINUS(DAE.ET_REAL()),{DAE.T_REAL_DEFAULT},
          DAE.T_REAL_DEFAULT)} "The UMINUS operator, unary minus" ;
        intarrs = operatorReturnUnary(DAE.UMINUS_ARR(DAE.ET_ARRAY(DAE.ET_INT(), {DAE.DIM_NONE})),
					intarrtypes, intarrtypes);
        realarrs = operatorReturnUnary(DAE.UMINUS_ARR(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
					realarrtypes, realarrtypes);
        types = Util.listFlatten({scalars,intarrs,realarrs});
      then
        (cache,types);
    case (cache,Absyn.UPLUS(),env,t1,t2)
      equation
        scalars = {
          (DAE.UPLUS(DAE.ET_INT()),{DAE.T_INTEGER_DEFAULT},
          DAE.T_INTEGER_DEFAULT),
          (DAE.UPLUS(DAE.ET_REAL()),{DAE.T_REAL_DEFAULT},
          DAE.T_REAL_DEFAULT)} "The UPLUS operator, unary plus." ;
        intarrs = operatorReturnUnary(DAE.UPLUS(DAE.ET_ARRAY(DAE.ET_INT(), {DAE.DIM_NONE})),
					intarrtypes, intarrtypes);
        realarrs = operatorReturnUnary(DAE.UPLUS(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
					realarrtypes, realarrtypes);
        types = Util.listFlatten({scalars,intarrs,realarrs});
      then
        (cache,types);
    case (cache,Absyn.UMINUS_EW(),env,t1,t2)
      equation
        scalars = {
          (DAE.UMINUS(DAE.ET_INT()),{DAE.T_INTEGER_DEFAULT},
          DAE.T_INTEGER_DEFAULT),
          (DAE.UMINUS(DAE.ET_REAL()),{DAE.T_REAL_DEFAULT},
          DAE.T_REAL_DEFAULT)} "The UMINUS operator, unary minus" ;
        intarrs = operatorReturnUnary(DAE.UMINUS_ARR(DAE.ET_ARRAY(DAE.ET_INT(), {DAE.DIM_NONE})),
					intarrtypes, intarrtypes);
        realarrs = operatorReturnUnary(DAE.UMINUS_ARR(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
					realarrtypes, realarrtypes);
        types = Util.listFlatten({scalars,intarrs,realarrs});
      then
        (cache,types);
    case (cache,Absyn.UPLUS_EW(),env,t1,t2)
      equation
        scalars = {
          (DAE.UPLUS(DAE.ET_INT()),{DAE.T_INTEGER_DEFAULT},
          DAE.T_INTEGER_DEFAULT),
          (DAE.UPLUS(DAE.ET_REAL()),{DAE.T_REAL_DEFAULT},
          DAE.T_REAL_DEFAULT)} "The UPLUS operator, unary plus." ;
        intarrs = operatorReturnUnary(DAE.UPLUS(DAE.ET_ARRAY(DAE.ET_INT(), {DAE.DIM_NONE})),
					intarrtypes, intarrtypes);
        realarrs = operatorReturnUnary(DAE.UPLUS(DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_NONE})),
					realarrtypes, realarrtypes);
        types = Util.listFlatten({scalars,intarrs,realarrs});
      then
        (cache,types);
    case (cache,Absyn.AND(),env,t1,t2) then (cache,{
          (DAE.AND(),
          {DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT},DAE.T_BOOL_DEFAULT)});  /* Logical operators Not considered for overloading yet. */
    case (cache,Absyn.OR(),env,t1,t2) then (cache,{
          (DAE.OR(),{DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT},
          DAE.T_BOOL_DEFAULT)});
    case (cache,Absyn.NOT(),env,t1,t2) then (cache,{
          (DAE.NOT(),{DAE.T_BOOL_DEFAULT},DAE.T_BOOL_DEFAULT)});
    case (cache,Absyn.LESS(),env,t1,t2) /* Relational operators */
      equation
        scalars = {
          (DAE.LESS(DAE.ET_INT()),
          {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.LESS(DAE.ET_REAL()),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.LESS(DAE.ET_STRING()),
          {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.LESS(DAE.ET_ENUMERATION(SOME(0),Absyn.IDENT(""),{},{})),{t1,t2},DAE.T_BOOL_DEFAULT)};
        types = Util.listFlatten({scalars});
      then
        (cache,types);
    case (cache,Absyn.LESSEQ(),env,t1,t2)
      equation
        scalars = {
          (DAE.LESSEQ(DAE.ET_INT()),
          {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.LESSEQ(DAE.ET_REAL()),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.LESSEQ(DAE.ET_STRING()),
          {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.LESSEQ(DAE.ET_ENUMERATION(SOME(0),Absyn.IDENT(""),{},{})),{t1,t2},DAE.T_BOOL_DEFAULT)};
        types = Util.listFlatten({scalars});
      then
        (cache,types);
    case (cache,Absyn.GREATER(),env,t1,t2)
      equation
        scalars = {
          (DAE.GREATER(DAE.ET_INT()),
          {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.GREATER(DAE.ET_REAL()),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.GREATER(DAE.ET_STRING()),
          {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.GREATER(DAE.ET_ENUMERATION(SOME(0),Absyn.IDENT(""),{},{})),{t1,t2},DAE.T_BOOL_DEFAULT)};
        types = Util.listFlatten({scalars});
      then
        (cache,types);
    case (cache,Absyn.GREATEREQ(),env,t1,t2)
      equation
        scalars = {
          (DAE.GREATEREQ(DAE.ET_INT()),
          {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.GREATEREQ(DAE.ET_REAL()),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.GREATEREQ(DAE.ET_STRING()),
          {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.GREATEREQ(DAE.ET_ENUMERATION(SOME(0),Absyn.IDENT(""),{},{})),{t1,t2},DAE.T_BOOL_DEFAULT)};

        types = Util.listFlatten({scalars});
      then
        (cache,types);
    case (cache,Absyn.EQUAL(),env,t1,t2)
      equation
        defaultExpType = Util.if_(Types.isBoxedType(t1) and Types.isBoxedType(t2), DAE.ET_BOXED(DAE.ET_OTHER), DAE.ET_ENUMERATION(SOME(0),Absyn.IDENT(""),{},{}));
        scalars = {
          (DAE.EQUAL(DAE.ET_INT()),
          {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.EQUAL(DAE.ET_REAL()),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.EQUAL(DAE.ET_STRING()),
          {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.EQUAL(DAE.ET_BOOL()),
          {DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.EQUAL(DAE.ET_ENUMERATION(SOME(0),Absyn.IDENT(""),{},{})),{t1,t2},DAE.T_BOOL_DEFAULT),
          (DAE.EQUAL(defaultExpType),{t1,t2},DAE.T_BOOL_DEFAULT)};
        types = Util.listFlatten({scalars});
      then
        (cache,types);
    case (cache,Absyn.NEQUAL(),env,t1,t2)
      equation
        defaultExpType = Util.if_(Types.isBoxedType(t1) and Types.isBoxedType(t2), DAE.ET_BOXED(DAE.ET_OTHER), DAE.ET_ENUMERATION(SOME(0),Absyn.IDENT(""),{},{}));
        scalars = {
          (DAE.NEQUAL(DAE.ET_INT()),
          {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.NEQUAL(DAE.ET_REAL()),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.NEQUAL(DAE.ET_STRING()),
          {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.NEQUAL(DAE.ET_BOOL()),
          {DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.NEQUAL(DAE.ET_ENUMERATION(SOME(0),Absyn.IDENT(""),{},{})),{t1,t2},DAE.T_BOOL_DEFAULT),
          (DAE.NEQUAL(defaultExpType),{t1,t2},DAE.T_BOOL_DEFAULT)};
        types = Util.listFlatten({scalars});
      then
        (cache,types);
    case (cache,op,env,t1,t2)
      equation
				true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "-operators failed, op: ");
        s = Dump.opSymbol(op);
        Debug.fprint("failtrace", s);
        Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end operators;

protected function buildOperatorTypes
"function: buildOperatorTypes
  This function takes the types operator overloaded user functions and
  builds  the type list structure suitable for the deoverload function."
  input list<DAE.Type> inTypesTypeLst;
  input Absyn.Path inPath;
  output list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> outTplExpOperatorTypesTypeLstTypesTypeLst;
algorithm
  outTplExpOperatorTypesTypeLstTypesTypeLst:=
  matchcontinue (inTypesTypeLst,inPath)
    local
      list<tuple<DAE.TType, Option<Absyn.Path>>> argtypes,tps;
      list<tuple<DAE.Operator, list<tuple<DAE.TType, Option<Absyn.Path>>>, tuple<DAE.TType, Option<Absyn.Path>>>> rest;
      list<tuple<Ident, tuple<DAE.TType, Option<Absyn.Path>>>> args;
      tuple<DAE.TType, Option<Absyn.Path>> tp;
      Absyn.Path funcname;
    case ({},_) then {};
    case (((DAE.T_FUNCTION(funcArg = args,funcResultType = tp),_) :: tps),funcname)
      equation
        argtypes = Util.listMap(args, Util.tuple22);
        rest = buildOperatorTypes(tps, funcname);
      then
        ((DAE.USERDEFINED(funcname),argtypes,tp) :: rest);
  end matchcontinue;
end buildOperatorTypes;

protected function nDimArray "function: nDimArray
  Returns a type based on the type given as input but as an array type with
  n dimensions.
"
  input Integer inInteger;
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType:=
  matchcontinue (inInteger,inType)
    local
      tuple<DAE.TType, Option<Absyn.Path>> t,t_1;
      Integer n_1,n;
    case (0,t) then t;  /* n orig type array type of n dimensions with element type = orig type */
    case (n,t)
      equation
        n_1 = n - 1;
        t_1 = nDimArray(n_1, t);
      then
        ((DAE.T_ARRAY(DAE.DIM_NONE,t_1),NONE));
  end matchcontinue;
end nDimArray;

protected function nTypes "function: nTypes
  Creates n copies of the type type.
  This could instead be accomplished with Util.list_fill...
"
  input Integer inInteger;
  input DAE.Type inType;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  outTypesTypeLst:=
  matchcontinue (inInteger,inType)
    local
      Integer n_1,n;
      list<tuple<DAE.TType, Option<Absyn.Path>>> l;
      tuple<DAE.TType, Option<Absyn.Path>> t;
    case (0,_) then {};
    case (n,t)
      equation
        n_1 = n - 1;
        l = nTypes(n_1, t);
      then
        (t :: l);
  end matchcontinue;
end nTypes;

protected function operatorReturn "function: operatorReturn
  This function collects the types and operator lists into a tuple list, suitable
  for the deoverloading function for binary operations.
"
  input DAE.Operator inOperator1;
  input list<DAE.Type> inTypesTypeLst2;
  input list<DAE.Type> inTypesTypeLst3;
  input list<DAE.Type> inTypesTypeLst4;
  output list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> outTplExpOperatorTypesTypeLstTypesTypeLst;
algorithm
  outTplExpOperatorTypesTypeLstTypesTypeLst:=
  matchcontinue (inOperator1,inTypesTypeLst2,inTypesTypeLst3,inTypesTypeLst4)
    local
      list<tuple<DAE.Operator, list<tuple<DAE.TType, Option<Absyn.Path>>>, tuple<DAE.TType, Option<Absyn.Path>>>> rest;
      tuple<DAE.Operator, list<tuple<DAE.TType, Option<Absyn.Path>>>, tuple<DAE.TType, Option<Absyn.Path>>> t;
      DAE.Operator op;
      tuple<DAE.TType, Option<Absyn.Path>> l,r,re;
      list<tuple<DAE.TType, Option<Absyn.Path>>> lr,rr,rer;
    case (_,{},{},{}) then {};
    case (op,(l :: lr),(r :: rr),(re :: rer))
      equation
        rest = operatorReturn(op, lr, rr, rer);
        t = (op,{l,r},re) "list contains two types, i.e. BINARY operations" ;
      then
        (t :: rest);
  end matchcontinue;
end operatorReturn;

protected function operatorReturnUnary "function: operatorReturnUnary
  This function collects the types and operator lists into a tuple list,
  suitable for the deoverloading function to be used for unary
  expressions.
"
  input DAE.Operator inOperator1;
  input list<DAE.Type> inTypesTypeLst2;
  input list<DAE.Type> inTypesTypeLst3;
  output list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> outTplExpOperatorTypesTypeLstTypesTypeLst;
algorithm
  outTplExpOperatorTypesTypeLstTypesTypeLst:=
  matchcontinue (inOperator1,inTypesTypeLst2,inTypesTypeLst3)
    local
      list<tuple<DAE.Operator, list<tuple<DAE.TType, Option<Absyn.Path>>>, tuple<DAE.TType, Option<Absyn.Path>>>> rest;
      tuple<DAE.Operator, list<tuple<DAE.TType, Option<Absyn.Path>>>, tuple<DAE.TType, Option<Absyn.Path>>> t;
      DAE.Operator op;
      tuple<DAE.TType, Option<Absyn.Path>> l,re;
      list<tuple<DAE.TType, Option<Absyn.Path>>> lr,rer;
    case (_,{},{}) then {};
    case (op,(l :: lr),(re :: rer))
      equation
        rest = operatorReturnUnary(op, lr, rer);
        t = (op,{l},re) "list only contains one type, i.e. for UNARY operations" ;
      then
        (t :: rest);
  end matchcontinue;
end operatorReturnUnary;

protected function arrayTypeList "function: arrayTypeList
  This function creates a list of types using the original type passed as input, but
  as array types up to n dimensions.
"
  input Integer inInteger;
  input DAE.Type inType;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  outTypesTypeLst:=
  matchcontinue (inInteger,inType)
    local
      Integer n_1,n;
      tuple<DAE.TType, Option<Absyn.Path>> f,t;
      list<tuple<DAE.TType, Option<Absyn.Path>>> r;
    case (0,_) then {};  /* n orig type array types */
    case (n,t)
      equation
        n_1 = n - 1;
        f = nDimArray(n, t);
        r = arrayTypeList(n_1, t);
      then
        (f :: r);
  end matchcontinue;
end arrayTypeList;

protected function warnUnsafeRelations "
Author: BZ, 2008-08
Check if we have real == real, if so give a warning.
"
input DAE.Const variability;
input DAE.Type t1,t2;
input DAE.Exp e1,e2;
input DAE.Operator op;
input Prefix inPrefix;
algorithm _ := matchcontinue(variability,t1,t2,e1,e2,op,inPrefix)
  case(DAE.C_VAR(),t1,t2,e1,e2,op,pre)
    local Boolean b1,b2;
      String stmtString,opString,pre_str;
      Prefix pre;
  equation
    b1 = Types.isReal(t1);
    b2 = Types.isReal(t1);
    true = boolOr(b1,b2);
    verifyOp(op);
    opString = Exp.relopSymbol(op);
    stmtString = Exp.printExpStr(e1) +& opString +& Exp.printExpStr(e2);
    pre_str = PrefixUtil.printPrefixStr3(pre);
    Error.addMessage(Error.WARNING_RELATION_ON_REAL, {pre_str,stmtString,opString});
    then
      ();
  case(_,_,_,_,_,_,_) then ();
end matchcontinue;
end warnUnsafeRelations;

protected function verifyOp "
Helper function for warnUnsafeRelations
We only want to check DAE.EQUAL and EXP.NEQUAL since they are the only illegal real operations.
"
input DAE.Operator op;
algorithm _ := matchcontinue(op)
  case(DAE.EQUAL(_)) then ();
  case(DAE.NEQUAL(_)) then ();
  end matchcontinue;
end verifyOp;

end Static;
