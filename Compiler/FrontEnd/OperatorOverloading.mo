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

encapsulated package OperatorOverloading

public
import Absyn;
import DAE;
import FCore;
import GlobalScript;
import Prefix;
import SCode;
import Util;

protected

import Ceval;
import ClassInf;
import Config;
import Debug;
import Dump;
import Error;
import Expression;
import ExpressionDump;
import ExpressionSimplify;
import FGraph;
import Flags;
import Global;
import Inline;
import List;
import Lookup;
import PrefixUtil;
import SCodeUtil;
import Static;
import Types;
import Values;

public

function binary
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Operator inOperator1;
  input DAE.Properties inProp1;
  input DAE.Exp inExp1;
  input DAE.Properties inProp2;
  input DAE.Exp inExp2;
  input Absyn.Exp AbExp "needed for function replaceOperatorWithFcall (not  really sure what is done in there though.)";
  input Absyn.Exp AbExp1 "We need this when/if we elaborate user defined operator functions";
  input Absyn.Exp AbExp2 "We need this when/if we elaborate user defined operator functions";
  input Boolean inImpl;
  input Option<GlobalScript.SymbolTable> inSymTab;
  input Prefix.Prefix inPre "For error-messages only";
  input SourceInfo inInfo "For error-messages only";
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProp;
algorithm
  (outCache, outExp, outProp) :=
   match (inCache,inEnv,inOperator1, inProp1, inExp1, inProp2, inExp2, AbExp, AbExp1, AbExp2, inImpl, inSymTab, inPre, inInfo)
       local
         FCore.Cache cache;
         FCore.Graph env;
         list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> opList;
         DAE.Type type1,type2, otype;
         DAE.Exp exp1,exp2,exp;
         DAE.Const const1,const2, const;
         DAE.Operator oper;
         Absyn.Operator aboper;
         DAE.Properties prop, props1, props2;
         Absyn.Exp  absexp1, absexp2;
         Boolean lastRound;
         DAE.Dimension n,m1,m2,p;
         DAE.FunctionTree functionTree;
         Boolean didInline;

     // handle tuple op non_tuple
     case (_, _, _, props1 as DAE.PROP_TUPLE(), _, DAE.PROP(), _, _, _, _, _, _, _, _) guard not Config.acceptMetaModelicaGrammar()
       equation
         (prop as DAE.PROP(type1, _)) = Types.propTupleFirstProp(props1);
         exp = DAE.TSUB(inExp1, 1, type1);
         (cache, exp, prop) = binary(inCache, inEnv, inOperator1, prop, exp, inProp2, inExp2, AbExp, AbExp1, AbExp2, inImpl, inSymTab, inPre, inInfo);
       then (cache, exp, prop);

     // handle non_tuple op tuple
     case (_, _, _, DAE.PROP(), _, props2 as DAE.PROP_TUPLE(), _, _, _, _, _, _, _, _) guard not Config.acceptMetaModelicaGrammar()
       equation
         (prop as DAE.PROP(type2, _)) = Types.propTupleFirstProp(props2);
         exp = DAE.TSUB(inExp2, 1, type2);
         (cache, exp, prop) = binary(inCache, inEnv, inOperator1, inProp1, inExp1, prop, exp, AbExp, AbExp1, AbExp2, inImpl, inSymTab, inPre, inInfo);
       then (cache, exp, prop);

     case (cache, env, aboper, DAE.PROP(type1,const1), exp1, DAE.PROP(type2,const2), exp2, _, _, _, _, _, _, _)
       algorithm
         if Types.isRecord(Types.arrayElementType(type1)) or Types.isRecord(Types.arrayElementType(type2)) then
           // Overloaded records
           (cache, exp, _, otype) := binaryUserdef(cache,env,aboper,inExp1,inExp2,type1,type2,inImpl,inSymTab,inPre,inInfo);
           functionTree := FCore.getFunctionTree(cache);
           exp := ExpressionSimplify.simplify1(exp);
           (exp,_,didInline,_) := Inline.inlineExp(exp,(SOME(functionTree),{DAE.BUILTIN_EARLY_INLINE(),DAE.EARLY_INLINE()}),DAE.emptyElementSource);
           exp := ExpressionSimplify.condsimplify(didInline,exp);
           const := Types.constAnd(const1, const2);
           prop := DAE.PROP(otype,const);
         else // Normal operator deoverloading
           if Types.isBoxedType(type1) and Types.isBoxedType(type2) then
             // Do the MetaModelica type-casting here for simplicity
             (exp1, type1) := Types.matchType(exp1, type1, Types.unboxedType(type1), true);
             (exp2, type2) := Types.matchType(exp2, type2, Types.unboxedType(type2), true);
           end if;
           (opList, type1, exp1, type2, exp2) := operatorsBinary(aboper, type1, exp1, type2, exp2);
           (oper, {exp1,exp2}, otype) := deoverload(opList, {(exp1,type1), (exp2,type2)}, AbExp, inPre, inInfo);
           const := Types.constAnd(const1, const2);
           exp := replaceOperatorWithFcall(AbExp, exp1,oper,SOME(exp2), const);
           exp := ExpressionSimplify.simplify(exp);
           prop := DAE.PROP(otype,const);
           warnUnsafeRelations(inEnv,AbExp,const, type1,type2,exp1,exp2,oper,inPre,inInfo);
         end if;
       then (cache, exp, prop);

  end match;
end binary;

function unary
"used to resolve unary operations.

also used to resolve user overloaded unary operators for operator records
It looks if there is an operator function defined for the specific
operation. If there is then it will call that function and returns the
resulting expression. "
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Operator inOperator1;
  input DAE.Properties inProp1;
  input DAE.Exp inExp1;
  input Absyn.Exp AbExp "needed for function replaceOperatorWithFcall (not  really sure what is done in there though.)";
  input Absyn.Exp AbExp1 "We need this when/if we elaborate user defined operator functions";
  input Boolean inImpl;
  input Option<GlobalScript.SymbolTable> inSymTab;
  input Prefix.Prefix inPre "For error-messages only";
  input SourceInfo inInfo "For error-messages only";
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProp;
algorithm
  (outCache, outExp, outProp) :=
   matchcontinue(inCache,inEnv,inOperator1, inProp1, inExp1, AbExp, AbExp1, inImpl, inSymTab, inPre, inInfo)
     local
       String str1;
       FCore.Cache cache;
       list<Absyn.Path> operNames;
       Absyn.Path path;
       FCore.Graph operatorEnv,recordEnv;
       SCode.Element operatorCl;
       list<DAE.Type> types;
       FCore.Graph env;
       list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> opList;
       DAE.Type type1, otype;
       DAE.Exp exp1,exp;
       DAE.Const const;
       DAE.Operator oper;
       Absyn.Operator aboper;
       DAE.Properties prop;
       Absyn.Exp  absexp1;

     // handle op tuple
     case (_, _, _, DAE.PROP_TUPLE(), exp1, _, _, _, _, _, _)
       equation
         false = Config.acceptMetaModelicaGrammar();
         (prop as DAE.PROP(type1, _)) = Types.propTupleFirstProp(inProp1);
         exp = DAE.TSUB(exp1, 1, type1);
         (cache, exp, prop) = unary(inCache, inEnv, inOperator1, prop, exp, AbExp, AbExp1, inImpl, inSymTab, inPre, inInfo);
       then
         (cache, exp, prop);

     case (_, _, aboper, DAE.PROP(type1,const), exp1, _, _, _, _, _, _)
       equation
         false = Types.isRecord(Types.arrayElementType(type1));
         opList = operatorsUnary(aboper);
         (oper, {exp1}, otype) = deoverload(opList, {(exp1,type1)}, AbExp, inPre, inInfo);
         exp = replaceOperatorWithFcall(AbExp, exp1,oper,NONE(), const);
         // (exp,_) = ExpressionSimplify.simplify(exp);
         prop = DAE.PROP(otype,const);
       then
         (inCache,exp, prop);

      // if we have a record check for overloaded operators
      // TODO: Improve this the same way we improved binary operators!
     case(cache, env, aboper, DAE.PROP(type1,_) , _, _, absexp1, _, _, _, _)
       equation

         path = getRecordPath(type1);
         path = Absyn.makeFullyQualified(path);
         (cache,_,recordEnv) = Lookup.lookupClass(cache,env,path, false);

         str1 = "'" + Dump.opSymbolCompact(aboper) + "'";
         path = Absyn.joinPaths(path, Absyn.IDENT(str1));

         (cache,operatorCl,operatorEnv) = Lookup.lookupClass(cache,recordEnv,path, false);
         true = SCode.isOperator(operatorCl);

         operNames = SCodeUtil.getListofQualOperatorFuncsfromOperator(operatorCl);
         (cache,types as _::_) = Lookup.lookupFunctionsListInEnv(cache, operatorEnv, operNames, inInfo, {});

         (cache,SOME((exp,prop))) = Static.elabCallArgs3(cache,env,types,path,{absexp1},{},inImpl,inSymTab,inPre,inInfo);

       then
         (cache,exp,prop);

  end matchcontinue;
end unary;

function string
"This functions checks if the builtin function string is overloaded for opertor records"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp1;
  input Boolean inImpl;
  input Option<GlobalScript.SymbolTable> inSyTabOpt;
  input Boolean inDoVect;
  input Prefix.Prefix inPre;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProp;
  output Option<GlobalScript.SymbolTable> outSyTabOpt;

algorithm

  (outCache,outExp,outProp,outSyTabOpt) :=
  match (inCache, inEnv,inExp1,inImpl,inSyTabOpt,inDoVect,inPre,inInfo)
    local
      String str1;
      Absyn.Path path;
      Option<GlobalScript.SymbolTable> st_1;
      list<Absyn.Path> operNames;
      FCore.Graph recordEnv,operatorEnv,env;
      SCode.Element operatorCl;
      FCore.Cache cache;
      list<DAE.Type> types;
      DAE.Properties prop;
      DAE.Type type1;
      Absyn.Exp exp1;
      DAE.Exp  daeExp;
      list<Absyn.Exp> restargs;
      list<Absyn.NamedArg> nargs;

    case (cache,env,Absyn.CALL(function_ = Absyn.CREF_IDENT("String",_),functionArgs = Absyn.FUNCTIONARGS(args = exp1::restargs,argNames = nargs)),_,_,_,_,_)
      equation
        (cache,_,DAE.PROP(type1,_),st_1) = Static.elabExp(cache,env,exp1,inImpl,inSyTabOpt,inDoVect,inPre,inInfo);

        path = getRecordPath(type1);
        path = Absyn.makeFullyQualified(path);
        (cache,_,recordEnv) = Lookup.lookupClass(cache,env,path, false);

        str1 = "'String'";
        path = Absyn.joinPaths(path, Absyn.IDENT(str1));

        (cache,operatorCl,operatorEnv) = Lookup.lookupClass(cache,recordEnv,path, false);
        true = SCode.isOperator(operatorCl);

        operNames = SCodeUtil.getListofQualOperatorFuncsfromOperator(operatorCl);
        (cache,types as _::_) = Lookup.lookupFunctionsListInEnv(cache, operatorEnv, operNames, inInfo, {});

        (cache,SOME((daeExp,prop))) = Static.elabCallArgs3(cache,env,types,path,exp1::restargs,nargs,inImpl,st_1,inPre,inInfo);
      then
        (cache,daeExp,prop,st_1);

   end match;

end string;

function elabArglist
"Given a list of parameter types and an argument list, this
  function tries to match the two, promoting the type of
  arguments when necessary."
  input list<DAE.Type> inTypes;
  input list<tuple<DAE.Exp, DAE.Type>> inArgs;
  output list<DAE.Exp> outArgs;
  output list<DAE.Type> outTypes;
algorithm
  (outArgs, outTypes) := match(inTypes, inArgs)
    local
      DAE.Exp arg_1,arg;
      DAE.Type atype_1,pt,atype;
      list<DAE.Exp> args_1;
      list<DAE.Type> atypes_1,pts;
      list<tuple<DAE.Exp, DAE.Type>> args;

    // empty lists
    case ({},{}) then ({},{});

    // we have something
    case ((pt :: pts),((arg,atype) :: args))
      equation
        (arg_1,atype_1) = Types.matchType(arg, atype, pt, false);
        (args_1,atypes_1) = elabArglist(pts, args);
      then
        ((arg_1 :: args_1),(atype_1 :: atypes_1));
  end match;
end elabArglist;

protected

/* We have these as constants instead of function calls as done previously
 * because it takes a long time to generate these types over and over again.
 * The types are a bit hard to read, but they are simply 1 through 9-dimensional
 * arrays of the basic types. */
constant list<DAE.Type> intarrtypes = {
  DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 1-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 2-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 3-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 4-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 5-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 6-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 7-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 8-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource) // 9-dim
};
constant list<DAE.Type> realarrtypes = {
  DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 1-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 2-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 3-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 4-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 5-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 6-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 7-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 8-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource) // 9-dim
};
constant list<DAE.Type> boolarrtypes = {
  DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 1-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 2-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 3-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 4-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 5-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 6-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 7-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 8-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource) // 9-dim
};
constant list<DAE.Type> stringarrtypes = {
  DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 1-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 2-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 3-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 4-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 5-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 6-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 7-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 8-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource) // 9-dim
};
/* Simply a list of 9 of that basic type; used to match with the array types */
constant list<DAE.Type> inttypes = {
  DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT
};
constant list<DAE.Type> realtypes = {
  DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT
};
constant list<DAE.Type> stringtypes = {
  DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT
};

function deoverloadBinaryUserdefNoConstructor
  input list<DAE.Type> inTypeList;
  input DAE.Exp inLhs;
  input DAE.Exp inRhs;
  input DAE.Type lhsType;
  input DAE.Type rhsType;
  input list<tuple<DAE.Exp,Option<DAE.Type>>> inAcc;
  output list<tuple<DAE.Exp,Option<DAE.Type>>> outExps;
algorithm
  outExps := matchcontinue (inTypeList,inLhs,inRhs,lhsType,rhsType,inAcc)
      local
        list<DAE.Type> types,scalartypes, arraytypes;
        FCore.Cache cache;
        DAE.Exp daeExp;
        DAE.Properties prop;
        String str1;
        list<DAE.FuncArg> restArgs;
        DAE.Type funcTy,ty,ty1,ty2;
        DAE.FunctionAttributes attr;
        Absyn.Path path;
        DAE.Exp lhs,rhs;
        list<tuple<DAE.Exp,Option<DAE.Type>>> acc;
        tuple<DAE.Exp,Option<DAE.Type>> tpl;

    // Matching types. Yay.
    case ((DAE.T_FUNCTION(source={path},funcResultType=ty,functionAttributes=attr,funcArg=DAE.FUNCARG(ty=ty1)::DAE.FUNCARG(ty=ty2)::restArgs))::types, _, _, _, _, acc)
      equation
        (lhs,_) = Types.matchType(inLhs,lhsType,ty1,false);
        (rhs,_) = Types.matchType(inRhs,rhsType,ty2,false);
        daeExp = makeCallFillRestDefaults(path,{lhs,rhs},restArgs,Types.makeCallAttr(ty,attr));
        tpl = (daeExp,overloadFoldType(ty1,ty2,ty));
        acc = deoverloadBinaryUserdefNoConstructor(types,inLhs,inRhs,lhsType,rhsType,tpl::acc);
      then acc;

    case (_::types, _, _, _, _, _)
      equation
        acc = deoverloadBinaryUserdefNoConstructor(types,inLhs,inRhs,lhsType,rhsType,inAcc);
      then acc;

    case ({}, _, _, _, _, _)
      then inAcc;

  end matchcontinue;
end deoverloadBinaryUserdefNoConstructor;

function overloadFoldType "It is only possible to fold this overloaded function if it has the same inputs and output"
  input DAE.Type inType1;
  input DAE.Type inType2;
  input DAE.Type inType3;
  output Option<DAE.Type> optType;
algorithm
  optType := if Types.equivtypesOrRecordSubtypeOf(inType1,inType2) and Types.equivtypesOrRecordSubtypeOf(inType1,inType3)
    then SOME(inType1) else NONE();
end overloadFoldType;

function deoverloadBinaryUserdefNoConstructorListLhs
  input list<DAE.Type> types;
  input list<DAE.Exp> inLhs;
  input DAE.Exp inRhs;
  input DAE.Type rhsType;
  input list<tuple<DAE.Exp,Option<DAE.Type>>> inAcc;
  output list<tuple<DAE.Exp,Option<DAE.Type>>> outExps;
algorithm
  outExps := match (types,inLhs,inRhs,rhsType,inAcc)
      local
        list<DAE.Type> scalartypes, arraytypes;
        FCore.Cache cache;
        DAE.Properties prop;
        String str1;
        list<DAE.FuncArg> restArgs;
        DAE.Type ty,ty1,ty2;
        DAE.FunctionAttributes attr;
        Absyn.Path path;
        DAE.Exp lhs,rhs;
        list<tuple<DAE.Exp,Option<DAE.Type>>> acc;
        list<DAE.Exp> rest;

    // Matching types. Yay.
    case (_, lhs::rest, _, _, acc)
      equation
        acc = deoverloadBinaryUserdefNoConstructor(types,lhs,inRhs,Expression.typeof(lhs),rhsType,acc);
        acc = deoverloadBinaryUserdefNoConstructorListLhs(types,rest,inRhs,rhsType,acc);
      then acc;

    else inAcc;

  end match;
end deoverloadBinaryUserdefNoConstructorListLhs;

function deoverloadBinaryUserdefNoConstructorListRhs
  input list<DAE.Type> types;
  input DAE.Exp inLhs;
  input list<DAE.Exp> inRhs;
  input DAE.Type lhsType;
  input list<tuple<DAE.Exp,Option<DAE.Type>>> inAcc;
  output list<tuple<DAE.Exp,Option<DAE.Type>>> outExps;
algorithm
  outExps := match (types,inLhs,inRhs,lhsType,inAcc)
      local
        list<DAE.Type> scalartypes, arraytypes;
        FCore.Cache cache;
        DAE.Properties prop;
        String str1;
        list<DAE.FuncArg> restArgs;
        DAE.Type ty,ty1,ty2;
        DAE.FunctionAttributes attr;
        Absyn.Path path;
        DAE.Exp lhs,rhs;
        list<tuple<DAE.Exp,Option<DAE.Type>>> acc;
        list<DAE.Exp> rest;

    // Matching types. Yay.
    case (_, _, rhs::rest, _, acc)
      equation
        acc = deoverloadBinaryUserdefNoConstructor(types,inLhs,rhs,lhsType,Expression.typeof(rhs),acc);
        acc = deoverloadBinaryUserdefNoConstructorListRhs(types,inLhs,rest,lhsType,acc);
      then acc;

    else inAcc;

  end match;
end deoverloadBinaryUserdefNoConstructorListRhs;

function deoverloadUnaryUserdefNoConstructor
  input list<DAE.Type> inTypeList;
  input DAE.Exp inExp;
  input DAE.Type inType;
  input list<DAE.Exp> inAcc;
  output list<DAE.Exp> outExps;
algorithm
  outExps := matchcontinue (inTypeList,inExp,inType,inAcc)
      local
        list<DAE.Type> types,scalartypes, arraytypes;
        FCore.Cache cache;
        DAE.Exp exp,daeExp;
        DAE.Properties prop;
        String str1;
        list<DAE.FuncArg> restArgs;
        DAE.Type ty,ty1,ty2;
        DAE.FunctionAttributes attr;
        Absyn.Path path;
        DAE.Exp lhs,rhs;
        list<DAE.Exp> acc;

    // Matching types. Yay.
    case (DAE.T_FUNCTION(source={path},funcResultType=ty,functionAttributes=attr,funcArg=DAE.FUNCARG(ty=ty1)::restArgs)::types, _, _, acc)
      equation
        (exp,_) = Types.matchType(inExp,inType,ty1,false);
        daeExp = makeCallFillRestDefaults(path,{exp},restArgs,Types.makeCallAttr(ty,attr));
        acc = deoverloadUnaryUserdefNoConstructor(types,inExp,ty,daeExp::acc);
      then acc;

    case (_::types, _, _, _)
      equation
        acc = deoverloadUnaryUserdefNoConstructor(types,inExp,inType,inAcc);
      then acc;

    case ({}, _, _, _)
      then inAcc;

  end matchcontinue;
end deoverloadUnaryUserdefNoConstructor;

function binaryUserdef
"used to resolve overloaded binary operators for operator records
It looks if there is an operator function defined for the specific
operation. If there is then it will call that function and returns the
resulting expression. "
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Operator inOper;
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Type inType1;
  input DAE.Type inType2;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> st;
  input Prefix.Prefix pre;
  input SourceInfo info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output Option<DAE.Type> foldType;
  output DAE.Type outType;
algorithm
  (outCache,outExp,foldType,outType) :=
  match (inCache, inEnv, inOper,inExp1,inExp2,inType1,inType2,impl,st,pre,info)
    local
      Boolean bool1,bool2;
      String opStr;
      Absyn.Path path,path2;
      list<Absyn.Path> operNames;
      FCore.Graph recordEnv,env;
      SCode.Element operatorCl;
      FCore.Cache cache;
      list<DAE.Type> types,types1,types2;
      DAE.Properties prop;
      DAE.Type type1, type2;
      DAE.Exp exp1,exp2;
      Absyn.Operator op;
      Absyn.ComponentRef comRef;
      DAE.Exp  daeExp;
      list<tuple<DAE.Exp,Option<DAE.Type>>> exps;

   case (cache, env, op, exp1, exp2, type1, type2, _, _, _, _)
      equation
        // Step 1 already failed (pre-defined types)
        // Apply operation according to the Specifications.See the function.
        bool1 = Types.arrayType(type1);
        bool2 = Types.arrayType(type2);
        if bool1 and bool2 and Absyn.opIsElementWise(op) then
          types = {};
        else
          opStr = "'" + Dump.opSymbolCompact(op) + "'";
          // print("Try overloading for " + opStr + " " + Types.unparseType(inType1) + "," + Types.unparseType(inType2) + "\n");
          (cache,types1) = getOperatorFuncsOrEmpty(cache,env,{type1},opStr,info,{});
          (cache,types2) = getOperatorFuncsOrEmpty(cache,env,{type2},opStr,info,{});
          // Spec: [...] function f in the union of A.op and B.op [...]
          types = List.union(types1,types2);
          types = List.select1(types, isOperatorBinaryFunctionOrWarn, info);
        end if;
        // Step 2: Look for exactly 1 matching function
        exps = deoverloadBinaryUserdefNoConstructor(types,exp1,exp2,type1,type2,{});
        // Step 3: Look for constructors to call that would have made Step 2 work
        (cache,exps) = binaryCastConstructor(cache,env,inExp1,inExp2,inType1,inType2,exps,types,info);
        (cache,exps) = binaryUserdefArray(cache,env,exps,bool1 or bool2,inOper,inExp1,inExp2,inType1,inType2,impl,st,pre,info);
        {(daeExp,foldType)} = exps;
      then
        (cache,daeExp,foldType,Expression.typeof(daeExp) /*FIXME?*/);

  end match;
end binaryUserdef;

function binaryUserdefArray
  input FCore.Cache inCache;
  input FCore.Graph env;
  input list<tuple<DAE.Exp,Option<DAE.Type>>> inExps;
  input Boolean isArray;
  input Absyn.Operator inOper;
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Type inType1;
  input DAE.Type inType2;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> st;
  input Prefix.Prefix pre;
  input SourceInfo info;
  output FCore.Cache cache;
  output list<tuple<DAE.Exp,Option<DAE.Type>>> exps;
algorithm
  (cache,exps) := match (inCache,env,inExps,isArray,inOper,inExp1,inExp2,inType1,inType2,impl,st,pre,info)
    local
      Boolean isRelation,isLogical,isVector1,isVector2,isScalar1,isScalar2,isMatrix1,isMatrix2;
    // Already found a match
    case (_,_,{_},_,_,_,_,_,_,_,_,_,_) then (inCache,inExps);
    // No match in Step 3; look for array expansions
    case (_,_,{},true,_,_,_,_,_,_,_,_,_)
      equation
        isRelation = listMember(inOper,{Absyn.LESS(),Absyn.LESSEQ(),Absyn.GREATER(),Absyn.GREATEREQ(),Absyn.EQUAL(),Absyn.NEQUAL()});
        Error.assertionOrAddSourceMessage(not isRelation,Error.COMPILER_ERROR,{"Not supporting overloading of relation array operations"},info);
        isScalar1 = not Types.arrayType(inType1);
        isScalar2 = not Types.arrayType(inType2);
        isVector1 = Types.isArray1D(inType1);
        isVector2 = Types.isArray1D(inType2);
        isMatrix1 = Types.isArray2D(inType1);
        isMatrix2 = Types.isArray2D(inType2);
        (cache,exps) = binaryUserdefArray2(inCache,env,isScalar1,isVector1,isMatrix1,isScalar2,isVector2,isMatrix2,
          inOper,inExp1,inExp2,inType1,inType2,impl,st,pre,info);
      then (cache,exps);
      /*
    case (_,{},_,_,_,_,_)
      // Error-message? collect all functions we tried to match? use matchcontinue?
      then fail();
      */
    else
      equation
        errorMultipleValid(List.map(inExps,Util.tuple21),info);
      then fail();
  end match;
end binaryUserdefArray;

function binaryUserdefArray2
  input FCore.Cache inCache;
  input FCore.Graph env;
  input Boolean isScalar1;
  input Boolean isVector1;
  input Boolean isMatrix1;
  input Boolean isScalar2;
  input Boolean isVector2;
  input Boolean isMatrix2;
  input Absyn.Operator inOper;
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Type inType1;
  input DAE.Type inType2;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> st;
  input Prefix.Prefix pre;
  input SourceInfo info;
  output FCore.Cache cache;
  output list<tuple<DAE.Exp,Option<DAE.Type>>> exps;
algorithm
  (cache,exps) := match (inCache,env,isScalar1,isVector1,isMatrix1,isScalar2,isVector2,isMatrix2,inOper,inExp1,inExp2,inType1,inType2,impl,st,pre,info)
    local
      DAE.Exp mulExp,exp,cr,cr1,cr2,cr3,cr4,cr5,cr6,foldExp,transposed;
      DAE.Type newType1,newType2,resType,newType1_1,newType2_1,ty;
      DAE.Dimension dim1,dim2,dim1_1,dim1_2,dim2_1,dim2_2;
      DAE.ReductionIterator iter,iter1,iter2,iter3,iter4;
      String foldName,resultName,foldName1,resultName1,foldName2,resultName2,foldName3,resultName3,foldName4,resultName4,iterName,iterName1,iterName2,iterName3,iterName4;
      Option<Values.Value> zeroConstructor;
      Option<DAE.Type> foldType;
      list<DAE.Type> zeroTypes;
      Absyn.Operator op;
    case (cache,_,false,_,_,true,_,_,_,_,_,_,_,_,_,_,_) // non-scalar op scalar
      equation
        DAE.T_ARRAY(ty=newType1,dims=dim1::{}) = inType1;
        // Not all operators are valid operations
        op = Util.assoc(inOper, {
            (Absyn.ADD_EW(),Absyn.ADD_EW()),
            (Absyn.SUB_EW(),Absyn.SUB_EW()),
            (Absyn.MUL(),Absyn.MUL_EW()),
            (Absyn.MUL_EW(),Absyn.MUL_EW()),
            (Absyn.DIV(),Absyn.DIV_EW()),
            (Absyn.DIV_EW(),Absyn.DIV_EW()),
            (Absyn.POW_EW(),Absyn.POW_EW())
            });
        iterName = Util.getTempVariableIndex();
        foldName = Util.getTempVariableIndex();
        resultName = Util.getTempVariableIndex();
        cr = DAE.CREF(DAE.CREF_IDENT(iterName,newType1,{}),newType1);
        (cache,exp,_,resType) = binaryUserdef(cache,env,op,cr,inExp2,newType1,inType2,impl,st,pre,info);
        resType = Types.liftArray(resType,dim1);
        exp = DAE.REDUCTION(DAE.REDUCTIONINFO(Absyn.IDENT("array"),Absyn.COMBINE(),resType,NONE(),foldName,resultName,NONE()),exp,DAE.REDUCTIONITER(iterName,inExp1,NONE(),newType1)::{});
        // exp = ExpressionSimplify.simplify1(exp);
      then (cache,{(exp,NONE())});
    case (cache,_,true,_,_,false,_,_,_,_,_,_,_,_,_,_,_) // scalar op non-scalar
      equation
        op = Util.assoc(inOper, {
            (Absyn.ADD_EW(),Absyn.ADD_EW()),
            (Absyn.SUB_EW(),Absyn.SUB_EW()),
            (Absyn.MUL(),Absyn.MUL_EW()),
            (Absyn.MUL_EW(),Absyn.MUL_EW()),
            (Absyn.DIV_EW(),Absyn.DIV_EW()),
            (Absyn.POW_EW(),Absyn.POW_EW())
            });
        DAE.T_ARRAY(ty=newType2,dims=dim2::_) = inType2;
        iterName = Util.getTempVariableIndex();
        foldName = Util.getTempVariableIndex();
        resultName = Util.getTempVariableIndex();
        cr = DAE.CREF(DAE.CREF_IDENT(iterName,newType2,{}),newType2);
        (cache,exp,_,resType) = binaryUserdef(cache,env,op,inExp1,cr,inType1,newType2,impl,st,pre,info);
        resType = DAE.T_ARRAY(resType,{dim2},{});
        exp = DAE.REDUCTION(DAE.REDUCTIONINFO(Absyn.IDENT("array"),Absyn.COMBINE(),resType,NONE(),foldName,resultName,NONE()),exp,DAE.REDUCTIONITER(iterName,inExp2,NONE(),newType2)::{});
        // exp = ExpressionSimplify.simplify1(exp);
      then (cache,{(exp,NONE())});
      // '*' invalid operations: vector*vector or vector*matrix
    case (_,_,_,true,_,_,true,_,Absyn.MUL(),_,_,_,_,_,_,_,_) then fail();
    case (_,_,_,true,_,_,_,true,Absyn.MUL(),_,_,_,_,_,_,_,_) then fail();
      // matrix-vector-multiply
    case (cache,_,_,_,true,_,true,_,Absyn.MUL(),_,_,_,_,_,_,_,_)
      equation
        DAE.T_ARRAY(ty=newType1_1,dims=dim1_1::{}) = inType1;
        DAE.T_ARRAY(ty=newType1,dims=dim1_2::{}) = newType1_1;
        DAE.T_ARRAY(ty=newType2,dims=dim2::{}) = inType2;
        true = Expression.dimensionsEqual(dim1_2,dim2);
        // true = Types.equivtypes(newType1,newType2); // Else we cannot sum() the expressions - we need to be able to fold them...
        // print("Got mvm (3)\n");
        // array(sum(a*rhs[b] for a in lhs[:,b]) for b in size(rhs,1))
        // array(sum(a*b for a in c) for c in lhs, b in rhs)

        foldName1 = Util.getTempVariableIndex();
        resultName1 = Util.getTempVariableIndex();
        foldName2 = Util.getTempVariableIndex();
        resultName2 = Util.getTempVariableIndex();
        iterName = Util.getTempVariableIndex();
        iterName1 = Util.getTempVariableIndex();
        iterName2 = Util.getTempVariableIndex();
        cr = DAE.CREF(DAE.CREF_IDENT(iterName,newType1_1,{}),newType1);
        cr1 = DAE.CREF(DAE.CREF_IDENT(iterName1,newType1,{}),newType1);
        cr2 = DAE.CREF(DAE.CREF_IDENT(iterName2,newType2,{}),newType2);
        cr3 = DAE.CREF(DAE.CREF_IDENT(foldName1,newType1,{}),newType1);
        cr4 = DAE.CREF(DAE.CREF_IDENT(resultName1,newType2,{}),newType2);
        // TODO: SUM?
        (cache,exp,SOME(ty),resType) = binaryUserdef(cache,env,Absyn.ADD(),cr1,cr2,newType1,newType2,impl,st,pre,info);
        (cache,foldExp,_,_) = binaryUserdef(cache,env,Absyn.ADD(),cr3,cr4,ty,ty,impl,st,pre,info);
        // TODO: Check that the expression can be folded? Pass it as input to the function, or pass the chosen function as output, or pass the chosen lhs,rhs types as outputs!
        (cache,zeroTypes) = getOperatorFuncsOrEmpty(cache,env,{ty},"'0'",info,{});
        (cache,zeroConstructor) = getZeroConstructor(cache,env,List.filterMap(zeroTypes,getZeroConstructorExpression),impl,st,info);

        resType = DAE.T_ARRAY(resType,{dim1_1},{});
        iter = DAE.REDUCTIONITER(iterName1,cr,NONE(),newType1);
        iter1 = DAE.REDUCTIONITER(iterName,inExp1,NONE(),newType1);
        iter2 = DAE.REDUCTIONITER(iterName2,inExp2,NONE(),newType2);
        exp = DAE.REDUCTION(DAE.REDUCTIONINFO(Absyn.IDENT("sum"),Absyn.THREAD(),resType,zeroConstructor,foldName1,resultName1,SOME(foldExp)),exp,iter::iter2::{});
        exp = DAE.REDUCTION(DAE.REDUCTIONINFO(Absyn.IDENT("array"),Absyn.COMBINE(),resType,NONE(),foldName2,resultName2,NONE()),exp,iter1::{});
      then (cache,{(exp,NONE())});
      // matrix-matrix-multiply
    case (cache,_,_,_,true,_,_,true,Absyn.MUL(),_,_,_,_,_,_,_,_)
      equation
        DAE.T_ARRAY(ty=newType1_1,dims=dim1_1::{}) = inType1;
        DAE.T_ARRAY(ty=newType1,dims=dim1_2::{}) = newType1_1;
        DAE.T_ARRAY(ty=newType2_1,dims=dim2_1::{}) = inType2;
        DAE.T_ARRAY(ty=newType2,dims=dim2_2::{}) = newType2_1;
        true = Expression.dimensionsEqual(dim1_2,dim2_1);
        transposed = Expression.makePureBuiltinCall("transpose",{inExp2},Types.liftArray(Types.liftArray(newType2,dim2_1),dim2_2));
        iterName1 = Util.getTempVariableIndex();
        iterName2 = Util.getTempVariableIndex();
        iterName3 = Util.getTempVariableIndex();
        iterName4 = Util.getTempVariableIndex();
        foldName1 = Util.getTempVariableIndex();
        resultName1 = Util.getTempVariableIndex();
        foldName2 = Util.getTempVariableIndex();
        resultName2 = Util.getTempVariableIndex();
        foldName = Util.getTempVariableIndex();
        resultName = Util.getTempVariableIndex();
        cr1 = DAE.CREF(DAE.CREF_IDENT(iterName1,newType1_1,{}),newType1_1);
        cr2 = DAE.CREF(DAE.CREF_IDENT(iterName2,newType2_1,{}),newType2_1);
        cr3 = DAE.CREF(DAE.CREF_IDENT(iterName3,newType1,{}),newType1);
        cr4 = DAE.CREF(DAE.CREF_IDENT(iterName4,newType2,{}),newType2);

        (cache,mulExp,_,ty) = binaryUserdef(cache,env,Absyn.MUL(),cr3,cr4,newType1,newType2,impl,st,pre,info);
        cr5 = DAE.CREF(DAE.CREF_IDENT(foldName,ty,{}),ty);
        cr6 = DAE.CREF(DAE.CREF_IDENT(resultName,ty,{}),ty);
        (cache,foldExp,SOME(ty),_) = binaryUserdef(cache,env,Absyn.ADD(),cr5,cr6,ty,ty,impl,st,pre,info);
        (cache,zeroTypes) = getOperatorFuncsOrEmpty(cache,env,{ty},"'0'",info,{});
        (cache,zeroConstructor) = getZeroConstructor(cache,env,List.filterMap(zeroTypes,getZeroConstructorExpression),impl,st,info);

        iter1 = DAE.REDUCTIONITER(iterName1,inExp1,NONE(),newType1_1);
        iter2 = DAE.REDUCTIONITER(iterName2,transposed,NONE(),newType2_1);
        iter3 = DAE.REDUCTIONITER(iterName3,cr1,NONE(),newType1_1);
        iter4 = DAE.REDUCTIONITER(iterName4,cr2,NONE(),newType2_1);

        exp = DAE.REDUCTION(DAE.REDUCTIONINFO(Absyn.IDENT("sum"),Absyn.THREAD(),ty,zeroConstructor,foldName,resultName,SOME(foldExp)),mulExp,iter3::iter4::{});
        ty = Types.liftArray(ty,dim2_2);
        exp = DAE.REDUCTION(DAE.REDUCTIONINFO(Absyn.IDENT("array"),Absyn.COMBINE(),ty,NONE(),foldName2,resultName2,NONE()),exp,iter2::{});
        ty = Types.liftArray(ty,dim1_1);
        exp = DAE.REDUCTION(DAE.REDUCTIONINFO(Absyn.IDENT("array"),Absyn.COMBINE(),ty,NONE(),foldName1,resultName1,NONE()),exp,iter1::{});
      then (cache,{(exp,NONE())});
      // The rest are array op array, which are element-wise operations
      // We thus change the operator to the element-wise one to avoid other vector operations than this one
    case (cache,_,false,_,_,false,_,_,_,_,_,_,_,_,_,_,_) // array op array, 1-D through n-D
      equation
        op = Util.assoc(inOper, {
            (Absyn.ADD(),Absyn.ADD_EW()),
            (Absyn.ADD_EW(),Absyn.ADD_EW()),
            (Absyn.SUB(),Absyn.SUB_EW()),
            (Absyn.SUB_EW(),Absyn.SUB_EW()),
            (Absyn.MUL_EW(),Absyn.MUL_EW()),
            (Absyn.DIV_EW(),Absyn.DIV_EW()),
            (Absyn.POW_EW(),Absyn.POW_EW()),
            (Absyn.AND(),Absyn.AND()),
            (Absyn.OR(),Absyn.OR())
            });
        DAE.T_ARRAY(ty=newType1,dims=dim1::{}) = inType1;
        DAE.T_ARRAY(ty=newType2,dims=dim2::{}) = inType2;
        true = Expression.dimensionsEqual(dim1,dim2);
        foldName = Util.getTempVariableIndex();
        resultName = Util.getTempVariableIndex();
        iterName1 = Util.getTempVariableIndex();
        iterName2 = Util.getTempVariableIndex();
        cr1 = DAE.CREF(DAE.CREF_IDENT(iterName1,newType1,{}),newType1);
        cr2 = DAE.CREF(DAE.CREF_IDENT(iterName2,newType2,{}),newType2);
        (cache,exp,_,resType) = binaryUserdef(cache,env,op,cr1,cr2,newType1,newType2,impl,st,pre,info);
        resType = DAE.T_ARRAY(resType,{dim2},{});
        iter1 = DAE.REDUCTIONITER(iterName1,inExp1,NONE(),newType1);
        iter2 = DAE.REDUCTIONITER(iterName2,inExp2,NONE(),newType2);
        exp = DAE.REDUCTION(DAE.REDUCTIONINFO(Absyn.IDENT("array"),Absyn.THREAD(),resType,NONE(),foldName,resultName,NONE()),exp,iter1::iter2::{});
      then (cache,{(exp,NONE())});
  end match;
end binaryUserdefArray2;

function operatorsBinary "This function relates the operators in the abstract syntax to the
  de-overloaded operators in the SCode. It produces a list of available
  types for a specific operator, that the overload function chooses from.
  Therefore, in order for the builtin type conversion from Integer to
  Real to work, operators that work on both Integers and Reals must
  return the Integer type -before- the Real type in the list."
  input Absyn.Operator inOperator1;
  input DAE.Type inType3;
  input DAE.Exp inE1;
  input DAE.Type inType4;
  input DAE.Exp inE2;
  output list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> ops;
  output DAE.Type oty1;
  output DAE.Exp oe1;
  output DAE.Type oty2;
  output DAE.Exp oe2;
algorithm
  (ops,oty1,oe1,oty2,oe2) :=
  matchcontinue (inOperator1,inType3,inE1,inType4,inE2)
    local
      list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> intarrs,realarrs,boolarrs,stringarrs,scalars,arrays,types,scalarprod,matrixprod,intscalararrs,realscalararrs,intarrsscalar,realarrsscalar,realarrscalar,arrscalar,stringarrsscalar;
      tuple<DAE.Operator, list<DAE.Type>, DAE.Type> enum_op;
      DAE.Type t1,t2,int_scalar,int_vector,int_matrix,real_scalar,real_vector,real_matrix;
      DAE.Operator int_mul,real_mul,int_mul_sp,real_mul_sp,int_mul_mp,real_mul_mp,real_div,real_pow;
      Absyn.Operator op;
      DAE.Exp e1,e2;

    // arithmetical operators
    case (Absyn.ADD(),t1,e1,t2,e2)
      equation
        intarrs = operatorReturn(DAE.ADD_ARR(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                    intarrtypes, intarrtypes, intarrtypes);
        realarrs = operatorReturn(DAE.ADD_ARR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                     realarrtypes, realarrtypes, realarrtypes);
        stringarrs = operatorReturn(DAE.ADD_ARR(DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                       stringarrtypes, stringarrtypes, stringarrtypes);
        scalars = {
          (DAE.ADD(DAE.T_INTEGER_DEFAULT),
          {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_INTEGER_DEFAULT),
          (DAE.ADD(DAE.T_REAL_DEFAULT),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_REAL_DEFAULT),
          (DAE.ADD(DAE.T_STRING_DEFAULT),
          {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_STRING_DEFAULT)};
        arrays = List.flatten({intarrs,realarrs,stringarrs});
        types = List.flatten({scalars,arrays});
      then
        (types,t1,e1,t2,e2);

    // arithmetical element wise operators
    case (Absyn.ADD_EW(),t1,e1,t2,e2)
      equation
        false = Types.isArray(t2) and (not Types.isArray(t1));
        intarrs = operatorReturn(DAE.ADD_ARR(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                    intarrtypes, intarrtypes, intarrtypes);
        realarrs = operatorReturn(DAE.ADD_ARR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                     realarrtypes, realarrtypes, realarrtypes);
        stringarrs = operatorReturn(DAE.ADD_ARR(DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                       stringarrtypes, stringarrtypes, stringarrtypes);
        scalars = {
          (DAE.ADD(DAE.T_INTEGER_DEFAULT),
          {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_INTEGER_DEFAULT),
          (DAE.ADD(DAE.T_REAL_DEFAULT),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_REAL_DEFAULT),
          (DAE.ADD(DAE.T_STRING_DEFAULT),
          {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_STRING_DEFAULT)};
        intarrsscalar = operatorReturn(DAE.ADD_ARRAY_SCALAR(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                          intarrtypes, inttypes, intarrtypes);
        realarrsscalar = operatorReturn(DAE.ADD_ARRAY_SCALAR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                           realarrtypes, realtypes, realarrtypes);
        stringarrsscalar = operatorReturn(DAE.ADD_ARRAY_SCALAR(DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                             stringarrtypes, stringtypes, stringarrtypes);
        types = List.flatten({scalars,intarrsscalar,realarrsscalar,stringarrsscalar,intarrs,realarrs,stringarrs});
      then
        (types,t1,e1,t2,e2);

    // arithmetical operators
    case (Absyn.SUB(),t1,e1,t2,e2)
      equation
        intarrs = operatorReturn(DAE.SUB_ARR(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                    intarrtypes, intarrtypes, intarrtypes);
        realarrs = operatorReturn(DAE.SUB_ARR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                     realarrtypes, realarrtypes, realarrtypes);
        scalars = {
          (DAE.SUB(DAE.T_INTEGER_DEFAULT),
          {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_INTEGER_DEFAULT),
          (DAE.SUB(DAE.T_REAL_DEFAULT),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_REAL_DEFAULT)};
        types = List.flatten({scalars,intarrs,realarrs});
      then
        (types,t1,e1,t2,e2);

    // arithmetical element wise operators
    case (Absyn.SUB_EW(),t1,e1,t2,e2)
      equation
        false = Types.isArray(t1) and (not Types.isArray(t2));
        intarrs = operatorReturn(DAE.SUB_ARR(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                    intarrtypes, intarrtypes, intarrtypes);
        realarrs = operatorReturn(DAE.SUB_ARR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                     realarrtypes, realarrtypes, realarrtypes);
        scalars = {
          (DAE.SUB(DAE.T_INTEGER_DEFAULT),
          {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_INTEGER_DEFAULT),
          (DAE.SUB(DAE.T_REAL_DEFAULT),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_REAL_DEFAULT)};
        intscalararrs = operatorReturn(DAE.SUB_SCALAR_ARRAY(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                          inttypes, intarrtypes, intarrtypes);
        realscalararrs = operatorReturn(DAE.SUB_SCALAR_ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                           realtypes, realarrtypes, realarrtypes);
        types = List.flatten({scalars,intscalararrs,realscalararrs,intarrs,realarrs});
      then
        (types,t1,e1,t2,e2);

    case (Absyn.MUL(),t1,e1,t2,e2)
      equation
        false = Types.isArray(t2) and (not Types.isArray(t1));
        int_mul = DAE.MUL(DAE.T_INTEGER_DEFAULT);
        real_mul = DAE.MUL(DAE.T_REAL_DEFAULT);
        int_mul_sp = DAE.MUL_SCALAR_PRODUCT(DAE.T_INTEGER_DEFAULT);
        real_mul_sp = DAE.MUL_SCALAR_PRODUCT(DAE.T_REAL_DEFAULT);
        int_mul_mp = DAE.MUL_MATRIX_PRODUCT(DAE.T_INTEGER_DEFAULT);
        real_mul_mp = DAE.MUL_MATRIX_PRODUCT(DAE.T_REAL_DEFAULT);
        int_scalar = DAE.T_INTEGER_DEFAULT;
        int_vector = DAE.T_ARRAY(int_scalar,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource);
        int_matrix = DAE.T_ARRAY(int_vector,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource);
        real_scalar = DAE.T_REAL_DEFAULT;
        real_vector = DAE.T_ARRAY(real_scalar,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource);
        real_matrix = DAE.T_ARRAY(real_vector,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource);
        scalars = {(int_mul,{int_scalar,int_scalar},int_scalar),
          (real_mul,{real_scalar,real_scalar},real_scalar)};
        scalarprod = {(int_mul_sp,{int_vector,int_vector},int_scalar),
          (real_mul_sp,{real_vector,real_vector},real_scalar)};
        matrixprod = {(int_mul_mp,{int_vector,int_matrix},int_vector),
          (int_mul_mp,{int_matrix,int_vector},int_vector),(int_mul_mp,{int_matrix,int_matrix},int_matrix),
          (real_mul_mp,{real_vector,real_matrix},real_vector),(real_mul_mp,{real_matrix,real_vector},real_vector),
          (real_mul_mp,{real_matrix,real_matrix},real_matrix)};
        intarrsscalar = operatorReturn(DAE.MUL_ARRAY_SCALAR(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                          intarrtypes, inttypes, intarrtypes);
        realarrsscalar = operatorReturn(DAE.MUL_ARRAY_SCALAR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                           realarrtypes, realtypes, realarrtypes);
        types = List.flatten({scalars,intarrsscalar,realarrsscalar,scalarprod,matrixprod});
      then
        (types,t1,e1,t2,e2);

    case (Absyn.MUL_EW(),t1,e1,t2,e2) /* Arithmetical operators */
      equation
        false = Types.isArray(t2) and (not Types.isArray(t1));
        intarrs = operatorReturn(DAE.MUL_ARR(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          intarrtypes, intarrtypes, intarrtypes);
        realarrs = operatorReturn(DAE.MUL_ARR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          realarrtypes, realarrtypes, realarrtypes);
        scalars = {
          (DAE.MUL(DAE.T_INTEGER_DEFAULT),
          {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_INTEGER_DEFAULT),
          (DAE.MUL(DAE.T_REAL_DEFAULT),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_REAL_DEFAULT)};
        intarrsscalar = operatorReturn(DAE.MUL_ARRAY_SCALAR(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          intarrtypes, inttypes, intarrtypes);
        realarrsscalar = operatorReturn(DAE.MUL_ARRAY_SCALAR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          realarrtypes, realtypes, realarrtypes);
        types = List.flatten({scalars,intarrsscalar,realarrsscalar,intarrs,realarrs});
      then
        (types,t1,e1,t2,e2);

    case (Absyn.DIV(),t1,e1,t2,e2)
      equation
        real_div = DAE.DIV(DAE.T_REAL_DEFAULT);
        real_scalar = DAE.T_REAL_DEFAULT;
        scalars = {(real_div,{real_scalar,real_scalar},real_scalar)};
        realarrscalar = operatorReturn(DAE.DIV_ARRAY_SCALAR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          realarrtypes, realtypes, realarrtypes);
        types = List.flatten({scalars,realarrscalar});
      then
        (types,t1,e1,t2,e2);

    case (Absyn.DIV_EW(),t1,e1,t2,e2) /* Arithmetical operators */
      equation
        realarrs = operatorReturn(DAE.DIV_ARR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          realarrtypes, realarrtypes, realarrtypes);
        scalars = {
          (DAE.DIV(DAE.T_REAL_DEFAULT),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_REAL_DEFAULT)};
        realscalararrs = operatorReturn(DAE.DIV_SCALAR_ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          realtypes, realarrtypes, realarrtypes);
        realarrsscalar = operatorReturn(DAE.DIV_ARRAY_SCALAR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          realarrtypes, realtypes, realarrtypes);
        types = List.flatten({scalars,realscalararrs,
          realarrsscalar,realarrs});
      then
        (types,t1,e1,t2,e2);

    case (Absyn.POW(),t1,e1,t2,e2)
      equation
        // Note: POW_ARR uses Integer exponents, while POW only uses Real exponents
        real_scalar = DAE.T_REAL_DEFAULT;
        int_scalar = DAE.T_INTEGER_DEFAULT;
        real_vector = DAE.T_ARRAY(real_scalar,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource);
        real_matrix = DAE.T_ARRAY(real_vector,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource);
        real_pow = DAE.POW(DAE.T_REAL_DEFAULT);
        scalars = {(real_pow,{real_scalar,real_scalar},real_scalar)};
        arrscalar = {
          (DAE.POW_ARR(DAE.T_REAL_DEFAULT),{real_matrix,int_scalar},
          real_matrix)};
        types = List.flatten({scalars,arrscalar});
      then
        (types,t1,e1,t2,e2);

    case (Absyn.POW_EW(),t1,e1,t2,e2)
      equation
        realarrs = operatorReturn(DAE.POW_ARR2(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          realarrtypes, realarrtypes, realarrtypes);
        scalars = {
          (DAE.POW(DAE.T_REAL_DEFAULT),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_REAL_DEFAULT)};
        realscalararrs = operatorReturn(DAE.POW_SCALAR_ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          realtypes, realarrtypes, realarrtypes);
        realarrsscalar = operatorReturn(DAE.POW_ARRAY_SCALAR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          realarrtypes, realtypes, realarrtypes);
        types = List.flatten({scalars,realscalararrs,
          realarrsscalar,realarrs});
      then
        (types,t1,e1,t2,e2);

    case (Absyn.AND(), t1, e1, t2, e2)
      equation
        scalars = {(DAE.AND(DAE.T_BOOL_DEFAULT), {DAE.T_BOOL_DEFAULT, DAE.T_BOOL_DEFAULT}, DAE.T_BOOL_DEFAULT)};
        boolarrs = operatorReturn(DAE.AND(DAE.T_BOOL_DEFAULT), boolarrtypes, boolarrtypes, boolarrtypes);
        types = List.flatten({scalars, boolarrs});
      then (types,t1,e1,t2,e2);

    case (Absyn.OR(), t1, e1, t2, e2)
      equation
        scalars = {(DAE.OR(DAE.T_BOOL_DEFAULT), {DAE.T_BOOL_DEFAULT, DAE.T_BOOL_DEFAULT}, DAE.T_BOOL_DEFAULT)};
        boolarrs = operatorReturn(DAE.OR(DAE.T_BOOL_DEFAULT), boolarrtypes, boolarrtypes, boolarrtypes);
        types = List.flatten({scalars, boolarrs});
      then (types,t1,e1,t2,e2);

    // Relational operators
    case (Absyn.LESS(),t1,e1,t2,e2)
      equation
        enum_op = makeEnumOperator(DAE.LESS(DAE.T_ENUMERATION_DEFAULT), t1, t2);
        scalars = {
          (DAE.LESS(DAE.T_INTEGER_DEFAULT),
            {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_BOOL_DEFAULT),
          enum_op,
          (DAE.LESS(DAE.T_REAL_DEFAULT),
            {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.LESS(DAE.T_BOOL_DEFAULT),
            {DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.LESS(DAE.T_STRING_DEFAULT),
            {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_BOOL_DEFAULT)};
        types = List.flatten({scalars});
      then (types,t1,e1,t2,e2);

    case (Absyn.LESSEQ(),t1,e1,t2,e2)
      equation
        enum_op = makeEnumOperator(DAE.LESSEQ(DAE.T_ENUMERATION_DEFAULT), t1, t2);
        scalars = {
          (DAE.LESSEQ(DAE.T_INTEGER_DEFAULT),
            {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_BOOL_DEFAULT),
          enum_op,
          (DAE.LESSEQ(DAE.T_REAL_DEFAULT),
            {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.LESSEQ(DAE.T_BOOL_DEFAULT),
            {DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.LESSEQ(DAE.T_STRING_DEFAULT),
            {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_BOOL_DEFAULT)};
        types = List.flatten({scalars});
      then (types,t1,e1,t2,e2);

    case (Absyn.GREATER(),t1,e1,t2,e2)
      equation
        enum_op = makeEnumOperator(DAE.GREATER(DAE.T_ENUMERATION_DEFAULT), t1, t2);
        scalars = {
          (DAE.GREATER(DAE.T_INTEGER_DEFAULT),
            {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_BOOL_DEFAULT),
          enum_op,
          (DAE.GREATER(DAE.T_REAL_DEFAULT),
            {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.GREATER(DAE.T_BOOL_DEFAULT),
            {DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.GREATER(DAE.T_STRING_DEFAULT),
            {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_BOOL_DEFAULT)};
        types = List.flatten({scalars});
      then (types,t1,e1,t2,e2);

    case (Absyn.GREATEREQ(),t1,e1,t2,e2)
      equation
        enum_op = makeEnumOperator(DAE.GREATEREQ(DAE.T_ENUMERATION_DEFAULT), t1, t2);
        scalars = {
          (DAE.GREATEREQ(DAE.T_INTEGER_DEFAULT),
            {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_BOOL_DEFAULT),
          enum_op,
          (DAE.GREATEREQ(DAE.T_REAL_DEFAULT),
            {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.GREATEREQ(DAE.T_BOOL_DEFAULT),
            {DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.GREATEREQ(DAE.T_STRING_DEFAULT),
            {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_BOOL_DEFAULT)};
        types = List.flatten({scalars});
      then (types,t1,e1,t2,e2);

    case (Absyn.EQUAL(),t1,e1,t2,e2)
      equation
        enum_op = makeEnumOperator(DAE.EQUAL(DAE.T_ENUMERATION_DEFAULT), t1, t2);
        types =
          (DAE.EQUAL(DAE.T_INTEGER_DEFAULT),
            {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_BOOL_DEFAULT)::
          enum_op::
          (DAE.EQUAL(DAE.T_REAL_DEFAULT),
            {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_BOOL_DEFAULT)::
          (DAE.EQUAL(DAE.T_STRING_DEFAULT),
            {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_BOOL_DEFAULT)::
          (DAE.EQUAL(DAE.T_BOOL_DEFAULT),
            {DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT},DAE.T_BOOL_DEFAULT)::
          {};
      then
        (types,t1,e1,t2,e2);

    case (Absyn.NEQUAL(),t1,e1,t2,e2)
      equation
        enum_op = makeEnumOperator(DAE.NEQUAL(DAE.T_ENUMERATION_DEFAULT), t1, t2);
        types =
          (DAE.NEQUAL(DAE.T_INTEGER_DEFAULT),
            {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_BOOL_DEFAULT)::
          enum_op::
          (DAE.NEQUAL(DAE.T_REAL_DEFAULT),
            {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_BOOL_DEFAULT)::
          (DAE.NEQUAL(DAE.T_STRING_DEFAULT),
            {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_BOOL_DEFAULT)::
          (DAE.NEQUAL(DAE.T_BOOL_DEFAULT),
            {DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT},DAE.T_BOOL_DEFAULT)::
          {};
      then
        (types,t1,e1,t2,e2);

    // element-wise equivalent operators
    case (Absyn.ADD_EW(),t1,e1,t2,e2)
      equation
        true = Types.isArray(t2) and (not Types.isArray(t1));
        (types,t1,e1,t2,e2) = operatorsBinary(Absyn.ADD_EW(),t2,e2,t1,e1);
      then (types,t1,e1,t2,e2);

    case (Absyn.SUB_EW(),t1,e1,t2,e2)
      equation
        true = Types.isArray(t1) and (not Types.isArray(t2));
        e2 = Expression.negate(e2);
        (types,t1,e1,t2,e2) = operatorsBinary(Absyn.ADD_EW(),t1,e1,t2,e2);
      then (types,t1,e1,t2,e2);

    case (Absyn.MUL(),t1,e1,t2,e2)
      equation
        true = Types.isArray(t2) and (not Types.isArray(t1));
        (types,t1,e1,t2,e2) = operatorsBinary(Absyn.MUL(),t2,e2,t1,e1);
      then (types,t1,e1,t2,e2);

    case (Absyn.MUL_EW(),t1,e1,t2,e2)
      equation
        true = Types.isArray(t2) and (not Types.isArray(t1));
        (types,t1,e1,t2,e2) = operatorsBinary(Absyn.MUL_EW(),t2,e2,t1,e1);
      then (types,t1,e1,t2,e2);

    case (op,_,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("OperatorOverloading.operatorsBinary failed, op: " + Dump.opSymbol(op));
      then
        fail();
  end matchcontinue;
end operatorsBinary;

function operatorsUnary "This function relates the operators in the abstract syntax to the
  de-overloaded operators in the SCode. It produces a list of available
  types for a specific operator, that the overload function chooses from.
  Therefore, in order for the builtin type conversion from Integer to
  Real to work, operators that work on both Integers and Reals must
  return the Integer type -before- the Real type in the list."
  input Absyn.Operator op;
  output list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> ops;
algorithm
  ops := match op
    local
      list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> intarrs,realarrs,boolarrs,scalars,types;

    case Absyn.UMINUS()
      equation
        scalars = {
          (DAE.UMINUS(DAE.T_INTEGER_DEFAULT),{DAE.T_INTEGER_DEFAULT},
          DAE.T_INTEGER_DEFAULT),
          (DAE.UMINUS(DAE.T_REAL_DEFAULT),{DAE.T_REAL_DEFAULT},
          DAE.T_REAL_DEFAULT)} "The UMINUS operator, unary minus" ;
        intarrs = operatorReturnUnary(DAE.UMINUS_ARR(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          intarrtypes, intarrtypes);
        realarrs = operatorReturnUnary(DAE.UMINUS_ARR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          realarrtypes, realarrtypes);
        types = List.flatten({scalars,intarrs,realarrs});
      then types;

    case Absyn.NOT()
      equation
        scalars = {(DAE.NOT(DAE.T_BOOL_DEFAULT), {DAE.T_BOOL_DEFAULT}, DAE.T_BOOL_DEFAULT)};
        boolarrs = operatorReturnUnary(DAE.NOT(DAE.T_BOOL_DEFAULT), boolarrtypes, boolarrtypes);
        types = List.flatten({scalars, boolarrs});
      then types;

    case _
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("OperatorOverloading.operatorsUnary failed, op: " + Dump.opSymbol(op));
      then fail();
  end match;
end operatorsUnary;

function makeEnumOperator
  "Used by operators to create an operator with enumeration type. It sets the
  correct expected type of the operator, so that for example integer=>enum type
  casts work correctly without matching things that it shouldn't match."
  input DAE.Operator inOp;
  input DAE.Type inType1;
  input DAE.Type inType2;
  output tuple<DAE.Operator, list<DAE.Type>, DAE.Type> outOp;
algorithm
  outOp := matchcontinue(inOp, inType1, inType2)
    local
      DAE.Type op_ty;
      DAE.Operator op;

    case (_, DAE.T_ENUMERATION(), DAE.T_ENUMERATION())
      equation
        op_ty = Types.simplifyType(inType1);
        op = Expression.setOpType(inOp, op_ty);
      then ((op, {inType1, inType2}, DAE.T_BOOL_DEFAULT));

    case (_, DAE.T_ENUMERATION(), _)
      equation
        op_ty = Types.simplifyType(inType1);
        op = Expression.setOpType(inOp, op_ty);
      then
        ((op, {inType1, inType1}, DAE.T_BOOL_DEFAULT));

    case (_, _, DAE.T_ENUMERATION())
      equation
        op_ty = Types.simplifyType(inType1);
        op = Expression.setOpType(inOp, op_ty);
      then
        ((op, {inType1, inType2}, DAE.T_BOOL_DEFAULT));

    else
      then ((inOp, {DAE.T_ENUMERATION_DEFAULT, DAE.T_ENUMERATION_DEFAULT}, DAE.T_BOOL_DEFAULT));
  end matchcontinue;
end makeEnumOperator;

function buildOperatorTypes
"This function takes the types operator overloaded user functions and
  builds  the type list structure suitable for the deoverload function."
  input list<DAE.Type> inTypes;
  input Absyn.Path inPath;
  output list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> outOperatorTypes;
algorithm
  outOperatorTypes := match (inTypes, inPath)
    local
      list<DAE.Type> argtypes,tps;
      list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> rest;
      list<DAE.FuncArg> args;
      DAE.Type tp;
      Absyn.Path funcname;
    case ({},_) then {};
    case (DAE.T_FUNCTION(funcArg = args,funcResultType = tp) :: tps,funcname)
      equation
        argtypes = List.map(args, Types.funcArgType);
        rest = buildOperatorTypes(tps, funcname);
      then
        ((DAE.USERDEFINED(funcname),argtypes,tp) :: rest);
  end match;
end buildOperatorTypes;

function operatorReturn "This function collects the types and operator lists into a tuple list, suitable
  for the deoverloading function for binary operations."
  input DAE.Operator inOperator;
  input list<DAE.Type> inLhsTypes;
  input list<DAE.Type> inRhsTypes;
  input list<DAE.Type> inReturnTypes;
  output list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> outOperators;
algorithm
  outOperators := match(inOperator, inLhsTypes, inRhsTypes, inReturnTypes)
    local
      list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> rest;
      tuple<DAE.Operator, list<DAE.Type>, DAE.Type> t;
      DAE.Operator op;
      DAE.Type l,r,re;
      list<DAE.Type> lr,rr,rer;
    case (_,{},{},{}) then {};
    case (op,(l :: lr),(r :: rr),(re :: rer))
      equation
        rest = operatorReturn(op, lr, rr, rer);
        t = (op,{l,r},re) "list contains two types, i.e. BINARY operations" ;
      then
        (t :: rest);
  end match;
end operatorReturn;

function operatorReturnUnary "This function collects the types and operator lists into a tuple list,
  suitable for the deoverloading function to be used for unary
  expressions."
  input DAE.Operator inOperator;
  input list<DAE.Type> inArgTypes;
  input list<DAE.Type> inReturnTypes;
  output list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> outOperators;
algorithm
  outOperators := match(inOperator, inArgTypes, inReturnTypes)
    local
      list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> rest;
      tuple<DAE.Operator, list<DAE.Type>, DAE.Type> t;
      DAE.Operator op;
      DAE.Type l,re;
      list<DAE.Type> lr,rer;
    case (_,{},{}) then {};
    case (op,(l :: lr),(re :: rer))
      equation
        rest = operatorReturnUnary(op, lr, rer);
        t = (op,{l},re) "list only contains one type, i.e. for UNARY operations" ;
      then
        (t :: rest);
  end match;
end operatorReturnUnary;

function getOperatorFuncsOrEmpty
  input FCore.Cache inCache;
  input FCore.Graph env;
  input list<DAE.Type> tys;
  input String opName;
  input SourceInfo info;
  input list<DAE.Type> acc;
  output FCore.Cache cache;
  output list<DAE.Type> funcs;
algorithm
  (cache,funcs) := matchcontinue (inCache,env,tys,opName,info,acc)
    local
      Absyn.Path path,opNamePath;
      SCode.Element operatorCl;
      FCore.Graph recordEnv,operEnv;
      list<Absyn.Path> paths;
      DAE.Type ty,scalarType;
      list<DAE.Type> rest;
    case (cache,_,ty::rest,_,_,_)
      equation
        // prepare the call path for the operator.
        // if *   => recordPath.'*'  , !!also if .*   => recordPath.'*'
        scalarType = Types.arrayElementType(ty);
        path = getRecordPath(scalarType);
        path = Absyn.makeFullyQualified(path);
        (cache,operatorCl,recordEnv) = Lookup.lookupClass(cache,env,path,false);
        (cache,path,recordEnv) = lookupOperatorBaseClass(cache,recordEnv,operatorCl);
        opNamePath = Absyn.IDENT(opName);
        path = Absyn.joinPaths(path, opNamePath);
        // check if the operator is defined. i.e overloaded
        (cache,operatorCl,operEnv) = Lookup.lookupClass(cache,recordEnv,path,false);
        true = SCode.isOperator(operatorCl);
        // get the list of functions in the operator. !! there can be multiple options
        paths = SCodeUtil.getListofQualOperatorFuncsfromOperator(operatorCl);
        (cache,funcs) = Lookup.lookupFunctionsListInEnv(cache, operEnv, paths, info, {});
        funcs = List.select2(funcs, if opName=="'constructor'" or opName=="'0'" then checkOperatorFunctionOutput else checkOperatorFunctionOneOutput,
          scalarType,info);
        (cache,funcs) = getOperatorFuncsOrEmpty(cache,env,rest,opName,info,listAppend(funcs,acc));
      then (cache,funcs);
    case (_,_,_::rest,_,_,_)
      equation
        (cache,funcs) = getOperatorFuncsOrEmpty(inCache,env,rest,opName,info,acc);
      then (cache,funcs);
    case (_,_,{},_,_,_)
      equation
        (cache,Util.SUCCESS()) = Static.instantiateDaeFunctionFromTypes(inCache, env, acc, false, NONE(), true, Util.SUCCESS());
        (DAE.T_TUPLE(funcs,_,{}),_) = Types.traverseType(DAE.T_TUPLE(acc,NONE(),{}), -1, Types.makeExpDimensionsUnknown);
      then (cache,funcs);
  end matchcontinue;
end getOperatorFuncsOrEmpty;

function lookupOperatorBaseClass "From a derived class, we find the parent.
This is required because we take the union of functions from lhs and rhs.
If one is Complex and one is named ComplexVoltage, we would get different types.
This also reduces the total number of functions that are instantiated.
"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SCode.Element inClass;
  output FCore.Cache cache;
  output Absyn.Path path;
  output FCore.Graph env;
algorithm
  (cache,path,env) := match (inCache,inEnv,inClass)
    local
      SCode.Element cl;
      String name;
    case (cache,env,SCode.CLASS(classDef=SCode.DERIVED(typeSpec=Absyn.TPATH(path,NONE()))))
      equation
        (cache,cl,env) = Lookup.lookupClass(cache,env,path,false);
        (cache,path,env) = lookupOperatorBaseClass(cache,env,cl);
      then (cache,path,env);

    case (cache,env,SCode.CLASS(name=name))
      equation
        path = FGraph.joinScopePath(env,Absyn.IDENT(name));
      then (cache,path,env);
  end match;
end lookupOperatorBaseClass;

function checkOperatorFunctionOneOutput
  input DAE.Type ty;
  input DAE.Type opType;
  input SourceInfo info;
  output Boolean isOK;
algorithm
  isOK := match (ty,opType,info)
    local
      DAE.Type ty1,ty2;
      Absyn.Path p;
      Boolean b;
    case (DAE.T_FUNCTION(funcResultType=DAE.T_TUPLE()),_,_) then false;
    case (DAE.T_FUNCTION(funcArg=DAE.FUNCARG(ty=ty1,defaultBinding=NONE())::DAE.FUNCARG(ty=ty2,defaultBinding=NONE())::_,source={_}),_,_)
      equation
        b = Types.equivtypesOrRecordSubtypeOf(Types.arrayElementType(ty1),opType) or Types.equivtypesOrRecordSubtypeOf(Types.arrayElementType(ty2),opType);
        checkOperatorFunctionOneOutputError(b,opType,ty,info);
      then b;
    case (DAE.T_FUNCTION(funcArg=DAE.FUNCARG(ty=ty1,defaultBinding=NONE())::_,source={_}),_,_)
      equation
        b = Types.equivtypesOrRecordSubtypeOf(Types.arrayElementType(ty1),opType);
        checkOperatorFunctionOneOutputError(b,opType,ty,info);
      then b;
    else true;
  end match;
end checkOperatorFunctionOneOutput;

function checkOperatorFunctionOneOutputError
  input Boolean ok;
  input DAE.Type opType;
  input DAE.Type ty;
  input SourceInfo info;
algorithm
  _ := match (ok,opType,ty,info)
    local
      String str1,str2;
    case (true,_,_,_) then ();
    else
      equation
        str1 = Types.unparseType(opType);
        str2 = Types.unparseType(ty);
        Error.addSourceMessage(Error.OP_OVERLOAD_OPERATOR_NOT_INPUT,{str1,str2},info);
      then fail();
  end match;
end checkOperatorFunctionOneOutputError;

function checkOperatorFunctionOutput
  input DAE.Type ty;
  input DAE.Type expected;
  input SourceInfo info;
  output Boolean isOK;
algorithm
  isOK := match (ty,expected,info)
    local
      DAE.Type actual;
    case (DAE.T_FUNCTION(funcResultType=actual),_,_)
      equation
        isOK = Types.equivtypesOrRecordSubtypeOf(actual,expected);
        // Error.assertionOrAddSourceMessage(isOK, Error.COMPILER_WARNING, {"TODO: Better warning for: " + Types.unparseType(actual) + ", expected: " + Types.unparseType(actual)}, info);
      then isOK;
    else false;
  end match;
end checkOperatorFunctionOutput;

function isOperatorBinaryFunctionOrWarn
  input DAE.Type ty;
  input SourceInfo info;
  output Boolean isBinaryFunc;
algorithm
  isBinaryFunc := match (ty,info)
    local
      list<DAE.FuncArg> rest;
    case (DAE.T_FUNCTION(funcArg={_}),_) then false; // Unary functions are legal even if we are not interested in them
    case (DAE.T_FUNCTION(funcArg=DAE.FUNCARG(defaultBinding=NONE())::DAE.FUNCARG(defaultBinding=NONE())::rest),_)
      equation
        isBinaryFunc = Util.boolAndList(List.mapMap(rest, Types.funcArgDefaultBinding, Util.isSome));
        // Error.assertionOrAddSourceMessage(isBinaryFunc, Error.COMPILER_WARNING, {"TODO: Better warning for: " + Types.unparseType(ty) + ", expected arguments 3..n to have default values"}, info);
      then isBinaryFunc; // Unary functions are legal even if we are not interested in them
    else
      equation
        // Error.addSourceMessage(Error.COMPILER_WARNING, {"TODO: Better warning for: " + Types.unparseType(ty) + ", expected arguments 1&2 to not have default values"}, info);
      then false;
  end match;
end isOperatorBinaryFunctionOrWarn;

function isOperatorUnaryFunction
  input DAE.Type ty;
  output Boolean isBinaryFunc;
algorithm
  isBinaryFunc := match ty
    local
      list<DAE.FuncArg> rest;
    case DAE.T_FUNCTION(funcArg=DAE.FUNCARG(defaultBinding=NONE())::rest)
      equation
        isBinaryFunc = Util.boolAndList(List.mapMap(rest, Types.funcArgDefaultBinding, Util.isSome));
      then isBinaryFunc;
    else false;
  end match;
end isOperatorUnaryFunction;

function getZeroConstructorExpression
  input DAE.Type ty;
  output DAE.Exp result;
algorithm
  result := match ty
    local
      list<DAE.FuncArg> args;
      Absyn.Path path;
      DAE.FunctionAttributes attr;
    case DAE.T_FUNCTION(funcArg=args,functionAttributes=attr,source={path})
      equation
        result = makeCallFillRestDefaults(path,{},args,Types.makeCallAttr(ty,attr));
      then result;
  end match;
end getZeroConstructorExpression;

function makeCallFillRestDefaults
  input Absyn.Path path;
  input list<DAE.Exp> inExps;
  input list<DAE.FuncArg> restArgs;
  input DAE.CallAttributes attr;
  output DAE.Exp exp;
protected
  list<DAE.Exp> exps;
algorithm
  exps := listAppend(inExps,List.mapMap(restArgs,Types.funcArgDefaultBinding,Util.getOption));
  exp := DAE.CALL(path,exps,attr);
end makeCallFillRestDefaults;

function getRecordPath
  input DAE.Type inType1;
  output Absyn.Path outPath;
algorithm
  DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_), source = outPath :: _) :=
    Types.arrayElementType(inType1);
end getRecordPath;

function deoverload "Given several lists of parameter types and one argument list,
  this function tries to find one list of parameter types which
  is compatible with the argument list. It uses elabArglist to
  do the matching, which means that automatic type conversions
  will be made when necessary.  The new argument list, together
  with a new operator that corresponds to the parameter type list
  is returned.

  The basic principle is that the first operator that matches is chosen.
  ."
  input list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> inOperators;
  input list<tuple<DAE.Exp, DAE.Type>> inArgs;
  input Absyn.Exp aexp "for error-messages";
  input Prefix.Prefix inPrefix;
  input SourceInfo info;
  output DAE.Operator outOperator;
  output list<DAE.Exp> outArgs;
  output DAE.Type outType;
algorithm
  (outOperator, outArgs, outType) :=
  matchcontinue (inOperators, inArgs, aexp, inPrefix, info)
    local
      list<DAE.Exp> exps,args_1;
      list<DAE.Type> types_1,params,tps;
      DAE.Type rtype_1,rtype;
      DAE.Operator op;
      list<tuple<DAE.Exp, DAE.Type>> args;
      list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> xs;
      Prefix.Prefix pre;
      DAE.Type ty;
      list<String> exps_str,tps_str;
      String estr, pre_str, s, tpsstr;

    case (((op,params,rtype) :: _),args,_,pre,_)
      equation
        //Debug.fprint(Flags.DOVL, stringDelimitList(List.map(params, Types.printTypeStr),"\n"));
        //Debug.fprint(Flags.DOVL, "\n===\n");
        (args_1,types_1) = elabArglist(params, args);
        rtype_1 = computeReturnType(op, types_1, rtype,pre,info);
        ty = Types.simplifyType(rtype_1);
        op = Expression.setOpType(op, ty);
      then
        (op,args_1,rtype_1);

    case ((_ :: xs),args,_,pre,_)
      equation
        (op,args_1,rtype) = deoverload(xs,args,aexp,pre,info);
      then
        (op,args_1,rtype);

    //Don't fail and dont print error messages. Operators can be overloaded
    //for records.
    //mahge: TODO move this to the proper place and print.
    case ({},args,_,pre,_)
      equation
        s = Dump.printExpStr(aexp);
        exps = List.map(args, Util.tuple21);
        tps = List.map(args, Util.tuple22);
        exps_str = List.map(exps, ExpressionDump.printExpStr);
        _ = stringDelimitList(exps_str, ", ");
        tps_str = List.map(tps, Types.unparseType);
        tpsstr = stringDelimitList(tps_str, ", ");
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s,tpsstr,pre_str}, info);
      then
        fail();
  end matchcontinue;
end deoverload;

function computeReturnType "This function determines the return type of
  an operator and the types of the operands."
  input DAE.Operator inOperator;
  input list<DAE.Type> inTypesTypeLst;
  input DAE.Type inType;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inOperator,inTypesTypeLst,inType,inPrefix, inInfo)
    local
      DAE.Type typ1,typ2,rtype,etype,typ;
      String t1_str,t2_str,pre_str;
      DAE.Dimension n1,n2,m,n,m1,m2,p;
      Prefix.Prefix pre;

    case (DAE.ADD_ARR(),{typ1,typ2},_,_, _)
      equation
        true = Types.subtype(typ1, typ2);
      then
        typ1;

    case (DAE.ADD_ARR(),{typ1,typ2},_,_, _)
      equation
        true = Types.subtype(typ2, typ1);
      then
        typ1;

    case (DAE.ADD_ARR(),{typ1,typ2},_,pre, _)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.INCOMPATIBLE_TYPES,
          {"vector addition", pre_str, t1_str, t2_str}, inInfo);
      then
        fail();

    case (DAE.SUB_ARR(),{typ1,typ2},_,_, _)
      equation
        true = Types.subtype(typ1, typ2);
      then
        typ1;

    case (DAE.SUB_ARR(),{typ1,typ2},_,_, _)
      equation
        true = Types.subtype(typ2, typ1);
      then
        typ1;

    case (DAE.SUB_ARR(),{typ1,typ2},_,pre, _)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.INCOMPATIBLE_TYPES,
          {"vector subtraction", pre_str, t1_str, t2_str}, inInfo);
      then
        fail();

    case (DAE.MUL_ARR(),{typ1,typ2},_,_, _)
      equation
        true = Types.subtype(typ1, typ2);
      then
        typ1;

    case (DAE.MUL_ARR(),{typ1,typ2},_,_, _)
      equation
        true = Types.subtype(typ2, typ1);
      then
        typ1;

    case (DAE.MUL_ARR(),{typ1,typ2},_,pre, _)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.INCOMPATIBLE_TYPES,
          {"vector elementwise multiplication", pre_str, t1_str, t2_str}, inInfo);
      then
        fail();

    case (DAE.DIV_ARR(),{typ1,typ2},_,_, _)
      equation
        true = Types.subtype(typ1, typ2);
      then
        typ1;

    case (DAE.DIV_ARR(),{typ1,typ2},_,_, _)
      equation
        true = Types.subtype(typ2, typ1);
      then
        typ1;

    case (DAE.DIV_ARR(),{typ1,typ2},_,pre, _)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.INCOMPATIBLE_TYPES,
          {"vector elementwise division", pre_str, t1_str, t2_str}, inInfo);
      then
        fail();

    // Matrix[n,m]^i
    case (DAE.POW_ARR(),{typ1,_},_,_, _)
      equation
        2 = nDims(typ1);
        n = Types.getDimensionNth(typ1, 1);
        m = Types.getDimensionNth(typ1, 2);
        true = Expression.dimensionsKnownAndEqual(n, m);
      then
        typ1;

    case (DAE.POW_ARR2(),{typ1,typ2},_,_, _)
      equation
        true = Types.subtype(typ1, typ2);
      then
        typ1;

    case (DAE.POW_ARR2(),{typ1,typ2},_,_, _)
      equation
        true = Types.subtype(typ2, typ1);
      then
        typ1;

    case (DAE.POW_ARR2(),{typ1,typ2},_,pre, _)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.INCOMPATIBLE_TYPES,
          {"elementwise vector^vector", pre_str, t1_str, t2_str}, inInfo);
      then
        fail();

    case (DAE.MUL_SCALAR_PRODUCT(),{typ1,typ2},rtype,_, _)
      equation
        true = Types.subtype(typ1, typ2);
      then
        rtype;

    case (DAE.MUL_SCALAR_PRODUCT(),{typ1,typ2},rtype,_, _)
      equation
        true = Types.subtype(typ2, typ1);
      then
        rtype;

    case (DAE.MUL_SCALAR_PRODUCT(),{typ1,typ2},_,pre, _)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.INCOMPATIBLE_TYPES,
          {"scalar product", pre_str, t1_str, t2_str}, inInfo);
      then
        fail();

    // Vector[n]*Matrix[n,m] = Vector[m]
    case (DAE.MUL_MATRIX_PRODUCT(),{typ1,typ2},_,_, _)
      equation
        1 = nDims(typ1);
        2 = nDims(typ2);

        n1 = Types.getDimensionNth(typ1, 1);
        n2 = Types.getDimensionNth(typ2, 1);
        m = Types.getDimensionNth(typ2, 2);

        true = isValidMatrixProductDims(n1, n2);
        etype = elementType(typ1);
        rtype = Types.liftArray(etype, m);
      then
        rtype;

    // Matrix[n,m]*Vector[m] = Vector[n]
    case (DAE.MUL_MATRIX_PRODUCT(),{typ1,typ2},_,_, _)
      equation
        2 = nDims(typ1);
        1 = nDims(typ2);

        n = Types.getDimensionNth(typ1, 1);
        m1 = Types.getDimensionNth(typ1, 2);
        m2 = Types.getDimensionNth(typ2, 1);

        true = isValidMatrixProductDims(m1, m2);
        etype = elementType(typ2);
        rtype = Types.liftArray(etype, n);
      then
        rtype;

    // Matrix[n,m] * Matrix[m,p] = Matrix[n, p]
    case (DAE.MUL_MATRIX_PRODUCT(),{typ1,typ2},_,_, _)
      equation
        2 = nDims(typ1);
        2 = nDims(typ2);

        n = Types.getDimensionNth(typ1, 1);
        m1 = Types.getDimensionNth(typ1, 2);
        m2 = Types.getDimensionNth(typ2, 1);
        p = Types.getDimensionNth(typ2, 2);

        true = isValidMatrixProductDims(m1, m2);
        etype = elementType(typ1);
        rtype = Types.liftArrayListDims(etype, {n, p});
      then
        rtype;

    case (DAE.MUL_MATRIX_PRODUCT(),{typ1,typ2},_,pre, _)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.INCOMPATIBLE_TYPES,
          {"matrix multiplication", pre_str, t1_str, t2_str}, inInfo);
      then
        fail();

    case (DAE.MUL_ARRAY_SCALAR(),{typ1,_},_,_, _) then typ1;  /* rtype */

    case (DAE.ADD_ARRAY_SCALAR(),{typ1,_},_,_, _) then typ1;  /* rtype */

    case (DAE.SUB_SCALAR_ARRAY(),{_,typ2},_,_, _) then typ2;  /* rtype */

    case (DAE.DIV_SCALAR_ARRAY(),{_,typ2},_,_, _) then typ2;  /* rtype */

    case (DAE.DIV_ARRAY_SCALAR(),{typ1,_},_,_, _) then typ1;  /* rtype */

    case (DAE.POW_ARRAY_SCALAR(),{typ1,_},_,_, _) then typ1;  /* rtype */

    case (DAE.POW_SCALAR_ARRAY(),{_,typ2},_,_, _) then typ2;  /* rtype */

    case (DAE.ADD(),_,typ,_, _) then typ;

    case (DAE.SUB(),_,typ,_, _) then typ;

    case (DAE.MUL(),_,typ,_, _) then typ;

    case (DAE.DIV(),_,typ,_, _) then typ;

    case (DAE.POW(),_,typ,_, _) then typ;

    case (DAE.UMINUS(),_,typ,_, _) then typ;

    case (DAE.UMINUS_ARR(),(typ1 :: _),_,_, _) then typ1;

    case (DAE.AND(), {typ1, typ2}, _, _, _)
      equation
        true = Types.equivtypes(typ1, typ2);
      then
        typ1;

    case (DAE.AND(), {typ1, typ2}, _, pre, _)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.INCOMPATIBLE_TYPES,
          {"and", pre_str, t1_str, t2_str}, inInfo);
      then
        fail();

    case (DAE.OR(), {typ1, typ2}, _, _, _)
      equation
        true = Types.equivtypes(typ1, typ2);
      then
        typ1;

    case (DAE.OR(), {typ1, typ2}, _, pre, _)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.INCOMPATIBLE_TYPES,
          {"or", pre_str, t1_str, t2_str}, inInfo);
      then
        fail();

    case (DAE.NOT(),{typ1},_,_, _) then typ1;

    case (DAE.LESS(),_,typ,_, _) then typ;

    case (DAE.LESSEQ(),_,typ,_, _) then typ;

    case (DAE.GREATER(),_,typ,_, _) then typ;

    case (DAE.GREATEREQ(),_,typ,_, _) then typ;

    case (DAE.EQUAL(),_,typ,_, _) then typ;

    case (DAE.NEQUAL(),_,typ,_, _) then typ;

    case (DAE.USERDEFINED(),_,typ,_, _) then typ;
  end matchcontinue;
end computeReturnType;

function nDims "Returns the number of dimensions of a Type."
  input DAE.Type inType;
  output Integer outInteger;
algorithm
  outInteger := match (inType)
    local
      Integer ns;
      DAE.Type t;
    case (DAE.T_INTEGER()) then 0;
    case (DAE.T_REAL()) then 0;
    case (DAE.T_STRING()) then 0;
    case (DAE.T_BOOL()) then 0;
    case (DAE.T_ARRAY(ty = t))
      equation
        ns = nDims(t);
      then
        ns + 1;
    case (DAE.T_SUBTYPE_BASIC(complexType = t))
      equation
        ns = nDims(t);
      then ns;
  end match;
end nDims;

function isValidMatrixProductDims
  "Checks if two dimensions are equal, which is a prerequisite for matrix
  multiplication."
  input DAE.Dimension dim1;
  input DAE.Dimension dim2;
  output Boolean res;
algorithm
  res := // Naturally dimensions 1 and 1 are equal
         Expression.dimensionsKnownAndEqual(dim1, dim2)
         // We need run-time checks for DIM_EXP=DIM_EXP
         or (not (Expression.dimensionKnown(dim1) or Expression.dimensionKnown(dim2)))
    // If checkModel is used we might get unknown dimensions. So use
    // dimensionsEqual instead, which matches anything against DIM_UNKNOWN.
         or (Flags.getConfigBool(Flags.CHECK_MODEL) and Expression.dimensionsEqual(dim1, dim2));
end isValidMatrixProductDims;

function elementType "Returns the element type of a type, i.e. for arrays, return the
  element type, and for bulitin scalar types return the type itself."
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := match (inType)
    local DAE.Type t,t_1;
    case ((t as DAE.T_INTEGER())) then t;
    case ((t as DAE.T_REAL())) then t;
    case ((t as DAE.T_STRING())) then t;
    case ((t as DAE.T_BOOL())) then t;
    case (DAE.T_ARRAY(ty = t))
      equation
        t_1 = elementType(t);
      then
        t_1;
    case (DAE.T_SUBTYPE_BASIC(complexType = t))
      equation
        t_1 = elementType(t);
      then t_1;
  end match;
end elementType;

function replaceOperatorWithFcall "Replaces a userdefined operator expression with a corresponding function
  call expression. Other expressions just passes through."
  input Absyn.Exp AbExp;
  input DAE.Exp inExp1;
  input DAE.Operator inOper;
  input Option<DAE.Exp> inExp2;
  input DAE.Const inConst;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (AbExp,inExp1,inOper,inExp2,inConst)
    local
      DAE.Exp e1,e2;
      Absyn.Path funcname;
      DAE.Const c;

    case (Absyn.BINARY(_,_,_), e1, DAE.USERDEFINED(fqName = funcname), SOME(e2), _)
      then DAE.CALL(funcname,{e1,e2},DAE.CALL_ATTR(DAE.T_UNKNOWN_DEFAULT,false,false,false,false,DAE.NO_INLINE(),DAE.NO_TAIL()));

    case (Absyn.BINARY(_,_,_), e1, _, SOME(e2), _)
      then DAE.BINARY(e1, inOper, e2);

    case (Absyn.UNARY(_, _), e1, DAE.USERDEFINED(fqName = funcname), NONE(), _)
      then DAE.CALL(funcname,{e1},DAE.CALL_ATTR(DAE.T_UNKNOWN_DEFAULT,false,false,false,false,DAE.NO_INLINE(),DAE.NO_TAIL()));

    case (Absyn.UNARY(_, _), e1, _, NONE(), _)
        then DAE.UNARY(inOper,e1);

    case (Absyn.LBINARY(_, _, _), e1, DAE.USERDEFINED(fqName = funcname), SOME(e2), _)
       then DAE.CALL(funcname,{e1,e2},DAE.CALL_ATTR(DAE.T_UNKNOWN_DEFAULT,false,false,false,false,DAE.NO_INLINE(),DAE.NO_TAIL()));

    case (Absyn.LBINARY(_,_,_), e1, _, SOME(e2), _)
      then DAE.LBINARY(e1, inOper, e2);

    case (Absyn.LUNARY(_, _), e1, DAE.USERDEFINED(fqName = funcname), NONE(),_)
      then DAE.CALL(funcname,{e1},DAE.CALL_ATTR(DAE.T_UNKNOWN_DEFAULT,false,false,false,false,DAE.NO_INLINE(),DAE.NO_TAIL()));

    case (Absyn.LUNARY(_, _), e1, _, NONE(), _)
        then DAE.LUNARY(inOper,e1);

    case (Absyn.RELATION(_, _, _), e1, DAE.USERDEFINED(fqName = funcname), SOME(e2),_)
      then DAE.CALL(funcname,{e1,e2},DAE.CALL_ATTR(DAE.T_UNKNOWN_DEFAULT,false,false,false,false,DAE.NO_INLINE(),DAE.NO_TAIL()));

    case (Absyn.RELATION(_,_,_), e1, _, SOME(e2), _)
      then DAE.RELATION(e1, inOper, e2, -1, NONE());

  end matchcontinue;
end replaceOperatorWithFcall;

function warnUnsafeRelations "Check if we have Real == Real or Real != Real, if so give a warning."
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input DAE.Const variability;
  input DAE.Type t1,t2;
  input DAE.Exp e1,e2;
  input DAE.Operator op;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
algorithm
  _ := matchcontinue(inEnv,inExp,variability,t1,t2,e1,e2,op,inPrefix,inInfo)
    local
      Boolean b1,b2;
      String stmtString,opString,pre_str;
      Prefix.Prefix pre;
    // == or != on Real is permitted in functions, so don't print an error if
    // we're in a function.
    case (_, _, _, _, _, _, _, _, _, _)
      equation
        true = FGraph.inFunctionScope(inEnv);
      then ();

    case(_, Absyn.RELATION(_, _, _), DAE.C_VAR(),_,_,_,_,_,pre,_)
      equation
        b1 = Types.isReal(t1);
        b2 = Types.isReal(t1);
        true = boolOr(b1,b2);
        verifyOp(op);
        opString = ExpressionDump.relopSymbol(op);
        stmtString = ExpressionDump.printExpStr(e1) + opString + ExpressionDump.printExpStr(e2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.WARNING_RELATION_ON_REAL, {pre_str,stmtString,opString}, inInfo);
      then
        ();
    else ();
  end matchcontinue;
end warnUnsafeRelations;

function verifyOp "
Helper function for warnUnsafeRelations
We only want to check DAE.EQUAL and Expression.NEQUAL since they are the only illegal real operations."
input DAE.Operator op;
algorithm _ := match(op)
  case(DAE.EQUAL(_)) then ();
  case(DAE.NEQUAL(_)) then ();
  end match;
end verifyOp;

function errorMultipleValid
  input list<DAE.Exp> exps;
  input SourceInfo info;
protected
  String str1,str2;
algorithm
  str1 := intString(listLength(exps));
  str2 := stringDelimitList(List.map(exps,ExpressionDump.printExpStr), ",");
  Error.addSourceMessage(Error.OP_OVERLOAD_MULTIPLE_VALID, {str1,str2}, info);
end errorMultipleValid;

function binaryCastConstructor
  input FCore.Cache inCache;
  input FCore.Graph env;
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Type inType1;
  input DAE.Type inType2;
  input list<tuple<DAE.Exp,Option<DAE.Type>>> exps;
  input list<DAE.Type> types;
  input SourceInfo info;
  output FCore.Cache cache;
  output list<tuple<DAE.Exp,Option<DAE.Type>>> resExps;
algorithm
  (cache,resExps) := match (inCache,env,inExp1,inExp2,inType1,inType2,exps,types,info)
    local
      list<list<DAE.FuncArg>> args;
      list<DAE.Type> tys1,tys2;
      list<DAE.Exp> exps1,exps2;
    case (_,_,_,_,_,_,{_},_,_) then (inCache,exps); // We already have exactly 1 match, so don't look for more
    case (_,_,_,_,_,_,{},_,_)
      equation
        // Step 3: Call constructor functions to try matching inputs
        args = List.map(types, Types.getFuncArg);
        tys1 = List.mapMap(args, listHead, Types.funcArgType);
        args = List.map(args, List.rest);
        tys2 = List.mapMap(args, listHead, Types.funcArgType);
        // We only look for constructors that are not of the initial type. Filter duplicates.
        tys1 = List.setDifference(List.union(tys1,tys1),{inType1});
        tys2 = List.setDifference(List.union(tys2,tys2),{inType2});
        // Get the constructors
        (cache,tys1) = getOperatorFuncsOrEmpty(inCache,env,tys1,"'constructor'",info,{});
        (cache,tys2) = getOperatorFuncsOrEmpty(cache,env,tys2,"'constructor'",info,{});
        // Filter out functions with more than 1 argument, since we cannot automatically construct such values anyway
        tys1 = List.select(tys1, isOperatorUnaryFunction);
        tys2 = List.select(tys2, isOperatorUnaryFunction);
        // Now see if any constructors were valid
        exps1 = deoverloadUnaryUserdefNoConstructor(tys1,inExp1,inType1,{});
        exps2 = deoverloadUnaryUserdefNoConstructor(tys2,inExp2,inType2,{});

        resExps = deoverloadBinaryUserdefNoConstructorListLhs(types,exps1,inExp2,inType2,{});
        resExps = deoverloadBinaryUserdefNoConstructorListRhs(types,inExp1,exps2,inType1,resExps);
      then (cache,resExps);
    else
      equation
        errorMultipleValid(List.map(exps,Util.tuple21),info);
      then fail();
  end match;
end binaryCastConstructor;

function getZeroConstructor
  input FCore.Cache inCache;
  input FCore.Graph env;
  input list<DAE.Exp> zexps;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> st;
  input SourceInfo info;
  output FCore.Cache cache;
  output Option<Values.Value> zeroExpression;
algorithm
  (cache,zeroExpression) := match (inCache,env,zexps,impl,st,info)
    local
      DAE.Exp zc;
      Values.Value v;
    case (_,_,{},_,_,_) then (inCache,NONE());
    case (cache,_,{zc},_,_,_)
      equation
        (cache, v, _) = Ceval.ceval(cache, env, zc, impl, st, Absyn.MSG(info), 0);
      then (cache,SOME(v));
    else
      equation
        errorMultipleValid(zexps,info);
      then fail();
  end match;
end getZeroConstructor;

annotation(__OpenModelica_Interface="frontend");
end OperatorOverloading;
